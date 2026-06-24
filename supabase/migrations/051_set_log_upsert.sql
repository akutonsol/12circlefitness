-- Migration 051: make a logged set uniquely addressable so edits upsert
--
-- Set logs were INSERT-only and saved only at the moment a set was marked
-- complete, so editing weight/RPE/notes (or adding a note after completing)
-- didn't persist, and re-completing a set created duplicate rows. A unique key
-- on (session_id, exercise_name, set_number) lets the app upsert: one row per
-- set, updated whenever the client edits it.

-- De-dup any existing rows first (keep the most recent per set).
delete from workout_set_logs a
using workout_set_logs b
where a.session_id is not null
  and a.session_id   = b.session_id
  and a.exercise_name = b.exercise_name
  and a.set_number    = b.set_number
  and a.logged_at     < b.logged_at;

create unique index if not exists uq_workout_set_logs_set
  on workout_set_logs (session_id, exercise_name, set_number);
