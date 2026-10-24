-- Anwesenheitserfassung (EZ), spec T5; spec.md EZ v0.5 Abschnitt 2 (ez_privacy_confirmations, ez_delete_event,
-- ez_cancel_event, ez_restore_event, ez_create_helper, ez_reactivate_helper), R15, R22–R25, R29, R31;
-- research.md R-EZ-14.

-- Bestätigung „Person informiert“ (R29). Nur ez_create_helper schreibt; lesen nur mit „EZ verwalten“.
create table public.ez_privacy_confirmations (
  id uuid primary key default gen_random_uuid(),
  person_id uuid not null references public.ea_persons (id) on delete cascade,
  event_id uuid references public.ez_events (id) on delete set null,
  notice_version text not null,
  confirmed_at timestamptz not null default now(),
  confirmed_by uuid not null default auth.uid(),
  confirmed_by_person_id uuid references public.ea_persons (id) on delete set null,
  constraint ez_privacy_confirmations_notice_version check (
    notice_version = btrim(notice_version) and char_length(notice_version) between 1 and 50)
);

create index ez_privacy_confirmations_person on public.ez_privacy_confirmations (person_id);

alter table public.ez_privacy_confirmations enable row level security;
revoke all on table public.ez_privacy_confirmations from public, anon, authenticated;
grant select on table public.ez_privacy_confirmations to authenticated;

create policy ez_privacy_confirmations_select on public.ez_privacy_confirmations
  for select to authenticated using (public.ez_can_delete());

-- Einsatz laden; nicht vorhanden oder nicht lesbar → EZ_NOT_FOUND (keine Unterscheidung); intern
create function public.ez_load_event(p_id uuid)
returns public.ez_events
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_event public.ez_events%rowtype;
begin
  select * into v_event from public.ez_events e where e.id = p_id for update;
  if not found or not public.ez_can_read(v_event.referat_id) then
    raise exception 'EZ_NOT_FOUND' using errcode = 'P0001';
  end if;
  return v_event;
end;
$$;

revoke all on function public.ez_load_event(uuid) from public, anon, authenticated;

-- Löschen (R15): nur Geschäftsstelle; Anwesenheiten und Probetrainings per cascade, Personen bleiben
create function public.ez_delete_event(p_id uuid)
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
  delete from public.ez_events where id = p_id;
end;
$$;

-- Absagen (R22, R23)
create function public.ez_cancel_event(p_id uuid, p_reason text)
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

-- Absage zurücknehmen (R24); ohne erneute Prüfung auf doppelte Erfassung
create function public.ez_restore_event(p_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_event public.ez_events%rowtype := public.ez_load_event(p_id);
begin
  if not public.ez_can_write(v_event.referat_id) then
    raise exception 'EZ_FORBIDDEN' using errcode = 'P0001';
  end if;
  if v_event.tk_plan_id is not null then
    raise exception 'EZ_TK_MANAGED' using errcode = 'P0001';
  end if;
  if v_event.cancelled_at is null then
    return;
  end if;
  update public.ez_events
     set cancelled_at = null, cancelled_by = null, cancelled_by_person_id = null, cancel_reason = null
   where id = p_id;
end;
$$;

-- Gemeinsame Prüfungen für neue bzw. wieder aktive Helfer:innen beim Arbeitseinsatz; intern
create function public.ez_check_helper_event(p_event uuid)
returns public.ez_events
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_event public.ez_events%rowtype := public.ez_load_event(p_event);
begin
  if v_event.kind <> 'work_assignment' then
    raise exception 'EZ_KIND_NOT_ALLOWED' using errcode = 'P0001';
  end if;
  if not public.ez_can_write(v_event.referat_id) then
    raise exception 'EZ_FORBIDDEN' using errcode = 'P0001';
  end if;
  if v_event.cancelled_at is not null then
    raise exception 'EZ_EVENT_CANCELLED' using errcode = 'P0001';
  end if;
  return v_event;
end;
$$;

revoke all on function public.ez_check_helper_event(uuid) from public, anon, authenticated;

-- Neue Person beim Arbeitseinsatz (US-EZ-11, R29): Person über ea_create_volunteer, Anwesenheit, Bestätigung
create function public.ez_create_helper(
  p_event uuid, p_first text, p_last text, p_preferred text default null, p_email text default null,
  p_privacy_confirmed boolean default false, p_notice_version text default null)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_event public.ez_events%rowtype := public.ez_check_helper_event(p_event);
  v_notice text := btrim(coalesce(p_notice_version, ''));
  v_person uuid;
begin
  if not coalesce(p_privacy_confirmed, false) or v_notice = '' or char_length(v_notice) > 50 then
    raise exception 'EZ_PRIVACY_NOT_CONFIRMED' using errcode = 'P0001';
  end if;

  -- Fehler aus ea_create_volunteer werden durchgereicht (R45 der Administration)
  v_person := public.ea_create_volunteer(
    p_first => p_first,
    p_last => p_last,
    p_preferred => nullif(btrim(coalesce(p_preferred, '')), ''),
    p_property_type => (select t.id from public.ea_property_types t where t.system_key = 'function'),
    p_referat => v_event.referat_id,
    p_field_values => '{"function": "Helfer:in"}'::jsonb,
    p_valid_from => v_event.start_date,
    p_contact_email => p_email);

  insert into public.ez_attendances (event_id, person_id, role, status, is_substitute)
  values (v_event.id, v_person, 'helper', 'present', false);

  insert into public.ez_privacy_confirmations (person_id, event_id, notice_version, confirmed_by_person_id)
  values (v_person, v_event.id, v_notice, public.ez_my_person_id());

  return v_person;
end;
$$;

-- Ruhende, ausgeschiedene Person oder Person ohne Ehrenamtsstatus wieder aktiv eintragen (R31, R45a AD)
create function public.ez_reactivate_helper(p_event uuid, p_person uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_event public.ez_events%rowtype := public.ez_check_helper_event(p_event);
begin
  if exists (select 1 from public.ea_persons pe where pe.id = p_person and pe.volunteer_status = 'active') then
    raise exception 'EZ_PERSON_NOT_INACTIVE' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.ez_attendances a where a.event_id = v_event.id and a.person_id = p_person) then
    raise exception 'EZ_DUPLICATE_PERSON' using errcode = 'P0001', detail = p_person::text;
  end if;

  -- Fehler aus ea_activate_person werden durchgereicht (z. B. AD_BAD_REQUEST für unbekannte Personen)
  perform public.ea_activate_person(
    p_person => p_person,
    p_property_type => (select t.id from public.ea_property_types t where t.system_key = 'function'),
    p_referat => v_event.referat_id,
    p_field_values => '{"function": "Helfer:in"}'::jsonb,
    p_valid_from => v_event.start_date);

  insert into public.ez_attendances (event_id, person_id, role, status, is_substitute)
  values (v_event.id, p_person, 'helper', 'present', false);
end;
$$;

revoke all on function public.ez_delete_event(uuid) from public, anon, authenticated;
revoke all on function public.ez_cancel_event(uuid, text) from public, anon, authenticated;
revoke all on function public.ez_restore_event(uuid) from public, anon, authenticated;
revoke all on function public.ez_create_helper(uuid, text, text, text, text, boolean, text) from public, anon, authenticated;
revoke all on function public.ez_reactivate_helper(uuid, uuid) from public, anon, authenticated;
grant execute on function public.ez_delete_event(uuid) to authenticated;
grant execute on function public.ez_cancel_event(uuid, text) to authenticated;
grant execute on function public.ez_restore_event(uuid) to authenticated;
grant execute on function public.ez_create_helper(uuid, text, text, text, text, boolean, text) to authenticated;
grant execute on function public.ez_reactivate_helper(uuid, uuid) to authenticated;
