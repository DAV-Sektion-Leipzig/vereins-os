-- US-AD-08, spec T4 (Teil): interne Statusfunktionen für die Edge Functions ad-invite und ad-access (change_email).
-- security definer; grant execute nur an service_role (spec.md Abschnitt 3, research.md R-07).
-- p_actor ist der aufrufende Admin (aus dem JWT in der Edge Function); auth.uid() ist im Service-Kontext leer.

-- Einladung verschickt: Status „eingeladen“, zuletzt eingeladen, Auth-Nutzer verknüpft, Protokoll
create function public.ad_apply_invite(p_person uuid, p_auth_user uuid, p_actor uuid)
returns table (status public.ad_access_status, last_invited_at timestamptz)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_now timestamptz := now();
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

  insert into public.ad_audit_log (actor_user_id, subject_person_id, action)
  values (p_actor, p_person, 'invited');

  return query select 'invited'::public.ad_access_status, v_now;
end;
$$;

-- Fehler der Auth-Admin-API: Ausgangsstand ohne Protokoll wiederherstellen (US-AD-08 AK5)
create function public.ad_revert_invite(
  p_person uuid, p_status public.ad_access_status, p_auth_user uuid, p_last_invited_at timestamptz)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.ad_accesses a
     set status = p_status,
         auth_user_id = p_auth_user,
         last_invited_at = p_last_invited_at
   where a.person_id = p_person;
end;
$$;

-- Login-Adresse bei „eingeladen“ ändern (R20): Einladung zurückgenommen, Status „kein Zugang“, Protokoll
create function public.ad_apply_email_change(p_person uuid, p_new_email extensions.citext, p_actor uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_old extensions.citext;
begin
  select a.login_email into v_old from public.ad_accesses a where a.person_id = p_person and a.status = 'invited';
  if v_old is null then
    raise exception 'AD_EMAIL_LOCKED' using errcode = 'P0001';
  end if;

  -- Kennzeichen für den Trigger ad_accesses_guard (nur dieser Weg darf bei „eingeladen“ ändern)
  perform set_config('ad.email_change', 'on', true);
  update public.ad_accesses a
     set login_email = p_new_email,
         auth_user_id = null,
         status = 'none'
   where a.person_id = p_person;
  perform set_config('ad.email_change', '', true);

  insert into public.ad_audit_log (actor_user_id, subject_person_id, action, details)
  values (p_actor, p_person, 'email_changed', v_old::text || ' → ' || p_new_email::text);
end;
$$;

revoke all on function public.ad_apply_invite(uuid, uuid, uuid) from public, anon, authenticated;
revoke all on function public.ad_revert_invite(uuid, public.ad_access_status, uuid, timestamptz) from public, anon, authenticated;
revoke all on function public.ad_apply_email_change(uuid, extensions.citext, uuid) from public, anon, authenticated;
grant execute on function public.ad_apply_invite(uuid, uuid, uuid) to service_role;
grant execute on function public.ad_revert_invite(uuid, public.ad_access_status, uuid, timestamptz) to service_role;
grant execute on function public.ad_apply_email_change(uuid, extensions.citext, uuid) to service_role;
