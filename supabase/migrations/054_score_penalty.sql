-- Migration 054: score penalties (e.g. rest-overrun / idle time)
--
-- award_points() only accepts positive points. This adds penalize_points(),
-- which logs a NEGATIVE score_event (so it shows in history) and subtracts from
-- the cycle + lifetime score, floored at 0 so totals never go negative.
-- p_points is the penalty magnitude (positive); it's stored negated.

create or replace function public.penalize_points(
  p_category text, p_action text, p_points int, p_dedup_key text default null
) returns int language plpgsql security definer as $$
declare
  v_uid    uuid := auth.uid();
  v_period text := to_char(now(), 'YYYY-MM');
  v_cycle  int;
  v_life   int;
  v_level  int;
  v_rank   text;
begin
  if v_uid is null or p_points <= 0 then return 0; end if;

  if p_dedup_key is not null and exists (
       select 1 from score_events where user_id = v_uid and dedup_key = p_dedup_key) then
    return 0;
  end if;

  insert into score_events (user_id, category, action, points, dedup_key)
    values (v_uid, p_category, p_action, -p_points, p_dedup_key);

  insert into score_cycles (user_id, period, score) values (v_uid, v_period, 0)
    on conflict (user_id, period) do update
      set score = greatest(0, score_cycles.score - p_points)
    returning score into v_cycle;

  insert into user_scores (user_id, current_period, current_cycle_score, lifetime_score)
    values (v_uid, v_period, 0, 0)
    on conflict (user_id) do update set
      lifetime_score      = greatest(0, user_scores.lifetime_score - p_points),
      current_cycle_score = greatest(0, user_scores.current_cycle_score - p_points),
      current_period      = v_period,
      updated_at          = now()
    returning lifetime_score into v_life;

  v_level := floor(coalesce(v_life, 0) / 500.0)::int + 1;
  v_rank  := case
    when v_level >= 10 then 'Diamond'
    when v_level >= 7  then 'Platinum'
    when v_level >= 5  then 'Gold'
    when v_level >= 3  then 'Silver'
    else 'Bronze' end;
  update user_scores set level = v_level, rank = v_rank where user_id = v_uid;

  return p_points;
end;
$$;

grant execute on function public.penalize_points(text, text, int, text) to authenticated;
