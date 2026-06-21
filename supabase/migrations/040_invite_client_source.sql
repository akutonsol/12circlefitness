-- ════════════════════════════════════════════════════════════════════════
-- Invite Client Flow → client_source = 'coach_invited' (0% marketplace commission).
-- Any relationship whose client was invited by that same coach (an existing
-- coach_invite matching the client's email) is automatically tagged
-- 'coach_invited'. This drives a 0% commission everywhere downstream
-- (create-checkout reads the relationship's client_source). Covers every path
-- that creates a relationship: client request approval, coach-added client, or
-- invite acceptance.
-- Idempotent.
-- ════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION set_relationship_client_source()
RETURNS trigger AS $$
BEGIN
  -- Only auto-decide when the caller didn't explicitly tag the source.
  IF NEW.client_source IS NULL OR NEW.client_source = 'marketplace' THEN
    IF EXISTS (
      SELECT 1
        FROM coach_invites i
        JOIN user_profiles p ON p.id = NEW.client_id
       WHERE i.coach_id = NEW.coach_id
         AND lower(i.invitee_email) = lower(p.email)
    ) THEN
      NEW.client_source := 'coach_invited';
    ELSE
      NEW.client_source := COALESCE(NEW.client_source, 'marketplace');
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_relationship_client_source ON coach_client_relationships;
CREATE TRIGGER trg_relationship_client_source
  BEFORE INSERT ON coach_client_relationships
  FOR EACH ROW EXECUTE FUNCTION set_relationship_client_source();

-- Re-run the backfill (idempotent) in case 040 lands before any new signups.
UPDATE coach_client_relationships r
   SET client_source = 'coach_invited'
  FROM coach_invites i
 WHERE i.coach_id = r.coach_id
   AND lower(i.invitee_email) = (SELECT lower(email) FROM user_profiles p WHERE p.id = r.client_id)
   AND r.client_source = 'marketplace';
