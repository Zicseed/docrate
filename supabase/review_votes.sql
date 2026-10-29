-- DocRate: upvotes and downvotes on reviews (replaces the single Helpful button).
-- Run once in Supabase Dashboard -> SQL Editor. Safe to re-run.
--
-- Reuses review_helpful_votes: every existing Helpful vote becomes an upvote (value = 1).
-- A student has at most one vote per review and can switch it (update) or remove it (delete).
-- Totals are public through review_vote_counts(); who voted stays private.

alter table public.review_helpful_votes
  add column if not exists value smallint not null default 1;

do $$ begin
  alter table public.review_helpful_votes add constraint review_helpful_votes_value_check check (value in (1, -1));
exception when duplicate_object then null;
end $$;

drop policy if exists "helpful votes: change own" on public.review_helpful_votes;
create policy "helpful votes: change own" on public.review_helpful_votes
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "helpful votes: remove own" on public.review_helpful_votes;
create policy "helpful votes: remove own" on public.review_helpful_votes
  for delete to authenticated using (user_id = auth.uid());

grant update, delete on public.review_helpful_votes to authenticated;

create or replace function public.review_vote_counts()
returns table (review_id uuid, up bigint, down bigint)
language sql stable security definer set search_path = public
as $$
  select review_id, count(*) filter (where value = 1), count(*) filter (where value = -1)
  from public.review_helpful_votes group by review_id;
$$;

grant execute on function public.review_vote_counts() to anon, authenticated;
