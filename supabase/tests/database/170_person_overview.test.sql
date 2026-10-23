-- US-AD-06, US-AD-24 (spec T7 Teil, T6, T41): Personenübersicht, ad_me mit Rufname, Verwendung von Qualifikationsarten.
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

select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select is((select count(*)::int from public.ad_v_person_overview), 16, 'Admin: 16 Personen (1–12, 19–22)');
select results_eq(
  $$ select access_status::text, volunteer_status::text, templates from public.ad_v_person_overview
      where person_id = 'a0000000-0000-4000-8000-000000000009' $$,
  $$ values ('active'::text, 'active'::text, array['Referent:in (Klettern)']) $$,
  'Rita: Zugang aktiv, Ehrenamtsstatus, Vorlage mit Referat');
select results_eq(
  $$ select access_status::text, login_email::text, templates from public.ad_v_person_overview
      where person_id = 'a0000000-0000-4000-8000-000000000004' $$,
  $$ values ('none'::text, null::text, '{}'::text[]) $$, 'ohne Zugang: Status „kein Zugang“');
select results_eq(
  $$ select kind::text from public.ad_v_person_overview where person_id = 'a0000000-0000-4000-8000-000000000008' $$,
  $$ values ('function'::text) $$, 'Funktionsperson mit Kennzeichen');
select results_eq(
  $$ select created_in, has_group_relation from public.ad_v_person_overview
      where person_id = 'a0000000-0000-4000-8000-000000000012' $$,
  $$ values ('GR'::text, true) $$, 'Person 12: Gruppenbezug (bis zur ersten GR-Migration über created_in)');
select results_eq(
  $$ select templates from public.ad_v_person_overview where person_id = 'a0000000-0000-4000-8000-000000000001' $$,
  $$ values (array['Admin']) $$, 'Vorlage ohne Referate ohne Klammer');

-- Rufname suchbar (US-AD-24)
select pg_temp.as_owner();
update public.ea_persons set preferred_name = 'Tonino' where id = 'a0000000-0000-4000-8000-000000000004';
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select results_eq($$ select person_id from public.ad_v_person_overview where preferred_name ilike '%nino%' $$,
  $$ values ('a0000000-0000-4000-8000-000000000004'::uuid) $$, 'Suche über den Rufnamen');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select is((select count(*)::int from public.ad_v_person_overview), 9, 'Geschäftsstelle: nur Personen im Pfad EA');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select is((select count(*)::int from public.ad_v_person_overview), 0, 'Vorstand: keine Zeilen');

-- ad_me mit Rufname
select pg_temp.as_owner();
update public.ea_persons set preferred_name = 'Ritchie' where id = 'a0000000-0000-4000-8000-000000000009';
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select results_eq($$ select first_name, preferred_name, last_name, access_status::text from public.ad_me() $$,
  $$ values ('Rita'::text, 'Ritchie'::text, 'Referentin'::text, 'active'::text) $$, 'ad_me liefert den Rufnamen');

-- Verwendung einer Qualifikationsart (nur die Zahl)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select is(public.ad_qualification_usage((select id from public.ad_qualification_types where code = 'TCSPI')), 1,
  'TCSPI: 1 Person');
select is(public.ad_qualification_usage((select id from public.ad_qualification_types where code = 'TCBO')), 0,
  'TCBO: 0 Personen');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select throws_ok($$ select public.ad_qualification_usage((select id from public.ad_qualification_types where code = 'TCSPI')) $$,
  'P0001', 'AD_FORBIDDEN', 'Vorstand: AD_FORBIDDEN');

select pg_temp.as_owner();
select * from finish();
rollback;
