-- ═══════════════════════════════════════════════════════════════════════════
-- Migration 088 — MIE Phase 3: Programming Rules Engine + Warm-Up Generator
--
-- Where scoring + graph combine into actual program construction. Still fully
-- DETERMINISTIC — the engine builds and validates workouts from rules; an LLM
-- only explains the result later.
--
--   build_workout(context)  → scored, rule-constrained exercise selection + warmup
--   validate_week(days)      → cross-day rule violations (fatigue/spinal/alternation)
--   generate_warmup(ids)     → graph-driven mobility/activation from the day's patterns
--   seed_warmup_library()    → curated mobility/warmup nodes+edges per movement pattern
--
-- Depends on 085 (graph) + 087 (intelligence + score_exercise). Idempotent.
-- ═══════════════════════════════════════════════════════════════════════════

-- ── Warm-up library seed: mobility + activation drills per movement pattern ──
-- Curated canonical knowledge (small), linked into the graph so generate_warmup
-- is graph-driven. HAS_MOBILITY / HAS_WARMUP edges from pattern → drill node.
create or replace function public.seed_warmup_library()
returns jsonb language plpgsql security definer as $$
declare rec record; v_pat uuid; v_node uuid; v_edges int := 0; m text;
begin
  if not public.is_content_editor() then raise exception 'forbidden'; end if;
  for rec in select * from (values
    ('hip-hinge',       array['90/90 Hip Stretch','World''s Greatest Stretch'], array['Band Hamstring Sweep','Bodyweight Good Morning']),
    ('squat',           array['Deep Squat Hold','Ankle Rock'],                  array['Bodyweight Squat','Goblet Squat Hold']),
    ('horizontal-push', array['Thoracic Rotation','Wall Slides'],               array['Band Pull-Apart','Scap Push-Up']),
    ('horizontal-pull', array['Thread the Needle','Wall Slides'],               array['Band Pull-Apart','Scap Retraction']),
    ('vertical-push',   array['Wall Slides','Thoracic Extension'],              array['Band Dislocate','Scap Push-Up']),
    ('vertical-pull',   array['Lat Stretch','Thoracic Extension'],              array['Band Lat Activation','Dead Hang']),
    ('lunge',           array['Couch Stretch','Hip Flexor Stretch'],           array['Bodyweight Lunge','Cossack Squat']),
    ('carry',           array['Wrist Circles','Thoracic Extension'],           array['Farmer Hold','Dead Hang']),
    ('rotation',        array['Open Book','Thread the Needle'],                 array['Band Chop','Cable Rotation'])
  ) as t(pat, mob, warm) loop
    select id into v_pat from movement_nodes where node_type = 'movement_pattern' and slug = rec.pat;
    if v_pat is null then continue; end if;
    foreach m in array rec.mob loop
      v_node := public.mie_upsert_node('mobility', m);
      perform public.mie_upsert_edge(v_pat, v_node, 'HAS_MOBILITY', 90, 'warm-up library', 'human');
      v_edges := v_edges + 1;
    end loop;
    foreach m in array rec.warm loop
      v_node := public.mie_upsert_node('warmup', m);
      perform public.mie_upsert_edge(v_pat, v_node, 'HAS_WARMUP', 90, 'warm-up library', 'human');
      v_edges := v_edges + 1;
    end loop;
  end loop;
  return jsonb_build_object('warmup_edges', v_edges);
end;
$$;
grant execute on function public.seed_warmup_library() to authenticated;

-- ── Warm-Up Generator: workout exercises → patterns → mobility/activation ────
create or replace function public.generate_warmup(p_exercise_ids uuid[])
returns jsonb language sql stable security definer as $$
  with pats as (
    select distinct pn.id as pattern_id
    from unnest(p_exercise_ids) xid
    join movement_nodes en on en.node_type = 'exercise' and en.ref_id = xid
    join movement_edges e  on e.from_node = en.id and e.relationship = 'HAS_MOVEMENT_PATTERN'
    join movement_nodes pn on pn.id = e.to_node)
  select coalesce(jsonb_agg(distinct jsonb_build_object(
           'type', case when e2.relationship = 'HAS_MOBILITY' then 'mobility' else 'activation' end,
           'name', dn.name)), '[]'::jsonb)
  from pats
  join movement_edges e2 on e2.from_node = pats.pattern_id
     and e2.relationship in ('HAS_MOBILITY', 'HAS_WARMUP')
  join movement_nodes dn on dn.id = e2.to_node;
$$;
grant execute on function public.generate_warmup(uuid[]) to authenticated;

-- ── Programming Rules Engine: build one rule-constrained workout ─────────────
-- Rules applied (deterministic):
--   • recovery < 60 → total volume −20%
--   • ≤ 2 systemic-fatigue (≥7) exercises per workout
--   • one exercise per movement pattern (variety)
--   • exclude unavailable-equipment / injury-incompatible candidates
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
  sel        jsonb := '[]'::jsonb;
  rec        record;
begin
  for rec in
    with scored as (
      select e.id, e.name, e.movement_pattern,
             coalesce(ei.systemic_fatigue, 0) as sysfat,
             public.score_exercise(e.id, p_context) as bd
      from exercises e
      join exercise_intelligence ei on ei.exercise_id = e.id)
    select id, name, movement_pattern, sysfat, bd,
           (bd->>'final_score')::int as fs
    from scored
    order by (bd->>'final_score')::int desc nulls last
  loop
    exit when v_count >= v_target;
    if (rec.bd->>'equipment_match')::int = 0 then continue; end if;
    if (rec.bd->>'injury_compatibility')::int < 40 then continue; end if;
    if rec.sysfat >= 7 and v_systemic >= 2 then continue; end if;
    if rec.movement_pattern is not null and rec.movement_pattern = any(v_patterns) then continue; end if;

    sel := sel || jsonb_build_object('id', rec.id, 'name', rec.name,
                    'pattern', rec.movement_pattern, 'score', rec.fs,
                    'systemic_fatigue', rec.sysfat);
    if rec.sysfat >= 7 then v_systemic := v_systemic + 1; end if;
    if rec.movement_pattern is not null then v_patterns := v_patterns || rec.movement_pattern; end if;
    v_ids := v_ids || rec.id;
    v_count := v_count + 1;
  end loop;

  return jsonb_build_object(
    'volume_factor', v_vol,
    'target_size', v_target,
    'selected', sel,
    'systemic_fatigue_count', v_systemic,
    'warmup', public.generate_warmup(v_ids),
    'rules_applied', jsonb_build_array(
      case when v_recovery < 60 then 'recovery<60 → volume −20%' else 'full volume' end,
      '≤2 systemic-fatigue exercises',
      'one exercise per movement pattern',
      'exclude unavailable-equipment / injury-incompatible'));
end;
$$;
grant execute on function public.build_workout(jsonb) to authenticated;

-- ── Weekly Rules validator: cross-day constraints ───────────────────────────
-- p_days = jsonb array of days, each an array of exercise ids: [[uuid,…],[uuid,…]]
-- Rules: no back-to-back high-fatigue hinge days; ≤3 spinal-loading days/week.
create or replace function public.validate_week(p_days jsonb)
returns jsonb language plpgsql stable security definer as $$
declare
  n int := coalesce(jsonb_array_length(p_days), 0);
  i int; day jsonb; xid uuid;
  hinge boolean[]; fatigue boolean[];
  v_hinge boolean; v_fat int; v_spinal boolean;
  spinal_days int := 0; viol jsonb := '[]'::jsonb;
begin
  if n = 0 then return jsonb_build_object('days', 0, 'violations', '[]'::jsonb, 'ok', true); end if;
  hinge := array_fill(false, array[n]);
  fatigue := array_fill(false, array[n]);
  for i in 0 .. n - 1 loop
    day := p_days->i; v_hinge := false; v_fat := 0; v_spinal := false;
    for xid in select (jsonb_array_elements_text(day))::uuid loop
      if exists (select 1 from exercises e where e.id = xid
                   and lower(coalesce(e.movement_pattern,'')) like '%hinge%') then v_hinge := true; end if;
      v_fat := v_fat + coalesce((select systemic_fatigue from exercise_intelligence where exercise_id = xid), 0);
      if exists (select 1 from exercise_intelligence ei where ei.exercise_id = xid
                   and coalesce((ei.joint_stress->>'lower_back')::int, 0) >= 6)
         or exists (select 1 from exercises e where e.id = xid
                   and (lower(coalesce(e.movement_pattern,'')) like '%hinge%'
                     or lower(coalesce(e.movement_pattern,'')) like '%squat%'))
      then v_spinal := true; end if;
    end loop;
    hinge[i + 1] := v_hinge;
    fatigue[i + 1] := (v_fat >= 14);
    if v_spinal then spinal_days := spinal_days + 1; end if;
  end loop;

  for i in 1 .. n - 1 loop
    if hinge[i] and hinge[i + 1] and fatigue[i] and fatigue[i + 1] then
      viol := viol || jsonb_build_object('rule', 'no back-to-back high-fatigue hinge days',
                        'days', jsonb_build_array(i - 1, i));
    end if;
  end loop;
  if spinal_days > 3 then
    viol := viol || jsonb_build_object('rule', 'max 3 spinal-loading days/week', 'value', spinal_days);
  end if;

  return jsonb_build_object('days', n, 'spinal_days', spinal_days,
    'violations', viol, 'ok', jsonb_array_length(viol) = 0);
end;
$$;
grant execute on function public.validate_week(jsonb) to authenticated;
