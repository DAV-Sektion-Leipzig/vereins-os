-- Testdaten Bereich Budget (spec.md DS v0.2 Abschnitt 9, DT17) – nur fiktive Daten, nur für den lokalen Stack und
-- vereins-os-test. Wird von supabase/seed.sh nach seed.sql geladen, wenn SEED_WITH_DS=1 gesetzt ist (nicht in CI; die
-- pgTAP-Tests legen ihre Daten selbst an). Idempotent: läuft nur, solange es für das laufende Jahr keinen Finanzplan gibt.
--
-- Vorstand (b…03) bekommt die Vorlage „Budgetpflege“ und legt über die Funktionen der Datenbank an: Finanzplan des
-- laufenden Jahres, Gesamtbudgets mit Sichtbarkeit, Zuordnungsregeln und einen DATEV-Export mit Buchungen bis 30.09.
-- Kim Kinderjugend (b…32) trägt einen Hinweis ein und beantragt eine Umschichtung; Rita Referentin (b…09) schlägt eine
-- Umschlüsselung vor. Buchungstexte ohne Personennamen.

insert into public.ad_template_assignments (person_id, template_id)
select 'a0000000-0000-4000-8000-000000000003', t.id from public.ad_templates t
 where t.name = 'Budgetpflege'
   and not exists (select 1 from public.ad_template_assignments a
                    where a.person_id = 'a0000000-0000-4000-8000-000000000003' and a.template_id = t.id and a.revoked_at is null);

do $$
declare
  v_y smallint := extract(year from current_date)::smallint;
  v_item record;
  v_groups text[] := array[
    -- Ausgaben in der Reihenfolge des Finanzplans → Gesamtbudget
    'Kinder und Jugend', 'Kinder und Jugend', 'Kinder und Jugend', 'Klettern', 'Klettern', 'Klettern',
    'Veranstaltungen', 'Geschäftsstelle', 'Vereinszentrum'];
  v_i int := 0;
begin
  if exists (select 1 from public.fi_budget_plans where year = v_y) then
    raise notice 'Finanzplan % gibt es schon, Seed Budget übersprungen.', v_y;
    return;
  end if;
  perform set_config('request.jwt.claims',
    json_build_object('sub', 'b0000000-0000-4000-8000-000000000003', 'role', 'authenticated')::text, true);

  perform public.fi_budget_plan_import(v_y, replace($j$ {"file": "Finanzen Sektion Test YYYY.xlsx", "sheet": "Finanzplan YYYY",
    "sums": {"income": 98000, "expense": 67000},
    "items": [
      {"kind": "income", "name": "Mitgliedsbeiträge", "plan": 90000, "row": 5},
      {"kind": "income", "name": "Kursgebühren", "plan": 8000, "row": 6},
      {"kind": "expense", "name": "Vergütung Aktive", "plan": 24000, "row": 5},
      {"kind": "expense", "name": "Fahrten und Freizeiten", "plan": 9000, "row": 6},
      {"kind": "expense", "name": "Material Jugend", "plan": 3000, "row": 7},
      {"kind": "expense", "name": "Vergütung Aktive", "plan": 12000, "row": 8},
      {"kind": "expense", "name": "Material Klettern", "plan": 2500, "row": 9},
      {"kind": "expense", "name": "Wettkämpfe", "plan": 1500, "row": 10},
      {"kind": "expense", "name": "Sektionsfest", "plan": 4000, "row": 11},
      {"kind": "expense", "name": "Büro", "plan": 6000, "row": 12},
      {"kind": "expense", "name": "Planung Vereinszentrum", "plan": 5000, "row": 13}]} $j$, 'YYYY', v_y::text)::jsonb);

  -- Gesamtbudgets bilden (plan.md P8)
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
      ('6400', 'Veranstaltungen', 'Sektionsfest', 'ok', 'Veranstaltungen'),
      ('6300 1 bis 6399 1', 'Geschäftsstelle', 'Büro', 'ok', 'Geschäftsstelle'),
      ('6500', 'Vereinszentrum', 'Planung Vereinszentrum', 'ok', 'Planungskosten'),
      ('4000', 'Mitgliedsbeiträge', 'Mitgliedsbeiträge', 'ok', 'Beiträge'),
      ('4100 5', 'Kursgebühren', 'Kursgebühren', 'ok', 'Kursgebühren')) as r (konto, grp, item, status, label)
    join public.fi_budget_groups g on g.year = v_y and g.name = r.grp
    join public.fi_budget_items i on i.group_id = g.id and i.name = r.item;
  perform public.fi_budget_rule_save(jsonb_build_object('year', v_y, 'account_text', '4000-7999', 'status', 'open',
    'note', 'Auffangregel Erfolgskonten'), 'Seed');

  -- DATEV-Export (fiktiv) mit Kontenübersicht und Buchungsliste
  perform public.fi_budget_import(v_y, replace($j$ {"name": "Kontenblaetter YYYY-09.csv", "info": "Mandant Sektion Test · Export fiktiv",
    "overview": [{"konto": "6326 6", "eb": 0, "soll": 15600, "haben": 0}, {"konto": "6330 7", "eb": 0, "soll": 2380, "haben": 0}],
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
      {"line": 23, "konto": "6326 6", "datum": "YYYY-01-01", "text": "EB-Wert", "beleg": "", "soll": 0},
      {"line": 24, "konto": "1200 0", "datum": "YYYY-01-15", "text": "Beiträge Januar", "beleg": "B01", "soll": 61000}]} $j$, 'YYYY', v_y::text)::jsonb);

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
  raise notice 'Seed Budget % angelegt.', v_y;
end;
$$;
