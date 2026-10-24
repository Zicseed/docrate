-- DocRate: age range, university and faculty on every account.
-- Run once in Supabase Dashboard -> SQL Editor. Safe to re-run.
--
-- Adds three columns to profiles and docrate_save_profile(), which lets a signed-in user fill in
-- only their OWN details. Until this runs, the site does not ask anyone for them.

alter table public.profiles
  add column if not exists age_range     text,
  add column if not exists university_id text,
  add column if not exists faculty       text;

create or replace function public.docrate_save_profile(p_age_range text, p_university text, p_faculty text)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  if auth.uid() is null then raise exception 'Please sign in first.'; end if;
  if p_age_range is null or p_age_range not in ('16-18', '19-21', '22-24', '25-29', '30+') then
    raise exception 'Choose your age range.';
  end if;
  if coalesce(trim(p_university), '') = '' or coalesce(trim(p_faculty), '') = '' then
    raise exception 'Choose your university and faculty.';
  end if;
  update public.profiles
     set age_range = p_age_range, university_id = left(trim(p_university), 40), faculty = left(trim(p_faculty), 80)
   where id = auth.uid();
  if not found then raise exception 'Your profile could not be found. Please sign out and in again.'; end if;
end;
$$;

grant execute on function public.docrate_save_profile(text, text, text) to authenticated;
