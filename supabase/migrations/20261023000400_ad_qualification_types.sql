-- US-AD-17, spec T26: Stammdaten Qualifikationsarten (R21–R25), ad_can_edit_qualification_types.
-- Pflege durch Admin (AD ≥ edit) und Geschäftsstelle (EA = manage); kein Löschen (R12, R25).
-- ad_qualification_usage folgt nach ea_properties (data-model.md).

create table public.ad_qualification_types (
  id uuid primary key default gen_random_uuid(),
  code text,
  name text not null,
  discipline text not null,
  kind public.ad_qualification_kind not null,
  level public.ad_license_level,
  specification text,
  issuer text not null default 'Bundesverband',
  dosb_eligible boolean,
  validity_years smallint,
  status public.ad_qualification_status not null default 'current',
  note text,
  source_ref text,
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid() references auth.users (id) on delete set null,
  updated_at timestamptz,
  updated_by uuid references auth.users (id) on delete set null,
  constraint ad_qualification_types_name_not_blank check (btrim(name) <> ''),
  constraint ad_qualification_types_discipline_not_blank check (btrim(discipline) <> ''),
  constraint ad_qualification_types_issuer_not_blank check (btrim(issuer) <> ''),
  constraint ad_qualification_types_code_format check (code is null or code ~ '^[A-Z0-9]{1,10}$'),
  constraint ad_qualification_types_level check ((kind = 'license') = (level is not null)),
  constraint ad_qualification_types_validity check (
    (kind = 'license' and validity_years between 1 and 10)
    or (kind = 'training' and (validity_years is null or validity_years between 1 and 10))
    or (kind in ('add_on', 'course') and validity_years is null)
  )
);

comment on table public.ad_qualification_types is
  'Qualifikationsarten (Stammdaten der Administration); Verweis aus ea_properties.field_values; nie löschen, nur historisch.';

create unique index ad_qualification_types_name_key on public.ad_qualification_types (lower(name));
create unique index ad_qualification_types_code_key on public.ad_qualification_types (lower(code)) where code is not null;
create unique index ad_qualification_types_source_ref_key on public.ad_qualification_types (source_ref)
  where source_ref is not null;
create index ad_qualification_types_discipline_kind on public.ad_qualification_types (discipline, kind);

-- R21–R24: trimmen, Kürzel groß, Fehlercodes vor den Constraints; geändert am/von
create function public.ad_qualification_types_guard()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- Startbestand erneut ausgeführt: vorhandene Quell-ID → on conflict do nothing entscheidet (T27)
  if tg_op = 'INSERT' and new.source_ref is not null and exists (
    select 1 from public.ad_qualification_types q where q.source_ref = new.source_ref
  ) then
    return new;
  end if;

  new.name := btrim(coalesce(new.name, ''));
  new.discipline := btrim(coalesce(new.discipline, ''));
  new.issuer := btrim(coalesce(new.issuer, ''));
  new.specification := nullif(btrim(coalesce(new.specification, '')), '');
  new.note := nullif(btrim(coalesce(new.note, '')), '');
  new.code := nullif(upper(btrim(coalesce(new.code, ''))), '');

  if new.name = '' then
    raise exception 'AD_QUALIFICATION_NAME_REQUIRED' using errcode = 'P0001';
  end if;
  if exists (
    select 1 from public.ad_qualification_types q
     where lower(q.name) = lower(new.name) and q.id <> new.id
  ) then
    raise exception 'AD_QUALIFICATION_NAME_TAKEN' using errcode = 'P0001';
  end if;

  if new.code is not null then
    if new.code !~ '^[A-Z0-9]{1,10}$' then
      raise exception 'AD_QUALIFICATION_CODE_FORMAT' using errcode = 'P0001';
    end if;
    if exists (
      select 1 from public.ad_qualification_types q
       where lower(q.code) = lower(new.code) and q.id <> new.id
    ) then
      raise exception 'AD_QUALIFICATION_CODE_TAKEN' using errcode = 'P0001';
    end if;
  end if;

  -- R23: Lizenzstufe nur bei Lizenz
  if new.kind <> 'license' then
    new.level := null;
  elsif new.level is null then
    raise exception 'AD_QUALIFICATION_LEVEL_REQUIRED' using errcode = 'P0001';
  end if;

  -- R24: Gültigkeitsdauer
  if new.kind in ('add_on', 'course') then
    new.validity_years := null;
  elsif new.kind = 'license' and (new.validity_years is null or new.validity_years not between 1 and 10) then
    raise exception 'AD_QUALIFICATION_VALIDITY' using errcode = 'P0001';
  elsif new.kind = 'training' and new.validity_years is not null and new.validity_years not between 1 and 10 then
    raise exception 'AD_QUALIFICATION_VALIDITY' using errcode = 'P0001';
  end if;

  if tg_op = 'UPDATE' then
    new.updated_at := now();
    new.updated_by := auth.uid();
  end if;

  return new;
end;
$$;

revoke all on function public.ad_qualification_types_guard() from public, anon, authenticated;

create trigger ad_qualification_types_guard
  before insert or update on public.ad_qualification_types
  for each row execute function public.ad_qualification_types_guard();

-- Pflegen dürfen Admin und Geschäftsstelle (Entscheidung Product Owner 21.10.2026)
create function public.ad_can_edit_qualification_types()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.ad_has_level('AD', 'edit') or public.ad_has_level('EA', 'manage');
$$;

revoke all on function public.ad_can_edit_qualification_types() from public, anon, authenticated;
grant execute on function public.ad_can_edit_qualification_types() to authenticated;

-- RLS: lesen mit aktivem Zugang [ANNAHME v0.6]; source_ref nur per Migration (kein Spaltenrecht)
alter table public.ad_qualification_types enable row level security;
revoke all on table public.ad_qualification_types from public, anon, authenticated;
grant select on table public.ad_qualification_types to authenticated;
grant insert (code, name, discipline, kind, level, specification, issuer, dosb_eligible, validity_years, status, note),
      update (code, name, discipline, kind, level, specification, issuer, dosb_eligible, validity_years, status, note)
  on table public.ad_qualification_types to authenticated;

create policy ad_qualification_types_select on public.ad_qualification_types
  for select to authenticated using (public.ad_has_active_access());
create policy ad_qualification_types_insert on public.ad_qualification_types
  for insert to authenticated with check (public.ad_can_edit_qualification_types());
create policy ad_qualification_types_update on public.ad_qualification_types
  for update to authenticated
  using (public.ad_can_edit_qualification_types()) with check (public.ad_can_edit_qualification_types());
