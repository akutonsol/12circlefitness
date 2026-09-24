# FIT INTERACTION COVERAGE — the measured backlog

**Regenerate with:** `dart tool/fit_backlog.dart <manifest.json> --markdown` from
`apps/mobile`. This file is generated; edit the tool, not the table.

Each route is resolved to the files it is **actually built from**: the screen the router's
builder constructs (skipping wrappers like `PaywallGate`), that screen's imports **two hops**
out within `lib/features` and `lib/core` — which reaches `screen → widget → domain rules` —
`app_shell.dart` for any frame the manifest marks `hasBottomNav`, and `app_top_nav.dart` for
all of them.

## What this measures, and what it does not

An interaction counts as **present** when its label appears in those files, comments
stripped. **One-word labels must appear as a string literal**, not a substring. That is a
text-presence heuristic:

- reasonably strong evidence of **absence**;
- **weak evidence of presence**. Seven false positives have been found and fixed —
  counting comments, resolving a route to a redirect stub, failing on HTML entities,
  matching a word inside an icon constant, resolving an interaction against a *different
  screen's* control, matching a sentence of body copy, and matching a **different scale's**
  word (`Low` from the sleep slider's `Optimal / Good / Low`, against the board's energy
  `Low / Steady / Strong`). Every one: **the tool matches text, and text is not a control.**
- the board's **sample rows** — `Priya Hit 70 kg on the hinge today 2h`,
  `1 Back squat 4 × 6 · 65 kg · rest 120 s` — can only be matched by fabricating that exact
  data. They are a **ceiling**, not a backlog.

A number here is a worklist entry. Nothing here is a closure claim under
`QA_CLOSURE_STANDARD`.

## Why the numbers moved, in both directions

**Up**, because the old ledger measured one file per anchor and a screen is a screen plus
its widgets plus its rules plus its shell. That under-reported five times, each found by
hand: FIT-001 4/9→7/9, FIT-005 4/12→6/12, FIT-028 4/10→5/10, FIT-014 5/12→6/12,
FIT-032 5/11→6/11.

**Down**, because half the manifest is one-word labels (300 of 600; `Back` alone 69 times)
and a bare substring match counted `background` as `Back`. Requiring a string literal moved
the total from 352 to **280** — and took **FIT-018 from 4/4 to 0/4**, because `Easy` and
`Hard` appear nowhere in `lib`. All four were coincidences, and it had been reported
complete.

Both corrections are now reproducible from one command, which is the point.

## Headline

| Measure | Value |
|---|---|
| FIT screens | 110 |
| Route resolved to a screen file | 108 |
| All declared interactions | **284 / 600** |
| **Locked-anchor interactions** | **127 / 179** |
| Locked anchors complete | **11** of 29 |

## Every anchor, by remaining gap

| Anchor | Locked | Covered | Gap | Name | Route |
|---|---|---|---|---|---|
| **FIT-095** | — | 0/15 | 15 | Grocery list — built | `/grocery-list` |
| **FIT-064** | — | 1/12 | 11 | Activity | `/activity` |
| **FIT-080** | — | 1/12 | 11 | Classes hub + schedule | `/classes` |
| **FIT-100** | — | 0/9 | 9 | Action items — what your coach set | `/action-items` |
| **FIT-065** | — | 11/20 | 9 | Community hub — feed | `/community` |
| **FIT-105** | — | 7/15 | 8 | AI Coach — how it speaks, what it knows | `/ai-coach` |
| **FIT-089** | — | 0/7 | 7 | AI nutrition — conversation | `/ai-nutrition` |
| **FIT-054** | — | 4/11 | 7 | Progress · Photos | `/progress` |
| **FIT-071** | — | 0/6 | 6 | Pods hub | `/pods` |
| **FIT-067** | — | 4/10 | 6 | Create post | `/community` |
| **FIT-062** | — | 1/7 | 6 | Notifications | `/notifications` |
| **FIT-066** | — | 3/9 | 6 | Post detail + comments | `/community` |
| **FIT-072** | — | 0/5 | 5 | Pod detail | `/pods` |
| **FIT-104** | — | 0/5 | 5 | AI Coach — the week | `/ai-coach` |
| **FIT-103** | — | 0/5 | 5 | AI Coach — today | `/ai-coach` |
| **FIT-102** | — | 2/7 | 5 | AI Coach — first open | `/ai-coach` |
| **FIT-058** | — | 0/5 | 5 | Habits | `/habits` |
| **FIT-027** | 🔒 | 5/10 | 5 | What's on | `/classes` |
| **FIT-032** | 🔒 | 6/11 | 5 | Coach dashboard | `/coach-dashboard` |
| **FIT-008** | 🔒 | 2/7 | 5 | Intake | `/intake` |
| **FIT-088** | — | 0/5 | 5 | Cancellation — confirm → cancelled | `/class-detail` |
| **FIT-045** | — | 2/6 | 4 | Progress photos | `/intake` |
| **FIT-047** | — | 1/5 | 4 | Coaching mode | `/intake` |
| **FIT-048** | — | 1/5 | 4 | Choose coach | `/intake` |
| **FIT-090** | — | 0/4 | 4 | AI nutrition — a turn that failed | `/ai-nutrition` |
| **FIT-096** | — | 3/7 | 4 | Booking — your calls and open slots | `/appointments` |
| **FIT-031** | 🔒 | 1/5 | 4 | Plans | `/upgrade` |
| **FIT-085** | — | 0/4 | 4 | Events hub | `/events` |
| **FIT-037** | — | 4/8 | 4 | Medical history | `/intake` |
| **FIT-016** | 🔒 | 3/7 | 4 | Workout detail | `/workout-detail` |
| **FIT-014** | 🔒 | 8/12 | 4 | Workouts hub | `/train` |
| **FIT-108** | — | 3/7 | 4 | AI Coach — conversation | `/ai-coach` |
| **FIT-005** | 🔒 | 8/12 | 4 | Connect | `/messages` |
| **FIT-039** | — | 2/6 | 4 | Experience | `/intake` |
| **FIT-003** | 🔒 | 8/12 | 4 | Nutrition | `/meals-dashboard` |
| **FIT-109** | — | 3/7 | 4 | AI Coach — a turn that failed | `/ai-coach` |
| **FIT-110** | — | 0/4 | 4 | AI Coach — coming back | `/ai-coach` |
| **FIT-075** | — | 1/5 | 4 | Challenges hub | `/challenges` |
| **FIT-079** | — | 1/5 | 4 | Challenges — empty + loading | `/challenges` |
| **FIT-044** | — | 5/9 | 4 | Lifestyle | `/intake` |
| **FIT-092** | — | 1/4 | 3 | Meal plan — built | `/meal-plan` |
| **FIT-086** | — | 0/3 | 3 | Event ticket | `event_ticket_screen (unrouted)` |
| **FIT-043** | — | 2/5 | 3 | Weight goal | `/intake` |
| **FIT-107** | — | 1/4 | 3 | AI Coach — a card that failed | `/ai-coach` |
| **FIT-046** | — | 0/3 | 3 | Photo source | `sheet — /intake, /progress` |
| **FIT-023** | 🔒 | 7/10 | 3 | Check-in hub | `/checkins` |
| **FIT-051** | — | 5/8 | 3 | Selection variants | `/intake` |
| **FIT-097** | — | 1/4 | 3 | Booking — before you have a coach | `/appointments` |
| **FIT-056** | — | 1/4 | 3 | Log measurements | `/progress` |
| **FIT-029** | 🔒 | 3/6 | 3 | Profile | `/profile` |
| **FIT-063** | — | 0/3 | 3 | Women's health | `/womens-health` |
| **FIT-004** | 🔒 | 8/11 | 3 | Check-In | `/daily-checkin` |
| **FIT-069** | — | 8/11 | 3 | Community — empty | `/community` |
| **FIT-076** | — | 0/3 | 3 | Challenge detail — active | `/challenge-detail` |
| **FIT-082** | — | 0/3 | 3 | Class — full / waitlist | `/class-detail` |
| **FIT-083** | — | 0/3 | 3 | Class — booked / live / cancelled | `/class-detail` |
| **FIT-098** | — | 0/2 | 2 | Booking — nothing open, and loading | `/appointments` |
| **FIT-050** | — | 4/6 | 2 | Consent | `/intake` |
| **FIT-053** | — | 5/7 | 2 | Progress · Measurements | `/progress` |
| **FIT-055** | — | 0/2 | 2 | Log weight | `/progress` |
| **FIT-091** | — | 14/16 | 2 | Meal plan — set your targets | `/meal-plan` |
| **FIT-028** | 🔒 | 8/10 | 2 | Connect — no coach | `/messages` |
| **FIT-059** | — | 0/2 | 2 | Goals | `/goals` |
| **FIT-101** | — | 0/2 | 2 | Action items — empty, loading, failed | `/action-items` |
| **FIT-087** | — | 0/2 | 2 | Booking sheet — confirm → confirmed | `/class-detail` |
| **FIT-106** | — | 5/7 | 2 | Add to memory | `/ai-coach` |
| **FIT-094** | — | 1/3 | 2 | Grocery list — the two blocked states | `/grocery-list` |
| **FIT-074** | — | 0/2 | 2 | Pods — empty + loading | `/pods` |
| **FIT-081** | — | 0/2 | 2 | Class detail | `/class-detail` |
| **FIT-093** | — | 0/2 | 2 | Meal plan — it didn’t build | `/meal-plan` |
| **FIT-015** | 🔒 | 8/9 | 1 | Workouts — no plan yet | `/train` |
| **FIT-024** | 🔒 | 1/2 | 1 | Check-in detail | `/checkin-detail` |
| **FIT-030** | 🔒 | 5/6 | 1 | Settings | `/settings` |
| **FIT-011** | — | 1/2 | 1 | Sign up | `/signup` |
| **FIT-038** | — | 11/12 | 1 | Injuries | `/intake` |
| **FIT-049** | — | 0/1 | 1 | Generating plan | `/intake` |
| **FIT-077** | — | 0/1 | 1 | Who else is in | `/challenge-detail` |
| **FIT-078** | — | 0/1 | 1 | Challenge — upcoming · completed · expired | `/challenges` |
| **FIT-020** | 🔒 | 4/5 | 1 | AI meal scan | `/log-meal (ai_scan_view)` |
| **FIT-040** | — | 3/4 | 1 | Height | `/intake` |
| **FIT-060** | — | 0/1 | 1 | Score | `/score` |
| **FIT-034** | — | 0/1 | 1 | Intake welcome | `/intake` |
| **FIT-061** | — | 0/1 | 1 | Insights | `/insights` |
| **FIT-084** | — | 2/3 | 1 | Classes — empty + loading + error | `/classes` |
| **FIT-070** | — | 3/4 | 1 | Community — loading + error | `/community` |
| **FIT-026** | 🔒 | 4/5 | 1 | Conversation | `/chat` |
| **FIT-035** | — | 1/2 | 1 | Profile information | `/intake` |
| **FIT-019** | 🔒 | 4/5 | 1 | Log a meal | `/log-meal` |
| **FIT-057** ✅ | — | 5/5 | 0 | Progress · states | `/progress` |
| **FIT-052** ✅ | — | 5/5 | 0 | Progress · Weight | `/progress` |
| **FIT-042** ✅ | — | 2/2 | 0 | Target weight | `/intake` |
| **FIT-073** ✅ | — | 0/0 | 0 | Pods — joined vs not joined | `/pods` |
| **FIT-041** ✅ | — | 4/4 | 0 | Weight | `/intake` |
| **FIT-001** ✅ | 🔒 | 9/9 | 0 | Home | `/home` |
| **FIT-036** ✅ | — | 8/8 | 0 | PAR-Q | `/intake` |
| **FIT-033** ✅ | 🔒 | 5/5 | 0 | Check-in review | `/coach-checkin-review` |
| **FIT-025** ✅ | 🔒 | 1/1 | 0 | Awaiting reply | `/checkin-detail` |
| **FIT-022** ✅ | 🔒 | 1/1 | 0 | Loading & failure | `cross-cutting pattern` |
| **FIT-099** ✅ | — | 0/0 | 0 | Booking handoff | `/booking-handoff` |
| **FIT-021** ✅ | 🔒 | 3/3 | 0 | Entitlement gate | `PaywallGate wrapper (12 routes)` |
| **FIT-018** ✅ | 🔒 | 4/4 | 0 | Session complete | `/active-workout` |
| **FIT-017** ✅ | 🔒 | 2/2 | 0 | Rest & completion | `/active-workout` |
| **FIT-013** ✅ | — | 1/1 | 0 | Set a new password | `/reset-password` |
| **FIT-012** ✅ | — | 2/2 | 0 | Forgot password | `/forgot-password` |
| **FIT-010** ✅ | — | 1/1 | 0 | Splash | `/splash` |
| **FIT-009** ✅ | 🔒 | 1/1 | 0 | Intake complete | `/intake` |
| **FIT-007** ✅ | 🔒 | 1/1 | 0 | Sign in | `/login` |
| **FIT-006** ✅ | 🔒 | 2/2 | 0 | Welcome | `/onboarding` |
| **FIT-002** ✅ | 🔒 | 5/5 | 0 | Active Workout | `/active-workout` |
| **FIT-068** ✅ | — | 0/0 | 0 | Post types | `/community` |
