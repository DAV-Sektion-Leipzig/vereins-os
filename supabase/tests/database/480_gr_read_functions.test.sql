-- US-GR-02, US-GR-05, US-GR-15, US-GR-19, US-GR-20 (GR spec T8, T10): Views und Lesefunktionen; Spaltenlisten und
-- JSON-Schlüssel (R20), Stichtage, E-Mail-Liste (R13), Hinweise (R2, R7, R17). EZ-Pfade als todo bis plan.md O2.
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
create function pg_temp.roster_persons(p_group uuid, p_date date) returns text[] language sql as $$
  select array(select right(x ->> 'person_id', 2) || ':' || (x ->> 'role')
                 from jsonb_array_elements(public.gr_group_roster(p_group, p_date) -> 'persons') x)
$$;

-- gr_v_memberships: Spalten und Hinweise
select columns_are('public', 'gr_v_memberships', array[
  'membership_id', 'group_id', 'person_id', 'first_name', 'preferred_name', 'last_name', 'joined_on', 'left_on',
  'birth_date', 'contract_id', 'contract_status', 'contract_ends_on', 'photo_consent', 'needs_clarification',
  'clarify_since', 'has_emergency_contact', 'needs_guardian'], 'Spalten gr_v_memberships');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select results_eq(
  $$ select right(person_id::text, 2)::int, contract_status, needs_clarification, clarify_since, has_emergency_contact,
            needs_guardian, photo_consent
       from public.gr_v_memberships order by person_id, joined_on $$,
  $$ values (23, 'active'::text, false, null::date, true, false, true),
            (23, 'active', false, null, true, false, true),
            (25, 'ended', true, public.gr_today() - 10, false, false, false),
            (28, 'active', false, null, false, false, false) $$,
  'Geschäftsstelle: Teilnahmen mit Status und Hinweisen (R7, R17)');
select ok((select bool_and(birth_date is not null) from public.gr_v_memberships), 'Geburtsdatum mit GR verwalten');
select results_eq($$ select right(person_id::text, 2)::int, group_name, needs_guardian from public.gr_v_pending_admissions $$,
  $$ values (30, 'Jugendgruppe Test 2'::text, true) $$, 'offene Aufnahme Paula, ohne Erziehungsberechtigte (R2)');

select pg_temp.as_owner();
update public.ad_template_rights r set level = 'read'
  from public.ad_templates t where t.id = r.template_id and t.name = 'Vorstand' and r.module_code = 'GR';
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select ok((select bool_and(birth_date is null) from public.gr_v_memberships), 'Vorstand mit GR lesen: kein Geburtsdatum (W2)');
select is((select count(*)::int from public.gr_v_memberships), 4, 'Vorstand mit GR lesen sieht die laufenden Teilnahmen');
select is((select needs_guardian from public.gr_v_pending_admissions), true, 'Hinweis ohne Alter auch mit GR lesen (R2)');
select pg_temp.as_owner();
update public.ad_template_rights r set level = 'none'
  from public.ad_templates t where t.id = r.template_id and t.name = 'Vorstand' and r.module_code = 'GR';

select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select is((select count(*)::int from public.gr_v_memberships), 5, 'Admin sieht auch beendete Teilnahmen (27)');

-- gr_group_overview
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select results_eq(
  $$ select name, referat_name, training_times_today, active_count, clarify_count, no_emergency_count, pending_count
       from public.gr_group_overview() $$,
  $$ values ('Jugendgruppe Test 1'::text, 'Kinder und Jugend'::text, 'Di 16:30–18:00 · Do 17:00–18:30'::text, 1, 0, 0, 0),
            ('Jugendgruppe Test 2', 'Kinder und Jugend', 'Mi 18:00–19:30', 2, 1, 2, 1),
            ('Klettergruppe Test', 'Klettern', null, 1, 0, 0, 0) $$,
  'Übersicht mit Trainingszeiten und Zählern');
select is((select count(*)::int from public.gr_group_overview(true)), 4, 'mit aufgelösten Gruppen');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select is_empty($$ select 1 from public.gr_group_overview(true) $$, 'Vorstand: leer');

-- gr_guardian_emails (R13)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select throws_ok($$ select public.gr_guardian_emails('c0000000-0000-4000-8000-000000000001') $$,
  'P0001', 'GR_FORBIDDEN', 'ohne GR lesen');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select results_eq($$ select public.gr_guardian_emails('c0000000-0000-4000-8000-000000000001') $$,
  $$ values ('jana.fiktiv@example.test'::text) $$, 'Test 1: Janas Adresse genau einmal');
select results_eq($$ select public.gr_guardian_emails('c0000000-0000-4000-8000-000000000002') $$,
  $$ values ('jana.fiktiv@example.test'::text) $$, 'Test 2: Geschwister ohne Dubletten');
select pg_temp.as_owner();
update public.ea_properties set field_values = '{"date": "2000-01-01"}', valid_from = date '2000-01-01'
 where id = 'e0000000-0000-4000-8000-000000000033';
update public.ea_properties set field_values = field_values || '{"email": "Sam.Sechzehn@example.test"}'
 where id = 'e0000000-0000-4000-8000-000000000034';
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select results_eq($$ select public.gr_guardian_emails('c0000000-0000-4000-8000-000000000002') $$,
  $$ values ('jana.fiktiv@example.test'::text), ('Sam.Sechzehn@example.test') $$,
  'volljährige Teilnehmer:in mit eigener Adresse statt der Erziehungsberechtigten (R13, A9)');

-- gr_group_roster (R20, US-GR-19)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select is((select array_agg(k order by k) from jsonb_object_keys(public.gr_group_roster('c0000000-0000-4000-8000-000000000001',
            public.gr_today())) k), array['group', 'persons', 'training_times'], 'Schlüssel der Rückgabe');
select is((select array_agg(distinct k order by k)
             from jsonb_array_elements(public.gr_group_roster('c0000000-0000-4000-8000-000000000001', public.gr_today()) -> 'persons') x,
                  jsonb_object_keys(x) k),
  array['first_name', 'last_name', 'person_id', 'preferred_name', 'role'], 'nur Namen und Rolle (R20)');
select is((select array_agg(k order by k) from jsonb_object_keys(public.gr_group_roster('c0000000-0000-4000-8000-000000000001',
            public.gr_today()) -> 'group') k), array['id', 'name', 'referat_id', 'referat_name'], 'Schlüssel group');
select is(pg_temp.roster_persons('c0000000-0000-4000-8000-000000000001', public.gr_today()),
  array['26:trainer', '28:helper', '23:participant'], 'Test 1 heute: Trainer, Helfer, Teilnehmerin');
select ok('27:participant' = any (pg_temp.roster_persons('c0000000-0000-4000-8000-000000000001', public.gr_today() - 40)),
  'Test 1 vor 40 Tagen enthält Lea (27)');
select ok('31:trainer' = any (pg_temp.roster_persons('c0000000-0000-4000-8000-000000000002', public.gr_today() - 90)),
  'Test 2 vor 90 Tagen enthält Tom (31) als trainer');
select ok(not ('31:trainer' = any (pg_temp.roster_persons('c0000000-0000-4000-8000-000000000002', public.gr_today()))),
  'Tom heute nicht mehr');
select ok('28:participant' = any (pg_temp.roster_persons('c0000000-0000-4000-8000-000000000002', public.gr_today())),
  'Sam in Test 2 als participant');
select is(public.gr_group_roster('c0000000-0000-4000-8000-000000000002', date '2025-10-01') -> 'training_times',
  '[{"starts_at": "17:00", "ends_at": "18:30"}]'::jsonb, 'Test 2 an einem Mittwoch 2025');
select is(public.gr_group_roster('c0000000-0000-4000-8000-000000000002', date '2026-10-21') -> 'training_times',
  '[{"starts_at": "18:00", "ends_at": "19:30"}]'::jsonb, 'Test 2 an einem Mittwoch 2026');
select is(public.gr_group_roster('c0000000-0000-4000-8000-000000000003', public.gr_today()) -> 'training_times',
  '[]'::jsonb, 'leere Liste statt Fehler');
select throws_ok($$ select public.gr_group_roster('c0000000-0000-4000-8000-000000000004', public.gr_today()) $$,
  'P0001', 'GR_GROUP_NOT_FOUND', 'aufgelöste Gruppe');
select throws_ok($$ select public.gr_group_roster('c0000000-0000-4000-8000-0000000000ee', public.gr_today()) $$,
  'P0001', 'GR_GROUP_NOT_FOUND', 'unbekannte Gruppe');
select lives_ok($$ select public.gr_group_roster('c0000000-0000-4000-8000-000000000004', date '2025-06-30') $$,
  'Altgruppe am letzten Tag noch lieferbar');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select throws_ok($$ select public.gr_group_roster('c0000000-0000-4000-8000-000000000001', public.gr_today()) $$,
  'P0001', 'GR_ROSTER_FORBIDDEN', 'Vorstand: keine Rechte');
select throws_ok($$ select public.gr_group_roster('c0000000-0000-4000-8000-0000000000ee', public.gr_today()) $$,
  'P0001', 'GR_ROSTER_FORBIDDEN', 'ohne Rechte auch bei unbekannter Gruppe keine Auskunft');

-- gr_groups_for_attendance
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select results_eq($$ select group_name from public.gr_groups_for_attendance(public.gr_today()) $$,
  $$ values ('Jugendgruppe Test 1'::text), ('Jugendgruppe Test 2'), ('Klettergruppe Test') $$, 'alle nicht aufgelösten Gruppen');
select is((select count(*)::int from public.gr_groups_for_attendance(date '2025-06-30')), 4, 'am Stichtag noch die Altgruppe');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select is_empty($$ select 1 from public.gr_groups_for_attendance(public.gr_today()) $$, 'Vorstand: leer');

-- gr_my_groups: Lars Lehrer (26) mit Zugang
select pg_temp.as_owner();
insert into public.ad_accesses (person_id, login_email, status, is_emergency)
values ('a0000000-0000-4000-8000-000000000026', 'test.lars@dav-leipzig.de', 'active', false);
insert into auth.users (instance_id, id, aud, role, email)
values ('00000000-0000-0000-0000-000000000000', 'b0000000-0000-4000-8000-000000000026', 'authenticated', 'authenticated',
        'test.lars@dav-leipzig.de');
update public.ad_accesses set auth_user_id = 'b0000000-0000-4000-8000-000000000026', status = 'active'
 where person_id = 'a0000000-0000-4000-8000-000000000026';
select pg_temp.as_user('b0000000-0000-4000-8000-000000000026');
select results_eq($$ select group_name, function, weekdays from public.gr_my_groups(public.gr_today()) $$,
  $$ values ('Jugendgruppe Test 1'::text, 'trainer'::text, '{2,4}'::smallint[]) $$, 'Lars: Test 1, trainer, Di und Do');
select is_empty($$ select 1 from public.gr_my_groups(date '2025-08-31') $$, 'vor Beginn der Funktion leer');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select is_empty($$ select 1 from public.gr_my_groups(public.gr_today()) $$, 'Geschäftsstelle ohne eigene Funktion: leer');

-- EZ-Pfade (Ü5, plan.md O2): erst mit Nachtrag v0.8 der Administration
select todo('O2: EZ-Rechte (Modul EZ, Reichweite Referat) fehlen bis AD v0.8', 4);
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select lives_ok($$ select public.gr_group_roster('c0000000-0000-4000-8000-000000000003', public.gr_today()) $$,
  'Rita (EZ Referat Klettern): Klettergruppe');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000032');
select lives_ok($$ select public.gr_group_roster('c0000000-0000-4000-8000-000000000001', public.gr_today()) $$,
  'Kim (EZ Referat Kinder und Jugend): Test 1');
select is((select count(*)::int from public.gr_groups_for_attendance(public.gr_today())), 2,
  'Kim: Gruppen ihres Referats');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select is((select count(*)::int from public.gr_groups_for_attendance(public.gr_today())), 1, 'Rita: Klettergruppe');
-- ohne EZ-Rechte bleibt der Zugriff heute gesperrt
select pg_temp.as_user('b0000000-0000-4000-8000-000000000032');
select throws_ok($$ select public.gr_group_roster('c0000000-0000-4000-8000-000000000003', public.gr_today()) $$,
  'P0001', 'GR_ROSTER_FORBIDDEN', 'Kim: Klettergruppe nicht');

select * from finish();
rollback;
