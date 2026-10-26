-- US-AD-01 (spec T7 Teil): Personen, Rechtevorlagen, Zuweisungen, Rechte je Vorlage.
-- Seed-Testzugänge (supabase/seed.sql): b…01 Admin, b…02 Geschäftsstelle, b…03 Vorstand,
-- b…06 eingeladen, b…07 gesperrt, b…08 Notfall-Admin.
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

-- Startvorlagen (US-AD-01 AK1, R6)
select results_eq(
  $$ select t.name, r.module_code, r.level::text
     from public.ad_template_rights r join public.ad_templates t on t.id = r.template_id
     where r.level <> 'none' order by t.name, r.module_code $$,
  $$ values ('Admin'::text, 'AD'::text, 'manage'::text), ('Admin', 'DS', 'read'), ('Admin', 'EA', 'manage'), ('Admin', 'EZ', 'read'),
            ('Admin', 'GR', 'read'), ('Admin', 'SC', 'manage'),
            ('Budgetpflege', 'DS', 'read'),
            ('Geschäftsstelle', 'AM', 'manage'), ('Geschäftsstelle', 'DS', 'read'), ('Geschäftsstelle', 'EA', 'manage'), ('Geschäftsstelle', 'EZ', 'manage'),
            ('Geschäftsstelle', 'FI', 'manage'),
            ('Geschäftsstelle', 'GR', 'manage'), ('Geschäftsstelle', 'GS', 'manage'), ('Geschäftsstelle', 'OA', 'manage'),
            ('Geschäftsstelle', 'PM', 'manage'), ('Referent:in', 'DS', 'read'), ('Referent:in', 'EA', 'edit'), ('Referent:in', 'EZ', 'edit'),
            ('Referent:in', 'FI', 'read'), ('Vorstand', 'DS', 'read') $$,
  'Startvorlagen nach spec.md Abschnitt 3 (Kern v0.7, Nachträge v0.8 und v0.10) und spec.md DS (DS lesen, Vorlage Budgetpflege)'
);
select is((select count(*)::int from public.ad_template_rights r join public.ad_templates t on t.id = r.template_id
           where t.name = 'Vorstand'), 11, 'Vorstand hat je Modul eine Zeile');

-- ad_user_level je Testzugang
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select is(public.ad_user_level('AD'), 'manage'::public.ad_level, 'Admin: AD verwalten');
select is(public.ad_user_level('GR'), 'read'::public.ad_level, 'Admin: GR lesen (E5)');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select is(public.ad_user_level('AD'), 'none'::public.ad_level, 'Geschäftsstelle: AD kein Zugriff');
select is(public.ad_user_level('EA'), 'manage'::public.ad_level, 'Geschäftsstelle: EA verwalten');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000006');
select is(public.ad_user_level('EA'), 'none'::public.ad_level, 'eingeladen: keine Rechte (R5)');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000007');
select is(public.ad_user_level('EA'), 'none'::public.ad_level, 'gesperrt: keine Rechte (R5)');

-- R6: Summe der Vorlagen; entzogene und abgelaufene Zuweisungen wirken nicht
select pg_temp.as_owner();
insert into public.ad_template_assignments (person_id, template_id)
select 'a0000000-0000-4000-8000-000000000003', id from public.ad_templates where name = 'Geschäftsstelle';
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select is(public.ad_user_level('FI'), 'manage'::public.ad_level, 'Vorstand + Geschäftsstelle: höchste Stufe (R6)');
select pg_temp.as_owner();
update public.ad_template_assignments set revoked_at = now()
where person_id = 'a0000000-0000-4000-8000-000000000003'
  and template_id = (select id from public.ad_templates where name = 'Geschäftsstelle');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select is(public.ad_user_level('FI'), 'none'::public.ad_level, 'entzogene Zuweisung wirkt nicht');
select pg_temp.as_owner();
insert into public.ad_template_assignments (person_id, template_id, valid_to)
select 'a0000000-0000-4000-8000-000000000003', id, current_date - 1 from public.ad_templates where name = 'Geschäftsstelle';
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select is(public.ad_user_level('FI'), 'none'::public.ad_level, 'abgelaufene Zuweisung wirkt nicht');

-- US-AD-01 AK4 / US-AD-10 AK4: ohne AD-Rechte keine Änderung an Vorlagen
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
update public.ad_template_rights set level = 'none'
where template_id = (select id from public.ad_templates where name = 'Admin') and module_code = 'AD';
select throws_ok($$ insert into public.ad_templates (name) values ('Fremd') $$, '42501',
  null, 'Geschäftsstelle darf keine Vorlage anlegen');
select pg_temp.as_owner();
select is((select r.level from public.ad_template_rights r join public.ad_templates t on t.id = r.template_id
           where t.name = 'Admin' and r.module_code = 'AD'), 'manage'::public.ad_level,
  'Vorlage Admin unverändert nach Änderungsversuch ohne AD-Rechte');

-- Admin legt Vorlage an: Trigger legt 10 Zeilen an; Name eindeutig ohne Groß-/Kleinschreibung
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select lives_ok($$ insert into public.ad_templates (name, description) values ('Testvorlage', 'nur Test') $$,
  'Admin legt Vorlage an');
select is((select count(*)::int from public.ad_template_rights r join public.ad_templates t on t.id = r.template_id
           where t.name = 'Testvorlage' and r.level = 'none'), 11, 'neue Vorlage hat 11 Zeilen kein Zugriff (auch EZ und DS)');
select throws_ok($$ insert into public.ad_templates (name) values ('testvorlage') $$, '23505',
  null, 'Vorlagenname doppelt (ad_templates_name_key)');

-- Zuweisungen nur über Funktionen (US-AD-11)
select throws_ok(
  $$ insert into public.ad_template_assignments (person_id, template_id)
     select 'a0000000-0000-4000-8000-000000000004', id from public.ad_templates where name = 'Vorstand' $$,
  '42501', null, 'kein direkter Insert in ad_template_assignments');
select lives_ok(
  $$ select public.ad_assign_template('a0000000-0000-4000-8000-000000000004',
       (select id from public.ad_templates where name = 'Vorstand')) $$,
  'Admin weist Vorlage zu');
select lives_ok(
  $$ select public.ad_assign_template('a0000000-0000-4000-8000-000000000004',
       (select id from public.ad_templates where name = 'Vorstand')) $$,
  'erneutes Zuweisen ohne Fehler');
select is((select count(*)::int from public.ad_template_assignments
           where person_id = 'a0000000-0000-4000-8000-000000000004' and revoked_at is null), 1,
  'keine doppelte Zuweisung (US-AD-11 AK3)');
select is((select count(*)::int from public.ad_audit_log
           where subject_person_id = 'a0000000-0000-4000-8000-000000000004'
             and action = 'template_assigned' and details = 'Vorstand'
             and actor_user_id = 'b0000000-0000-4000-8000-000000000001'), 1,
  'Zuweisung protokolliert (R13)');
select lives_ok(
  $$ select public.ad_revoke_template('a0000000-0000-4000-8000-000000000004',
       (select id from public.ad_templates where name = 'Vorstand')) $$,
  'Admin entzieht Vorlage');
select is((select count(*)::int from public.ad_template_assignments
           where person_id = 'a0000000-0000-4000-8000-000000000004' and revoked_at is null), 0,
  'Zuweisung entzogen, nicht gelöscht');
select is((select count(*)::int from public.ad_audit_log
           where subject_person_id = 'a0000000-0000-4000-8000-000000000004' and action = 'template_revoked'), 1,
  'Entzug protokolliert (R13)');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select throws_ok(
  $$ select public.ad_assign_template('a0000000-0000-4000-8000-000000000004',
       (select id from public.ad_templates where name = 'Admin')) $$,
  'P0001', 'AD_FORBIDDEN', 'Geschäftsstelle darf nicht zuweisen (US-AD-11 AK5)');

-- Startseite (nur AD und EA geprüft; GR, EZ, FI haben eigene Tests)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select results_eq($$ select code from public.ad_my_modules() where code in ('AD', 'EA') $$, $$ values ('AD'::text), ('EA') $$,
  'Admin sieht AD und EA');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select is_empty($$ select code from public.ad_my_modules() where code in ('AD', 'EA') $$, 'Vorstand sieht AD und EA nicht');

-- Personen (US-AD-07 AK6, R15)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select is((select count(*)::int from public.ea_persons where kind = 'function'), 1, 'Admin sieht Funktionsperson');
select is_empty($$ select id from public.ea_v_persons where kind = 'function' $$,
  'ea_v_persons ohne Funktionsperson (R15)');
select throws_ok($$ insert into public.ea_persons (first_name, last_name) values ('  ', 'Leer') $$,
  'P0001', 'AD_NAME_REQUIRED', 'leerer Vorname (R4)');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select is((select count(*)::int from public.ea_persons where kind = 'function'), 0,
  'Geschäftsstelle (EA) sieht keine Funktionsperson');
select ok((select count(*) from public.ea_persons) > 0, 'Geschäftsstelle (EA) sieht Menschen');
select throws_ok($$ insert into public.ea_persons (first_name, last_name) values ('Erika', 'Neu') $$,
  '42501', null, 'EA verwalten legt Personen nur über ea_create_volunteer an (spec v0.7, Abschnitt 3)');
select is((select count(*)::int from public.ea_persons), 18,
  'Geschäftsstelle sieht Personen mit Ehrenamtsstatus (R32: 4, 5, 9, 10, 11, 19–22, 26, 28, 31, 32) und im Pfad GR (23–25, 29, 30)');
select throws_ok($$ insert into public.ea_persons (first_name, last_name, kind) values ('Funktion', 'Test', 'function') $$,
  '42501', null, 'Funktionsperson nur durch AD');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select is_empty($$ select id from public.ea_persons $$, 'Vorstand sieht keine Personen');
select throws_ok($$ insert into public.ea_persons (first_name, last_name) values ('Kein', 'Recht') $$,
  '42501', null, 'Vorstand darf keine Personen anlegen');

-- Protokoll für Nutzer unveränderbar (US-AD-14 AK4)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select throws_ok($$ insert into public.ad_audit_log (subject_person_id, action) values ('a0000000-0000-4000-8000-000000000001', 'invited') $$,
  '42501', null, 'kein Insert ins Protokoll');
select throws_ok($$ update public.ad_audit_log set details = 'x' $$, '42501', null, 'kein Update im Protokoll');
select throws_ok($$ delete from public.ad_audit_log $$, '42501', null, 'kein Delete im Protokoll');

select pg_temp.as_owner();
select * from finish();
rollback;
