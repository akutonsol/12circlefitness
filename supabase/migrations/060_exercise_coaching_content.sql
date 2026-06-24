-- Migration 060: structured coaching content on the exercise core row
--
-- Supports the richer "coaching" import shape: leveled coaching cues, a breathing
-- protocol, and per-goal AI tips (rep range / rest / recommendation). Stored as
-- JSONB on custom_exercises (the exercises core). Flat instructions/cues/mistakes
-- still populate the existing text[] columns for display; these preserve the
-- structured detail.

alter table custom_exercises
  add column if not exists breathing              jsonb default '{}',  -- {before_descent, during_movement, at_lockout}
  add column if not exists ai_exercise_tips       jsonb default '{}',  -- {fat_loss:{rep_range,rest_period,recommendation}, ...}
  add column if not exists coaching_cues_by_level jsonb default '{}';  -- {beginner:[], intermediate:[], advanced:[]}
