-- ═══════════════════════════════════════════════════════════════════════════
-- Migration 093 — Program Intelligence Engine (Dynamic Program Builder)
--
-- Extends the MIE from one-day decisions to multi-week programs. DETERMINISTIC —
-- plan_program() reasons about the whole cycle (mesocycles, per-week volume/
-- intensity/deload) up front; each week's workouts are MATERIALIZED just-in-time
-- by reusing the existing build_workout() engine (no duplicated workout logic).
-- The LLM never builds programs; it only explains strategy later.
--
-- Depends on 088 (build_workout) + 089 (decision traces). Idempotent.
-- ═══════════════════════════════════════════════════════════════════════════

-- Program metadata on the existing workout_programs table (no new subsystem).
alter table workout_programs add column if not exists strategy         jsonb;
alter table workout_programs add column if not exists plan             jsonb;   -- plan_program() output
alter table workout_programs add column if not exists program_version  int default 1;
alter table workout_programs add column if not exists engine_generated boolean default false;

-- Version history — every regeneration/edit snapshots the plan (roll back).
create table if not exists program_versions (
  id          uuid primary key default gen_random_uuid(),
  program_id  uuid not null references workout_programs(id) on delete cascade,
  version     int not null,
  strategy    jsonb,
  plan        jsonb,
  reason      text,                 -- 'initial' | 'recovery_adjustment' | 'injury_mod' | 'coach_edit'
  created_by  uuid references user_profiles(id),
  created_at  timestamptz default now()
);
create index if not exists idx_progver on program_versions(program_id, version desc);
alter table program_versions enable row level security;
drop policy if exists "prog versions read" on program_versions;
create policy "prog versions read" on program_versions for select to authenticated using (
  exists (select 1 from workout_programs p where p.id = program_id
          and (p.coach_id = auth.uid()
               or exists (select 1 from user_profiles where id = auth.uid() and role in ('admin','content_manager')))));

-- ── The planner: strategy → mesocycles + per-week targets (DETERMINISTIC) ───
-- strategy keys: program_type, duration_weeks, frequency, primary_focus,
--   secondary_focus, progression_model (linear|undulating|block|hybrid),
--   deload_strategy (every_4th|final_only|coach).
create or replace function public.plan_program(p_strategy jsonb)
returns jsonb language plpgsql immutable as $$
declare
  d       int := greatest(1, least(coalesce((p_strategy->>'duration_weeks')::int, 12), 24));
  freq    int := greatest(1, least(coalesce((p_strategy->>'frequency')::int, 4), 6));
  prog    text := lower(coalesce(p_strategy->>'progression_model', 'linear'));
  deload  text := lower(coalesce(p_strategy->>'deload_strategy', 'every_4th'));
  focus   text := coalesce(p_strategy->>'primary_focus', 'Full Body');
  f_end   int := greatest(1, round(d * 0.33));
  o_end   int := greatest(f_end + 1, round(d * 0.66));
  wk int; phase text; is_deload boolean; volm numeric; intens int;
  split text[]; weeks jsonb := '[]'::jsonb; mesos jsonb;
begin
  -- Split by weekly frequency.
  split := case freq
    when 2 then array['Full Body','Full Body']
    when 3 then array['Push','Pull','Legs']
    when 4 then array['Upper','Lower','Upper','Lower']
    when 5 then array['Push','Pull','Legs','Upper','Lower']
    when 6 then array['Push','Pull','Legs','Push','Pull','Legs']
    else array['Full Body'] end;

  for wk in 1 .. d loop
    -- Phase by position in the cycle.
    phase := case
      when wk = d then 'Deload & Assessment'
      when wk <= f_end then 'Foundation'
      when wk <= o_end then 'Progressive Overload'
      else 'Intensification' end;
    -- Deload weeks.
    is_deload := (wk = d) or (deload = 'every_4th' and wk % 4 = 0 and wk <> d);

    -- Volume multiplier by progression model.
    if is_deload then
      volm := 0.6;
    else
      volm := case prog
        when 'linear'     then least(1.0 + 0.03 * (wk - 1), 1.35)
        when 'undulating' then case when wk % 2 = 1 then 1.10 else 0.90 end
        when 'block'      then case phase when 'Foundation' then 0.90
                                          when 'Progressive Overload' then 1.05
                                          else 1.15 end
        else least(1.0 + 0.025 * (wk - 1), 1.30) end;  -- hybrid/default
    end if;

    -- Intensity ramps across the cycle (RPE-like 5..9); deloads back off.
    intens := case when is_deload then 5
                   else least(6 + floor((wk - 1)::numeric / greatest(1, d - 1) * 3)::int, 9) end;

    weeks := weeks || jsonb_build_object(
      'week', wk, 'phase', phase, 'is_deload', is_deload,
      'volume_multiplier', round(volm, 2), 'intensity', intens,
      'sessions', freq, 'split', to_jsonb(split), 'emphasis', focus);
  end loop;

  mesos := jsonb_build_array(
    jsonb_build_object('name','Foundation','weeks', jsonb_build_array(1, f_end),
      'volume_target','moderate','intensity_target','low-moderate','emphasis',focus),
    jsonb_build_object('name','Progressive Overload','weeks', jsonb_build_array(f_end+1, o_end),
      'volume_target','high','intensity_target','moderate','emphasis',focus),
    jsonb_build_object('name','Intensification','weeks', jsonb_build_array(o_end+1, greatest(o_end+1, d-1)),
      'volume_target','moderate','intensity_target','high','emphasis',focus),
    jsonb_build_object('name','Deload & Assessment','weeks', jsonb_build_array(d, d),
      'volume_target','low','intensity_target','low','emphasis','recovery'));

  return jsonb_build_object(
    'strategy', p_strategy, 'duration_weeks', d, 'frequency', freq,
    'progression_model', prog, 'mesocycles', mesos, 'weeks', weeks);
end;
$$;
grant execute on function public.plan_program(jsonb) to authenticated;

-- Snapshot a program's current strategy+plan as the next version.
create or replace function public.snapshot_program_version(p_program_id uuid, p_reason text)
returns int language plpgsql security definer as $$
declare v_next int; v_strat jsonb; v_plan jsonb;
begin
  select strategy, plan into v_strat, v_plan from workout_programs where id = p_program_id;
  select coalesce(max(version),0)+1 into v_next from program_versions where program_id = p_program_id;
  insert into program_versions(program_id, version, strategy, plan, reason, created_by)
  values (p_program_id, v_next, v_strat, v_plan, p_reason, auth.uid());
  update workout_programs set program_version = v_next where id = p_program_id;
  return v_next;
end;
$$;
grant execute on function public.snapshot_program_version(uuid, text) to authenticated;

-- ── Materialize ONE week's workouts by reusing build_workout (no duplication) ──
-- Adjusts the base context by the week's volume multiplier, generates each
-- session through the engine, and writes program_workouts rows. Records a
-- decision trace per session via generate_workout.
create or replace function public.materialize_program_week(
  p_program_id uuid, p_week int, p_context jsonb)
returns jsonb language plpgsql security definer as $$
declare
  v_plan jsonb; v_week jsonb; v_split jsonb; v_vol numeric; v_base int;
  i int; v_ctx jsonb; v_result jsonb; v_made int := 0; v_sessions jsonb := '[]'::jsonb;
begin
  select plan into v_plan from workout_programs where id = p_program_id;
  if v_plan is null then raise exception 'program has no plan'; end if;
  select w into v_week from jsonb_array_elements(v_plan->'weeks') w
    where (w->>'week')::int = p_week;
  if v_week is null then raise exception 'week % not in plan', p_week; end if;

  v_split := v_week->'split';
  v_vol := coalesce((v_week->>'volume_multiplier')::numeric, 1.0);
  v_base := coalesce((p_context->>'size')::int, 5);

  -- Clear any prior materialization of this week.
  delete from program_workouts where program_id = p_program_id and week_number = p_week;

  for i in 0 .. jsonb_array_length(v_split) - 1 loop
    -- Per-session context: scale target size by the week's volume multiplier.
    v_ctx := p_context || jsonb_build_object(
      'size', greatest(2, round(v_base * v_vol)),
      'recovery', coalesce((p_context->>'recovery')::int, 75));
    v_result := public.generate_workout(v_ctx, (p_context->>'subject')::uuid);

    insert into program_workouts(program_id, week_number, day_of_week, title, exercises, sort_order)
    values (p_program_id, p_week,
      lower(to_char(now(),'day')),  -- placeholder day; coach can reorder
      format('Week %s · %s', p_week, v_split->>i),
      coalesce(v_result->'selected', '[]'::jsonb), i);
    v_made := v_made + 1;
    v_sessions := v_sessions || jsonb_build_object('session', v_split->>i, 'trace_id', v_result->'trace_id');
  end loop;

  return jsonb_build_object('week', p_week, 'sessions_created', v_made, 'sessions', v_sessions);
end;
$$;
grant execute on function public.materialize_program_week(uuid, int, jsonb) to authenticated;
