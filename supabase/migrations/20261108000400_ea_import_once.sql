-- B-07 (Sicherheits- und Code-Review): Wiederholungsschutz für ea_import_volunteers (US-EA-18; contracts/migration-script.md).
-- Gibt es bereits Personen mit created_in = 'script', bricht ein schreibender Lauf mit EA_IMPORT_ALREADY_RUN ab;
-- der Probelauf meldet denselben Befund als Fehler im Bericht (Code EA_IMPORT_ALREADY_RUN), damit er vorab sichtbar ist.
-- Sonst unverändert gegenüber 20261024000700_ea_import.sql (Signatur, Rückgabe, Prüfungen, Schreiben).

create or replace function public.ea_import_volunteers(p_rows jsonb, p_cutoff date, p_dry_run boolean)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_cutoff date := coalesce(p_cutoff, current_date);
  v_errors jsonb := '[]';
  v_warnings jsonb := '[]';
  v_plans jsonb := '[]';
  v_counts jsonb;
  v_row jsonb;
  v_n int;
  v_props jsonb;
  v_text text;
  v_key text;
  v_value jsonb;
  v_ref record;
  v_qual public.ad_qualification_types;
  v_referat uuid;
  v_gremium uuid;
  v_until date;
  v_licenses int;
  v_numbers int;
  v_has_license boolean;
  v_contact jsonb;
  v_fields jsonb;
  v_from date;
  v_other jsonb;
  v_m int;
  v_person uuid;
  v_plan jsonb;
  v_prop jsonb;
  v_imported bigint;
  v_issue_columns constant jsonb := '{"schluessel_nolimit": "Schlüssel NoLimit", "schluessel_k4": "Schlüssel K4",
                                      "k4_karte": "K4-Karte", "vereinsjacke": "Vereinsjacke"}';
  v_access_columns constant jsonb := '{"dav360": "DAV360", "forms": "Forms", "jdav_verteiler": "JDAV Aktiven-Mailverteiler",
                                       "redaktion": "Redaktion", "mailingliste": "Mailingliste"}';
  v_contact_columns constant jsonb := '{"email": "email", "telefon_mobil": "phone_mobile", "telefon_festnetz": "phone_landline",
                                        "strasse": "street", "plz": "postal_code", "ort": "city", "dav_email": "dav_email"}';
begin
  if p_rows is null or jsonb_typeof(p_rows) <> 'array' then
    raise exception 'AD_BAD_REQUEST' using errcode = 'P0001';
  end if;

  -- Wiederholungsschutz (B-07): Der Import legt Personen mit created_in = 'script' an. Gibt es solche schon,
  -- würde ein zweiter Lauf alle Personen samt Eigenschaften doppelt anlegen. Der schreibende Lauf sperrt
  -- (bis Transaktionsende), damit zwei gleichzeitige Läufe die Prüfung nicht beide bestehen.
  if not p_dry_run then
    perform pg_advisory_xact_lock(hashtext('public.ea_import_volunteers'));
  end if;
  select count(*) into v_imported from public.ea_persons p where p.created_in = 'script';
  if v_imported > 0 then
    if not p_dry_run then
      raise exception 'EA_IMPORT_ALREADY_RUN' using errcode = 'P0001',
        detail = format('%s Personen mit created_in = script vorhanden', v_imported);
    end if;
    v_errors := v_errors || jsonb_build_object('row', 0, 'code', 'EA_IMPORT_ALREADY_RUN', 'message',
      format('Der Import wurde bereits ausgeführt (%s Personen aus dem Migrationsskript vorhanden). '
             'Ein zweiter Lauf würde alle Personen doppelt anlegen.', v_imported));
  end if;

  -- 1. Prüfen und planen
  for v_row in select value from jsonb_array_elements(p_rows) loop
    v_n := coalesce((v_row ->> 'row')::int, 0);
    v_props := '[]';

    foreach v_key in array array['nachname', 'vorname', 'aktiv'] loop
      if nullif(btrim(coalesce(v_row ->> v_key, '')), '') is null then
        v_errors := v_errors || jsonb_build_object('row', v_n, 'message', format('Zeile %s: %s fehlt', v_n, v_key));
      end if;
    end loop;

    -- Lizenzen (L1–L3): Typ Lizenz prüft die Funktion selbst (R-EA-10), gültig bis leer → R5 mit Warnung
    v_licenses := 0;
    v_numbers := 0;
    v_has_license := false;
    for v_m in 1..3 loop
      v_text := nullif(btrim(coalesce(v_row ->> format('l%s_art', v_m), '')), '');
      continue when v_text is null;
      v_has_license := true;
      v_licenses := v_licenses + 1;
      if nullif(btrim(coalesce(v_row ->> format('l%s_nummer', v_m), '')), '') is not null then
        v_numbers := v_numbers + 1;
      end if;
      v_qual := public.ea_import_qualification(v_text);
      if v_qual.id is null then
        v_errors := v_errors || jsonb_build_object('row', v_n,
          'message', format('Zeile %s: Qualifikationsart %s unbekannt', v_n, v_text));
        continue;
      end if;
      if v_qual.kind <> 'license' then
        v_errors := v_errors || jsonb_build_object('row', v_n, 'message', format('Zeile %s: %s ist keine Lizenz', v_n, v_text));
        continue;
      end if;
      v_from := coalesce((v_row ->> format('l%s_erworben_am', v_m))::date, v_cutoff);
      v_until := (v_row ->> format('l%s_gueltig_bis', v_m))::date;
      if v_until is null then
        v_until := public.ea_default_valid_until(v_qual.id, v_from, (v_row ->> format('l%s_letzte_fb', v_m))::date);
        if v_until is null then
          v_errors := v_errors || jsonb_build_object('row', v_n,
            'message', format('Zeile %s: Lizenz %s ohne gültig bis', v_n, coalesce(v_qual.code, v_qual.name)));
          continue;
        end if;
        v_warnings := v_warnings || jsonb_build_object('row', v_n, 'message',
          format('Zeile %s: Lizenz %s ohne gültig bis, berechnet %s', v_n, coalesce(v_qual.code, v_qual.name),
                 to_char(v_until, 'DD.MM.YYYY')));
      end if;
      v_props := v_props || jsonb_build_object('system_key', 'license', 'valid_from', v_from,
        'field_values', jsonb_strip_nulls(jsonb_build_object(
          'qualification_type', v_qual.id,
          'valid_until', v_until,
          'license_number', nullif(btrim(coalesce(v_row ->> format('l%s_nummer', v_m), '')), ''),
          'dosb_valid_until', v_row ->> format('l%s_dosb_gueltig_bis', v_m),
          'last_training', v_row ->> format('l%s_letzte_fb', v_m))));
    end loop;
    if v_licenses > v_numbers then
      v_warnings := v_warnings || jsonb_build_object('row', v_n,
        'message', format('Zeile %s: %s Lizenzen, %s Lizenznummern', v_n, v_licenses, v_numbers));
    end if;

    -- Referate → je Referat eine Funktion (R15)
    for v_text in select btrim(x) from jsonb_array_elements_text(coalesce(v_row -> 'referate', '[]')) as x where btrim(x) <> '' loop
      select r.id into v_referat from public.ea_referate r where lower(r.name) = lower(v_text) and r.is_active;
      if v_referat is null then
        v_errors := v_errors || jsonb_build_object('row', v_n, 'message', format('Zeile %s: Referat %s unbekannt', v_n, v_text));
        continue;
      end if;
      v_props := v_props || jsonb_build_object('system_key', 'function', 'referat_id', v_referat,
        'valid_from', coalesce((v_row ->> 'aktiv_seit')::date, v_cutoff),
        'field_values', jsonb_strip_nulls(jsonb_build_object(
          'function', case when v_has_license then 'Trainer:in' else 'Helfer:in' end,
          'training_units_per_week', case when v_has_license then v_row -> 'te_pro_woche' end)));
      v_referat := null;
    end loop;

    -- Qualifikationen (Liste {code, date, valid_until, detail})
    for v_value in select value from jsonb_array_elements(coalesce(v_row -> 'qualifikationen', '[]')) loop
      v_text := btrim(coalesce(v_value ->> 'code', ''));
      continue when v_text = '';
      v_qual := public.ea_import_qualification(v_text);
      if v_qual.id is null then
        v_errors := v_errors || jsonb_build_object('row', v_n,
          'message', format('Zeile %s: Qualifikationsart %s unbekannt', v_n, v_text));
        continue;
      end if;
      -- Lizenzen gehören in l1–l3 (Feld „Qualifikationsart“ erlaubt keine Lizenz, R28 AD) [ANNAHME: Wortlaut]
      if v_qual.kind = 'license' then
        v_errors := v_errors || jsonb_build_object('row', v_n,
          'message', format('Zeile %s: %s ist eine Lizenz (Spalten l1–l3)', v_n, v_text));
        continue;
      end if;
      v_props := v_props || jsonb_build_object('system_key', 'qualification',
        'valid_from', coalesce((v_value ->> 'date')::date, v_cutoff),
        'field_values', jsonb_strip_nulls(jsonb_build_object(
          'qualification_type', v_qual.id, 'valid_until', v_value ->> 'valid_until', 'detail', nullif(btrim(coalesce(v_value ->> 'detail', '')), ''))));
    end loop;

    -- Mitglied, Geburtsdatum, Geschlecht
    if nullif(btrim(coalesce(v_row ->> 'mitgliedsnummer', '')), '') is not null then
      v_props := v_props || jsonb_build_object('system_key', 'member', 'valid_from', v_cutoff,
        'field_values', jsonb_build_object('is_member', true, 'member_number', btrim(v_row ->> 'mitgliedsnummer')));
    end if;
    if v_row ? 'geburtsdatum' then
      v_props := v_props || jsonb_build_object('system_key', 'birth_date', 'valid_from', v_cutoff,
        'field_values', jsonb_build_object('date', v_row ->> 'geburtsdatum'));
    end if;
    if nullif(btrim(coalesce(v_row ->> 'geschlecht', '')), '') is not null then
      v_text := btrim(v_row ->> 'geschlecht');
      if not exists (
        select 1 from public.ea_property_fields f join public.ea_property_types t on t.id = f.property_type_id
         where t.system_key = 'gender' and f.key = 'gender' and v_text = any (f.choice_values)
      ) then
        v_errors := v_errors || jsonb_build_object('row', v_n,
          'message', format('Zeile %s: Wert %s für Geschlecht unbekannt', v_n, v_text));
      else
        v_props := v_props || jsonb_build_object('system_key', 'gender', 'valid_from', v_cutoff,
          'field_values', jsonb_build_object('gender', v_text));
      end if;
    end if;

    -- Kontaktdaten (eine Eigenschaft)
    v_contact := '{}';
    for v_key, v_text in select key, value from jsonb_each_text(v_contact_columns) loop
      if nullif(btrim(coalesce(v_row ->> v_key, '')), '') is not null then
        v_contact := v_contact || jsonb_build_object(v_text, btrim(v_row ->> v_key));
      end if;
    end loop;
    if v_contact <> '{}' then
      v_props := v_props || jsonb_build_object('system_key', 'contact', 'valid_from', v_cutoff, 'field_values', v_contact);
    end if;

    -- Bankverbindung (R13)
    if v_row ? 'iban' or v_row ? 'kontoinhaber' then
      if not v_row ? 'kontoinhaber' or not v_row ? 'iban' then
        v_errors := v_errors || jsonb_build_object('row', v_n, 'message',
          format('Zeile %s: %s fehlt', v_n, case when v_row ? 'iban' then 'kontoinhaber' else 'iban' end));
      elsif not public.ea_iban_valid(v_row ->> 'iban') then
        v_errors := v_errors || jsonb_build_object('row', v_n, 'message', format('Zeile %s: Die IBAN ist ungültig.', v_n));
      else
        v_props := v_props || jsonb_build_object('system_key', 'bank_account', 'valid_from', v_cutoff,
          'field_values', jsonb_build_object('account_holder', btrim(v_row ->> 'kontoinhaber'), 'iban', v_row ->> 'iban'));
      end if;
    end if;

    -- Fortbildungen {"2019": "Titel"} (gültig von = 01.01. des Jahres)
    for v_key, v_text in select key, value from jsonb_each_text(coalesce(v_row -> 'fb', '{}')) loop
      continue when btrim(v_text) = '';
      v_props := v_props || jsonb_build_object('system_key', 'further_training', 'valid_from', make_date(v_key::int, 1, 1),
        'field_values', jsonb_build_object('year', v_key::int, 'title', btrim(v_text)));
    end loop;

    -- Ausweis, Führungszeugnis-Einsicht, Ehrenkodex, Trainervereinbarung
    if nullif(btrim(coalesce(v_row ->> 'ausweis_nr', '')), '') is not null then
      v_props := v_props || jsonb_build_object('system_key', 'id_card', 'valid_from', v_cutoff,
        'field_values', jsonb_strip_nulls(jsonb_build_object('card_number', btrim(v_row ->> 'ausweis_nr'),
                                                             'copy_available', v_row -> 'ausweis_kopie')));
    end if;
    if v_row ? 'fz_ausgestellt' then
      v_props := v_props || jsonb_build_object('system_key', 'police_clearance',
        'valid_from', coalesce((v_row ->> 'fz_eingesehen')::date, v_cutoff),
        'field_values', jsonb_build_object('issued_on', v_row ->> 'fz_ausgestellt'));
    elsif v_row ? 'fz_eingesehen' then
      v_errors := v_errors || jsonb_build_object('row', v_n, 'message', format('Zeile %s: fz_ausgestellt fehlt', v_n));
    end if;
    if v_row ? 'ehrenkodex' then
      v_props := v_props || jsonb_build_object('system_key', 'code_of_conduct', 'valid_from', v_row ->> 'ehrenkodex',
        'field_values', jsonb_build_object('signed', true));
    end if;
    if v_row ? 'trainervereinbarung' then
      v_props := v_props || jsonb_build_object('system_key', 'trainer_agreement', 'valid_from', v_row ->> 'trainervereinbarung',
        'field_values', jsonb_build_object('signed', true));
    end if;

    -- Jahresspalten: Marke {jahr: datum}, Förderung {jahr: bool}, Jahreskarte {jahr: datum}
    for v_key, v_text in select key, value from jsonb_each_text(coalesce(v_row -> 'marke', '{}')) loop
      v_props := v_props || jsonb_build_object('system_key', 'license_stamp', 'valid_from', v_text,
        'field_values', jsonb_build_object('year', v_key::int));
    end loop;
    for v_key, v_value in select key, value from jsonb_each(coalesce(v_row -> 'foerderung', '{}')) loop
      v_props := v_props || jsonb_build_object('system_key', 'funding', 'valid_from', make_date(v_key::int, 1, 1),
        'field_values', jsonb_build_object('year', v_key::int, 'applied', v_value));
    end loop;
    for v_key, v_text in select key, value from jsonb_each_text(coalesce(v_row -> 'jahreskarte', '{}')) loop
      v_props := v_props || jsonb_build_object('system_key', 'issued_item', 'valid_from', v_text,
        'field_values', jsonb_build_object('item', 'Jahreskarte', 'year', v_key::int));
    end loop;

    -- Ehrenamtspass
    if v_row ? 'ehrenamtspass_ausgegeben' or v_row ? 'ehrenamtspass_gueltig_bis' then
      v_props := v_props || jsonb_build_object('system_key', 'volunteer_pass',
        'valid_from', coalesce((v_row ->> 'ehrenamtspass_ausgegeben')::date, v_cutoff),
        'field_values', jsonb_strip_nulls(jsonb_build_object('valid_until', v_row ->> 'ehrenamtspass_gueltig_bis')));
    end if;

    -- Ausgaben (Nummer oder „x“) und Zugänge extern („x“ oder Datum seit)
    for v_key, v_text in select key, value from jsonb_each_text(v_issue_columns) loop
      continue when nullif(btrim(coalesce(v_row ->> v_key, '')), '') is null;
      v_props := v_props || jsonb_build_object('system_key', 'issued_item',
        'valid_from', coalesce((v_row ->> (v_key || '_am'))::date, v_cutoff),
        'field_values', jsonb_strip_nulls(jsonb_build_object('item', v_text,
          'number', case when lower(btrim(v_row ->> v_key)) <> 'x' then btrim(v_row ->> v_key) end)));
    end loop;
    for v_key, v_text in select key, value from jsonb_each_text(v_access_columns) loop
      continue when nullif(btrim(coalesce(v_row ->> v_key, '')), '') is null;
      v_props := v_props || jsonb_build_object('system_key', 'external_access',
        'valid_from', case when (v_row ->> v_key) ~ '^\d{4}-\d{2}-\d{2}$' then (v_row ->> v_key)::date else v_cutoff end,
        'field_values', jsonb_build_object('system', v_text));
    end loop;

    -- Jugendausschuss (Gremium, Mitglied)
    if (v_row -> 'jugendausschuss') = 'true'::jsonb then
      select g.id into v_gremium from public.ea_gremien g where g.name = 'Jugendausschuss' and g.is_active;
      if v_gremium is null then
        v_errors := v_errors || jsonb_build_object('row', v_n, 'message', format('Zeile %s: Gremium Jugendausschuss unbekannt', v_n));
      else
        v_props := v_props || jsonb_build_object('system_key', 'committee', 'gremium_id', v_gremium,
          'valid_from', coalesce((v_row ->> 'jugendausschuss_seit')::date, v_cutoff),
          'field_values', jsonb_build_object('role', 'Mitglied'));
      end if;
      v_gremium := null;
    end if;

    -- Auszeichnung
    if nullif(btrim(coalesce(v_row ->> 'auszeichnung_art', '')), '') is not null then
      v_props := v_props || jsonb_build_object('system_key', 'award',
        'valid_from', coalesce((v_row ->> 'auszeichnung_datum')::date, v_cutoff),
        'field_values', jsonb_build_object('kind', btrim(v_row ->> 'auszeichnung_art')));
    end if;

    -- Gruppe, Gruppenleitung: nur Warnung (Gruppen-Import)
    foreach v_key in array array['gruppe', 'gruppenleitung'] loop
      if nullif(btrim(coalesce(v_row ->> v_key, '')), '') is not null then
        v_warnings := v_warnings || jsonb_build_object('row', v_n,
          'message', format('Zeile %s: Gruppe %s', v_n, btrim(v_row ->> v_key)));
      end if;
    end loop;

    -- Dublettenverdacht gegen vorhandene Personen (R3a AD: Nachname gleich, Vor- oder Rufname ähnlich; E-Mail gleich)
    for v_ref in
      select coalesce(p.preferred_name, p.first_name) || ' ' || p.last_name as name
        from public.ea_persons p
       where p.kind = 'human'
         and (
           (lower(p.last_name) = lower(btrim(coalesce(v_row ->> 'nachname', '')))
            and (public.ad_first_names_match(p.first_name, v_row ->> 'vorname')
                 or public.ad_first_names_match(p.preferred_name, v_row ->> 'vorname')
                 or public.ad_first_names_match(p.first_name, v_row ->> 'rufname')
                 or public.ad_first_names_match(p.preferred_name, v_row ->> 'rufname')))
           or exists (
             select 1 from public.ad_accesses a
              where a.person_id = p.id
                and lower(a.login_email::text) in (lower(v_row ->> 'email'), lower(v_row ->> 'dav_email')))
           or exists (
             select 1 from public.ea_properties c join public.ea_property_types t on t.id = c.property_type_id
              where c.person_id = p.id and t.system_key = 'contact'
                and (lower(c.field_values ->> 'email') in (lower(v_row ->> 'email'), lower(v_row ->> 'dav_email'))
                     or lower(c.field_values ->> 'dav_email') in (lower(v_row ->> 'email'), lower(v_row ->> 'dav_email'))))
         )
       order by p.last_name, p.first_name
    loop
      v_warnings := v_warnings || jsonb_build_object('row', v_n,
        'message', format('Zeile %s: Dublettenverdacht zu %s (vorhanden)', v_n, v_ref.name));
    end loop;

    -- Dublettenverdacht innerhalb der Datei (frühere Zeilen)
    for v_other in select value from jsonb_array_elements(v_plans) loop
      if lower(btrim(coalesce(v_other ->> 'nachname', ''))) = lower(btrim(coalesce(v_row ->> 'nachname', '')))
         and (public.ad_first_names_match(v_other ->> 'vorname', v_row ->> 'vorname')
              or public.ad_first_names_match(v_other ->> 'rufname', v_row ->> 'vorname')
              or public.ad_first_names_match(v_other ->> 'vorname', v_row ->> 'rufname')
              or public.ad_first_names_match(v_other ->> 'rufname', v_row ->> 'rufname')) then
        v_warnings := v_warnings || jsonb_build_object('row', v_n, 'message',
          format('Zeile %s: Dublettenverdacht zu %s %s (Zeile %s)', v_n,
                 coalesce(nullif(v_other ->> 'rufname', ''), v_other ->> 'vorname'), v_other ->> 'nachname', v_other ->> 'row'));
      end if;
    end loop;

    v_plans := v_plans || jsonb_build_object(
      'row', v_n, 'vorname', v_row ->> 'vorname', 'rufname', v_row ->> 'rufname', 'nachname', v_row ->> 'nachname',
      'aktiv', v_row -> 'aktiv', 'properties', v_props);
  end loop;

  -- Zählung je Art und „gültig von“ = Stichtag (R17)
  select jsonb_build_object('persons', jsonb_array_length(v_plans))
         || coalesce((select jsonb_object_agg(k, c) from (
              select pr ->> 'system_key' as k, count(*) as c
                from jsonb_array_elements(v_plans) pl, jsonb_array_elements(pl -> 'properties') pr
               group by 1) s), '{}')
         || jsonb_build_object('valid_from_cutoff', (
              select count(*) from jsonb_array_elements(v_plans) pl, jsonb_array_elements(pl -> 'properties') pr
               where (pr ->> 'valid_from')::date = v_cutoff))
    into v_counts;

  -- 2. Ohne Schreiben bei Probelauf oder Fehlern
  if p_dry_run or jsonb_array_length(v_errors) > 0 then
    return jsonb_build_object('errors', v_errors, 'warnings', v_warnings, 'counts', v_counts, 'written', false);
  end if;

  -- 3. Schreiben (eine Transaktion); Trigger prüfen jede Eigenschaft erneut (R35 AD)
  for v_plan in select value from jsonb_array_elements(v_plans) loop
    insert into public.ea_persons
      (first_name, last_name, preferred_name, kind, created_in, created_by, volunteer_status, volunteer_status_since)
    values (v_plan ->> 'vorname', v_plan ->> 'nachname', v_plan ->> 'rufname', 'human', 'script', null,
            case when (v_plan -> 'aktiv') = 'true'::jsonb then 'active' else 'dormant' end::public.ea_volunteer_status,
            v_cutoff)
    returning id into v_person;

    insert into public.ea_volunteer_status_history (person_id, status, valid_from, set_by)
    values (v_person,
            case when (v_plan -> 'aktiv') = 'true'::jsonb then 'active' else 'dormant' end::public.ea_volunteer_status,
            v_cutoff, null);

    for v_prop in select value from jsonb_array_elements(v_plan -> 'properties') loop
      insert into public.ea_properties
        (person_id, property_type_id, field_values, related_referat_id, related_gremium_id, valid_from)
      values (v_person,
              (select t.id from public.ea_property_types t where t.system_key = v_prop ->> 'system_key'),
              v_prop -> 'field_values',
              (v_prop ->> 'referat_id')::uuid,
              (v_prop ->> 'gremium_id')::uuid,
              (v_prop ->> 'valid_from')::date);
    end loop;
  end loop;

  return jsonb_build_object('errors', v_errors, 'warnings', v_warnings, 'counts', v_counts, 'written', true);
end;
$$;

-- Rechte unverändert: nur der Service-Client des Migrationsskripts (R-EA-10)
revoke all on function public.ea_import_volunteers(jsonb, date, boolean) from public, anon, authenticated;
grant execute on function public.ea_import_volunteers(jsonb, date, boolean) to service_role;
