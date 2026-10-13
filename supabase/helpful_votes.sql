-- DocRate: persistent "Helpful" votes on reviews.
-- Run once in Supabase Dashboard -> SQL Editor. Safe to re-run.
--
-- One row per (review, student). Students can see and add only their own
-- votes; everyone gets the totals through review_helpful_counts(), which
-- never reveals who voted.

create table if not exists public.review_helpful_votes (
  review_id  uuid not null references public.reviews(id) on delete cascade,
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (review_id, user_id)
);

alter table public.review_helpful_votes enable row level security;

drop policy if exists "helpful votes: read own" on public.review_helpful_votes;
create policy "helpful votes: read own" on public.review_helpful_votes
  for select to authenticated using (user_id = auth.uid());

drop policy if exists "helpful votes: add own" on public.review_helpful_votes;
create policy "helpful votes: add own" on public.review_helpful_votes
  for insert to authenticated with check (user_id = auth.uid());

create or replace function public.review_helpful_counts()
returns table (review_id uuid, helpful bigint)
language sql stable security definer set search_path = public
as $$
  select review_id, count(*) from public.review_helpful_votes group by review_id;
$$;

grant select, insert on public.review_helpful_votes to authenticated;
grant execute on function public.review_helpful_counts() to anon, authenticated;
