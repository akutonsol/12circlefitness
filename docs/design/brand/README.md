# 12Circle+ brand

| | |
|---|---|
| Master brand | **12Circle** |
| Product | **12Circle+** (a product under the 12Circle brand) |
| Tagline | **Connecting Coaches. Clients. Communities.** |

Never rename the product to 12Circle Fitness, 12Circle+ Fitness, 12Circle OS or anything else.

## Logo

Source: `assets/12circle-plus-logo.png` (imported unmodified from `uploads/12circle+.png`; the original upload is still in place).

Reading of the mark (from the file): a ring of twelve rounded triangular dots, a solid violet disc at the centre, the wordmark **12CIRCLE** in near-white and a violet **+**. The wordmark is near-white, so the lockup is for **dark grounds** only. The PNG has no transparency check recorded and no light-ground variant, one-colour variant, icon-only (app icon) crop, clear-space rule or minimum size. Those are listed as missing in `../12CIRCLE-PLUS-HANDOFF-REPORT.md`; none are invented here.

The earlier `logo-mark.svg` drawn during token extraction was **not** the approved mark and has been removed.

## Shared identity (Admin and Mobile)

- **One violet.** Brand violet `#7C3AED`; accent `#A78BFA` for text and lines on dark; hover `#C4B1FC`.
- **Dark ground.** Near-black canvas with neutral-violet greys. Both surfaces ship dark.
- **Type.** Schibsted Grotesk, weights 400/500/600, tight tracking on headings.
- **Icons.** Phosphor, regular weight; fill only for the selected state. See `icons/`.
- **Status semantics.** success = green, warning = amber, danger = red, info = blue. Never colour alone: every status carries a label or icon.
- **Accessibility.** Text 4.5:1 or better (see `tokens/admin.contrast.md`). 44px minimum controls. 2px accent focus ring. Reduced motion respected.
- **Consistency means shared identity, not identical screens.** Admin is dense and operational; Mobile is touch-first.

## Tokens

- `tokens/admin.tokens.json` and `admin.tokens.css` are **extracted from the approved Admin pages** (colour, type scale, spacing, radius, sizes, shadows, motion, breakpoints). Prefix `--adm-`.
- Mobile tokens are governed by the Fitness **Helix three-tier token** system documented in `../12CIRCLE-FITNESS-PHASE-2-DESIGN-SYSTEM.md`. Not duplicated here. Brand violet and the dark ground are common to both. Whether Admin tokens should be re-expressed as Helix tier-1 values is an **architecture question** (see boundaries).
