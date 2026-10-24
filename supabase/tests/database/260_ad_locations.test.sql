-- Nachtrag v0.8 (spec T51, T56 Teil; US-AD-27; Übergabe EZ A8; R43): Orte.
-- Seed: Kletterhalle Test (Punktekonto, aktiv), Fels Test (aktiv), Halle alt Test (inaktiv).
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

select has_table('public', 'ad_locations', 'Tabelle ad_locations');
select ok((select relrowsecurity from pg_class where oid = 'public.ad_locations'::regclass), 'RLS aktiv');
select ok(not has_table_privilege('anon', 'public.ad_locations', 'SELECT'), 'anon: kein Zugriff');
select ok(not has_table_privilege('authenticated', 'public.ad_locations', 'DELETE'), 'kein Löschen');
select ok(not has_column_privilege('authenticated', 'public.ad_locations', 'created_by', 'UPDATE'), 'created_by nicht änderbar');

-- Lesen mit aktivem Zugang
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select results_eq($$ select name, has_climbing_points, is_active from public.ad_locations order by name $$,
  $$ values ('Fels Test'::text, false, true), ('Halle alt Test', false, false), ('Kletterhalle Test', true, true) $$,
  'Referent:in liest die Orte');
select ok(not public.ad_can_edit_locations(), 'Referent:in pflegt keine Orte');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000006');
select is_empty($$ select 1 from public.ad_locations $$, 'eingeladen (kein aktiver Zugang): liest nichts');

-- Pflege nur Admin
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select ok(not public.ad_can_edit_locations(), 'Geschäftsstelle pflegt keine Orte');
select throws_ok($$ insert into public.ad_locations (name) values ('Ort GS') $$, '42501', null,
  'Geschäftsstelle: anlegen abgelehnt');
update public.ad_locations set name = 'geändert' where name = 'Fels Test';
select pg_temp.as_owner();
select ok(exists (select 1 from public.ad_locations where name = 'Fels Test'), 'Geschäftsstelle: ändern ohne Wirkung');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select ok(public.ad_can_edit_locations(), 'Admin pflegt Orte');
select lives_ok($$ insert into public.ad_locations (name, has_climbing_points) values ('  Boulderhalle Test  ', true) $$,
  'Admin legt Ort an');
select pg_temp.as_owner();
select results_eq($$ select name, created_by from public.ad_locations where lower(name) = 'boulderhalle test' $$,
  $$ values ('Boulderhalle Test'::text, 'b0000000-0000-4000-8000-000000000001'::uuid) $$, 'getrimmt, angelegt von');

-- R43
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select throws_ok($$ insert into public.ad_locations (name) values ('   ') $$, 'P0001', 'AD_LOCATION_NAME_REQUIRED',
  'leere Bezeichnung');
select throws_ok($$ insert into public.ad_locations (name) values ('kletterhalle test') $$, 'P0001', 'AD_LOCATION_NAME_TAKEN',
  'Bezeichnung doppelt ohne Groß-/Kleinschreibung');
select throws_ok($$ update public.ad_locations set name = 'FELS TEST' where name = 'Kletterhalle Test' $$,
  'P0001', 'AD_LOCATION_NAME_TAKEN', 'Umbenennen auf vorhandene Bezeichnung');
select lives_ok($$ update public.ad_locations set name = 'fels test' where name = 'Fels Test' $$,
  'eigene Bezeichnung in anderer Schreibweise');
select lives_ok($$ update public.ad_locations set is_active = false where name = 'Kletterhalle Test' $$, 'inaktiv setzen');
select pg_temp.as_owner();
select results_eq(
  $$ select is_active, updated_by, updated_at is not null from public.ad_locations where name = 'Kletterhalle Test' $$,
  $$ values (false, 'b0000000-0000-4000-8000-000000000001'::uuid, true) $$, 'geändert am/von gesetzt');

-- Kein Löschen, auch nicht für den Admin
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select throws_ok($$ delete from public.ad_locations where name = 'Halle alt Test' $$, '42501', null, 'Admin: löschen abgelehnt');

select pg_temp.as_owner();
select * from finish();
rollback;
