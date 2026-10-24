-- Testdaten nach spec.md AD Abschnitt 9 – nur fiktive Personen und Adressen (die Adressen existieren nicht).
-- Nur über supabase/seed.sh ausführen (psql-Variable test_password; Abbruch bei PROD).
-- Idempotent; feste UUIDs, auf die sich die pgTAP-Tests beziehen:
--   Personen a…01–a…12, Auth-Nutzer b…01 (Admin), b…02 (Geschäftsstelle), b…03 (Vorstand),
--   b…06 (eingeladen), b…07 (gesperrt), b…08 (Notfall-Admin), b…09 (Referent:in, Referat Klettern).
-- Personen 1–12 (Kern bis v0.7.1) und 19–22 (EA spec.md Abschnitt 9); 13–18, Orte und Sätze folgen mit den
-- Nachträgen v0.8/v0.9 der Administration.
-- Läuft ohne Nutzerkontext: Ehrenamtsstatus und historische Qualifikationsarten sind dadurch setzbar.
--   Testarten d…02 (T-Shirt-Größe) und d…03 (Erste-Hilfe-Kurs am); alle übrigen Eigenschaften verweisen auf die
--   System-Eigenschaftsarten der Migration 20261024000100 (Auflösung über system_key, Ü3 nach
--   docs/specs/ea-ehrenamt/uebergabe-administration.md). Eigenschaften e…01–e…24.
--   Datumswerte der Personen 19–22 relativ zu current_date (EA spec.md Abschnitt 9).
-- Abschnitt 8: Gruppen (GR spec.md Abschnitt 9) – Gruppen c…01–c…04, Personen a…23–a…32, Eigenschaften e…25–e…41,
--   Testzugang b…32 (Kim Kinderjugend, Referent:in Kinder und Jugend).

-- 1. Personen
insert into public.ea_persons (id, first_name, last_name, kind) values
  ('a0000000-0000-4000-8000-000000000001', 'Test', 'Admin', 'human'),
  ('a0000000-0000-4000-8000-000000000002', 'Anna', 'Fiktiv', 'human'),
  ('a0000000-0000-4000-8000-000000000003', 'Bernd', 'Beispiel', 'human'),
  ('a0000000-0000-4000-8000-000000000004', 'Toni', 'Muster', 'human'),
  ('a0000000-0000-4000-8000-000000000005', 'Anton', 'Muster', 'human'),
  ('a0000000-0000-4000-8000-000000000006', 'Eva', 'Eingeladen', 'human'),
  ('a0000000-0000-4000-8000-000000000007', 'Dieter', 'Gesperrt', 'human'),
  ('a0000000-0000-4000-8000-000000000008', 'Geschäftsstelle', 'Notfall-Admin', 'function')
on conflict (id) do nothing;

insert into public.ea_persons (id, first_name, last_name, kind, created_in) values
  ('a0000000-0000-4000-8000-000000000009', 'Rita', 'Referentin', 'human', 'AD'),
  ('a0000000-0000-4000-8000-000000000010', 'Karl', 'Zweireferat', 'human', 'AD'),
  ('a0000000-0000-4000-8000-000000000011', 'Olga', 'Ausgeschieden', 'human', 'AD'),
  ('a0000000-0000-4000-8000-000000000012', 'Paul', 'Nurgruppe', 'human', 'GR'),
  ('a0000000-0000-4000-8000-000000000019', 'Lena', 'Lizenz', 'human', 'AD'),
  ('a0000000-0000-4000-8000-000000000020', 'Max', 'Abgelaufen', 'human', 'AD'),
  ('a0000000-0000-4000-8000-000000000021', 'Greta', 'Gremium', 'human', 'AD'),
  ('a0000000-0000-4000-8000-000000000022', 'Sven', 'Schlüssel', 'human', 'AD')
on conflict (id) do nothing;

-- Ehrenamtsstatus mit Historie (spec.md Abschnitt 9)
with v (person_id, status, since) as (values
  ('a0000000-0000-4000-8000-000000000004'::uuid, 'active'::public.ea_volunteer_status, date '2025-03-01'),
  ('a0000000-0000-4000-8000-000000000005'::uuid, 'dormant'::public.ea_volunteer_status, date '2026-01-01'),
  ('a0000000-0000-4000-8000-000000000009'::uuid, 'active'::public.ea_volunteer_status, date '2024-01-01'),
  ('a0000000-0000-4000-8000-000000000010'::uuid, 'active'::public.ea_volunteer_status, date '2023-01-01'),
  ('a0000000-0000-4000-8000-000000000011'::uuid, 'left'::public.ea_volunteer_status, date '2025-06-30'),
  ('a0000000-0000-4000-8000-000000000019'::uuid, 'active'::public.ea_volunteer_status, date '2024-01-01'),
  ('a0000000-0000-4000-8000-000000000020'::uuid, 'active'::public.ea_volunteer_status, date '2020-01-01'),
  ('a0000000-0000-4000-8000-000000000021'::uuid, 'active'::public.ea_volunteer_status, date '2023-01-01'),
  ('a0000000-0000-4000-8000-000000000022'::uuid, 'active'::public.ea_volunteer_status, date '2025-01-01')
), upd as (
  update public.ea_persons p
     set volunteer_status = v.status, volunteer_status_since = v.since
    from v
   where p.id = v.person_id and p.volunteer_status is null
  returning p.id, p.volunteer_status, p.volunteer_status_since
)
insert into public.ea_volunteer_status_history (person_id, status, valid_from)
select id, volunteer_status, volunteer_status_since from upd;

-- 2. Zugänge mit Zielstatus (vor auth.users, damit der Insert-Trigger nur auth_user_id setzt)
insert into public.ad_accesses (person_id, login_email, status, is_emergency, last_invited_at, locked_at) values
  ('a0000000-0000-4000-8000-000000000001', 'test.admin@dav-leipzig.de', 'active', false, now() - interval '30 days', null),
  ('a0000000-0000-4000-8000-000000000002', 'test.geschaeftsstelle@dav-leipzig.de', 'active', false, now() - interval '30 days', null),
  ('a0000000-0000-4000-8000-000000000003', 'test.vorstand@dav-leipzig.de', 'active', false, now() - interval '30 days', null),
  ('a0000000-0000-4000-8000-000000000006', 'test.eingeladen@dav-leipzig.de', 'invited', false, now() - interval '2 days', null),
  ('a0000000-0000-4000-8000-000000000007', 'test.gesperrt@dav-leipzig.de', 'locked', false, now() - interval '400 days', now() - interval '10 days'),
  ('a0000000-0000-4000-8000-000000000008', 'test.notfall@dav-leipzig.de', 'active', true, now() - interval '30 days', null),
  ('a0000000-0000-4000-8000-000000000009', 'test.referent@dav-leipzig.de', 'active', false, now() - interval '30 days', null)
on conflict (person_id) do nothing;

-- 3. Zuweisungen der Rechtevorlagen
insert into public.ad_template_assignments (person_id, template_id)
select v.person_id, t.id
  from (values
    ('a0000000-0000-4000-8000-000000000001'::uuid, 'Admin'),
    ('a0000000-0000-4000-8000-000000000002'::uuid, 'Geschäftsstelle'),
    ('a0000000-0000-4000-8000-000000000003'::uuid, 'Vorstand'),
    ('a0000000-0000-4000-8000-000000000006'::uuid, 'Geschäftsstelle'),
    ('a0000000-0000-4000-8000-000000000007'::uuid, 'Geschäftsstelle'),
    ('a0000000-0000-4000-8000-000000000008'::uuid, 'Admin'),
    ('a0000000-0000-4000-8000-000000000009'::uuid, 'Referent:in')
  ) as v (person_id, template_name)
  join public.ad_templates t on t.name = v.template_name
 where not exists (
   select 1 from public.ad_template_assignments ta
    where ta.person_id = v.person_id and ta.template_id = t.id and ta.revoked_at is null
 );

-- Referat der Zuweisung Referent:in (R31)
insert into public.ad_assignment_referate (assignment_id, referat_id)
select ta.id, r.id
  from public.ad_template_assignments ta
  join public.ad_templates t on t.id = ta.template_id and t.name = 'Referent:in'
  join public.ea_referate r on r.name = 'Klettern'
 where ta.person_id = 'a0000000-0000-4000-8000-000000000009' and ta.revoked_at is null
on conflict do nothing;

-- 4. Auth-Nutzer (Passwort aus psql-Variable; eingeladen ohne Passwort; gesperrt mit Bann)
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, invited_at, banned_until,
  raw_app_meta_data, raw_user_meta_data,
  confirmation_token, recovery_token, email_change_token_new, email_change,
  created_at, updated_at
)
select
  '00000000-0000-0000-0000-000000000000', v.id, 'authenticated', 'authenticated', v.email,
  case when v.with_password then extensions.crypt(:'test_password', extensions.gen_salt('bf')) else '' end,
  case when v.with_password then now() else null end,
  now() - interval '30 days',
  case when v.banned then now() + interval '100 years' else null end,
  '{"provider": "email", "providers": ["email"]}'::jsonb, '{}'::jsonb,
  '', '', '', '',
  now() - interval '30 days', now()
from (values
  ('b0000000-0000-4000-8000-000000000001'::uuid, 'test.admin@dav-leipzig.de', true, false),
  ('b0000000-0000-4000-8000-000000000002'::uuid, 'test.geschaeftsstelle@dav-leipzig.de', true, false),
  ('b0000000-0000-4000-8000-000000000003'::uuid, 'test.vorstand@dav-leipzig.de', true, false),
  ('b0000000-0000-4000-8000-000000000006'::uuid, 'test.eingeladen@dav-leipzig.de', false, false),
  ('b0000000-0000-4000-8000-000000000007'::uuid, 'test.gesperrt@dav-leipzig.de', true, true),
  ('b0000000-0000-4000-8000-000000000008'::uuid, 'test.notfall@dav-leipzig.de', true, false),
  ('b0000000-0000-4000-8000-000000000009'::uuid, 'test.referent@dav-leipzig.de', true, false)
) as v (id, email, with_password, banned)
on conflict (id) do nothing;

insert into auth.identities (id, user_id, provider_id, provider, identity_data, last_sign_in_at, created_at, updated_at)
select gen_random_uuid(), u.id, u.id::text, 'email',
       jsonb_build_object('sub', u.id::text, 'email', u.email, 'email_verified', u.email_confirmed_at is not null),
       null, now(), now()
  from auth.users u
 where u.id in (
   'b0000000-0000-4000-8000-000000000001', 'b0000000-0000-4000-8000-000000000002',
   'b0000000-0000-4000-8000-000000000003', 'b0000000-0000-4000-8000-000000000006',
   'b0000000-0000-4000-8000-000000000007', 'b0000000-0000-4000-8000-000000000008',
   'b0000000-0000-4000-8000-000000000009'
 )
on conflict (provider_id, provider) do nothing;

-- Gesperrt am/von (durch den Test-Admin)
update public.ad_accesses
   set locked_by = 'b0000000-0000-4000-8000-000000000001'
 where person_id = 'a0000000-0000-4000-8000-000000000007' and locked_by is null;

-- 5. Protokoll: je ein Eintrag invited, template_assigned (Rita Referentin, Referat Klettern), locked, emergency_login
insert into public.ad_audit_log (occurred_at, actor_user_id, subject_person_id, action, details)
select v.occurred_at, v.actor, v.subject, v.action::public.ad_audit_action, v.details
  from (values
    (now() - interval '2 days', 'b0000000-0000-4000-8000-000000000001'::uuid,
     'a0000000-0000-4000-8000-000000000006'::uuid, 'invited', null::text),
    (now() - interval '30 days', 'b0000000-0000-4000-8000-000000000001'::uuid,
     'a0000000-0000-4000-8000-000000000009'::uuid, 'template_assigned', 'Referent:in (Referate: Klettern)'),
    (now() - interval '10 days', 'b0000000-0000-4000-8000-000000000001'::uuid,
     'a0000000-0000-4000-8000-000000000007'::uuid, 'locked', null),
    (now() - interval '1 day', 'b0000000-0000-4000-8000-000000000008'::uuid,
     'a0000000-0000-4000-8000-000000000008'::uuid, 'emergency_login', null)
  ) as v (occurred_at, actor, subject, action, details)
 where not exists (
   select 1 from public.ad_audit_log l
    where l.subject_person_id = v.subject and l.action = v.action::public.ad_audit_action
 );

-- 6. Testarten ohne system_key (spec.md AD Abschnitt 9); die System-Eigenschaftsarten kommen aus der Migration
insert into public.ea_property_types
  (id, name, purpose, category, read_level, relation_kind, relation_required, allow_multiple, system_key, visible_in)
values
  ('d0000000-0000-4000-8000-000000000002', 'T-Shirt-Größe', 'Bestellung von Vereinskleidung',
   'issue', 'all', 'none', false, false, null, '{EA}'),
  ('d0000000-0000-4000-8000-000000000003', 'Erste-Hilfe-Kurs am', 'Nachweis für Tätigkeiten mit Gruppen',
   'qualification', 'all', 'none', false, true, null, '{EA}')
on conflict (id) do nothing;

-- Vorhandene Felder vorher herausfiltern: der Trigger ea_property_fields_guard prüft vor „on conflict“ und lehnt
-- Pflichtfelder für Arten mit Eigenschaften ab (zweiter Seed-Lauf in TEST)
insert into public.ea_property_fields
  (property_type_id, key, label, data_type, is_required, choice_values, allowed_qualification_kinds, sort_order)
select v.property_type_id, v.key, v.label, v.data_type::public.ea_data_type, v.is_required, v.choice_values,
       v.allowed_qualification_kinds::public.ad_qualification_kind[], v.sort_order
  from (values
    ('d0000000-0000-4000-8000-000000000002'::uuid, 'size'::text, 'Größe'::text, 'choice'::text, true, '{S,M,L,XL}'::text[], null::text[], 1),
    ('d0000000-0000-4000-8000-000000000003', 'date', 'Datum', 'date', true, null, null, 1)
  ) as v (property_type_id, key, label, data_type, is_required, choice_values, allowed_qualification_kinds, sort_order)
 where not exists (
   select 1 from public.ea_property_fields f where f.property_type_id = v.property_type_id and f.key = v.key
 );

-- 7. Eigenschaften (ohne Nutzerkontext: historische Qualifikationsart von Person 5 erlaubt, R27).
-- Art über system_key (System-Eigenschaftsarten, Ü3) oder feste ID (Testarten).
insert into public.ea_properties
  (id, person_id, property_type_id, field_values, related_referat_id, related_gremium_id, valid_from, valid_to)
select v.id, v.person_id,
       coalesce(v.type_id, (select t.id from public.ea_property_types t where t.system_key = v.system_key)),
       v.field_values,
       (select r.id from public.ea_referate r where r.name = v.referat),
       (select g.id from public.ea_gremien g where g.name = v.gremium),
       v.valid_from, v.valid_to
  from (values
    -- Anna Fiktiv: Hauptamt (vertraulich, nur AD)
    ('e0000000-0000-4000-8000-000000000001'::uuid, 'a0000000-0000-4000-8000-000000000002'::uuid,
     'employment'::text, null::uuid, '{"title": "Mitarbeiterin Geschäftsstelle"}'::jsonb,
     null::text, null::text, date '2024-03-01', null::date),
    -- Toni Muster
    ('e0000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000004',
     'function', null, '{"function": "Trainer:in"}', 'Klettern', null, date '2025-03-01', null),
    ('e0000000-0000-4000-8000-000000000003', 'a0000000-0000-4000-8000-000000000004',
     'license', null,
     jsonb_build_object('qualification_type', (select id from public.ad_qualification_types where code = 'TCSPI'),
                        'license_number', 'TEST-0001', 'valid_until', '2027-12-31'),
     null, null, date '2025-03-01', null),
    ('e0000000-0000-4000-8000-000000000004', 'a0000000-0000-4000-8000-000000000004',
     null, 'd0000000-0000-4000-8000-000000000002', '{"size": "M"}', null, null, date '2025-01-01', null),
    ('e0000000-0000-4000-8000-000000000005', 'a0000000-0000-4000-8000-000000000004',
     'birth_date', null, '{"date": "1990-05-12"}', null, null, date '1990-05-12', null),
    -- Anton Muster (Dublettenpaar zu 4)
    ('e0000000-0000-4000-8000-000000000006', 'a0000000-0000-4000-8000-000000000005',
     'function', null, '{"function": "Trainer:in"}', 'Ausbildung', null, date '2016-05-01', null),
    ('e0000000-0000-4000-8000-000000000007', 'a0000000-0000-4000-8000-000000000005',
     'license', null,
     jsonb_build_object('qualification_type', (select id from public.ad_qualification_types where code = 'TCSP'),
                        'valid_until', '2019-12-31'),
     null, null, date '2016-05-01', null),
    -- Dieter Gesperrt: Hauptamt beendet (vertraulich)
    ('e0000000-0000-4000-8000-000000000008', 'a0000000-0000-4000-8000-000000000007',
     'employment', null, '{"title": "Mitarbeiter Geschäftsstelle"}', null, null,
     date '2020-01-01', date '2025-12-31'),
    -- Rita Referentin
    ('e0000000-0000-4000-8000-000000000009', 'a0000000-0000-4000-8000-000000000009',
     'position', null, '{"position": "Referent:in"}', 'Klettern', null, date '2024-01-01', null),
    -- Karl Zweireferat
    ('e0000000-0000-4000-8000-000000000010', 'a0000000-0000-4000-8000-000000000010',
     'function', null, '{"function": "Helfer:in"}', 'Klettern', null, date '2023-01-01', null),
    ('e0000000-0000-4000-8000-000000000011', 'a0000000-0000-4000-8000-000000000010',
     'function', null, '{"function": "Trainer:in"}', 'Ausbildung', null, date '2023-01-01', null),
    ('e0000000-0000-4000-8000-000000000012', 'a0000000-0000-4000-8000-000000000010',
     'birth_date', null, '{"date": "1985-03-03"}', null, null, date '1985-03-03', null),
    -- Olga Ausgeschieden
    ('e0000000-0000-4000-8000-000000000013', 'a0000000-0000-4000-8000-000000000011',
     'function', null, '{"function": "Trainer:in"}', 'Klettern', null, date '2020-01-01', date '2025-06-30'),
    -- Paul Nurgruppe (simuliert eine Person nur aus Gruppen)
    ('e0000000-0000-4000-8000-000000000014', 'a0000000-0000-4000-8000-000000000012',
     'contact', null, '{"email": "paul.nurgruppe@example.test"}', null, null, date '2025-01-01', null),
    -- Lena Lizenz (19): Trainer:in Klettern, Lizenz TCBO läuft in 2 Monaten ab
    ('e0000000-0000-4000-8000-000000000015', 'a0000000-0000-4000-8000-000000000019',
     'function', null, '{"function": "Trainer:in"}', 'Klettern', null, date '2024-01-01', null),
    ('e0000000-0000-4000-8000-000000000016', 'a0000000-0000-4000-8000-000000000019',
     'license', null,
     jsonb_build_object('qualification_type', (select id from public.ad_qualification_types where code = 'TCBO'),
                        'license_number', 'TEST-0019',
                        'valid_until', to_char(current_date + interval '2 months', 'YYYY-MM-DD')),
     null, null, date '2022-06-01', null),
    -- Max Abgelaufen (20): Trainer:in Kinder und Jugend, Lizenz abgelaufen, Führungszeugnis-Einsicht läuft bald ab
    ('e0000000-0000-4000-8000-000000000017', 'a0000000-0000-4000-8000-000000000020',
     'function', null, '{"function": "Trainer:in"}', 'Kinder und Jugend', null, date '2020-01-01', null),
    ('e0000000-0000-4000-8000-000000000018', 'a0000000-0000-4000-8000-000000000020',
     'license', null,
     jsonb_build_object('qualification_type', (select id from public.ad_qualification_types where code = 'TCSPI'),
                        'valid_until', '2025-12-31'),
     null, null, date '2021-05-01', null),
    ('e0000000-0000-4000-8000-000000000019', 'a0000000-0000-4000-8000-000000000020',
     'police_clearance', null,
     jsonb_build_object('issued_on', to_char(current_date - interval '34 months', 'YYYY-MM-DD')),
     null, null, (current_date - interval '34 months' + interval '7 days')::date, null),
    -- Greta Gremium (21): Beirat, Mitglied, kein Referat
    ('e0000000-0000-4000-8000-000000000020', 'a0000000-0000-4000-8000-000000000021',
     'committee', null, '{"role": "Mitglied"}', null, 'Beirat', date '2023-07-01', null),
    -- Sven Schlüssel (22): Helfer:in Klettern, Schlüssel K4, Zugang DAV360, Bankverbindung (Beispiel-IBAN)
    ('e0000000-0000-4000-8000-000000000021', 'a0000000-0000-4000-8000-000000000022',
     'function', null, '{"function": "Helfer:in"}', 'Klettern', null, date '2025-01-01', null),
    ('e0000000-0000-4000-8000-000000000022', 'a0000000-0000-4000-8000-000000000022',
     'issued_item', null, '{"item": "Schlüssel K4", "number": "TEST-K4-22"}', null, null, date '2025-02-01', null),
    ('e0000000-0000-4000-8000-000000000023', 'a0000000-0000-4000-8000-000000000022',
     'external_access', null, '{"system": "DAV360"}', null, null, date '2025-02-01', null),
    ('e0000000-0000-4000-8000-000000000024', 'a0000000-0000-4000-8000-000000000022',
     'bank_account', null, '{"account_holder": "Sven Schlüssel", "iban": "DE89370400440532013000"}',
     null, null, date '2025-01-01', null)
  ) as v (id, person_id, system_key, type_id, field_values, referat, gremium, valid_from, valid_to)
on conflict (id) do nothing;

-- 8. Gruppen (GR spec.md Abschnitt 9): Gruppen c…01–c…04, Personen 23–32, Testzugang Kim Kinderjugend (b…32).
-- Ohne Nutzerkontext; Datumswerte relativ zu current_date, damit Status und Stichtage stabil bleiben.
-- Abweichung zur Tabelle in spec.md 9: Jana Fiktiv (24) ist zusätzlich erziehungsberechtigt für Sam Sechzehn (28),
-- damit dessen Vertrag eine gültige Vertragsinhaber:in hat (R4).
insert into public.gr_groups (id, name, referat_id, dissolved_on)
select v.id, v.name, r.id, v.dissolved_on
  from (values
    ('c0000000-0000-4000-8000-000000000001'::uuid, 'Jugendgruppe Test 1', 'Kinder und Jugend', null::date),
    ('c0000000-0000-4000-8000-000000000002'::uuid, 'Jugendgruppe Test 2', 'Kinder und Jugend', null::date),
    ('c0000000-0000-4000-8000-000000000003'::uuid, 'Klettergruppe Test', 'Klettern', null::date),
    ('c0000000-0000-4000-8000-000000000004'::uuid, 'Altgruppe Test', 'Kinder und Jugend', date '2025-06-30')
  ) as v (id, name, referat, dissolved_on)
  join public.ea_referate r on r.name = v.referat
on conflict (id) do nothing;

insert into public.gr_training_times (id, group_id, weekday, starts_at, ends_at, valid_from, valid_to) values
  ('c1000000-0000-4000-8000-000000000001', 'c0000000-0000-4000-8000-000000000001', 2, '16:30', '18:00', date '2025-09-01', null),
  ('c1000000-0000-4000-8000-000000000002', 'c0000000-0000-4000-8000-000000000001', 4, '17:00', '18:30', date '2025-09-01', null),
  ('c1000000-0000-4000-8000-000000000003', 'c0000000-0000-4000-8000-000000000002', 3, '17:00', '18:30', date '2025-01-01', date '2025-12-31'),
  ('c1000000-0000-4000-8000-000000000004', 'c0000000-0000-4000-8000-000000000002', 3, '18:00', '19:30', date '2026-01-01', null),
  ('c1000000-0000-4000-8000-000000000005', 'c0000000-0000-4000-8000-000000000004', 1, '16:00', '17:30', date '2024-01-01', date '2025-06-30')
on conflict (id) do nothing;

insert into public.ea_persons (id, first_name, last_name, kind, created_in) values
  ('a0000000-0000-4000-8000-000000000023', 'Mia', 'Fiktiv', 'human', 'GR'),
  ('a0000000-0000-4000-8000-000000000024', 'Jana', 'Fiktiv', 'human', 'GR'),
  ('a0000000-0000-4000-8000-000000000025', 'Ben', 'Fiktiv', 'human', 'GR'),
  ('a0000000-0000-4000-8000-000000000026', 'Lars', 'Lehrer', 'human', 'GR'),
  ('a0000000-0000-4000-8000-000000000027', 'Lea', 'Lehrer', 'human', 'GR'),
  ('a0000000-0000-4000-8000-000000000028', 'Sam', 'Sechzehn', 'human', 'GR'),
  ('a0000000-0000-4000-8000-000000000029', 'Erika', 'Oma', 'human', 'GR'),
  ('a0000000-0000-4000-8000-000000000030', 'Paula', 'Plan', 'human', 'GR'),
  ('a0000000-0000-4000-8000-000000000031', 'Tom', 'Ehemals', 'human', 'GR'),
  ('a0000000-0000-4000-8000-000000000032', 'Kim', 'Kinderjugend', 'human', 'AD')
on conflict (id) do nothing;

-- Ehrenamtsstatus der Betreuer:innen (R29) und von Kim Kinderjugend
with v (person_id, status, since) as (values
  ('a0000000-0000-4000-8000-000000000026'::uuid, 'active'::public.ea_volunteer_status, date '2025-09-01'),
  ('a0000000-0000-4000-8000-000000000028'::uuid, 'active'::public.ea_volunteer_status, date '2026-01-01'),
  ('a0000000-0000-4000-8000-000000000031'::uuid, 'active'::public.ea_volunteer_status, date '2024-01-01'),
  ('a0000000-0000-4000-8000-000000000032'::uuid, 'active'::public.ea_volunteer_status, date '2024-01-01')
), upd as (
  update public.ea_persons p
     set volunteer_status = v.status, volunteer_status_since = v.since
    from v
   where p.id = v.person_id and p.volunteer_status is null
  returning p.id, p.volunteer_status, p.volunteer_status_since
)
insert into public.ea_volunteer_status_history (person_id, status, valid_from)
select id, volunteer_status, volunteer_status_since from upd;

-- Personenangaben (Geburtsdatum, Kontaktdaten) und Amt von Kim
insert into public.ea_properties (id, person_id, property_type_id, field_values, related_referat_id, valid_from)
select v.id, v.person_id, t.id, v.field_values, (select r.id from public.ea_referate r where r.name = v.referat),
       coalesce(v.valid_from, (v.field_values ->> 'date')::date)
  from (values
    -- Mia Fiktiv (23): 12 Jahre
    ('e0000000-0000-4000-8000-000000000025'::uuid, 'a0000000-0000-4000-8000-000000000023'::uuid, 'birth_date'::text,
     jsonb_build_object('date', to_char(current_date - interval '12 years' + interval '10 days', 'YYYY-MM-DD')),
     null::text, null::date),
    ('e0000000-0000-4000-8000-000000000026', 'a0000000-0000-4000-8000-000000000023', 'contact',
     '{"street": "Testweg 1", "postal_code": "04109", "city": "Leipzig"}', null, date '2025-09-01'),
    -- Jana Fiktiv (24)
    ('e0000000-0000-4000-8000-000000000027', 'a0000000-0000-4000-8000-000000000024', 'contact',
     '{"street": "Testweg 1", "postal_code": "04109", "city": "Leipzig", "phone_mobile": "0151 0000024",
       "email": "jana.fiktiv@example.test"}', null, date '2025-01-15'),
    -- Ben Fiktiv (25): 9 Jahre
    ('e0000000-0000-4000-8000-000000000028', 'a0000000-0000-4000-8000-000000000025', 'birth_date',
     jsonb_build_object('date', to_char(current_date - interval '9 years', 'YYYY-MM-DD')), null, null),
    ('e0000000-0000-4000-8000-000000000029', 'a0000000-0000-4000-8000-000000000025', 'contact',
     '{"street": "Testweg 1", "postal_code": "04109", "city": "Leipzig"}', null, date '2025-01-15'),
    -- Lars Lehrer (26)
    ('e0000000-0000-4000-8000-000000000030', 'a0000000-0000-4000-8000-000000000026', 'contact',
     '{"street": "Beispielstraße 26", "postal_code": "04103", "city": "Leipzig", "email": "lars.lehrer@example.test"}',
     null, date '2025-09-01'),
    -- Lea Lehrer (27): 10 Jahre
    ('e0000000-0000-4000-8000-000000000031', 'a0000000-0000-4000-8000-000000000027', 'birth_date',
     jsonb_build_object('date', to_char(current_date - interval '10 years', 'YYYY-MM-DD')), null, null),
    ('e0000000-0000-4000-8000-000000000032', 'a0000000-0000-4000-8000-000000000027', 'contact',
     '{"street": "Beispielstraße 26", "postal_code": "04103", "city": "Leipzig"}', null, date '2025-09-01'),
    -- Sam Sechzehn (28): 16 Jahre
    ('e0000000-0000-4000-8000-000000000033', 'a0000000-0000-4000-8000-000000000028', 'birth_date',
     jsonb_build_object('date', to_char(current_date - interval '16 years' - interval '30 days', 'YYYY-MM-DD')), null, null),
    ('e0000000-0000-4000-8000-000000000034', 'a0000000-0000-4000-8000-000000000028', 'contact',
     '{"street": "Musterplatz 28", "postal_code": "04105", "city": "Leipzig", "phone_mobile": "0151 0000028"}',
     null, date '2025-01-15'),
    -- Erika Oma (29): nur Telefon mobil
    ('e0000000-0000-4000-8000-000000000035', 'a0000000-0000-4000-8000-000000000029', 'contact',
     '{"phone_mobile": "0151 0000029"}', null, date '2025-09-01'),
    -- Paula Plan (30): 8 Jahre
    ('e0000000-0000-4000-8000-000000000036', 'a0000000-0000-4000-8000-000000000030', 'birth_date',
     jsonb_build_object('date', to_char(current_date - interval '8 years', 'YYYY-MM-DD')), null, null),
    ('e0000000-0000-4000-8000-000000000037', 'a0000000-0000-4000-8000-000000000030', 'contact',
     '{"street": "Planweg 30", "postal_code": "04107", "city": "Leipzig"}', null, current_date),
    -- Kim Kinderjugend (32): Amt Referent:in Kinder und Jugend
    ('e0000000-0000-4000-8000-000000000038', 'a0000000-0000-4000-8000-000000000032', 'position',
     '{"position": "Referent:in"}', 'Kinder und Jugend', date '2024-01-01')
  ) as v (id, person_id, system_key, field_values, referat, valid_from)
  join public.ea_property_types t on t.system_key = v.system_key
on conflict (id) do nothing;

-- Funktionen in Gruppen
insert into public.ea_properties (id, person_id, property_type_id, field_values, related_group_id, valid_from, valid_to)
select v.id, v.person_id, t.id, v.field_values, v.group_id, v.valid_from, v.valid_to
  from (values
    -- Lars Lehrer (26): Trainer Test 1
    ('e0000000-0000-4000-8000-000000000039'::uuid, 'a0000000-0000-4000-8000-000000000026'::uuid,
     '{"function": "Trainer:in"}'::jsonb, 'c0000000-0000-4000-8000-000000000001'::uuid, date '2025-09-01', null::date),
    -- Sam Sechzehn (28): Helfer Test 1
    ('e0000000-0000-4000-8000-000000000040', 'a0000000-0000-4000-8000-000000000028',
     '{"function": "Helfer:in"}', 'c0000000-0000-4000-8000-000000000001', date '2026-01-01', null),
    -- Tom Ehemals (31): Trainer Test 2 bis vor 60 Tagen
    ('e0000000-0000-4000-8000-000000000041', 'a0000000-0000-4000-8000-000000000031',
     '{"function": "Trainer:in"}', 'c0000000-0000-4000-8000-000000000002', date '2024-01-01', current_date - 60)
  ) as v (id, person_id, field_values, group_id, valid_from, valid_to)
  join public.ea_property_types t on t.system_key = 'group_function'
on conflict (id) do nothing;

-- Erziehungsberechtigte und Notfallkontakte
insert into public.gr_guardians (child_person_id, guardian_person_id) values
  ('a0000000-0000-4000-8000-000000000023', 'a0000000-0000-4000-8000-000000000024'),
  ('a0000000-0000-4000-8000-000000000025', 'a0000000-0000-4000-8000-000000000024'),
  ('a0000000-0000-4000-8000-000000000027', 'a0000000-0000-4000-8000-000000000026'),
  ('a0000000-0000-4000-8000-000000000028', 'a0000000-0000-4000-8000-000000000024')
on conflict (child_person_id, guardian_person_id) do nothing;

insert into public.gr_emergency_contacts (child_person_id, contact_person_id, sort_order) values
  ('a0000000-0000-4000-8000-000000000023', 'a0000000-0000-4000-8000-000000000024', 1),
  ('a0000000-0000-4000-8000-000000000023', 'a0000000-0000-4000-8000-000000000029', 2)
on conflict (child_person_id, contact_person_id) do nothing;

-- Teilnahmen
insert into public.gr_memberships (id, group_id, person_id, joined_on, left_on) values
  ('c2000000-0000-4000-8000-000000000001', 'c0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000023', date '2025-09-01', null),
  ('c2000000-0000-4000-8000-000000000002', 'c0000000-0000-4000-8000-000000000003', 'a0000000-0000-4000-8000-000000000023', date '2026-01-01', null),
  ('c2000000-0000-4000-8000-000000000003', 'c0000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000025', date '2025-01-15', null),
  ('c2000000-0000-4000-8000-000000000004', 'c0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000027', date '2025-09-01', current_date - 30),
  ('c2000000-0000-4000-8000-000000000005', 'c0000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000028', date '2025-01-15', null)
on conflict (id) do nothing;

-- Verträge (Beispiel-IBAN, fiktive Mandatsreferenzen)
insert into public.gr_contracts (id, membership_id, holder_person_id, starts_on, cancelled_on, ends_on,
                                 account_holder, iban, mandate_reference, mandate_signed_on, purpose, monthly_amount) values
  ('c3000000-0000-4000-8000-000000000001', 'c2000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000024',
   date '2025-09-01', null, null, 'Jana Fiktiv', 'DE89370400440532013000', 'TEST-GR-23-1', date '2025-08-20',
   'Beitrag Jugendgruppe Test 1 Mia Fiktiv', 25.00),
  ('c3000000-0000-4000-8000-000000000002', 'c2000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000024',
   date '2026-01-01', null, null, 'Jana Fiktiv', 'DE89370400440532013000', 'TEST-GR-23-2', date '2025-12-15',
   'Beitrag Klettergruppe Test Mia Fiktiv', 30.00),
  ('c3000000-0000-4000-8000-000000000003', 'c2000000-0000-4000-8000-000000000003', 'a0000000-0000-4000-8000-000000000024',
   date '2025-01-15', current_date - 40, current_date - 10, 'Jana Fiktiv', 'DE89370400440532013000', 'TEST-GR-25-1',
   date '2025-01-10', 'Beitrag Jugendgruppe Test 2 Ben Fiktiv', 25.00),
  ('c3000000-0000-4000-8000-000000000004', 'c2000000-0000-4000-8000-000000000004', 'a0000000-0000-4000-8000-000000000026',
   date '2025-09-01', current_date - 60, current_date - 30, 'Lars Lehrer', 'DE89370400440532013000', 'TEST-GR-27-1',
   date '2025-08-25', 'Beitrag Jugendgruppe Test 1 Lea Lehrer', 25.00),
  ('c3000000-0000-4000-8000-000000000005', 'c2000000-0000-4000-8000-000000000005', 'a0000000-0000-4000-8000-000000000024',
   date '2025-01-15', null, null, 'Jana Fiktiv', 'DE89370400440532013000', 'TEST-GR-28-1', date '2025-01-10',
   'Beitrag Jugendgruppe Test 2 Sam Sechzehn', 25.00)
on conflict (id) do nothing;

-- Offene Aufnahme: Paula Plan (30) in Test 2
insert into public.gr_pending_admissions (person_id, group_id) values
  ('a0000000-0000-4000-8000-000000000030', 'c0000000-0000-4000-8000-000000000002')
on conflict (person_id) do nothing;

-- Fotoerlaubnis, Einwilligung, Gesundheitsangaben (Ben: Widerruf nach „ja“, Text bleibt gespeichert)
insert into public.gr_photo_consents (person_id, granted, effective_on)
select 'a0000000-0000-4000-8000-000000000023', true, date '2025-09-01'
 where not exists (select 1 from public.gr_photo_consents where person_id = 'a0000000-0000-4000-8000-000000000023');

insert into public.gr_health_consents (person_id, granted, effective_on)
select v.person_id, v.granted, v.effective_on
  from (values
    ('a0000000-0000-4000-8000-000000000023'::uuid, true, date '2025-09-01'),
    ('a0000000-0000-4000-8000-000000000025'::uuid, true, date '2025-01-15'),
    ('a0000000-0000-4000-8000-000000000025'::uuid, false, current_date - 5)
  ) as v (person_id, granted, effective_on)
 where not exists (select 1 from public.gr_health_consents c where c.person_id = v.person_id);

insert into public.gr_health_notes (person_id, note) values
  ('a0000000-0000-4000-8000-000000000023', 'Asthma (fiktiv), Spray im Rucksack.'),
  ('a0000000-0000-4000-8000-000000000025', 'Allergie gegen Testpollen (fiktiv).')
on conflict (person_id) do nothing;

-- Testzugang Kim Kinderjugend: Vorlage Referent:in, Referat Kinder und Jugend (EZ-Rechte folgen mit AD v0.8, plan.md O2)
insert into public.ad_accesses (person_id, login_email, status, is_emergency, last_invited_at, locked_at) values
  ('a0000000-0000-4000-8000-000000000032', 'test.kiju@dav-leipzig.de', 'active', false, now() - interval '30 days', null)
on conflict (person_id) do nothing;

insert into public.ad_template_assignments (person_id, template_id)
select 'a0000000-0000-4000-8000-000000000032', t.id
  from public.ad_templates t
 where t.name = 'Referent:in'
   and not exists (
     select 1 from public.ad_template_assignments ta
      where ta.person_id = 'a0000000-0000-4000-8000-000000000032' and ta.template_id = t.id and ta.revoked_at is null
   );

insert into public.ad_assignment_referate (assignment_id, referat_id)
select ta.id, r.id
  from public.ad_template_assignments ta
  join public.ad_templates t on t.id = ta.template_id and t.name = 'Referent:in'
  join public.ea_referate r on r.name = 'Kinder und Jugend'
 where ta.person_id = 'a0000000-0000-4000-8000-000000000032' and ta.revoked_at is null
on conflict do nothing;

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, invited_at, banned_until,
  raw_app_meta_data, raw_user_meta_data,
  confirmation_token, recovery_token, email_change_token_new, email_change,
  created_at, updated_at
)
values (
  '00000000-0000-0000-0000-000000000000', 'b0000000-0000-4000-8000-000000000032', 'authenticated', 'authenticated',
  'test.kiju@dav-leipzig.de', extensions.crypt(:'test_password', extensions.gen_salt('bf')),
  now(), now() - interval '30 days', null,
  '{"provider": "email", "providers": ["email"]}'::jsonb, '{}'::jsonb,
  '', '', '', '',
  now() - interval '30 days', now()
)
on conflict (id) do nothing;

insert into auth.identities (id, user_id, provider_id, provider, identity_data, last_sign_in_at, created_at, updated_at)
select gen_random_uuid(), u.id, u.id::text, 'email',
       jsonb_build_object('sub', u.id::text, 'email', u.email, 'email_verified', true),
       null, now(), now()
  from auth.users u
 where u.id = 'b0000000-0000-4000-8000-000000000032'
on conflict (provider_id, provider) do nothing;

-- Nachtrag v0.8 (spec.md AD v0.9.4, Abschnitt 9; spec T57): Testorte, solange es keinen Startbestand gibt.
-- Die Testzugänge erhalten die EZ-Startwerte über ihre Vorlagen (Migration 20261026000100).
insert into public.ad_locations (id, name, has_climbing_points, is_active) values
  ('e1000000-0000-4000-8000-000000000001', 'Kletterhalle Test', true, true),
  ('e1000000-0000-4000-8000-000000000002', 'Fels Test', false, true),
  ('e1000000-0000-4000-8000-000000000003', 'Halle alt Test', false, false)
on conflict (id) do nothing;
