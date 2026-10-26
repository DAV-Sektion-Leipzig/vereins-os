-- Nachtrag v0.9 und v0.12 (spec.md AD v0.12.0), spec T65; AD tasks.md T139: Modul TK, Startwerte, Vorlage
-- „Freigabe Touren und Kurse“, Erwartete Ergebnisse v0.9 (Abschnitt 9), Sätze der Planungshilfe, ea_person_licenses
-- mit Erwerbsdatum (R47a), Anlegen und Wieder-aktiv-Eintragen über den TK-Weg (R59).
-- Testzugänge: b…01 Admin, b…02 Geschäftsstelle, b…03 Vorstand, b…09 Rita Referentin (Klettern), b…13 Tina Touren,
-- b…14 Alex Ausbildung, b…15 Fritz Freigabe. Personen a…16 Bernd Berg, a…17 Hilde Helfer, a…18 Karl Kletter.
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
create function pg_temp.u(p_n int) returns uuid language sql as $$
  select ('b0000000-0000-4000-8000-0000000000' || lpad(p_n::text, 2, '0'))::uuid
$$;
create function pg_temp.p(p_n int) returns uuid language sql as $$
  select ('a0000000-0000-4000-8000-0000000000' || lpad(p_n::text, 2, '0'))::uuid
$$;
create function pg_temp.referat(p_name text) returns uuid language sql as $$
  select id from public.ea_referate where name = p_name
$$;
create function pg_temp.names(p_ids uuid[]) returns text[] language sql as $$
  select coalesce(array_agg(r.name order by r.name), '{}') from public.ea_referate r where r.id = any (p_ids)
$$;
-- Eigenschaftsart Funktion einmal als Owner auflösen (Nutzer ohne EA-Rechte lesen ea_property_types nicht; die
-- Planungshilfe löst sie in tk_create_leader selbst auf)
select set_config('test.function_type', (select id::text from public.ea_property_types where system_key = 'function'), true);
create function pg_temp.function_type() returns uuid language sql as $$
  select current_setting('test.function_type')::uuid
$$;

-- Modul und Startwerte (T134)
select results_eq($$ select name, is_available from public.ad_modules where code = 'TK' $$,
  $$ values ('Planungshilfe Touren und Kurse'::text, true) $$, 'Modul TK, verfügbar seit der Freigabe 27.10.2026');
select results_eq(
  $$ select t.name, r.level::text, r.scope::text, r.can_approve
       from public.ad_template_rights r join public.ad_templates t on t.id = r.template_id
      where r.module_code = 'TK' order by t.name $$,
  $$ values ('Admin'::text, 'read'::text, 'all'::text, false), ('Budgetpflege', 'none', 'all', false),
            ('Freigabe Touren und Kurse', 'edit', 'referat', true),
            ('Geschäftsstelle', 'manage', 'all', false), ('Referent:in', 'edit', 'referat', false),
            ('Vorstand', 'none', 'all', false) $$,
  'Startwerte TK: Admin lesen, Geschäftsstelle verwalten, Referent:in bearbeiten (Referat), Freigabe bearbeiten + freigeben');
select is((select count(*)::int from public.ad_template_rights r join public.ad_templates t on t.id = r.template_id
           where t.name = 'Freigabe Touren und Kurse' and r.level <> 'none'), 1, 'Freigabe-Vorlage: nur TK');

-- Erwartete Ergebnisse v0.9 (spec.md AD Abschnitt 9)
select pg_temp.as_user(pg_temp.u(1));
select is(pg_temp.names(public.ad_my_referate('TK', 'edit')), '{}'::text[], 'Admin: keine TK-Referate');
select is(pg_temp.names(public.ad_my_approve_referate('TK')), '{}'::text[], 'Admin: gibt nicht frei');
select throws_ok($$ select * from public.ea_search_active_persons('Berg') $$, 'P0001', 'AD_FORBIDDEN',
  'Admin (TK lesen): keine Suche');
select results_eq(
  $$ select right(person_id::text, 2)::int, qualification_code, valid_until, is_fundable, valid_on_date
       from public.ea_person_licenses(array[pg_temp.p(16), pg_temp.p(17), pg_temp.p(18)], date '2027-10-29')
      order by 1 $$,
  $$ values (16, 'TCBW'::text, date '2027-10-30', true, true) $$,
  'Admin: Bernd Berg mit TCBW bis 30.10.2027, gültig; Karl Kletter ohne Zeile (abgelaufen); Hilde ohne Lizenz');
select is((select value from public.ad_rates_at(date '2028-01-01') where rate_key = 'rOrg'), 12::numeric,
  'rOrg ab 2028 = 12 € (Seed)');
select is((select value from public.ad_rates_at(date '2027-12-31') where rate_key = 'rOrg'), 10::numeric,
  'rOrg bis 2027 = 10 €');

select pg_temp.as_user(pg_temp.u(2));
select is(pg_temp.names(public.ad_my_referate('TK', 'edit')), '{}'::text[], 'Geschäftsstelle: Reichweite alle');
select ok(public.ad_has_level('TK', 'manage'), 'Geschäftsstelle: TK verwalten');
select ok(not public.ad_can_approve('TK', pg_temp.referat('Touren')), 'Geschäftsstelle: gibt nicht frei (A2)');
select results_eq($$ select id from public.ea_search_active_persons('Berg') $$, $$ values (pg_temp.p(16)) $$,
  'Geschäftsstelle: „Berg“ → Bernd Berg');

select pg_temp.as_user(pg_temp.u(13));
select is(pg_temp.names(public.ad_my_referate('TK', 'edit')), array['Touren'], 'Tina: TK bearbeiten Touren');
select is(pg_temp.names(public.ad_my_approve_referate('TK')), array['Touren'], 'Tina: gibt Touren frei');
select results_eq($$ select id from public.ea_search_active_persons('Berg') $$, $$ values (pg_temp.p(16)) $$,
  'Tina: „Berg“ → Bernd Berg');

select pg_temp.as_user(pg_temp.u(14));
select is(pg_temp.names(public.ad_my_referate('TK', 'edit')), array['Ausbildung'], 'Alex: TK bearbeiten Ausbildung');
select is(pg_temp.names(public.ad_my_approve_referate('TK')), '{}'::text[], 'Alex: ohne Freigabe');

select pg_temp.as_user(pg_temp.u(15));
select is(pg_temp.names(public.ad_my_referate('TK', 'edit')), array['Touren'],
  'Fritz: TK bearbeiten Touren (Vorlage Freigabe)');
select is(pg_temp.names(public.ad_my_approve_referate('TK')), array['Touren'], 'Fritz: gibt Touren frei');
select ok(public.ad_can_approve('TK', pg_temp.referat('Touren')), 'Fritz: ad_can_approve Touren');
select ok(not public.ad_can_approve('TK', pg_temp.referat('Ausbildung')), 'Fritz: nicht Ausbildung');
select results_eq($$ select id from public.ea_search_active_persons('Berg') $$, $$ values (pg_temp.p(16)) $$,
  'Fritz: „Berg“ → Bernd Berg');
select lives_ok($$ select * from public.ad_rates_at(current_date) $$, 'Fritz: liest Sätze (TK)');
select results_eq($$ select code, level::text from public.ad_my_modules() where code = 'TK' $$, $$ values ('TK'::text, 'edit'::text) $$,
  'Fritz: Kachel TK auch nur mit der Vorlage Freigabe (Annahme v0.9 AD)');

select pg_temp.as_user(pg_temp.u(9));
select is(pg_temp.names(public.ad_my_referate('TK', 'edit')), array['Klettern'], 'Rita: TK bearbeiten Klettern');
select is(pg_temp.names(public.ad_my_approve_referate('TK')), '{}'::text[], 'Rita: ohne Freigabe');
select is((select count(*)::int from public.ea_person_licenses(array[pg_temp.p(16)], date '2027-10-29')), 1,
  'Rita (TK bearbeiten Klettern): liest Lizenzen');

select pg_temp.as_user(pg_temp.u(3));
select throws_ok($$ select * from public.ea_person_licenses(array[pg_temp.p(16)], current_date) $$, 'P0001', 'AD_FORBIDDEN',
  'Vorstand: keine Lizenzen');
select throws_ok($$ select * from public.ea_search_active_persons('Berg') $$, 'P0001', 'AD_FORBIDDEN', 'Vorstand: keine Suche');
select throws_ok($$ select * from public.ad_rates_at(current_date) $$, 'P0001', 'AD_FORBIDDEN', 'Vorstand: keine Sätze');

-- ea_person_licenses (R47, R47a)
select pg_temp.as_owner();
select is(
  (select array_agg(c.parameter_name::text order by c.ordinal_position)
     from information_schema.routines r
     join information_schema.parameters c on c.specific_name = r.specific_name and c.parameter_mode = 'OUT'
    where r.routine_schema = 'public' and r.routine_name = 'ea_person_licenses'),
  array['person_id', 'qualification_type_id', 'qualification_code', 'qualification_name', 'valid_from', 'valid_until',
        'is_fundable', 'valid_on_date'],
  'Spalten ohne Lizenznummer, mit Erwerbsdatum');
-- Karl Kletter erwirbt am 15.08.2027 eine neue Lizenz (TCBW bis 2031)
insert into public.ea_properties (person_id, property_type_id, field_values, valid_from)
select pg_temp.p(18), t.id,
       jsonb_build_object('qualification_type', (select id from public.ad_qualification_types where code = 'TCBW'),
                          'valid_until', '2031-12-31'),
       date '2027-08-15'
  from public.ea_property_types t where t.system_key = 'license';
select pg_temp.as_user(pg_temp.u(13));
select results_eq(
  $$ select qualification_code, valid_from, valid_on_date from public.ea_person_licenses(array[pg_temp.p(18)], date '2027-07-10') $$,
  $$ values ('TCBW'::text, date '2027-08-15', false) $$,
  'Erwerb im selben Halbjahr nach dem Datum: Zeile mit Erwerbsdatum, nicht gültig am Datum (R47a)');
select is_empty($$ select 1 from public.ea_person_licenses(array[pg_temp.p(18)], date '2027-06-30') $$,
  'Erwerb im nächsten Halbjahr: keine Zeile');
select results_eq(
  $$ select valid_from, valid_on_date from public.ea_person_licenses(array[pg_temp.p(18)], date '2027-09-01') $$,
  $$ values (date '2027-08-15', true) $$, 'nach dem Erwerb gültig');
select results_eq(
  $$ select right(person_id::text, 2)::int, valid_from from public.ea_person_licenses(array[pg_temp.p(16)], current_date) $$,
  $$ values (16, date '2023-10-30') $$, 'Bernd Berg: Erwerbsdatum aus „gültig von“');
select throws_ok($$ select * from public.ea_person_licenses(array(select gen_random_uuid() from generate_series(1, 51)), current_date) $$,
  'P0001', 'AD_TOO_MANY_IDS', 'höchstens 50 IDs');
select pg_temp.as_owner();
update public.ea_persons set volunteer_status = 'left' where id = pg_temp.p(16);
select pg_temp.as_user(pg_temp.u(13));
select is_empty($$ select 1 from public.ea_person_licenses(array[pg_temp.p(16)], date '2027-01-01') $$,
  'ausgeschiedene Person: keine Lizenzen');
select pg_temp.as_owner();
update public.ea_persons set volunteer_status = 'active' where id = pg_temp.p(16);
update public.ea_property_types set read_level = 'office' where system_key = 'license';
select pg_temp.as_user(pg_temp.u(13));
select is_empty($$ select 1 from public.ea_person_licenses(array[pg_temp.p(16)], date '2027-01-01') $$,
  'Lesestufe der Art Lizenz nicht „alle mit Zugriff“: keine Zeile');
select pg_temp.as_owner();
update public.ea_property_types set read_level = 'all' where system_key = 'license';

-- Sätze der Planungshilfe (T135)
select pg_temp.as_user(pg_temp.u(13));
select results_eq(
  $$ select rate_key, value from public.ad_rates_at(date '2027-07-12')
      where rate_key in ('rKm', 'rUe', 'rNM', 'rRund', 'rVat', 'rCO2', 'ef_rail_long', 'ef_stay_hut', 'car_permit_km',
                         'flight_min_km', 'hut_hp_min', 'hut_hp_max', 'planning_lead_months')
      order by rate_key $$,
  $$ values ('car_permit_km'::text, 500::numeric), ('ef_rail_long', 26), ('ef_stay_hut', 9.32), ('flight_min_km', 1000),
            ('hut_hp_max', 90), ('hut_hp_min', 45), ('planning_lead_months', 6), ('rCO2', 140), ('rKm', 0.2),
            ('rNM', 30), ('rRund', 5), ('rUe', 70), ('rVat', 19) $$,
  'Startbestand Sätze der Planungshilfe (Prototyp 5.1–5.4)');
select results_eq(
  $$ select rate_key, percent, fixed, active from public.ad_rates_at(date '2027-07-12')
      where rate_group = 'payment_fee' order by rate_key $$,
  $$ values ('fee_card'::text, 2.9::numeric, 0.25::numeric, true), ('fee_klarna', 4.3, 0.35, false),
            ('fee_paypal', 4.5, 0.58, true), ('fee_sepa', 1.5, 0.35, true), ('fee_transfer', 1.9, 0.35, false) $$,
  'Zahlungsgebühren mit Prozent, fest, aktiv');
select is((select count(*)::int from public.ad_rates_at(date '2027-07-12') where rate_key like 'ef\_%'), 16,
  '16 Emissionsfaktoren');

-- Anlegen über den TK-Weg (R59)
-- Fritz (nur Freigabe-Vorlage, TK bearbeiten Touren): created_in = 'TK'
select pg_temp.as_user(pg_temp.u(15));
select lives_ok($$ select public.ea_create_volunteer('Erika', 'Extern', null, pg_temp.function_type(), pg_temp.referat('Touren'),
                     '{"function": "Helfer:in"}', current_date, 'erika.extern@example.test') $$,
  'Fritz legt externe Leitung im Referat Touren an');
select pg_temp.as_owner();
select results_eq(
  $$ select p.created_in, p.volunteer_status::text, f.field_values ->> 'function', r.name
       from public.ea_persons p
       join public.ea_properties f on f.person_id = p.id and f.property_type_id = pg_temp.function_type()
       join public.ea_referate r on r.id = f.related_referat_id
      where p.last_name = 'Extern' $$,
  $$ values ('TK'::text, 'active'::text, 'Helfer:in'::text, 'Touren'::text) $$,
  'neue Person: created_in TK, aktiv, Funktion Helfer:in im Referat Touren');
select pg_temp.as_user(pg_temp.u(15));
select throws_ok($$ select public.ea_create_volunteer('Xaver', 'Fremd', null, pg_temp.function_type(), pg_temp.referat('Ausbildung'),
                      '{"function": "Helfer:in"}', current_date) $$,
  'P0001', 'EA_RELATION_FOREIGN_REFERAT', 'Fritz: fremdes Referat');
select throws_ok($$ select public.ea_create_volunteer('Xaver', 'Trainer', null, pg_temp.function_type(), pg_temp.referat('Touren'),
                      '{"function": "Trainer:in"}', current_date) $$,
  'P0001', 'EA_CREATE_FORBIDDEN', 'Fritz: nur Funktion Helfer:in');
select throws_ok($$ select public.ea_create_volunteer('Xaver', 'Ohne', null, pg_temp.function_type(), null,
                      '{"function": "Helfer:in"}', current_date) $$,
  'P0001', 'EA_CREATE_FORBIDDEN', 'Fritz: Referat Pflicht');
select lives_ok($$ select * from public.ad_find_similar_persons('Erika', 'Extern', null) $$,
  'Fritz: Dublettenprüfung erlaubt');
-- Tina (Referent:in mit EA bearbeiten Touren): EA-Weg hat Vorrang
select pg_temp.as_user(pg_temp.u(13));
select lives_ok($$ select public.ea_create_volunteer('Udo', 'Ueber', null, pg_temp.function_type(), pg_temp.referat('Touren'),
                     '{"function": "Helfer:in"}', current_date) $$,
  'Tina legt an');
select pg_temp.as_owner();
select is((select created_in from public.ea_persons where last_name = 'Ueber'), 'EA', 'Tina: created_in EA (EA-Weg)');
-- Vorstand ohne Rechte
select pg_temp.as_user(pg_temp.u(3));
select throws_ok($$ select public.ea_create_volunteer('Xaver', 'Vorstand', null, pg_temp.function_type(), pg_temp.referat('Touren'),
                      '{"function": "Helfer:in"}', current_date) $$,
  'P0001', 'EA_CREATE_FORBIDDEN', 'Vorstand: kein Anlegen');
select throws_ok($$ select * from public.ad_find_similar_persons('Erika', 'Extern', null) $$, 'P0001', 'AD_FORBIDDEN',
  'Vorstand: keine Dublettenprüfung');

-- Wieder aktiv eintragen über den TK-Weg: Olga Ausgeschieden (11, zuletzt Klettern) durch Fritz im Referat Touren
select pg_temp.as_user(pg_temp.u(15));
select lives_ok($$ select public.ea_activate_person(pg_temp.p(11), pg_temp.function_type(), pg_temp.referat('Touren'),
                     '{"function": "Helfer:in"}', current_date) $$,
  'Fritz trägt Olga wieder aktiv ein');
select pg_temp.as_owner();
select is((select volunteer_status::text from public.ea_persons where id = pg_temp.p(11)), 'active', 'Olga wieder aktiv');
select ok(exists (select 1 from public.ea_properties f where f.person_id = pg_temp.p(11)
                   and f.related_referat_id = pg_temp.referat('Touren') and f.field_values ->> 'function' = 'Helfer:in'),
  'Olga: Funktion Helfer:in im Referat Touren');

-- Namen: tk_person_visible ist Platzhalter (false); Fritz sieht Bernd Berg nur über die Suche, nicht über Namen
select pg_temp.as_user(pg_temp.u(15));
select ok(not public.tk_person_visible(pg_temp.p(16)), 'tk_person_visible: Platzhalter false');
select is_empty($$ select 1 from public.ea_person_names(array[pg_temp.p(16)]) $$,
  'Fritz: ea_person_names ohne Planung leer');

-- A2: Startzuweisung der Freigabe an vorhandene Referent:innen Touren/Ausbildung (Migration, beim Seed nicht wirksam)
select pg_temp.as_owner();
select is((select count(*)::int from public.ad_template_assignments ta join public.ad_templates t on t.id = ta.template_id
           where t.name = 'Freigabe Touren und Kurse' and ta.revoked_at is null), 2,
  'Freigabe-Vorlage im Seed: Tina und Fritz (Alex bewusst ohne)');

select * from finish();
rollback;
