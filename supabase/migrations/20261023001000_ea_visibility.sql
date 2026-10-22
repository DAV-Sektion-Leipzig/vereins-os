-- US-AD-23, spec T38: Sichtbarkeit von Personen und Eigenschaften je Pfad (R29, R32, R34, R39, R41, R42).
-- Pfade AD, EA (Reichweite alle bzw. Referat) und GR (Platzhalter bis zur ersten GR-Migration).
-- Ersetzt die Policies auf ea_persons aus 20261020000200 und die vorläufigen Policies aus …000600 und …000900.
-- Alle Funktionen security definer, stable, search_path = '' (research.md R-19).

-- Person hat heute eine gültige Eigenschaft mit Bezug auf eines der Referate
create function public.ea_person_in_referate(p_person uuid, p_referate uuid[])
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select cardinality(p_referate) > 0 and exists (
    select 1 from public.ea_properties p
     where p.person_id = p_person
       and p.related_referat_id = any (p_referate)
       and p.valid_from <= current_date
       and (p.valid_to is null or p.valid_to >= current_date)
  );
$$;

-- Pfad AD: der Admin sieht alle Personen aller Module (v0.7.1)
create function public.ea_person_visible_ad(p_person uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.ad_has_level('AD', 'read');
$$;

-- Pfad EA: Mensch mit Ehrenamtsstatus; „ausgeschieden“ nur mit EA = verwalten (R34);
-- Reichweite Referat: aktiv oder ruhend und heute gültige Eigenschaft mit Bezug auf ein eigenes Referat
create function public.ea_person_visible_ea(p_person uuid, p_min public.ad_level default 'read')
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.ea_persons pe
     where pe.id = p_person
       and pe.kind = 'human'
       and pe.volunteer_status is not null
       and (
         (public.ad_has_level('EA', p_min)
          and (pe.volunteer_status <> 'left' or public.ad_has_level('EA', 'manage')))
         or (pe.volunteer_status <> 'left'
             and public.ea_person_in_referate(p_person, public.ad_my_referate('EA', p_min)))
       )
  );
$$;

-- Pfad GR: Platzhalter; die erste GR-Migration ersetzt die Funktion mit gleicher Signatur [ANNAHME v0.7]
create function public.gr_person_visible(p_person uuid, p_min public.ad_level default 'read')
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select false;
$$;

-- Oder-Verknüpfung der Pfade; Grundlage der Policies (R32)
create function public.ea_person_visible(p_person uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.ea_person_visible_ad(p_person)
      or public.ea_person_visible_ea(p_person)
      or public.gr_person_visible(p_person);
$$;

-- Lesestufe je Pfad (R29)
create function public.ea_property_readable(p_property_type uuid, p_person uuid)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_level public.ea_read_level;
begin
  select t.read_level into v_level from public.ea_property_types t where t.id = p_property_type;
  if v_level is null then
    return false;
  end if;
  if public.ea_person_visible_ad(p_person) then
    return true;
  end if;
  if v_level = 'confidential' then
    return false;
  end if;
  if v_level = 'office' then
    return (public.ad_has_level('EA', 'manage') and public.ea_person_visible_ea(p_person))
        or (public.ad_has_level('GR', 'manage') and public.gr_person_visible(p_person));
  end if;
  return public.ea_person_visible_ea(p_person) or public.gr_person_visible(p_person);
end;
$$;

-- Schreiben setzt Lesen im selben Pfad voraus (R42); vertraulich nur AD ≥ edit; Bezug Gruppe nur über GR (R39);
-- im Pfad EA mit Reichweite Referat nur mit Bezug auf ein eigenes Referat (R41)
create function public.ea_property_writable(p_property_type uuid, p_person uuid, p_referat uuid)
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

  v_gr := v_level <> 'confidential'
          and (v_level = 'all' or public.ad_has_level('GR', 'manage'))
          and public.ad_has_level('GR', 'edit')
          and public.gr_person_visible(p_person, 'edit');

  if v_relation = 'group' then
    return v_gr;
  end if;

  if public.ad_has_level('AD', 'edit') then
    return true;
  end if;
  if v_level = 'confidential' then
    return false;
  end if;

  v_ea := (v_level = 'all' or public.ad_has_level('EA', 'manage'))
          and public.ea_person_visible_ea(p_person, 'edit')
          and (public.ad_has_level('EA', 'edit')
               or (p_referat is not null and p_referat = any (public.ad_my_referate('EA', 'edit'))));

  return v_ea or v_gr;
end;
$$;

-- Mengenfunktionen für die Policies (research.md R-19): dieselben Regeln wie ea_person_visible_ea,
-- gr_person_visible und ea_property_readable, aber einmal je Abfrage statt je Zeile ausgewertet.

-- Personen im Pfad EA
create function public.ea_person_ids_ea(p_min public.ad_level default 'read')
returns setof uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_all boolean := public.ad_has_level('EA', p_min);
  v_manage boolean := public.ad_has_level('EA', 'manage');
  v_referate uuid[] := public.ad_my_referate('EA', p_min);
begin
  if not v_all and cardinality(v_referate) = 0 then
    return;
  end if;
  return query
  select pe.id
    from public.ea_persons pe
   where pe.kind = 'human'
     and pe.volunteer_status is not null
     and (
       (v_all and (pe.volunteer_status <> 'left' or v_manage))
       or (pe.volunteer_status <> 'left' and exists (
             select 1 from public.ea_properties p
              where p.person_id = pe.id
                and p.related_referat_id = any (v_referate)
                and p.valid_from <= current_date
                and (p.valid_to is null or p.valid_to >= current_date)))
     );
end;
$$;

-- Personen im Pfad GR; leitet sich aus gr_person_visible ab, das die erste GR-Migration ersetzt
create function public.gr_person_ids(p_min public.ad_level default 'read')
returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
  select pe.id from public.ea_persons pe
   where public.ad_has_level('GR', p_min) and public.gr_person_visible(pe.id, p_min);
$$;

-- Eigenschaftsarten, deren Lesestufe im Pfad EA bzw. GR lesbar ist (R29; vertraulich nur Pfad AD)
create function public.ea_readable_type_ids(p_path text)
returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
  select t.id from public.ea_property_types t
   where t.read_level = 'all'
      or (t.read_level = 'office' and public.ad_has_level(p_path, 'manage'));
$$;

revoke all on function public.ea_person_ids_ea(public.ad_level) from public, anon, authenticated;
revoke all on function public.gr_person_ids(public.ad_level) from public, anon, authenticated;
revoke all on function public.ea_readable_type_ids(text) from public, anon, authenticated;
grant execute on function public.ea_person_ids_ea(public.ad_level) to authenticated;
grant execute on function public.gr_person_ids(public.ad_level) to authenticated;
grant execute on function public.ea_readable_type_ids(text) to authenticated;

revoke all on function public.ea_person_in_referate(uuid, uuid[]) from public, anon, authenticated;
revoke all on function public.ea_person_visible_ad(uuid) from public, anon, authenticated;
revoke all on function public.ea_person_visible_ea(uuid, public.ad_level) from public, anon, authenticated;
revoke all on function public.gr_person_visible(uuid, public.ad_level) from public, anon, authenticated;
revoke all on function public.ea_person_visible(uuid) from public, anon, authenticated;
revoke all on function public.ea_property_readable(uuid, uuid) from public, anon, authenticated;
revoke all on function public.ea_property_writable(uuid, uuid, uuid) from public, anon, authenticated;
grant execute on function public.ea_person_in_referate(uuid, uuid[]) to authenticated;
grant execute on function public.ea_person_visible_ad(uuid) to authenticated;
grant execute on function public.ea_person_visible_ea(uuid, public.ad_level) to authenticated;
grant execute on function public.gr_person_visible(uuid, public.ad_level) to authenticated;
grant execute on function public.ea_person_visible(uuid) to authenticated;
grant execute on function public.ea_property_readable(uuid, uuid) to authenticated;
grant execute on function public.ea_property_writable(uuid, uuid, uuid) to authenticated;

-- ea_persons: Lesen über die Pfade; direkt anlegen nur AD (EA über ea_create_volunteer); ändern mit ≥ edit im Pfad
drop policy ea_persons_select on public.ea_persons;
drop policy ea_persons_insert on public.ea_persons;
drop policy ea_persons_update on public.ea_persons;

create policy ea_persons_select on public.ea_persons
  for select to authenticated
  using (
    (select public.ad_has_level('AD', 'read'))
    or id in (select public.ea_person_ids_ea('read'))
    or id in (select public.gr_person_ids('read'))
  );
create policy ea_persons_insert on public.ea_persons
  for insert to authenticated
  with check (public.ad_has_level('AD', 'edit') and created_in = 'AD' and volunteer_status is null);
create policy ea_persons_update on public.ea_persons
  for update to authenticated
  using (public.ad_has_level('AD', 'edit') or public.ea_person_visible_ea(id, 'edit') or public.gr_person_visible(id, 'edit'))
  with check (public.ad_has_level('AD', 'edit') or public.ea_person_visible_ea(id, 'edit') or public.gr_person_visible(id, 'edit'));

-- Historie des Ehrenamtsstatus: wie die Person
drop policy ea_volunteer_status_history_select on public.ea_volunteer_status_history;
create policy ea_volunteer_status_history_select on public.ea_volunteer_status_history
  for select to authenticated
  using ((select public.ad_has_level('AD', 'read')) or person_id in (select public.ea_person_ids_ea('read'))
         or person_id in (select public.gr_person_ids('read')));

-- Eigenschaften: Person lesbar und Lesestufe erlaubt; schreiben nach R42 für alte und neue Fassung
drop policy ea_properties_select on public.ea_properties;
drop policy ea_properties_insert on public.ea_properties;
drop policy ea_properties_update on public.ea_properties;

create policy ea_properties_select on public.ea_properties
  for select to authenticated
  using (
    (select public.ad_has_level('AD', 'read'))
    or (person_id in (select public.ea_person_ids_ea('read'))
        and property_type_id in (select public.ea_readable_type_ids('EA')))
    or (person_id in (select public.gr_person_ids('read'))
        and property_type_id in (select public.ea_readable_type_ids('GR')))
  );
create policy ea_properties_insert on public.ea_properties
  for insert to authenticated
  with check (public.ea_property_writable(property_type_id, person_id, related_referat_id));
create policy ea_properties_update on public.ea_properties
  for update to authenticated
  using (public.ea_property_writable(property_type_id, person_id, related_referat_id))
  with check (public.ea_property_writable(property_type_id, person_id, related_referat_id));

-- Historie einer Eigenschaft: wie die Eigenschaft
drop policy ea_property_history_select on public.ea_property_history;
create policy ea_property_history_select on public.ea_property_history
  for select to authenticated
  using (exists (select 1 from public.ea_properties p where p.id = property_id));
