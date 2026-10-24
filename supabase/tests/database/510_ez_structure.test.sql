-- Anwesenheitserfassung (spec.md EZ v0.5, T9 Teil; tasks.md T003): Typen, Tabellen, RLS, Grants, keine direkten
-- Schreibrechte, Rechtefunktionen je Testzugang, Check ez_events_shape je Einsatzart.
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
create function pg_temp.u(n int) returns uuid language sql as $$
  select ('b0000000-0000-4000-8000-' || lpad(n::text, 12, '0'))::uuid
$$;
create temp table refs as select id, name from public.ea_referate;
grant select on refs to authenticated;
create function pg_temp.referat(p_name text) returns uuid language sql as $$
  select id from refs where name = p_name
$$;

-- Typen
select enum_has_labels('public', 'ez_event_kind', array['training', 'day_trip', 'multi_day_trip', 'training_trip',
  'competition', 'work_assignment', 'course', 'tour', 'training_camp'], 'Einsatzarten');
select enum_has_labels('public', 'ez_span', array['single', 'multi'], 'eintägig/mehrtägig');
select enum_has_labels('public', 'ez_day_category', array['under_8h', 'at_least_8h'], 'Dauer');
select enum_has_labels('public', 'ez_role', array['trainer', 'helper', 'participant'], 'Rollen');
select enum_has_labels('public', 'ez_attendance_status', array['registered', 'present', 'absent'], 'Stände');

-- Tabellen mit RLS, nur select für authenticated, nichts für anon
select ok((select bool_and(c.relrowsecurity) from pg_class c
            where c.oid in ('public.ez_events'::regclass, 'public.ez_event_groups'::regclass,
                            'public.ez_attendances'::regclass, 'public.ez_trial_participants'::regclass,
                            'public.ez_privacy_confirmations'::regclass)), 'RLS auf allen ez_-Tabellen');
select ok((select bool_and(has_table_privilege('authenticated', t, 'SELECT')
                   and not has_table_privilege('authenticated', t, 'INSERT')
                   and not has_table_privilege('authenticated', t, 'UPDATE')
                   and not has_table_privilege('authenticated', t, 'DELETE')
                   and not has_table_privilege('anon', t, 'SELECT'))
             from unnest(array['public.ez_events', 'public.ez_event_groups', 'public.ez_attendances',
                               'public.ez_trial_participants', 'public.ez_privacy_confirmations', 'public.ez_v_events']) t),
  'authenticated nur select, anon nichts');
select is((select count(*)::int from pg_policies where schemaname = 'public' and tablename like 'ez\_%' and cmd <> 'SELECT'),
  0, 'keine Schreib-Policies');
select ok((select 'security_invoker=true' = any (c.reloptions) from pg_class c where c.oid = 'public.ez_v_events'::regclass),
  'ez_v_events mit security_invoker');

-- Funktionen: Grants
select ok(bool_and(has_function_privilege('authenticated', f, 'EXECUTE') and not has_function_privilege('anon', f, 'EXECUTE')),
  'öffentliche EZ-Funktionen nur für authenticated')
  from unnest(array['public.ez_can_read(uuid)', 'public.ez_can_write(uuid)', 'public.ez_can_delete()',
                    'public.ez_person_visible(uuid)', 'public.ez_save_event(jsonb, jsonb, jsonb, boolean)',
                    'public.ez_delete_event(uuid)', 'public.ez_cancel_event(uuid, text)', 'public.ez_restore_event(uuid)',
                    'public.ez_create_helper(uuid, text, text, text, text, boolean, text)',
                    'public.ez_reactivate_helper(uuid, uuid)',
                    'public.ez_list_events(date, date, uuid, uuid, ez_event_kind, integer, integer)',
                    'public.ez_get_event(uuid)', 'public.ez_climbing_points_report(uuid, date, date)']) f;
select ok(bool_and(not has_function_privilege('authenticated', f, 'EXECUTE')), 'interne EZ-Funktionen ohne Grant')
  from unnest(array['public.ez_my_person_id()', 'public.ez_roster(uuid[], date)', 'public.ez_load_event(uuid)',
                    'public.ez_check_helper_event(uuid)', 'public.ez_group_label(uuid, uuid)']) f;
select ok(bool_and(p.prosecdef and 'search_path=""' = any (p.proconfig)), 'alle EZ-Funktionen security definer, search_path leer')
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public' and p.proname like 'ez\_%';

-- Rechte je Testzugang (R13, R14; Startwerte AD v0.8)
select pg_temp.as_user(pg_temp.u(1));
select ok(public.ez_can_read(pg_temp.referat('Klettern')) and public.ez_can_read(pg_temp.referat('Kinder und Jugend'))
          and not public.ez_can_write(pg_temp.referat('Klettern')) and not public.ez_can_delete(), 'Admin: nur lesen, alle');
select pg_temp.as_user(pg_temp.u(2));
select ok(public.ez_can_read(pg_temp.referat('Touren')) and public.ez_can_write(pg_temp.referat('Touren'))
          and public.ez_can_delete(), 'Geschäftsstelle: verwalten, alle');
select pg_temp.as_user(pg_temp.u(9));
select ok(public.ez_can_read(pg_temp.referat('Klettern')) and public.ez_can_write(pg_temp.referat('Klettern'))
          and not public.ez_can_read(pg_temp.referat('Kinder und Jugend'))
          and not public.ez_can_write(pg_temp.referat('Kinder und Jugend')) and not public.ez_can_delete(),
  'Rita: lesen und schreiben nur im Referat Klettern, nicht löschen');
select ok(not public.ez_can_read(null) and not public.ez_can_write(null), 'Rita: Referat null nie');
select pg_temp.as_user(pg_temp.u(3));
select ok(not public.ez_can_read(pg_temp.referat('Klettern')) and not public.ez_can_write(pg_temp.referat('Klettern'))
          and not public.ez_can_delete(), 'Vorstand: nichts');
select pg_temp.as_owner();
select ok(not public.ez_can_read(pg_temp.referat('Klettern')), 'ohne Nutzerkontext: nichts');

-- Direkte Schreibversuche (Geschäftsstelle) werden abgelehnt
select pg_temp.as_user(pg_temp.u(2));
select throws_ok($$ insert into public.ez_events (kind, span, referat_id, title, start_date, day_category, client_request_id)
                    values ('work_assignment', 'single', pg_temp.referat('Klettern'), 'X', date '2026-10-01', 'under_8h',
                            gen_random_uuid()) $$,
  '42501', null, 'kein direkter Insert');
select throws_ok($$ delete from public.ez_attendances $$, '42501', null, 'kein direktes Delete');

-- Check ez_events_shape je Einsatzart (als Eigentümer mit Nutzerkontext Geschäftsstelle)
select pg_temp.as_owner();
select set_config('request.jwt.claims', json_build_object('sub', pg_temp.u(2), 'role', 'authenticated')::text, true);
create function pg_temp.ins(p jsonb) returns void language sql as $$
  insert into public.ez_events (kind, span, referat_id, group_id, title, organizer_person_id, start_date, start_time,
                                end_date, end_time, day_category, location_id, client_request_id)
  select (p ->> 'kind')::public.ez_event_kind, (p ->> 'span')::public.ez_span, pg_temp.referat('Klettern'),
         (p ->> 'group_id')::uuid, p ->> 'title', (p ->> 'organizer')::uuid, date '2026-10-13',
         (p ->> 'start_time')::time, (p ->> 'end_date')::date, null, (p ->> 'day')::public.ez_day_category,
         (p ->> 'location_id')::uuid, gen_random_uuid()
$$;

select lives_ok($$ select pg_temp.ins('{"kind": "training", "span": "single", "group_id": "c0000000-0000-4000-8000-000000000003",
  "location_id": "e1000000-0000-4000-8000-000000000001"}') $$, 'Training gültig');
select throws_ok($$ select pg_temp.ins('{"kind": "training", "span": "single", "group_id": "c0000000-0000-4000-8000-000000000003",
  "location_id": "e1000000-0000-4000-8000-000000000001", "title": "X"}') $$, '23514', null, 'Training ohne Titel');
select throws_ok($$ select pg_temp.ins('{"kind": "training", "span": "single", "group_id": "c0000000-0000-4000-8000-000000000003"}') $$,
  '23514', null, 'Training ohne Ort ungültig');
select lives_ok($$ select pg_temp.ins('{"kind": "day_trip", "span": "single", "group_id": "c0000000-0000-4000-8000-000000000003",
  "title": "Ausflug", "organizer": "a0000000-0000-4000-8000-000000000004", "day": "under_8h"}') $$, 'Tagesausflug gültig');
select throws_ok($$ select pg_temp.ins('{"kind": "day_trip", "span": "single", "group_id": "c0000000-0000-4000-8000-000000000003",
  "title": "Ausflug", "organizer": "a0000000-0000-4000-8000-000000000004", "day": "under_8h", "start_time": "08:00"}') $$,
  '23514', null, 'Tagesausflug ohne Uhrzeit (R3)');
select lives_ok($$ select pg_temp.ins('{"kind": "multi_day_trip", "span": "multi", "group_id": "c0000000-0000-4000-8000-000000000003",
  "title": "Fahrt", "organizer": "a0000000-0000-4000-8000-000000000004", "end_date": "2026-10-15"}') $$, 'Mehrtagesfahrt gültig');
select throws_ok($$ select pg_temp.ins('{"kind": "multi_day_trip", "span": "multi", "group_id": "c0000000-0000-4000-8000-000000000003",
  "title": "Fahrt", "organizer": "a0000000-0000-4000-8000-000000000004", "end_date": "2026-10-13"}') $$,
  '23514', null, 'Enddatum nach Startdatum (R2)');
select lives_ok($$ select pg_temp.ins('{"kind": "training_trip", "span": "single", "group_id": "c0000000-0000-4000-8000-000000000003",
  "title": "Ausbildung", "organizer": "a0000000-0000-4000-8000-000000000004", "day": "at_least_8h"}') $$, 'Ausbildungsfahrt gültig');
select lives_ok($$ select pg_temp.ins('{"kind": "competition", "span": "single", "group_id": "c0000000-0000-4000-8000-000000000003",
  "title": "Cup", "day": "under_8h"}') $$, 'Wettkampfbetreuung gültig');
select throws_ok($$ select pg_temp.ins('{"kind": "competition", "span": "single", "group_id": "c0000000-0000-4000-8000-000000000003",
  "title": "Cup", "day": "under_8h", "organizer": "a0000000-0000-4000-8000-000000000004"}') $$,
  '23514', null, 'Wettkampfbetreuung ohne organisierende Person');
select lives_ok($$ select pg_temp.ins('{"kind": "work_assignment", "span": "single", "title": "Aufbau", "day": "under_8h"}') $$,
  'Arbeitseinsatz gültig');
select throws_ok($$ select pg_temp.ins('{"kind": "work_assignment", "span": "single", "title": "Aufbau", "day": "under_8h",
  "group_id": "c0000000-0000-4000-8000-000000000003"}') $$, '23514', null, 'Arbeitseinsatz ohne Gruppe');
select lives_ok($$ select pg_temp.ins('{"kind": "training_camp", "span": "multi", "group_id": "c0000000-0000-4000-8000-000000000003",
  "title": "Lager", "organizer": "a0000000-0000-4000-8000-000000000004", "end_date": "2026-10-20"}') $$, 'Trainingslager gültig');
select throws_ok($$ select pg_temp.ins('{"kind": "training_camp", "span": "single", "group_id": "c0000000-0000-4000-8000-000000000003",
  "title": "Lager", "organizer": "a0000000-0000-4000-8000-000000000004", "day": "under_8h"}') $$,
  '23514', null, 'Trainingslager immer mehrtägig');
select lives_ok($$ select pg_temp.ins('{"kind": "course", "span": "single", "title": "Kurs",
  "organizer": "a0000000-0000-4000-8000-000000000004", "day": "at_least_8h"}') $$, 'Kurs gültig');
select throws_ok($$ select pg_temp.ins('{"kind": "tour", "span": "single", "title": "Tour", "day": "at_least_8h"}') $$,
  '23514', null, 'Tour mit organisierender Person');
select throws_ok($$ select pg_temp.ins('{"kind": "course", "span": "single", "title": "", "organizer": "a0000000-0000-4000-8000-000000000004",
  "day": "at_least_8h"}') $$, '23514', null, 'Titel nicht leer');

-- Audit und Sperre (R9, R19)
select is((select count(*)::int from public.ez_events where created_by = pg_temp.u(2)
            and created_by_person_id = 'a0000000-0000-4000-8000-000000000002'), 8, 'erfasst von über Trigger');
select is((select count(*)::int from public.ez_events e join public.gr_groups g on g.id = e.group_id
            where e.referat_id <> g.referat_id), 0, 'Referat aus der Gruppe');
select throws_ok($$ update public.ez_events set kind = 'training_trip' where kind = 'day_trip' $$,
  'P0001', 'EZ_FIELD_LOCKED', 'Einsatzart gesperrt (Trigger)');
select throws_ok($$ update public.ez_events set referat_id = pg_temp.referat('Touren') where kind = 'training' $$,
  'P0001', 'EZ_FIELD_LOCKED', 'Referat bei Einsatz mit Gruppe gesperrt');
select lives_ok($$ update public.ez_events set referat_id = pg_temp.referat('Touren') where kind = 'work_assignment' $$,
  'Referat bei Arbeitseinsatz änderbar');
select ok((select updated_by_person_id = 'a0000000-0000-4000-8000-000000000002' and updated_at is not null
             from public.ez_events where kind = 'work_assignment'), 'geändert von über Trigger');
select throws_ok($$ insert into public.ez_events (kind, span, referat_id, title, organizer_person_id, start_date, day_category,
                    client_request_id, tk_plan_id)
                    values ('work_assignment', 'single', pg_temp.referat('Klettern'), 'X', null, date '2026-10-01',
                            'under_8h', gen_random_uuid(), gen_random_uuid()) $$,
  '23514', null, 'tk_plan_id nur bei Kurs und Tour');

select * from finish();
rollback;
