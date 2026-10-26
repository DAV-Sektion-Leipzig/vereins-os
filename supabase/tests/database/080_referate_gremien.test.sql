-- US-AD-20, US-AD-22 (spec T7 Teil, T34): Stammdaten Referate und Gremien.
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

-- Startbestand
select results_eq($$ select name from public.ea_referate order by sort_order $$,
  $$ values ('Ausbildung'::text), ('Touren'), ('Kinder und Jugend'), ('Klettern'), ('Leistungssport'),
            ('Karl-Stein-Hütte'), ('Sulzenauhütte'), ('Öffentlichkeitsarbeit'), ('Umwelt und Naturschutz') $$,
  '9 Referate in der Reihenfolge aus spec.md (Dashboard D10: Öffentlichkeitsarbeit, Umwelt und Naturschutz)');
select results_eq($$ select name from public.ea_gremien order by sort_order $$,
  $$ values ('Vorstand'::text), ('Beirat'), ('Ehrenrat'), ('Jugendausschuss') $$, '4 Gremien');
select ok((select bool_and(is_active) from public.ea_referate), 'alle Referate aktiv');

-- Lesen mit aktivem Zugang
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select is((select count(*)::int from public.ea_referate), 9, 'Vorstand liest Referate');
select is((select count(*)::int from public.ea_gremien), 4, 'Vorstand liest Gremien');
select ok(public.ad_has_active_access(), 'ad_has_active_access für aktiven Zugang');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000006');
select is((select count(*)::int from public.ea_referate), 0, 'eingeladen: keine Referate');
select ok(not public.ad_has_active_access(), 'ad_has_active_access ohne aktiven Zugang falsch');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000007');
select is((select count(*)::int from public.ea_gremien), 0, 'gesperrt: keine Gremien');

-- Pflegen: Admin und Geschäftsstelle; nicht Vorstand, nicht Referent:in; kein Löschen
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select lives_ok($$ insert into public.ea_referate (name, sort_order) values ('Testreferat', 8) $$, 'Admin legt Referat an');
select throws_ok($$ insert into public.ea_referate (name, sort_order) values ('testreferat', 9) $$,
  '23505', null, 'Bezeichnung doppelt ohne Groß-/Kleinschreibung (ea_referate_name_key)');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select lives_ok($$ update public.ea_referate set is_active = false where name = 'Testreferat' $$,
  'Geschäftsstelle setzt Referat inaktiv');
select lives_ok($$ insert into public.ea_gremien (name, sort_order) values ('Testgremium', 5) $$,
  'Geschäftsstelle legt Gremium an');
select pg_temp.as_owner();
select is((select updated_by from public.ea_referate where name = 'Testreferat'),
  'b0000000-0000-4000-8000-000000000002'::uuid, 'geändert von');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select throws_ok($$ insert into public.ea_referate (name, sort_order) values ('Fremd', 10) $$,
  '42501', null, 'Vorstand darf kein Referat anlegen');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select throws_ok($$ insert into public.ea_gremien (name, sort_order) values ('Fremd', 10) $$,
  '42501', null, 'Referent:in darf kein Gremium anlegen');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select throws_ok($$ delete from public.ea_referate where name = 'Testreferat' $$, '42501', null, 'kein Löschen');

select pg_temp.as_owner();
select * from finish();
rollback;
