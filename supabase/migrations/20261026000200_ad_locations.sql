-- Nachtrag v0.8 (spec.md AD v0.9.4, Nachtrag v0.8.1), spec T51; US-AD-27; Übergabe EZ A8; R43.
-- Stammdaten Orte. Kein Startbestand im Nachtrag (Product Owner 24.10.2026); in TEST nur Testorte aus dem Seed.
-- Pflege nur Admin (ad_can_edit_locations); lesen jeder Nutzer mit aktivem Zugang; kein Löschen.

create table public.ad_locations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  has_climbing_points boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid() references auth.users (id) on delete set null,
  updated_at timestamptz,
  updated_by uuid references auth.users (id) on delete set null,
  constraint ad_locations_name_not_blank check (btrim(name) <> '')
);

comment on table public.ad_locations is
  'Orte (Stammdaten, spec.md AD v0.8, R43); die Anwesenheitserfassung verweist mit Fremdschlüssel darauf. Nie löschen, nur inaktiv.';

create unique index ad_locations_name_key on public.ad_locations (lower(name));

-- R43 mit Fehlercodes vor Check und Unique-Index; updated_* bei Änderung
create function public.ad_locations_guard()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.name := btrim(coalesce(new.name, ''));
  if new.name = '' then
    raise exception 'AD_LOCATION_NAME_REQUIRED' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.ad_locations l where lower(l.name) = lower(new.name) and l.id <> new.id) then
    raise exception 'AD_LOCATION_NAME_TAKEN' using errcode = 'P0001';
  end if;
  if tg_op = 'UPDATE' then
    new.created_at := old.created_at;
    new.created_by := old.created_by;
    new.updated_at := now();
    new.updated_by := auth.uid();
  end if;
  return new;
end;
$$;

revoke all on function public.ad_locations_guard() from public, anon, authenticated;

create trigger ad_locations_guard
  before insert or update on public.ad_locations
  for each row execute function public.ad_locations_guard();

-- Pflege nur Admin (Product Owner 22.10.2026)
create function public.ad_can_edit_locations()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.ad_has_level('AD', 'edit');
$$;

revoke all on function public.ad_can_edit_locations() from public, anon, authenticated;
grant execute on function public.ad_can_edit_locations() to authenticated;

-- RLS: lesen mit aktivem Zugang; anlegen und ändern nur ad_can_edit_locations(); kein Delete
alter table public.ad_locations enable row level security;
revoke all on table public.ad_locations from public, anon, authenticated;
grant select on table public.ad_locations to authenticated;
grant insert (name, has_climbing_points, is_active),
      update (name, has_climbing_points, is_active)
  on table public.ad_locations to authenticated;

create policy ad_locations_select on public.ad_locations
  for select to authenticated using (public.ad_has_active_access());

create policy ad_locations_insert on public.ad_locations
  for insert to authenticated with check (public.ad_can_edit_locations());

create policy ad_locations_update on public.ad_locations
  for update to authenticated
  using (public.ad_can_edit_locations())
  with check (public.ad_can_edit_locations());
