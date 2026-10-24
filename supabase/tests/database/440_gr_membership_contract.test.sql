-- US-GR-08, US-GR-11 (GR spec T5, T10): Teilnahme nur mit Vertrag (R16), Vertragsprüfung (R4–R6, R27), Folgevertrag
-- (R8a), Kündigung und „Teilnahme bis“ (R8, R8b), Vertragsstatus.
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
-- gültiger Vertrag für Mia (23) mit Inhaberin Jana (24); einzelne Felder überschreibbar
create function pg_temp.contract(p_patch jsonb default '{}') returns jsonb language sql as $$
  select jsonb_build_object(
    'holder_person_id', 'a0000000-0000-4000-8000-000000000024', 'starts_on', '2026-02-01',
    'account_holder', 'Jana Fiktiv', 'iban', 'DE89 3704 0044 0532 0130 00', 'mandate_reference', 'TEST-GR-NEU-1',
    'mandate_signed_on', '2026-01-20', 'purpose', 'Beitrag Test', 'monthly_amount', 20) || p_patch
$$;

select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');

-- Mia (23) zusätzlich in Test 2 aufnehmen, ohne offene Aufnahme (US-GR-08 AK4)
select throws_ok($$ select public.gr_admit('a0000000-0000-4000-8000-000000000023', 'c0000000-0000-4000-8000-000000000002',
                                           date '2026-02-01', null) $$,
  'P0001', 'GR_CONTRACT_REQUIRED', 'Teilnahme nur mit Vertrag (R16)');
select throws_ok($$ select public.gr_admit('a0000000-0000-4000-8000-000000000023', 'c0000000-0000-4000-8000-000000000002',
                                           date '2026-02-01', pg_temp.contract('{"purpose": ""}')) $$,
  'P0001', 'GR_CONTRACT_FIELDS_REQUIRED', 'alle Vertragsangaben Pflicht (R27)');
select throws_ok($$ select public.gr_admit('a0000000-0000-4000-8000-000000000023', 'c0000000-0000-4000-8000-000000000002',
                     date '2026-02-01', pg_temp.contract('{"holder_person_id": "a0000000-0000-4000-8000-000000000029"}')) $$,
  'P0001', 'GR_HOLDER_INVALID', 'Inhaber:in muss erziehungsberechtigt sein (R4)');
select throws_ok($$ select public.gr_admit('a0000000-0000-4000-8000-000000000023', 'c0000000-0000-4000-8000-000000000002',
                     date '2026-02-01', pg_temp.contract('{"holder_person_id": "a0000000-0000-4000-8000-000000000023"}')) $$,
  'P0001', 'GR_HOLDER_INVALID', 'minderjähriges Kind nicht selbst Inhaber:in (R4)');
select throws_ok($$ select public.gr_admit('a0000000-0000-4000-8000-000000000023', 'c0000000-0000-4000-8000-000000000002',
                     date '2026-02-01', pg_temp.contract('{"iban": "DE00 1234"}')) $$,
  'P0001', 'GR_IBAN_INVALID', 'IBAN-Prüfsumme (R5)');
select throws_ok($$ select public.gr_admit('a0000000-0000-4000-8000-000000000023', 'c0000000-0000-4000-8000-000000000002',
                     date '2026-02-01', pg_temp.contract('{"mandate_reference": "test-gr-23-1"}')) $$,
  'P0001', 'GR_MANDATE_TAKEN', 'Mandatsreferenz ohne Groß-/Kleinschreibung eindeutig (R6)');
select throws_ok($$ select public.gr_admit('a0000000-0000-4000-8000-000000000023', 'c0000000-0000-4000-8000-000000000002',
                     date '2026-02-01', pg_temp.contract('{"mandate_reference": "ABC#1"}')) $$,
  'P0001', 'GR_MANDATE_FORMAT', 'Mandatsreferenz Zeichensatz (R27)');
select throws_ok($$ select public.gr_admit('a0000000-0000-4000-8000-000000000023', 'c0000000-0000-4000-8000-000000000002',
                     date '2026-02-01', pg_temp.contract(jsonb_build_object('mandate_reference', repeat('A', 36)))) $$,
  'P0001', 'GR_MANDATE_FORMAT', 'Mandatsreferenz höchstens 35 Zeichen (R27)');
select throws_ok($$ select public.gr_admit('a0000000-0000-4000-8000-000000000023', 'c0000000-0000-4000-8000-000000000002',
                     date '2026-02-01', pg_temp.contract(jsonb_build_object('account_holder', repeat('A', 71)))) $$,
  'P0001', 'GR_TEXT_TOO_LONG', 'Kontoinhaber:in höchstens 70 Zeichen (R27)');
select throws_ok($$ select public.gr_admit('a0000000-0000-4000-8000-000000000023', 'c0000000-0000-4000-8000-000000000002',
                     date '2026-02-01', pg_temp.contract(jsonb_build_object('purpose', repeat('A', 141)))) $$,
  'P0001', 'GR_TEXT_TOO_LONG', 'Verwendungszweck höchstens 140 Zeichen (R27)');
select throws_ok($$ select public.gr_admit('a0000000-0000-4000-8000-000000000023', 'c0000000-0000-4000-8000-000000000002',
                     date '2026-02-01', pg_temp.contract('{"monthly_amount": 0}')) $$,
  'P0001', 'GR_AMOUNT_INVALID', 'Betrag > 0 (R27)');
select throws_ok($$ select public.gr_admit('a0000000-0000-4000-8000-000000000023', 'c0000000-0000-4000-8000-000000000002',
                     date '2026-02-01', pg_temp.contract(jsonb_build_object('mandate_signed_on', public.gr_today() + 1))) $$,
  'P0001', 'GR_DATE_IN_FUTURE', 'Unterschriftsdatum nicht in der Zukunft (R27)');
select throws_ok($$ select public.gr_admit('a0000000-0000-4000-8000-000000000023', 'c0000000-0000-4000-8000-000000000001',
                     date '2026-02-01', pg_temp.contract()) $$,
  'P0001', 'GR_ALREADY_MEMBER', 'laufende Teilnahme an derselben Gruppe (R10)');

select pg_temp.as_owner();
select is((select count(*)::int from public.gr_memberships where person_id = 'a0000000-0000-4000-8000-000000000023'), 2,
  'bei Fehlern wird nichts gespeichert');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
create temp table m (id uuid);
grant all on m to authenticated;
insert into m select public.gr_admit('a0000000-0000-4000-8000-000000000023', 'c0000000-0000-4000-8000-000000000002',
                                     date '2026-02-01', pg_temp.contract());
select is((select iban from public.gr_contracts where membership_id = (select id from m)), 'DE89370400440532013000',
  'IBAN normalisiert gespeichert');
select is((select public.gr_contract_status(ends_on, public.gr_today()) from public.gr_contracts
            where membership_id = (select id from m)), 'active', 'Vertrag aktiv');

-- Aufnahme offen wird mit gr_admit gelöscht (Paula, 30)
select pg_temp.as_owner();
insert into public.gr_guardians (child_person_id, guardian_person_id)
values ('a0000000-0000-4000-8000-000000000030', 'a0000000-0000-4000-8000-000000000024');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select lives_ok($$ select public.gr_admit('a0000000-0000-4000-8000-000000000030', 'c0000000-0000-4000-8000-000000000002',
                     public.gr_today(), pg_temp.contract('{"mandate_reference": "TEST-GR-30-1"}')) $$, 'Paula aufnehmen');
select is((select count(*)::int from public.gr_pending_admissions), 0, 'offene Aufnahme gelöscht');

-- Folgevertrag (R8a)
select throws_ok(format($$ select public.gr_add_contract(%L, pg_temp.contract('{"mandate_reference": "TEST-F-1"}')) $$,
                        (select id from m)),
  'P0001', 'GR_CONTRACT_EXISTS', 'Folgevertrag nur nach Vertragsende (R8a)');
select lives_ok(format($$ select public.gr_cancel_contract(
                          (select id from public.gr_contracts where membership_id = %L), date '2026-05-01', date '2026-06-30', false) $$,
                       (select id from m)), 'kündigen ohne Ende der Teilnahme');
select is((select left_on from public.gr_memberships where id = (select id from m)), null::date,
  'Teilnahme läuft weiter (R8b)');
select throws_ok(format($$ select public.gr_add_contract(%L, pg_temp.contract('{"mandate_reference": "TEST-F-1", "starts_on": "2026-06-30"}')) $$,
                        (select id from m)),
  'P0001', 'GR_CONTRACT_EXISTS', 'Folgevertrag beginnt nach dem letzten Vertragsende (R8a)');
select lives_ok(format($$ select public.gr_add_contract(%L, pg_temp.contract('{"mandate_reference": "TEST-F-1", "starts_on": "2026-07-01"}')) $$,
                       (select id from m)), 'Folgevertrag');
select is((select count(*)::int from public.gr_contracts where membership_id = (select id from m)), 2,
  'beendeter Vertrag bleibt (R8a)');

-- Vertrag ändern: erlaubte Felder, Vertragsbeginn bleibt
select lives_ok(format($$ select public.gr_update_contract(
                          (select id from public.gr_contracts where membership_id = %L and ends_on is null),
                          '{"monthly_amount": 22.5, "starts_on": "2030-01-01", "mandate_reference": "TEST-F-1"}') $$,
                       (select id from m)), 'Vertrag ändern (eigene Mandatsreferenz erlaubt)');
select results_eq(format($$ select monthly_amount, starts_on from public.gr_contracts where membership_id = %L and ends_on is null $$,
                         (select id from m)),
  $$ values (22.50::numeric(10, 2), date '2026-07-01') $$, 'Betrag geändert, Vertragsbeginn unverändert');

-- Kündigen mit Ende der Teilnahme (R8, R8b)
select throws_ok(format($$ select public.gr_cancel_contract(
                           (select id from public.gr_contracts where membership_id = %L and ends_on is null),
                           date '2026-08-01', date '2026-06-01', true) $$, (select id from m)),
  'P0001', 'GR_CONTRACT_END_BEFORE_START', 'Vertragsende vor Vertragsbeginn (R8)');
select lives_ok(format($$ select public.gr_cancel_contract(
                          (select id from public.gr_contracts where membership_id = %L and ends_on is null),
                          date '2026-08-01', date '2026-09-30', true) $$, (select id from m)),
  'kündigen mit Ende der Teilnahme');
select is((select left_on from public.gr_memberships where id = (select id from m)), date '2026-09-30',
  '„Teilnahme bis“ = Vertragsende (R8b)');

-- „Teilnahme bis“ (R8)
select throws_ok(format($$ select public.gr_end_membership(%L, date '2026-01-01') $$, (select id from m)),
  'P0001', 'GR_LEFT_BEFORE_JOINED', '„Teilnahme bis“ nicht vor Eintritt (R8)');
select lives_ok(format($$ select public.gr_end_membership(%L, date '2026-10-31') $$, (select id from m)), '„Teilnahme bis“ ändern');

-- Vertragsstatus
select is(public.gr_contract_status(null, date '2026-01-01'), 'active', 'ohne Ende aktiv');
select is(public.gr_contract_status(date '2026-01-01', date '2026-01-01'), 'cancelled', 'am letzten Tag gekündigt');
select is(public.gr_contract_status(date '2026-01-01', date '2026-01-02'), 'ended', 'danach beendet');

-- Volljährige Teilnehmer:in als eigene Inhaber:in (R4)
select pg_temp.as_owner();
update public.ea_properties set field_values = '{"date": "2000-01-01"}', valid_from = date '2000-01-01'
 where id = 'e0000000-0000-4000-8000-000000000033';
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select lives_ok($$ select public.gr_admit('a0000000-0000-4000-8000-000000000028', 'c0000000-0000-4000-8000-000000000001',
                     date '2026-02-01', pg_temp.contract('{"holder_person_id": "a0000000-0000-4000-8000-000000000028",
                                                           "mandate_reference": "TEST-GR-28-2", "account_holder": "Sam Sechzehn"}')) $$,
  'volljährig am Vertragsbeginn: selbst Inhaber:in (R4)');

-- Admin (GR lesen) darf nicht schreiben
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select throws_ok(format($$ select public.gr_end_membership(%L, null) $$, (select id from m)),
  'P0001', 'GR_FORBIDDEN', 'Admin ändert keine Teilnahme');

select * from finish();
rollback;
