-- US-AD-16, US-AD-26 (spec T7 Teil, T48): Seed nach spec.md Abschnitt 9, Personen 1–12 (Kern v0.7.2).
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

select is((select count(*)::int from public.ea_persons), 12, '12 Personen');
select is((select count(*)::int from public.ea_persons where kind = 'function'), 1, 'eine Funktionsperson');
select results_eq(
  $$ select a.login_email::text, a.status::text from public.ad_accesses a order by a.login_email $$,
  $$ values ('test.admin@dav-leipzig.de'::text, 'active'::text),
            ('test.eingeladen@dav-leipzig.de', 'invited'),
            ('test.geschaeftsstelle@dav-leipzig.de', 'active'),
            ('test.gesperrt@dav-leipzig.de', 'locked'),
            ('test.notfall@dav-leipzig.de', 'active'),
            ('test.referent@dav-leipzig.de', 'active'),
            ('test.vorstand@dav-leipzig.de', 'active') $$,
  'Zugänge mit Zielstatus; fünf aktive Testzugänge');
select results_eq(
  $$ select name from public.ea_property_types order by name $$,
  $$ values ('Amt (Test)'::text), ('Erste-Hilfe-Kurs am'), ('Funktion (Test)'), ('Geburtsdatum (Test)'),
            ('Hauptamt'), ('Kontaktdaten (Test)'), ('Lizenz (Test)'), ('T-Shirt-Größe') $$,
  '8 Testarten');
select results_eq(
  $$ select system_key from public.ea_property_types where system_key is not null order by system_key $$,
  $$ values ('birth_date'::text), ('contact') $$,
  'im Kern nur birth_date und contact als system_key (v0.7.2)');
select results_eq(
  $$ select f.key from public.ea_property_fields f join public.ea_property_types t on t.id = f.property_type_id
      where t.name in ('Lizenz (Test)', 'Kontaktdaten (Test)', 'Geburtsdatum (Test)', 'Funktion (Test)', 'Amt (Test)',
                       'Hauptamt')
      order by t.name, f.sort_order $$,
  $$ values ('position'::text), ('function'), ('date'), ('title'), ('email'), ('phone_mobile'),
            ('qualification_type'), ('license_number'), ('valid_until') $$,
  'Feldschlüssel nach EA 01-erhebung.md C2');
select is((select count(*)::int from public.ea_properties), 14, '14 Eigenschaften');
select is(
  (select q.code from public.ea_properties p join public.ad_qualification_types q on q.id = (p.field_values ->> 'qualification_type')::uuid
    where p.id = 'e0000000-0000-4000-8000-000000000007'), 'TCSP', 'Person 5 mit historischer Qualifikationsart (Altbestand)');
select is((select field_values ->> 'valid_until' from public.ea_properties where id = 'e0000000-0000-4000-8000-000000000007'),
  '2019-12-31', 'Lizenz von Person 5 mit gültig bis 31.12.2019 (v0.7.2)');
select is((select count(*)::int from public.ea_volunteer_status_history), 5, 'Ehrenamtsstatus mit Historie');
select results_eq(
  $$ select r.name from public.ad_assignment_referate ar
       join public.ad_template_assignments ta on ta.id = ar.assignment_id
       join public.ea_referate r on r.id = ar.referat_id
      where ta.person_id = 'a0000000-0000-4000-8000-000000000009' $$,
  $$ values ('Klettern'::text) $$, 'Rita Referentin mit Referat Klettern');
select is((select count(*)::int from public.ad_audit_log), 4, '4 Protokolleinträge');
select is((select details from public.ad_audit_log where action = 'template_assigned'), 'Referent:in (Referate: Klettern)',
  'template_assigned für Rita Referentin');
select is((select count(*)::int from public.ea_persons where created_in = 'GR'), 1, 'Person 12 aus Gruppen');

select * from finish();
rollback;
