-- US-GR-01, US-GR-03, US-GR-18, spec T1 (GR spec.md 2.1, 2.2): Gruppen und Trainingszeiten; Bezug „Gruppe“ an
-- ea_properties (R38), Schreiben von Eigenschaften mit Bezug Gruppe nur über Gruppen-Funktionen (R39, Ü7);
-- System-Eigenschaftsart „Funktion in Gruppe“ (group_function).
-- Schreiben auf gr_-Tabellen nur über security-definer-Funktionen (…000300 ff.); authenticated hat nur select.

-- Heute in Europe/Berlin (Datumskonvention GR spec.md 2, research.md R-GR-03)
create function public.gr_today()
returns date
language sql
stable
set search_path = ''
as $$
  select (now() at time zone 'Europe/Berlin')::date;
$$;

revoke all on function public.gr_today() from public, anon, authenticated;
grant execute on function public.gr_today() to authenticated;

-- Gruppe
create table public.gr_groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  referat_id uuid not null references public.ea_referate (id) on delete restrict,
  dissolved_on date,
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid() references auth.users (id) on delete set null,
  updated_at timestamptz,
  updated_by uuid references auth.users (id) on delete set null,
  constraint gr_groups_name_length check (name = btrim(name) and char_length(name) between 1 and 80)
);

comment on table public.gr_groups is 'Gruppe des Kinder- und Jugendbereichs; dissolved_on = letzter Tag; schreiben nur über gr_save_group, gr_dissolve_group.';

create unique index gr_groups_name_active on public.gr_groups (lower(name)) where dissolved_on is null;
create index gr_groups_referat on public.gr_groups (referat_id);

create trigger gr_groups_set_updated
  before update on public.gr_groups
  for each row execute function public.ad_set_updated();

-- Trainingszeit mit Historie (R18, R19, A13)
create table public.gr_training_times (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.gr_groups (id) on delete restrict,
  weekday smallint not null,
  starts_at time not null,
  ends_at time not null,
  valid_from date not null,
  valid_to date,
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid() references auth.users (id) on delete set null,
  updated_at timestamptz,
  updated_by uuid references auth.users (id) on delete set null,
  constraint gr_training_times_weekday check (weekday between 1 and 7),
  constraint gr_training_times_end check (ends_at > starts_at),
  constraint gr_training_times_valid_range check (valid_to is null or valid_to >= valid_from)
);

comment on table public.gr_training_times is 'Trainingszeit einer Gruppe (Wochentag ISO 1 = Montag); Kernfelder nach dem Anlegen gesperrt.';

create index gr_training_times_group on public.gr_training_times (group_id, weekday);

-- Kernfelder gesperrt; nur valid_to änderbar (A13, R19)
create function public.gr_training_times_guard()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if (new.group_id, new.weekday, new.starts_at, new.ends_at, new.valid_from)
     is distinct from (old.group_id, old.weekday, old.starts_at, old.ends_at, old.valid_from) then
    raise exception 'GR_TRAINING_TIME_LOCKED' using errcode = 'P0001';
  end if;
  new.updated_at := now();
  new.updated_by := auth.uid();
  return new;
end;
$$;

revoke all on function public.gr_training_times_guard() from public, anon, authenticated;

create trigger gr_training_times_guard
  before update on public.gr_training_times
  for each row execute function public.gr_training_times_guard();

-- RLS: lesen nach GR spec.md 3; kein Schreiben für authenticated
alter table public.gr_groups enable row level security;
alter table public.gr_training_times enable row level security;
revoke all on table public.gr_groups, public.gr_training_times from public, anon, authenticated;
grant select on table public.gr_groups, public.gr_training_times to authenticated;

-- Gruppenname auch mit EA-Rechten (Anzeige der Funktion in Gruppe im Ehrenamtsmanagement, US-GR-13 AK3)
create policy gr_groups_select on public.gr_groups
  for select to authenticated
  using ((select public.ad_has_level('GR', 'read')) or (select public.ad_has_any_level('EA', 'read')));
create policy gr_training_times_select on public.gr_training_times
  for select to authenticated
  using ((select public.ad_has_level('GR', 'read')));

-- Bezug „Gruppe“ an Eigenschaften (GR spec.md 2.2)
alter table public.ea_properties
  add column related_group_id uuid references public.gr_groups (id) on delete restrict;
alter table public.ea_property_history
  add column related_group_id uuid;

create index ea_properties_group on public.ea_properties (related_group_id) where related_group_id is not null;

-- Validierung je Feld und Bezug; neue Fassung mit Zweig „Gruppe“ (R38, R39)
create or replace function public.ea_properties_validate()
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
  v_dissolved date;
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
    new.related_group_id := null;
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
    new.related_group_id := null;
    if new.related_gremium_id is null then
      if v_type.relation_required then
        raise exception 'EA_RELATION_REQUIRED' using errcode = 'P0001';
      end if;
    elsif (tg_op = 'INSERT' or new.related_gremium_id is distinct from old.related_gremium_id)
          and not exists (select 1 from public.ea_gremien g where g.id = new.related_gremium_id and g.is_active) then
      raise exception 'EA_RELATION_REQUIRED' using errcode = 'P0001';
    end if;
  elsif v_type.relation_kind = 'group' then
    new.related_referat_id := null;
    new.related_gremium_id := null;
    -- R39: Eigenschaften mit Bezug auf eine Gruppe schreiben nur Nutzer mit GR ≥ edit (über Gruppen-Funktionen)
    if v_user and not public.ad_has_level('GR', 'edit') then
      raise exception 'EA_GROUP_RELATION_ONLY_GR' using errcode = 'P0001';
    end if;
    if new.related_group_id is null then
      if v_type.relation_required then
        raise exception 'EA_RELATION_REQUIRED' using errcode = 'P0001';
      end if;
    elsif tg_op = 'INSERT' or new.related_group_id is distinct from old.related_group_id then
      select g.dissolved_on into v_dissolved from public.gr_groups g where g.id = new.related_group_id;
      if not found then
        raise exception 'EA_RELATION_REQUIRED' using errcode = 'P0001';
      end if;
      -- aufgelöste Gruppen nicht neu wählbar
      if v_dissolved is not null and v_dissolved < new.valid_from then
        raise exception 'GR_GROUP_DISSOLVED' using errcode = 'P0001';
      end if;
    end if;
  else
    new.related_referat_id := null;
    new.related_gremium_id := null;
    new.related_group_id := null;
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

-- Historie: alte Fassung bei jeder Änderung, jetzt mit related_group_id
create or replace function public.ea_properties_history()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (new.field_values, new.related_referat_id, new.related_gremium_id, new.related_group_id, new.valid_from, new.valid_to)
     is distinct from
     (old.field_values, old.related_referat_id, old.related_gremium_id, old.related_group_id, old.valid_from, old.valid_to) then
    insert into public.ea_property_history
      (property_id, field_values, related_referat_id, related_gremium_id, related_group_id, valid_from, valid_to)
    values (old.id, old.field_values, old.related_referat_id, old.related_gremium_id, old.related_group_id,
            old.valid_from, old.valid_to);
  end if;
  return new;
end;
$$;

-- Schreibrecht: Bezug Gruppe nie über RLS, nur über Gruppen-Funktionen (R39, Ü7); sonst unverändert
create or replace function public.ea_property_writable(p_property_type uuid, p_person uuid, p_referat uuid)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_level public.ea_read_level;
  v_relation public.ea_relation_kind;
  v_ea boolean := false;
  v_gr boolean := false;
begin
  select t.read_level, t.relation_kind into v_level, v_relation
    from public.ea_property_types t where t.id = p_property_type;
  if v_level is null then
    return false;
  end if;

  if v_relation = 'group' then
    return false;
  end if;

  if public.ad_has_level('AD', 'edit') then
    return true;
  end if;
  if v_level = 'confidential' then
    return false;
  end if;

  v_gr := (v_level = 'all' or public.ad_has_level('GR', 'manage'))
          and public.ad_has_level('GR', 'edit')
          and public.gr_person_visible(p_person, 'edit');

  v_ea := (v_level = 'all' or public.ad_has_level('EA', 'manage'))
          and public.ea_person_visible_ea(p_person, 'edit')
          and (public.ad_has_level('EA', 'edit')
               or (p_referat is not null and p_referat = any (public.ad_my_referate('EA', 'edit'))));

  return v_ea or v_gr;
end;
$$;

-- System-Eigenschaftsart „Funktion in Gruppe“ (GR spec.md 2.2); ohne Nutzerkontext, idempotent über system_key
create function public.gr_seed_group_function_type()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid;
begin
  insert into public.ea_property_types
    (name, purpose, system_key, category, read_level, relation_kind, relation_required, allow_multiple,
     visible_in, origin, valid_from_label, valid_to_label)
  values
    ('Funktion in Gruppe', 'Betreuung einer Gruppe (Gruppenleitung, Trainer:in, Helfer:in)', 'group_function',
     'assignment', 'all', 'group', true, true, '{AD,EA,GR}', 'system', 'seit', 'bis')
  on conflict (system_key) do nothing
  returning id into v_id;

  if v_id is not null then
    insert into public.ea_property_fields
      (property_type_id, key, label, data_type, is_required, choice_values, sort_order)
    values
      (v_id, 'function', 'Funktion', 'choice', true, '{Gruppenleitung,Trainer:in,Helfer:in}', 1);
  end if;
end;
$$;

revoke all on function public.gr_seed_group_function_type() from public, anon, authenticated;

select public.gr_seed_group_function_type();
