-- ═══════════════════════════════════════════════════════════════
-- 12 Circle Fitness — Custom Exercises + Workout Tracking
-- Run in Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════════

-- ── 1. Custom exercises table ────────────────────────────────────────────────
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
  -- Video variants: [{url, label, type}]
  -- label: Tutorial | Beginner | Intermediate | Advanced | Form Correction | Warm-up
  -- type:  youtube  | vimeo   | upload
  video_variants   jsonb DEFAULT '[]',
  image_url        text,
  -- Visibility: private | team | global
  visibility       text NOT NULL DEFAULT 'private',
  -- Global library submission
  submission_status text DEFAULT NULL, -- null | pending | approved | rejected
  submission_notes  text,
  submitted_at     timestamptz,
  approved_at      timestamptz,
  created_at       timestamptz DEFAULT now(),
  updated_at       timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_custom_exercises_coach ON custom_exercises (coach_id);
CREATE INDEX IF NOT EXISTS idx_custom_exercises_visibility ON custom_exercises (visibility);
CREATE INDEX IF NOT EXISTS idx_custom_exercises_submission ON custom_exercises (submission_status);

-- ── 2. RLS for custom_exercises ──────────────────────────────────────────────
ALTER TABLE custom_exercises ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "coaches manage own exercises" ON custom_exercises;
CREATE POLICY "coaches manage own exercises"
  ON custom_exercises FOR ALL TO authenticated
  USING (coach_id = auth.uid());

-- Clients/team can read approved global exercises
DROP POLICY IF EXISTS "all read global exercises" ON custom_exercises;
CREATE POLICY "all read global exercises"
  ON custom_exercises FOR SELECT TO authenticated
  USING (visibility = 'global' AND submission_status = 'approved');

-- Team members can read team exercises from their coach
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

-- ── 3. Workout sessions: add tracking columns ─────────────────────────────────
ALTER TABLE workout_sessions ADD COLUMN IF NOT EXISTS workout_name    text;
ALTER TABLE workout_sessions ADD COLUMN IF NOT EXISTS total_exercises int DEFAULT 0;
ALTER TABLE workout_sessions ADD COLUMN IF NOT EXISTS total_sets      int DEFAULT 0;
ALTER TABLE workout_sessions ADD COLUMN IF NOT EXISTS completed_sets  int DEFAULT 0;
ALTER TABLE workout_sessions ADD COLUMN IF NOT EXISTS calories_burned int DEFAULT 0;

-- ── 4. Workout set logs: ensure exercise_id column exists ─────────────────────
ALTER TABLE workout_set_logs ADD COLUMN IF NOT EXISTS exercise_id text;
ALTER TABLE workout_set_logs ADD COLUMN IF NOT EXISTS tempo       text;

-- ── 5. Auto-updated_at trigger for custom_exercises ──────────────────────────
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;

DROP TRIGGER IF EXISTS custom_exercises_updated_at ON custom_exercises;
CREATE TRIGGER custom_exercises_updated_at
  BEFORE UPDATE ON custom_exercises
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ── 6. Trigger: notify coach when exercise approved ───────────────────────────
CREATE OR REPLACE FUNCTION trg_notify_exercise_approved()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NEW.submission_status = 'approved' AND OLD.submission_status != 'approved' THEN
    PERFORM insert_notification(
      NEW.coach_id,
      'today_score',
      '🌐 Exercise approved for Global Library!',
      '"' || NEW.name || '" has been approved and is now available to all coaches.',
      jsonb_build_object('exercise_id', NEW.id)
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS notify_exercise_approved ON custom_exercises;
CREATE TRIGGER notify_exercise_approved
  AFTER UPDATE ON custom_exercises
  FOR EACH ROW EXECUTE FUNCTION trg_notify_exercise_approved();

-- ── 7. View: coach exercise stats per client ──────────────────────────────────
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

-- Grant access to authenticated users (RLS on underlying tables still applies)
GRANT SELECT ON coach_client_workout_stats TO authenticated;

-- ── 8. Realtime ───────────────────────────────────────────────────────────────
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE custom_exercises;
EXCEPTION WHEN others THEN NULL; END $$;
