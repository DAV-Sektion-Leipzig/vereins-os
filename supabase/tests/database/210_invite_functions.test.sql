-- US-AD-08 (spec T7 Teil, T4 Teil): ad_apply_invite, ad_revert_invite, ad_apply_email_change – nur service_role.
-- Seed: Person 4 (Toni Muster, kein Zugang), Person 6 (Eva Eingeladen, b…06), Admin b…01.
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

-- Rechte
select ok(not has_function_privilege('authenticated', 'public.ad_apply_invite(uuid, uuid, uuid)', 'EXECUTE'), 'authenticated: kein ad_apply_invite');
select ok(not has_function_privilege('authenticated', 'public.ad_revert_invite(uuid, public.ad_access_status, uuid, timestamptz)', 'EXECUTE'), 'authenticated: kein ad_revert_invite');
select ok(not has_function_privilege('authenticated', 'public.ad_apply_email_change(uuid, extensions.citext, uuid)', 'EXECUTE'), 'authenticated: kein ad_apply_email_change');
select ok(has_function_privilege('service_role', 'public.ad_apply_invite(uuid, uuid, uuid)', 'EXECUTE'), 'service_role: ad_apply_invite');
select ok(has_function_privilege('service_role', 'public.ad_apply_email_change(uuid, extensions.citext, uuid)', 'EXECUTE'), 'service_role: ad_apply_email_change');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select throws_ok($$ select public.ad_apply_invite('a0000000-0000-4000-8000-000000000004', null, null) $$, '42501', null,
  'Admin kann die interne Funktion nicht direkt aufrufen');
select pg_temp.as_owner();

-- Einladen: Toni Muster bekommt einen Zugang (none); der Auth-Nutzer entsteht durch die Einladung
-- (hier ohne E-Mail angelegt, damit der Insert-Trigger nicht vorab verknüpft)
insert into public.ad_accesses (person_id, login_email) values ('a0000000-0000-4000-8000-000000000004', 'toni.muster@dav-leipzig.de');
insert into auth.users (id, aud, role, encrypted_password) values ('d0000000-0000-4000-8000-000000000004', 'authenticated', 'authenticated', '');
select results_eq(
  $$ select status::text, last_invited_at is not null from public.ad_apply_invite('a0000000-0000-4000-8000-000000000004',
       'd0000000-0000-4000-8000-000000000004', 'b0000000-0000-4000-8000-000000000001') $$,
  $$ values ('invited'::text, true) $$, 'ad_apply_invite liefert Status und Zeitpunkt');
select results_eq(
  $$ select status::text, auth_user_id, last_invited_at is not null from public.ad_accesses
      where person_id = 'a0000000-0000-4000-8000-000000000004' $$,
  $$ values ('invited'::text, 'd0000000-0000-4000-8000-000000000004'::uuid, true) $$, 'Zugang eingeladen und verknüpft');
select is((select count(*)::int from public.ad_audit_log
            where subject_person_id = 'a0000000-0000-4000-8000-000000000004' and action = 'invited'
              and actor_user_id = 'b0000000-0000-4000-8000-000000000001'), 1, 'Protokoll „eingeladen“ mit Akteur (R13)');
select lives_ok($$ select public.ad_apply_invite('a0000000-0000-4000-8000-000000000004', null, 'b0000000-0000-4000-8000-000000000001') $$,
  'erneut einladen bei „eingeladen“ erlaubt (AK4)');
select is((select auth_user_id from public.ad_accesses where person_id = 'a0000000-0000-4000-8000-000000000004'),
  'd0000000-0000-4000-8000-000000000004'::uuid, 'Verknüpfung bleibt bei erneuter Einladung');
select throws_ok($$ select public.ad_apply_invite('a0000000-0000-4000-8000-000000000001', null, null) $$,
  'P0001', 'AD_INVALID_STATUS', 'aktiver Zugang kann nicht eingeladen werden');

-- Zurücksetzen nach Mailfehler (AK5): Ausgangsstand ohne Protokoll
select lives_ok($$ select public.ad_revert_invite('a0000000-0000-4000-8000-000000000004', 'none', null, null) $$, 'ad_revert_invite');
select results_eq(
  $$ select status::text, auth_user_id, last_invited_at from public.ad_accesses where person_id = 'a0000000-0000-4000-8000-000000000004' $$,
  $$ values ('none'::text, null::uuid, null::timestamptz) $$, 'Ausgangsstand wiederhergestellt');
select is((select count(*)::int from public.ad_audit_log
            where subject_person_id = 'a0000000-0000-4000-8000-000000000004' and action = 'invited'), 2,
  'kein zusätzlicher Protokolleintrag durch das Zurücksetzen');

-- Login-Adresse bei „eingeladen“ ändern (R20, AK7): Eva Eingeladen
select lives_ok($$ select public.ad_apply_email_change('a0000000-0000-4000-8000-000000000006', 'eva.neu@dav-leipzig.de',
  'b0000000-0000-4000-8000-000000000001') $$, 'ad_apply_email_change');
select results_eq(
  $$ select login_email::text, status::text, auth_user_id from public.ad_accesses where person_id = 'a0000000-0000-4000-8000-000000000006' $$,
  $$ values ('eva.neu@dav-leipzig.de'::text, 'none'::text, null::uuid) $$, 'neue Adresse, kein Zugang, nicht mehr verknüpft');
select is((select details from public.ad_audit_log
            where subject_person_id = 'a0000000-0000-4000-8000-000000000006' and action = 'email_changed'),
  'test.eingeladen@dav-leipzig.de → eva.neu@dav-leipzig.de', 'Protokoll mit alter und neuer Adresse');
select throws_ok($$ select public.ad_apply_email_change('a0000000-0000-4000-8000-000000000001', 'x@dav-leipzig.de', null) $$,
  'P0001', 'AD_EMAIL_LOCKED', 'bei „aktiv“ nicht über diese Funktion (R20)');
select throws_ok($$ select public.ad_apply_email_change('a0000000-0000-4000-8000-000000000006', 'fremd@example.test', null) $$,
  'P0001', 'AD_EMAIL_LOCKED', 'nach der Änderung ist der Status „kein Zugang“ – nicht erneut über die Funktion');

select * from finish();
rollback;
