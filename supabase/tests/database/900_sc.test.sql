-- Schnittstellen-Connector (spec.md SC v0.2, T10): Struktur, Rechte (R17), Anbindung und Key (R3, R4, R11), Freigaben (R2),
-- Vorlagen (R8, R9), Postausgang (R5, R10), Versand (R7, R13), Test-E-Mail, Notfall-Admin (US-SC-14), Jobs (R6, R12).
-- Seed: b…01/a…01 Admin, b…02/a…02 Geschäftsstelle, b…08/a…08 Notfall-Admin, b…09/a…09 Referent:in,
-- a…10 Karl Zweireferat (ohne Zugang, ohne Kontakt-E-Mail), a…12 Paul Nurgruppe (Kontakt-E-Mail, ohne Zugang).
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

create function pg_temp.as_user(p_user uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', p_user, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
end $$;
create function pg_temp.as_owner() returns void language plpgsql as $$
begin
  execute 'reset role';
  perform set_config('request.jwt.claims', '', true);
end $$;

-- Struktur, RLS, Grants
select ok((select bool_and(c.relrowsecurity) from pg_class c
            where c.relnamespace = 'public'::regnamespace
              and c.relname in ('sc_connections', 'sc_connection_modules', 'sc_mail_occasions', 'sc_outbox', 'sc_log')),
  'RLS auf allen Tabellen des SC');
select ok(not has_table_privilege('anon', 'public.sc_connections', 'SELECT'), 'anon liest keine Anbindungen');
select ok(not has_table_privilege('authenticated', 'public.sc_connections', 'INSERT'), 'kein direktes Anlegen');
select ok(not has_table_privilege('authenticated', 'public.sc_outbox', 'UPDATE'), 'kein direktes Ändern im Postausgang');
select ok(not has_column_privilege('authenticated', 'public.sc_outbox', 'body', 'SELECT'), 'Text einer E-Mail nicht lesbar');
select ok(not has_column_privilege('authenticated', 'public.sc_outbox', 'subject', 'SELECT'), 'Betreff nicht lesbar');
select ok(not has_column_privilege('authenticated', 'public.sc_mail_occasions', 'body', 'SELECT'), 'Vorlagentext nicht lesbar');
select ok(has_column_privilege('authenticated', 'public.sc_outbox', 'recipient_email', 'SELECT'), 'Empfänger lesbar');
select ok(not has_function_privilege('authenticated', 'public.sc_mail_enqueue(text, uuid, jsonb, text)', 'EXECUTE'),
  'sc_mail_enqueue nur aus Datenbankfunktionen');
select ok(not has_function_privilege('authenticated', 'public.sc_connection_key(uuid)', 'EXECUTE'), 'Key nicht für Nutzer');
select ok(has_function_privilege('service_role', 'public.sc_connection_key(uuid)', 'EXECUTE'), 'Key für die Edge Function');
select ok(not has_function_privilege('authenticated', 'public.sc_claim(int)', 'EXECUTE'), 'sc_claim nur service_role');
select ok(not has_function_privilege('anon', 'public.sc_status()', 'EXECUTE'), 'anon: keine Hinweise');
select ok(not exists (select 1 from information_schema.columns where table_schema = 'public'
                         and table_name = 'sc_connections' and column_name ~ '(secret|key)$'),
  'keine Spalte für Key oder Secret');

-- Startwerte (Erhebung E1)
select results_eq(
  $$ select t.name, r.level::text from public.ad_template_rights r join public.ad_templates t on t.id = r.template_id
      where r.module_code = 'SC' and r.level <> 'none' order by t.name $$,
  $$ values ('Admin'::text, 'manage'::text), ('Geschäftsstelle', 'read') $$,
  'Startwerte SC: Admin verwalten, Geschäftsstelle lesen');
select is((select name from public.ad_modules where code = 'SC'), 'Schnittstellen', 'Name in der Oberfläche (Q-SC1)');
select results_eq($$ select code from public.sc_mail_occasions order by code $$,
  $$ values ('ad_emergency_login'::text), ('sc_key_expiry'), ('sc_test') $$, 'Anlässe des MVP (E3)');

-- Rechte: Referent:in und Geschäftsstelle (R17)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select throws_ok($$ select public.sc_save_connection(null, 'email_brevo', 'X', 'x@example.org', 'X', null) $$,
  'P0001', 'SC_FORBIDDEN', 'Referent:in legt keine Anbindung an');
select is((select count(*)::int from public.sc_mail_occasions), 0, 'Referent:in sieht keine Anlässe');
select is((select count(*)::int from public.sc_status()), 0, 'Referent:in: keine Hinweise');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select throws_ok($$ select public.sc_save_connection(null, 'email_brevo', 'X', 'x@example.org', 'X', null) $$,
  'P0001', 'SC_FORBIDDEN', 'Geschäftsstelle legt keine Anbindung an');
select throws_ok($$ select * from public.sc_occasion_texts() $$, 'P0001', 'SC_FORBIDDEN',
  'Geschäftsstelle liest keine Vorlagentexte');
select is((select count(*)::int from public.sc_mail_occasions), 3, 'Geschäftsstelle sieht die Anlässe');

-- Anbindung anlegen (US-SC-02)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select throws_ok($$ select public.sc_save_connection(null, 'email_brevo', 'E-Mail', 'keine-adresse', 'Vereins OS', null) $$,
  'P0001', 'SC_EMAIL_INVALID', 'ungültige Absenderadresse');
select throws_ok($$ select public.sc_save_connection(null, 'email_brevo', 'E-Mail', 'a@example.org', 'Vereins OS', null, 100, 301) $$,
  'P0001', 'SC_LIMIT_INVALID', 'Tageslimit höchstens 300 (R13)');
create temp table conn on commit drop as
  select public.sc_save_connection(null, 'email_brevo', 'E-Mail Test', 'vereinsos.test@example.org', 'Vereins OS (TEST)',
                                   null, 100, 300) as id;
grant select on conn to authenticated;
select results_eq($$ select state::text, key_last4 from public.sc_connections where id = (select id from conn) $$,
  $$ values ('disabled'::text, null::text) $$, 'neu: abgeschaltet, ohne Key');
select throws_ok($$ select public.sc_save_connection(null, 'email_brevo', 'e-mail test', 'b@example.org', 'X', null) $$,
  'P0001', 'SC_NAME_TAKEN', 'Name eindeutig');

-- Aktivieren ohne Key bzw. ohne Test (R3)
select throws_ok($$ select public.sc_set_state((select id from conn), 'active') $$, 'P0001', 'SC_KEY_MISSING',
  'aktivieren ohne Key');
select throws_ok($$ select public.sc_set_key((select id from conn), 'kurz', null) $$, 'P0001', 'SC_KEY_INVALID',
  'Key zu kurz');
select lives_ok($$ select public.sc_set_key((select id from conn), 'xkeysib-geheim-0000k3x9', null) $$, 'Key hinterlegen');
select is((select key_last4 from public.sc_connections where id = (select id from conn)), 'k3x9', 'nur die letzten 4 Zeichen (R11)');
select throws_ok($$ select public.sc_set_state((select id from conn), 'active') $$, 'P0001', 'SC_TEST_REQUIRED',
  'aktivieren ohne erfolgreichen Test (R3)');
select is((select count(*)::int from public.sc_log where kind = 'key_changed' and message like '%geheim%'), 0,
  'Key nicht im Protokoll');

-- Module freigeben (US-SC-06)
select throws_ok($$ select public.sc_set_modules((select id from conn), '{AD,XX}') $$, 'P0001', 'SC_MODULE_UNKNOWN',
  'unbekanntes Modul');
select lives_ok($$ select public.sc_set_modules((select id from conn), '{SC,AD}') $$, 'AD und SC freigeben');
select results_eq($$ select module_code from public.sc_connection_modules where connection_id = (select id from conn)
                     order by module_code $$, $$ values ('AD'::text), ('SC') $$, 'Freigaben gespeichert');

-- Test-E-Mail (service_role bzw. Eigentümer)
select pg_temp.as_owner();
select ok(public.sc_vault_get('sc_connection_' || (select id from conn)) = 'xkeysib-geheim-0000k3x9', 'Key liegt in Vault');
select throws_ok($$ select * from public.sc_test_prepare((select id from conn), 'b0000000-0000-4000-8000-000000000002') $$,
  'P0001', 'SC_FORBIDDEN', 'Test nur mit SC ≥ bearbeiten');
select results_eq($$ select recipient_email, sender_email from public.sc_test_prepare((select id from conn),
                     'b0000000-0000-4000-8000-000000000001') $$,
  $$ values ('test.admin@dav-leipzig.de'::text, 'vereinsos.test@example.org'::text) $$, 'Test an die eigene Login-Adresse');
select ok((select body from public.sc_test_prepare((select id from conn), 'b0000000-0000-4000-8000-000000000001'))
            like '%http://localhost:5173/schnittstellen%', 'Link mit Adresse der Umgebung (A6)');
select lives_ok($$ select public.sc_test_report((select id from conn), 'b0000000-0000-4000-8000-000000000001', false,
                   'Key not found') $$, 'Test fehlgeschlagen');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select throws_ok($$ select public.sc_set_state((select id from conn), 'active') $$, 'P0001', 'SC_TEST_REQUIRED',
  'nach fehlgeschlagenem Test nicht aktivierbar');
select pg_temp.as_owner();
select lives_ok($$ select public.sc_test_report((select id from conn), 'b0000000-0000-4000-8000-000000000001', true, null) $$,
  'Test erfolgreich');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select lives_ok($$ select public.sc_set_state((select id from conn), 'active') $$, 'aktivieren nach Test');

-- R4: zweite Anbindung nicht aktivierbar
create temp table conn2 on commit drop as
  select public.sc_save_connection(null, 'email_brevo', 'E-Mail Zwei', 'zwei@example.org', 'Vereins OS', null) as id;
select lives_ok($$ select public.sc_set_key((select id from conn2), 'zweiter-key-1234', null) $$, 'Key zweite Anbindung');
select pg_temp.as_owner();
select lives_ok($$ select public.sc_test_report((select id from conn2), 'b0000000-0000-4000-8000-000000000001', true, null) $$,
  'Test zweite Anbindung');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select throws_ok($$ select public.sc_set_state((select id from conn2), 'active') $$, 'P0001', 'SC_ALREADY_ACTIVE', 'R4');

-- Vorlagen (US-SC-07)
select throws_ok($$ select public.sc_save_occasion('ad_emergency_login', 'Hallo {vorname}', 'Text {link}') $$,
  'P0001', 'SC_PLACEHOLDER_UNKNOWN', 'nicht erlaubter Platzhalter (R8, R9)');
select throws_ok($$ select public.sc_save_occasion('ad_emergency_login', repeat('x', 151), 'Text') $$,
  'P0001', 'SC_TOO_LONG', 'Betreff höchstens 150 Zeichen');
select lives_ok($$ select public.sc_save_occasion('ad_emergency_login', 'Notfall-Admin angemeldet',
                   e'Hallo,\nAnmeldung am {zeitpunkt}.\n{link}') $$, 'Vorlage speichern');
select is((select body from public.sc_preview_occasion('ad_emergency_login', 'B', 'Am {zeitpunkt}: {link}')),
  'Am 27.10.2026 10:15: http://localhost:5173/ad/protokoll', 'Vorschau mit Beispielwerten');

-- Postausgang (US-SC-08)
select pg_temp.as_owner();
select throws_ok($$ select public.sc_mail_enqueue('ea_unbekannt', 'a0000000-0000-4000-8000-000000000001', '{}', 'k0') $$,
  'P0001', 'SC_OCCASION_UNKNOWN', 'unbekannter Anlass');
create temp table m1 on commit drop as
  select public.sc_mail_enqueue('ad_emergency_login', 'a0000000-0000-4000-8000-000000000001',
                                '{"zeitpunkt": "01.11.2026 08:00"}', 'test:1') as id;
select results_eq($$ select recipient_email::text, state::text, module_code from public.sc_outbox where id = (select id from m1) $$,
  $$ values ('test.admin@dav-leipzig.de'::text, 'waiting'::text, 'AD'::text) $$, 'Login-Adresse bei aktivem Zugang (R5)');
select ok((select body from public.sc_outbox where id = (select id from m1)) like '%01.11.2026 08:00%', 'Platzhalter ersetzt');
select is(public.sc_mail_enqueue('ad_emergency_login', 'a0000000-0000-4000-8000-000000000001', '{}', 'test:1'),
  (select id from m1), 'gleicher Schlüssel: keine zweite E-Mail (R10)');
create temp table m2 on commit drop as
  select public.sc_mail_enqueue('ad_emergency_login', 'a0000000-0000-4000-8000-000000000012', '{}', 'test:2') as id;
select is((select recipient_email::text from public.sc_outbox where id = (select id from m2)),
  'paul.nurgruppe@example.test', 'ohne Zugang: Kontakt-E-Mail (R5)');
select throws_ok($$ select public.sc_mail_enqueue('ad_emergency_login', 'a0000000-0000-4000-8000-000000000010', '{}', 'test:3') $$,
  'P0001', 'SC_NO_EMAIL', 'ohne Adresse (R5)');
select throws_ok($$ select public.sc_mail_enqueue('ad_emergency_login', 'a0000000-0000-4000-8000-000000000001',
                    '{"vorname": "Test"}', 'test:4') $$, 'P0001', 'SC_PLACEHOLDER_UNKNOWN', 'kein Platzhalter für Namen (R8)');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select lives_ok($$ select public.sc_set_modules((select id from conn), '{SC}') $$, 'Freigabe AD zurücknehmen');
select pg_temp.as_owner();
select throws_ok($$ select public.sc_mail_enqueue('ad_emergency_login', 'a0000000-0000-4000-8000-000000000001', '{}', 'test:5') $$,
  'P0001', 'SC_MODULE_NOT_ALLOWED', 'Modul nicht freigegeben (R2)');
select is(public.sc_mail_try_enqueue('ad_emergency_login', 'a0000000-0000-4000-8000-000000000001', '{}', 'test:6'), null,
  'ohne Fehler, aber abgelehnt');
select ok(exists (select 1 from public.sc_log where kind = 'enqueue_rejected' and message like 'ad_emergency_login: SC_MODULE_NOT_ALLOWED%'),
  'Ablehnung im Protokoll');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select lives_ok($$ select public.sc_set_modules((select id from conn), '{SC,AD}') $$, 'AD wieder freigeben');
select pg_temp.as_owner();

-- Notfall-Admin meldet sich an (US-SC-14)
update auth.users set last_sign_in_at = now() where id = 'b0000000-0000-4000-8000-000000000008';
select results_eq(
  $$ select recipient_email::text from public.sc_outbox where occasion_code = 'ad_emergency_login'
      and dedupe_key like 'ad_emergency_login:%' order by 1 $$,
  $$ values ('test.admin@dav-leipzig.de'::text) $$, 'E-Mail an den Admin, nicht an den Notfall-Admin selbst (AK1, AK2)');
select ok((select body from public.sc_outbox where dedupe_key like 'ad_emergency_login:%') !~ 'Notfall-Admin Geschäftsstelle',
  'kein Name in der E-Mail (R8)');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select lives_ok($$ select public.sc_set_modules((select id from conn), '{SC}') $$, 'AD nicht freigegeben');
select pg_temp.as_owner();
select lives_ok($$ update auth.users set last_sign_in_at = now() + interval '1 minute'
                    where id = 'b0000000-0000-4000-8000-000000000008' $$, 'Anmeldung scheitert nicht (AK3)');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select lives_ok($$ select public.sc_set_modules((select id from conn), '{SC,AD}') $$, 'AD wieder freigeben');
select pg_temp.as_owner();

-- Versand (US-SC-09): Sperre, Fehler, Wiederholung, Störung
update public.sc_outbox set created_at = now() - interval '1 minute' where id = (select id from m1);
select is((select count(*)::int from public.sc_claim(20)), 3, 'drei fällige E-Mails geholt');
select is((select count(*)::int from public.sc_claim(20)), 0, 'gesperrte E-Mails nicht doppelt');
select lives_ok($$ select public.sc_report((select id from m1), true, null, null, '<msg-1@brevo>') $$, 'Erfolg melden');
select results_eq($$ select state::text, provider_message_id from public.sc_outbox where id = (select id from m1) $$,
  $$ values ('sent'::text, '<msg-1@brevo>'::text) $$, 'versendet');
select lives_ok($$ select public.sc_report((select id from m2), false, 'server', 'Zeitüberschreitung', null) $$, 'Fehler 1');
select results_eq($$ select state::text, attempts, last_error,
                     next_attempt_at between now() + interval '14 minutes' and now() + interval '16 minutes'
                     from public.sc_outbox where id = (select id from m2) $$,
  $$ values ('waiting'::text, 1, 'Zeitüberschreitung'::text, true) $$, 'nächster Versuch nach 15 Minuten (R7)');
update public.sc_outbox set next_attempt_at = now() - interval '1 second' where id = (select id from m2);
select is((select count(*)::int from public.sc_claim(20)), 1, 'Versuch 2 geholt');
select lives_ok($$ select public.sc_report((select id from m2), false, 'server', 'Zeitüberschreitung', null) $$, 'Fehler 2');
select ok((select next_attempt_at > now() + interval '59 minutes' from public.sc_outbox where id = (select id from m2)),
  'dann nach 1 Stunde (R7)');
update public.sc_outbox set next_attempt_at = now() - interval '1 second' where id = (select id from m2);
select is((select count(*)::int from public.sc_claim(20)), 1, 'Versuch 3 geholt');
select lives_ok($$ select public.sc_report((select id from m2), false, 'server', 'Zeitüberschreitung', null) $$, 'Fehler 3');
select is((select state::text from public.sc_outbox where id = (select id from m2)), 'failed', 'nach 3 Versuchen fehlgeschlagen');
select is((select state::text from public.sc_connections where id = (select id from conn)), 'disturbed',
  '3 Fehler in Folge: gestört (R7)');
select is((select count(*)::int from public.sc_claim(20)), 0, 'gestört: kein Versand');

-- Admin: erneut senden, verwerfen, Inhalt; Geschäftsstelle nicht (US-SC-10)
grant select on m1, m2 to authenticated;
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select throws_ok($$ select public.sc_outbox_retry((select id from m2)) $$, 'P0001', 'SC_FORBIDDEN', 'Geschäftsstelle: kein erneutes Senden');
select throws_ok($$ select * from public.sc_outbox_content((select id from m2)) $$, 'P0001', 'SC_FORBIDDEN',
  'Geschäftsstelle: kein Inhalt (E1)');
select is((select count(*)::int from public.sc_outbox where id = (select id from m2)), 1, 'Geschäftsstelle sieht die E-Mail');
select ok(exists (select 1 from public.sc_status() where kind = 'disturbed'), 'Hinweis „gestört“ (US-SC-13)');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select lives_ok($$ select public.sc_outbox_retry((select id from m2)) $$, 'Admin: erneut senden');
select results_eq($$ select state::text, attempts from public.sc_outbox where id = (select id from m2) $$,
  $$ values ('waiting'::text, 0) $$, 'wieder wartend mit 0 Versuchen');
select throws_ok($$ select public.sc_outbox_retry((select id from m1)) $$, 'P0001', 'SC_OUTBOX_STATE', 'versendet: kein erneutes Senden');
select throws_ok($$ select public.sc_outbox_discard((select id from m1)) $$, 'P0001', 'SC_OUTBOX_STATE', 'versendet: nicht verwerfen');
select is((select subject from public.sc_outbox_content((select id from m1))), 'Notfall-Admin angemeldet', 'Admin liest den Inhalt');

-- Neuer Key bei aktiver Anbindung: gestört bis zum Test (A3)
select pg_temp.as_owner();
select lives_ok($$ select public.sc_test_report((select id from conn), 'b0000000-0000-4000-8000-000000000001', true, null) $$,
  'Test nach Störung');
select is((select state::text from public.sc_connections where id = (select id from conn)), 'active', 'wieder aktiv');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select lives_ok($$ select public.sc_set_key((select id from conn), 'xkeysib-neu-0000abcd', null) $$, 'Key wechseln');
select is((select state::text from public.sc_connections where id = (select id from conn)), 'disturbed', 'gestört bis zum Test (A3)');
select pg_temp.as_owner();
select ok(public.sc_vault_get('sc_connection_' || (select id from conn)) = 'xkeysib-neu-0000abcd', 'alter Key überschrieben');
select lives_ok($$ select public.sc_test_report((select id from conn), 'b0000000-0000-4000-8000-000000000001', true, null) $$,
  'Test mit neuem Key');

-- Grenzen (R13)
update public.sc_connections set daily_limit = 2 where id = (select id from conn);
insert into public.sc_outbox (occasion_code, module_code, recipient_person_id, recipient_email, subject, body, dedupe_key,
                              state, sent_at, connection_id)
values ('sc_test', 'SC', 'a0000000-0000-4000-8000-000000000001', 'test.admin@dav-leipzig.de', 'S', 'B', 'limit:1',
        'sent', now(), (select id from conn));
select is((select count(*)::int from public.sc_claim(20)), 0, 'Tageslimit erreicht: nichts geholt');
select ok(exists (select 1 from public.sc_log where kind = 'limit_reached' and message like 'Tageslimit%'), 'Limit im Protokoll');
update public.sc_connections set daily_limit = 300 where id = (select id from conn);

-- Versand-Job: ohne Vault-Einträge kein Aufruf; mit Einträgen ein Aufruf
select lives_ok($$ select public.sc_dispatch() $$, 'Job ohne Vault-Einträge');
select vault.create_secret('https://example.test/functions/v1/sc-send', 'sc_dispatch_url');
select vault.create_secret('dispatch-geheim', 'sc_dispatch_secret');
select ok(public.sc_check_dispatch_secret('dispatch-geheim'), 'Geheimnis passt');
select ok(not public.sc_check_dispatch_secret('falsch'), 'falsches Geheimnis');
select ok(not public.sc_check_dispatch_secret(''), 'leeres Geheimnis');

select results_eq($$ select jobname, schedule from cron.job where jobname like 'sc-%' order by jobname $$,
  $$ values ('sc-daily'::text, '40 2 * * *'::text), ('sc-dispatch', '*/5 * * * *') $$, 'Jobs geplant (T8)');

-- Täglicher Job (R6, R12)
update public.sc_connections set key_expires_on = (now() at time zone 'Europe/Berlin')::date + 30 where id = (select id from conn);
select lives_ok($$ select public.sc_daily() $$, 'täglicher Job');
select results_eq($$ select recipient_email::text from public.sc_outbox where occasion_code = 'sc_key_expiry' order by 1 $$,
  $$ values ('test.admin@dav-leipzig.de'::text), ('test.notfall@dav-leipzig.de') $$,
  'Erinnerung 30 Tage vorher an alle mit SC verwalten (R6)');
select lives_ok($$ select public.sc_daily() $$, 'Job zweimal am Tag');
select is((select count(*)::int from public.sc_outbox where occasion_code = 'sc_key_expiry'), 2, 'keine doppelte Erinnerung');
update public.sc_connections set key_expires_on = (now() at time zone 'Europe/Berlin')::date where id = (select id from conn);
update public.sc_outbox set created_at = now() - interval '8 days' where dedupe_key = 'test:2';
update public.sc_outbox set state_changed_at = now() - interval '91 days' where id = (select id from m1);
select lives_ok($$ select public.sc_daily() $$, 'täglicher Job (Ablauf)');
select is((select state::text from public.sc_connections where id = (select id from conn)), 'expired', 'abgelaufen (R6)');
select results_eq($$ select state::text, last_error from public.sc_outbox where dedupe_key = 'test:2' $$,
  $$ values ('failed'::text, 'zu alt'::text) $$, 'älter als 7 Tage: zu alt');
select is((select count(*)::int from public.sc_outbox where id = (select id from m1)), 0, 'nach 90 Tagen gelöscht (R12)');

-- Abschalten (US-SC-05)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select lives_ok($$ select public.sc_set_state((select id from conn), 'disabled') $$, 'abschalten');
select throws_ok($$ select public.sc_set_state((select id from conn), 'disturbed') $$, 'P0001', 'SC_STATE_INVALID',
  'nur aktiv oder abgeschaltet');

select * from finish();
rollback;
