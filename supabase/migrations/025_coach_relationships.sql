-- ═══════════════════════════════════════════════════════════════════════════
-- 12 Circle Fitness — Coach relationship: per-client pricing + specialty
-- Enables: (a) coaches setting a custom price per client (overrides their global
-- pricing_monthly), and (b) a client working with multiple coaches at once,
-- each tagged with a specialty (e.g. fitness vs nutrition).
-- Idempotent — safe to run more than once.
-- ═══════════════════════════════════════════════════════════════════════════

-- Per-client custom price. NULL = use the coach's global user_profiles.pricing_monthly.
ALTER TABLE coach_client_relationships ADD COLUMN IF NOT EXISTS monthly_price numeric;

-- What kind of coaching this relationship is for (allows nutrition + fitness etc.).
ALTER TABLE coach_client_relationships ADD COLUMN IF NOT EXISTS specialty text DEFAULT 'general';

-- Cancellation bookkeeping (used by the client-side "stop working together").
ALTER TABLE coach_client_relationships ADD COLUMN IF NOT EXISTS cancelled_by text;
ALTER TABLE coach_client_relationships ADD COLUMN IF NOT EXISTS cancel_reason text;
ALTER TABLE coach_client_relationships ADD COLUMN IF NOT EXISTS cancel_reason_custom text;
ALTER TABLE coach_client_relationships ADD COLUMN IF NOT EXISTS cancelled_at timestamptz;

CREATE INDEX IF NOT EXISTS idx_ccr_client_status ON coach_client_relationships (client_id, status);
