-- Migration 048: harden generate_client_plan() for the coach→self/AI transition
--
-- When a previously coach-guided client switches to self/AI, they may still have
-- coach-assigned plans active. generate_client_plan() (047) only cleared the
-- system-generated (coach_id IS NULL) rows, which would leave TWO active plans
-- (coach + new self) and break getMyAssignedProgram()'s maybeSingle(). It also
-- deleted self programs before their assignments, which FK-fails on regeneration.
--
-- This version: deactivates ALL active nutrition/habit plans and supersedes ALL
-- active program assignments for the caller first (it only runs in self/AI
-- context, where the client should have no coach), deletes prior self-generated
-- programs in FK-safe order, then creates the fresh self plan.

create or replace function public.generate_client_plan()
returns void language plpgsql security definer as $$
declare
  p           user_profiles%rowtype;
  v_uid       uuid := auth.uid();
  v_age       int;
  v_mult      numeric;
  v_bmr       numeric;
  v_cal       int;
  v_protein   int;
  v_fat       int;
  v_carbs     int;
  v_water     int;
  v_days      int;
  v_is_home   boolean;
  v_reps      int;
  v_rest      int;
  v_prog      uuid;
  v_old_progs uuid[];
  v_split     text[];
  v_daynames  text[];
  i           int;
begin
  if v_uid is null then return; end if;
  select * into p from user_profiles where id = v_uid;
  if not found then return; end if;

  -- ── Nutrition targets (Mifflin–St Jeor → TDEE → goal adjustment) ──
  v_age := greatest(16, extract(year from age(coalesce(p.date_of_birth, date '1995-01-01')))::int);
  v_mult := case
    when p.activity_level ilike '%sedentary%' then 1.2
    when p.activity_level ilike '%light%'     then 1.375
    when p.activity_level ilike '%moder%'     then 1.55
    when p.activity_level ilike '%very%'      then 1.725
    when p.activity_level ilike '%active%'    then 1.6
    else 1.45 end;
  v_bmr := 10 * coalesce(p.weight_kg, 70) + 6.25 * coalesce(p.height_cm, 170)
           - 5 * v_age + case when p.gender ilike 'f%' then -161 else 5 end;
  v_cal := round(v_bmr * v_mult + case
      when p.fitness_goal = 'lose_fat'    then -500
      when p.fitness_goal = 'build_muscle' then 300
      when p.fitness_goal = 'body_recomp'  then -200
      else 0 end);
  v_cal     := greatest(v_cal, 1200);
  v_protein := round(coalesce(p.weight_kg, 70) * 2.0);
  v_fat     := round(v_cal * 0.25 / 9.0);
  v_carbs   := greatest(0, round((v_cal - v_protein * 4 - v_fat * 9) / 4.0));
  v_water   := round(coalesce(p.weight_kg, 70) * 2.20462 * 0.5);

  -- Supersede ANY active nutrition plan (coach or self) — self/AI has no coach.
  update client_nutrition_plans set is_active=false
    where client_id=v_uid and is_active;
  insert into client_nutrition_plans
    (client_id, coach_id, calories_target, protein_g, carbs_g, fat_g, water_target_oz, notes, is_active)
  values (v_uid, null, v_cal, v_protein, v_carbs, v_fat, v_water,
          'Auto-generated from your onboarding answers.', true);

  -- ── Habits (supersede ANY active set) ──
  update client_habits set is_active=false
    where client_id=v_uid and is_active;
  insert into client_habits (client_id, coach_id, name, emoji, category, target_value, unit, is_active) values
    (v_uid, null, 'Drink Water',    '💧', 'health',      coalesce(v_water, 64), 'oz',    true),
    (v_uid, null, 'Hit Step Goal',  '🚶', 'fitness',     8000,                  'steps', true),
    (v_uid, null, 'Sleep 7+ Hours', '😴', 'recovery',    7,                     'hours', true),
    (v_uid, null, 'Log Your Meals', '🍽️', 'nutrition',   3,                     'meals', true),
    (v_uid, null, 'Daily Mobility', '🧘', 'mindfulness', 10,                    'min',   true);

  -- ── Workout program ──
  -- Supersede coach-assigned active assignments (kept for history).
  update workout_program_assignments set status='superseded'
    where client_id=v_uid and status='active' and coach_id is not null;
  -- Remove prior self-generated programs FK-safely: assignments first, then programs.
  select array_agg(program_id) into v_old_progs
    from workout_program_assignments where client_id=v_uid and coach_id is null;
  delete from workout_program_assignments where client_id=v_uid and coach_id is null;
  if v_old_progs is not null then
    delete from workout_programs where id = any(v_old_progs) and coach_id is null;
  end if;

  v_days    := least(greatest(coalesce(p.training_days_per_week, 3), 2), 6);
  v_is_home := coalesce(p.training_location, '') ilike '%home%';
  v_reps    := case when p.fitness_goal = 'build_muscle' then 10
                    when p.fitness_goal in ('lose_fat','body_recomp') then 13 else 12 end;
  v_rest    := case when p.fitness_goal = 'build_muscle' then 90
                    when p.fitness_goal in ('lose_fat','body_recomp') then 60 else 75 end;

  if v_days <= 3 then
    v_split := array['full_body','full_body','full_body'];
    v_daynames := array['Monday','Wednesday','Friday'];
  elsif v_days = 4 then
    v_split := array['upper','lower','upper','lower'];
    v_daynames := array['Monday','Tuesday','Thursday','Friday'];
  elsif v_days = 5 then
    v_split := array['push','pull','legs','upper','lower'];
    v_daynames := array['Monday','Tuesday','Wednesday','Thursday','Friday'];
  else
    v_split := array['push','pull','legs','push','pull','legs'];
    v_daynames := array['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'];
  end if;

  insert into workout_programs (coach_id, name, description, goal, difficulty, duration_weeks, is_template)
  values (null,
    initcap(replace(coalesce(p.fitness_goal, 'general'), '_', ' ')) || ' Program',
    'Auto-generated ' || v_days || '-day program from your onboarding answers.',
    coalesce(p.fitness_goal, 'general'),
    coalesce(p.experience_level, 'intermediate'),
    12, false)
  returning id into v_prog;

  for i in 1 .. v_days loop
    insert into program_workouts
      (program_id, week_number, day_of_week, title, description, estimated_minutes, exercises, sort_order)
    values (v_prog, 1, v_daynames[i],
      public._plan_day_title(v_split[i]),
      'Generated from your onboarding answers.', 45,
      public._plan_day_exercises(v_split[i], v_is_home, v_reps, v_rest), i);
  end loop;

  insert into workout_program_assignments (program_id, client_id, coach_id, current_week, status)
  values (v_prog, v_uid, null, 1, 'active');
end;
$$;
