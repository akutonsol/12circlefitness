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

### The guardian question (ask first, always)

> **Does this make 12 Circle a better *coaching platform*, or just a bigger
> *software platform*?**

If it only makes the software bigger, stop here. This one question prevents
feature creep better than any roadmap, and it protects the Product Bible.

### Three questions before any feature enters development

Every request must answer all three, or it stays in the backlog:

1. **Which user problem does this solve?**
2. **What evidence from beta supports building it?**
3. **How will we know it was successful?** (the metric, defined up front)

If any answer is missing, there isn't enough evidence yet.

## The one question beta answers

> **At the end of a coaching week, did the coach ever need to leave 12 Circle to
> finish their job?** If mostly *no*, you've built something real. If *yes* — what
> task, why, how often — that's the roadmap.

## Monday standup (5 questions, every week)

1. How many coaching sessions were completed entirely inside 12 Circle?
2. Where did coaches leave the platform?
3. What did they override or ignore?
4. What delighted them enough to mention unprompted?
5. What did they ask for repeatedly?

## Cohort 1 scorecard (first five coaches)

| Metric | Target |
|--------|--------|
| Coaches onboarded | 5 |
| Still active after 4 weeks | 4+ |
| Weekly programs created inside 12 Circle | 100% |
| Weekly reviews sent | > 75% of clients |
| Coach Copilot used | > 70% of programming sessions |
| "I'd use this with paying clients" | 4 / 5 |

## Moments log (capture quotes, not just bugs)

Save the exact words. Positive *and* negative — they're product data now, marketing
language later.

- ✅ "That saved me 20 minutes." · "I didn't have to think about programming." ·
  "I usually use Google Docs for this."
- ⚠️ "I switched back to Excel." · "I couldn't find…" · "I didn't trust…"

Each ⚠️ moment should become a board row (with severity + area).

## Deferred until there's usage (not a beta blocker)

**Internal product analytics** (for the team, not the coach): feature usage, AI
acceptance rates, most-applied packs, most-viewed exercises, screen abandonment,
time-from-signup-to-first-assigned-workout. Build *after* cohort 1 — real usage
makes it worth building; before, there's nothing to measure.

## North star

**50 active coaches using the platform for 90 days**, and at least one coach who
says *"I can't imagine coaching without this anymore."*
