# 12Circle+ public website — owner direction record and current status

| | |
|---|---|
| Recorded | 2026-10-07 |
| Source | Owner instruction "V5 + 12CIRCLE+ WEBSITE — OWNER DIRECTION / HOLD IMPLEMENTATION" |
| Baseline accepted | [`12CIRCLE_PLUS_WEBSITE_WORKSTREAM_ASSESSMENT.md`](12CIRCLE_PLUS_WEBSITE_WORKSTREAM_ASSESSMENT.md) (commit `4e115ff`) as the discovery baseline |
| Branch | `workstream/12c-plus-website`, isolated. Never merged into `reconcile/12circle-integrated` automatically. No website work on `reconcile/12circle-integrated` or `design/12circle-plus-admin-dashboard`. |

Where this record conflicts with the earlier assessment, decision package or brief, **this record wins**.

## Current status

| Track | Status |
|---|---|
| Discovery | **COMPLETE** |
| Architecture | **RECOMMENDATION PREPARED.** Static site plus a link to the app. Not approved (WEB-OD-02 open). |
| Design | **CLAUDE DESIGN IN PROGRESS.** Claude Design is the design authority (WEB-OD-05). |
| Implementation | **WAITING FOR APPROVED DESIGN / AUTHORITY.** Not implementation-ready. |
| Domain | **UNRESOLVED.** `12circle.app` is not assumed owned, approved or final. |
| Hosting | **UNRESOLVED.** No hosting is created; nothing is deployed. |
| Backend | **NOT REQUIRED** by the current recommendation |
| Legal / support pages | **REQUIRED FOR RELEASE.** Content authority still required. |

Design-package check, 2026-10-07: every remote branch was searched after a fresh fetch. **No Claude Design website
package exists in the repository yet.** The stop condition holds.

## Decisions: what the direction settles and what it leaves open

| ID | Before | Now |
|---|---|---|
| WEB-OD-01 scope | Open; recommendation "(a) legal/support only now" | **SETTLED: a public website exists** as the 12Circle+ public web surface. It is not 12Circle Fitness, a separate company or product, the Admin app or the mobile app. **Scope is the broader public site Claude Design is designing.** The four legal and support pages are minimum release infrastructure, **not** the whole site. The "(a) now" recommendation is **withdrawn**. |
| WEB-OD-02 architecture | Recommendation D1 | **OPEN.** The D1 recommendation stands as engineering advice only. It is not an approval. The site is not to be collapsed into the Flutter Admin application. |
| WEB-OD-03 domain | Open | **OPEN.** Tied to V5 PD-F04. No purchase, DNS change, hosting or deploy. Final hosted Privacy, Terms and Support URLs are **not** to be written down until it closes. |
| WEB-OD-05 design | Options: supply, commission, plain template | **ASSIGNED TO CLAUDE DESIGN.** "Commission from the brief" and "approve a plain template" are **withdrawn**. The package becomes authority once approved. |
| WEB-OD-04, 06–11 | Open | Still open. They are re-evaluated against the design package at reconciliation, batched into one package. |

## Withdrawn or downgraded in the earlier documents

- **Design brief** ([`12CIRCLE_PLUS_WEBSITE_DESIGN_BRIEF.md`](12CIRCLE_PLUS_WEBSITE_DESIGN_BRIEF.md)): **not a commission and not design authority.** It remains only as a record of the constraints engineering will check the Claude Design package against (identity, CONF-D6, contrast, no third parties). Its "deliverables requested" list is not a request to anyone.
- **Assessment §F "minimum viable site" and §P "first buildable unit"**: withdrawn as scope advice. The four pages are a release requirement inside the broader site.
- **Assessment §O "visual design for Home…"**: no engineering-authored design, wireframe or layout will be produced. Those artefacts come from Claude Design.

## Binding constraints carried into reconciliation

- **Identity (CONF-D6, closed):**
  - dark surfaces
  - violet `#7C3AED`, amber `#E0A030`, green `#2FBF87`
  - the shipped Helix three-tier stack
  - no electric-lime FIRST PASS palette
  - no second design system
  - Admin screens are not website authority.
- **Contrast:** violet `#7C3AED` on `#0A0A0B` = 3.47:1, so it is not used for body text. The package's own tokens are used. If it needs an accessible text colour Helix lacks, that is recorded as an **additive Helix token requirement**, never a brand change.
- **Backend:** none, preferred. No new tables, public user APIs, auth or authorization systems unless the approved design shows a real need **and** V5 authorises the extension. Never expose PHI, health, audit, Guardian, Admin, credential or private user data.
- **Third parties:** vendor-free by construction. Every dependency is identified and reconciled. **No `flagcdn`** (V5 records it as documentation-only today, `V5_PROGRAMME_DEFINITION.md` §156.2; the website must not introduce it). No production egress, no secrets, no Admin API reachable anonymously.
- **Legal and support content:** engineering does not write legal language or claim legal approval. The content authority for Privacy, Terms, Support and Account deletion is to be named (WEB-OD-06 / WEB-OD-10). Routing and page infrastructure only when authorised.

## Intake procedure when the Claude Design package arrives

Order: **DESIGN → V5 RECONCILIATION → ARCHITECTURE → IMPLEMENTATION.**

1. Ingest the whole package and record its path, commit and provenance. Confirm it is the approved package before treating it as authority.
2. Produce the reconciliation `docs/website/12CIRCLE_PLUS_WEBSITE_DESIGN_RECONCILIATION.md` with sections:
   - A pages
   - B components
   - C states
   - D responsive
   - E token mapping (each token mapped to Helix primitive/semantic, or marked additive)
   - F icon mapping (Phosphor; licence; self-hosted)
   - G accessibility (measured contrast for every text/background pair)
   - H SEO
   - I content (each block with its content owner)
   - J backend
   - K security (every external request in the package listed)
   - L hosting/deployment
   - M conflicts with V5
   - N owner decisions
   - O implementation-ready scope
3. Batch every new owner question, together with WEB-OD-02/03/04/06–11, into **one** decision package. No individual questions.
4. Implement every portion that is then authorised, on this branch only, with tests. Nothing that depends on an open decision. No deploy without WEB-OD-03/04.

## V5 independence

The website and V5 frontiers are separate. No website item gates V5 work. No V5 owner decision gates website
design discovery. The only cross-links are named ones: PD-F04 (domain), PD-F02 (where "Sign in" points), PD-E08 and PD-F01 (any
pricing content), and PD-D08 (health-claim review).
