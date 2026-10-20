-- Einrichtungsskript PROD (US-AD-01, spec T24). Ausführung NUR durch den Product Owner nach
-- supabase/setup/README.md – Claude Code führt dieses Skript nie gegen PROD aus.
-- In CI läuft es nur gegen den lokalen Stack (mit fiktiven Parametern).
--
-- Aufruf (psql):
--   psql "<Verbindung>" -v ON_ERROR_STOP=1 \
--     -v admin_first='<Vorname>' -v admin_last='<Nachname>' -v admin_email='<login>@dav-leipzig.de' \
--     -f supabase/setup/prod-bootstrap.sql
--
-- Idempotent: mehrfaches Ausführen legt nichts doppelt an (US-AD-01 AK3).
-- Bricht ab, wenn ein Parameter fehlt oder ad_test_login_domains Einträge hat.
-- Legt an: Admin (Mensch) mit Zugang und den Vorlagen Admin und Vorstand; Funktionsperson
-- „Geschäftsstelle / Notfall-Admin“ mit Zugang geschaeftsstelle@dav-leipzig.de und Vorlage Admin.
-- Beide Zugänge bleiben im Status „kein Zugang“; die erste Einladung erfolgt über das Dashboard.

\set ON_ERROR_STOP on

\if :{?admin_first}
\else
  \echo 'Abbruch: Parameter admin_first fehlt (-v admin_first=…).'
  select 1 / 0 as parameter_admin_first_fehlt;
\endif
\if :{?admin_last}
\else
  \echo 'Abbruch: Parameter admin_last fehlt (-v admin_last=…).'
  select 1 / 0 as parameter_admin_last_fehlt;
\endif
\if :{?admin_email}
\else
  \echo 'Abbruch: Parameter admin_email fehlt (-v admin_email=…).'
  select 1 / 0 as parameter_admin_email_fehlt;
\endif

begin;

select set_config('ad_bootstrap.admin_first', :'admin_first', true),
       set_config('ad_bootstrap.admin_last', :'admin_last', true),
       set_config('ad_bootstrap.admin_email', :'admin_email', true);

do $$
declare
  v_first text := btrim(current_setting('ad_bootstrap.admin_first'));
  v_last text := btrim(current_setting('ad_bootstrap.admin_last'));
  v_email extensions.citext := btrim(current_setting('ad_bootstrap.admin_email'))::extensions.citext;
  v_emergency_email constant extensions.citext := 'geschaeftsstelle@dav-leipzig.de';
  v_admin_template uuid;
  v_board_template uuid;
  v_admin_person uuid;
  v_emergency_person uuid;
  v_template record;
begin
  -- Schutz: in PROD gibt es keine Testdomains (spec.md v0.5 T24)
  if exists (select 1 from public.ad_test_login_domains) then
    raise exception 'Abbruch: ad_test_login_domains hat Einträge. In PROD muss die Tabelle leer sein.';
  end if;

  if v_first = '' or v_last = '' or v_email = '' then
    raise exception 'Abbruch: admin_first, admin_last und admin_email dürfen nicht leer sein.';
  end if;

  select id into v_admin_template from public.ad_templates where name = 'Admin';
  select id into v_board_template from public.ad_templates where name = 'Vorstand';
  if v_admin_template is null or v_board_template is null then
    raise exception 'Abbruch: Startvorlagen fehlen. Zuerst die Migrationen ausführen.';
  end if;

  -- Admin (Mensch)
  select person_id into v_admin_person from public.ad_accesses where login_email = v_email;
  if v_admin_person is null then
    insert into public.ea_persons (first_name, last_name, kind)
    values (v_first, v_last, 'human')
    returning id into v_admin_person;

    insert into public.ad_accesses (person_id, login_email)
    values (v_admin_person, v_email);
  end if;

  -- Funktionsperson Geschäftsstelle / Notfall-Admin (R14, R15)
  select person_id into v_emergency_person from public.ad_accesses where login_email = v_emergency_email;
  if v_emergency_person is null then
    insert into public.ea_persons (first_name, last_name, kind)
    values ('Geschäftsstelle', 'Notfall-Admin', 'function')
    returning id into v_emergency_person;

    insert into public.ad_accesses (person_id, login_email, is_emergency)
    values (v_emergency_person, v_emergency_email, true);
  end if;

  -- Zuweisungen, jede genau einmal und protokolliert (R13)
  for v_template in
    select v_admin_person as person_id, v_admin_template as template_id, 'Admin' as name
    union all select v_admin_person, v_board_template, 'Vorstand'
    union all select v_emergency_person, v_admin_template, 'Admin'
  loop
    if not exists (
      select 1 from public.ad_template_assignments
       where person_id = v_template.person_id and template_id = v_template.template_id and revoked_at is null
    ) then
      insert into public.ad_template_assignments (person_id, template_id)
      values (v_template.person_id, v_template.template_id);

      insert into public.ad_audit_log (actor_user_id, subject_person_id, action, details)
      values (null, v_template.person_id, 'template_assigned', v_template.name);
    end if;
  end loop;
end
$$;

commit;

\echo 'Einrichtung abgeschlossen. Nächster Schritt: erste Einladung über das Supabase-Dashboard (supabase/setup/README.md).'
