-- 101_public_profiles_view.sql
--
-- PHASE 1 of the user_profiles hardening. This migration is PURELY ADDITIVE and
-- safe to apply immediately -- it breaks nothing, including app binaries already
-- installed on beta testers' phones.
--
-- Problem: user_profiles holds medical_conditions, parq_answers, injury_description,
-- date_of_birth, phone, email, risk_score, stripe_customer_id and stripe_account_id,
-- but two blanket `USING (true)` policies make every row readable by any
-- authenticated account. It cannot simply be locked down, because the app reads other
-- users' rows in ~12 places purely to show a display name (community posts and
-- comments, pods, classes, coach reviews, weekly check-ins, coach marketplace).
--
-- Fix: expose those non-sensitive fields through a dedicated view, repoint the app
-- at it (phase 2), then restrict the base table (phase 3, migration 102).
--
-- The view deliberately runs with security_invoker = off, so it reads the base table
-- as the view owner and is unaffected by the row restriction added in phase 3. Its
-- safety comes from the column list below: no medical, contact, billing or intake
-- data is projected.

CREATE OR REPLACE VIEW public.public_profiles
WITH (security_invoker = off) AS
SELECT
    -- identity (used for display names / avatars anywhere a user is shown)
    id,
    first_name,
    last_name,
    avatar_url,
    role,
    -- public coach-marketplace fields (NULL for non-coaches)
    coach_title,
    coach_bio,
    bio,
    tagline,
    specialties,
    certifications,
    years_experience,
    pricing_monthly,
    pricing_description,
    rating_avg,
    review_count,
    transformation_photo_urls,
    is_accepting_clients,
    max_clients
FROM public.user_profiles;

COMMENT ON VIEW public.public_profiles IS
  'Non-sensitive projection of user_profiles for display names and coach marketplace. '
  'Never add medical, contact, billing or intake columns to this view.';

-- Readable by signed-in users only. Deliberately NOT granted to anon: the anon key
-- is published in this public repo.
REVOKE ALL ON public.public_profiles FROM PUBLIC, anon;
GRANT SELECT ON public.public_profiles TO authenticated;
