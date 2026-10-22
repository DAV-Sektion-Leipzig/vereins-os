-- US-AD-07, US-AD-25 (spec T7 Teil, T43, T45): Dublettenprüfung nach R3a und R40;
-- erwartete Ergebnisse nach spec.md Abschnitt 9 („Erwartete Ergebnisse der Dublettenprüfung“, „Namensregel R3a“).
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
create function pg_temp.hits(p_first text, p_last text, p_email text) returns int[] language sql as $$
  select coalesce(array_agg(right(person_id::text, 2)::int order by person_id), '{}')
    from public.ad_find_similar_persons(p_first, p_last, p_email)
$$;
create function pg_temp.birth_year_4() returns int language sql as $$
  select birth_year from public.ad_find_similar_persons('Toni', 'Muster', null)
   where person_id = 'a0000000-0000-4000-8000-000000000004'
$$;

-- ad_first_names_match (R3a)
select ok(public.ad_first_names_match('Toni', 'Anton'), 'Toni/Anton: gemeinsam „ton“');
select ok(public.ad_first_names_match('Jo', 'Johanna'), 'Jo/Johanna: enthalten');
select ok(public.ad_first_names_match('Ben', 'Benjamin'), 'Ben/Benjamin');
select ok(not public.ad_first_names_match('Paul', 'Anton'), 'Paul/Anton nicht');
select ok(not public.ad_first_names_match('', 'Anton'), 'leer → falsch');
select ok(not public.ad_first_names_match(null, 'Anton'), 'null → falsch');
select ok(public.ad_first_names_match(' TONY ', 'toni'), 'Trigramm-Ähnlichkeit, getrimmt, ohne Groß-/Kleinschreibung');

-- Namensregel R3a, Aufruf als Admin
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select is(pg_temp.hits('Anton', 'Muster', null), array[4, 5], '(Anton, Muster) → 4 und 5');
select is(pg_temp.hits('Toni', 'Muster', null), array[4, 5], '(Toni, Muster) → 4 und 5');
select is(pg_temp.hits(' toni ', 'MUSTER', null), array[4, 5], 'Trimmen, Groß-/Kleinschreibung');
select is(pg_temp.hits('Paul', 'Muster', null), '{}'::int[], '(Paul, Muster) → keine');
select is(pg_temp.hits('Toni', 'Mustermann', null), '{}'::int[], 'Nachname nicht gleich → keine');
select is(pg_temp.hits('X', 'Y', 'paul.nurgruppe@example.test'), array[12], 'E-Mail aus Feld email der Art contact');
select is(pg_temp.hits('X', 'Y', 'TEST.REFERENT@dav-leipzig.de'), array[9], 'Login-Adresse ohne Groß-/Kleinschreibung');
select is(pg_temp.hits('Geschäftsstelle', 'Notfall-Admin', null), '{}'::int[], 'Funktionsperson nie');

-- Nur die Spalten nach R40
select results_eq(
  $$ select first_name, last_name, preferred_name, birth_year, volunteer_status::text, left_since
       from public.ad_find_similar_persons('Olga', 'Ausgeschieden', null) $$,
  $$ values ('Olga'::text, 'Ausgeschieden'::text, null::text, null::int, 'left'::text, date '2025-06-30') $$,
  '„ausgeschieden seit“ bei Ausgeschiedenen');
select is((select left_since from public.ad_find_similar_persons('Toni', 'Muster', null)
            where person_id = 'a0000000-0000-4000-8000-000000000004'), null, 'kein „seit“ bei Aktiven');

-- Geburtsjahr nach Lesestufe und Rechten (R40, Ü2)
select is(pg_temp.birth_year_4(), 1990, 'Admin: 1990');
select is((select birth_year from public.ad_find_similar_persons('Toni', 'Muster', null)
            where person_id = 'a0000000-0000-4000-8000-000000000005'), null, 'Person 5 ohne Geburtsdatum');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select is(pg_temp.birth_year_4(), 1990, 'Geschäftsstelle: 1990');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select is(pg_temp.birth_year_4(), null, 'Referent:in: null (nur Geschäftsstelle und Admin)');
select is((select is_visible from public.ad_find_similar_persons('Toni', 'Muster', null)
            where person_id = 'a0000000-0000-4000-8000-000000000005'), false, 'Person 5 für Referent:in nicht sichtbar');
select is((select is_visible from public.ad_find_similar_persons('Toni', 'Muster', null)
            where person_id = 'a0000000-0000-4000-8000-000000000004'), true, 'Person 4 für Referent:in sichtbar');

select pg_temp.as_owner();
update public.ea_property_types set read_level = 'confidential' where system_key = 'birth_date';
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select is(pg_temp.birth_year_4(), null, 'Geschäftsstelle bei „vertraulich“: null');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select is(pg_temp.birth_year_4(), 1990, 'Admin bei „vertraulich“: 1990');
select pg_temp.as_owner();
update public.ea_property_types set read_level = 'all' where system_key = 'birth_date';
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select is(pg_temp.birth_year_4(), 1990, 'Referent:in bei „alle mit Zugriff“: 1990');

-- Recht zum Aufruf
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select throws_ok($$ select * from public.ad_find_similar_persons('Toni', 'Muster', null) $$,
  'P0001', 'AD_FORBIDDEN', 'Vorstand: AD_FORBIDDEN');

select pg_temp.as_owner();
select * from finish();
rollback;
