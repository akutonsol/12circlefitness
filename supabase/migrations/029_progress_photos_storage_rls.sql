-- Storage RLS for the private `progress-photos` bucket.
-- A user fully manages files in their own `<uid>/...` folder (select/insert/
-- update/delete) so they can ADD and REPLACE baseline + gallery photos, and a
-- coach can READ their active clients' photos (needed to createSignedUrl).
-- The folder name (first path segment) is the owner's user id.

-- ── Owner: full CRUD on own folder ──────────────────────────────────────────
DROP POLICY IF EXISTS "own progress photos select" ON storage.objects;
CREATE POLICY "own progress photos select"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'progress-photos'
         AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "own progress photos insert" ON storage.objects;
CREATE POLICY "own progress photos insert"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'progress-photos'
              AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "own progress photos update" ON storage.objects;
CREATE POLICY "own progress photos update"
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'progress-photos'
         AND (storage.foldername(name))[1] = auth.uid()::text)
  WITH CHECK (bucket_id = 'progress-photos'
              AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "own progress photos delete" ON storage.objects;
CREATE POLICY "own progress photos delete"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'progress-photos'
         AND (storage.foldername(name))[1] = auth.uid()::text);

-- ── Coach: read an active client's photos ───────────────────────────────────
DROP POLICY IF EXISTS "coach reads client progress photos" ON storage.objects;
CREATE POLICY "coach reads client progress photos"
  ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'progress-photos'
    AND EXISTS (
      SELECT 1 FROM coach_client_relationships r
      WHERE r.coach_id = auth.uid()
        AND r.client_id::text = (storage.foldername(name))[1]
    )
  );
