-- Anwesenheitserfassung Nachtrag v0.6 (spec.md EZ v0.6), spec T22, T23 Teil; R32, R34; Übergabe FI → EZ Z1, Z3.
-- Platzhalter der Sperre durch Finanzen, Abrechnungsart am Einsatz (Altbestand mit der Vorbelegung der Einsatzart),
-- Lesefunktionen um Abrechnungsart und Kennzeichen „abgerechnet“ erweitert.
-- Voraussetzung: Administration Nachtrag v0.10 (20261029000300, ad_remuneration_kinds/_defaults).

-- Platzhalter; die erste Migration von Finanzen ersetzt sie mit derselben Signatur (spec.md FI Abschnitt 2)
create function public.fi_attendance_locked(p_attendance uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select false;
$$;

create function public.fi_event_locked(p_event uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select false;
$$;

revoke all on function public.fi_attendance_locked(uuid) from public, anon, authenticated;
revoke all on function public.fi_event_locked(uuid) from public, anon, authenticated;
grant execute on function public.fi_attendance_locked(uuid) to authenticated;
grant execute on function public.fi_event_locked(uuid) to authenticated;

-- Abrechnungsart (R32); null = keine Vergütung
alter table public.ez_events
  add column remuneration_kind_id uuid references public.ad_remuneration_kinds (id) on delete restrict;

comment on column public.ez_events.remuneration_kind_id is
  'Abrechnungsart des Einsatzes (spec.md EZ R32); null = keine Vergütung. Vorbelegt aus ad_remuneration_defaults.';

create index ez_events_remuneration_kind on public.ez_events (remuneration_kind_id);

-- Altbestand: Vorbelegung der Einsatzart am Datum (ohne Nutzerkontext direkt aus den Stammdaten); ohne Audit-Trigger,
-- damit „geändert am“ der vorhandenen Einsätze erhalten bleibt
alter table public.ez_events disable trigger ez_events_before_update;
update public.ez_events e
   set remuneration_kind_id = (
         select d.kind_id
           from public.ad_remuneration_defaults d
          where d.event_kind = e.kind::text
            and d.span = e.span::text
            and d.valid_from <= e.start_date
          order by d.valid_from desc
          limit 1)
 where e.remuneration_kind_id is null;
alter table public.ez_events enable trigger ez_events_before_update;

-- View um die Abrechnungsart erweitert (Spalte am Ende)
create or replace view public.ez_v_events with (security_invoker = true) as
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
       (select count(*)::int from public.ez_trial_participants t where t.event_id = e.id) as trial_count,
       e.remuneration_kind_id
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

-- Liste mit Abrechnungsart und Kennzeichen „abgerechnet“ (neuer Rückgabetyp, deshalb neu anlegen)
drop function public.ez_list_events(date, date, uuid, uuid, public.ez_event_kind, int, int);

create function public.ez_list_events(
  p_from date, p_to date, p_referat uuid default null, p_group uuid default null,
  p_kind public.ez_event_kind default null, p_limit int default 50, p_offset int default 0)
returns table (
  id uuid, kind public.ez_event_kind, span public.ez_span, referat_id uuid, referat_name text, group_id uuid,
  group_name text, title text, organizer_person_id uuid, start_date date, start_time time, end_date date,
  end_time time, day_category public.ez_day_category, location_id uuid, location_name text, is_cancelled boolean,
  cancel_reason text, from_planning boolean, present_trainer int, present_helper int, present_participant int,
  registered_count int, absent_count int, trial_count int, remuneration_kind_id uuid, remuneration_kind_name text,
  is_settled boolean, total_count bigint)
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
         v.present_participant, v.registered_count, v.absent_count, v.trial_count, v.remuneration_kind_id, k.name,
         public.fi_event_locked(v.id), count(*) over ()
    from public.ez_v_events v
    join public.ea_referate r on r.id = v.referat_id
    left join public.ad_locations l on l.id = v.location_id
    left join public.ad_remuneration_kinds k on k.id = v.remuneration_kind_id
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

revoke all on function public.ez_list_events(date, date, uuid, uuid, public.ez_event_kind, int, int) from public, anon, authenticated;
grant execute on function public.ez_list_events(date, date, uuid, uuid, public.ez_event_kind, int, int) to authenticated;

-- Detail mit Abrechnungsart und Kennzeichen „abgerechnet“ je Einsatz und Anwesenheit (R32, R34)
create or replace function public.ez_get_event(p_id uuid)
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
      'from_planning', v_event.tk_plan_id is not null,
      'remuneration_kind_name',
        (select k.name from public.ad_remuneration_kinds k where k.id = v_event.remuneration_kind_id),
      'is_settled', public.fi_event_locked(p_id)),
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
                                          'is_substitute', a.is_substitute, 'from_plan', a.from_plan,
                                          'is_settled', public.fi_attendance_locked(a.id))
                       order by a.role, a.created_at)
        from public.ez_attendances a where a.event_id = p_id), '[]'),
    'trials', coalesce((
      select jsonb_agg(jsonb_build_object('id', t.id, 'first_name', t.first_name) order by t.created_at, t.first_name)
        from public.ez_trial_participants t where t.event_id = p_id), '[]'));
end;
$$;
