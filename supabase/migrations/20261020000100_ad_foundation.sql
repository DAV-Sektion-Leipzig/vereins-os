-- US-AD-01, spec T1: Grundlagen – Erweiterungen, Enums, Module, Rechtefunktionen.
-- ad_user_level/ad_has_level entstehen hier (spec.md v0.5 Abschnitt 2), damit jede folgende Tabelle
-- ihre Policies direkt mitbringt. plpgsql löst die Tabellen aus T3 erst zur Laufzeit auf.

-- Erweiterungen
create extension if not exists citext with schema extensions;
create extension if not exists pg_trgm with schema extensions;
create extension if not exists pg_cron with schema pg_catalog;

-- Typen
create type public.ad_level as enum ('none', 'read', 'edit', 'manage');
create type public.ad_access_status as enum ('none', 'invited', 'active', 'locked');
create type public.ea_data_type as enum ('text', 'date', 'boolean', 'choice');
create type public.ea_person_kind as enum ('human', 'function');
create type public.ad_audit_action as enum (
  'invited', 'email_changed', 'template_assigned', 'template_revoked', 'locked', 'unlocked', 'emergency_login'
);

revoke all on type public.ad_level, public.ad_access_status, public.ea_data_type,
  public.ea_person_kind, public.ad_audit_action from public, anon;
grant usage on type public.ad_level, public.ad_access_status, public.ea_data_type,
  public.ea_person_kind, public.ad_audit_action to authenticated, service_role;

-- Module
create table public.ad_modules (
  code text primary key,
  name text not null,
  sort_order int not null,
  is_available boolean not null default false
);

comment on table public.ad_modules is 'Module des Vereins OS; is_available = auf der Startseite sichtbar (MVP: nur AD).';

insert into public.ad_modules (code, name, sort_order, is_available) values
  ('AD', 'Administration', 1, true),
  ('SC', 'Schnittstellen-Connector', 2, false),
  ('EA', 'Ehrenamtsmanagement', 3, false),
  ('GR', 'Gruppen', 4, false),
  ('FI', 'Finanzen', 5, false),
  ('OA', 'Öffentlichkeitsarbeit', 6, false),
  ('PM', 'Projektmanagement', 7, false),
  ('GS', 'Geschäftsstellenmanagement', 8, false),
  ('AM', 'Aufgabenmanagement', 9, false);

alter table public.ad_modules enable row level security;
revoke all on table public.ad_modules from public, anon, authenticated;
grant select on table public.ad_modules to authenticated;

create policy ad_modules_select on public.ad_modules
  for select to authenticated using (true);

-- Rechte des aufrufenden Nutzers (R5, R6)
create function public.ad_user_level(p_module text)
returns public.ad_level
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_level public.ad_level;
begin
  select max(r.level)
    into v_level
    from public.ad_accesses a
    join public.ad_template_assignments ta on ta.person_id = a.person_id
    join public.ad_template_rights r on r.template_id = ta.template_id
   where a.auth_user_id = auth.uid()
     and a.status = 'active'
     and ta.revoked_at is null
     and (ta.valid_from is null or ta.valid_from <= current_date)
     and (ta.valid_to is null or ta.valid_to >= current_date)
     and r.module_code = p_module
     and r.object is null;

  return coalesce(v_level, 'none');
end;
$$;

create function public.ad_has_level(p_module text, p_min public.ad_level)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  return public.ad_user_level(p_module) >= p_min;
end;
$$;

revoke all on function public.ad_user_level(text) from public, anon, authenticated;
revoke all on function public.ad_has_level(text, public.ad_level) from public, anon, authenticated;
grant execute on function public.ad_user_level(text) to authenticated;
grant execute on function public.ad_has_level(text, public.ad_level) to authenticated;
