-- Migration 044: handle_new_user — support OAuth (Google/Apple) metadata
--
-- Email signup passes first_name/last_name/role in raw_user_meta_data.
-- OAuth providers don't: Google sends given_name/family_name/full_name/name
-- and a photo under picture/avatar_url; Apple sends name only on first consent.
-- Without this, OAuth users were created as first_name='User' with no avatar.
-- This rewrite reads both key sets and backfills the avatar from the provider.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
as $function$
declare
  v_meta  jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  v_full  text  := coalesce(v_meta->>'full_name', v_meta->>'name', '');
  v_first text;
  v_last  text;
  v_avatar text;
begin
  v_first := coalesce(
    v_meta->>'first_name',
    v_meta->>'given_name',
    nullif(split_part(v_full, ' ', 1), ''),
    'User'
  );
  v_last := coalesce(
    v_meta->>'last_name',
    v_meta->>'family_name',
    nullif(trim(substr(v_full, length(split_part(v_full, ' ', 1)) + 1)), ''),
    ''
  );
  v_avatar := coalesce(v_meta->>'avatar_url', v_meta->>'picture');

  insert into public.user_profiles (id, first_name, last_name, email, role, avatar_url)
  values (
    new.id,
    v_first,
    v_last,
    new.email,
    coalesce(v_meta->>'role', 'client'),
    v_avatar
  );
  return new;
end;
$function$;
