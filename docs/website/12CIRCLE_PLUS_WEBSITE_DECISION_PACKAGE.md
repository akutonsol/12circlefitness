# 12Circle+ public website — consolidated owner decision package

> **Superseded in part by [`12CIRCLE_PLUS_WEBSITE_OWNER_DIRECTION.md`](12CIRCLE_PLUS_WEBSITE_OWNER_DIRECTION.md) (2026-10-07).** WEB-OD-01 is settled (a site exists, with broad scope). WEB-OD-05 is assigned to Claude Design. The "(a) now", "commission" and "plain template" recommendations are withdrawn. All other decisions are re-batched after design reconciliation.

Companion to [`12CIRCLE_PLUS_WEBSITE_WORKSTREAM_ASSESSMENT.md`](12CIRCLE_PLUS_WEBSITE_WORKSTREAM_ASSESSMENT.md).
Each decision is stated once, with a recommendation. **None has been taken on the owner's behalf.**
These are website-only decisions. They do not block V5, and V5 decisions block them only where a row
says so explicitly.

## Gating decisions (nothing can be built without these)

| ID | Question | Options | Recommendation |
|---|---|---|---|
| **WEB-OD-01** | Does a public 12Circle+ website exist, and what is its scope? | (a) Minimum: legal, support and deletion pages only (satisfies REL-17) · (b) Minimum + marketing pages (Home, For coaches, For clients) · (c) No site; host the legal pages elsewhere | **(a) now, (b) when copy and design exist.** (a) needs almost no design and unblocks the App Store requirement. |
| **WEB-OD-02** | Architecture and framework | D1 static HTML + CSS with tokens generated from Helix · D2 static-site generator · D3 route group inside the Flutter web app · D4 SSR JS framework | **D1.** Departs from the D6 Flutter-web precedent on purpose: a public site needs crawlable HTML and no auth. Reuses the theme through generated tokens. |
| **WEB-OD-03** | Domain and origins | Confirm ownership of `12circle.app` (or name another) · site on apex/`www` · app on a separate subdomain · mailboxes `support@`, `privacy@`, `security@` | Confirm the domain **as part of V5 PD-F04**, which is the same question. Separate origins for site and app. |
| **WEB-OD-05** | Design authority for the website | Supply designs · commission from the brief · approve "plain typographic template" for option (a) only | Commission from [the brief](12CIRCLE_PLUS_WEBSITE_DESIGN_BRIEF.md). Approving the plain template now unblocks WEB-OD-01(a). |

## Dependent decisions

| ID | Question | Options | Recommendation |
|---|---|---|---|
| **WEB-OD-04** | Static hosting provider | Any static host that supports custom response headers and TLS, or owned infrastructure | Owner's choice. Requirements: custom headers (CSP, HSTS), preview deploys, no mandatory analytics or script injection |
| **WEB-OD-06** | Who writes and approves copy, including health claims? | Owner · named marketing owner · plus clinical review | Name an approver. Client-facing health claims need clinical review, which ties to V5 **PD-D08** (open). |
| **WEB-OD-07** | Pricing on the site | Show tiers · "contact / in-app" · omit | **Omit** until V5 PD-E08 (tier ladder) and PD-F01 (iOS IAP) close |
| **WEB-OD-08** | Contact / lead capture | `mailto:` only · contact form · waitlist | **`mailto:` only.** A form or waitlist stores personal data and needs a table, consent and retention rules. Not authorised for convenience. |
| **WEB-OD-09** | Analytics | None · self-hosted, cookieless, aggregate · third-party | **None** at launch. Any analytics must be first-party and cookieless, with no third-party requests. |
| **WEB-OD-10** | Single source for legal text | The website copy is canonical and the app links to it · the app text is canonical and the site is generated from it · two hand-kept copies | **One canonical source**, so the in-app and hosted text cannot drift. Two copies are not recommended. |
| **WEB-OD-11** | Token export | Generated CSS from Helix with a CI drift check · adopt `--adm-*` · hand-written CSS | **Generated from Helix.** `--adm-*` vs Helix is an open architecture question (design branch `BOUNDARIES.md` G). Hand-written CSS would be a fork. |

## Related V5 decisions (V5-owned, listed for visibility only)

| V5 ID | Why it matters to the website |
|---|---|
| PD-F04 | Canonical name and marketing domain. It is the same question as WEB-OD-03. |
| PD-F02 | Web-first beta. Decides where the site's "Sign in" link points. |
| PD-E08 / PD-F01 | Tier ladder and iOS payments. They gate the pricing page. |
| PD-D08 | Clinical owner. Health-claim review. |

## Response sheet

```
WEB-OD-01 scope        : a / b / c
WEB-OD-02 architecture : D1 / D2 / D3 / D4
WEB-OD-03 domain       : ____________   site origin: ________   app origin: ________   mailboxes exist? Y / N
WEB-OD-04 host         : ____________
WEB-OD-05 design       : supply / commission / plain template approved for (a): Y / N
WEB-OD-06 copy approver: ____________   clinical reviewer: ____________
WEB-OD-07 pricing      : show / contact / omit
WEB-OD-08 contact      : mailto / form / waitlist
WEB-OD-09 analytics    : none / first-party cookieless / third-party: ______
WEB-OD-10 legal source : site canonical / app canonical / two copies
WEB-OD-11 tokens       : Helix-generated / --adm-* / hand-written
```
