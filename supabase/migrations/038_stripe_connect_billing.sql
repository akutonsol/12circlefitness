-- ════════════════════════════════════════════════════════════════════════
-- Billing architecture refactor — Stripe Connect.
-- Platform subscriptions (Self/AI, Coach Starter/Growth/Elite) → 12 Circle's
-- own Stripe account. Coaching subscriptions/packages → the COACH's connected
-- Stripe account (destination charge), with the platform taking a commission
-- (application fee). coach_invited clients = 0%; marketplace = configurable %.
-- ════════════════════════════════════════════════════════════════════════

-- ── Coach's connected Stripe account ────────────────────────────────────────
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS stripe_account_id text;          -- acct_…
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS stripe_charges_enabled boolean NOT NULL DEFAULT false;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS stripe_payouts_enabled boolean NOT NULL DEFAULT false;
-- Commission charged to a MARKETPLACE-acquired client's coaching payments (0–1).
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS marketplace_commission_rate numeric NOT NULL DEFAULT 0.10;

-- ── How a client came to the coach (drives commission) ──────────────────────
ALTER TABLE coach_client_relationships
  ADD COLUMN IF NOT EXISTS client_source text NOT NULL DEFAULT 'marketplace'; -- 'coach_invited' | 'marketplace'

-- ── Money split, recorded on each coaching charge / subscription ────────────
ALTER TABLE payments ADD COLUMN IF NOT EXISTS service_id        uuid REFERENCES coach_packages(id) ON DELETE SET NULL;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS client_source     text;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS commission_rate   numeric;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS coach_payout      int;   -- cents to the coach
ALTER TABLE payments ADD COLUMN IF NOT EXISTS platform_fee      int;   -- cents to 12 Circle
ALTER TABLE payments ADD COLUMN IF NOT EXISTS stripe_account_id text;  -- destination acct

ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS service_id        uuid REFERENCES coach_packages(id) ON DELETE SET NULL;
ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS client_source     text;
ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS commission_rate   numeric;
ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS coach_payout      int;
ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS platform_fee      int;
ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS stripe_account_id text;

-- Backfill existing relationships: invited clients (came via a coach_invite) → 0%.
UPDATE coach_client_relationships r
   SET client_source = 'coach_invited'
  FROM coach_invites i
 WHERE i.coach_id = r.coach_id
   AND lower(i.email) = (SELECT lower(email) FROM user_profiles p WHERE p.id = r.client_id)
   AND r.client_source = 'marketplace';
