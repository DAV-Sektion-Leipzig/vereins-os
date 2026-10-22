-- US-AD-07, US-AD-25, spec T8, T43 (Kern v0.7, v0.7.2, v0.7.3): Dublettenprüfung modulübergreifend.
-- Namensregel R3a über ad_first_names_match; Trefferdaten nur nach R40; Geburtsjahr nur nach der Lesestufe
-- der Eigenschaftsart mit system_key = 'birth_date' (Ü2). Erweiterung für EZ folgt mit spec T53.

-- Vornamen passen zusammen (R3a): Trigramm-Ähnlichkeit ≥ 0,3, einer im anderen enthalten
-- oder gemeinsame zusammenhängende Zeichenfolge von mindestens 3 Zeichen (z. B. Toni/Anton: „ton“)
create function public.ad_first_names_match(p_a text, p_b text)
returns boolean
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_a text := lower(btrim(coalesce(p_a, '')));
  v_b text := lower(btrim(coalesce(p_b, '')));
  v_short text;
  v_long text;
begin
  if v_a = '' or v_b = '' then
    return false;
  end if;
  if extensions.similarity(v_a, v_b) >= 0.3 or strpos(v_a, v_b) > 0 or strpos(v_b, v_a) > 0 then
    return true;
  end if;
  if char_length(v_a) <= char_length(v_b) then
    v_short := v_a; v_long := v_b;
  else
    v_short := v_b; v_long := v_a;
  end if;
  return exists (
    select 1 from generate_series(1, char_length(v_short) - 2) as i
     where strpos(v_long, substr(v_short, i, 3)) > 0
  );
end;
$$;

revoke all on function public.ad_first_names_match(text, text) from public, anon, authenticated;
grant execute on function public.ad_first_names_match(text, text) to authenticated;

create function public.ad_find_similar_persons(p_first text, p_last text, p_email text)
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
  if not (public.ad_has_level('AD', 'edit') or public.ad_has_any_level('EA', 'edit') or public.ad_has_level('GR', 'edit')) then
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

revoke all on function public.ad_find_similar_persons(text, text, text) from public, anon, authenticated;
grant execute on function public.ad_find_similar_persons(text, text, text) to authenticated;
