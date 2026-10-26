-- US-AD-23, US-AD-26 (spec T45): Sichtbarkeit von Personen und Eigenschaften je Pfad (R29, R32, R34, R39, R41, R42)
-- nach spec.md Abschnitt 9 („Erwartete Sichtbarkeit“, Personen 1–12) und data-model.md („Testdaten“);
-- seit der Seed-Umstellung Ü3 (EA) zusätzlich die Personen 19–22 mit System-Eigenschaftsarten.
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
create function pg_temp.persons() returns int[] language sql as $$
  select coalesce(array_agg(right(id::text, 2)::int order by id), '{}') from public.ea_persons
$$;
create function pg_temp.types_of(p_person int) returns text[] language sql as $$
  select coalesce(array_agg(t.name order by t.name), '{}')
    from public.ea_properties p join public.ea_property_types t on t.id = p.property_type_id
   where p.person_id = ('a0000000-0000-4000-8000-0000000000' || lpad(p_person::text, 2, '0'))::uuid
$$;
create function pg_temp.referat(p_name text) returns uuid language sql as $$
  select id from public.ea_referate where name = p_name
$$;

-- Admin: alle Personen (Pfad AD, v0.7.1), alle Lesestufen
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select is(pg_temp.persons(), array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32],
  'Admin sieht 1–32');
select ok('Hauptamt' = any (pg_temp.types_of(2)), 'Admin liest vertrauliches Hauptamt');
select ok('Geburtsdatum' = any (pg_temp.types_of(4)), 'Admin liest Geburtsdatum');
select is(pg_temp.types_of(12), array['Kontaktdaten'], 'Admin liest Person 12 nur aus Gruppen');
select is((select count(*)::int from public.ea_v_persons), 31, 'ea_v_persons ohne Funktionsperson (R15)');

-- Geschäftsstelle: Pfad EA verwalten, Lesestufen „alle“ und „nur Geschäftsstelle und Admin“
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select is(pg_temp.persons(), array[4, 5, 9, 10, 11, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 28, 29, 30, 31, 32],
  'Geschäftsstelle sieht 4, 5, 9, 10, 11, 13–22 und 26, 28, 31, 32 (Pfad EA) sowie 23–25, 29, 30 (Pfad GR)');
select is(pg_temp.types_of(4), array['Funktion', 'Geburtsdatum', 'Lizenz', 'T-Shirt-Größe'],
  'Geschäftsstelle liest Geburtsdatum, keine vertraulichen Arten');
select is(pg_temp.types_of(2), '{}'::text[], 'Geschäftsstelle liest kein Hauptamt (Person 2 ohne Ehrenamtsstatus)');
select is(pg_temp.types_of(11), array['Funktion'], 'Geschäftsstelle sieht Ausgeschiedene mit EA verwalten (R34)');
select is(pg_temp.types_of(12), '{}'::text[], 'Person 12 (nur Gruppen) nicht im Pfad EA');

-- Referent:in Klettern: Pfad EA mit Reichweite Referat
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select is(pg_temp.persons(), array[4, 9, 10, 19, 22], 'Referent:in sieht 4, 9, 10, 19, 22');
select is(pg_temp.types_of(10), array['Funktion', 'Funktion'],
  'Referent:in liest bei 10 auch die Funktion im Referat Ausbildung, kein Geburtsdatum');
select is(pg_temp.types_of(4), array['Funktion', 'Lizenz', 'T-Shirt-Größe'],
  'Referent:in liest kein Geburtsdatum (nur Geschäftsstelle und Admin)');
select is((select count(*)::int from public.ea_volunteer_status_history), 5, 'Status-Historie nur der sichtbaren Personen');

-- Referent:in schreibt nur Zuordnungen zu eigenen Referaten (R41, R42)
select lives_ok(format($$ insert into public.ea_properties (person_id, property_type_id, field_values, related_referat_id, valid_from)
                   values ('a0000000-0000-4000-8000-000000000004', (select id from public.ea_property_types where system_key = 'function'),
                           '{"function": "Helfer:in"}', %L, current_date) $$, pg_temp.referat('Klettern')),
  'Referent:in legt Funktion im eigenen Referat an');
select throws_ok(format($$ insert into public.ea_properties (person_id, property_type_id, field_values, related_referat_id, valid_from)
                    values ('a0000000-0000-4000-8000-000000000004', (select id from public.ea_property_types where system_key = 'function'),
                            '{"function": "Helfer:in"}', %L, current_date) $$, pg_temp.referat('Ausbildung')),
  'P0001', 'EA_RELATION_FOREIGN_REFERAT', 'Funktion in fremdem Referat abgelehnt (R41)');
update public.ea_properties set field_values = '{"function": "Helfer:in"}'
 where id = 'e0000000-0000-4000-8000-000000000011';
select throws_ok($$ insert into public.ea_properties (person_id, property_type_id, field_values, valid_from)
                    values ('a0000000-0000-4000-8000-000000000004', 'd0000000-0000-4000-8000-000000000003',
                            '{"date": "2026-01-01"}', '2026-01-01') $$,
  '42501', null, 'ohne Bezug auf ein eigenes Referat kein Schreiben (spec Abschnitt 2, ea_property_writable)');
select throws_ok($$ insert into public.ea_properties (person_id, property_type_id, field_values, related_referat_id, valid_from)
                    values ('a0000000-0000-4000-8000-000000000005', (select id from public.ea_property_types where system_key = 'function'),
                            '{"function": "Helfer:in"}',
                            (select id from public.ea_referate where name = 'Klettern'), current_date) $$,
  '42501', null, 'Person 5 (nur Ausbildung) nicht lesbar, also nicht beschreibbar (R42)');
select pg_temp.as_owner();
select is((select field_values ->> 'function' from public.ea_properties where id = 'e0000000-0000-4000-8000-000000000011'),
  'Trainer:in', 'Funktion von 10 im Referat Ausbildung unverändert (R41)');

-- Bezug „Gruppe“: im Pfad EA nicht schreibbar (R39)
insert into public.ea_property_types (id, name, purpose, relation_kind, visible_in)
values ('d0000000-0000-4000-8000-0000000000bb', 'Gruppenfunktion (Test)', 'Test', 'group', '{EA,GR}');
insert into public.ea_property_fields (property_type_id, key, label, data_type, sort_order)
values ('d0000000-0000-4000-8000-0000000000bb', 'role', 'Rolle', 'text', 1);
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select throws_ok($$ insert into public.ea_properties (person_id, property_type_id, field_values, valid_from)
                    values ('a0000000-0000-4000-8000-000000000004', 'd0000000-0000-4000-8000-0000000000bb',
                            '{"role": "x"}', current_date) $$,
  'P0001', 'EA_GROUP_RELATION_ONLY_GR', 'Bezug Gruppe nur über Gruppen, auch nicht für den Admin (R39)');

-- Vorstand: niemanden
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select is(pg_temp.persons(), '{}'::int[], 'Vorstand sieht niemanden');
select is_empty($$ select 1 from public.ea_properties $$, 'Vorstand sieht keine Eigenschaften');
select is_empty($$ select 1 from public.ea_property_history $$, 'Vorstand sieht keine Historie');

-- Gesperrter Zugang: keine Daten (R5, R10)
select pg_temp.as_owner();
update public.ad_accesses set status = 'locked' where person_id = 'a0000000-0000-4000-8000-000000000009';
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select is(pg_temp.persons(), '{}'::int[], 'gesperrte Referent:in sieht sofort niemanden');

-- Pfad wechselt mit dem Ehrenamtsstatus: Person 12 erhält einen Status und erscheint im Pfad EA
select pg_temp.as_owner();
update public.ea_persons set volunteer_status = 'active', volunteer_status_since = current_date
 where id = 'a0000000-0000-4000-8000-000000000012';
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select ok(12 = any (pg_temp.persons()), 'Person 12 mit Ehrenamtsstatus sofort im Pfad EA (R32)');

-- Eigenschaften erzeugen keine Rechte (R7)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select pg_temp.as_owner();
update public.ad_accesses set status = 'active' where person_id = 'a0000000-0000-4000-8000-000000000009';
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select is(public.ad_user_level('EA'), 'none'::public.ad_level, 'Amt Referent:in gibt keine Rechte (R7)');
select is(public.ad_my_referate('EA', 'read'), array[pg_temp.referat('Klettern')], 'Referate nur aus der Zuweisung (R7)');

select pg_temp.as_owner();
select * from finish();
rollback;
