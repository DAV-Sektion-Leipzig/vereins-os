-- Anwesenheitserfassung (spec.md EZ v0.5, T9 Teil; tasks.md T005): ez_save_event mit R1–R12, R16–R21, R28, R30,
-- Idempotenz (US-EZ-18), Stichtag (Einsatz 8), Ersetzen der Anwesenheiten, Audit (R9).
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

-- Zweite Gruppe im Referat Klettern für R30 (in der Transaktion)
insert into public.gr_groups (id, name, referat_id) values
  ('f7000000-0000-4000-8000-000000000001', 'Zweitgruppe EZ Test', pg_temp.referat('Klettern'));
insert into public.gr_memberships (group_id, person_id, joined_on)
values ('f7000000-0000-4000-8000-000000000001', pg_temp.p(41), date '2025-09-01');

select pg_temp.as_user(pg_temp.u(9));

-- R1 Pflichtfelder (Feld in detail)
select is(pg_temp.save(pg_temp.tr('2026-10-27') - 'group_id', pg_temp.att('{4}', '{33}')), 'EZ_FIELD_REQUIRED:Gruppe', 'R1 Gruppe');
select is(pg_temp.save(pg_temp.tr('2026-10-27') - 'location_id', pg_temp.att('{4}', '{33}')), 'EZ_FIELD_REQUIRED:Ort', 'R1 Ort');
select is(pg_temp.save(pg_temp.tr('2026-10-27') - 'start_date', pg_temp.att('{4}', '{33}')), 'EZ_FIELD_REQUIRED:Datum', 'R1 Datum');
select is(pg_temp.save(pg_temp.trip('day_trip', '2026-10-28') - 'title', pg_temp.att('{4}', '{33}')), 'EZ_FIELD_REQUIRED:Titel', 'R1 Titel');
select is(pg_temp.save(pg_temp.trip('day_trip', '2026-10-28') - 'organizer_person_id', pg_temp.att('{4}', '{33}')),
  'EZ_FIELD_REQUIRED:Organisierende Person', 'R1 Organisierende Person');
select is(pg_temp.save(pg_temp.trip('day_trip', '2026-10-28') - 'day_category', pg_temp.att('{4}', '{33}')),
  'EZ_FIELD_REQUIRED:Dauer', 'R1 Dauer');
select is(pg_temp.save(pg_temp.trip('multi_day_trip', '2026-10-28'), pg_temp.att('{4}', '{33}')),
  'EZ_FIELD_REQUIRED:Enddatum', 'R1 Enddatum');
select is(pg_temp.save(pg_temp.trip('multi_day_trip', '2026-10-28') - 'start_date' || '{"end_date": "2026-10-30"}',
  pg_temp.att('{4}', '{33}')), 'EZ_FIELD_REQUIRED:Startdatum', 'R1 Startdatum');
select is(pg_temp.save(pg_temp.wa('Klettern', '2026-10-28') - 'referat_id', '[]'), 'EZ_FIELD_REQUIRED:Referat', 'R1 Referat');

-- R2, Längen, R7, R6
select is(pg_temp.save(pg_temp.trip('multi_day_trip', '2026-10-28') || '{"end_date": "2026-10-28"}', pg_temp.att('{4}', '{33}')),
  'EZ_END_DATE', 'R2 Enddatum nach Startdatum');
select is(pg_temp.save(pg_temp.trip('day_trip', '2026-10-28') || jsonb_build_object('title', repeat('x', 91)),
  pg_temp.att('{4}', '{33}')), 'EZ_TITLE_LENGTH', 'Titel höchstens 90 Zeichen');
select is(pg_temp.save(pg_temp.trip('day_trip', '2026-10-28') || jsonb_build_object('title', repeat('x', 90)),
  pg_temp.att('{4}', '{33}')), 'ok', 'Titel mit 90 Zeichen');
select is(pg_temp.save(pg_temp.tr('2026-10-27') || jsonb_build_object('remark', repeat('x', 501)), pg_temp.att('{4}', '{33}')),
  'EZ_REMARK_LENGTH', 'R7 Bemerkung höchstens 500 Zeichen');
select is(pg_temp.save(pg_temp.tr('2026-10-27'), pg_temp.att('{4}', '{33}'), '["  "]'), 'EZ_TRIAL_NAME:required', 'R6 leer');
select is(pg_temp.save(pg_temp.tr('2026-10-27'), pg_temp.att('{4}', '{33}'), jsonb_build_array(repeat('x', 31))),
  'EZ_TRIAL_NAME:too_long', 'R6 höchstens 30 Zeichen');

-- R5 Mindestbesetzung
select is(pg_temp.save(pg_temp.tr('2026-10-27'), pg_temp.att('{}', '{33,34}')), 'EZ_MIN_ATTENDANCE', 'R5 ohne Trainer:in');
select is(pg_temp.save(pg_temp.tr('2026-10-27'), pg_temp.att('{4}', '{}')), 'EZ_MIN_ATTENDANCE', 'R5 ohne Teilnehmer:in');
select is(pg_temp.save(pg_temp.trip('competition', '2026-10-28') - 'organizer_person_id', pg_temp.att('{9}', '{}')),
  'EZ_MIN_ATTENDANCE', 'R5 auch bei Wettkampfbetreuung');
select is(pg_temp.save(pg_temp.wa('Klettern', '2026-10-28'), '[]'), 'ok', 'R5 nicht beim Arbeitseinsatz');

-- R11, R12
select is(pg_temp.save(pg_temp.trip('day_trip', '2026-10-29') || jsonb_build_object('organizer_person_id', pg_temp.p(5)),
  pg_temp.att('{4}', '{33}')), 'EZ_ORGANIZER_NOT_ACTIVE', 'R11 organisierende Person ruhend');
select is(pg_temp.save(pg_temp.tr('2026-10-27') || '{"location_id": "e1000000-0000-4000-8000-000000000003"}',
  pg_temp.att('{4}', '{33}')), 'EZ_LOCATION_INACTIVE', 'R12 inaktiver Ort');

-- R13, R14
select is(pg_temp.save(pg_temp.tr('2026-10-27') || '{"group_id": "c0000000-0000-4000-8000-000000000001"}',
  pg_temp.att('{26}', '{41}')), 'EZ_FORBIDDEN', 'R13 Rita: Gruppe eines anderen Referats');
select is(pg_temp.save(pg_temp.wa('Kinder und Jugend', '2026-10-28'), '[]'), 'EZ_FORBIDDEN', 'R13 Rita: Arbeitseinsatz anderes Referat');
select is(pg_temp.save(jsonb_build_object('id', pg_temp.e(3)) || pg_temp.tr('2026-10-14'), '[]'), 'EZ_NOT_FOUND',
  'R13 Ändern eines nicht lesbaren Einsatzes');
select pg_temp.as_user(pg_temp.u(1));
select is(pg_temp.save(pg_temp.tr('2026-10-27'), pg_temp.att('{4}', '{33}')), 'EZ_FORBIDDEN', 'R14 Admin liest nur');
select pg_temp.as_user(pg_temp.u(9));

-- R16 Stichtag, R17, R20, R21
select is(pg_temp.save(pg_temp.tr('2026-10-27'), pg_temp.att('{4}', '{33,41}')),
  'EZ_PARTICIPANT_NOT_IN_GROUP:' || pg_temp.p(41), 'R16 Teilnehmer:in einer anderen Gruppe');
select is(pg_temp.save(pg_temp.trip('training_trip', '2026-08-01') || '{"span": "multi", "end_date": "2026-08-08", "day_category": null}',
  pg_temp.att('{4}', '{33,39}')), 'EZ_PARTICIPANT_NOT_IN_GROUP:' || pg_temp.p(39),
  'R16 Stichtag: Eintritt 01.09.2026 nicht am 01.08.2026 (Einsatz 8)');
select ok(not (pg_temp.p(39)::text = any (
  select x ->> 'person_id' from jsonb_array_elements(public.gr_group_roster('c0000000-0000-4000-8000-000000000003',
                                                                           date '2026-08-01') -> 'persons') x)),
  'R16 Roster vom 01.08.2026 ohne Späteintritt');
select is(pg_temp.save(pg_temp.tr('2026-10-27'), pg_temp.att('{4}', '{33,33}')), 'EZ_DUPLICATE_PERSON:' || pg_temp.p(33), 'R17');
select is(pg_temp.save(pg_temp.tr('2026-10-27'), pg_temp.att('{4,5}', '{33}')), 'EZ_PERSON_NOT_ACTIVE:' || pg_temp.p(5),
  'R20 Vertretung ruhend');
select is(pg_temp.save(pg_temp.tr('2026-10-27'), pg_temp.att('{4}', '{33}', 'trainer', 'registered')), 'EZ_STATUS_NOT_ALLOWED',
  'R21 eingetragen nur bei Arbeitseinsatz, Kurs, Tour');
select is(pg_temp.save(jsonb_build_object('kind', 'course', 'referat_id', pg_temp.referat('Klettern'), 'title', 'Kurs Test',
  'organizer_person_id', pg_temp.p(4), 'start_date', '2026-11-28', 'span', 'single', 'day_category', 'at_least_8h'),
  pg_temp.att('{4}', '{33}', 'trainer', 'registered')), 'EZ_ROLE_NOT_ALLOWED', 'R21 Kurs ohne Teilnehmer:innen');

-- Anlegen: Vertretung, Probetraining, Audit (R9), Uhrzeit beim Training null (R28)
create temp table ids (name text, id uuid);
grant all on ids to authenticated;
insert into ids select 'training', public.ez_save_event(
  jsonb_build_object('client_request_id', 'f8000000-0000-4000-8000-000000000001') || pg_temp.tr('2026-10-27')
    || '{"start_time": "17:00", "remark": "  Halle voll  "}',
  pg_temp.att('{4,10}', '{33,34}'), '[" Lena "]');
select results_eq($$ select person_id, role::text, is_substitute from public.ez_attendances a
                      where a.event_id = (select id from ids where name = 'training') order by person_id $$,
  $$ values (pg_temp.p(4), 'trainer'::text, false), (pg_temp.p(10), 'trainer', true),
            (pg_temp.p(33), 'participant', false), (pg_temp.p(34), 'participant', false) $$,
  'Vertretung Karl erkannt (R20), Toni aus der Gruppe');
select ok((select start_time is null and remark = 'Halle voll' and created_by_person_id = pg_temp.p(9)
                  and referat_id = pg_temp.referat('Klettern')
             from public.ez_events where id = (select id from ids where name = 'training')),
  'R28 ohne Uhrzeit, Bemerkung getrimmt, erfasst von Rita, Referat aus der Gruppe');
select is((select array_agg(first_name) from public.ez_trial_participants where event_id = (select id from ids where name = 'training')),
  array['Lena'], 'Probetraining getrimmt');

-- Idempotenz (US-EZ-18)
select is(public.ez_save_event(
  jsonb_build_object('client_request_id', 'f8000000-0000-4000-8000-000000000001') || pg_temp.tr('2026-10-27'),
  pg_temp.att('{4}', '{33}'), '[]'), (select id from ids where name = 'training'), 'gleiche client_request_id → gleiche id');
select is((select count(*)::int from public.ez_events where client_request_id = 'f8000000-0000-4000-8000-000000000001'), 1,
  'kein zweiter Einsatz');
select is((select count(*)::int from public.ez_attendances where event_id = (select id from ids where name = 'training')), 4,
  'Idempotenz ohne Schreiben');

-- Ändern: Ersetzen der Anwesenheiten und Probetrainings, Audit
select is(pg_temp.err(format('select public.ez_save_event(%L::jsonb, %L::jsonb, %L::jsonb)',
  jsonb_build_object('id', (select id from ids where name = 'training')) || pg_temp.tr('2026-10-27'),
  '[{"person_id": "a0000000-0000-4000-8000-000000000004", "role": "helper"},
    {"person_id": "a0000000-0000-4000-8000-000000000033", "role": "participant"},
    {"person_id": "a0000000-0000-4000-8000-000000000035", "role": "participant"}]', '[]')), 'ok', 'Ändern');
select results_eq($$ select person_id, role::text from public.ez_attendances a
                      where a.event_id = (select id from ids where name = 'training') order by person_id $$,
  $$ values (pg_temp.p(4), 'helper'::text), (pg_temp.p(33), 'participant'), (pg_temp.p(35), 'participant') $$,
  'Anwesenheiten ersetzt, Rolle geändert');
select is((select count(*)::int from public.ez_trial_participants where event_id = (select id from ids where name = 'training')),
  0, 'Probetrainings ersetzt');
select ok((select updated_by_person_id = pg_temp.p(9) and updated_at is not null
             from public.ez_events where id = (select id from ids where name = 'training')), 'R9 geändert von');

-- R19 unveränderliche Felder
select is(pg_temp.err(format('select public.ez_save_event(%L::jsonb, %L::jsonb, %L::jsonb)',
  jsonb_build_object('id', (select id from ids where name = 'training')) || pg_temp.tr('2026-10-27')
    || '{"kind": "day_trip"}', pg_temp.att('{4}', '{33}'), '[]')), 'EZ_FIELD_LOCKED', 'R19 Einsatzart');
select is(pg_temp.err(format('select public.ez_save_event(%L::jsonb, %L::jsonb, %L::jsonb)',
  jsonb_build_object('id', (select id from ids where name = 'training')) || pg_temp.tr('2026-10-27')
    || '{"group_id": "f7000000-0000-4000-8000-000000000001"}', pg_temp.att('{4}', '{33}'), '[]')), 'EZ_FIELD_LOCKED', 'R19 Gruppe');

-- eintägig → mehrtägig bleibt änderbar
insert into ids select 'ausbildung', public.ez_save_event(
  jsonb_build_object('client_request_id', gen_random_uuid()) || pg_temp.trip('training_trip', '2026-11-04'),
  pg_temp.att('{4}', '{33}'), '[]');
select is(pg_temp.err(format('select public.ez_save_event(%L::jsonb, %L::jsonb, %L::jsonb)',
  jsonb_build_object('id', (select id from ids where name = 'ausbildung')) || pg_temp.trip('training_trip', '2026-11-04')
    || '{"span": "multi", "end_date": "2026-11-06", "start_time": "08:00"}', pg_temp.att('{4}', '{33}'), '[]')), 'ok',
  'eintägig → mehrtägig');
select ok((select span = 'multi' and day_category is null and start_time = '08:00' from public.ez_events
            where id = (select id from ids where name = 'ausbildung')), 'Form neu geprüft');

-- Referat bei Arbeitseinsatz änderbar, nur auf beschreibbares Referat (R19)
insert into ids select 'arbeit', public.ez_save_event(
  jsonb_build_object('client_request_id', gen_random_uuid()) || pg_temp.wa('Klettern', '2026-11-05'),
  pg_temp.att('{4}', '{}', 'helper', 'registered'), '[]');
select is(pg_temp.err(format('select public.ez_save_event(%L::jsonb, %L::jsonb, %L::jsonb)',
  jsonb_build_object('id', (select id from ids where name = 'arbeit')) || pg_temp.wa('Kinder und Jugend', '2026-11-05'),
  '[]', '[]')), 'EZ_FORBIDDEN', 'R19 Rita: Referat nur auf eigenes');
select pg_temp.as_user(pg_temp.u(2));
select is(pg_temp.err(format('select public.ez_save_event(%L::jsonb, %L::jsonb, %L::jsonb)',
  jsonb_build_object('id', (select id from ids where name = 'arbeit')) || pg_temp.wa('Touren', '2026-11-05'),
  pg_temp.att('{4}', '{}', 'helper', 'registered'), '[]')), 'ok', 'R19 Geschäftsstelle ändert Referat');
select is((select referat_id from public.ez_events where id = (select id from ids where name = 'arbeit')),
  pg_temp.referat('Touren'), 'Referat geändert');

-- R30 Wettkampfbetreuung mit mehreren Gruppen
select is(pg_temp.save(pg_temp.trip('competition', '2026-11-07') - 'organizer_person_id'
    || '{"additional_group_ids": ["c0000000-0000-4000-8000-000000000001"]}', pg_temp.att('{9}', '{33}')),
  'EZ_GROUP_REFERAT_MISMATCH', 'R30 gleiches Referat');
select is(pg_temp.save(pg_temp.tr('2026-11-10') || '{"additional_group_ids": ["f7000000-0000-4000-8000-000000000001"]}',
  pg_temp.att('{4}', '{33}')), 'EZ_KIND_NOT_ALLOWED', 'R30 nur Wettkampfbetreuung');
insert into ids select 'cup', public.ez_save_event(
  jsonb_build_object('client_request_id', gen_random_uuid()) || pg_temp.trip('competition', '2026-11-07') - 'organizer_person_id'
    || '{"additional_group_ids": ["f7000000-0000-4000-8000-000000000001"]}',
  pg_temp.att('{9}', '{33,41}'), '[]');
select is((select array_agg(group_id) from public.ez_event_groups where event_id = (select id from ids where name = 'cup')),
  array['f7000000-0000-4000-8000-000000000001'::uuid], 'weitere Gruppe gespeichert');
select is((select group_name from public.ez_list_events(date '2026-11-07', date '2026-11-07', p_kind => 'competition')),
  'Klettergruppe Test + Zweitgruppe EZ Test', 'Gruppenname „A + B“');
select is(pg_temp.err(format('select public.ez_save_event(%L::jsonb, %L::jsonb, %L::jsonb)',
  jsonb_build_object('id', (select id from ids where name = 'cup')) || pg_temp.trip('competition', '2026-11-07')
    - 'organizer_person_id' || '{"additional_group_ids": []}', pg_temp.att('{9}', '{33}'), '[]')),
  'EZ_FIELD_LOCKED', 'R19 weitere Gruppen nicht änderbar');

-- R8 doppelte Erfassung
select pg_temp.as_user(pg_temp.u(9));
select is(pg_temp.save(pg_temp.tr('2026-10-13'), pg_temp.att('{4}', '{33}')), 'EZ_DUPLICATE_EVENT:' || pg_temp.e(1),
  'R8 mit Link auf lesbaren Einsatz');
select is(pg_temp.save(pg_temp.tr('2026-10-13'), pg_temp.att('{4}', '{33}'), '[]', true), 'ok', 'R8 trotzdem speichern');
select is(pg_temp.save(pg_temp.trip('day_trip', '2026-10-10'), pg_temp.att('{4}', '{33}')), 'ok',
  'R8 abgesagter Einsatz zählt nicht (Einsatz 11)');

-- R20 beim Ändern: gespeicherte, inzwischen ruhende Vertretung bleibt erlaubt
select pg_temp.as_owner();
update public.ea_persons set volunteer_status = 'dormant', volunteer_status_since = date '2026-10-28' where id = pg_temp.p(10);
select pg_temp.as_user(pg_temp.u(9));
select is(pg_temp.err(format('select public.ez_save_event(%L::jsonb, %L::jsonb, %L::jsonb)',
  jsonb_build_object('id', pg_temp.e(2)) || pg_temp.tr('2026-10-20'),
  pg_temp.att('{}', '{33,34,35,36}') || jsonb_build_array(jsonb_build_object('person_id', pg_temp.p(10), 'role', 'helper')),
  '[]')), 'ok', 'R20 gespeicherte Vertretung bleibt beim Ändern erlaubt');
select is(pg_temp.save(pg_temp.tr('2026-11-17'), pg_temp.att('{4,10}', '{33}')), 'EZ_PERSON_NOT_ACTIVE:' || pg_temp.p(10),
  'R20 neue ruhende Vertretung abgelehnt');

-- R8 ohne Link, wenn der vorhandene Einsatz nicht lesbar ist: Gruppe wechselt nach Erfassung ins Referat Klettern
select pg_temp.as_owner();
update public.gr_groups set referat_id = pg_temp.referat('Klettern') where id = 'c0000000-0000-4000-8000-000000000001';
select pg_temp.as_user(pg_temp.u(9));
select is(pg_temp.save(pg_temp.tr('2026-10-14') || '{"group_id": "c0000000-0000-4000-8000-000000000001"}',
  pg_temp.att('{26}', '{41}')), 'EZ_DUPLICATE_EVENT', 'R8 ohne Link bei nicht lesbarem Einsatz (US-EZ-17 AK4)');

select * from finish();
rollback;
