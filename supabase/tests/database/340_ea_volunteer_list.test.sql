-- US-EA-02, US-EA-03 (EA spec T9 Teil, T4): ea_volunteer_list – Erwartete Ergebnisse (spec.md Abschnitt 9),
-- Suche, Filter, Sortierung, Paginierung, Spalten (R1, R2, R14, R32 AD, R34 AD).
-- Hinweis: Anton Muster (5, ruhend, Trainer:in mit Lizenz bis 2019) erfüllt R14 ebenso wie Max (20); die Tabelle
-- „Erwartete Ergebnisse“ nennt nur 20 – gemeldet als plan.md H3. Der Test folgt der Regel R14.
-- Seit dem Seed von Gruppen (GR spec.md 9) zusätzlich aktiv: 26 Lars Lehrer, 28 Sam Sechzehn (Funktion in Gruppe),
-- 31 Tom Ehemals (Funktion in Gruppe beendet), 32 Kim Kinderjugend (Amt Referent:in Kinder und Jugend).
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
create function pg_temp.referat(p_name text) returns uuid language sql as $$
  select id from public.ea_referate where name = p_name
$$;
create function pg_temp.gremium(p_name text) returns uuid language sql as $$
  select id from public.ea_gremien where name = p_name
$$;
create function pg_temp.qual(p_code text) returns uuid language sql as $$
  select id from public.ad_qualification_types where code = p_code
$$;

-- Standardaufruf je Testzugang
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select is((select coalesce(array_agg(right(l.id::text, 2)::int order by l.id), '{}') from public.ea_volunteer_list() l),
  array[4, 5, 9, 10, 19, 20, 21, 22, 26, 28, 31, 32], 'Admin: 4, 5, 9, 10, 19–22, 26, 28, 31, 32');
select is((select array_agg(right(l.id::text, 2)::int) from public.ea_volunteer_list() l),
  array[20, 31, 21, 32, 26, 19, 5, 4, 9, 22, 28, 10], 'Sortierung nach Nachname, dann Rufname bzw. Vorname (R2)');
select is((select l.total_count from public.ea_volunteer_list() l limit 1), 12::bigint, 'total_count');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select is((select coalesce(array_agg(right(l.id::text, 2)::int order by l.id), '{}') from public.ea_volunteer_list() l),
  array[4, 5, 9, 10, 19, 20, 21, 22, 26, 28, 31, 32], 'Geschäftsstelle wie Admin');

-- Spalten
select results_eq(
  $$ select referate, functions, positions, license_codes, worst_expiry, trainer_without_license
       from public.ea_volunteer_list() where id = 'a0000000-0000-4000-8000-000000000004' $$,
  $$ values ('{Klettern}'::text[], '{"Trainer:in – Klettern"}'::text[], '{}'::text[], '{TCSPI}'::text[], 'valid'::text, false) $$,
  'Toni: Referat, Funktion mit Referat, Lizenzkürzel, Ablauf gültig');
select results_eq(
  $$ select referate, functions, positions, worst_expiry, trainer_without_license
       from public.ea_volunteer_list() where id = 'a0000000-0000-4000-8000-000000000010' $$,
  $$ values ('{Ausbildung,Klettern}'::text[], '{"Trainer:in – Ausbildung","Helfer:in – Klettern"}'::text[], '{}'::text[], 'none'::text, true) $$,
  'Karl: zwei Referate nach sort_order, zwei Funktionen, ohne Lizenz (R14)');
select results_eq(
  $$ select referate, positions, license_codes, worst_expiry
       from public.ea_volunteer_list() where id = 'a0000000-0000-4000-8000-000000000009' $$,
  $$ values ('{Klettern}'::text[], '{"Referent:in – Klettern"}'::text[], '{}'::text[], 'none'::text) $$, 'Rita: Amt mit Referat');
select results_eq(
  $$ select license_codes, worst_expiry, trainer_without_license, volunteer_status::text, volunteer_status_since
       from public.ea_volunteer_list() where id = 'a0000000-0000-4000-8000-000000000020' $$,
  $$ values ('{TCSPI}'::text[], 'expired'::text, true, 'active'::text, date '2020-01-01') $$,
  'Max: abgelaufen, Trainer:in ohne gültige Lizenz, Status mit seit');
select results_eq(
  $$ select license_codes, worst_expiry, trainer_without_license from public.ea_volunteer_list()
      where id = 'a0000000-0000-4000-8000-000000000019' $$,
  $$ values ('{TCBO}'::text[], 'expiring'::text, false) $$, 'Lena: läuft ab, Lizenz noch gültig');
select results_eq(
  $$ select referate, functions, worst_expiry from public.ea_volunteer_list() where id = 'a0000000-0000-4000-8000-000000000021' $$,
  $$ values ('{}'::text[], '{}'::text[], 'none'::text) $$, 'Greta: kein Referat, keine Funktion');

-- Suche (R2, AK3)
select is((select array_agg(right(l.id::text, 2)::int order by l.id) from public.ea_volunteer_list(p_search => 'toni') l),
  array[4], 'Suche „toni“ findet Toni Muster');
select is((select array_agg(right(l.id::text, 2)::int order by l.id) from public.ea_volunteer_list(p_search => 'MUSTER') l),
  array[4, 5], 'Suche ohne Groß-/Kleinschreibung im Nachnamen');
select is((select array_agg(right(l.id::text, 2)::int order by l.id) from public.ea_volunteer_list(p_search => '  ') l),
  array[4, 5, 9, 10, 19, 20, 21, 22, 26, 28, 31, 32], 'leerer Suchbegriff = kein Filter');
select is_empty($$ select 1 from public.ea_volunteer_list(p_search => 'gibtesnicht') $$, 'Suche ohne Treffer (AK4)');
select pg_temp.as_owner();
update public.ea_persons set preferred_name = 'Zwerg' where id = 'a0000000-0000-4000-8000-000000000021';
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select is((select array_agg(right(l.id::text, 2)::int) from public.ea_volunteer_list(p_search => 'zwerg') l),
  array[21], 'Suche im Rufnamen');

-- Status (R1, R34 AD)
select is((select array_agg(right(l.id::text, 2)::int order by l.id) from public.ea_volunteer_list(p_status => '{left}') l),
  array[11], 'Geschäftsstelle: Statusfilter ausgeschieden → Olga (AK3)');
select is((select array_agg(right(l.id::text, 2)::int order by l.id) from public.ea_volunteer_list(p_status => '{active}') l),
  array[4, 9, 10, 19, 20, 21, 22, 26, 28, 31, 32], 'nur aktiv (Anton ruhend fehlt)');
select is_empty($$ select 1 from public.ea_volunteer_list(p_status => '{active,dormant,left}')
                    where id = 'a0000000-0000-4000-8000-000000000012' $$, 'Person 12 (ohne Status) erscheint nie');

-- Zuordnung
select is((select array_agg(right(l.id::text, 2)::int order by l.id)
             from public.ea_volunteer_list(p_referate => array[pg_temp.referat('Klettern')]) l),
  array[4, 9, 10, 19, 22], 'Referat Klettern');
select is((select array_agg(right(l.id::text, 2)::int order by l.id)
             from public.ea_volunteer_list(p_referate => array[pg_temp.referat('Ausbildung')]) l),
  array[5, 10], 'Referat Ausbildung');
select is((select array_agg(right(l.id::text, 2)::int order by l.id)
             from public.ea_volunteer_list(p_referate => array[pg_temp.referat('Klettern')], p_function => 'Trainer:in') l),
  array[4, 19], 'Referat Klettern und Funktion Trainer:in: dieselbe Eigenschaft (nicht Karl mit Trainer:in in Ausbildung)');
select is((select array_agg(right(l.id::text, 2)::int order by l.id) from public.ea_volunteer_list(p_function => 'Helfer:in') l),
  array[10, 22], 'Funktion Helfer:in');
select is((select array_agg(right(l.id::text, 2)::int order by l.id) from public.ea_volunteer_list(p_position => 'Referent:in') l),
  array[9, 32], 'Amt Referent:in');
select is((select array_agg(right(l.id::text, 2)::int order by l.id)
             from public.ea_volunteer_list(p_gremium => pg_temp.gremium('Beirat')) l),
  array[21], 'Gremium Beirat');

-- Qualifikation und Ablauf (R9, R14)
select is((select array_agg(right(l.id::text, 2)::int order by l.id)
             from public.ea_volunteer_list(p_qualification_type => pg_temp.qual('TCBO')) l),
  array[19], 'Qualifikationsart TCBO');
select is((select array_agg(right(l.id::text, 2)::int order by l.id)
             from public.ea_volunteer_list(p_discipline => 'Klettersport') l),
  array[4, 5, 19, 20], 'Sparte Klettersport');
select is((select array_agg(right(l.id::text, 2)::int order by l.id) from public.ea_volunteer_list(p_expiry => '{expired}') l),
  array[5, 20], 'Ablaufstatus abgelaufen');
select is((select array_agg(right(l.id::text, 2)::int order by l.id) from public.ea_volunteer_list(p_expiry => '{expiring}') l),
  array[19], 'Ablaufstatus läuft ab');
select is((select array_agg(right(l.id::text, 2)::int order by l.id)
             from public.ea_volunteer_list(p_expiry => '{valid,expiring}') l),
  array[4, 19], 'Ablaufstatus mehrfach');
select is((select array_agg(right(l.id::text, 2)::int order by l.id)
             from public.ea_volunteer_list(p_trainer_without_license => true) l),
  array[5, 10, 20], 'Trainer:in ohne gültige Lizenz: Max (AK2), Anton und Karl (R14, plan.md H3), nicht Lena');
select results_eq($$ select right(id::text, 2)::int from public.ea_volunteer_list(p_referate => array[pg_temp.referat('Klettern')], p_trainer_without_license => true) $$,
  $$ values (10) $$, 'Schnittmenge Referat Klettern und ohne gültige Lizenz: nur Karl (AK1, Schnittmenge je Person, plan.md H3)');

-- aktiv ohne Funktion oder Amt
select results_eq($$ select last_name from public.ea_volunteer_list(p_without_assignment => true) $$,
  $$ values ('Ehemals'::text) $$,
  'im Seed ohne Funktion oder Amt nur Tom (Funktion in Gruppe beendet; laufende zählt, GR plan.md H6)');
select lives_ok($$ select public.ea_create_volunteer('Ohne', 'Zuordnung', null, null, null, null, null) $$,
  'Geschäftsstelle legt Person ohne Zuordnung an');
select results_eq($$ select last_name from public.ea_volunteer_list(p_without_assignment => true) $$,
  $$ values ('Ehemals'::text), ('Zuordnung') $$, 'Filter „aktiv ohne Funktion oder Amt“');

-- Paginierung
select is((select count(*)::int from public.ea_volunteer_list(p_limit => 3)), 3, 'p_limit 3');
select is((select l.total_count from public.ea_volunteer_list(p_limit => 3) l limit 1), 13::bigint, 'total_count unabhängig von limit');
select is((select array_agg(right(l.id::text, 2)::int) from public.ea_volunteer_list(p_limit => 3, p_offset => 12) l),
  array[10], 'p_offset (Zuordnung sortiert vor Zweireferat)');
select is((select count(*)::int from public.ea_volunteer_list(p_limit => 0)), 1, 'p_limit unter 1 → 1');
select is((select count(*)::int from public.ea_volunteer_list(p_limit => 500)), 13, 'p_limit über 200 → begrenzt, kein Fehler');
select is((select count(*)::int from public.ea_volunteer_list(p_offset => -5)), 13, 'negativer Offset → 0');

-- Referent:in Klettern (R32 AD): nur eigene Referate, nie ausgeschieden, kein Gremium
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select is((select coalesce(array_agg(right(l.id::text, 2)::int order by l.id), '{}') from public.ea_volunteer_list() l),
  array[4, 9, 10, 19, 22], 'Referent:in: 4, 9, 10, 19, 22 (AK2)');
select is((select l.total_count from public.ea_volunteer_list() l limit 1), 5::bigint, 'Referent:in total_count');
select results_eq($$ select right(id::text, 2)::int from public.ea_volunteer_list(p_trainer_without_license => true) $$,
  $$ values (10) $$, 'Referent:in: Trainer:in ohne Lizenz nur Karl (Anton und Max nicht sichtbar)');
select is_empty($$ select 1 from public.ea_volunteer_list(p_status => '{left}') $$, 'Referent:in: ausgeschieden leer');
select is_empty($$ select 1 from public.ea_volunteer_list(p_gremium => pg_temp.gremium('Beirat')) $$, 'Referent:in: Greta unsichtbar');
select results_eq(
  $$ select referate, functions from public.ea_volunteer_list() where id = 'a0000000-0000-4000-8000-000000000010' $$,
  $$ values ('{Ausbildung,Klettern}'::text[], '{"Trainer:in – Ausbildung","Helfer:in – Klettern"}'::text[]) $$,
  'Referent:in sieht bei Karl auch das Referat Ausbildung (Lesestufe alle)');

-- Vorstand: nichts
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select is_empty($$ select 1 from public.ea_volunteer_list() $$, 'Vorstand sieht niemanden');
select is_empty($$ select 1 from public.ea_volunteer_list(p_status => '{active,dormant,left}') $$, 'Vorstand auch nicht mit allen Status');

select pg_temp.as_owner();
select * from finish();
rollback;
