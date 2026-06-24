-- Migration 057: enterprise exercise master schema
--
-- Extends custom_exercises into the foundation for the Workout Builder, AI Coach,
-- Program Generator, Progress/PR tracking, injury-aware recommendations, and the
-- exercise marketplace. Design = typed columns + GIN indexes for everything AI/
-- search/filtering queries, JSONB for rich nested content. All additive +
-- idempotent; existing columns (instructions, coaching_cues, video_variants,
-- supports_pr/rpe_tracking, movement_pattern, exercise_type, primary_muscles…)
-- are reused.

alter table custom_exercises
  -- Identity / lifecycle
  add column if not exists slug                     text,
  add column if not exists status                   text default 'published', -- draft | published | archived
  -- Classification (filterable)
  add column if not exists subcategories            text[] default '{}',
  add column if not exists body_region              text[] default '{}',
  add column if not exists goal_tags                text[] default '{}',
  add column if not exists experience_levels        text[] default '{}',
  add column if not exists sports_relevance         text[] default '{}',
  add column if not exists contraindications        text[] default '{}',  -- injury-aware
  -- Equipment (master splits required vs optional)
  add column if not exists equipment_required       text[] default '{}',
  add column if not exists equipment_optional        text[] default '{}',
  -- Variations / progressions (arrays)
  add column if not exists beginner_modifications   text[] default '{}',
  add column if not exists advanced_progressions    text[] default '{}',
  add column if not exists warmup_recommendations   text[] default '{}',
  add column if not exists cooldown_recommendations text[] default '{}',
  add column if not exists tempo_options            text[] default '{}',
  add column if not exists badges                   text[] default '{}',
  add column if not exists training_effect          text[] default '{}',
  -- Prescription / energetics
  add column if not exists default_rest_seconds     int,
  add column if not exists estimated_calories_per_set numeric,
  add column if not exists supports_volume_tracking boolean default true,
  -- AI scoring (promoted from ai_metadata for fast querying)
  add column if not exists fatigue_score            int,
  add column if not exists complexity_score         int,
  add column if not exists recovery_demand          int,
  -- Rich nested content (JSONB)
  add column if not exists common_mistakes_detailed jsonb default '[]',  -- [{mistake, correction}]
  add column if not exists substitutions            jsonb default '{}',  -- {same_equipment, less_equipment, machine_based}
  add column if not exists video_assets             jsonb default '[]',
  add column if not exists image_assets             jsonb default '[]',
  add column if not exists form_correction_videos   jsonb default '[]',
  add column if not exists mobility_videos          jsonb default '[]',
  add column if not exists supports_tracking        jsonb default '{}',  -- {weight, reps, sets, rpe, time, distance}
  add column if not exists ai_metadata              jsonb default '{}',
  add column if not exists recommended_frequency    jsonb default '{}',
  add column if not exists recommended_rep_ranges   jsonb default '{}',
  add column if not exists recommended_rpe          jsonb default '{}',
  add column if not exists analytics                jsonb default '{}';

-- Unique slug per published exercise (where set).
create unique index if not exists uq_custom_exercises_slug
  on custom_exercises (slug) where slug is not null;

-- GIN indexes for the array/jsonb fields AI + search + filtering hit.
create index if not exists idx_cx_primary_muscles    on custom_exercises using gin (primary_muscles);
create index if not exists idx_cx_secondary_muscles  on custom_exercises using gin (secondary_muscles);
create index if not exists idx_cx_equipment_required on custom_exercises using gin (equipment_required);
create index if not exists idx_cx_goal_tags          on custom_exercises using gin (goal_tags);
create index if not exists idx_cx_experience_levels  on custom_exercises using gin (experience_levels);
create index if not exists idx_cx_contraindications  on custom_exercises using gin (contraindications);
create index if not exists idx_cx_body_region        on custom_exercises using gin (body_region);
create index if not exists idx_cx_subcategories      on custom_exercises using gin (subcategories);
create index if not exists idx_cx_sports_relevance   on custom_exercises using gin (sports_relevance);
create index if not exists idx_cx_ai_metadata        on custom_exercises using gin (ai_metadata);

-- Btree for the common equality/sort filters.
create index if not exists idx_cx_status           on custom_exercises (status);
create index if not exists idx_cx_movement_pattern on custom_exercises (movement_pattern);
create index if not exists idx_cx_exercise_type    on custom_exercises (exercise_type);
create index if not exists idx_cx_difficulty       on custom_exercises (difficulty);
