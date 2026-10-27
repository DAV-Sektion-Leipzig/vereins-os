-- Anwesenheitserfassung (EZ) mit Planungshilfe (TK), Befund S-02 aus dem Sicherheits-Review:
-- 1. ez_upsert_planned_event und ez_cancel_planned_event sind nur noch intern (Aufruf ausschließlich über die
--    TK-Funktionen tk_ez_sync, tk_save_plan und tk_change_status, security definer); kein execute mehr für authenticated.
--    ez_planned_event_state bleibt für die Oberfläche der Planungshilfe gewährt.
-- 2. Fremdschlüssel ez_events.tk_plan_id → tk_plans(id), on delete restrict (TK löscht Planungen nur ohne Einsatz,
--    tk_delete_plan in 20261105000400). Verwaiste Werte werden nicht verändert: Der Fremdschlüssel wird nur validiert,
--    wenn es keine gibt; sonst bleibt er „not valid“ (gilt trotzdem für neue und geänderte Zeilen) und die Migration
--    meldet die Anzahl per NOTICE.
-- 3. ez_upsert_planned_event prüft zusätzlich: Planung vorhanden, gleiches Referat, Status „freigegeben“ (Übergang zu
--    „in Yolawo angelegt“, tk_change_status publish) oder „in Yolawo angelegt“ (Aktualisierung aus tk_save_plan).
--    Sonst EZ_FORBIDDEN. Übriger Inhalt unverändert aus 20261106000100.

-- 1. Nur intern
revoke execute on function public.ez_upsert_planned_event(uuid, public.ez_event_kind, uuid, text, public.ez_span, date, time,
  date, time, public.ez_day_category, uuid, jsonb, text) from public, anon, authenticated;
revoke execute on function public.ez_cancel_planned_event(uuid, text) from public, anon, authenticated;

-- 2. Fremdschlüssel zur Planung
alter table public.ez_events
  add constraint ez_events_tk_plan_id_fkey foreign key (tk_plan_id) references public.tk_plans (id) on delete restrict
  not valid;

do $$
declare
  v_orphans int;
begin
  select count(*) into v_orphans
    from public.ez_events e
   where e.tk_plan_id is not null
     and not exists (select 1 from public.tk_plans p where p.id = e.tk_plan_id);
  if v_orphans = 0 then
    alter table public.ez_events validate constraint ez_events_tk_plan_id_fkey;
  else
    raise notice 'ez_events_tk_plan_id_fkey bleibt NOT VALID: % Einsätze verweisen auf keine vorhandene Planung', v_orphans;
  end if;
end $$;

-- 3. Planung vorhanden, gleiches Referat, Status freigegeben oder in Yolawo angelegt
create or replace function public.ez_upsert_planned_event(
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
  -- Planung vorhanden, im selben Referat und freigegeben bzw. in Yolawo angelegt (S-02)
  if not exists (select 1 from public.tk_plans p
                  where p.id = p_tk_plan_id and p.referat_id = p_referat_id
                    and p.status in ('approved', 'published')) then
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

-- create or replace behält die Rechte; zur Sicherheit erneut entziehen
revoke all on function public.ez_upsert_planned_event(uuid, public.ez_event_kind, uuid, text, public.ez_span, date, time,
  date, time, public.ez_day_category, uuid, jsonb, text) from public, anon, authenticated;
