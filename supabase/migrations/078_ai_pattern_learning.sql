-- Migration 078: behavioral pattern learning (AI Memory Engine, advanced)
--
-- Scans the user's logs for durable behavioral patterns and writes them into
-- ai_profiles.behavioral_patterns + ai_memories (kind='pattern'), so the coach
-- learns instead of asking the same questions. Run before each generation.

create or replace function public.ai_detect_patterns(p_uid uuid)
returns void language plpgsql security definer as $$
declare
  v_best int; v_worst int; v_best_day text; v_missed_day text;
  v_avg_min int; v_bf int; v_din int;
  dow text[] := array['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'];
begin
  -- Workout day-of-week distribution (completed sessions, last 70 days).
  with d as (
    select extract(dow from started_at)::int as dw, count(*) c
    from workout_sessions
    where user_id = p_uid and status = 'completed' and started_at > now() - interval '70 days'
    group by 1
  )
  select (select dw from d order by c desc, dw limit 1),
         (select dw from d order by c asc,  dw limit 1)
  into v_best, v_worst;

  select round(avg(duration_seconds) / 60.0)::int into v_avg_min
    from workout_sessions
    where user_id = p_uid and status = 'completed' and duration_seconds > 0
      and started_at > now() - interval '70 days';

  select count(*) filter (where meal_type = 'breakfast'),
         count(*) filter (where meal_type = 'dinner')
    into v_bf, v_din
    from nutrition_logs where user_id = p_uid and logged_at > now() - interval '30 days';

  v_best_day   := case when v_best  is not null then dow[v_best + 1] end;
  v_missed_day := case when v_worst is not null and v_worst <> coalesce(v_best, -1) then dow[v_worst + 1] end;

  -- Persist behavioral patterns on the profile.
  insert into ai_profiles (user_id, behavioral_patterns)
  values (p_uid, jsonb_strip_nulls(jsonb_build_object(
    'best_adherence_day', v_best_day, 'missed_workout_day', v_missed_day,
    'average_workout_time', v_avg_min)))
  on conflict (user_id) do update
    set behavioral_patterns = jsonb_strip_nulls(jsonb_build_object(
          'best_adherence_day', v_best_day, 'missed_workout_day', v_missed_day,
          'average_workout_time', v_avg_min)),
        updated_at = now();

  -- Recompute pattern memories fresh (replace, don't accumulate stale ones).
  delete from ai_memories where user_id = p_uid and kind = 'pattern';
  if v_best_day is not null and v_avg_min is not null then
    insert into ai_memories (user_id, kind, content, source) values
      (p_uid, 'pattern', 'Trains most consistently on ' || v_best_day || ' (~' || v_avg_min || ' min sessions)', 'inferred')
      on conflict (user_id, kind, content) do nothing;
  end if;
  if v_missed_day is not null then
    insert into ai_memories (user_id, kind, content, source) values
      (p_uid, 'pattern', 'Tends to miss ' || v_missed_day || ' workouts', 'inferred')
      on conflict (user_id, kind, content) do nothing;
  end if;
  if v_bf >= 5 and v_din <= greatest(1, v_bf / 3) then
    insert into ai_memories (user_id, kind, content, source) values
      (p_uid, 'pattern', 'Logs breakfast consistently but rarely logs dinner', 'inferred')
      on conflict (user_id, kind, content) do nothing;
  end if;
end;
$$;

grant execute on function public.ai_detect_patterns(uuid) to authenticated, service_role;
