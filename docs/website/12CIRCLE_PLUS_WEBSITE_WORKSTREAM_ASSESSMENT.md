# 12Circle+ public website — workstream assessment (read-only)

| | |
|---|---|
| Date | 2026-10-07 |
| Branch | `workstream/12c-plus-website`, cut from `reconcile/12circle-integrated` @ `f1c2db6` |
| Scope | Discovery and assessment only. **No website code has been written.** |
| Isolation | Nothing on `reconcile/12circle-integrated` (V5) or `design/12circle-plus-admin-dashboard` was changed. This branch must not be merged into V5 automatically. |
| Identity | Product **12Circle+**, master brand **12Circle**, tagline *Connecting Coaches. Clients. Communities.* (from `docs/design/brand/README.md` on the design branch). Not "12Circle Fitness". No new brand. |
| Colour authority | CONF-D6: violet `#7C3AED` / amber `#E0A030` / green `#2FBF87` on dark `#0A0A0B`, via the shipped Helix three-tier stack. The standalone Helix electric-lime (`#9EF01A`) FIRST PASS palette is **not** authoritative and is not used here. |

## Verdict

**STOP CONDITION MET.** No approved website design, no defined product scope for a site, and
no hosting, domain or deployment target exist. Per the workstream instructions, none of these
has been invented. Everything after section C is a recommendation or a requirement for the
owner to confirm, not a decision. The decisions are collected in
[`12CIRCLE_PLUS_WEBSITE_DECISION_PACKAGE.md`](12CIRCLE_PLUS_WEBSITE_DECISION_PACKAGE.md).
The design inputs a designer needs are in
[`12CIRCLE_PLUS_WEBSITE_DESIGN_BRIEF.md`](12CIRCLE_PLUS_WEBSITE_DESIGN_BRIEF.md). That file is a brief, not a design.

The website workstream and V5 do not block each other. Nothing here sits on any V5 critical path,
and no V5 blocker stops the website's owner decisions from being taken.

---

## A · Existing website code

**None.** Searched every remote branch (`main`, `reconcile/12circle-integrated`,
`chore/qa-environments-secure-ai-backend`, `design/12circle-plus-admin-dashboard`,
`claude/dreamy-ptolemy-3sk1vz`):

- `apps/` holds only `apps/mobile`, on the integrated branch.
- No `next.config.*`, `vite.config.*`, `astro.config.*`, `gatsby-*`, `hugo.*`, `_config.yml`, `website/`, `site/` or `www/` exists anywhere.
- `docs/SKILLS_AGENT_AUDIT.md` already records the `04-web-engineer` skill as **ORPHANED**: *"No website app … The only 'web' is `flutter build web` — the same Flutter app, not a site."*

What exists and is adjacent, but **is not a website**:

| Item | What it is | Relevance |
|---|---|---|
| `apps/mobile/web/index.html`, `manifest.json`, `icons/` | Flutter web bootstrap for the authenticated app | Still the scaffold defaults: `<title>circle_fitness</title>`, `<meta name="description" content="A new Flutter project.">`. This is finding **WEB-F1**: it belongs to the app (REL-11 / PD-F04 naming) and is not fixed here. |
| `apps/mobile/web/stripe_checkout.html`, `checkout_complete.html` | Static helper pages served with the app; the first loads `js.stripe.com/v3` | These are app/billing surfaces, not website pages. They stay with the app. |
| App routes `/payment-success`, `/payment-cancel`, `/privacy-policy`, `/terms-of-service` (`apps/mobile/lib/core/router/app_router.dart`) | In-app Flutter screens | The legal text exists **only** in-app (`privacy_policy_screen.dart`, `terms_of_service_screen.dart`) |
| Edge Function `APP_URL` default `https://12circle.app` (checkout, portal, connect, invite email) | Redirect targets | The domain cannot be confirmed as registered or controlled (PD-F04, REL-17, E-06) |
| CI `flutter build web --dart-define-from-file=dart_defines/qa.json` | A build-only check | **No deploy job and no hosting config anywhere** |

## B · Existing website designs

**None approved, and none drafted.** The only design authority published for 12Circle+ is on
`design/12circle-plus-admin-dashboard` (`931218b`). It contains the Admin Control Center
(six screens, two superseded) and a brand kit. That brand kit is the only input that carries
over to a website:

| Input | Path (design branch) | Usable for the website? |
|---|---|---|
| Logo (raster) | `docs/design/brand/assets/12circle-plus-logo.png` | Yes, as the identity source. There is **no vector master**: the README records that an earlier drawn `logo-mark.svg` was not the approved mark and was removed. A website needs an SVG for favicon, OG image and crisp rendering (see O). |
| Identity rules | `docs/design/brand/README.md` | Yes: one violet, dark ground, Schibsted Grotesk 400/500/600, Phosphor icons (regular, fill only when selected), status semantics never by colour alone, accessibility floor |
| `--adm-*` tokens | `docs/design/brand/tokens/admin.tokens.{css,json}` | **Not as the source.** They were extracted from Admin pages, and `BOUNDARIES.md` row G leaves "Admin tokens vs Fitness Helix tiers" as an open architecture question. See G. |
| Admin screens | `docs/design/admin-dashboard/screens/*.dc.html` | **No.** They are dense operational UI behind auth, and must never be reproduced or linked publicly (see I, J) |

Under the workstream rule ("if no approved website design exists, produce a design brief, not
invented designs"), this assessment ships a brief only.

## C · Recommended architecture

**A static, pre-rendered, content-only site with no runtime backend, no authentication and no
data reads, on its own origin, linking out to the authenticated app.**

```
                 public, crawlable, no auth                  authenticated (Supabase Auth only)
 ┌──────────────────────────────────────────┐        ┌──────────────────────────────────────────┐
 │ 12Circle+ website   (www / apex origin)  │  link  │ 12Circle+ app  (Flutter web, app origin) │
 │ static HTML + CSS, generated at build    │ ─────► │ /login, /signup, member + coach surfaces │
 │ no JS required · no cookies · no forms   │        │ Admin Control Center = separate Flutter  │
 │ reads nothing from Supabase / API        │        │ web target (V5 D6), never linked from    │
 └──────────────────────────────────────────┘        │ the website                              │
                                                     └──────────────────────────────────────────┘
```

Why this shape:

1. **It inherits no attack surface.** A site that never calls Supabase, the API or an Edge Function cannot leak PHI, protected profile data, audit records, Guardian internals or Admin data. It also needs none of the V5 RLS work to be "secure by construction".
2. **No second auth system.** The site has no login of its own. "Sign in" is a link to the app's existing Supabase flow.
3. **It needs no new tables.** Section H finds nothing on the site that needs storage.
4. **It answers REL-17.** The App Store needs hosted Privacy, Terms and Support URLs. A static site is the cheapest correct way to provide them.
5. **It matches PD-F02's recommendation ("web-first beta"), if accepted.** The app runs on its own origin and the site points to it.

**Departure from precedent, flagged rather than taken.** V5 decision D6 chose a Flutter web
target for Admin to reuse "the existing codebase, auth and theme". The website's needs are the
opposite of Admin's: public, anonymous, indexable, fast on first paint, and no auth. Flutter web renders through a canvas, ships a
multi-megabyte runtime, and gives crawlers little or no semantic HTML. So the recommendation is to depart from
the D6 precedent for this surface while reusing the theme through generated tokens (G). This is owner
decision **WEB-OD-02**. It is not assumed.

## D · Framework

| Option | SEO / perf | Vendor-free | Reuses V5 | Risk | Assessment |
|---|---|---|---|---|---|
| **D1. Hand-authored HTML + CSS, tokens generated from Helix by a Dart script already in the repo toolchain** | Best | Yes: no new package manager, no runtime dependency | Tokens (generated), brand, Dart toolchain | Templating by hand across ~8–10 pages; acceptable at this size | **Recommended** |
| D2. A static-site generator (Astro, Eleventy, Hugo …) | Best | No: adds an npm/Go toolchain and its supply chain | Tokens only | Supply chain and a new toolchain to maintain | Only if page count or content authoring outgrows D1 |
| D3. A route group inside the Flutter web app | Poor (canvas render, large first load, weak crawlability) | Yes | Everything | Ties public pages to the app bundle and auth router; risk of public routes inheriting app state | Not recommended for a public site |
| D4. A JS framework SPA/SSR (Next.js etc.) | Good with SSR | No | Tokens only | Requires a server runtime and so a host with compute. Largest new surface | Not recommended |

"Vendor-free by construction" is achievable for **building** the site (D1). It is **not**
achievable for **hosting** it: serving a public site always needs a provider or owned
infrastructure. That is WEB-OD-04.

## E · Branch structure

- `workstream/12c-plus-website` was cut from the integrated tip `f1c2db6`. It holds this assessment and nothing else.
- Proposed code location, **not created**: `apps/website/`. The site's source, generated token CSS and build script would live there, outside `apps/mobile`, so no website change can alter the app bundle.
- Keep current with V5 by **merging** `reconcile/12circle-integrated` into this branch. Never rebase a shared branch, and never merge in the other direction automatically.
- Promotion into V5 or `main` happens only through a PR the owner opens or approves.
- Optional topic branches `workstream/12c-plus-website/<topic>` merge into the workstream branch, not into V5.

## F · Page inventory (candidate, unapproved)

Each row lists what it depends on. Nothing here is approved scope (WEB-OD-01).

| # | Page | Purpose | Blocked by |
|---|---|---|---|
| 1 | Home | Who 12Circle+ is for: coaches, clients, communities (from the tagline) | WEB-OD-01, design, copy (WEB-OD-06) |
| 2 | For coaches | The coach value proposition | same |
| 3 | For clients | The client value proposition. Health claims need review. | same, plus a clinical/claims reviewer (PD-D08 is open) |
| 4 | Pricing | Tiers | **V5 PD-E08 (which tier ladder) and PD-F01 (iOS IAP) are open.** Omit until those close. |
| 5 | **Privacy Policy** | Required hosted URL (REL-17) | WEB-OD-10 (single source with in-app text), domain |
| 6 | **Terms of Service** | Required hosted URL (REL-17) | same |
| 7 | **Support / contact** | Required hosted URL (REL-17). A `mailto:` to `support@` needs no backend. | WEB-OD-08, mailbox ownership on the domain |
| 8 | Account and data deletion | How to request deletion (`privacy@`, as the Privacy Policy states today) | same as 5 |
| 9 | 404 | — | design |
| 10 | `robots.txt`, `sitemap.xml`, `/.well-known/security.txt` | Crawl control, disclosure contact | domain |

**Minimum viable site if the owner wants only the App Store requirement:** rows 5–10. These
need design input only at the level of a plain typographic template.

The following are **not** website pages and stay in the app: `/login`, `/signup`,
`/payment-success`, `/payment-cancel`, account and billing, every member, coach and Admin surface.

## G · Shared design-system strategy

- **Single source:** the shipped Helix three-tier stack in Dart (`apps/mobile/lib/core/helix/helix_primitives.dart` → `helix_semantics.dart` → `core/theme/twelve_circle_theme.dart`), which is authoritative under CONF-D6-B.
- **Website consumption:** a generated `tokens.css` of CSS custom properties, emitted from those Dart definitions by a build script, never edited by hand. A CI check regenerates it and fails on any diff (drift guard). That is consumption, not a fork.
- **Not the source:** the design branch's `--adm-*` tokens. Their relation to Helix is open (`BOUNDARIES.md` G). Not the standalone Helix repo's lime palette either.
- **Type:** Schibsted Grotesk 400/500/600, self-hosted font files (no Google Fonts request; see J). The license allows this (SIL OFL), but confirm the exact files used.
- **Icons:** Phosphor, regular weight, self-hosted SVG subset (MIT).
- **Identity check, measured:** brand violet `#7C3AED` on `#0A0A0B` is **3.47:1**, so it fails 4.5:1 for body text. Use it for fills, large display text and non-text UI only. Text on dark uses accent `#A78BFA` (**7.27:1**), as the brand README already says. White on violet is 5.70:1, which is fine for buttons. Amber 8.71:1 and green 8.41:1 on dark both pass.

## H · Backend dependencies

**None required.** The recommended site reads and writes nothing.

| Possible feature | Would need | Status |
|---|---|---|
| Contact form | An endpoint, storage, spam control and consent text. Probably a new table. | **Not authorised.** "No new DB tables for convenience." Use `mailto:` (WEB-OD-08) |
| Beta waitlist / lead capture | Storage of personal data, consent, retention, deletion | Owner decision (WEB-OD-08). Not assumed |
| Live pricing from the DB | A public read of tier data | Not needed; pricing is blocked anyway (F4) |
| Coach directory / profiles | A public read of `public_profiles` | **Out of scope.** It exposes user data on an anonymous surface. Would need its own owner and privacy decision |
| NestJS API | — | Not used. It has no deployment target (PD-A17 open) |

## I · Authentication boundary

| Surface | Auth | Origin (proposed) | Indexed |
|---|---|---|---|
| Public website | **None.** No sessions, no cookies, no Supabase client, no anon key in the bundle | apex / `www` | Yes |
| Authenticated app (Flutter web) | Supabase Auth, the existing and only system | separate app subdomain | No (`noindex`) |
| Admin Control Center | Supabase Auth plus admin role (V5 P5/D6) | its own Flutter web target, never linked from the site | No |

Rules:
- One auth system: Supabase. The site has no login, no "member area" and no token handling. "Sign in" and "Get started" are plain links to the app's `/login` and `/signup`.
- **Separate origins.** The app keeps its Supabase session in browser storage, which is scoped to the app's origin. A site on another origin cannot read it, and an XSS on the site could not reach it.
- Admin is never referenced from the website: no link, no route, no `robots.txt` entry naming it.

## J · Security

Inherited from V5 and adapted to a static surface:

- **Data exposure:** the site contains no PHI, protected user information, internal audit data, Guardian internals, Admin-only information, credentials or operational data. A build check fails if the output contains a Supabase URL, an anon or service key, a JWT-shaped string or an internal hostname.
- **No third-party requests:** no analytics, tag managers, pixels, embedded videos, chat widgets or remote fonts. A health product's marketing site is a known channel for health-adjacent data leaking to ad networks. Any analytics is owner decision WEB-OD-09; the recommendation is none.
- **Headers** (set at the host, WEB-OD-04):
  - `Content-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data:; font-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'`
  - `Strict-Transport-Security` with preload once the domain is confirmed
  - `X-Content-Type-Options: nosniff`
  - `Referrer-Policy: strict-origin-when-cross-origin`
  - `Permissions-Policy` denying camera, microphone, geolocation and payment
- **No inline script.** The site should work with JavaScript disabled.
- **Supply chain:** D1 adds no package dependencies. Generated CSS is reproducible from the repo.
- **Secrets:** the build needs none. No deploy credential may live in the repo; it belongs in the CI secret store once WEB-OD-04 is decided.
- **Disclosure:** `/.well-known/security.txt` with a contact on the owned domain.

## K · SEO

- Pre-rendered HTML per page with a unique `<title>`, meta description and canonical URL. Canonical URLs need the domain decided first (PD-F04 / WEB-OD-03).
- `sitemap.xml`; `robots.txt` that allows the site and says nothing about app or Admin paths, which live on other origins and send `noindex` themselves.
- Open Graph and Twitter card metadata with an OG image derived from the approved logo. This needs a vector master (O).
- `Organization` / `SoftwareApplication` structured data, factual only: no ratings or reviews unless real.
- The app origin should send `X-Robots-Tag: noindex`, and its `index.html` metadata should be fixed (WEB-F1, V5 side).
- Performance budget: no JavaScript required, one CSS file, subset fonts. The target is Lighthouse ≥ 95 on all four categories, measured, not asserted.

## L · Accessibility

Target **WCAG 2.2 AA**, with the brand README floor:
- Text contrast ≥ 4.5:1 (see the measured values in G: never violet text on dark at body size).
- Controls at least 44×44 px.
- A 2 px accent focus ring that is always visible.
- `prefers-reduced-motion` respected.
- Status is never shown by colour alone.
- Semantic landmarks, one `h1` per page, a skip link, `lang`, descriptive link text, alt text, and visible labels if a form is ever added.
- Verify with automated checks (axe, Lighthouse) **and** a manual keyboard and screen-reader pass. Automated checks alone are not evidence of AA.
- Legal pages must be readable at 200% zoom and 320 px width without horizontal scroll.

## M · Infrastructure and deployment

**Nothing exists, and none of it can be assumed.**

| Need | State | Decision |
|---|---|---|
| Domain (`12circle.app` or other) | Referenced in code; ownership and DNS unconfirmed | PD-F04 (V5, open) / WEB-OD-03 |
| Hosting for static files plus headers | None | WEB-OD-04 |
| TLS / HSTS | — | follows the host |
| CI deploy job (preview and production) | None; CI only builds the Flutter app | After WEB-OD-04 |
| Mailboxes `support@`, `privacy@`, `security@` | Referenced in the Privacy Policy; existence unconfirmed | WEB-OD-03 |
| App-origin hosting (PD-F02 web-first beta) | None | V5 PD-F02 (open). The website can launch without it, but the "Sign in" links need a target. |

Production is never touched by this workstream. A preview deploy, once a host exists, runs from
this branch only.

## N · Owner decisions

Collected, not asked one by one, in
[`12CIRCLE_PLUS_WEBSITE_DECISION_PACKAGE.md`](12CIRCLE_PLUS_WEBSITE_DECISION_PACKAGE.md):
**WEB-OD-01 … WEB-OD-11**. Four of them gate everything: **01** (does a site exist, and what scope),
**02** (architecture), **03** (domain) and **05** (design authority).

## O · Design artifacts required

Before any page is built:
1. Wireframes per approved page, at mobile (360–390), tablet (768) and desktop (1280–1440) widths.
2. Visual design for Home plus one content template, from which legal, support and 404 pages derive.
3. Components: header and nav (including the mobile menu state), footer, buttons (primary, secondary, link), section/hero, feature card, legal-text typography, the focus state of each.
4. A **vector logo master**, plus favicon set, app-touch icon and OG image, derived from the approved mark. Only a PNG exists today.
5. Imagery direction and rights: whether photography is used, from where, and under what licence.
6. Copy for every page, with the approver named (WEB-OD-06).

The brief that frames items 1–5 is
[`12CIRCLE_PLUS_WEBSITE_DESIGN_BRIEF.md`](12CIRCLE_PLUS_WEBSITE_DESIGN_BRIEF.md).

## P · Already-authorised implementation work

| Work | Authorised? | Done |
|---|---|---|
| Create `workstream/12c-plus-website`, isolated from V5 | Yes (workstream instruction) | Yes, at `f1c2db6` |
| This assessment, decision package and design brief | Yes | Yes |
| Website section in the consolidated owner-input report | Yes | Yes, as Part II of `docs/V5_OWNER_INPUT_PACKAGE.md` **on this branch only**. The V5 copy is untouched. |
| Any site code, token generator, CI job or deploy | **No.** "Do NOT begin implementation merely because the branch is authorized" | Not started |

Once WEB-OD-01, 02 and 05 are answered, the first buildable unit is the **minimum viable site**
(F rows 5–10) plus the token generator and its drift check. It needs no backend, no new table and
no V5 change.

## Findings recorded (not fixed here)

| ID | Finding | Owner surface |
|---|---|---|
| WEB-F1 | `apps/mobile/web/index.html` ships the scaffold title `circle_fitness` and description "A new Flutter project." | V5 app (REL-11 / PD-F04) |
| WEB-F2 | No hosted Privacy, Terms or Support URL exists (restates REL-17) | Website: F rows 5–7 |
| WEB-F3 | The approved logo exists only as a PNG; no vector master | Design authority |
