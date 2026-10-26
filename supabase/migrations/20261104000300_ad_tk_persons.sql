-- Nachtrag v0.9 und v0.12 (spec.md AD v0.12.0), spec T62 und Übergabe TK v1.8 Punkte 15, 16; R47, R47a, R48, R59.
-- Namen, Suche und Lizenzen für die Planungshilfe; Anlegen und Wieder-aktiv-Eintragen von Personen aus der Planung:
--   tk_person_visible        Platzhalter; die erste Migration der Planungshilfe ersetzt ihn (gleiche Signatur)
--   ea_person_names          zusätzlich über tk_person_visible
--   ea_search_active_persons auch mit TK ≥ bearbeiten
--   ea_person_licenses       neu: Lizenzen ausgewählter Personen mit Erwerbsdatum (R47, R47a)
--   ea_create_path           zusätzlicher TK-Weg (R59); created_in = 'TK'
--   ad_find_similar_persons  auch mit TK ≥ bearbeiten

create function public.tk_person_visible(p_person uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select false;
$$;

revoke all on function public.tk_person_visible(uuid) from public, anon, authenticated;
grant execute on function public.tk_person_visible(uuid) to authenticated;

-- Namen zu IDs (R44, R48, R56): Pfade AD, EA, GR sowie Anwesenheitserfassung, Finanzen und Planungshilfe
create or replace function public.ea_person_names(p_ids uuid[])
returns table (id uuid, first_name text, preferred_name text, last_name text)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if coalesce(cardinality(p_ids), 0) > 500 then
    raise exception 'AD_TOO_MANY_IDS' using errcode = 'P0001';
  end if;
  return query
  select p.id, p.first_name, p.preferred_name, p.last_name
    from public.ea_persons p
   where p.id = any (coalesce(p_ids, '{}'))
     and p.kind = 'human'
     and (public.ea_person_visible(p.id) or public.ez_person_visible(p.id) or public.fi_person_visible(p.id)
          or public.tk_person_visible(p.id));
end;
$$;

-- Suche über alle Aktiven: zusätzlich für die Planungshilfe (Leitung wählen, R48)
create or replace function public.ea_search_active_persons(p_query text, p_limit int default 20)
returns table (id uuid, first_name text, preferred_name text, last_name text)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_query text := btrim(regexp_replace(coalesce(p_query, ''), '\s+', ' ', 'g'));
  v_words text[];
begin
  if not (public.ad_has_any_level('EZ', 'edit') or public.ad_has_any_level('TK', 'edit')) then
    raise exception 'AD_FORBIDDEN' using errcode = 'P0001';
  end if;
  if char_length(v_query) < 2 then
    raise exception 'AD_SEARCH_TOO_SHORT' using errcode = 'P0001';
  end if;
  if p_limit is null or p_limit not between 1 and 50 then
    raise exception 'AD_BAD_REQUEST' using errcode = 'P0001';
  end if;

  -- Platzhalter von LIKE maskieren
  select array_agg('%' || replace(replace(replace(w, '\', '\\'), '%', '\%'), '_', '\_') || '%')
    into v_words
    from unnest(string_to_array(v_query, ' ')) as w;

  return query
  select p.id, p.first_name, p.preferred_name, p.last_name
    from public.ea_persons p
   where p.kind = 'human'
     and p.volunteer_status = 'active'
     and not exists (
       select 1 from unnest(v_words) as w
        where not (p.first_name ilike w or p.last_name ilike w or coalesce(p.preferred_name, '') ilike w)
     )
   order by lower(p.last_name), lower(coalesce(p.preferred_name, p.first_name)), p.id
   limit p_limit;
end;
$$;

-- Lizenzen für die Planungshilfe (R47, R47a): nur Menschen mit Ehrenamtsstatus „aktiv“ oder „ruhend“, nur Eigenschaften
-- der Art Lizenz mit Lesestufe „alle mit Zugriff“ und Qualifikationsart vom Typ Lizenz. Geliefert werden die am Datum
-- gültigen Lizenzen und die im selben Kalenderhalbjahr nach dem Datum erworbenen. Keine Lizenznummer.
create function public.ea_person_licenses(p_person_ids uuid[], p_date date)
returns table (
  person_id uuid, qualification_type_id uuid, qualification_code text, qualification_name text,
  valid_from date, valid_until date, is_fundable boolean, valid_on_date boolean
)
language plpgsql
stable
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_date date := coalesce(p_date, current_date);
  v_half_end date;
begin
  if not public.ad_has_any_level('TK', 'read') then
    raise exception 'AD_FORBIDDEN' using errcode = 'P0001';
  end if;
  if coalesce(cardinality(p_person_ids), 0) > 50 then
    raise exception 'AD_TOO_MANY_IDS' using errcode = 'P0001';
  end if;
  v_half_end := case when extract(month from v_date) <= 6
                     then make_date(extract(year from v_date)::int, 6, 30)
                     else make_date(extract(year from v_date)::int, 12, 31) end;

  return query
  select l.person_id, q.id, q.code, q.name, l.valid_from, x.valid_until,
         coalesce(q.dosb_eligible, false),
         l.valid_from <= v_date and (x.valid_until is null or x.valid_until >= v_date)
    from public.ea_properties l
    join public.ea_property_types lt on lt.id = l.property_type_id and lt.system_key = 'license' and lt.read_level = 'all'
    join public.ea_persons p on p.id = l.person_id and p.kind = 'human' and p.volunteer_status in ('active', 'dormant')
    join public.ad_qualification_types q on q.id = nullif(l.field_values ->> 'qualification_type', '')::uuid
                                        and q.kind = 'license'
    cross join lateral (select nullif(l.field_values ->> 'valid_until', '')::date as valid_until) x
   where l.person_id = any (coalesce(p_person_ids, '{}'))
     and l.valid_from <= v_half_end
     and (l.valid_to is null or l.valid_to >= v_date)
     and (x.valid_until is null or x.valid_until >= v_date or l.valid_from > v_date)
   order by l.person_id, l.valid_from;
end;
$$;

revoke all on function public.ea_person_licenses(uuid[], date) from public, anon, authenticated;
grant execute on function public.ea_person_licenses(uuid[], date) to authenticated;

-- Anlagemodul TK (R59)
alter table public.ea_persons drop constraint ea_persons_created_in_check;
alter table public.ea_persons
  add constraint ea_persons_created_in_check check (created_in in ('AD', 'EA', 'GR', 'EZ', 'TK', 'script'));

-- EA-Weg zuerst; scheitert er nur an den Rechten bzw. am Referat, gilt der EZ-Weg und danach der TK-Weg (R45, R59):
-- Referat Pflicht, nur Funktion Helfer:in, Referat aus den eigenen EZ- bzw. TK-Referaten (Reichweite „Referat“).
-- Rückgabe 'EA', 'EZ' oder 'TK'.
create or replace function public.ea_create_path(p_property_type uuid, p_referat uuid, p_field_values jsonb)
returns text
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_ea_error text;
  v_ez_all boolean := public.ad_has_level('EZ', 'edit');
  v_ez_referate uuid[] := public.ad_my_referate('EZ', 'edit');
  v_tk_all boolean := public.ad_has_level('TK', 'edit');
  v_tk_referate uuid[] := public.ad_my_referate('TK', 'edit');
  v_ez_any boolean;
  v_tk_any boolean;
  v_ez_ok boolean;
  v_tk_ok boolean;
begin
  begin
    perform public.ea_check_create(p_property_type, p_referat);
    return 'EA';
  exception when sqlstate 'P0001' then
    v_ea_error := sqlerrm;
  end;

  v_ez_any := v_ez_all or cardinality(v_ez_referate) > 0;
  v_tk_any := v_tk_all or cardinality(v_tk_referate) > 0;
  v_ez_ok := v_ez_all or p_referat = any (v_ez_referate);
  v_tk_ok := v_tk_all or p_referat = any (v_tk_referate);

  -- Der EZ- bzw. TK-Weg greift nur, wenn der EA-Weg an fehlenden Rechten (kein EA-Recht) oder am Referat scheitert
  -- und die Rechte dafür reichen; sonst gilt die Meldung des EA-Wegs (z. B. vertrauliche Art, Bezugsart).
  if not (v_ez_any or v_tk_any)
     or not (v_ea_error = 'EA_CREATE_FORBIDDEN'
             or (v_ea_error = 'EA_RELATION_FOREIGN_REFERAT' and coalesce(v_ez_ok or v_tk_ok, false))) then
    raise exception '%', v_ea_error using errcode = 'P0001';
  end if;

  if p_referat is null
     or p_property_type is distinct from (select t.id from public.ea_property_types t where t.system_key = 'function')
     or p_field_values is distinct from '{"function": "Helfer:in"}'::jsonb then
    raise exception 'EA_CREATE_FORBIDDEN' using errcode = 'P0001';
  end if;

  if coalesce(v_ez_ok, false) then
    return 'EZ';
  end if;
  if coalesce(v_tk_ok, false) then
    return 'TK';
  end if;
  raise exception 'EA_RELATION_FOREIGN_REFERAT' using errcode = 'P0001';
end;
$$;

revoke all on function public.ea_create_path(uuid, uuid, jsonb) from public, anon, authenticated;

-- Dublettenprüfung auch für die Planungshilfe (R59)
create or replace function public.ad_find_similar_persons(p_first text, p_last text, p_email text)
returns table (person_id uuid, first_name text, last_name text, preferred_name text, birth_year int,
               volunteer_status public.ea_volunteer_status, left_since date, is_visible boolean)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_birth_type uuid;
  v_birth_level public.ea_read_level;
  v_show_birth boolean := false;
  v_email text := lower(btrim(coalesce(p_email, '')));
begin
  if not (public.ad_has_level('AD', 'edit') or public.ad_has_any_level('EA', 'edit') or public.ad_has_level('GR', 'edit')
          or public.ad_has_any_level('EZ', 'edit') or public.ad_has_any_level('TK', 'edit')) then
    raise exception 'AD_FORBIDDEN' using errcode = 'P0001';
  end if;

  -- Geburtsjahr nur nach der Lesestufe der Art Geburtsdatum (R40, Ü2)
  select t.id, t.read_level into v_birth_type, v_birth_level
    from public.ea_property_types t where t.system_key = 'birth_date';
  v_show_birth := case v_birth_level
    when 'all' then true
    when 'office' then public.ad_has_level('AD', 'read') or public.ad_has_level('EA', 'manage')
                       or public.ad_has_level('GR', 'manage')
    when 'confidential' then public.ad_has_level('AD', 'read')
    else false
  end;

  return query
  select p.id, p.first_name, p.last_name, p.preferred_name,
         case when v_show_birth then (
           select extract(year from (b.field_values ->> 'date')::date)::int
             from public.ea_properties b
            where b.person_id = p.id
              and b.property_type_id = v_birth_type
              and b.field_values ? 'date'
            order by (b.valid_from <= current_date and (b.valid_to is null or b.valid_to >= current_date)) desc,
                     b.valid_from desc
            limit 1
         ) end,
         p.volunteer_status,
         case when p.volunteer_status = 'left' then p.volunteer_status_since end,
         public.ea_person_visible(p.id)
    from public.ea_persons p
   where p.kind = 'human'
     and (
       (lower(btrim(p.last_name)) = lower(btrim(coalesce(p_last, '')))
        and (public.ad_first_names_match(p_first, p.first_name)
             or public.ad_first_names_match(p_first, p.preferred_name)))
       or (v_email <> '' and (
             exists (select 1 from public.ad_accesses a
                      where a.person_id = p.id and lower(a.login_email::text) = v_email)
             or exists (
               select 1
                 from public.ea_properties c
                 join public.ea_property_types ct on ct.id = c.property_type_id and ct.system_key = 'contact'
                where c.person_id = p.id
                  and (lower(c.field_values ->> 'email') = v_email or lower(c.field_values ->> 'dav_email') = v_email)
             )))
     )
   order by p.last_name, p.first_name;
end;
$$;
