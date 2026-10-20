-- US-AD-01 (spec T7 Teil, T24 Teil): Einrichtungsskript PROD, auf dem lokalen Stack zweimal ausgeführt
-- (siehe .github/workflows/db-tests.yml, Block A; fiktive Parameter Erika Beispiel).
-- Der Abbruch bei eingetragener Testdomain wird im Workflow geprüft.
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

select is((select count(*)::int from public.ad_templates), 3, 'genau drei Startvorlagen (AK1, AK3)');

select is((select count(*)::int from public.ea_persons), 2, 'genau zwei Personen, nichts doppelt (AK3)');

select results_eq(
  $$ select p.first_name, p.last_name, p.kind::text, a.login_email::text, a.status::text, a.is_emergency
     from public.ea_persons p join public.ad_accesses a on a.person_id = p.id
     order by a.is_emergency $$,
  $$ values ('Erika'::text, 'Beispiel'::text, 'human'::text, 'erika.beispiel@dav-leipzig.de'::text, 'none'::text, false),
            ('Geschäftsstelle', 'Notfall-Admin', 'function', 'geschaeftsstelle@dav-leipzig.de', 'none', true) $$,
  'Admin und Funktionsperson mit Zugang im Status „kein Zugang“ (AK2)'
);

select results_eq(
  $$ select a.login_email::text, t.name
     from public.ad_template_assignments ta
     join public.ad_accesses a on a.person_id = ta.person_id
     join public.ad_templates t on t.id = ta.template_id
     where ta.revoked_at is null
     order by a.login_email, t.name $$,
  $$ values ('erika.beispiel@dav-leipzig.de'::text, 'Admin'::text),
            ('erika.beispiel@dav-leipzig.de', 'Vorstand'),
            ('geschaeftsstelle@dav-leipzig.de', 'Admin') $$,
  'Vorlagen Admin und Vorstand bzw. Admin, nicht doppelt'
);

select is((select count(*)::int from public.ad_audit_log where action = 'template_assigned'), 3,
  'jede Zuweisung genau einmal protokolliert');

select is((select count(*)::int from public.ad_test_login_domains), 0, 'keine Testdomain');

select * from finish();
rollback;
