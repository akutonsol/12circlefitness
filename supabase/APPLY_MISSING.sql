-- ═══════════════════════════════════════════════════════════════════════════
-- 12 Circle Fitness — APPLY MISSING SCHEMA
-- Generated 2026-06-17 after a live audit of the remote DB (nxdbooufqzkpslkcogxc).
-- The live database was missing 5 objects that the app code depends on:
--   custom_exercises, coach_client_workout_stats (view), user_integrations,
--   community_groups, community_group_members
-- Paste this whole file into the Supabase SQL Editor and run it.
-- Every statement is idempotent — safe to run more than once.
-- ═══════════════════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. CUSTOM EXERCISES  (migration 005)  — Module 3 Create Exercise / Module 4
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS custom_exercises (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id         uuid REFERENCES user_profiles(id) ON DELETE CASCADE,
  name             text NOT NULL,
  category         text NOT NULL DEFAULT 'Strength',
  muscle_group     text NOT NULL DEFAULT 'Full Body',
  secondary_muscles text[] DEFAULT '{}',
  equipment        text NOT NULL DEFAULT 'Bodyweight',
  difficulty       text NOT NULL DEFAULT 'Intermediate',
  description      text DEFAULT '',
  instructions     text[] DEFAULT '{}',
  coaching_cues    text[] DEFAULT '{}',
  common_mistakes  text[] DEFAULT '{}',
  alternatives     text[] DEFAULT '{}',
  beginner_modification text,
  advanced_progression  text,
  tags             text[] DEFAULT '{}',
  video_variants   jsonb DEFAULT '[]',
  image_url        text,
  visibility       text NOT NULL DEFAULT 'private',
  submission_status text DEFAULT NULL,
  submission_notes  text,
  submitted_at     timestamptz,
  approved_at      timestamptz,
  created_at       timestamptz DEFAULT now(),
  updated_at       timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_custom_exercises_coach ON custom_exercises (coach_id);
CREATE INDEX IF NOT EXISTS idx_custom_exercises_visibility ON custom_exercises (visibility);
CREATE INDEX IF NOT EXISTS idx_custom_exercises_submission ON custom_exercises (submission_status);

ALTER TABLE custom_exercises ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "coaches manage own exercises" ON custom_exercises;
CREATE POLICY "coaches manage own exercises"
  ON custom_exercises FOR ALL TO authenticated
  USING (coach_id = auth.uid());

DROP POLICY IF EXISTS "all read global exercises" ON custom_exercises;
CREATE POLICY "all read global exercises"
  ON custom_exercises FOR SELECT TO authenticated
  USING (visibility = 'global' AND submission_status = 'approved');

DROP POLICY IF EXISTS "team read team exercises" ON custom_exercises;
CREATE POLICY "team read team exercises"
  ON custom_exercises FOR SELECT TO authenticated
  USING (
    visibility = 'team'
    AND coach_id IN (
      SELECT coach_id FROM coach_client_relationships
      WHERE client_id = auth.uid() AND status = 'active'
    )
  );

-- Workout tracking columns relied on by the active-workout screen
ALTER TABLE workout_sessions ADD COLUMN IF NOT EXISTS workout_name    text;
ALTER TABLE workout_sessions ADD COLUMN IF NOT EXISTS total_exercises int DEFAULT 0;
ALTER TABLE workout_sessions ADD COLUMN IF NOT EXISTS total_sets      int DEFAULT 0;
ALTER TABLE workout_sessions ADD COLUMN IF NOT EXISTS completed_sets  int DEFAULT 0;
ALTER TABLE workout_sessions ADD COLUMN IF NOT EXISTS calories_burned int DEFAULT 0;
-- Resume-workout (WKT-004/005): the app persists/restores elapsed time here.
-- Was missing on the live DB — without it, starting/resuming a workout errors.
ALTER TABLE workout_sessions ADD COLUMN IF NOT EXISTS elapsed_seconds int DEFAULT 0;
ALTER TABLE workout_set_logs ADD COLUMN IF NOT EXISTS exercise_id text;
ALTER TABLE workout_set_logs ADD COLUMN IF NOT EXISTS tempo       text;

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;

DROP TRIGGER IF EXISTS custom_exercises_updated_at ON custom_exercises;
CREATE TRIGGER custom_exercises_updated_at
  BEFORE UPDATE ON custom_exercises
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Coach client workout stats view
CREATE OR REPLACE VIEW coach_client_workout_stats AS
SELECT
  r.coach_id,
  r.client_id,
  p.first_name || ' ' || p.last_name AS client_name,
  p.avatar_url,
  COUNT(DISTINCT ws.id) FILTER (WHERE ws.status = 'completed') AS total_completed,
  COUNT(DISTINCT ws.id) FILTER (WHERE ws.status = 'in_progress') AS total_in_progress,
  COUNT(DISTINCT ws.id) FILTER (WHERE ws.status = 'abandoned') AS total_abandoned,
  ROUND(
    100.0 * COUNT(DISTINCT ws.id) FILTER (WHERE ws.status = 'completed') /
    NULLIF(COUNT(DISTINCT ws.id), 0)
  , 1) AS completion_rate_pct,
  MAX(ws.completed_at) AS last_workout_at,
  COUNT(DISTINCT ws.id) FILTER (
    WHERE ws.status = 'completed'
    AND ws.completed_at >= now() - INTERVAL '7 days'
  ) AS workouts_this_week
FROM coach_client_relationships r
JOIN user_profiles p ON p.id = r.client_id
LEFT JOIN workout_sessions ws ON ws.user_id = r.client_id
WHERE r.status = 'active'
GROUP BY r.coach_id, r.client_id, p.first_name, p.last_name, p.avatar_url;

GRANT SELECT ON coach_client_workout_stats TO authenticated;

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE custom_exercises;
EXCEPTION WHEN others THEN NULL; END $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. USER INTEGRATIONS  (migration 011)  — Settings ▸ Integrations
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_integrations (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  provider         text NOT NULL,
  connected        boolean NOT NULL DEFAULT TRUE,
  access_token     text,
  refresh_token    text,
  connected_at     timestamptz DEFAULT now(),
  disconnected_at  timestamptz,
  UNIQUE (user_id, provider)
);

ALTER TABLE user_integrations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "user_own_integrations" ON user_integrations;
CREATE POLICY "user_own_integrations" ON user_integrations
  FOR ALL USING (auth.uid() = user_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- 2b. EVENT TICKET CODE  — Module 14 (EVT-001)
-- The event-ticket screen reads/writes ticket_code, but the table only had
-- qr_code. Add ticket_code so registration + QR ticket works.
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE event_registrations ADD COLUMN IF NOT EXISTS ticket_code text;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2c. FIX BROKEN CHALLENGE-JOIN TRIGGER  — Module 12 (CHL-001)
-- The live trigger trg_notify_on_challenge_join() selected challenges.name,
-- but the column is challenges.title. Result: EVERY challenge join failed with
-- 'column "name" does not exist'. This recreates it with the correct column.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION trg_notify_on_challenge_join()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_coach_id       uuid;
  v_challenge_name text;
  v_joiner_name    text;
BEGIN
  SELECT coach_id, title INTO v_coach_id, v_challenge_name
  FROM challenges WHERE id = NEW.challenge_id;

  IF v_coach_id IS NULL OR v_coach_id = NEW.user_id THEN RETURN NEW; END IF;

  SELECT COALESCE(first_name, email, 'Someone')
  INTO v_joiner_name FROM user_profiles WHERE id = NEW.user_id;

  PERFORM insert_notification(
    v_coach_id,
    'challenges',
    v_joiner_name || ' joined a challenge',
    v_joiner_name || ' is now competing in "' || COALESCE(v_challenge_name, 'your challenge') || '".',
    jsonb_build_object('challenge_id', NEW.challenge_id, 'user_id', NEW.user_id)
  );
  RETURN NEW;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2d. FIX 3 MORE BROKEN TRIGGERS (same column-drift bug as the challenge one)
--   workout_complete : NEW.duration_minutes -> duration_seconds  (WKT-002)
--   class_booking    : classes.starts_at    -> scheduled_at      (Module 13)
--   coach_review     : NEW.content          -> review_text       (reviews)
-- Without these, completing a workout, booking a class, and posting a review
-- all error on the live DB.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION trg_notify_on_workout_complete()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF (NEW.status = 'completed' AND (OLD.status IS DISTINCT FROM 'completed')) THEN
    PERFORM insert_notification(
      NEW.user_id,
      'workout',
      'Workout complete! 💪',
      'Great work finishing ' ||
        COALESCE(NEW.workout_name, 'your session') ||
        '. Keep that momentum going!',
      jsonb_build_object('session_id', NEW.id, 'duration_seconds', NEW.duration_seconds)
    );
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION trg_notify_on_class_booking()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_class_title text;
  v_class_time  timestamptz;
BEGIN
  SELECT title, scheduled_at INTO v_class_title, v_class_time
  FROM classes WHERE id = NEW.class_id;

  PERFORM insert_notification(
    NEW.user_id,
    'messages',
    'Class booked: ' || COALESCE(v_class_title, 'your class'),
    'You''re in! Your class starts ' ||
      COALESCE(to_char(v_class_time AT TIME ZONE 'UTC', 'Mon DD at HH:MI AM'), 'soon') || '.',
    jsonb_build_object('class_id', NEW.class_id)
  );
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION trg_notify_on_coach_review()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_reviewer_name text;
BEGIN
  SELECT COALESCE(first_name, email, 'A client')
  INTO v_reviewer_name FROM user_profiles WHERE id = NEW.client_id;

  PERFORM insert_notification(
    NEW.coach_id,
    'coach_request',
    NEW.rating::text || '⭐ review from ' || v_reviewer_name,
    CASE WHEN NEW.rating >= 5 THEN 'You received a 5-star review! 🌟 '
         WHEN NEW.rating >= 4 THEN 'Great feedback — keep it up! '
         ELSE 'New review posted. ' END
    || COALESCE(LEFT(NEW.review_text, 80), ''),
    jsonb_build_object('review_id', NEW.id, 'rating', NEW.rating)
  );
  RETURN NEW;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. COMMUNITY GROUPS  (migration 016)  — Community ▸ Groups / Activity
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS community_groups (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text NOT NULL,
  description text,
  emoji       text DEFAULT '💪',
  member_count integer DEFAULT 0,
  created_at  timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS community_group_members (
  id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id  uuid REFERENCES community_groups(id) ON DELETE CASCADE,
  user_id   uuid REFERENCES user_profiles(id) ON DELETE CASCADE,
  joined_at timestamptz DEFAULT now(),
  UNIQUE(group_id, user_id)
);

ALTER TABLE community_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_group_members ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "all read groups" ON community_groups;
CREATE POLICY "all read groups"
  ON community_groups FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "users manage own group membership" ON community_group_members;
CREATE POLICY "users manage own group membership"
  ON community_group_members FOR ALL TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "all read group members" ON community_group_members;
CREATE POLICY "all read group members"
  ON community_group_members FOR SELECT TO authenticated USING (true);

INSERT INTO community_groups (id, name, description, emoji) VALUES
  ('10000000-0000-0000-0000-000000000001', 'Transformation Squad',  'Share your progress and inspire others on their transformation journey', '💪'),
  ('10000000-0000-0000-0000-000000000002', 'Nutrition Warriors',     'Meal prep tips, recipes, and nutrition accountability',                 '🥗'),
  ('10000000-0000-0000-0000-000000000003', 'Mindset & Wellness',     'Mental health, meditation, and holistic wellness discussions',          '🧘'),
  ('10000000-0000-0000-0000-000000000004', 'Beginners Circle',       'A safe space for those just starting their fitness journey',            '🌱'),
  ('10000000-0000-0000-0000-000000000005', 'Advanced Athletes',      'For experienced members pushing their limits',                          '🏆')
ON CONFLICT (id) DO NOTHING;
