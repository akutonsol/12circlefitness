# V5 · Consolidated owner decision pack — the complete reconciled queue

**Nothing was implemented for this pack.** It reconciles the carried queue against the
governing V5, programme and design sources, retrieves each decision's exact options and
evidence, states what each blocks, and recommends where the evidence supports one. **No option
is selected.**

**Design provenance.** `SCREEN-INVENTORY.md`, `BOUNDARIES.md`, `COMPONENTS.md`, `README.md` and
the six `.dc.html` screens live on the design branch at commit **`931218b`**
(`design/12circle-plus-admin-dashboard`), which is **not** an ancestor of this branch — read
them with `git show 931218b:<path>`.

---

## 0 · What the reconciliation changed, before the questions

Three corrections, all to my own bookkeeping. They are listed first because each one means a
previous pack told you something inaccurate.

| | correction |
|---|---|
| **Q14 · WITHDRAWN** | Already recorded in §197.4. I reported *"one cancelled relationship has no `cancelled_at`"*; **that reading was taken while my own `D01` fixture was live.** Measured clean (2026-10-08): **185 relationships, every one `active`, `cancelled_at` populated on zero rows** — an empty population, not a writer gap. The count drifts with QA activity; the property does not. And there is no gap: **three production paths** set it in the same write as the status (`coach_relationship_service.dart:104`, `profile_screen.dart:918`, `intake_flow_screen.dart:4188`). |
| **Q15 · PREMISE DISPROVED, a narrower question survives** | My pack carried `BOUNDARIES.md` row A's framing — *"approved screens show CRITICAL / HIGH / MEDIUM / LOW"*. **`METRIC-12` disproved that by reading all six pages: `CRITICAL` appears ZERO times**, and the uppercase `HIGH/MEDIUM/LOW` appears **only on Ecosystem**, attached to *"Harassment"*, *"Health misinformation"*, *"Spam"*, *"Off-topic"* — **moderation report priorities, a different object entirely.** `METRIC-12` is recorded `ALREADY SATISFIED` and you left it blank on 2026-10-07 with the evidence standing. **I inherited a stale framing from the design's own boundaries list instead of the verified one.** The surviving question is one value on one object — see `Q15` below. |
| **Q3 · RESTATED, it was too narrow** | I framed it as *"release METRIC-11's CI ingestion"*. **`METRIC-11` itself was never answered** (§162.7): the open question is **which authority the card shows**, not merely how to ingest. Restated below. |

**Four decisions were open in the programme record and absent from every pack** — `D-2`, `D-3`,
the `60+` bucket and `EC-01 Q2–Q5`. They are in §11, and they were found by the sweep in §12,
not by any earlier pass.

---

## 1 · Q1 · In which timezone is "today" measured?

**Exact source.** `V5_ADMIN_DASHBOARD_DATA_CONTRACT.md:98`, the `METRIC-02` row:

> **"B · OWNER — the central question** … Sub-questions the owner's answer must settle: which
> event(s) count · **the timezone the "day" is measured in** · whether a coach or partner counts
> as an "active user" or only clients."

So `Q1` and `Q2` are **two of three sub-questions of one parent**. `METRIC-02 = Option 3`
answered only the first — *"does a sign-in with no Session count as active?"* → **both bases,
shown separately.** The other two were not covered.

**What is shipped.** Migration **176 publishes the boundaries rather than choosing them**:
`day_start`, `week_start`, `month_start` and `window_timezone` are columns, and the card renders
*"Day begins 2026-10-07 00:00 UTC"*. The live value is **UTC**, because that is the database's
timezone.

**A second unruled boundary sits with it.** The decision sheet records of `METRIC-02`: *"The
weekly window is `date_trunc('week')` — an applied convention, **not** an owner ruling."*
§162.3 repeats it: *"recorded here as an applied convention, not an authorization."* In Postgres
`date_trunc('week')` starts **Monday**.

**Options.** `1` UTC, ratifying what ships · `2` a single fixed business timezone (e.g.
Europe/London), with the card restating it · `3` the viewer's local timezone · `4` per-tenant,
which needs a tenancy model that does not exist. **Week start:** `a` Monday, ratifying
`date_trunc` · `b` Sunday.

**Blocks:** nothing. The figures are correct and self-describing today. It changes what DAU
*means*, not whether it computes.

**Recommendation — `1` + `a`, i.e. ratify.** Two reasons, and neither is "it is already built":
the figures are **disclosed on the surface**, so a reader is never misled about which day was
measured; and a timezone change is a **one-line change to 176's window columns** with the
disclosure updating itself, so deferring costs nothing and ratifying loses nothing. `3` is the
only option I would argue against — a per-viewer "today" makes two operators disagree about the
same number.

---

## 2 · Q2 · Does a coach or partner count as an "active user", or only clients?

**Exact source.** The same line — `…:98`, third sub-question.

**What is shipped.** The counts are over **every** user with a Session, **no role filter**. No
filter was invented because selecting one is the business definition the contract names.

**Evidence that bears on it.** `METRIC-03` separately counts **active coaches** on the
relationship signal, and §162.4 records that on QA *"1 active coach of 135"* is **correct** —
*"of the 118 distinct `coach_id` values on active rows, only one belongs to a profile with
`role = 'coach'`; 59 of the first 60 hold `role = 'trust_operator'`"*, which is QA seed noise.
So coach activity already has its own measure on its own signal.

**Options.** `1` all users, ratifying what ships · `2` clients only · `3` all users, with the
role split published beside the total.

**Blocks:** nothing.

**Recommendation — `3`.** The split is **mechanically available** (`user_profiles.role` is on
the same population already being counted) and it is the only option that cannot be wrong: it
answers `1` and `2` simultaneously and lets the reader apply whichever definition they meant.
`1` and `2` each discard information the surface already has.

---

## 3 · Q3 · `METRIC-11` — does the release card show the V5 gate ledger or CI status?

**Restated, because my earlier framing was too narrow.**

**Exact question, from `V5_METRIC_DECISION_SHEET.md`:**

> *"does the card show the **V5 gate ledger** or **CI status**? They disagree today (CI green,
> 8 of 15 gates FAIL)"*

**Options.** `1` CI · `2` gate ledger · `3` both, labelled.

**Evidence established, verbatim from the sheet.** *"The disagreement is live and current: CI
is green 6/6 … while `RELEASE_GATES` still records failing gates. The approved card shows a
`BLOCKED` badge beside "Release 4.2.0 · staging", "Build: Passing" and "Automated QA: 1,412 /
1,418" — a gate verdict and a CI verdict **side by side**, which is evidence that the card
already contemplates both. No ingestion exists for either."*

And: *"**STILL OPEN — the one metric on this sheet you did not answer.** … Nothing was
implemented and nothing was inferred."*

**What is shipped.** Migrations **173/174** record **both halves with independent provenance** —
`ci_status`/`ci_checks_passed`/`ci_source`/`ci_recorded_at` and
`gate_verdict`/`gates_pass`/`gates_fail`/`gate_source`/`gate_recorded_at` — with a CHECK that a
verdict cannot exist without its source and timestamp, and **no `overall_status` column**. D16
asserts that a recorded disagreement **survives to the surface** (CI `Passing` beside gate
`FAIL`) with **no third combined verdict**.

**Blocks:** the *automatic* half only. The registry and the surface exist and accept recorded
verdicts; nothing ingests from CI (`CONF-D9`, and `P10` is externally constrained).

**Recommendation — `3`.** The approved card shows both side by side, the schema already shapes
both with separate provenance, and the live disagreement means `1` or `2` would **assert a
release verdict nobody authorized**. This is the one recommendation where the implementation is
already built to the recommended option *without* the ruling — so ruling `3` ratifies, while `1`
or `2` would require removing a half the design shows.

---

## 4 · Q4 · Merge the design branch, or keep commit-pinned citations?

**Facts, verified now.** `931218b` is **NOT an ancestor of `HEAD`**. The branch exists locally
and on `origin` as `design/12circle-plus-admin-dashboard`. `check-design-citations.mjs` reports
**5 citations resolved in the working tree, 60 resolved at `931218b`, 0 unresolvable anywhere,
0 commit-only without the commit named** — exit 0.

**Governing instruction.** `CLAUDE-CODE-INSTRUCTIONS.md` at that commit: *"create branch
`design/12circle-plus-admin-dashboard` … **Do not merge to main.** Do not touch existing Mobile
work."*

**Options.** `1` keep commit-pinned citations, ratifying what ships · `2` merge the design
branch into the integration branch · `3` copy the design package into this branch without
merging history.

**Blocks:** nothing. Every citation resolves and the guard enforces that.

**Recommendation — `1`.** The design package's **own instruction forbids merging**, and the
guard already proves no citation can rot: it fails on a reference that points off-branch
*without naming the commit*. `2` would contradict the handoff; `3` duplicates artifacts the
provenance file calls *"Design authority. Not modified by this handoff."* The only cost of `1`
is that a reader needs `git show`, which the citations state.

---

## 5 · Q5 · Add the Phosphor icon dependency?

**Exact source.** §15727: *"The specification names `ph-fill ph-warning-circle` from Phosphor.
**The app does not depend on Phosphor** — `pubspec.yaml` carries only `cupertino_icons` — so a
Material fill-weight equivalent is substituted. That is a substitution, not fidelity, and adding
an icon dependency is not a decision to take in passing."*

Also §11547: the handoff *"declares one shared identity — violet `#7C3AED`, Schibsted,
**Phosphor**, 4.5:1, 44px"*, and §11244 counts *"Phosphor Icons"* among what the Admin package
specifies against Helix's smaller set.

**Scope.** One icon is substituted today. The Admin icon inventory
(`docs/design/brand/icons/admin-icon-inventory.md`) is the full set the design names.

**Options.** `1` add the dependency and match the specification · `2` keep Material
substitutions and record each deviation · `3` vendor only the icons actually used.

**Blocks:** nothing. It is visual fidelity, and each substitution is recorded.

**Recommendation — none, and that is deliberate.** This is a **dependency decision for the
design system**, not for this product: §11547 records Phosphor as part of the *one shared
identity*, so the answer binds whatever consumes Helix next. It also interacts with **`Q16`** —
if the canonical Helix artefact is settled first, the icon question may be answered there rather
than here. Recommending in isolation would be the agent inference the standing constraints
forbid.

---

## 6 · Q7 · `D-1` — which reconstruction mechanism may the SEC-W1 CI negative control use?

**Exact source.** §365, reproduced with its own governance column:

| Option | Governance status | Exercises the 15 assertions |
|---|---|---|
| Delete migrations 132/133 in the workspace, restore | Authorized by precedent (`i3a11_negative_control.sh`, CI-wired) | **No — 0 of 15** |
| Isolated worktree at the pre-fix commit `07f5bfb` | Authorized by precedent (`wrk01_live_probe.sh`) | **No — 0 of 15** |
| Temporarily mutate 132/133 text, restore byte-identically | **UNSETTLED** — §8 of the closure standard says *"Never rewrite a migration in place unless the wave plan explicitly authorizes it"*; **no harness precedent exists** | **Yes — 15 of 15** |
| Change SEC-W1's `setUpAll` to lazy reads, then delete | Governed by §4:111 as a reviewed decision recorded in the evidence | **Yes**, per test, as I/O errors rather than the guard's curated `reason:` strings |

**Why the first two exercise nothing**, verbatim: *"SEC-W1 reads migration 132 inside
`setUpAll`, and in `package:test` a failing `setUpAll` means the group's tests are never run.
Deleting the migration therefore produces exactly one failure, named `(setUpAll)`, and zero of
the 15 assertions execute."*

**Blocks:** *"`QAX-SEC-08`'s fourth rung — **and nothing else**"* (§7323). Three of four rungs
hold.

**Recommendation — option 4 (lazy `setUpAll`), with a caveat I will not resolve for you.**
It is the only option that is **both governance-clean and exercises the assertions**: option 3
needs an explicit authorization against the closure standard's own prohibition, and options 1
and 2 run zero of the fifteen. The caveat is that option 4's failures surface as **I/O errors
rather than the guard's curated `reason:` strings**, so the negative control would prove the
assertions *execute and fail* without proving they fail *for the stated reason* — a weaker rung
than the other harnesses in this repository produce. Whether that is acceptable for this rung is
yours.

**Related and also open:** `D-2` and `D-3` — see §11.

---

## 7 · Q13 · `subscriptions.kind` carries `'app'`; the documented vocabulary is `coach | self_guided | ai_guided`

**Exact source.** `022_payments.sql:17-20`, the table's own comments:

```
-- 'coach'        → client subscribing to a coach (coach_id set)
-- 'self_guided'  → platform membership $29/mo (coach_id null)
-- 'ai_guided'    → platform membership $59/mo (coach_id null)
kind text NOT NULL,
```

**There is no CHECK on `kind`.** Measured on QA, **2026-10-08: 184 rows, every one
`kind = 'app'`.**

> **The row count drifts** — QA gains subscriptions from CI runs and fixtures, and it read 173
> earlier in this programme. **The evidence is the property, not the number:** *every* row
> carries `'app'`, and *every* row carries null Stripe identifiers. Re-measuring moves the
> count and not the finding.

**Two facts narrow it considerably, and neither decides it.**

1. **Every `'app'` row has a null `stripe_subscription_id` and a null `stripe_price_id`** —
   184 of 184 on both columns — so they did not arrive through Stripe.
2. **No code anywhere writes `kind = 'app'`.** `create-checkout` and `stripe-webhook` write the
   documented vocabulary and always set the Stripe identifiers.

So the `'app'` rows are **seed data, not subscriptions any code path produced**.

**Options.** `1` the comment is authoritative; `'app'` is QA seed noise · `2` `'app'` is an
intended value this repo does not yet write, and the comment is incomplete · `3` add a CHECK
once the vocabulary is ruled.

**Blocks:** any plan-level breakdown, including **churn by plan**, which `METRIC-20`'s ruling
explicitly deferred to this question. Nothing built depends on it: **no admin surface reads
`subscriptions`** except `METRIC-20`'s churn columns, which carry no `kind`.

**Recommendation — `1`, and I will not go further than that.** The evidence inside the
repository points one way: no writer, no Stripe identifiers, and the documented trio is what
both Edge Functions produce. But `2` **cannot be excluded from inside the repository** — an
`'app'` tier could be an intended product concept not yet implemented — and that is precisely
the kind of thing only you can rule. **No CHECK was added** per your instruction; adding one is
the natural consequence of `1` and remains yours to authorize.

---

## 8 · Q15 · One incident severity the design shows and the schema forbids

**My earlier framing was wrong — see §0.** `BOUNDARIES.md` row A's premise is disproved. What
survives is one value on one object.

**Exact facts.** The shipped CHECK, `143_p2_audit_incident_population.sql:70`:

```sql
CONSTRAINT audit_incidents_severity_check
  CHECK (severity = ANY (ARRAY['Critical','High','Warning','Informational']))
```

…and its comment: *"The severity enum is SPECIFIED, not chosen:
`V5_DECISION_RESOLUTION:117` — 'Severity enum also specified: Critical · High · Warning ·
Informational.'"*

**The approved Trust screen shows a fifth value on the same object.** `INC-2041` is rendered
with severity **`Elevated`** (*"INC-2041 · Elevated · AI safety · AI Guardian"*), and the
incidents overview tile reads *"Elevated · 1 elevated · INC-2041 · 3 open, 0 critical"*. §12343
records it: *"a fifth value appearing in Trust that matches neither vocabulary — recorded as
evidence, and **NOT resolved into either enum without product authority**."*

**So the design shows an incident state the schema cannot store.**

**Options.** `1` add `Elevated` to the enum · `2` the design's `Elevated` is an error; the four
specified values stand · `3` `Elevated` is a *display* grouping over existing values, not a
stored one.

**Blocks:** nothing today, and this is worth stating because it changes the urgency and not the
substance: `_severityColor` and `_severityTint` map the three coloured values and send
everything else to **neutral** — *"rendered neutrally rather than guessed into a danger
colour"* — so an `Elevated` arriving would be **legible rather than mis-coloured**. The CHECK
currently makes it unstorable, so no incident can carry it.

**Recommendation — none.** `README.md` at `931218b` instructs, in terms: *"**Do not resolve**:
attention severity labels …"*. The design package forbids me resolving it, and the enum's own
comment records it as *specified* by `V5_DECISION_RESOLUTION:117` — so changing it is amending a
specification, not filling a gap.

---

## 9 · Q16 · Which Helix artefact is canonical?

**Exact source.** `BOUNDARIES.md` row **G**: *"Admin tokens (`--adm-*`) vs Fitness Helix tiers |
Architecture question | Both documented, no merge."*

**§103 found something sharper than the row states.** Two artefacts both claim to be the
12Circle Helix theme:

| artefact | brand | status |
|---|---|---|
| in-repo Dart (`core/helix/` + `core/theme/twelve_circle_theme.dart`) | **violet `#7C3AED`**, Schibsted Grotesk | **conformance-tested in CI** |
| `/Users/dmac/Documents/projects/helix` · `src/themes/12circle.ts` | **electric lime `#9EF01A`**, Hanken Grotesk / Clash Display | its own header: *"FIRST PASS — values are meant to be tuned by design."* |

**Row G's own question is answered in substance.** §103.1 established that **eleven of eleven
shared colour roles match exactly** between the Admin tokens and the in-repo theme, along with
the typeface, both hairline strengths and the easing curve — *"This is one design system, not
two that happen to agree."* So `--adm-*` is a **normalisation of the live theme**, not a rival
tier to it.

**What remains open is narrower and outside this repository:** which artefact a future product
binds to. §103.2's own words: *"The enforced in-repo theme is the live one; the standalone lime
theme is a stale first pass … **Which is canonical is a design-system authority decision and is
not made here.**"*

**Options.** `1` the in-repo Dart theme is canonical; retire or re-tune the lime first pass ·
`2` the standalone `/helix` theme is canonical and the in-repo one is a product deviation ·
`3` both stand, with the `/helix` lime explicitly marked non-canonical.

**Blocks:** nothing in this repository — the enforced theme is live and CI holds it. It blocks
**the second product**, which is the point at which a wrong binding imports a different brand.
It also interacts with **`Q5`**.

**Recommendation — `1` or `3`, and the evidence does not distinguish them.** What the evidence
*does* establish is that `2` would be **a brand change to a shipped, CI-enforced product**: the
live app is violet and eleven colour roles, a typeface, two hairlines and an easing curve agree
across the Admin design and the in-repo theme. Between `1` and `3` the difference is whether the
lime file is deleted or labelled, which is a housekeeping preference I have no evidence to rank.

---

## 10 · The four unanswered from the metric sheet's own residue

These were recorded as *"things the rulings did not settle"* and are smaller than the questions
above. Two are already closed; two are open.

| item | status |
|---|---|
| `METRIC-02`'s **weekly window** (`date_trunc('week')` = Monday) | **OPEN · folded into `Q1`** as the week-start sub-option. Recorded as *"an applied convention, not an authorization."* |
| `METRIC-17`'s **two age sources** | **CLOSED by engineering, disclosed.** `date_of_birth` preferred, `user_profiles.age` as fallback, because dob is populated on **0 of 635** QA profiles and age on **4 of 640** — using dob alone *"would have made the panel vacuous on QA."* |
| **an age of 60 or above has no ruled bucket** | **OPEN · NEW to this pack.** `METRIC-17 = Option 2` fixed the fourth bucket as `unknown`, leaving three labelled ranges covering `[18,60)` and nothing above. No `60+` bucket was invented; `age_out_of_range` carries those rows so the four buckets plus it **reconcile exactly to `users_total`**, which D16 asserts at every boundary age. §162.3: *"whether `60+` becomes a real bucket is **narrow and still open**."* **Blocks:** nothing — the rows are counted and disclosed. **Recommendation:** none; it is a card-design choice with no evidence pointing either way. |
| `METRIC-12` · attention queue severity | **DISSOLVED BY EVIDENCE** — see §0 and §8. |

---

## 11 · Four decisions that were open in the record and in no pack

Found by the §12 sweep. None was concealed; none had been carried.

### `D-2` · Authorize remediation of **Finding A**?

**Finding A — schema-qualification blind spot — UNREGISTERED, NO ID** (§9.2):

> *"SEC-W1's `FOR ALL` detector and its `FOR UPDATE` detector both require
> `ON\s+public\.coach_team_members`. The real historical defective policy at
> `supabase/migrations/002_ecosystem_additions.sql:146-147` is written **unqualified**
> (`ON coach_team_members`), and the unqualified form is the repository's dominant style
> (approximately 3.6:1 …)."*

So the detector would **miss the real historical defect** it was written to catch.

**Blocks:** *"Finding A only"* (§7324).

### `D-3` · Authorize remediation of **Finding B**?

**Finding B — forward-supersession blind spot — UNREGISTERED, NO ID** (§9.3):

> *"SEC-W1 pins **migration 132's** text for `is_team_lead_of()` and `may_notify()`. Migration
> **134** later `CREATE OR REPLACE`s both and, because migrations apply in filename order, is
> the authoritative definition at HEAD. SEC-W1 does not read 134. **A future migration could
> weaken either helper while leaving 132 byte-identical, and SEC-W1 would still pass.**"*

Classified a *"genuine defect — the unmechanized half of §5.2's clause."*

**Blocks:** *"Finding B only"* (§7325).

**Why both need you and not me.** Remediation requires a registry ID, and **no `NEW-W1-*` ID
exists in `MASTER_REMEDIATION_REGISTRY.md` (count: 0), so no convention permits
self-allocation** (§365). I am also instructed not to modify that registry.

**Recommendation — authorize `D-3` ahead of `D-1` and `D-2`.** This is the one place in this
pack where I would argue about ordering, because `D-3` is not a reporting gap but a **live guard
blindness**: `SEC-W1` can pass while the helper it exists to protect has been weakened by a
later migration. `D-1` affects whether a negative control exercises its assertions, and `D-2`
affects whether a detector would have caught a *historical* defect — both matter less than a
guard that can be silently bypassed going forward.

### `EC-01 Q2–Q5` · what "evaluable" means

§2980: *"**blocks no phase.** `Q3`'s facts are settled — `G-14`'s audit-log conjunct has **no
requirement row**, so it can never be *met*; what is open is whether 'evaluable' means
*assessable* or *meetable*."*

**Blocks:** nothing. It is a definition inside the finding ledger, and §4-H's discipline is to
leave such contradictions unreconciled rather than pick.

### `EC-02` · the registry contradiction

Carried unchanged and **deliberately unreconciled** per §4-H: `:709` records a
`BLOCKED_DECISION` on `Q-5` while `:782` says it *"lands now"*.

---

## 12 · Verification — are there additional owner decisions hidden?

**Method.** Four passes, each stated so you can judge the coverage:

1. **The design package at `931218b`, document by document.** All seven markdown files plus the
   six screens and the build spec `.docx`. `SCREEN-INVENTORY`'s **three** requirements lists
   (*Data each page needs*, *Interactions expected*, *States designed*), `COMPONENTS.md`,
   `RESPONSIVE.md`, `BOUNDARIES.md`, `README.md`, `PROVENANCE.md`,
   `CLAUDE-CODE-INSTRUCTIONS.md`.
2. **`BOUNDARIES.md`'s seven rows**, reconciled one by one (§202). **Five were already handled;
   two became `Q15` and `Q16` — and row A's premise turned out to be disproved.**
3. **The programme definition swept for unruled markers** — *still open · remains open · not an
   authorization · applied convention · NOT DECIDED · owner decision required*. Every hit
   triaged against later sections, because this document supersedes itself as it goes.
4. **The separate registers** — `V5_METRIC_DECISION_SHEET.md`, `MASTER_PRODUCT_DECISIONS.md`.

**What the sweep closed rather than carried**, each by a later ruling I verified:

| candidate | resolution |
|---|---|
| `A13` audit-read recursion | **owner decision `R-1`** (§86), implemented |
| `A2` anonymisation recursion | **owner decision `S-2`** (§86), implemented |
| `A12` pseudonym mapping home + protection — *"UNRESOLVED — owner decision required"* at §1918 | **RESOLVED BY EXISTING AUTHORITY** → implemented in migration **146**; §19.3 answered all four of §8.20's questions |
| `phi_correction` changed-column **name set** — *"NOT DECIDED"* | **decided by `B4`** (§84.2): the names get their own column, `delta` stays NULL for that category, and only `array_agg(key)` is computed so *"no value can reach the ledger by this route"* |
| `METRIC-12` attention severity | dissolved by evidence; `CRITICAL` appears zero times |
| `D4` · `D11` · `A14` · `D-D1` | closed; **P2 reached all four rungs** (§85) and *"Nothing of `D-D1` remains open"* (§9851) |

**One register is larger than this queue and is not duplicated into it.**
`MASTER_PRODUCT_DECISIONS.md` carries **73 decisions grouped A–G by the authority required**,
with **eight on the critical path**: `PD-D08` (name a clinical owner), `PD-B01`+`PD-B02` (daily
vs weekly check-in and the canonical column family), `PD-A02` (the certification predicate),
`PD-D01` (PAR-Q policy), `PD-A17`+`PD-A10` (where the API runs, which nutrition backend is
canonical), `PD-A26`+`PD-A25` (PITR/forward-only, and what beta is), `PD-F02` (launch platform),
`PD-E07`+`PD-E08` (is production billing real, which tier ladder).

They are **catalogued, not hidden**, they are a product-programme queue rather than the V5 Admin
one, and that document states: *"**Nothing in Waves 1, 2, 3A or 3B is blocked by any decision in
this document.**"* I am instructed not to modify it, and I have not. **None of the 73 blocks the
V5 admin frontier.**

**Conclusion.** Beyond the ten questions above, the four items in §10–§11, and the 73 in the
product register, **I found no further unresolved owner decision** in the design package or the
programme records. Two things I will not claim: that the 73-decision register is itself complete,
since I did not re-derive it; and that a decision cannot be hiding in a document neither register
cites.

---

## 13 · What each decision blocks — one table

| decision | blocks | branch-local? |
|---|---|---|
| **Q1** timezone + week start | nothing; figures are correct and disclosed | — |
| **Q2** active-user population | nothing | — |
| **Q3** `METRIC-11` authority | the *automatic* half of "QA and release status (from CI)". Registry and surface exist | yes |
| **Q4** design branch | nothing; all 65 citations resolve | — |
| **Q5** Phosphor | nothing; visual fidelity, deviations recorded | — |
| **Q7 / `D-1`** | `QAX-SEC-08`'s fourth rung **and nothing else** | yes |
| **Q13** `kind` vocabulary | plan-level churn only | yes |
| **Q15** `Elevated` | nothing; unrecognised values render neutrally and the CHECK makes it unstorable | yes |
| **Q16** canonical Helix | nothing here; **the second product** | yes |
| **`D-2`** Finding A | Finding A only | yes |
| **`D-3`** Finding B | Finding B only — but it is a **live guard blindness** | yes |
| **`60+` bucket** | nothing; rows are counted in `age_out_of_range` and reconcile | — |
| **`EC-01 Q2–Q5`** | nothing | — |

**Every blocker is branch-local. No decision in this pack blocks another branch's work.**

---

## 14 · State at this frontier

No code, schema, migration, guard or test changed for this pack. Last verified state, unchanged:
live **1089/1089 across 21 suites** · Flutter **1944 / 5 skipped** · `dart analyze` **0 errors**
· nine static guards **exit 0** · QA frontier **180**, ledger `180 | 180` matching
`expected_applied.json` · CI **green on all seven jobs** at `2affe39`.

**Production was not contacted.**
