-- Migration 065: humanize display values in the seed engine
--
-- Seed data often arrives snake_case/lowercase (upper_body, rear_delts,
-- horizontal_push). Store Title-Case in the display columns (category,
-- muscle_group, equipment, muscles, difficulty, movement_pattern, type) while
-- the normalized child tables keep lowercased tags for querying. Re-running a
-- prior seed batch (idempotent by slug) refreshes its display.

create or replace function public._titleize(s text)
returns text language sql immutable as $$
  select case when s is null or s = '' then null
              else initcap(replace(replace(s, '_', ' '), '-', ' ')) end;
$$;

create or replace function public.seed_exercise(p jsonb, p_coach_id uuid default null)
returns uuid language plpgsql security definer as $$
declare
  o jsonb; n jsonb;
  v_id uuid; v_name text; v_slug text;
  v_primary text[]; v_secondary text[]; v_equipment text[]; v_region text[];
  v_instructions text[]; v_cues text[]; v_mistakes text[]; v_alts text[];
  v_begin text[]; v_adv text[];
begin
  o := p || coalesce(p->'exercise_overview', '{}'::jsonb);
  v_name := o->>'exercise_name';
  if v_name is null then raise exception 'seed_exercise: missing exercise_name'; end if;
  v_slug := coalesce(nullif(o->>'slug',''),
                     lower(trim(both '-' from regexp_replace(trim(v_name), '[^a-zA-Z0-9]+', '-', 'g'))));

  v_primary   := array(select public._titleize(j) from jsonb_array_elements_text(coalesce(o->'primary_muscles','[]')) j);
  v_secondary := array(select public._titleize(j) from jsonb_array_elements_text(coalesce(o->'secondary_muscles','[]')) j);
  v_equipment := array(select public._titleize(j) from jsonb_array_elements_text(coalesce(o->'equipment_required', o->'equipment','[]')) j);
  if jsonb_typeof(o->'body_region') = 'array' then
    v_region := array(select public._titleize(j) from jsonb_array_elements_text(o->'body_region') j);
  elsif o->>'body_region' is not null then v_region := array[public._titleize(o->>'body_region')];
  else v_region := '{}'; end if;

  v_instructions := array(
    select case when jsonb_typeof(x)='object' then coalesce(x->>'instruction', x->>'text') else x #>> '{}' end
    from jsonb_array_elements(coalesce(o->'step_by_step_instructions', o->'instructions','[]')) x);

  if jsonb_typeof(o->'coaching_cues') = 'object' then
    v_cues := array(select e from jsonb_each(o->'coaching_cues') kv, lateral jsonb_array_elements_text(kv.value) e);
  else
    v_cues := array(select jsonb_array_elements_text(coalesce(o->'coaching_cues','[]')));
  end if;

  v_mistakes := array(
    select case when jsonb_typeof(x)='object'
                then x->>'mistake' || coalesce(' → ' || (x->>'fix'), coalesce(' → ' || (x->>'correction'), ''))
                else x #>> '{}' end
    from jsonb_array_elements(coalesce(o->'common_mistakes','[]')) x);

  v_alts := array(
    select case when jsonb_typeof(x)='object' then coalesce(x->>'exercise', x->>'name') else x #>> '{}' end
    from jsonb_array_elements(coalesce(o->'alternative_exercises', o->'alternatives','[]')) x);
  v_begin := array(
    select case when jsonb_typeof(x)='object' then coalesce(x->>'exercise', x->>'name') else x #>> '{}' end
    from jsonb_array_elements(coalesce(o->'beginner_modifications','[]')) x);
  v_adv := array(
    select case when jsonb_typeof(x)='object' then coalesce(x->>'exercise', x->>'name') else x #>> '{}' end
    from jsonb_array_elements(coalesce(o->'advanced_progressions', o->'progressions','[]')) x);

  select id into v_id from custom_exercises
    where slug = v_slug and coach_id is not distinct from p_coach_id limit 1;
  if v_id is null then
    insert into custom_exercises (coach_id, name) values (p_coach_id, v_name) returning id into v_id;
  end if;

  update custom_exercises set
    name = v_name, slug = v_slug,
    description = coalesce(o->>'description', description),
    category = coalesce(public._titleize(nullif(o->>'category','')), (v_region)[1], category),
    difficulty = coalesce(public._titleize(o->>'difficulty'), difficulty),
    movement_pattern = coalesce(public._titleize(o->>'movement_pattern'), movement_pattern),
    exercise_type = coalesce(public._titleize(o->>'exercise_type'), exercise_type),
    muscle_group = coalesce((v_primary)[1], muscle_group),
    equipment = coalesce((v_equipment)[1], equipment, 'Bodyweight'),
    secondary_muscles = v_secondary,
    primary_muscles = v_primary,
    equipment_required = v_equipment,
    body_region = v_region,
    instructions = v_instructions,
    coaching_cues = v_cues,
    common_mistakes = v_mistakes,
    alternatives = v_alts,
    beginner_modification = (v_begin)[1],
    advanced_progression = (v_adv)[1],
    beginner_modifications = v_begin,
    advanced_progressions = v_adv,
    coaching_cues_by_level = case when jsonb_typeof(o->'coaching_cues')='object' then o->'coaching_cues' else '{}'::jsonb end,
    common_mistakes_detailed = case when jsonb_typeof(o->'common_mistakes')='array' then o->'common_mistakes' else '[]'::jsonb end,
    breathing = coalesce(o->'breathing', '{}'::jsonb),
    ai_exercise_tips = coalesce(o->'ai_exercise_tips', '{}'::jsonb),
    goal_tags = array(select jsonb_array_elements_text(coalesce(o->'goal_tags','[]'))),
    contraindications = array(select jsonb_array_elements_text(coalesce(o->'contraindications','[]'))),
    supports_pr_tracking = coalesce((o->>'supports_pr_tracking')::boolean, true),
    supports_rpe_tracking = coalesce((o->>'supports_rpe_tracking')::boolean, (o#>>'{supports_tracking,rpe}')::boolean, true),
    visibility = 'global',
    submission_status = 'approved'
  where id = v_id;

  n := jsonb_build_object(
    'primary_muscles', to_jsonb(v_primary),
    'secondary_muscles', to_jsonb(v_secondary),
    'equipment_required', to_jsonb(v_equipment),
    'body_region', to_jsonb(v_region),
    'substitutions', jsonb_build_object('same_movement', to_jsonb(v_alts)),
    'beginner_modifications', to_jsonb(v_begin),
    'progressions', to_jsonb(v_adv),
    'goal_tags', coalesce(o->'goal_tags','[]'),
    'experience_levels', coalesce(o->'experience_levels','[]'),
    'contraindications', coalesce(o->'contraindications','[]'),
    'warmup_recommendations', coalesce(o->'warmup_recommendations','[]'),
    'mobility_requirements', coalesce(o->'mobility_requirements','[]'),
    'cooldown_recommendations', coalesce(o->'cooldown_recommendations','[]'),
    'injury_modifications', coalesce(o->'injury_modifications','[]'),
    'video_assets', coalesce(o->'video_assets','[]'));
  perform public._sync_exercise_relations(v_id, n);
  return v_id;
end;
$$;
