-- ═══════════════════════════════════════════════════════════════════════════
-- 081 — Intake "Pick your Activities" step
-- Adds the activities column collected by the new onboarding step
-- (Running / Cycling / Swimming / Yoga / Hiking, multi-select). Idempotent.
-- ═══════════════════════════════════════════════════════════════════════════

ALTER TABLE user_profiles
  ADD COLUMN IF NOT EXISTS activities text[] DEFAULT '{}';
