-- Finanzen (FI), spec T5; US-FI-07 bis US-FI-12; R16, R17, R19, R20, R23, R33: Korrektur, Ausnahme, Bestätigung,
-- Vertretung, Abschluss (Sperre über fi_attendance_locked/fi_event_locked), Rücknahme, Abgabe, Verfall.

-- Abrechnung zum Ändern sperren und laden; intern
create function public.fi_lock_settlement(p_id uuid)
returns public.fi_settlements
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_s public.fi_settlements%rowtype;
begin
  select * into v_s from public.fi_settlements s where s.id = p_id for update;
  if not found or not public.fi_can_read_settlement(p_id) then
    raise exception 'FI_NOT_FOUND' using errcode = 'P0001', detail = coalesce(p_id::text, '');
  end if;
  return v_s;
end;
$$;

revoke all on function public.fi_lock_settlement(uuid) from public, anon, authenticated;

-- Bestätigung eines Referats zurücksetzen (R23); bestätigt → Entwurf; intern
create function public.fi_reset_confirmation(p_settlement uuid, p_referat uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  delete from public.fi_settlement_confirmations c where c.settlement_id = p_settlement and c.referat_id = p_referat;
  if found then
    perform public.fi_log(p_settlement, 'confirmation_reset', jsonb_build_object('referate', jsonb_build_array(p_referat)));
  end if;
  update public.fi_settlements set status = 'draft' where id = p_settlement and status = 'confirmed';
end;
$$;

revoke all on function public.fi_reset_confirmation(uuid, uuid) from public, anon, authenticated;

-- Alle Referate bestätigt → bestätigt; intern
create function public.fi_update_confirmed(p_settlement uuid)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.fi_settlements s set status = 'confirmed'
   where s.id = p_settlement and s.status = 'draft'
     and not exists (select 1 from public.fi_settlement_items i
                      where i.settlement_id = s.id
                        and not exists (select 1 from public.fi_settlement_confirmations c
                                         where c.settlement_id = s.id and c.referat_id = i.referat_id));
$$;

revoke all on function public.fi_update_confirmed(uuid) from public, anon, authenticated;

-- Korrektur einer Position (US-FI-07, R16); beide Werte null = Korrektur entfernen
create function public.fi_correct_item(p_item uuid, p_rate_role public.fi_rate_role, p_quantity numeric, p_reason text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_item public.fi_settlement_items%rowtype;
  v_s public.fi_settlements%rowtype;
  v_reason text := nullif(btrim(coalesce(p_reason, '')), '');
begin
  if not public.fi_can_manage() then
    raise exception 'FI_FORBIDDEN' using errcode = 'P0001';
  end if;
  select * into v_item from public.fi_settlement_items i where i.id = p_item;
  if not found then
    raise exception 'FI_NOT_FOUND' using errcode = 'P0001';
  end if;
  v_s := public.fi_lock_settlement(v_item.settlement_id);
  if v_s.status not in ('draft', 'confirmed') then
    raise exception 'FI_STATUS' using errcode = 'P0001';
  end if;
  if p_rate_role is null and p_quantity is null then
    update public.fi_settlement_items
       set override_rate_role = null, override_quantity = null, correction_reason = null,
           corrected_at = now(), corrected_by = auth.uid()
     where id = p_item;
  else
    if v_reason is null or char_length(v_reason) > 500 then
      raise exception 'FI_REASON_REQUIRED' using errcode = 'P0001';
    end if;
    if p_quantity is not null and (p_quantity < 0 or p_quantity <> round(p_quantity, 2) or p_quantity >= 10000) then
      raise exception 'FI_QUANTITY' using errcode = 'P0001';
    end if;
    update public.fi_settlement_items
       set override_rate_role = p_rate_role, override_quantity = p_quantity, correction_reason = v_reason,
           corrected_at = now(), corrected_by = auth.uid()
     where id = p_item;
  end if;
  perform public.fi_log(v_s.id, 'corrected', jsonb_build_object(
    'item', p_item, 'rate_role', p_rate_role, 'quantity', p_quantity, 'reason', v_reason));
  perform public.fi_reset_confirmation(v_s.id, v_item.referat_id);
end;
$$;

-- Begründung einer Ausnahme (Lizenz) durch die Referent:in oder die Geschäftsstelle (US-FI-08 AK4)
create function public.fi_set_exception_reason(p_item uuid, p_reason text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_item public.fi_settlement_items%rowtype;
  v_s public.fi_settlements%rowtype;
  v_reason text := nullif(btrim(coalesce(p_reason, '')), '');
begin
  select * into v_item from public.fi_settlement_items i where i.id = p_item;
  if not found then
    raise exception 'FI_NOT_FOUND' using errcode = 'P0001';
  end if;
  v_s := public.fi_lock_settlement(v_item.settlement_id);
  if not (public.fi_can_manage() or public.ad_can_approve('FI', v_item.referat_id)) then
    raise exception 'FI_FORBIDDEN' using errcode = 'P0001';
  end if;
  if v_s.status <> 'draft' then
    raise exception 'FI_STATUS' using errcode = 'P0001';
  end if;
  if char_length(v_reason) > 500 then
    raise exception 'FI_REASON_REQUIRED' using errcode = 'P0001';
  end if;
  update public.fi_settlement_items set exception_reason = v_reason where id = p_item;
  perform public.fi_log(v_s.id, 'exception_reason', jsonb_build_object('item', p_item, 'reason', v_reason));
end;
$$;

-- Bestätigung „sachlich richtig“ durch die Referent:in (US-FI-08, R23): alle eigenen Referate der Abrechnung
create function public.fi_confirm(p_ids uuid[])
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid;
  v_s public.fi_settlements%rowtype;
  v_all boolean := public.ad_has_approve('FI');
  v_mine uuid[] := public.fi_confirm_referate();
  v_refs uuid[];
begin
  foreach v_id in array coalesce(p_ids, '{}') loop
    v_s := public.fi_lock_settlement(v_id);
    if v_s.status <> 'draft' then
      raise exception 'FI_STATUS' using errcode = 'P0001', detail = v_id::text;
    end if;
    select coalesce(array_agg(distinct i.referat_id), '{}') into v_refs
      from public.fi_settlement_items i
     where i.settlement_id = v_id and (v_all or i.referat_id = any (v_mine));
    if cardinality(v_refs) = 0 then
      raise exception 'FI_FORBIDDEN' using errcode = 'P0001', detail = v_id::text;
    end if;
    insert into public.fi_settlement_confirmations (settlement_id, referat_id)
    select v_id, r from unnest(v_refs) as r
    on conflict (settlement_id, referat_id) do nothing;
    if found then
      perform public.fi_log(v_id, 'confirmed', jsonb_build_object('referate', to_jsonb(v_refs)));
    end if;
    perform public.fi_update_confirmed(v_id);
  end loop;
end;
$$;

-- Bestätigung in Vertretung durch die Geschäftsstelle (US-FI-09, R23)
create function public.fi_confirm_substitute(p_id uuid, p_referat uuid, p_reason text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_s public.fi_settlements%rowtype;
  v_reason text := nullif(btrim(coalesce(p_reason, '')), '');
begin
  if not public.fi_can_manage() then
    raise exception 'FI_FORBIDDEN' using errcode = 'P0001';
  end if;
  v_s := public.fi_lock_settlement(p_id);
  if v_s.status <> 'draft' then
    raise exception 'FI_STATUS' using errcode = 'P0001';
  end if;
  if not exists (select 1 from public.fi_settlement_items i where i.settlement_id = p_id and i.referat_id = p_referat) then
    raise exception 'FI_NOT_FOUND' using errcode = 'P0001';
  end if;
  if v_reason is null or char_length(v_reason) > 500 then
    raise exception 'FI_REASON_REQUIRED' using errcode = 'P0001';
  end if;
  insert into public.fi_settlement_confirmations (settlement_id, referat_id, is_substitute, substitute_reason)
  values (p_id, p_referat, true, v_reason)
  on conflict (settlement_id, referat_id) do nothing;
  if found then
    perform public.fi_log(p_id, 'confirmed_substitute', jsonb_build_object('referat', p_referat, 'reason', v_reason));
  end if;
  perform public.fi_update_confirmed(p_id);
end;
$$;

-- Abschluss (US-FI-10, R9, R17, R23): danach sind die Anwesenheiten gesperrt; alle oder keine
create function public.fi_close(p_ids uuid[])
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid;
  v_s public.fi_settlements%rowtype;
begin
  if not public.fi_can_manage() then
    raise exception 'FI_FORBIDDEN' using errcode = 'P0001';
  end if;
  foreach v_id in array coalesce(p_ids, '{}') loop
    v_s := public.fi_lock_settlement(v_id);
    if v_s.status <> 'confirmed' then
      raise exception 'FI_NOT_CONFIRMED' using errcode = 'P0001', detail = v_id::text;
    end if;
    if exists (select 1 from public.fi_settlement_items i where i.settlement_id = v_id and i.rate is null) then
      raise exception 'FI_RATE_MISSING' using errcode = 'P0001', detail = v_id::text;
    end if;
    if v_s.amount <= 0 then
      raise exception 'FI_AMOUNT_ZERO' using errcode = 'P0001', detail = v_id::text;
    end if;
    if exists (select 1 from public.fi_settlement_confirmations c where c.settlement_id = v_id and c.confirmed_by = auth.uid()) then
      raise exception 'FI_SAME_PERSON' using errcode = 'P0001', detail = v_id::text;
    end if;
    update public.fi_settlements
       set status = 'closed', closed_at = now(), closed_by = auth.uid(), closed_by_person_id = public.fi_my_person_id()
     where id = v_id;
    perform public.fi_log(v_id, 'closed');
  end loop;
end;
$$;

-- Rücknahme des Abschlusses vor der Abgabe (US-FI-11): Bestätigungen entfallen, Sperre aufgehoben
create function public.fi_reopen(p_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_s public.fi_settlements%rowtype;
begin
  if not public.fi_can_manage() then
    raise exception 'FI_FORBIDDEN' using errcode = 'P0001';
  end if;
  v_s := public.fi_lock_settlement(p_id);
  if v_s.status <> 'closed' then
    raise exception 'FI_STATUS' using errcode = 'P0001';
  end if;
  delete from public.fi_settlement_confirmations c where c.settlement_id = p_id;
  update public.fi_settlements
     set status = 'draft', closed_at = null, closed_by = null, closed_by_person_id = null
   where id = p_id;
  perform public.fi_log(p_id, 'reopened');
end;
$$;

-- Abgabe des unterschriebenen Abrechnungsdokuments (US-FI-12, R19); nach der Frist nur mit Begründung
create function public.fi_record_submission(p_id uuid, p_date date, p_late_reason text default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_s public.fi_settlements%rowtype;
  v_deadline date;
  v_reason text := nullif(btrim(coalesce(p_late_reason, '')), '');
begin
  if not public.fi_can_manage() then
    raise exception 'FI_FORBIDDEN' using errcode = 'P0001';
  end if;
  v_s := public.fi_lock_settlement(p_id);
  if v_s.status <> 'closed' then
    raise exception 'FI_STATUS' using errcode = 'P0001';
  end if;
  if p_date is null or p_date > current_date then
    raise exception 'FI_DATE_FUTURE' using errcode = 'P0001';
  end if;
  v_deadline := public.ad_settlement_deadline(v_s.year, v_s.half);
  if p_date > v_deadline and (v_reason is null or char_length(v_reason) > 500) then
    raise exception 'FI_LATE_REASON_REQUIRED' using errcode = 'P0001', detail = v_deadline::text;
  end if;
  update public.fi_settlements
     set status = 'submitted', submitted_on = p_date,
         submitted_late_reason = case when p_date > v_deadline then v_reason end
   where id = p_id;
  perform public.fi_log(p_id, 'submitted', jsonb_build_object('date', p_date, 'late_reason',
    case when p_date > v_deadline then v_reason end));
end;
$$;

-- Verfall nach Ablauf der Frist, von Hand (US-FI-12 AK3)
create function public.fi_expire(p_ids uuid[])
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid;
  v_s public.fi_settlements%rowtype;
begin
  if not public.fi_can_manage() then
    raise exception 'FI_FORBIDDEN' using errcode = 'P0001';
  end if;
  foreach v_id in array coalesce(p_ids, '{}') loop
    v_s := public.fi_lock_settlement(v_id);
    if v_s.status <> 'closed' then
      raise exception 'FI_STATUS' using errcode = 'P0001', detail = v_id::text;
    end if;
    if current_date <= public.ad_settlement_deadline(v_s.year, v_s.half) then
      raise exception 'FI_DEADLINE_NOT_PASSED' using errcode = 'P0001', detail = v_id::text;
    end if;
    update public.fi_settlements set status = 'expired', expired_at = now(), expired_by = auth.uid() where id = v_id;
    perform public.fi_log(v_id, 'expired');
  end loop;
end;
$$;

revoke all on function public.fi_correct_item(uuid, public.fi_rate_role, numeric, text) from public, anon, authenticated;
revoke all on function public.fi_set_exception_reason(uuid, text) from public, anon, authenticated;
revoke all on function public.fi_confirm(uuid[]) from public, anon, authenticated;
revoke all on function public.fi_confirm_substitute(uuid, uuid, text) from public, anon, authenticated;
revoke all on function public.fi_close(uuid[]) from public, anon, authenticated;
revoke all on function public.fi_reopen(uuid) from public, anon, authenticated;
revoke all on function public.fi_record_submission(uuid, date, text) from public, anon, authenticated;
revoke all on function public.fi_expire(uuid[]) from public, anon, authenticated;
grant execute on function public.fi_correct_item(uuid, public.fi_rate_role, numeric, text) to authenticated;
grant execute on function public.fi_set_exception_reason(uuid, text) to authenticated;
grant execute on function public.fi_confirm(uuid[]) to authenticated;
grant execute on function public.fi_confirm_substitute(uuid, uuid, text) to authenticated;
grant execute on function public.fi_close(uuid[]) to authenticated;
grant execute on function public.fi_reopen(uuid) to authenticated;
grant execute on function public.fi_record_submission(uuid, date, text) to authenticated;
grant execute on function public.fi_expire(uuid[]) to authenticated;
