-- Finanzen Nachtrag v0.3 (spec.md FI Abschnitt 12, FT20; US-FI-18 bis US-FI-21; R34–R47) mit AD v0.11 (R57, R58)
-- und GR v0.4 (gr_contracts_for_collection): Buchungslauf Verträge. Monate relativ zu heute; nur fiktive Daten,
-- IBAN nur die Beispiel-IBAN, Gläubiger-ID nur die Test-Kennung der Bundesbank.
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
  perform set_config('request.jwt.claims', json_build_object('sub', 'b0000000-0000-4000-8000-000000000002', 'role', 'authenticated')::text, true);
end $$;
create function pg_temp.gs() returns void language sql as $$ select pg_temp.as_user('b0000000-0000-4000-8000-000000000002') $$;
create function pg_temp.c(n int) returns uuid language sql as $$
  select ('c3000000-0000-4000-8000-' || lpad(n::text, 12, '0'))::uuid $$;
-- Monat M = nächster Monat, M2 = übernächster
create function pg_temp.m(k int default 1) returns date language sql as $$
  select (date_trunc('month', current_date) + make_interval(months => k))::date $$;
create temp table ids (name text primary key, id uuid);
grant select, insert, update on ids to authenticated;
create function pg_temp.id(p_name text) returns uuid language sql as $$ select id from ids where name = p_name $$;
create function pg_temp.line(p_run uuid, p_contract uuid) returns public.fi_collections language sql as $$
  select * from public.fi_collections where run_id = p_run and contract_id = p_contract $$;

-- ---------------------------------------------------------------------------------------------------------------
-- Testdaten: Stichtag = aktueller Monat; neuer Vertrag ab M (Erstlastschrift), Vertrag mit Mandat nach dem Fälligkeitstag
select pg_temp.as_owner();
insert into public.ad_collection_settings (start_month) values (date_trunc('month', current_date)::date)
on conflict (id) do update set start_month = excluded.start_month;
update public.ad_payout_settings set creditor_id = 'DE98ZZZ09999999999', ledger_account_collection = '0000 1'
 where valid_from = (select max(valid_from) from public.ad_payout_settings);
insert into public.ea_persons (id, first_name, last_name, kind, created_in) values
  ('a0000000-0000-4000-8000-000000000641', 'Nora', 'Neuvertrag', 'human', 'GR'),
  ('a0000000-0000-4000-8000-000000000642', 'Otto', 'Spätmandat', 'human', 'GR');
insert into public.gr_memberships (id, group_id, person_id, joined_on) values
  ('c2000000-0000-4000-8000-000000000641', 'c0000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000641', pg_temp.m()),
  ('c2000000-0000-4000-8000-000000000642', 'c0000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000642', pg_temp.m());
insert into public.gr_contracts (id, membership_id, holder_person_id, starts_on, account_holder, iban, mandate_reference,
                                 mandate_signed_on, purpose, monthly_amount) values
  (pg_temp.c(641), 'c2000000-0000-4000-8000-000000000641', 'a0000000-0000-4000-8000-000000000641', pg_temp.m(),
   'Nora Neuvertrag', 'DE89370400440532013000', 'TEST-FI-641', current_date - 5, 'Beitrag', 20.00),
  (pg_temp.c(642), 'c2000000-0000-4000-8000-000000000642', 'a0000000-0000-4000-8000-000000000642', pg_temp.m(),
   'Otto Spätmandat', 'DE89370400440532013000', 'TEST-FI-642', pg_temp.m() + 20, 'Beitrag', 20.00);

-- ---------------------------------------------------------------------------------------------------------------
-- AD v0.11: Gläubiger-ID, Stichtag
select ok(public.ad_creditor_id_valid('DE98ZZZ09999999999'), 'Gläubiger-ID: Test-Kennung gültig (R57)');
select ok(not public.ad_creditor_id_valid('DE99ZZZ09999999999'), 'Gläubiger-ID: falsche Prüfziffer ungültig');
select throws_ok($$ update public.ad_payout_settings set creditor_id = 'DE00ZZZ00000000000' $$,
  'P0001', 'AD_CREDITOR_ID_INVALID', 'Speichern einer ungültigen Gläubiger-ID abgelehnt');
select is((select creditor_id from public.ad_payout_settings_at(current_date)), 'DE98ZZZ09999999999',
  'ad_payout_settings_at liefert die Gläubiger-ID');
select is(public.ad_collection_start(), date_trunc('month', current_date)::date, 'ad_collection_start (R58)');

-- Rechte (R32, G1)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select throws_ok($$ select public.fi_create_collection_run(pg_temp.m()) $$, 'P0001', 'FI_FORBIDDEN', 'Admin: kein Buchungslauf');
select throws_ok($$ select * from public.gr_contracts_for_collection(pg_temp.m()) $$, 'P0001', 'GR_FORBIDDEN',
  'Admin: keine Verträge für den Einzug');
select throws_ok($$ insert into public.ad_collection_settings (start_month) values (date '2020-01-01') $$, '23505', null,
  'Admin: Stichtag nur eine Zeile');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000032');
select throws_ok($$ select * from public.fi_list_collection_runs() $$, 'P0001', 'FI_FORBIDDEN', 'Referent:in: keine Buchungsläufe');
select is_empty($$ select 1 from public.fi_collection_runs $$, 'Referent:in: RLS ohne Zeilen');

-- ---------------------------------------------------------------------------------------------------------------
-- Fälligkeitstag (R39) und Monat (R36)
select pg_temp.gs();
select is(public.fi_default_due_date(date '2026-12-02'), date '2026-12-07', 'Mi + 3 = Sa → Mo (R39)');
select is(public.fi_default_due_date(date '2026-12-01'), date '2026-12-04', 'Di + 3 = Fr');
select throws_ok($$ select public.fi_create_collection_run(pg_temp.m(-1)) $$, 'P0001', 'FI_COLLECTION_MONTH',
  'vergangener Monat abgelehnt (R36)');
select throws_ok($$ select public.fi_create_collection_run(pg_temp.m(), current_date) $$, 'P0001', 'FI_DUE_DATE',
  'Fälligkeit heute abgelehnt (R39)');

-- Lauf 1 für M (R34, R37, R38)
insert into ids values ('R1', public.fi_create_collection_run(pg_temp.m()));
select is((select number from public.fi_collection_runs where id = pg_temp.id('R1')), 1::smallint, 'Lauf 1');
select is((select due_date from public.fi_collection_runs where id = pg_temp.id('R1')), public.fi_default_due_date(),
  'Fälligkeit vorbelegt');
select ok((pg_temp.line(pg_temp.id('R1'), pg_temp.c(1))).included, 'aktiver Bestandsvertrag enthalten (R34)');
select is((pg_temp.line(pg_temp.id('R1'), pg_temp.c(1))).sequence, 'RCUR'::public.fi_sequence,
  'Vertragsbeginn vor dem Stichtag: Folgelastschrift (R38)');
select is((pg_temp.line(pg_temp.id('R1'), pg_temp.c(1))).monthly_amount, 25.00, 'voller Monatsbetrag');
select ok(pg_temp.line(pg_temp.id('R1'), pg_temp.c(3)) is null, 'beendeter Vertrag nicht enthalten');
select is((pg_temp.line(pg_temp.id('R1'), pg_temp.c(641))).sequence, 'FRST'::public.fi_sequence,
  'neuer Vertrag ab M: Erstlastschrift (R38)');
select is((pg_temp.line(pg_temp.id('R1'), pg_temp.c(642))).excluded_reason, 'mandate_not_signed',
  'Mandat nach Fälligkeit: ausgeschlossen (R37)');
select ok(not (pg_temp.line(pg_temp.id('R1'), pg_temp.c(642))).included, 'ausgeschlossen = nicht enthalten');
select is((select l ->> 'iban_last4' from jsonb_array_elements(public.fi_get_collection_run(pg_temp.id('R1')) -> 'lines') l
            where (l ->> 'contract_id')::uuid = pg_temp.c(1)), '3000', 'Detail: IBAN gekürzt (R41)');
select throws_ok(format('select public.fi_set_collection_included(%L, true)', (pg_temp.line(pg_temp.id('R1'), pg_temp.c(642))).id),
  'P0001', 'FI_COLLECTION_EXCLUDED', 'ausgeschlossene Lastschrift nicht wählbar');

-- Nachtrag (R35): Lauf 2 enthält nichts, was Lauf 1 enthält; Abwahl macht den Vertrag frei
insert into ids values ('R2', public.fi_create_collection_run(pg_temp.m()));
select is((select number from public.fi_collection_runs where id = pg_temp.id('R2')), 2::smallint, 'Lauf 2 (Nachtrag)');
select is_empty(format('select 1 from public.fi_collections where run_id = %L and included', pg_temp.id('R2')),
  'Nachtrag ohne bereits enthaltene Verträge (R35)');
select lives_ok(format('select public.fi_set_collection_included(%L, false)', (pg_temp.line(pg_temp.id('R1'), pg_temp.c(5))).id),
  'Lastschrift abwählen');
select lives_ok(format('select public.fi_refresh_collection_run(%L)', pg_temp.id('R2')), 'Nachtrag aktualisieren');
select ok((pg_temp.line(pg_temp.id('R2'), pg_temp.c(5))).included, 'abgewählter Vertrag im Nachtrag enthalten');
select throws_ok(format('select public.fi_set_collection_included(%L, true)', (pg_temp.line(pg_temp.id('R1'), pg_temp.c(5))).id),
  'P0001', 'FI_COLLECTION_TAKEN', 'Vertrag nicht in zwei Läufen desselben Monats (R35)');

-- Zusatzbetrag (R47)
select throws_ok(format('select public.fi_set_collection_extra(%L, 50, %L, null)', (pg_temp.line(pg_temp.id('R1'), pg_temp.c(1))).id, 'x'),
  'P0001', 'FI_EXTRA_REQUIRED', 'Zusatzbetrag ohne Begründung abgelehnt');
select throws_ok(format('select public.fi_set_collection_extra(%L, 1.234, %L, %L)', (pg_temp.line(pg_temp.id('R1'), pg_temp.c(1))).id, 'x', 'y'),
  'P0001', 'FI_AMOUNT_INVALID', 'Zusatzbetrag mit 3 Nachkommastellen abgelehnt');
select lives_ok(format('select public.fi_set_collection_extra(%L, 50, %L, %L)', (pg_temp.line(pg_temp.id('R1'), pg_temp.c(1))).id,
  'und rückwirkend', 'Nachzahlung zwei Monate'), 'Zusatzbetrag erfasst');
select is((pg_temp.line(pg_temp.id('R1'), pg_temp.c(1))).amount, 75.00, 'Betrag = Monatsbetrag + Zusatzbetrag');

-- Freigabe: Angaben der Sektion (R45), geänderter Vertrag
select pg_temp.as_owner();
update public.ad_payout_settings set creditor_id = null;
select pg_temp.gs();
select throws_ok(format('select public.fi_release_collection_run(%L)', pg_temp.id('R1')), 'P0001',
  'FI_COLLECTION_SETTINGS_MISSING', 'ohne Gläubiger-ID keine Freigabe (R45)');
select pg_temp.as_owner();
update public.ad_payout_settings set creditor_id = 'DE98ZZZ09999999999';
update public.gr_contracts set monthly_amount = 26.00 where id = pg_temp.c(2);
select pg_temp.gs();
select throws_ok(format('select public.fi_release_collection_run(%L)', pg_temp.id('R1')), 'P0001',
  'FI_COLLECTION_CHANGED', 'geänderter Monatsbetrag: Freigabe abgelehnt');
select lives_ok(format('select public.fi_refresh_collection_run(%L)', pg_temp.id('R1')), 'Lauf 1 aktualisieren');
select is((pg_temp.line(pg_temp.id('R1'), pg_temp.c(2))).monthly_amount, 26.00, 'Betrag aktualisiert');
select is((pg_temp.line(pg_temp.id('R1'), pg_temp.c(1))).extra_amount, 50.00, 'Zusatzbetrag bleibt beim Aktualisieren');
select ok(not (pg_temp.line(pg_temp.id('R1'), pg_temp.c(5))).included, 'Abwahl bleibt beim Aktualisieren');

create temp table expected as
  select count(*)::int as cnt, sum(amount) as total from public.fi_collections where run_id = pg_temp.id('R1') and included;
select lives_ok(format('select public.fi_release_collection_run(%L)', pg_temp.id('R1')), 'Lauf 1 freigeben');
select is((select status from public.fi_collection_runs where id = pg_temp.id('R1')), 'released'::public.fi_collection_status,
  'freigegeben');
select is((select line_count from public.fi_collection_runs where id = pg_temp.id('R1')), (select cnt from expected),
  'Anzahl = enthaltene Lastschriften');
select is((select total from public.fi_collection_runs where id = pg_temp.id('R1')), (select total from expected),
  'Summe = Summe der Lastschriften');
select matches((select msg_id from public.fi_collection_runs where id = pg_temp.id('R1')),
  '^FI-L-[0-9]{4}-[0-9]{2}-01-[0-9a-f]{8}$', 'Nachrichten-ID (R40)');
select ok((select pmt_inf_id_frst is not null and pmt_inf_id_rcur is not null and char_length(pmt_inf_id_frst) <= 35
             from public.fi_collection_runs where id = pg_temp.id('R1')), 'Zahlungs-IDs je Sequenz');
select is_empty(format('select 1 from public.fi_collections where run_id = %L and not included', pg_temp.id('R1')),
  'nicht enthaltene Zeilen gelöscht');
select is_empty(format('select 1 from public.fi_collections where run_id = %L and (end_to_end_id is null or sort_no is null)', pg_temp.id('R1')),
  'Ende-zu-Ende-ID und Reihenfolge vergeben');
select is((pg_temp.line(pg_temp.id('R1'), pg_temp.c(1))).remittance,
  'Jugendgruppe Test 1 Beitragszahlung ' || public.fi_month_name(pg_temp.m()) || ' und rückwirkend',
  'Verwendungszweck nach Vorlage mit Zusatztext (R42, R47)');
select throws_ok(format('select public.fi_set_collection_extra(%L, null, null, null)', (pg_temp.line(pg_temp.id('R1'), pg_temp.c(1))).id),
  'P0001', 'FI_STATUS', 'nach der Freigabe nicht änderbar');
select throws_ok(format('select public.fi_discard_collection_run(%L)', pg_temp.id('R1')), 'P0001', 'FI_STATUS',
  'freigegebener Lauf nicht verwerfbar');

-- Export (R40–R43)
select is((select count(*)::int from jsonb_array_elements(public.fi_collection_export(pg_temp.id('R1')) -> 'lines')),
  (select cnt from expected), 'Export: alle Lastschriften');
select is((select l ->> 'iban' from jsonb_array_elements(public.fi_collection_export(pg_temp.id('R1')) -> 'lines') l
            where l ->> 'mandate_reference' = 'TEST-GR-23-1'), 'DE89370400440532013000', 'Export: IBAN aus Gruppen');
select is(public.fi_collection_export(pg_temp.id('R1')) -> 'creditor' ->> 'creditor_id', 'DE98ZZZ09999999999',
  'Export: Gläubiger-ID');
select throws_ok(format('select public.fi_collection_export(%L)', pg_temp.id('R2')), 'P0001', 'FI_STATUS',
  'Export nur für freigegebene Läufe');
select hasnt_column('public', 'fi_collections', 'iban', 'keine IBAN in fi_collections (R43)');
select hasnt_column('public', 'fi_collections', 'account_holder', 'kein Kontoinhaber in fi_collections (R43)');

-- Folgemonat: Erstlastschrift nur einmal (R38); Verwerfen
insert into ids values ('R3', public.fi_create_collection_run(pg_temp.m(2)));
select is((pg_temp.line(pg_temp.id('R3'), pg_temp.c(641))).sequence, 'RCUR'::public.fi_sequence,
  'nach erstem Einzug Folgelastschrift (R38)');
select lives_ok(format('select public.fi_discard_collection_run(%L)', pg_temp.id('R3')), 'Entwurf verwerfen');
select is_empty(format('select 1 from public.fi_collections where run_id = %L', pg_temp.id('R3')), 'Zeilen mit verworfen');
select is((select count(*)::int from public.fi_list_collection_runs()), 2, 'Liste: zwei Läufe');

-- Schreiben nur über Funktionen
select throws_ok($$ insert into public.fi_collection_runs (month, number, due_date) values (date '2030-01-01', 1, date '2030-01-05') $$,
  '42501', null, 'kein direktes Schreiben');

select * from finish();
rollback;
