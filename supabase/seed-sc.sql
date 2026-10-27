-- Testdaten des Schnittstellen-Connectors (spec.md SC v0.2 Abschnitt 9, T12). Nur fiktiv, nur TEST, nicht in CI
-- (die pgTAP-Tests legen ihre Daten selbst an). Aufruf über supabase/seed.sh mit SEED_WITH_SC=1 nach seed.sql.
-- Kein Key (R14): den TEST-Key von Brevo hinterlegt der Admin in der Oberfläche; danach Test-E-Mail und aktivieren.
-- Idempotent über feste UUIDs.

-- Anbindung 1: abgeschaltet, ohne Key, 50 E-Mails am Tag (TEST teilt sich das Brevo-Konto mit PROD, R13)
insert into public.sc_connections (id, kind, name, state, sender_email, sender_name, hourly_limit, daily_limit, created_by)
values ('f5c00000-0000-4000-8000-000000000001', 'email_brevo', 'E-Mail Test', 'disabled',
        'vereinsos.test@example.org', 'Vereins OS (TEST)', 100, 50, 'b0000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

insert into public.sc_connection_modules (connection_id, module_code, granted_by)
values ('f5c00000-0000-4000-8000-000000000001', 'AD', 'b0000000-0000-4000-8000-000000000001'),
       ('f5c00000-0000-4000-8000-000000000001', 'SC', 'b0000000-0000-4000-8000-000000000001')
on conflict do nothing;

-- Postausgang 2–6 (Empfänger: Testzugang Admin, a…01)
insert into public.sc_outbox (id, occasion_code, module_code, recipient_person_id, recipient_email, subject, body,
                              dedupe_key, state, attempts, next_attempt_at, last_error, connection_id, provider_message_id,
                              created_at, sent_at, state_changed_at)
select v.id, v.occasion, v.module, 'a0000000-0000-4000-8000-000000000001', 'test.admin@dav-leipzig.de',
       o.subject, o.body, 'seed:' || v.id, v.state::public.sc_outbox_state, v.attempts, v.created,
       v.error, 'f5c00000-0000-4000-8000-000000000001', v.provider, v.created,
       case when v.state = 'sent' then v.created + interval '2 minutes' end, v.changed
  from (values
    ('f5c00000-0000-4000-8000-000000000102'::uuid, 'sc_test', 'SC', 'sent', 1, null::text, '<seed-1@brevo.test>',
     now() - interval '2 days', now() - interval '2 days'),
    ('f5c00000-0000-4000-8000-000000000103'::uuid, 'ad_emergency_login', 'AD', 'waiting', 1, 'Zeitüberschreitung', null,
     now() - interval '20 minutes', now() - interval '20 minutes'),
    ('f5c00000-0000-4000-8000-000000000104'::uuid, 'sc_key_expiry', 'SC', 'failed', 3, '401 unauthorized: Key not found', null,
     now() - interval '1 day', now() - interval '22 hours'),
    ('f5c00000-0000-4000-8000-000000000105'::uuid, 'ad_emergency_login', 'AD', 'discarded', 1, 'Zeitüberschreitung', null,
     now() - interval '5 days', now() - interval '4 days'),
    ('f5c00000-0000-4000-8000-000000000106'::uuid, 'sc_test', 'SC', 'sent', 1, null, '<seed-2@brevo.test>',
     now() - interval '95 days', now() - interval '95 days')
  ) as v (id, occasion, module, state, attempts, error, provider, created, changed)
  join public.sc_mail_occasions o on o.code = v.occasion
on conflict (id) do nothing;

-- Protokoll 7
insert into public.sc_log (created_at, connection_id, module_code, actor_user_id, kind, result, message)
select v.at, 'f5c00000-0000-4000-8000-000000000001', v.module, v.actor, v.kind::public.sc_log_kind,
       v.result::public.sc_log_result, v.message
  from (values
    (now() - interval '3 days', null::text, 'b0000000-0000-4000-8000-000000000001'::uuid, 'connection_created', 'ok', 'E-Mail Test'),
    (now() - interval '3 days', null, 'b0000000-0000-4000-8000-000000000001'::uuid, 'modules_changed', 'ok', '– → AD, SC'),
    (now() - interval '3 days', 'SC', 'b0000000-0000-4000-8000-000000000001'::uuid, 'test', 'error', '401 unauthorized: Key not found'),
    (now() - interval '2 days', 'SC', null, 'send', 'ok', 'sc_test'),
    (now() - interval '20 minutes', 'AD', null, 'send', 'error', 'ad_emergency_login: Zeitüberschreitung')
  ) as v (at, module, actor, kind, result, message)
 where not exists (select 1 from public.sc_log l where l.connection_id = 'f5c00000-0000-4000-8000-000000000001');
