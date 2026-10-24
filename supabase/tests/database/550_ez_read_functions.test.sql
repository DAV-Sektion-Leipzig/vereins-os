-- Anwesenheitserfassung (spec.md EZ v0.5, T9 Teil; tasks.md T007): ez_list_events, ez_get_event,
-- ez_climbing_points_report (US-EZ-14, -15, -16).
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
create function pg_temp.p(n int) returns uuid language sql as $$
  select ('a0000000-0000-4000-8000-' || lpad(n::text, 12, '0'))::uuid
$$;
create function pg_temp.u(n int) returns uuid language sql as $$
  select ('b0000000-0000-4000-8000-' || lpad(n::text, 12, '0'))::uuid
$$;
create function pg_temp.e(n int) returns uuid language sql as $$
  select ('f0000000-0000-4000-8000-' || lpad(n::text, 12, '0'))::uuid
$$;
create temp table refs as select id, name from public.ea_referate;
grant select on refs to authenticated;
create function pg_temp.referat(p_name text) returns uuid language sql as $$
  select id from refs where name = p_name
$$;

-- Testdaten nach spec.md EZ 9 in der Transaktion (plan.md O3 a; gleiche UUIDs wie der EZ-Seed, on conflict do nothing).
-- „Gruppe Test Klettern“ = Klettergruppe Test (c…03), „Gruppe Test Jugend“ = Jugendgruppe Test 1 (c…01).
-- Als Eigentümer mit Nutzerkontext Geschäftsstelle (erfasst von).
select set_config('request.jwt.claims', json_build_object('sub', 'b0000000-0000-4000-8000-000000000002', 'role', 'authenticated')::text, true);

insert into public.ea_persons (id, first_name, last_name, kind, created_in, volunteer_status, volunteer_status_since) values
  ('a0000000-0000-4000-8000-000000000033', 'Ella', 'Klettertest', 'human', 'GR', null, null),
  ('a0000000-0000-4000-8000-000000000034', 'Finn', 'Klettertest', 'human', 'GR', null, null),
  ('a0000000-0000-4000-8000-000000000035', 'Ida', 'Klettertest', 'human', 'GR', null, null),
  ('a0000000-0000-4000-8000-000000000036', 'Jonas', 'Klettertest', 'human', 'GR', null, null),
  ('a0000000-0000-4000-8000-000000000037', 'Lotta', 'Klettertest', 'human', 'GR', null, null),
  ('a0000000-0000-4000-8000-000000000038', 'Noah', 'Klettertest', 'human', 'GR', null, null),
  ('a0000000-0000-4000-8000-000000000039', 'Mila', 'Späteintritt', 'human', 'GR', null, null),
  ('a0000000-0000-4000-8000-000000000040', 'Hanna', 'Helferin', 'human', 'GR', 'active', date '2025-09-01'),
  ('a0000000-0000-4000-8000-000000000041', 'Clara', 'Jugendtest', 'human', 'GR', null, null),
  ('a0000000-0000-4000-8000-000000000042', 'David', 'Jugendtest', 'human', 'GR', null, null),
  ('a0000000-0000-4000-8000-000000000043', 'Emil', 'Jugendtest', 'human', 'GR', null, null),
  ('a0000000-0000-4000-8000-000000000044', 'Frida', 'Jugendtest', 'human', 'GR', null, null),
  ('a0000000-0000-4000-8000-000000000045', 'Hugo', 'Jugendtest', 'human', 'GR', null, null),
  ('a0000000-0000-4000-8000-000000000046', 'Ina', 'Jugendtest', 'human', 'GR', null, null),
  ('a0000000-0000-4000-8000-000000000047', 'Jan', 'Jugendtest', 'human', 'GR', null, null),
  ('a0000000-0000-4000-8000-000000000048', 'Kai', 'Jugendtest', 'human', 'GR', null, null),
  ('a0000000-0000-4000-8000-000000000049', 'Jule', 'Jugendtrainerin', 'human', 'GR', 'active', date '2025-09-01')
on conflict (id) do nothing;

insert into public.gr_memberships (id, group_id, person_id, joined_on, left_on)
select ('f3000000-0000-4000-8000-0000000000' || right(p.n::text, 2))::uuid,
       case when p.n < 41 then 'c0000000-0000-4000-8000-000000000003' else 'c0000000-0000-4000-8000-000000000001' end::uuid,
       ('a0000000-0000-4000-8000-0000000000' || p.n)::uuid,
       case when p.n = 39 then date '2026-09-01' else date '2025-09-01' end, null::date
  from generate_series(33, 48) as p (n)
 where p.n not in (40)
on conflict (id) do nothing;

insert into public.ea_properties (id, person_id, property_type_id, field_values, related_group_id, valid_from)
select v.id, v.person_id, t.id, v.field_values, v.group_id, date '2025-09-01'
  from (values
    ('f4000000-0000-4000-8000-000000000001'::uuid, 'a0000000-0000-4000-8000-000000000004'::uuid,
     '{"function": "Trainer:in"}'::jsonb, 'c0000000-0000-4000-8000-000000000003'::uuid),
    ('f4000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000009',
     '{"function": "Trainer:in"}', 'c0000000-0000-4000-8000-000000000003'),
    ('f4000000-0000-4000-8000-000000000003', 'a0000000-0000-4000-8000-000000000040',
     '{"function": "Helfer:in"}', 'c0000000-0000-4000-8000-000000000003'),
    ('f4000000-0000-4000-8000-000000000004', 'a0000000-0000-4000-8000-000000000049',
     '{"function": "Trainer:in"}', 'c0000000-0000-4000-8000-000000000001')
  ) as v (id, person_id, field_values, group_id)
  join public.ea_property_types t on t.system_key = 'group_function'
on conflict (id) do nothing;

insert into public.gr_training_times (id, group_id, weekday, starts_at, ends_at, valid_from, valid_to) values
  ('f5000000-0000-4000-8000-000000000001', 'c0000000-0000-4000-8000-000000000003', 2, '17:00', '19:00', date '2025-09-01', null)
on conflict (id) do nothing;

insert into public.ez_events (id, kind, span, referat_id, group_id, title, organizer_person_id, start_date, start_time,
                              end_date, end_time, day_category, location_id, client_request_id, cancelled_at,
                              cancelled_by, cancelled_by_person_id, cancel_reason)
select v.id, v.kind::public.ez_event_kind, v.span::public.ez_span, r.id, v.group_id, v.title, v.organizer, v.start_date,
       v.start_time, v.end_date, v.end_time, v.day::public.ez_day_category, v.location_id,
       ('f6000000-0000-4000-8000-0000000000' || right(v.id::text, 2))::uuid,
       v.cancelled_at, case when v.cancelled_at is not null then 'b0000000-0000-4000-8000-000000000002'::uuid end,
       case when v.cancelled_at is not null then 'a0000000-0000-4000-8000-000000000002'::uuid end, v.reason
  from (values
    ('f0000000-0000-4000-8000-000000000001'::uuid, 'training', 'single', 'Klettern',
     'c0000000-0000-4000-8000-000000000003'::uuid, null::text, null::uuid, date '2026-10-13', null::time, null::date, null::time,
     null::text, 'e1000000-0000-4000-8000-000000000001'::uuid, null::timestamptz, null::text),
    ('f0000000-0000-4000-8000-000000000002', 'training', 'single', 'Klettern',
     'c0000000-0000-4000-8000-000000000003', null, null, date '2026-10-20', null, null, null,
     null, 'e1000000-0000-4000-8000-000000000001', null, null),
    ('f0000000-0000-4000-8000-000000000003', 'training', 'single', 'Kinder und Jugend',
     'c0000000-0000-4000-8000-000000000001', null, null, date '2026-10-14', null, null, null,
     null, 'e1000000-0000-4000-8000-000000000002', null, null),
    ('f0000000-0000-4000-8000-000000000004', 'day_trip', 'single', 'Klettern',
     'c0000000-0000-4000-8000-000000000003', 'Boulderfelsen', 'a0000000-0000-4000-8000-000000000004', date '2026-10-03',
     null, null, null, 'at_least_8h', null, null, null),
    ('f0000000-0000-4000-8000-000000000005', 'multi_day_trip', 'multi', 'Kinder und Jugend',
     'c0000000-0000-4000-8000-000000000001', 'Elbsandstein', 'a0000000-0000-4000-8000-000000000010', date '2026-11-07',
     '16:00', date '2026-11-09', '18:30', null, null, null, null),
    ('f0000000-0000-4000-8000-000000000006', 'competition', 'single', 'Klettern',
     'c0000000-0000-4000-8000-000000000003', 'Jugendcup Test', null, date '2026-10-24', null, null, null,
     'under_8h', null, null, null),
    ('f0000000-0000-4000-8000-000000000007', 'work_assignment', 'single', 'Klettern',
     null, 'Aufbau Test-Cup', null, date '2026-10-17', null, null, null, 'at_least_8h', null, null, null),
    ('f0000000-0000-4000-8000-000000000008', 'training_trip', 'multi', 'Klettern',
     'c0000000-0000-4000-8000-000000000003', 'Alpinfahrt Test', 'a0000000-0000-4000-8000-000000000004', date '2026-08-01',
     '08:00', date '2026-08-08', '20:00', null, null, null, null),
    ('f0000000-0000-4000-8000-000000000009', 'course', 'single', 'Klettern',
     null, 'Toprope-Kurs Test', 'a0000000-0000-4000-8000-000000000004', date '2026-11-21', null, null, null,
     'at_least_8h', null, null, null),
    ('f0000000-0000-4000-8000-000000000010', 'training_camp', 'multi', 'Klettern',
     'c0000000-0000-4000-8000-000000000003', 'Frankenjura Test', 'a0000000-0000-4000-8000-000000000004', date '2026-12-28',
     '09:00', date '2027-01-02', '17:00', null, null, null, null),
    ('f0000000-0000-4000-8000-000000000011', 'day_trip', 'single', 'Klettern',
     'c0000000-0000-4000-8000-000000000003', 'Sächsische Schweiz Test', 'a0000000-0000-4000-8000-000000000004',
     date '2026-10-10', null, null, null, 'under_8h', null, timestamptz '2026-10-08 18:00+02', 'Wetter')
  ) as v (id, kind, span, referat, group_id, title, organizer, start_date, start_time, end_date, end_time, day,
          location_id, cancelled_at, reason)
  join public.ea_referate r on r.name = v.referat
on conflict (id) do nothing;

insert into public.ez_attendances (event_id, person_id, role, status, is_substitute)
select ('f0000000-0000-4000-8000-0000000000' || lpad(v.e::text, 2, '0'))::uuid,
       ('a0000000-0000-4000-8000-0000000000' || lpad(v.p::text, 2, '0'))::uuid,
       v.role::public.ez_role, v.status::public.ez_attendance_status, v.sub
  from (
    -- 1: Toni Trainer:in, 5 Teilnehmer:innen
    select 1 as e, 4 as p, 'trainer' as role, 'present' as status, false as sub
    union all select 1, n, 'participant', 'present', false from generate_series(33, 37) n
    -- 2: Karl Helfer:in (Vertretung), 4 Teilnehmer:innen
    union all select 2, 10, 'helper', 'present', true
    union all select 2, n, 'participant', 'present', false from generate_series(33, 36) n
    -- 3: Lars Trainer:in, 3 Teilnehmer:innen (Referat Kinder und Jugend)
    union all select 3, 26, 'trainer', 'present', false
    union all select 3, n, 'participant', 'present', false from generate_series(41, 43) n
    -- 4: 2 Trainer:innen, 6 Teilnehmer:innen
    union all select 4, 4, 'trainer', 'present', false
    union all select 4, 9, 'trainer', 'present', false
    union all select 4, n, 'participant', 'present', false from generate_series(33, 38) n
    -- 5: 2 Trainer:innen, 8 Teilnehmer:innen (Referat Kinder und Jugend)
    union all select 5, 26, 'trainer', 'present', false
    union all select 5, 49, 'trainer', 'present', false
    union all select 5, n, 'participant', 'present', false from generate_series(41, 48) n
    -- 6: 1 Trainer:in, 3 Teilnehmer:innen
    union all select 6, 9, 'trainer', 'present', false
    union all select 6, n, 'participant', 'present', false from generate_series(33, 35) n
    -- 7: 3 eingetragen, 2 anwesend, 1 nicht erschienen
    union all select 7, n, 'helper', 'registered', false from generate_series(19, 21) n
    union all select 7, 22, 'helper', 'present', false
    union all select 7, 4, 'helper', 'present', false
    union all select 7, 10, 'helper', 'absent', false
    -- 8: 1 Trainer:in, 1 Helfer:in, 4 Teilnehmer:innen
    union all select 8, 4, 'trainer', 'present', false
    union all select 8, 40, 'helper', 'present', false
    union all select 8, n, 'participant', 'present', false from generate_series(33, 36) n
    -- 9: Kurs, eingetragen
    union all select 9, 4, 'trainer', 'registered', false
    union all select 9, 10, 'helper', 'registered', false
    -- 10: 1 Trainer:in, 5 Teilnehmer:innen
    union all select 10, 4, 'trainer', 'present', false
    union all select 10, n, 'participant', 'present', false from generate_series(33, 37) n
  ) v
on conflict (event_id, person_id) do nothing;

insert into public.ez_trial_participants (id, event_id, first_name) values
  ('f2000000-0000-4000-8000-000000000001', 'f0000000-0000-4000-8000-000000000001', 'Lena')
on conflict (id) do nothing;

select set_config('request.jwt.claims', '', true);

-- Fehlercode und Detail eines Aufrufs als Text („ok“ ohne Fehler)
create function pg_temp.err(p_sql text) returns text language plpgsql as $$
declare
  v_msg text;
  v_detail text;
begin
  execute p_sql;
  return 'ok';
exception when others then
  get stacked diagnostics v_msg = message_text, v_detail = pg_exception_detail;
  return v_msg || coalesce(':' || nullif(v_detail, ''), '');
end $$;
create function pg_temp.save(p_event jsonb, p_att jsonb, p_trials jsonb default '[]', p_confirm boolean default false)
returns text language sql as $$
  select pg_temp.err(format('select public.ez_save_event(%L::jsonb, %L::jsonb, %L::jsonb, %L)',
                            jsonb_build_object('client_request_id', gen_random_uuid()) || p_event, p_att, p_trials, p_confirm))
$$;
-- Anwesenheiten: Betreuer:innen mit Rolle, Teilnehmer:innen
create function pg_temp.att(p_staff int[], p_participants int[], p_role text default 'trainer', p_status text default 'present')
returns jsonb language sql as $$
  select coalesce(jsonb_agg(x), '[]') from (
    select jsonb_build_object('person_id', pg_temp.p(n), 'role', p_role, 'status', p_status) as x from unnest(p_staff) n
    union all
    select jsonb_build_object('person_id', pg_temp.p(n), 'role', 'participant', 'status', p_status) from unnest(p_participants) n
  ) s
$$;
-- Training der Klettergruppe Test an einem Datum
create function pg_temp.tr(p_date text) returns jsonb language sql as $$
  select jsonb_build_object('kind', 'training', 'group_id', 'c0000000-0000-4000-8000-000000000003',
                            'start_date', p_date, 'location_id', 'e1000000-0000-4000-8000-000000000001')
$$;
create function pg_temp.trip(p_kind text, p_date text) returns jsonb language sql as $$
  select jsonb_build_object('kind', p_kind, 'group_id', 'c0000000-0000-4000-8000-000000000003', 'start_date', p_date,
                            'title', 'Fahrt Test', 'organizer_person_id', pg_temp.p(4), 'day_category', 'under_8h', 'span', 'single')
$$;
create function pg_temp.wa(p_referat text, p_date text) returns jsonb language sql as $$
  select jsonb_build_object('kind', 'work_assignment', 'referat_id', pg_temp.referat(p_referat), 'start_date', p_date,
                            'title', 'Arbeitseinsatz Test', 'day_category', 'under_8h', 'span', 'single')
$$;

create function pg_temp.ids(p_rows text) returns int[] language plpgsql as $$
declare
  v int[];
begin
  execute format('select coalesce(array_agg(right(id::text, 2)::int order by ord), ''{}'') from (select id, row_number() over () as ord from (%s) q) s', p_rows)
    into v;
  return v;
end $$;

-- ez_list_events: Sortierung und Filter
select pg_temp.as_user(pg_temp.u(9));
select is(pg_temp.ids($$ select id from public.ez_list_events(date '2026-10-01', date '2026-10-31') $$),
  array[6, 2, 7, 1, 11, 4], 'Rita: Oktober 2026 nach Datum absteigend, mit abgesagtem Einsatz');
select pg_temp.as_user(pg_temp.u(2));
select is(pg_temp.ids(format('select id from public.ez_list_events(null, null, p_referat => %L)', pg_temp.referat('Kinder und Jugend'))),
  array[5, 3], 'Filter Referat');
select is(pg_temp.ids($$ select id from public.ez_list_events(null, null, p_group => 'c0000000-0000-4000-8000-000000000001') $$),
  array[5, 3], 'Filter Gruppe');
select is(pg_temp.ids($$ select id from public.ez_list_events(null, null, p_kind => 'training') $$),
  array[2, 3, 1], 'Filter Einsatzart');
select results_eq($$ select count(*)::int, max(total_count)::int from public.ez_list_events(null, null, p_limit => 2) $$,
  $$ values (2, 11) $$, 'Seite mit 2 Zeilen, total_count 11');
select is((select count(*)::int from public.ez_list_events(null, null, p_limit => 0)), 1, 'p_limit mindestens 1');
select is(pg_temp.ids($$ select id from public.ez_list_events(null, null, p_limit => 2, p_offset => 2) $$), array[5, 6], 'Offset');
select results_eq($$ select group_name, location_name, present_trainer, present_helper, present_participant, trial_count,
                            registered_count, absent_count
                       from public.ez_list_events(date '2026-10-13', date '2026-10-13') $$,
  $$ values ('Klettergruppe Test'::text, 'Kletterhalle Test'::text, 1, 0, 5, 1, 0, 0) $$, 'Einsatz 1: Zähler je Rolle, Probetraining');
select results_eq($$ select group_name, present_helper, registered_count, absent_count, referat_name
                       from public.ez_list_events(date '2026-10-17', date '2026-10-17') $$,
  $$ values (null::text, 2, 3, 1, 'Klettern'::text) $$, 'Einsatz 7: Stände');
select results_eq($$ select is_cancelled, cancel_reason from public.ez_list_events(date '2026-10-10', date '2026-10-10') $$,
  $$ values (true, 'Wetter'::text) $$, 'Einsatz 11 abgesagt');

-- ez_get_event
select pg_temp.as_user(pg_temp.u(9));
select results_eq(format($$ select x -> 'groups' -> 0 ->> 'name', x ->> 'location_name', x ->> 'referat_name',
                                  jsonb_array_length(x -> 'attendances'), jsonb_array_length(x -> 'trials'),
                                  (x ->> 'can_write')::boolean, (x ->> 'can_delete')::boolean,
                                  (x -> 'event' ->> 'is_cancelled')::boolean, (x -> 'event' ->> 'from_planning')::boolean
                             from public.ez_get_event(%L) x $$, pg_temp.e(1)),
  $$ values ('Klettergruppe Test'::text, 'Kletterhalle Test'::text, 'Klettern'::text, 6, 1, true, false, false, false) $$,
  'Rita: Einsatz 1 mit Gruppe, Ort, Anwesenheit, Probetraining, schreiben ja, löschen nein');
select ok((select bool_and((a ->> 'is_substitute')::boolean = ((a ->> 'person_id')::uuid = pg_temp.p(10)))
             from jsonb_array_elements(public.ez_get_event(pg_temp.e(2)) -> 'attendances') a), 'Einsatz 2: Karl als Vertretung');
select is(pg_temp.err(format('select public.ez_get_event(%L)', pg_temp.e(3))), 'EZ_NOT_FOUND', 'Rita: Einsatz 3 nicht gefunden');
select is(pg_temp.err(format('select public.ez_get_event(%L)', gen_random_uuid())), 'EZ_NOT_FOUND', 'unbekannter Einsatz');
select pg_temp.as_user(pg_temp.u(1));
select ok(not (public.ez_get_event(pg_temp.e(1)) ->> 'can_write')::boolean, 'Admin: nur lesen');
select pg_temp.as_user(pg_temp.u(2));
select ok((public.ez_get_event(pg_temp.e(1)) ->> 'can_delete')::boolean, 'Geschäftsstelle: löschen');
select is(public.ez_get_event(pg_temp.e(11)) -> 'event' ->> 'cancel_reason', 'Wetter', 'Absage mit Grund');
select pg_temp.as_user(pg_temp.u(3));
select is(pg_temp.err(format('select public.ez_get_event(%L)', pg_temp.e(1))), 'EZ_NOT_FOUND', 'Vorstand: nicht gefunden');

-- Kontrollliste Kletterhalle (US-EZ-16): abgesagtes Training zählt nicht (R22)
select pg_temp.as_owner();
select set_config('request.jwt.claims', json_build_object('sub', pg_temp.u(2), 'role', 'authenticated')::text, true);
insert into public.ez_events (kind, span, referat_id, group_id, start_date, location_id, client_request_id, cancelled_at,
                              cancel_reason)
values ('training', 'single', pg_temp.referat('Klettern'), 'c0000000-0000-4000-8000-000000000003', date '2026-10-27',
        'e1000000-0000-4000-8000-000000000001', gen_random_uuid(), now(), 'Halle gesperrt');
select pg_temp.as_user(pg_temp.u(9));
select results_eq($$ select start_date, group_name, participants_present, trial_count
                       from public.ez_climbing_points_report('e1000000-0000-4000-8000-000000000001', date '2026-10-01', date '2026-10-31') $$,
  $$ values (date '2026-10-13', 'Klettergruppe Test'::text, 5, 1), (date '2026-10-20', 'Klettergruppe Test', 4, 0) $$,
  'Kontrollliste Oktober 2026: 2 Zeilen, 5/1 und 4/0');
select is(pg_temp.err($$ select * from public.ez_climbing_points_report('e1000000-0000-4000-8000-000000000002', null, null) $$),
  'EZ_LOCATION_NO_POINTS', 'Ort ohne Punktekonto');
select pg_temp.as_user(pg_temp.u(3));
select is_empty($$ select 1 from public.ez_climbing_points_report('e1000000-0000-4000-8000-000000000001', null, null) $$,
  'Vorstand: leer');

select * from finish();
rollback;
