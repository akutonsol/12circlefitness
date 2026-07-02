-- ═══════════════════════════════════════════════════════════════════════════
-- Migration 089 — MIE Phase 4: Decision Intelligence Engine (DIE)
--
-- Records WHY every workout decision happened. The trace is STRUCTURED DATA —
-- coach view, client view, and the MIE debugger all read it directly, with NO
-- AI. A future LLM may only narrate the trace (it cannot invent reasoning).
--
--   build_workout(context)  → now emits a `trace` (per-candidate accept/reject +
--                             reason + rule) and `rules_triggered`
--   generate_workout(ctx)    → runs build_workout, PERSISTS a decision_traces row
--                             (with engine versions), returns plan + trace_id
--   decision_analytics()     → most-triggered rule, most-rejected exercise, etc.
--
-- Depends on 085 + 087 + 088. Idempotent.
-- ═══════════════════════════════════════════════════════════════════════════

create table if not exists decision_traces (
  id              uuid primary key default gen_random_uuid(),
  subject_id      uuid references user_profiles(id),  -- who the workout is for
  created_by      uuid references user_profiles(id),
  engine_version  text, rules_version text, scoring_version text, graph_version text,
  context         jsonb not null,
  result          jsonb not null,          -- selected + warmup + volume_factor
  trace           jsonb not null,          -- ordered decision events
  rules_triggered text[] default '{}',
  created_at      timestamptz default now()
);
create index if not exists idx_dtrace_subject on decision_traces(subject_id, created_at desc);

alter table decision_traces enable row level security;
drop policy if exists "dtrace read own/staff" on decision_traces;
create policy "dtrace read own/staff" on decision_traces for select to authenticated using (
  subject_id = auth.uid() or created_by = auth.uid()
  or exists (select 1 from user_profiles where id = auth.uid() and role in ('admin','content_manager','coach')));

-- ── build_workout — now trace-emitting (still deterministic, still stable) ──
create or replace function public.build_workout(p_context jsonb)
returns jsonb language plpgsql stable security definer as $$
declare
  v_size     int := coalesce((p_context->>'size')::int, 5);
  v_recovery int := coalesce((p_context->>'recovery')::int, 100);
  v_vol      numeric := case when v_recovery < 60 then 0.8 else 1.0 end;
  v_target   int := greatest(1, round(v_size * v_vol));
  v_systemic int := 0;
  v_patterns text[] := '{}';
  v_ids      uuid[] := '{}';
  v_count    int := 0;
  v_traced   int := 0;
  sel        jsonb := '[]'::jsonb;
  trace      jsonb := '[]'::jsonb;
  rules      text[] := '{}';
  rec        record;
  decision text; reason text; rule text; em int; ic int;
begin
  if v_recovery < 60 then rules := rules || 'RECOVERY_REDUCTION'; end if;
  for rec in
    with scored as (
      select e.id, e.name, e.movement_pattern,
             coalesce(ei.systemic_fatigue, 0) as sysfat,
             public.score_exercise(e.id, p_context) as bd
      from exercises e join exercise_intelligence ei on ei.exercise_id = e.id)
    select id, name, movement_pattern, sysfat, bd, (bd->>'final_score')::int as fs
    from scored order by (bd->>'final_score')::int desc nulls last
  loop
    exit when v_count >= v_target;
    em := (rec.bd->>'equipment_match')::int;
    ic := (rec.bd->>'injury_compatibility')::int;
    rule := null; reason := null; decision := 'accepted';
    if em = 0 then
      decision := 'rejected'; rule := 'EQUIPMENT_CONSTRAINT'; reason := 'required equipment unavailable';
    elsif ic < 40 then
      decision := 'rejected'; rule := 'INJURY_PREVENTION'; reason := 'injury incompatibility (score ' || ic || ')';
    elsif rec.sysfat >= 7 and v_systemic >= 2 then
      decision := 'rejected'; rule := 'MAX_SYSTEMIC_FATIGUE'; reason := 'systemic-fatigue cap (2) reached';
    elsif rec.movement_pattern is not null and rec.movement_pattern = any(v_patterns) then
      decision := 'rejected'; rule := 'MOVEMENT_VARIETY'; reason := rec.movement_pattern || ' already selected';
    else
      reason := 'top-ranked available candidate';
    end if;

    if v_traced < 25 then
      trace := trace || jsonb_build_object(
        'name', rec.name, 'score', rec.fs, 'pattern', rec.movement_pattern,
        'systemic_fatigue', rec.sysfat, 'decision', decision, 'reason', reason,
        'rule', rule, 'breakdown', rec.bd);
      v_traced := v_traced + 1;
    end if;

    if decision = 'accepted' then
      sel := sel || jsonb_build_object('id', rec.id, 'name', rec.name,
               'pattern', rec.movement_pattern, 'score', rec.fs, 'systemic_fatigue', rec.sysfat);
      if rec.sysfat >= 7 then v_systemic := v_systemic + 1; end if;
      if rec.movement_pattern is not null then v_patterns := v_patterns || rec.movement_pattern; end if;
      v_ids := v_ids || rec.id;
      v_count := v_count + 1;
    elsif rule is not null and not (rule = any(rules)) then
      rules := rules || rule;
    end if;
  end loop;

  return jsonb_build_object(
    'volume_factor', v_vol, 'target_size', v_target, 'selected', sel,
    'systemic_fatigue_count', v_systemic, 'warmup', public.generate_warmup(v_ids),
    'trace', trace, 'rules_triggered', to_jsonb(rules),
    'rules_applied', jsonb_build_array(
      case when v_recovery < 60 then 'recovery<60 → volume −20%' else 'full volume' end,
      '≤2 systemic-fatigue exercises', 'one exercise per movement pattern',
      'exclude unavailable-equipment / injury-incompatible'));
end;
$$;
grant execute on function public.build_workout(jsonb) to authenticated;

-- ── generate_workout — build + PERSIST the decision trace (versioned) ───────
create or replace function public.generate_workout(p_context jsonb, p_subject uuid default null)
returns jsonb language plpgsql security definer as $$
declare plan jsonb; v_id uuid;
begin
  plan := public.build_workout(p_context);
  insert into decision_traces(
    subject_id, created_by, engine_version, rules_version, scoring_version, graph_version,
    context, result, trace, rules_triggered)
  values (
    coalesce(p_subject, auth.uid()), auth.uid(),
    '3.0.0', '1.0.0', '1.0.0', '1.0.0',
    p_context,
    plan - 'trace' - 'rules_triggered',
    coalesce(plan->'trace', '[]'::jsonb),
    array(select jsonb_array_elements_text(coalesce(plan->'rules_triggered', '[]'::jsonb))))
  returning id into v_id;
  return plan || jsonb_build_object('trace_id', v_id);
end;
$$;
grant execute on function public.generate_workout(jsonb, uuid) to authenticated;

-- ── Decision analytics over recorded traces ─────────────────────────────────
create or replace function public.decision_analytics()
returns jsonb language sql stable security definer as $$
  select jsonb_build_object(
    'total_generations', (select count(*) from decision_traces),
    'avg_recovery', (select round(avg((context->>'recovery')::numeric), 1)
                       from decision_traces where context ? 'recovery'),
    'most_triggered_rule', (select rule from (
        select unnest(rules_triggered) rule, count(*) c
        from decision_traces group by 1 order by c desc limit 1) x),
    'most_rejected_exercise', (select nm from (
        select ev->>'name' nm, count(*) c
        from decision_traces, jsonb_array_elements(trace) ev
        where ev->>'decision' = 'rejected' group by 1 order by c desc limit 1) y),
    'engine_version', '3.0.0');
$$;
grant execute on function public.decision_analytics() to authenticated;
