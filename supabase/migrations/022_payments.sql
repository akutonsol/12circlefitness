-- ═══════════════════════════════════════════════════════════════════════════
-- 12 Circle Fitness — Module 16 (Payments / Stripe)
-- Tables for recurring subscriptions (coach + App Pro) and one-time payments
-- (event tickets). All writes happen from the Stripe webhook via service_role,
-- which bypasses RLS — so RLS here only needs to grant each user read access to
-- their own rows (and coaches read of their subscribers).
-- Idempotent — safe to run more than once.
-- ═══════════════════════════════════════════════════════════════════════════

-- Stripe customer handle on the profile (one customer per user).
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS stripe_customer_id text;

-- ── Subscriptions (recurring) ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS subscriptions (
  id                     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  -- 'coach'        → client subscribing to a coach (coach_id set)
  -- 'self_guided'  → platform membership $29/mo (coach_id null)
  -- 'ai_guided'    → platform membership $59/mo (coach_id null)
  kind                   text NOT NULL,
  coach_id               uuid REFERENCES user_profiles(id),
  stripe_subscription_id text UNIQUE,
  stripe_price_id        text,
  status                 text NOT NULL DEFAULT 'incomplete',
  current_period_end     timestamptz,
  cancel_at_period_end   boolean DEFAULT false,
  created_at             timestamptz DEFAULT now(),
  updated_at             timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user  ON subscriptions (user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_coach ON subscriptions (coach_id);

-- ── Payments (one-time, e.g. event tickets) ─────────────────────────────────
CREATE TABLE IF NOT EXISTS payments (
  id                        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                   uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  kind                      text NOT NULL DEFAULT 'event_ticket',
  event_id                  uuid REFERENCES events(id) ON DELETE SET NULL,
  amount_cents              int NOT NULL DEFAULT 0,
  currency                  text NOT NULL DEFAULT 'usd',
  stripe_payment_intent_id  text,
  stripe_checkout_session_id text UNIQUE,
  status                    text NOT NULL DEFAULT 'pending',
  created_at                timestamptz DEFAULT now(),
  updated_at                timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_payments_user  ON payments (user_id);
CREATE INDEX IF NOT EXISTS idx_payments_event ON payments (event_id);

-- Link a registration to the payment that unlocked it (paid events).
ALTER TABLE event_registrations ADD COLUMN IF NOT EXISTS payment_id uuid REFERENCES payments(id);
ALTER TABLE event_registrations ADD COLUMN IF NOT EXISTS paid boolean DEFAULT false;

-- ── RLS ─────────────────────────────────────────────────────────────────────
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments      ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "users read own subscriptions" ON subscriptions;
CREATE POLICY "users read own subscriptions"
  ON subscriptions FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR coach_id = auth.uid());

DROP POLICY IF EXISTS "users read own payments" ON payments;
CREATE POLICY "users read own payments"
  ON payments FOR SELECT TO authenticated
  USING (user_id = auth.uid());

DROP TRIGGER IF EXISTS subscriptions_updated_at ON subscriptions;
CREATE TRIGGER subscriptions_updated_at
  BEFORE UPDATE ON subscriptions
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS payments_updated_at ON payments;
CREATE TRIGGER payments_updated_at
  BEFORE UPDATE ON payments
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ── Convenience: the current user's active platform membership tier ─────────
-- Returns 'ai_guided' or 'self_guided' (ai outranks self), or null if neither.
-- Gate platform features on this; coach subscriptions are separate.
CREATE OR REPLACE FUNCTION public.active_membership()
RETURNS text LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT kind FROM subscriptions
  WHERE user_id = auth.uid()
    AND kind IN ('self_guided', 'ai_guided')
    AND status IN ('active', 'trialing')
    AND (current_period_end IS NULL OR current_period_end > now())
  ORDER BY CASE kind WHEN 'ai_guided' THEN 0 ELSE 1 END
  LIMIT 1;
$$;

GRANT EXECUTE ON FUNCTION public.active_membership() TO authenticated;
