import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// SEC-G1 — the F-21 policy shape must not spread.
///
/// ── THE DEFECT THIS PINS ───────────────────────────────────────────────────
/// `001_full_ecosystem.sql:351` reads:
///
///   CREATE POLICY "coaches manage programs" ON workout_programs
///     FOR ALL TO authenticated USING (coach_id = auth.uid());
///
/// The policy is *named* for coaches and never checks that the caller is one.
/// Anyone willing to write their own uid into `coach_id` satisfies it. Proven
/// empirically against QA: a client fixture created a programme naming itself
/// coach (201), self-assigned it (201), and **assigned it to another user**
/// (201 — cross-user write). All rows were deleted and cleanup verified.
/// See F-21 / F-21b in docs/QA_EVIDENCE.md.
///
/// `public.is_coach_profile(uuid)` already exists
/// (113_rls_coach_client_relationships.sql:58) and migration 113 applies
/// exactly that check to `coach_client_relationships`. It was never applied to
/// these tables.
///
/// ── WHY THIS IS A RATCHET AND NOT A FIX ────────────────────────────────────
/// Correcting the policies changes the authorization model, which the governing
/// instruction reserves as an owner decision (OD-14). This guard does not change
/// it. It holds the population at its measured size so a 16th cannot ship while
/// the decision is outstanding.
///
/// ── WHY IT READS THE MIGRATIONS AND NOT A MODEL OF THEM ────────────────────
/// `QA_CLOSURE_STANDARD` §4 records that 259 tests in this suite "define the
/// logic inside the test file and assert against the copy ... green whatever
/// the app does", and names `spec_security_guards_test.dart`'s simulated role
/// model as that shape. This guard parses the real `supabase/migrations/*.sql`
/// so it cannot pass while the database says otherwise.
void main() {
  /// Measured 2026-09-23. Lower it when policies are corrected under OD-14;
  /// never raise it. A rise means a new table shipped with a policy that claims
  /// a role it does not verify.
  const baseline = 15;

  /// Policies that name a privilege but only compare a caller-writable column
  /// to `auth.uid()`.
  List<({String file, int line, String table, String name, String cols})> scan() {
    final dir = Directory('../../supabase/migrations');
    if (!dir.existsSync()) return const [];

    final policy = RegExp(
      r'CREATE POLICY\s+"([^"]+)"\s+ON\s+([\w.]+)\s+FOR\s+ALL(.*?);',
      dotAll: true,
      caseSensitive: false,
    );
    // A real guard: a role helper, an explicit role comparison, or a subquery
    // that establishes a relationship.
    final guarded = RegExp(
      r'is_coach_profile|is_admin|is_active_coach_of|is_team_lead_of|'
      r'hosts_event_for|role\s*=|EXISTS\s*\(',
      caseSensitive: false,
    );
    final privileged = RegExp(r'coach|admin|head|team|vendor', caseSensitive: false);
    final uidCol = RegExp(r'(\w*?_?id)\s*=\s*\(?\s*(?:SELECT\s+)?auth\.uid\(\)',
        caseSensitive: false);

    final out = <({String file, int line, String table, String name, String cols})>[];
    final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.sql')).toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    for (final f in files) {
      final src = f.readAsStringSync();
      for (final m in policy.allMatches(src)) {
        final name = m.group(1)!;
        final table = m.group(2)!;
        final body = m.group(3)!;
        if (body.toUpperCase().contains('WITH CHECK')) continue;
        if (guarded.hasMatch(body)) continue;
        if (!privileged.hasMatch(name)) continue;
        final cols = uidCol.allMatches(body).map((c) => c.group(1)!).toSet().toList()..sort();
        if (cols.isEmpty) continue;
        out.add((
          file: f.uri.pathSegments.last,
          line: '\n'.allMatches(src.substring(0, m.start)).length + 1,
          table: table,
          name: name,
          cols: cols.join(','),
        ));
      }
    }
    return out;
  }

  test('SEC-G1 privilege-asserting policies with no role check do not increase', () {
    final found = scan();
    if (found.isEmpty) {
      // The migrations directory is not reachable from this working directory.
      // Say so rather than passing silently — a guard that cannot see its
      // subject protects nothing.
      fail('Could not read supabase/migrations — SEC-G1 asserted nothing. '
          'Check the relative path before trusting this suite.');
    }

    final listing = found
        .map((p) => '  ${p.file}:${p.line} ${p.table} [${p.cols}] "${p.name}"')
        .join('\n');

    expect(
      found.length,
      lessThanOrEqualTo(baseline),
      reason: 'A policy claims a privileged role but only compares a '
          'caller-writable column to auth.uid(), so anyone can satisfy it by '
          'writing their own uid into that column. This is the F-21 shape, '
          'proven exploitable for cross-user writes.\n'
          'Found ${found.length} (baseline $baseline):\n$listing\n\n'
          'Add is_coach_profile(coach_id) and an explicit WITH CHECK — the '
          'pattern migration 113 already uses for coach_client_relationships.',
    );
  });

  test('SEC-G1 the two proven-exploitable policies are still recorded', () {
    final found = scan();
    final tables = found.map((p) => p.table).toSet();
    // If these disappear from the inventory the fix has landed — lower the
    // baseline in the same commit rather than leaving this stale.
    expect(
      tables.any((t) => t.contains('workout_programs')) ||
          tables.any((t) => t.contains('workout_program_assignments')),
      isTrue,
      reason: 'F-21 is recorded as OPEN in docs/QA_EVIDENCE.md. If the policies '
          'have been corrected, close F-21 and lower the SEC-G1 baseline in the '
          'same change — do not leave the ledger and the guard disagreeing.',
    );
  });

  test('SEC-G1 the helper the fix needs already exists', () {
    final f = File('../../supabase/migrations/113_rls_coach_client_relationships.sql');
    expect(f.existsSync(), isTrue);
    expect(f.readAsStringSync(), contains('is_coach_profile'),
        reason: 'The correction for F-21 needs no new database function — '
            'migration 113 already defines and uses this one.');
  });
}
