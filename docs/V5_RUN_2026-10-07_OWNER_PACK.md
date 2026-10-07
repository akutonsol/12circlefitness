# V5 autonomous run — 2026-10-07 — consolidated owner pack

**One pack, not a queue of questions.** Nothing here blocked the run: every item below was
either implemented under an existing authority and recorded, or deliberately left alone.
Each entry states what was done, so a "no change needed" answer is a valid answer.

**None of these is a decision you already gave me.** The METRIC-06b marketplace-scope
discrepancy recorded at §162.2 is **closed** by your 2026-10-07 clarification and is not
re-asked.

---

## A · Narrow confirmations — a word each

| # | Item | What was built | What I need |
|---|---|---|---|
| **A1** | **METRIC-02's weekly window** | `date_trunc('week')`. You ruled "calendar" for *"this month"* under METRIC-03 and the month-on-month delta only works on calendar months, so I applied the same convention to the week. | Confirm, or name a different week boundary. Recorded at §162.3 as **an applied convention, not an authorization**. |
| **A2** | **An age of 60 or above has no bucket** | METRIC-17 = Option 2 fixed the fourth bucket as `unknown`, leaving three labelled ranges covering `[18,60)` and nothing above. I did **not** invent a `60+` bucket. Those rows go to `age_out_of_range`, a reconciliation column that keeps the panel's total honest; D16 asserts the buckets reconcile at every boundary age. | Should `60+` become a real card bucket, or stay a reconciliation figure? |
| **A3** | **METRIC-16 / 18 / 19 are not in the non-operational register** | That register is keyed by `(area, verb)` **capability**, and these are Dashboard cards. Forcing them in would corrupt the one artifact D15 reads to keep the ruling and the test from drifting, so they are ledgered in §162 instead. | Confirm the ledger is the right home. |

---

## B · Architecture / modelling — genuinely undecided

**B1 · `weekly_feedback` has no defined subject when a program has several clients.**
`workout_programs` carries no subject column, so the subject can only come from
`workout_program_assignments` — and a program may hold **several** active assignments, while
`weekly_feedback` is `unique (program_id, week)`: one row per program-week for what could be
many people. Migration 175 derives `subject_id` **only** when there is exactly one active
assignment and leaves it NULL otherwise, because guessing would decide silently whose body a
coaching decision was made about. D17 proves the refusal.
**Decision:** should `weekly_feedback` become per-assignment, or is a program single-subject
by definition?

**B2 · `needs_approval` is NULL — not false — when the subject is undecidable.**
`evaluate_week` computes `(coaching_mode = 'coach_guided' and action <> 'CONTINUE') or
(rules && INJURY_ADAPTATION)`. With no subject, `coaching_mode` is NULL, so the whole
expression is NULL by three-valued logic. Every consumer treats null as falsy, so the
behaviour today is "no approval required". I asserted it **as null** rather than quietly
coalescing it, and did not change the engine to suit a test.
**Decision:** should an unknown coaching mode **require** approval (fail-closed), or not?

**B3 · CI ingestion for METRIC-11 is still unreleased.** Your ruling settled *what the card
shows* — both verdicts, labelled, never collapsed — and that is built (migration 173/174,
`admin_release_status`). The **ingestion** path is a separate item the data contract records at
`:220` as `C · ARCHITECTURE`, citing `P10`'s *"installation forbidden"* constraint and
`CONF-D9`, neither released. So the registry starts **empty** and the card renders `A11`; D16
asserts it is empty, so nobody can seed it to make the dashboard look finished.
**Decision:** release the ingestion path, or keep the registry recorded by deliberate act?

---

## C · Design authority

**C1 · The approved design package is not on this branch.** Commit `931218b`
(`design/12circle-plus-admin-dashboard`) publishes `admin.tokens.css`, `admin.contrast.md`,
`admin-icon-inventory.md`, `RESPONSIVE.md`, `SCREEN-INVENTORY.md` and `COMPONENTS.md`. **None
is an ancestor of `reconcile/12circle-integrated`**, so 17 citations across four documents
pointed at paths that resolve to nothing here (§164.1, §165). I did **not** merge the design
branch: the token layer is generated from that commit by `git show`, which is a stronger
citation than a path, and the four documents now carry a provenance block. A new guard fails
CI on any design citation that resolves nowhere.
**Decision:** merge the design branch into the integrated branch, or keep commit-pinned
citations?

**C2 · The Critical severity colour disagrees with the token set.** `COMPONENT-SPECS` ›
Severity badge records the observed colour as **`#f08a9b`, marked with no token** — and that
value appears **nowhere** in `admin.tokens.css`. I used `--adm-color-status-danger-text`
(`#f07a8c`), because the Helix rule forbids raw hex in a component and `admin.contrast.md`
publishes a **measured 7.4:1** ratio for the token while `#f08a9b` carries no measurement.
They are visually near-identical. Two further badge values are untokenised: `11.5px` (I used
the 11px overline token) and `0.08em` tracking (not the `0.12em` overline token).
**Decision:** add these to the token set, or confirm the token is correct and the observed
values are incidental?

**C3 · The design specifies Phosphor icons; the app has none.** `pubspec.yaml` carries only
`cupertino_icons`. `DESIGN-01` §1 names `ph-fill ph-warning-circle`, and I substituted a
Material fill-weight equivalent — **a substitution, not fidelity**.
**Decision:** add a Phosphor dependency, or accept Material equivalents?

---

## D · Recorded debt — no decision needed unless you want it prioritised

| # | Item |
|---|---|
| **D1** | Two legacy display coercions remain, recorded in `SEC-G4`'s shrinking allowlist: `observability_screen:62` and `admin_dashboard_screen:224` render a missing figure as `0` on the pre-token console. Rewriting another screen's data handling is a product call. |
| **D2** | `_saveProgress` Phase 2 is still `catch (_) {}` — the progressive autosave, with `_finish()`'s full upsert as its backstop. Interrupting the flow on every transient mid-step failure is a UX decision. |
| **D3** | `MASTER_REMEDIATION_REGISTRY.md` is outside this run's mutation boundary and was **not** edited, so `I-COM-01`, `EC-04`, `EC-03` and `ENG-02` still read `READY_TO_REMEDIATE` although their remediations are implemented and verified. Their records are §169–§172. |
| **D4** | `DESIGN-01` §2's `Guardian-approval-required` state remains unimplemented. That document deliberately stops short of specifying it, so there is nothing to build from yet. |
