# 12 Circle Fitness — Remediation Progress Board

**Running status. Updated on every status change.**
**Last updated:** 2026-08-25 · **Wave 0 complete · W1-T1 complete · Wave 1 batch tasks 2–8 REMEDIATED (task 9 blocked, EB-12) · custody commit pending**

> **Update rules.** A status change here must be accompanied by the matching change in
> [`MASTER_REMEDIATION_REGISTRY.md`](MASTER_REMEDIATION_REGISTRY.md) and by the evidence
> [`QA_CLOSURE_STANDARD.md`](QA_CLOSURE_STANDARD.md) requires for that finding's class.
> **This board never leads the registry.**

---

## 1. Programme status

| | |
|---|---|
| **Current wave** | **1 — Custody, Environment & Release Safety · IN PROGRESS** |
| **Completed** | Wave 0 · **W1-T1 (custody) — COMPLETE**, see §12 · **Batch tasks 2–8 — REMEDIATED (uncommitted)**, task 9 **BLOCKED** (EB-12), see §11 and [`WAVE_1_BATCH_CLOSURE.md`](WAVE_1_BATCH_CLOSURE.md) |
| **Next action** | **Custody commit checkpoint of the batch** (owner, locally, in the prepared slices — task 8's wording needs owner approval first) → push so `ci.yml` executes for the first time → EB-1/EB-12 owner actions → **then W1-T2 (migration 123) and W1-T3 (QA ledger), sequentially** |
| **Highest gate met** | **none.** Gate 0 is not mechanized; `.github/workflows/` holds one file, a production keep-alive ping |
| **Production contact** | **none, by any wave, at any point** |
| **Blocking on** | 8 critical-path decisions (§5) and 12 environment blockers (§6) |

---

## 2. Wave board

| Wave | Name | Status | Findings | Entry met? | Exit gate |
|---|---|---|---|---:|---|
| **0** | Reconciliation | ✅ **COMPLETE** | 310 catalogued | — | — |
| **1** | Custody, Environment & Release Safety | 🟨 **IN PROGRESS** — W1-T1 done · batch tasks 2–8 REMEDIATED (custody commit pending) · task 9 blocked (EB-12) · spine W1-T2/W1-T3 remain | 22 (+5 new, §11a) | ✅ yes | Gate 0, Gate 1 (partly) |
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
| `BLOCKED_DECISION` | 48 | 31 have a mechanical half that is **not** blocked · +1: W1B-N3 |
| `BLOCKED_ENVIRONMENT` | 25 | +1: `R-06` → EB-12 (batch task 9) |
| `READY_TO_REMEDIATE` | 182 | −8 batch REMEDIATED, −1 `R-06` blocked, +4 new (W1B-N1/N2/N4/N5) |
| `REMEDIATED` | 10 | ENV-4, `K-26`, ENV-5, ENV-6, `E-09`, `LRE-34`, `REL-36`, REL-3, **W1B-N6**, **W1B-N7** *(plus the UIX-2 text half and `LRE-35` inside the `LRE-09…42` aggregate, counted at their parent rows)* — **FIXED IN CODE, uncommitted; see registry §7.7** |
| `RETEST_REQUIRED` | 0 | |
| **`VERIFIED_CLOSED`** | **0** | **and none can be until the batch is committed, pushed, and ci.yml executes (then EB-1 for the live rows)** |
| `DEFERRED` | 0 | |
| `RELEASE_BLOCKER` | 56 | a gate attachment, not a severity — counted inside the rows above |
| **Canonical total** | **317** | 310 from 428 raw records + **7 Wave 1 batch discoveries** (W1B-N1…N7, registry §7.7; N6 and N7 filed and remediated 2026-08-25) |

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
| **EB-12** | No Management API credential; HIBP state not exposed read-only. One owner dashboard action: QA → Authentication → Policies → "Prevent use of leaked passwords", record before/after | Product owner / DevOps | ⬜ **open · added by Wave 1 batch** | `R-06` (task 9) |

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

**Post-batch (2026-08-24, [`WAVE_1_BATCH_CLOSURE.md`](WAVE_1_BATCH_CLOSURE.md)):**
`flutter test` **750 / 9 / 0** (20 net-new tests, each shown failing against the restored
defect) · analyze 0 errors · API 58 + 6 · `npm run check:guards` 10/10. Measured by the
batch session against the uncommitted tree; **becomes the standing baseline only when
ci.yml reproduces it after the custody commit.** The three static guards were
independently re-run at the custody checkpoint (2026-08-25) and pass.

### 8.1 Suite composition — the number that matters more than the total

| Class | Tests | Share | Proves |
|---|---:|---:|---|
| Behavioural — runs the real code | 268 | 38% | the product behaves as asserted |
| Static source guards | 172 | 25% | the committed source cannot express a known hole |
| **Replica / self-referential** | **259** | **37%** | **nothing about the product** |

*(Measured by Workstream N at 699 total; the 31 tests added since have not been
reclassified. Replica conversion is Wave 8 item 8 — **convert, never delete**.)*

---

## 9. Working-tree custody — **CLOSED by W1-T1**

**Resolved 2026-08-24.** The programme is now represented in Git across five commits.

| Item | Wave 0 said | Actual | Status |
|---|---:|---:|---|
| Untracked migrations — incl. **113–118** (all Phase 1) and **119–122** (all Phase 2) | 20 | **20** | ✅ tracked |
| Historical migrations edited in place | 15 | **15** | ✅ tracked, isolated in one commit |
| Untracked Dart test files | 22 | **20** | ✅ tracked |
| Untracked Supabase QA harnesses | *not counted* | **25** | ✅ tracked |
| Untracked production source the app will not compile without | 2 | **2** | ✅ tracked |
| Untracked documents | 18 | **29** | ✅ tracked |
| **Total** | **62** | **96** | ✅ **0 untracked non-ignored files remain** |

**⚠ Wave 0 undercounted by 34 files.** `git status` collapses a wholly-untracked directory
into a single entry, and Wave 0 counted status lines rather than files. `supabase/tests/` —
25 files holding **every live security and AI probe in the repository** — appeared as one
line. Full correction in
[`WORKING_TREE_CUSTODY_MANIFEST.md`](WORKING_TREE_CUSTODY_MANIFEST.md) §1.1.

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
| 1 | **Commit the tree** — 5 reviewable slices (§12) | ENV-1 | release eng | ✅ **COMPLETE** |
| 2 | `APP_ENV` → `dev`; prod constants out of the binary; ENV-012 inverted | ENV-4, `K-26` | mobile | ✅ **REMEDIATED** (2026-08-24) |
| 3 | Three harnesses take their target from env and refuse production | ENV-5 | mobile | ✅ **REMEDIATED** (2026-08-24) |
| 4 | `ci.yml` | ENV-6 | release eng | ✅ **REMEDIATED** — has never executed; first run requires the custody commit + push |
| 5 | `[functions.*] verify_jwt` per function | `E-09` | backend | ✅ **REMEDIATED** — deployment gated by **W1B-N5** (never `config push`) |
| 6 | `.temp` untracked; seed guard refuses a non-QA ref | `LRE-34`, `REL-36` | release eng | ✅ **REMEDIATED** — guards proven in a local container only |
| 7 | Release-mode route gate | REL-3 | mobile | ✅ **REMEDIATED** (incl. recorded affordance-gating scope extension) |
| 8 | Correct the false account-deletion claims | UIX-2 text half | mobile | 🟨 **REMEDIATED · wording REQUIRES_REVIEW** — replacement text promises an email deletion path (30-day window) with no recorded owner decision; **held for owner approval before commit** |
| 9 | Leaked-password protection on QA | `R-06` | DevOps | ⛔ **BLOCKED — EB-12.** Preserved; HIBP state unverified, not disproven. Owner dashboard action + recorded before/after required |

Closure evidence: [`WAVE_1_BATCH_CLOSURE.md`](WAVE_1_BATCH_CLOSURE.md). Statuses are
`REMEDIATED` (FIXED IN CODE), **not** `VERIFIED_CLOSED` — the tree is uncommitted, CI has
never run, and EB-1 still blocks the live suites.

### 11a. Wave 1 batch discoveries

Five new findings, **W1B-N1…W1B-N5**, registered in
[`MASTER_REMEDIATION_REGISTRY.md`](MASTER_REMEDIATION_REGISTRY.md) §7.7 with root causes
and waves. **W1B-N5 is a Wave 5.0 entry precondition:** the `[functions.*]` block may be
deployed only per function via `supabase functions deploy` — never `supabase config
push` — until `config.toml` is reconciled with QA's live configuration.

**Deliberately excluded from the first batch** — each is defensible and each is wrong:
migration 123 *(one analytical act, one owner, sequential)*; migration 124 *(numbers are
assigned; 123 lands first)*; the five schema column renames *(they share
`known-violations.json`, and three of them land in one file — they are the first batch of
Wave 3A, sequenced behind CI so the ratchet has something to enforce against)*.

---

## 12. W1-T1 — working-tree custody · **COMPLETE**

**Completed 2026-08-24.** Full inventory and rationale:
[`WORKING_TREE_CUSTODY_MANIFEST.md`](WORKING_TREE_CUSTODY_MANIFEST.md).

### The five commits

| # | Hash | Files | Commit |
|---:|---|---:|---|
| 1 | `f8f4490` | 30 | `docs: place the QA remediation programme under version control` |
| 2 | `2b3d857` | 20 | `db: track migrations 000 and 104-122, including all Phase 1 and Phase 2 work` |
| 3 | `99492df` | 25 | `db: track the in-place migration corrections, seed rebuild and QA CLI link` |
| 4 | `11fbc6a` | 20 | `app: track the workout-contract source, including two files the build requires` |
| 5 | `8e47f07` | 52 | `test: track every standing guard and QA harness in the programme` |
| | **total** | **147** | on top of `39ca39c` |

**Five slices, not the four Wave 0 proposed.** The 20 *new* migrations and the 15
*in-place-edited* ones were separated. Finding **ENV-2** (P0) requires enumerating the
semantic delta of each of the 15 for forward migration 123 — isolated, `git show 99492df`
**is** that enumeration input, permanently. Mixed into a 35-file commit it would have to be
re-derived at every review.

### Included

Wave 0 orchestration artifacts (6) · A–N evidence reports (14) · phase artifacts (6) ·
approved roadmaps (2) · migrations `000` and `104`–`122` (20, incl. all of Phase 1 and
Phase 2) · the 15 in-place-edited migrations · seeds (2) · `config.toml` · `.temp` CLI link
(7) · application source (18, incl. the 2 compilation-critical files) · `dart_defines/qa.json` ·
`ai-generate-workout/index.ts` · Dart guards (20) · Supabase QA harnesses (25) ·
`package.json` · `.gitignore`.

### Intentionally excluded — **left on disk, nothing deleted**

`dist/`, `apps/api/dist/`, `apps/mobile/build/`, `.dart_tool/`, `node_modules/` (build
output and caches) · `.env`, `.env.local`, `apps/api/.env` (local secrets — verified
ignored, and **no `.env` file is tracked**) · `supabase/tests/security/ids.json` (generated
fixture identities, newly ignored) · `.claude/settings.local.json` ·
`supabase/.temp/cli-latest`.

### Remaining untracked non-ignored files

**Zero.** `git status --short` is empty; `git diff HEAD --stat` is empty.

### Anomalies found during custody

1. **Wave 0 undercounted the untracked set by 34 files** — 62 reported, **96** actual.
   `git status` collapses a wholly-untracked directory into one entry and Wave 0 counted
   status lines. **`supabase/tests/` — 25 files holding every live security and AI probe —
   was counted as a single item.** Corrected here and in §9.
2. **`supabase/.temp/` was tracked *and* ignored.** `.gitignore:29` carries `**/.temp/`,
   but the eight files predate it and a tracked file overrides its ignore rule — `LRE-34`
   confirmed exactly as reported. Committing them **removed six production references and
   added none**: they move the CLI link from the production project to QA. Left
   uncommitted, a `git checkout` would have restored the **production** link. Untracking
   them properly is Wave 1 batch task 6.
3. **The seed diffs introduce QA fixture-account passwords not present in `HEAD`.** Three
   bcrypt-hashed literals for seeded fixture accounts; two are already published in
   `docs/`. Not production or third-party credentials. The real exposure is **`REL-36`** —
   `config.toml` runs the seeds on `supabase db reset` and nothing yet refuses a non-QA
   project ref. **`REL-36` is raised P2 → P1** and pulled into the Wave 1 batch.
4. **Two credential-shaped literals were found and cleared.** Both decode to
   `role=anon` — a QA publishable key in `dart_defines/qa.json`, and the pre-existing
   production publishable key in `tool/live_integration_test.dart` (which is finding
   `ENV-5`, unchanged and committed as-is). **No `service_role` key, no `sk_live_`/
   `sk_test_`, no `whsec_`, no `sk-ant-`, and no connection string with a password appears
   anywhere in the committed set.** Twelve further matches on the *name* `service_role_key`
   were each inspected and are Vault secret names, guard-test regexes or report prose.

### Verification

| Check | Result |
|---|---|
| `git status --short` | **empty** |
| `git diff HEAD --stat` | **empty** |
| Untracked non-ignored files | **0** |
| All 146 pre-existing candidates tracked | **yes, 0 missing** |
| `flutter test` | **730 passed · 9 skipped · 0 failed** — identical to the pre-custody baseline |
| `npm run test:api` | **58 + 6 passed** |
| Work lost | **none.** No reset, stash, clean, checkout, revert, delete or overwrite was performed |
| Production contacted | **no** |
| Any environment contacted | **no** |

*Commits 1–4 are not individually test-green: slice 4 lands application changes whose
matching test updates arrive in slice 5. This is correct for a custody split, which
optimises for recoverability, not for a green build at every intermediate SHA. Only `HEAD`
is asserted green, and it is.*

---

## 13. Change log

| Date | Change |
|---|---|
| 2026-08-24 | **Wave 0 complete.** 428 raw records reconciled to 310 canonical findings; 118 aliases retired; 14-cause root-cause model established; **5 regressions identified, 3 of them introduced by the migrations that closed other findings**; 52 findings confirmed `ALREADY_FIXED` and **none promoted to `VERIFIED_CLOSED`**; 73 decisions extracted; 11 environment blockers named; 10 gates defined; baseline re-measured at **730/9/0**. Six artifacts created. **No code, migration, test or configuration changed. No environment contacted.** |
| 2026-08-24 | **New finding, from Wave 0 rather than from A–N:** the approved `ROADMAP_AI_MONETIZATION_UNIT_ECONOMICS.md` commercial architecture and the implemented tier ladder do not match. Filed as **PD-E08** |
| 2026-08-24 | **W1-T1 complete.** 147 files placed under version control in five reviewable commits (`f8f4490`, `2b3d857`, `99492df`, `11fbc6a`, `8e47f07`). Working tree clean, zero untracked non-ignored files, suites at baseline (730/9/0 and 58+6). Wave 0's custody count corrected from 62 to **96**. `REL-36` raised P2 → P1. **Nothing deleted, reverted or discarded; no environment contacted.** |
| 2026-08-24 | **Three questions retired as already-answered** by `product-bible.md` §6 and `decision-log.md`: the engine's certification gate, LLM-derived `intensity_delta`, and the coach approval matrix. Each is reclassified from *open decision* to *contract violation* |
| 2026-08-24 | **Wave 1 parallel batch tasks 2–9 executed.** Tasks 2–8 `REMEDIATED` (task 8 wording `REQUIRES_REVIEW`); task 9 `BLOCKED` on new **EB-12**. Suites 750/9/0 · 58+6 · guards 10/10 (uncommitted tree). Five new findings **W1B-N1…N5** (registry §7.7); **W1B-N5 recorded as a Wave 5.0 entry precondition**. `REL-36`'s seed guard, the reset wrapper (`LRE-35`) and the edge-function config guard added. **No QA mutation; production not contacted.** Evidence: `WAVE_1_BATCH_CLOSURE.md` |
| 2026-08-25 | **Custody checkpoint prepared** (orchestrator). Batch reconciled against the tree; classifications confirmed; W1B-N1…N5 registered in registry §7.7; EB-12 added; counts moved (310→315 canonical, 8 `REMEDIATED`); config-push prohibition written into `config.toml`, `qa-environments.md` and Wave 5 prerequisites; commit slices prepared for owner execution. **Registry and this board updated together per the §1 update rule. No environment contacted.** |
| 2026-08-25 | **First CI run (`9319c67`) red on the production-ref guard** — `ci.yml` and `qa-db-reset.sh` named the production ref. Classified **B** (refusal/assertion references, no executable production path). Remediated by rewriting all three usages in QA-allowlist form with no production literal (artifact scan now fails on *any* foreign project ref) and adding `--untracked` to the guard scan, closing the local-green/CI-red blind spot. Filed + closed as **W1B-N6** (registry §7.7). Guards re-run locally: all green; the two files reproduce the CI failure under the corrected guard before the fix and pass after. **No commit/push performed; CI must reproduce. No environment contacted.** |
| 2026-08-25 | **CI run for `aac64b3` red on the ENV-4 inline check — filed and remediated as W1B-N7** (registry §7.7). The check's over-broad patterns matched doc placeholders in `app_env.dart` (lines 11/13) on the step's first-ever execution; W1B-N6's production-ref guard fix **passed in the same run** (its first CI evidence), as did migration hygiene, edge config, Flutter (incl. the new artifact allowlist scan) and API; live-qa was skipped by the failed dependency, so the EB-1 skip path remains unobserved. Fix: real-material-only patterns + an inline pattern self-test (placeholder-vs-real regression guard); comments remain scanned. Old/new behavior and self-test integrity demonstrated locally; all other static guards re-run green. **Prepared only — `.github/` is bridge-protected: corrected ci.yml staged at `docs/cowork/pending-cifix/ci.yml` for owner copy. No commit/push; no environment contacted.** |
