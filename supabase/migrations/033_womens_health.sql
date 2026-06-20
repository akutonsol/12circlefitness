-- Module 18 — Women's Health: menstrual cycle tracking, symptoms, and
-- cycle-aware settings. Used to derive the current phase and phase-based
-- training / recovery / nutrition guidance (computed client-side).

-- One row per logged period.
CREATE TABLE IF NOT EXISTS cycle_logs (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  start_date  date NOT NULL,
  end_date    date,
  created_at  timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_cycle_logs_user ON cycle_logs (user_id, start_date DESC);

-- Daily symptom / mood / energy check-in.
CREATE TABLE IF NOT EXISTS cycle_symptoms (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  log_date    date NOT NULL DEFAULT current_date,
  symptoms    text[] NOT NULL DEFAULT '{}',
  energy      int,   -- 1..5
  mood        int,   -- 1..5
  flow        text,  -- none|light|medium|heavy
  notes       text,
  created_at  timestamptz DEFAULT now(),
  UNIQUE (user_id, log_date)
);
CREATE INDEX IF NOT EXISTS idx_cycle_symptoms_user ON cycle_symptoms (user_id, log_date DESC);

-- Per-user cycle settings (averages used for predictions).
CREATE TABLE IF NOT EXISTS cycle_settings (
  user_id            uuid PRIMARY KEY REFERENCES user_profiles(id) ON DELETE CASCADE,
  avg_cycle_length   int NOT NULL DEFAULT 28,
  avg_period_length  int NOT NULL DEFAULT 5,
  tracking_enabled   boolean NOT NULL DEFAULT true,
  updated_at         timestamptz DEFAULT now()
);

-- ── RLS — each user manages only their own data ─────────────────────────────
ALTER TABLE cycle_logs      ENABLE ROW LEVEL SECURITY;
ALTER TABLE cycle_symptoms  ENABLE ROW LEVEL SECURITY;
ALTER TABLE cycle_settings  ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "own cycle logs" ON cycle_logs;
CREATE POLICY "own cycle logs" ON cycle_logs FOR ALL TO authenticated
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "own cycle symptoms" ON cycle_symptoms;
CREATE POLICY "own cycle symptoms" ON cycle_symptoms FOR ALL TO authenticated
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "own cycle settings" ON cycle_settings;
CREATE POLICY "own cycle settings" ON cycle_settings FOR ALL TO authenticated
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
