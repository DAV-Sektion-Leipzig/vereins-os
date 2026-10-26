-- Finanzen (spec.md FI v0.2, T9 Teil; US-FI-01 bis US-FI-17): ein Abrechnungshalbjahr von der Berechnung bis zur
-- Auszahlungsrunde mit fiktiven Daten (Abschnitt 9 sinngemäß). Alle Namen fiktiv, IBAN nur die Beispiel-IBAN.
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
  perform set_config('request.jwt.claims', json_build_object('sub', 'b0000000-0000-4000-8000-000000000002', 'role', 'authenticated')::text, true);
end $$;
create function pg_temp.p(n int) returns uuid language sql as $$
  select ('a0000000-0000-4000-8000-' || lpad(n::text, 12, '0'))::uuid $$;
create function pg_temp.e(n int) returns uuid language sql as $$
  select ('f6100000-0000-4000-8000-' || lpad(n::text, 12, '0'))::uuid $$;
create temp table ids (name text primary key, id uuid);
grant select, insert on ids to authenticated;
create function pg_temp.id(p_name text) returns uuid language sql as $$ select id from ids where name = p_name $$;
create function pg_temp.sid(n int) returns uuid language sql as $$
  select s.id from public.fi_settlements s where s.person_id = pg_temp.p(n) and s.year = 2026 and s.half = 1 $$;

-- ---------------------------------------------------------------------------------------------------------------
-- Testdaten (als Eigentümer, „erfasst von“ Geschäftsstelle)
select pg_temp.as_owner();
insert into ids select 'KJ', id from public.ea_referate where name = 'Kinder und Jugend';
insert into ids select 'LS', id from public.ea_referate where name = 'Leistungssport';
insert into ids select 'TRAINING', id from public.ad_remuneration_kinds where code = 'TRAINING';
insert into ids select 'TRIP', id from public.ad_remuneration_kinds where code = 'TRIP';
insert into ids select 'COMPETITION', id from public.ad_remuneration_kinds where code = 'COMPETITION';

insert into public.ea_persons (id, first_name, last_name, kind, created_in, volunteer_status, volunteer_status_since)
select pg_temp.p(v.n), v.f, v.l, 'human', 'EA', 'active', date '2024-01-01'
  from (values (601, 'Tina', 'Trainerin'), (602, 'Ben', 'Lizenzneu'), (603, 'Clara', 'Ablauf'), (604, 'Hans', 'Helfer'),
               (605, 'Olga', 'Ohnebank'), (606, 'Paul', 'Zweigruppen')) as v (n, f, l);

-- Lizenzen (TCSPI, DOSB-lizenzfähig): 601 bis 2027, 602 erworben 15.05.2026, 603 bis 31.03.2026, 606 bis 2027
insert into public.ea_properties (person_id, property_type_id, field_values, valid_from)
select pg_temp.p(v.n), t.id,
       jsonb_build_object('qualification_type', (select q.id from public.ad_qualification_types q where q.code = 'TCSPI'),
                          'valid_until', v.until),
       v.since
  from (values (601, date '2024-01-01', '2027-12-31'), (602, date '2026-05-15', '2030-12-31'),
               (603, date '2020-01-01', '2026-03-31'), (606, date '2024-01-01', '2027-12-31')) as v (n, since, until)
  join public.ea_property_types t on t.system_key = 'license';
-- Bankverbindung (nicht 605), Trainervereinbarung und Bestätigung steuerfreie Einnahmen 2026 (alle)
insert into public.ea_properties (person_id, property_type_id, field_values, valid_from)
select pg_temp.p(n), t.id,
       jsonb_build_object('account_holder', p.first_name || ' ' || p.last_name, 'iban', 'DE89370400440532013000'),
       date '2025-01-01'
  from unnest(array[601, 602, 603, 604, 606]) as n
  join public.ea_persons p on p.id = pg_temp.p(n)
  join public.ea_property_types t on t.system_key = 'bank_account';
insert into public.ea_properties (person_id, property_type_id, field_values, valid_from)
select pg_temp.p(n), t.id, '{"signed": true}', date '2025-01-01'
  from generate_series(601, 606) as n join public.ea_property_types t on t.system_key = 'trainer_agreement';
insert into public.ea_properties (person_id, property_type_id, field_values, valid_from)
select pg_temp.p(n), t.id, '{"year": 2026}', date '2026-01-10'
  from generate_series(601, 606) as n join public.ea_property_types t on t.system_key = 'tax_free_confirmation';

-- Leistungsgruppe (Leistungssport) mit Trainingszeit Di 16:00–18:00; Jugendgruppe Test 1: Di 16:30–18:00, Do 17:00–18:30 (Seed)
insert into public.gr_groups (id, name, referat_id) values ('c0000000-0000-4000-8000-000000000605', 'Leistungsgruppe Test', pg_temp.id('LS'));
insert into public.gr_training_times (group_id, weekday, starts_at, ends_at, valid_from)
values ('c0000000-0000-4000-8000-000000000605', 2, '16:00', '18:00', date '2025-01-01');

insert into public.ez_events (id, kind, span, referat_id, group_id, title, organizer_person_id, start_date, start_time,
                              end_date, end_time, day_category, location_id, client_request_id, remuneration_kind_id)
select pg_temp.e(v.n), v.kind::public.ez_event_kind, v.span::public.ez_span, pg_temp.id('KJ'), v.grp, v.title, v.org,
       v.d1, v.t1, v.d2, v.t2, v.cat::public.ez_day_category, v.loc, gen_random_uuid(), pg_temp.id(v.rem)
  from (values
    (1, 'training', 'single', 'c0000000-0000-4000-8000-000000000001'::uuid, null::text, null::uuid, date '2026-03-03', null::time,
     null::date, null::time, null::text, 'e1000000-0000-4000-8000-000000000002'::uuid, 'TRAINING'),
    (2, 'training', 'single', 'c0000000-0000-4000-8000-000000000001', null, null, date '2026-04-14', null, null, null, null,
     'e1000000-0000-4000-8000-000000000002', 'TRAINING'),
    (3, 'training', 'single', 'c0000000-0000-4000-8000-000000000605', null, null, date '2026-04-14', null, null, null, null,
     'e1000000-0000-4000-8000-000000000002', 'TRAINING'),
    (4, 'training', 'single', 'c0000000-0000-4000-8000-000000000001', null, null, date '2026-05-14', null, null, null, null,
     'e1000000-0000-4000-8000-000000000002', 'TRAINING'),
    (5, 'multi_day_trip', 'multi', 'c0000000-0000-4000-8000-000000000001', 'Ostern Test', pg_temp.p(603), date '2026-03-30',
     null, date '2026-04-01', null, null, null, 'TRIP'),
    (6, 'competition', 'multi', 'c0000000-0000-4000-8000-000000000001', 'Jugendcup Test', null, date '2026-06-13', null,
     date '2026-06-14', null, null, null, 'COMPETITION'),
    (7, 'training', 'single', 'c0000000-0000-4000-8000-000000000001', null, null, date '2026-03-04', null, null, null, null,
     'e1000000-0000-4000-8000-000000000002', 'TRAINING'),
    (8, 'training', 'single', 'c0000000-0000-4000-8000-000000000003', null, null, date '2026-03-03', null, null, null, null,
     'e1000000-0000-4000-8000-000000000002', 'TRAINING'),
    (9, 'multi_day_trip', 'multi', 'c0000000-0000-4000-8000-000000000001', 'Mai Test', pg_temp.p(601), date '2026-05-01',
     '16:00', date '2026-05-03', '06:00', null, null, 'TRIP')
  ) as v (n, kind, span, grp, title, org, d1, t1, d2, t2, cat, loc, rem);

insert into public.ez_attendances (event_id, person_id, role, status)
select pg_temp.e(v.e), pg_temp.p(v.p), v.r::public.ez_role, 'present'
  from (values (1, 601, 'trainer'), (1, 603, 'trainer'), (1, 604, 'helper'), (2, 601, 'trainer'), (2, 603, 'trainer'),
               (3, 602, 'trainer'), (3, 606, 'trainer'), (4, 606, 'trainer'), (5, 603, 'trainer'), (6, 604, 'helper'),
               (7, 605, 'helper'), (8, 601, 'trainer'), (9, 601, 'trainer')) as v (e, p, r);

-- Vorstand erhält für den Test „FI verwalten“ (zweite Person zum Abschließen, US-FI-09 AK3)
update public.ad_template_rights r set level = 'manage'
  from public.ad_templates t where r.template_id = t.id and t.name = 'Vorstand' and r.module_code = 'FI';

-- ---------------------------------------------------------------------------------------------------------------
-- Berechnung (US-FI-01 bis -05)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select is((public.fi_calculate_half(2026::smallint, 1::smallint) ->> 'created')::int, 6, 'sechs Abrechnungen angelegt');
select results_eq(
  $$ select p.last_name, s.amount from public.fi_settlements s join public.ea_persons p on p.id = s.person_id
      where s.year = 2026 and s.half = 1 and p.id in (select pg_temp.p(n) from generate_series(601, 606) n)
      order by p.last_name $$,
  $$ values ('Ablauf'::text, 150.00::numeric), ('Helfer', 92.00), ('Lizenzneu', 24.00), ('Ohnebank', 0.00),
            ('Trainerin', 141.00), ('Zweigruppen', 42.00) $$,
  'Beträge nach R3–R8 (Klettern nicht halbjährlich, R2)');
select results_eq(
  format($$ select i.position::text, coalesce(i.recorded_role::text, '-'), i.calc_rate_role::text, i.calc_quantity, i.amount
              from public.fi_settlement_items i where i.settlement_id = %L order by i.event_date, i.position $$, pg_temp.sid(603)),
  $$ values ('training_unit'::text, 'trainer'::text, 'trainer'::text, 3.00::numeric, 18.00::numeric),
            ('day', 'trainer', 'trainer', 3.00, 90.00), ('organization_day', '-', 'none', 3.00, 30.00),
            ('training_unit', 'trainer', 'helper', 3.00, 12.00) $$,
  'Clara: 90 Min. = 3 TE; Fahrt ohne Uhrzeit 3 Tagessätze + Organisation; nach Lizenzablauf Satz Helfer:in (R8)');
select is((select hints from public.fi_settlement_items where settlement_id = pg_temp.sid(603) and event_id = pg_temp.e(2)),
  array['no_license']::public.fi_hint[], 'Hinweis keine förderfähige Lizenz');
select is((select hints from public.fi_settlement_items where settlement_id = pg_temp.sid(603) and event_id = pg_temp.e(5)
             and position = 'day'), array['no_time']::public.fi_hint[], 'Hinweis ohne Uhrzeit (R5)');
select results_eq(
  format($$ select i.position::text, i.calc_quantity from public.fi_settlement_items i
             where i.settlement_id = %L and i.event_id = %L order by i.position $$, pg_temp.sid(601), pg_temp.e(9)),
  $$ values ('day'::text, 2.00::numeric), ('half_day', 1.00), ('organization_day', 3.00) $$,
  'Fahrt Fr 16:00 – So 06:00: 2 Tage + 1 Halbtag + 3 Tage Organisation (R5, R7)');
select is((select calc_rate_role::text from public.fi_settlement_items where settlement_id = pg_temp.sid(602)),
  'trainer', 'Ben: Lizenz im selben Halbjahr erworben → Satz Trainer:in auch vor dem Erwerb (R8)');
select is((select calc_quantity from public.fi_settlement_items where settlement_id = pg_temp.sid(604) and event_id = pg_temp.e(6)),
  2.00::numeric, 'Wettkampfbetreuung je Kalendertag (R6)');
select is((select hints from public.fi_settlement_items where settlement_id = pg_temp.sid(605)),
  array['no_training_time']::public.fi_hint[], 'Training ohne Trainingszeit: 0 TE mit Hinweis (R4)');
select ok((public.fi_get_settlement(pg_temp.sid(605)) -> 'info' -> 'hints') ? 'no_bank_account', 'Hinweis Bankverbindung fehlt');
select ok(not (public.fi_get_settlement(pg_temp.sid(605)) -> 'info') ? 'bank_check', 'kein Prüfwert der IBAN nach außen');
select is((public.fi_calculate_half(2026::smallint, 1::smallint) ->> 'unchanged')::int, 6, 'zweite Berechnung ändert nichts');

-- Sichtbarkeit (R31)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000032');
select results_eq(
  $$ select display_name from public.fi_list_settlements(2026::smallint, 1::smallint)
      where person_id in (select pg_temp.p(n) from generate_series(601, 606) n) order by display_name $$,
  $$ values ('Clara Ablauf'::text), ('Hans Helfer'), ('Olga Ohnebank'), ('Paul Zweigruppen'), ('Tina Trainerin') $$,
  'Kim (K&J): Abrechnungen mit K&J-Positionen, nicht Ben (nur Leistungssport)');
select throws_ok(format($$ select public.fi_get_settlement(%L) $$, pg_temp.sid(602)), 'P0001', 'FI_NOT_FOUND',
  'Ben per direktem Aufruf nicht lesbar');
select is(jsonb_array_length(public.fi_get_settlement(pg_temp.sid(606)) -> 'items'), 2,
  'Paul: ganze Abrechnung sichtbar, auch die Position des Leistungssports');
select throws_ok(format($$ select public.fi_correct_item(%L, null, 3, 'x') $$,
  (select id from public.fi_settlement_items where settlement_id = pg_temp.sid(605))), 'P0001', 'FI_FORBIDDEN',
  'Referent:in korrigiert nicht');

-- Korrektur (US-FI-07)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select throws_ok(format($$ select public.fi_correct_item(%L, null, 3, '  ') $$,
  (select id from public.fi_settlement_items where settlement_id = pg_temp.sid(605))), 'P0001', 'FI_REASON_REQUIRED',
  'Begründung Pflicht (R16)');
select lives_ok(format($$ select public.fi_correct_item(%L, null, 3, 'Training 17:00–18:30 laut Gruppenleitung') $$,
  (select id from public.fi_settlement_items where settlement_id = pg_temp.sid(605))), 'Menge korrigiert');
select is((select amount from public.fi_settlements where id = pg_temp.sid(605)), 12.00::numeric, '3 TE × 4 € Helfer:in');

-- Bestätigung (US-FI-08, -09)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000032');
select lives_ok(format($$ select public.fi_confirm(array[%L, %L, %L, %L, %L]::uuid[]) $$,
  pg_temp.sid(601), pg_temp.sid(603), pg_temp.sid(604), pg_temp.sid(605), pg_temp.sid(606)), 'Kim bestätigt K&J');
select results_eq(
  $$ select p.last_name, s.status::text from public.fi_settlements s join public.ea_persons p on p.id = s.person_id
      where p.id in (select pg_temp.p(n) from generate_series(601, 606) n) order by p.last_name $$,
  $$ values ('Ablauf'::text, 'confirmed'::text), ('Helfer', 'confirmed'), ('Lizenzneu', 'draft'), ('Ohnebank', 'confirmed'),
            ('Trainerin', 'confirmed'), ('Zweigruppen', 'draft') $$,
  'Paul wartet auf Leistungssport (R23)');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000032');
select throws_ok(format($$ select public.fi_confirm(array[%L]::uuid[]) $$, pg_temp.sid(602)), 'P0001', 'FI_NOT_FOUND',
  'Kim kann Ben (nur Leistungssport) nicht bestätigen');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select throws_ok(format($$ select public.fi_confirm_substitute(%L, %L, '') $$, pg_temp.sid(606), pg_temp.id('LS')),
  'P0001', 'FI_REASON_REQUIRED', 'Vertretung nur mit Begründung');
select lives_ok(format($$ select public.fi_confirm_substitute(%L, %L, 'Referat Leistungssport derzeit unbesetzt') $$,
  pg_temp.sid(606), pg_temp.id('LS')), 'Geschäftsstelle bestätigt in Vertretung');
select is((select status::text from public.fi_settlements where id = pg_temp.sid(606)), 'confirmed', 'Paul bestätigt');

-- Abschluss (US-FI-10) und Sperre (US-FI-13)
select throws_ok(format($$ select public.fi_close(array[%L]::uuid[]) $$, pg_temp.sid(606)), 'P0001', 'FI_SAME_PERSON',
  'wer bestätigt hat, schließt nicht ab (R23)');
select throws_ok(format($$ select public.fi_close(array[%L]::uuid[]) $$, pg_temp.sid(602)), 'P0001', 'FI_NOT_CONFIRMED',
  'nicht bestätigt');
select lives_ok(format($$ select public.fi_close(array[%L, %L, %L]::uuid[]) $$, pg_temp.sid(601), pg_temp.sid(603),
  pg_temp.sid(604)), 'Geschäftsstelle schließt ab');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select lives_ok(format($$ select public.fi_close(array[%L]::uuid[]) $$, pg_temp.sid(606)), 'zweite Person schließt Paul ab');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select ok(public.fi_event_locked(pg_temp.e(1)), 'Einsatz gesperrt');
select throws_ok(format($$ select public.ez_delete_event(%L) $$, pg_temp.e(1)), 'P0001', 'EZ_SETTLED',
  'abgerechneter Einsatz nicht löschbar');
select is(jsonb_array_length(public.fi_settlement_document(array[pg_temp.sid(601)]) -> 0 -> 'groups'), 1,
  'Abrechnungsdokument: Positionen nach Gruppe');
select throws_ok(format($$ select public.fi_settlement_document(array[%L]::uuid[]) $$, pg_temp.sid(605)),
  'P0001', 'FI_STATUS', 'Dokument erst nach dem Abschluss');

-- Neuer Einsatz nach dem Abschluss (US-FI-01 AK4)
select pg_temp.as_owner();
insert into public.ez_events (id, kind, span, referat_id, group_id, start_date, location_id, client_request_id, remuneration_kind_id)
values (pg_temp.e(10), 'training', 'single', pg_temp.id('KJ'), 'c0000000-0000-4000-8000-000000000001', date '2026-06-09',
        'e1000000-0000-4000-8000-000000000002', gen_random_uuid(), pg_temp.id('TRAINING'));
insert into public.ez_attendances (event_id, person_id, role, status) values (pg_temp.e(10), pg_temp.p(601), 'trainer', 'present');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select is((public.fi_calculate_half(2026::smallint, 1::smallint) ->> 'locked')::int, 4, 'abgeschlossene bleiben unverändert');
select ok((public.fi_get_settlement(pg_temp.sid(601)) -> 'info' -> 'hints') ? 'has_new_events', 'Hinweis nicht abgerechnete Einsätze');
select is((select amount from public.fi_settlements where id = pg_temp.sid(601)), 141.00::numeric, 'Betrag unverändert');

-- Rücknahme (US-FI-11)
select lives_ok(format($$ select public.fi_reopen(%L) $$, pg_temp.sid(603)), 'Abschluss zurückgenommen');
select is((select count(*)::int from public.fi_settlement_confirmations where settlement_id = pg_temp.sid(603)), 0,
  'Bestätigungen entfallen');
select ok(not public.fi_event_locked(pg_temp.e(5)), 'Sperre aufgehoben');

-- Abgabe (US-FI-12)
select throws_ok(format($$ select public.fi_record_submission(%L, current_date + 1) $$, pg_temp.sid(601)),
  'P0001', 'FI_DATE_FUTURE', 'kein Datum in der Zukunft');
select lives_ok(format($$ select public.fi_record_submission(%L, date '2026-07-20') $$, pg_temp.sid(601)), 'fristgerecht');
select throws_ok(format($$ select public.fi_record_submission(%L, date '2026-08-02') $$, pg_temp.sid(604)),
  'P0001', 'FI_LATE_REASON_REQUIRED', 'nach der Frist nur mit Begründung (R19)');
select lives_ok(format($$ select public.fi_record_submission(%L, date '2026-08-02', 'Krankheit') $$, pg_temp.sid(604)),
  'nach der Frist mit Begründung');
select lives_ok(format($$ select public.fi_record_submission(%L, date '2026-07-01') $$, pg_temp.sid(606)), 'Paul abgegeben');
select throws_ok(format($$ select public.fi_expire(array[%L]::uuid[]) $$, pg_temp.sid(601)), 'P0001', 'FI_STATUS',
  'nur abgeschlossene verfallen');

-- Auszahlungsrunde (US-FI-14 bis -16)
select throws_ok($$ select public.fi_create_payout_run(2026::smallint, 1::smallint, current_date - 1) $$, 'P0001',
  'FI_EXECUTION_DATE', 'Ausführungsdatum nicht in der Vergangenheit (R30)');
insert into ids select 'RUN', public.fi_create_payout_run(2026::smallint, 1::smallint, current_date);
select is((select number from public.fi_payout_runs where id = pg_temp.id('RUN')), 1::smallint, 'Runde 1');
select results_eq(
  $$ select l ->> 'last_name', l ->> 'group_label', (l ->> 'amount')::numeric
       from jsonb_array_elements(public.fi_preview_payout_run(pg_temp.id('RUN')) -> 'lines') l $$,
  $$ values ('Helfer'::text, 'Jugendgruppe Test 1'::text, 92.00::numeric), ('Trainerin', 'Jugendgruppe Test 1', 141.00),
            ('Zweigruppen', 'Jugendgruppe Test 1', 18.00), ('Zweigruppen', 'Leistungsgruppe Test', 24.00) $$,
  'Vorschau: je Person und Gruppe, sortiert nach Gruppe und Name (R24)');
select lives_ok($$ select public.fi_release_payout_run(pg_temp.id('RUN')) $$, 'Runde freigegeben');
select results_eq(
  $$ select status::text, line_count, total from public.fi_payout_runs where id = pg_temp.id('RUN') $$,
  $$ values ('released'::text, 4, 275.00::numeric) $$, 'Anzahl und Summe (R28)');
select results_eq(
  $$ select p.last_name, s.status::text from public.fi_settlements s join public.ea_persons p on p.id = s.person_id
      where s.payout_run_id = pg_temp.id('RUN') order by p.last_name $$,
  $$ values ('Helfer'::text, 'paid'::text), ('Trainerin', 'paid'), ('Zweigruppen', 'paid') $$, 'ausgezahlt');
select is((public.fi_payout_export(pg_temp.id('RUN')) -> 'lines' -> 0 ->> 'remittance'),
  'ÜL-Vergütung 1. Hj 2026 Jugendgruppe Test 1', 'Verwendungszweck (R26)');
select is((public.fi_payout_export(pg_temp.id('RUN')) -> 'lines' -> 0 ->> 'iban'), 'DE89370400440532013000', 'IBAN im Export');
select is((public.fi_payout_export(pg_temp.id('RUN')) -> 'debtor' ->> 'debtor_name'), 'Sektion Test', 'Auftraggeber (Seed)');
select ok((public.fi_payout_export(pg_temp.id('RUN')) -> 'run' ->> 'msg_id') ~ '^FI-2026-1-01-[0-9a-f]{8}$', 'Nachrichten-ID');
select ok(not exists (select 1 from information_schema.columns
                       where table_schema = 'public' and table_name = 'fi_payout_lines' and column_name in ('iban', 'account_holder')),
  'IBAN und Name nicht gespeichert (R21)');
select throws_ok($$ select public.fi_release_payout_run(pg_temp.id('RUN')) $$, 'P0001', 'FI_STATUS', 'nur einmal freigeben');
select is((select count(*)::int from public.fi_payout_lines where run_id = pg_temp.id('RUN')
             and end_to_end_id ~ '^FI-2026-1-01-[0-9]{4}$'), 4, 'Ende-zu-Ende-IDs');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000032');
select throws_ok($$ select public.fi_payout_export(pg_temp.id('RUN')) $$, 'P0001', 'FI_FORBIDDEN', 'Referent:in: kein Export');
select is_empty($$ select 1 from public.fi_payout_lines $$, 'Referent:in: keine Auszahlzeilen');

-- Abgleich Punktekonto (US-FI-17)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select lives_ok($$ select public.fi_save_climbing_check('e1000000-0000-4000-8000-000000000001', date '2026-03-01',
  date '2026-03-31', 5, 'TEST-2026-03') $$, 'Abgleich gespeichert');
select is((select invoiced - counted_without_trials from public.fi_list_climbing_checks() limit 1), 5, 'Abweichung zur Rechnung');
select throws_ok($$ select * from public.fi_climbing_report('e1000000-0000-4000-8000-000000000002', date '2026-03-01',
  date '2026-03-31') $$, 'P0001', 'FI_LOCATION_NO_POINTS', 'nur Orte mit Punktekonto');

select * from finish();
rollback;
