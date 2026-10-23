-- US-EA-07 (EA spec T9 Teil, T6): ea_renew_property (R6, AK3, AK6), EA_RENEW_INVALID, historische Art (O2, R27 AD).
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
create function pg_temp.qual(p_code text) returns text language sql as $$
  select id::text from public.ad_qualification_types where code = p_code
$$;

create temp table renewed (id uuid);
grant all on renewed to authenticated;

-- Toni TCSPI verlängern ab 01.11.2027 mit Fortbildung (AK3)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select lives_ok($$ insert into renewed select public.ea_renew_property('e0000000-0000-4000-8000-000000000003', '2027-11-01',
  '{"valid_until": "2031-12-31", "last_training": "2027-11-01"}', '{"year": 2027, "title": "Fortbildung Sportklettern"}') $$,
  'Geschäftsstelle verlängert Toni');
select results_eq(
  $$ select p.field_values ->> 'qualification_type', p.field_values ->> 'license_number', p.field_values ->> 'valid_until',
            p.field_values ->> 'last_training', p.valid_from, p.valid_to, p.related_referat_id
       from public.ea_properties p join renewed r on r.id = p.id $$,
  format($$ values (%L::text, 'TEST-0001'::text, '2031-12-31'::text, '2027-11-01'::text, date '2027-11-01', null::date, null::uuid) $$,
         pg_temp.qual('TCSPI')),
  'neue Lizenz: gleiche Qualifikationsart und Lizenznummer, neue Werte, ab 01.11.2027');
select is((select valid_to from public.ea_properties where id = 'e0000000-0000-4000-8000-000000000003'), date '2027-10-31',
  'alte Lizenz endet am Vortag (R6)');
select is((select field_values ->> 'valid_until' from public.ea_properties where id = 'e0000000-0000-4000-8000-000000000003'),
  '2027-12-31', 'alte Werte bleiben');
select results_eq(
  $$ select p.field_values ->> 'year', p.field_values ->> 'title', p.field_values ->> 'qualification_type', p.valid_from
       from public.ea_properties p join public.ea_property_types t on t.id = p.property_type_id
      where t.system_key = 'further_training' and p.person_id = 'a0000000-0000-4000-8000-000000000004' $$,
  format($$ values ('2027'::text, 'Fortbildung Sportklettern'::text, %L::text, date '2027-11-01') $$, pg_temp.qual('TCSPI')),
  'Fortbildung 2027 mit der Qualifikationsart der Lizenz angelegt');
select is((select count(*)::int from public.ea_property_history where property_id = 'e0000000-0000-4000-8000-000000000003'), 1,
  'Historie der alten Lizenz (Beenden)');

-- ohne Fortbildung: keine weitere Eigenschaft
select lives_ok($$ select public.ea_renew_property('e0000000-0000-4000-8000-000000000016', current_date + 1,
  '{"valid_until": "2030-12-31"}') $$, 'Lena ohne Fortbildung verlängern');
select is((select count(*)::int from public.ea_properties p join public.ea_property_types t on t.id = p.property_type_id
            where t.system_key = 'further_training' and p.person_id = 'a0000000-0000-4000-8000-000000000019'), 0,
  'keine Fortbildung ohne p_training');

-- EA_RENEW_INVALID (R6)
select throws_ok($$ select public.ea_renew_property('e0000000-0000-4000-8000-000000000003', '2025-03-01', '{}') $$,
  'P0001', 'EA_RENEW_INVALID', 'neues Datum nicht später als bisheriges gültig von');
select throws_ok($$ select public.ea_renew_property('e0000000-0000-4000-8000-000000000003', '2024-01-01', '{}') $$,
  'P0001', 'EA_RENEW_INVALID', 'neues Datum früher');
select throws_ok($$ select public.ea_renew_property('e0000000-0000-4000-8000-000000000004', current_date + 1, '{}') $$,
  'P0001', 'EA_RENEW_INVALID', 'T-Shirt-Größe ist keine Lizenz oder Qualifikation');
select throws_ok($$ select public.ea_renew_property('e0000000-0000-4000-8000-000000000002', current_date + 1, '{}') $$,
  'P0001', 'EA_RENEW_INVALID', 'Funktion ist keine Lizenz oder Qualifikation');
select pg_temp.as_owner();
update public.ea_properties set valid_to = '2024-12-31' where id = 'e0000000-0000-4000-8000-000000000018';
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select throws_ok($$ select public.ea_renew_property('e0000000-0000-4000-8000-000000000018', current_date + 1, '{}') $$,
  'P0001', 'EA_RENEW_INVALID', 'beendete Lizenz nicht verlängerbar');
select throws_ok($$ select public.ea_renew_property('00000000-0000-4000-8000-000000000000', current_date + 1, '{}') $$,
  'P0001', 'EA_RENEW_INVALID', 'unbekannte Eigenschaft');

-- historische Qualifikationsart (O2, R27 AD): Anton TCSP ist aktuell, aber historisch
select throws_ok($$ select public.ea_renew_property('e0000000-0000-4000-8000-000000000007', current_date + 1,
  '{"valid_until": "2030-12-31"}') $$,
  'P0001', 'AD_QUALIFICATION_HISTORIC', 'historische Qualifikationsart lässt sich nicht verlängern');
select pg_temp.as_owner();
select is((select valid_to from public.ea_properties where id = 'e0000000-0000-4000-8000-000000000007'), null,
  'alte Lizenz bei Fehler unverändert');

-- Rechte (AK6): Referent:in Klettern verlängert Lena, nicht Anton (Ausbildung); Vorstand nichts
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
-- [OFFEN] plan.md H4: ea_property_writable der Administration erlaubt Referent:innen nur Eigenschaften mit Bezug auf ein
-- eigenes Referat; EA spec.md R12 und US-EA-07 AK6 erwarten alle Arten der Lesestufe „alle“ für Personen ihrer Referate.
-- Bis zur Entscheidung des Product Owners als TODO: der Fall darf fehlschlagen, ohne die CI rot zu machen.
select todo('H4: Referent:in verlängert Lizenz ohne Referatsbezug (EA R12 vs. ea_property_writable AD)', 1);
select lives_ok($$ select public.ea_renew_property('e0000000-0000-4000-8000-000000000016', current_date + 2,
  '{"valid_until": "2031-12-31"}') $$, 'Referent:in verlängert Lena (eigenes Referat, AK6)');
select throws_ok($$ select public.ea_renew_property('e0000000-0000-4000-8000-000000000007', current_date + 1,
  '{"valid_until": "2030-12-31"}') $$,
  'P0001', 'EA_RENEW_INVALID', 'Referent:in: Anton nicht sichtbar, also keine Auskunft');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select throws_ok($$ select public.ea_renew_property('e0000000-0000-4000-8000-000000000003', current_date + 1, '{}') $$,
  'P0001', 'EA_RENEW_INVALID', 'Vorstand');

select pg_temp.as_owner();
select * from finish();
rollback;
