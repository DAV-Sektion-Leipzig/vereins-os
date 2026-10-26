-- Planungshilfe Touren und Kurse, spec T6 (tasks.md T006): Kalkulation nach R1–R4, R6, R22 mit den Planungen aus
-- spec.md TK Abschnitt 9 (Werte Prototyp 4.5, 4.7), Satzwechsel nach valid_from (US-TK-19 AK2), fehlender Satz (AK4),
-- Satzart mit Lizenz-Erwerb im Halbjahr (R2 b). Testzugänge aus seed.sql: b…13 Tina Touren, b…14 Alex Ausbildung,
-- b…02 Geschäftsstelle; Personen a…16 Bernd Berg (TCBW bis 30.10.2027), a…17 Hilde Helfer, a…18 Karl Kletter.
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
create function pg_temp.res(p_id uuid) returns public.tk_plan_results language sql as $$
  select * from public.tk_plan_results where plan_id = p_id
$$;
create function pg_temp.complete() returns jsonb language sql as $$
  select '{"teaser": "x", "image_source": "referat", "public_transport": "possible", "fitness": "medium",
           "technique": "easy", "requirements": "x", "equipment": "x", "confirm_license": true,
           "confirm_calculation": true, "confirm_ul_declaration": true, "confirm_emergency_card": true,
           "meeting_point": "x", "region": "x"}'::jsonb
$$;
create function pg_temp.contact(p_person text) returns jsonb language sql as $$
  select jsonb_build_array(jsonb_build_object('person_id', p_person, 'email', 'leitung.test@example.test',
           'emergency_name', 'Notfall Test', 'emergency_phone', '0151 0000001'))
$$;
create function pg_temp.save(p_plan jsonb, p_leaders jsonb, p_contacts jsonb, p_legs jsonb, p_costs jsonb)
returns uuid language sql as $$
  select (public.tk_save_plan(p_plan, p_leaders, p_contacts, p_legs, p_costs) ->> 'id')::uuid
$$;

-- Planung 1 (Beispiel Prototyp 3.5)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000013');
select set_config('test.p1', pg_temp.save(
  pg_temp.complete() || '{"plan_type": "guided_tour", "title": "Hüttentour Stubaier Alpen (Test)", "sport": "Bergwandern",
    "image_source": "own", "image_credit": "Foto: Test", "start_date": "2027-07-12", "end_date": "2027-07-16",
    "meet_time": "11:00", "end_time": "15:00", "public_transport": "together", "accommodation": "hut",
    "max_walk_hours": 7, "max_ascent": 1000, "max_descent": 1000, "fitness": "high", "technique": "medium",
    "min_participants": 5, "max_participants": 8, "registration_deadline": "2027-05-15", "days_full": 5,
    "days_half": 0, "org_days": 5, "touched": ["days_full", "days_half", "org_days"]}',
  '[{"person_id": "a0000000-0000-4000-8000-000000000016", "role": "lead"}]',
  pg_temp.contact('a0000000-0000-4000-8000-000000000016'),
  '[{"mode": "rail_long", "km_one_way": 650, "persons": 9}, {"mode": "local_bus", "km_one_way": 30, "persons": 9}]',
  '[{"cost_group": "leader", "label": "Bahnfahrt", "quantity": 2, "unit_price": 105},
    {"cost_group": "leader", "label": "Halbpension Hütte", "quantity": 5, "unit_price": 45},
    {"cost_group": "leader", "label": "Übernachtung Hütte", "quantity": 5, "unit_price": 0, "is_overnight": true},
    {"cost_group": "self_paid", "label": "Ü + HP", "quantity": 4, "unit_price": 63.5, "is_hut_half_board": true},
    {"cost_group": "self_paid", "label": "Bahn", "quantity": 1, "unit_price": 210},
    {"cost_group": "self_paid", "label": "Getränke", "quantity": 5, "unit_price": 15}]')::text, true);
select results_eq(
  $$ select fee_total, org_total, leader_costs, total_costs, price_suggested, price_member_effective, break_even,
            result_min, result_max, fees_at_min, self_paid_per_participant, fee_method
       from pg_temp.res(current_setting('test.p1')::uuid) $$,
  $$ values (250.00::numeric, 50.00::numeric, 435.00::numeric, 735.00::numeric, 160.00::numeric, 160.00::numeric, 5,
             18.71::numeric, 470.93::numeric, 46.29::numeric, 539.00::numeric, 'fee_paypal'::text) $$,
  'Planung 1: Vergütung 250, Org 50, Kosten 735, Vorschlag 160 (PayPal), ab 5, Ergebnis 18,71 / 470,93 (Prototyp 4.5)');
select results_eq(
  $$ select co2_mobility_kg, co2_stay_kg, co2_food_kg, co2_tour_kg, co2_all_kg, co2_per_person_kg,
            co2_per_person_day_kg, climate_budget_eur, co2_status, fitness_suggested::text
       from pg_temp.res(current_setting('test.p1')::uuid) $$,
  $$ values (352.80::numeric, 335.52::numeric, 211.50::numeric, 564.30::numeric, 899.82::numeric, 99.98::numeric,
             20.00::numeric, 79.00::numeric, 'mostly_pt'::text, 'high'::text) $$,
  'Planung 1: CO2 Tour 564,3 kg, je Person ≈ 100, Budget 79,00 € (Prototyp 4.7)');
select is((pg_temp.res(current_setting('test.p1')::uuid)).missing, '{}'::text[], 'Planung 1: vollständig');
select results_eq($$ select nights, co2_persons from public.tk_plans where id = current_setting('test.p1')::uuid $$,
  $$ values (4, 9) $$, 'Vorschläge: 4 Nächte, 9 Personen (8 TN + 1 Leitung)');
select is((select rate_kind::text from public.tk_plan_leaders where plan_id = current_setting('test.p1')::uuid),
  'trainer', 'Bernd Berg: Trainersatz');

-- Nichtmitglieder 210 € bei Ausnahme
select lives_ok($$ select public.tk_save_plan(jsonb_build_object('id', current_setting('test.p1'),
                     'non_members_allowed', true, 'non_members_reason', 'Schnupperangebot (Test)'), null, null, null, null) $$,
  'Ausnahme Nichtmitglieder speichern');
select is((pg_temp.res(current_setting('test.p1')::uuid)).price_non_member_effective, 210.00::numeric,
  'Nichtmitglieder: ceil(160 × 1,3 / 5) × 5 = 210 €');
select lives_ok($$ select public.tk_save_plan(jsonb_build_object('id', current_setting('test.p1'), 'price_member', 150),
                     null, null, null, null) $$, 'eigener Beitrag 150 €');
select ok('price_below_suggestion' = any ((pg_temp.res(current_setting('test.p1')::uuid)).warnings),
  'Beitrag unter dem Vorschlag: Warnung, wird übernommen');
select is((pg_temp.res(current_setting('test.p1')::uuid)).price_non_member_effective, 195.00::numeric,
  'Nichtmitglieder aus dem eigenen Mitgliederbeitrag: ceil(150 × 1,3 / 5) × 5 = 195 €');

-- Planung 2: eintägiger Kurs, 8 Lehreinheiten × 15 €, Sportart nicht abgedeckt
select pg_temp.as_user('b0000000-0000-4000-8000-000000000014');
select set_config('test.p2', pg_temp.save(
  pg_temp.complete() || '{"plan_type": "course", "title": "Vorstieg am Fels (Test)", "sport": "Klettern",
    "start_date": "2027-10-15", "end_date": "2027-10-15", "meet_time": "09:00", "end_time": "17:00",
    "min_participants": 4, "max_participants": 6, "registration_deadline": "2027-09-15"}',
  '[{"person_id": "a0000000-0000-4000-8000-000000000016", "role": "lead"}]', null,
  '[{"mode": "car", "km_one_way": 150, "persons": 6, "vehicles": 2}]', '[]')::text, true);
select results_eq(
  $$ select r.fee_total, r.org_total, p.teaching_hours, r.days
       from pg_temp.res(current_setting('test.p2')::uuid) r join public.tk_plans p on p.id = r.plan_id $$,
  $$ values (120.00::numeric, 0.00::numeric, 8, 1) $$, 'Planung 2: 8 Lehreinheiten × 15 € = 120 €, Org 0');
select ok('sport_not_covered' = any ((pg_temp.res(current_setting('test.p2')::uuid)).warnings),
  'Planung 2: Klettern nicht durch Bergwandern abgedeckt');
select is((select referat_id from public.tk_plans where id = current_setting('test.p2')::uuid),
  (select id from public.ea_referate where name = 'Ausbildung'), 'Kurs im Referat Ausbildung (R12)');

-- Planung 3: Lizenz läuft während der Tour ab → Trainersatz für die ganze Tour, Warnung
select pg_temp.as_user('b0000000-0000-4000-8000-000000000013');
select set_config('test.p3', pg_temp.save(
  '{"plan_type": "guided_tour", "title": "Herbstwanderung (Test)", "start_date": "2027-10-29", "end_date": "2027-11-01"}',
  '[{"person_id": "a0000000-0000-4000-8000-000000000016", "role": "lead"}]', null, '[]', '[]')::text, true);
select is((select rate_kind::text from public.tk_plan_leaders where plan_id = current_setting('test.p3')::uuid),
  'trainer', 'Planung 3: Trainersatz trotz Ablauf 30.10. (R2)');
select ok('license_expires_during' = any ((pg_temp.res(current_setting('test.p3')::uuid)).warnings),
  'Planung 3: Warnung Lizenz läuft während der Tour ab');
select is((pg_temp.res(current_setting('test.p3')::uuid)).fee_total, 200.00::numeric, 'Planung 3: 4 Tagessätze × 50 €');

-- Planung 4: Lizenz abgelaufen → Helfersatz
select set_config('test.p4', pg_temp.save(
  '{"plan_type": "guided_tour", "title": "Novembertour (Test)", "start_date": "2027-11-02", "end_date": "2027-11-02",
    "meet_time": "08:00", "end_time": "17:00"}',
  '[{"person_id": "a0000000-0000-4000-8000-000000000016", "role": "lead"}]', null, '[]', '[]')::text, true);
select is((select rate_kind::text from public.tk_plan_leaders where plan_id = current_setting('test.p4')::uuid),
  'helper', 'Planung 4: Helfersatz (Lizenz bis 30.10.2027)');
select ok('helper_rate' = any ((pg_temp.res(current_setting('test.p4')::uuid)).warnings), 'Planung 4: Warnung Helfersatz');
select is((pg_temp.res(current_setting('test.p4')::uuid)).fee_total, 40.00::numeric,
  'Planung 4: 9 h → 1 Tagessatz Helfer:in 40 €');

-- Planung 5: Gemeinschaftstour, Organisationspauschale 3 × 10 €, trägt die Sektion (R4)
select set_config('test.p5', pg_temp.save(
  '{"plan_type": "community_tour", "title": "Sächsische Schweiz (Test)", "start_date": "2027-09-10",
    "end_date": "2027-09-12", "min_participants": 4}',
  '[{"person_id": "a0000000-0000-4000-8000-000000000017", "role": "lead"}]', null, '[]',
  '[{"cost_group": "leader", "label": "PKW-Fahrt", "quantity": 600, "unit_price": 0.2, "is_car": true}]')::text, true);
select results_eq(
  $$ select fee_total, org_total, leader_costs, total_costs, price_member_effective, is_free, section_bears
       from pg_temp.res(current_setting('test.p5')::uuid) $$,
  $$ values (0.00::numeric, 30.00::numeric, 0.00::numeric, 30.00::numeric, 0.00::numeric, true, 30.00::numeric) $$,
  'Planung 5: Org 30 €, keine Kosten der Leitung, Beitrag 0, Sektion trägt 30 €');
select ok(not ('car_permit' = any ((pg_temp.res(current_setting('test.p5')::uuid)).warnings))
          and not ('car_reason' = any ((pg_temp.res(current_setting('test.p5')::uuid)).missing)),
  'Gemeinschaftstour: keine PKW-Warnung, keine PKW-Begründung');
select ok('community_reason' = any ((pg_temp.res(current_setting('test.p5')::uuid)).missing),
  'Gemeinschaftstour: Begründung Pflicht');
select ok(not ('confirm_license' = any ((pg_temp.res(current_setting('test.p5')::uuid)).missing)),
  'Gemeinschaftstour: c1 ausgeblendet');

-- Planung 7: Familienwanderung ohne Beitrag
select set_config('test.p7', pg_temp.save(
  '{"plan_type": "guided_tour", "title": "Familienwanderung (Test)", "target_groups": ["Familienwanderungen"],
    "start_date": "2027-04-18", "end_date": "2027-04-18", "meet_time": "10:00", "end_time": "15:00", "no_fee": true,
    "min_participants": 4}',
  '[{"person_id": "a0000000-0000-4000-8000-000000000016", "role": "lead"}]', null, '[]',
  '[{"cost_group": "fixed", "label": "Eintritt", "quantity": 1, "unit_price": 40}]')::text, true);
select results_eq(
  $$ select is_free, total_costs, section_bears, price_member_effective from pg_temp.res(current_setting('test.p7')::uuid) $$,
  $$ values (true, 65.00::numeric, 65.00::numeric, 0.00::numeric) $$,
  'Planung 7: ohne Beitrag, Sektion trägt Gesamtkosten (Halbtagessatz 25 + 40)');
select lives_ok($$ select public.tk_save_plan(jsonb_build_object('id', current_setting('test.p7'), 'target_groups', '[]'::jsonb),
                     null, null, null, null) $$, 'Zielgruppe entfernt');
select ok(not (pg_temp.res(current_setting('test.p7')::uuid)).is_free
          and 'no_fee_not_allowed' = any ((pg_temp.res(current_setting('test.p7')::uuid)).warnings),
  'ohne Beitrag nur bei Familienwanderung als Tagestour');

-- Planung 9: mehrtägiger Kurs nur nach Lehreinheiten, ohne Vorschlag (R22)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000014');
select set_config('test.p9', pg_temp.save(
  '{"plan_type": "course", "title": "Grundkurs Hochtouren (Test)", "start_date": "2027-07-01", "end_date": "2027-07-03",
    "meet_time": "08:00", "end_time": "18:00"}',
  '[{"person_id": "a0000000-0000-4000-8000-000000000016", "role": "lead"},
    {"person_id": "a0000000-0000-4000-8000-000000000017", "role": "helper"}]', null, '[]', '[]')::text, true);
select results_eq(
  $$ select p.teaching_hours, r.fee_total, r.org_total
       from public.tk_plans p join pg_temp.res(p.id) r on true where p.id = current_setting('test.p9')::uuid $$,
  $$ values (null::int, 0.00::numeric, 0.00::numeric) $$, 'Planung 9: kein Vorschlag für Lehreinheiten, Org 0');
select ok('teaching_hours' = any ((pg_temp.res(current_setting('test.p9')::uuid)).missing), 'Planung 9: Lehreinheiten Pflicht');
select lives_ok($$ select public.tk_save_plan(jsonb_build_object('id', current_setting('test.p9'), 'teaching_hours', 20,
                     'touched', '["teaching_hours"]'::jsonb), null, null, null, null) $$, '20 Lehreinheiten');
select is((pg_temp.res(current_setting('test.p9')::uuid)).fee_total, 300.00::numeric,
  'Planung 9: 20 × 15 € nur für Bernd (Helfer:in 0 €), keine Tagessätze');
select ok(not ('teaching_hours' = any ((pg_temp.res(current_setting('test.p9')::uuid)).missing)), 'Lehreinheiten erfasst');

-- R2 b: Lizenz im Halbjahr des Startdatums erworben (Karl Kletter, neue Lizenz ab 15.08.2027)
select pg_temp.as_owner();
insert into public.ea_properties (person_id, property_type_id, field_values, valid_from)
select 'a0000000-0000-4000-8000-000000000018', t.id,
       jsonb_build_object('qualification_type', (select id from public.ad_qualification_types where code = 'TCBW'),
                          'valid_until', '2031-12-31'), date '2027-08-15'
  from public.ea_property_types t where t.system_key = 'license';
select pg_temp.as_user('b0000000-0000-4000-8000-000000000013');
select set_config('test.pk', pg_temp.save(
  '{"plan_type": "guided_tour", "title": "Sommertour (Test)", "start_date": "2027-07-10", "end_date": "2027-07-10"}',
  '[{"person_id": "a0000000-0000-4000-8000-000000000018", "role": "lead"}]', null, '[]', '[]')::text, true);
select results_eq(
  $$ select rate_kind::text, license_valid_from from public.tk_plan_leaders where plan_id = current_setting('test.pk')::uuid $$,
  $$ values ('trainer'::text, date '2027-08-15') $$, 'Erwerb im Halbjahr: Trainersatz (wie Finanzen)');
select ok('license_acquired_in_half' = any ((pg_temp.res(current_setting('test.pk')::uuid)).warnings),
  'Hinweis Lizenz erworben im Halbjahr');
select lives_ok($$ select public.tk_save_plan(jsonb_build_object('id', current_setting('test.pk'),
                     'start_date', '2027-06-30', 'end_date', '2027-06-30'), null, null, null, null) $$, 'Termin im ersten Halbjahr');
select is((select rate_kind::text from public.tk_plan_leaders where plan_id = current_setting('test.pk')::uuid),
  'helper', 'Erwerb im nächsten Halbjahr: Helfersatz');

-- US-TK-19 AK2: Satzwechsel nach valid_from (Seed: rOrg 12 € ab 01.01.2028)
select set_config('test.p28', pg_temp.save(
  '{"plan_type": "guided_tour", "title": "Neujahrstour (Test)", "start_date": "2028-01-02", "end_date": "2028-01-04"}',
  '[{"person_id": "a0000000-0000-4000-8000-000000000017", "role": "lead"}]', null, '[]', '[]')::text, true);
select is((pg_temp.res(current_setting('test.p28')::uuid)).org_total, 36.00::numeric, '2028: Organisationspauschale 3 × 12 €');
select is((pg_temp.res(current_setting('test.p28')::uuid)).rates_valid_on, date '2028-01-02', 'Satzstand zum Beginn');

-- US-TK-19 AK4: fehlender Satz → Pflichtangabe und Warnung (Startbestand der Planungshilfe gilt erst ab 01.01.2026)
select set_config('test.p25', pg_temp.save(
  '{"plan_type": "guided_tour", "title": "Alte Planung (Test)", "start_date": "2025-06-01", "end_date": "2025-06-01"}',
  '[{"person_id": "a0000000-0000-4000-8000-000000000017", "role": "lead"}]', null, '[]', '[]')::text, true);
select ok('rate:rCO2' = any ((pg_temp.res(current_setting('test.p25')::uuid)).missing)
          and 'rate:rTL' = any ((pg_temp.res(current_setting('test.p25')::uuid)).missing)
          and 'rates_missing' = any ((pg_temp.res(current_setting('test.p25')::uuid)).warnings),
  'fehlender Satz zum Beginn: als Pflichtangabe gemeldet, Einreichen gesperrt');

-- Warnungen mit Grenzwerten aus den Sätzen (R6)
select set_config('test.pw', pg_temp.save(
  '{"plan_type": "guided_tour", "title": "Warnungen (Test)", "start_date": "2027-08-01", "end_date": "2027-08-02",
    "min_participants": 9, "max_participants": 8, "registration_deadline": "2027-08-01", "accommodation": "hut",
    "fitness": "low", "max_walk_hours": 9}',
  '[{"person_id": "a0000000-0000-4000-8000-000000000016", "role": "lead"}]', null,
  '[{"mode": "flight", "km_one_way": 500, "persons": 1}, {"mode": "car", "km_one_way": 300, "persons": 2, "vehicles": 1}]',
  '[{"cost_group": "leader", "label": "PKW-Fahrt", "quantity": 600, "unit_price": 0.2, "is_car": true},
    {"cost_group": "leader", "label": "Übernachtung", "quantity": 1, "unit_price": 80, "is_overnight": true},
    {"cost_group": "self_paid", "label": "Hütte HP", "quantity": 1, "unit_price": 30, "is_hut_half_board": true}]')::text, true);
select is(
  (select array_agg(w order by w) from unnest((pg_temp.res(current_setting('test.pw')::uuid)).warnings) w
    where w in ('min_gt_max', 'deadline_not_before_start', 'flight_short', 'car_pooling', 'car_over_guideline',
                'car_permit', 'overnight_over_limit', 'hut_free_place', 'hut_hp_price', 'fitness_differs')),
  array['car_over_guideline', 'car_permit', 'car_pooling', 'deadline_not_before_start', 'fitness_differs',
        'flight_short', 'hut_free_place', 'hut_hp_price', 'min_gt_max', 'overnight_over_limit'],
  'Warnungen: Grenzwerte aus den Sätzen, Kennzeichen statt Texterkennung');
select ok('car_reason' = any ((pg_temp.res(current_setting('test.pw')::uuid)).missing), 'PKW-Fahrt: Begründung Pflicht');

select * from finish();
rollback;
