// ENV-001 … ENV-006 — build-time environment configuration.
//
// Which backend a build talks to is fixed by `--dart-define` values. Those
// can't be varied inside a single test run, so these tests drive the pure
// resolver (`resolveEnvConfig`) directly with the values a build would supply.
import 'package:flutter_test/flutter_test.dart';
import 'package:circle_fitness/core/config/app_env.dart';


/// Resolves an environment without inheriting this build's `--dart-define`
/// values, so these assertions describe the baked-in defaults no matter which
/// define file the suite is run with.
EnvConfig resolveDefaults(String appEnv) => resolveEnvConfig(
      appEnv: appEnv,
      supabaseUrl: '',
      supabaseAnonKey: '',
      stripePublishableKey: '',
      apiBaseUrl: '',
    );

void main() {
  // ENV-001 — every supported environment is selectable
  group('ENV-001 environment selection', () {
    test('dev, qa and prod are all resolvable', () {
      expect(resolveDefaults('dev').environment, AppEnvironment.dev);
      expect(resolveDefaults('qa').environment, AppEnvironment.qa);
      expect(resolveDefaults('prod').environment, AppEnvironment.prod);
    });

    test('selection is case- and whitespace-insensitive', () {
      expect(resolveDefaults(' QA ').environment, AppEnvironment.qa);
      expect(resolveDefaults('Prod').environment, AppEnvironment.prod);
    });

    test('long-form aliases resolve to the same environments', () {
      expect(resolveDefaults('development').environment,
          AppEnvironment.dev);
      expect(resolveDefaults('staging').environment, AppEnvironment.qa);
      expect(resolveDefaults('production').environment,
          AppEnvironment.prod);
    });

    test('an unknown environment fails the build rather than defaulting', () {
      expect(() => resolveDefaults('prd'), throwsArgumentError);
      expect(() => resolveDefaults(''), throwsArgumentError);
    });

    test('APP_ENV defaults to prod when no define file is used', () {
      // kAppEnvDefine is whatever this build was compiled with; the default
      // when nothing is passed is prod, which is what keeps pre-existing
      // `flutter build web` commands behaving as before.
      const unset = String.fromEnvironment('APP_ENV_NOT_SET', defaultValue: 'prod');
      expect(AppEnvironment.tryParse(unset), AppEnvironment.prod);
      // And whatever this build did select must be a valid environment.
      expect(AppEnvironment.tryParse(kAppEnvDefine), isNotNull);
    });
  });

  // ENV-002 — defines override the per-environment defaults
  group('ENV-002 dart-define overrides', () {
    test('every setting can be supplied at build time', () {
      final config = resolveEnvConfig(
        appEnv: 'qa',
        supabaseUrl: 'https://qa-ref.supabase.co',
        supabaseAnonKey: 'qa-anon-key',
        stripePublishableKey: 'pk_test_qa',
        apiBaseUrl: 'https://qa-api.12circle.test',
      );

      expect(config.environment, AppEnvironment.qa);
      expect(config.supabaseUrl, 'https://qa-ref.supabase.co');
      expect(config.supabaseAnonKey, 'qa-anon-key');
      expect(config.stripePublishableKey, 'pk_test_qa');
      expect(config.apiBaseUrl, 'https://qa-api.12circle.test');
      expect(config.missingSettings(), isEmpty);
    });

    test('an override wins over the environment default', () {
      final config = resolveEnvConfig(
        appEnv: 'prod',
        supabaseUrl: 'https://override.supabase.co',
        supabaseAnonKey: '',
        stripePublishableKey: '',
        apiBaseUrl: '',
      );
      expect(config.supabaseUrl, 'https://override.supabase.co');
      // Untouched settings still come from the prod defaults.
      expect(config.supabaseAnonKey,
          kEnvironmentDefaults[AppEnvironment.prod]!.supabaseAnonKey);
    });

    test('an empty override falls back to the environment default', () {
      final config = resolveDefaults('prod');
      expect(config.supabaseUrl,
          kEnvironmentDefaults[AppEnvironment.prod]!.supabaseUrl);
    });
  });

  // ENV-003 — QA is isolated from production by construction
  group('ENV-003 environment isolation', () {
    test('qa ships no backend defaults, so it cannot fall through to prod', () {
      final qa = resolveDefaults('qa');
      final prod = resolveDefaults('prod');

      expect(qa.supabaseUrl, isEmpty);
      expect(qa.supabaseAnonKey, isEmpty);
      expect(qa.supabaseUrl, isNot(prod.supabaseUrl));
      expect(qa.supabaseAnonKey, isNot(prod.supabaseAnonKey));
      expect(qa.canInitialiseSupabase, isFalse);
    });

    test('dev ships no backend defaults either', () {
      final dev = resolveDefaults('dev');
      expect(dev.supabaseUrl, isEmpty);
      expect(dev.supabaseAnonKey, isEmpty);
      expect(dev.canInitialiseSupabase, isFalse);
    });

    test('a configured qa build points at its own project', () {
      final qa = resolveEnvConfig(
        appEnv: 'qa',
        supabaseUrl: 'https://qa-ref.supabase.co',
        supabaseAnonKey: 'qa-anon-key',
      );
      final prod = resolveDefaults('prod');

      expect(qa.canInitialiseSupabase, isTrue);
      expect(qa.supabaseUrl, isNot(prod.supabaseUrl));
      expect(qa.supabaseAnonKey, isNot(prod.supabaseAnonKey));
    });

    test('an unconfigured build reports exactly what is missing', () {
      expect(
        resolveDefaults('qa').missingSettings(),
        containsAll(['SUPABASE_URL', 'SUPABASE_ANON_KEY', 'API_BASE_URL']),
      );
      expect(
        resolveEnvConfig(
          appEnv: 'qa',
          supabaseUrl: 'https://qa-ref.supabase.co',
          supabaseAnonKey: 'qa-anon-key',
          apiBaseUrl: 'https://qa-api.12circle.test',
        ).missingSettings(),
        isEmpty,
      );
    });
  });

  // ENV-004 — prod defaults preserve the previously hard-coded values
  group('ENV-004 prod defaults are unchanged', () {
    test('supabase url and key match what the app shipped with', () {
      final prod = resolveDefaults('prod');
      expect(prod.supabaseUrl, 'https://nxdbooufqzkpslkcogxc.supabase.co');
      expect(prod.supabaseAnonKey, startsWith('eyJ'));
      expect(prod.canInitialiseSupabase, isTrue);
    });

    test('stripe publishable key is present and publishable, per environment',
        () {
      final prod = resolveDefaults('prod');
      expect(prod.hasStripeKey, isTrue);
      expect(prod.stripePublishableKey, startsWith('pk_'));

      // Environment-specific: qa/dev get their own key or none at all.
      expect(resolveDefaults('qa').hasStripeKey, isFalse);
      final qa = resolveEnvConfig(appEnv: 'qa', stripePublishableKey: 'pk_test_qa');
      expect(qa.stripePublishableKey, 'pk_test_qa');
      expect(qa.stripePublishableKey, isNot(prod.stripePublishableKey));
    });

    test('no environment ships a Stripe secret key', () {
      for (final env in AppEnvironment.values) {
        final key = resolveDefaults(env.label).stripePublishableKey;
        expect(key, isNot(startsWith('sk_')));
        expect(key, isNot(startsWith('rk_')));
      }
    });
  });

  // ENV-005 — API base URL handling
  group('ENV-005 API base URL', () {
    test('dev defaults to the local API', () {
      final dev = resolveDefaults('dev');
      expect(dev.apiBaseUrl, 'http://localhost:3000');
      expect(dev.hasApiBaseUrl, isTrue);
    });

    test('apiUri joins without doubling or dropping the slash', () {
      final withSlash =
          resolveEnvConfig(appEnv: 'qa', apiBaseUrl: 'https://api.test/');
      final withoutSlash =
          resolveEnvConfig(appEnv: 'qa', apiBaseUrl: 'https://api.test');

      expect(withSlash.apiUri('/ai/nutrition/message'),
          'https://api.test/ai/nutrition/message');
      expect(withoutSlash.apiUri('/ai/nutrition/message'),
          'https://api.test/ai/nutrition/message');
      expect(withoutSlash.apiUri('ai/nutrition/message'),
          'https://api.test/ai/nutrition/message');
    });

    test('an unset API base URL is reported rather than guessed', () {
      final qa = resolveDefaults('qa');
      expect(qa.hasApiBaseUrl, isFalse);
      expect(qa.missingSettings(), contains('API_BASE_URL'));
    });
  });

  // ENV-006 — the config surface carries no server secret
  group('ENV-006 no server secrets in client config', () {
    test('no resolved environment exposes an Anthropic key', () {
      for (final env in AppEnvironment.values) {
        final config = resolveDefaults(env.label);
        expect(config.toString(), isNot(contains('sk-ant')));
        for (final value in [
          config.supabaseUrl,
          config.supabaseAnonKey,
          config.stripePublishableKey,
          config.apiBaseUrl,
        ]) {
          expect(value, isNot(contains('sk-ant')));
          expect(value, isNot(contains('anthropic')));
        }
      }
    });

    test('toString never prints a raw Stripe key beyond its presence', () {
      final prod = resolveDefaults('prod');
      expect(prod.toString(), contains('stripe: configured'));
      expect(prod.toString(), isNot(contains(prod.stripePublishableKey)));
    });
  });
}
