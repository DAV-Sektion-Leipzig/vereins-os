-- Review S-04: Login-Adresse in Supabase Auth nicht auf fremde Domain änderbar (R1) und
-- bei verknüpftem Zugang nur über die Administration (R20). Trigger ad_auth_user_email_guard.
-- Seed: b…01 test.admin@dav-leipzig.de (Zugang aktiv), b…06 test.eingeladen@dav-leipzig.de (eingeladen).
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

-- Trigger und Rechte
select has_trigger('auth', 'users', 'ad_auth_user_email_guard', 'Trigger auf auth.users vorhanden');
select ok(not has_function_privilege('authenticated', 'public.ad_auth_user_email_guard()', 'EXECUTE'),
  'authenticated: kein ad_auth_user_email_guard');
select ok(not has_function_privilege('anon', 'public.ad_auth_user_email_guard()', 'EXECUTE'),
  'anon: kein ad_auth_user_email_guard');

-- Auth-Nutzer ohne Zugang (fiktiv, z. B. per Dashboard angelegt), einer mit offener fremder Änderung
insert into auth.users (id, email, encrypted_password, aud, role, email_change) values
  ('d3500000-0000-4000-8000-000000000001', 'ohne.zugang@dav-leipzig.de', '', 'authenticated', 'authenticated', ''),
  ('d3500000-0000-4000-8000-000000000002', 'altlast@dav-leipzig.de', '', 'authenticated', 'authenticated', 'altlast@example.org');
select is((select count(*)::int from public.ad_accesses
           where auth_user_id in ('d3500000-0000-4000-8000-000000000001', 'd3500000-0000-4000-8000-000000000002')),
  0, 'Testnutzer ohne Zugang');

-- Regel 1 (R1): fremde Domain
select throws_ok(
  $$ update auth.users set email = 'privat@example.org' where id = 'b0000000-0000-4000-8000-000000000001' $$,
  'P0001', 'AD_EMAIL_DOMAIN', 'email auf fremde Domain abgelehnt');
select throws_ok(
  $$ update auth.users set email_change = 'privat@example.org' where id = 'b0000000-0000-4000-8000-000000000001' $$,
  'P0001', 'AD_EMAIL_DOMAIN', 'email_change auf fremde Domain abgelehnt (updateUser)');
select throws_ok(
  $$ update auth.users set email = 'privat@example.org', email_change = '' where id = 'b0000000-0000-4000-8000-000000000001' $$,
  'P0001', 'AD_EMAIL_DOMAIN', 'Bestätigung einer fremden Änderung abgelehnt');
select throws_ok(
  $$ update auth.users set email = 'privat@example.org' where id = 'd3500000-0000-4000-8000-000000000001' $$,
  'P0001', 'AD_EMAIL_DOMAIN', 'ohne Zugang: fremde Domain abgelehnt');
select throws_ok(
  $$ update auth.users set email_change = '@dav-leipzig.de' where id = 'd3500000-0000-4000-8000-000000000001' $$,
  'P0001', 'AD_EMAIL_DOMAIN', 'leerer lokaler Teil abgelehnt');
select is((select email::text from auth.users where id = 'b0000000-0000-4000-8000-000000000001'),
  'test.admin@dav-leipzig.de', 'Login-Adresse unverändert');

-- Leere Werte und andere Spalten gehen durch
select lives_ok(
  $$ update auth.users set email_change = '' where id = 'b0000000-0000-4000-8000-000000000001' $$,
  'email_change auf leer erlaubt');
select lives_ok(
  $$ update auth.users set email_change = null where id = 'b0000000-0000-4000-8000-000000000001' $$,
  'email_change auf NULL erlaubt');
select lives_ok(
  $$ update auth.users set last_sign_in_at = now(), encrypted_password = '$2a$10$abcdefghijklmnopqrstuv',
                           banned_until = null, raw_user_meta_data = '{}'::jsonb
      where id = 'b0000000-0000-4000-8000-000000000001' $$,
  'Login, Passwort, Bann, Metadaten unberührt');
select lives_ok(
  $$ update auth.users set email = email, email_change = email_change, last_sign_in_at = now()
      where id in ('b0000000-0000-4000-8000-000000000001', 'd3500000-0000-4000-8000-000000000002') $$,
  'vollständiges Zeilen-Update ohne Änderung der Adressen erlaubt (auch bei offener Altlast)');
select throws_ok(
  $$ update auth.users set email = email_change, email_change = '' where id = 'd3500000-0000-4000-8000-000000000002' $$,
  'P0001', 'AD_EMAIL_DOMAIN', 'offene fremde Änderung kann nicht bestätigt werden');

-- Regel 2 (R20): erlaubte Domain, aber ≠ login_email des verknüpften Zugangs
select throws_ok(
  $$ update auth.users set email = 'anderer.admin@dav-leipzig.de' where id = 'b0000000-0000-4000-8000-000000000001' $$,
  'P0001', 'AD_EMAIL_CHANGE_VIA_FUNCTION', 'aktiv: Adresse nur über die Administration');
select throws_ok(
  $$ update auth.users set email_change = 'anderer.admin@dav-leipzig.de' where id = 'b0000000-0000-4000-8000-000000000001' $$,
  'P0001', 'AD_EMAIL_CHANGE_VIA_FUNCTION', 'aktiv: email_change nur über die Administration');
select throws_ok(
  $$ update auth.users set email = 'eva.neu@dav-leipzig.de' where id = 'b0000000-0000-4000-8000-000000000006' $$,
  'P0001', 'AD_EMAIL_CHANGE_VIA_FUNCTION', 'eingeladen: Adresse nur über die Administration');
select lives_ok(
  $$ update auth.users set email = 'TEST.ADMIN@dav-leipzig.de' where id = 'b0000000-0000-4000-8000-000000000001' $$,
  'Adresse gleich login_email (andere Schreibweise) erlaubt');
update auth.users set email = 'test.admin@dav-leipzig.de' where id = 'b0000000-0000-4000-8000-000000000001';

-- Ohne Zugang gilt nur Regel 1
select lives_ok(
  $$ update auth.users set email = 'ohne.zugang2@dav-leipzig.de' where id = 'd3500000-0000-4000-8000-000000000001' $$,
  'ohne Zugang: erlaubte Domain zulässig');

-- Testdomain (nur in dieser Transaktion)
insert into public.ad_test_login_domains (domain) values ('example.test');
select lives_ok(
  $$ update auth.users set email_change = 'ohne.zugang@example.test' where id = 'd3500000-0000-4000-8000-000000000001' $$,
  'ohne Zugang: freigegebene Testdomain zulässig');
select throws_ok(
  $$ update auth.users set email_change = 'test.admin@example.test' where id = 'b0000000-0000-4000-8000-000000000001' $$,
  'P0001', 'AD_EMAIL_CHANGE_VIA_FUNCTION', 'mit Zugang: Testdomain ≠ login_email abgelehnt');
delete from public.ad_test_login_domains;

-- Ablauf der Administration (change_email): löscht den Auth-Eintrag und legt ihn neu an.
-- Die Neuanlage (insert) ist vom Trigger nicht betroffen.
select lives_ok(
  $$ insert into auth.users (id, email, encrypted_password, aud, role)
     values ('d3500000-0000-4000-8000-000000000003', 'neu.angelegt@dav-leipzig.de', '', 'authenticated', 'authenticated') $$,
  'Neuanlage in Supabase Auth nicht betroffen');

select * from finish();
rollback;
