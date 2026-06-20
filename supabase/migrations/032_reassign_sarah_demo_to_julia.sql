-- Remove the seeded demo coach "Sarah Johnson" (sarah@marketplace.test) from
-- view by re-homing her demo content onto Julia. Safe + idempotent: if either
-- account is missing it does nothing. Does not delete profiles (avoids FK
-- cascade surprises) — the app hides @marketplace.test accounts from Members.
DO $$
DECLARE
  v_sarah uuid;
  v_julia uuid;
BEGIN
  SELECT id INTO v_sarah FROM user_profiles
    WHERE lower(email) = 'sarah@marketplace.test'
       OR (lower(trim(first_name)) = 'sarah' AND lower(trim(last_name)) = 'johnson')
    LIMIT 1;
  SELECT id INTO v_julia FROM user_profiles
    WHERE lower(trim(first_name)) LIKE 'julia%' OR lower(trim(last_name)) LIKE 'julia%'
    LIMIT 1;

  IF v_sarah IS NULL OR v_julia IS NULL OR v_sarah = v_julia THEN
    RETURN;
  END IF;

  -- Community content authored by Sarah → Julia.
  UPDATE community_posts SET user_id  = v_julia WHERE user_id  = v_sarah;
  UPDATE post_comments   SET user_id  = v_julia WHERE user_id  = v_sarah;
  -- Reactions are just counts; drop Sarah's to avoid (post_id,user_id) clashes.
  DELETE FROM post_reactions WHERE user_id = v_sarah;

  -- Her seeded group class → Julia (so it shows under a real coach in Classes).
  UPDATE classes SET coach_id = v_julia WHERE coach_id = v_sarah;
END $$;
