-- ════════════════════════════════════════════════════════════════════════
-- Avatars storage bucket. Profile-photo uploads (client + coach) write to
-- `avatars` at path `<uid>/avatar.<ext>`, but the bucket was never created —
-- so every avatar upload failed. Create it (public read) with owner-scoped
-- write policies. Idempotent.
-- ════════════════════════════════════════════════════════════════════════

INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Public read (avatars are shown across the app via public URLs).
DROP POLICY IF EXISTS "avatars read" ON storage.objects;
CREATE POLICY "avatars read" ON storage.objects FOR SELECT TO public
  USING (bucket_id = 'avatars');

-- A user may upload/replace/delete only files under their own <uid>/ folder.
DROP POLICY IF EXISTS "avatars insert own" ON storage.objects;
CREATE POLICY "avatars insert own" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "avatars update own" ON storage.objects;
CREATE POLICY "avatars update own" ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "avatars delete own" ON storage.objects;
CREATE POLICY "avatars delete own" ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);
