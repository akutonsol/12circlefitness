-- ═══════════════════════════════════════════════════════════════════════════
-- 12 Circle Fitness — Module 14 (Speaker / Session Management)
-- Adds an agenda to events: scheduled sessions, each with a speaker. The event
-- owner (vendor) manages sessions; any authenticated user can read the agenda
-- (events are public-read, so their agenda should be too).
-- Idempotent — safe to run more than once.
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS event_sessions (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id          uuid NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  title             text NOT NULL,
  description       text,
  speaker_name      text,
  speaker_title     text,
  speaker_avatar_url text,
  track             text,                 -- e.g. room / stage / track label
  starts_at         timestamptz,
  ends_at           timestamptz,
  sort_order        int DEFAULT 0,
  created_at        timestamptz DEFAULT now(),
  updated_at        timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_event_sessions_event ON event_sessions (event_id, sort_order);

ALTER TABLE event_sessions ENABLE ROW LEVEL SECURITY;

-- Public read: anyone authenticated can view an event's agenda.
DROP POLICY IF EXISTS "all read sessions" ON event_sessions;
CREATE POLICY "all read sessions"
  ON event_sessions FOR SELECT TO authenticated
  USING (true);

-- Only the owning vendor (or admin) can create/update/delete sessions.
DROP POLICY IF EXISTS "vendors manage own event sessions" ON event_sessions;
CREATE POLICY "vendors manage own event sessions"
  ON event_sessions FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM events e
      WHERE e.id = event_sessions.event_id AND e.vendor_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM events e
      WHERE e.id = event_sessions.event_id AND e.vendor_id = auth.uid()
    )
  );

DROP TRIGGER IF EXISTS event_sessions_updated_at ON event_sessions;
CREATE TRIGGER event_sessions_updated_at
  BEFORE UPDATE ON event_sessions
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
