-- US-AD-20, US-AD-22, spec T34 (und T26 Teil): Stammdaten Referate und Gremien; ad_has_active_access.
-- Startbestand ohne Personendaten, läuft in TEST und PROD (spec.md Abschnitt 2, 8).

-- Wahr, wenn der aufrufende Nutzer einen aktiven Zugang hat (Lesen der Stammdaten)
create function public.ad_has_active_access()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.ad_accesses a
     where a.auth_user_id = auth.uid() and a.status = 'active'
  );
$$;

revoke all on function public.ad_has_active_access() from public, anon, authenticated;
grant execute on function public.ad_has_active_access() to authenticated;

create table public.ea_referate (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  sort_order int not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz,
  updated_by uuid references auth.users (id) on delete set null,
  constraint ea_referate_name_not_blank check (btrim(name) <> '')
);

comment on table public.ea_referate is 'Referate der Sektion; Bezug von Eigenschaften und Reichweite „Referat“. Kein Löschen, nur inaktiv.';

create unique index ea_referate_name_key on public.ea_referate (lower(name));

create table public.ea_gremien (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  sort_order int not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz,
  updated_by uuid references auth.users (id) on delete set null,
  constraint ea_gremien_name_not_blank check (btrim(name) <> '')
);

comment on table public.ea_gremien is 'Gremien der Sektion; getrennt von der Rechtevorlage Vorstand und vom Amt. Kein Löschen, nur inaktiv.';

create unique index ea_gremien_name_key on public.ea_gremien (lower(name));

create trigger ea_referate_set_updated
  before update on public.ea_referate
  for each row execute function public.ad_set_updated();

create trigger ea_gremien_set_updated
  before update on public.ea_gremien
  for each row execute function public.ad_set_updated();

-- Startbestand (idempotent)
insert into public.ea_referate (name, sort_order)
select v.name, v.sort_order
  from (values
    ('Ausbildung', 1), ('Touren', 2), ('Kinder und Jugend', 3), ('Klettern', 4),
    ('Leistungssport', 5), ('Karl-Stein-Hütte', 6), ('Sulzenauhütte', 7)
  ) as v (name, sort_order)
 where not exists (select 1 from public.ea_referate r where lower(r.name) = lower(v.name));

insert into public.ea_gremien (name, sort_order)
select v.name, v.sort_order
  from (values ('Vorstand', 1), ('Beirat', 2), ('Ehrenrat', 3), ('Jugendausschuss', 4)) as v (name, sort_order)
 where not exists (select 1 from public.ea_gremien g where lower(g.name) = lower(v.name));

-- RLS: lesen mit aktivem Zugang; pflegen mit AD ≥ edit oder EA = manage [ANNAHME v0.7]; kein Löschen
alter table public.ea_referate enable row level security;
alter table public.ea_gremien enable row level security;
revoke all on table public.ea_referate, public.ea_gremien from public, anon, authenticated;
grant select on table public.ea_referate, public.ea_gremien to authenticated;
grant insert (name, sort_order, is_active), update (name, sort_order, is_active)
  on table public.ea_referate, public.ea_gremien to authenticated;

create policy ea_referate_select on public.ea_referate
  for select to authenticated using (public.ad_has_active_access());
create policy ea_referate_insert on public.ea_referate
  for insert to authenticated
  with check (public.ad_has_level('AD', 'edit') or public.ad_has_level('EA', 'manage'));
create policy ea_referate_update on public.ea_referate
  for update to authenticated
  using (public.ad_has_level('AD', 'edit') or public.ad_has_level('EA', 'manage'))
  with check (public.ad_has_level('AD', 'edit') or public.ad_has_level('EA', 'manage'));

create policy ea_gremien_select on public.ea_gremien
  for select to authenticated using (public.ad_has_active_access());
create policy ea_gremien_insert on public.ea_gremien
  for insert to authenticated
  with check (public.ad_has_level('AD', 'edit') or public.ad_has_level('EA', 'manage'));
create policy ea_gremien_update on public.ea_gremien
  for update to authenticated
  using (public.ad_has_level('AD', 'edit') or public.ad_has_level('EA', 'manage'))
  with check (public.ad_has_level('AD', 'edit') or public.ad_has_level('EA', 'manage'));
