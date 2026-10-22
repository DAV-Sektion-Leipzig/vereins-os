-- US-AD-14, US-AD-15 (spec T7 Teil, T4 Teil): Hinweis auf Anmeldungen des Notfall-Admins, Löschlauf des Protokolls.
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

-- Hinweis (R16): Seed enthält eine Anmeldung des Notfall-Admins von gestern
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select is((select count from public.ad_pending_emergency_logins()), 1, 'eine offene Anmeldung (ohne Zeile in ad_notice_acks)');
select ok((select last_at from public.ad_pending_emergency_logins()) > now() - interval '2 days', 'mit Zeitpunkt');
select lives_ok($$ select public.ad_acknowledge_emergency() $$, '„Zur Kenntnis genommen“');
select is((select count from public.ad_pending_emergency_logins()), 0, 'danach keine offene Anmeldung');
select pg_temp.as_owner();
-- now() ist in der Transaktion fest; die spätere Anmeldung liegt deshalb eine Sekunde danach
insert into public.ad_audit_log (occurred_at, actor_user_id, subject_person_id, action)
values (now() + interval '1 second', 'b0000000-0000-4000-8000-000000000008', 'a0000000-0000-4000-8000-000000000008',
        'emergency_login');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select is((select count from public.ad_pending_emergency_logins()), 1, 'neue Anmeldung erscheint wieder');
select is((select count(*)::int from public.ad_notice_acks), 1, 'eigene Zeile lesbar');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select throws_ok($$ select * from public.ad_pending_emergency_logins() $$, 'P0001', 'AD_FORBIDDEN', 'Geschäftsstelle: AD_FORBIDDEN');
select throws_ok($$ select public.ad_acknowledge_emergency() $$, 'P0001', 'AD_FORBIDDEN', 'Geschäftsstelle: kein Bestätigen');
select is_empty($$ select 1 from public.ad_notice_acks $$, 'fremde Zeilen nicht lesbar');

-- Löschen eines Auth-Nutzers löscht seine Zeile mit (Aufräumen in TEST)
select pg_temp.as_owner();
delete from auth.users where id = 'b0000000-0000-4000-8000-000000000001';
select is((select count(*)::int from public.ad_notice_acks), 0, 'ad_notice_acks per cascade gelöscht');

-- Löschlauf nach 5 Jahren (R13, US-AD-14 AK2)
select results_eq($$ select schedule from cron.job where jobname = 'ad_audit_log_retention' $$,
  $$ values ('15 1 * * *'::text) $$, 'Job täglich 01:15 UTC');
insert into public.ad_audit_log (occurred_at, subject_person_id, action)
values (now() - interval '6 years', 'a0000000-0000-4000-8000-000000000004', 'invited'),
       (now() - interval '1 day', 'a0000000-0000-4000-8000-000000000005', 'invited');
do $$ begin execute (select command from cron.job where jobname = 'ad_audit_log_retention'); end $$;
select is((select count(*)::int from public.ad_audit_log where subject_person_id = 'a0000000-0000-4000-8000-000000000004'),
  0, 'Eintrag von vor 6 Jahren gelöscht');
select is((select count(*)::int from public.ad_audit_log where subject_person_id = 'a0000000-0000-4000-8000-000000000005'),
  1, 'Eintrag von gestern bleibt');

select * from finish();
rollback;
