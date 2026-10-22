-- US-AD-23, spec T39: Ehrenamtsstatus setzen (R33), Referate einer Person, Person anlegen bzw. übernehmen.
-- Kern-Fassung: ea_create_volunteer ohne Erweiterung für die Anwesenheitserfassung (kein p_contact_email,
-- kein created_in = 'EZ'); diese folgt mit spec T53 per neuer Migration.
-- Die Funktionen setzen das transaktionslokale Kennzeichen ea.status_change (Trigger ea_persons_guard, research.md R-23).

-- Status setzen (R33): EA ≥ bearbeiten (Reichweite alle) für jede Person mit Status, Referent:innen für Personen
-- ihrer Referate; Rückkehr aus „ausgeschieden“ mit EA ≥ bearbeiten (Reichweite alle) (spec.md Abschnitt 4)
create function public.ea_set_volunteer_status(
  p_person uuid, p_status public.ea_volunteer_status, p_valid_from date default current_date)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_person public.ea_persons%rowtype;
begin
  select * into v_person from public.ea_persons p where p.id = p_person;
  if not found or v_person.kind <> 'human' or v_person.volunteer_status is null
     or not (public.ea_person_visible_ea(p_person, 'edit')
             or (v_person.volunteer_status = 'left' and public.ad_has_level('EA', 'edit'))) then
    raise exception 'EA_STATUS_FORBIDDEN' using errcode = 'P0001';
  end if;

  if v_person.volunteer_status = p_status then
    return;
  end if;

  perform set_config('ea.status_change', 'on', true);
  update public.ea_persons
     set volunteer_status = p_status, volunteer_status_since = coalesce(p_valid_from, current_date)
   where id = p_person;
  perform set_config('ea.status_change', '', true);

  insert into public.ea_volunteer_status_history (person_id, status, valid_from)
  values (p_person, p_status, coalesce(p_valid_from, current_date));
end;
$$;

-- Aktuelle Referate der Person (Bestätigungsdialog „Die Person ist auch in … tätig“)
create function public.ea_person_referate(p_person uuid)
returns table (id uuid, name text)
language sql
stable
security definer
set search_path = ''
as $$
  select r.id, r.name
    from public.ea_referate r
   where public.ea_person_visible_ea(p_person)
     and exists (
       select 1 from public.ea_properties p
        where p.person_id = p_person
          and p.related_referat_id = r.id
          and p.valid_from <= current_date
          and (p.valid_to is null or p.valid_to >= current_date)
     )
   order by r.sort_order, r.name;
$$;

-- Darf der Aufrufer eine Person im Pfad EA anlegen bzw. übernehmen? (R41)
create function public.ea_check_create(p_property_type uuid, p_referat uuid)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if public.ad_has_level('EA', 'edit') then
    return;
  end if;
  if cardinality(public.ad_my_referate('EA', 'edit')) = 0 then
    raise exception 'AD_FORBIDDEN' using errcode = 'P0001';
  end if;
  -- Reichweite Referat: erste Zuordnung mit Bezug auf ein eigenes Referat ist Pflicht [ANNAHME v0.7]
  if p_property_type is null or p_referat is null then
    raise exception 'EA_RELATION_REQUIRED' using errcode = 'P0001';
  end if;
  if not (p_referat = any (public.ad_my_referate('EA', 'edit'))) then
    raise exception 'EA_RELATION_FOREIGN_REFERAT' using errcode = 'P0001';
  end if;
end;
$$;

revoke all on function public.ea_check_create(uuid, uuid) from public, anon, authenticated;

-- Person mit Ehrenamtsstatus „aktiv“ und erster Zuordnung in einer Transaktion anlegen
create function public.ea_create_volunteer(
  p_first text, p_last text, p_preferred text, p_property_type uuid, p_referat uuid,
  p_field_values jsonb, p_valid_from date)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid;
  v_from date := coalesce(p_valid_from, current_date);
begin
  perform public.ea_check_create(p_property_type, p_referat);

  insert into public.ea_persons (first_name, last_name, preferred_name, created_in, volunteer_status, volunteer_status_since)
  values (p_first, p_last, p_preferred, 'EA', 'active', v_from)
  returning id into v_id;

  insert into public.ea_volunteer_status_history (person_id, status, valid_from)
  values (v_id, 'active', v_from);

  if p_property_type is not null then
    insert into public.ea_properties (person_id, property_type_id, field_values, related_referat_id, valid_from)
    values (v_id, p_property_type, coalesce(p_field_values, '{}'), p_referat, v_from);
  end if;

  return v_id;
end;
$$;

-- Rückkehr Ausgeschiedener bzw. Übernahme aus einem anderen Pfad (E1): Status „aktiv“ und Zuordnung
create function public.ea_activate_person(
  p_person uuid, p_property_type uuid, p_referat uuid, p_field_values jsonb, p_valid_from date)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_person public.ea_persons%rowtype;
  v_from date := coalesce(p_valid_from, current_date);
begin
  perform public.ea_check_create(p_property_type, p_referat);

  select * into v_person from public.ea_persons p where p.id = p_person;
  if not found or v_person.kind <> 'human' then
    raise exception 'AD_BAD_REQUEST' using errcode = 'P0001';
  end if;

  if v_person.volunteer_status is distinct from 'active' then
    perform set_config('ea.status_change', 'on', true);
    update public.ea_persons
       set volunteer_status = 'active', volunteer_status_since = v_from
     where id = p_person;
    perform set_config('ea.status_change', '', true);
    insert into public.ea_volunteer_status_history (person_id, status, valid_from)
    values (p_person, 'active', v_from);
  end if;

  if p_property_type is not null then
    insert into public.ea_properties (person_id, property_type_id, field_values, related_referat_id, valid_from)
    values (p_person, p_property_type, coalesce(p_field_values, '{}'), p_referat, v_from);
  end if;
end;
$$;

revoke all on function public.ea_set_volunteer_status(uuid, public.ea_volunteer_status, date) from public, anon, authenticated;
revoke all on function public.ea_person_referate(uuid) from public, anon, authenticated;
revoke all on function public.ea_create_volunteer(text, text, text, uuid, uuid, jsonb, date) from public, anon, authenticated;
revoke all on function public.ea_activate_person(uuid, uuid, uuid, jsonb, date) from public, anon, authenticated;
grant execute on function public.ea_set_volunteer_status(uuid, public.ea_volunteer_status, date) to authenticated;
grant execute on function public.ea_person_referate(uuid) to authenticated;
grant execute on function public.ea_create_volunteer(text, text, text, uuid, uuid, jsonb, date) to authenticated;
grant execute on function public.ea_activate_person(uuid, uuid, uuid, jsonb, date) to authenticated;
