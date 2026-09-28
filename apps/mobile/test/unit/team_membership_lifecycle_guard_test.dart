import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// SEC-W1 — the Security Foundation Wave 1 fix ratchet.
///
/// Wave 1 closed the QAX-SEC-08 (P0) forgery and the team arm of F-03b (P1) by
/// `132_team_membership_lifecycle.sql`, under owner decisions D1(i)/(ii)/(iii)
/// recorded in `docs/adr/ADR-W1-001-team-membership-lifecycle.md`.
///
/// ── WHY THIS FILE EXISTS RATHER THAN A LOWERED SEC-G1 BASELINE ─────────────
/// SEC-G1 and CHAIN-G1's chain-set detector read `supabase/migrations/*.sql` as
/// text and do **not** resolve supersession — a policy dropped by a later
/// migration still matches the `CREATE POLICY` in the earlier one. So neither
/// can observe this fix, and lowering SEC-G1's baseline to 14 would make it fail
/// against text that is still present in `002_ecosystem_additions.sql`.
/// Deriving those populations from the live catalog instead is recorded as
/// owner/architecture decision **D15** and is out of Wave 1 scope.
///
/// This guard therefore asserts the *corrected* definitions in 132 directly. It
/// is a fix ratchet: it fails if any part of Wave 1 is reverted.
///
/// ── WHAT WAVE 1 DID NOT DO — do not read a pass here as more than it is ────
///   * `may_notify()` still trusts `coach_client_relationships` at ANY status.
///     That is **F-03b's second half** and is outside Wave 1 (decision D3), so
///     F-03b must stay OPEN.
///   * `hosts_event_for(id)` still grants an event host the whole
///     `user_profiles` row. That is **QAX-SEC-09** and is a separate path, so
///     "the P0 is closed" does **not** mean profile PHI is safe.
///   * `coach_team_invites` is still `FOR ALL` with no `WITH CHECK`. Wave 2.
/// Migration source with SQL line comments stripped.
///
/// Migration 132's own header quotes the defective policy and the rejected
/// `security_invoker = on` form in prose. Asserting against the raw text would
/// read that prose as DDL — the commented-code-as-active-code trap this
/// programme has hit seven times. Every assertion below runs on stripped code.
String stripComments(String src) => src
    .split('\n')
    .map((l) {
      final i = l.indexOf('--');
      return i < 0 ? l : l.substring(0, i);
    })
    .join('\n');

void main() {
  late String m132;
  late String code;

  setUpAll(() {
    final f = File('../../supabase/migrations/132_team_membership_lifecycle.sql');
    expect(f.existsSync(), isTrue,
        reason: 'migration 132 is missing — Wave 1 has been reverted or the '
            'relative path from apps/mobile is wrong');
    m132 = f.readAsStringSync();
    code = stripComments(m132);
  });


  test('SEC-W1 the guard is reading the right migration', () {
    // An absent result must not read as "fixed" — the H-D1 lesson.
    expect(code, contains('coach_team_members'));
    expect(code, contains('team_member_profiles'));
  });

  group('SEC-W1 · D1(i) — a lead cannot create a membership', () {
    test('the defective FOR ALL policy is dropped, not supplemented', () {
      expect(code,
          contains('DROP POLICY IF EXISTS "Head coach manages team" ON public.coach_team_members'),
          reason: 'the 002 policy must be DROPPED. Permissive policies OR '
              'together, so leaving it in place preserves the P0 entirely.');
      expect(RegExp(r'CREATE POLICY[^;]*ON\s+public\.coach_team_members[^;]*FOR\s+ALL',
              caseSensitive: false, dotAll: true).hasMatch(code),
          isFalse,
          reason: 'a FOR ALL policy is back on coach_team_members. FOR ALL with '
              'USING and no WITH CHECK reuses USING as the INSERT check — that '
              'reuse IS the P0.');
    });

    test('the INSERT policy carries a WITH CHECK that is member-originated', () {
      final insert = RegExp(
              r'CREATE POLICY\s+"member originates own membership"(.*?);',
              dotAll: true, caseSensitive: false)
          .firstMatch(code);
      expect(insert, isNotNull, reason: 'the member-originated INSERT policy is gone');
      final body = insert!.group(1)!;
      expect(body.toUpperCase(), contains('WITH CHECK'),
          reason: 'the INSERT policy lost its WITH CHECK — this is the defect');
      expect(body, contains('member_id = auth.uid()'),
          reason: 'D1(i): creation must be member-originated. A lead must not be '
              'able to name a member.');
      expect(body, contains("status = 'invited'"),
          reason: 'D1(ii): a self-originated row must not be born active, or the '
              'lifecycle is decorative and F-03b reopens in reverse.');
      expect(body, contains('coach_id <> member_id'),
          reason: 'self-membership guard removed');
    });

    test('no UPDATE policy grants an ungoverned activation route', () {
      expect(
          RegExp(r'CREATE POLICY[^;]*ON\s+public\.coach_team_members[^;]*FOR\s+UPDATE',
                  caseSensitive: false, dotAll: true)
              .hasMatch(code),
          isFalse,
          reason: 'an UPDATE policy on coach_team_members would let a row be '
              'moved to status = active outside the Wave 2 governed conversion, '
              'defeating D1(i).');
    });
  });

  // ── ADDENDUM A · migration 133 supersedes 132's INSERT policy ──────────────
  //
  // Agent 3's independent verification found that 132's member-originated INSERT
  // was permitted by no clause of D1(i). D1(i)'s second clause is unscoped —
  // "Membership must originate through the invite/consent flow" — and that flow
  // does not exist, so no origination is authorized yet. Migration 133 replaces
  // the policy with an explicit deny.
  //
  // These assertions exist because the group above still reads 132, where the
  // superseded policy text remains. Without them this guard would pin a policy
  // that is no longer in force — the same supersession blindness that prevents
  // SEC-G1's baseline from being lowered (D15).
  group('SEC-W1 · Addendum A — origination is denied until the consent flow exists', () {
    late String code133;

    setUpAll(() {
      final f = File(
          '../../supabase/migrations/133_team_membership_consent_origination.sql');
      expect(f.existsSync(), isTrue,
          reason: 'migration 133 is missing — the D1(i) fidelity remediation has '
              'been reverted, and 132 alone permits member-originated membership '
              'that no clause of D1(i) authorizes');
      code133 = stripComments(f.readAsStringSync());
    });

    test('the 132 INSERT policy is dropped', () {
      expect(code133,
          contains('DROP POLICY IF EXISTS "member originates own membership"'),
          reason: 'the superseded policy must be dropped, not left alongside the '
              'deny — permissive policies OR together');
    });

    test('INSERT is denied to every caller', () {
      final pol = RegExp(
              r'CREATE POLICY\s+"membership originates only through the consent flow"(.*?);',
              dotAll: true, caseSensitive: false)
          .firstMatch(code133);
      expect(pol, isNotNull, reason: 'the explicit deny policy is gone');
      final body = pol!.group(1)!;
      expect(body.toUpperCase(), contains('FOR INSERT'),
          reason: 'the deny must target INSERT');
      expect(RegExp(r'WITH\s+CHECK\s*\(\s*false\s*\)', caseSensitive: false)
              .hasMatch(body),
          isTrue,
          reason: 'D1(i): origination must go through the invite/consent flow. '
              'That flow does not exist, so nothing may originate a membership. '
              'Anything other than WITH CHECK (false) reopens NEW-W1-01, where an '
              'attacker injected an unsolicited row naming an arbitrary lead.');
    });

    test('Addendum A changes nothing else', () {
      // Scope discipline: 133 must touch one policy on one table. Its own
      // COMMENT text names other tables in prose, so this asserts on DDL only.
      final ddlTargets = RegExp(r'ON\s+public\.([a-z_]+)', caseSensitive: false)
          .allMatches(code133)
          .map((m) => m.group(1))
          .toSet();
      expect(ddlTargets, {'coach_team_members'},
          reason: 'migration 133 touched a table outside its authorized scope');
      for (final forbidden in [
        'DROP COLUMN', 'DROP CONSTRAINT', 'DROP FUNCTION', 'DROP VIEW',
        'TRUNCATE', 'DELETE FROM', 'DISABLE ROW LEVEL SECURITY',
      ]) {
        expect(code133.toUpperCase().contains(forbidden), isFalse,
            reason: '133 must be a single policy replacement; found $forbidden');
      }
    });
  });

  group('SEC-W1 · D1(ii) — the lifecycle is load-bearing', () {
    test('status exists with a CHECK limited to the four owner states', () {
      expect(code, contains('ADD COLUMN IF NOT EXISTS status text NOT NULL'),
          reason: 'the lifecycle column is gone');
      expect(code, contains("DEFAULT 'invited'"),
          reason: 'D1(ii): existence must not imply authorization, so the '
              'default must not be active');
      for (final s in ['invited', 'active', 'suspended', 'revoked']) {
        expect(code, contains("'$s'"), reason: 'owner state $s missing from the CHECK');
      }
    });

    test('is_team_lead_of() requires ACTIVE', () {
      final fn = RegExp(r'FUNCTION public\.is_team_lead_of\(.*?\$function\$;',
              dotAll: true)
          .firstMatch(code);
      expect(fn, isNotNull, reason: 'is_team_lead_of is no longer redefined by 132');
      expect(fn!.group(0), contains("t.status    = 'active'"),
          reason: 'D1(ii): only ACTIVE membership may satisfy team-lead '
              'authorization. Without this the status column is decorative and '
              'the P0 read path reopens.');
    });

    test('may_notify() requires ACTIVE on the team arm', () {
      final fn = RegExp(r'FUNCTION public\.may_notify\(.*?\$function\$;', dotAll: true)
          .firstMatch(code);
      expect(fn, isNotNull, reason: 'may_notify is no longer redefined by 132');
      final body = fn!.group(0)!;
      expect(
          RegExp(r"coach_team_members t\s*\n\s*WHERE t\.status = 'active'")
              .hasMatch(body),
          isTrue,
          reason: 'D1(ii): the notify channel must require an ACTIVE membership. '
              'This is the team arm of F-03b.');
    });
  });

  group('SEC-W1 · D1(iii) — PHI is out of the team-lead path', () {
    test('the user_profiles SELECT policy no longer trusts is_team_lead_of', () {
      final pol = RegExp(
              r'CREATE POLICY\s+"own profile or active coach reads profile"(.*?);',
              dotAll: true)
          .firstMatch(code);
      expect(pol, isNotNull, reason: '132 no longer redefines the user_profiles SELECT policy');
      final body = pol!.group(1)!;
      expect(body.contains('is_team_lead_of'), isFalse,
          reason: 'D1(iii): a team lead must NOT reach the whole user_profiles '
              'row. This arm granted parq_answers, weights, transformation '
              'photos and billing flags.');
      expect(body, contains('id = auth.uid()'),
          reason: 'self-read broken');
      expect(body, contains('is_active_coach_of(id)'),
          reason: 'the ACTIVE COACH clinical path must not break — an active '
              'coach legitimately needs the PAR-Q');
    });

    test('the roster view is column-limited and carries no PHI', () {
      final view = RegExp(r'CREATE OR REPLACE VIEW public\.team_member_profiles(.*?);',
              dotAll: true)
          .firstMatch(code);
      expect(view, isNotNull, reason: 'the minimum-necessary view is gone');
      final body = view!.group(1)!;
      for (final phi in [
        'parq', 'weight', 'medical', 'injury', 'risk_score', 'stripe',
        'membership_tier', 'transformation', 'date_of_birth', 'phone',
      ]) {
        expect(body.toLowerCase().contains(phi), isFalse,
            reason: 'D1(iii) excludes PHI absolutely, and `$phi` has appeared in '
                'the roster view.');
      }
      expect(body, contains('is_team_lead_of'),
          reason: 'the view must stay gated by the (now ACTIVE-only) helper');
    });

    test('the view does NOT use security_invoker = on', () {
      // NEW-5: the SEC_PHI_1 proposal used `on`, which applies the CALLER's RLS
      // — and the caller is exactly who the base policy now denies, so it would
      // return `200 []` to the users it exists to serve.
      expect(code, contains('security_invoker = off'),
          reason: 'the view must run as owner to serve rows the caller\'s own '
              'RLS denies — this is the corrected pattern');
      expect(code.contains('security_invoker = on'), isFalse,
          reason: 'NEW-5: security_invoker = on makes this view return 200 [] '
              'for every team lead');
      expect(code, contains('security_barrier = true'),
          reason: 'security_barrier keeps the optimizer from leaking rows past '
              'the predicate');
    });

    test('the view is not writable by authenticated — the migration-112 hole', () {
      // Supabase's ALTER DEFAULT PRIVILEGES grants ALL on new views to
      // authenticated. This view is auto-updatable and runs as owner, so a
      // surviving write grant is a write-through into user_profiles that
      // bypasses RLS. Migration 112 exists because 101/102/110 revoked PUBLIC
      // and anon but not authenticated. Wave 1 reproduced that bug once and
      // Agent 3 caught it live.
      expect(code, contains('REVOKE ALL ON public.team_member_profiles FROM PUBLIC, anon, authenticated'),
          reason: 'the write grant is back. An authenticated user could UPDATE '
              'user_profiles through this view as the owner, unfiltered by RLS '
              '— exactly what migration 112 closed for the other five views.');
      expect(code, contains('GRANT SELECT ON public.team_member_profiles TO authenticated'),
          reason: 'the roster can no longer be read');
    });
  });

  test('SEC-W1 the detector can still fail — non-vacuity', () {
    // Without this, every assertion above could be passing because the regexes
    // have rotted rather than because Wave 1 holds. The RG3 vacuous-pass lesson.
    const planted = '''
      CREATE POLICY "member originates own membership" ON public.coach_team_members
        FOR INSERT TO authenticated WITH CHECK (member_id = auth.uid());
    ''';
    // The real policy additionally pins status; a version without it must not
    // satisfy the D1(ii) assertion.
    expect(planted.contains("status = 'invited'"), isFalse,
        reason: 'the planted weaker policy should lack the status pin');
    expect(
        RegExp(r'CREATE POLICY[^;]*ON\s+public\.coach_team_members[^;]*FOR\s+ALL',
                caseSensitive: false, dotAll: true)
            .hasMatch('CREATE POLICY "x" ON public.coach_team_members FOR ALL USING (true);'),
        isTrue,
        reason: 'the FOR ALL detector no longer matches the shape it exists to catch');
  });
}
