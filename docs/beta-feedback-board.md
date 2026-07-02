# 12 Circle — Beta Feedback Board

**Phase 1 (Platform Build): COMPLETE.**
**Phase 2 (Validation & Product-Market Fit): OPEN.**

This board turns raw beta observations into a prioritized, evidence-driven
backlog. In Phase 2, **new work must earn its place here** — no feature ships
without a justification rooted in beta evidence (see the bar at the bottom).

Companion to `validation-playbook.md` (what to measure) and `beta-readiness.md`
(activation). This is the *triage system* for what coaches actually hit.

---

## Severity framework

| Severity | Definition | Target response |
|----------|-----------|-----------------|
| **Critical** | Prevents successful coaching or onboarding. Blocks the core loop. | Same day — hotfix or workaround before the next coach session. |
| **High** | Significant friction, but a workaround exists. | Within the current cohort week. |
| **Medium** | Noticeable improvement to the experience; not blocking. | Batched into the next iteration. |
| **Low** | Cosmetic or preference. | Backlog; address during hygiene passes. |

## Area tags

`onboarding` · `coach-copilot` · `program-builder` · `continuous-coaching` ·
`weekly-review` · `workout` · `nutrition` · `ai-reviews` · `content` ·
`marketplace` · `payments` · `ux` · `performance` · `notifications`

## What to capture per item

```
ID · Date · Coach (or "internal") · Area tag · Severity
Observation  — what actually happened (behavior, not opinion)
Friction     — where they hesitated / what they asked to be explained
Evidence     — how many coaches hit it; any observability/metric signal
Decision     — fix now / batch / backlog / won't-do (+ why)
```

Prefer **observed behavior over stated preference.** "Three coaches hesitated on
the recovery slider" beats "a coach said the UI could be nicer."

## Board

| ID | Date | Area | Sev | Observation | Coaches | Decision |
|----|------|------|-----|-------------|---------|----------|
| _(add rows during cohort sessions)_ | | | | | | |

## Triage cadence

- **During each session:** log observations live; don't help the coach — note
  where they hesitate, which screens they ignore, what they ask you to explain,
  which AI suggestions they accept vs override.
- **End of each cohort week:** triage the new rows, assign severity, decide.
  Ship Critical/High before the next five coaches arrive.
- **Cross-cohort:** watch for the *same* friction across cohorts — repeated
  medium-severity items are often the highest-value fixes.

## Signals to watch (from the Observability dashboard)

- AI suggestions accepted immediately vs overridden → trust/quality.
- Screens never visited → dead weight or discoverability problem.
- Adherence / goal-confidence trends by cohort → is it working?
- Most-triggered rule / most-common adaptation → where the engine leans.

## The bar for new features in Phase 2

A feature is justified only if **at least one** is true:

1. A coach requested it **repeatedly** (or multiple coaches did).
2. The **observability dashboard** identified a measurable problem it solves.
3. The **validation metrics** (trust rate, decision accuracy, time saved)
   revealed an opportunity.
4. **Multiple users** hit the same friction.

Otherwise it waits. The candidate presentation features (Daily Brief, Celebration
Engine, Goal/Prediction dashboards, Client Timeline) are held against this bar —
build the one coaches ask for, not the one that sounds good.

### Three questions before any feature enters development

Every request must answer all three, or it stays in the backlog:

1. **Which user problem does this solve?**
2. **What evidence from beta supports building it?**
3. **How will we know it was successful?** (the metric, defined up front)

If any answer is missing, there isn't enough evidence yet.

## Definition of Phase 2 success

**50 active coaches using the platform for 90 days**, and at least one coach who
says *"I can't imagine coaching without this anymore."*
