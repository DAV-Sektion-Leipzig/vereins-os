-- US-AD-12, US-AD-19, US-AD-22 (spec T7 Teil, T35, T45 Teil): Eigenschaftsarten mit Feldern, R9, R29, R36, R49.
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

create function pg_temp.as_user(p_user uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', p_user, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
end $$;
create function pg_temp.as_owner() returns void language plpgsql as $$
begin
  execute 'reset role';
  perform set_config('request.jwt.claims', '', true);
end $$;
-- ID der vertraulichen System-Eigenschaftsart Hauptamt, unabhängig von der RLS des aktuellen Nutzers
create function pg_temp.employment() returns uuid language sql security definer as $$
  select id from public.ea_property_types where system_key = 'employment'
$$;

-- Anlegen mit Feldern (US-AD-22 AK1, US-AD-19 AK1)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select lives_ok($$
  select public.ea_save_property_type(
    '{"name": "Lizenz neu", "purpose": "Nachweis", "category": "qualification", "read_level": "all",
      "visible_in": ["AD", "EA"], "valid_from_label": "  erworben am  ", "valid_to_label": "   "}',
    '[{"key": "qualification_type", "label": "Qualifikationsart", "data_type": "qualification_type",
       "is_required": true, "allowed_qualification_kinds": ["license"]},
      {"key": "license_number", "label": "Lizenznummer", "data_type": "text"},
      {"key": "valid_until", "label": "gültig bis", "data_type": "date"}]')
$$, 'Admin legt Eigenschaftsart mit drei Feldern an');
select results_eq(
  $$ select f.key, f.sort_order from public.ea_property_fields f
       join public.ea_property_types t on t.id = f.property_type_id
      where t.name = 'Lizenz neu' order by f.sort_order $$,
  $$ values ('qualification_type'::text, 1), ('license_number', 2), ('valid_until', 3) $$,
  'Felder in der Reihenfolge der Eingabe');
select results_eq(
  $$ select valid_from_label, valid_to_label from public.ea_property_types where name = 'Lizenz neu' $$,
  $$ values ('erworben am'::text, null::text) $$, 'Bezeichnungen getrimmt, leer → null (R49)');

-- R9, R49, Name doppelt
select throws_ok($$ select public.ea_save_property_type('{"name": "Ohne Felder", "purpose": "x", "visible_in": ["AD"]}', '[]') $$,
  'P0001', 'EA_NO_FIELDS', 'ohne Feld abgelehnt (R9)');
select throws_ok($$ select public.ea_save_property_type('{"name": "Ohne Zweck", "purpose": "  ", "visible_in": ["AD"]}',
  '[{"key": "a", "label": "A", "data_type": "text"}]') $$,
  'P0001', 'EA_PURPOSE_REQUIRED', 'ohne Zweck abgelehnt (R9)');
select throws_ok($$ select public.ea_save_property_type('{"name": "Auswahl leer", "purpose": "x", "visible_in": ["AD"]}',
  '[{"key": "a", "label": "A", "data_type": "choice", "choice_values": [" ", ""]}]') $$,
  'P0001', 'EA_CHOICE_VALUES_REQUIRED', 'Auswahlliste ohne Werte abgelehnt (R9)');
select throws_ok($$ select public.ea_save_property_type('{"name": "lizenz NEU", "purpose": "x", "visible_in": ["AD"]}',
  '[{"key": "a", "label": "A", "data_type": "text"}]') $$,
  '23505', null, 'Name doppelt ohne Groß-/Kleinschreibung (ea_property_types_name_key)');
select throws_ok($$ select public.ea_save_property_type('{"name": "Feld doppelt", "purpose": "x", "visible_in": ["AD"]}',
  '[{"key": "a", "label": "Feld", "data_type": "text"}, {"key": "b", "label": "feld", "data_type": "text"}]') $$,
  '23505', null, 'Feldbezeichnung doppelt (ea_property_fields_label_key)');
select throws_ok($$ select public.ea_save_property_type('{"name": "Label lang", "purpose": "x", "visible_in": ["AD"],
  "valid_to_label": "12345678901234567890123456789012345678901"}', '[{"key": "a", "label": "A", "data_type": "text"}]') $$,
  'P0001', 'EA_LABEL_TOO_LONG', '41 Zeichen abgelehnt (R49)');
select lives_ok($$ select public.ea_save_property_type('{"name": "Label 40", "purpose": "x", "visible_in": ["AD"],
  "valid_to_label": "1234567890123456789012345678901234567890"}', '[{"key": "a", "label": "A", "data_type": "text"}]') $$,
  '40 Zeichen erlaubt (R49)');
select throws_ok($$ select public.ea_save_property_type('{"name": "Modul fremd", "purpose": "x", "visible_in": ["XX"]}',
  '[{"key": "a", "label": "A", "data_type": "text"}]') $$,
  'P0001', 'AD_BAD_REQUEST', 'unbekannter Modulcode in „sichtbar in“');
select throws_ok($$ select public.ea_save_property_type('{"name": "Schlüssel", "purpose": "x", "visible_in": ["AD"]}',
  '[{"key": "Groß", "label": "A", "data_type": "text"}]') $$,
  '23514', null, 'Feldschlüssel nur Kleinbuchstaben, Ziffern, Unterstrich');

-- R29: vertraulich nur mit AD ≥ edit; Geschäftsstelle sieht keine vertraulichen Arten
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select throws_ok($$ select public.ea_save_property_type('{"name": "Geheim", "purpose": "x", "read_level": "confidential",
  "visible_in": ["EA"]}', '[{"key": "a", "label": "A", "data_type": "text"}]') $$,
  'P0001', 'AD_CONFIDENTIAL_ONLY_AD', 'Geschäftsstelle darf „vertraulich“ nicht setzen (R29)');
select lives_ok($$ select public.ea_save_property_type('{"name": "Schuhgröße", "purpose": "Ausgabe", "visible_in": ["EA"]}',
  '[{"key": "size", "label": "Größe", "data_type": "number"}]') $$,
  'Geschäftsstelle (EA verwalten) legt Art an');
select is_empty($$ select 1 from public.ea_property_types where read_level = 'confidential' $$,
  'Geschäftsstelle sieht keine vertraulichen Arten');
select is_empty($$ select 1 from public.ea_property_fields f
                     where f.property_type_id = pg_temp.employment() $$,
  'Geschäftsstelle sieht keine Felder vertraulicher Arten');
update public.ea_property_types set name = 'Hauptamt neu' where id = pg_temp.employment();
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select ok((select count(*) from public.ea_property_types) > 0, 'Referent:in liest Eigenschaftsarten');
select is_empty($$ select 1 from public.ea_property_types where read_level = 'confidential' $$,
  'Referent:in sieht keine vertraulichen Arten');
select throws_ok($$ select public.ea_save_property_type('{"name": "Referent neu", "purpose": "x", "visible_in": ["EA"]}',
  '[{"key": "a", "label": "A", "data_type": "text"}]') $$,
  '42501', null, 'Referent:in legt keine Art an');
update public.ea_property_types set valid_to_label = 'bis' where id = (select id from public.ea_property_types where system_key = 'function');
select pg_temp.as_owner();
select is((select name from public.ea_property_types where id = pg_temp.employment()), 'Hauptamt',
  'Geschäftsstelle ändert keine vertrauliche Art (RLS)');
select is((select valid_to_label from public.ea_property_types where id = (select id from public.ea_property_types where system_key = 'function')), null,
  'Referent:in ändert keine Bezeichnung (R49, Rechte wie die übrigen Spalten)');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select is_empty($$ select 1 from public.ea_property_types $$, 'Vorstand liest keine Eigenschaftsarten');

-- R36 mit vorhandenen Eigenschaften (Seed): Datentyp, Bezug, neue Pflichtfelder, Auswahlwerte, Schlüssel
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select throws_ok($$ update public.ea_property_fields set data_type = 'text'
                    where property_type_id = 'd0000000-0000-4000-8000-000000000002' and key = 'size' $$,
  'P0001', 'EA_DATA_TYPE_LOCKED', 'Datentyp gesperrt bei vorhandenen Eigenschaften (R36)');
select throws_ok($$ update public.ea_property_types set relation_kind = 'gremium', relation_required = false
                    where id = (select id from public.ea_property_types where system_key = 'function') $$,
  'P0001', 'EA_RELATION_LOCKED', 'Bezug gesperrt bei vorhandenen Eigenschaften');
select throws_ok($$ select public.ea_save_property_type('{"id": "d0000000-0000-4000-8000-000000000002"}',
  (select jsonb_agg(jsonb_build_object('id', id)) from public.ea_property_fields
    where property_type_id = 'd0000000-0000-4000-8000-000000000002')
  || '[{"key": "color", "label": "Farbe", "data_type": "text", "is_required": true}]') $$,
  'P0001', 'EA_FIELD_NEW_REQUIRED', 'neues Pflichtfeld bei vorhandenen Eigenschaften (R36)');
select lives_ok($$ select public.ea_save_property_type('{"id": "d0000000-0000-4000-8000-000000000002"}',
  (select jsonb_agg(jsonb_build_object('id', id)) from public.ea_property_fields
    where property_type_id = 'd0000000-0000-4000-8000-000000000002')
  || '[{"key": "color", "label": "Farbe", "data_type": "text"}]') $$,
  'neues optionales Feld erlaubt');
select throws_ok($$ update public.ea_property_fields set choice_values = '{S,M,L}'
                    where property_type_id = 'd0000000-0000-4000-8000-000000000002' and key = 'size' $$,
  'P0001', 'EA_CHOICE_VALUE_REMOVED', 'Auswahlwert entfernen abgelehnt (R36)');
select lives_ok($$ update public.ea_property_fields set choice_values = '{S,M,L,XL,XXL}'
                   where property_type_id = 'd0000000-0000-4000-8000-000000000002' and key = 'size' $$,
  'Auswahlwert ergänzen erlaubt');
select throws_ok($$ update public.ea_property_fields set key = 'groesse'
                    where property_type_id = 'd0000000-0000-4000-8000-000000000002' and key = 'size' $$,
  '42501', null, 'Feldschlüssel nicht änderbar');
select throws_ok($$ delete from public.ea_property_fields where key = 'color' $$, '42501', null, 'Felder nicht löschbar');
select throws_ok($$ delete from public.ea_property_types where name = 'Lizenz neu' $$, '42501', null, 'Arten nicht löschbar');

-- system_key und Bezug „Gruppe“
select throws_ok($$ update public.ea_property_types set system_key = 'x' where name = 'Lizenz neu' $$,
  '42501', null, 'system_key nicht über die Oberfläche');
select throws_ok($$ select public.ea_save_property_type('{"name": "Gruppenart", "purpose": "x", "relation_kind": "group",
  "visible_in": ["GR"]}', '[{"key": "a", "label": "A", "data_type": "text"}]') $$,
  'P0001', 'AD_FORBIDDEN', 'Bezug Gruppe nur mit GR verwalten');

select pg_temp.as_owner();
select * from finish();
rollback;
