# 12Circle Fitness Mobile — QA sweep, 2026-09-22

**Repository** `12circle-fitness` · **Branch** `chore/qa-environments-secure-ai-backend` ·
**Commit** `7c2266c0346f6da0e50eba16d5c58fa0a64f0e09` (in sync with `origin`, 0/0)

A full re-verification of the Mobile application's QA gates, run after migration 131
reached QA. This document records what was actually executed, with results. It does not
supersede `WAVE_3A_11_EXECUTION_EVIDENCE.md`, which remains the record for the migration
itself.

**Scope boundary, stated because a sibling workstream was live in the same session:**
this app is **Flutter/Dart**. It has no `@helix/design-system` dependency, no React
Native, no Metro, no npm design-system package — `grep -rn "@helix"` matches zero
JSON/YAML/JS/TS files repo-wide, and `apps/mobile/pubspec.yaml` declares no such
dependency. The `helix` under `apps/mobile/lib/core/helix/` is an **in-repo Dart token
system**, unrelated to the standalone `helix-design-system` package. The sole React
Native trace is a dead `"extraneous": true` entry in the root `package-lock.json`,
residue of an abandoned Expo scaffold with no backing `apps/mobile/package.json`.
Nothing from the Communities/Helix workstream applies here and nothing from it was acted
on.

---

## 1. Gates executed — all green

| Gate | Command | Result |
|---|---|---|
| Static analysis | `flutter analyze` | **0 errors, 0 warnings**, 160 infos |
| Flutter tests | `flutter test` | **819 passed**, 9 skipped |
| API unit | `npm test -w apps/api` | **58 passed** (8 suites) |
| API e2e | `npm run test:e2e -w apps/api` | **6 passed** (2 suites) |
| Production-ref guard | `.github/scripts/check-production-refs.sh` | OK |
| Migration hygiene | `.github/scripts/check-migration-hygiene.sh` | OK — 132 migrations, contiguous 000–131 |
| Edge-function config | `.github/scripts/check-edge-function-config.sh` | OK — 19 functions, `stripe-webhook` the only `verify_jwt=false` |
| I-MIG-03 durability | `migration-durability-guard.mjs` | **PASS (enforcing)** — 0 unrecorded regressions |
| ENV-3 static manifest | `check-migration-manifest.mjs` | OK (see §3 — static half only) |
| Schema contract | `npm run test:contract` | **PASS** — no unknown relation/column outside the 3-entry allowlist |
| QA web build | `flutter build web --dart-define-from-file=dart_defines/qa.json` | **Built** `build/web` |
| Web secret scan | `tool/check_web_build_secrets.sh build/web` | **PASS** — no server secrets, 85 files |
| Web ref allowlist | CI's inline scan | **PASS** — only `eyqtldjqpgpljlqvpowh.supabase.co` present |
| Live security suites | `npm run test:security` | **351/351 across 8 suites** |
| Live AI suites | `npm run test:ai` | **49/49 across 5 suites**, 17/17 characterizations still reproduce |

### Live security detail (QA project `eyqtldjqpgpljlqvpowh`)

D-01 43/43 · D-02 40/40 · D-03 27/27 · 1D 66/66 · 1E 75/75 · 1F 34/34 ·
**3A-10 chat-media 42/42** · **3A-11 identity constraints 24/24**.

Migration 131 re-confirmed live: frontier **131**, `131` ledger row present, **all seven**
objects present.

### Negative controls — 7/7 harnesses PASS

`wrk02` · `ec23` · `uix1` · `nut01` · `int02` · `icom01` · **`i3a11`** — each fails against
its pre-fix tree and passes post-fix, restoring byte-identically.

`supabase/scripts/negative-control.sh` is **ENVIRONMENT-BLOCKED locally** — `initdb` cannot
find a `postgres` binary beside it (the local install is `libpq` only, not a full server).
It is **not** claimed as passing on local evidence; it runs in CI, which supplies the
server.

---

## 2. Failures encountered and repaired

**DEPENDENCY_FAILURE — API suite could not run.** `npm run test:api` failed with
`jest: command not found`; `apps/api/node_modules` did not exist. Repaired with `npm ci`
(the command CI itself uses). No tracked file changed. The suite then passed 58 + 6.
Classification: harness/environment, **not** a product defect.

---

## 3. ENV-3 — declared vs observed divergence (UNRESOLVED)

| | |
|---|---|
| Live QA frontier | **131** (ledger row present, 7/7 objects) |
| `expected_applied.json` declares | `applied_through: "130"`, `pending: {"131": …}` |

`check-migration-manifest.mjs` passes — but only because its own output says *"This is the
STATIC half only: nothing here has looked at a real ledger."*

**The live half DOES exist and DOES catch this.** `supabase/scripts/live-evidence.sh` runs
in CI's `live-qa` job, `QA_DB_URL` **is** provisioned, and CI run `35794428054` reports:

```
PASS L-1  expected migrations missing from the ledger: 0
FAIL L-2  applied but undeclared: 1 — 131
PASS L-3  stale ledger rows (no authored migration): 0
PASS L-4  holes in the applied sequence (000-131): 0
FAIL L-5  ledger rows 132 vs declared expected 131
INFO      authored and PENDING for qa (declared, not applied): 131
          assertions: 3 PASS · 2 FAIL
```

*(Correction of record: an earlier draft of this section asserted the live half was never
implemented and the divergence was invisible to CI. That was wrong, and it was wrong
because it trusted `expected_applied.json`'s own header — "The live half of this contract
… is NOT implemented" — which is stale. CI evidence supersedes it.)*

L-2 and L-5 are the **same two assertions** that commit `de20ea7` recorded moving from FAIL
to PASS when the 130 frontier was reconciled. They now fail again, for 131, for the
identical reason.

Under ENV-3's own rule — *"a version applied without being declared here fails"* — the
declaration is factually behind reality. Reconciling it was explicitly excluded from the
migration-131 authorization and `WAVE_3A_11_EXECUTION_EVIDENCE.md` §14.7 records that it
requires its own authorization. **It remains unreconciled. No file was modified here.**

---

## 4. Design-system conformance — measured, unresolved

`apps/mobile/lib/core/helix/helix_semantics.dart:5-7` states the contract:
*"Components consume ONLY these — never raw hex."*

Measured against the tree:

| Metric | Measured |
|---|---|
| Presentation files under `lib/features/**/presentation/**` | 158 |
| Files reading `context.helix` / `HelixSemantics` | **0** |
| Files importing anything from `core/helix/` | **0** |
| Files with ≥1 non-semantic colour reference | **150 / 158 (94.9%)** |
| Total non-semantic colour references | **3,009** |
| Distinct `Color(0xFF……)` literals in presentation | **252** |
| Files declaring their own private palette class | **20** |
| Design/theme guard test | **none exists** |

Three competing palettes ship concurrently — the Helix brand tier, a legacy `AppColors`
(imported by 52 files though `AppTheme.darkTheme` is never installed), and 20 per-screen
private palettes. Four different brand purples are live at once (`0xFF7C5CFF`,
`0xFF7C3AED`, `0xFFA855F7`, `0xFFB76DFF`), and three background blacks.

Helix is instantiated once in `main.dart` and read by **zero** widgets.

**Not remediated.** Migrating 3,009 references is a design decision and a large refactor,
outside QA-repair scope. Two widget tests additionally hard-assert a hex that is not the
Helix accent (`test/widget/filter_chip_test.dart:90`), so any token migration must
reconcile those tests deliberately rather than incidentally.

---

## 5. Accessibility — measured, unresolved

| Metric | Measured across `lib/` |
|---|---|
| `Semantics(` widgets | **0** |
| `semanticLabel:` | **0** |
| `IconButton`s with neither tooltip nor semantic label | **49 / 49** |
| `GestureDetector` / `InkWell` without semantics | 392 / 7 |
| Hit boxes measurably below 44 pt | **38** |
| Explicit opt-outs of Material's 48 pt minimum (`tapTargetSize: shrinkWrap`) | **8** |
| Tests asserting any accessibility property | **0** |

Smallest hit boxes found include `action_center_screen.dart:191` (32×32),
`meals_dashboard_screen.dart:1146` (32×32), `nutrition_screen.dart:163` (28×36), and two
custom toggles at 48×26. Because these are raw `GestureDetector` + `Container`, Flutter
applies no minimum tap padding — the painted box *is* the hit box.

Two specific defects worth separating from the aggregate:

- `resume_workout_banner.dart:94-97` — an `IconButton` whose
  `padding: EdgeInsets.zero, constraints: const BoxConstraints()` strips its default
  48×48 minimum, leaving an unlabelled control about the size of its 18 px icon.
- `train_hub_screen.dart:701,705` — `_IconBtn` declares a `tooltip` parameter that its
  `build` never uses. The string is accepted and silently discarded, reaching neither a
  `Tooltip` nor the semantics tree. Three call sites pass it believing it does something.

**Not remediated.** Labels are product copy and target sizes change layout; both are owner
decisions, not QA repairs.

---

## 6. Mutation made

**`.github/workflows/ci.yml`** — one step added (+12 lines, 0 deletions, purely additive):

```yaml
- name: 3A-11 — identity constraint guards, pre-fix / post-fix evidence
  run: apps/mobile/tool/negative_control/i3a11_negative_control.sh
```

`i3a11_negative_control.sh` has existed since 3A-11 and passes, but was the **only one of
the seven** negative controls CI never executed — its six siblings are all wired. It needs
no credential, no network and no new job, reusing the Flutter set-up and `fetch-depth: 0`
checkout already present in that job. YAML re-validated after the edit.

**Uncommitted.** No push authorization was given for this repository.

---

## 7. CI

A `workflow_dispatch` run was triggered at this commit (run `35794428054`) because CI had
**never run green here** — the previous run at this same SHA (`34410026228`, 2026-09-09)
failed on `d08`, which could not pass before migration 131 was applied. That run predates
the application and its failure is no longer representative.

Note the triggered run executes the **committed** `ci.yml`, so it does not include the §6
step.

### Result — `35794428054`

| Job | Conclusion |
|---|---|
| Static guards | **success** |
| API — unit + e2e | **success** |
| Flutter — analyze, test, QA web build | **success** |
| Negative control | **success** |
| Live QA suites (security / AI / contract) | **failure** |
| UIX-1 booking e2e | skipped |
| I-WRK-01 live progression | skipped |

Inside the failing job, steps 1–9 all succeeded — including **Live security suite** and
**Live AI suite**, independently corroborating the local 351/351 and 49/49 above. The
**only** failing step is step 10, *Live SQL evidence — FG-1, FG-2, ENV-3 ledger*, and
within it only the two ENV-3 assertions in §3. FG-1 5/5, FG-2a 20/20, FG-2b 15/15 pass.

Two consequences worth separating:

1. The whole CI run is red for **one** reason: the §3 declaration divergence.
2. `uix1-e2e` and `wrk01-live` are gated on `live-qa` and therefore **skipped**. Those two
   gates have still never executed at this commit, and reconciling §3 is what unblocks
   them.

---

## 8. Not verified — stated rather than implied

- **No iOS or Android runtime testing** — see §10, which supersedes an earlier draft of
  this line that claimed no runtime testing at all. The **web** surface was subsequently
  run and rendered; iOS and Android remain untested and are environmentally unavailable.
- **AI features are not verified end-to-end.** The AI suite passes as a *characterization*
  suite and records that **no AI edge function is deployed** (7/7 `NOT_FOUND`, F-J-15).
  Green here means the characterization still holds, not that AI works.
- **Stripe** — no QA test-mode credentials (EB-5); `I-PAY-01` terminal closure stays
  deferred to Wave 6 / K-01. The database arbiter is proven; the webhook replay is not.
- **Edge Function tests** — 19 tests unrunnable, no Deno runtime (EB-8).
- **`live-evidence.sh`** — needs a `QA_DB_URL` database credential that does not exist
  here; FG-1, FG-2 and the ENV-3 live comparison remain uncollected.
- **Gate 6 manual QA matrix** (22 surfaces × 10 conditions) — never prepared or executed
  (EB-9: no UI harness, no device).
- **Production** — not contacted. Production `schema_migrations` has still never been
  dumped or reconciled (Gate 9B.2 / G-09).

---

## 9. Governance documents are stale

`REMEDIATION_PROGRESS.md` is stamped 2026-08-28 and still shows Wave 1 IN PROGRESS with
Waves 2/3A/3B blocked; `MASTER_REMEDIATION_REGISTRY.md`'s last reconciliation is §7.22
(2026-08-31). Neither records the 3A-9 / 3A-10 / 3A-11 outcomes, all three of which have
since landed and been applied to QA. `WAVE_3A_11_EXECUTION_EVIDENCE.md`'s own header still
reads "NOT COMMITTED, NOT APPLIED", contradicted by its own §14.

Updating those boards is ARCH-owned and was not done here.

---

## 10. Runtime verification — web surface (second pass)

*This section supersedes the earlier "no runtime testing" line in §8, which was written
before runtime availability had actually been established rather than assumed.*

### Availability, measured

| Target | State | Evidence |
|---|---|---|
| iOS simulator | **UNAVAILABLE** | `/Applications/Xcode.app` does not exist; only CommandLineTools. `xcrun simctl list devices available` returns no iPhone/iPad. `flutter doctor`: *"Xcode installation is incomplete"*, CocoaPods absent |
| Android emulator | **UNAVAILABLE** | `flutter doctor`: *"Unable to locate Android SDK"*; no `adb`, no emulator binary |
| macOS desktop | listed by `flutter devices`, but unbuildable without Xcode |
| **Chrome (web)** | **AVAILABLE** | `flutter devices` lists Chrome 153; web is a first-class target here (CI builds it; the tree carries web-only sources) |

Neither mobile platform is fixable from inside QA — installing Xcode or the Android SDK is
a multi-gigabyte owner action.

### What was actually run

The `build/web` artifact produced in §1 was served on `127.0.0.1:8799` and loaded in a real
browser, then rendered in headless Chrome for pixel evidence.

**Verified:**

- The app **boots**: `flutter_bootstrap.js` and `main.dart.js` 200, engine initialises
  (`_flutter` defined), `flutter-view` and the glass pane mount.
- **Zero console errors** and **zero failed network requests** across the session.
- All assets resolve 200 — fonts, splash imagery, brand marks.
- **`go_router` works at runtime**: `initialLocation` lands on `#/splash`, and a hash route
  to `#/login` resolves.
- **Two routes render complete, correct UI.** The onboarding/splash screen paints its brand
  ring, hero image, eyebrow, display headline, body copy, primary CTA and secondary
  "Sign In" affordance. `/login` paints "Welcome Back", email and password fields, a forgot
  link, the Sign In CTA, an OR divider, Google and Apple provider buttons, and the Sign Up
  link.
- **No backend egress before authentication** — no Supabase request is issued at rest, and
  no non-QA host was contacted at any point.

**A clipping artifact was observed and is NOT a product defect.** Content appeared cut at
the right edge in headless captures. Cause, measured: `flutter-view` reported
`width: 500px; height: 809px` inside a `414×896` window — *neither* dimension matches, so
headless Flutter was not reading the real viewport. A genuine minimum-width would have
matched the window height. Classified **ENVIRONMENT/HARNESS**. The same limitation appears
in the hosted browser pane, where a hidden pane leaves the view at 0×0 and Flutter never
composites.

**Consequently still unverified at runtime:** responsive layout at specific device widths
(no true 414 px logical viewport was achieved), all interaction, and every authenticated
flow. No credentials were entered.

---

## 11. Second-pass repairs

### 11.1 Product defect repaired — dead `tooltip` parameter

`lib/features/workout/presentation/train_hub_screen.dart` · `_IconBtn`

`_IconBtn` declared `final String tooltip` as a **required** parameter and its `build`
returned a bare `GestureDetector`. The string reached neither a `Tooltip` nor the semantics
tree. Two call sites pass `'History'` and `'Exercise Library'` believing they label the
control; a screen reader announced nothing.

A required parameter that is never read is unambiguously an implementation defect rather
than a design choice, which is why this was repaired while the broader labelling question
in §5 was not. The fix wraps the existing widget in `Tooltip(message: tooltip, …)` —
`Tooltip` carries its message into semantics, so **two previously unlabelled controls are
now labelled using copy that already existed**. No product copy was invented.

The 40×40 hit box remains below 44 pt. That is a layout change and stays an owner decision.

### 11.2 QA guard added — `test/unit/presentation_drift_guard_test.dart`

Three assertions, in the shape the suite's other guards already use:

- **A-G1** — no presentation widget may declare a `tooltip` field it never reads (the
  defect class above), plus a specific assertion that `_IconBtn` carries its tooltip.
- **H-D1** — a **drift ratchet**, not a conformance guard: the 20 files that declare a
  private colour palette are pinned by name, and the test fails on the 21st. It does not
  judge the existing 20. This is the "safe QA-only guard" the design-system question
  permits: it holds the line while D-2 is outstanding, without pre-empting the decision or
  requiring a 3,009-reference migration.

**Both were mutation-tested**, to this repository's own §2 standard. Reverting `_IconBtn`
to its bare-`GestureDetector` form makes A-G1 fail; restoring makes it pass, byte-exactly.

That mutation test earned its keep: the **first** version of A-G1's general scan returned a
false negative, because its "consumed" pattern matched `required this.tooltip` in the
constructor — which is a declaration, not a consumption. The guard was tightened to strip
constructor initialisers before checking, and re-mutated: both assertions now fail pre-fix
and pass post-fix. Recorded because a guard that has never failed proves nothing.

### 11.3 Regression after the change

`flutter analyze` **0 errors, 0 warnings** (175 infos, unchanged). Full suite **822 passed**
(819 + the 3 new guards), 9 skipped. `ec23` and `i3a11` negative controls re-run and still
PASS, restoring the tree byte-identically.

---

## 12. Runtime verification — web, third pass (clipping resolved, routes exercised)

Instrument: headless Chrome 153 driven over the Chrome DevTools Protocol from a
dependency-free Node 22 script (native `WebSocket`; nothing installed). CDP is used
because `Emulation.setDeviceMetricsOverride` sets the **layout viewport** independently of
the OS window — the distinction the previous pass could not make.

### 12.1 The splash-copy clipping — RESOLVED: capture artifact, not a defect

§10 classified the clipping as a harness artifact from a single measurement. That was the
right call but under-evidenced. Measured properly:

| `--window-size` | resulting `flutter-view` |
|---|---|
| 320×900 | **500**×813 |
| 390×900 | **500**×813 |
| 430×900 | **500**×813 |
| 768×900 | 768×813 |
| 1440×900 | 1440×813 |

`flutter-view` tracks the window exactly at 768 and 1440 but **floors at 500** below it.
Two candidates remained — an app min-width (a real defect) or Chrome's own minimum window
width — and `--window-size` cannot separate them, because Chrome will not create a window
narrower than ~500 px.

With a true viewport override the ambiguity disappears:

| viewport | `window.innerWidth` | `flutter-view` | `document.scrollWidth` | overflow |
|---|---|---|---|---|
| 320 | 320 | **320**×900 | 320 | none |
| 390 | 390 | **390**×900 | 390 | none |
| 430 | 430 | **430**×900 | 430 | none |
| 768 | 768 | 768×900 | 768 | none |
| 1024 | 1024 | 1024×900 | 1024 | none |
| 1440 | 1440 | 1440×900 | 1440 | none |

`flutter-view` tracks the viewport exactly at every width, and `scrollWidth == innerWidth`
at every width — **zero horizontal overflow anywhere in 320–1440**. The 500 px floor was
Chrome's minimum window width and never an app constraint.

**Classification: B — viewport/capture artifact.** Confirmed visually: at 320 px the splash
body copy renders complete ("…built to push you through all 12 weeks."), the headline wraps
to two lines, and the CTA is correctly inset. The login screen at 390×844 likewise renders
whole — "Forgot password?", both provider buttons, and the footer link all intact.

*The responsive-behaviour item listed as unverified in §10 is therefore now VERIFIED at six
widths, and this supersedes that line.*

### 12.2 Route sweep — 16 routes at 390×844

Each route was loaded from a clean page load; renders are compared by SHA-256 of the
screenshot, not by byte length alone.

- **Public routes render distinctly**: `/onboarding` (205,249 B), `/login` (93,284 B),
  `/signup` (111,667 B), `/forgot-password` (89,137 B) — four different screens.
- **Auth guard VERIFIED LIVE.** `/home`, `/workouts`, `/progress`, `/nutrition`,
  `/messages`, `/settings`, `/profile`, `/train`, `/community` — all nine are
  **pixel-identical** to `/login` (`3b60b908…`). Unauthenticated access to a protected
  route lands on sign-in.
- **REL-3 VERIFIED LIVE.** `/qa-center` and `/mie-debugger` are also pixel-identical to
  `/login`. `flutter build web` is a release build, so `kQaToolingEnabled` is false and the
  debug routes are not registered. This is the runtime counterpart of the static assertion
  in `release_route_gate_test.dart`.
- **Unknown route degrades gracefully** — `/this-route-does-not-exist` lands on sign-in. No
  crash, no blank screen, no unhandled exception.
- Across all 16: **0 console errors, 0 failed network requests, 0 horizontal overflow.**

### 12.3 Interaction — verified

- **Password visibility toggle works.** Clicking the eye control on `/login` changes the
  render (93,284 B → 93,400 B).
- **Navigation by real user input works.** Clicking "Sign Up" drives the route to
  `#/signup`, and the resulting render is **111,667 B — exactly the `/signup` fingerprint**
  from the sweep above. Input, routing and rendering are consistent end to end.

### 12.4 Authenticated UI runtime — BLOCKED (harness), not a product finding

A QA fixture session was minted through the auth API — the same path
`supabase/tests/security/lib.mjs` uses — and injected into `localStorage` so the UI could be
driven authenticated **without typing credentials into a form**. Three key/format
combinations were tried (`flutter.supabase.auth` and `supabase.auth`, wrapped and raw);
the compiled bundle's own key strings (`"supabase.auth"`,
`"supabase.auth.token-code-verifier"`) were read to inform them. The app did not restore
the session and continued to route to `/login`.

Classification **HARNESS_FAILURE**. It is not evidence of a product defect: the injection
simply does not reproduce `supabase_flutter`'s exact persistence format, and PKCE
code-verifier state is likely also required.

What this leaves genuinely unverified is **authenticated UI rendering on web**. Authenticated
*authorization* behaviour is not unverified — the live suites in §1 sign in as these exact
fixtures and exercise RLS, RPC execution and authorization boundaries across 351 assertions.

The remaining route to authenticated UI would be typing the fixture password into the login
form. That was deliberately not done.

---

## 13. D-1 / ENV-3 — governance investigation, and why it was NOT reconciled

A forensic read of every governing text was performed specifically to answer: does this
repository's own governance record **explicitly authorize** changing
`qa.applied_through` 130 → 131 and clearing `pending`, now that 131 is applied and verified?

**Finding: no document states a general rule either way.** There is no migration-application
checklist anywhere in `docs/` that contains the step at all. Every governing text is
instance-specific — about 128, or 130, or 131, never about the class.

**Evidence that it is a procedural consequence (would authorize):**
- `expected_applied.json:11-12` — *"The frontier can only move when reality and intent move
  together."* Both have now moved.
- The 131 `gate` field names exactly one releasing condition — application under separate
  explicit authorization — and that condition **has fired**.
- `fb36f18` — *"This commit reconciles the declaration to the state that application
  produced"* … *"The declaration is moved AFTER the application, never before it."*
- `docs/decisions/DEC-3A-10_CHAT_MEDIA_STORAGE_CONTRACT.md:737` — *"`expected_applied.json`
  **must** move `applied_through` to 130 — the `352ee68` precedent."*
- None of the four precedent commits (`c66f575`→124, `fb36f18`→128, `352ee68`→129,
  `de20ea7`→130) cites an owner ruling for the frontier move itself.

**Evidence that it requires a discrete owner act (withholds authorization):**
- `WAVE_3A_11_EXECUTION_EVIDENCE.md:609-610` — the most recent and most on-point sentence in
  the repository: *"Reconciling `applied_through` to `131` and clearing `pending` **requires
  its own separate authorization**."*
- `WAVE_3A_11_READINESS_AUDIT.md:404-406` — *"**Never, at any step:** … editing
  `expected_applied.json` for any reason but steps 1 and 3"*. No enumerated step covers a
  131 frontier move. The default posture toward this file is prohibition-with-exceptions.
- `WAVE_3A_11_RULING_VALIDATION.md:232` — *"Separate authorization? **Yes, for both.**"*
- Four consecutive application authorizations each explicitly carved this file out of scope.

**Verdict: explicit authorization is ABSENT.** Ambiguity pointing both ways is not explicit
authorization, and authorization may not be inferred from the change being obviously
correct. **`supabase/expected_applied.json` was NOT modified.**

**One asymmetry the owner should know, because it makes the decision cheap:** no text
anywhere grants anyone discretion to *decline* this reconciliation. Every text treats the
post-application declaration as a state the file *should* reach. What is disputed is **who
may perform the edit under which grant**, not whether the end state is correct. This reads
as a procedural-authorization requirement rather than a substantive re-decision — but the
repository never says so, and that gap was not filled here.

**Status: OWNER-AUTHORIZED GOVERNANCE BLOCKER.** It remains the sole cause of CI red, and it
keeps `uix1-e2e` and `wrk01-live` skipped.

---

## 14. Accessibility — runtime semantics tree (corrects §5)

§5 counted source: 0 `Semantics` widgets, 0 `semanticLabel`, "49/49 `IconButton`s
unlabelled". Static counting was the wrong instrument, and the figure overstated the
problem. Flutter builds a semantics tree automatically from `Text` descendants, so a
control with a text child **is** announced without any `semanticLabel` in source.

Measured at runtime by activating Flutter's own `flt-semantics-placeholder`
("Enable accessibility") and reading the resulting `flt-semantics` tree — i.e. what a screen
reader actually consumes. On `/login`: 17 nodes, 13 carrying role/label/text.

**Text-bearing controls ARE labelled.** "Forgot password?", "Sign In", "Apple",
"Don't have an account? Sign Up" all expose accessible names from their child text.
"Google" announces as "G Google" — awkward, not inaccessible.

**The genuine defect class is icon-only controls**, and it is small and specific:

| Route | buttons | unlabelled | size |
|---|---|---|---|
| `/onboarding` | 2 | **1** | 56×56 |
| `/login` | 6 | **1** | **20×20** |
| `/signup` | 9 | **1** | **20×20** |
| `/forgot-password` | 3 | **1** | **22×22** |

**DEFECT (P3), evidence-backed:** the password-visibility toggle on `/login`, `/signup` and
`/forgot-password` is an icon-only control that announces only as "button" with no name, at
**20×20 / 22×22** — less than half the 44 pt minimum on both axes. It is simultaneously
unlabelled and undersized, and it is a control users must operate to check a password they
typed.

**Not fixed, deliberately.** Labelling it requires copy ("Show password" / "Hide password");
`grep` confirms no such string exists anywhere in `lib/` to reuse, so supplying one would be
inventing product copy. Resizing it changes layout. Both are owner calls. This is now a
**single, precisely located fix** rather than the vague "49 controls" of §5.

Also measured: several text links sit at 20–22 px height (`"Forgot password?"` 122×20,
`"Don't have an account? Sign Up"` 219×20, `"I agree to the Te…"` 342×22). Below the 44 pt
guideline on the vertical axis. Recorded as **OBSERVATION** — inline text links are a
widespread convention and calling them defects would be a product judgement.

---

## 15. Network-failure and offline runtime

Driven over CDP against the served QA build.

| Scenario | Result |
|---|---|
| Supabase host blocked (`Network.setBlockedURLs`) | App boots and renders `/login` identically to healthy (93,284 B). **0 JS errors, 0 unhandled exceptions.** |
| Fully offline (`emulateNetworkConditions offline:true`) | `readyState=complete`, 0 errors |
| Network restored | `/login` renders normally — clean recovery |

**Honest limitation, stated rather than glossed:** `netFails` was **0** in the blocked
scenario — because the unauthenticated surface issues **no backend request at all** (already
established in §10). Blocking the host therefore never exercised an error path. This
evidences **graceful boot and render without a backend**; it does **not** evidence
backend-error-state handling. That would require an authenticated session, which is
BLOCKED per §12.4.

Error-contract coverage does exist statically and passes: `ui_error_surface_guard_test.dart`
(EC-G6…G8) and `error_contract_guard_test.dart` are green in the 822-test suite.

---

## 16. D-1 / ENV-3 — AUTHORIZED AND RECONCILED

**Authorization.** The owner explicitly authorized the two-line reconciliation, scoped to
`supabase/expected_applied.json` only, with migrations, schema, production, CI logic,
application code, other declarations, and commit/push all excluded. This supersedes §13's
"authorization absent" verdict — the missing grant was supplied.

### 16.1 Pre-change state, re-confirmed

Live QA: frontier **131**, `131` ledger row present, **`132` ABSENT**, 132 ledger rows.
Declaration: `applied_through: "130"`, `pending: ["131"]`, `excluded: []`.

### 16.2 The change — exactly two fields

```diff
-      "applied_through": "130",
+      "applied_through": "131",
       "excluded": [],
-      "pending": {
-        "131": { "reason": …, "gate": … }
-      }
+      "pending": {}
```

`+2 / −7`, one file. `ref`, `name`, `excluded`, and the entire `_` header block are
untouched. This is the same shape as the `fb36f18` precedent (frontier bumped, pending
cleared).

### 16.3 Validation

- **JSON valid**; parses to `applied_through: 131`, `pending: {}`, `excluded: []`.
- **ENV-3 static** (`check-migration-manifest.mjs`): **OK** — *"frontier 131 (expected
  applied: 132 version(s), 000–131) · authored, PENDING (none) — the tree and this
  environment's frontier agree."*
- **ENV-3 LIVE** — CI's own generator (`supabase/scripts/env3-live-check.mjs --env qa`)
  executed against the live QA ledger:

```
=== ENV-3 LEDGER (qa) ===
PASS L-1  expected migrations missing from the ledger: 0 — —
PASS L-2  applied but undeclared: 0 — —
PASS L-3  stale ledger rows (no authored migration): 0 — —
PASS L-4  holes in the applied sequence (000-131): 0 — —
PASS L-5  ledger rows 132 vs declared expected 132
INFO authored and PENDING for qa (declared, not applied): (none)
```

**L-2: FAIL → PASS. L-5: FAIL → PASS.** L-1/L-3/L-4 unchanged at PASS. The two assertions
that `de20ea7` recorded flipping green for 130 have now flipped green for 131, for the
identical reason. (The surrounding `P0001` is the script's own `RAISE`-to-roll-back
reporting path, which `run_suite` consumes — not an error.)

- **Ledger unchanged by the edit**, as a declaration-only change must be: frontier still
  **131**, `132` still **ABSENT**, 132 rows, all **7** migration-131 objects present.
- **No migration file touched**; `git status supabase/migrations/` clean.

### 16.4 CI — why the job is not re-run here

The edit is **uncommitted**, and commit/push were explicitly excluded from this
authorization. CI builds the committed tree, so triggering a run now would execute the
*old* declaration and reproduce the identical `L-2`/`L-5` failure — an expensive run with
unchanged inputs and misleading output. It was therefore not triggered.

The evidence above is not a substitute of lesser kind: it is **CI's own generator against
the same live database**. What remains un-exercised is the CI *job*, not the assertion.

### 16.5 Downstream jobs — still NOT_RUN

`uix1-e2e` and `wrk01-live` are `needs: [live-qa]`, so they stay skipped until `live-qa`
passes **in CI**, which requires the commit. They also cannot be run locally: both default
to `PROBE_DEVICE=linux`, and the only devices here are `macos` (needs Xcode — not
installed) and `chrome` (needs chromedriver — not installed). Installing either is a
system-level toolchain change outside QA authority.

**Status: NOT_RUN — blocked on commit authorization, and environment-blocked locally.**

---

## 17. D-4 authorized — committed, pushed, CI fully green

Recorded retrospectively, following the `1b2fe57` precedent: a run's result cannot be
named by the commit that causes it.

### 17.1 Commits

| | |
|---|---|
| `ea1c6dd` | `chore(ENV-3): reconcile QA migration frontier to 131` — **one file**, `supabase/expected_applied.json`, +2/−7 |
| `55ae5f0` | `test(QA): wire the dormant 3A-11 negative control, fix a dead tooltip, add drift guards` — 4 files, +831/−9 |

Split along the repository's own precedent (`352ee68` / `fb36f18` / `de20ea7`): a frontier
move after application is its own commit. Pushed to
`origin/chore/qa-environments-secure-ai-backend`; remote HEAD `55ae5f01`.

Deliberately **not** included: `docs/WAVE_3A_11_EXECUTION_EVIDENCE.md` and the three
untracked audit documents, per the authorization's file list.

### 17.2 CI run `35799461932` — ALL SEVEN JOBS SUCCESS

| Job | Result |
|---|---|
| Static guards | **success** |
| API — unit + e2e | **success** |
| Flutter — analyze, test, QA web build | **success** |
| Negative control | **success** |
| Live QA suites (security / AI / contract) | **success** |
| **I-WRK-01 — live progression read path** | **success** ← never executed before |
| **UIX-1 — booking surface end-to-end** | **success** ← never executed before |

This is the **first fully green run this branch has ever produced.**

### 17.3 ENV-3, confirmed in CI

`live-qa` step 10, *"Live SQL evidence — FG-1, FG-2, ENV-3 ledger"* — **success**. That is
the exact step that failed in run `35794428054` with `L-2`/`L-5`. CI independently
confirms §16.3's local result.

### 17.4 The newly-wired negative control, confirmed in CI

`negative-control` step 12, *"3A-11 — identity constraint guards, pre-fix / post-fix
evidence"* — **success**. All seven harnesses now execute in CI: `M-1/2/3`, `WKT-204`,
`EC-23`, `UIX-1`, `I-NUT-01`, `I-INT-02`, `I-COM-01`, `3A-11`.

### 17.5 The two first-ever jobs — results verified, not assumed

Job conclusions were not taken as evidence; the step output was read.

**I-WRK-01** — `🎉 3 tests passed` · `RESULT: PASS — I-WRK-01 VERIFIED LIVE legs both
established.` The `❌ pre-fix leg … (failed)` line in the log is the **required** pre-fix
failure of a negative control, followed by `✅` on the restored tree. Fixture hygiene:
`WRK01-MARK CLEANUP verified remaining=0`, and CI's own independent re-check
`fixture WRK01-PROBE-35799461932-1 — rows remaining after cleanup: 0`.

**UIX-1** — `UIX1-MARK ASSERT-ALL PASS` · `🎉 2 tests passed` · `RESULT: PASS` ·
**`Evidence class: UIX-1 VERIFIED END-TO-END — real route, real PaywallGate, real
surface`**. The booking surface was reached through the real `/appointments` route, passed
the real paywall, and rendered the real coach. Fixture retirement proven:
`run-tagged availability remaining: 0 ; active relationships remaining: 0`.

**Carried forward honestly — UIX-1's own self-declared gap:**
> `NOT ESTABLISHED: the failure path (A4). See the probe header — _load() returns at
> uid == null before its try/catch, so _LoadFailedState cannot [be reached]`

The harness says one path is not established. That is **not** a green result for A4 and is
not counted as one.

**No fixture leaked in either job** — the failure mode that blocked migration 131 in §13
did not recur.

---

## 18. Post-green closure sweep

Run against `6cc1ff6a`, CI `35799894916` (7/7 success). Nothing below re-runs completed
work; each item adds coverage or examines a state that could have changed.

### 18.1 CI forensics — three caveats a "passed" summary would have hidden

**(a) The security roll-up is 350/350 here, not the 351/351 recorded in §1.** The difference
is one *conditional* assertion, not a regression. `d02-role-escalation.mjs:137-144`:

```js
if (pub.status === 429) {
  console.log('  SKIP  public /auth/v1/signup — project email rate limit (429); …');
} else {
  check('public signup cannot mint an admin', …);
}
```

CI logged that SKIP. Re-running `d02` locally now reproduces it — **39/39, still rate-limited**.
So the suite's count is **non-deterministic (39 or 40 for D-02, 350 or 351 overall)**
depending on Supabase's email rate limiter. Both figures were correct for their moment;
§1's "351/351" should be read as 350–351. The underlying invariant is not uncovered — the
harness notes *"the same handle_new_user() trigger is covered above."*
Classification: **ENVIRONMENT_BLOCKED (intermittent)**.

**(b) Two `##[error] N tests passed, M failed` lines appear inside green jobs.** These are
the negative controls' **required** pre-fix legs — e.g. `❌ WKT-204 … (failed)` immediately
followed by `✅` and `restore: committed implementation`. Working as designed.

**(c) Skip inventory, complete:** 9 Flutter skips, all
`billing_entitlement_contract_test.dart` K/OPEN executable specifications (K-01…K-12,
K-ENV-1) for findings that remain open on Stripe test mode (EB-5) · 1 AI section, J-03E
writes · 1 security assertion, (a) above.

**J-03E was deliberately NOT run.** `j03-engine-boundary.mjs:89-101` gates it behind
`AI_ALLOW_WRITES=1`, and its own comment states **"decision_traces rows are not
client-deletable."** Running it would add one characterization assertion at the cost of
permanent uncleanable residue in shared QA — the exact failure mode that blocked migration
131 in §13. Not run, by choice.

### 18.2 Authenticated UI runtime — §12.4 SUPERSEDED

§12.4 recorded authenticated UI runtime as harness-blocked. That was true locally and is
now **superseded**: the sanctioned mechanism already exists and already passed.

`integration_test/uix1_booking_e2e_test.dart:121-132` signs in for real —
`_db.auth.signInWithPassword(email, password)` against the fixture identities, asserting
`currentUser != null` — then drives the real app. CI logged `UIX1-MARK AUTH ok
client-session=true`, `ROUTE navigated=/appointments`, `A1 surface-reached=true`,
`A2 coach-rendered=true`, `A3 ready-state=true`.

**Authenticated UI rendering is VERIFIED — in CI, on Linux desktop.** It remains
unavailable *locally* (no Xcode for macOS desktop, no chromedriver for web), which is an
environment limit, not a coverage gap.

### 18.3 UIX-1 A4 — NOT_ESTABLISHED, and it is a TEST limitation, not a product defect

A4 is not an oversight. The probe header says so verbatim
(`uix1_booking_e2e_test.dart:50-55`):

> `A4 IS NOT ASSERTED, AND THAT IS A RECORDED LIMITATION, NOT AN OVERSIGHT.`
> `_LoadFailedState` cannot be reached honestly from here: `_load()` returns at
> `uid == null` before its try/catch (booking_screen.dart:50), so an unreachable URL yields
> `noCoach`, not `error`. Reaching it would need a production-code edit, an RLS change, or a
> mock — all forbidden by the owner ruling.

**What A4 would assert:** the inverse of A3's third negative — that when the authoritative
read genuinely fails, the surface renders `_LoadFailedState` ("Couldn't load your bookings"
+ Try again) rather than the confident empty answer `_NoSlotsState`. That false success is
the exact defect this workstream exists to prevent.

**`_LoadFailedState` is NOT dead code** — three independent pieces of evidence:
1. `app_router.dart:180-198` redirects unauthenticated users to `/login`, and
   `/appointments` sits behind `PaywallGate`, so in production `uid` is non-null and the
   `try`/`catch` **is** the live path. The harness's blocker and production's behaviour are
   inverted.
2. The catch has demonstrably executed in production: PostgREST answered `PGRST200` for the
   `coach:coach_id(…)` embed, and `_load()`'s catch turned it into a confident "no slots" —
   the original M-03 defect. UIX-1 changed what that catch *renders*.
3. `_LoadFailedState(onRetry: _load)` plus the AppBar refresh shown in every state except
   `loading`/`noCoach` is an intended live re-entry after a transient outage.

**Structural cause — a testability defect, recorded not fixed:**
`booking_screen.dart:26` — `final _db = Supabase.instance.client;`. The screen reaches the
network through a global singleton inside a `StatefulWidget`, so there is **no seam to fail**.
Every error state in this repo that *is* tested sits behind a Riverpod provider — compare
`test/widget/active_workout_hydration_test.dart:21-59`, which does exactly the A4-shaped job
for another screen via `activeWorkoutRestorationProvider.overrideWith(...)`, with no backend
and no production access. A4 becomes trivially testable the moment that read moves behind a
provider. Moving it is a product change and was not made.

**One candidate path exists that touches neither production code, RLS, nor a mock:** reach
`ready`, break host reachability on the CI runner, then tap the AppBar refresh — `uid` stays
non-null from the cached session, the PostgREST call fails, and the catch renders
`_LoadFailedState`. This is *environment-level fault injection*. It is implemented nowhere
in the repo, and the owner ruling quoted in the header does not enumerate it in either
direction. **OWNER DECISION** — not assumed, not implemented.

### 18.4 Error / empty / loading coverage — measured

| Measure | Count |
|---|---|
| Presentation files | 158 |
| Using `.when(` | 39 — **all 39 declare both `error:` and `loading:`** |
| Bypassing `.when()` via `.valueOrNull` | **41** (collapses an error to `null` beneath any declared arm) |
| `error: → SizedBox/Container` swallows | **16** |
| Tests rendering loading/empty/error as distinct outcomes | **1** (`active_workout_hydration_test.dart`, WKT-112) |

Branch *presence* is 100%; the real hole is `.valueOrNull`. All three ratchets are green and
already pin these: EC-G7 at baseline **16**, EC-G8 at **134**, EC-G5 at **234**, each checked
bidirectionally so a fix must lower the baseline.

Two findings worth recording:
- **A sanctioned-swallow list exists, but only for the service layer.**
  `docs/QA_WORKSTREAM_B_ERROR_CONTRACT_REPORT.md` §5 enumerates exactly five allowed cases.
  There is **no presentation-layer equivalent**, so all 16 `error: → SizedBox` branches are
  unsanctioned by contract and held only by EC-G7's numeric ratchet. **OWNER DECISION**
  whether to sanction or remediate them.
- **`EC-G6` deliberately pins a live defect by name** —
  *"DEFECT: Train hub renders the failure as 'nothing to resume'"* — with the instruction to
  delete the test when the arm gains a retry. It is a defect marker, not a passing contract.

### 18.5 Accessibility — the label question is settled as a product decision

`semanticLabel` appears in **0 files** across `lib/`; `tooltip:` in **3** (one of which is
`'Filter'`; the other two are the `_IconBtn` strings §11.1 wired). There is **no established
accessibility-label convention and no reusable copy** anywhere in the repository. Labelling
the password-visibility toggle therefore requires inventing product copy, which QA will not
do. **OWNER DECISION**, unchanged from §14.

### 18.6 Security regression — scoped, not repeated

The three commits touched `ci.yml`, `train_hub_screen.dart`, a new test, the evidence doc,
and `expected_applied.json`. **No migration, Edge Function, auth, policy, `app_env`,
`config.toml` or `dart_defines` file was touched**, so nothing could invalidate the security
evidence — and that evidence is current regardless: the full live suite ran **in CI at
`6cc1ff6a`**. Prod-ref guard re-run on the current tree: OK, both arms.

### 18.7 Fixtures

Independently re-verified after all CI activity: conversations **1** (the pre-existing
25-message survivor), duplicate participant pairs **0**, payments **0**, session credits
**0**, p1-victim cycle logs **0**. Both CI probes proved their own removal
(`UIX1-MARK CLEANUP verified availability=0 active-relationships=0`;
`WRK01-MARK CLEANUP verified remaining=0`, plus CI's independent re-check). **No fixture
leaked, by me or by CI.**

---

## 19. Android runtime gate — pursued to a hard, quantified blocker

§10 recorded Android as unavailable on the strength of `flutter doctor` alone. That was
under-investigated. This section supersedes it with an actual attempt.

### 19.1 No sanctioned tooling existed to reuse

Searched exhaustively before building anything: no `adb`/`emulator`/`sdkmanager`/`avdmanager`
anywhere under `$HOME`, no `cmdline-tools`, no Android Studio, no SDK in any standard
location, `~/.android` holding only `analytics.settings` and `cache` (no `avd/`),
`apps/mobile/android/local.properties` carrying only `flutter.sdk=` with **no `sdk.dir`**,
and **no Android job, script or documented emulator workflow anywhere in the repository or
its CI**. There was nothing to reuse, so the toolchain had to be built.

### 19.2 Toolchain installed from nothing — this part succeeded

| Component | Version | Result |
|---|---|---|
| cmdline-tools | 12.0 | installed (Google official zip; the Homebrew cask fails on this machine with `Failed to quarantine … xattr: No such file: …kotlin-compiler-mvn.jar`, and `--no-quarantine` was removed in Homebrew 7) |
| platform-tools | 37.0.1 | installed — `adb` 1.0.41 working |
| platforms;android-35 | 2 | installed |
| emulator | 37.1.11 | installed |
| system-images;android-35;google_apis;arm64-v8a | rev 9 | installed (1.78 GB, direct from `dl.google.com` after `sdkmanager` failed twice with a bare `Warning: Failed to download package!`) |
| SDK licences | — | 14 accepted |
| AVD `qa35` | Pixel 6, API 35, arm64-v8a | **created**, and `flutter emulators` lists it: `qa35 • qa35 • Google • android` |

### 19.3 Boot blocked — disk, with exact numbers

```
FATAL | Not enough space to create userdata partition.
        Available: 2201.36 MB at ~/.android/avd/qa35.avd, need 7372.80 MB.
```

The 7,372.80 MB figure is a fixed emulator pre-flight requirement, **not** the configured
partition size: it was reproduced after setting `disk.dataPartition.size = 1600M`, removing
the 512 MB SD card and passing `-partition-size 2048`. Two boot attempts, same FATAL.

Disk was also reclaimed along the way — Homebrew caches pruned twice, the failed cask
download removed, the QA web build deleted, temp logs cleared — which is why free space
*rose* from 942 MiB to ~2.2 GiB mid-run. It is still **≈5.1 GB short**.

**ANDROID: ENVIRONMENT_BLOCKED — insufficient disk, ~5.1 GB short of the emulator's
7.2 GB pre-flight requirement.** This is not a tooling gap any more: the SDK, system image
and AVD are all installed and staged, and the gate should clear on the next attempt once
~5–6 GB is free. Freeing that means deleting data this QA pass does not own.

Not attempted, deliberately: installing Xcode (explicitly excluded by the owner), and
deleting user data to make room.
