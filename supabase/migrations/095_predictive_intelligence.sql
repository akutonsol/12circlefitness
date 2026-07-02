-- ═══════════════════════════════════════════════════════════════════════════
-- Migration 095 — Predictive Intelligence Engine (PIE) · Layer 7
--
-- Predicts OUTCOMES deterministically from existing platform data (weekly_feedback,
-- program plan, profile). No new data sources, no LLM prediction — the LLM only
-- explains. Every prediction is stored (history) with the inputs + engine version
-- so predictions can later be compared to reality.
--
-- Depends on 093/094 (plan, weekly_feedback). Idempotent.
-- ═══════════════════════════════════════════════════════════════════════════

create table if not exists predictions (
  id             uuid primary key default gen_random_uuid(),
  subject_id     uuid references user_profiles(id),
  program_id     uuid references workout_programs(id) on delete cascade,
  prediction     jsonb not null,          -- full bundle (also the decision trace)
  confidence     int,
  engine_version text default '1.0.0',
  created_at     timestamptz default now()
);
create index if not exists idx_pred_subject on predictions(subject_id, created_at desc);
alter table predictions enable row level security;
drop policy if exists "pred read" on predictions;
create policy "pred read" on predictions for select to authenticated using (
  subject_id = auth.uid()
  or exists (select 1 from workout_programs p where p.id = program_id and p.coach_id = auth.uid())
  or exists (select 1 from user_profiles where id = auth.uid() and role in ('admin','content_manager')));

-- ── The deterministic predictor ─────────────────────────────────────────────
create or replace function public.predict_client(p_subject uuid, p_program uuid default null)
returns jsonb language plpgsql stable security definer as $$
declare
  v_prog uuid := p_program;
  v_dur int; v_done int; v_maxwk int;
  v_avg_comp numeric; v_avg_rec numeric; v_rec_first numeric; v_rec_last numeric;
  v_prs_recent int; v_pain_recent boolean; v_pain jsonb;
  v_start numeric; v_goal numeric; v_cur numeric; v_fitgoal text;
  need numeric; done numeric; progress numeric; pace_need numeric; pace_act numeric;
  remaining numeric; weeks_left numeric; finish date; confidence int;
  plateau text; injury_general text; adherence_churn text; rec_forecast numeric;
  alerts text[] := '{}';
begin
  if v_prog is null then
    select id into v_prog from workout_programs
      where coach_id is not null and id in (select program_id from weekly_feedback where subject_id = p_subject)
      order by created_at desc limit 1;
    if v_prog is null then
      select program_id into v_prog from weekly_feedback where subject_id = p_subject
        order by created_at desc limit 1;
    end if;
  end if;

  select (plan->>'duration_weeks')::int into v_dur from workout_programs where id = v_prog;
  v_dur := coalesce(v_dur, 12);

  select count(*), avg(completion_pct), avg(recovery), max(week)
    into v_done, v_avg_comp, v_avg_rec, v_maxwk
    from weekly_feedback where program_id = v_prog and subject_id = p_subject;
  v_done := coalesce(v_done, 0);
  if v_done = 0 then
    return jsonb_build_object('status','no_data','program_id',v_prog);
  end if;

  select recovery into v_rec_first from weekly_feedback
    where program_id = v_prog and subject_id = p_subject order by week asc limit 1;
  select recovery into v_rec_last from weekly_feedback
    where program_id = v_prog and subject_id = p_subject order by week desc limit 1;
  select coalesce(sum(prs),0) into v_prs_recent from weekly_feedback
    where program_id = v_prog and subject_id = p_subject and week > v_maxwk - 3;
  select bool_or(coalesce(jsonb_array_length(pain),0) > 0), (array_agg(pain order by week desc))[1]
    into v_pain_recent, v_pain
    from weekly_feedback where program_id = v_prog and subject_id = p_subject and week > v_maxwk - 2;

  select weight_kg, weight_goal_kg, fitness_goal into v_start, v_goal, v_fitgoal
    from user_profiles where id = p_subject;
  select bodyweight into v_cur from weekly_feedback
    where program_id = v_prog and subject_id = p_subject and bodyweight is not null
    order by week desc limit 1;
  v_cur := coalesce(v_cur, v_start);

  -- ── Goal Progress Engine (weight-based goals) ──
  if v_start is not null and v_goal is not null and v_start <> v_goal then
    need := v_goal - v_start;                 -- gain:+  loss:-
    done := v_cur - v_start;
    progress := case when need = 0 then 100
                     when (need * done) <= 0 then 0   -- wrong direction / none
                     else least(abs(done) / abs(need) * 100, 100) end;
    pace_need := need / v_dur;
    pace_act  := done / greatest(v_done, 1);
    remaining := need - done;
    weeks_left := case when pace_act = 0 or (pace_act * need) <= 0 then null
                       else remaining / pace_act end;
    finish := case when weeks_left is null then null
                   else current_date + (ceil(weeks_left) * 7)::int end;
    confidence := greatest(0, least(100, round(
        0.40 * least(case when pace_need = 0 then 1 else abs(pace_act / pace_need) end, 1.2) / 1.2 * 100
      + 0.30 * coalesce(v_avg_comp, 0)
      + 0.30 * coalesce(v_avg_rec, 0))::numeric));
  else
    progress := coalesce(v_avg_comp, 0);       -- non-weight goal → use adherence as proxy
    confidence := round((0.5 * coalesce(v_avg_comp,0) + 0.5 * coalesce(v_avg_rec,0))::numeric);
    finish := null;
  end if;

  -- ── Plateau ──
  plateau := case
    when v_done >= 3 and v_prs_recent = 0 and coalesce(v_avg_comp,0) > 85 then 'high'
    when v_done >= 3 and v_prs_recent = 0 then 'medium'
    else 'low' end;

  -- ── Injury risk ──
  injury_general := case when v_pain_recent then 'high'
                         when coalesce(v_avg_rec, 100) < 60 then 'medium' else 'low' end;

  -- ── Adherence / churn ──
  adherence_churn := case when coalesce(v_avg_comp,100) < 60 then 'high'
                          when coalesce(v_avg_comp,100) < 80 then 'medium' else 'low' end;

  -- ── Recovery forecast (linear extrapolation of the trend) ──
  rec_forecast := greatest(0, least(100,
    coalesce(v_rec_last, v_avg_rec, 70)
    + coalesce(v_rec_last - v_rec_first, 0) / greatest(v_done - 1, 1)));

  -- ── Deterministic alerts ──
  if plateau = 'high' then alerts := alerts || 'plateau_approaching'; end if;
  if coalesce(v_rec_last,100) < coalesce(v_rec_first,0) and coalesce(v_avg_rec,100) < 65 then
    alerts := alerts || 'recovery_declining'; end if;
  if injury_general = 'high' then alerts := alerts || 'high_injury_probability'; end if;
  if adherence_churn = 'high' then alerts := alerts || 'coach_followup_recommended'; end if;
  if confidence >= 90 and progress >= 60 then alerts := alerts || 'ahead_of_schedule'; end if;
  if progress >= 100 then alerts := alerts || 'goal_achieved_early'; end if;

  return jsonb_build_object(
    'status', 'ok', 'program_id', v_prog, 'engine_version', '1.0.0',
    'weeks_completed', v_done, 'duration_weeks', v_dur,
    'goal', jsonb_build_object(
      'fitness_goal', v_fitgoal, 'start', v_start, 'current', v_cur, 'target', v_goal,
      'progress_pct', round(progress), 'predicted_finish', finish, 'confidence', confidence),
    'plateau_risk', plateau,
    'injury_risk', jsonb_build_object('general', injury_general, 'areas', coalesce(v_pain, '[]'::jsonb)),
    'adherence', jsonb_build_object('avg_completion', round(coalesce(v_avg_comp,0)),
      'churn_risk', adherence_churn),
    'recovery', jsonb_build_object('avg', round(coalesce(v_avg_rec,0)),
      'forecast_next', round(rec_forecast),
      'trend', case when coalesce(v_rec_last,0) > coalesce(v_rec_first,0) then 'improving'
                    when coalesce(v_rec_last,0) < coalesce(v_rec_first,0) then 'declining' else 'stable' end),
    'alerts', to_jsonb(alerts));
end;
$$;
grant execute on function public.predict_client(uuid, uuid) to authenticated;

-- Compute + persist a prediction (history for prediction-vs-reality comparison).
create or replace function public.record_prediction(p_subject uuid, p_program uuid default null)
returns jsonb language plpgsql security definer as $$
declare pred jsonb; v_id uuid;
begin
  pred := public.predict_client(p_subject, p_program);
  if pred->>'status' <> 'ok' then return pred; end if;
  insert into predictions(subject_id, program_id, prediction, confidence, engine_version)
  values (p_subject, (pred->>'program_id')::uuid, pred,
    (pred#>>'{goal,confidence}')::int, pred->>'engine_version')
  returning id into v_id;
  return pred || jsonb_build_object('prediction_id', v_id);
end;
$$;
grant execute on function public.record_prediction(uuid, uuid) to authenticated;
