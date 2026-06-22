-- Migration 045: keep user_profiles.rating_avg / review_count in sync with coach_reviews
--
-- Bug: coach_reviews rows were inserted, but nothing ever recomputed the
-- rating_avg / review_count columns on user_profiles. Both the intake coach
-- picker and the marketplace RPC read those columns, so every coach showed
-- "No reviews yet" even with real reviews on file. This adds an aggregation
-- trigger (insert/update/delete) plus a one-time backfill of existing reviews.

create or replace function public.recalc_coach_rating(p_coach_id uuid)
returns void
language sql
security definer
as $$
  update public.user_profiles p
     set rating_avg   = sub.avg_rating,
         review_count = sub.cnt
    from (
      select round(coalesce(avg(rating), 0)::numeric, 1) as avg_rating,
             count(*)::int                               as cnt
        from public.coach_reviews
       where coach_id = p_coach_id
    ) sub
   where p.id = p_coach_id;
$$;

create or replace function public.on_coach_review_change()
returns trigger
language plpgsql
security definer
as $$
begin
  -- Recompute for the affected coach(es). On UPDATE the coach_id could change.
  if tg_op = 'DELETE' then
    perform public.recalc_coach_rating(old.coach_id);
    return old;
  end if;
  perform public.recalc_coach_rating(new.coach_id);
  if tg_op = 'UPDATE' and new.coach_id is distinct from old.coach_id then
    perform public.recalc_coach_rating(old.coach_id);
  end if;
  return new;
end;
$$;

drop trigger if exists coach_review_rollup on public.coach_reviews;
create trigger coach_review_rollup
  after insert or update or delete on public.coach_reviews
  for each row execute function public.on_coach_review_change();

-- One-time backfill for reviews that already exist.
update public.user_profiles p
   set rating_avg   = sub.avg_rating,
       review_count = sub.cnt
  from (
    select coach_id,
           round(avg(rating)::numeric, 1) as avg_rating,
           count(*)::int                  as cnt
      from public.coach_reviews
     group by coach_id
  ) sub
 where p.id = sub.coach_id;
