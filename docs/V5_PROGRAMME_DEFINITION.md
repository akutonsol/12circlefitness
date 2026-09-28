# V5 PROGRAMME DEFINITION

**The single authoritative V5 programme document for 12 Circle Fitness.**
**Date:** 2026-09-28 · **Entry commit:** `16ba19f0a612edf18754851f98bc2000205eff2b`

---

## 1 · PURPOSE AND AUTHORITY

This document defines the V5 programme, records its entry state, and carries its open
decisions, open findings and deferred scope.

**It is a definition and evidence document. It is not an analysis document, not an
implementation plan, and not a closure record.** It closes no finding, makes no owner
decision, allocates no finding ID, and changes no other document.

**Authority.** Where this document and the prior V5 analysis documents differ in *structure*,
this document governs. Where they differ in *fact*, the analysis documents are the evidence
and this document is wrong and must be corrected. This document synthesises; it does not
supersede. Every figure here is traceable to a cited artifact or to a stated count.

**Precedence for facts.** `QA_CLOSURE_STANDARD.md` and `MASTER_REMEDIATION_REGISTRY.md` are
authoritative over anything written here. Neither is modified by this document.

---

## 2 · V5 SOURCE AUTHORITY AND PROVENANCE

**V5 source specification:**
`12Circle_V5_Product_Ecosystem_Release_Sequencing_V5_Wearable_Intelligence_Platform.docx`

### 2.1 The source is not present in this repository — verified

A search of the working tree returns **no `.docx` file anywhere**, and `git ls-files` tracks
none. The specification is named at `V5_IMPACT_ANALYSIS_2026-09-27.md:5` and nowhere else; the
artifact itself was never committed.

**Three consequences, recorded and not waived:**

1. **The V5 requirements cannot be re-derived from this repository.** Every requirement in §4
   traces to a document under no version control.
2. **No integrity check is possible.** There is no hash and no committed copy, so no future
   reader can confirm that the specification they hold is the one these requirements came from.
3. **§4 is a transcription, not a citation.** It records what was read from the source during a
   prior session. It is evidence of a reading; it is not the source.

**This document does not claim that the V5 requirements were independently reconstructed from
repository state, and no such reconstruction was performed.** Repository evidence was used only
to *classify* each transcribed requirement against the current codebase — never to establish
what V5 requires.

This gap does not prevent V5 documentation. It does mean that any downstream claim of the form
*"V5 requires X"* rests on §4's transcription rather than on a repository artifact.

---

## 3 · ENTRY STATE

Frozen at authorship. Every value independently verified.

| Item | Value |
|---|---|
| HEAD | `16ba19f0a612edf18754851f98bc2000205eff2b` |
| Remote HEAD | `16ba19f0a612edf18754851f98bc2000205eff2b` — **synchronized** |
| Branch | `reconcile/12circle-integrated` |
| CI run | **36368081140** — conclusion **success**, 7/7 jobs |
| `continue-on-error` in the workflow | **0** |
| SEC-W1 in CI | **15/15 executed and passed**, 0 skip markers, real per-test output |
| Migration frontier | `applied_through: "134"` — **QA only**; production is deliberately not declared |
| QA completeness | **90.0%** — QA COMPLETE WITH OPEN FINDINGS |

### 3.1 What CI run 36368081140 does and does not prove

**It proves:** SEC-W1 executed and passed **against the post-fix tree, in CI**, on the pushed
commit, with no `continue-on-error` anywhere in the workflow to mask a failure.

**It does not prove:** that SEC-W1 *fails* against a pre-fix tree. **No CI run has ever observed
SEC-W1 fail.** This run is **not a negative control** and contains no pre-fix demonstration.

**Any representation of this run as pre-fix or negative-control evidence would be false.** The
distinction is load-bearing: `QA_CLOSURE_STANDARD.md` §2 defines VERIFIED IN CI as a check that
*"fails against the pre-fix tree and passes against the post-fix tree, **in CI**"*. Only the
second half is evidenced. The pre-fix half is evidenced **locally only**, by 13 of 13 killed
mutations, which is not "in CI".

---

## 4 · V5 REQUIREMENT INVENTORY

Transcribed from the V5 source (§2 — the source is not in the repository). Per-requirement
detail lives in `V5_IMPACT_ANALYSIS_2026-09-27.md` §2a–2f, whose terminology and structure are
preserved here.

### 4.1 An unresolved requirement-count discrepancy in the source analysis

Three figures in the source analysis disagree:

| Figure | Value | Where |
|---|---:|---|
| Distinct requirement IDs in the inventory tables | **101** | §2a–2f, counted |
| Sum of the stated classification distribution | **74** | `:204-207` |
| Stated total | **64** | `:63` and `:203` |

An independent recount reproduces **101** and no other figure. Causes were tested and excluded:
**duplicate IDs** (zero; every prefix range contiguous), **deliberate exclusions** (no row
carries one and no rule exists), and the source's own caveat *"(Primary classification per
requirement; several carry a secondary.)"* — which could only push a tally **above** the row
count, never below it, and is silent on 74 → 64. **The evidence supports only a manual
arithmetic error in the source.**

**This document asserts no authoritative requirement total.** The figures below are
**inventory-row counts**, not counts of V5 requirements. The two are demonstrably not
one-to-one: `SQ-01…30` compresses the 48-step master sequence into 30 rows covering **43 of 48
steps**, with steps **4, 8, 9, 12 and 14 not inventoried at all**. The semantic count is
unestablishable while the source specification is absent.

**`V5_IMPACT_ANALYSIS_2026-09-27.md` is unchanged and remains source evidence. Its figures are
quoted here, not corrected there.**

### 4.2 Inventory rows by group

| Group | Prefix | Rows | Domain |
|---|---|---:|---|
| Governance & source of truth (V2 head) | `GV-01…10` | 10 | hierarchy, conflict handling, protected screens, data realism, first-class security |
| Master sequence | `SQ-01…30` | 30 | the 48-step sequence — those steps creating build surface |
| AI Guardian, Admin & incident model (V2) | `AG-01…07`, `AD-01…03` | 10 | 8 Guardian domains, autonomy L0–L3, incident model, 13 Admin domains |
| Wearable Intelligence (V3) | `WI-01…25` | 25 | platform boundary, connector, ingestion, normalization, intelligence, provenance |
| Agentic AI security (V4) | `AS-01…13` | 13 | OWASP AST10, agent inventory, action audit trail, runtime least privilege |
| Security assurance, SBOM & control mapping (V5) | `SA-01…13` | 13 | ASVS 5.0.0, control evidence, CycloneDX SBOM, release-integrity chain |
| **Total** | | **101** | 101 distinct IDs, zero duplicates |

### 4.3 Classification — counted, against the figures the source states

| Class | Name | Counted | Source states | Δ |
|---|---|---:|---:|---:|
| **1** | EXISTS | 9 | 6 | +3 |
| **2** | PARTIALLY EXISTS | 21 | 18 | +3 |
| **3** | NOT IMPLEMENTED | **49** | 26 | **+23** |
| **4** | CONFLICTS | 1 | 1 | 0 |
| **5** | REQUIRES ARCH DECISION | 7 | 9 | −2 |
| **6** | BLOCKED BY QA FINDING | 2 | 3 | −1 |
| **7** | BLOCKED BY EXTERNAL DEPENDENCY | **0** | *not listed* | — |
| **8** | V5 AMBIGUOUS | 1 | 2 | −1 |
| **9** | NOT CURRENTLY EVIDENCED | 11 | 9 | +2 |
| | **Sum** | **101** | **74** | **+27** |

Every row carries exactly one parsable class; none is unparsable. Class **7** is defined in the
source's legend and used by no row. The stated distribution disagrees with the count in **seven
of the eight** classes it lists — only CONFLICTS agrees.

**Gaps.** The source states *"Gaps = the 58 that are not EXISTS."* That figure is **doubly
derived** from two already-incorrect inputs (stated total 64 − stated EXISTS 6 = 58); it is not
an independent measurement. The counted non-EXISTS total is **101 − 9 = 92**.

---

## 5 · V5 DEPENDENCY AND SEQUENCING MODEL

Derived from `V5_IMPACT_ANALYSIS_2026-09-27.md` §17–18. **No dependency is invented here.**

### 5.1 Dependency graph

```
CONF-01/02 (governance baseline) ──► what "protected" and "V5" mean
        │
D4 AUDIT SCHEMA ◄── the deepest dependency; 4 V5 requirements need it
        ├──► Admin audit domain ──► Admin Control Center (13 domains)
        ├──► Incidents ──────────► Trust → Incidents
        ├──► Agent action trail ─► AI Guardian (AS-05) ──► Guardian QA
        └──► Trust → Audit Logs
OBSERVABILITY FOUNDATION (SQ-10) ──► Admin health/analytics ──► Release Guardian
QAX-SEC-08 ──► is_team_lead_of ──► user_profiles PHI
        └──► may_notify ──► notifications ──► Guardian alerting (F-03b)
        └──► SEC_PHI_1 view pattern ──► Admin column-limited views
WEARABLE: D-V1 boundary ──► D-V2 store ──► D-V3 contract
        Connector (PARTIAL: user_integrations, 7 providers)
             └──► Ingestion ──► Normalization ──► Intelligence (zones, Training Alignment)
                        └──► Storage ──► RLS/authz (D-V4) ──► API/SDK ──► Partner APIs (CONF-06)
SUPPLY CHAIN: SBOM tooling (D-V6) ──► CI stage ──► release-integrity chain (SA-11)
TESTING: CI secrets ──► E2E journeys (SQ-24); egress ──► security/AI tiers
```

**Stated critical path:** `CONF-01/02 → D4 audit schema → observability →
Admin/Trust/Guardian`, with the wearable stack in parallel from `D-V1`. **The P0 fix gates any
feature reading PHI through team membership.**

### 5.2 Phases — dependency-derived, no dates

V5 defines no dates, durations or story points, and none are assigned here.

| Phase | Contents | Entry condition | State at this entry point |
|---|---|---|---|
| **P0 · GOVERNANCE** | Resolve CONF-01/02; confirm protected baseline; assign migration numbers 132+ | owner decisions | **partially consumed** — 132/133/134 assigned and applied; **CONF-01/02 unresolved** |
| **P1 · FOUNDATION / SECURITY** | `coach_team_members` `WITH CHECK`; corrected `SEC_PHI_1`; status predicates | D1, D3, D17 | **partially executed** — Wave 1 closed the P0's write path and F-03b's team arm; **QAX-SEC-08 not closed** (§7) |
| **P2 · DATA (AUDIT + OBSERVABILITY)** | Audit event schema + RLS; incidents; observability store | **D4, D12** | not started |
| **P3 · BACKEND** | Wearable boundary; ingestion/normalization; canonical contracts | **D-V1, D-V2, D-V3** | not started |
| **P4 · CORE PRODUCT** | Intelligence layer; provenance + calculation versioning | P3 | not started |
| **P5 · ADMIN** | Control Center over the 13 domains | P2, D5–D7 | not started |
| **P6 · TRUST** | Security · Incidents · Audit Logs | P2, P5, D11 | not started |
| **P7 · AI GUARDIAN** | 8 domains, autonomy L0–L3, approval gates, agent audit trail | P2, P6, D-V5 | not started |
| **P8 · MOBILE** | Wearable UX; Admin/Trust surfaces; feature flags | P4, D6, designs | not started |
| **P9 · INTEGRATION** | Platform contracts; partner APIs + tenancy | P3–P8, CONF-06 | not started |
| **P10 · QA & SUPPLY CHAIN** | Wearable QA, agentic security QA, a11y, performance, SBOM, DR drills | D-V6, CI secrets, egress | not started |

**Monetization (SQ-04/SQ-14) runs alongside P1–P2** — its six open K specs are entitlement
defects, and K-04 is a live-confirmed authorization defect.

**Naming collision, preserved:** phase **P0 · GOVERNANCE** and severity **P0** are unrelated
uses of the same token, each established in its own source. Disambiguate by context.

---

## 6 · V5 GATE MODEL

### 6.1 Readiness gates 1–15

From `V5_IMPLEMENTATION_READINESS_GATE_2026-09-27.md` §3. **5 pass · 2 partial · 8 fail.**

| Gate | Subject | Result |
|---|---|---|
| 1 | V5 source-of-truth conflict | **PASS with owner confirmation** |
| 2 | Approved screen inventory | **PASS in part** — different units (design board 156/169 vs repo 91/148) |
| 3 | Admin readiness | **FAIL** — designs not in repository |
| 4 | Trust / audit foundation | **FAIL** — 14 decisions must precede audit-dependent work |
| 5 | Security / open QA findings | **CONDITIONAL** — P0 must precede team/PHI workstreams |
| 6 | Wearable architecture | **FAIL** — boundary, store, canonical contract undecided |
| 7 | AI / agentic security | **FAIL** — depends on audit + observability |
| 8 | SBOM / release integrity | **PASS build-time, FAIL release-time** |
| 9 | Database / migration readiness | **FAIL** — entities undefined pending D4/D-V2/D-V3 |
| 10 | API / mobile readiness | **FAIL** — no contracts |
| 11 | Design readiness | **FAIL** — Admin/Trust designs absent; 46 routes already without design |
| 12 | Skills-Agent build readiness | **PASS** |
| 13 | Remaining QA 10% | **PASS** — carry-forward matrix established |
| 14 | Implementation sequencing | **PASS** — sequence derived |
| 15 | Owner decisions | **PASS** — reconciled and separated |

### 6.2 Closure-standard constraints the programme inherits unchanged

- **§2.1 — the class ladder.** Security / authorization requires
  `FIXED IN CODE · FIXED ON QA · VERIFIED LIVE · VERIFIED IN CI`, and *"`VERIFIED_CLOSED`
  requires every state its class demands. **There are no partial closures and no exceptions
  granted at implementation time.**"*
- **§5.2 — security findings.** Live evidence is mandatory where feasible and safe;
  security-sensitive probes use transaction rollback, and *"where they cannot, the probe is not
  run and the limitation is recorded"*; **test the class, not the instance** — *"a closure that
  pins only the instance is incomplete"*; and a closure that redefines a database object must
  prove it preserved every property the object carried.
- **§4:105 — the static-test bound.** *"A static test asserting migration text… **cannot**
  assert the database's actual grant state. **Necessary, never sufficient**, for a security
  finding."*
- **§4:111 — test changes.** *"Never weaken a test to get green. If a test must change, the
  change is a **reviewed decision recorded in the finding's evidence**."*

**Consequence for V5:** no phase may treat a green CI run as security readiness. `SA-13` states
this as a V5 requirement and the impact analysis records it as *"already this programme's stated
position"*.

---

## 7 · CURRENT SECURITY / QA STATE

### 7.1 QAX-SEC-08 — evidence matrix

**The finding (P0):** a self-registered coach inserts
`coach_team_members(coach_id = self, member_id = <victim>)`; `is_team_lead_of()` treats the row
as an authorization fact; the `user_profiles` SELECT policy then exposes the victim's whole row
— PAR-Q answers, medical conditions, weights, phone, billing flags.

| Rung | Evidence | Status |
|---|---|---|
| **FIXED IN CODE** | Committed diffs `d364ff0` (migration 132 +294, migration 133 +86) and `16ba19f` (migration 134 +109), present at HEAD and pushed | **MET** |
| **FIXED ON QA** | Three replacement policies, the `status` column with its four-state CHECK, the `team_member_profiles` view, and both lifecycle-aware helpers present in the live catalog; ledger records 132/133/134 | **MET** |
| **VERIFIED LIVE** | Pre-fix: forged INSERT **succeeded**, `is_team_lead_of` → **t**, victim profile **readable**, `parq_answers` **reachable**, `may_notify` → **t**, forged notification **succeeded**. Post-fix, same fixture: every path **denied / 0 / f**. One transaction, ended in `ROLLBACK`; zero net mutation; fixtures re-read at zero | **MET** — with the limitation in §7.3 |
| **VERIFIED IN CI** | **Post-fix half MET** — SEC-W1 15/15 in run 36368081140 on `16ba19f`. **Pre-fix half ABSENT in CI** — evidenced only by 13/13 mutations killed **locally** | **NOT MET** |

### 7.2 Disposition

**QAX-SEC-08 — OPEN / PARTIALLY VERIFIED. Three of four required rungs met.**

**This is NOT `VERIFIED_CLOSED`.** §2.1 permits no partial closure and no implementation-time
exception. The word **PASS** is not applied to this finding.

### 7.3 Two limitations recorded, not waived

- **VERIFIED LIVE rests on a one-time ad-hoc probe, not a standing suite.** No committed,
  CI-executed probe covers `coach_team_members` or `is_team_lead_of`. The only file naming them
  is `supabase/tests/security/d09-assessment-access.mjs`, which is **untracked**;
  `supabase/tests/qa_exhaustion/` is absent from `.github/workflows/ci.yml`. The rung is met
  under §2 and §5.2, but it is **not repeatable in CI**.
- **SEC-W1 is a static migration-text test**, so §4:105 bounds its whole class as *necessary,
  never sufficient*. Completing the CI rung would not by itself make the finding secure; the
  live rung carries that weight.

### 7.4 The remaining blocker

A **CI-side demonstration that SEC-W1 fails against a reconstructed pre-fix condition**. This is
blocked on owner decision **D-1** (§8). It is a decision, not a task.

---

## 8 · OPEN DECISIONS

**All three are unresolved. No option is selected or recommended here.**

### D-1 · Which reconstruction mechanism may the SEC-W1 CI negative control use?

| Option | Governance status | Exercises the 15 assertions |
|---|---|---|
| Delete migrations 132/133 in the workspace, restore | Authorized by precedent (`i3a11_negative_control.sh`, CI-wired) | **No — 0 of 15** |
| Isolated worktree at the pre-fix commit `07f5bfb` | Authorized by precedent (`wrk01_live_probe.sh`) | **No — 0 of 15** |
| Temporarily mutate 132/133 text, restore byte-identically | **UNSETTLED** — §8 of the closure standard says *"Never rewrite a migration in place unless the wave plan explicitly authorizes it"*; **no harness precedent exists** | **Yes — 15 of 15** |
| Change SEC-W1's `setUpAll` to lazy reads, then delete | Governed by §4:111 as a reviewed decision recorded in the evidence | **Yes**, per test, as I/O errors rather than the guard's curated `reason:` strings |

**Why the first two exercise nothing:** SEC-W1 reads migration 132 inside `setUpAll`, and in
`package:test` a failing `setUpAll` means the group's tests **are never run**. Deleting the
migration therefore produces exactly one failure, named `(setUpAll)`, and **zero of the 15
assertions execute**.

### D-2 · Authorize remediation of Finding A? (§9.2)
### D-3 · Authorize remediation of Finding B? (§9.3)

**Dependent on D-2/D-3: registry ID allocation**, which is a registry act. No `NEW-W1-*` ID
exists in `MASTER_REMEDIATION_REGISTRY.md` (count: **0**), so no convention permits
self-allocation.

### 8.1 Inherited decisions — unresolved, carried forward

`CONF-01` (174 approved screens vs a repository inventory of 91 routes / 148 surfaces) ·
`CONF-02` · **`D4`** (audit schema — the deepest dependency) · `D12` (observability) ·
`D5`–`D7` (Admin) · `D11` (Trust) · `D15` (derive guard population from the live catalog) ·
`D17` · `D-V1`/`D-V2`/`D-V3` (wearable boundary, store, contract) · `D-V4` · `D-V5` ·
`D-V6` (SBOM tooling) · `CONF-06` (tenancy) · `CONF-08` (missing Admin/Trust designs).

---

## 9 · OPEN FINDINGS AND LIMITATIONS

### 9.1 Registered findings, open

| ID | Status | Note |
|---|---|---|
| **QAX-SEC-08** | **OPEN / PARTIALLY VERIFIED** | §7. Three of four rungs |
| **F-03b** | **OPEN** | Team arm closed by migration 132; the `coach_client_relationships` any-status arm remains, outside Wave 1 scope (decision D3) |
| **QAX-SEC-09** | **OPEN** | `hosts_event_for()` still grants an event host the **whole** `user_profiles` row. **Profile PHI remains exposed through this path.** Closing QAX-SEC-08 would not change it |
| **SEC-PHI-9** | **OPEN** | — |
| **SEC-PHI-10** | **OPEN** | — |
| **SEC-AI-1** | **OPEN** | — |
| **NEW-W1-02** | **OPEN** | A member cannot leave a team; unreachable while origination is denied by migration 133. Wave 2 |
| **NEW-10** | **OPEN** | Silent invite-insert failure |

**Resolved during the Wave 1 programme:** `NEW-9` (credential-gated CI suites executed) ·
`NEW-W1-01` (removed by migration 133's `WITH CHECK (false)`).

**No `NEW-W1-03` exists.** Only `NEW-W1-01` and `NEW-W1-02` are allocated anywhere in `docs/`,
and neither appears in the master registry.

### 9.2 Finding A — schema-qualification blind spot — **UNREGISTERED, NO ID**

SEC-W1's `FOR ALL` detector and its `FOR UPDATE` detector both require
`ON\s+public\.coach_team_members`. The real historical defective policy at
`supabase/migrations/002_ecosystem_additions.sql:146-147` is written **unqualified**
(`ON coach_team_members`), and the unqualified form is the repository's dominant style
(approximately 3.6:1 across `supabase/migrations/*.sql`; exact counts are method-sensitive and
should not be cited without publishing the counting expression).

A future migration re-introducing a `FOR ALL` policy on `coach_team_members` in the unqualified
style would **pass SEC-W1 undetected**. SEC-W1's own non-vacuity test cannot surface this,
because it plants a `public.`-qualified literal.

**Classification:** genuine defect. §5.2 names the failure mode — *"Test the class, not the
instance… A closure that pins only the instance is incomplete."*
**Current exposure:** none — the applied catalog is correct and 002's policy is dropped at
runtime by migration 132. **Compensating control:** none.
**Status:** OPEN, unremediated, **no registered finding ID**. Remediation requires **D-2**.

### 9.3 Finding B — forward-supersession blind spot — **UNREGISTERED, NO ID**

SEC-W1 pins **migration 132's** text for `is_team_lead_of()` and `may_notify()`. Migration
**134** later `CREATE OR REPLACE`s both and, because migrations apply in filename order, is the
authoritative definition at HEAD. SEC-W1 does not read 134. A future migration could weaken
either helper while leaving 132 byte-identical, and **SEC-W1 would still pass**.

**Classification:** genuine defect — the unmechanized half of §5.2's clause *"A closure that
redefines a database object must prove it preserved every property the object carried."* That is
a procedural obligation with no enforcing guard.
**Migration 134 itself complied** with that clause: its `CREATE OR REPLACE` preserved
`LANGUAGE sql`, `STABLE`, `SECURITY DEFINER`, both bodies including `t.status = 'active'`, each
function's own established `search_path`, and existing ACLs and comments. **134 is the occasion
of this gap, not its cause.**
**Distinct from D15:** D15 concerns *backward* supersession of SEC-G1's **policy population**;
this is *forward* supersession of SEC-W1's **pinned function text** — different direction,
subject and guard.
**Current exposure:** none. **Compensating control:** none.
**Status:** OPEN, unremediated, **no registered finding ID**. Remediation requires **D-3**.

---

## 10 · OBSERVATIONS WITHOUT A REGISTERED FINDING

**This section is not a findings register.** The item here was observed during QA, was never
written into any document, and carries **no finding ID**. It must not be cited as a finding, and
no ID is assigned to it.

- **`supabase/tests/security/lib.mjs` and `supabase/tests/ai/lib.mjs` refuse by blocklist, not
  by allowlist.** `apps/mobile/tool/qa_target.dart` states the governing principle: *"Refusal is
  by allowlist, not by blocklist: 'is not production' is not the same claim as 'is QA', and only
  the second one is safe to write against."* A blocklist passes every target it has never heard
  of. Both files are allowlisted in `.github/scripts/check-production-refs.sh` and were placed
  under a **record-only** instruction during the QAT-1 remediation; neither was modified.
  **Two files, one observation. No ID. Not a registered finding. Not remediated.**

---

## 11 · DEFERRED SCOPE

Deferred by prior authorization, carried forward unchanged and **not** started:

| Item | Note |
|---|---|
| **Wave 2** | Invite hardening; acceptance/consent flow; invite → membership conversion. `coach_team_invites` is still `FOR ALL` with no `WITH CHECK` |
| **D15** | Derive guard population from the live catalog — proposed, not applied |
| **V6 / CHAIN-G1 widening** | Not started |
| **Admin Control Center** | 13 domains; blocked on D4, D5–D7, and missing designs (CONF-08) |
| **Trust** | Security · Incidents · Audit Logs; blocked on D4, D11, CONF-08 |
| **AI Guardian** | 8 domains, autonomy L0–L3; blocked on audit + observability |
| **Wearable Intelligence** | Blocked on D-V1/D-V2/D-V3 |
| **Security Center** | Not started |
| **SBOM / release-integrity chain** | Blocked on D-V6; 0 security-scan steps in CI |
| **E2E journeys incl. Admin and Wellness Partner** | Blocked on CI secrets and HTTPS egress |
| **Full data realism pass** | Fixture writes declined on shared QA |

---

## 12 · STATUS VOCABULARY

The registry's vocabulary is authoritative and unchanged:
`VERIFIED_CLOSED · ALREADY_FIXED · READY_TO_REMEDIATE · REMEDIATED · BLOCKED_DECISION ·
BLOCKED_ENVIRONMENT · DISCOVERED`.

This document uses two terms that are **documentation extensions / working terminology and are
not registered statuses**:

| Term | Registry equivalent | Standing |
|---|---|---|
| **OPEN / PARTIALLY VERIFIED** | *none* — **0 occurrences** in the registry | **Working terminology.** Not a registered status |
| **OBSERVATION WITHOUT A REGISTERED FINDING** | *none* — no registry concept | **Working terminology.** Not a registered status |

**The gap is pre-existing and is now in its third instance.** `QA_CLOSURE_STANDARD.md` §2
provides no term for *"every required state but one"*. The programme escalated this twice before
— for `SEC-R2`/`SEC-R3`, and again for `M-03` — and in both cases the row was left
**understated** rather than carrying a false evidence claim. `QAX-SEC-08` is the third instance
and is treated the same way.

**Consequence, stated rather than resolved:** a reader mapping this document onto the registry
will find no row that says `OPEN / PARTIALLY VERIFIED`. That is the recorded gap, not an
inconsistency to be fixed by editing the registry. **The registry is not modified by this
document.** Closing the gap would require an owner decision on the registry's status vocabulary,
which is not taken here.

---

## 13 · CONTRADICTIONS AND PROVENANCE GAPS

Recorded deliberately and **not** resolved. §1 of the closure standard exists because prior
phases closed things that were not closed; these stay visible.

| # | Contradiction / limit |
|---|---|
| **C-1** | **The V5 source specification is not in the repository** (§2). The requirements cannot be re-derived from repository evidence |
| **C-2** | **V5 appears zero times** in `MASTER_REMEDIATION_WAVES.md`, `REMEDIATION_EXECUTION_PLAN.md` and `MASTER_QA_RECONCILIATION.md`. V5 is not integrated into the programme's wave structure |
| **C-3** | **Eight of the eleven V5 analysis documents are uncommitted** (§15). Citations to them are citations to non-durable session artifacts |
| **C-4** | **`OPEN / PARTIALLY VERIFIED` has no registry standing** (§12). Third instance of the status-vocabulary gap |
| **C-5** | **QAX-SEC-08's VERIFIED IN CI rung is half-met.** The successful CI run is **not** a negative control and must never be represented as pre-fix evidence |
| **C-6** | **VERIFIED LIVE is not repeatable in CI** — a one-time ad-hoc rollback probe, with no committed CI-run probe covering the path |
| **C-7** | **§4:105's static-test bound** — SEC-W1's class is *necessary, never sufficient* for a security finding |
| **C-8** | **Findings A and B have no IDs** (§9.2, §9.3). No `NEW-W1-*` ID exists in the registry; allocation is a registry act |
| **C-9** | **QAX-SEC-09 remains open** — profile PHI is **not** safe, and nothing here should be read as implying otherwise |
| **C-10** | **CONF-01 is unresolved** — V5 names 174 approved screens; the repository inventory records 91 routes / 148 surfaces; the design board records 156/169. "Protected baseline" is therefore undefined |
| **C-11** | **Unresolved requirement-count discrepancy in the source analysis** (§4.1). Counted **101**; stated distribution sums to **74**; stated total **64**; stated "58 gaps" derived from two wrong inputs against a counted **92**. No authoritative total is asserted |
| **C-12** | **Two dangling requirement references in the source** — `SQ-31` (line 600) and `SQ-39` (line 601) do not exist; the `SQ` series ends at `SQ-30`. They appear to mean sequence *steps* 31 and 39 (`SQ-16` and `SQ-24`), mislabelled with the requirement-ID prefix. **Inferred, not verified**; the source is unchanged and the ambiguity stands |

*C-1 through C-9 are carried from the read-only documentation inventory. C-10 through C-12 were
established during the requirement-count reconciliation and are recorded here for the first
time; none is a new security finding.*

---

## 14 · V5 IMPLEMENTATION-READINESS BOUNDARY

**Three states. They are not interchangeable and must never be substituted for one another.**

| State | Meaning | Current |
|---|---|---|
| **Documentation readiness** | The evidence base is consistent and truthfully labelled, so the programme can be *described* | **YES** — this document exists and every gap is named |
| **Implementation readiness** | The gates permit *building* | **NO** — §6.1 records 5 pass · 2 partial · **8 fail**, and the critical path is blocked at `CONF-01/02` and `D4` |
| **Security closure** | A finding has every rung its class demands | **NO for QAX-SEC-08** — three of four rungs (§7) |

**Documentation readiness does not imply implementation readiness, and neither implies security
closure.** This document asserts only the first. Producing it closes no finding, unblocks no
gate, and must not be recorded as doing either.

---

## 15 · EVIDENCE INDEX

**Durability matters.** An untracked document is a session artifact: it exists in one working
tree, is not in git history, and cannot be relied on as committed authority.

| Artifact | Lines | Durability |
|---|---:|---|
| `V5_IMPACT_ANALYSIS_2026-09-27.md` | 690 | **UNTRACKED — session artifact** |
| `V5_IMPLEMENTATION_READINESS_GATE_2026-09-27.md` | 527 | **UNTRACKED — session artifact** |
| `V5_DECISION_RESOLUTION_2026-09-27.md` | 650 | **UNTRACKED — session artifact** |
| `QA_TO_V5_TRANSITION_RECONCILIATION_2026-09-27.md` | 467 | **UNTRACKED — session artifact** |
| `V5_DESIGN_AUTHORITY_RECONCILIATION_2026-09-27.md` | 441 | **UNTRACKED — session artifact** |
| `V5_FINAL_DESIGN_AUTHORITY_RECONCILIATION_2026-09-27.md` | 394 | **UNTRACKED — session artifact** |
| `V5_D1_SECURITY_FOUNDATION_AUTHORIZATION_ANALYSIS_2026-09-27.md` | 393 | **UNTRACKED — session artifact** |
| `V5_SECURITY_FOUNDATION_OWNER_DECISION_AND_IMPLEMENTATION_READINESS.md` | 386 | **UNTRACKED — session artifact** |
| `V5_WAVE1_INDEPENDENT_VERIFICATION_REPORT.md` | 580 | TRACKED |
| `V5_SECURITY_FOUNDATION_WAVE1_FINAL_REPORT.md` | 334 | TRACKED |
| `V5_SECURITY_FOUNDATION_WAVE1_AUTHORIZATION.md` | 286 | TRACKED |
| `adr/ADR-W1-001-team-membership-lifecycle.md` | 210 | TRACKED |

**Authoritative and tracked:** `QA_CLOSURE_STANDARD.md` · `MASTER_REMEDIATION_REGISTRY.md` ·
`MASTER_PRODUCT_DECISIONS.md` · `QA_EVIDENCE.md` · `REMEDIATION_PROGRESS.md`.

**Eight of the eleven V5 analysis documents are uncommitted** (C-3). Committing them is a
separate act requiring its own authorization and is **not** performed by this document.

---

## 16 · FINAL STATE AND NEXT DECISION BOUNDARY

### 16.1 What remains owner-controlled

| # | Decision | Blocks |
|---|---|---|
| **D-1** | SEC-W1 negative-control reconstruction mechanism | QAX-SEC-08's fourth rung — **and nothing else** |
| **D-2** | Finding A remediation authorization | Finding A only |
| **D-3** | Finding B remediation authorization | Finding B only |
| — | Registry ID allocation for Findings A and B | Their registration |
| — | `CONF-01`/`CONF-02` | The protected baseline, and therefore P0 → everything downstream |
| — | `D4` (audit schema), `D12` (observability) | P2 → Admin, Trust, Guardian |
| — | `D-V1`/`D-V2`/`D-V3` | The whole wearable stack |
| — | Registry status vocabulary (§12) | Whether `OPEN / PARTIALLY VERIFIED` becomes a registered status |

### 16.2 What documentation can proceed without those decisions

Anything that **describes** rather than **commits** the programme: requirement elaboration,
dependency refinement, gate specification, design intake, and architecture options presented as
options. None of it may assert implementation readiness, close a finding, or allocate an ID.

### 16.3 What this document does not do

- It closes no finding. **QAX-SEC-08 remains OPEN / PARTIALLY VERIFIED and is not
  `VERIFIED_CLOSED`.**
- It makes no owner decision. **D-1, D-2 and D-3 remain unresolved**, as does every inherited
  decision.
- It allocates no finding ID, and creates no `NEW-W1-03`.
- It modifies no registry, standard, decision log, wave document, migration, test, or CI
  configuration.
- It does not assert V5 implementation readiness.
- It does not imply that `QAX-SEC-09` is resolved. **Profile PHI remains exposed through
  `hosts_event_for()`.**
- It does not represent CI run 36368081140 as evidence of a pre-fix negative control.
