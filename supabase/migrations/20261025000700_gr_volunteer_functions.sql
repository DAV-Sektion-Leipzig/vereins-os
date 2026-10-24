-- US-GR-13, spec T7 (GR spec.md 2.3, R28, R29): Gruppenleitung, Trainer:in, Helfer:in als Eigenschaft
-- „Funktion in Gruppe“ (group_function); Ehrenamtsstatus „aktiv“ für Personen ohne Status (Ü1 an die Administration,
-- vorgezogen, research.md R-GR-04).

-- Ü1: Status „aktiv“ nur bei Menschen ohne Ehrenamtsstatus; sonst ohne Änderung. Ohne Grant: nur aus
-- security-definer-Funktionen desselben Eigentümers aufrufbar. Rückgabe: Status gesetzt.
create function public.ea_set_status_from_group(p_person uuid, p_valid_from date)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (select 1 from public.ea_persons pe
                  where pe.id = p_person and pe.kind = 'human' and pe.volunteer_status is null) then
    return false;
  end if;
  perform set_config('ea.status_change', 'on', true);
  update public.ea_persons
     set volunteer_status = 'active', volunteer_status_since = p_valid_from
   where id = p_person;
  perform set_config('ea.status_change', '', true);
  insert into public.ea_volunteer_status_history (person_id, status, valid_from)
  values (p_person, 'active', p_valid_from);
  return true;
end;
$$;

revoke all on function public.ea_set_status_from_group(uuid, date) from public, anon, authenticated;

-- Gleiche Funktion derselben Person in derselben Gruppe überschneidet sich (R28); intern
create function public.gr_function_overlaps(
  p_person uuid, p_group uuid, p_function text, p_from date, p_to date, p_exclude uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.ea_properties p
      join public.ea_property_types t on t.id = p.property_type_id and t.system_key = 'group_function'
     where p.person_id = p_person
       and p.related_group_id = p_group
       and p.field_values ->> 'function' = p_function
       and p.id is distinct from p_exclude
       and daterange(p.valid_from, p.valid_to, '[]') && daterange(p_from, p_to, '[]')
  );
$$;

revoke all on function public.gr_function_overlaps(uuid, uuid, text, date, date, uuid) from public, anon, authenticated;

-- Funktion in Gruppe hinzufügen; setzt „aktiv“ bei Person ohne Status (R29), sonst Hinweis
create function public.gr_add_group_function(
  p_group uuid, p_function text, p_valid_from date, p_valid_to date default null,
  p_person_id uuid default null, p_new_person jsonb default null)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_person uuid;
  v_property uuid;
  v_status public.ea_volunteer_status;
  v_set boolean := false;
begin
  if not public.ad_has_level('GR', 'edit') then
    raise exception 'GR_FORBIDDEN' using errcode = 'P0001';
  end if;
  perform public.gr_check_group_open(p_group);
  if p_valid_from is null then
    raise exception 'GR_CONSENT_DATE_REQUIRED' using errcode = 'P0001';
  end if;
  if p_valid_to is not null and p_valid_to < p_valid_from then
    raise exception 'EA_VALID_RANGE' using errcode = 'P0001';
  end if;

  v_person := public.gr_resolve_person(p_person_id, p_new_person, 'function');

  if public.gr_function_overlaps(v_person, p_group, btrim(coalesce(p_function, '')), p_valid_from, p_valid_to, null) then
    raise exception 'GR_FUNCTION_OVERLAP' using errcode = 'P0001';
  end if;

  -- Auswahlwerte und Pflicht prüft ea_properties_validate (EA_FIELD_CHOICE, EA_FIELD_REQUIRED)
  insert into public.ea_properties (person_id, property_type_id, field_values, related_group_id, valid_from, valid_to)
  select v_person, t.id, jsonb_build_object('function', p_function), p_group, p_valid_from, p_valid_to
    from public.ea_property_types t where t.system_key = 'group_function'
  returning id into v_property;

  select pe.volunteer_status into v_status from public.ea_persons pe where pe.id = v_person;
  if v_status is null then
    v_set := public.ea_set_status_from_group(v_person, p_valid_from);
  end if;

  return jsonb_build_object(
    'property_id', v_property,
    'status_hint', case v_status when 'dormant' then 'dormant' when 'left' then 'left' end,
    'status_set', v_set);
end;
$$;

-- Funktion in Gruppe beenden bzw. „bis“ ändern; Ehrenamtsstatus bleibt
create function public.gr_end_group_function(p_property uuid, p_valid_to date)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_prop public.ea_properties%rowtype;
begin
  if not public.ad_has_level('GR', 'edit') then
    raise exception 'GR_FORBIDDEN' using errcode = 'P0001';
  end if;
  select p.* into v_prop
    from public.ea_properties p
    join public.ea_property_types t on t.id = p.property_type_id and t.system_key = 'group_function'
   where p.id = p_property;
  if not found then
    raise exception 'GR_FORBIDDEN' using errcode = 'P0001';
  end if;
  perform public.gr_check_group_open(v_prop.related_group_id);
  if p_valid_to is null then
    raise exception 'GR_CONSENT_DATE_REQUIRED' using errcode = 'P0001';
  end if;
  if p_valid_to < v_prop.valid_from then
    raise exception 'EA_VALID_RANGE' using errcode = 'P0001';
  end if;
  if public.gr_function_overlaps(v_prop.person_id, v_prop.related_group_id, v_prop.field_values ->> 'function',
                                 v_prop.valid_from, p_valid_to, v_prop.id) then
    raise exception 'GR_FUNCTION_OVERLAP' using errcode = 'P0001';
  end if;

  update public.ea_properties set valid_to = p_valid_to where id = p_property;
end;
$$;

revoke all on function public.gr_add_group_function(uuid, text, date, date, uuid, jsonb) from public, anon, authenticated;
revoke all on function public.gr_end_group_function(uuid, date) from public, anon, authenticated;
grant execute on function public.gr_add_group_function(uuid, text, date, date, uuid, jsonb) to authenticated;
grant execute on function public.gr_end_group_function(uuid, date) to authenticated;
