-- Migration 063: seed engine for the exercise database
--
-- seed_exercise(json[, coach_id]) ingests one exercise in the coaching/master
-- shape and:
--   • flattens the exercise_overview wrapper,
--   • extracts object-form instructions/cues/mistakes/alternatives/mods,
--   • upserts the core row (idempotent by coach_id+slug) as a published,
--     platform-wide exercise (visibility=global, submission_status=approved),
--   • fans out the normalized child tables via the shared relation sync.
-- Seeding a batch = a list of `select seed_exercise('{...}'::jsonb);` calls.

-- ── Internal relation fan-out (no auth gate; used by seed + the RPC) ──────────
create or replace function public._sync_exercise_relations(p_exercise_id uuid, p jsonb)
returns void language plpgsql security definer as $$
declare rec jsonb;
begin
  delete from exercise_muscles        where exercise_id = p_exercise_id;
  delete from exercise_equipment      where exercise_id = p_exercise_id;
  delete from exercise_tags           where exercise_id = p_exercise_id;
  delete from exercise_media          where exercise_id = p_exercise_id;
  delete from exercise_substitutions  where exercise_id = p_exercise_id;
  delete from exercise_progressions   where exercise_id = p_exercise_id;
  delete from exercise_modifications  where exercise_id = p_exercise_id;

  insert into exercise_muscles (exercise_id, muscle, role)
  select p_exercise_id, lower(v), 'primary'   from jsonb_array_elements_text(coalesce(p->'primary_muscles','[]')) v
  on conflict do nothing;
  insert into exercise_muscles (exercise_id, muscle, role)
  select p_exercise_id, lower(v), 'secondary' from jsonb_array_elements_text(coalesce(p->'secondary_muscles','[]')) v
  on conflict do nothing;

  insert into exercise_equipment (exercise_id, equipment, requirement)
  select p_exercise_id, lower(v), 'required'
    from jsonb_array_elements_text(coalesce(p->'equipment_required', p->'equipment','[]')) v
  on conflict (exercise_id, equipment) do nothing;
  insert into exercise_equipment (exercise_id, equipment, requirement)
  select p_exercise_id, lower(v), 'optional'
    from jsonb_array_elements_text(coalesce(p->'equipment_optional','[]')) v
  on conflict (exercise_id, equipment) do nothing;

  insert into exercise_tags (exercise_id, tag, tag_type)
  select p_exercise_id, lower(v.tag), v.kind from (
    select jsonb_array_elements_text(coalesce(p->'subcategories','[]'))   as tag, 'subcategory'    as kind
    union all select jsonb_array_elements_text(coalesce(p->'goal_tags','[]')),         'goal'
    union all select jsonb_array_elements_text(coalesce(p->'sports_tags', p->'sports_relevance','[]')), 'sport'
    union all select jsonb_array_elements_text(coalesce(p->'experience_levels','[]')), 'experience'
    union all select jsonb_array_elements_text(coalesce(p->'body_region','[]')),       'body_region'
    union all select jsonb_array_elements_text(coalesce(p->'joint_actions','[]')),     'joint_action'
    union all select jsonb_array_elements_text(coalesce(p->'movement_tags','[]')),     'movement'
    union all select jsonb_array_elements_text(coalesce(p->'search_keywords','[]')),   'search_keyword'
  ) v
  on conflict do nothing;

  for rec in select * from jsonb_array_elements(coalesce(p->'video_assets','[]')) loop
    if coalesce(rec->>'url','') <> '' then
      insert into exercise_media (exercise_id, media_type, role, url, difficulty)
      values (p_exercise_id, 'video', coalesce(rec->>'type','demo'), rec->>'url', rec->>'difficulty');
    end if;
  end loop;

  if jsonb_typeof(p->'substitutions') = 'object' then
    insert into exercise_substitutions (exercise_id, substitute_name, substitution_type)
    select p_exercise_id, e.val, s.key
      from jsonb_each(p->'substitutions') s(key, arr),
           lateral jsonb_array_elements_text(s.arr) e(val)
    on conflict do nothing;
  end if;
  insert into exercise_substitutions (exercise_id, substitute_name, substitution_type)
  select p_exercise_id, v, 'related' from jsonb_array_elements_text(coalesce(p->'related_exercises','[]')) v
  on conflict do nothing;

  insert into exercise_progressions (exercise_id, name, progression_type)
  select p_exercise_id, v, 'progression' from jsonb_array_elements_text(coalesce(p->'progressions', p->'advanced_progressions','[]')) v
  on conflict do nothing;
  insert into exercise_progressions (exercise_id, name, progression_type)
  select p_exercise_id, v, 'regression' from jsonb_array_elements_text(coalesce(p->'regressions','[]')) v
  on conflict do nothing;
  insert into exercise_progressions (exercise_id, name, progression_type)
  select p_exercise_id, v, 'beginner_mod' from jsonb_array_elements_text(coalesce(p->'beginner_modifications','[]')) v
  on conflict do nothing;

  for rec in select * from jsonb_array_elements(coalesce(p->'injury_modifications','[]')) loop
    insert into exercise_modifications (exercise_id, modification_type, condition, recommendation)
    values (p_exercise_id, 'injury', rec->>'condition', rec->>'recommendation');
  end loop;
  insert into exercise_modifications (exercise_id, modification_type, condition)
  select p_exercise_id, 'contraindication', v from jsonb_array_elements_text(coalesce(p->'contraindications','[]')) v;
  insert into exercise_modifications (exercise_id, modification_type, recommendation)
  select p_exercise_id, 'warmup', v from jsonb_array_elements_text(coalesce(p->'warmup_recommendations','[]')) v;
  insert into exercise_modifications (exercise_id, modification_type, recommendation)
  select p_exercise_id, 'cooldown', v from jsonb_array_elements_text(coalesce(p->'cooldown_recommendations','[]')) v;
  insert into exercise_modifications (exercise_id, modification_type, recommendation)
  select p_exercise_id, 'mobility', v from jsonb_array_elements_text(coalesce(p->'mobility_requirements','[]')) v;

  insert into exercise_analytics (exercise_id) values (p_exercise_id)
  on conflict (exercise_id) do nothing;
end;
$$;

-- Rewire the auth-gated RPC to call the internal fan-out.
create or replace function public.sync_exercise_relations(p_exercise_id uuid, p jsonb)
returns void language plpgsql security definer as $$
begin
  if not public.exercise_writable(p_exercise_id) then
    raise exception 'not authorized to modify exercise %', p_exercise_id;
  end if;
  perform public._sync_exercise_relations(p_exercise_id, p);
end;
$$;

-- ── Seed one exercise (coaching or master shape) ─────────────────────────────
create or replace function public.seed_exercise(p jsonb, p_coach_id uuid default null)
returns uuid language plpgsql security definer as $$
declare
  o jsonb; n jsonb;
  v_id uuid; v_name text; v_slug text;
  v_primary text[]; v_secondary text[]; v_equipment text[]; v_region text[];
  v_instructions text[]; v_cues text[]; v_mistakes text[]; v_alts text[];
  v_begin text[]; v_adv text[];
begin
  o := p || coalesce(p->'exercise_overview', '{}'::jsonb);  -- flatten wrapper
  v_name := o->>'exercise_name';
  if v_name is null then raise exception 'seed_exercise: missing exercise_name'; end if;
  v_slug := coalesce(nullif(o->>'slug',''),
                     lower(trim(both '-' from regexp_replace(trim(v_name), '[^a-zA-Z0-9]+', '-', 'g'))));

  v_primary   := array(select jsonb_array_elements_text(coalesce(o->'primary_muscles','[]')));
  v_secondary := array(select jsonb_array_elements_text(coalesce(o->'secondary_muscles','[]')));
  v_equipment := array(select jsonb_array_elements_text(coalesce(o->'equipment_required', o->'equipment','[]')));
  if jsonb_typeof(o->'body_region') = 'array' then
    v_region := array(select jsonb_array_elements_text(o->'body_region'));
  elsif o->>'body_region' is not null then v_region := array[o->>'body_region'];
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
    category = coalesce(nullif(o->>'category',''), (v_region)[1], category),
    difficulty = coalesce(o->>'difficulty', difficulty),
    movement_pattern = coalesce(o->>'movement_pattern', movement_pattern),
    exercise_type = coalesce(o->>'exercise_type', exercise_type),
    muscle_group = coalesce((v_primary)[1], muscle_group),
    equipment = coalesce((v_equipment)[1], equipment),
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

  -- Canonical jsonb for the relation fan-out.
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

grant execute on function public.seed_exercise(jsonb, uuid) to authenticated, service_role;
