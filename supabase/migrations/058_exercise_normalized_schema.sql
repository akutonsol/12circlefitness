-- Migration 058: normalized exercise schema (scales to 100k+ exercises)
--
-- custom_exercises remains the core "exercises" row (scalar fields + RLS + global
-- library approval + workout integrations). Multi-valued / relational data is
-- normalized into child tables so AI recommendations, advanced search, and
-- filtering are fast joins/indexes instead of JSONB scans:
--   exercise_muscles, exercise_equipment, exercise_tags, exercise_media,
--   exercise_substitutions, exercise_progressions, exercise_modifications,
--   exercise_analytics, exercise_reviews.
-- A convenience view `exercises` aliases custom_exercises.

-- A few additional scalar columns on the core row.
alter table custom_exercises
  add column if not exists organization_id              uuid,
  add column if not exists space_requirements           text,
  add column if not exists estimated_setup_time_seconds int,
  add column if not exists estimated_execution_time_seconds int,
  add column if not exists supports_progress_tracking   boolean default true,
  add column if not exists supports_ai_recommendations  boolean default true,
  add column if not exists exercise_scoring             jsonb default '{}',
  add column if not exists achievement_triggers         text[] default '{}';

create or replace view public.exercises as select * from custom_exercises;

-- ── RLS helpers (a child row inherits its parent's readability/writability) ──
create or replace function public.exercise_readable(eid uuid)
returns boolean language sql stable security definer as $$
  select exists (
    select 1 from custom_exercises ce where ce.id = eid and (
      (ce.visibility = 'global' and ce.submission_status = 'approved')
      or ce.coach_id = auth.uid()
      or public.is_admin()));
$$;

create or replace function public.exercise_writable(eid uuid)
returns boolean language sql stable security definer as $$
  select exists (
    select 1 from custom_exercises ce where ce.id = eid and (
      ce.coach_id = auth.uid() or public.is_admin()));
$$;

-- ── Child tables ──
create table if not exists exercise_muscles (
  exercise_id uuid not null references custom_exercises(id) on delete cascade,
  muscle      text not null,
  role        text not null default 'primary', -- primary | secondary
  primary key (exercise_id, muscle, role)
);

create table if not exists exercise_equipment (
  exercise_id uuid not null references custom_exercises(id) on delete cascade,
  equipment   text not null,
  requirement text not null default 'required', -- required | optional
  category    text,
  primary key (exercise_id, equipment)
);

-- Polymorphic tags: subcategory | goal | sport | experience | body_region |
-- joint_action | movement | search_keyword
create table if not exists exercise_tags (
  exercise_id uuid not null references custom_exercises(id) on delete cascade,
  tag         text not null,
  tag_type    text not null,
  primary key (exercise_id, tag, tag_type)
);

create table if not exists exercise_media (
  id          uuid primary key default gen_random_uuid(),
  exercise_id uuid not null references custom_exercises(id) on delete cascade,
  media_type  text not null,            -- video | image | voiceover
  role        text,                     -- demo | cover | form_correction | youtube | vimeo
  url         text not null,
  difficulty  text,
  issue       text,                     -- for form_correction
  sort_order  int default 0,
  created_at  timestamptz default now()
);

create table if not exists exercise_substitutions (
  exercise_id      uuid not null references custom_exercises(id) on delete cascade,
  substitute_name  text not null,
  substitution_type text not null default 'same_movement', -- same_movement | machine_based | bodyweight | related
  primary key (exercise_id, substitute_name, substitution_type)
);

create table if not exists exercise_progressions (
  exercise_id     uuid not null references custom_exercises(id) on delete cascade,
  name            text not null,
  progression_type text not null default 'progression', -- progression | regression | beginner_mod
  primary key (exercise_id, name, progression_type)
);

create table if not exists exercise_modifications (
  id          uuid primary key default gen_random_uuid(),
  exercise_id uuid not null references custom_exercises(id) on delete cascade,
  modification_type text not null,      -- injury | contraindication | warmup | cooldown | mobility
  condition   text,
  recommendation text
);

create table if not exists exercise_analytics (
  exercise_id     uuid primary key references custom_exercises(id) on delete cascade,
  times_performed int     default 0,
  average_weight  numeric default 0,
  average_reps    numeric default 0,
  average_rpe     numeric default 0,
  completion_rate numeric default 0,
  updated_at      timestamptz default now()
);

create table if not exists exercise_reviews (
  id          uuid primary key default gen_random_uuid(),
  exercise_id uuid not null references custom_exercises(id) on delete cascade,
  reviewer_id uuid references user_profiles(id),
  status      text not null default 'submitted', -- submitted | approved | rejected
  notes       text,
  created_at  timestamptz default now()
);

-- ── Indexes (search / filter / join) ──
create index if not exists idx_ex_muscles_muscle    on exercise_muscles (muscle, role);
create index if not exists idx_ex_muscles_exercise  on exercise_muscles (exercise_id);
create index if not exists idx_ex_equip_equipment   on exercise_equipment (equipment, requirement);
create index if not exists idx_ex_equip_exercise    on exercise_equipment (exercise_id);
create index if not exists idx_ex_tags_tag          on exercise_tags (tag, tag_type);
create index if not exists idx_ex_tags_exercise     on exercise_tags (exercise_id);
create index if not exists idx_ex_media_exercise    on exercise_media (exercise_id, media_type);
create index if not exists idx_ex_subs_exercise     on exercise_substitutions (exercise_id);
create index if not exists idx_ex_subs_name         on exercise_substitutions (substitute_name);
create index if not exists idx_ex_prog_exercise     on exercise_progressions (exercise_id);
create index if not exists idx_ex_mods_exercise     on exercise_modifications (exercise_id, modification_type);
create index if not exists idx_ex_reviews_status    on exercise_reviews (status);

-- ── RLS ──
do $$
declare t text;
begin
  foreach t in array array[
    'exercise_muscles','exercise_equipment','exercise_tags','exercise_media',
    'exercise_substitutions','exercise_progressions','exercise_modifications',
    'exercise_analytics','exercise_reviews'] loop
    execute format('alter table %I enable row level security', t);
    execute format($f$drop policy if exists "read exercise child" on %I$f$, t);
    execute format($f$create policy "read exercise child" on %I for select to authenticated using (public.exercise_readable(exercise_id))$f$, t);
    execute format($f$drop policy if exists "write exercise child" on %I$f$, t);
    execute format($f$create policy "write exercise child" on %I for all to authenticated using (public.exercise_writable(exercise_id)) with check (public.exercise_writable(exercise_id))$f$, t);
  end loop;
end $$;
