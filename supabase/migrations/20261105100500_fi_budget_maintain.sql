-- Bereich Budget (spec.md DS v0.2 Abschnitte 2.3, 4), Task T10 (DT10): Umschlüsseln (US-FI-27),
-- Umschlüsselungs-Vorschläge (US-DS-14, -15), Hinweise (US-DS-11), Umschichtungen (US-DS-12, -13; R15, Q-DS18),
-- Markierung „Auszahlungsrunde gebucht“ (R18).

-- Buchung des aktuellen Imports mit Regel und Budgetposten (intern)
create function public.fi_budget_booking_info(p_booking uuid)
returns table (id uuid, year smallint, main_account int, sub_account smallint, booking_date date, receipt text,
  booking_text text, debit numeric, credit numeric, rule_id uuid, item_id uuid)
language sql stable security definer set search_path = '' as $$
  select a.id, a.year, a.main_account, a.sub_account, a.booking_date, a.receipt, a.booking_text, a.debit, a.credit,
         a.rule_id, a.item_id
    from public.fi_budget_assigned a where a.id = p_booking;
$$;

-- ---------------------------------------------------------------------------------------------------------------
-- Umschlüsseln (Budgetpflege): p_scope 'booking' = nur diese Buchung, 'account' = alle Buchungen auf dem Konto
create function public.fi_budget_rekey(p_booking uuid, p_item uuid, p_scope text, p_reason text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  v_b record;
  v_id uuid;
  v_old uuid;
begin
  perform public.fi_budget_require_maintain();
  select * into v_b from public.fi_budget_booking_info(p_booking);
  if v_b.id is null then
    raise exception 'FI_BUDGET_BOOKING_UNKNOWN' using errcode = 'P0001';
  end if;
  if btrim(coalesce(p_reason, '')) = '' then
    raise exception 'FI_BUDGET_REASON_REQUIRED' using errcode = 'P0001';
  end if;
  if not exists (select 1 from public.fi_budget_items i where i.id = p_item and i.year = v_b.year and i.removed_at is null) then
    raise exception 'FI_BUDGET_ITEM_UNKNOWN' using errcode = 'P0001';
  end if;
  if coalesce(p_scope, 'booking') = 'account' then
    update public.fi_budget_rules set valid_to = now()
     where year = v_b.year and valid_to is null and rule_type = 'account' and main_account = v_b.main_account
       and sub_account = v_b.sub_account and cardinality(cost_centers) = 0
    returning id into v_old;
    v_id := public.fi_budget_rule_insert(v_b.year, jsonb_build_object(
      'account_text', v_b.main_account || ' ' || v_b.sub_account, 'item_id', p_item, 'status', 'ok',
      'note', left(btrim(p_reason), 500)), 'Umschlüsselung Konto');
  elsif p_scope = 'booking' then
    update public.fi_budget_rules set valid_to = now()
     where id = v_b.rule_id and rule_type = 'booking' and valid_to is null
    returning id into v_old;
    v_id := public.fi_budget_rule_insert(v_b.year, jsonb_build_object(
      'account_text', v_b.main_account || ' ' || v_b.sub_account, 'item_id', p_item, 'status', 'ok',
      'b_date', v_b.booking_date, 'b_receipt', v_b.receipt, 'b_text', v_b.booking_text,
      'b_amount', case when v_b.debit > 0 then v_b.debit else v_b.credit end,
      'b_side', case when v_b.debit > 0 then 'S' else 'H' end, 'reason', btrim(p_reason)), 'Umschlüsselung');
  else
    raise exception 'FI_BUDGET_SCOPE_INVALID' using errcode = 'P0001';
  end if;
  perform public.fi_budget_write_log(v_b.year, 'rekey', v_id,
    jsonb_build_object('scope', coalesce(p_scope, 'booking'), 'from_item', v_b.item_id, 'to_item', p_item,
                       'replaces', v_old));
  return v_id;
end;
$$;

create function public.fi_budget_rekey_undo(p_rule uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare
  v_year smallint;
begin
  perform public.fi_budget_require_maintain();
  update public.fi_budget_rules set valid_to = now()
   where id = p_rule and rule_type = 'booking' and valid_to is null
  returning year into v_year;
  if v_year is null then
    raise exception 'FI_BUDGET_RULE_UNKNOWN' using errcode = 'P0001';
  end if;
  perform public.fi_budget_write_log(v_year, 'rekey_undo', p_rule, '{}');
end;
$$;

-- ---------------------------------------------------------------------------------------------------------------
-- Umschlüsselungs-Vorschlag (Referent:in für Buchungen ihres Referats, R16)
create function public.fi_budget_proposal_create(p_booking uuid, p_to uuid, p_reason text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  v_b record;
  v_id uuid;
begin
  select * into v_b from public.fi_budget_booking_info(p_booking);
  if v_b.id is null then
    raise exception 'FI_BUDGET_BOOKING_UNKNOWN' using errcode = 'P0001';
  end if;
  if v_b.item_id is null or not public.fi_budget_can_edit_item(v_b.item_id) then
    raise exception 'FI_BUDGET_FORBIDDEN' using errcode = 'P0001';
  end if;
  if btrim(coalesce(p_reason, '')) = '' then
    raise exception 'FI_BUDGET_REASON_REQUIRED' using errcode = 'P0001';
  end if;
  if p_to = v_b.item_id or not exists (select 1 from public.fi_budget_items i
                                        where i.id = p_to and i.year = v_b.year and i.removed_at is null) then
    raise exception 'FI_BUDGET_ITEM_UNKNOWN' using errcode = 'P0001';
  end if;
  begin
    insert into public.fi_budget_proposals (year, booking_id, b_date, b_main_account, b_sub_account, b_receipt, b_amount,
      b_side, b_text, from_item, to_item, reason, proposed_by_person_id)
    values (v_b.year, v_b.id, v_b.booking_date, v_b.main_account, v_b.sub_account, v_b.receipt,
      case when v_b.debit > 0 then v_b.debit else v_b.credit end, case when v_b.debit > 0 then 'S' else 'H' end,
      v_b.booking_text, v_b.item_id, p_to, btrim(p_reason), public.fi_my_person_id())
    returning id into v_id;
  exception when unique_violation then
    raise exception 'FI_BUDGET_PROPOSAL_OPEN' using errcode = 'P0001';
  end;
  perform public.fi_budget_write_log(v_b.year, 'proposal_create', v_id,
    jsonb_build_object('from_item', v_b.item_id, 'to_item', p_to));
  return v_id;
end;
$$;

create function public.fi_budget_proposal_withdraw(p_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare
  v_p record;
begin
  select * into v_p from public.fi_budget_proposals where id = p_id;
  if v_p.id is null or v_p.proposed_by is distinct from auth.uid() then
    raise exception 'FI_BUDGET_FORBIDDEN' using errcode = 'P0001';
  end if;
  if v_p.status <> 'proposed' then
    raise exception 'FI_BUDGET_STATE' using errcode = 'P0001';
  end if;
  update public.fi_budget_proposals set status = 'withdrawn', decided_by = auth.uid(), decided_at = now() where id = p_id;
  perform public.fi_budget_write_log(v_p.year, 'proposal_withdraw', p_id, '{}');
end;
$$;

create function public.fi_budget_proposal_decide(p_id uuid, p_accept boolean, p_scope text, p_reason text)
returns void language plpgsql security definer set search_path = '' as $$
declare
  v_p record;
  v_rule uuid;
begin
  perform public.fi_budget_require_maintain();
  select * into v_p from public.fi_budget_proposals where id = p_id;
  if v_p.id is null or v_p.status <> 'proposed' or (p_accept and v_p.booking_id is null) then
    raise exception 'FI_BUDGET_STATE' using errcode = 'P0001';
  end if;
  if p_accept then
    v_rule := public.fi_budget_rekey(v_p.booking_id, v_p.to_item, coalesce(p_scope, 'booking'), v_p.reason);
    update public.fi_budget_proposals
       set status = 'accepted', decided_by = auth.uid(), decided_at = now(), rule_id = v_rule,
           decision_reason = nullif(btrim(coalesce(p_reason, '')), '')
     where id = p_id;
  else
    if btrim(coalesce(p_reason, '')) = '' then
      raise exception 'FI_BUDGET_REASON_REQUIRED' using errcode = 'P0001';
    end if;
    update public.fi_budget_proposals
       set status = 'rejected', decided_by = auth.uid(), decided_at = now(), decision_reason = btrim(p_reason)
     where id = p_id;
  end if;
  perform public.fi_budget_write_log(v_p.year, case when p_accept then 'proposal_accept' else 'proposal_reject' end,
    p_id, '{}');
end;
$$;

-- ---------------------------------------------------------------------------------------------------------------
-- Hinweis je Budgetposten (R17); leerer Text beendet den Hinweis
create function public.fi_budget_note_save(p_item uuid, p_text text)
returns void language plpgsql security definer set search_path = '' as $$
declare
  v_year smallint;
begin
  select year into v_year from public.fi_budget_items where id = p_item and removed_at is null;
  if v_year is null or not public.fi_budget_can_edit_item(p_item) then
    raise exception 'FI_BUDGET_FORBIDDEN' using errcode = 'P0001';
  end if;
  if char_length(btrim(coalesce(p_text, ''))) > 500 then
    raise exception 'FI_BUDGET_NOTE_TOO_LONG' using errcode = 'P0001';
  end if;
  update public.fi_budget_notes set valid_to = now() where item_id = p_item and valid_to is null;
  if btrim(coalesce(p_text, '')) <> '' then
    insert into public.fi_budget_notes (item_id, text, created_by_person_id)
    values (p_item, btrim(p_text), public.fi_my_person_id());
  end if;
  perform public.fi_budget_write_log(v_year, 'note', p_item, '{}');
end;
$$;

-- ---------------------------------------------------------------------------------------------------------------
-- Umschichtung (R15): nur innerhalb eines Gesamtbudgets, gleiche Art, Summe bleibt; Bestätigung durch die Budgetpflege
create function public.fi_budget_realloc_check(p_from uuid, p_to uuid, p_amount numeric)
returns smallint language plpgsql stable security definer set search_path = '' as $$
declare
  v_f record;
  v_t record;
begin
  select * into v_f from public.fi_budget_items where id = p_from and removed_at is null;
  select * into v_t from public.fi_budget_items where id = p_to and removed_at is null;
  if v_f.id is null or v_t.id is null or v_f.id = v_t.id or v_f.group_id <> v_t.group_id or v_f.kind <> v_t.kind then
    raise exception 'FI_BUDGET_REALLOC_GROUP' using errcode = 'P0001';
  end if;
  if p_amount is null or p_amount <= 0 or p_amount > coalesce(public.fi_budget_plan_current(p_from), 0) then
    raise exception 'FI_BUDGET_REALLOC_AMOUNT' using errcode = 'P0001', detail = v_f.name;
  end if;
  return v_f.year;
end;
$$;

create function public.fi_budget_realloc_request(p_from uuid, p_to uuid, p_amount numeric, p_reason text,
  p_direct boolean default false)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  v_year smallint;
  v_id uuid;
  v_direct boolean := coalesce(p_direct, false);
begin
  if not public.fi_budget_can_edit_item(p_from) or (v_direct and not public.ad_has_budget_maintain()) then
    raise exception 'FI_BUDGET_FORBIDDEN' using errcode = 'P0001';
  end if;
  if btrim(coalesce(p_reason, '')) = '' then
    raise exception 'FI_BUDGET_REASON_REQUIRED' using errcode = 'P0001';
  end if;
  v_year := public.fi_budget_realloc_check(p_from, p_to, p_amount);
  insert into public.fi_budget_reallocations (year, from_item, to_item, amount, reason, status, requested_by_person_id,
    decided_by, decided_by_person_id, decided_at)
  values (v_year, p_from, p_to, p_amount, btrim(p_reason),
    case when v_direct then 'confirmed' else 'requested' end::public.fi_budget_realloc_status, public.fi_my_person_id(),
    case when v_direct then auth.uid() end, case when v_direct then public.fi_my_person_id() end,
    case when v_direct then now() end)
  returning id into v_id;
  perform public.fi_budget_write_log(v_year, case when v_direct then 'realloc_confirm' else 'realloc_request' end, v_id,
    jsonb_build_object('from_item', p_from, 'to_item', p_to, 'amount', p_amount, 'direct', v_direct));
  return v_id;
end;
$$;

create function public.fi_budget_realloc_withdraw(p_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare
  v_a record;
begin
  select * into v_a from public.fi_budget_reallocations where id = p_id;
  if v_a.id is null or v_a.requested_by is distinct from auth.uid() then
    raise exception 'FI_BUDGET_FORBIDDEN' using errcode = 'P0001';
  end if;
  if v_a.status <> 'requested' then
    raise exception 'FI_BUDGET_STATE' using errcode = 'P0001';
  end if;
  update public.fi_budget_reallocations set status = 'withdrawn', decided_at = now(), decided_by = auth.uid()
   where id = p_id;
  perform public.fi_budget_write_log(v_a.year, 'realloc_withdraw', p_id, '{}');
end;
$$;

create function public.fi_budget_realloc_decide(p_id uuid, p_confirm boolean, p_reason text)
returns void language plpgsql security definer set search_path = '' as $$
declare
  v_a record;
begin
  perform public.fi_budget_require_maintain();
  select * into v_a from public.fi_budget_reallocations where id = p_id;
  if v_a.id is null or v_a.status <> 'requested' then
    raise exception 'FI_BUDGET_STATE' using errcode = 'P0001';
  end if;
  if v_a.requested_by = auth.uid() then
    raise exception 'FI_BUDGET_OWN_REQUEST' using errcode = 'P0001';
  end if;
  if p_confirm then
    begin
      perform public.fi_budget_realloc_check(v_a.from_item, v_a.to_item, v_a.amount);
    exception when raise_exception then
      raise exception 'FI_BUDGET_REALLOC_STALE' using errcode = 'P0001';
    end;
    update public.fi_budget_reallocations
       set status = 'confirmed', decided_by = auth.uid(), decided_by_person_id = public.fi_my_person_id(),
           decided_at = now(), decision_reason = nullif(btrim(coalesce(p_reason, '')), '')
     where id = p_id;
  else
    if btrim(coalesce(p_reason, '')) = '' then
      raise exception 'FI_BUDGET_REASON_REQUIRED' using errcode = 'P0001';
    end if;
    update public.fi_budget_reallocations
       set status = 'rejected', decided_by = auth.uid(), decided_by_person_id = public.fi_my_person_id(),
           decided_at = now(), decision_reason = btrim(p_reason)
     where id = p_id;
  end if;
  perform public.fi_budget_write_log(v_a.year, case when p_confirm then 'realloc_confirm' else 'realloc_reject' end,
    p_id, '{}');
end;
$$;

-- ---------------------------------------------------------------------------------------------------------------
-- Auszahlungsrunde von Hand als gebucht markieren oder Markierung entfernen (R18)
create function public.fi_budget_payout_mark(p_run uuid, p_booked boolean)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform public.fi_budget_require_maintain();
  if not exists (select 1 from public.fi_payout_runs r where r.id = p_run and r.status = 'released') then
    raise exception 'FI_BUDGET_STATE' using errcode = 'P0001';
  end if;
  if p_booked then
    insert into public.fi_budget_payout_marks (run_id) values (p_run) on conflict do nothing;
  else
    delete from public.fi_budget_payout_marks where run_id = p_run;
  end if;
  perform public.fi_budget_write_log(
    (select extract(year from r.execution_date)::smallint from public.fi_payout_runs r where r.id = p_run),
    'payout_mark', p_run, jsonb_build_object('booked', p_booked));
end;
$$;

revoke all on function public.fi_budget_booking_info(uuid), public.fi_budget_realloc_check(uuid, uuid, numeric)
  from public, anon, authenticated;
revoke all on function public.fi_budget_rekey(uuid, uuid, text, text), public.fi_budget_rekey_undo(uuid),
  public.fi_budget_proposal_create(uuid, uuid, text), public.fi_budget_proposal_withdraw(uuid),
  public.fi_budget_proposal_decide(uuid, boolean, text, text), public.fi_budget_note_save(uuid, text),
  public.fi_budget_realloc_request(uuid, uuid, numeric, text, boolean), public.fi_budget_realloc_withdraw(uuid),
  public.fi_budget_realloc_decide(uuid, boolean, text), public.fi_budget_payout_mark(uuid, boolean)
  from public, anon;
grant execute on function public.fi_budget_rekey(uuid, uuid, text, text), public.fi_budget_rekey_undo(uuid),
  public.fi_budget_proposal_create(uuid, uuid, text), public.fi_budget_proposal_withdraw(uuid),
  public.fi_budget_proposal_decide(uuid, boolean, text, text), public.fi_budget_note_save(uuid, text),
  public.fi_budget_realloc_request(uuid, uuid, numeric, text, boolean), public.fi_budget_realloc_withdraw(uuid),
  public.fi_budget_realloc_decide(uuid, boolean, text), public.fi_budget_payout_mark(uuid, boolean)
  to authenticated;
