-- ════════════════════════════════════════════════════════════════════════
-- Billing polish — close the remaining gaps in the Stripe Connect spec:
--   • persist whether the coach finished Stripe onboarding (details_submitted)
--   • richer coach services: a cancellation policy + structured features list
-- (Note: user_profiles.onboarding_complete already means *client* onboarding,
--  so Connect onboarding gets its own column.)
-- Idempotent.
-- ════════════════════════════════════════════════════════════════════════

ALTER TABLE user_profiles
  ADD COLUMN IF NOT EXISTS stripe_details_submitted boolean NOT NULL DEFAULT false;

ALTER TABLE coach_packages
  ADD COLUMN IF NOT EXISTS cancellation_policy text;
ALTER TABLE coach_packages
  ADD COLUMN IF NOT EXISTS features text[] NOT NULL DEFAULT '{}';
