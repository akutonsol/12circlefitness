import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// SEC-G3 — a read the database has already denied must not spread.
///
/// ── THE DEFECT THIS PINS ───────────────────────────────────────────────────
/// `workout_logs` carries exactly one policy, from `003_fk_and_rls_fixes.sql:193`:
///
///   CREATE POLICY "users manage own workout logs" ON workout_logs
///     FOR ALL TO authenticated USING (user_id = auth.uid())
///
/// No coach clause exists in any of the 131 migrations. The project knows the
/// correct shape — `114_rls_weekly_checkins.sql` writes
/// `user_id = (SELECT auth.uid()) OR public.is_active_coach_of(user_id)`, and
/// `100_rls_harden_client_data.sql` applies exactly that to `workout_sessions`
/// — it was simply never applied here.
///
/// ── WHY IT IS WORSE THAN A DENIAL ──────────────────────────────────────────
/// An RLS-filtered SELECT is **not an error**. PostgREST returns `200` and an
/// empty array, indistinguishable from "this client trained zero times". So a
/// coach surface built on it does not fail — it reports a confident, wrong
/// zero, permanently, and no `AsyncError` arm can catch it. The F-15 work gave
/// these screens an error path; this defect never reaches it.
///
/// `docs/QA_EVIDENCE.md` §6b records the finding in prose. Nothing enforced it,
/// so a fourth call site could ship at any time. This is that enforcement.
///
/// ── WHY IT IS *NOT* OD-14 ──────────────────────────────────────────────────
/// F-21/OD-14 is a policy that **claims a role it never verifies** — changing it
/// alters the authorization model, which is the owner's decision. This is the
/// opposite: a table with **no coach policy at all**, where the authorized path
/// already exists on a different table. Nothing here proposes a policy change.
/// The fix is to read `workout_sessions`, which a coach is permitted to read,
/// or `coach_client_ai_signals()`, the `SECURITY DEFINER` RPC written for
/// precisely this purpose.
void main() {
  /// The three reads that ask `workout_logs` about somebody else. Measured
  /// 2026-09-23 and matching the inventory in `docs/QA_EVIDENCE.md` §6b.
  ///
  /// This is a SHRINKING allowlist, checked in both directions: an unlisted
  /// cross-user read fails as new, and a listed one that no longer reproduces
  /// also fails, so a fix cannot leave a stale excuse behind.
  const declaredDenied = <String>{
    'lib/features/dashboard/presentation/coach_dashboard_screen.dart',
    'lib/features/compliance/data/compliance_service.dart',
    'lib/features/coach/domain/coach_ecosystem_provider.dart',
  };

  /// A read is cross-user when it filters `user_id` by anything other than the
  /// caller's own id. `insights_provider.dart` uses `.eq('user_id', uid)` where
  /// `uid` is the signed-in user — a self-read, permitted, and deliberately not
  /// listed above.
  Set<String> crossUserWorkoutLogReads() {
    final out = <String>{};
    for (final dir in const ['lib']) {
      for (final f in Directory(dir)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final src = f.readAsStringSync();
        for (final m in RegExp(r"\.from\('workout_logs'\)").allMatches(src)) {
          final window =
              src.substring(m.start, (m.start + 320).clamp(0, src.length));
          final selfRead = RegExp(r"\.eq\('user_id',\s*uid\s*\)").hasMatch(window);
          final otherRead = RegExp(
                  r"\.inFilter\('user_id'|\.eq\('user_id',\s*(?!uid\s*\))")
              .hasMatch(window);
          if (!selfRead && otherRead) out.add(f.path);
        }
      }
    }
    return out;
  }

  test('SEC-G3 no NEW code path reads workout_logs for another user', () {
    final found = crossUserWorkoutLogReads();

    // Detector floor — the lesson of H-D1. `found.difference(known)` is empty
    // both when nothing was added and when the scanner has gone blind, and
    // those are opposite facts.
    expect(found, isNotEmpty,
        reason: 'the scanner found no cross-user workout_logs read at all. '
            'Either all three were fixed — in which case empty this list and '
            'say so — or the detector is broken and proves nothing.');

    expect(
      found.difference(declaredDenied),
      isEmpty,
      reason: 'A new call site reads `workout_logs` for another user. RLS '
          'denies it and PostgREST answers 200 + [], so this will not fail — '
          'it will report a confident zero for every client, forever.\n'
          'Read `workout_sessions` instead (100_rls_harden_client_data.sql '
          'permits `is_active_coach_of`), or call the SECURITY DEFINER RPC '
          '`coach_client_ai_signals()`.',
    );

    expect(
      declaredDenied.difference(found),
      isEmpty,
      reason: 'a recorded declared-denied read no longer reproduces — delete '
          'it from `declaredDenied` and update docs/QA_EVIDENCE.md §6b in the '
          'same change, rather than leaving a stale excuse behind',
    );
  });

  test('SEC-G3 the authorized alternative still exists', () {
    // If either of these disappears, the guidance above becomes wrong and the
    // three recorded sites have nowhere correct to go.
    final harden =
        File('../../supabase/migrations/100_rls_harden_client_data.sql');
    expect(harden.existsSync(), isTrue);
    final src = harden.readAsStringSync();
    expect(src, contains('workout_sessions'),
        reason: 'the coach-readable session table is the sanctioned source');
    expect(RegExp(r'is_active_coach_of').hasMatch(src), isTrue);

    final rpc = File(
        '../../supabase/migrations/079_nutrition_autoadjust_and_coach_signals.sql');
    expect(rpc.existsSync(), isTrue);
    final rpcSrc = rpc.readAsStringSync();
    expect(rpcSrc, contains('coach_client_ai_signals'));
    expect(rpcSrc, contains('security definer'),
        reason: 'the RPC exists precisely because RLS restricts the underlying '
            'rows to the client');
    expect(rpcSrc, contains('workouts_7d'),
        reason: 'the coach-visible training-frequency signal');
  });

  test('SEC-G3 workout_logs still has no coach-read policy', () {
    // The guard above is only necessary while this is true. When a coach
    // policy lands, this fails and the whole guard should be revisited rather
    // than silently continuing to forbid a now-legitimate read.
    final dir = Directory('../../supabase/migrations');
    if (!dir.existsSync()) {
      fail('Could not read supabase/migrations — SEC-G3 asserted nothing.');
    }
    final policies = <String>[];
    for (final f in dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.sql'))) {
      for (final m in RegExp(
              r'CREATE POLICY\s+"([^"]+)"\s+ON\s+(?:public\.)?workout_logs\b(.*?);',
              dotAll: true,
              caseSensitive: false)
          .allMatches(f.readAsStringSync())) {
        policies.add(m.group(2)!);
      }
    }
    expect(policies, isNotEmpty,
        reason: 'no workout_logs policy found at all — the detector is broken, '
            'or the table lost its RLS entirely, which is far worse');
    expect(
      policies.any((p) => RegExp(r'is_active_coach_of|coach_id').hasMatch(p)),
      isFalse,
      reason: 'a coach-read policy now exists on workout_logs. The three reads '
          'this guard forbids may have become legitimate — re-evaluate SEC-G3 '
          'and docs/QA_EVIDENCE.md §6b together.',
    );
  });
}
