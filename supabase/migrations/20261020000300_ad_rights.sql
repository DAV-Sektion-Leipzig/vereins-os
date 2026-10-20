-- US-AD-01, spec T3: Rechtevorlagen, Rechte, Zuweisungen, Zugänge, Startvorlagen,
-- ad_my_modules, ad_assign_template, ad_revoke_template.
-- Das Protokoll (ad_audit_log) folgt in 20261020000400; plpgsql löst es erst zur Laufzeit auf.

-- Hilfstrigger: geändert am/von
create function public.ad_set_updated()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  new.updated_by := auth.uid();
  return new;
end;
$$;

revoke all on function public.ad_set_updated() from public, anon, authenticated;

-- Rechtevorlagen
create table public.ad_templates (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid() references auth.users (id) on delete set null,
  updated_at timestamptz,
  updated_by uuid references auth.users (id) on delete set null
);

comment on table public.ad_templates is 'Rechtevorlage; Rechte je Modul in ad_template_rights.';

create unique index ad_templates_name_key on public.ad_templates (lower(name));

create trigger ad_templates_set_updated
  before update on public.ad_templates
  for each row execute function public.ad_set_updated();

-- Rechte je Vorlage und Modul
create table public.ad_template_rights (
  id uuid primary key default gen_random_uuid(),
  template_id uuid not null references public.ad_templates (id) on delete cascade,
  module_code text not null references public.ad_modules (code),
  object text,
  scope text not null default 'all',
  level public.ad_level not null default 'none',
  constraint ad_template_rights_object_mvp check (object is null),
  constraint ad_template_rights_scope_mvp check (scope = 'all')
);

create unique index ad_template_rights_key
  on public.ad_template_rights (template_id, module_code, coalesce(object, ''));

-- Je Vorlage für jedes Modul eine Zeile
create function public.ad_templates_init_rights()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.ad_template_rights (template_id, module_code)
  select new.id, m.code from public.ad_modules m
  on conflict do nothing;
  return new;
end;
$$;

revoke all on function public.ad_templates_init_rights() from public, anon, authenticated;

create trigger ad_templates_init_rights
  after insert on public.ad_templates
  for each row execute function public.ad_templates_init_rights();

-- Zuweisungen (Befristung nur im Datenmodell)
create table public.ad_template_assignments (
  id uuid primary key default gen_random_uuid(),
  person_id uuid not null references public.ea_persons (id),
  template_id uuid not null references public.ad_templates (id),
  valid_from date,
  valid_to date,
  assigned_at timestamptz not null default now(),
  assigned_by uuid default auth.uid() references auth.users (id) on delete set null,
  revoked_at timestamptz,
  revoked_by uuid references auth.users (id) on delete set null
);

create unique index ad_template_assignments_active_key
  on public.ad_template_assignments (person_id, template_id)
  where revoked_at is null;

-- Zugänge
create table public.ad_accesses (
  id uuid primary key default gen_random_uuid(),
  person_id uuid not null references public.ea_persons (id),
  login_email extensions.citext not null,
  status public.ad_access_status not null default 'none',
  auth_user_id uuid references auth.users (id) on delete set null,
  is_emergency boolean not null default false,
  last_invited_at timestamptz,
  locked_at timestamptz,
  locked_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid() references auth.users (id) on delete set null,
  constraint ad_accesses_person_key unique (person_id),
  constraint ad_accesses_login_email_key unique (login_email),
  constraint ad_accesses_auth_user_key unique (auth_user_id)
);

comment on table public.ad_accesses is
  'Zugang einer Person; R1 per Trigger ad_accesses_guard (kein Check-Constraint), Statuswechsel nur über Edge Functions und Trigger.';

create unique index ad_accesses_one_emergency on public.ad_accesses (is_emergency) where is_emergency;

-- Startvorlagen (US-AD-01 AK1, R6)
insert into public.ad_templates (name, description) values
  ('Admin', 'Administration, Schnittstellen und Ehrenamtsmanagement verwalten'),
  ('Geschäftsstelle', 'Alle Fachmodule verwalten'),
  ('Vorstand', 'Ohne Rechte; Konfiguration durch den Admin')
on conflict do nothing;

update public.ad_template_rights r
   set level = 'manage'
  from public.ad_templates t
 where r.template_id = t.id
   and t.name = 'Admin'
   and r.module_code in ('AD', 'SC', 'EA');

update public.ad_template_rights r
   set level = 'manage'
  from public.ad_templates t
 where r.template_id = t.id
   and t.name = 'Geschäftsstelle'
   and r.module_code in ('EA', 'GR', 'FI', 'OA', 'PM', 'GS', 'AM');

-- Module für Startseite und Navigation
create function public.ad_my_modules()
returns table (code text, name text, level public.ad_level)
language sql
stable
security definer
set search_path = ''
as $$
  select m.code, m.name, public.ad_user_level(m.code)
    from public.ad_modules m
   where m.is_available
     and public.ad_user_level(m.code) >= 'read'
   order by m.sort_order;
$$;

-- Vorlage zuweisen (R13, US-AD-11)
create function public.ad_assign_template(p_person uuid, p_template uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_name text;
begin
  if not public.ad_has_level('AD', 'edit') then
    raise exception 'AD_FORBIDDEN' using errcode = 'P0001';
  end if;

  select t.name into v_name from public.ad_templates t where t.id = p_template;

  if exists (
    select 1 from public.ad_template_assignments ta
     where ta.person_id = p_person and ta.template_id = p_template and ta.revoked_at is null
  ) then
    return;
  end if;

  insert into public.ad_template_assignments (person_id, template_id)
  values (p_person, p_template);

  insert into public.ad_audit_log (subject_person_id, action, details)
  values (p_person, 'template_assigned', v_name);
end;
$$;

-- Vorlage entziehen (R13, US-AD-11)
create function public.ad_revoke_template(p_person uuid, p_template uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_name text;
begin
  if not public.ad_has_level('AD', 'edit') then
    raise exception 'AD_FORBIDDEN' using errcode = 'P0001';
  end if;

  update public.ad_template_assignments ta
     set revoked_at = now(), revoked_by = auth.uid()
   where ta.person_id = p_person and ta.template_id = p_template and ta.revoked_at is null;

  if found then
    select t.name into v_name from public.ad_templates t where t.id = p_template;
    insert into public.ad_audit_log (subject_person_id, action, details)
    values (p_person, 'template_revoked', v_name);
  end if;
end;
$$;

revoke all on function public.ad_my_modules() from public, anon, authenticated;
revoke all on function public.ad_assign_template(uuid, uuid) from public, anon, authenticated;
revoke all on function public.ad_revoke_template(uuid, uuid) from public, anon, authenticated;
grant execute on function public.ad_my_modules() to authenticated;
grant execute on function public.ad_assign_template(uuid, uuid) to authenticated;
grant execute on function public.ad_revoke_template(uuid, uuid) to authenticated;

-- RLS und Grants
alter table public.ad_templates enable row level security;
alter table public.ad_template_rights enable row level security;
alter table public.ad_template_assignments enable row level security;
alter table public.ad_accesses enable row level security;

revoke all on table public.ad_templates, public.ad_template_rights,
  public.ad_template_assignments, public.ad_accesses from public, anon, authenticated;

grant select on table public.ad_templates to authenticated;
grant insert (name, description), update (name, description) on table public.ad_templates to authenticated;

grant select on table public.ad_template_rights to authenticated;
grant update (level) on table public.ad_template_rights to authenticated;

grant select on table public.ad_template_assignments to authenticated;

grant select on table public.ad_accesses to authenticated;
grant insert (person_id, login_email), update (login_email) on table public.ad_accesses to authenticated;

create policy ad_templates_select on public.ad_templates
  for select to authenticated using (public.ad_has_level('AD', 'read'));
create policy ad_templates_insert on public.ad_templates
  for insert to authenticated with check (public.ad_has_level('AD', 'edit'));
create policy ad_templates_update on public.ad_templates
  for update to authenticated
  using (public.ad_has_level('AD', 'edit')) with check (public.ad_has_level('AD', 'edit'));

create policy ad_template_rights_select on public.ad_template_rights
  for select to authenticated using (public.ad_has_level('AD', 'read'));
create policy ad_template_rights_update on public.ad_template_rights
  for update to authenticated
  using (public.ad_has_level('AD', 'edit')) with check (public.ad_has_level('AD', 'edit'));

create policy ad_template_assignments_select on public.ad_template_assignments
  for select to authenticated using (public.ad_has_level('AD', 'read'));

create policy ad_accesses_select on public.ad_accesses
  for select to authenticated using (public.ad_has_level('AD', 'read'));
create policy ad_accesses_insert on public.ad_accesses
  for insert to authenticated with check (public.ad_has_level('AD', 'edit'));
create policy ad_accesses_update on public.ad_accesses
  for update to authenticated
  using (public.ad_has_level('AD', 'edit')) with check (public.ad_has_level('AD', 'edit'));
