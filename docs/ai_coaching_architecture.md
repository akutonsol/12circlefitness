# 12 Circle — AI Coaching Technical Architecture (v1.0)

The AI Coach is a **coaching-intelligence layer**, not a chatbot. It consumes the
user's full context (profile, goals, adherence, recovery, history, memory) and
produces decisions and content: daily briefs, weekly reviews, predictions, risk
assessments, accountability nudges, progress insights, and full workout sessions —
delivered in the user's chosen coaching voice, gated by a confidence score.

This document is the spec **and** a description of the shipped system (migrations
074–078, edge functions `ai-coaching-engine`, `ai-generate-workout`, `ai-coach`).

---

## 1. Design principles

1. **Separation of concerns.** The exercise schema powers *workouts*; the AI
   schema powers *decision-making and personalization*. They are different
   systems that cooperate.
2. **Many small tables, not one JSON blob.** Each concern is its own table so it
   scales and stays queryable.
3. **Deterministic where possible, LLM where it adds judgement.** Pattern
   detection, confidence, and eligibility are computed in SQL/TS; nuance,
   phrasing, and selection are Claude's job.
4. **Ground the LLM in real data.** Workout generation selects from the actual
   library by exact name; insights cite real numbers. No hallucinated exercises.
5. **Cost-scoped.** Generation runs for *active* users (last 14 days) on a nightly
   cron, plus on-open auto-generation. Cheap models (Haiku) for extraction.
6. **Safety via confidence.** When data is thin, the coach softens advice instead
   of making strong changes.

---

## 2. Data model

| Table | Purpose | Key fields |
|---|---|---|
| `ai_profiles` | Persona + goals + preferences + learned patterns (1/user) | `coach_persona`, `goals`, `preferences`, `behavioral_patterns`, `last_review_at` |
| `ai_memories` | Durable facts the coach remembers | `kind` (like/dislike/injury/constraint/preference/note/pattern), `content`, `source` |
| `ai_insights` | Daily briefs + accountability + risk + progress | `type`, `title`, `body`, `data`, `for_date` |
| `ai_reviews` | Weekly reviews | `period_start/end`, `summary`, `metrics` |
| `ai_goal_predictions` | Goal-date projections | `current/target_weight`, `current_pace`, `projected_date`, `confidence` |

All RLS-scoped to `user_id = auth.uid()`. The engine reads/writes via the service
role; the app reads its own rows directly.

---

## 3. The 10 systems

| # | System | Implementation |
|---|---|---|
| 1 | **Profile Engine** | `ai_profiles`; seeded from onboarding + maintained by the pattern job |
| 2 | **Memory Engine** | `ai_memories`: manual (UI), auto-capture (075 triggers: injuries, feedback notes), pattern-learning (078), conversation extraction (ai-coach fn) |
| 3 | **Decision Engine** | `daily_insight` type → focus, `intensity_delta`, nutrition/recovery notes |
| 4 | **Workout Generator** | `ai-generate-workout` — library-grounded session; rule-based `generate_client_plan()` (077) for multi-week programs, focus-biased |
| 5 | **Nutrition Coach** | Mifflin–St Jeor plan + daily `nutrition_note` + AI nutrition module |
| 6 | **Accountability Coach** | `accountability` type → contextual nudge → `ai_insights` + notification |
| 7 | **Insights Engine** | `progress_insight` type → data-grounded win from set logs |
| 8 | **Prediction Engine** | `goal_prediction` (date) + `risk_assessment` (plateau/churn/injury) |
| 9 | **Conversation Memory** | ai-coach chat extracts durable facts (Haiku, keyword-gated) → `ai_memories` |
| 10 | **Coach Personality** | `coach_persona` (7 styles); engine injects a delivery directive |
| ⭐ | **Confidence Score** | Deterministic 0–99 from data depth; passed to Claude to gate strong advice |

---

## 4. The engine (`ai-coaching-engine`)

A single edge function parameterized by `type`. Pipeline:

```
auth (user JWT, or service-role + user_id for cron)
  → ai_detect_patterns(uid)          # refresh behavioral memory
  → assemble context                 # profile, goals, scores, workouts,
                                     #   nutrition, habits, recovery, set logs,
                                     #   ai_memories (likes/dislikes/injuries/notes/patterns)
  → compute confidence (TS)          # data depth → 0-99 + reasons
  → build system prompt              # persona directive + per-type instructions
  → Claude (sonnet)                  # strict JSON out
  → persist to the right table
  → return { result, confidence, persona }
```

### Context window
Compact, structured JSON: profile snapshot, latest score, 14 recent workouts
(date/completed/title), nutrition/habit counts, latest recovery, grouped memory,
and (for progress) recent set logs. Kept terse to control tokens.

### Prompt architecture
- **System** = `persona directive` + `type instructions` (strict JSON shape).
- **User** = `confidence directive` + the context JSON (+ library for workout gen).
- Output parsed defensively (strip fences, slice to first/last brace).

### Confidence (safety gate)
```
base 15
+ workouts:   ≥8 → +28, ≥3 → +16, ≥1 → +7
+ daily activity ≥5 days → +14
+ goal set → +10
+ memory items: ≥3 → +16, ≥1 → +8
+ nutrition logged ≥7 → +9
+ weight on file → +5         (cap 99)
```
< 50 → the prompt instructs the model to soften changes and ask for
confirmation. Surfaced to the user as a Confidence chip (amber < 50).

---

## 5. Memory & pattern-learning

- **Auto-capture triggers (075):** profile injuries → `injury` memories; workout
  feedback notes → `note` memories.
- **Pattern job (078) `ai_detect_patterns(uid)`:** best/missed workout day,
  average session length, meal-logging gaps → `ai_profiles.behavioral_patterns`
  + `pattern` memories (recomputed fresh each run). Runs before every generation.
- **Conversation extraction:** the chat fn extracts likes/dislikes/injuries/
  constraints ("traveling next week") via a cheap gated Haiku call.

---

## 6. Workout generation rules (`ai-generate-workout`)

Inputs: goal, equipment, experience, location, injuries, dislikes/likes, recovery,
today's **focus** + **intensity_delta**, target duration, and a **library subset**
(global/approved exercises with muscle/equipment/contraindications).

Rules enforced via the system prompt:
- Select **only** from the library, by exact name.
- Avoid injury-contraindicated and disliked exercises; favour likes.
- Apply `intensity_delta`: negative → less volume / RIR; positive → push.
- 4–7 exercises, big→small, supersets where sensible.

Output is the program-workout exercise shape (`name`, `sets`, `reps`,
`rest_seconds`, `tempo`, `superset_group`, `notes`) so it plugs straight into the
existing active-workout flow and is started immediately (no program entanglement).

`generate_client_plan()` (multi-week, rule-based) remains for full programs and
is **focus-biased** (077): the final training day swaps to the coach's focus.

---

## 7. Scheduling

- **Nightly cron (076):** `ai_cron_generate(type)` posts to the engine
  (service-role) for users active in the last 14 days — daily briefs 06:00 UTC,
  weekly reviews Mon 07:00 UTC. Service key stored in Vault.
- **On-open:** the AI Coach screen auto-generates a missing daily brief (1/day
  via per-date dedup) and a stale weekly review (≥7 days).
- **Manual:** every card has generate / refresh.

---

## 8. How AI output reaches training

```
ai_insights.daily_insight (focus, intensity_delta)
  → coachAdjustmentProvider
     → Workouts banner            (surface)
     → active-workout load cue    (apply during the session)
  → generate_client_plan() (077)  (bias program structure)
ai-generate-workout                (full personalized session, started in-app)
```

---

## 9. Coach personality

`coach_persona = { name, style, tone }`. Seven styles (Supportive → High Energy)
chosen in-app. The engine prepends a directive: *"Deliver in a `{style}` style with
a `{tone}` tone — the substance never changes, only the delivery."* The advice is
constant; only voice varies.

---

## 10. Safety rules

1. **Confidence gating** (§4) — no strong changes on thin data.
2. **Injury-aware** — generation avoids contraindicated exercises; injuries live
   in memory and profile.
3. **Grounded output** — workout exercises must exist in the library.
4. **RLS isolation** — users only see their own AI data.
5. **Best-effort, non-blocking** — extraction and pattern jobs never break the
   primary response.
6. **Human handoff (future)** — coach-assigned clients keep coach authority;
   AI augments, and a coach can override any AI artifact (see §11).

---

## 11. Coach ↔ AI handoff (current + planned)

- Coaching mode (`self` / `ai_guided` / `coach`) already routes plan ownership.
- AI artifacts are advisory; a human coach's assignments supersede self/AI plans.
- **Planned:** surface AI insights/risk to the assigned coach's dashboard so the
  human coach acts on AI signals (e.g. churn/injury risk) for their clients.

---

## 12. Roadmap (post-v1.0)

- Nutrition macro **auto-adjustment** from weight trend (close #5).
- Coach-facing **AI signals** (risk/adherence) on the client dashboard.
- **Accountability timing** — fire nudges around the user's usual training time.
- **A/B the persona** effect on adherence; learn the best style per user.
- Per-exercise **substitution** suggestions in the active workout from memory.
