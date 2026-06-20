-- ── 006: Create nutrition_logs table ─────────────────────────────────────────
-- Migration 003 added RLS policies for this table but it was never created.
-- This migration creates it (IF NOT EXISTS so it is safe to re-run).

CREATE TABLE IF NOT EXISTS nutrition_logs (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid REFERENCES user_profiles(id) ON DELETE CASCADE,
  meal_type   text NOT NULL DEFAULT 'breakfast',
  food_name   text NOT NULL,
  calories    numeric DEFAULT 0,
  protein     numeric DEFAULT 0,
  carbs       numeric DEFAULT 0,
  fat         numeric DEFAULT 0,
  amount_g    numeric DEFAULT 0,
  logged_at   timestamptz DEFAULT now()
);

-- Enable RLS (no-op if already enabled by migration 003)
ALTER TABLE nutrition_logs ENABLE ROW LEVEL SECURITY;

-- Policies (DROP IF EXISTS so they are idempotent alongside migration 003)
DROP POLICY IF EXISTS "users manage own nutrition logs" ON nutrition_logs;
CREATE POLICY "users manage own nutrition logs"
  ON nutrition_logs FOR ALL TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "coaches read client nutrition logs" ON nutrition_logs;
CREATE POLICY "coaches read client nutrition logs"
  ON nutrition_logs FOR SELECT TO authenticated
  USING (true);
