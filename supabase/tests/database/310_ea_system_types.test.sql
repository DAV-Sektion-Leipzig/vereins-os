-- US-EA-16 (EA spec T9 Teil, T1): 25 System-Eigenschaftsarten mit Feldern und Bezeichnungen nach 01-erhebung.md C2/C2a;
-- zweiter Lauf (AK2) und Abbruch bei Namenskonflikt (AK5, A7) über die interne Funktion ea_seed_system_property_types().
-- Ohne die Art group_function der ersten GR-Migration (GR spec.md 2.2; Test 470).
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

select is((select count(*)::int from public.ea_property_types where origin = 'system' and system_key <> 'group_function'), 25, '25 System-Eigenschaftsarten');
select is((select count(*)::int from public.ea_property_types where system_key is not null and system_key <> 'group_function'), 25, 'alle mit system_key');

select results_eq(
  $$ select system_key, name, category::text, read_level::text, relation_kind::text, relation_required, allow_multiple,
            visible_in::text, valid_from_label, valid_to_label
       from public.ea_property_types where origin = 'system' and system_key <> 'group_function' order by system_key collate "C" $$,
  $$ values
     ('award'::text, 'Auszeichnung'::text, 'other'::text, 'all'::text, 'none'::text, false, true, '{AD,EA}'::text, 'verliehen am'::text, null::text),
     ('bank_account', 'Bankverbindung', 'master_data', 'office', 'none', false, false, '{AD,EA}', null, null),
     ('birth_date', 'Geburtsdatum', 'master_data', 'office', 'none', false, false, '{AD,EA,GR}', null, null),
     ('code_of_conduct', 'Ehrenkodex', 'proof', 'all', 'none', false, false, '{AD,EA}', 'unterschrieben am', 'beendet am'),
     ('committee', 'Gremium', 'assignment', 'all', 'gremium', true, true, '{AD,EA}', 'seit', 'bis'),
     ('contact', 'Kontaktdaten', 'contact', 'all', 'none', false, false, '{AD,EA,GR}', null, null),
     ('employment', 'Hauptamt', 'other', 'confidential', 'none', false, true, '{AD}', 'seit', 'bis'),
     ('external_access', 'Zugang extern', 'external_access', 'all', 'none', false, true, '{AD,EA}', 'seit', 'bis'),
     ('function', 'Funktion', 'assignment', 'all', 'referat', false, true, '{AD,EA}', 'seit', 'bis'),
     ('funding', 'Förderung', 'yearly', 'office', 'none', false, true, '{AD,EA}', null, null),
     ('further_training', 'Fortbildung', 'qualification', 'all', 'none', false, true, '{AD,EA}', 'Datum', null),
     ('gender', 'Geschlecht', 'master_data', 'office', 'none', false, false, '{AD,EA}', null, null),
     ('id_card', 'Trainer- und Jugendleiterausweis', 'proof', 'all', 'none', false, true, '{AD,EA}', 'ausgestellt am', 'ungültig ab'),
     ('issued_item', 'Ausgabe', 'issue', 'all', 'none', false, true, '{AD,EA}', 'ausgegeben am', 'zurückgegeben am'),
     ('license', 'Lizenz', 'qualification', 'all', 'none', false, true, '{AD,EA}', 'erworben bzw. verlängert am', 'beendet am'),
     ('license_stamp', 'Jugendleiter- und Trainermarke', 'yearly', 'all', 'none', false, true, '{AD,EA}', 'ausgegeben am', null),
     ('member', 'Mitglied', 'master_data', 'all', 'none', false, false, '{AD,EA,GR}', 'seit', 'bis'),
     ('police_clearance', 'Führungszeugnis-Einsicht', 'proof', 'office', 'none', false, false, '{AD,EA}', 'eingesehen am', null),
     ('position', 'Amt', 'assignment', 'all', 'referat', false, true, '{AD,EA}', 'Amtszeit von', 'Amtszeit bis'),
     ('qualification', 'Qualifikation', 'qualification', 'all', 'none', false, true, '{AD,EA}', 'erworben bzw. verlängert am', 'beendet am'),
     ('tax_free_confirmation', 'Bestätigung steuerfreie Einnahmen', 'proof', 'office', 'none', false, true, '{AD,EA}', 'abgegeben am', null),
     ('trainer_agreement', 'Trainervereinbarung', 'proof', 'office', 'none', false, false, '{AD,EA}', 'unterschrieben am', 'beendet am'),
     ('volunteer_agreement', 'Vereinbarung ehrenamtliche Tätigkeit', 'proof', 'office', 'none', false, false, '{AD,EA}', 'unterschrieben am', 'beendet am'),
     ('volunteer_allowance_declaration', 'Erklärung zur Ehrenamtspauschale', 'proof', 'office', 'none', false, true, '{AD,EA}', 'abgegeben am', null),
     ('volunteer_pass', 'Ehrenamtspass', 'issue', 'all', 'none', false, true, '{AD,EA}', 'ausgegeben am', null)
  $$, 'Kategorie, Lesestufe, Bezug, mehrfach, sichtbar in und Bezeichnungen nach C2 und C2a');

select is((select count(*)::int from public.ea_property_fields f
            join public.ea_property_types t on t.id = f.property_type_id where t.origin = 'system' and t.system_key <> 'group_function'), 47, '47 Felder');
select is_empty(
  $$ select t.system_key from public.ea_property_types t
      where t.origin = 'system' and t.system_key <> 'group_function' and not exists (select 1 from public.ea_property_fields f where f.property_type_id = t.id) $$,
  'jede Art hat mindestens ein Feld (R9)');

select results_eq(
  $$ select t.system_key, f.key, f.label, f.data_type::text, f.is_required, f.sort_order
       from public.ea_property_fields f join public.ea_property_types t on t.id = f.property_type_id
      where t.origin = 'system' and t.system_key <> 'group_function' order by t.system_key collate "C", f.sort_order $$,
  $$ values
     ('award'::text, 'kind'::text, 'Art'::text, 'text'::text, true, 1),
     ('bank_account', 'account_holder', 'Kontoinhaber:in', 'text', true, 1),
     ('bank_account', 'iban', 'IBAN', 'text', true, 2),
     ('birth_date', 'date', 'Geburtsdatum', 'date', true, 1),
     ('code_of_conduct', 'signed', 'unterschrieben', 'boolean', true, 1),
     ('committee', 'role', 'Rolle', 'choice', true, 1),
     ('contact', 'email', 'E-Mail', 'text', false, 1),
     ('contact', 'phone_mobile', 'Telefon mobil', 'text', false, 2),
     ('contact', 'phone_landline', 'Telefon Festnetz', 'text', false, 3),
     ('contact', 'street', 'Straße und Hausnummer', 'text', false, 4),
     ('contact', 'postal_code', 'PLZ', 'text', false, 5),
     ('contact', 'city', 'Ort', 'text', false, 6),
     ('contact', 'dav_email', 'DAV-E-Mail-Adresse', 'text', false, 7),
     ('employment', 'title', 'Bezeichnung', 'text', true, 1),
     ('external_access', 'system', 'System', 'choice', true, 1),
     ('function', 'function', 'Funktion', 'choice', true, 1),
     ('function', 'training_units_per_week', 'Trainingseinheiten pro Woche', 'number', false, 2),
     ('funding', 'year', 'Jahr', 'year', true, 1),
     ('funding', 'applied', 'beantragt', 'boolean', true, 2),
     ('funding', 'funder', 'Fördergeber', 'text', false, 3),
     ('further_training', 'year', 'Jahr', 'year', true, 1),
     ('further_training', 'title', 'Titel', 'text', true, 2),
     ('further_training', 'qualification_type', 'verlängerte Lizenz', 'qualification_type', false, 3),
     ('gender', 'gender', 'Geschlecht', 'choice', true, 1),
     ('id_card', 'card_number', 'Ausweisnummer', 'text', true, 1),
     ('id_card', 'copy_available', 'Kopie liegt vor', 'boolean', false, 2),
     ('issued_item', 'item', 'Gegenstand', 'choice', true, 1),
     ('issued_item', 'number', 'Nummer', 'text', false, 2),
     ('issued_item', 'year', 'Jahr', 'year', false, 3),
     ('license', 'qualification_type', 'Qualifikationsart', 'qualification_type', true, 1),
     ('license', 'valid_until', 'gültig bis', 'date', true, 2),
     ('license', 'license_number', 'Lizenznummer', 'text', false, 3),
     ('license', 'dosb_valid_until', 'DOSB-Lizenz gültig bis', 'date', false, 4),
     ('license', 'last_training', 'letzte Fortbildung', 'date', false, 5),
     ('license_stamp', 'year', 'Jahr', 'year', true, 1),
     ('member', 'is_member', 'Mitglied', 'boolean', true, 1),
     ('member', 'member_number', 'Mitgliedsnummer', 'text', false, 2),
     ('police_clearance', 'issued_on', 'Ausstellungsdatum', 'date', true, 1),
     ('position', 'position', 'Amt', 'choice', true, 1),
     ('qualification', 'qualification_type', 'Qualifikationsart', 'qualification_type', true, 1),
     ('qualification', 'valid_until', 'gültig bis', 'date', false, 2),
     ('qualification', 'detail', 'Angabe', 'text', false, 3),
     ('tax_free_confirmation', 'year', 'für Jahr', 'year', false, 1),
     ('trainer_agreement', 'signed', 'unterschrieben', 'boolean', true, 1),
     ('volunteer_agreement', 'signed', 'unterschrieben', 'boolean', true, 1),
     ('volunteer_allowance_declaration', 'year', 'für Jahr', 'year', true, 1),
     ('volunteer_pass', 'valid_until', 'gültig bis', 'date', false, 1)
  $$, 'Felder mit Schlüssel, Bezeichnung, Typ, Pflicht und Reihenfolge nach C2');

create function pg_temp.field(p_key text, p_field text) returns public.ea_property_fields language sql as $$
  select f.* from public.ea_property_fields f join public.ea_property_types t on t.id = f.property_type_id
   where t.system_key = p_key and f.key = p_field
$$;
select is((pg_temp.field('gender', 'gender')).choice_values, '{weiblich,männlich,divers,"keine Angabe"}'::text[], 'Auswahl Geschlecht');
select is((pg_temp.field('function', 'function')).choice_values, '{Trainer:in,Helfer:in}'::text[], 'Auswahl Funktion');
select is((pg_temp.field('position', 'position')).choice_values, '{Referent:in,"stellv. Referent:in",Hüttenwart:in}'::text[], 'Auswahl Amt');
select is((pg_temp.field('committee', 'role')).choice_values, '{Mitglied,Vorsitz}'::text[], 'Auswahl Rolle');
select is((pg_temp.field('issued_item', 'item')).choice_values,
  '{"Schlüssel NoLimit","Schlüssel K4",K4-Karte,Jahreskarte,Vereinsjacke}'::text[], 'Auswahl Gegenstand');
select is((pg_temp.field('external_access', 'system')).choice_values,
  '{DAV360,Forms,"JDAV Aktiven-Mailverteiler",Redaktion,Mailingliste}'::text[], 'Auswahl System');
select is((pg_temp.field('license', 'qualification_type')).allowed_qualification_kinds, '{license}'::public.ad_qualification_kind[],
  'Lizenz: nur Typ Lizenz (AK4)');
select is((pg_temp.field('qualification', 'qualification_type')).allowed_qualification_kinds,
  '{add_on,course,training}'::public.ad_qualification_kind[], 'Qualifikation: Zusatzqualifikation, Lehrgang, Weiterbildung');
select is((pg_temp.field('further_training', 'qualification_type')).allowed_qualification_kinds, '{license}'::public.ad_qualification_kind[],
  'Fortbildung: verlängerte Lizenz nur Typ Lizenz');

-- Idempotenz über system_key (AK2): zweiter Lauf legt nichts an und überschreibt keine Änderung aus der Oberfläche
update public.ea_property_types set valid_from_label = 'Mitglied seit', purpose = 'geändert' where system_key = 'member';
select lives_ok($$ select public.ea_seed_system_property_types() $$, 'zweiter Lauf ohne Fehler');
select is((select count(*)::int from public.ea_property_types where origin = 'system' and system_key <> 'group_function'), 25, 'weiterhin 25 Arten');
select is((select count(*)::int from public.ea_property_fields f
            join public.ea_property_types t on t.id = f.property_type_id where t.origin = 'system' and t.system_key <> 'group_function'), 47, 'keine doppelten Felder');
select results_eq($$ select valid_from_label, purpose from public.ea_property_types where system_key = 'member' $$,
  $$ values ('Mitglied seit'::text, 'geändert'::text) $$, 'geänderte Bezeichnung und Zweck bleiben erhalten');

-- Konflikt (AK5, A7): Art „Mitglied“ ohne system_key → Abbruch mit klarer Meldung
delete from public.ea_property_fields where property_type_id = (select id from public.ea_property_types where system_key = 'member');
delete from public.ea_property_types where system_key = 'member';
insert into public.ea_property_types (name, purpose, visible_in) values ('Mitglied', 'Test', '{AD}');
select throws_ok($$ select public.ea_seed_system_property_types() $$, 'P0001',
  'Eigenschaftsart Mitglied existiert bereits ohne system_key.', 'Namenskonflikt bricht ab (A7)');
select ok(not exists (select 1 from public.ea_property_types where system_key = 'member'), 'nichts angelegt');

-- interne Funktion nicht für Nutzer
select ok(not has_function_privilege('authenticated', 'public.ea_seed_system_property_types()', 'EXECUTE'),
  'ea_seed_system_property_types nicht für authenticated');

select * from finish();
rollback;
