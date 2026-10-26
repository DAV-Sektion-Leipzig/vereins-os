-- Anwesenheitserfassung Nachtrag v0.6 (spec.md EZ v0.6), spec T24; R33; Übergabe FI → EZ Z2.
-- Lesefunktion für Finanzen (nur FI-Reichweite „alle“, unabhängig von EZ-Rechten) und Kontrollliste der Kletterhalle
-- auch mit „FI verwalten“. Keine Teilnehmer:innen außer Anzahlen, keine Namen.

create function public.ez_settlement_basis(p_from date, p_to date, p_referate uuid[] default null)
returns table (
  event_id uuid, attendance_id uuid, kind public.ez_event_kind, span public.ez_span, remuneration_kind_id uuid,
  referat_id uuid, group_id uuid, group_name text, title text, organizer_person_id uuid, start_date date,
  start_time time, end_date date, end_time time, day_category public.ez_day_category, training_minutes int,
  person_id uuid, role public.ez_role, tk_plan_id uuid)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.ad_has_level('FI', 'read') then
    raise exception 'EZ_FORBIDDEN' using errcode = 'P0001';
  end if;
  if p_from is null or p_to is null or p_to < p_from then
    raise exception 'EZ_FIELD_REQUIRED' using errcode = 'P0001', detail = 'Zeitraum';
  end if;
  return query
  select e.id, a.id, e.kind, e.span, e.remuneration_kind_id, e.referat_id, e.group_id, g.name, e.title,
         e.organizer_person_id, e.start_date, e.start_time, e.end_date, e.end_time, e.day_category,
         case when e.kind = 'training' then (
           select (extract(epoch from (tt.ends_at - tt.starts_at)) / 60)::int
             from public.gr_training_times tt
            where tt.group_id = e.group_id
              and tt.weekday = extract(isodow from e.start_date)
              and tt.valid_from <= e.start_date
              and (tt.valid_to is null or tt.valid_to >= e.start_date)
            order by tt.valid_from desc
            limit 1) end,
         a.person_id, a.role, e.tk_plan_id
    from public.ez_events e
    join public.ez_attendances a on a.event_id = e.id
    left join public.gr_groups g on g.id = e.group_id
   where e.cancelled_at is null
     and e.remuneration_kind_id is not null
     and e.start_date between p_from and p_to
     and a.status = 'present'
     and a.role in ('trainer', 'helper')
     and (p_referate is null or e.referat_id = any (p_referate))
   order by e.start_date, e.id, a.person_id;
end;
$$;

revoke all on function public.ez_settlement_basis(date, date, uuid[]) from public, anon, authenticated;
grant execute on function public.ez_settlement_basis(date, date, uuid[]) to authenticated;

-- Kontrollliste Punktekonto Kletterhalle (US-EZ-16; Finanzen US-FI-17): zusätzlich mit „FI verwalten“
create or replace function public.ez_climbing_points_report(p_location uuid, p_from date, p_to date)
returns table (event_id uuid, start_date date, group_name text, participants_present int, trial_count int)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_all boolean := public.ad_has_level('EZ', 'read') or public.ad_has_level('FI', 'manage');
  v_referate uuid[] := public.ad_my_referate('EZ', 'read');
begin
  if not exists (select 1 from public.ad_locations l where l.id = p_location and l.has_climbing_points) then
    raise exception 'EZ_LOCATION_NO_POINTS' using errcode = 'P0001';
  end if;
  return query
  select v.id, v.start_date, public.ez_group_label(v.id, v.group_id), v.present_participant, v.trial_count
    from public.ez_v_events v
   where v.kind = 'training'
     and v.location_id = p_location
     and not v.is_cancelled
     and (v_all or v.referat_id = any (v_referate))
     and (p_from is null or v.start_date >= p_from)
     and (p_to is null or v.start_date <= p_to)
   order by v.start_date, public.ez_group_label(v.id, v.group_id);
end;
$$;
