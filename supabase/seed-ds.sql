-- Testdaten Bereich Budget (spec.md DS v0.2 Abschnitt 9, DT17) – nur fiktive Daten, nur für den lokalen Stack und
-- vereins-os-test. Wird von supabase/seed.sh nach seed.sql geladen, wenn SEED_WITH_DS=1 gesetzt ist (nicht in CI; die
-- pgTAP-Tests legen ihre Daten selbst an). Idempotent: Die Budgetdaten entstehen nur, solange es für das laufende Jahr
-- keinen Finanzplan gibt. Buchungstexte ohne Personennamen.
--
-- Testzugänge (spec 9 Nr. 9, Vier-Augen-Prinzip): Vorstand Test (b…03, fiktive:r 1. Vorsitzende:r) und
-- Schatzmeisterin Test (b…703, test.schatzmeisterin@dav-leipzig.de) mit der Vorlage „Budgetpflege“.
--
-- Fälle aus spec 9 (Namen der Budgetposten wie im Seed, nicht wie in spec 9; die Fälle sind dieselben):
--  1 Gesamtbudget Kinder und Jugend (Referat) mit drei Ausgaben; Klettern (Referat) für Rita Referentin
--  2 Leistungssport (Referat) mit zweitem „Vergütung Aktive“ (doppelter Name, R10)
--  3 Veranstaltungen (alle), Vereinszentrum und Geschäftsstelle (ohne Referat)
--  4 Regeln: Einzelkonto, Hauptkonto, Bereich 6300 1–6399 1, Auffangregel 4000-7999 ohne Posten, Einzelbuchung
--    „Startgebühr Testcup“ → Leistungssport Kosten
--  5 Import laufendes Jahr: Doppelbuchung über Sammelkonto, Storno, Umbuchung, EB-Wert, Buchung des Vorjahres, Konto mit
--    fehlender Einzelbuchung (6340 6); Import des Folgejahres (Finanzplan J+1, Regeln aus dem Vorjahr)
--  6 Umschichtung von Kim Kinderjugend (Material Jugend → Fahrten und Freizeiten); Umschichtung von Vorstand Test, die
--    nur Schatzmeisterin Test bestätigen kann
--  7 Umschlüsselungs-Vorschlag von Rita Referentin
--  8 Auszahlungsrunde 901 freigegeben und gebucht (Abgleich), Runde 902 freigegeben, nicht gebucht (Vorschau K&J)

-- Testzugang Schatzmeisterin Test und Vorlage „Budgetpflege“ für Vorstand Test und Schatzmeisterin Test
insert into public.ea_persons (id, first_name, last_name, kind, created_in) values
  ('a0000000-0000-4000-8000-000000000703', 'Schatzmeisterin', 'Test', 'human', 'AD')
on conflict (id) do nothing;

insert into public.ad_accesses (person_id, login_email, status, is_emergency, last_invited_at, locked_at) values
  ('a0000000-0000-4000-8000-000000000703', 'test.schatzmeisterin@dav-leipzig.de', 'active', false, now() - interval '30 days', null)
on conflict (person_id) do nothing;

insert into public.ad_template_assignments (person_id, template_id)
select p, t.id
  from public.ad_templates t,
       unnest(array['a0000000-0000-4000-8000-000000000003', 'a0000000-0000-4000-8000-000000000703']::uuid[]) p
 where t.name = 'Budgetpflege'
   and not exists (select 1 from public.ad_template_assignments a
                    where a.person_id = p and a.template_id = t.id and a.revoked_at is null);

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, invited_at, banned_until,
  raw_app_meta_data, raw_user_meta_data,
  confirmation_token, recovery_token, email_change_token_new, email_change,
  created_at, updated_at
)
select '00000000-0000-0000-0000-000000000000', 'b0000000-0000-4000-8000-000000000703', 'authenticated', 'authenticated',
       'test.schatzmeisterin@dav-leipzig.de', extensions.crypt(:'test_password', extensions.gen_salt('bf')),
       now(), now() - interval '30 days', null,
       '{"provider": "email", "providers": ["email"]}'::jsonb, '{}'::jsonb,
       '', '', '', '',
       now() - interval '30 days', now()
on conflict (id) do nothing;

insert into auth.identities (id, user_id, provider_id, provider, identity_data, last_sign_in_at, created_at, updated_at)
select gen_random_uuid(), u.id, u.id::text, 'email',
       jsonb_build_object('sub', u.id::text, 'email', u.email, 'email_verified', true),
       null, now(), now()
  from auth.users u
 where u.id = 'b0000000-0000-4000-8000-000000000703'
on conflict (provider_id, provider) do nothing;

update public.ad_accesses set auth_user_id = 'b0000000-0000-4000-8000-000000000703'
 where person_id = 'a0000000-0000-4000-8000-000000000703' and auth_user_id is null;

do $$
declare
  v_y smallint := extract(year from current_date)::smallint;
  v_n smallint := extract(year from current_date)::smallint + 1;
  v_item record;
  v_groups text[] := array[
    -- Ausgaben in der Reihenfolge des Finanzplans → Gesamtbudget
    'Kinder und Jugend', 'Kinder und Jugend', 'Kinder und Jugend', 'Klettern', 'Klettern', 'Klettern',
    'Leistungssport', 'Leistungssport', 'Veranstaltungen', 'Geschäftsstelle', 'Vereinszentrum'];
  v_i int := 0;
  v_plan text := $j$ {"file": "Finanzen Sektion Test YYYY.xlsx", "sheet": "Finanzplan YYYY",
    "sums": {"income": 98000, "expense": 79000},
    "items": [
      {"kind": "income", "name": "Mitgliedsbeiträge", "plan": 90000, "row": 5},
      {"kind": "income", "name": "Kursgebühren", "plan": 8000, "row": 6},
      {"kind": "expense", "name": "Vergütung Aktive", "plan": 24000, "row": 5},
      {"kind": "expense", "name": "Fahrten und Freizeiten", "plan": 9000, "row": 6},
      {"kind": "expense", "name": "Material Jugend", "plan": 3000, "row": 7},
      {"kind": "expense", "name": "Vergütung Aktive", "plan": 12000, "row": 8},
      {"kind": "expense", "name": "Material Klettern", "plan": 2500, "row": 9},
      {"kind": "expense", "name": "Wettkämpfe", "plan": 1500, "row": 10},
      {"kind": "expense", "name": "Vergütung Aktive", "plan": 8000, "row": 11},
      {"kind": "expense", "name": "Leistungssport Kosten", "plan": 4000, "row": 12},
      {"kind": "expense", "name": "Sektionsfest", "plan": 4000, "row": 13},
      {"kind": "expense", "name": "Büro", "plan": 6000, "row": 14},
      {"kind": "expense", "name": "Planung Vereinszentrum", "plan": 5000, "row": 15}]} $j$;
begin
  if exists (select 1 from public.fi_budget_plans where year = v_y) then
    raise notice 'Finanzplan % gibt es schon, Seed Budget übersprungen.', v_y;
    return;
  end if;
  perform set_config('request.jwt.claims',
    json_build_object('sub', 'b0000000-0000-4000-8000-000000000003', 'role', 'authenticated')::text, true);

  perform public.fi_budget_plan_import(v_y, replace(v_plan, 'YYYY', v_y::text)::jsonb);

  -- Gesamtbudgets bilden (plan.md P8); Sichtbarkeit nach Startwert (R22), Veranstaltungen für alle
  for v_item in select i.id from public.fi_budget_items i where i.year = v_y and i.kind = 'expense' order by i.sort_order loop
    v_i := v_i + 1;
    perform public.fi_budget_item_move(v_item.id, v_groups[v_i]);
  end loop;
  perform public.fi_budget_group_set(g.id, 'all', null) from public.fi_budget_groups g where g.year = v_y and g.name = 'Veranstaltungen';

  -- Zuordnungsregeln (R2)
  perform public.fi_budget_rule_save(jsonb_build_object('year', v_y, 'account_text', r.konto, 'item_id', i.id,
            'status', r.status, 'account_label', r.label), 'Seed')
    from (values
      ('6326 6', 'Kinder und Jugend', 'Vergütung Aktive', 'ok', 'Übungsleitervergütung Jugend'),
      ('6340 6', 'Kinder und Jugend', 'Fahrten und Freizeiten', 'ok', 'Fahrtkosten Jugend'),
      ('6330 6', 'Kinder und Jugend', 'Material Jugend', 'ok', 'Material Jugend'),
      ('6326 7', 'Klettern', 'Vergütung Aktive', 'ok', 'Übungsleitervergütung Klettern'),
      ('6330 7', 'Klettern', 'Material Klettern', 'ok', 'Material Klettern'),
      ('6350 7', 'Klettern', 'Wettkämpfe', 'uncertain', 'Startgelder'),
      ('6326 8', 'Leistungssport', 'Vergütung Aktive', 'ok', 'Übungsleitervergütung Leistungssport'),
      ('6360 8', 'Leistungssport', 'Leistungssport Kosten', 'ok', 'Trainingslager'),
      ('6400', 'Veranstaltungen', 'Sektionsfest', 'ok', 'Veranstaltungen'),
      ('6300 1 bis 6399 1', 'Geschäftsstelle', 'Büro', 'ok', 'Geschäftsstelle'),
      ('6500', 'Vereinszentrum', 'Planung Vereinszentrum', 'ok', 'Planungskosten'),
      ('4000', 'Mitgliedsbeiträge', 'Mitgliedsbeiträge', 'ok', 'Beiträge'),
      ('4100 5', 'Kursgebühren', 'Kursgebühren', 'ok', 'Kursgebühren')) as r (konto, grp, item, status, label)
    join public.fi_budget_groups g on g.year = v_y and g.name = r.grp
    join public.fi_budget_items i on i.group_id = g.id and i.name = r.item;
  perform public.fi_budget_rule_save(jsonb_build_object('year', v_y, 'account_text', '4000-7999', 'status', 'open',
    'note', 'Auffangregel Erfolgskonten'), 'Seed');
  -- Einzelbuchung: Startgebühr Testcup gehört zu Leistungssport, obwohl sie auf dem Konto der Wettkämpfe Klettern steht
  perform public.fi_budget_rule_save(jsonb_build_object('year', v_y, 'account_text', '6350 7', 'item_id', i.id,
            'b_date', make_date(v_y, 6, 15), 'b_receipt', 'W02', 'b_amount', 180, 'b_side', 'S',
            'b_text', 'Startgebühr Testcup', 'reason', 'Startgebühr des Leistungssports'), 'Seed')
    from public.fi_budget_items i join public.fi_budget_groups g on g.id = i.group_id
   where i.year = v_y and g.name = 'Leistungssport' and i.name = 'Leistungssport Kosten';

  -- DATEV-Export (fiktiv) mit Kontenübersicht und Buchungsliste
  perform public.fi_budget_import(v_y, replace(replace($j$ {"name": "Kontenblaetter YYYY-09.csv", "info": "Mandant Sektion Test · Export fiktiv",
    "overview": [{"konto": "6326 6", "eb": 0, "soll": 15600, "haben": 0}, {"konto": "6330 7", "eb": 0, "soll": 2580, "haben": 0},
                 {"konto": "6340 6", "eb": 0, "soll": 6300, "haben": 150}],
    "rows": [
      {"line": 1, "konto": "4000 0", "datum": "YYYY-01-15", "text": "Beiträge Januar", "beleg": "B01", "haben": 61000, "kost1": "1"},
      {"line": 2, "konto": "4000 0", "datum": "YYYY-02-15", "text": "Beiträge Februar", "beleg": "B02", "haben": 9200, "kost1": "1"},
      {"line": 3, "konto": "4000 0", "datum": "YYYY-03-20", "text": "Rücklastschriften", "beleg": "B03", "soll": 640, "kost1": "1"},
      {"line": 4, "konto": "4100 5", "datum": "YYYY-04-10", "text": "Kursgebühren Frühjahr", "beleg": "K01", "haben": 3900, "kost1": "3"},
      {"line": 5, "konto": "6326 6", "datum": "YYYY-02-05", "text": "Übungsleitervergütung Jugend 2. Halbjahr Vorjahr", "beleg": "U01", "soll": 7800, "kost1": "1"},
      {"line": 6, "konto": "6326 6", "datum": "YYYY-08-05", "text": "Übungsleitervergütung Jugend 1. Halbjahr", "beleg": "U02", "soll": 7800, "kost1": "1"},
      {"line": 7, "konto": "6340 6", "datum": "YYYY-05-12", "text": "Busfahrt Jugendgruppe", "beleg": "F01", "soll": 1850, "kost1": "1"},
      {"line": 8, "konto": "6340 6", "datum": "YYYY-07-20", "text": "Sommerfreizeit Unterkunft", "beleg": "F02", "soll": 4200, "kost1": "1"},
      {"line": 9, "konto": "6330 6", "datum": "YYYY-03-02", "text": "Seile und Gurte Jugend", "beleg": "M01", "soll": 2650, "kost1": "1"},
      {"line": 10, "konto": "6326 7", "datum": "YYYY-02-05", "text": "Übungsleitervergütung Klettern 2. Halbjahr Vorjahr", "beleg": "U03", "soll": 4100, "kost1": "1"},
      {"line": 11, "konto": "6326 7", "datum": "YYYY-08-05", "text": "Übungsleitervergütung Klettern 1. Halbjahr", "beleg": "U04", "soll": 4300, "kost1": "1"},
      {"line": 12, "konto": "6330 7", "datum": "YYYY-04-18", "text": "Klettergriffe", "beleg": "M02", "soll": 1480, "kost1": "1"},
      {"line": 13, "konto": "6330 7", "datum": "YYYY-06-09", "text": "Startgebühr Bouldercup", "beleg": "M03", "soll": 240, "kost1": "1"},
      {"line": 14, "konto": "6330 7", "datum": "YYYY-09-11", "text": "Expressschlingen", "beleg": "M04", "soll": 660, "kost1": "1"},
      {"line": 15, "konto": "6350 7", "datum": "YYYY-05-25", "text": "Startgelder Wettkampf", "beleg": "W01", "soll": 380, "kost1": "1"},
      {"line": 16, "konto": "6400 0", "datum": "YYYY-06-28", "text": "Sektionsfest Getränke", "beleg": "V01", "soll": 1320, "kost1": "4"},
      {"line": 17, "konto": "6400 0", "datum": "YYYY-06-30", "text": "Sektionsfest Zeltmiete", "beleg": "V02", "soll": 980, "kost1": "4"},
      {"line": 18, "konto": "6310 1", "datum": "YYYY-01-31", "text": "Miete Geschäftsstelle Januar", "beleg": "G01", "soll": 450, "kost1": "1"},
      {"line": 19, "konto": "6310 1", "datum": "YYYY-02-28", "text": "Miete Geschäftsstelle Februar", "beleg": "G02", "soll": 450, "kost1": "1"},
      {"line": 20, "konto": "6310 1", "datum": "YYYY-03-31", "text": "Miete Geschäftsstelle März", "beleg": "G03", "soll": 450, "kost1": "1"},
      {"line": 21, "konto": "6815 1", "datum": "YYYY-04-02", "text": "Bürobedarf", "beleg": "G04", "soll": 312.5, "kost1": "1"},
      {"line": 22, "konto": "6500 0", "datum": "YYYY-09-30", "text": "Planungsbüro Abschlag", "beleg": "Z01", "soll": 2800, "kost1": "2"},
      {"line": 23, "konto": "6326 6", "datum": "YYYY-01-01", "text": "EB-Wert", "beleg": "", "gegenkonto": "9000", "gegenkonto_label": "Saldenvorträge", "soll": 0},
      {"line": 24, "konto": "1200 0", "datum": "YYYY-01-15", "text": "Beiträge Januar", "beleg": "B01", "soll": 61000},
      {"line": 25, "konto": "6350 7", "datum": "YYYY-06-15", "text": "Startgebühr Testcup", "beleg": "W02", "soll": 180, "kost1": "1"},
      {"line": 26, "konto": "1590 0", "datum": "YYYY-06-15", "text": "Startgebühr Testcup", "beleg": "W02", "haben": 180},
      {"line": 27, "konto": "6340 6", "datum": "YYYY-05-20", "text": "Storno Busfahrt", "beleg": "F03", "haben": 150, "kost1": "1"},
      {"line": 28, "konto": "6330 6", "datum": "YYYY-06-01", "text": "Umbuchung Material an Klettern", "beleg": "UM1", "haben": 200, "kost1": "1"},
      {"line": 29, "konto": "6330 7", "datum": "YYYY-06-01", "text": "Umbuchung Material von Jugend", "beleg": "UM1", "soll": 200, "kost1": "1"},
      {"line": 30, "konto": "6326 6", "datum": "PREV-12-20", "text": "Übungsleitervergütung Dezember", "beleg": "U00", "soll": 500, "kost1": "1"},
      {"line": 31, "konto": "6326 8", "datum": "YYYY-08-06", "text": "Übungsleitervergütung Leistungssport 1. Halbjahr", "beleg": "U06", "soll": 3900, "kost1": "1"},
      {"line": 32, "konto": "6360 8", "datum": "YYYY-04-12", "text": "Trainingslager Leistungssport", "beleg": "L01", "soll": 2100, "kost1": "1"}]} $j$,
    'YYYY', v_y::text), 'PREV', (v_y - 1)::text)::jsonb);

  -- Folgejahr: Finanzplan, Sichtbarkeit und Regeln aus dem Vorjahr (US-FI-29), erste Buchungen (Vorjahresvergleich)
  perform public.fi_budget_plan_import(v_n, replace(replace(v_plan, 'YYYY', v_n::text), '"plan": 9000,', '"plan": 9500,')
    ::jsonb || jsonb_build_object('sums', jsonb_build_object('income', 98000, 'expense', 79500)));
  perform public.fi_budget_year_from_previous(v_n, true);
  perform public.fi_budget_import(v_n, replace($j$ {"name": "Kontenblaetter YYYY-03.csv", "info": "Mandant Sektion Test · Export fiktiv",
    "rows": [
      {"line": 1, "konto": "4000 0", "datum": "YYYY-01-15", "text": "Beiträge Januar", "beleg": "B01", "haben": 62500, "kost1": "1"},
      {"line": 2, "konto": "6326 6", "datum": "YYYY-02-05", "text": "Übungsleitervergütung Jugend 2. Halbjahr Vorjahr", "beleg": "U01", "soll": 8100, "kost1": "1"},
      {"line": 3, "konto": "6330 6", "datum": "YYYY-03-10", "text": "Helme Jugend", "beleg": "M01", "soll": 900, "kost1": "1"},
      {"line": 4, "konto": "6310 1", "datum": "YYYY-01-31", "text": "Miete Geschäftsstelle Januar", "beleg": "G01", "soll": 460, "kost1": "1"}]} $j$,
    'YYYY', v_n::text)::jsonb);

  -- Umschichtung von Vorstand Test (nicht direkt): nur Schatzmeisterin Test darf sie bestätigen (Vier-Augen-Prinzip)
  perform public.fi_budget_realloc_request(f.id, t.id, 300, 'Neue Griffe für die Wand.')
    from public.fi_budget_items f join public.fi_budget_groups g on g.id = f.group_id
    join public.fi_budget_items t on t.group_id = g.id and t.name = 'Material Klettern'
   where f.year = v_y and g.name = 'Klettern' and f.name = 'Wettkämpfe';

  -- Referent:innen: Hinweis, Umschichtung, Umschlüsselungs-Vorschlag
  perform set_config('request.jwt.claims',
    json_build_object('sub', 'b0000000-0000-4000-8000-000000000032', 'role', 'authenticated')::text, true);
  perform public.fi_budget_note_save(i.id, 'Herbstfreizeit noch offen, Anzahlung im Oktober.')
    from public.fi_budget_items i join public.fi_budget_groups g on g.id = i.group_id
   where i.year = v_y and g.name = 'Kinder und Jugend' and i.name = 'Fahrten und Freizeiten';
  perform public.fi_budget_realloc_request(f.id, t.id, 400, 'Material reicht, Freizeit wird teurer.')
    from public.fi_budget_items f join public.fi_budget_groups g on g.id = f.group_id
    join public.fi_budget_items t on t.group_id = g.id and t.name = 'Fahrten und Freizeiten'
   where f.year = v_y and g.name = 'Kinder und Jugend' and f.name = 'Material Jugend';

  perform set_config('request.jwt.claims',
    json_build_object('sub', 'b0000000-0000-4000-8000-000000000009', 'role', 'authenticated')::text, true);
  perform public.fi_budget_proposal_create(a.id, t.id, 'Startgebühr gehört zu den Wettkämpfen.')
    from public.fi_budget_assigned a
    join public.fi_budget_items t on t.year = v_y and t.name = 'Wettkämpfe'
   where a.year = v_y and a.booking_text = 'Startgebühr Bouldercup';

  perform set_config('request.jwt.claims', '', true);

  -- Auszahlungsrunden (R18): 901 gebucht (Buchung „Übungsleitervergütung Jugend 1. Halbjahr“ am 05.08.), 902 offen
  insert into public.ea_persons (id, first_name, last_name, kind, created_in) values
    ('a0000000-0000-4000-8000-000000000701', 'Toni', 'Trainertest', 'human', 'AD'),
    ('a0000000-0000-4000-8000-000000000702', 'Uli', 'Helfertest', 'human', 'AD')
  on conflict (id) do nothing;
  insert into public.fi_payout_runs (id, year, half, number, status, execution_date, msg_id, released_at, total, line_count)
  values ('c7000000-0000-4000-8000-000000000901', v_y, 1, 901, 'released', make_date(v_y, 7, 25), 'SEED-DS-901', now(), 7800, 1),
         ('c7000000-0000-4000-8000-000000000902', v_y, 1, 902, 'released', make_date(v_y, 10, 15), 'SEED-DS-902', now(), 1250, 1)
  on conflict (id) do nothing;
  insert into public.fi_settlements (id, person_id, year, half, status, amount, payout_run_id)
  values ('c7000000-0000-4000-8000-000000000911', 'a0000000-0000-4000-8000-000000000701', v_y, 1, 'paid', 7800,
          'c7000000-0000-4000-8000-000000000901'),
         ('c7000000-0000-4000-8000-000000000912', 'a0000000-0000-4000-8000-000000000702', v_y, 1, 'paid', 1250,
          'c7000000-0000-4000-8000-000000000902')
  on conflict (id) do nothing;
  insert into public.fi_payout_lines (run_id, settlement_id, person_id, referat_id, group_label, amount, remittance,
    end_to_end_id, sort_no)
  select v.run_id, v.settlement_id, v.person_id, r.id, 'Kinder und Jugend', v.amount, 'Verguetung 1. Halbjahr', v.e2e, 1
    from (values ('c7000000-0000-4000-8000-000000000901'::uuid, 'c7000000-0000-4000-8000-000000000911'::uuid,
                  'a0000000-0000-4000-8000-000000000701'::uuid, 7800::numeric, 'SEED-DS-901-1'),
                 ('c7000000-0000-4000-8000-000000000902', 'c7000000-0000-4000-8000-000000000912',
                  'a0000000-0000-4000-8000-000000000702', 1250, 'SEED-DS-902-1')) as v (run_id, settlement_id, person_id, amount, e2e)
    join public.ea_referate r on r.name = 'Kinder und Jugend'
  on conflict do nothing;

  raise notice 'Seed Budget % und % angelegt.', v_y, v_n;
end;
$$;
