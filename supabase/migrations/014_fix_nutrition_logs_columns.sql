-- 014: Ensure nutrition_logs has serving_unit and created_at columns.
-- Migration 012 used CREATE TABLE IF NOT EXISTS which was a no-op when
-- migration 006 had already created the table without these columns.

ALTER TABLE nutrition_logs
  ADD COLUMN IF NOT EXISTS serving_unit TEXT NOT NULL DEFAULT 'g',
  ADD COLUMN IF NOT EXISTS created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW();
