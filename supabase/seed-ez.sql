-- Testdaten der Anwesenheitserfassung (EZ spec.md Abschnitt 9, T8) – nur fiktive Daten, nur für vereins-os-test.
-- Wird von supabase/seed.sh nach seed.sql geladen, wenn SEED_WITH_EZ=1 gesetzt ist; nicht in CI, weil die Tests
-- anderer Module den Seed mit exakten Zählern prüfen (Entscheidung Product Owner 24.10.2026,
-- docs/specs/ez-einsaetze/uebergabe-seed-umsetzung.md, Vorschlag a). Die EZ-Tests legen dieselben Daten selbst an.
-- Voraussetzung: seed.sql (Personen 1–32, Gruppen c…01–c…04, Orte e1…01–03). Idempotent.

-- Einsätze f…01–f…11, Personen a…33–a…49 (research.md R-EZ-16).
-- „Gruppe Test Klettern“ = Klettergruppe Test (c…03), „Gruppe Test Jugend“ = Jugendgruppe Test 1 (c…01).
-- Feste Datumswerte (Einsätze im Oktober/November 2026). Die pgTAP-Tests 520–550 legen dieselben Daten mit denselben
-- UUIDs selbst an (on conflict do nothing). „erfasst von“ = Geschäftsstelle: Nutzerkontext für diesen Abschnitt.
select set_config('request.jwt.claims', json_build_object('sub', 'b0000000-0000-4000-8000-000000000002', 'role', 'authenticated')::text, false);


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

-- Ehrenamtsstatus mit Historie für die beiden Betreuer:innen
insert into public.ea_volunteer_status_history (person_id, status, valid_from)
select p.id, p.volunteer_status, p.volunteer_status_since
  from public.ea_persons p
 where p.id in ('a0000000-0000-4000-8000-000000000040', 'a0000000-0000-4000-8000-000000000049')
   and not exists (select 1 from public.ea_volunteer_status_history h where h.person_id = p.id);

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

select set_config('request.jwt.claims', '', false);
