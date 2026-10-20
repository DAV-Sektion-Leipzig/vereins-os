-- Testdaten nach spec.md AD Abschnitt 9 – nur fiktive Personen und Adressen (die Adressen existieren nicht).
-- Nur über supabase/seed.sh ausführen (psql-Variable test_password; Abbruch bei PROD).
-- Idempotent; feste UUIDs, auf die sich die pgTAP-Tests beziehen:
--   Personen a…01–a…08, Auth-Nutzer b…01 (Admin), b…02 (Geschäftsstelle), b…03 (Vorstand),
--   b…06 (eingeladen), b…07 (gesperrt), b…08 (Notfall-Admin).
-- Eigenschaftsarten und Eigenschaften folgen mit US-AD-13.

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

-- 2. Zugänge mit Zielstatus (vor auth.users, damit der Insert-Trigger nur auth_user_id setzt)
insert into public.ad_accesses (person_id, login_email, status, is_emergency, last_invited_at, locked_at) values
  ('a0000000-0000-4000-8000-000000000001', 'test.admin@dav-leipzig.de', 'active', false, now() - interval '30 days', null),
  ('a0000000-0000-4000-8000-000000000002', 'test.geschaeftsstelle@dav-leipzig.de', 'active', false, now() - interval '30 days', null),
  ('a0000000-0000-4000-8000-000000000003', 'test.vorstand@dav-leipzig.de', 'active', false, now() - interval '30 days', null),
  ('a0000000-0000-4000-8000-000000000006', 'test.eingeladen@dav-leipzig.de', 'invited', false, now() - interval '2 days', null),
  ('a0000000-0000-4000-8000-000000000007', 'test.gesperrt@dav-leipzig.de', 'locked', false, now() - interval '400 days', now() - interval '10 days'),
  ('a0000000-0000-4000-8000-000000000008', 'test.notfall@dav-leipzig.de', 'active', true, now() - interval '30 days', null)
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
    ('a0000000-0000-4000-8000-000000000008'::uuid, 'Admin')
  ) as v (person_id, template_name)
  join public.ad_templates t on t.name = v.template_name
 where not exists (
   select 1 from public.ad_template_assignments ta
    where ta.person_id = v.person_id and ta.template_id = t.id and ta.revoked_at is null
 );

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
  ('b0000000-0000-4000-8000-000000000008'::uuid, 'test.notfall@dav-leipzig.de', true, false)
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
   'b0000000-0000-4000-8000-000000000007', 'b0000000-0000-4000-8000-000000000008'
 )
on conflict (provider_id, provider) do nothing;

-- Gesperrt am/von (durch den Test-Admin)
update public.ad_accesses
   set locked_by = 'b0000000-0000-4000-8000-000000000001'
 where person_id = 'a0000000-0000-4000-8000-000000000007' and locked_by is null;

-- 5. Protokoll: je ein Eintrag invited, template_assigned, locked, emergency_login
insert into public.ad_audit_log (occurred_at, actor_user_id, subject_person_id, action, details)
select v.occurred_at, v.actor, v.subject, v.action::public.ad_audit_action, v.details
  from (values
    (now() - interval '2 days', 'b0000000-0000-4000-8000-000000000001'::uuid,
     'a0000000-0000-4000-8000-000000000006'::uuid, 'invited', null::text),
    (now() - interval '30 days', 'b0000000-0000-4000-8000-000000000001'::uuid,
     'a0000000-0000-4000-8000-000000000002'::uuid, 'template_assigned', 'Geschäftsstelle'),
    (now() - interval '10 days', 'b0000000-0000-4000-8000-000000000001'::uuid,
     'a0000000-0000-4000-8000-000000000007'::uuid, 'locked', null),
    (now() - interval '1 day', 'b0000000-0000-4000-8000-000000000008'::uuid,
     'a0000000-0000-4000-8000-000000000008'::uuid, 'emergency_login', null)
  ) as v (occurred_at, actor, subject, action, details)
 where not exists (
   select 1 from public.ad_audit_log l
    where l.subject_person_id = v.subject and l.action = v.action::public.ad_audit_action
 );
