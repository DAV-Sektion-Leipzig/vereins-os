-- Planungshilfe Touren und Kurse (TK), spec T9, T11; spec.md TK v0.4 Abschnitt 2 (tk_list_plans, tk_get_plan,
-- tk_cost_report, tk_settlement_draft); tasks.md T009, T011. Namen der Leitenden wie ea_person_names (R48 AD):
-- sichtbar, weil die Person Leitung in einer lesbaren Planung ist (tk_person_visible).

create function public.tk_person_name(p_person uuid)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(e.preferred_name, e.first_name) || ' ' || e.last_name from public.ea_persons e where e.id = p_person;
$$;

revoke all on function public.tk_person_name(uuid) from public, anon, authenticated;

-- Liste (US-TK-01): Standard ohne abgesagte und abgeschlossene; Sortierung nach Beginn
create function public.tk_list_plans(
  p_year int default null, p_referat uuid default null, p_type public.tk_plan_type default null,
  p_status public.tk_plan_status[] default null, p_limit int default 50, p_offset int default 0)
returns table (
  id uuid, plan_type public.tk_plan_type, referat_id uuid, referat_name text, status public.tk_plan_status, title text,
  start_date date, end_date date, lead_person_id uuid, lead_name text, price_member_effective numeric,
  missing_count int, total_count bigint)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.ad_has_any_level('TK', 'read') then
    raise exception 'TK_FORBIDDEN' using errcode = 'P0001';
  end if;
  if p_limit is null or p_limit not between 1 and 200 or coalesce(p_offset, 0) < 0 then
    raise exception 'TK_FIELD_INVALID' using errcode = 'P0001', detail = 'limit';
  end if;
  return query
  select p.id, p.plan_type, p.referat_id, r.name, p.status, p.title, p.start_date, p.end_date, l.person_id,
         public.tk_person_name(l.person_id), res.price_member_effective, cardinality(coalesce(res.missing, '{}')),
         count(*) over ()
    from public.tk_plans p
    join public.ea_referate r on r.id = p.referat_id
    left join lateral (
      select x.person_id from public.tk_plan_leaders x
       where x.plan_id = p.id and x.role = 'lead' order by x.sort_order limit 1
    ) l on true
    left join public.tk_plan_results res on res.plan_id = p.id
   where public.tk_can_read(p.referat_id)
     and (p_year is null or extract(year from coalesce(p.start_date, p.created_at::date)) = p_year)
     and (p_referat is null or p.referat_id = p_referat)
     and (p_type is null or p.plan_type = p_type)
     and (case when p_status is null then p.status not in ('cancelled', 'closed') else p.status = any (p_status) end)
   order by p.start_date asc nulls last, p.title, p.id
   limit p_limit offset coalesce(p_offset, 0);
end;
$$;

revoke all on function public.tk_list_plans(int, uuid, public.tk_plan_type, public.tk_plan_status[], int, int)
  from public, anon, authenticated;
grant execute on function public.tk_list_plans(int, uuid, public.tk_plan_type, public.tk_plan_status[], int, int)
  to authenticated;

-- Planung mit allen Teilen; Kontaktdaten nur mit tk_can_read_contacts (Schlüssel fehlt sonst)
create function public.tk_get_plan(p_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_plan public.tk_plans%rowtype;
  v_result jsonb;
begin
  select * into v_plan from public.tk_plans p where p.id = p_id;
  if not found or not public.tk_can_read(v_plan.referat_id) then
    raise exception 'TK_NOT_FOUND' using errcode = 'P0001';
  end if;

  v_result := jsonb_build_object(
    'plan', to_jsonb(v_plan) || jsonb_build_object(
              'referat_name', (select r.name from public.ea_referate r where r.id = v_plan.referat_id),
              'updated_by_name', public.tk_person_name(v_plan.updated_by_person_id),
              'created_by_name', public.tk_person_name(v_plan.created_by_person_id)),
    'leaders', (select coalesce(jsonb_agg(jsonb_build_object(
                  'id', l.id, 'person_id', l.person_id, 'name', public.tk_person_name(l.person_id),
                  'first_name', e.first_name, 'preferred_name', e.preferred_name, 'last_name', e.last_name,
                  'role', l.role, 'sort_order', l.sort_order, 'rate_kind', l.rate_kind,
                  'license_type_id', l.license_type_id, 'license_code', q.code, 'license_name', q.name,
                  'license_valid_from', l.license_valid_from, 'license_valid_until', l.license_valid_until)
                  order by l.sort_order), '[]')
                  from public.tk_plan_leaders l
                  join public.ea_persons e on e.id = l.person_id
                  left join public.ad_qualification_types q on q.id = l.license_type_id
                 where l.plan_id = p_id),
    'legs', (select coalesce(jsonb_agg(to_jsonb(g) - 'plan_id' order by g.sort_order), '[]')
               from public.tk_plan_legs g where g.plan_id = p_id),
    'costs', (select coalesce(jsonb_agg(to_jsonb(c) - 'plan_id' order by c.cost_group, c.sort_order), '[]')
                from public.tk_plan_costs c where c.plan_id = p_id),
    'results', (select to_jsonb(r) - 'plan_id' from public.tk_plan_results r where r.plan_id = p_id),
    'rates', public.tk_rates(p_id),
    'rates_frozen', exists (select 1 from public.tk_plan_rates r where r.plan_id = p_id),
    'history', (select coalesce(jsonb_agg(jsonb_build_object(
                  'at', h.at, 'by_name', public.tk_person_name(h.by_person_id), 'event', h.event,
                  'from_status', h.from_status, 'to_status', h.to_status, 'comment', h.comment,
                  'changed_fields', h.changed_fields) order by h.at, h.id), '[]')
                  from public.tk_plan_history h where h.plan_id = p_id),
    'can_write', public.tk_can_edit_plan(v_plan.status, v_plan.referat_id),
    'can_change_status', public.tk_can_write(v_plan.referat_id),
    'can_approve', public.tk_can_approve(v_plan.referat_id),
    'can_manage', public.tk_can_manage(),
    'can_read_contacts', public.tk_can_read_contacts(v_plan.referat_id));

  if public.tk_can_read_contacts(v_plan.referat_id) then
    v_result := v_result || jsonb_build_object('contacts', (
      select coalesce(jsonb_agg(jsonb_build_object(
               'person_id', l.person_id, 'email', c.email, 'mobile', c.mobile,
               'emergency_name', c.emergency_name, 'emergency_phone', c.emergency_phone) order by l.sort_order), '[]')
        from public.tk_plan_contacts c join public.tk_plan_leaders l on l.id = c.leader_id
       where c.plan_id = p_id));
  end if;
  return v_result;
end;
$$;

revoke all on function public.tk_get_plan(uuid) from public, anon, authenticated;
grant execute on function public.tk_get_plan(uuid) to authenticated;

-- Kostenauswertung (US-TK-20): keine Kontaktdaten; Summenzeile im Frontend
create function public.tk_cost_report(
  p_year int, p_referat uuid default null, p_type public.tk_plan_type default null,
  p_include_cancelled boolean default false)
returns table (
  id uuid, title text, plan_type public.tk_plan_type, referat_id uuid, referat_name text, start_date date,
  end_date date, status public.tk_plan_status, fee_total numeric, org_total numeric, leader_costs numeric,
  fixed_costs numeric, total_costs numeric, price_member_effective numeric, min_participants int,
  max_participants int, result_min numeric, result_max numeric, section_bears numeric)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.ad_has_any_level('TK', 'read') then
    raise exception 'TK_FORBIDDEN' using errcode = 'P0001';
  end if;
  return query
  select p.id, p.title, p.plan_type, p.referat_id, r.name, p.start_date, p.end_date, p.status, res.fee_total,
         res.org_total, res.leader_costs, res.fixed_costs, res.total_costs, res.price_member_effective,
         p.min_participants, p.max_participants, res.result_min, res.result_max, res.section_bears
    from public.tk_plans p
    join public.ea_referate r on r.id = p.referat_id
    left join public.tk_plan_results res on res.plan_id = p.id
   where public.tk_can_read(p.referat_id)
     and extract(year from coalesce(p.start_date, p.created_at::date)) = p_year
     and (p_referat is null or p.referat_id = p_referat)
     and (p_type is null or p.plan_type = p_type)
     and (p_include_cancelled or p.status <> 'cancelled')
   order by p.start_date asc nulls last, p.title, p.id;
end;
$$;

revoke all on function public.tk_cost_report(int, uuid, public.tk_plan_type, boolean) from public, anon, authenticated;
grant execute on function public.tk_cost_report(int, uuid, public.tk_plan_type, boolean) to authenticated;

-- Vorbelegung der Abrechnung für Finanzen (US-TK-24, Übergabe TK → FI v1.3); ab „in Yolawo angelegt“
create function public.tk_settlement_draft(p_plan_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_plan public.tk_plans%rowtype;
  v_res public.tk_plan_results%rowtype;
begin
  if not (public.tk_can_manage() or public.ad_has_level('FI', 'read')) then
    raise exception 'TK_FORBIDDEN' using errcode = 'P0001';
  end if;
  select * into v_plan from public.tk_plans p where p.id = p_plan_id;
  if not found then
    raise exception 'TK_NOT_FOUND' using errcode = 'P0001';
  end if;
  if v_plan.status = 'cancelled' then
    raise exception 'TK_PLAN_CANCELLED' using errcode = 'P0001';
  end if;
  if v_plan.status not in ('published', 'done', 'closed') then
    raise exception 'TK_STATUS_NOT_ALLOWED' using errcode = 'P0001', detail = v_plan.status::text;
  end if;
  select * into v_res from public.tk_plan_results r where r.plan_id = p_plan_id;

  return jsonb_build_object(
    'plan_id', v_plan.id, 'plan_type', v_plan.plan_type, 'referat_id', v_plan.referat_id, 'title', v_plan.title,
    'start_date', v_plan.start_date, 'end_date', v_plan.end_date, 'status', v_plan.status,
    'ez_event_id', v_plan.ez_event_id,
    'persons', (select coalesce(jsonb_agg(jsonb_build_object(
                  'person_id', l.person_id, 'role', l.role, 'rate_kind', l.rate_kind,
                  'helper_reason', case when l.rate_kind = 'helper' then
                                     case when l.role = 'helper' then 'role' else 'no_license' end end,
                  'license_type_id', l.license_type_id, 'license_valid_from', l.license_valid_from,
                  'license_valid_until', l.license_valid_until) order by l.sort_order), '[]')
                  from public.tk_plan_leaders l where l.plan_id = p_plan_id),
    'days_full', v_plan.days_full, 'days_half', v_plan.days_half, 'teaching_hours', v_plan.teaching_hours,
    'org_days', v_plan.org_days,
    'org_person_id', (select l.person_id from public.tk_plan_leaders l
                       where l.plan_id = p_plan_id and l.role = 'lead' order by l.sort_order limit 1),
    'leader_costs', (select coalesce(jsonb_agg(jsonb_build_object(
                       'label', c.label, 'quantity', c.quantity, 'unit_price', c.unit_price, 'is_car', c.is_car,
                       'is_overnight', c.is_overnight) order by c.sort_order), '[]')
                       from public.tk_plan_costs c where c.plan_id = p_plan_id and c.cost_group = 'leader'
                         and v_plan.plan_type <> 'community_tour'),
    'car_reason', v_plan.car_reason,
    'approval_notes', to_jsonb(array(select w from unnest(coalesce(v_res.warnings, '{}')) w
                                      where w in ('car_permit', 'overnight_over_limit'))),
    'total_costs', v_res.total_costs, 'price_member', v_res.price_member_effective,
    'price_non_member', v_res.price_non_member_effective,
    'min_participants', v_plan.min_participants, 'max_participants', v_plan.max_participants,
    'rates_valid_on', v_res.rates_valid_on, 'rates_frozen_on', v_plan.rates_frozen_on);
end;
$$;

revoke all on function public.tk_settlement_draft(uuid) from public, anon, authenticated;
grant execute on function public.tk_settlement_draft(uuid) to authenticated;
