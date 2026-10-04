# Admin screen inventory

**Navigation (authoritative six-item IA):** Dashboard · People · Ecosystem · Trust · Operations · Settings. Dashboard links to the Control Center; every page file carries the shared header nav (a section not yet designed stays `aria-disabled` with "Soon").

The older eight-item navigation in the build spec (Overview, Ecosystem, Users, Finance, Analytics, Security, AI Guardian, Operations) is historical and is **not** used.

| Page | File | Top-level nav | Sections on the page |
|---|---|---|---|
| Control Center (Dashboard) | 12Circle Admin Control Center.dc.html | Dashboard | Needs your attention (attention queue + drawer); Ecosystem snapshot; Ecosystem activity; Events & community; Security; AI Guardian; Wearable intelligence; QA & release; Recent admin activity; Installs, Age range, Impressions; Dashboard states; Requires architectural verification (design-time notes panel) |
| Ecosystem | 12Circle Admin Pages - Ecosystem.dc.html | Ecosystem | #overview (What’s happening across 12Circle+), #community, #events, #training, #monetization, #wearables, audit pattern |
| People | 12Circle Admin Pages - People.dc.html | People | #users, #coaches, #clients, #partners (Wellness Partners), #states (state system) |
| Trust | 12Circle Admin Pages - Trust.dc.html | Trust | #overview, #ai-guardian, #security (incl. #sec-authz), #incidents, #audit (audit explorer, #audit-event before/after), #trust-system |
| Operations | 12Circle Admin Pages - Operations.dc.html | Operations | #overview, #releases, #integrations, #system (#sys-events), #ops-system |
| Settings | 12Circle Admin Pages - Settings.dc.html | Settings | #overview, #organization, #users (Administrators), #roles (Roles & permissions), #platform (General), #notifications, AI & intelligence, #privacy (Data & privacy), #security, #integrations, #billing (Billing & monetization), #states |

## Other Admin files (kept, not the current design)

| File | Status |
|---|---|
| `12Circle Admin Control Center v1.dc.html` | Earlier version of the Control Center. Superseded, preserved. |
| `12Circle Admin Dashboard.dc.html` | Earlier analytics dashboard (Revenue, Sessions logged, Most-logged exercises, Client age, Where clients train). Superseded, preserved. |

## States designed (present in all six current files unless noted)

Loading, Empty, Error, Permission (denied), Degraded. Also: Unavailable (Control Center, Operations, People), Stale (People, Trust), Offline and Skeleton (Ecosystem, People), Read-only (Operations, Settings, Trust). A "State system" panel on People, Trust, Operations and Settings and "Dashboard states" on the Control Center show the patterns side by side.

## Interactions expected

Attention queue opens a drawer; every "View audit history" link deep-links to Trust > Audit logs; before/after diffs deep-link to a Trust audit event; Settings links across to Operations > System events, Trust > Authorization and Trust > AI Guardian; global search and filters on tables; row actions open confirm dialogs for destructive changes.

## Data each page needs (approved design requirement; implementation/architecture capability required)

- **Dashboard:** user counts by role; DAU/WAU/MAU; revenue by stream; churn; service health feed (six tiles); AI Guardian autonomy level and findings; wearable sync status; QA and release status (from CI); install, age-range and impression series; audit-log tail.
- **Ecosystem:** community posts, reports and moderation queue; events and attendance; training content and completion; monetisation (plans, payouts, commission); wearable connections.
- **People:** account list with role, status, last active; coach verification; client assignment; Wellness Partner onboarding and approval states.
- **Trust:** AI Guardian actions and autonomy; auth and authorisation events; incidents; immutable audit log with before/after.
- **Operations:** releases and environments; integrations health; system events.
- **Settings:** organisation profile; admins and roles; platform, notification, AI, privacy, security, integration and billing configuration.

Each of these is **kept** even where no API or table exists today. The Control Center's own "Requires architectural verification" panel records the same gaps (no known admin data layer; service health; AI Guardian not in code; wearables are Android-first so HealthKit and Apple Watch need confirming; CI cannot be read by the app; audit log assumes an append-only store).
