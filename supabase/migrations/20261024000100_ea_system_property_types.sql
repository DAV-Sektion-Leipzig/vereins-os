-- US-EA-16, spec T1 (EA spec.md 2.1): 25 System-Eigenschaftsarten mit Feldern und Bezeichnungen „gültig von/bis“
-- wörtlich nach docs/specs/ea-ehrenamt/01-erhebung.md C2 und C2a (research.md R-EA-03).
-- Läuft ohne Nutzerkontext: die Trigger der Administration erlauben dann system_key, origin = 'system' und
-- die Lesestufe „vertraulich“ (Nr. 24 Hauptamt). Idempotent über system_key; Felder nur für neu angelegte Arten.
-- Die Daten stehen in der internen Funktion ea_seed_system_property_types() (security definer, ohne Grant),
-- damit pgTAP den zweiten Lauf und den Namenskonflikt prüfen kann (research.md R-EA-03, „Testbarkeit“).
-- Abbruch (A7), wenn eine Art gleichen Namens ohne system_key existiert – dann zuerst TEST neu aufbauen
-- (quickstart.md B) bzw. die Art umbenennen.

create function public.ea_seed_system_property_types()
returns void
language plpgsql
security definer
set search_path = ''
as $fn$
declare
  v_name text;
begin
  -- Prüfung A7 (US-EA-16 AK5)
    select t.name into v_name
      from public.ea_property_types t
      join (values
        ('Mitglied'), ('Geburtsdatum'), ('Geschlecht'), ('Kontaktdaten'), ('Bankverbindung'), ('Funktion'), ('Amt'),
        ('Gremium'), ('Lizenz'), ('Qualifikation'), ('Fortbildung'), ('Trainer- und Jugendleiterausweis'),
        ('Führungszeugnis-Einsicht'), ('Ehrenkodex'), ('Trainervereinbarung'), ('Bestätigung steuerfreie Einnahmen'),
        ('Erklärung zur Ehrenamtspauschale'), ('Jugendleiter- und Trainermarke'), ('Förderung'), ('Ausgabe'),
        ('Ehrenamtspass'), ('Zugang extern'), ('Auszeichnung'), ('Hauptamt'), ('Vereinbarung ehrenamtliche Tätigkeit')
      ) as s (name) on lower(t.name) = lower(s.name)
     where t.system_key is null
     order by t.name
     limit 1;
    if v_name is not null then
      raise exception 'Eigenschaftsart % existiert bereits ohne system_key.', v_name;
    end if;

  -- Arten und Felder (Reihenfolge der Felder = sort_order)
  with s (name, purpose, system_key, category, read_level, relation_kind, relation_required, allow_multiple,
          visible_in, valid_from_label, valid_to_label, fields) as (
    values
      ('Mitglied', 'Abgleich mit der Mitgliederverwaltung', 'member', 'master_data'::public.ea_property_category,
       'all'::public.ea_read_level, 'none'::public.ea_relation_kind, false, false, '{AD,EA,GR}'::text[], 'seit', 'bis',
       '[{"key": "is_member", "label": "Mitglied", "data_type": "boolean", "is_required": true},
         {"key": "member_number", "label": "Mitgliedsnummer", "data_type": "text"}]'::jsonb),
      ('Geburtsdatum', 'Lizenzanträge', 'birth_date', 'master_data', 'office', 'none', false, false, '{AD,EA,GR}', null, null,
       '[{"key": "date", "label": "Geburtsdatum", "data_type": "date", "is_required": true}]'),
      ('Geschlecht', 'Lizenzanträge, korrekte Ansprache', 'gender', 'master_data', 'office', 'none', false, false, '{AD,EA}', null, null,
       '[{"key": "gender", "label": "Geschlecht", "data_type": "choice", "is_required": true,
          "choice_values": ["weiblich", "männlich", "divers", "keine Angabe"]}]'),
      ('Kontaktdaten', 'Erreichbarkeit', 'contact', 'contact', 'all', 'none', false, false, '{AD,EA,GR}', null, null,
       '[{"key": "email", "label": "E-Mail", "data_type": "text"},
         {"key": "phone_mobile", "label": "Telefon mobil", "data_type": "text"},
         {"key": "phone_landline", "label": "Telefon Festnetz", "data_type": "text"},
         {"key": "street", "label": "Straße und Hausnummer", "data_type": "text"},
         {"key": "postal_code", "label": "PLZ", "data_type": "text"},
         {"key": "city", "label": "Ort", "data_type": "text"},
         {"key": "dav_email", "label": "DAV-E-Mail-Adresse", "data_type": "text"}]'),
      ('Bankverbindung', 'Trainerabrechnung (Modul Finanzen)', 'bank_account', 'master_data', 'office', 'none', false, false, '{AD,EA}', null, null,
       '[{"key": "account_holder", "label": "Kontoinhaber:in", "data_type": "text", "is_required": true},
         {"key": "iban", "label": "IBAN", "data_type": "text", "is_required": true}]'),
      ('Funktion', 'Zuordnung zu Referaten', 'function', 'assignment', 'all', 'referat', false, true, '{AD,EA}', 'seit', 'bis',
       '[{"key": "function", "label": "Funktion", "data_type": "choice", "is_required": true,
          "choice_values": ["Trainer:in", "Helfer:in"]},
         {"key": "training_units_per_week", "label": "Trainingseinheiten pro Woche", "data_type": "number"}]'),
      ('Amt', 'Gewählte Verantwortung', 'position', 'assignment', 'all', 'referat', false, true, '{AD,EA}', 'Amtszeit von', 'Amtszeit bis',
       '[{"key": "position", "label": "Amt", "data_type": "choice", "is_required": true,
          "choice_values": ["Referent:in", "stellv. Referent:in", "Hüttenwart:in"]}]'),
      ('Gremium', 'Zusammensetzung der Gremien', 'committee', 'assignment', 'all', 'gremium', true, true, '{AD,EA}', 'seit', 'bis',
       '[{"key": "role", "label": "Rolle", "data_type": "choice", "is_required": true, "choice_values": ["Mitglied", "Vorsitz"]}]'),
      ('Lizenz', 'Nachweis der Trainerlizenz; Vergütung (förderfähig)', 'license', 'qualification', 'all', 'none', false, true, '{AD,EA}',
       'erworben bzw. verlängert am', 'beendet am',
       '[{"key": "qualification_type", "label": "Qualifikationsart", "data_type": "qualification_type", "is_required": true,
          "allowed_qualification_kinds": ["license"]},
         {"key": "valid_until", "label": "gültig bis", "data_type": "date", "is_required": true},
         {"key": "license_number", "label": "Lizenznummer", "data_type": "text"},
         {"key": "dosb_valid_until", "label": "DOSB-Lizenz gültig bis", "data_type": "date"},
         {"key": "last_training", "label": "letzte Fortbildung", "data_type": "date"}]'),
      ('Qualifikation', 'Weitere Befähigungen', 'qualification', 'qualification', 'all', 'none', false, true, '{AD,EA}',
       'erworben bzw. verlängert am', 'beendet am',
       '[{"key": "qualification_type", "label": "Qualifikationsart", "data_type": "qualification_type", "is_required": true,
          "allowed_qualification_kinds": ["add_on", "course", "training"]},
         {"key": "valid_until", "label": "gültig bis", "data_type": "date"},
         {"key": "detail", "label": "Angabe", "data_type": "text"}]'),
      ('Fortbildung', 'Fortbildungspflicht', 'further_training', 'qualification', 'all', 'none', false, true, '{AD,EA}', 'Datum', null,
       '[{"key": "year", "label": "Jahr", "data_type": "year", "is_required": true},
         {"key": "title", "label": "Titel", "data_type": "text", "is_required": true},
         {"key": "qualification_type", "label": "verlängerte Lizenz", "data_type": "qualification_type",
          "allowed_qualification_kinds": ["license"]}]'),
      ('Trainer- und Jugendleiterausweis', 'Lizenzanträge Landes- und Stadtsportbund', 'id_card', 'proof', 'all', 'none', false, true, '{AD,EA}',
       'ausgestellt am', 'ungültig ab',
       '[{"key": "card_number", "label": "Ausweisnummer", "data_type": "text", "is_required": true},
         {"key": "copy_available", "label": "Kopie liegt vor", "data_type": "boolean"}]'),
      ('Führungszeugnis-Einsicht', 'Kinderschutz; Erneuerung alle 3 Jahre', 'police_clearance', 'proof', 'office', 'none', false, false, '{AD,EA}',
       'eingesehen am', null,
       '[{"key": "issued_on", "label": "Ausstellungsdatum", "data_type": "date", "is_required": true}]'),
      ('Ehrenkodex', 'Kinderschutz', 'code_of_conduct', 'proof', 'all', 'none', false, false, '{AD,EA}', 'unterschrieben am', 'beendet am',
       '[{"key": "signed", "label": "unterschrieben", "data_type": "boolean", "is_required": true}]'),
      ('Trainervereinbarung', 'Trainerabrechnung', 'trainer_agreement', 'proof', 'office', 'none', false, false, '{AD,EA}',
       'unterschrieben am', 'beendet am',
       '[{"key": "signed", "label": "unterschrieben", "data_type": "boolean", "is_required": true}]'),
      ('Bestätigung steuerfreie Einnahmen', 'Voraussetzung der Übungsleiterpauschale', 'tax_free_confirmation', 'proof', 'office', 'none',
       false, true, '{AD,EA}', 'abgegeben am', null,
       '[{"key": "year", "label": "für Jahr", "data_type": "year"}]'),
      ('Erklärung zur Ehrenamtspauschale', 'Voraussetzung der Ehrenamtspauschale', 'volunteer_allowance_declaration', 'proof', 'office',
       'none', false, true, '{AD,EA}', 'abgegeben am', null,
       '[{"key": "year", "label": "für Jahr", "data_type": "year", "is_required": true}]'),
      ('Jugendleiter- und Trainermarke', 'Gültigkeit des Ausweises', 'license_stamp', 'yearly', 'all', 'none', false, true, '{AD,EA}',
       'ausgegeben am', null,
       '[{"key": "year", "label": "Jahr", "data_type": "year", "is_required": true}]'),
      ('Förderung', 'Förderanträge', 'funding', 'yearly', 'office', 'none', false, true, '{AD,EA}', null, null,
       '[{"key": "year", "label": "Jahr", "data_type": "year", "is_required": true},
         {"key": "applied", "label": "beantragt", "data_type": "boolean", "is_required": true},
         {"key": "funder", "label": "Fördergeber", "data_type": "text"}]'),
      ('Ausgabe', 'Rückgabe beim Ausscheiden', 'issued_item', 'issue', 'all', 'none', false, true, '{AD,EA}', 'ausgegeben am', 'zurückgegeben am',
       '[{"key": "item", "label": "Gegenstand", "data_type": "choice", "is_required": true,
          "choice_values": ["Schlüssel NoLimit", "Schlüssel K4", "K4-Karte", "Jahreskarte", "Vereinsjacke"]},
         {"key": "number", "label": "Nummer", "data_type": "text"},
         {"key": "year", "label": "Jahr", "data_type": "year"}]'),
      ('Ehrenamtspass', 'Vergünstigungen für Ehrenamtliche', 'volunteer_pass', 'issue', 'all', 'none', false, true, '{AD,EA}', 'ausgegeben am', null,
       '[{"key": "valid_until", "label": "gültig bis", "data_type": "date"}]'),
      ('Zugang extern', 'Entzug beim Ausscheiden', 'external_access', 'external_access', 'all', 'none', false, true, '{AD,EA}', 'seit', 'bis',
       '[{"key": "system", "label": "System", "data_type": "choice", "is_required": true,
          "choice_values": ["DAV360", "Forms", "JDAV Aktiven-Mailverteiler", "Redaktion", "Mailingliste"]}]'),
      ('Auszeichnung', 'Ehrungen', 'award', 'other', 'all', 'none', false, true, '{AD,EA}', 'verliehen am', null,
       '[{"key": "kind", "label": "Art", "data_type": "text", "is_required": true}]'),
      ('Hauptamt', 'Zuordnung der hauptamtlich Beschäftigten', 'employment', 'other', 'confidential', 'none', false, true, '{AD}', 'seit', 'bis',
       '[{"key": "title", "label": "Bezeichnung", "data_type": "text", "is_required": true}]'),
      ('Vereinbarung ehrenamtliche Tätigkeit', 'Voraussetzung der Ehrenamtspauschale', 'volunteer_agreement', 'proof', 'office', 'none',
       false, false, '{AD,EA}', 'unterschrieben am', 'beendet am',
       '[{"key": "signed", "label": "unterschrieben", "data_type": "boolean", "is_required": true}]')
  ), ins as (
    insert into public.ea_property_types
      (name, purpose, system_key, category, read_level, relation_kind, relation_required, allow_multiple,
       visible_in, origin, valid_from_label, valid_to_label)
    select s.name, s.purpose, s.system_key, s.category, s.read_level, s.relation_kind, s.relation_required, s.allow_multiple,
           s.visible_in, 'system', s.valid_from_label, s.valid_to_label
      from s
    on conflict (system_key) do nothing
    returning id, system_key
  )
  insert into public.ea_property_fields
    (property_type_id, key, label, data_type, is_required, choice_values, allowed_qualification_kinds, sort_order)
  select ins.id,
         f.value ->> 'key',
         f.value ->> 'label',
         (f.value ->> 'data_type')::public.ea_data_type,
         coalesce((f.value ->> 'is_required')::boolean, false),
         case when f.value ? 'choice_values'
              then array(select jsonb_array_elements_text(f.value -> 'choice_values')) end,
         case when f.value ? 'allowed_qualification_kinds'
              then array(select jsonb_array_elements_text(f.value -> 'allowed_qualification_kinds'))::public.ad_qualification_kind[] end,
         f.ordinality::int
    from ins
    join s on s.system_key = ins.system_key
    cross join lateral jsonb_array_elements(s.fields) with ordinality as f (value, ordinality);
end;
$fn$;

revoke all on function public.ea_seed_system_property_types() from public, anon, authenticated;

select public.ea_seed_system_property_types();
