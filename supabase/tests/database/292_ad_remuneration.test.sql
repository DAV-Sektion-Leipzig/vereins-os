-- Nachtrag v0.10 (spec T69, T70, T75 Teil; R51–R54): Abrechnungsarten mit Positionen, Vorbelegung je Einsatzart,
-- Abgabefristen, Angaben der Sektion, Kennzeichen „halbjährliche Abrechnung“ am Referat.
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
create function pg_temp.kind(p_code text) returns uuid language sql as $$
  select id from public.ad_remuneration_kinds where code = p_code
$$;

-- Struktur, RLS, kein Löschen
select ok((select bool_and(relrowsecurity) from pg_class
            where oid in ('public.ad_remuneration_kinds'::regclass, 'public.ad_remuneration_positions'::regclass,
                          'public.ad_remuneration_defaults'::regclass, 'public.ad_settlement_deadlines'::regclass,
                          'public.ad_payout_settings'::regclass)), 'RLS auf allen neuen Tabellen');
select ok(not has_table_privilege('authenticated', 'public.ad_remuneration_kinds', 'DELETE')
      and not has_table_privilege('authenticated', 'public.ad_remuneration_positions', 'DELETE')
      and not has_table_privilege('authenticated', 'public.ad_remuneration_defaults', 'DELETE')
      and not has_table_privilege('authenticated', 'public.ad_settlement_deadlines', 'DELETE')
      and not has_table_privilege('authenticated', 'public.ad_payout_settings', 'DELETE'), 'kein Löschen');
select ok(not has_table_privilege('anon', 'public.ad_payout_settings', 'SELECT'), 'anon: keine Angaben der Sektion');

-- Startbestand
select results_eq($$ select code from public.ad_remuneration_kinds order by sort_order $$,
  $$ values ('TRAINING'::text), ('TRIP'), ('COMPETITION'), ('MULTIDAY'), ('COURSE'), ('COMMUNITY_TOUR') $$,
  'sechs Abrechnungsarten');
select results_eq(
  $$ select k.code, p.position, coalesce(p.rate_key_trainer, '-'), coalesce(p.rate_key_helper, '-'), coalesce(p.rate_key_none, '-')
       from public.ad_remuneration_positions p join public.ad_remuneration_kinds k on k.id = p.kind_id
      order by k.sort_order, p.position $$,
  $$ values ('TRAINING'::text, 'training_unit'::text, 'rTE'::text, 'rTEH'::text, '-'::text),
            ('TRIP', 'day', 'rFT', 'rFH', '-'), ('TRIP', 'half_day', 'rFTh', 'rFHh', '-'),
            ('TRIP', 'organization_day', '-', '-', 'rOrg'),
            ('COMPETITION', 'competition_day', 'rWK', 'rWKH', '-'),
            ('MULTIDAY', 'day', 'rTL', 'rH', '-'), ('MULTIDAY', 'half_day', 'rTLh', 'rHh', '-'),
            ('MULTIDAY', 'organization_day', '-', '-', 'rOrg'),
            ('COURSE', 'teaching_unit', '-', '-', 'rLE'),
            ('COMMUNITY_TOUR', 'organization_day', '-', '-', 'rOrg') $$,
  'Positionen mit Satzschlüsseln (Anhang 1)');
select is((select count(*)::int from public.ad_remuneration_defaults), 14, 'Vorbelegung für alle Einsatzarten');
select results_eq($$ select name from public.ea_referate where semiannual_settlement order by name $$,
  $$ values ('Kinder und Jugend'::text), ('Leistungssport') $$, 'halbjährliche Abrechnung: K&J und Leistungssport');

-- Lesefunktionen (Geschäftsstelle)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select is(public.ad_remuneration_default_at('training_trip', 'single', date '2026-06-01'), pg_temp.kind('MULTIDAY'),
  'eintägige Ausbildungsfahrt → Mehrtageskurse (Product Owner 26.10.2026)');
select is(public.ad_remuneration_default_at('training', 'single', date '2026-06-01'), pg_temp.kind('TRAINING'), 'Training');
select is(public.ad_remuneration_default_at('work_assignment', 'single', date '2026-06-01'), null::uuid,
  'Arbeitseinsatz → keine Vergütung');
select is(public.ad_remuneration_default_at('training', 'single', date '2025-06-01'), null::uuid,
  'vor dem ersten „gültig ab“ keine Vorbelegung');
select is(public.ad_settlement_deadline(2026, 1), date '2026-07-31', 'Frist 1. Halbjahr');
select is(public.ad_settlement_deadline(2026, 2), date '2026-12-15', 'Frist 2. Halbjahr');
select throws_ok($$ select public.ad_settlement_deadline(2025, 2) $$, 'P0001', 'AD_DEADLINE_MISSING',
  'ohne gültige Frist');
select throws_ok($$ insert into public.ad_remuneration_kinds (code, name, sort_order, source)
                    values ('TEST', 'Test', 99, 'Test') $$, '42501', null, 'Geschäftsstelle pflegt keine Abrechnungsarten');
select throws_ok($$ update public.ea_referate set semiannual_settlement = true where name = 'Klettern' $$,
  'P0001', 'AD_FORBIDDEN', 'Kennzeichen am Referat nur durch den Admin (R53)');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000032');
select ok(public.ad_can_read_remuneration(), 'Referent:in liest Abrechnungsarten (Auswahl am Einsatz)');
select throws_ok($$ select * from public.ad_payout_settings_at(current_date) $$, 'P0001', 'AD_FORBIDDEN',
  'Referent:in: keine Angaben der Sektion');
select is_empty($$ select 1 from public.ad_payout_settings $$, 'Referent:in: Tabelle per RLS leer');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select throws_ok($$ select public.ad_settlement_deadline(2026, 1) $$, 'P0001', 'AD_FORBIDDEN', 'Vorstand: nichts');

-- Pflege durch den Admin (R51–R54)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select throws_ok($$ insert into public.ad_remuneration_kinds (code, name, sort_order, source)
                    values ('TRAINING_NEU', 'trainingseinheiten', 70, 'Test') $$,
  'P0001', 'AD_REMUNERATION_DUPLICATE', 'Bezeichnung eindeutig ohne Groß-/Kleinschreibung');
select lives_ok($$ insert into public.ad_remuneration_kinds (code, name, sort_order, source)
                   values ('VOLUNTEER', 'Ehrenamtspauschale', 70, 'Test') $$, 'neue Abrechnungsart');
select throws_ok($$ insert into public.ad_remuneration_positions (kind_id, position, rate_key_trainer, rate_key_helper)
                    values (pg_temp.kind('VOLUNTEER'), 'day', 'rXYZ', 'rH') $$,
  'P0001', 'AD_RATE_KEY_UNKNOWN', 'Satzschlüssel muss existieren');
select throws_ok($$ insert into public.ad_remuneration_positions (kind_id, position, rate_key_trainer, rate_key_helper)
                    values (pg_temp.kind('VOLUNTEER'), 'organization_day', 'rTL', 'rH') $$,
  'P0001', 'AD_REMUNERATION_POSITION', 'Organisationspauschale nur ohne Rolle');
select throws_ok($$ insert into public.ad_remuneration_positions (kind_id, position, rate_key_trainer, rate_key_helper)
                    values (pg_temp.kind('TRIP'), 'day', 'rTL', 'rH') $$,
  'P0001', 'AD_REMUNERATION_DUPLICATE', 'je Abrechnungsart jede Position einmal');
select lives_ok($$ update public.ad_remuneration_kinds set is_active = false where code = 'VOLUNTEER' $$, 'inaktiv setzen');
select throws_ok($$ insert into public.ad_remuneration_defaults (event_kind, span, kind_id, valid_from)
                    values ('work_assignment', 'single', pg_temp.kind('VOLUNTEER'), date '2027-01-01') $$,
  'P0001', 'AD_REMUNERATION_INACTIVE', 'nur aktive Abrechnungsarten in der Vorbelegung');
select throws_ok($$ insert into public.ad_remuneration_defaults (event_kind, span, kind_id, valid_from)
                    values ('training', 'single', pg_temp.kind('TRAINING'), date '2026-01-01') $$,
  'P0001', 'AD_RATE_DUPLICATE', 'je Einsatzart, Dauer und Datum eine Zeile');
select throws_ok($$ insert into public.ad_settlement_deadlines (half, deadline_month, deadline_day, valid_from)
                    values (1, 2, 31, date '2027-01-01') $$,
  'P0001', 'AD_DEADLINE_INVALID', '31.02. ist kein Datum');
select throws_ok($$ insert into public.ad_payout_settings (debtor_name, iban, bic, ledger_account, valid_from)
                    values ('Sektion Test', 'DE00 1234', 'TESTDEFFXXX', '0000 0', date '2030-01-01') $$,
  'P0001', 'EA_IBAN_INVALID', 'IBAN geprüft');
select throws_ok($$ insert into public.ad_payout_settings (debtor_name, iban, bic, ledger_account, valid_from)
                    values ('Sektion Test', 'DE89370400440532013000', 'TEST', '0000 0', date '2030-01-01') $$,
  'P0001', 'AD_BIC_INVALID', 'BIC geprüft');
select lives_ok($$ insert into public.ad_payout_settings (debtor_name, iban, bic, ledger_account, valid_from)
                   values ('Sektion Test 2030', 'de89 3704 0044 0532 0130 00', 'testdeff', '0000 1', date '2030-01-01') $$,
  'Angaben der Sektion mit „gültig ab“');
select is((select iban || '|' || bic from public.ad_payout_settings_at(date '2030-06-01')),
  'DE89370400440532013000|TESTDEFF', 'IBAN und BIC normalisiert');
select lives_ok($$ update public.ea_referate set semiannual_settlement = true where name = 'Klettern' $$,
  'Admin setzt das Kennzeichen am Referat');

select * from finish();
rollback;
