-- US-GR-03, US-GR-04, US-GR-18 (GR spec T1, T3, T10): Gruppen anlegen, ändern, auflösen; Trainingszeiten
-- (R1, R9, R18, R19, R21, A12, A13) mit dem Seed aus GR spec.md Abschnitt 9.
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

-- Struktur und Rechte
select ok((select relrowsecurity from pg_class where oid = 'public.gr_groups'::regclass), 'RLS auf gr_groups');
select ok((select relrowsecurity from pg_class where oid = 'public.gr_training_times'::regclass), 'RLS auf gr_training_times');
select ok(not has_table_privilege('authenticated', 'public.gr_groups', 'INSERT'), 'kein Insert-Recht auf gr_groups');
select ok(not has_table_privilege('authenticated', 'public.gr_training_times', 'UPDATE'), 'kein Update-Recht auf gr_training_times');
select ok(not has_table_privilege('anon', 'public.gr_groups', 'SELECT'), 'anon liest gr_groups nicht');
select is(public.gr_today(), (now() at time zone 'Europe/Berlin')::date, 'gr_today = heute in Europe/Berlin');

-- Lesen: Geschäftsstelle und Admin alle Gruppen; Referent:in über EA (Gruppenname, US-GR-13 AK3); Vorstand nichts
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select is((select count(*)::int from public.gr_groups), 4, 'Geschäftsstelle liest alle Gruppen');
select is((select count(*)::int from public.gr_training_times), 5, 'Geschäftsstelle liest Trainingszeiten');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select is((select count(*)::int from public.gr_groups), 4, 'Referent:in liest Gruppennamen (EA-Recht)');
select is((select count(*)::int from public.gr_training_times), 0, 'Referent:in liest keine Trainingszeiten');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select is((select count(*)::int from public.gr_groups), 0, 'Vorstand liest keine Gruppen');

-- gr_save_group (R1, R21)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select throws_ok(format($$ select public.gr_save_group(null, 'Neue Gruppe', %L) $$, pg_temp.referat('Kinder und Jugend')),
  'P0001', 'GR_FORBIDDEN', 'Admin (Gruppen lesen) legt keine Gruppe an');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select throws_ok($$ select public.gr_save_group(null, '  ', null) $$, 'P0001', 'GR_GROUP_FIELDS_REQUIRED', 'Name und Referat Pflicht');
select throws_ok(format($$ select public.gr_save_group(null, 'jugendgruppe test 1', %L) $$, pg_temp.referat('Kinder und Jugend')),
  'P0001', 'GR_GROUP_NAME_TAKEN', 'Name ohne Groß-/Kleinschreibung eindeutig (R1)');
select lives_ok(format($$ select public.gr_save_group(null, 'Altgruppe Test', %L) $$, pg_temp.referat('Kinder und Jugend')),
  'Name einer aufgelösten Gruppe ist wieder frei');

select pg_temp.as_owner();
update public.ea_referate set is_active = false where name = 'Touren';
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select throws_ok(format($$ select public.gr_save_group(null, 'Tourengruppe', %L) $$, pg_temp.referat('Touren')),
  'P0001', 'GR_REFERAT_INACTIVE', 'nur aktive Referate (R21)');

select lives_ok($$ select public.gr_save_group('c0000000-0000-4000-8000-000000000003', ' Klettergruppe Test neu ',
                                               (select referat_id from public.gr_groups where id = 'c0000000-0000-4000-8000-000000000003')) $$,
  'Gruppe umbenennen');
select is((select name from public.gr_groups where id = 'c0000000-0000-4000-8000-000000000003'), 'Klettergruppe Test neu',
  'Name getrimmt gespeichert');
select throws_ok(format($$ select public.gr_save_group('c0000000-0000-4000-8000-000000000004', 'Altgruppe neu', %L) $$,
                        pg_temp.referat('Kinder und Jugend')),
  'P0001', 'GR_GROUP_DISSOLVED', 'aufgelöste Gruppe nicht änderbar');

-- Trainingszeiten (R18, R19)
select throws_ok($$ select public.gr_add_training_time('c0000000-0000-4000-8000-000000000003', null, '17:00', '18:00', public.gr_today()) $$,
  'P0001', 'GR_TRAINING_TIME_REQUIRED', 'Wochentag Pflicht (R18)');
select throws_ok($$ select public.gr_add_training_time('c0000000-0000-4000-8000-000000000003', 1::smallint, '18:00', '18:00', public.gr_today()) $$,
  'P0001', 'GR_TRAINING_TIME_END', 'Ende nach Beginn (R18)');
select throws_ok($$ select public.gr_add_training_time('c0000000-0000-4000-8000-000000000003', 1::smallint, '17:00', '18:00',
                                                        public.gr_today(), public.gr_today() - 1) $$,
  'P0001', 'GR_VALID_TO_BEFORE_FROM', '„gültig bis“ nicht vor „gültig von“ (R18)');
select is((public.gr_add_training_time('c0000000-0000-4000-8000-000000000001', 2::smallint, '17:00', '18:30',
                                       public.gr_today()) ->> 'overlap')::boolean, true,
  'Überschneidung mit Di 16:30–18:00 wird gemeldet, gespeichert wird trotzdem (R19)');
select is((public.gr_add_training_time('c0000000-0000-4000-8000-000000000001', 5::smallint, '17:00', '18:30',
                                       public.gr_today()) ->> 'overlap')::boolean, false, 'keine Überschneidung');

select throws_ok($$ select public.gr_change_training_time('c1000000-0000-4000-8000-000000000001', date '2025-09-01',
                                                           2::smallint, '16:00', '17:30') $$,
  'P0001', 'GR_CHANGE_DATE_INVALID', '„Ändern ab“ nicht am „gültig von“ (R19)');
select throws_ok($$ select public.gr_change_training_time('c1000000-0000-4000-8000-000000000003', date '2026-02-01',
                                                           3::smallint, '16:00', '17:30') $$,
  'P0001', 'GR_CHANGE_DATE_INVALID', '„Ändern ab“ nicht nach „gültig bis“ (R19)');
select lives_ok($$ select public.gr_change_training_time('c1000000-0000-4000-8000-000000000001', date '2026-03-01',
                                                          2::smallint, '16:00', '17:30') $$, '„Ändern ab“');
select is((select valid_to from public.gr_training_times where id = 'c1000000-0000-4000-8000-000000000001'), date '2026-02-28',
  'alte Trainingszeit endet am Vortag');
select results_eq(
  $$ select starts_at, ends_at, valid_to from public.gr_training_times
      where group_id = 'c0000000-0000-4000-8000-000000000001' and valid_from = date '2026-03-01' $$,
  $$ values (time '16:00', time '17:30', null::date) $$,
  'neue Trainingszeit ab dem Datum mit altem „gültig bis“');

select lives_ok($$ select public.gr_end_training_time('c1000000-0000-4000-8000-000000000002', date '2026-12-31') $$, 'beenden');
select lives_ok($$ select public.gr_end_training_time('c1000000-0000-4000-8000-000000000002', date '2027-06-30') $$,
  '„gültig bis“ ändern');
select throws_ok($$ select public.gr_end_training_time('c1000000-0000-4000-8000-000000000002', date '2025-01-01') $$,
  'P0001', 'GR_VALID_TO_BEFORE_FROM', 'beenden vor „gültig von“');

select pg_temp.as_owner();
select throws_ok($$ update public.gr_training_times set weekday = 5 where id = 'c1000000-0000-4000-8000-000000000002' $$,
  'P0001', 'GR_TRAINING_TIME_LOCKED', 'Kernfelder gesperrt, auch für den Eigentümer (A13)');

-- Auflösen (R9, A12)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select throws_ok($$ select public.gr_dissolve_group('c0000000-0000-4000-8000-000000000001', public.gr_today()) $$,
  'P0001', 'GR_GROUP_HAS_MEMBERS', 'Gruppe mit aktiven Teilnehmer:innen (R9)');
select throws_ok($$ select public.gr_dissolve_group('c0000000-0000-4000-8000-000000000003', public.gr_today() + 1) $$,
  'P0001', 'GR_DATE_IN_FUTURE', 'Auflösungsdatum nicht in der Zukunft');

select pg_temp.as_owner();
update public.gr_memberships set left_on = public.gr_today() - 1 where group_id = 'c0000000-0000-4000-8000-000000000002';
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select throws_ok($$ select public.gr_dissolve_group('c0000000-0000-4000-8000-000000000002', public.gr_today()) $$,
  'P0001', 'GR_GROUP_HAS_PENDING', 'Gruppe mit offener Aufnahme (R9)');

-- Leere Gruppe mit Funktion und Trainingszeit; eine Trainingszeit beginnt erst nach dem Auflösungsdatum
select pg_temp.as_owner();
insert into public.ea_properties (person_id, property_type_id, field_values, related_group_id, valid_from)
select 'a0000000-0000-4000-8000-000000000026', t.id, '{"function": "Helfer:in"}', 'c0000000-0000-4000-8000-000000000003',
       public.gr_today() - 100
  from public.ea_property_types t where t.system_key = 'group_function';
insert into public.gr_training_times (id, group_id, weekday, starts_at, ends_at, valid_from)
values ('c1000000-0000-4000-8000-0000000000ff', 'c0000000-0000-4000-8000-000000000003', 6, '10:00', '11:00', public.gr_today() + 30);
update public.gr_memberships set left_on = public.gr_today() - 10 where group_id = 'c0000000-0000-4000-8000-000000000003';

select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select is(public.gr_dissolve_group('c0000000-0000-4000-8000-000000000003', public.gr_today() - 1) -> 'starts_after_dissolution',
  '[{"id": "c1000000-0000-4000-8000-0000000000ff", "kind": "training_time"}]'::jsonb,
  'später beginnende Trainingszeit bleibt und wird gemeldet (plan.md H5)');
select pg_temp.as_owner();
select is((select dissolved_on from public.gr_groups where id = 'c0000000-0000-4000-8000-000000000003'), public.gr_today() - 1,
  'aufgelöst am');
select is((select valid_to from public.ea_properties p
             where p.related_group_id = 'c0000000-0000-4000-8000-000000000003'), public.gr_today() - 1,
  'Funktion endet zum Auflösungsdatum (A12)');
select is((select valid_to from public.gr_training_times where id = 'c1000000-0000-4000-8000-000000000005'), date '2025-06-30',
  'Trainingszeit der Altgruppe unverändert');
select is((select count(*)::int from public.gr_training_times
             where group_id = 'c0000000-0000-4000-8000-000000000003' and valid_to = public.gr_today() - 1), 1,
  'offene Trainingszeit endet zum Auflösungsdatum (A12)');
select is((select valid_to from public.gr_training_times where id = 'c1000000-0000-4000-8000-0000000000ff'), null::date,
  'später beginnende Trainingszeit unverändert');

select * from finish();
rollback;
