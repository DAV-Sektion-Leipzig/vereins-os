-- Bereich Budget (spec.md DS v0.2, T5–T13): Finanzplan, Gesamtbudgets, Regeln nach Vorrang (R2), Betrag nach Art (R3),
-- DATEV-Import mit Ausschlüssen und Prüfung (R1, R4, R8, R9), Lesefunktionen und Rechte (R6, R7, R12–R14, R20),
-- Hinweise, Umschichtungen, Vorschläge, Umschlüsseln, Vorschau (R15–R18), Zu tun, Löschlauf (R19).
-- Alle Zahlen und Texte fiktiv. Jahr J = laufendes Jahr, J+1 für den Vorjahresvergleich.
-- Seed: b…02 Geschäftsstelle, b…03 Vorstand, b…09 Rita Referentin (Klettern), b…32 Kim Kinderjugend.
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
create function pg_temp.y() returns smallint language sql as $$ select extract(year from current_date)::smallint $$;
-- JSON mit Platzhaltern YYYY (Jahr J) und YYNN (J+1)
create function pg_temp.j(p text) returns jsonb language sql as $$
  select replace(replace(p, 'YYYY', pg_temp.y()::text), 'YYNN', (pg_temp.y() + 1)::text)::jsonb
$$;
create function pg_temp.item(p_year smallint, p_group text, p_name text) returns uuid language sql security definer as $$
  select i.id from public.fi_budget_items i join public.fi_budget_groups g on g.id = i.group_id
   where i.year = p_year and g.name = p_group and i.name = p_name and i.removed_at is null
$$;
create function pg_temp.booking(p_text text) returns uuid language sql security definer as $$
  select a.id from public.fi_budget_assigned a where a.year = pg_temp.y() and a.booking_text = p_text
$$;

create temp table plan_src (v jsonb);
insert into plan_src values (pg_temp.j($$ {"file": "Finanzplan.xlsx", "sheet": "Finanzplan YYYY",
  "sums": {"income": 5000, "expense": 3840},
  "items": [
    {"kind": "income", "name": "Mitgliedsbeiträge", "plan": 5000, "row": 4},
    {"kind": "expense", "name": "Material Klettern", "plan": 100, "row": 10},
    {"kind": "expense", "name": "Vergütung Aktive", "plan": 1000, "row": 11},
    {"kind": "expense", "name": "Fahrtkosten", "plan": 300, "row": 12},
    {"kind": "expense", "name": "Vergütung Aktive", "plan": 2000, "row": 13},
    {"kind": "expense", "name": "Veranstaltungen", "plan": 400, "row": 14},
    {"kind": "expense", "name": "Vereinszentrum", "plan": 40, "row": 15},
    {"kind": "expense", "name": "Sonstiges", "plan": 0, "row": 16}]} $$));
grant select on plan_src to authenticated;

-- Fiktiver DATEV-Export mit allen Sonderfällen
create temp table datev (v jsonb);
insert into datev values (pg_temp.j($$ {"name": "Kontenblatt.csv", "info": "Export fiktiv",
  "overview": [{"konto": "6326 3", "eb": 0, "soll": 300, "haben": 20}, {"konto": "6330 5", "eb": 0, "soll": 150, "haben": 0}],
  "rows": [
    {"line": 1, "konto": "6326 3", "datum": "YYYY-02-10", "text": "Übungsleiter Februar", "beleg": "A1", "soll": 300},
    {"line": 2, "konto": "6326 3", "datum": "YYYY-04-01", "text": "Storno Übungsleiter", "beleg": "A2", "haben": 20},
    {"line": 3, "konto": "6330 5", "datum": "YYYY-03-05", "text": "Seile", "beleg": "B1", "soll": 100},
    {"line": 4, "konto": "6350 2", "datum": "YYYY-03-06", "text": "Reinigung", "beleg": "C1", "soll": 50},
    {"line": 5, "konto": "6340 1", "datum": "YYYY-03-07", "text": "Fahrt Jugend", "beleg": "D1", "soll": 40, "kost1": "20"},
    {"line": 6, "konto": "6340 1", "datum": "YYYY-03-08", "text": "Fahrt Fest", "beleg": "D2", "soll": 70},
    {"line": 7, "konto": "4000 0", "datum": "YYYY-01-15", "text": "Beiträge Januar", "beleg": "E1", "haben": 1000},
    {"line": 8, "konto": "4000 0", "datum": "YYYY-01-20", "text": "Rückbuchung Beitrag", "beleg": "E2", "soll": 50},
    {"line": 9, "konto": "6800 1", "datum": "YYYY-05-01", "text": "Unklar", "beleg": "F1", "soll": 25},
    {"line": 10, "konto": "6900 0", "datum": "YYYY-05-02", "text": "Ohne Regel", "beleg": "G1", "soll": 999},
    {"line": 11, "konto": "6326 3", "datum": "YYYY-01-01", "text": "EB-Wert", "beleg": "", "soll": 5000},
    {"line": 12, "konto": "6326 3", "datum": "2025-12-31", "text": "Altes Jahr", "beleg": "H1", "soll": 77},
    {"line": 13, "konto": "6326 4", "datum": "YYYY-06-03", "text": "Auszahlung Runde 1", "beleg": "J1", "soll": 1500},
    {"line": 14, "konto": "6810 0", "datum": "YYYY-06-04", "text": "Ohne Plan", "beleg": "K1", "soll": 10}]} $$));
grant select on datev to authenticated;

-- Budgetpflege: Vorstand und Geschäftsstelle
insert into public.ad_template_assignments (person_id, template_id)
select p, t.id from public.ad_templates t,
       unnest(array['a0000000-0000-4000-8000-000000000003', 'a0000000-0000-4000-8000-000000000002']::uuid[]) p
 where t.name = 'Budgetpflege';

-- ---------------------------------------------------------------------------------------------------------------
-- Pflege nur mit Budgetpflege (R21)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select throws_ok($$ select public.fi_budget_plan_import(pg_temp.y(), (select v from plan_src)) $$,
  'P0001', 'FI_BUDGET_FORBIDDEN', 'Referent:in darf keinen Finanzplan einlesen');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select throws_ok($$ select public.fi_budget_plan_import(pg_temp.y(), (select v || '{"sums": {"income": 4999}}' from plan_src)) $$,
  'P0001', 'FI_BUDGET_SUM_MISMATCH', 'R10: Summe passt nicht zur Excel');
select is((public.fi_budget_plan_preview(pg_temp.y(), (select v from plan_src)) -> 'sums' ->> 'expense')::numeric,
  3840::numeric, 'Vorschau rechnet die Summen');
select is((select count(*)::int from public.fi_budget_items), 0, 'Vorschau schreibt nichts');
select lives_ok($$ select public.fi_budget_plan_import(pg_temp.y(), (select v from plan_src)) $$, 'Finanzplan eingelesen');
select is((select count(*)::int from public.fi_budget_items where year = pg_temp.y()), 8, '8 Budgetposten');

-- Gesamtbudgets bilden (P8): doppelter Name „Vergütung Aktive“ hing am Posten darüber
select public.fi_budget_item_move(pg_temp.item(pg_temp.y(), 'Material Klettern', 'Vergütung Aktive'), 'Klettern');
select public.fi_budget_item_move(pg_temp.item(pg_temp.y(), 'Material Klettern', 'Material Klettern'), 'Klettern');
select public.fi_budget_item_move(pg_temp.item(pg_temp.y(), 'Fahrtkosten', 'Vergütung Aktive'), 'Kinder und Jugend');
select public.fi_budget_item_move(pg_temp.item(pg_temp.y(), 'Fahrtkosten', 'Fahrtkosten'), 'Kinder und Jugend');
select results_eq(
  $$ select g.name, g.visibility::text, r.name from public.fi_budget_groups g left join public.ea_referate r on r.id = g.referat_id
      where g.year = pg_temp.y() order by g.name $$,
  $$ values ('Kinder und Jugend'::text, 'referat'::text, 'Kinder und Jugend'::text), ('Klettern', 'referat', 'Klettern'),
            ('Mitgliedsbeiträge', 'none', null), ('Sonstiges', 'none', null), ('Veranstaltungen', 'all', null),
            ('Vereinszentrum', 'none', null) $$,
  'Gesamtbudgets mit Startwert der Sichtbarkeit (R22)');
select throws_ok($$ select public.fi_budget_group_set((select id from public.fi_budget_groups where name = 'Sonstiges'),
  'referat', null) $$, 'P0001', 'FI_BUDGET_REFERAT_REQUIRED', 'Referat Pflicht bei Sichtbarkeit Referat');

-- Regeln (R2): Einzelkonto, Hauptkonto, Bereich, Kostenstelle, Regel ohne Posten
select public.fi_budget_rule_save(jsonb_build_object('year', pg_temp.y(), 'account_text', '6326 3',
  'item_id', pg_temp.item(pg_temp.y(), 'Klettern', 'Vergütung Aktive')), null);
select public.fi_budget_rule_save(jsonb_build_object('year', pg_temp.y(), 'account_text', '63264',
  'item_id', pg_temp.item(pg_temp.y(), 'Kinder und Jugend', 'Vergütung Aktive')), null);
select public.fi_budget_rule_save(jsonb_build_object('year', pg_temp.y(), 'account_text', '6330',
  'item_id', pg_temp.item(pg_temp.y(), 'Klettern', 'Material Klettern')), null);
select public.fi_budget_rule_save(jsonb_build_object('year', pg_temp.y(), 'account_text', '6300 0 bis 6399 9',
  'item_id', pg_temp.item(pg_temp.y(), 'Vereinszentrum', 'Vereinszentrum'), 'status', 'uncertain'), null);
select public.fi_budget_rule_save(jsonb_build_object('year', pg_temp.y(), 'account_text', '6340 1',
  'cost_centers', jsonb_build_array('20'), 'item_id', pg_temp.item(pg_temp.y(), 'Kinder und Jugend', 'Fahrtkosten')), null);
select public.fi_budget_rule_save(jsonb_build_object('year', pg_temp.y(), 'account_text', '6340 1',
  'item_id', pg_temp.item(pg_temp.y(), 'Veranstaltungen', 'Veranstaltungen')), null);
select public.fi_budget_rule_save(jsonb_build_object('year', pg_temp.y(), 'account_text', '4000',
  'item_id', pg_temp.item(pg_temp.y(), 'Mitgliedsbeiträge', 'Mitgliedsbeiträge')), null);
select public.fi_budget_rule_save(jsonb_build_object('year', pg_temp.y(), 'account_text', '6800 1', 'status', 'open'), null);
select public.fi_budget_rule_save(jsonb_build_object('year', pg_temp.y(), 'account_text', '6810 0',
  'item_id', pg_temp.item(pg_temp.y(), 'Sonstiges', 'Sonstiges')), null);
select throws_ok($$ select public.fi_budget_rule_save(jsonb_build_object('year', pg_temp.y(), 'account_text', '6326 3',
  'item_id', pg_temp.item(pg_temp.y(), 'Klettern', 'Material Klettern')), null) $$,
  'P0001', 'FI_BUDGET_RULE_DUPLICATE', 'R11: dieselbe Kontoangabe nur einmal gültig');
select throws_ok($$ select public.fi_budget_rule_save(jsonb_build_object('year', pg_temp.y(), 'account_text', '6399 - 6300'), null) $$,
  'P0001', 'FI_BUDGET_RANGE_INVALID', 'Bereich rückwärts');

-- ---------------------------------------------------------------------------------------------------------------
-- DATEV-Import (R1, R4, R8)
select throws_ok($$ select public.fi_budget_import(pg_temp.y(), '{"rows": []}') $$, 'P0001', 'FI_BUDGET_NO_ROWS', 'leere Datei');
select is((public.fi_budget_import_preview(pg_temp.y(), (select v from datev)) ->> 'rows_saved')::int, 11,
  'Vorschau: 11 Zeilen mit Regel');
select is((select count(*)::int from public.fi_budget_bookings), 0, 'Vorschau schreibt nichts');
create temp table imp as select public.fi_budget_import(pg_temp.y(), (select v from datev)) as r;
select results_eq($$ select (r ->> 'rows_read')::int, (r ->> 'rows_saved')::int, (r ->> 'rows_ignored')::int,
                            (r ->> 'rows_opening')::int, (r ->> 'rows_other_year')::int, (r ->> 'data_until')::date
                       from imp $$,
  $$ values (14, 11, 1, 1, 1, make_date(pg_temp.y(), 6, 4)) $$,
  'Zählung: gespeichert, ohne Regel, EB-Wert, anderes Jahr; Datenstand');
select is((select count(*)::int from public.fi_budget_bookings where main_account = 6900), 0, 'R1: Konto ohne Regel nicht gespeichert');
select ok((select r -> 'warnings' @> '[{"type": "incomplete", "konto": "6330 5"}]' from imp),
  'R8: Kontenübersicht 6330 5 weicht ab');
select ok((select (c ->> 'ok')::boolean from imp, jsonb_array_elements(r -> 'checks') c where c ->> 'konto' = '6326 3'),
  'R8: 6326 3 stimmt (ohne EB-Wert)');

-- Summen nach Vorrang (R2) und Vorzeichen (R3)
select results_eq(
  $$ select o.group_name, o.name, o.plan_current, o.actual, o.ampel from public.ds_budget_overview(pg_temp.y()) o
      order by o.group_name, o.name $$,
  $$ values ('Kinder und Jugend'::text, 'Fahrtkosten'::text, 300::numeric, 40::numeric, 'ok'::text),
            ('Kinder und Jugend', 'Vergütung Aktive', 2000, 1500, 'ok'),
            ('Klettern', 'Material Klettern', 100, 100, 'warn'),
            ('Klettern', 'Vergütung Aktive', 1000, 280, 'ok'),
            ('Mitgliedsbeiträge', 'Mitgliedsbeiträge', 5000, 950, null),
            ('Sonstiges', 'Sonstiges', 0, 10, 'no_plan'),
            ('Veranstaltungen', 'Veranstaltungen', 400, 70, 'ok'),
            ('Vereinszentrum', 'Vereinszentrum', 40, 50, 'over') $$,
  'Ist je Posten: Einzelkonto, Hauptkonto vor Bereich, Kostenstelle vor ohne, Einnahmen Haben − Soll, Ampel (R6)');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
create temp table head as select public.ds_budget_head(pg_temp.y()) as h;
select results_eq($$ select (h ->> 'expense_plan')::numeric, (h ->> 'expense_actual')::numeric,
                            (h ->> 'income_actual')::numeric, (h ->> 'income_missing')::numeric from head $$,
  $$ values (3840::numeric, 2050::numeric, 950::numeric, 4050::numeric) $$, 'Kopf: Summen des Vereins');
select is((select (h ->> 'progress')::numeric from head),
  round((make_date(pg_temp.y(), 6, 4) - make_date(pg_temp.y(), 1, 1) + 1)::numeric
        / (make_date(pg_temp.y() + 1, 1, 1) - make_date(pg_temp.y(), 1, 1)) * 100, 1), 'R7: Jahresfortschritt');
select results_eq($$ select booking_text, amount, rule_status::text from public.ds_budget_unassigned(pg_temp.y()) $$,
  $$ values ('Unklar'::text, 25::numeric, 'open'::text) $$, 'R14: nicht zugeordnete Buchung für Reichweite alle');
select ok((select jsonb_array_length(public.ds_budget_checks(pg_temp.y()) -> 'uncertain') = 2),
  'Prüfung: unsichere und offene Regel');

-- ---------------------------------------------------------------------------------------------------------------
-- Rechte beim Lesen (R12, R13, R14): Rita Referentin (Klettern)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select is((select count(*)::int from public.ds_budget_overview(pg_temp.y())), 8, 'R12: alle Summen sichtbar');
select results_eq(
  $$ select o.group_name, o.name, o.can_see_bookings, o.can_edit, o.is_mine from public.ds_budget_overview(pg_temp.y()) o
      where o.name in ('Vergütung Aktive', 'Veranstaltungen', 'Vereinszentrum') order by o.group_name $$,
  $$ values ('Kinder und Jugend'::text, 'Vergütung Aktive'::text, false, false, false),
            ('Klettern', 'Vergütung Aktive', true, true, true), ('Veranstaltungen', 'Veranstaltungen', true, false, false),
            ('Vereinszentrum', 'Vereinszentrum', false, false, false) $$,
  'R13: Einzelbuchungen eigenes Referat und „alle“');
select is((select count(*)::int from public.ds_budget_bookings(pg_temp.item(pg_temp.y(), 'Klettern', 'Vergütung Aktive'))),
  2, 'eigene Einzelbuchungen');
select throws_ok($$ select * from public.ds_budget_bookings(pg_temp.item(pg_temp.y(), 'Kinder und Jugend', 'Vergütung Aktive')) $$,
  'P0001', 'FI_BUDGET_FORBIDDEN', 'fremde Einzelbuchungen gesperrt');
select throws_ok($$ select * from public.ds_budget_unassigned(pg_temp.y()) $$, 'P0001', 'FI_BUDGET_FORBIDDEN',
  'R14: nicht zugeordnete nur Reichweite alle');
select throws_ok($$ select public.ds_budget_checks(pg_temp.y()) $$, 'P0001', 'FI_BUDGET_FORBIDDEN', 'Prüfung nur Reichweite alle');
select is((select count(*)::int from public.fi_budget_bookings), 0, 'RLS: Referent:in liest Buchungen nicht direkt');
select is((select count(*)::int from public.fi_budget_items), 8, 'RLS: Posten lesbar mit DS lesen');
select results_eq($$ select account, amount, bookings from public.ds_budget_account_sums(
                        pg_temp.item(pg_temp.y(), 'Klettern', 'Vergütung Aktive')) $$,
  $$ values ('6326 3'::text, 280::numeric, 2) $$, 'Summe je Konto');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000006');
select throws_ok($$ select * from public.ds_budget_overview(pg_temp.y()) $$, 'P0001', 'FI_BUDGET_FORBIDDEN',
  'ohne DS lesen kein Budget');

-- ---------------------------------------------------------------------------------------------------------------
-- Hinweise (R17)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select lives_ok($$ select public.fi_budget_note_save(pg_temp.item(pg_temp.y(), 'Klettern', 'Material Klettern'),
  'Neue Seile im Herbst') $$, 'Hinweis zum eigenen Posten');
select lives_ok($$ select public.fi_budget_note_save(pg_temp.item(pg_temp.y(), 'Klettern', 'Material Klettern'),
  'Neue Seile bestellt') $$, 'Hinweis ändern');
select is((select o.note from public.ds_budget_overview(pg_temp.y()) o where o.name = 'Material Klettern'),
  'Neue Seile bestellt', 'aktueller Hinweis');
select is((select count(*)::int from public.fi_budget_notes), 2, 'Historie der Hinweise');
select throws_ok($$ select public.fi_budget_note_save(pg_temp.item(pg_temp.y(), 'Kinder und Jugend', 'Fahrtkosten'), 'x') $$,
  'P0001', 'FI_BUDGET_FORBIDDEN', 'kein Hinweis zu fremden Posten');
select throws_ok($$ select public.fi_budget_note_save(pg_temp.item(pg_temp.y(), 'Klettern', 'Material Klettern'),
  repeat('x', 501)) $$, 'P0001', 'FI_BUDGET_NOTE_TOO_LONG', 'Hinweis höchstens 500 Zeichen');

-- Umschichtung (R15)
select throws_ok($$ select public.fi_budget_realloc_request(pg_temp.item(pg_temp.y(), 'Klettern', 'Vergütung Aktive'),
  pg_temp.item(pg_temp.y(), 'Kinder und Jugend', 'Fahrtkosten'), 10, 'Test') $$,
  'P0001', 'FI_BUDGET_REALLOC_GROUP', 'nur innerhalb eines Gesamtbudgets');
select throws_ok($$ select public.fi_budget_realloc_request(pg_temp.item(pg_temp.y(), 'Klettern', 'Vergütung Aktive'),
  pg_temp.item(pg_temp.y(), 'Klettern', 'Material Klettern'), 1000.01, 'Test') $$,
  'P0001', 'FI_BUDGET_REALLOC_AMOUNT', 'höchstens der Plan');
select throws_ok($$ select public.fi_budget_realloc_request(pg_temp.item(pg_temp.y(), 'Klettern', 'Vergütung Aktive'),
  pg_temp.item(pg_temp.y(), 'Klettern', 'Material Klettern'), 100, ' ') $$,
  'P0001', 'FI_BUDGET_REASON_REQUIRED', 'Grund Pflicht');
select throws_ok($$ select public.fi_budget_realloc_request(pg_temp.item(pg_temp.y(), 'Klettern', 'Vergütung Aktive'),
  pg_temp.item(pg_temp.y(), 'Klettern', 'Material Klettern'), 100, 'Test', true) $$,
  'P0001', 'FI_BUDGET_FORBIDDEN', 'direkt nur mit Budgetpflege');
create temp table ids (k text primary key, id uuid);
grant all on ids to authenticated;
insert into ids select 'r1', public.fi_budget_realloc_request(pg_temp.item(pg_temp.y(), 'Klettern', 'Vergütung Aktive'),
  pg_temp.item(pg_temp.y(), 'Klettern', 'Material Klettern'), 100, 'Mehr Material');
select throws_ok($$ select public.fi_budget_realloc_decide((select id from ids where k = 'r1'), true, null) $$,
  'P0001', 'FI_BUDGET_FORBIDDEN', 'Referent:in bestätigt nicht');
select results_eq($$ select request_type, status, amount, is_mine, can_decide from public.ds_budget_requests(pg_temp.y()) $$,
  $$ values ('reallocation'::text, 'requested'::text, 100::numeric, true, false) $$, 'eigener Antrag sichtbar');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000032');
select is((select count(*)::int from public.ds_budget_requests(pg_temp.y())), 0, 'fremde Anträge nicht sichtbar');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select ok((select t @> '[{"type": "reallocations_open", "count": 1}]' from public.ds_todo() t), 'Zu tun: offener Antrag');
select lives_ok($$ select public.fi_budget_realloc_decide((select id from ids where k = 'r1'), true, null) $$,
  'Budgetpflege bestätigt');
select results_eq($$ select o.name, o.plan_decided, o.plan_current from public.ds_budget_overview(pg_temp.y()) o
                      where o.group_name = 'Klettern' order by o.name $$,
  $$ values ('Material Klettern'::text, 100::numeric, 200::numeric), ('Vergütung Aktive', 1000, 900) $$,
  'aktueller Plan mit Umschichtung; Summe bleibt');
select throws_ok($$ select public.fi_budget_realloc_decide((select id from ids where k = 'r1'), false, 'x') $$,
  'P0001', 'FI_BUDGET_STATE', 'schon entschieden');
insert into ids select 'r2', public.fi_budget_realloc_request(pg_temp.item(pg_temp.y(), 'Kinder und Jugend', 'Vergütung Aktive'),
  pg_temp.item(pg_temp.y(), 'Kinder und Jugend', 'Fahrtkosten'), 50, 'Eigener Antrag');
select throws_ok($$ select public.fi_budget_realloc_decide((select id from ids where k = 'r2'), true, null) $$,
  'P0001', 'FI_BUDGET_OWN_REQUEST', 'eigenen Antrag bestätigt eine andere Person');
select throws_ok($$ select public.fi_budget_realloc_decide((select id from ids where k = 'r2'), false, '') $$,
  'P0001', 'FI_BUDGET_OWN_REQUEST', 'auch nicht ablehnen');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select throws_ok($$ select public.fi_budget_realloc_decide((select id from ids where k = 'r2'), false, '') $$,
  'P0001', 'FI_BUDGET_REASON_REQUIRED', 'Ablehnen mit Grund');
select lives_ok($$ select public.fi_budget_realloc_decide((select id from ids where k = 'r2'), false, 'Nicht nötig') $$,
  'andere Budgetpflege lehnt ab');

-- ---------------------------------------------------------------------------------------------------------------
-- Umschlüsselungs-Vorschlag (R16) und Umschlüsseln (US-FI-27)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
insert into ids select 'p1', public.fi_budget_proposal_create(pg_temp.booking('Übungsleiter Februar'),
  pg_temp.item(pg_temp.y(), 'Klettern', 'Material Klettern'), 'War Material');
select throws_ok($$ select public.fi_budget_proposal_create(pg_temp.booking('Übungsleiter Februar'),
  pg_temp.item(pg_temp.y(), 'Veranstaltungen', 'Veranstaltungen'), 'Doch Fest') $$,
  'P0001', 'FI_BUDGET_PROPOSAL_OPEN', 'je Buchung ein offener Vorschlag');
select throws_ok($$ select public.fi_budget_proposal_create(pg_temp.booking('Fahrt Jugend'),
  pg_temp.item(pg_temp.y(), 'Klettern', 'Material Klettern'), 'Meins') $$,
  'P0001', 'FI_BUDGET_FORBIDDEN', 'kein Vorschlag zu fremden Buchungen');
select is((select o.open_proposals from public.ds_budget_overview(pg_temp.y()) o
            where o.group_name = 'Klettern' and o.name = 'Vergütung Aktive'), 1, 'offener Vorschlag am Posten');
select ok((select proposal_open from public.ds_budget_bookings(pg_temp.item(pg_temp.y(), 'Klettern', 'Vergütung Aktive'))
            where booking_text = 'Übungsleiter Februar'), 'Buchung zeigt offenen Vorschlag');
insert into ids select 'p2', public.fi_budget_proposal_create(pg_temp.booking('Storno Übungsleiter'),
  pg_temp.item(pg_temp.y(), 'Klettern', 'Material Klettern'), 'Zurückziehen');
select lives_ok($$ select public.fi_budget_proposal_withdraw((select id from ids where k = 'p2')) $$, 'eigenen Vorschlag zurückziehen');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select throws_ok($$ select public.fi_budget_proposal_decide((select id from ids where k = 'p2'), true, null, null) $$,
  'P0001', 'FI_BUDGET_STATE', 'zurückgezogener Vorschlag nicht mehr entscheidbar');
select lives_ok($$ select public.fi_budget_proposal_decide((select id from ids where k = 'p1'), true, 'booking', null) $$,
  'Vorschlag angenommen');
select results_eq($$ select o.name, o.actual from public.ds_budget_overview(pg_temp.y()) o
                      where o.group_name = 'Klettern' order by o.name $$,
  $$ values ('Material Klettern'::text, 400::numeric), ('Vergütung Aktive', -20) $$,
  'Einzelbuchung umgeschlüsselt (Vorrang Einzelbuchung)');
select ok((select rekeyed from public.ds_budget_bookings(pg_temp.item(pg_temp.y(), 'Klettern', 'Material Klettern'))
            where booking_text = 'Übungsleiter Februar'), 'als umgeschlüsselt gekennzeichnet');

-- Umschlüsseln ganzes Konto: 6350 2 (bisher Bereich) zu Veranstaltungen
select lives_ok($$ select public.fi_budget_rekey(pg_temp.booking('Reinigung'),
  pg_temp.item(pg_temp.y(), 'Veranstaltungen', 'Veranstaltungen'), 'account', 'Reinigung nach Fest') $$, 'Konto umschlüsseln');
select is((select o.actual from public.ds_budget_overview(pg_temp.y()) o where o.name = 'Veranstaltungen'), 120::numeric,
  'Konto 6350 2 jetzt Veranstaltungen');
select throws_ok($$ select public.fi_budget_rekey(pg_temp.booking('Seile'),
  pg_temp.item(pg_temp.y(), 'Veranstaltungen', 'Veranstaltungen'), 'booking', '') $$,
  'P0001', 'FI_BUDGET_REASON_REQUIRED', 'Umschlüsseln mit Grund');

-- Neuer Import (R9): Umschlüsselung bleibt, offener Vorschlag wird neu verbunden
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
insert into ids select 'p3', public.fi_budget_proposal_create(pg_temp.booking('Storno Übungsleiter'),
  pg_temp.item(pg_temp.y(), 'Klettern', 'Material Klettern'), 'Storno auch Material');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
create temp table imp2 as select public.fi_budget_import(pg_temp.y(), (select v from datev)) as r;
select is((select (r ->> 'proposals_obsolete')::int from imp2), 0, 'kein Vorschlag gegenstandslos');
select ok((select booking_id is not null and status = 'proposed' from public.fi_budget_proposals
            where id = (select id from ids where k = 'p3')), 'Vorschlag mit neuer Buchung verbunden');
select is((select o.actual from public.ds_budget_overview(pg_temp.y()) o where o.name = 'Material Klettern'), 400::numeric,
  'Umschlüsselung gilt nach neuem Import');
select is((select count(*)::int from public.fi_budget_imports where year = pg_temp.y() and is_current), 1, 'ein aktueller Import');
-- Import ohne die Storno-Buchung: Vorschlag gegenstandslos, Warnung zur fehlenden Umschlüsselung
create temp table imp3 as select public.fi_budget_import(pg_temp.y(), (select jsonb_set(v, '{rows}',
  (select jsonb_agg(e) from jsonb_array_elements(v -> 'rows') e where e ->> 'line' not in ('1', '2'))) from datev)) as r;
select is((select (r ->> 'proposals_obsolete')::int from imp3), 1, 'Vorschlag ohne Buchung gegenstandslos');
select ok((select r -> 'warnings' @> '[{"type": "rekey_missing"}]' from imp3), 'R9: Umschlüsselung ohne Buchung gemeldet');
select lives_ok($$ select public.fi_budget_import(pg_temp.y(), (select v from datev)) $$, 'wieder vollständiger Import');

-- Rückgängig
select lives_ok($$ select public.fi_budget_rekey_undo((select rule_id from public.fi_budget_proposals
  where id = (select id from ids where k = 'p1'))) $$, 'Umschlüsselung zurücknehmen');
select is((select o.actual from public.ds_budget_overview(pg_temp.y()) o where o.name = 'Material Klettern'), 100::numeric,
  'Buchung wieder beim alten Posten');

-- ---------------------------------------------------------------------------------------------------------------
-- Vorschau (R18): Runde 1 (1.500 €) gebucht über Betrag und Datum, Runde 2 (200 €) offen
select pg_temp.as_owner();
insert into public.fi_settlements (id, person_id, year, half, status, amount)
values ('c7100000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000032', pg_temp.y(), 1, 'paid', 1700);
insert into public.fi_payout_runs (id, year, half, number, status, execution_date, msg_id, released_at, total)
values ('c7100000-0000-4000-8000-000000000011', pg_temp.y(), 1, 91, 'released', make_date(pg_temp.y(), 6, 1), 'TEST-91', now(), 1500),
       ('c7100000-0000-4000-8000-000000000012', pg_temp.y(), 2, 92, 'released', make_date(pg_temp.y(), 9, 1), 'TEST-92', now(), 200);
insert into public.fi_payout_lines (run_id, settlement_id, person_id, referat_id, group_label, amount, remittance,
  end_to_end_id, sort_no)
values ('c7100000-0000-4000-8000-000000000011', 'c7100000-0000-4000-8000-000000000001',
        'a0000000-0000-4000-8000-000000000032', (select id from public.ea_referate where name = 'Kinder und Jugend'),
        'Kinder und Jugend', 1500, 'Verguetung', 'TEST-91-1', 1),
       ('c7100000-0000-4000-8000-000000000012', 'c7100000-0000-4000-8000-000000000001',
        'a0000000-0000-4000-8000-000000000032', (select id from public.ea_referate where name = 'Kinder und Jugend'),
        'Kinder und Jugend', 200, 'Verguetung', 'TEST-92-1', 1);

select pg_temp.as_user('b0000000-0000-4000-8000-000000000032');
select results_eq($$ select o.actual, o.preview_runs, o.ampel from public.ds_budget_overview(pg_temp.y()) o
                      where o.group_name = 'Kinder und Jugend' and o.name = 'Vergütung Aktive' $$,
  $$ values (1500::numeric, 200::numeric, 'ok'::text) $$, 'Vorschau nur nicht gebuchte Runde; zählt nicht zum Ist');
select is((select count(*)::int from public.ds_budget_overview(pg_temp.y()) o where o.preview_runs is not null), 2,
  'Vorschau nur bei „Vergütung Aktive“');
select throws_ok($$ select public.fi_budget_payout_mark('c7100000-0000-4000-8000-000000000012', true) $$,
  'P0001', 'FI_BUDGET_FORBIDDEN', 'Markieren nur Budgetpflege');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select lives_ok($$ select public.fi_budget_payout_mark('c7100000-0000-4000-8000-000000000012', true) $$, 'Runde als gebucht markieren');
select is((select o.preview_runs from public.ds_budget_overview(pg_temp.y()) o
            where o.group_name = 'Kinder und Jugend' and o.name = 'Vergütung Aktive'), 0::numeric, 'markierte Runde ohne Vorschau');
select results_eq($$ select number::int, booked, marked from public.ds_budget_payout_runs(pg_temp.y()) order by number $$,
  $$ values (91, true, false), (92, true, true) $$, 'Runden: gebucht per Abgleich bzw. von Hand markiert');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000032');
select throws_ok($$ select * from public.ds_budget_payout_runs(pg_temp.y()) $$, 'P0001', 'FI_BUDGET_FORBIDDEN',
  'Runden nur für die Budgetpflege');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');

-- ---------------------------------------------------------------------------------------------------------------
-- Zu tun (US-DS-17)
select ok((select t @> '[{"type": "unassigned", "count": 1}]' and t @> '[{"type": "rules_uncertain", "count": 2}]'
             and (t @> '[{"type": "data_stale"}]') = (current_date - make_date(pg_temp.y(), 6, 4) > 42)
            from public.ds_todo() t), 'Zu tun Budgetpflege: nicht zugeordnet, unsichere Regeln, Datenstand');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select ok((select t @> '[{"type": "own_reallocation", "status": "confirmed"}]'
             and not t @> '[{"type": "unassigned"}]' from public.ds_todo() t), 'Zu tun Referent:in: eigener Antrag');

-- ---------------------------------------------------------------------------------------------------------------
-- Vorjahr (R20): Jahr J+1 mit Gesamtbudgets und Regeln aus J
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select lives_ok($$ select public.fi_budget_plan_import((pg_temp.y() + 1)::smallint,
  (select jsonb_set(v, '{sheet}', '"Finanzplan"') from plan_src)) $$, 'Finanzplan J+1');
select is((select count(*)::int from public.fi_budget_groups where year = pg_temp.y() + 1), 6,
  'Gesamtbudgets aus dem Vorjahr übernommen');
select is((public.fi_budget_year_from_previous((pg_temp.y() + 1)::smallint, true) ->> 'rules')::int, 10,
  'Regeln aus dem Vorjahr übernommen (ohne Einzelbuchungsregeln)');
select lives_ok($$ select public.fi_budget_import((pg_temp.y() + 1)::smallint, pg_temp.j('{"name": "J1.csv", "rows": [
  {"line": 1, "konto": "6326 3", "datum": "YYNN-03-01", "text": "Übungsleiter März", "beleg": "N1", "soll": 120}]}')) $$,
  'Import J+1');
select results_eq($$ select o.actual, o.actual_prev_same_day, o.actual_prev_full, o.prev_found
                      from public.ds_budget_overview((pg_temp.y() + 1)::smallint) o
                     where o.group_name = 'Klettern' and o.name = 'Vergütung Aktive' $$,
  $$ values (120::numeric, 300::numeric, 280::numeric, true) $$, 'R20: Vorjahr zum gleichen Stichtag und ganzes Jahr');

-- ---------------------------------------------------------------------------------------------------------------
-- Protokoll und Löschlauf (R19, R24)
select ok((select count(*) from public.fi_budget_log where action = 'booking_import') >= 4, 'Importe protokolliert');
select pg_temp.as_owner();
select is((public.fi_budget_purge() ->> 'bookings')::int, 0, 'Löschlauf: nichts älter als J−2');
select ok(exists (select 1 from public.fi_budget_log where action = 'purge'), 'Löschlauf protokolliert');
select ok(exists (select 1 from cron.job where jobname = 'fi-budget-purge'), 'Löschlauf täglich geplant');
select ok(not has_function_privilege('authenticated', 'public.fi_budget_purge()', 'EXECUTE'), 'Löschlauf nicht aufrufbar');
select ok(not has_function_privilege('anon', 'public.ds_budget_overview(smallint)', 'EXECUTE'), 'anon: keine Lesefunktion');
select ok(not has_table_privilege('authenticated', 'public.fi_budget_assigned', 'SELECT'), 'View nur intern');

select * from finish();
rollback;
