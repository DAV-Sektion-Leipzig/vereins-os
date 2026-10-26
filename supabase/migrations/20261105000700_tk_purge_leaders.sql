-- Planungshilfe Touren und Kurse (TK), spec T10 und T23; spec.md TK v0.4 R16 (Löschung der Kontaktdaten nach
-- 30 Tagen), R23 (externe Leitende anlegen bzw. wieder aktiv eintragen); tasks.md T010, T012.

-- R16: täglich; Kontakt- und Notfalldaten 30 Tage nach Tourende bzw. Absage löschen. Nur für den Scheduler.
create function public.tk_purge_contacts()
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_count int := 0;
  v_id uuid;
begin
  for v_id in
    select p.id from public.tk_plans p
     where p.contacts_purged_at is null
       and ((p.status in ('published', 'done', 'closed') and p.end_date + 30 < current_date)
            or (p.status = 'cancelled' and p.cancelled_at::date + 30 < current_date))
  loop
    delete from public.tk_plan_contacts c where c.plan_id = v_id;
    update public.tk_plans set contacts_purged_at = now() where id = v_id;
    insert into public.tk_plan_history (plan_id, event) values (v_id, 'contacts_purged');
    v_count := v_count + 1;
  end loop;
  return v_count;
end;
$$;

revoke all on function public.tk_purge_contacts() from public, anon, authenticated;

select cron.schedule('tk_purge_contacts', '15 3 * * *', $$select public.tk_purge_contacts()$$);

-- R23: neue Person aus der Planung (Funktion Helfer:in im Referat der Planung, Hinweis nach Art. 13 DSGVO)
create function public.tk_create_leader(
  p_plan_id uuid, p_first text, p_last text, p_preferred text default null, p_email text default null,
  p_privacy_confirmed boolean default false, p_notice_version text default null)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_plan public.tk_plans%rowtype;
  v_notice text := nullif(btrim(coalesce(p_notice_version, '')), '');
  v_person uuid;
begin
  select * into v_plan from public.tk_plans p where p.id = p_plan_id;
  if not found or not public.tk_can_read(v_plan.referat_id) then
    raise exception 'TK_NOT_FOUND' using errcode = 'P0001';
  end if;
  if not public.tk_can_write(v_plan.referat_id) or not public.tk_can_edit_plan(v_plan.status, v_plan.referat_id) then
    raise exception 'TK_FORBIDDEN' using errcode = 'P0001';
  end if;
  if not coalesce(p_privacy_confirmed, false) or v_notice is null or char_length(v_notice) > 50 then
    raise exception 'TK_PRIVACY_NOT_CONFIRMED' using errcode = 'P0001';
  end if;
  v_person := public.ea_create_volunteer(
    btrim(coalesce(p_first, '')), btrim(coalesce(p_last, '')), nullif(btrim(coalesce(p_preferred, '')), ''),
    (select t.id from public.ea_property_types t where t.system_key = 'function'), v_plan.referat_id,
    '{"function": "Helfer:in"}'::jsonb, current_date, p_email);
  insert into public.tk_privacy_confirmations (person_id, plan_id, notice_version, confirmed_by_person_id)
  values (v_person, p_plan_id, v_notice, public.tk_my_person_id());
  return v_person;
end;
$$;

revoke all on function public.tk_create_leader(uuid, text, text, text, text, boolean, text) from public, anon, authenticated;
grant execute on function public.tk_create_leader(uuid, text, text, text, text, boolean, text) to authenticated;

-- R23: Person mit Ehrenamtsstatus „ruhend“, „ausgeschieden“ oder ohne wieder aktiv eintragen
create function public.tk_reactivate_leader(p_plan_id uuid, p_person uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_plan public.tk_plans%rowtype;
  v_status public.ea_volunteer_status;
begin
  select * into v_plan from public.tk_plans p where p.id = p_plan_id;
  if not found or not public.tk_can_read(v_plan.referat_id) then
    raise exception 'TK_NOT_FOUND' using errcode = 'P0001';
  end if;
  if not public.tk_can_write(v_plan.referat_id) or not public.tk_can_edit_plan(v_plan.status, v_plan.referat_id) then
    raise exception 'TK_FORBIDDEN' using errcode = 'P0001';
  end if;
  select e.volunteer_status into v_status from public.ea_persons e where e.id = p_person and e.kind = 'human';
  if not found then
    raise exception 'TK_NOT_FOUND' using errcode = 'P0001';
  end if;
  if v_status = 'active' then
    raise exception 'TK_PERSON_NOT_INACTIVE' using errcode = 'P0001';
  end if;
  perform public.ea_activate_person(
    p_person, (select t.id from public.ea_property_types t where t.system_key = 'function'), v_plan.referat_id,
    '{"function": "Helfer:in"}'::jsonb, current_date);
end;
$$;

revoke all on function public.tk_reactivate_leader(uuid, uuid) from public, anon, authenticated;
grant execute on function public.tk_reactivate_leader(uuid, uuid) to authenticated;
