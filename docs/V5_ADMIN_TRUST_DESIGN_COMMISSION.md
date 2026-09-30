# V5 — ADMIN / TRUST DESIGN COMMISSION (`CONF-08`)

**Authoritative input to the design phase. No screen is designed here.**
Baseline: migration frontier 152, QA ledger 152, `V5_PROGRAMME_DEFINITION.md` §92.
Owner decisions applied at §9 (`CONF-D2`, `CONF-D1`, Admin scope) and §9.6 (`CONF-D5`).
**`CONF-D6` and `CONF-D7` remain open, and `CONF-08` remains NOT satisfied — see §9.6.4.**

This document is the artefact `CONF-08`'s ruling calls for. §19.4:

> **`CONF-08` — THE DECISION OBJECT IS THE IMPERATIVE, AND THE ANSWER IS COMMISSION.** The
> interrogative *"where do they live"* is answered by evidence — **0 mentions in 7 design docs** — so
> the live decision is supply-vs-commission, and with zero artefacts only commissioning is available.
> **The 21 / 23 / 10 surface counts are preserved unreconciled and NONE is adopted.**

It follows the form of `FINAL_NEW_SCREEN_DESIGN_COMMISSION.md`, which states its own nature exactly:
*"Authoritative input to the design phase … **no screen was designed**."*

> ### WHAT THIS DOCUMENT IS NOT
> **It is not the `CONF-08` artefacts, and it does not unblock P5.** §20.2 blocks P5 on *"`CONF-08`
> artefacts"* — the **design surfaces**. A commission is input **to** design; it is not design. P5
> remains blocked until an approved screen package exists.
>
> **Nothing here is a product decision.** Every element below cites the record. Where the record does
> not settle something a designer needs, §6 marks it **UNRESOLVED** rather than filling it.

---

## 1 · Architecture the design MUST honour — already decided, not open

These are settled rulings. The commission carries them so the design cannot contradict them.

| ref | ruling | design consequence |
|---|---|---|
| **`D5`** §19.4 | **(a) DIRECT SUPABASE + RLS, for Admin AND Trust** | **No API tier.** The surfaces read Supabase directly under RLS. `PD-A17 = A2` retired the NestJS service; `apps/api` holds no tracked file |
| **`D6`** §19.4 | **SEPARATE SURFACE, AS A FLUTTER WEB TARGET** — answered in two steps: in-app vs separate → **SEPARATE**; new app vs added target → **ADDED TARGET** | **Not in the member mobile bundle**, and **not a new application.** An added target reusing the existing codebase, auth and theme |
| **`D7`** §19.4 | **COLUMN-LIMITED VIEWS over `user_profiles`, not distinct modules** | Users / Coaches / Clients are **views**, not separate identity models. The pattern is `SEC_PHI_1`'s, as migration 135's `event_attendee_profiles` implements it |
| **`D11`** §19.2 | Trust's scope is **Security · Incidents · Audit Logs**; AI Guardian is **P7 and NOT inside Trust** | Trust is three areas, not four. Guardian is a separate later surface |
| **`D-D1`** §8.17 · §19.2 | Trust is **a governance review surface over existing audit and observability records**, and **"introduces no tables of its own"** | Trust **reads**. It is not an authoring surface |
| **`A13`** §8.8 · §19.2 | Trust operator visibility is **exactly `A13`'s grants and nothing more**; **no PHI payload** reaches Trust | Occurrence facts, actor/subject identifiers and control evidence only |
| **`A13`·1** §8.8 | an admin may **not** read their own `admin_action` records | The Admin audit view must exclude the reader's own admin actions. Enforced in the data layer (migration 152) — the design must not present it as available |
| **§8.18·Q2** | **no single party holds both erasure authority and read authority** | Trust (read) and the erasure executor are **different roles**. Do not design a combined control |
| **`D12`·Q5** §19.3 | the observability population carries **no subject identifier** | Observability views cannot offer per-member filtering |
| **§71.1** | signing is **detection, never prevention**, against a compromised function tier | No surface may present correlation as tamper-proof |

**Data substrate that now exists** (§85, live on QA at ledger 152): `audit_events` · `audit_incidents`
· `audit_incident_transitions` · `audit_control_evidence` · `observability_events` ·
`audit_identity_map`. Trust reads these. **They are built and verified; the design does not need to
specify them.**

---

## 2 · Admin — the evidenced scope

**`AD-01`** (`V5_IMPACT_ANALYSIS:133`), quoted: *"Admin Control Center over **health, security, users,
roles, payments, AI, wearables, database, incidents, releases, analytics, audit** (**13 domains**)."*

> **DISCREPANCY IN THE AUTHORITATIVE SOURCE — recorded, not resolved.** That sentence **enumerates
> twelve** domains and **claims thirteen**. The thirteenth is named nowhere. See §6.1.

**Success criterion** — design-authority `A14` (`V5_FINAL_DESIGN_AUTHORITY_RECONCILIATION:42`):

> *"an authorized administrator understands platform health, users, revenue, engagement, security,
> Guardian status, incidents and ecosystem activity **without navigating the consumer application**."*

*(This `A14` is the design-authority criterion. It is **not** `D4 · A14`, the Trust-visibility ruling.
Two different `A14`s. See §7.)*

**What exists today**, so the design knows what it is replacing: **3 screens** — dashboard, exercise
review, observability (`AD-01`, `SQ-09`) — and `admin_recent_users()` as the only Admin data function.

---

## 3 · Trust — the evidenced scope

**Three areas, from `D11`**: **Security · Incidents · Audit Logs**. AI Guardian is **P7**, outside
Trust.

**Trust is a review surface** (§19.2) reading the four populations. Per `A13` it sees occurrence facts,
actor/subject identifiers and control evidence — **never a PHI payload**. Per §19.3 cross-population
correlation is permitted **only** through the D12 correlation identifier, **never by joining on
subject identity**.

**Design authority currently records Trust as `CANNOT START`**
(`V5_FINAL_DESIGN_AUTHORITY_RECONCILIATION:338`): *"**none exists** · **none — V5 has no Trust** ·
container decision (`D-D1`) · **`CONF-D2` — may not be a surface at all**."*

> **Two of those three blockers are now discharged.** `D-D1` is answered (§8.17), and §19.2's
> *"governance review **surface**"* settles that Trust **is** a surface — which appears to resolve
> `CONF-D2`, though no ruling says so in those terms. **`CONF-D2` is carried as UNRESOLVED in §6.3
> rather than declared closed here.**

---

## 4 · Surface enumeration — NOT adopted

**§19.4 adopts no count**, and §18 records why: *"**Surface count, three-way and unreconciled:
21 · 23 · 10.** **No tracked source states any count.**"* All three come from untracked sources.

Ten surfaces are **named** in a tracked document
(`V5_IMPLEMENTATION_READINESS_GATE:319`): **Admin Home · Ecosystem · Users · Coaches · Clients ·
Trust · Security · Incidents · Audit Logs · AI Guardian**.

> **That list is recorded as evidence, NOT adopted as the surface set.** It is the probable origin of
> the "10". It also **mixes the two surfaces this commission keeps separate** — `Trust`, `Security`,
> `Incidents` and `Audit Logs` belong to Trust per `D11`, and `AI Guardian` belongs to **P7**, not to
> Admin or Trust at all. **A designer must not treat those ten as one Admin navigation.**

---

## 5 · Design inputs that DO exist

> **CORRECTED.** An earlier revision of this section listed the Fitonist reference and brand tokens as
> **present**, on the strength of the Admin row at
> `V5_FINAL_DESIGN_AUTHORITY_RECONCILIATION:337`, which *names* them as Admin's inputs. **That row
> states what the brief claims, not what exists** — and `CONF-D5`/`CONF-D6`, twelve lines above it in
> the same document, record both as missing. Reading a "stated inputs" row as an inventory is the same
> mistake this programme has corrected repeatedly. See V5 §89.

> **UPDATED 2026-09-30 (second owner input).** Row 1 changed state: the owner supplied the visual
> reference and it is now committed at `docs/design/admin-control-center/`. The other three rows are
> **unchanged** — see §9.6. A reference existing does not make a token package exist, state frames
> exist, or a screen package approved.

| input | state | authority |
|---|---|---|
| ~~Fitonist reference~~ **12Circle+ Admin visual reference** | **PRESENT** — four owner-supplied screens, committed and identified at `docs/design/admin-control-center/` | `CONF-D5`, resolved §9.6 |
| Brand tokens / identity package | **NOT FINAL** — *"no locked package · brand not final · token values, chart identity **blocked**"* | `CONF-D6` |
| 11 Admin states | **ENUMERATED, NOT DESIGNED** — *"11 states listed (§14); **no frames**"* | `CONF-D5` §5 `:204` |
| **Approved screen package** | **ABSENT** | `:337` |

**One of the four design inputs is now present; three remain absent, unlocked or undesigned.** §89
corrected two of these rows and left one wrong, concluding a designer had *"the 11 state frames and
nothing else"*. **There are no frames** — §5 `:204` records the 11 states as *"ENUMERATED, NOT
DESIGNED"*, and the four supplied screens are populated dashboard/analytics views, not state frames.
**That was the third correction to this table; recorded at §91.2 rather than quietly amended.**

What a designer actually has: the **logo** (`apps/mobile/assets/images/12circle-logo.png`, verified), a
**mobile/consumer theme** (`app_theme.dart`, `twelve_circle_theme.dart`, with no shared design-system
dependency), and the owner's supplied visual reference (§9.6).

The member-side precedent is a design **board** (`12Circle Fitness - Complete Board.dc.html`, 110
`.phone` frames) regenerated into reference images by `capture-references.mjs`. **No Admin or Trust
frames exist on it.** The commissioned work must add them, or an equivalent authoritative source.

---

## 6 · UNRESOLVED — a designer cannot proceed past these without a ruling

Each is a real gap in the record. **None is filled here.**

### 6.1 The thirteenth Admin domain
`AD-01` claims 13 and names 12. **Owner must name the thirteenth, or correct the count to 12.**

### 6.2 The surface set
§19.4 adopts **no** count, and no tracked source states one. **Owner must adopt a surface
enumeration** — the ten named in §4, one of the untracked counts, or a new list.

### 6.3 Four design-authority conflicts, absent from §19/§20's resolved ledger
`V5_FINAL_DESIGN_AUTHORITY_RECONCILIATION:337` lists Admin's blockers as **`CONF-D4` / `CONF-D5` /
`CONF-D6` / `CONF-D7`**, plus **`CONF-D8`** (data-access model) and **`CONF-D2`** (whether Trust is a
surface). **Verified: zero of these appear in §19 or §20's resolved ledger.** Two matter directly:

- **`CONF-D7` — the role matrix.** Without it the design cannot say which role sees which surface.
  The roles that now exist are `client` · `coach` · `vendor` · `admin` · `content_manager` ·
  `trust_operator` · `erasure_executor` (migrations 142, 147).
- **`CONF-D8` — the data-access model.** Without it the design cannot say what data each surface
  shows. `D7` fixes the *mechanism* (column-limited views); it does not enumerate the columns.

> **These are NOT the Admin decisions `D4`–`D7`.** §18 warns that `CONF-D4/D5/D6/D7` are different
> items and that *"that string must never be read as `D5`/`D6`."*

### 6.3b The visual foundation itself — `CONF-D5` and `CONF-D6`
`CONF-D5`: the Fitonist reference the brief names is **not on disk**, so *"the visual system is
unspecifiable."* `CONF-D6`: there is **no locked identity package**, so *"token values and chart
identity are blocked."* **Both are recorded OWNER decisions.** Design cannot begin on a visual system
that has no reference and no locked tokens.

> **STATUS 2026-09-30: `CONF-D5` RESOLVED · `CONF-D6` STILL OPEN, narrowed.** The owner supplied the
> reference, so the first half of this paragraph no longer describes the state — see §9.6. The second
> half stands: a rendering is not a token package. **§6.3b is half-closed, not closed.**

### 6.4 Trust's information architecture
`D11` gives three areas; **no ruling gives their navigation, hierarchy or entry points.**

### 6.5 Incident authoring in the surface
Owner decision **B1** restricts incident creation to `admin` and `trust_operator` through
`audit_open_incident()`. **Which surface hosts that action is not ruled** — Trust is a *review* surface
that *"introduces no tables of its own"*, yet B1 grants `trust_operator` the authority to open one.
**Recorded; not resolved.**

---

## 7 · Naming collisions a designer or agent will hit

| string | distinct meanings |
|---|---|
| **`D5`** | Admin data-access decision (§19.4) · `CONF-D5` design-authority conflict · `D-5` = `PD-A24` (§8.21) · **§68's signer design D5** ("signs the complete row") · a verification report's own `## D5 ·` heading |
| **`D6`** | Admin surface decision (§19.4) · `CONF-D6` · a verification report's own `## D6 ·` heading |
| **`A14`** | `D4 · A14` Trust-visibility ruling (§19.2) · design-authority `A14` Admin success criterion (§2 above) |

**Four distinct `D5`s exist in the tracked tree.** A naive grep hits the wrong one first.

---

## 8 · Scope of this commission

**Commissioned:** Admin and Trust design surfaces, honouring §1, scoped by §2 and §3, subject to §6.

**Explicitly NOT commissioned:** AI Guardian (**P7**) · wearable surfaces (**P3**, deferred under
`PD-G01`) · any member-facing screen · any implementation.

**Delivery target:** an approved screen package on the authoritative board, or an equivalent tracked
source, sufficient to satisfy §20.2's *"`CONF-08` artefacts"*.

---

## 9 · OWNER DECISIONS APPLIED — 2026-09-30

Three of the five §6 items are **resolved by owner decision**. Two were **not yet resolvable** at the
time of writing (§9.5); **one of those two was resolved by a second owner input the same day — §9.6.**

### 9.1 `CONF-D2` — RESOLVED: Trust is a top-level area WITHIN the Admin Control Center

**Owner decision.** Trust is a top-level area **inside** the Admin Control Center, consistent with the
supplied design. **Not a separate application or product.**

This is §2's reading **(B)** — *"capabilities within Admin"* — which §2 recorded as **supported**:
*"of the four candidate readings, (B) and (C) are supported and (A) is not."*

> **`CONF-D2` is closed. The old ambiguity is not preserved as if the decision had not occurred.**
> §2's determination that (A) *"has no support in either source"* is now moot rather than contested.

### 9.2 `CONF-D1` — RESOLVED: the adopted Admin IA is six items

**Owner decision.** The navigation in the supplied design is the adopted Admin IA:

**Dashboard · People · Ecosystem · Trust · Operations · Settings**

**No additional navigation item may be invented.** This supersedes the 8-item-vs-13-domain mismatch
`CONF-D1` recorded: neither the brief's 8 nav items nor an extended nav is adopted — a **six-item** IA is.

### 9.3 Admin scope — RESOLVED: TWELVE domains, and there is no thirteenth

**Owner decision.** The intended Admin-controlled domains are the twelve enumerated:

**Health · Security · Users · Roles · Payments · AI · Wearables · Database · Incidents · Releases ·
Analytics · Audit**

**There is no thirteenth domain.** The historical *"13 domains"* figure is a **source discrepancy**, and
`AD-01`'s own restatement enumerates twelve while claiming thirteen. **No thirteenth is invented.**

### 9.4 Domain → IA mapping: THREE established, NINE open

Mapped **only** where the authoritative record establishes it.

| domain | IA placement | basis |
|---|---|---|
| **Security** | **Trust** | `D11` §19.2 — Trust's scope is *"Security · Incidents · Audit Logs"* |
| **Incidents** | **Trust** | `D11` §19.2 |
| **Audit** | **Trust** | `D11` §19.2 |
| Health · Users · Roles · Payments · Analytics · Database · Releases | **NOT ESTABLISHED** | no authoritative statement places them |
| **AI** | **NOT ESTABLISHED**, with one negative constraint | §19.2: *"AI Guardian remains **P7** and is **NOT** inside Trust"* — so not Trust; where it does go is unstated |
| **Wearables** | **NOT ESTABLISHED**, and its phase is deferred | P3 deferred under `PD-G01` |

> **Nine of twelve placements are an explicit remaining design question**, per the instruction not to
> invent domain behaviour to populate navigation. `Dashboard`, `People`, `Ecosystem`, `Operations` and
> `Settings` have **no authoritative domain assignment at all**.

### 9.5 `CONF-D5` and `CONF-D6` — NOT YET RESOLVABLE *(superseded in part by §9.6)*

> **This subsection is the record as it stood before the screenshots arrived. It is retained, not
> rewritten** — the programme's rule is that a superseded finding keeps its own text and gains a
> pointer. `CONF-D5` is now resolved (§9.6); `CONF-D6` is not.

The owner's decisions on both rest on *"the supplied screenshots"*. **No screenshots were received.**
They are therefore **not applied**, and nothing has been substituted for them — §5's lead imagery is
**not** adopted, because `CONF-D5` requires the reference to be *identified*, and which files the owner
means is unknown.

**What is needed:** the screenshot artefacts themselves, or the exact paths of the files the owner
intends, so they can be recorded as the 12Circle+ visual reference (`CONF-D5`) and the 12Circle+ visual
system direction (`CONF-D6`) — **not** as the unmodified Fitonist product, and **not** as the 12Circle+
identity being the Fitonist identity.


### 9.6 SCREENSHOTS RECEIVED — `CONF-D5` RESOLVED, `CONF-D6` NOT — 2026-09-30

**The screenshots §9.5 was waiting for were supplied, and they are accessible.** Verified before any
claim was made about them: four images read and described, then committed to
`docs/design/admin-control-center/` with a provenance `README.md`, because `CONF-D5`'s recorded defect
was *"disk: **not found**"* — an artefact held only in ephemeral session storage would leave that defect
live.

Recorded as the owner stated them: **the 12Circle+ Admin design — Fitonist-DERIVED, MODIFIED for
12Circle+.** Not the unmodified Fitonist product, and **the visual system is not Fitonist branding.**
The screens carry their own *"All figures are sample design-state data"* disclaimer.

#### 9.6.1 `CONF-D5` — RESOLVED

`CONF-D5`'s defect was specific and it is now cured: the reference **exists**, is **identified** (no
longer *"unidentified dashboard imagery"*), and is **tracked in the repository**. The visual system is
no longer *"unspecifiable"*.

**What the reference establishes.**

1. **The six-item Admin IA, confirmed visually** — `Dashboard · People ▾ · Ecosystem ▾ · Trust ●▾ ·
   Operations ●▾ · Settings`, matching §9.2's `CONF-D1` decision item-for-item, with status dots on
   Trust and Operations.
2. **A visual system direction** — dark surface; violet primary accent with an amber secondary; green
   operational / red critical; large light-weight numeric readouts; a card grid with generous radii;
   pill segmented time-range controls (Today / 7 / 30 / 90 days).
3. **Product framing that constrains the design** — a staging banner (*"Staging environment — changes
   here do not affect members"*), a `Staging` environment pill, a `D. Mac · Platform admin` identity,
   and a *Needs your attention* drawer whose footer reads *"Actions open the item. **Nothing is changed
   from this screen.**"* That footer is a **read-then-act** discipline consistent with §3's Trust-as-a-
   review-surface scope; it is observed in the reference, not adopted as a ruling here.

#### 9.6.2 `CONF-D6` — STILL OPEN

`CONF-D6`'s defect is a different defect and the screenshots do not cure it. It requires a **locked
identity package**; four renderings give **direction, not values**. There are no hex values, no type
scale, no spacing scale, no chart identity specification. **`CONF-D6` remains an owner/design-input
boundary**, now narrowed from *"there is no reference at all"* to *"the reference is not yet reduced to
locked tokens"*.

#### 9.6.3 What the reference does NOT establish — stated so it is not over-read

| still open | why the screenshots do not close it |
|---|---|
| **`CONF-D6`** token values / chart identity | a rendering is not a token package (§9.6.2) |
| **The nine open domain placements** (§9.4) | **every dropdown — `People`, `Ecosystem`, `Trust`, `Operations` — is closed in all four screens.** No sub-navigation is visible anywhere, so the reference adds nothing to §9.4. The three placements that hold still hold on `D11` alone |
| **The 11 Admin states** | *"ENUMERATED, NOT DESIGNED … no frames"*. These four screens are **populated** states; empty, loading, error, denied and the rest are not among them |
| **`CONF-D7`** the role matrix | the reference shows one identity, `Platform admin`. It says nothing about `coach` · `vendor` · `content_manager` · `trust_operator` · `erasure_executor` |
| **`CONF-D8`** the data-access model | the tiles show figures, not the columns a surface is permitted to read |
| **§6.2** the surface set | four screens are not a surface enumeration, and none of the four is a Trust, Audit or Incident surface |
| **Responsive behaviour, component specs, iconography** | not derivable from four fixed-width captures |
| **§6.5** incident authoring placement | no incident-authoring affordance appears in any screen |

#### 9.6.4 `CONF-08` is NOT satisfied

**Stated explicitly, because the arrival of design imagery is exactly the point at which this gate gets
skipped.** `CONF-D4` holds that *"a brief cannot serve as design authority"*, and by the same standard
**four dashboard renderings are not the approved screen package** §8 commissions. §5's fourth row —
**Approved screen package: ABSENT** — is unchanged.

**`CONF-08` therefore remains NOT SATISFIED, and P5 remains unauthorized.** What the screenshots did was
resolve one of the *inputs* `CONF-08` depends on. The sequence is unchanged and only its first step is
complete:

> screenshots accessible **✓** → reconcile `CONF-D5`/`CONF-D6` **✓ (D5 resolved, D6 open)** → reassess
> `CONF-08` **✓ NOT satisfied** → formal approved design package **✗ OUTSTANDING** → P5 when authorized
> **✗ NOT AUTHORIZED**

**No Admin UI implementation follows from this reconciliation.**
