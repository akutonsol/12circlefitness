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
   **CAUTION on the "no retention rule at all" option.** `A12` rulings 3 and 5 are **category-keyed**
   (§8.21 finding 4) and unqualified — *"otherwise erasure applies, using de-identification where
   possible"* — and `A2` tier 2 names *"observability audit events"* as a **category** whose `IN`
   ruling §8.14 confirms **STANDS IN FULL**. **Selecting "no retention rule at all" would therefore
   SUPERSEDE `A12` ruling 3 for that category.** This programme treats superseding an answered
   ruling as a **deliberate act**, never a by-product of a downstream answer. **Offered as a
   caution, NOT as a narrowing** — §8.21 expressly declined to adopt this reframing, and that
   declination stands.
3. **Does it inherit `A13`'s reader model?** Extend the mixed model · a distinct operator class ·
   admin-only. *(**Blocked on `D-D1`** for any option naming a Trust operator.)*
   **STALENESS CORRECTION:** `D-D1` was answered at §8.17, so this block is **discharged as to the
   role**. **Q3 remains UNANSWERED** — and **the role still does not exist in any migration.**

   > **CORRECTION TO THE CORRECTION (recorded, not quietly amended).** The sentence above
   > previously read *"all three options remain live … so the answer narrows the option set **not at
   > all**."* **That was wrong.** §8.17 did not merely name a role — it assigned that role a
   > **subject matter**: *"Trust is a distinct governance role responsible for **audit/observability
   > review**, erasure authorization and governance operations,"* and *"Admin and domain roles do
   > **NOT** automatically inherit Trust access."*
   >
   > **An `admin-only` reader model for the observability population would deny the Trust operator
   > read access to the very records §8.17 made it responsible for reviewing.** `admin-only` is
   > therefore **FORECLOSED by §8.17**, and the `D-D1` answer **does** narrow the option set — from
   > three live options to **two**.
   >
   > **This matters for how the question is put.** Offering `admin-only` on a menu presented as
   > fully live would let it be chosen without anyone being told it **silently reverses §8.17**.
   > The same foreclosure applies to **§8.13·Q12**.
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
| **QUESTION TRACKED** | ~~`CONF-02`~~ · `D1(iv)` · `D15` | ~~**3**~~ **2** — **corrected at §8.24**: `CONF-02` has **no tracked interrogative** |
| **TOPIC GLOSS ONLY** — a tracked ID plus a few words of subject, no question | `D3` · `D5`–`D7` (the group label *"Admin"*) · `D-V1` · `D-V2` · `D-V3` · `D-V6` · `CONF-06` · `CONF-08` | **9** |
| **BARE ID OR ABSENT** | `D17` · `D-V4` · `D-V5` · `D10` | **4** |

**`D10` is in neither §8.1 nor §5.2.** Verified: `grep -c "D10"` over this document returns **0**.
Its only tracked appearances are ~~two~~ **three** dependency references in the Wave-1 files
(**corrected at §8.24**).

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

### 8.23 ADMITTED DECISION QUESTIONS — the register

Question text admitted under §8.22, **verbatim only**. Every entry is a quotation carrying its
source. **No wording is composed, smoothed, merged or completed. No option is invented. No owner
choice is inferred.** Admission records *what was asked*; it answers nothing.

**All source wordings for these items are UNTRACKED.** Admission gives them tracked standing as
**quotations**; it does not give their origin tracked standing.

> #### ⚠ THREE ID COLLISIONS — verified, and each would fabricate a decision if mis-admitted
>
> 1. **`CONF-D4`/`CONF-D5`/`CONF-D6`/`CONF-D7` are DIFFERENT ITEMS** — design-authority conflicts
>    (Fitonist reference absent, brand not locked, Admin role matrix). They appear compressed as
>    *"CONF-D4/D5/D6"*. **That string must never be read as `D5`/`D6`.**
> 2. **`V5_WAVE1_INDEPENDENT_VERIFICATION_REPORT.md:571` and `:577` carry `## D5 ·` and `## D6 ·`
>    as that report's OWN section labels** — *"D5 · SEC-G1 baseline"* and *"D6 · Findings"*. They
>    are unrelated to the Admin decisions. **A naive tracked-tree grep for `D5` hits these first.**
> 3. **`D-5` ≠ `D5`.** `D-5` is another ID for `PD-A24` (§8.21).

#### `D5` — ADMITTED. **Two wordings, and they disagree on scope**

- *"Does Admin reach data via the NestJS API or direct Supabase?"* — `V5_DECISION_RESOLUTION:482`
- *"Does Admin/Trust go through the NestJS API or direct to Supabase?"* — `QA_TO_V5_TRANSITION:330`

**The disagreement is preserved, not resolved: the first asks about *Admin*, the second about
*Admin/Trust*. Whether Trust is inside `D5` is settled by neither.**

**Options, as enumerated at `:482`:** *"(a) direct Supabase + RLS (matches today) (b) via API"*.
`QA_TO_V5_TRANSITION:330` records **no options**.
**A third branch exists outside any lettered set** — `V5_DECISION_RESOLUTION:412–414` marks
*"New backend services?"* as `UNRESOLVED (D5)`. **Recorded; not merged into the option set.**

#### `D6` — ADMITTED. **Four wordings, and TWO OF THEM PRESUPPOSE THE ANSWER**

- *"Confirm Admin/Trust as a **web** surface (V5-indicated) — new app or added target?"* — `:483`
- *"V5 names a 'web/admin surface' separately from the 'mobile client' in three places. Confirm that
  Admin and Trust are a **web** surface rather than Flutter screens — and if so, whether it is a new
  application or an added target of the existing Flutter codebase."* — `:418–421`
- *"Is Admin/Trust in the Flutter app or a separate surface?"* — `QA_TO_V5_TRANSITION:331`
- *"Are Admin/Trust in the Flutter app or a separate surface? (D6)"* — `V5_IMPACT_ANALYSIS:575`

> **These are NOT one question in four wordings.** The first two **presuppose the web reading** and
> ask only *new app vs added target*. The last two ask the **prior** question and presuppose
> nothing. **Admitting one in place of the other would import a premise the owner has not ruled
> on.** Not harmonized.

**Options at `:483`:** *"(a) separate web app (b) Flutter web target (c) in-app"* — note **option
(c) sits inside a wording that has already excluded it.** Recorded, not reconciled.

**Status conflict, three-way, preserved:** one untracked ledger marks `D6` *"SUBSTANTIALLY RESOLVED
— confirm"* and *"Downgraded to confirmation-only"*; another records *"V5 resolves it: **NO** …
still unresolved: **YES**"* and *"D6 open"*; this tracked document carries it **unresolved**.
**Decisively, the corroborating document refuses to treat its own finding as a resolution:**
*"neither is treated as a resolution; both remain owner confirmations."*

#### `D7` — ADMITTED. **Two wordings, differing by one word**

- *"Are Users/Coaches/Clients distinct **Admin** modules or views over `user_profiles`?"* — `:484`
- *"Are Users/Coaches/Clients distinct modules or views over `user_profiles`?"* —
  `QA_TO_V5_TRANSITION:332`

**One word — *Admin* — scopes whether the modules are Admin-specific. Not harmonized.**

**NO OPTIONS RECORDED** in any source. The binary implicit in *"modules or views"* is **part of the
question text, not an option set, and is NOT upgraded into one.**

#### `CONF-08` — ADMITTED IN PART. **The record does not agree on whether it is a question at all**

- **Interrogative** — *"Where do the Admin/Trust design artefacts live?"* — `V5_IMPACT_ANALYSIS:581`
- **Imperative** — *"Supply or commission the 21 Admin/Trust design surfaces"* — `:476`; and
  *"Supply Admin/Trust designs or commission them"*; *"Supply or commission Admin/Trust designs"*.

> **Three of the four "Question"-column entries hold an IMPERATIVE, not a question.** *"Where do
> they live"* and *"supply or commission them"* are **not the same decision** — the first presumes
> the artefacts may exist somewhere, the second presumes they may not. **Neither is selected and
> they are not merged.** **Which of these is "the question" is itself an owner call**, and it is
> **not made here.**

**Options for the imperative form:** *"(a) supply existing packages (b) commission"*. The
interrogative form carries **none**.

**Surface count, three-way and unreconciled: 21 · 23 · 10.** No tracked source states any count.
And the *"21"* figure carries a warning from its own source: *"**Trust Home, Reviews and Policies
are named in the mission brief but not in V5** — recorded, not adopted as requirements."*

#### Resolvability — **all four are (c): REQUIRE OWNER AUTHORITY**

No ruling in §8.2–§8.22 addresses any of them. `D7` has **no recorded options at all**, so no
evidentiary route could select between branches without composing them. `CONF-08`'s substance is
the **supply of design artefacts that do not exist in the repository** — *"0 mentions in 7 design
docs"* — which no evidence can supply.

**`D6` is the one most at risk of being mis-classified (b)**, because V5 names a *"web/admin
surface"* three times. **It must not be.** Its own corroborating document declines to treat that as
a resolution, and §8.22·2 forbids inferring an outcome. **Converting a corroboration into a decision
is exactly what the admission does not authorize.**

#### Dependency contradiction — preserved

`D5` **depends on `D6`** in one untracked ledger; `D6` **depends on `D5`** in another. **The arrow
points both ways and is not resolved here.**

---

#### `D-V1` — ADMITTED. Three wordings

- *"**Where does the wearable platform live** — expand NestJS, new service, or separate repo + SDK?"*
  — `V5_IMPACT_ANALYSIS:461`
- *"Where does the wearable platform live?"* — `V5_DECISION_RESOLUTION:489`
- *"Where does the wearable platform live, and does it share this database? (D-V1/D-V2)"* —
  `V5_IMPACT_ANALYSIS:572` — **a compound that merges `D-V1` and `D-V2` into one sentence. Recorded,
  NOT split and NOT merged into either.**

**Options at `:489`:** *"(a) expand NestJS (b) new service (c) separate repo + SDK"*. Its companion
source states outright that *"**the evidence does not select one**, so no choice is made here."*

#### `D-V2` — ADMITTED. Two wordings plus the compound above

- *"Does the wearable platform share this Postgres instance or own its store?"* —
  `V5_IMPACT_ANALYSIS:462`
- *"Shared Postgres or its own store?"* — `V5_DECISION_RESOLUTION:490`

**Options at `:490`:** *"(a) shared (b) separate"*.

#### `D-V3` — **UNRECOVERABLE**

**No question text exists in any source, tracked or untracked.** Verified: `D-V3` has **no row** in
the one untracked section that states owner decisions in interrogative form
(`V5_DECISION_RESOLUTION` §15, *"OWNER DECISIONS — exact formulations"*), whose D-V rows are `D-V1`,
`D-V2`, `D-V4`, `D-V5` — **`D-V3` is absent.**

**Provenance marked:** four sources, all **noun-phrase topic glosses** — *"Canonical observation +
derived-metric contract, and the provenance/version model"* · *"Canonical observation + provenance
contract"* ×2 · the tracked *"(wearable boundary, store, **contract**)"*. **NOT upgraded into a
question. NO OPTIONS RECORDED.**

**Status conflict preserved:** one untracked ledger marks `D-V3` **PARTIALLY RESOLVED** (on the
ground that V5 supplies four provenance fields); **the same file elsewhere lists it under
*"Still required"***; the tracked record carries it **unresolved**. **Not reconciled.**

#### `D-V4` — ADMITTED. Four wordings, and their scopes differ materially

- *"Who may see a member's wearable data — active coach only, partners, admin?"* —
  `V5_IMPACT_ANALYSIS:464`
- *"Who may read a member's wearable health data? (D-V4)"* — `V5_IMPACT_ANALYSIS:573`
- *"Does "coach" mean active-only, and do Admin/Partner ever see member-level wearable PHI or only
  telemetry?"* — `V5_DECISION_RESOLUTION:491`
- *"does "coach" mean active-only, and do Admin/Partner ever see member-level PHI rather than
  telemetry?"* — `:315`

**NO OPTIONS RECORDED.** The *"Options"* column at `:491` holds a **statement, not an option set** —
*"V5 authorizes coach + member; Admin/Guardian = telemetry"* — and the list inside
`V5_IMPACT_ANALYSIS:464` is **part of the question sentence**. **Neither is converted into options.**

> **`D-V4` is the item most at risk of a fabricated (b).** An untracked ledger marks it *"PARTIALLY
> RESOLVED"* because V5's text authorizes coach + member access. **That is evidence about V5's
> text, not an owner ruling, and it answers neither clause of the narrowed question.** The same
> document records *"**7 of 8 roles have at least one unresolved column. Nothing was inferred from
> convenience, and no permission was granted.**"* **Treating this as resolved would fabricate a PHI
> access boundary.**

#### `D-V5` — ADMITTED. Two wordings

- *"What identity represents an agent in the audit trail?"* — `V5_DECISION_RESOLUTION:492`
- *"What agent identity appears in the audit trail? (D-V5)"* — `V5_IMPACT_ANALYSIS:578`

**NO OPTIONS RECORDED** — the options column is a literal em-dash.

**Near-miss checked and rejected:** §8.3's `A2` rules *"agent actions"* **IN** audit scope, and
§8.4's Event population names an *"actor"* field. **Neither says what identity an agent presents.**
§8.18 and §8.20 concern Trust and erasure-subject identity, not agent identity. **Reading any of
them as answering `D-V5` would fabricate a decision.**

#### `D-V6` — **UNRECOVERABLE**

**No question text in any source.** Like `D-V3`, `D-V6` has **no row** in `V5_DECISION_RESOLUTION`
§15. Every formulation is a noun phrase: *"SBOM toolchain and where it runs"* ×2 · *"SBOM toolchain
and location"* · the tracked *"SBOM tooling"*. **NO OPTIONS RECORDED.**

> **⚠ DO NOT SUBSTITUTE `CONF-03`'s QUESTION FOR `D-V6`'s.** `CONF-03` **is a different ID** and
> **does** have a recovered formulation — *"Authorize SBOM tooling, or accept the gap as a governed
> risk"*, with options *"(a) authorize `syft`/`cyclonedx`/`trivy` (b) documented risk acceptance"*.
> The sources **pair** the two (blocker B8) but **never equate** them; `D-V6`'s own row lists
> `CONF-03` as a **dependency**, not an identity. **Transferring that wording would be composition.**

**The blocking constraint has NO tracked standing.** *"installation currently forbidden"* appears in
**untracked ledgers only** — verified: **zero** tracked files contain the phrase. The nearest
tracked statement is §6's *"Gate 8 · PASS build-time, FAIL release-time"*. *(A tracked **FORBIDDEN**
does appear in the Wave-1 authorization — but it is a **scope prohibition on work areas**, not a
statement about installing tooling, and is **not** offered as this constraint.)*

**Status disagreement preserved:** an untracked ledger marks `D-V6` *"**OPEN, format fixed**"* with
*"CycloneDX named by V5"*; the tracked record carries it unresolved and **records no format
constraint**. Also disputed: that ledger scopes the block to *"**release only**, not build"*, while
§5.2 makes `D-V6` an **unqualified** P10 entry condition.

#### Resolvability — **all six D-V items are (c)**

No ruling in §8.2–§8.22 names any of them. `D-V3` and `D-V6` are additionally **UNRECOVERABLE**, so
there is nothing for an evidentiary route to resolve against.

#### Observation — a TRACKED owner decision appears unremediated

**Not a finding, no ID, NOT remediated, and no application code is touched.** `PD-B23` (owner
*Julia*, **tracked**) records that the integrations screen *"marks a service "connected" after
launching a `YOUR_CLIENT_ID` URL"*, rules *"**Hide unapproved providers for v1**"*, and states that
*"deleting the fake `_toggleConnect(id, true)` is **unconditional**"*. **Verified at HEAD: the
`YOUR_CLIENT_ID` placeholders and the `_toggleConnect(…, true)` call are both still present.**
`PD-G01` separately records Wearable Intelligence as *"APPROVED — FUTURE BUILD · implementation
**NOT AUTHORIZED**"*. **Recorded so it is not mistaken for V5 scope; acting on it is a separate,
separately-authorized act.**

#### What the wearable stack actually contains — verified at HEAD

**EXISTS:** `user_integrations` (`011:29–39`) — a **boolean `connected` flag** with an OAuth
placeholder, RLS enabled with a `FOR ALL` policy that has **no `WITH CHECK`**; one screen
(`integrations_screen.dart`, 8 providers); one reader — **a badge count**.

**ABSENT — verified zero:** HealthKit · Health Connect (the one hit is UI copy) · Fitbit · **Oura
(appears nowhere at all, not even among the 8 providers)** · any health/wearable SDK in
`pubspec.yaml` · any observation, device, metric, sync or health table · heart-rate/HRV data ·
any ingestion, normalization or provenance path · any SBOM or supply-chain step in CI.

**So `D-V1`–`D-V6` scope a stack that does not exist in any form.**

---

#### `D3` — ADMITTED. **One wording — and FOUR distinct senses of "D3" exist**

- *"Do relationship-consuming policies require `status='active'` uniformly?"* —
  `QA_TO_V5_TRANSITION:328`

**Options at `:328`:** *"(a) inline predicate (b) `is_active_coach_of(text)` overload — **(b)
recommended**"*. **The "recommended" note is NOT an owner choice** — its own source says it *"is
carried from prior QA, not new"*, and **no owner choice is recorded anywhere.**

> **⚠ FOUR SENSES OF "D3", all tracked, all distinct:** **(i)** this decision, the uniform status
> predicate · **(ii)** **`D-3`** of §8 — *"Authorize remediation of Finding B?"*, which §8.1 already
> warns is *"a different decision"* · **(iii)** **two separate** mutation-test row IDs in
> `QA_EVIDENCE.md`, themselves distinct from each other · **(iv)** `## D3 · Agent 3 independent
> verification` — an addendum sub-heading in the Wave-1 verification report.

**Owner class is a three-way split** across untracked registers (owner · owner-collective ·
architecture); the tracked record leaves it unclassified. **Not resolved.**

#### `D17` — ADMITTED. **Recoverable after all**

§8.21 recorded `D17` in the **BARE ID OR ABSENT** tier — correct **for the tracked tree**, and a
question **does** exist untracked:

- *"Fix `SEC_PHI_1` before applying it?"* — `QA_TO_V5_TRANSITION:342`

**NO OPTIONS RECORDED.** What the sources carry is the *content of a fix* —
*"`security_invoker = off` + `security_barrier` + predicate in the view"* — **not a yes/no branch.**
**A documented fix is not an option set and is NOT upgraded into one.**

**Same three-way owner-class split as `D3`.** Preserved.

#### `D10` — ADMITTED

- *"What AI processing is disclosed to members?"* — `QA_TO_V5_TRANSITION:335` **and**
  `V5_DECISION_RESOLUTION:486`, identically.

**NO OPTIONS RECORDED.** The *"Options"* cell reads *"matrix complete and ready to rule on"* — **a
readiness statement, not an option set.** Not upgraded.

**All four untracked sources agree `D10` is owner-class — no split.** It gates the P1 finding
**`SEC-AI-1`**, not a phase, and has **no tracked status at all.**

#### `D11` — ADMITTED. Confirms §8.12

- *"What is Trust's actual scope?"* — `QA_TO_V5_TRANSITION:336`

**NO OPTIONS RECORDED.** §8.12's four *"What must be answered"* questions are **this document's
questions ABOUT `D11`**, not `D11`'s question text, and are kept strictly separate.

#### `CONF-02` — ADMITTED

- *"Is this document "V5" or "V1 Master Version 2+amendments"? (CONF-02)"* — `V5_IMPACT_ANALYSIS:571`

**Options:** *"(a) "V1 Master V2+V3+V4+V5" (b) rename to V5"*. No owner-class split.

**Blocking conflict preserved:** two untracked registers **downgrade it to *"non-blocking"* /
*"confirmation-only"***, while the tracked record treats it as a live P0 gate — *"the critical path
is blocked at `CONF-02` and `D4`"*. **Tracked governs; the conflict stands.**

**And its gate is self-referential:** the requirement that makes `CONF-02` matter (version-qualified
traceability) **lives in the document whose identity is in question.** Recorded, not resolved.

#### `CONF-06` — ADMITTED. Three wordings

- *"Harden the partner role before partner APIs?"* — `V5_DECISION_RESOLUTION:76` and `:475`
- *"Harden `vendor` before partner APIs?"* — `V5_IMPLEMENTATION_READINESS_GATE:375`
- *"Does the Wellness Partner role get hardened before partner APIs? (D2/CONF-06)"* —
  `V5_IMPACT_ANALYSIS:576`

**Options at `:475`:** *"(a) harden first (b) build behind a flag (c) defer"*. No owner-class split.

**`CONF-06` ≠ `D2`.** `D2` asks separately *"Do `coach` and `vendor` remain self-assertable at
signup?"*, and `CONF-06` lists `D2` as a **dependency**. **Two decisions; not merged.**

**The tracked gloss *"(tenancy)" remains contradicted** by every untracked definition, which is
about **`vendor` role hardening**. Preserved (§8.21).

#### Resolvability — **all six are (c)**

No ruling in §8.2–§8.22 addresses any of them.

---

### 8.24 TWO CORRECTIONS TO §8.21's TIER TABLE

Both found during recovery, both verified, both corrections to **this document's own** claims.

**1 · `CONF-02` is NOT in the "QUESTION TRACKED" tier.** §8.21 placed it there. Verified: `CONF-02`
appears in **exactly one** tracked file — this one — and **not one of its occurrences is
interrogative.** They are dependency-graph labels, phase-content imperatives, a bare list entry and
declarative glosses. **The only interrogative form is untracked** (`V5_IMPACT_ANALYSIS:571`, now
admitted at §8.23).

> **Corrected tier count: QUESTION TRACKED = 2 (`D1(iv)`, `D15`), not 3.** `CONF-02` belongs with
> the **topic-gloss** tier for question text. **This does not change `CONF-02`'s status** — it
> remains OPEN and gates P0 — and it does not change §8.21's structural conclusion, which it
> strengthens: **15 of 17 inherited decisions had no tracked statement of their question, not 14.**

**2 · `D10` has THREE tracked dependency references, not two.** §8.21 said two. Verified: they are
in `V5_SECURITY_FOUNDATION_WAVE1_AUTHORIZATION.md`, `V5_SECURITY_FOUNDATION_WAVE1_FINAL_REPORT.md`
**and** `V5_WAVE1_INDEPENDENT_VERIFICATION_REPORT.md` — three files. *(A fourth `git grep` hit,
`splash_screen.dart`, is the hex colour `Color(0xD104020A)` — a coincidental byte sequence, not an
ID. Same class of trap as the `D11` binary-asset match recorded at §8.12.)*

**Neither correction changes any decision, status, ID or finding.**

---

### 8.25 ADVERSARIAL RESOLVABILITY PASS — result and four packet corrections

A deliberately opposed pass was run against all 42 open decisions, mandated to **argue that they
ARE resolvable** and to counteract the earlier passes' explicit "when in doubt choose (c)"
instruction. **Result: 0 ENTAILED, 6 ARGUABLE, 42 remain (c).** Recorded because a null result from
an adversarial pass is evidence, not an absence of it.

#### Why the opposite case fails — **structural, not an artifact of instruction**

**Every recorded ruling in §8.2–§8.22 carries an explicit anti-entailment clause inside its own
owner-recorded text**, not as editorial hedging:

| ruling | clause |
|---|---|
| §8.3 `A2` | *"**A2 only.** `A1`, `A3`, `A11`, `A12` and `A13` remain OPEN and **nothing below decides or implies any of them.**"* |
| §8.10 `D12` scope | *"Owner decisions on **scope only**… **nothing below decides its content**"* |
| §8.14 | *"This decision settles **scope-vs-topology and nothing else.**"* |
| §8.19 | *"**§8.18·Q3 and §8.16·Q1/Q4 are NOT touched by this decision and are NOT inferred.**"* |

**A chain from a recorded ruling to an open decision almost always has to cross one of these
clauses — and crossing it is not interpretation, it is contradiction.** Secondarily, **six** of the
admitted inherited decisions have **no option set at all**, so resolution-by-elimination is
unavailable by construction, and §8.22·2 bars manufacturing one.

#### Four corrections this pass produced

1. **§8.16·Q3 / §8.13·Q12 — an affirmative error in this document, corrected in place at §8.16.**
   `admin-only` is **FORECLOSED by §8.17**; the prior text claimed the `D-D1` answer narrowed
   nothing.
2. **§8.16·Q2 — caution added**: *"no retention rule at all"* would supersede `A12` ruling 3 for the
   observability-audit-events category.
3. **`D17` — a consistency note.** §5.2's P1 row lists its content as *"…**corrected `SEC_PHI_1`**…"*
   **in the same row that records `D17` OPEN**. If the owner answers *"apply as written"*, **the
   tracked phase model must change.** Surfaced, not resolved.
4. **`EC-01`·Q2 — context note.** Answering *"yes, the class binds its aliases"* sits awkwardly
   beside §8.15's *"substantive status must be determined separately for each."* **Not a
   contradiction** — class and status are different — but the owner should know §8.15 exists before
   answering.

#### The grouping this pass recommends — **engineering guidance, NOT a ruling**

**§8.18·Q3, §8.20·Q2 and §8.20·Q3 should be put as ONE question.** `A12` ruling 6 mandates *"A NEW
CONSTRAINED ROLE"* (**singular**); §8.18 ruled **TWO ROLES**; `A13` sub-ruling 6 keeps **three**
authorizations apart, so **one has no holder**. Answering these separately is **how a third role
gets created by accident**, against a record that has twice committed to two — with **zero**
application-role precedent in the repository.

**Nothing in this section resolves any decision.** No status changes, no ID allocated, nothing
remediated.

---

## 17 · CONSOLIDATED OWNER-DECISION PACKET

**Produced at the close of the full autonomous preparation cycle.** Every branch that could be
investigated without owner authority has been. **No decision below is answered, inferred or
ranked.** No implementation has begun.

> **REVISION 2 — after the §8.22 admission.** The owner admitted the missing decision questions,
> and recovery has run against every one. **The counts below are revised; the structural conclusion
> is not.** What changed: **14 questions were recovered and admitted** (§8.23), **2 are
> UNRECOVERABLE** (`D-V3`, `D-V6`), **2 were answered** (`D15`, `D1(iv)`, §8.22), and **two of this
> document's own tier claims were corrected** (§8.24). **Not one recovered question became
> resolvable from evidence. All remain (c).**

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

> **REVISION 2 — the admission has been performed, and this changes the picture.** Fourteen of the
> seven-item minimal unblocking set's questions are now **recovered and admitted** (§8.23):
> `D5`, `D6`, `D7`, `CONF-08`, `D-V1`, `D-V2` all have wordings on the tracked record.
> **The set is no longer unpreparable — it is prepared and awaiting owner answers.**
>
> **But two of the seven remain blocked behind a harder wall.** **`D-V3` is UNRECOVERABLE**, and it
> is a P3 entry condition alongside `D-V1`/`D-V2`. **So P3 cannot be entered even if every
> answerable question in the set is answered**, because one of its three conditions has no question
> to answer. **The same is true of P10 and `D-V6`.**
>
> **Revised structural conclusion:** the blocker is no longer *"the questions do not exist."* It is
> now **two specific decisions whose questions could not be recovered**, plus **42 open owner
> decisions** (corrected from 41 — see §17.C). That is a materially better position than §17.B originally recorded — and it is
> still not implementable.

### 17.C · Remaining owner decisions — **42, none answered** *(revised from 27, then 41)*

> **COUNT CORRECTION.** The figure 41 **omitted `D4 · A14` as a decision in its own right.** `A14`
> appears in this section only as a dependency note on `D11`'s row. It is a **standalone open owner
> decision** — *"Trust visibility rules"* — and it is **the last item gating `D4`'s completion**,
> so it sits directly on the critical path to P2. **Corrected total: 42.**

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

**C.6 — Outside §8.** ~~`CONF-02` (c, gates P0) · `D1(iv)` (c, gates P1) · `D15` (b)~~ —
**SUPERSEDED**: `D15` and `D1(iv)` are **ANSWERED** at §8.22; `CONF-02` is **admitted at §8.23** and
still **(c)**, gating P0 alone.

**C.7 — THE FOURTEEN ADMITTED INHERITED DECISIONS (§8.23). All (c). Questions now recorded
verbatim; options only where a source enumerated one.**

| decision | question recovered? | options | gates |
|---|---|---|---|
| **`D3`** | yes | (a)/(b), *"(b) recommended"* — **not an owner choice** | **P1** |
| **`D17`** | yes | **none** — only the content of a fix | **P1** |
| **`D5`** | yes ×2, scopes differ | (a)/(b) + an unlettered third branch | **P5** |
| **`D6`** | yes ×4 — **two presuppose the answer** | (a)/(b)/(c) | **P8** |
| **`D7`** | yes ×2, differ by one word | **none** | **P5** |
| **`D10`** | yes | **none** | `SEC-AI-1`, **not a phase** |
| **`D11`** | yes | **none** | **P6**; blocks `A14` → `D4` |
| **`CONF-02`** | yes (**untracked only** — §8.24) | (a)/(b) | **P0** |
| **`CONF-06`** | yes ×3 | (a)/(b)/(c) | **P9** |
| **`CONF-08`** | **part** — imperative vs interrogative unsettled | (a)/(b) for one form | **P5, P6, P8** |
| **`D-V1`** | yes ×3 | (a)/(b)/(c) | **P3** |
| **`D-V2`** | yes ×2 | (a)/(b) | **P3** |
| **`D-V4`** | yes ×4, scopes differ | **none** | wearable authz |
| **`D-V5`** | yes ×2 | **none** | **P7** |

**C.8 — THE TWO UNRECOVERABLE ITEMS — owner-boundary, not answerable as posed.**
**`D-V3`** (canonical observation + provenance contract) and **`D-V6`** (SBOM toolchain). **No
question text exists in any source**; both are absent from the one section that states decisions
interrogatively. Per §8.22·3 they are **preserved as UNRECOVERABLE**, not reworded. **`D-V3` gates
P3; `D-V6` gates P10.** **Deciding them requires the owner to supply a question, not merely an
answer.**

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
but P2 cannot complete while `D4` remains open on `A14` → `D11`.

> **REVISION 2.** `D11`'s question **is now admitted** — *"What is Trust's actual scope?"* — so the
> `D4` → `A14` → `D11` chain is **answerable end to end** for the first time. Answering
> `D11`, then `A14`, then §17.C.1–C.3 would **complete `D4` and `D12`, and open P2.**
> **P2 is therefore the first phase that becomes reachable**, and it is reachable **without**
> `D-V3` or `D-V6`.
>
> **P1 likewise:** its only remaining blockers are `D3` and `D17`, **both now admitted with
> recovered questions.** Answering those two opens P1. **P0 needs `CONF-02` alone.**
>
> **So the answerable path is `CONF-02` → (`D3`, `D17`) → (`D11`, `A14`) → the P2 decision set.**
> Everything beyond P2 still needs the Admin, wearable and design sets — and P3 and P10 still need
> the two UNRECOVERABLE items.

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

## 18 · FINAL OWNER-DECISION FRONTIER

**The definitive packet.** §17 is retained as the preparation record; **this section governs.**
**42 open decisions, 0 resolvable from evidence** (§8.25), grouped **by dependency, not by
discovery order**, and ordered so **one answer set clears the maximum coherent chain.**

### 18.1 · The frontier — **22 decisions, put as 20 questions, opens P0 + P1 + P2**

Answering only these three tiers takes the programme from *"no phase enterable"* to **P2 open**.

#### TIER 0 — depends on nothing · opens P0 and P1 · **3 decisions**

| # | decision | question (verbatim, admitted §8.23) | options | unlocks |
|---|---|---|---|---|
| 1 | **`CONF-02`** | *"Is this document "V5" or "V1 Master Version 2+amendments"?"* | (a) *"V1 Master V2+V3+V4+V5"* (b) rename to V5 | **P0** |
| 2 | **`D3`** | *"Do relationship-consuming policies require `status='active'` uniformly?"* | (a) inline predicate (b) `is_active_coach_of(text)` overload | **P1** (with 3) |
| 3 | **`D17`** | *"Fix `SEC_PHI_1` before applying it?"* | **none recorded** — only the content of a fix | **P1** (with 2) |

**`CONF-02` caveat:** its gate is **self-referential** — the requirement making it matter lives in
the document whose identity is in question — and **the source `.docx` does not exist in the repo.**
**`D17` caveat (§8.25·3):** §5.2's P1 row already lists *"corrected `SEC_PHI_1`"* **in the same row
that gates on `D17`**; answering *"apply as written"* **requires changing the tracked phase model.**

#### TIER 1 — depends on Tier 0 only in sequence · completes `D4` · **2 decisions**

| # | decision | question | options | unlocks |
|---|---|---|---|---|
| 4 | **`D11`** | *"What is Trust's actual scope?"* | **none recorded** | `A14`; gates **P6** |
| 5 | **`D4 · A14`** | Trust visibility rules *(depends on `A13` — ANSWERED — and `D11`)* | — | **completes `D4`** |

> **This is the critical path.** `D4` is open on `A14` alone; `A14` is blocked on `D11`; `D11`'s
> question was admitted at §8.23. **The chain is answerable end to end for the first time.**
> **`D11` is three-areas-vs-four on the record and neither reading is adopted** (§8.12) — and all
> four untracked sources agree the **build scope** is open regardless.

#### TIER 2 — the P2 audit + observability set · **17 decisions, 15 questions**

**§8.16 · inheritance (4) — answer `Q4` before or with `Q1`:**
`Q4` `A11` sub-ruling 3's `service_role` deferral for this population · `Q1` `A11` immutability
(**`NO RUNTIME WRITE PATH` already excluded on its own text**) · `Q2` `A12` retention (**see the
supersession caution at §8.16**) · `Q3` `A13` readers (**`admin-only` FORECLOSED by §8.17** —
§8.25·1).
**Put `Q4` together with the `A11` sub-ruling 3 contradiction** (§8.21): §8.7 records the deferral
discharged **unqualified**, §8.16/§8.17 record it discharged *"for the **audit** populations"*, and
**the qualifier is in neither owner ruling's text.**

**The role question (3 decisions, ONE question) — §8.18·Q3 + §8.20·Q2 + §8.20·Q3.**
**Who holds the identity-mapping authorization, who may resolve identity through it, and who may
sever it?** `A12` ruling 6 mandates *"A NEW CONSTRAINED ROLE"* (**singular**); §8.18 ruled **TWO
ROLES**; `A13` sub-ruling 6 keeps **three** authorizations apart — **so one has no holder.**
**Answering these separately is how a third role gets created by accident** (§8.25).

**§8.20 · mapping (2):** `Q1` where it lives (`public` · a new schema — **zero `CREATE SCHEMA`
precedent** · outside the database; **`vault` verified unsuitable**) · `Q4` durability against the
DDL layer (**with no anchor, severance is DML-deep only — "anonymised" may be reversible**).

**§8.18·Q2 (1):** which reading of `A13` sub-ruling 4 governs. **Moot for TWO ROLES, not answered.**

**§8.13 · D12 content, unblocked (7):** `Q1` `SQ-10` components · `Q2` where the correlation
identifier is minted · `Q3` does it appear on the audit Event row · `Q5` does it survive `A12`
anonymisation · `Q6` retention window *(vendor option only, blocked)* · `Q9` structured logging
*(one option blocked)* · `Q12` observability readers *(**`admin-only` foreclosed**, as `Q3`)*.

### 18.2 · Beyond the frontier — **20 decisions, deliberately excluded from the frontier**

| group | decisions | why it is not in the frontier |
|---|---|---|
| **Another owner's gate** | `D12` `Q7`, `Q8`, `Q10`, `Q11` | blocked on **`PD-A24`** / **`PD-A17`** — **TRACKED, OPEN, owner *Julia*. Not yours to answer; a scheduling matter.** |
| **Finding ledger** | `EC-01` `Q2`–`Q5` | **blocks no phase.** `Q3`'s facts are settled — `G-14`'s audit-log conjunct has **no requirement row**, so it can never be *met*; what is open is whether "evaluable" means *assessable* or *meetable*. |
| **P5 / P6 / P8** | `D5`, `D6`, `D7`, `CONF-08` | downstream of P2. **`D6`'s four wordings are not one question — two presuppose the web answer.** **`CONF-08`'s form is itself an owner call** (imperative vs interrogative). |
| **P3 / P7** | `D-V1`, `D-V2`, `D-V4`, `D-V5` | the wearable stack **does not exist in any form**. **`D-V4` is the item most at risk of a fabricated resolution.** |
| **P9 / SEC-AI-1** | `CONF-06`, `D10` | downstream; `D10` gates a finding, not a phase. |

### 18.3 · UNRECOVERABLE — **2 decisions, a different kind of input**

**`D-V3`** (canonical observation + provenance contract, gates **P3**) and **`D-V6`** (SBOM
toolchain, gates **P10**). **No question text exists in any source.** Both are absent from the one
section that states decisions interrogatively; every formulation is a noun-phrase gloss.

> **These are NOT answerable decisions. The owner must SUPPLY A QUESTION, not choose an answer.**
> **`CONF-03`'s wording must not be borrowed for `D-V6`** — paired as a blocker, never equated, and
> `D-V6` lists `CONF-03` as a **dependency**. **`D-V3` blocks P3 alongside `D-V1`/`D-V2`, so P3
> cannot be entered even if every answerable question in the wearable set is answered.**

### 18.4 · What the frontier buys

| answer | result |
|---|---|
| Tier 0 (3) | **P0 and P1 open** |
| Tier 0 + 1 (5) | **`D4` completes** |
| Tier 0 + 1 + 2 (22) | **`D4` and `D12` complete → P2 OPENS** |
| everything (42) | **P3 and P10 still blocked** on the two unrecoverable items |

### 18.5 · Contradictions carried into the packet — **none resolved**

`A11` sub-ruling 3's two discharge readings · `decision_traces` *"erased only by `service_role`"* vs
`A12` ruling 6 · registry `:2102`'s discharging reading vs §8.15 · `EC-01` `VERIFIED_CLOSED` beside
*"invisible twice over"* · `PD-A24` also carried as **`D-5`** · `CONF-06` glossed *"(tenancy)"*
against every untracked definition · §5.1's critical path vs §5.2's entry-condition column · `N07`
having neither new role · `D5`↔`D6` circular dependency · **four distinct senses of "D3"** · the
accepted adversary exposure with **no recorded scope** for the observability population · `CONF-08`
at **21 vs 23 vs 10** surfaces · `PD-B23`'s *"unconditional"* deletion **still unremediated at
HEAD**.

---

## 19 · ARCHITECTURE-LED OWNER DECISIONS

**Authority.** The owner delegated architecture authority to resolve the §18 frontier, supplying a
13-point decision hierarchy. **Every decision below is an OWNER DECISION made under that delegation**
— not an inference, not a recommendation. **Alternatives are preserved. No prior ruling is
rewritten. Where a prior ruling constrains, it governs.**

**Hierarchy, as supplied:** 1 security/least privilege · 2 PHI/PII and privacy · 3 explicit
separation of authorization, execution and audit · 4 deterministic controls for high-impact
operations · 5 repository precedent **only where genuinely applicable** · 6 minimal irreversible
commitment · 7 clear ownership · 8 reversibility/extensibility · 9 simplest sufficient design ·
10 avoid speculative infrastructure · 11 **never silently broaden** a permission, data scope,
retention period or trust boundary · 12 **never treat documentation evidence as implementation
evidence** · 13 **never claim a control stronger than the implementation can prove**.

### 19.1 · TIER 0 — opens P0 and P1

**`CONF-02` — ANSWERED: (b) THE CANONICAL DESIGNATION IS "V5".**
*Rationale (7, 9):* every tracked artefact, the handoff and this programme already use V5; a
composite name serves no traceability purpose the single name does not. *Qualification required by
12 and 13:* **the source specification is absent from the repository**, so "V5" names **the
programme**, and SA-01/SA-12 traceability resolves to §4's transcription, **not to an inspectable
artifact**. **The self-referential gate is not cured by this decision** — it is recorded as
accepted. *(a) preserved.*

**`D3` — ANSWERED: YES, UNIFORMLY, via (b) the `is_active_coach_of(text)` overload.**
*Rationale (1, 4):* a non-uniform status predicate grants access on **inactive** relationships —
a standing privilege leak. Uniformity is the security answer. *Mechanism (4, 9, 5):* a single
helper is one place to audit and **cannot drift across policies**, where inline predicates
demonstrably did — the evidence is *"2 of 5 policies omit it"*. `is_active_coach_of` already exists
in three migrations, so the precedent is genuinely applicable. **The untracked *"(b) recommended"*
note is NOT the basis** — §8.23 records it as carried from prior QA. *(a) preserved.*

**`D17` — ANSWERED: YES, FIX BEFORE APPLYING.**
*Rationale (1, 13):* `QA_CLOSURE_STANDARD` §5.2 — **tracked** — requires that *"a closure that
redefines a database object must prove it preserved every property the object carried."*
`SEC_PHI_1` redefines PHI-limiting views; **fix-first is the only order under which that proof is
possible.** *Explicitly NOT the basis (12):* the *"non-functional as written"* finding is
**UNTRACKED** and is not treated as implementation evidence. *Consequence:* §5.2's P1 row already
reads *"corrected `SEC_PHI_1`"*, so **§8.25·3's inconsistency resolves in favour of the existing
row** — no phase-model change is required.

### 19.2 · TIER 1 — completes `D4`

**`D11` — ANSWERED: TRUST'S SCOPE IS THE THREE AREAS OF §5.2's P6 — Security · Incidents · Audit
Logs. AI Guardian remains P7 and is NOT inside Trust.**
*Rationale (6, 10, and the constraint rule):* §5.2's P6/P7 split is a **tracked prior ruling** and
governs over the untracked four-area count. **Build scope, minimally stated:** Trust is a
**governance review surface over existing audit and observability records**. **It introduces no
tables of its own** — it reads the three audit populations and the D12 population. *The three-vs-four
contradiction is preserved, not resolved.*

**`D4 · A14` — ANSWERED: TRUST VISIBILITY = EXACTLY `A13`'s GRANTS, AND NOTHING MORE.**
The Trust operator sees, per population, precisely what `A13` already grants it: Event, Incident and
Control evidence. *Rationale (1, 2):* **no PHI payload is surfaced to Trust** — occurrence facts,
actor/subject identifiers and control evidence only. **Cross-population correlation is permitted
ONLY through the D12 correlation identifier, never by joining on subject identity** (2, 11). Trust
reads remain audit-worthy per `A13` sub-ruling 5 with its recursion boundary unchanged.

> **`D4` IS NOW COMPLETE.** `A2`, `A1`, `A3`, `A6`, `A11`, `A12`, `A13` and `A14` are all answered.

### 19.3 · TIER 2 — the P2 audit + observability set

**§8.16·Q4 — ANSWERED: THE DEFERRAL IS DISCHARGED FOR THE OBSERVABILITY POPULATION ON THE SAME
TERMS AS THE AUDIT POPULATIONS — `service_role` is NOT the writer of record.**
**Precedence recorded, as required:** §8.7 discharges `A11` sub-ruling 3 **unqualified**;
§8.16/§8.17 read it as *"for the audit populations"*. **§8.7's unqualified reading governs**, because
the narrower reading would leave **the newest population the least constrained** — which 11 forbids.
**The contradiction is preserved, not rewritten.** *Limit required by 13:* §8.19 declined the
anchor, so this binding is **DML-deep only**.

**§8.16·Q1 — ANSWERED: FREEZE-IDENTITY-COLUMNS, extended from the Event population.**
Identity and occurrence facts of an observability record are immutable at the DML layer; payload
fields are write-once. *Rationale (6, 9):* no fourth meaning is invented; `NO RUNTIME WRITE PATH` is
excluded on its own text; `APPEND-STATE-TRANSITIONS` presumes a lifecycle observability records do
not have; **declaring them mutable would broaden what can be silently rewritten (11)**.
***This is NOT a tamper-resistance claim*** (13, §8.19).

**§8.16·Q2 and `D12`·Q6 — ANSWERED AS ONE: PER-COMPONENT WINDOWS.**
**Observability audit events retain `A12`'s 6-year Event window.** **All other observability
components — logs, metrics, traces, health — take a 90-day operational window.**
*Rationale (2, 11):* retaining telemetry for six years broadens retention enormously with no privacy
justification; shortening the audit-worthy category would narrow an already-ruled retention. **The
90-day figure is an owner-selected architectural default pending legal/compliance ratification, NOT
a claim that any legal requirement exists** — the same qualification `A12` ruling 4 carries.
*"No retention rule at all" is REJECTED* because it would supersede `A12` ruling 3 (§8.16 caution).

**§8.16·Q3 and `D12`·Q12 — ANSWERED AS ONE: EXTEND THE MIXED MODEL — admin and Trust operator,
role-class only.**
Observability records carry **no subject relationship to anchor on**, so no relationship-based
reader applies. *Rationale (6, 10):* **no new operator class is created.** `admin-only` was
foreclosed by §8.17 (§8.25·1).

**THE ROLE QUESTION — §8.18·Q3 + §8.20·Q2 + §8.20·Q3, ANSWERED AS ONE. No third role is created.**

| dimension | decision |
|---|---|
| **Who may RESOLVE identity** | **NO STANDING PARTY.** Resolution occurs **inside the audit read path**, gated by `A13`'s per-population reader rules. **No party may enumerate or bulk-resolve the mapping.** |
| **Who may SEVER** | **The erasure executor role** established by §8.18·Q1. |
| **The identity-mapping authority** (`A13` sub-ruling 6's third authorization) | **A named, separately-grantable capability vested in the erasure executor — NOT a third role.** |

*Rationale (1, 3, 6, 10):* a standing "resolve any pseudonym" power is the single largest
re-identification risk and nothing requires it; making the third authorization a **named grant
rather than a role** keeps it **separable later without redesign (8)** while honouring the two-role
commitment today. ***`service_role` is not the answer and is explicitly excluded*** per `A12`
ruling 6.

**§8.20·Q1 — ANSWERED: A TABLE IN `public`, RLS ENABLED, WITH NO POLICY GRANTING ANY CLIENT ROLE.**
Deny-by-default; reachable only by the erasure executor's named grant and the `SECURITY DEFINER`
audit read path. *Rationale (5, 6, 10):* the `decision_traces` shape — a policy that grants reads and
**no write policy at all** — is genuinely applicable precedent. A new schema has **zero** precedent
and buys little while the DDL layer is open; an external store is speculative and would import
`PD-A24`-adjacent decisions. ***Not claimed to be tamper-resistant*** (13).

**§8.20·Q4 — ANSWERED: ACCEPT DML-DEEP SEVERANCE, EXPLICITLY QUALIFIED.**
Severance binds **every caller at the DML layer** and is **NOT durable against a party holding DDL
rights**. *Required by 13:* **the programme must NOT describe anonymisation as irreversible.**
**§8.19's accepted-exposure posture is hereby EXTENDED to the observability population and to the
mapping** — closing the scope gap §8.16·Q4 flagged.

**§8.18·Q2 — ANSWERED: THE PARTY READING.** No single party may hold both erasure authority and read
authority. *Rationale (3):* this is the direct expression of separating authorization, execution and
audit, and it makes TWO ROLES structural rather than incidental. **No supersession of `A13`
sub-ruling 4 is required or made.**

**`D12`·Q1 — ANSWERED: AUTHOR A TRACKED LIST.** `SQ-10` comprises **six** components D12 owns:
**structured logs · metrics · traces · health endpoints · alerting · the correlation identifier.**
Retention is governed by §8.16·Q2, not a separate component; **audit events belong to `D4`, not
`SQ-10`**. *Rationale (12):* the untracked eight-item list is **NOT ratified**.

**`D12`·Q2 — ANSWERED: EACH ORIGIN MINTS, WITH A PROVENANCE TAG.**
*Rationale (3, 13):* it is the only option with tracked precedent — `A3` sub-ruling 3 requires
asserted and cryptographically grounded attribution to **remain distinguishable and never be
equated**. Client-minted identifiers are accepted but tagged `asserted`; server-minted are tagged by
origin. ***No identifier is treated as trustworthy merely because it is present*** — the only
signed channel into Postgres is the JWT claims GUC.

**`D12`·Q3 — ANSWERED: YES — a correlation identifier column on the audit Event row**, classified
under `A11`'s freeze as an **identity/occurrence column** (immutable). *Rationale (4):* relating by
actor + time window is not deterministic. Delivery is downstream of `D4`, **which §19.2 completes**.

**`D12`·Q5 — ANSWERED: THE IDENTIFIER IS NON-IDENTIFYING BY CONSTRUCTION AND SURVIVES ON BOTH
SIDES.** It must be a **random opaque value with no derivation from subject identity**, and **the
observability population carries NO subject identifier — only the correlation identifier.**
*Rationale (2, 11):* this **resolves** the §8.13 hazard rather than accepting it — severing the
audit-side mapping now fully anonymises the operation **across both populations**.

**`D12`·Q9 — ANSWERED: YES — D12 specifies the structured log record shape; the TRANSPORT remains
`PD-A24`'s.** *Rationale (5):* `PD-A24` itself states the sink *"can and should be built **before**
the vendor is chosen — it is one interface"*. **Option (b) remains blocked on `PD-A24` and is
preserved as an external owner dependency.**

### 19.4 · Beyond the frontier — resolved under the same hierarchy

**`EC-01`·Q2 — NO.** A canonical's closure class does not bind an alias of a different class; under
§8.15 each alias's substantive status **and** its evidence standard follow its own subject matter.
**`EC-01`·Q3 — `G-14` IS EVALUABLE, AND IT EVALUATES TO NOT MET.** *"Evaluable"* means capable of
assessment; a conjunct with no requirement row evaluates to **not satisfied**, never indeterminate.
*Required by 13:* **a gate with an unmeasurable conjunct must never be reported as passed.** The
missing audit-log requirement row is a **documentation gap in `RELEASE_GATES.md`** — recorded, **not
edited**.
**`EC-01`·Q4 — IT IS A PRECONDITION, AND ITS ABSENCE IS A ROW-COMPLETENESS DEFECT, NOT A CLOSURE
DEFECT.** The standard prescribes a consequence for an *inadequate* answer, not a *missing* one, so
the class-ladder satisfaction stands while the row is incomplete. **No registry edit is made.**
**`EC-01`·Q5 — YES.** `QA_CLOSURE_STANDARD.md` should carry the REFERENCE-ONLY definition. **Recorded
as a required documentation action; NOT performed — that file is outside the mutation boundary.**

**`D5` — (a) DIRECT SUPABASE + RLS, for Admin AND Trust.** *Rationale (9, 10):* the NestJS service is
thin and **has no deployment target at all** (`PD-A17`, open, Julia's); routing Admin through an
undeployed API is speculative infrastructure. The Admin-vs-Admin/Trust wording disagreement is
resolved as **both**, consistent with §19.2's Trust-as-read-surface.
**`D6` — SEPARATE SURFACE, AS A FLUTTER WEB TARGET — option (b).** *Answered in two steps so the
presupposition is not imported:* the **prior** question (in-app vs separate) is answered
**SEPARATE**, because admin surfaces must not ship in the member mobile bundle (1); the **narrower**
question (new app vs added target) is answered **ADDED TARGET**, reusing the existing codebase, auth
and theme with no new application to deploy (6, 9). *(a) and (c) preserved.*
**`D7` — COLUMN-LIMITED VIEWS over `user_profiles`, not distinct modules.** *Rationale (1, 2):*
distinct modules duplicate the identity model; column-limited views enforce least privilege at the
data layer. **Coherence note:** this depends on `D17`'s fix landing — the view pattern is `D17`'s
subject, and §19.1 answered it fix-first.
**`CONF-08` — THE DECISION OBJECT IS THE IMPERATIVE, AND THE ANSWER IS COMMISSION.** The
interrogative *"where do they live"* is answered by evidence — **0 mentions in 7 design docs** — so
the live decision is supply-vs-commission, and with zero artefacts only commissioning is available.
**The 21 / 23 / 10 surface counts are preserved unreconciled and NONE is adopted.**
**`CONF-06` — (a) HARDEN FIRST.** *Rationale (1, 11):* `role='vendor'` is **self-assertable at
signup**; building partner APIs on it would broaden a trust boundary silently. With **0 vendor
users** the hardening is cheap now and expensive later (8). **Newly surfaced dependency recorded:
`CONF-06` depends on `D2`, which is not among the 42.**
**`D10` — DISCLOSE EVERY AI PROCESSING PURPOSE THAT OPERATES ON MEMBER DATA, NAMING THE PROCESSOR.**
*Rationale (2, 13):* disclosure must match implementation. The privacy policy currently names
*"selected analytics providers"* **that do not exist** while **not naming Anthropic, which does
process member data**. **Requires a copy amendment — NOT performed; app copy is outside the
boundary.**
**`D-V5` — AN AGENT IS REPRESENTED BY A DISTINCT NON-HUMAN PRINCIPAL IDENTIFIER in the Event
`actor` field, carrying `A3` sub-ruling 3's provenance tag marking it `agent`.** **Never a human
user's identity; never `service_role`.** *Rationale (3, 7):* this is an identifier convention, not a
new principal — **no role is created**, and auditability does not depend on `service_role`.

### 19.5 · DEFERRED under a prior ruling — the wearable block

**`D-V1`, `D-V2`, `D-V4` — DEFERRED, and `D-V3` with them (§19.6).**
**`PD-G01` is a tracked owner decision recording Wearable Intelligence as *"APPROVED — FUTURE
BUILD · implementation NOT AUTHORIZED"*, explicitly *"recorded so it is not accidentally
started."*** The constraint rule requires obeying it. Selecting a platform location, a store or a
PHI boundary for a programme whose implementation is not authorized would be **speculative
infrastructure (10) and an irreversible commitment (6)** for a phase that may not begin.
**This is a deferral under a prior owner ruling, not an architecture selection.** `PD-G01` is not
overridden, and the wearable stack remains non-existent at HEAD.

### 19.6 · ARCHITECT-FORMULATED — `D-V3` and `D-V6`

> **PROVENANCE, stated exactly as required:** ***"Architect-formulated owner decision; original
> historical question text was unrecoverable."*** **These wordings did NOT exist historically.**
> No wording was borrowed from `CONF-03`, from a dependency or from any adjacent ID.

**`D-V3` — formulated question:** *"What is the canonical wearable observation contract — the record
shape, units and provenance fields every ingested wearable metric must conform to before it may be
stored or read?"*
**Options:** (a) adopt a published external health-data standard · (b) define a minimal internal
canonical record · (c) store provider-native payloads and normalise on read.
**DECISION: (b).** *Rationale (2, 6, 9, 10, 11):* (a) is speculative — **no evidence any provider
here emits any standard**; (c) defers normalisation into every reader and leaves **PHI scope
unbounded**, which 11 forbids. **Execution is DEFERRED under `PD-G01`** with the rest of the block.

**`D-V6` — formulated question:** *"By what mechanism, and at which point in the release chain, is a
software bill of materials produced and retained for a release?"*
**Options:** (a) generate in CI at release time · (b) generate outside CI as a manual release-time
artefact · (c) accept the absence as a governed risk with a recorded compensating control.
**DECISION: (a) generate in CI at release time.** *Rationale (4, 13):* **a manual step is not a
control**; accepting absence means the release chain cannot prove component provenance, and 13
forbids claiming a supply-chain control the implementation cannot demonstrate.
***The "installation currently forbidden" constraint is UNTRACKED and has no tracked standing
(§8.23), so under 12 it does not bind this architecture decision.*** It is preserved as an
**operational constraint requiring separate resolution before execution.**

**No implementation follows from any decision in §19.**

---

## 20 · FINAL IMPLEMENTATION-READINESS AUDIT

Run after §19. **Nothing below is implemented.**

### 20.1 · Decision ledger — **42 accounted for**

| disposition | count | items |
|---|---|---|
| **RESOLVED** under delegated architecture authority (§19) | **35** | Tier 0 (3) · Tier 1 (2) · Tier 2 (17) · beyond-frontier (11) · architect-formulated (2) |
| **DEFERRED** under a prior owner ruling (`PD-G01`) | **3** | `D-V1`, `D-V2`, `D-V4` |
| **EXTERNAL OWNER DEPENDENCY** — *not this delegation's to make* | **4** | `D12` `Q7`, `Q8`, `Q10`, `Q11` |

Plus previously answered: `CONF-01` · `D4·A1/A2/A3/A6/A11/A12/A13` · `D12` scope · `D12·Q4` ·
`EC-01·Q1` · `D-D1` · §8.18·Q1 · §8.19·Q1 · `D15` · `D1(iv)`.

### 20.2 · Phase entry conditions — recomputed

| phase | entry condition | state after §19 |
|---|---|---|
| **P0** | `CONF-01`, `CONF-02` | ✅ **SATISFIED** — both answered |
| **P1** | `D1(i)–(iv)`, `D3`, `D17` | ✅ **SATISFIED** — all answered |
| **P2** | `D4`, `D12` | ⛔ **`D4` COMPLETE** (§19.2); **`D12` INCOMPLETE** — `Q7`/`Q8`/`Q10`/`Q11` await `PD-A24`/`PD-A17` |
| **P3** | `D-V1`, `D-V2`, `D-V3` | ⛔ deferred under `PD-G01` |
| **P4** | P3 | ⛔ downstream |
| **P5** | P2, `D5`–`D7` | ⛔ decisions answered; **blocked on P2 and on `CONF-08` artefacts** |
| **P6** | P2, P5, `D11`, `D-D1` | ⛔ decisions answered; blocked on P2/P5 |
| **P7** | P2, P6, `D-V5` | ⛔ `D-V5` answered; blocked on P2/P6 |
| **P8** | P4, `D6`, designs | ⛔ `D6` answered; blocked on P4 and `CONF-08` |
| **P9** | P3–P8, `CONF-06` | ⛔ `CONF-06` answered; blocked upstream |
| **P10** | `D-V6`, CI secrets, egress | ⛔ `D-V6` answered; **operational "installation forbidden" constraint unresolved** |

### 20.3 · Security gates

**Unchanged: 5 PASS · 2 PARTIAL · 8 FAIL of 15.** **No gate moved** — §19 recorded decisions, and a
decision is not evidence. **`G-14` now has a recorded evaluation: NOT MET** (§19.4), and its
audit-log conjunct still has **no requirement row** in `RELEASE_GATES.md`.

### 20.4 · Required actions that are NOT performed — each outside the mutation boundary

| action | required by | status |
|---|---|---|
| `QA_CLOSURE_STANDARD.md` to carry the alias definition | `EC-01·Q5` | **NOT performed** — file outside boundary |
| `EC-01` row's §10 one-line answer (verified **absent**) | `EC-01·Q4` | **NOT performed** — registry outside boundary |
| Registry `:2102`'s discharging reading vs §8.15 | §8.15 | **stands unedited** — conflict preserved |
| `RELEASE_GATES.md` audit-log requirement row | `EC-01·Q3` | **NOT performed** |
| Privacy-policy AI-processor disclosure | `D10` | **NOT performed** — app copy outside boundary |
| `PD-B23`'s *"unconditional"* `_toggleConnect` deletion | `PD-B23` | **still unremediated at HEAD** |
| `SEC-G1` baseline lowered to the live catalog | `D15` | **still "proposed, not applied"** |
| Admin/Trust design artefacts | `CONF-08` | **commissioning required — 0 exist** |
| **No registry ID allocated** | — | **correct; none may be** |

### 20.5 · Required migrations — **none written**

Verified zero at HEAD: audit tables · observability tables · incident tables · `CREATE ROLE` ·
correlation identifier · identity-mapping table · SBOM step in CI. **§19 specifies their shape; it
does not create them.**

### 20.6 · QA / control-evidence dependencies

**`QAX-SEC-08` remains OPEN / PARTIALLY VERIFIED — 3 of 4 rungs.** `QAX-SEC-09`, `F-03b`,
`SEC-PHI-9/10`, `SEC-AI-1`, `NEW-W1-02`, `NEW-10` all remain **OPEN**. **No finding was remediated
and no status changed.**

### 20.7 · Contradictions — carried forward, none resolved

All thirteen from §18.5, **plus two precedences recorded in §19 rather than resolved**: `A11`
sub-ruling 3's discharge scope (**§8.7's unqualified reading given precedence**), and `CONF-08`'s
imperative-vs-interrogative form (**the imperative taken as the decision object**). **Both original
readings stand.** **Newly surfaced:** `CONF-06` depends on **`D2`**, which is **not among the 42**.

### 20.8 · Unrecoverable items — final state

**`D-V3`** and **`D-V6`** now carry **architect-formulated** questions and decisions, marked
***"Architect-formulated owner decision; original historical question text was unrecoverable."***
**The historical wording remains lost and is not claimed to have been found.**

### 20.9 · Verdict

**P0 and P1 are fully unblocked. Their every entry condition is satisfied and every decision they
depend on is answered.**

**P2 is NOT unblocked.** `D12` cannot complete while `Q7`, `Q8`, `Q10` and `Q11` await **`PD-A24`**
and **`PD-A17`** — **TRACKED, OPEN, owner *Julia***. Per the delegation these are **preserved as
external owner dependencies, not architecturally settled**, and **Julia's ownership is not
overridden.**

> **A genuine owner decision therefore remains necessary for P2 and beyond — but NOT for P0 and P1.**
> **V5 implementation may begin at P0/P1 now; it cannot reach P2 until `PD-A24` and `PD-A17` are
> answered by their owner.**

---

## 21 · IMPLEMENTATION STATUS — P0 / P1

**Implementation has begun.** This section records what was built and what evidence exists.
**No owner decision or historical ruling is rewritten here.**

### 21.1 · P0 · GOVERNANCE — **COMPLETE**

Its deliverables are governance records, not code: `CONF-01` and `CONF-02` answered, the protected
baseline confirmed as the 91 registered routes, migration numbers 132+ assigned. **No code was
required and none was written.**

### 21.2 · P1 · FOUNDATION / SECURITY — **CODE COMPLETE, CLOSURE BLOCKED**

| P1 content item | migration | state |
|---|---|---|
| `coach_team_members` `WITH CHECK` | 133 | done (Wave 1) |
| corrected `SEC_PHI_1` — team-lead arm | 132 | done (Wave 1) |
| corrected `SEC_PHI_1` — event-host arm (`QAX-SEC-09`) | **135** | **FIXED IN CODE** |
| status predicates (`D3`) — `SEC-PHI-9`, `SEC-PHI-10` | **136** | **FIXED IN CODE** |

**Migration 135 — `QAX-SEC-09`.** Creates `event_attendee_profiles` (five columns, no PHI) and
removes the `hosts_event_for` arm from the `user_profiles` SELECT policy, which now admits only the
subject and an **active** coach. `security_invoker = off` is the `D17` correction — the proposal's
`on` would have returned `200 []` to exactly the users the view serves, the defect 132 recorded as
`NEW-5`. Companion: `vendor_service.getRegistrations` became a two-step read on 132's proven
pattern, plus the `schema.mjs` view-inventory entry.

**Migration 136 — `D3`.** Adds `is_active_coach_of(text)`, which **delegates to the uuid overload
rather than restating the predicate**, so the meaning of *"active"* has one definition and cannot
drift. Both offending policies now route through it. **The "2 of 5" population was confirmed by
enumeration:** `005`, `026`, `036` already carried `status = 'active'`; `029` and `035` did not.
`029`'s own comment claimed *"an ACTIVE client's photos"* while its predicate enforced nothing.

**Two defects found during implementation and fixed, recorded so they are not lost:**
- A bare `const {}` in the reshape infers `Map<dynamic, dynamic>` and **would have thrown on the
  consumer's cast** whenever a profile was RLS-filtered. *(The identical pattern exists at
  `coach_business_screen.dart:90` from 132 — **not touched**, outside this change's scope.)*
- A bare `::uuid` cast on a storage path would raise **22P02 from inside an RLS predicate** — a
  query error, not a denial. The overload fails closed on NULL and non-uuid input instead.

**Incidental hardening:** both `D3` policies previously read `coach_client_relationships` **directly
inside a policy predicate**, against a table `113` put RLS on. Routing them through the
`SECURITY DEFINER` helper removes that recursion exposure, which `100:18–19` exists to prevent.

### 21.3 · Evidence — and its ceiling

**173 Flutter tests passed** across seven guard suites; **contract guard PASS** (91 tables, 7 views,
134 FKs); `check:guards` green; `dart analyze` clean; bypass hunt found **no alternate coach route**
into either protected surface.

> **CEILING: FIXED IN CODE. Nothing here is VERIFIED LIVE.**
> `npm run test:security` requires `QA_URL`/`QA_ANON`/`QA_SERVICE`, which are unavailable. **No
> database was contacted.** **`QAX-SEC-09`, `SEC-PHI-9` and `SEC-PHI-10` are NOT closed, the
> remediation registry is NOT edited, and migrations 135 and 136 have not been applied anywhere.**

### 21.4 · Why P1 is not COMPLETE

`QA_CLOSURE_STANDARD` §5.2 requires **VERIFIED LIVE** for a security finding — *"a real request
against QA reproduces the secure/correct behaviour, and the same probe demonstrably failed before
the fix."* **Every remaining P1 acceptance criterion is a live-verification criterion**, including
`QAX-SEC-08`'s fourth rung (§7 records 3 of 4). **The code is written; the evidence the standard
demands cannot be produced without database access.**

### 21.5 · Phase graph, recomputed

**P2 is NOT reachable.** `D4` is complete (§19.2) but `D12` is not — `Q7`, `Q8`, `Q10`, `Q11` await
**`PD-A24`** and **`PD-A17`**, owner *Julia*. **P3** deferred under `PD-G01`. **P5–P9** blocked
upstream on P2. **P10** needs `D-V6` (answered) **plus CI secrets and egress**, which are
infrastructure dependencies, not decisions.

---

## 22 · LIVE VERIFICATION ATTEMPT — P1

**Outcome: live verification is UNAVAILABLE. P1 remains FIXED IN CODE.** No QA evidence was
obtained, none is claimed, and **no finding's closure state was changed.**

### 22.1 · Three independent gaps, each sufficient on its own

1. **Credentials absent.** `QA_URL`, `QA_ANON`, `QA_SERVICE` are unset in the environment, and both
   `.env` and `.env.local` are **empty (0 bytes)**. `supabase/tests/security/README.md` requires all
   three; `run.mjs` refuses without them. *(Presence was checked, never values.)*
2. **Docker daemon not running.** The Supabase CLI's remote dump path requires it, so **even a
   read-only catalog observation is unavailable.** The linked project was first verified **not** to
   be the production ref before any command was attempted.
3. **Migrations 135 and 136 are not applied to QA.** Even with 1 and 2 resolved, **no post-fix state
   exists there to probe**, so the standard's *"the same probe demonstrably failed before the fix"*
   comparison has no second half.

### 22.2 · Static verification completed instead — and it is genuinely adversarial

**`migration-durability-guard.mjs`: PASS (enforcing) — 0 unrecorded regressions.** It detects
*strip events*, where a later migration silently removes a property an earlier one established.
**Neither 135 nor 136 produced one.**

**`--self-test`: ALL PASS (7/7).** The guard is **proven non-vacuous** — it correctly flags a
dropped wrapper and pin, treats an unrecorded strip as fatal, does **not** flag a redefinition that
carries both properties forward, and still detects the historical `F-J-01` regression and attributes
it to migration 119.

> **This is static evidence about migration source. It is NOT live evidence and is not offered as a
> substitute for it.**

### 22.3 · Cross-check against the recorded fix simulation — a justified divergence

`supabase/tests/qa_exhaustion/fixsim/QAX-SEC-09.sql` simulated the fix as: drop the
`hosts_event_for` arm, and *"they use **`public_profiles`** for registrant names."*

**Migration 135 drops the same arm but does NOT use `public_profiles`. That divergence is
deliberate and, on the evidence, necessary:**

- **`public_profiles` has no `email`** (`110:81–89` — `id`, `first_name`, `last_name`, `avatar_url`,
  `role`). Using it would have **silently dropped the attendee email** from the vendor's list —
  changing vendor-facing behaviour and **pre-empting the owner's explicit PII question in one
  direction**, which §19 forbids.
- **`public_profiles` carries no row predicate.** It is a general-purpose public projection, so
  routing attendee reads through it would rest on an **unrestricted** view rather than a
  relationship-gated one. `event_attendee_profiles` is gated by `hosts_event_for()` and is
  **strictly tighter**.

**The simulation also predates migration 132** — it still carries the `is_team_lead_of` arm that 132
removed. It is a Wave-0 artifact and is **preserved unchanged**, not treated as governing.

### 22.4 · Status — unchanged and not overclaimed

**`QAX-SEC-09`, `SEC-PHI-9` and `SEC-PHI-10` remain OPEN and FIXED IN CODE.**
**`MASTER_REMEDIATION_REGISTRY.md` is NOT edited.** `QAX-SEC-08` remains OPEN / PARTIALLY VERIFIED
at 3 of 4 rungs. **P1 is CODE COMPLETE, not VERIFIED COMPLETE.**

### 22.5 · Exact resume point

Supply `QA_URL`, `QA_ANON`, `QA_SERVICE`, **start Docker**, and **apply 135 and 136 to QA**. Then
`node supabase/tests/security/setup-identities.mjs` followed by `run.mjs` produces the request-level
probes §5.2 requires, and the three findings become closable on their own evidence.

---

## 23 · QA VERIFICATION — MIGRATIONS 135/136 APPLIED · **FIXED ON QA**

**Reached: `FIXED ON QA`. NOT reached: `VERIFIED LIVE`.** §2's ladder defines `FIXED ON QA` as *"the
migration, function or configuration is applied to QA and the object exists in the live catalog"* and
`VERIFIED LIVE` as *"a real request against QA reproduces the secure/correct behaviour."* **The first
is now evidenced; the second is blocked by infrastructure.** **No finding is closed.**

### 23.1 · Environment — verified, not assumed

`QA_URL`/`QA_ANON`/`QA_SERVICE` present and clean (single-line, pure ASCII). **All three, and the
linked project, verified NOT to reference the production ref before any contact.** Docker running.
`setup-identities.mjs` succeeded — five fixture identities, `ids.json` written.

### 23.2 · PRE-FIX baseline — captured from the **live QA catalog** before applying anything

Migration list confirmed **135 and 136 unapplied** (Local present, Remote empty). All three
vulnerabilities were then observed **live**:

| finding | live pre-fix state |
|---|---|
| **QAX-SEC-09** | `user_profiles` policy carried `… OR "public"."hosts_event_for"("id")` — the whole-row arm |
| **SEC-PHI-10** | `score_events` *"coach reads client events"* = `EXISTS(… WHERE r.coach_id = auth.uid() AND r.client_id = score_events.user_id)` — **no status condition** |
| **SEC-PHI-9** | `storage.objects` *"coach reads client progress photos"* = `EXISTS(… r.client_id::text = foldername(name)[1])` — **no status condition** |

`event_attendee_profiles`: **absent**. **The source analysis in §21 is confirmed against the real
database — the two D3 policies genuinely lacked `status = 'active'` in QA, and 029's comment claiming
*"an ACTIVE client's photos"* was false in the live catalog.**

### 23.3 · Applied, then POST-FIX state re-read

`supabase db push` applied **135** and **136**. Re-dumped catalog:

| object | live post-fix state |
|---|---|
| `user_profiles` policy | `(("id" = auth.uid()) OR is_active_coach_of("id"))` — **`hosts_event_for` GONE** |
| `score_events` policy | `is_active_coach_of("user_id")` |
| `storage.objects` policy | `bucket_id = 'progress-photos' AND is_active_coach_of(foldername("name")[1])` |
| `event_attendee_profiles` | exists, `security_invoker='off'`, `security_barrier='true'`, **exactly 5 columns** |
| `is_active_coach_of(text)` | overload present |
| grants on the new view | `GRANT ALL … service_role` · `GRANT SELECT … authenticated` — **no write grant to `authenticated` or `anon`**, identical to `team_member_profiles` |

**This is a genuine before/after comparison against the live catalog, not an inference.**

### 23.4 · Why `VERIFIED LIVE` was NOT reached — infrastructure

**PostgREST (`/rest/v1/`) is unreachable from this host.** Diagnosed, not guessed:

- `curl /rest/v1/user_profiles?select=id&limit=1` → **`http=000`, `connect=0.000000s`, twice at 20 s.
  TCP never establishes.**
- `curl /auth/v1/health` → **`200`, but `connect=5.88 s`** — the same host and port answer, slowly.
- `supabase db dump` → **succeeds** (10,619 lines). **The database and auth are reachable; only
  PostgREST is not, so the project is NOT paused.**
- Harness result: `58/65` across 8 suites, with **six suites reporting `-1/0`** — which
  `run.mjs:36-38` shows means the suite **threw before recording any assertion**, cause
  `UND_ERR_CONNECT_TIMEOUT`. **`3A-10 chat-media storage` passed 42/42** because it exercises the
  **Storage** API, not PostgREST — which is exactly why the failure pattern is endpoint-shaped.

**The harness asserts over PostgREST. With PostgREST unreachable, request-level evidence cannot be
produced at all — for these findings or any other.**

### 23.5 · A second, independent gap in the harness itself

**No existing suite probes any of the three surfaces.** Verified: zero matches for `progress-photos`,
`score_events` or `event_registrations`/`event_attendee_profiles` across every
`supabase/tests/security/*.mjs`. **Even with PostgREST restored, `run.mjs` as it stands would not
produce §5.2 evidence for these findings — new probes must be written.** `d08` is the established
precedent for a suite authored against a migration and failing by design before its gate.

### 23.6 · Status

**`QAX-SEC-09`, `SEC-PHI-9`, `SEC-PHI-10`: OPEN — now `FIXED ON QA`, previously `FIXED IN CODE`.**
**`MASTER_REMEDIATION_REGISTRY.md` is NOT edited** — §2.1 requires `VERIFIED LIVE` for a security
finding's closure and that rung is not met. `QAX-SEC-08` unchanged at 3 of 4.
**P1: CODE COMPLETE and APPLIED TO QA, not VERIFIED COMPLETE.**

---

## 24 · REQUEST-LEVEL QA VERIFICATION — 28/28 · **POST-FIX PROVEN**

New suite `d10-p1-profile-and-status-boundaries.mjs`, registered in `run.mjs`. **28/28 against live
QA.** **No finding is closed — see §24.3.**

### 24.1 · Why it had to be written

**No existing suite probed any of the three surfaces** — verified: zero matches for
`progress-photos`, `score_events` or `event_registrations` across every other
`supabase/tests/security/*.mjs`. §4:105's *"necessary, never sufficient"* applies exactly: the static
guards assert migration **text**; only a request proves the policies, column grants and PostgREST
**compose** into a boundary.

### 24.2 · What is now proven at request level

| surface | proven |
|---|---|
| **QAX-SEC-09** | host can **no longer** read the attendee `user_profiles` row (rows=0) · PHI unreachable there · host **does** still read via `event_attendee_profiles` (rows=1) · **exactly** the five columns · six PHI columns individually absent · selecting PHI *through* the view rejected (400) · a non-host reads nothing · **a write through the view refused (403) and the profile unmodified** |
| **SEC-PHI-10** | `active` **READS** (rows=1) · `pending` **DENIED** · `ended` **DENIED** · no relationship denied without erroring |
| **SEC-PHI-9** | `active` **LISTS** (objects=1) · `pending` **DENIED** · `ended` **DENIED** · no relationship denied · **self-access preserved** |

**The positive cases are what make the negatives meaningful.** An all-deny result would pass a
broken probe equally well — and did, on the first run, until the positive assertion exposed that the
fixture insert had failed.

**Two probe defects were found and fixed rather than worked around:** `score_events` requires
`category` and `action` (both `NOT NULL`), read from the live catalog rather than assumed; and the
resulting vacuous all-deny pass was caught by the positive case.

### 24.3 · Why the findings are still NOT closed

§2's `VERIFIED LIVE` rung requires *"a real request against QA reproduces the secure/correct
behaviour, **and the same probe demonstrably failed before the fix**."*

**The second half cannot now be produced.** 135/136 were applied to QA (§23) **before** a
request-level probe existed, so the pre-fix state no longer exists there to probe. The pre-fix
evidence that does exist is **catalog-level** (§23.2) and is genuine, but it is not a request.

> **The only way to obtain the request-level pre-fix half is to temporarily revert these policies on
> QA — deliberately reintroducing a PHI exposure on a shared environment. That is an authorization
> decision, not a test detail, and it is NOT taken here.** The `I-WRK-01` precedent did run its live
> probe against a pre-fix tree, so the pattern exists — but it reverted **application code**, not a
> **PHI access-control policy**.

**`QAX-SEC-09`, `SEC-PHI-9`, `SEC-PHI-10` remain OPEN.** `MASTER_REMEDIATION_REGISTRY.md` is **not
edited**.

### 24.4 · Harness reliability — a standing infrastructure caveat

**QA connectivity from this host is intermittently unreliable.** Across runs, `run.mjs` produced
`58/65`, then `17/24`, with **different** suites failing each time (`3A-10` passed 42/42 in one run
and threw in the next), all with `UND_ERR_CONNECT_TIMEOUT` / `read ETIMEDOUT`. The new suite itself
needed **three attempts** before it completed.

**This is not a security result and must never be read as one.** `run.mjs:36–38` renders a thrown
suite as `-1/0`, which is visually indistinguishable from a failure. **Any future closure evidence
from this harness must come from a run that completed**, and the count must be checked against the
suite's own expected total.

---

## 25 · ⚠ ADVERSARIAL FINDING — migration 135's gate is ATTACKER-WRITABLE

An independent adversarial pass against the **live QA catalog** found a composition migration 135
did not close and whose severity its own header **understates**. **Every link below was
re-verified independently against the live dump.**

### 25.1 · The chain — five links, each confirmed live

1. **Zero `FORCE ROW LEVEL SECURITY` anywhere.** `event_attendee_profiles` runs
   `security_invoker='off'` and is owned by `postgres`, so it **bypasses `user_profiles` RLS by
   construction**. `hosts_event_for()` is the **entire** authorization.
2. **`hosts_event_for()` trusts `event_registrations.user_id`.**
3. **That column is attacker-writable.** The live policy
   `"vendors check in own event registrations" FOR UPDATE` has **NO `WITH CHECK`** — verified, zero
   occurrences. Postgres then reuses `USING`, which constrains **`event_id → vendor_id` only, never
   `user_id`**. The sibling `"users manage own registrations"` is **permissive**, so its stricter
   predicate is OR-ed away, not AND-ed. **No trigger exists on `event_registrations`** — verified.
4. **Vendor is self-assignable at signup.** `handle_new_user()` takes the role from signup metadata
   and admits `'vendor'`.
5. **Victim UUIDs are freely enumerable.** `public_profiles` is `security_invoker='off'` with
   **no `WHERE` clause at all** — verified — and `GRANT SELECT` to `authenticated`.

**Result: a self-registered vendor can rewrite a registration's `user_id` to any victim and read
that victim's `first_name`, `last_name`, `email`, `avatar_url` through the new view — repeatable
across the entire user base.**

### 25.2 · What this is, and what it is NOT

**It is NOT a regression introduced by 135.** Before 135, the *same* forgeable `hosts_event_for()`
gate granted the **whole `user_profiles` row including PAR-Q** through the base-table policy.
**135 genuinely reduced the blast radius from full PHI to four PII columns** — confirmed by the
live before/after in §23.

**It IS an understatement in 135's header**, which records only that the access **lifetime** is
unbounded. **The gate is also attacker-writable, and the header does not say so.**
*(Migration 135 is NOT edited — §8:219: "Never rewrite a migration in place unless the wave plan
explicitly authorizes it." The correction lives here.)*

### 25.3 · The underlying defect is ALREADY REGISTERED — under a different impact

**`BIL-3` / `K-04` · P0 · `READY_TO_REMEDIATE` · Wave 6** records exactly this policy defect:
*"`event_registrations`' policy has no `WITH CHECK`, so a member sets `paid`/`payment_id`
themselves."*

**Its recorded impact is billing self-grant. The PII-harvesting path is NOT recorded**, because
`event_attendee_profiles` did not exist until 135 created it. **This is the same shape §8.11
recorded for QAX-SEC-08 — *"three separately recorded facts that nobody had joined up."***

**No registry edit is made. No new finding ID is allocated.** `BIL-3`'s status, wave and ownership
are the registry's to change.

### 25.4 · Why this is an owner boundary, not something to fix here

Closing it means adding a `WITH CHECK` or an immutability trigger to `event_registrations` — which
is **`BIL-3`/`K-04`'s remediation, assigned to Wave 6**, and touches the **`F-21`/`OD-14`
policy-shape population, itself an open owner decision.** Doing it inside P1 would be scope
expansion into another wave's work on a P0 that has its own owner.

> **THE DECISION: does migration 135 stand as applied, or must `BIL-3` be pulled forward into P1?**
> Standing pat leaves a self-registered vendor able to enumerate the user base's names and email
> addresses. Pulling `BIL-3` forward means P1 absorbs a Wave 6 P0 and an `OD-14`-adjacent policy
> change. **Not decided here.**

### 25.5 · Two gaps that must not be papered over

1. **Bucket publicity is unverified.** The storage dumps are schema-only. **If `progress-photos` has
   `public = true`, all five of its policies are moot for reads via the public object URL** — and
   §24's `SEC-PHI-9` result would not mean what it appears to. **This must be checked before any
   "progress photos are protected" claim is signed.**
2. **The bypass is derived from the catalog, not executed.** Every link is individually verified and
   the Postgres semantics are documented behaviour, but **no exploit was run**. An executed proof
   should precede remediation scoping.

### 25.6 · What the pass confirmed

`diff` of pre/post public dumps is **exactly six hunks** and the storage diff **one** — the new
overload and its grants, the new view and its two grants, the `score_events` rewrite, the
`hosts_event_for` arm removal and its comment, and the storage policy. **No stray grant, policy or
function rode along. 135 and 136 did on QA precisely what they claim, and no more.**
Also confirmed: `is_active_coach_of(text)` **delegates** to the uuid overload in the live catalog,
`status = 'active'` is present in the uuid body, the guard **cannot** raise `22P02`, and **all 109**
`SECURITY DEFINER` functions have a pinned `search_path`.

---

## 26 · CORRECTION TO §24, A REGRESSION REPAIRED, AND ONE GAP CLOSED

### 26.1 · §24's "28/28" was OVERSTATED — corrected

An independent review of the probe found **four of the 28 assertions could pass while the boundary
they name was broken** — and **those four were the entire load-bearing evidence for `SEC-PHI-9` and
`SEC-PHI-10`.**

| defect | why it mattered |
|---|---|
| `setRelationship` **discarded its INSERT return** | a failed `pending`/`cancelled` insert left **no row**, the coach was denied, and the negative assertion passed **proving nothing about the status predicate** — it merely re-proved "no relationship → denied" |
| the loops **never asserted `status < 400`** | `n()` returns 0 for an error body, so **a 500 raised from inside the RLS predicate — precisely the `22P02` regression 136's guard exists to prevent — would have scored as a successful denial** |

**Both are fixed.** The relationship row is now **read back and its status asserted**
(`insert=201 readback=pending` appears in the evidence), and both loops require `status < 400`.

**Three further weaknesses fixed:** the write-refusal used `blocked()`, which accepts **any** status
≥ 400, so a 405 or 500 would pass and the grant hardening would go untested — it now asserts **403
specifically**; storage requests sent `apikey: SERVICE` instead of `ANON`, which is not the request a
phone makes; and the suite carried only `lib.mjs`'s production **blocklist** — it now also carries
d07/d08's **positive `QA_REF` allowlist**, because *"is not production" is not "is QA"* and this is
the most write-heavy suite in the directory.

**Also corrected: `'ended'` is not a status this product writes.** It appears **nowhere** in the
schema; `'cancelled'` is the real terminal state. The suite now exercises the real one.

### 26.2 · NEW COVERAGE — 136's headline property was entirely untested

136 exists to make a non-uuid storage path **deny rather than raise `22P02` from inside an RLS
predicate**. **Nothing tested that.** An arm now places an object at a non-uuid folder via
`service_role`, then lists it as an **ACTIVE** coach so **only the guard can deny**:

> **Result: `status=200`, `objects=0` — denies cleanly, no error.** The fail-closed guard is now
> actually exercised.

**Revised result: 37/37**, up from 28/28, with the four unsound assertions **made sound**.

### 26.3 · A regression migration 136 introduced — found live, repaired in 137

**`PGRST203` — the two `is_active_coach_of` overloads shared the parameter name `target_user`, and
PostgREST resolves RPC overloads BY PARAMETER NAME**, so every `/rpc/is_active_coach_of` call became
ambiguous. Found by `d01` against live QA (status 300).

**Scope, stated accurately:** **the RLS policies were never ambiguous** — inside SQL the argument
type is known at parse time, and the live catalog confirmed both resolved. **Only the PostgREST RPC
path broke.** No application code calls it, but it is `EXECUTE`-granted to `authenticated` and
reachable at `/rpc/`, so it was a real regression in a reachable surface.

**Migration 137** renames the text overload's parameter to `target_path`. Because Postgres cannot
rename a parameter via `CREATE OR REPLACE`, the function is dropped and recreated **with the
dependent policy dropped and recreated in the same transaction**, so the boundary is never absent
from a committed state. **`D3` is unchanged** — same overload, body, delegation and grants; only the
name differs, invisible to positional callers.
**Verified live: `/rpc/is_active_coach_of` now returns `false` cleanly, zero `PGRST203`.**

### 26.4 · The §25 bucket gap is CLOSED

**`progress-photos` is `public = false`** — confirmed via the Storage API. **The RLS policies
genuinely govern reads, so §24's `SEC-PHI-9` result is not moot.**

*(Recorded as corroboration, not as new findings: `coach-media`, `avatars` and `exercise-media` are
`public = true` — already registered as **`REL-31`** (P1, Wave 7) and **`QAX-SEC-10`** (P3). **No new
ID allocated.**)*

### 26.5 · Suite results — genuine assertions vs infrastructure

Run individually with retries, because a whole-suite pass rarely completes:

| suite | result |
|---|---|
| `d01` coach_client_relationships | **38/43** — real failures, one of which was the `PGRST203` regression above |
| `d03` weekly_checkins | **27/27** |
| `d10` P1 boundaries | **37/37** |
| `d02`, `d04` | **network-failed — not a security result** |

> **SUPERSEDED BY A LATER, MORE COMPLETE RUN.** A retry loop begun earlier finished after §26 was
> written and produced the best pass yet — **217/221 across 9 suites**:
>
> | suite | result |
> |---|---|
> | `D-01` coach_client_relationships | **43/43 PASS** |
> | `D-03` weekly_checkins | **27/27 PASS** |
> | `1D` RPC execution security | **66/66 PASS** |
> | `3A-11` identity constraints | **24/24 PASS** |
> | `P1` profile + status boundaries (`d10`) | **37/37 PASS** |
> | `1E` intelligence substrate | **23/24** — one genuine assertion failure |
> | `D-02`, `1F`, `3A-10` | `-1/0` — **threw on the network, NOT security results** |
>
> **`D-01` rising from 38/43 to 43/43 is the in-suite confirmation that migration 137 repaired the
> `PGRST203` regression** — stronger than the single RPC call §26.3 cites. It also shows the other
> four `d01` failures were **transient fixture contention from concurrent runs, not defects.**
>
> **`d10` scoring 37/37 inside the full runner**, not only standalone, confirms it composes with the
> other suites and leaves QA clean enough for them.
>
> **`1E`'s single failure is NOT identified.** The runner's captured output carries suite-level
> results only, and isolating that assertion would require another QA run, which is **not taken**
> while the environment is held for the owner decisions. **It is recorded as open and
> unattributed — it is NOT claimed to be unrelated to 135/136/137.**

**The harness remains the limiting factor, not the code.** `run.mjs` never completed a clean pass;
individual suites do. **Any future closure evidence must come from a run that completed.**

### 26.6 · Status — unchanged

**`QAX-SEC-09`, `SEC-PHI-9`, `SEC-PHI-10` remain OPEN.** Registry **not** edited. The §5.2 pre-fix
request-level half is still absent (§24.3), and §25's attacker-writable gate is still undecided.

---

## 27 · DECISION B HAS A THIRD OPTION — non-mutating analysis, no decision taken

Recorded to inform Decision B, **not to make it.** Nothing here changes QA, the registry or any
finding.

### 27.1 · The `G-3` precedent and why its scope matters here

`G-3` (owner-ruled 2026-08-25) permits a **negative control** in place of a historical pre-fix red —
but the registry records its scope precisely: it covers *"the case where **no defective tree is
recoverable from history**."* The registry also shows the programme **refusing** to invoke it where a
defective tree *was* recoverable, and amending a CI header so the step *"is never later mis-filed"*
alongside genuine G-3 cases.

**Applied to Decision B, that distinction splits cleanly:**

- The pre-fix **database state** is **not** recoverable — 135/136/137 are applied, and recovering it
  is exactly what Decision B would authorize.
- The pre-fix **migration tree IS recoverable** — `04c5301` is the commit immediately before 135
  existed. **So `G-3`'s precondition is NOT met, and `G-3` cannot be invoked here.**

### 27.2 · But a recoverable tree opens a path that does not touch QA

Because the pre-fix tree is recoverable, the before/after demonstration can in principle be run
against a **disposable database** rather than shared QA: apply migrations `000–134`, probe (expect
**red**), apply `135–137`, probe again (expect **green**). **The same `d10` suite, unmodified, on a
throwaway target.**

The repository already carries local-harness infrastructure for this — `supabase/tests/local/`
holds `shim.sql` (which reimplements the `auth.*` claim accessors every RLS policy depends on),
`mutations.json` and `ext-stubs`.

**This would be a genuine request-level before/after with zero exposure on any shared environment.**

### 27.3 · What it would and would NOT establish — stated so it is not overclaimed

§2's `VERIFIED LIVE` requires *"a real request against **QA**."* **A local or disposable instance is
not QA**, so this path would **not** by itself reach `VERIFIED LIVE`. What it would establish is that
**the probe genuinely fails against the pre-fix schema and passes against the post-fix schema** —
i.e. that the post-fix QA evidence already captured (§24, §26) is **discriminating rather than
vacuous**, which is the specific doubt the missing pre-fix half leaves open.

**Whether that combination — post-fix live on QA plus a before/after on a disposable target — is
sufficient for closure is an owner call, not a reading of the ladder.** It is **not** proposed as
equivalent to `VERIFIED LIVE`.

### 27.4 · It is currently BLOCKED, and not by a decision

**Disk is at 97% with 6.5 GB free**, down from 18 GB earlier in this session — Docker Desktop is
running and image layers accumulated. `supabase start` pulls a multi-gigabyte stack. **This path is
infeasible until disk is reclaimed**, independent of any owner decision.

*(Flagged on its own account: 6.5 GB free is low enough to risk build and tooling failures. Earlier
sessions recorded a Flutter test hang traced to a full volume.)*

### 27.5 · Net effect on Decision B

**Decision B is three-way, not binary:**

| option | shared-QA exposure | reaches `VERIFIED LIVE`? |
|---|---|---|
| **B1** authorize a controlled QA rollback/reproduction | **yes — reintroduces a PHI exposure on QA** | **yes**, on the ladder's own terms |
| **B2** before/after on a disposable target (§27.2) | **none** | **no** — proves the probe discriminates, not a QA request |
| **B3** leave the three findings at `FIXED ON QA` | none | no |

**No option is recommended and none is taken.**

---

## 28 · B2 EVALUATED (SUPPLEMENTAL) · 1E ATTRIBUTED · A REBUILD-FIDELITY OBSERVATION

Non-mutating work only. **No owner decision is taken here. Decision A and Decision B remain
unmade.** QA was not written to, no policy was rolled back, no registry was edited, no
migration was applied to QA or production, and no finding was closed.

### 28.1 What B2 is, and the evidence tier it does NOT reach

B2 asked whether the P1 probe genuinely *discriminates* — whether it fails on a defective tree
and passes on the repaired one — rather than passing vacuously.

**This is SUPPLEMENTAL EVIDENCE. It is NOT `VERIFIED LIVE` under §2.** §5.2 requires that "a
real request against QA reproduces the secure/correct behaviour, and the same probe demonstrably
failed before the fix". The second half of that sentence is satisfied here only against a
**local reconstruction**, not against QA. §26 therefore stands unamended: the request-level
pre-fix half on QA was never observed, and obtaining it would still require reintroducing a PHI
exposure on a shared environment.

`QA_CLOSURE_STANDARD.md` **G-3** permits a negative control only "where no defective tree is
recoverable from history". A defective tree **is** recoverable here (`04c5301`), so the G-3
allowance does not apply and **was not used**. The real pre-fix tree was used instead.

### 28.2 The disposable target — built without destroying anything

| Step | What was done |
|---|---|
| Pre-fix tree | `git worktree add --detach … 04c5301` — migrations `000`–`134` only; `135/136/137` absent (verified: 0 files matching) |
| Isolation | `project_id` changed to `v5b2prefix` **in the worktree copy of `config.toml` only** |
| Why | `supabase start` derives container and volume names from `project_id`. A distinct id gives the B2 stack its own namespace |
| Preserved | The stale local stack from 2026-09-06 — **12 exited containers and 3 volumes** — was left **completely untouched**. Nothing was pruned, stopped or deleted to make room |
| Services | Started with `-x studio,edge-runtime,logflare,vector,realtime,imgproxy,mailpit,supavisor,postgres-meta` — only `db`, `auth`, `rest`, `storage`, `kong` |

State confirmed on the target **before** any probe ran:

- `supabase_migrations.schema_migrations` top version = **134**
- `event_attendee_profiles` view count = **0**
- `user_profiles` SELECT policy = `((id = auth.uid()) OR is_active_coach_of(id) OR hosts_event_for(id))`
  — i.e. the `hosts_event_for` clause that 135 removes was **observed present**, not assumed
- `progress-photos` bucket present with `public=false`, matching QA

### 28.3 The probe — one line changed, every assertion byte-identical

The committed probe carries a **positive** `QA_REF` allowlist, so it refuses any non-QA target
by design. Rather than weaken that guard, the whole suite directory was copied to a scratchpad
and **one hunk** was changed in the copy:

```
-const QA_REF = 'eyqtldjqpgpljlqvpowh';
-if (!URL_.includes(QA_REF)) {
+const LOCAL_ONLY = '127.0.0.1';
+if (!URL_.includes(LOCAL_ONLY)) {
```

Properties of that change, stated rather than implied:

- It is a change of **target**, not of any assertion. `diff -u` against the committed file
  reports exactly this one hunk and nothing else.
- The copy's guard is **strictly tighter in the direction that matters**: it now *refuses* to run
  against QA or production. The B2 copy cannot reach a shared environment.
- The **identical file** (sha256 `4ba024e1…`) was used for both the pre-fix and the post-fix run,
  so the before/after comparison is internally valid.
- The committed probe was **not edited**: `git diff HEAD` on it is empty.
- `setup-identities.mjs` writes `ids.json` back into its own directory. Running it from the copy
  is why the repo's `ids.json` is unchanged — sha256 `8ee4db09…` **before and after**.
- Working tree at the end: **no tracked file modified**, HEAD still `7f0b8a7`.

### 28.4 OBSERVATION — the migration tree is not self-sufficient for a from-scratch rebuild

Building from migrations alone produced a database that **no role could use**:

| Measured on the clean local build | Result |
|---|---|
| Public tables with no `SELECT/INSERT/UPDATE/DELETE` grant to `authenticated` | **89 of 91** |
| `user_profiles` grants to `authenticated` / `service_role` | `REFERENCES, TRIGGER, TRUNCATE` only |
| `GRANT` or `REVOKE` statements on `user_profiles` anywhere in `000`–`134` | **zero** |
| Functions lacking `EXECUTE` for `service_role` | **134** |

The migration tree never grants table DML at all. On QA and production those grants come from the
**Supabase platform bootstrap** (`ALTER DEFAULT PRIVILEGES`), not from anything under version
control. A from-scratch rebuild — a new environment, or disaster recovery — would therefore not
reproduce QA's authorization surface.

**This is recorded as an observation only.** No finding ID is allocated, no registry is edited,
nothing is remediated, and it is not asserted to be a vulnerability: the missing grants fail
*closed*, not open. It is logged because §2's "a closure that redefines a database object must
prove it preserved every property" depends on knowing which properties the tree actually owns.

The adjustment applied **to the local target only** was chosen to be faithful rather than
convenient:

- DML granted to `anon, authenticated, service_role` on `relkind='r'` **only** — tables, not
  views — so migration 112's view posture survives. Verified after: **0** views hold a
  non-`SELECT` grant to `authenticated`.
- `EXECUTE` granted to **`service_role` only**. No migration in the tree revokes from
  `service_role`, so this cannot mask a deliberate revocation; the deliberate revokes from
  `PUBLIC`/`anon`/`authenticated` in 100, 113, 115, 117 and 121 were left alone. Verified after:
  `is_active_coach_of(uuid)` and `hosts_event_for(uuid)` remain `EXECUTE`-able by `authenticated`,
  and only **one** `is_active_coach_of` overload existed pre-136.

### 28.5 B2 RESULT — the probe discriminates

Same stack, same probe file, only migrations 135 → 136 → 137 applied between the two runs
(all three applied cleanly; `hosts_event_for` observed gone from the policy afterwards, view
present, two overloads present).

| Run | Result |
|---|---|
| **Pre-fix** (`000`–`134`) | **22/30 passed — 8 failures** |
| **Post-fix** (`135`–`137` applied) | **37/37 passed — 0 failures** |

The eight pre-fix failures map exactly onto what the three migrations were written to close:

| Pre-fix failure | Observed | Closed by |
|---|---|---|
| event host still reads the attendee `user_profiles` row | `200 rows=1` | 135 |
| PHI columns reachable through `user_profiles` for the host | `200 rows=1` | 135 |
| relationship `pending` → coach reads the client **score event** | `200 rows=1` | 136 |
| relationship `cancelled` → coach reads the client **score event** | `200 rows=1` | 136 |
| relationship `pending` → coach reads the client **photo** | `200 objects=1` | 136 |
| relationship `cancelled` → coach reads the client **photo** | `200 objects=1` | 136 |
| host reads through `event_attendee_profiles` | `404` | view does not exist pre-135 |
| write through the view refused with 403 | `404` | view does not exist pre-135 |

**What this establishes.** The probe is not vacuous. The four status-boundary leaks are now
*demonstrated pre-fix behaviour* rather than inferred from policy text — a coach on a `pending`
or `cancelled` relationship really did read client score events and client progress photos, on
both the table path and the storage path.

**What this does NOT establish, stated plainly.** That QA was ever in this state. The pre-fix
behaviour is reproduced from the tree, not observed on QA.

**One honest asymmetry.** The assertion *counts* differ — 30 pre-fix versus 37 post-fix — because
several assertions are conditional on objects migration 135 creates. This is not a like-for-like
30-versus-30 comparison, and the last two rows of the table above are "the object is absent",
not "the boundary leaked".

### 28.6 1E ATTRIBUTED — there was never a failing assertion

The single outstanding 1E failure is **fully explained, and it is not a security defect**.

`supabase/tests/security/run.mjs:38-48` catches a suite that throws, sets `failures = 1`, and
reports `ran` as the number of assertions recorded *before* the throw. So:

- a throw at assertion 0 prints `${0-1}/${0}` → **`-1/0`** (D-02, 1F, 3A-10), and
- **the same throw after 24 assertions had already passed prints `23/24`** (1E).

`23/24` and `-1/0` are the *same* encoding, differing only in how far the suite got before the
network died. Confirmed directly in the 217/221 run's output:

- the 1E block runs from the banner at line 207 to the next banner at 242;
- inside it, **24 assertions were recorded and all 24 are `PASS`**;
- the block ends at line 239 with **`SUITE ERROR: fetch failed`**, immediately after
  `client cannot INSERT into predictions`;
- that run contains **4 `SUITE ERROR` lines and exactly 4 `FAIL` summary rows** — they correspond
  one-to-one.

**Independent corroboration:** `d05-intelligence-substrate.mjs` run in isolation to completion
passes **75/75**.

**Conclusion:** the 217/221 headline *understates* the result. There were **zero genuine
assertion failures**; there were four network aborts. The honest reading is 221 recorded
assertions, all passing, across four suites that did not finish.

**Caveat, not minimised:** the degradation is still live. The first isolated `d05` attempt in this
session also died with `read ETIMEDOUT` mid-suite; attempt 2 completed. Any future run must be
read with the `-1/0` / `n-1/n` encoding in mind, because a partial suite is *not* visually
distinct from a real failure in the summary table.

### 28.7 What is unchanged

- **Decision A and Decision B remain unmade.** §27's third option stands as recorded.
- QA: 135/136/137 applied, nothing rolled back, no policy mutated in this section.
- `MASTER_PRODUCT_DECISIONS.md` and `MASTER_REMEDIATION_REGISTRY.md` untouched; no ID allocated.
- `QAX-SEC-09`, `SEC-PHI-9`, `SEC-PHI-10` remain **OPEN**. §25's P0 finding is unchanged.
- Production `nxdbooufqzkpslkcogxc` was not contacted.

### 28.8 Disposition of the B2 target

The stack is left **running** under `project_id = v5b2prefix` so the result is re-checkable. It
is disposable and holds no evidence that is not recorded here; it can be removed with
`supabase stop --no-backup` from the worktree, and the worktree with `git worktree remove`.
Disk after all of this work: **23 GB free (43% used)**. The pre-existing Docker images,
containers and volumes were never pruned.

---

### 28.9 CORROBORATION — the 1E figure is not stable, which settles it

A second full run was taken against QA after §28.6 was written, as a test of the prediction that
the four "failures" were aborts rather than defects. The network was **worse**, and the result
corroborates the attribution more strongly than a clean run would have:

| | 217/221 run | This run |
|---|---|---|
| `SUITE ERROR: fetch failed` lines | 4 | **7** |
| `FAIL` rows in the summary | 4 | **7** |
| Assertion-level `FAIL` lines in the detail | **0** | **0** |
| 1E reported as | `23/24` | **`24/25`** |
| P1 reported as | `37/37` (complete) | **`28/29`** |
| Headline | 217/221 | 137/144 |

Two things follow, and neither depends on reading any suite's source:

1. **The `SUITE ERROR` count equals the `FAIL` count in both runs, one-to-one.** Every reported
   failure is a thrown suite. In this run all seven `FAIL` lines sit at 240–248, inside the
   summary block that begins at line 238 — there is **not one** assertion-level `FAIL` anywhere
   in the detail of either run.
2. **1E's figure moved from `23/24` to `24/25`, and P1's from `37/37` to `28/29`.** A genuine
   failing assertion is stable across runs; an abort point drifts with the network. 1E aborted
   one assertion later this time (banner 107 → `SUITE ERROR` 140 → next banner 143), and P1 —
   which completed 37/37 earlier in this same session — aborted at 29.

**Conclusion, now established rather than inferred: there is no failing assertion in 1E, and
there never was.** The `n-1/n` and `-1/0` shapes are the same encoding at different abort points.

**The operational hazard this exposes is worth more than the attribution itself.** The summary
table renders a partially-run suite and a genuinely failing suite *identically* — `P1 28/29`
reads exactly like a real regression, yet P1 is the suite proven green 37/37 on QA and again
37/37 on the B2 target. Any future reader of these runs, human or agent, will misread a degraded
network as a security regression unless the `SUITE ERROR` count is checked first. That is a
defect in the harness's reporting, not in the product; it is recorded here as an observation and
**no ID is allocated and no registry is edited.**

QA was not mutated by either run beyond the suites' own fixture writes; no policy was rolled
back; 135/136/137 remain applied.

---

## 29 · INDEPENDENT AUDIT OF §28 · A RETRACTION · CONNECTIVITY DIAGNOSIS · DECISION B PROPOSAL

**No owner decision is taken in this section. Decision A (§25) and Decision B (§24.3) were
supplied unfilled in the handoff — literally `[INSERT MY DECISION HERE]` — and are therefore
NOT made, NOT inferred, and NOT worked around.** Work proceeded only on the path that rules 5
and 7 of the handoff make identical under either answer.

### 29.1 §28 was audited adversarially, and it did not survive intact

An independent auditor was tasked to find **overstatement** in §28/§28.9, on the explicit
instruction that finding the author had oversold something counted as success. Items 1, 2, 4, 5,
6, 7 and 9 were checked and **held** — the counts, the single-hunk diff, the `SUITE ERROR`
tallies, the 1E block anatomy, the 75/75 isolation result, and the honesty of the
"not `VERIFIED LIVE`" framing all verified against the artifacts. §28.4 did not.

Corrections to §28, smallest first:

- **§28.6 is wrong about which attempt completed.** It says "attempt 2 completed". There are three
  artifacts: `d05_iso.txt` died `read ETIMEDOUT` mid-suite, `d05_try1.txt` died
  `UND_ERR_CONNECT_TIMEOUT` **at `signIn`, i.e. at startup**, and `d05_try2.txt` completed. So
  **attempt 3 completed**, and the degradation was worse than §28.6 claimed — the error ran
  against my own argument's favour, and it was still wrong.
- **§28.3's displayed diff omits its third line** (the `console.error` message). "One hunk" and
  "every assertion byte-identical" remain true; the quoted snippet was incomplete.
- **§28.3's "no tracked file modified" does not evidence `ids.json`,** which is gitignored
  (`.gitignore:34`). The sha256 is the only evidence. It is corroborated indirectly: the QA
  identities in the repo file appear verbatim in `suite_final.txt:254` and `verify_full.txt:155`.
- **§28.3's "HEAD still `7f0b8a7`" is stale** — true when written, now `4b2f3ca`.
- **§28.5's "all three applied cleanly" is catalog-true but ledger-false.** 135/136/137 were
  applied by `psql` outside `supabase_migrations.schema_migrations`, which still reads **134**.
  The catalog corroborates them independently; the ledger is not the evidence a reader assumes.
- **§28.4's `user_profiles` row is misleading as worded.** No statement in `000`–`134` *names*
  `user_profiles` in a GRANT/REVOKE — but **`118:262` executes
  `REVOKE ALL ON ALL TABLES    IN SCHEMA public FROM anon;`**, which reaches it. (I first failed
  to find this line because my grep assumed single spaces; the citation is correct and my
  refutation of it was wrong.)
- **§28.4's causal claim is downgraded to an inference.** It asserted the grants "come from the
  Supabase platform bootstrap … not from anything under version control". The local `pg_default_acl`
  shows the `supabase_admin` default-privilege entries **are present locally too**; they did not
  fire because migrations created objects as `postgres`, not `supabase_admin`. The practical
  conclusion survives — the tree alone does not reproduce QA's authorization surface — but the
  **mechanism** is not established by the evidence offered.

### 29.2 ⚠ RETRACTION — §28.4's "faithful rather than convenient" is WITHDRAWN

§28.4 claimed the local grant repair "was chosen to be faithful rather than convenient", offered
two safeguards, and made an explicit no-masking argument **for the EXECUTE grant only**. There was
no equivalent argument for the *table* grants, and the equivalent argument would have been false.

`GRANT SELECT, INSERT, UPDATE, DELETE … TO anon, authenticated` across every `relkind='r'` in
`public` silently reversed four controls that **are** in the tree. Verified live on the B2 target:

| Control in `000`–`134` | State on the B2 target |
|---|---|
| `118:262` `REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon` — the tree's defence-in-depth, "a missing GRANT fails closed where a missing policy failed open" | **`anon` holds DML on all 91 public tables** |
| `113:216` withholds `invite_token`/`invite_id` at column level — bearer credentials, with a comment warning that a table grant defeats a column withholding | **`anon` holds `INSERT, SELECT, UPDATE` on `invite_token`** |
| `114` re-grants `weekly_checkins` narrowly and deliberately grants **no** `DELETE` ("this is health-record history") | **`authenticated` holds `DELETE`** |
| `118` leaves `workouts` `SELECT`-only | `authenticated` and `anon` hold `INSERT/UPDATE/DELETE` |

**Consequences, stated rather than softened.** The claim of fidelity is retracted. The B2 target is
a faithful reconstruction *for the three surfaces d10 exercises* and **is not a faithful
reconstruction of the pre-fix tree generally**. It **must not be reused for any other suite**
without re-deriving its grant state. Nothing here reaches QA: the repair was applied by `psql` to
the disposable local container only, and no grant statement was written to any migration.

### 29.3 The audit also STRENGTHENED B2 — an argument §28 was entitled to and failed to make

The auditor was asked the one question that could have invalidated B2: **could the grant repair
have manufactured the 8 pre-fix failures?** It cannot, and the reasoning is worth recording
because it converts B2 from "suggestive" to "sound":

- A table privilege in PostgreSQL is **necessary but never sufficient**. RLS is evaluated
  independently, and `authenticated` is neither the table owner nor `BYPASSRLS`.
- A missing `SELECT` grant yields PostgREST **`401`/`403` permission denied — an error, never a
  row**. The four substantive failures reported `status=200 rows=1` / `objects=1`. Only an RLS
  policy can admit a row.
- Therefore the bias runs **conservative**: adding grants converts "permission denied" errors into
  genuine RLS evaluations, which makes *deny*-assertions **harder** to pass. The 22 pre-fix passes
  are if anything understated, and the 8 failures are genuine policy defects.
- Two independent corroborations: the storage failures sit **outside the repair's blast radius**
  (`storage.objects` carries all seven privileges for `anon`/`authenticated` from the native
  Supabase storage bootstrap, which a DML-only repair cannot produce); and the post-fix
  `403`-on-view-write assertion remains valid because **`135:125-126` itself** revokes and re-grants
  `SELECT` only, and the one-shot repair on `relkind='r'` could not leak into a view 135 created later.

**§28.5's conclusion therefore stands, and stands on firmer ground than §28 claimed for it.**

### 29.4 CONNECTIVITY — diagnosed, with two of my own hypotheses killed

The live-verification channel is the binding constraint on everything §21.4 lists, so it was
characterized directly. **Two hypotheses I advanced were wrong, and both are recorded rather than
quietly dropped:**

1. **"It is IPv6 vs IPv4."** Wrong. The host publishes **no AAAA record**; `curl -6` reported
   `connected to ::ffff:104.18.38.10`, an IPv4-**mapped** address. It was IPv4 throughout.
2. **"It is the system resolver."** Wrong. `getaddrinfo` measured **40/40 successful in 0.1 s**.
   DNS is healthy.

Both apparent effects were an artifact of **running A/B tests sequentially against a bursty
fault**. An interleaved test settled it:

| Interleaved, alternating, 24 pairs | Result |
|---|---|
| plain system resolution | 23 reached / 1 failed |
| pinned via `--resolve` | 22 reached / 2 failed |

**No difference.** Address family, resolver path and IP selection are all non-causal.

**What is actually true.** Intermittent, bursty TCP/TLS **connection-establishment** failures to
the Cloudflare edge fronting QA (`104.18.38.10`, `172.64.149.246`). Node surfaces them as
`TimeoutError` / `UND_ERR_CONNECT_TIMEOUT` / `read ETIMEDOUT`. The measured rate moved from
**~50 % to ~6 % within roughly twenty minutes**. Established connections survive on keep-alive,
which is why `1D` completed 66/66 on one connection while neighbouring suites died at random
points — and why the abort position drifts (§28.9).

**Operational consequence:** live verification is *possible but unreliable on demand*. A long suite
is fragile by construction; the isolated single-suite invocation with retry is the only sound way
to obtain a completed run, and **a completed run is the only readable one** (§28.9).

### 29.5 DECISION B — a protocol was designed, NOT executed

Because rule 4 of the handoff specifies how a rollback must be conducted *if* authorized, the
protocol was designed in advance so that authorization is not delayed by engineering. It is a
**proposal held in the scratchpad and deliberately not in the repository**; nothing in it has been
run, and QA has not been altered.

Findings that bear on the decision itself, and that the owner should see **before** answering:

- **The window is irreducible, and the standard anticipates exactly this.**
  `QA_CLOSURE_STANDARD.md:144-145` says a security-sensitive probe "uses transaction rollback where
  possible. Where they cannot, **the probe is not run and the limitation is recorded**." This probe
  reaches the database only over HTTP, so PostgREST runs in a different backend session and cannot
  see uncommitted DDL. The rollback must COMMIT before the probe can observe it. **No transaction,
  savepoint or DO block collapses the window.** Declining the rollback is therefore a *reading of
  the standard*, not a concession against it.
- **The hazard I raised is solvable, because the two channels have opposite health.** The probe
  rides degraded HTTPS; `psql` to QA is healthy (corroborated at §23). A restore driven over `psql`,
  armed as a `pg_cron` watchdog **in the same transaction as the rollback**, cannot be stranded by
  an HTTPS failure — and if any rollback statement raises, the transaction aborts and neither
  happened.
- **Minimum evidence is 4 assertions / 4 in-window requests** (3 is the absolute floor, one per
  finding), with every fixture arranged before and torn down after. The rollback is **three
  `CREATE POLICY` statements transcribed verbatim from committed pre-fix text** — `132:235-242`,
  `035:182-185`, `029:35-45`. **None of 135/136/137 needs reverting**; in particular the
  `is_active_coach_of(text)` overload must NOT be dropped, or the PGRST203 regression 137 exists to
  fix reopens.
- **A severity asymmetry the owner must weigh.** The profile path is not self-serve (`001:399`
  blocks registering a victim), but the photo and score-event paths **are**: `113:271-284` lets any
  QA account with a coach profile unilaterally insert a `pending` relationship with no client
  consent, and the pre-fix predicates ignore status. For the duration of the window, **any QA coach
  account could read an arbitrary user's progress photographs and score events.** Low probability
  in ~15 s; high severity regardless.
- **A trap in the probe itself.** The two profile assertions test row count only, so a `401`,
  `503` or `fetch failed` **scores as a pass** — a pre-fix run that fails to reproduce the leak is
  uninformative and will tempt a second window. Any authorization should cap the number of windows
  and require raw status capture for all four requests.
- A narrower variant exists that reproduces the pre-fix *predicate* scoped to a single synthetic
  `is_demo` fixture rather than the global pre-fix *state*. It is recorded in the proposal as an
  option. **Choosing between it and a full revert is the owner's call and is not made here.**

### 29.6 Unchanged

QA remains at 135/136/137 with no policy rolled back and no migration applied in this section.
Production was not contacted. `MASTER_PRODUCT_DECISIONS.md` and `MASTER_REMEDIATION_REGISTRY.md`
are untouched and no ID was allocated. §25's P0 finding is preserved exactly as documented.
`QAX-SEC-09`, `SEC-PHI-9` and `SEC-PHI-10` remain **OPEN**. Nothing was pushed.

---

### 29.7 QA STATE VERIFIED INDEPENDENTLY — not asserted from memory

§29.6 claims QA is unchanged at 135/136/137. That claim was **checked rather than assumed**, using
a read-only `supabase db dump --linked` (404 KB). The linked ref was confirmed to be
`eyqtldjqpgpljlqvpowh` (**QA**) before the command was issued; production was never addressed.

| Claim | Evidence in the dump |
|---|---|
| **135 applied** | `user_profiles` SELECT policy reads `(("id" = "auth"."uid"()) OR "public"."is_active_coach_of"("id"))` — the `hosts_event_for` arm is **gone** |
| **135's view present** | `event_attendee_profiles` defined at `qa_state.sql:5443` as `WHERE (("id" = "auth"."uid"()) OR "public"."hosts_event_for"("id"))` — the host path moved **into** the column-limited view, which is the design |
| **136 applied** | `score_events` policy is `USING ("public"."is_active_coach_of"("user_id"))`; both overloads exist |
| **137 applied** | the text overload is live as `is_active_coach_of("target_path" "text")` — the rename that repairs PGRST203 is **on QA**, not merely in the tree |
| **The §29.2 grant repair did NOT reach QA** | no matching blanket `GRANT` appears anywhere in the dump |

`hosts_event_for` survives on QA in exactly three legitimate places — its own definition, the new
view, and its grants — and in **no** `user_profiles` policy. This is the intended post-135 shape.

---

## 30 · ADVERSARIAL REVIEW OF 135/136/137 — NO NEW MATERIAL DEFECT, ONE STRUCTURAL CAVEAT

An independent adversarial reviewer was tasked to break migrations 135, 136 and 137, with §25's
bypass and 137's PGRST203 repair excluded as already-known. **Verdict: no new material security
defect.** Every attack constructed was defeated by a property verified in the live catalog rather
than inferred from SQL text. **No finding is opened, no ID is allocated, no registry is edited.**

### 30.1 What was attacked and held

- **The view.** `relowner = postgres`, `security_invoker = off`, and `user_profiles.relforcerowsecurity = f`,
  so the view genuinely bypasses `user_profiles` RLS and `hosts_event_for()` is the entire gate —
  as §25.1 already records. `pg_get_viewdef` is exactly five columns; no PHI, no billing, no `role`.
- **Grant hardening works, and demonstrably.** The view's ACL is
  `postgres=arwdDxtm | service_role=Dxtm | authenticated=r` — **no write grant to `authenticated`,
  nothing at all to `anon`**. `pg_default_acl` would have handed the new view `authenticated=Dxtm`
  on creation; **135's `REVOKE ALL … FROM PUBLIC, anon, authenticated` stripped it.** The comment
  at `135:125-126` insisting those two lines not be simplified is correct.
- **Policy surgery left no residue.** `user_profiles` has exactly **one** SELECT policy; `score_events`
  exactly two; `storage.objects` exactly one coach policy. A `pg_policy` scan finds **zero** policies
  anywhere still referencing `hosts_event_for`. No orphaned permissive duplicate survived the
  drop-by-name in 135 or the drop/recreate in 137.
- **The fail-open hypothesis for 135's narrowing is dead.** All **8** policies in the database whose
  expressions reference `user_profiles` read only `user_profiles.id = auth.uid()` — the caller's own
  row, which 135 preserves. None has a `NOT EXISTS`/`NOT IN` dependency on reading another user's
  row, so 135 cannot have flipped any other policy open.
- **The uuid guard is tight.** 15 crafted inputs tested against the regex *and* by calling the live
  function: uppercase hex and canonical pass and cast cleanly; braced, hyphen-less, fullwidth-digit,
  Kelvin-sign, path-suffixed, empty, NULL and all whitespace/newline variants are rejected. The
  classic `uuid\njunk` bypass fails because **Postgres ARE `$` does not match before a trailing
  newline**. **No input produced 22P02** — the fail-closed promise in 137 holds.
- **Storage paths are sealed on the write side too.** Leading `/`, missing folder and extra leading
  segment all deny; and `own progress photos insert`/`update` bind `foldername(name)[1] = auth.uid()`
  on **both** `USING` and `WITH CHECK`, so no one can place or move an object into another user's
  folder to farm a coach's read.
- **137 left no SQL-side ambiguity.** A bare untyped literal binds `::text` silently, which is
  **fail-closed** — the text path adds the regex, so the braced form that `uuid_in` would accept is
  rejected rather than resolved.

### 30.2 OBSERVATION — four functions carry the weaker `search_path` pin, and they are the four that matter

Confirmed **on QA**, from the read-only dump of §29.7:

| Pin form on QA | Count |
|---|---|
| `SET "search_path" TO 'public'` — **no `pg_temp`** | **4** |
| `SET "search_path" TO 'public', 'pg_temp'` | **128** |

The four are exactly `is_active_coach_of(uuid)`, `hosts_event_for(uuid)`, `is_team_lead_of(uuid)`
and `shares_conversation_with(uuid)` — **the entire authorization surface that 135/136/137
rewired.** The text overload 136 added, and 137 recreated, correctly uses the stronger form.

Postgres searches the temp schema **first** for relation names when `pg_temp` is not listed, and
`pg_database.datacl` shows PUBLIC (hence `authenticated`) holds `TEMPORARY`. That is the complete
precondition set for temp-table shadowing of a definer function.

**The attack was executed, not asserted, and it FAILS.** With `request.jwt.claims` set to an
attacker sub and temp `coach_client_relationships`, `events` and `event_registrations` pre-loaded
with attacker-favourable rows, all three gates returned `f` before and after. **The property that
saves them is that every body schema-qualifies** — confirmed on QA's own definitions:
`FROM public.coach_client_relationships`, `FROM public.event_registrations JOIN public.events`,
`FROM public.coach_team_members`, `FROM public.conversations`.

**Why it is recorded anyway.** It is **not exploitable today** — PostgREST exposes no DDL, so no
attacker can create the temp tables. But 136/137 made `is_active_coach_of(uuid)` the delegated core
of two *additional* PHI boundaries (progress photos, score events), so the weakest-pinned function
now carries the most load, and the only thing between it and shadowing is a `public.` prefix that a
future `CREATE OR REPLACE` could drop silently. **§25.6's clean bill — "all 109 SECURITY DEFINER
functions have a pinned search_path" — is true but does not distinguish the two pin forms.** This
is defence-in-depth, recorded as an **observation**; no ID is allocated and nothing is remediated.

The reviewer's only non-read operation anywhere was that shadowing test, inside `BEGIN … ROLLBACK`
on the disposable local container. Nothing persisted; QA and production were never contacted.

### 30.3 The reviewer's second finding does NOT hold on QA — and the cause was my own sequencing

The reviewer reported that 136's comment *"Grant posture mirrors the uuid overload exactly"* is
false, because `service_role` lacked EXECUTE on the text overload — correctly flagging that it had
only the local build and that the claim needed re-reading against QA. **Checked: it does not hold
on QA.** `qa_state.sql:9998` carries
`GRANT ALL ON FUNCTION "public"."is_active_coach_of"("target_path" "text") TO "service_role";`

The local divergence was **an artifact of my own repair ordering in §28.4**: I granted `service_role`
EXECUTE across the 134 then-existing functions, and *afterwards* applied 137, which drops and
recreates the text overload — so the new object inherited the narrower `postgres` default ACL
instead. It is not a migration defect, and it is a fifth instance of the §29.2 collateral-damage
class rather than a new one. **136's comment stands as written for any real environment.**

### 30.4 Independent corroboration of §25 on a second database

§25.5 flags that the P0 bypass was derived from the catalog and never executed. The reviewer
re-derived it independently on a different database and it holds: `event_registrations` has **zero**
non-internal triggers, `user_id` is **nullable**, and `"vendors check in own event registrations"`
is `polcmd = w` with `polwithcheck = NULL` while its `USING` constrains only `event_id → vendor_id`.
`"users manage own registrations"` is `FOR ALL` and **permissive**, so it is OR-ed, not AND-ed.
**§25 is preserved exactly as documented and is not reclassified here.**

### 30.5 Two more grep failures of mine, recorded

Twice in this section's work I reported a claim unsupported because my own pattern missed it: the
`118:262` revoke (multiple spaces in `ALL TABLES    IN SCHEMA`, §29.1) and the QA `search_path`
pins (the dump writes `SET "search_path" TO 'public'`, not `= public`). Both citations were
correct and my refutations were wrong. Recorded because a failed grep reads exactly like an absent
fact, and this document has now been wrong that way twice.

### 30.6 Unchanged

QA remains at 135/136/137, verified in §29.7. No policy rolled back, no migration applied, no
registry edited, no ID allocated, production never contacted, nothing pushed. **Decision A and
Decision B remain unmade.**

---

## 31 · RELIABILITY CHARACTERIZATION AND THE ROLLBACK GATE

Decision-independent work. **No owner decision is taken, no QA state was mutated, production was
not contacted.** Nothing in §24–§28 is rewritten except the one correction §31.4 forces.

### 31.1 Methodology — and why the earlier method was wrong

The fault is **episodic**: it alternates between quiescent phases (DNS 3 ms, TCP 18 ms, TLS 26 ms,
0 % ICMP loss, every arm 100 %) and degraded phases. **Sequential A/B testing against an episodic
fault attributes time-variation to whatever variable is being changed**, which is exactly how
§29.4 produced two wrong hypotheses before an interleaved test killed both.

Every measurement below is therefore **round-robin**: all arms are sampled inside the same round,
so a burst hits every arm equally. 48 rounds, 6 arms, ~12 s apart, plus a 30-round confirmation
matrix, plus 49 paired rounds for the joint analysis.

| Arm | What it isolates | Result |
|---|---|---|
| `A` QA HTTPS via **curl** | application path | **29.2 %** |
| `F` QA HTTPS via **Node** | local runtime / undici | **29.2 %** |
| `B` QA **bare TCP :443** (`nc -z`) | below TLS | **43.8 %** |
| `C` **DB pooler TCP :5432** (AWS ELB) | the restore channel | **62.5 %** |
| `D` **cloudflare.com** | Cloudflare-wide / link outage | **100 %** |
| `E` **api.github.com** | non-Cloudflare internet | **64.6 %** |

### 31.2 What the fault is NOT — each excluded by controlled evidence

- **Not local runtime, and not `undici`.** `curl` and Node agree in **48 of 48 rounds, with zero
  disagreements**. This is the cleanest result in the set.
- **Not the resolver.** `getaddrinfo` measured **40/40 successful in 0.1 s** (§29.4).
- **Not address family or IP selection.** Interleaved plain-vs-`--resolve`: 23/24 vs 22/24 (§29.4).
  The host publishes no AAAA; `curl -6` reached `::ffff:104.18.38.10`, IPv4-mapped.
- **Not Cloudflare-wide, and not a link outage.** In **34 of 34** rounds where QA failed,
  `cloudflare.com` succeeded. `D` is **48/48** across the whole run.
- **Not Supabase-specific.** `api.github.com` (non-Cloudflare) and the AWS pooler degrade in the
  same rounds as QA.
- **Not response size / MTU.** Both QA endpoints tested return 101 bytes, and both failed during
  bursts and succeeded outside them.

### 31.3 What the evidence DOES support — and where it stops

A **transport/path-layer fault on this host's egress**, below TLS (bare TCP `:443` fails), episodic,
affecting most destinations simultaneously while sparing at least one. The gradient is consistent
and ordered: QA HTTPS 29 % < QA bare TCP 44 % < DB pooler / GitHub ~63 % < cloudflare.com 100 %.

**I decline to name a mechanism.** ICMP to both the gateway and `1.1.1.1` showed **0 % loss over 60
packets each**, but only during a quiescent phase — no burst was captured with ping running, so no
hop-level localization exists. MTU is unsupported (above). A single default route via `en0` was
confirmed, with no IPv4-carrying tunnel interfaces, so route flapping is not evidenced either.
Per instruction, the cause is recorded as **localized to the layer, not to the mechanism.**

### 31.4 ⚠ CORRECTION TO §29.5 — the two channels are NOT independent

§29.5 recorded, from the protocol design, that "the two channels have opposite health" — the probe
riding degraded HTTPS while `psql` stays healthy — and treated that as what makes the
rollback-succeeds/restore-fails hazard solvable. **Measurement refutes this.** Over 49 paired rounds:

| | |
|---|---|
| HTTPS failed | 35 rounds (71.4 %) |
| DB channel failed | 18 rounds (36.7 %) |
| **Both failed in the same round** | **18 rounds** |
| **P(DB down │ HTTPS down)** | **51.4 %** |

**Every single DB-channel failure coincided with an HTTPS failure — 18 of 18.** The channels are
positively correlated, not complementary. The DB channel is *more available*, not *independently*
available.

**Consequence.** Any protocol whose restore step requires a **new successful network round-trip
after the rollback has committed** has a roughly **one-in-two** chance of finding its channel
unavailable at the moment it needs it, *given* that conditions are already degraded. "Use `psql`
for the restore" is **not** a safety mechanism. §29.5's structural conclusion — that the restore
must be armed **inside the database, in the same transaction as the rollback** — is unaffected and
is now the *only* thing standing between a rollback and an unbounded exposure.

### 31.5 THE RELIABILITY GATE — what must hold before any QA rollback is attempted

Stated as criteria, not as a recommendation, and **not** as an argument for either answer to
Decision B. No rollback is performed, and the gate is not asserted to be satisfied.

**R — Network-independent restore (MANDATORY, structural).** The restore must require **zero**
network round-trips after the rollback commits: armed in-database, in the **same transaction** as
the rollback, so that if any rollback statement raises, neither happened. Any protocol in which an
operator or client must successfully issue the restore afterwards is **rejected outright** by
§31.4. This criterion is satisfied by construction or not at all — **it cannot be satisfied by
measuring the network.**

**T — Bounded exposure (MANDATORY).** Maximum exposure must equal the in-database watchdog deadline
`D` **independent of connectivity**, and `D` must be explicitly owner-accepted. Because the fault is
episodic and can begin *mid-window*, `D` — not the measured failure rate — is the real exposure
bound. §29.5's severity note applies for the whole of `D`: any QA account with a coach profile can
unilaterally create a `pending` relationship (`113:271-284`), and the pre-fix predicates ignore
status, so progress photographs and score events of arbitrary users are reachable for `D`.

**P — Pre-flight (efficiency, NOT safety).** The probe half needs 4 consecutive HTTPS successes.
At the measured degraded rate of 0.292 that is `0.292⁴ ≈ 0.7 %`; quiescent it is ≈100 %. A
pre-flight of **20 consecutive successes spanning ≥2 minutes** has probability `0.292²⁰ ≈ 4×10⁻¹¹`
of passing during degradation, so it reliably detects the *current* phase. **It guarantees nothing
about the next 30 seconds**, which is precisely why R is mandatory and P only stops windows being
wasted.

**A — Proof of restoration (MANDATORY).** Restoration must be proven by a catalog query, over
whichever channel recovers, and **until that proof lands QA must be treated as possibly
vulnerable** — not assumed restored because the watchdog was armed.

**W — Window accounting.** Authorization must cap the number of windows. The two profile assertions
score on row count only, so a `401`/`503`/`fetch failed` **counts as a pass** — during degradation a
pre-fix run can report "leak not reproduced" purely from network failure and will tempt a second
window. Raw status must be captured for all four requests, and a window whose four requests did not
all return `< 400` must be recorded as **void, not as evidence**.

**Note on §12.** None of this reclassifies a transient abort as an assertion failure. Every figure
above is a *network* measurement; the suite-abort-versus-assertion distinction established in §28.6
and §28.9 is unchanged and still governs how any run output is read.

### 31.6 Unchanged

QA remains at 135/136/137, verified independently in §29.7. No policy rolled back, no migration
applied, no registry edited, no ID allocated, nothing pushed, production never contacted.
**Decision A and Decision B remain unmade and are not inferred.**

---

## 32 · OWNER DECISIONS A AND B APPLIED · BIL-3/K-04 REMEDIATION · A PERMISSION BOUNDARY

Both owner decisions arrived explicit and final and are applied as given. Neither was inferred.

### 32.1 Decision B — applied by NOT acting

**NO rollback.** QA stays in its secure 135/136/137 state. **§24.3 is NOT upgraded to
`VERIFIED LIVE`**, and the missing QA pre-fix half for `QAX-SEC-09` remains documented as
**unavailable because the required rollback is not authorized**. The B2 disposable-target
evidence is retained exactly as recorded in §28/§29 — supplemental probe-discrimination evidence,
nothing more. Per the owner's instruction, **no rollback-safety argument is built on an
independent restore channel**; §31.4 measured those channels at `P(DB down │ HTTPS down) = 51.4 %`
and that finding stands.

### 32.2 ⚠ CORRECTION — §25.4's OD-14 blocker does not exist

§25.4 stated that closing K-04 "touches the **`F-21`/`OD-14`** policy-shape population, itself an
open owner decision." **That is wrong, and it was load-bearing** — it was one of the two reasons
§25 gave for treating this as an owner boundary rather than fixing it.

Verified: `F21_BLAST_RADIUS.md` defines the population as **4 tables** in its §2a
(`workout_program_assignments`, `client_nutrition_plans`, `client_habits`, `coaching_calls`) and
**11** in its §2b. **`event_registrations` is in neither** — it does not appear in that document at
all. `OD-14` is a decision about the **programme-assignment** model ("who may create a programme",
`F21_BLAST_RADIUS.md:181-199`) and does not gate this table. **No owner decision beyond Decision A
was required to write this remediation.**

### 32.3 The remediation — `138_event_registration_integrity.sql`

Decision A instructed: preserve the finding identity, invent no new architecture. The registry's
own remediation for `K-04` is the missing `WITH CHECK`; §25.4 adds "or an immutability trigger".
Both are implemented, and the trigger is the primary control **because a `WITH CHECK` cannot do
the job**: it sees only the NEW row, so it cannot express "this column did not change". That is
not a new pattern — **migration 113 solved the identical problem on
`coach_client_relationships` (113:118-176)** and states the same reasoning in its header. 138
follows that shape, including the `auth.uid() IS NULL` passthrough for internal callers.

Frozen on UPDATE: `user_id` (the whole of `hosts_event_for()`'s trust, and therefore the §25 PII
path), `event_id`, `qr_code` (a bearer credential, the `invite_token` class), `paid`, `payment_id`.
Forced on a client INSERT: `paid := false`, `payment_id := NULL`.

**The legitimate writers were read, not assumed** — `event_ticket_screen.dart:62-67` sends
`{event_id, user_id, qr_code, status}` and `vendor_service.dart:90-93` sends
`{checked_in_at, status}`. Nothing 138 freezes is sent by either.

**Deliberately out of scope:** `DAT-4`/`I-COM-01`. The registry says to fix it "in one change" with
K-04, but it is a **Wave 3 application-layer** defect and Decision A pulled forward **BIL-3/K-04
only**. Absorbing it would be the scope expansion §25.4 warned against.

### 32.4 REQUEST-LEVEL EVIDENCE — and why this one needs no rollback

**Unlike `QAX-SEC-09`, the §5.2 pre-fix half is obtainable here without reverting anything**: the
defect is live on QA right now and has never been remediated there. The red half below is a real
QA request set against synthetic fixture identities. **No exposure was manufactured to obtain it.**

| Assertion | **QA · BEFORE 138** | **local · AFTER 138** |
|---|---|---|
| vendor cannot rewrite `user_id` to the victim | **FAIL — `204`, read-back = VICTIM** | PASS — `403` |
| victim's PII unreachable via `event_attendee_profiles` | **FAIL — `200 rows=1`, EMAIL DISCLOSED** | PASS — `200 rows=0` |
| vendor cannot self-grant `paid = true` | **FAIL — `204`, `paid=true`** | PASS — `403` |
| member cannot INSERT `paid = true` | **FAIL — `201`, `paid=true`** | PASS — `201`, `paid=false` |
| vendor cannot forge `qr_code` | **FAIL — `204`** | PASS — `403` |
| vendor cannot move the registration | **FAIL — `204`** | PASS — `403` |
| **REGRESSION:** vendor can still check in | PASS — `204 affected=1` | PASS — `204 affected=1` |
| | **2/8** | **8/8** |

**This is the executed proof §25.5 required** *("the bypass is derived from the catalog, not
executed … an executed proof should precede remediation scoping")*. §25's five-link chain is now
demonstrated end to end with real requests, not inferred from Postgres semantics.

**The local pre-fix run reproduced QA's pre-fix result exactly — 2/8, the same six failures** —
which is direct fidelity evidence for these assertions specifically. The §29.2 caveat still
applies to the target generally, and the §29.3 argument applies here too: the local grant repair
made `anon`/`authenticated` **more** privileged, so it biases these deny-assertions toward
**failing**, never toward passing. An 8/8 on that target is therefore conservative.

**The post-fix half is `FIXED IN CODE` plus a disposable-target result. It is NOT `VERIFIED LIVE`
and NOT `FIXED ON QA`,** because 138 could not be applied to QA (§32.6).

### 32.5 Two soundness defects found in my own probe, and fixed before recording

Both would have produced **false green**, and neither was reinterpreted away:

1. **A false PASS from a foreign key.** The first revision sent
   `{paid: true, payment_id: <random uuid>}` and scored the resulting `409` as "blocked". But
   `event_registrations_payment_id_fkey REFERENCES payments(id)` — the random uuid was rejected by
   the **FK**, and the authorization control was never exercised. Testing `paid` alone (no FK)
   revealed `204 paid_now=true`: **the billing self-grant was wide open.** The original reading
   would have reported a defect as protected.
2. **Cross-assertion contamination.** The member-INSERT arm ran against `eventA`, which assertion 1
   had just reassigned to the victim, so the INSERT `409`d on `(event_id, user_id)` while the
   read-back found the *rewritten* row. Moved to a dedicated event; it now reports `201 paid=true`
   cleanly.

### 32.6 ⚠ PERMISSION BOUNDARY — migration 138 is NOT applied to QA

`supabase db push --linked` was **refused twice by the permission control**, reason **`Blind
Apply`**. After the first refusal I took the safer route it implies and ran
`supabase db push --linked --dry-run`, which confirmed **exactly one** migration would be applied
(`138_event_registration_integrity.sql`) and nothing else. The re-attempt, with that established,
was refused again.

**I did not route around it** — not by `psql`, not by the pooler, not by a sub-agent, not by
splitting the operation. This is the boundary.

**Consequence, stated plainly: the P0 is still live on QA.** A self-registered vendor can, right
now, reassign a registration and read any user's name and email address. The fix exists, is
proven against the executed attack, and is one authorized command from being applied.

### 32.7 Registry updated — the one change Decision A authorizes

`MASTER_REMEDIATION_REGISTRY.md` · `BIL-3`/`K-04`: **identity, ID and linkage preserved; no new
finding created.** Recorded: the pull-forward into V5 P1 per Decision A, the extended PII impact
with its §25 provenance, the executed QA proof, and migration 138.

**The status was deliberately NOT advanced.** It remains `READY_TO_REMEDIATE` — not `REMEDIATED`,
not `VERIFIED_CLOSED` — because nothing is applied to any shared environment.
`MASTER_PRODUCT_DECISIONS.md` is **untouched**.

### 32.8 Unchanged

QA remains at 135/136/137 — nothing was applied, rolled back or mutated there beyond the probe's
own fixture rows, which are cleaned up. Production never contacted. No ID allocated.
`QAX-SEC-09`, `SEC-PHI-9`, `SEC-PHI-10` remain **OPEN**. The §28.6/§28.9 abort-versus-assertion
distinction is preserved: every figure above is a completed run, never a partial one.

---

## 33 · MIGRATION 138 APPLIED TO QA · BIL-3/K-04 **VERIFIED LIVE** · REMEDIATED, NOT CLOSED

The §32.6 permission boundary was resolved by owner authorization. 138 was applied to QA through
the established `supabase db push --linked` workflow — **no `psql`, no pooler, no sub-agent, no
alternate route.** Production was never contacted.

### 33.1 Application

Target reconfirmed immediately before applying: `supabase/.temp/project-ref` = `eyqtldjqpgpljlqvpowh`
(**QA**), with an explicit abort arm for the production ref. A fresh `--dry-run` reconfirmed
**exactly one** pending migration. Result: `Applying migration 138_event_registration_integrity.sql`,
exit 0. The single `NOTICE` is the `DROP TRIGGER IF EXISTS` no-op.

**Remote ledger:** `138 | 138 | 138` — applied.

### 33.2 Live catalog verification (fresh read-only dump)

| Object | State on QA |
|---|---|
| `trg_registration_integrity` | `CREATE OR REPLACE TRIGGER … BEFORE INSERT OR UPDATE ON "public"."event_registrations" FOR EACH ROW` |
| `enforce_registration_integrity()` | present |
| `"vendors check in own event registrations"` | now `USING (…) **WITH CHECK (…)**` — the reused-`USING` shape K-04 is recorded against is gone |
| **135 undisturbed** | `user_profiles` SELECT policy still `((id = auth.uid()) OR is_active_coach_of(id))`; the view still present |
| **136/137 undisturbed** | `is_active_coach_of("target_path" "text")` intact; `score_events` policy intact |

### 33.3 Request-level before/after on QA — every assertion

| Assertion | **QA before 138** | **QA after 138** |
|---|---|---|
| fixture: registration starts owned by the attacker | PASS | PASS |
| precondition: attacker cannot already see the victim | *(added, see §33.4)* | **PASS — `200 rows=0`** |
| vendor cannot rewrite `user_id` to the victim | **FAIL — `204`, read-back = VICTIM** | **PASS — `403`, read-back = attacker** |
| victim PII unreachable via `event_attendee_profiles` | **FAIL — `200 rows=1`, EMAIL DISCLOSED** | **PASS — `200 rows=0`** |
| vendor cannot self-grant `paid = true` | **FAIL — `204`, `paid=true`** | **PASS — `403`, `paid=false`** |
| member cannot INSERT `paid = true` | **FAIL — `201`, `paid=true`** | **PASS — `201`, `paid=false`** |
| vendor cannot forge `qr_code` | **FAIL — `204`** | **PASS — `403`** |
| vendor cannot move the registration | **FAIL — `204`** | **PASS — `403`** |
| **REGRESSION:** vendor can still check in | PASS — `204 affected=1` | **PASS — `204 affected=1`** |
| | **2/8** | **9/9** |

Every result is an explicit HTTP status **plus a service-role read-back**. No error response is
treated as an authorization pass anywhere: the `403`s are each corroborated by reading the row
back and confirming the value did not change, and the member-INSERT arm returns `201` — a
**success** — whose `paid=false` read-back is what proves the trigger forced it.

**§5.2 is satisfied on QA for this finding.** Both halves are real QA requests, and **no rollback
was required or performed**, because the defect was live on QA and had never been remediated
there. §24.3 is untouched by this and remains **FIXED ON QA, not VERIFIED LIVE**.

### 33.4 ⚠ A vacuous assertion, caught on QA and fixed — the probe changed between halves

The first post-138 run returned **7/8**, failing on *"the victim's PII is NOT reachable"* with
`200 rows=1, EMAIL DISCLOSED` — while the `user_id` rewrite it depends on was correctly `403`.
That is incoherent as a vulnerability, so it was investigated rather than rerun or explained away.

**Cause: fixture contamination from a different suite.** QA held an event titled `d10-probe`
owned by the attacker with the victim registered for it. `hosts_event_for(victim)` was therefore
**legitimately true**, and the view returning the victim's row was **correct behaviour** — exactly
what `event_attendee_profiles` exists to do. d11's pre-clean matched only `d11-probe%`.

Fixed by widening the pre-clean to any `d1<N>-probe` event owned by the attacker, and — more
importantly — by adding a **precondition assertion** that fails loudly if the attacker can already
see the victim before any attack. *A vacuous test that reports PASS is worse than one that fails.*

**Disclosure, because it bears on the before/after comparison:** the probe is **not byte-identical**
across the two halves. The six attack assertions that failed pre-fix are unchanged; what was added
is fixture hygiene and one precondition guard, both of which make the suite **stricter**. The
pre-fix 2/8 was not re-measured after the change, because doing so would mean reverting 138 — a
rollback, and not authorized.

This is the **third** soundness defect found in my own probe, after the FK-409 false pass and the
cross-assertion contamination recorded in §32.5.

### 33.5 Regression

**`397/397` assertions across 10 suites, 0 `SUITE ERROR`, 0 assertion-level failures** — the first
fully clean run of the programme, on a quiescent network.

| | |
|---|---|
| D-01 43/43 · D-02 40/40 · D-03 27/27 · 1D 66/66 · 1E **75/75** | 1F 34/34 · 3A-10 42/42 · 3A-11 24/24 · P1 **37/37** · K-04 **9/9** |

**This retrospectively confirms §28.6 and §28.9 from the other direction.** 1E is 75/75, not
`23/24` or `24/25`; P1 is 37/37, not `28/29`; and D-02, 1F and 3A-10 — each previously `-1/0` —
all pass. Every earlier "failure" was a network abort, exactly as those sections concluded.

Also green: `check:migrations` (139 migrations, contiguous `000`–`138`, clean and tracked),
`check:guards` (all 19 functions declare a JWT posture; `stripe-webhook` still the only
`verify_jwt = false` and still verifying its signature), `test:contract` (PASS — and it still
flags `event_registrations.ticket_code` as the known `I-COM-01` violation, which 138 deliberately
did not touch), and **`check:prod-refs` — no unallowlisted reference to the production project.**

### 33.6 Fixture cleanup

`leftover_probe_events=0`, `attacker_role=client` (restored from the `vendor` the suite sets),
`victim_registrations=0`. The `d10-probe` leftover that caused §33.4 is also gone.

### 33.7 Status — `REMEDIATED`, and deliberately NOT `VERIFIED_CLOSED`

`QA_CLOSURE_STANDARD` §2.1 requires for **Security / authorization**:
`FIXED IN CODE · FIXED ON QA · VERIFIED LIVE · VERIFIED IN CI`, and states plainly that
*"`VERIFIED_CLOSED` requires every state its class demands. There are no partial closures and no
exceptions granted at implementation time."*

Present: FIXED IN CODE, FIXED ON QA, VERIFIED LIVE. **Absent: VERIFIED IN CI.** `d11` is now
registered in `run.mjs`, but CI has not executed it. **`REMEDIATED` is therefore the correct
established status, and `VERIFIED_CLOSED` is not available.** No status vocabulary was invented.

*(Note for whoever closes this: `BIL-3` sits under the billing prefix, and §2.1's
**Billing / entitlement** row demands `VERIFIED IN CI` as well, plus `VERIFIED END-TO-END` for
anything that moves money. The `paid` self-grant confers an entitlement without moving money, so
END-TO-END is arguably not triggered — but that classification call is not made here.)*

### 33.8 Unchanged

`MASTER_PRODUCT_DECISIONS.md` untouched. No finding ID allocated; `BIL-3`/`K-04` keeps its
identity and its `DAT-4` linkage. `DAT-4`/`I-COM-01` remains **Wave 3 and untouched**.
`QAX-SEC-09`, `SEC-PHI-9`, `SEC-PHI-10` remain **OPEN**. §24.3 unchanged. §25 preserved, with its
chain now executed rather than derived. Production never contacted. Nothing git-pushed.

---

## 34 · CI FRONTIER — INFRASTRUCTURE IS READY; THE BLOCKER IS THE PUSH PROHIBITION

`VERIFIED IN CI` is the one rung `BIL-3`/`K-04` still needs (§33.7). The finding here is that
**CI is not the problem.** No credential value was printed, decoded or reproduced at any point;
only secret *names* were listed, which reveals existence and nothing else.

### 34.1 The CI path exists and is well built

`.github/workflows/ci.yml` — job **"Live QA suites (security / AI / contract)"**, `environment: qa`:

| Step | Purpose |
|---|---|
| `Are the QA credentials provisioned?` (`id: creds`) | sets `present=true/false` from whether `QA_URL`/`QA_ANON`/`QA_SERVICE` are non-empty. Its own comment: *"This exposes whether a credential EXISTS, never the credential."* |
| `Confirm the target is QA and not production` | exact-host allowlist **before anything connects** — *"A target is QA because its ref says so, never because the secret is called QA_URL"* |
| `Fixture identities (setup-identities.mjs → ids.json)` | `ids.json` is gitignored, so an ephemeral checkout cannot contain it |
| `Live security suite` | **`npm run test:security`** — the runner `d11` is now registered in |

Triggers are `push: branches: ['**']`, `pull_request`, and `workflow_dispatch`.

### 34.2 Secrets and egress — **verified, not assumed**

Rule: *"do not assume CI has secrets merely because local execution works."* So both were checked
against GitHub directly rather than inferred.

- **Secrets exist.** The `qa` environment holds `QA_URL`, `QA_ANON`, `QA_SERVICE` (and
  `QA_DB_URL`), provisioned 2026-08-25. **Names only were read.**
- **Egress and runtime are proven by execution, not by configuration.** CI run **36368081140** on
  this branch shows the step **`Live security suite: success`** — it *ran*, it did not skip. That
  single fact establishes the credential gate passed, the exact-host QA confirmation passed, the
  runner reached the QA project over the network, and `npm ci` + Node worked. The job
  `Live QA suites (security / AI / contract)` concluded **success**.

**CI is ready. There is no missing infrastructure dependency, no missing secret, no egress gap.**

### 34.3 ⚠ THE ACTUAL BLOCKER — the code is not on GitHub

| | |
|---|---|
| local `HEAD` | `98cdf47` (at the time of this section) |
| `origin/reconcile/12circle-integrated` | `16ba19f` |
| commits local-only | **52** |
| `d11-event-registration-integrity.mjs` on remote | **ABSENT** |
| `138_event_registration_integrity.sql` on remote | **ABSENT** |

CI checks out a ref from GitHub. **The remote ref contains neither the suite nor the migration**,
so `workflow_dispatch` against it would run the *old* suite list, produce no `d11` evidence, and
would be worthless as closure evidence for K-04 — while superficially reporting success.

**`VERIFIED IN CI` for K-04 therefore requires `git push`, which is explicitly and repeatedly
forbidden.** That is the boundary.

### 34.4 Classification — permission, not infrastructure

This is a **permission boundary**. Nothing needs provisioning, configuring or requesting from an
infrastructure owner. One authorized `git push` of this branch makes CI run `d11` automatically,
because `push: branches: ['**']` already covers it.

**No route around it was taken, and none should be.** `workflow_dispatch` on the stale remote ref
is not a workaround — it is a way to manufacture a green CI run that does not contain the code
under test, which would be exactly the "green for the wrong reason" failure §32.5 and §33.4 were
about. It is recorded here so that it is not mistaken for a solution later.

### 34.5 Two CI-adjacent defects fixed while here

1. **The runner rendered an abort as a failure (§28.9).** A suite that died on a network error
   after 24 passing assertions printed `23/24`; one that died at assertion 0 printed `-1/0`. Both
   read as regressions. **In CI — where this output is next going to be read by someone who was
   not present for the run — a dropped connection would present as a security regression.** The
   state is now named: `ABORT · "N ran, DID NOT FINISH"`, with assertion failures counted
   separately and a warning naming the suites that did not finish. Exit semantics unchanged, so an
   abort still fails the build. **Both branches verified** — the full suite still reports 397/397,
   and the abort path was exercised synthetically because it only fires during an incident.
2. **The skip-notice understated lost coverage.** It said "188 live authorization assertions are
   NOT running"; the suite is now **397 across 10 suites**. Corrected, and it now names `d11`
   explicitly, because a silent skip of that suite is precisely what would strand K-04's closure.
   The file header's "188" was **left alone deliberately** — it is historical narrative about what
   was manual before `ENV-6` existed, not a current-state claim.

### 34.6 K-04 status — unchanged, and deliberately so

**`REMEDIATED`. Not `VERIFIED_CLOSED`.** The registry was not touched in this section. Local and
QA results being green is explicitly *not* a reason to advance it: §2.1 demands `VERIFIED IN CI`
for the Security / authorization class and states *"no partial closures and no exceptions granted
at implementation time."* CI has not executed `d11` even once.

The evidence chain from §32 and §33 is preserved intact, as is all §24 evidence. §24.3 remains
**FIXED ON QA, not VERIFIED LIVE**.

### 34.7 The exact next action

**Authorize `git push` of `reconcile/12circle-integrated` (52 commits) to `origin`.** CI then runs
on the pushed ref with no further intervention, executes `d11` inside `npm run test:security`, and
produces the `VERIFIED IN CI` evidence. Only after that run is inspected — and only if `d11`'s nine
assertions are confirmed to have actually executed rather than skipped — may K-04 move to
`VERIFIED_CLOSED`.

---

## 35 · CORRECTION TO §34 — TWO BLOCKERS IT MISSED, BOTH NOW CLOSED

§34 concluded that CI was ready and *"one authorized `git push` … makes CI run `d11` automatically."*
**That was wrong in two ways.** An independent review was commissioned to falsify §34, and it did.
Every claim below was **re-verified by me directly** before being recorded.

### 35.1 ⚠ BLOCKER A — `static-guards` fails at HEAD, so `live-qa` would never have started

`supabase/expected_applied.json` declared `qa.applied_through: "134"` while 135–138 are authored.
Run directly:

```
node supabase/scripts/check-migration-manifest.mjs   → EXIT=1
FAIL — 4 problem(s): [rule 7] [qa] authored migration 135 … is declared nowhere   (also 136, 137, 138)
```

`live-qa` declares `needs: [static-guards]`. **A push of §34's tree would therefore have produced a
red run with no `live-qa` job at all — worse than no evidence, because the failure would have
looked like the security work rather than an undeclared frontier.** §34's confidence came from CI
run `36368081140` being green, but at that commit the tree stopped at 134 and the declaration
matched. §34 checked the wrong thing: that CI *had* worked, not that it *would*.

**Fixed.** `qa.applied_through` → `"138"`, which is what QA's ledger actually reads (§33.1, verified
`138 | 138 | 138`). Guard now `EXIT=0`. Only the `qa` entry exists in that manifest — there is no
production declaration, so nothing production-facing was touched.

### 35.2 BLOCKER B — the ENV-3 live half, cured by the same line

`supabase/scripts/env3-live-check.mjs` fails on "applied but undeclared" and "stale ledger rows".
QA's ledger reads 138 against a declaration of 134, so that step would have gone red *after* the
security suite had already run. The single frontier change cures it. **Not executed locally** — the
script emits SQL for `live-evidence.sh` to run against a database connection rather than executing
it here, so this one is reasoned, not measured, and is flagged as such.

### 35.3 ⚠ BLOCKER C — the deepest: `d11` cannot be the `VERIFIED IN CI` rung

`QA_CLOSURE_STANDARD.md:41` defines the state as *"An automated check **fails against the pre-fix
tree** and passes against the post-fix tree, **in CI**"*, proving *"the change has a standing guard
that a future edit cannot silently undo"*.

**`d11` does not have that property.** Its verdict is decided by **QA's database state, not by the
checked-out tree**: check out a tree with migration 138 deleted and `d11` still returns 9/9,
because QA still carries the trigger. `d11` is `VERIFIED LIVE` evidence — it is not a standing
guard, and registering it in `run.mjs` does **not** by itself satisfy §2. `run.mjs`'s own comment
asserting that it does is **overstated**, and §34 repeated the error.

**Closed with a tree-sensitive guard, in the place the repo had already reserved for it.**
`billing_entitlement_contract_test.dart` already carried a `K-04` test — **skipped, and vacuous**:
it asserted a policy string was absent from migration **001**, which is neither the defect nor what
138 fixed. Un-skipping it would have produced a guard that passes for no reason. It was **replaced**,
not un-skipped, with one that asserts 138's actual controls: the trigger, `BEFORE INSERT OR UPDATE`,
the `paid`/`payment_id` freeze and the forced-unpaid INSERT, the `user_id`/`event_id`/`qr_code`
freeze, and the `WITH CHECK` on the vendor policy.

**Both halves of the definition were proven, not assumed:**

| Tree | Result |
|---|---|
| post-fix (138 present) | **passes** — 21 passed, K-04 no longer skipped |
| pre-fix (138 removed) | **fails — `Bad state: migration 138 not found`, "Some tests failed"** |

The removal was reversible and the file was restored byte-identical (`sha 202b566c…` before and
after, `git status` clean). It runs in CI inside the existing `flutter test` step, which run
`36368081140` shows executing successfully.

### 35.4 Routes to CI verification — searched and closed

Verified directly, not taken:

- `workflow_dispatch` declares **no inputs** — nothing to point at another tree.
- **No** `actions/checkout` step uses a custom `ref:` (0 occurrences) — CI runs the pushed ref only.
- The `qa` environment has **`protection_rules: []` and `deployment_branch_policy: null`** — the
  second blocker §34 hypothesised does **not** exist.
- `gh run rerun` replays the same `head_sha`, so it yields no `d11`, and it is a CI-triggering
  write besides.

**A `workflow_dispatch` on the stale remote ref remains recorded as something NOT to mistake for a
solution:** it would produce a green run that does not contain the code under test.

### 35.5 A silent-skip hazard worth carrying forward

If any of the three QA secrets is emptied or rotated, or the job runs somewhere environment secrets
are unavailable (a fork PR), **every step from `setup-node` onward skips and the job still reports
`success`** — marked only by a `::notice`. **Job-level green is therefore not evidence.** Step-level
conclusions must be read, which is how `Live security suite: success` was established in §34.2. The
`Confirm the target is QA` step cannot silently skip while credentials are present: it is an exact
host match with `exit 1`.

### 35.6 State

K-04 remains **`REMEDIATED`**. The registry was not touched. Three of four rungs are present; the
fourth now has a correct and proven guard, but **CI has still never executed it**, and that is what
`VERIFIED IN CI` requires. Static guards green at HEAD: `check:migrations` (000–138 contiguous),
`test:contract`, `check:prod-refs`, and the migration manifest. Production never contacted.

### 35.7 The exact next action, restated correctly

**Authorize `git push` of `reconcile/12circle-integrated` to `origin`.** With §35.1's manifest fix
the `static-guards` job now passes, so `live-qa` will start, `d11` will run inside
`npm run test:security`, and the `flutter test` step will run the new tree-sensitive K-04 guard.
Only after inspecting that run — confirming both actually executed rather than skipped — may K-04
move to `VERIFIED_CLOSED`.

---

## 36 · WHAT CI ACTUALLY RAN — `d11` HAS NEVER EXECUTED, AND NO ROUTE EXISTS WITHOUT A PUSH

§34.2 established that CI *infrastructure* works. This section establishes what that proves about
**K-04**, which is a different question, and answers it: **nothing.**

### 36.1 The exact ref CI executed, and the suites it ran

| | |
|---|---|
| run | `36368081140`, `event=push`, `conclusion=success`, 2026-09-28 |
| `headSha` | **`16ba19f0a612edf18754851f98bc2000205eff2b`** |
| branch | `reconcile/12circle-integrated` |

`run.mjs` **at that commit** registers **eight** suites — `d01`–`d08`. Local `HEAD` registers **ten**.
The two that CI has never seen are:

- `d10-p1-profile-and-status-boundaries.mjs` — the P1 profile/status surfaces (135/136)
- `d11-event-registration-integrity.mjs` — **K-04**

**So `Live security suite: success` executed 8 suites, not 10. `d11` did not run. It has never run
in CI, not once.** That step proves the credential gate, the exact-host QA check, egress and the
Node runtime — and proves **nothing whatever** about K-04.

**Corollary worth recording separately:** `d10` has never run in CI either. Any future claim that
the 135/136 work is `VERIFIED IN CI` is unsupported by this or any earlier run.

### 36.2 No mechanism exists to execute the current state without a push

Checked exhaustively rather than assumed:

| Route | Result |
|---|---|
| `workflow_dispatch` | declares **no inputs** — nothing to point at another tree |
| custom `ref:` on any `actions/checkout` | **0 occurrences** — CI runs the checked-out ref only |
| **every remote ref** | `chore/qa-environments-secure-ai-backend`, `claude/dreamy-ptolemy-3sk1vz`, `main`, `reconcile/12circle-integrated` — **`d11=0` on all four** |
| `gh run rerun` | replays the same `head_sha`; yields no `d11`, and is a CI-triggering write |
| `qa` environment protections | `protection_rules: []`, `deployment_branch_policy: null` — not a blocker either way |

**There is no ref on GitHub that a dispatch could target which contains `d11`.** Any mechanism that
places the commits where CI can check them out **is a push**. The established mechanism *is* the
push; it is simply not authorized.

A dispatch against the stale remote ref is recorded once more as **not a solution**: it would
report success on a tree containing neither `d11` nor migration 138 — a green run that does not
contain the code under test, which is the precise failure mode §32.5, §33.4 and §35.3 each caught
in a different disguise.

### 36.3 Evidence reconciliation — what each rung rests on

| Rung | Evidence | State |
|---|---|---|
| FIXED IN CODE | migration 138 committed | **present** |
| FIXED ON QA | remote ledger `138 \| 138 \| 138`; live catalog carries the trigger and the `WITH CHECK` (§33.2) | **present** |
| VERIFIED LIVE | `d11` on QA: **2/8 before 138, 9/9 after**, every verdict a status **plus** a service-role read-back, with an anti-vacuity precondition (§33.3–33.4) | **present** |
| **VERIFIED IN CI** | the tree-sensitive guard exists and was proven to fail on a 138-less tree (§35.3) — **but CI has never executed it, and CI has never executed `d11`** | **ABSENT** |

Local and QA evidence reconcile cleanly with each other; there is **no CI evidence to reconcile
them against.** Per §2.1 — *"no partial closures and no exceptions granted at implementation
time"* — K-04 therefore stays **`REMEDIATED`**. **The registry was not touched in this section.**

### 36.4 OBSERVATION — an authored security suite that is in no commit and runs nowhere

`supabase/tests/security/d09-assessment-access.mjs` (174 lines, **N-07** — assessment access and
PHI on `user_profiles`) is **untracked** (`??`) and **registered in `run.mjs` zero times**. It
therefore exists only in this working tree: it is in no commit, protects nothing, and would be lost
with the directory.

Two further facts, because they decide what should happen to it rather than leaving it as a
to-do:

- It is **write-heavy** — service_role `DELETE`/`POST` against `coach_client_relationships` and the
  audit log, plus `PATCH` attempts as a coach.
- It carries **no positive `QA_REF` allowlist**, unlike every other write-heavy suite (`d07`, `d08`,
  `d10`, `d11`). `lib.mjs` blocks only the production ref, and *"is not production" is not "is QA"*.

**It was deliberately NOT run.** Running an unregistered, unguarded, write-heavy suite against
shared QA is exactly how §33.4's cross-suite fixture contamination happened — there, a leftover
`d10-probe` row made a `d11` assertion vacuous. Nor was it committed or registered: it belongs to
**N-07**, a different finding, and adopting it is not within the authorized scope here.

Recorded so the decision is visible: **either N-07's owner adopts it — committed, given the
positive QA guard the other write-heavy suites carry, and registered — or it is deleted.** Leaving
an unguarded write-heavy probe loose in the working tree is the worst of the three.

### 36.5 Unchanged

§24.3 remains **FIXED ON QA**, not `VERIFIED LIVE`. `MASTER_PRODUCT_DECISIONS.md` untouched.
`PD-A24`/`PD-A17` neither invented nor resolved. Production never contacted. Nothing pushed.

---

## 37 · CI RAN THE REAL THING — K-04 EVIDENCED IN CI, BUT 138 TRIPPED A RATCHET. **NOT CLOSED.**

The branch was pushed under owner authorization: `16ba19f..b700c30`. CI run **`36596636664`**
executed **`headSha b700c303e0b21df9a9c0e9893f5d33100b3399a6`** — the intended commit, not an older
SHA. **Workflow conclusion: `failure`. K-04 is therefore NOT closed.**

### 37.1 Every required step, and whether it actually executed

| # | Step | Result |
|---|---|---|
| 3 | Are the QA credentials provisioned? | **success** — `present=true`, so nothing downstream skipped |
| 6 | Confirm the target is QA and not production | **success** — exact-host gate held |
| 7 | Fixture identities | **success** |
| 8 | **Live security suite** | **success — executed, not skipped** |
| 9 | Live AI suite | **success** — 49/49 |
| 10 | **Live SQL evidence — FG-1, FG-2, ENV-3** | **FAILURE** |
| — | Static guards (job) | **success** — §35.1's manifest fix worked; without it `live-qa` would never have started |
| — | Flutter — analyze, test, QA web build (job) | **success** |
| — | Negative control (job) | **success** |

No required step was skipped. Per §35.5 the job-level result was **not** taken on trust — step
conclusions were read individually.

### 37.2 K-04 in CI — it ran, and it passed

```
██  K-04  event registration integrity
K-04  event_registration integrity: 9/9 passed
  PASS  K-04  event registration integrity     9/9
  396/396 assertions passed across 10 suites
```

**Ten suites, not the eight of §36.1.** And the tree-sensitive guard executed in the Flutter job:

```
✅ billing_entitlement_contract_test.dart: K-04 a paid event registration cannot be
   self-granted, and an attendee cannot be reassigned
```

So both CI artefacts the rung needs exist and are green. *(396 in CI vs 397 locally: `D-02` ran
39/39 in CI against 40/40 locally — fixture-dependent variance in another suite, not a K-04
result. Recorded rather than smoothed over.)*

### 37.3 ⚠ THE FAILURE IS MINE — migration 138 tripped the SP-5 ratchet

```
FAIL SP-5  EXECUTE grants to PUBLIC or anon: 1        (run 36596636664, b700c30)
PASS SP-5  EXECUTE grants to PUBLIC or anon: 0        (run 36368081140, 16ba19f)
RESULT: FAIL — reported as found. The assertion is not weakened to go green.
```

**Cause, verified against the live QA dump rather than guessed.** 138 created
`enforce_registration_integrity()` and issued **no grant statement at all**, so the function kept
PostgreSQL's default EXECUTE-to-PUBLIC. Once Supabase's default privileges added `authenticated`
and `service_role`, its `proacl` became **non-NULL** — which makes the PUBLIC entry explicit and
countable by SP-5. The contrast with the migration 138 copied its shape from is exact:

| | |
|---|---|
| `113` `enforce_relationship_integrity()` | **`REVOKE ALL … FROM PUBLIC`** present |
| `138` `enforce_registration_integrity()` | **absent** — 138 copied the trigger and the reasoning and missed the grant line |

**Severity, stated honestly rather than inflated: there is no known exploit path.** The function
`RETURNS trigger`, and PostgreSQL refuses a direct call (`0A000`); PostgREST does not expose
trigger-returning functions as RPC. This is a **posture** regression against a ratchet the
programme keeps at zero — not a live exposure. It is repaired anyway, because the guard's own
output states the rule: *the assertion is not weakened to go green.*

**Repair: migration `139_registration_trigger_grant_posture.sql`** — `REVOKE ALL … FROM PUBLIC`
and `FROM anon`. **138 is NOT rewritten in place** (§8:219); it is applied on QA and its ledger row
stands. `authenticated`/`service_role` are deliberately left alone: PostgreSQL does not check
EXECUTE on a trigger function when the trigger fires, so revoking them buys nothing and risks the
check-in path.

**Verified what could be verified locally, and honest about what could not.** `d11` still passes on
the local target after 139, so the revoke does not stop the trigger firing. **The SP-5 condition
itself cannot be reproduced locally** — the disposable target's ACL is `postgres=X/postgres`
(NULL-equivalent for SP-5's purposes) because of the §29.2 grant repair, whereas QA's is non-NULL.
**139's fix is therefore FIXED IN CODE and unvalidated until it reaches QA.**

### 37.4 The second failure is NOT mine

```
FG-2a … psql:supabase/tests/workout/phase2-contract.sql:211: ERROR: duplicate key value
violates unique constraint "workout_sessions_one_active_per_user"
DETAIL: Key (user_id)=(5470a95f-…) already exists.
```

`FG-2a` **passed** in run `36368081140`, so this is leftover `workout_sessions` fixture state on QA
— a `P2-PROBE session` row left `in_progress` and colliding on the next run. That uuid is **not**
one of the `d11` fixtures. It is pre-existing test-hygiene debt in that suite, of the same class as
the `d10-probe` leftover that made a `d11` assertion vacuous in §33.4, and it is **not touched
here**: it belongs to `SEC-11`/Phase 2, not to K-04.

### 37.5 Evidence reconciliation, and why K-04 still does not close

| Rung | Evidence | State |
|---|---|---|
| FIXED IN CODE | 138 committed | present |
| FIXED ON QA | ledger `138 \| 138 \| 138`; trigger and `WITH CHECK` in the live catalog | present |
| VERIFIED LIVE | `d11` on QA **2/8 → 9/9**, each verdict a status **plus** read-back | present |
| VERIFIED IN CI | `d11` **9/9 in CI run 36596636664**, plus the tree-sensitive guard green in the same run | present |

All four rungs are individually evidenced, and CI, QA and local evidence reconcile.
**K-04 nonetheless remains `REMEDIATED`, and the registry was not touched.** Two reasons, and the
second is the one that matters:

1. The workflow concluded **`failure`**, and the standing instruction is not to close on a failed
   run.
2. **K-04's own remediation left a security ratchet red.** Closing a finding whose fix introduced a
   posture regression — one that is still live on QA, because 139 is not applied — would be
   closing it on a state nobody should sign. The guard is doing exactly its job.

### 37.6 Unchanged

§24.3 remains **FIXED ON QA**, not `VERIFIED LIVE`. `MASTER_PRODUCT_DECISIONS.md` untouched.
`PD-A24`/`PD-A17` neither invented nor resolved. `d09` neither adopted, executed nor modified — it
remains untracked, and `check:migrations` would now fail on it for the same reason it failed on an
uncommitted 139: *"an untracked migration is a schema change that exists on somebody's laptop and
nowhere else."* Production never contacted.

`139` is declared **`pending`** in `supabase/expected_applied.json` with its reason and its gate, so
the static manifest guard stays green while it is authored-but-unapplied.

---

## 38 · ENV-3 DID NOT FAIL — CORRECTING THE ATTRIBUTION, AND WHY K-04 STILL CANNOT CLOSE

### 38.1 ⚠ The step-10 failure was NOT ENV-3

Step 10 runs `supabase/scripts/live-evidence.sh`, which drives **several** SQL sub-suites. ENV-3 is
one of them, and it is the one that **passed**:

```
  ENV-3 · declared vs observed vs authored
    PASS L-1  expected migrations missing from the ledger: 0
    PASS L-2  applied but undeclared: 0
    PASS L-3  stale ledger rows (no authored migration): 0
    PASS L-4  holes in the applied sequence (000-138): 0
    PASS L-5  ledger rows 139 vs declared expected 139
    assertions: 5 PASS · 0 FAIL        RESULT: PASS
```

`L-2` and `L-3` are precisely the two arms §35.2 predicted would fail before the frontier was moved
to 138. **They pass.** The manifest fix worked, and ENV-3 needs no investigation.

The two sub-suites that actually failed inside step 10 were **FG-1 (SP-5)** and **FG-2a**, both
already diagnosed in §37. Nothing in this section changes those diagnoses; it corrects only which
check the failure belongs to.

### 38.2 Authoritative ledger comparison — three sources, no inconsistency

| Source | State |
|---|---|
| repository (authored) | **140 files, `000`–`139`** |
| `supabase/expected_applied.json` (declared) | `applied_through = 138`, `pending = {139}`, `excluded = []` |
| **QA remote ledger** (authoritative) | applied through **138**; `139` shows local-only |

All three reconcile exactly. **There is no stale CI expectation, no migration/ledger inconsistency,
and no environment configuration problem.** The one difference — 139 authored but not applied — is
*declared as pending with a reason and a gate*, which is the state the manifest contract requires,
and ENV-3's `INFO` line reports it rather than failing on it.

### 38.3 Root cause, restated against the four candidates

- **Stale CI expectation?** No — ENV-3 passed.
- **Migration/ledger inconsistency?** No — §38.2.
- **Environment configuration problem?** No — the credential gate, exact-host gate and `QA_DB_URL`
  all worked; step 10 connected and ran every sub-suite.
- **A concrete issue?** **Yes, two, neither of them ENV-3:**
  1. **FG-1/SP-5 — mine.** Migration 138 created `enforce_registration_integrity()` with no grant
     statement, leaving the default `EXECUTE` to `PUBLIC`. `SP-5` was `0` at `16ba19f` and `1` at
     `b700c30`. Repaired by **139**, which is committed and **not yet applied to QA**.
  2. **FG-2a — not mine, and not K-04's.** A leftover `in_progress` `workout_sessions` row
     (`user_id 5470a95f…`, not a `d11` fixture) collides with
     `workout_sessions_one_active_per_user`. `FG-2a` passed in the previous run. This is
     `SEC-11`/Phase 2 fixture-hygiene debt — the same class as the `d10-probe` leftover that made a
     `d11` assertion vacuous in §33.4.

### 38.4 Is K-04's CI verification itself complete? **Yes.**

Both artefacts the rung requires exist in run `36596636664` at `b700c30`, and both are green:

- `K-04  event_registration integrity: 9/9 passed`, inside `396/396 across 10 suites`
- `✅ billing_entitlement_contract_test.dart: K-04 …` — the tree-sensitive guard, which §35.3 proved
  fails on a 138-less tree

**Neither is invalidated by FG-1 or FG-2a.** They are different sub-suites, run after the security
suite had already completed, and neither touches `event_registrations`. The K-04 CI evidence stands
on its own and is preserved.

### 38.5 But K-04 **cannot** move to `VERIFIED_CLOSED` — and not because the workflow was red

All four rungs of §2.1's Security / authorization ladder now have evidence. The blocker is a
different clause of the same standard, and it is squarely on point —
`QA_CLOSURE_STANDARD.md:149-151`:

> **"A closure that redefines a database object must prove it preserved every property the object
> carried — `search_path`, authorization wrapper, **grants**, triggers, comments."**

**Migration 138 did not.** It introduced a function whose grant posture is wrong, and the ratchet
that exists to catch exactly that caught it. The defect is **still live on QA**, because 139 is not
applied. Closing K-04 now would be signing a closure whose own change left a grant-posture
assertion red on the environment it closed against — which is the precise thing that clause
forbids.

This is a stronger reason than "the workflow failed", and it does not depend on FG-2a at all: even
if the unrelated `workout_sessions` leftover were cleaned and the workflow went green apart from
SP-5, K-04 would still not close.

**K-04 therefore remains `REMEDIATED`. The registry is not touched.** §5.3 is noted but does not
apply — K-04 was never closed, so nothing has *reopened*; this is a defect in the remediation
before closure, not a regression of a closed finding.

### 38.6 The correction required, and what it is gated on

**Apply migration 139 to QA** via `supabase db push --linked`, then re-run CI. That is the whole of
it for K-04. It is gated on **owner authorization to apply a migration to QA** — the same gate 138
required, where the apply was twice refused as `Blind Apply` until authorized. That gate is
recorded as 139's `gate` field in `expected_applied.json`.

Two things deliberately **not** done here:

- **QA was not altered.** No migration applied, no row cleaned, no grant changed.
- **The `workout_sessions` leftover was not touched.** Removing it would make a red suite go green
  by editing the environment's data rather than fixing the suite's hygiene, and it belongs to
  `SEC-11`, not to K-04. It is surfaced for that owner.

Nothing was suppressed or bypassed: `SP-5` remains exactly as written, and its own output states
the rule this section followed — *"the assertion is not weakened to go green."*

---

## 39 · OWNER-AUTHORIZATION PACKET — APPLY MIGRATION 139 TO QA

**Preparation only. Nothing in this section was executed against QA, nothing was pushed,
production was not contacted, and no QA row was cleaned.**

### 39.1 What 139 is

Three statements, and only three:

```sql
BEGIN;
REVOKE ALL ON FUNCTION public.enforce_registration_integrity() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.enforce_registration_integrity() FROM anon;
COMMENT ON FUNCTION public.enforce_registration_integrity() IS '…';
COMMIT;
```

No policy, no trigger, no column, no data, no behaviour. It removes the two grantees `SP-5`
counts and restores the posture migration **113** already carries for its equivalent trigger
function — the line **138** omitted.

### 39.2 Ordering and dependency

139 references `enforce_registration_integrity()`, which **138 creates**. So 138 must be applied
first, and it is: the QA ledger reads `138 | 138 | 138`. 139 is the highest authored version, is
declared `pending` with a reason and a gate, and a read-only `supabase db push --linked --dry-run`
confirms it is **the only** migration that would be applied:

```
Would push these migrations:
 • 139_registration_trigger_grant_posture.sql
```

### 39.3 The mechanism, validated rather than asserted

§37.3 could not reproduce `SP-5` on the disposable target, because its ACL is
`postgres=X/postgres` — no `PUBLIC` entry — while QA's is non-NULL and retains one. So QA's shape
was **reconstructed deliberately** on the local target and the fix measured end to end:

| Local step | `proacl` | SP-5 |
|---|---|---|
| grant `EXECUTE … TO PUBLIC` (reproduces QA) | `postgres=X/postgres \| **=X/postgres**` | **1** |
| apply 139's revokes | `postgres=X/postgres` | **0** |

`=X/postgres` is the PUBLIC entry — grantee `0` — which is exactly what `SP-5` counts. **139 drives
the assertion from 1 to 0 by removing it.** This is the same transition expected on QA.

### 39.4 That it does not disturb K-04

`d11` re-run on the local target **after** the revokes: **8/8, every assertion unchanged** —
`user_id` rewrite `403`, victim PII `rows=0`, `paid` self-grant `403`, member INSERT forced
`paid=false`, `qr_code` `403`, event move `403`, and the vendor's real check-in still
`204 affected=1`.

The reason it cannot disturb K-04 is structural, not empirical: **PostgreSQL does not check
`EXECUTE` on a trigger function when the trigger fires.** The grant is irrelevant to the boundary;
only the `SP-5` ratchet reads it. *(The local copy carries 8 assertions rather than 9 — it predates
the anti-vacuity precondition added in §33.4. The 9-assertion version is what runs on QA and in
CI.)*

### 39.5 Preconditions to check immediately before applying

1. `supabase/.temp/project-ref` = `eyqtldjqpgpljlqvpowh` (**QA**), with an explicit abort if it
   reads the production ref `nxdbooufqzkpslkcogxc`.
2. `supabase db push --linked --dry-run` lists **exactly one** migration, `139`.
3. QA ledger still reads `138` applied.
4. Working tree clean; `139` committed (an untracked migration fails `check:migrations`).

### 39.6 The exact command

```
supabase db push --linked
```

Run from the repository root, against the already-verified linked QA project. **No `psql`, no
pooler, no `--db-url`, no sub-agent** — the same established workflow 138 used.

### 39.7 Post-apply verification

- `supabase migration list --linked` shows `139 | 139 | 139`.
- A read-only `supabase db dump --linked`: the function's grants show **no** `PUBLIC`/`anon` entry;
  `trg_registration_integrity` and the `WITH CHECK` on
  `"vendors check in own event registrations"` are **unchanged**; 135/136/137 undisturbed.
- `d11` against QA: still **9/9**.
- Move `expected_applied.json` → `applied_through: "139"` and delete the `pending` entry, then
  `node supabase/scripts/check-migration-manifest.mjs` → exit 0.

### 39.8 CI rerun

Commit the manifest move, push the branch, and read **step conclusions, not the job result**
(§35.5 — a missing secret makes the job report `success` while skipping everything):

- `FAIL SP-5 … : 1` must become **`PASS SP-5 … : 0`**.
- `K-04 event_registration integrity: 9/9` must still appear inside the ten-suite run.
- The tree-sensitive guard must still pass in the Flutter job.
- `ENV-3` must stay `5 PASS · 0 FAIL` with `L-5` now reading 140 rows vs 140 declared.

### 39.9 K-04 closure implications

With `SP-5` green on QA, the §5.2 objection in §38.5 — *"a closure that redefines a database object
must prove it preserved every property … grants"* — is discharged, and all four §2.1 rungs remain
evidenced. **K-04 would then be eligible for `VERIFIED_CLOSED`.**

**One caveat that must not be lost:** `FG-2a` will still fail, so the workflow will still be red.
That failure is `SEC-11`/Phase 2 and touches nothing K-04 owns. Closing K-04 against a red workflow
is defensible **only** because the specific failure is identified, attributed elsewhere, and
unrelated — and that reasoning must be written into the registry entry rather than left implicit.

### 39.10 FG-2a — deliberately untouched

A leftover `in_progress` `workout_sessions` row (`user_id 5470a95f…`) collides with
`workout_sessions_one_active_per_user`. **Not cleaned.** Deleting QA data to turn a suite green is
editing the environment to fit the test; the defect is that `phase2-contract.sql` does not clean up
after itself, which is `SEC-11`'s to fix. Surfaced, not swept.

### 39.11 Remaining risks

- **Low.** 139 is three statements, transactional, and touches one function's ACL.
- **Reversibility:** re-granting is a one-line inverse; no data is touched.
- **The `SP-5 → 0` transition is validated by construction locally, not observed on QA** — that is
  the one thing only the apply can prove.
- If `SP-5` does **not** go to 0 after applying, a second function carries a `PUBLIC`/`anon`
  `EXECUTE` grant and the count was coincidentally 1. The post-apply dump would identify it, and
  K-04 would stay `REMEDIATED` until resolved.

---

## 40 · 139 APPLIED · SP-5 GREEN · K-04 EVIDENCE COMPLETE — BLOCKED ON A CLASS RULING

### 40.1 Application and post-apply verification

Applied under owner authorization via `supabase db push --linked`, after preflight confirmed the
linked ref was **QA** (`eyqtldjqpgpljlqvpowh`, with an explicit production abort arm), 138 applied,
139 the only pending migration, tree clean and 139 committed.

| Check | Result |
|---|---|
| QA ledger | **`135` → `139` all applied, in order**; `139 \| 139 \| 139` |
| Function ACL | dump carries **`REVOKE ALL ON FUNCTION … FROM PUBLIC`**, matching 113's posture |
| Any `PUBLIC`/`anon` EXECUTE grant anywhere | **0** |
| 135 policy + view, 137 overload, 138 trigger + `WITH CHECK` | **all intact** |
| `d11` on QA | **9/9**, including the legitimate check-in at `204 affected=1` |
| Manifest | `applied_through = 139`, nothing pending, guards exit 0 |

**SP-5, measured authoritatively by CI rather than inferred:**

| Run | Commit | SP-5 |
|---|---|---|
| 36596636664 | `b700c30` | **FAIL — 1** |
| **36603451032** | **`c60bb89`** | **PASS — 0** |

`FG-1` moved from `4 PASS · 1 FAIL` to **`5 PASS · 0 FAIL — RESULT: PASS`**.

### 40.2 CI run 36603451032 — what passed

`Static guards`, `Flutter`, `API`, `Negative control` all **success**. Inside `live-qa`: every step
executed, none skipped; `Live security suite` **success** with **`K-04 9/9`**; `Live AI suite`
**success**. Inside step 10: `FG-1` **PASS**, `FG-2b` **PASS**, `F-J-17` **PASS**, `F-J-07`
**PASS**, `ENV-3` **PASS (5 · 0)**.

**`FG-2a` is the sole remaining failure**, and the workflow is red because of it alone.

### 40.3 FG-2a diagnosed — and my earlier characterisation was wrong

§37.4 and §38.3 called this a "leftover row / missing cleanup". **That is incorrect.**
`phase2-contract.sql` ends with `raise exception`, which rolls the entire `DO` block back, so the
suite **cannot** leave rows behind — and its teardown at `:204-207` is explicitly labelled "belt
and braces" for that reason.

The real defect is at **`phase2-contract.sql:17`**:

```sql
v_client uuid := '5470a95f-bcae-4e01-b2be-7c16964fa432';
```

The suite **hardcodes a shared, real QA user** and then inserts an `in_progress` session for them
(`:104`). `workout_sessions_one_active_per_user` (migration `108:98`) permits one active session
per user, so the moment that real account has an active session — ordinary QA usage is enough —
the fixture insert fails and the suite dies before its report banner. **It is an unsound
precondition, not a cleanup failure.**

**Deliberately not fixed here.** The remedy is a judgement between two options that belong to
`SEC-11`: make the suite self-isolating (clear the active session *inside* its own rolled-back
transaction, which alters no QA data), or treat a stuck active session as a finding in its own
right. Choosing for them — and editing another finding's test asset — is out of scope. **No QA row
was deleted, rewritten or reset, and no assertion was weakened or suppressed.**

### 40.4 K-04 — every rung evidenced, and still not closed

| Rung | Evidence |
|---|---|
| FIXED IN CODE | migrations 138 + 139 committed |
| FIXED ON QA | ledger `139`; trigger, `WITH CHECK` and the revoke all in the live catalog |
| VERIFIED LIVE | `d11` on QA **2/8 → 9/9**, each verdict a status **plus** a service-role read-back, with an anti-vacuity precondition |
| VERIFIED IN CI | `d11` **9/9** in runs **36596636664** and **36603451032**; the tree-sensitive guard green in both Flutter jobs |
| §5.2 grants preservation | **`PASS SP-5 … : 0`** on QA in run 36603451032 |

Under **Security / authorization** this closes. **It is not closed, for one reason:**

This finding carries the **`BIL`** prefix, its title leads with *"A paid event ticket can be
self-granted"*, and §2.1's **Billing / entitlement** row demands *"**VERIFIED LIVE** against
Stripe **test mode**"*. That rung is **not evidenced and was never attempted** — and arguably does
not map onto this defect at all, since the self-grant bypasses Stripe entirely and the control is a
Postgres trigger verified at the layer it operates.

**The standard does not say how to classify a finding that is both.** It does say
*"no partial closures and **no exceptions granted at implementation time**"* — and deciding, at
implementation time, that the lenient class applies is precisely what that forbids. **So the class
determination is left to the owner and K-04 stays `REMEDIATED`.** The registry entry records the
full evidence and names the single missing item, so closure is a one-line ruling away.

*(§39.9's caveat also stands and is recorded: FG-2a keeps the workflow red, so any closure must
state in the entry that the red is identified, attributed to `SEC-11`, and touches nothing K-04
owns.)*

### 40.5 State

Production never contacted. `MASTER_PRODUCT_DECISIONS.md` untouched. `PD-A24`/`PD-A17` untouched.
§24.3 unchanged — no rollback, still **FIXED ON QA**. `d09` still untracked and unadopted. No QA
data altered beyond the probes' own self-cleaning fixtures.

---

## 41 · K-04 **VERIFIED_CLOSED** · FG-2a REPAIRED · CI GREEN

### 41.1 The owner class ruling, and K-04's closure

**OWNER RULING 2026-09-29: `BIL-3`/`K-04` is classified Security / authorization / database
integrity for closure purposes.** The bypass is in the **database write path** and the remediation
is a PostgreSQL integrity/authorization control, so the control is verified at the layer where it
operates. §2.1's **Billing / entitlement** *"VERIFIED LIVE against Stripe test mode"* rung is
**not** required here merely because the finding carries the `BIL` prefix or touches
`paid`/`payment_id`. **The ruling is scoped: it claims nothing about Stripe or payment flows
generally.** It is recorded in the registry entry itself so the reason is explicit.

`BIL-3`/`K-04` → **`VERIFIED_CLOSED`**, with all four rungs evidenced:

| Rung | Evidence |
|---|---|
| FIXED IN CODE | migrations **138** + **139** committed |
| FIXED ON QA | ledger `139 \| 139 \| 139`; trigger, `WITH CHECK` and `REVOKE ALL … FROM PUBLIC` all in the live catalog |
| VERIFIED LIVE | `d11` on QA **2/8 → 9/9**, each verdict an HTTP status **plus** a service-role read-back, with an anti-vacuity precondition. **No rollback was needed** |
| VERIFIED IN CI | `d11` **9/9** in runs `36596636664`, `36603451032` and `36605282711`; the tree-sensitive guard green in every Flutter job, and §35.3 proved it **fails** on a 138-less tree |

**§5.2 grants preservation — satisfied.** `SP-5` transitioned **`1 → 0`** after 139, confirmed
authoritatively by CI; `FG-1` moved to `5 PASS · 0 FAIL`. The legitimate vendor check-in still
returns `204 affected=1`, so the bypass is closed without breaking the feature.

### 41.2 FG-2a repaired — a precondition, not hygiene debt

My earlier sections (§37.4, §38.3) called this a leftover row or a missing cleanup. **Both were
wrong, and the correction stands recorded.** `phase2-contract.sql` ends by `RAISE`-ing its report,
so the whole `DO` block rolls back and the suite **cannot** leave a session behind — its own
teardown is even labelled *"belt and braces"* for that reason.

The defect was line 17: it **hardcoded a single real QA account** and then inserted an
`in_progress` session for it. `workout_sessions_one_active_per_user` permits one active session
per user, so the moment that shared account had a live session — ordinary usage, **not** a defect —
the setup was refused with `23505` and the suite died before emitting its banner.

**Fix:** the client is now selected deterministically from the demo fixture population, and only
from rows that **already satisfy** the precondition. A user with a live session is simply not
selected. If no eligible fixture exists the suite raises a specific setup error rather than
skipping, because *"no eligible fixture"* is a different diagnosis from *"an assertion broke"*.

**No QA row was deleted, rewritten or reset. No assertion was weakened, suppressed or removed.**
`SEC-11`'s own finding (migration 120) is untouched — the defect was in its **test asset**, not in
the control it guards.

### 41.3 CI GREEN — run `36605282711` at `3dc73bd`

**All seven jobs `success`**, including `UIX-1` and `I-WRK-01`, which had been skipped in the two
previous runs because `live-qa` failed. Every step of `live-qa` executed, none skipped — checked at
step level per §35.5, not taken from the job colour.

| | |
|---|---|
| `Live security suite` | **396/396 across 10 suites**, incl. **`K-04 9/9`** |
| `Live AI suite` | 49/49 across 5 suites |
| `FG-1` | `PASS SP-5 … : 0` |
| `FG-2a` | **`RESULT: PASS`** |
| `FG-2b`, `F-J-17`, `F-J-07`, `ENV-3` | PASS |
| `Static guards`, `Flutter`, `API`, `Negative control` | success |

**This is the first fully green CI run of the programme.**

### 41.4 Unchanged

Production **never contacted**. `MASTER_PRODUCT_DECISIONS.md` untouched. `PD-A24`/`PD-A17`
untouched and unresolved. **§24.3 unchanged — `FIXED ON QA`, not `VERIFIED LIVE`; no rollback was
performed.** No migration history rewritten. `d09-assessment-access.mjs` still untracked and
unadopted (§36.4).

---

## 42 · N-07 / `d09` — ADOPTED AND GUARDED, DELIBERATELY NOT REGISTERED

§36.4 recorded `d09-assessment-access.mjs` as untracked, unregistered, write-heavy and unguarded,
and said the choice was *adopt-and-guard or delete*. The evidence settles it: **adopt.**

### 42.1 Provenance — established from the repository, not the filename

| Evidence | Finding |
|---|---|
| `git log --all -- d09…` | **zero commits, on every branch.** It existed only in this working tree and would have been lost with the directory |
| file mtime | `2026-09-24 10:17` |
| `docs/proposed/N07_assessment_access.sql` | exists, `2026-09-24 10:16` — **written one minute before the probe** |
| `d09`'s own header | *"Every assertion below requires the proposed migration in `docs/proposed/N07_assessment_access.sql`, which is authored and NOT applied … this suite fails by design. That is the pre-fix reading, not a defect … **Do not delete it to make the runner green.**"* |

**Classification: a legitimate security probe pre-staged with its proposed migration (C/E), not an
abandoned experiment and not a duplicate.** The author anticipated exactly this conversation and
left the instruction in the file.

### 42.2 Why it cannot run today

`get_client_assessment()` and `assessment_access_log` **do not exist** — zero references in
`supabase/migrations`, zero in the live QA catalog. All seven RPC assertions would fail on a
*missing function*, not on a boundary.

And the migration that would create them is blocked: `FINAL_SCREEN_INVENTORY.json:1523` records
**"OD-30 coach access to PAR-Q (blocks N-07)"**, with `blocked_by: OD-30` on the N-07 entry;
`SECURITY_LEDGER_PHI.md:138` records the audit table as *"SECURITY GAP — REMEDIATION REQUIRED …
has never been applied"*. **OD-30 is an owner decision and is not resolved here.**

### 42.3 Coverage — unique, but only of things that do not exist

| Surface | Covered elsewhere? |
|---|---|
| `get_client_assessment()` RPC path (7 assertions) | **nowhere** — but the function does not exist |
| `assessment_access_log` audit write (1 assertion) | **nowhere** — but the table does not exist |
| medical/PAR-Q columns on the base table | **yes** — `d02` (9 refs), `d10` (3), `d01` (1) |

So registering `d09` today would add **no coverage of any behaviour that exists**, while turning a
green baseline permanently red with no path to green. That is the opposite of what the ratchet is
for.

### 42.4 What was done

**Adopted:** the file is now committed, so the asset survives the working directory — which was
§36.4's actual complaint.

**Guarded:** a positive `QA_REF` allowlist matching `d07`/`d08`/`d10`/`d11`, verified to refuse a
non-QA target before any database work. This suite needed it more than any other in the directory:
its arrange step issues `service_role` **DELETE**s against `coach_client_relationships` and
`assessment_access_log` filtered only by `client_id`. Pointed at the wrong project that is
destructive, not merely wrong.

**Not registered**, and the two conditions that release it are written into the file itself:

1. N-07's migration numbered, applied, and its objects present — which needs **OD-30** first.
2. The arrange step must stop mutating **shared** fixture state. `reset()` deletes every
   `coach_client_relationships` row for the victim — the same fixture `d01` asserts on. **This is
   the cross-suite contamination class that made a `d11` assertion vacuous in §33.4**, and it must
   be fixed *before* this suite ever runs alongside the others.

**Not deleted**, and not run against shared QA.

### 42.5 Boundary

`d09` is now safe, preserved and honestly labelled. Taking it further requires **owner decision
OD-30**, which gates N-07's migration. That is a second owner decision alongside `PD-A24`/`PD-A17`,
and it is not inferred or resolved here.

---

## 43 · DECISION RECONCILIATION — `OD-30` IS NOT A BLOCKER; THE REAL GATE IS `OD-56`

Preparation only. **No owner decision is made, `MASTER_PRODUCT_DECISIONS.md` is untouched, nothing
was applied, registered or deployed.** Each ID was re-read from the current repository rather than
carried over from a prior handoff — and one of the three turned out to be wrong.

### 43.1 ⚠ `OD-30` does not block N-07 — it is a known ID collision

My §42 reported "N-07 is blocked on owner decision OD-30", sourced from
`FINAL_SCREEN_INVENTORY.json:1523` (*"OD-30 coach access to PAR-Q (blocks N-07)"*). **That is
stale, and the repository already says so in two places:**

- **`QA_EVIDENCE.md:4634`** names `OD-30` explicitly as a **collision** — *"a calorie constant vs a
  PAR-Q privacy question … two registers, two owners, one counter"* — and instructs that
  **`N-07` on its own should be treated as ambiguous**. `QA_EVIDENCE.md:3131` assigns `OD-30` to
  the fabricated `_elapsedSeconds ~/ 60 * 8` calorie figure, which is a different matter entirely.
- **`QA_EVIDENCE.md` §3ch** is titled **"N-07 is BUILT AND SHIPPED — the commission document is
  stale"** and refutes the premise directly: `client_detail_screen.dart` carries a live
  `TabBarView` with `Assessment` and `PAR-Q` tabs rendering `parq_answers`, `medical_conditions`,
  `has_injuries`, `injury_locations`, `injury_description`, `risk_level`, `risk_score` and
  `risk_flags`. **Corrected conclusion, verbatim: *"N-07 is not a missing screen. It is a shipped
  PHI viewer whose authorization model is the open question."*** Flagged there as **`OD-54`**.

**`OD-30` is therefore removed from the blocker list.** It was never the gate.

### 43.2 The real gate is `OD-56` — and it is narrow

`SECURITY_LEDGER_PHI.md:139` (**SEC-PHI-AUDIT**, *"no PHI access logging exists"*):
**Governance blocker — "Migration number + owner sign-off (`OD-56`)."**
`QA_EVIDENCE.md:5748` and `QA_REMEDIATION_FINAL_REPORT.md:104` agree: *"SEC-PHI-AUDIT, N-07 —
**BLOCKED (OD-56)** — Migration number + sign-off."*

`N07_IMPLEMENTATION_STATUS.md` §4 explains why nothing landed, and **none of the gates is a
privacy or clinical policy question**: `MASTER_REMEDIATION_WAVES.md` §0.2 assigns migration
numbers `132+` *"at wave entry, never before"*, and the hygiene guard fails on any untracked
migration, so the file cannot be created without being committed in the same change.

### 43.3 ⚠ The one genuine privacy question in N-07 is ALREADY ANSWERED by V5's own work

`N07_IMPLEMENTATION_STATUS.md` §2 recorded as **"Still open"**: *"the base-table exposure is
unchanged. The RPC does not fix it and never claimed to … Narrowing it is a separate decision with
regression cost on two coach/vendor screens."* Its §7 next-step 2 asks the owner to *"rule on the
§2 base-table exposure (S-N07-a)"*.

**That ruling has since been made and implemented.** The two arms it names were removed:

| Arm | Removed by | Recorded |
|---|---|---|
| `is_team_lead_of` | **migration 132** | §21.2 — *"corrected `SEC_PHI_1` — team-lead arm"* |
| `hosts_event_for` | **migration 135** | §21.2 / §23 — `QAX-SEC-09` |

The live QA policy is now `USING ((id = auth.uid()) OR is_active_coach_of(id))` — verified in the
post-139 dump. **`d09`'s `S-N07-a`** (*"a team lead cannot read a member's medical columns"*,
written to **fail**, `d09:203-205`) **would now pass.** Both coach/vendor screens were preserved by
giving them column-limited views instead (`team_member_profiles`, `event_attendee_profiles`), which
is the "regression cost" the 2026-09-24 note was worried about.

**So N-07's substantive privacy decision is settled by evidence and is not an owner question.**
What remains under `OD-56` is governance: a wave-entry migration number and sign-off.

### 43.4 `PD-A24` and `PD-A17` — verified current, and each is narrower than reported

Both re-read from `MASTER_PRODUCT_DECISIONS.md`. Both are genuinely open, and **both have a half
the document already marks as proceeding without a decision**:

- **`PD-A24`** — *"Observability vendor, cost, and data-residency posture."* Blocks
  `EC-01`, `REL-26`, `LRE-27`, `LRE-28` — **it does not list N-07 or `d09`.** Proceed column:
  **"Partly — the sink is unconditional and is Wave 3B-0"**, with the recommendation that
  *"the sink abstraction (`reportFailure`) can and should be built **before** the vendor is
  chosen — it is one interface."*
- **`PD-A17`** — *"Where does the NestJS API run, and does the parallel auth stack stay?"*
  Proceed column: **"Partly — the stack removal proceeds now"**, with the recommendation
  *"decide the platform; **delete the parallel stack regardless** … unused authentication is
  unmaintained attack surface."*

### 43.5 Net effect

The blocker list changes from **three owner decisions** to **two open decisions plus one
governance sign-off**, with three work items already released by the documents themselves (the
observability sink, the parallel-auth-stack deletion, and N-07's base-table ruling). The
consolidated packet is delivered to the owner separately.

---

---

## 44 · THE TWO DECISION-INDEPENDENT ITEMS — ONE EXECUTED, ONE ALREADY DONE

The consolidated packet arrived with all three decision slots **unfilled** — `PD-A24 = A / B / C`,
`PD-A17 API = A: ____ / B`, `OD-56 = A / B` are option lists, not selections, and the packet says
engineering proceeds *"once these three decisions are supplied"*. **No owner decision was inferred
or made.** But the same message explicitly released two items, and both are now settled.

### 44.1 ✅ PD-A17's auth-stack half — EXECUTED

*"DELETE THE PARALLEL AUTH STACK = AUTHORIZED NOW. No separate owner decision is required for that
portion."* — and `PD-A17`'s own record: *"unused authentication is unmaintained attack surface …
delete the parallel stack regardless."*

**Deleted:** `auth.controller` (`/auth/register`, `/auth/login`), `auth.service`, `auth.module`,
the `firebase` and `jwt` strategies, the `jwt-auth` and `roles` guards, the `roles` decorator, the
login/register DTOs, and the whole `users` module (`/users`) — unwired from `app.module`. Packages:
`@nestjs/passport`, `bcryptjs`, `firebase-admin`, `passport`, `passport-jwt`, and their `@types`.

**Kept:** `auth/supabase/*`, now the API's only authentication. **`@nestjs/jwt` was deliberately
NOT removed** — `supabase-auth.module` and `supabase-token.service` both use it, so removing it
would have broken the live path. That is the one trap in this change.

**Checked before deleting, not after.** `ai.controller` uses `SupabaseAuthGuard`; the mobile app
calls no `/auth` or `/users` route; the only inbound references were `app.module` and
`auth.module`'s own import of `UsersModule` — a closed island. Remaining routes: `@Controller()`
and `@Controller('ai')`.

**⚠ A claim I made here was wrong, and is corrected rather than quietly dropped.** I first
reported that *"the root lockfile never contained `firebase-admin`, `passport-jwt` or `bcryptjs`"*
and offered it as evidence the stack was dead. **It is false.** My grep pattern missed them:
`git show 23e2310:package-lock.json` matches all **three** entries. The lockfile carried the entire
`firebase-admin` dependency tree — removing the packages from the workspace manifest deleted
**1702 lines** from it. This is the **third** time in this programme a failed grep has read to me
as an absent fact (§30.5 records the first two), and the lesson there evidently did not take.

The stack is dead on the evidence that actually holds — no inbound reference, no route called by
the client, `ai.controller` on `SupabaseAuthGuard` — not on that one.

**Consequence, and it mattered:** the lockfile had to be synced in the same change. `npm ci` fails
on a manifest/lockfile mismatch, so committing the manifest edit alone would have broken **every**
CI job at the install step.

**Verified:** 54 unit + 6 e2e pass (from 58 + 6; the four removed suites were the deleted modules'
own specs), `tsc --noEmit` clean, `npm ci --dry-run` in sync, and **CI run `36619448820` green
across all seven jobs including `API — unit + e2e`.**

**This decides nothing about where the API runs.** `PD-A17`'s platform half remains open.

### 44.2 ✅ PD-A24's sink half — ALREADY DONE, and the packet understates it

The packet lists the observability sink as *"already authorized … buildable now"*. It is not
merely buildable — **it is built, shipped and closed.**

`EC-01` (= `REL-26`, `LRE-27/28`, `EC-23`) is **`VERIFIED_CLOSED` 2026-08-27**:
`lib/core/observability/app_failure.dart` provides `AppFailure`, `FailureSink`, `reportFailure`
and `reportError`, **vendor-free per PD-A24**, with 7 guard tests in `error_sink_test.dart`.
Its closure carries both rungs its RELEASE / ENVIRONMENT class demands, including a strict §2
pre-fix half — run `#34` step 7 shows the `EC-23` guard failing against a tree carrying the seven
historical `print()` sites and passing against the restored tree, in CI.

**So there is no sink work to do.** `PD-A24`'s remaining scope is purely the telemetry/vendor
posture, and nothing in the repository is waiting on the interface.

### 44.3 What is now genuinely blocked

With both released items settled, **every remaining workstream sits behind one of the three
unfilled decisions.** There is no reachable engineering work left that does not require one.


---

## 45 · OWNER DECISIONS APPLIED · N-07 LANDED · SEC-PHI-AUDIT **VERIFIED_CLOSED**

Lead decisions of 2026-09-29 recorded and applied: **`PD-A24 = C`** (sink only, defer vendor),
**`PD-A17 = A`** (deploy the NestJS API), **`OD-56 = A`** (approve N-07). None was inferred.

### 45.1 PD-A24 = C — nothing to build

The sink was already `VERIFIED_CLOSED` as `EC-01` on 2026-08-27 (§44.2), vendor-free by
construction. **`C` is satisfied by the existing implementation**: the abstraction stays, no
third-party vendor is introduced, and the choice remains reversible behind one interface.

### 45.2 OD-56 = A — N-07 landed, and three defects surfaced only by running it

`140` was **verified free, not assumed**: authored migrations topped out at 139, the QA ledger read
139, the declared frontier was 139. `docs/proposed/N07_assessment_access.sql` moved to
`supabase/migrations/140_assessment_access.sql`. One deliberate change on landing — `SET search_path`
widened from `public` to `public, pg_temp`, because §30.2 recorded that the four weakly-pinned
functions are the whole authorization surface and landing a fifth onto the PHI surface would be a
step backwards.

**The suite had only ever been authored** — `N07_IMPLEMENTATION_STATUS.md` §5: *"None of these has
been executed."* Executing it surfaced **three defects, none visible from source review**:

| # | Defect | Symptom |
|---|---|---|
| 1 | **140 declared `sleep_hours numeric`; the column is `text`** | PostgreSQL validates a `RETURNS TABLE` signature at **execution** time, so 140 applied cleanly and then raised **`42804` on every call**. Authorization was never at fault — `is_active_coach_of(victim)` returned `true` in the same session. Repaired by **141** (drop + recreate; a return type cannot be changed by `CREATE OR REPLACE`). 140 is **not** rewritten in place — the shape 137 used for 136. |
| 2 | **`d09` called `signIn()` and discarded the tokens** | It passed the literal strings `'coach'`/`'attacker'`/`'victim'`/`'admin'` as `lib.mjs`'s `who`, which sends them verbatim as `Authorization: Bearer coach`. QA answered **401 to all eighteen assertions, and seven scored that blanket rejection as a PASS.** |
| 3 | **All four fixture writes were double-encoded** | `svc()` stringifies `body` itself (`lib.mjs:156`); `d09` passed `JSON.stringify(...)`. Every write was rejected, and because the arrange **discarded its result** it silently did nothing — no coach-of-record relationship, so §1's coach was correctly 403'd and every audit assertion failed downstream. The arrange now **throws** if the write fails. |

`N07_IMPLEMENTATION_STATUS.md` §6 claims all 36 column types *"were verified against the migrations
before writing; five type errors were caught and corrected"*. Defect 1 was the sixth. **This is the
concrete vindication of §42's refusal to register `d09` on the strength of it being "authored".**

**Also fixed: `d09`'s `reset()`** deleted **every** `coach_client_relationships` row for the victim —
the authorization root `d01` asserts on. Now scoped to the two pairs `d09` owns. **`D-01` still
reads 43/43**, which is the evidence the scoping worked.

### 45.3 SEC-PHI-AUDIT → **`VERIFIED_CLOSED`**

| Rung | Evidence |
|---|---|
| FIXED IN CODE | 140 + 141 committed |
| FIXED ON QA | ledger `141 \| 141 \| 141`; table, RLS, both policies and the function verified in the live catalog |
| VERIFIED LIVE | `d09` **18/18 on QA** — coach 200/36 cols, unassigned 403, anon 401, **ended relationship 403**, audit row naming actor/subject/event/time, subject reads own log, third party 0 rows, `UPDATE` **and** `DELETE` both **403** |
| VERIFIED IN CI | `d09` 18/18 inside **414/414 across 11 suites** (runs `36625112249`, `36626036076`), **plus** a tree-sensitive guard in `phase1_security_boundary_test.dart`, proven to fail when 140/141 are removed |

The guard exists because **`d09` cannot be the CI rung** — its verdict comes from QA's database
state, not the checked-out tree, exactly as §35.3 established for `d11`/K-04. One of my own guard
assertions was wrong and **failed loudly rather than passing vacuously**: it matched 140's *header*,
which legitimately names both removed policy arms while explaining their exclusion; it now strips
comments and asserts on executable SQL only.

**A by-product worth recording:** `d09`'s `S-N07-a` — written to **fail**, asserting a team lead
cannot read a member's medical columns — now **PASSES**, confirming §43.3's reconciliation that
migrations 132 and 135 already answered N-07's base-table question.

### 45.4 State

CI **green** across runs `36625112249` and `36626036076`; 414/414 live security assertions,
0 aborts; `SP-5` still 0; `ENV-3` `L-5` reads 142 vs 142. QA frontier **141**. Production never
contacted. `MASTER_PRODUCT_DECISIONS.md` untouched.


---

## 46 · PD-A17 = A · THE PLATFORM IS NOT DETERMINED BY THE ARCHITECTURE — AND THERE IS A THIRD OPTION

`PD-A17 = A` authorizes deploying the NestJS API, with the instruction *"do not assume a platform
… resolve the platform implementation from the existing architecture/evidence and stop only if an
actual owner decision is required."* The evidence was gathered; it resolves to **a boundary**, and
it also surfaces an option the packet did not contain.

### 46.1 Nothing in the repository determines a platform

| Searched | Result |
|---|---|
| `Dockerfile`, `docker-compose.yml`, `Procfile`, `fly.toml`, `vercel.json`, `render.yaml`, `railway.{json,toml}`, `app.yaml`, `nixpacks.toml`, `captain-definition`, `.dockerignore` | **none exist anywhere** |
| a deploy job in `.github/workflows/` | **none** |
| any hosting precedent (firebase / vercel / netlify / cloudflare / amplify) | **none** |
| a documented platform candidate in `docs/` | **none** — the only `vercel` hits are an MCP-plugin audit, not deployment |

This matches `PD-A17`'s own wording — *"No deployment target of any kind exists"* — and its
assessment that the platform *"is a cost and ops commitment and is genuinely open."*
**The architecture does not choose for us.**

### 46.2 What would actually be deployed — one endpoint

The API's entire live surface, after §44.1 removed the parallel auth stack:

- `POST /ai/nutrition/message` — `ai.controller.ts`, guarded by `SupabaseAuthGuard`
- `GET /` — a health route

Runtime requirements: `ANTHROPIC_API_KEY`, `ANTHROPIC_MODEL`, `ANTHROPIC_MAX_TOKENS`,
`SUPABASE_URL`, `SUPABASE_JWT_SECRET`, `CORS_ORIGINS`, `PORT`.

### 46.3 ⚠ The third option — the project already runs this class of workload

`supabase/functions/` holds **19 deployed Edge Functions**, and **three of them are already
Anthropic-calling AI endpoints**: `ai-coach`, `ai-coaching-engine`, `ai-generate-workout`. They are
already authenticated, already hold the Anthropic key, already carry a JWT posture that
`check:guards` enforces (*"all 19 functions declare a JWT posture"*), and already have a deployment
path. **There is no `ai-nutrition` function — that one endpoint is the only reason the NestJS API
needs to exist at all.**

So the real choice is wider than the packet's A/B:

| Option | Consequence |
|---|---|
| **A1 — deploy NestJS to a new platform** | A new hosting account, cost and ops commitment, secret management, CORS config and a CI deploy path, to serve **one** endpoint. Keeps the Nest codebase and its tests. |
| **A2 — port `/ai/nutrition/message` to a Supabase Edge Function and retire the API** | **Zero new platform.** Reuses infrastructure that is already deployed, authenticated, CI-guarded and holds the same Anthropic key. Retires `apps/api` — and with it `API_BASE_URL`, `ENV-8`, and the `REL-28/29/30` and `LRE-14/22/23/38` cluster, which exist *because* an undeployed API is referenced. Cost: the Nest service, its DTO/validation layer and its 60 tests are rewritten as a Deno function. |

**A2 is not proposed as a decision and is not taken.** It is surfaced because it is materially
cheaper on the evidence, because the packet's A/B did not contain it, and because choosing A1
without seeing it would commit real money and ops surface to serve a single endpoint whose three
siblings already run elsewhere. **Retiring a whole application is a product/architecture decision,
not an implementation detail** — it is exactly the kind of thing §25.4 warned against deciding
inside another workstream.

### 46.4 Why this is a genuine boundary

Both remaining paths require something only the owner can supply:

- **A1** needs a **named platform** — a cost and ops commitment `PD-A17` itself calls genuinely open.
- **A2** needs authorization to **retire `apps/api`**, which is an architectural decision about the
  product's backend shape.

**No platform was assumed, nothing was deployed, and `apps/api` was not touched beyond §44.1's
authorized auth-stack removal.**


---

## 47 · A2 EXECUTED — THE EDGE PORT IS LIVE; RETIREMENT BLOCKED ON A MISSING QA SECRET

`PD-A17 = A` resolved as **A2**. The evaluation cycle was run in the order the lead set, and it
stops at step 6 — **`apps/api` is NOT retired.**

### 47.1 Steps 1–3 · Inventory and mapping — **complete, no capability lost**

The API's only live surface was `POST /ai/nutrition/message`. Every requirement maps:

| Requirement | Edge equivalent | Evidence |
|---|---|---|
| Auth: HS256 JWT, `role = authenticated` | `verify_jwt = true` **plus** an explicit `getUser()` check | the pattern `ai-coach` and `analyze-food-image` already use |
| Base64 image + `mediaType` → Anthropic image block | identical | **`analyze-food-image` already does exactly this, deployed, and the mobile app already invokes it** |
| Anthropic call with system prompt / model / max_tokens | `fetch` to `api.anthropic.com` | the house pattern in five existing functions |
| `ValidationPipe({whitelist, forbidNonWhitelisted})` | hand-written `validate()` | reproduced explicitly, including refusing unknown properties |
| Generic 503, detail logged never returned | identical | ported verbatim |
| Image size | equivalent | both paths send `imageQuality: 80`; `analyze-food-image` already carries this load |

**No capability requires a persistent NestJS deployment.** The one genuine delta is test
infrastructure: the repo has **no Deno test harness** — its nineteen functions are covered by Dart
guards that parse `index.ts` plus the live suites — so the 54 Jest unit tests could not be ported
like-for-like. That is a verification-tooling gap, not a runtime capability.

### 47.2 Steps 4–5 · Implementation and coverage

`supabase/functions/ai-nutrition/index.ts`, registered `verify_jwt = true` (`check:guards`: **all
20 functions declare a JWT posture**). The client keeps **Dio** and changes only the URL — which is
precisely what made the port verifiable: of the 14 tests in `ai_nutrition_client_test.dart`, the
**12 covering authorization, payload shape, the `{ text }` field and every status mapping are
unchanged and still pass.** Only the AI-001 URL assertions moved, and two were added for the
trailing-slash join and for the anon key riding alongside the user token.

`flutter analyze`: **0 errors**. Full mobile suite: **1698 tests pass**. CI green across all seven
jobs (`36635440465`).

### 47.3 Step 6 · QA verification — and a real defect it caught

Deployed to QA. The first probe returned **503 for five validation cases that should have been
400**. Cause: I checked `ANTHROPIC_API_KEY` **before** validating, while Nest's order is
guard → `ValidationPipe` → service, so a malformed body was a 400 *whether or not* the server held
a key. Fixed and redeployed. **A source review would not have found this; the live probe did.**

| Probe | Result |
|---|---|
| no token / garbage token | **401** (gateway) |
| unknown property | **400** `property bogus should not exist` |
| empty message · over 8000 chars | **400**, exact messages |
| unsupported media type · history over 40 turns | **400**, exact messages |
| **valid authenticated request** | **503 `AI is not configured`** |

### 47.4 ⚠ THE BOUNDARY — `ANTHROPIC_API_KEY` is absent from QA

`supabase secrets list` on QA returns only Supabase's own defaults. The key is **not set**, and
**six** functions read it — including the already-shipped **`ai-coach`**, **`ai-generate-workout`**
and **`analyze-food-image`**. So every AI Edge Function on QA is unconfigured. **This is
pre-existing and was not introduced here.**

Consequence: the happy path cannot be exercised on QA, so **step 6 is incomplete**, and step 8's
*"only then retire"* is not satisfied. **`apps/api` therefore stands.** Setting a paid credential
on a shared environment is an owner action — the key is not mine to invent or install.

**Nothing of value is at risk in the meantime.** The NestJS route was never reachable either:
`API_BASE_URL` was empty in **every** environment, so this feature could not work in any build
before this change, and cannot regress by waiting.

### 47.5 What retirement will involve when it is unblocked

Larger than deleting `apps/api`: `API_BASE_URL` is embedded in the mobile env contract
(`app_env.dart`, `resolveEnvConfig`, the required-vars list) and asserted across **six** test files,
and the CI web builds pass it by `--dart-define`. That is why §46 called it a cluster and why it is
staged behind the evidence rather than bundled into this change.


---

## 48 · A2 CAPABILITY MATRIX COMPLETED — ONE ROW WAS MISSING, AND IT MATTERED

§47 declared the mapping complete. It was **incomplete**: two rows the lead's Phase 1 list names
explicitly — **timeout/retry** and **logging/privacy** — had not been inventoried. Completing them
found a real behavioural delta.

### 48.1 The completed matrix

| Capability | Verdict | Evidence |
|---|---|---|
| Request/DTO contract | **PASS** | limits ported verbatim; live QA probe returns **400** with the exact message for all five cases |
| Authentication | **PASS** | `verify_jwt = true` + explicit `getUser()`; live **401** for absent and malformed tokens |
| Authorization | **PASS** | same as Nest — any authenticated user; no role gate existed to lose |
| Prompt construction | **PASS** | `NUTRITION_SYSTEM_PROMPT` verbatim; image block before text, as before |
| Anthropic request | **PASS** | model / `max_tokens` / `system` / `messages` identical |
| Model configuration | **PASS** | `ANTHROPIC_MODEL`, `ANTHROPIC_MAX_TOKENS` from env, as Nest read them from config |
| Image handling | **PASS** | `analyze-food-image` already does base64 + `mediaType` → Anthropic image block, **deployed and already invoked by the app** |
| Response schema | **PASS** | `{ text }`, text blocks joined and trimmed, empty → 503 |
| Error behaviour | **PASS** | generic 503, detail logged never returned |
| Secrets | **PASS** | server-side only; guard asserts the key can never reach a response body |
| **Timeout / retry** | **GAP — FOUND AND CLOSED** | see §48.2 |
| Logging / privacy | **PASS** | upstream failures logged **by status only**; no body, no key, no prompt |
| Dependencies | **PASS** | `@anthropic-ai/sdk` → `fetch`; `class-validator` → explicit `validate()`; `@nestjs/jwt` → gateway + `getUser()` |

### 48.2 ⚠ The gap: retry was part of the contract and the house pattern would have dropped it

`ai-nutrition.service.ts` constructed `new Anthropic({ apiKey })` and **overrode neither
`maxRetries` nor `timeout`**, so it inherited the SDK default —
**`maxRetries = 2`** (`@anthropic-ai/sdk/client.d.ts:207`).

The sibling functions `ai-coach` and `analyze-food-image` use a **bare `fetch` with no retry**. So
*following the house pattern faithfully would have silently removed two retries*, turning transient
`429`s and upstream `5xx`s into a user-visible *"The AI coach is temporarily unavailable"* far more
often. **That is client-visible, so it is contract, not embellishment.**

Closed: 2 attempts, exponential backoff, on the SDK's own retryable set
(`408/409/429/5xx` and connection errors), never on a `4xx` the caller can fix.

**This is the second time the house pattern was the wrong guide.** The first was §47.3's ordering
defect — the house pattern checks configuration early, while Nest's pipeline validates first.
Matching the neighbours would have been wrong both times; matching the *contract* was right.

### 48.3 Coverage — repository-native and shown non-vacuous

`AI-005` in `ai_nutrition_client_test.dart` asserts the **server** half: `verify_jwt = true`, the
persona server-side, all five limits and four media types, that an unknown property is **refused**,
that **validation precedes the configuration check**, retry parity, and that no failure path can
return the credential.

It is the repository-native mechanism — there is no Deno harness, and the other nineteen functions
are covered exactly this way. **Shown non-vacuous, not assumed:** with the function removed it
produces **7 failure signals**; restored byte-identical; passes again. **21 tests in the file pass**,
of which the **12 original client tests are untouched** — the evidence the port preserved the
contract.

### 48.4 Evidence ladder for the nutrition capability

| Rung | State |
|---|---|
| FIXED IN CODE | ✅ function, client repoint, guards committed |
| FIXED ON QA | ✅ deployed to `eyqtldjqpgpljlqvpowh` |
| VERIFIED LIVE | ⚠ **PARTIAL** — auth and all validation verified by live probe; **the happy path cannot be exercised** |
| VERIFIED IN CI | ✅ `AI-005` + the 14 client tests green in CI (`36646605521`) |

### 48.5 The boundary is unchanged, and Phase 5 stays closed

`ANTHROPIC_API_KEY` is **absent from QA's function secrets** — `supabase secrets list` returns only
Supabase's own defaults. **Six** functions read it, including the shipped `ai-coach`,
`ai-generate-workout` and `analyze-food-image`, so **every AI Edge Function on QA is unconfigured.**
Pre-existing; not introduced here.

Per the guardrail *"require evidence that the Edge implementation actually works against QA before
removing the NestJS implementation"*, and *"do not declare closure from static code inspection
alone"* — **`apps/api` stands and `API_BASE_URL` is untouched.** Installing a paid credential on a
shared environment is an owner action.

**Nothing is at risk while it waits:** `API_BASE_URL` was empty in every environment, so the NestJS
route was unreachable in every build. The Edge path is strictly better than what it replaces even
unconfigured — it returns honest `400`s and `401`s where the old path returned nothing at all.


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
