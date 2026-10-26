-- Planungshilfe Touren und Kurse (TK), spec T8; spec.md TK v0.4 Abschnitt 4 (Zustände), R3, R6, R21; tasks.md T008.
-- tk_change_status ohne Aufrufe der Anwesenheitserfassung; publish und cancel erzeugen bzw. markieren den Einsatz
-- ab Stufe 3 (tasks.md T015).

create function public.tk_change_status(
  p_id uuid, p_action text, p_comment text default null, p_yolawo_ref text default null, p_row_version int default null)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_plan public.tk_plans%rowtype;
  v_comment text := nullif(btrim(coalesce(p_comment, '')), '');
  v_ref text := nullif(btrim(coalesce(p_yolawo_ref, '')), '');
  v_from public.tk_plan_status;
  v_to public.tk_plan_status;
  v_event text;
  v_allowed boolean;
  v_missing text[];
  v_start date;
begin
  select * into v_plan from public.tk_plans p where p.id = p_id for update;
  if not found or not public.tk_can_read(v_plan.referat_id) then
    raise exception 'TK_NOT_FOUND' using errcode = 'P0001';
  end if;
  if p_row_version is not null and p_row_version <> v_plan.row_version then
    raise exception 'TK_CONFLICT' using errcode = 'P0001', detail = public.tk_last_editor(v_plan);
  end if;
  v_from := v_plan.status;

  -- Übergang und Recht (Abschnitt 4)
  case p_action
    when 'submit' then
      v_to := 'submitted'; v_event := 'submitted';
      v_allowed := v_from = 'draft';
      if not public.tk_can_write(v_plan.referat_id) then raise exception 'TK_FORBIDDEN' using errcode = 'P0001'; end if;
    when 'query' then
      v_to := 'query'; v_event := 'query';
      v_allowed := v_from = 'submitted';
      if not public.tk_can_write(v_plan.referat_id) then raise exception 'TK_FORBIDDEN' using errcode = 'P0001'; end if;
    when 'resubmit' then
      v_to := 'submitted'; v_event := 'resubmitted';
      v_allowed := v_from = 'query';
      if not public.tk_can_write(v_plan.referat_id) then raise exception 'TK_FORBIDDEN' using errcode = 'P0001'; end if;
    when 'approve' then
      v_to := 'approved'; v_event := 'approved';
      v_allowed := v_from = 'submitted';
      if not public.tk_can_approve(v_plan.referat_id) then raise exception 'TK_FORBIDDEN' using errcode = 'P0001'; end if;
    when 'publish' then
      v_to := 'published'; v_event := 'published';
      v_allowed := v_from = 'approved';
      if not (public.tk_can_approve(v_plan.referat_id) or public.tk_can_manage()) then
        raise exception 'TK_FORBIDDEN' using errcode = 'P0001';
      end if;
    when 'cancel' then
      v_to := 'cancelled'; v_event := 'cancelled';
      v_allowed := v_from in ('draft', 'submitted', 'query', 'approved', 'published');
      if not public.tk_can_write(v_plan.referat_id) then raise exception 'TK_FORBIDDEN' using errcode = 'P0001'; end if;
    when 'done' then
      v_to := 'done'; v_event := 'done';
      v_allowed := v_from = 'published';
      if not public.tk_can_write(v_plan.referat_id) then raise exception 'TK_FORBIDDEN' using errcode = 'P0001'; end if;
    when 'close' then
      v_to := 'closed'; v_event := 'closed';
      v_allowed := v_from = 'done';
      if not public.tk_can_manage() then raise exception 'TK_FORBIDDEN' using errcode = 'P0001'; end if;
    else
      raise exception 'TK_FIELD_INVALID' using errcode = 'P0001', detail = 'action';
  end case;
  if not v_allowed then
    raise exception 'TK_STATUS_NOT_ALLOWED' using errcode = 'P0001', detail = v_from::text;
  end if;

  -- Kommentar Pflicht bei Rückfrage und Absage (R21)
  if p_action in ('query', 'cancel') and v_comment is null then
    raise exception 'TK_COMMENT_REQUIRED' using errcode = 'P0001', detail = p_action;
  end if;
  if v_comment is not null and char_length(v_comment) > 500 then
    raise exception 'TK_FIELD_INVALID' using errcode = 'P0001', detail = 'comment';
  end if;
  if v_ref is not null and char_length(v_ref) > 200 then
    raise exception 'TK_FIELD_INVALID' using errcode = 'P0001', detail = 'yolawo_ref';
  end if;

  -- Pflichtangaben (R6) mit aktuellem Stand
  if p_action in ('submit', 'resubmit', 'approve', 'publish') then
    perform public.tk_calculate(p_id);
    select r.missing into v_missing from public.tk_plan_results r where r.plan_id = p_id;
    if cardinality(coalesce(v_missing, '{}')) > 0 then
      raise exception 'TK_MISSING_FIELDS' using errcode = 'P0001', detail = array_to_string(v_missing, ',');
    end if;
  end if;
  if p_action = 'done' and (v_plan.end_date is null or v_plan.end_date >= current_date) then
    raise exception 'TK_NOT_FINISHED' using errcode = 'P0001';
  end if;

  -- R3: Satzstand bei der Freigabe einfrieren
  if p_action = 'approve' then
    v_start := coalesce(v_plan.start_date, current_date);
    delete from public.tk_plan_rates r where r.plan_id = p_id;
    insert into public.tk_plan_rates (plan_id, rate_key, label, value, percent, fixed, active, valid_from)
    select p_id, r.rate_key, r.label, r.value, r.percent, r.fixed, r.active, r.valid_from
      from public.ad_rates_at(v_start) r
     where r.rate_group <> 'remuneration' or r.rate_key in ('rTL', 'rTLh', 'rH', 'rHh', 'rOrg', 'rLE');
  end if;

  perform set_config('tk.status_change', 'on', true);
  update public.tk_plans
     set status = v_to,
         row_version = row_version + 1,
         rates_frozen_on = case when p_action = 'approve' then current_date else rates_frozen_on end,
         yolawo_ref = case when p_action = 'publish' then coalesce(v_ref, yolawo_ref) else yolawo_ref end,
         cancelled_at = case when p_action = 'cancel' then now() else cancelled_at end,
         cancel_reason = case when p_action = 'cancel' then v_comment else cancel_reason end
   where id = p_id;
  perform set_config('tk.status_change', '', true);

  insert into public.tk_plan_history (plan_id, event, from_status, to_status, comment)
  values (p_id, v_event, v_from, v_to, v_comment);

  if p_action = 'approve' then
    perform public.tk_calculate(p_id);
  end if;
  return public.tk_save_result(p_id);
end;
$$;

revoke all on function public.tk_change_status(uuid, text, text, text, int) from public, anon, authenticated;
grant execute on function public.tk_change_status(uuid, text, text, text, int) to authenticated;
