-- B-07 (Sicherheits- und Code-Review), US-EA-18: Wiederholungsschutz von ea_import_volunteers.
-- Erster schreibender Lauf gelingt; danach bricht ein zweiter schreibender Lauf mit EA_IMPORT_ALREADY_RUN ab,
-- und der Probelauf meldet den Befund als Fehler im Bericht. Fiktive Zeilen (CLAUDE.md, keine Echtdaten).
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

create function pg_temp.as_service() returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', '', true);
  execute 'set local role service_role';
end $$;
create function pg_temp.as_owner() returns void language plpgsql as $$
begin
  execute 'reset role';
  perform set_config('request.jwt.claims', '', true);
end $$;

create function pg_temp.rows() returns jsonb language sql as $$
  select '[
    {"row": 2, "nachname": "Einmalig", "vorname": "Erna", "aktiv": true, "referate": ["Touren"]},
    {"row": 3, "nachname": "Einmalig", "vorname": "Egon", "aktiv": false,
     "kontoinhaber": "Egon Einmalig", "iban": "DE89370400440532013000"}
  ]'::jsonb
$$;

create temp table result (kind text primary key, value jsonb);
grant all on result to service_role;

-- Ausgangslage: Seed ohne Personen aus dem Migrationsskript
select is((select count(*) from public.ea_persons where created_in = 'script'), 0::bigint,
  'vor dem ersten Lauf keine Personen mit created_in = script');

-- Probelauf vor dem ersten Lauf: kein Wiederholungsbefund
select pg_temp.as_service();
insert into result values ('dry_before', public.ea_import_volunteers(pg_temp.rows(), '2026-10-01', true));
select pg_temp.as_owner();
select is((select value -> 'errors' from result where kind = 'dry_before'), '[]'::jsonb, 'Probelauf vorher ohne Fehler');

-- Erster schreibender Lauf
select pg_temp.as_service();
insert into result values ('run', public.ea_import_volunteers(pg_temp.rows(), '2026-10-01', false));
select pg_temp.as_owner();
select is((select value -> 'written' from result where kind = 'run'), 'true'::jsonb, 'erster Lauf schreibt');
select is((select count(*) from public.ea_persons where created_in = 'script'), 2::bigint, 'zwei Personen angelegt');
select is((select count(*) from public.ea_properties pr join public.ea_persons p on p.id = pr.person_id
             join public.ea_property_types t on t.id = pr.property_type_id
            where p.created_in = 'script' and t.system_key in ('function', 'bank_account')), 2::bigint,
  'Funktion und Bankverbindung angelegt');

-- Zweiter schreibender Lauf: Abbruch, nichts doppelt
select pg_temp.as_service();
select throws_ok(
  $$ select public.ea_import_volunteers(pg_temp.rows(), '2026-10-01', false) $$,
  'P0001', 'EA_IMPORT_ALREADY_RUN', 'zweiter schreibender Lauf bricht mit EA_IMPORT_ALREADY_RUN ab');
select throws_ok(
  $$ select public.ea_import_volunteers('[{"row": 2, "nachname": "Anders", "vorname": "Anna", "aktiv": true}]', '2026-10-01', false) $$,
  'P0001', 'EA_IMPORT_ALREADY_RUN', 'auch mit einer anderen Datei kein zweiter Lauf');
select pg_temp.as_owner();
select is((select count(*) from public.ea_persons where created_in = 'script'), 2::bigint, 'weiterhin zwei Personen');
select is((select count(*) from public.ea_persons where last_name = 'Anders'), 0::bigint, 'keine Person aus dem zweiten Lauf');

-- Probelauf nach dem ersten Lauf: Befund als Fehler im Bericht, nichts geschrieben
select pg_temp.as_service();
insert into result values ('dry_after', public.ea_import_volunteers(pg_temp.rows(), '2026-10-01', true));
select pg_temp.as_owner();
select is((select value -> 'written' from result where kind = 'dry_after'), 'false'::jsonb, 'Probelauf schreibt nicht');
select is(
  (select value -> 'errors' -> 0 from result where kind = 'dry_after'),
  jsonb_build_object('row', 0, 'code', 'EA_IMPORT_ALREADY_RUN', 'message',
    'Der Import wurde bereits ausgeführt (2 Personen aus dem Migrationsskript vorhanden). '
    'Ein zweiter Lauf würde alle Personen doppelt anlegen.'),
  'Probelauf meldet den Wiederholungsbefund als Fehler');
select is((select jsonb_array_length(value -> 'errors') from result where kind = 'dry_after'), 1,
  'sonst keine Fehler');
select is((select value -> 'counts' -> 'persons' from result where kind = 'dry_after'), '2'::jsonb,
  'Prüfung und Zählung laufen weiter');

-- Rechte unverändert
select ok(not has_function_privilege('authenticated', 'public.ea_import_volunteers(jsonb, date, boolean)', 'EXECUTE'),
  'authenticated darf ea_import_volunteers weiterhin nicht ausführen');
select ok(not has_function_privilege('anon', 'public.ea_import_volunteers(jsonb, date, boolean)', 'EXECUTE'), 'anon auch nicht');
select ok(has_function_privilege('service_role', 'public.ea_import_volunteers(jsonb, date, boolean)', 'EXECUTE'), 'service_role darf');

select * from finish();
rollback;
