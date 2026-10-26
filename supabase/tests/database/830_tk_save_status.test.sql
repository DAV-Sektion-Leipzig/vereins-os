-- Planungshilfe Touren und Kurse, spec T7, T8, T11, T18 (tasks.md T007–T011, T014): Speichern (R12, R13, R17, R18,
-- R20), Statusablauf (Abschnitt 4, R3, R6, R21), Verlauf ab Freigabe (R19), Kopieren (US-TK-23), Abrechnungsvorlage
-- (US-TK-24).
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

create function pg_temp.as_user(p_user int) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object(
    'sub', ('b0000000-0000-4000-8000-0000000000' || lpad(p_user::text, 2, '0')), 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
end $$;
create function pg_temp.as_owner() returns void language plpgsql as $$
begin
  execute 'reset role';
  perform set_config('request.jwt.claims', '', true);
end $$;
create function pg_temp.p() returns uuid language sql as $$ select current_setting('test.p')::uuid $$;
create function pg_temp.st() returns text language sql as $$ select status::text from public.tk_plans where id = pg_temp.p() $$;
create function pg_temp.rv() returns int language sql as $$ select row_version from public.tk_plans where id = pg_temp.p() $$;
create function pg_temp.complete() returns jsonb language sql as $$
  select '{"plan_type": "guided_tour", "title": "Hüttentour (Test)", "sport": "Bergwandern", "region": "x",
           "teaser": "x", "image_source": "referat", "start_date": "2027-07-12", "end_date": "2027-07-16",
           "meet_time": "11:00", "meeting_point": "x", "public_transport": "possible", "fitness": "medium",
           "technique": "easy", "requirements": "x", "equipment": "x", "min_participants": 5, "max_participants": 8,
           "registration_deadline": "2027-05-15", "confirm_license": true, "confirm_calculation": true,
           "confirm_ul_declaration": true, "confirm_emergency_card": true}'::jsonb
$$;
create function pg_temp.leaders() returns jsonb language sql as $$
  select '[{"person_id": "a0000000-0000-4000-8000-000000000016", "role": "lead"}]'::jsonb
$$;
create function pg_temp.contacts() returns jsonb language sql as $$
  select '[{"person_id": "a0000000-0000-4000-8000-000000000016", "email": "bernd.test@example.test",
            "emergency_name": "Notfall Test", "emergency_phone": "0151 0000001"}]'::jsonb
$$;
create function pg_temp.legs() returns jsonb language sql as $$
  select '[{"mode": "rail_long", "km_one_way": 650, "persons": 9}]'::jsonb
$$;

-- Anlegen (R12) und Schutz gegen doppeltes Anlegen
select pg_temp.as_user(13);
select throws_ok($$ select public.tk_save_plan('{"plan_type": "course", "title": "Kurs"}', null, null, null, null) $$,
  'P0001', 'TK_FORBIDDEN_REFERAT', 'Tina: Kurs gehört zum Referat Ausbildung (R12)');
select pg_temp.as_user(3);
select throws_ok($$ select public.tk_save_plan('{"plan_type": "guided_tour", "title": "X"}', null, null, null, null) $$,
  'P0001', 'TK_FORBIDDEN', 'Vorstand: keine Berechtigung');
select pg_temp.as_user(13);
select set_config('test.crid', gen_random_uuid()::text, true);
select set_config('test.p', public.tk_save_plan(
  jsonb_build_object('plan_type', 'guided_tour', 'title', 'Entwurf (Test)', 'client_request_id', current_setting('test.crid')),
  null, null, null, null) ->> 'id', true);
select is(public.tk_save_plan(jsonb_build_object('plan_type', 'guided_tour', 'title', 'Entwurf (Test)',
            'client_request_id', current_setting('test.crid')), null, null, null, null) ->> 'id',
  current_setting('test.p'), 'gleiche client_request_id → gleiche Planung');
select is(pg_temp.st(), 'draft', 'neu: Entwurf');
select results_eq($$ select event from public.tk_plan_history where plan_id = pg_temp.p() $$, $$ values ('created'::text) $$,
  'Verlauf: angelegt');
select throws_like($$ select public.tk_save_plan(jsonb_build_object('id', pg_temp.p(), 'title', repeat('x', 91)),
                       null, null, null, null) $$, 'TK_FIELD_INVALID', 'Titel höchstens 90 Zeichen');

-- R13, R17, R18
select throws_ok($$ select public.tk_save_plan(jsonb_build_object('id', pg_temp.p()),
                     '[{"person_id": "a0000000-0000-4000-8000-000000000011", "role": "lead"}]', null, null, null) $$,
  'P0001', 'TK_PERSON_NOT_ACTIVE', 'ausgeschiedene Person nicht wählbar (R13)');
select throws_ok($$ select public.tk_save_plan(jsonb_build_object('id', pg_temp.p()),
                     '[{"person_id": "a0000000-0000-4000-8000-000000000016"}, {"person_id": "a0000000-0000-4000-8000-000000000016"}]',
                     null, null, null) $$,
  'P0001', 'TK_DUPLICATE_PERSON', 'Person doppelt (R17)');
select throws_ok($$ select public.tk_save_plan(jsonb_build_object('id', pg_temp.p()), pg_temp.leaders(),
                     '[{"person_id": "a0000000-0000-4000-8000-000000000016", "email": "kein-at"}]', null, null) $$,
  'P0001', 'TK_EMAIL_INVALID', 'E-Mail ungültig (R18)');
select throws_ok($$ select public.tk_save_plan(jsonb_build_object('id', pg_temp.p()), pg_temp.leaders(),
                     '[{"person_id": "a0000000-0000-4000-8000-000000000016", "emergency_phone": "abc"}]', null, null) $$,
  'P0001', 'TK_PHONE_INVALID', 'Telefon ungültig (R18)');

-- R20 gleichzeitiges Bearbeiten
select set_config('test.rv', pg_temp.rv()::text, true);
select lives_ok($$ select public.tk_save_plan(jsonb_build_object('id', pg_temp.p(), 'region', 'Harz'), null, null, null, null,
                     current_setting('test.rv')::int) $$, 'Speichern mit aktuellem Stand');
select throws_like($$ select public.tk_save_plan(jsonb_build_object('id', pg_temp.p(), 'region', 'Alpen'), null, null, null, null,
                       current_setting('test.rv')::int) $$, 'TK_CONFLICT', 'veralteter Stand → TK_CONFLICT (R20)');

-- Einreichen mit offenen Pflichtangaben
select throws_like($$ select public.tk_change_status(pg_temp.p(), 'submit') $$, 'TK_MISSING_FIELDS',
  'Einreichen mit offenen Angaben verweigert (US-TK-13 AK2)');
select is(pg_temp.st(), 'draft', 'Status bleibt Entwurf');
select throws_ok($$ select public.tk_change_status(pg_temp.p(), 'approve') $$, 'P0001', 'TK_STATUS_NOT_ALLOWED',
  'Entwurf kann nicht freigegeben werden');

-- vollständig machen und einreichen
select lives_ok($$ select public.tk_save_plan(pg_temp.complete() || jsonb_build_object('id', pg_temp.p()), pg_temp.leaders(),
                     pg_temp.contacts(), pg_temp.legs(), '[]') $$, 'Planung vollständig');
select lives_ok($$ select public.tk_change_status(pg_temp.p(), 'submit') $$, 'Tina reicht ein');
select is(pg_temp.st(), 'submitted', 'eingereicht');
select throws_ok($$ select public.tk_change_status(pg_temp.p(), 'query') $$, 'P0001', 'TK_COMMENT_REQUIRED',
  'Rückfrage ohne Kommentar (R21)');
select pg_temp.as_user(15);
select lives_ok($$ select public.tk_change_status(pg_temp.p(), 'query', 'Bitte Treffpunkt präzisieren.') $$,
  'Fritz stellt Rückfrage');
select is(pg_temp.st(), 'query', 'Rückfrage');
select lives_ok($$ select public.tk_change_status(pg_temp.p(), 'resubmit') $$, 'erneut eingereicht');
select pg_temp.as_user(2);
select throws_ok($$ select public.tk_change_status(pg_temp.p(), 'approve') $$, 'P0001', 'TK_FORBIDDEN',
  'Geschäftsstelle gibt nicht frei');
select pg_temp.as_user(15);
select lives_ok($$ select public.tk_change_status(pg_temp.p(), 'approve', 'Passt.') $$, 'Fritz gibt frei');
select is(pg_temp.st(), 'approved', 'freigegeben');
select ok((select count(*) from public.tk_plan_rates where plan_id = pg_temp.p()) > 30, 'Satzstand eingefroren (R3)');
select is((select rates_frozen_on from public.tk_plans where id = pg_temp.p()), current_date, 'eingefroren am heutigen Tag');

-- R3: neuer Satz ändert die freigegebene Planung nicht
select pg_temp.as_owner();
insert into public.ad_rates (rate_key, label, rate_group, unit, value, valid_from, source)
values ('rOrg', 'Organisationspauschale je Tag', 'remuneration', '€', 99, date '2027-01-01', 'Test');
select pg_temp.as_user(15);
select lives_ok($$ select public.tk_save_plan(jsonb_build_object('id', pg_temp.p(), 'start_date', '2027-07-13'), null, null,
                     null, null) $$, 'Fritz ändert den Beginn nach der Freigabe');
select is((select org_total from public.tk_plan_results where plan_id = pg_temp.p()), 40.00::numeric,
  'eingefrorener Satz: 4 Tage × 10 € (nicht 99 €)');
select ok('start_date' = any (coalesce((select changed_fields from public.tk_plan_history
                                          where plan_id = pg_temp.p() and event = 'saved' order by at desc limit 1), '{}')),
  'Verlauf ab Freigabe mit geänderten Feldern (R19)');

-- In Yolawo angelegt (A11: Freigaberecht oder Geschäftsstelle)
select pg_temp.as_user(15);
select lives_ok($$ select public.tk_change_status(pg_temp.p(), 'publish', null, 'YLW-4711') $$, 'Fritz: in Yolawo angelegt');
select results_eq($$ select status::text, yolawo_ref from public.tk_plans where id = pg_temp.p() $$,
  $$ values ('published'::text, 'YLW-4711'::text) $$, 'Status und Yolawo-Angebot');
select throws_ok($$ select public.tk_change_status(pg_temp.p(), 'done') $$, 'P0001', 'TK_NOT_FINISHED', 'Tour noch nicht vorbei');

-- Abrechnungsvorlage (US-TK-24)
select pg_temp.as_user(13);
select throws_ok($$ select public.tk_settlement_draft(pg_temp.p()) $$, 'P0001', 'TK_FORBIDDEN', 'Tina: keine Abrechnungsvorlage');
select pg_temp.as_user(2);
select results_eq(
  $$ select (d ->> 'days_full')::int, (d ->> 'org_days')::int, d -> 'persons' -> 0 ->> 'rate_kind', (d ->> 'total_costs')::numeric
       from public.tk_settlement_draft(pg_temp.p()) d $$,
  $$ values (4, 4, 'trainer'::text, 240.00::numeric) $$, 'Geschäftsstelle: Planwerte mit Satzart');

-- Absage (R21)
select pg_temp.as_user(13);
select throws_ok($$ select public.tk_change_status(pg_temp.p(), 'cancel') $$, 'P0001', 'TK_COMMENT_REQUIRED',
  'Absage ohne Grund');
select lives_ok($$ select public.tk_change_status(pg_temp.p(), 'cancel', 'Mindestteilnehmerzahl nicht erreicht') $$,
  'Absage mit Grund');
select results_eq($$ select status::text, cancel_reason from public.tk_plans where id = pg_temp.p() $$,
  $$ values ('cancelled'::text, 'Mindestteilnehmerzahl nicht erreicht'::text) $$, 'abgesagt mit Grund');
select pg_temp.as_user(2);
select throws_ok($$ select public.tk_settlement_draft(pg_temp.p()) $$, 'P0001', 'TK_PLAN_CANCELLED',
  'abgesagte Planung: keine Abrechnungsvorlage');

-- durchgeführt und abgeschlossen (Planung in der Vergangenheit)
select pg_temp.as_user(13);
select set_config('test.p', public.tk_save_plan(jsonb_build_object('plan_type', 'guided_tour', 'title', 'Vergangen (Test)',
  'start_date', (current_date - 10)::text, 'end_date', (current_date - 9)::text), pg_temp.leaders(), null, '[]', '[]') ->> 'id', true);
select pg_temp.as_owner();
select set_config('tk.status_change', 'on', true);
update public.tk_plans set status = 'published' where id = pg_temp.p();
select set_config('tk.status_change', '', true);
select pg_temp.as_user(13);
select lives_ok($$ select public.tk_change_status(pg_temp.p(), 'done') $$, 'durchgeführt nach dem Ende');
select throws_ok($$ select public.tk_change_status(pg_temp.p(), 'close') $$, 'P0001', 'TK_FORBIDDEN',
  'abschließen nur Geschäftsstelle');
select pg_temp.as_user(2);
select lives_ok($$ select public.tk_change_status(pg_temp.p(), 'close') $$, 'Geschäftsstelle schließt ab');
select is(pg_temp.st(), 'closed', 'abgeschlossen');
select is((select array_agg(event order by at, id) from public.tk_plan_history where plan_id = pg_temp.p()),
  array['created', 'done', 'closed'], 'Verlauf je Statuswechsel');

-- Kopieren (US-TK-23)
select pg_temp.as_user(13);
select set_config('test.src', public.tk_save_plan(pg_temp.complete() || '{"title": "Vorlage (Test)"}',
  '[{"person_id": "a0000000-0000-4000-8000-000000000016", "role": "lead"},
    {"person_id": "a0000000-0000-4000-8000-000000000017", "role": "helper"}]', pg_temp.contacts(), pg_temp.legs(), '[]') ->> 'id', true);
select pg_temp.as_owner();
update public.ea_persons set volunteer_status = 'left' where id = 'a0000000-0000-4000-8000-000000000017';
select pg_temp.as_user(13);
select set_config('test.copy', public.tk_copy_plan(current_setting('test.src')::uuid, gen_random_uuid())::text, true);
select is(current_setting('test.copy')::jsonb -> 'removed', '["Hilde Helfer"]'::jsonb,
  'nicht mehr aktive Person entfernt, Hinweis mit Namen (AK4)');
select results_eq(
  $$ select status::text, start_date, registration_deadline, confirm_license, title
       from public.tk_plans where id = (current_setting('test.copy')::jsonb ->> 'id')::uuid $$,
  $$ values ('draft'::text, null::date, null::date, false, 'Vorlage (Test)'::text) $$,
  'Kopie: Entwurf ohne Termin, Anmeldeschluss und Bestätigungen');
select is((select count(*)::int from public.tk_plan_contacts where plan_id = (current_setting('test.copy')::jsonb ->> 'id')::uuid), 0,
  'Kopie ohne Kontaktdaten');
select is((select count(*)::int from public.tk_plan_legs where plan_id = (current_setting('test.copy')::jsonb ->> 'id')::uuid), 1,
  'Kopie mit Teilstrecken');
select pg_temp.as_user(14);
select throws_ok($$ select public.tk_copy_plan(current_setting('test.src')::uuid, gen_random_uuid()) $$, 'P0001', 'TK_NOT_FOUND',
  'Alex kopiert keine Planung des Referats Touren (AK3)');

select * from finish();
rollback;
