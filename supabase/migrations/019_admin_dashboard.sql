-- ═══════════════════════════════════════════════════════════════════════════
-- 12 Circle Fitness — Module 25 (Admin Dashboard)
-- Org-wide oversight for role='admin'. Rather than loosen per-table RLS, we
-- expose two SECURITY DEFINER functions guarded by an admin-role check, so an
-- admin can read aggregates without any client/coach gaining cross-tenant read.
-- Idempotent — safe to run more than once.
-- ═══════════════════════════════════════════════════════════════════════════

-- Guard helper: true only when the calling user is an admin.
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM user_profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$;

-- ── Platform stats ──────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.admin_platform_stats()
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  result jsonb;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'not authorized' USING errcode = '42501';
  END IF;

  SELECT jsonb_build_object(
    'total_users',          (SELECT count(*) FROM user_profiles),
    'coaches',              (SELECT count(*) FROM user_profiles WHERE role = 'coach'),
    'clients',              (SELECT count(*) FROM user_profiles WHERE role = 'client'),
    'vendors',              (SELECT count(*) FROM user_profiles WHERE role = 'vendor'),
    'admins',               (SELECT count(*) FROM user_profiles WHERE role = 'admin'),
    'new_signups_week',     (SELECT count(*) FROM user_profiles WHERE created_at >= now() - interval '7 days'),
    'active_relationships', (SELECT count(*) FROM coach_client_relationships WHERE status = 'active'),
    'programs_created',     (SELECT count(*) FROM workout_programs),
    'active_assignments',   (SELECT count(*) FROM workout_program_assignments WHERE status = 'active'),
    'workouts_logged',      (SELECT count(*) FROM workout_logs),
    'checkins_week',        (SELECT count(*) FROM weekly_checkins WHERE created_at >= now() - interval '7 days'),
    'total_challenges',     (SELECT count(*) FROM challenges),
    'total_events',         (SELECT count(*) FROM events)
  ) INTO result;

  RETURN result;
END;
$$;

-- ── Recent signups (for the admin "newest members" list) ────────────────────
CREATE OR REPLACE FUNCTION public.admin_recent_users(p_limit int DEFAULT 20)
RETURNS TABLE (
  id uuid,
  first_name text,
  last_name text,
  email text,
  role text,
  avatar_url text,
  created_at timestamptz
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'not authorized' USING errcode = '42501';
  END IF;

  RETURN QUERY
    SELECT u.id, u.first_name, u.last_name, u.email, u.role, u.avatar_url, u.created_at
    FROM user_profiles u
    ORDER BY u.created_at DESC
    LIMIT greatest(1, least(p_limit, 100));
END;
$$;

GRANT EXECUTE ON FUNCTION public.is_admin()              TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_platform_stats()  TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_recent_users(int) TO authenticated;
