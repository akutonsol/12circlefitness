-- 12 Circle — pending migrations (028 → 041). Idempotent. 2026-06-20

-- ══════════════════════════════════════════════════════════════════
-- 028_package_payments.sql
-- ══════════════════════════════════════════════════════════════════
-- Package payments: a client buys a coach's package (per_session / bulk one-time,
-- or monthly subscription). Extends the existing payments + subscriptions plumbing.

-- Tie a payment to the package + coach it bought.
ALTER TABLE payments ADD COLUMN IF NOT EXISTS package_id uuid REFERENCES coach_packages(id) ON DELETE SET NULL;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS coach_id   uuid REFERENCES user_profiles(id) ON DELETE SET NULL;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS sessions   int  NOT NULL DEFAULT 0;

-- The coach can see payments made to them.
DROP POLICY IF EXISTS "coach reads payments to them" ON payments;
CREATE POLICY "coach reads payments to them"
  ON payments FOR SELECT TO authenticated
  USING (coach_id = auth.uid());

-- Session credits: bought session packs grant a balance the coach draws down.
CREATE TABLE IF NOT EXISTS client_session_credits (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id       uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  coach_id        uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  package_id      uuid REFERENCES coach_packages(id) ON DELETE SET NULL,
  payment_id      uuid REFERENCES payments(id) ON DELETE SET NULL,
  sessions_total  int  NOT NULL DEFAULT 0,
  sessions_used   int  NOT NULL DEFAULT 0,
  created_at      timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_session_credits_client ON client_session_credits (client_id);
CREATE INDEX IF NOT EXISTS idx_session_credits_coach  ON client_session_credits (coach_id);

ALTER TABLE client_session_credits ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "client reads own credits" ON client_session_credits;
CREATE POLICY "client reads own credits"
  ON client_session_credits FOR SELECT TO authenticated
  USING (client_id = auth.uid());

DROP POLICY IF EXISTS "coach reads client credits" ON client_session_credits;
CREATE POLICY "coach reads client credits"
  ON client_session_credits FOR SELECT TO authenticated
  USING (coach_id = auth.uid());

-- The coach can log a used session (decrement is done via update of sessions_used).
DROP POLICY IF EXISTS "coach updates client credits" ON client_session_credits;
CREATE POLICY "coach updates client credits"
  ON client_session_credits FOR UPDATE TO authenticated
  USING (coach_id = auth.uid())
  WITH CHECK (coach_id = auth.uid());

-- ══════════════════════════════════════════════════════════════════
-- 029_progress_photos_storage_rls.sql
-- ══════════════════════════════════════════════════════════════════
-- Storage RLS for the private `progress-photos` bucket.
-- A user fully manages files in their own `<uid>/...` folder (select/insert/
-- update/delete) so they can ADD and REPLACE baseline + gallery photos, and a
-- coach can READ their active clients' photos (needed to createSignedUrl).
-- The folder name (first path segment) is the owner's user id.

-- ── Owner: full CRUD on own folder ──────────────────────────────────────────
DROP POLICY IF EXISTS "own progress photos select" ON storage.objects;
CREATE POLICY "own progress photos select"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'progress-photos'
         AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "own progress photos insert" ON storage.objects;
CREATE POLICY "own progress photos insert"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'progress-photos'
              AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "own progress photos update" ON storage.objects;
CREATE POLICY "own progress photos update"
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'progress-photos'
         AND (storage.foldername(name))[1] = auth.uid()::text)
  WITH CHECK (bucket_id = 'progress-photos'
              AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "own progress photos delete" ON storage.objects;
CREATE POLICY "own progress photos delete"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'progress-photos'
         AND (storage.foldername(name))[1] = auth.uid()::text);

-- ── Coach: read an active client's photos ───────────────────────────────────
DROP POLICY IF EXISTS "coach reads client progress photos" ON storage.objects;
CREATE POLICY "coach reads client progress photos"
  ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'progress-photos'
    AND EXISTS (
      SELECT 1 FROM coach_client_relationships r
      WHERE r.coach_id = auth.uid()
        AND r.client_id::text = (storage.foldername(name))[1]
    )
  );

-- ══════════════════════════════════════════════════════════════════
-- 030_schedule_day_times.sql
-- ══════════════════════════════════════════════════════════════════
-- Per-day training times: a client can set a different session time for each
-- training day. `day_times` is a JSON map of dayKey -> "HH:mm"
-- (e.g. {"monday":"07:00","thursday":"18:30"}). The single `session_time`
-- stays as the default / fallback for days without a specific time.
ALTER TABLE client_schedules
  ADD COLUMN IF NOT EXISTS day_times jsonb NOT NULL DEFAULT '{}'::jsonb;

-- ══════════════════════════════════════════════════════════════════
-- 031_classes_seed_and_price.sql
-- ══════════════════════════════════════════════════════════════════
-- Classes = group sessions (online group calls OR in-person group classes).
-- Additive only: a nullable `price` (the app's FitnessClass model already has it).
ALTER TABLE classes ADD COLUMN IF NOT EXISTS price numeric;

-- Seed the sample group classes as real rows, split across the two coaches
-- (Truck & Julia). Idempotent: skips a row that already exists for that coach.
WITH coaches AS (
  SELECT
    (SELECT id FROM user_profiles
       WHERE lower(trim(first_name)) LIKE 'truck%' OR lower(trim(last_name)) LIKE 'truck%'
       LIMIT 1) AS truck,
    (SELECT id FROM user_profiles
       WHERE lower(trim(first_name)) LIKE 'julia%' OR lower(trim(last_name)) LIKE 'julia%'
       LIMIT 1) AS julia
),
seed (coach_key, title, description, type, location, is_online, meeting_link, mins, cap, hrs, price) AS (
  VALUES
    ('truck','HIIT Cardio Blast','High intensity interval training to torch calories and build endurance. Bring water and a towel!','hiit','Studio A · 120 Market St', false, NULL::text, 45, 20,  26, NULL::numeric),
    ('truck','Full Body Strength','Build lean muscle and strength with compound movements. All levels welcome.','strength','Weight Room · 120 Market St', false, NULL, 60, 15, 42, NULL),
    ('truck','Boxing Fundamentals','Learn boxing basics while getting an amazing full body workout. Gloves provided.','boxing','Boxing Ring · 120 Market St', false, NULL, 60, 10, 50, NULL),
    ('truck','Dance Cardio','Fun high energy dance workout. No experience needed — just good vibes!','dance','Studio A · 120 Market St', false, NULL, 45, 20, 74, NULL),
    ('julia','Morning Yoga Flow','Start your day with intention. Gentle yoga flow focusing on flexibility and mindfulness.','yoga','Online', true, 'https://zoom.us/j/123', 50, 12, 31, NULL),
    ('julia','Pilates Core','Strengthen and tone your core with this challenging pilates session. Mat required.','pilates','Studio B · 120 Market St', false, NULL, 45, 15, 57, NULL),
    ('julia','Nutrition Workshop','Interactive workshop on meal planning, macros and sustainable eating habits with Q&A.','meditation','Online', true, 'https://zoom.us/j/456', 90, 30, 83, NULL)
)
INSERT INTO classes (coach_id, title, description, type, location, is_online, meeting_link,
                     scheduled_at, duration_minutes, max_capacity, current_enrolled, status, price)
SELECT
  CASE s.coach_key WHEN 'truck' THEN c.truck ELSE c.julia END,
  s.title, s.description, s.type, s.location, s.is_online, s.meeting_link,
  now() + (s.hrs || ' hours')::interval,
  s.mins, s.cap, 0, 'scheduled', s.price
FROM seed s CROSS JOIN coaches c
WHERE (CASE s.coach_key WHEN 'truck' THEN c.truck ELSE c.julia END) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM classes x
    WHERE x.title = s.title
      AND x.coach_id = CASE s.coach_key WHEN 'truck' THEN c.truck ELSE c.julia END
  );

-- ══════════════════════════════════════════════════════════════════
-- 032_reassign_sarah_demo_to_julia.sql
-- ══════════════════════════════════════════════════════════════════
-- Remove the seeded demo coach "Sarah Johnson" (sarah@marketplace.test) from
-- view by re-homing her demo content onto Julia. Safe + idempotent: if either
-- account is missing it does nothing. Does not delete profiles (avoids FK
-- cascade surprises) — the app hides @marketplace.test accounts from Members.
DO $$
DECLARE
  v_sarah uuid;
  v_julia uuid;
BEGIN
  SELECT id INTO v_sarah FROM user_profiles
    WHERE lower(email) = 'sarah@marketplace.test'
       OR (lower(trim(first_name)) = 'sarah' AND lower(trim(last_name)) = 'johnson')
    LIMIT 1;
  SELECT id INTO v_julia FROM user_profiles
    WHERE lower(trim(first_name)) LIKE 'julia%' OR lower(trim(last_name)) LIKE 'julia%'
    LIMIT 1;

  IF v_sarah IS NULL OR v_julia IS NULL OR v_sarah = v_julia THEN
    RETURN;
  END IF;

  -- Community content authored by Sarah → Julia.
  UPDATE community_posts SET user_id  = v_julia WHERE user_id  = v_sarah;
  UPDATE post_comments   SET user_id  = v_julia WHERE user_id  = v_sarah;
  -- Reactions are just counts; drop Sarah's to avoid (post_id,user_id) clashes.
  DELETE FROM post_reactions WHERE user_id = v_sarah;

  -- Her seeded group class → Julia (so it shows under a real coach in Classes).
  UPDATE classes SET coach_id = v_julia WHERE coach_id = v_sarah;
END $$;

-- ══════════════════════════════════════════════════════════════════
-- 033_womens_health.sql
-- ══════════════════════════════════════════════════════════════════
-- Module 18 — Women's Health: menstrual cycle tracking, symptoms, and
-- cycle-aware settings. Used to derive the current phase and phase-based
-- training / recovery / nutrition guidance (computed client-side).

-- One row per logged period.
CREATE TABLE IF NOT EXISTS cycle_logs (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  start_date  date NOT NULL,
  end_date    date,
  created_at  timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_cycle_logs_user ON cycle_logs (user_id, start_date DESC);

-- Daily symptom / mood / energy check-in.
CREATE TABLE IF NOT EXISTS cycle_symptoms (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  log_date    date NOT NULL DEFAULT current_date,
  symptoms    text[] NOT NULL DEFAULT '{}',
  energy      int,   -- 1..5
  mood        int,   -- 1..5
  flow        text,  -- none|light|medium|heavy
  notes       text,
  created_at  timestamptz DEFAULT now(),
  UNIQUE (user_id, log_date)
);
CREATE INDEX IF NOT EXISTS idx_cycle_symptoms_user ON cycle_symptoms (user_id, log_date DESC);

-- Per-user cycle settings (averages used for predictions).
CREATE TABLE IF NOT EXISTS cycle_settings (
  user_id            uuid PRIMARY KEY REFERENCES user_profiles(id) ON DELETE CASCADE,
  avg_cycle_length   int NOT NULL DEFAULT 28,
  avg_period_length  int NOT NULL DEFAULT 5,
  tracking_enabled   boolean NOT NULL DEFAULT true,
  updated_at         timestamptz DEFAULT now()
);

-- ── RLS — each user manages only their own data ─────────────────────────────
ALTER TABLE cycle_logs      ENABLE ROW LEVEL SECURITY;
ALTER TABLE cycle_symptoms  ENABLE ROW LEVEL SECURITY;
ALTER TABLE cycle_settings  ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "own cycle logs" ON cycle_logs;
CREATE POLICY "own cycle logs" ON cycle_logs FOR ALL TO authenticated
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "own cycle symptoms" ON cycle_symptoms;
CREATE POLICY "own cycle symptoms" ON cycle_symptoms FOR ALL TO authenticated
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "own cycle settings" ON cycle_settings;
CREATE POLICY "own cycle settings" ON cycle_settings FOR ALL TO authenticated
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- ══════════════════════════════════════════════════════════════════
-- 034_nutrition_water_target.sql
-- ══════════════════════════════════════════════════════════════════
-- Coach can set a daily water target (oz) as part of a client's nutrition plan.
ALTER TABLE client_nutrition_plans ADD COLUMN IF NOT EXISTS water_target_oz int;

-- ══════════════════════════════════════════════════════════════════
-- 035_scoring_engine.sql
-- ══════════════════════════════════════════════════════════════════
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

-- ══════════════════════════════════════════════════════════════════
-- 036_client_plan_and_coach_media.sql
-- ══════════════════════════════════════════════════════════════════
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

-- ══════════════════════════════════════════════════════════════════
-- 037_realtime_tables.sql
-- ══════════════════════════════════════════════════════════════════
-- Enable Supabase Realtime on the tables behind the live surfaces:
-- 12 Circle Score, messages list/coach dashboard, and the coaching relationship.
-- Safe to re-run (each ADD is guarded).
DO $$ BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE user_scores;                 EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE score_events;                EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE conversations;               EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE coach_client_relationships;  EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE daily_scores;                EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE weekly_checkins;             EXCEPTION WHEN others THEN NULL; END $$;

-- ══════════════════════════════════════════════════════════════════
-- 038_stripe_connect_billing.sql
-- ══════════════════════════════════════════════════════════════════
-- ════════════════════════════════════════════════════════════════════════
-- Billing architecture refactor — Stripe Connect.
-- Platform subscriptions (Self/AI, Coach Starter/Growth/Elite) → 12 Circle's
-- own Stripe account. Coaching subscriptions/packages → the COACH's connected
-- Stripe account (destination charge), with the platform taking a commission
-- (application fee). coach_invited clients = 0%; marketplace = configurable %.
-- ════════════════════════════════════════════════════════════════════════

-- ── Coach's connected Stripe account ────────────────────────────────────────
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS stripe_account_id text;          -- acct_…
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS stripe_charges_enabled boolean NOT NULL DEFAULT false;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS stripe_payouts_enabled boolean NOT NULL DEFAULT false;
-- Commission charged to a MARKETPLACE-acquired client's coaching payments (0–1).
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS marketplace_commission_rate numeric NOT NULL DEFAULT 0.10;

-- ── How a client came to the coach (drives commission) ──────────────────────
ALTER TABLE coach_client_relationships
  ADD COLUMN IF NOT EXISTS client_source text NOT NULL DEFAULT 'marketplace'; -- 'coach_invited' | 'marketplace'

-- ── Money split, recorded on each coaching charge / subscription ────────────
ALTER TABLE payments ADD COLUMN IF NOT EXISTS service_id        uuid REFERENCES coach_packages(id) ON DELETE SET NULL;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS client_source     text;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS commission_rate   numeric;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS coach_payout      int;   -- cents to the coach
ALTER TABLE payments ADD COLUMN IF NOT EXISTS platform_fee      int;   -- cents to 12 Circle
ALTER TABLE payments ADD COLUMN IF NOT EXISTS stripe_account_id text;  -- destination acct

ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS service_id        uuid REFERENCES coach_packages(id) ON DELETE SET NULL;
ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS client_source     text;
ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS commission_rate   numeric;
ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS coach_payout      int;
ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS platform_fee      int;
ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS stripe_account_id text;

-- Backfill existing relationships: invited clients (came via a coach_invite) → 0%.
UPDATE coach_client_relationships r
   SET client_source = 'coach_invited'
  FROM coach_invites i
 WHERE i.coach_id = r.coach_id
   AND lower(i.invitee_email) = (SELECT lower(email) FROM user_profiles p WHERE p.id = r.client_id)
   AND r.client_source = 'marketplace';

-- ══════════════════════════════════════════════════════════════════
-- 039_platform_settings.sql
-- ══════════════════════════════════════════════════════════════════
-- Admin-configurable platform settings (key/value). Seeds the marketplace
-- commission rate (0–1). create-checkout reads this for marketplace clients.
CREATE TABLE IF NOT EXISTS platform_settings (
  key        text PRIMARY KEY,
  value      text NOT NULL,
  updated_at timestamptz DEFAULT now()
);

INSERT INTO platform_settings (key, value) VALUES
  ('marketplace_commission_rate', '0.10')
ON CONFLICT (key) DO NOTHING;

ALTER TABLE platform_settings ENABLE ROW LEVEL SECURITY;

-- Any authenticated user can READ settings (checkout/coach need the rate).
DROP POLICY IF EXISTS "read platform settings" ON platform_settings;
CREATE POLICY "read platform settings" ON platform_settings
  FOR SELECT TO authenticated USING (true);

-- Only admins can change them.
DROP POLICY IF EXISTS "admin writes platform settings" ON platform_settings;
CREATE POLICY "admin writes platform settings" ON platform_settings
  FOR ALL TO authenticated
  USING      (EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin'));

-- ══════════════════════════════════════════════════════════════════
-- 040_invite_client_source.sql
-- ══════════════════════════════════════════════════════════════════
-- ════════════════════════════════════════════════════════════════════════
-- Invite Client Flow → client_source = 'coach_invited' (0% marketplace commission).
-- Any relationship whose client was invited by that same coach (an existing
-- coach_invite matching the client's email) is automatically tagged
-- 'coach_invited'. This drives a 0% commission everywhere downstream
-- (create-checkout reads the relationship's client_source). Covers every path
-- that creates a relationship: client request approval, coach-added client, or
-- invite acceptance.
-- Idempotent.
-- ════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION set_relationship_client_source()
RETURNS trigger AS $$
BEGIN
  -- Only auto-decide when the caller didn't explicitly tag the source.
  IF NEW.client_source IS NULL OR NEW.client_source = 'marketplace' THEN
    IF EXISTS (
      SELECT 1
        FROM coach_invites i
        JOIN user_profiles p ON p.id = NEW.client_id
       WHERE i.coach_id = NEW.coach_id
         AND lower(i.invitee_email) = lower(p.email)
    ) THEN
      NEW.client_source := 'coach_invited';
    ELSE
      NEW.client_source := COALESCE(NEW.client_source, 'marketplace');
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_relationship_client_source ON coach_client_relationships;
CREATE TRIGGER trg_relationship_client_source
  BEFORE INSERT ON coach_client_relationships
  FOR EACH ROW EXECUTE FUNCTION set_relationship_client_source();

-- Re-run the backfill (idempotent) in case 040 lands before any new signups.
UPDATE coach_client_relationships r
   SET client_source = 'coach_invited'
  FROM coach_invites i
 WHERE i.coach_id = r.coach_id
   AND lower(i.invitee_email) = (SELECT lower(email) FROM user_profiles p WHERE p.id = r.client_id)
   AND r.client_source = 'marketplace';

-- ══════════════════════════════════════════════════════════════════
-- 041_marketplace_ranking.sql
-- ══════════════════════════════════════════════════════════════════
-- ════════════════════════════════════════════════════════════════════════
-- Marketplace ranking with an Elite-coach boost.
-- Clients can't read other users' subscriptions (RLS), so ranking by plan tier
-- has to run server-side. This SECURITY DEFINER function returns every coach
-- with their active platform plan tier and a blended rank_score:
--   score = rating (0–5) + review-volume bump (≤1) + tier boost
--   tier boost: elite +1.5, growth +0.75, starter +0.25, none 0
-- Elite coaches surface at the top without burying a genuinely 5-star coach
-- under an unrated one. is_featured flags elite/growth for a marketplace badge.
-- Idempotent.
-- ════════════════════════════════════════════════════════════════════════

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
  )
  SELECT p.id, p.first_name, p.last_name, p.avatar_url, p.coach_title,
         p.tagline, p.bio, p.specialties, p.certifications, p.pricing_monthly,
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
   WHERE p.role = 'coach'
   ORDER BY rank_score DESC, p.rating_avg DESC NULLS LAST, p.review_count DESC NULLS LAST;
$$;

GRANT EXECUTE ON FUNCTION public.marketplace_coaches() TO authenticated;

