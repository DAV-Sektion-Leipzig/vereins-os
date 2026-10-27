-- Schnittstellen-Connector (spec.md SC v0.2), Task T1 und T2 (Datenbankteil): Typen, Tabellen, RLS, Spaltenrechte,
-- Startwert Geschäftsstelle SC lesen, Anlässe des SC. Schreiben nur über Funktionen (spätere Migrationen).
-- ad_modules.is_available für SC setzt die Oberfläche mit ihrer Freigabe (wie DS, TK).

create extension if not exists pg_net;

-- 2.1 Typen
create type public.sc_connection_kind as enum ('email_brevo');
create type public.sc_connection_state as enum ('disabled', 'active', 'disturbed', 'expired');
create type public.sc_outbox_state as enum ('waiting', 'sent', 'failed', 'discarded');
create type public.sc_log_kind as enum (
  'connection_created', 'connection_changed', 'key_changed', 'state_changed', 'modules_changed', 'template_changed',
  'test', 'send', 'enqueue_rejected', 'retry', 'discard', 'limit_reached'
);
create type public.sc_log_result as enum ('ok', 'error', 'rejected');

grant usage on type public.sc_connection_kind, public.sc_connection_state, public.sc_outbox_state,
  public.sc_log_kind, public.sc_log_result to authenticated, service_role;

-- 2.2 Anbindung
create table public.sc_connections (
  id uuid primary key default gen_random_uuid(),
  kind public.sc_connection_kind not null,
  name text not null,
  state public.sc_connection_state not null default 'disabled',
  sender_email extensions.citext not null,
  sender_name text not null default 'Vereins OS',
  key_last4 text,
  key_expires_on date,
  key_changed_at timestamptz,
  key_changed_by uuid,
  config_changed_at timestamptz not null default now(),
  last_test_ok_at timestamptz,
  last_success_at timestamptz,
  last_error_at timestamptz,
  last_error text,
  consecutive_failures int not null default 0,
  hourly_limit int not null default 100,
  daily_limit int not null default 300,
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid(),
  constraint sc_connections_name_key unique (name),
  constraint sc_connections_name_length check (char_length(btrim(name)) between 1 and 80),
  constraint sc_connections_sender_name_length check (char_length(btrim(sender_name)) between 1 and 80),
  constraint sc_connections_sender_email_format check (sender_email::text ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  constraint sc_connections_hourly_limit check (hourly_limit between 1 and 100),
  constraint sc_connections_daily_limit check (daily_limit between 1 and 300),
  constraint sc_connections_failures check (consecutive_failures >= 0)
);

comment on table public.sc_connections is
  'Anbindung an einen Dienst (spec.md SC 2.2). Der API-Key liegt nur in Vault (Name sc_connection_<id>), hier nur key_last4.';

-- R4: je Art höchstens eine aktive Anbindung
create unique index sc_connections_one_active on public.sc_connections (kind) where state = 'active';

-- Freigabe je Modul (R2)
create table public.sc_connection_modules (
  connection_id uuid not null references public.sc_connections (id),
  module_code text not null references public.ad_modules (code),
  granted_at timestamptz not null default now(),
  granted_by uuid default auth.uid(),
  primary key (connection_id, module_code)
);

-- Anlass mit Vorlage (R8, R9)
create table public.sc_mail_occasions (
  code text primary key,
  module_code text not null references public.ad_modules (code),
  name text not null,
  description text not null,
  placeholders text[] not null default '{}',
  link_path text not null default '/',
  subject text not null,
  body text not null,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  constraint sc_mail_occasions_code_format check (code ~ '^[a-z][a-z0-9_]{2,59}$'),
  constraint sc_mail_occasions_subject_length check (char_length(btrim(subject)) between 1 and 150),
  constraint sc_mail_occasions_body_length check (char_length(btrim(body)) between 1 and 2000),
  constraint sc_mail_occasions_link_path check (link_path ~ '^/')
);

comment on column public.sc_mail_occasions.link_path is
  'Pfad für den Platzhalter {link}; SC setzt die Adresse der Umgebung (Vault sc_app_url) davor (spec.md SC A6).';

-- Postausgang
create table public.sc_outbox (
  id uuid primary key default gen_random_uuid(),
  occasion_code text not null references public.sc_mail_occasions (code),
  module_code text not null references public.ad_modules (code),
  recipient_person_id uuid not null references public.ea_persons (id),
  recipient_email extensions.citext not null,
  subject text not null,
  body text not null,
  dedupe_key text not null,
  state public.sc_outbox_state not null default 'waiting',
  attempts int not null default 0,
  next_attempt_at timestamptz not null default now(),
  claimed_until timestamptz,
  last_error text,
  connection_id uuid references public.sc_connections (id),
  provider_message_id text,
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid(),
  sent_at timestamptz,
  state_changed_at timestamptz not null default now(),
  constraint sc_outbox_attempts check (attempts between 0 and 3)
);

-- R10: kein Doppelversand
create unique index sc_outbox_dedupe on public.sc_outbox (dedupe_key) where state <> 'discarded';
create index sc_outbox_due on public.sc_outbox (state, next_attempt_at);
create index sc_outbox_state_changed on public.sc_outbox (state_changed_at);
create index sc_outbox_created on public.sc_outbox (created_at desc);
create index sc_outbox_sent on public.sc_outbox (connection_id, sent_at) where state = 'sent';

-- Protokoll (R15)
create table public.sc_log (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  connection_id uuid references public.sc_connections (id),
  module_code text,
  actor_user_id uuid,
  kind public.sc_log_kind not null,
  result public.sc_log_result not null,
  message text,
  outbox_id uuid,
  constraint sc_log_message_length check (message is null or char_length(message) <= 300)
);

create index sc_log_created on public.sc_log (created_at desc);

-- 3. RLS: lesen mit SC ≥ lesen; Schreiben nur über Funktionen
alter table public.sc_connections enable row level security;
alter table public.sc_connection_modules enable row level security;
alter table public.sc_mail_occasions enable row level security;
alter table public.sc_outbox enable row level security;
alter table public.sc_log enable row level security;

create policy sc_connections_select on public.sc_connections
  for select to authenticated using (public.ad_has_level('SC', 'read'));
create policy sc_connection_modules_select on public.sc_connection_modules
  for select to authenticated using (public.ad_has_level('SC', 'read'));
create policy sc_mail_occasions_select on public.sc_mail_occasions
  for select to authenticated using (public.ad_has_level('SC', 'read'));
create policy sc_outbox_select on public.sc_outbox
  for select to authenticated using (public.ad_has_level('SC', 'read'));
create policy sc_log_select on public.sc_log
  for select to authenticated using (public.ad_has_level('SC', 'read'));

revoke all on public.sc_connections, public.sc_connection_modules, public.sc_mail_occasions, public.sc_outbox,
  public.sc_log from anon, authenticated;

grant select on public.sc_connections, public.sc_connection_modules, public.sc_log to authenticated;
-- Spaltenrechte: Betreff und Text nur über Funktionen mit SC ≥ bearbeiten (Erhebung E1)
grant select (code, module_code, name, description, placeholders, link_path, updated_at, updated_by)
  on public.sc_mail_occasions to authenticated;
grant select (id, occasion_code, module_code, recipient_person_id, recipient_email, dedupe_key, state, attempts,
  next_attempt_at, last_error, connection_id, created_at, created_by, sent_at, state_changed_at)
  on public.sc_outbox to authenticated;

-- Startwert Geschäftsstelle SC lesen (Erhebung E1); überschreibt keine Änderungen des Admins
update public.ad_template_rights r
   set level = 'read'
  from public.ad_templates t
 where r.template_id = t.id
   and t.name = 'Geschäftsstelle'
   and r.module_code = 'SC'
   and r.object is null
   and r.level = 'none'
   and r.scope = 'all';

-- Modulname in der Oberfläche (Q-SC1)
update public.ad_modules set name = 'Schnittstellen' where code = 'SC';

-- Anlässe des SC (Starttexte; Texte des Admins bleiben bei erneutem Lauf erhalten)
insert into public.sc_mail_occasions (code, module_code, name, description, placeholders, link_path, subject, body)
values
  ('sc_test', 'SC', 'Test-E-Mail',
   'Kommt, wenn der Admin auf der Seite „Schnittstellen“ eine Test-E-Mail sendet.',
   '{link}', '/schnittstellen',
   'Vereins OS: Test-E-Mail',
   e'Hallo,\n\ndiese Test-E-Mail zeigt, dass der E-Mail-Versand des Vereins OS funktioniert.\n\nZu den Schnittstellen: {link}\n\nDiese E-Mail wurde automatisch versendet. Bitte antworte nicht darauf.'),
  ('sc_key_expiry', 'SC', 'Ablauf eines API-Keys',
   'Kommt 30 und 7 Tage vor dem Ablaufdatum eines API-Keys an alle mit „Schnittstellen verwalten“.',
   '{anbindung,ablaufdatum,tage,link}', '/schnittstellen',
   'Vereins OS: API-Key läuft in {tage} Tagen ab',
   e'Hallo,\n\nder API-Key der Anbindung „{anbindung}“ läuft am {ablaufdatum} ab. Bitte hinterlege rechtzeitig einen neuen Key.\n\nZu den Schnittstellen: {link}\n\nDiese E-Mail wurde automatisch versendet. Bitte antworte nicht darauf.')
on conflict (code) do nothing;
