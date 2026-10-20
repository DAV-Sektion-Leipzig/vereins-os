-- US-AD-01, spec T2 (Teil): Person und View für die Fachmodule.
-- Eigenschaftsarten und Eigenschaften folgen mit US-AD-12 und US-AD-13.

create table public.ea_persons (
  id uuid primary key default gen_random_uuid(),
  first_name text not null,
  last_name text not null,
  kind public.ea_person_kind not null default 'human',
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid() references auth.users (id) on delete set null,
  constraint ea_persons_first_name_not_blank check (btrim(first_name) <> ''),
  constraint ea_persons_last_name_not_blank check (btrim(last_name) <> '')
);

comment on table public.ea_persons is 'Person (Mensch oder Funktionsperson); Eigenschaften als eigene Zeilen in ea_properties.';

create index ea_persons_first_name_trgm on public.ea_persons using gin (first_name extensions.gin_trgm_ops);
create index ea_persons_last_name_lower on public.ea_persons (lower(last_name));

-- R4: Vor- und Nachname getrimmt und nicht leer
create function public.ea_persons_normalize()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.first_name := btrim(coalesce(new.first_name, ''));
  new.last_name := btrim(coalesce(new.last_name, ''));
  if new.first_name = '' or new.last_name = '' then
    raise exception 'AD_NAME_REQUIRED' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

revoke all on function public.ea_persons_normalize() from public, anon, authenticated;

create trigger ea_persons_normalize
  before insert or update of first_name, last_name on public.ea_persons
  for each row execute function public.ea_persons_normalize();

alter table public.ea_persons enable row level security;
revoke all on table public.ea_persons from public, anon, authenticated;
grant select on table public.ea_persons to authenticated;
grant insert (first_name, last_name, kind), update (first_name, last_name, kind)
  on table public.ea_persons to authenticated;

-- AD ≥ read: alle; EA ≥ read: nur Menschen (R15)
create policy ea_persons_select on public.ea_persons
  for select to authenticated
  using (public.ad_has_level('AD', 'read') or (public.ad_has_level('EA', 'read') and kind = 'human'));

-- AD ≥ edit oder EA ≥ edit; Funktionsperson nur durch AD
create policy ea_persons_insert on public.ea_persons
  for insert to authenticated
  with check (public.ad_has_level('AD', 'edit') or (public.ad_has_level('EA', 'edit') and kind = 'human'));

create policy ea_persons_update on public.ea_persons
  for update to authenticated
  using (public.ad_has_level('AD', 'edit') or (public.ad_has_level('EA', 'edit') and kind = 'human'))
  with check (public.ad_has_level('AD', 'edit') or (public.ad_has_level('EA', 'edit') and kind = 'human'));

-- Fachmodule lesen Personen ausschließlich über diese View (R15)
create view public.ea_v_persons
with (security_invoker = true)
as
select id, first_name, last_name, kind, created_at, created_by
  from public.ea_persons
 where kind = 'human';

revoke all on table public.ea_v_persons from public, anon, authenticated;
grant select on table public.ea_v_persons to authenticated;
