-- Coach profile columns (referenced in Flutter code but missing from earlier migrations)
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS coach_title TEXT DEFAULT 'Personal Health Coach';
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS coach_bio TEXT DEFAULT '';
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS max_clients INTEGER DEFAULT 20;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS is_accepting_clients BOOLEAN DEFAULT TRUE;

-- User preferences
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS unit_preference TEXT DEFAULT 'imperial'
  CHECK (unit_preference IN ('imperial', 'metric'));

ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS membership_tier TEXT DEFAULT 'basic'
  CHECK (membership_tier IN ('basic', 'pro', 'elite'));

-- Notification preferences (individual toggles per notification type)
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS notif_workout_reminders BOOLEAN DEFAULT TRUE;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS notif_checkin_reminders BOOLEAN DEFAULT TRUE;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS notif_coach_messages   BOOLEAN DEFAULT TRUE;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS notif_progress_updates BOOLEAN DEFAULT TRUE;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS notif_challenges        BOOLEAN DEFAULT FALSE;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS notif_community         BOOLEAN DEFAULT FALSE;

-- Backfill defaults for existing rows
UPDATE user_profiles SET
  unit_preference  = COALESCE(unit_preference,  'imperial'),
  membership_tier  = COALESCE(membership_tier,  'basic'),
  is_accepting_clients = COALESCE(is_accepting_clients, TRUE),
  max_clients      = COALESCE(max_clients, 20)
WHERE unit_preference IS NULL
   OR membership_tier IS NULL;
