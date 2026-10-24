-- Nachtrag v0.8 (spec T52, T56 Teil; US-AD-29; Übergabe EZ A3; R44): ez_person_visible, ea_person_names,
-- ea_search_active_persons nach der Tabelle „Erwartete Ergebnisse der Namensfunktionen“ (spec.md Abschnitt 9, v0.8.1);
-- Mengentest Abschnitt 8 (300 Aktive, 50 IDs, je < 300 ms; Anhaltspunkt aus CI).
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

-- Grants und Spalten
select ok(has_function_privilege('authenticated', 'public.ea_person_names(uuid[])', 'EXECUTE'), 'ea_person_names');
select ok(has_function_privilege('authenticated', 'public.ea_search_active_persons(text, int)', 'EXECUTE'), 'ea_search_active_persons');
select ok(has_function_privilege('authenticated', 'public.ez_person_visible(uuid)', 'EXECUTE'), 'ez_person_visible');
select ok(not has_function_privilege('anon', 'public.ea_person_names(uuid[])', 'EXECUTE'), 'anon: keine Namen');
select ok(not has_function_privilege('anon', 'public.ea_search_active_persons(text, int)', 'EXECUTE'), 'anon: keine Suche');
select is(pg_get_function_result('public.ea_search_active_persons(text, int)'::regprocedure),
  'TABLE(id uuid, first_name text, preferred_name text, last_name text)', 'Suche liefert nur vier Spalten');
select is(pg_get_function_result('public.ea_person_names(uuid[])'::regprocedure),
  'TABLE(id uuid, first_name text, preferred_name text, last_name text)', 'Namen liefern nur vier Spalten');
select is(public.ez_person_visible(pg_temp.p(4)), false, 'Platzhalter ez_person_visible = false');

-- Admin (EZ lesen)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select throws_ok($$ select * from public.ea_search_active_persons('Muster') $$, 'P0001', 'AD_FORBIDDEN', 'Admin: Suche abgelehnt');
select results_eq($$ select id from public.ea_person_names(array[pg_temp.p(4), pg_temp.p(5), pg_temp.p(12)]) order by id $$,
  $$ values (pg_temp.p(4)), (pg_temp.p(5)), (pg_temp.p(12)) $$, 'Admin: Namen 4, 5, 12 (Pfad AD)');
select is_empty($$ select 1 from public.ea_person_names(array[pg_temp.p(8)]) $$, 'Funktionsperson 8 nie');

-- Geschäftsstelle (EZ verwalten)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select results_eq($$ select id from public.ea_search_active_persons('Muster') $$,
  $$ values (pg_temp.p(4)) $$, 'Geschäftsstelle: „Muster“ → 4 (nicht 5: ruhend)');
select results_eq($$ select id from public.ea_search_active_persons('Karl') $$,
  $$ values (pg_temp.p(10)) $$, 'Geschäftsstelle: „Karl“ → 10');
select results_eq($$ select id from public.ea_person_names(array[pg_temp.p(4), pg_temp.p(5), pg_temp.p(12)]) order by id $$,
  $$ values (pg_temp.p(4)), (pg_temp.p(5)) $$,
  'Geschäftsstelle: Namen 4, 5 (Pfad EA; 12 hat im Seed keinen laufenden Gruppenbezug)');
select results_eq($$ select id from public.ea_search_active_persons('toni mus') $$,
  $$ values (pg_temp.p(4)) $$, 'mehrere Wörter, Teilwort, ohne Groß-/Kleinschreibung');
select is_empty($$ select 1 from public.ea_search_active_persons('Notfall') $$, 'Funktionsperson nicht in der Suche');
select is_empty($$ select 1 from public.ea_search_active_persons('%%') $$, 'Platzhalter % werden maskiert');
select throws_ok($$ select * from public.ea_search_active_persons('M') $$, 'P0001', 'AD_SEARCH_TOO_SHORT', 'ein Zeichen');
select throws_ok($$ select * from public.ea_search_active_persons('  M  ') $$, 'P0001', 'AD_SEARCH_TOO_SHORT',
  'ein Zeichen mit Leerzeichen');
select throws_ok($$ select * from public.ea_search_active_persons('Muster', 51) $$, 'P0001', 'AD_BAD_REQUEST', 'höchstens 50');
select throws_ok($$ select * from public.ea_person_names(array(select gen_random_uuid() from generate_series(1, 501))) $$,
  'P0001', 'AD_TOO_MANY_IDS', 'höchstens 500 IDs');
select is_empty($$ select 1 from public.ea_person_names(array[gen_random_uuid()]) $$, 'unbekannte ID ohne Fehler ausgelassen');

-- Referent:in (Klettern, EZ bearbeiten Referat)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select results_eq($$ select id from public.ea_search_active_persons('Muster') $$, $$ values (pg_temp.p(4)) $$,
  'Referent:in: „Muster“ → 4');
select results_eq($$ select id from public.ea_search_active_persons('Karl') $$, $$ values (pg_temp.p(10)) $$,
  'Referent:in: „Karl“ → 10 (über Referatsgrenzen)');
select results_eq($$ select id from public.ea_person_names(array[pg_temp.p(4), pg_temp.p(5), pg_temp.p(12)]) $$,
  $$ values (pg_temp.p(4)) $$, 'Referent:in: Namen nur 4 (Pfad EA Referat)');

-- Vorstand
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select throws_ok($$ select * from public.ea_search_active_persons('Muster') $$, 'P0001', 'AD_FORBIDDEN', 'Vorstand: Suche abgelehnt');
select is_empty($$ select 1 from public.ea_person_names(array[pg_temp.p(4), pg_temp.p(5), pg_temp.p(12)]) $$,
  'Vorstand: keine Namen');

-- Mengentest: 300 Aktive (ohne Trigger eingefügt)
select pg_temp.as_owner();
alter table public.ea_persons disable trigger user;
insert into public.ea_persons (first_name, last_name, created_in, volunteer_status, volunteer_status_since)
select 'Vorname' || g, 'Menge' || lpad(g::text, 4, '0'), 'script', 'active', date '2024-01-01'
  from generate_series(1, 300) as g;
alter table public.ea_persons enable trigger user;
analyze public.ea_persons;

create temp table zeit (was text, ms numeric);
grant all on zeit to authenticated;
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
do $$
declare v_t timestamptz; v_ids uuid[];
begin
  v_t := clock_timestamp();
  perform * from public.ea_search_active_persons('Menge01', 50);
  insert into zeit values ('suche', extract(epoch from clock_timestamp() - v_t) * 1000);
  select array_agg(id) into v_ids from (select id from public.ea_persons where last_name like 'Menge%' limit 50) s;
  v_t := clock_timestamp();
  perform * from public.ea_person_names(v_ids);
  insert into zeit values ('namen', extract(epoch from clock_timestamp() - v_t) * 1000);
end $$;
select cmp_ok((select ms from zeit where was = 'suche'), '<', 300::numeric, 'Suche bei 300 Aktiven < 300 ms');
select cmp_ok((select ms from zeit where was = 'namen'), '<', 300::numeric, 'Namen zu 50 IDs < 300 ms');
select is((select count(*)::int from public.ea_search_active_persons('Menge', 50)), 50, 'höchstens 50 Treffer');

select pg_temp.as_owner();
select * from finish();
rollback;
