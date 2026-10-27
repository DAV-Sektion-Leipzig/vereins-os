-- Schnittstellen-Connector (spec.md SC v0.2), Task T13 (ST13): Oberfläche „Schnittstellen“ freigeschaltet;
-- Namen der Ausführenden für das Protokoll der Schnittstellen.

update public.ad_modules set is_available = true where code = 'SC';

-- Namen zu Nutzer-IDs aus sc_log (nur mit SC ≥ lesen; sonst leer). Nur Personen mit Zugang, nur der Name.
create function public.sc_actor_names(p_users uuid[])
returns table (user_id uuid, name text)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.ad_has_level('SC', 'read') then
    return;
  end if;
  return query
  select a.auth_user_id, coalesce(nullif(btrim(p.preferred_name), ''), p.first_name) || ' ' || p.last_name
    from public.ad_accesses a
    join public.ea_persons p on p.id = a.person_id
   where a.auth_user_id = any (coalesce(p_users, '{}'));
end;
$$;

revoke all on function public.sc_actor_names(uuid[]) from public, anon, authenticated;
grant execute on function public.sc_actor_names(uuid[]) to authenticated;
