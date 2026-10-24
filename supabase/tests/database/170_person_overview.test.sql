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
select is((select count(*)::int from public.ad_v_person_overview), 26, 'Admin: 26 Personen (1–12, 19–32)');
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
  $$ values ('GR'::text, false) $$, 'Person 12: angelegt in Gruppen, aber ohne laufenden Bezug (Ü3)');
select results_eq(
  $$ select person_id from public.ad_v_person_overview where has_group_relation order by person_id $$,
  $$ values ('a0000000-0000-4000-8000-000000000023'::uuid), ('a0000000-0000-4000-8000-000000000024'),
            ('a0000000-0000-4000-8000-000000000025'), ('a0000000-0000-4000-8000-000000000026'),
            ('a0000000-0000-4000-8000-000000000028'), ('a0000000-0000-4000-8000-000000000029'),
            ('a0000000-0000-4000-8000-000000000030') $$,
  'Gruppenbezug über gr_has_current_relation (Ü3)');
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
select is((select count(*)::int from public.ad_v_person_overview), 18, 'Geschäftsstelle: nur Personen in den Pfaden EA und GR');
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
select is(public.ad_qualification_usage((select id from public.ad_qualification_types where code = 'TCSPI')), 2,
  'TCSPI: 2 Personen (Toni, Max)');
select is(public.ad_qualification_usage((select id from public.ad_qualification_types where code = 'TCBO')), 1,
  'TCBO: 1 Person (Lena)');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select throws_ok($$ select public.ad_qualification_usage((select id from public.ad_qualification_types where code = 'TCSPI')) $$,
  'P0001', 'AD_FORBIDDEN', 'Vorstand: AD_FORBIDDEN');

select pg_temp.as_owner();
select * from finish();
rollback;
