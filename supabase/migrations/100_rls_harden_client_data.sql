-- 100_rls_harden_client_data.sql
--
-- Closes two RLS holes found by auditing the LIVE policy set (184 policies):
--
--   1. Policies named "coaches read client X" used `USING (true)` and never checked
--      that the caller was actually a coach of that client. Any authenticated
--      account could read EVERY user's health data.
--
--   2. Three policies had no `TO` clause, so they applied to PUBLIC — i.e. anonymous
--      internet traffic, using the anon key that is published in this public repo.
--
-- NOT covered here: user_profiles. Its blanket policies cannot be tightened without
-- breaking community/class/review screens that read other users' display names.
-- That needs a public-safe view plus app changes -- tracked separately.

-- ---------------------------------------------------------------------------
-- Helper: is the current user an ACTIVE coach of the given client?
-- SECURITY DEFINER so the check can read coach_client_relationships regardless of
-- that table's own RLS (prevents recursive policy evaluation).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_active_coach_of(target_user uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.coach_client_relationships r
    WHERE r.coach_id = auth.uid()
      AND r.client_id = target_user
      AND r.status = 'active'
  );
$$;

REVOKE ALL ON FUNCTION public.is_active_coach_of(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_active_coach_of(uuid) TO authenticated;

-- ---------------------------------------------------------------------------
-- 1. Health / body / training data: owner OR their active coach.
--    Each table already has a separate "users manage own X" policy; these
--    replace only the over-permissive coach-read policies.
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "coaches read client nutrition logs" ON public.nutrition_logs;
CREATE POLICY "coaches read client nutrition logs"
  ON public.nutrition_logs FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR public.is_active_coach_of(user_id));

DROP POLICY IF EXISTS "coaches read client weight logs" ON public.weight_logs;
CREATE POLICY "coaches read client weight logs"
  ON public.weight_logs FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR public.is_active_coach_of(user_id));

DROP POLICY IF EXISTS "coaches read client measurements" ON public.body_measurements;
CREATE POLICY "coaches read client measurements"
  ON public.body_measurements FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR public.is_active_coach_of(user_id));

DROP POLICY IF EXISTS "coaches read client photo logs" ON public.progress_photo_logs;
CREATE POLICY "coaches read client photo logs"
  ON public.progress_photo_logs FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR public.is_active_coach_of(user_id));

DROP POLICY IF EXISTS "coaches read client habit logs" ON public.habit_logs;
CREATE POLICY "coaches read client habit logs"
  ON public.habit_logs FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR public.is_active_coach_of(user_id));

DROP POLICY IF EXISTS "coaches read client scores" ON public.daily_scores;
CREATE POLICY "coaches read client scores"
  ON public.daily_scores FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR public.is_active_coach_of(user_id));

DROP POLICY IF EXISTS "coaches read client sessions" ON public.workout_sessions;
CREATE POLICY "coaches read client sessions"
  ON public.workout_sessions FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR public.is_active_coach_of(user_id));

DROP POLICY IF EXISTS "coaches read client set logs" ON public.workout_set_logs;
CREATE POLICY "coaches read client set logs"
  ON public.workout_set_logs FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR public.is_active_coach_of(user_id));

DROP POLICY IF EXISTS "coaches read feedback" ON public.workout_feedback;
CREATE POLICY "coaches read feedback"
  ON public.workout_feedback FOR SELECT TO authenticated
  USING (
    user_id = auth.uid()
    OR coach_id = auth.uid()
    OR public.is_active_coach_of(user_id)
  );

-- ---------------------------------------------------------------------------
-- 2. Close anonymous access. These policies had no TO clause, so they applied to
--    PUBLIC (including the anon role). Requiring `authenticated` keeps the app
--    working -- these screens are all behind login -- while removing the ability
--    for anyone on the internet to read them with the published anon key.
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "Anyone can read pods" ON public.accountability_pods;
CREATE POLICY "Authenticated can read pods"
  ON public.accountability_pods FOR SELECT TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Members can see pod membership" ON public.accountability_pod_members;
CREATE POLICY "Authenticated can see pod membership"
  ON public.accountability_pod_members FOR SELECT TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Anyone can view posts" ON public.community_posts;
-- Note: an "all read posts" policy scoped TO authenticated already exists on this
-- table, so authenticated reads are unaffected by dropping the PUBLIC one.
