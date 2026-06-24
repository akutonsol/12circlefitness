-- Migration 071: backfill slugs for slug-less exercises
--
-- Manually-created exercises saved before slug logic have NULL slug, so the AI-
-- enrich FAB (which keys on slug) couldn't target them. Derive a slug from the
-- name, deduped per coach (…-2, …-3 for same-coach same-name rows).

with ranked as (
  select id,
    lower(trim(both '-' from regexp_replace(trim(name), '[^a-zA-Z0-9]+', '-', 'g'))) as base,
    row_number() over (
      partition by coach_id,
        lower(trim(both '-' from regexp_replace(trim(name), '[^a-zA-Z0-9]+', '-', 'g')))
      order by created_at) as rn
  from custom_exercises
  where slug is null or slug = ''
)
update custom_exercises ce
set slug = case when r.rn = 1 then r.base else r.base || '-' || r.rn end
from ranked r
where ce.id = r.id;
