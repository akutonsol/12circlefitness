-- Bulk video enrichment: a lightweight name→video lookup so ANY exercise (the
-- hardcoded Dart library, the exercise guides, and DB custom_exercises) can be
-- given a real, embeddable form-tutorial video without re-keying the whole
-- catalog into the DB. Ids are resolved from the YouTube Data API by the
-- `enrich-exercise-videos` edge function (never AI-invented) and cached here.

create table if not exists public.exercise_videos (
  name_key   text primary key,          -- lowercased, trimmed exercise name
  name       text not null,             -- original display name (for audit)
  youtube_id text,                      -- 11-char embeddable id, null until resolved
  title      text,                      -- resolved video title (audit / debugging)
  channel    text,                      -- resolved channel title (audit)
  source     text not null default 'youtube_search',
  updated_at timestamptz not null default now()
);

alter table public.exercise_videos enable row level security;

-- Any signed-in user may read (the app resolves the in-app video from here).
drop policy if exists exercise_videos_read on public.exercise_videos;
create policy exercise_videos_read
  on public.exercise_videos for select
  to authenticated
  using (true);

-- Writes happen only from the enricher edge function via the service role, which
-- bypasses RLS. No client insert/update/delete policy is granted on purpose.
