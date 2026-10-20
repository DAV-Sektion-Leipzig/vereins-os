-- US-AD-02, spec T6 (Teil): eigene Person und eigener Zugang für Kopfzeile und Startseite.
-- Für alle angemeldeten Nutzer, auch ohne Leserechte auf ea_persons oder ad_accesses (spec.md v0.5 Abschnitt 2).

create function public.ad_me()
returns table (person_id uuid, first_name text, last_name text, access_status public.ad_access_status)
language sql
stable
security definer
set search_path = ''
as $$
  select p.id, p.first_name, p.last_name, a.status
    from public.ad_accesses a
    join public.ea_persons p on p.id = a.person_id
   where a.auth_user_id = auth.uid();
$$;

revoke all on function public.ad_me() from public, anon, authenticated;
grant execute on function public.ad_me() to authenticated;
