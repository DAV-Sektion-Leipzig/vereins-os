-- Sätze und Pauschalen (spec T60, T61 Teil, T69 Teil, T75 Teil; R46; Nachtrag v0.10 A3, A4): Tabelle ad_rates,
-- Rechte, ad_rates_at, Startbestand der Vergütung und des steuerfreien Höchstbetrags.
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

-- Struktur, RLS, Grants
select has_table('public', 'ad_rates', 'Tabelle ad_rates');
select ok((select relrowsecurity from pg_class where oid = 'public.ad_rates'::regclass), 'RLS aktiv');
select ok(not has_table_privilege('authenticated', 'public.ad_rates', 'DELETE'), 'kein Löschen (R46)');
select ok(not has_table_privilege('anon', 'public.ad_rates', 'SELECT'), 'anon: nichts');
select ok(not has_column_privilege('authenticated', 'public.ad_rates', 'rate_key', 'UPDATE'), 'Schlüssel nicht änderbar');
select ok(not has_column_privilege('authenticated', 'public.ad_rates', 'valid_from', 'UPDATE'), '„gültig ab“ nicht änderbar');
select ok(has_column_privilege('authenticated', 'public.ad_rates', 'value', 'UPDATE'), 'Wert korrigierbar');

-- Startbestand
select results_eq(
  $$ select rate_key, value from public.ad_rates where rate_group = 'remuneration' and valid_from = date '2026-01-01'
      order by rate_key $$,
  $$ values ('rFH'::text, 20::numeric), ('rFHh', 10), ('rFT', 30), ('rFTh', 15), ('rH', 40), ('rHh', 20), ('rLE', 15),
            ('rOrg', 10), ('rTE', 6), ('rTEH', 4), ('rTL', 50), ('rTLh', 25), ('rWK', 50), ('rWKH', 40) $$,
  'Startbestand Vergütung nach Anhang 1');
select results_eq(
  $$ select valid_from, value from public.ad_rates where rate_key = 'maxUeL' order by valid_from $$,
  $$ values (date '2021-01-01', 3000::numeric), (date '2026-01-01', 3300) $$,
  'Höchstbetrag mit Historie (3.000 € ab 2021, 3.300 € ab 2026)');

-- Lesen nach ad_can_read_rates
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select is((select value from public.ad_rates_at(date '2026-06-01') where rate_key = 'maxUeL'), 3300::numeric,
  'Geschäftsstelle (FI verwalten): Höchstbetrag 2026');
select is((select value from public.ad_rates_at(date '2025-06-01') where rate_key = 'maxUeL'), 3000::numeric,
  'Höchstbetrag 2025');
select is((select value from public.ad_rates_at(date '2026-06-01') where rate_key = 'rTE'), 6::numeric, 'Trainingseinheit 6 €');
select is_empty($$ select 1 from public.ad_rates_at(date '2025-06-01') where rate_key = 'rTE' $$,
  'Schlüssel ohne gültige Zeile fehlen');
select throws_ok($$ insert into public.ad_rates (rate_key, label, rate_group, unit, value, valid_from, source)
                    values ('rTest', 'Test', 'remuneration', '€', 1, date '2026-01-01', 'Test') $$,
  '42501', null, 'Geschäftsstelle darf keine Sätze anlegen (nur Admin)');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000032');
-- Seit AD v0.9 (T59) hat die Vorlage Referent:in TK bearbeiten (Reichweite Referat) und liest damit die Sätze
-- (ad_can_read_rates, Erwartete Ergebnisse v0.9: Referent:in Klettern liest rOrg); nur über FI-Reichweite „Referat“ nicht.
select lives_ok($$ select * from public.ad_rates_at(current_date) $$, 'Referent:in (über TK bearbeiten): liest Sätze');
select pg_temp.as_owner();
update public.ad_template_rights r set level = 'none', scope = 'all'
  from public.ad_templates t where r.template_id = t.id and t.name = 'Referent:in' and r.module_code = 'TK';
select pg_temp.as_user('b0000000-0000-4000-8000-000000000032');
select throws_ok($$ select * from public.ad_rates_at(current_date) $$, 'P0001', 'AD_FORBIDDEN',
  'Referent:in nur mit FI-Reichweite Referat (ohne TK): keine Sätze');
select is_empty($$ select 1 from public.ad_rates $$, 'Referent:in ohne TK: Tabelle per RLS leer');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select throws_ok($$ select * from public.ad_rates_at(current_date) $$, 'P0001', 'AD_FORBIDDEN', 'Vorstand: keine Sätze');

-- Pflege durch den Admin (R46)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select lives_ok($$ insert into public.ad_rates (rate_key, label, rate_group, unit, value, valid_from, source)
                   values ('rOrg', 'Organisationspauschale je Tag', 'remuneration', '€', 12, date '2029-01-01', 'Test') $$,
  'Admin: neuer Wert mit „gültig ab“');
select is((select value from public.ad_rates_at(date '2029-01-02') where rate_key = 'rOrg'), 12::numeric,
  'neuer Wert ab 2029');
select is((select value from public.ad_rates_at(date '2027-12-31') where rate_key = 'rOrg'), 10::numeric,
  'alter Wert bis 2027');
select throws_ok($$ insert into public.ad_rates (rate_key, label, rate_group, unit, value, valid_from, source)
                    values ('rOrg', 'x', 'remuneration', '€', 13, date '2029-01-01', 'Test') $$,
  'P0001', 'AD_RATE_DUPLICATE', 'je Schlüssel und Datum eine Zeile');
select throws_ok($$ insert into public.ad_rates (rate_key, label, rate_group, unit, value, valid_from, source)
                    values ('rNeu', 'x', 'remuneration', '€', -1, date '2029-01-01', 'Test') $$,
  'P0001', 'AD_RATE_VALUE', 'Werte ≥ 0');
select throws_ok($$ insert into public.ad_rates (rate_key, label, rate_group, unit, value, valid_from, source)
                    values ('rNeu', '  ', 'remuneration', '€', 1, date '2029-01-01', 'Test') $$,
  'P0001', 'AD_RATE_FIELD_REQUIRED', 'Bezeichnung Pflicht');
select throws_ok($$ insert into public.ad_rates (rate_key, label, rate_group, unit, value, valid_from, source)
                    values ('fee_test', 'Gebühr', 'payment_fee', '%', 1, date '2029-01-01', 'Test') $$,
  'P0001', 'AD_RATE_VALUE', 'Zahlungsgebühr mit Prozentsatz und festem Betrag statt Wert');
select lives_ok($$ update public.ad_rates set source = 'Vergütungsordnung 2025, Anhang 1 (korrigiert)'
                    where rate_key = 'rTE' and valid_from = date '2026-01-01' $$, 'Quelle korrigierbar');
select throws_ok($$ update public.ad_rates set valid_from = date '2027-01-01' where rate_key = 'rTE' $$,
  '42501', null, '„gültig ab“ nicht änderbar');

select * from finish();
rollback;
