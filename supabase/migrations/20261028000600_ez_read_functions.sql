-- Anwesenheitserfassung (EZ), spec T6; spec.md EZ v0.5 Abschnitt 2 „Views“ und „Lesen“, US-EZ-14, -15, -16;
-- research.md R-EZ-13; contracts/database-api.md.

-- Einsätze mit Zählern; security_invoker, damit RLS auf ez_events greift
create view public.ez_v_events with (security_invoker = true) as
select e.id, e.kind, e.span, e.referat_id, e.group_id, e.title, e.organizer_person_id, e.start_date, e.start_time,
       e.end_date, e.end_time, e.day_category, e.location_id, e.remark, e.client_request_id, e.tk_plan_id,
       e.cancelled_at, e.cancelled_by, e.cancelled_by_person_id, e.cancel_reason,
       e.created_at, e.created_by, e.created_by_person_id, e.updated_at, e.updated_by, e.updated_by_person_id,
       e.cancelled_at is not null as is_cancelled,
       coalesce(c.present_trainer, 0) as present_trainer,
       coalesce(c.present_helper, 0) as present_helper,
       coalesce(c.present_participant, 0) as present_participant,
       coalesce(c.registered_count, 0) as registered_count,
       coalesce(c.absent_count, 0) as absent_count,
       (select count(*)::int from public.ez_trial_participants t where t.event_id = e.id) as trial_count
  from public.ez_events e
  left join lateral (
    select count(*) filter (where a.status = 'present' and a.role = 'trainer')::int as present_trainer,
           count(*) filter (where a.status = 'present' and a.role = 'helper')::int as present_helper,
           count(*) filter (where a.status = 'present' and a.role = 'participant')::int as present_participant,
           count(*) filter (where a.status = 'registered')::int as registered_count,
           count(*) filter (where a.status = 'absent')::int as absent_count
      from public.ez_attendances a
     where a.event_id = e.id
  ) c on true;

revoke all on table public.ez_v_events from public, anon, authenticated;
grant select on table public.ez_v_events to authenticated;

-- Gruppenname eines Einsatzes (bei Wettkampfbetreuung „A + B“, erste Gruppe zuerst); intern
create function public.ez_group_label(p_event uuid, p_group uuid)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select nullif(concat_ws(' + ',
           (select g.name from public.gr_groups g where g.id = p_group),
           (select string_agg(g.name, ' + ' order by g.name)
              from public.ez_event_groups eg join public.gr_groups g on g.id = eg.group_id
             where eg.event_id = p_event)), '');
$$;

revoke all on function public.ez_group_label(uuid, uuid) from public, anon, authenticated;

-- Liste (US-EZ-14, -15): nur lesbare Einsätze; abgesagte sind enthalten (R22)
create function public.ez_list_events(
  p_from date, p_to date, p_referat uuid default null, p_group uuid default null,
  p_kind public.ez_event_kind default null, p_limit int default 50, p_offset int default 0)
returns table (
  id uuid, kind public.ez_event_kind, span public.ez_span, referat_id uuid, referat_name text, group_id uuid,
  group_name text, title text, organizer_person_id uuid, start_date date, start_time time, end_date date,
  end_time time, day_category public.ez_day_category, location_id uuid, location_name text, is_cancelled boolean,
  cancel_reason text, from_planning boolean, present_trainer int, present_helper int, present_participant int,
  registered_count int, absent_count int, trial_count int, total_count bigint)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_all boolean := public.ad_has_level('EZ', 'read');
  v_referate uuid[] := public.ad_my_referate('EZ', 'read');
begin
  return query
  select v.id, v.kind, v.span, v.referat_id, r.name, v.group_id, public.ez_group_label(v.id, v.group_id), v.title,
         v.organizer_person_id, v.start_date, v.start_time, v.end_date, v.end_time, v.day_category, v.location_id,
         l.name, v.is_cancelled, v.cancel_reason, v.tk_plan_id is not null, v.present_trainer, v.present_helper,
         v.present_participant, v.registered_count, v.absent_count, v.trial_count, count(*) over ()
    from public.ez_v_events v
    join public.ea_referate r on r.id = v.referat_id
    left join public.ad_locations l on l.id = v.location_id
   where (v_all or v.referat_id = any (v_referate))
     and (p_from is null or v.start_date >= p_from)
     and (p_to is null or v.start_date <= p_to)
     and (p_referat is null or v.referat_id = p_referat)
     and (p_kind is null or v.kind = p_kind)
     and (p_group is null or v.group_id = p_group
          or exists (select 1 from public.ez_event_groups eg where eg.event_id = v.id and eg.group_id = p_group))
   order by v.start_date desc, v.start_time desc nulls last, v.created_at desc
   limit least(greatest(coalesce(p_limit, 50), 1), 200)
  offset greatest(coalesce(p_offset, 0), 0);
end;
$$;

-- Detail (US-EZ-10, -12, -15, -22, -23); Namen holt das Frontend über ea_person_names
create function public.ez_get_event(p_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_event public.ez_events%rowtype;
begin
  select * into v_event from public.ez_events e where e.id = p_id;
  if not found or not public.ez_can_read(v_event.referat_id) then
    raise exception 'EZ_NOT_FOUND' using errcode = 'P0001';
  end if;

  return jsonb_build_object(
    'event', to_jsonb(v_event) || jsonb_build_object(
      'is_cancelled', v_event.cancelled_at is not null,
      'from_planning', v_event.tk_plan_id is not null),
    'groups', coalesce((
      select jsonb_agg(jsonb_build_object('id', g.id, 'name', g.name, 'is_primary', x.is_primary)
                       order by x.is_primary desc, g.name)
        from (select v_event.group_id as id, true as is_primary where v_event.group_id is not null
              union all
              select eg.group_id, false from public.ez_event_groups eg where eg.event_id = p_id) x
        join public.gr_groups g on g.id = x.id), '[]'),
    'referat_name', (select r.name from public.ea_referate r where r.id = v_event.referat_id),
    'location_name', (select l.name from public.ad_locations l where l.id = v_event.location_id),
    'can_write', public.ez_can_write(v_event.referat_id),
    'can_delete', public.ez_can_delete(),
    'attendances', coalesce((
      select jsonb_agg(jsonb_build_object('id', a.id, 'person_id', a.person_id, 'role', a.role, 'status', a.status,
                                          'is_substitute', a.is_substitute, 'from_plan', a.from_plan)
                       order by a.role, a.created_at)
        from public.ez_attendances a where a.event_id = p_id), '[]'),
    'trials', coalesce((
      select jsonb_agg(jsonb_build_object('id', t.id, 'first_name', t.first_name) order by t.created_at, t.first_name)
        from public.ez_trial_participants t where t.event_id = p_id), '[]'));
end;
$$;

-- Kontrollliste Punktekonto Kletterhalle (US-EZ-16): nicht abgesagte Trainings am Ort, ohne Namen
create function public.ez_climbing_points_report(p_location uuid, p_from date, p_to date)
returns table (event_id uuid, start_date date, group_name text, participants_present int, trial_count int)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_all boolean := public.ad_has_level('EZ', 'read');
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

revoke all on function public.ez_list_events(date, date, uuid, uuid, public.ez_event_kind, int, int) from public, anon, authenticated;
revoke all on function public.ez_get_event(uuid) from public, anon, authenticated;
revoke all on function public.ez_climbing_points_report(uuid, date, date) from public, anon, authenticated;
grant execute on function public.ez_list_events(date, date, uuid, uuid, public.ez_event_kind, int, int) to authenticated;
grant execute on function public.ez_get_event(uuid) to authenticated;
grant execute on function public.ez_climbing_points_report(uuid, date, date) to authenticated;
