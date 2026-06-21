# Stripe Connect — billing architecture

Two separate money flows:

| Flow | Goes to | Stripe pieces |
|---|---|---|
| **Platform subscriptions** — Self-Guided $29, AI-Guided $59, Coach Starter/Growth/Elite | **12 Circle's** Stripe account | `create-checkout` kinds `self_guided`/`ai_guided`/`coach_plan` (unchanged) |
| **Coaching** — client → coach packages & monthly plans | **The coach's connected** Stripe account (destination charge) | `create-checkout` kinds `coach`/`package`/`package_monthly` + Connect |

12 Circle only collects **SaaS subscription revenue + marketplace commissions** — not the coaching revenue.

## Commission
- `coach_invited` clients → **0%** (coach keeps 100%).
- `marketplace` clients → **`user_profiles.marketplace_commission_rate`** (default **10%**), applied as the Stripe `application_fee`.
- Source is stored on `coach_client_relationships.client_source`; the split (`commission_rate`, `platform_fee`, `coach_payout`, `stripe_account_id`, `service_id`) is stored on the `payments` / `subscriptions` row.

## One-time setup (Stripe Dashboard — required before this works)
1. **Enable Connect**: Stripe Dashboard → **Connect** → get started (test mode). Choose **Express** accounts.
2. Set the platform business profile / branding for Connect onboarding.
3. No new secrets needed — uses the existing `STRIPE_SECRET_KEY` (the platform account). The webhook should also receive events for connected accounts (default platform webhook covers `checkout.session.completed`).

## Apply / deploy
- DB: run migration **038_stripe_connect_billing.sql** (in `APPLY_ALL.sql`).
- Functions (already deployed): `stripe-connect`, `create-checkout`, `stripe-webhook`.

## Coach flow (in app)
Coach dashboard → **Tools → Payments** (`/coach-payments`) → **Connect Stripe** → completes Stripe Express onboarding → returns to the app. Until `charges_enabled` is true, the coach sees a "Connect your Stripe account" banner on the Packages screen, and **clients cannot check out** that coach's packages (`create-checkout` returns 409 "coach has not finished setting up payments").

## Notes / TODO
- New coach-invited relationships should set `client_source='coach_invited'` at creation (migration backfills existing ones by matching `coach_invites.email`). The marketplace request path defaults to `marketplace`.
- Connected-account refunds/disputes and a coach earnings dashboard are future work.
