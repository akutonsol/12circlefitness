# 12 Circle Fitness — Remediation Progress Board

**Running status. Updated on every status change.**
**Last updated:** 2026-08-24 · **Wave 0 complete, no implementation begun**

> **Update rules.** A status change here must be accompanied by the matching change in
> [`MASTER_REMEDIATION_REGISTRY.md`](MASTER_REMEDIATION_REGISTRY.md) and by the evidence
> [`QA_CLOSURE_STANDARD.md`](QA_CLOSURE_STANDARD.md) requires for that finding's class.
> **This board never leads the registry.**

---

## 1. Programme status

| | |
|---|---|
| **Current wave** | **0 — Reconciliation · COMPLETE** |
| **Next wave** | **1 — Custody, Environment & Release Safety** |
| **Next action** | **W1-T1 — commit the working tree. Alone, first, blocking** |
| **Highest gate met** | **none.** Gate 0 is not mechanized; `.github/workflows/` holds one file, a production keep-alive ping |
| **Production contact** | **none, by any wave, at any point** |
| **Blocking on** | 8 critical-path decisions (§5) and 11 environment blockers (§6) |

---

## 2. Wave board

| Wave | Name | Status | Findings | Entry met? | Exit gate |
|---|---|---|---|---:|---|
| **0** | Reconciliation | ✅ **COMPLETE** | 310 catalogued | — | — |
| **1** | Custody, Environment & Release Safety | ⬜ **READY — start here** | 22 | ✅ yes | Gate 0, Gate 1 (partly) |
| **2** | Security Regression & Boundary Re-assertion | ⬜ blocked on Wave 1 | 9 | ❌ needs Wave 1 + EB-1 | Gate 2 (security) |
| **3A** | Schema-contract truth | ⬜ blocked on Wave 1 | 21 | ❌ | Gate 1 |
| **3B** | Error contract | ⬜ blocked on 3A | 26 | ❌ | Gate 2 (error) |
| **3C** | Fabrication removal | ⬜ blocked on 3B | 6 | ❌ · needs PD-B09, PD-B13 | Gate 2 |
| **4** | Core Member Journey | ⬜ blocked | 34 | ❌ · needs PD-B01, PD-B02, PD-B03, PD-B04, PD-B21 | Gate 2 (journey) |
| **5** | AI / Intelligence | ⬜ blocked | 64 | ❌ · needs EB-2/3/4/7, PD-A02, PD-D01, PD-D08, PD-A07 | Gate 3 |
| **6** | Billing & Entitlements | ⬜ blocked | 35 | ❌ · needs EB-5, PD-E01…PD-E08 | Gate 4 |
| **7** | Secondary Surfaces & Compliance | ⬜ blocked | 61 | ❌ · needs PD-B*, PD-D03…PD-D06, PD-F03 | Gate 4 |
| **8** | Testing Maturity & Release Engineering | ⬜ blocked | 48 | ❌ · needs EB-8, EB-11, PD-A17, PD-A25, PD-A26, PD-F04 | Gates 5, 7, 8 |
| **9** | Manual QA Gate | ⬜ blocked | — | ❌ · needs Gates 0–5 | Gate 6 |
| **10** | Production rollout | ⬜ blocked · **requires separate explicit authorization** | — | ❌ | Gate 9 |

---

## 3. Status counts

| Status | Count | Note |
|---|---:|---|
| `DISCOVERED` | 0 | all triaged in Wave 0 |
| `DUPLICATE` | 118 | collapsed; see registry §3. **Retired IDs must not be used as tracking keys** |
| `ALREADY_FIXED` | 52 | Phase 1 (24) + Phase 2 (12) + other (16). **None is `VERIFIED_CLOSED`** — see §4 |
| `FIX_IN_PROGRESS` | 0 | |
| `BLOCKED_DECISION` | 47 | 31 of these have a mechanical half that is **not** blocked |
| `BLOCKED_ENVIRONMENT` | 24 | |
| `READY_TO_REMEDIATE` | 187 | 22 of them are Wave 1 |
| `REMEDIATED` | 0 | |
| `RETEST_REQUIRED` | 0 | |
| **`VERIFIED_CLOSED`** | **0** | **and none can be until Gate 0 is mechanized** |
| `DEFERRED` | 0 | |
| `RELEASE_BLOCKER` | 56 | a gate attachment, not a severity — counted inside the rows above |
| **Canonical total** | **310** | from 428 raw records |

| Severity | Open | Fixed | Total |
|---|---:|---:|---:|
| **P0** | 42 | 12 | 54 |
| **P1** | 111 | 18 | 129 |
| **P2** | 121 | 14 | 135 |
| **P3** | 63 | 8 | 71 |
| **Total** | **337** | **52** | *(389 — exceeds 310 because 79 findings are counted at both a fixed-half and an open-half severity; each split is stated in its row)* |

---

## 4. Why nothing is `VERIFIED_CLOSED`

52 findings are `ALREADY_FIXED`. **None qualifies for `VERIFIED_CLOSED`,** and the reason
is the same for all of them:

- Their live evidence — 270 assertions for Phase 1, 20 for Phase 2 — was captured at a
  point in time and **has not been re-run since.** `npm run test:security` requires
  `QA_SERVICE`, which exists in no working copy (**EB-1**), and it runs in no CI
  (**ENV-6**).
- The posture has demonstrably drifted since: **five closed findings regressed**, three of
  them introduced by the very migrations that closed other findings (registry §4.2).

`ALREADY_FIXED` is therefore the honest state. It becomes `VERIFIED_CLOSED` in Wave 1,
when the suites execute in CI for the first time — **not before, and not by assertion.**

---

## 5. Decision board

**8 of 73 are on the critical path.** Nothing in Waves 1, 2, 3A or 3B is blocked by any of
them — that was deliberate in the sequencing.

| Rank | Decision | Owner | Status | Stalls |
|---:|---|---|---|---|
| 1 | **PD-D08** — name a clinical owner | Julia | ⬜ **open · take this first** | Wave 5.7 |
| 2 | **PD-B01 + PD-B02** — daily vs weekly check-in; the canonical column family | Julia | ⬜ open | Wave 4 (12 findings) |
| 3 | **PD-A02** — the certification predicate | Julia + clinical | ⬜ open | Wave 5.2 · *and whether the substrate bootstrap is safe at all* |
| 4 | **PD-D01** — PAR-Q policy | **Clinical** | ⬜ open | Wave 5.7 |
| 5 | **PD-A17 + PD-A10** — where the API runs; which nutrition backend is canonical | Julia | ⬜ open | Waves 1 and 5 |
| 6 | **PD-A26 + PD-A25** — PITR vs forward-only; what beta is | Julia | ⬜ open | Wave 8, the whole rollout chain |
| 7 | **PD-F02** — launch platform | Julia | ⬜ open | whether PD-F01's weeks of IAP work are on the critical path |
| 8 | **PD-E07 + PD-E08** — is production billing real; which tier ladder is the target | Julia | ⬜ open | Wave 6 |

**Answered: 3** — Q-A (the engine prescribes), Q-B (End Workout semantics), and three
questions that turn out to be settled by `product-bible.md` §6 and `decision-log.md` and
are therefore **findings, not decisions** (decisions doc §0.2).

**Open: 73** — A:26 · B:27 · C:5 · D:8 · E:8 · F:4 · G:4 *(some groups overlap where a
decision needs two authorities).*

---

## 6. Environment blocker board

| ID | Blocker | Owner | Status | Blocks |
|---|---|---|---|---|
| **EB-1** | No `QA_SERVICE` key in any working copy | QA key holder | ⬜ **open · highest-value unblock** | 188 live assertions; every security closure |
| **EB-2** | Zero Edge Functions deployed to QA; `secrets: []` | DevOps | ⬜ open | Wave 5 entire |
| **EB-3** | QA Vault `project_url` / `service_role_key` unset | DevOps | ⬜ open | the coaching crons |
| **EB-4** | Intelligence substrate empty — 0 profiles / 621 exercises, 0 graph nodes | Content + PD-A02 | ⬜ open | any real engine decision |
| **EB-5** | No QA Stripe account, runbook, endpoint, secret or price ids | DevOps + finance | ⬜ open | Wave 6 entire |
| **EB-6** | `API_BASE_URL` empty everywhere; the API runs nowhere | PD-A17 | ⬜ open | the AI Nutrition Coach in all environments |
| **EB-7** | Resend sender domain unset — mail reaches only the account owner | DevOps | ⬜ open | every email test |
| **EB-8** | No Deno runtime; no `deno.json` in `supabase/` | DevOps | ⬜ open | all 19 Edge Function tests |
| **EB-9** | No runtime UI harness — no driver, no device | QA | ⬜ open | every UI finding's end-to-end evidence |
| **EB-10** | No QA content-editor or coach credential | QA key holder | ⬜ open | library re-measurement, H-06 coach half |
| **EB-11** | No staging environment, no `dart_defines/staging.json` | Release eng | ⬜ open | Gate 5 entire |

---

## 7. Gate board

| Gate | Rows | Met | Status |
|---|---:|---:|---|
| **Gate 0** — Merge to `main` | 14 | **0** | ❌ no CI exists |
| **Gate 1** — QA promotion / contract truth | 9 | 0 | ❌ |
| **Gate 2** — Security & error contract | 13 | 0 | ❌ · *row 2.2 has never executed* |
| **Gate 3** — AI enablement | 15 | 0 | ❌ · EB-2, EB-3, EB-4 |
| **Gate 4** — Commerce enablement | 14 | 0 | ❌ · EB-5 |
| **Gate 5** — RC → staging | 13 | 0 | ❌ · EB-11 |
| **Gate 6** — Manual QA sign-off | 8 | 0 | ❌ |
| **Gate 7** — TestFlight internal | 9 | 0 | ❌ |
| **Gate 8** — TestFlight external | 9 | 0 | ❌ |
| **Gate 9** — Submission → rollout | 15 | 0 | ❌ · **requires separate explicit authorization** |

---

## 8. Baselines — the numbers a regression is measured against

Measured **2026-08-24 in this session**, against the current working tree.

| Suite | Command | Result |
|---|---|---|
| Flutter | `cd apps/mobile && flutter test` | **730 passed · 9 skipped · 0 failed** |
| Flutter analyzer | `flutter analyze` | 0 errors · 15 warnings · 156 infos |
| API unit | `npm test --workspace apps/api` | 58 passed |
| API e2e | `npm run test:e2e --workspace apps/api` | 6 passed |
| Schema contract | `npm run test:contract` | exists · 2 relations + 8 columns allowlisted |
| **Live security** | `npm run test:security` | **NOT RUN — no `QA_SERVICE` (EB-1). 188 assertions across 6 suites** |
| **Live AI** | `npm run test:ai` | **NOT RUN — EB-1 / EB-2. 5 suites** |
| **Live workout SQL** | `supabase db query --file supabase/tests/workout/*.sql` | **NOT RUN — no credentials. 32 assertions** |
| **Edge Function** | *(none exist)* | **0 — no Deno runtime (EB-8)** |

> **Every count quoted in a workstream report — 514 / 591 / 623 / 667 / 690 / 699 — is a
> snapshot of a tree that several sessions were writing to concurrently. `730 / 9 / 0` is
> the Wave 0 baseline. No count below 730 is a regression signal on its own.**

### 8.1 Suite composition — the number that matters more than the total

| Class | Tests | Share | Proves |
|---|---:|---:|---|
| Behavioural — runs the real code | 268 | 38% | the product behaves as asserted |
| Static source guards | 172 | 25% | the committed source cannot express a known hole |
| **Replica / self-referential** | **259** | **37%** | **nothing about the product** |

*(Measured by Workstream N at 699 total; the 31 tests added since have not been
reclassified. Replica conversion is Wave 8 item 8 — **convert, never delete**.)*

---

## 9. Working-tree custody — the standing risk

**This is the programme's single largest exposure and it is unchanged since Workstream L
reported it.**

| Item | Count | Status |
|---|---:|---|
| Untracked migrations — incl. **113–118** (all Phase 1 security) and **119–122** (all Phase 2 contract) | **20** | ⬜ **at risk** |
| Historical migrations edited in place | **15** | ⬜ at risk — production cannot receive their corrections |
| Untracked test files — incl. every Dart security guard | **22** | ⬜ at risk |
| Untracked production source the app will not compile without — `workout_restoration.dart`, `workout_contract.dart` | **2** | ⬜ at risk |
| Untracked A–N reports and Wave 0 artifacts | **24** | ⬜ at risk |

**One `git clean -fd` destroys the entire remediation programme.** W1-T1 exists to close
this and it is the first action of Wave 1.

---

## 10. Regression watch

Permanently visible. A closed regression stays listed with its guard.

| ID | Regressed | By | Guard that should have caught it | Status |
|---|---|---|---|---|
| **F-J-01** | SEC-04's authorization guard on `materialize_program_week` | migration 119 | none existed — `d04` asserted 4 of 5 wrappers individually rather than the class | ⬜ **open** · Wave 2 |
| **F-J-17** | PAR-Q server-authority, by making risk unrecordable | migration 115 itself | no test executed `derive_parq_risk`; `SEC-023` pins its *text* | ⬜ open · Wave 2 |
| **F-J-07** | `build_workout`'s under-recovery rule | migration 089 | no engine test exists at all (`ENG-20`) | ⬜ open · Wave 2 |
| **EC-05 / N-07** | WKA-04, the orphaned `in_progress` session, through the error path | pre-existing; unchanged by Phase 2 | `EC-G1` **does not read `active_workout_screen.dart`** | ⬜ open · Wave 3B |
| **EC-11** | WRK-07 — the swallow moved one layer down | pre-existing service layer | `EC-G1` reads only `workout_provider.dart` | ⬜ open · Wave 3B |

**Class fix — `I-MIG-03`, Wave 2:** generalise `SEC-027` so that no migration may redefine
a function carrying an authorization wrapper, a `search_path` pin or a security trigger
without carrying them forward. **This is the only reason to expect the next
Phase-1-equivalent to hold.**

---

## 11. First parallel batch — task board

Wave 1's opening batch. Full justification in
[`MASTER_REMEDIATION_WAVES.md`](MASTER_REMEDIATION_WAVES.md) §"First safe parallel batch".

| # | Task | Findings | Owner | Status |
|---:|---|---|---|---|
| 1 | **Commit the tree** — 4 reviewable slices | ENV-1 | release eng | ⬜ **do first, alone** |
| 2 | `APP_ENV` → `dev`; prod constants out of the binary; ENV-012 inverted | ENV-4, `K-26` | mobile | ⬜ after 1 |
| 3 | Three harnesses take their target from env and refuse production | ENV-5 | mobile | ⬜ after 1 |
| 4 | `ci.yml` | ENV-6 | release eng | ⬜ after 1 |
| 5 | `[functions.*] verify_jwt` per function | `E-09` | backend | ⬜ after 1 |
| 6 | `.temp` untracked; seed guard refuses a non-QA ref | `LRE-34`, `REL-36` | release eng | ⬜ after 1 |
| 7 | Release-mode route gate | REL-3 | mobile | ⬜ after 1 |
| 8 | Correct the false account-deletion claims | UIX-2 text half | mobile | ⬜ after 1 |
| 9 | Leaked-password protection on QA | `R-06` | DevOps | ⬜ anytime |

**Deliberately excluded from the first batch** — each is defensible and each is wrong:
migration 123 *(one analytical act, one owner, sequential)*; migration 124 *(numbers are
assigned; 123 lands first)*; the five schema column renames *(they share
`known-violations.json`, and three of them land in one file — they are the first batch of
Wave 3A, sequenced behind CI so the ratchet has something to enforce against)*.

---

## 12. Change log

| Date | Change |
|---|---|
| 2026-08-24 | **Wave 0 complete.** 428 raw records reconciled to 310 canonical findings; 118 aliases retired; 14-cause root-cause model established; **5 regressions identified, 3 of them introduced by the migrations that closed other findings**; 52 findings confirmed `ALREADY_FIXED` and **none promoted to `VERIFIED_CLOSED`**; 73 decisions extracted; 11 environment blockers named; 10 gates defined; baseline re-measured at **730/9/0**. Six artifacts created. **No code, migration, test or configuration changed. No environment contacted.** |
| 2026-08-24 | **New finding, from Wave 0 rather than from A–N:** the approved `ROADMAP_AI_MONETIZATION_UNIT_ECONOMICS.md` commercial architecture and the implemented tier ladder do not match. Filed as **PD-E08** |
| 2026-08-24 | **Three questions retired as already-answered** by `product-bible.md` §6 and `decision-log.md`: the engine's certification gate, LLM-derived `intensity_delta`, and the coach approval matrix. Each is reclassified from *open decision* to *contract violation* |
