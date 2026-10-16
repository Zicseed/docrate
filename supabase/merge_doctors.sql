-- DocRate: merge two duplicate doctor profiles into one (Admin -> Content -> Possible duplicates).
-- Run once in Supabase Dashboard -> SQL Editor. Safe to re-run.
--
-- docrate_merge_professors(p_keep, p_remove):
--   * moves every review of p_remove onto p_keep;
--   * if the same student reviewed both, their review on p_keep stays and the one on p_remove is
--     marked deleted (a student can only have one active review per doctor);
--   * archives p_remove so it disappears from the site, exactly like "Delete doctor".
-- Admins only. Runs as one transaction: if any step fails, nothing changes.

create or replace function public.docrate_is_admin()
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;

create or replace function public.docrate_merge_professors(p_keep text, p_remove text)
returns json
language plpgsql security definer set search_path = public
as $$
declare
  v_duplicates int;
  v_moved int;
begin
  if not public.docrate_is_admin() then
    raise exception 'Only an admin can merge doctors.';
  end if;
  if p_keep is null or p_remove is null or p_keep = p_remove then
    raise exception 'Choose two different doctors to merge.';
  end if;

  -- Same student reviewed both profiles: keep the review already on p_keep.
  update public.reviews r set deleted_at = now()
  where r.prof_id = p_remove and r.deleted_at is null
    and exists (select 1 from public.reviews k
                where k.prof_id = p_keep and k.author_id = r.author_id
                  and k.kind = r.kind and k.deleted_at is null);
  get diagnostics v_duplicates = row_count;

  -- Everything else moves to the kept profile.
  select count(*) into v_moved from public.reviews where prof_id = p_remove and deleted_at is null;
  update public.reviews set prof_id = p_keep where prof_id = p_remove;

  insert into public.entity_archive (entity_type, entity_id)
  values ('professor', p_remove)
  on conflict (entity_type, entity_id) do nothing;

  return json_build_object('moved', v_moved, 'duplicates_removed', v_duplicates);
end;
$$;

grant execute on function public.docrate_is_admin() to authenticated;
grant execute on function public.docrate_merge_professors(text, text) to authenticated;
