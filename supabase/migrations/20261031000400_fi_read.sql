-- Finanzen (FI), spec T4; US-FI-05, -06, -10; R11–R14, R18, R31, R33: Liste, Detail, Daten des Abrechnungsdokuments.

-- Anzeigename „Rufname Nachname“ bzw. „Vorname Nachname“; intern
create function public.fi_person_label(p_person uuid)
returns text language sql stable security definer set search_path = '' as $$
  select coalesce(p.preferred_name, p.first_name) || ' ' || p.last_name from public.ea_persons p where p.id = p_person;
$$;

revoke all on function public.fi_person_label(uuid) from public, anon, authenticated;

-- Bezeichnung des Einsatzes für Positionen (Training: Gruppe; sonst Titel); intern
create function public.fi_event_label(p_event uuid)
returns text language sql stable security definer set search_path = '' as $$
  select coalesce(e.title, g.name) from public.ez_events e left join public.gr_groups g on g.id = e.group_id
   where e.id = p_event;
$$;

revoke all on function public.fi_event_label(uuid) from public, anon, authenticated;

-- Liste der Abrechnungen eines Halbjahres (US-FI-06); nur lesbare (R31)
create function public.fi_list_settlements(
  p_year smallint, p_half smallint, p_status public.fi_settlement_status default null, p_group uuid default null,
  p_with_hint boolean default null, p_to_confirm boolean default null, p_deadline_passed boolean default null,
  p_limit int default 50, p_offset int default 0)
returns table (
  id uuid, person_id uuid, display_name text, groups text[], amount numeric, status public.fi_settlement_status,
  hints text[], referate jsonb, payable boolean, has_new_events boolean, total_count bigint)
language plpgsql
stable
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_confirm uuid[] := public.fi_confirm_referate();
  v_deadline date;
begin
  if not (public.fi_can_read_all() or cardinality(public.fi_read_referate()) > 0) then
    raise exception 'FI_FORBIDDEN' using errcode = 'P0001';
  end if;
  if p_deadline_passed then
    v_deadline := public.ad_settlement_deadline(p_year, p_half);
  end if;
  return query
  with s as (
    select s.*, public.fi_settlement_info(s.id) as info
      from public.fi_settlements s
     where s.year = p_year and s.half = p_half
       and public.fi_can_read_settlement(s.id)
       and (p_status is null or s.status = p_status)
       and (p_group is null or exists (select 1 from public.fi_settlement_items i
                                        where i.settlement_id = s.id and i.group_id = p_group))
       and (not coalesce(p_to_confirm, false)
            or (s.status = 'draft' and exists (
                  select 1 from public.fi_settlement_items i
                   where i.settlement_id = s.id and i.referat_id = any (v_confirm)
                     and not exists (select 1 from public.fi_settlement_confirmations c
                                      where c.settlement_id = s.id and c.referat_id = i.referat_id))))
       and (not coalesce(p_deadline_passed, false) or (s.status = 'closed' and current_date > v_deadline))
  )
  select s.id, s.person_id, public.fi_person_label(s.person_id),
         array(select distinct coalesce(g.name, r.name) from public.fi_settlement_items i
                 join public.ea_referate r on r.id = i.referat_id
                 left join public.gr_groups g on g.id = i.group_id
                where i.settlement_id = s.id order by 1),
         s.amount, s.status,
         array(select jsonb_array_elements_text(s.info -> 'hints')),
         (select jsonb_agg(jsonb_build_object(
                   'referat_id', x.referat_id, 'name', r.name,
                   'confirmed', exists (select 1 from public.fi_settlement_confirmations c
                                         where c.settlement_id = s.id and c.referat_id = x.referat_id))
                 order by r.name)
            from (select distinct i.referat_id from public.fi_settlement_items i where i.settlement_id = s.id) x
            join public.ea_referate r on r.id = x.referat_id),
         (s.info ->> 'payable')::boolean, s.has_new_events, count(*) over ()
    from s
    join public.ea_persons p on p.id = s.person_id
   where p_with_hint is null or (jsonb_array_length(s.info -> 'hints') > 0) = p_with_hint
   order by p.last_name, coalesce(p.preferred_name, p.first_name)
   limit least(greatest(coalesce(p_limit, 50), 1), 200)
  offset greatest(coalesce(p_offset, 0), 0);
end;
$$;

-- Detail (US-FI-06): ganze Abrechnung mit Positionen, Bestätigungen, Verlauf, Hinweisen; FI_NOT_FOUND, wenn nicht lesbar
create function public.fi_get_settlement(p_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_s public.fi_settlements%rowtype;
  v_info jsonb;
begin
  select * into v_s from public.fi_settlements s where s.id = p_id;
  if not found or not public.fi_can_read_settlement(p_id) then
    raise exception 'FI_NOT_FOUND' using errcode = 'P0001';
  end if;
  v_info := public.fi_settlement_info(p_id) - 'bank_check';

  return jsonb_build_object(
    'settlement', to_jsonb(v_s) - 'closed_by' - 'expired_by' - 'created_by' - 'updated_by'
                  || jsonb_build_object('display_name', public.fi_person_label(v_s.person_id),
                                        'closed_by_name', public.fi_person_label(v_s.closed_by_person_id),
                                        'deadline', public.ad_settlement_deadline(v_s.year, v_s.half)),
    'info', v_info,
    'items', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', i.id, 'event_id', i.event_id, 'event_date', i.event_date, 'event_kind', e.kind,
               'event_label', public.fi_event_label(i.event_id), 'span', e.span, 'end_date', e.end_date,
               'start_time', e.start_time, 'end_time', e.end_time, 'day_category', e.day_category,
               'referat_id', i.referat_id, 'referat_name', r.name, 'group_id', i.group_id, 'group_name', g.name,
               'remuneration_kind', k.name, 'position', i.position, 'recorded_role', i.recorded_role,
               'calc_rate_role', i.calc_rate_role, 'calc_quantity', i.calc_quantity,
               'override_rate_role', i.override_rate_role, 'override_quantity', i.override_quantity,
               'rate_role', coalesce(i.override_rate_role, i.calc_rate_role),
               'quantity', coalesce(i.override_quantity, i.calc_quantity),
               'correction_reason', i.correction_reason, 'exception_reason', i.exception_reason,
               'rate', i.rate, 'amount', i.amount, 'hints', to_jsonb(i.hints))
             order by coalesce(g.name, r.name), i.event_date, i.position)
        from public.fi_settlement_items i
        join public.ez_events e on e.id = i.event_id
        join public.ea_referate r on r.id = i.referat_id
        join public.ad_remuneration_kinds k on k.id = i.remuneration_kind_id
        left join public.gr_groups g on g.id = i.group_id
       where i.settlement_id = p_id), '[]'),
    'confirmations', coalesce((
      select jsonb_agg(jsonb_build_object(
               'referat_id', x.referat_id, 'referat_name', r.name,
               'confirmed_at', c.confirmed_at, 'confirmed_by_name', public.fi_person_label(c.confirmed_by_person_id),
               'is_substitute', c.is_substitute, 'substitute_reason', c.substitute_reason,
               'can_confirm', public.ad_can_approve('FI', x.referat_id))
             order by r.name)
        from (select distinct i.referat_id from public.fi_settlement_items i where i.settlement_id = p_id) x
        join public.ea_referate r on r.id = x.referat_id
        left join public.fi_settlement_confirmations c on c.settlement_id = p_id and c.referat_id = x.referat_id), '[]'),
    'log', coalesce((
      select jsonb_agg(jsonb_build_object('action', l.action, 'detail', l.detail, 'at', l.at,
                                          'by_name', public.fi_person_label(l.by_person_id)) order by l.at, l.id)
        from public.fi_settlement_log l where l.settlement_id = p_id), '[]'),
    'can_manage', public.fi_can_manage());
end;
$$;

-- Daten des Abrechnungsdokuments (US-FI-10, R18) für abgeschlossene oder spätere Abrechnungen
create function public.fi_settlement_document(p_ids uuid[])
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.fi_can_manage() then
    raise exception 'FI_FORBIDDEN' using errcode = 'P0001';
  end if;
  if exists (select 1 from unnest(coalesce(p_ids, '{}')) as x (id)
              where not exists (select 1 from public.fi_settlements s
                                 where s.id = x.id and s.status in ('closed', 'submitted', 'expired', 'paid'))) then
    raise exception 'FI_STATUS' using errcode = 'P0001';
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'id', s.id, 'first_name', p.first_name, 'last_name', p.last_name, 'preferred_name', p.preferred_name,
             'year', s.year, 'half', s.half, 'amount', s.amount,
             'deadline', public.ad_settlement_deadline(s.year, s.half),
             'groups', (
               select jsonb_agg(jsonb_build_object('label', gl.label, 'total', gl.total, 'items', gl.items)
                                order by gl.label)
                 from (select coalesce(g.name, r.name) as label, sum(i.amount) as total,
                              jsonb_agg(jsonb_build_object(
                                'event_date', i.event_date, 'event_label', public.fi_event_label(i.event_id),
                                'position', i.position, 'rate_role', coalesce(i.override_rate_role, i.calc_rate_role),
                                'quantity', coalesce(i.override_quantity, i.calc_quantity), 'rate', i.rate,
                                'amount', i.amount, 'correction_reason', i.correction_reason,
                                'exception_reason', i.exception_reason) order by i.event_date, i.position) as items
                         from public.fi_settlement_items i
                         join public.ea_referate r on r.id = i.referat_id
                         left join public.gr_groups g on g.id = i.group_id
                        where i.settlement_id = s.id
                        group by coalesce(g.name, r.name)) gl))
           order by p.last_name, p.first_name)
      from public.fi_settlements s
      join public.ea_persons p on p.id = s.person_id
     where s.id = any (p_ids)), '[]');
end;
$$;

revoke all on function public.fi_list_settlements(smallint, smallint, public.fi_settlement_status, uuid, boolean, boolean,
  boolean, int, int) from public, anon, authenticated;
revoke all on function public.fi_get_settlement(uuid) from public, anon, authenticated;
revoke all on function public.fi_settlement_document(uuid[]) from public, anon, authenticated;
grant execute on function public.fi_list_settlements(smallint, smallint, public.fi_settlement_status, uuid, boolean, boolean,
  boolean, int, int) to authenticated;
grant execute on function public.fi_get_settlement(uuid) to authenticated;
grant execute on function public.fi_settlement_document(uuid[]) to authenticated;
