-- US-AD-23 (spec T7 Teil, T39): Ehrenamtsstatus setzen (R33), Referate einer Person, Person anlegen und übernehmen.
-- Fehlercodes beim Anlegen nach EA-Migration 20261024000600 (plan.md EA O3): EA_CREATE_FORBIDDEN, EA_CREATE_REFERAT_REQUIRED.
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

-- Kern-Signatur ohne Erweiterung für die Anwesenheitserfassung
select has_function('public', 'ea_create_volunteer', array['text', 'text', 'text', 'uuid', 'uuid', 'jsonb', 'date'],
  'ea_create_volunteer mit sieben Parametern');
select hasnt_function('public', 'ea_create_volunteer',
  array['text', 'text', 'text', 'uuid', 'uuid', 'jsonb', 'date', 'text'], 'kein p_contact_email (Nachtrag v0.8)');

-- Status setzen (R33)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select lives_ok($$ select public.ea_set_volunteer_status('a0000000-0000-4000-8000-000000000005', 'active', '2026-10-01') $$,
  'Geschäftsstelle setzt Person 5 auf aktiv');
select pg_temp.as_owner();
select results_eq(
  $$ select volunteer_status::text, volunteer_status_since from public.ea_persons where id = 'a0000000-0000-4000-8000-000000000005' $$,
  $$ values ('active'::text, date '2026-10-01') $$, 'Status und „seit“ gesetzt');
select results_eq(
  $$ select status::text, valid_from, set_by from public.ea_volunteer_status_history
      where person_id = 'a0000000-0000-4000-8000-000000000005' order by id desc limit 1 $$,
  $$ values ('active'::text, date '2026-10-01', 'b0000000-0000-4000-8000-000000000002'::uuid) $$,
  'Historie mit wer und gültig ab');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select lives_ok($$ select public.ea_set_volunteer_status('a0000000-0000-4000-8000-000000000004', 'dormant') $$,
  'Referent:in setzt Person ihres Referats auf ruhend');
select throws_ok($$ select public.ea_set_volunteer_status('a0000000-0000-4000-8000-000000000002', 'active') $$,
  'P0001', 'EA_STATUS_FORBIDDEN', 'Person ohne Ehrenamtsstatus nicht über diese Funktion');
select pg_temp.as_owner();
select set_config('ea.status_change', 'on', true);
update public.ea_persons set volunteer_status = 'dormant', volunteer_status_since = current_date
 where id = 'a0000000-0000-4000-8000-000000000005';
select set_config('ea.status_change', '', true);
update public.ea_properties set valid_to = current_date - 1 where person_id = 'a0000000-0000-4000-8000-000000000005';
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select throws_ok($$ select public.ea_set_volunteer_status('a0000000-0000-4000-8000-000000000005', 'left') $$,
  'P0001', 'EA_STATUS_FORBIDDEN', 'Referent:in Klettern ändert Person 5 (Ausbildung) nicht');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select throws_ok($$ select public.ea_set_volunteer_status('a0000000-0000-4000-8000-000000000004', 'left') $$,
  'P0001', 'EA_STATUS_FORBIDDEN', 'Vorstand ändert keinen Status');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select lives_ok($$ select public.ea_set_volunteer_status('a0000000-0000-4000-8000-000000000011', 'active') $$,
  'Rückkehr aus „ausgeschieden“ mit EA bearbeiten (Reichweite alle)');

-- Referate einer Person
select results_eq($$ select name from public.ea_person_referate('a0000000-0000-4000-8000-000000000010') $$,
  $$ values ('Ausbildung'::text), ('Klettern') $$, 'Referate von Person 10');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select is_empty($$ select 1 from public.ea_person_referate('a0000000-0000-4000-8000-000000000010') $$,
  'ohne Pfad EA keine Referate');

-- Person anlegen (R41)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select lives_ok(format($$ select public.ea_create_volunteer('Neu', 'Klettrerin', 'Nele',
                   (select id from public.ea_property_types where system_key = 'function'), %L, '{"function": "Helfer:in"}', '2026-10-01') $$,
                   pg_temp.referat('Klettern')),
  'Referent:in legt Person mit Funktion im eigenen Referat an');
select pg_temp.as_owner();
select results_eq(
  $$ select p.created_in, p.volunteer_status::text, p.preferred_name, pr.field_values ->> 'function', r.name
       from public.ea_persons p
       join public.ea_properties pr on pr.person_id = p.id
       join public.ea_referate r on r.id = pr.related_referat_id
      where p.last_name = 'Klettrerin' $$,
  $$ values ('EA'::text, 'active'::text, 'Nele'::text, 'Helfer:in'::text, 'Klettern'::text) $$,
  'Person mit created_in EA, Status aktiv und erster Zuordnung');
select is((select count(*)::int from public.ea_volunteer_status_history h join public.ea_persons p on p.id = h.person_id
            where p.last_name = 'Klettrerin'), 1, 'Status mit Historie');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select ok(exists (select 1 from public.ea_persons where last_name = 'Klettrerin'), 'angelegte Person sofort sichtbar');
select throws_ok(format($$ select public.ea_create_volunteer('Fremd', 'Person', null,
                    (select id from public.ea_property_types where system_key = 'function'), %L, '{"function": "Helfer:in"}', null) $$,
                    pg_temp.referat('Ausbildung')),
  'P0001', 'EA_RELATION_FOREIGN_REFERAT', 'fremdes Referat abgelehnt (R41)');
select throws_ok($$ select public.ea_create_volunteer('Ohne', 'Bezug', null, null, null, null, null) $$,
  'P0001', 'EA_CREATE_REFERAT_REQUIRED', 'Referent:in nur mit erster Zuordnung (R3 EA, plan.md EA O3)');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select lives_ok($$ select public.ea_create_volunteer('Gremium', 'Mitglied', null, null, null, null, null) $$,
  'Geschäftsstelle ohne Art und Referat');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select throws_ok($$ select public.ea_create_volunteer('Kein', 'Recht', null, null, null, null, null) $$,
  'P0001', 'EA_CREATE_FORBIDDEN', 'Vorstand legt nicht an (US-EA-05 AK6, plan.md EA O3)');

-- Übernahme bzw. Rückkehr (E1)
select pg_temp.as_owner();
select set_config('ea.status_change', 'on', true);
update public.ea_persons set volunteer_status = 'left', volunteer_status_since = '2025-06-30'
 where id = 'a0000000-0000-4000-8000-000000000011';
select set_config('ea.status_change', '', true);
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select lives_ok(format($$ select public.ea_activate_person('a0000000-0000-4000-8000-000000000011',
                   (select id from public.ea_property_types where system_key = 'function'), %L, '{"function": "Trainer:in"}', current_date) $$,
                   pg_temp.referat('Klettern')),
  'Referent:in übernimmt Ausgeschiedene mit Zuordnung zum eigenen Referat');
select ok(exists (select 1 from public.ea_persons where id = 'a0000000-0000-4000-8000-000000000011'
                   and volunteer_status = 'active'), 'wieder aktiv und sichtbar, keine neue Person');
select lives_ok(format($$ select public.ea_activate_person('a0000000-0000-4000-8000-000000000012',
                   (select id from public.ea_property_types where system_key = 'function'), %L, '{"function": "Helfer:in"}', current_date) $$,
                   pg_temp.referat('Klettern')),
  'Referent:in übernimmt Person aus Gruppen (v0.7.1)');
select ok(exists (select 1 from public.ea_persons where id = 'a0000000-0000-4000-8000-000000000012'), 'Person 12 jetzt sichtbar');
select throws_ok($$ select public.ea_activate_person('a0000000-0000-4000-8000-000000000011', null, null, null, current_date) $$,
  'P0001', 'EA_CREATE_REFERAT_REQUIRED', 'Referent:in aktiviert nicht ohne Funktion oder Amt (US-EA-10 AK5)');
select throws_ok(format($$ select public.ea_activate_person('a0000000-0000-4000-8000-000000000011',
                    (select id from public.ea_property_types where system_key = 'license'), %L,
                    '{"qualification_type": "x"}', current_date) $$, pg_temp.referat('Klettern')),
  'P0001', 'EA_CREATE_REFERAT_REQUIRED', 'erste Zuordnung muss Funktion oder Amt sein (R3 EA)');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select throws_ok($$ select public.ea_activate_person('a0000000-0000-4000-8000-000000000011', null, null, null, current_date) $$,
  'P0001', 'EA_CREATE_FORBIDDEN', 'Vorstand übernimmt nicht');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select throws_ok(format($$ select public.ea_activate_person('a0000000-0000-4000-8000-000000000008',
                    (select id from public.ea_property_types where system_key = 'function'), %L, '{"function": "Helfer:in"}', current_date) $$,
                    pg_temp.referat('Klettern')),
  'P0001', 'AD_BAD_REQUEST', 'Funktionsperson nicht übernehmbar');

select pg_temp.as_owner();
select * from finish();
rollback;
