-- Anwesenheitserfassung Nachtrag v0.6 (spec.md EZ v0.6, T26; US-EZ-24, US-EZ-25): Abrechnungsart am Einsatz (R32),
-- Lesefunktion für Finanzen (R33), Sperre abgerechneter Einsätze (R34) mit im Test ersetzten Platzhaltern.
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
create temp table ids (name text primary key, id uuid);
grant select, insert, update on ids to authenticated;
insert into ids select 'TRAINING', id from public.ad_remuneration_kinds where code = 'TRAINING';
insert into ids select 'COMPETITION', id from public.ad_remuneration_kinds where code = 'COMPETITION';
insert into ids select 'COMMUNITY_TOUR', id from public.ad_remuneration_kinds where code = 'COMMUNITY_TOUR';
insert into ids select 'Klettern', id from public.ea_referate where name = 'Klettern';
create function pg_temp.id(p_name text) returns uuid language sql as $$ select id from ids where name = p_name $$;
-- Vollständige Kopfdaten für Änderungen (ez_save_event übernimmt Titel, Datum, Ort nur aus dem Aufruf)
create function pg_temp.w1(p_extra jsonb) returns jsonb language sql as $$
  select jsonb_build_object('id', pg_temp.id('W1'), 'kind', 'work_assignment', 'referat_id', pg_temp.id('Klettern'),
                            'title', 'Bergfilmfestival Test', 'span', 'single', 'start_date', '2026-10-17',
                            'day_category', 'at_least_8h') || p_extra $$;
create function pg_temp.t1(p_extra jsonb) returns jsonb language sql as $$
  select jsonb_build_object('id', pg_temp.id('T1'), 'kind', 'training', 'group_id', 'c0000000-0000-4000-8000-000000000001',
                            'start_date', '2026-10-13', 'location_id', 'e1000000-0000-4000-8000-000000000002') || p_extra $$;
create function pg_temp.att() returns jsonb language sql as $$
  select '[{"person_id": "a0000000-0000-4000-8000-000000000049", "role": "trainer", "status": "present"},
           {"person_id": "a0000000-0000-4000-8000-000000000041", "role": "participant", "status": "present"}]'::jsonb $$;

-- Testdaten: Jugendgruppe Test 1 (c…01, Kinder und Jugend; Trainingszeit Di 16:30–18:00 aus dem Seed)
select set_config('request.jwt.claims', json_build_object('sub', 'b0000000-0000-4000-8000-000000000002', 'role', 'authenticated')::text, true);
insert into public.ea_persons (id, first_name, last_name, kind, created_in, volunteer_status, volunteer_status_since) values
  ('a0000000-0000-4000-8000-000000000041', 'Clara', 'Jugendtest', 'human', 'GR', null, null),
  ('a0000000-0000-4000-8000-000000000049', 'Jule', 'Jugendtrainerin', 'human', 'GR', 'active', date '2025-09-01')
on conflict (id) do nothing;
insert into public.gr_memberships (id, group_id, person_id, joined_on, left_on) values
  ('f3000000-0000-4000-8000-000000000041', 'c0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000041',
   date '2025-09-01', null)
on conflict (id) do nothing;
insert into public.ea_properties (id, person_id, property_type_id, field_values, related_group_id, valid_from)
select 'f4000000-0000-4000-8000-000000000004', 'a0000000-0000-4000-8000-000000000049', t.id, '{"function": "Trainer:in"}',
       'c0000000-0000-4000-8000-000000000001', date '2025-09-01'
  from public.ea_property_types t where t.system_key = 'group_function'
on conflict (id) do nothing;
select pg_temp.as_owner();

-- Struktur
select has_column('public', 'ez_events', 'remuneration_kind_id', 'Spalte remuneration_kind_id (R32)');
select col_is_null('public', 'ez_events', 'remuneration_kind_id', 'null = keine Vergütung');
select is(public.fi_event_locked('00000000-0000-0000-0000-000000000000'), false, 'Platzhalter fi_event_locked = false');
select is(public.fi_attendance_locked('00000000-0000-0000-0000-000000000000'), false, 'Platzhalter fi_attendance_locked = false');
select ok(has_function_privilege('authenticated', 'public.ez_settlement_basis(date, date, uuid[])', 'EXECUTE'),
  'ez_settlement_basis');

-- R32: Vorbelegung und Auswahl (Geschäftsstelle)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
insert into ids select 'T1', public.ez_save_event(
  jsonb_build_object('kind', 'training', 'group_id', 'c0000000-0000-4000-8000-000000000001', 'start_date', '2026-10-13',
                     'location_id', 'e1000000-0000-4000-8000-000000000002', 'client_request_id', gen_random_uuid()),
  pg_temp.att(), '[]');
select is((select remuneration_kind_id from public.ez_events where id = pg_temp.id('T1')), pg_temp.id('TRAINING'),
  'Training ohne Angabe: Vorbelegung Trainingseinheiten (US-EZ-24 AK1)');

insert into ids select 'W1', public.ez_save_event(
  jsonb_build_object('kind', 'work_assignment', 'referat_id', pg_temp.id('Klettern'), 'title', 'Bergfilmfestival Test',
                     'span', 'single', 'start_date', '2026-10-17', 'day_category', 'at_least_8h',
                     'client_request_id', gen_random_uuid()), '[]', '[]');
select is((select remuneration_kind_id from public.ez_events where id = pg_temp.id('W1')), null::uuid,
  'Arbeitseinsatz ohne Angabe: keine Vergütung');
select lives_ok(format($$ select public.ez_save_event(pg_temp.w1(jsonb_build_object('remuneration_kind_id', %L)), '[]', '[]') $$,
  pg_temp.id('COMPETITION')),
  'Vergütung am Arbeitseinsatz wählen (US-EZ-24 AK2)');
select is((select remuneration_kind_id from public.ez_events where id = pg_temp.id('W1')), pg_temp.id('COMPETITION'),
  'gewählte Abrechnungsart gespeichert');
select lives_ok($$ select public.ez_save_event(pg_temp.w1('{"remark": "nur Bemerkung"}'), '[]', '[]') $$,
  'ohne Angabe bleibt die Abrechnungsart');
select is((select remuneration_kind_id from public.ez_events where id = pg_temp.id('W1')), pg_temp.id('COMPETITION'),
  'Abrechnungsart unverändert');
select lives_ok($$ select public.ez_save_event(pg_temp.w1('{"remuneration_kind_id": null}'), '[]', '[]') $$,
  '„keine Vergütung“ wählbar');
select is((select remuneration_kind_id from public.ez_events where id = pg_temp.id('W1')), null::uuid, 'keine Vergütung');

select pg_temp.as_owner();
update public.ad_remuneration_kinds set is_active = false where code = 'COMMUNITY_TOUR';
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select throws_ok(format($$ select public.ez_save_event(pg_temp.w1(jsonb_build_object('remuneration_kind_id', %L)), '[]', '[]') $$,
  pg_temp.id('COMMUNITY_TOUR')), 'P0001', 'EZ_REMUNERATION_INACTIVE', 'inaktive Abrechnungsart (US-EZ-24 AK4)');

-- R33: Lesefunktion für Finanzen
select results_eq(
  format($$ select event_id, person_id, role::text, training_minutes, remuneration_kind_id
              from public.ez_settlement_basis(date '2026-10-01', date '2026-10-31') where event_id = %L $$, pg_temp.id('T1')),
  format($$ values (%L::uuid, 'a0000000-0000-4000-8000-000000000049'::uuid, 'trainer'::text, 90, %L::uuid) $$,
         pg_temp.id('T1'), pg_temp.id('TRAINING')),
  'nur Trainer:in, Dauer der Trainingszeit 90 Minuten, keine Teilnehmer:innen');
select is_empty(format($$ select 1 from public.ez_settlement_basis(date '2026-10-01', date '2026-10-31') where event_id = %L $$,
  pg_temp.id('W1')), 'Einsätze ohne Vergütung fehlen');
select throws_ok($$ select * from public.ez_settlement_basis(null, date '2026-10-31') $$, 'P0001', 'EZ_FIELD_REQUIRED',
  'Zeitraum Pflicht');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000032');
select throws_ok($$ select * from public.ez_settlement_basis(date '2026-10-01', date '2026-10-31') $$, 'P0001', 'EZ_FORBIDDEN',
  'Referent:in (FI Reichweite Referat): keine Abrechnungsgrundlage');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select throws_ok($$ select * from public.ez_settlement_basis(date '2026-10-01', date '2026-10-31') $$, 'P0001', 'EZ_FORBIDDEN',
  'Admin ohne FI: keine Abrechnungsgrundlage');

-- R34: Sperre mit im Test ersetzten Platzhaltern (T1 gilt als abgerechnet)
select pg_temp.as_owner();
create or replace function public.fi_event_locked(p_event uuid) returns boolean language sql stable security definer
  set search_path = '' as $$ select p_event = (select id from pg_temp.ids where name = 'T1') $$;
create or replace function public.fi_attendance_locked(p_attendance uuid) returns boolean language sql stable security definer
  set search_path = '' as $$
  select exists (select 1 from public.ez_attendances a
                  where a.id = p_attendance and a.event_id = (select id from pg_temp.ids where name = 'T1')
                    and a.role = 'trainer') $$;

select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select throws_ok($$ select public.ez_save_event(pg_temp.t1('{"start_date": "2026-10-20"}'), pg_temp.att(), '[]') $$,
  'P0001', 'EZ_SETTLED', 'Datum eines abgerechneten Einsatzes gesperrt (US-EZ-25 AK2)');
select throws_ok($$ select public.ez_save_event(pg_temp.t1('{"remuneration_kind_id": null}'), pg_temp.att(), '[]') $$,
  'P0001', 'EZ_SETTLED', 'Vergütung eines abgerechneten Einsatzes gesperrt');
select throws_ok($$ select public.ez_save_event(pg_temp.t1('{}'),
    '[{"person_id": "a0000000-0000-4000-8000-000000000041", "role": "participant", "status": "present"}]', '[]') $$,
  'P0001', 'EZ_SETTLED', 'abgerechnete Trainerin nicht entfernbar (US-EZ-25 AK1)');
select throws_ok($$ select public.ez_save_event(pg_temp.t1('{}'),
    '[{"person_id": "a0000000-0000-4000-8000-000000000049", "role": "helper", "status": "present"},
      {"person_id": "a0000000-0000-4000-8000-000000000041", "role": "participant", "status": "present"}]', '[]') $$,
  'P0001', 'EZ_SETTLED', 'Rolle einer abgerechneten Anwesenheit nicht änderbar');
select lives_ok($$ select public.ez_save_event(pg_temp.t1('{"remark": "Halle voll"}'), pg_temp.att(), '[]') $$,
  'Bemerkung bleibt änderbar (US-EZ-25 AK3)');
select throws_ok(format($$ select public.ez_cancel_event(%L, 'Ausfall') $$, pg_temp.id('T1')),
  'P0001', 'EZ_SETTLED', 'abgerechneter Einsatz nicht absagbar');
select throws_ok(format($$ select public.ez_delete_event(%L) $$, pg_temp.id('T1')),
  'P0001', 'EZ_SETTLED', 'abgerechneter Einsatz nicht löschbar, auch nicht mit „EZ verwalten“ (US-EZ-25 AK5)');
select is((public.ez_get_event(pg_temp.id('T1')) -> 'event' ->> 'is_settled')::boolean, true, 'Detail: Einsatz abgerechnet');
select is((select count(*)::int from jsonb_array_elements(public.ez_get_event(pg_temp.id('T1')) -> 'attendances') a
            where (a ->> 'is_settled')::boolean), 1, 'Detail: genau die Trainerin abgerechnet');
select is((public.ez_get_event(pg_temp.id('T1')) -> 'event' ->> 'remuneration_kind_name'), 'Trainingseinheiten',
  'Detail: Vergütung mit Bezeichnung');
select is((select is_settled from public.ez_list_events(date '2026-10-01', date '2026-10-31') where id = pg_temp.id('T1')),
  true, 'Liste: Kennzeichen abgerechnet');
select is((select is_settled from public.ez_list_events(date '2026-10-01', date '2026-10-31') where id = pg_temp.id('W1')),
  false, 'Liste: nicht abgerechneter Einsatz');

select * from finish();
rollback;
