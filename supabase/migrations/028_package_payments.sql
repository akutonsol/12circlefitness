-- Package payments: a client buys a coach's package (per_session / bulk one-time,
-- or monthly subscription). Extends the existing payments + subscriptions plumbing.

-- Tie a payment to the package + coach it bought.
ALTER TABLE payments ADD COLUMN IF NOT EXISTS package_id uuid REFERENCES coach_packages(id) ON DELETE SET NULL;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS coach_id   uuid REFERENCES user_profiles(id) ON DELETE SET NULL;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS sessions   int  NOT NULL DEFAULT 0;

-- The coach can see payments made to them.
DROP POLICY IF EXISTS "coach reads payments to them" ON payments;
CREATE POLICY "coach reads payments to them"
  ON payments FOR SELECT TO authenticated
  USING (coach_id = auth.uid());

-- Session credits: bought session packs grant a balance the coach draws down.
CREATE TABLE IF NOT EXISTS client_session_credits (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id       uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  coach_id        uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  package_id      uuid REFERENCES coach_packages(id) ON DELETE SET NULL,
  payment_id      uuid REFERENCES payments(id) ON DELETE SET NULL,
  sessions_total  int  NOT NULL DEFAULT 0,
  sessions_used   int  NOT NULL DEFAULT 0,
  created_at      timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_session_credits_client ON client_session_credits (client_id);
CREATE INDEX IF NOT EXISTS idx_session_credits_coach  ON client_session_credits (coach_id);

ALTER TABLE client_session_credits ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "client reads own credits" ON client_session_credits;
CREATE POLICY "client reads own credits"
  ON client_session_credits FOR SELECT TO authenticated
  USING (client_id = auth.uid());

DROP POLICY IF EXISTS "coach reads client credits" ON client_session_credits;
CREATE POLICY "coach reads client credits"
  ON client_session_credits FOR SELECT TO authenticated
  USING (coach_id = auth.uid());

-- The coach can log a used session (decrement is done via update of sessions_used).
DROP POLICY IF EXISTS "coach updates client credits" ON client_session_credits;
CREATE POLICY "coach updates client credits"
  ON client_session_credits FOR UPDATE TO authenticated
  USING (coach_id = auth.uid())
  WITH CHECK (coach_id = auth.uid());
