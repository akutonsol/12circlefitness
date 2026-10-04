# Transport record — 12Circle+ Admin Dashboard Design Authority

**This branch is the 12Circle+ Admin Dashboard Design Authority.**
**Transport and verification only. No design artifact was created, modified, recreated or substituted.**

This file records *how the artifacts arrived*. It is **not** design authority and **not** a summary of the
design. The authority is the `.dc.html` files, the brand assets, the Build Specification DOCX, and the
package's own `README` · `SCREEN-INVENTORY` · `COMPONENTS` · `RESPONSIVE` · `BOUNDARIES` · `PROVENANCE` ·
`12CIRCLE-PLUS-HANDOFF-REPORT.md`.

## Source

| | |
|---|---|
| Design package | `12circle+-dashboard.zip` — 26 files, SHA-256 `f3c358be146b64c41ce8014ad73329fe371d7dcb39023277eb7abbdd2a1b55b3` |
| Build Specification | `12Circle+_Admin_Control_Center_Dashboard_Build_Spec_V1.docx` — SHA-256 `2b564ce633ac21b6c04f0960b221b7aa5121faedb1df8bfc9166204f5d368a68`, verified against the expected hash **before** any commit |
| Published | 27 files — all 26 package files plus the DOCX |
| Integrity | **every one of the 27 verified byte-identical** to its source by `cmp`, not by hash of a copy |

Layout follows the structure the package's own handoff report §4 specifies — `docs/design/` with
`brand/`, `admin-dashboard/`, and the handoff report at the root. The package's internal organisation
(`brand/{assets,icons,tokens}`, `screens/`, `screens/superseded/`) is preserved exactly.

## Referenced but NOT supplied — three, recorded rather than fabricated

**Nothing below was created, stubbed or substituted.** Each is a reference *inside a supplied artifact* to
something the package did not contain.

1. **The design-system bundle.** All eight `.dc.html` files — six current and two superseded — reference
   `_ds/nocturne-042b8c43-38a6-4d0d-ac7e-0c98f29520e9/_ds_bundle.js` and `…/styles.css`. **Neither is in
   the package, and no `_ds` directory exists in it.** `./support.js` and `./image-slot.js`, which the same
   files also load, **are** present as siblings in both `screens/` and `screens/superseded/`. Consequence:
   opening a `.dc.html` directly will render **degraded** until the `_ds` bundle is supplied. The design
   files themselves are complete and unmodified.
2. **`mobile/`.** The handoff report §2 and §4 describe `mobile/README.md` and `mobile/SCREEN-INVENTORY.md`
   covering 218 frames. **This publication is Dashboard-first by instruction and no Mobile file was
   fabricated.** The handoff report is published unmodified, so it describes a section this branch does not
   carry. **This branch is not the Mobile design authority.**
3. **`_backup-admin-cc-pre-panels.dc.html.txt`**, listed in `PROVENANCE.md` as a preserved pre-panels
   snapshot, is not in the package.

## Scope and boundaries

**Six current Admin pages** — Control Center · Ecosystem · People · Trust · Operations · Settings — in
`admin-dashboard/screens/`. **Two superseded designs** retained in `screens/superseded/`, superseded status
stated by `PROVENANCE.md` and the package `README`; they are preserved deliberately and were not deleted
because newer designs exist.

`BOUNDARIES.md` records the open items (A–G) and **none is resolved here**: attention severity labels ·
Notifications placement · Platform Health vs Infrastructure · `PD-C03` currency · the five existing
Dashboard owner decisions · backend capability gaps. **`PD-G01` and `PD-A24` remain under their existing V5
authorisation.** V5 §102 applies: an approved capability is not removed, hidden, collapsed or simplified to
fit the current backend.

**No implementation, architecture reconciliation, schema, migration, application-code or production change
was made in this publication.**
