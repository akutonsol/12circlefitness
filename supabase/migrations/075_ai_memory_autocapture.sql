-- Migration 075: auto-capture coaching memory
--
-- Memory fills itself from existing signals so the AI coach gets smarter without
-- the user re-entering everything:
--   • injuries from the user's profile (has_injuries / injury_locations)
--   • session notes from workout_feedback
-- Both write into ai_memories (dedup via the unique key). SECURITY DEFINER so
-- they bypass RLS for the insert.

-- ── Injuries from the profile ──
create or replace function public.capture_injury_memory()
returns trigger language plpgsql security definer as $$
begin
  if NEW.has_injuries and coalesce(NEW.injury_locations, '') <> '' then
    insert into ai_memories (user_id, kind, content, source)
    select NEW.id, 'injury', trim(loc), 'inferred'
      from unnest(string_to_array(NEW.injury_locations, ',')) loc
      where trim(loc) <> ''
    on conflict (user_id, kind, content) do nothing;
  end if;
  if NEW.has_injuries and coalesce(NEW.injury_description, '') <> '' then
    insert into ai_memories (user_id, kind, content, source)
    values (NEW.id, 'note', left(NEW.injury_description, 240), 'inferred')
    on conflict (user_id, kind, content) do nothing;
  end if;
  return NEW;
end;
$$;

drop trigger if exists trg_capture_injury_memory on user_profiles;
create trigger trg_capture_injury_memory
  after insert or update of has_injuries, injury_locations, injury_description
  on user_profiles
  for each row execute function public.capture_injury_memory();

-- ── Session notes from workout feedback ──
create or replace function public.capture_feedback_memory()
returns trigger language plpgsql security definer as $$
begin
  if coalesce(NEW.notes, '') <> '' and NEW.user_id is not null then
    insert into ai_memories (user_id, kind, content, source)
    values (NEW.user_id, 'note', left(NEW.notes, 240), 'inferred')
    on conflict (user_id, kind, content) do nothing;
  end if;
  return NEW;
end;
$$;

drop trigger if exists trg_capture_feedback_memory on workout_feedback;
create trigger trg_capture_feedback_memory
  after insert on workout_feedback
  for each row execute function public.capture_feedback_memory();

-- ── Backfill existing injuries into memory (one-time) ──
insert into ai_memories (user_id, kind, content, source)
select id, 'injury', trim(loc), 'inferred'
  from user_profiles, unnest(string_to_array(injury_locations, ',')) loc
  where has_injuries and coalesce(injury_locations, '') <> '' and trim(loc) <> ''
on conflict (user_id, kind, content) do nothing;
