-- US-AD-01 (spec T6 Teil): Policies und Grants je Tabelle gegen spec.md Abschnitt 3.
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

-- Policies (Name und Befehl) je Tabelle
select results_eq(
  $$ select tablename::text collate "default", policyname::text collate "default", cmd::text collate "default"
     from pg_policies
     where schemaname = 'public'
       and tablename in ('ad_modules', 'ea_persons', 'ad_templates', 'ad_template_rights',
                         'ad_template_assignments', 'ad_accesses', 'ad_audit_log', 'ad_test_login_domains')
     order by tablename, policyname $$,
  $$ values
     ('ad_accesses'::text, 'ad_accesses_insert'::text, 'INSERT'::text),
     ('ad_accesses', 'ad_accesses_select', 'SELECT'),
     ('ad_accesses', 'ad_accesses_update', 'UPDATE'),
     ('ad_audit_log', 'ad_audit_log_select', 'SELECT'),
     ('ad_modules', 'ad_modules_select', 'SELECT'),
     ('ad_template_assignments', 'ad_template_assignments_select', 'SELECT'),
     ('ad_template_rights', 'ad_template_rights_select', 'SELECT'),
     ('ad_template_rights', 'ad_template_rights_update', 'UPDATE'),
     ('ad_templates', 'ad_templates_insert', 'INSERT'),
     ('ad_templates', 'ad_templates_select', 'SELECT'),
     ('ad_templates', 'ad_templates_update', 'UPDATE'),
     ('ea_persons', 'ea_persons_insert', 'INSERT'),
     ('ea_persons', 'ea_persons_select', 'SELECT'),
     ('ea_persons', 'ea_persons_update', 'UPDATE') $$,
  'Policies nach spec.md Abschnitt 3; ad_test_login_domains ohne Policy'
);
select is_empty(
  $$ select policyname from pg_policies where schemaname = 'public' and 'anon' = any(roles) $$,
  'keine Policy für anon'
);

-- Tabellenrechte für authenticated
select ok(has_table_privilege('authenticated', 'public.ad_modules', 'SELECT'), 'ad_modules: lesen');
select ok(not has_table_privilege('authenticated', 'public.ad_modules', 'INSERT, UPDATE, DELETE'), 'ad_modules: nicht schreiben');

select ok(has_table_privilege('authenticated', 'public.ea_persons', 'SELECT'), 'ea_persons: lesen');
select ok(not has_table_privilege('authenticated', 'public.ea_persons', 'DELETE'), 'ea_persons: nicht löschen');
select ok(has_column_privilege('authenticated', 'public.ea_persons', 'first_name', 'INSERT, UPDATE'), 'ea_persons.first_name: schreiben');
select ok(has_column_privilege('authenticated', 'public.ea_persons', 'kind', 'INSERT, UPDATE'), 'ea_persons.kind: schreiben (RLS begrenzt)');
select ok(not has_column_privilege('authenticated', 'public.ea_persons', 'created_by', 'INSERT'), 'ea_persons.created_by: nur Default');
select ok(not has_column_privilege('authenticated', 'public.ea_persons', 'id', 'UPDATE'), 'ea_persons.id: nicht ändern');

select ok(has_table_privilege('authenticated', 'public.ad_templates', 'SELECT'), 'ad_templates: lesen');
select ok(not has_table_privilege('authenticated', 'public.ad_templates', 'DELETE'), 'ad_templates: nicht löschen');
select ok(has_column_privilege('authenticated', 'public.ad_templates', 'name', 'INSERT, UPDATE'), 'ad_templates.name: schreiben');
select ok(not has_column_privilege('authenticated', 'public.ad_templates', 'created_by', 'INSERT'), 'ad_templates.created_by: nur Default');

select ok(has_column_privilege('authenticated', 'public.ad_template_rights', 'level', 'UPDATE'), 'ad_template_rights.level: ändern');
select ok(not has_column_privilege('authenticated', 'public.ad_template_rights', 'module_code', 'UPDATE'), 'ad_template_rights.module_code: nicht ändern');
select ok(not has_table_privilege('authenticated', 'public.ad_template_rights', 'INSERT, DELETE'), 'ad_template_rights: kein Insert/Delete');

select ok(has_table_privilege('authenticated', 'public.ad_template_assignments', 'SELECT'), 'ad_template_assignments: lesen');
select ok(not has_table_privilege('authenticated', 'public.ad_template_assignments', 'INSERT, UPDATE, DELETE'), 'ad_template_assignments: nur über Funktionen');

select ok(has_column_privilege('authenticated', 'public.ad_accesses', 'login_email', 'INSERT, UPDATE'), 'ad_accesses.login_email: schreiben');
select ok(has_column_privilege('authenticated', 'public.ad_accesses', 'person_id', 'INSERT'), 'ad_accesses.person_id: anlegen');
select ok(not has_column_privilege('authenticated', 'public.ad_accesses', 'status', 'INSERT'), 'ad_accesses.status: nicht anlegen');
select ok(not has_column_privilege('authenticated', 'public.ad_accesses', 'status', 'UPDATE'), 'ad_accesses.status: nicht ändern');
select ok(not has_column_privilege('authenticated', 'public.ad_accesses', 'auth_user_id', 'UPDATE'), 'ad_accesses.auth_user_id: nicht ändern');
select ok(not has_column_privilege('authenticated', 'public.ad_accesses', 'is_emergency', 'INSERT'), 'ad_accesses.is_emergency: nicht anlegen');
select ok(not has_table_privilege('authenticated', 'public.ad_accesses', 'DELETE'), 'ad_accesses: nicht löschen');

select ok(has_table_privilege('authenticated', 'public.ad_audit_log', 'SELECT'), 'ad_audit_log: lesen');
select ok(not has_table_privilege('authenticated', 'public.ad_audit_log', 'INSERT, UPDATE, DELETE'), 'ad_audit_log: nur System');

select ok(not has_table_privilege('authenticated', 'public.ad_test_login_domains', 'SELECT, INSERT, UPDATE, DELETE'),
  'ad_test_login_domains: kein Recht für authenticated');

-- Kern v0.6/v0.7 (spec T26, T33, T34, T37): Policies und Rechte der neuen Tabellen
select results_eq(
  $$ select tablename::text collate "default", policyname::text collate "default", cmd::text collate "default"
     from pg_policies
     where schemaname = 'public'
       and tablename in ('ea_referate', 'ea_gremien', 'ad_assignment_referate', 'ad_qualification_types',
                         'ea_volunteer_status_history')
     order by tablename, policyname $$,
  $$ values
     ('ad_assignment_referate'::text, 'ad_assignment_referate_select'::text, 'SELECT'::text),
     ('ad_qualification_types', 'ad_qualification_types_insert', 'INSERT'),
     ('ad_qualification_types', 'ad_qualification_types_select', 'SELECT'),
     ('ad_qualification_types', 'ad_qualification_types_update', 'UPDATE'),
     ('ea_gremien', 'ea_gremien_insert', 'INSERT'),
     ('ea_gremien', 'ea_gremien_select', 'SELECT'),
     ('ea_gremien', 'ea_gremien_update', 'UPDATE'),
     ('ea_referate', 'ea_referate_insert', 'INSERT'),
     ('ea_referate', 'ea_referate_select', 'SELECT'),
     ('ea_referate', 'ea_referate_update', 'UPDATE'),
     ('ea_volunteer_status_history', 'ea_volunteer_status_history_select', 'SELECT') $$,
  'Policies der neuen Tabellen nach spec.md Abschnitt 3'
);
select is_empty(
  $$ select c.relname from pg_class c join pg_namespace n on n.oid = c.relnamespace
     where n.nspname = 'public' and c.relkind = 'r' and not c.relrowsecurity $$,
  'RLS auf jeder Tabelle'
);
select ok(has_column_privilege('authenticated', 'public.ad_template_rights', 'scope', 'UPDATE'), 'ad_template_rights.scope: ändern');
select ok(not has_table_privilege('authenticated', 'public.ad_assignment_referate', 'INSERT, UPDATE, DELETE'),
  'ad_assignment_referate: nur über Funktionen');
select ok(not has_table_privilege('authenticated', 'public.ea_referate', 'DELETE'), 'ea_referate: nicht löschen');
select ok(not has_table_privilege('authenticated', 'public.ea_gremien', 'DELETE'), 'ea_gremien: nicht löschen');
select ok(not has_table_privilege('authenticated', 'public.ad_qualification_types', 'DELETE'), 'ad_qualification_types: nicht löschen');
select ok(not has_column_privilege('authenticated', 'public.ad_qualification_types', 'source_ref', 'INSERT'),
  'ad_qualification_types.source_ref: nur Migration');
select ok(not has_column_privilege('authenticated', 'public.ad_qualification_types', 'source_ref', 'UPDATE'),
  'ad_qualification_types.source_ref: nicht ändern');
select ok(has_column_privilege('authenticated', 'public.ea_persons', 'preferred_name', 'INSERT, UPDATE'), 'ea_persons.preferred_name: schreiben');
select ok(not has_column_privilege('authenticated', 'public.ea_persons', 'kind', 'UPDATE'), 'ea_persons.kind: nicht ändern');
select ok(not has_column_privilege('authenticated', 'public.ea_persons', 'volunteer_status', 'INSERT'), 'ea_persons.volunteer_status: nicht anlegen');
select ok(not has_column_privilege('authenticated', 'public.ea_persons', 'volunteer_status', 'UPDATE'), 'ea_persons.volunteer_status: nicht ändern');
select ok(not has_column_privilege('authenticated', 'public.ea_persons', 'created_in', 'INSERT, UPDATE'), 'ea_persons.created_in: nur Default');
select ok(not has_table_privilege('authenticated', 'public.ea_volunteer_status_history', 'INSERT, UPDATE, DELETE'),
  'ea_volunteer_status_history: nur über Funktionen');

-- Funktionen
select ok(has_function_privilege('authenticated', 'public.ad_has_level(text, public.ad_level)', 'EXECUTE'), 'ad_has_level');
select ok(has_function_privilege('authenticated', 'public.ad_has_any_level(text, public.ad_level)', 'EXECUTE'), 'ad_has_any_level');
select ok(has_function_privilege('authenticated', 'public.ad_my_referate(text, public.ad_level)', 'EXECUTE'), 'ad_my_referate');
select ok(has_function_privilege('authenticated', 'public.ad_set_assignment_referate(uuid, uuid[])', 'EXECUTE'),
  'ad_set_assignment_referate');
select ok(has_function_privilege('authenticated', 'public.ad_has_active_access()', 'EXECUTE'), 'ad_has_active_access');
select ok(has_function_privilege('authenticated', 'public.ad_can_edit_qualification_types()', 'EXECUTE'),
  'ad_can_edit_qualification_types');
select ok(not has_function_privilege('authenticated', 'public.ad_check_referate(uuid[])', 'EXECUTE'), 'ad_check_referate intern');
select ok(not has_function_privilege('authenticated', 'public.ad_template_needs_referate(uuid)', 'EXECUTE'),
  'ad_template_needs_referate intern');
select is_empty(
  $$ select p.proname from pg_proc p join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'public' and has_function_privilege('anon', p.oid, 'EXECUTE') $$,
  'keine Funktion für anon'
);
select ok(has_function_privilege('authenticated', 'public.ad_my_modules()', 'EXECUTE'), 'ad_my_modules');
select ok(has_function_privilege('authenticated', 'public.ad_assign_template(uuid, uuid, uuid[])', 'EXECUTE'), 'ad_assign_template');
select ok(has_function_privilege('authenticated', 'public.ad_revoke_template(uuid, uuid)', 'EXECUTE'), 'ad_revoke_template');
select ok(not has_function_privilege('authenticated', 'public.ad_login_email_allowed(extensions.citext)', 'EXECUTE'),
  'ad_login_email_allowed nur service_role');
select ok(has_function_privilege('service_role', 'public.ad_login_email_allowed(extensions.citext)', 'EXECUTE'),
  'ad_login_email_allowed für Edge Functions');
select is_empty(
  $$ select p.proname from pg_proc p join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'public' and p.prorettype = 'trigger'::regtype
       and has_function_privilege('authenticated', p.oid, 'EXECUTE') $$,
  'Trigger-Funktionen ohne Grant'
);

-- security definer immer mit leerem search_path
select is_empty(
  $$ select p.proname from pg_proc p join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'public' and p.prosecdef
       and not coalesce(p.proconfig @> array['search_path=""'], false) $$,
  'jede security-definer-Funktion hat search_path = '''''
);

select * from finish();
rollback;
