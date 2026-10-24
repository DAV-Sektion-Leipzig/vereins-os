-- Nachtrag v0.8 (spec.md AD v0.9.4, Nachtrag v0.8.1), spec T53; US-AD-30; Übergabe EZ A4, A9; R45, R45a.
-- Anlegen und Wieder-aktiv-Eintragen von Helfer:innen aus der Anwesenheitserfassung:
--   ea_create_path      intern: entscheidet EA- oder EZ-Weg und prüft die Rechte
--   ea_create_volunteer neue Fassung mit p_contact_email und created_in = 'EZ' (alte Signatur entfällt, Aufrufe
--                       mit benannten Parametern bleiben gültig)
--   ea_activate_person  neue Fassung mit dem EZ-Weg (A9: ruhend, ausgeschieden, ohne Ehrenamtsstatus; auch
--                       referatsübergreifend; Product Owner 24.10.2026)
--   ad_find_similar_persons auch mit EZ ≥ bearbeiten
-- Regel (spec.md Abschnitt 2): Der EZ-Weg gilt nur, wenn der Aufruf ausschließlich über EZ-Rechte erlaubt ist.
-- Wer den EA-Weg nutzen darf (z. B. Referent:in mit EA bearbeiten im Referat), legt mit created_in = 'EA' an.

-- EA-Weg zuerst (ea_check_create mit allen Prüfungen und Codes des Ehrenamtsmanagements); scheitert er nur an
-- den Rechten bzw. am Referat und hat der Nutzer passende EZ-Rechte, gilt der EZ-Weg: Referat Pflicht, nur Funktion Helfer:in, Referat aus den
-- eigenen EZ-Referaten (bei Reichweite „Referat“). Rückgabe 'EA' oder 'EZ'.
create function public.ea_create_path(p_property_type uuid, p_referat uuid, p_field_values jsonb)
returns text
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_ea_error text;
  v_ez_all boolean := public.ad_has_level('EZ', 'edit');
  v_ez_referate uuid[] := public.ad_my_referate('EZ', 'edit');
begin
  begin
    perform public.ea_check_create(p_property_type, p_referat);
    return 'EA';
  exception when sqlstate 'P0001' then
    v_ea_error := sqlerrm;
  end;

  -- Der EZ-Weg greift nur, wenn der EA-Weg an fehlenden Rechten (kein EA-Recht) oder am Referat scheitert
  -- und die EZ-Rechte dafür reichen; sonst gilt die Meldung des EA-Wegs (z. B. vertrauliche Art, Bezugsart).
  if not (v_ez_all or cardinality(v_ez_referate) > 0)
     or not (v_ea_error = 'EA_CREATE_FORBIDDEN'
             or (v_ea_error = 'EA_RELATION_FOREIGN_REFERAT' and (v_ez_all or p_referat = any (v_ez_referate)))) then
    raise exception '%', v_ea_error using errcode = 'P0001';
  end if;

  if p_referat is null
     or p_property_type is distinct from (select t.id from public.ea_property_types t where t.system_key = 'function')
     or p_field_values is distinct from '{"function": "Helfer:in"}'::jsonb then
    raise exception 'EA_CREATE_FORBIDDEN' using errcode = 'P0001';
  end if;

  if not v_ez_all and not (p_referat = any (v_ez_referate)) then
    raise exception 'EA_RELATION_FOREIGN_REFERAT' using errcode = 'P0001';
  end if;

  return 'EZ';
end;
$$;

revoke all on function public.ea_create_path(uuid, uuid, jsonb) from public, anon, authenticated;

drop function public.ea_create_volunteer(text, text, text, uuid, uuid, jsonb, date);

create function public.ea_create_volunteer(
  p_first text, p_last text, p_preferred text, p_property_type uuid, p_referat uuid,
  p_field_values jsonb, p_valid_from date, p_contact_email text default null)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid;
  v_from date := coalesce(p_valid_from, current_date);
  v_path text := public.ea_create_path(p_property_type, p_referat, p_field_values);
  v_email text := nullif(btrim(coalesce(p_contact_email, '')), '');
begin
  insert into public.ea_persons (first_name, last_name, preferred_name, created_in, volunteer_status, volunteer_status_since)
  values (p_first, p_last, p_preferred, v_path, 'active', v_from)
  returning id into v_id;

  insert into public.ea_volunteer_status_history (person_id, status, valid_from)
  values (v_id, 'active', v_from);

  if p_property_type is not null then
    insert into public.ea_properties (person_id, property_type_id, field_values, related_referat_id, valid_from)
    values (v_id, p_property_type, coalesce(p_field_values, '{}'), p_referat, v_from);
  end if;

  -- Kontakt-E-Mail (R45; Feldschlüssel nach 01-erhebung.md EA C2 Nr. 4)
  if v_email is not null then
    insert into public.ea_properties (person_id, property_type_id, field_values, valid_from)
    select v_id, t.id, jsonb_build_object('email', v_email), v_from
      from public.ea_property_types t where t.system_key = 'contact';
  end if;

  return v_id;
end;
$$;

revoke all on function public.ea_create_volunteer(text, text, text, uuid, uuid, jsonb, date, text) from public, anon, authenticated;
grant execute on function public.ea_create_volunteer(text, text, text, uuid, uuid, jsonb, date, text) to authenticated;

create or replace function public.ea_activate_person(
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
  perform public.ea_create_path(p_property_type, p_referat, p_field_values);

  select * into v_person from public.ea_persons p where p.id = p_person;
  if not found or v_person.kind <> 'human' then
    raise exception 'AD_BAD_REQUEST' using errcode = 'P0001';
  end if;

  -- ruhend, ausgeschieden oder ohne Status → aktiv mit Historie; bei „aktiv“ bleibt der Status (R45a)
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

-- Dublettenprüfung auch für die Anwesenheitserfassung (R45, A4)
create or replace function public.ad_find_similar_persons(p_first text, p_last text, p_email text)
returns table (person_id uuid, first_name text, last_name text, preferred_name text, birth_year int,
               volunteer_status public.ea_volunteer_status, left_since date, is_visible boolean)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_birth_type uuid;
  v_birth_level public.ea_read_level;
  v_show_birth boolean := false;
  v_email text := lower(btrim(coalesce(p_email, '')));
begin
  if not (public.ad_has_level('AD', 'edit') or public.ad_has_any_level('EA', 'edit') or public.ad_has_level('GR', 'edit')
          or public.ad_has_any_level('EZ', 'edit')) then
    raise exception 'AD_FORBIDDEN' using errcode = 'P0001';
  end if;

  -- Geburtsjahr nur nach der Lesestufe der Art Geburtsdatum (R40, Ü2)
  select t.id, t.read_level into v_birth_type, v_birth_level
    from public.ea_property_types t where t.system_key = 'birth_date';
  v_show_birth := case v_birth_level
    when 'all' then true
    when 'office' then public.ad_has_level('AD', 'read') or public.ad_has_level('EA', 'manage')
                       or public.ad_has_level('GR', 'manage')
    when 'confidential' then public.ad_has_level('AD', 'read')
    else false
  end;

  return query
  select p.id, p.first_name, p.last_name, p.preferred_name,
         case when v_show_birth then (
           select extract(year from (b.field_values ->> 'date')::date)::int
             from public.ea_properties b
            where b.person_id = p.id
              and b.property_type_id = v_birth_type
              and b.field_values ? 'date'
            order by (b.valid_from <= current_date and (b.valid_to is null or b.valid_to >= current_date)) desc,
                     b.valid_from desc
            limit 1
         ) end,
         p.volunteer_status,
         case when p.volunteer_status = 'left' then p.volunteer_status_since end,
         public.ea_person_visible(p.id)
    from public.ea_persons p
   where p.kind = 'human'
     and (
       (lower(btrim(p.last_name)) = lower(btrim(coalesce(p_last, '')))
        and (public.ad_first_names_match(p_first, p.first_name)
             or public.ad_first_names_match(p_first, p.preferred_name)))
       or (v_email <> '' and (
             exists (select 1 from public.ad_accesses a
                      where a.person_id = p.id and lower(a.login_email::text) = v_email)
             or exists (
               select 1
                 from public.ea_properties c
                 join public.ea_property_types ct on ct.id = c.property_type_id and ct.system_key = 'contact'
                where c.person_id = p.id
                  and (lower(c.field_values ->> 'email') = v_email or lower(c.field_values ->> 'dav_email') = v_email)
             )))
     )
   order by p.last_name, p.first_name;
end;
$$;
