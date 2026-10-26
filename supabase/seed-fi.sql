-- Testdaten Finanzen (spec.md FI v0.2 Abschnitt 9, FT10) – nur fiktive Daten, nur für vereins-os-test.
-- Wird von supabase/seed.sh nach seed.sql geladen, wenn SEED_WITH_FI=1 gesetzt ist (wie SEED_WITH_EZ; nicht in CI,
-- die pgTAP-Tests legen ihre Daten selbst an). Voraussetzung: seed.sql (Gruppen c…01–c…04, Orte e1…01–03,
-- Kim Kinderjugend). Idempotent. Berechnet keine Abrechnungen: Das macht die Geschäftsstelle in der Oberfläche
-- („1. Halbjahr 2026 berechnen“). IBAN nur die Beispiel-IBAN.
--
-- Personen a…601–606 (Abrechnung), a…607 Lea Leistung (Referent:in Leistungssport), a…608 Gerd Geschäftsstelle
-- (zweite Person der Geschäftsstelle, schließt nach einer Vertretung ab). Einsätze f61…01–09 im 1. Halbjahr 2026.
-- Erwartete Beträge nach der Berechnung: Clara Ablauf 150 €, Hans Helfer 92 €, Ben Lizenzneu 24 €, Olga Ohnebank 0 €
-- (ohne Trainingszeit, ohne Bankverbindung), Tina Trainerin 141 €, Paul Zweigruppen 42 € (zwei Referate).
select set_config('request.jwt.claims', json_build_object('sub', 'b0000000-0000-4000-8000-000000000002', 'role', 'authenticated')::text, false);

-- Personen
insert into public.ea_persons (id, first_name, last_name, kind, created_in, volunteer_status, volunteer_status_since) values
  ('a0000000-0000-4000-8000-000000000601', 'Tina', 'Trainerin', 'human', 'EA', 'active', date '2024-01-01'),
  ('a0000000-0000-4000-8000-000000000602', 'Ben', 'Lizenzneu', 'human', 'EA', 'active', date '2024-01-01'),
  ('a0000000-0000-4000-8000-000000000603', 'Clara', 'Ablauf', 'human', 'EA', 'active', date '2024-01-01'),
  ('a0000000-0000-4000-8000-000000000604', 'Hans', 'Helfer', 'human', 'EA', 'active', date '2024-01-01'),
  ('a0000000-0000-4000-8000-000000000605', 'Olga', 'Ohnebank', 'human', 'EA', 'active', date '2024-01-01'),
  ('a0000000-0000-4000-8000-000000000606', 'Paul', 'Zweigruppen', 'human', 'EA', 'active', date '2024-01-01'),
  ('a0000000-0000-4000-8000-000000000607', 'Lea', 'Leistung', 'human', 'AD', null, null),
  ('a0000000-0000-4000-8000-000000000608', 'Gerd', 'Geschäftsstelle', 'human', 'AD', null, null)
on conflict (id) do nothing;

insert into public.ea_volunteer_status_history (person_id, status, valid_from)
select p.id, p.volunteer_status, p.volunteer_status_since
  from public.ea_persons p
 where p.id in (select ('a0000000-0000-4000-8000-000000000' || n)::uuid from generate_series(601, 606) n)
   and not exists (select 1 from public.ea_volunteer_status_history h where h.person_id = p.id);

-- Lizenzen (TCSPI, DOSB-lizenzfähig): 601 bis 2027, 602 erworben 15.05.2026, 603 bis 31.03.2026, 606 bis 2027
insert into public.ea_properties (id, person_id, property_type_id, field_values, valid_from)
select ('f7100000-0000-4000-8000-000000000' || v.n)::uuid, ('a0000000-0000-4000-8000-000000000' || v.n)::uuid, t.id,
       jsonb_build_object('qualification_type', (select q.id from public.ad_qualification_types q where q.code = 'TCSPI'),
                          'valid_until', v.until),
       v.since
  from (values (601, date '2024-01-01', '2027-12-31'), (602, date '2026-05-15', '2030-12-31'),
               (603, date '2020-01-01', '2026-03-31'), (606, date '2024-01-01', '2027-12-31')) as v (n, since, until)
  join public.ea_property_types t on t.system_key = 'license'
on conflict (id) do nothing;

-- Bankverbindung (nicht 605), Trainervereinbarung, Bestätigung steuerfreie Einnahmen 2026
insert into public.ea_properties (id, person_id, property_type_id, field_values, valid_from)
select ('f7200000-0000-4000-8000-000000000' || n)::uuid, p.id, t.id,
       jsonb_build_object('account_holder', p.first_name || ' ' || p.last_name, 'iban', 'DE89370400440532013000'),
       date '2025-01-01'
  from unnest(array[601, 602, 603, 604, 606]) as n
  join public.ea_persons p on p.id = ('a0000000-0000-4000-8000-000000000' || n)::uuid
  join public.ea_property_types t on t.system_key = 'bank_account'
on conflict (id) do nothing;
insert into public.ea_properties (id, person_id, property_type_id, field_values, valid_from)
select ('f7300000-0000-4000-8000-000000000' || n)::uuid, ('a0000000-0000-4000-8000-000000000' || n)::uuid, t.id,
       '{"signed": true}', date '2025-01-01'
  from generate_series(601, 606) as n join public.ea_property_types t on t.system_key = 'trainer_agreement'
on conflict (id) do nothing;
insert into public.ea_properties (id, person_id, property_type_id, field_values, valid_from)
select ('f7400000-0000-4000-8000-000000000' || n)::uuid, ('a0000000-0000-4000-8000-000000000' || n)::uuid, t.id,
       '{"year": 2026}', date '2026-01-10'
  from generate_series(601, 606) as n join public.ea_property_types t on t.system_key = 'tax_free_confirmation'
on conflict (id) do nothing;

-- Leistungsgruppe Test (Leistungssport), Trainingszeit Di 16:00–18:00
insert into public.gr_groups (id, name, referat_id)
select 'c0000000-0000-4000-8000-000000000605', 'Leistungsgruppe Test', r.id
  from public.ea_referate r where r.name = 'Leistungssport'
on conflict (id) do nothing;
insert into public.gr_training_times (id, group_id, weekday, starts_at, ends_at, valid_from) values
  ('c1000000-0000-4000-8000-000000000605', 'c0000000-0000-4000-8000-000000000605', 2, '16:00', '18:00', date '2025-01-01')
on conflict (id) do nothing;

-- Einsätze im 1. Halbjahr 2026 (Jugendgruppe Test 1: Di 16:30–18:00, Do 17:00–18:30 aus seed.sql)
insert into public.ez_events (id, kind, span, referat_id, group_id, title, organizer_person_id, start_date, start_time,
                              end_date, end_time, day_category, location_id, client_request_id, remuneration_kind_id)
select ('f6100000-0000-4000-8000-0000000000' || lpad(v.n::text, 2, '0'))::uuid, v.kind::public.ez_event_kind,
       v.span::public.ez_span, r.id, v.grp, v.title, v.org, v.d1, v.t1, v.d2, v.t2, v.cat::public.ez_day_category, v.loc,
       ('f6200000-0000-4000-8000-0000000000' || lpad(v.n::text, 2, '0'))::uuid, k.id
  from (values
    (1, 'training', 'single', 'c0000000-0000-4000-8000-000000000001'::uuid, null::text, null::uuid, date '2026-03-03',
     null::time, null::date, null::time, null::text, 'e1000000-0000-4000-8000-000000000002'::uuid, 'TRAINING'),
    (2, 'training', 'single', 'c0000000-0000-4000-8000-000000000001', null, null, date '2026-04-14', null, null, null, null,
     'e1000000-0000-4000-8000-000000000002', 'TRAINING'),
    (3, 'training', 'single', 'c0000000-0000-4000-8000-000000000605', null, null, date '2026-04-14', null, null, null, null,
     'e1000000-0000-4000-8000-000000000002', 'TRAINING'),
    (4, 'training', 'single', 'c0000000-0000-4000-8000-000000000001', null, null, date '2026-05-14', null, null, null, null,
     'e1000000-0000-4000-8000-000000000002', 'TRAINING'),
    (5, 'multi_day_trip', 'multi', 'c0000000-0000-4000-8000-000000000001', 'Ostern Test',
     'a0000000-0000-4000-8000-000000000603'::uuid, date '2026-03-30', null, date '2026-04-01', null, null, null, 'TRIP'),
    (6, 'competition', 'multi', 'c0000000-0000-4000-8000-000000000001', 'Jugendcup Test', null, date '2026-06-13', null,
     date '2026-06-14', null, null, null, 'COMPETITION'),
    (7, 'training', 'single', 'c0000000-0000-4000-8000-000000000001', null, null, date '2026-03-04', null, null, null, null,
     'e1000000-0000-4000-8000-000000000002', 'TRAINING'),
    (8, 'training', 'single', 'c0000000-0000-4000-8000-000000000003', null, null, date '2026-03-03', null, null, null, null,
     'e1000000-0000-4000-8000-000000000002', 'TRAINING'),
    (9, 'multi_day_trip', 'multi', 'c0000000-0000-4000-8000-000000000001', 'Mai Test',
     'a0000000-0000-4000-8000-000000000601', date '2026-05-01', '16:00', date '2026-05-03', '06:00', null, null, 'TRIP')
  ) as v (n, kind, span, grp, title, org, d1, t1, d2, t2, cat, loc, rem)
  join public.gr_groups g on g.id = v.grp
  join public.ea_referate r on r.id = g.referat_id
  join public.ad_remuneration_kinds k on k.code = v.rem
on conflict (id) do nothing;

insert into public.ez_attendances (event_id, person_id, role, status)
select ('f6100000-0000-4000-8000-0000000000' || lpad(v.e::text, 2, '0'))::uuid,
       ('a0000000-0000-4000-8000-000000000' || v.p)::uuid, v.r::public.ez_role, 'present'
  from (values (1, 601, 'trainer'), (1, 603, 'trainer'), (1, 604, 'helper'), (2, 601, 'trainer'), (2, 603, 'trainer'),
               (3, 602, 'trainer'), (3, 606, 'trainer'), (4, 606, 'trainer'), (5, 603, 'trainer'), (6, 604, 'helper'),
               (7, 605, 'helper'), (8, 601, 'trainer'), (9, 601, 'trainer')) as v (e, p, r)
on conflict (event_id, person_id) do nothing;

-- Angaben der Sektion (auch in seed.sql; hier, falls seed.sql vor dem Nachtrag v0.10 lief)
insert into public.ad_payout_settings (debtor_name, iban, bic, ledger_account, valid_from)
select 'Sektion Test', 'DE89370400440532013000', 'TESTDEFFXXX', '0000 0', date '2026-01-01'
 where not exists (select 1 from public.ad_payout_settings s where s.valid_from = date '2026-01-01');

-- Testzugänge Lea Leistung (Referent:in, Referat Leistungssport) und Gerd Geschäftsstelle (Geschäftsstelle)
insert into public.ad_accesses (person_id, login_email, status, is_emergency, last_invited_at, locked_at) values
  ('a0000000-0000-4000-8000-000000000607', 'test.leistung@dav-leipzig.de', 'active', false, now() - interval '30 days', null),
  ('a0000000-0000-4000-8000-000000000608', 'test.geschaeftsstelle2@dav-leipzig.de', 'active', false, now() - interval '30 days', null)
on conflict (person_id) do nothing;

insert into public.ad_template_assignments (person_id, template_id)
select v.person_id, t.id
  from (values ('a0000000-0000-4000-8000-000000000607'::uuid, 'Referent:in'),
               ('a0000000-0000-4000-8000-000000000608', 'Geschäftsstelle')) as v (person_id, template)
  join public.ad_templates t on t.name = v.template
 where not exists (select 1 from public.ad_template_assignments ta
                    where ta.person_id = v.person_id and ta.template_id = t.id and ta.revoked_at is null);

insert into public.ad_assignment_referate (assignment_id, referat_id)
select ta.id, r.id
  from public.ad_template_assignments ta
  join public.ad_templates t on t.id = ta.template_id and t.name = 'Referent:in'
  join public.ea_referate r on r.name = 'Leistungssport'
 where ta.person_id = 'a0000000-0000-4000-8000-000000000607' and ta.revoked_at is null
on conflict do nothing;

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, invited_at, banned_until,
  raw_app_meta_data, raw_user_meta_data,
  confirmation_token, recovery_token, email_change_token_new, email_change,
  created_at, updated_at
)
select '00000000-0000-0000-0000-000000000000', v.id, 'authenticated', 'authenticated',
       v.email, extensions.crypt(:'test_password', extensions.gen_salt('bf')),
       now(), now() - interval '30 days', null,
       '{"provider": "email", "providers": ["email"]}'::jsonb, '{}'::jsonb,
       '', '', '', '',
       now() - interval '30 days', now()
  from (values ('b0000000-0000-4000-8000-000000000607'::uuid, 'test.leistung@dav-leipzig.de'),
               ('b0000000-0000-4000-8000-000000000608', 'test.geschaeftsstelle2@dav-leipzig.de')) as v (id, email)
on conflict (id) do nothing;

insert into auth.identities (id, user_id, provider_id, provider, identity_data, last_sign_in_at, created_at, updated_at)
select gen_random_uuid(), u.id, u.id::text, 'email',
       jsonb_build_object('sub', u.id::text, 'email', u.email, 'email_verified', true),
       null, now(), now()
  from auth.users u
 where u.id in ('b0000000-0000-4000-8000-000000000607', 'b0000000-0000-4000-8000-000000000608')
on conflict (provider_id, provider) do nothing;

select set_config('request.jwt.claims', '', false);
