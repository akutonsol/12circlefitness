# V5 · `CONF-D8` — ADMIN AREA → DATA-SURFACE RECONCILIATION

**Analysis only. Nothing was created, altered or authorized. No mapping is invented: an area is recorded
as backed only where a surface demonstrably exists and the record says what governs it.**

Baseline: QA 155 · the approved capability matrix live and verified (425/425, V5 §125) ·
`CONF-D8`'s mechanism half `VERIFIED_CLOSED`, its surface half open (§126).

## 0 · Method, and the two rules that shaped the result

**A name is not a surface.** `events` backing the *Events* area is evidence; `integrations` would have
backed *Integrations* but **does not exist**, and the UI showing an Integrations tab is not proof of a
database surface.

**An additive `OR admin_can(...)` arm is only safe where it does not restore something an existing policy
deliberately removes.** That is the whole of the `A13·1` problem (§126.2) and it recurs.

**One pattern is already adopted and decided**, and most of the harder cases resolve to it: `D7` ruled
**column-limited views over `user_profiles`, not distinct modules**, and five such views already ship —
`public_profiles`, `conversation_participant_profiles`, `event_attendee_profiles`,
`team_member_profiles`, `coach_client_workout_stats`, each `WITH (security_invoker = off)`. **The curated
view is not a new idea here; it is the house pattern.**

---

## 1 · ECOSYSTEM

### 1.1 Community — **EXISTING** (moderation sub-capability: ARCHITECTURE_EXTENSION)

| | |
|---|---|
| Surface | `community_posts` · `post_comments` · `post_reactions` · `community_groups` · `accountability_pods` — all exist, all RLS-enabled (2/2/2/1/3 policies) |
| Boundary today | **member-scoped** (`auth.uid()`), plus public-read arms |
| Can consume `admin_can`? | **Yes, additively on SELECT.** Nothing is deliberately excluded, so an OR arm restores nothing |
| Security | Admin read is a **new cross-user read of member content** — `CONF-D8`'s actual subject. Not PHI, but personal |
| Constraints | — |
| Extension | **The reports/moderation queue does not exist** (`CAP-1`, §102.3). Zero report/moderation tables for community content; `050` moderates the *exercise library*, a different object |

### 1.2 Events — **EXISTING**

`events` · `event_registrations` · `classes` · `class_bookings`, all RLS-enabled (2/4/2/3). Member- and
coach-scoped. **`K-04` governs registration integrity and is CI-verified 9/9** — an additive admin SELECT
arm does not touch its write path. Safe to consume `admin_can` on read.

### 1.3 Training — **EXISTING**, with a PHI caution

`workout_programs` (3) · `workouts` (1) · `workout_sessions` (3) · `workout_logs` (1), all RLS-enabled and
member-scoped. **Caution:** these are health-adjacent and sit under the PHI regime; `D17`'s fix-first
ruling and `SEC_PHI` apply to any view that redefines them. An **aggregate** admin surface (counts,
completion) raises nothing; a **row-level** admin read of a member's training history is a PHI disclosure
decision, not a mechanical one.

### 1.4 Monetization — **EXISTING** for entities · **ARCHITECTURE_EXTENSION** for the metrics

`subscriptions` (1) · `payments` (2) · `coach_packages` (2) exist. **But §99.2 established `subscriptions`
carries no amount and no currency** — so the *entities* are authorizable today while **revenue
decomposition is absent architecture**, and `PD-C03` (currency) plus the gross-vs-commission split remain
owner decisions.

### 1.5 Wearable intelligence — **EXISTING** (connections) · **ARCHITECTURE_EXTENSION** (ingestion health)

`user_integrations` (`011:29`) exists, RLS-enabled, member-scoped — it backs *"Apple HealthKit: Connected"*
and the device count. **Ingestion health (`~40 min behind`, error counts) is `WI-13`, which is deferred
under `PD-G01` and is NOT released.** The area splits exactly as §100.4 determined.

---

## 2 · TRUST

### 2.1 AI Guardian — **EXISTING** (`governance_policy*`) · **ARCHITECTURE_EXTENSION** (runtime) · plus `PD-A05`

| | |
|---|---|
| Surface | `governance_policy` + 4 companions (migration 154), RLS-enabled, gated `is_admin() OR is_trust_operator()` |
| Can consume `admin_can`? | **Yes, additively** — 154 is new infrastructure, not a V5-ruled population, and nothing in its policy is an exclusion |
| Extension | **Guardian runtime state does not exist** — no `ai_agents`, no evaluation store. That is **`P7`** |
| ⚠ Separate constraint | **`decision_traces` exists** (`089:17`) and is governed by **`PD-A05`**, an *answered* owner decision about who may read a trace. **Any Guardian surface touching it inherits `PD-A05`, not the capability matrix** |

### 2.2 Security — **CURATED_VIEW_REQUIRED** · detectors are ARCHITECTURE_EXTENSION

**No `security_events` or `auth_events` table exists.** The Security area's content is a *projection* of
`audit_events` (authorization/authentication categories) — which carries the `A13·1` exclusion — plus
detectors that do not exist (*"sign-in anomalies"* has no detector, §98.2).

**So Security cannot attach to a base table.** It needs the same curated projection as *Audit logs* (§2.4),
and its anomaly content needs new architecture.

### 2.3 Incidents — **CURATED_VIEW_REQUIRED**

`audit_incidents` (1 policy) and `audit_incident_transitions` (1) exist. The existing policy is already
`is_admin() OR is_trust_operator() OR actor_identity = auth.uid() OR is_active_coach_of(actor_identity)` —
**no exclusion**, so an additive arm restores nothing.

**But the population carries `evidence jsonb` and a real `actor_identity`.** The approved matrix grants
`Viewer` **View** on Incidents, so an additive arm would expose an unbounded evidence blob to the
least-privileged role. **A projection omitting `evidence` is the least-privilege form**; the base table is
not. Recorded as a recommendation, **not a decision**.

### 2.4 Audit logs — **CURATED_VIEW_REQUIRED** · the hard constraint

`audit_events`, policy `A13·1`:

```sql
USING ( (public.is_admin()
         AND NOT (category = 'admin_action' AND actor_id = (SELECT auth.uid())))
        OR public.is_trust_operator() )
```

**`AND NOT` is a deliberate exclusion: an admin may not read their own `admin_action` rows.** Adding
`OR admin_can('Audit logs','view')` **restores exactly what the exclusion removes** for any Admin-layer
holder. **Forbidden**, and the instruction says so explicitly.

**The curated-view approach evaluated first, as directed, and it works:**

- a view over `audit_events` that **carries the `A13·1` exclusion in its own `WHERE`**, so the exclusion
  survives rather than being bypassed;
- `WITH (security_invoker = off)` — the established pattern (`101`, `110`);
- the **view** gated on `admin_can('Audit logs','view')`, so the Admin layer is authorized *separately*
  from the base table, which keeps its policy unchanged;
- subjects remain **pseudonymous** — `audit_events` carries `subject_pseudonym`, never a subject id, so
  **`A12` is preserved by construction** and no re-identification path is created;
- least privilege: `Viewer` sees the permitted population and nothing more.

**This is `CONF-D8`'s second option and `D7`'s adopted pattern, applied to the one case that cannot take
the first.**

---

## 3 · OPERATIONS

### 3.1 QA — **NO_BACKING_SURFACE**
No `qa_runs` or `test_results` table. The data exists **in GitHub Actions** (§98.2) and is not ingested.
Ingestion is additive architecture under **`P10`'s unresolved installation constraint**, which is not
released.

### 3.2 Releases — **NO_BACKING_SURFACE**
No `releases` or `deployments` table, and **no version registry anywhere** (§1.6/§6 of the data contract).

### 3.3 Integrations — **EXISTING** (connections) · **ARCHITECTURE_EXTENSION** (health)
`user_integrations` exists and is member-scoped; **no `integrations` table** for provider-level health.
`PD-B23` names the provider set. Same split as *Wearable intelligence*, and the two areas **share one
table** — worth noting, because an `admin_can` arm there serves both areas and must satisfy the stricter.

### 3.4 System — **EXISTING** (`observability_events`) · **ARCHITECTURE_EXTENSION**
`observability_events` (migration 145) exists, RLS-enabled, gated `is_admin() OR is_trust_operator()`, and
**carries no subject identifier at all** (D12·Q5) — so it is `A12`-safe by construction and can take an
additive arm. **`system_events` and `background_jobs` do not exist**; the six platform-health tiles have no
source (§99.2), and `PD-A24 = C` requires any build to be vendor-free.

---

## 4 · SETTINGS

### 4.1 Organization — **NO_BACKING_SURFACE**
**No `organizations` or `organization_settings` table exists.** The approved Settings page shows an
Organization profile; nothing backs it.

### 4.2 Users — **CURATED_VIEW_REQUIRED**, and this is already ruled

`user_profiles` exists with **9 policies** and `enforce_profile_privilege()` guarding `role`,
`membership_tier`, `marketplace_commission_rate`, `stripe_charges_enabled`, `is_demo`.

> **`D7` already decided this area: *"COLUMN-LIMITED VIEWS over `user_profiles`, not distinct modules …
> column-limited views enforce least privilege at the data layer."*** Five such views already ship.

**So the Admin Users surface is a column-limited view gated on `admin_can('Users','view')` — not an arm on
`user_profiles` itself.** `Support`'s single non-View grant, `Users · Update`, must therefore write through
a constrained path that **cannot touch the privilege columns** `enforce_profile_privilege()` protects.
**That is the sharpest write-path question in the matrix.**

### 4.3 Roles — **EXISTING**, read-only, and the write boundary must not move

`admin_role_assignments` (2 policies) and `admin_role_capabilities` (2) exist from migration 153. The
approved matrix gives **every role `View` only** on this area.

**Reads may consume `admin_can('Roles','view')` additively. Writes must remain on legacy `is_admin()`,
exactly as 153 built them.** D13 proves a Viewer is refused both tables with 403/403. **The capability
matrix does not authorize self-grant or self-promotion, and nothing here may create that authority.**

### 4.4 Configuration — **EXISTING**, with a pre-existing defect worth flagging

`platform_settings` (migration 039) exists with two policies. **Its read policy is
`FOR SELECT TO authenticated USING (true)` — every authenticated user can read platform settings today.**
Writes are admin-gated.

**That is a pre-existing posture, not something this work introduces**, and an `admin_can` arm would
*narrow* nothing because the table is already world-readable to authenticated callers. **Recorded as an
observation for the owner; no change proposed here.** The area also holds one key only (§99).

---

## 5 · Consolidated classification

| # | Group | Area | Backing surface | Classification |
|---|---|---|---|---|
| 1 | Ecosystem | Community | `community_posts` + 4 | **EXISTING** (+ `CAP-1` extension) |
| 2 | Ecosystem | Events | `events` + 3 | **EXISTING** |
| 3 | Ecosystem | Training | `workout_*` ×4 | **EXISTING** (PHI caution) |
| 4 | Ecosystem | Monetization | `subscriptions`, `payments`, `coach_packages` | **EXISTING** + **ARCHITECTURE_EXTENSION** |
| 5 | Ecosystem | Wearable intelligence | `user_integrations` | **EXISTING** + **ARCHITECTURE_EXTENSION** (`WI-13`, `PD-G01`) |
| 6 | Trust | AI Guardian | `governance_policy` ×5 | **EXISTING** + **ARCHITECTURE_EXTENSION** (`P7`) + `PD-A05` |
| 7 | Trust | Security | — (projection of `audit_events`) | **CURATED_VIEW_REQUIRED** |
| 8 | Trust | Incidents | `audit_incidents` ×2 | **CURATED_VIEW_REQUIRED** |
| 9 | Trust | **Audit logs** | `audit_events` | **CURATED_VIEW_REQUIRED** — `A13·1` hard constraint |
| 10 | Operations | QA | — | **NO_BACKING_SURFACE** (`P10`) |
| 11 | Operations | Releases | — | **NO_BACKING_SURFACE** |
| 12 | Operations | Integrations | `user_integrations` (shared with #5) | **EXISTING** + **ARCHITECTURE_EXTENSION** |
| 13 | Operations | System | `observability_events` | **EXISTING** + **ARCHITECTURE_EXTENSION** |
| 14 | Settings | Organization | — | **NO_BACKING_SURFACE** |
| 15 | Settings | Users | `user_profiles` | **CURATED_VIEW_REQUIRED** — `D7` already rules it |
| 16 | Settings | Roles | `admin_role_*` | **EXISTING** (read only; writes stay `is_admin()`) |
| 17 | Settings | Configuration | `platform_settings` | **EXISTING** (⚠ already world-readable) |

**7 EXISTING · 4 CURATED_VIEW_REQUIRED · 3 NO_BACKING_SURFACE · 3 EXISTING-plus-extension** (4, 5, 12, 13
carry both, counted once above).

## 6 · What this makes implementable, and what it does not

**Implementable without an owner decision — 7 areas** can take an additive `OR admin_can(area,'view')` arm
on SELECT, because nothing in their policies is an exclusion and no V5 ruling governs them otherwise:
Community · Events · Training (aggregate) · Monetization (entities) · Wearable/Integrations (connections) ·
System · Roles (read).

**Needs a curated view — 4 areas**, three of them because the base population carries something the Admin
layer should not receive wholesale (`A13·1`'s exclusion, unbounded `evidence`, `user_profiles`' privilege
columns). **`D7` already adopted this pattern and five such views ship.**

**Needs architecture before authorization — 3 areas** have nothing to authorize.

## 7 · Boundaries, stated precisely

1. **`Audit logs` / `Security` view design** — the projection must carry the `A13·1` exclusion in its own
   predicate. **Architecture/security decision: approve the curated-view approach, or rule that the
   exclusion does not apply to the Admin layer.** The first preserves the control; the second changes it.
2. **`Users · Update` for `Support`** — the one non-View grant outside Trust/Operations. It must not reach
   the columns `enforce_profile_privilege()` protects. **Write-path design + security review.**
3. **Training row-level admin read** — aggregate is mechanical; per-member history is a **PHI disclosure
   decision**.
4. **`Incidents` evidence exposure to `Viewer`** — projection or base table.
5. **`platform_settings` is world-readable to authenticated callers** — pre-existing; owner's call.
6. `CAP-1` · `PD-C03` · `P7` · `PD-G01` · `P10` · `PD-A05` — unchanged, each already parked.

**Nothing was created. No policy, view, migration or grant was written. `CONF-D8` remains open.**
