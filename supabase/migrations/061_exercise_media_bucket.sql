-- Migration 061: storage bucket for exercise images/videos
--
-- Public-read bucket so getPublicUrl() works in the app; authenticated users
-- (coaches/admins) can upload/update/remove. Without this bucket the image and
-- video uploads on the create-exercise screen fail.

insert into storage.buckets (id, name, public)
values ('exercise-media', 'exercise-media', true)
on conflict (id) do update set public = true;

-- Public read of objects in this bucket.
drop policy if exists "exercise-media public read" on storage.objects;
create policy "exercise-media public read" on storage.objects
  for select using (bucket_id = 'exercise-media');

-- Authenticated users may upload / replace / delete in this bucket.
drop policy if exists "exercise-media auth write" on storage.objects;
create policy "exercise-media auth write" on storage.objects
  for insert to authenticated with check (bucket_id = 'exercise-media');

drop policy if exists "exercise-media auth update" on storage.objects;
create policy "exercise-media auth update" on storage.objects
  for update to authenticated using (bucket_id = 'exercise-media') with check (bucket_id = 'exercise-media');

drop policy if exists "exercise-media auth delete" on storage.objects;
create policy "exercise-media auth delete" on storage.objects
  for delete to authenticated using (bucket_id = 'exercise-media');
