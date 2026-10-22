-- US-AD-13, US-AD-19, US-AD-22, spec T36: Eigenschaften mit Werten je Feld (field_values), Bezug, Gültigkeit
-- und Historie; Trigger ea_properties_validate (R27, R28, R35, R37, R38, R39, R41) und ea_properties_history.
-- Die Policies hier sind vorläufig (nur AD); …001000 ersetzt sie durch die Sichtbarkeit je Pfad.

create table public.ea_properties (
  id uuid primary key default gen_random_uuid(),
  person_id uuid not null references public.ea_persons (id),
  property_type_id uuid not null references public.ea_property_types (id) on delete restrict,
  field_values jsonb not null default '{}',
  related_referat_id uuid references public.ea_referate (id),
  related_gremium_id uuid references public.ea_gremien (id),
  valid_from date not null,
  valid_to date,
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid() references auth.users (id) on delete set null,
  updated_at timestamptz not null default now(),
  updated_by uuid default auth.uid() references auth.users (id) on delete set null,
  constraint ea_properties_valid_range check (valid_to is null or valid_to >= valid_from),
  constraint ea_properties_field_values_object check (jsonb_typeof(field_values) = 'object')
);

comment on table public.ea_properties is
  'Eigenschaft einer Person (eine Zeile je Eigenschaft, Werte je Feld in field_values); Bezugsspalte für RLS und Filter.';

create index ea_properties_person on public.ea_properties (person_id);
create index ea_properties_type on public.ea_properties (property_type_id);
create index ea_properties_referat on public.ea_properties (related_referat_id) where related_referat_id is not null;
create index ea_properties_gremium on public.ea_properties (related_gremium_id) where related_gremium_id is not null;
create index ea_properties_field_values on public.ea_properties using gin (field_values jsonb_path_ops);

create table public.ea_property_history (
  id bigint generated always as identity primary key,
  property_id uuid not null references public.ea_properties (id) on delete cascade,
  field_values jsonb not null,
  related_referat_id uuid,
  related_gremium_id uuid,
  valid_from date not null,
  valid_to date,
  changed_at timestamptz not null default now(),
  changed_by uuid default auth.uid() references auth.users (id) on delete set null
);

comment on table public.ea_property_history is 'Frühere Fassungen einer Eigenschaft; schreibt nur der Trigger ea_properties_history.';

create index ea_property_history_property on public.ea_property_history (property_id, changed_at desc);

-- Validierung je Feld und Bezug
create function public.ea_properties_validate()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_type public.ea_property_types%rowtype;
  v_field public.ea_property_fields%rowtype;
  v_value jsonb;
  v_text text;
  v_values jsonb := '{}';
  v_key text;
  v_date date;
  v_qual public.ad_qualification_types%rowtype;
  v_user boolean := auth.uid() is not null;
  v_changed boolean;
begin
  select * into v_type from public.ea_property_types t where t.id = new.property_type_id;
  if not found then
    raise exception 'AD_BAD_REQUEST' using errcode = 'P0001';
  end if;
  if tg_op = 'UPDATE' and (new.person_id <> old.person_id or new.property_type_id <> old.property_type_id) then
    raise exception 'AD_BAD_REQUEST' using errcode = 'P0001';
  end if;

  -- Bezug (R38, R39)
  if v_type.relation_kind = 'referat' then
    new.related_gremium_id := null;
    if new.related_referat_id is null then
      if v_type.relation_required then
        raise exception 'EA_RELATION_REQUIRED' using errcode = 'P0001';
      end if;
    elsif (tg_op = 'INSERT' or new.related_referat_id is distinct from old.related_referat_id)
          and not exists (select 1 from public.ea_referate r where r.id = new.related_referat_id and r.is_active) then
      raise exception 'EA_RELATION_REQUIRED' using errcode = 'P0001';
    end if;
    -- R41: mit Reichweite Referat nur eigene Referate anlegen oder dorthin ändern
    if v_user and new.related_referat_id is not null
       and (tg_op = 'INSERT' or new.related_referat_id is distinct from old.related_referat_id)
       and not public.ad_has_level('AD', 'edit')
       and not public.ad_has_level('EA', 'edit')
       and not public.ad_has_level('GR', 'edit')
       and cardinality(public.ad_my_referate('EA', 'edit')) > 0
       and not (new.related_referat_id = any (public.ad_my_referate('EA', 'edit'))) then
      raise exception 'EA_RELATION_FOREIGN_REFERAT' using errcode = 'P0001';
    end if;
  elsif v_type.relation_kind = 'gremium' then
    new.related_referat_id := null;
    if new.related_gremium_id is null then
      if v_type.relation_required then
        raise exception 'EA_RELATION_REQUIRED' using errcode = 'P0001';
      end if;
    elsif (tg_op = 'INSERT' or new.related_gremium_id is distinct from old.related_gremium_id)
          and not exists (select 1 from public.ea_gremien g where g.id = new.related_gremium_id and g.is_active) then
      raise exception 'EA_RELATION_REQUIRED' using errcode = 'P0001';
    end if;
  else
    new.related_referat_id := null;
    new.related_gremium_id := null;
    -- R39: Eigenschaften mit Bezug auf eine Gruppe schreiben nur Nutzer mit GR ≥ edit
    if v_type.relation_kind = 'group' and v_user and not public.ad_has_level('GR', 'edit') then
      raise exception 'EA_GROUP_RELATION_ONLY_GR' using errcode = 'P0001';
    end if;
  end if;

  -- Unbekannte Schlüssel (R35)
  for v_key in select jsonb_object_keys(new.field_values) loop
    if not exists (
      select 1 from public.ea_property_fields f where f.property_type_id = new.property_type_id and f.key = v_key
    ) then
      raise exception 'EA_FIELD_UNKNOWN' using errcode = 'P0001', detail = v_key;
    end if;
  end loop;

  -- Werte je Feld (R35, R27, R28)
  for v_field in
    select * from public.ea_property_fields f where f.property_type_id = new.property_type_id order by f.sort_order
  loop
    v_value := new.field_values -> v_field.key;
    if v_value is null or jsonb_typeof(v_value) = 'null'
       or (jsonb_typeof(v_value) = 'string' and btrim(v_value #>> '{}') = '') then
      if v_field.is_required then
        raise exception 'EA_FIELD_REQUIRED' using errcode = 'P0001', detail = v_field.label;
      end if;
      continue;
    end if;

    case v_field.data_type
      when 'text' then
        if jsonb_typeof(v_value) <> 'string' then
          raise exception 'EA_VALUE_TYPE' using errcode = 'P0001', detail = v_field.label;
        end if;
        v_value := to_jsonb(btrim(v_value #>> '{}'));
      when 'choice' then
        if jsonb_typeof(v_value) <> 'string' then
          raise exception 'EA_VALUE_TYPE' using errcode = 'P0001', detail = v_field.label;
        end if;
        v_text := btrim(v_value #>> '{}');
        if not (v_text = any (v_field.choice_values)) then
          raise exception 'EA_FIELD_CHOICE' using errcode = 'P0001', detail = v_field.label;
        end if;
        v_value := to_jsonb(v_text);
      when 'number' then
        if jsonb_typeof(v_value) <> 'number' then
          raise exception 'EA_VALUE_TYPE' using errcode = 'P0001', detail = v_field.label;
        end if;
      when 'year' then
        if jsonb_typeof(v_value) <> 'number'
           or (v_value #>> '{}')::numeric <> trunc((v_value #>> '{}')::numeric)
           or (v_value #>> '{}')::numeric not between 1900 and 2100 then
          raise exception 'EA_VALUE_TYPE' using errcode = 'P0001', detail = v_field.label;
        end if;
      when 'boolean' then
        if jsonb_typeof(v_value) <> 'boolean' then
          raise exception 'EA_VALUE_TYPE' using errcode = 'P0001', detail = v_field.label;
        end if;
      when 'date' then
        v_text := v_value #>> '{}';
        if jsonb_typeof(v_value) <> 'string' or v_text !~ '^\d{4}-\d{2}-\d{2}$' then
          raise exception 'EA_VALUE_TYPE' using errcode = 'P0001', detail = v_field.label;
        end if;
        begin
          v_date := v_text::date;
        exception when others then
          raise exception 'EA_VALUE_TYPE' using errcode = 'P0001', detail = v_field.label;
        end;
        if to_char(v_date, 'YYYY-MM-DD') <> v_text then
          raise exception 'EA_VALUE_TYPE' using errcode = 'P0001', detail = v_field.label;
        end if;
      when 'qualification_type' then
        v_text := v_value #>> '{}';
        if jsonb_typeof(v_value) <> 'string'
           or v_text !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
          raise exception 'EA_VALUE_TYPE' using errcode = 'P0001', detail = v_field.label;
        end if;
        select * into v_qual from public.ad_qualification_types q where q.id = v_text::uuid;
        if not found then
          raise exception 'EA_VALUE_TYPE' using errcode = 'P0001', detail = v_field.label;
        end if;
        v_changed := tg_op = 'INSERT' or (old.field_values ->> v_field.key) is distinct from v_text;
        -- R27: historische Qualifikationsart nicht neu vergeben (ohne Nutzerkontext erlaubt: Altbestand)
        if v_changed and v_user and v_qual.status = 'historic' then
          raise exception 'AD_QUALIFICATION_HISTORIC' using errcode = 'P0001', detail = v_field.label;
        end if;
        -- R28: erlaubte Typen je Feld
        if v_changed and v_field.allowed_qualification_kinds is not null
           and not (v_qual.kind = any (v_field.allowed_qualification_kinds)) then
          raise exception 'AD_QUALIFICATION_KIND' using errcode = 'P0001', detail = v_field.label;
        end if;
        v_value := to_jsonb(lower(v_text));
    end case;

    v_values := v_values || jsonb_build_object(v_field.key, v_value);
  end loop;
  new.field_values := v_values;

  -- R37: nur ein gültiger Eintrag je Zeitraum
  if not v_type.allow_multiple and exists (
    select 1 from public.ea_properties p
     where p.person_id = new.person_id
       and p.property_type_id = new.property_type_id
       and p.id <> new.id
       and daterange(p.valid_from, p.valid_to, '[]') && daterange(new.valid_from, new.valid_to, '[]')
  ) then
    raise exception 'EA_SINGLE_VALUE' using errcode = 'P0001';
  end if;

  if tg_op = 'UPDATE' then
    new.updated_at := now();
    new.updated_by := auth.uid();
  end if;

  return new;
end;
$$;

revoke all on function public.ea_properties_validate() from public, anon, authenticated;

create trigger ea_properties_validate
  before insert or update on public.ea_properties
  for each row execute function public.ea_properties_validate();

-- Historie: alte Fassung bei jeder Änderung
create function public.ea_properties_history()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (new.field_values, new.related_referat_id, new.related_gremium_id, new.valid_from, new.valid_to)
     is distinct from (old.field_values, old.related_referat_id, old.related_gremium_id, old.valid_from, old.valid_to) then
    insert into public.ea_property_history
      (property_id, field_values, related_referat_id, related_gremium_id, valid_from, valid_to)
    values (old.id, old.field_values, old.related_referat_id, old.related_gremium_id, old.valid_from, old.valid_to);
  end if;
  return new;
end;
$$;

revoke all on function public.ea_properties_history() from public, anon, authenticated;

create trigger ea_properties_history
  after update on public.ea_properties
  for each row execute function public.ea_properties_history();

-- RLS: vorläufig nur AD; …001000 ersetzt die Policies (R29, R32, R42)
alter table public.ea_properties enable row level security;
alter table public.ea_property_history enable row level security;
revoke all on table public.ea_properties, public.ea_property_history from public, anon, authenticated;

grant select on table public.ea_properties to authenticated;
grant insert (person_id, property_type_id, field_values, related_referat_id, related_gremium_id, valid_from, valid_to),
      update (field_values, related_referat_id, related_gremium_id, valid_from, valid_to)
  on table public.ea_properties to authenticated;
grant select on table public.ea_property_history to authenticated;

create policy ea_properties_select on public.ea_properties
  for select to authenticated using (public.ad_has_level('AD', 'read'));
create policy ea_properties_insert on public.ea_properties
  for insert to authenticated with check (public.ad_has_level('AD', 'edit'));
create policy ea_properties_update on public.ea_properties
  for update to authenticated
  using (public.ad_has_level('AD', 'edit')) with check (public.ad_has_level('AD', 'edit'));
create policy ea_property_history_select on public.ea_property_history
  for select to authenticated using (public.ad_has_level('AD', 'read'));
