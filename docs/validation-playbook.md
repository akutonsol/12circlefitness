# 12 Circle — Validation Playbook

**Phase transition: BUILD → VALIDATE.** The platform architecture is
feature-complete (L1–L8). The question is no longer *"what should we build?"* but
*"what do real coaches actually need next?"* — answered with evidence, not
assumptions.

This complements `beta-readiness.md` (the *checklist*). This document is the
*measurement plan*: the activation sprint, the KPIs, and — honestly — what each
KPI requires before it can be trusted.

---

## The Activation Sprint (Week 1 — lock the repo, ship nothing new)

| Day | Work |
|-----|------|
| 1 | Apply migrations **082–096** in order. |
| 2 | Deploy edge functions; set secrets (Anthropic, YouTube, Stripe, email, push). |
| 3 | Populate the exercise library — Content Center: enrich → **Knowledge Review → approve** → repeat. |
| 4 | Run the **QA Center**; drive the **Release Certification** gate to green. |
| 5 | Internal dogfooding — every team member uses it as a coach + a client. |
| 6 | Fix **friction**, not bugs — where people hesitate, not where it breaks. |
| 7 | Invite **five** coaches. Watch. Don't help. Note every hesitation. |

Then repeat weekly: **five more coaches at a time.** Small cohorts keep the
feedback signal high and the support load survivable.

---

## The KPIs — and what each honestly requires

The Observability dashboard (`/observability`) already reports what's derivable
today from deterministic data (programs, traces, predictions, reviews sent,
adherence, goal confidence, certification %, knowledge confidence).

The three *validation* metrics below are more valuable — and **not yet
measurable.** Each needs a small, deliberate capture hook. This is the **one
exception** to the backend freeze: instrument to measure, nothing more.

### 1. Time Saved Per Coach / Week  ⭐ (the headline)
- **Needs:** a per-task baseline (how long program creation / review writing /
  modifications took *before* 12 Circle) + timestamps on the same tasks in-app.
- **Honest method:** baselines come from a short coach intake survey (self-report);
  in-app timings come from lightweight event timestamps (started → completed).
  Report *estimated* hours saved, labeled as estimate.
- **Not derivable from current data** — requires the survey + a few event marks.

### 2. Recommendation Trust Rate  ⭐ (few AI products can measure this)
- **Definition:** of recommendations shown, how many were accepted **without
  edit** vs edited vs rejected.
- **Gap:** today, coach edits **overwrite** the AI draft (`update_communication`),
  and only *applied* regenerations are traced — so "edited" and "rejected" are
  invisible. **Trust rate cannot be computed correctly right now, and a naïve
  version would be a vanity metric.**
- **Minimal capture to make it real:**
  - Communications: retain the original AI draft alongside the coach-final text
    (`llm_draft_client/coach`), and stamp `edited` / `sent_clean` on send.
  - Regenerations & Copilot: log the outcome (accepted / edited / rejected), not
    just the applied result.
- Then: `trust_rate = accepted_without_edit / total_shown`.

### 3. Decision Accuracy  (prediction vs reality)
- **Definition:** compare each prediction to what actually happened (predicted
  finish vs actual, plateau-risk vs plateau-occurred, recovery-forecast vs actual).
- **Have:** the `predictions` table stores every prediction with inputs + version.
- **Gap:** realized outcomes aren't recorded against them.
- **Minimal capture:** at program/goal completion (and each week), write the
  actual outcome back onto the matching prediction row (`actual_outcome`,
  `resolved_at`). Then accuracy is a straight comparison, and — because
  predictions store `engine_version` — you can see which rule versions perform.

> These three hooks are the *only* new backend I'd add in the validation phase,
> and only because they measure the mission. Ship them when the first cohort is
> live, not before.

---

## What drives Version 2 (evidence, not features)

Prioritize V2 by what the data and cohorts reveal:

- Which coach workflows still take too long? (task timings)
- Which AI communications are edited most? (trust-rate capture)
- Which prediction rules are least accurate? (decision-accuracy capture)
- Which exercises are skipped most? (session logs)
- Which content fields are corrected most? (`intelligence_attribute_reviews`)
- Which recommendations get overridden? (regeneration/Copilot outcomes)

Each question maps to a capture hook above — so validation *is* the V2 research.

## The milestone to celebrate

Not downloads, not revenue. **The first coach who says "I can't imagine coaching
without this anymore."** That's product-market fit at the individual level. The
target that proves it: **50 active coaches using the platform for 90 days.**

## Operating model, going forward

`BUILD → VALIDATE`. New work must earn its place against real usage. Presentation
layers over existing engines (Daily Brief, Celebration Engine, Goal/Prediction
dashboards, Client Timeline) remain fair game; new *foundational* systems are on
hold until a cohort tells us they're needed.
