# QA EVIDENCE LEDGER — 12Circle Fitness

The single classified index of findings. **This is an index, not a second report**: detail
lives in the documents referenced, and nothing is restated here that is recorded there.

- `docs/MOBILE_QA_SWEEP_2026-09-22.md` — technical + Android runtime QA (§1–§23)
- `docs/DESIGN_INTAKE_REPORT.md` — design package intake and repo conflicts
- `docs/DESIGN_ROUTE_IMPLEMENTATION_MATRIX.md` — FIT→route→implementation mapping

Classifications are used strictly, per brief §19: **PASS · FAIL · BLOCKED ·
NOT ESTABLISHED · OWNER DECISION · ENVIRONMENT LIMITATION**. A category is never converted
to make the ledger read better.

Repository: `chore/qa-environments-secure-ai-backend`. Last updated 2026-09-22.

---

## 1 · Defects found and fixed, each verified at runtime

| # | Finding | Evidence | Status |
|---|---|---|---|
| F-1 | Android app could not build at all — `flutter_local_notifications` 18.x requires core library desugaring, never configured in repo history | `:app:checkDebugAarMetadata` failure; `git log -S` empty | **PASS** — fixed `6fdfed9`, APK builds |
| F-2 | All four auth screens showed users a raw `AuthApiException(...)` object | On-device SnackBar, `emulator-5554` | **PASS** — fixed `320d565`, device shows "Invalid login credentials"; guard A-G2 mutation-tested |
| F-3 | App's user-facing name was `circle_fitness` in launcher, Settings and every permission dialog | Permission dialog screenshot | **PASS** — fixed `dfea573` to "12Circle Fitness"; re-verified on device; guard A-G3 mutation-tested |
| F-4 | `_IconBtn` declared a required `tooltip` it never read — control unlabelled | Source + guard | **PASS** — fixed earlier; guard A-G1 mutation-tested |

## 2 · Defects found, NOT fixed — each blocked on a decision, not on effort

| # | Finding | Evidence | Status |
|---|---|---|---|
| F-5 | Landscape: `splash_screen.dart:109` overflows 39 px, painting Flutter's overflow stripe across the "Get Started" CTA | On-device, `ROTATION_90`, reproduced on cold start | **OWNER DECISION** (OD-1) — no one-line fix exists (`Spacer` cannot sit in a `SingleChildScrollView`); design GAP-06 says landscape is not designed at all |
| F-6 | Password visibility toggle is **19.8 × 20.2 dp with no accessible name** — under half the 44 dp floor | `uiautomator` dump, 2.625 px/dp | **OWNER DECISION** (D-3 copy) — size fix is mechanical, the label is product copy |
| F-7 | "Forgot password?" 20.2 dp and "Sign Up" 19.8 dp targets | same dump | **OWNER DECISION** — same class as F-6 |
| F-8 | Text inputs expose their *value* but carry no accessible **name** | same dump | **OWNER DECISION** (copy) |
| F-9 | Intake welcome page collapses to **one merged accessibility node**; "Get Started" not separately focusable | dump ×2, plus 11-node control on next page | **FAIL** — real defect, origin not yet isolated → **NOT ESTABLISHED** for cause |
| F-10 | `event_ticket_screen` is unrouted — reached only via `MaterialPageRoute`, so no URL, no deep link, outside the router shell | `app_router.dart` grep + `events_screen.dart:81` | **OWNER DECISION** (OD-4, design GAP-09) |
| F-2b | Chat screen displayed four **fabricated messages** as the user's real coach conversation whenever a thread was empty or could not be created | `chat_screen.dart:88`, `messaging_service.dart:237-245` | **PASS** — fixed `0243867`; empty state restored, distinct failure state added, 840 tests pass |
| F-6b | Password toggle 19.8x20.2dp unlabelled | `uiautomator` before/after | **PASS** — now **43.8 x 43.8 dp, labelled "Show password"**, verified on device; copy is the design's own |
| F-11 | **No fonts are bundled and `allowRuntimeFetching` is never set** (defaults true) — every font is fetched from `fonts.gstatic.com` at runtime, so a first launch offline silently falls back to Roboto and the whole type system degrades | no `fonts:` in `pubspec.yaml`, no `.ttf`/`.otf` assets, no `GoogleFonts.config` anywhere | **OWNER DECISION** — bundle the family, or accept the degraded offline first run |

## 3 · Verified passing — stated because absence of evidence is not evidence

| Finding | Evidence | Status |
|---|---|---|
| App launches, authenticates against QA, navigates; no `FATAL`, no `E/flutter` in any pass | `emulator-5554`, API 35; session key `flutter.sb-eyqtldjqpgpljlqvpowh-auth-token` persisted | **PASS** |
| Keyboard insets correct — content resizes, footer relocates, nothing clipped or obscured | `mInputShown=true` + screenshot | **PASS** |
| Password masking is secure — masked field reports `password=true` and **withholds its value** from the accessibility tree | dump before/after toggle | **PASS** |
| System back returns to the previous screen and stays in-app | `dumpsys activity` | **PASS** |
| Landscape produces **no** `RenderFlex` overflow on the onboarding route | logcat + dump | **PASS** (distinct from F-5, a different screen) |
| Unit + widget suite | **840 tests pass** | **PASS** |
| Design token conformance | 14 assertions, mutation-tested | **PASS** |

## 4 · Design package

| Check | Status |
|---|---|
| Authoritative package identified, legacy package rejected | **PASS** — `DESIGN_INTAKE_REPORT.md` §1 |
| FIT-001…FIT-110 contiguous and machine-readable | **PASS** |
| manifest ↔ DESIGN_HANDOFF ↔ IMPLEMENT-THIS ↔ board | **PASS** — 0 mismatches across 110 screens |
| Components 25 vs 28 | **PASS** — resolved by the `shipped` field; my earlier FAIL was wrong |
| 105/110 FIT screens map to an existing route | **PASS** — `DESIGN_ROUTE_IMPLEMENTATION_MATRIX.md` |
| Design board carries no FIT ids — frame↔manifest linkage is by name only | **ENVIRONMENT LIMITATION** — automated visual regression breaks silently on a rename |
| `capture-references.mjs` baseline not yet generated | **NOT ESTABLISHED** — required before Visual QA (Phase 11) |

## 5 · Integration state

| Item | Status |
|---|---|
| Tier 1 — weight ramp extended below w400 (`light`, `extraLight`) | **PASS** |
| Tier 2 — contract extended: `borderSubtle`, `accentOnDark`, `displayWeight`, `displayTracking`; `helixDisplay`/`helixNumeric` now read the theme; tabular figures added | **PASS** |
| Tier 3 — 12Circle bundle retargeted to the design tokens (colour, shape, motion, type) | **PASS** — conformance-tested |
| **Screens consuming the semantic tokens** | **0 of 158** — see below |
| Visual change at runtime from the Tier-3 retarget | **none observed**, as predicted |

**The honest state of integration.** The token foundation is correct, test-pinned and
mutation-verified — and it changed nothing on screen. Confirmed at runtime: after
retargeting every token, the login screen renders identically (still a pill CTA, still a
purple glow, still the old violet), because `login_screen.dart` reads its own private
`AuthColors` palette rather than the theme.

This is not a failure of the change; it is the measured shape of the remaining work.
`DESIGN_INTAKE_REPORT.md` §10.1 established it in advance: **zero files read
`context.helix`**, 108 of 158 presentation files carry raw hex (1,418 occurrences),
`AppColors` has 1,028 call sites, and 20 mutually inconsistent private palettes ship
concurrently. Visual integration is necessarily **per-screen**, across the 45 implementing
files in the matrix.

## 6 · Owner decisions — open

| Id | Question | Blocks | Can continue without |
|---|---|---|---|
| OD-1 | Landscape: lock to portrait, or design and support it? | F-5 | everything portrait |
| OD-2 | GAP-07 — AI error states the backend cannot reach | those states | all reachable states |
| OD-3 | GAP-08 — Score frame semantics (`ScoreService` vs `ScoreEngine`) | one screen | all others |
| OD-4 | GAP-09 — navigation entry for the event ticket | F-10 | all others |
| OD-6 | Display weight: the design says w300; Schibsted Grotesk ships no w300 via `google_fonts` 8.1.0; the board renders w400 | display/metric type only | colour, shape, spacing, motion, geometry |
| OD-7 | Font delivery — bundle the family or accept runtime fetch (F-11) | offline fidelity | online behaviour |
| D-2 | Adoption of design tokens by screens (now partially answered by IMPLEMENT-THIS) | per-screen migration | foundation done |
| D-3 | Accessibility copy for icon-only controls | F-6, F-8 | sizes, which are mechanical |

## 6b · Phase A/B findings — navigation, authorization and state coverage

Produced by two delegated read-only audits. **Every item marked VERIFIED below was
re-checked by me directly against source**, because each is consequential enough that a
delegated claim alone is not evidence.

### F-12 · DISPOSITION — route entry is weak; the data layer is not **TESTED EMPIRICALLY**

> **This supersedes the severity recorded below. The original finding is retained
> unaltered underneath, because it is accurate about the router — it was simply incomplete
> about consequence.**

The open question was whether route-entry weakness produces data exposure. It was settled
by **testing the live QA database as an authenticated client**, not by reading code.

Method: signed in as the committed QA fixture `p1-victim@qa.12circle.test` (role `client`,
`uid 1c89c873-…`) against QA `eyqtldjqpgpljlqvpowh` using the anon key, then issued the
reads and writes the privileged screens issue. Probe:
`scratchpad/f12_probe.mjs`. Prod ref is never contacted.

| Probe | Result | Verdict |
|---|---|---|
| `GET user_profiles?select=id,role` | **1 row, `id == own uid`**, `content-range 0-0/1` | own row only |
| `GET coach_client_relationships` | **403 `42501`** — "Grant the required privileges…" | denied at GRANT level |
| `GET payments` / `subscriptions` / `event_registrations` / `notifications` / `workout_sessions` | 200, **0 rows** | filtered |
| `GET events` | 200, 3 rows | shared content, not privileged |
| `PATCH user_profiles(own).role = 'admin'` | **403 `42501` — "user_profiles.role is not self-assignable — use admin_set_user_role"**; role re-read as `client` | escalation blocked by a named guard |
| `PATCH user_profiles(coach).first_name` | 200 **`[]` — 0 rows affected** | RLS filtered the target row out |

**Neither mutation changed anything**, confirmed by re-reading after each.

Separating the concerns exactly as the brief requires:

| Layer | Finding |
|---|---|
| Route entry | **WEAK — confirmed.** Any authenticated user can enter `/admin-dashboard`, `/vendor-portal`, `/compliance`, `/coach-dashboard` |
| UI self-guarding | **PARTIAL.** 9 screens swap the body for a placeholder; the rest do not |
| Backend authorization | **SOUND in every path tested** — grants, RLS row filtering, and an explicit anti-escalation guard |
| Information disclosure | **NOT DEMONSTRATED** |
| Mutation capability | **NOT DEMONSTRATED** |

**Revised classification: P3 — SECURITY/UX/ARCHITECTURE, not data exposure.** A client can
open an admin screen and see it render empty or placeholdered. That is a trust, polish and
defence-in-depth problem, not a breach. Overstating it would be as wrong as missing it.

**Scope limit, stated plainly:** this tested the tables named above, not an exhaustive set.
It establishes that the data layer *is* enforcing, not that every table is covered. A
table-by-table sweep is the remaining work, and the repo already has the harness for it
(`supabase/tests/security/`, which needs `QA_SERVICE` — not available locally, supplied in
CI).

**Correction of a stale record of mine:** a memory note claimed role escalation had been
regressed by migrations 115/119. QA now blocks it with a purpose-built message. That note
was wrong for QA as it stands today; production was not tested and is not claimed either
way.

### F-12 (original finding, retained) — the router enforces no role restriction at all **VERIFIED**

`app_router.dart:180-224` contains exactly one denial:

```dart
if (!isAuthenticated && !isAuthRoute) return '/login';
```

That is the whole access-control surface. The `role` lookup at `:206-218` runs **only**
inside the `isAuthenticated && isAuthRoute` branch and returns a *destination*
(`/coach-dashboard`, `/admin-dashboard`, `/vendor-portal`), never a refusal. It is a
landing-page selector, not a guard.

**Consequence:** any authenticated user — any client — can navigate to
`/admin-dashboard`, `/admin-exercise-review`, `/vendor-portal`, `/compliance`,
`/coach-dashboard`, `/coach-payments`, `/coach-business`, `/coach-client-workouts` and the
rest. The URL resolves, the shell mounts, the screen builds.

Nine screens self-guard **inside the widget** and render a text placeholder
(`observability_screen.dart:43` "Admins only.", `coach_copilot_screen.dart:112`,
`content_review_queue_screen.dart:76`, and six more). The route is still entered; only the
body is swapped. The remaining role-oriented routes — including `/admin-dashboard`,
`/vendor-portal`, `/coach-dashboard` and `/compliance` — carry **no role check anywhere**.

**Classification: OWNER DECISION.** Adding router-level role enforcement changes
authorization behaviour, which brief §7 reserves. **NOT ESTABLISHED:** whether Supabase
RLS backstops the data behind these screens — that is a server-side question this audit did
not open, and it determines whether this is an information-disclosure defect or "only" a
UX and trust defect. It should be answered before the decision is taken.

### F-13 · PaywallGate fails open on provider error **VERIFIED — deliberate**

`paywall_gate.dart:45` — `error: (_, __) => child, // fail open rather than lock a paying
user out`. A plan-provider error grants access to all 13 gated routes.

**Classification: RECORDED RISK, not a defect.** The comment shows this is a considered
trade-off with a stated rationale. Recorded so the owner knows the failure mode exists; not
changed, because reversing a documented product decision is not QA's call.

### F-14 · The shipped bottom nav is not the mandated five tabs **VERIFIED**

`IMPLEMENT-THIS.md`: *"Five client tabs, fixed: Home · Workouts · Nutrition · Check-In ·
Connect. No sixth."* Shipped (`app_shell.dart:147-151`):

| # | Shipped | Mandated |
|---|---|---|
| 1 | Home → `/home` | Home ✅ |
| 2 | Train/AI Train → `/train` **or `/ai-coach`** depending on coaching mode | Workouts — present but **not a stable destination** |
| 3 | unlabelled FAB → `/directory` | — **not mandated** |
| 4 | Activity → `/activity` | — **not mandated** |
| 5 | Check-In → `/daily-checkin` | Check-In ✅ |
| — | **absent** | **Nutrition** ❌ |
| — | **absent** | **Connect** ❌ |

Only four labelled destinations are exposed, not five. `/messages` (Connect) is demoted to a
top-bar icon (`app_top_nav.dart:116`); Nutrition has no nav entry at all.

**Classification: OWNER DECISION — and it is not a one-line change.** `/directory` is the
**sole** entry point to `/events`, and the primary entry to `/classes`, `/challenges`,
`/community` and `/progress`. Replacing the FAB with a Connect tab would strand them.
A third, never-rendered nav definition also exists (`app_scaffold.dart:252-279`,
`AppBottomNav`, never instantiated) with a *fourth* different tab set.

### F-15 · Error→empty collapse — the dominant defect pattern

Eight screens present a **server failure as "you have no data"**:
`progress_screen.dart:139`, `checkin_screen.dart:146`, `coach_dashboard_screen.dart:68/98/114/133`,
`profile_screen.dart:830`, `classes_screen.dart:39`, `challenges_screen.dart:36-39`,
`home_screen.dart:80`, `train_hub_screen.dart:224-238`.

Worked examples:
- A coach whose client fetch fails is told **"No clients found — Clients will appear here
  when they sign up."**
- `train_hub_screen.dart:224` — `error: (_, __) => '0'`. A failed load **displays "0
  workouts" as a real answer.**
- `progress_screen.dart:139` swallows the entire screen load and renders every empty state
  at once: "Log your first weight…", "No entries yet", "No check-ins yet".

`booking_screen.dart:609-643` is the **only** place in the codebase that names this as a bug
and guards against it — its copy reads *"This is a connection problem, not an empty
schedule."* That screen is the in-repo reference implementation for the correct pattern.

**Classification: FAIL (P2).** Fixing each is mechanical but touches eight screens' product
copy; the pattern to copy already exists in-repo.

### F-16 · Swallowed errors and stringified exceptions, quantified

- **52 of 94 `catch` blocks (55%)** under `features/*/presentation/` (excluding auth)
  neither surface anything nor call `reportError`.
- `reportError` is called in **5 places total** in the whole presentation layer — the four
  auth screens plus `chat_screen.dart:207`.
- **48 sites across 30 files** put a raw error object into user-visible text. Seven are
  bare `Text('Error: $e')` with no human copy at all.

Worst swallows, each hiding a *user-initiated* action: `settings_screen.dart:62` (unit
preference silently not saved — the toggle appears to work), `progress_screen.dart:1195`
and `:1339` (measurement and weight saves), `home_screen.dart:1257` (coach review lost),
`pods_screen.dart:67` (pod join), `intake_flow_screen.dart:219/227` (**the entire
onboarding profile save, double-nested silent catch**).

`settings_screen.dart:546` deserves separate mention: a swallowed read leaves `coaches`
empty, which **skips the destructive-action confirmation at `:549`** — coaching mode is
switched away with no warning that coaches will be cancelled.

### F-17 · Zero offline handling, zero back protection **VERIFIED**

- No connectivity package is in `pubspec.yaml`; **0 of 18** audited screens detect
  connectivity. Several show a `wifi_off` icon and "check your connection" copy that is
  never driven by an actual signal.
- `grep PopScope|WillPopScope|onPopInvoked` across `lib/` → **0 matches**. Nothing guards
  back-out of an **in-progress workout with running timers** or the **27-page intake
  flow**. The only back containment in the app is the router's recovery redirect
  (`app_router.dart:189-191`).

### F-18 · Screens that cannot be reached

| Route | Finding |
|---|---|
| `/log-meal` | **Zero inbound navigation.** Deep-link only — and it is **FIT-019 "Log a meal", a LOCKED design anchor** |
| `/checkin-detail` | Only inbound is `checkin_card.dart:27`, in a widget **no file imports** |
| `/food-search` | Zero inbound; registered and paywalled |
| `/checkin-form` | Only inbound is the same dead widget |
| `/events` | Exactly **one** entry point — the `/directory` FAB (see F-14) |

Separately, **9 screens exist entirely outside the router**, reachable only by
`MaterialPageRoute`: `CreateClassScreen`, `EventTicketScreen`, `EventAgendaScreen`,
`ClientDetailScreen`, `CoachVideoResponseScreen`, `ChoosePackageScreen`,
`CoachAvailabilityScreen`, `EventAttendeesScreen`, `ProgramBuilderScreen`. They have no URL,
no deep link, and do not update the shell's active-tab state.
`vendor_portal_screen.dart:170` passes `canManage: true` as a constructor argument in a file
with no role check — a privilege granted by which button was tapped.

### F-19 · Dead code

`home_org.dart`, `dashboard_screen.dart`, `dash_org.dart`, `checkin_card.dart` and
`AppBottomNav` (`app_scaffold.dart:252`) have **zero importers or zero instantiations**.
Navigation links inside them are unreachable. **Classification: PASS WITH OBSERVATION** —
harmless at runtime, but it inflates every "screen exists" count, which is exactly the trap
brief §9 warns about.

### F-20 · FIT-016 "Workout detail" is a hardcoded mockup **VERIFIED**

`workout_detail_screen.dart` contains **0** occurrences of `ref.`, `Supabase`, `await` or
`Future` — no data access of any kind, with a hardcoded hero asset at `:49`. It is a static
mockup, and **FIT-016 is a LOCKED design anchor**. `/workout-detail` is reachable
(`workout_list_screen.dart:319`) and shows the same content regardless of which workout was
tapped.

**Classification: FAIL (P1 for integration).** No amount of restyling makes this screen
correct; it needs wiring to a workout. Recorded against FIT-016 in the matrix.

#### F-20 · Full workflow trace — the contract EXISTS, the plumbing does not

Traced end to end, as required, before changing anything:

```
tap a workout        workout_list_screen.dart:312-320
  │  final match = sampleWorkouts.where((sw) => sw.title == w.title).firstOrNull;
  │  if (match != null) _startWorkout(match);        → sets identity, goes /active-workout
  └─ else               context.go('/workout-detail');  → NO identity, static mockup
route                app_router.dart:264
  │  GoRoute(path: '/workout-detail', builder: (_, __) => const WorkoutDetailScreen())
  │  no path parameter, no query, no `extra`
implementation       workout_detail_screen.dart:18-19
  │  const WorkoutDetailScreen({super.key})   ← accepts no workout identity at all
data source          NONE — 0 occurrences of ref. / Supabase / await / Future
loading / empty / error   none of the three exist
```

**Two defects, not one.**

1. `/workout-detail` is the **failure branch of a title-string match**. `w` is a local
   `_WorkoutItem` view model (`:529`) and `sampleWorkouts` are `Workout` objects, so the
   code recovers the real object by comparing `title` strings. When that comparison misses,
   the user is sent to a hardcoded screen describing **a different workout than the one
   they tapped**. Matching domain objects by display title is fragile by construction.
2. The screen renders fixed content regardless.

**The backend contract exists and nothing needs inventing:**

| Piece | Where |
|---|---|
| Identity carrier | `selectedWorkoutProvider` — `StateProvider<Workout?>`, `workout_provider.dart:116` |
| Real data | `assignedWorkoutsProvider` → `FutureProvider<List<Workout>>` via `CoachProgramService().getMyAssignedProgram()`, `workout_provider.dart:152-158` |
| Model | `Workout`, `workout_model.dart:232` |
| Established convention | `active_workout_screen.dart:102` already does exactly this: `ref.watch(selectedWorkoutProvider)`. `chat_screen.dart` uses the same pattern with `selectedConversationProvider` |

So integration is **objectively supported**: set the identity before navigating, read
`selectedWorkoutProvider` in the screen, render the real workout, and add the three states.
No backend field is missing and no data would be fabricated.

**Status: MAPPED, NOT YET IMPLEMENTED.** It is a screen rewrite against a locked design
anchor and belongs in its own coherent commit — recorded here so the next tranche starts
from evidence rather than rediscovery.

### F-10 / GAP-09 · CORRECTION OF TERMINOLOGY

The design package calls `event_ticket_screen` **"unreachable"**. That word is wrong and
this ledger will not repeat it.

Measured: it has **no `GoRoute`** (`grep EventTicket lib/core/router/app_router.dart` →
nothing), and it **is** reached at `events_screen.dart:81` via
`Navigator.of(context).push(MaterialPageRoute(...))`.

Correct terminology, used from here on: **not router-addressable / not deep-linkable.**
The user-facing consequence is that the destination has no URL, cannot be deep-linked,
does not participate in the router's shell or redirect logic, and does not update the
bottom nav's active tab — **not** that it cannot be opened. Eight further screens share
this characteristic (F-18).

## 6c · F-15 inventory — every error→empty collapse

Required fields per the brief. "Distinguishable" = can the user tell a failure from a
genuinely empty result. Design state = does the authoritative package specify an error
state for that screen.

| Screen | Route | Failure behaviour | Empty behaviour | Distinguishable | Data source | Existing error state | Design state | Decision needed |
|---|---|---|---|---|---|---|---|---|
| `progress_screen.dart:139` | `/progress` | `catch (_) { _loading = false }` — whole-screen load | "Log your first weight…", "No entries yet", "No check-ins yet" — **all at once** | **NO** | direct Supabase, 6 fetches | none | FIT-052…057 declare `empty`; no error state declared | copy for an error state |
| `checkin_screen.dart:146` | `/checkins` | `catch (_)` on `_loadCalls()` | "No upcoming sessions. Book a call with your coach." | **NO** | `coaching_calls` | none | FIT-023 | copy |
| `coach_dashboard_screen.dart:68` | `/coach-dashboard` | provider `catch` → `[]` | "No clients found — Clients will appear here when they sign up" | **NO** | clients query | none | FIT-032 | copy |
| `coach_dashboard_screen.dart:98/114/133` | `/coach-dashboard` | `catch` → `[]` ×3 | empty tabs | **NO** | check-ins, workouts, aggregate | none | FIT-032/033 | copy |
| `profile_screen.dart:830` | `/profile` | `valueOrNull` → null | "No coach assigned yet" | **NO** | coach provider | none | FIT-029 | copy |
| `classes_screen.dart:39` | `/classes` | `valueOrNull ?? []` | Schedule tab renders **nothing at all** (`itemCount: 0`) | **NO** | class providers | none | FIT-027/080/084 | copy + an empty state for Schedule |
| `challenges_screen.dart:36-39` | `/challenges` | `AsyncError` never consumed | "🏁 No challenges here" | **NO** | challenge StateNotifier | none | FIT-075/078/079 | copy |
| `home_screen.dart:80` | `/home` | `catch` → all-zero bars | zero bars | **NO** | weekly activity | none | FIT-001 (locked) | copy |
| `train_hub_screen.dart:224-246` | `/train` | **`error: (_, __) => '0'`** — shows **"0 workouts" as a real answer** | `'—'` placeholders | **NO** | 4 stat providers | none | FIT-014/015 (locked) | copy |

**Reference implementation already in-repo:** `booking_screen.dart:612-643` (`_LoadFailedState`)
— *"Couldn't load your bookings / We could not reach your coach and availability data just
now. **This is a connection problem, not an empty schedule.**"* with a Try-again action, and
a comment at `:609-611` naming the collapse as the bug. `chat_screen.dart` now follows it.

**Why these are not fixed in this pass:** the pattern is unambiguous but each needs
**user-facing error copy**, and the authoritative package declares `empty`/`loading` states
for these frames without declaring error copy for them. Writing nine new error strings is
inventing product copy, which the brief forbids. **The mechanism is free; the words are
not.** Two routes out: (a) the owner supplies copy, or (b) QA is authorised to reuse the
booking screen's existing, already-shipped phrasing as the house pattern. Recorded as
**OD-8**.

## 6d · OWNER DECISION REGISTER

| ID | Question | Evidence | Options | QA can continue without it | Blocked by it |
|---|---|---|---|---|---|
| **F-12** | Should role authorization move into the router? | Route entry weak (verified); backend sound in every path tested (6 probes, 2 mutations, no change) | (a) router-level role guard; (b) keep widget guards, extend to the 4 unguarded routes; (c) accept, document as defence-in-depth gap | **everything** — no data exposure demonstrated | nothing |
| **F-14** | Adopt the mandated 5 tabs (Home/Workouts/Nutrition/Check-In/Connect)? | Shipped nav has 4 labelled destinations; Nutrition and Connect absent; `/directory` FAB is the **sole** entry to `/events` | (a) adopt 5 tabs and re-home `/directory`'s destinations; (b) keep shipped nav, record design deviation; (c) hybrid | all non-nav work | `/events` reachability, FIT-003/005 integration |
| **F-13** | Keep PaywallGate failing open on provider error? | `paywall_gate.dart:45`, deliberate + commented | (a) keep; (b) fail closed; (c) fail closed with retry | everything | nothing |
| **OD-1** | Landscape: lock portrait, or support it? | 39 px overflow on `splash_screen.dart:109`; design GAP-06 "Tablet and landscape are not designed. Phone widths only." | (a) lock portrait (1 line, matches comparators); (b) design landscape | all portrait work | F-5 |
| **OD-2** | GAP-07 AI error states the backend cannot reach | manifest `implementationGaps` | owner-defined | all reachable states | those states |
| **OD-3** | GAP-08 Score semantics — frame depicts `ScoreService`, route renders `ScoreEngine` | package calls it "locked, unresolved" | owner-defined | all other screens | FIT-060 |
| **OD-4** | Navigation entry for the event ticket (not router-addressable) | `events_screen.dart:81` push; no `GoRoute` | (a) register a route; (b) keep imperative, accept no deep link | all other screens | FIT-086 |
| **OD-6** | Display weight — design says w300; Schibsted Grotesk ships no w300 via `google_fonts` 8.1.0; board renders w400 | verified in pub-cache source | (a) w400/w500 per board (**currently implemented**); (b) bundle a Light weight; (c) substitute a family with w300 | colour, shape, spacing, motion, geometry | display/metric type only |
| **OD-7** | Bundle fonts, or keep runtime fetch? | no `fonts:` in pubspec, no font assets, `allowRuntimeFetching` unset → true | (a) bundle; (b) accept offline degradation to Roboto | online behaviour | offline fidelity |
| **OD-8** | Error copy for the 9 F-15 screens | package declares `empty`/`loading`, not error copy | (a) owner supplies copy; (b) authorise reuse of `booking_screen`'s shipped phrasing as the house pattern | everything else | F-15 fixes |

## 7 · Environment

| Item | Status |
|---|---|
| Android emulator `emulator-5554`, API 35, arm64-v8a | **PASS** — running, no further SDK installed |
| iOS / Xcode | **out of scope** by instruction — not a blocker |
| CI has **no** Android build job | **OWNER DECISION** — pipeline contract change; F-1 could recur undetected |
| Disk headroom on the build volume | **ENVIRONMENT LIMITATION** — ~1.6 GB free after a build; two earlier runs were killed by a disk watchdog (the watchdog killed them; the builds did not fail) |
