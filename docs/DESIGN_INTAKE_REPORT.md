# DESIGN INTAKE REPORT — 12Circle Fitness rebuilt screens

**Phase 2 deliverable.** Read-only intake of the external design package. Nothing in the
package was modified; nothing was copied into this repository.

Date of intake: 2026-09-22 · Repository `12circle-fitness`, branch
`chore/qa-environments-secure-ai-backend` @ `5b9ac79`.

---

## 1 · Package inventory — two packages exist, one is authoritative

A machine-wide search found exactly two candidates.

### 1.1 AUTHORITATIVE

| | |
|---|---|
| Source | `~/Downloads/12circle-fitness-new-screens.zip` |
| sha256 | `d4438803deee0984875998fa93c63548fc011eef55d34f5e766510d5fad88d32` |
| Size / date | 1,826,216 bytes · 2026-09-22 19:53 |
| Root | `fitness-handoff/` — **21 files** |
| Identity | `manifest.json` → project `12Circle Fitness`, `handoffVersion` **1.0**, `sourceOfTruth` **design**, `generated` **2026-09-23**, `viewport` **390x844** |
| Status | `DESIGN_HANDOFF.md:4` — **"READY FOR CLAUDE CODE"** |

Extracted read-only for analysis to the session scratchpad, **outside the repository**.

### 1.2 REJECTED — legacy package

`/Users/dmac/Documents/projects/helix-design-references/12circle fitness/fitness-app-board/`
— **8 entries**. Rejected against the criteria in the governing brief §4:

| Required artefact | Legacy package |
|---|---|
| `manifest.json` | **ABSENT** |
| `IMPLEMENT-THIS.md` | **ABSENT** |
| `DESIGN_HANDOFF.md` | **ABSENT** |
| FIT-001…FIT-110 identifiers | **ABSENT** (prose screen names only) |
| `capture-references.mjs` | **ABSENT** |

Its `12Circle Fitness - Complete Board.dc.html` is **byte-identical** to the authoritative
package's board (`edcce7a51d6a0a87…`), so the legacy directory is an **incomplete
extraction of the same design**, not a competing or older design. It carries the design
surface without any of the machine-readable contract or handoff authority.

**RULING: `fitness-app-board/` is REJECTED as implementation authority and is recorded as
LEGACY. It must not be merged, reconciled, or used as visual authority.** No attempt was
made to reconcile the two.

> **Correction of record.** `docs/MOBILE_QA_SWEEP_2026-09-22.md` §20 audited the legacy
> package and concluded integration was blocked because "the package forbids its own
> application." That conclusion was sound reasoning on an incomplete input and is
> **withdrawn**; §21 already records the withdrawal. The "SPECIFICATION ONLY — DO NOT APPLY
> FROM THIS DOCUMENT" banner on `PHASE-2-DESIGN-SYSTEM.md` scopes to that one document,
> and `IMPLEMENT-THIS.md` — absent from the legacy copy — directs implementation and points
> *at* that document for token values.

---

## 2 · Manifest integrity — PASS

Verified programmatically against `manifest.json`.

| Check | Expected (brief §4) | Measured | Verdict |
|---|---|---|---|
| FIT screens | 110 | **110** | **PASS** |
| FIT ids well-formed `FIT-\d{3}` | 110 | **110** | **PASS** |
| Contiguous FIT-001…FIT-110 | yes | **yes** | **PASS** |
| Missing ids | none | **none** | **PASS** |
| Duplicate ids | none | **none** | **PASS** |
| Routes | 50 | **50 declared, 50 unique** | **PASS** |
| Routes referenced by screens | — | **50 distinct** (exact agreement) | **PASS** |
| Tokens | 19 | **19** | **PASS** |
| Icons | 108 | **108** | **PASS** |
| Assets | 6 | **6**, all 6 files present | **PASS** |
| Interactions | — | **600** | **PASS** |
| Gaps | — | **9** (`GAP-01`…`GAP-09`) | **PASS** |
| **Components** | **25** | **`counts.components` = 25, `components` array = 28** | **FAIL** |

### 2.1 The one manifest inconsistency — components 25 vs 28

`manifest.json` declares `counts.components = 25` while its own `components` array holds
**28** entries:

```
CMP-stat CMP-bar CMP-body CMP-fc-card CMP-fc-btn CMP-fc-btn2 CMP-fc-btn--off
CMP-fc-nav CMP-fc-navi CMP-fc-seg CMP-fc-sego CMP-fc-opt CMP-fc-prog CMP-fc-slot
CMP-tap CMP-row CMP-pill CMP-fld CMP-bub-in CMP-bub-out CMP-state CMP-sico
CMP-skel CMP-mic CMP-lbl CMP-cap CMP-note CMP-grp
```

The brief's expected inventory (25) matches the *declared count*, not the array. Three
entries are unaccounted for. Plausibly the three `--modifier`/variant-looking ids
(`CMP-fc-btn2`, `CMP-fc-btn--off`, `CMP-fc-sego`) are variants counted under their base
component — **but that is inference, and the package does not say so.**

**CLASSIFICATION: DESIGN PACKAGE INCONSISTENCY — NOT ESTABLISHED.** Per the brief §5, the
missing information is not invented. This does not block integration: all 28 ids are
present and addressable. It blocks only any claim of "all 25 components implemented",
because the denominator is unresolved.

---

## 3 · Cross-document agreement — PASS

| Pair | Method | Result |
|---|---|---|
| `DESIGN_HANDOFF.md` ↔ `manifest.json` | parsed all 110 inventory rows, compared id/name/route | **110 rows, 110 unique ids, 0 missing, 0 name mismatches, 0 route mismatches** |
| `IMPLEMENT-THIS.md` ↔ `manifest.json` | asserted claims | 29 locked screens · five client tabs · nine gaps — all consistent; `GAP-07/08/09` named as the owner-decision subset of the manifest's 9 |
| Board ↔ `manifest.json` | `<section>` count + name presence | **110 `<section>` elements = 110 screens**; **110/110 screen names present** after HTML-unescaping |

This is unusually clean: the three documents agree on every screen id, name and route.

### 3.1 Board caption is stale — cosmetic

The board's meta strip renders a hardcoded caption:

```
390 × 844   |   88 screens · 18 sections
```

The board itself contains **110** `<section>` elements and the manifest declares
**110 screens / 19 sections**. The caption contradicts its own document.

> **Correction of record.** §21.4 of the QA sweep recorded the "88-vs-110 frame-count
> inconsistency" as a real structural contradiction surviving the package correction. That
> was wrong, and is corrected here: the board **does** carry 110 frames. Only the caption
> string is stale. The two names that appeared absent (`Rest & completion`,
> `Loading & failure`) were `&` vs `&amp;` HTML escaping, not missing frames.

**CLASSIFICATION: DOCUMENTATION DEFECT (cosmetic).** No impact on implementation.

### 3.2 Locked-screen count — RESOLVED, 29

`manifest.json` carries an explicit per-screen `locked` boolean. Counted:
**29 screens `locked: true`**, which agrees exactly with `IMPLEMENT-THIS.md`'s "29 locked
screens". `DESIGN_HANDOFF.md` renders **30** `(locked)` annotations, i.e. one extra
occurrence outside the 110-row inventory table (prose). The machine-readable field is
authoritative. **PASS** — no discrepancy in the data; a single prose annotation is
surplus.

### 3.3 Wave distribution agrees

`DESIGN_HANDOFF.md` §1 declares Approved core 33 · Wave 1 31 · Wave 2 24 · Wave 3 13 ·
Wave 4 9 = 110. The manifest's per-screen `wave` field yields **exactly the same
distribution**. **PASS**.

---

## 4 · Design board integrity

- 466,177 bytes, live HTML/CSS — not images. `IMPLEMENT-THIS.md` §1: *"It is live markup,
  not images — inspect any element for exact values."*
- 110 `<section>` frames at 390×844, 237 `aria-label` attributes.
- **The board carries no `FIT-` identifiers.** Frame↔manifest linkage is by **screen name**
  (110/110 match), not by id. This is a real limitation for automated visual regression:
  a rename on either side silently breaks the mapping. **CLASSIFICATION: LIMITATION.**
- `capture-references.mjs` regenerates `screens/FIT-001.png … FIT-110.png` from the live
  board and "refuses to run if the frame count and the manifest disagree". **Not executed
  during intake** — it writes files and intake is read-only. Required before Visual QA
  (Phase 11) to obtain the baseline.

---

## 5 · Documented gaps — all 9, verbatim classification

| Gap | Type | Substance | QA classification |
|---|---|---|---|
| GAP-01 | ASSET_GAP | No white/single-colour logo; board CSS-inverts the black-on-white repo asset | **BLOCKED** (asset absent) |
| GAP-02 | ASSET_GAP | Coach/member avatars are neutral glyph placeholders | **BLOCKED** (asset absent) |
| GAP-03 | ASSET_GAP | Photography for yoga, pilates, dance, boxing, meditation, split squat, hip thrust, events — Wave 2 placeholders intentional | **BLOCKED** (asset absent, deliberate) |
| GAP-04 | DESIGN_HANDOFF_GAP | Per-interaction destinations not drawn on the board; routed destinations live in the coverage matrix and wave audits, "unlisted ones must be asked" | **OWNER DECISION** when hit |
| GAP-05 | ANIMATION_SPEC_NOT_EXPLICIT | Only three motions specified: 200 ms emphasised transitions, 1400 ms skeleton shimmer (static under reduced motion), 3 s booking-handoff auto-advance | **LIMITATION** |
| GAP-06 | DESIGN_HANDOFF_GAP | **"Tablet and landscape are not designed. Phone widths only."** | **OWNER DECISION** — see §7 |
| GAP-07 | BACKEND_DATA_MAPPING_REQUIRED | AI error states, persistent AI Coach dashboard (Wave 4 Option B), card-level inline failure — states the implementation cannot currently reach | **OWNER DECISION** (named in IMPLEMENT-THIS) |
| GAP-08 | BACKEND_DATA_MAPPING_REQUIRED | Frame 60 Score depicts `ScoreService` (daily composite) under `/score`, which renders `ScoreEngine`. "Locked, unresolved — needs an owner decision." | **OWNER DECISION** (named) |
| GAP-09 | DESIGN_HANDOFF_GAP | Event ticket has no registered route — `event_ticket_screen` is unreachable | **IMPLEMENTATION GAP** — but see correction below |

#### GAP-09 is half right — the screen is unrouted, not unreachable

Verified in this repository:

- **Unrouted: confirmed.** `grep "EventTicket" lib/core/router/app_router.dart` returns
  nothing. There is no `GoRoute`, so the screen has no path and cannot be deep-linked.
- **Unreachable: false.** `lib/features/classes/presentation/events_screen.dart:81` pushes
  it imperatively from an event-card tap:
  ```dart
  onTap: () => Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => EventTicketScreen(event: events[i]),
  ))
  ```
  This is the only navigation to it in the tree.

**The user-facing consequence is therefore navigation inconsistency, not a dead screen:**
one destination bypasses `go_router` entirely, so it has no URL, no deep link, and does
not participate in the router's shell or redirect logic. Recorded as an **IMPLEMENTATION
GAP** with corrected wording. The design package's own phrasing overstates the defect.

---

## 6 · Screen states to be implemented

20 distinct states across the 110 screens. Distribution:

```
default 80 · empty 8 · loading 8 · gate 5 · failure 5 · failed 4 · complete 3
error 3 · expired 2 · paywall 2 · locked 2 · cancel 2 · (8 further states, 1 each)
```

Note `failure`/`failed` and `error` coexist as distinct state names — 12 screens carry a
negative-path state under three different labels. Whether these are three semantics or one
inconsistently named is **NOT ESTABLISHED** from the manifest.

No screen record carries an explicit `BACKEND` marker; backend dependency is expressed
only in prose (GAP-07/GAP-08) and in `IMPLEMENT-THIS.md`'s
`BACKEND_DATA_MAPPING_REQUIRED` instruction. Backend dependency per screen must therefore
be derived during mapping (Phase 3), not read off the manifest.

---

## 7 · GAP-06 resolves an open QA question

`docs/MOBILE_QA_SWEEP_2026-09-22.md` §23.8 recorded a runtime defect: in landscape the
app's first screen (`splash_screen.dart:109`) overflows by 39 px, painting Flutter's
`BOTTOM OVERFLOWED BY 39 PIXELS` stripe across the "Get Started" CTA. The app has **no
orientation lock** — no `setPreferredOrientations`, no `android:screenOrientation` — so
Android rotates it into a layout that was never designed.

**GAP-06 now supplies the design-side evidence: "Tablet and landscape are not designed.
Phone widths only."** The design authority does not cover landscape at any of the 110
frames, all of which are 390×844.

This does not make the decision — locking orientation is product posture — but it removes
the ambiguity: there is no landscape design to implement against, so "support landscape
properly" would mean commissioning design that does not exist.

**OWNER DECISION REQUIRED** — recorded in §8.

---

## 8 · Owner decisions arising from intake

**OD-1 · Landscape posture**
*Question:* lock phone orientation to portrait, or design and support landscape?
*Evidence:* GAP-06 (not designed, phone widths only); all 110 frames 390×844; runtime
overflow at §23.8; no orientation lock in the repo.
*Impact:* one runtime defect today, and an unbounded landscape audit across 91 repo routes
if landscape is to be supported.
*Can continue without it:* yes — all portrait work is unaffected.

**OD-2 · GAP-07 backend states**
*Question:* AI error states, persistent AI Coach dashboard (Wave 4 Option B), card-level
inline failure — the current implementation cannot reach these states.
*Can continue without it:* yes — affected screens implement their reachable states.

**OD-3 · GAP-08 Score semantics**
*Question:* Frame 60 depicts `ScoreService` (daily composite) under `/score`, which renders
`ScoreEngine`. The package calls this "locked, unresolved".
*Can continue without it:* yes — isolated to that screen.

**OD-4 · GAP-09 event-ticket route**
*Question:* what navigation entry should reach `event_ticket_screen`? GAP-04 says unlisted
destinations "must be asked".
*Can continue without it:* yes.

**OD-5 · Component denominator (§2.1)**
*Question:* is the component set 25 or 28?
*Can continue without it:* yes — all 28 are addressable.

---

## 9 · Intake verdict

| Criterion (brief §5) | Verdict |
|---|---|
| Exact package location | **ESTABLISHED** |
| Package identity / version / date | **ESTABLISHED** — handoffVersion 1.0, generated 2026-09-23 |
| FIT-001…FIT-110 present and machine-readable | **PASS** |
| Manifest integrity | **PASS**, except components 25 vs 28 |
| manifest ↔ DESIGN_HANDOFF | **PASS** — 0 mismatches across 110 screens |
| IMPLEMENT-THIS ↔ both | **PASS** |
| Board ↔ manifest | **PASS** — 110 = 110; caption stale |
| Route / component / token / asset counts | **PASS** (components noted) |
| Gaps enumerated | **PASS** — 9, all classified |
| Legacy package rejected | **DONE** |

**THE AUTHORITATIVE PACKAGE IS VALIDATED AND FIT FOR IMPLEMENTATION**, subject to the five
recorded owner decisions, none of which blocks the majority of integration work.

**Next:** Phase 3 — FIT→route→implementation mapping
(`DESIGN_ROUTE_IMPLEMENTATION_MATRIX.md`).
