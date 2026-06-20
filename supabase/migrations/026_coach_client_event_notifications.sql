-- ═══════════════════════════════════════════════════════════════════════════
-- Coach gets notified about client activity (e.g. client completes a workout).
-- Extends the existing workout-complete trigger to ALSO notify the client's
-- active coach. Idempotent — safe to run more than once.
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION trg_notify_on_workout_complete()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_coach_id uuid;
  v_name     text;
BEGIN
  IF (NEW.status = 'completed' AND (OLD.status IS DISTINCT FROM 'completed')) THEN
    -- 1. Notify the client (existing behaviour).
    PERFORM insert_notification(
      NEW.user_id,
      'workout',
      'Workout complete! 💪',
      'Great work finishing ' || COALESCE(NEW.workout_name, 'your session') ||
        '. Keep that momentum going!',
      jsonb_build_object('session_id', NEW.id, 'duration_seconds', NEW.duration_seconds)
    );

    -- 2. Notify the client's active coach.
    SELECT coach_id INTO v_coach_id
      FROM coach_client_relationships
      WHERE client_id = NEW.user_id AND status = 'active'
      LIMIT 1;

    IF v_coach_id IS NOT NULL THEN
      SELECT TRIM(COALESCE(first_name, '') || ' ' || COALESCE(last_name, ''))
        INTO v_name FROM user_profiles WHERE id = NEW.user_id;
      PERFORM insert_notification(
        v_coach_id,
        'client_workout',
        COALESCE(NULLIF(v_name, ''), 'A client') || ' completed a workout',
        COALESCE(NULLIF(v_name, ''), 'Your client') || ' just finished ' ||
          COALESCE(NEW.workout_name, 'a session') || '.',
        jsonb_build_object('client_id', NEW.user_id, 'session_id', NEW.id)
      );
    END IF;
  END IF;
  RETURN NEW;
END;
$$;
