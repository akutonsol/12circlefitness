# 12Circle Fitness — Correction-Rights Exhaustion Report

**Phase:** Priority 6 — data-subject correction / access rights. **Discovery, not remediation.**
**Branch** `chore/qa-environments-secure-ai-backend` · entry HEAD `e591528`
**Live evidence:** QA `eyqtldjqpgpljlqvpowh`, reversible writes only, every row restored and verified.
**Production `nxdbooufqzkpslkcogxc` never contacted.**

> Technical control assessment. Not a HIPAA compliance certification. No production
> code was changed and no migration was created or applied.

---

## A · Executive summary

The Privacy Policy states, in full: *"You may update your personal information
directly within the app."*

**The database grants a member complete correction rights over their own health
record. The application exposes a fraction of it.** Live reversible writes confirmed
the subject may correct — and clear — `parq_answers`, `medical_conditions`,
`dietary_restrictions`, `food_allergies`, `injury_description`, `consent_agreed`,
even `email`, and may DELETE rows in 8 of 9 health tables. The app offers almost
none of this.

Three things make that more than a UI gap:

1. **The guarded-write pattern** — `if (value.isNotEmpty) payload['field'] = value`
   across 19 PHI-relevant fields. Clearing a wrong value in the UI writes **nothing**,
   so the old value survives. Erasure is part of correction.
2. **`CycleService` cannot report failure at all** — four write methods, all
   `Future<void>`, **zero `catch` in the file**, each beginning
   `if (uid == null) return;`. On an expired session it returns normally, the sheet
   closes, the UI refreshes, and nothing was written. This is period and symptom data.
3. **The subject cannot view 17 stored fields**, including their own `parq_answers`
   and `consent_date` — while the coach reads `parq_answers` at
   `client_detail_screen:806`. The subject can *write* those fields via the API but
   cannot *read* them in the app.

The app's own `daily_checkin_screen` + `submitWeeklyCheckin` do this correctly, which
is what makes the rest deviations rather than an absent convention.

---

## B · Scope and methodology

Categories C–G of the correction-rights brief. Method: source mapping of every
client-facing write path per health table → classification (a–e) → live reversible
verification against QA fixtures → mutation-tested guard.

**Live-test protocol:** capture original → mutate → observe authorization → restore →
re-read → assert equality. Every run in this report ended `MATCHES ORIGINAL: True`.
No PHI values are reproduced here; only field names, paths and authorization outcomes.

---

## C · Baseline

| | Entry | Exit |
|---|---|---|
| Tests | 1,625 pass / 9 skipped | **1,631 pass / 9 skipped** |
| Analyzer errors | 0 | **0** |
| Guard tests | 36 | **37** |
| Production files changed | — | **0** |
| Migrations changed | — | **0** |
| Disk | 822 MiB | **786 MiB (96 %)** |
| Runtime | BLOCKED | **BLOCKED** |
| Docker | DOWN | DOWN |
| `QA_SERVICE` | absent | absent |

---

## D · Correction-rights matrix

Classification: **(a)** UI corrects · **(b)** UI corrects but cannot clear ·
**(c)** backend permits, no UI control · **(d)** intentionally prohibited ·
**(e)** not demonstrable.

| Record | Surface | Class | Live-verified |
|---|---|---|---|
| first / last name | `personal_info_screen:164` | **(a)** | ✓ |
| gender, date_of_birth, phone | `personal_info_screen:168–170` | **(b)** | ✓ |
| height, weight, goal weight | `personal_info_screen:174–176` | **(b)** | ✓ |
| fitness_goal, activity_level, training_location, nutrition_goal | same | **(b)** | ✓ |
| **email** | none | **(c)** — DB permits; `auth.updateUser` is password-only | ✓ |
| **parq_answers, medical_conditions, injury_description** | intake only; `/intake` unreachable post-onboarding | **(c)** | ✓ write **and clear** permitted |
| dietary_restrictions, food_allergies | intake only | **(c)** | ✓ |
| consent_agreed / consent_date | none | **(c)** — self-writable → §L | ✓ |
| weight_logs | `progress_screen:1392` insert only | **(c)** UPDATE+DELETE granted | ✓ |
| body_measurements | `progress_screen:1242` insert only | **(c)** | ✓ |
| nutrition_logs | `nutrition_service:53` insert only | **(c)** | ✓ |
| **cycle_logs** | `cycle_service:44` insert; `:64` sets `end_date` only — a **state transition**, not correction | **(c)** | ✓ |
| **cycle_symptoms** | `cycle_service:79` upsert on `(user_id, log_date)` | **(b)** — `energy/mood/flow/notes` omitted when null | ✓ |
| cycle_settings | `cycle_service:19` upsert | **(b)** | ✓ |
| weekly_checkins | `submitWeeklyCheckin` upsert corrects the week; **UI gate** `mayOfferCheckinForm(k) => k == notDone` blocks re-entry | **(c)** | ✓ |
| workout_set_logs | `workout_service:133` update-then-insert on identity | **(a)** | — |
| goals | `goal_service` insert/update/delete | **(a)** — the only full client CRUD | — |
| ai_memories | `ai_coach_service` upsert/delete; long-press only (OD-60) | **(a)** | — |
| action_items `client_notes` | `action_item_service:91`, written **only at completion** | **(b)+(c)** no later edit path | — |
| workout_feedback | insert only, table read nowhere (OD-59) | **(c)** | — |
| **coach_notes** | **(d)** — migration 018:25 states *"ONLY the authoring coach can read/write — the client must never see these."* | **(d)** | INCONCLUSIVE (0 rows) |
| progress photos | upload/replace; no in-app delete | **(c)** | ✓ owner delete works |

---

## E · Live-tested controls

| Test | Result |
|---|---|
| Subject corrects every intake/health field on own row | **PERMITTED** (7/7), restored exactly |
| Subject clears `parq_answers` → `{}`, `activities` → `[]` | **PERMITTED** |
| Subject clears `phone`/`medical_conditions`/`dietary_restrictions` → `''` | **PERMITTED** |
| Subject writes `email` | **PERMITTED** at DB level |
| DELETE grant, 9 health tables | granted on 8; **`weekly_checkins` denied `42501`** |
| End-to-end erasure with negative control | attacker DELETE on owner's real row → **0 rows**; owner → **1 row**; net state unchanged |
| Privileged columns (`role`, billing, Stripe) | rejected `42501` — unchanged |

`weekly_checkins` DELETE being deliberately denied is the strongest evidence that the
other grants are **intended**: the schema author reasoned about erasure and made one
explicit exception.

---

## F · UI-only gaps (backend capable, product silent)

1. **Erasure of any health record** — 8 tables grant DELETE, no screen offers it.
2. **PAR-Q / medical history correction** — `/intake` is reachable only from
   login/signup when `onboarding_complete == false`; no screen links to it.
3. **Weekly check-in correction** — the upsert corrects, the UI gate blocks re-entry.
4. **Clearing an optional profile field** — the guarded-write pattern.
5. **Email change** — no path at all.

---

## G · Backend-only capabilities

Every field in §E. Notably, the seven fields the subject **cannot view** (§H) are all
fully **writable** by them — the inverse of the expected asymmetry.

---

## H · Not demonstrable / blocked

| Check | Status | Blocker |
|---|---|---|
| `coach_notes` client-invisibility | **INCONCLUSIVE** | 0 rows; policy source is explicit |
| Any app runtime confirmation of UI behaviour | **ENVIRONMENT BLOCKED** | disk 786 MiB; Docker down |
| Optimistic-toggle failure behaviour end-to-end | **INCONCLUSIVE** | source-confirmed; needs runtime |
| Coach-authored record correction workflow | **NOT PRESENT** | no request/appeal flow exists |

**Fields stored but absent from the subject's own profile load** (`auth_provider:81`),
excluding privilege/billing: `parq_answers`, `injury_description`,
`biggest_challenges`, `consent_agreed`, `consent_date`, `protein_confidence`,
`worked_with_coach_before`, `activities`, `age`, `current_weight_kg`,
`goal_weight_kg`, `fitness_level`, `assigned_coach_id`, `bio`, `pricing_description`,
`transformation_photo_urls`, `onboarding_step` — **17 of 78**.

---

## I · Privacy Policy discrepancies

| Claim (verbatim, short) | Actual capability | Evidence | Severity | Decision |
|---|---|---|---|---|
| *"You may update your personal information directly within the app."* | Partial: name and some profile fields yes; PAR-Q, medical, allergies, email **no**; clearing **no** | §D, §E | **High** | Correct the copy, or expose the capability the DB already grants |
| *"You may request a full export of your data at any time from Profile → Settings → Account."* | **No export control anywhere**; no backend export path | prior phase, re-confirmed | **High** | Owner (SEC-PHI-4) |
| *"...disable marketing notifications from Profile → Settings → Notification Preferences..."* | Control exists, but the toggle is **optimistic and never reverted**; on an expired session it fails **silently** | `notification_preferences_screen:114–116, 50–53` | **Medium** | Fix; the policy names this control explicitly |
| *"We provide data exports in JSON or CSV format on request."* | Manual channel; not contradicted by code | no PDF/CSV generator exists | Low | none |
| *"Deleting your account from inside the app is not available yet."* | **ACCURATE** | §prior | — | none |

---

## J · HIPAA / security implications

| Safeguard | Status |
|---|---|
| Least privilege on correction | **VERIFIED** — subject writes only their own row; cross-user write returns `rows=0` |
| Integrity of privileged fields | **VERIFIED** — `role`/billing/Stripe rejected `42501` |
| Amendment of records (correction) | **CONTROL GAP** — backend capable, product surface absent |
| Accounting of disclosures / audit | **CONTROL GAP** — no audit table exists (carried) |
| Data-subject access to own record | **CONTROL GAP** — 17 fields neither viewable nor exportable |
| Integrity of consent record | **EVIDENCE REQUIRED** — `consent_agreed`/`consent_date` are self-writable |
| Failure transparency on PHI writes | **CONTROL GAP** — `CycleService`, `_persistUnit` |

---

## K · New findings

| ID | Sev | Surface | Behaviour | Live | Runtime | Mutated |
|---|---|---|---|---|---|---|
| **CORR-1** | **High** | `cycle_service.dart` (all 4 writes) | 4 × `Future<void>`, **0 `catch`**, each `if (uid == null) return;`. Expired session → returns normally, sheet closes, refresh fires, nothing written. Call sites `womens_health_screen:186, 233` have no error handling. `logPeriod` is a plain insert with no dedup, so retries can duplicate period records. | ✓ source; DB behaviour ✓ | ✗ | ✓ |
| **CORR-2** | Medium | `settings_screen.dart:54–63` | `_persistUnit` ends `catch (_) {}` — fully silent — and is called unawaited after `setState`. | ✓ source | ✗ | ✓ |
| **CORR-3** | **High** | `personal_info_screen:164–181`, `cycle_service`, `action_item_service:90–91` | Guarded-write pattern across **19 PHI-relevant fields**; a cleared field writes nothing. | ✓ DB permits clearing | ✗ | ✓ |
| **CORR-4** | Medium | `notification_preferences_screen:114–116` | 6 toggles: `setState` flips first, `_saveToggle` **not awaited**, state **never reverted** on failure; `uid == null` → no snackbar at all. | ✓ source | ✗ | ✗ |
| **CORR-5** | **High** | `auth_provider:81` vs schema | 17 stored fields unviewable by the subject, incl. `parq_answers` and `consent_date`, while the coach reads `parq_answers`. | ✓ | ✗ | ✗ |
| **CORR-6** | Medium | `daily_checkin_screen:184–192` | `mayOfferCheckinForm(k) => k == notDone` blocks re-entry, so the upsert's correction capability is unreachable. | ✓ | ✗ | ✗ |
| **CORR-7** | Low | `action_item_service:91` | `client_notes` written only at completion; no later edit or clear path. | ✓ source | ✗ | ✗ |

**Reproduction** for CORR-1/2/3: `flutter test test/unit/correction_rights_guard_test.dart`
— it asserts each defect's current shape and fails when any is fixed.
For the DB-side claims: the probes in §E, all reversible.

---

## L · Owner decisions required

1. **Correction scope** — expose the DB-granted correction rights, or amend the
   Privacy Policy's *"directly within the app"*. (Legal copy is not QA's to write.)
2. **Erasure** — should a member be able to delete a weight log, measurement,
   nutrition entry or cycle log? The DB already permits it; `weekly_checkins` is the
   deliberate exception.
3. **PAR-Q amendment** — clinical. Migration 115's trigger derives `risk_level` from
   it for the coach and the AI, so a stale PAR-Q is a safety question (carried
   SEC-PHI-7 / SAFE-1).
4. **`consent_agreed` / `consent_date` self-writability** — should a consent record be
   client-writable, or server-stamped and append-only?
5. **`coach_notes`** — the product rule is explicit and deliberate; whether PHI held
   about a subject who may never see it is acceptable is a legal question.
6. **Coach-authored records** — no correction/appeal workflow exists for a client who
   disputes what a coach recorded about them. Is one required?

---

## M · Mutation testing

**CORR-G1 — 6 killed / 6 meaningful mutations, plus 1 false-alarm check.**

| Mutation | Result |
|---|---|
| `logPeriod` starts reporting failure (`bool`) | KILLED |
| `CycleService` gains a real `catch` clause | KILLED |
| silent-return arms removed | KILLED |
| `_persistUnit` stops swallowing | KILLED |
| `phone` becomes unconditionally writable (clearable) | KILLED |
| the correct-clearing baseline (`notes ?? ''`) disappears | KILLED |
| **`catch` appears only in a COMMENT** | **correctly raises no alarm** |

**A guard weakness mutation testing found and forced me to fix.** The first version
asserted `src.contains('catch')` on the raw file — killed by the word appearing in a
*comment*. That is the commented-code-as-active-code trap this programme has already
been bitten by in SQL. The guard now strips line comments and matches a catch
**clause** (`} catch (`), not the bare token.

---

## N · False positives and corrections to earlier work

| Claim | Correction |
|---|---|
| *"`submitCheckin` and `hasSubmittedThisWeek` are dead code"* | **MY ERROR.** I grepped names that do not exist. The real methods are `submitWeeklyCheckin` and `weekStatus`, both with callers. Withdrawn before it reached the report. |
| `create_exercise_screen` "optimistic writes" ×4 | **FALSE POSITIVE** — `_toggleRow` is a widget **builder** (line 38), not a persistence call. |
| Guarded-write sweep hits `p_program`, `p_subject`, `p_note`, `token` | **FALSE POSITIVE** — RPC parameters and an invite token, not user-data columns. 26 raw hits → **19** PHI-relevant. |
| M2 mutation "SURVIVED" | **INVALID mutation, not a guard weakness** — it inserted `try {` and never a `catch`, so the assertion was correctly unmoved. Re-run properly: KILLED. |

---

## O · Remaining executable QA work

Essentially none in this environment for correction rights. Remaining items need a
capability, not more analysis:

| Needs | Would enable |
|---|---|
| **Runtime (≥10 GiB disk)** | CORR-1/2/4 end-to-end: does the sheet really close on failure; does the toggle really stay flipped |
| **`QA_SERVICE` + fixtures** | `coach_notes` client-invisibility; coach-authored record tests |
| **Docker** | schema introspection of column-level grants |

**A new environment data point:** a `flutter test` run **stalled at 0 % CPU with no
output** during this phase and had to be killed (exit 144). Disk is 786 MiB. Disk
pressure has begun to affect the **test suite**, not only runtime builds. The suite
completed on retry (1,631 pass), but QA capability is now degrading.

---

## P · Recommended next QA phase

1. **Reclaim disk.** It has now interrupted the test suite itself.
2. Carry CORR-1…CORR-7 into the remediation queue. **CORR-1 first** — silent failure
   on reproductive-health writes is the most consequential and the cheapest fix
   (`bool` return + a snackbar, matching `submitWeeklyCheckin` beside it).
3. Put the §L decisions to the owner; items 1 and 4 gate the rest.
4. `QA_SERVICE` + fixtures remains the highest-leverage unblock across all phases.

---

## Final status

| | |
|---|---|
| Tests | **1,631 pass / 9 skipped** |
| Analyzer | **0 errors** |
| Runtime | **BLOCKED** (disk 786 MiB; Docker down; 0 devices) |
| Live schema | reachable via anon + fixture identities; introspection blocked |
| Files changed | 1 new guard, 1 new report |
| Production files changed | **0** |
| Migrations changed | **0** |
| Commits | 1 |
| Open findings | CORR-1…CORR-7, plus all carried |
| Owner decisions | 6 (§L) |

**CORRECTION-RIGHTS QA EXHAUSTED — OPEN FINDINGS REMAIN.**

Not "QA complete", and not a claim of HIPAA compliance. The correction-rights surface
has been examined to the limit of this environment; what remains is blocked on disk,
`QA_SERVICE` and Docker.
