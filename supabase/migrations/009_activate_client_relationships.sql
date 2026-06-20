-- Fix relationships that were set to 'pending' by the onboarding upsert
-- when the coach had is_accepting_clients = TRUE.
-- Going forward, the onboarding flow creates relationships as 'active' directly.

UPDATE coach_client_relationships ccr
SET
  status       = 'active',
  activated_at = COALESCE(activated_at, pending_at, NOW())
FROM user_profiles coach_profile
WHERE ccr.coach_id = coach_profile.id
  AND ccr.status   = 'pending'
  AND coach_profile.is_accepting_clients = TRUE;
