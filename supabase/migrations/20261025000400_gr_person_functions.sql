-- US-GR-06, US-GR-07, US-GR-09, spec T4 (GR spec.md 2.2, 2.3): Personen anlegen oder übernehmen, Aufnahme offen,
-- Personenangaben ändern, Erziehungsberechtigte und Notfallkontakte. security definer; GR ≥ edit zuerst.
-- Personenangaben als Eigenschaften der System-Eigenschaftsarten birth_date, contact, member (eine Person, alle Module).

-- Text aus jsonb: getrimmt, leer = null; intern
create function public.gr_text(p_data jsonb, p_key text)
returns text
language sql
immutable
set search_path = ''
as $$
  select nullif(btrim(coalesce(p_data ->> p_key, '')), '');
$$;

-- Aktuelle Eigenschaft einer System-Eigenschaftsart (heute gültig, sonst die jüngste); intern
create function public.gr_current_property(p_person uuid, p_system_key text)
returns public.ea_properties
language sql
stable
security definer
set search_path = ''
as $$
  select p.*
    from public.ea_properties p
    join public.ea_property_types t on t.id = p.property_type_id and t.system_key = p_system_key
   where p.person_id = p_person
   order by (p.valid_from <= public.gr_today() and (p.valid_to is null or p.valid_to >= public.gr_today())) desc,
            p.valid_from desc
   limit 1;
$$;

-- Felder der Kontaktdaten setzen (nur übergebene Schlüssel); eine Eigenschaft je Person, Änderung als Update; intern
create function public.gr_set_contact(p_person uuid, p_values jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_prop public.ea_properties%rowtype;
  v_values jsonb := '{}';
  v_key text;
begin
  foreach v_key in array array['street', 'postal_code', 'city', 'phone_mobile', 'phone_landline', 'email'] loop
    if p_values ? v_key then
      v_values := v_values || jsonb_build_object(v_key, public.gr_text(p_values, v_key));
    end if;
  end loop;
  if v_values = '{}' then
    return;
  end if;

  v_prop := public.gr_current_property(p_person, 'contact');
  if v_prop.id is null then
    v_values := jsonb_strip_nulls(v_values);
    if v_values = '{}' then
      return;
    end if;
    insert into public.ea_properties (person_id, property_type_id, field_values, valid_from)
    select p_person, t.id, v_values, public.gr_today()
      from public.ea_property_types t where t.system_key = 'contact';
  else
    update public.ea_properties
       set field_values = jsonb_strip_nulls(field_values || v_values)
     where id = v_prop.id;
  end if;
end;
$$;

-- Geburtsdatum setzen; valid_from = Geburtsdatum; intern
create function public.gr_set_birth_date(p_person uuid, p_birth_date text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_prop public.ea_properties%rowtype;
  v_date date;
begin
  begin
    v_date := p_birth_date::date;
  exception when others then
    raise exception 'EA_VALUE_TYPE' using errcode = 'P0001', detail = 'Geburtsdatum';
  end;
  v_prop := public.gr_current_property(p_person, 'birth_date');
  if v_prop.id is null then
    insert into public.ea_properties (person_id, property_type_id, field_values, valid_from)
    select p_person, t.id, jsonb_build_object('date', to_char(v_date, 'YYYY-MM-DD')), v_date
      from public.ea_property_types t where t.system_key = 'birth_date';
  else
    update public.ea_properties
       set field_values = jsonb_build_object('date', to_char(v_date, 'YYYY-MM-DD')), valid_from = v_date
     where id = v_prop.id;
  end if;
end;
$$;

-- Mitgliedsnummer (R25): gesetzt → Mitglied ja mit Nummer; leer → laufende Eigenschaft endet zum Vortag; intern
create function public.gr_set_member_number(p_person uuid, p_number text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_prop public.ea_properties%rowtype;
  v_today date := public.gr_today();
begin
  select p.* into v_prop
    from public.ea_properties p
    join public.ea_property_types t on t.id = p.property_type_id and t.system_key = 'member'
   where p.person_id = p_person and (p.valid_to is null or p.valid_to >= v_today)
   order by p.valid_from desc
   limit 1;

  if p_number is null then
    if v_prop.id is not null then
      update public.ea_properties set valid_to = greatest(v_today - 1, v_prop.valid_from) where id = v_prop.id;
    end if;
  elsif v_prop.id is null then
    insert into public.ea_properties (person_id, property_type_id, field_values, valid_from)
    select p_person, t.id, jsonb_build_object('is_member', true, 'member_number', p_number), v_today
      from public.ea_property_types t where t.system_key = 'member';
  else
    update public.ea_properties
       set field_values = jsonb_build_object('is_member', true, 'member_number', p_number)
     where id = v_prop.id;
  end if;
end;
$$;

-- Erreichbar: Telefon mobil, Festnetz oder E-Mail (R7); intern
create function public.gr_is_reachable(p_person uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((
    select (c.field_values ? 'phone_mobile') or (c.field_values ? 'phone_landline') or (c.field_values ? 'email')
      from public.gr_current_property(p_person, 'contact') c
     where c.id is not null
  ), false);
$$;

-- Adresse vollständig (Straße, PLZ, Ort); intern
create function public.gr_has_address(p_person uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((
    select (c.field_values ? 'street') and (c.field_values ? 'postal_code') and (c.field_values ? 'city')
      from public.gr_current_property(p_person, 'contact') c
     where c.id is not null
  ), false);
$$;

-- Neue Person aus p_new_person anlegen (Rolle participant, guardian, contact, function); intern
create function public.gr_create_person(p_new jsonb, p_role text, p_created_in text default 'GR')
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid;
  v_birth text := public.gr_text(p_new, 'birth_date');
  v_address boolean := public.gr_text(p_new, 'street') is not null
                       and public.gr_text(p_new, 'postal_code') is not null
                       and public.gr_text(p_new, 'city') is not null;
  v_names boolean := public.gr_text(p_new, 'first_name') is not null and public.gr_text(p_new, 'last_name') is not null;
begin
  if v_birth is not null and auth.uid() is not null and not public.ad_has_level('GR', 'manage') then
    raise exception 'GR_BIRTH_DATE_FORBIDDEN' using errcode = 'P0001';
  end if;
  if p_role = 'participant' and not (v_names and v_birth is not null and v_address) then
    raise exception 'GR_PARTICIPANT_FIELDS_REQUIRED' using errcode = 'P0001';
  end if;
  if p_role = 'guardian' and not (v_names and v_address) then
    raise exception 'GR_GUARDIAN_FIELDS_REQUIRED' using errcode = 'P0001';
  end if;
  if p_role = 'contact' and v_names
     and public.gr_text(p_new, 'phone_mobile') is null
     and public.gr_text(p_new, 'phone_landline') is null
     and public.gr_text(p_new, 'email') is null then
    raise exception 'GR_CONTACT_REACHABILITY' using errcode = 'P0001';
  end if;

  -- Vor- und Nachname prüft der Trigger ea_persons_normalize (AD_NAME_REQUIRED, R4 AD)
  insert into public.ea_persons (first_name, last_name, preferred_name, created_in)
  values (coalesce(p_new ->> 'first_name', ''), coalesce(p_new ->> 'last_name', ''),
          public.gr_text(p_new, 'preferred_name'), p_created_in)
  returning id into v_id;

  if v_birth is not null then
    perform public.gr_set_birth_date(v_id, v_birth);
  end if;
  perform public.gr_set_contact(v_id, p_new);
  if public.gr_text(p_new, 'member_number') is not null then
    perform public.gr_set_member_number(v_id, public.gr_text(p_new, 'member_number'));
  end if;
  return v_id;
end;
$$;

-- Genau eine vorhandene oder eine neue Person (Übernahmeregel spec.md 2.3, Ü2); intern
create function public.gr_resolve_person(p_person_id uuid, p_new jsonb, p_role text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (p_person_id is null) = (p_new is null or p_new = '{}' or jsonb_typeof(p_new) = 'null') then
    raise exception 'GR_PERSON_INVALID' using errcode = 'P0001';
  end if;
  if p_person_id is not null then
    -- vorhandene Person, auch wenn sie für den Nutzer nicht sichtbar ist (Übernahme nicht sichtbarer Treffer)
    if not exists (select 1 from public.ea_persons pe where pe.id = p_person_id and pe.kind = 'human') then
      raise exception 'GR_PERSON_INVALID' using errcode = 'P0001';
    end if;
    return p_person_id;
  end if;
  return public.gr_create_person(p_new, p_role);
end;
$$;

-- Kind im Pfad GR mit edit sichtbar; intern
create function public.gr_check_child(p_child uuid)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.gr_person_visible(p_child, 'edit') then
    raise exception 'GR_FORBIDDEN' using errcode = 'P0001';
  end if;
end;
$$;

revoke all on function public.gr_text(jsonb, text) from public, anon, authenticated;
revoke all on function public.gr_current_property(uuid, text) from public, anon, authenticated;
revoke all on function public.gr_set_contact(uuid, jsonb) from public, anon, authenticated;
revoke all on function public.gr_set_birth_date(uuid, text) from public, anon, authenticated;
revoke all on function public.gr_set_member_number(uuid, text) from public, anon, authenticated;
revoke all on function public.gr_is_reachable(uuid) from public, anon, authenticated;
revoke all on function public.gr_has_address(uuid) from public, anon, authenticated;
revoke all on function public.gr_create_person(jsonb, text, text) from public, anon, authenticated;
revoke all on function public.gr_resolve_person(uuid, jsonb, text) from public, anon, authenticated;
revoke all on function public.gr_check_child(uuid) from public, anon, authenticated;

-- Aufnahme beginnen (Schritt 1 des Assistenten): Person anlegen oder übernehmen, „Aufnahme offen“ (R2, R10)
create function public.gr_start_admission(p_group uuid, p_person_id uuid default null, p_new_person jsonb default null)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_person uuid;
begin
  if not public.ad_has_level('GR', 'edit') then
    raise exception 'GR_FORBIDDEN' using errcode = 'P0001';
  end if;
  perform public.gr_check_group_open(p_group);

  if p_person_id is not null then
    if exists (select 1 from public.gr_pending_admissions a where a.person_id = p_person_id) then
      raise exception 'GR_PENDING_EXISTS' using errcode = 'P0001';
    end if;
    if exists (select 1 from public.gr_memberships m
                where m.person_id = p_person_id and m.group_id = p_group
                  and (m.left_on is null or m.left_on >= public.gr_today())) then
      raise exception 'GR_ALREADY_MEMBER' using errcode = 'P0001';
    end if;
  end if;

  v_person := public.gr_resolve_person(p_person_id, p_new_person, 'participant');
  insert into public.gr_pending_admissions (person_id, group_id) values (v_person, p_group);
  return v_person;
end;
$$;

-- Aufnahme abbrechen: Zeile löschen; Zuordnungen bleiben (W7)
create function public.gr_cancel_admission(p_person uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.ad_has_level('GR', 'edit') then
    raise exception 'GR_FORBIDDEN' using errcode = 'P0001';
  end if;
  delete from public.gr_pending_admissions where person_id = p_person;
end;
$$;

-- Namen und Personenangaben ändern (nur übergebene Schlüssel); prüft R2, R26, R7 nach dem Speichern
create function public.gr_update_person(p_person uuid, p_data jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_today date := public.gr_today();
begin
  if not public.ad_has_level('GR', 'edit') or not public.gr_person_visible(p_person, 'edit') then
    raise exception 'GR_FORBIDDEN' using errcode = 'P0001';
  end if;
  if p_data ? 'birth_date' and not public.ad_has_level('GR', 'manage') then
    raise exception 'GR_BIRTH_DATE_FORBIDDEN' using errcode = 'P0001';
  end if;

  if p_data ? 'first_name' or p_data ? 'last_name' or p_data ? 'preferred_name' then
    update public.ea_persons pe
       set first_name = case when p_data ? 'first_name' then coalesce(p_data ->> 'first_name', '') else pe.first_name end,
           last_name = case when p_data ? 'last_name' then coalesce(p_data ->> 'last_name', '') else pe.last_name end,
           preferred_name = case when p_data ? 'preferred_name' then public.gr_text(p_data, 'preferred_name')
                                 else pe.preferred_name end
     where pe.id = p_person;
  end if;
  if public.gr_text(p_data, 'birth_date') is not null then
    perform public.gr_set_birth_date(p_person, public.gr_text(p_data, 'birth_date'));
  end if;
  perform public.gr_set_contact(p_person, p_data);
  if p_data ? 'member_number' then
    perform public.gr_set_member_number(p_person, public.gr_text(p_data, 'member_number'));
  end if;

  -- R2: Teilnehmer:in mit laufender Teilnahme oder offener Aufnahme
  if (exists (select 1 from public.gr_pending_admissions a where a.person_id = p_person)
      or exists (select 1 from public.gr_memberships m
                  where m.person_id = p_person and (m.left_on is null or m.left_on >= v_today)))
     and (not public.gr_has_address(p_person)
          or (public.gr_current_property(p_person, 'birth_date')).id is null) then
    raise exception 'GR_PARTICIPANT_FIELDS_REQUIRED' using errcode = 'P0001';
  end if;
  -- R26: Erziehungsberechtigte:r
  if exists (select 1 from public.gr_guardians g where g.guardian_person_id = p_person)
     and not public.gr_has_address(p_person) then
    raise exception 'GR_GUARDIAN_FIELDS_REQUIRED' using errcode = 'P0001';
  end if;
  -- R7: Notfallkontakt
  if exists (select 1 from public.gr_emergency_contacts e where e.contact_person_id = p_person)
     and not public.gr_is_reachable(p_person) then
    raise exception 'GR_CONTACT_REACHABILITY' using errcode = 'P0001';
  end if;
end;
$$;

-- Adresse der erziehungsberechtigten Person in die Kontaktdaten des Kindes kopieren (einmalig, A3)
create function public.gr_copy_address(p_child uuid, p_from_guardian uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_from public.ea_properties%rowtype;
begin
  if not public.ad_has_level('GR', 'edit') then
    raise exception 'GR_FORBIDDEN' using errcode = 'P0001';
  end if;
  perform public.gr_check_child(p_child);
  if not exists (select 1 from public.gr_guardians g
                  where g.child_person_id = p_child and g.guardian_person_id = p_from_guardian) then
    raise exception 'GR_PERSON_INVALID' using errcode = 'P0001';
  end if;
  v_from := public.gr_current_property(p_from_guardian, 'contact');
  perform public.gr_set_contact(p_child, jsonb_build_object(
    'street', v_from.field_values ->> 'street',
    'postal_code', v_from.field_values ->> 'postal_code',
    'city', v_from.field_values ->> 'city'));
end;
$$;

-- Erziehungsberechtigte:n hinzufügen (R3, R22, R26)
create function public.gr_add_guardian(p_child uuid, p_person_id uuid default null, p_new_person jsonb default null)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_person uuid;
begin
  if not public.ad_has_level('GR', 'edit') then
    raise exception 'GR_FORBIDDEN' using errcode = 'P0001';
  end if;
  perform public.gr_check_child(p_child);
  if (select count(*) from public.gr_guardians g where g.child_person_id = p_child) >= 2 then
    raise exception 'GR_GUARDIAN_LIMIT' using errcode = 'P0001';
  end if;
  if p_person_id is not null
     and exists (select 1 from public.gr_guardians g
                  where g.child_person_id = p_child and g.guardian_person_id = p_person_id) then
    raise exception 'GR_GUARDIAN_EXISTS' using errcode = 'P0001';
  end if;
  if p_person_id = p_child then
    raise exception 'GR_PERSON_INVALID' using errcode = 'P0001';
  end if;

  v_person := public.gr_resolve_person(p_person_id, p_new_person, 'guardian');
  insert into public.gr_guardians (child_person_id, guardian_person_id) values (p_child, v_person);
  return v_person;
end;
$$;

-- Erziehungsberechtigte:n entfernen; nicht als Vertragsinhaber:in eines nicht beendeten Vertrags (R22)
create function public.gr_remove_guardian(p_child uuid, p_guardian uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.ad_has_level('GR', 'edit') then
    raise exception 'GR_FORBIDDEN' using errcode = 'P0001';
  end if;
  perform public.gr_check_child(p_child);
  if exists (select 1 from public.gr_contracts c join public.gr_memberships m on m.id = c.membership_id
              where m.person_id = p_child and c.holder_person_id = p_guardian
                and (c.ends_on is null or c.ends_on >= public.gr_today())) then
    raise exception 'GR_GUARDIAN_IS_HOLDER' using errcode = 'P0001';
  end if;
  delete from public.gr_guardians where child_person_id = p_child and guardian_person_id = p_guardian;
end;
$$;

-- Notfallkontakt hinzufügen (R7, R23); sort_order = höchste + 1
create function public.gr_add_emergency_contact(p_child uuid, p_person_id uuid default null, p_new_person jsonb default null)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_person uuid;
begin
  if not public.ad_has_level('GR', 'edit') then
    raise exception 'GR_FORBIDDEN' using errcode = 'P0001';
  end if;
  perform public.gr_check_child(p_child);
  if p_person_id is not null
     and exists (select 1 from public.gr_emergency_contacts e
                  where e.child_person_id = p_child and e.contact_person_id = p_person_id) then
    raise exception 'GR_EMERGENCY_EXISTS' using errcode = 'P0001';
  end if;
  if p_person_id = p_child then
    raise exception 'GR_PERSON_INVALID' using errcode = 'P0001';
  end if;

  v_person := public.gr_resolve_person(p_person_id, p_new_person, 'contact');
  if not public.gr_is_reachable(v_person) then
    raise exception 'GR_CONTACT_REACHABILITY' using errcode = 'P0001';
  end if;
  insert into public.gr_emergency_contacts (child_person_id, contact_person_id, sort_order)
  select p_child, v_person, coalesce(max(e.sort_order), 0) + 1
    from public.gr_emergency_contacts e where e.child_person_id = p_child;
  return v_person;
end;
$$;

-- Notfallkontakt entfernen; Reihenfolge der übrigen 1…n
create function public.gr_remove_emergency_contact(p_child uuid, p_contact uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.ad_has_level('GR', 'edit') then
    raise exception 'GR_FORBIDDEN' using errcode = 'P0001';
  end if;
  perform public.gr_check_child(p_child);
  delete from public.gr_emergency_contacts where child_person_id = p_child and contact_person_id = p_contact;
  update public.gr_emergency_contacts e
     set sort_order = s.rn
    from (select id, row_number() over (order by sort_order, created_at) as rn
            from public.gr_emergency_contacts where child_person_id = p_child) s
   where e.id = s.id;
end;
$$;

-- Reihenfolge setzen: Liste muss genau alle Notfallkontakte des Kindes enthalten
create function public.gr_reorder_emergency_contacts(p_child uuid, p_contact_ids uuid[])
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.ad_has_level('GR', 'edit') then
    raise exception 'GR_FORBIDDEN' using errcode = 'P0001';
  end if;
  perform public.gr_check_child(p_child);
  if p_contact_ids is null
     or cardinality(p_contact_ids) <> (select count(distinct x) from unnest(p_contact_ids) as x)
     or (select array_agg(e.contact_person_id order by e.contact_person_id)
           from public.gr_emergency_contacts e where e.child_person_id = p_child)
        is distinct from (select array_agg(x order by x) from unnest(p_contact_ids) as x) then
    raise exception 'GR_ORDER_INVALID' using errcode = 'P0001';
  end if;
  update public.gr_emergency_contacts e
     set sort_order = o.pos
    from unnest(p_contact_ids) with ordinality as o (contact_id, pos)
   where e.child_person_id = p_child and e.contact_person_id = o.contact_id;
end;
$$;

revoke all on function public.gr_start_admission(uuid, uuid, jsonb) from public, anon, authenticated;
revoke all on function public.gr_cancel_admission(uuid) from public, anon, authenticated;
revoke all on function public.gr_update_person(uuid, jsonb) from public, anon, authenticated;
revoke all on function public.gr_copy_address(uuid, uuid) from public, anon, authenticated;
revoke all on function public.gr_add_guardian(uuid, uuid, jsonb) from public, anon, authenticated;
revoke all on function public.gr_remove_guardian(uuid, uuid) from public, anon, authenticated;
revoke all on function public.gr_add_emergency_contact(uuid, uuid, jsonb) from public, anon, authenticated;
revoke all on function public.gr_remove_emergency_contact(uuid, uuid) from public, anon, authenticated;
revoke all on function public.gr_reorder_emergency_contacts(uuid, uuid[]) from public, anon, authenticated;
grant execute on function public.gr_start_admission(uuid, uuid, jsonb) to authenticated;
grant execute on function public.gr_cancel_admission(uuid) to authenticated;
grant execute on function public.gr_update_person(uuid, jsonb) to authenticated;
grant execute on function public.gr_copy_address(uuid, uuid) to authenticated;
grant execute on function public.gr_add_guardian(uuid, uuid, jsonb) to authenticated;
grant execute on function public.gr_remove_guardian(uuid, uuid) to authenticated;
grant execute on function public.gr_add_emergency_contact(uuid, uuid, jsonb) to authenticated;
grant execute on function public.gr_remove_emergency_contact(uuid, uuid) to authenticated;
grant execute on function public.gr_reorder_emergency_contacts(uuid, uuid[]) to authenticated;
