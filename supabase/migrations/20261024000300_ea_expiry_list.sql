-- US-EA-02, 03, 11, 12, spec T4 (EA spec.md 2.3): Ablaufstatus, Vorbelegung „gültig bis“, View ea_v_expiry,
-- Liste der Aktiven ea_volunteer_list, Index auf valid_until (research.md R-EA-06, R-EA-07).
-- Alle Objekte security invoker: welche Zeilen sichtbar sind, entscheidet die RLS der Administration.

-- Ablaufstatus (R9): Grenze 3 Monate
create function public.ea_expiry_status(p_valid_until date, p_today date default current_date)
returns text
language sql
immutable
set search_path = public
as $$
  select case
    when p_valid_until is null then 'none'
    when p_valid_until < p_today then 'expired'
    when p_valid_until <= (p_today + interval '3 months')::date then 'expiring'
    else 'valid'
  end;
$$;

-- Vorbelegung „gültig bis“ (R5): 31.12. des Jahres (letzte Fortbildung, sonst gültig von) + Gültigkeitsdauer
create function public.ea_default_valid_until(p_qualification_type uuid, p_valid_from date, p_last_training date default null)
returns date
language sql
stable
security invoker
set search_path = public
as $$
  select case
    when q.validity_years is null then null
    else make_date(extract(year from coalesce(p_last_training, p_valid_from))::int + q.validity_years, 12, 31)
  end
    from public.ad_qualification_types q
   where q.id = p_qualification_type;
$$;

-- Index für die Stichtagsliste und den Filter nach Ablauf
create index ea_properties_valid_until_idx on public.ea_properties ((field_values ->> 'valid_until'))
  where field_values ? 'valid_until';

-- Eine Zeile je aktueller Eigenschaft mit Ablaufdatum (Lizenz, Qualifikation, Führungszeugnis-Einsicht nach R10)
-- von Personen mit Status aktiv oder ruhend. RLS auf ea_properties und ea_persons gilt für den Aufrufer.
create view public.ea_v_expiry
with (security_invoker = true)
as
select p.person_id,
       p.id as property_id,
       p.property_type_id,
       t.system_key,
       t.system_key as kind,
       q.id as qualification_type_id,
       q.code as qualification_code,
       q.name as qualification_name,
       q.discipline,
       vu.valid_until,
       public.ea_expiry_status(vu.valid_until) as expiry_status
  from public.ea_properties p
  join public.ea_property_types t
    on t.id = p.property_type_id and t.system_key in ('license', 'qualification', 'police_clearance')
  join public.ea_persons pe
    on pe.id = p.person_id and pe.volunteer_status in ('active', 'dormant')
  cross join lateral (
    select case
      when t.system_key = 'police_clearance'
        then ((p.field_values ->> 'issued_on')::date + interval '3 years')::date
      else (p.field_values ->> 'valid_until')::date
    end as valid_until
  ) as vu
  left join public.ad_qualification_types q
    on t.system_key <> 'police_clearance'
   and q.id = nullif(p.field_values ->> 'qualification_type', '')::uuid
 where p.valid_from <= current_date
   and (p.valid_to is null or p.valid_to >= current_date);

comment on view public.ea_v_expiry is
  'Ablauf von Lizenzen, Qualifikationen und Führungszeugnis-Einsicht (R9, R10); security invoker, Zeilen nach RLS.';

-- Liste der Aktiven mit Suche, Filtern und Paginierung (spec.md EA 2.3)
create function public.ea_volunteer_list(
  p_search text default null,
  p_status public.ea_volunteer_status[] default '{active,dormant}',
  p_referate uuid[] default null,
  p_function text default null,
  p_position text default null,
  p_gremium uuid default null,
  p_qualification_type uuid default null,
  p_discipline text default null,
  p_expiry text[] default null,
  p_trainer_without_license boolean default false,
  p_without_assignment boolean default false,
  p_limit int default 50,
  p_offset int default 0)
returns table (
  id uuid, first_name text, preferred_name text, last_name text,
  volunteer_status public.ea_volunteer_status, volunteer_status_since date,
  referate text[], functions text[], positions text[], license_codes text[],
  worst_expiry text, trainer_without_license boolean, total_count bigint)
language sql
stable
security invoker
set search_path = public
as $$
  with base as (
    select pe.id as pid, pe.first_name as pfirst, pe.preferred_name as ppreferred, pe.last_name as plast,
           pe.volunteer_status as pstatus, pe.volunteer_status_since as psince
      from public.ea_persons pe
     where pe.kind = 'human'
       and pe.volunteer_status = any (coalesce(p_status, '{active,dormant}'::public.ea_volunteer_status[]))
       and (nullif(btrim(p_search), '') is null
            or pe.first_name ilike '%' || btrim(p_search) || '%'
            or pe.preferred_name ilike '%' || btrim(p_search) || '%'
            or pe.last_name ilike '%' || btrim(p_search) || '%')
  ),
  cur as (
    select p.person_id, t.system_key, p.field_values, p.related_referat_id, p.related_gremium_id,
           r.name as referat_name, r.sort_order as referat_sort
      from public.ea_properties p
      join public.ea_property_types t
        on t.id = p.property_type_id and t.system_key in ('function', 'position', 'committee', 'license')
      left join public.ea_referate r on r.id = p.related_referat_id
     where p.person_id in (select b.pid from base b)
       and p.valid_from <= current_date
       and (p.valid_to is null or p.valid_to >= current_date)
  ),
  exp as (
    select e.person_id,
           max(case e.expiry_status when 'expired' then 3 when 'expiring' then 2 when 'valid' then 1 else 0 end) as rank
      from public.ea_v_expiry e
     where e.person_id in (select b.pid from base b)
     group by e.person_id
  ),
  agg as (
    select b.pid, b.pfirst, b.ppreferred, b.plast, b.pstatus, b.psince,
           (select coalesce(array_agg(x.name order by x.sort_order, x.name), '{}'::text[])
              from (select distinct c.referat_name as name, c.referat_sort as sort_order
                      from cur c
                     where c.person_id = b.pid and c.system_key in ('function', 'position')
                       and c.referat_name is not null) as x) as referate,
           (select coalesce(array_agg(x.v order by x.sort_order, x.v), '{}'::text[])
              from (select distinct (c.field_values ->> 'function') || coalesce(' – ' || c.referat_name, '') as v,
                                    coalesce(c.referat_sort, 0) as sort_order
                      from cur c
                     where c.person_id = b.pid and c.system_key = 'function') as x) as functions,
           (select coalesce(array_agg(x.v order by x.sort_order, x.v), '{}'::text[])
              from (select distinct (c.field_values ->> 'position') || coalesce(' – ' || c.referat_name, '') as v,
                                    coalesce(c.referat_sort, 0) as sort_order
                      from cur c
                     where c.person_id = b.pid and c.system_key = 'position') as x) as positions,
           (select coalesce(array_agg(distinct q.code order by q.code), '{}'::text[])
              from cur c
              join public.ad_qualification_types q on q.id = nullif(c.field_values ->> 'qualification_type', '')::uuid
             where c.person_id = b.pid and c.system_key = 'license') as license_codes,
           case coalesce((select e.rank from exp e where e.person_id = b.pid), 0)
             when 3 then 'expired' when 2 then 'expiring' when 1 then 'valid' else 'none' end as worst_expiry,
           (exists (select 1 from cur c
                     where c.person_id = b.pid and c.system_key = 'function'
                       and c.field_values ->> 'function' = 'Trainer:in')
            and not exists (select 1 from public.ea_v_expiry e
                             where e.person_id = b.pid and e.kind = 'license'
                               and e.valid_until >= current_date)) as trainer_without_license
      from base b
  ),
  filtered as (
    select a.*
      from agg a
     where (p_function is null or exists (
              select 1 from cur c
               where c.person_id = a.pid and c.system_key = 'function'
                 and c.field_values ->> 'function' = p_function
                 and (p_referate is null or c.related_referat_id = any (p_referate))))
       and (p_position is null or exists (
              select 1 from cur c
               where c.person_id = a.pid and c.system_key = 'position'
                 and c.field_values ->> 'position' = p_position
                 and (p_referate is null or c.related_referat_id = any (p_referate))))
       and (p_referate is null or p_function is not null or p_position is not null or exists (
              select 1 from cur c
               where c.person_id = a.pid and c.system_key in ('function', 'position')
                 and c.related_referat_id = any (p_referate)))
       and (p_gremium is null or exists (
              select 1 from cur c
               where c.person_id = a.pid and c.system_key = 'committee' and c.related_gremium_id = p_gremium))
       and (p_qualification_type is null or exists (
              select 1 from public.ea_v_expiry e
               where e.person_id = a.pid and e.qualification_type_id = p_qualification_type))
       and (nullif(btrim(p_discipline), '') is null or exists (
              select 1 from public.ea_v_expiry e
               where e.person_id = a.pid and e.discipline = btrim(p_discipline)))
       and (p_expiry is null or a.worst_expiry = any (p_expiry))
       and (not coalesce(p_trainer_without_license, false) or a.trainer_without_license)
       and (not coalesce(p_without_assignment, false)
            or (a.pstatus = 'active' and not exists (
                  select 1 from cur c
                   where c.person_id = a.pid and c.system_key in ('function', 'position', 'committee'))))
  )
  select f.pid, f.pfirst, f.ppreferred, f.plast, f.pstatus, f.psince,
         f.referate, f.functions, f.positions, f.license_codes, f.worst_expiry, f.trainer_without_license,
         count(*) over () as total_count
    from filtered f
   order by lower(f.plast), lower(coalesce(f.ppreferred, f.pfirst))
   limit greatest(1, least(coalesce(p_limit, 50), 200))
  offset greatest(0, coalesce(p_offset, 0));
$$;

comment on function public.ea_volunteer_list is
  'Übersicht der Aktiven (EA spec.md 2.3): Suche, Filter, Sortierung, 1–200 je Seite; security invoker.';

revoke all on function public.ea_expiry_status(date, date) from public, anon;
revoke all on function public.ea_default_valid_until(uuid, date, date) from public, anon;
revoke all on function public.ea_volunteer_list(text, public.ea_volunteer_status[], uuid[], text, text, uuid, uuid, text, text[], boolean, boolean, int, int)
  from public, anon;
revoke all on public.ea_v_expiry from public, anon;
grant execute on function public.ea_expiry_status(date, date) to authenticated;
grant execute on function public.ea_default_valid_until(uuid, date, date) to authenticated;
grant execute on function public.ea_volunteer_list(text, public.ea_volunteer_status[], uuid[], text, text, uuid, uuid, text, text[], boolean, boolean, int, int)
  to authenticated;
grant select on public.ea_v_expiry to authenticated;
