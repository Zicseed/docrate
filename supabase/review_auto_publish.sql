-- DocRate: make "Require approval for new reviews" = OFF actually publish new reviews.
-- Run once in Supabase Dashboard -> SQL Editor. Safe to re-run.
--
-- Why: reviews_protect_row_trigger (BEFORE INSERT) always sets a new review to 'pending', and the
-- later AFTER INSERT auto-approve update runs as the student, so the same protection puts it back
-- to 'pending'. This trigger runs right AFTER the protection (triggers fire in name order) and sets
-- the status while the review is being saved, so no extra update is needed.

create or replace function public.docrate_publish_when_open()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if coalesce((select setting_value::text::boolean from public.app_settings
               where setting_key = 'require_review_approval'), true) = false then
    new.status := 'approved';
  end if;
  return new;
end;
$$;

drop trigger if exists reviews_publish_when_open on public.reviews;
create trigger reviews_publish_when_open
  before insert on public.reviews
  for each row execute function public.docrate_publish_when_open();

-- Check: should list reviews_protect_row_trigger first, then reviews_publish_when_open.
select tgname from pg_trigger
where tgrelid = 'public.reviews'::regclass and not tgisinternal
  and tgname in ('reviews_protect_row_trigger', 'reviews_publish_when_open')
order by tgname;
