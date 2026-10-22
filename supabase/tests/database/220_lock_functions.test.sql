-- US-AD-09 (spec T7 Teil, T4 Teil): ad_apply_lock, ad_apply_unlock – nur service_role; R5, R10, R12.
-- Seed: Person 2 (Geschäftsstelle, aktiv, b…02), Person 6 (eingeladen, b…06 ohne Passwort), Person 7 (gesperrt, b…07).
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

select ok(not has_function_privilege('authenticated', 'public.ad_apply_lock(uuid, uuid)', 'EXECUTE'), 'authenticated: kein ad_apply_lock');
select ok(not has_function_privilege('authenticated', 'public.ad_apply_unlock(uuid, uuid)', 'EXECUTE'), 'authenticated: kein ad_apply_unlock');
select ok(has_function_privilege('service_role', 'public.ad_apply_lock(uuid, uuid)', 'EXECUTE'), 'service_role: ad_apply_lock');

-- Sperren: Geschäftsstelle verliert sofort alle Rechte (R5, R10)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select is(public.ad_user_level('EA'), 'manage'::public.ad_level, 'vorher: EA verwalten');
select pg_temp.as_owner();
select results_eq(
  $$ select status::text from public.ad_apply_lock('a0000000-0000-4000-8000-000000000002', 'b0000000-0000-4000-8000-000000000001') $$,
  $$ values ('locked'::text) $$, 'ad_apply_lock liefert „gesperrt“');
select results_eq(
  $$ select status::text, locked_at is not null, locked_by from public.ad_accesses where person_id = 'a0000000-0000-4000-8000-000000000002' $$,
  $$ values ('locked'::text, true, 'b0000000-0000-4000-8000-000000000001'::uuid) $$, 'gesperrt am/von gesetzt (AK1)');
select is((select count(*)::int from public.ad_audit_log
            where subject_person_id = 'a0000000-0000-4000-8000-000000000002' and action = 'locked'), 1, 'Protokoll „gesperrt“');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select is(public.ad_user_level('EA'), 'none'::public.ad_level, 'nach dem Sperren sofort keine Rechte (R5, R10)');
select pg_temp.as_owner();
select is((select count(*)::int from public.ea_properties where person_id = 'a0000000-0000-4000-8000-000000000002'), 1,
  'Eigenschaften bleiben erhalten (AK6, R12)');
select is((select count(*)::int from public.ad_template_assignments
            where person_id = 'a0000000-0000-4000-8000-000000000002' and revoked_at is null), 1, 'Zuweisung bleibt (AK6)');
select throws_ok($$ select public.ad_apply_lock('a0000000-0000-4000-8000-000000000002', null) $$,
  'P0001', 'AD_INVALID_STATUS', 'gesperrt kann nicht erneut gesperrt werden');
select throws_ok($$ select public.ad_apply_lock('a0000000-0000-4000-8000-000000000004', null) $$,
  'P0001', 'AD_INVALID_STATUS', 'ohne Zugang nichts zu sperren');

-- Entsperren: mit Passwort → aktiv (AK2), ohne Passwort → eingeladen (AK3)
select results_eq(
  $$ select status::text from public.ad_apply_unlock('a0000000-0000-4000-8000-000000000007', 'b0000000-0000-4000-8000-000000000001') $$,
  $$ values ('active'::text) $$, 'Dieter Gesperrt (mit Passwort) → aktiv');
select results_eq(
  $$ select status::text, locked_at, locked_by from public.ad_accesses where person_id = 'a0000000-0000-4000-8000-000000000007' $$,
  $$ values ('active'::text, null::timestamptz, null::uuid) $$, 'gesperrt am/von geleert');
select is((select count(*)::int from public.ad_audit_log
            where subject_person_id = 'a0000000-0000-4000-8000-000000000007' and action = 'unlocked'), 1, 'Protokoll „entsperrt“');
select lives_ok($$ select public.ad_apply_lock('a0000000-0000-4000-8000-000000000006', 'b0000000-0000-4000-8000-000000000001') $$,
  'eingeladen → gesperrt (Einladung zurückziehen)');
select results_eq(
  $$ select status::text from public.ad_apply_unlock('a0000000-0000-4000-8000-000000000006', 'b0000000-0000-4000-8000-000000000001') $$,
  $$ values ('invited'::text) $$, 'ohne Passwort → eingeladen (AK3)');
select throws_ok($$ select public.ad_apply_unlock('a0000000-0000-4000-8000-000000000001', null) $$,
  'P0001', 'AD_INVALID_STATUS', 'aktiv kann nicht entsperrt werden');

select * from finish();
rollback;
