# Admin: unresolved boundaries (not decided here)

| # | Boundary | Classification | What is preserved |
|---|---|---|---|
| A | Attention severity: spec says Critical / High / Warning / Informational; approved screens show CRITICAL / HIGH / MEDIUM / LOW | Existing V5 decision (attention queue severity), owner decision required | Approved screens untouched; both vocabularies recorded |
| B | Notifications Overview group is in the spec; no corresponding area on the approved Dashboard | Owner decision required (placement) | Requirement kept; no placement invented |
| C | Spec "Platform Health" vs approved Dashboard "Infrastructure" | Design/product reconciliation | Both kept; health requirements not removed |
| D | PD-C03 currency | Existing V5 decision | Not duplicated |
| E | Existing V5 owner decisions: partner approval state machine; coaching revenue gross vs platform commission; attention-queue severity; store-console ingestion (PD-A24); which "impressions" | Existing V5 decisions | Referenced only |
| F | Admin data layer, AI Guardian, service health feed, CI feed, wearable (HealthKit) coverage, append-only audit store | Existing architecture requirement / implementation gap | Designs kept. Approved design requirement; implementation/architecture capability required |
| G | Admin tokens (`--adm-*`) vs Fitness Helix tiers | Architecture question | Both documented, no merge |

PD-G01 and PD-A24 remain under their existing V5 authorisation. Nothing here authorises implementation or contact with production.
