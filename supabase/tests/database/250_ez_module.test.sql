-- Nachtrag v0.8 (spec T50, T56 Teil; US-AD-28; Übergabe EZ A1, A2, A5): Modul EZ, Startwerte, Reichweite „Referat“ für EZ (R30, R31).
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

-- Modul
select results_eq(
  $$ select code, name, is_available from public.ad_modules where code = 'EZ' $$,
  $$ values ('EZ'::text, 'Anwesenheitserfassung'::text, true) $$,
  'Modul EZ „Anwesenheitserfassung“, verfügbar seit der Freigabe 26.10.2026');
select is((select sort_order from public.ad_modules where code = 'EZ'),
          (select sort_order + 1 from public.ad_modules where code = 'GR'), 'EZ direkt nach GR');

-- Startwerte (A1)
select results_eq(
  $$ select t.name, r.level::text, r.scope::text
       from public.ad_template_rights r join public.ad_templates t on t.id = r.template_id
      where r.module_code = 'EZ' order by t.name $$,
  $$ values ('Admin'::text, 'read'::text, 'all'::text), ('Freigabe Touren und Kurse', 'none', 'all'),
            ('Geschäftsstelle', 'manage', 'all'), ('Referent:in', 'edit', 'referat'), ('Vorstand', 'none', 'all') $$,
  'Startwerte EZ: Admin lesen, Geschäftsstelle verwalten, Referent:in bearbeiten (Referat), Vorstand und Freigabe ohne');

-- Wirkung je Testzugang (A5)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select is(public.ad_user_level('EZ'), 'read'::public.ad_level, 'Admin: EZ lesen');
select ok(not public.ad_has_any_level('EZ', 'edit'), 'Admin: kein EZ bearbeiten');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select is(public.ad_user_level('EZ'), 'manage'::public.ad_level, 'Geschäftsstelle: EZ verwalten');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select is(public.ad_user_level('EZ'), 'none'::public.ad_level, 'Referent:in: keine Rechte mit Reichweite „alle“');
select ok(public.ad_has_any_level('EZ', 'edit'), 'Referent:in: EZ bearbeiten (Reichweite Referat)');
select results_eq(
  $$ select r.name from public.ea_referate r where r.id = any (public.ad_my_referate('EZ', 'edit')) $$,
  $$ values ('Klettern'::text) $$, 'Referent:in: EZ-Referate = Referate der Zuweisung (R31)');
select ok('EZ' = any (select m.code from public.ad_my_modules() m), 'Referent:in: Kachel EZ (verfügbar, Reichweite Referat)');
select pg_temp.as_owner();
update public.ad_modules set is_available = false where code = 'EZ';
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select ok(not ('EZ' = any (select m.code from public.ad_my_modules() m)), 'keine Kachel EZ, solange nicht verfügbar');
select pg_temp.as_owner();
update public.ad_modules set is_available = true where code = 'EZ';
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select ok(not public.ad_has_any_level('EZ', 'read'), 'Vorstand: kein Zugriff auf EZ');

-- R30: Reichweite „Referat“ für EZ erlaubt, für GR abgelehnt; neue Vorlage EZ „kein Zugriff“
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select lives_ok($$ insert into public.ad_templates (name, description) values ('Test EZ', 'nur Test') $$, 'Admin legt Vorlage an');
select results_eq(
  $$ select r.level::text, r.scope::text from public.ad_template_rights r join public.ad_templates t on t.id = r.template_id
      where t.name = 'Test EZ' and r.module_code = 'EZ' $$,
  $$ values ('none'::text, 'all'::text) $$, 'neue Vorlage: EZ kein Zugriff');
select lives_ok(
  $$ update public.ad_template_rights r set level = 'edit', scope = 'referat'
       from public.ad_templates t where t.id = r.template_id and t.name = 'Test EZ' and r.module_code = 'EZ' $$,
  'Reichweite „Referat“ für EZ');
select throws_ok(
  $$ update public.ad_template_rights r set level = 'edit', scope = 'referat'
       from public.ad_templates t where t.id = r.template_id and t.name = 'Test EZ' and r.module_code = 'GR' $$,
  'P0001', 'AD_SCOPE_NOT_ALLOWED', 'Reichweite „Referat“ für GR abgelehnt (R30)');

-- Anlagemodul EZ
select pg_temp.as_owner();
select lives_ok($$ insert into public.ea_persons (first_name, last_name, created_in) values ('Ez', 'Anlage', 'EZ') $$,
  'created_in EZ zulässig');

select * from finish();
rollback;
