-- ═══════════════════════════════════════════════════════════════════════════
-- 12 Circle Fitness — Module 29 (Coach Notes) + Module 34 (Goal Management)
-- Idempotent — safe to run more than once.
-- ═══════════════════════════════════════════════════════════════════════════

-- ── COACH NOTES (Module 29) ─────────────────────────────────────────────────
-- Private notes a coach keeps on a client. Visible only to the coach (and the
-- admin layer later) — never to the client.
CREATE TABLE IF NOT EXISTS coach_notes (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id   uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  client_id  uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  body       text NOT NULL,
  -- injury | motivation | adherence | program | general
  tag        text NOT NULL DEFAULT 'general',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_coach_notes_coach  ON coach_notes (coach_id);
CREATE INDEX IF NOT EXISTS idx_coach_notes_client ON coach_notes (client_id);

ALTER TABLE coach_notes ENABLE ROW LEVEL SECURITY;

-- ONLY the authoring coach can read/write — the client must never see these.
DROP POLICY IF EXISTS "coach manages own notes" ON coach_notes;
CREATE POLICY "coach manages own notes"
  ON coach_notes FOR ALL TO authenticated
  USING (coach_id = auth.uid())
  WITH CHECK (coach_id = auth.uid());

DROP TRIGGER IF EXISTS coach_notes_updated_at ON coach_notes;
CREATE TRIGGER coach_notes_updated_at
  BEFORE UPDATE ON coach_notes
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ── GOALS (Module 34) ───────────────────────────────────────────────────────
-- Client (or coach) goals with progress tracking and completion %.
CREATE TABLE IF NOT EXISTS goals (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id     uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  coach_id      uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
  title         text NOT NULL,
  -- weight_loss | muscle_gain | body_fat | event_prep | wellness | performance
  type          text NOT NULL DEFAULT 'wellness',
  start_value   numeric,
  current_value numeric,
  target_value  numeric,
  unit          text DEFAULT '',
  target_date   date,
  -- active | completed | abandoned
  status        text NOT NULL DEFAULT 'active',
  completed_at  timestamptz,
  created_at    timestamptz DEFAULT now(),
  updated_at    timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_goals_client ON goals (client_id);
CREATE INDEX IF NOT EXISTS idx_goals_status ON goals (status);

ALTER TABLE goals ENABLE ROW LEVEL SECURITY;

-- Client manages own goals; assigned coach can read/update.
DROP POLICY IF EXISTS "client manages own goals" ON goals;
CREATE POLICY "client manages own goals"
  ON goals FOR ALL TO authenticated
  USING (client_id = auth.uid())
  WITH CHECK (client_id = auth.uid());

DROP POLICY IF EXISTS "coach reads client goals" ON goals;
CREATE POLICY "coach reads client goals"
  ON goals FOR SELECT TO authenticated
  USING (coach_id = auth.uid());

DROP POLICY IF EXISTS "coach updates client goals" ON goals;
CREATE POLICY "coach updates client goals"
  ON goals FOR UPDATE TO authenticated
  USING (coach_id = auth.uid());

DROP TRIGGER IF EXISTS goals_updated_at ON goals;
CREATE TRIGGER goals_updated_at
  BEFORE UPDATE ON goals
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE goals;
EXCEPTION WHEN others THEN NULL; END $$;
