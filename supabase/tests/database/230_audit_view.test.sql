-- US-AD-14 (spec T7 Teil, T4 Teil): ad_v_audit_log mit Namen; nur AD ≥ lesen; neueste zuerst.
-- Seed: 4 Einträge (invited, template_assigned, locked, emergency_login), Akteur Admin b…01 bzw. Notfall-Admin b…08.
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

select has_view('public', 'ad_v_audit_log', 'View vorhanden');
select ok(has_table_privilege('authenticated', 'public.ad_v_audit_log', 'SELECT'), 'authenticated darf lesen');
select ok(not has_table_privilege('authenticated', 'public.ad_v_audit_log', 'INSERT, UPDATE, DELETE'), 'nur lesen');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select is((select count(*)::int from public.ad_v_audit_log), 4, 'Admin sieht die 4 Seed-Einträge');
select results_eq(
  $$ select action::text, actor_name, subject_name, details from public.ad_v_audit_log order by occurred_at desc $$,
  $$ values ('emergency_login'::text, 'Geschäftsstelle Notfall-Admin'::text, 'Geschäftsstelle Notfall-Admin'::text, null::text),
            ('invited', 'Test Admin', 'Eva Eingeladen', null),
            ('locked', 'Test Admin', 'Dieter Gesperrt', null),
            ('template_assigned', 'Test Admin', 'Rita Referentin', 'Referent:in (Referate: Klettern)') $$,
  'Namen des Akteurs und der betroffenen Person, neueste zuerst (AK1)');

-- Rufname bevorzugt
select pg_temp.as_owner();
update public.ea_persons set preferred_name = 'Ritchie' where id = 'a0000000-0000-4000-8000-000000000009';
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select is((select subject_name from public.ad_v_audit_log where action = 'template_assigned'), 'Ritchie Referentin', 'Rufname in der Anzeige');

-- Akteur ohne Zugang (z. B. gelöschter Auth-Nutzer): Eintrag bleibt, Name leer
select pg_temp.as_owner();
insert into public.ad_audit_log (actor_user_id, subject_person_id, action)
values ('e0000000-0000-4000-8000-0000000000ee', 'a0000000-0000-4000-8000-000000000004', 'invited');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select is((select actor_name from public.ad_v_audit_log where subject_person_id = 'a0000000-0000-4000-8000-000000000004'), null,
  'unbekannter Akteur ohne Namen');

-- Ohne AD-Rechte keine Daten (AK5)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select is_empty($$ select 1 from public.ad_v_audit_log $$, 'Geschäftsstelle sieht nichts');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select is_empty($$ select 1 from public.ad_v_audit_log $$, 'Vorstand sieht nichts');

select pg_temp.as_owner();
select * from finish();
rollback;
