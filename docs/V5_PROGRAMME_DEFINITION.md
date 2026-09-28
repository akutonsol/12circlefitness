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
CONF-01 ANSWERED (baseline = 91 routes, §8.2) · CONF-02 OPEN ──► what "V5" means
        │
D4 AUDIT SCHEMA ◄── deepest dependency  [A2/A1/A3/A6/A11/A12/A13 ANSWERED §8.3-8.9; A14 OPEN, blocked on D11]
        ├──► Admin audit domain ──► Admin Control Center (13 domains)
        ├──► Incidents ──────────► Trust → Incidents
        ├──► Agent action trail ─► AI Guardian (AS-05) ──► Guardian QA
        └──► Trust → Audit Logs
OBSERVABILITY FOUNDATION (SQ-10) ──► Admin health/analytics ──► Release Guardian
QAX-SEC-08 ──► is_team_lead_of ──X  user_profiles PHI
        !! that ONE arm is PRE-FIX: migration 132 SEVERED it.  The two arms below
        !! were NOT severed -- may_notify was NARROWED to status='active'.
        └──► may_notify ──► notifications ──► Guardian alerting (F-03b)
        └──► SEC_PHI_1 view pattern ──► Admin column-limited views
WEARABLE: D-V1 boundary ──► D-V2 store ──► D-V3 contract
        Connector (PARTIAL: user_integrations, 8 providers -- see the note below)
             └──► Ingestion ──► Normalization ──► Intelligence (zones, Training Alignment)
                        └──► Storage ──► RLS/authz (D-V4) ──► API/SDK ──► Partner APIs (CONF-06)
SUPPLY CHAIN: SBOM tooling (D-V6) ──► CI stage ──► release-integrity chain (SA-11)
TESTING: CI secrets ──► E2E journeys (SQ-24); egress ──► security/AI tiers
```

**Stated critical path:** `CONF-01/02 → D4 audit schema → observability →
Admin/Trust/Guardian`, with the wearable stack in parallel from `D-V1`. **`CONF-01` is now
ANSWERED (§8.2) and no longer gates this path; `CONF-02` and `D4` still do.**

**What team membership reaches today.** Migration 132 removed the `is_team_lead_of(id)` arm from
the `user_profiles` SELECT policy, which at HEAD reads
`id = auth.uid() OR public.is_active_coach_of(id) OR public.hosts_event_for(id)`. Team membership
therefore reaches exactly two things: the **5-column** `team_member_profiles` roster view
(`id, first_name, last_name, email, avatar_url`) — which carries **no PHI**, though ADR-3 records
`email` as a **residual PII question** — and the team arm of `may_notify()`. It does
**not** reach the `user_profiles` row. The gating is **prospective** — a *new* team-gated PHI read
would have to be authored, and Wave 1's fix is what prevents one being authored against the old
arm. Stated in the present tense as "the P0 fix gates any feature reading PHI through team
membership", it would overstate the current exposure.

**This says nothing about `QAX-SEC-09`**, whose `hosts_event_for(id)` arm remains in the policy
above and still grants the **whole** `user_profiles` row. Profile PHI is **not** safe (§9.1, C-9).

**Provider count — the sources disagree, and the disagreement is preserved, not normalised.** The connector UI offers **8** providers (`apple_health`, `google_fit`, `whoop`,
`garmin`, `polar`, `strava`, `myfitnesspal`, `spotify`), which is the figure used above. Three
other figures circulate, and their provenance differs:

- **7** — the figure this document previously carried. Its **only** sources are **uncommitted**
  analysis documents (`V5_IMPACT_ANALYSIS_2026-09-27.md`, `V5_DECISION_RESOLUTION_2026-09-27.md`).
  No tracked file states it. It is therefore a non-durable session artifact (C-3).
- **6** — `MASTER_PRODUCT_DECISIONS.md` (PD-B23). **Tracked.**
- **5** — `FUTURE_CAPABILITIES.md` (FC-01). **Tracked.**

None of those documents is corrected here — they are historical records and are left as they
stand. Note also that `user_integrations.provider` is unconstrained
`TEXT` — no enum, no CHECK — so **no count is schema-enforced**; every figure is a count of
client-side intent, not of a database constraint.

### 5.2 Phases — dependency-derived, no dates

V5 defines no dates, durations or story points, and none are assigned here.

| Phase | Contents | Entry condition | State at this entry point |
|---|---|---|---|
| **P0 · GOVERNANCE** | Resolve CONF-01/02; confirm protected baseline; assign migration numbers 132+ | **`CONF-02` OPEN** (`CONF-01` ANSWERED, §8.2) | **partially consumed** — 132/133/134 assigned and applied; **protected baseline confirmed = the 91 registered routes**; `CONF-02` unresolved |
| **P1 · FOUNDATION / SECURITY** | `coach_team_members` `WITH CHECK`; corrected `SEC_PHI_1`; status predicates | **`D1(i)/(ii)/(iii)` ANSWERED** (do not block) · **`D1(iv)` ANSWERED §8.22 — DEFER TO WAVE 2** (no longer an open blocker; the deferral is now a decision, not a gap) · **`D3` OPEN** · **`D17` OPEN** — **P1's remaining blockers are `D3` and `D17` alone** | **partially executed** — Wave 1 closed the P0's write path and F-03b's team arm; **QAX-SEC-08 not closed** (§7) |
| **P2 · DATA (AUDIT + OBSERVABILITY)** | Audit event schema + RLS; incidents; observability store | **D4, D12** | not started |
| **P3 · BACKEND** | Wearable boundary; ingestion/normalization; canonical contracts | **D-V1, D-V2, D-V3** | not started |
| **P4 · CORE PRODUCT** | Intelligence layer; provenance + calculation versioning | P3 | not started |
| **P5 · ADMIN** | Control Center over the 13 domains | P2, D5–D7 | not started |
| **P6 · TRUST** | Security · Incidents · Audit Logs | P2, P5, D11, **`D-D1`** (§8.1) | not started |
| **P7 · AI GUARDIAN** | 8 domains, autonomy L0–L3, approval gates, agent audit trail | P2, P6, D-V5 | not started |
| **P8 · MOBILE** | Wearable UX; Admin/Trust surfaces; feature flags | P4, D6, designs | not started |
| **P9 · INTEGRATION** | Platform contracts; partner APIs + tenancy | P3–P8, CONF-06 | not started |
| **P10 · QA & SUPPLY CHAIN** | Wearable QA, agentic security QA, a11y, performance, SBOM, DR drills | D-V6, CI secrets, egress | not started |

**`D1(i)`, `D1(ii)` and `D1(iii)` are ANSWERED and do not block P1.** The owner's decisions are
recorded verbatim in three **tracked** files:
[`adr/ADR-W1-001-team-membership-lifecycle.md`](adr/ADR-W1-001-team-membership-lifecycle.md),
[`V5_SECURITY_FOUNDATION_WAVE1_AUTHORIZATION.md`](V5_SECURITY_FOUNDATION_WAVE1_AUTHORIZATION.md) §1,
and [`V5_SECURITY_FOUNDATION_WAVE1_FINAL_REPORT.md`](V5_SECURITY_FOUNDATION_WAVE1_FINAL_REPORT.md) §2.

**`D1(iv)` was NOT answered and remains open.** ADR-2 records it verbatim: *"The owner answered
D1(i), (ii) and (iii). **D1(iv) — the permitted `role` value set — was not answered.**"* Adding a
CHECK constraint would have decided an unanswered question, so `role` was deliberately left
unconstrained and the decision **deferred to Wave 2**. `D1` must therefore not be described as
answered without qualification.

> **SUPERSEDED IN PART — §8.22.** The owner has since **ANSWERED `D1(iv)`: DEFER TO WAVE 2**, with
> **no `CHECK` constraint for the role value set**. The paragraph above is retained as the state at
> the time of Wave 1. **What changes:** the deferral is now a **decision**, not an unanswered gap,
> so `D1(iv)` is **no longer an open blocker on P1**. **What does not change:** the column stays
> unconstrained, migration `132` is untouched, and **`D1` still must not be described as answered
> without qualification** — Wave 2 must still settle the value set. **Scope: `coach_team_members.role`
> only;** `user_profiles.role`'s existing `CHECK` at `115:79` is unaffected (§8.22).

**`D3` and `D17` remain OPEN and are not resolved here.**

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

`CONF-02` · **`D3`** (uniform status predicate — **a P1 entry blocker**, see §5.2; *not* the
`D-3` of §8, which is a different decision) ·
**`D4`** (audit schema — the deepest dependency; **`A2`/`A1`/`A3`/`A6`/`A11`/`A12`/`A13` ANSWERED
§8.3–8.9**; **still OPEN on `A14` alone**, which is blocked on `D11`) ·
`D12` (observability — **scope answered §8.10**, content still OPEN; `SQ-10` is now a **P2 entry
condition** and `PD-A24` sits inside it) ·
`D5`–`D7` (Admin) · `D11` (Trust) · **`D-D1`** (Trust container — see below) ·
`D15` (derive guard population from the live catalog) ·
`D17` · `D-V1`/`D-V2`/`D-V3` (wearable boundary, store, contract) · `D-V4` · `D-V5` ·
`D-V6` (SBOM tooling) · `CONF-06` (tenancy) · `CONF-08` (missing Admin/Trust designs).

**`D-D1` — the Trust container.** *Are Security / Incidents / Audit / Guardian a separate "Trust"
product area, or Admin domains?* It is recorded **deliberately unfilled** in a tracked file —
`V5_SECURITY_FOUNDATION_WAVE1_AUTHORIZATION.md` §1 carries the literal field
`TRUST = [INSERT OWNER DECISION HERE]` with the annotation *"Preserved unfilled, as instructed. It
does not gate this wave"*, and `V5_SECURITY_FOUNDATION_WAVE1_FINAL_REPORT.md:46` repeats that it
was *"left unfilled, as instructed."* It is therefore a **live unresolved owner decision**, not a
stale artifact, and it is **not resolved here.**

> **ANSWERED IN PART — §8.17, owner-ruled: TRUST OPERATOR.** The **governance/reader boundary** is
> decided: Trust is a **distinct governance role**, and admin/domain roles do **not** automatically
> inherit Trust access. **The tracked file above is NOT edited and its field remains literally
> unfilled.** **Residual, flagged not resolved:** the question as phrased here also asks whether
> Security / Incidents / Audit / Guardian form a separate **product area**. What was put and
> answered was the **role** boundary. **This document does not deem the product-area question
> answered, and does not answer it.** See §8.17.

**Effect on P6.** §5.2 previously entered **P6 · TRUST** on `P2, P5, D11` alone. That list was
**incomplete**:
`D-D1` determines whether a Trust surface exists at all, so it gates P6 ahead of D11, which only
scopes it. Until `D-D1` is answered, **P6's entry condition must be read as `P2, P5, D11, D-D1`**.
This was the one omission in this document that erred toward permissiveness rather than caution;
it is corrected here. The only other entry condition changed in the same revision is **P1's**,
where `D1(i)/(ii)/(iii)` were marked answered (§5.2) — a relaxation, and the only one. No other
phase's entry condition changes.

### 8.2 `CONF-01` — ANSWERED

**The canonical V5 protected baseline is the 91 registered routes.** Owner decision, recorded
here as supplied.

> **Unit:** *"route — an enumerated application route represented in the authoritative tracked
> route inventory."*

**The baseline is enumerated, twice, in tracked machine-readable evidence** — which is what makes
`GV-03` checkable rather than rhetorical:

| Carrier | Form | Members |
|---|---|---|
| `SCREEN_INVENTORY.json` | JSON `screens` array | **91** |
| `DESIGN_TO_IMPLEMENTATION_FINAL_MATRIX.md` | table, one row per route path | **91** distinct paths |

**What this decision does NOT do.** The other populations are **preserved as evidence
limitations** — not reconciled, converted or deleted (C-10):

- **148** (`surfaces_all_kinds`) — remains a tracked scalar with **no enumerated membership
  anywhere in the repository**, whose published sub-counts do not sum to it. **No members are
  invented for it.**
- **156 / 169** — design-board frames. They reconcile exactly among themselves (117 + 39 = 156;
  156 + 13 voice frames = 169) but **are not application routes** and are not treated as such.
  No frame→route mapping exists.
- **174** — its unit remains **uninferred** while the V5 source specification is absent (C-1).

`CONF-02` is a separate decision and **remains OPEN**.

### 8.3 `D4 · A2` — ANSWERED — what is audit-worthy

Owner decisions, recorded as supplied. **A2 only. `A1`, `A3`, `A11`, `A12` and `A13` remain OPEN
and nothing below decides or implies any of them.**

**Scope principle, verbatim:**

> *"Audit-worthy does not mean 'log everything.' It means durably record events that establish
> who/what performed a security, privacy, administrative, financial, authorization, or material
> state-changing action.*
>
> *Treat routine session lifecycle and ordinary operational telemetry as outside the core audit
> ledger unless a later requirement explicitly promotes a specific event into audit scope."*

**Server-log question — NO.** A `RAISE LOG` server-log line **does not** satisfy an audit
obligation.

| Tier | Category | Ruling |
|---|---|---|
| **1** — tracked gaps | PHI reads · PHI corrections · financial / charge trail | **IN** (all three) |
| **2** — V5-named | incidents · agent actions · control evidence · admin actions · observability audit events | **IN** (all five) |
| **3** — previously unrequired | authentication · authorization denials · billing / entitlement changes · relationship changes · storage / media access · export / deletion events | **IN** (six) |
| **3** — previously unrequired | **session lifecycle** | **OUT** — subject to the promotion clause above |

> **PRECEDENCE MARKER — `D12·Q4`, owner-ruled (§8.14).** The tier-2 entry *"observability audit
> events"* above is **preserved verbatim and REMAINS `IN`**. `A2` **CONTROLS** its contradiction
> with `A1` sub-ruling 3. The category is **audit-worthy** *and* resident in a **separate
> D12/observability population** — not in any of `A1`'s three audit populations. See §8.14.

**Fourteen of fifteen categories are IN; one is OUT.**

#### Consequences that follow from A2 alone — recorded, not remediated

- **`admin_set_user_role()` is unaudited.** Admin actions are **IN**, and the server-log ruling is
  **NO**. The repository's single sanctioned privilege-escalation primitive
  (`115_profile_privilege_boundary.sql:363`) writes **no audit row**; its only record is one
  `RAISE LOG` at `:392` — the **only** `RAISE LOG` in the entire migration tree. Under A2 that is
  not an audit record. **Note:** tracked `MASTER_PRODUCT_DECISIONS.md` PD-A19 describes the
  function as *"exists and is logged"*; that premise is superseded by this ruling. **PD-A19 is
  outside this document's mutation boundary and is NOT edited here** — the divergence is recorded,
  not reconciled.
- **Authorization denials are IN, and nothing observes them.** A denial raises an exception; no
  row is written anywhere. A database trigger cannot observe one, because no table write occurs.
  This constrains `A3` and is **not** decided here.
- **Storage / media access is IN**, and Supabase storage objects live outside the `public` schema.
  Implication for `A1`/`A3`; not decided here.
- **Export / deletion events are IN**, which means the act that erases must itself leave a record.
  That interacts directly with `A12` (retention vs erasure), for which **no tracked precedence
  rule exists**. Not decided here.
- **Session lifecycle is OUT** only until a later requirement explicitly promotes a specific
  event. This is a scope boundary, not a finding, and closes nothing.

**A2 changes no finding's status.** `QAX-SEC-08` remains OPEN / PARTIALLY VERIFIED;
`QAX-SEC-09` remains OPEN; `SEC-PHI-AUDIT`, `QAX-PRV-03` and `K-16` remain as recorded. No
registry ID is allocated and nothing is remediated.

### 8.4 `D4 · A1` — ANSWERED — audit schema topology

Owner decisions, recorded as supplied. **A1 only. `A3`, `A11`, `A12` and `A13` remain OPEN and
nothing below decides or implies any of them.**

**Topology: THREE V5-shaped populations.**

| # | Population | Shape |
|---|---|---|
| **1** | **Event** | append-only occurrence record — actor · subject · action · time · outcome |
| **2** | **Incident** | case record carrying **mutable** investigation state (AG-04's 11 fields) |
| **3** | **Control evidence / control matrix** | versioned matrix row keyed to a requirement (SA-03) — no actor, no subject, no occurrence time |

**Sub-ruling 1 — the `decision_traces` write-deny rule is SPECIFIC, not universal.** Migration
128's *"No write policy exists on this table and none may be added"* governs **that provenance
model only**; it is **not** a standing D4 rule. **Consequence:** the Incident population may carry
an UPDATE path, which its mutable investigation state requires. The structural
incidents-versus-append-only conflict is therefore resolved **by this ruling**, not deferred.

**Sub-ruling 2 — AUDIT OUTRANKS DELETION for audit-record retention.** Audit records **must not
be `ON DELETE CASCADE`'d merely because the audited subject is deleted.** Retention duration,
de-identification and export/deletion mechanics are **NOT decided here** and remain **`A12`**.

**Sub-ruling 3 — audit and observability audit events are TWO DISTINCT populations.** Their
schemas and semantics must not be merged. Shared infrastructure may be considered later. So the
audit ledger is the three populations above; **observability audit events sit outside them** and
are not a fourth audit population.

> **PRECEDENCE MARKER — `D12·Q4`, owner-ruled (§8.14).** This sub-ruling is **preserved verbatim**
> and **survives almost entirely**: *"two distinct populations"*, *"schemas and semantics must not
> be merged"* and *"not a fourth audit population"* all **STAND**. **`A2` CONTROLS** on the one
> point where the two collided. **What is superseded, and only this:** any reading of *"sit outside
> them"* as placing observability audit events outside **audit-worthy scope**. Per §8.14 that
> phrase is a statement of **topology**, not of **scope**. See §8.14.

#### Consequences that follow from A1 alone — recorded, not remediated

- **`N07_assessment_access.sql` now conflicts with a decided ruling.** Both its identity FKs are
  `REFERENCES auth.users(id) ON DELETE CASCADE`, so deleting either party destroys the access log
  — the precise shape sub-ruling 2 forbids. Under A2 this was an *implementation choice*; under
  A1 sub-ruling 2 it is a **conflict**. N07 remains **evidence and a proposal only — it is not
  adopted, not applied, and is not modified by this document.**
- **86 `ON DELETE CASCADE` occurrences exist tree-wide**, 53 of them on FKs to a user across 44
  distinct tables. Sub-ruling 2 governs **audit records**; it does **not** reach those existing
  tables, and none is changed here.
- **Three populations do not resolve the category mapping.** A2 placed 14 categories IN; the
  Event population absorbs 10–11 of them, whose differences — denials having no subject row,
  storage living in another schema, financial records reconciling against an external ledger —
  are **carried forward to `A3`**, not settled.
- **The immutability ceiling is unchanged by topology.** Zero `FORCE ROW LEVEL SECURITY`, zero
  `CREATE SCHEMA`/`CREATE ROLE`/`OWNER TO`; the table owner and **17 of 19** Edge Functions bypass
  RLS. Topology changes blast radius, not the ceiling. Whether "append-only" is claimed honestly
  against that ceiling is **`A11`**, still OPEN.

**A1 changes no finding's status**, allocates no registry ID, and remediates nothing.

### 8.5 `D4 · A3` — ANSWERED — audit write path

Owner decisions, recorded as supplied. **A3 only. `A11`, `A12` and `A13` remain OPEN and nothing
below decides or implies any of them.**

**Write path per A1 population:**

| Population | Write path |
|---|---|
| **Event** | **COMBINATION — trigger + RPC + application** |
| **Incident** | **RPC + application** |
| **Control evidence** | **AUTHORED MIGRATION + application** |

**Five sub-rulings:**

1. **PHI-read coverage: PARTIAL.** A 565-call-site RPC rewrite is **not authorized** solely for
   audit completeness. PHI-read auditing therefore covers only reads routed through an RPC.
2. **RLS denials, managed authentication events, and storage/media reads: ACCEPTED AS BLIND
   SPOTS.** They are preserved **explicitly as coverage limitations** and **must not be
   represented as audited**.
3. **Application-asserted actor: PERMITTED — but provenance must be preserved.** Asserted /
   application-provided identity and cryptographically grounded `auth.uid()` attribution **must
   remain distinguishable in the design and must not be equated**.
4. **Failed audit write: BEST-EFFORT.** An audit-write failure **must not automatically abort the
   audited business action**. Reliable failure visibility is recorded as an **unresolved
   implementation concern** carried to the downstream design.
5. **`service_role`: CONSTRAIN** its ability to bypass the intended audit controls. This is an
   **architectural ruling only** — the 17 service-role-holding Edge Functions are **not modified**.

#### Consequences that follow from A3 alone — recorded, not remediated

- **`N07_assessment_access.sql` now conflicts on a THIRD count.** Its stated design is *"Log
  BEFORE returning. If the insert fails the read does not happen"* — audit-as-blocking, the exact
  inverse of sub-ruling 4. Together with the `ON DELETE CASCADE` conflict (A1 sub-ruling 2) and
  the non-canonical `SET search_path = public` at `:151` (`134` requires `public, pg_temp`;
  `I-MIG-03` matches only the canonical form), plus its **missing `116` class declaration**, N07
  now carries **three conflicts and one omission**. It remains **evidence and a proposal only —
  not adopted, not applied, NOT MODIFIED.**
- **Coverage is now bounded and must be stated honestly.** The mobile client makes **565 direct
  `.from()` calls against 54 `.rpc()` calls** — RPC carries **8.7%** of data-access calls. Under
  sub-ruling 1, PHI-read audit observes that minority only. **No document may describe PHI-read
  auditing as complete.**
- **Four of A2's fourteen IN categories remain unemittable by any path:** RLS authorization
  denials (silent; and the 32 explicit `42501` raises **abort the transaction**, rolling back any
  audit row written in it) · authentication (Supabase-managed `auth` schema; zero references to
  `auth.audit_log_entries`/`auth.sessions`) · storage/media reads (no instrumented mint point) ·
  control evidence (no runtime occurrence, by construction). Sub-ruling 2 accepts the first three
  as blind spots.
- **Sub-ruling 5 has no precedent to build on.** No migration constrains `service_role` anywhere;
  `114`'s header explicitly *reserves* erasure to it. The only mechanism verified to bind **every**
  caller including owner and `service_role` is a BEFORE UPDATE/DELETE trigger that RAISEs
  (`120_workout_set_identity_authority.sql` precedent). Whether that is sufficient is **`A11`**,
  still OPEN.
- **Actor provenance is now a design obligation.** `auth.uid()` is NULL on every internal path;
  `current_user` cannot distinguish an Edge Function from pg_cron from a migration; and
  `stripe-webhook` has no JWT at all — its actor is `session.metadata.user_id`, supplied by a
  third party's payload. Sub-ruling 3 permits such actors **provided the distinction is carried in
  the record**.

**A3 changes no finding's status**, allocates no registry ID, and remediates nothing.

### 8.6 `D4 · A11` — ANSWERED — audit immutability

Owner decisions, recorded as supplied. **A11 only. `A12` and `A13` remain OPEN and nothing below
decides or implies either.**

**Meaning of "immutable", per A1 population:**

| Population | Ruling |
|---|---|
| **Event** | **FREEZE-IDENTITY-COLUMNS** — identity and occurrence facts are immutable. Any future writable annotation field **must be explicitly classified** and **must not alter the occurrence record**. |
| **Incident** | **APPEND-STATE-TRANSITIONS** — the incident may evolve, but **each state transition is retained as an immutable historical event**. |
| **Control evidence** | **NO RUNTIME WRITE PATH** — authored/produced evidence, not a runtime audit event. |

**Four sub-rulings:**

1. **Adversary: COMPROMISED EDGE FUNCTION.**
2. **DML-layer binding with an open DDL layer: NOT SUFFICIENT.** If the system claims meaningful
   append-only or tamper-resistance, **an out-of-database trust anchor is required**. The anchor is
   **not designed or implemented here**.
3. **Owner binding: NOT YET.** Do **not** bind the database owner / `service_role` boundary until
   **`A12`**'s retention/erasure mechanism is decided.
4. **User-facing logging claim: ONLY WITH QUALIFICATION.** **No universal access-logging claim may
   be made.** A3's PARTIAL coverage and the three accepted blind spots are preserved.

#### Consequences that follow from A11 alone — recorded, not remediated

- **The named adversary is precisely the party that is not yet bound.** Sub-ruling 1 names the
  **compromised Edge Function**; **17 of 19** Edge Functions hold the `service_role` key, and that
  role bypasses RLS. Sub-ruling 3 defers binding the owner/`service_role` boundary until `A12`.
  **Therefore, until `A12` is decided and the sub-ruling 2 anchor exists, the design is not
  defended against its own named adversary.** Stated plainly because it must not be discovered
  later.
- **Sub-ruling 3 defers the mechanism of A3 sub-ruling 5; it does not reverse it.** A3 ruled that
  `service_role` **must be constrained** from bypassing audit controls. A11 sequences that binding
  behind `A12`. The intent stands; only the implementation waits.
- **Grant- and policy-based mechanisms are insufficient by construction against this adversary.**
  A compromised Edge Function holds `service_role`, so omitting write policies and `REVOKE`
  bind nothing relevant. Verified: the tree contains exactly **one** `REVOKE` of UPDATE or DELETE
  (`117:216`, against `authenticated`) and **zero** `REVOKE … FROM service_role`. `FORCE ROW LEVEL
  SECURITY` would bind the **owner** but **not** `service_role`, which is `BYPASSRLS` at the role
  level.
- **Only one in-database mechanism binds the named adversary, and its DELETE form is
  unprecedented.** A `BEFORE UPDATE` trigger that RAISEs binds every caller at the DML layer
  (`120` precedent, 11 such triggers exist). There are **zero** `BEFORE DELETE` triggers and
  **zero** `FOR EACH STATEMENT` triggers tree-wide, so `TRUNCATE` and row DELETE have no
  precedented guard. Sub-ruling 2 is consistent with this: DML binding alone is not enough.
- **What may be claimed today.** Under sub-rulings 2 and 4, and with A3's best-effort emit, the
  honest claim is **integrity of the retained record** — never completeness, and **not**
  tamper-resistance until the anchor exists. Related observation, not a new finding: N07's
  user-facing copy *"Opening it is logged"* would be an unqualified universal claim, which
  sub-ruling 4 disallows. N07 remains **evidence only — not adopted, not applied, NOT MODIFIED.**
- **Event's freeze ruling requires a column classification that does not yet exist.** Every column
  must be assigned to identity/occurrence (frozen) or annotation (writable). The `120` precedent
  shows the shape — it freezes `session_id`/`set_id`/`exercise_instance_id` while leaving other
  columns editable — but no such classification exists for any audit population.

**A11 changes no finding's status**, allocates no registry ID, and remediates nothing.

### 8.7 `D4 · A12` — ANSWERED — retention, de-identification, erasure

Owner decisions, recorded as supplied. **A12 only. `A13` remains OPEN and nothing below decides
or implies it.**

| # | Ruling |
|---|---|
| **1 · Erasure model** | **ANONYMISE-AND-RETAIN** |
| **2 · A11 Event freeze** | **NO exception — use an external mapping.** The frozen row is never mutated |
| **3 · Precedence** | **PER-CATEGORY** — *"mandatory legal/regulatory retention controls where applicable; otherwise erasure applies, using de-identification where possible"* |
| **4 · Windows** | Event **6 years** · Incident **6 years** · Control evidence **6 years** · Financial/tax **7 years** |
| **5 · Governing regime** | **BOTH** — *"apply the applicable mandatory requirement by data category; where retention is mandatory, retain the minimum necessary data and de-identify where permitted"* |
| **6 · Erasure executor** | **A NEW CONSTRAINED ROLE.** May that party be `service_role`? **NO** |
| **7 · Public copy** | False export claim → **AMEND COPY**. Unratified 30-day window → **AMEND COPY** |
| **8 · Privacy §6 indefinite anonymised retention** | **STAND BEHIND** |

**The windows in ruling 4 are recorded verbatim as owner-selected architectural defaults
*pending legal/compliance ratification*. They are NOT claims that any such legal requirement
exists**, and must not be cited as one.

#### Consequences that follow from A12 alone — recorded, not remediated

- **Ruling 6 requires a structural first.** `CREATE ROLE` has **zero occurrences in
  `supabase/migrations/`**, as do `CREATE SCHEMA` and `OWNER TO`. A new constrained role has **no
  precedent to copy** in this repository. Everything currently lives in `public`, owned by the
  migration-running role.

  > **PRECISION CORRECTION.** This bullet previously said `CREATE ROLE` has zero occurrences
  > *"tree-wide"*. **That was too strong.** There are **six**, all in
  > `supabase/tests/local/shim.sql:23–28`, where the offline harness recreates Supabase's **built-in
  > platform roles** (`anon`, `authenticated`, `service_role`, `authenticator`,
  > `supabase_auth_admin`, `supabase_admin`) so local tests can run. **None creates an application
  > role, and none is in a migration**, so the "no precedent to copy" conclusion is unaffected —
  > but the count was wrong and is corrected rather than left to be found later.
- **Ruling 6 satisfies A11 sub-ruling 3's deferral condition.** A11 deferred binding the
  owner/`service_role` boundary *"until `A12`'s retention/erasure mechanism is decided."* It is now
  decided, and the executor is explicitly **not** `service_role`. The binding intent of A3
  sub-ruling 5 therefore has a named beneficiary; **implementing it remains future work and is not
  authorized here.**
- **Ruling 2 carries a write-path implication forward.** An external pseudonymous mapping —
  severed to anonymise, leaving the frozen Event row untouched — is machinery **A3 did not
  contemplate**. A3's three write paths (trigger · RPC · application) remain as decided; the
  mapping is an **addition** to be specified downstream, **not** a reversal of A3. Where the
  mapping lives, and who may sever it, are open.
- **The A2 recursion is unresolved by A12.** Export/deletion events are IN, so the act of
  anonymising is itself auditable and produces a **new** Event naming the subject. Nothing tracked
  resolves this, and A12 does not.
- **Ruling 7 names required copy changes that are OUTSIDE this document's mutation boundary.**
  `privacy_policy_screen.dart:85` still claims *"a full export of your data at any time from
  Profile → Settings → Account"* and **no export path exists anywhere**; the 30-day purge window is
  unratified and held at a custody checkpoint. **Neither string is edited here**, and no
  application file is modified. Recorded as required work, not performed.
- **Ruling 8 stands behind a promise with no mechanism.** Privacy §6 already tells users that
  *"aggregate, anonymised"* data is *"retained indefinitely to improve our AI models."* No
  de-identification routine exists anywhere in the repository.
- **A tracked release gate bounds ruling 7.** `RELEASE_GATES.md` gate 8.2 requires in-app deletion
  end-to-end **including an audit record**, and Guideline 5.1.1(v) makes an email-only path
  untenable for an App Store release. Amending copy does not clear that gate.
- **No retention machinery exists to build on.** Zero soft-delete columns, no TTL, no purge job;
  `pg_cron` exists but is used only for coaching and accountability timing. A12 sets retention
  **de novo**.
- **What retention actually preserves, stated honestly.** Under A3's PARTIAL coverage, its three
  accepted blind spots and best-effort emit, the retained ledger omits four of A2's fourteen
  categories and observes **8.7%** of data-access calls. **Absence of a row proves nothing, and no
  retention window converts a partial log into a complete one.**

**A12 changes no finding's status**, allocates no registry ID, and remediates nothing.

### 8.8 `D4 · A13` — ANSWERED — who may read audit records

Owner decisions, recorded as supplied.

**Readers per A1 population:**

| Population | Readers |
|---|---|
| **Event** | active coach · admin · Trust operator |
| **Incident** | actor · active coach · admin · Trust operator |
| **Control evidence** | admin · Trust operator |

**Seven sub-rulings:**

1. **May the audited party read its own audit? NOT FOR ADMIN ACTIONS.**
2. **Does a subject retain read access after their own anonymisation? NO.**
3. **Reader model: MIXED** — *"relationship-based authorization for subject/actor/active-coach
   access; role-class authorization for admin and Trust operator access."*
4. **Do erasure authority and read authority coincide? NO.**
5. **Are audit reads themselves audit-worthy? YES** — *"record audit-read activity at the
   application/access layer, but do not recursively generate another audit record for the
   audit-read event itself. The recursion boundary is the audit-read operation itself."*
6. **Frozen row vs identity mapping: TWO SEPARATE AUTHORIZATIONS.**
7. **Answer now, not deferred to `D-D1`.**

#### Consequences that follow from A13 alone — recorded, not remediated

- **The subject is not a reader of any audit population.** This diverges from **both** existing
  artifacts: `decision_traces` (`128:86-99`, owner-ruled PD-A05) admits `subject_id` and
  `created_by`, and N07 admits `client_id` (subject) and `coach_id` (actor). It also departs from
  N07's stated rationale — that *"Opening it is logged"* be verifiable *"by the person it
  protects, rather than merely asserted at them."* Recorded as a deliberate ruling, not an
  oversight, and **noted because it is the most consequential divergence in A13**.
- **Sub-ruling 5 resolves the A2 recursion** that A12 left open. Audit-read activity is recorded
  at the application/access layer and the audit-read operation is itself the recursion boundary.
  This does **not** resolve the separate A2 recursion on *anonymisation* events, which remains
  open.
- **The Trust operator is named as a reader of all three populations and does not exist.**
  *(**§8.17**: `D-D1` is now answered **TRUST OPERATOR**, so the role is owner-mandated. It still
  does not exist in any migration — the decision creates an obligation, not an object.)*
  `CREATE ROLE` has **zero** occurrences in `supabase/migrations/` (the only six in the tree
  recreate Supabase's built-in platform roles in the offline test harness — see the precision
  correction at §8.7), and **`D-D1`** — whether a Trust product area
  exists at all — is a live unresolved owner decision (§8.1). Sub-ruling 7 answers A13 **anyway**,
  deliberately. A13 therefore depends on an entity whose existence is still open.
- **Sub-ruling 1 requires a mechanism that does not exist.** Excluding an admin from their own
  admin-action records means a predicate distinguishing actor-identity from reader-identity within
  one population. No policy in the repository does this, and **no audit-shaped policy uses `admin`
  alone** — the two `admin`-only policies in the tree (`020` vendor events, `039` platform
  settings) are not audit reads.
- **Sub-ruling 4 keeps `see` and `unmake-identity` apart**, and with sub-ruling 6 makes the
  external mapping a separately authorized object. Who may resolve identity through it is **not**
  settled by A13.

#### `D4` is NOT complete — one sub-decision remains

The register that enumerates D4's sub-decisions lists **seven** as open: `A2`, `A3`, `A6`,
`A11`/`A-NEW`, `A12`, `A13`, `A14`. Five are now answered (§8.3, §8.5, §8.6, §8.7, §8.8, with
topology at §8.4). **Two had not been put at the time `A13` was decided.** One of those two —
`A6` — was **subsequently answered** and is recorded at **§8.9**; the paragraph below is retained
as the state at the time of the `A13` decision and is **superseded on `A6` by §8.9**. `A14` alone
remains OPEN:

- **`A6` — before/after state capture.** *(**SUPERSEDED — ANSWERED at §8.9.** Retained as the
  state at the time of `A13`.)* Recorded as *not* a V5 requirement, and as carrying a
  **PHI consequence** if adopted: capturing before/after values puts the changed data itself into
  the audit store. Untouched by A2, A1, A3, A11, A12 or A13. **§8.9 answered it NON-PHI DELTAS
  ONLY, which avoids rather than resolves that PHI consequence.**
- **`A14` — Trust visibility rules.** Recorded as depending on **`A13` and `D11`**. A13 is now
  answered; **`D11` is not** — and `D11` additionally carries a tracked/untracked status conflict
  (§8.1 lists it unresolved; an untracked register marks it *"RESOLVED — build open"*; **the
  tracked document governs**).

**`D4` therefore remains OPEN pending `A14` alone** (`A6` was answered at §8.9 after this
paragraph was written), and `A14` is itself blocked on `D11`.

**A13 changes no finding's status**, allocates no registry ID, and remediates nothing.

### 8.9 `D4 · A6` — ANSWERED — before/after state capture

Owner decision, recorded as supplied.

**`A6` — NON-PHI DELTAS ONLY.** Before/after values are captured for delta-bearing categories that
carry no PHI. **PHI-correction deltas are excluded.**

**The A11/A12 payload conflict does not arise** — PHI payloads are not adopted, so the owner
recorded the resolution question as **N/A**.

#### Consequences — recorded, not remediated

- **The conflict is AVOIDED, not RESOLVED.** A11 freezes identity; A12 anonymises by severing an
  external identity mapping; **neither reaches a payload**. That collision is dormant only because
  no PHI payload is captured. **If `A6` is ever widened to PHI deltas, the conflict returns
  unchanged** and would require amending A11's freeze, holding payloads out of anonymisation
  scope, or narrowing by category. Recorded so a future widening does not appear cost-free.
- **Which categories this reaches.** Of A2's 14 IN categories, **nine carry a delta**: PHI
  corrections · admin actions · billing/entitlement changes · financial/charge trail ·
  relationship changes · incidents · agent actions (writing ones only) · export/deletion events ·
  storage/media (the revocation/replacement arm). **Five are occurrences with no delta**: PHI
  reads · authorization denials · authentication · observability audit events · control evidence.
  Under this ruling, **PHI corrections are the excluded case**; the others carry role, tier,
  commission, payout, status or Stripe-identifier values — **not PHI**.
- **An implementation question this ruling does not settle, flagged not inferred.** Whether a
  PHI-correction record still carries the **changed-column NAME set** (metadata, not values) is
  **not decided** — "changed-column names only" was a separate option and was not the one chosen.
  Relevant evidence: `114_rls_weekly_checkins.sql:76-78` **already computes** that name set by
  diffing `to_jsonb(NEW)` against `to_jsonb(OLD)`, uses it for authorization, and **discards it**.
- **Before/after capture is already precedented here.** `094_continuous_coaching_engine.sql:125-127`
  writes a literal `'before'`/`'after'` jsonb pair into `result->'diff'`, carrying training
  parameters (volume multiplier, deload flag) — **not PHI**. `096` reads it back. So A6 adopts a
  shape the codebase already uses.
- **No trigger anywhere writes an `OLD` value into any table.** All ten files using `OLD.` are
  compare-and-reject or compare-and-restore guards. A6 would be the first delta **persisted by a
  trigger**, though not the first delta persisted at all.

### 8.10 `D12` — SCOPE ANSWERED — observability

Owner decisions on **scope only**. **`D12` itself remains OPEN**; nothing below decides its
content.

| # | Ruling |
|---|---|
| **D12 vs `PD-A24`** | **SUPERSET** — `PD-A24` sits **inside** `D12` |
| **`SQ-10`** | **ENTRY CONDITION** for **P2** — not deferrable past it |
| **Correlation identifier** | **`D12` owns it** |

#### Consequences — recorded, not remediated

- **`PD-A24` is not superseded and must not be re-decided here.** It is **TRACKED**, **OPEN**, and
  assigned to *Julia + privacy*, covering observability vendor, cost and data-residency posture.
  As a subset of D12 it retains its own owner and status; **D12 must not fork it.**
- **P2 is now strictly tighter.** Its entry condition was `D4, D12`; with `SQ-10` ruled an entry
  condition, **P2 cannot exit on audit alone** — the observability foundation is required. This
  **increases** what P2 must deliver before P5 Admin, P6 Trust and P7 AI Guardian can begin.
- **The correlation identifier now has an owner, and nothing to build on.** Verified, **excluding
  this document itself**: **zero** occurrences of `correlation_id`, `x-request-id`, `requestId`,
  `request_id` and **zero** of `span_id` anywhere in the tracked tree.

  > **CORRECTION (recorded, not quietly amended).** This bullet previously also claimed zero
  > occurrences of *"any trace/span id"*. **That was false.** `trace_id` occurs **25 times across
  > 13 tracked files** — `089`, `093`, `094`, `096`, `116`, `119`, `explain-decision/index.ts`,
  > four Flutter files, a unit test and a QA report. The claim's **intent** was correct and the
  > sentence that follows it always carried the real point; the literal wording was not. It is
  > corrected here rather than deleted, so the error is visible.

  Those 25 occurrences are **not a request-correlation identifier**. `trace_id` is the
  *name under which `decision_traces.id` is surfaced to callers* — `089:130` returns
  `jsonb_build_object('trace_id', v_id)`. It is domain-scoped to engine generations and carries no
  HTTP request, edge invocation, mobile session or API call.
  A1 sub-ruling 3 separated audit from observability, which is precisely what makes a **shared
  identifier** necessary to reconstruct one incident across both. **D12 must mint it.**
- **PRECISION HAZARD — "17 of 19" names TWO DIFFERENT SETS of seventeen.** This document uses the
  figure in both senses and they must never be conflated. Verified by set difference:

  | figure | the 19 minus… |
  |---|---|
  | **17 hold `SUPABASE_SERVICE_ROLE_KEY`** (§8.4, §8.6) | `analyze-food-image`, `enrich-exercise` |
  | **17 carry `console.*`** (30 calls total, this section) | `notify-coach-email`, `send-checkin-reminder` |

  **The two omitted pairs are disjoint.** Any argument that moves from one figure to the other —
  for example inferring that the service-role holders are the ones already emitting logs — is
  **unsound**, and no such inference is made here.
- **What exists today, verified.** One interface — `apps/mobile/lib/core/observability/app_failure.dart`
  — and **no observability system**. Its default sink is `if (kDebugMode) debugPrint(...)`, so
  **release builds record nothing at all**; its own comment says so, *"until PD-A24 is answered."*
  Elsewhere: 30 unstructured `console.*` calls across 17 of 19 Edge Functions **(see the warning
  below — this is NOT the same seventeen as the service-role seventeen)**; two NestJS `Logger`
  call sites with no transport; **no `/health`, no `/metrics`, no log aggregation, no alerting**;
  **zero observability, metric or telemetry tables** in the migration tree.
- **`observability_screen.dart` is NOT SQ-10 coverage** and must not be counted as such. Its own
  header says *"coaching QUALITY, not servers"*; it row-counts domain tables, and its `cnt()`
  helper swallows errors — **a failed query renders as the metric zero**, indistinguishable from a
  true zero.
- **Provenance limit on `SQ-10` itself.** `SQ-10` appears in this **tracked** document only as a
  dependency-graph node with **no component list**. The component list exists solely in an
  **untracked** analysis file, names **eight** items, and does **not** contain the words
  *"structured"* (of logs) or *"operational dashboards"*. **Ruling SQ-10 an entry condition does
  not ratify any particular component list**, which remains uncommitted and unversioned.

### 8.11 `EC-01` / `LRE-27` / `LRE-28` — INVESTIGATION AUTHORIZED

**Owner disposition: INVESTIGATE FURTHER.** This is **not** a closure change and **not** a
re-opening. No finding status moves.

**The condition being investigated, verified:** `EC-01` is recorded `✅ VERIFIED_CLOSED 2026-08-27`
in `MASTER_REMEDIATION_REGISTRY.md:769`, carrying **`LRE-27`** (*"No observability anywhere"*, P1)
and **`LRE-28`** (*"No audit log"*, P1) as aliases — while the same row's own text at `:773` reads
*"invisible twice over."* The closure was class **RELEASE / ENVIRONMENT** and covered the failure
**sink interface** only; neither alias's substantive condition was addressed.

**`MASTER_REMEDIATION_REGISTRY.md` is outside this document's mutation boundary and is NOT edited.**
The condition is recorded here; any status change is a separate, separately-authorized act.

**Relevance to `D12`:** `LRE-27` is the observability finding and sits on release gate **G-14**.
Its disposition bears directly on whether D12's content can be scoped against an accurate finding
ledger.

#### Investigation result — evidence only. **No status changes. Nothing is proposed.**

Every claim below was verified independently against HEAD. `MASTER_REMEDIATION_REGISTRY.md` is
**read, never written.**

**(a) `EC-01` carries FOUR aliases, not two.** `:190` — *"`EC-01` | REL-26, LRE-27, LRE-28,
EC-23"*. §8.11 above named only two. `REL-26` and `EC-23` are also collapsed into it.

**(b) The alias mechanism has NO tracked definition.**
`grep -i "alias" docs/QA_CLOSURE_STANDARD.md` returns **zero hits** — the document that governs
every status change **never uses the word**. The registry's §3 does, but only about bookkeeping:
`:148–149` *"The alias must not be used as a tracking key after this document"*; the column header
is *"Aliases retired"*; `:3413` *"The alias map (§3) is closed. Do not resurrect a retired ID."*
**No tracked text states either that closing a canonical discharges an alias's substantive
condition, or that the alias retains independent status.** Two positions coexist unreconciled:
`:2102` asserts *"`EC-23` **closes with it**"* as an inference from §3, while `LRE-27`/`LRE-28`
remain bound to gate **G-14** and listed under the **open** `PD-A24`.

**(c) The closure's own "what this does NOT do" list never names either alias.** `:2105–2113`
enumerates the exclusions and names only `EC-05` and the Phase-B4 backlog. Verified: **no `LRE-2*`
string occurs in that range.** So the record is silent, not affirmative, on both aliases.

**(d) The scope asymmetry is total.** `EC-01`'s own origin statement bounds it to
`apps/mobile` (*"`apps/mobile/pubspec.yaml`; all of `apps/mobile/lib`"*). `LRE-27` spans **three
tiers** (mobile + API + all 19 Edge Functions). `LRE-28` is a **database table** with RLS.
**`LRE-28`'s remediation — an append-only `audit_log` table — has zero subject-matter overlap with
a Dart `reportFailure` function.** The alias map is the only thing joining them.

**(e) Both aliases' conditions are verifiable-TRUE at HEAD by their own stated evidence methods.**
Re-verified, not inherited: zero `sentry|crashlytics|datadog|opentelemetry` in
`apps/mobile/pubspec.yaml` or `apps/api/package.json`; **zero** files matching
`audit_log|audit_events|activity_log` in `supabase/migrations/`. `LRE-27`'s reproduction
(*"cause a crash in a QA build; nothing records it"*) **still reproduces**, because a QA build is
release mode and the default sink is a no-op there.

**(f) What the closure actually delivered.** `app_failure.dart` — `AppFailure`, `FailureSink`,
`reportFailure`/`reportError`. **23 real `reportError` call sites** in `lib/` (a 24th grep hit is a
comment in `messaging_service.dart` describing the `ec23` regex), against the file's own
denominator of **~234** swallow sites, with classification deferred to Phase B4. **No sink is
installed at start-up** — `setFailureSink` is annotated `@visibleForTesting` and `main.dart`
references neither it nor `app_failure`. `AppFailure` has four fields — `origin`, `error`,
`stackTrace`, `context` — and **no environment field and no release field.**

**(g) `G-14` cannot be evaluated as passed on this closure.** Its condition has three conjuncts —
*"Error tracking live in all three tiers, tagged by environment and release; audit log in place"* —
and **all three are false at HEAD** (one tier, debug-only, not live; no env/release fields per (f);
no audit table per (e)). The gate's own governing sentence forecloses the alternative reading:
*"A gate is met when its check passes in CI, **not when someone believes it is true**."* **NOT
FOUND:** no tracked document asserts that `G-14` is met, partially met, or advanced by this closure.

**(h) The closure is procedurally CORRECT on the class it was assigned — and this is the seam.**
§2.1's **Release / environment** row demands `FIXED IN CODE · VERIFIED IN CI` and nothing more, and
**both are present**, including a genuine pre-fix red in CI (run #34's `ec23` negative control).
The standard's two rules that would otherwise bite do **not** reach it, because each carries an
explicit scope clause:
- §4:105 *"Necessary, never sufficient"* — scoped *"**for a security finding**"*. The `ec23` guard
  is structurally the same instrument (a regex over source text) but `EC-01` is not a security
  finding.
- §5.2 *"Test the class, not the instance"* — under the heading *"Security findings"*. The wiring
  assertion pins **three named instances** out of ~234.
Meanwhile §2's own ladder states that `VERIFIED IN CI` *"does not prove **that the deployed
environment behaves as the code implies**"* — and the deployed environment is the entire subject of
`LRE-27`. **Both things are true at once and the tracked corpus contains no rule reconciling them.**

**(i) One requirement that is NOT class-scoped appears unmet.** §10 requires the one-line test —
*"if this defect were reintroduced tomorrow… what exactly goes red, and where does someone see it"*
— to be answered *"**in writing, in the registry row**"*, with **no scope clause**. Verified: the
`EC-01` row (`:769`) and its §7.13 checkpoint (`:2001–2113`) contain **no such answer**, while the
comparable `I-WRK-01` closure at `:1415` carries one, explicitly labelled *"§10 one-line test"*,
enumerating three standing guards. **This is recorded as an observation about the tracked record.
It is NOT a finding, NOT an ID, and NOT a proposed status change.**

**Counting caveat.** A naive `git grep -n "EC-01"` returns **103** lines **outside this document**,
but most are substring matches inside `SEC-01` / `QAX-SEC-01` / `QAX-SEC-010`. The word-boundary
count (`grep -E '(^|[^A-Za-z-])EC-01'`) is **32**. Any figure for "EC-01 mentions" taken from an
unanchored grep is inflated by roughly 3×. *(Both counts exclude this file, whose own text would
otherwise inflate them — the first count taken while writing this section did not, and was wrong
for that reason.)*

#### What must be answered — options preserved, **none chosen**

1. **~~Does `EC-01`'s closure discharge `LRE-27` and `LRE-28`?~~ — ANSWERED §8.15:
   REFERENCE-ONLY.** The alias is a de-duplication pointer; the closure **neither discharges nor
   preserves** their conditions, and substantive status must be determined **separately for each**.
   That separate determination is **not performed** here. **Questions 2–5 below remain OPEN.**
2. **May a closure-class ruling made for a canonical bind aliases that would fall in a different
   class?** The ruling is recorded as *"explicitly confined to `EC-01`"* and the programme twice
   refused to carry it to **other canonicals** — but **the case of `EC-01`'s own aliases has never
   been put.**
3. **Can `G-14` be evaluated at all**, given its three conjuncts, or is it unevaluable until each
   has a mechanical check?
4. **Is the §10 written answer a precondition this closure did not meet** — and if so, is that a
   defect in the closure, or in the row's completeness?
5. **Does the tracked corpus need a definition of alias semantics** before this or any similar
   question can be disposed of?

**No status changes. `EC-01` remains `VERIFIED_CLOSED` in the registry; this document does not
alter it. `LRE-27` and `LRE-28` remain as the registry records them. `PD-A24` remains OPEN and is
not re-decided. No registry ID is allocated. Nothing is remediated.**

---

### 8.12 `D11` — PREPARED, **NOT ANSWERED** — Trust scope

**No owner decision is recorded here.** This section records verified evidence about `D11` so the
decision can be put. `D11` remains **OPEN**. Nothing below closes a finding, allocates an ID, or
changes a status.

#### Finding 1 — `D11` has **no tracked statement anywhere**

`D11` appears in exactly one tracked **text** file — this one (`git grep -lI -- D11`) — and in
**every case as a dependency reference only**: §5.1 (:166), §5.2's P6 row (:230), §8.1's carried-forward list (:376, :379),
§8.1's `D-D1` analysis (:392, :394, :395), §8.8's `A14` note (:772–:773), and §11 · DEFERRED SCOPE (:1074). **Not one
of these states what `D11` asks.** *(Line numbers in this section are relative to this file at
the commit that introduced §8.12; the section references are the durable citation.)*

The question text exists **only in untracked analysis**:
`QA_TO_V5_TRANSITION_RECONCILIATION_2026-09-27.md:336` — *"What is Trust's actual scope?"*

`git ls-files` returns nothing for that file, nor for the other three files that mention `D11`
(`V5_DECISION_RESOLUTION_2026-09-27.md`, `V5_IMPACT_ANALYSIS_2026-09-27.md`,
`V5_IMPLEMENTATION_READINESS_GATE_2026-09-27.md`).

**Consequence:** `A14` is blocked, and `P6 · TRUST` is gated, on a decision whose question is not
recorded in any tracked document. This is a **provenance gap, not a decision**, and it is preserved
rather than repaired: writing a question text here would be inventing the decision's content.

#### Finding 2 — the tracked/untracked conflict is **narrower** than "resolved vs unresolved"

§8.8 recorded that an untracked register marks `D11` *"RESOLVED — build open"*. Reconciled against
all four untracked sources, they do **not** disagree with each other, and none of them asserts
`D11` is fully resolved:

| source (all **UNTRACKED**) | line | wording |
|---|---|---|
| `V5_DECISION_RESOLUTION` | :88 | *"**V5 names 4 areas**" … "**RESOLVED — build open**"* |
| `V5_IMPACT_ANALYSIS` | :449 | *"scope resolved; **build unresolved**"* |
| `V5_IMPLEMENTATION_READINESS_GATE` | :385 | *"largely resolved by V5; **build scope open**"* |
| `QA_TO_V5_TRANSITION` | :336 | *"**Nothing is evidenced**; scope determines everything downstream"* |

All four agree the **build scope is open**. The word "RESOLVED" attaches only to the *naming* of
areas. **The tracked document governs, and it records `D11` as unresolved** — but the conflict to
preserve is now specific: it is a disagreement about whether *naming* constitutes *scoping*, not
about whether `D11` is done.

The same untracked register that marks `D11` "RESOLVED" **also** records `A14` as
*"**OPEN.** Depends on A13 and D11"* (`V5_DECISION_RESOLUTION:157`). **Even the untracked source
does not treat its own "RESOLVED" as unblocking `A14`.**

#### Finding 3 — the untracked resolution rests on the **`D-D1` question**, which is OPEN

The stated basis for "RESOLVED" is *"V5 names 4 areas"* — Security · Incidents · Audit Logs ·
**AI Guardian** (`V5_IMPACT_ANALYSIS:286`). But naming those four as one area **is the `D-D1`
question verbatim**: §8.1:384 poses it as *"Are Security / Incidents / Audit / Guardian a separate
'Trust' product area, or Admin domains?"*, recorded **deliberately unfilled** in a **tracked** file
(`V5_SECURITY_FOUNDATION_WAVE1_AUTHORIZATION.md` §1: `TRUST = [INSERT OWNER DECISION HERE]`).

And this document **does not group those four**: §5.2 scopes **`P6 · TRUST` to three** — Security ·
Incidents · Audit Logs (:230) — while **AI Guardian is a separate phase, `P7`** (:231), entered on
`P2, P6, D-V5`. The untracked register's four-area count and this document's phase split
**disagree**.

**The untracked "RESOLVED" therefore presupposes an answer to `D-D1` that does not exist.** §8.1:394
already records the ordering: *"`D-D1` … gates P6 ahead of D11, which only scopes it."*

#### Finding 4 — Trust has **zero implementation evidence** at HEAD (verified, tracked)

Independently re-verified against tracked code at HEAD, not inherited from the untracked claim:

- **`trust`** — 3 hits across `apps/mobile/lib/`, **all unrelated English prose** in workout files
  (`workout_contract.dart:177` *"never trusted from the row"*, `workout_provider.dart:97`,
  `workout_restoration.dart:204`). **Zero Trust surfaces.**
- **`incident`** — 1 app hit (`terms_of_service_screen.dart:84`, *"indirect, incidental"*) and
  2 migration hits (`122:149`, `132:246`), **all unrelated English prose**. **Zero incident model.**
- **`trust` in migrations** — 15 hits across 9 files, **every one unrelated English prose**
  (*"trustworthy"*, *"the trusted server-side identity"*, *"an untrusted storage argument"*).
  **Zero Trust schema.**
- **Zero Trust database objects**, verified by object name rather than by word:
  `create (table|view|type|materialized view)` matching `trust` or `incident` returns **NONE**
  across all migrations.
- **0 Trust routes, 0 Trust designs** (`CONF-08` records the missing Admin/Trust designs and is
  itself unresolved).

*Search caveat, recorded so the claim is exactly as strong as its evidence:* an unrestricted
`git grep -l -- D11` also matches **`apps/mobile/assets/images/train-deadlift.jpg`**, a coincidental
byte sequence in a **binary** asset. The "exactly one file" claim above is stated over text files
(`-I`) for that reason, and is **not** a claim about binary assets.

So `D11` is not a decision about which of several built things to keep. **It scopes an area that
does not exist in any form**, which is why §6 Gate 11 reads **FAIL** on design readiness and §16
records Trust as *"blocked on D4, D11, CONF-08"* under **§11 · DEFERRED SCOPE**.

#### What must be answered — options preserved, **not chosen**

1. **Does `D-D1` have to be answered before `D11`?** §8.1:394 says it gates P6 ahead of D11. If so,
   `D11` is not the next boundary and `A14` stays blocked behind **two** decisions, not one.
2. **Is Trust's scope three areas or four?** This document's P6/P7 split says three; the untracked
   register says four. Both readings are recorded; neither is adopted.
3. **Does "V5 names the areas" discharge `D11`, or does `D11` require a build scope?** All four
   untracked sources say the build scope is open; the tracked document records `D11` unresolved.
4. **Should `D11`'s question text be admitted to the tracked record?** It exists only in an
   untracked file. Admitting it is an owner act, not a documentation act — **it is not done here.**

**`D11` is NOT answered. `A14` remains blocked. `D-D1` remains unfilled. `CONF-08` remains open.**
No status changes.

---

### 8.13 `D12` — CONTENT PREPARED, **NOT ANSWERED**

§8.10 answered D12's **scope**. Its **content** is OPEN and **no part of it is decided here.**
`PD-A24` remains **TRACKED, OPEN, owner *Julia + privacy*, wave 3B/8** and is **not re-decided.**
No registry ID, migration, schema, SQL or application code is proposed.

#### The SUPERSET relation, stated exactly

`PD-A24` covers **three things and only three**, by its own words: **vendor · cost · data-residency
posture.** Its Options field is literally *"vendor choice"*; its privacy concern is scoped to egress
(*"anything that **leaves the device**"*). **That part of D12 keeps PD-A24's owner and status.**

**The excess D12 adds**, none of which PD-A24's three fields reach: the **correlation identifier** ·
**`SQ-10`'s component list** · **whether the observability store is in-database** (a Postgres store
involves no vendor) · **structured logging of the server tiers** (30 `console.*` calls are not a
vendor problem) · **`/health`, `/metrics`, aggregation, alerting** · **observability retention and
reader model**.

There is tracked precedent that interface work is separable from vendor work: PD-A24 itself says
the sink *"can and should be built **before** the vendor is chosen — it is one interface"*, and
`app_failure.dart` was in fact built without it.

#### The Postgres constraint — the hardest fact for D12's content

**At HEAD there is exactly ONE request-scoped channel into Postgres, and this repository cannot
extend it.** Verified by search across `supabase/migrations/` and `supabase/functions/`:

| mechanism | production uses |
|---|---|
| `request.jwt.claims` (read by `auth.uid()`) | the **only** one — set by PostgREST from a **signed** JWT |
| `request.headers` (PostgREST's header GUC) | **ZERO**, anywhere under `supabase/` |
| `set_config` by a **caller** for request context | **ZERO** |
| `SET LOCAL` in migrations or functions | **ZERO** |

The single `set_config` in the tree (`115:387`, `:390`) is set by a definer function **on itself**,
`is_local = true`, and carries a two-valued privilege flag — **not** request context and **not**
caller-supplied.

**Consequence.** An audit row written by one of the **33 `CREATE TRIGGER` statements** in the
migration tree (34 matching lines, one of which is a comment; the count is of **statements**, not
necessarily of surviving triggers) can see **no caller-supplied value
whatsoever** beyond `NEW`/`OLD` contents and `auth.uid()` — and `auth.uid()` is **NULL on every
internal path**. So a correlation identifier reaching a trigger-written audit row **has no existing
channel to arrive on.** Naming the gap is not proposing the change: **no mechanism is proposed here.**

#### Trustworthiness — the identifier is forgeable by construction at HEAD

Any caller-supplied value other than the signed JWT claims is unsigned and unverified, and **there
is no precedent in the tree for validating one.** Worse, `A11` sub-ruling 1's named adversary is the
**compromised Edge Function**, and such a function holds `service_role`, which is `BYPASSRLS`. It
can therefore **write the identifier into the audit row and write or withhold the matching
observability record** — both sides of the very join the identifier exists to make. `A3` sub-ruling
3's requirement that asserted and cryptographically grounded attribution *"must not be equated"*
reaches the correlation identifier directly, and **nothing tracked addresses it for that dimension.**

#### **NEW CONTRADICTION — between two ANSWERED rulings. Preserved, NOT resolved.**

> **`A2` places observability audit events IN. `A1` places them OUTSIDE.**
>
> - **§8.3, A2, tier 2:** *"incidents · agent actions · control evidence · admin actions ·
>   **observability audit events**"* → **IN (all five)**.
> - **§8.4, A1, sub-ruling 3:** *"audit and observability audit events are **TWO DISTINCT
>   populations**… **observability audit events sit outside them** and are **not a fourth audit
>   population**."*
>
> Both are recorded owner decisions, in this document, neither superseding the other. The tension
> is not merely verbal: A2 makes the category **audit-worthy**, while A1 leaves it **no audit
> population to live in**. **This document does not choose a reading.** It is put to the owner
> below as question 4. **ANSWERED at §8.14: `A2` CONTROLS** — the category stays audit-worthy and
> becomes a separate D12/observability population. Both rulings are preserved; the supersession is
> confined to reading *"sit outside them"* as a scope statement rather than a topology statement.

This contradiction decides roughly **half of D12's remaining content**, because it determines
whether D12's records inherit `A11`'s immutability, `A12`'s retention and `A13`'s reader model.

#### Other gaps that bear on D12's content

- **`A12`'s four retention windows name no observability population** (Event 6y · Incident 6y ·
  Control evidence 6y · Financial/tax 7y), while the untracked `SQ-10` list names retention a
  component. **No tracked window exists for observability.**
- **`A13` names no observability reader**, because its mixed model is assigned *per audit
  population* and observability sits outside them. The **Trust operator does not exist** (`CREATE
  ROLE`: zero tree-wide).
- **A structural hazard:** if the correlation key spans both populations and the observability side
  carries identifying data, then severing `A12`'s external mapping **does not anonymise the
  operation**. Unaddressed in any tracked file. **UNRESOLVED.**
- **`SQ-10`'s tracked and untracked descriptions are not supersets of each other in either
  direction** — the untracked list omits *"structured"* and *"operational dashboards"*; the tracked
  document names no components at all.
- **`D17`'s statement text is absent from the tracked tree**, so its bearing on D12 **cannot be
  assessed.** Recorded, not guessed.

#### What must be answered — **twelve questions, none chosen, none ranked**

1. **Does D12 adopt a component list for `SQ-10`, and which?** Ratify the untracked eight ·
   author a tracked list · rule components out of D12. *(Not blocked.)*
2. **Where is the correlation identifier minted?** Client · first server-side touch · Postgres ·
   each origin with a provenance tag. *(Not blocked; `A3` constrains it.)*
3. **Does the identifier appear on the audit Event row?** *(Decision not blocked; **delivery** is
   downstream of `D4`, which is open on `A14`, which is blocked on `D11`.)*
4. **~~Are observability audit events inside the audit ledger or outside it?~~ — ANSWERED §8.14,
   `A2` CONTROLS.** Audit-worthy **and** a separate D12/observability population. This settles
   scope-vs-topology **only**; whether D12's records inherit `A11` immutability, `A12` retention and
   `A13` readers is **newly OPEN** and none of the three currently reaches them.
5. **Does the identifier survive `A12` anonymisation, and on which side?** *(Not blocked.)*
6. **What is the retention window for observability records?** *(Option "defer to the vendor" is
   blocked on `PD-A24`.)*
7. **Is the observability store in-database, external, or both?** *(**Blocked on `PD-A24`** — data
   residency is its own field. Whether an in-Postgres store is separable from it is itself
   unresolved.)*
8. **Which tiers get `/health` and `/metrics`?** *(**Blocked on `PD-A17`** — tracked, OPEN, owner
   Julia; no deployment target exists and `API_BASE_URL` is empty in every environment.)*
9. **Does D12 include structured logging for the server tiers?** *(Partially blocked on `PD-A24`;
   the interface-before-vendor precedent bears on the unblocked option.)*
10. **Does the Flutter release sink get a destination under D12, or wait for `PD-A24`?**
    *(**Blocked on `PD-A24`**, except an in-repository destination, which depends on 7.)*
11. **Does D12 include alerting, and on what signals?** *(Partially blocked, downstream of 7.)*
12. **Who may read observability records?** *(**Blocked on `D-D1` and `D11`** — if the readers
    include a Trust operator, this cannot close ahead of `D-D1`.)*
    **STALENESS CORRECTION:** the `D-D1` half of that block is **discharged** by §8.17 — but
    **only as to the role**, and **Q12 is still NOT answered** (§8.17 states both). The **`D11`
    half stands**, and `D11` still has no tracked substantive definition. The **product-area
    residual** of `D-D1` also stands. **Net: partially unblocked, unanswered.**

**Two blockers operative on D12 that §8.1 does not list, flagged rather than absorbed:**
`PD-A24` (blocks 6d, 7, 9b, 10) and **`PD-A17`** (blocks 8). Both are **TRACKED and OPEN** with
owner *Julia*; **neither is re-decided here.**

**And the §8.11 investigation bears on all twelve**, because the finding ledger D12 would be scoped
against records its own subject — `LRE-27`, *"No observability anywhere"* — as closed.
**STALENESS CORRECTION:** §8.15 (alias REFERENCE-ONLY) removed that specific defect — `EC-01`'s
closure now **says nothing about `LRE-27`**, so the ledger no longer asserts what the evidence
denies. **What `LRE-27`'s status IS remains undetermined**, so the ledger is *readable*, not
*settled*.

**`D12`'s content is NOT answered. No status changes. No ID is allocated. Nothing is remediated.**

---

### 8.14 `D12 · Q4` — ANSWERED — **A2 CONTROLS** — observability audit events

**Owner decision: `A2` CONTROLS.** Observability audit events **REMAIN IN audit-worthy scope** and
are a **separate `D12`/observability population**.

**Both original rulings are preserved verbatim in place** (§8.3's tier-2 row, §8.4's sub-ruling 3),
each carrying a precedence marker pointing here. **Neither is deleted, edited or silently
reconciled.**

#### What each ruling keeps, exactly

| ruling | disposition |
|---|---|
| **`A2` tier 2 — *"observability audit events"* `IN` (all five)** | **STANDS IN FULL.** The 14 audit-worthy categories are unchanged; none is removed. |
| **`A1` sub-ruling 3 — *"TWO DISTINCT populations"*** | **STANDS.** |
| **`A1` sub-ruling 3 — *"schemas and semantics must not be merged"*** | **STANDS.** |
| **`A1` sub-ruling 3 — *"not a fourth audit population"*** | **STANDS.** The D12/observability population is **not** an audit population. |
| **`A1` sub-ruling 3 — *"observability audit events sit outside them"*** | **SUPERSEDED ON ONE READING ONLY.** |

#### The supersession, stated narrowly

**Superseded:** any reading of *"sit outside them"* as placing observability audit events outside
**audit-worthy scope**.

**The distinction this decision establishes:** *"outside the audit ledger"* is a statement about
**topology** — which population's schema a record lives in. It is **not** a statement about
**scope** — whether the category must be recorded at all. **A category can be audit-worthy and
resident in a non-audit population.** That is now the recorded architecture, and it is the whole of
what changes.

**Nothing else in `A1` is disturbed.** The three audit populations, the merge prohibition and the
"not a fourth population" clause are untouched. `A2`'s category list is untouched.

#### Consequences — recorded, not remediated

- **`D12` now inherits an obligation it did not have.** Because the category is **audit-worthy**
  but lives in a **D12** population, `D12` must decide whether its records take on `A11`
  immutability, `A12` retention and `A13` readers. **None of the three currently reaches it:**
  `A11`'s freeze applies to audit populations; `A12`'s four windows (Event 6y · Incident 6y ·
  Control evidence 6y · Financial/tax 7y) **name no observability population**; `A13`'s reader
  model is assigned **per audit population** and **names no observability reader**. **These remain
  OPEN and are not decided here.**
- **`A12`'s anonymisation hazard sharpens.** §8.13 recorded that a correlation key spanning both
  populations means severing `A12`'s external mapping may not anonymise the operation. Under this
  decision the record on the **non-audit** side is **also audit-worthy**, so the hazard now applies
  to a record the programme is obliged to keep. **Still UNRESOLVED** — it is `D12` question 5.
- **`D12` questions 6, 7, 11 and 12 are unchanged in status.** Where the records live, their
  retention window, alerting, and who may read them all remain **OPEN**, with `PD-A24` and `D-D1`
  blocking as recorded in §8.13. This decision settles **scope-vs-topology and nothing else.**
  **STALENESS CORRECTION:** this sentence predates §8.17 and is imprecise twice over. `D-D1` never
  blocked **6, 7 or 11** — only **12** — and its block on 12 is now discharged as to the role.
  **`PD-A24` remains accurate for 6(d), 7 and 11-via-7.** All four remain OPEN.
- **The 14-category count is unchanged**, so no downstream count in this document moves.

**No finding status changes. No registry ID is allocated. `D12` is not implemented. `D4` is not
implemented. `QAX-SEC-08` remains OPEN / PARTIALLY VERIFIED; `QAX-SEC-09` remains OPEN.**

---

### 8.15 `EC-01 · Q1` — ANSWERED — **ALIAS IS REFERENCE-ONLY**

**Owner decision: the alias map is REFERENCE-ONLY.** An alias is a **de-duplication pointer**.
Closing a canonical finding **neither discharges nor preserves** an alias's substantive condition:
**substantive status must be determined separately for each.**

#### What this does and does not touch

- **`EC-01` remains `VERIFIED_CLOSED`.** Its closure is **preserved**, and this document does not
  alter it. **`MASTER_REMEDIATION_REGISTRY.md` is NOT edited.** The closure remains procedurally
  correct on its assigned **RELEASE / ENVIRONMENT** class, exactly as §8.11 found.
- **`LRE-27` and `LRE-28` acquire NO status from that closure** — and equally, **none is taken away
  from them.** Their disposition becomes a **separate act**, and that act is **NOT performed here.**
  They are **not remediated** and **not re-opened**; they remain as the registry records them.
- **This applies to all four of `EC-01`'s aliases** — `REL-26`, `LRE-27`, `LRE-28`, `EC-23` — not
  only the two under investigation.
- **The absence of a tracked alias definition is PRESERVED, not repaired.** `QA_CLOSURE_STANDARD.md`
  still contains **zero** occurrences of the word *"alias"*. This ruling records the semantics in
  **this** document; **amending the closure standard is a separate, separately-authorized act and
  is not done here.**

#### The conflict this creates with an existing registry entry — recorded, not resolved

`MASTER_REMEDIATION_REGISTRY.md:2102` states *"**`EC-23` closes with it**: §3 records it as an alias
of EC-01, so it carries no separate row and no separate count."* **That is the discharging reading,
which this decision does not adopt.**

- **The registry text stands unedited** and is **outside this document's mutation boundary**.
- **`EC-23` is not re-opened**, its status is not changed, and no ID is allocated.
- **The conflict is recorded here rather than reconciled.** A future act that applies this ruling to
  the registry is a separate authorization.
- §3's own text is consistent with reference-only: it speaks solely of tracking keys and counts
  (*"The alias must not be used as a tracking key after this document"*; *"Aliases retired"*;
  *"The alias map (§3) is closed"*). **The discharging language at `:2102` is an inference drawn in
  §7.13, not a quotation of §3.**

#### Consequences — recorded, not remediated

- **`G-14` is unaffected by `EC-01`'s closure**, which §8.11 had already established on the
  evidence. Its three conjuncts — error tracking live in all three tiers · tagged by environment
  and release · audit log in place — **remain false at HEAD**, and `LRE-27`/`LRE-28` remain bound to
  it **carrying no status conferred by the parent.**
- **`D12`'s finding ledger is now readable without contradiction.** §8.13 recorded that D12 would be
  scoped against a ledger recording its own subject as closed. Under reference-only, `EC-01`'s
  closure **says nothing about `LRE-27`**, so the ledger no longer asserts what the evidence denies.
  **What `LRE-27`'s status IS remains undetermined** — that is the separate act above.
- **The `:773` internal tension in the `EC-01` row is untouched.** The row still reads *"invisible
  twice over"* four lines below its own `VERIFIED_CLOSED` mark. Reference-only explains why both
  sentences can stand; it does **not** rewrite either, and the registry is not edited.
- **§10's absent one-line test on the `EC-01` row is unchanged** — still recorded in §8.11 as an
  observation about the tracked record, **not a finding, not an ID, not a status change.**
- **`EC-01` questions 2, 3, 4 and 5 remain OPEN** (class binding across aliases · whether `G-14` is
  evaluable at all · the §10 precondition · whether the corpus needs an amended definition).
  **Only Q1 is answered.**

**No registry status changes. `LRE-27` and `LRE-28` are NOT remediated. `PD-A24` remains TRACKED,
OPEN, owner *Julia + privacy*. No ID is allocated.**

---

### 8.16 `D12 · INHERITANCE` — PREPARED, **NOT ANSWERED** — opened by §8.14

§8.14 made the D12/observability population **audit-worthy but not an audit population**. That
creates a question §8.14 explicitly did not settle: **does this population inherit `A11`
immutability, `A12` retention and `A13` readers?** Nothing blocks it. **No option is chosen here.**

#### The structural finding: all three rulings are keyed on `A1`'s audit populations

This is not an oversight to be patched — it is how each ruling is built. Verified:

| ruling | its shape | rows |
|---|---|---|
| **`A11` immutability** | a *"meaning of 'immutable', **per `A1` population**"* table | Event · Incident · Control evidence — **three** |
| **`A12` retention** | four windows, **per population** | Event 6y · Incident 6y · Control evidence 6y · Financial/tax 7y — **four** |
| **`A13` readers** | a Population → Readers table | Event · Incident · Control evidence — **three** |

**The D12/observability population appears in none of the ten rows.** It is keyed out of all three
rulings **by construction**, because §8.14 placed it outside the audit populations those tables
enumerate. **Each of the three must therefore be either extended to it or explicitly declined — and
neither has been done.**

#### What extension would actually import

- **`A11` offers three different meanings of "immutable" and none obviously fits.**
  `FREEZE-IDENTITY-COLUMNS` is built for a fixed occurrence record; `APPEND-STATE-TRANSITIONS` for
  something that evolves; `NO RUNTIME WRITE PATH` for *"authored/produced evidence, not a runtime
  audit event"* — and observability records are **precisely** runtime-produced and high-volume.
  **A fourth meaning may be required.** Recorded, not drafted.
- **`A11` sub-ruling 3 re-opens for this population.** It deferred binding the owner/`service_role`
  boundary *"until `A12`"*. `A12` settled that for the **audit** populations. **For a D12 population
  the same deferral has no resolution**, and the named adversary — the compromised Edge Function,
  which holds `service_role` in **17 of 19** cases — is the party that would write these records.
- **`A12`'s 6-year window is the audit default, not an operational one.** Extending it makes
  telemetry and logs 6-year records; `A12` ruling 8 (**STAND BEHIND** indefinite anonymised
  retention) would then reach them too. Note `A12`'s windows are recorded as *"owner-selected
  architectural defaults **pending legal/compliance ratification**, not claims that any such legal
  requirement exists"* — that qualification travels with any extension.
- **`A13` extension imports a dependency on `D-D1`.** **Every** row of `A13`'s reader table names
  the **Trust operator**, and that role **does not exist** — `CREATE ROLE` has zero occurrences in
  `supabase/migrations/`, and `D-D1` (whether a Trust product area exists at all) is **unfilled**.
  So extending `A13` to observability **cannot close ahead of `D-D1`**, exactly as D12 question 12
  already could not.

#### Interaction with the sharpened `A12` hazard

§8.14 recorded that the anonymisation hazard now applies to a record the programme is **obliged to
keep**. Inheritance decides its severity: if this population inherits `A12`, the correlation
identifier's lifetime becomes **6 years**, which is itself a data-residency fact that `PD-A24`'s
review would bear on. If it does not inherit `A12`, the population has **no** retention rule at all.
**Both branches are live. Neither is chosen.**

#### What must be answered — options preserved, **none chosen, none ranked**

1. **Does the D12/observability population inherit `A11` immutability?** Extend one of the three
   existing meanings · define a fourth · declare it mutable. *(Not blocked.)*
2. **Does it inherit `A12` retention?** Adopt the 6-year Event window · set a shorter operational
   window · per-component windows · no retention rule. *(Option "defer to the vendor" is blocked on
   `PD-A24`.)*
3. **Does it inherit `A13`'s reader model?** Extend the mixed model · a distinct operator class ·
   admin-only. *(**Blocked on `D-D1`** for any option naming a Trust operator.)*
   **STALENESS CORRECTION:** `D-D1` was answered at §8.17, so this block is **discharged as to the
   role**. **Q3 remains UNANSWERED**, all three options remain live — two of them
   (*distinct operator class*, *admin-only*) never named a Trust operator, so the answer narrows
   the option set **not at all** — and **the role still does not exist in any migration.**
4. **Does `A11` sub-ruling 3's owner/`service_role` deferral resolve for this population, and
   against what?** *(Not blocked, but the answer bears on 1.)*

**Nothing here is decided. No status changes, no ID is allocated, `D12` and `D4` are not
implemented, and `D11`, `A14` and `D17` are not invented.** *(`D-D1` was subsequently answered at
§8.17; question 3 above is unblocked as to the role, though the role still does not exist.)*

---

### 8.17 `D-D1` — ANSWERED — **TRUST OPERATOR** — the governance/reader boundary

**Owner decision: TRUST OPERATOR.** Trust is a **distinct governance role** responsible for
audit/observability review, erasure authorization and governance operations. **Admin and domain
roles do NOT automatically inherit Trust access.**

**No role, policy, migration, reader, erasure flow or observability mechanism is implemented.** No
registry ID is allocated. No finding is remediated. `MASTER_PRODUCT_DECISIONS.md`,
`MASTER_REMEDIATION_REGISTRY.md` and `QA_CLOSURE_STANDARD.md` are **not modified**, and the tracked
`TRUST = [INSERT OWNER DECISION HERE]` field in
`V5_SECURITY_FOUNDATION_WAVE1_AUTHORIZATION.md` **remains literally unfilled** — it is outside this
document's mutation boundary.

#### **Scope of what was answered — read this before relying on it**

§8.1 phrases `D-D1` as *"Are Security / Incidents / Audit / Guardian a separate 'Trust' **product
area**, or Admin domains?"* **What was put and answered here is the governance/reader boundary — a
ROLE.** **This document does not treat the product-area question as answered**, and **does not
answer it.** The residual is flagged in §8.1 in place. Anyone reading `D-D1` as settling whether a
Trust **surface** exists is reading more than was decided.

#### What this resolves

- **`A13` is no longer inconsistent with the role inventory.** Its reader table names the **Trust
  operator** in **all three** rows (Event · Incident · Control evidence), and §8.8 recorded that the
  role *"does not exist"*. The decision converts that from an unbacked reference into an
  **owner-mandated obligation**. The role **still does not exist in any migration** — the decision
  creates an obligation, not an object.
- **`A13` sub-ruling 3's MIXED model now has both halves.** *"Relationship-based authorization for
  subject/actor/active-coach access; role-class authorization for admin and Trust operator access."*
  The role-class half finally has a role to name.
- **`D12` question 12 and §8.16 question 3 are unblocked as to the role** — though neither is
  answered, and both still require the role to exist.

#### What this does NOT resolve — recorded, not inferred

- **`D11` is NOT answered.** §8.1 records that `D-D1` *"gates P6 ahead of D11, **which only scopes
  it**"*. Answering the gate does not answer the scoping. **`D11` still has no tracked substantive
  definition** — it appears in exactly one tracked text file and only as a dependency reference.
  **It is not invented here.**
- **`A14` remains BLOCKED**, because it is blocked on `D11`, which remains open.
- **P6's entry condition.** §8.1 records it must be read as `P2, P5, D11, D-D1` until `D-D1` is
  answered. `D-D1` is now answered **as to the role**; the **product-area residual above** bears on
  whether the `D-D1` term is fully discharged for P6. **Not asserted either way here.**

#### Consequences and contradictions — characterized from verified evidence, **not remediated**

1. **The role has no precedent to copy, and creating it has no precedent either.** The tracked role
   inventory is **five values** — `client`, `coach`, `vendor`, `admin`, `content_manager`
   (`115:79`). **`CREATE ROLE` has ZERO occurrences in `supabase/migrations/`.** The only six in the
   tree are in `supabase/tests/local/shim.sql:23–28`, recreating Supabase's **built-in platform
   roles** for the offline harness — **not an application-role precedent.**
2. **A new open question this decision creates: is the Trust operator the SAME role `A12` already
   mandated?** `A12` ruling 6 rules the erasure executor is **A NEW CONSTRAINED ROLE** and
   explicitly **NOT `service_role`**. D-D1 assigns *erasure authorization* to Trust. **Whether these
   are one role or two is NOT decided** — and `A13` sub-ruling 4 rules that **erasure authority and
   read authority do NOT coincide**, which pulls toward two. **UNRESOLVED — owner decision
   required.** Not answered here.
3. **The only existing governance-data reader precedent excludes a Trust operator and reserves
   erasure to `service_role`.** `decision_traces` (`128:86–99`) is readable by *subject OR creator
   OR active coach OR admin*, with `content_manager` **deliberately not granted** and the coach role
   alone **never sufficient**; its comment states provenance is *"erased **only by**
   `service_role`"*. That erasure clause **contradicts `A12` ruling 6**. `decision_traces` is not an
   audit population, so the contradiction is **adjacent, not direct** — **recorded, not resolved,
   and the migration is not modified.**
4. **`N07` diverges further.** `docs/proposed/N07_assessment_access.sql` — **tracked, unapplied,
   never adopted, and not modified** — carries **two `FOR SELECT` policies only** (*client reads
   own*, *coach reads own*) and **zero `is_admin()`**. It therefore has **no admin reader and no
   Trust operator**, against `A13`'s Event row of *active coach · admin · Trust operator*. The
   pre-existing N07 conflict **widens** under this decision. **Evidence only.**
5. **Nothing distinguishes a Trust operator from `service_role` today.** **17 of 19** Edge Functions
   hold the service-role key, and there are **zero** `REVOKE … FROM service_role` statements in the
   migration tree. `service_role` is `BYPASSRLS`, so a role-class check is not a boundary against
   it. `A11` sub-ruling 3 deferred the owner/`service_role` binding *"until `A12`"*; `A12` resolved
   it for the **audit** populations; §8.16·Q4 re-opened it for **observability**. **D-D1 adds a
   third face of the same gap: the Trust operator's relationship to `service_role` is undefined.**
   **Not decided here.**
6. **`A13` sub-ruling 5 compounds it.** Audit reads are themselves **audit-worthy**, so a Trust
   operator reading audit generates audit records that a Trust operator may read. §8.8 already
   recorded the recursion boundary; **D-D1 makes the recursing party a named role.**
7. **`PD-A24` and `PD-A17` are untouched.** Both remain **TRACKED**, `Proceed? = "Partly"`, owner
   **Julia** (`PD-A24`: *Julia + privacy*), waves 3B/8 and 1/8. **Neither is re-decided**, and
   `PD-A24` continues to block `D12` questions 6(d), 7, 9(b) and 10.

**No status changes. `QAX-SEC-08` remains OPEN / PARTIALLY VERIFIED; `QAX-SEC-09` remains OPEN.
`D11`, `A14`, `D17`, `CONF-02`, `CONF-08`, `D1(iv)` and `D3` remain as recorded.**

---

### 8.18 `TRUST ROLE IDENTITY` — **ANSWERED on Q1: TWO ROLES** — opened by §8.17

**Owner decision (Q1): TWO ROLES.** The **Trust operator reads and reviews**; a **separate new
constrained role executes erasure.** The Trust operator is therefore **NOT** the role `A12` ruling 6
mandated — **that remains a distinct second role.**

**Q2 and Q3 were NOT put and are NOT answered here.** They are preserved below, open.

**No role is created. No policy, migration, reader or erasure flow is implemented.** No registry ID
is allocated, no finding is remediated, no status changes.

§8.17 assigns the Trust operator *"audit/observability **review**, **erasure authorization**, and
governance operations."* Two answered rulings bear on that combination.

> **PHRASING CORRECTION.** This section previously said neither ruling *"was written with it in
> view."* **Too loose:** `A13` sub-ruling 7 names `D-D1` explicitly. Accurately: `A13` had `D-D1`'s
> **existence** in view and chose not to wait for it; it did not have **`D-D1`'s answer** in view,
> because that answer did not yet exist. The options were unaffected.

#### The collision, stated exactly

| source | text | bearing |
|---|---|---|
| **§8.17 `D-D1`** | Trust holds **review** *and* **erasure authorization** | one party, both powers |
| **§8.8 `A13` sub-ruling 4** | *"Do erasure authority and read authority coincide? **NO.**"* | they must not be the same |
| **§8.7 `A12` ruling 6** | erasure executor is *"**A NEW CONSTRAINED ROLE.** May that party be `service_role`? **NO**"* | a new role was already mandated |

**`A13` sub-ruling 7 is decisive for how this must be handled:** *"**Answer now, not deferred to
`D-D1`.**"* `A13` was deliberately settled **ahead of** `D-D1`. So **`D-D1` cannot retroactively
alter `A13`'s content** — it supplies the role `A13` named, and any conflict must be resolved as a
conflict, **not absorbed silently.**

#### Two readings of sub-ruling 4, both available on the text

- **Set reading:** the *set* of erasure-authorized parties ≠ the *set* of read-authorized parties.
  A single role holding both is permitted so long as the sets differ elsewhere.
- **Party reading:** **no single party** may hold both. Under this reading §8.17 must be read as
  granting Trust erasure ***authorization*** only, with **execution** elsewhere.

**§8.17's own wording is "erasure *authorization*", not "erasure execution"** — a textual hook that
bears on the party reading. **It is recorded as evidence, not adopted.**

#### `A13` sub-ruling 6 adds a third authorization, already separated

*"Frozen row vs identity mapping: **TWO SEPARATE AUTHORIZATIONS**."* Combined with `A12` ruling 2 —
anonymisation works by **severing an external mapping**, never mutating the frozen row — the party
that erases needs **identity-mapping** access, which `A13` already holds **separate** from the
frozen-row read access Trust has. So the design already contains **three** distinct authorizations,
and §8.17 named **one** role.

#### Q1 — ANSWERED: **TWO ROLES**

**Trust reads; a separate new constrained role erases.** The alternatives — ONE ROLE, and the
AUTHORIZE/EXECUTE SPLIT — are **not adopted** and are preserved above as the options that were open.

**`A13` sub-ruling 4 is satisfied under BOTH readings.** Two distinct parties means the erasure
authority and the read authority neither coincide as sets nor coincide in any single party.
**Therefore no supersession of sub-ruling 4 is required, and none is made.** `A13` and `A12` keep
their existing separation intact, exactly as recorded.

**Q2 is consequently MOOT FOR THIS DECISION BUT NOT ANSWERED.** Which reading governs still matters
for any future case where one party might hold both. **It remains OPEN and is not resolved here.**

#### Still to be answered — options preserved, **none chosen, none ranked**

2. **Which reading of `A13` sub-ruling 4 governs?** Set reading · party reading · **explicitly
   supersede sub-ruling 4** (which §8.8 records was answered *"now, not deferred to `D-D1`"*, so
   superseding it is a deliberate act, not a reconciliation). **OPEN** — not required by Q1's
   answer, and **not answered by it.** *(Not blocked.)*
3. **Who holds the identity-mapping authorization** that `A13` sub-ruling 6 keeps separate — Trust,
   the erasure executor, or a third party? **OPEN.** Q1 named **two** roles; sub-ruling 6 keeps
   **three** authorizations apart, so **one authorization still has no holder.** *(Not blocked.)*

#### Consequences of TWO ROLES — recorded, **not remediated**

1. **The design now requires TWO new roles where the repository has precedent for none.**
   `CREATE ROLE` has **zero** occurrences in `supabase/migrations/`; the only six in the tree are
   `supabase/tests/local/shim.sql:23–28`, recreating Supabase's **built-in platform roles** for the
   offline harness. **Two roles must be created against zero application-role precedent.**
2. **Neither role is distinguishable from `service_role` today.** **17 of 19** Edge Functions hold
   the service-role key, there are **zero** `REVOKE … FROM service_role` statements in the migration
   tree, and `service_role` is `BYPASSRLS`. `A12` ruling 6 excludes `service_role` from the erasure
   role specifically — and **no mechanism currently enforces that exclusion.**
3. **The one authorize/execute precedent in the repository is NOT the shape chosen — recorded so
   the gap is visible.** `admin_set_user_role()` (`115:363–395`) separates **authorization from
   execution within one call**: the caller proves role class
   (`auth.uid() IS NOT NULL AND NOT is_admin()` → `42501`), the `SECURITY DEFINER` function then
   announces a transaction-local exception via
   `set_config('circle12.privileged_role_write','on',true)` — the **only** `set_config` in the
   migration tree — and `trg_profile_privilege`, a `BEFORE INSERT OR UPDATE … FOR EACH ROW` trigger
   running `enforce_profile_privilege()`, enforces it at DML. Its own comment reads *"the
   authorization decision was made above."*
   **TWO ROLES separates the PARTIES instead, so this precedent does not supply the shape** — and it
   carries **three defects** that would have to be addressed by whatever does:
   - **Its authorization half is bypassed by the adversary.** Both the function and the trigger skip
     the check on the internal path (`IF v_uid IS NULL THEN RETURN NEW`) — i.e. for `service_role`,
     the party `A12` ruling 6 excludes and `A11` sub-ruling 1 names as the adversary.
   - **Its record is a `RAISE LOG`** — the only one in the tree — and **`A2` already ruled a
     server-log line does not satisfy an audit obligation** (§8.3).
   - **It has no `DELETE` arm.** Under `A12`'s ANONYMISE-AND-RETAIN that may not be needed, since
     erasure severs an external mapping rather than deleting; **not decided here.**
4. **`A13` sub-ruling 5's recursion is now confined to one role.** Audit reads are themselves
   audit-worthy; with only Trust reading, the recursing party is a single named role rather than a
   role that also erases. **The recursion boundary itself is unchanged.**
5. **The `decision_traces` contradiction sharpens.** `128:99` states provenance is *"erased **only
   by** `service_role`"*, which contradicts `A12` ruling 6 — and now contradicts a **named, distinct
   erasure role** rather than an unnamed one. `decision_traces` is not an audit population, so the
   contradiction remains **adjacent, not direct**. **Recorded, not resolved; the migration is not
   modified.**
6. **`N07` has neither role.** `docs/proposed/N07_assessment_access.sql` — **tracked, unapplied,
   never adopted, not modified** — carries two `FOR SELECT` policies and **zero `is_admin()`**, so it
   names no Trust operator and no erasure executor. **Evidence only.**

**No status changes. `D11`, `A14`, `D17`, `CONF-02`, `CONF-08`, `D1(iv)` and `D3` remain as
recorded, and none is invented.** `PD-A24` and `PD-A17` remain **TRACKED and OPEN**, owner *Julia*.

---

### 8.19 `A11 · SUB-RULING 2 TRUST ANCHOR` — **ANSWERED on Q1: DECLINE THE CLAIM**

**Owner decision (Q1): DECLINE THE APPEND-ONLY / TAMPER-RESISTANCE CLAIM.** No such claim is made.
**`A11` sub-ruling 2 is therefore DISCHARGED UNBUILT** — its requirement is conditional on the
claim, and with no claim there is no anchor obligation.

> ### The decision changes what is CLAIMED. It does not change what is TRUE.
>
> **`A11` sub-ruling 1's adversary — the COMPROMISED EDGE FUNCTION — remains undefended against.**
> Declining the claim removes the **obligation** to build an anchor. It removes **none** of the
> **exposure**. **17 of 19** Edge Functions hold the `service_role` key, there are **zero**
> `REVOKE … FROM service_role` statements, `service_role` is `BYPASSRLS`, and the DDL layer is open
> so any party able to `DROP`/`DISABLE` a trigger removes the DML binding.
>
> **§8.6's sentence must not be read as closed by defence.** It said *"until `A12` is decided **and**
> the sub-ruling 2 anchor exists, the design is **not defended against its own named adversary**."*
> `A12` is decided and the anchor obligation is discharged — **and the design is still not defended
> against its own named adversary.** That is the recorded state, stated plainly so it is not
> discovered later as a surprise.

**No anchor is designed or implemented.** No role created, no migration or policy written, no status
changes, no registry ID allocated, no finding remediated.

**`A11` sub-ruling 2, verbatim:** *"**DML-layer binding with an open DDL layer: NOT SUFFICIENT.** If
the system claims meaningful append-only or tamper-resistance, **an out-of-database trust anchor is
required**. The anchor is **not designed or implemented here**."* **The conditional is the operative
clause, and the condition is now declined.**

**`A11` sub-ruling 2, verbatim:** *"**DML-layer binding with an open DDL layer: NOT SUFFICIENT.** If
the system claims meaningful append-only or tamper-resistance, **an out-of-database trust anchor is
required**. The anchor is **not designed or implemented here**."*

#### The in-database ceiling — re-verified at HEAD, unchanged

| mechanism | count in `supabase/migrations/` |
|---|---|
| `FORCE ROW LEVEL SECURITY` | **0** |
| `CREATE RULE` | **0** |
| `BEFORE DELETE` triggers | **0** |
| `BEFORE` triggers of any kind | 19 |
| `REVOKE … FROM service_role` | **0** |

The **only** mechanism that binds every caller — owner and `service_role` included — is a
`BEFORE UPDATE` trigger that RAISEs, because `BYPASSRLS` bypasses **policies**, not **triggers**.
The document already records **11** such triggers and the **`120`** precedent; verified, that
precedent (`workout_set_logs_protect_history()`) is `LANGUAGE plpgsql` with **no `SECURITY DEFINER`
and no `auth.uid()` check at all** — it reads only `OLD` and `NEW`, so it binds unconditionally, and
it freezes identity columns while leaving values writable. **That is `A11`'s FREEZE-IDENTITY-COLUMNS
shape, already working in this repository.**

**And that is exactly why sub-ruling 2 exists:** the **DDL layer stays open**, so whoever can
`ALTER TABLE … DISABLE TRIGGER` or `DROP TRIGGER` removes the binding. **A DML guard cannot anchor
its own integrity.**

#### Anchor precedent: **NONE**, verified

Zero occurrences in `supabase/migrations/` of `hash`, `digest`, `hmac`, `checksum`, `merkle` or
`prev_hash`. The single `sha256` hit (`130:17`) is a **comment recording a file digest**, not a
mechanism. All six `signature` hits are **function signatures**. **No hash chain, no notarization,
no external attestation, no write-once store exists anywhere.**

**One capability is present and entirely unused for integrity:** `pgcrypto` **is** enabled
(`000:40`, `WITH SCHEMA extensions`), but its **only** consumed function tree-wide is
`gen_random_uuid` (**81** uses) — **zero** `digest()`, `hmac()`, `crypt()` or `gen_salt()`.

#### The option that is easy to miss

**Sub-ruling 2 is CONDITIONAL:** *"**If** the system **claims** meaningful append-only or
tamper-resistance…"* The anchor is required **by the claim**, not by the data. **`A11` sub-ruling 4
already constrains claims** — *"**ONLY WITH QUALIFICATION. No universal access-logging claim may be
made.**"* — so **declining the tamper-resistance claim is a coherent option that discharges
sub-ruling 2 without building anything.** It is presented as an option, **not recommended**, and it
carries its own cost: the audit ledger would then be explicitly **not** tamper-resistant against a
compromised Edge Function, which `A11` sub-ruling 1 names as the adversary.

#### Q1 — ANSWERED: **DECLINE THE CLAIM.** Q2–Q4 are MOOT, **not answered**

The alternatives — *make the claim and build the anchor*, and *claim it for a named subset* — are
**not adopted** and are preserved as the options that were open.

**Q2 (anchor form), Q3 (anchor holder) and Q4 (observability coverage) are conditional on Q1 being
answered the other way.** With no claim there is no anchor, so they **fall away — they are NOT
answered, and they return unchanged if the claim is ever made.** Their evidence stands: all four
candidate forms remain unprecedented here; `pgcrypto` still supplies primitives for chaining and
has still never been used for them.

**§8.18·Q3 and §8.16·Q1/Q4 are NOT touched by this decision and are NOT inferred.** §8.19·Q3 asked
who holds an *anchor*; §8.18·Q3 asks who holds the *identity mapping*. **Different questions. Both
of the latter remain OPEN exactly as recorded.**

#### Verified: this decision requires NO copy amendment

**Zero** occurrences of `append-only`, `append only` or `tamper` in `apps/mobile/lib/**` **or** in
`supabase/migrations/`. **No claim exists to withdraw.** Contrast `A12` ruling 7, which required
**AMEND COPY twice** for claims that did exist. **This decision is a decision not to make a claim,
not a correction of one.**

*(Verification caveat, recorded because it bears on any future source-level assertion of this kind:
a static grep of `ENABLE ROW LEVEL SECURITY` **systematically undercounts in this repository** —
`074:76–81` enables RLS on five `ai_*` tables through a **dynamic** `execute format(…)` loop over a
name array, which no static pattern can match. This is §4:105's *"necessary, never sufficient"*
holding on live material. The claim-absence counts above are literal-string searches and are not
subject to that effect.)*

#### Consequences — recorded, **not remediated**

1. **What remains in force, unweakened.** This decision touches **only the claim**. `A11`'s
   **FREEZE-IDENTITY-COLUMNS**, **APPEND-STATE-TRANSITIONS** and **NO RUNTIME WRITE PATH** remain
   binding **as design constraints**, and the `120` precedent still shows the DML shape that
   implements the first. `A12` ruling 2's frozen Event row remains frozen. **What is withdrawn is
   any assertion that these amount to tamper-resistance** — because the DDL layer is open, exactly
   as sub-ruling 2 says.
2. **`A11` sub-ruling 4 is extended in effect.** It already barred a universal access-logging claim
   *"ONLY WITH QUALIFICATION"*. The programme now also makes **no append-only and no
   tamper-resistance claim**. Both limits are claim-limits; neither is a statement about the data.
3. **FORWARD CONSTRAINT — this is the part that must not be lost.** Any future user-facing,
   contractual, regulatory, marketing or certification statement asserting append-only,
   tamper-evidence, immutability or an unalterable audit trail **re-triggers sub-ruling 2 and
   reinstates the anchor obligation in full.** The obligation is dormant, **not deleted**.
4. **Mandatory requirements are a separate matter and are NOT decided here.** If a regime that
   applies to this product independently requires a tamper-evident audit trail, **declining to claim
   one does not discharge that requirement.** `A12` rulings 3 and 5 are **PER-CATEGORY** and its
   windows are recorded as *"owner-selected architectural defaults **pending legal/compliance
   ratification**, not claims that any such legal requirement exists."* **The same caveat attaches
   here. UNRESOLVED — outside this decision.**
5. **The adversary gap is now a decided posture rather than an open task.** Previously §8.6 carried
   it as a defect awaiting two conditions. It is now an **accepted, recorded exposure**: the
   compromised Edge Function can alter audit rows at the DDL layer, and the programme neither
   prevents that nor claims otherwise. **Recorded as an accepted limitation, not as a finding, not
   as an ID, and not remediated.**
6. **Anchor precedent remains NONE**, and the provenance gap is preserved rather than closed: zero
   `hash`/`digest`/`hmac`/`checksum`/`merkle`/`prev_hash` in migrations; the single `sha256` is a
   comment recording a file digest; all six `signature` hits are function signatures; `pgcrypto` is
   enabled but its only consumed function tree-wide is `gen_random_uuid`.

**No status changes. `QAX-SEC-08` remains OPEN / PARTIALLY VERIFIED; `QAX-SEC-09` remains OPEN.
`D11`, `A14`, `D17`, `CONF-02`, `CONF-08`, `D1(iv)` and `D3` remain as recorded and none is
invented.** `PD-A24` and `PD-A17` remain **TRACKED and OPEN**, owner *Julia*.

---

### 8.20 `IDENTITY MAPPING` — PREPARED, **NOT ANSWERED** — §8.18·Q3 and §8.7's open note

**`A12`'s entire erasure model rests on this object.** Ruling 1 is **ANONYMISE-AND-RETAIN**; ruling
2 is *"**NO exception — use an external mapping.** The frozen row is never mutated."* **Anonymising
means severing the mapping.** §8.7 already records *"**Where the mapping lives, and who may sever
it, are open**"* and *"**Who may resolve identity through it is not** [decided]"*; §8.18·Q3 records
that `A13` sub-ruling 6 keeps **three** authorizations apart while §8.18 named **two** roles.
**Nothing blocks this. No option is chosen here, and §8.18·Q3 is NOT inferred.**

#### Precedent: **NONE**, verified in `supabase/migrations/`

| term | occurrences |
|---|---|
| `pseudonym` | **0** |
| `anonymi…` | **0** |
| `de-identif…` / `deidentif…` | **0** |
| `mapping table` | **0** |
| `tombstone` | **0** |

**No de-identification object, routine or vocabulary exists anywhere in the migration tree.**

#### "External" has no referent in this repository — verified

`CREATE SCHEMA` occurs **zero** times in migrations. Every application object lives in `public`
(**962** schema-qualified references). The only other schemas present are **Supabase platform**
schemas, none application-created: `auth` (370) · `storage` (75) · `cron` (11) · `vault` (9) ·
`extensions` (3).

**So "external mapping" cannot mean "another application schema" — none exists and none has ever
been created.** Whether `A12` ruling 2's *"external"* means external to the **frozen row**, to the
**table**, or to the **database** is **not settled by the ruling's text** and is **not settled
here.**

**`vault` is verified NOT a candidate.** It is a secrets store, used solely to hold `project_url`
and `service_role_key` so `pg_cron` jobs can call Edge Functions (`076`, `080`, `123`). It holds
key-value secrets, not data. **And a party that can read `vault.decrypted_secrets` obtains the
`service_role` key itself** — the `BYPASSRLS` credential. **Recorded as an observation about the
existing design; it is not a finding, carries no ID, and is not remediated.**

#### **NEW — the consequence §8.19 just created for this object**

§8.19 declined the tamper-resistance claim, so **no anchor protects the mapping either.** The
mapping's integrity is now **DML-deep only**, and the DDL layer is open.

> **If the mapping can be restored at the DDL layer, severance is not durable — and
> "anonymised" becomes REVERSIBLE by `A11` sub-ruling 1's named adversary.**
>
> `A12` ruling 1 retains the frozen row forever and relies **entirely** on severance for
> anonymisation; ruling 8 **stands behind** indefinite anonymised retention. **A reversible
> severance would make both claims weaker than they read.** This is **not** asserted as a defect —
> it is a **consequence that depends on where the mapping lives and how it is protected**, which is
> exactly what is undecided. **UNRESOLVED — owner decision required.**

#### What must be answered — options preserved, **none chosen, none ranked**

1. **Where does the mapping live?** A table in `public` · a **new schema** (unprecedented — zero
   `CREATE SCHEMA`) · **outside the database entirely** · somewhere else. **`vault` is verified
   unsuitable.** *(Not blocked.)*
2. **Who may RESOLVE identity through it?** §8.7 records this as not decided. Trust · the erasure
   executor · a third party · **no one, by construction** (a one-way severance with no resolution
   path). *(Not blocked.)*
3. **Who may SEVER it?** §8.7 records this as open. Under §8.18 the erasure executor is the natural
   candidate — **but that is an inference, not a decision, and it is not made here.** *(Not
   blocked.)*
4. **Is severance required to be durable against the DDL layer**, given §8.19 declined an anchor?
   Accept DML-deep severance · require durability and reopen a scoped anchor obligation for **this
   object only** · place the mapping outside the database so the DDL layer does not reach it.
   *(Not blocked. Note §8.19's forward constraint: a durability **claim** re-triggers sub-ruling 2.)*

**Nothing here is decided.** No object is created or designed, no schema, migration or policy is
written, no status changes, no ID is allocated. **§8.18·Q3, §8.16·Q1/Q4, `D11`, `A14` and `D17` are
not inferred.**

---

### 8.21 PROVENANCE OF THE INHERITED DECISION SET — evidence, **no decisions**

A full sweep of every decision ID in §8.1 and §5.2 that this document has **not** answered. **This
section allocates no ID, changes no status, and answers nothing.**

#### The finding: **14 of 17 inherited decisions have NO tracked statement of their question**

`D17` was known. **It is not the exception — it is the rule.** Three tiers, verified:

| tier | items | count |
|---|---|---|
| **QUESTION TRACKED** | `CONF-02` · `D1(iv)` · `D15` | **3** |
| **TOPIC GLOSS ONLY** — a tracked ID plus a few words of subject, no question | `D3` · `D5`–`D7` (the group label *"Admin"*) · `D-V1` · `D-V2` · `D-V3` · `D-V6` · `CONF-06` · `CONF-08` | **9** |
| **BARE ID OR ABSENT** | `D17` · `D-V4` · `D-V5` · `D10` | **4** |

**`D10` is in neither §8.1 nor §5.2.** Verified: `grep -c "D10"` over this document returns **0**.
Its only tracked appearances are two dependency references in the Wave-1 files.

**Every decision ledger that states these as questions is UNTRACKED** — verified via `git ls-files`
for `V5_DECISION_RESOLUTION_2026-09-27.md`, `QA_TO_V5_TRANSITION_RECONCILIATION_2026-09-27.md` and
`V5_IMPACT_ANALYSIS_2026-09-27.md`. In the tracked tree, §8.1:373–382 carries these IDs as a **bare
list with parenthetical topic glosses**, not as question statements.

**This traces to §2.1's absent source.** Re-verified: **no `.docx` exists anywhere** in the working
tree and `git ls-files` tracks none.

#### **The minimal unblocking set IS the unpreparable set**

By §5.2's entry conditions, `{D5, D6, D7, D-V1, D-V2, D-V3, CONF-08}` — **seven items** — unblocks
**every phase P3 through P9**. **All seven are tier-2 or worse: not one has a tracked statement of
its question.**

- The only item resolvable **without** the owner is **`D15`** — and `D15` **unblocks no phase and
  closes no finding**; its scope is the `SEC-G1` guard's own accuracy.
- The only two substantive owner-decidable items with tracked questions — **`CONF-02`** and
  **`D1(iv)`** — gate **P0** and **P1**, and **no phase in §5.2's entry-condition column enters on
  P0 or P1.** **UPDATE (§8.22): `D1(iv)` is now ANSWERED (defer to Wave 2), leaving `P1` blocked on
  `D3` and `D17` alone and `P0` on `CONF-02` alone. The structural point is unchanged — neither P0
  nor P1 is any later phase's entry condition.**

**So answering every question this programme can currently state would unblock nothing downstream.**
Recorded plainly because it determines what the next act must be.

> **The blocking act is NOT an owner decision on the merits.** It is **admitting these questions'
> text to the tracked record.** §8.12 already set the precedent for `D11`: *"Admitting it is an
> **owner act**, not a documentation act — **it is not done here.**"* **The same applies to all
> fourteen. That act is not performed, proposed or scoped here.**

#### New cross-file findings — recorded, not remediated

1. **`G-14`'s audit-log conjunct has NO requirement row.** `RELEASE_GATES.md:327` maps `G-14` to
   requirement **5.8** alone, and `:190` shows 5.8 covers **error tracking only**. Verified:
   *"audit log"* occurs **exactly once** in `RELEASE_GATES.md` — in the `:327` label itself. **One
   of `G-14`'s three conjuncts has no requirement row and therefore no mechanical check to attach
   to** — which is precisely the condition `EC-01`·Q3 asks about. **No gate definition is proposed
   or amended.**
2. **`PD-A24` is also `D-5`.** `QA_WORKSTREAM_L…:841` states the same subject — *"Which
   observability vendor, at what cost, with what data-residency posture?"* — under the ID **`D-5`**.
   Same decision, two tracked IDs, **reconciled nowhere.** Preserved.
3. **`CONF-06`'s tracked gloss contradicts its untracked definition.** §8.1:382 glosses it
   *"(tenancy)"*; the untracked ledgers define it as **vendor role hardening**. **Tracked governs;
   the conflict is preserved, not resolved.**
4. **`A12` is CATEGORY-keyed, not population-keyed — a precision correction to §8.16.** §8.16's
   table presents `A11`/`A12`/`A13` as uniformly keyed on `A1`'s populations. For `A12` that
   overstates: ruling 3 is **PER-CATEGORY**, ruling 5 keys *"by data **category**"*, and window 4's
   **Financial/tax is not one of `A1`'s three populations**. The four windows are **four items in a
   single table cell**, not four rows. **§8.16's substance survives — observability still has no
   window — but its framing is corrected here.** *(A consequence worth flagging and NOT acting on:
   if `A12` is category-keyed, then `A2` tier 2 already names "observability audit events" as a
   **category**, one `A12` ruling 4 simply never assigned a window. **No tracked text frames
   §8.16·Q2 that way, and no reframing is adopted.**)*

#### **CONTRADICTION — `A11` sub-ruling 3's discharge has two incompatible tracked readings**

| reading | text |
|---|---|
| **Global discharge** — §8.7 | *"**Ruling 6 satisfies A11 sub-ruling 3's deferral condition.**… It is now decided"* — **no population scoping** |
| **Audit-only discharge** — §8.16, §8.17 | *"`A12` settled that for the **audit** populations"* · *"`A12` resolved it for the **audit** populations"* |

**The scope qualifier appears in NEITHER owner ruling's own text.** `A11` sub-ruling 3 speaks of
*"the database owner / `service_role` boundary"*, unqualified; `A12` ruling 6 is unqualified too.
The audit-only reading is an **editorial characterization added later by this document**; the global
reading rests on **silence**, and at the time `A12` was ruled the observability population **did not
yet exist** as a decided object — §8.14 created it.

**Neither reading can be derived without adding words the owner did not write.** This is why
§8.16·Q4 exists, and **it must be put to the owner together with §8.16·Q4.** Preserved, **not
resolved.**

#### Verification-method caveat, recorded for reuse

Two independent instances now show source-level greps misreporting this repository: `ENABLE ROW
LEVEL SECURITY` is **undercounted** because `074:76–81` enables it through a **dynamic**
`execute format(…)` loop; and a naive `EC-01` grep **overcounts ~3×** through `SEC-01` substrings.
**§4:105's *"necessary, never sufficient"* holds on live material, in both directions.**

**Nothing in this section is a decision.** No ID allocated, no status changed, nothing remediated,
no question text reconstructed.

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
| **C-10** | **`CONF-01` is ANSWERED (§8.2) — the baseline is the 91 registered routes — but the underlying count discrepancy is NOT resolved and is preserved here.** V5 names **174** approved screens (unit undefined, source absent per C-1); the repository inventory records **91** routes and **148** surfaces; the design board records **156/169**. Of these, only **91** is enumerated (twice, in tracked evidence); **148 has no enumerated membership anywhere and its published sub-counts do not sum to it**; **156/169** reconcile among themselves but are design frames, not routes, with no frame→route mapping; **174** cannot be placed at all. The decision selects a baseline; it does **not** reconcile the other populations, and no members are invented for them |
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
| **Implementation readiness** | The gates permit *building* | **NO** — §6.1 records 5 pass · 2 partial · **8 fail**, and the critical path is blocked at `CONF-02` and `D4` (`CONF-01` is ANSWERED, §8.2) |
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

### 8.22 ADMISSION OF MISSING DECISION QUESTIONS — **ANSWERED** — plus `D15` and `D1(iv)`

**Four owner decisions, recorded exactly as supplied.**

#### 1 · ADMISSION — **the missing inherited V5 decision questions are ADMITTED, as a formal owner act**

§8.21 established that 14 of 17 inherited decisions have no tracked statement of their question, and
that admitting that text is *"an **owner act**, not a documentation act."* **That act is now
authorized.**

#### 2 · SCOPE OF THE ADMISSION — **what it does and does not permit**

The admission authorizes **reconstruction/admission of the decision objects from the available
provenance.** It **DOES NOT authorize invention of requirements, options, or outcomes.**

**Operationally, this means: QUOTE, NEVER COMPOSE.** A question enters the tracked record only as a
verbatim quotation carrying its source. A topic gloss is **not** upgraded into a question. An option
set is admitted only where a source enumerates one.

#### 3 · UNRECOVERABLE WORDING — **the handling rule**

Where a decision's original wording **cannot be recovered from authoritative evidence**:

- **preserve it as UNRECOVERABLE;**
- **mark the provenance explicitly;**
- **do NOT fabricate wording;**
- **do NOT infer an owner choice.**

An item marked UNRECOVERABLE remains an **owner-boundary item**. It is not closed, not resolved, and
not reworded into something answerable.

#### 4 · `D15` — **ANSWERED: PROCEED WITH LIVE-CATALOG DERIVATION**

Adopts the already-proposed `D15` direction. **It does NOT authorize implementation yet.**

- **The question, verbatim:** *"Should the guard population be derived from the live catalog rather
  than migrations?"* — recorded at `V5_WAVE1_INDEPENDENT_VERIFICATION_REPORT.md:353` **[TRACKED]**,
  which itself quotes an **untracked** source. **The question has tracked standing; its origin does
  not.**
- **The evidence it rests on:** **37 live vs 33 source** policies; cause — source counting missed 3
  duplicate policies.
- **Status unchanged until implementation:** §11 records `D15` as *"proposed, **not applied**"*, and
  that remains true. **`SEC-G1` (`rls_policy_shape_guard_test.dart`) is NOT modified.** Its header
  already anticipates the act — *"Measured 2026-09-23. **Lower it when policies are corrected under
  OD-14**; never raise it"* — but lowering it is implementation and is **not performed here.**
- **Reach, recorded so it is not overstated:** `D15` **unblocks no phase and closes no finding.** Its
  scope is the `SEC-G1` guard's own accuracy. It appears in **no** §5.2 entry condition.
- **Provenance limit preserved:** `D15` is a **V5-chain construct** — it appears in no pre-existing
  repository document, as its own source states.

#### 5 · `D1(iv)` — **ANSWERED: DEFER TO WAVE 2.** No `CHECK` constraint for the role value set

- **The question, verbatim:** *"`D1(iv)` — the permitted `role` value set — was not answered."* —
  `docs/adr/ADR-W1-001-team-membership-lifecycle.md:71` **[TRACKED]**, ADR-2.
- **The decision confirms the existing posture rather than changing it.** Migration `132:95–96`
  already records *"`role` is deliberately NOT constrained. The owner answered D1(i), (ii) and (iii);
  the permitted `role` value set was NOT answered."* **Nothing is implemented, and migration 132 is
  not modified.**

> **SCOPE PRECISION — this matters and is easy to misread.** `D1(iv)` concerns
> **`coach_team_members.role`**, the team-membership role. It does **NOT** concern
> **`user_profiles.role`**, which **already carries a `CHECK`** —
> `115:79`: `CHECK (role IN ('client', 'coach', 'vendor', 'admin', 'content_manager'))`. **That
> existing constraint is untouched and is not contradicted by this decision.** The instruction "do
> not introduce a CHECK constraint for the role value set" applies to `coach_team_members.role`
> alone.

- **Evidence recorded for the Wave 2 decision**, carried forward unchanged: the column defaults to
  `'assistant_coach'`, and `coach_business_screen.dart:256` hard-codes the same value when creating
  an invite. The column remains `text NOT NULL`. **No regression, no new constraint.**
- **`D1` must still not be described as answered without qualification.**

**No status changes. No registry ID allocated. No finding remediated. No implementation authorized
by any of the four.**

---

## 17 · CONSOLIDATED OWNER-DECISION PACKET

**Produced at the close of the full autonomous preparation cycle.** Every branch that could be
investigated without owner authority has been. **No decision below is answered, inferred or
ranked.** No implementation has begun.

### 17.A · Current V5 readiness

**Documentation readiness: HIGH. Implementation readiness: ZERO, and not primarily for want of
decisions.**

| gates (§6) | **5 PASS · 2 PARTIAL · 8 FAIL** of 15 — re-verified |
|---|---|
| phases (§5.2) | **P0 and P1 partially executed. P2–P10 all "not started."** |
| audit substrate | **0** `audit_log`/`audit_events`/`activity_log` tables |
| observability substrate | **0** observability/metric/telemetry tables |
| incident substrate | **0** incident tables |
| roles | **0** `CREATE ROLE` in migrations — and **two** are now required (§8.18) |
| open findings (§9) | **8 OPEN**, incl. `QAX-SEC-08` OPEN / PARTIALLY VERIFIED and `QAX-SEC-09` OPEN |

### 17.B · The blocker that is not a decision — **read before the decision tables**

§8.21 established it and it governs how this packet should be used:

> **14 of the 17 inherited decisions have no tracked statement of their question**, and the
> **minimal unblocking set is exactly the unpreparable set**: `{D5, D6, D7, D-V1, D-V2, D-V3,
> CONF-08}` unblocks **every phase P3–P9**, and not one of the seven can be stated from the tracked
> record. The two owner-decidable items that *do* have tracked questions — `CONF-02`, `D1(iv)` —
> gate **P0/P1**, on which **no later phase enters**.

**Consequence: answering every question in §17.C would unblock no downstream phase.** The act that
would is **admitting the missing question text to the tracked record** — which §8.12 already ruled
*"an **owner act**, not a documentation act."* **It is not performed or scoped here.**

### 17.C · Remaining owner decisions — **27, none answered**

All are documentation-stage. **None is resolvable from a recorded ruling or a governing constraint**
(the sole exception, `D15`, is in §17.C.6 and unblocks nothing).

**C.1 — `D4`/`D12` inheritance (§8.16). All four (c). Blocks P2.**
`Q1` A11 immutability for the observability population — *extend one of three meanings · define a
fourth · declare it mutable*. `Q2` A12 retention — *6-year Event window · shorter operational ·
per-component · none* (*vendor* option blocked on `PD-A24`). `Q3` A13 readers — *extend the mixed
model · a distinct operator class · admin-only*. `Q4` A11 sub-ruling 3's `service_role` deferral for
this population.
**Contradiction that must be answered WITH Q4:** §8.7 records A12 ruling 6 as discharging sub-ruling
3 **unqualified**; §8.16/§8.17 record it as discharged *"for the **audit** populations"*. **The
qualifier is in neither owner ruling's text.** **Order: Q4 before or with Q1** (§8.16 records Q4
*"bears on 1"*).
**Eliminated by evidence, not by choice:** A11's `NO RUNTIME WRITE PATH` is defined as *"authored
evidence, **not a runtime audit event**"* — observability records are runtime-produced, so that
branch is excluded on its own text. It narrows one option; it selects nothing.

**C.2 — Trust/erasure roles (§8.18). Both (c). Blocks P2/P6.**
`Q2` which reading of A13 sub-ruling 4 governs — *set · party · explicitly supersede it*. **Moot for
TWO ROLES, not answered**; it governs any future case where one party holds both. `Q3` who holds the
identity-mapping authorization — **overlaps §8.20·Q2/Q3**.

**C.3 — Identity mapping (§8.20). All four (c). Blocks P2; A12's erasure model rests on it.**
`Q1` where it lives — *`public` table · a new schema (zero `CREATE SCHEMA` precedent) · outside the
database*; **`vault` verified unsuitable** (secrets store; a reader of it obtains the `service_role`
key). `Q2` who may resolve identity — incl. *no one, by construction*. `Q3` who may sever it.
`Q4` must severance be durable against the DDL layer, given §8.19 declined an anchor.
**Live hazard:** with no anchor the mapping is **DML-deep only**; if it can be restored at the DDL
layer, **severance is not durable and "anonymised" becomes reversible** by A11 sub-ruling 1's named
adversary.

**C.4 — `EC-01` (§8.11) Q2–Q5. All four (c). Blocks no phase; blocks the finding ledger.**
`Q2` may a closure-class ruling bind aliases of a different class. `Q3` **can `G-14` be evaluated at
all** — **new evidence:** `RELEASE_GATES.md:327` maps `G-14` to requirement `5.8` alone and `5.8`
covers **error tracking only**; *"audit log"* appears **once** in that file, in the label. **One
conjunct has no requirement row and therefore no mechanical check.** `Q4` is §10's written one-line
test a precondition this closure did not meet — **note the standard prescribes a consequence for an
*inadequate* answer, not a *missing* one.** `Q5` must `QA_CLOSURE_STANDARD.md` carry an alias
definition (it contains the word **zero** times).
**§8.19's DECLINE has NO bearing on `G-14`** — the gate requires an audit log *in place*, not
tamper-evidence.

**C.5 — `D12` content (§8.13) Q1–Q3, Q5–Q12 (eleven). All (c). All block P2 → P5/P6/P7.**
Unblocked by evidence: **Q1** (SQ-10 components), **Q2** (identifier minting), **Q5** (survives
anonymisation). Blocked on **`PD-A24`**: Q6(d), Q7, Q9(b), Q10 — and Q11 via Q7. Blocked on
**`PD-A17`**: Q8. Blocked on **`D11`**: Q3's delivery, and Q12's remaining half.
**`PD-A24` and `PD-A17` are TRACKED, OPEN, owner *Julia*, and must NOT be re-decided here.**

**C.6 — With tracked questions, outside §8: `CONF-02` (c, gates P0) · `D1(iv)` (c, gates P1) ·
`D15` (b — resolvable WITHOUT the owner, and unblocks nothing).**

### 17.D · Unresolved contradictions — carried, none resolved

`A11` sub-ruling 3's two discharge readings (§17.C.1) · `decision_traces` *"erased only by
`service_role`"* vs `A12` ruling 6 · registry `:2102`'s discharging reading vs §8.15's
REFERENCE-ONLY · `EC-01`'s row asserting `VERIFIED_CLOSED` and *"invisible twice over"* four lines
apart · `PD-A24` also carried as **`D-5`** · `CONF-06` glossed *"(tenancy)"* against an untracked
*vendor role hardening* · §5.1's narrative critical path vs §5.2's entry-condition column · `N07`
having neither new role · the accepted adversary exposure (§8.19) with **no recorded scope** as to
the observability population.

### 17.E · Exact implementation boundary

**Nothing in V5 is implementable today.** Even with all 27 answered: P2 needs an audit schema whose
`A14` half is blocked on `D11`; P3–P9 need the seven unpreparable items; P10 needs `D-V6`. **The
only fully-specified, unblocked act in the entire set is `D15`** — lowering the `SEC-G1` guard's
population to the live catalog — which closes no finding and unblocks no phase.

### 17.F · What becomes implementable once decisions are supplied

**Directly: nothing beyond `D15`.** Answering §17.C.1–C.3 specifies the **shape** of the P2 audit
and observability substrate — populations, immutability, retention, readers, identifier, mapping —
but P2 cannot complete while `D4` remains open on `A14` → `D11`, and `D11` has no tracked question.

### 17.G · Confirmation

**Implementation has NOT started.** Across this entire cycle the only file modified is
`docs/V5_PROGRAMME_DEFINITION.md`. **Zero** changes to migrations, application code, app copy,
tests, CI, `MASTER_PRODUCT_DECISIONS.md`, `MASTER_REMEDIATION_REGISTRY.md`, `QA_CLOSURE_STANDARD.md`
or `docs/proposed/`. No registry ID allocated, no finding remediated, no database contacted, nothing
pushed.

### 17.H · Engineering guidance — **NOT owner decisions, NOT recorded as rulings**

Offered because §17.B makes the sequencing question real. **Advisory only; nothing here is adopted.**

1. **The highest-value owner act is probably not on the §17.C list.** It is deciding whether to
   admit the fourteen missing question texts to the tracked record. Until then P3–P9 cannot be
   prepared at all.
2. **`D15` can proceed independently** of everything else, and is the only such item.
3. **§8.16·Q4 and its contradiction should be answered together**, since Q4 cannot be answered
   coherently while the record disagrees about what `A12` already discharged.
4. **`PD-A24` and `PD-A17` belong to another owner** and gate six D12 questions between them;
   routing them is a scheduling matter, not a V5 decision.

---

## 16 · FINAL STATE AND NEXT DECISION BOUNDARY

### 16.1 What remains owner-controlled

| # | Decision | Blocks |
|---|---|---|
| **D-1** | SEC-W1 negative-control reconstruction mechanism | QAX-SEC-08's fourth rung — **and nothing else** |
| **D-2** | Finding A remediation authorization | Finding A only |
| **D-3** | Finding B remediation authorization | Finding B only |
| — | Registry ID allocation for Findings A and B | Their registration |
| — | `CONF-02` | The V5 document's canonical name/version, and therefore P0. **`CONF-01` is ANSWERED (§8.2); the protected baseline is the 91 registered routes** |
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
