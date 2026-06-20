-- ════════════════════════════════════════════════════════════════════════
-- 12 Circle Automated Scoring Engine
-- Event-sourced points: every eligible action calls award_points(), which
-- records an auditable score_event, rolls up the monthly cycle + lifetime
-- totals, recomputes level/rank, and auto-grants badges. Never manual.
-- ════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS user_scores (
  user_id             uuid PRIMARY KEY REFERENCES user_profiles(id) ON DELETE CASCADE,
  current_period      text NOT NULL DEFAULT to_char(now(), 'YYYY-MM'),
  current_cycle_score int  NOT NULL DEFAULT 0,
  lifetime_score      int  NOT NULL DEFAULT 0,
  level               int  NOT NULL DEFAULT 1,
  rank                text NOT NULL DEFAULT 'Bronze',
  updated_at          timestamptz DEFAULT now()
);

-- One row per user per monthly cycle (monthly score resets each cycle).
CREATE TABLE IF NOT EXISTS score_cycles (
  id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id   uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  period    text NOT NULL,            -- 'YYYY-MM'
  score     int  NOT NULL DEFAULT 0,
  UNIQUE (user_id, period)
);

-- Auditable history — every point award.
CREATE TABLE IF NOT EXISTS score_events (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  category   text NOT NULL,
  action     text NOT NULL,
  points     int  NOT NULL,
  ref_type   text,
  ref_id     text,
  dedup_key  text,                    -- set for once-only awards
  created_at timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_score_events_user ON score_events (user_id, created_at DESC);
CREATE UNIQUE INDEX IF NOT EXISTS uq_score_events_dedup
  ON score_events (user_id, dedup_key) WHERE dedup_key IS NOT NULL;

CREATE TABLE IF NOT EXISTS badges (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code             text UNIQUE NOT NULL,
  name             text NOT NULL,
  description      text,
  icon             text,
  threshold_type   text NOT NULL,     -- 'lifetime' | 'action_count'
  threshold_action text,
  threshold_value  int  NOT NULL,
  sort_order       int  DEFAULT 0
);

CREATE TABLE IF NOT EXISTS user_badges (
  id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id   uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  badge_id  uuid NOT NULL REFERENCES badges(id) ON DELETE CASCADE,
  earned_at timestamptz DEFAULT now(),
  UNIQUE (user_id, badge_id)
);

INSERT INTO badges (code, name, description, icon, threshold_type, threshold_action, threshold_value, sort_order) VALUES
  ('starter','Getting Started','Earn 100 points','🌱','lifetime',NULL,100,1),
  ('committed','Committed','Earn 500 points','🔥','lifetime',NULL,500,2),
  ('dedicated','Dedicated','Earn 1,000 points','💪','lifetime',NULL,1000,3),
  ('elite','Elite','Earn 5,000 points','🏆','lifetime',NULL,5000,4),
  ('legend','Legend','Earn 10,000 points','👑','lifetime',NULL,10000,5),
  ('first_sweat','First Sweat','Complete your first workout','🏋️','action_count','workout_complete',1,6),
  ('consistent','Consistent','Complete 10 workouts','⚡','action_count','workout_complete',10,7),
  ('accountable','Accountable','Submit 4 weekly check-ins','✅','action_count','checkin_weekly',4,8),
  ('picture_perfect','Picture Perfect','Upload progress photos','📸','action_count','photos_upload',1,9),
  ('challenger','Challenger','Complete a challenge','🎯','action_count','challenge_complete',1,10),
  ('nourished','Nourished','Log 50 meals','🥗','action_count','meal_log',50,11)
ON CONFLICT (code) DO NOTHING;

-- ── The single automated entry point ────────────────────────────────────
CREATE OR REPLACE FUNCTION award_points(
  p_category text, p_action text, p_points int,
  p_ref_type text DEFAULT NULL, p_ref_id text DEFAULT NULL, p_dedup_key text DEFAULT NULL
) RETURNS int LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_uid      uuid := auth.uid();
  v_period   text := to_char(now(), 'YYYY-MM');
  v_cycle    int;
  v_lifetime int;
  v_level    int;
  v_rank     text;
  b          record;
BEGIN
  IF v_uid IS NULL OR p_points <= 0 THEN RETURN 0; END IF;

  -- Idempotency: a once-only award won't double-count.
  IF p_dedup_key IS NOT NULL AND EXISTS (
       SELECT 1 FROM score_events WHERE user_id = v_uid AND dedup_key = p_dedup_key) THEN
    RETURN 0;
  END IF;

  INSERT INTO score_events (user_id, category, action, points, ref_type, ref_id, dedup_key)
    VALUES (v_uid, p_category, p_action, p_points, p_ref_type, p_ref_id, p_dedup_key);

  INSERT INTO score_cycles (user_id, period, score) VALUES (v_uid, v_period, p_points)
    ON CONFLICT (user_id, period) DO UPDATE SET score = score_cycles.score + EXCLUDED.score
    RETURNING score INTO v_cycle;

  INSERT INTO user_scores (user_id, current_period, current_cycle_score, lifetime_score)
    VALUES (v_uid, v_period, v_cycle, p_points)
    ON CONFLICT (user_id) DO UPDATE SET
      lifetime_score      = user_scores.lifetime_score + p_points,
      current_period      = v_period,
      current_cycle_score = v_cycle,
      updated_at          = now()
    RETURNING lifetime_score INTO v_lifetime;

  v_level := floor(v_lifetime / 500.0)::int + 1;
  v_rank  := CASE
    WHEN v_level >= 10 THEN 'Diamond'
    WHEN v_level >= 7  THEN 'Platinum'
    WHEN v_level >= 5  THEN 'Gold'
    WHEN v_level >= 3  THEN 'Silver'
    ELSE 'Bronze' END;
  UPDATE user_scores SET level = v_level, rank = v_rank WHERE user_id = v_uid;

  -- Auto-grant any newly-earned badges.
  FOR b IN SELECT * FROM badges LOOP
    IF NOT EXISTS (SELECT 1 FROM user_badges WHERE user_id = v_uid AND badge_id = b.id) THEN
      IF (b.threshold_type = 'lifetime' AND v_lifetime >= b.threshold_value)
         OR (b.threshold_type = 'action_count'
             AND (SELECT count(*) FROM score_events
                    WHERE user_id = v_uid AND action = b.threshold_action) >= b.threshold_value) THEN
        INSERT INTO user_badges (user_id, badge_id) VALUES (v_uid, b.id) ON CONFLICT DO NOTHING;
      END IF;
    END IF;
  END LOOP;

  RETURN p_points;
END $$;

-- ── Leaderboards ────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION leaderboard_global(p_limit int DEFAULT 50)
RETURNS TABLE(user_id uuid, first_name text, last_name text, avatar_url text,
              cycle_score int, lifetime_score int, level int, rank text)
LANGUAGE sql STABLE AS $$
  SELECT s.user_id, p.first_name, p.last_name, p.avatar_url,
         s.current_cycle_score, s.lifetime_score, s.level, s.rank
  FROM user_scores s JOIN user_profiles p ON p.id = s.user_id
  WHERE s.current_period = to_char(now(), 'YYYY-MM') AND s.current_cycle_score > 0
  ORDER BY s.current_cycle_score DESC, s.lifetime_score DESC
  LIMIT p_limit;
$$;

-- Coach's group leaderboard (their active clients).
CREATE OR REPLACE FUNCTION leaderboard_coach(p_coach uuid, p_limit int DEFAULT 50)
RETURNS TABLE(user_id uuid, first_name text, last_name text, avatar_url text,
              cycle_score int, lifetime_score int, level int, rank text)
LANGUAGE sql STABLE AS $$
  SELECT s.user_id, p.first_name, p.last_name, p.avatar_url,
         s.current_cycle_score, s.lifetime_score, s.level, s.rank
  FROM user_scores s
  JOIN user_profiles p ON p.id = s.user_id
  JOIN coach_client_relationships r ON r.client_id = s.user_id
  WHERE r.coach_id = p_coach AND r.status = 'active'
  ORDER BY s.current_cycle_score DESC, s.lifetime_score DESC
  LIMIT p_limit;
$$;

-- ── RLS ─────────────────────────────────────────────────────────────────
ALTER TABLE user_scores  ENABLE ROW LEVEL SECURITY;
ALTER TABLE score_cycles ENABLE ROW LEVEL SECURITY;
ALTER TABLE score_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE badges       ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_badges  ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "read user_scores" ON user_scores;       -- leaderboard needs cross-user read
CREATE POLICY "read user_scores" ON user_scores FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "own score cycles" ON score_cycles;
CREATE POLICY "own score cycles" ON score_cycles FOR SELECT TO authenticated USING (user_id = auth.uid());

DROP POLICY IF EXISTS "own score events" ON score_events;
CREATE POLICY "own score events" ON score_events FOR SELECT TO authenticated USING (user_id = auth.uid());
DROP POLICY IF EXISTS "coach reads client events" ON score_events;
CREATE POLICY "coach reads client events" ON score_events FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM coach_client_relationships r
                 WHERE r.coach_id = auth.uid() AND r.client_id = score_events.user_id));

DROP POLICY IF EXISTS "read badges" ON badges;
CREATE POLICY "read badges" ON badges FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "read user_badges" ON user_badges;
CREATE POLICY "read user_badges" ON user_badges FOR SELECT TO authenticated USING (true);

GRANT EXECUTE ON FUNCTION award_points(text,text,int,text,text,text) TO authenticated;
GRANT EXECUTE ON FUNCTION leaderboard_global(int) TO authenticated;
GRANT EXECUTE ON FUNCTION leaderboard_coach(uuid,int) TO authenticated;
