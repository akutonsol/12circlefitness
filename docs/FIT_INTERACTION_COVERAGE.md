# FIT INTERACTION COVERAGE — the measured backlog

**Regenerate with:** `dart tool/fit_backlog.dart <manifest.json> --markdown` from
`apps/mobile`. This file is generated; edit the tool, not the table.

Resolved against the files each route is **actually built from** — the screen the router's
builder constructs (skipping wrappers like `PaywallGate`), that screen's own imports one hop
out, which picks up `widgets/…` and `domain/…`; `app_shell.dart` for any frame the manifest
marks `hasBottomNav`; and `app_top_nav.dart` for all of them.

## What this measures, and what it does not

A declared interaction counts as **present** when the first three words of its label appear
in the implementing files, with comments stripped. That is a **text-presence heuristic**:

- reasonably strong evidence of **absence**;
- **weak evidence of presence**. Six false positives have been found and fixed so far —
  counting comments, resolving a route to a redirect stub, failing on HTML entities,
  matching a word inside an icon constant, resolving an interaction against a *different
  screen's* control, and matching a sentence of body copy. Every one is the same thing:
  **the tool matches text, and text is not a control.**
- the board's **sample rows** — `Priya Hit 70 kg on the hinge today 2h`,
  `1 Back squat 4 × 6 · 65 kg · rest 120 s` — can only be matched by fabricating that exact
  data. They are a **ceiling**, not a backlog.

A number here is a worklist entry. Nothing here is a closure claim under
`QA_CLOSURE_STANDARD`.

## Why the previous numbers were wrong

The old ledger measured **one file per anchor**. A screen is a screen, the widgets it
composes, the rules those widgets call, and the shell that draws its nav. That under-reported
five times before the resolver existed, each found by hand, one anchor at a time:

| Anchor | Recorded | Actual |
|---|---|---|
| FIT-001 | 4/9 | 7/9 (before the nav work; **9/9** after) |
| FIT-005 | 4/12 | 6/12 |
| FIT-028 | 4/10 | 5/10 |
| FIT-014 | 5/12 | 6/12 |
| FIT-032 | 5/11 | 6/11 |

The resolver reproduced the redirect-stub defect on its own first run — `/meals-dashboard`'s
builder returns `PaywallGate(child: MealsDashboardScreen())`, so taking the first widget
after `=>` resolved the route to the **gate**. Wrappers are now skipped, and the four anchors
that are sub-surfaces of a route rather than screens of their own (FIT-019, FIT-020,
FIT-021, FIT-022) are named explicitly rather than guessed.

## Headline

| Measure | Value |
|---|---|
| FIT screens | 110 |
| Route resolved to a screen file | 108 |
| All declared interactions | **352 / 600** |
| **Locked-anchor interactions** | **128 / 179** |
| Locked anchors complete | **11** of 29 |

## Every anchor, by remaining gap

| Anchor | Locked | Covered | Gap | Name | Route |
|---|---|---|---|---|---|
| **FIT-095** | — | 1/15 | 14 | Grocery list — built | `/grocery-list` |
| **FIT-065** | — | 9/20 | 11 | Community hub — feed | `/community` |
| **FIT-080** | — | 1/12 | 11 | Classes hub + schedule | `/classes` |
| **FIT-064** | — | 4/12 | 8 | Activity | `/activity` |
| **FIT-100** | — | 1/9 | 8 | Action items — what your coach set | `/action-items` |
| **FIT-054** | — | 4/11 | 7 | Progress · Photos | `/progress` |
| **FIT-066** | — | 3/9 | 6 | Post detail + comments | `/community` |
| **FIT-089** | — | 1/7 | 6 | AI nutrition — conversation | `/ai-nutrition` |
| **FIT-008** | 🔒 | 2/7 | 5 | Intake | `/intake` |
| **FIT-105** | — | 10/15 | 5 | AI Coach — how it speaks, what it knows | `/ai-coach` |
| **FIT-071** | — | 1/6 | 5 | Pods hub | `/pods` |
| **FIT-027** | 🔒 | 5/10 | 5 | What's on | `/classes` |
| **FIT-032** | 🔒 | 6/11 | 5 | Coach dashboard | `/coach-dashboard` |
| **FIT-088** | — | 0/5 | 5 | Cancellation — confirm → cancelled | `/class-detail` |
| **FIT-062** | — | 2/7 | 5 | Notifications | `/notifications` |
| **FIT-014** | 🔒 | 8/12 | 4 | Workouts hub | `/train` |
| **FIT-016** | 🔒 | 3/7 | 4 | Workout detail | `/workout-detail` |
| **FIT-067** | — | 6/10 | 4 | Create post | `/community` |
| **FIT-037** | — | 4/8 | 4 | Medical history | `/intake` |
| **FIT-003** | 🔒 | 8/12 | 4 | Nutrition | `/meals-dashboard` |
| **FIT-031** | 🔒 | 1/5 | 4 | Plans | `/upgrade` |
| **FIT-039** | — | 2/6 | 4 | Experience | `/intake` |
| **FIT-005** | 🔒 | 8/12 | 4 | Connect | `/messages` |
| **FIT-044** | — | 5/9 | 4 | Lifestyle | `/intake` |
| **FIT-045** | — | 2/6 | 4 | Progress photos | `/intake` |
| **FIT-072** | — | 1/5 | 4 | Pod detail | `/pods` |
| **FIT-048** | — | 1/5 | 4 | Choose coach | `/intake` |
| **FIT-058** | — | 1/5 | 4 | Habits | `/habits` |
| **FIT-047** | — | 1/5 | 4 | Coaching mode | `/intake` |
| **FIT-051** | — | 5/8 | 3 | Selection variants | `/intake` |
| **FIT-046** | — | 0/3 | 3 | Photo source | `sheet — /intake, /progress` |
| **FIT-023** | 🔒 | 7/10 | 3 | Check-in hub | `/checkins` |
| **FIT-043** | — | 2/5 | 3 | Weight goal | `/intake` |
| **FIT-090** | — | 1/4 | 3 | AI nutrition — a turn that failed | `/ai-nutrition` |
| **FIT-096** | — | 4/7 | 3 | Booking — your calls and open slots | `/appointments` |
| **FIT-069** | — | 8/11 | 3 | Community — empty | `/community` |
| **FIT-004** | 🔒 | 8/11 | 3 | Check-In | `/daily-checkin` |
| **FIT-085** | — | 1/4 | 3 | Events hub | `/events` |
| **FIT-055** | — | 0/2 | 2 | Log weight | `/progress` |
| **FIT-076** | — | 1/3 | 2 | Challenge detail — active | `/challenge-detail` |
| **FIT-086** | — | 1/3 | 2 | Event ticket | `event_ticket_screen (unrouted)` |
| **FIT-106** | — | 5/7 | 2 | Add to memory | `/ai-coach` |
| **FIT-053** | — | 5/7 | 2 | Progress · Measurements | `/progress` |
| **FIT-050** | — | 4/6 | 2 | Consent | `/intake` |
| **FIT-028** | 🔒 | 8/10 | 2 | Connect — no coach | `/messages` |
| **FIT-029** | 🔒 | 4/6 | 2 | Profile | `/profile` |
| **FIT-092** | — | 2/4 | 2 | Meal plan — built | `/meal-plan` |
| **FIT-056** | — | 2/4 | 2 | Log measurements | `/progress` |
| **FIT-083** | — | 1/3 | 2 | Class — booked / live / cancelled | `/class-detail` |
| **FIT-082** | — | 1/3 | 2 | Class — full / waitlist | `/class-detail` |
| **FIT-063** | — | 1/3 | 2 | Women's health | `/womens-health` |
| **FIT-079** | — | 3/5 | 2 | Challenges — empty + loading | `/challenges` |
| **FIT-097** | — | 2/4 | 2 | Booking — before you have a coach | `/appointments` |
| **FIT-102** | — | 5/7 | 2 | AI Coach — first open | `/ai-coach` |
| **FIT-075** | — | 3/5 | 2 | Challenges hub | `/challenges` |
| **FIT-024** | 🔒 | 1/2 | 1 | Check-in detail | `/checkin-detail` |
| **FIT-084** | — | 2/3 | 1 | Classes — empty + loading + error | `/classes` |
| **FIT-030** | 🔒 | 5/6 | 1 | Settings | `/settings` |
| **FIT-059** | — | 1/2 | 1 | Goals | `/goals` |
| **FIT-049** | — | 0/1 | 1 | Generating plan | `/intake` |
| **FIT-094** | — | 2/3 | 1 | Grocery list — the two blocked states | `/grocery-list` |
| **FIT-015** | 🔒 | 8/9 | 1 | Workouts — no plan yet | `/train` |
| **FIT-109** | — | 6/7 | 1 | AI Coach — a turn that failed | `/ai-coach` |
| **FIT-108** | — | 6/7 | 1 | AI Coach — conversation | `/ai-coach` |
| **FIT-098** | — | 1/2 | 1 | Booking — nothing open, and loading | `/appointments` |
| **FIT-040** | — | 3/4 | 1 | Height | `/intake` |
| **FIT-035** | — | 1/2 | 1 | Profile information | `/intake` |
| **FIT-081** | — | 1/2 | 1 | Class detail | `/class-detail` |
| **FIT-087** | — | 1/2 | 1 | Booking sheet — confirm → confirmed | `/class-detail` |
| **FIT-070** | — | 3/4 | 1 | Community — loading + error | `/community` |
| **FIT-101** | — | 1/2 | 1 | Action items — empty, loading, failed | `/action-items` |
| **FIT-038** | — | 11/12 | 1 | Injuries | `/intake` |
| **FIT-110** | — | 3/4 | 1 | AI Coach — coming back | `/ai-coach` |
| **FIT-074** | — | 1/2 | 1 | Pods — empty + loading | `/pods` |
| **FIT-093** | — | 1/2 | 1 | Meal plan — it didn’t build | `/meal-plan` |
| **FIT-026** | 🔒 | 4/5 | 1 | Conversation | `/chat` |
| **FIT-020** | 🔒 | 4/5 | 1 | AI meal scan | `/log-meal (ai_scan_view)` |
| **FIT-078** | — | 0/1 | 1 | Challenge — upcoming · completed · expired | `/challenges` |
| **FIT-091** | — | 15/16 | 1 | Meal plan — set your targets | `/meal-plan` |
| **FIT-019** | 🔒 | 4/5 | 1 | Log a meal | `/log-meal` |
| **FIT-068** ✅ | — | 0/0 | 0 | Post types | `/community` |
| **FIT-061** ✅ | — | 1/1 | 0 | Insights | `/insights` |
| **FIT-060** ✅ | — | 1/1 | 0 | Score | `/score` |
| **FIT-057** ✅ | — | 5/5 | 0 | Progress · states | `/progress` |
| **FIT-052** ✅ | — | 5/5 | 0 | Progress · Weight | `/progress` |
| **FIT-042** ✅ | — | 2/2 | 0 | Target weight | `/intake` |
| **FIT-041** ✅ | — | 4/4 | 0 | Weight | `/intake` |
| **FIT-001** ✅ | 🔒 | 9/9 | 0 | Home | `/home` |
| **FIT-036** ✅ | — | 8/8 | 0 | PAR-Q | `/intake` |
| **FIT-034** ✅ | — | 1/1 | 0 | Intake welcome | `/intake` |
| **FIT-033** ✅ | 🔒 | 5/5 | 0 | Check-in review | `/coach-checkin-review` |
| **FIT-073** ✅ | — | 0/0 | 0 | Pods — joined vs not joined | `/pods` |
| **FIT-025** ✅ | 🔒 | 1/1 | 0 | Awaiting reply | `/checkin-detail` |
| **FIT-022** ✅ | 🔒 | 1/1 | 0 | Loading & failure | `cross-cutting pattern` |
| **FIT-021** ✅ | 🔒 | 3/3 | 0 | Entitlement gate | `PaywallGate wrapper (12 routes)` |
| **FIT-018** ✅ | 🔒 | 4/4 | 0 | Session complete | `/active-workout` |
| **FIT-017** ✅ | 🔒 | 2/2 | 0 | Rest & completion | `/active-workout` |
| **FIT-013** ✅ | — | 1/1 | 0 | Set a new password | `/reset-password` |
| **FIT-099** ✅ | — | 0/0 | 0 | Booking handoff | `/booking-handoff` |
| **FIT-012** ✅ | — | 2/2 | 0 | Forgot password | `/forgot-password` |
| **FIT-011** ✅ | — | 2/2 | 0 | Sign up | `/signup` |
| **FIT-010** ✅ | — | 1/1 | 0 | Splash | `/splash` |
| **FIT-103** ✅ | — | 5/5 | 0 | AI Coach — today | `/ai-coach` |
| **FIT-104** ✅ | — | 5/5 | 0 | AI Coach — the week | `/ai-coach` |
| **FIT-009** ✅ | 🔒 | 1/1 | 0 | Intake complete | `/intake` |
| **FIT-007** ✅ | 🔒 | 1/1 | 0 | Sign in | `/login` |
| **FIT-107** ✅ | — | 4/4 | 0 | AI Coach — a card that failed | `/ai-coach` |
| **FIT-006** ✅ | 🔒 | 2/2 | 0 | Welcome | `/onboarding` |
| **FIT-002** ✅ | 🔒 | 5/5 | 0 | Active Workout | `/active-workout` |
| **FIT-077** ✅ | — | 1/1 | 0 | Who else is in | `/challenge-detail` |
