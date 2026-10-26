-- Testdaten der Planungshilfe Touren und Kurse (spec.md TK v0.4 Abschnitt 9; tasks.md T014). Nur fiktiv, nur TEST,
-- nicht in CI (die pgTAP-Tests legen ihre Daten selbst an). Aufruf über supabase/seed.sh mit SEED_WITH_TK=1 nach
-- seed.sql (Personen 13–18 aus AD v0.9).
-- Planungen werden über tk_save_plan mit dem Nutzerkontext der Testzugänge angelegt (Rechte, Kalkulation);
-- Status ohne Prüfung der Pflichtangaben direkt gesetzt (nur Seed). Idempotent über client_request_id.
-- Planung 5 erhält ihren Einsatz mit Stufe 3 (tasks.md T015).

create function pg_temp.as_user(p_user uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', p_user, 'role', 'authenticated')::text, true);
end $$;

create function pg_temp.save(p_user uuid, p_crid uuid, p_plan jsonb, p_leaders jsonb, p_contacts jsonb, p_legs jsonb,
                             p_costs jsonb, p_status public.tk_plan_status) returns uuid language plpgsql as $$
declare
  v_id uuid;
begin
  perform pg_temp.as_user(p_user);
  select id into v_id from public.tk_plans where client_request_id = p_crid;
  if v_id is not null then
    return v_id;
  end if;
  v_id := (public.tk_save_plan(p_plan || jsonb_build_object('client_request_id', p_crid), p_leaders, p_contacts, p_legs,
                               p_costs) ->> 'id')::uuid;
  if p_status <> 'draft' then
    perform set_config('tk.status_change', 'on', true);
    update public.tk_plans set status = p_status where id = v_id;
    perform set_config('tk.status_change', '', true);
    insert into public.tk_plan_history (plan_id, event, from_status, to_status, comment)
    values (v_id, case p_status when 'submitted' then 'submitted' when 'approved' then 'approved'
                                when 'published' then 'published' when 'cancelled' then 'cancelled'
                                when 'closed' then 'closed' else 'saved' end,
            'draft', p_status, 'Testdaten');
  end if;
  return v_id;
end $$;

-- Gemeinsame Teile
create function pg_temp.complete() returns jsonb language sql as $$
  select '{"teaser": "Testbeschreibung (fiktiv).", "image_source": "referat", "public_transport": "possible",
           "fitness": "medium", "technique": "easy", "requirements": "Trittsicherheit (Test).",
           "equipment": "Wanderausrüstung (Test).", "confirm_license": true, "confirm_calculation": true,
           "confirm_ul_declaration": true, "confirm_emergency_card": true}'::jsonb
$$;
create function pg_temp.contact(p_person text) returns jsonb language sql as $$
  select jsonb_build_array(jsonb_build_object('person_id', p_person, 'email', 'leitung.test@example.test',
           'mobile', '0151 0000000', 'emergency_name', 'Notfallkontakt Test', 'emergency_phone', '0151 0000001'))
$$;

do $$
declare
  v_tina uuid := 'b0000000-0000-4000-8000-000000000013';
  v_alex uuid := 'b0000000-0000-4000-8000-000000000014';
  v_bernd text := 'a0000000-0000-4000-8000-000000000016';
  v_hilde text := 'a0000000-0000-4000-8000-000000000017';
  v_id uuid;
begin
  -- 1 Führungstour „Hüttentour Stubaier Alpen (Test)“, eingereicht (Beispiel Prototyp 3.5)
  perform pg_temp.save(v_tina, 'f1000000-0000-4000-8000-000000000001',
    pg_temp.complete() || '{"plan_type": "guided_tour", "title": "Hüttentour Stubaier Alpen (Test)",
      "sport": "Bergwandern", "region": "Stubaier Alpen, Tirol", "base": "Sulzenauhütte", "image_source": "own",
      "image_credit": "Foto: Test", "start_date": "2027-07-12", "end_date": "2027-07-16", "meet_time": "11:00",
      "end_time": "15:00", "meeting_point": "Talstation Grawa-Alm (Test)", "public_transport": "together",
      "accommodation": "hut", "max_walk_hours": 7, "max_ascent": 1000, "max_descent": 1000, "fitness": "high",
      "technique": "medium", "min_participants": 5, "max_participants": 8, "registration_deadline": "2027-05-15",
      "days_full": 5, "days_half": 0, "org_days": 5, "touched": ["days_full", "days_half", "org_days"]}',
    jsonb_build_array(jsonb_build_object('person_id', v_bernd, 'role', 'lead')), pg_temp.contact(v_bernd),
    '[{"mode": "rail_long", "label": "Leipzig–Innsbruck", "km_one_way": 650, "persons": 9},
      {"mode": "local_bus", "label": "Innsbruck–Grawa-Alm", "km_one_way": 30, "persons": 9}]',
    '[{"cost_group": "leader", "label": "Bahnfahrt hin und zurück", "quantity": 2, "unit_price": 105},
      {"cost_group": "leader", "label": "Halbpension Hütte", "quantity": 5, "unit_price": 45},
      {"cost_group": "leader", "label": "Übernachtung Hütte (Freiplatz 5+1)", "quantity": 5, "unit_price": 0, "is_overnight": true},
      {"cost_group": "self_paid", "label": "Übernachtung (Lager) und Halbpension auf der Hütte, Mitglieder", "quantity": 4, "unit_price": 63.5, "is_hut_half_board": true},
      {"cost_group": "self_paid", "label": "Bahnfahrt Leipzig–Neustift hin und zurück", "quantity": 1, "unit_price": 210},
      {"cost_group": "self_paid", "label": "Getränke und Tourenproviant", "quantity": 5, "unit_price": 15}]',
    'submitted');

  -- 2 Kurs „Vorstieg am Fels (Test)“, Referat Ausbildung, Entwurf (eintägig, 8 Lehreinheiten)
  perform pg_temp.save(v_alex, 'f1000000-0000-4000-8000-000000000002',
    pg_temp.complete() || '{"plan_type": "course", "title": "Vorstieg am Fels (Test)", "sport": "Klettern",
      "region": "Sächsische Schweiz", "start_date": "2027-10-15", "end_date": "2027-10-15", "meet_time": "09:00",
      "end_time": "17:00", "meeting_point": "Parkplatz (Test)", "min_participants": 4, "max_participants": 6,
      "registration_deadline": "2027-09-15"}',
    jsonb_build_array(jsonb_build_object('person_id', v_bernd, 'role', 'lead')), pg_temp.contact(v_bernd),
    '[{"mode": "car", "label": "Leipzig–Fels", "km_one_way": 150, "persons": 6, "vehicles": 2}]', '[]', 'draft');

  -- 3 Führungstour „Herbstwanderung (Test)“, freigegeben (Lizenz läuft während der Tour ab)
  v_id := pg_temp.save(v_tina, 'f1000000-0000-4000-8000-000000000003',
    pg_temp.complete() || '{"plan_type": "guided_tour", "title": "Herbstwanderung (Test)", "sport": "Bergwandern",
      "region": "Harz", "start_date": "2027-10-29", "end_date": "2027-11-01", "meet_time": "08:00",
      "meeting_point": "Leipzig Hbf (Test)", "accommodation": "hotel", "min_participants": 6, "max_participants": 10,
      "registration_deadline": "2027-09-30"}',
    jsonb_build_array(jsonb_build_object('person_id', v_bernd, 'role', 'lead')), pg_temp.contact(v_bernd),
    '[{"mode": "rail_regional", "label": "Leipzig–Wernigerode", "km_one_way": 160, "persons": 11}]', '[]', 'approved');
  perform pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
  if not exists (select 1 from public.tk_plan_rates where plan_id = v_id) then
    insert into public.tk_plan_rates (plan_id, rate_key, label, value, percent, fixed, active, valid_from)
    select v_id, r.rate_key, r.label, r.value, r.percent, r.fixed, r.active, r.valid_from
      from public.ad_rates_at(date '2027-10-29') r
     where r.rate_group <> 'remuneration' or r.rate_key in ('rTL', 'rTLh', 'rH', 'rHh', 'rOrg', 'rLE');
    update public.tk_plans set rates_frozen_on = current_date where id = v_id;
  end if;

  -- 4 Führungstour „Novembertour (Test)“, Entwurf (Lizenz abgelaufen → Helfersatz)
  perform pg_temp.save(v_tina, 'f1000000-0000-4000-8000-000000000004',
    '{"plan_type": "guided_tour", "title": "Novembertour (Test)", "sport": "Wandern", "start_date": "2027-11-02",
      "end_date": "2027-11-02", "meet_time": "09:00", "end_time": "16:00", "min_participants": 5,
      "max_participants": 10}',
    jsonb_build_array(jsonb_build_object('person_id', v_bernd, 'role', 'lead')), null, '[]', '[]', 'draft');

  -- 5 Gemeinschaftstour „Sächsische Schweiz (Test)“, in Yolawo angelegt (Organisationspauschale 3 × 10 €)
  perform pg_temp.save(v_tina, 'f1000000-0000-4000-8000-000000000005',
    pg_temp.complete() || '{"plan_type": "community_tour", "title": "Sächsische Schweiz (Test)",
      "community_reason": "Gemeinsames Wochenende ohne Führung (Test).", "sport": "Wandern",
      "region": "Sächsische Schweiz", "start_date": "2027-09-10", "end_date": "2027-09-12", "meet_time": "08:30",
      "meeting_point": "Leipzig Hbf (Test)", "accommodation": "self_catering", "min_participants": 4,
      "max_participants": 12, "registration_deadline": "2027-08-15"}',
    jsonb_build_array(jsonb_build_object('person_id', v_hilde, 'role', 'lead')), pg_temp.contact(v_hilde),
    '[{"mode": "rail_regional", "label": "Leipzig–Bad Schandau", "km_one_way": 150, "persons": 13}]',
    '[{"cost_group": "self_paid", "label": "Übernachtung Selbstversorgerhütte", "quantity": 2, "unit_price": 20}]',
    'published');

  -- 6 Führungstour „Absage (Test)“, abgesagt vor 20 Tagen, Kontaktdaten vorhanden
  v_id := pg_temp.save(v_tina, 'f1000000-0000-4000-8000-000000000006',
    '{"plan_type": "guided_tour", "title": "Absage (Test)", "sport": "Wandern", "start_date": "2027-06-05",
      "end_date": "2027-06-05", "min_participants": 6, "max_participants": 10}',
    jsonb_build_array(jsonb_build_object('person_id', v_hilde, 'role', 'lead')), pg_temp.contact(v_hilde),
    '[]', '[]', 'draft');
  if (select status from public.tk_plans where id = v_id) = 'draft' then
    perform set_config('tk.status_change', 'on', true);
    update public.tk_plans set status = 'cancelled', cancelled_at = now() - interval '20 days',
           cancel_reason = 'Mindestteilnehmerzahl nicht erreicht' where id = v_id;
    perform set_config('tk.status_change', '', true);
    insert into public.tk_plan_history (plan_id, event, from_status, to_status, comment)
    values (v_id, 'cancelled', 'draft', 'cancelled', 'Mindestteilnehmerzahl nicht erreicht');
  end if;

  -- 7 Führungstour „Familienwanderung (Test)“, Entwurf, Tagestour ohne Beitrag
  perform pg_temp.save(v_tina, 'f1000000-0000-4000-8000-000000000007',
    '{"plan_type": "guided_tour", "title": "Familienwanderung (Test)", "sport": "Wandern",
      "target_groups": ["Familienwanderungen"], "start_date": "2027-04-18", "end_date": "2027-04-18",
      "meet_time": "10:00", "end_time": "15:00", "no_fee": true, "min_participants": 4, "max_participants": 15}',
    jsonb_build_array(jsonb_build_object('person_id', v_bernd, 'role', 'lead')), null,
    '[{"mode": "local_bus", "label": "Leipzig–Rand", "km_one_way": 20, "persons": 16}]', '[]', 'draft');

  -- 8 Führungstour „Alte Tour (Test)“, abgeschlossen, Kontaktdaten gelöscht
  v_id := pg_temp.save(v_tina, 'f1000000-0000-4000-8000-000000000008',
    '{"plan_type": "guided_tour", "title": "Alte Tour (Test)", "sport": "Wandern", "start_date": "2026-07-12",
      "end_date": "2026-07-12", "min_participants": 5, "max_participants": 10}',
    jsonb_build_array(jsonb_build_object('person_id', v_hilde, 'role', 'lead')), null, '[]', '[]', 'closed');
  update public.tk_plans set contacts_purged_at = coalesce(contacts_purged_at, now() - interval '30 days')
   where id = v_id;

  -- 9 Kurs „Grundkurs Hochtouren (Test)“, Entwurf, mehrtägig ohne Lehreinheiten (R22)
  perform pg_temp.save(v_alex, 'f1000000-0000-4000-8000-000000000009',
    pg_temp.complete() || '{"plan_type": "course", "title": "Grundkurs Hochtouren (Test)", "sport": "Hochtour",
      "region": "Ötztaler Alpen", "start_date": "2027-07-01", "end_date": "2027-07-03", "meet_time": "08:00",
      "meeting_point": "Vent (Test)", "accommodation": "hut", "min_participants": 4, "max_participants": 6,
      "registration_deadline": "2027-05-31"}',
    jsonb_build_array(jsonb_build_object('person_id', v_bernd, 'role', 'lead'),
                      jsonb_build_object('person_id', v_hilde, 'role', 'helper')), pg_temp.contact(v_bernd),
    '[{"mode": "rail_long", "label": "Leipzig–Ötztal", "km_one_way": 700, "persons": 8}]', '[]', 'draft');

  -- Ergebnisse mit eingefrorenem bzw. aktuellem Satzstand neu rechnen
  perform pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
  perform public.tk_calculate(p.id) from public.tk_plans p where p.client_request_id::text like 'f1000000-%';
  perform set_config('request.jwt.claims', '', true);
end;
$$;
