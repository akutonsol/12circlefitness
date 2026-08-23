/// Build-time environment configuration for the 12 Circle Flutter client.
///
/// Nothing here is environment-specific at *runtime*: every value is resolved
/// from `--dart-define` values baked in at compile time, so a QA build can
/// never accidentally talk to the production backend.
///
/// Select an environment with:
///   flutter build web --dart-define-from-file=dart_defines/qa.json
/// or pass the individual defines:
///   flutter run --dart-define=APP_ENV=qa \
///               --dart-define=SUPABASE_URL=https://YOUR_QA_REF.supabase.co \
///               --dart-define=SUPABASE_ANON_KEY=YOUR_QA_PUBLISHABLE_KEY \
///               --dart-define=STRIPE_PK=pk_test_... \
///               --dart-define=API_BASE_URL=https://qa-api.example.com
///
/// SECURITY: only client-safe values belong in this file. The Supabase
/// publishable/anon key and the Stripe *publishable* key are designed to be
/// shipped to clients (they are protected by RLS and by Stripe's key scoping).
/// Server secrets — the Anthropic API key above all — must never appear here;
/// the AI integration is reached through the NestJS API instead.
library;

/// The environments the client can be built for.
enum AppEnvironment {
  dev,
  qa,
  prod;

  static AppEnvironment? tryParse(String value) {
    switch (value.trim().toLowerCase()) {
      case 'dev':
      case 'development':
        return AppEnvironment.dev;
      case 'qa':
      case 'staging':
        return AppEnvironment.qa;
      case 'prod':
      case 'production':
        return AppEnvironment.prod;
    }
    return null;
  }

  String get label => name;
}

/// Immutable, fully-resolved configuration for one environment.
class EnvConfig {
  final AppEnvironment environment;
  final String supabaseUrl;

  /// Supabase publishable ("anon") key — client-safe, RLS-protected.
  final String supabaseAnonKey;

  /// Stripe *publishable* key — client-safe. Never the secret key.
  final String stripePublishableKey;

  /// Base URL of the 12 Circle NestJS API (hosts the AI endpoints).
  final String apiBaseUrl;

  const EnvConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.stripePublishableKey,
    required this.apiBaseUrl,
  });

  bool get isProduction => environment == AppEnvironment.prod;
  bool get isQa => environment == AppEnvironment.qa;
  bool get isDev => environment == AppEnvironment.dev;

  /// True when Stripe.js can be initialised for in-app Embedded Checkout.
  /// When false the app falls back to hosted (redirect) checkout, exactly as
  /// it did before environments were introduced.
  bool get hasStripeKey => stripePublishableKey.isNotEmpty;

  /// True when the AI endpoints on the NestJS API are reachable.
  bool get hasApiBaseUrl => apiBaseUrl.isNotEmpty;

  /// Joins [path] onto [apiBaseUrl] without doubling or dropping the slash.
  String apiUri(String path) {
    final base = apiBaseUrl.endsWith('/')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;
    final suffix = path.startsWith('/') ? path : '/$path';
    return '$base$suffix';
  }

  /// Human-readable list of anything a build of this environment is missing.
  /// Empty means the build is fully configured.
  List<String> missingSettings() => [
        if (supabaseUrl.isEmpty) 'SUPABASE_URL',
        if (supabaseAnonKey.isEmpty) 'SUPABASE_ANON_KEY',
        if (apiBaseUrl.isEmpty) 'API_BASE_URL',
      ];

  /// Supabase can be initialised (Stripe/API are checked at point of use).
  bool get canInitialiseSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  @override
  String toString() =>
      'EnvConfig(${environment.label}, supabaseUrl: $supabaseUrl, '
      'api: ${apiBaseUrl.isEmpty ? '<unset>' : apiBaseUrl}, '
      'stripe: ${hasStripeKey ? 'configured' : '<unset>'})';
}

// ── Baked-in defaults ────────────────────────────────────────────────────────
//
// `prod` carries the values that used to be hard-coded in app_constants.dart /
// stripe_config.dart, so existing build commands keep working unchanged.
// `dev` and `qa` deliberately ship *no* backend defaults: an isolated QA run
// must be pointed at its own project explicitly, so it can never silently fall
// through to production data.

const String _prodSupabaseUrl = 'https://nxdbooufqzkpslkcogxc.supabase.co';
const String _prodSupabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im54ZGJvb3VmcXprcHNsa2NvZ3hjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEwMjA4NzksImV4cCI6MjA5NjU5Njg3OX0.D0rl8hxQmDjqknsDCPRuKK1uyIYruSMjycHmNTI-xcE';
const String _prodStripePublishableKey =
    'pk_test_51TjY6fLwsDN0E0HCYEjmJTW7kJlJAC81nHgNVtRfDpWJFcZ133ob0zSeSqJQoDw4BqqJsdlTOieOWSif2CYzzSrh00BXlrGnFb';

/// Per-environment defaults, overridable by the matching `--dart-define`.
const Map<AppEnvironment, EnvConfig> kEnvironmentDefaults = {
  AppEnvironment.dev: EnvConfig(
    environment: AppEnvironment.dev,
    supabaseUrl: '',
    supabaseAnonKey: '',
    stripePublishableKey: '',
    apiBaseUrl: 'http://localhost:3000',
  ),
  AppEnvironment.qa: EnvConfig(
    environment: AppEnvironment.qa,
    supabaseUrl: '',
    supabaseAnonKey: '',
    stripePublishableKey: '',
    apiBaseUrl: '',
  ),
  AppEnvironment.prod: EnvConfig(
    environment: AppEnvironment.prod,
    supabaseUrl: _prodSupabaseUrl,
    supabaseAnonKey: _prodSupabaseAnonKey,
    stripePublishableKey: _prodStripePublishableKey,
    apiBaseUrl: '',
  ),
};

// ── Compile-time defines ─────────────────────────────────────────────────────

const String kAppEnvDefine =
    String.fromEnvironment('APP_ENV', defaultValue: 'prod');
const String kSupabaseUrlDefine = String.fromEnvironment('SUPABASE_URL');
const String kSupabaseAnonKeyDefine =
    String.fromEnvironment('SUPABASE_ANON_KEY');
const String kStripePkDefine = String.fromEnvironment('STRIPE_PK');
const String kApiBaseUrlDefine = String.fromEnvironment('API_BASE_URL');

/// Resolves an [EnvConfig] from raw define values.
///
/// Pure and side-effect free so it can be exercised directly in tests with
/// arbitrary inputs — `--dart-define` values cannot be varied within a test
/// run. Precedence: an explicit define wins; otherwise the environment default.
///
/// Throws [ArgumentError] when [appEnv] is not one of dev/qa/prod, so a typo in
/// a build command fails the build rather than silently shipping production
/// configuration.
EnvConfig resolveEnvConfig({
  String appEnv = kAppEnvDefine,
  String supabaseUrl = kSupabaseUrlDefine,
  String supabaseAnonKey = kSupabaseAnonKeyDefine,
  String stripePublishableKey = kStripePkDefine,
  String apiBaseUrl = kApiBaseUrlDefine,
}) {
  final environment = AppEnvironment.tryParse(appEnv);
  if (environment == null) {
    throw ArgumentError.value(
      appEnv,
      'APP_ENV',
      'Unknown environment. Expected one of: dev, qa, prod',
    );
  }

  final defaults = kEnvironmentDefaults[environment]!;
  String pick(String override, String fallback) =>
      override.isNotEmpty ? override : fallback;

  return EnvConfig(
    environment: environment,
    supabaseUrl: pick(supabaseUrl, defaults.supabaseUrl),
    supabaseAnonKey: pick(supabaseAnonKey, defaults.supabaseAnonKey),
    stripePublishableKey:
        pick(stripePublishableKey, defaults.stripePublishableKey),
    apiBaseUrl: pick(apiBaseUrl, defaults.apiBaseUrl),
  );
}

/// The environment this binary was built for.
class AppEnv {
  AppEnv._();

  static final EnvConfig current = resolveEnvConfig();
}
