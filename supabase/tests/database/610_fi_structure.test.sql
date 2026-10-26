-- Finanzen (spec.md FI v0.2, T9 Teil): Struktur, RLS, Grants, ersetzte Platzhalter.
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

select has_table('public', t, t) from unnest(array['fi_settlements', 'fi_settlement_items', 'fi_settlement_confirmations',
  'fi_settlement_log', 'fi_payout_runs', 'fi_run_counters', 'fi_payout_lines', 'fi_climbing_checks']) as t;
select ok((select bool_and(c.relrowsecurity) from pg_class c
            where c.relnamespace = 'public'::regnamespace and c.relkind = 'r' and c.relname like 'fi\_%'),
  'RLS auf allen fi_-Tabellen');
select is((select count(*)::int from pg_policies where schemaname = 'public' and tablename like 'fi\_%' and cmd <> 'SELECT'),
  0, 'nur Lese-Policies; geschrieben wird über Funktionen');
select ok(not exists (
  select 1 from information_schema.role_table_grants g
   where g.table_schema = 'public' and g.table_name like 'fi\_%' and g.grantee = 'authenticated'
     and g.privilege_type in ('INSERT', 'UPDATE', 'DELETE')), 'keine Schreibrechte für authenticated');
select ok(not exists (
  select 1 from information_schema.role_table_grants g
   where g.table_schema = 'public' and g.table_name like 'fi\_%' and g.grantee = 'anon'), 'anon: nichts');

-- Öffentliche Funktionen nur für authenticated; interne Funktionen für niemanden
select ok(has_function_privilege('authenticated', f, 'EXECUTE'), f) from unnest(array[
  'public.fi_calculate_half(smallint, smallint)', 'public.fi_list_settlements(smallint, smallint, public.fi_settlement_status, uuid, boolean, boolean, boolean, int, int)',
  'public.fi_get_settlement(uuid)', 'public.fi_settlement_document(uuid[])', 'public.fi_correct_item(uuid, public.fi_rate_role, numeric, text)',
  'public.fi_set_exception_reason(uuid, text)', 'public.fi_confirm(uuid[])', 'public.fi_confirm_substitute(uuid, uuid, text)',
  'public.fi_close(uuid[])', 'public.fi_reopen(uuid)', 'public.fi_record_submission(uuid, date, text)', 'public.fi_expire(uuid[])',
  'public.fi_create_payout_run(smallint, smallint, date)', 'public.fi_set_payout_run_settlements(uuid, uuid[])',
  'public.fi_update_payout_run(uuid, date)', 'public.fi_discard_payout_run(uuid)', 'public.fi_preview_payout_run(uuid)',
  'public.fi_release_payout_run(uuid)', 'public.fi_payout_export(uuid)', 'public.fi_list_payout_runs(smallint, smallint)',
  'public.fi_climbing_report(uuid, date, date)', 'public.fi_save_climbing_check(uuid, date, date, int, text, text)',
  'public.fi_list_climbing_checks(uuid)']) as f;
select ok(not has_function_privilege('anon', 'public.fi_calculate_half(smallint, smallint)', 'EXECUTE'), 'anon: keine Berechnung');
select ok(not has_function_privilege('authenticated', f, 'EXECUTE'), 'intern: ' || f) from unnest(array[
  'public.fi_person_flags(uuid, int)', 'public.fi_settlement_info(uuid)', 'public.fi_log(uuid, public.fi_log_action, jsonb)',
  'public.fi_lines_for(uuid[])', 'public.fi_lock_settlement(uuid)', 'public.fi_payable(uuid)']) as f;

-- Platzhalter ersetzt (keine Konstante mehr)
select ok(pg_get_functiondef('public.fi_event_locked(uuid)'::regprocedure) like '%fi_settlement_items%',
  'fi_event_locked ersetzt (Anwesenheitserfassung R34)');
select ok(pg_get_functiondef('public.fi_attendance_locked(uuid)'::regprocedure) like '%fi_settlement_items%',
  'fi_attendance_locked ersetzt');
select ok(pg_get_functiondef('public.fi_person_visible(uuid)'::regprocedure) like '%fi_settlements%',
  'fi_person_visible ersetzt (Administration R56)');

-- Rechte: Kim (Referent:in K&J), Vorstand, Admin ohne FI-Verwaltung
select set_config('request.jwt.claims', json_build_object('sub', 'b0000000-0000-4000-8000-000000000032', 'role', 'authenticated')::text, true);
set local role authenticated;
select throws_ok($$ select public.fi_calculate_half(2026::smallint, 1::smallint) $$, 'P0001', 'FI_FORBIDDEN',
  'Referent:in berechnet nicht (R32)');
select throws_ok($$ select public.fi_create_payout_run(2026::smallint, 1::smallint, current_date) $$, 'P0001', 'FI_FORBIDDEN',
  'Referent:in: keine Auszahlungsrunden');
select lives_ok($$ select * from public.fi_list_settlements(2026::smallint, 1::smallint) $$, 'Referent:in: Liste erlaubt');
reset role;
select set_config('request.jwt.claims', json_build_object('sub', 'b0000000-0000-4000-8000-000000000003', 'role', 'authenticated')::text, true);
set local role authenticated;
select throws_ok($$ select * from public.fi_list_settlements(2026::smallint, 1::smallint) $$, 'P0001', 'FI_FORBIDDEN',
  'Vorstand ohne FI: keine Liste');
reset role;
select set_config('request.jwt.claims', json_build_object('sub', 'b0000000-0000-4000-8000-000000000002', 'role', 'authenticated')::text, true);
set local role authenticated;
select throws_ok($$ select public.fi_calculate_half(2026::smallint, 3::smallint) $$, 'P0001', 'FI_PERIOD_INVALID',
  'Halbjahr 1 oder 2');

select * from finish();
rollback;
