-- Kern v0.7.4 (spec.md v0.9.3, Review des Kerns, Entscheidungen Product Owner 23.10.2026):
-- 1. ea_person_in_referate nur intern (kein Ja/Nein-Orakel über Referatszugehörigkeit unsichtbarer Personen)
-- 2. ad_login_email_ok: R1-Prüfung für das Frontend vor dem Anlegen einer Person (US-AD-07 AK5)
-- 3. Einladung über das Supabase-Dashboard wird protokolliert; ad_apply_invite vervollständigt den Eintrag
-- 4. ea_create_volunteer / ea_activate_person prüfen Lesestufe und Bezugsart der Eigenschaftsart

-- 1.
revoke execute on function public.ea_person_in_referate(uuid, uuid[]) from authenticated;

-- 2.
create function public.ad_login_email_ok(p_email extensions.citext)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not (public.ad_has_level('AD', 'edit') or public.ad_has_any_level('EA', 'edit') or public.ad_has_level('GR', 'edit')) then
    raise exception 'AD_FORBIDDEN' using errcode = 'P0001';
  end if;
  return coalesce(public.ad_login_email_allowed(p_email), false);
end;
$$;

revoke all on function public.ad_login_email_ok(extensions.citext) from public, anon, authenticated;
grant execute on function public.ad_login_email_ok(extensions.citext) to authenticated;

-- 3. Trigger: none → invited schreibt Protokoll ohne Akteur (Dashboard); bei ad-invite vervollständigt ad_apply_invite
create or replace function public.ad_auth_user_created()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_person uuid;
begin
  if new.email is not null then
    update public.ad_accesses a
       set auth_user_id = new.id,
           status = case when a.status = 'none' then 'invited'::public.ad_access_status else a.status end
     where a.login_email = new.email::extensions.citext
       and a.auth_user_id is null
    returning case when a.status = 'invited' and a.last_invited_at is null then a.person_id end into v_person;

    if v_person is not null then
      insert into public.ad_audit_log (actor_user_id, subject_person_id, action, details)
      values (null, v_person, 'invited', 'Einladung über das Supabase-Dashboard');
    end if;
  end if;
  return new;
end;
$$;

create or replace function public.ad_apply_invite(p_person uuid, p_auth_user uuid, p_actor uuid)
returns table (status public.ad_access_status, last_invited_at timestamptz)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_now timestamptz := now();
  v_system_entry bigint;
begin
  update public.ad_accesses a
     set status = 'invited',
         last_invited_at = v_now,
         auth_user_id = coalesce(p_auth_user, a.auth_user_id)
   where a.person_id = p_person
     and a.status in ('none', 'invited');
  if not found then
    raise exception 'AD_INVALID_STATUS' using errcode = 'P0001';
  end if;

  -- Eintrag des Insert-Triggers (ohne Akteur, gerade entstanden) mit dem Akteur vervollständigen statt doppeln
  select l.id into v_system_entry
    from public.ad_audit_log l
   where l.subject_person_id = p_person
     and l.action = 'invited'
     and l.actor_user_id is null
     and l.occurred_at > v_now - interval '10 minutes'
   order by l.occurred_at desc
   limit 1;

  if v_system_entry is not null then
    update public.ad_audit_log set actor_user_id = p_actor, details = null where id = v_system_entry;
  else
    insert into public.ad_audit_log (actor_user_id, subject_person_id, action)
    values (p_actor, p_person, 'invited');
  end if;

  return query select 'invited'::public.ad_access_status, v_now;
end;
$$;

-- 4. Prüfung der Eigenschaftsart beim Anlegen bzw. Übernehmen (R29, R39, R41)
create or replace function public.ea_check_create(p_property_type uuid, p_referat uuid)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_type public.ea_property_types%rowtype;
  v_all boolean := public.ad_has_level('EA', 'edit');
begin
  if not v_all and cardinality(public.ad_my_referate('EA', 'edit')) = 0 then
    raise exception 'AD_FORBIDDEN' using errcode = 'P0001';
  end if;

  if p_property_type is not null then
    select * into v_type from public.ea_property_types t where t.id = p_property_type;
    if not found then
      raise exception 'AD_BAD_REQUEST' using errcode = 'P0001';
    end if;
    if v_type.read_level = 'confidential' and not public.ad_has_level('AD', 'edit') then
      raise exception 'AD_CONFIDENTIAL_ONLY_AD' using errcode = 'P0001';
    end if;
    if v_type.relation_kind = 'group' then
      raise exception 'EA_GROUP_RELATION_ONLY_GR' using errcode = 'P0001';
    end if;
    if p_referat is not null and v_type.relation_kind <> 'referat' then
      raise exception 'AD_BAD_REQUEST' using errcode = 'P0001';
    end if;
  end if;

  if v_all then
    return;
  end if;

  -- Reichweite Referat: erste Zuordnung mit Bezug auf ein eigenes Referat ist Pflicht (R41)
  if p_property_type is null or p_referat is null or v_type.relation_kind <> 'referat' then
    raise exception 'EA_RELATION_REQUIRED' using errcode = 'P0001';
  end if;
  if not (p_referat = any (public.ad_my_referate('EA', 'edit'))) then
    raise exception 'EA_RELATION_FOREIGN_REFERAT' using errcode = 'P0001';
  end if;
end;
$$;
