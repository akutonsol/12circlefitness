-- Ensure columns required for onboarding resume exist.
-- These may already be present on live instances created via the dashboard;
-- IF NOT EXISTS makes this migration safe to run multiple times.

ALTER TABLE user_profiles
  ADD COLUMN IF NOT EXISTS onboarding_complete BOOLEAN DEFAULT FALSE;

ALTER TABLE user_profiles
  ADD COLUMN IF NOT EXISTS onboarding_step INTEGER DEFAULT 0;

-- Backfill: users who reached home are complete; everyone else is step 0
UPDATE user_profiles
SET onboarding_complete = TRUE
WHERE onboarding_complete IS NULL;

UPDATE user_profiles
SET onboarding_step = 0
WHERE onboarding_step IS NULL;
