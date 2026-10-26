-- Planungshilfe Touren und Kurse, spec T1–T4, T18 (tasks.md T001–T004, T014): Tabellen, RLS, Grants, Funktionen,
-- Startbestand Qualifikationsart → Sportart, direkte Schreibzugriffe abgelehnt.
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

select has_table('public', t, 'Tabelle ' || t) from unnest(array[
  'tk_plans', 'tk_plan_leaders', 'tk_plan_contacts', 'tk_plan_legs', 'tk_plan_costs', 'tk_plan_results',
  'tk_plan_rates', 'tk_plan_history', 'tk_qualification_sports', 'tk_privacy_confirmations']) t;
select is_empty(
  $$ select c.relname from pg_class c join pg_namespace n on n.oid = c.relnamespace
      where n.nspname = 'public' and c.relname like 'tk\_%' and c.relkind = 'r' and not c.relrowsecurity $$,
  'RLS auf jeder tk_-Tabelle');
select is_empty(
  $$ select t.table_name, t.privilege_type from information_schema.table_privileges t
      where t.table_schema = 'public' and t.table_name like 'tk\_%' and t.grantee in ('authenticated', 'anon')
        and (t.grantee = 'anon' or t.privilege_type <> 'SELECT') $$,
  'authenticated nur SELECT, anon nichts');
select is_empty(
  $$ select p.proname from pg_proc p join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'public' and p.proname like 'tk\_%' and has_function_privilege('anon', p.oid, 'EXECUTE') $$,
  'anon führt keine tk_-Funktion aus');
select ok(has_function_privilege('authenticated', f, 'EXECUTE'), f || ': authenticated') from unnest(array[
  'public.tk_save_plan(jsonb, jsonb, jsonb, jsonb, jsonb, int)', 'public.tk_change_status(uuid, text, text, text, int)',
  'public.tk_get_plan(uuid)', 'public.tk_list_plans(int, uuid, public.tk_plan_type, public.tk_plan_status[], int, int)',
  'public.tk_cost_report(int, uuid, public.tk_plan_type, boolean)', 'public.tk_copy_plan(uuid, uuid)',
  'public.tk_delete_plan(uuid)', 'public.tk_settlement_draft(uuid)',
  'public.tk_create_leader(uuid, text, text, text, text, boolean, text)', 'public.tk_reactivate_leader(uuid, uuid)']) f;
select ok(not has_function_privilege('authenticated', f, 'EXECUTE'), f || ': intern') from unnest(array[
  'public.tk_calculate(uuid)', 'public.tk_rates(uuid)', 'public.tk_purge_contacts()',
  'public.tk_plan_referat(public.tk_plan_type)']) f;
select ok(exists (select 1 from pg_proc where proname = 'tk_purge_contacts'), 'Löschjob vorhanden (pg_cron in CI)');

-- Startbestand Qualifikationsart → Sportart (Prototyp 4.8)
select results_eq(
  $$ select qs.sport from public.tk_qualification_sports qs join public.ad_qualification_types q on q.id = qs.qualification_type_id
      where q.code = 'TCBW' order by 1 $$,
  $$ values ('Bergwandern'::text), ('Sport- und Langstreckenwandern'), ('Wandern') $$, 'TCBW deckt Wandern ab');
select is((select count(distinct qualification_type_id)::int from public.tk_qualification_sports), 10,
  'zehn Qualifikationsarten zugeordnet');

-- Direkte Schreibzugriffe abgelehnt
select set_config('request.jwt.claims', json_build_object('sub', 'b0000000-0000-4000-8000-000000000002', 'role', 'authenticated')::text, true);
set local role authenticated;
select throws_ok($$ insert into public.tk_plans (plan_type, referat_id, title, client_request_id)
                    values ('guided_tour', (select id from public.ea_referate where name = 'Touren'), 'X', gen_random_uuid()) $$,
  '42501', null, 'Geschäftsstelle: kein direktes Insert');
select throws_ok($$ update public.tk_plans set title = 'X' $$, '42501', null, 'kein direktes Update');
select throws_ok($$ delete from public.tk_plan_results $$, '42501', null, 'kein direktes Delete');
reset role;

-- Status nur über tk_change_status (auch für den Owner ohne Schalter)
select set_config('request.jwt.claims', json_build_object('sub', 'b0000000-0000-4000-8000-000000000013', 'role', 'authenticated')::text, true);
select set_config('test.p', (public.tk_save_plan('{"plan_type": "guided_tour", "title": "Status (Test)"}', null, null, null, null) ->> 'id'), true);
select throws_ok($$ update public.tk_plans set status = 'approved' where id = current_setting('test.p')::uuid $$,
  'P0001', 'TK_STATUS_DIRECT', 'Statuswechsel direkt abgelehnt');
select throws_ok($$ update public.tk_plans set plan_type = 'course', title = 'Kurs' where id = current_setting('test.p')::uuid
                    returning (case when referat_id = (select id from public.ea_referate where name = 'Ausbildung')
                               then 1/0 else 0 end) $$,
  '22012', null, 'Referat folgt dem Tourtyp (Trigger, R12)');

select * from finish();
rollback;
