-- Enable Supabase Realtime on the tables behind the live surfaces:
-- 12 Circle Score, messages list/coach dashboard, and the coaching relationship.
-- Safe to re-run (each ADD is guarded).
DO $$ BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE user_scores;                 EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE score_events;                EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE conversations;               EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE coach_client_relationships;  EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE daily_scores;                EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE weekly_checkins;             EXCEPTION WHEN others THEN NULL; END $$;
