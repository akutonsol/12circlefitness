-- Migration 076: overnight AI coaching generation (pg_cron, active users only)
--
-- Generates daily briefs each morning and weekly reviews on Mondays for users
-- who were ACTIVE in the last 14 days (a workout session or a daily score), so
-- briefs are ready instantly when they open the app — without billing Claude for
-- inactive users.
--
-- ⚠️ ONE-TIME SETUP: store the project's service_role key in Vault so the cron
-- can authenticate to the edge function (run once, with your real key):
--   select vault.create_secret('<SERVICE_ROLE_KEY>', 'service_role_key');
-- The function no-ops with a notice until that secret exists.

create extension if not exists pg_cron;
create extension if not exists pg_net;

create or replace function public.ai_cron_generate(p_type text)
returns void language plpgsql security definer
set search_path = public, extensions, vault as $$
declare
  v_key text;
  v_url text := 'https://nxdbooufqzkpslkcogxc.supabase.co/functions/v1/ai-coaching-engine';
  u record;
begin
  select decrypted_secret into v_key from vault.decrypted_secrets where name = 'service_role_key';
  if v_key is null then
    raise notice 'ai_cron_generate: vault secret "service_role_key" not set — skipping';
    return;
  end if;

  for u in
    select id from (
      select distinct user_id as id from workout_sessions where created_at > now() - interval '14 days'
      union
      select distinct user_id from daily_scores where score_date > current_date - 14
    ) active where id is not null
  loop
    perform net.http_post(
      url     := v_url,
      headers := jsonb_build_object('Content-Type', 'application/json', 'Authorization', 'Bearer ' || v_key),
      body    := jsonb_build_object('type', p_type, 'user_id', u.id));
  end loop;
end;
$$;

-- Daily briefs at 06:00 UTC; weekly reviews Monday 07:00 UTC. Reschedule-safe.
select cron.unschedule('ai-daily-briefs')   where exists (select 1 from cron.job where jobname = 'ai-daily-briefs');
select cron.unschedule('ai-weekly-reviews') where exists (select 1 from cron.job where jobname = 'ai-weekly-reviews');

select cron.schedule('ai-daily-briefs',   '0 6 * * *', $$ select public.ai_cron_generate('daily_insight'); $$);
select cron.schedule('ai-weekly-reviews', '0 7 * * 1', $$ select public.ai_cron_generate('weekly_review'); $$);
