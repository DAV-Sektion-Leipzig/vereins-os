-- US-AD-02 (spec T7 Teil, T6 Teil): ad_me() liefert nur die eigene Person und den eigenen Zugang.
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

select ok(has_function_privilege('authenticated', 'public.ad_me()', 'EXECUTE'), 'authenticated darf ad_me aufrufen');
select ok(not has_function_privilege('anon', 'public.ad_me()', 'EXECUTE'), 'anon darf ad_me nicht aufrufen');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select results_eq(
  $$ select person_id, first_name, last_name, access_status::text from public.ad_me() $$,
  $$ values ('a0000000-0000-4000-8000-000000000001'::uuid, 'Test'::text, 'Admin'::text, 'active'::text) $$,
  'Admin erhält genau die eigene Person'
);

select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select results_eq(
  $$ select person_id, first_name, last_name, access_status::text from public.ad_me() $$,
  $$ values ('a0000000-0000-4000-8000-000000000002'::uuid, 'Anna'::text, 'Fiktiv'::text, 'active'::text) $$,
  'Geschäftsstelle erhält genau die eigene Person (ohne AD-Rechte)'
);

select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select results_eq(
  $$ select person_id, first_name, last_name, access_status::text from public.ad_me() $$,
  $$ values ('a0000000-0000-4000-8000-000000000003'::uuid, 'Bernd'::text, 'Beispiel'::text, 'active'::text) $$,
  'Vorstand erhält genau die eigene Person (ohne jede Leserechte)'
);

select pg_temp.as_user('b0000000-0000-4000-8000-000000000007');
select results_eq(
  $$ select access_status::text from public.ad_me() $$,
  $$ values ('locked'::text) $$,
  'gesperrter Zugang sieht den eigenen Status'
);

-- Ohne Zugang: Auth-Nutzer ohne Zeile in ad_accesses
select pg_temp.as_owner();
insert into auth.users (id, email, encrypted_password, aud, role)
values ('d0000000-0000-4000-8000-0000000000e1', 'ohne.zugang@example.test', '', 'authenticated', 'authenticated');
select pg_temp.as_user('d0000000-0000-4000-8000-0000000000e1');
select is_empty($$ select * from public.ad_me() $$, 'ohne Zugang keine Zeile');

-- Ohne Anmeldung
select pg_temp.as_owner();
select is_empty($$ select * from public.ad_me() $$, 'ohne auth.uid() keine Zeile');

select * from finish();
rollback;
