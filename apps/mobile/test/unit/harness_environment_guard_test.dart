// ENV-020 … ENV-022 — production-contact hygiene in the TEST HARNESSES
// (Workstream N).
//
// `qa_environment_isolation_test.dart` proves that a BUILD of the app resolves
// to exactly one project: qa.json names QA, an unconfigured build names prod,
// and the two share no backend value. That guard is sound and this file does
// not duplicate it.
//
// It does not cover the other way the tree can reach a Supabase project: the
// write-capable harnesses under `tool/` and `integration_test/`, which are run
// by hand, are named for QA, and do not go through `AppEnv` at all. Every one of
// them currently resolves to PRODUCTION:
//
//   tool/live_integration_test.dart   hardcodes the prod ref; POST/PATCH/DELETE
//                                     on workout_sessions, nutrition_logs,
//                                     daily_scores, weekly_checkins, posts
//   tool/qa_self_guided.dart          hardcodes the prod ref; PATCHes
//                                     user_profiles, calls generate_client_plan
//   tool/qa_entitlements.dart         hardcodes the prod ref; service-role
//                                     DELETEs on subscriptions and
//                                     coach_client_relationships
//   integration_test/service_logic_test.dart
//                                     resolves through AppConstants -> AppEnv,
//                                     which DEFAULTS TO PROD, and its own run
//                                     instructions pass no --dart-define-from-file
//
// These guards assert what is TRUE today and ratchet it. The allowlist is a
// SHRINKING one: repointing a harness at QA is a one-line deletion here, and a
// NEW write-capable harness aimed at production fails immediately.
//
// Nothing in this file contacts any Supabase project. It reads committed source.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const prodRef = 'nxdbooufqzkpslkcogxc';
const qaRef = 'eyqtldjqpgpljlqvpowh';

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

Iterable<File> _dartFilesUnder(String relative) sync* {
  final dir = Directory('${_mobileRoot().path}/$relative');
  if (!dir.existsSync()) return;
  for (final e in dir.listSync(recursive: true)) {
    if (e is File && e.path.endsWith('.dart')) yield e;
  }
}

String _relative(File f) => f.path.split('/apps/mobile/').last;

/// A harness that can change server state, as opposed to one that only reads.
final _writeVerb = RegExp(
    r"'(POST|PATCH|PUT|DELETE)'|\.insert\(|\.upsert\(|\.update\(|\.delete\(");

void main() {
  // ── ENV-020 · the harnesses that name a project directly ──────────────────
  group('ENV-020 no NEW harness hardcodes the production project', () {
    // Recorded 2026-08-24. Each of these hardcodes the production ref AND
    // writes. Delete an entry when it is repointed at QA (or made to take the
    // target as an argument). Do not add an entry to silence a new failure.
    const knownProdTargeted = {
      'tool/live_integration_test.dart',
      'tool/qa_self_guided.dart',
      'tool/qa_entitlements.dart',
    };

    test('the set of prod-targeted harnesses has not grown', () {
      final hits = <String>{};
      for (final relative in ['tool', 'integration_test']) {
        for (final f in _dartFilesUnder(relative)) {
          if (f.readAsStringSync().contains(prodRef)) hits.add(_relative(f));
        }
      }
      printOnFailure(hits.join('\n'));

      expect(hits.difference(knownProdTargeted), isEmpty,
          reason: 'a harness under tool/ or integration_test/ names the '
              'PRODUCTION project. These are run by hand against real accounts '
              'and they write. Point it at QA, or take the project as an '
              'argument with no default.');

      expect(knownProdTargeted.difference(hits), isEmpty,
          reason: 'a recorded harness no longer names production — delete it '
              'from `knownProdTargeted` so the guard tightens');
    });

    test('each recorded harness is genuinely write-capable, which is why it '
        'is recorded', () {
      for (final relative in knownProdTargeted) {
        final src = File('${_mobileRoot().path}/$relative').readAsStringSync();
        expect(_writeVerb.hasMatch(src), isTrue,
            reason: '$relative was recorded as a write-capable prod-targeted '
                'harness; if it is now read-only, say so here');
      }
    });

    test('no harness carries a service_role key in source', () {
      // A hardcoded ref is a contamination risk; a hardcoded service-role key
      // would be an unbounded one. This is the line that must never be crossed.
      for (final relative in ['tool', 'integration_test']) {
        for (final f in _dartFilesUnder(relative)) {
          final src = f.readAsStringSync();
          expect(src.contains('"role":"service_role"'), isFalse,
              reason: '${_relative(f)} embeds a service-role JWT');
          expect(RegExp(r'service_role_key\s*=\s*.[A-Za-z0-9]').hasMatch(src),
              isFalse,
              reason: '${_relative(f)} embeds a service-role key');
        }
      }
    });
  });

  // ── ENV-021 · the harness that inherits the app's default ─────────────────
  group('ENV-021 the in-app integration harness inherits the prod default', () {
    late final String src = File(
            '${_mobileRoot().path}/integration_test/service_logic_test.dart')
        .readAsStringSync();

    test('it resolves its project through AppEnv, not a literal', () {
      expect(src, contains('AppConstants.supabaseUrl'));
      expect(src.contains(prodRef), isFalse);
      expect(src.contains(qaRef), isFalse);
    });

    test('DEFECT: it writes, and AppEnv defaults to prod, so the documented '
        'invocation targets production', () {
      // `env_config_test.dart` ENV-001 pins the default: "APP_ENV defaults to
      // prod when no define file is used". This harness's own run instructions
      // pass no --dart-define-from-file, so the two facts compose into a
      // production write from a file named "integration test".
      expect(_writeVerb.hasMatch(src), isTrue);
      expect(src, contains('flutter test integration_test/service_logic_test.dart -d macos'));
      expect(src.contains('--dart-define-from-file'), isFalse,
          reason: 'if this now fails because the instructions name a defines '
              'file, delete this test — the finding is closed');
    });

    test('it signs in as a shared seeded account, so a failed teardown is '
        'visible to other testers', () {
      expect(src, contains('test@12circle.app'));
    });
  });

  // ── ENV-022 · the QA project is never named by the shipped app ────────────
  group('ENV-022 QA and production stay separated in the committed tree', () {
    test('lib/ names both refs only as environment defaults', () {
      // AppEnv is the one place allowed to know both, because knowing both is
      // its job. Anywhere else is a hardcoded target.
      final naming = <String>[];
      for (final f in _dartFilesUnder('lib')) {
        final src = f.readAsStringSync();
        if (src.contains(prodRef) || src.contains(qaRef)) naming.add(_relative(f));
      }
      expect(naming, ['lib/core/config/app_env.dart']);
    });

    test('the keep-alive workflow pings production and writes nothing', () {
      // The only automated job in the repo that touches a real project. It is
      // read-only by construction; that is what makes it safe to run daily.
      var dir = _mobileRoot();
      while (!Directory('${dir.path}/.github').existsSync()) {
        dir = dir.parent;
      }
      final wf = File('${dir.path}/.github/workflows/supabase-keepalive.yml');
      expect(wf.existsSync(), isTrue);
      final src = wf.readAsStringSync();
      expect(src, contains(prodRef));
      expect(RegExp(r'-X\s+(POST|PATCH|PUT|DELETE)').hasMatch(src), isFalse,
          reason: 'the keep-alive must stay a read-only GET');
      expect(src.contains('service_role'), isFalse);
    });
  });
}
