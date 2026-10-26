-- Nachtrag v0.10 (spec T68, T71, T75 Teil; R30, R50): Aktion „freigeben“ (can_approve), Reichweite „Referat“ für FI,
-- Startwert Referent:in FI lesen + freigeben; ad_my_approve_referate, ad_has_approve, ad_can_approve.
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

-- Struktur und Grants
select has_column('public', 'ad_template_rights', 'can_approve', 'Spalte can_approve');
select col_default_is('public', 'ad_template_rights', 'can_approve', 'false', 'standardmäßig nicht freigeben');
select ok(has_column_privilege('authenticated', 'public.ad_template_rights', 'can_approve', 'UPDATE'),
  'authenticated darf can_approve ändern (RLS: nur AD ≥ bearbeiten)');
select ok(has_function_privilege('authenticated', 'public.ad_my_approve_referate(text)', 'EXECUTE'), 'ad_my_approve_referate');
select ok(has_function_privilege('authenticated', 'public.ad_has_approve(text)', 'EXECUTE'), 'ad_has_approve');
select ok(has_function_privilege('authenticated', 'public.ad_can_approve(text, uuid)', 'EXECUTE'), 'ad_can_approve');
select ok(not has_function_privilege('anon', 'public.ad_can_approve(text, uuid)', 'EXECUTE'), 'anon: kein Freigaberecht');

-- Startwerte (T71)
select results_eq(
  $$ select t.name, r.module_code, r.level::text, r.scope::text
       from public.ad_template_rights r join public.ad_templates t on t.id = r.template_id
      where r.can_approve order by t.name, r.module_code $$,
  $$ values ('Referent:in'::text, 'FI'::text, 'read'::text, 'referat'::text) $$,
  'nur Referent:in darf freigeben: FI lesen, Reichweite Referat');

-- Erwartete Ergebnisse v0.10 (spec.md Abschnitt 9)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000032');
select is(public.ad_my_approve_referate('FI'), array[pg_temp.referat('Kinder und Jugend')],
  'Kim Kinderjugend: freigeben in FI für Kinder und Jugend');
select ok(public.ad_can_approve('FI', pg_temp.referat('Kinder und Jugend')), 'Kim: ad_can_approve(FI, K&J)');
select ok(not public.ad_can_approve('FI', pg_temp.referat('Leistungssport')), 'Kim: nicht für Leistungssport');
select ok(not public.ad_has_approve('FI'), 'Kim: kein Freigaberecht mit Reichweite alle');
select ok(not public.ad_can_approve('FI', null), 'ohne Referat kein Freigaberecht');
select ok(public.ad_has_any_level('FI', 'read'), 'Kim: FI lesen (Reichweite Referat)');
select is(public.ad_user_level('FI'), 'none'::public.ad_level, 'Kim: keine FI-Rechte mit Reichweite alle');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select is(public.ad_my_approve_referate('FI'), array[pg_temp.referat('Klettern')], 'Rita Referentin: Klettern');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select is(public.ad_my_approve_referate('FI'), '{}'::uuid[], 'Geschäftsstelle: keine Referate');
select ok(not public.ad_has_approve('FI'), 'Geschäftsstelle: kein Freigaberecht (bestätigt nur in Vertretung)');
select ok(not public.ad_can_approve('FI', pg_temp.referat('Kinder und Jugend')), 'Geschäftsstelle: ad_can_approve falsch');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select ok(not public.ad_can_approve('FI', pg_temp.referat('Kinder und Jugend')), 'Vorstand: kein Freigaberecht');

-- R50: nur FI und TK, nur mit Stufe ≠ none
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select throws_ok(
  $$ update public.ad_template_rights set level = 'read', can_approve = true
      where template_id = pg_temp.template('Vorstand') and module_code = 'EA' $$,
  'P0001', 'AD_APPROVE_NOT_ALLOWED', 'freigeben in EA abgelehnt (R50)');
select throws_ok(
  $$ update public.ad_template_rights set can_approve = true
      where template_id = pg_temp.template('Vorstand') and module_code = 'FI' $$,
  'P0001', 'AD_APPROVE_NOT_ALLOWED', 'freigeben ohne Stufe abgelehnt (R50)');
select throws_ok(
  $$ update public.ad_template_rights set level = 'none'
      where template_id = pg_temp.template('Referent:in') and module_code = 'FI' $$,
  'P0001', 'AD_APPROVE_NOT_ALLOWED', 'Stufe „kein Zugriff“ bei gesetztem freigeben abgelehnt');
select lives_ok(
  $$ update public.ad_template_rights set level = 'read', can_approve = true
      where template_id = pg_temp.template('Vorstand') and module_code = 'FI' $$,
  'Admin: Vorstand FI lesen + freigeben (Reichweite alle)');
select lives_ok(
  $$ update public.ad_template_rights set scope = 'referat', level = 'read'
      where template_id = pg_temp.template('Vorstand') and module_code = 'EZ' $$,
  'Reichweite „Referat“ für EZ weiterhin erlaubt');
select throws_ok(
  $$ update public.ad_template_rights set scope = 'referat'
      where template_id = pg_temp.template('Vorstand') and module_code = 'OA' $$,
  'P0001', 'AD_SCOPE_NOT_ALLOWED', 'Reichweite „Referat“ für OA abgelehnt (R30)');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select ok(public.ad_has_approve('FI'), 'Vorstand: nach Änderung freigeben mit Reichweite alle');
select ok(public.ad_can_approve('FI', pg_temp.referat('Leistungssport')), 'Reichweite alle gilt für jedes Referat');

-- Nur der Admin ändert Rechte (RLS)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
update public.ad_template_rights set can_approve = true
 where template_id = pg_temp.template('Geschäftsstelle') and module_code = 'FI';
select pg_temp.as_owner();
select is(
  (select r.can_approve from public.ad_template_rights r
    where r.template_id = pg_temp.template('Geschäftsstelle') and r.module_code = 'FI'),
  false, 'Geschäftsstelle kann sich kein Freigaberecht geben');

-- Check sichert ab, auch ohne Trigger
alter table public.ad_template_rights disable trigger ad_template_rights_guard;
select throws_ok(
  $$ update public.ad_template_rights set level = 'read', can_approve = true
      where template_id = pg_temp.template('Vorstand') and module_code = 'GS' $$,
  '23514', null, 'Check ad_template_rights_approve_allowed');
alter table public.ad_template_rights enable trigger ad_template_rights_guard;

select * from finish();
rollback;
