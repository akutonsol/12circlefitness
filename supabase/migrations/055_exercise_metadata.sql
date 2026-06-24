-- Migration 055: richer exercise metadata (for AI/JSON-imported exercises)
--
-- Adds structured fields so an exercise definition like:
--   { equipment:[...], primary_muscles:[...], movement_pattern, exercise_type,
--     beginner_friendly, video_required, supports_pr_tracking,
--     supports_rpe_tracking }
-- can be stored. The single muscle_group/equipment columns remain (set from the
-- first array entry) for backward compatibility. The supports_* flags can drive
-- the set tracker (show/hide RPE, skip weight-PR detection for bodyweight moves).

alter table custom_exercises
  add column if not exists equipment_list       text[]  default '{}',
  add column if not exists primary_muscles       text[]  default '{}',
  add column if not exists movement_pattern       text,
  add column if not exists exercise_type          text,
  add column if not exists beginner_friendly      boolean default false,
  add column if not exists video_required         boolean default false,
  add column if not exists supports_pr_tracking   boolean default true,
  add column if not exists supports_rpe_tracking  boolean default true;
