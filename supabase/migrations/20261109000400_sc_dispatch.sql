-- Schnittstellen-Connector (spec.md SC v0.2), Tasks T6 und T8: Funktionen für die Edge Function sc-send (nur service_role),
-- Versand-Job (pg_cron → pg_net → sc-send), täglicher Job (Erinnerung vor Ablauf, abgelaufen, „zu alt“, Löschlauf).
-- Vault-Einträge je Umgebung (Product Owner, supabase/setup/README.md): sc_dispatch_url, sc_dispatch_secret, sc_app_url.

-- Beginn der laufenden Stunde und des laufenden Tages (Europe/Berlin)
create function public.sc_period_start(p_unit text)
returns timestamptz
language sql
stable
set search_path = ''
as $$
  select (date_trunc(p_unit, now() at time zone 'Europe/Berlin')) at time zone 'Europe/Berlin';
$$;

-- Geheimnis des Job-Aufrufs prüfen
create function public.sc_check_dispatch_secret(p_secret text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(p_secret <> '' and p_secret = public.sc_vault_get('sc_dispatch_secret'), false);
$$;

-- Fällige E-Mails holen und sperren (R13: Grenzen je Stunde und Tag)
create function public.sc_claim(p_max int)
returns table (outbox_id uuid, connection_id uuid, recipient_email text, subject text, body text,
               sender_email text, sender_name text)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_conn public.sc_connections;
  v_hour int;
  v_day int;
  v_free int;
  v_hour_start timestamptz := public.sc_period_start('hour');
  v_day_start timestamptz := public.sc_period_start('day');
begin
  select * into v_conn from public.sc_connections c where c.kind = 'email_brevo' and c.state = 'active';
  if not found then
    return;
  end if;

  select count(*) filter (where o.sent_at >= v_hour_start or o.claimed_until > now()),
         count(*) filter (where o.sent_at >= v_day_start or o.claimed_until > now())
    into v_hour, v_day
    from public.sc_outbox o
   where o.connection_id = v_conn.id
     and ((o.state = 'sent' and o.sent_at >= v_day_start) or (o.state = 'waiting' and o.claimed_until > now()));

  v_free := least(coalesce(p_max, 20), v_conn.hourly_limit - v_hour, v_conn.daily_limit - v_day);
  if v_free <= 0 then
    if v_conn.daily_limit - v_day <= 0 then
      if not exists (select 1 from public.sc_log l where l.kind = 'limit_reached' and l.connection_id = v_conn.id
                        and l.created_at >= v_day_start and l.message like 'Tag%') then
        perform public.sc_log_write(v_conn.id, null, 'limit_reached', 'rejected',
          format('Tageslimit erreicht (%s)', v_conn.daily_limit), null, null);
      end if;
    elsif not exists (select 1 from public.sc_log l where l.kind = 'limit_reached' and l.connection_id = v_conn.id
                         and l.created_at >= v_hour_start and l.message like 'Stunden%') then
      perform public.sc_log_write(v_conn.id, null, 'limit_reached', 'rejected',
        format('Stundenlimit erreicht (%s)', v_conn.hourly_limit), null, null);
    end if;
    return;
  end if;

  return query
  with due as (
    select o.id
      from public.sc_outbox o
     where o.state = 'waiting'
       and o.next_attempt_at <= now()
       and (o.claimed_until is null or o.claimed_until <= now())
     order by o.next_attempt_at, o.created_at
     limit v_free
     for update skip locked
  ), claimed as (
    update public.sc_outbox o
       set claimed_until = now() + interval '10 minutes',
           attempts = least(o.attempts + 1, 3),
           connection_id = v_conn.id
      from due
     where o.id = due.id
    returning o.id, o.recipient_email, o.subject, o.body
  )
  select c.id, v_conn.id, c.recipient_email::text, c.subject, c.body, v_conn.sender_email::text, v_conn.sender_name
    from claimed c;
end;
$$;

-- Key einer Anbindung (nur für die Edge Function)
create function public.sc_connection_key(p_connection uuid)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select public.sc_vault_get('sc_connection_' || p_connection::text);
$$;

-- Ergebnis eines Versands (R7). p_error_kind: recipient (400 Empfänger), auth (401/403), rate (429), server (5xx, Zeit)
create function public.sc_report(p_outbox uuid, p_ok boolean, p_error_kind text, p_message text, p_provider_id text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_row public.sc_outbox;
  v_conn public.sc_connections;
  v_failures int;
begin
  select * into v_row from public.sc_outbox where id = p_outbox for update;
  if not found or v_row.state <> 'waiting' then
    return;
  end if;
  select * into v_conn from public.sc_connections where id = v_row.connection_id for update;

  if p_ok then
    update public.sc_outbox
       set state = 'sent', sent_at = now(), provider_message_id = left(p_provider_id, 200), claimed_until = null,
           last_error = null, state_changed_at = now()
     where id = p_outbox;
    update public.sc_connections
       set last_success_at = now(), consecutive_failures = 0
     where id = v_row.connection_id;
    perform public.sc_log_write(v_row.connection_id, v_row.module_code, 'send', 'ok', v_row.occasion_code, p_outbox, null);
    return;
  end if;

  if p_error_kind = 'recipient' or v_row.attempts >= 3 then
    update public.sc_outbox
       set state = 'failed', claimed_until = null, last_error = left(p_message, 300), state_changed_at = now()
     where id = p_outbox;
  else
    update public.sc_outbox
       set claimed_until = null, last_error = left(p_message, 300),
           next_attempt_at = now() + case when v_row.attempts <= 1 then interval '15 minutes' else interval '1 hour' end
     where id = p_outbox;
  end if;
  perform public.sc_log_write(v_row.connection_id, v_row.module_code, 'send', 'error',
    v_row.occasion_code || ': ' || coalesce(p_message, ''), p_outbox, null);

  if v_conn.id is not null then
    v_failures := case when p_error_kind in ('auth', 'server') then v_conn.consecutive_failures + 1
                       else v_conn.consecutive_failures end;
    update public.sc_connections
       set last_error_at = now(), last_error = left(p_message, 300), consecutive_failures = v_failures,
           state = case when v_failures >= 3 and state = 'active' then 'disturbed'::public.sc_connection_state
                        else state end
     where id = v_conn.id;
    if v_failures >= 3 and v_conn.state = 'active' then
      perform public.sc_log_write(v_conn.id, null, 'state_changed', 'error', 'active → disturbed (3 Fehler in Folge)',
        null, null);
    end if;
  end if;
end;
$$;

-- Test-E-Mail vorbereiten (US-SC-03); Recht des Admins prüft auch die Edge Function mit seinem JWT
create function public.sc_test_prepare(p_connection uuid, p_user uuid)
returns table (recipient_email text, subject text, body text, sender_email text, sender_name text)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_person uuid;
  v_email text;
  v_conn public.sc_connections;
  v_occ public.sc_mail_occasions;
  v_values jsonb;
begin
  select a.person_id, a.login_email::text into v_person, v_email
    from public.ad_accesses a where a.auth_user_id = p_user and a.status = 'active';
  if v_person is null or v_person not in (select public.sc_persons_with_level('SC', 'edit')) then
    raise exception 'SC_FORBIDDEN' using errcode = 'P0001';
  end if;
  select * into v_conn from public.sc_connections where id = p_connection;
  if not found then
    raise exception 'SC_CONNECTION_UNKNOWN' using errcode = 'P0001';
  end if;
  if v_conn.key_last4 is null then
    raise exception 'SC_KEY_MISSING' using errcode = 'P0001';
  end if;
  select * into v_occ from public.sc_mail_occasions where code = 'sc_test';
  v_values := jsonb_build_object('link', public.sc_app_url() || v_occ.link_path);
  return query select v_email, public.sc_render(v_occ.subject, v_values), public.sc_render(v_occ.body, v_values),
                      v_conn.sender_email::text, v_conn.sender_name;
end;
$$;

-- Ergebnis der Test-E-Mail; Erfolg setzt gestörte oder abgelaufene Anbindungen wieder aktiv (Abschnitt 4)
create function public.sc_test_report(p_connection uuid, p_user uuid, p_ok boolean, p_message text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_conn public.sc_connections;
  v_activate boolean;
begin
  select * into v_conn from public.sc_connections where id = p_connection for update;
  if not found then
    raise exception 'SC_CONNECTION_UNKNOWN' using errcode = 'P0001';
  end if;

  if p_ok then
    v_activate := v_conn.state in ('disturbed', 'expired')
      and (v_conn.key_expires_on is null or v_conn.key_expires_on > (now() at time zone 'Europe/Berlin')::date)
      and not exists (select 1 from public.sc_connections c
                       where c.kind = v_conn.kind and c.state = 'active' and c.id <> p_connection);
    update public.sc_connections
       set last_test_ok_at = clock_timestamp(), last_success_at = now(), consecutive_failures = 0,
           state = case when v_activate then 'active'::public.sc_connection_state else state end
     where id = p_connection;
    perform public.sc_log_write(p_connection, 'SC', 'test', 'ok', 'Test-E-Mail versendet', null, p_user);
    if v_activate then
      perform public.sc_log_write(p_connection, null, 'state_changed', 'ok',
        v_conn.state::text || ' → active (Test erfolgreich)', null, p_user);
    end if;
  else
    update public.sc_connections
       set last_error_at = now(), last_error = left(p_message, 300)
     where id = p_connection;
    perform public.sc_log_write(p_connection, 'SC', 'test', 'error', p_message, null, p_user);
  end if;
end;
$$;

-- Versand-Job: Edge Function nur aufrufen, wenn E-Mails fällig sind (A1)
create function public.sc_dispatch()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_url text := public.sc_vault_get('sc_dispatch_url');
  v_secret text := public.sc_vault_get('sc_dispatch_secret');
begin
  if v_url is null or v_secret is null then
    return;
  end if;
  if not exists (select 1 from public.sc_connections c where c.kind = 'email_brevo' and c.state = 'active') then
    return;
  end if;
  if not exists (select 1 from public.sc_outbox o
                  where o.state = 'waiting' and o.next_attempt_at <= now()
                    and (o.claimed_until is null or o.claimed_until <= now())) then
    return;
  end if;
  perform net.http_post(
    url := v_url,
    body := '{}'::jsonb,
    headers := jsonb_build_object('Content-Type', 'application/json', 'x-sc-dispatch-secret', v_secret),
    timeout_milliseconds := 60000
  );
end;
$$;

-- Täglicher Job (R6, R12; „zu alt“ nach 7 Tagen)
create function public.sc_daily()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_today date := (now() at time zone 'Europe/Berlin')::date;
  r record;
  v_person uuid;
  v_days int;
begin
  -- Erinnerung 30 und 7 Tage vor Ablauf an alle mit SC verwalten
  for r in select c.* from public.sc_connections c
            where c.key_expires_on in (v_today + 30, v_today + 7) and c.state <> 'expired' loop
    v_days := r.key_expires_on - v_today;
    for v_person in select public.sc_persons_with_level('SC', 'manage') loop
      perform public.sc_mail_try_enqueue('sc_key_expiry', v_person,
        jsonb_build_object('anbindung', r.name, 'ablaufdatum', to_char(r.key_expires_on, 'DD.MM.YYYY'),
                           'tage', v_days::text),
        'sc_key_expiry:' || r.id || ':' || r.key_expires_on || ':' || v_days || ':' || v_person);
    end loop;
  end loop;

  -- Ablaufdatum erreicht
  for r in select c.* from public.sc_connections c
            where c.key_expires_on <= v_today and c.state in ('active', 'disturbed') loop
    update public.sc_connections set state = 'expired' where id = r.id;
    perform public.sc_log_write(r.id, null, 'state_changed', 'ok', r.state::text || ' → expired (Ablaufdatum)',
      null, null);
  end loop;

  -- zu alt
  update public.sc_outbox
     set state = 'failed', last_error = 'zu alt', claimed_until = null, state_changed_at = now()
   where state = 'waiting' and created_at < now() - interval '7 days';

  -- Löschlauf nach 90 Tagen
  delete from public.sc_outbox where state_changed_at < now() - interval '90 days';
  delete from public.sc_log where created_at < now() - interval '90 days';
end;
$$;

revoke all on function public.sc_period_start(text) from public, anon, authenticated;
revoke all on function public.sc_check_dispatch_secret(text) from public, anon, authenticated;
revoke all on function public.sc_claim(int) from public, anon, authenticated;
revoke all on function public.sc_connection_key(uuid) from public, anon, authenticated;
revoke all on function public.sc_report(uuid, boolean, text, text, text) from public, anon, authenticated;
revoke all on function public.sc_test_prepare(uuid, uuid) from public, anon, authenticated;
revoke all on function public.sc_test_report(uuid, uuid, boolean, text) from public, anon, authenticated;
revoke all on function public.sc_dispatch() from public, anon, authenticated;
revoke all on function public.sc_daily() from public, anon, authenticated;

grant execute on function public.sc_check_dispatch_secret(text) to service_role;
grant execute on function public.sc_claim(int) to service_role;
grant execute on function public.sc_connection_key(uuid) to service_role;
grant execute on function public.sc_report(uuid, boolean, text, text, text) to service_role;
grant execute on function public.sc_test_prepare(uuid, uuid) to service_role;
grant execute on function public.sc_test_report(uuid, uuid, boolean, text) to service_role;

select cron.schedule('sc-dispatch', '*/5 * * * *', 'select public.sc_dispatch()');
select cron.schedule('sc-daily', '40 2 * * *', 'select public.sc_daily()');
