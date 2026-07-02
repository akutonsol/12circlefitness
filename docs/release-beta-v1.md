# 12 Circle — Release: Beta 1.0 (Build Complete)

**Version:** 12 Circle Beta 1.0
**Tag:** `beta-v1.0-build-complete`
**Date:** 2026-07-02
**Milestone:** Platform architecture feature-complete (L1–L8). Entering Phase 2
(Validation & Product-Market Fit).

This is the immutable baseline snapshot taken before the first coach cohort. Use
it to compare Beta 1.0 → Beta 2.0 and see exactly how the product evolved.

---

## What's included

### The 8-layer platform
L1 Content · L2 Knowledge · L3 Decision · L4 Communication · L5 Experience ·
L6 Continuous Coaching · L7 Predictive Intelligence · L8 Coaching Communication.
Lifecycle: **Plan → Generate → Assign → Observe → Adapt → Predict → Communicate.**

### Database migrations (apply in order)
`082` exercise videos · `083` content pipeline · `084` certification ·
`085` movement intelligence engine · `086` certification projected ·
`087` programming intelligence · `088` rules + warm-up · `089` decision intelligence ·
`090` knowledge enrichment · `091` attribute review · `092` explanations ·
`093` program intelligence · `094` continuous coaching · `095` predictive intelligence ·
`096` communication engine.

### Edge functions (deploy + secrets required)
`enrich-exercise-content`, `enrich-exercise-intelligence`, `enrich-exercise-videos`,
`explain-decision`, `generate-communication` (+ existing `stripe-*`, `create-checkout`,
`ai-*`, email/reminder functions).
Secrets: `ANTHROPIC_API_KEY`, `YOUTUBE_API_KEY`, Stripe keys, email/push providers.

### Coach experiences (L5)
Coach Copilot · Dynamic Program Builder · Continuous Coaching · Weekly Review ·
Exercise Content Center · Knowledge Review · MIE Debugger · Coaching Observability.

### Internal tooling
QA Center (`/qa-center`) with Release Certification gate · CLI harnesses
(`qa_self_guided.dart`, `qa_entitlements.dart`).

### Governance documentation
`product-bible` · `movement-intelligence-engine` · `beta-readiness` ·
`why-12-circle-wins` · `validation-playbook` · `decision-log` · `beta-feedback-board` ·
this release manifest.

## Quality status at snapshot
- `flutter analyze lib`: **0 errors, 0 warnings** (73 info-level lints, non-blocking).
- `flutter build web`: **passes**.
- Deterministic engine logic (scoring, rules, planner, evaluation, prediction,
  certification): **verified via simulation** at build time.

## Known state / not yet done (Phase 2 work)
- Migrations **not yet applied** to the production DB; edge functions **not yet
  deployed**; secrets **not yet set** → most intelligence is dormant until the
  Activation Sprint runs (`beta-readiness.md` §0).
- Exercise content **~25% populated** (623 exercises, ~22 complete). Largest
  remaining task; architecture to fix it is built.
- Measurement capture hooks (trust rate, decision accuracy, coach time) **not yet
  added** — the only sanctioned backend work in Phase 2, to ship once a cohort is
  live (`validation-playbook.md`).

## Deliberately excluded from this tag
- `apps/api/` — a pre-existing untracked NestJS service with a compiled `dist/`.
  Not authored in this build phase; needs its own review + `.gitignore` before
  being committed. Left untracked intentionally.

## Reproduce / verify this baseline
```
git checkout beta-v1.0-build-complete
cd apps/mobile && flutter analyze lib && flutter build web
```
