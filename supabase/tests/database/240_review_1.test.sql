-- Kern v0.7.4 (Review 1): ad_login_email_ok, Protokoll bei Dashboard-Einladung, ea_check_create, Grants.
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
create function pg_temp.referat(p_name text) returns uuid language sql as $$
  select id from public.ea_referate where name = p_name
$$;

-- 1. kein Orakel über Referatszugehörigkeit
select ok(not has_function_privilege('authenticated', 'public.ea_person_in_referate(uuid, uuid[])', 'EXECUTE'),
  'ea_person_in_referate nicht für authenticated');

-- 2. ad_login_email_ok (R1 im Frontend)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select ok(public.ad_login_email_ok('neu@dav-leipzig.de'), 'Admin: @dav-leipzig.de ok');
select ok(not public.ad_login_email_ok('neu@example.test'), 'Admin: fremde Domain nicht ok');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select ok(public.ad_login_email_ok('neu@dav-leipzig.de'), 'Referent:in (EA bearbeiten, Reichweite Referat) darf prüfen');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select throws_ok($$ select public.ad_login_email_ok('neu@dav-leipzig.de') $$, 'P0001', 'AD_FORBIDDEN', 'Vorstand darf nicht prüfen');
select pg_temp.as_owner();
insert into public.ad_test_login_domains (domain) values ('example.test');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select ok(public.ad_login_email_ok('neu@example.test'), 'Testdomain in TEST erlaubt (R1-Ausnahme)');
select throws_ok($$ select domain from public.ad_test_login_domains $$, '42501', null, 'Testdomains bleiben unsichtbar');

-- 3. Dashboard-Einladung protokolliert; ad-invite vervollständigt den Eintrag (kein Doppel)
select pg_temp.as_owner();
insert into public.ad_accesses (person_id, login_email) values ('a0000000-0000-4000-8000-000000000004', 'toni.muster@dav-leipzig.de');
insert into auth.users (id, email, encrypted_password, aud, role)
values ('d0000000-0000-4000-8000-000000000004', 'toni.muster@dav-leipzig.de', '', 'authenticated', 'authenticated');
select results_eq(
  $$ select actor_user_id, details from public.ad_audit_log
      where subject_person_id = 'a0000000-0000-4000-8000-000000000004' and action = 'invited' $$,
  $$ values (null::uuid, 'Einladung über das Supabase-Dashboard'::text) $$,
  'Dashboard-Einladung: Protokoll ohne Akteur');
select lives_ok($$ select public.ad_apply_invite('a0000000-0000-4000-8000-000000000004', 'd0000000-0000-4000-8000-000000000004',
  'b0000000-0000-4000-8000-000000000001') $$, 'ad-invite nach dem Trigger');
select results_eq(
  $$ select actor_user_id, details from public.ad_audit_log
      where subject_person_id = 'a0000000-0000-4000-8000-000000000004' and action = 'invited' $$,
  $$ values ('b0000000-0000-4000-8000-000000000001'::uuid, null::text) $$,
  'ad_apply_invite vervollständigt den Eintrag statt zu doppeln');
select lives_ok($$ select public.ad_apply_invite('a0000000-0000-4000-8000-000000000004', null, 'b0000000-0000-4000-8000-000000000001') $$,
  'erneut einladen');
select is((select count(*)::int from public.ad_audit_log
            where subject_person_id = 'a0000000-0000-4000-8000-000000000004' and action = 'invited'), 2,
  'erneute Einladung ergibt einen zweiten Eintrag');
-- Seed-Auth-Nutzer mit vorgegebenem Status (last_invited_at gesetzt) erzeugen keinen Eintrag: Seed hat genau 1 „invited“ (Eva)
select is((select count(*)::int from public.ad_audit_log where action = 'invited' and details = 'Einladung über das Supabase-Dashboard'), 0,
  'keine Dashboard-Einträge aus dem Seed');

-- 4. ea_check_create: Lesestufe und Bezugsart
select pg_temp.as_owner();
insert into public.ea_property_types (id, name, purpose, read_level, relation_kind, relation_required, visible_in)
values ('d0000000-0000-4000-8000-0000000000cc', 'Geheime Zuordnung', 'Test', 'confidential', 'referat', true, '{AD}');
insert into public.ea_property_fields (property_type_id, key, label, data_type, sort_order)
values ('d0000000-0000-4000-8000-0000000000cc', 'note', 'Notiz', 'text', 1);
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select throws_ok(format($$ select public.ea_create_volunteer('Neu', 'Geheim', null, 'd0000000-0000-4000-8000-0000000000cc', %L, '{"note": "x"}', null) $$,
  pg_temp.referat('Klettern')), 'P0001', 'AD_CONFIDENTIAL_ONLY_AD', 'Geschäftsstelle: vertrauliche Art nicht über ea_create_volunteer (R29)');
select throws_ok(format($$ select public.ea_create_volunteer('Neu', 'Falsch', null, 'd0000000-0000-4000-8000-000000000002', %L, '{"size": "M"}', null) $$,
  pg_temp.referat('Klettern')), 'P0001', 'AD_BAD_REQUEST', 'Art ohne Referatsbezug zusammen mit Referat abgelehnt');
select lives_ok($$ select public.ea_create_volunteer('Neu', 'Shirt', null, 'd0000000-0000-4000-8000-000000000002', null, '{"size": "M"}', null) $$,
  'Geschäftsstelle: Art ohne Bezug ohne Referat erlaubt (Reichweite alle)');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select throws_ok($$ select public.ea_create_volunteer('Neu', 'Ohne', null, 'd0000000-0000-4000-8000-000000000002', null, '{"size": "M"}', null) $$,
  'P0001', 'EA_CREATE_REFERAT_REQUIRED', 'Referent:in: Art ohne Referatsbezug abgelehnt (R41; Code nach EA O3)');
select throws_ok(format($$ select public.ea_activate_person('a0000000-0000-4000-8000-000000000011', 'd0000000-0000-4000-8000-0000000000cc', %L, '{"note": "x"}', null) $$,
  pg_temp.referat('Klettern')), 'P0001', 'AD_CONFIDENTIAL_ONLY_AD', 'Referent:in: vertrauliche Art auch beim Übernehmen abgelehnt');
select lives_ok(format($$ select public.ea_create_volunteer('Neu', 'Richtig', null, (select id from public.ea_property_types where system_key = 'function'), %L, '{"function": "Helfer:in"}', null) $$,
  pg_temp.referat('Klettern')), 'Referent:in: Funktion mit eigenem Referat weiterhin erlaubt');

select pg_temp.as_owner();
select * from finish();
rollback;
