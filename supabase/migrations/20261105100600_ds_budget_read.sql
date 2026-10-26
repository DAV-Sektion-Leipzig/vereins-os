-- Bereich Budget (spec.md DS v0.2 Abschnitt 2.3), Task T11 (DT11): Lesefunktionen des Dashboards
-- (US-DS-07 bis -10, -16 bis -18; R6, R7, R12 bis R14, R18, R20, R23). Alle Summen aus fi_budget_assigned.

create function public.ds_budget_require_read()
returns void language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.fi_budget_can_read() then
    raise exception 'FI_BUDGET_FORBIDDEN' using errcode = 'P0001';
  end if;
end;
$$;

-- Datenstand des aktuellen Imports eines Jahres
create function public.fi_budget_data_until(p_year smallint)
returns date language sql stable security definer set search_path = '' as $$
  select im.data_until from public.fi_budget_imports im where im.year = p_year and im.is_current;
$$;

-- Summe je Budgetposten bis zu einem Stichtag (R20). Mit Einzelbuchungen aus diesen; nach dem Löschlauf aus den
-- Monatssummen bis zum letzten vollen Monat vor dem Stichtag [ANNAHME spec R20].
create function public.fi_budget_item_sums(p_year smallint, p_until date)
returns table (item_id uuid, amount numeric)
language plpgsql stable security definer set search_path = '' as $$
begin
  if exists (select 1 from public.fi_budget_bookings b join public.fi_budget_imports im on im.id = b.import_id
              where im.year = p_year and im.is_current) then
    return query
      select a.item_id, sum(a.amount) from public.fi_budget_assigned a
       where a.year = p_year and a.item_id is not null and a.booking_date <= p_until
       group by a.item_id;
  else
    return query
      select i.id, sum(case when i.kind = 'income' then m.credit - m.debit else m.debit - m.credit end)
        from public.fi_budget_month_totals m
        cross join lateral (select public.fi_budget_match_rule(p_year, m.main_account, m.sub_account,
                              nullif(m.cost_center, ''), null, null, null, null, null) as rule_id) x
        join public.fi_budget_rules r on r.id = x.rule_id
        join public.fi_budget_items i on i.id = r.item_id
       where m.year = p_year and (make_date(m.year, m.month, 1) + interval '1 month' - interval '1 day')::date <= p_until
       group by i.id;
  end if;
end;
$$;

-- Posten „Vergütung Aktive“ eines Referats im Jahr (R18)
create function public.fi_budget_remuneration_item(p_year smallint, p_referat uuid)
returns uuid language sql stable security definer set search_path = '' as $$
  select i.id from public.fi_budget_items i join public.fi_budget_groups g on g.id = i.group_id
   where i.year = p_year and i.removed_at is null and i.kind = 'expense' and lower(i.name) = 'vergütung aktive'
     and g.visibility = 'referat' and g.referat_id = p_referat
   order by g.sort_order, i.sort_order limit 1;
$$;

-- Freigegebene Auszahlungsrunde gilt für ein Referat als gebucht (R18): von Hand markiert oder Buchung im Soll auf
-- einem Posten „Vergütung Aktive“ mit Betrag = Summe der Runde oder des Referats, Datum −3 bis +14 Tage
create function public.fi_budget_run_booked(p_run uuid, p_referat uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  with run as (
    select r.id, r.execution_date,
           (select sum(l.amount) from public.fi_payout_lines l where l.run_id = r.id) as total,
           (select sum(l.amount) from public.fi_payout_lines l left join public.gr_groups g on g.id = l.group_id
             where l.run_id = r.id and coalesce(l.referat_id, g.referat_id) = p_referat) as part
      from public.fi_payout_runs r where r.id = p_run)
  select exists (select 1 from public.fi_budget_payout_marks m where m.run_id = p_run)
      or exists (select 1 from run
                   join public.fi_budget_assigned a
                     on a.year = extract(year from run.execution_date)::smallint
                    and a.booking_date between run.execution_date - 3 and run.execution_date + 14
                    and a.debit > 0 and a.debit in (run.total, run.part)
                   join public.fi_budget_items i on i.id = a.item_id and lower(i.name) = 'vergütung aktive');
$$;

-- Vorschau je Referat (R18): freigegebene, nicht gebuchte Runden des Jahres; abgeschlossene, nicht ausgezahlte
-- Abrechnungen (getrennt ausgewiesen). Wird nie zu verbraucht, frei oder Ampel gerechnet.
create function public.fi_budget_preview(p_year smallint, p_referat uuid,
  out runs numeric, out settlements numeric)
language sql stable security definer set search_path = '' as $$
  select
    coalesce((select sum(l.amount)
                from public.fi_payout_runs r
                join public.fi_payout_lines l on l.run_id = r.id
                left join public.gr_groups g on g.id = l.group_id
               where r.status = 'released' and extract(year from r.execution_date) = p_year
                 and coalesce(l.referat_id, g.referat_id) = p_referat
                 and not public.fi_budget_run_booked(r.id, p_referat)), 0),
    coalesce((select sum(si.amount)
                from public.fi_settlements s
                join public.fi_settlement_items si on si.settlement_id = s.id
                left join public.fi_payout_runs r on r.id = s.payout_run_id
               where s.year = p_year and s.status in ('closed', 'submitted')
                 and (r.id is null or r.status <> 'released')
                 and si.referat_id = p_referat), 0);
$$;

-- ---------------------------------------------------------------------------------------------------------------
create function public.ds_budget_years()
returns setof smallint language plpgsql stable security definer set search_path = '' as $$
begin
  perform public.ds_budget_require_read();
  return query select p.year from public.fi_budget_plans p
                where p.year >= extract(year from current_date)::smallint - 1 order by p.year desc;
end;
$$;

-- Je Budgetposten (R12: Summen für alle mit DS lesen)
create function public.ds_budget_overview(p_year smallint)
returns table (item_id uuid, group_id uuid, group_name text, visibility public.fi_budget_visibility, referat_id uuid,
  referat_name text, kind public.fi_budget_kind, name text, no_booking boolean, plan_decided numeric,
  plan_current numeric, actual numeric, actual_prev_same_day numeric, actual_prev_full numeric, prev_found boolean,
  pct numeric, ampel text, note text, note_by text, note_at timestamptz, can_see_bookings boolean, can_edit boolean,
  open_reallocations int, open_proposals int, preview_runs numeric, preview_settlements numeric,
  status_uncertain boolean, is_mine boolean)
language plpgsql stable security definer set search_path = '' as $$
declare
  v_until date := public.fi_budget_data_until(p_year);
  v_prev_until date;
  v_prev smallint := p_year - 1;
begin
  perform public.ds_budget_require_read();
  v_prev_until := (coalesce(v_until, make_date(p_year, 12, 31)) - interval '1 year')::date;
  return query
  with act as (select a.item_id, sum(a.amount) as amount from public.fi_budget_assigned a
                where a.year = p_year and a.item_id is not null group by a.item_id),
  prev_day as (select * from public.fi_budget_item_sums(v_prev, v_prev_until)),
  prev_full as (select * from public.fi_budget_item_sums(v_prev, make_date(v_prev, 12, 31))),
  base as (
    select i.id, i.group_id, g.name as group_name, g.visibility, g.referat_id, rf.name as referat_name, i.kind,
           i.name, i.no_booking, i.plan_decided, coalesce(public.fi_budget_plan_current(i.id), 0) as plan_current,
           coalesce(act.amount, 0) as actual,
           pi.id as prev_id, g.sort_order as g_sort, i.sort_order as i_sort
      from public.fi_budget_items i
      join public.fi_budget_groups g on g.id = i.group_id
      left join public.ea_referate rf on rf.id = g.referat_id
      left join act on act.item_id = i.id
      left join lateral (
        select p.id from public.fi_budget_items p join public.fi_budget_groups pg on pg.id = p.group_id
         where p.year = v_prev and p.removed_at is null and p.kind = i.kind and lower(p.name) = lower(i.name)
           and lower(pg.name) = lower(g.name) limit 1) pi on true
     where i.year = p_year and i.removed_at is null)
  select b.id, b.group_id, b.group_name, b.visibility, b.referat_id, b.referat_name, b.kind, b.name, b.no_booking,
         b.plan_decided, b.plan_current, b.actual,
         case when b.prev_id is not null then coalesce(pd.amount, 0) end,
         case when b.prev_id is not null then coalesce(pf.amount, 0) end,
         b.prev_id is not null,
         case when b.plan_current > 0 then round(b.actual / b.plan_current * 100, 1) end,
         case when b.kind = 'income' then null
              when b.plan_current <= 0 then case when b.actual > 0 then 'no_plan' end
              when b.actual / b.plan_current < 0.8 then 'ok'
              when b.actual / b.plan_current <= 1 then 'warn'
              else 'over' end,
         n.text, public.fi_person_label(n.created_by_person_id), n.created_at,
         public.fi_budget_can_see_bookings(b.id), public.fi_budget_can_edit_item(b.id),
         (select count(*)::int from public.fi_budget_reallocations a
           where a.status = 'requested' and b.id in (a.from_item, a.to_item)),
         (select count(*)::int from public.fi_budget_proposals p
           where p.status = 'proposed' and b.id in (p.from_item, p.to_item)),
         pv.runs, pv.settlements,
         exists (select 1 from public.fi_budget_rules r
                  where r.item_id = b.id and r.valid_to is null and r.status in ('uncertain', 'open')),
         public.fi_budget_group_mine(b.group_id)
    from base b
    left join prev_day pd on pd.item_id = b.prev_id
    left join prev_full pf on pf.item_id = b.prev_id
    left join public.fi_budget_notes n on n.item_id = b.id and n.valid_to is null
    left join lateral (
      select x.runs, x.settlements from public.fi_budget_preview(p_year, b.referat_id) x
       where b.referat_id is not null and b.id = public.fi_budget_remuneration_item(p_year, b.referat_id)) pv on true
   order by b.g_sort, b.group_name, b.kind desc, b.i_sort, b.name;
end;
$$;

-- Kopf: Summen des Vereins, Datenstand, Jahresfortschritt (R7), Datenstand alt (R23)
create function public.ds_budget_head(p_year smallint)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare
  v_im record;
  v_r jsonb;
begin
  perform public.ds_budget_require_read();
  select * into v_im from public.fi_budget_imports where year = p_year and is_current;
  with o as (
    select i.kind, i.no_booking, coalesce(public.fi_budget_plan_current(i.id), 0) as plan,
           coalesce((select sum(a.amount) from public.fi_budget_assigned a where a.item_id = i.id), 0) as actual
      from public.fi_budget_items i where i.year = p_year and i.removed_at is null)
  select jsonb_build_object(
    'year', p_year,
    'has_plan', exists (select 1 from public.fi_budget_plans p where p.year = p_year),
    'expense_plan', coalesce(sum(plan) filter (where kind = 'expense'), 0),
    'expense_actual', coalesce(sum(actual) filter (where kind = 'expense'), 0),
    'expense_free', coalesce(sum(plan - actual) filter (where kind = 'expense'), 0),
    'income_plan', coalesce(sum(plan) filter (where kind = 'income'), 0),
    'income_actual', coalesce(sum(actual) filter (where kind = 'income'), 0),
    'income_missing', coalesce(sum(greatest(plan - actual, 0)) filter (where kind = 'income' and not no_booking), 0))
    into v_r from o;
  return v_r || jsonb_build_object(
    'data_until', v_im.data_until,
    'imported_at', v_im.imported_at,
    'progress', case when v_im.data_until is not null then
                  round((v_im.data_until - make_date(p_year, 1, 1) + 1)::numeric
                        / (make_date(p_year + 1, 1, 1) - make_date(p_year, 1, 1)) * 100, 1) end,
    'data_stale', p_year = extract(year from current_date)
                  and (v_im.data_until is null or current_date - v_im.data_until > 42));
end;
$$;

-- Einzelbuchungen eines Budgetpostens (R13)
create function public.ds_budget_bookings(p_item uuid)
returns table (booking_id uuid, booking_date date, account text, contra_label text, booking_text text, receipt text,
  cost_center text, amount numeric, rekeyed boolean, rekey_info text, rule_id uuid, proposal_open boolean)
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.fi_budget_can_see_bookings(p_item) then
    raise exception 'FI_BUDGET_FORBIDDEN' using errcode = 'P0001';
  end if;
  return query
    select a.id, a.booking_date, a.main_account || ' ' || a.sub_account, a.contra_label, a.booking_text, a.receipt,
           a.cost_center, a.amount, a.rule_type = 'booking', case when a.rule_type = 'booking' then r.reason end,
           a.rule_id,
           exists (select 1 from public.fi_budget_proposals p where p.booking_id = a.id and p.status = 'proposed')
      from public.fi_budget_assigned a join public.fi_budget_rules r on r.id = a.rule_id
     where a.item_id = p_item
     order by a.booking_date desc, a.line_no;
end;
$$;

create function public.ds_budget_account_sums(p_item uuid)
returns table (account text, account_label text, debit numeric, credit numeric, amount numeric, bookings int)
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.fi_budget_can_see_bookings(p_item) then
    raise exception 'FI_BUDGET_FORBIDDEN' using errcode = 'P0001';
  end if;
  return query
    select a.main_account || ' ' || a.sub_account, max(r.account_label), sum(a.debit), sum(a.credit), sum(a.amount),
           count(*)::int
      from public.fi_budget_assigned a join public.fi_budget_rules r on r.id = a.rule_id
     where a.item_id = p_item
     group by a.main_account, a.sub_account
     order by a.main_account, a.sub_account;
end;
$$;

-- Nicht zugeordnete Buchungen (R14): Regel ohne Budgetposten; Betrag Soll − Haben (R3)
create function public.ds_budget_unassigned(p_year smallint)
returns table (booking_id uuid, booking_date date, account text, contra_label text, booking_text text, receipt text,
  cost_center text, amount numeric, rule_id uuid, rule_status public.fi_budget_rule_status)
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.fi_budget_scope_all() then
    raise exception 'FI_BUDGET_FORBIDDEN' using errcode = 'P0001';
  end if;
  return query
    select a.id, a.booking_date, a.main_account || ' ' || a.sub_account, a.contra_label, a.booking_text, a.receipt,
           a.cost_center, a.debit - a.credit, a.rule_id, r.status
      from public.fi_budget_assigned a join public.fi_budget_rules r on r.id = a.rule_id
     where a.year = p_year and a.item_id is null
     order by a.booking_date desc, a.line_no;
end;
$$;

-- Prüfung: Ergebnis des aktuellen Imports, Umschlüsselungen, unsichere Regeln
create function public.ds_budget_checks(p_year smallint)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare
  v_im record;
begin
  if not public.fi_budget_scope_all() then
    raise exception 'FI_BUDGET_FORBIDDEN' using errcode = 'P0001';
  end if;
  select * into v_im from public.fi_budget_imports where year = p_year and is_current;
  return jsonb_build_object(
    'import', case when v_im.id is not null then jsonb_build_object(
      'id', v_im.id, 'file_name', v_im.file_name, 'export_info', v_im.export_info, 'data_until', v_im.data_until,
      'imported_at', v_im.imported_at, 'rows_read', v_im.rows_read, 'rows_saved', v_im.rows_saved,
      'rows_ignored', v_im.rows_ignored, 'rows_opening', v_im.rows_opening, 'rows_other_year', v_im.rows_other_year,
      'checks', v_im.checks, 'warnings', v_im.warnings) end,
    'rekeyed', coalesce((
      select jsonb_agg(jsonb_build_object('rule_id', r.id, 'account', r.account_text, 'date', r.b_date,
               'amount', r.b_amount, 'side', r.b_side, 'item', i.name, 'reason', r.reason,
               'found', exists (select 1 from public.fi_budget_assigned a where a.rule_id = r.id))
               order by r.b_date)
        from public.fi_budget_rules r left join public.fi_budget_items i on i.id = r.item_id
       where r.year = p_year and r.valid_to is null and r.rule_type = 'booking'), '[]'),
    'uncertain', coalesce((
      select jsonb_agg(jsonb_build_object('rule_id', r.id, 'account', r.account_text, 'status', r.status,
               'item', i.name, 'note', r.note) order by r.account_text)
        from public.fi_budget_rules r left join public.fi_budget_items i on i.id = r.item_id
       where r.year = p_year and r.valid_to is null and r.status in ('uncertain', 'open')), '[]'));
end;
$$;

-- Umschichtungen und Vorschläge: eigene (alle) und, mit Budgetpflege, alle offenen
create function public.ds_budget_requests(p_year smallint)
returns table (request_type text, id uuid, status text, from_item uuid, from_name text, to_item uuid, to_name text,
  amount numeric, booking_date date, booking_text text, reason text, requested_by text, requested_at timestamptz,
  decided_by text, decided_at timestamptz, decision_reason text, is_mine boolean, can_decide boolean)
language plpgsql stable security definer set search_path = '' as $$
declare
  v_maintain boolean := public.ad_has_budget_maintain();
begin
  perform public.ds_budget_require_read();
  return query
    select 'reallocation'::text, a.id, a.status::text, a.from_item, fi.name, a.to_item, ti.name, a.amount, null::date,
           null::text, a.reason, public.fi_person_label(a.requested_by_person_id), a.requested_at,
           public.fi_person_label(a.decided_by_person_id), a.decided_at, a.decision_reason,
           a.requested_by = auth.uid(),
           v_maintain and a.status = 'requested' and a.requested_by is distinct from auth.uid()
      from public.fi_budget_reallocations a
      join public.fi_budget_items fi on fi.id = a.from_item
      join public.fi_budget_items ti on ti.id = a.to_item
     where a.year = p_year and (a.requested_by = auth.uid() or (v_maintain and a.status = 'requested'))
    union all
    select 'proposal', p.id, p.status::text, p.from_item, fi.name, p.to_item, ti.name, p.b_amount, p.b_date,
           case when p.from_item is null or public.fi_budget_can_see_bookings(p.from_item) then p.b_text end,
           p.reason, public.fi_person_label(p.proposed_by_person_id), p.proposed_at, null, p.decided_at,
           p.decision_reason, p.proposed_by = auth.uid(), v_maintain and p.status = 'proposed'
      from public.fi_budget_proposals p
      left join public.fi_budget_items fi on fi.id = p.from_item
      join public.fi_budget_items ti on ti.id = p.to_item
     where p.year = p_year and (p.proposed_by = auth.uid() or (v_maintain and p.status = 'proposed'))
     order by 13 desc;
end;
$$;

-- Block ① „Zu tun“ (US-DS-17)
create function public.ds_todo()
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare
  v_year smallint := extract(year from current_date)::smallint;
  v_r jsonb := '[]';
  v_n int;
  v_d date;
  v_maintain boolean := public.ad_has_budget_maintain();
begin
  -- Abrechnungen zur Bestätigung (Finanzen)
  select count(distinct s.id), min(public.ad_settlement_deadline(s.year, s.half)) into v_n, v_d
    from public.fi_settlements s join public.fi_settlement_items i on i.settlement_id = s.id
   where s.status = 'draft' and i.referat_id = any (public.fi_confirm_referate())
     and not exists (select 1 from public.fi_settlement_confirmations c
                      where c.settlement_id = s.id and c.referat_id = i.referat_id);
  if v_n > 0 then
    v_r := v_r || jsonb_build_object('type', 'settlements_confirm', 'count', v_n, 'deadline', v_d);
  end if;

  if not public.fi_budget_can_read() then
    return v_r;
  end if;

  -- eigene Anträge und Vorschläge: offen oder in den letzten 14 Tagen entschieden [ANNAHME]
  select v_r || coalesce(jsonb_agg(jsonb_build_object('type', 'own_' || t.request_type, 'id', t.id,
           'status', t.status, 'from_name', t.from_name, 'to_name', t.to_name, 'amount', t.amount,
           'decided_at', t.decided_at, 'decision_reason', t.decision_reason) order by t.requested_at desc), '[]')
    into v_r
    from public.ds_budget_requests(v_year) t
   where t.is_mine and (t.status in ('requested', 'proposed') or t.decided_at > now() - interval '14 days');

  if not v_maintain then
    return v_r;
  end if;

  select count(*) into v_n from public.fi_budget_reallocations
   where status = 'requested' and requested_by is distinct from auth.uid();
  if v_n > 0 then v_r := v_r || jsonb_build_object('type', 'reallocations_open', 'count', v_n); end if;
  select count(*) into v_n from public.fi_budget_proposals where status = 'proposed';
  if v_n > 0 then v_r := v_r || jsonb_build_object('type', 'proposals_open', 'count', v_n); end if;
  select count(*) into v_n from public.fi_budget_assigned where year = v_year and item_id is null;
  if v_n > 0 then v_r := v_r || jsonb_build_object('type', 'unassigned', 'count', v_n); end if;
  select count(*) into v_n from public.fi_budget_rules
   where year = v_year and valid_to is null and status in ('uncertain', 'open');
  if v_n > 0 then v_r := v_r || jsonb_build_object('type', 'rules_uncertain', 'count', v_n); end if;
  if exists (select 1 from public.fi_budget_plans where year = v_year) then
    v_d := public.fi_budget_data_until(v_year);
    if v_d is null or current_date - v_d > 42 then
      v_r := v_r || jsonb_build_object('type', 'data_stale', 'data_until', v_d);
    end if;
  end if;
  if exists (select 1 from public.fi_budget_log l where l.action = 'purge_failed'
                and not exists (select 1 from public.fi_budget_log k where k.action = 'purge' and k.at > l.at)) then
    v_r := v_r || jsonb_build_object('type', 'purge_failed');
  end if;
  return v_r;
end;
$$;

revoke all on function public.ds_budget_require_read(), public.fi_budget_data_until(smallint),
  public.fi_budget_item_sums(smallint, date), public.fi_budget_remuneration_item(smallint, uuid),
  public.fi_budget_run_booked(uuid, uuid), public.fi_budget_preview(smallint, uuid)
  from public, anon, authenticated;
revoke all on function public.ds_budget_years(), public.ds_budget_overview(smallint), public.ds_budget_head(smallint),
  public.ds_budget_bookings(uuid), public.ds_budget_account_sums(uuid), public.ds_budget_unassigned(smallint),
  public.ds_budget_checks(smallint), public.ds_budget_requests(smallint), public.ds_todo()
  from public, anon;
grant execute on function public.ds_budget_years(), public.ds_budget_overview(smallint),
  public.ds_budget_head(smallint), public.ds_budget_bookings(uuid), public.ds_budget_account_sums(uuid),
  public.ds_budget_unassigned(smallint), public.ds_budget_checks(smallint), public.ds_budget_requests(smallint),
  public.ds_todo() to authenticated;
