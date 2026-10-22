-- US-AD-23, US-AD-24 (spec T7 Teil, T37): Rufname, Modul der Anlage, Ehrenamtsstatus mit Historie.
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

-- Spalten und Bestand
select has_column('public', 'ea_persons', 'preferred_name', 'Rufname');
select col_default_is('public', 'ea_persons', 'created_in', 'AD', 'created_in standardmäßig AD');
select is((select created_in from public.ea_persons where id = 'a0000000-0000-4000-8000-000000000001'), 'AD',
  'Bestand mit created_in = AD');
select is((select created_in from public.ea_persons where id = 'a0000000-0000-4000-8000-000000000012'), 'GR',
  'Seed-Person 12 aus Gruppen');
select results_eq(
  $$ select id, volunteer_status::text, volunteer_status_since from public.ea_persons
      where volunteer_status is not null order by id $$,
  $$ values ('a0000000-0000-4000-8000-000000000004'::uuid, 'active'::text, date '2025-03-01'),
            ('a0000000-0000-4000-8000-000000000005', 'dormant', date '2026-01-01'),
            ('a0000000-0000-4000-8000-000000000009', 'active', date '2024-01-01'),
            ('a0000000-0000-4000-8000-000000000010', 'active', date '2023-01-01'),
            ('a0000000-0000-4000-8000-000000000011', 'left', date '2025-06-30') $$,
  'Ehrenamtsstatus nach spec.md Abschnitt 9');
select is((select count(*)::int from public.ea_volunteer_status_history), 5, 'je Status ein Eintrag in der Historie');

-- Rufname getrimmt, leer → null (US-AD-24)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select lives_ok($$ update public.ea_persons set preferred_name = '  Toni  ' where id = 'a0000000-0000-4000-8000-000000000005' $$,
  'Admin setzt Rufname');
select is((select preferred_name from public.ea_persons where id = 'a0000000-0000-4000-8000-000000000005'), 'Toni',
  'Rufname getrimmt');
update public.ea_persons set preferred_name = '   ' where id = 'a0000000-0000-4000-8000-000000000005';
select is((select preferred_name from public.ea_persons where id = 'a0000000-0000-4000-8000-000000000005'), null,
  'leerer Rufname → null');
select lives_ok($$ insert into public.ea_persons (first_name, last_name, preferred_name) values ('Erika', 'Neu', 'Eri') $$,
  'Admin legt Person mit Rufname an');

-- Geschützte Spalten
select throws_ok($$ update public.ea_persons set volunteer_status = 'left' where id = 'a0000000-0000-4000-8000-000000000004' $$,
  '42501', null, 'Ehrenamtsstatus nicht direkt änderbar');
select throws_ok($$ update public.ea_persons set kind = 'function' where id = 'a0000000-0000-4000-8000-000000000004' $$,
  '42501', null, 'kind nicht änderbar');
select throws_ok($$ update public.ea_persons set created_in = 'EA' where id = 'a0000000-0000-4000-8000-000000000004' $$,
  '42501', null, 'created_in nicht änderbar');

-- Trigger sichert auch Wege mit Nutzerkontext ab, die die Spaltenrechte umgehen (security definer)
select pg_temp.as_owner();
select set_config('request.jwt.claims', '{"sub":"b0000000-0000-4000-8000-000000000001","role":"authenticated"}', true);
select throws_ok($$ update public.ea_persons set volunteer_status = 'left' where id = 'a0000000-0000-4000-8000-000000000004' $$,
  'P0001', 'EA_STATUS_FORBIDDEN', 'Ehrenamtsstatus mit Nutzerkontext nur über die EA-Funktionen');
select throws_ok($$ update public.ea_persons set created_in = 'EA' where id = 'a0000000-0000-4000-8000-000000000004' $$,
  'P0001', 'AD_FORBIDDEN', 'created_in unveränderlich');
select set_config('ea.status_change', 'on', true);
select lives_ok($$ update public.ea_persons set volunteer_status = 'dormant', volunteer_status_since = current_date
                   where id = 'a0000000-0000-4000-8000-000000000004' $$,
  'mit Kennzeichen der EA-Funktionen erlaubt');
select set_config('ea.status_change', '', true);
select set_config('request.jwt.claims', '', true);
select lives_ok($$ update public.ea_persons set volunteer_status = 'active', volunteer_status_since = current_date
                   where id = 'a0000000-0000-4000-8000-000000000004' $$,
  'ohne Nutzerkontext (Migration, Seed, Skript) erlaubt');

-- Checks
select throws_ok($$ update public.ea_persons set volunteer_status_since = null where id = 'a0000000-0000-4000-8000-000000000004' $$,
  '23514', null, 'Status und „seit“ nur gemeinsam');
select throws_ok($$ update public.ea_persons set volunteer_status = 'active', volunteer_status_since = current_date
                   where id = 'a0000000-0000-4000-8000-000000000008' $$,
  '23514', null, 'Funktionsperson ohne Ehrenamtsstatus (R15)');
select throws_ok($$ insert into public.ea_persons (first_name, last_name, created_in) values ('X', 'Y', 'EZ') $$,
  '23514', null, 'created_in EZ erst mit Nachtrag v0.8');

-- Historie nur lesbar
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select is((select count(*)::int from public.ea_volunteer_status_history), 5, 'Admin liest die Historie');
select throws_ok($$ insert into public.ea_volunteer_status_history (person_id, status, valid_from)
                   values ('a0000000-0000-4000-8000-000000000004', 'left', current_date) $$,
  '42501', null, 'Historie nicht direkt schreibbar');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select is_empty($$ select 1 from public.ea_volunteer_status_history $$, 'Vorstand liest keine Historie');

-- View für die Fachmodule enthält die neuen Spalten
select has_column('public', 'ea_v_persons', 'preferred_name', 'ea_v_persons mit Rufname');
select has_column('public', 'ea_v_persons', 'volunteer_status', 'ea_v_persons mit Ehrenamtsstatus');

select pg_temp.as_owner();
select * from finish();
rollback;
