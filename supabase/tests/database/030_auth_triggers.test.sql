-- US-AD-01 (spec T7 Teil): Trigger auf auth.users, R1 mit Testdomain, R2, R20.
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

-- Testpersonen (fiktiv)
insert into public.ea_persons (id, first_name, last_name) values
  ('c0000000-0000-4000-8000-000000000001', 'Nina', 'Neu'),
  ('c0000000-0000-4000-8000-000000000002', 'Otto', 'Ohnepass'),
  ('c0000000-0000-4000-8000-000000000003', 'Rita', 'Regel');
insert into public.ad_accesses (person_id, login_email) values
  ('c0000000-0000-4000-8000-000000000001', 'nina.neu@dav-leipzig.de'),
  ('c0000000-0000-4000-8000-000000000002', 'otto.ohnepass@dav-leipzig.de');

-- Anlage in Supabase Auth → auth_user_id gesetzt, none → invited
insert into auth.users (id, email, encrypted_password, aud, role) values
  ('d0000000-0000-4000-8000-000000000001', 'nina.neu@dav-leipzig.de', '', 'authenticated', 'authenticated'),
  ('d0000000-0000-4000-8000-000000000002', 'otto.ohnepass@dav-leipzig.de', '', 'authenticated', 'authenticated');
select results_eq(
  $$ select auth_user_id, status::text from public.ad_accesses
     where person_id = 'c0000000-0000-4000-8000-000000000001' $$,
  $$ values ('d0000000-0000-4000-8000-000000000001'::uuid, 'invited'::text) $$,
  'Insert in auth.users verknüpft den Zugang und setzt „eingeladen“'
);

-- erstes Passwort → aktiv; ohne Passwort bleibt eingeladen
update auth.users set encrypted_password = '$2a$10$abcdefghijklmnopqrstuv' where id = 'd0000000-0000-4000-8000-000000000001';
select is((select status::text from public.ad_accesses where person_id = 'c0000000-0000-4000-8000-000000000001'),
  'active', 'erstes Passwort setzt „aktiv“');
update auth.users set raw_user_meta_data = '{}'::jsonb, last_sign_in_at = now()
where id = 'd0000000-0000-4000-8000-000000000002';
select is((select status::text from public.ad_accesses where person_id = 'c0000000-0000-4000-8000-000000000002'),
  'invited', 'eingelöster Link ohne Passwort bleibt „eingeladen“ (US-AD-03 AK6)');

-- Anmeldung des Notfall-Admins wird protokolliert (R16)
update auth.users set last_sign_in_at = now() + interval '1 minute' where id = 'b0000000-0000-4000-8000-000000000008';
select is((select count(*)::int from public.ad_audit_log
           where action = 'emergency_login'
             and actor_user_id = 'b0000000-0000-4000-8000-000000000008'
             and subject_person_id = 'a0000000-0000-4000-8000-000000000008'
             and occurred_at = now()), 1,
  'Anmeldung Notfall-Admin protokolliert, Akteur ist der Notfall-Admin');
update auth.users set last_sign_in_at = now() + interval '2 minutes' where id = 'b0000000-0000-4000-8000-000000000001';
select is((select count(*)::int from public.ad_audit_log where action = 'emergency_login' and occurred_at = now()), 1,
  'Anmeldung anderer Nutzer wird nicht als Notfall-Anmeldung protokolliert');

-- R1 mit Testdomain (nur in dieser Transaktion)
select throws_ok(
  $$ insert into public.ad_accesses (person_id, login_email) values ('c0000000-0000-4000-8000-000000000003', 'rita@example.test') $$,
  'P0001', 'AD_EMAIL_DOMAIN', 'fremde Domain abgelehnt (R1)');
insert into public.ad_test_login_domains (domain) values ('example.test');
select lives_ok(
  $$ insert into public.ad_accesses (person_id, login_email) values ('c0000000-0000-4000-8000-000000000003', 'rita@example.test') $$,
  'freigegebene Testdomain erlaubt');
select throws_ok(
  $$ update public.ad_accesses set login_email = 'rita@woanders.test' where person_id = 'c0000000-0000-4000-8000-000000000003' $$,
  'P0001', 'AD_EMAIL_DOMAIN', 'R1 gilt auch beim Ändern');
delete from public.ad_test_login_domains;

-- ad_test_login_domains ist für Nutzer nicht lesbar
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select throws_ok($$ select * from public.ad_test_login_domains $$, '42501', null,
  'authenticated darf ad_test_login_domains nicht lesen');
select throws_ok($$ select public.ad_login_email_allowed('x@dav-leipzig.de') $$, '42501', null,
  'authenticated darf ad_login_email_allowed nicht direkt aufrufen');

-- Rollenfall: Admin speichert eine gültige Adresse ohne Rechtefehler
-- (id kommt per Default; authenticated hat kein Spaltenrecht auf id)
select lives_ok(
  $$ insert into public.ea_persons (first_name, last_name) values ('Erika', 'Gültig') $$,
  'Admin legt Person an');
select lives_ok(
  $$ insert into public.ad_accesses (person_id, login_email)
     select id, 'erika.gueltig@dav-leipzig.de' from public.ea_persons where last_name = 'Gültig' $$,
  'Admin speichert gültige Login-Adresse');
select lives_ok(
  $$ update public.ad_accesses set login_email = 'erika.gueltig2@dav-leipzig.de'
      where login_email = 'erika.gueltig@dav-leipzig.de' $$,
  'Admin ändert Login-Adresse bei „kein Zugang“');
select is((select a.login_email::text from public.ad_accesses a join public.ea_persons p on p.id = a.person_id
           where p.last_name = 'Gültig'),
  'erika.gueltig2@dav-leipzig.de', 'Änderung gespeichert');

-- R20
select throws_ok(
  $$ update public.ad_accesses set login_email = 'eva.neu@dav-leipzig.de' where person_id = 'a0000000-0000-4000-8000-000000000006' $$,
  'P0001', 'AD_EMAIL_CHANGE_VIA_FUNCTION', 'bei „eingeladen“ nicht direkt änderbar');
select throws_ok(
  $$ update public.ad_accesses set login_email = 'bernd.neu@dav-leipzig.de' where person_id = 'a0000000-0000-4000-8000-000000000003' $$,
  'P0001', 'AD_EMAIL_LOCKED', 'bei „aktiv“ nicht änderbar');
select throws_ok(
  $$ update public.ad_accesses set login_email = 'dieter.neu@dav-leipzig.de' where person_id = 'a0000000-0000-4000-8000-000000000007' $$,
  'P0001', 'AD_EMAIL_LOCKED', 'bei „gesperrt“ nicht änderbar');

-- R2
select throws_ok(
  $$ update public.ad_accesses set login_email = 'TEST.ADMIN@dav-leipzig.de' where login_email = 'erika.gueltig2@dav-leipzig.de' $$,
  '23505', null, 'Login-Adresse doppelt, auch bei anderer Schreibweise (R2)');

-- Statusspalten sind nicht direkt änderbar
select throws_ok(
  $$ update public.ad_accesses set status = 'active' where login_email = 'erika.gueltig2@dav-leipzig.de' $$,
  '42501', null, 'Status nur über Edge Functions und Trigger');

select pg_temp.as_owner();
select * from finish();
rollback;
