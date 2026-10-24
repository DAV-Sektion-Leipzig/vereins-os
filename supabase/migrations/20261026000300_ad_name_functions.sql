-- Nachtrag v0.8 (spec.md AD v0.9.4, Nachtrag v0.8.1), spec T52; US-AD-29; Übergabe EZ A3; R44.
-- Namen für die Anwesenheitserfassung statt eines vierten Lesepfads: ez_person_visible (Platzhalter),
-- ea_person_names, ea_search_active_persons. Liefern nur Vorname, Rufname, Nachname.

-- Platzhalter; die erste Migration der Anwesenheitserfassung ersetzt die Funktion mit derselben Signatur
-- (Inhalt nach spec.md EZ v0.4 Abschnitt 2: Person kommt in einem lesbaren Einsatz vor).
create function public.ez_person_visible(p_person uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select false;
$$;

revoke all on function public.ez_person_visible(uuid) from public, anon, authenticated;
grant execute on function public.ez_person_visible(uuid) to authenticated;

-- Namen zu IDs: nur Menschen, die über einen Pfad (R32) oder über die Anwesenheitserfassung sichtbar sind;
-- andere IDs werden ohne Fehler ausgelassen. Höchstens 500 IDs (AD_TOO_MANY_IDS, allgemeine Meldung).
create function public.ea_person_names(p_ids uuid[])
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
     and (public.ea_person_visible(p.id) or public.ez_person_visible(p.id));
end;
$$;

revoke all on function public.ea_person_names(uuid[]) from public, anon, authenticated;
grant execute on function public.ea_person_names(uuid[]) to authenticated;

-- Suche über alle Aktiven (Ehrenamtsstatus „aktiv“) für die organisierende Person und Vertretungen.
-- Erlaubt mit EZ ≥ bearbeiten (Reichweite alle oder Referat); jedes Wort des Suchbegriffs muss als Teilwort
-- in Vor-, Ruf- oder Nachname vorkommen (ohne Groß-/Kleinschreibung).
create function public.ea_search_active_persons(p_query text, p_limit int default 20)
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
  if not public.ad_has_any_level('EZ', 'edit') then
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

revoke all on function public.ea_search_active_persons(text, int) from public, anon, authenticated;
grant execute on function public.ea_search_active_persons(text, int) to authenticated;

-- Index für die Teilwortsuche im Nachnamen (Vor- und Rufname haben bereits Trigramm-Indizes)
create index ea_persons_last_name_trgm on public.ea_persons using gin (last_name extensions.gin_trgm_ops);
