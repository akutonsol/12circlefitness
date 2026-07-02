-- ═══════════════════════════════════════════════════════════════════════════
-- Migration 085 — Movement Intelligence Engine (MIE) · Phase 1: Graph Foundation
--
-- The canonical knowledge layer for 12 Circle. NOT exercise-centric: it models
-- MOVEMENT-DOMAIN NODES (exercises, muscles, patterns, equipment, goals, warmups,
-- mobility, recovery, correctives, injuries, skill levels, energy systems,
-- workout types) and TYPED, REVIEWABLE RELATIONSHIPS between them.
--
-- Every downstream system (AI Coach, Workout Builder, Program Generator, Self-
-- Guided, Coach programming) becomes a CONSUMER of this engine rather than
-- re-deriving relationships itself.
--
-- Phase 1 = structure + bootstrap from existing exercise data. No AI logic yet.
-- Idempotent.
-- ═══════════════════════════════════════════════════════════════════════════

-- ── Nodes ───────────────────────────────────────────────────────────────────
-- node_type ∈ exercise | muscle | movement_pattern | equipment | goal | warmup |
--   mobility | recovery | corrective | injury | skill_level | energy_system |
--   workout_type   (free text — extensible by design)
-- Exercises bridge to the existing library via ref_id → exercises.id.
create table if not exists movement_nodes (
  id         uuid primary key default gen_random_uuid(),
  node_type  text not null,
  slug       text not null,
  name       text not null,
  ref_id     uuid,                      -- exercises.id when node_type='exercise'
  metadata   jsonb not null default '{}',
  created_at timestamptz default now(),
  unique (node_type, slug)
);
create index if not exists idx_mnodes_type on movement_nodes(node_type);
create index if not exists idx_mnodes_ref  on movement_nodes(ref_id);

-- ── Edges (relationships are first-class, reviewable assets) ─────────────────
-- relationship ∈ HAS_MOVEMENT_PATTERN | TARGETS | SECONDARY_TARGETS | USES |
--   PROGRESSES_TO | REGRESSES_TO | ALTERNATIVE_OF | HAS_WARMUP | HAS_MOBILITY |
--   HAS_RECOVERY | HAS_CORRECTIVE | CONTRAINDICATED_FOR | DEVELOPS | REQUIRES_SKILL
create table if not exists movement_edges (
  id           uuid primary key default gen_random_uuid(),
  from_node    uuid not null references movement_nodes(id) on delete cascade,
  to_node      uuid not null references movement_nodes(id) on delete cascade,
  relationship text not null,
  confidence   int,                          -- 0..100
  reason       text,
  source       text not null default 'derived',   -- derived | ai_generated | human | import
  status       text not null default 'approved',  -- ai_generated | under_review | approved | rejected
  reviewed_by  uuid references user_profiles(id),
  reviewed_at  timestamptz,
  metadata     jsonb not null default '{}',
  created_at   timestamptz default now(),
  unique (from_node, to_node, relationship)
);
create index if not exists idx_medges_from on movement_edges(from_node, relationship);
create index if not exists idx_medges_to   on movement_edges(to_node, relationship);
create index if not exists idx_medges_status on movement_edges(status);

-- ── RLS: reference data — any authenticated user may READ; writes via RPC ────
alter table movement_nodes enable row level security;
alter table movement_edges enable row level security;
drop policy if exists "mie nodes read" on movement_nodes;
create policy "mie nodes read" on movement_nodes for select to authenticated using (true);
drop policy if exists "mie edges read" on movement_edges;
create policy "mie edges read" on movement_edges for select to authenticated using (true);

-- ── Helpers ─────────────────────────────────────────────────────────────────
create or replace function public.slugify(p text)
returns text language sql immutable as $$
  select trim(both '-' from regexp_replace(lower(coalesce(p,'')), '[^a-z0-9]+', '-', 'g'));
$$;

-- Upsert a node, returning its id.
create or replace function public.mie_upsert_node(
  p_type text, p_name text, p_ref uuid default null)
returns uuid language plpgsql security definer as $$
declare v_slug text := public.slugify(p_name); v_id uuid;
begin
  if v_slug = '' then return null; end if;
  insert into movement_nodes(node_type, slug, name, ref_id)
  values (p_type, v_slug, p_name, p_ref)
  on conflict (node_type, slug)
    do update set name = excluded.name,
                  ref_id = coalesce(excluded.ref_id, movement_nodes.ref_id)
  returning id into v_id;
  return v_id;
end;
$$;

create or replace function public.mie_upsert_edge(
  p_from uuid, p_to uuid, p_rel text, p_conf int, p_reason text, p_source text)
returns void language plpgsql security definer as $$
begin
  if p_from is null or p_to is null or p_from = p_to then return; end if;
  insert into movement_edges(from_node, to_node, relationship, confidence, reason, source, status)
  values (p_from, p_to, p_rel, p_conf, p_reason, p_source, 'approved')
  on conflict (from_node, to_node, relationship) do update
    set confidence = excluded.confidence, reason = excluded.reason;
end;
$$;

-- ── Bootstrap: derive the graph from existing exercise columns ───────────────
-- No AI — pure structured data already on `exercises` (pattern, muscle, equipment,
-- alternatives). Derived edges are source='derived', status='approved'.
create or replace function public.rebuild_movement_graph()
returns jsonb language plpgsql security definer as $$
declare
  r record; v_ex uuid; v_to uuid; m text; v_nodes int; v_edges int;
begin
  if not public.is_content_editor() then raise exception 'forbidden'; end if;

  for r in select id, name, slug, muscle_group, secondary_muscles, movement_pattern,
                  equipment, alternatives
           from exercises loop
    v_ex := public.mie_upsert_node('exercise', r.name, r.id);
    if v_ex is null then continue; end if;

    if coalesce(r.movement_pattern,'') <> '' then
      v_to := public.mie_upsert_node('movement_pattern', r.movement_pattern);
      perform public.mie_upsert_edge(v_ex, v_to, 'HAS_MOVEMENT_PATTERN', 100,
        'derived from exercise.movement_pattern', 'derived');
    end if;

    if coalesce(r.muscle_group,'') <> '' then
      v_to := public.mie_upsert_node('muscle', r.muscle_group);
      perform public.mie_upsert_edge(v_ex, v_to, 'TARGETS', 100,
        'primary muscle group', 'derived');
    end if;

    if coalesce(r.equipment,'') <> '' then
      v_to := public.mie_upsert_node('equipment', r.equipment);
      perform public.mie_upsert_edge(v_ex, v_to, 'USES', 100,
        'required equipment', 'derived');
    end if;

    -- Array fields (secondary muscles, alternatives) — type-agnostic unnest.
    if coalesce(r.secondary_muscles::text,'') not in ('','[]','{}','null') then
      for m in select jsonb_array_elements_text(to_jsonb(r.secondary_muscles)) loop
        v_to := public.mie_upsert_node('muscle', m);
        perform public.mie_upsert_edge(v_ex, v_to, 'SECONDARY_TARGETS', 90,
          'secondary muscle', 'derived');
      end loop;
    end if;

    if coalesce(r.alternatives::text,'') not in ('','[]','{}','null') then
      for m in select jsonb_array_elements_text(to_jsonb(r.alternatives)) loop
        v_to := public.mie_upsert_node('exercise', m);  -- link to (or stub) the alt
        perform public.mie_upsert_edge(v_ex, v_to, 'ALTERNATIVE_OF', 80,
          'listed alternative', 'derived');
      end loop;
    end if;
  end loop;

  select count(*) into v_nodes from movement_nodes;
  select count(*) into v_edges from movement_edges;
  return jsonb_build_object('nodes', v_nodes, 'edges', v_edges);
end;
$$;
grant execute on function public.rebuild_movement_graph() to authenticated;

-- ── Consumer API: everything the graph knows about one exercise ─────────────
create or replace function public.movement_graph(p_exercise_id uuid)
returns jsonb language sql stable security definer as $$
  with n as (
    select id, name from movement_nodes
    where node_type = 'exercise' and ref_id = p_exercise_id limit 1)
  select jsonb_build_object(
    'exercise_id', p_exercise_id,
    'node', (select name from n),
    'relationships', coalesce((
      select jsonb_agg(jsonb_build_object(
        'relationship', e.relationship, 'to', tn.name, 'to_type', tn.node_type,
        'confidence', e.confidence, 'status', e.status, 'reason', e.reason)
        order by e.relationship)
      from movement_edges e
      join movement_nodes tn on tn.id = e.to_node
      where e.from_node = (select id from n)), '[]'::jsonb)
  );
$$;
grant execute on function public.movement_graph(uuid) to authenticated;

-- Graph shape overview for the ops UI.
create or replace function public.movement_graph_stats()
returns jsonb language sql stable security definer as $$
  select jsonb_build_object(
    'nodes', (select count(*) from movement_nodes),
    'edges', (select count(*) from movement_edges),
    'nodes_by_type', coalesce((select jsonb_object_agg(node_type, c)
        from (select node_type, count(*) c from movement_nodes group by node_type) t), '{}'::jsonb),
    'edges_by_type', coalesce((select jsonb_object_agg(relationship, c)
        from (select relationship, count(*) c from movement_edges group by relationship) t), '{}'::jsonb),
    'edges_pending', (select count(*) from movement_edges where status in ('ai_generated','under_review'))
  );
$$;
grant execute on function public.movement_graph_stats() to authenticated;
