-- US-AD-14, US-AD-15, spec T4 (Teil): Hinweis auf Anmeldungen des Notfall-Admins (R16) und Löschlauf
-- des Protokolls nach 5 Jahren (R13), täglich 01:15 UTC.

create table public.ad_notice_acks (
  user_id uuid primary key default auth.uid() references auth.users (id) on delete cascade,
  emergency_acknowledged_until timestamptz not null
);

comment on table public.ad_notice_acks is 'Zeitpunkt „Zur Kenntnis genommen“ je Nutzer für den Hinweis Notfall-Admin.';

alter table public.ad_notice_acks enable row level security;
revoke all on table public.ad_notice_acks from public, anon, authenticated;
grant select, insert (emergency_acknowledged_until), update (emergency_acknowledged_until)
  on table public.ad_notice_acks to authenticated;

create policy ad_notice_acks_select on public.ad_notice_acks
  for select to authenticated using (user_id = auth.uid());
create policy ad_notice_acks_insert on public.ad_notice_acks
  for insert to authenticated with check (user_id = auth.uid());
create policy ad_notice_acks_update on public.ad_notice_acks
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Anmeldungen des Notfall-Admins nach dem letzten „Zur Kenntnis genommen“
create function public.ad_pending_emergency_logins()
returns table (count int, last_at timestamptz)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.ad_has_level('AD', 'read') then
    raise exception 'AD_FORBIDDEN' using errcode = 'P0001';
  end if;
  return query
  select count(*)::int, max(l.occurred_at)
    from public.ad_audit_log l
   where l.action = 'emergency_login'
     and l.occurred_at > coalesce(
       (select n.emergency_acknowledged_until from public.ad_notice_acks n where n.user_id = auth.uid()),
       '-infinity'::timestamptz);
end;
$$;

create function public.ad_acknowledge_emergency()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.ad_has_level('AD', 'read') then
    raise exception 'AD_FORBIDDEN' using errcode = 'P0001';
  end if;
  insert into public.ad_notice_acks (user_id, emergency_acknowledged_until)
  values (auth.uid(), now())
  on conflict (user_id) do update set emergency_acknowledged_until = excluded.emergency_acknowledged_until;
end;
$$;

revoke all on function public.ad_pending_emergency_logins() from public, anon, authenticated;
revoke all on function public.ad_acknowledge_emergency() from public, anon, authenticated;
grant execute on function public.ad_pending_emergency_logins() to authenticated;
grant execute on function public.ad_acknowledge_emergency() to authenticated;

-- R13: Protokolleinträge nach 5 Jahren löschen (pg_cron läuft in UTC)
select cron.schedule(
  'ad_audit_log_retention',
  '15 1 * * *',
  $$delete from public.ad_audit_log where occurred_at < now() - interval '5 years'$$
);
