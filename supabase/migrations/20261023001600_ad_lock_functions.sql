-- US-AD-09, spec T4 (Teil): Sperren und Entsperren für die Edge Function ad-access.
-- Der Bann in Supabase Auth wird von der Edge Function gesetzt; hier Status, Zeitstempel und Protokoll.
-- security definer; grant execute nur an service_role.

create function public.ad_apply_lock(p_person uuid, p_actor uuid)
returns table (status public.ad_access_status)
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.ad_accesses a
     set status = 'locked',
         locked_at = now(),
         locked_by = p_actor
   where a.person_id = p_person
     and a.status in ('invited', 'active');
  if not found then
    raise exception 'AD_INVALID_STATUS' using errcode = 'P0001';
  end if;

  insert into public.ad_audit_log (actor_user_id, subject_person_id, action)
  values (p_actor, p_person, 'locked');

  return query select 'locked'::public.ad_access_status;
end;
$$;

-- Zielstatus nach spec.md Abschnitt 4: „aktiv“, wenn ein Passwort gesetzt ist, sonst „eingeladen“
create function public.ad_apply_unlock(p_person uuid, p_actor uuid)
returns table (status public.ad_access_status)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_status public.ad_access_status;
begin
  select case when coalesce(u.encrypted_password, '') <> '' then 'active' else 'invited' end::public.ad_access_status
    into v_status
    from public.ad_accesses a
    left join auth.users u on u.id = a.auth_user_id
   where a.person_id = p_person
     and a.status = 'locked';
  if v_status is null then
    raise exception 'AD_INVALID_STATUS' using errcode = 'P0001';
  end if;

  update public.ad_accesses a
     set status = v_status,
         locked_at = null,
         locked_by = null
   where a.person_id = p_person;

  insert into public.ad_audit_log (actor_user_id, subject_person_id, action)
  values (p_actor, p_person, 'unlocked');

  return query select v_status;
end;
$$;

revoke all on function public.ad_apply_lock(uuid, uuid) from public, anon, authenticated;
revoke all on function public.ad_apply_unlock(uuid, uuid) from public, anon, authenticated;
grant execute on function public.ad_apply_lock(uuid, uuid) to service_role;
grant execute on function public.ad_apply_unlock(uuid, uuid) to service_role;
