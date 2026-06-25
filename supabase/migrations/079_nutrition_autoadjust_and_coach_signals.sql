-- Migration 079: nutrition macro auto-adjustment (#5) + coach AI signals (handoff §11)

-- ── #5: adjust the active nutrition plan from the weight trend ──
-- Compares the user's recent weekly check-in weight trend against their goal and
-- nudges calories (±150, floored at 1200), recomputing macros, then logs an
-- insight. Needs ≥2 check-ins with weight in the last 35 days; no-ops otherwise.
create or replace function public.ai_adjust_nutrition(p_uid uuid)
returns void language plpgsql security definer as $$
declare
  p        user_profiles%rowtype;
  v_plan   client_nutrition_plans%rowtype;
  v_first  numeric; v_last numeric; v_weeks numeric; v_rate numeric;
  v_goal   text; v_delta int := 0; v_new int; v_protein int; v_fat int; v_carbs int; v_n int;
begin
  select * into p from user_profiles where id = p_uid;
  if not found then return; end if;
  select * into v_plan from client_nutrition_plans
    where client_id = p_uid and is_active order by created_at desc limit 1;
  if not found then return; end if;

  select count(*) into v_n from weekly_checkins
    where user_id = p_uid and weight_kg is not null and created_at > now() - interval '35 days';
  if v_n < 2 then return; end if;

  select weight_kg into v_first from weekly_checkins
    where user_id = p_uid and weight_kg is not null and created_at > now() - interval '35 days'
    order by created_at asc limit 1;
  select weight_kg into v_last from weekly_checkins
    where user_id = p_uid and weight_kg is not null order by created_at desc limit 1;
  select greatest(extract(epoch from (max(created_at) - min(created_at))) / 604800.0, 1)
    into v_weeks from weekly_checkins
    where user_id = p_uid and weight_kg is not null and created_at > now() - interval '35 days';
  v_rate := (v_last - v_first) / v_weeks;   -- kg/week, signed

  v_goal := coalesce(p.fitness_goal, p.goal, 'general');
  if v_goal = 'lose_fat' then
    if v_rate > -0.2 then v_delta := -150; elsif v_rate < -1.0 then v_delta := 150; end if;
  elsif v_goal = 'build_muscle' then
    if v_rate < 0.1 then v_delta := 150; elsif v_rate > 0.5 then v_delta := -150; end if;
  elsif v_goal = 'body_recomp' then
    if v_rate > 0.3 then v_delta := -120; elsif v_rate < -0.5 then v_delta := 120; end if;
  end if;
  if v_delta = 0 then return; end if;

  v_new := greatest(1200, v_plan.calories_target + v_delta);
  if v_new = v_plan.calories_target then return; end if;
  v_protein := round(coalesce(p.weight_kg, 70) * 2.0);
  v_fat     := round(v_new * 0.25 / 9.0);
  v_carbs   := greatest(0, round((v_new - v_protein * 4 - v_fat * 9) / 4.0));

  update client_nutrition_plans
    set calories_target = v_new, protein_g = v_protein, carbs_g = v_carbs, fat_g = v_fat,
        notes = 'Auto-adjusted from your weight trend (' || to_char(v_rate, 'FM990.0') || ' kg/wk).'
    where id = v_plan.id;

  insert into ai_insights (user_id, type, title, body, data)
  values (p_uid, 'nutrition_adjustment',
    case when v_delta < 0 then 'Calories reduced' else 'Calories increased' end,
    'Your ' || to_char(v_rate, 'FM990.0') || ' kg/week trend moved your target to ' || v_new ||
      ' kcal to keep you on pace for your goal.',
    jsonb_build_object('delta_cal', v_delta, 'new_calories', v_new, 'rate_kg_wk', round(v_rate::numeric, 2)));
end;
$$;

grant execute on function public.ai_adjust_nutrition(uuid) to authenticated, service_role;

-- ── Handoff §11: AI signals for a coach's active clients ──
-- SECURITY DEFINER so a coach can read their clients' AI risk/insights (which RLS
-- otherwise restricts to the client). Filtered to the caller's active clients.
create or replace function public.coach_client_ai_signals()
returns table (
  client_id uuid, client_name text,
  plateau_risk int, churn_risk int, injury_risk int, risk_summary text,
  last_brief text, workouts_7d int
) language sql stable security definer as $$
  select r.client_id,
    nullif(trim(coalesce(up.first_name, '') || ' ' || coalesce(up.last_name, '')), ''),
    (ri.data->>'plateau_risk')::int, (ri.data->>'churn_risk')::int, (ri.data->>'injury_risk')::int, ri.body,
    di.title, coalesce(w.cnt, 0)::int
  from coach_client_relationships r
  join user_profiles up on up.id = r.client_id
  left join lateral (select data, body from ai_insights
    where user_id = r.client_id and type = 'risk' order by created_at desc limit 1) ri on true
  left join lateral (select title from ai_insights
    where user_id = r.client_id and type = 'daily_insight' order by for_date desc limit 1) di on true
  left join lateral (select count(*) cnt from workout_sessions
    where user_id = r.client_id and status = 'completed' and started_at > now() - interval '7 days') w on true
  where r.coach_id = auth.uid() and r.status = 'active'
  order by (ri.data->>'churn_risk')::int desc nulls last;
$$;

grant execute on function public.coach_client_ai_signals() to authenticated;
