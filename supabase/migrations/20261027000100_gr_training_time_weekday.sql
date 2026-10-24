-- GR spec T20 (US-GR-18, US-GR-19; Übergabe EZ uebergabe-gruppen.md G6, G7, G9): je Gruppe und Wochentag höchstens
-- eine gültige Trainingszeit (R19 v0.3). Ausschluss-Constraint als Sicherung, Prüfung mit eigenem Code in den
-- Funktionen; der Hinweis auf Überschneidung (Rückgabe `overlap`) entfällt.

create extension if not exists btree_gist with schema extensions;

alter table public.gr_training_times
  add constraint gr_training_times_one_per_weekday
  exclude using gist (
    group_id extensions.gist_uuid_ops with =,
    weekday extensions.gist_int2_ops with =,
    daterange(valid_from, valid_to, '[]') with &&
  );

-- Gibt es für die Gruppe am Wochentag eine andere Trainingszeit mit sich überschneidender Gültigkeit?
create function public.gr_training_time_weekday_taken(
  p_group uuid, p_weekday smallint, p_valid_from date, p_valid_to date, p_except uuid default null)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
      from public.gr_training_times tt
     where tt.group_id = p_group
       and tt.weekday = p_weekday
       and tt.id is distinct from p_except
       and daterange(tt.valid_from, tt.valid_to, '[]') && daterange(p_valid_from, p_valid_to, '[]')
  );
$$;

revoke all on function public.gr_training_time_weekday_taken(uuid, smallint, date, date, uuid) from public, anon, authenticated;

-- Trainingszeit anlegen (R18, R19)
create or replace function public.gr_add_training_time(
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
  if public.gr_training_time_weekday_taken(p_group, p_weekday, p_valid_from, p_valid_to) then
    raise exception 'GR_TRAINING_TIME_WEEKDAY_EXISTS' using errcode = 'P0001';
  end if;

  insert into public.gr_training_times (group_id, weekday, starts_at, ends_at, valid_from, valid_to)
  values (p_group, p_weekday, p_starts, p_ends, p_valid_from, p_valid_to)
  returning id into v_id;

  return jsonb_build_object('id', v_id);
end;
$$;

-- „Ändern ab“ (R19): alte endet am Vortag, neue beginnt am Datum mit dem alten „gültig bis“
create or replace function public.gr_change_training_time(
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
  -- Die alte zählt nicht mit: Sie endet am Vortag und überschneidet sich danach nicht mehr mit der neuen.
  if public.gr_training_time_weekday_taken(v_old.group_id, p_weekday, p_from, v_old.valid_to, p_id) then
    raise exception 'GR_TRAINING_TIME_WEEKDAY_EXISTS' using errcode = 'P0001';
  end if;

  update public.gr_training_times set valid_to = p_from - 1 where id = p_id;

  insert into public.gr_training_times (group_id, weekday, starts_at, ends_at, valid_from, valid_to)
  values (v_old.group_id, p_weekday, p_starts, p_ends, p_from, v_old.valid_to)
  returning id into v_id;

  return jsonb_build_object('id', v_id);
end;
$$;

-- „gültig bis“ setzen oder ändern; Verlängern in eine spätere Trainingszeit am selben Wochentag verletzt R19
create or replace function public.gr_end_training_time(p_id uuid, p_valid_to date)
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
  if public.gr_training_time_weekday_taken(v_old.group_id, v_old.weekday, v_old.valid_from, p_valid_to, p_id) then
    raise exception 'GR_TRAINING_TIME_WEEKDAY_EXISTS' using errcode = 'P0001';
  end if;

  update public.gr_training_times set valid_to = p_valid_to where id = p_id;
end;
$$;

drop function public.gr_training_time_overlaps(uuid);
