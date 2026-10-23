-- US-AD-16, US-AD-26 (spec T7 Teil, T48) und US-EA-19 (EA spec T3): Seed nach spec.md AD Abschnitt 9 (Personen 1–12)
-- und EA spec.md Abschnitt 9 (Personen 19–22, System-Eigenschaftsarten statt Testarten, Ü3).
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

select is((select count(*)::int from public.ea_persons), 16, '16 Personen (1–12, 19–22)');
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

-- Eigenschaftsarten: 25 System-Eigenschaftsarten (Migration) und 2 Testarten ohne system_key (Ü3)
select is((select count(*)::int from public.ea_property_types), 27, '25 System-Eigenschaftsarten + 2 Testarten');
select results_eq(
  $$ select name from public.ea_property_types where system_key is null order by name $$,
  $$ values ('Erste-Hilfe-Kurs am'::text), ('T-Shirt-Größe') $$,
  'nur T-Shirt-Größe und Erste-Hilfe-Kurs am bleiben Testarten (Ü3)');
select is((select count(*)::int from public.ea_property_types where name like '%(Test)%' or name = 'Hauptamt' and system_key is null), 0,
  'keine Testarten mit demselben system_key wie eine System-Eigenschaftsart');

-- Eigenschaften der Personen 1–12 verweisen auf die System-Eigenschaftsarten (AK1)
select results_eq(
  $$ select p.id, t.system_key from public.ea_properties p join public.ea_property_types t on t.id = p.property_type_id
      where p.id in ('e0000000-0000-4000-8000-000000000001', 'e0000000-0000-4000-8000-000000000002',
                     'e0000000-0000-4000-8000-000000000003', 'e0000000-0000-4000-8000-000000000005',
                     'e0000000-0000-4000-8000-000000000009', 'e0000000-0000-4000-8000-000000000014')
      order by p.id $$,
  $$ values ('e0000000-0000-4000-8000-000000000001'::uuid, 'employment'::text), ('e0000000-0000-4000-8000-000000000002', 'function'),
            ('e0000000-0000-4000-8000-000000000003', 'license'), ('e0000000-0000-4000-8000-000000000005', 'birth_date'),
            ('e0000000-0000-4000-8000-000000000009', 'position'), ('e0000000-0000-4000-8000-000000000014', 'contact') $$,
  'Hauptamt, Funktion, Lizenz, Geburtsdatum, Amt, Kontaktdaten über system_key');
select is((select property_type_id from public.ea_properties where id = 'e0000000-0000-4000-8000-000000000004'),
  'd0000000-0000-4000-8000-000000000002'::uuid, 'T-Shirt-Größe bleibt Testart');
select is((select count(*)::int from public.ea_properties), 24, '24 Eigenschaften');
select is(
  (select q.code from public.ea_properties p join public.ad_qualification_types q on q.id = (p.field_values ->> 'qualification_type')::uuid
    where p.id = 'e0000000-0000-4000-8000-000000000007'), 'TCSP', 'Person 5 mit historischer Qualifikationsart (Altbestand)');
select is((select field_values ->> 'valid_until' from public.ea_properties where id = 'e0000000-0000-4000-8000-000000000007'),
  '2019-12-31', 'Lizenz von Person 5 mit gültig bis 31.12.2019 (v0.7.2)');

-- Personen 19–22 (AK2): relative Datumswerte, Beispiel-IBAN, Gremium
select results_eq(
  $$ select right(id::text, 2)::int, first_name, last_name, volunteer_status::text, volunteer_status_since
       from public.ea_persons where id > 'a0000000-0000-4000-8000-000000000012' order by id $$,
  $$ values (19, 'Lena'::text, 'Lizenz'::text, 'active'::text, date '2024-01-01'), (20, 'Max', 'Abgelaufen', 'active', date '2020-01-01'),
            (21, 'Greta', 'Gremium', 'active', date '2023-01-01'), (22, 'Sven', 'Schlüssel', 'active', date '2025-01-01') $$,
  'Lena Lizenz, Max Abgelaufen, Greta Gremium, Sven Schlüssel aktiv');
select is((select field_values ->> 'valid_until' from public.ea_properties where id = 'e0000000-0000-4000-8000-000000000016'),
  to_char(current_date + interval '2 months', 'YYYY-MM-DD'), 'Lena: Lizenz gültig bis heute + 2 Monate');
select is((select field_values ->> 'issued_on' from public.ea_properties where id = 'e0000000-0000-4000-8000-000000000019'),
  to_char(current_date - interval '34 months', 'YYYY-MM-DD'), 'Max: Führungszeugnis ausgestellt heute − 34 Monate');
select is((select valid_from from public.ea_properties where id = 'e0000000-0000-4000-8000-000000000019'),
  (current_date - interval '34 months' + interval '7 days')::date, 'Max: eingesehen 7 Tage nach Ausstellung');
select is((select g.name from public.ea_properties p join public.ea_gremien g on g.id = p.related_gremium_id
            where p.id = 'e0000000-0000-4000-8000-000000000020'), 'Beirat', 'Greta im Beirat');
select is((select field_values ->> 'iban' from public.ea_properties where id = 'e0000000-0000-4000-8000-000000000024'),
  'DE89370400440532013000', 'Sven: Beispiel-IBAN normalisiert');
select is((select count(*)::int from public.ea_volunteer_status_history), 9, 'Ehrenamtsstatus mit Historie (5 + 4)');

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

-- nur fiktive Daten (AK4)
select is_empty($$ select 1 from public.ea_persons where last_name !~ '^[A-Za-zÄÖÜäöüß -]+$' $$, 'nur fiktive Nachnamen');
select is_empty($$ select 1 from public.ea_properties where field_values ->> 'email' not like '%@example.test' $$,
  'E-Mail-Adressen nur @example.test');

select * from finish();
rollback;
