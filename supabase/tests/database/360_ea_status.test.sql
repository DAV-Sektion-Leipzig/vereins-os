-- US-EA-08, US-EA-09, US-EA-10 (EA spec T9 Teil, T6): ea_change_volunteer_status (R18, R19, R33 AD) und
-- ea_leave (R8, R20, A2) je Testzugang.
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
create function pg_temp.error_detail(p_sql text) returns text language plpgsql as $$
declare v_detail text;
begin
  execute p_sql;
  return null;
exception when others then
  get stacked diagnostics v_detail = pg_exception_detail;
  return v_detail;
end $$;
create function pg_temp.status(p_person uuid) returns text language sql as $$
  select volunteer_status::text || ' ' || volunteer_status_since::text from public.ea_persons where id = p_person
$$;

-- Status ändern (US-EA-08 AK1): Geschäftsstelle setzt Toni auf ruhend ab 01.11.2026
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select lives_ok($$ select public.ea_change_volunteer_status('a0000000-0000-4000-8000-000000000004', 'dormant', '2026-11-01') $$,
  'Geschäftsstelle setzt Toni auf ruhend');
select pg_temp.as_owner();
select is(pg_temp.status('a0000000-0000-4000-8000-000000000004'), 'dormant 2026-11-01', 'Status und seit');
select results_eq(
  $$ select status::text, valid_from, set_by from public.ea_volunteer_status_history
      where person_id = 'a0000000-0000-4000-8000-000000000004' order by id desc limit 1 $$,
  $$ values ('dormant'::text, date '2026-11-01', 'b0000000-0000-4000-8000-000000000002'::uuid) $$, 'Historie mit wer und ab wann');

-- R19, R18, „ausgeschieden“ nur über ea_leave
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select throws_ok($$ select public.ea_change_volunteer_status('a0000000-0000-4000-8000-000000000004', 'dormant', current_date) $$,
  'P0001', 'EA_STATUS_UNCHANGED', 'gleicher Status (R19)');
select throws_ok($$ select public.ea_change_volunteer_status('a0000000-0000-4000-8000-000000000004', 'active', (current_date + interval '1 year')::date + 1) $$,
  'P0001', 'EA_STATUS_DATE', 'Datum später als heute + 1 Jahr (R18)');
select is(pg_temp.error_detail($$ select public.ea_change_volunteer_status('a0000000-0000-4000-8000-000000000004', 'active', (current_date + interval '1 year')::date + 1) $$),
  to_char(current_date + interval '1 year', 'DD.MM.YYYY'), 'Grenzdatum TT.MM.JJJJ im detail');
select lives_ok($$ select public.ea_change_volunteer_status('a0000000-0000-4000-8000-000000000004', 'active', (current_date + interval '1 year')::date) $$,
  'genau heute + 1 Jahr erlaubt');
select throws_ok($$ select public.ea_change_volunteer_status('a0000000-0000-4000-8000-000000000019', 'left', current_date) $$,
  'P0001', 'EA_STATUS_FORBIDDEN', '„ausgeschieden“ nur über ea_leave');
select lives_ok($$ select public.ea_change_volunteer_status('a0000000-0000-4000-8000-000000000005', 'active', current_date) $$,
  'Anton (ruhend) wieder aktiv (AK3)');
select lives_ok($$ select public.ea_change_volunteer_status('a0000000-0000-4000-8000-000000000011', 'active', current_date) $$,
  'Olga (ausgeschieden) wieder aktiv ohne Zuordnung (US-EA-10 AK3)');
select throws_ok($$ select public.ea_change_volunteer_status('a0000000-0000-4000-8000-000000000002', 'active', current_date) $$,
  'P0001', 'EA_STATUS_FORBIDDEN', 'Person ohne Ehrenamtsstatus');

-- Rechte (R33 AD, AK5)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select lives_ok($$ select public.ea_change_volunteer_status('a0000000-0000-4000-8000-000000000010', 'dormant', current_date) $$,
  'Referent:in Klettern setzt Karl (Klettern und Ausbildung) auf ruhend');
select throws_ok($$ select public.ea_change_volunteer_status('a0000000-0000-4000-8000-000000000020', 'dormant', current_date) $$,
  'P0001', 'EA_STATUS_FORBIDDEN', 'Referent:in Klettern ändert Max (Kinder und Jugend) nicht');
select throws_ok($$ select public.ea_change_volunteer_status('a0000000-0000-4000-8000-000000000011', 'dormant', current_date) $$,
  'P0001', 'EA_STATUS_FORBIDDEN', 'Referent:in ändert unsichtbare Person nicht (keine Auskunft über Existenz)');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select throws_ok($$ select public.ea_change_volunteer_status('a0000000-0000-4000-8000-000000000004', 'dormant', current_date) $$,
  'P0001', 'EA_STATUS_FORBIDDEN', 'Vorstand ändert keinen Status');
select throws_ok($$ select public.ea_leave('a0000000-0000-4000-8000-000000000004', current_date, '{}') $$,
  'P0001', 'EA_STATUS_FORBIDDEN', 'Vorstand setzt niemanden auf ausgeschieden');

-- Ausscheiden (US-EA-09 AK1, AK2): Sven zum 31.12.2026 mit Funktion; Ausgabe und Zugang bleiben
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select lives_ok($$ select public.ea_leave('a0000000-0000-4000-8000-000000000022', '2026-12-31',
  array['e0000000-0000-4000-8000-000000000021'::uuid]) $$, 'Geschäftsstelle: Sven ausgeschieden zum 31.12.2026');
select pg_temp.as_owner();
select is(pg_temp.status('a0000000-0000-4000-8000-000000000022'), 'left 2026-12-31', 'Status ausgeschieden seit 31.12.2026');
select results_eq(
  $$ select id, valid_to from public.ea_properties where person_id = 'a0000000-0000-4000-8000-000000000022' order by id $$,
  $$ values ('e0000000-0000-4000-8000-000000000021'::uuid, date '2026-12-31'),
            ('e0000000-0000-4000-8000-000000000022', null::date),
            ('e0000000-0000-4000-8000-000000000023', null),
            ('e0000000-0000-4000-8000-000000000024', null) $$,
  'Funktion beendet, Ausgabe, Zugang und Bankverbindung unverändert (AK2)');
select is((select status::text from public.ea_volunteer_status_history
            where person_id = 'a0000000-0000-4000-8000-000000000022' order by id desc limit 1), 'left', 'Historie');

-- leeres Array erlaubt; bereits ausgeschieden → unverändert
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select lives_ok($$ select public.ea_leave('a0000000-0000-4000-8000-000000000021', current_date, '{}') $$, 'Greta ohne Beenden');
select throws_ok($$ select public.ea_leave('a0000000-0000-4000-8000-000000000021', current_date, '{}') $$,
  'P0001', 'EA_STATUS_UNCHANGED', 'schon ausgeschieden (R19)');
select throws_ok($$ select public.ea_leave('a0000000-0000-4000-8000-000000000019', (current_date + interval '1 year')::date + 1, '{}') $$,
  'P0001', 'EA_STATUS_DATE', 'Datum zu weit in der Zukunft (R18)');

-- R20: fremde, beendete, zu junge oder nicht schreibbare Eigenschaft → nichts geändert
select throws_ok($$ select public.ea_leave('a0000000-0000-4000-8000-000000000019', current_date,
  array['e0000000-0000-4000-8000-000000000017'::uuid]) $$,
  'P0001', 'EA_LEAVE_PROPERTY', 'Eigenschaft einer anderen Person (Max)');
select throws_ok($$ select public.ea_leave('a0000000-0000-4000-8000-000000000004', '2025-02-01',
  array['e0000000-0000-4000-8000-000000000002'::uuid]) $$,
  'P0001', 'EA_LEAVE_PROPERTY', 'Austritt vor Beginn der Funktion (gültig von 01.03.2025)');
select pg_temp.as_owner();
update public.ea_properties set valid_to = current_date - 1 where id = 'e0000000-0000-4000-8000-000000000004';
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select throws_ok($$ select public.ea_leave('a0000000-0000-4000-8000-000000000004', current_date,
  array['e0000000-0000-4000-8000-000000000004'::uuid]) $$,
  'P0001', 'EA_LEAVE_PROPERTY', 'beendete Eigenschaft');
select throws_ok($$ select public.ea_leave('a0000000-0000-4000-8000-000000000004', current_date,
  array['e0000000-0000-4000-8000-000000000002'::uuid, '00000000-0000-4000-8000-000000000000'::uuid]) $$,
  'P0001', 'EA_LEAVE_PROPERTY', 'unbekannte ID');
select pg_temp.as_owner();
select is(pg_temp.status('a0000000-0000-4000-8000-000000000004'), 'active ' || (current_date + interval '1 year')::date::text,
  'Toni unverändert: bei jedem Fehler wird nichts geändert (AK6)');
select is((select valid_to from public.ea_properties where id = 'e0000000-0000-4000-8000-000000000002'), null, 'Funktion von Toni unverändert');

-- Referent:in Klettern bei Karl (AK3): Funktion im Referat Ausbildung nicht beendbar, nichts geändert
select pg_temp.as_owner();
select set_config('ea.status_change', 'on', true);
update public.ea_persons set volunteer_status = 'active' where id = 'a0000000-0000-4000-8000-000000000010';
select set_config('ea.status_change', '', true);
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select throws_ok($$ select public.ea_leave('a0000000-0000-4000-8000-000000000010', current_date,
  array['e0000000-0000-4000-8000-000000000010'::uuid, 'e0000000-0000-4000-8000-000000000011'::uuid]) $$,
  'P0001', 'EA_LEAVE_PROPERTY', 'Funktion im fremden Referat Ausbildung nicht beendbar (R20, R41 AD)');
select pg_temp.as_owner();
select is((select volunteer_status::text from public.ea_persons where id = 'a0000000-0000-4000-8000-000000000010'), 'active',
  'Karl weiter aktiv');
select is((select count(*)::int from public.ea_properties where person_id = 'a0000000-0000-4000-8000-000000000010' and valid_to is not null), 0,
  'keine Eigenschaft von Karl beendet');

-- Referent:in beendet nur die Funktion im eigenen Referat; danach ist Karl für sie unsichtbar (AK5)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select lives_ok($$ select public.ea_leave('a0000000-0000-4000-8000-000000000010', current_date,
  array['e0000000-0000-4000-8000-000000000010'::uuid]) $$, 'Referent:in: Karl ausgeschieden, Funktion Klettern beendet');
select is_empty($$ select 1 from public.ea_persons where id = 'a0000000-0000-4000-8000-000000000010' $$,
  'Karl für die Referent:in nicht mehr sichtbar');
select pg_temp.as_owner();
select results_eq(
  $$ select id, valid_to from public.ea_properties where person_id = 'a0000000-0000-4000-8000-000000000010' and valid_to is not null $$,
  $$ values ('e0000000-0000-4000-8000-000000000010'::uuid, current_date) $$, 'nur die Funktion Klettern beendet');
select is((select volunteer_status::text from public.ea_persons where id = 'a0000000-0000-4000-8000-000000000010'), 'left', 'Karl ausgeschieden');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select is((select count(*)::int from public.ea_volunteer_list(p_status => '{left}')
            where id = 'a0000000-0000-4000-8000-000000000010'), 1, 'Geschäftsstelle findet Karl über den Statusfilter');

-- rückdatiertes Ausscheiden durch die Referent:in (Sichtbarkeit darf nicht mitten im Vorgang verloren gehen)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select lives_ok($$ select public.ea_leave('a0000000-0000-4000-8000-000000000019', current_date - 7,
  array['e0000000-0000-4000-8000-000000000015'::uuid]) $$, 'Referent:in: Lena rückdatiert ausgeschieden');
select pg_temp.as_owner();
select is(pg_temp.status('a0000000-0000-4000-8000-000000000019'), 'left ' || (current_date - 7)::text, 'Status rückdatiert');
select is((select valid_to from public.ea_properties where id = 'e0000000-0000-4000-8000-000000000015'), current_date - 7,
  'Funktion zum selben Datum beendet');

-- Vorstand und Nutzer ohne Pfad: nichts
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select throws_ok($$ select public.ea_leave('a0000000-0000-4000-8000-000000000020', current_date, '{}') $$,
  'P0001', 'EA_STATUS_FORBIDDEN', 'Vorstand');

select pg_temp.as_owner();
select * from finish();
rollback;
