-- Migration 056: PR detection respects an exercise's supports_pr_tracking flag
--
-- detect_pr_on_set_log() (049) flagged any new weight PR. If a library exercise
-- (matched by exact name) is marked supports_pr_tracking = false, skip the PR.
-- Only an exact-name match with the flag explicitly false suppresses it, so
-- there are no accidental skips.

create or replace function public.detect_pr_on_set_log()
returns trigger language plpgsql security definer as $$
declare
  v_prior numeric; v_coach uuid; v_name text; v_recent int; v_supports boolean;
begin
  if NEW.weight_kg is null or NEW.weight_kg <= 0 then return NEW; end if;

  -- Respect the exercise's PR-tracking flag (only an exact library match with
  -- the flag false suppresses PR detection).
  select supports_pr_tracking into v_supports
    from custom_exercises
    where lower(name) = lower(NEW.exercise_name)
      and visibility = 'global' and submission_status = 'approved'
    limit 1;
  if v_supports is false then return NEW; end if;

  select max(weight_kg) into v_prior from workout_set_logs
    where user_id = NEW.user_id and exercise_name = NEW.exercise_name and id <> NEW.id;
  if v_prior is null or v_prior <= 0 or NEW.weight_kg <= v_prior then return NEW; end if;

  select count(*) into v_recent from notifications
    where recipient_id = NEW.user_id and type = 'pr_achieved'
      and data->>'exercise' = NEW.exercise_name
      and created_at > now() - interval '2 hours';
  if v_recent > 0 then return NEW; end if;

  select nullif(trim(coalesce(first_name,'') || ' ' || coalesce(last_name,'')), '')
    into v_name from user_profiles where id = NEW.user_id;

  insert into notifications (recipient_id, type, title, body, data, read)
  values (NEW.user_id, 'pr_achieved', 'New Personal Record! 🎉',
    'You hit a new PR on ' || NEW.exercise_name || ': ' ||
      trim(to_char(NEW.weight_kg, 'FM999990.0')) || ' kg.',
    jsonb_build_object('exercise', NEW.exercise_name, 'weight_kg', NEW.weight_kg), false);

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
