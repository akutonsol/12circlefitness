-- Migration 046: marketplace pricing parity with the intake coach picker.
--
-- The intake picker falls back to a coach's cheapest active monthly package
-- price when they haven't set a profile rate (coach_provider.dart). This makes
-- marketplace_coaches() do the same so pricing is consistent across both
-- surfaces: profile rate wins, else the lowest active monthly package, else 0
-- (the UI shows "Flexible pricing" for 0). Re-declares the function so the
-- pricing_monthly column reflects the effective price. Idempotent.

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
  ),
  pkg_price AS (
    SELECT cp.coach_id, MIN(cp.price) AS lowest_monthly
      FROM coach_packages cp
     WHERE cp.active = true
       AND cp.type = 'monthly'
       AND cp.price > 0
     GROUP BY cp.coach_id
  )
  SELECT p.id, p.first_name, p.last_name, p.avatar_url, p.coach_title,
         p.tagline, p.bio, p.specialties, p.certifications,
         CASE WHEN COALESCE(p.pricing_monthly, 0) > 0
              THEN p.pricing_monthly
              ELSE COALESCE(pp.lowest_monthly, 0) END AS pricing_monthly,
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
    LEFT JOIN pkg_price  pp ON pp.coach_id = p.id
   WHERE p.role = 'coach'
   ORDER BY rank_score DESC, p.rating_avg DESC NULLS LAST, p.review_count DESC NULLS LAST;
$$;

GRANT EXECUTE ON FUNCTION public.marketplace_coaches() TO authenticated;
