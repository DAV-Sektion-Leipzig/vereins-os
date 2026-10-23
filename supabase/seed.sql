-- Testdaten nach spec.md AD Abschnitt 9 – nur fiktive Personen und Adressen (die Adressen existieren nicht).
-- Nur über supabase/seed.sh ausführen (psql-Variable test_password; Abbruch bei PROD).
-- Idempotent; feste UUIDs, auf die sich die pgTAP-Tests beziehen:
--   Personen a…01–a…12, Auth-Nutzer b…01 (Admin), b…02 (Geschäftsstelle), b…03 (Vorstand),
--   b…06 (eingeladen), b…07 (gesperrt), b…08 (Notfall-Admin), b…09 (Referent:in, Referat Klettern).
-- Personen 1–12 (Kern bis v0.7.1) und 19–22 (EA spec.md Abschnitt 9); 13–18, Orte und Sätze folgen mit den
-- Nachträgen v0.8/v0.9 der Administration.
-- Läuft ohne Nutzerkontext: Ehrenamtsstatus und historische Qualifikationsarten sind dadurch setzbar.
--   Testarten d…02 (T-Shirt-Größe) und d…03 (Erste-Hilfe-Kurs am); alle übrigen Eigenschaften verweisen auf die
--   System-Eigenschaftsarten der Migration 20261023002100 (Auflösung über system_key, Ü3 nach
--   docs/specs/ea-ehrenamt/uebergabe-administration.md). Eigenschaften e…01–e…24.
--   Datumswerte der Personen 19–22 relativ zu current_date (EA spec.md Abschnitt 9).

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

insert into public.ea_property_fields
  (property_type_id, key, label, data_type, is_required, choice_values, allowed_qualification_kinds, sort_order)
values
  ('d0000000-0000-4000-8000-000000000002', 'size', 'Größe', 'choice', true, '{S,M,L,XL}', null, 1),
  ('d0000000-0000-4000-8000-000000000003', 'date', 'Datum', 'date', true, null, null, 1)
on conflict (property_type_id, key) do nothing;

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
