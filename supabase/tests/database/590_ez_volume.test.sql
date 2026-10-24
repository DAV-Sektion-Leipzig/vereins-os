-- Anwesenheitserfassung (spec.md EZ v0.5, Abschnitt 8; T9 Teil; tasks.md T008): Mengentest mit 1.200 Einsätzen und
-- 15.000 Anwesenheiten in der Transaktion. Zeiten sind Anhaltspunkte aus CI (clock_timestamp()).
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
create function pg_temp.ms(p_sql text) returns numeric language plpgsql as $$
declare
  v_start timestamptz := clock_timestamp();
begin
  execute p_sql;
  return round(extract(epoch from clock_timestamp() - v_start) * 1000, 1);
end $$;

-- 40 aktive Personen, 300 Trainings der Klettergruppe Test in der Kletterhalle, 900 Arbeitseinsätze im Referat Klettern
select set_config('request.jwt.claims', json_build_object('sub', pg_temp.u(2), 'role', 'authenticated')::text, true);
insert into public.ea_persons (id, first_name, last_name, created_in, volunteer_status, volunteer_status_since)
select ('a9000000-0000-4000-8000-' || lpad(n::text, 12, '0'))::uuid, 'Menge' || n, 'Volumentest', 'AD', 'active', date '2025-01-01'
  from generate_series(1, 40) n;
insert into public.ez_events (id, kind, span, referat_id, group_id, start_date, location_id, client_request_id)
select ('f9000000-0000-4000-8000-' || lpad(n::text, 12, '0'))::uuid, 'training', 'single', pg_temp.referat('Klettern'),
       'c0000000-0000-4000-8000-000000000003', date '2026-01-01' + (n % 365), 'e1000000-0000-4000-8000-000000000001',
       gen_random_uuid()
  from generate_series(1, 300) n;
insert into public.ez_events (id, kind, span, referat_id, title, start_date, day_category, client_request_id)
select ('f9000000-0000-4000-8000-' || lpad(n::text, 12, '0'))::uuid, 'work_assignment', 'single', pg_temp.referat('Klettern'),
       'Menge ' || n, date '2026-01-01' + (n % 365), 'under_8h', gen_random_uuid()
  from generate_series(301, 1200) n;
insert into public.ez_attendances (event_id, person_id, role, status)
select ('f9000000-0000-4000-8000-' || lpad(e::text, 12, '0'))::uuid,
       ('a9000000-0000-4000-8000-' || lpad((((e + k) % 40) + 1)::text, 12, '0'))::uuid,
       case when k = 0 then 'trainer' when e <= 300 then 'participant' else 'helper' end::public.ez_role, 'present'
  from generate_series(1, 1200) e, generate_series(0, 12) k
 where k < 12 or e % 2 = 0;
select set_config('request.jwt.claims', '', true);
analyze public.ez_events;
analyze public.ez_attendances;

select pg_temp.as_owner();
select ok((select count(*) from public.ez_events) >= 1200, 'mindestens 1.200 Einsätze');
select ok((select count(*) from public.ez_attendances) >= 15000, 'mindestens 15.000 Anwesenheiten');

-- Messungen als Rita (Reichweite Referat) und Geschäftsstelle
select pg_temp.as_user(pg_temp.u(9));
select ok(pg_temp.ms($$ select * from public.ez_list_events(date '2026-07-01', date '2026-12-31') $$) < 1000,
  'Liste 50 Zeilen < 1 s (Rita)');
select diag('Liste Rita: ' || pg_temp.ms($$ select * from public.ez_list_events(date '2026-07-01', date '2026-12-31') $$) || ' ms');
select ok(pg_temp.ms($$ select * from public.ez_climbing_points_report('e1000000-0000-4000-8000-000000000001',
                                                                      date '2026-03-01', date '2026-03-31') $$) < 1000,
  'Kontrollliste eines Monats < 1 s');
select ok(pg_temp.ms(format('select * from public.ea_person_names(%L)',
                            (select array_agg(('a9000000-0000-4000-8000-' || lpad(n::text, 12, '0'))::uuid)
                               from generate_series(1, 40) n))) < 1000, 'ea_person_names mit ez_person_visible < 1 s');
select diag('Namen Rita: ' || pg_temp.ms(format('select * from public.ea_person_names(%L)',
  (select array_agg(('a9000000-0000-4000-8000-' || lpad(n::text, 12, '0'))::uuid) from generate_series(1, 40) n))) || ' ms');
select ok(pg_temp.ms(format('select public.ez_save_event(%L::jsonb, %L::jsonb, %L::jsonb)',
  jsonb_build_object('client_request_id', gen_random_uuid(), 'kind', 'work_assignment', 'referat_id', pg_temp.referat('Klettern'),
                     'title', 'Messung', 'start_date', '2026-12-30', 'span', 'single', 'day_category', 'under_8h'),
  (select jsonb_agg(jsonb_build_object('person_id', ('a9000000-0000-4000-8000-' || lpad(n::text, 12, '0'))::uuid,
                                       'role', 'helper', 'status', 'present')) from generate_series(1, 30) n),
  '[]')) < 1000, 'ez_save_event mit 30 Anwesenheiten < 1 s');
select pg_temp.as_user(pg_temp.u(2));
select ok(pg_temp.ms($$ select * from public.ez_list_events(null, null) $$) < 1000, 'Liste ohne Filter < 1 s (Geschäftsstelle)');
select diag('Liste Geschäftsstelle: ' || pg_temp.ms($$ select * from public.ez_list_events(null, null) $$) || ' ms');

select * from finish();
rollback;
