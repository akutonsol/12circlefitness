-- ═══════════════════════════════════════════════════════════════════════════
-- 12 Circle Fitness — Client Action Items (Coach Operating System)
-- Coach (or AI) assigns tasks → client completes with optional proof/notes →
-- coach is notified. Drives the Coach Dashboard completion-rate view.
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS action_items (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id    uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  coach_id     uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
  title        text NOT NULL,
  description  text DEFAULT '',
  -- onboarding | daily | weekly | nutrition | workout | accountability | community | challenge
  category     text NOT NULL DEFAULT 'daily',
  -- pending | completed
  status       text NOT NULL DEFAULT 'pending',
  points       int  NOT NULL DEFAULT 10,
  -- coach | ai | system
  created_by   text NOT NULL DEFAULT 'coach',
  proof_url    text,
  client_notes text,
  due_date     date,
  completed_at timestamptz,
  created_at   timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_action_items_client ON action_items (client_id);
CREATE INDEX IF NOT EXISTS idx_action_items_coach  ON action_items (coach_id);
CREATE INDEX IF NOT EXISTS idx_action_items_status ON action_items (status);

ALTER TABLE action_items ENABLE ROW LEVEL SECURITY;

-- Client can read + update (complete / add proof) their own items
DROP POLICY IF EXISTS "client reads own action items" ON action_items;
CREATE POLICY "client reads own action items"
  ON action_items FOR SELECT TO authenticated
  USING (client_id = auth.uid() OR coach_id = auth.uid());

DROP POLICY IF EXISTS "client updates own action items" ON action_items;
CREATE POLICY "client updates own action items"
  ON action_items FOR UPDATE TO authenticated
  USING (client_id = auth.uid());

-- Coach can create / update / delete items they own (assigned to their clients)
DROP POLICY IF EXISTS "coach manages assigned action items" ON action_items;
CREATE POLICY "coach manages assigned action items"
  ON action_items FOR ALL TO authenticated
  USING (coach_id = auth.uid());

-- Client may also self-insert (system/AI-generated onboarding tasks on their own row)
DROP POLICY IF EXISTS "client inserts own action items" ON action_items;
CREATE POLICY "client inserts own action items"
  ON action_items FOR INSERT TO authenticated
  WITH CHECK (client_id = auth.uid());

-- ── Trigger: notify CLIENT when a new action item is assigned ────────────────
CREATE OR REPLACE FUNCTION trg_notify_action_assigned()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  -- Don't notify the client about items they created for themselves
  IF NEW.created_by = 'coach' OR NEW.created_by = 'ai' THEN
    PERFORM insert_notification(
      NEW.client_id,
      'today_score',
      '🔔 New Action Item Assigned',
      NEW.title,
      jsonb_build_object('action_item_id', NEW.id, 'category', NEW.category)
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS notify_action_assigned ON action_items;
CREATE TRIGGER notify_action_assigned
  AFTER INSERT ON action_items
  FOR EACH ROW EXECUTE FUNCTION trg_notify_action_assigned();

-- ── Trigger: notify COACH when the client completes an action item ───────────
CREATE OR REPLACE FUNCTION trg_notify_action_completed()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_client_name text;
BEGIN
  IF NEW.status = 'completed' AND OLD.status IS DISTINCT FROM 'completed'
     AND NEW.coach_id IS NOT NULL THEN
    SELECT COALESCE(first_name, email, 'A client')
    INTO v_client_name FROM user_profiles WHERE id = NEW.client_id;
    PERFORM insert_notification(
      NEW.coach_id,
      'today_score',
      '✅ Action Item Completed',
      v_client_name || ' completed: ' || NEW.title,
      jsonb_build_object('action_item_id', NEW.id)
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS notify_action_completed ON action_items;
CREATE TRIGGER notify_action_completed
  AFTER UPDATE ON action_items
  FOR EACH ROW EXECUTE FUNCTION trg_notify_action_completed();

DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE action_items;
EXCEPTION WHEN others THEN NULL; END $$;
