# Admin responsive behaviour

Designed for **desktop first** (1440 reference). Breakpoints found in the approved pages:

| Max width | What changes |
|---|---|
| 1439px | Content width relaxes from the 1440 reference |
| 1400px | Wide grids drop a column |
| 1199 / 1180px | Two-column layouts collapse; side panels stack under content |
| 1100px | Dense tables get horizontal scroll inside their card; tile rows wrap |
| 900px | Navigation collapses to a compact bar; single-column; touch targets 44px |

Rules: tables scroll inside their own card, never the page; no horizontal page scroll at any width; `prefers-reduced-motion` removes animation. A phone layout below 480px has **not** been separately designed for Admin (Admin is an operator tool); recorded as a gap.
