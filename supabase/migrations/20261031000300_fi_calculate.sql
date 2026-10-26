-- Finanzen (FI), spec T3; US-FI-01 bis US-FI-05; R1–R10, R15, R23 (Rücksetzen der Bestätigung).
-- Halbjahresabrechnung aus der Anwesenheitserfassung (ez_settlement_basis) nach den Abrechnungsarten der Administration.

create function public.fi_calculate_half(p_year smallint, p_half smallint)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_from date;
  v_to date;
  v_referate uuid[];
  v_ids uuid[];
  v_i int;
  v_person uuid;
  v_s public.fi_settlements%rowtype;
  v_sid uuid;
  v_ref_del uuid[];
  v_ref_upd uuid[];
  v_ref_ins uuid[];
  v_affected uuid[];
  v_count int;
  v_created int := 0;
  v_recalculated int := 0;
  v_unchanged int := 0;
  v_locked int := 0;
  v_removed int := 0;
begin
  if not public.fi_can_manage() then
    raise exception 'FI_FORBIDDEN' using errcode = 'P0001';
  end if;
  if p_half is null or p_half not in (1, 2) or p_year is null or p_year not between 2026 and 2100 then
    raise exception 'FI_PERIOD_INVALID' using errcode = 'P0001';
  end if;
  v_from := make_date(p_year, case p_half when 1 then 1 else 7 end, 1);
  v_to := case p_half when 1 then make_date(p_year, 6, 30) else make_date(p_year, 12, 31) end;
  select coalesce(array_agg(r.id), '{}') into v_referate from public.ea_referate r where r.semiannual_settlement;

  -- Grundlage (R1, R2)
  create temp table if not exists fi_tmp_basis (
    event_id uuid, attendance_id uuid, kind public.ez_event_kind, span public.ez_span, remuneration_kind_id uuid,
    referat_id uuid, group_id uuid, group_name text, title text, organizer_person_id uuid, start_date date,
    start_time time, end_date date, end_time time, day_category public.ez_day_category, training_minutes int,
    person_id uuid, role public.ez_role, tk_plan_id uuid
  ) on commit drop;
  truncate pg_temp.fi_tmp_basis;
  insert into pg_temp.fi_tmp_basis select * from public.ez_settlement_basis(v_from, v_to, v_referate);

  -- Positionen je Abrechnungsart
  create temp table if not exists fi_tmp_kindpos (kind_id uuid primary key, positions text[]) on commit drop;
  truncate pg_temp.fi_tmp_kindpos;
  insert into pg_temp.fi_tmp_kindpos
  select p.kind_id, array_agg(p.position) from public.ad_remuneration_positions p group by p.kind_id;

  -- Förderfähige Lizenzen der Trainer:innen (R8; Lesefunktion der Administration, höchstens 500 IDs je Aufruf)
  create temp table if not exists fi_tmp_lic (person_id uuid, valid_from date, valid_until date) on commit drop;
  truncate pg_temp.fi_tmp_lic;
  select coalesce(array_agg(distinct b.person_id), '{}') into v_ids from pg_temp.fi_tmp_basis b where b.role = 'trainer';
  v_i := 1;
  while v_i <= coalesce(cardinality(v_ids), 0) loop
    insert into pg_temp.fi_tmp_lic
    select d.person_id, (l ->> 'valid_from')::date, nullif(l ->> 'valid_until', '')::date
      from public.ea_person_finance_data(v_ids[v_i:v_i + 499], v_to) d,
           jsonb_array_elements(d.licenses) as l
     where coalesce((l ->> 'is_fundable')::boolean, false);
    v_i := v_i + 500;
  end loop;

  -- Sollpositionen (R3–R8, R10)
  create temp table if not exists fi_tmp_pos (
    person_id uuid, event_id uuid, attendance_id uuid, event_date date, referat_id uuid, group_id uuid,
    kind_id uuid, position public.fi_position, recorded_role public.ez_role, calc_rate_role public.fi_rate_role,
    calc_quantity numeric, hints public.fi_hint[]
  ) on commit drop;
  truncate pg_temp.fi_tmp_pos;

  with b as (
    select b.*, k.positions,
           case when b.span = 'multi' then b.end_date - b.start_date + 1 else 1 end as days,
           case
             when b.role = 'helper' then 'helper'::public.fi_rate_role
             when exists (select 1 from pg_temp.fi_tmp_lic l
                           where l.person_id = b.person_id
                             and ((l.valid_from <= b.start_date and (l.valid_until is null or l.valid_until >= b.start_date))
                                  or l.valid_from between v_from and v_to)) then 'trainer'::public.fi_rate_role
             else 'helper'::public.fi_rate_role
           end as rate_role
      from pg_temp.fi_tmp_basis b
      join pg_temp.fi_tmp_kindpos k on k.kind_id = b.remuneration_kind_id
  ), d as (
    -- Tages- und Halbtagessätze (R5): erster Tag Beginn–24:00, letzter Tag 0:00–Ende, Zwischentage voll
    select b.*,
           case when b.span = 'single' then (b.day_category = 'at_least_8h')::int
                else greatest(b.days - 2, 0)
                     + (b.start_time is null or time '24:00' - b.start_time >= interval '8 hours')::int
                     + (b.end_time is null or b.end_time >= time '08:00')::int
           end as full_days,
           (b.span = 'multi' and (b.start_time is null or b.end_time is null)) as no_time
      from b
  ), x as (
    select d.*, case when 'half_day' = any (d.positions) then d.days - d.full_days else 0 end as half_days,
           case when 'half_day' = any (d.positions) then d.full_days else d.days end as day_count
      from d
  )
  insert into pg_temp.fi_tmp_pos
  -- Trainingseinheiten (R3, R4)
  select x.person_id, x.event_id, x.attendance_id, x.start_date, x.referat_id, x.group_id, x.remuneration_kind_id,
         'training_unit'::public.fi_position, x.role, x.rate_role,
         case when x.training_minutes is null then 0 else ceil(x.training_minutes / 30.0) end,
         array_remove(array[case when x.training_minutes is null then 'no_training_time'::public.fi_hint end,
                            case when x.role = 'trainer' and x.rate_role = 'helper' then 'no_license'::public.fi_hint end],
                      null)
    from x where 'training_unit' = any (x.positions)
  union all
  -- Wettkampfbetreuung je Kalendertag (R6)
  select x.person_id, x.event_id, x.attendance_id, x.start_date, x.referat_id, x.group_id, x.remuneration_kind_id,
         'competition_day'::public.fi_position, x.role, x.rate_role, x.days,
         array_remove(array[case when x.role = 'trainer' and x.rate_role = 'helper' then 'no_license'::public.fi_hint end],
                      null)
    from x where not 'training_unit' = any (x.positions) and 'competition_day' = any (x.positions)
  union all
  -- Tagessätze (R5)
  select x.person_id, x.event_id, x.attendance_id, x.start_date, x.referat_id, x.group_id, x.remuneration_kind_id,
         'day'::public.fi_position, x.role, x.rate_role, x.day_count,
         array_remove(array[case when x.no_time then 'no_time'::public.fi_hint end,
                            case when x.role = 'trainer' and x.rate_role = 'helper' then 'no_license'::public.fi_hint end],
                      null)
    from x where not 'training_unit' = any (x.positions) and not 'competition_day' = any (x.positions)
             and 'day' = any (x.positions) and x.day_count > 0
  union all
  -- Halbtagessätze (R5)
  select x.person_id, x.event_id, x.attendance_id, x.start_date, x.referat_id, x.group_id, x.remuneration_kind_id,
         'half_day'::public.fi_position, x.role, x.rate_role, x.half_days,
         array_remove(array[case when x.no_time then 'no_time'::public.fi_hint end,
                            case when x.role = 'trainer' and x.rate_role = 'helper' then 'no_license'::public.fi_hint end],
                      null)
    from x where not 'training_unit' = any (x.positions) and not 'competition_day' = any (x.positions)
             and 'day' = any (x.positions) and x.half_days > 0;

  -- Organisationspauschale je Tag für die organisierende Person (R7), auch ohne eigene Anwesenheit
  insert into pg_temp.fi_tmp_pos
  select distinct on (b.event_id)
         b.organizer_person_id, b.event_id,
         (select o.attendance_id from pg_temp.fi_tmp_basis o
           where o.event_id = b.event_id and o.person_id = b.organizer_person_id limit 1),
         b.start_date, b.referat_id, b.group_id, b.remuneration_kind_id, 'organization_day'::public.fi_position, null::public.ez_role,
         'none'::public.fi_rate_role,
         case when b.span = 'multi' then b.end_date - b.start_date + 1 else 1 end, '{}'::public.fi_hint[]
    from pg_temp.fi_tmp_basis b
    join pg_temp.fi_tmp_kindpos k on k.kind_id = b.remuneration_kind_id
   where b.organizer_person_id is not null and 'organization_day' = any (k.positions)
   order by b.event_id;

  -- Abgleich mit vorhandenen Abrechnungen (R15)
  for v_person in
    select t.person_id from pg_temp.fi_tmp_pos t
    union
    select s.person_id from public.fi_settlements s
     where s.year = p_year and s.half = p_half and s.status in ('draft', 'confirmed')
  loop
    select * into v_s from public.fi_settlements s where s.person_id = v_person and s.year = p_year and s.half = p_half;

    if not found then
      insert into public.fi_settlements (person_id, year, half) values (v_person, p_year, p_half) returning id into v_sid;
      insert into public.fi_settlement_items (settlement_id, event_id, attendance_id, event_date, referat_id, group_id,
                                              remuneration_kind_id, position, recorded_role, calc_rate_role,
                                              calc_quantity, hints)
      select v_sid, t.event_id, t.attendance_id, t.event_date, t.referat_id, t.group_id, t.kind_id, t.position,
             t.recorded_role, t.calc_rate_role, t.calc_quantity, t.hints
        from pg_temp.fi_tmp_pos t where t.person_id = v_person;
      get diagnostics v_count = row_count;
      perform public.fi_log(v_sid, 'calculated', jsonb_build_object('positions', v_count));
      v_created := v_created + 1;

    elsif v_s.status in ('draft', 'confirmed') then
      with d as (
        delete from public.fi_settlement_items i
         where i.settlement_id = v_s.id
           and not exists (select 1 from pg_temp.fi_tmp_pos t
                            where t.person_id = v_person and t.event_id = i.event_id and t.position = i.position)
        returning i.referat_id)
      select coalesce(array_agg(d.referat_id), '{}') into v_ref_del from d;

      with u as (
        update public.fi_settlement_items i
           set attendance_id = t.attendance_id, event_date = t.event_date, referat_id = t.referat_id,
               group_id = t.group_id, remuneration_kind_id = t.kind_id, calc_rate_role = t.calc_rate_role,
               calc_quantity = t.calc_quantity, hints = t.hints,
               override_rate_role = case when i.recorded_role is distinct from t.recorded_role then null else i.override_rate_role end,
               override_quantity = case when i.recorded_role is distinct from t.recorded_role then null else i.override_quantity end,
               correction_reason = case when i.recorded_role is distinct from t.recorded_role then null else i.correction_reason end,
               exception_reason = case when i.recorded_role is distinct from t.recorded_role then null else i.exception_reason end,
               recorded_role = t.recorded_role
          from pg_temp.fi_tmp_pos t
         where i.settlement_id = v_s.id and t.person_id = v_person and t.event_id = i.event_id
           and t.position = i.position
           and (i.attendance_id, i.event_date, i.referat_id, i.group_id, i.remuneration_kind_id, i.recorded_role,
                i.calc_rate_role, i.calc_quantity,
                array(select h from unnest(array_remove(i.hints, 'rate_missing')) as h order by h))
               is distinct from
               (t.attendance_id, t.event_date, t.referat_id, t.group_id, t.kind_id, t.recorded_role,
                t.calc_rate_role, t.calc_quantity::numeric(6, 2), array(select h from unnest(t.hints) as h order by h))
        returning i.referat_id)
      select coalesce(array_agg(u.referat_id), '{}') into v_ref_upd from u;

      with n as (
        insert into public.fi_settlement_items (settlement_id, event_id, attendance_id, event_date, referat_id, group_id,
                                                remuneration_kind_id, position, recorded_role, calc_rate_role,
                                                calc_quantity, hints)
        select v_s.id, t.event_id, t.attendance_id, t.event_date, t.referat_id, t.group_id, t.kind_id, t.position,
               t.recorded_role, t.calc_rate_role, t.calc_quantity, t.hints
          from pg_temp.fi_tmp_pos t
         where t.person_id = v_person
           and not exists (select 1 from public.fi_settlement_items i
                            where i.settlement_id = v_s.id and i.event_id = t.event_id and i.position = t.position)
        returning referat_id)
      select coalesce(array_agg(n.referat_id), '{}') into v_ref_ins from n;

      v_affected := v_ref_del || v_ref_upd || v_ref_ins;
      if not exists (select 1 from public.fi_settlement_items i where i.settlement_id = v_s.id) then
        delete from public.fi_settlements where id = v_s.id;
        v_removed := v_removed + 1;
      elsif cardinality(v_affected) > 0 then
        perform public.fi_log(v_s.id, 'calculated',
          jsonb_build_object('removed', cardinality(v_ref_del), 'changed', cardinality(v_ref_upd),
                             'added', cardinality(v_ref_ins)));
        delete from public.fi_settlement_confirmations c
         where c.settlement_id = v_s.id and c.referat_id = any (v_affected);
        get diagnostics v_count = row_count;
        if v_s.status = 'confirmed' then
          update public.fi_settlements set status = 'draft' where id = v_s.id;
        end if;
        if v_count > 0 then
          perform public.fi_log(v_s.id, 'confirmation_reset', jsonb_build_object('referate', to_jsonb(v_affected)));
        end if;
        v_recalculated := v_recalculated + 1;
      else
        v_unchanged := v_unchanged + 1;
      end if;

    else
      -- Abgeschlossen oder später: nicht neu berechnen, nur Hinweis auf nicht abgerechnete Einsätze (US-FI-01 AK4)
      update public.fi_settlements s
         set has_new_events = exists (
               select 1 from pg_temp.fi_tmp_pos t
                where t.person_id = v_person
                  and not exists (select 1 from public.fi_settlement_items i
                                   where i.settlement_id = v_s.id and i.event_id = t.event_id and i.position = t.position))
       where s.id = v_s.id
         and s.has_new_events is distinct from exists (
               select 1 from pg_temp.fi_tmp_pos t
                where t.person_id = v_person
                  and not exists (select 1 from public.fi_settlement_items i
                                   where i.settlement_id = v_s.id and i.event_id = t.event_id and i.position = t.position));
      v_locked := v_locked + 1;
    end if;
  end loop;

  return jsonb_build_object('created', v_created, 'recalculated', v_recalculated, 'unchanged', v_unchanged,
                            'locked', v_locked, 'removed', v_removed);
end;
$$;

revoke all on function public.fi_calculate_half(smallint, smallint) from public, anon, authenticated;
grant execute on function public.fi_calculate_half(smallint, smallint) to authenticated;
