-- Coach availability slots (published by coaches for clients to book)
CREATE TABLE IF NOT EXISTS coach_availability (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id         UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  slot_time        TIMESTAMPTZ NOT NULL,
  duration_minutes INTEGER NOT NULL DEFAULT 30,
  type             TEXT NOT NULL DEFAULT 'check_in'
    CHECK (type IN ('check_in', 'consultation', 'nutrition_review', 'strategy')),
  is_booked        BOOLEAN NOT NULL DEFAULT FALSE,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

-- Booked coaching calls
CREATE TABLE IF NOT EXISTS coaching_calls (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id              UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  client_id             UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  availability_slot_id  UUID REFERENCES coach_availability(id),
  scheduled_at          TIMESTAMPTZ NOT NULL,
  duration_minutes      INTEGER NOT NULL DEFAULT 30,
  call_type             TEXT NOT NULL DEFAULT 'check_in',
  status                TEXT NOT NULL DEFAULT 'scheduled'
    CHECK (status IN ('scheduled', 'completed', 'cancelled', 'no_show')),
  notes                 TEXT,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- User integrations (third-party app connections)
CREATE TABLE IF NOT EXISTS user_integrations (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  provider         TEXT NOT NULL,
  connected        BOOLEAN NOT NULL DEFAULT TRUE,
  access_token     TEXT,
  refresh_token    TEXT,
  connected_at     TIMESTAMPTZ DEFAULT NOW(),
  disconnected_at  TIMESTAMPTZ,
  UNIQUE (user_id, provider)
);

-- RLS
ALTER TABLE coach_availability  ENABLE ROW LEVEL SECURITY;
ALTER TABLE coaching_calls       ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_integrations    ENABLE ROW LEVEL SECURITY;

-- coach_availability: coaches manage their own; clients can read
CREATE POLICY "coach_manage_availability" ON coach_availability
  FOR ALL USING (auth.uid() = coach_id);
CREATE POLICY "client_read_availability" ON coach_availability
  FOR SELECT USING (TRUE);

-- coaching_calls: participants can read their own
CREATE POLICY "calls_participant_access" ON coaching_calls
  FOR ALL USING (auth.uid() = coach_id OR auth.uid() = client_id);

-- user_integrations: users manage their own
CREATE POLICY "user_own_integrations" ON user_integrations
  FOR ALL USING (auth.uid() = user_id);
