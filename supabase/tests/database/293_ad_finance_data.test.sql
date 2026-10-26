-- Nachtrag v0.10 (spec T72, T75 Teil; R55, R56): ea_person_finance_data, fi_person_visible, ea_person_names.
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

create function pg_temp.as_user(p_user uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', p_user, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
end $$;
create function pg_temp.p(n int) returns uuid language sql as $$
  select ('a0000000-0000-4000-8000-' || lpad(n::text, 12, '0'))::uuid
$$;

-- Grants und Spalten
select ok(has_function_privilege('authenticated', 'public.ea_person_finance_data(uuid[], date)', 'EXECUTE'),
  'ea_person_finance_data');
select ok(not has_function_privilege('anon', 'public.ea_person_finance_data(uuid[], date)', 'EXECUTE'), 'anon: nichts');
select is(pg_get_function_result('public.ea_person_finance_data(uuid[], date)'::regprocedure),
  'TABLE(person_id uuid, account_holder text, iban text, trainer_agreement_from date, tax_free_confirmations jsonb, licenses jsonb)',
  'feste Spalten (R55)');
select is(public.fi_person_visible(pg_temp.p(22)), false, 'Platzhalter fi_person_visible = false');

-- Geschäftsstelle (FI verwalten, Reichweite alle)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select results_eq(
  $$ select account_holder, iban from public.ea_person_finance_data(array[pg_temp.p(22)], current_date) $$,
  $$ values ('Sven Schlüssel'::text, 'DE89370400440532013000'::text) $$,
  'Bankverbindung trotz Lesestufe „nur Geschäftsstelle und Admin“ über die Funktion');
select is((select tax_free_confirmations from public.ea_person_finance_data(array[pg_temp.p(22)], current_date)),
  '[]'::jsonb, 'ohne Bestätigung steuerfreie Einnahmen leere Liste');
select is((select trainer_agreement_from from public.ea_person_finance_data(array[pg_temp.p(22)], current_date)),
  null::date, 'ohne Trainervereinbarung null');
select is((select jsonb_array_length(licenses) from public.ea_person_finance_data(array[pg_temp.p(19)], current_date)),
  1, 'Lena: eine Lizenz');
select is((select licenses -> 0 ->> 'valid_from' from public.ea_person_finance_data(array[pg_temp.p(19)], current_date)),
  '2022-06-01', 'Lizenz mit gültig von (Erwerb)');
select ok((select not (licenses -> 0 ? 'license_number') from public.ea_person_finance_data(array[pg_temp.p(19)], current_date)),
  'keine Lizenznummer');
select is((select licenses -> 0 ->> 'valid_until' from public.ea_person_finance_data(array[pg_temp.p(20)], current_date)),
  '2025-12-31', 'abgelaufene Lizenz wird geliefert (Prüfung für das Halbjahr)');
select is_empty($$ select 1 from public.ea_person_finance_data(array[pg_temp.p(8)], current_date) $$,
  'Funktionsperson nie');
select throws_ok($$ select * from public.ea_person_finance_data(array(select gen_random_uuid() from generate_series(1, 501)), current_date) $$,
  'P0001', 'AD_TOO_MANY_IDS', 'höchstens 500 IDs');

-- Ohne FI-Reichweite „alle“ keine Personendaten
select pg_temp.as_user('b0000000-0000-4000-8000-000000000032');
select throws_ok($$ select * from public.ea_person_finance_data(array[pg_temp.p(22)], current_date) $$,
  'P0001', 'AD_FORBIDDEN', 'Referent:in (FI Reichweite Referat): keine Bankdaten (R55)');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select throws_ok($$ select * from public.ea_person_finance_data(array[pg_temp.p(22)], current_date) $$,
  'P0001', 'AD_FORBIDDEN', 'Admin ohne FI-Rechte: keine Personendaten über Finanzen');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select throws_ok($$ select * from public.ea_person_finance_data(array[pg_temp.p(22)], current_date) $$,
  'P0001', 'AD_FORBIDDEN', 'Vorstand: nichts');

-- Namen bleiben wie bisher (Platzhalter false)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select results_eq($$ select id from public.ea_person_names(array[pg_temp.p(4)]) $$, $$ values (pg_temp.p(4)) $$,
  'ea_person_names unverändert über den Pfad EA');

select * from finish();
rollback;
