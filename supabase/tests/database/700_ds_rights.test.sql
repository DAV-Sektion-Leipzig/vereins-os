-- Dashboard (spec.md DS v0.2, T1–T3; uebergabe-administration.md D1–D4, D6, D10): Modul DS, Startwerte,
-- Reichweite „Referat“ für DS, Kennzeichen „darf Budget pflegen“, ad_has_budget_maintain(), Vorlage „Budgetpflege“,
-- neue Referate. Seed: b…01 Admin, b…02 Geschäftsstelle, b…03 Vorstand, b…09 Rita Referentin (Klettern),
-- b…32 Kim Kinderjugend (Referent:in Kinder und Jugend).
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
create function pg_temp.template(p_name text) returns uuid language sql as $$
  select id from public.ad_templates where name = p_name
$$;
create function pg_temp.referat(p_name text) returns uuid language sql as $$
  select id from public.ea_referate where name = p_name
$$;

-- Modul (D1, plan.md P1)
select results_eq($$ select name, sort_order, is_available from public.ad_modules where code = 'DS' $$,
  $$ values ('Dashboard'::text, 1, false) $$, 'Modul DS „Dashboard“ an erster Stelle, noch nicht verfügbar');
select is((select count(*)::int from public.ad_templates t
            where not exists (select 1 from public.ad_template_rights r
                               where r.template_id = t.id and r.module_code = 'DS')),
  0, 'jede Vorlage hat eine Zeile DS');

-- Struktur und Grants
select has_column('public', 'ad_template_rights', 'can_maintain_budget', 'Spalte can_maintain_budget');
select col_default_is('public', 'ad_template_rights', 'can_maintain_budget', 'false', 'standardmäßig keine Budgetpflege');
select ok(has_column_privilege('authenticated', 'public.ad_template_rights', 'can_maintain_budget', 'UPDATE'),
  'authenticated darf can_maintain_budget ändern (RLS: nur AD ≥ bearbeiten)');
select ok(has_function_privilege('authenticated', 'public.ad_has_budget_maintain()', 'EXECUTE'), 'ad_has_budget_maintain');
select ok(not has_function_privilege('anon', 'public.ad_has_budget_maintain()', 'EXECUTE'), 'anon: keine Budgetpflege');

-- Startwerte (D3, D6)
select results_eq(
  $$ select t.name, r.level::text, r.scope::text, r.can_maintain_budget
       from public.ad_template_rights r join public.ad_templates t on t.id = r.template_id
      where r.module_code = 'DS' order by t.name $$,
  $$ values ('Admin'::text, 'read'::text, 'all'::text, false), ('Budgetpflege', 'read', 'all', true),
            ('Geschäftsstelle', 'read', 'all', false), ('Referent:in', 'read', 'referat', false),
            ('Vorstand', 'read', 'all', false) $$,
  'Startwerte DS: Admin, Geschäftsstelle, Vorstand lesen (alle); Referent:in lesen (Referat); Budgetpflege mit Kennzeichen');
select is((select count(*)::int from public.ad_template_rights r
            where r.template_id = pg_temp.template('Budgetpflege') and r.level <> 'none'),
  1, 'Vorlage Budgetpflege: nur DS');

-- Neue Referate (D10)
select results_eq(
  $$ select name, sort_order, semiannual_settlement, is_active from public.ea_referate
      where name in ('Öffentlichkeitsarbeit', 'Umwelt und Naturschutz') order by sort_order $$,
  $$ values ('Öffentlichkeitsarbeit'::text, 8, false, true), ('Umwelt und Naturschutz', 9, false, true) $$,
  'Referate Öffentlichkeitsarbeit und Umwelt und Naturschutz');

-- Reichweiten (D2, D4)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000032');
select ok(public.ad_has_any_level('DS', 'read'), 'Kim: DS lesen (Reichweite Referat)');
select ok(not public.ad_has_level('DS', 'read'), 'Kim: kein DS mit Reichweite alle');
select is(public.ad_my_referate('DS', 'read'), array[pg_temp.referat('Kinder und Jugend')], 'Kim: DS für Kinder und Jugend');
select ok(not public.ad_has_budget_maintain(), 'Kim: keine Budgetpflege');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select is(public.ad_my_referate('DS', 'read'), array[pg_temp.referat('Klettern')], 'Rita Referentin: DS für Klettern');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select ok(public.ad_has_level('DS', 'read'), 'Vorstand: DS lesen (alle)');
select ok(not public.ad_has_budget_maintain(), 'Vorstand: ohne Vorlage Budgetpflege keine Budgetpflege');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select ok(public.ad_has_level('DS', 'read'), 'Admin: DS lesen (alle, D5)');
select ok(not public.ad_has_budget_maintain(), 'Admin: keine Budgetpflege ohne Vorlage');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select ok(public.ad_has_level('DS', 'read'), 'Geschäftsstelle: DS lesen (alle)');
select ok(not public.ad_has_budget_maintain(), 'Geschäftsstelle: keine Budgetpflege (Q-DS7)');

-- Budgetpflege über die Vorlage (D6): Vorstand erhält „Budgetpflege“
select pg_temp.as_owner();
insert into public.ad_template_assignments (person_id, template_id)
values ('a0000000-0000-4000-8000-000000000003', pg_temp.template('Budgetpflege'));
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select ok(public.ad_has_budget_maintain(), 'Vorstand + Vorlage Budgetpflege: Budgetpflege');

select pg_temp.as_owner();
update public.ad_template_assignments set revoked_at = now()
 where person_id = 'a0000000-0000-4000-8000-000000000003' and template_id = pg_temp.template('Budgetpflege');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select ok(not public.ad_has_budget_maintain(), 'entzogene Zuweisung: keine Budgetpflege');

select pg_temp.as_owner();
insert into public.ad_template_assignments (person_id, template_id, valid_to)
values ('a0000000-0000-4000-8000-000000000003', pg_temp.template('Budgetpflege'), current_date - 1);
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select ok(not public.ad_has_budget_maintain(), 'abgelaufene Zuweisung: keine Budgetpflege');

-- Kennzeichen nur DS, Stufe ≠ none, Reichweite alle (P2)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select throws_ok(
  $$ update public.ad_template_rights set level = 'read', can_maintain_budget = true
      where template_id = pg_temp.template('Vorstand') and module_code = 'FI' $$,
  'P0001', 'AD_BUDGET_MAINTAIN_NOT_ALLOWED', 'Budgetpflege in FI abgelehnt');
select throws_ok(
  $$ update public.ad_template_rights set scope = 'referat', can_maintain_budget = true
      where template_id = pg_temp.template('Referent:in') and module_code = 'DS' $$,
  'P0001', 'AD_BUDGET_MAINTAIN_NOT_ALLOWED', 'Budgetpflege mit Reichweite Referat abgelehnt');
select throws_ok(
  $$ update public.ad_template_rights set level = 'none'
      where template_id = pg_temp.template('Budgetpflege') and module_code = 'DS' $$,
  'P0001', 'AD_BUDGET_MAINTAIN_NOT_ALLOWED', 'Stufe „kein Zugriff“ bei gesetzter Budgetpflege abgelehnt');
select throws_ok(
  $$ update public.ad_template_rights set scope = 'referat'
      where template_id = pg_temp.template('Budgetpflege') and module_code = 'DS' $$,
  'P0001', 'AD_BUDGET_MAINTAIN_NOT_ALLOWED', 'Reichweite Referat bei gesetzter Budgetpflege abgelehnt');
select lives_ok(
  $$ update public.ad_template_rights set can_maintain_budget = true
      where template_id = pg_temp.template('Vorstand') and module_code = 'DS' $$,
  'Admin: Vorstand DS lesen + Budgetpflege');
select lives_ok(
  $$ update public.ad_template_rights set scope = 'referat', level = 'read'
      where template_id = pg_temp.template('Geschäftsstelle') and module_code = 'DS' $$,
  'Reichweite „Referat“ für DS erlaubt (R30)');
select throws_ok(
  $$ update public.ad_template_rights set scope = 'referat'
      where template_id = pg_temp.template('Vorstand') and module_code = 'GS' $$,
  'P0001', 'AD_SCOPE_NOT_ALLOWED', 'Reichweite „Referat“ für GS weiterhin abgelehnt');

-- Nur der Admin ändert Rechte (RLS)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
update public.ad_template_rights set can_maintain_budget = true
 where template_id = pg_temp.template('Admin') and module_code = 'DS';
select pg_temp.as_owner();
select is(
  (select r.can_maintain_budget from public.ad_template_rights r
    where r.template_id = pg_temp.template('Admin') and r.module_code = 'DS'),
  false, 'Geschäftsstelle kann keine Budgetpflege vergeben');

-- Check sichert ab, auch ohne Trigger
alter table public.ad_template_rights disable trigger ad_template_rights_guard;
select throws_ok(
  $$ update public.ad_template_rights set level = 'read', can_maintain_budget = true
      where template_id = pg_temp.template('Vorstand') and module_code = 'OA' $$,
  '23514', null, 'Check ad_template_rights_budget_allowed');
alter table public.ad_template_rights enable trigger ad_template_rights_guard;

-- Kein doppeltes Modul
select is(
  (select count(*)::int from public.ad_modules where code = 'DS'), 1, 'Modul DS genau einmal');

select * from finish();
rollback;
