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

## 7 · Environment

| Item | Status |
|---|---|
| Android emulator `emulator-5554`, API 35, arm64-v8a | **PASS** — running, no further SDK installed |
| iOS / Xcode | **out of scope** by instruction — not a blocker |
| CI has **no** Android build job | **OWNER DECISION** — pipeline contract change; F-1 could recur undetected |
| Disk headroom on the build volume | **ENVIRONMENT LIMITATION** — ~1.6 GB free after a build; two earlier runs were killed by a disk watchdog (the watchdog killed them; the builds did not fail) |
