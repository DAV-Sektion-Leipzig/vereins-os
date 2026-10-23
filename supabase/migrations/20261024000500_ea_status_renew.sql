-- US-EA-07, 08, 09, 10, spec T6 (EA spec.md 2.3): Ehrenamtsstatus ändern (R18, R19), Ausscheiden (R8, R20),
-- Verlängern (R6). Alle security invoker; die RLS der Administration und ea_set_volunteer_status (R33 AD)
-- entscheiden über die Rechte (research.md R-EA-09).

-- Status ändern: nicht auf „ausgeschieden“ (dafür ea_leave), Datum höchstens heute + 1 Jahr, Status muss sich ändern
create function public.ea_change_volunteer_status(
  p_person uuid, p_status public.ea_volunteer_status, p_valid_from date)
returns void
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_status public.ea_volunteer_status;
  v_from date := coalesce(p_valid_from, current_date);
  v_limit date := (current_date + interval '1 year')::date;
begin
  -- nach RLS: nicht lesbar → keine Auskunft über die Existenz (R33 AD)
  select pe.volunteer_status into v_status from public.ea_persons pe where pe.id = p_person;
  if not found or v_status is null or p_status = 'left' then
    raise exception 'EA_STATUS_FORBIDDEN' using errcode = 'P0001';
  end if;
  if v_from > v_limit then
    raise exception 'EA_STATUS_DATE' using errcode = 'P0001', detail = to_char(v_limit, 'DD.MM.YYYY');
  end if;
  if v_status = p_status then
    raise exception 'EA_STATUS_UNCHANGED' using errcode = 'P0001';
  end if;

  perform public.ea_set_volunteer_status(p_person, p_status, v_from);
end;
$$;

-- Ausscheiden in einer Transaktion (A2): Status „ausgeschieden“ und Beenden der gewählten Eigenschaften (R8).
-- Zuerst werden alle IDs geprüft (R20), ohne etwas zu schreiben. Status und Beenden laufen dann in einer
-- Anweisung (Statusaufruf als CTE, Beenden im Hauptbefehl): Beide sehen denselben Snapshot vom Beginn der
-- Anweisung, in dem die Person noch aktiv und die Zuordnungen noch gültig sind. So verliert eine Referent:in
-- weder durch den neuen Status noch durch eine rückdatierte Beendigung die Sichtbarkeit mitten im Vorgang.
create function public.ea_leave(p_person uuid, p_valid_from date, p_end_property_ids uuid[])
returns void
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_status public.ea_volunteer_status;
  v_from date := coalesce(p_valid_from, current_date);
  v_limit date := (current_date + interval '1 year')::date;
  v_ids uuid[] := array(select distinct x from unnest(coalesce(p_end_property_ids, '{}'::uuid[])) as x where x is not null);
  v_id uuid;
  v_ok boolean;
  v_count int;
begin
  select pe.volunteer_status into v_status from public.ea_persons pe where pe.id = p_person;
  if not found or v_status is null then
    raise exception 'EA_STATUS_FORBIDDEN' using errcode = 'P0001';
  end if;
  if v_from > v_limit then
    raise exception 'EA_STATUS_DATE' using errcode = 'P0001', detail = to_char(v_limit, 'DD.MM.YYYY');
  end if;
  if v_status = 'left' then
    raise exception 'EA_STATUS_UNCHANGED' using errcode = 'P0001';
  end if;

  -- R20: jede ID gehört zur Person, ist aktuell, beginnt spätestens am Austrittsdatum und ist schreibbar
  foreach v_id in array v_ids loop
    select p.person_id = p_person
           and p.valid_from <= current_date
           and (p.valid_to is null or p.valid_to >= current_date)
           and p.valid_from <= v_from
           and public.ea_property_writable(p.property_type_id, p.person_id, p.related_referat_id)
      into v_ok
      from public.ea_properties p
     where p.id = v_id;
    if not found or not coalesce(v_ok, false) then
      raise exception 'EA_LEAVE_PROPERTY' using errcode = 'P0001';
    end if;
  end loop;

  with status as (
    select public.ea_set_volunteer_status(p_person, 'left', v_from) as done
  )
  update public.ea_properties p
     set valid_to = v_from
   where p.id = any (v_ids)
     and (select count(*) from status) = 1;
  get diagnostics v_count = row_count;
  if v_count <> cardinality(v_ids) then
    raise exception 'EA_LEAVE_PROPERTY' using errcode = 'P0001';
  end if;

  -- ohne zu beendende Eigenschaften lief der Statusaufruf noch nicht
  if cardinality(v_ids) = 0 then
    perform public.ea_set_volunteer_status(p_person, 'left', v_from);
  end if;
end;
$$;

-- Verlängern (R6): neue Eigenschaft mit denselben Werten plus p_field_values; die alte endet am Vortag.
-- Nur aktuelle Lizenzen und Qualifikationen; das neue Datum muss nach dem bisherigen „gültig von“ liegen.
-- Eine historische Qualifikationsart lehnt der Trigger der Administration ab (AD_QUALIFICATION_HISTORIC, O2).
-- Optional entsteht eine Fortbildung (further_training) mit der Qualifikationsart der Lizenz.
create function public.ea_renew_property(
  p_property uuid, p_valid_from date, p_field_values jsonb, p_training jsonb default null)
returns uuid
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_old public.ea_properties%rowtype;
  v_key text;
  v_new uuid;
  v_training_type uuid;
  v_training_values jsonb;
  v_count int;
begin
  select p.* into v_old from public.ea_properties p where p.id = p_property;
  if not found then
    raise exception 'EA_RENEW_INVALID' using errcode = 'P0001';
  end if;
  select t.system_key into v_key from public.ea_property_types t where t.id = v_old.property_type_id;
  if v_key is null or v_key not in ('license', 'qualification')
     or v_old.valid_from > current_date
     or (v_old.valid_to is not null and v_old.valid_to < current_date)
     or p_valid_from is null or p_valid_from <= v_old.valid_from then
    raise exception 'EA_RENEW_INVALID' using errcode = 'P0001';
  end if;

  update public.ea_properties p set valid_to = p_valid_from - 1 where p.id = p_property;
  get diagnostics v_count = row_count;
  if v_count <> 1 then
    raise exception 'AD_FORBIDDEN' using errcode = 'P0001';
  end if;

  insert into public.ea_properties
    (person_id, property_type_id, field_values, related_referat_id, related_gremium_id, valid_from, valid_to)
  values (v_old.person_id, v_old.property_type_id,
          v_old.field_values || coalesce(p_field_values, '{}'::jsonb),
          v_old.related_referat_id, v_old.related_gremium_id, p_valid_from, null)
  returning id into v_new;

  if p_training is not null and jsonb_typeof(p_training) = 'object' then
    select t.id into v_training_type from public.ea_property_types t where t.system_key = 'further_training';
    v_training_values := jsonb_build_object(
      'year', (p_training ->> 'year')::int,
      'title', p_training ->> 'title');
    if v_key = 'license' and v_old.field_values ? 'qualification_type' then
      v_training_values := v_training_values
        || jsonb_build_object('qualification_type', v_old.field_values ->> 'qualification_type');
    end if;
    insert into public.ea_properties (person_id, property_type_id, field_values, valid_from)
    values (v_old.person_id, v_training_type, v_training_values, p_valid_from);
  end if;

  return v_new;
end;
$$;

revoke all on function public.ea_change_volunteer_status(uuid, public.ea_volunteer_status, date) from public, anon;
revoke all on function public.ea_leave(uuid, date, uuid[]) from public, anon;
revoke all on function public.ea_renew_property(uuid, date, jsonb, jsonb) from public, anon;
grant execute on function public.ea_change_volunteer_status(uuid, public.ea_volunteer_status, date) to authenticated;
grant execute on function public.ea_leave(uuid, date, uuid[]) to authenticated;
grant execute on function public.ea_renew_property(uuid, date, jsonb, jsonb) to authenticated;
