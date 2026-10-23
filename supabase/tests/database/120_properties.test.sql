-- US-AD-13, US-AD-19 (spec T7 Teil, T36): Eigenschaften – R35, R37, R38, R27, R28, Gültigkeit, Historie.
-- Arten: d…02 T-Shirt-Größe (Seed, ein Eintrag) sowie die System-Eigenschaftsarten function, committee (Bezug Gremium
-- Pflicht) und license (EA-Migration 20261024000100, Ü3). Als test.admin (AD verwalten), sofern nicht anders angegeben.
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
create function pg_temp.referat(p_name text) returns uuid language sql as $$
  select id from public.ea_referate where name = p_name
$$;
create function pg_temp.qual(p_code text) returns text language sql as $$
  select id::text from public.ad_qualification_types where code = p_code
$$;

-- Testart mit Feldern aller Datentypen für die Prüfungen von R35
select pg_temp.as_owner();
insert into public.ea_property_types (id, name, purpose, visible_in)
values ('d0000000-0000-4000-8000-0000000000aa', 'Alle Typen', 'Test', '{AD}');
insert into public.ea_property_fields (property_type_id, key, label, data_type, is_required, choice_values, sort_order) values
  ('d0000000-0000-4000-8000-0000000000aa', 'pflicht', 'Pflichttext', 'text', true, null, 1),
  ('d0000000-0000-4000-8000-0000000000aa', 'zahl', 'Zahl', 'number', false, null, 2),
  ('d0000000-0000-4000-8000-0000000000aa', 'jahr', 'Jahr', 'year', false, null, 3),
  ('d0000000-0000-4000-8000-0000000000aa', 'datum', 'Datum', 'date', false, null, 4),
  ('d0000000-0000-4000-8000-0000000000aa', 'janein', 'Ja/Nein', 'boolean', false, null, 5),
  ('d0000000-0000-4000-8000-0000000000aa', 'wahl', 'Auswahl', 'choice', false, '{a,b}', 6);

select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
create function pg_temp.prop(p_values jsonb) returns void language sql as $$
  insert into public.ea_properties (person_id, property_type_id, field_values, valid_from)
  values ('a0000000-0000-4000-8000-000000000004', 'd0000000-0000-4000-8000-0000000000aa', p_values, current_date)
$$;

select lives_ok($$ select pg_temp.prop('{"pflicht": " x ", "zahl": 1.5, "jahr": 1990, "datum": "2026-02-28",
  "janein": true, "wahl": "b"}') $$, 'alle Datentypen gültig');
select is((select field_values ->> 'pflicht' from public.ea_properties
            where property_type_id = 'd0000000-0000-4000-8000-0000000000aa'), 'x', 'Text getrimmt');
select throws_ok($$ select pg_temp.prop('{"zahl": 1}') $$, 'P0001', 'EA_FIELD_REQUIRED', 'Pflichtfeld fehlt (R35)');
select throws_ok($$ select pg_temp.prop('{"pflicht": "  "}') $$, 'P0001', 'EA_FIELD_REQUIRED', 'Pflichtfeld leer (R35)');
select throws_ok($$ select pg_temp.prop('{"pflicht": "x", "zahl": "1"}') $$, 'P0001', 'EA_VALUE_TYPE', 'Zahl als Text');
select throws_ok($$ select pg_temp.prop('{"pflicht": "x", "jahr": 1899}') $$, 'P0001', 'EA_VALUE_TYPE', 'Jahr 1899');
select throws_ok($$ select pg_temp.prop('{"pflicht": "x", "jahr": 2101}') $$, 'P0001', 'EA_VALUE_TYPE', 'Jahr 2101');
select throws_ok($$ select pg_temp.prop('{"pflicht": "x", "jahr": 2000.5}') $$, 'P0001', 'EA_VALUE_TYPE', 'Jahr nicht ganzzahlig');
select throws_ok($$ select pg_temp.prop('{"pflicht": "x", "datum": "31.12.2026"}') $$, 'P0001', 'EA_VALUE_TYPE', 'Datum im falschen Format');
select throws_ok($$ select pg_temp.prop('{"pflicht": "x", "datum": "2026-02-30"}') $$, 'P0001', 'EA_VALUE_TYPE', 'ungültiges Datum');
select throws_ok($$ select pg_temp.prop('{"pflicht": "x", "janein": "ja"}') $$, 'P0001', 'EA_VALUE_TYPE', 'Ja/Nein als Text');
select throws_ok($$ select pg_temp.prop('{"pflicht": "x", "wahl": "c"}') $$, 'P0001', 'EA_FIELD_CHOICE', 'Wert nicht in der Liste (R35)');
select throws_ok($$ select pg_temp.prop('{"pflicht": "x", "fremd": 1}') $$, 'P0001', 'EA_FIELD_UNKNOWN', 'unbekannter Schlüssel (R35)');

-- Feldname im detail des Fehlers (für die Meldung „Bitte ‚<Feld>‘ ausfüllen.“)
select pg_temp.as_owner();
create function pg_temp.error_detail(p_sql text) returns text language plpgsql as $$
declare v_detail text;
begin
  execute p_sql;
  return null;
exception when others then
  get stacked diagnostics v_detail = pg_exception_detail;
  return v_detail;
end $$;
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select is(pg_temp.error_detail($$ select pg_temp.prop('{"zahl": 1}') $$), 'Pflichttext', 'detail = Feldbezeichnung');

-- R38: Bezug Pflicht, inaktives Referat
select throws_ok($$ insert into public.ea_properties (person_id, property_type_id, field_values, valid_from)
                    values ('a0000000-0000-4000-8000-000000000004',
                            (select id from public.ea_property_types where system_key = 'committee'),
                            '{"role": "Mitglied"}', current_date) $$,
  'P0001', 'EA_RELATION_REQUIRED', 'Bezug Pflicht ohne Gremium (R38)');
select pg_temp.as_owner();
update public.ea_referate set is_active = false where name = 'Leistungssport';
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select throws_ok(format($$ insert into public.ea_properties (person_id, property_type_id, field_values, related_referat_id, valid_from)
                    values ('a0000000-0000-4000-8000-000000000004', (select id from public.ea_property_types where system_key = 'function'),
                            '{"function": "Helfer:in"}', %L, current_date) $$, pg_temp.referat('Leistungssport')),
  'P0001', 'EA_RELATION_REQUIRED', 'inaktives Referat nicht neu wählbar (R38)');

-- R37: nur ein gültiger Eintrag je Zeitraum (T-Shirt-Größe, Toni seit 01.01.2025)
select throws_ok($$ insert into public.ea_properties (person_id, property_type_id, field_values, valid_from)
                    values ('a0000000-0000-4000-8000-000000000004', 'd0000000-0000-4000-8000-000000000002',
                            '{"size": "L"}', '2026-01-01') $$,
  'P0001', 'EA_SINGLE_VALUE', 'zweiter überlappender Eintrag (R37)');
select lives_ok($$ update public.ea_properties set valid_to = '2025-12-31' where id = 'e0000000-0000-4000-8000-000000000004' $$,
  'alten Eintrag beenden');
select lives_ok($$ insert into public.ea_properties (person_id, property_type_id, field_values, valid_from)
                   values ('a0000000-0000-4000-8000-000000000004', 'd0000000-0000-4000-8000-000000000002',
                           '{"size": "L"}', '2026-01-01') $$,
  'nicht überlappender Eintrag erlaubt');

-- R27, R28: Qualifikationsart als Feld
select throws_ok(format($$ insert into public.ea_properties (person_id, property_type_id, field_values, valid_from)
                    values ('a0000000-0000-4000-8000-000000000010', (select id from public.ea_property_types where system_key = 'license'),
                            jsonb_build_object('qualification_type', %L), current_date) $$, pg_temp.qual('TCSP')),
  'P0001', 'AD_QUALIFICATION_HISTORIC', 'historische Qualifikationsart nicht neu vergeben (R27)');
select throws_ok(format($$ insert into public.ea_properties (person_id, property_type_id, field_values, valid_from)
                    values ('a0000000-0000-4000-8000-000000000010', (select id from public.ea_property_types where system_key = 'license'),
                            jsonb_build_object('qualification_type', %L), current_date) $$, pg_temp.qual('ZQOS')),
  'P0001', 'AD_QUALIFICATION_KIND', 'Zusatzqualifikation im Lizenzfeld (R28)');
select throws_ok($$ insert into public.ea_properties (person_id, property_type_id, field_values, valid_from)
                    values ('a0000000-0000-4000-8000-000000000010', (select id from public.ea_property_types where system_key = 'license'),
                            '{"qualification_type": "00000000-0000-4000-8000-000000000000"}', current_date) $$,
  'P0001', 'EA_VALUE_TYPE', 'nicht vorhandene Qualifikationsart');
select lives_ok($$ update public.ea_properties set field_values = field_values || '{"license_number": "TEST-0002"}'
                   where id = 'e0000000-0000-4000-8000-000000000007' $$,
  'andere Werte einer Eigenschaft mit historischer Qualifikationsart änderbar (R27)');
select pg_temp.as_owner();
select lives_ok(format($$ insert into public.ea_properties (person_id, property_type_id, field_values, valid_from)
                   values ('a0000000-0000-4000-8000-000000000010', (select id from public.ea_property_types where system_key = 'license'),
                           jsonb_build_object('qualification_type', %L, 'valid_until', '2015-12-31'), '2010-01-01') $$, pg_temp.qual('TCSP')),
  'ohne Nutzerkontext historische Qualifikationsart erlaubt (Altbestand)');

-- Gültigkeit und Historie
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select throws_ok($$ update public.ea_properties set valid_to = '2020-01-01' where id = 'e0000000-0000-4000-8000-000000000002' $$,
  '23514', null, '„gültig bis“ vor „gültig von“ (ea_properties_valid_range)');
select lives_ok($$ update public.ea_properties set field_values = '{"function": "Helfer:in"}'
                   where id = 'e0000000-0000-4000-8000-000000000002' $$, 'Funktion ändern');
select results_eq(
  $$ select field_values ->> 'function', changed_by from public.ea_property_history
      where property_id = 'e0000000-0000-4000-8000-000000000002' $$,
  $$ values ('Trainer:in'::text, 'b0000000-0000-4000-8000-000000000001'::uuid) $$,
  'Historie mit alter Fassung und geändert von');
select is((select updated_by from public.ea_properties where id = 'e0000000-0000-4000-8000-000000000002'),
  'b0000000-0000-4000-8000-000000000001'::uuid, 'geändert von an der Eigenschaft');
select throws_ok($$ delete from public.ea_properties where id = 'e0000000-0000-4000-8000-000000000002' $$,
  '42501', null, 'kein Löschen (Beenden über gültig bis)');
select throws_ok($$ insert into public.ea_property_history (property_id, field_values, valid_from)
                    values ('e0000000-0000-4000-8000-000000000002', '{}', current_date) $$,
  '42501', null, 'Historie nicht direkt schreibbar');

select pg_temp.as_owner();
select * from finish();
rollback;
