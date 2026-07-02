# Movement Intelligence Engine (MIE)

The MIE is 12 Circle's deterministic coaching engine. It is the **source of truth**
for every workout recommendation, substitution, progression, and warm-up. AI is a
**communication layer only** — it explains the engine's decisions, it never makes them.

> **Design invariant:** the engine decides; the LLM explains. Any recommendation a
> user or coach sees must originate from a deterministic function here and be
> reproducible from a recorded decision trace.

---

## Five-layer architecture

| Layer | Responsibility | Built on |
|-------|----------------|----------|
| **L1 Content** | Exercise library, editorial pipeline, certification | migrations 083/084/086 |
| **L2 Knowledge** | Movement graph, programming intelligence, per-attribute review | 085/087/090/091 |
| **L3 Decision** | Scoring, rules, workout assembly, warm-up, decision trace | 087/088/089 |
| **L4 Communication** | Grounded LLM narration (coach + client) | 092 + `explain-decision` |
| **L5 Experience** | Flutter UI (Coach Copilot, MIE Debugger, review queues) | app |

Each layer consumes only the layer beneath it. Layers can evolve independently as
long as the public function contracts below are preserved.

---

## Graph model (L2)

- **`movement_nodes`** — any movement-domain entity: `exercise` (bridged to
  `exercises.id` via `ref_id`), `muscle`, `movement_pattern`, `equipment`, `goal`,
  `warmup`, `mobility`, `recovery`, `corrective`, `injury`, `skill_level`,
  `energy_system`, `workout_type`. Unique on `(node_type, slug)`; `slugify()`
  normalizes names so `hip hinge`/`hip_hinge` collapse to one node.
- **`movement_edges`** — typed, **reviewable** relationships:
  `HAS_MOVEMENT_PATTERN`, `TARGETS`, `SECONDARY_TARGETS`, `USES`, `PROGRESSES_TO`,
  `REGRESSES_TO`, `ALTERNATIVE_OF`, `HAS_WARMUP`, `HAS_MOBILITY`, `HAS_RECOVERY`,
  `HAS_CORRECTIVE`, `CONTRAINDICATED_FOR`, `DEVELOPS`, `REQUIRES_SKILL`. Every edge
  carries `confidence`, `reason`, `source` (`derived`/`ai_generated`/`human`), and
  `status`.
- **Bootstrap:** `rebuild_movement_graph()` derives nodes + edges from existing
  exercise columns (pattern/muscle/secondary/equipment/alternatives). No AI.

## Programming intelligence (L2)

**`exercise_intelligence`** (1:1 with exercises). Scoring-critical fields are typed
(`goal_*`, `systemic_fatigue`, `joint_stress`, `min_experience`, `contraindications`);
the richer profile (biomechanics, per-region loading, coaching metadata, extended
goals) lives in `profile` jsonb. **`attribute_confidence`** jsonb holds per-attribute
confidence so review is targeted.

**Knowledge review pipeline (per attribute):** AI drafts → `attribute_review_state()`
surfaces confidence + status → `review_attribute()` approves/rejects/flags each
attribute (high-confidence auto-pass) → `finalize_intelligence()` sets the profile
`approved` only when every attribute is resolved.

## Certification (L1→L2 bridge)

`exercise_certifications` view computes, per exercise, which modules may consume it
(`workout_builder`, `program_generator`, `ai_coach`, `self_guided`, `coach_guided`,
`marketplace`, `premium_content`, …) from content + media + review + publish state,
with **current** vs **projected** (post-approval) certification. Every module should
gate on this view, not on individual fields.

---

## Decision layer (L3) — public API

```
score_exercise(exercise_id uuid, context jsonb) → jsonb
```
Deterministic suitability breakdown for one exercise. `context`:
`{goal, equipment[], recovery(0..100), experience, injuries[], recent_patterns[]}`.
Returns `{goal_match, equipment_match, recovery_match, experience_match,
injury_compatibility, movement_balance, final_score}`. Weights: **30/20/15/15/15/5**.

```
rank_exercises(context jsonb, limit int) → rows(exercise_id, name, final_score, breakdown)
build_workout(context jsonb) → jsonb   -- selected + warmup + trace + rules_triggered
generate_workout(context jsonb, subject uuid) → jsonb   -- build + PERSIST a decision trace
validate_week(days jsonb) → jsonb       -- cross-day rule violations
generate_warmup(exercise_ids uuid[]) → jsonb   -- graph-driven mobility/activation
```

**Rules (deterministic, in `build_workout`):** recovery < 60 → volume ×0.8; ≤ 2
systemic-fatigue exercises; one exercise per movement pattern; exclude
equipment-unavailable / injury-incompatible. **Weekly:** no back-to-back
high-fatigue hinge days; ≤ 3 spinal-loading days/week.

### Decision trace format (L3, the contract L4 depends on)

`decision_traces` rows are stamped with `engine_version` / `rules_version` /
`scoring_version` / `graph_version` (compare workouts across engine versions).

```jsonc
{
  "context":  { "goal": "hypertrophy", "recovery": 58, ... },
  "result":   { "volume_factor": 0.8, "selected": [ ... ], "warmup": [ ... ] },
  "trace": [
    { "name": "Deadlift",  "score": 91, "decision": "accepted", "rule": null,
      "reason": "top-ranked available candidate" },
    { "name": "RDL",       "score": 88, "decision": "rejected",
      "rule": "MOVEMENT_VARIETY", "reason": "hinge already selected" }
  ],
  "rules_triggered": ["RECOVERY_REDUCTION", "MOVEMENT_VARIETY", "MAX_SYSTEMIC_FATIGUE"]
}
```

`decision_analytics()` aggregates traces (most-triggered rule, most-rejected
exercise, average recovery).

---

## Communication layer (L4)

`explain-decision` (edge function) narrates a `decision_traces` row for
`audience: client | coach`. It is **hard-constrained** to the trace: it may not
introduce exercises/reasons/numbers not present, must say "not recorded" for
anything absent, and must not contradict the trace. Explanations are cached on the
trace (`explanation_client` / `explanation_coach`).

Because the trace is complete structured ground truth, the model cannot hallucinate
a recommendation — it can only phrase decisions the engine already logged.

---

## Extension points

- **New node/edge type** — add to `movement_nodes.node_type` / `movement_edges.relationship`
  (free text, no migration needed) and populate via `mie_upsert_node/edge` or an
  enrichment function.
- **New programming rule** — add a deterministic branch in `build_workout` (emit a
  trace entry + append to `rules_triggered`) or a check in `validate_week`.
- **New scoring factor** — add a sub-score in `score_exercise` and fold it into the
  weighted `final_score` (bump `scoring_version`).
- **New consumer** — query `exercise_certifications` to gate usage and call
  `rank_exercises` / `generate_workout`; never re-derive relationships or scores.
- **New audience** — extend `explain-decision` framing; the trace contract is stable.

## Versioning

`engine_version` 3.0.0 · `rules_version` 1.0.0 · `scoring_version` 1.0.0 ·
`graph_version` 1.0.0. Bump the relevant version when its logic changes; traces
record the versions in effect so historical decisions stay reproducible and
A/B-comparable.

## Deploy / bootstrap order

1. Apply migrations **082 → 092** in order.
2. Secrets: `ANTHROPIC_API_KEY`, `YOUTUBE_API_KEY`.
3. Deploy edge functions: `enrich-exercise-videos`, `enrich-exercise-content`,
   `enrich-exercise-intelligence`, `explain-decision`.
4. In the Content Center: Rebuild graph → AI-enrich intelligence → Knowledge
   Review → Seed warm-up library.
