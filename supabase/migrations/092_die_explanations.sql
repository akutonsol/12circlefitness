-- ═══════════════════════════════════════════════════════════════════════════
-- Migration 092 — DIE Phase 4b: Explanation cache (L4 Communication)
--
-- The LLM narrates a decision_trace into coach/client language. It may ONLY use
-- the recorded trace (grounded, non-inventing) — see the explain-decision edge
-- function's SYSTEM prompt. Generated explanations are cached on the trace so we
-- don't re-call the model on every view.
--
-- Depends on 089 (decision_traces). Idempotent.
-- ═══════════════════════════════════════════════════════════════════════════

alter table decision_traces add column if not exists explanation_client text;
alter table decision_traces add column if not exists explanation_coach  text;
alter table decision_traces add column if not exists explained_at       timestamptz;
alter table decision_traces add column if not exists explain_model      text;
