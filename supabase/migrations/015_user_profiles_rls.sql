-- 015: Enable RLS on user_profiles and add self-management policies.
-- Without these policies, UPDATE calls from authenticated users may fail if
-- RLS was implicitly enabled by Supabase's security settings.

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users to read profiles (needed for coach directory etc.)
DROP POLICY IF EXISTS "profiles are viewable by authenticated users" ON user_profiles;
CREATE POLICY "profiles are viewable by authenticated users"
  ON user_profiles FOR SELECT TO authenticated
  USING (true);

-- Allow users to insert their own profile row (signup / onboarding)
DROP POLICY IF EXISTS "users can insert own profile" ON user_profiles;
CREATE POLICY "users can insert own profile"
  ON user_profiles FOR INSERT TO authenticated
  WITH CHECK (id = auth.uid());

-- Allow users to update their own profile row
DROP POLICY IF EXISTS "users can update own profile" ON user_profiles;
CREATE POLICY "users can update own profile"
  ON user_profiles FOR UPDATE TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Allow coaches to update their clients' profiles (e.g. assign programs)
DROP POLICY IF EXISTS "coaches can update client profiles" ON user_profiles;
CREATE POLICY "coaches can update client profiles"
  ON user_profiles FOR UPDATE TO authenticated
  USING (
    id IN (
      SELECT client_id FROM coach_client_relationships
      WHERE coach_id = auth.uid() AND status = 'active'
    )
  )
  WITH CHECK (
    id IN (
      SELECT client_id FROM coach_client_relationships
      WHERE coach_id = auth.uid() AND status = 'active'
    )
  );
