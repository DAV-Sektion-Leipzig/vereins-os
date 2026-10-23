-- US-EA-05, US-EA-10 (plan.md EA O3): Codes beim Anlegen und Übernehmen über ea_create_volunteer und ea_activate_person.
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
create function pg_temp.art(p_key text) returns uuid language sql as $$
  select id from public.ea_property_types where system_key = p_key
$$;

-- Vorstand: kein EA-Recht (US-EA-05 AK6)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select throws_ok($$ select public.ea_create_volunteer('Kein', 'Recht', null, null, null, null, null) $$,
  'P0001', 'EA_CREATE_FORBIDDEN', 'Vorstand legt nicht an');
select throws_ok($$ select public.ea_activate_person('a0000000-0000-4000-8000-000000000011', null, null, null, null) $$,
  'P0001', 'EA_CREATE_FORBIDDEN', 'Vorstand übernimmt nicht');

-- Referent:in Klettern (R3 EA, R41 AD)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select throws_ok($$ select public.ea_create_volunteer('Ohne', 'Zuordnung', null, null, null, null, null) $$,
  'P0001', 'EA_CREATE_REFERAT_REQUIRED', 'ohne Funktion oder Amt (US-EA-05 AK2)');
select throws_ok($$ select public.ea_create_volunteer('Ohne', 'Referat', null, pg_temp.art('function'), null, '{"function": "Helfer:in"}', null) $$,
  'P0001', 'EA_CREATE_REFERAT_REQUIRED', 'Funktion ohne Referat');
select throws_ok($$ select public.ea_create_volunteer('Nur', 'Gremium', null, pg_temp.art('committee'), null, '{"role": "Mitglied"}', null) $$,
  'P0001', 'EA_CREATE_REFERAT_REQUIRED', 'Gremium ist keine Funktion oder kein Amt');
select throws_ok($$ select public.ea_create_volunteer('Fremd', 'Referat', null, pg_temp.art('function'), pg_temp.referat('Ausbildung'),
                    '{"function": "Helfer:in"}', null) $$,
  'P0001', 'EA_RELATION_FOREIGN_REFERAT', 'fremdes Referat');

create temp table created (id uuid);
grant all on created to authenticated;
select lives_ok($$ insert into created select public.ea_create_volunteer('Nina', 'Neu', null, pg_temp.art('function'),
                   pg_temp.referat('Klettern'), '{"function": "Helfer:in"}', null) $$,
  'Nina Neu mit Funktion Helfer:in im Referat Klettern (US-EA-05 AK1)');
select results_eq(
  $$ select p.volunteer_status::text, p.volunteer_status_since, p.created_in from public.ea_persons p join created c on c.id = p.id $$,
  $$ values ('active'::text, current_date, 'EA'::text) $$, 'aktiv ab heute, created_in EA (R4)');
select lives_ok($$ select public.ea_create_volunteer('Rita', 'Zwei', null, pg_temp.art('position'), pg_temp.referat('Klettern'),
                   '{"position": "stellv. Referent:in"}', null) $$, 'Amt im eigenen Referat');

-- Rückkehr (US-EA-10 AK1, AK5)
select throws_ok($$ select public.ea_activate_person('a0000000-0000-4000-8000-000000000011', null, null, null, null) $$,
  'P0001', 'EA_CREATE_REFERAT_REQUIRED', 'Wieder aktivieren ohne Funktion oder Amt (AK5)');
select lives_ok($$ select public.ea_activate_person('a0000000-0000-4000-8000-000000000011', pg_temp.art('function'),
                   pg_temp.referat('Klettern'), '{"function": "Trainer:in"}', null) $$, 'Olga wieder aktivieren');
select pg_temp.as_owner();
select results_eq($$ select volunteer_status::text, volunteer_status_since from public.ea_persons
                     where id = 'a0000000-0000-4000-8000-000000000011' $$,
  $$ values ('active'::text, current_date) $$, 'Olga aktiv ab heute');
select is((select count(*)::int from public.ea_persons where last_name = 'Ausgeschieden'), 1, 'keine neue Person');
select is((select count(*)::int from public.ea_volunteer_status_history where person_id = 'a0000000-0000-4000-8000-000000000011'), 2,
  'Historie bleibt und erhält einen Eintrag');

-- Geschäftsstelle: ohne Zuordnung erlaubt (US-EA-05 AK3), Übernahme Paul (US-EA-10 AK2)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select lives_ok($$ select public.ea_create_volunteer('Gremium', 'Mitglied', null, null, null, null, null) $$, 'ohne Zuordnung');
select lives_ok($$ select public.ea_activate_person('a0000000-0000-4000-8000-000000000012', pg_temp.art('function'),
                   pg_temp.referat('Touren'), '{"function": "Helfer:in"}', null) $$, 'Paul Nurgruppe übernehmen');
select is((select count(*)::int from public.ea_volunteer_list() where id = 'a0000000-0000-4000-8000-000000000012'), 1,
  'Paul in der Übersicht');

select pg_temp.as_owner();
select * from finish();
rollback;
