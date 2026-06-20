-- Nutrition logs table
CREATE TABLE IF NOT EXISTS nutrition_logs (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  meal_type    TEXT NOT NULL DEFAULT 'breakfast'
    CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack', 'protein_shake')),
  food_name    TEXT NOT NULL,
  calories     DOUBLE PRECISION NOT NULL DEFAULT 0,
  protein      DOUBLE PRECISION NOT NULL DEFAULT 0,
  carbs        DOUBLE PRECISION NOT NULL DEFAULT 0,
  fat          DOUBLE PRECISION NOT NULL DEFAULT 0,
  amount_g     DOUBLE PRECISION NOT NULL DEFAULT 0,
  serving_unit TEXT NOT NULL DEFAULT 'g',
  logged_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE nutrition_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_own_nutrition_logs" ON nutrition_logs
  FOR ALL USING (auth.uid() = user_id);

-- Index for fast date-range queries
CREATE INDEX IF NOT EXISTS nutrition_logs_user_date
  ON nutrition_logs (user_id, logged_at DESC);
