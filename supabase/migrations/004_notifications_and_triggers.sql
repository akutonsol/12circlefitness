-- ═══════════════════════════════════════════════════════════════
-- 12 Circle Fitness — Notifications Table + DB Triggers
-- Run in Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════════

-- ── 1. Ensure notifications table exists ────────────────────────────────────
CREATE TABLE IF NOT EXISTS notifications (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_id uuid REFERENCES user_profiles(id) ON DELETE CASCADE,
  type         text NOT NULL DEFAULT 'general',
  title        text NOT NULL,
  body         text NOT NULL DEFAULT '',
  read         boolean NOT NULL DEFAULT false,
  data         jsonb,
  created_at   timestamptz DEFAULT now()
);

-- Index for fast per-user queries ordered by time
CREATE INDEX IF NOT EXISTS idx_notifications_recipient_time
  ON notifications (recipient_id, created_at DESC);

-- ── 2. RLS (safe re-run) ─────────────────────────────────────────────────────
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "recipients read own notifications" ON notifications;
CREATE POLICY "recipients read own notifications"
  ON notifications FOR SELECT TO authenticated
  USING (recipient_id = auth.uid());

DROP POLICY IF EXISTS "system can insert notifications" ON notifications;
CREATE POLICY "system can insert notifications"
  ON notifications FOR INSERT TO authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "recipients update own notifications" ON notifications;
CREATE POLICY "recipients update own notifications"
  ON notifications FOR UPDATE TO authenticated
  USING (recipient_id = auth.uid());

DROP POLICY IF EXISTS "recipients delete own notifications" ON notifications;
CREATE POLICY "recipients delete own notifications"
  ON notifications FOR DELETE TO authenticated
  USING (recipient_id = auth.uid());

-- Realtime (safe re-run)
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
EXCEPTION WHEN others THEN NULL; END $$;

-- ═══════════════════════════════════════════════════════════════
-- TRIGGER HELPER
-- ═══════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION insert_notification(
  p_recipient_id uuid,
  p_type         text,
  p_title        text,
  p_body         text,
  p_data         jsonb DEFAULT NULL
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO notifications (recipient_id, type, title, body, data)
  VALUES (p_recipient_id, p_type, p_title, p_body, p_data);
END;
$$;

-- ═══════════════════════════════════════════════════════════════
-- TRIGGER 1 — New inbound message → notify recipient
-- ═══════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION trg_notify_on_message()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_recipient_id uuid;
  v_sender_name  text;
BEGIN
  -- Find the OTHER participant in the conversation
  SELECT CASE
    WHEN participant_1 = NEW.sender_id THEN participant_2
    ELSE participant_1
  END INTO v_recipient_id
  FROM conversations
  WHERE id = NEW.conversation_id;

  IF v_recipient_id IS NULL OR v_recipient_id = NEW.sender_id THEN
    RETURN NEW;
  END IF;

  SELECT COALESCE(first_name || ' ' || last_name, email, 'Someone')
  INTO v_sender_name
  FROM user_profiles WHERE id = NEW.sender_id;

  PERFORM insert_notification(
    v_recipient_id,
    'message',
    'New message from ' || v_sender_name,
    LEFT(NEW.content, 120),
    jsonb_build_object('conversation_id', NEW.conversation_id, 'sender_id', NEW.sender_id)
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS notify_on_message ON messages;
CREATE TRIGGER notify_on_message
  AFTER INSERT ON messages
  FOR EACH ROW EXECUTE FUNCTION trg_notify_on_message();

-- ═══════════════════════════════════════════════════════════════
-- TRIGGER 2 — Workout session completed → notify user
-- ═══════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION trg_notify_on_workout_complete()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  -- Only fire when status transitions to 'completed'
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

DROP TRIGGER IF EXISTS notify_on_workout_complete ON workout_sessions;
CREATE TRIGGER notify_on_workout_complete
  AFTER UPDATE ON workout_sessions
  FOR EACH ROW EXECUTE FUNCTION trg_notify_on_workout_complete();

-- ═══════════════════════════════════════════════════════════════
-- TRIGGER 3 — Weekly check-in submitted → notify coach
-- ═══════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION trg_notify_coach_on_checkin()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_client_name text;
  v_coach_id    uuid;
BEGIN
  -- Get the coach from the check-in's coach_id column
  v_coach_id := NEW.coach_id;
  IF v_coach_id IS NULL THEN RETURN NEW; END IF;

  SELECT COALESCE(first_name, email, 'Your client')
  INTO v_client_name
  FROM user_profiles WHERE id = NEW.user_id;

  PERFORM insert_notification(
    v_coach_id,
    'weekly_checkins',
    v_client_name || ' submitted Week ' || COALESCE(NEW.week_number::text, '?') || ' check-in',
    'Weight: ' || COALESCE(NEW.weight_kg::text, '—') || 'kg | '
      || 'Energy: ' || COALESCE(NEW.energy_level::text, '—') || '/5 | '
      || 'Compliance: ' || COALESCE(NEW.compliance_percent::text, '—') || '%',
    jsonb_build_object('checkin_id', NEW.id, 'client_id', NEW.user_id)
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS notify_coach_on_checkin ON weekly_checkins;
CREATE TRIGGER notify_coach_on_checkin
  AFTER INSERT ON weekly_checkins
  FOR EACH ROW EXECUTE FUNCTION trg_notify_coach_on_checkin();

-- ═══════════════════════════════════════════════════════════════
-- TRIGGER 4 — New challenge participant → notify the coach
-- ═══════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION trg_notify_on_challenge_join()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_coach_id      uuid;
  v_challenge_name text;
  v_joiner_name   text;
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

DROP TRIGGER IF EXISTS notify_on_challenge_join ON challenge_participants;
CREATE TRIGGER notify_on_challenge_join
  AFTER INSERT ON challenge_participants
  FOR EACH ROW EXECUTE FUNCTION trg_notify_on_challenge_join();

-- ═══════════════════════════════════════════════════════════════
-- TRIGGER 5 — Class booking confirmed → notify user
-- ═══════════════════════════════════════════════════════════════
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

DROP TRIGGER IF EXISTS notify_on_class_booking ON class_bookings;
CREATE TRIGGER notify_on_class_booking
  AFTER INSERT ON class_bookings
  FOR EACH ROW EXECUTE FUNCTION trg_notify_on_class_booking();

-- ═══════════════════════════════════════════════════════════════
-- TRIGGER 6 — New coach review posted → notify the coach
-- ═══════════════════════════════════════════════════════════════
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

DROP TRIGGER IF EXISTS notify_on_coach_review ON coach_reviews;
CREATE TRIGGER notify_on_coach_review
  AFTER INSERT ON coach_reviews
  FOR EACH ROW EXECUTE FUNCTION trg_notify_on_coach_review();

-- ═══════════════════════════════════════════════════════════════
-- TEST DATA — Insert sample notifications for both test users
-- (Runs inside a DO block so it can use SELECT to find user IDs)
-- ═══════════════════════════════════════════════════════════════
DO $$
DECLARE
  v_client_id uuid;
  v_coach_id  uuid;
BEGIN
  SELECT id INTO v_client_id FROM user_profiles WHERE email = 'testclient@12circle.com' LIMIT 1;
  SELECT id INTO v_coach_id  FROM user_profiles WHERE email = 'testcoach@12circle.com'  LIMIT 1;

  IF v_client_id IS NULL AND v_coach_id IS NULL THEN
    RAISE NOTICE 'Test users not found — skipping notification seeds.';
    RETURN;
  END IF;

  IF v_client_id IS NOT NULL THEN
    INSERT INTO notifications (recipient_id, type, title, body, read, created_at) VALUES
      (v_client_id, 'workout',            'Workout unlocked 🏋️',
        'Your Full Body Strength session for today is ready. Tap to start.',
        false,  NOW() - INTERVAL '8 minutes'),
      (v_client_id, 'message',            'New message from Coach Alex',
        'You''re crushing your protein goals! Let''s keep this momentum for tomorrow 💪',
        false,  NOW() - INTERVAL '2 hours'),
      (v_client_id, 'today_score',        'Daily score updated ✨',
        'Your 12Circle score just jumped +4 points. You''re at 71/100 today!',
        false,  NOW() - INTERVAL '3 hours'),
      (v_client_id, 'nutrition_assigned', 'Log your lunch 🍽️',
        'You haven''t logged lunch yet. Staying on track helps hit your 2,000 cal target.',
        true,   NOW() - INTERVAL '1 day 1 hour'),
      (v_client_id, 'challenges',         '🏆 Challenge update',
        '10k Steps Challenge: you''re in 3rd place with 12 days logged! Push for the top!',
        true,   NOW() - INTERVAL '1 day 5 hours'),
      (v_client_id, 'user',               '🔥 7-Day Streak achieved!',
        'You''re in the top 5% this week. Incredible consistency — keep it rolling!',
        true,   NOW() - INTERVAL '1 day 8 hours'),
      (v_client_id, 'messages',           'Class reminder ⏰',
        'Your Live Q&A with Alex is in 1 hour. Join via the Classes tab.',
        true,   NOW() - INTERVAL '3 days'),
      (v_client_id, 'coach_request',      'Coach feedback received',
        'Alex reviewed your Week 3 check-in: "Strong week! Nutrition compliance was excellent."',
        true,   NOW() - INTERVAL '4 days'),
      (v_client_id, 'today_score',        'New Personal Best! 🎉',
        'You hit a squat PR of 85kg. That''s incredible — a new all-time high!',
        true,   NOW() - INTERVAL '7 days')
    ON CONFLICT DO NOTHING;
  END IF;

  IF v_coach_id IS NOT NULL THEN
    INSERT INTO notifications (recipient_id, type, title, body, read, created_at) VALUES
      (v_coach_id, 'weekly_checkins', 'Jordan completed Week 3 check-in ✅',
        'Weight: 81.2kg | Energy: 4/5 | Compliance: 92%. Review now.',
        false, NOW() - INTERVAL '1 hour'),
      (v_coach_id, 'message',         'New message from Jordan',
        'Weigh-in this morning: 81.9kg. Down from 82.5kg — progress!',
        false, NOW() - INTERVAL '6 hours'),
      (v_coach_id, 'challenges',      'Maria joined your challenge',
        'Maria Chen is now competing in "Summer Shred Challenge". 14 participants total.',
        true,  NOW() - INTERVAL '1 day 2 hours'),
      (v_coach_id, 'coach_request',   '5⭐ review from Maria Chen',
        'Maria left you a 5-star review: "Alex completely transformed my training mindset!" 🌟',
        true,  NOW() - INTERVAL '2 days')
    ON CONFLICT DO NOTHING;
  END IF;
END;
$$;
