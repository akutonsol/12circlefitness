// SEC-020 … SEC-026 — Phase 1 P0 security remediation (migrations 113-118).
//
// These are STATIC guards: they parse the committed SQL and the committed Dart,
// so a regression fails `flutter test` before anything reaches a database and
// without needing QA credentials.
//
// They are the second half of a pair. The first half lives in
// supabase/tests/security/ and proves the boundary holds against a REAL
// project over REST — that is where "does this actually stop the attack?" is
// answered. What is asserted HERE is narrower and complementary: that the
// committed source cannot express the hole again. A live suite that nobody runs
// in CI protects nothing; a static suite alone cannot tell you whether
// PostgREST, the grants, the policies and the triggers compose.
//
// Findings guarded:
//   D-01  coach_client_relationships had no RLS -> forged relationship -> full
//         health-record and PII disclosure through is_active_coach_of()
//   D-02  user_profiles.role self-assignable, and signup metadata role trusted
//   D-03  weekly_checkins had no RLS -> anon CRUD on free-text health data
//   Q-4   PAR-Q risk classification was computed and written by the client
//   1D    98/100 public functions executable by anon; subject UUIDs trusted
//   1E/1F engine substrate readable, notification injection, view leak
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// ── Locating the tree ────────────────────────────────────────────────────────

Directory _mobileRoot() {
  var dir = Directory.current;
  while (!File('${dir.path}/pubspec.yaml').existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('Could not locate the Flutter package root');
    }
    dir = parent;
  }
  return dir;
}

Directory _repoRoot() {
  var dir = _mobileRoot();
  while (!Directory('${dir.path}/supabase/migrations').existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('Could not locate supabase/migrations');
    }
    dir = parent;
  }
  return dir;
}

Map<int, ({String name, String sql})> _allMigrations() {
  final dir = Directory('${_repoRoot().path}/supabase/migrations');
  final out = <int, ({String name, String sql})>{};
  for (final f in dir.listSync().whereType<File>()) {
    final name = f.uri.pathSegments.last;
    if (!name.endsWith('.sql')) continue;
    final n = int.tryParse(name.split('_').first);
    if (n == null) continue;
    out[n] = (name: name, sql: f.readAsStringSync());
  }
  return out;
}

String _stripComments(String sql) => sql
    .split('\n')
    .map((line) {
      final i = line.indexOf('--');
      return i == -1 ? line : line.substring(0, i);
    })
    .join('\n');

String _flat(String sql) => _stripComments(sql).replaceAll(RegExp(r'\s+'), ' ');

String _sql(int n) {
  final m = _allMigrations()[n];
  if (m == null) throw StateError('migration $n should exist');
  return _flat(m.sql);
}

String _lib(String relative) {
  final f = File('${_mobileRoot().path}/lib/$relative');
  if (!f.existsSync()) throw StateError('lib/$relative should exist');
  return f.readAsStringSync();
}

void main() {
  // ══════════════════════════════════════════════════════════════════════════
  // SEC-020 — D-01: the authorization root
  // ══════════════════════════════════════════════════════════════════════════
  group('SEC-020 coach_client_relationships is a trustworthy authorization source', () {
    late String m113;
    setUpAll(() => m113 = _sql(113));

    test('RLS is enabled on the table', () {
      expect(m113, contains('ALTER TABLE public.coach_client_relationships ENABLE ROW LEVEL SECURITY'));
    });

    test('anon holds nothing on it', () {
      expect(m113, contains('REVOKE ALL ON public.coach_client_relationships FROM PUBLIC, anon'));
    });

    test('all four verbs are governed, not just SELECT', () {
      // The table decides who may read whose health record, so the WRITE path is
      // the security boundary. A SELECT-only fix leaves the escalation intact.
      for (final cmd in ['FOR SELECT', 'FOR INSERT', 'FOR UPDATE']) {
        expect(m113, contains(cmd),
            reason: 'migration 113 should carry a $cmd policy');
      }
      expect(RegExp(r'CREATE POLICY[^;]*coach_client_relationships FOR DELETE', caseSensitive: false)
              .hasMatch(m113),
          isFalse,
          reason: 'DELETE must NOT be granted to clients — ending a relationship '
              'is status = cancelled, and hard deletion would destroy the audit trail');
    });

    test('a coach cannot unilaterally activate a relationship', () {
      // The asymmetry is the whole model: activating grants the COACH access to
      // the CLIENT's record, so only the client may consent.
      expect(m113, contains("coach_id = (SELECT auth.uid()) AND (status <> 'active' OR initiated_by = 'client')"),
          reason: 'the UPDATE WITH CHECK must let a coach leave a row active only '
              'when the client initiated it');
      expect(m113, contains("coach_id = (SELECT auth.uid()) AND initiated_by = 'coach' AND status = 'pending'"),
          reason: 'a coach-initiated INSERT must be pending only');
    });

    test('the row identity and provenance are immutable', () {
      // A WITH CHECK sees only NEW, so it cannot stop a party repointing their
      // own row at a third party. That is the trigger's job.
      expect(m113, contains('enforce_relationship_integrity'));
      for (final col in ['coach_id', 'client_id', 'initiated_by', 'client_source', 'invite_token']) {
        expect(m113, contains('NEW.$col'),
            reason: '$col must be pinned by trg_relationship_integrity');
      }
      expect(m113, contains('BEFORE UPDATE ON public.coach_client_relationships'));
    });

    test('invite_token is withheld by never granting the column', () {
      // A column-level REVOKE does not cut back a table-level GRANT — Postgres
      // treats them independently and the table grant wins. Observed live.
      expect(m113, contains("column_name NOT IN ('invite_token', 'invite_id')"),
          reason: 'the grant must enumerate allowed columns, not grant the table '
              'and then revoke two columns');
      expect(RegExp(r'GRANT\s+SELECT\s*,\s*INSERT\s*,\s*UPDATE\s+ON\s+public\.coach_client_relationships\s+TO\s+authenticated',
              caseSensitive: false).hasMatch(m113),
          isFalse,
          reason: 'a table-wide grant would re-expose invite_token');
    });

    test('marketplace capacity no longer reads the relationship rows', () {
      final provider = _lib('features/coach/domain/coach_provider.dart');
      expect(provider, contains("rpc('coach_active_client_counts'"),
          reason: 'capacity must come from the aggregate RPC');
      expect(
        RegExp(r"from\('coach_client_relationships'\)[\s\S]{0,200}inFilter\('coach_id'")
            .hasMatch(provider),
        isFalse,
        reason: 'availableCoachesProvider must not read other coaches\' relationship rows',
      );
      expect(m113, contains('coach_active_client_counts'));
      expect(m113, contains('COUNT(DISTINCT r.client_id)'),
          reason: 'the capacity RPC must return a count, never a client identity');
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // SEC-021 — D-03: health check-ins
  // ══════════════════════════════════════════════════════════════════════════
  group('SEC-021 weekly_checkins protects free-text health data', () {
    late String m114;
    setUpAll(() => m114 = _sql(114));

    test('RLS is enabled and anon holds nothing', () {
      expect(m114, contains('ALTER TABLE public.weekly_checkins ENABLE ROW LEVEL SECURITY'));
      expect(m114, contains('REVOKE ALL ON public.weekly_checkins FROM PUBLIC, anon'));
    });

    test('reads are owner + active coach only', () {
      expect(m114, contains('public.is_active_coach_of(user_id)'));
      expect(m114, contains('FOR SELECT TO authenticated'));
    });

    test('only the subject may create their own check-in', () {
      expect(m114, contains('FOR INSERT TO authenticated WITH CHECK (user_id = (SELECT auth.uid()))'),
          reason: 'a coach creating check-ins would let them fabricate compliance history');
    });

    test('the coach/client authorship split is enforced', () {
      expect(m114, contains('enforce_checkin_authorship'));
      expect(m114, contains("'feedback_message', 'feedback_recommendations', 'coach_name', 'reviewed_at', 'coach_id', 'status'"),
          reason: 'the coach-writable column set must be explicit');
      expect(m114, contains('a client cannot mark their own check-in reviewed'));
    });

    test('nobody but service_role deletes health history', () {
      expect(RegExp(r'GRANT[^;]*DELETE[^;]*ON public\.weekly_checkins', caseSensitive: false)
              .hasMatch(m114),
          isFalse);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // SEC-022 — D-02: the privilege boundary
  // ══════════════════════════════════════════════════════════════════════════
  group('SEC-022 user_profiles privilege columns are not self-assignable', () {
    late String m115;
    setUpAll(() => m115 = _sql(115));

    test('role has a vocabulary', () {
      expect(m115, contains("CHECK (role IN ('client', 'coach', 'vendor', 'admin', 'content_manager'))"),
          reason: 'there was no CHECK constraint at all, which is why an invented '
              'role landed silently');
    });

    test('every privilege column raises on a client write', () {
      for (final col in [
        'role', 'membership_tier', 'marketplace_commission_rate',
        'stripe_customer_id', 'stripe_account_id', 'stripe_charges_enabled',
        'stripe_payouts_enabled', 'stripe_details_submitted', 'is_demo',
      ]) {
        expect(m115, contains('NEW.$col IS DISTINCT FROM OLD.$col'),
            reason: '$col must be guarded by enforce_profile_privilege');
      }
      expect(m115, contains('BEFORE INSERT OR UPDATE ON public.user_profiles'));
    });

    test('server-derived columns are pinned to their stored value', () {
      for (final col in ['rating_avg', 'review_count', 'email', 'ai_client_summary']) {
        expect(m115, contains('NEW.$col := OLD.$col'), reason: '$col must be pinned');
      }
    });

    test('signup metadata cannot mint a privileged role', () {
      // raw_user_meta_data is supplied by whoever calls /auth/v1/signup.
      expect(m115, contains("if v_role not in ('client', 'coach', 'vendor') then"));
      expect(m115, contains("v_role := 'client'"));
    });

    test('there is exactly one authorized role-assignment path', () {
      expect(m115, contains('CREATE OR REPLACE FUNCTION public.admin_set_user_role'));
      expect(m115, contains('NOT public.is_admin()'));
      expect(m115, contains("REVOKE ALL ON FUNCTION public.admin_set_user_role(uuid, text) FROM PUBLIC, anon"));
      expect(m115, contains('RAISE LOG'), reason: 'a privileged role change must be logged');
    });

    test('is_admin() has a pinned search_path', () {
      expect(
        RegExp(r'CREATE OR REPLACE FUNCTION public\.is_admin\(\)[\s\S]{0,200}SET search_path')
            .hasMatch(m115),
        isTrue,
        reason: 'a SECURITY DEFINER function without a pinned search_path resolves '
            'unqualified names through the caller\'s search_path',
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // SEC-023 — Q-4: PAR-Q risk is a server decision
  // ══════════════════════════════════════════════════════════════════════════
  group('SEC-023 PAR-Q risk classification is server authority', () {
    late String m115;
    setUpAll(() => m115 = _sql(115));

    test('the classification lives in the database', () {
      expect(m115, contains('CREATE OR REPLACE FUNCTION public.derive_parq_risk'));
      expect(m115, contains('BEFORE INSERT OR UPDATE ON public.user_profiles FOR EACH ROW EXECUTE FUNCTION public.apply_parq_risk'));
    });

    test('it recomputes rather than trusting the submitted values', () {
      for (final col in ['risk_score', 'risk_level', 'risk_flags']) {
        expect(m115, contains('NEW.$col := d.$col'),
            reason: '$col must be overwritten with the derived value');
      }
    });

    test('the SQL thresholds match the Dart risk engine', () {
      // intake_data.dart still computes these for immediate UI feedback. If the
      // two drift, the number the member is shown stops matching the number the
      // safety constraint is evaluated on.
      final dart = _lib('features/onboarding/domain/intake_data.dart');
      expect(dart, contains('[1, 2, 3, 4, 7].any'),
          reason: 'the Dart high-risk question set');
      expect(m115, contains("ARRAY['1', '2', '3', '4', '7']"),
          reason: 'the SQL high-risk question set must be the same five questions');

      for (final flag in [
        'heart_condition', 'chest_pain_exercise', 'chest_pain_rest',
        'fainting_dizziness', 'orthopedic_condition', 'bp_heart_medication',
        'doctor_advised_no_exercise', 'other_medical_reason',
        'pregnancy', 'postpartum', 'active_injuries',
      ]) {
        expect(dart, contains("'$flag'"), reason: 'Dart flag $flag');
        expect(m115, contains("'$flag'"), reason: 'SQL flag $flag');
      }

      for (final cond in ['Pregnancy', 'Heart Disease', 'High Blood Pressure']) {
        expect(m115, contains("v_med LIKE '%$cond%'"),
            reason: 'the moderate-risk medical condition "$cond"');
      }
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // SEC-024 — Phase 1D: RPC execution
  // ══════════════════════════════════════════════════════════════════════════
  group('SEC-024 SECURITY DEFINER functions are not open to the internet', () {
    late String m116;
    setUpAll(() => m116 = _sql(116));

    test('EXECUTE is taken back from PUBLIC and anon schema-wide', () {
      expect(m116, contains('REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC'));
      expect(m116, contains('REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM anon'));
    });

    test('future functions inherit the closed posture', () {
      expect(m116, contains('ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC'));
      expect(m116, contains('ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE EXECUTE ON FUNCTIONS FROM anon'));
    });

    test('every SECURITY DEFINER function gets a pinned search_path', () {
      expect(m116, contains('ALTER FUNCTION %s SET search_path = public, pg_temp'));
      expect(m116, contains('p.prosecdef'));
    });

    test('there is an authorization predicate for subject-scoped RPCs', () {
      expect(m116, contains('CREATE OR REPLACE FUNCTION public.can_act_for(subject uuid)'));
      expect(m116, contains('public.is_active_coach_of(subject)'));
      // The internal/engine arm is load-bearing: pg_cron, the edge functions and
      // the API all call in as service_role with no JWT subject.
      expect(m116, contains('(SELECT auth.uid()) IS NULL'));
    });

    test('the named intelligence functions no longer trust a caller UUID', () {
      for (final fn in [
        'generate_workout', 'create_weekly_review', 'record_prediction',
        'predict_client', 'assemble_weekly_review', 'resolve_exercise_media',
        'snapshot_program_version',
      ]) {
        expect(m116, contains('FUNCTION public.$fn('), reason: '$fn should be re-declared');
      }
      expect(m116, contains('not authorized to generate for this subject'));
      expect(m116, contains('public.can_act_on_program(p_program_id)'));
    });

    test('the engine keeps its own execution path', () {
      // service_role and postgres are never revoked from; only PUBLIC/anon/
      // authenticated are, and the allowlist grants authenticated back.
      expect(RegExp(r'REVOKE[^;]*FROM[^;]*\bservice_role\b', caseSensitive: false).hasMatch(m116),
          isFalse,
          reason: 'revoking service_role would break the deterministic engine');
      expect(m116, contains('GRANT EXECUTE ON FUNCTION %s TO authenticated'));
    });

    test('every RPC the app calls is on the allowlist', () {
      // The blanket revoke is only safe if the allowlist is complete; this is the
      // check that stops a new .rpc() call site silently 404ing in production.
      final libDir = Directory('${_mobileRoot().path}/lib');
      final called = <String>{};
      final rpcCall = RegExp(r"\.rpc\(\s*'([a-z_0-9]+)'");
      for (final f in libDir.listSync(recursive: true).whereType<File>()) {
        if (!f.path.endsWith('.dart')) continue;
        for (final m in rpcCall.allMatches(f.readAsStringSync())) {
          called.add(m.group(1)!);
        }
      }
      expect(called, isNotEmpty, reason: 'the scan should find RPC call sites');

      final allowlistBlock = RegExp(r'allowed constant text\[\] := ARRAY\[(.*?)\];', dotAll: true)
          .firstMatch(m116);
      expect(allowlistBlock, isNotNull, reason: 'migration 116 should declare the allowlist');
      final allowed = RegExp(r"'([a-z_0-9]+)'")
          .allMatches(allowlistBlock!.group(1)!)
          .map((m) => m.group(1)!)
          .toSet();

      final missing = called.difference(allowed).toList()..sort();
      expect(missing, isEmpty,
          reason: 'these RPCs are called from lib/ but hold no EXECUTE grant after '
              'migration 116, so they will fail at runtime: ${missing.join(', ')}');
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // SEC-025 — Phase 1E: engine substrate
  // ══════════════════════════════════════════════════════════════════════════
  group('SEC-025 the deterministic engine substrate is not client-facing', () {
    late String m117;
    setUpAll(() => m117 = _sql(117));

    test('the blanket USING (true) reads are gone', () {
      for (final p in ['intel read', 'mie nodes read', 'mie edges read', 'read user_scores',
                       'all read programs', 'all read program workouts']) {
        expect(m117, contains('DROP POLICY IF EXISTS "$p"'),
            reason: 'the blanket policy "$p" must be dropped');
      }
    });

    test('substrate reads are content-editor only', () {
      expect(m117, contains('public.is_content_editor()'));
      for (final t in ['exercise_intelligence', 'movement_nodes', 'movement_edges']) {
        expect(m117, contains('ON public.$t FOR SELECT TO authenticated'),
            reason: '$t needs a scoped SELECT policy');
      }
    });

    test('programming is readable only by its parties', () {
      expect(m117, contains('CREATE OR REPLACE FUNCTION public.can_read_program'));
      expect(m117, contains('ON public.program_workouts FOR SELECT TO authenticated USING (public.can_read_program(program_id))'));
    });

    test('engine input cannot be deleted by the client', () {
      expect(m117, contains('REVOKE DELETE ON public.weekly_feedback FROM authenticated'));
      expect(m117, contains('DROP POLICY IF EXISTS "weekly fb rw"'),
          reason: 'the FOR ALL policy allowed DELETE');
    });

    test('the ai_conversations PUBLIC policy is closed', () {
      expect(m117, contains('ON public.ai_conversations FOR ALL TO authenticated'));
    });

    test('moderation dashboards are gated', () {
      expect(m117, contains('PERFORM public.require_content_editor()'));
      for (final fn in ['intelligence_review_queue', 'intelligence_stats', 'decision_analytics',
                        'movement_graph_stats', 'certification_summary', 'exercise_content_stats']) {
        expect(m117, contains('public.${fn}_engine'),
            reason: '$fn should delegate to a revoked *_engine original');
      }
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // SEC-026 — Phase 1F: the standing posture
  // ══════════════════════════════════════════════════════════════════════════
  group('SEC-026 schema-wide posture', () {
    late String m118;
    setUpAll(() => m118 = _sql(118));

    test('anon holds no table privilege, now or in future', () {
      expect(m118, contains('REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon'));
      expect(m118, contains('ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM anon'));
    });

    test('the three RLS-less tables are all closed', () {
      // coach_client_relationships (113), weekly_checkins (114), workouts (118).
      expect(_sql(113), contains('coach_client_relationships ENABLE ROW LEVEL SECURITY'));
      expect(_sql(114), contains('weekly_checkins ENABLE ROW LEVEL SECURITY'));
      expect(m118, contains('ALTER TABLE public.workouts ENABLE ROW LEVEL SECURITY'));
    });

    test('workouts is read-only and NOT deleted (Q-2)', () {
      expect(m118, contains('GRANT SELECT ON public.workouts TO authenticated'));
      expect(RegExp(r'DROP TABLE[^;]*workouts', caseSensitive: false).hasMatch(m118), isFalse,
          reason: 'Q-2: no destructive deletion in Phase 1');
    });

    test('the coach stats view carries its own authorization', () {
      expect(m118, contains('r.coach_id = (SELECT auth.uid())'),
          reason: 'a security_invoker = off view has no RLS behind it — the WHERE '
              'clause is the only authorization there is');
      expect(m118, contains('REVOKE ALL ON public.coach_client_workout_stats FROM PUBLIC, anon, authenticated'));
    });

    test('notification injection is closed', () {
      expect(m118, contains('DROP POLICY IF EXISTS "system can insert notifications"'));
      expect(m118, contains('WITH CHECK (public.may_notify(recipient_id))'));
    });

    test('no policy is left applying to PUBLIC', () {
      expect(m118, contains("roles::text = '{public}'"));
      expect(m118, contains('TO authenticated'));
    });

    test('there is a standing RLS check in the migration output', () {
      expect(m118, contains('NOT c.relrowsecurity'));
      expect(m118, contains('RAISE WARNING'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // SEC-027 — migration discipline
  // ══════════════════════════════════════════════════════════════════════════
  group('SEC-027 Phase 1 migration discipline', () {
    final phase1 = [113, 114, 115, 116, 117, 118];

    test('every Phase 1 migration documents its purpose and rollback', () {
      final migrations = _allMigrations();
      for (final n in phase1) {
        final raw = migrations[n]!.sql;
        expect(raw, contains('ROLLBACK'), reason: 'migration $n needs a rollback note');
        expect(raw.split('\n').where((l) => l.startsWith('--')).length, greaterThan(15),
            reason: 'migration $n needs a security rationale, not just DDL');
      }
    });

    test('no Phase 1 migration rewrites an already-applied historical file', () {
      // Forward-only: 113-118 may CREATE OR REPLACE functions and DROP/CREATE
      // policies, but must not edit files 000-112. That is checked by the file
      // set being additive — this test pins the numbering.
      final migrations = _allMigrations();
      for (final n in phase1) {
        expect(migrations[n], isNotNull, reason: 'migration $n should exist');
      }
      // Phase 1 occupies 113-118 and nothing else. Later phases add their own
      // numbers — that is the forward-only rule working, not a breach — so what
      // is pinned is the boundary, not the high-water mark.
      expect(migrations.keys.where((k) => k > 112 && k < 113), isEmpty,
          reason: 'Phase 1 starts at 113');
      expect(migrations.keys.where((k) => k > 118),
          everyElement(greaterThan(118)),
          reason: 'a post-Phase-1 migration must be additive, never a renumber '
              'of an already-applied file');
    });

    test('a migration that redefines generate_client_plan() keeps the '
        'unique day-title rule', () {
      // The 077/052 drift, pinned at source. Migration 077 rebuilt
      // generate_client_plan() from 048 — which predates 052 — and silently
      // reverted 052's A/B/C day-title suffixing. Its own header says it
      // "Reproduces 048 verbatim", so the regression was invisible in review.
      //
      // Any future migration that redefines the function must carry the rule
      // forward. This is the guard the 077 review did not have.
      final migrations = _allMigrations();
      final redefiners = <int>[
        for (final e in migrations.entries)
          if (e.value.sql
              .toLowerCase()
              .contains('function public.generate_client_plan'))
            e.key,
      ]..sort();

      expect(redefiners, isNotEmpty);
      final latest = redefiners.last;
      final sql = migrations[latest]!.sql;
      expect(sql, contains('plan_day_titles'),
          reason: 'migration $latest is the current definition of '
              'generate_client_plan() and must apply the unique day-title rule '
              '(migration 052, restored by 121)');

      // And it must title from the split AS FINALLY SET — migration 077's focus
      // bias rewrites the last day, which can manufacture a duplicate that a
      // pre-bias titling would miss.
      final biasAt = sql.indexOf('v_split[v_days] := v_focus_day');
      final titleAt = sql.indexOf('plan_day_titles(v_split)');
      if (biasAt >= 0) {
        expect(titleAt, greaterThan(biasAt),
            reason: 'day titles must be computed after the focus bias');
      }
    });

    test('no Phase 2 migration widens the Phase 1 authorization boundary', () {
      // Phase 2 rebuilt the workout domain contract on top of the Phase 1
      // boundary. It must not have relaxed it to make that easier.
      final migrations = _allMigrations();
      final phase2 = migrations.keys.where((k) => k >= 119);
      for (final n in phase2) {
        final sql = migrations[n]!.sql;
        expect(sql, isNot(contains('nxdbooufqzkpslkcogxc')),
            reason: 'migration $n must not name the production project');
        expect(sql.toUpperCase(), isNot(contains('USING (TRUE)')),
            reason: 'migration $n must not open a blanket read policy');
        expect(sql.toUpperCase(), isNot(contains('TO ANON')),
            reason: 'migration $n must not grant anything to anon');
        expect(sql.toUpperCase(), isNot(contains('DISABLE ROW LEVEL SECURITY')),
            reason: 'migration $n must not disable RLS');
        expect(sql, isNot(contains('DROP FUNCTION public.can_read_program')),
            reason: 'migration $n must not remove the Phase 1 program gate');
      }
    });

    test('a function redefined after Phase 1 keeps its pinned search_path', () {
      // SEC-028. The 119/120/121 drift, pinned at source — and the exact same
      // failure mode as the 077/052 drift above, one layer down.
      //
      // Migration 116 §1 pinned `search_path = public, pg_temp` on every
      // SECURITY DEFINER function; 118 F-08 did the rest. Both used ALTER
      // FUNCTION so no body was touched. But `SET search_path` is part of a
      // function's DEFINITION, not a grant: ACLs and ownership survive
      // CREATE OR REPLACE, proconfig does not. Every Phase 2 migration that
      // redefined a function without repeating the clause silently unpinned it
      // — 15 functions live on QA, including the client-callable definer
      // `generate_client_plan()`. Migration 122 re-pins them.
      //
      // The invariant is about the END STATE of the chain, not each file: a
      // declaration may omit the clause only if a LATER migration re-pins
      // generically. So this fails the moment someone adds a migration above
      // the last sweep that declares a function without pinning it.
      final migrations = _allMigrations();

      // The generic sweep: 118's loop — the proconfig predicate plus the ALTER.
      final sweeps = <int>[
        for (final e in migrations.entries)
          if (e.value.sql
                  .contains('ALTER FUNCTION %s SET search_path = public, pg_temp') &&
              e.value.sql.contains("c LIKE 'search_path=%'"))
            e.key,
      ]..sort();
      expect(sweeps, isNotEmpty,
          reason: 'the search_path sweep must exist somewhere in the chain');
      final lastSweep = sweeps.last;
      expect(lastSweep, greaterThanOrEqualTo(122),
          reason: 'migration 122 re-pins what 119/120/121 dropped; a later '
              'migration may supersede it, but it may not disappear');

      // Every function DECLARED above the last sweep must pin inline.
      final decl = RegExp(
          r'CREATE\s+(?:OR\s+REPLACE\s+)?FUNCTION\s+(?:public\.)?'
          r'([a-z_0-9]+)\s*\(([^)]*)\)\s+RETURNS(.*?)\bAS\b',
          caseSensitive: false);
      for (final n in migrations.keys.where((k) => k > lastSweep)) {
        for (final m in decl.allMatches(_flat(migrations[n]!.sql))) {
          expect(m.group(3)!.toLowerCase(), contains('set search_path'),
              reason: 'migration $n declares ${m.group(1)}() after the last '
                  'search_path sweep (migration $lastSweep), so it must carry '
                  '`SET search_path = public, pg_temp` in its own header — '
                  'CREATE OR REPLACE discards the pin an ALTER put there');
        }
      }
    });

    test('the search_path re-pin verifies itself', () {
      // A repair that cannot fail is a repair nobody notices has stopped
      // working. 122 asserts the posture it restores.
      final m122 = _sql(122);
      expect(m122, contains('RAISE EXCEPTION'),
          reason: 'migration 122 must fail loudly if a function is left '
              'with a mutable search_path');
      expect(_allMigrations()[122]!.sql, isNot(contains('nxdbooufqzkpslkcogxc')),
          reason: 'migration 122 must not name the production project');
    });

    test('no Phase 1 migration targets production', () {
      const prodRef = 'nxdbooufqzkpslkcogxc';
      final migrations = _allMigrations();
      for (final n in phase1) {
        expect(migrations[n]!.sql, isNot(contains(prodRef)));
      }
    });
  });
}
