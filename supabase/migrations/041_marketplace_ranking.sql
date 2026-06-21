-- ════════════════════════════════════════════════════════════════════════
-- Marketplace ranking with an Elite-coach boost.
-- Clients can't read other users' subscriptions (RLS), so ranking by plan tier
-- has to run server-side. This SECURITY DEFINER function returns every coach
-- with their active platform plan tier and a blended rank_score:
--   score = rating (0–5) + review-volume bump (≤1) + tier boost
--   tier boost: elite +1.5, growth +0.75, starter +0.25, none 0
-- Elite coaches surface at the top without burying a genuinely 5-star coach
-- under an unrated one. is_featured flags elite/growth for a marketplace badge.
-- Idempotent.
-- ════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.marketplace_coaches()
RETURNS TABLE (
  id              uuid,
  first_name      text,
  last_name       text,
  avatar_url      text,
  coach_title     text,
  tagline         text,
  bio             text,
  specialties     text[],
  certifications  text[],
  pricing_monthly numeric,
  years_experience int,
  rating_avg      numeric,
  review_count    int,
  plan_tier       text,
  is_featured     boolean,
  rank_score      numeric
)
LANGUAGE sql STABLE SECURITY DEFINER AS $$
  WITH coach_tier AS (
    SELECT s.user_id,
           (ARRAY_AGG(s.plan_tier ORDER BY CASE s.plan_tier
              WHEN 'elite' THEN 0 WHEN 'growth' THEN 1 ELSE 2 END))[1] AS tier
      FROM subscriptions s
     WHERE s.kind = 'coach_plan'
       AND s.status IN ('active', 'trialing')
       AND (s.current_period_end IS NULL OR s.current_period_end > now())
     GROUP BY s.user_id
  )
  SELECT p.id, p.first_name, p.last_name, p.avatar_url, p.coach_title,
         p.tagline, p.bio, p.specialties, p.certifications, p.pricing_monthly,
         p.years_experience, p.rating_avg, p.review_count,
         ct.tier AS plan_tier,
         (ct.tier IN ('elite', 'growth')) AS is_featured,
         ( COALESCE(p.rating_avg, 0)
           + LEAST(COALESCE(p.review_count, 0), 50) / 50.0
           + CASE ct.tier
               WHEN 'elite'  THEN 1.5
               WHEN 'growth' THEN 0.75
               WHEN 'starter' THEN 0.25
               ELSE 0 END
         ) AS rank_score
    FROM user_profiles p
    LEFT JOIN coach_tier ct ON ct.user_id = p.id
   WHERE p.role = 'coach'
   ORDER BY rank_score DESC, p.rating_avg DESC NULLS LAST, p.review_count DESC NULLS LAST;
$$;

GRANT EXECUTE ON FUNCTION public.marketplace_coaches() TO authenticated;
