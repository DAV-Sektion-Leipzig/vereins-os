-- US-AD-17, US-AD-18 (spec T29): Qualifikationsarten – Startbestand, R21–R24, Rechte, kein Löschen, Idempotenz.
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

-- Startbestand (US-AD-18)
select is((select count(*)::int from public.ad_qualification_types), 47, '47 Qualifikationsarten');
select is((select count(*)::int from public.ad_qualification_types where status = 'historic'), 11, '11 historisch');
select is((select status::text from public.ad_qualification_types where code = 'PSA'), 'historic', 'PSA historisch, bis entschieden');
select results_eq(
  $$ select discipline, count(*)::int from public.ad_qualification_types group by discipline order by discipline $$,
  $$ values ('Berg- und Klettersport Winter'::text, 11), ('Bergsport Sommer', 18), ('Jugend und Familie', 2),
            ('Klettersport', 16) $$,
  'Anzahl je Sparte');
select results_eq(
  $$ select code, kind::text, level::text, validity_years::int, dosb_eligible from public.ad_qualification_types
      where code in ('KB', 'TCSPI', 'RB', 'ZQOS', 'TBS', 'JL') order by code $$,
  $$ values ('JL'::text, 'license'::text, 'none'::text, 1, null::boolean),
            ('KB', 'license', 'pre', 4, false),
            ('RB', 'license', 'none', 4, false),
            ('TBS', 'course', null, null, null),
            ('TCSPI', 'license', 'C', 4, true),
            ('ZQOS', 'add_on', null, null, null) $$,
  'Abbildung Typ, Stufe, Gültigkeitsdauer, DOSB');

-- Lesen mit aktivem Zugang
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select is((select count(*)::int from public.ad_qualification_types), 47, 'Vorstand liest');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select is((select count(*)::int from public.ad_qualification_types), 47, 'Referent:in liest');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000006');
select is((select count(*)::int from public.ad_qualification_types), 0, 'eingeladen: liest nicht');

-- Schreiben: Admin und Geschäftsstelle; R21–R24
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select ok(public.ad_can_edit_qualification_types(), 'Geschäftsstelle darf pflegen (EA verwalten)');
select lives_ok(
  $$ insert into public.ad_qualification_types (code, name, discipline, kind, level, validity_years)
     values (' tneu1 ', '  Trainer*in C Test  ', 'Klettersport', 'license', 'C', 4) $$,
  'Geschäftsstelle legt Qualifikationsart an');
select results_eq(
  $$ select code, name from public.ad_qualification_types where code = 'TNEU1' $$,
  $$ values ('TNEU1'::text, 'Trainer*in C Test'::text) $$, 'Kürzel groß, Bezeichnung getrimmt (R22)');
select throws_ok(
  $$ insert into public.ad_qualification_types (name, discipline, kind) values ('  ', 'Klettersport', 'course') $$,
  'P0001', 'AD_QUALIFICATION_NAME_REQUIRED', 'leere Bezeichnung (R21)');
select throws_ok(
  $$ insert into public.ad_qualification_types (name, discipline, kind) values ('trainer*in c test', 'Klettersport', 'course') $$,
  'P0001', 'AD_QUALIFICATION_NAME_TAKEN', 'Bezeichnung doppelt ohne Groß-/Kleinschreibung (R21)');
select throws_ok(
  $$ insert into public.ad_qualification_types (code, name, discipline, kind) values ('tcspi', 'Neu 1', 'Klettersport', 'course') $$,
  'P0001', 'AD_QUALIFICATION_CODE_TAKEN', 'Kürzel doppelt (R22)');
select throws_ok(
  $$ insert into public.ad_qualification_types (code, name, discipline, kind) values ('AB-1', 'Neu 2', 'Klettersport', 'course') $$,
  'P0001', 'AD_QUALIFICATION_CODE_FORMAT', 'Kürzel mit Bindestrich (R22)');
select throws_ok(
  $$ insert into public.ad_qualification_types (code, name, discipline, kind) values ('ABCDEFGHIJK', 'Neu 3', 'Klettersport', 'course') $$,
  'P0001', 'AD_QUALIFICATION_CODE_FORMAT', 'Kürzel länger als 10 Zeichen (R22)');
select throws_ok(
  $$ insert into public.ad_qualification_types (name, discipline, kind, validity_years) values ('Neu 4', 'Klettersport', 'license', 4) $$,
  'P0001', 'AD_QUALIFICATION_LEVEL_REQUIRED', 'Lizenz ohne Stufe (R23)');
select throws_ok(
  $$ insert into public.ad_qualification_types (name, discipline, kind, level) values ('Neu 5', 'Klettersport', 'license', 'C') $$,
  'P0001', 'AD_QUALIFICATION_VALIDITY', 'Lizenz ohne Gültigkeitsdauer (R24)');
select throws_ok(
  $$ insert into public.ad_qualification_types (name, discipline, kind, level, validity_years) values ('Neu 6', 'Klettersport', 'license', 'C', 11) $$,
  'P0001', 'AD_QUALIFICATION_VALIDITY', 'Gültigkeitsdauer 11 (R24)');
select throws_ok(
  $$ insert into public.ad_qualification_types (name, discipline, kind, validity_years) values ('Neu 7', 'Klettersport', 'training', 0) $$,
  'P0001', 'AD_QUALIFICATION_VALIDITY', 'Weiterbildung mit Gültigkeitsdauer 0 (R24)');
select lives_ok(
  $$ insert into public.ad_qualification_types (name, discipline, kind, level, validity_years)
     values ('Neu 8', 'Klettersport', 'add_on', 'C', 4) $$,
  'Zusatzqualifikation mit Stufe und Dauer angelegt');
select results_eq(
  $$ select level::text, validity_years::int from public.ad_qualification_types where name = 'Neu 8' $$,
  $$ values (null::text, null::int) $$, 'Stufe und Gültigkeitsdauer bei Zusatzqualifikation geleert (R23, R24)');

-- R25: historisch setzen und zurück; geändert am/von
select lives_ok($$ update public.ad_qualification_types set status = 'historic' where code = 'TNEU1' $$, 'auf historisch setzen');
select lives_ok($$ update public.ad_qualification_types set status = 'current' where code = 'TNEU1' $$, 'zurück auf aktuell');
select is((select updated_by from public.ad_qualification_types where code = 'TNEU1'),
  'b0000000-0000-4000-8000-000000000002'::uuid, 'geändert von');

-- source_ref nur per Migration
select throws_ok($$ update public.ad_qualification_types set source_ref = 'x' where code = 'TNEU1' $$,
  '42501', null, 'source_ref für Nutzer nicht änderbar');

-- Vorstand und Referent:in dürfen nicht pflegen; niemand löscht
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select ok(not public.ad_can_edit_qualification_types(), 'Vorstand darf nicht pflegen');
select throws_ok(
  $$ insert into public.ad_qualification_types (name, discipline, kind) values ('Vorstand Test', 'Klettersport', 'course') $$,
  '42501', null, 'Vorstand legt nicht an');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
update public.ad_qualification_types set note = 'geändert' where code = 'KB';
select pg_temp.as_owner();
select is((select note from public.ad_qualification_types where code = 'KB'), 'R3-Ausnahme', 'Referent:in ändert nichts');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select throws_ok($$ delete from public.ad_qualification_types where code = 'KB' $$, '42501', null, 'kein Löschen');

-- Idempotenz des Startbestands: ein geänderter Eintrag bleibt geändert
select lives_ok($$ update public.ad_qualification_types set name = 'Kletterbetreuer*in (geändert)' where code = 'KB' $$,
  'Admin ändert einen Eintrag des Startbestands');
select pg_temp.as_owner();
insert into public.ad_qualification_types (source_ref, code, name, discipline, kind, level, validity_years)
values ('2325', 'KB', 'Kletterbetreuer*in Breitensport', 'Klettersport', 'license', 'pre', 4)
on conflict (source_ref) where source_ref is not null do nothing;
select is((select name from public.ad_qualification_types where source_ref = '2325'), 'Kletterbetreuer*in (geändert)',
  'zweiter Lauf überschreibt nichts');
select is((select count(*)::int from public.ad_qualification_types where source_ref is not null), 47, 'keine Dubletten');

select * from finish();
rollback;
