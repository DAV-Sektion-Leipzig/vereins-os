-- Nachtrag v0.8 (spec T53, T56 Teil; US-AD-30; Übergabe EZ A4, A9; R45, R45a): Anlegen und Wieder-aktiv-Eintragen
-- über die Anwesenheitserfassung. Der EZ-Weg gilt nur, wenn der Aufruf ausschließlich über EZ-Rechte erlaubt ist
-- (spec.md Abschnitt 2; Entscheidung Product Owner 24.10.2026). Dafür legt der Test einen Nutzer an, der nur
-- „Anwesenheitserfassung bearbeiten“ mit Reichweite Referat (Klettern) hat. Rita Referentin hat zusätzlich EA-Rechte
-- und nutzt deshalb den EA-Weg.
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
create function pg_temp.p(n int) returns uuid language sql as $$
  select ('a0000000-0000-4000-8000-' || lpad(n::text, 12, '0'))::uuid
$$;
-- IDs als Eigentümer ermitteln (der Testnutzer ohne EA-Rechte liest die Eigenschaftsarten nicht)
create temp table ids as
  select (select id from public.ea_property_types where system_key = 'function') as fn,
         (select id from public.ea_property_types where system_key = 'employment') as employment;
create temp table referate as select id, name from public.ea_referate;
grant select on ids, referate to authenticated;
create function pg_temp.referat(p_name text) returns uuid language sql as $$
  select id from referate where name = p_name
$$;
create function pg_temp.fn() returns uuid language sql as $$
  select fn from ids
$$;

-- Testnutzer nur mit EZ bearbeiten, Reichweite Referat, Referat Klettern
insert into public.ea_persons (id, first_name, last_name, created_in)
values ('a0000000-0000-4000-8000-0000000000e1', 'Erik', 'Erfasser', 'AD');
insert into public.ad_templates (id, name, description)
values ('c1000000-0000-4000-8000-0000000000e1', 'Nur Anwesenheit (Test)', 'nur Test');
update public.ad_template_rights set level = 'edit', scope = 'referat'
 where template_id = 'c1000000-0000-4000-8000-0000000000e1' and module_code = 'EZ';
insert into public.ad_accesses (person_id, login_email, status, is_emergency, last_invited_at)
values ('a0000000-0000-4000-8000-0000000000e1', 'test.erfasser@dav-leipzig.de', 'active', false, now() - interval '1 day');
insert into public.ad_template_assignments (id, person_id, template_id)
values ('c2000000-0000-4000-8000-0000000000e1', 'a0000000-0000-4000-8000-0000000000e1', 'c1000000-0000-4000-8000-0000000000e1');
insert into public.ad_assignment_referate (assignment_id, referat_id)
values ('c2000000-0000-4000-8000-0000000000e1', pg_temp.referat('Klettern'));
insert into auth.users (id, email, encrypted_password, aud, role)
values ('b0000000-0000-4000-8000-0000000000e1', 'test.erfasser@dav-leipzig.de', 'x', 'authenticated', 'authenticated');

select ok(not has_function_privilege('authenticated', 'public.ea_create_path(uuid, uuid, jsonb)', 'EXECUTE'),
  'ea_create_path nur intern');

select pg_temp.as_user('b0000000-0000-4000-8000-0000000000e1');
select ok(not public.ad_has_any_level('EA', 'edit') and public.ad_has_any_level('EZ', 'edit'), 'Testnutzer: nur EZ-Rechte');

-- R45: Helfer:in anlegen über den EZ-Weg
create temp table neu (id uuid);
grant all on neu to authenticated;
select lives_ok(format($$ insert into neu select public.ea_create_volunteer('Hanna', 'Helferin', null, %L, %L,
  '{"function": "Helfer:in"}', date '2026-10-24', '  hanna.helferin@example.test ') $$, pg_temp.fn(), pg_temp.referat('Klettern')),
  'EZ: Helfer:in im eigenen Referat angelegt');
select pg_temp.as_owner();
select results_eq(
  $$ select p.created_in, p.volunteer_status::text, p.volunteer_status_since from public.ea_persons p join neu on neu.id = p.id $$,
  $$ values ('EZ'::text, 'active'::text, date '2026-10-24') $$, 'created_in EZ, Status aktiv');
select is((select count(*)::int from public.ea_volunteer_status_history h join neu on neu.id = h.person_id), 1, 'Historie');
select results_eq(
  $$ select t.system_key, e.field_values, e.related_referat_id from public.ea_properties e
       join public.ea_property_types t on t.id = e.property_type_id join neu on neu.id = e.person_id order by t.system_key $$,
  format($$ values ('contact'::text, '{"email": "hanna.helferin@example.test"}'::jsonb, null::uuid),
                   ('function', '{"function": "Helfer:in"}'::jsonb, %L::uuid) $$, pg_temp.referat('Klettern')),
  'Funktion Helfer:in im Referat Klettern und Kontakt-E-Mail (getrimmt)');

select pg_temp.as_user('b0000000-0000-4000-8000-0000000000e1');
select throws_ok(format($$ select public.ea_create_volunteer('X', 'Ausbildung', null, %L, %L, '{"function": "Helfer:in"}', null) $$,
  pg_temp.fn(), pg_temp.referat('Ausbildung')), 'P0001', 'EA_RELATION_FOREIGN_REFERAT', 'EZ: fremdes Referat');
select throws_ok(format($$ select public.ea_create_volunteer('X', 'Trainer', null, %L, %L, '{"function": "Trainer:in"}', null) $$,
  pg_temp.fn(), pg_temp.referat('Klettern')), 'P0001', 'EA_CREATE_FORBIDDEN', 'EZ: Trainer:in abgelehnt');
select throws_ok(format($$ select public.ea_create_volunteer('X', 'Einheiten', null, %L, %L,
  '{"function": "Helfer:in", "training_units_per_week": 2}', null) $$, pg_temp.fn(), pg_temp.referat('Klettern')),
  'P0001', 'EA_CREATE_FORBIDDEN', 'EZ: weitere Feldschlüssel abgelehnt');
select throws_ok(format($$ select public.ea_create_volunteer('X', 'OhneReferat', null, %L, null, '{"function": "Helfer:in"}', null) $$,
  pg_temp.fn()), 'P0001', 'EA_CREATE_FORBIDDEN', 'EZ: ohne Referat abgelehnt');
select throws_ok($$ select public.ea_create_volunteer('X', 'Shirt', null, 'd0000000-0000-4000-8000-000000000002', null, '{"size": "M"}', null) $$,
  'P0001', 'EA_CREATE_FORBIDDEN', 'EZ: andere Eigenschaftsart abgelehnt');
select lives_ok($$ select * from public.ad_find_similar_persons('Tony', 'Muster', null) $$, 'EZ: Dublettenprüfung erlaubt (R45)');

-- EA-Weg bleibt für Nutzer mit EA-Rechten maßgeblich
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
delete from neu;
select lives_ok(format($$ insert into neu select public.ea_create_volunteer('Rita', 'Helfer', null, %L, %L,
  '{"function": "Helfer:in"}', null) $$, pg_temp.fn(), pg_temp.referat('Klettern')), 'Referent:in legt Helfer:in an');
select lives_ok(format($$ select public.ea_create_volunteer('Rita', 'Trainer', null, %L, %L, '{"function": "Trainer:in"}', null) $$,
  pg_temp.fn(), pg_temp.referat('Klettern')), 'Referent:in: Trainer:in erlaubt (EA-Weg)');
select throws_ok(format($$ select public.ea_create_volunteer('Rita', 'Fremd', null, %L, %L, '{"function": "Helfer:in"}', null) $$,
  pg_temp.fn(), pg_temp.referat('Ausbildung')), 'P0001', 'EA_RELATION_FOREIGN_REFERAT', 'Referent:in: fremdes Referat');
select pg_temp.as_owner();
select is((select p.created_in from public.ea_persons p join neu on neu.id = p.id), 'EA', 'Referent:in: created_in EA');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select throws_ok($$ select public.ea_create_volunteer('X', 'Vertraulich', null,
  (select employment from ids), null, '{"title": "x"}', null) $$,
  'P0001', 'AD_CONFIDENTIAL_ONLY_AD', 'Geschäftsstelle: Meldung des EA-Wegs bleibt (vertrauliche Art)');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select throws_ok(format($$ select public.ea_create_volunteer('X', 'Vorstand', null, %L, %L, '{"function": "Helfer:in"}', null) $$,
  pg_temp.fn(), pg_temp.referat('Klettern')), 'P0001', 'EA_CREATE_FORBIDDEN', 'Vorstand: abgelehnt');

-- R45a: wieder aktiv eintragen über den EZ-Weg (Tabelle „Reaktivieren“, spec.md Abschnitt 9)
select pg_temp.as_user('b0000000-0000-4000-8000-0000000000e1');
select lives_ok(format($$ select public.ea_activate_person(%L, %L, %L, '{"function": "Helfer:in"}', date '2026-10-24') $$,
  pg_temp.p(11), pg_temp.fn(), pg_temp.referat('Klettern')), 'EZ: Olga Ausgeschieden wieder aktiv');
select lives_ok(format($$ select public.ea_activate_person(%L, %L, %L, '{"function": "Helfer:in"}', date '2026-10-24') $$,
  pg_temp.p(12), pg_temp.fn(), pg_temp.referat('Klettern')), 'EZ: Paul Nurgruppe (ohne Status) aktiv');
select throws_ok(format($$ select public.ea_activate_person(%L, %L, %L, '{"function": "Helfer:in"}', null) $$,
  pg_temp.p(5), pg_temp.fn(), pg_temp.referat('Ausbildung')), 'P0001', 'EA_RELATION_FOREIGN_REFERAT', 'EZ: fremdes Referat');
select throws_ok(format($$ select public.ea_activate_person(%L, %L, %L, '{"function": "Trainer:in"}', null) $$,
  pg_temp.p(5), pg_temp.fn(), pg_temp.referat('Klettern')), 'P0001', 'EA_CREATE_FORBIDDEN', 'EZ: Trainer:in abgelehnt');
select lives_ok(format($$ select public.ea_activate_person(%L, %L, %L, '{"function": "Helfer:in"}', date '2026-10-24') $$,
  pg_temp.p(5), pg_temp.fn(), pg_temp.referat('Klettern')),
  'EZ: Anton Muster (ruhend, zuletzt im Referat Ausbildung) im Referat Klettern wieder aktiv');
select lives_ok(format($$ select public.ea_activate_person(%L, %L, %L, '{"function": "Helfer:in"}', date '2026-10-24') $$,
  pg_temp.p(4), pg_temp.fn(), pg_temp.referat('Klettern')), 'EZ: aktive Person, Funktion ergänzt');
select pg_temp.as_owner();
select results_eq(
  $$ select p.id, p.volunteer_status::text from public.ea_persons p where p.id in (
       'a0000000-0000-4000-8000-000000000004', 'a0000000-0000-4000-8000-000000000005',
       'a0000000-0000-4000-8000-000000000011', 'a0000000-0000-4000-8000-000000000012') order by p.id $$,
  $$ values (pg_temp.p(4), 'active'::text), (pg_temp.p(5), 'active'), (pg_temp.p(11), 'active'), (pg_temp.p(12), 'active') $$,
  'alle vier aktiv');
select is((select count(*)::int from public.ea_volunteer_status_history
            where person_id in (pg_temp.p(5), pg_temp.p(11), pg_temp.p(12)) and status = 'active' and valid_from = date '2026-10-24'),
  3, 'Historie für die drei Rückkehrer, nicht für die schon aktive Person');
select is((select count(*)::int from public.ea_properties e
            where e.person_id in (pg_temp.p(4), pg_temp.p(5), pg_temp.p(11), pg_temp.p(12))
              and e.property_type_id = pg_temp.fn() and e.field_values = '{"function": "Helfer:in"}'
              and e.related_referat_id = pg_temp.referat('Klettern') and e.valid_from = date '2026-10-24'),
  4, 'Funktion Helfer:in im Referat Klettern');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select throws_ok(format($$ select public.ea_activate_person(%L, %L, %L, '{"function": "Helfer:in"}', null) $$,
  pg_temp.p(11), pg_temp.fn(), pg_temp.referat('Klettern')), 'P0001', 'EA_CREATE_FORBIDDEN', 'Vorstand: abgelehnt');
select throws_ok($$ select * from public.ad_find_similar_persons('Tony', 'Muster', null) $$, 'P0001', 'AD_FORBIDDEN',
  'Vorstand: keine Dublettenprüfung');

select pg_temp.as_owner();
select * from finish();
rollback;
