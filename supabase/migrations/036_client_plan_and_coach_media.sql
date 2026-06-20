-- ── Fix 1: a client on ANY coaching arrangement reads as 'coach_guided' ──────
-- Previously only a kind='coach' subscription counted. Coach packages create a
-- 'package_monthly' sub (or none, for one-time packs), and an accepted coach
-- relationship may have no sub at all — so paying clients showed as "Free".
-- Now an active coach_client_relationship (the signal set when a client is on a
-- coach via any path) makes the plan 'coach_guided'.
CREATE OR REPLACE FUNCTION public.client_plan()
RETURNS text LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT COALESCE(
    -- Top tier: an active coaching relationship (package, monthly sub, or accepted coach).
    (SELECT 'coach_guided' FROM coach_client_relationships
       WHERE client_id = auth.uid() AND status = 'active' LIMIT 1),
    -- Legacy / explicit coach or monthly-package subscription.
    (SELECT 'coach_guided' FROM subscriptions
       WHERE user_id = auth.uid() AND kind IN ('coach', 'package_monthly')
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
    'free'
  );
$$;
GRANT EXECUTE ON FUNCTION public.client_plan() TO authenticated;

-- ── Fix 2: create the coach-media bucket (coach video responses) ─────────────
INSERT INTO storage.buckets (id, name, public)
VALUES ('coach-media', 'coach-media', true)
ON CONFLICT (id) DO UPDATE SET public = true;

DROP POLICY IF EXISTS "coach media insert" ON storage.objects;
CREATE POLICY "coach media insert" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'coach-media');

DROP POLICY IF EXISTS "coach media read" ON storage.objects;
CREATE POLICY "coach media read" ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'coach-media');

DROP POLICY IF EXISTS "coach media manage own" ON storage.objects;
CREATE POLICY "coach media manage own" ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'coach-media' AND owner = auth.uid());
