# V5 — METRIC DECISION SHEET

**Source: `docs/V5_OWNER_DECISION_PACK.md` §C.3, read verbatim. 12 decision IDs across 11 cards —
Revenue carries two.** Prepared 2026-10-07 against QA frontier 170.

**No option is selected and no answer is inferred.** Options are quoted exactly as §C.3 states them. The
*Evidence established* column is what this programme has since proven at source or measured live on QA; it is
there to make the choice cheaper, not to make it for you.

**Two IDs are not open.** `METRIC-12` resolved by evidence and `METRIC-18`'s *meaning* is already ruled —
both are shown so the sheet is complete, and neither needs an option.

---

## The four cards that need no decision

Already determined and **producers live**, verified this run: **Total users** → `admin_user_overview` ·
**Recent admin activity** → `admin_audit_events` · **Security** → `admin_security_events` ·
**AI Guardian (read-only)** → `governance_policy` + `guardian_state`.

---

## METRIC-02 · Active users / DAU

**Question (§C.3).** *"does a **sign-in with no Session** count as active?"*
**Options.** `1` Session only (`product-bible` §5: Session = one day's workout) · `2` sign-in counts ·
`3` both, shown separately

**Evidence established.** No rollup or producer exists. `workout_sessions` holds **9 rows** on QA and is the
only candidate for "Session". Sign-in events reach `audit_events` as category `authentication`, which your
`B-1` ruling already placed in the Security area — so option 2 or 3 would read a population the Admin layer
can already see. The approved card shows **DAU / weekly / monthly plus a month-on-month delta**, so whichever
basis you pick must support three windows.

**Response: METRIC-02 = Option ____**

---

## METRIC-03 · Active coaches

**Question.** *"'this month' = **calendar month** or **trailing 30 days**? (the approved screens use both)"*
**Options.** `1` calendar · `2` trailing 30d

**Evidence established.** `coach_client_relationships` holds **117 active** rows — the intersection the card
needs ("of 164 · 23 with no client this month") is computable today; only the window is undecided. The
approved screens genuinely use both phrasings, which is why the record calls this narrow rather than open.

**Response: METRIC-03 = Option ____**

---

## METRIC-05 · Wellness partners

**Question.** *"the **approval state machine** — '9 awaiting approval' implies states the schema does not
have"*
**Options.** `1` define now (needs the state list from you) · `2` drop the sub-count, show total only ·
`3` defer the card's second line to an `A11` state

**Evidence established.** Confirmed twice over: **no approval-state column exists** on `user_profiles`, and
**`role='vendor'` returns 0 rows on QA** — so the card has neither a state machine nor any partner data.
`PD-A19` (role-assignment governance) is the nearest existing decision and is itself open. Option 1 needs the
state list; the vocabulary must come from you, as with `approval_status` and `events.status`.

**Response: METRIC-05 = Option ____**

---

## METRIC-06a · Revenue — currency

**Question.** *"**`PD-C03` currency** — `'usd'` is hardcoded everywhere; the card shows **£**"*
**Options.** `1` record single-currency USD + explicit FX for display · `2` multi-currency (large)

**Evidence established.** Verified live: `payments.currency` is `text NOT NULL DEFAULT 'usd'`. `PD-C03` is an
**open register row**, not a new question — it is listed here because the card cannot render until it closes.
Your standing instruction keeps **GBP/£ as the Admin display currency with explicit FX**, which option 1
satisfies without touching billing.

**Response: METRIC-06a = Option ____**

---

## METRIC-06b · Revenue — gross vs commission

**Question.** *"is 'coaching' **gross** or **platform commission**?"*
**Options.** `1` show all three (gross / commission / net) — *"your earlier direction already approved this
decomposition"* · `2` gross only · `3` net only

**Evidence established — the decomposition is already ruled.** Direction **`I`** (ledger `:12344`), verified
at source: *"Admin must distinguish **gross coaching revenue · platform commission · net/platform revenue**.
`marketplace_commission_rate` (0.10, `038:14`) is the commission input. **Calculation and source definitions
must be explicit before implementation; no monetary value is fabricated.**"*

So option 1 is the recorded direction. **What is still owed is the calculation itself**, which the direction
demands and `COWORK` §8 forbids an agent inventing. QA holds **1 payment** and **116 subscriptions**, and
`subscriptions` carries no monetary amount — so a source definition is required before any figure exists.

**Response: METRIC-06b = Option ____**
**Response: METRIC-06b calculation + source definition = ______________________________**

---

## METRIC-11 · QA & release

**Question.** *"does the card show the **V5 gate ledger** or **CI status**? They disagree today (CI green,
8 of 15 gates FAIL)"*
**Options.** `1` CI · `2` gate ledger · `3` both, labelled

**Evidence established.** The disagreement is live and current: CI is **green 6/6** on `8bc17cc` while
`RELEASE_GATES` still records failing gates. The approved card shows a **`BLOCKED` badge** beside
*"Release 4.2.0 · staging"*, *"Build: Passing"* and *"Automated QA: 1,412 / 1,418"* — a gate verdict and a CI
verdict **side by side**, which is evidence that the card already contemplates both. No ingestion exists for
either.

**Response: METRIC-11 = Option ____**

---

## METRIC-12 · Attention queue severity — **RESOLVED BY EVIDENCE, no option needed**

**Question as recorded.** *"Approved UI shows `CRITICAL/HIGH/MEDIUM/LOW`; the shipped, V5-specified CHECK is
`Critical/High/Warning/Informational` (`143:70`)."*

**Evidence established — the premise was wrong and the conflict does not exist.** Reading all six approved
pages: **`CRITICAL` appears zero times.** The attention queue renders **`Critical`** and **`High`** — title
case, *the shipped enum* (*"Critical · Security · 14 min ago · Open"*). The uppercase `HIGH/MEDIUM/LOW`
appears **only on Ecosystem**, attached to *"Harassment"*, *"Health misinformation"*, *"Spam"*,
*"Off-topic"* — **moderation report priorities, a different object entirely.**

**No enum change, no display-map, no implementation.** Recorded as `ALREADY SATISFIED` (§158).

**Response: only if you read it differently — METRIC-12 = Option ____ (otherwise leave blank)**

---

## METRIC-13 · Ecosystem activity — "pods"

**Question.** *"what a 'pod' is (`86 pods`) — `accountability_pods` exists but the count does not match"*
**Options.** `1` `accountability_pods` · `2` `community_groups` · `3` something else you define

**Evidence established.** Both candidates exist and **neither matches**: `accountability_pods` holds **1 row**
and `community_groups` **5** against the design's *"86 pods"* — though the screens carry *"sample
design-state data"*, so counts cannot settle it either way. The design uses *pods* as a Community unit
(*"Community — 86 pods · 1,940 posts"*) and separately names *"Pod-level challenges"*. Your `B-18` ruling
confirmed `accountability_pods` is readable by any authenticated member.

**Response: METRIC-13 = Option ____**

---

## METRIC-14 · Events / community — "attendance"

**Question.** *"which '74% attendance' means"*
**Options.** `1` registrations ÷ capacity · `2` attended ÷ registered (**no attendance column exists**) ·
`3` bookings ÷ capacity

**Evidence established, and it bears on the choice.** The approved design renders *"Registrations · 30 d —
1,640"* and *"Attendance rate — 74%"* as **two separate figures**, and an individual event as *"88 / 120"* —
which **argues against option 1**, since the design already shows registrations and attendance as different
numbers. A member profile shows *"Events attended — 3"*. Confirmed live: `event_registrations` has **no
`attended` column** (2 rows on QA), so option 2 requires a new column and a capture mechanism.

**Response: METRIC-14 = Option ____**

---

## METRIC-16 · Installs

**Question.** *"`PD-A24` = `C` forecloses an **analytics vendor**; is reading **our own** store consoles
that? Console credentials are also an **account boundary**"*
**Options.** `1` not a vendor — authorize console ingestion · `2` it is — card renders `A11` empty ·
`3` manual periodic entry

**Evidence established.** No ingestion, no credentials, no table. The approved card fixes an **Apple / Google
Play split**. `PD-A24` is ruled `C` and this question tests its edge — the record states the matter *"is not
settled either way"*. Option 1 additionally requires store-console credentials, which is an account boundary
only you can cross.

**Response: METRIC-16 = Option ____**

---

## METRIC-17 · Age demographics

**Question.** *"is the 4th bucket **60+** or **unknown**?"*
**Options.** `1` 60+ · `2` unknown · `3` both (5 buckets)

**Evidence established.** The approved panel labels exactly **three** buckets — `18–30 years` (46%),
`30–45 years` (32%), `45–60 years` (18%) — plus an **unlabelled 4%** remainder. The labelled edges
**overlap** (30 and 45 each appear in two buckets), so half-open intervals are required whichever way you
rule. Confirmed live: **`date_of_birth` is populated on 0 of 635 QA profiles**, so the aggregate has a column
but no data.

**Response: METRIC-17 = Option ____**

---

## METRIC-18 · Impressions — **MEANING ALREADY RULED; producer is the open half**

**Question.** *"**which impression** — store-listing, marketing, or in-app?"*
**Options.** `1` in-app · `2` store-listing · `3` marketing · `4` card renders `A11` empty

**Evidence established — direction `K` already defines it.** Ledger `:12345`, verified at source: impressions
are ***"eligible content renders/views, held distinct from reach · unique viewers · clicks · engagement ·
sessions"***. That **supersedes** the earlier reconciliation line (`:12134`) saying the term appears in no V5
source, which predates it. So the meaning is **closed** and matches option 1.

**What remains is the producer.** Confirmed live: **no impressions table exists** and nothing emits a render
event. **`flagcdn.com` appears only in documentation** — no shipped reference in `apps/` or `supabase/` — so
there is no egress today and none was introduced.

**Response: METRIC-18 producer — build an in-app render event? Y / N ____**
**Response: only if you intend a different meaning — METRIC-18 = Option ____ (otherwise leave blank)**

---

## METRIC-19 · Notifications placement — *new, from the design package's own boundary list*

**Question.** `BOUNDARIES B`: the build spec names a **Notifications Overview** group; **no corresponding
area exists on the approved Dashboard**, and `Notifications` is **not** one of the 17 matrix areas.
**Options.** `1` place it under Operations · `2` place it on the Dashboard · `3` out of scope for V1

**Evidence established.** The requirement is kept by the design package and its placement explicitly left
undecided. A `notifications` table exists and ships. `CAP-2` additionally records that it has **no
sent/delivered/failed/pending state** — it records `read`, i.e. engagement only — so delivery telemetry would
be a separate extension.

**Response: METRIC-19 = Option ____**

---

## RESPONSE SHEET

```
METRIC-02  = Option ____     METRIC-13  = Option ____
METRIC-03  = Option ____     METRIC-14  = Option ____
METRIC-05  = Option ____     METRIC-16  = Option ____
METRIC-06a = Option ____     METRIC-17  = Option ____
METRIC-06b = Option ____     METRIC-19  = Option ____

METRIC-06b calculation + source definition:
    ______________________________________________________________

METRIC-18  producer — build an in-app render event?   Y / N ____

METRIC-12  resolved by evidence; answer only to overrule  = Option ____
METRIC-18  meaning ruled by direction K; answer only to change it = Option ____
```

**Ten fields need an answer. Two are there only if you disagree with the evidence.**
