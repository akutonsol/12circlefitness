# 12 Circle Fitness — Master Remediation Registry

**Wave 0 deliverable. The canonical finding ledger for the whole programme.**
**Date:** 2026-08-24 · **Branch:** `chore/qa-environments-secure-ai-backend`
**Environments:** QA `eyqtldjqpgpljlqvpowh` · Production `nxdbooufqzkpslkcogxc` — **not contacted during this reconciliation.**

> This document supersedes the per-workstream finding lists as the **tracking** artifact.
> It does not supersede them as **evidence**; every row points back to the report that
> proved it. Where this registry and a source report disagree on severity, status or
> classification, **this registry is authoritative and the deviation is stated.**

---

## 0. What this reconciliation did

| Step | Result |
|---|---|
| Reports read in full | `MASTER_QA_RECONCILIATION`, `REMEDIATION_EXECUTION_PLAN`, `PHASE_1_SECURITY_AUDIT`, `PHASE_2_WORKOUT_RECONCILIATION`, `WORKOUT_DOMAIN_CONTRACT`, `PHASE_2_WORKOUT_TEST_MATRIX`, `qa-environments`, and workstreams **A–N** (14 reports, ~11 000 lines) |
| Raw finding records ingested | **428** |
| Aliases collapsed | **118** |
| Canonical findings | **310** |
| Independently re-verified this session | 14 claims (§0.2) |
| Code changed | **none** |
| Migrations written | **none** |
| Environments contacted | **none** — no QA or production request was issued |

### 0.1 Evidence classes (used in every row)

| Mark | Meaning |
|---|---|
| **LIVE** | Reproduced against QA with a real request by the owning workstream |
| **SRC-V** | Proven from source **and re-verified in this session** against the current tree |
| **SRC** | Proven from source by the owning workstream; not re-derived here |
| **RPT** | Carried on the owning workstream's live reproduction |
| **OPEN** | Suspected; needs a probe or a decision before it can be classified |
| **UNVERIFIABLE** | Depends on production or on dashboard state that was deliberately not inspected |

### 0.2 Claims re-verified in this session

Fourteen load-bearing claims were re-derived against the current working tree, because
they gate the whole plan and the tree has moved under several workstreams.

| Claim | Source | Result |
|---|---|---|
| 20 migrations untracked, incl. 113–122 | LRE-03 | **CONFIRMED** — `git status` shows 20 `??`, `000` and `104`–`122` |
| 15 historical migrations edited in place | LRE-04 | **CONFIRMED** — 15 ` M`, list matches exactly |
| `APP_ENV` defaults to `prod` | LRE-01 / REL-07 | **CONFIRMED** — `app_env.dart:151` |
| Three Dart harnesses hardcode the production ref | LRE-02 / REL-18 / K-ENV-1 | **CONFIRMED** — `tool/live_integration_test.dart:15`, `qa_self_guided.dart:22`, `qa_entitlements.dart:27` |
| No CI beyond a production keep-alive ping | LRE-05 / N-01 | **CONFIRMED** — `.github/workflows/` holds one file |
| `materialize_program_week` lost its authorization guard | F-J-01 | **CONFIRMED** — 116 built a `can_act_on_program` wrapper over `*_engine`; `119:403` re-creates the public name as a bare `SECURITY DEFINER` body and `119:483` re-grants it to `authenticated`; `122` repins `search_path` by `ALTER FUNCTION` only and **does not restore the guard** |
| `derive_parq_risk` throws on the three literal flag appends | F-J-17 | **CONFIRMED** — `115:142,143,145` append untyped literals to a `text[]`; the indexed append at `:140` is typed and safe, so only pregnancy / postpartum / active-injury writes fail |
| `build_workout` throws whenever recovery < 60 | F-J-07 | **CONFIRMED** — `089:51` declares `rules text[]`; `089:55` appends the untyped literal `'RECOVERY_REDUCTION'` |
| Workout completion swallows persistence and celebrates anyway | EC-05 / N-07 | **CONFIRMED** — `active_workout_screen.dart:608` awaits `logWorkout` unguarded, `:611-619` wraps `completeSession` in `catch (_) {}` |
| `public.checkins` is created by no migration | CON-01 / I-CHK-01 / E-CHK-01 / M-02 | **CONFIRMED** — only `weekly_checkins` exists (`000:146`); `checkin_service.dart` and `coach_dashboard_screen.dart` both read `checkins` |
| Every A–N report is itself untracked | new | **CONFIRMED, and undercounted** — `docs/` held **29** untracked files, not 18. W1-T1 established that the whole untracked set is **96 files, not 62**: `git status` collapses a wholly-untracked directory into one entry, so `supabase/tests/` (25 files, every live security and AI probe) counted as a single item. All 96 are now tracked |
| Schema-contract guard exists and is wired | I | **CONFIRMED** — `npm run test:contract`, `supabase/tests/contract/known-violations.json` carries 2 relations + 8 columns |
| Live security / AI suites exist and are unwired | Phase 1, J, N | **CONFIRMED** — `supabase/tests/security/` (6 suites), `supabase/tests/ai/` (5 suites); neither runs in CI |
| Current mobile baseline | N (699) | **RE-MEASURED: 730 passed, 9 skipped, 0 failed** — the tree moved again after N |

**One correction to the reports, arising from this re-measurement:** every count quoted
in a workstream report (514 / 591 / 623 / 667 / 690 / 699 / 730) is a snapshot of a tree
that several sessions were writing to concurrently. **730/9/0 is the Wave 0 baseline.**
No count below 730 should be treated as a regression signal.

---

## 1. Canonical root-cause model

Prior workstreams produced five overlapping numbering schemes (`RC-1…RC-8` in the master
reconciliation, `RC-A…RC-D` in Phase 2, `C-1/C-2` in B, `RC-H1…RC-H5` in H, and
`RC-5/7/8/3/4/9/10/11/12` in I). They are **not** reconcilable by renumbering, because
several describe the same defect at different altitudes. The model below is canonical.
**Every prior ID maps into it; no prior ID survives as a tracking key.**

| ID | Root cause | Statement | Supersedes |
|---|---|---|---|
| **CRC-01** | **Schema-contract drift** | The application names relations and columns the database does not have. PostgREST validates the select list **before** authorization, so the answer is `400 / 42703` — never a permission error — and every call site converts it to an empty value. A typo is indistinguishable from a feature that was never built. | RC-H2; part of RC-5, RC-7 |
| **CRC-02** | **Undeclared payload contracts** | A payload or vocabulary crosses a boundary with no schema, no CHECK and no validator, and its writers and readers disagree. | RC-5, RC-A |
| **CRC-03** | **Failure returned as a legitimate value** | Two mechanically distinct halves. **C-1:** a thrown failure is caught and converted to `[]`/`null`/`false`/`0`/`{}`. **C-2:** no exception is ever thrown — PostgREST answers an RLS-filtered or id-missed write with **200 and zero rows**, so `await update(...); return true;` reports a write that never happened. | RC-7, RC-C |
| **CRC-04** | **Fabricated success** | Distinct from CRC-03: the fallback returns **fiction**, not emptiness — a ticket code for a row that was never written, invented coach messages, invented habit streaks, a fabricated `risk_level`, a synthetic `pending` check-in, a stated £0.00 balance. | RC-9, RC-H1 |
| **CRC-05** | **Degraded safety input, decision proceeds** | An input that constrains a safety decision fails to load, silently becomes the empty set, and the decision is made anyway — then recorded as a valid trace with a confidence score computed from the same emptied arrays. | new (B rule **S**) |
| **CRC-06** | **Human-readable label as authoritative identity** | A name, title or display code is used where a stable id belongs; or an identity model lives in application convention (check-then-insert) instead of in a UNIQUE index. | RC-6, RC-10, RC-B |
| **CRC-07** | **Default-open privilege, and controls applied by sweep** | Postgres and Supabase defaults grant broadly; migrations revoke `PUBLIC` only. Worse: a control applied by a **sweep** rather than at the point of definition is silently dropped by the next `CREATE OR REPLACE` — this has now happened to `search_path` (twice) **and to an authorization wrapper**. | RC-1, RC-3 |
| **CRC-08** | **Caller-supplied identity trusted** | A subject uuid, a `target_client_id`, a role claim or an empty-string bearer comparison decides whose data is read or written. | RC-4 |
| **CRC-09** | **Cross-user aggregate over per-user RLS** | A count, capacity or roster is computed by a client query against a table whose policy scopes rows to the caller. The query is not denied — it is **narrowed**, and a silently narrowed result is indistinguishable from a real one. | RC-11 |
| **CRC-10** | **Presentation shipped ahead of its write path** | Tabs with no data source, toggles with no consumer, screens with no route, engine functions with no caller, columns with no writer. No error is ever produced, because no call is ever made. | RC-H4 |
| **CRC-11** | **Two systems for one concept** | The newer, server-authoritative implementation was built and the older one was left running beside it. | RC-H5 |
| **CRC-12** | **Naive local time into `timestamptz`** | `DateTime.now().toIso8601String()` renders local time with no zone marker; Postgres reads it as UTC. Day-window reads are skewed in both directions. | RC-8 |
| **CRC-13** | **No mechanical gate** | Nothing automated watches the repository. No CI, no migration ledger, no artifact provenance, no rollback, no observability. **This is why every other root cause survived to be discovered by audit rather than by a red build.** | new (L, N) |
| **CRC-14** | **Fixtures and guards aimed at the wrong layer** | QA fixtures written against readers rather than the writer; 259 tests that execute a copy of the product; four guards written for a specific defect that cannot detect it because the defect moved one layer away. | RC-12 |

### 1.1 Dominance

| Root cause | Canonical findings | Share |
|---|---:|---:|
| CRC-03 Failure as value | 61 | 20% |
| CRC-13 No mechanical gate | 44 | 14% |
| CRC-10 Presentation ahead of write path | 38 | 12% |
| CRC-01 Schema-contract drift | 29 | 9% |
| CRC-07 Default-open / sweep-applied control | 24 | 8% |
| CRC-04 Fabricated success | 19 | 6% |
| CRC-11 Two systems for one concept | 18 | 6% |
| CRC-06 Label as identity | 17 | 5% |
| CRC-05 Degraded safety input | 15 | 5% |
| CRC-08 Caller-supplied identity | 14 | 5% |
| CRC-02 Undeclared payload contract | 13 | 4% |
| CRC-14 Guards at the wrong layer | 11 | 4% |
| CRC-12 Naive timestamps | 4 | 1% |
| CRC-09 Aggregate over per-user RLS | 3 | 1% |

**The single most important structural statement in this document:** CRC-13 is not
merely the largest cluster after the error contract — it is the **enabler of all the
others.** Phase 1 and Phase 2 closed 24 findings correctly and both were then partially
undone by a later migration that nothing was watching (§4). Until Wave 1 lands, every
remediation in this programme has the same half-life.

---

## 2. Canonical statuses

| Status | Meaning | Evidence required to enter it |
|---|---|---|
| `DISCOVERED` | Recorded, not yet triaged into a wave | a source report |
| `DUPLICATE` | Collapsed into a canonical ID | the alias map, §3 |
| `ALREADY_FIXED` | Closed before this reconciliation | see the evidence-state ladder in `QA_CLOSURE_STANDARD.md` |
| `FIX_IN_PROGRESS` | A named owner is mid-change in this tree | a working-tree diff |
| `BLOCKED_DECISION` | Cannot be built without product/business/clinical authority | a decision ID in `MASTER_PRODUCT_DECISIONS.md` |
| `BLOCKED_ENVIRONMENT` | Cannot be built or verified until an environment exists | an environment blocker ID, §8 |
| `READY_TO_REMEDIATE` | No blocker; assigned to a wave | a wave ID |
| `REMEDIATED` | Code/migration changed; not yet retested | FIXED IN CODE |
| `RETEST_REQUIRED` | Applied to QA; live assertion outstanding | FIXED ON QA |
| `VERIFIED_CLOSED` | Every required evidence state present | VERIFIED LIVE **and** VERIFIED IN CI |
| `DEFERRED` | Deliberately out of scope for this programme, with an owner and a date |
| `RELEASE_BLOCKER` | Not a code defect here; blocks a named release gate |

**As written at Wave 0, nothing in this registry was `VERIFIED_CLOSED`** — fifty-two
findings were `ALREADY_FIXED`, a weaker state, because the live suites that proved them
had not been re-run since the tree moved, and two of them were subsequently regressed.
**Update 2026-08-26 (§7.8):** Wave 1 put the suites in CI, and the green run at commit
`6d42b10` (271/271 live security across six suites) supplied the missing VERIFIED LIVE +
VERIFIED IN CI states. **23 rows are now `VERIFIED_CLOSED`** — exactly those whose class
evidence is fully present; every exclusion and its missing evidence is recorded in §7.8.

---

## 3. Deduplication map

118 aliases collapse into 61 canonical findings. **The alias must not be used as a
tracking key after this document.** Full list:

| Canonical | Aliases retired | Note |
|---|---|---|
| **I-CHK-01** | CON-01, EC-10 *(checkins half)*, E-CHK-01, M-02, H-21 *(evidence)* | `public.checkins` does not exist. Five workstreams, one defect |
| **I-LEG-03** | EC-10 *(coach_tips half)*, M-08 | `public.coach_tips` has never existed |
| **LRE-02** | REL-18, K-ENV-1, OBS-4-R4, N-05 | Three production-targeting harnesses. Found five times independently |
| **LRE-05** | REL-20, N-01 | No CI |
| **LRE-01** | REL-07 | `APP_ENV` defaults to production |
| **LRE-03** | HYG-01 *(partly — HYG-01 also covers untracked tests, now folded here)* | 20 untracked migrations |
| **LRE-04** | HYG-02, LRE-09 *(the 076 instance)* | 15 in-place-edited migrations |
| **LRE-34** | HYG-03, REL-34 | `supabase/.temp` tracked despite being ignored |
| **LRE-08** | REL-22 *(rollback half)*, LRE-10, LRE-11 | No rollback path; production history unreconciled |
| **LRE-06** | REL-23, M-B-2, D §7 D-1 *(infrastructure half)* | NestJS API has no deployment target |
| **LRE-07** | REL-33 | Android release signed with the debug keystore |
| **REL-04** | M-06, K-16, I-USR-01(b), I Q-8 | No account deletion, and the app states one exists |
| **REL-05** | D-K1, G D-1 | iOS purchase architecture |
| **K-01** | E-08, I-PAY-01, REL-24 *(idempotency half)*, N register #3 | Webhook re-grants session credits on redelivery |
| **I-WRK-01** | H-01, M-07, M R-2 | `workout_set_logs.created_at` does not exist |
| **I-COM-01** | H-02, M-04, M R-4 | Event registration writes `ticket_code`, then fabricates one |
| **I-COM-03** | H-03, M-09, M R-11 | `custom_exercises.approved_by` does not exist; approval always fails |
| **I-NUT-01** | E-13, E-NUT-04, F-J-03 | `ai-coaching-engine` reads `protein_g`/`carbs_g`/`fat_g` |
| **I-INT-01** | F-J-02 *(coaching-engine half)* | `user_profiles.goal` does not exist |
| **I-INT-02** | F-J-02 *(generator half)*, EC-02 *(input half)* | `ai-generate-workout` loses injuries in a query that fails on `goal`/`equipment` |
| **F-J-04** | E-12 | `recent()` orders five tables by a column they do not have |
| **F-J-12** | ENG-09, E-04 | `decision_traces` readable by every coach |
| **F-J-18/19** | E-11, E-CHK-07 | `ai-coach` ignores `target_client_id`; coach analyses describe the coach |
| **ENG-15** | F-J-15, M-01, ENV-01, D P-1, M B-1 | Zero Edge Functions deployed to QA |
| **ENG-17** | F-J-06, ENV-03, D P-6, J B-3 | Intelligence substrate unpopulated in QA |
| **ENG-16** | ENV-02, D P-5 | QA Vault `project_url` / `service_role_key` unset |
| **I-MIG-01** | A §8 *(ledger residual)* | 113–122 applied to QA, absent from `schema_migrations` |
| **CON-04** | Q-4, ENG-12, C A-5, J D-4, G §10 inherited, F-J-05 *(PAR-Q half)* | A high-risk PAR-Q constrains nothing |
| **E-NUT-05** | CON-08, F-J-26, F-J-05 *(allergy half)*, E Q-E5, J D-6 | Allergies never reach the meal-plan prompt |
| **CON-03** | Q-6, M §13 | `dietary_restrictions` — two serializers, one column, prod type unknown |
| **EC-03** | CON-02 | Onboarding marks itself complete after a failed save |
| **CON-06** | I-TYP-03, F-15 | ~52 naive-local timestamps |
| **E-NUT-01** | CON-09 | Barcode per-100 g logged as one serving |
| **CON-10** | F-08, F-09, F-13 *(as the parent record; F retains the three as children)* | Women's-health cycle computation |
| **E-09** | K-12, LRE-12, D P-3, REL-24 *(config half)* | No `[functions]` block; `verify_jwt` undeclared |
| **E-07** | K-21 | Caller-controlled redirect URLs, no allowlist |
| **K-28** | REL-35 | `Access-Control-Allow-Origin: '*'` on money-moving endpoints |
| **EC-01** | REL-26, LRE-27, LRE-28, EC-23 | No error-reporting sink or observability in any tier |
| **M-05** | REL-39, G D-6 | Integrations screen fakes a successful OAuth connection |
| **REL-08** | M-11, LRE-26 *(mobile half)* | No deep-link return path; reset and OAuth dead on iOS |
| **REL-06** | LRE-26 *(routes half)*, M-13 *(partly)* | `/qa-center` and `/mie-debugger` ship in release builds |
| **D §7 D-1** | E-NUT-06 *(backend half)*, REL-29 *(adjacent)* | Two parallel AI nutrition backends |
| **K-09** | H-12 *(capacity half)* | Coach plan capacity granted, never revoked, self-writable |
| **K-07** | M R-7 | A failed Stripe cancel still revokes local access, UI says "Switched to Free" |
| **EC-09** | M R-8 *(invite half)*, H §7 | Unverified writes reported as success |
| **EC-12** | M R-9 | Habit optimistic writes swallow failure, no rollback |
| **SEC-12** | D-04, R-03, H-12 *(demo half)* | `marketplace_coaches()` does not filter `is_demo` |
| **P-8** | K-ENV-2, K-ENV-3, K-ENV-4, M B-3 | No QA Stripe test-mode credentials, runbook or price ids |
| **P-11** | D §7 D-8 | No Anthropic spend cap in QA |
| **I-NOT-04** | H-19 | A conversation participant can rewrite the other party's message |
| **H-11** | H-15 *(dead-rule residue)* | Two "12 Circle Score" systems, one client-writable |
| *(19 further single-alias collapses)* | SEC-01↔D-01, SEC-02↔D-02, SEC-03↔D-03, SEC-04↔D-1D, SEC-08↔F-02↔Q-2, SEC-10↔D-05↔F-04, SEC-11↔D-06↔R-02, WRK-01/02↔WKA-01/02↔RC-B, WRK-03/04/05↔WKA-03↔RC-A, WRK-06↔ENG-03 *(engine half)*, WRK-07↔EC-G1, CON-05↔E-NUT-17↔SEC-04 *(nutrition arm)*, ENG-11↔C §3 layer 11, EC-10↔I-CHK-01/I-LEG-03, EC-02↔CRC-05 parent, N-07↔EC-05, H-20↔E-CHK-06, I-USR-01(a)↔I-WRK-03↔Q-7, LRE-42↔LRE-02 | recorded, individually unremarkable |

### 3.1 Findings the reports **contradict each other** on — resolved here

| Item | Disagreement | Resolution |
|---|---|---|
| `/checkins` route | Master reconciliation called it "a working check-in screen, orphaned". Workstream E found it is an **appointments calendar** that queries `coaching_calls`, reached from two entry points | **E is correct.** The master reading was wrong. The genuinely orphaned code is the *service layer* — `submitWeeklyCheckin` and ten sibling symbols have zero callers. Recorded as **E-CHK-05** + **E-CHK-02**, and the master's phrasing is retired |
| `ai_adjust_nutrition` "incorrect schema reference" | Reported three times, **not reproduced** three times | **NOT REPRODUCED — closed as a false positive.** `weekly_checkins.weight_kg` and `created_at` both exist. The real defect of that shape is `I-NUT-01` (`ai-coaching-engine`), and a *second* one is `I-NUT-02` (`user_profiles.goal` inside the same function). Do not re-open the original phrasing |
| `weekly_checkins` RLS | Phase 1 marked D-03 closed; E flagged that the closure was inferred, not probed | **E is right to flag it.** 114+118 are source-correct and `d03` asserts 27/27 — but that suite has not run since. Status stays `ALREADY_FIXED`, **not** `VERIFIED_CLOSED`, pending Wave 1's CI |
| `dietary_restrictions` column type | Code comment asserts `text[]`; QA probe says `text` | QA is `text`. **Production is unverified and must be confirmed before rollout** (Q-6). The forward migration must converge from either starting type |
| K-04 reproduction payload | K published a repro including `ticket_code` | **H is correct:** `ticket_code` does not exist, so K's payload fails rather than succeeds. Drop that field from the repro. The vulnerability is real; the published proof was wrong |
| Test baseline | 514 / 591 / 623 / 667 / 690 / 699 quoted across reports | All are snapshots of a concurrently-edited tree. **730 passed / 9 skipped / 0 failed** is the Wave 0 baseline, measured this session |

---

## 4. Already fixed, regressed, and not reproduced

### 4.1 `ALREADY_FIXED` — 52 findings. Do not re-open.

> **2026-08-26:** 13 of these rows (SEC-01, SEC-02, SEC-03, SEC-05, SEC-06, SEC-07,
> SEC-10, F-01, F-03, F-05, F-06, F-07, F-08) are promoted to `VERIFIED_CLOSED` on the
> live CI evidence at `6d42b10` — see **§7.8** for the promotion record, the rows that
> deliberately stay, and each row's remaining evidence gap. The tables below are the
> historical Wave 0 record and are not rewritten.

**Phase 1 (security), closed by migrations 113–118 — evidence: 270/270 live assertions**

| Finding | What closed it |
|---|---|
| SEC-01 / D-01 · `coach_client_relationships` had no RLS | 113 — RLS + asymmetric activation model + `enforce_relationship_integrity` |
| SEC-02 / D-02 · role self-escalation | 115 — `enforce_profile_privilege` trigger pins 7 privilege columns; role vocabulary CHECK; `admin_set_user_role()` |
| SEC-03 / D-03 · `weekly_checkins` had no RLS | 114 — RLS + `enforce_checkin_authorship` split |
| SEC-04 / D-1D · 11 subject-scoped RPCs trusting a caller uuid | 116 — `can_act_for` / `can_act_on_program`; 13 engine functions renamed `*_engine` behind authorized wrappers |
| SEC-05 · `anon` could execute 98 of 100 functions | 116 — schema-wide `REVOKE` + a 50-name allowlist |
| SEC-06 / SEC-07 · AI and MIE substrate tables had no RLS | 117 |
| SEC-09 · 73 definer functions with a mutable `search_path` | 116 + 118 → 0 |
| SEC-10 / D-05 / F-04 · `coach_availability` `USING (true)` to PUBLIC | 118 |
| SEC-11 / D-06 / R-02 · client could rewrite a completed session | 120 — `workout_set_logs_protect_history`, `workout_sessions_terminal_status` |
| Q-4 client-computed PAR-Q risk | 115 — `derive_parq_risk` + `apply_parq_risk` made the classification server-authoritative ⚠ *see §4.2* |
| F-01 · `coach_client_workout_stats` unscoped view | 118 |
| F-03 · `notifications` INSERT `WITH CHECK (true)` | 118 + `may_notify()` |
| F-05, F-06, F-07, F-08 · blanket policies, no-`TO` policies, anon grants, invoker search_path | 118 |
| SEC-08 / F-02 / Q-2 · `public.workouts` had no RLS | 118 — made a read-only catalog rather than dropped, so retirement stays an open data-model decision |

**Phase 2 (workout contract), closed by 119–121 — evidence: 20/20 live assertions + 129 behavioural tests**

| Finding | What closed it |
|---|---|
| WRK-01 / WKA-01 · two live set-identity keys | 120 retires 051's ordinal unique index; `(session_id, set_id)` is the only key |
| WRK-02 / WKA-02 · swap inherits set identities → 23505 | `WorkoutExercise.replacedBy` mints fresh identities; uniqueness moved to workout scope |
| WRK-03/04/05 / WKA-03 · untyped `program_workouts.exercises`; String reps; 0 kg; lost rest | 119 — canonical prescription contract, canonicalizing trigger, `CHECK`, `weight_kg` nullable with `null ≠ 0` |
| WRK-06 · engine materialized no prescription | 119 — `materialize_program_week` emits `weight_kg: null` and **raises** rather than writing an empty workout |
| WRK-07 · workout providers returned `[]` on error | Phase 2 — `workout_provider.dart` now contains no `catch`; pinned by `EC-G1` ⚠ *the swallow moved down a layer — EC-11* |
| WKA-04 · "End Workout" left an orphaned `in_progress` row | Phase 2 — honest two-choice exit; ended sessions are `abandoned` ⚠ *resurrected through the error path — EC-05* |
| OBS-4 · duplicate generated day titles | 121 — `plan_day_titles()` restored as one authority, applied after 077's bias; backfill scoped to `coach_id IS NULL` |
| Session determinism, warm-up ack, set identity column, cursor, restoration seating, client-side completed-set immutability | 103, 105, 106, 107, 108 + `workout_restoration.dart` |
| OBS-4-R1/R2/R3 · 121/119/120 dropped pinned `search_path` on 14 functions; 4 trigger functions born `EXECUTE TO PUBLIC` | 122 |

**Other closures**

| Finding | Status |
|---|---|
| Community/messaging display-name reads | Closed — `public_profiles`, `conversation_participant_profiles` ⚠ *five client surfaces were never repointed — H-06* |
| Cross-project cron URLs (prod URL in 076/080) | Closed **in the working tree only** — Vault-resolved, fail-closed. ⚠ *uncommitted; see LRE-03/LRE-04* |
| Coach rating written by the client | Closed by design — a no-op behind 045's trigger and 115's PINNED class. Not a finding |
| "514 vs working-tree test count" | Not a defect |
| Memory note "RLS coach policies unfixed" | **Outdated** — superseded by 113–118 on QA. Production remains unpatched (REL-21) |

### 4.2 ⚠ `REGRESSION` — closed work that a later change undid. **Five findings. This is the most important section of this document.**

Every one of these was introduced by a *correct* later change that nobody was watching.
They are the direct, measurable cost of CRC-13.

| ID | What regressed | Introduced by | Mechanism | Sev |
|---|---|---|---|---|
| **F-J-01** | SEC-04's authorization guard on `materialize_program_week` | migration **119** | 116 renamed the engine body to `*_engine` and published a `can_act_on_program` wrapper under the public name. `119:403` re-created the public name as a **bare `SECURITY DEFINER` body** and `119:483` re-granted `EXECUTE` to `authenticated`. `122` repinned `search_path` with `ALTER FUNCTION` and never touched the body. **116's own header warned about exactly this escape.** Live: an unrelated authenticated client reaches the engine against another coach's program; with a real week number it `DELETE`s and rewrites that week's `program_workouts` | **P0** |
| **F-J-17** | Phase 1's PAR-Q server-authority fix (Q-4 / SEC-023) | migration **115** itself | `derive_parq_risk` appends three flags as **untyped literals** to a `text[]`. Postgres resolves `anyarray \|\| anyarray` and fails with `22P02 malformed array literal`. `apply_parq_risk` is a `BEFORE INSERT OR UPDATE` trigger, so the throw rejects the whole profile write. **A member cannot declare an injury, a pregnancy or a postpartum state.** The fix that made risk server-authoritative made risk unrecordable | **P0** |
| **F-J-07** | `build_workout`'s under-recovery rule | migration **089** (pre-existing, surfaced by J) | Identical shape. `recovery = 60` returns 200; `recovery = 59` returns `22P02`. **The single rule that protects an under-recovered member is the only rule in the function that cannot run** | **P0** |
| **EC-05 / N-07** | WKA-04 (orphaned `in_progress` session), closed by Phase 2 through the happy path | pre-existing error path, unchanged by Phase 2 | `active_workout_screen.dart:611-619` wraps `completeSession` in `catch (_) {}` and shows the celebration regardless; `:608` awaits `logWorkout`, whose whole body is `catch (_) {}`. The session stays `in_progress`, the Resume banner keeps offering a finished workout, and `workout_sessions_one_active_per_user` then constrains the next one. `EC-G1` passes because it does not read this file | **P1** |
| **EC-11** | WRK-07 (provider-layer swallow), closed by Phase 2 | pre-existing service layer | The swallow **moved down a layer rather than away**. `WorkoutService` holds 13 swallow sites; nine providers Phase 2 did not name are thin wrappers over them and are therefore error-blind by construction. `getCompletionRate() → 0` is a **fabricated** adherence figure shown to a coach | **P1** |

**The class fix, and it is mandatory:** a standing test asserting that no function
carrying an authorization wrapper, a `search_path` pin or a security trigger may be
redefined by a later migration without carrying them forward. `SEC-027` already does
exactly this for one function (`generate_client_plan` / `plan_day_titles`) and is the
strongest guard in the tree. Generalise it. **Tracked as `I-MIG-03` and scheduled in
Wave 2; it is the only reason to believe the next Phase-1-equivalent will hold.**

### 4.3 `NOT_REPRODUCED` — closed as false positives

| Claim | Verdict |
|---|---|
| `ai_adjust_nutrition` references an incorrect schema | **Not reproduced, three times independently.** Both columns exist. The real instances are I-NUT-01 and I-NUT-02 |
| `resumePosition` is corrupt | **Not a defect in itself.** Its inputs were — a stale cursor after a swap now misses cleanly (RC-B, closed) |
| A working `/checkins` screen exists but is orphaned | **Materially wrong** — see §3.1 |
| Migration 076's `created_at` schema defect | **Already corrected in the working tree** (`B2-6`). ⚠ *the correction is an in-place edit and does not self-apply — LRE-04* |
| Cross-tenant read/write in nutrition or check-in | **Not reproduced anywhere.** The one reachable subject-uuid surface (`ai-coach`'s `target_client_id`) fails **closed** |

---

## 5. Reconciliation summary — required table

Canonical findings only. Aliases excluded. `Fixed` counts §4.1 entries attributed to that
domain; the five §4.2 regressions are counted as **open**, in their domain, at their
current severity.

| Domain | Findings | P0 | P1 | P2 | P3 | Fixed | Blocked | Ready | Release blocker |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Security & Authorization | 34 | 3 | 5 | 8 | 4 | 14 | 2 | 15 | 3 |
| Workout & Session | 21 | 0 | 4 | 5 | 3 | 9 | 1 | 11 | 0 |
| Error Contract | 26 | 4 | 10 | 8 | 4 | 0 | 1 | 25 | 4 |
| AI / Intelligence Engine | 44 | 6 | 17 | 15 | 6 | 0 | 9 | 29 | 5 |
| Edge Functions | 20 | 2 | 3 | 10 | 5 | 0 | 5 | 15 | 2 |
| Nutrition | 19 | 1 | 6 | 9 | 3 | 0 | 5 | 14 | 1 |
| Check-In | 12 | 2 | 3 | 4 | 3 | 0 | 6 | 6 | 2 |
| Women's Health | 25 | 0 | 6 | 12 | 7 | 1 | 5 | 20 | 0 |
| Billing & Entitlements | 35 | 4 | 14 | 12 | 5 | 0 | 10 | 25 | 5 |
| Release & Environment | 46 | 12 | 18 | 11 | 5 | 0 | 6 | 40 | 24 |
| UI Reachability | 13 | 2 | 4 | 5 | 2 | 0 | 5 | 8 | 2 |
| Product Integrity | 21 | 0 | 5 | 6 | 10 | 3 | 5 | 16 | 3 |
| Data Contract | 33 | 5 | 12 | 12 | 4 | 0 | 8 | 25 | 2 |
| Testing | 11 | 1 | 4 | 4 | 2 | 0 | 3 | 8 | 3 |
| **Total** | **310** | **42** | **111** | **121** | **63** | **52** | **71** | **257** | **56** |

*Reading notes.* `Fixed` (52) and `Ready`/`Blocked` overlap by design: a fixed finding is
neither ready nor blocked, so `Ready + Blocked + Fixed` ≈ 380 > 310 because 70 findings
are counted in both `Blocked` and `Ready` — they are ready in part and blocked in part
(typically a mechanical half plus a decision-gated half). Every such split is stated in
the finding's own row. `Release blocker` is a **gate attachment**, not a severity: a P3
that blocks App Review is still a release blocker.

**Severity is assigned by impact, not by gate.** Where this registry departs from a
source report's rating, the deviation is recorded in the row. The two systematic
departures are: (a) Workstream G's iOS **build** blockers are rated P1 here, not P0 —
they block Gate 3 and nothing else, and rating them P0 alongside "AI prescribes without
knowing the injuries" destroys the meaning of the scale; (b) three findings rated P1 by
their owning workstream are raised to **P0** because a later workstream proved a safety
consequence (F-J-17, F-J-07, I-INT-02).

---

## 6. P0 register — full field set

Forty-two findings. Each is stated with the complete field set required by the
programme brief. **These are the findings that gate the plan.**

---

### SEC-R1 · `materialize_program_week` lost its authorization guard
`F-J-01` · **P0** · `READY_TO_REMEDIATE` · Wave 2

| Field | Value |
|---|---|
| **Source** | J (live) · re-verified **SRC-V** this session |
| **Root cause** | CRC-07 — a control applied by a sweep, dropped by the next definition |
| **Layer** | database / RPC |
| **Affected** | `supabase/migrations/119_workout_prescription_contract.sql:403,483`; `116_rpc_execution_security.sql:326,375`; `122_repin_function_search_path.sql` |
| **Security impact** | Any authenticated account reaches a `SECURITY DEFINER` engine body against **any** coach's program. With a real week number the call `DELETE`s and rewrites that week's `program_workouts`. All four sibling functions correctly return 403 — this one alone is open |
| **User impact** | A coach's programming for a real client can be destroyed and rewritten by an unrelated account |
| **Business impact** | Re-opens a P0 that Phase 1 closed and certified. Undermines the evidence value of the Phase 1 sign-off |
| **Dependencies** | None to fix. Blocks nothing, but must land before any Wave 5 engine work re-exercises this path |
| **Decision** | none |
| **Remediation** | Forward migration: restore the `can_act_on_program` wrapper over `materialize_program_week_engine`, `SET search_path = public, pg_temp`, re-`REVOKE` from the engine name. **Do not** edit 119 |
| **Parallel** | **YES** — one new migration, disjoint from every other file |
| **Owner** | database / security |
| **Tests** | Extend `supabase/tests/security/d04-rpc-execution.mjs` to assert **all five** 116 wrappers as a class, not individually. Add `I-MIG-03`'s standing source guard (§4.2) so a future `CREATE OR REPLACE` cannot repeat this |
| **Live QA** | An unrelated authenticated client → 403 on a program they do not own; the owning coach → 200; `service_role` → 200 |
| **Gate** | Gate 2 |
| **Evidence** | BEFORE: J's live probe, unrelated client reaches the body while 4 siblings 403. Re-derived from source this session |

---

### SEC-R2 · The PAR-Q classifier throws — a member cannot declare an injury or a pregnancy
`F-J-17` · **P0** · `READY_TO_REMEDIATE` · Wave 2

| Field | Value |
|---|---|
| **Source** | J (live) · re-verified **SRC-V** |
| **Root cause** | CRC-05 + CRC-07 |
| **Layer** | database (trigger) |
| **Affected** | `115_profile_privilege_boundary.sql:142,143,145` (`v_flags := v_flags \|\| '<literal>'`), `:171` (`apply_parq_risk` `BEFORE INSERT OR UPDATE`) |
| **Security impact** | None directly — it fails closed by throwing |
| **User impact** | **`PATCH user_profiles {has_injuries:true, injury_locations:'left knee'}` is rejected with `22P02`.** Onboarding intake writes exactly these columns, so an injured, pregnant or postpartum member cannot complete onboarding at all — and CON-02/EC-03 then marks them onboarded with the data discarded |
| **Business impact** | The three highest-consequence safety declarations the product collects are unrecordable |
| **Dependencies** | **Blocks** every downstream safety finding (CON-04, E-NUT-05, F-J-05) — there is no point wiring a constraint to data that cannot be written. **Must precede Wave 5** |
| **Decision** | none — the cast is a defect fix, not a policy choice |
| **Remediation** | Cast the three literals to `::text` in a forward migration; backfill rows whose flags were silently never written. Grep the whole migration set for the same `array \|\| untyped-literal` shape |
| **Parallel** | **YES** — same migration as SEC-R1/SEC-R3 |
| **Owner** | database |
| **Tests** | A live assertion per flag: pregnancy / postpartum / injury each produce the flag and a `moderate`-or-higher level. Extend `SEC-023` (which pins the Dart and SQL classifiers in step) to assert the classifier **executes** |
| **Live QA** | The three writes succeed and produce the expected `risk_flags` |
| **Gate** | Gate 1 |
| **Evidence** | BEFORE: `22P02 malformed array literal: "active_injuries"`, J live |

---

### SEC-R3 · `build_workout` throws whenever recovery is below the deload threshold
`F-J-07` · **P0** · `READY_TO_REMEDIATE` · Wave 2

| Field | Value |
|---|---|
| **Source** | J (live) · re-verified **SRC-V** |
| **Root cause** | CRC-05 |
| **Layer** | deterministic engine |
| **Affected** | `089_mie_decision_intelligence.sql:51` (`rules text[]`), `:55` |
| **User impact** | `recovery = 60` → 200; `recovery = 59` → `22P02`. **The only rule that protects an under-recovered member is the only rule in the function that cannot run** |
| **Business impact** | Product bible §3 — *"Injury signals and low recovery override progression"* — is unenforceable |
| **Dependencies** | Blocks Wave 5 engine verification |
| **Decision** | none |
| **Remediation** | `rules := rules \|\| 'RECOVERY_REDUCTION'::text` in a forward migration |
| **Parallel** | **YES** |
| **Owner** | database |
| **Tests** | `supabase/tests/ai/` assertion at recovery 59, 60, 61 |
| **Live QA** | `build_workout({recovery:59})` returns 200 with `RECOVERY_REDUCTION` in `rules` |
| **Gate** | Gate 2 |

---

### ENV-1 · The entire remediation programme is untracked
`LRE-03` · **P0** · ✅ `VERIFIED_CLOSED` 2026-08-26 *(W1-T1 custody + migration-hygiene guard green in CI at `6d42b10`; zero untracked non-ignored engineering files)* · Wave 1

| Field | Value |
|---|---|
| **Source** | L · re-verified **SRC-V** |
| **Root cause** | CRC-13 |
| **Layer** | repository |
| **Affected** | 20 untracked migrations (`000`, `104`–`122`) — **every Phase 1 security migration and every Phase 2 contract migration**; 22 untracked test files including all six live security suites' Dart guards; `workout_restoration.dart` and `workout_contract.dart`, both **production source the app does not compile without**; and **all 18 A–N reports** |
| **Security impact** | The complete P0 security remediation is one `git clean -fd` from non-existence. It cannot be reviewed, deployed from CI, or applied to production, because it exists nowhere but this working tree |
| **User impact** | none today |
| **Business impact** | Total loss of the programme's output on any tree accident |
| **Dependencies** | **Hard prerequisite for every other task in the programme.** Several Wave 1 tasks edit files that are currently modified-but-uncommitted; without a clean base they cannot be reviewed or reverted independently |
| **Decision** | none |
| **Remediation** | Commit in reviewable slices: (1) migrations 000+104–122, (2) test files, (3) the two `lib/` files, (4) docs. Nothing is deleted; nothing is squashed |
| **Parallel** | **NO — sequential, and it went first, alone** |
| **Closure evidence** | **FIXED IN CODE.** 147 files in five commits — `f8f4490`, `2b3d857`, `99492df`, `11fbc6a`, `8e47f07`. Working tree clean; 0 untracked non-ignored files; suites at baseline (730/9/0, 58+6). Full record: [`WORKING_TREE_CUSTODY_MANIFEST.md`](WORKING_TREE_CUSTODY_MANIFEST.md) and progress board §12. **Not `VERIFIED_CLOSED`** — its guard (Gate 0 row 0.7, `git status --porcelain supabase/migrations` empty in CI) does not exist until ENV-6 lands |
| **Owner** | release engineering |
| **Tests** | `git status --porcelain supabase/migrations` is empty, asserted in CI |
| **Live QA** | n/a |
| **Gate** | Gate 0 |

---

### ENV-2 · 15 already-applied migrations were edited in place
`LRE-04` (= HYG-02, LRE-09) · **P0** · `READY_TO_REMEDIATE` · Wave 1

| Field | Value |
|---|---|
| **Source** | L, master · re-verified **SRC-V** |
| **Root cause** | CRC-13 |
| **Affected** | `001, 002, 003, 009, 076, 080, 083, 084, 086, 087, 090, 091, 096, 097, 102` |
| **Security impact** | 076's cross-environment cron target — the fix that stopped a QA project POSTing to **production** Edge Functions with a service-role bearer — is an in-place edit. Any environment that already ran the old 076 still has the production target |
| **User impact** | Production silently retains every defect these edits fix, including 076's `created_at`→`started_at` bug, which raises on every scheduled run once Vault is configured |
| **Business impact** | Production cannot receive the corrections at all. This is the reason the security rollout is not yet writable |
| **Dependencies** | Requires ENV-1. **Blocks** LRE-08 → the production rollout chain |
| **Decision** | none |
| **Remediation** | Enumerate the semantic delta of each of the 15 and emit **one idempotent forward migration `123`** carrying every one. Keep the in-place edits for from-empty replay; never rely on them for promotion. Master's HYG-02 flagged this for 076 only — it applies to all fifteen |
| **Parallel** | **NO** — one owner must do the delta enumeration; splitting it guarantees a missed delta |
| **Owner** | database |
| **Tests** | A guard asserting no tracked migration is modified relative to its merge-base |
| **Live QA** | Replay 123 twice against QA; no-op the second time |
| **Gate** | Gate 0 → G-04 |

---

### ENV-3 · Migrations 113–122 are applied to QA but absent from the migration ledger
`I-MIG-01` · **P0** · `REMEDIATED` *(W1-T3 executed on QA 2026-08-25 — the ledger repair below is complete and live-verified; `VERIFIED_CLOSED` withheld, see the dated block)* · Wave 1

| Field | Value |
|---|---|
| **Source** | I, A |
| **Root cause** | CRC-13 |
| **Affected** | `supabase_migrations.schema_migrations` on QA stops at **112** |
| **Business impact** | QA cannot be reasoned about from its ledger. `supabase db push` would re-run all ten. **All ten were verified idempotent by I**, so a push today would be a no-op *in effect* — that is a property of how they were written, not of the process |
| **Dependencies** | Requires ENV-1 |
| **Remediation** | Insert the ten version rows into `schema_migrations` on **QA only**, after confirming the linked project is QA. Never touch production's ledger without the §9 rollout plan |
| **Parallel** | **YES**, after ENV-1 |
| **Tests** | A CI check that the ledger's max version equals the highest migration filename |
| **Live QA** | `supabase migration list --linked` shows local and remote in step |
| **Gate** | G-03 → G-09 |

**W1-T3 · QA ledger repair — executed 2026-08-25.** Owner-authorized; performed by the
product owner from the local Supabase CLI, because the orchestration session has no
network egress to the QA project and holds no QA credential (recorded at the time as
BLOCKED rather than worked around, per governance §5).

| | |
|---|---|
| **Target** | `eyqtldjqpgpljlqvpowh` — *12Circle QA*. Independently confirmed before the write from five agreeing local sources (`.temp/project-ref`, `.temp/linked-project.json`, `config.toml` `project_id`, `dart_defines/qa.json`, and `supabase/scripts/qa-db-reset.sh --check-only`), not from a variable name. Production `nxdbooufqzkpslkcogxc` was **not** the target and was not contacted |
| **Operation** | `supabase migration repair --status applied 113 114 115 116 117 118 119 120 121 122 --linked` — a ledger write only. **No migration was executed**, no `db push` was run, and no schema object changed |
| **Observed transition** | `113`–`122`: Local-only → **Local + Remote** · `123`: Local-only → **Local-only** (unchanged). Before/after captured as `/tmp/w1t3-before.txt` and `/tmp/w1t3-after.txt`; the diff contains exactly ten changed rows, versions 113–122, and no other migration-history row changed |
| **Migration 123** | **Deliberately excluded and still unapplied.** It is committed (`24187bf`) and locally validated only. Marking it applied would cause a later `supabase db push` to skip it, so the ENV-2 forward carry would never reach any environment. No claim is made here that 123's objects exist on QA |
| **Evidence state** | FIXED ON QA · VERIFIED LIVE (the row's own *Live QA* line — `migration list --linked` now shows 113–122 in step) |
| **Why not `VERIFIED_CLOSED`** | The closure standard's release/environment class requires **VERIFIED IN CI**, and this row's own *Tests* field names the specific check — "a CI check that the ledger's max version equals the highest migration filename". **That check does not exist.** Until it does, this row stays `REMEDIATED` |
| **Open question, not resolved here** | That prescribed check, as literally worded, would be **red today by design**: the ledger's max version is `122` while the highest migration filename is `123`, precisely because 123 is committed-but-unapplied. Its predicate therefore needs an owner ruling (compare against applied-and-intended, or gate it on the pending application of 123) before it can be implemented. Recorded, not decided |

**Amendment, 2026-08-25 — the Tests field, corrected and expanded.** The original
wording above ("a CI check that the ledger's max version equals the highest
migration filename") is preserved as written and is **superseded**, not deleted.
It is a specification defect: a max cannot see a hole in the middle of the
sequence; it asserts *authored == applied*, which this programme violates by
design (102 is withheld from production, 123 is committed-but-unapplied); and it
is environment-blind, so it cannot hold for QA and production at once during any
staged rollout. Read literally it is red today for a correct reason.

`RELEASE_GATES.md` row **1.2** already states the property properly — *"every
migration **applied to QA** is recorded in `schema_migrations`"* — and row 0.9
owns migration numbering. The corrected contract is those two, made mechanical:

| Term | Source of truth |
|---|---|
| `authored` | the migration files in `supabase/migrations/` |
| `declared` | `supabase/expected_applied.json` — per environment: the applied frontier, plus deliberately `pending` / `excluded` versions, each with a reason and the gate that releases it |
| `observed` | `supabase_migrations.schema_migrations`, the only authority on what is applied |

**Closure of ENV-3 requires all of:**

1. authored migration inventory validation — filenames, no duplicate numbers,
   and a contiguous sequence (gate 0.9, owned by `check-migration-hygiene.sh`);
2. an environment-specific expected-state declaration in which every authored
   migration is classified and every deviation carries a reason and a gate;
3. a live comparison of `declared` against `schema_migrations`, per environment;
4. detection of **missing expected migrations** (`declared − observed`);
5. detection of **unexpected applied migrations** (`observed − declared`) — the
   signal that catches an out-of-band apply;
6. detection of **stale ledger rows** (`observed − authored`) — a row whose file
   no longer exists means history was rewritten or a migration deleted;
7. detection of **skipped migration versions** — a hole in either the authored
   sequence or the applied set below the frontier;
8. **CI execution of the live ledger check**. A check that has never run in CI
   is not a gate (closure standard §4).

**Explicitly: a committed-but-pending migration is never inserted into
`schema_migrations` to satisfy this check.** Migration 123 is declared `pending`
for QA and its ledger row is created only by its actual, separately authorized
application. Writing it early would make a later `supabase db push` skip it, and
the ENV-2 forward carry would silently never reach any environment.

**Status after this amendment: `REMEDIATED`, unchanged.** Items 1, 2 and the
static half of 7 are implemented and run in CI's `static-guards` job
(`check-migration-hygiene.sh` contiguity + `supabase/scripts/check-migration-manifest.mjs`).
Items 3–6, the applied-set half of 7, and item 8 are the **live half**, which is
not implemented: it needs a QA database credential in CI, the same blocker as
FG-1 and FG-2. `VERIFIED_CLOSED` is unavailable until that half executes.

---

### ENV-4 · `APP_ENV` defaults to production
`LRE-01` (= REL-07) · **P0** · ✅ `VERIFIED_CLOSED` 2026-08-26 *(Wave 1 batch task 2, [`WAVE_1_BATCH_CLOSURE.md`](WAVE_1_BATCH_CLOSURE.md); CI at `6d42b10`: ENV-4 static guard + env-ratchet tests + QA-bundle allowlist scan all green — see §7.8)* · Wave 1

| Field | Value |
|---|---|
| **Source** | L, G · re-verified **SRC-V** (`app_env.dart:151`) |
| **Root cause** | CRC-13 |
| **Security impact** | Any `flutter run`, `flutter build`, `flutter test` or IDE launch without `--dart-define-from-file` connects to **production**, using the anon and Stripe keys baked in at `app_env.dart:117-121`. **This is the highest-probability contamination path in the repository, because it requires no mistake — only an omission** |
| **Aggravation** | `qa_environment_isolation_test.dart` ENV-012 currently *codifies this as intended* ("the default run proves it resolves to production") |
| **Remediation** | Default `APP_ENV` to `dev`; make an absent `APP_ENV` a hard failure in a release build; move the prod URL/key into `dart_defines/prod.json` and delete `_prodSupabaseUrl`/`_prodSupabaseAnonKey`/`_prodStripePublishableKey`. **Invert ENV-012** to prove the default is *not* production |
| **Parallel** | **YES** — touches `app_env.dart`, `dart_defines/*`, and two test files, all disjoint from other Wave 1 tasks |
| **Tests** | `env_config_test.dart`: empty `APP_ENV` throws. Inverted ENV-012 |
| **Gate** | G-01 |

---

### ENV-5 · Three QA harnesses are hardcoded to production and perform destructive writes
`LRE-02` (= REL-18, K-ENV-1, OBS-4-R4, N-05) · **P0** · ✅ `VERIFIED_CLOSED` 2026-08-26 *(Wave 1 batch task 3 — shared `tool/qa_target.dart` allowlist refusal, no defaults; CI at `6d42b10`: harness guard tests + `--untracked` production-ref guard green — see §7.8)* · Wave 1

| Field | Value |
|---|---|
| **Source** | L, G, K, A, N — **found five times independently** · re-verified **SRC-V** |
| **Affected** | `tool/live_integration_test.dart:15`, `tool/qa_self_guided.dart:22`, `tool/qa_entitlements.dart:27` |
| **Security impact** | 20+ `DELETE` calls between them; two delete an `auth.users` row via the admin API when `SERVICE_ROLE_KEY` is set. `qa_self_guided.dart:200` calls `generate_client_plan()`, which **supersedes assignments, deletes the caller's self-generated programs and writes new ones**. Their own headers call the target "the real Supabase **dev** instance" |
| **Business impact** | An operator running a script named `qa_entitlements` — the repository's own "Entitlement & Subscription QA certification harness" — signs up users and writes subscription rows **into production**. Workstream K could not run the one tool built for its mandate |
| **Remediation** | Repoint all three at `QA_URL`/`QA_ANON` with **no default**, and copy `supabase/tests/security/lib.mjs`'s production-ref refusal verbatim into each. Add a repo-wide CI guard failing on any occurrence of the production ref outside `app_env.dart`, the keep-alive workflow, and tests asserting *about* it |
| **Parallel** | **YES** |
| **Tests** | `harness_environment_guard_test.dart` ENV-020…022 already ratchet this — flip them from "records the contamination" to "asserts its absence" |
| **Gate** | G-02 |

---

### ENV-6 · No CI, and the only workflow contacts production
`LRE-05` (= REL-20, N-01) · **P0** · `REMEDIATED` *(2026-08-24, Wave 1 batch task 4 — `ci.yml` + three guard scripts exist in-tree; the workflow has **not yet executed** on any push/PR, so this row cannot advance past REMEDIATED until the branch is pushed; see [`WAVE_1_BATCH_CLOSURE.md`](WAVE_1_BATCH_CLOSURE.md))* · Wave 1

| Field | Value |
|---|---|
| **Source** | L, G, N · re-verified **SRC-V** |
| **Business impact** | 763+ executable tests, 188 live authorization assertions, 32 live workout assertions, and every static guard in the tree protect **only a developer who remembers to run them**. `npm test`, `test:security`, `test:ai`, `test:contract`, `check:web-secrets` all exist and are all manual. The live security suite — the best test asset in the repository, written to fail against the pre-remediation database — **has never run in CI and did not run in any workstream session** |
| **Dependencies** | Requires ENV-1 (there is nothing to gate until the tree is committed) |
| **Remediation** | One `ci.yml`: `flutter analyze`, `flutter test`, `npm run test:api`, `npm run check:web-secrets` on a QA web build, plus the migration-hygiene and production-ref guards. A second, environment-scoped job runs `test:security` / `test:ai` / `test:contract` against QA behind a repository secret |
| **Parallel** | **YES**, after ENV-1 |
| **Gate** | G-05 · **this is the single highest-leverage change in the programme** |

---

### ENV-7 · Zero Edge Functions are deployed to QA
`ENG-15` (= F-J-15, M-01, ENV-01) · **P0** · `BLOCKED_ENVIRONMENT` · Wave 5

All 19 functions return `404 NOT_FOUND` (**LIVE**, three workstreams). Every AI surface,
every payment path, invites and enrichment are dead on QA. `supabase secrets list`
returns `{"secrets":[]}`. **Deliberately not remediated before Wave 5:** deploying now
converts a visibly dead system into an invisibly wrong one, because every input defect
below (CRC-01, CRC-05) currently produces confident output with no error anywhere.
Sequencing per Workstream D §6 and J §11. **Gate:** Gate 2 · **Decision:** D-8 (spend cap), D-2 (nutrition backend).

---

### ENV-8 · The NestJS API has no deployment target in any environment
`LRE-06` (= REL-23, M B-2) · **P0** · `BLOCKED_DECISION` · Wave 1/5

No Dockerfile, compose file, `fly.toml`, `vercel.json`, `render.yaml` or Terraform
anywhere. `API_BASE_URL` is empty in `qa.json`, `prod.json` **and** the prod default
table. The AI Nutrition Coach — the flagship AI surface, and the best-tested layer in
the repository — is non-functional in every buildable environment, and the Anthropic
key's only sanctioned home is a process that runs nowhere. **Blocked on D-2** (platform,
cost, and whether the parallel Firebase/passport auth stack stays). **Gate:** G-06.

---

### ENV-9 · No database rollback path
`LRE-08` (= REL-22) · **P0** · `BLOCKED_DECISION` · Wave 1

Zero down migrations across 123 files; no documented or rehearsed restore; free tier
implies no PITR. The security rollout — the highest-value change pending — is a one-way
door, and migration 102's own header documents that it breaks older clients on the way
in. **Blocked on D-3** (pay for PITR, or accept forward-only). **Gate:** G-08 → G-09.

---

### ENV-10 · Android release builds are signed with the debug keystore
`LRE-07` (= REL-33) · **P0** · `READY_TO_REMEDIATE` · Wave 8

`build.gradle.kts:32` — `signingConfig = signingConfigs.getByName("debug")`, Flutter's
scaffold TODO still above it. If a debug-signed build ever reached a distribution
channel the signing identity is a well-known key that cannot be rotated; the app would
have to be republished under a new package name. **Gate:** G-07.

---

### ENV-11 · Production carries the unpatched P0 security defects
`REL-21` · **P0** · `RELEASE_BLOCKER` · Wave 1 output, Wave 10 execution

SEC-01…SEC-05 are properties of the migration source and are therefore live in
production. 113–122 close them **on QA only**. Compounding: by migration 083's own
header, `083/084/086/087/090/091/097/099` were *never applied in any environment* before
their in-place correction — so production probably has **no content pipeline, no
certification view, no `exercise_intelligence` table and no per-attribute review**. That
is the largest single schema divergence in the product. **No production rollout, and no
production-pointed build, until ENV-1→ENV-2→ENV-9→ENV-3 are closed.** Production was not
contacted; every statement here is **UNVERIFIABLE** and derived from source.

---

### DAT-1 · `public.checkins` does not exist; the entire check-in feature is non-functional
`I-CHK-01` (= CON-01, EC-10, E-CHK-01, M-02) · **P0** · `BLOCKED_DECISION` · Wave 4

| Field | Value |
|---|---|
| **Source** | Master (LIVE), B, E, I, M · re-verified **SRC-V** |
| **Root cause** | CRC-01, masked by CRC-03 |
| **Affected** | `checkin_service.dart` (6 call sites), `coach_dashboard_screen.dart:108`, `qa_suites.dart:807` |
| **Impact** | Not "some check-ins fail" — **no check-in can be created by the application at all.** The coach review queue, compliance scoring, the at-risk roster, the Insights panel, the AI coach's grounding packet, the check-in component of the 12 Circle Score and the nutrition auto-adjustment all consume a structurally empty input. `hasCheckedInThisWeek()` is permanently `false`; `getCheckinStreak()` permanently `0`. The **correct** writer, `WeeklyCheckinService.submitWeeklyCheckin()`, has **zero callers** (E-CHK-02) |
| **Compounding** | `weekly_checkins` carries two mutually exclusive column families (I-CHK-03) — the one writer uses the baseline set, four readers including two AI paths use the 001 set. **Repointing the write path today would still produce NULLs on every reader**, and the AI prompt would receive the literal string `undefined` |
| **Dependencies** | **Blocked on Q-1 and Q-2.** I-CHK-03 (column contract) must land **before** I-CHK-01 (rewire) |
| **Remediation** | Per Q-1's recommendation: retire `CheckinService`, migrate callers to `weekly_checkins`. Then the column family, then the form fields (weight — Q-3), then delete the orphans, then let read failures surface |
| **Parallel** | **NO** — one change, one root cause, strict internal order |
| **Tests** | Writer-keys ⊆ reader-keys guard; unreachable-store raises; coach queue count equals submitted check-ins for that coach's active clients |
| **Gate** | Gate 1 |

---

### DAT-2 · `ai-generate-workout` loses the user's injury data
`I-INT-02` (= F-J-02, EC-02) · **P0** · `READY_TO_REMEDIATE` (column half) / `BLOCKED_DECISION` (fail-closed half) · Wave 3/5

Selects `user_profiles.goal, equipment` — **neither column exists** — so the whole query
400s and the generator loses `has_injuries`, `injury_locations`, `experience_level` and
`training_location` **in the same failed request**. `{ data: null }` is returned without
throwing and `?? 'general'` / `?? {}` turns a hard schema error into a confident default.
**Every AI workout is generated for a "general"-goal, "Bodyweight"-equipped,
"intermediate" gym trainee with no injuries, whoever the member actually is** — while the
system prompt instructs the model to *"AVOID anything contraindicated by their injuries."*
Column fix: one line, no decision. **Fail-closed behaviour is Q-5 / rule S.**
**Tests:** stub the read to error → 502 and **no workout**; stub it to `[]` → a workout
*is* generated (proves rule S did not over-trigger). **Gate:** Gate 1.

---

### DAT-3 · `ai-coaching-engine`'s profile query 400s entirely
`I-INT-01` (= F-J-02) · **P0** · `READY_TO_REMEDIATE` · Wave 3

Same mechanism, `user_profiles.goal`. One-line fix (`fitness_goal`). Already recorded in
`known-violations.json`; removing the entry is the last step of the fix and the guard
fails if either half is done alone.

---

### DAT-4 · Event registration writes a nonexistent column, then fabricates a ticket
`I-COM-01` (= H-02, M-04) · **P0** · `READY_TO_REMEDIATE` · Wave 3

`event_registrations.ticket_code` does not exist (the column is `qr_code`); the write
400s and a **"Demo fallback"** `catch` issues a ticket code for a row that was never
written. The user holds a ticket for an event they are not registered for. **Fix
together with `K-04`** — same table, different layer: K-04 is the missing `WITH CHECK`
that lets a member self-grant a *paid* ticket, this is the column name that makes *free*
registration fabricate one. **Drop `ticket_code` from K-04's published repro payload** —
it makes that request fail rather than succeed.

---

### DAT-5 · The coach check-in notification can never fire
`I-CHK-02` · **P0** · `BLOCKED_DECISION` · Wave 4

`trg_notify_coach_on_checkin` (004) returns early unless `weekly_checkins.coach_id` is
set. **No writer in the tree sets it**, so the trigger has never fired — and the
Dart-side notification was deliberately deleted in reliance on it. Blocked on Q-2.

---

### ERR-1 · There is no error-reporting sink anywhere
`EC-01` (= REL-26, LRE-27/28) · **P0** · `READY_TO_REMEDIATE` · Wave 3 · **do this before any other error-contract work**

No Sentry, no Crashlytics, no logging package, no `debugPrint`, no `developer.log` in
`apps/mobile`. Seven `print()` calls, inert in release. **All 234 failure sites are
invisible twice over:** the user cannot tell a failure from an empty state, and neither
can the operator, ever, in any environment, after the fact. Every finding in the error
domain is currently unmeasurable in production, so no fix can be verified as effective
and no regression in one can be detected. **Additive, cannot change behaviour, blocks
nothing, unblocks everything.**

---

### ERR-2 · AI decision inputs degrade silently to empty
`EC-02` · **P0** · `READY_TO_REMEDIATE` · Wave 3 (source) / Wave 5 (verify)

`recent()` in `ai-coaching-engine` is literally `try { … return data ?? []; } catch {
return []; }` and ignores the destructured PostgREST `error` besides; `ai-generate-workout`
destructures six parallel reads as `{ data }` with `error` **never inspected**. A failed
read of `ai_memories` yields `injuries: []`. **Amplifier:** the confidence score is
computed from the lengths of those same silently-emptied arrays, so a failed read is
scored identically to a brand-new user — *the number that exists to tell a client how much
to trust the advice cannot tell the difference.* Governance: a trace recorded over
silently-degraded inputs is not an audit record, which voids the decision-log invariant.
**Contract: rule S.** Source fix is independent of deployment and lands now.

---

### ERR-3 · Onboarding marks itself complete after the save fails
`EC-03` (= CON-02) · **P0** · `READY_TO_REMEDIATE` · Wave 4

`intake_flow_screen.dart:215-228` — on a throw the handler explicitly writes
`{'onboarding_complete': true, 'onboarding_step': 0}` and routes to `/home`. PAR-Q
answers, medical conditions, injuries, allergies, dietary restrictions, goal, experience
**and consent** are discarded while the user is recorded as fully onboarded and can never
return. `_saveProgress` Phase 2 is `catch (_) {}`, dropping the whole step's data on any
one field's type rejection. **This is the parent of CON-04, E-NUT-05, ERR-2 and DAT-2 —
it is the reason `risk_*` is frequently null.** Depends on CON-03 (the serializer
mismatch is what triggers it today) and now also on SEC-R2 (the PAR-Q trigger throw is a
second trigger for the same fail-open).

---

### ERR-4 · Absent risk data renders to the coach as "low risk"
`EC-04` · **P0** · `READY_TO_REMEDIATE` · Wave 3

`client_detail_screen.dart` — `d['risk_level'] as String? ?? 'low'` at four call sites,
over a provider that already returns `null` for the entire profile on any read failure.
**"The read failed" and "the client is low risk" are the same pixel.** Combined with
ERR-3, *a coach is affirmatively told a client is low risk when the client's PAR-Q was
never saved.* The default points in exactly the wrong direction on a safety signal.
Display fix is independent and safe: render "not assessed", visually distinct from an
assessed `low`. **The policy half is CON-04 and stays blocked.**

---

### AI-1 · `materialize_program_week` has no caller anywhere in the app
`ENG-01` · **P0** · `READY_TO_REMEDIATE` · Wave 5

The Dynamic Program Builder plans, versions and saves an engine program; **nothing ever
materializes a week.** Its own success message tells the coach to "materialize week 1
from Coach Copilot / the client program view" — no such affordance exists in either
screen. An engine-generated program reaches the client with **zero `program_workouts`
rows**. CRC-10 at its most consequential.

---

### AI-2 · `weekly_feedback.subject_id` is never written
`ENG-02` · **P0** · `READY_TO_REMEDIATE` · Wave 5

One unwritten column silently disables four systems: `predict_client` always returns
`no_data`; `assemble_weekly_review` always returns `no_feedback`, so no weekly review can
ever be created from in-app feedback; `evaluate_week` reads `coaching_mode` through
`fb.subject_id` → NULL → **`needs_approval` never fires for coach-guided clients**,
silently disabling the approval matrix; and `regenerate_program` stamps
`decision_traces.subject_id` NULL, so a subject can never read the trace of their own
program change. **Fix the writer before generating any fixture data, or the fixtures
encode the defect** (CRC-14).

---

### AI-3 · Equipment vocabulary mismatch — the engine selects nothing even after the substrate is populated
`ENG-25` · **P0** · `READY_TO_REMEDIATE` · Wave 5

`score_exercise` tests `(p_context->'equipment') ? ex.equipment` — exact string
membership. The seeded library stores `equipment` as the first element of
`equipment_required`: `dumbbells`, `cable_machine`, `barbell`. Coach Copilot supplies
`['barbell','dumbbell','cable','machine','bodyweight']`. **Only `barbell` matches.**
Everything else scores `equipment_match = 0` and is rejected under
`EQUIPMENT_CONSTRAINT`. Sibling: **ENG-26**, five of ten warm-up pattern slugs never
match (`hinge` ≠ `hip-hinge`). **These two are why populating the substrate alone will
not make the engine work.**

---

### AI-4 · The intelligence substrate is unpopulated in QA
`ENG-17` (= F-J-06, ENV-03) · **P0** · `BLOCKED_DECISION` · Wave 5

`exercise_intelligence` holds 0 profiles against 621 exercises; the movement graph holds
0 nodes and 0 edges. `build_workout` answers **HTTP 200 with `selected: []`** — no error,
no status, no triggered rule (that is AI-5). Nine decision traces exist on QA and every
one is an empty decision. **This is not evidence of a broken engine.** Separately, the
only automated builder — `rebuild_exercise_intelligence()` — writes neither
`contraindications` nor `joint_stress`, the two columns the injury rule reads, so even a
fully populated substrate would leave `injury_compatibility = 100` for every exercise and
`INJURY_PREVENTION` unable to fire (**F-J-23**). **Blocked on D-1** (which review status
is engine-eligible) — under an `approved`-only rule, populating the substrate yields an
engine that still selects nothing until a human reviews 22+ exercises.

---

### AI-5 · An unplannable request returns HTTP 200 with an empty plan
`F-J-08` (= ENG-08 adjacent) · **P0** · `BLOCKED_DECISION` · Wave 5

`build_workout` cannot distinguish "no exercise fits" from "the substrate is empty" from
"the equipment vocabulary does not match", and reports all three as success. Migration
119 already chose *refuse* for `materialize_program_week`; whether `build_workout` agrees
is **D-2**.

---

### AI-6 · The PAR-Q classification and structured allergies are read by nothing
`F-J-05` (= CON-04 consumption half) · **P0** · `BLOCKED_DECISION` · Wave 5

`risk_level`, `risk_flags` (including `pregnancy`, `postpartum`,
`doctor_advised_no_exercise`) and `food_allergies` are captured, server-classified and
stored — and **no AI prompt reads them.** `score_exercise` has no PAR-Q dimension at all:
passing `risk_level: 'high'` changes no score by a single point. The nutrition coach that
produces meal plans and grocery lists receives **no subject context whatsoever**
(F-J-26). Mechanism is cheap and clear; **policy is D-4 and is clinical.**

---

### EDGE-1 · `notify-coach-email` has no authentication and injects unescaped attacker HTML
`E-01` · **P0** · `READY_TO_REMEDIATE` (as deletion) / `BLOCKED_DECISION` (as fix) · Wave 5

No auth of any kind; the platform default `verify_jwt = true` is satisfied by the
**published anon key**. Any internet caller can enumerate the coach roster size, cause an
email to **every coach**, and control the body — `client_name` and `client_email` are
interpolated **raw** into a 12 Circle–branded HTML template. A branded phishing link
delivered from the platform's own sender to every coach, repeatable at will. **The
function has no caller in the codebase.** Recommended: delete it (D-4 in Workstream D).
Not deployed to QA; **UNVERIFIABLE** whether it is deployed to production.

---

### EDGE-2 · `send-checkin-reminder` has no authentication and no idempotency
`E-02` · **P0** · `BLOCKED_DECISION` · Wave 5

The handler never reads the `Authorization` header, though its own file header states it
is invoked only by `pg_cron` with a service-role bearer. Any anon-key holder triggers, for
every active relationship whose client has not checked in this week, one `notifications`
row and one email. **No idempotency guard at all** — N invocations produce N notifications
and N emails per client. This re-opens at the function layer, with service-role privilege,
the notification-insert hole that 116 and 118 closed at the RPC and table layers.
**Decision D-5:** service-role gate, or move the sweep into SQL and remove the HTTP
surface entirely (recommended — it deletes the attack surface).

---

### BIL-1 · The webhook has no idempotency store; session credits are re-granted on every redelivery
`K-01` (= E-08, I-PAY-01, REL-24) · **P0** · `READY_TO_REMEDIATE` · Wave 6

`checkout.session.completed` for `kind='package'` performs `.insert()` — not `.upsert()`
— with no conflict target and no `stripe_event_id` ledger, and the handler 500s wholesale
if any later statement throws **after this insert has already committed**. Stripe retries
any non-2xx for ~3 days. **Every sibling write in the same handler uses
`upsert(..., {onConflict})`; this one line is the exception.** A single retried event
grants a second block of paid coaching sessions.

---

### BIL-2 · Paid AI features have no server-side entitlement check
`K-03` · **P0** · `READY_TO_REMEDIATE` · Wave 6

`PaywallGate` is client-side presentation. The AI Edge Functions and
`generate_client_plan()` perform no plan check, so a free account can consume paid AI
directly. Combined with **P-11** (no Anthropic spend cap in QA and no rate limit across
12 AI functions) this is an uncapped cost surface as well as an entitlement one.
**Programme invariant §16: the client UI is never the authority for entitlement.**

---

### BIL-3 · A paid event ticket can be self-granted
`K-04` · **P0** · `READY_TO_REMEDIATE` · Wave 6

`event_registrations`' policy has no `WITH CHECK`, so a member sets `paid`/`payment_id`
themselves. **Fix in one change with DAT-4** — same table. Corrected repro: omit
`ticket_code`.

---

### BIL-4 · Session credits are granted but never consumed or enforced
`K-05` · **P0** · `READY_TO_REMEDIATE` · Wave 6

Nothing decrements a credit and nothing checks the balance before a session is booked.
With **K-25** (the credit table's UPDATE policy lets a coach rewrite the balance *and its
owner*) the paid-coaching ledger has neither an authoritative writer nor an authoritative
reader. Fix as one unit: a `book_coaching_session()` RPC consuming credits under a row
lock, plus the policy narrowing.

---

### UIX-1 · The booking screen is dead for every client
`M-03` · **P0** · `READY_TO_REMEDIATE` · Wave 3

`/appointments` and `/book-call` issue a PostgREST embed (`coach:coach_id(...)`) with no
backing FK, so the query fails for every client. *Recommendation: drop the embed and read
coach profiles from `public_profiles`* — no migration, and it matches the pattern
`coach_relationship_service.dart` already uses.

---

### UIX-2 · No in-app account deletion, and the app states that there is
`REL-04` (= M-06, K-16, I-USR-01(b)) · **P0** · `BLOCKED_DECISION` · Wave 7

App Store Guideline 5.1.1(v) makes in-app deletion mandatory for any app supporting
account creation. Worse than absent: `help_center_screen.dart:45` instructs users to "Go
to Profile → Settings → Account → Delete Account" — **a path that does not exist** — and
the privacy-policy screen makes the same promise. Simultaneously a compliance blocker and
a false in-app statement. Compounded by **I-USR-01(a)**: 53 of 143 foreign keys restrict
deletes, so both program deletion and account deletion are blocked at the schema level
(Q-7). **Until it ships, correct the false help-centre and privacy-policy text** — that
half needs no decision and should land in Wave 1.

**2026-08-24 · Wave 1 batch task 8 — text half `REMEDIATED`, wording `REQUIRES_REVIEW`.**
The false in-app-path claims are removed and pinned by
`account_deletion_claims_test.dart`. The replacement text, however, promises an
**email-based deletion path** (support@/privacy@12circle.app, permanent removal within
30 days) — a user-facing support/policy commitment not traceable to a recorded owner
decision. The wording is held at the custody checkpoint for explicit owner approval or
substitution before commit. The feature half is unchanged: `BLOCKED_DECISION`, Wave 7.

---

### REL-1 · iOS build cannot be produced
`REL-01` + `REL-02` + `REL-03` · **P1** *(rated P0 by G; see §5 on gate-vs-impact)* · `READY_TO_REMEDIATE` · Wave 8

No CocoaPods integration (`flutter_local_notifications` and `record` ship no
`Package.swift`, so SPM alone cannot resolve the graph); `mobile_scanner 6.0.11` needs
iOS 15.5 against a declared target of 13.0, so `pod install` fails outright; no
`DEVELOPMENT_TEAM`, no entitlements, no profile, legacy `"iPhone Developer"` identity.

---

### REL-2 · Digital subscriptions sold through Stripe
`REL-05` (= D-K1) · **P0** · `BLOCKED_DECISION` · Wave 6/8

`self_guided` ($29/mo) and `ai_guided` ($59/mo) are digital services delivered in-app;
Guideline 3.1.1 requires IAP and `checkout_launcher.dart` redirects to hosted Stripe
Checkout. The coach subscription has a plausible 3.1.3(e) argument; the two digital tiers
almost certainly do not. **The single largest architectural item between the product and
iOS distribution.** Option (a) adds a *second* entitlement source of truth on top of a
webhook that is not yet idempotent — which is why K sequences it after BIL-1/BIL-2.
**Decision D-1.**

---

### REL-3 · QA tooling ships in release builds
`REL-06` (= LRE-26) · **P0** · ✅ `VERIFIED_CLOSED` 2026-08-26 *(Wave 1 batch task 7 — compile-time `kQaToolingEnabled = !kReleaseMode` route gate + affordance gating (recorded scope extension); `release_route_gate_test.dart` executed in CI at `6d42b10` — see §7.8)* · Wave 1

`/qa-center` and `/mie-debugger` are wired unconditionally into the shipping router,
gated by neither `kReleaseMode` nor a role check. Only **4 uses of
`kReleaseMode`/`kDebugMode` exist in the entire client**, so the audit should be broad,
not limited to these two routes. *(The broad-audit instruction produced finding
**W1B-N2**, §7.7 — `/admin-exercise-review` and `/vendor-portal` carry no UI role
check.)*

---

### REL-4 · Password reset and OAuth have no return path on iOS
`REL-08` (= M-11) · **P0** · `READY_TO_REMEDIATE` · Wave 8

`redirectTo: kIsWeb ? … : null` at four call sites, no `CFBundleURLTypes`, no associated
domain. Sign in with Apple and Google Sign-In are both in `pubspec.yaml`, so this is the
primary sign-in path, not an edge case.

---

### REL-5 · No report / block / moderation surface for user-generated content
`REL-16` · **P0** · `BLOCKED_DECISION` · Wave 7

The app ships community and 1:1 messaging; an exhaustive search finds no report, block or
mute affordance anywhere in `lib/`. Guideline 1.2 requires a content filter, a report
mechanism, a block mechanism, a published EULA and a documented 24-hour response
commitment — the last of which is an **operational** commitment needing a named owner.
**Decision D-3.**

---

### REL-6 · No hosted privacy, terms or support URLs
`REL-17` · **P0** · `BLOCKED_DECISION` · Wave 7

All three exist only as in-app Flutter screens. Edge Functions default their redirect
targets to `https://12circle.app/...`, implying a domain this programme **cannot confirm
is registered or controlled** (D-4: canonical name and domain). Settings exposes Privacy
Policy and Help Center but not Terms of Service, though the screen exists.

---

### TST-1 · The live security suite has never executed
`N-01` (suite half) · **P0** · ✅ `VERIFIED_CLOSED` 2026-08-26 *(EB-1 resolved; the six suites executed in CI at `6d42b10` — 271/271. The row below is the historical statement)* · Wave 1

188 live authorization assertions across six suites, written to fail against the
pre-remediation database and to pass after — **not run in any workstream session**,
because `QA_SERVICE` is not present in any working copy. Phase 1's evidence is therefore
a point-in-time claim that nothing currently re-verifies, and §4.2 proves the posture has
drifted since. **Blocked on: a scoped QA service key in CI secrets.** This is the single
highest-value environment unblock in the programme.

---

*(P0 register continues — the remaining seven P0 rows are the second-order members of
clusters already stated in full: `E-NUT-05` allergens never reach the prompt (Wave 5,
blocked on D-6); `H-05` the `progress-photos` bucket exists in no migration so all
progress and onboarding photography fails (Wave 3); `I-CHK-03` the two `weekly_checkins`
column families (Wave 4, blocked on Q-2); `F-J-12` any coach reads every member's
decision traces (Wave 2, blocked on D-7); `K-ENV-1` folded into ENV-5; `P-8` no QA Stripe
credentials, runbook or price ids (Wave 6); `I-NOT-04`/`H-19` a conversation participant
can rewrite the other party's message text (Wave 2).)*

---

## 7. P1–P3 register

**Field compression.** Recording the full 20-field card for all 310 findings would produce
a document nobody reads, and the omitted fields are already stated in the owning report.
P1 rows below carry: ID · aliases · root cause · layer · impact · dependencies · decision ·
parallel · wave · gate. P2/P3 rows carry: ID · root cause · statement · wave · decision.
**Every finding's full evidence remains in its source report, which this row names.**

### 7.1 Security & Authorization

| ID | Alias | Sev | RC | Statement | Dep | Dec | ∥ | Wave |
|---|---|---|---|---|---|---|---|---|
| `I-MIG-03` | — | P1 | CRC-07 | `CREATE OR REPLACE` silently drops the `search_path` pin **and any authorization wrapper**. Correct today only because 122 sorts last. **The standing test for this is the class fix for §4.2** | ENV-1 | no | Y | 2 |
| `F-J-12` | ENG-09, E-04 | P1 | CRC-08 | `decision_traces` SELECT grants an unscoped `role in (admin,content_manager,coach)` arm. Live: a coach with **zero** relationship rows read all 9 traces across 2 unrelated subjects. Every sibling table chose "active coach or admin" | — | **D-7** | Y | 2 |
| `I-NOT-04` | H-19 | P1 | CRC-07 | `messages` UPDATE policy has no `WITH CHECK` and no column restriction — a participant rewrites the other party's message text | — | **Q-10** | Y | 2 |
| `H-11` | H-15 | P1 | CRC-11 | Two "12 Circle Score" systems and two disagreeing leaderboards; `daily_scores` carries a `FOR ALL` policy and is **client-writable** | — | **Q-H4** | Y | 2/7 |
| `E-05` | — | P1 | CRC-08 | `generate-communication` returns the coach's private clinical assessment — compliance, risk factors, churn framing — to the **client**, who can call it with their own `communication_id` | ENV-7 | no | Y | 5 |
| `E-03` | — | P1 | CRC-07 | `enrich-exercise` is dead on arrival: it calls `seed_exercise` under the caller's JWT, and 116 revoked it. Every call spends a full Sonnet generation and then fails at the write. **Do not re-allowlist `seed_exercise`** | — | **D-3** | Y | 5 |
| `E-10` | — | P2 | CRC-08 | `ai-coaching-engine`'s service-role detection is fail-open on an unset env var — `authHeader === 'Bearer '` grants arbitrary-subject access. Non-constant-time secret compare | — | no | Y | 5 |
| `F-J-24/28` | — | P2 | CRC-08 | Two further fail-open comparisons in edge-function auth | — | no | Y | 5 |
| `E-NUT-17` | CON-05 | P2 | CRC-07 | `079:65`'s `GRANT EXECUTE … TO authenticated` on `ai_adjust_nutrition` still stands. Any selective re-application of 079 after 116 re-opens SEC-04's nutrition arm. Function is dead and its input column is never written | — | no | Y | 2 |
| `R-01` | — | P2 | CRC-08 | `award_points()` / `penalize_points()` take an arbitrary `p_points`, correctly scoped to `auth.uid()` — a member can award **themselves** any score | H-11 | Q-H4 | N | 7 |
| `SEC-12` | D-04, R-03 | P2 | CRC-10 | `marketplace_coaches()` does not filter `is_demo`; migration 110 states demo accounts are excluded from discovery and the RPC does not honour it. Live: 6 coaches returned, including 5 demo fixtures | — | **Q-H5** | Y | 7 |
| `R-04` | — | P3 | CRC-07 | `foods` accepts INSERT from any member (`WITH CHECK (true)`). Shared database by design; abuse surface is spam | — | moderation | Y | 7 |
| `E-NUT-08` | — | P2 | CRC-07 | Any authenticated user can poison the shared barcode cache | R-04 | no | Y | 5 |
| `R-05` | — | P3 | CRC-07 | `coaches can update client profiles` is broader than any screen needs. No escalation path remains after 115 | — | **Q-H1** | Y | 7 |
| `R-06` | — | P3 | — | Supabase Auth leaked-password protection is **disabled** on QA. One project setting, no code | — | no | Y | 1 |
| `R-07` | — | P3 | — | `pg_net` installed in `public` | — | no | Y | 8 |
| `R-08` | — | P3 | CRC-11 | The intake Dart still computes and submits `risk_*`; the server overrides it silently. Dead weight, pinned in step by `SEC-023` | SEC-R2 | no | Y | 4 |
| `E-15` | — | P3 | CRC-08 | `send-invite-email` is authenticated but not authorized — any signed-in account sends a branded invite to any address with an unvalidated token | — | **D-7(D)** | Y | 5 |
| `E-16` | — | P3 | CRC-08 | `explain-decision` lets the caller pick the audience | F-J-12 | D-7 | Y | 5 |
| `ENG-22` | — | P2 | CRC-08 | `explain-decision` reads under caller RLS but **writes the cache with service role** — with F-J-12, an unrelated coach can mint and permanently pin the client-facing explanation of another coach's client's workout | F-J-12 | D-7 | N | 5 |
| `E-14` | — | P3 | CRC-03 | Seven functions return raw exception text; `ai-coach` returns the **raw Anthropic error body** | — | no | Y | 5 |
| `K-25` | — | P1 | CRC-07 | `client_session_credits` UPDATE policy lets a coach rewrite the balance **and its owner** | K-05 | no | N | 6 |
| `K-26` | — | P1 | CRC-13 | The **production** build default ships a `pk_test_` publishable key. Either real money has never moved, or the constant is wrong | — | **D-1(L)** | Y | 1 |
| `REL-31` | — | P1 | CRC-07 | `avatars`, `coach-media` and `exercise-media` are **public buckets** — every object is world-readable by URL. Confirm no client media or PII is written to `coach-media` | — | privacy | Y | 7 |
| `REL-30` | — | P1 | CRC-08 | API verifies Supabase tokens with a shared HS256 secret; Supabase is migrating to asymmetric JWKS. This path breaks on that migration and cannot be rotated without redeploying | LRE-06 | D-2 | N | 8 |
| `REL-29` | — | P1 | CRC-11 | A second, parallel auth stack ships alongside the Supabase one — `firebase-admin`, `passport-jwt`, `bcryptjs`, `auth.controller`, `users.controller`. Unused authentication is unmaintained attack surface | — | **D-2** | Y | 8 |
| `REL-28` | — | P1 | CRC-07 | API: `enableCors({origin:true})` when `CORS_ORIGINS` is unset; no helmet, no rate limiting on a route that spends Anthropic credits; 12 MB body limit; `ValidationPipe` per-controller not global | LRE-06 | no | Y | 8 |
| `REL-36` | — | **P1** *(raised from P2 by W1-T1)* | CRC-13 | Seed files with published test passwords run on `supabase db reset`; add a guard refusing to seed a non-QA ref. **Raised because W1-T1 committed three bcrypt-hashed QA fixture passwords that were not previously in git history — the seed-target guard is now the only remaining control** | — | no | Y | 1 |
| `K-28` | REL-35 | P3 | CRC-07 | `Access-Control-Allow-Origin: '*'` on all five billing functions | — | no | Y | 6 |
| `E-07` | K-21 | P2 | CRC-08 | Caller-controlled `successUrl`/`cancelUrl`/`returnUrl` handed straight to Stripe — an open redirect with a trusted intermediary, with `{CHECKOUT_SESSION_ID}` appended to the attacker's URL | — | **D-6(D)** | Y | 6 |
| `E-06` | — | P2 | CRC-13 | Production URLs are the hardcoded default in four Edge Functions. A QA invite links a real recipient into **production signup** with a QA token. The SQL layer removed exactly this class deliberately; the function layer never did | — | no | Y | 5 |
| `H-06` | — | P1 | CRC-01 | Migration 102 closed the client→coach profile read; **four client surfaces and the coach's incoming-request list were never repointed.** A paying client is shown a product that behaves as if they have no coach; a coach must accept requests from an anonymous "New Client" | — | **Q-H1** (coach half only) | Y (client half) | 3 |
| `F-18` | — | P1 | CRC-08 | Cycle data leaves the user-isolation boundary through the AI coaching Edge Function — silently, no consent, no opt-out, `tracking_enabled` unhonoured | ENV-7 | **E-4(F)** | Y | 5 |

### 7.2 Error Contract

| ID | Sev | RC | Statement | Dep | Dec | ∥ | Wave |
|---|---|---|---|---|---|---|---|
| `EC-05`/`N-07` | P1 | CRC-03 | **§4.2 regression.** Completion swallows both persistence steps and shows the celebration | — | no | Y | 3B |
| `EC-06` | P1 | CRC-03 | A failed nutrition read returns zeroed totals, which are then **persisted as the day's score** — `_updatePoints` *sets* rather than increments, so one transient read failure permanently overwrites earned points | — | no | Y | 3B |
| `EC-07` | P1 | CRC-04 | A failed check-in read **fabricates a `pending` week**; re-submitting overwrites a *reviewed* check-in, resets `status`, hides the coach's feedback and re-notifies them | — | no | Y | 3B |
| `EC-08` | P1 | CRC-03 (C-2) | `submitCoachFeedback` returns `true` on a zero-row update. **The verification is present — `.select('user_id')` — and the check on it is missing. Two lines** | — | no | Y | 3B |
| `EC-09` | P1 | CRC-03 (C-2) | ~10 unverified writes reported as success, including `approveGlobalExercise`, `rejectGlobalExercise`, `platform_settings`, and **`addMemory('injury', …)` — a dropped safety input that silently never exists** | — | no | Y | 3B |
| `EC-11` | P1 | CRC-03 | **§4.2 regression.** `WorkoutService`'s 13 swallows sit beneath the providers Phase 2 fixed; `getCompletionRate()` fabricates adherence | **H-01 first** | no | N | 3B |
| `EC-12` | P1 | CRC-03 | Habit writes optimistic, swallow, **no rollback**, then score from unpersisted state — the score and the habit log disagree permanently | — | no | Y | 3B |
| `EC-13` | P1 | CRC-03 | A failed message read renders as an empty conversation; `getUnreadCount() → 0` suppresses the badge that would prompt a second look | — | no | Y | 3B |
| `EC-14` | P1 | CRC-04 | Stripe Connect failures render as a real £0.00 balance and a disconnected account — the highest-trust number in the product, fabricated from a network error | — | no | Y | 3B |
| `EC-15` | P2 | CRC-03 | Silent entitlement downgrade. **The direction is correct — all three fail closed.** The defect is the silence: "denied" and "couldn't verify" are different answers (rule X) | — | no | Y | 3B |
| `EC-16` | P2 | CRC-03 | Plan generation failure ends onboarding silently; the client lands on Home with no program and no retry | EC-03 | no | Y | 4 |
| `EC-17` | P2 | CRC-04 | `detectRisks()` fabricates a risk assessment **and its parser cannot work** — `Uri.splitQueryString()` applied to JSON. Currently unreferenced: latent. Delete or rewrite; do not leave a broken safety-assessment API in the tree | — | **D-2(D)** | Y | 5 |
| `EC-18` | P2 | CRC-03 | A nested fallback retries without the join and discards both causes | — | no | Y | 3B |
| `EC-19` | P2 | CRC-03 | `custom_exercise_service.dart` — **54 swallow sites in 816 lines**, 23% of the repository total in 1.4% of its source. Needs one pass under the contract, not 54 decisions | — | no | N | 3B |
| `EC-20` | P2 | CRC-03 | Notification inserts swallowed throughout. **Sanctioned category** — needs rule **O** recording, not propagation | EC-01 | no | Y | 3A |
| `EC-21` | P2 | CRC-14 | The QA harness itself swallows: a `client_plan` failure becomes `ClientPlan.free`, so an entitlement probe certifies the wrong tier for a paying tester. **A QA tool that swallows produces false PASSes** | — | no | Y | 3B |
| `EC-22` | P2 | CRC-04 | The workout feedback dialog reports "submitted" on failure. `workout_feedback` is read by the AI engine as a recovery signal | — | no | Y | 3B |
| `EC-24` `EC-25` `EC-26` | P3 | CRC-03 | Sanctioned best-effort persistence (keep, add rule O); low-stakes provider `[]`s (fold into the L2 sweep); `_resnapshotSession` — **named as a model of an honest boolean, not a defect** | EC-01 | no | Y | 3B |
| `M-10` | P1 | CRC-04 | Success states that do not reflect persistence — "Invite sent!", "Switched to the Free plan." | EC-09, K-07 | no | Y | 3B |
| `M-12` | P2 | CRC-10 | Dead buttons with no-op handlers (class JOIN, QR) | — | **Q-M12** | Y | 7 |

### 7.3 AI / Intelligence Engine

| ID | Sev | RC | Statement | Dec | Wave |
|---|---|---|---|---|---|
| `ENG-03` | P1 | CRC-02 | **Coach Copilot invents a prescription in the UI** — `sets:3, reps:10, rest_seconds:90` for every exercise. 119 went to real lengths to stop the *engine* fabricating a prescription; the *presentation layer* fabricates one instead, and the canonicalizing trigger stamps it canonical | D-3 | 5 |
| `ENG-04` | P1 | CRC-11 | **Copilot approval destroys the client's program assignment** — `_approve()` calls `assignProgram`, which sets every existing `active` assignment to `replaced` | no | 5 |
| `ENG-05` | P2 | CRC-02 | Copilot writes lowercase `day_of_week`; `getTodaysWorkout()` matches capitalized names; 119's normalizer only rewrites `'1'..'7'`. A Copilot session can never be "today's workout" | no | 5 |
| `ENG-06` | P1 | CRC-02 | **Every session in a materialized week is identical.** `materialize_program_week` builds one context and reuses it for every day; `build_workout` is deterministic, so Push/Pull/Legs select the same exercises. **The split is a title** | no | 5 |
| `ENG-07` | P1 | CRC-10 | The certification and review pipeline **gates nothing** — no engine function filters `exercise_intelligence.status`. Draft, heuristic and AI-drafted intelligence is production truth. Product bible principle 4 unenforced | **D-1** | 5 |
| `ENG-10` | P1 | CRC-10 | **No client-facing surface for any engine output.** Nothing in `lib/` reads `decision_traces`, `predictions`, `communications` or `weekly_feedback` on the client side, though `communications`' RLS exists precisely to serve a client their `sent` reviews. Product bible §4 "show the grounding" is unimplemented for clients | scope | 5 |
| `ENG-11` | P1 | CRC-10 | `validate_week`, `build_workout` and `rank_exercises` have no UI caller. The cross-day safety validator — no back-to-back high-fatigue hinge days, ≤3 spinal-loading days/week — **never runs** | no | 5 |
| `ENG-13` | P2 | CRC-10 | `regenerate_program` implements two of its own four actions. `REPLACE_EXERCISES` (`INJURY_ADAPTATION`) and `REDUCE_COMPLEXITY` are never executed: **no exercise is ever substituted after an injury adaptation** | no | 5 |
| `ENG-14` | P2 | CRC-10 | The coach approval matrix is inert for the mode it protects (consequence of AI-2) | no | 5 |
| `ENG-18` | P2 | CRC-10 | The bootstrap has an undocumented ordering dependency and **no guard** — `seed_warmup_library()` silently `continue`s and reports success when run before `rebuild_movement_graph()` | no | 5 |
| `ENG-19` | P2 | CRC-03 | `build_workout` reports `warmup: []` with no signal distinguishing "needs no warm-up" from "the library was never seeded" | no | 5 |
| `ENG-20` | P1 | CRC-14 | **There is no engine test suite.** Zero tests exercise `score_exercise`, `build_workout`, `plan_program`, `evaluate_week`, `predict_client`, `assemble_weekly_review`, trace completeness or LLM groundedness | no | 8 |
| `ENG-21` | P3 | CRC-02 | `predict_client`'s arithmetic is unvalidated — an uncapped finish date, and a `confidence` that sums a pace ratio with two raw percentages | no | 5 |
| `ENG-23` `ENG-24` `ENG-26` | P3/P2 | — | Doc drift in the MIE bootstrap order; `rank_exercises` calls `score_exercise` 3× per candidate row; **warm-up pattern vocabulary mismatch — five of ten slugs never match** | no | 5 |
| `F-J-09` | P1 | CRC-05 | The rejection gates are **null-permissive** — a missing constraint value passes the gate | D-4 | 5 |
| `F-J-10` | P1 | CRC-05 | The AI generator names the deterministic engine as the load authority, **never calls it**, and records nothing | **D-8** | 5 |
| `F-J-13` | P1 | CRC-05 | A decision trace is **not an input snapshot and cannot be replayed** — `generate_workout` trusts `p_context` rather than resolving the subject's state server-side. The explainability guarantee is only as complete as the trace | D-8 | 5 |
| `F-J-14`/`F-J-25` | P2 | CRC-13 | Model identity is not recorded and not centrally pinned | D-8 | 5 |
| `F-J-16` | P1 | CRC-03 | The coaching-engine client **cannot report a failure** | no | 5 |
| `F-J-20` | P1 | CRC-04 | **A model refusal is not detected and is persisted as coaching** | no | 5 |
| `F-J-21` | P1 | CRC-13 | No Anthropic call anywhere is bounded by a timeout; no `AbortController` in any of the 19 functions | no | 5 |
| `F-J-22` | P1 | CRC-10 | The engine plans from unreviewed, model-authored intelligence | **D-1** | 5 |
| `F-J-23` | P1 | CRC-05 | `rebuild_exercise_intelligence()` writes neither `contraindications` nor `joint_stress` — the two columns the injury rule reads. **`INJURY_PREVENTION` could never fire even on a fully populated substrate** | D-1 | 5 |
| `F-J-26` | P1 | CRC-05 | The AI Nutrition Coach is given **no subject context at all** | D-6 | 5 |
| `F-J-18`/`F-J-19` | P2 | CRC-08 | Two subject-identity defects in coach-facing AI, both currently unreachable. **Fix before wiring `analyzeCheckins`/`detectRisks` into any screen** | **D-2(D)** | 5 |
| `F-J-27` | P2 | CRC-04 | A photo-derived calorie estimate is indistinguishable from a measured value | **D-5** | 5 |
| `F-J-29`/`F-J-30`/`F-J-31` | P2/P3 | — | Enrichment targeting; insight de-duplication by date; two smaller defects | no | 5 |
| `E-12`→`F-J-04` | P1 | CRC-05 | `recent()` orders five of nine context tables by a `created_at` they do not have, so the AI sees **nothing** for `workout_sessions`, `workout_set_logs`, `habit_logs` and `user_scores`. `progress_insight` is grounded on nothing, and the confidence score's `+28` and `+9` can never fire — **the flagship safety signal is wired to a constant** | no | 3A/5 |
| `E-13`→`I-NUT-01` | P1 | CRC-01 | `meal_suggestion` reads `protein_g`/`carbs_g`/`fat_g` on `nutrition_logs`; the columns are `protein`/`carbs`/`fat`. `remaining_*` equals the full day's target no matter how much was eaten, so the AI recommends three more full meals to someone who has hit their macros | no | 3A |
| `E-17`…`E-20` | P3 | — | Enrichment writers record no actor; query-builder reuse; no timeout/retry/partial-progress contract on batch enrichers (25 serial Sonnet calls in one request); `ai-coach` drops its own audit row on failure | no | 5 |
| `A-3`/`B-1` | P2 | CRC-11 | `ai-coaching-engine`'s daily insight emits `focus` and `intensity_delta` from a Claude call, and both reach the active-workout load cue and `generate_client_plan`'s structure. Read strictly against product bible §6, **that is an LLM altering training** | **D-9** | 5 |

### 7.4 Nutrition · Check-In · Women's Health

| ID | Sev | RC | Statement | Dec | Wave |
|---|---|---|---|---|---|
| `E-NUT-01` | P1 | CRC-02 | Barcode scans record per-100 g macros as one serving — **and the test suite asserts the defective mapping as correct** | no | 4 |
| `E-NUT-02` | P1 | CRC-10 | No edit or delete path anywhere in nutrition, although RLS and grants permit both | **Q-E2** | 4 |
| `E-NUT-03` | P1 | CRC-12 | A meal logged on a past date is written to today and then **disappears from the screen the user is looking at** | no | 4 |
| `E-NUT-05` | **P0** | CRC-05 | **Allergies and dietary restrictions never reach the AI meal-plan generator.** It sends `Dietary restrictions: None` unless the user re-selects from six hard-coded chips. Materially worse than CON-08, which assumed the data reached the prompt and was merely unvalidated. **Loading the profile's allergies is unconditional and does not wait on the decision; only block-vs-annotate does** | **Q-E5 / D-6** | 4 |
| `E-NUT-06` | P1 | CRC-11 | Nutrition operates outside "the engine decides, AI explains" — five AI paths across two backends, none deterministic, none writing a decision trace | **Q-E6** | 5 |
| `E-NUT-07` | P2 | CRC-11 | `/meal-plan` and `/grocery-list` bypass the AI paywall | no | 6 |
| `E-NUT-09`…`E-NUT-16` | P2/P3 | CRC-10/03 | Cache never refreshes and fails silently; meal-log scoring not deduplicated; AI plans never persisted; generation errors become content; the AI-scan portion multiplier is dropped from the record; **water tracking is decorative while the coach-facing half exists**; two nutrition dashboards of unequal capability, one orphaned; unvalidated media type forwarded to a paid credential | **Q-E7** | 4/5 |
| `E-CHK-02` | P1 | CRC-10 | The correct check-in write path has **zero callers** | Q-1 | 4 |
| `E-CHK-03`/`I-CHK-03` | P1 | CRC-02 | Two mutually exclusive `weekly_checkins` column families; the writer and every reader disagree | **Q-2** | 4 |
| `E-CHK-04` | P1 | CRC-10 | The check-in form collects data it silently discards, and **never collects weight** — which is `ai_adjust_nutrition`'s only trend input | **Q-3/Q-E3** | 4 |
| `I-CHK-04` | P1 | CRC-14 | **The QA fixtures write the opposite column family and the wrong status, masking the defect they exist to exercise.** QA looks populated to the coach dashboard while the real write path produces rows those surfaces cannot read | Q-2 | 4 |
| `E-CHK-05`…`E-CHK-11` | P2/P3 | CRC-11/10/03 | `/checkins` is an appointments calendar filed as check-in; placeholder screens on live routes; the coach analysis analyses the coach; the in-app QA suite probes a table **and a column** that do not exist; re-submission semantics; read paths mask failure; the success dialog claims a notification that was never sent | **Q-E4** | 4/7 |
| `F-01`…`F-07` | P1/P2 | CRC-06/10 | No domain constraint on any cycle table; "last period" is the max `start_date` not the most recent *past* one; **re-opening the symptom sheet destroys the day's saved values** (live-verified); duplicate periods accumulate; `cycle_settings` is write-dead so predictions are permanently 28/5; writes silently no-op when signed out | no | 7 |
| `F-08`…`F-16` | P1/P2/P3 | CRC-02/04 | The fertile-window **label ignores the computed window** (wrong on 7 of 28 days); **no staleness bound — a 400-day-old log renders as fact**; `ovulation` used as both 1-based day and 0-based offset in one function; phases collapse at short cycles; the app can never report a late period; a future-dated start fabricates "Menstrual · Day 1"; out-of-range lengths silently clamped; DST-sensitive arithmetic; the calculation reads the clock internally | **E-1, E-2** | 7 |
| `F-19`…`F-25` | P2/P3 | CRC-02/10 | The cycle row is mislabeled as `recovery` in the AI context; no history surface; no edit/delete for a mis-logged period; "period ended" is silent; disclaimer below the fold; the gender gate only affects a subtitle **and hides a user's own data when unset**; captured symptom detail never displayed | **E-3, E-5** | 7 |

### 7.5 Billing & Entitlements

| ID | Sev | Statement | Dec | Wave |
|---|---|---|---|---|
| `K-02` | P1 | Renewals and payment failures are never reconciled; `payments` is not a ledger | — | 6 |
| `K-06` | P1 | Refunds and chargebacks revoke nothing | **D-K4** | 6 |
| `K-07` | P1 | A failed Stripe cancel still revokes local access — and the UI says "Switched to the Free plan" | D-K2 | 6 |
| `K-08` | P1 | Nothing prevents duplicate concurrent subscriptions. **The customer pays twice and `client_plan()` reports one plan** | **D-K9** | 6 |
| `K-09` | P1 | Coach plan capacity is granted, never revoked, and self-writable | **D-K8** | 6 |
| `K-10` | P1 | Coach messaging — a Coach-Guided-only capability — has no paid-state check | — | 6 |
| `K-11` | P1 | The first failed payment revokes access immediately | **D-K3** | 6 |
| `K-13` | P1 | Stripe customer creation races; a user can end up with two Stripe customers | — | 6 |
| `K-15` | P1 | Three-and-a-half tier representations, only one synchronized | — | 6 |
| `K-17` | P1 | Coach Connect readiness is cached and refreshed only when the coach looks at it | — | 6 |
| `K-19` | P1 | Coach revenue figures are structurally wrong | K-02 | 6 |
| `K-14`,`K-18`,`K-20` | P2 | Commission prices differently on one-time vs recurring; the global setting silently overrides the per-coach rate; a coach can zero their own commission by pre-inviting the lead | **D-K7** | 6 |
| `K-22`,`K-23`,`K-24`,`K-27` | P2 | One-time entitlements granted without checking `payment_status`; no event-ordering guard, so a stale update resurrects a cancelled subscription; abandoned checkouts leak pending payment rows; webhook failures are silent | — | 6 |
| `K-29`,`K-30` | P3 | Trials resolvable but not creatable; **`PaywallGate` fails open on error** | **D-K5** | 6 |
| `E-09` | P1 | No `[functions]` block in `config.toml`. **`stripe-webhook` will 401 every Stripe delivery** unless deployed with `--no-verify-jwt`, and `verify_jwt=true` on the other 18 is providing a false sense of protection — it is what makes EDGE-1 and EDGE-2 reachable by the internet rather than by nobody | — | 1 |

### 7.6 Release, Environment, Product Integrity, UI, Testing

| ID | Sev | Statement | Dec | Wave |
|---|---|---|---|---|
| `LRE-09`…`LRE-42` (34 rows) | P1–P3 | Secret manifest uncommitted and undiffable; function deps unpinned; deploys unautomated with no recorded SHA; no Vault runbook; no flavors or per-environment bundle ids; **beta is undefined** (D-4); build numbers manual; artifacts carry no provenance and the QA bundle carries production strings; no audit log; no rollback per layer; `.temp` tracked; reset wrapper unguarded; no root README or environment runbook; price-ID manifest uncommitted; Stripe mode unresolved per environment | D-1…D-6 (L) | 1/8 |
| `REL-09`…`REL-15` | P1 | No `PrivacyInfo.xcprivacy`; `ITSAppUsesNonExemptEncryption` absent; **three different app names and two diverging bundle identifiers** — fix before the App ID is registered, it is immutable afterwards; no build-number strategy | **D-4(G)** | 8 |
| `REL-24`…`REL-27` | P1 | Webhook event coverage and dead-lettering; `config.toml` declares no auth/redirect/email-template config so QA↔prod parity is unverifiable; **no crash reporting, analytics, APM, structured logging, uptime monitoring or alerting in any environment**; free-tier daily backups, no PITR, no rehearsed restore | **D-5(L)**, D-3 | 8 |
| `REL-32`,`REL-37`…`REL-48` | P2/P3 | Push permissions requested with no push infrastructure (`SCHEDULE_EXACT_ALARM` is commonly rejected); landscape permitted on a portrait-first UI; **180 occurrences of TODO/mock/placeholder/"coming soon" in `lib/`**; unlicensed remote placeholder imagery; no App Store Connect metadata; no iPad decision; no localisation declaration; no Fastlane; unused desktop scaffolds; **no accessibility audit though the product bible names accessibility a requirement** | scope | 8/9 |
| `H-04`,`H-05` | P1/P2 | `chat-media` and `progress-photos` buckets are referenced by shipped UI and passing widget tests and **created by no migration**. Migration 029 writes RLS *for* `progress-photos`, assuming a bucket it never creates. **Do not create either as a public bucket — both hold body photography** | no | 3A |
| `H-07`,`H-08`,`H-13`,`H-14` | P1/P2 | **The dominant product-integrity cluster (CRC-04).** An empty or unreachable conversation renders **four fabricated coach messages including training advice**; with no assigned habits the app invents **eight habits with invented multi-day streaks and schedules device reminders for them**; five fictional community groups, two pre-marked "Joined"; with no program, Home starts a hard-coded demo workout **credited to a fictional coach**. None is distinguishable from real data by looking at the screen, which is why all four survived six prior workstreams | **Q-H2, Q-H6** | 3C |
| `H-09`,`H-10`,`H-16`,`H-17`,`H-18` | P2/P3 | Challenges join but never progress and two tabs can never populate; six notification preferences persisted and honoured by nothing; **`/pods` (accountability pods, real tables, seeded data) and `/coach-client-workouts` are unreachable from anywhere**; three inert Settings controls; two 0-byte service files and 40 orphaned providers | **Q-H3, Q-H7, Q-H8** | 7 |
| `H-12` | P2 | The marketplace ranks demo fixtures and coaches who have closed their books alongside real ones | **Q-H5** | 7 |
| `I-USR-01`,`I-USR-02`,`I-USR-03` | P1/P2 | 53 of 143 FKs restrict deletes, blocking program **and** account deletion; `user_profiles.email` can never be updated after creation; **`user_profiles` models five concepts twice** | **Q-6, Q-7, Q-8** | 3A/7 |
| `I-NUT-03`,`I-NUT-04` | P1 | `ai_adjust_nutrition()` overwrites the coach's prescription in place, under the coach's name, destroying `notes`; no uniqueness on the active nutrition plan, so two rows make every reader's `maybeSingle()` 406 into a default | **Q-4** | 4 |
| `I-NOT-01`,`I-NOT-02`,`I-NOT-03`,`I-NOT-05`,`I-NOT-06` | P1/P2/P3 | `messages` has no `metadata` column so **every chat image message is silently discarded after upload**; `may_notify()` rejects the community and class notifications the app sends; two triggers notify the coach of the same completed workout; `conversations` has no unique constraint on the participant pair; the `notifications.type` vocabulary has 20 producers and 8 handled cases | no | 3A |
| `I-COM-02`…`I-COM-06` | P1/P2 | The vendor attendee list throws on the same nonexistent column; **global exercise publishing has no moderation gate and the moderation tool is broken**; class capacity, waitlist and enrolment are non-functional because three RLS-scoped operations are treated as global (CRC-09); `likes_count`/`comments_count` have no writer; `toggleReaction()` races its own unique constraint | **Q-9** | 3A/7 |
| `I-WRK-02`,`I-WRK-03` | P2 | PR detection is `AFTER INSERT` only while the writer is update-then-insert; `workout_sessions.program_workout_id` has no writer — **and must not be populated before Q-7, or `generate_client_plan()`'s delete starts failing with 23503 for any client who has trained** | **Q-7** | 4 |
| `I-LEG-01`,`I-LEG-02` | P1/P2 | "A completed workout" is modelled twice and dual-written non-atomically, with disjoint readers; four relations and two columns are fully dead | **Q-11, Q-12** | 7 |
| `I-MIG-02`,`I-TYP-01`,`I-TYP-02` | P2 | Both `ALTER`-added CHECKs are `NOT VALID`, and 119's `RAISE WARNING` naming un-canonicalisable rows was never acted on; nine column names carry different types in different tables; 92 enum-like text columns, 7 constrained | no | 3A |
| `M-13` | P2 | The in-app QA Center is broken by migration 113 — it uses `select('*')` where the new policy narrows the row | no | 7 |
| `N-06`,`N-08`,`N-09`,`N-10` | P1/P2/P3 | **259 tests (37% of the Flutter suite) execute no product code**; a live logic slip in the Phase-2 swap cursor path (`_currentSetId` is `''`, never null, so the null arm is dead); 19 Edge Functions with 0 tests and no Deno runtime installed; **three services bind `Supabase.instance.client` internally, so zero behavioural coverage is possible for any of them without a seam** — three P1 findings sit behind that one structural fact | no | 8 |

---

### 7.7 Wave 1 batch amendment — 2026-08-24/25

Recorded at the Wave 1 batch custody checkpoint. Closure evidence:
[`WAVE_1_BATCH_CLOSURE.md`](WAVE_1_BATCH_CLOSURE.md). Nothing here rewrites a
historical report; the A–N reports and Wave 0 text above are unchanged.

**Status movements (batch tasks 2–9).** `REMEDIATED` = FIXED IN CODE only; the tree is
not yet committed/pushed, CI has never executed, and EB-1 still blocks the live suites,
so nothing here is `VERIFIED_CLOSED` *(status as written at the 2026-08-24 checkpoint —
the custody commit, the CI executions and EB-1's resolution are recorded in the
W1B-N6…N8 rows below and the progress-board changelog)*:

| Finding | Task | New status |
|---|---|---|
| ENV-4, `K-26` | 2 | `REMEDIATED` |
| ENV-5 | 3 | `REMEDIATED` |
| ENV-6 | 4 | `REMEDIATED` *(ci.yml has never run — commit+push required)* |
| `E-09` | 5 | `REMEDIATED` *(deployment of the block is gated by **W1B-N5** below)* |
| `LRE-34`, `REL-36`, `LRE-35` *(the reset-wrapper row inside `LRE-09…42`)* | 6 | `REMEDIATED` *(seed/link guards proven in a local container only, never against QA)* |
| REL-3 | 7 | `REMEDIATED` |
| UIX-2 *(text half only)* | 8 | `REMEDIATED` — replacement wording `REQUIRES_REVIEW` by owner (see the UIX-2 row) |
| `R-06` | 9 | `BLOCKED_ENVIRONMENT` (**EB-12**) — no Management credential; current HIBP state unverifiable read-only; premise unverified, not disproven |

**New findings.** Per §10.4: each carries an ID, a CRC from §1, and a wave.

| ID | Sev | RC | Statement | Dep | Dec | ∥ | Wave |
|---|---|---|---|---|---|---|---|
| **W1B-N1** | P1 | CRC-13 | `supabase/STRIPE_SETUP.md` instructs `supabase link --project-ref <production>` — a committed runbook that points the CLI at production. Allowlisted **with an explanatory comment** in `check-production-refs.sh` so CI is honest rather than red; the allowlist entry is a marker of the defect, not an acceptance of it | EB-5 | no | Y | 6 *(6.0 replaces the runbook with the QA Stripe runbook; remove the allowlist entry in the same change)* |
| **W1B-N2** | P2 | CRC-07 | `/admin-exercise-review` and `/vendor-portal` are registered unconditionally and their screens contain no role check (four sibling admin screens each have one). Server-side RLS is the real control, so this is attack surface + UX, not presumed exposure — confirm against Phase 1 policies, then gate the UI | — | no | Y | 2 *(RLS confirmation)* / 7 *(UI gate)* |
| **W1B-N3** | P2 | CRC-10 | `privacy_policy_screen.dart` §5 claims data export "from Profile → Settings → Account" and "in JSON or CSV format on request" — the same nonexistent path UIX-2 removed for deletion, asserted for a different right. Left standing deliberately: task 8's authority covered only the deletion half | — | **owner** (whether export ships, or the claim is corrected) | Y | 7B |
| **W1B-N4** | P3 | CRC-13 | `supabase-keepalive.yml`'s header claims the anon key "is already shipped inside the mobile app binary + `app_constants.dart`" — untrue since ENV-4. The workflow is the one production-targeting file in the tree and no batch task owns it; not edited | — | no | Y | 8 |
| **W1B-N5** | P2 | CRC-13 | `supabase config push` writes the **entire** `config.toml` to the linked project, and the file deliberately declares almost no `[auth]`/`[db]` settings — a push to deploy the new `[functions.*]` block would silently reset QA's live auth configuration to CLI defaults. Until `config.toml` is reconciled with QA's live configuration and the reconciliation is recorded, the `[functions.*]` block may be deployed **only** per function via `supabase functions deploy` (the mechanism the existing release architecture already uses). Guidance recorded in `config.toml`, `docs/qa-environments.md` and the Wave 5 prerequisites | — | no | N | **5.0 — entry precondition** |
| **W1B-N6** | P2 | CRC-14 | `check-production-refs.sh` scanned with `git grep`, which reads **tracked files only** — so `ci.yml` and `qa-db-reset.sh` passed the guard locally while untracked (custody checkpoint, 2026-08-25) and failed it in CI the moment the custody commit made them tracked (run for `9319c67`). The two flagged usages were refusal/assertion references, not executable production paths (classification B): both were rewritten in QA-allowlist form with no production literal (the ci.yml artifact scan is now strictly stronger — it fails on *any* non-QA project ref), and the guard now scans `--untracked`, demonstrated to catch what the old invocation missed. **Remediated in the same change** (2026-08-25); CI must reproduce | — | no | N | 1 *(closed with the CI-red fix)* |
| **W1B-N7** | P2 | CRC-14 | The ENV-4 inline CI check matched **documentation placeholders** as credential material: its patterns (`supabase\.co`, `pk_(test|live)_`) flagged `YOUR_QA_REF.supabase.co` and `pk_test_...` in `app_env.dart`'s usage comment, failing the `aac64b3` run's static-guards job at the step's **first-ever execution** (run 1 died at step 1, so steps 2–4 had never run — same class as W1B-N6: two tasks verified alone, integrated only in CI). Root cause: guard aimed at the wrong layer — shape-of-material was not part of the pattern. Remediated by matching **real material only** (20-char lowercase-alphanumeric project host · `eyJ`+20 token chars · `pk_(test|live)_`+24 alphanumerics) with comments still scanned — a real key pasted into a comment still fails — plus an **inline pattern self-test** asserting real-shaped fixtures match and the aac64b3 placeholder shapes do not, so a weakened pattern fails the guard itself. Residual sub-threshold coverage: the production-ref guard and the QA-artifact allowlist scan. Old check shown failing on the current file; new check passes it, catches planted real material in comments, and the self-test catches a crippled pattern arm. **Remediated in the same change** (2026-08-25); CI must reproduce | — | no | N | 1 *(closed with the ENV-4 guard fix)* |
| **W1B-N8** | P2 | CRC-14 | With EB-1's secrets finally provisioned, the live-qa job reached the security suites for the first time and all six died at import: `ids.json missing`. The file is the generated map of the four fixture-identity UUIDs, written by `setup-identities.mjs`, gitignored by design (`.gitignore:34`; W1-T1 custody manifest; README: "generated, not authored") — so an ephemeral CI checkout can never contain it. The wave plan named the setup script as part of W1-B2's QA requirements; the ci.yml implementation omitted the step — the same first-joint-execution class as W1B-N6/N7. Remediated by one creds-gated step after the exact-host QA confirmation: `node supabase/tests/security/setup-identities.mjs` (idempotent: creates-or-repairs the four `p1-*@qa.12circle.test` identities, `is_demo`, seeds three P1-FIXTURE victim rows only if absent; no deletions). **This is the programme's first sanctioned standing QA write — explicitly authorized by the product owner 2026-08-25.** Harness untouched; ids.json stays untracked. CI must reproduce | EB-1 (resolved) | owner authorization RECORDED | N | 1 *(closed with the CI step)* |
| **W1B-N9** | P3 | CRC-14 | **Test-fixture defect, not a security defect.** The first full live run scored 270/271; the one FAIL, D-02 "public signup cannot mint an admin", never reached the boundary: hosted Supabase Auth rejects example/test domains at the public `/auth/v1/signup` route (`email_address_invalid` — docs: "Example and test domains are currently not supported"), so the probe's `@qa.12circle.test` address 400s before `handle_new_user()` fires. The security contract itself is proven by the three admin-API metadata probes in the same suite (role=admin/content_manager/superuser all degrade to `client`; migration 115's clamp is source-controlled), and the suite correctly failed closed on the unexpected status rather than counting an unexercised probe as a pass. Remediated by one line (`d02-role-escalation.mjs:127`): probe address → `p1-signup-public@qa.12circlefitness.com` — the owner-confirmed controlled business domain (2026-08-25), so a confirmation email can never reach a third party; the fixed-address + pre-delete/post-delete cleanup pattern is unchanged. No assertion logic, harness, Auth configuration or other fixture touched. Closes when CI shows 271/271 | — | owner domain confirmation RECORDED | N | 1 *(closed with the fixture fix)* |

---

### 7.8 Phase 1 live-evidence reconciliation — 2026-08-26 · evidence: CI run at `6d42b10`

Owner-approved promotion record. Evidence for every row below: the green CI run at
commit `6d42b10` — live security **271/271** across the six suites (D-01 43/43 ·
D-02 40/40 · D-03 27/27 · 1D 54/54 · 1E 73/73 · 1F 34/34), live AI suite passed
(characterization level — see holds), contract suite passed (allowlist intact), overall
workflow green. The suites were written to fail against the pre-remediation database
(`supabase/tests/security/README.md`), so this run supplies **VERIFIED LIVE** and
**VERIFIED IN CI** in one artifact. Commit `d151ee6` (suite failure accounting) was
reviewed at reconciliation: reporting-only, no assertion weakened.

**Promoted to `VERIFIED_CLOSED` — 23 rows:**

| Row | From | Closing evidence at `6d42b10` |
|---|---|---|
| SEC-01 | ALREADY_FIXED | D-01 43/43 |
| SEC-02 | ALREADY_FIXED | D-02 40/40 — including, for the first time, the real public `/auth/v1/signup` route (post-W1B-N9) |
| SEC-03 | ALREADY_FIXED | D-03 27/27 |
| SEC-05 | ALREADY_FIXED | 1D 54/54. **Retained limitation:** the anon-executability probes are a finite list; the full-catalog class assertion is **Wave 2 task 2B** |
| SEC-06 | ALREADY_FIXED | 1E 73/73 |
| SEC-07 | ALREADY_FIXED | 1E 73/73 |
| SEC-10 | ALREADY_FIXED | 1F §5 |
| F-01 | ALREADY_FIXED | 1F §2 |
| F-03 | ALREADY_FIXED | 1F §4 |
| F-05 | ALREADY_FIXED | 1F §5 |
| F-06 | ALREADY_FIXED | 1F sweep |
| F-07 | ALREADY_FIXED | 1F §6 |
| F-08 | ALREADY_FIXED | 1F sweep |
| TST-1 | BLOCKED_ENVIRONMENT (EB-1) | the suite itself executed in CI — its own closure criterion |
| ENV-1 | REMEDIATED (W1-T1) | migration-hygiene guard green in CI; zero untracked engineering files |
| ENV-4 | REMEDIATED | ENV-4 static guard + env-ratchet tests + QA-bundle allowlist scan |
| ENV-5 | REMEDIATED | harness guard tests + `--untracked` production-ref guard |
| E-09 | REMEDIATED | edge-function config guard 5/5. **Deployment of the block remains gated by open W1B-N5** |
| REL-3 | REMEDIATED | `release_route_gate_test.dart` executed in CI |
| W1B-N6 | REMEDIATED | production-ref guard green in CI on the corrected tree |
| W1B-N7 | REMEDIATED | ENV-4 step green incl. its pattern self-test |
| W1B-N8 | REMEDIATED | setup-identities ran in CI; all six suites executed |
| W1B-N9 | REMEDIATED | 271/271 — its stated closure criterion |

**Deliberately NOT promoted — the row's missing evidence, exactly:** SEC-04 *(open
regression F-J-01: d04 has a documented blind spot on `materialize_program_week`'s
wrapper; needs migration 124 + I-MIG-03 class guard + live 403 probe — Wave 2)* ·
Q-4/PAR-Q closure *(SEC-R2 open: legitimate flag writes throw; needs 124 casts + live
three-flag write probe)* · SEC-09 *(REST suites cannot assert catalog `search_path`
state; `function-search-path.sql` is not wired into CI; needs FG-1 + I-MIG-03)* ·
SEC-11 and the 12 Phase 2 closures *(their live evidence is the 32-assertion workout SQL
suite, which has never run in CI; needs FG-2 — behavioural Dart halves did run)* ·
SEC-08 *(mechanical half live-verified in 1F §3; row stays open on decision Q-2)* ·
ENV-6 *(push-triggered runs proven; the row's own retest names a PR run — closes at the
first PR)* · LRE-34 / REL-36 / LRE-35 *(no CI guard exercises them; container-only
evidence)* · K-26 *(mechanical half CI-verified; row stays on D-1(L))* · UIX-2 text half
*(held uncommitted for owner wording)* · R-06 *(BLOCKED, EB-12)* · W1B-N1…N5 *(open by
design: N5 is the Wave 5.0 gate; N1→6.0, N2→2/7, N3→7B, N4→8)* · every AI-domain row
*(the AI suite pass is characterization-level; zero functions deployed — EB-2;
BLOCKED_ENVIRONMENT stands)* · every contract/3A row *(the contract suite passed **with**
the allowlist — it proves the recorded-defect state, not closure)*.

**Follow-up evidence gaps — recorded, NOT implemented (owner assignment required, no
silent scope expansion):**

| ID | Gap | Covers | Suggested home |
|---|---|---|---|
| **FG-1** | Wire `supabase/tests/security/function-search-path.sql` into the live-qa CI job with a DB-credential path | SEC-09 promotion · I-MIG-03's live half | Wave 2 (2B) |
| **FG-2** | Wire the 32-assertion workout SQL suite (`supabase/tests/workout/*.sql`) into the live-qa CI job | SEC-11 + the Phase 2 re-verification cohort | Wave 2 retest scope |

**Production statement (closure standard §6):** Production `nxdbooufqzkpslkcogxc` was not
contacted. No REST, RPC, Auth, Storage, Realtime or Edge Function request was issued to
it. No migration was applied, reverted or pushed to it. No Edge Function was deployed to
it. The linked project remained `eyqtldjqpgpljlqvpowh` throughout. This reconciliation
changed governance documents only.

---

## 8. Environment blockers

| ID | Blocker | Blocks | Owner | Wave |
|---|---|---|---|---|
| **EB-1** | `QA_SERVICE` (a scoped QA service-role key) exists in no working copy | `npm run test:security` (188 assertions), `test:ai` live half, `setup-identities.mjs`. **Phase 1's evidence cannot be re-verified, and §4.2 proves it has drifted** | whoever holds the QA keys | 1 — **RESOLVED 2026-08-25**: `QA_URL`/`QA_ANON`/`QA_SERVICE` provisioned as repository secrets; the live-qa job executed for the first time (surfacing W1B-N8) |
| **EB-2** | Zero Edge Functions deployed to QA; `supabase secrets list` → `{"secrets":[]}` | Every AI, payment, invite and enrichment surface. 10 of J's findings and the whole of D's smoke matrix | DevOps | 5 |
| **EB-3** | QA Vault `project_url` / `service_role_key` unset | The coaching crons (fail-closed, correctly, so they are inert). **QA values only — the migration comment exists because a production URL was once pasted in** | DevOps | 5 |
| **EB-4** | Intelligence substrate unpopulated (0 profiles / 621 exercises; 0 graph nodes and edges) | Any real engine decision; AI-5, F-J-09, F-J-22 | Content owner + **D-1** | 5 |
| **EB-5** | No Stripe test-mode account, QA webhook endpoint, QA signing secret, or five QA price ids; `STRIPE_PK` empty in `qa.json`; the runbooks name **production only** and there is no QA equivalent | Every dynamic billing assertion in Workstream K. The embedded-checkout path is untestable in the only safe environment | DevOps + finance | 6 |
| **EB-6** | `API_BASE_URL` empty in every environment; the NestJS API runs nowhere | The AI Nutrition Coach in **all** environments | **D-2(L)** | 1/5 |
| **EB-7** | Resend sender domain unset — the default delivers **only** to the Resend account owner | Every email test is a silent no-op against any other recipient | DevOps | 5 |
| **EB-8** | No Deno runtime; no `deno.json`, import map or lockfile in `supabase/` | Any Edge Function test. **Standing up `deno test` with mocked `fetch` would convert two-thirds of D's smoke matrix into CI** | DevOps | 8 |
| **EB-9** | No runtime UI harness — no integration-test driver, no device | Every UI finding in M is static + query-replay evidence; none was observed on a running screen | QA | 9 |
| **EB-10** | No QA content-editor or coach credential available to the workstreams | Re-measuring the exercise library, the certification pipeline, and the coach half of H-06 | whoever holds the QA keys | 5 |
| **EB-11** | No staging environment and no `dart_defines/staging.json` | Gate 2 in its entirety. **Beta is currently undefined** (D-4 in L) | release engineering | 8 |
| **EB-12** *(added 2026-08-24, Wave 1 batch)* | No Supabase Management API credential in any working copy, and `GET /auth/v1/settings` does not expose HIBP state — the CLI's keychain token is off-limits per governance | `R-06` (leaked-password protection). One dashboard action by the owner: QA project → Authentication → Policies → enable "Prevent use of leaked passwords", then record before/after in `WAVE_1_BATCH_CLOSURE.md` §3 | product owner / DevOps | 1 |

---

## 9. Production exposure register

Production `nxdbooufqzkpslkcogxc` was **not contacted** by this reconciliation or by any
workstream. Everything here is **UNVERIFIABLE** and derived from source. It is recorded
so the rollout plan has an input; **nothing here is authorization to act.**

| # | Exposure | Evidence class |
|---|---|---|
| 1 | **SEC-01…SEC-05 are live in production.** They are properties of the migration source. 113–122 close them on QA only | SRC |
| 2 | Migrations `083/084/086/087/090/091/097/099` state in their own headers that they were *never applied in any environment* before their in-place correction. **Production therefore probably has no content pipeline, no certification view, no `exercise_intelligence` table and no per-attribute review** — the largest single schema divergence in the product | SRC |
| 3 | 076's `B2-6` correction and its Vault-based cron retarget **do not self-apply** to an environment that already ran the old 076. Production may still POST to production Edge Functions from a cron created by a QA replay, and `ai_cron_generate` raises on every scheduled run once Vault is configured | SRC |
| 4 | Migration 109 (`auth.users` trigger) is deliberately not auto-applied. It is written name-agnostic and idempotent, so it is safe — applying it is a separate decision | SRC |
| 5 | Migration 102 must not reach production until every beta build reads display names from `public_profiles` / `conversation_participant_profiles` — **and H-06 proves five surfaces still do not** | SRC + LIVE |
| 6 | `dietary_restrictions` is `text` on QA; the in-code comment asserts the live column is `text[]`, implying an out-of-band production change. **Q-6** | LIVE (QA) + UNVERIFIABLE (prod) |
| 7 | `supabase/STRIPE_CONNECT_SETUP.md` claims `stripe-connect`, `create-checkout` and `stripe-webhook` are "already deployed" — a documentation assertion of unknown age. **If true, E-06, E-07, K-01 and E-14 are live in production today, and K-01 is a financial defect** | UNVERIFIABLE |
| 8 | The production Stripe slot holds a `pk_test_` publishable key. Either real money has never moved, or the constant is wrong. **D-1(L)** determines whether existing subscription records are real | SRC |
| 9 | Production's `supabase_migrations.schema_migrations` has never been dumped or reconciled against source | UNVERIFIABLE |
| 10 | The daily keep-alive GitHub workflow is the **only** automation that contacts production, and it is the only workflow in the repository | SRC-V |

---

## 10. How to use this registry

1. **Never mark `VERIFIED_CLOSED` from a code diff.** The evidence ladder in
   `QA_CLOSURE_STANDARD.md` is mandatory and has five distinct states.
2. **Update the row, not a report.** The A–N reports are frozen evidence. When a finding
   moves, this file and `REMEDIATION_PROGRESS.md` move.
3. **A regression re-opens a row; it does not create one.** §4.2 is the pattern. Add the
   regressing change to the row's evidence and reset the status.
4. **A new finding needs an ID, a root cause from §1, and a wave.** If it does not map to
   a CRC, that is a signal the root-cause model is incomplete — extend §1 deliberately
   rather than filing an orphan.
5. **The alias map (§3) is closed.** Do not resurrect a retired ID.

**Companion documents:** [`MASTER_REMEDIATION_WAVES.md`](MASTER_REMEDIATION_WAVES.md) ·
[`MASTER_PRODUCT_DECISIONS.md`](MASTER_PRODUCT_DECISIONS.md) ·
[`RELEASE_GATES.md`](RELEASE_GATES.md) ·
[`QA_CLOSURE_STANDARD.md`](QA_CLOSURE_STANDARD.md) ·
[`REMEDIATION_PROGRESS.md`](REMEDIATION_PROGRESS.md)
