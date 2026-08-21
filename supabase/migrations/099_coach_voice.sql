-- ═══════════════════════════════════════════════════════════════════════════
-- Migration 099 — Coach Audio Coaching (Exercise Audio, Phase 2 of layered media)
--
-- A coach records a short voice note on an exercise; every client performing it
-- hears their coach. voice_url already exists (097); this adds duration + an
-- auto-expiration so libraries stay clean. The resolver hides expired audio.
--
-- Depends on 097. Idempotent.
-- ═══════════════════════════════════════════════════════════════════════════

alter table coach_exercise_media add column if not exists voice_duration_ms int;
alter table coach_exercise_media add column if not exists voice_expires_at   timestamptz;  -- null = never

-- Resolver: same as 097 but voice is nulled out once expired.
create or replace function public.resolve_exercise_media(p_exercise_id uuid, p_viewer_id uuid)
returns jsonb language sql stable security definer as $$
  select coalesce((
    select jsonb_build_object(
      'has_coach_overlay', true,
      'coach_id', m.coach_id,
      'coach_name', up.first_name,
      'note', m.note,
      'focus', to_jsonb(coalesce(m.focus, '{}')),
      'video_ref', m.video_ref,
      'voice_url', case when m.voice_expires_at is null or m.voice_expires_at > now()
                        then m.voice_url else null end,
      'voice_duration_ms', case when m.voice_expires_at is null or m.voice_expires_at > now()
                                then m.voice_duration_ms else null end,
      'updated_at', m.updated_at)
    from coach_client_relationships r
    join coach_exercise_media m on m.coach_id = r.coach_id and m.exercise_id = p_exercise_id
    join user_profiles up on up.id = m.coach_id
    where r.client_id = p_viewer_id and r.status = 'active'
    order by r.activated_at desc nulls last
    limit 1),
    jsonb_build_object('has_coach_overlay', false));
$$;
grant execute on function public.resolve_exercise_media(uuid, uuid) to authenticated;
