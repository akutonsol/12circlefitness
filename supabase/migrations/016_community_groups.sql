-- Community groups and memberships
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

CREATE POLICY "all read groups"
  ON community_groups FOR SELECT TO authenticated USING (true);

CREATE POLICY "users manage own group membership"
  ON community_group_members FOR ALL TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "all read group members"
  ON community_group_members FOR SELECT TO authenticated USING (true);

-- Seed default groups (fixed UUIDs so re-runs are idempotent)
INSERT INTO community_groups (id, name, description, emoji) VALUES
  ('10000000-0000-0000-0000-000000000001', 'Transformation Squad',  'Share your progress and inspire others on their transformation journey', '💪'),
  ('10000000-0000-0000-0000-000000000002', 'Nutrition Warriors',     'Meal prep tips, recipes, and nutrition accountability',                 '🥗'),
  ('10000000-0000-0000-0000-000000000003', 'Mindset & Wellness',     'Mental health, meditation, and holistic wellness discussions',          '🧘'),
  ('10000000-0000-0000-0000-000000000004', 'Beginners Circle',       'A safe space for those just starting their fitness journey',            '🌱'),
  ('10000000-0000-0000-0000-000000000005', 'Advanced Athletes',      'For experienced members pushing their limits',                          '🏆')
ON CONFLICT (id) DO NOTHING;
