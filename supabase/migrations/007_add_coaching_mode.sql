-- Add coaching_mode to user_profiles
-- Allowed values: self_guided | ai_guided | coach_guided

ALTER TABLE user_profiles
  ADD COLUMN IF NOT EXISTS coaching_mode TEXT
    DEFAULT 'self_guided'
    CHECK (coaching_mode IN ('self_guided', 'ai_guided', 'coach_guided'));

-- Backfill existing rows so the column is never null
UPDATE user_profiles
SET coaching_mode = 'self_guided'
WHERE coaching_mode IS NULL;

ALTER TABLE user_profiles
  ALTER COLUMN coaching_mode SET NOT NULL;
