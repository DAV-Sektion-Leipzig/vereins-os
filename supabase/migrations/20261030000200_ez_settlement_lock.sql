-- Anwesenheitserfassung Nachtrag v0.6 (spec.md EZ v0.6), spec T23; R32, R34; Übergabe FI → EZ Z1, Z3.
-- ez_save_event mit Abrechnungsart (Schritt 3a, EZ_REMUNERATION_INACTIVE) und Sperre abgerechneter Einsätze
-- (Schritte 3, 10a, EZ_SETTLED); ez_delete_event und ez_cancel_event mit Sperre. Übrige Schritte unverändert
-- (20261028000400, 20261028000500). Die Anbindung der Planungshilfe (T19) prüft die Sperre bei ihrer Umsetzung.

create or replace function public.ez_save_event(
  p_event jsonb, p_attendances jsonb, p_trials jsonb, p_confirm_duplicate boolean default false)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid := nullif(p_event ->> 'id', '')::uuid;
  v_is_new boolean := v_id is null;
  v_old public.ez_events%rowtype;
  v_kind public.ez_event_kind;
  v_has_group boolean;
  v_span public.ez_span;
  v_group uuid;
  v_add uuid[] := '{}';
  v_old_add uuid[] := '{}';
  v_groups uuid[];
  v_referat uuid;
  v_title text := nullif(btrim(coalesce(p_event ->> 'title', '')), '');
  v_organizer uuid := nullif(p_event ->> 'organizer_person_id', '')::uuid;
  v_start date := nullif(p_event ->> 'start_date', '')::date;
  v_start_time time := nullif(p_event ->> 'start_time', '')::time;
  v_end date := nullif(p_event ->> 'end_date', '')::date;
  v_end_time time := nullif(p_event ->> 'end_time', '')::time;
  v_day public.ez_day_category := nullif(p_event ->> 'day_category', '')::public.ez_day_category;
  v_location uuid := nullif(p_event ->> 'location_id', '')::uuid;
  v_remark text := nullif(btrim(coalesce(p_event ->> 'remark', '')), '');
  v_crid uuid := coalesce(nullif(p_event ->> 'client_request_id', '')::uuid, gen_random_uuid());
  v_location_active boolean;
  v_existing public.ez_events%rowtype;
  v_person uuid;
  v_trial text;
  v_trials text[] := '{}';
  v_rem uuid := nullif(p_event ->> 'remuneration_kind_id', '')::uuid;
  v_rem_given boolean := p_event ? 'remuneration_kind_id';
begin
  -- Einsatzart und gespeicherter Stand
  if not v_is_new then
    select * into v_old from public.ez_events e where e.id = v_id for update;
    if not found or not public.ez_can_read(v_old.referat_id) then
      raise exception 'EZ_NOT_FOUND' using errcode = 'P0001';
    end if;
    v_kind := coalesce(nullif(p_event ->> 'kind', '')::public.ez_event_kind, v_old.kind);
  else
    v_kind := nullif(p_event ->> 'kind', '')::public.ez_event_kind;
    if v_kind is null then
      raise exception 'EZ_KIND_NOT_ALLOWED' using errcode = 'P0001';
    end if;
  end if;
  v_has_group := v_kind not in ('work_assignment', 'course', 'tour');

  -- Gruppe bzw. Referat (Schritt 1)
  if v_has_group then
    v_group := nullif(p_event ->> 'group_id', '')::uuid;
    if not v_is_new then
      v_group := coalesce(v_group, v_old.group_id);
    end if;
    if v_group is null then
      raise exception 'EZ_FIELD_REQUIRED' using errcode = 'P0001', detail = 'Gruppe';
    end if;
    select g.referat_id into v_referat from public.gr_groups g where g.id = v_group;
    if not found then
      raise exception 'EZ_FIELD_REQUIRED' using errcode = 'P0001', detail = 'Gruppe';
    end if;
  else
    v_referat := nullif(p_event ->> 'referat_id', '')::uuid;
    if not v_is_new then
      v_referat := coalesce(v_referat, v_old.referat_id);
    end if;
    if v_referat is null then
      raise exception 'EZ_FIELD_REQUIRED' using errcode = 'P0001', detail = 'Referat';
    end if;
  end if;

  -- Rechte (Schritt 1, R13, R14)
  if v_is_new then
    if not public.ez_can_write(v_referat) then
      raise exception 'EZ_FORBIDDEN' using errcode = 'P0001';
    end if;
  else
    if not public.ez_can_write(v_old.referat_id) then
      raise exception 'EZ_FORBIDDEN' using errcode = 'P0001';
    end if;
    -- Einsätze mit Gruppe behalten das gespeicherte Referat (R19)
    if v_has_group then
      v_referat := v_old.referat_id;
    elsif v_referat is distinct from v_old.referat_id and v_old.tk_plan_id is null
          and not public.ez_can_write(v_referat) then
      raise exception 'EZ_FORBIDDEN' using errcode = 'P0001';
    end if;
  end if;

  -- Idempotenz (Schritt 2, US-EZ-18)
  if v_is_new then
    select e.id into v_id from public.ez_events e where e.client_request_id = v_crid;
    if found then
      return v_id;
    end if;
  end if;

  -- Weitere Gruppen (Schritt 1a, R30)
  if p_event ? 'additional_group_ids' and jsonb_typeof(p_event -> 'additional_group_ids') = 'array' then
    select coalesce(array_agg(distinct x::uuid), '{}') into v_add
      from jsonb_array_elements_text(p_event -> 'additional_group_ids') as x
     where nullif(x, '') is not null and x::uuid is distinct from v_group;
  end if;
  if not v_is_new then
    select coalesce(array_agg(eg.group_id), '{}') into v_old_add from public.ez_event_groups eg where eg.event_id = v_id;
    if not (p_event ? 'additional_group_ids') then
      v_add := v_old_add;
    end if;
  end if;
  if cardinality(v_add) > 0 and v_kind <> 'competition' then
    raise exception 'EZ_KIND_NOT_ALLOWED' using errcode = 'P0001';
  end if;

  -- Unveränderliche Felder (Schritt 3, R19)
  if not v_is_new then
    if v_kind is distinct from v_old.kind or v_group is distinct from v_old.group_id
       or not (v_add <@ v_old_add and v_old_add <@ v_add) then
      raise exception 'EZ_FIELD_LOCKED' using errcode = 'P0001';
    end if;
    if v_old.cancelled_at is not null then
      raise exception 'EZ_EVENT_CANCELLED' using errcode = 'P0001';
    end if;
  elsif cardinality(v_add) > 0 then
    if exists (select 1 from unnest(v_add) as a (id)
                where not exists (select 1 from public.gr_groups g where g.id = a.id)) then
      raise exception 'EZ_FIELD_REQUIRED' using errcode = 'P0001', detail = 'Gruppe';
    end if;
    if exists (select 1 from public.gr_groups g where g.id = any (v_add) and g.referat_id <> v_referat) then
      raise exception 'EZ_GROUP_REFERAT_MISMATCH' using errcode = 'P0001';
    end if;
  end if;
  v_groups := case when v_has_group then array[v_group] || v_add else '{}' end;

  -- Form je Einsatzart: Felder, die nicht zur Einsatzart gehören, werden null (research.md R-EZ-05)
  v_span := case
    when v_kind in ('training', 'day_trip') then 'single'
    when v_kind in ('multi_day_trip', 'training_camp') then 'multi'
    else coalesce(nullif(p_event ->> 'span', '')::public.ez_span, 'single')
  end;
  if v_kind = 'training' then
    v_title := null;
    v_start_time := null;
    v_end_time := null;
    v_end := null;
    v_day := null;
  else
    v_location := null;
    if v_span = 'single' then
      v_start_time := null;
      v_end_time := null;
      v_end := null;
    else
      v_day := null;
    end if;
  end if;
  if v_kind not in ('day_trip', 'multi_day_trip', 'training_trip', 'training_camp', 'course', 'tour') then
    v_organizer := null;
  end if;

  -- Abrechnungsart (Schritt 3a, v0.6, R32): beim Anlegen ohne Angabe Vorbelegung aus der Einsatzart,
  -- beim Ändern ohne Angabe unverändert; null = keine Vergütung
  if not v_rem_given then
    v_rem := case when v_is_new then public.ad_remuneration_default_at(v_kind::text, v_span::text, v_start)
                  else v_old.remuneration_kind_id end;
  end if;

  -- Pflichtfelder und Längen (Schritt 4, R1, R2, R7, Längen)
  if v_kind <> 'training' and v_title is null then
    raise exception 'EZ_FIELD_REQUIRED' using errcode = 'P0001', detail = 'Titel';
  end if;
  if v_kind in ('day_trip', 'multi_day_trip', 'training_trip', 'training_camp', 'course', 'tour') and v_organizer is null then
    raise exception 'EZ_FIELD_REQUIRED' using errcode = 'P0001', detail = 'Organisierende Person';
  end if;
  if v_start is null then
    raise exception 'EZ_FIELD_REQUIRED' using errcode = 'P0001',
      detail = case when v_span = 'multi' then 'Startdatum' else 'Datum' end;
  end if;
  if v_span = 'multi' and v_end is null then
    raise exception 'EZ_FIELD_REQUIRED' using errcode = 'P0001', detail = 'Enddatum';
  end if;
  if v_kind <> 'training' and v_span = 'single' and v_day is null then
    raise exception 'EZ_FIELD_REQUIRED' using errcode = 'P0001', detail = 'Dauer';
  end if;
  if v_kind = 'training' and v_location is null then
    raise exception 'EZ_FIELD_REQUIRED' using errcode = 'P0001', detail = 'Ort';
  end if;
  if char_length(v_title) > 90 then
    raise exception 'EZ_TITLE_LENGTH' using errcode = 'P0001';
  end if;
  if v_span = 'multi' and v_end <= v_start then
    raise exception 'EZ_END_DATE' using errcode = 'P0001';
  end if;
  if char_length(v_remark) > 500 then
    raise exception 'EZ_REMARK_LENGTH' using errcode = 'P0001';
  end if;

  -- Einsätze aus der Planungshilfe: nur Bemerkung im Kopf änderbar (R25)
  if not v_is_new and v_old.tk_plan_id is not null
     and (v_span, v_referat, v_title, v_organizer, v_start, v_start_time, v_end, v_end_time, v_day)
         is distinct from
         (v_old.span, v_old.referat_id, v_old.title, v_old.organizer_person_id, v_old.start_date, v_old.start_time,
          v_old.end_date, v_old.end_time, v_old.day_category) then
    raise exception 'EZ_TK_MANAGED' using errcode = 'P0001';
  end if;

  -- Abrechnungsart aktiv (v0.6, R32), nur bei Anlage oder Änderung
  if v_rem is not null and (v_is_new or v_rem is distinct from v_old.remuneration_kind_id)
     and not exists (select 1 from public.ad_remuneration_kinds k where k.id = v_rem and k.is_active) then
    raise exception 'EZ_REMUNERATION_INACTIVE' using errcode = 'P0001';
  end if;

  -- Abgerechneter Einsatz (v0.6, R34): abrechnungsrelevante Kopfdaten gesperrt
  if not v_is_new and public.fi_event_locked(v_id)
     and (v_span, v_start, v_start_time, v_end, v_end_time, v_day, v_rem, v_organizer)
         is distinct from
         (v_old.span, v_old.start_date, v_old.start_time, v_old.end_date, v_old.end_time, v_old.day_category,
          v_old.remuneration_kind_id, v_old.organizer_person_id) then
    raise exception 'EZ_SETTLED' using errcode = 'P0001';
  end if;

  -- Gruppen am Stichtag wählbar (O1: sonst Feld „Gruppe“)
  if v_has_group and exists (
       select 1 from unnest(v_groups) as g (id)
        where not exists (select 1 from public.gr_groups_for_attendance(v_start) f where f.group_id = g.id)) then
    raise exception 'EZ_FIELD_REQUIRED' using errcode = 'P0001', detail = 'Gruppe';
  end if;

  -- Ort aktiv (Schritt 5, R12) nur bei Anlage oder Änderung des Orts
  if v_location is not null and (v_is_new or v_location is distinct from v_old.location_id) then
    select l.is_active into v_location_active from public.ad_locations l where l.id = v_location;
    if not found then
      raise exception 'EZ_FIELD_REQUIRED' using errcode = 'P0001', detail = 'Ort';
    end if;
    if not v_location_active then
      raise exception 'EZ_LOCATION_INACTIVE' using errcode = 'P0001';
    end if;
  end if;

  -- Organisierende Person aktiv (Schritt 6, R11) nur bei Anlage oder Änderung
  if v_organizer is not null and (v_is_new or v_organizer is distinct from v_old.organizer_person_id)
     and not exists (select 1 from public.ea_persons pe
                      where pe.id = v_organizer and pe.kind = 'human' and pe.volunteer_status = 'active') then
    raise exception 'EZ_ORGANIZER_NOT_ACTIVE' using errcode = 'P0001';
  end if;

  -- Anwesenheiten (Schritt 7, R16, R17, R20, R21, R25)
  create temp table if not exists ez_tmp_att (
    person_id uuid, role public.ez_role, status public.ez_attendance_status, is_substitute boolean
  ) on commit drop;
  truncate pg_temp.ez_tmp_att;
  insert into pg_temp.ez_tmp_att (person_id, role, status)
  select x.person_id, x.role, coalesce(x.status, 'present')
    from jsonb_to_recordset(coalesce(p_attendances, '[]'))
         as x (person_id uuid, role public.ez_role, status public.ez_attendance_status);

  if exists (select 1 from pg_temp.ez_tmp_att where person_id is null or role is null) then
    raise exception 'EZ_PERSON_NOT_ACTIVE' using errcode = 'P0001';
  end if;
  select t.person_id into v_person from pg_temp.ez_tmp_att t group by t.person_id having count(*) > 1 limit 1;
  if found then
    raise exception 'EZ_DUPLICATE_PERSON' using errcode = 'P0001', detail = v_person::text;
  end if;
  if not v_has_group and exists (select 1 from pg_temp.ez_tmp_att where role = 'participant') then
    raise exception 'EZ_ROLE_NOT_ALLOWED' using errcode = 'P0001';
  end if;
  if v_has_group and exists (select 1 from pg_temp.ez_tmp_att where status = 'registered') then
    raise exception 'EZ_STATUS_NOT_ALLOWED' using errcode = 'P0001';
  end if;
  select t.person_id into v_person from pg_temp.ez_tmp_att t
   where not exists (select 1 from public.ea_persons pe where pe.id = t.person_id and pe.kind = 'human') limit 1;
  if found then
    raise exception 'EZ_PERSON_NOT_ACTIVE' using errcode = 'P0001', detail = v_person::text;
  end if;

  -- Einsätze aus der Planungshilfe: Personen aus der Planung bleiben mit ihrer Rolle (R25)
  if not v_is_new and v_old.tk_plan_id is not null and exists (
       select 1 from public.ez_attendances a
        where a.event_id = v_id and a.from_plan
          and not exists (select 1 from pg_temp.ez_tmp_att t where t.person_id = a.person_id and t.role = a.role)) then
    raise exception 'EZ_TK_MANAGED' using errcode = 'P0001';
  end if;

  -- Abgerechnete Anwesenheiten (Schritt 10a, v0.6, R34): nicht entfernen, Rolle und Stand nicht ändern
  if not v_is_new then
    select a.person_id into v_person from public.ez_attendances a
     where a.event_id = v_id and public.fi_attendance_locked(a.id)
       and not exists (select 1 from pg_temp.ez_tmp_att t
                        where t.person_id = a.person_id and t.role = a.role and t.status = a.status)
     limit 1;
    if found then
      raise exception 'EZ_SETTLED' using errcode = 'P0001', detail = v_person::text;
    end if;
  end if;

  if v_has_group then
    create temp table if not exists ez_tmp_roster (person_id uuid, role text) on commit drop;
    truncate pg_temp.ez_tmp_roster;
    insert into pg_temp.ez_tmp_roster select r.person_id, r.role from public.ez_roster(v_groups, v_start) r;

    select t.person_id into v_person from pg_temp.ez_tmp_att t
     where t.role = 'participant'
       and not exists (select 1 from pg_temp.ez_tmp_roster r where r.person_id = t.person_id and r.role = 'participant')
     limit 1;
    if found then
      raise exception 'EZ_PARTICIPANT_NOT_IN_GROUP' using errcode = 'P0001', detail = v_person::text;
    end if;

    update pg_temp.ez_tmp_att t
       set is_substitute = t.role <> 'participant'
           and not exists (select 1 from pg_temp.ez_tmp_roster r
                            where r.person_id = t.person_id and r.role in ('group_lead', 'trainer', 'helper'));
  else
    update pg_temp.ez_tmp_att set is_substitute = false;
  end if;

  -- R20: ohne Funktion in der Gruppe nur aktive Personen; gespeicherte Personen bleiben erlaubt
  select t.person_id into v_person from pg_temp.ez_tmp_att t
   where t.role <> 'participant'
     and (not v_has_group or t.is_substitute)
     and not exists (select 1 from public.ea_persons pe where pe.id = t.person_id and pe.volunteer_status = 'active')
     and not exists (select 1 from public.ez_attendances a where a.event_id = v_id and a.person_id = t.person_id)
   limit 1;
  if found then
    raise exception 'EZ_PERSON_NOT_ACTIVE' using errcode = 'P0001', detail = v_person::text;
  end if;

  -- Mindestbesetzung (Schritt 8, R5)
  if v_has_group and not (
       exists (select 1 from pg_temp.ez_tmp_att where status = 'present' and role in ('trainer', 'helper'))
       and exists (select 1 from pg_temp.ez_tmp_att where status = 'present' and role = 'participant')) then
    raise exception 'EZ_MIN_ATTENDANCE' using errcode = 'P0001';
  end if;

  -- Probetrainings (Schritt 9, R6), nur beim Training
  if v_kind = 'training' and jsonb_typeof(p_trials) = 'array' then
    for v_trial in select btrim(coalesce(x, '')) from jsonb_array_elements_text(p_trials) as x loop
      if v_trial = '' then
        raise exception 'EZ_TRIAL_NAME' using errcode = 'P0001', detail = 'required';
      end if;
      if char_length(v_trial) > 30 then
        raise exception 'EZ_TRIAL_NAME' using errcode = 'P0001', detail = 'too_long';
      end if;
      v_trials := v_trials || v_trial;
    end loop;
  end if;

  -- Doppelte Erfassung (Schritt 10, R8)
  if v_has_group and not coalesce(p_confirm_duplicate, false) then
    select e.* into v_existing from public.ez_events e
     where e.group_id = v_group and e.start_date = v_start and e.kind = v_kind
       and e.cancelled_at is null and e.id is distinct from v_id
     order by e.created_at
     limit 1;
    if found then
      raise exception 'EZ_DUPLICATE_EVENT' using errcode = 'P0001',
        detail = case when public.ez_can_read(v_existing.referat_id) then v_existing.id::text else '' end;
    end if;
  end if;

  -- Schreiben (Schritt 11: Audit über Trigger)
  if v_is_new then
    begin
      insert into public.ez_events (kind, span, referat_id, group_id, title, organizer_person_id, start_date, start_time,
                                    end_date, end_time, day_category, location_id, remark, client_request_id,
                                    remuneration_kind_id)
      values (v_kind, v_span, v_referat, v_group, v_title, v_organizer, v_start, v_start_time,
              v_end, v_end_time, v_day, v_location, v_remark, v_crid, v_rem)
      returning id into v_id;
    exception when unique_violation then
      select e.id into v_id from public.ez_events e where e.client_request_id = v_crid;
      if v_id is null then
        raise;
      end if;
      return v_id;
    end;
    insert into public.ez_event_groups (event_id, group_id) select v_id, g from unnest(v_add) as g;
  else
    update public.ez_events
       set span = v_span, referat_id = v_referat, title = v_title, organizer_person_id = v_organizer,
           start_date = v_start, start_time = v_start_time, end_date = v_end, end_time = v_end_time,
           day_category = v_day, location_id = v_location, remark = v_remark, remuneration_kind_id = v_rem
     where id = v_id;
  end if;

  delete from public.ez_attendances a
   where a.event_id = v_id and not exists (select 1 from pg_temp.ez_tmp_att t where t.person_id = a.person_id);
  insert into public.ez_attendances (event_id, person_id, role, status, is_substitute)
  select v_id, t.person_id, t.role, t.status, t.is_substitute from pg_temp.ez_tmp_att t
  on conflict (event_id, person_id) do update
    set role = excluded.role, status = excluded.status, is_substitute = excluded.is_substitute
  where (public.ez_attendances.role, public.ez_attendances.status, public.ez_attendances.is_substitute)
        is distinct from (excluded.role, excluded.status, excluded.is_substitute);

  delete from public.ez_trial_participants tp where tp.event_id = v_id;
  insert into public.ez_trial_participants (event_id, first_name) select v_id, n from unnest(v_trials) as n;

  return v_id;
end;
$$;


create or replace function public.ez_delete_event(p_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_event public.ez_events%rowtype := public.ez_load_event(p_id);
begin
  if not public.ez_can_delete() then
    raise exception 'EZ_DELETE_FORBIDDEN' using errcode = 'P0001';
  end if;
  if v_event.tk_plan_id is not null then
    raise exception 'EZ_TK_MANAGED' using errcode = 'P0001';
  end if;
  if public.fi_event_locked(p_id) then
    raise exception 'EZ_SETTLED' using errcode = 'P0001';
  end if;
  delete from public.ez_events where id = p_id;
end;
$$;

create or replace function public.ez_cancel_event(p_id uuid, p_reason text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_event public.ez_events%rowtype := public.ez_load_event(p_id);
  v_reason text := btrim(coalesce(p_reason, ''));
begin
  if not public.ez_can_write(v_event.referat_id) then
    raise exception 'EZ_FORBIDDEN' using errcode = 'P0001';
  end if;
  if v_event.tk_plan_id is not null then
    raise exception 'EZ_TK_MANAGED' using errcode = 'P0001';
  end if;
  if v_event.cancelled_at is not null then
    raise exception 'EZ_EVENT_CANCELLED' using errcode = 'P0001';
  end if;
  if public.fi_event_locked(p_id) then
    raise exception 'EZ_SETTLED' using errcode = 'P0001';
  end if;
  if v_reason = '' or char_length(v_reason) > 500 then
    raise exception 'EZ_CANCEL_REASON' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.ez_attendances a where a.event_id = p_id and a.status = 'present') then
    raise exception 'EZ_CANCEL_NOT_ALLOWED' using errcode = 'P0001';
  end if;
  update public.ez_events
     set cancelled_at = now(), cancelled_by = auth.uid(), cancelled_by_person_id = public.ez_my_person_id(),
         cancel_reason = v_reason
   where id = p_id;
end;
$$;
