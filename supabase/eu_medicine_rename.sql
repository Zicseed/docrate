-- DocRate: European University Medicine - shorter names for the integrated courses.
--   Body Systems I (...) .. IV (...)        ->  Body System I .. Body System IV  (sections: Anatomy, Physiology, Imaging)
--   Gene, Cell and Tissue I (...) .. IV (...) ->  Gene, Cell and Tissue           (same name in every semester)
-- Run once in Supabase Dashboard -> SQL Editor. Safe to re-run. Only these 8 course codes are touched.
-- If the table layout is not what this expects, it stops without changing anything and lists the columns.

do $$
declare
  v_name_col text;   -- 'name' when the course name is its own column
  v_data_col text;   -- otherwise the json/jsonb column holding {"name": ...}
  v_data_type text;
  v_code_expr text;
  v_changed int := 0;
  n int;
  r record;
begin
  select column_name into v_name_col from information_schema.columns
   where table_schema = 'public' and table_name = 'catalogue_courses' and column_name = 'name';
  select column_name, data_type into v_data_col, v_data_type from information_schema.columns
   where table_schema = 'public' and table_name = 'catalogue_courses' and data_type in ('jsonb', 'json')
   order by (column_name = 'data') desc limit 1;
  v_code_expr := case when exists (select 1 from information_schema.columns
                   where table_schema = 'public' and table_name = 'catalogue_courses' and column_name = 'code')
                 then 'code' else format('(%I ->> %L)', v_data_col, 'code') end;

  if v_name_col is null and v_data_col is null then
    raise exception 'catalogue_courses has no name or json column. Columns: %',
      (select string_agg(column_name || ' ' || data_type, ', ') from information_schema.columns
        where table_schema = 'public' and table_name = 'catalogue_courses');
  end if;

  for r in select * from (values
    ('EU-MD-0101', 'Body System I'), ('EU-MD-0201', 'Body System II'),
    ('EU-MD-0301', 'Body System III'), ('EU-MD-0401', 'Body System IV'),
    ('EU-MD-0102', 'Gene, Cell and Tissue'), ('EU-MD-0202', 'Gene, Cell and Tissue'),
    ('EU-MD-0302', 'Gene, Cell and Tissue'), ('EU-MD-0402', 'Gene, Cell and Tissue')
  ) as t(code, new_name) loop
    if v_name_col is not null then
      execute format('update public.catalogue_courses set name = $1 where %s = $2', v_code_expr) using r.new_name, r.code;
    else
      execute format('update public.catalogue_courses set %1$I = jsonb_set(%1$I::jsonb, ''{name}'', to_jsonb($1::text))::%2$s where %3$s = $2',
                     v_data_col, v_data_type, v_code_expr) using r.new_name, r.code;
    end if;
    get diagnostics n = row_count;
    v_changed := v_changed + n;
  end loop;

  -- If the json copy also exists alongside a name column, keep it in sync.
  if v_name_col is not null and v_data_col is not null then
    execute format('update public.catalogue_courses set %1$I = jsonb_set(%1$I::jsonb, ''{name}'', to_jsonb(name::text))::%2$s where %3$s like %4$L and (%1$I::jsonb ? ''name'')',
                   v_data_col, v_data_type, v_code_expr, 'EU-MD-0%');
  end if;

  if v_changed = 0 then
    raise exception 'No European University courses found to rename (were they added with eu_medicine_courses.sql?).';
  end if;
  raise notice 'Renamed % European University course rows.', v_changed;
end;
$$;
