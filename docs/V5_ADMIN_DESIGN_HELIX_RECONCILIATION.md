# V5 — ADMIN DESIGN × HELIX × ARCHITECTURE RECONCILIATION

**Ingestion of `design/12circle-plus-admin-dashboard` (`931218b`) as the authoritative 12Circle+ Admin
Dashboard design package, reconciled against V5 architecture, governance and the Helix design system.**

**Analysis only. Nothing was implemented, rewritten, scaffolded or redesigned. V5 §102 governs throughout:
no approved capability is deleted, simplified, hidden or redesigned to fit the current architecture.**

---

## 0 · Headline results

| | |
|---|---|
| **Helix conformance** | **Far higher than expected. 11 of 11 shared colour roles match the shipped Helix theme EXACTLY**, as do the brand typeface and the signature easing curve. §2. |
| **Nocturne** | **Not Helix, not a Helix predecessor.** It is the *design tool's* baseline design-system runtime, shared across every 12Circle `.dc.html` artifact. **The bundle was located on disk.** §7. |
| **Trust IA** | **No longer absent.** The package designs the full Trust page. This closes one of the four §97.4 gates. §1. |
| **Domain placement** | **11 of 12 Admin domains are now placed by approved design.** `Database` is the one that is not. §1.3. |
| **The 11 states** | **No longer *"enumerated, not designed"*.** Ten state patterns are designed across all six pages. §1.4. |
| **Genuine conflict** | **One**: the approved Trust page contains `#ai-guardian`; `D11`/§19.2 rules *"AI Guardian … is **NOT** inside Trust."* §6.1. |

---

## 1 · Design capability inventory

Six approved pages, six-item IA — `Dashboard · People · Ecosystem · Trust · Operations · Settings` —
confirmed by `SCREEN-INVENTORY.md`, which also states the build spec's older eight-item nav *"is
historical and is **not** used"*. **The design package itself defers to `CONF-D1`.**

| Page | Sections |
|---|---|
| **Control Center** (Dashboard) | attention queue + drawer · Ecosystem snapshot · Ecosystem activity · Events & community · Security · AI Guardian · Wearable intelligence · QA & release · Recent admin activity · Installs / Age range / Impressions · Dashboard states · *"Requires architectural verification"* notes panel |
| **Ecosystem** | `#overview` `#community` `#events` `#training` `#monetization` `#wearables` + audit pattern |
| **People** | `#users` `#coaches` `#clients` `#partners` `#states` |
| **Trust** | `#overview` `#ai-guardian` `#security` (+`#sec-authz`) `#incidents` `#audit` (explorer, before/after) `#trust-system` |
| **Operations** | `#overview` `#releases` `#integrations` `#system` (+`#sys-events`) `#ops-system` |
| **Settings** | `#overview` `#organization` `#users` `#roles` `#platform` `#notifications` AI & intelligence `#privacy` `#security` `#integrations` `#billing` `#states` |

Two superseded designs (`Control Center v1`, `Admin Dashboard`) are preserved and labelled.

### 1.1 Components required by the approved pages

From `COMPONENTS.md`: environment strip (34px) · header with six-item nav · user menu · search · card ·
panel · drawer · dialog · menu · **table with sticky header and row actions** · stat tile · sparkline /
bar / line chart · severity badge · status pill · progress bar · timeline · **audit row with before/after
diff** · text · select · segmented control · switch (`role=switch`) · checkbox · radio · search · date
range · toast · inline error · empty state · skeleton · degraded banner · permission-denied panel ·
read-only banner.

**≈30 component types.** `COMPONENTS.md` records that a per-component specification sheet (anatomy,
variants, spacing annotations) **has not been produced** — listed as missing, §7.

### 1.2 Interactions

Attention queue opens a drawer · every *"View audit history"* deep-links to **Trust › Audit logs** ·
before/after diffs deep-link to a Trust audit event · Settings cross-links to Operations › System events,
Trust › Authorization and Trust › AI Guardian · global search and table filters · **row actions open
confirm dialogs for destructive changes**.

### 1.3 Domain placement — §97.4 gate 4, now largely answered by approved design

§91 ruled twelve Admin domains; §97.4 recorded **nine unplaced**. The approved pages place them:

| domain | placement | basis |
|---|---|---|
| Security · Incidents · Audit | **Trust** | `D11` **and** the approved Trust page |
| **Users** | **People** `#users` | approved design |
| **Roles** | **Settings** `#roles` | approved design |
| **Health** | **Operations** `#system` / `#sys-events` (+ Control Center tiles) | approved design |
| **Releases** | **Operations** `#releases` | approved design |
| **Wearables** | **Ecosystem** `#wearables` | approved design |
| **Payments** | **Ecosystem** `#monetization` **and** **Settings** `#billing` | approved design — **two placements, deliberate split (operational view vs configuration)** |
| **Analytics** | **Dashboard** (Installs / Age / Impressions) + **Ecosystem** `#overview` | approved design |
| **AI** | **Trust** `#ai-guardian` | approved design — **⚠ conflicts with `D11`/§19.2, see §6.1** |
| **Database** | **NOT PLACED** | no section in any approved page |

**Eleven of twelve placed. `Database` is unplaced and is NOT removed** — it remains an approved §91 domain
awaiting placement.

### 1.4 States — §97.4 gate 6 is now STALE

The record said the 11 states were *"ENUMERATED, NOT DESIGNED … no frames"*. **That is no longer true.**
`SCREEN-INVENTORY.md`: **Loading · Empty · Error · Permission (denied) · Degraded** in all six pages, plus
**Unavailable · Stale · Offline · Skeleton · Read-only**, with dedicated *"State system"* panels on People,
Trust, Operations and Settings and *"Dashboard states"* on the Control Center.

**Ten designed state patterns.** Against `A11`'s eleven, **two are not separately designed**:
**critical-incident** and **Guardian-approval-required**. They remain approved `A11` requirements with no
frame. The design also adds four states `A11` never named (Unavailable, Stale, Skeleton, Read-only) —
**preserved as approved capability under §102**.

---

## 2 · Helix conformance

### 2.1 Which Helix is authoritative — a correction that matters

Two artefacts both call themselves the 12Circle Helix theme:

| | |
|---|---|
| `/Users/dmac/Documents/projects/helix` → `src/themes/12circle.ts` | accent **`#9EF01A` electric lime**, Hanken Grotesk / Clash Display, `easing.spring`, pill buttons. Its own header says ***"FIRST PASS — values are meant to be tuned by design."*** |
| **`apps/mobile/lib/core/helix/` + `core/theme/twelve_circle_theme.dart`** | accent **`#7C3AED` violet**, **Schibsted Grotesk**, `Motion.emphasized`. **Conformance-tested in CI** by `design_token_conformance_test.dart`. |

**The in-repo Dart implementation is the live, enforced 12Circle Helix theme.** The standalone repo's
`12circle.ts` is a self-declared first pass and is **stale relative to the product**. The audit below is
against the enforced one.

### 2.2 Already Helix-conformant — 11/11 exact

| Admin token | value | Helix (`TwelveCircleTheme`) | match |
|---|---|---|---|
| `bg.canvas` | `#0a0a0b` | `bg` | ✅ |
| `bg.surface` | `#121215` | `surface` | ✅ |
| `bg.hover` | `#1b1b20` | `surfaceHigh` | ✅ |
| `text.primary` | `#f4f3f6` | `ink` | ✅ |
| `text.muted` | `#9b96a3` | `grey` | ✅ |
| `text.subtle` | `#8b8595` | `dim` | ✅ |
| `brand.violet` | `#7c3aed` | `violet` | ✅ |
| `brand.accent` | `#a78bfa` | `violetText` | ✅ |
| `status.success` | `#2fbf87` | `green` | ✅ |
| `status.warning` | `#e0a030` | `amber` | ✅ |
| `status.danger` | `#e8556d` | `red` | ✅ |

**Also exact:** typeface **Schibsted Grotesk** (Helix `fontDisplay`/`fontBody`/`fontNumeric`); hairlines
`rgba(255,255,255,0.08)` / `0.045` = Helix `border` `0x14FFFFFF` / `borderSubtle` `0x0BFFFFFF`; easing
`cubic-bezier(0.2,0,0,1)` = `Motion.emphasized`; `motion.fast` 120ms = `Motion.d120`.

**This is not a coincidence of taste — it is the same design system.** The Admin design and the shipped
mobile theme were authored from one identity. **Helix conformance on colour, type, hairline and signature
motion is already achieved.**

### 2.3 Requiring mapping / adaptation

| element | Admin | Helix | action |
|---|---|---|---|
| **Sunken surface** | `bg.inset` `#232326` (**lighter** than surface — a well on dark) | `surfaceSunken` `#070708` (**darker**) | **Different roles, same name family.** Map Admin `inset` to a new role; do **not** overload `surfaceSunken` |
| **Motion durations** | `base` 180ms, `slow` 240ms | `d120 · d200 · d300 · d450` | map `base`→`d200` (180≠200) or add primitives |
| **Radius** | `xs`4 `sm`6 `md`10 `lg`12 `xl`16 `2xl`20 `pill`999 | semantic `button/card/pill` only | Admin's 7-step ramp exceeds the 3-role contract |
| **Breakpoints** | tokens name 4 (1440/1200/900/768); pages use 6 (1439/1400/1199-1180/1100/900) | none in Helix | reconcile to one set, then add |

### 2.4 Requiring additive Helix extensions

**None of these is a conflict. Each is a token Helix does not yet carry.**

1. **Colour roles (4):** `bg.raised` `#16161a` · `bg.inset` `#232326` · `text.secondary` `#d0ccd6` ·
   **`status.info` `#7cb8f0`** — Helix has no `info` role at all.
2. **Status *text* and *tint* variants:** `successText/Tint`, `warningText/Tint/Border`,
   `dangerText/Tint/Border`, `text.onWarning`. Helix carries one flat value per status. **The Admin
   contrast table proves these are required, not decorative** — `brand.violet` is 3.5:1 and *"never used
   for text"*, which is exactly why `brand.accent` and the `*Text` variants exist.
3. **A type scale.** Helix Tier-2 carries font *families* only; Admin defines **10 named steps**
   (`overline … display`) with size/line/weight/tracking. This belongs in Tier 1 or a new Tier-2 group.
4. **Density/size tokens:** `control` 44px, `controlCompact` 40px, `rowList` 52px, `rowRich` 64px,
   `envStrip` 34px, icon sm/md/lg.
5. **Admin shadow semantics:** `menu · edge · divider · header` — structural insets, not Helix's
   elevation ramp `sm/md/lg/glow`. **Both are needed; neither replaces the other.**
6. **Z-index scale:** header 10 · menu 20 · dialog 50 · toast 60.
7. **Components.** Helix ships **three** (`Button`, `Card`, `MetricReadout`); Admin requires **≈30**.
   This is the single largest additive gap.
8. **Icons.** Phosphor Icons **v2.1.1**, `regular` default / `fill` for active, **107 icons** in use.
   Helix specifies no icon system.

### 2.5 Elements relying on a different design-system runtime

All eight `.dc.html` files link `_ds/nocturne-…/styles.css` and `_ds_bundle.js` (§7). **Measured
dependence on it is effectively nil:** Nocturne's accent `#9184d9` appears **0 times**; Nocturne class
names (`.btn .nav .tag .field .seg`) appear **0 times**; `.card` once. The approved pages carry **6,274
raw hex and 22,109 raw px values** of their own.

**Consequence for implementation:** the pages are **not** token-driven — `admin.tokens.*` was
*reverse-extracted* from them (`PROVENANCE.md`: *"Extracted from the six approved pages by counting values
actually used … Derived, not invented"*). Implementation must bind to tokens, so **the extraction is the
bridge, and it must be validated value-by-value against the pages before it is trusted.**

### 2.6 Genuine design-system conflicts

**None on values.** Two authority questions:

- **Which Helix is canonical** (§2.1). The standalone repo's lime first-pass contradicts the enforced
  violet theme. **Leaving both is the real risk** — a future consumer could bind to the wrong one.
- **Where Admin tokens live.** `BOUNDARIES.md` item G already records *"Admin tokens (`--adm-*`) vs
  Fitness Helix tiers | Architecture question | Both documented, no merge."* **Not merged here.**

---

## 3 · Current V5 architecture support

Unchanged from the data contract (§11) and §102.6, and **nothing is removed for lack of support**:

| served today | partial | no source |
|---|---|---|
| Total users · role counts · Recent admin activity · Security/audit/incidents (`audit_events`, `audit_incidents`, shipped + CI-verified) · Age (`date_of_birth`) · pods/posts · events · sessions/check-ins · wearable **connections** (`user_integrations`) | Wellness partners (no approval state) · Active coaches/clients (window undefined) · QA & release (exists in CI, not ingested) | DAU/WAU/MAU · Revenue decomposition · Platform health · AI Guardian · wearable **ingestion health** · Installs · Impressions · notification delivery · community moderation queue |

The design package reaches the same conclusion independently — the Control Center carries a *"Requires
architectural verification"* panel naming: no known admin data layer; service health; AI Guardian not in
code; **wearables are Android-first so HealthKit and Apple Watch need confirming**; CI cannot be read by
the app; audit log assumes an append-only store.

> **New finding from that panel.** *"Wearables are Android-first"* — yet the approved Wearable tile shows
> **Apple HealthKit** and **Apple Watch** as connected. `user_integrations.provider` is free text and
> `PD-B23` names Strava/WHOOP/Garmin/Polar/Spotify/MyFitnessPal — **not HealthKit**. The capability is
> **preserved**; platform coverage needs confirming against `WI-01`/`WI-08`.

---

## 4 · Additive architecture extensions required

Beyond §102.6's register, the six-page package adds:

| # | capability | extension | new? |
|---|---|---|---|
| E-1 | **Trust audit explorer with before/after diff** | `audit_events.delta` **already exists** (migration 150, `A6`). A read/query surface and deep-link addressing are needed | mostly **supported** |
| E-2 | **Deep-link addressing** — every audit link targets a Trust audit event | stable public identifiers for audit rows; `A12` constrains what an identifier may expose | new |
| E-3 | **Destructive-action confirm dialogs + row actions** | each is a privileged write ⇒ `CONF-D7` cell **and** an `A10` audit emitter | new |
| E-4 | **Settings configuration surfaces** (org, platform, notifications, AI, privacy, security, integrations, billing) | a settings/config store with change audit. `platform_settings` exists (`039`) but covers one key | largely new |
| E-5 | **Coach verification · client assignment · partner onboarding** | state machines on People | new |
| E-6 | **Releases + environments + integrations health** | ingest CI; `P10` constraint applies | new |
| E-7 | **Global search across users, events, incidents** | cross-domain search respecting `A10` boundaries | new |

---

## 5 · Security / RLS / governance implications

1. **`A10` governs the whole surface** — *"dashboard data must respect the same authorization boundaries
   as the underlying system."* `CONF-D8` remains open and remains behind `CONF-D7`.
2. **Every row action and confirm dialog is a privileged write** ⇒ a `CONF-D7` cell and an audit emitter.
   The Settings page alone adds eight configuration domains.
3. **The audit explorer's before/after diff is the sharpest PHI surface in the package.** Migration 150
   deliberately **excludes** `phi_correction` and the five occurrence categories from `delta`. **A Trust
   explorer that rendered a diff for those categories would defeat `A6`'s exclusion.** Preserved; not
   designed; a boundary.
4. **The `A12` re-identification boundary (§102.5) applies to People, Trust and the attention queue** —
   the design shows named accounts while the Event population carries a pseudonym.
5. **`#sec-authz` (Trust › Authorization)** reads directly onto the `CONF-D7` matrix — the design assumes
   a surface for a model that does not yet exist.
6. **Contrast is specified and self-enforcing** — `admin.contrast.md` gives measured ratios and the rule
   that `text.disabled` and `brand.violet` are *never* used for text. **Adopt as an accessibility gate.**

---

## 6 · Genuine owner decisions

### 6.1 NEW — AI Guardian inside Trust (§102 governance exception)

| | |
|---|---|
| **Approved design** | Trust page section **`#ai-guardian`**; Settings cross-links to *"Trust › AI Guardian"* |
| **Governing V5 authority** | `D11` / §19.2 — *"Trust's scope = Security · Incidents · Audit Logs. **AI Guardian remains P7 and is NOT inside Trust.**"* |
| **Nature** | A **scope/phase** conflict, not a security one. The approved design places a P7 capability inside the P6/Trust surface |
| **Disposition** | **Capability PRESERVED. Not implemented, not deleted, not relocated.** §102: preserve · name the conflict · name the authority · **stop** |
| **Decision required** | Does the approved design supersede §19.2's exclusion, or does AI Guardian render elsewhere? **Owner.** |

### 6.2 Design-system authority

**Which Helix is canonical** — the standalone repo's lime first-pass or the enforced in-repo violet theme
(§2.1) — and **where Admin tokens live** (`BOUNDARIES.md` G). **Design-system authority decisions.**

### 6.3 Carried forward, unchanged

The five of §100.5 · `PD-C03` · `CAP-1`'s policy question · the `A12` boundary (§102.5) ·
`BOUNDARIES.md` A–G. **None resolved here.**

### 6.4 Explicitly NOT owner decisions

**`Database` domain placement** (§1.3) — a design placement question. **Token extensions** (§2.4) —
additive design-system work. **Critical-incident and Guardian-approval-required state frames** (§1.4) —
design work against an existing `A11` requirement.

---

## 7 · Missing design-system artifacts and dependencies

### 7.1 Nocturne — identified from evidence

**Nocturne is the design tool's baseline design-system runtime. It is NOT Helix and NOT a Helix
predecessor.**

| evidence | finding |
|---|---|
| Occurrences of "nocturne" | **0** in Helix (src + dist), **0** in the 12circle-fitness repository, **9** in the design package |
| **The bundle was located** | `/Users/dmac/Desktop/community-portal/_ds/nocturne-042b8c43-…/` and `/Users/dmac/Desktop/mobile-app/_ds/nocturne-042b8c43-…/` |
| **Same instance UUID** | shared by the **Admin dashboard**, the **12Circle Mobile App** design and the **community portal** designs ⇒ one tool-level system, not an Admin dependency |
| Its own `readme.md` | *"Nocturne is a quiet, compact dark interface … a single accent **#9184d9**"*, Inter, 8px radii, Phosphor icons, `.btn/.tag/.field/.card/.nav`, *"derived from `theme.json`"* |
| Token namespace | `--color-bg/--color-text/--color-neutral-100…900` (OKLCH ramps) — **disjoint** from Helix's `--color-surface/--color-text-primary/…` |
| `support.js` | *"GENERATED from **dc-runtime**/src/*.ts"*, requires `window.React` |
| `image-slot.js` | *"@ds-adherence-ignore — **omelette starter** scaffold"* |

**Classification: an unrelated, tool-level dependency of the design artifacts.** It is **not renamed, not
substituted, and not assumed to be Helix.** It is required only to *view* the `.dc.html` files at full
fidelity; **it is not a product runtime and must not be shipped.**

**Status: available but not published.** The bundle is on the Desktop, outside the repository. It was
**not** copied into the design branch — that is a publication decision outside this analysis task.

### 7.2 Other missing artifacts

| missing | source |
|---|---|
| Per-component specification sheets (anatomy, variants, spacing) | `COMPONENTS.md` — *"has **not** been produced"* |
| Admin phone layout below 480px | `RESPONSIVE.md` — *"has **not** been separately designed"* |
| Logo: light-ground variant, one-colour, icon-only crop, clear-space, minimum size, transparency check | `brand/README.md` |
| `critical-incident` and `Guardian-approval-required` state frames | §1.4 vs `A11` |
| `mobile/` design authority | out of scope by instruction |
| `_backup-admin-cc-pre-panels.dc.html.txt` | referenced by `PROVENANCE.md` |

---

## 8 · Implementation boundaries and sequencing

**No implementation is authorized. P5 remains gated.**

**Gate movement from this ingestion — two of four §97.4 gates move:**

| gate | before | after |
|---|---|---|
| `CONF-D6` identity package | OPEN — no tokens | **NARROWED, not closed.** Tokens now exist and match Helix 11/11; but they are **derived**, and the logo package is incomplete (§7.2). **A derived extraction is not an owner lock.** |
| `CONF-D7` role matrix | OPEN | **OPEN, unchanged** — and `#sec-authz` now has a surface awaiting it |
| **Trust IA** | **OPEN — external design authority** | ✅ **CLOSED.** The Trust page is designed |
| Nine domain placements | OPEN | **11 of 12 placed**; `Database` outstanding |

**Sequence the evidence supports** — no step authorized by this document:

1. **Validate the token extraction** against the six pages value-by-value (§2.5). Everything downstream
   binds to it.
2. **Resolve §6.1** (AI Guardian in Trust) and **§6.2** (canonical Helix) — both block structure.
3. **`CONF-D7`**, which unblocks `CONF-D8` and every row action, confirm dialog and `#sec-authz`.
4. **Additive Helix extensions** (§2.4) — tokens first, then the ≈30 components.
5. **`CONF-D9` architecture** per §102.6 and §4, in the order the data contract gives.
6. **P5 only when its gates are satisfied.**

**Nothing in this reconciliation removes, simplifies, hides or redesigns any approved capability.
`PD-G01`, `PD-A24` and `P10` are not released. No migration, application file, schema change or
production contact.**
