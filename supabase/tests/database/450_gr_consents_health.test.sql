-- US-GR-10, US-GR-12 (GR spec T6, T10): Fotoerlaubnis und Einwilligung mit Historie (R12, R24), Gesundheitsangaben
-- nur mit Einwilligung und GR ≥ bearbeiten, nie über „Gruppen lesen“ oder den Pfad AD (R11).
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

-- Fotoerlaubnis (R12)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select throws_ok($$ select public.gr_set_photo_consent('a0000000-0000-4000-8000-000000000025', true, null) $$,
  'P0001', 'GR_CONSENT_DATE_REQUIRED', 'Datum Pflicht');
select throws_ok($$ select public.gr_set_photo_consent('a0000000-0000-4000-8000-000000000025', true, public.gr_today() + 1) $$,
  'P0001', 'GR_DATE_IN_FUTURE', 'Datum nicht in der Zukunft');
select throws_ok($$ select public.gr_set_photo_consent('a0000000-0000-4000-8000-000000000025', false, public.gr_today()) $$,
  'P0001', 'GR_CONSENT_UNCHANGED', 'ohne Eintrag gilt „nein“');
select lives_ok($$ select public.gr_set_photo_consent('a0000000-0000-4000-8000-000000000025', true, public.gr_today()) $$, 'ja');
select lives_ok($$ select public.gr_set_photo_consent('a0000000-0000-4000-8000-000000000025', false, public.gr_today()) $$,
  'Widerruf am selben Tag');
select results_eq($$ select granted from public.gr_photo_consents where person_id = 'a0000000-0000-4000-8000-000000000025'
                      order by effective_on, created_at, id $$,
  $$ values (true), (false) $$, 'Historie bleibt (R12)');
select ok((select created_by from public.gr_photo_consents where person_id = 'a0000000-0000-4000-8000-000000000025' limit 1)
          = 'b0000000-0000-4000-8000-000000000002', 'ändernde Person gespeichert');

-- Gesundheitsangaben (R11, R24)
select throws_ok($$ select public.gr_save_health_note('a0000000-0000-4000-8000-000000000028', 'Brille') $$,
  'P0001', 'GR_HEALTH_CONSENT_REQUIRED', 'ohne Einwilligung nicht speicherbar (R24)');
select lives_ok($$ select public.gr_set_health_consent('a0000000-0000-4000-8000-000000000028', true, public.gr_today()) $$,
  'Einwilligung ja');
select throws_ok($$ select public.gr_save_health_note('a0000000-0000-4000-8000-000000000028', '   ') $$,
  'P0001', 'GR_HEALTH_NOTE_INVALID', 'leerer Text');
select throws_ok($$ select public.gr_save_health_note('a0000000-0000-4000-8000-000000000028', repeat('x', 2001)) $$,
  'P0001', 'GR_HEALTH_NOTE_INVALID', 'höchstens 2000 Zeichen');
select lives_ok($$ select public.gr_save_health_note('a0000000-0000-4000-8000-000000000028', 'Brille') $$, 'speichern');
select lives_ok($$ select public.gr_save_health_note('a0000000-0000-4000-8000-000000000028', 'Brille, Heuschnupfen') $$, 'ändern');
select is((select note from public.gr_health_note_history where person_id = 'a0000000-0000-4000-8000-000000000028'), 'Brille',
  'alte Fassung in der Historie');
select lives_ok($$ select public.gr_save_health_note('a0000000-0000-4000-8000-000000000028', 'Brille, Heuschnupfen') $$,
  'gleicher Text');
select is((select count(*)::int from public.gr_health_note_history where person_id = 'a0000000-0000-4000-8000-000000000028'), 1,
  'gleicher Text erzeugt keine Historienzeile');

-- Widerruf: Text bleibt gespeichert, ist aber nicht lesbar; erneut „ja“ macht ihn wieder lesbar (R24)
select lives_ok($$ select public.gr_set_health_consent('a0000000-0000-4000-8000-000000000028', false, public.gr_today()) $$,
  'Widerruf');
select is((select count(*)::int from public.gr_health_notes where person_id = 'a0000000-0000-4000-8000-000000000028'), 0,
  'nach Widerruf nicht lesbar');
select throws_ok($$ select public.gr_save_health_note('a0000000-0000-4000-8000-000000000028', 'neu') $$,
  'P0001', 'GR_HEALTH_CONSENT_REQUIRED', 'nach Widerruf nicht speicherbar');
select pg_temp.as_owner();
select is((select note from public.gr_health_notes where person_id = 'a0000000-0000-4000-8000-000000000028'), 'Brille, Heuschnupfen',
  'Text bleibt gespeichert');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');
select lives_ok($$ select public.gr_set_health_consent('a0000000-0000-4000-8000-000000000028', true, public.gr_today()) $$,
  'erneut ja');
select is((select count(*)::int from public.gr_health_notes where person_id = 'a0000000-0000-4000-8000-000000000028'), 1,
  'wieder lesbar');

-- Ohne „Gruppen bearbeiten“: nichts lesen, nichts schreiben (R11)
select pg_temp.as_user('b0000000-0000-4000-8000-000000000001');
select throws_ok($$ select public.gr_save_health_note('a0000000-0000-4000-8000-000000000023', 'x') $$,
  'P0001', 'GR_FORBIDDEN', 'Admin schreibt keine Gesundheitsangaben');
select throws_ok($$ select public.gr_set_health_consent('a0000000-0000-4000-8000-000000000023', false, public.gr_today()) $$,
  'P0001', 'GR_FORBIDDEN', 'Admin setzt keine Einwilligung');
select is((select count(*)::int from public.gr_health_notes) + (select count(*)::int from public.gr_health_note_history)
          + (select count(*)::int from public.gr_health_consents), 0, 'Admin liest nichts davon');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000009');
select is((select count(*)::int from public.gr_health_notes) + (select count(*)::int from public.gr_health_consents), 0,
  'Referent:in liest nichts davon');
select pg_temp.as_user('b0000000-0000-4000-8000-000000000032');
select is((select count(*)::int from public.gr_health_notes) + (select count(*)::int from public.gr_health_consents), 0,
  'Kim liest nichts davon');
select pg_temp.as_owner();
update public.ad_template_rights r set level = 'read'
  from public.ad_templates t where t.id = r.template_id and t.name = 'Vorstand' and r.module_code = 'GR';
select pg_temp.as_user('b0000000-0000-4000-8000-000000000003');
select is((select count(*)::int from public.gr_health_notes) + (select count(*)::int from public.gr_health_consents), 0,
  'Vorstand mit „Gruppen lesen“ liest nichts davon');
select throws_ok($$ select public.gr_set_photo_consent('a0000000-0000-4000-8000-000000000023', false, public.gr_today()) $$,
  'P0001', 'GR_FORBIDDEN', '„Gruppen lesen“ ändert keine Fotoerlaubnis');

select * from finish();
rollback;
