-- ═══════════════════════════════════════════════════════════════════════════
-- 12 Circle Fitness — Module 16b (Coach Platform Plans)
-- Updated revenue model: coaches pay a monthly PLATFORM subscription to operate
-- on 12 Circle (Starter $99 / Growth $199 / Elite $299), separate from the
-- client→coach subscription (kind 'coach'). Marketplace-lead commission is a
-- later Stripe Connect phase; this migration only models the coach's own plan.
-- Idempotent — safe to run more than once.
-- ═══════════════════════════════════════════════════════════════════════════

-- The coach plan tier lives on the subscription row (kind = 'coach_plan').
ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS plan_tier text;  -- starter | growth | elite

-- The coach's current active platform plan tier (or null if none).
CREATE OR REPLACE FUNCTION public.coach_plan_tier()
RETURNS text LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT plan_tier FROM subscriptions
  WHERE user_id = auth.uid()
    AND kind = 'coach_plan'
    AND status IN ('active', 'trialing')
    AND (current_period_end IS NULL OR current_period_end > now())
  ORDER BY CASE plan_tier
             WHEN 'elite' THEN 0 WHEN 'growth' THEN 1 ELSE 2 END
  LIMIT 1;
$$;

GRANT EXECUTE ON FUNCTION public.coach_plan_tier() TO authenticated;
