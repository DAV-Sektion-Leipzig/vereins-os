-- Review-Befund S-01: Schutz vor Aussperren (R14) – ad_apply_lock, ad_check_lock, ad_revoke_template,
-- Trigger ad_template_rights_keep_admin.
-- Seed: b…01 Admin (aktiv), b…02 Geschäftsstelle (aktiv, ohne AD), b…03 Vorstand (aktiv, ohne AD),
-- b…08 Notfall-Admin (aktiv, is_emergency, Vorlage Admin).
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
create function pg_temp.template(p_name text) returns uuid language sql as $$
  select id from public.ad_templates where name = p_name
$$;

-- Rechte
select ok(not has_function_privilege('authenticated', 'public.ad_manage_remains(uuid, uuid)', 'EXECUTE'),
  'ad_manage_remains intern');
select ok(not has_function_privilege('authenticated', 'public.ad_check_lock(uuid, uuid)', 'EXECUTE'),
  'authenticated: kein ad_check_lock');
select ok(has_function_privilege('service_role', 'public.ad_check_lock(uuid, uuid)', 'EXECUTE'),
  'service_role: ad_check_lock');
select ok(not has_function_privilege('authenticated', 'public.ad_apply_lock(uuid, uuid)', 'EXECUTE'),
  'authenticated: weiterhin kein ad_apply_lock');
select ok(public.ad_manage_remains(), 'Seed: aktive Admins vorhanden');

-- Sperren: Notfall-Admin, Selbstsperre
select throws_ok($$ select public.ad_apply_lock('a0000000-0000-4000-8000-000000000008', 'b0000000-0000-4000-8000-000000000001') $$,
  'P0001', 'AD_EMERGENCY_PROTECTED', 'Notfallzugang kann nicht gesperrt werden');
select throws_ok($$ select public.ad_check_lock('a0000000-0000-4000-8000-000000000008', 'b0000000-0000-4000-8000-000000000001') $$,
  'P0001', 'AD_EMERGENCY_PROTECTED', 'ad_check_lock: Notfallzugang');
select throws_ok($$ select public.ad_apply_lock('a0000000-0000-4000-8000-000000000001', 'b0000000-0000-4000-8000-000000000001') $$,
  'P0001', 'AD_SELF_LOCK', 'eigener Zugang kann nicht gesperrt werden');
select is((select status::text from public.ad_accesses where person_id = 'a0000000-0000-4000-8000-000000000001'), 'active',
  'Admin bleibt aktiv');
select throws_ok($$ select public.ad_check_lock('a0000000-0000-4000-8000-000000000004', null) $$,
  'P0001', 'AD_INVALID_STATUS', 'ad_check_lock: ohne Zugang');
select lives_ok($$ select public.ad_check_lock('a0000000-0000-4000-8000-000000000002', 'b0000000-0000-4000-8000-000000000001') $$,
  'ad_check_lock: anderer Zugang ohne Einwand');
select lives_ok($$ select public.ad_apply_lock('a0000000-0000-4000-8000-000000000002', 'b0000000-0000-4000-8000-000000000001') $$,
  'anderer Zugang wird gesperrt');
select is((select status::text from public.ad_accesses where person_id = 'a0000000-0000-4000-8000-000000000002'), 'locked',
  'Geschäftsstelle gesperrt');

-- Entziehen: Vorlage des Notfall-Admins
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select throws_ok(
  $$ select public.ad_revoke_template('a0000000-0000-4000-8000-000000000008', pg_temp.template('Admin')) $$,
  'P0001', 'AD_EMERGENCY_PROTECTED', 'Vorlage Admin des Notfall-Admins kann nicht entzogen werden');
select is((select count(*)::int from public.ad_template_assignments
            where person_id = 'a0000000-0000-4000-8000-000000000008' and revoked_at is null), 1,
  'Zuweisung des Notfall-Admins bleibt');

-- Weiterer Admin: Zuweisen und Entziehen bleibt möglich, solange ein Admin bleibt
select lives_ok(
  $$ select public.ad_assign_template('a0000000-0000-4000-8000-000000000003', pg_temp.template('Admin')) $$,
  'Vorstand erhält Vorlage Admin');
select lives_ok(
  $$ select public.ad_revoke_template('a0000000-0000-4000-8000-000000000003', pg_temp.template('Admin')) $$,
  'Vorlage Admin entziehen, solange weitere Admins bleiben');

-- Notfall-Admin noch nicht aktiv (wie in PROD nach dem Einrichtungsskript): Admin b…01 ist der letzte aktive Admin
select pg_temp.as_owner();
update public.ad_accesses set status = 'invited' where person_id = 'a0000000-0000-4000-8000-000000000008';
select ok(public.ad_manage_remains() and not public.ad_manage_remains(p_exclude_person => 'a0000000-0000-4000-8000-000000000001'),
  'nur noch b…01 kann AD verwalten');
select throws_ok($$ select public.ad_apply_lock('a0000000-0000-4000-8000-000000000001', null) $$,
  'P0001', 'AD_LAST_ADMIN', 'letzter aktiver Admin kann nicht gesperrt werden');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select throws_ok(
  $$ select public.ad_revoke_template('a0000000-0000-4000-8000-000000000001', pg_temp.template('Admin')) $$,
  'P0001', 'AD_LAST_ADMIN', 'Vorlage des letzten aktiven Admins kann nicht entzogen werden');
select throws_ok(
  $$ update public.ad_template_rights set level = 'none' where template_id = pg_temp.template('Admin') and module_code = 'AD' $$,
  'P0001', 'AD_LAST_ADMIN', 'AD „kein Zugriff“ in der einzigen Admin-Vorlage abgelehnt');
select throws_ok(
  $$ update public.ad_template_rights set level = 'edit' where template_id = pg_temp.template('Admin') and module_code = 'AD' $$,
  'P0001', 'AD_LAST_ADMIN', 'AD „bearbeiten“ in der einzigen Admin-Vorlage abgelehnt');
select is((select r.level::text from public.ad_template_rights r
            where r.template_id = pg_temp.template('Admin') and r.module_code = 'AD'), 'manage',
  'Admin-Vorlage unverändert');
select lives_ok(
  $$ update public.ad_template_rights set level = 'read' where template_id = pg_temp.template('Admin') and module_code = 'EA' $$,
  'andere Module der Admin-Vorlage bleiben änderbar');

-- Stufe AD herabsetzen, wenn ein anderer aktiver Admin bleibt; Vorlage ohne aktive Zuweisung ist frei änderbar
select pg_temp.as_owner();
select lives_ok(
  $$ update public.ad_template_rights set level = 'manage' where template_id = pg_temp.template('Budgetpflege') and module_code = 'AD' $$,
  'Budgetpflege (ohne Zuweisung): AD verwalten');
select lives_ok(
  $$ update public.ad_template_rights set level = 'none' where template_id = pg_temp.template('Budgetpflege') and module_code = 'AD' $$,
  'Budgetpflege (ohne Zuweisung): AD wieder kein Zugriff');
select lives_ok(
  $$ update public.ad_template_rights set level = 'manage' where template_id = pg_temp.template('Vorstand') and module_code = 'AD' $$,
  'Vorstand: AD verwalten');
select lives_ok(
  $$ update public.ad_template_rights set level = 'read' where template_id = pg_temp.template('Admin') and module_code = 'AD' $$,
  'Admin-Vorlage herabsetzen, weil Vorstand AD verwalten kann');
select throws_ok(
  $$ update public.ad_template_rights set level = 'none' where template_id = pg_temp.template('Vorstand') and module_code = 'AD' $$,
  'P0001', 'AD_LAST_ADMIN', 'letzte Vorlage mit AD verwalten kann nicht herabgesetzt werden');
select throws_ok(
  $$ update public.ad_template_rights set level = 'none' where module_code = 'AD' $$,
  'P0001', 'AD_LAST_ADMIN', 'Herabsetzen aller Vorlagen in einer Anweisung abgelehnt');

select * from finish();
rollback;
