-- US-AD-20, US-AD-21 (spec T7 Teil, T33): Reichweite „Referat“ (R30, nur EA im Kern), Referate je Zuweisung (R31),
-- ad_my_referate, ad_has_any_level, ad_user_level nur Reichweite „alle“, ad_my_modules.
-- Seed: b…09 Rita Referentin, Vorlage Referent:in mit Referat Klettern.
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
create function pg_temp.template(p_name text) returns uuid language sql as $$
  select id from public.ad_templates where name = p_name
$$;

-- Rita Referentin (Seed): Reichweite „Referat“ zählt nicht für ad_user_level (R30)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select is(public.ad_user_level('EA'), 'none'::public.ad_level, 'Referent:in: ad_user_level(EA) = none (nur Reichweite alle)');
select is(public.ad_my_referate('EA', 'edit'), array[pg_temp.referat('Klettern')], 'ad_my_referate(EA, edit) = {Klettern}');
select is(public.ad_my_referate('EA', 'manage'), '{}'::uuid[], 'ad_my_referate(EA, manage) leer');
select ok(public.ad_has_any_level('EA', 'read'), 'ad_has_any_level(EA, read)');
select ok(not public.ad_has_any_level('AD', 'read'), 'kein Recht auf AD');
select is_empty($$ select code from public.ad_my_modules() $$, 'keine Kachel, solange EA nicht verfügbar ist');

select pg_temp.as_owner();
update public.ad_modules set is_available = true where code = 'EA';
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select results_eq($$ select code, level::text from public.ad_my_modules() $$,
  $$ values ('EA'::text, 'edit'::text) $$, 'Kachel EA mit Stufe bearbeiten über Reichweite Referat');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select results_eq($$ select code, level::text from public.ad_my_modules() $$,
  $$ values ('EA'::text, 'manage'::text) $$, 'Geschäftsstelle: Kachel EA verwalten');
select pg_temp.as_owner();
update public.ad_modules set is_available = false where code = 'EA';

-- Typ und R30
select col_type_is('public', 'ad_template_rights', 'scope', 'ad_scope', 'scope ist ad_scope');
select col_default_is('public', 'ad_template_rights', 'scope', 'all', 'Reichweite standardmäßig „alle“');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select lives_ok(
  $$ update public.ad_template_rights set scope = 'referat', level = 'read'
      where template_id = pg_temp.template('Vorstand') and module_code = 'EA' $$,
  'Reichweite „Referat“ für EA erlaubt');
select throws_ok(
  $$ update public.ad_template_rights set scope = 'referat'
      where template_id = pg_temp.template('Vorstand') and module_code = 'GR' $$,
  'P0001', 'AD_SCOPE_NOT_ALLOWED', 'Reichweite „Referat“ für GR abgelehnt (R30)');
select pg_temp.as_owner();
alter table public.ad_template_rights disable trigger ad_template_rights_guard;
select throws_ok(
  $$ update public.ad_template_rights set scope = 'referat'
      where template_id = (select id from public.ad_templates where name = 'Vorstand') and module_code = 'FI' $$,
  '23514', null, 'Check ad_template_rights_scope_allowed sichert ab');
alter table public.ad_template_rights enable trigger ad_template_rights_guard;

-- Referate je Zuweisung (R31)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select throws_ok(
  $$ select public.ad_assign_template('a0000000-0000-4000-8000-000000000010', pg_temp.template('Referent:in')) $$,
  'P0001', 'AD_REFERAT_REQUIRED', 'Referent:in ohne Referat abgelehnt (R31)');
select throws_ok(
  $$ select public.ad_assign_template('a0000000-0000-4000-8000-000000000010', pg_temp.template('Referent:in'), '{}') $$,
  'P0001', 'AD_REFERAT_REQUIRED', 'Referent:in mit leerer Liste abgelehnt');
select pg_temp.as_owner();
update public.ea_referate set is_active = false where name = 'Sulzenauhütte';
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select throws_ok(
  $$ select public.ad_assign_template('a0000000-0000-4000-8000-000000000010', pg_temp.template('Referent:in'),
       array[pg_temp.referat('Sulzenauhütte')]) $$,
  'P0001', 'AD_REFERAT_REQUIRED', 'inaktives Referat nicht wählbar');
select lives_ok(
  $$ select public.ad_assign_template('a0000000-0000-4000-8000-000000000010', pg_temp.template('Referent:in'),
       array[pg_temp.referat('Ausbildung'), pg_temp.referat('Klettern')]) $$,
  'Referent:in mit zwei Referaten zugewiesen');
select results_eq(
  $$ select r.name from public.ad_assignment_referate ar
       join public.ad_template_assignments ta on ta.id = ar.assignment_id
       join public.ea_referate r on r.id = ar.referat_id
      where ta.person_id = 'a0000000-0000-4000-8000-000000000010' and ta.revoked_at is null
      order by r.sort_order $$,
  $$ values ('Ausbildung'::text), ('Klettern') $$,
  'Referate der Zuweisung gespeichert');
select is(
  (select details from public.ad_audit_log
    where subject_person_id = 'a0000000-0000-4000-8000-000000000010' and action = 'template_assigned'),
  'Referent:in (Referate: Ausbildung, Klettern)', 'Protokoll nennt Vorlage und Referate (R13)');

-- Vorlage ohne Reichweite „Referat“: Referate werden nicht gespeichert
select lives_ok(
  $$ select public.ad_assign_template('a0000000-0000-4000-8000-000000000010', pg_temp.template('Geschäftsstelle'),
       array[pg_temp.referat('Touren')]) $$,
  'Geschäftsstelle mit Referat zugewiesen');
select is_empty(
  $$ select 1 from public.ad_assignment_referate ar
       join public.ad_template_assignments ta on ta.id = ar.assignment_id
      where ta.person_id = 'a0000000-0000-4000-8000-000000000010'
        and ta.template_id = pg_temp.template('Geschäftsstelle') $$,
  'keine Referate bei Vorlage ohne Reichweite „Referat“ (R31)');

-- Referate ändern (US-AD-21 AK3)
select lives_ok(
  $$ select public.ad_set_assignment_referate(
       (select id from public.ad_template_assignments
         where person_id = 'a0000000-0000-4000-8000-000000000009' and revoked_at is null),
       array[pg_temp.referat('Touren')]) $$,
  'Referat Klettern → Touren');
select is(
  (select details from public.ad_audit_log
    where subject_person_id = 'a0000000-0000-4000-8000-000000000009' and action = 'referate_changed'),
  'Referent:in: Klettern → Touren', 'Protokoll „Referate geändert“ mit vorher und nachher');
select throws_ok(
  $$ select public.ad_set_assignment_referate(
       (select id from public.ad_template_assignments
         where person_id = 'a0000000-0000-4000-8000-000000000009' and revoked_at is null), '{}') $$,
  'P0001', 'AD_REFERAT_REQUIRED', 'Referate ändern ohne Referat abgelehnt');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select is(public.ad_my_referate('EA', 'edit'), array[pg_temp.referat('Touren')],
  'Datenzugriff gilt sofort für Touren statt Klettern (US-AD-21 AK3)');

-- ohne AD ≥ edit
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select throws_ok(
  $$ select public.ad_assign_template('a0000000-0000-4000-8000-000000000011', pg_temp.template('Referent:in'),
       array[pg_temp.referat('Klettern')]) $$,
  'P0001', 'AD_FORBIDDEN', 'Geschäftsstelle darf nicht zuweisen');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select throws_ok(
  $$ select public.ad_set_assignment_referate(gen_random_uuid(), array[pg_temp.referat('Klettern')]) $$,
  'P0001', 'AD_FORBIDDEN', 'Vorstand darf Referate nicht ändern');
select is_empty($$ select 1 from public.ad_assignment_referate $$, 'Vorstand liest keine Referate der Zuweisungen');

-- R5: ohne aktiven Zugang keine Referate
select pg_temp.as_owner();
update public.ad_accesses set status = 'locked' where person_id = 'a0000000-0000-4000-8000-000000000009';
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select is(public.ad_my_referate('EA', 'read'), '{}'::uuid[], 'gesperrt: keine Referate (R5)');

select pg_temp.as_owner();
select * from finish();
rollback;
