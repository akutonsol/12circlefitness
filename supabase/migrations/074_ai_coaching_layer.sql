-- Migration 074: AI Coaching intelligence layer
--
-- A coaching-intelligence layer (not a chatbot). Separate tables that the engine
-- reads (profile/goals/adherence/recovery/memory) and writes (insights, reviews,
-- goal predictions). Decoupled from the exercise schema: exercises power
-- workouts; this powers decision-making + personalization.

-- ── ai_profiles: persona, goals, preferences, behavioral patterns (1 per user) ──
create table if not exists ai_profiles (
  user_id    uuid primary key references user_profiles(id) on delete cascade,
  coach_persona jsonb default '{"name":"Nova","style":"motivational","tone":"supportive"}',
  goals      jsonb default '{}',   -- {primary_goal, secondary_goal, target_weight, target_date, weekly_rate}
  preferences jsonb default '{}',  -- {favorite_exercises, disliked_exercises, available_equipment, training_days}
  behavioral_patterns jsonb default '{}', -- {missed_workout_day, best_adherence_day, average_workout_time}
  last_review_at timestamptz,
  updated_at timestamptz default now(),
  created_at timestamptz default now()
);

-- ── ai_memories: durable facts the coach remembers ──
create table if not exists ai_memories (
  id      uuid primary key default gen_random_uuid(),
  user_id uuid not null references user_profiles(id) on delete cascade,
  kind    text not null,   -- like | dislike | injury | preference | constraint | note
  content text not null,
  source  text default 'inferred',  -- user | inferred | coach
  created_at timestamptz default now(),
  unique (user_id, kind, content)
);

-- ── ai_insights: daily coaching insights + targeted recommendations ──
create table if not exists ai_insights (
  id      uuid primary key default gen_random_uuid(),
  user_id uuid not null references user_profiles(id) on delete cascade,
  type    text not null default 'daily_insight', -- daily_insight | workout_adjustment | nutrition_adjustment | recovery | accountability
  title   text,
  body    text,
  data    jsonb default '{}',   -- structured payload, e.g. {intensity_delta:-10, focus:"upper"}
  for_date date default current_date,
  dismissed boolean default false,
  created_at timestamptz default now()
);

-- ── ai_reviews: weekly reviews ──
create table if not exists ai_reviews (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references user_profiles(id) on delete cascade,
  period_start date not null,
  period_end   date not null,
  summary      text,
  metrics      jsonb default '{}', -- {workouts_completed, workouts_planned, habit_adherence, weight_change, ...}
  created_at   timestamptz default now()
);

-- ── ai_goal_predictions: goal-prediction engine output ──
create table if not exists ai_goal_predictions (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references user_profiles(id) on delete cascade,
  current_weight numeric,
  target_weight  numeric,
  current_pace   numeric,           -- e.g. lbs/week (signed)
  projected_date date,
  confidence     int,               -- 0-100
  summary        text,
  created_at     timestamptz default now()
);

create index if not exists idx_ai_insights_user_date on ai_insights (user_id, for_date desc);
create index if not exists idx_ai_reviews_user        on ai_reviews (user_id, period_end desc);
create index if not exists idx_ai_predictions_user    on ai_goal_predictions (user_id, created_at desc);
create index if not exists idx_ai_memories_user       on ai_memories (user_id, kind);

-- ── RLS: a user owns their AI coaching data ──
do $$
declare t text;
begin
  foreach t in array array['ai_profiles','ai_memories','ai_insights','ai_reviews','ai_goal_predictions'] loop
    execute format('alter table %I enable row level security', t);
    execute format($f$drop policy if exists "own ai data" on %I$f$, t);
    execute format($f$create policy "own ai data" on %I for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid())$f$, t);
  end loop;
end $$;
