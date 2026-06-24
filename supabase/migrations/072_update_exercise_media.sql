-- Migration 072: coach-accessible media updates
--
-- AI-generated text content on platform exercises is admin-managed, but coaches
-- should be able to attach their own images/videos to any exercise. This
-- SECURITY DEFINER RPC updates ONLY the media columns (image_url,
-- video_variants) and is gated to coach/admin roles — so coaches can add media
-- without the ability to edit the AI text (which RLS still restricts to
-- owners/admins).

create or replace function public.update_exercise_media(
  p_id uuid, p_image_url text, p_video_variants jsonb)
returns boolean language plpgsql security definer as $$
declare v_role text;
begin
  select role into v_role from user_profiles where id = auth.uid();
  if v_role not in ('coach', 'admin') then
    raise exception 'not authorized to add media';
  end if;
  update custom_exercises set
    image_url      = coalesce(p_image_url, image_url),
    video_variants = coalesce(p_video_variants, video_variants)
  where id = p_id;
  return found;
end;
$$;

grant execute on function public.update_exercise_media(uuid, text, jsonb) to authenticated;
