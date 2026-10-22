-- Testdaten nach spec.md AD Abschnitt 9 – nur fiktive Personen und Adressen (die Adressen existieren nicht).
-- Nur über supabase/seed.sh ausführen (psql-Variable test_password; Abbruch bei PROD).
-- Idempotent; feste UUIDs, auf die sich die pgTAP-Tests beziehen:
--   Personen a…01–a…12, Auth-Nutzer b…01 (Admin), b…02 (Geschäftsstelle), b…03 (Vorstand),
--   b…06 (eingeladen), b…07 (gesperrt), b…08 (Notfall-Admin), b…09 (Referent:in, Referat Klettern).
-- Nur Personen 1–12 (Kern bis v0.7.1); Personen 13–18, Orte und Sätze folgen mit den Nachträgen v0.8/v0.9.
-- Läuft ohne Nutzerkontext: Ehrenamtsstatus und historische Qualifikationsarten sind dadurch setzbar.
--   Testarten d…01–d…08, Eigenschaften e…01–e…14 (spec.md Abschnitt 9, Feldschlüssel nach EA 01-erhebung.md C2).
-- Testarten mit system_key (birth_date, contact) gelten nur bis zur ersten EA-Migration (spec v0.7.2, Ü3).

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
  ('a0000000-0000-4000-8000-000000000012', 'Paul', 'Nurgruppe', 'human', 'GR')
on conflict (id) do nothing;

-- Ehrenamtsstatus mit Historie (spec.md Abschnitt 9)
with v (person_id, status, since) as (values
  ('a0000000-0000-4000-8000-000000000004'::uuid, 'active'::public.ea_volunteer_status, date '2025-03-01'),
  ('a0000000-0000-4000-8000-000000000005'::uuid, 'dormant'::public.ea_volunteer_status, date '2026-01-01'),
  ('a0000000-0000-4000-8000-000000000009'::uuid, 'active'::public.ea_volunteer_status, date '2024-01-01'),
  ('a0000000-0000-4000-8000-000000000010'::uuid, 'active'::public.ea_volunteer_status, date '2023-01-01'),
  ('a0000000-0000-4000-8000-000000000011'::uuid, 'left'::public.ea_volunteer_status, date '2025-06-30')
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

-- 6. Testarten (Eigenschaftsarten mit Feldern) nach spec.md Abschnitt 9
insert into public.ea_property_types
  (id, name, purpose, category, read_level, relation_kind, relation_required, allow_multiple, system_key, visible_in)
values
  ('d0000000-0000-4000-8000-000000000001', 'Hauptamt', 'Zuordnung der hauptamtlich Beschäftigten',
   'other', 'confidential', 'none', false, true, null, '{AD}'),
  ('d0000000-0000-4000-8000-000000000002', 'T-Shirt-Größe', 'Bestellung von Vereinskleidung',
   'issue', 'all', 'none', false, false, null, '{EA}'),
  ('d0000000-0000-4000-8000-000000000003', 'Erste-Hilfe-Kurs am', 'Nachweis für Tätigkeiten mit Gruppen',
   'qualification', 'all', 'none', false, true, null, '{EA}'),
  ('d0000000-0000-4000-8000-000000000004', 'Lizenz (Test)', 'Nachweis der Trainerlizenz',
   'qualification', 'all', 'none', false, true, null, '{AD,EA}'),
  ('d0000000-0000-4000-8000-000000000005', 'Funktion (Test)', 'Zuordnung zu Referaten',
   'assignment', 'all', 'referat', true, true, null, '{AD,EA}'),
  ('d0000000-0000-4000-8000-000000000006', 'Amt (Test)', 'Gewählte Verantwortung für ein Referat',
   'assignment', 'all', 'referat', true, true, null, '{AD,EA}'),
  ('d0000000-0000-4000-8000-000000000007', 'Geburtsdatum (Test)', 'Lizenzanträge',
   'master_data', 'office', 'none', false, false, 'birth_date', '{AD,EA,GR}'),
  ('d0000000-0000-4000-8000-000000000008', 'Kontaktdaten (Test)', 'Erreichbarkeit',
   'contact', 'all', 'none', false, true, 'contact', '{AD,EA,GR}')
on conflict (id) do nothing;

insert into public.ea_property_fields
  (property_type_id, key, label, data_type, is_required, choice_values, allowed_qualification_kinds, sort_order)
values
  ('d0000000-0000-4000-8000-000000000001', 'title', 'Bezeichnung', 'text', true, null, null, 1),
  ('d0000000-0000-4000-8000-000000000002', 'size', 'Größe', 'choice', true, '{S,M,L,XL}', null, 1),
  ('d0000000-0000-4000-8000-000000000003', 'date', 'Datum', 'date', true, null, null, 1),
  ('d0000000-0000-4000-8000-000000000004', 'qualification_type', 'Qualifikationsart', 'qualification_type', true,
   null, '{license}', 1),
  ('d0000000-0000-4000-8000-000000000004', 'license_number', 'Lizenznummer', 'text', false, null, null, 2),
  ('d0000000-0000-4000-8000-000000000004', 'valid_until', 'gültig bis', 'date', false, null, null, 3),
  ('d0000000-0000-4000-8000-000000000005', 'function', 'Funktion', 'choice', true, '{Trainer:in,Helfer:in}', null, 1),
  ('d0000000-0000-4000-8000-000000000006', 'position', 'Amt', 'choice', true, '{Referent:in,Hüttenwart:in}', null, 1),
  ('d0000000-0000-4000-8000-000000000007', 'date', 'Geburtsdatum', 'date', true, null, null, 1),
  ('d0000000-0000-4000-8000-000000000008', 'email', 'E-Mail', 'text', false, null, null, 1),
  ('d0000000-0000-4000-8000-000000000008', 'phone_mobile', 'Telefon mobil', 'text', false, null, null, 2)
on conflict (property_type_id, key) do nothing;

-- 7. Eigenschaften (ohne Nutzerkontext: historische Qualifikationsart von Person 5 erlaubt, R27)
insert into public.ea_properties
  (id, person_id, property_type_id, field_values, related_referat_id, valid_from, valid_to)
select v.id, v.person_id, v.type_id, v.field_values,
       (select r.id from public.ea_referate r where r.name = v.referat), v.valid_from, v.valid_to
  from (values
    -- Anna Fiktiv: Hauptamt (vertraulich)
    ('e0000000-0000-4000-8000-000000000001'::uuid, 'a0000000-0000-4000-8000-000000000002'::uuid,
     'd0000000-0000-4000-8000-000000000001'::uuid, '{"title": "Mitarbeiterin Geschäftsstelle"}'::jsonb,
     null::text, date '2024-03-01', null::date),
    -- Toni Muster
    ('e0000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000004',
     'd0000000-0000-4000-8000-000000000005', '{"function": "Trainer:in"}', 'Klettern', date '2025-03-01', null),
    ('e0000000-0000-4000-8000-000000000003', 'a0000000-0000-4000-8000-000000000004',
     'd0000000-0000-4000-8000-000000000004',
     jsonb_build_object('qualification_type', (select id from public.ad_qualification_types where code = 'TCSPI'),
                        'license_number', 'TEST-0001', 'valid_until', '2027-12-31'),
     null, date '2025-03-01', null),
    ('e0000000-0000-4000-8000-000000000004', 'a0000000-0000-4000-8000-000000000004',
     'd0000000-0000-4000-8000-000000000002', '{"size": "M"}', null, date '2025-01-01', null),
    ('e0000000-0000-4000-8000-000000000005', 'a0000000-0000-4000-8000-000000000004',
     'd0000000-0000-4000-8000-000000000007', '{"date": "1990-05-12"}', null, date '1990-05-12', null),
    -- Anton Muster (Dublettenpaar zu 4)
    ('e0000000-0000-4000-8000-000000000006', 'a0000000-0000-4000-8000-000000000005',
     'd0000000-0000-4000-8000-000000000005', '{"function": "Trainer:in"}', 'Ausbildung', date '2016-05-01', null),
    ('e0000000-0000-4000-8000-000000000007', 'a0000000-0000-4000-8000-000000000005',
     'd0000000-0000-4000-8000-000000000004',
     jsonb_build_object('qualification_type', (select id from public.ad_qualification_types where code = 'TCSP'),
                        'valid_until', '2019-12-31'),
     null, date '2016-05-01', null),
    -- Dieter Gesperrt: Hauptamt beendet (vertraulich)
    ('e0000000-0000-4000-8000-000000000008', 'a0000000-0000-4000-8000-000000000007',
     'd0000000-0000-4000-8000-000000000001', '{"title": "Mitarbeiter Geschäftsstelle"}', null,
     date '2020-01-01', date '2025-12-31'),
    -- Rita Referentin
    ('e0000000-0000-4000-8000-000000000009', 'a0000000-0000-4000-8000-000000000009',
     'd0000000-0000-4000-8000-000000000006', '{"position": "Referent:in"}', 'Klettern', date '2024-01-01', null),
    -- Karl Zweireferat
    ('e0000000-0000-4000-8000-000000000010', 'a0000000-0000-4000-8000-000000000010',
     'd0000000-0000-4000-8000-000000000005', '{"function": "Helfer:in"}', 'Klettern', date '2023-01-01', null),
    ('e0000000-0000-4000-8000-000000000011', 'a0000000-0000-4000-8000-000000000010',
     'd0000000-0000-4000-8000-000000000005', '{"function": "Trainer:in"}', 'Ausbildung', date '2023-01-01', null),
    ('e0000000-0000-4000-8000-000000000012', 'a0000000-0000-4000-8000-000000000010',
     'd0000000-0000-4000-8000-000000000007', '{"date": "1985-03-03"}', null, date '1985-03-03', null),
    -- Olga Ausgeschieden
    ('e0000000-0000-4000-8000-000000000013', 'a0000000-0000-4000-8000-000000000011',
     'd0000000-0000-4000-8000-000000000005', '{"function": "Trainer:in"}', 'Klettern', date '2020-01-01',
     date '2025-06-30'),
    -- Paul Nurgruppe (simuliert eine Person nur aus Gruppen)
    ('e0000000-0000-4000-8000-000000000014', 'a0000000-0000-4000-8000-000000000012',
     'd0000000-0000-4000-8000-000000000008', '{"email": "paul.nurgruppe@example.test"}', null, date '2025-01-01', null)
  ) as v (id, person_id, type_id, field_values, referat, valid_from, valid_to)
on conflict (id) do nothing;
