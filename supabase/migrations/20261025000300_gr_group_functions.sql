-- US-GR-03, US-GR-04, US-GR-18, spec T3 (GR spec.md 2.3): Gruppen anlegen, ändern, auflösen; Trainingszeiten
-- anlegen, „Ändern ab“, beenden. security definer; Rechteprüfung GR ≥ edit als erste Anweisung.

-- Gruppe vorhanden und nicht aufgelöst; intern
create function public.gr_check_group_open(p_group uuid)
returns public.gr_groups
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_group public.gr_groups%rowtype;
begin
  select * into v_group from public.gr_groups g where g.id = p_group;
  if not found then
    raise exception 'GR_GROUP_NOT_FOUND' using errcode = 'P0001';
  end if;
  if v_group.dissolved_on is not null then
    raise exception 'GR_GROUP_DISSOLVED' using errcode = 'P0001';
  end if;
  return v_group;
end;
$$;

-- Überschneidung mit einer anderen Trainingszeit derselben Gruppe am selben Wochentag (R19, nur Hinweis); intern
create function public.gr_training_time_overlaps(p_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
      from public.gr_training_times a
      join public.gr_training_times b
        on b.group_id = a.group_id and b.weekday = a.weekday and b.id <> a.id
     where a.id = p_id
       and a.starts_at < b.ends_at and b.starts_at < a.ends_at
       and daterange(a.valid_from, a.valid_to, '[]') && daterange(b.valid_from, b.valid_to, '[]')
  );
$$;

revoke all on function public.gr_check_group_open(uuid) from public, anon, authenticated;
revoke all on function public.gr_training_time_overlaps(uuid) from public, anon, authenticated;

-- Anlegen (p_id null) oder Ändern von Name und Referat (R1, R21)
create function public.gr_save_group(p_id uuid, p_name text, p_referat_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_name text := btrim(coalesce(p_name, ''));
  v_group public.gr_groups%rowtype;
  v_id uuid;
begin
  if not public.ad_has_level('GR', 'edit') then
    raise exception 'GR_FORBIDDEN' using errcode = 'P0001';
  end if;
  if v_name = '' or p_referat_id is null then
    raise exception 'GR_GROUP_FIELDS_REQUIRED' using errcode = 'P0001';
  end if;
  if char_length(v_name) > 80 then
    raise exception 'GR_TEXT_TOO_LONG' using errcode = 'P0001', detail = '80';
  end if;
  if p_id is not null then
    v_group := public.gr_check_group_open(p_id);
  end if;

  if (p_id is null or p_referat_id is distinct from v_group.referat_id)
     and not exists (select 1 from public.ea_referate r where r.id = p_referat_id and r.is_active) then
    raise exception 'GR_REFERAT_INACTIVE' using errcode = 'P0001';
  end if;

  if exists (
    select 1 from public.gr_groups g
     where lower(g.name) = lower(v_name) and g.dissolved_on is null and g.id is distinct from p_id
  ) then
    raise exception 'GR_GROUP_NAME_TAKEN' using errcode = 'P0001';
  end if;

  if p_id is null then
    insert into public.gr_groups (name, referat_id) values (v_name, p_referat_id) returning id into v_id;
  else
    update public.gr_groups set name = v_name, referat_id = p_referat_id where id = p_id;
    v_id := p_id;
  end if;
  return v_id;
end;
$$;

-- Auflösen (R9, A12): beendet Funktionen und Trainingszeiten zum Datum; später beginnende bleiben und werden
-- zurückgegeben (plan.md H5)
create function public.gr_dissolve_group(p_id uuid, p_dissolved_on date)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_later jsonb;
begin
  if not public.ad_has_level('GR', 'edit') then
    raise exception 'GR_FORBIDDEN' using errcode = 'P0001';
  end if;
  perform public.gr_check_group_open(p_id);
  if p_dissolved_on is null then
    raise exception 'GR_CONSENT_DATE_REQUIRED' using errcode = 'P0001';
  end if;
  if p_dissolved_on > public.gr_today() then
    raise exception 'GR_DATE_IN_FUTURE' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.gr_memberships m
              where m.group_id = p_id and (m.left_on is null or m.left_on > p_dissolved_on)) then
    raise exception 'GR_GROUP_HAS_MEMBERS' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.gr_pending_admissions a where a.group_id = p_id) then
    raise exception 'GR_GROUP_HAS_PENDING' using errcode = 'P0001';
  end if;

  update public.gr_groups set dissolved_on = p_dissolved_on where id = p_id;

  update public.ea_properties p
     set valid_to = p_dissolved_on
    from public.ea_property_types t
   where t.id = p.property_type_id and t.system_key = 'group_function'
     and p.related_group_id = p_id
     and p.valid_from <= p_dissolved_on
     and (p.valid_to is null or p.valid_to > p_dissolved_on);

  update public.gr_training_times tt
     set valid_to = p_dissolved_on
   where tt.group_id = p_id
     and tt.valid_from <= p_dissolved_on
     and (tt.valid_to is null or tt.valid_to > p_dissolved_on);

  select coalesce(jsonb_agg(x order by x ->> 'kind', x ->> 'id'), '[]') into v_later
    from (
      select jsonb_build_object('kind', 'function', 'id', p.id) as x
        from public.ea_properties p
        join public.ea_property_types t on t.id = p.property_type_id and t.system_key = 'group_function'
       where p.related_group_id = p_id and p.valid_from > p_dissolved_on
      union all
      select jsonb_build_object('kind', 'training_time', 'id', tt.id)
        from public.gr_training_times tt
       where tt.group_id = p_id and tt.valid_from > p_dissolved_on
    ) s;

  return jsonb_build_object('starts_after_dissolution', v_later);
end;
$$;

-- Trainingszeit anlegen (R18); Rückgabe mit Hinweis Überschneidung (R19)
create function public.gr_add_training_time(
  p_group uuid, p_weekday smallint, p_starts time, p_ends time, p_valid_from date, p_valid_to date default null)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid;
begin
  if not public.ad_has_level('GR', 'edit') then
    raise exception 'GR_FORBIDDEN' using errcode = 'P0001';
  end if;
  perform public.gr_check_group_open(p_group);
  if p_weekday is null or p_starts is null or p_ends is null or p_valid_from is null then
    raise exception 'GR_TRAINING_TIME_REQUIRED' using errcode = 'P0001';
  end if;
  if p_weekday not between 1 and 7 then
    raise exception 'GR_TRAINING_TIME_REQUIRED' using errcode = 'P0001';
  end if;
  if p_ends <= p_starts then
    raise exception 'GR_TRAINING_TIME_END' using errcode = 'P0001';
  end if;
  if p_valid_to is not null and p_valid_to < p_valid_from then
    raise exception 'GR_VALID_TO_BEFORE_FROM' using errcode = 'P0001';
  end if;

  insert into public.gr_training_times (group_id, weekday, starts_at, ends_at, valid_from, valid_to)
  values (p_group, p_weekday, p_starts, p_ends, p_valid_from, p_valid_to)
  returning id into v_id;

  return jsonb_build_object('id', v_id, 'overlap', public.gr_training_time_overlaps(v_id));
end;
$$;

-- „Ändern ab“ (R19): alte endet am Vortag, neue beginnt am Datum mit dem alten „gültig bis“
create function public.gr_change_training_time(
  p_id uuid, p_from date, p_weekday smallint, p_starts time, p_ends time)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_old public.gr_training_times%rowtype;
  v_id uuid;
begin
  if not public.ad_has_level('GR', 'edit') then
    raise exception 'GR_FORBIDDEN' using errcode = 'P0001';
  end if;
  select * into v_old from public.gr_training_times tt where tt.id = p_id;
  if not found then
    raise exception 'AD_BAD_REQUEST' using errcode = 'P0001';
  end if;
  perform public.gr_check_group_open(v_old.group_id);
  if p_from is null or p_weekday is null or p_starts is null or p_ends is null or p_weekday not between 1 and 7 then
    raise exception 'GR_TRAINING_TIME_REQUIRED' using errcode = 'P0001';
  end if;
  if p_from <= v_old.valid_from or (v_old.valid_to is not null and p_from > v_old.valid_to) then
    raise exception 'GR_CHANGE_DATE_INVALID' using errcode = 'P0001';
  end if;
  if p_ends <= p_starts then
    raise exception 'GR_TRAINING_TIME_END' using errcode = 'P0001';
  end if;

  update public.gr_training_times set valid_to = p_from - 1 where id = p_id;

  insert into public.gr_training_times (group_id, weekday, starts_at, ends_at, valid_from, valid_to)
  values (v_old.group_id, p_weekday, p_starts, p_ends, p_from, v_old.valid_to)
  returning id into v_id;

  return jsonb_build_object('id', v_id, 'overlap', public.gr_training_time_overlaps(v_id));
end;
$$;

-- „gültig bis“ setzen oder ändern
create function public.gr_end_training_time(p_id uuid, p_valid_to date)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_old public.gr_training_times%rowtype;
begin
  if not public.ad_has_level('GR', 'edit') then
    raise exception 'GR_FORBIDDEN' using errcode = 'P0001';
  end if;
  select * into v_old from public.gr_training_times tt where tt.id = p_id;
  if not found then
    raise exception 'AD_BAD_REQUEST' using errcode = 'P0001';
  end if;
  perform public.gr_check_group_open(v_old.group_id);
  if p_valid_to is null then
    raise exception 'GR_CONSENT_DATE_REQUIRED' using errcode = 'P0001';
  end if;
  if p_valid_to < v_old.valid_from then
    raise exception 'GR_VALID_TO_BEFORE_FROM' using errcode = 'P0001';
  end if;

  update public.gr_training_times set valid_to = p_valid_to where id = p_id;
end;
$$;

revoke all on function public.gr_save_group(uuid, text, uuid) from public, anon, authenticated;
revoke all on function public.gr_dissolve_group(uuid, date) from public, anon, authenticated;
revoke all on function public.gr_add_training_time(uuid, smallint, time, time, date, date) from public, anon, authenticated;
revoke all on function public.gr_change_training_time(uuid, date, smallint, time, time) from public, anon, authenticated;
revoke all on function public.gr_end_training_time(uuid, date) from public, anon, authenticated;
grant execute on function public.gr_save_group(uuid, text, uuid) to authenticated;
grant execute on function public.gr_dissolve_group(uuid, date) to authenticated;
grant execute on function public.gr_add_training_time(uuid, smallint, time, time, date, date) to authenticated;
grant execute on function public.gr_change_training_time(uuid, date, smallint, time, time) to authenticated;
grant execute on function public.gr_end_training_time(uuid, date) to authenticated;
