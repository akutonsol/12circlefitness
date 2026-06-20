-- ══════════════════════════════════════════════════════════════════════════════
-- PASTE THIS ENTIRE FILE INTO THE SUPABASE DASHBOARD SQL EDITOR AND RUN IT.
-- Go to: https://supabase.com/dashboard → Your Project → SQL Editor → New Query
-- ══════════════════════════════════════════════════════════════════════════════

-- ── Migration 010: Notification preference columns ────────────────────────────
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS coach_title TEXT DEFAULT 'Personal Health Coach';
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS coach_bio TEXT DEFAULT '';
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS max_clients INTEGER DEFAULT 20;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS is_accepting_clients BOOLEAN DEFAULT TRUE;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS unit_preference TEXT DEFAULT 'imperial';
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS membership_tier TEXT DEFAULT 'basic';
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS notif_workout_reminders BOOLEAN DEFAULT TRUE;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS notif_checkin_reminders BOOLEAN DEFAULT TRUE;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS notif_coach_messages   BOOLEAN DEFAULT TRUE;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS notif_progress_updates BOOLEAN DEFAULT TRUE;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS notif_challenges        BOOLEAN DEFAULT FALSE;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS notif_community         BOOLEAN DEFAULT FALSE;

-- ── Migration 013: PAR-Q / health assessment columns ─────────────────────────
ALTER TABLE user_profiles
  ADD COLUMN IF NOT EXISTS parq_answers             JSONB        NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS medical_conditions       TEXT         NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS has_injuries             BOOLEAN      NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS injury_locations         TEXT         NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS injury_description       TEXT         NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS experience_level         TEXT         NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS worked_with_coach_before BOOLEAN      NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS sleep_hours              TEXT         NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS stress_level             INTEGER      NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS occupation               TEXT         NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS dietary_restrictions     TEXT         NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS food_allergies           TEXT         NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS target_timeline          TEXT         NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS consent_agreed           BOOLEAN      NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS consent_date             TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS risk_score               INTEGER      NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS risk_level               TEXT         NOT NULL DEFAULT 'low',
  ADD COLUMN IF NOT EXISTS risk_flags               TEXT         NOT NULL DEFAULT '';

CREATE INDEX IF NOT EXISTS idx_user_profiles_risk_level
  ON user_profiles (risk_level)
  WHERE risk_level IN ('moderate', 'high');

-- ── Migration 014: Fix nutrition_logs missing columns ─────────────────────────
ALTER TABLE nutrition_logs
  ADD COLUMN IF NOT EXISTS serving_unit TEXT NOT NULL DEFAULT 'g',
  ADD COLUMN IF NOT EXISTS created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- ── Migration 015: user_profiles RLS + self-update policy ────────────────────
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "profiles are viewable by authenticated users" ON user_profiles;
CREATE POLICY "profiles are viewable by authenticated users"
  ON user_profiles FOR SELECT TO authenticated
  USING (true);

DROP POLICY IF EXISTS "users can insert own profile" ON user_profiles;
CREATE POLICY "users can insert own profile"
  ON user_profiles FOR INSERT TO authenticated
  WITH CHECK (id = auth.uid());

DROP POLICY IF EXISTS "users can update own profile" ON user_profiles;
CREATE POLICY "users can update own profile"
  ON user_profiles FOR UPDATE TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Allow coaches to update client profiles
DROP POLICY IF EXISTS "coaches can update client profiles" ON user_profiles;
CREATE POLICY "coaches can update client profiles"
  ON user_profiles FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM coach_client_relationships
      WHERE coach_id = auth.uid() AND client_id = user_profiles.id AND status = 'active'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM coach_client_relationships
      WHERE coach_id = auth.uid() AND client_id = user_profiles.id AND status = 'active'
    )
  );

-- ── Migration 016: Gender and Date of Birth ───────────────────────────────────
ALTER TABLE user_profiles
  ADD COLUMN IF NOT EXISTS gender         TEXT,
  ADD COLUMN IF NOT EXISTS date_of_birth  DATE;

-- ── Migration 017: AI Client Summary ─────────────────────────────────────────
ALTER TABLE user_profiles
  ADD COLUMN IF NOT EXISTS ai_client_summary TEXT DEFAULT '';

-- ── Migration 018: Explicit INSERT policies for challenge_participants ─────────
-- The FOR ALL ... USING policy doesn't always cover INSERT in all PG versions.
-- Adding explicit INSERT + SELECT policies to be safe.
DROP POLICY IF EXISTS "users join challenges" ON challenge_participants;
CREATE POLICY "users join challenges"
  ON challenge_participants FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users read all participants" ON challenge_participants;
CREATE POLICY "users read all participants"
  ON challenge_participants FOR SELECT TO authenticated
  USING (true);

-- ── Migration 019: Community groups and memberships ───────────────────────────
CREATE TABLE IF NOT EXISTS community_groups (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name         text NOT NULL,
  description  text,
  emoji        text DEFAULT '💪',
  member_count integer DEFAULT 0,
  created_at   timestamptz DEFAULT now()
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

DROP POLICY IF EXISTS "users join groups" ON community_group_members;
CREATE POLICY "users join groups"
  ON community_group_members FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users leave groups" ON community_group_members;
CREATE POLICY "users leave groups"
  ON community_group_members FOR DELETE TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "all read group members" ON community_group_members;
CREATE POLICY "all read group members"
  ON community_group_members FOR SELECT TO authenticated USING (true);

-- Seed default groups (fixed UUIDs so re-runs are safe)
INSERT INTO community_groups (id, name, description, emoji) VALUES
  ('10000000-0000-0000-0000-000000000001', 'Transformation Squad',  'Share your progress and inspire others on their transformation journey', '💪'),
  ('10000000-0000-0000-0000-000000000002', 'Nutrition Warriors',     'Meal prep tips, recipes, and nutrition accountability',                 '🥗'),
  ('10000000-0000-0000-0000-000000000003', 'Mindset & Wellness',     'Mental health, meditation, and holistic wellness discussions',          '🧘'),
  ('10000000-0000-0000-0000-000000000004', 'Beginners Circle',       'A safe space for those just starting their fitness journey',            '🌱'),
  ('10000000-0000-0000-0000-000000000005', 'Advanced Athletes',      'For experienced members pushing their limits',                          '🏆')
ON CONFLICT (id) DO NOTHING;

-- ══════════════════════════════════════════════════════════════════════════════
-- Done. Reload the app after running this.
-- ══════════════════════════════════════════════════════════════════════════════
