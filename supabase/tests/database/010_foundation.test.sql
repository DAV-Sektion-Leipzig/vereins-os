-- US-AD-01 (spec T7 Teil): Grundlagen, Enums, Module, RLS überall, keine Rechte für anon.
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

-- Erweiterungen
select has_extension('citext');
select has_extension('pg_trgm');
select has_extension('pg_cron');

-- Enums mit genau diesen Werten in dieser Reihenfolge
select enum_has_labels('public', 'ad_level', array['none', 'read', 'edit', 'manage']);
select enum_has_labels('public', 'ad_access_status', array['none', 'invited', 'active', 'locked']);
select enum_has_labels('public', 'ea_data_type',
  array['text', 'date', 'boolean', 'choice', 'number', 'year', 'qualification_type']);
select enum_has_labels('public', 'ea_person_kind', array['human', 'function']);
select enum_has_labels('public', 'ad_audit_action',
  array['invited', 'email_changed', 'template_assigned', 'template_revoked', 'referate_changed', 'locked', 'unlocked',
        'emergency_login']);
select enum_has_labels('public', 'ad_scope', array['all', 'referat']);
select enum_has_labels('public', 'ea_read_level', array['all', 'office', 'confidential']);
select enum_has_labels('public', 'ea_relation_kind', array['none', 'referat', 'gremium', 'group']);
select enum_has_labels('public', 'ea_property_category',
  array['master_data', 'contact', 'assignment', 'qualification', 'proof', 'yearly', 'issue', 'external_access', 'other']);
select enum_has_labels('public', 'ea_volunteer_status', array['active', 'dormant', 'left']);
select enum_has_labels('public', 'ad_qualification_kind', array['license', 'add_on', 'course', 'training']);
select enum_has_labels('public', 'ad_license_level', array['pre', 'C', 'B', 'A', 'none']);
select enum_has_labels('public', 'ad_qualification_status', array['current', 'historic']);

-- Module
select is((select count(*)::int from public.ad_modules), 12, 'ad_modules hat 12 Module (v0.8: EZ; Dashboard: DS; v0.9: TK)');
select results_eq(
  $$ select code from public.ad_modules where is_available order by sort_order $$,
  $$ values ('AD'::text), ('EA'), ('GR'), ('EZ'), ('FI') $$,
  'verfügbar: AD, EA, GR, EZ, FI (Freigabe 26.10.2026)'
);
select results_eq(
  $$ select code from public.ad_modules order by sort_order $$,
  $$ values ('DS'::text), ('AD'), ('SC'), ('EA'), ('GR'), ('EZ'), ('TK'), ('FI'), ('OA'), ('PM'), ('GS'), ('AM') $$,
  'Reihenfolge der Module (v0.8: EZ direkt nach GR; Dashboard: DS zuerst; v0.9: TK direkt nach EZ)'
);

-- RLS auf jeder Tabelle in public
select is_empty(
  $$ select c.relname from pg_class c
     join pg_namespace n on n.oid = c.relnamespace
     where n.nspname = 'public' and c.relkind in ('r', 'p') and not c.relrowsecurity $$,
  'jede Tabelle in public hat RLS'
);

-- anon hat auf nichts in public ein Recht
select is_empty(
  $$ select c.relname from pg_class c
     join pg_namespace n on n.oid = c.relnamespace
     where n.nspname = 'public' and c.relkind in ('r', 'p', 'v')
       and has_table_privilege('anon', c.oid, 'SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER') $$,
  'anon hat keine Rechte auf Tabellen und Views'
);
select is_empty(
  $$ select p.proname from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'public' and has_function_privilege('anon', p.oid, 'EXECUTE') $$,
  'anon darf keine Funktion in public ausführen'
);

select * from finish();
rollback;
