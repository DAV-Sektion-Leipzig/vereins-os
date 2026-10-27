-- Schnittstellen-Connector (spec.md SC v0.2), Tasks T3, T4, T7: Hilfsfunktionen, Pflege der Anbindungen (Key in Vault),
-- Vorlagen der Anlässe, Postausgang (erneut senden, verwerfen, Inhalt), Hinweise. Alle Funktionen security definer;
-- Prüfung des Rechts im Rumpf (R17), Fehler als SC_* (contracts/error-codes.md).

-- Recht prüfen (R17)
create function public.sc_require(p_min public.ad_level)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.ad_has_level('SC', p_min) then
    raise exception 'SC_FORBIDDEN' using errcode = 'P0001';
  end if;
end;
$$;

-- Protokolleintrag (R15); Meldung gekürzt, nie Key oder Inhalt
create function public.sc_log_write(
  p_connection uuid, p_module text, p_kind public.sc_log_kind, p_result public.sc_log_result,
  p_message text default null, p_outbox uuid default null, p_actor uuid default auth.uid()
)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.sc_log (connection_id, module_code, actor_user_id, kind, result, message, outbox_id)
  values (p_connection, p_module, p_actor, p_kind, p_result, left(p_message, 300), p_outbox);
$$;

-- Wert aus Vault (nur intern)
create function public.sc_vault_get(p_name text)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select s.decrypted_secret from vault.decrypted_secrets s where s.name = p_name limit 1;
$$;

-- Platzhalter einer Vorlage (ohne Klammern)
create function public.sc_template_placeholders(p_text text)
returns text[]
language sql
immutable
set search_path = ''
as $$
  select coalesce(array_agg(distinct m[1]), '{}') from regexp_matches(coalesce(p_text, ''), '\{([a-z_]+)\}', 'g') as m;
$$;

-- R9: Platzhalter und Längen
create function public.sc_check_template(p_allowed text[], p_subject text, p_body text)
returns void
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_unknown text;
begin
  if coalesce(btrim(p_subject), '') = '' or coalesce(btrim(p_body), '') = '' then
    raise exception 'SC_TEXT_REQUIRED' using errcode = 'P0001';
  end if;
  if char_length(btrim(p_subject)) > 150 or char_length(btrim(p_body)) > 2000 then
    raise exception 'SC_TOO_LONG' using errcode = 'P0001';
  end if;
  select p into v_unknown
    from unnest(public.sc_template_placeholders(p_subject) || public.sc_template_placeholders(p_body)) as p
   where p <> all (p_allowed)
   limit 1;
  if v_unknown is not null then
    raise exception 'SC_PLACEHOLDER_UNKNOWN' using errcode = 'P0001', detail = v_unknown;
  end if;
end;
$$;

-- Platzhalter ersetzen
create function public.sc_render(p_text text, p_values jsonb)
returns text
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_result text := p_text;
  v_key text;
  v_value text;
begin
  for v_key, v_value in select key, value from jsonb_each_text(coalesce(p_values, '{}')) loop
    v_result := replace(v_result, '{' || v_key || '}', coalesce(v_value, ''));
  end loop;
  return v_result;
end;
$$;

-- Adresse des Vereins OS je Umgebung (A6)
create function public.sc_app_url()
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select rtrim(coalesce(public.sc_vault_get('sc_app_url'), 'http://localhost:5173'), '/');
$$;

-- 2.3 Anbindung anlegen oder ändern (US-SC-02)
create function public.sc_save_connection(
  p_id uuid, p_kind public.sc_connection_kind, p_name text, p_sender_email text, p_sender_name text,
  p_key_expires_on date, p_hourly_limit int default 100, p_daily_limit int default 300
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid := p_id;
  v_old public.sc_connections;
begin
  perform public.sc_require('manage');
  if coalesce(btrim(p_name), '') = '' or char_length(btrim(p_name)) > 80
     or coalesce(btrim(p_sender_name), '') = '' or char_length(btrim(p_sender_name)) > 80 then
    raise exception 'SC_NAME_INVALID' using errcode = 'P0001';
  end if;
  if coalesce(btrim(p_sender_email), '') !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
    raise exception 'SC_EMAIL_INVALID' using errcode = 'P0001';
  end if;
  if coalesce(p_hourly_limit, 0) not between 1 and 100 or coalesce(p_daily_limit, 0) not between 1 and 300 then
    raise exception 'SC_LIMIT_INVALID' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.sc_connections c
              where lower(c.name) = lower(btrim(p_name)) and c.id is distinct from p_id) then
    raise exception 'SC_NAME_TAKEN' using errcode = 'P0001';
  end if;

  if p_id is null then
    insert into public.sc_connections (kind, name, sender_email, sender_name, key_expires_on, hourly_limit, daily_limit)
    values (p_kind, btrim(p_name), btrim(p_sender_email), btrim(p_sender_name), p_key_expires_on,
            p_hourly_limit, p_daily_limit)
    returning id into v_id;
    perform public.sc_log_write(v_id, null, 'connection_created', 'ok', btrim(p_name));
  else
    select * into v_old from public.sc_connections where id = p_id for update;
    if not found then
      raise exception 'SC_CONNECTION_UNKNOWN' using errcode = 'P0001';
    end if;
    if v_old.kind <> p_kind then
      raise exception 'SC_KIND_FIXED' using errcode = 'P0001';
    end if;
    update public.sc_connections
       set name = btrim(p_name),
           sender_email = btrim(p_sender_email),
           sender_name = btrim(p_sender_name),
           key_expires_on = p_key_expires_on,
           hourly_limit = p_hourly_limit,
           daily_limit = p_daily_limit,
           config_changed_at = case
             when v_old.sender_email is distinct from btrim(p_sender_email)::extensions.citext
               or v_old.sender_name is distinct from btrim(p_sender_name) then clock_timestamp()
             else config_changed_at end
     where id = p_id;
    perform public.sc_log_write(p_id, null, 'connection_changed', 'ok', btrim(p_name));
  end if;
  return v_id;
end;
$$;

-- API-Key hinterlegen oder wechseln (US-SC-04, R11, A3)
create function public.sc_set_key(p_id uuid, p_key text, p_expires_on date)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_conn public.sc_connections;
  v_secret uuid;
  v_name text := 'sc_connection_' || p_id::text;
  v_key text := btrim(coalesce(p_key, ''));
begin
  perform public.sc_require('manage');
  select * into v_conn from public.sc_connections where id = p_id for update;
  if not found then
    raise exception 'SC_CONNECTION_UNKNOWN' using errcode = 'P0001';
  end if;
  if char_length(v_key) not between 8 and 500 or v_key ~ '\s' then
    raise exception 'SC_KEY_INVALID' using errcode = 'P0001';
  end if;

  select s.id into v_secret from vault.decrypted_secrets s where s.name = v_name;
  if v_secret is null then
    perform vault.create_secret(v_key, v_name, 'Schnittstellen-Connector: API-Key der Anbindung');
  else
    perform vault.update_secret(v_secret, v_key);
  end if;

  update public.sc_connections
     set key_last4 = right(v_key, 4),
         key_expires_on = p_expires_on,
         key_changed_at = now(),
         key_changed_by = auth.uid(),
         config_changed_at = clock_timestamp(),
         consecutive_failures = 0,
         state = case when state = 'active' then 'disturbed'::public.sc_connection_state else state end
   where id = p_id;

  perform public.sc_log_write(p_id, null, 'key_changed', 'ok', '…' || right(v_key, 4));
  if v_conn.state = 'active' then
    perform public.sc_log_write(p_id, null, 'state_changed', 'ok', 'gestört bis zum erfolgreichen Test (neuer Key)');
  end if;
end;
$$;

-- Aktivieren oder abschalten (US-SC-03, US-SC-05; R3, R4)
create function public.sc_set_state(p_id uuid, p_state public.sc_connection_state)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_conn public.sc_connections;
begin
  perform public.sc_require('manage');
  if p_state not in ('active', 'disabled') then
    raise exception 'SC_STATE_INVALID' using errcode = 'P0001';
  end if;
  select * into v_conn from public.sc_connections where id = p_id for update;
  if not found then
    raise exception 'SC_CONNECTION_UNKNOWN' using errcode = 'P0001';
  end if;
  if v_conn.state = p_state then
    return;
  end if;

  if p_state = 'active' then
    if v_conn.key_last4 is null then
      raise exception 'SC_KEY_MISSING' using errcode = 'P0001';
    end if;
    if v_conn.key_expires_on is not null and v_conn.key_expires_on <= (now() at time zone 'Europe/Berlin')::date then
      raise exception 'SC_KEY_EXPIRED' using errcode = 'P0001';
    end if;
    if v_conn.last_test_ok_at is null or v_conn.last_test_ok_at <= v_conn.config_changed_at then
      raise exception 'SC_TEST_REQUIRED' using errcode = 'P0001';
    end if;
    if exists (select 1 from public.sc_connections c
                where c.kind = v_conn.kind and c.state = 'active' and c.id <> p_id) then
      raise exception 'SC_ALREADY_ACTIVE' using errcode = 'P0001';
    end if;
  end if;

  update public.sc_connections
     set state = p_state,
         consecutive_failures = case when p_state = 'active' then 0 else consecutive_failures end
   where id = p_id;
  perform public.sc_log_write(p_id, null, 'state_changed', 'ok', v_conn.state::text || ' → ' || p_state::text);
end;
$$;

-- Module freigeben (US-SC-06, R2)
create function public.sc_set_modules(p_id uuid, p_modules text[])
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_old text;
  v_new text;
begin
  perform public.sc_require('manage');
  if not exists (select 1 from public.sc_connections where id = p_id) then
    raise exception 'SC_CONNECTION_UNKNOWN' using errcode = 'P0001';
  end if;
  if exists (select 1 from unnest(coalesce(p_modules, '{}')) m
              where not exists (select 1 from public.ad_modules a where a.code = m)) then
    raise exception 'SC_MODULE_UNKNOWN' using errcode = 'P0001';
  end if;

  select coalesce(string_agg(module_code, ', ' order by module_code), '–') into v_old
    from public.sc_connection_modules where connection_id = p_id;

  delete from public.sc_connection_modules
   where connection_id = p_id and module_code <> all (coalesce(p_modules, '{}'));
  insert into public.sc_connection_modules (connection_id, module_code)
  select p_id, m from unnest(coalesce(p_modules, '{}')) m
  on conflict do nothing;

  select coalesce(string_agg(module_code, ', ' order by module_code), '–') into v_new
    from public.sc_connection_modules where connection_id = p_id;
  if v_old <> v_new then
    perform public.sc_log_write(p_id, null, 'modules_changed', 'ok', v_old || ' → ' || v_new);
  end if;
end;
$$;

-- Vorlagen lesen (Betreff und Text nur mit SC ≥ bearbeiten)
create function public.sc_occasion_texts()
returns table (code text, subject text, body text)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform public.sc_require('edit');
  return query select o.code, o.subject, o.body from public.sc_mail_occasions o order by o.module_code, o.name;
end;
$$;

-- Vorlage speichern (US-SC-07, R8, R9)
create function public.sc_save_occasion(p_code text, p_subject text, p_body text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_occ public.sc_mail_occasions;
begin
  perform public.sc_require('edit');
  select * into v_occ from public.sc_mail_occasions where code = p_code for update;
  if not found then
    raise exception 'SC_OCCASION_UNKNOWN' using errcode = 'P0001';
  end if;
  perform public.sc_check_template(v_occ.placeholders, p_subject, p_body);
  update public.sc_mail_occasions
     set subject = btrim(p_subject), body = btrim(p_body), updated_at = now(), updated_by = auth.uid()
   where code = p_code;
  perform public.sc_log_write(null, v_occ.module_code, 'template_changed', 'ok', v_occ.name);
end;
$$;

-- Beispielwerte für die Vorschau
create function public.sc_sample_values(p_placeholders text[], p_link_path text)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(jsonb_object_agg(p, case p
           when 'link' then public.sc_app_url() || p_link_path
           when 'zeitpunkt' then '27.10.2026 10:15'
           when 'ablaufdatum' then '30.06.2027'
           when 'tage' then '30'
           when 'anbindung' then 'E-Mail Sektion'
           else 'Beispiel' end), '{}')
    from unnest(p_placeholders) p;
$$;

create function public.sc_preview_occasion(p_code text, p_subject text, p_body text)
returns table (subject text, body text)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_occ public.sc_mail_occasions;
  v_values jsonb;
begin
  perform public.sc_require('edit');
  select * into v_occ from public.sc_mail_occasions where code = p_code;
  if not found then
    raise exception 'SC_OCCASION_UNKNOWN' using errcode = 'P0001';
  end if;
  perform public.sc_check_template(v_occ.placeholders, p_subject, p_body);
  v_values := public.sc_sample_values(v_occ.placeholders, v_occ.link_path);
  return query select public.sc_render(btrim(p_subject), v_values), public.sc_render(btrim(p_body), v_values);
end;
$$;

-- Postausgang: erneut senden, verwerfen, Inhalt (US-SC-10)
create function public.sc_outbox_retry(p_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_row public.sc_outbox;
begin
  perform public.sc_require('edit');
  select * into v_row from public.sc_outbox where id = p_id for update;
  if not found then
    raise exception 'SC_OUTBOX_UNKNOWN' using errcode = 'P0001';
  end if;
  if v_row.state <> 'failed' then
    raise exception 'SC_OUTBOX_STATE' using errcode = 'P0001';
  end if;
  update public.sc_outbox
     set state = 'waiting', attempts = 0, next_attempt_at = now(), claimed_until = null,
         state_changed_at = now()
   where id = p_id;
  perform public.sc_log_write(v_row.connection_id, v_row.module_code, 'retry', 'ok', v_row.occasion_code, p_id);
end;
$$;

create function public.sc_outbox_discard(p_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_row public.sc_outbox;
begin
  perform public.sc_require('edit');
  select * into v_row from public.sc_outbox where id = p_id for update;
  if not found then
    raise exception 'SC_OUTBOX_UNKNOWN' using errcode = 'P0001';
  end if;
  if v_row.state not in ('waiting', 'failed') then
    raise exception 'SC_OUTBOX_STATE' using errcode = 'P0001';
  end if;
  update public.sc_outbox
     set state = 'discarded', claimed_until = null, state_changed_at = now()
   where id = p_id;
  perform public.sc_log_write(v_row.connection_id, v_row.module_code, 'discard', 'ok', v_row.occasion_code, p_id);
end;
$$;

create function public.sc_outbox_content(p_id uuid)
returns table (subject text, body text)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform public.sc_require('edit');
  return query select o.subject, o.body from public.sc_outbox o where o.id = p_id;
end;
$$;

-- Hinweise für Seite und Startseite (US-SC-13); ohne Recht leer
create function public.sc_status()
returns table (kind text, amount int, message text)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_today date := (now() at time zone 'Europe/Berlin')::date;
  v_day_start timestamptz := (date_trunc('day', now() at time zone 'Europe/Berlin')) at time zone 'Europe/Berlin';
  v_failed int;
  v_sent int;
  r record;
begin
  if not public.ad_has_level('SC', 'read') then
    return;
  end if;

  for r in select c.* from public.sc_connections c order by c.name loop
    if r.state = 'disturbed' then
      return query select 'disturbed'::text, 1,
        format('Die Anbindung „%s“ ist gestört. Prüfe die Schnittstellen.', r.name);
    elsif r.state = 'expired' then
      return query select 'expired'::text, 1,
        format('Der API-Key der Anbindung „%s“ ist abgelaufen.', r.name);
    elsif r.key_expires_on is not null and r.key_expires_on <= v_today + 30 then
      return query select 'expiring'::text, (r.key_expires_on - v_today)::int,
        format('Der API-Key der Anbindung „%s“ läuft am %s ab.', r.name, to_char(r.key_expires_on, 'DD.MM.YYYY'));
    end if;
    if r.state = 'active' then
      select count(*)::int into v_sent from public.sc_outbox o
       where o.connection_id = r.id and o.state = 'sent' and o.sent_at >= v_day_start;
      if v_sent >= r.daily_limit then
        return query select 'limit'::text, v_sent,
          format('Tageslimit erreicht (%s von %s). Weitere E-Mails gehen morgen hinaus.', v_sent, r.daily_limit);
      elsif v_sent >= r.daily_limit * 5 / 6 then
        return query select 'limit_near'::text, v_sent,
          format('Tageslimit fast erreicht (%s von %s).', v_sent, r.daily_limit);
      end if;
    end if;
  end loop;

  select count(*)::int into v_failed from public.sc_outbox o where o.state = 'failed';
  if v_failed = 1 then
    return query select 'failed'::text, 1, 'Eine E-Mail konnte nicht versendet werden.'::text;
  elsif v_failed > 1 then
    return query select 'failed'::text, v_failed, format('%s E-Mails konnten nicht versendet werden.', v_failed);
  end if;
end;
$$;

-- Grants: nur gezielt
revoke all on function public.sc_require(public.ad_level) from public, anon, authenticated;
revoke all on function public.sc_log_write(uuid, text, public.sc_log_kind, public.sc_log_result, text, uuid, uuid)
  from public, anon, authenticated;
revoke all on function public.sc_vault_get(text) from public, anon, authenticated;
revoke all on function public.sc_template_placeholders(text) from public, anon, authenticated;
revoke all on function public.sc_check_template(text[], text, text) from public, anon, authenticated;
revoke all on function public.sc_render(text, jsonb) from public, anon, authenticated;
revoke all on function public.sc_app_url() from public, anon, authenticated;
revoke all on function public.sc_sample_values(text[], text) from public, anon, authenticated;
revoke all on function public.sc_save_connection(uuid, public.sc_connection_kind, text, text, text, date, int, int)
  from public, anon, authenticated;
revoke all on function public.sc_set_key(uuid, text, date) from public, anon, authenticated;
revoke all on function public.sc_set_state(uuid, public.sc_connection_state) from public, anon, authenticated;
revoke all on function public.sc_set_modules(uuid, text[]) from public, anon, authenticated;
revoke all on function public.sc_occasion_texts() from public, anon, authenticated;
revoke all on function public.sc_save_occasion(text, text, text) from public, anon, authenticated;
revoke all on function public.sc_preview_occasion(text, text, text) from public, anon, authenticated;
revoke all on function public.sc_outbox_retry(uuid) from public, anon, authenticated;
revoke all on function public.sc_outbox_discard(uuid) from public, anon, authenticated;
revoke all on function public.sc_outbox_content(uuid) from public, anon, authenticated;
revoke all on function public.sc_status() from public, anon, authenticated;

grant execute on function public.sc_save_connection(uuid, public.sc_connection_kind, text, text, text, date, int, int)
  to authenticated;
grant execute on function public.sc_set_key(uuid, text, date) to authenticated;
grant execute on function public.sc_set_state(uuid, public.sc_connection_state) to authenticated;
grant execute on function public.sc_set_modules(uuid, text[]) to authenticated;
grant execute on function public.sc_occasion_texts() to authenticated;
grant execute on function public.sc_save_occasion(text, text, text) to authenticated;
grant execute on function public.sc_preview_occasion(text, text, text) to authenticated;
grant execute on function public.sc_outbox_retry(uuid) to authenticated;
grant execute on function public.sc_outbox_discard(uuid) to authenticated;
grant execute on function public.sc_outbox_content(uuid) to authenticated;
grant execute on function public.sc_status() to authenticated;
