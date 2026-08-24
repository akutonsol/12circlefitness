// ENV-010 … ENV-012 — QA/production Supabase isolation.
//
// Guards the boundary between the two Supabase projects:
//   production  12Circle Fitness  nxdbooufqzkpslkcogxc
//   QA          12Circle QA       eyqtldjqpgpljlqvpowh
//
// Two things are checked. First, the committed `dart_defines/*.json` files name
// the project they claim to. Second, whatever this binary was actually compiled
// with is internally consistent — so running
//   flutter test --dart-define-from-file=dart_defines/qa.json
// proves the real --dart-define pipeline resolves to QA, and the default run
// (no defines) proves it resolves to production.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:circle_fitness/core/config/app_env.dart';

const prodRef = 'nxdbooufqzkpslkcogxc';
const qaRef = 'eyqtldjqpgpljlqvpowh';

/// Project ref each environment must resolve to. dev has no project yet.
const refForEnvironment = <AppEnvironment, String?>{
  AppEnvironment.prod: prodRef,
  AppEnvironment.qa: qaRef,
  AppEnvironment.dev: null,
};

Directory _mobileRoot() {
  var dir = Directory.current;
  while (!File('${dir.path}/pubspec.yaml').existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) fail('Could not locate the Flutter package root');
    dir = parent;
  }
  return dir;
}

Map<String, String> _defines(String env) {
  final file = File('${_mobileRoot().path}/dart_defines/$env.json');
  expect(file.existsSync(), isTrue, reason: 'dart_defines/$env.json should exist');
  final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return raw.map((k, v) => MapEntry(k, v?.toString() ?? ''));
}

/// Reads the `ref` claim out of a Supabase anon/publishable JWT.
String? _refFromKey(String key) {
  final parts = key.split('.');
  if (parts.length != 3) return null;
  var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
  payload = payload.padRight((payload.length + 3) ~/ 4 * 4, '=');
  try {
    final claims = jsonDecode(utf8.decode(base64.decode(payload))) as Map;
    return claims['ref']?.toString();
  } catch (_) {
    return null;
  }
}

void main() {
  // ── ENV-010 — the committed QA define file points at the QA project ────────
  group('ENV-010 dart_defines/qa.json targets 12Circle QA', () {
    test('declares the qa environment', () {
      expect(_defines('qa')['APP_ENV'], 'qa');
    });

    test('URL is the QA project and not production', () {
      final url = _defines('qa')['SUPABASE_URL']!;
      expect(url, 'https://$qaRef.supabase.co');
      expect(url, contains(qaRef));
      expect(url, isNot(contains(prodRef)),
          reason: 'a QA build must never point at production');
    });

    test('anon key is issued for the QA project', () {
      final key = _defines('qa')['SUPABASE_ANON_KEY']!;
      expect(key, isNotEmpty);
      // The key carries its own project ref — a production key pasted here
      // would be caught even though the URL looked right.
      expect(_refFromKey(key), qaRef);
      expect(_refFromKey(key), isNot(prodRef));
    });

    test('carries no secret key of any kind', () {
      final d = _defines('qa');
      for (final entry in d.entries) {
        expect(entry.value, isNot(startsWith('sk_')), reason: entry.key);
        expect(entry.value, isNot(startsWith('sb_secret_')), reason: entry.key);
        expect(entry.value, isNot(contains('service_role')), reason: entry.key);
        expect(entry.value, isNot(contains('sk-ant-')), reason: entry.key);
      }
    });
  });

  // ── ENV-011 — resolving the QA defines yields QA, never production ────────
  group('ENV-011 APP_ENV=qa resolves exclusively to 12Circle QA', () {
    test('resolved config is the QA project', () {
      final d = _defines('qa');
      final config = resolveEnvConfig(
        appEnv: d['APP_ENV']!,
        supabaseUrl: d['SUPABASE_URL']!,
        supabaseAnonKey: d['SUPABASE_ANON_KEY']!,
        stripePublishableKey: d['STRIPE_PK']!,
        apiBaseUrl: d['API_BASE_URL']!,
      );

      expect(config.environment, AppEnvironment.qa);
      expect(config.supabaseUrl, contains(qaRef));
      expect(config.supabaseAnonKey, isNot(contains(prodRef)));
      expect(_refFromKey(config.supabaseAnonKey), qaRef);
      expect(config.canInitialiseSupabase, isTrue);
    });

    test('shares no backend value with the production defaults', () {
      final d = _defines('qa');
      final qa = resolveEnvConfig(
        appEnv: 'qa',
        supabaseUrl: d['SUPABASE_URL']!,
        supabaseAnonKey: d['SUPABASE_ANON_KEY']!,
      );
      // Compared against the baked-in production defaults rather than
      // resolveEnvConfig('prod'): an explicit --dart-define overrides whichever
      // environment is selected, so inside a QA build the resolver would hand
      // back QA's own values for every environment name. The constant table is
      // what production actually ships with.
      final prod = kEnvironmentDefaults[AppEnvironment.prod]!;

      expect(prod.supabaseUrl, contains(prodRef));
      expect(qa.supabaseUrl, isNot(prod.supabaseUrl));
      expect(qa.supabaseAnonKey, isNot(prod.supabaseAnonKey));
      expect(qa.supabaseUrl, isNot(contains(prodRef)));
    });
  });

  // ── ENV-012 — the compiled binary never mixes projects ────────────────────
  group('ENV-012 this build resolves to exactly one project', () {
    test('AppEnv.current URL and key agree with its declared environment', () {
      final current = AppEnv.current;
      final expectedRef = refForEnvironment[current.environment];

      if (expectedRef == null) {
        // dev ships no project; nothing to cross-check.
        expect(current.environment, AppEnvironment.dev);
        return;
      }

      expect(current.supabaseUrl, contains(expectedRef),
          reason: 'URL must belong to ${current.environment.label}');
      expect(_refFromKey(current.supabaseAnonKey), expectedRef,
          reason: 'anon key must be issued for ${current.environment.label}');

      // And crucially, nothing from any other environment leaked in.
      for (final entry in refForEnvironment.entries) {
        final otherRef = entry.value;
        if (otherRef == null || otherRef == expectedRef) continue;
        expect(current.supabaseUrl, isNot(contains(otherRef)));
        expect(current.supabaseAnonKey, isNot(contains(otherRef)));
      }
    });
  });
}
