-- ═══════════════════════════════════════════════════════════════════════════
-- Coach pricing packages + client workout schedule
-- Coaches offer multiple package types (pay-per-session, bulk, monthly).
-- Clients pick a package and confirm/modify their training days + times
-- (seeded from their onboarding training_days_per_week). The schedule drives
-- workout reminders and coach "client completed workout" notifications.
-- Idempotent — safe to run more than once.
-- ═══════════════════════════════════════════════════════════════════════════

-- ── Coach packages ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS coach_packages (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id   uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  -- 'per_session' | 'bulk' | 'monthly'
  type       text NOT NULL,
  name       text NOT NULL,
  sessions   int  NOT NULL DEFAULT 1,   -- 1 for per_session, N for bulk, 0 for monthly
  price      numeric NOT NULL DEFAULT 0,
  description text,
  active     boolean NOT NULL DEFAULT true,
  sort_order int DEFAULT 0,
  created_at timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_coach_packages_coach ON coach_packages (coach_id);

ALTER TABLE coach_packages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "all read coach packages" ON coach_packages;
CREATE POLICY "all read coach packages"
  ON coach_packages FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "coach manages own packages" ON coach_packages;
CREATE POLICY "coach manages own packages"
  ON coach_packages FOR ALL TO authenticated
  USING (coach_id = auth.uid()) WITH CHECK (coach_id = auth.uid());

-- ── Client workout schedule ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS client_schedules (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id    uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  coach_id     uuid REFERENCES user_profiles(id),
  package_id   uuid REFERENCES coach_packages(id),
  days         text[] NOT NULL DEFAULT '{}',  -- ['monday','wednesday',...]
  session_time text,                          -- 'HH:MM' preferred time
  created_at   timestamptz DEFAULT now(),
  updated_at   timestamptz DEFAULT now(),
  UNIQUE (client_id)
);
CREATE INDEX IF NOT EXISTS idx_client_schedules_coach ON client_schedules (coach_id);

ALTER TABLE client_schedules ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "client manages own schedule" ON client_schedules;
CREATE POLICY "client manages own schedule"
  ON client_schedules FOR ALL TO authenticated
  USING (client_id = auth.uid()) WITH CHECK (client_id = auth.uid());
DROP POLICY IF EXISTS "coach reads client schedules" ON client_schedules;
CREATE POLICY "coach reads client schedules"
  ON client_schedules FOR SELECT TO authenticated
  USING (coach_id = auth.uid());

DROP TRIGGER IF EXISTS client_schedules_updated_at ON client_schedules;
CREATE TRIGGER client_schedules_updated_at
  BEFORE UPDATE ON client_schedules
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
