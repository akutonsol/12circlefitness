-- Migration 050: admin moderation for the Global Exercise Library (EL-005)
--
-- Coaches submit exercises to the global library (submission_status='pending').
-- Admins need to see the pending queue and approve/reject. The 005 RLS only let
-- coaches manage their own rows, so admins couldn't read pending submissions or
-- flip submission_status. These policies grant org admins (is_admin()) read +
-- update across custom_exercises. The existing "notify coach when approved"
-- trigger then fires on approval.

drop policy if exists "admin read all exercises" on custom_exercises;
create policy "admin read all exercises"
  on custom_exercises for select to authenticated
  using (public.is_admin());

drop policy if exists "admin moderate exercises" on custom_exercises;
create policy "admin moderate exercises"
  on custom_exercises for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());
