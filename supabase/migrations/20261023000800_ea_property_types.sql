-- US-AD-12, US-AD-19, US-AD-22, spec T35 (Kern v0.7, v0.7.2): Eigenschaftsarten mit Feldern, Kategorie,
-- Lesestufe, Bezug und Bezeichnungen „gültig von/bis“ (R49); ea_save_property_type (R9).
-- Die Sperren gegen vorhandene Eigenschaften prüfen ea_properties zur Laufzeit (Tabelle folgt in …000900).

create table public.ea_property_types (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  purpose text not null,
  category public.ea_property_category not null default 'other',
  read_level public.ea_read_level not null default 'all',
  relation_kind public.ea_relation_kind not null default 'none',
  relation_required boolean not null default false,
  allow_multiple boolean not null default true,
  system_key text,
  visible_in text[] not null,
  origin text not null default 'custom',
  valid_from_label text,
  valid_to_label text,
  created_at timestamptz not null default now(),
  created_by uuid default auth.uid() references auth.users (id) on delete set null,
  updated_at timestamptz,
  updated_by uuid references auth.users (id) on delete set null,
  constraint ea_property_types_name_not_blank check (btrim(name) <> ''),
  constraint ea_property_types_purpose_not_blank check (btrim(purpose) <> ''),
  constraint ea_property_types_origin check (origin in ('system', 'custom')),
  constraint ea_property_types_visible_in check (cardinality(visible_in) >= 1),
  constraint ea_property_types_relation_required check (relation_kind <> 'none' or not relation_required),
  constraint ea_property_types_system_key_key unique (system_key),
  constraint ea_property_types_valid_from_label_length check (char_length(valid_from_label) <= 40),
  constraint ea_property_types_valid_to_label_length check (char_length(valid_to_label) <= 40)
);

comment on table public.ea_property_types is
  'Eigenschaftsart mit Feldern (ea_property_fields); Lesestufe nach R29, Bezug nach R38, Bezeichnungen gültig von/bis nach R49.';

create unique index ea_property_types_name_key on public.ea_property_types (lower(name));

create table public.ea_property_fields (
  id uuid primary key default gen_random_uuid(),
  property_type_id uuid not null references public.ea_property_types (id) on delete restrict,
  key text not null,
  label text not null,
  data_type public.ea_data_type not null,
  is_required boolean not null default false,
  choice_values text[],
  allowed_qualification_kinds public.ad_qualification_kind[],
  sort_order int not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz,
  updated_by uuid references auth.users (id) on delete set null,
  constraint ea_property_fields_key_format check (key ~ '^[a-z][a-z0-9_]{0,39}$'),
  constraint ea_property_fields_type_key unique (property_type_id, key),
  constraint ea_property_fields_label_not_blank check (btrim(label) <> ''),
  constraint ea_property_fields_choice check (
    (data_type = 'choice' and choice_values is not null and cardinality(choice_values) >= 1)
    or (data_type <> 'choice' and choice_values is null)
  ),
  constraint ea_property_fields_kinds check (allowed_qualification_kinds is null or data_type = 'qualification_type')
);

comment on table public.ea_property_fields is 'Felder einer Eigenschaftsart; nicht löschen (R36), Schlüssel nach Anlage unveränderlich.';

create unique index ea_property_fields_label_key on public.ea_property_fields (property_type_id, lower(label));

-- Eigenschaften dieser Art vorhanden? (Sperren nach R36; ea_properties folgt in …000900)
create function public.ea_property_type_in_use(p_type uuid)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  return exists (select 1 from public.ea_properties p where p.property_type_id = p_type);
end;
$$;

revoke all on function public.ea_property_type_in_use(uuid) from public, anon, authenticated;

-- Eigenschaftsart: R9, R29, R36 (Bezug), R49, visible_in, system_key, Bezug Gruppe
create function public.ea_property_types_guard()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.name := btrim(coalesce(new.name, ''));
  new.purpose := btrim(coalesce(new.purpose, ''));
  new.valid_from_label := nullif(btrim(coalesce(new.valid_from_label, '')), '');
  new.valid_to_label := nullif(btrim(coalesce(new.valid_to_label, '')), '');

  if new.purpose = '' then
    raise exception 'EA_PURPOSE_REQUIRED' using errcode = 'P0001';
  end if;
  if char_length(new.valid_from_label) > 40 or char_length(new.valid_to_label) > 40 then
    raise exception 'EA_LABEL_TOO_LONG' using errcode = 'P0001';
  end if;
  if exists (
    select 1 from unnest(new.visible_in) as v (code)
     where not exists (select 1 from public.ad_modules m where m.code = v.code)
  ) then
    raise exception 'AD_BAD_REQUEST' using errcode = 'P0001';
  end if;

  if auth.uid() is not null then
    -- R29: vertraulich setzen oder aufheben nur mit AD ≥ edit
    if ((tg_op = 'INSERT' and new.read_level = 'confidential')
        or (tg_op = 'UPDATE' and (new.read_level = 'confidential') <> (old.read_level = 'confidential')))
       and not public.ad_has_level('AD', 'edit') then
      raise exception 'AD_CONFIDENTIAL_ONLY_AD' using errcode = 'P0001';
    end if;
    -- Bezug „Gruppe“ nur mit GR = verwalten [ANNAHME v0.7]
    if new.relation_kind = 'group'
       and (tg_op = 'INSERT' or old.relation_kind <> 'group')
       and not public.ad_has_level('GR', 'manage') then
      raise exception 'AD_FORBIDDEN' using errcode = 'P0001';
    end if;
    -- system_key und origin nur per Migration bzw. ohne Nutzerkontext
    if (tg_op = 'INSERT' and (new.system_key is not null or new.origin <> 'custom'))
       or (tg_op = 'UPDATE' and (new.system_key is distinct from old.system_key or new.origin <> old.origin)) then
      raise exception 'AD_FORBIDDEN' using errcode = 'P0001';
    end if;
  end if;

  if tg_op = 'UPDATE' then
    if new.relation_kind <> old.relation_kind and public.ea_property_type_in_use(new.id) then
      raise exception 'EA_RELATION_LOCKED' using errcode = 'P0001';
    end if;
    new.updated_at := now();
    new.updated_by := auth.uid();
  end if;

  return new;
end;
$$;

revoke all on function public.ea_property_types_guard() from public, anon, authenticated;

create trigger ea_property_types_guard
  before insert or update on public.ea_property_types
  for each row execute function public.ea_property_types_guard();

-- Felder: R9 (Auswahlwerte), R36 (Datentyp, Auswahlwerte, neue Pflichtfelder), Schlüssel unveränderlich
create function public.ea_property_fields_guard()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.label := btrim(coalesce(new.label, ''));

  if new.data_type = 'choice' then
    -- getrimmt, ohne leere und doppelte Werte, in der Reihenfolge der Eingabe
    new.choice_values := array(
      select s.v
        from (select btrim(x) as v, min(n) as n
                from unnest(coalesce(new.choice_values, '{}')) with ordinality as u (x, n)
               where btrim(x) <> ''
               group by btrim(x)) as s
       order by s.n
    );
    if cardinality(new.choice_values) = 0 then
      raise exception 'EA_CHOICE_VALUES_REQUIRED' using errcode = 'P0001';
    end if;
  else
    new.choice_values := null;
  end if;
  if new.data_type <> 'qualification_type' then
    new.allowed_qualification_kinds := null;
  end if;

  if tg_op = 'INSERT' then
    if new.is_required and public.ea_property_type_in_use(new.property_type_id) then
      raise exception 'EA_FIELD_NEW_REQUIRED' using errcode = 'P0001';
    end if;
  else
    if new.key <> old.key or new.property_type_id <> old.property_type_id then
      raise exception 'AD_BAD_REQUEST' using errcode = 'P0001';
    end if;
    if new.data_type <> old.data_type and public.ea_property_type_in_use(new.property_type_id) then
      raise exception 'EA_DATA_TYPE_LOCKED' using errcode = 'P0001';
    end if;
    if old.data_type = 'choice' and new.data_type = 'choice'
       and not (old.choice_values <@ coalesce(new.choice_values, '{}')) then
      raise exception 'EA_CHOICE_VALUE_REMOVED' using errcode = 'P0001';
    end if;
    new.updated_at := now();
    new.updated_by := auth.uid();
  end if;

  return new;
end;
$$;

revoke all on function public.ea_property_fields_guard() from public, anon, authenticated;

create trigger ea_property_fields_guard
  before insert or update on public.ea_property_fields
  for each row execute function public.ea_property_fields_guard();

-- Art mit Feldern in einer Transaktion speichern (R9); security invoker: RLS und Spaltenrechte gelten.
-- p_type: {id?, name, purpose, category, read_level, relation_kind, relation_required, allow_multiple,
--          visible_in[], valid_from_label, valid_to_label}
-- p_fields: [{id?, key, label, data_type, is_required, choice_values[], allowed_qualification_kinds[]}]
-- Reihenfolge der Felder = Reihenfolge im Array. Nicht genannte vorhandene Felder bleiben (kein Löschen).
create function public.ea_save_property_type(p_type jsonb, p_fields jsonb)
returns uuid
language plpgsql
set search_path = ''
as $$
declare
  v_id uuid := nullif(p_type ->> 'id', '')::uuid;
  v_field jsonb;
  v_pos int := 0;
  v_existing int;
begin
  if jsonb_typeof(p_fields) is distinct from 'array' then
    raise exception 'EA_NO_FIELDS' using errcode = 'P0001';
  end if;

  if v_id is null then
    if jsonb_array_length(p_fields) = 0 then
      raise exception 'EA_NO_FIELDS' using errcode = 'P0001';
    end if;
    insert into public.ea_property_types (name, purpose, category, read_level, relation_kind, relation_required,
                                          allow_multiple, visible_in, valid_from_label, valid_to_label)
    values (
      p_type ->> 'name',
      coalesce(p_type ->> 'purpose', ''),
      coalesce((p_type ->> 'category')::public.ea_property_category, 'other'),
      coalesce((p_type ->> 'read_level')::public.ea_read_level, 'all'),
      coalesce((p_type ->> 'relation_kind')::public.ea_relation_kind, 'none'),
      coalesce((p_type ->> 'relation_required')::boolean, false),
      coalesce((p_type ->> 'allow_multiple')::boolean, true),
      array(select jsonb_array_elements_text(coalesce(p_type -> 'visible_in', '[]'))),
      p_type ->> 'valid_from_label',
      p_type ->> 'valid_to_label'
    )
    returning id into v_id;
  else
    update public.ea_property_types t
       set name = coalesce(p_type ->> 'name', t.name),
           purpose = coalesce(p_type ->> 'purpose', t.purpose),
           category = coalesce((p_type ->> 'category')::public.ea_property_category, t.category),
           read_level = coalesce((p_type ->> 'read_level')::public.ea_read_level, t.read_level),
           relation_kind = coalesce((p_type ->> 'relation_kind')::public.ea_relation_kind, t.relation_kind),
           relation_required = coalesce((p_type ->> 'relation_required')::boolean, t.relation_required),
           allow_multiple = coalesce((p_type ->> 'allow_multiple')::boolean, t.allow_multiple),
           visible_in = case when p_type ? 'visible_in'
                             then array(select jsonb_array_elements_text(p_type -> 'visible_in'))
                             else t.visible_in end,
           valid_from_label = case when p_type ? 'valid_from_label' then p_type ->> 'valid_from_label'
                                   else t.valid_from_label end,
           valid_to_label = case when p_type ? 'valid_to_label' then p_type ->> 'valid_to_label'
                                 else t.valid_to_label end
     where t.id = v_id;
    if not found then
      raise exception 'AD_FORBIDDEN' using errcode = 'P0001';
    end if;
  end if;

  for v_field in select value from jsonb_array_elements(p_fields) loop
    v_pos := v_pos + 1;
    if nullif(v_field ->> 'id', '') is null then
      insert into public.ea_property_fields (property_type_id, key, label, data_type, is_required, choice_values,
                                             allowed_qualification_kinds, sort_order)
      values (
        v_id,
        v_field ->> 'key',
        v_field ->> 'label',
        (v_field ->> 'data_type')::public.ea_data_type,
        coalesce((v_field ->> 'is_required')::boolean, false),
        case when jsonb_typeof(v_field -> 'choice_values') = 'array'
             then array(select jsonb_array_elements_text(v_field -> 'choice_values')) end,
        case when jsonb_typeof(v_field -> 'allowed_qualification_kinds') = 'array'
              and jsonb_array_length(v_field -> 'allowed_qualification_kinds') > 0
             then array(select jsonb_array_elements_text(v_field -> 'allowed_qualification_kinds'))::public.ad_qualification_kind[] end,
        v_pos
      );
    else
      update public.ea_property_fields f
         set label = coalesce(v_field ->> 'label', f.label),
             data_type = coalesce((v_field ->> 'data_type')::public.ea_data_type, f.data_type),
             is_required = coalesce((v_field ->> 'is_required')::boolean, f.is_required),
             choice_values = case when v_field ? 'choice_values' and jsonb_typeof(v_field -> 'choice_values') = 'array'
                                  then array(select jsonb_array_elements_text(v_field -> 'choice_values'))
                                  when v_field ? 'choice_values' then null
                                  else f.choice_values end,
             allowed_qualification_kinds = case
               when v_field ? 'allowed_qualification_kinds'
                    and jsonb_typeof(v_field -> 'allowed_qualification_kinds') = 'array'
                    and jsonb_array_length(v_field -> 'allowed_qualification_kinds') > 0
                 then array(select jsonb_array_elements_text(v_field -> 'allowed_qualification_kinds'))::public.ad_qualification_kind[]
               when v_field ? 'allowed_qualification_kinds' then null
               else f.allowed_qualification_kinds end,
             sort_order = v_pos
       where f.id = (v_field ->> 'id')::uuid and f.property_type_id = v_id;
      if not found then
        raise exception 'AD_BAD_REQUEST' using errcode = 'P0001';
      end if;
    end if;
  end loop;

  select count(*) into v_existing from public.ea_property_fields f where f.property_type_id = v_id;
  if v_existing = 0 then
    raise exception 'EA_NO_FIELDS' using errcode = 'P0001';
  end if;

  return v_id;
end;
$$;

revoke all on function public.ea_save_property_type(jsonb, jsonb) from public, anon, authenticated;
grant execute on function public.ea_save_property_type(jsonb, jsonb) to authenticated;

-- RLS (spec.md Abschnitt 3): lesen AD ≥ read alles, EA (beide Reichweiten) oder GR ≥ read ohne vertrauliche;
-- pflegen AD ≥ edit oder EA = manage (vertraulich nur AD, Trigger); kein Löschen
alter table public.ea_property_types enable row level security;
alter table public.ea_property_fields enable row level security;
revoke all on table public.ea_property_types, public.ea_property_fields from public, anon, authenticated;

grant select on table public.ea_property_types to authenticated;
grant insert (name, purpose, category, read_level, relation_kind, relation_required, allow_multiple, visible_in,
              valid_from_label, valid_to_label),
      update (name, purpose, category, read_level, relation_kind, relation_required, allow_multiple, visible_in,
              valid_from_label, valid_to_label)
  on table public.ea_property_types to authenticated;

grant select on table public.ea_property_fields to authenticated;
grant insert (property_type_id, key, label, data_type, is_required, choice_values, allowed_qualification_kinds, sort_order),
      update (label, data_type, is_required, choice_values, allowed_qualification_kinds, sort_order)
  on table public.ea_property_fields to authenticated;

create policy ea_property_types_select on public.ea_property_types
  for select to authenticated
  using (
    public.ad_has_level('AD', 'read')
    or ((public.ad_has_any_level('EA', 'read') or public.ad_has_level('GR', 'read')) and read_level <> 'confidential')
  );
create policy ea_property_types_insert on public.ea_property_types
  for insert to authenticated
  with check (public.ad_has_level('AD', 'edit') or (public.ad_has_level('EA', 'manage') and read_level <> 'confidential'));
create policy ea_property_types_update on public.ea_property_types
  for update to authenticated
  using (public.ad_has_level('AD', 'edit') or (public.ad_has_level('EA', 'manage') and read_level <> 'confidential'))
  with check (public.ad_has_level('AD', 'edit') or (public.ad_has_level('EA', 'manage') and read_level <> 'confidential'));

create policy ea_property_fields_select on public.ea_property_fields
  for select to authenticated
  using (exists (select 1 from public.ea_property_types t where t.id = property_type_id));
create policy ea_property_fields_insert on public.ea_property_fields
  for insert to authenticated
  with check (exists (
    select 1 from public.ea_property_types t
     where t.id = property_type_id
       and (public.ad_has_level('AD', 'edit') or (public.ad_has_level('EA', 'manage') and t.read_level <> 'confidential'))
  ));
create policy ea_property_fields_update on public.ea_property_fields
  for update to authenticated
  using (exists (
    select 1 from public.ea_property_types t
     where t.id = property_type_id
       and (public.ad_has_level('AD', 'edit') or (public.ad_has_level('EA', 'manage') and t.read_level <> 'confidential'))
  ))
  with check (exists (
    select 1 from public.ea_property_types t
     where t.id = property_type_id
       and (public.ad_has_level('AD', 'edit') or (public.ad_has_level('EA', 'manage') and t.read_level <> 'confidential'))
  ));
