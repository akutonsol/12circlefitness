-- ═══════════════════════════════════════════════════════════════════════════
-- 12 Circle Fitness — Module 16c (Free tier + unified client plan)
-- Customer journey: Free → Self-Guided → AI-Guided → Coach-Guided.
-- Free is the default (no paid subscription). This resolves a client's single
-- effective plan for feature-gating + upgrade prompts. Coach-Guided (an active
-- client→coach subscription) is treated as the top tier.
-- Idempotent — safe to run more than once.
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.client_plan()
RETURNS text LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT COALESCE(
    -- Top tier: an active client→coach subscription.
    (SELECT 'coach_guided' FROM subscriptions
       WHERE user_id = auth.uid() AND kind = 'coach'
         AND status IN ('active', 'trialing')
         AND (current_period_end IS NULL OR current_period_end > now())
       LIMIT 1),
    -- Else the highest active platform membership (ai outranks self).
    (SELECT kind FROM subscriptions
       WHERE user_id = auth.uid() AND kind IN ('self_guided', 'ai_guided')
         AND status IN ('active', 'trialing')
         AND (current_period_end IS NULL OR current_period_end > now())
       ORDER BY CASE kind WHEN 'ai_guided' THEN 0 ELSE 1 END
       LIMIT 1),
    -- Default.
    'free'
  );
$$;

GRANT EXECUTE ON FUNCTION public.client_plan() TO authenticated;
