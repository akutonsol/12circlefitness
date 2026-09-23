# QA EVIDENCE LEDGER — 12Circle Fitness

The single classified index of findings. **This is an index, not a second report**: detail
lives in the documents referenced, and nothing is restated here that is recorded there.

- `docs/MOBILE_QA_SWEEP_2026-09-22.md` — technical + Android runtime QA (§1–§23)
- `docs/DESIGN_INTAKE_REPORT.md` — design package intake and repo conflicts
- `docs/DESIGN_ROUTE_IMPLEMENTATION_MATRIX.md` — FIT→route→implementation mapping

Classifications are used strictly, per brief §19: **PASS · FAIL · BLOCKED ·
NOT ESTABLISHED · OWNER DECISION · ENVIRONMENT LIMITATION**. A category is never converted
to make the ledger read better.

Repository: `chore/qa-environments-secure-ai-backend`. Last updated 2026-09-23.

---

## 0 · RECONCILIATION AGAINST `QA_CLOSURE_STANDARD.md` — several of my own claims were overstated

`docs/QA_CLOSURE_STANDARD.md` outranks this ledger and outranks any specialist skill
(governance precedence: owner → product spec → design package → repo contracts → **closure
standard** → skills → generic agents). Reading it against the work recorded below forces
three corrections. They are made here rather than quietly edited into the tables.

### 0.1 The evidence ladder has five states, and I used one word for several of them

§2 defines `FIXED IN CODE` · `VERIFIED IN CI` · `FIXED ON QA` · `VERIFIED LIVE` ·
`VERIFIED END-TO-END`, and §4 states plainly that *"the code changed"* is **one** of those
states, not a closure. §2.1 then fixes, per finding class, which states are **required**.

**No finding in this programme is `VERIFIED_CLOSED`, because nothing is `VERIFIED IN CI`.**

There are **17 commits on this branch and none are pushed**. §4 lists, as an explicit
non-closure: *"A passing suite that has never run in CI — a guard nobody runs protects
nobody."* Every guard I added (A-G1…A-G5, D-T1…D-T5, the F-20 widget tests) is in exactly
that position. They pass on this machine. That is not the claim the standard requires.

| Finding | Class (§2.1) | States required | States I actually have | Verdict |
|---|---|---|---|---|
| F-1 Android build | Release / environment | FIXED IN CODE · **VERIFIED IN CI** | FIXED IN CODE | **NOT CLOSED** |
| F-2 auth exception text | Error contract / false success | FIXED IN CODE · VERIFIED IN CI · VERIFIED END-TO-END | FIXED IN CODE · END-TO-END (device) | **NOT CLOSED** — no CI |
| F-2b chat fabrication | Error contract / false success | FIXED IN CODE · VERIFIED IN CI · VERIFIED END-TO-END | FIXED IN CODE only | **NOT CLOSED** — I earlier wrote "VERIFIED COMPLETE"; that was wrong. I never reached an empty conversation at runtime |
| F-3 app name | Hygiene / P3 | FIXED IN CODE · VERIFIED IN CI where cheap | FIXED IN CODE · END-TO-END | **NOT CLOSED** — no CI |
| F-6b password toggle | Product integrity / UI reachability | FIXED IN CODE · VERIFIED IN CI · VERIFIED END-TO-END | FIXED IN CODE · END-TO-END | **NOT CLOSED** — no CI |
| F-20 workout identity | Product integrity / UI reachability | FIXED IN CODE · VERIFIED IN CI · VERIFIED END-TO-END | FIXED IN CODE · END-TO-END | **NOT CLOSED** — no CI |
| F-12 / F-12a | Security / authorization | FIXED IN CODE · FIXED ON QA · VERIFIED LIVE · VERIFIED IN CI | VERIFIED LIVE (disposition only; no fix exists) | **OPEN by design** — F-12a has no fix |

**Correction of record:** my previous checkpoint reported F-20 as "IMPLEMENTED AND
RUNTIME-VERIFIED" and F-2b as "VERIFIED COMPLETE". Both were accurate about the *device*
and inaccurate as *closures*. `VERIFIED END-TO-END` is a real state and I earned it for
F-20; it is not the whole ladder its class demands.

**This is not a technicality.** The standard exists (§1) because *"findings were later found
open, and in three cases the closure itself introduced the regression."* I introduced two
regressions during this programme and caught both only on-device — the `MergeSemantics`
change that destroyed the password toggle, and the doubled semantics labels. A guard that
has never run in CI would not have caught either on someone else's machine.

**Blocking condition, escalated rather than worked around:** the owner instructed "Hold —
keep local" for pushes. That instruction is higher in the precedence order than this
standard and is respected. The consequence is recorded, not circumvented: **until these
commits run in CI, no finding in this programme can be marked `VERIFIED_CLOSED`.** See
OD-12.

### 0.2 "850 tests pass" is a weaker statement than it sounds

§4 records that **259 tests — 37% of the Flutter suite — define the logic inside the test
file and assert against the copy**: *"They are green whatever the app does."*

I have repeated "848 / 850 tests pass" as a headline several times without that caveat. It
remains true and remains worth running, but it is not evidence that the *application*
behaves. The guards I added are deliberately of the other kind — they read committed source
or drive the real widget — and each was mutation-tested, which is the property that makes a
guard mean something. That distinction should have been stated the first time.

### 0.3 The standard already names two of my findings, independently

§4's non-closure table records, before I looked at either:

- *"`EC-G1` asserts `workout_provider.dart` contains no `catch`. The defect moved to the
  screens and to the service. The guard passes. **The defect is live.**"*
- *"`EC-G5` counts `catch` blocks. Riverpod swallows via `error: (_,__) =>` and
  `.valueOrNull`, which contain no `catch`. **~150 sites are invisible to it.**"*

That is F-15 and F-16, reached from the opposite direction. It also explains why my A-G5
guard is written to match `error: (_, __) =>` shapes rather than `catch` blocks: the
existing ratchet cannot see the defect's shape, and a second guard with the same blind spot
would have been theatre.

---

---

## 0b · F-21 — **P1 SECURITY: any authenticated user can assign a workout programme to any other user**

**ID** F-21 · **Severity** P1 · **Status** OPEN — **authorization change required, escalated as OD-14**
**Source** found incidentally while arranging a runtime fixture for FIT-014, then
investigated under `12-12circle-security-engineer`.
**Environment** QA `eyqtldjqpgpljlqvpowh`. **Production was not tested and nothing is
claimed about it.**

### Observed

Signed in as the committed fixture `p1-victim@qa.12circle.test` — **role `client`**:

| Step | Request | Result |
|---|---|---|
| 1 | `POST workout_programs {name, coach_id: <own uid>}` | **201 — row created** |
| 2 | `POST workout_program_assignments {program_id, client_id: <own uid>, coach_id: <own uid>, status: active}` | **201 — row created** |
| 3 | `POST workout_program_assignments {program_id, client_id: <p1-coach uid>, coach_id: <own uid>, status: active}` | **201 — CROSS-USER WRITE** |

### Expected

A member cannot author a training programme as a coach, and cannot place a programme into
another person's plan.

### Root cause

`supabase/migrations/001_full_ecosystem.sql:351,357`:

```sql
CREATE POLICY "coaches manage programs" ON workout_programs
  FOR ALL TO authenticated USING (coach_id = auth.uid());

CREATE POLICY "coaches manage assignments" ON workout_program_assignments
  FOR ALL TO authenticated USING (coach_id = auth.uid() OR client_id = auth.uid());
```

Both are named for coaches and **neither checks that the caller is one.** The predicate is
satisfied by anyone willing to write their own uid into `coach_id`. The repository already
has the helper this needs — `public.is_coach_profile(uuid)`
(`113_rls_coach_client_relationships.sql:58`) — and migration 113 applies exactly that
check to `coach_client_relationships`. It was never applied here.

`FOR ALL` with `USING` and no `WITH CHECK` also means the INSERT path is governed by a
predicate written for reads.

### Why this is more serious than F-12

F-12 found route-entry weakness with **no demonstrated cross-user mutation**. This one *is*
a demonstrated cross-user mutation, and its payload is a **training prescription**: loads,
sets and reps that the receiving member's `/train` will present as their coach's plan. Under
`QA_CLOSURE_STANDARD` §5.1 a workout prescription injected by an arbitrary party is a
safety input, and §5.1 closes safety findings live or not at all.

The victim's hub renders it through the very surface integrated in this cycle
(`_PlanSurface` → `_TodayHeroCard`), attributed with "assigned by …".

### Not fixed — and why that is the correct call

Tightening these policies is an **authorization policy change**, which the governing
instruction lists as a genuine stop condition. The fix is small and obvious — add
`is_coach_profile(coach_id)` and an explicit `WITH CHECK` — but QA does not change the
authorization model on its own initiative. **OD-14.**

### Fixture hygiene

Three rows were created by the probe and all three deleted. Verified by re-query:
`remaining SEC-PROBE rows: 0`. An earlier single-row probe was likewise deleted and
verified at 0.

### F-21b · Blast radius — measured statically, read-only, no further mutation

The exploit is a *policy shape*, so the surface was sized by auditing every `FOR ALL`
policy in `supabase/migrations/` rather than by creating more rows.

**22 policies share the shape and are CORRECT** — `"users manage own weight logs"` with
`user_id = auth.uid()` scopes a user to their own rows, which is the intent. Those are not
defects and are not listed.

**15 carry a privilege-asserting NAME with no role check.** The predicate is satisfied by
writing your own uid into the column the name claims authority over:

| Migration | Table | Predicate columns | Policy |
|---|---|---|---|
| `001:347` | `coach_invites` | coach_id | "coaches manage invites" |
| `001:351` | `workout_programs` | coach_id | "coaches manage programs" — **PROVEN** |
| `001:354` | `program_workouts` | coach_id | "coaches manage program workouts" |
| `001:357` | `workout_program_assignments` | **client_id, coach_id** | "coaches manage assignments" — **PROVEN** |
| `001:360` | `client_nutrition_plans` | **client_id, coach_id** | "coach client nutrition" |
| `001:361` | `client_habits` | **client_id, coach_id** | "coach client habits" |
| `001:386` | `challenges` | coach_id | "coaches manage challenges" |
| `001:392` | `classes` | coach_id | "coaches manage classes" |
| `002:47` | `coach_availability` | coach_id | "Coaches manage own availability" |
| `002:67` | `coaching_calls` | **client_id, coach_id** | "Coach and client can see calls" |
| `002:104` | `accountability_pods` | coach_id | "Coaches manage pods" |
| `002:146` | `coach_team_members` | coach_id | "Head coach manages team" |
| `002:159` | `coach_team_invites` | coach_id | "Coach manages own invites" |
| `005:48` | `custom_exercises` | coach_id | "coaches manage own exercises" |
| `017:46` | `action_items` | coach_id | "coach manages assigned action items" |

**The four in bold are the cross-user injection candidates.** They carry a `client_id`
alongside `coach_id`, so the `coach_id = auth.uid()` arm lets a caller name themselves
coach while targeting *someone else* as the client — which is exactly the step-3 write
proven for `workout_program_assignments`. The other three are **UNTESTED**: predicted from
the shape, not demonstrated, and recorded that way.

By payload: `client_nutrition_plans` and `client_habits` would inject a nutrition plan or
habit into another member's programme; `coaching_calls` would place a call in their
schedule. With `workout_program_assignments` these are the same class of safety input as
F-21.

**Nothing further was written.** Confirming the remaining three needs one INSERT each, which
is a security decision to authorise, not one to take unilaterally — it is folded into
OD-14.

### Next tests, once authorised

`program_workouts` (`001:354` scopes by program ownership — inherits the same weakness),
`workout_program_assignments` UPDATE/DELETE by a non-party, and whether the victim's client
actually renders an injected programme end-to-end.

---

## 0c · F-22 — icon-only controls ship with no accessible name (**56 → 46 raw, ~40 real**)

**ID** F-22 · **Severity** P2 accessibility · **Status** RATCHETED, OD-8 for the copy

A tappable whose entire content is an `Icon` reports to the accessibility tree with **no
name**; a screen reader announces nothing. Measured on-device twice — the password toggle
(19.8 × 20.2 dp) and the three top-bar controls (38 × 38). Both are now named from the
design's own wording.

A repository-wide scan of the shape that actually reports unlabelled — a tappable whose
subtree holds an `Icon` and no `Text`, `tooltip` or `Semantics` — finds **56 more across 36
files**. Heaviest: `exercise_content_center_screen` (4), `active_workout_screen` (4),
`progress_screen` (3), `create_exercise_screen` (3), `meals_dashboard_screen` (3).

**Not mass-fixed, deliberately.** Naming a control is product copy. The authoritative
package supplies vocabulary for the controls it draws — "Back", "More", "Directory",
"Messages", "Notifications", "History", "Exercise library", "Show password" — and all of
those have been applied. It does not name every icon in screens it does not draw, and
inventing 56 strings is the fabrication the brief forbids. Folded into **OD-8**.

**Guard A-G8** holds the population at 56 and fails on the 57th — mutation-tested
("Found 57 across 36 files (baseline 56)"). A second assertion pins the controls already
fixed so they cannot silently regress.

It deliberately does **not** repeat EC-G5's mistake, which `QA_CLOSURE_STANDARD` §4 records
as counting `catch` blocks while the defect it targets contains none: A-G8 matches the
shape that reports unlabelled, not a keyword that happens to sit nearby.

### What was named, and what was deliberately left alone

The package declares short control labels, and three cover a large share of this
population: **"Back" (138 declarations), "Close" (4), "Refresh" (8)**. A back arrow named
"Back" and a close cross named "Close" use the design's own words, so they are not product
copy. Nine controls were named on that basis, plus the intake flow's three under F-9:

| Screen | Control | Name |
|---|---|---|
| `/progress` ×2 | measurement-sheet crosses | Close |
| `/directory` | sheet cross | Close |
| `/nutrition` | sheet cross | Close |
| `/daily-checkin` | header back arrow | Back |
| `/chat` | header back arrow | Back |
| `/messages` | header back arrow, refresh | Back, Refresh |
| `/intake` ×3 | `_AppBar`, `_IntakeStepBar`, profile header | Back |

Each also gained a 44 dp target around its unchanged 36 dp chip.

**Three crosses were left unnamed on purpose**, although naming them "Close" would have
moved the number faster:

* `coach_checkin_review_screen.dart` — the cross **removes a recommendation**. "Close" is
  wrong, and the package declares only "Remove <thing>", never a bare "Remove".
* `exercise_database_screen.dart` — the cross **clears a search field**. Same reason.
* `coach_notes_sheet.dart` — the cross is wired to `onDelete`. The package declares no
  delete label at all.

A wrong name is not a smaller version of a missing one. These stay under OD-8.

**A false positive found by doing this.** `workout_detail_screen.dart`'s back control was
*already* named by F-20 — the scan reads forward from each tappable and could not see the
`Semantics` above it, so the site was counted. The first attempt double-wrapped it and the
F-20 test caught it (`Found 2 widgets with a semantics label named "Back"`). The wrapper
was removed and the site annotated. The scan is still not widened backwards, for the
reason recorded in the guard.

### The scan over-counts, and by how much

A-G8 reads **forward** from each tappable, so a `Semantics` wrapper placed *outside* the
`GestureDetector` is invisible to it. Six sites are verified named and still counted. The
clearest is `auth_design.dart`'s password toggle: **this guard already asserts that control
is named** — it was measured on-device at 19.8 × 20.2 dp and fixed as F-6b — and the scan
counts it anyway.

| Site | Name it actually carries |
|---|---|
| `auth_design.dart` | `Show password` / `Hide password` |
| `workout_detail_screen.dart` | `Back` |
| `nutrition_screen.dart` | `Close` |
| `directory_screen.dart` | `Close` |
| `meals_dashboard_screen.dart` | `Log a meal` |
| `ai_nutrition_screen.dart` | `Scan a meal` |

So the raw figure is **46** and the real one is about **40**.

**The window is still not widened backwards.** A backward window would also swallow an
unrelated `Semantics` above a genuinely unnamed control, and a ratchet that under-counts
hides regressions while one that over-counts only overstates the work left. What was not
acceptable was leaving the discrepancy as a sentence in prose: the six are now **listed and
asserted** in the guard, so if one loses its name the test fails and it becomes a real
finding again. Mutation-tested both ways — removing a listed name fails, and a new unnamed
control still fails the baseline at 47.

**Two more named from the package's vocabulary**, bringing 47 → 46: FIT-003 declares
`Log a meal` and `Scan a meal`, and both controls do exactly what those labels say — the
`+` opens the add-meal sheet, the camera picks a photo and has it analysed.

## 0d · F-9 — **RESOLVED AND MEASURED ON DEVICE**, including the related finding

**Cause.** There is no `MergeSemantics`, `Semantics` or `BlockSemantics` anywhere in
`intake_flow_screen.dart` — verified by grep. The merge was Flutter's default: with only
one actionable node on the page (a bare `GestureDetector` around a back icon), the
surrounding `Text` had no boundary of its own and was absorbed into it, which also
expanded that node's rect to the whole screen. Page 2 yielded 11 nodes because its form
fields create boundaries naturally.

**What was wrong, measured.** The earlier `uiautomator` dump recorded page 2 still
carrying a whole-screen control: `411.4 × 914.3 dp, clickable=true, 'Your Profile\nTell
us a little about yourself.'`. A screen reader offered the entire page as one button named
after the heading.

**The fix.** The intake flow's **three** back controls — `_AppBar` (40 dp),
`_IntakeStepBar` (36 dp) and the profile header (36 dp) — were all bare
`GestureDetector`s with no name and under the 44 dp floor. They are now one
`IntakeBackButton`: named "Back" (FIT-027's own word), `container: true` so it is its own
node and cannot swallow its neighbours, 44 dp target, visible chip unchanged. The two
header lines were given their own boundaries, the title as a `header`.

**Measured on `emulator-5554`, dpr 2.625, 411.4 × 914.3 dp** — by reading the real
semantics tree through the embedder rather than `uiautomator`, which returns an empty tree
unless an accessibility service is enabled:

| | Before | After |
|---|---|---|
| nodes on page 2 | the header and the control merged into one whole-screen node | **18 discrete nodes** |
| tappable nodes covering >50% of the screen | 1 | **0** |
| back control | absorbed, unnamed | `44.0 × 44.0 dp, tap=true, label="Back"` |
| "Your Profile" | inside the control | own node, `315.4 × 29.0 dp`, not tappable |
| "Tell us a little about yourself." | inside the control | own node, `186.0 × 20.0 dp`, not tappable |
| "Continue" | — | `button=true enabled=false tap=false` while the form is invalid, `enabled=true tap=true` once filled |

`integration_test/f9_intake_semantics_device_test.dart`. It writes nothing: the page takes
plain values and callbacks, so it mounts with no session and touches no backend — which is
also how it sidesteps the blocker recorded before. Reaching page 2 as a signed-in user
needs a fixture with no intake data, and manufacturing one means writing intake rows while
F-21 is open.

### A defect this probe found in my own fix, and the rule it produced

The first version of `IntakeBackButton` used `excludeSemantics: true` to keep the icon out
of the announcement. **That drops the child's ACTIONS along with its labels.** The device
read `44x44 tap=false label="Back"` — a node announced as a button that a screen reader
cannot press. Worse than the unnamed control it replaced, and every host-VM test was green,
because they asserted the name and the size and not the action.

`_RestAction` (FIT-017's "Add 30 seconds" / "Skip rest, start set") had the identical
defect, introduced earlier in this same cycle and not noticed. Both now pass `onTap` to the
`Semantics` as well, and **all three device probes assert the tap action, not just the
name**. Confirmed by mutation: removing the `Semantics` `onTap` fails both files.

The rule: *`excludeSemantics: true` requires re-declaring the action.* Only the device
showed it.

### Still open on this screen

`_GradientButton` now declares its role and `enabled` state (the child `Text` supplies the
name, so no label is set — doubling an announcement is a mistake this repository has
already made once). The rest of the intake flow's controls have not been audited; A-G8
counts what remains.

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
| F-9 | Intake welcome page collapses to **one merged accessibility node**; "Get Started" not separately focusable; the same whole-screen clickable node also present on page 2 | `uiautomator` dump ×2; re-measured through the embedder on `emulator-5554` | **PASS — MEASURED ON DEVICE.** 18 discrete nodes, 0 whole-screen controls, back control `44.0 × 44.0 dp, tap=true, label="Back"`. See §0d, including a defect the probe found in the fix itself |
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
| Unit + widget suite | **1060 tests pass, 9 skipped** | **PASS** |
| Device probes | 9 integration test files on `emulator-5554`; only one signs in, and it issues `SELECT`s only | **PASS** |
| Design token conformance | 14 assertions, mutation-tested | **PASS** |

## 3b · FIT-028 · Connect — no coach — **VERIFIED LIVE**

The design calls this state *"/messages · the state that sells the plan honestly"*. It
was absent: a member with no coach saw "No conversations yet", which is true and useless
— nothing on the screen tells them a coach is the thing they are missing, or how to get
one.

**Why this anchor and not a larger one.** F-21 (cross-user write on
`workout_programs`/`workout_program_assignments`) is OPEN and the standing instruction
reserves the policy change as an owner decision. FIT-028 depends on no coach-assigned
data — only on whether an active relationship exists — so it is integrable without
touching the vulnerable path. FIT-005, the anchor above it, is a full relationship layer
(coach + community + pods + classes) whose declared content is sample messages; building
it means inventing them.

**Nothing was invented.** Both strings already ship in this repository:

| String | Already at |
|---|---|
| `Find a coach` | `manage_subscription_screen.dart:241` |
| `Browse coaches, compare plans and get matched.` | `directory_screen.dart:59` |

**The design decision worth recording.** The pitch renders only on *proof of two facts*:
that the viewer is a member rather than a coach, and that their active-coach list really
is empty. If either read is loading or has failed, the screen falls back to the neutral
sentence. Collapsing a failed lookup into "you have no coach" would be the F-15
error→empty defect, and here it would also sell a plan to someone who has already bought
one. A coach with no client messages is likewise not a sales prospect.

| Layer | Evidence | Status |
|---|---|---|
| Branch correctness | `test/widget/messaging_no_coach_test.dart` — 8 tests against the real widget tree, no simulated logic | **PASS** |
| Guard strength | 3 mutations of the source, each killed: collapse `orElse`→pitch (2 fail), drop the role gate (2 fail), shrink the CTA to 30 px (1 fail) | **PASS** |
| Suite | 899 pass / 9 skipped; EC-G8, A-G5, A-G8, SEC-G1 ratchets all hold, none raised | **PASS** |
| Build | `flutter build apk --debug --dart-define-from-file=dart_defines/qa.json` | **PASS** |
| **Runtime, real data** | `integration_test/fit028_no_coach_live_test.dart` on `emulator-5554` against QA, signed in as `p1-victim`: `PRECONDITION role=client · active_coaches=0 · conversations=0` then `RENDER pitch=1 neutral=0 failed=0` | **VERIFIED LIVE** |
| Fixture residue | **none to clean** — the live test issues only `SELECT`s plus auth; it creates, updates and deletes nothing. Deliberate: F-21 is open and must not be exercised through unnecessary mutation. | **PASS** |

The live test asserts its own preconditions from the database *before* it asserts
anything about the screen, so if this fixture ever acquires a coach the run fails as
"precondition changed" rather than quietly reporting a FIT-028 regression.

**Still absent on this anchor, and why.** Six of ten declared interactions remain.
Three are bottom-nav items that exist in the shell and are invisible to a screen-file
heuristic — not gaps. Three are sample community content (`Tues Lifters…`, `Priya Hit
70 kg…`, `What's on this week`) belonging to FIT-005 and FIT-027; implementing them from
the design means fabricating messages and activity, which the brief forbids. Itemised in
`FIT_INTERACTION_COVERAGE.md`.

## 3c · FIT-017 · "Add 30 seconds" — the rest state's missing control

`/active-workout` declares two controls on its rest state. Only one existed.

**The defect, stated as a user experience.** A client mid-session who needs longer than
the prescribed rest had no control to say so. The only thing they could do was let the
clock run out — at which point the screen starts a siren, fires
`ScoreEngine().idleTimePenalty()` for −5, and drains another 5 points every 20 seconds
until they start the next set. The screen punished a need it gave them no way to express.

**What shipped.**

| Declared | Before | Now |
|---|---|---|
| `Skip rest, start set` | drawn "SKIP" / "STOP", **no accessible name**, ~30 dp tall | same short visible label, announces the design's phrase, 44 × 44 dp |
| `Add 30 seconds` | **absent** | present, same treatment |

The banner is a single row containing a progress bar, so the full phrase does not fit as
visible text. The short label is drawn and the design's wording is what a screen reader
announces. That is a deliberate compromise and is recorded as one.

**The rule the arithmetic encodes.** Extending adds to the *end*, not to now, so two taps
add a minute rather than restarting a short rest twice. And **overtime already accrued is
banked, never erased**: past zero the siren has been sounding and points have already
drained, so the overrun is added to the session's idle total exactly as dismissing the
rest would add it, and only then does a fresh 30 s start. Without that, tapping "+30s" the
instant the siren began would be an undo button for a penalty that had already fired.

`extendRest()` was extracted to `workout_provider.dart` to make this testable —
`_ActiveWorkoutViewState` touches `Supabase.instance`, `ScoreEngine` and a platform audio
channel in `initState`, so the arithmetic cannot be reached from a widget test. Same
reason `plan_summary.dart` was extracted.

| Layer | Evidence | Status |
|---|---|---|
| Arithmetic | `test/unit/extend_rest_test.dart` — 8 tests | **PASS** |
| Controls | `test/widget/rest_timer_controls_test.dart` — 5 tests | **PASS** |
| Guard strength | 6 mutations, all killed: extend-from-now, discard the banked overtime, leave `total` unchanged, drop `excludeSemantics`, drop the 44 dp constraint, wire "+30s" to the skip handler | **PASS** |
| **Runtime, on device** | `integration_test/fit017_rest_controls_device_test.dart` on `emulator-5554`: `dpr=2.625 physical=1080x2400`, then `+30s` → "Add 30 seconds" **44.0 × 44.0 dp** and `SKIP` → "Skip rest, start set" **44.0 × 44.0 dp** | **VERIFIED ON DEVICE** |
| Backend | none touched — `RestTimerWidget` is a leaf; nothing signed in, read or written | **n/a** |

**A correction of record, about my own test.** The first version of the target-floor
assertion was worthless. It mounted the banner under an `Align`, which hands down
loose-but-bounded constraints where `/active-workout`'s `Column` hands down unbounded
ones; the controls expanded to 566 dp tall and the assertion passed no matter what the
widget declared. Deleting the 44 dp constraint outright did not fail it. Found by running
that deletion as a mutation, which is the whole point of running them. The harness now
reproduces the production constraints, and the deletion fails as it should. The same
mutation was then run against FIT-028's CTA assertion, which killed it correctly.

The on-device leg exists for the same reason: F-6 and F-6b were found by measuring the
password toggle on the emulator (19.8 × 20.2 dp) after it looked fine in source. A host-VM
measurement is not a device measurement, and this file now has both.

## 3d · F-23 · the session-complete dialog claimed a delivery that never happened **FOUND AND FIXED**

**New finding this cycle.** Found while reading `/active-workout`'s completion flow for
FIT-018, not by a test.

`_WorkoutCompleteDialog._saveFeedback` ended `catch (_) {}` and then set
`_submitted = true` unconditionally. Every failure — no network, an RLS refusal, a
malformed row — produced the same screen as success: a green tick and the words
**"Feedback sent to your coach!"**. The dialog then offered only "Back to Home", so the
notes the client had written for their coach were gone and unrecoverable.

This is the F-15 error→empty pattern in its most harmful form. Not a failure shown as
emptiness — a failure shown as **success**, with a specific factual claim about a third
party attached to it. It is also a fabricated UI state, which the programme's brief names
explicitly.

A second falsehood sat next to it: the same line was shown to clients with **no coach at
all**. The insert writes `coach_id: null`, nobody is notified, and the screen still said
the feedback had been sent to a coach.

**Three outcomes, because the two writes fail independently.**

| Outcome | Condition | What the client is told |
|---|---|---|
| `failed` | the `workout_feedback` insert threw | "Could not send your feedback. Check your connection and try again." — form stays up, values intact, the button now reads "Try Again" |
| `saved` | feedback written; no coach, or the notification insert threw | "Feedback saved." |
| `delivered` | feedback written and the coach notified | "Feedback sent to your coach!" — now true |

A notification failure deliberately does **not** retract the save. The notes are stored;
reporting a failure would send the client to re-enter something already in the database,
and a second success would show their coach the same feedback twice. The coach loses a
ping, which is recoverable. The client is not lied to, which is the point.

The failure message carries **no interpolated exception** — F-2 and F-16 were raised
about exactly that, and this screen's own `_RestoreFailedView` already supplies the voice
and the recovery wording.

| Layer | Evidence | Status |
|---|---|---|
| Behaviour | `test/widget/workout_feedback_honesty_test.dart` — 8 widget tests + 4 on `deliveryFor` | **PASS** |
| Guard strength | 5 mutations, all killed: restore the original catch-all success, claim delivery when only saved, close the form on failure, retract the save when only the notification failed, claim delivery when there is no coach | **PASS** |
| Suite | 911 pass / 9 skipped | **PASS** |
| Runtime | **not yet** — reaching this dialog needs a completed session, which means writing `workout_sessions` and `workout_set_logs` rows to QA. Not done: F-21 is open and the instruction is not to exercise it through unnecessary mutation. Classified **FIXED IN CODE**, not VERIFIED LIVE. | **OPEN** |

**Why the dialog is now `WorkoutCompleteDialog` and takes a `submit` callback.** Its real
path reads `Supabase.instance`, which no widget test can provide — the defect was
unreachable from a test, which is part of why it survived. The seam exists so each
outcome is assertable; the default path is unchanged in behaviour.

### F-24 · investigated and **NOT a defect** — the complete dialog does not overflow

A widget test at 420 dp reported `A RenderFlex overflowed by 18 pixels on the right` from
the Duration/Calories/Idle row. **That was the harness, not the product.** Widget tests
render in Ahem, where every glyph is a full em square, so text measures wider than any
real font.

Settled by measuring on the device rather than by arguing about it.
`integration_test/fit018_complete_dialog_device_test.dart` mounts the same dialog on
`emulator-5554` with the real font at three widths, with the worst realistic values
(1:42:10, 1250 kcal, 10:05 idle):

| Surface | Stats row | Constraint | Overflows |
|---|---|---|---|
| 411.4 dp (the emulator) | 283.4 dp | 283.4 dp | 0 |
| 390 dp (the design's viewport) | 262.0 dp | 262.0 dp | 0 |
| 360 dp (narrowest in common use) | 232.0 dp | 232.0 dp | 0 |

The probe is kept as a regression guard. Recording this matters as much as recording a
real defect: an Ahem artifact reported as a product bug would be a fabricated finding,
and F-5 (a genuine 39 px landscape overflow, confirmed on-device) is what a real one
looks like.

## 3e · FIT-002 · the Workout Zone — the screen the design calls the most focus-critical in the app

Four of five declared controls. Two of them were **defects, not gaps**: they existed, and
both were unreachable by a screen reader and under the touch-target floor.

| Declared | Before | Now |
|---|---|---|
| `End session` | unlabelled 36 dp cross | named, 44.0 × 44.0 dp on device, chip still 36 dp |
| `Log set` | unlabelled 32 dp check — the most-used control on the screen | named, 44.0 × 44.0 dp, chip still 32 dp; a completed set reports the same control `enabled: false` |
| `Pause session` | **absent** | present |
| `Skip` | present | unchanged |
| `Adjust weight or reps` | visible label "Edit", target **54.8 × 13.0 dp** | design's wording drawn, **140.8 × 44.0 dp** |

**Pause suspends the rest countdown, deliberately.** Rest is wall-clock. Left running, a
paused session would keep sliding into overtime, sound its siren and take 5 points every
20 seconds for time the client has explicitly said they are not training. Overtime already
accrued is still banked, so pausing is not a way to erase a drain that has already
happened — only to stop a new one. Elapsed time is persisted on pause so a crash while
paused resumes at the right number.

**`Adjust weight or reps` — resolved, and the defect it was hiding.** The affordance on a
completed set did what the design describes but read "Edit". Announcing the design's
phrase over a different visible word would break WCAG 2.5.3, so the **visible label** was
changed and the name follows it.

Measuring it on the device to decide the layout question found the thing that actually
mattered: the control was **54.8 × 13.0 dp** — under a third of the 44 dp floor — sitting
under *every completed set* on one of the app's most-used screens. It is now
`140.8 × 44.0 dp`, announced as a button with a tap action.

The cost is recorded rather than hidden: the completed-set row grows `81.0 → 108.0 dp`, so
a 20-set workout scrolls about 540 dp further. Part of the height was given back by
dropping the affordance's bottom padding. The alternative was keeping a 13 dp target.

**FIT-002 is now 5/5** and is the first locked anchor completed in this programme.

| Layer | Evidence | Status |
|---|---|---|
| Zone controls | `test/widget/zone_action_test.dart` — 5 tests | **PASS** |
| Log set | `test/widget/set_tracker_row_test.dart` — 3 added, 10 total | **PASS** |
| Guard strength | 8 mutations, all killed: drop the Semantics wrapper, drop the 44 dp constraint, drop opaque hit-testing, grow the chip into the target (×2 widgets), drop the "Log set" label, always report enabled, grow the check | **PASS** |
| **Runtime, on device** | `integration_test/fit002_zone_controls_device_test.dart` on `emulator-5554`: `dpr=2.625 width=411.4dp`, `"End session" 44.0x44.0dp`, `"Pause session" 44.0x44.0dp` | **VERIFIED ON DEVICE** |
| Pause state machine | **not runtime-verified** — reaching it needs a live session, which means writing to QA. F-21 is open. Classified **FIXED IN CODE**. | **OPEN** |
| Suite | 919 pass / 9 skipped | **PASS** |

**A-G8 lowered 56 → 55, and why not further.** Naming "End session" removed one from the
population *while FIT-002 also added a control*, which is the ratchet working as intended.
"Log set" is now named too, and the scan still counts it: it reads forward from each
tappable, so a `Semantics` wrapper placed outside the `GestureDetector` is invisible to
it. The window was **not** widened backwards to make the number fall — a backward window
would also swallow an unrelated `Semantics` above a genuinely unnamed control, and a
ratchet that under-counts hides regressions while one that over-counts only overstates the
work left. The discrepancy is recorded in the guard rather than tuned away.

## 3f · F-15 · `/home` told clients they had done nothing when the read failed **FIXED**

`weeklyActivityProvider` ended `catch (_) { return List.filled(7, 0.0); }`. A failed read
arrived at "This Week's Progress" as a real week containing nothing, and that card does
not merely look empty — **it answers**. A client who had logged six meals was shown:

* **"0%"**, in 28 pt brand colour;
* "Log meals or workouts to see progress" underneath; and
* seven flat bars with today's lit at 15%.

A failure presented as a confident wrong number, with a nudge blaming the client for it.

**Fixed with no new copy, which is why it could be fixed at all.** The error now
propagates — the same change `assignedWorkoutsProvider` already carries — and the card
reports what it knows:

| | Before a failure | After |
|---|---|---|
| headline | `0%` in brand colour | `—`, dimmed |
| nudge | "Log meals or workouts to see progress" | **omitted** |
| bars | flat, today's highlighted | flat unknown track, nothing highlighted |

A lit "today" bar over a failed read reads as *"you did nothing today"*, which is exactly
the claim the screen cannot make.

**A genuinely empty week still answers `0%` with the nudge.** The fix must not collapse
the two in the other direction — an empty week is a real result, and a test pins it.

| Layer | Evidence | Status |
|---|---|---|
| Derivation | `test/unit/week_progress_test.dart` — 10 tests | **PASS** |
| Guard strength | 4 mutations, all killed: never take the error branch (the original behaviour), keep the nudge on failure, go by the value instead of the state so stale data answers, treat an empty week as a failure | **PASS** |
| Suite | 929 pass / 9 skipped; EC-G8 unchanged at 134 — `weekProgressFrom` holds the single `.valueOrNull` the card already had | **PASS** |
| Runtime | **not verified** — reproducing it needs the read to fail against QA, i.e. inducing a network or policy failure for a signed-in fixture. Classified **FIXED IN CODE**. | **OPEN** |

`weekProgressFrom` is extracted because `home_screen.dart` reaches `Supabase.instance` at
the top level, so the card cannot be mounted in a widget test — the same reason
`plan_summary.dart`, `extendRest()` and `ZoneAction` were extracted. The pattern by now is
settled: **a thing worth asserting gets moved somewhere it can be.**

**This does not close F-15.** Seven collapses remain, and each needs user-facing error
copy the design package does not supply for those frames. A full error state with a retry
— the `booking_screen.dart:612` pattern — is still OD-8. What changed is that the two
cases needing *no words at all* are done.

## 3g · F-15 · `/profile` told paying clients they had no coach **FIXED**

The "MY COACH" section read `assignedCoachProvider.valueOrNull`, so a failed read and
"you have no coach" arrived as the same `null`. On any failure the client saw:

> **No coach assigned yet**
> Complete onboarding to choose your coach.

Not a blank where data should be — a **specific false statement about the client's own
relationship, with an instruction attached**. Someone paying a coach every month, told to
go and pick one.

This is the same falsehood FIT-028 was built to avoid on `/messages`. There it was caught
before it shipped. Here it had shipped.

**Hidden, not reworded.** FIT-028 could fall back to a neutral sentence because one was
already shipping. Here the string already sitting there *is* the false one, so there is
nothing to fall back to, and any replacement is new product copy — OD-8, like the other
collapses. Saying nothing is not ideal; saying something untrue is worse, and that is what
shipped. The heading goes too: a "MY COACH" label over empty space is its own small
assertion that there is nothing there.

**A retry in flight stays hidden.** Riverpod reports `isLoading` and `hasError` together
during a refresh; a retry knows no more than the failure before it, and flashing a spinner
in and out of a hidden section is worse than leaving it hidden until there is something
true to say. Pinned by a test, because a plausible reordering would change it silently.

**`coachSectionFor` matches on the state, never on the value** — `.valueOrNull` is exactly
how the failure became "no coach", and it is the read EC-G8 ratchets. Fixing an error→null
collapse by adding an error→null read would have been self-defeating. EC-G8 is unchanged
at 134.

| Layer | Evidence | Status |
|---|---|---|
| Decision | `test/widget/coach_section_state_test.dart` — 6 tests on `coachSectionFor` | **PASS** |
| Wiring | 2 widget tests mounting the real `MyCoachSection` with the providers overridden | **PASS** |
| Guard strength | 4 mutations, all killed | **PASS** |
| Suite | 937 pass / 9 skipped; EC-G8 unchanged | **PASS** |
| Runtime | **not verified** — reproducing it needs the coach read to fail against QA. Classified **FIXED IN CODE**. | **OPEN** |

**A correction of record.** The first version of this fix had only the decision function
under test, and the mutation *"delete the early return in `build`"* **survived** — the
screen could have gone on rendering the denial with every unit test green. The section was
made public and mounted so the wiring is asserted too. Found by running the mutation,
which is the only reason it is not still true.

## 3h · F-22 · `/daily-checkin` — fifteen controls that announced nothing at all

The weekly check-in is five mood faces and two rows of five numbers. All fifteen were bare
`GestureDetector`s. A screen reader read five emoji and the words "Rough Meh Good Great
Amazing", then "1 2 3 4 5", then "1 2 3 4 5" again — **no role, no group, and no
indication of which one was chosen**.

Worse than an unnamed button. A blind client could fill this form, submit it to their
coach, and have no way to know what they had said. Both number rows are identical, so they
could not tell which one they were in either.

**Nothing was invented to fix it.** The mood options are named by the label already drawn
under each face. The number options are named from the section heading already drawn above
the row plus the number already drawn inside it — "Energy Level 3 of 5" — because a screen
reader announces one option at a time and "3" alone says nothing about what was rated.
`inMutuallyExclusiveGroup` and `selected` are facts about the widget, not copy.

| Layer | Evidence | Status |
|---|---|---|
| Behaviour | `test/widget/checkin_pickers_test.dart` — 8 tests | **PASS** |
| Guard strength | 6 mutations, all killed: drop the wrapper (the shipped defect), always report selected, drop the exclusive group, drop the `Semantics` `onTap`, name the numbers with a bare digit, stop excluding the child so the emoji leaks | **PASS** |
| Suite | 945 pass / 9 skipped | **PASS** |
| Runtime | not verified on device — these are leaves, and the host-VM semantics tree is the same tree. Classified **FIXED IN CODE**. | **OPEN** |

`MoodPicker` and `NumberPicker` were extracted to `widgets/checkin_pickers.dart` because
the screen constructs a `CheckinService` in a field initializer and loads from Supabase in
`initState`. Fifth instance of the same move.

**A-G8 did not fall.** These fifteen carry `Text` inside the tappable, so the scan never
counted them — its heuristic is "an `Icon` and no `Text`". The count stays at 47 and this
is a reminder of what it does not see: **a control with a visible label can still be
unreachable**, because a label is not a role and not a state.

## 3i · Fixture hygiene for this cycle — **nothing was written to QA**

The brief requires every QA fixture to be cleaned up and the remainder proved zero. This
cycle there was nothing to clean up, which is a stronger result and was deliberate: F-21
is open, and the standing instruction is not to exercise it through unnecessary mutation.

Every device probe added this cycle mounts a widget directly and injects its data, so four
of the five touch no backend at all. The fifth (`fit028_no_coach_live_test.dart`) signs in
as `p1-victim` and issues only `SELECT`s.

Verified after the run, as `p1-victim`, against QA:

| Table | Rows owned by the fixture |
|---|---|
| `workout_programs` (`coach_id = uid`) | **0** |
| `workout_program_assignments` (`client_id = uid`) | **0** |
| `workout_feedback` (`user_id = uid`) | **0** |
| `user_profiles.onboarding_complete` | **`false`** — unchanged |

The last row is worth stating. Reaching `/messages` through the app UI would have needed
this fixture past onboarding, and a `PATCH` to flip that one column **was attempted and
refused by the sandbox**. Rather than work around the refusal, the runtime verification was
re-done as an integration test that mounts the screen against the live read paths — which
proved more, wrote less, and left the fixture exactly as it was found.

## 3j · FIT-027 · "What's on" — three routes under one list

`/classes · /events · /challenges under one list`. The three shipped as separate screens,
and F-14 recorded `/events` and `/challenges` as **stranded** once the bottom nav went to
five tabs. This is the anchor that unstrands them.

**Five of the ten declared interactions, and that is the ceiling.** `Back`, `All`,
`Classes`, `Events`, `Challenges` — the entire structure — are present. The other five are
the design board's own sample rows (`11 Sep Reformer, small group Class · Studio 2 · 4
places left`). The row *formats* are implemented and tested; matching the literal strings
would mean fabricating a class, an event and a challenge. Itemised in
`FIT_INTERACTION_COVERAGE.md`.

### The rule the architecture exists for

**A partial failure is reported, never hidden.** Three sources load independently. If
Events fails and the other two succeed, rendering the surviving two as "what's on" tells
the client there are no events this month — a false answer assembled from a true one and a
failure. A merged list invites exactly this: the list still looks full, so nothing looks
wrong.

So `WhatsOn` carries `failed` alongside `items`, and:

| State | What the screen does |
|---|---|
| one source failed, others have rows | names the failed source **above** the rows that loaded |
| one source failed, nothing else to show | the failure notice **replaces** the empty state |
| viewing a single segment | reports that source's failure, and only that one |
| all three genuinely empty | the three shipped empty lines, no failure line |
| any source still in flight | a spinner — **not** a partial list |
| a failed source carrying stale rows | contributes **none** of them |

**Every string is one this repository already renders.** `Could not load events`
(`events_screen.dart:66`), `Could not load classes` (`coach_classes_screen.dart:37`),
`Could not load challenges` (the `Could not load [noun]` pattern used in fifteen files),
`No classes yet`, `No upcoming events`, `No challenges here`, and `Try again` (the
package's own label, 16 declarations). FIT-027 declares only a `default` state, so it
supplies no failure or empty copy — and this screen can report a failure at all only
because it borrows from the three screens it replaces. Nothing here needs OD-8.

### Two swallowed reads fixed on the way

| Where | Was | Now |
|---|---|---|
| `LiveClassService.getUpcomingClasses` | `catch (_) { return []; }` | propagates — without this FIT-027's failure machinery could never fire for classes |
| `events_screen.dart`'s private provider | `catch (_) { return []; }` | propagates, which **makes `/events`' own `error:` branch reachable for the first time** — the copy for the failure was written; the catch made sure nobody ever saw it |

| Layer | Evidence | Status |
|---|---|---|
| Rules | `test/unit/whats_on_test.dart` — 26 tests | **PASS** |
| Wiring | `test/widget/whats_on_view_test.dart` — 16 tests over the real view and the three real source providers | **PASS** |
| Guard strength | 9 mutations, all killed | **PASS** |
| **Runtime, on device** | `integration_test/fit027_whats_on_device_test.dart` on `emulator-5554` at 411.4 / 390 / 360 dp: all four segments ≥ 44 dp, exclusive-group + tap action on each, 0 overflows at every width | **VERIFIED ON DEVICE** |
| Suite | 987 pass / 9 skipped; A-G8 unchanged at 47, EC-G8 unchanged at 134 | **PASS** |

The segment row needs **372.2 dp**. It fits at 411 and at the design's own 390; at 360 it
scrolls horizontally, which is what the widget is for. Measured, not assumed — and
measured on the device because the host harness renders in Ahem, where a width means
nothing (F-24 is the recorded instance of mistaking an Ahem overflow for a product bug).

### A trivially-passing test, caught and moved

The first version asserted "a failed read carrying stale rows contributes none of them" as
a **widget** test. It passed — and it would have passed whatever the code did. The harness
turns an `AsyncError` into `Future.error`, so Riverpod rebuilds with a plain error and the
previous value is discarded; the state the test named could not exist inside it. Found by
running the mutation, which survived.

`combineWhatsOn` was extracted as a pure function so the state can actually be
constructed, and the assertion moved there, where the mutation now fails. The widget file
keeps a note saying why that particular claim is not made in it.

### OD-15 — the coach's "New Class" affordance

FIT-027 does not draw one. A booked class is still a class and appears in the one list
carrying "Booked", so nothing was lost there — but removing the FAB would take away a
coach's only way to create a class. **A locked screen not drawing something is not the
same as the design saying to delete it**, so the FAB stays and the discrepancy is recorded
rather than resolved by guessing.

## 3k · FIT-005 · Connect — "Coach, community and pods in one relationship layer"

`/messages` was a conversation list. The anchor makes it the place a client sees every
relationship they have. Three teasers now sit under the conversations — **Feed**,
**Groups**, **What's on** — all three titles being labels the design package declares, all
three fed by providers that already existed.

**FIT-027 is reused, not reimplemented.** The "What's on" teaser reads the same merged
list `/classes` reads. Two independent definitions of "what is coming up" would drift, and
the first symptom would be the two screens disagreeing in front of the client.

**The rule, again, for the same reason.** A section whose source failed must never be
drawn as a section with nothing in it. Under a heading that says "Groups", an absence is
an answer: it tells the client they are in none.

| State | What the section does |
|---|---|
| source failed | names the failure under its own heading; the other sections are untouched |
| failed carrying stale rows | contributes **none** of them |
| genuinely empty | stays quiet and offers the way to the screen that owns it |
| still loading | renders **nothing** — not a spinner, and above all not an empty section |
| the merged list partly failed with rows surviving | shows them; the full screen names what is missing |

**`Open message` is a hint, not a name.** The row's accessible name must contain its
visible label (WCAG 2.5.3), and what is visible — participant, last message, age — is also
what a client needs in order to choose a thread. The design's phrase describes the action,
so it is announced after it. Naming the row "Open message" would have scored a coverage
point by deleting the information the row exists to carry. The mutation that does exactly
that now fails.

| Layer | Evidence | Status |
|---|---|---|
| Rules | `test/unit/connect_sections_test.dart` — 16 tests | **PASS** |
| Wiring | `test/widget/connect_sections_view_test.dart` — 10 tests over the real sections and real providers | **PASS** |
| `Open message` | 1 test in `messaging_no_coach_test.dart`, 2 mutations killed | **PASS** |
| Guard strength | 9 mutations, all killed | **PASS** |
| **Runtime, on device** | `integration_test/fit005_connect_device_test.dart` on `emulator-5554`: all three headings report `header=true`, all three "Open …" affordances `button:true tap:true` at `379.4 × 44.0 dp` | **VERIFIED ON DEVICE** |
| Suite | 1014 pass / 9 skipped; A-G8 47, EC-G8 134, both unchanged | **PASS** |

**Five of twelve, and the ceiling is lower than it looks.** Four of the seven absent are
the design board's sample rows and the bottom nav. One — `Priya Hit 70 kg…` — is counted
but is a **doc-comment artifact**, and is recorded as one rather than left to flatter the
number. `Book` is genuinely absent: the teaser defers to `/classes`, which carries the
affordance, and wiring a booking from `/messages` would be a second write path to the same
table for one row in a summary.

## 3l · F-21 · blast radius — **screen-level, static, no further mutation**

Full analysis in **`docs/F21_BLAST_RADIUS.md`**. The policy was not changed; OD-14 stands.

**The fifteen are not equally dangerous.** The split is whether the predicate names one
party or two:

| Class | Count | Effect |
|---|---|---|
| two-party, `coach_id = uid() OR client_id = uid()` | **5 policies, 4 tables** | a caller can write a row naming itself coach and **any other user** as client — the class that reaches a victim, and the one that was proven |
| single-party, `coach_id = uid()` | 11 | self-forgery: claim to be a coach; no direct victim |

**What a victim would actually see, traced end to end in code.** A forged
`workout_program_assignments` row satisfies `getMyAssignedProgram()`'s filter
(`.eq('client_id', me).eq('status','active')`, `coach_program_service.dart:219`) exactly as
a real one does. It decodes through `assignedWorkoutsProvider` into `/train`'s hero card and
programme list, `getTodaysWorkout()` → `/home`, and `/active-workout`. **The victim sees
prescribed exercises, loads and rep schemes attributed to their coach, and can start and log
the session.** The attacker chooses the weights, which makes this a physical-safety exposure
in a strength product, not only a data-integrity one.

**A second effect, not previously recorded.** That read uses `.maybeSingle()`. A victim who
already has a real active assignment and receives a forged one matches **two** rows and the
read fails — so the forged row does not merely add a fake programme, **it makes the victim's
real programme unreadable.** Because `assignedWorkoutsProvider` now propagates its errors
(the F-15 work), the client is at least shown `_PlanUnavailable` rather than told they have
no plan. The denial stands either way.

Also traced: forged `coaching_calls` appear in `/checkins` upcoming and **inflate `/home`'s
activity bars** (calls are weighted ×3 there); forged `client_nutrition_plans` and
`client_habits` land under the victim's id; forged `classes` and `challenges` are publicly
readable and render in `/classes` and `/challenges` as real.

**Which screens are safe to keep integrating.** The test is whether a screen's correctness
depends on the integrity of a row written through one of these policies — not whether it
touches the feature at all. `/train`, `/active-workout`, `/checkins`, `/booking`, nutrition
and habits surfaces, `/coach-dashboard` are **BLOCKED-BY-F21 for integrity claims**, and
that is narrower than "do not work on them": FIT-002 was taken to 5/5 while F-21 was open,
because accessibility and interaction work does not rest on the row being authentic.
`/messages`, `/classes`' structure, `/home`'s week card, `/daily-checkin`, `/profile`,
`/progress`, `/intake` and auth are clear.

**SEC-G2 added.** SEC-G1 holds the whole population at 15; a new two-party policy could
hide inside that number by displacing a single-party one. SEC-G2 holds the cross-user-write
subset at 5. Both parse the real migrations, both are ratchets, and both were
mutation-tested — a sixth two-party policy fails SEC-G2, a sixteenth single-party one fails
SEC-G1 without disturbing SEC-G2.

**A correction of record.** The analysis first stated that `coaching_calls` carried its
policy "twice", from reading the migration. SEC-G2 measured it: they are two *different*
policies with different names, one added later. Five, not four. A correction that fixed one
and left the other would have looked complete against the guess.

## 3m · FIT-023 · Check-in hub — "status and history"

`/checkins` had a calendar strip and an upcoming-sessions list. FIT-023 declares two
controls and a history, and the screen had neither.

| Declared | Built |
|---|---|
| `Measurements` | → `/progress`, which is where this app keeps them. No screen was invented to satisfy a label. |
| `Start check-in` | → `/daily-checkin` |
| a week history | real weeks from `weekly_checkins`, rendered `Week 13 · Energy 3 of 5 · Nadia replied` |

### Two F-15 collapses closed here

| Where | Was | Now |
|---|---|---|
| `_loadCalls()` | `catch (_) { _loading = false; }` → **"No upcoming sessions. Book a call with your coach."** on any failure | `Could not load sessions` with a `Try again`, distinct from the empty state |
| `WeeklyCheckinService.getWeeklyCheckins()` | `catch (e) { return []; }` | propagates — without it the new history section would have told a client who has checked in for thirteen weeks that they never had |

The first is the sharper of the two: it did not merely hide a failure, it **instructed the
client to book a call they may already have booked**.

### "Energy steady" was not built, and that is the point

The anchor draws `Week 13 · Energy steady · Nadia replied`. Two of those three come
straight from the data. The third does not: the stored value is **1–5**, and turning it
into Low / Steady / Strong means choosing thresholds on a number a coach reads. That is the
same decision FIT-004's difficulty mapping is blocked on — recorded together as **OD-16**.

The row states `Energy 3 of 5` instead, which is the phrasing already used for those
controls' accessible names. **A test asserts the row never produces the anchor's three
words**, so the decision cannot be made silently by a later edit — the mutation that makes
it fails.

`Awaiting reply` is FIT-025's own screen name, so the no-reply half is not invented either.
A **pending** week reports neither: nothing has been sent, so nobody is awaiting anything,
and merging the two would misreport the client's own state back to them.

| Layer | Evidence | Status |
|---|---|---|
| Rules | `test/unit/checkin_hub_test.dart` — 15 tests | **PASS** |
| Wiring | `test/widget/checkin_hub_sections_test.dart` — 7 tests over the real sections | **PASS** |
| Guard strength | 6 mutations, all killed — including *"interpret energy into the anchor's words"*, which is OD-16 made silently | **PASS** |
| Suite | 1038 pass / 9 skipped; A-G8 47, EC-G8 134, both unchanged | **PASS** |
| Runtime | not device-verified — the sections are leaves and the host semantics tree is the same tree. **FIXED IN CODE**. | **OPEN** |

**BLOCKED-BY-F21 note.** `/checkins`' *upcoming sessions* read `coaching_calls`, which
carries the two-party policy (`F21_BLAST_RADIUS.md` §3b) — a forged row appears there as a
session the client never booked. **The work done here is structure, accessibility and error
honesty, none of which rests on those rows being authentic.** The integrity of what the
sessions list displays remains blocked on OD-14, and is not claimed.

## 3n · FIT-004 · Check-In, and a measurement that counted its own comments

### FIT-004 — three of its declared controls

| Declared | Built |
|---|---|
| `Past check-ins` | → `/checkins` |
| `Add a progress photo` | → `/progress`, where this app already keeps photo capture and the `progress-photos` bucket. No screen invented to satisfy a label. |
| `Send to Nadia` | the submit button is addressed to the client's coach, by name |

**The submit label is the interesting one.** The name is real data, so using it invents
nothing — but the two failure modes either side of it are ones this repository has already
been bitten by:

* naming a coach the client does not have, and
* naming one when the read **failed** — which is `/profile`'s "No coach assigned yet"
  collapse turned inside out. There a failure claimed the client had no coach; here it
  would claim they have one. Both are the screen answering a question it cannot.

So the name is used only on a settled, non-empty value. Loading, failed, no coach, and a
coach with a blank first name all fall back to `Submit Check-In` — the label this screen
already ships. 7 tests, 2 mutations killed.

`Low` / `Steady` / `Strong` remain **OD-16**, unchanged.

### The measurement counted its own comments — reported numbers fell by four

The coverage tool matched a declared label's first three words against the **raw text** of
the implementing file. Dart comments are raw text, and this programme's comments quote the
design constantly. Four anchors had accumulated artifacts — each recorded at the time, none
left to flatter the count:

| Anchor | Counted | Actually |
|---|---|---|
| FIT-028 | `Connect` | a doc comment naming the anchor |
| FIT-005 | `Priya Hit 70 kg…` | a comment quoting the sample row |
| FIT-023 | `Week 13 Energy steady…` | the same |
| FIT-004 | `Steady`, `Strong`, `Send to Nadia` | a comment explaining why the mapping was **not** built |

The last settled it. **Writing down that something was deliberately not implemented made
the metric report it as implemented.** A number that rises when nothing ships is not a
measurement, and annotating each case was treating the symptom.

`apps/mobile/tool/fit_coverage.dart` now strips comments before matching, leaving string
literals alone. Every anchor this programme touched was re-measured:

| Anchor | Was reported | Measured |
|---|---|---|
| FIT-002 · FIT-017 · FIT-027 · FIT-028 | 5/5 · 2/2 · 5/10 · 4/10 | **unchanged** |
| FIT-005 | 5/12 | **4/12** |
| FIT-023 | 5/10 | **4/10** |
| FIT-004 | 8/11 | **5/11** |

Headline: **276 → 272 present**, locked anchors **71 → 67**. The anchors reported complete
were complete, which is the part of the result worth having.

## 3o · F-15 — the inventory is closed

Nine error→empty collapses were recorded in §6c. **All nine are now fixed, and none of
them needed new product copy.**

| Screen | Was | Now |
|---|---|---|
| `/train` | `error: (_, __) => '0'` — **"0 workouts" as a real answer** | `'—'` |
| `/home` | `catch` → all-zero bars → **"0%"** and "Log meals or workouts to see progress" | `'—'`, nudge dropped, no bar highlighted |
| `/profile` | `valueOrNull` → **"No coach assigned yet · Complete onboarding"** | section hidden |
| `/classes` | `valueOrNull ?? []` and a swallowing service | per-source failure named |
| `/checkins` sessions | `catch (_)` → **"No upcoming sessions. Book a call with your coach."** | `Could not load sessions` + Try again |
| `/checkins` history | `catch (e) { return []; }` in the service | propagates |
| `/challenges` | `AsyncError` never consumed → "🏁 No challenges here" **and "0 active challenges"** | `Could not load challenges` + Try again, count `—` |
| `/progress` | `catch (_)` → **three empty states at once** | `Could not load your progress` + Try again |
| `/coach-dashboard` ×4 reads | `catch` → `[]` → **"No clients found"** | `Could not load your clients`; any of the three failing is reported |

### What OD-8 turned out to be

OD-8 said these could not be fixed because each needed **user-facing error copy**, and
writing nine new strings would be inventing product copy. That was true of writing them.
It was not true of the fix.

Every line used is one this repository already renders: `Could not load events`
(`events_screen.dart:66`), `Could not load classes` (`coach_classes_screen.dart:37`), the
`Could not load [noun]` pattern in fifteen files, and `Try again` — the **design package's
own label**, 16 declarations. Two of the nine needed no words at all: a number the screen
could not support became `'—'`.

**OD-8 is no longer blocking anything.** It asked for permission to invent; none was
needed. It stays open only as the question of whether the owner wants *better* copy than
the house pattern.

### The two that were worse than "empty"

Most of the nine hid a failure. Two **instructed the client to act on it**:

* `/checkins` told them to **book a call with their coach** — one they may already have
  booked, which is what the failed read was trying to tell them.
* `/coach-dashboard` told a coach **their entire roster had vanished**. Both false and
  alarming, and the read had simply failed.

### Three that answered with a confident wrong number

`/train`'s "0 workouts", `/home`'s "0%", `/challenges`' "0 active challenges". Not a
failure shown as emptiness — a failure shown as a **measurement**. All three now read
`'—'`, which needs no copy and cannot be misread as a result.

## 3p · Addressing the coach by name — one rule, three screens

The package names the client's coach in three places: **"Send to Nadia"** (FIT-004),
**"Message Nadia"** (FIT-015), and `/train`'s empty-state body copy. The name is real data,
so using it invents nothing — but the two failure modes either side of it are easy to
reintroduce one screen at a time:

* naming a coach the client **does not have**; and
* naming one when the read **failed** — `/profile`'s "No coach assigned yet" collapse
  turned inside out. There a failure claimed the client had no coach; here it would claim
  they have one. Both are a screen answering a question it cannot.

So the rule lives once, in `coach_name.dart`: **the name is used only on a settled,
non-empty value.** Loading, failed, no coach and a blank first name all fall back to
wording that stays true without one — `Submit Check-In`, `Message your coach`,
`Your coach` — each of which this repository already shipped.

| Layer | Evidence | Status |
|---|---|---|
| Rule | `test/unit/coach_name_test.dart` — 10 tests | **PASS** |
| Guard strength | 2 mutations killed: a failed read still yields a name; a blank name is used verbatim | **PASS** |
| Suite | 1056 pass / 9 skipped | **PASS** |

**A third mutation was an equivalent mutant, and is recorded as one.** Adding an explicit
`AsyncLoading()` arm to the switch changed nothing, because the catch-all already returns
null for a true loading state — and a refresh in flight is `AsyncData` with
`isLoading: true`, not `AsyncLoading`, which was measured rather than assumed. A surviving
mutation and a mutation that changes nothing look identical in a report; this one is the
second, and the test now says so.

**FIT-015's `Message Nadia` still measures ABSENT, and correctly.** The label is composed
(`'Message $name'`), so the literal string never appears in source. Making the metric count
it would mean hard-coding "Nadia" — naming every client's coach after the design board's
example. The same ceiling as FIT-027's and FIT-005's sample rows.

## 3q · F-25 · two live assertions that could not observe what they asserted

Found by running the **whole** `integration_test/` directory rather than the files added
this cycle — which is the only reason it surfaced.

`service_logic_test.dart` counted the **recipient's** notifications from the **sender's**
session. `notifications` carries
`recipients read own notifications … USING (recipient_id = auth.uid())` (migrations 003 and
004), so both reads return 0 for any sender, forever.

| Test | Asserted | Result |
|---|---|---|
| `MessagingService.sendMessage notifies recipient exactly once` | `after - before == 1` | `0 == 1` — **red forever**, and it said nothing about the trigger |
| `WeeklyCheckinService.submitWeeklyCheckin scores + notifies coach` | `after - before <= 1` | `0 <= 1` — **green forever, whatever the app did** |

One root cause, opposite symptoms. **The green one is the more dangerous**, because nobody
looks at a passing test: it had been sitting in the suite reporting that the coach is not
double-notified, while being structurally incapable of detecting it either way. That is the
"green whatever the app does" shape `QA_CLOSURE_STANDARD` §4 warns about, in a file that
runs against the live database.

And the red one is worse than useless: **the only way it could ever have passed is if
`notifications` leaked rows across users.** A test whose passing condition is a privacy
defect is not a weaker test, it is a wrong one. RLS was verified working during this
analysis — the same query run as the client returns 0, run as the recipient returns their
own rows.

### What replaced them

Each test now asserts what its own session can observe, and nothing else:

* the sender is **not** notified of their own message; the message row exists;
* the client is **not** notified of their own check-in; the points were awarded.

The recipient-side half — *did the coach actually get one?* — needs the **recipient's
session**, which this file does not have: it signs in as `test@12circle.app` and does not
hold that client's coach's credentials. **It is recorded as open rather than asserted from a
session that cannot see it.** Closing it needs either a coach fixture paired to this client
or a `SECURITY DEFINER` counting RPC; both are changes to the test estate, not to a policy.

`test/unit/message_notification_guard_test.dart` holds the half that *can* be held in the
fast suite: no Dart-side notification insert in `sendMessage` (the duplicate the test was
originally written for), the trigger and its `AFTER INSERT ON messages` are still installed,
and the cross-RLS count does not come back. 3 mutations, all killed.

**A correction of record, again about comments.** The first version of that guard failed on
the very file it protects, because that file's header *explains* the defect and quotes the
expression it forbids. The FIT coverage metric had the identical fault the same day. Both
now strip comments before matching: **writing down what went wrong must not register as the
thing going wrong.**

### An environment note, so the next run is not misread

`flutter test integration_test/` runs files in parallel and they race on the single
`build/app/outputs/flutter-apk/app-debug.apk`, producing
`Error opening archive … Invalid file` and *"No application found for
TargetPlatform.android_arm64"*. Those are **loading** failures of the harness, not test
results. Run device tests with `--concurrency=1`, or as an explicit file list.

With a fresh APK and `--concurrency=1`: **16 pass**, and the only failures are
`wrk01_progression_live_test` and `uix1_booking_e2e_test`, which fail their own
`setUpAll` guard — `Bad state: PROBE_RUN_ID is required — the fixture must be run-scoped`.
They are driven by `tool/negative_control/wrk01_live_probe.sh` and are expected to refuse a
bare run.

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

#### Second pass — the privileged screens' actual calls, probed

A delegated trace produced the exact table/RPC surface of the four routes, which was then
probed with the same client identity:

| Probe | Result | Verdict |
|---|---|---|
| `rpc admin_platform_stats` | **403 `42501` "not authorized"** | denied — `SECURITY DEFINER` + `is_admin()` guard, `019_admin_dashboard.sql:24-26` |
| `rpc admin_recent_users` | **403 `42501` "not authorized"** | denied — same guard, `:60-62` |
| `rpc coach_client_ai_signals` | 200 **`[]`** | executes, but server-filters `r.coach_id = auth.uid()` (`079:88`) — returns nothing |
| `GET events` | 200, 3 rows | `"all read events" USING (true)` (`001:398`) — shared content, by design |
| **`GET platform_settings`** | **200, 1 row** | **readable by any authenticated user** |

**F-12a · Platform configuration is readable by every member — the one real exposure.**

`039_platform_settings.sql:17-18` declares
`CREATE POLICY "read platform settings" … FOR SELECT TO authenticated USING (true)`. Writes
are correctly admin-gated (`:22-25`), but reads are open, and the table holds business
configuration — the row the admin dashboard reads is `marketplace_commission_rate`
(`platform_settings_service.dart:11`).

So a member can read the platform's commission rate. **Classification: P3 — business-
configuration disclosure, not user-data disclosure.** It is declared and deliberate in the
migration, so it may be intentional; recorded so the owner can confirm rather than
discover. Raised as **OD-9**.

**Declared-policy weak points found by the trace but NOT demonstrated as exploitable**, each
recorded for the eventual table-by-table sweep rather than asserted as defects:
`events` vendor UPDATE/DELETE are ownership-scoped but the role predicate sits only in
`WITH CHECK` (`020:18-27`); `event_registrations` vendor UPDATE has `USING` and no
`WITH CHECK` (`020:42-49`); `workout_logs` has **no coach-read policy at all** (owner-only,
`003:193`) while three code paths read it for other users' ids — which means those reads are
declared-denied and the coach surface silently gets nothing; `goals` coach-read keys on the
row's `coach_id` column rather than an active-relationship check (`018:71`); and `checkins`
— read by `coach_dashboard_screen.dart:107-112` — **does not exist in any migration** and is
already a tracked contract violation (`known-violations.json:14-17`, I-CHK-01).

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

### F-14 · UPDATE — the stranding objection is resolved by FIT-001

My recorded reason for not adopting the mandated five tabs was that `/directory` is the
**sole** entry to `/events` and the primary entry to `/classes`, `/challenges`,
`/community` and `/progress`, so replacing the FAB would strand them. **FIT-001 answers
that directly.**

Its subtitle is *"Activity folded in · Directory moved to the top bar"*, and its frame
carries three 44×44 controls in the Home bar:

```
aria-label="Directory"      ph-compass
aria-label="Messages"       ph-chat-circle
aria-label="Notifications"  ph-bell   + unread dot (violet-txt)
```

So the design does not delete those destinations — it **relocates** them. Directory moves
from the bottom FAB to the Home top bar, and Activity folds into Home rather than holding a
tab. That frees exactly the two slots the five-tab contract needs for Nutrition and
Connect.

**Consequence for the decision:** the technical objection is withdrawn. Nothing is
stranded, and the package supplies the complete relocation plan rather than only the tab
list. What remains is a genuine product choice — whether to adopt the new navigation —
not an unanswered engineering question. The repo already has a top bar
(`core/widgets/app_top_nav.dart`, which routes to `/messages` at `:116` and `/profile` at
`:73`), so the Directory and Notifications controls have an established home.

This is recorded as an update rather than an edit: the original objection was correct on the
evidence available then, and wrong once FIT-001 was read.

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

**Status: ~~MAPPED, NOT YET IMPLEMENTED~~ → IMPLEMENTED AND RUNTIME-VERIFIED.**

#### F-20 · Acceptance criteria, each with evidence

Runtime walk on `emulator-5554`, signed in as `p1-victim`, Workouts → browse list.

| # | Criterion | Evidence | Verdict |
|---|---|---|---|
| 1 | Implementation corresponds to FIT-016 | back/more bar, context line, 3-col metric strip between hairlines, coach note, numbered rows, CTA — all from the board | **PASS** |
| 2 | Selected identity preserved | `selectedWorkoutProvider` set at the nav site, read by the screen | **PASS** |
| 3 | Title matching no longer identity | `_WorkoutItem.workoutId` resolves `Workout.id`; the title comparison is deleted | **PASS** |
| 4 | Workout A displays A | tapped "Full Body Strength" → `ASSIGNED BY COACH SARAH` · `3 EXERCISES / 45min / 7 SETS` · `1 Barbell Squat 3 × 8 · 60 kg · rest 90 s` | **PASS** |
| 5 | Workout B displays B | tapped the card shown as `Glute & Hamstring\nFocus` → resolved to domain title **`Glute and Hamstring Focus`** · `2 EXERCISES / 50min / 5 SETS` · `1 Hip Thrust 3 × 12 · 80 kg` | **PASS** |
| 6 | No fabricated data | every value traced to `Workout`/`WorkoutExercise`/`WorkoutSet`/`Exercise` | **PASS** |
| 7 | Empty/no-selection distinct | tapped "Metabolic Overdrive" (no domain workout) → **"No workout selected"**, no CTA, no exercises | **PASS** |
| 8 | Error does not masquerade as success | — | **N/A, stated honestly** — see below |
| 9 | Existing flows intact | 848 tests pass; active-workout, list, assignment, AI generation untouched | **PASS** |
| 10 | Relevant tests pass | 6 new widget tests + 848 suite + analyzer clean | **PASS** |
| 11 | Android runtime verification | the walk above; **zero** `E/flutter`, `FATAL`, `RenderFlex` or overflow throughout | **PASS** |
| 12 | Accessibility not regressed | `Back`, `Begin session` and each row (`1 Barbell Squat 3 × 8 · 60 kg · rest 90 s`) carry names; rows ≥ 44 dp | **PASS** |

**Criterion 5 is the decisive one.** The card's *displayed* title and the *resolved* workout
title differ (`Glute & Hamstring\nFocus` vs `Glute and Hamstring Focus`). That they differ
is the proof: a title match could not have produced this, and previously that exact card
always fell through to the mockup.

**Criterion 8 — why N/A rather than PASS.** This screen reads an in-memory
`StateProvider`; there is no fetch, so there is no load to fail and nothing to inject. The
analogous risk — a *missing* selection being dressed up as content — is criterion 7 and it
passes. Claiming a PASS for an untestable path would be exactly the category conversion
this ledger forbids.

**Two defects found and fixed during verification, both by runtime evidence:**

- **Doubled semantics labels.** Wrapping a labelled `Semantics` around a widget that
  already contains the same `Text` produced `'Sign in\nSign in'` and
  `'Continue with Apple\nContinue with Apple'` — a screen reader says it twice. Visible in
  my own earlier on-device dumps and not questioned at the time. Removed the redundant
  `label:` on both auth buttons and the CTA, and used `excludeSemantics` on the exercise
  row whose composed label replaces its children. Re-verified on-device: now `'Sign in'`.
- **Back button returned to `/train`, not the list.** Navigating with `context.go` leaves
  no pop-able entry, so `canPop()` was false and the fallback fired. Changed to
  `context.push`, matching this feature's own convention
  (`train_hub_screen.dart:123`). Re-verified: Back now lands on `BROWSE WORKOUTS`.

**A test of mine was passing trivially and was fixed.** The screen is a `ListView`, so the
CTA sat below the fold of the default 800×600 test surface and was never built — meaning
`expect(find.text('Begin session'), findsNothing)` proved nothing. The tests that assert
the CTA's presence or absence now set a 390×1600 surface first.

**Fixture hygiene.** Reaching the list required the fixture's `onboarding_complete` to be
true. It was flipped, used, and restored: re-read confirms `onboarding_complete: false`,
`role: client`. Device state cleared with `pm clear`.

#### F-20b · The browse list advertises workouts that do not exist **NEW**

Established while fixing F-20, and left unfixed deliberately.

| Browse card | Domain workout |
|---|---|
| Full Body Strength | `id '1'` |
| `Glute & Hamstring\nFocus` | `id '2'` |
| Metabolic Overdrive | **none** |
| Morning Cardio Blast | **none** |
| Active Recovery Flow | **none** |
| — | `id '3'` Upper Body + Core Circuit — **not in the list** |

`_sampleWorkouts` (`workout_list_screen.dart:64`) is a hardcoded list of five presentation
items; `workoutsProvider` returns three domain workouts. **Three cards have no workout
behind them at all, and one real workout is not offered.** Those three now open an honest
"No workout selected" instead of a mockup, but a browse list that advertises sessions the
app cannot open is a product-content question, not a QA repair. **OWNER DECISION — OD-11**:
remove the unbacked cards, author real workouts for them, or accept the placeholder.

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
| ~~`progress_screen.dart:139`~~ | `/progress` | ~~`catch (_)` → three empty states at once~~ → **`Could not load your progress` + Try again** | "Log your first weight…", "No entries yet", "No check-ins yet" | **YES** | direct Supabase, 6 fetches | yes | FIT-052…057 | **none for this leg** |
| ~~`checkin_screen.dart:146`~~ | `/checkins` | ~~`catch (_)` → "No upcoming sessions. Book a call with your coach."~~ → **`Could not load sessions` + Try again** | "No upcoming sessions…" | **YES** | `coaching_calls` | yes — see §3m | FIT-023 | **none for this leg** |
| ~~`coach_dashboard_screen.dart:68`~~ | `/coach-dashboard` | ~~`catch` → `[]` → "No clients found"~~ → **`Could not load your clients`** | "No clients found…" | **YES** | clients query | yes | FIT-032 | **none for this leg** |
| ~~`coach_dashboard_screen.dart:98/114/133`~~ | `/coach-dashboard` | ~~`catch` → `[]` ×3~~ → **errors propagate**; any of the three failing is reported | empty tabs | **YES** | check-ins, workouts, aggregate | yes | FIT-032/033 | **none for this leg** |
| ~~`profile_screen.dart:830`~~ | `/profile` | ~~`valueOrNull` → null → "No coach assigned yet"~~ → **section hidden**; a failure is never rendered as a denial | "No coach assigned yet · Complete onboarding to choose your coach." | **YES** | coach provider | partial — see §3g | FIT-029 | **none for this leg**; a visible error state still needs OD-8 |
| ~~`classes_screen.dart:39`~~ | `/classes` | ~~`valueOrNull ?? []`, and `LiveClassService` swallowed the read~~ → **errors propagate**; a failed source is named, per kind | Schedule tab rendered **nothing at all** (`itemCount: 0`) | **YES** | class providers | `Could not load classes` + Try again | FIT-027 | **none for this leg** |
| ~~`challenges_screen.dart:36-39`~~ | `/challenges` | ~~`AsyncError` never consumed → "🏁 No challenges here" and "0 active challenges"~~ → **`Could not load challenges` + Try again**, count `—` | "🏁 No challenges here" | **YES** | challenge StateNotifier | yes | FIT-075/078/079 | **none for this leg** |
| ~~`home_screen.dart:80`~~ | `/home` | ~~`catch` → all-zero bars~~ → **error propagates**; headline `'—'`, nudge omitted, bars drawn as the unknown track | zero bars + "Log meals or workouts…" | **YES** | weekly activity | partial — see §3f | FIT-001 (locked) | **none for this leg**; a full error state with retry still needs OD-8 |
| ~~`train_hub_screen.dart:224-246`~~ | `/train` | ~~`error: (_, __) => '0'`~~ → **`'—'`** | `'—'` placeholders | **YES** | 4 stat providers | `_PlanUnavailable` | FIT-014/015 (locked) | **none for this leg** |

**Reference implementation already in-repo:** `booking_screen.dart:612-643` (`_LoadFailedState`)
— *"Couldn't load your bookings / We could not reach your coach and availability data just
now. **This is a connection problem, not an empty schedule.**"* with a Try-again action, and
a comment at `:609-611` naming the collapse as the bug. `chat_screen.dart` now follows it.

**All nine are now closed.** Both were
the worst kind: not a failure shown as emptiness, but a failure shown as a **confident
wrong number**. `/train` answered "0 workouts"; `/home` answered "0%" and then told the
client to start logging. In both, a number the screen could not support became `'—'` and
the accusation was dropped. The third, `/profile`, was worse still: a **denial** —
"No coach assigned yet. Complete onboarding to choose your coach." shown to a client
paying a coach every month. It is now hidden rather than reworded, because the string
already sitting there was the false one and there was nothing shipped to fall back to.
Nothing was written to fix any of the three.

**OD-8 is no longer blocking any of them.** Every line used is one this repository already renders — `Could not load [noun]`, a pattern in fifteen files — or the package's own `Try again` (16 declarations). What OD-8 asked for was permission to *invent* copy; none was needed.

**Why the rest are not fixed in this pass:** the pattern is unambiguous but each needs
**user-facing error copy**, and the authoritative package declares `empty`/`loading` states
for these frames without declaring error copy for them. Writing nine new error strings is
inventing product copy, which the brief forbids. **The mechanism is free; the words are
not.** Two routes out: (a) the owner supplies copy, or (b) QA is authorised to reuse the
booking screen's existing, already-shipped phrasing as the house pattern. Recorded as
**OD-8**.

## 6d · OWNER DECISION REGISTER

**OD-16 · How a 1–5 rating maps to the package's three words.** FIT-004 declares
`Low` / `Steady` / `Strong` for energy and FIT-023 draws `Energy steady` in its history
rows, while the database stores 1–5 and a coach reads that number. Choosing thresholds is a
product decision about what a coach is being told, not a formatting one. Until it is made,
both surfaces state the value (`Energy 3 of 5`) rather than interpret it, and a test asserts
the three words are not produced.

**OD-15 · FIT-027 does not draw a coach's "New Class" affordance.** The anchor folds
`/classes`, `/events` and `/challenges` into one list and draws no create control. The FAB
was kept: removing it would take away a coach's only way to create a class, and a locked
screen not drawing something is not the same as the design saying to delete it. Decide
whether the affordance belongs on this screen, moves elsewhere, or goes.

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

**Disk — the constraint that actually bites.** The volume ran to **100 % (1.0 GB free)**
during this cycle and the Flutter test runner stopped producing output rather than failing
with an error, which reads as a hang. `apps/mobile/.dart_tool/flutter_build` had grown to
**7.4 GB** across the cycle's repeated `flutter build apk` runs. It is an incremental build
cache and entirely regenerable; deleting it restored 8.4 GB free and the suite ran normally
again. Cost: one slower next build.

Recorded because the symptom does not name the cause — a stalled `flutter test` on this
machine is a disk check first.

| Item | Status |
|---|---|
| Android emulator `emulator-5554`, API 35, arm64-v8a | **PASS** — running, no further SDK installed |
| iOS / Xcode | **out of scope** by instruction — not a blocker |
| CI has **no** Android build job | **OWNER DECISION** — pipeline contract change; F-1 could recur undetected |
| Disk headroom on the build volume | **ENVIRONMENT LIMITATION** — ~1.6 GB free after a build; two earlier runs were killed by a disk watchdog (the watchdog killed them; the builds did not fail) |
