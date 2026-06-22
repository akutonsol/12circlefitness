-- Migration 049: workout-completion + PR notifications (Module 4 WS-004, TR-002, Section 6)
--
-- WS-004: when a client completes a workout, their coach must be notified.
-- TR-002: a new personal record must be auto-detected and notify client + coach.
-- Implemented as triggers so they fire regardless of which client path wrote the
-- data (and can't be skipped by the app).

-- ── Notify the client's coach when a workout session is completed ──
create or replace function public.notify_coach_workout_complete()
returns trigger language plpgsql security definer as $$
declare v_coach uuid; v_name text;
begin
  if NEW.status = 'completed' and OLD.status is distinct from 'completed' then
    select coach_id into v_coach from coach_client_relationships
      where client_id = NEW.user_id and status = 'active'
      order by activated_at desc nulls last limit 1;
    if v_coach is not null then
      select nullif(trim(coalesce(first_name,'') || ' ' || coalesce(last_name,'')), '')
        into v_name from user_profiles where id = NEW.user_id;
      insert into notifications (recipient_id, type, title, body, data, read)
      values (v_coach, 'workout_completed', 'Workout Completed',
        coalesce(v_name, 'Your client') || ' completed "' ||
          coalesce(NEW.workout_title, 'a workout') || '".',
        jsonb_build_object('client_id', NEW.user_id, 'session_id', NEW.id), false);
    end if;
  end if;
  return NEW;
end;
$$;

drop trigger if exists trg_notify_coach_workout_complete on workout_sessions;
create trigger trg_notify_coach_workout_complete
  after update on workout_sessions
  for each row execute function public.notify_coach_workout_complete();

-- ── Detect a new weight PR on each logged set; notify client + coach ──
create or replace function public.detect_pr_on_set_log()
returns trigger language plpgsql security definer as $$
declare v_prior numeric; v_coach uuid; v_name text; v_recent int;
begin
  if NEW.weight_kg is null or NEW.weight_kg <= 0 then return NEW; end if;

  -- Prior best for this exercise (excluding the row just inserted).
  select max(weight_kg) into v_prior from workout_set_logs
    where user_id = NEW.user_id and exercise_name = NEW.exercise_name and id <> NEW.id;
  -- Only a PR if there's a prior baseline and we beat it (first-ever isn't a "PR").
  if v_prior is null or v_prior <= 0 or NEW.weight_kg <= v_prior then return NEW; end if;

  -- Dedup: at most one PR notification per exercise per ~session (2h window).
  select count(*) into v_recent from notifications
    where recipient_id = NEW.user_id and type = 'pr_achieved'
      and data->>'exercise' = NEW.exercise_name
      and created_at > now() - interval '2 hours';
  if v_recent > 0 then return NEW; end if;

  select nullif(trim(coalesce(first_name,'') || ' ' || coalesce(last_name,'')), '')
    into v_name from user_profiles where id = NEW.user_id;

  -- Client notification.
  insert into notifications (recipient_id, type, title, body, data, read)
  values (NEW.user_id, 'pr_achieved', 'New Personal Record! 🎉',
    'You hit a new PR on ' || NEW.exercise_name || ': ' ||
      trim(to_char(NEW.weight_kg, 'FM999990.0')) || ' kg.',
    jsonb_build_object('exercise', NEW.exercise_name, 'weight_kg', NEW.weight_kg), false);

  -- Coach notification (if any active coach).
  select coach_id into v_coach from coach_client_relationships
    where client_id = NEW.user_id and status = 'active'
    order by activated_at desc nulls last limit 1;
  if v_coach is not null then
    insert into notifications (recipient_id, type, title, body, data, read)
    values (v_coach, 'pr_achieved', 'Client PR 🎉',
      coalesce(v_name, 'Your client') || ' hit a new PR on ' || NEW.exercise_name ||
        ': ' || trim(to_char(NEW.weight_kg, 'FM999990.0')) || ' kg.',
      jsonb_build_object('client_id', NEW.user_id, 'exercise', NEW.exercise_name,
                         'weight_kg', NEW.weight_kg), false);
  end if;

  return NEW;
end;
$$;

drop trigger if exists trg_detect_pr on workout_set_logs;
create trigger trg_detect_pr
  after insert on workout_set_logs
  for each row execute function public.detect_pr_on_set_log();
