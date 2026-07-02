# 12 Circle — Beta Readiness Checklist

The platform architecture is complete (L1–L8). Remaining work is **finishing the
product**, not building it. Every task below maps to one of four categories:
**Product · Content · Operations · Launch**. Ordered by what gates a controlled
coach beta.

> Snapshot: architecture ~100%, engineering ~98%, **content ~25%** (the real
> gate), polish ~80%. Beta-ready once content is substantially populated and the
> ops items below are green.

---

## 0. Activate the intelligence stack (one-time, blocking)

The MIE/CCE/PIE/Communication layers are code + migrations; they are **inert
until applied & deployed**. This is the single highest-leverage unblock.

- [ ] Apply migrations **082 → 096 in order** (Supabase SQL). These add the
  exercise content pipeline, certification, movement graph, programming
  intelligence, decision traces, program builder, continuous coaching,
  predictions, and communications.
- [ ] Set secrets: `ANTHROPIC_API_KEY`, `YOUTUBE_API_KEY`, Stripe keys.
- [ ] Deploy edge functions:
  `enrich-exercise-content`, `enrich-exercise-intelligence`, `enrich-exercise-videos`,
  `explain-decision`, `generate-communication` (plus existing `stripe-*`, `create-checkout`, etc.).
- [ ] Bootstrap in the Content Center: **Rebuild graph → AI-enrich content →
  AI-enrich intelligence → Knowledge Review → Seed warm-up library**.
- [ ] Smoke-test end to end: Coach Copilot → recommend → assign; Program Builder
  → plan → create; Continuous Coaching → feedback → regenerate; Weekly Review →
  generate → send.
- [ ] Run the **QA Center** (`/qa-center`) and confirm the **Release
  Certification** gate is green (Critical = 0).

---

## 1. Content  ⚠️ *the gate*

Verified live: **623 exercises, ~22 fully complete, ~601 stubs**; images **1/623**,
videos **1/623**, instructions/cues/mistakes **~22/623**. Architecture to fix this
is done (pipeline + certification + review queue); it needs to be *run*.

- [ ] Run AI content enrichment across the library (batches; Content Center).
- [ ] Run AI intelligence enrichment (fatigue/joint-stress/rep-ranges/etc.).
- [ ] Work the **Knowledge Review** queue — certify low-confidence attributes.
- [ ] Populate **cover images** — decide source hierarchy (coach demo > licensed >
  brand-generated > AI placeholder). *No automated source wired yet — needs a decision.*
- [ ] Populate **demo videos** via `enrich-exercise-videos` (YouTube) and/or coach uploads.
- [ ] Target: **Certification Matrix** shows a healthy count of `workout_builder`,
  `self_guided`, and `ai_coach`-ready exercises (Content Quality dashboard).
- [ ] Nutrition database seed (for the Nutrition module) — currently thin.

## 2. Product (UX polish)

- [ ] Onboarding flow review (intake → mode selection → first program).
- [ ] Empty states for every list (no clients, no programs, no feedback, no content).
- [ ] Error handling / offline states (surface failures, retry affordances).
- [ ] Mobile responsiveness pass (the new coach tools: Copilot, Program Builder,
  Continuous Coaching, Weekly Review, Content Center).
- [ ] Loading skeletons for engine calls (some take a beat under real data).
- [ ] Coach dashboard tool sheet is getting dense — consider grouping
  (Clients / Intelligence / Content / Business).
- [ ] Quick, high-delight comms on the existing engine: **Daily Brief**,
  **Post-Workout**, **Celebration** (deterministic streak/PR/milestone triggers).

## 3. Operations

- [ ] **Stripe production** configuration (live keys, products, Connect onboarding,
  webhook endpoint verified). `create-checkout` / `stripe-connect` / `stripe-webhook` exist.
- [ ] Email delivery in production (`notify-coach-email`, `send-invite-email`,
  `send-checkin-reminder`) — verify sender domain / provider.
- [ ] Push notifications (device tokens, APNs/FCM) — currently browser-only.
- [ ] Monitoring / error logging / alerting on edge functions + DB.
- [ ] Database backups + restore drill; RLS audit on the new tables
  (predictions, communications, weekly_feedback, program_versions, decision_traces).
- [ ] Rate-limit / cost guardrails on the AI edge functions (batch caps exist;
  confirm daily spend ceilings).
- [ ] Cron health: score resets, any scheduled jobs.

## 4. Launch

- [ ] Privacy Policy + Terms of Service (screens exist — confirm content is final/reviewed).
- [ ] App Store / Play assets (icons, screenshots, descriptions) if shipping native.
- [ ] Marketing / landing site.
- [ ] Support documentation + **coach onboarding guide** (how Copilot / Program
  Builder / Reviews work).
- [ ] Beta cohort selection + feedback capture loop.
- [ ] Internal reference docs kept current:
  `docs/movement-intelligence-engine.md`, `docs/ai_coaching_architecture.md`.

---

## Suggested engineering allocation (per the beta phase)

**Experience/UX 70% · Content 20% · Backend 10%.** The backend has reached
diminishing returns; do not add new foundational systems before beta. New
communication types (daily brief, celebrations) and dashboards (Goal Progress,
Prediction history) are *thin layers on existing engines*, not new backend.

## Definition of "beta-ready"

1. Migrations applied, edge functions deployed, QA Release gate green.
2. Exercise library substantially enriched + certified (not 25%).
3. Stripe live + email/push working.
4. Onboarding + empty/error states polished on the client and coach happy paths.
5. Privacy/ToS/support docs in place.
