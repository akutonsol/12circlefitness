-- 013_health_assessment.sql
-- Adds PAR-Q, medical history, injury, lifestyle, dietary, and risk fields to user_profiles.

ALTER TABLE user_profiles
  ADD COLUMN IF NOT EXISTS parq_answers             JSONB        NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS medical_conditions       TEXT         NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS has_injuries             BOOLEAN      NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS injury_locations         TEXT         NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS injury_description       TEXT         NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS experience_level         TEXT         NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS worked_with_coach_before BOOLEAN      NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS sleep_hours              TEXT         NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS stress_level             INTEGER      NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS occupation               TEXT         NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS dietary_restrictions     TEXT         NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS food_allergies           TEXT         NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS target_timeline          TEXT         NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS consent_agreed           BOOLEAN      NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS consent_date             TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS risk_score               INTEGER      NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS risk_level               TEXT         NOT NULL DEFAULT 'low',
  ADD COLUMN IF NOT EXISTS risk_flags               TEXT         NOT NULL DEFAULT '';

-- Index for coach dashboards querying high-risk clients
CREATE INDEX IF NOT EXISTS idx_user_profiles_risk_level
  ON user_profiles (risk_level)
  WHERE risk_level IN ('moderate', 'high');
