# V5 — ADMIN / TRUST DESIGN COMMISSION (`CONF-08`)

**Authoritative input to the design phase. No screen is designed here.**
Baseline: migration frontier 152, QA ledger 152, `V5_PROGRAMME_DEFINITION.md` §87.

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

| input | state | authority |
|---|---|---|
| Fitonist reference | **ABSENT** — *"disk: **not found**; unidentified dashboard imagery on Desktop … the stated visual foundation is absent · visual system unspecifiable"* | `CONF-D5` |
| Brand tokens / identity package | **NOT FINAL** — *"no locked package · brand not final · token values, chart identity **blocked**"* | `CONF-D6` |
| 11 state frames | present | `:337` |
| **Approved screen package** | **ABSENT** | `:337` |

**So three of the four design inputs are absent or unlocked.** A designer receiving this commission has
**the 11 state frames and nothing else** to build a visual system on. `CONF-D5` and `CONF-D6` are
**owner decisions** in their own right and are added to §6.

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
