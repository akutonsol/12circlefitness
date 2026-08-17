-- 102_restrict_user_profiles.sql
--
-- PHASE 3 of the user_profiles hardening. THIS IS THE MIGRATION THAT ACTUALLY
-- CLOSES THE HOLE -- and the one that can break things.
--
-- ############################################################################
-- ## DO NOT APPLY THIS UNTIL BOTH ARE TRUE:                                 ##
-- ##   1. Migration 101 (public_profiles view) is applied, AND              ##
-- ##   2. Every beta tester is running an app build that reads display       ##
-- ##      names from public_profiles instead of user_profiles.               ##
-- ##                                                                         ##
-- ## Beta testers have the OLD binary installed on their phones. Applying    ##
-- ## this before they update breaks the community feed, class list, pods,    ##
-- ## coach reviews and check-ins for them IMMEDIATELY -- server-side changes  ##
-- ## do not wait for an app update.                                          ##
-- ############################################################################
--
-- After this runs, user_profiles rows are readable only by:
--   * the owner, and
--   * a coach with an ACTIVE coach_client_relationship to that user
-- which matches how the sensitive columns are actually consumed: the owner via
-- personal_info_screen / intake, and the coach via client_detail_screen.

-- Two access paths read profile columns that are deliberately NOT in the
-- public_profiles view (email), so they cannot be served by the view and need
-- their own policies instead:
--   * a head coach viewing their own team roster (coach_business_screen)
--   * an event host viewing their attendee list (vendor_portal_screen)
-- Both are SECURITY DEFINER so the lookup is not itself filtered by RLS on the
-- table being consulted, which would otherwise return no rows.

CREATE OR REPLACE FUNCTION public.is_team_lead_of(target_user uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.coach_team_members t
    WHERE t.coach_id = auth.uid()
      AND t.member_id = target_user
  );
$$;

CREATE OR REPLACE FUNCTION public.hosts_event_for(target_user uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.event_registrations r
    JOIN public.events e ON e.id = r.event_id
    WHERE e.vendor_id = auth.uid()
      AND r.user_id = target_user
  );
$$;

REVOKE ALL ON FUNCTION public.is_team_lead_of(uuid)  FROM PUBLIC;
REVOKE ALL ON FUNCTION public.hosts_event_for(uuid)  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_team_lead_of(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.hosts_event_for(uuid) TO authenticated;

-- Two overlapping blanket policies exist on the live database; both grant
-- `USING (true)` to every authenticated user. Names verified against the live
-- schema dump -- a typo here would silently no-op and leave the hole open.
DROP POLICY IF EXISTS "authenticated_read_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "profiles are viewable by authenticated users" ON public.user_profiles;

CREATE POLICY "own profile or active coach reads profile"
  ON public.user_profiles FOR SELECT TO authenticated
  USING (
    id = auth.uid()
    OR public.is_active_coach_of(id)
    OR public.is_team_lead_of(id)
    OR public.hosts_event_for(id)
  );

-- Rollback (paste into the SQL editor if the app misbehaves after applying):
--
--   DROP POLICY IF EXISTS "own profile or active coach reads profile" ON public.user_profiles;
--   CREATE POLICY "authenticated_read_profiles"
--     ON public.user_profiles FOR SELECT TO authenticated USING (true);
