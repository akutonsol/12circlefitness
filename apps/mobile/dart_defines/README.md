# Build-time environment configuration

Every backend value the Flutter client uses is chosen at **build time** via
`--dart-define`, so a QA binary can never reach production data. The resolver
lives in [`lib/core/config/app_env.dart`](../lib/core/config/app_env.dart).

```bash
flutter run   -d chrome --dart-define-from-file=dart_defines/dev.json
flutter build web       --dart-define-from-file=dart_defines/qa.json
flutter build web       --dart-define-from-file=dart_defines/prod.json
```

## Defines

| Define | Meaning | Client-safe? |
|---|---|---|
| `APP_ENV` | `dev` \| `qa` \| `prod`. Unknown values fail the build. Defaults to `prod`. | n/a |
| `SUPABASE_URL` | Supabase project URL for the environment. | yes |
| `SUPABASE_ANON_KEY` | Supabase publishable/anon key (RLS-protected). | yes |
| `STRIPE_PK` | Stripe **publishable** key (`pk_test_…` / `pk_live_…`). Never the secret key. | yes |
| `API_BASE_URL` | Base URL of the 12 Circle NestJS API. Hosts the AI endpoints. | yes |

An empty value falls back to that environment's default. Only `prod` ships
defaults (the values that used to be hard-coded); `dev` and `qa` must be
pointed at their own Supabase project explicitly — that's what keeps an
isolated QA run isolated. A missing setting is reported at startup rather than
silently falling through to production.

## What must never be here

Server secrets — the Anthropic API key above all. The AI nutrition feature
calls `POST {API_BASE_URL}/ai/nutrition/message` on the NestJS API, which holds
`ANTHROPIC_API_KEY` server-side. `test/unit/client_secret_hygiene_test.dart`
and `tool/check_web_build_secrets.sh` fail the build if a secret leaks into the
client.

## Filling these in

These files are committed as templates with empty values. Fill in the
environment you own, or keep them empty and pass the values from your CI
secret store:

```bash
flutter build web \
  --dart-define=APP_ENV=qa \
  --dart-define=SUPABASE_URL="$QA_SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$QA_SUPABASE_ANON_KEY" \
  --dart-define=STRIPE_PK="$QA_STRIPE_PK" \
  --dart-define=API_BASE_URL="$QA_API_BASE_URL"
```

## What is and isn't isolated

**Runtime configuration is fully isolated.** A `qa` build resolves only QA
values; it cannot reach the production Supabase project. `test/unit/env_config_test.dart`
covers this (`ENV-003 environment isolation`).

**The compiled bundle still contains the `prod` default strings.** The
per-environment default table is a runtime lookup, so dart2js keeps all three
entries regardless of which environment you build. That's not a leak — the
production Supabase URL, its publishable/anon key and the Stripe publishable
key are public by design (the anon key is already committed to
`.github/workflows/`, and RLS is what protects the data). No secret is
affected: `tool/check_web_build_secrets.sh` scans every build artifact for
credential material.
