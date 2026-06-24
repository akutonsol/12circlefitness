-- Migration 059: sync_exercise_relations(exercise_id, master_json)
--
-- Fans a master-schema exercise JSON out into the normalized child tables
-- (058) in a single transaction. Idempotent: clears the exercise's existing
-- child rows, then re-inserts from the JSON. Empty media URLs are skipped.
-- SECURITY DEFINER but gated on exercise_writable() so a coach can only sync
-- their own (or admins any).

create or replace function public.sync_exercise_relations(p_exercise_id uuid, p jsonb)
returns void language plpgsql security definer as $$
declare
  rec jsonb;
  txt text;
begin
  if not public.exercise_writable(p_exercise_id) then
    raise exception 'not authorized to modify exercise %', p_exercise_id;
  end if;

  -- Clear prior child rows for a clean re-sync.
  delete from exercise_muscles        where exercise_id = p_exercise_id;
  delete from exercise_equipment      where exercise_id = p_exercise_id;
  delete from exercise_tags           where exercise_id = p_exercise_id;
  delete from exercise_media          where exercise_id = p_exercise_id;
  delete from exercise_substitutions  where exercise_id = p_exercise_id;
  delete from exercise_progressions   where exercise_id = p_exercise_id;
  delete from exercise_modifications  where exercise_id = p_exercise_id;

  -- ── Muscles ──
  insert into exercise_muscles (exercise_id, muscle, role)
  select p_exercise_id, lower(v), 'primary'   from jsonb_array_elements_text(coalesce(p->'primary_muscles','[]')) v
  on conflict do nothing;
  insert into exercise_muscles (exercise_id, muscle, role)
  select p_exercise_id, lower(v), 'secondary' from jsonb_array_elements_text(coalesce(p->'secondary_muscles','[]')) v
  on conflict do nothing;

  -- ── Equipment ──
  insert into exercise_equipment (exercise_id, equipment, requirement, category)
  select p_exercise_id, lower(v), 'required', nullif(p->'equipment_category'->>0,'')
    from jsonb_array_elements_text(coalesce(p->'equipment_required', p->'equipment','[]')) v
  on conflict (exercise_id, equipment) do nothing;
  insert into exercise_equipment (exercise_id, equipment, requirement, category)
  select p_exercise_id, lower(v), 'optional', nullif(p->'equipment_category'->>0,'')
    from jsonb_array_elements_text(coalesce(p->'equipment_optional','[]')) v
  on conflict (exercise_id, equipment) do nothing;

  -- ── Tags (polymorphic) ──
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

  -- ── Media (skip empty URLs) ──
  for rec in select * from jsonb_array_elements(coalesce(p->'video_assets','[]')) loop
    if coalesce(rec->>'url','') <> '' then
      insert into exercise_media (exercise_id, media_type, role, url, difficulty)
      values (p_exercise_id, 'video', coalesce(rec->>'type','demo'), rec->>'url', rec->>'difficulty');
    end if;
  end loop;
  for rec in select * from jsonb_array_elements(coalesce(p->'image_assets','[]')) loop
    if coalesce(rec->>'url','') <> '' then
      insert into exercise_media (exercise_id, media_type, role, url)
      values (p_exercise_id, 'image', coalesce(rec->>'type','cover'), rec->>'url');
    end if;
  end loop;
  for rec in select * from jsonb_array_elements(coalesce(p->'form_correction_videos','[]')) loop
    if coalesce(rec->>'url','') <> '' then
      insert into exercise_media (exercise_id, media_type, role, url, issue)
      values (p_exercise_id, 'video', 'form_correction', rec->>'url', rec->>'issue');
    end if;
  end loop;
  insert into exercise_media (exercise_id, media_type, role, url)
  select p_exercise_id, 'voiceover', 'voiceover', v from jsonb_array_elements_text(coalesce(p->'voiceover_assets','[]')) v where v <> '';
  insert into exercise_media (exercise_id, media_type, role, url)
  select p_exercise_id, 'video', 'youtube', v from jsonb_array_elements_text(coalesce(p->'youtube_links','[]')) v where v <> '';
  insert into exercise_media (exercise_id, media_type, role, url)
  select p_exercise_id, 'video', 'vimeo', v from jsonb_array_elements_text(coalesce(p->'vimeo_links','[]')) v where v <> '';

  -- ── Substitutions ──
  if jsonb_typeof(p->'substitutions') = 'object' then
    insert into exercise_substitutions (exercise_id, substitute_name, substitution_type)
    select p_exercise_id, e.val, e.key
      from jsonb_each(p->'substitutions') s(key, arr),
           lateral jsonb_array_elements_text(s.arr) e(val)
    on conflict do nothing;
  end if;
  insert into exercise_substitutions (exercise_id, substitute_name, substitution_type)
  select p_exercise_id, v, 'related' from jsonb_array_elements_text(coalesce(p->'related_exercises','[]')) v
  on conflict do nothing;

  -- ── Progressions / regressions / beginner mods ──
  insert into exercise_progressions (exercise_id, name, progression_type)
  select p_exercise_id, v, 'progression' from jsonb_array_elements_text(coalesce(p->'progressions', p->'advanced_progressions','[]')) v
  on conflict do nothing;
  insert into exercise_progressions (exercise_id, name, progression_type)
  select p_exercise_id, v, 'regression' from jsonb_array_elements_text(coalesce(p->'regressions','[]')) v
  on conflict do nothing;
  insert into exercise_progressions (exercise_id, name, progression_type)
  select p_exercise_id, v, 'beginner_mod' from jsonb_array_elements_text(coalesce(p->'beginner_modifications','[]')) v
  on conflict do nothing;

  -- ── Modifications (injury / contraindication / warmup / cooldown / mobility) ──
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

  -- ── Analytics (upsert; seed at zero) ──
  if jsonb_typeof(p->'analytics') = 'object' then
    insert into exercise_analytics (exercise_id, times_performed, average_weight, average_reps, average_rpe, completion_rate, updated_at)
    values (p_exercise_id,
      coalesce((p->'analytics'->>'times_performed')::int, 0),
      coalesce((p->'analytics'->>'average_weight')::numeric, 0),
      coalesce((p->'analytics'->>'average_reps')::numeric, 0),
      coalesce((p->'analytics'->>'average_rpe')::numeric, 0),
      coalesce((p->'analytics'->>'completion_rate')::numeric, 0),
      now())
    on conflict (exercise_id) do update set updated_at = now();
  else
    insert into exercise_analytics (exercise_id) values (p_exercise_id)
    on conflict (exercise_id) do nothing;
  end if;
end;
$$;

grant execute on function public.sync_exercise_relations(uuid, jsonb) to authenticated;
