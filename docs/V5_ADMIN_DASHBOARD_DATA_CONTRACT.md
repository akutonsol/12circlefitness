# V5 — ADMIN DASHBOARD DATA CONTRACT

**Authoritative specification input for the 14 REQUIRED Dashboard areas. No screen is designed here and
no aggregate is implemented here.**
Baseline: migration frontier 152, QA ledger 152, `V5_PROGRAMME_DEFINITION.md` §99.

## 0 · Owner ruling that governs this document

> *"All Dashboard metrics and functional areas represented in the approved Dashboard design are REQUIRED
> to remain on the Dashboard homescreen. Do not remove, defer, collapse, or treat any of the following as
> optional … The approved Dashboard screenshot is the authoritative UI requirement. The fact that some
> metrics currently lack backend aggregates is an **implementation/data-contract gap, not permission to
> alter the approved Dashboard scope**."*

**All 14 areas are REQUIRED. Nothing below proposes removing, deferring or collapsing any of them.**
§98.2 recorded the absent data paths as an implementation gap and proposed no scope change; this document
is the obligation that follows from it.

### 0.1 Method, and the rule against invention

The owner's instruction sets the method exactly:

> *"Determine the authoritative definition, source of truth, calculation, authorization requirements, and
> data contract for each metric/area before implementation. **Do not invent business definitions where an
> owner decision is required.** Identify those definitions as owner decisions. **For anything already
> determined by the existing V5 record/database, use the existing authority** rather than reopening it."*

Every row below is therefore classified, and the classification is the point of the document:

| class | meaning |
|---|---|
| **A · DETERMINED** | fixed by the existing V5 record, the database, or **the approved design itself** (which is design authority since `CONF-D4` closed, §97.1). **Not reopened.** |
| **B · OWNER DECISION** | a business definition the record does not fix. **Stated as a question, never answered.** |
| **C · ARCHITECTURE** | a data-path/aggregate design question, class `Architecture`, available to §19's delegation once its inputs exist. **Not decided here.** |
| **D · EXTERNAL** | needs data the platform does not own or produce. |

**A note on reading the approved design as authority.** Where a screen states its own arithmetic — e.g.
*"of 164 · 23 with no client this month"* — that is an approved requirement and is used as such. Where a
screen only shows a **number**, that is not a definition, and no definition is inferred from it. The
distinction is applied strictly and is the difference between class A and class B throughout.

### 0.2 Authorization — one rule, already established, applies to all 14

**Every area on this Dashboard is a cross-user aggregate**, so every one of them is a `CONF-D8` subject:
*"Admin needs broad cross-user reads."*

**The existing authority is migration `019_admin_dashboard.sql`**, whose header states the chosen approach
and its reason:

> *"Org-wide oversight for `role='admin'`. **Rather than loosen per-table RLS**, we expose two
> `SECURITY DEFINER` functions **guarded by an admin-role check**, so an admin can read aggregates
> **without any client/coach gaining cross-tenant read**."*

That is `CONF-D8`'s option (b) — *"curated bypassing views"* — already exercised in shipped code for
`admin_platform_stats()` and `admin_recent_users()`. **It is precedent, not a resolution:** it settles two
functions, not a model. §99 reassesses `CONF-D8` over the complete requirement.

**Baseline authorization for every area below: `is_admin()`, via a `SECURITY DEFINER` aggregate, per the
019 pattern.** Departures are noted per area. Two questions are NOT settled by that baseline and are
raised once here rather than repeated fourteen times:

- **B-AUTH-1 · Does an admin reading an aggregate emit an audit record?** `R-1` added `audit_read` as the
  15th `A2` category and `audit_read_events()` emits it for the **Event read path**. Whether an
  **aggregate** read of member-derived data is an `audit_read` is **not** ruled. **OWNER/ARCHITECTURE.**
- **B-AUTH-2 · Is any Dashboard area visible to a role other than `admin`?** `CONF-D7`. The approved screen
  shows one identity, `Platform admin`. **Not inferable; part of the `CONF-D7` matrix (§98.1).**

---

## 1 · The six KPI cards

### 1.1 Total users — `4,812`

| field | value |
|---|---|
| **Definition** | **A · DETERMINED.** The approved card states its own composition: *"4,390 clients · 164 coaches / 246 partners · 12 admins"* — and 4,390 + 164 + 246 + 12 = **4,812**. So Total users = **the sum of the role populations**, and the breakdown is a required part of the card. |
| **Source of truth** | **A.** `user_profiles`, by `role`. `admin_platform_stats()` already returns `total_users`, `coaches`, `clients`, `vendors`, `admins` (`019:28`). |
| **Calculation** | **A** for the four displayed roles. **B · OWNER** for the residual: the enforced vocabulary has **seven** roles (`147:49`) — `content_manager`, `trust_operator`, `erasure_executor` appear in **no** displayed bucket. `admin_platform_stats()` likewise counts only five. **Are they counted in the 4,812 total, shown as a bucket, or excluded?** The arithmetic above is exact, which means the sample data had none of them; it does not tell us the rule. |
| **Also B · OWNER** | **Does "Total users" include demo and deleted accounts?** `user_profiles.is_demo` exists and is a privilege-protected column (`115`). The count is unqualified today. |
| **Data contract** | `{ total: int, by_role: { client, coach, partner, admin, …}: int }` |

### 1.2 Active users / DAU — `1,906 DAU`

| field | value |
|---|---|
| **Definition** | **A (shape) / B (rule).** The approved card requires **three windows and a trend**: *"1,906 DAU"*, *"3,120 weekly · 3,944 monthly"*, *"↑ 4.1% vs last month"*. `Ecosystem activity` repeats the monthly figure (3,944) and adds *"947 Daily sessions"*, so **DAU and sessions are distinct required measures.** |
| **B · OWNER — the central question** | **What constitutes "active"?** The record defines it nowhere. Candidate signals all exist (`workout_sessions`, `weekly_checkins`, `auth` sign-in) but **selecting among them is a business definition**, and it is the one the whole card rests on. Sub-questions the owner's answer must settle: which event(s) count · the timezone the "day" is measured in · whether a coach or partner counts as an "active user" or only clients. |
| **Source of truth** | **⛔ DOES NOT EXIST.** §98.2. No DAU/WAU/MAU measure exists in the migration set. `108:75`'s `last_active_at` is a per-session expression inside one view, not a platform activity measure. |
| **Calculation** | **C · ARCHITECTURE**, once B is answered. Distinct-user counts over a rolling window are not free; a daily rollup table is the obvious shape and is a design question, not an owner one. |
| **Data contract** | `{ dau: int, wau: int, mau: int, mom_change_pct: numeric, daily_sessions: int }` |

### 1.3 Active coaches — `141`

| field | value |
|---|---|
| **Definition** | **A · DETERMINED by the approved design.** The card states it: *"of 164 · **23 with no client this month**"*, and 164 − 23 = **141**. So **an active coach is a coach with at least one client this month**, and the "of N · M with no client" breakdown is required. |
| **Source of truth** | **A.** `coach_client_relationships` (`status='active'`) joined to `user_profiles` where `role='coach'`. `admin_platform_stats()` already exposes `coaches` and `active_relationships` but **not this intersection**. |
| **Calculation** | **B · OWNER, narrow.** *"this month"* — **calendar month or trailing 30 days?** The design says "this month"; `Ecosystem snapshot` says *"last 30 days"*. Both appear on the approved screens, so the ambiguity is real and is not resolvable by reading harder. |
| **Also B · OWNER, narrow** | **"has a client" = an active relationship exists, or the coach acted for a client this month?** The phrase *"with no client"* reads as the former; the former is assumed nowhere. |
| **Data contract** | `{ active: int, total: int, without_client: int, window: 'month' }` |

### 1.4 Active clients — `3,610`

| field | value |
|---|---|
| **Definition** | **A (decomposition) / B (rule).** The card requires a three-way split: *"2,210 coach-guided · 880 AI · 520 self"* = **3,610**. Those three map exactly onto `subscriptions.kind` — `'coach'`, `'ai_guided'`, `'self_guided'` (`022:16-18`). **The decomposition is determined; the word "active" is not.** |
| **B · OWNER** | **Does "active client" mean an active subscription, or activity?** The split is by subscription kind, which suggests subscription state; the card's title says "Active". `subscriptions.status` exists. **These give different numbers and the record chooses neither.** |
| **⚠ Integrity caveat** | If the answer is `subscriptions.status`, open finding **`K-07`** applies — *"A failed Stripe cancel still revokes local access"* (`MASTER_REMEDIATION_REGISTRY:196`), i.e. local status can diverge from Stripe. **A metric built on that column inherits the defect.** Recorded, not fixed. |
| **Data contract** | `{ active: int, coach_guided: int, ai: int, self: int }` |

### 1.5 Wellness partners — `218`

| field | value |
|---|---|
| **Definition** | **A · DETERMINED by the approved design.** *"**active of 246** · 9 awaiting approval"* — so the headline is **active partners**, against a total of 246, with an approval queue. |
| **Terminology** | **A.** `B7` records that the brief adopts *"Wellness Partner"* for the repo's `vendor` role, and the `Total users` card's *"246 partners"* agrees with `user_profiles` `role='vendor'`. **The label maps; no new role is needed.** |
| **B · OWNER** | **What makes a partner "active", and what is the approval state machine?** *"9 awaiting approval"* requires an approval status that **does not exist**: `user_profiles` has no partner approval column, and `admin_platform_stats()` returns only a flat `vendors` count. Approval is a **business process**, so its states are the owner's. |
| **Data contract** | `{ active: int, total: int, awaiting_approval: int }` |

### 1.6 Revenue — `£184.2k`, September

**The area with the largest gap between the approved design and the database.**

| field | value |
|---|---|
| **Definition** | **A (decomposition and period) / B (everything else).** The card states: **monthly** (*"Revenue · September"*), in **£**, decomposed *"£121k subscriptions · £48k coaching · £15k partners"* = **£184.2k**. `Ecosystem snapshot` adds *"£184.2k · **2.1% churn**"*, so **churn is a required measure too**. A further **£18,434** figure accompanies the calendar (day- or selection-scoped). |
| **⛔ Source of truth — the hard finding** | **No subscription monetary amount exists in the database.** `subscriptions` (`022:14`) has **no amount and no currency column** — only `stripe_price_id`. **The amount lives in Stripe.** The only monetary columns in the whole schema are `payments.amount_cents` / `payments.currency` (`022:40`), and `payments.kind` defaults to `'event_ticket'`. So **two of the three required streams have no local amount at all.** |
| **⛔ Currency conflict** | The single `currency` column in the schema **defaults to `'usd'`** (`022:41`), and `022`'s own comments price membership at **"$29/mo"** and **"$59/mo"**. **The approved design displays £ (GBP).** This is a direct conflict between an approved UI requirement and the shipped schema. **B · OWNER:** what is the **display currency**, is it a presentation conversion or the billing currency, and if converted — **what FX source and what rate date**? *(An FX source may implicate `PD-A24 = C`, which forecloses introducing a vendor.)* |
| **B · OWNER — "coaching" revenue** | **Gross client payments, or the platform's commission?** `marketplace_commission_rate` exists (default **0.10**, `038:14`, with a `platform_settings` row `039:10`). **The two readings differ by roughly an order of magnitude** and the record chooses neither. |
| **B · OWNER — recognition** | **Collected, billed, or recognised?** Refunds, failed payments, proration and cancellations each change the figure. The attention queue itself shows *"6 card payments failed after 3 retries"*, so failures are a live case, not hypothetical. |
| **B · OWNER — churn** | **Churn of what, over what window, and counted how** (logo vs revenue churn)? |
| **Calculation / path** | **C · ARCHITECTURE** once the above are answered, and it forks: **(i)** read Stripe at query time, **(ii)** persist amounts locally at webhook time, or **(iii)** a scheduled reconciliation. **Not decided here.** Note `pg_cron` and `pg_net` are installed on QA, so (iii) is *available*; availability is not a decision. |
| **Data contract** | `{ period: 'YYYY-MM', currency: 'GBP', total_minor: bigint, subscriptions_minor, coaching_minor, partners_minor: bigint, churn_pct: numeric }` |

---

## 2 · Health — the six platform tiles

`API · Database · Authentication · Background jobs · Integrations · Infrastructure`, each `Operational` or
`Degraded`, plus the banner *"Attention required — One integration is degraded and one release gate is
failing. **Everything members use is working.**"*

| field | value |
|---|---|
| **Definition** | **A · DETERMINED (the tile set).** The approved design fixes **exactly these six**, and fixes the state vocabulary as at least `Operational` / `Degraded`. |
| **⛔ Source of truth** | **DOES NOT EXIST, and `D12` does not supply it.** `D12`'s observability population constrains `component` to `structured_log` · `metric` · `trace` · `observability_audit` (`145:49`) — **telemetry kinds, not platform subsystems.** There is no health-check surface in the repo; every `health` hit in the migrations is `health_assessment`, i.e. **member** health. |
| **B · OWNER** | **What makes each subsystem "Degraded"?** A status tile is a **policy** statement — thresholds, probe frequency, and what counts as an outage. Six subsystems, six definitions. |
| **Calculation** | **C · ARCHITECTURE** once thresholds exist: probes, a status store, and a staleness rule for *"updated 2 minutes ago"*. |
| **A · a constraint worth keeping** | The banner distinguishes **internal degradation from member impact** — *"Everything members use is working."* That is an approved requirement: the tiles must support a **member-impact** statement, not only a subsystem roll-up. |
| **Data contract** | `{ subsystems: [{ key, label, state: 'operational'\|'degraded'\|…, since }], member_impact: bool, summary: text, observed_at }` |

---

## 3 · Security card

*"1 open incident"* · *"Sign-in anomalies · 24 h: 3"* · *"Permission changes · 7 d: 11"* ·
*"Critical vulnerabilities: None"* · *"Last event: MFA reset · 09:12"* · link *"View security →"*.

| field | value |
|---|---|
| **Open incidents** | **A · DETERMINED.** `audit_incidents` (migration 143) with its status model; read authorization already enforced at `143:219` — `is_admin() OR is_trust_operator() OR actor_identity = auth.uid() OR is_active_coach_of(actor_identity)`. |
| **Permission changes · 7 d** | **A · LARGELY DETERMINED.** This is the `audit_events` population: `admin_set_user_role()` is audited (`147`), and `Recent admin activity` labels such a row *"Permission change"*. **B · OWNER, narrow:** whether "permission changes" means role changes only, or every `admin_action`. |
| **Sign-in anomalies · 24 h** | **B · OWNER.** *"Anomaly"* is a detection policy, not a record. The attention queue's own example — *"38 failed sign-ins on one coach account from 3 countries"* — shows the **shape** (threshold + velocity + geo) but is sample data and defines no rule. |
| **Critical vulnerabilities** | **D · EXTERNAL.** Dependency/CVE state comes from a scanner, not the product database. **B · OWNER:** which scanner is authoritative, and whether this is even in Admin's scope. `PD-A24 = C` bears on introducing one. |
| **Last event** | **A.** `audit_events`, most recent, subject to `A13·1`'s admin self-read exclusion (`142:306`) — **an admin's own `admin_action` is excluded from their own read**, so *"Last event"* may legitimately differ between two admins. **That is `A13·1` working, and the UI must tolerate it.** |
| **Authorization** | **A.** Already enforced; no new model needed for incidents or events. |

---

## 4 · AI Guardian card

*"Operating normally"* · an **autonomy scale** `Observe · Analyze · Recommend · Reversible action · Human
only` with the current level marked **Recommend** · *"Awaiting human review: 2"* ·
*"Recommendations · 24 h: 17"* · link *"Open Guardian →"*.

| field | value |
|---|---|
| **Definition** | **A · DETERMINED (the five levels).** The approved design fixes the scale and its order. **The Dashboard card is a summary; it is not P7's surface.** |
| **⚠ Phase relationship — recorded, not resolved** | **AI Guardian is `P7`**, and §19.2 rules *"AI Guardian remains **P7** and is **NOT** inside Trust."* The owner now requires the **card** on the Dashboard. **These are compatible** — a summary tile plus an *"Open Guardian"* link is not the Guardian surface — **but the card cannot render without Guardian state existing**, so the Dashboard has a **data dependency on P7** even though it has no UI dependency. **Flagged; no phase is resequenced here.** |
| **⛔ Source of truth** | **Does not exist in the migration set.** No autonomy-level store, recommendation queue or review queue. |
| **B · OWNER** | **Who sets the autonomy level, and is it global or per-domain?** It is a **control**, not a metric — the most consequential item on the card. **Also:** what *"Operating normally"* means, and what "awaiting human review" counts. |
| **⚠ Authorization** | If the level is ever **settable** from Admin, that is a **privileged action** and therefore a `CONF-D7` cell **and** an `audit_events` emitter — *"every privileged action emits its record"* (`:337`). **The approved card shows it as read-only; nothing here authorizes making it settable.** |

---

## 5 · Wearables — "Wearable intelligence"

*"Delayed"* · *"Apple HealthKit: Connected"* · *"Apple Watch: Connected"* · *"Ingestion: ~40 min behind"*
· *"Connected devices: 1,0xx · 14 errors"*. `Ecosystem snapshot` adds *"1,288 devices · 880 AI plans"*.

| field | value |
|---|---|
| **⛔ Source of truth** | **DOES NOT EXIST — no device, wearable or HealthKit table exists in the migration set at all.** This is the emptiest of the fourteen. |
| **⚠ Phase conflict — the one that needs an owner ruling** | **`P3` (wearables) is DEFERRED under `PD-G01`**, and `D-V1`/`D-V2`/`D-V4` are deferred with it. The owner now requires a Wearables area on the Dashboard homescreen. **A Dashboard tile summarising wearable ingestion cannot exist before the ingestion it summarises.** This is **not** resolvable by reading the record: it is a **direct interaction between a standing deferral and a new requirement**, and only the owner can rule on it. **Stated, not resolved, and `PD-G01` is not treated as overridden.** |
| **B · OWNER** | Whether the tile is in scope **before** `P3`, and if so what it shows in the interim — noting that the 11 enumerated states include exactly this kind of case and **have no frames** (§97.4). |
| **Definition (if in scope)** | *"Delayed"*, *"~40 min behind"* and *"14 errors"* are **ingestion-pipeline SLOs** — thresholds are **B · OWNER**; the pipeline is `P3`. |

---

## 6 · QA & release

*"BLOCKED"* · *"Release: 4.2.0 · staging"* · *"Build: Passing"* · *"Automated QA: 1,412 / 1,418"*.

| field | value |
|---|---|
| **Definition** | **A · DETERMINED in part.** *"Automated QA: n/m"* is a pass/total, and this programme **has** that number — the live suite reports `484/484 across 12 suites`, and CI publishes it per run (§94.1, §96.1). *"Build: Passing"* is CI conclusion. |
| **Source of truth** | **D · EXTERNAL, but already owned: GitHub Actions.** The workflow, its per-job conclusions and the suite summary are already produced every push. **This is the only one of the six unserved areas whose data already exists — it is simply not ingested.** |
| **`BLOCKED` / release gates** | **A · PARTLY.** `RELEASE_GATES.md` exists and §20.3 tracks **15 gates: 5 PASS · 2 PARTIAL · 8 FAIL**. The banner's *"one release gate is failing"* maps to that ledger. **B · OWNER, narrow:** whether the card reflects the **V5 gate ledger**, **CI status**, or both — they currently disagree, since CI is green while 8 of 15 V5 gates FAIL. |
| **Calculation** | **C · ARCHITECTURE:** ingesting CI results requires an egress or webhook path. Note **`P10`'s unresolved *"installation forbidden"* operational constraint** bears on this and is **not** released here. |
| **B · OWNER** | What *"Release 4.2.0 · staging"* is sourced from — there is no release/version registry in the database. |

---

## 7 · Attention queue — "Needs your attention"

Five items, each `SEVERITY · domain · age · state`, an action button (`Investigate` / `Review` / `View`),
an *"All items"* link, and the footer *"Actions open the item. **Nothing is changed from this screen.**"*

| field | value |
|---|---|
| **A · DETERMINED — the behavioural rule** | The footer is an approved constraint and a strong one: **the queue is read-only; every action navigates.** No mutation may be wired into this surface. It matches `D11`'s Trust-as-review posture. |
| **A · DETERMINED — it is cross-domain** | The five sample items carry domains **Security · QA · AI Guardian · System · Payments**, so the queue **aggregates across domains** and is not a view of one table. |
| **⚠ B · OWNER — a concrete conflict with shipped code** | **The approved severities are `CRITICAL · HIGH · MEDIUM · LOW`.** The shipped `audit_incidents_severity_check` is **`Critical · High · Warning · Informational`** (`143:70`). **`MEDIUM` and `LOW` are not in the enum, and `Warning`/`Informational` are not in the UI.** Either the queue is not sourced from `audit_incidents`, or one vocabulary must change. **A migration altering that CHECK would be a change to a `D4`/`A11` population and is NOT proposed here.** |
| **Source of truth** | **C · ARCHITECTURE**, partly blocked: incidents exist; QA, AI Guardian, System-health and Payments items depend on §§2, 4, 6 and 1.6, none of which has a source yet. |
| **B · OWNER** | The **ranking rule** (severity, then age? weighted?), what makes an item "open", and who may dismiss one — **dismissal is a privileged action**, hence a `CONF-D7` cell and an audit emitter, **and the footer says this screen changes nothing**, so dismissal must live on the item's own surface. |
| **Authorization** | Baseline `is_admin()`, **but** the items reference member-identifying facts (*"one coach account"*). Under `A12` the Event population carries a **pseudonym**, not a subject id, so **rendering a human-readable subject in this queue is exactly the re-identification `A12` governs.** **C · ARCHITECTURE + `CONF-D7`. Not designed here.** |

---

## 8 · Installs · Age · Impressions

### 8.1 Installs — `4,365 this week`

| field | value |
|---|---|
| **A · DETERMINED** | The approved design fixes the split: **Apple `2,876`** and **Google Play `1,489`** (2,876 + 1,489 = 4,365), with ranges `Today / Week / Month / Range`. |
| **D · EXTERNAL** | Install counts are owned by **App Store Connect** and **Google Play Console**. The platform cannot derive them; a first install is invisible to the backend until a sign-in. |
| **B · OWNER** | Whether ingesting these consoles is authorized, and how. **`PD-A24 = C` forecloses introducing a vendor** — whether a first-party distribution console counts as one **is the owner's call, not mine**, and I do not read `PD-A24` as already answering it either way. Also: credentials for those consoles are an **account boundary** this agent cannot cross. |
| **Calculation** | **C · ARCHITECTURE** once authorized: a scheduled pull into a local rollup. |

### 8.2 Age range

| field | value |
|---|---|
| **A · DETERMINED** | The approved design fixes **four buckets**: `18–30` (46%), `30–45` (32%), `45–60` (18%), and a fourth at **4%** (unlabelled in the capture, positionally 60+). |
| **A · Source of truth exists** | `user_profiles.date_of_birth` (`000:64`). **This is the one previously-unserved area whose source data is already in the database.** |
| **B · OWNER, narrow but real** | **The boundaries overlap: 30 appears in both `18–30` and `30–45`, 45 in both `30–45` and `45–60`.** A contract must be half-open (e.g. `[18,30)`), and **which side each boundary belongs to is a definition**, not an implementation detail. Also: the treatment of **null `date_of_birth`** (the 4% bucket may be "unknown" rather than 60+ — **the capture does not say, and it is not inferred here**). |
| **⚠ Privacy** | Age is member-derived. Aggregate display is not a subject read, but **small buckets can re-identify**. Whether a minimum bucket size applies is **B · OWNER / ARCHITECTURE**, consistent with `A12`'s posture. |

### 8.3 Impressions — `231,841 worldwide`

| field | value |
|---|---|
| **A · DETERMINED** | Total plus **per-country** rows (`USA 43,987 · Australia 32,648 · Germany 26,563 · Spain 21,514 · Argentina 18,2xx`) and a world map. |
| **⛔ / B · OWNER — the definition is missing entirely** | **"Impressions" is undefined in the record.** It could mean store-listing impressions (an App Store / Play metric), marketing impressions, or in-app content impressions. **These have completely different sources**, and the design does not say which. **This is the single most undefined item of the fourteen.** |
| **D · EXTERNAL** | On every candidate reading except in-app, the source is outside the platform. Same `PD-A24` and account-boundary considerations as §8.1. |
| **⚠ A runtime third-party dependency, from the design itself** | The screen's own footer reads: *"Flags load from **flagcdn.com**; the map is drawn from Natural Earth country outlines."* **`flagcdn.com` is a third-party runtime dependency of the Admin UI** — an egress from an authenticated admin surface to an outside host. **B · OWNER / ARCHITECTURE:** whether that is acceptable or the flags are self-hosted. *(Natural Earth is public-domain geometry and can be bundled, so it raises no runtime dependency.)* **Recorded because it is a dependency introduced by the approved design, and it would otherwise be implemented silently.** |

---

## 9 · Ecosystem snapshot, Events & community, Recent admin activity

Present on the approved Dashboard and therefore in scope, though not itemised in the owner's fourteen.

| area | classification |
|---|---|
| **Ecosystem snapshot** (*"How each domain feeds the next · last 30 days"*) | **Mostly A.** People (`164 coaches → 3,610 clients`), Training & wellness (`28,410 sessions · 9,120 check-ins` → `workout_sessions`, `weekly_checkins`), Partners & events (`218 partners · 64 events` → `events`), Data & AI (`1,288 devices` → **blocked on §5**; `880 AI plans` → `subscriptions.kind='ai_guided'`), Business (`£184.2k · 2.1% churn` → **blocked on §1.6**). **Community — `86 pods · 1,940 posts` — B · OWNER:** *"pods"* is not a term the schema uses. |
| **Events & community** (`12 upcoming · 38 active classes · 74% attendance`) | **A (source) / B (definitions).** `events`, `classes` and `event_registrations` exist; **"attendance"** — registered, checked-in, or completed? — is undefined. `K-04` already governs registration integrity and is CI-verified. |
| **Recent admin activity** + *"Audit log"* link | **A · DETERMINED.** This is the `audit_events` read path with `A13·1`'s policy (`142:306`) already enforced, and the sample rows match its categories (*Permission change · System · Admin login · Release*). **The best-served area on the Dashboard.** |

---

## 10 · Summary — where the fourteen stand

| # | area | source of truth | principal open class |
|---|---|---|---|
| 1 | Total users | ✅ exists | **B** — the three unrepresented roles; demo/deleted |
| 2 | Active coaches | ✅ exists | **B** — month window; "has a client" |
| 3 | Active clients | ✅ exists | **B** — "active"; ⚠ `K-07` |
| 4 | Wellness partners | ⚠ partial | **B** — "active"; approval state machine absent |
| 5 | Active users / DAU | ⛔ **none** | **B** — what "active" means |
| 6 | Revenue | ⛔ **none** | **B** — currency (£ vs `usd`), commission, recognition, churn |
| 7 | Health | ⛔ **none** | **B** — degradation policy ×6 |
| 8 | AI Guardian | ⛔ **none** | **B** + data dependency on **P7** |
| 9 | Wearables | ⛔ **none** | **B** + direct conflict with **`PD-G01`** |
| 10 | QA & release | ⚠ exists in CI | **B** — CI vs V5 gate ledger; **P10** constraint |
| 11 | Attention queue | ⚠ partial | **B** + ⚠ severity vocabulary conflicts with shipped CHECK |
| 12 | Installs | ⛔ external | **B/D** — console ingestion; `PD-A24` |
| 13 | Age | ✅ `date_of_birth` | **B** — bucket boundaries; nulls |
| 14 | Impressions | ⛔ external | **B/D** — **term undefined**; `flagcdn.com` egress |

**Three areas are well served** (Total users, Recent admin activity, Security/audit). **Age needs no new
source.** **Six have no source of truth at all.** **Every one of the fourteen has at least one open
business definition**, which is why this document ends in questions rather than a schema.

**Nothing here is decided, recommended, ranked or implemented. No migration is authored. No Dashboard area
is removed, deferred or collapsed.**
