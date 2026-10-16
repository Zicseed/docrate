-- DocRate: permanent moderation history (Admin -> Activity).
-- Run once in Supabase Dashboard -> SQL Editor. Safe to re-run.
--
-- One row per admin action (approve/reject/delete review, resolve report, approve professor,
-- hide/unhide/delete doctor or course, change an approval setting). Only admins can read or add rows;
-- nobody can edit or delete them from the site, so the history can't be rewritten.

create or replace function public.docrate_is_admin()
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;

create table if not exists public.moderation_log (
  id              bigint generated always as identity primary key,
  created_at      timestamptz not null default now(),
  moderator_id    uuid not null default auth.uid(),
  moderator_email text default (auth.jwt() ->> 'email'),
  action          text not null,
  target_type     text,
  target_id       text,
  target_label    text
);

create index if not exists moderation_log_created_at_idx on public.moderation_log (created_at desc);

alter table public.moderation_log enable row level security;

drop policy if exists "moderation log: admins read" on public.moderation_log;
create policy "moderation log: admins read" on public.moderation_log
  for select to authenticated using (public.docrate_is_admin());

drop policy if exists "moderation log: admins add" on public.moderation_log;
create policy "moderation log: admins add" on public.moderation_log
  for insert to authenticated with check (public.docrate_is_admin() and moderator_id = auth.uid());

grant select, insert on public.moderation_log to authenticated;
grant execute on function public.docrate_is_admin() to authenticated;
