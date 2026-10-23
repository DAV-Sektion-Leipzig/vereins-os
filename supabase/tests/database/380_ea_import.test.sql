-- US-EA-17, US-EA-18 (EA spec T9 Teil, T7): ea_import_volunteers – nur service_role, Probelauf, Fehler, Warnungen,
-- Schreiben in einer Transaktion (A3). Zeilen in der Form, die das Migrationsskript übergibt (contracts/migration-script.md).
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

create function pg_temp.as_user(p_user uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', p_user, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
end $$;
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

-- Fünf Beispielzeilen nach spec.md Abschnitt 9 (fiktiv)
create function pg_temp.rows() returns jsonb language sql as $$
  select '[
    {"row": 2, "nachname": "Kletter", "vorname": "Clara", "aktiv": true, "aktiv_seit": "2021-04-01", "referate": ["Klettern"],
     "te_pro_woche": 2, "l1_art": "TCSPI", "l1_nummer": "IMP-0001", "l1_gueltig_bis": "2027-12-31", "l1_erworben_am": "2023-05-15",
     "l2_art": "TCBO", "email": "clara.kletter@example.test"},
    {"row": 3, "nachname": "Ruhend", "vorname": "Rudi", "aktiv": false, "referate": ["Klettern", "Ausbildung"],
     "l1_art": "TCSP", "l1_gueltig_bis": "2019-12-31"},
    {"row": 4, "nachname": "Helfer", "vorname": "Hanna", "aktiv": true, "referate": ["Touren"],
     "schluessel_k4": "K4-77", "dav360": "x", "gruppe": "Kindergruppe Dienstag"},
    {"row": 5, "nachname": "Fortbildung", "vorname": "Fritz", "aktiv": true, "referate": ["Ausbildung"],
     "fb": {"2019": "Sicherungstraining", "2023": "Kletterhallen-Update"},
     "qualifikationen": [{"code": "EH", "date": "2025-02-01", "valid_until": "2027-02-01"}]},
    {"row": 6, "nachname": "Muster", "vorname": "Toni", "aktiv": true, "referate": ["Klettern"],
     "kontoinhaber": "Toni Muster", "iban": "de89 3704 0044 0532 0130 00"}
  ]'::jsonb
$$;

create function pg_temp.messages(p_result jsonb, p_kind text) returns text[] language sql as $$
  select coalesce(array_agg(m ->> 'message' order by (m ->> 'row')::int, m ->> 'message'), '{}')
    from jsonb_array_elements(p_result -> p_kind) m
$$;

create temp table result (kind text primary key, value jsonb);
grant all on result to service_role, authenticated;

-- Rechte (R-EA-10)
select ok(not has_function_privilege('authenticated', 'public.ea_import_volunteers(jsonb, date, boolean)', 'EXECUTE'),
  'authenticated darf ea_import_volunteers nicht ausführen');
select ok(not has_function_privilege('anon', 'public.ea_import_volunteers(jsonb, date, boolean)', 'EXECUTE'), 'anon auch nicht');
select ok(has_function_privilege('service_role', 'public.ea_import_volunteers(jsonb, date, boolean)', 'EXECUTE'), 'service_role darf');
select ok(not has_function_privilege('authenticated', 'public.ea_import_qualification(text)', 'EXECUTE'),
  'Hilfsfunktion nicht für authenticated');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select throws_ok($$ select public.ea_import_volunteers('[]', current_date, true) $$, '42501', null,
  'test.admin erhält beim Aufruf einen Rechtefehler');

-- Probelauf (US-EA-17)
select pg_temp.as_owner();
create temp table before as select count(*) as n from public.ea_persons;
grant select on before to service_role;
select pg_temp.as_service();
insert into result values ('dry', public.ea_import_volunteers(pg_temp.rows(), '2026-10-01', true));
select pg_temp.as_owner();

select is((select value -> 'written' from result where kind = 'dry'), 'false'::jsonb, 'Probelauf schreibt nicht');
select is((select count(*) from public.ea_persons), (select n from before), 'keine neuen Personen');
select is((select pg_temp.messages(value, 'errors') from result where kind = 'dry'), '{}'::text[], 'Beispiel ohne Fehler');
select is((select value -> 'counts' from result where kind = 'dry'),
  '{"persons": 5, "function": 6, "license": 3, "issued_item": 1, "external_access": 1, "further_training": 2,
    "qualification": 1, "contact": 1, "bank_account": 1, "valid_from_cutoff": 11}'::jsonb,
  'Zählung je Art und gültig von = Stichtag (R17)');
select ok((select pg_temp.messages(value, 'warnings') from result where kind = 'dry') @> array[
    'Zeile 2: Lizenz TCBO ohne gültig bis, berechnet 31.12.2030',
    'Zeile 2: 2 Lizenzen, 1 Lizenznummern',
    'Zeile 3: 1 Lizenzen, 0 Lizenznummern',
    'Zeile 4: Gruppe Kindergruppe Dienstag',
    'Zeile 6: Dublettenverdacht zu Toni Muster (vorhanden)'],
  'Warnungen: berechnetes gültig bis, Lizenznummern, Gruppe, Dublettenverdacht zu Toni Muster (US-EA-17 AK3)');

-- Dublettenverdacht innerhalb der Datei
select pg_temp.as_service();
insert into result values ('file', public.ea_import_volunteers('[
  {"row": 2, "nachname": "Doppelt", "vorname": "Johanna", "aktiv": true},
  {"row": 3, "nachname": "doppelt", "vorname": "Johanne", "aktiv": true}]', '2026-10-01', true));
select pg_temp.as_owner();
select is((select pg_temp.messages(value, 'warnings') from result where kind = 'file'),
  array['Zeile 3: Dublettenverdacht zu Johanna Doppelt (Zeile 2)'], 'Dublettenverdacht innerhalb der Datei');

-- Fehlerfälle (Fehler verhindern den Lauf)
select pg_temp.as_service();
insert into result values ('errors', public.ea_import_volunteers('[
  {"row": 2, "nachname": "Fehler", "vorname": "Ute", "aktiv": true, "l1_art": "XYZ"},
  {"row": 3, "nachname": "Fehler", "vorname": "Udo", "aktiv": true, "l1_art": "EH"},
  {"row": 4, "nachname": "Fehler", "vorname": "Uwe", "aktiv": true, "referate": ["Gibtsnicht"]},
  {"row": 5, "nachname": "Fehler", "vorname": "Ulla", "aktiv": true, "kontoinhaber": "Ulla Fehler", "iban": "DE00 1234"},
  {"row": 6, "vorname": "Ohne", "aktiv": true},
  {"row": 7, "nachname": "Fehler", "vorname": "Uta", "aktiv": true, "geschlecht": "unbekannt",
   "qualifikationen": [{"code": "Gibtsnicht"}]}]', '2026-10-01', false));
select pg_temp.as_owner();
select is((select pg_temp.messages(value, 'errors') from result where kind = 'errors'), array[
    'Zeile 2: Qualifikationsart XYZ unbekannt',
    'Zeile 3: EH ist keine Lizenz',
    'Zeile 4: Referat Gibtsnicht unbekannt',
    'Zeile 5: Die IBAN ist ungültig.',
    'Zeile 6: nachname fehlt',
    'Zeile 7: Qualifikationsart Gibtsnicht unbekannt',
    'Zeile 7: Wert unbekannt für Geschlecht unbekannt'],
  'Fehler: unbekanntes Kürzel (US-EA-17 AK2), keine Lizenz, Referat, IBAN, Nachname, Auswahlwert');
select is((select value -> 'written' from result where kind = 'errors'), 'false'::jsonb, 'Lauf mit Fehlern schreibt nichts (A3)');
select is((select count(*) from public.ea_persons where last_name = 'Fehler'), 0::bigint, 'keine Person aus der Fehlerdatei');

-- Lauf ohne Fehler (US-EA-18)
select pg_temp.as_service();
insert into result values ('run', public.ea_import_volunteers(pg_temp.rows(), '2026-10-01', false));
select pg_temp.as_owner();
select is((select value -> 'written' from result where kind = 'run'), 'true'::jsonb, 'Lauf schreibt');
select is((select count(*) from public.ea_persons where created_in = 'script'), 5::bigint, 'fünf Personen mit created_in = script');
select is((select count(*) from public.ea_persons where created_in = 'script' and created_by is not null), 0::bigint, 'created_by leer');
select results_eq(
  $$ select last_name, volunteer_status::text, volunteer_status_since from public.ea_persons
      where created_in = 'script' order by last_name, first_name $$,
  $$ values ('Fortbildung'::text, 'active'::text, date '2026-10-01'), ('Helfer', 'active', date '2026-10-01'),
            ('Kletter', 'active', date '2026-10-01'), ('Muster', 'active', date '2026-10-01'),
            ('Ruhend', 'dormant', date '2026-10-01') $$,
  'Status aktiv bzw. ruhend ab Stichtag');
select is((select count(*) from public.ea_volunteer_status_history h join public.ea_persons p on p.id = h.person_id
            where p.created_in = 'script'), 5::bigint, 'je Person ein Historieneintrag');

create function pg_temp.props(p_last text, p_key text) returns setof public.ea_properties language sql as $$
  select pr.* from public.ea_properties pr
    join public.ea_persons p on p.id = pr.person_id and p.created_in = 'script' and p.last_name = p_last
    join public.ea_property_types t on t.id = pr.property_type_id and t.system_key = p_key
$$;

select results_eq(
  $$ select field_values, r.name, valid_from from pg_temp.props('Kletter', 'function') f
       join public.ea_referate r on r.id = f.related_referat_id $$,
  $$ values ('{"function": "Trainer:in", "training_units_per_week": 2}'::jsonb, 'Klettern'::text, date '2021-04-01') $$,
  'Lizenz → Funktion Trainer:in mit Trainingseinheiten, gültig von = aktiv_seit (R15)');
select results_eq(
  $$ select field_values ->> 'function', valid_from from pg_temp.props('Helfer', 'function') $$,
  $$ values ('Helfer:in'::text, date '2026-10-01') $$, 'ohne Lizenz → Helfer:in ab Stichtag (R15)');
select is((select count(*) from pg_temp.props('Ruhend', 'function') where field_values ->> 'function' = 'Trainer:in'), 2::bigint,
  'zwei Referate → zwei Funktionen Trainer:in (auch mit abgelaufener Lizenz)');
select is((select q.code from pg_temp.props('Ruhend', 'license') l
             join public.ad_qualification_types q on q.id = (l.field_values ->> 'qualification_type')::uuid), 'TCSP',
  'historische Qualifikationsart TCSP erlaubt (R27 AD ohne Nutzerkontext)');
select results_eq(
  $$ select field_values ->> 'valid_until', valid_from from pg_temp.props('Kletter', 'license') order by valid_from $$,
  $$ values ('2027-12-31'::text, date '2023-05-15'), ('2030-12-31', date '2026-10-01') $$,
  'Lizenzen: gültig von = erworben am bzw. Stichtag, gültig bis berechnet (R5)');
select results_eq(
  $$ select field_values ->> 'title', valid_from from pg_temp.props('Fortbildung', 'further_training') order by valid_from $$,
  $$ values ('Sicherungstraining'::text, date '2019-01-01'), ('Kletterhallen-Update', date '2023-01-01') $$,
  'Fortbildungen mit gültig von 01.01. des Jahres');
select is((select field_values ->> 'iban' from pg_temp.props('Muster', 'bank_account')), 'DE89370400440532013000',
  'IBAN normalisiert (R13)');
select results_eq(
  $$ select field_values from pg_temp.props('Helfer', 'issued_item') $$,
  $$ values ('{"item": "Schlüssel K4", "number": "K4-77"}'::jsonb) $$, 'Ausgabe Schlüssel K4 mit Nummer');
select results_eq(
  $$ select field_values from pg_temp.props('Helfer', 'external_access') $$,
  $$ values ('{"system": "DAV360"}'::jsonb) $$, 'Zugang extern DAV360');

select * from finish();
rollback;
