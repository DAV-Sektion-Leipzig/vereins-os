-- US-GR-13 (GR spec T7, T10): Funktionen in Gruppen (R28), Ehrenamtsstatus aus Gruppen (R29, Ü1).
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

create temp table r (name text primary key, result jsonb);
grant all on r to authenticated;

-- Ü1: nur intern aufrufbar
select ok(not has_function_privilege('authenticated', 'public.ea_set_status_from_group(uuid, date)', 'EXECUTE'),
  'ea_set_status_from_group für authenticated nicht ausführbar');
select ok(not has_function_privilege('anon', 'public.gr_add_group_function(uuid, text, date, date, uuid, jsonb)', 'EXECUTE'),
  'anon führt keine Gruppen-Funktion aus');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select throws_ok($$ select public.gr_add_group_function('c0000000-0000-4000-8000-000000000003', 'Trainer:in', public.gr_today(),
                                                         null, 'a0000000-0000-4000-8000-000000000012') $$,
  'P0001', 'GR_FORBIDDEN', 'Admin (Gruppen lesen) trägt keine Funktion ein');

-- Neue Person ohne Status → aktiv (R29)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
insert into r select 'neu', public.gr_add_group_function('c0000000-0000-4000-8000-000000000003', 'Trainer:in', date '2026-03-01',
  null, null, '{"first_name": "Tina", "last_name": "Trainerin", "email": "tina.trainerin@example.test"}');
select is((select result ->> 'status_set' from r where name = 'neu'), 'true', 'Status gesetzt');
select is((select result -> 'status_hint' from r where name = 'neu'), 'null'::jsonb, 'kein Hinweis');
select pg_temp.as_owner();
select results_eq(
  $$ select pe.volunteer_status::text, pe.volunteer_status_since, pe.created_in
       from public.ea_properties p join public.ea_persons pe on pe.id = p.person_id
      where p.id = ((select result ->> 'property_id' from r where name = 'neu'))::uuid $$,
  $$ values ('active'::text, date '2026-03-01', 'GR'::text) $$, 'aktiv ab „seit“ der Funktion (R29)');
select is((select count(*)::int from public.ea_volunteer_status_history h
             join public.ea_properties p on p.person_id = h.person_id
            where p.id = ((select result ->> 'property_id' from r where name = 'neu'))::uuid), 1, 'mit Historie');
select results_eq(
  $$ select field_values ->> 'function', related_group_id from public.ea_properties
      where id = ((select result ->> 'property_id' from r where name = 'neu'))::uuid $$,
  $$ values ('Trainer:in'::text, 'c0000000-0000-4000-8000-000000000003'::uuid) $$, 'Eigenschaft mit Bezug auf die Gruppe');

-- Ruhend bzw. ausgeschieden: Status bleibt, Hinweis
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
insert into r select 'ruhend', public.gr_add_group_function('c0000000-0000-4000-8000-000000000003', 'Helfer:in', public.gr_today(),
  null, 'a0000000-0000-4000-8000-000000000005');
insert into r select 'ausgeschieden', public.gr_add_group_function('c0000000-0000-4000-8000-000000000003', 'Helfer:in',
  public.gr_today(), null, 'a0000000-0000-4000-8000-000000000011');
select results_eq($$ select result ->> 'status_hint', result ->> 'status_set' from r where name in ('ruhend', 'ausgeschieden')
                      order by name desc $$,
  $$ values ('dormant'::text, 'false'::text), ('left', 'false') $$, 'Hinweis ruhend bzw. ausgeschieden (R29)');
select pg_temp.as_owner();
select results_eq($$ select volunteer_status::text from public.ea_persons
                      where id in ('a0000000-0000-4000-8000-000000000005', 'a0000000-0000-4000-8000-000000000011') order by id $$,
  $$ values ('dormant'::text), ('left') $$, 'Status unverändert');

-- R28 und Prüfungen
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select throws_ok($$ select public.gr_add_group_function('c0000000-0000-4000-8000-000000000001', 'Trainer:in', public.gr_today(),
                                                         null, 'a0000000-0000-4000-8000-000000000026') $$,
  'P0001', 'GR_FUNCTION_OVERLAP', 'gleiche Funktion überschneidend (R28)');
select lives_ok($$ select public.gr_add_group_function('c0000000-0000-4000-8000-000000000001', 'Gruppenleitung', public.gr_today(),
                                                        null, 'a0000000-0000-4000-8000-000000000026') $$,
  'andere Funktion gleichzeitig erlaubt (R28)');
select lives_ok($$ select public.gr_add_group_function('c0000000-0000-4000-8000-000000000002', 'Trainer:in', public.gr_today() - 59,
                                                        null, 'a0000000-0000-4000-8000-000000000031') $$,
  'nach Ende der früheren Funktion wieder erlaubt');
select throws_ok($$ select public.gr_add_group_function('c0000000-0000-4000-8000-000000000001', 'Helfer:in', public.gr_today(),
                                                         public.gr_today() - 1, 'a0000000-0000-4000-8000-000000000024') $$,
  'P0001', 'EA_VALID_RANGE', '„bis“ vor „seit“');
select throws_ok($$ select public.gr_add_group_function('c0000000-0000-4000-8000-000000000004', 'Helfer:in', public.gr_today(),
                                                         null, 'a0000000-0000-4000-8000-000000000024') $$,
  'P0001', 'GR_GROUP_DISSOLVED', 'aufgelöste Gruppe');
select throws_ok($$ select public.gr_add_group_function('c0000000-0000-4000-8000-000000000001', 'Chef:in', public.gr_today(),
                                                         null, 'a0000000-0000-4000-8000-000000000024') $$,
  'P0001', 'EA_FIELD_CHOICE', 'nur Gruppenleitung, Trainer:in, Helfer:in');

-- Beenden: nur group_function, Status bleibt
select throws_ok($$ select public.gr_end_group_function('e0000000-0000-4000-8000-000000000002', public.gr_today()) $$,
  'P0001', 'GR_FORBIDDEN', 'andere Eigenschaft nicht über Gruppen beendbar');
select throws_ok($$ select public.gr_end_group_function('e0000000-0000-4000-8000-000000000039', date '2025-01-01') $$,
  'P0001', 'EA_VALID_RANGE', '„bis“ vor „seit“');
select lives_ok($$ select public.gr_end_group_function('e0000000-0000-4000-8000-000000000040', public.gr_today()) $$,
  'Funktion von Sam beenden');
select pg_temp.as_owner();
select is((select valid_to from public.ea_properties where id = 'e0000000-0000-4000-8000-000000000040'), public.gr_today(), 'beendet');
select is((select volunteer_status::text from public.ea_persons where id = 'a0000000-0000-4000-8000-000000000028'), 'active',
  'Ehrenamtsstatus bleibt beim Ende der Funktion (R29)');

select * from finish();
rollback;
