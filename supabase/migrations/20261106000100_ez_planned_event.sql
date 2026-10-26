-- Anwesenheitserfassung (EZ), spec T19 (EZ tasks.md T036): Anbindung der Planungshilfe nach spec.md EZ v0.7
-- (R25–R27, R26a, R34): ez_upsert_planned_event, ez_cancel_planned_event, ez_planned_event_state.
-- Umgesetzt mit TK T015 (tk-touren-kurse/plan.md Stufe 3), weil die Rechte über tk_can_write/tk_can_read laufen.

-- Vorbelegung der Abrechnungsart ohne Leserecht des Aufrufers (Einsatz entsteht im Auftrag der Planungshilfe); intern
create function public.ez_remuneration_default(p_kind public.ez_event_kind, p_span public.ez_span, p_date date)
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select d.kind_id from public.ad_remuneration_defaults d
   where d.event_kind = p_kind::text and d.span = p_span::text and d.valid_from <= coalesce(p_date, current_date)
   order by d.valid_from desc limit 1;
$$;

revoke all on function public.ez_remuneration_default(public.ez_event_kind, public.ez_span, date) from public, anon, authenticated;

-- R26, R26a: Einsatz zur Planung anlegen oder aktualisieren
create function public.ez_upsert_planned_event(
  p_tk_plan_id uuid, p_kind public.ez_event_kind, p_referat_id uuid, p_title text, p_span public.ez_span,
  p_start_date date, p_start_time time, p_end_date date, p_end_time time, p_day_category public.ez_day_category,
  p_organizer_person_id uuid, p_persons jsonb, p_remuneration_kind_code text default null)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_old public.ez_events%rowtype;
  v_id uuid;
  v_title text := nullif(btrim(coalesce(p_title, '')), '');
  v_rem uuid;
  v_person uuid;
begin
  -- 1. Rechte der Planungshilfe
  if p_tk_plan_id is null or not public.tk_can_write(p_referat_id) then
    raise exception 'EZ_FORBIDDEN' using errcode = 'P0001';
  end if;
  -- 2. Einsatzart, Form, Längen (wie ez_save_event)
  if p_kind not in ('course', 'tour') then
    raise exception 'EZ_KIND_NOT_ALLOWED' using errcode = 'P0001';
  end if;
  if v_title is null then
    raise exception 'EZ_FIELD_REQUIRED' using errcode = 'P0001', detail = 'Titel';
  end if;
  if char_length(v_title) > 90 then
    raise exception 'EZ_TITLE_LENGTH' using errcode = 'P0001';
  end if;
  if p_organizer_person_id is null then
    raise exception 'EZ_FIELD_REQUIRED' using errcode = 'P0001', detail = 'Organisierende Person';
  end if;
  if p_start_date is null then
    raise exception 'EZ_FIELD_REQUIRED' using errcode = 'P0001',
      detail = case when p_span = 'multi' then 'Startdatum' else 'Datum' end;
  end if;
  if p_span = 'multi' and p_end_date is null then
    raise exception 'EZ_FIELD_REQUIRED' using errcode = 'P0001', detail = 'Enddatum';
  end if;
  if p_span = 'multi' and p_end_date <= p_start_date then
    raise exception 'EZ_END_DATE' using errcode = 'P0001';
  end if;
  if p_span = 'single' and p_day_category is null then
    raise exception 'EZ_FIELD_REQUIRED' using errcode = 'P0001', detail = 'Dauer';
  end if;

  -- 3. vorhandener Einsatz
  select * into v_old from public.ez_events e where e.tk_plan_id = p_tk_plan_id for update;
  if found then
    v_id := v_old.id;
    if v_old.cancelled_at is not null then
      raise exception 'EZ_EVENT_CANCELLED' using errcode = 'P0001';
    end if;
    if exists (select 1 from public.ez_attendances a where a.event_id = v_id and a.status = 'present') then
      raise exception 'EZ_EVENT_LOCKED' using errcode = 'P0001';
    end if;
    if public.fi_event_locked(v_id) then
      raise exception 'EZ_SETTLED' using errcode = 'P0001';
    end if;
    if v_old.kind <> p_kind or v_old.referat_id <> p_referat_id then
      raise exception 'EZ_FIELD_LOCKED' using errcode = 'P0001';
    end if;
  end if;

  -- R26a Abrechnungsart: Code gesetzt → dieser Wert; sonst Vorbelegung bei Anlage, unverändert bei Aktualisierung
  if p_remuneration_kind_code is not null then
    select k.id into v_rem from public.ad_remuneration_kinds k where k.code = p_remuneration_kind_code and k.is_active;
    if v_rem is null then
      raise exception 'EZ_REMUNERATION_INACTIVE' using errcode = 'P0001';
    end if;
  elsif v_id is null then
    v_rem := public.ez_remuneration_default(p_kind, p_span, p_start_date);
  else
    v_rem := v_old.remuneration_kind_id;
  end if;

  -- Organisierende Person aktiv (R11) bei Anlage oder Änderung
  if (v_id is null or p_organizer_person_id is distinct from v_old.organizer_person_id)
     and not exists (select 1 from public.ea_persons pe
                      where pe.id = p_organizer_person_id and pe.kind = 'human' and pe.volunteer_status = 'active') then
    raise exception 'EZ_ORGANIZER_NOT_ACTIVE' using errcode = 'P0001';
  end if;

  -- 4. Personen aus der Planung (R17, R20)
  create temp table if not exists ez_tmp_plan (person_id uuid, role public.ez_role) on commit drop;
  truncate pg_temp.ez_tmp_plan;
  insert into pg_temp.ez_tmp_plan (person_id, role)
  select x.person_id, x.role from jsonb_to_recordset(coalesce(p_persons, '[]')) as x (person_id uuid, role public.ez_role);
  if exists (select 1 from pg_temp.ez_tmp_plan where person_id is null or role is null or role not in ('trainer', 'helper')) then
    raise exception 'EZ_ROLE_NOT_ALLOWED' using errcode = 'P0001';
  end if;
  select t.person_id into v_person from pg_temp.ez_tmp_plan t group by t.person_id having count(*) > 1 limit 1;
  if found then
    raise exception 'EZ_DUPLICATE_PERSON' using errcode = 'P0001', detail = v_person::text;
  end if;
  select t.person_id into v_person from pg_temp.ez_tmp_plan t
   where not exists (select 1 from public.ez_attendances a where a.event_id = v_id and a.person_id = t.person_id)
     and not exists (select 1 from public.ea_persons pe
                      where pe.id = t.person_id and pe.kind = 'human' and pe.volunteer_status = 'active')
   limit 1;
  if found then
    raise exception 'EZ_PERSON_NOT_ACTIVE' using errcode = 'P0001', detail = v_person::text;
  end if;

  -- Schreiben (Audit über Trigger)
  if v_id is null then
    insert into public.ez_events (kind, span, referat_id, title, organizer_person_id, start_date, start_time, end_date,
                                  end_time, day_category, client_request_id, tk_plan_id, remuneration_kind_id)
    values (p_kind, p_span, p_referat_id, v_title, p_organizer_person_id, p_start_date,
            case when p_span = 'multi' then p_start_time end, case when p_span = 'multi' then p_end_date end,
            case when p_span = 'multi' then p_end_time end, case when p_span = 'single' then p_day_category end,
            gen_random_uuid(), p_tk_plan_id, v_rem)
    returning id into v_id;
  else
    update public.ez_events
       set span = p_span, title = v_title, organizer_person_id = p_organizer_person_id, start_date = p_start_date,
           start_time = case when p_span = 'multi' then p_start_time end,
           end_date = case when p_span = 'multi' then p_end_date end,
           end_time = case when p_span = 'multi' then p_end_time end,
           day_category = case when p_span = 'single' then p_day_category end,
           remuneration_kind_id = v_rem
     where id = v_id
       and (span, title, organizer_person_id, start_date, start_time, end_date, end_time, day_category,
            remuneration_kind_id)
           is distinct from
           (p_span, v_title, p_organizer_person_id, p_start_date, case when p_span = 'multi' then p_start_time end,
            case when p_span = 'multi' then p_end_date end, case when p_span = 'multi' then p_end_time end,
            case when p_span = 'single' then p_day_category end, v_rem);
  end if;

  -- Personen mit from_plan: entfernen, die nicht mehr in der Planung stehen; übrige anlegen bzw. Rolle setzen
  delete from public.ez_attendances a
   where a.event_id = v_id and a.from_plan
     and not exists (select 1 from pg_temp.ez_tmp_plan t where t.person_id = a.person_id);
  insert into public.ez_attendances (event_id, person_id, role, status, from_plan)
  select v_id, t.person_id, t.role, 'registered', true from pg_temp.ez_tmp_plan t
  on conflict (event_id, person_id) do update
    set role = excluded.role, from_plan = true
  where (public.ez_attendances.role, public.ez_attendances.from_plan) is distinct from (excluded.role, true);

  return v_id;
end;
$$;

revoke all on function public.ez_upsert_planned_event(uuid, public.ez_event_kind, uuid, text, public.ez_span, date, time, date,
  time, public.ez_day_category, uuid, jsonb, text) from public, anon, authenticated;
grant execute on function public.ez_upsert_planned_event(uuid, public.ez_event_kind, uuid, text, public.ez_span, date, time, date,
  time, public.ez_day_category, uuid, jsonb, text) to authenticated;

-- R27: Absage aus der Planungshilfe
create function public.ez_cancel_planned_event(p_tk_plan_id uuid, p_reason text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_event public.ez_events%rowtype;
  v_reason text := btrim(coalesce(p_reason, ''));
begin
  select * into v_event from public.ez_events e where e.tk_plan_id = p_tk_plan_id for update;
  if not found then
    return;
  end if;
  if not public.tk_can_write(v_event.referat_id) then
    raise exception 'EZ_FORBIDDEN' using errcode = 'P0001';
  end if;
  if v_event.cancelled_at is not null then
    return;
  end if;
  if exists (select 1 from public.ez_attendances a where a.event_id = v_event.id and a.status = 'present') then
    raise exception 'EZ_EVENT_LOCKED' using errcode = 'P0001';
  end if;
  if public.fi_event_locked(v_event.id) then
    raise exception 'EZ_SETTLED' using errcode = 'P0001';
  end if;
  if v_reason = '' or char_length(v_reason) > 500 then
    raise exception 'EZ_CANCEL_REASON' using errcode = 'P0001';
  end if;
  update public.ez_events
     set cancelled_at = now(), cancelled_by = auth.uid(), cancelled_by_person_id = public.ez_my_person_id(),
         cancel_reason = v_reason
   where id = v_event.id;
end;
$$;

revoke all on function public.ez_cancel_planned_event(uuid, text) from public, anon, authenticated;
grant execute on function public.ez_cancel_planned_event(uuid, text) to authenticated;

-- Stand des Einsatzes für die Planungshilfe (ohne Namen)
create function public.ez_planned_event_state(p_tk_plan_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_event public.ez_events%rowtype;
begin
  select * into v_event from public.ez_events e where e.tk_plan_id = p_tk_plan_id;
  if not found then
    if exists (select 1 from public.tk_plans p where p.id = p_tk_plan_id and public.tk_can_read(p.referat_id)) then
      return null;
    end if;
    raise exception 'EZ_NOT_FOUND' using errcode = 'P0001';
  end if;
  if not public.tk_can_read(v_event.referat_id) then
    raise exception 'EZ_NOT_FOUND' using errcode = 'P0001';
  end if;
  return jsonb_build_object(
    'event_id', v_event.id,
    'is_cancelled', v_event.cancelled_at is not null,
    'counts', (select coalesce(jsonb_object_agg(k, n), '{}') from (
                 select a.role::text || '_' || a.status::text as k, count(*) as n
                   from public.ez_attendances a where a.event_id = v_event.id group by 1) c),
    'is_done', exists (select 1 from public.ez_attendances a
                        where a.event_id = v_event.id and a.role in ('trainer', 'helper') and a.status = 'present'));
end;
$$;

revoke all on function public.ez_planned_event_state(uuid) from public, anon, authenticated;
grant execute on function public.ez_planned_event_state(uuid) to authenticated;
