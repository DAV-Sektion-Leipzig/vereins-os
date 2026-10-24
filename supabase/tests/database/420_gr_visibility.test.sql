-- US-GR-01 (GR spec T2, T10): Sichtbarkeit im Pfad GR je Testzugang nach GR spec.md Abschnitt 9 („Erwartete
-- Ergebnisse“), Ü4 (nur laufende Bezüge), R11 (Gesundheitsangaben), Tests aus AD T45.
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
create function pg_temp.p(p_nr int) returns uuid language sql as $$
  select ('a0000000-0000-4000-8000-0000000000' || lpad(p_nr::text, 2, '0'))::uuid
$$;
create function pg_temp.nrs(p_ids uuid[]) returns int[] language sql as $$
  select coalesce(array_agg(right(x::text, 2)::int order by x), '{}') from unnest(p_ids) as x
$$;
create function pg_temp.gr_ids() returns int[] language sql as $$
  select pg_temp.nrs(array(select public.gr_person_ids('read')))
$$;
create function pg_temp.persons() returns int[] language sql as $$
  select pg_temp.nrs(array(select id from public.ea_persons))
$$;
create function pg_temp.birth_rows(p_nr int) returns int language sql as $$
  select count(*)::int from public.ea_properties p
    join public.ea_property_types t on t.id = p.property_type_id and t.system_key = 'birth_date'
   where p.person_id = pg_temp.p(p_nr)
$$;
create function pg_temp.set_level(p_template text, p_module text, p_level public.ad_level) returns void language sql as $$
  update public.ad_template_rights r set level = p_level
    from public.ad_templates t
   where t.id = r.template_id and t.name = p_template and r.module_code = p_module and r.object is null
$$;

-- Struktur: RLS auf allen gr_-Tabellen, nur select für authenticated
select is_empty($$ select c.relname from pg_class c join pg_namespace n on n.oid = c.relnamespace
                    where n.nspname = 'public' and c.relkind = 'r' and c.relname like 'gr\_%' and not c.relrowsecurity $$,
  'RLS auf allen gr_-Tabellen');
select is_empty($$ select c.relname from pg_class c join pg_namespace n on n.oid = c.relnamespace
                    where n.nspname = 'public' and c.relkind = 'r' and c.relname like 'gr\_%'
                      and (has_table_privilege('authenticated', c.oid, 'INSERT')
                           or has_table_privilege('authenticated', c.oid, 'UPDATE')
                           or has_table_privilege('authenticated', c.oid, 'DELETE')) $$,
  'keine Schreibrechte auf gr_-Tabellen für authenticated');
select is_empty($$ select c.relname from pg_class c join pg_namespace n on n.oid = c.relnamespace
                    where n.nspname = 'public' and c.relkind = 'r' and c.relname like 'gr\_%'
                      and has_table_privilege('anon', c.oid, 'SELECT') $$,
  'anon liest keine gr_-Tabelle');

-- Pfad GR: Personen mit laufendem Bezug (spec.md 2.3, Ü4); 27 (beendet) und 31 (Funktion beendet) nicht
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select is(pg_temp.gr_ids(), array[23, 24, 25, 26, 28, 29, 30], 'Pfad GR für die Geschäftsstelle');
select pg_temp.as_owner();
select is(
  (select array_agg(n order by n) from generate_series(1, 32) n
    where exists (select 1 from public.ea_persons where id = pg_temp.p(n)) and public.gr_has_current_relation(pg_temp.p(n))),
  array[23, 24, 25, 26, 28, 29, 30], 'gr_has_current_relation und gr_person_ids liefern dieselbe Menge (R-GR-06)');

-- Admin: alle über Pfad AD; personenbezogene gr_-Zeilen auch ohne laufenden Bezug; nie Gesundheit
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select ok(pg_temp.persons() @> array[23, 24, 25, 26, 27, 28, 29, 30, 31, 32], 'Admin sieht alle Personen aus Gruppen');
select is((select count(*)::int from public.gr_memberships), 5, 'Admin liest alle Teilnahmen, auch beendete (27)');
select is(pg_temp.birth_rows(23), 1, 'Admin liest Geburtsdatum Kind (Pfad AD)');
select is((select count(*)::int from public.gr_health_notes), 0, 'Admin liest keine Gesundheitsangaben (R11)');
select is((select count(*)::int from public.gr_health_note_history), 0, 'Admin liest keine Historie der Gesundheitsangaben');
select is((select count(*)::int from public.gr_health_consents), 0, 'Admin liest keine Einwilligung zu Gesundheitsangaben');

-- Geschäftsstelle: Kinder 23, 25, 28, 30, nicht 27; Geburtsdatum; Gesundheit 23 ja, 25 nein (Widerruf)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select ok(pg_temp.persons() @> array[23, 25, 28, 30], 'Geschäftsstelle sieht Kinder 23, 25, 28, 30');
select ok(not (27 = any (pg_temp.persons())), 'Geschäftsstelle sieht 27 (beendet) nicht');
select is((select count(*)::int from public.gr_memberships), 4, 'Geschäftsstelle liest nur Teilnahmen sichtbarer Kinder');
select is((select count(*)::int from public.gr_contracts), 4, 'Verträge nur zu sichtbaren Teilnahmen');
select is(pg_temp.birth_rows(23), 1, 'Geschäftsstelle liest Geburtsdatum (GR verwalten)');
select is((select array_agg(right(person_id::text, 2)::int) from public.gr_health_notes), array[23],
  'Gesundheit 23 lesbar, 25 nach Widerruf nicht (R24)');
select is((select count(*)::int from public.gr_health_consents where person_id = pg_temp.p(25)), 2,
  'Einwilligungshistorie von 25 lesbar');
select ok(not public.ea_person_visible_ea(pg_temp.p(23)), 'Teilnehmer:in nicht über EA sichtbar (AD T45)');

-- Rita Referentin, Kim Kinderjugend, Vorstand: keine personenbezogenen gr_-Zeilen, keine Kinder
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select is(pg_temp.gr_ids(), '{}'::int[], 'Rita: kein Pfad GR');
select ok(not (pg_temp.persons() && array[23, 25, 28, 30]), 'Rita sieht keine Kinder');
select is((select count(*)::int from public.gr_memberships) + (select count(*)::int from public.gr_guardians)
          + (select count(*)::int from public.gr_emergency_contacts) + (select count(*)::int from public.gr_contracts)
          + (select count(*)::int from public.gr_photo_consents) + (select count(*)::int from public.gr_pending_admissions),
  0, 'Rita liest keine personenbezogenen gr_-Zeilen');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000032');
select ok(not (pg_temp.persons() && array[23, 25, 28, 30]), 'Kim sieht keine Kinder');
select is((select count(*)::int from public.gr_memberships), 0, 'Kim liest keine Teilnahmen');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select ok(not (pg_temp.persons() && array[23, 24, 25, 28, 29, 30]), 'Vorstand sieht niemanden aus Gruppen');
select is((select count(*)::int from public.gr_memberships), 0, 'Vorstand liest keine Teilnahmen');

-- Vorstand mit „Gruppen lesen“: Kinder ja, Geburtsdatum nein, Gesundheit nein (W2, R11)
select pg_temp.as_owner();
select pg_temp.set_level('Vorstand', 'GR', 'read');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select ok(pg_temp.persons() @> array[23, 25, 28, 30], 'Vorstand mit GR lesen sieht die Kinder');
select ok(not (27 = any (pg_temp.persons())), 'Vorstand mit GR lesen sieht 27 nicht');
select is(pg_temp.birth_rows(23), 0, 'Vorstand mit GR lesen liest kein Geburtsdatum (W2)');
select ok((select count(*) from public.ea_properties p join public.ea_property_types t on t.id = p.property_type_id
            where t.system_key = 'contact' and p.person_id = pg_temp.p(24)) = 1,
  'nur „Gruppen lesen“ liest Kontaktdaten (AD T45)');
select is((select count(*)::int from public.gr_health_notes) + (select count(*)::int from public.gr_health_consents), 0,
  'Vorstand mit GR lesen liest keine Gesundheitsangaben');

-- Erziehungsberechtigter zugleich Trainer (26) über EA: keine gruppenspezifischen Daten, Funktion nicht änderbar
select pg_temp.as_owner();
select pg_temp.set_level('Vorstand', 'GR', 'none');
select pg_temp.set_level('Vorstand', 'EA', 'edit');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select ok(26 = any (pg_temp.persons()), 'Vorstand mit EA bearbeiten sieht Lars Lehrer über EA');
select ok(not (27 = any (pg_temp.persons())), 'aber nicht sein Kind');
select is((select count(*)::int from public.gr_guardians) + (select count(*)::int from public.gr_memberships), 0,
  'keine gruppenspezifischen Daten über EA (AD T45)');
select is((select g.name from public.ea_properties p
             join public.ea_property_types t on t.id = p.property_type_id and t.system_key = 'group_function'
             join public.gr_groups g on g.id = p.related_group_id
            where p.person_id = pg_temp.p(26)), 'Jugendgruppe Test 1', 'Funktion in Gruppe mit Gruppenname lesbar (US-GR-13 AK3)');
update public.ea_properties set valid_to = public.gr_today() where id = 'e0000000-0000-4000-8000-000000000039';
select pg_temp.as_owner();
select is((select valid_to from public.ea_properties where id = 'e0000000-0000-4000-8000-000000000039'), null::date,
  'Funktion in Gruppe im EA nicht änderbar (R14, R39, AD T45)');

select * from finish();
rollback;
