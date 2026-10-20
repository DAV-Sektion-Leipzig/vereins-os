-- US-AD-01, spec T5: Trigger auf auth.users, Testdomains (nur TEST befüllt), R1 und R20 per Trigger.

-- Zusätzlich erlaubte Domains, nur in TEST, nur per SQL-Editor befüllt (spec.md v0.5 Abschnitt 2).
-- Kein Nutzerzugriff: RLS an, keine Policy, kein Grant (Constitution III, Ausnahme).
create table public.ad_test_login_domains (
  domain extensions.citext primary key,
  created_at timestamptz not null default now(),
  constraint ad_test_login_domains_no_at check (position('@' in domain::text) = 0)
);

comment on table public.ad_test_login_domains is
  'Nur TEST: zusätzliche Domains für Login-Adressen (Abnahme der Mail-Abläufe). In PROD immer leer. Nie per Migration, Seed oder Repo befüllen.';

alter table public.ad_test_login_domains enable row level security;
revoke all on table public.ad_test_login_domains from public, anon, authenticated;

-- R1: @dav-leipzig.de oder (nur TEST) eine freigegebene Domain
create function public.ad_login_email_allowed(p_email extensions.citext)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select split_part(p_email::text, '@', 1) <> ''
     and (
       lower(split_part(p_email::text, '@', 2)) = 'dav-leipzig.de'
       or exists (
         select 1 from public.ad_test_login_domains d
          where d.domain = split_part(p_email::text, '@', 2)::extensions.citext
       )
     );
$$;

revoke all on function public.ad_login_email_allowed(extensions.citext) from public, anon, authenticated;
grant execute on function public.ad_login_email_allowed(extensions.citext) to service_role;

-- R1 und R20 auf ad_accesses
create function public.ad_accesses_guard()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not coalesce(public.ad_login_email_allowed(new.login_email), false) then
    raise exception 'AD_EMAIL_DOMAIN' using errcode = 'P0001';
  end if;

  if tg_op = 'UPDATE' and new.login_email is distinct from old.login_email then
    if old.status = 'none' then
      null;
    elsif old.status = 'invited' then
      -- nur über ad-access (change_email) → ad_apply_email_change setzt dieses Kennzeichen
      if coalesce(current_setting('ad.email_change', true), '') <> 'on' then
        raise exception 'AD_EMAIL_CHANGE_VIA_FUNCTION' using errcode = 'P0001';
      end if;
    else
      raise exception 'AD_EMAIL_LOCKED' using errcode = 'P0001';
    end if;
  end if;

  return new;
end;
$$;

revoke all on function public.ad_accesses_guard() from public, anon, authenticated;

create trigger ad_accesses_guard
  before insert or update of login_email on public.ad_accesses
  for each row execute function public.ad_accesses_guard();

-- Anlage in Supabase Auth (ad-invite oder Einladung über das Dashboard): verknüpfen, none → invited
create function public.ad_auth_user_created()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.email is not null then
    update public.ad_accesses a
       set auth_user_id = new.id,
           status = case when a.status = 'none' then 'invited'::public.ad_access_status else a.status end
     where a.login_email = new.email::extensions.citext
       and a.auth_user_id is null;
  end if;
  return new;
end;
$$;

-- Erstes Passwort: invited → active (ein eingelöster Link ohne Passwort ändert nichts)
create function public.ad_auth_user_password_set()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.ad_accesses a
     set status = 'active'
   where a.auth_user_id = new.id
     and a.status = 'invited';
  return new;
end;
$$;

-- Jede Anmeldung des Notfall-Admins protokollieren (R16, auch nach „Passwort vergessen“)
create function public.ad_auth_user_signed_in()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.ad_audit_log (actor_user_id, subject_person_id, action)
  select new.id, a.person_id, 'emergency_login'
    from public.ad_accesses a
   where a.auth_user_id = new.id
     and a.is_emergency;
  return new;
end;
$$;

revoke all on function public.ad_auth_user_created() from public, anon, authenticated;
revoke all on function public.ad_auth_user_password_set() from public, anon, authenticated;
revoke all on function public.ad_auth_user_signed_in() from public, anon, authenticated;

create trigger ad_auth_user_created
  after insert on auth.users
  for each row execute function public.ad_auth_user_created();

create trigger ad_auth_user_password_set
  after update of encrypted_password on auth.users
  for each row
  when (coalesce(old.encrypted_password, '') = '' and coalesce(new.encrypted_password, '') <> '')
  execute function public.ad_auth_user_password_set();

create trigger ad_auth_user_signed_in
  after update of last_sign_in_at on auth.users
  for each row
  when (new.last_sign_in_at is not null and new.last_sign_in_at is distinct from old.last_sign_in_at)
  execute function public.ad_auth_user_signed_in();
