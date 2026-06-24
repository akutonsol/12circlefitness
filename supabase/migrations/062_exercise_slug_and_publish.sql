-- Migration 062: per-coach unique slug + publish coach-global exercises
--
-- 1. The global unique slug index made re-imports collide (and the app then
--    created numbered duplicates). Scope uniqueness to (coach_id, slug) so a
--    coach re-importing the same exercise updates their existing row, while
--    different coaches can still have an exercise with the same slug.
-- 2. Setting visibility='global' left submission_status NULL, so the "clients
--    read global + approved" RLS hid it. Publish existing coach-global
--    exercises so they become visible to clients.

drop index if exists uq_custom_exercises_slug;

create unique index if not exists uq_custom_exercises_coach_slug
  on custom_exercises (coach_id, slug);

update custom_exercises
  set submission_status = 'approved'
  where visibility = 'global' and submission_status is distinct from 'approved';
