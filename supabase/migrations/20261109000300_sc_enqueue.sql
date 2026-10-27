-- Schnittstellen-Connector (spec.md SC v0.2), Tasks T5 und T9: E-Mail in den Postausgang legen (R2, R5, R8–R10),
-- Personen mit einer Mindeststufe, Anlass der Administration „Anmeldung des Notfall-Admins“ mit Trigger.
-- sc_mail_enqueue ist nicht für authenticated ausführbar; Module rufen es aus eigenen security-definer-Funktionen auf.

-- Personen mit aktivem Zugang und mindestens dieser Stufe (Logik wie ad_user_level, für alle Zugänge)
create function public.sc_persons_with_level(p_module text, p_min public.ad_level)
returns setof uuid
language sql
stable
security definer
set search_path = ''
as $$
  select a.person_id
    from public.ad_accesses a
    join public.ad_template_assignments ta on ta.person_id = a.person_id
    join public.ad_template_rights r on r.template_id = ta.template_id
   where a.status = 'active'
     and ta.revoked_at is null
     and (ta.valid_from is null or ta.valid_from <= current_date)
     and (ta.valid_to is null or ta.valid_to >= current_date)
     and r.module_code = p_module
     and r.object is null
     and r.scope = 'all'
   group by a.person_id
  having max(r.level) >= p_min;
$$;

-- R5: Login-Adresse bei aktivem Zugang, sonst Kontakt-E-Mail (gültig heute)
create function public.sc_recipient_email(p_person uuid)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (select a.login_email::text from public.ad_accesses a where a.person_id = p_person and a.status = 'active'),
    (select nullif(btrim(c.field_values ->> 'email'), '')
       from public.ea_properties c
       join public.ea_property_types ct on ct.id = c.property_type_id and ct.system_key = 'contact'
      where c.person_id = p_person
        and c.valid_from <= current_date
        and (c.valid_to is null or c.valid_to >= current_date)
        and nullif(btrim(c.field_values ->> 'email'), '') is not null
      order by c.valid_from desc
      limit 1)
  );
$$;

-- E-Mail einstellen (US-SC-08). Rückgabe: id der (ggf. schon vorhandenen) E-Mail
create function public.sc_mail_enqueue(p_occasion text, p_person uuid, p_values jsonb, p_dedupe_key text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_occ public.sc_mail_occasions;
  v_id uuid;
  v_email text;
  v_unknown text;
  v_values jsonb;
begin
  select * into v_occ from public.sc_mail_occasions where code = p_occasion;
  if not found then
    raise exception 'SC_OCCASION_UNKNOWN' using errcode = 'P0001';
  end if;
  if coalesce(btrim(p_dedupe_key), '') = '' then
    raise exception 'SC_DEDUPE_KEY_REQUIRED' using errcode = 'P0001';
  end if;

  -- R10: vorhandene E-Mail mit diesem Schlüssel
  select o.id into v_id from public.sc_outbox o where o.dedupe_key = p_dedupe_key and o.state <> 'discarded';
  if v_id is not null then
    return v_id;
  end if;

  -- R2: Anbindung für das Modul des Anlasses freigegeben
  if not exists (select 1
                   from public.sc_connection_modules m
                   join public.sc_connections c on c.id = m.connection_id
                  where c.kind = 'email_brevo' and m.module_code = v_occ.module_code) then
    raise exception 'SC_MODULE_NOT_ALLOWED' using errcode = 'P0001';
  end if;

  -- R8, R9: nur erlaubte Platzhalter; {link} setzt SC selbst
  select k into v_unknown
    from jsonb_object_keys(coalesce(p_values, '{}')) k
   where k = 'link' or k <> all (v_occ.placeholders)
   limit 1;
  if v_unknown is not null then
    raise exception 'SC_PLACEHOLDER_UNKNOWN' using errcode = 'P0001', detail = v_unknown;
  end if;

  v_email := public.sc_recipient_email(p_person);
  if v_email is null then
    raise exception 'SC_NO_EMAIL' using errcode = 'P0001';
  end if;

  v_values := coalesce(p_values, '{}') || jsonb_build_object('link', public.sc_app_url() || v_occ.link_path);

  insert into public.sc_outbox (occasion_code, module_code, recipient_person_id, recipient_email, subject, body,
                                dedupe_key)
  values (v_occ.code, v_occ.module_code, p_person, v_email,
          left(public.sc_render(v_occ.subject, v_values), 300), public.sc_render(v_occ.body, v_values),
          p_dedupe_key)
  returning id into v_id;
  return v_id;
end;
$$;

-- Wie sc_mail_enqueue, aber ohne Fehler: Ablehnung steht im Protokoll (für Trigger und Jobs)
create function public.sc_mail_try_enqueue(p_occasion text, p_person uuid, p_values jsonb, p_dedupe_key text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_module text;
  v_detail text;
begin
  return public.sc_mail_enqueue(p_occasion, p_person, p_values, p_dedupe_key);
exception when others then
  get stacked diagnostics v_detail = pg_exception_detail;
  select o.module_code into v_module from public.sc_mail_occasions o where o.code = p_occasion;
  perform public.sc_log_write(null, v_module, 'enqueue_rejected', 'rejected',
    p_occasion || ': ' || sqlerrm || coalesce(' (' || nullif(v_detail, '') || ')', ''));
  return null;
end;
$$;

-- Anlass der Administration (US-SC-14, E3)
insert into public.sc_mail_occasions (code, module_code, name, description, placeholders, link_path, subject, body)
values
  ('ad_emergency_login', 'AD', 'Anmeldung des Notfall-Admins',
   'Kommt bei jeder Anmeldung des Notfall-Admins an alle anderen mit „Administration verwalten“.',
   '{zeitpunkt,link}', '/ad/protokoll',
   'Vereins OS: Anmeldung des Notfall-Admins',
   e'Hallo,\n\nder Notfall-Admin hat sich am {zeitpunkt} im Vereins OS angemeldet. Bitte prüfe, ob das so gewollt war.\n\nZum Protokoll: {link}\n\nDiese E-Mail wurde automatisch versendet. Bitte antworte nicht darauf.')
on conflict (code) do nothing;

-- Trigger: bei jeder Anmeldung des Notfall-Admins E-Mail an die übrigen Admins; scheitert nie (AK3)
create function public.sc_ad_emergency_login_mail()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_person uuid;
  v_when text := to_char(new.occurred_at at time zone 'Europe/Berlin', 'DD.MM.YYYY HH24:MI');
begin
  for v_person in
    select p from public.sc_persons_with_level('AD', 'manage') p
     where p <> new.subject_person_id
       and not exists (select 1 from public.ad_accesses a where a.person_id = p and a.is_emergency)
  loop
    perform public.sc_mail_try_enqueue('ad_emergency_login', v_person, jsonb_build_object('zeitpunkt', v_when),
      'ad_emergency_login:' || new.id || ':' || v_person);
  end loop;
  return new;
exception when others then
  begin
    perform public.sc_log_write(null, 'AD', 'enqueue_rejected', 'rejected', 'ad_emergency_login: ' || sqlerrm);
  exception when others then
    null;
  end;
  return new;
end;
$$;

create trigger sc_ad_emergency_login_mail
  after insert on public.ad_audit_log
  for each row
  when (new.action = 'emergency_login')
  execute function public.sc_ad_emergency_login_mail();

revoke all on function public.sc_persons_with_level(text, public.ad_level) from public, anon, authenticated;
revoke all on function public.sc_recipient_email(uuid) from public, anon, authenticated;
revoke all on function public.sc_mail_enqueue(text, uuid, jsonb, text) from public, anon, authenticated;
revoke all on function public.sc_mail_try_enqueue(text, uuid, jsonb, text) from public, anon, authenticated;
revoke all on function public.sc_ad_emergency_login_mail() from public, anon, authenticated;
