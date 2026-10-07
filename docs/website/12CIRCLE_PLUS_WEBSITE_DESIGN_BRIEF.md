# 12Circle+ public website — design brief

**This is a brief, not a design.** No layouts, screens or visual decisions were invented. It
records the inputs a designer is bound by and the outputs the build needs. Scope depends on
**WEB-OD-01** ([decision package](12CIRCLE_PLUS_WEBSITE_DECISION_PACKAGE.md)).

## Identity (binding)

| | |
|---|---|
| Master brand | 12Circle |
| Product | **12Circle+**. Never "12Circle Fitness", "12Circle+ Fitness" or "12Circle OS" |
| Tagline | *Connecting Coaches. Clients. Communities.* |
| Logo | The approved mark, `docs/design/brand/assets/12circle-plus-logo.png` (design branch): a ring of twelve rounded triangular dots, a violet centre disc, the **12CIRCLE** wordmark in near-white and a violet **+**. Use it unmodified. |
| Palette | CONF-D6. Violet `#7C3AED` (fills, large display, non-text UI), accent `#A78BFA` (text and lines on dark), hover `#C4B1FC`, amber `#E0A030`, green `#2FBF87`, dark ground `#0A0A0B`. **Not** the Helix-repo lime FIRST PASS palette. |
| Type | Schibsted Grotesk 400 / 500 / 600, with tight tracking on headings |
| Icons | Phosphor, regular weight; fill only for a selected state |
| Ground | Dark, consistent with the app and Admin. A light variant is not requested. |

## Audience and tone

- Coaches, clients and communities, in the tagline's order.
- Plain and factual. No unreviewed health or outcome claims (WEB-OD-06).
- No testimonials, ratings or statistics unless they are real and sourced.

## Constraints

- WCAG 2.2 AA:
  - text ≥ 4.5:1 (violet `#7C3AED` on `#0A0A0B` measures 3.47:1, so it is not usable for body text)
  - controls ≥ 44 px
  - visible 2 px focus ring
  - reduced motion respected
  - status never shown by colour alone
- Must work without JavaScript. No third-party embeds, fonts, maps, videos or widgets.
- Must not resemble or reveal the Admin Control Center, and must not show real user data, coach profiles or app screenshots containing personal data.
- Breakpoints: mobile 360–390, tablet 768, desktop 1280–1440. No horizontal scroll at 320 px or at 200% zoom.

## Deliverables requested

1. Page list confirmed against WEB-OD-01 (candidate list: assessment §F).
2. Wireframes and visual design for Home and for one long-form content template (legal, support, deletion and 404 derive from it).
3. Component specs with all states: header/nav (mobile menu open and closed), footer, primary/secondary/link buttons, hero/section, feature card, legal typography (headings, lists, tables), focus and hover.
4. A **vector logo master (SVG)**, favicon set, touch icon and a 1200×630 OG image, all derived from the approved mark.
5. Imagery direction and licensing, or an explicit "no photography".

## Out of scope for the designer

Hosting, domain, analytics, forms, pricing content (WEB-OD-03/04/07/08/09) and anything behind sign-in.
