-- DocRate: admin switch for whether new reviews need approval.
-- Run once in Supabase Dashboard -> SQL Editor. Safe to re-run.
--
-- Setting  require_review_approval  (in app_settings, next to require_professor_approval):
--   ON  (true)  -> new reviews stay 'pending' until an admin approves them (today's behaviour)
--   OFF (false) -> new reviews are published ('approved') as soon as they are submitted
-- Admins flip it from Admin -> Moderation on the site. It starts ON, so nothing changes until you switch it.

insert into public.app_settings (setting_key, setting_value)
values ('require_review_approval', 'true')
on conflict (setting_key) do nothing;

-- After a review is inserted: publish it right away when approval is switched off.
-- If publishing fails for any reason, the review simply stays pending; the student's submit never fails.
create or replace function public.docrate_auto_approve_review()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_require boolean;
begin
  select setting_value::text::boolean into v_require
  from public.app_settings where setting_key = 'require_review_approval';

  if coalesce(v_require, true) = false and new.status = 'pending' then
    begin
      update public.reviews set status = 'approved' where id = new.id and status = 'pending';
    exception when others then
      raise warning 'docrate_auto_approve_review: left review % pending (%)', new.id, sqlerrm;
    end;
  end if;
  return null;
end;
$$;

drop trigger if exists docrate_auto_approve_review on public.reviews;
create trigger docrate_auto_approve_review
  after insert on public.reviews
  for each row execute function public.docrate_auto_approve_review();
