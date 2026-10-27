-- Review S-04: Login-Identität in Supabase Auth nicht auf eine fremde Domain änderbar (R1, R20).
--
-- Problem: supabase.auth.updateUser({ email }) schreibt die neue Adresse über GoTrue in
-- auth.users.email_change und nach Bestätigung in auth.users.email. R1 (ad_login_email_allowed)
-- galt bisher nur für ad_accesses. Login und Passwort-Reset liefen danach über eine private Adresse.
--
-- Regeln (nur bei tatsächlicher Änderung der Spalte, damit GoTrue-Abläufe mit vollständigem
-- Zeilen-Update – Login, Passwort, Bann – nicht gestört werden):
--   1. Neue email bzw. neue, nicht leere email_change muss R1 erfüllen → sonst AD_EMAIL_DOMAIN.
--      Leere/NULL-Werte gehen durch (GoTrue setzt email_change nach Abschluss auf '').
--   2. Ist der Auth-Eintrag mit einem Zugang verknüpft (ad_accesses.auth_user_id), muss die neue
--      Adresse der login_email des Zugangs entsprechen → sonst AD_EMAIL_CHANGE_VIA_FUNCTION.
--      Login-Adressen ändert nur die Administration (ad-access change_email löscht den
--      Auth-Eintrag und legt ihn neu an, statt ihn zu ändern). Ohne Zugang gilt nur Regel 1.
-- Kein Ablauf im Repo (Edge Functions, Seeds, prod-bootstrap.sql) ändert email per UPDATE.

create function public.ad_auth_user_email_guard()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_login extensions.citext;
  v_linked boolean;
  v_candidates text[] := array[]::text[];
  v_addr text;
begin
  if new.email is distinct from old.email and coalesce(new.email, '') <> '' then
    v_candidates := v_candidates || new.email::text;
  end if;
  if new.email_change is distinct from old.email_change and coalesce(new.email_change, '') <> '' then
    v_candidates := v_candidates || new.email_change::text;
  end if;

  if cardinality(v_candidates) = 0 then
    return new;
  end if;

  select a.login_email, true
    into v_login, v_linked
    from public.ad_accesses a
   where a.auth_user_id = new.id;

  foreach v_addr in array v_candidates loop
    -- Regel 1 (R1)
    if not coalesce(public.ad_login_email_allowed(v_addr::extensions.citext), false) then
      raise exception 'AD_EMAIL_DOMAIN' using errcode = 'P0001';
    end if;
    -- Regel 2 (R20): nur mit verknüpftem Zugang
    if coalesce(v_linked, false) and v_addr::extensions.citext is distinct from v_login then
      raise exception 'AD_EMAIL_CHANGE_VIA_FUNCTION' using errcode = 'P0001';
    end if;
  end loop;

  return new;
end;
$$;

revoke all on function public.ad_auth_user_email_guard() from public, anon, authenticated;

create trigger ad_auth_user_email_guard
  before update of email, email_change on auth.users
  for each row execute function public.ad_auth_user_email_guard();
