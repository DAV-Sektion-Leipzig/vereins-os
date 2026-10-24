-- Anwesenheitserfassung (spec.md EZ v0.5, T9 Teil; tasks.md T006): Löschen (R15), Absagen und Rücknahme (R22–R24),
-- neue Helfer:innen mit Bestätigung (R29), wieder aktiv eintragen (R31), Einsätze aus der Planungshilfe (R25).
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

-- Kopf eines Einsatzes als Eingabe für ez_save_event (unverändert)
create function pg_temp.head(p_id uuid) returns jsonb language sql as $$
  select jsonb_build_object('id', e.id, 'kind', e.kind, 'referat_id', e.referat_id, 'group_id', e.group_id, 'title', e.title,
                            'organizer_person_id', e.organizer_person_id, 'start_date', e.start_date, 'span', e.span,
                            'start_time', e.start_time, 'end_date', e.end_date, 'end_time', e.end_time,
                            'day_category', e.day_category, 'location_id', e.location_id, 'remark', e.remark)
    from public.ez_events e where e.id = p_id
$$;

-- Löschen (R15)
select pg_temp.as_user(pg_temp.u(9));
select is(pg_temp.err(format('select public.ez_delete_event(%L)', pg_temp.e(7))), 'EZ_DELETE_FORBIDDEN', 'R15 Rita darf nicht löschen');
select pg_temp.as_user(pg_temp.u(3));
select is(pg_temp.err(format('select public.ez_delete_event(%L)', pg_temp.e(7))), 'EZ_NOT_FOUND', 'Vorstand: nicht gefunden');
select pg_temp.as_user(pg_temp.u(2));
select is(pg_temp.err(format('select public.ez_delete_event(%L)', pg_temp.e(4))), 'ok', 'R15 Geschäftsstelle löscht');
select pg_temp.as_owner();
select is((select count(*)::int from public.ez_attendances where event_id = pg_temp.e(4)), 0, 'Anwesenheiten mitgelöscht');
select ok(exists (select 1 from public.ea_persons where id = pg_temp.p(38)), 'Personen bleiben');
select pg_temp.as_user(pg_temp.u(2));
select is(pg_temp.err(format('select public.ez_delete_event(%L)', pg_temp.e(11))), 'ok', 'abgesagter Einsatz löschbar');

-- Absagen (R22, R23)
select pg_temp.as_user(pg_temp.u(9));
select is(pg_temp.err(format('select public.ez_cancel_event(%L, %L)', pg_temp.e(9), '  ')), 'EZ_CANCEL_REASON', 'R23 Grund leer');
select is(pg_temp.err(format('select public.ez_cancel_event(%L, %L)', pg_temp.e(9), repeat('x', 501))), 'EZ_CANCEL_REASON',
  'R23 Grund höchstens 500 Zeichen');
select is(pg_temp.err(format('select public.ez_cancel_event(%L, %L)', pg_temp.e(1), 'Krank')), 'EZ_CANCEL_NOT_ALLOWED',
  'R23 nicht mit anwesenden Personen');
select pg_temp.as_user(pg_temp.u(1));
select is(pg_temp.err(format('select public.ez_cancel_event(%L, %L)', pg_temp.e(9), 'Wetter')), 'EZ_FORBIDDEN', 'R14 Admin');
select pg_temp.as_user(pg_temp.u(9));
select is(pg_temp.err(format('select public.ez_cancel_event(%L, %L)', pg_temp.e(9), ' Zu wenig Anmeldungen ')), 'ok', 'Kurs abgesagt');
select ok((select cancelled_at is not null and cancel_reason = 'Zu wenig Anmeldungen' and cancelled_by = pg_temp.u(9)
                  and cancelled_by_person_id = pg_temp.p(9) and updated_by_person_id = pg_temp.p(9)
             from public.ez_events where id = pg_temp.e(9)), 'abgesagt am/von, Grund getrimmt');
select is((select count(*)::int from public.ez_attendances where event_id = pg_temp.e(9)), 2, 'eingetragene Personen bleiben');
select is(pg_temp.err(format('select public.ez_cancel_event(%L, %L)', pg_temp.e(9), 'nochmal')), 'EZ_EVENT_CANCELLED',
  'schon abgesagt');
select is(pg_temp.err(format('select public.ez_save_event(%L::jsonb, %L::jsonb, %L::jsonb)', pg_temp.head(pg_temp.e(9)), '[]', '[]')),
  'EZ_EVENT_CANCELLED', 'R22 abgesagter Einsatz nicht änderbar');
select ok((select is_cancelled from public.ez_list_events(date '2026-11-21', date '2026-11-21')), 'R22 in der Liste mit Kennzeichen');

-- Absage zurücknehmen (R24)
select is(pg_temp.err(format('select public.ez_restore_event(%L)', pg_temp.e(9))), 'ok', 'R24 Absage zurückgenommen');
select ok((select cancelled_at is null and cancelled_by is null and cancelled_by_person_id is null and cancel_reason is null
             from public.ez_events where id = pg_temp.e(9)), 'Absage geleert');
select is(pg_temp.err(format('select public.ez_restore_event(%L)', pg_temp.e(9))), 'ok', 'ohne Absage ohne Wirkung');
select is(pg_temp.err(format('select public.ez_save_event(%L::jsonb, %L::jsonb, %L::jsonb)', pg_temp.head(pg_temp.e(9)),
  pg_temp.att('{4}', '{}', 'trainer', 'present'), '[]')), 'ok', 'nach Rücknahme wieder änderbar');

-- Neue Person beim Arbeitseinsatz (R29)
select is(pg_temp.err(format('select public.ez_create_helper(%L, %L, %L)', pg_temp.e(7), 'Neue', 'Helferin')),
  'EZ_PRIVACY_NOT_CONFIRMED', 'R29 ohne Häkchen');
select is(pg_temp.err(format('select public.ez_create_helper(%L, %L, %L, p_privacy_confirmed => true, p_notice_version => %L)',
  pg_temp.e(7), 'Neue', 'Helferin', ' ')), 'EZ_PRIVACY_NOT_CONFIRMED', 'R29 ohne Version der Datenschutzhinweise');
select is((select count(*) from public.ea_persons where last_name = 'Helferin' and first_name = 'Neue'), 0::bigint,
  'R29 ohne Häkchen wird nichts angelegt');
select is(pg_temp.err(format('select public.ez_create_helper(%L, %L, %L, p_privacy_confirmed => true, p_notice_version => %L)',
  pg_temp.e(1), 'Neue', 'Helferin', 'test')), 'EZ_KIND_NOT_ALLOWED', 'nur beim Arbeitseinsatz');
create temp table neu (id uuid);
grant all on neu to authenticated;
insert into neu select public.ez_create_helper(pg_temp.e(7), ' Neue ', 'Helferin', 'Nele', 'neue.helferin@example.test',
                                               true, 'test-2026-10');
select pg_temp.as_owner();
select ok((select volunteer_status = 'active' and volunteer_status_since = date '2026-10-17' and created_in = 'EA'
                  and first_name = 'Neue' and preferred_name = 'Nele'
             from public.ea_persons where id = (select id from neu)), 'Person aktiv seit Einsatzdatum (Rita über den EA-Weg)');
select ok(exists (select 1 from public.ea_properties p join public.ea_property_types t on t.id = p.property_type_id
                   where p.person_id = (select id from neu) and t.system_key = 'function'
                     and p.field_values = '{"function": "Helfer:in"}' and p.related_referat_id = pg_temp.referat('Klettern')
                     and p.valid_from = date '2026-10-17'), 'Funktion Helfer:in im Referat des Einsatzes');
select ok(exists (select 1 from public.ez_attendances where event_id = pg_temp.e(7) and person_id = (select id from neu)
                    and role = 'helper' and status = 'present'), 'Anwesenheit angelegt');
select ok(exists (select 1 from public.ez_privacy_confirmations where person_id = (select id from neu) and event_id = pg_temp.e(7)
                    and notice_version = 'test-2026-10' and confirmed_by = pg_temp.u(9)
                    and confirmed_by_person_id = pg_temp.p(9)), 'Bestätigung gespeichert');
select pg_temp.as_user(pg_temp.u(9));
select is((select count(*)::int from public.ez_privacy_confirmations), 0, 'Rita liest Bestätigungen nicht');
select pg_temp.as_user(pg_temp.u(2));
select is((select count(*)::int from public.ez_privacy_confirmations), 1, 'Geschäftsstelle liest Bestätigungen');

-- Abgesagter Arbeitseinsatz
create temp table wa (id uuid);
grant all on wa to authenticated;
insert into wa select public.ez_save_event(jsonb_build_object('client_request_id', gen_random_uuid(), 'kind', 'work_assignment',
  'referat_id', pg_temp.referat('Klettern'), 'title', 'Abbau Test', 'start_date', '2026-11-14', 'span', 'single',
  'day_category', 'under_8h'), '[]', '[]');
select public.ez_cancel_event((select id from wa), 'verschoben');
select is(pg_temp.err(format('select public.ez_create_helper(%L, %L, %L, p_privacy_confirmed => true, p_notice_version => %L)',
  (select id from wa), 'Neue', 'Helferin', 'test')), 'EZ_EVENT_CANCELLED', 'nicht bei abgesagtem Einsatz');

-- Wieder aktiv eintragen (R31)
select pg_temp.as_user(pg_temp.u(9));
select is(pg_temp.err(format('select public.ez_reactivate_helper(%L, %L)', pg_temp.e(7), pg_temp.p(4))), 'EZ_PERSON_NOT_INACTIVE',
  'R31 aktive Person');
select is(pg_temp.err(format('select public.ez_reactivate_helper(%L, %L)', pg_temp.e(1), pg_temp.p(5))), 'EZ_KIND_NOT_ALLOWED',
  'R31 nur beim Arbeitseinsatz');
select is(pg_temp.err(format('select public.ez_reactivate_helper(%L, %L)', pg_temp.e(7), pg_temp.p(5))), 'ok', 'R31 ruhend');
select is(pg_temp.err(format('select public.ez_reactivate_helper(%L, %L)', pg_temp.e(7), pg_temp.p(11))), 'ok', 'R31 ausgeschieden');
select is(pg_temp.err(format('select public.ez_reactivate_helper(%L, %L)', pg_temp.e(7), pg_temp.p(33))), 'ok',
  'R31 ohne Ehrenamtsstatus');
select pg_temp.as_owner();
select ok((select bool_and(volunteer_status = 'active' and volunteer_status_since = date '2026-10-17')
             from public.ea_persons where id in (pg_temp.p(5), pg_temp.p(11), pg_temp.p(33))), 'R31 aktiv seit Einsatzdatum');
select is((select count(*)::int from public.ea_volunteer_status_history
            where person_id in (pg_temp.p(5), pg_temp.p(11), pg_temp.p(33)) and status = 'active' and valid_from = date '2026-10-17'),
  3, 'R31 mit Historie');
select is((select count(*)::int from public.ez_attendances where event_id = pg_temp.e(7)
            and person_id in (pg_temp.p(5), pg_temp.p(11), pg_temp.p(33)) and role = 'helper' and status = 'present'), 3,
  'R31 Anwesenheit Helfer:in');
update public.ea_persons set volunteer_status = 'dormant', volunteer_status_since = date '2026-10-20' where id = pg_temp.p(19);
select pg_temp.as_user(pg_temp.u(9));
select is(pg_temp.err(format('select public.ez_reactivate_helper(%L, %L)', pg_temp.e(7), pg_temp.p(19))),
  'EZ_DUPLICATE_PERSON:' || pg_temp.p(19), 'R31 schon eingetragen');

-- Einsätze aus der Planungshilfe (R25): tk_plan_id im Test gesetzt
select pg_temp.as_owner();
select set_config('request.jwt.claims', json_build_object('sub', pg_temp.u(2), 'role', 'authenticated')::text, true);
insert into public.ez_events (id, kind, span, referat_id, title, organizer_person_id, start_date, day_category, client_request_id,
                              tk_plan_id)
values ('f0000000-0000-4000-8000-000000000099', 'tour', 'single', pg_temp.referat('Klettern'), 'Tour aus der Planung',
        pg_temp.p(4), date '2026-11-29', 'at_least_8h', gen_random_uuid(), gen_random_uuid());
insert into public.ez_attendances (event_id, person_id, role, status, from_plan)
values (pg_temp.e(99), pg_temp.p(4), 'trainer', 'registered', true);
select pg_temp.as_user(pg_temp.u(9));
select is(pg_temp.err(format('select public.ez_save_event(%L::jsonb, %L::jsonb, %L::jsonb)',
  pg_temp.head(pg_temp.e(99)) || '{"remark": "Treffpunkt Parkplatz"}',
  '[{"person_id": "a0000000-0000-4000-8000-000000000004", "role": "trainer", "status": "present"},
    {"person_id": "a0000000-0000-4000-8000-000000000010", "role": "helper", "status": "present"}]', '[]')), 'ok',
  'R25 Bemerkung, Stand und weitere Personen änderbar');
select ok((select from_plan from public.ez_attendances where event_id = pg_temp.e(99) and person_id = pg_temp.p(4)),
  'R25 Person aus der Planung bleibt gekennzeichnet');
select is(pg_temp.err(format('select public.ez_save_event(%L::jsonb, %L::jsonb, %L::jsonb)',
  pg_temp.head(pg_temp.e(99)) || '{"title": "Andere Tour"}',
  '[{"person_id": "a0000000-0000-4000-8000-000000000004", "role": "trainer", "status": "present"}]', '[]')),
  'EZ_TK_MANAGED', 'R25 Kopf nur über die Planungshilfe');
select is(pg_temp.err(format('select public.ez_save_event(%L::jsonb, %L::jsonb, %L::jsonb)', pg_temp.head(pg_temp.e(99)),
  '[{"person_id": "a0000000-0000-4000-8000-000000000004", "role": "helper", "status": "present"}]', '[]')),
  'EZ_TK_MANAGED', 'R25 Rolle aus der Planung fest');
select is(pg_temp.err(format('select public.ez_save_event(%L::jsonb, %L::jsonb, %L::jsonb)', pg_temp.head(pg_temp.e(99)),
  '[]', '[]')), 'EZ_TK_MANAGED', 'R25 Person aus der Planung nicht entfernbar');
select is(pg_temp.err(format('select public.ez_cancel_event(%L, %L)', pg_temp.e(99), 'Wetter')), 'EZ_TK_MANAGED', 'R25 Absage');
select is(pg_temp.err(format('select public.ez_restore_event(%L)', pg_temp.e(99))), 'EZ_TK_MANAGED', 'R25 Rücknahme');
select pg_temp.as_user(pg_temp.u(2));
select is(pg_temp.err(format('select public.ez_delete_event(%L)', pg_temp.e(99))), 'EZ_TK_MANAGED', 'R25 Löschen');

select * from finish();
rollback;
