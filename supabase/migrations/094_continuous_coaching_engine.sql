-- ═══════════════════════════════════════════════════════════════════════════
-- Migration 094 — Continuous Coaching Engine (CCE)
--
-- Closes the loop: PLAN → GENERATE → ASSIGN → OBSERVE → LEARN → ADAPT → CONTINUE.
-- Completed weeks are IMMUTABLE; only future weeks adapt. All decisions are
-- DETERMINISTIC (evaluate_week); regeneration snapshots a version + a decision
-- trace + a diff. The LLM only explains, later.
--
-- Depends on 089 (decision_traces) + 093 (program plan/versions). Idempotent.
-- ═══════════════════════════════════════════════════════════════════════════

-- ── Feedback collection: one structured report per completed week ───────────
create table if not exists weekly_feedback (
  id             uuid primary key default gen_random_uuid(),
  program_id     uuid not null references workout_programs(id) on delete cascade,
  subject_id     uuid references user_profiles(id),
  week           int not null,
  completion_pct int,                    -- 0..100
  recovery       int, sleep int, stress int, energy int,  -- 0..100
  pain           jsonb default '[]',     -- reported pain areas (strings)
  bodyweight     numeric,
  prs            int default 0,
  coach_note     text, client_note text,
  created_at     timestamptz default now(),
  unique (program_id, week)
);
alter table weekly_feedback enable row level security;
drop policy if exists "weekly fb rw" on weekly_feedback;
create policy "weekly fb rw" on weekly_feedback for all to authenticated using (
  subject_id = auth.uid()
  or exists (select 1 from workout_programs p where p.id = program_id and p.coach_id = auth.uid())
) with check (
  subject_id = auth.uid()
  or exists (select 1 from workout_programs p where p.id = program_id and p.coach_id = auth.uid()));

-- ── Coaching Evaluation Engine (deterministic) ─────────────────────────────
create or replace function public.evaluate_week(p_program_id uuid, p_week int)
returns jsonb language plpgsql stable security definer as $$
declare
  fb weekly_feedback%rowtype; v_mode text; v_dur int; v_focus_injury boolean;
  action text := 'CONTINUE'; vol_delta numeric := 0; rules text[] := '{}';
  escalate boolean := false; needs_approval boolean := false; reason text := 'on track';
begin
  select * into fb from weekly_feedback where program_id = p_program_id and week = p_week;
  if not found then return jsonb_build_object('action', 'NO_FEEDBACK'); end if;
  select (plan->>'duration_weeks')::int into v_dur from workout_programs where id = p_program_id;
  select coaching_mode into v_mode from user_profiles where id = fb.subject_id;
  v_focus_injury := coalesce(jsonb_array_length(fb.pain), 0) > 0;

  -- Priority order: injury → fatigue deload → recovery → adherence → overload.
  if v_focus_injury then
    action := 'REPLACE_EXERCISES'; rules := rules || 'INJURY_ADAPTATION';
    reason := 'pain reported — substitute via movement graph';
  elsif fb.recovery is not null and fb.recovery < 55 and coalesce(fb.energy, 100) < 50 then
    action := 'INSERT_DELOAD'; rules := rules || 'FATIGUE_DELOAD'; reason := 'accumulated fatigue';
  elsif fb.recovery is not null and fb.recovery < 60 then
    action := 'REDUCE_VOLUME'; vol_delta := -0.10;
    rules := rules || array['RECOVERY_PROTECTION', 'REPLACE_HIGH_FATIGUE']; reason := 'low recovery';
  elsif fb.completion_pct is not null and fb.completion_pct < 60 then
    action := 'REDUCE_COMPLEXITY'; rules := rules || 'ADHERENCE_SUPPORT';
    escalate := true; reason := 'low adherence';
  elsif fb.recovery is not null and fb.recovery > 85
        and fb.completion_pct is not null and fb.completion_pct > 90 then
    action := 'INCREASE_VOLUME'; vol_delta := 0.05;
    rules := rules || 'PROGRESSIVE_OVERLOAD'; reason := 'recovered + high completion';
  end if;

  -- Coach approval matrix: coach-guided approves any change; injury needs
  -- approval in every mode; otherwise minor changes are automatic.
  needs_approval := (v_mode = 'coach_guided' and action <> 'CONTINUE')
                    or (rules && array['INJURY_ADAPTATION']);

  return jsonb_build_object(
    'week', p_week, 'action', action, 'volume_delta', vol_delta,
    'rules_triggered', to_jsonb(rules), 'escalate', escalate,
    'needs_approval', needs_approval, 'coaching_mode', coalesce(v_mode, 'unknown'),
    'affected_weeks', case when p_week < v_dur
        then jsonb_build_array(p_week + 1, v_dur) else jsonb_build_array() end,
    'reason', reason);
end;
$$;
grant execute on function public.evaluate_week(uuid, int) to authenticated;

-- ── Regeneration: adapt FUTURE weeks only; lock completed; version + trace ──
create or replace function public.regenerate_program(
  p_program_id uuid, p_week int, p_approved boolean default false)
returns jsonb language plpgsql security definer as $$
declare
  eval jsonb; action text; vol_delta numeric; v_plan jsonb; w jsonb;
  new_weeks jsonb := '[]'::jsonb; diff jsonb := '[]'::jsonb;
  wknum int; oldvol numeric; newvol numeric; olddel boolean; newdel boolean;
  v_subject uuid; v_ver int; v_trace uuid;
begin
  eval := public.evaluate_week(p_program_id, p_week);
  action := eval->>'action';
  if action in ('CONTINUE', 'NO_FEEDBACK') then
    return jsonb_build_object('status', 'no_change', 'evaluation', eval);
  end if;
  if (eval->>'needs_approval')::boolean and not p_approved then
    return jsonb_build_object('status', 'pending_approval', 'evaluation', eval);
  end if;

  vol_delta := coalesce((eval->>'volume_delta')::numeric, 0);
  select plan into v_plan from workout_programs where id = p_program_id;
  select subject_id into v_subject from weekly_feedback where program_id = p_program_id and week = p_week;

  for w in select value from jsonb_array_elements(v_plan->'weeks') loop
    wknum := (w->>'week')::int;
    if wknum <= p_week then
      new_weeks := new_weeks || w;                       -- LOCKED
    else
      oldvol := (w->>'volume_multiplier')::numeric;
      olddel := (w->>'is_deload')::boolean;
      newvol := oldvol; newdel := olddel;
      if action in ('INCREASE_VOLUME', 'REDUCE_VOLUME') and not olddel then
        newvol := round(greatest(0.5, least(oldvol * (1 + vol_delta), 1.5)), 2);
      elsif action = 'INSERT_DELOAD' and wknum = p_week + 1 then
        newdel := true; newvol := 0.6;
      elsif action = 'REDUCE_COMPLEXITY' and not olddel then
        newvol := round(greatest(0.5, oldvol * 0.9), 2);  -- fewer/simpler → less volume
      end if;
      new_weeks := new_weeks || (w || jsonb_build_object('volume_multiplier', newvol,
                     'is_deload', newdel, 'regenerated', true));
      if newvol <> oldvol or newdel <> olddel then
        diff := diff || jsonb_build_object('week', wknum,
          'before', jsonb_build_object('volume_multiplier', oldvol, 'is_deload', olddel),
          'after',  jsonb_build_object('volume_multiplier', newvol, 'is_deload', newdel));
      end if;
    end if;
  end loop;

  update workout_programs set plan = jsonb_set(v_plan, '{weeks}', new_weeks) where id = p_program_id;
  v_ver := public.snapshot_program_version(p_program_id, lower(action));

  -- Every regeneration is a decision trace (audit).
  insert into decision_traces(subject_id, created_by, engine_version, rules_version,
      scoring_version, graph_version, context, result, trace, rules_triggered)
  values (v_subject, auth.uid(), '3.0.0', '1.0.0', '1.0.0', '1.0.0',
    jsonb_build_object('type', 'regeneration', 'program_id', p_program_id,
      'from_week', p_week, 'action', action),
    jsonb_build_object('diff', diff, 'version', v_ver),
    jsonb_build_array(jsonb_build_object('decision', action, 'reason', eval->>'reason')),
    array(select jsonb_array_elements_text(eval->'rules_triggered')))
  returning id into v_trace;

  return jsonb_build_object('status', 'applied', 'evaluation', eval,
    'diff', diff, 'version', v_ver, 'trace_id', v_trace);
end;
$$;
grant execute on function public.regenerate_program(uuid, int, boolean) to authenticated;
