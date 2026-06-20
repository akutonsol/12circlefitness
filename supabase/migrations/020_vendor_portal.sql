-- ═══════════════════════════════════════════════════════════════════════════
-- 12 Circle Fitness — Module 15 (Vendor Portal)
-- Lets role='vendor' own and manage events, and read/check-in their attendees.
-- Idempotent — safe to run more than once.
-- ═══════════════════════════════════════════════════════════════════════════

-- 1. Event ownership.
ALTER TABLE events ADD COLUMN IF NOT EXISTS vendor_id uuid REFERENCES user_profiles(id);
CREATE INDEX IF NOT EXISTS idx_events_vendor ON events (vendor_id);

-- Attendance check-in marker on registrations (status already exists; add a
-- dedicated timestamp so vendors can record arrival without clobbering status).
ALTER TABLE event_registrations ADD COLUMN IF NOT EXISTS checked_in_at timestamptz;

-- 2. Events: keep public read, add vendor-owned write (vendors/admins only).
--    "all read events" already exists from migration 001 — leave it.
DROP POLICY IF EXISTS "vendors manage own events" ON events;
CREATE POLICY "vendors manage own events"
  ON events FOR ALL TO authenticated
  USING (vendor_id = auth.uid())
  WITH CHECK (
    vendor_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM user_profiles p
      WHERE p.id = auth.uid() AND p.role IN ('vendor', 'admin')
    )
  );

-- 3. Registrations: a vendor can read + update (check-in) registrations that
--    belong to events they own. Clients keep "users manage own registrations".
DROP POLICY IF EXISTS "vendors read own event registrations" ON event_registrations;
CREATE POLICY "vendors read own event registrations"
  ON event_registrations FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM events e
      WHERE e.id = event_registrations.event_id AND e.vendor_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "vendors check in own event registrations" ON event_registrations;
CREATE POLICY "vendors check in own event registrations"
  ON event_registrations FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM events e
      WHERE e.id = event_registrations.event_id AND e.vendor_id = auth.uid()
    )
  );
