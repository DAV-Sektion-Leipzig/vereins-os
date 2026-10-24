-- US-GR-06, US-GR-07, US-GR-09 (GR spec T4, T10): Aufnahme offen, Personen anlegen oder übernehmen (Ü2),
-- Personenangaben, Erziehungsberechtigte und Notfallkontakte (R2, R3, R7, R10, R22, R23, R25, R26).
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
create function pg_temp.prop(p_person uuid, p_key text) returns public.ea_properties language sql as $$
  select p.* from public.ea_properties p join public.ea_property_types t on t.id = p.property_type_id
   where p.person_id = p_person and t.system_key = p_key order by p.valid_from desc limit 1
$$;

create temp table ids (name text primary key, id uuid);
grant all on ids to authenticated;

-- Neue Teilnehmer:in (GR verwalten)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select throws_ok($$ select public.gr_start_admission('c0000000-0000-4000-8000-000000000001', null,
                     '{"first_name": "Nora", "last_name": "Neu", "birth_date": "2016-04-01"}') $$,
  'P0001', 'GR_PARTICIPANT_FIELDS_REQUIRED', 'Adresse Pflicht (R2)');
select throws_ok($$ select public.gr_start_admission('c0000000-0000-4000-8000-000000000001', null, null) $$,
  'P0001', 'GR_PERSON_INVALID', 'weder Person noch neue Person');
select throws_ok($$ select public.gr_start_admission('c0000000-0000-4000-8000-000000000001',
                     'a0000000-0000-4000-8000-000000000012', '{"first_name": "X", "last_name": "Y"}') $$,
  'P0001', 'GR_PERSON_INVALID', 'nicht beides');
select throws_ok($$ select public.gr_start_admission('c0000000-0000-4000-8000-000000000004', 'a0000000-0000-4000-8000-000000000012') $$,
  'P0001', 'GR_GROUP_DISSOLVED', 'nicht in aufgelöste Gruppe');

insert into ids
select 'nora', public.gr_start_admission('c0000000-0000-4000-8000-000000000001', null,
  '{"first_name": "Nora", "last_name": "Neu", "preferred_name": "", "birth_date": "2016-04-01", "street": "Neuweg 1",
    "postal_code": "04109", "city": "Leipzig", "member_number": "TEST-123"}');
select pg_temp.as_owner();
select is((select created_in from public.ea_persons where id = (select id from ids where name = 'nora')), 'GR', 'created_in = GR');
select is((select preferred_name from public.ea_persons where id = (select id from ids where name = 'nora')), null,
  'leerer Rufname = null');
select is((pg_temp.prop((select id from ids where name = 'nora'), 'birth_date')).valid_from, date '2016-04-01',
  'Geburtsdatum mit valid_from = Geburtsdatum');
select is((pg_temp.prop((select id from ids where name = 'nora'), 'contact')).field_values,
  '{"street": "Neuweg 1", "postal_code": "04109", "city": "Leipzig"}'::jsonb, 'Kontaktdaten nur mit gesetzten Feldern');
select is((pg_temp.prop((select id from ids where name = 'nora'), 'member')).field_values,
  '{"is_member": true, "member_number": "TEST-123"}'::jsonb, 'Mitglied mit Nummer (R25)');
select is((select group_id from public.gr_pending_admissions where person_id = (select id from ids where name = 'nora')),
  'c0000000-0000-4000-8000-000000000001'::uuid, 'Aufnahme offen');

select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select throws_ok(format($$ select public.gr_start_admission('c0000000-0000-4000-8000-000000000002', %L) $$,
                        (select id from ids where name = 'nora')),
  'P0001', 'GR_PENDING_EXISTS', 'zweite offene Aufnahme (R10)');
select throws_ok($$ select public.gr_start_admission('c0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000023') $$,
  'P0001', 'GR_ALREADY_MEMBER', 'laufende Teilnahme an derselben Gruppe (R10)');

-- Admin (GR lesen) darf nicht; GR bearbeiten ohne verwalten: Geburtsdatum verboten
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select throws_ok($$ select public.gr_start_admission('c0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000012') $$,
  'P0001', 'GR_FORBIDDEN', 'Admin (Gruppen lesen) nimmt nicht auf');
select pg_temp.as_owner();
update public.ad_template_rights r set level = 'edit'
  from public.ad_templates t where t.id = r.template_id and t.name = 'Vorstand' and r.module_code = 'GR';
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select throws_ok($$ select public.gr_start_admission('c0000000-0000-4000-8000-000000000001', null,
                     '{"first_name": "Ole", "last_name": "Ohne", "birth_date": "2016-01-01", "street": "a",
                       "postal_code": "1", "city": "b"}') $$,
  'P0001', 'GR_BIRTH_DATE_FORBIDDEN', 'Geburtsdatum nur mit GR verwalten');

-- Übernahme einer nicht sichtbaren Person mit GR bearbeiten (Ü2)
select ok(not exists (select 1 from public.ea_persons where id = 'a0000000-0000-4000-8000-000000000012'),
  'Paul Nurgruppe vorher nicht sichtbar');
select lives_ok($$ select public.gr_start_admission('c0000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000012') $$,
  'nicht sichtbaren Dublettentreffer übernehmen');
select ok(exists (select 1 from public.ea_persons where id = 'a0000000-0000-4000-8000-000000000012'),
  'danach im Pfad GR sichtbar');
select throws_ok($$ select public.gr_start_admission('c0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000008') $$,
  'P0001', 'GR_PERSON_INVALID', 'Funktionsperson nicht übernehmbar');

-- Abbrechen: Zeile weg, Person nur noch über AD sichtbar
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select lives_ok($$ select public.gr_cancel_admission('a0000000-0000-4000-8000-000000000012') $$, 'Aufnahme abbrechen');
select ok(not exists (select 1 from public.ea_persons where id = 'a0000000-0000-4000-8000-000000000012'),
  'nach Abbruch nicht mehr im Pfad GR (Ü4)');

-- Erziehungsberechtigte (R3, R22, R26)
select throws_ok(format($$ select public.gr_add_guardian(%L, null, '{"first_name": "Nina", "last_name": "Neu"}') $$,
                        (select id from ids where name = 'nora')),
  'P0001', 'GR_GUARDIAN_FIELDS_REQUIRED', 'Adresse der Erziehungsberechtigten Pflicht (R26)');
insert into ids
select 'nina', public.gr_add_guardian((select id from ids where name = 'nora'), null,
  '{"first_name": "Nina", "last_name": "Neu", "street": "Elternweg 5", "postal_code": "04103", "city": "Leipzig",
    "email": "nina.neu@example.test"}');
select ok((pg_temp.prop((select id from ids where name = 'nina'), 'birth_date')).id is null,
  'kein Geburtsdatum für Erziehungsberechtigte');
select throws_ok(format($$ select public.gr_add_guardian(%L, %L) $$,
                        (select id from ids where name = 'nora'), (select id from ids where name = 'nina')),
  'P0001', 'GR_GUARDIAN_EXISTS', 'doppelte Zuordnung (R22)');
select lives_ok(format($$ select public.gr_add_guardian(%L, 'a0000000-0000-4000-8000-000000000026') $$,
                       (select id from ids where name = 'nora')), 'zweite erziehungsberechtigte Person');
select throws_ok(format($$ select public.gr_add_guardian(%L, 'a0000000-0000-4000-8000-000000000024') $$,
                        (select id from ids where name = 'nora')),
  'P0001', 'GR_GUARDIAN_LIMIT', 'höchstens zwei (R3)');
select throws_ok($$ select public.gr_remove_guardian('a0000000-0000-4000-8000-000000000023', 'a0000000-0000-4000-8000-000000000024') $$,
  'P0001', 'GR_GUARDIAN_IS_HOLDER', 'Vertragsinhaberin nicht entfernbar (R22)');
select lives_ok(format($$ select public.gr_remove_guardian(%L, 'a0000000-0000-4000-8000-000000000026') $$,
                       (select id from ids where name = 'nora')), 'Erziehungsberechtigten entfernen');

-- Adresse übernehmen (A3)
select lives_ok(format($$ select public.gr_copy_address(%L, %L) $$,
                       (select id from ids where name = 'nora'), (select id from ids where name = 'nina')), 'Adresse übernehmen');
select pg_temp.as_owner();
select is((pg_temp.prop((select id from ids where name = 'nora'), 'contact')).field_values ->> 'street', 'Elternweg 5',
  'Straße übernommen');
select is((select count(*)::int from public.ea_property_history h
             where h.property_id = (pg_temp.prop((select id from ids where name = 'nora'), 'contact')).id), 1,
  'Änderung der Kontaktdaten mit Historie');

-- Notfallkontakte (R7, R23)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select throws_ok(format($$ select public.gr_add_emergency_contact(%L, null, '{"first_name": "Otto", "last_name": "Opa"}') $$,
                        (select id from ids where name = 'nora')),
  'P0001', 'GR_CONTACT_REACHABILITY', 'Notfallkontakt braucht Telefon oder E-Mail (R7)');
insert into ids
select 'otto', public.gr_add_emergency_contact((select id from ids where name = 'nora'), null,
  '{"first_name": "Otto", "last_name": "Opa", "phone_landline": "0341 000000"}');
select lives_ok(format($$ select public.gr_add_emergency_contact(%L, %L) $$,
                       (select id from ids where name = 'nora'), (select id from ids where name = 'nina')),
  'vorhandene Person als Notfallkontakt');
select throws_ok(format($$ select public.gr_add_emergency_contact(%L, %L) $$,
                        (select id from ids where name = 'nora'), (select id from ids where name = 'otto')),
  'P0001', 'GR_EMERGENCY_EXISTS', 'einmal je Kind (R23)');
select throws_ok(format($$ select public.gr_add_emergency_contact(%L, 'a0000000-0000-4000-8000-000000000025') $$,
                        (select id from ids where name = 'nora')),
  'P0001', 'GR_CONTACT_REACHABILITY', 'vorhandene Person ohne Erreichbarkeit');
select results_eq(format($$ select contact_person_id, sort_order from public.gr_emergency_contacts
                             where child_person_id = %L order by sort_order $$, (select id from ids where name = 'nora')),
  format($$ values (%L::uuid, 1), (%L::uuid, 2) $$, (select id from ids where name = 'otto'), (select id from ids where name = 'nina')),
  'Reihenfolge = höchste + 1');
select throws_ok(format($$ select public.gr_reorder_emergency_contacts(%L, array[%L]::uuid[]) $$,
                        (select id from ids where name = 'nora'), (select id from ids where name = 'nina')),
  'P0001', 'GR_ORDER_INVALID', 'unvollständige Reihenfolge');
select lives_ok(format($$ select public.gr_reorder_emergency_contacts(%L, array[%L, %L]::uuid[]) $$,
                       (select id from ids where name = 'nora'), (select id from ids where name = 'nina'),
                       (select id from ids where name = 'otto')), 'Reihenfolge ändern');
select is((select sort_order from public.gr_emergency_contacts
            where child_person_id = (select id from ids where name = 'nora') and contact_person_id = (select id from ids where name = 'nina')),
  1, 'Nina jetzt zuerst');
select lives_ok(format($$ select public.gr_remove_emergency_contact(%L, %L) $$,
                       (select id from ids where name = 'nora'), (select id from ids where name = 'nina')), 'entfernen');
select is((select sort_order from public.gr_emergency_contacts
            where child_person_id = (select id from ids where name = 'nora')), 1, 'übrige neu nummeriert');

-- Personenangaben ändern (R2, R7, R25)
select throws_ok(format($$ select public.gr_update_person(%L, '{"phone_landline": ""}') $$, (select id from ids where name = 'otto')),
  'P0001', 'GR_CONTACT_REACHABILITY', 'Notfallkontakt bleibt erreichbar (R7)');
select throws_ok(format($$ select public.gr_update_person(%L, '{"street": ""}') $$, (select id from ids where name = 'nora')),
  'P0001', 'GR_PARTICIPANT_FIELDS_REQUIRED', 'Teilnehmer:in bleibt mit Adresse (R2)');
select throws_ok(format($$ select public.gr_update_person(%L, '{"city": ""}') $$, (select id from ids where name = 'nina')),
  'P0001', 'GR_GUARDIAN_FIELDS_REQUIRED', 'Erziehungsberechtigte bleibt mit Adresse (R26)');
select lives_ok(format($$ select public.gr_update_person(%L, '{"preferred_name": "Nori", "member_number": ""}') $$,
                       (select id from ids where name = 'nora')), 'Rufname setzen, Mitgliedsnummer leeren');
select pg_temp.as_owner();
select is((select preferred_name from public.ea_persons where id = (select id from ids where name = 'nora')), 'Nori', 'Rufname');
select is((pg_temp.prop((select id from ids where name = 'nora'), 'member')).valid_to,
  (pg_temp.prop((select id from ids where name = 'nora'), 'member')).valid_from,
  'Mitglied endet beim Leeren zum Vortag, frühestens am Beginn (R25)');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select throws_ok($$ select public.gr_update_person('a0000000-0000-4000-8000-000000000027', '{"preferred_name": "Lea"}') $$,
  'P0001', 'GR_FORBIDDEN', 'Person ohne laufenden Bezug nicht änderbar');

select * from finish();
rollback;
