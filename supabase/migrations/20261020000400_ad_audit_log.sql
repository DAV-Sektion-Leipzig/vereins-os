-- US-AD-01, spec T4 (Teil): Protokoll. Einträge nur über security-definer-Funktionen und Trigger;
-- Löschlauf nach 5 Jahren folgt mit US-AD-14, Notfall-Hinweis mit US-AD-15.

create table public.ad_audit_log (
  id bigint generated always as identity primary key,
  occurred_at timestamptz not null default now(),
  -- ohne FK auf auth.users: das Löschen von Auth-Einträgen (ad-invite, change_email) darf
  -- nicht an Protokolleinträgen scheitern; das Protokoll bleibt vollständig
  actor_user_id uuid default auth.uid(),
  subject_person_id uuid not null references public.ea_persons (id),
  action public.ad_audit_action not null,
  details text
);

comment on table public.ad_audit_log is 'Protokoll nach R13/R16; für Nutzer nur lesbar (AD ≥ read), Aufbewahrung 5 Jahre.';

create index ad_audit_log_occurred_at on public.ad_audit_log (occurred_at desc);
create index ad_audit_log_action_occurred_at on public.ad_audit_log (action, occurred_at desc);

alter table public.ad_audit_log enable row level security;
revoke all on table public.ad_audit_log from public, anon, authenticated;
grant select on table public.ad_audit_log to authenticated;

create policy ad_audit_log_select on public.ad_audit_log
  for select to authenticated using (public.ad_has_level('AD', 'read'));
