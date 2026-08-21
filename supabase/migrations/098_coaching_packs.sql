-- ═══════════════════════════════════════════════════════════════════════════
-- Migration 098 — Coach Coaching Packs (reusable cue sets)
--
-- A coach saves a named set of focus cues once ("Julia Squat Cues") and applies
-- it across many exercises (back/front/goblet/safety-bar squat) instead of
-- retyping. Applying a pack simply writes the exercise's coach overlay focus
-- (coach_exercise_media.focus) — no new render path, consistent coaching.
--
-- Depends on 097. Idempotent.
-- ═══════════════════════════════════════════════════════════════════════════

create table if not exists coach_coaching_packs (
  id         uuid primary key default gen_random_uuid(),
  coach_id   uuid not null references user_profiles(id) on delete cascade,
  name       text not null,
  cues       text[] default '{}',
  created_at timestamptz default now()
);
create index if not exists idx_packs_coach on coach_coaching_packs(coach_id, created_at desc);

alter table coach_coaching_packs enable row level security;
drop policy if exists "coach packs own rw" on coach_coaching_packs;
create policy "coach packs own rw" on coach_coaching_packs for all to authenticated
  using (coach_id = auth.uid()) with check (coach_id = auth.uid());
