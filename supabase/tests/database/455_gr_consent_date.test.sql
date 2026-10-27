-- Review-Befund D-02 (R12, R24): Fotoerlaubnis und Einwilligung zu Gesundheitsangaben nicht vor dem aktuellen
-- Eintrag datieren; ein rückdatierter Widerruf würde sonst gespeichert, bliebe aber wirkungslos.
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

create function pg_temp.as_user(p_user uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', p_user, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
end $$;

-- Liefert das detail der Ausnahme einer Anweisung
create function pg_temp.detail_of(p_sql text) returns text language plpgsql as $$
declare v_detail text;
begin
  execute p_sql;
  return null;
exception when others then
  get stacked diagnostics v_detail = pg_exception_detail;
  return v_detail;
end $$;

select pg_temp.as_user('b0000000-0000-4000-8000-000000000002');

-- Gesundheit: „ja“ vor 7 Tagen, Widerruf 5 Tage davor wird abgelehnt
select lives_ok($$ select public.gr_set_health_consent('a0000000-0000-4000-8000-000000000028', true, public.gr_today() - 7) $$,
  'Einwilligung ja');
select throws_ok($$ select public.gr_set_health_consent('a0000000-0000-4000-8000-000000000028', false, public.gr_today() - 12) $$,
  'P0001', 'GR_CONSENT_DATE_BEFORE_CURRENT', 'Widerruf vor dem aktuellen Eintrag abgelehnt (Gesundheit)');
select is((select count(*)::int from public.gr_health_consents where person_id = 'a0000000-0000-4000-8000-000000000028'), 1,
  'kein wirkungsloser Eintrag gespeichert');
select ok(public.gr_can_read_health('a0000000-0000-4000-8000-000000000028'), 'vor dem Widerruf lesbar');

-- detail enthält das Datum des aktuellen Eintrags (TT.MM.JJJJ) für die Meldung
select is(pg_temp.detail_of($$ select public.gr_set_health_consent('a0000000-0000-4000-8000-000000000028', false, public.gr_today() - 12) $$),
  to_char(public.gr_today() - 7, 'DD.MM.YYYY'), 'detail = Datum des aktuellen Eintrags');

-- gleicher Tag ist erlaubt und wirkt (created_at/id entscheiden)
select lives_ok($$ select public.gr_set_health_consent('a0000000-0000-4000-8000-000000000028', false, public.gr_today() - 7) $$,
  'Widerruf am selben Tag');
select ok(not public.gr_can_read_health('a0000000-0000-4000-8000-000000000028'), 'nach Widerruf am selben Tag nicht lesbar');

-- Foto: „ja“ vor 7 Tagen; früher abgelehnt, später erlaubt
select lives_ok($$ select public.gr_set_photo_consent('a0000000-0000-4000-8000-000000000025', true, public.gr_today() - 7) $$,
  'Fotoerlaubnis ja');
select throws_ok($$ select public.gr_set_photo_consent('a0000000-0000-4000-8000-000000000025', false, public.gr_today() - 12) $$,
  'P0001', 'GR_CONSENT_DATE_BEFORE_CURRENT', 'Widerruf vor dem aktuellen Eintrag abgelehnt (Foto)');
select lives_ok($$ select public.gr_set_photo_consent('a0000000-0000-4000-8000-000000000025', false, public.gr_today() - 6) $$,
  'Widerruf am Folgetag');
select is((select granted from public.gr_photo_consents where person_id = 'a0000000-0000-4000-8000-000000000025'
            order by effective_on desc, created_at desc, id desc limit 1), false, 'aktueller Stand „nein“');

-- Prüfreihenfolge: unveränderter Wert meldet weiterhin GR_CONSENT_UNCHANGED
select throws_ok($$ select public.gr_set_photo_consent('a0000000-0000-4000-8000-000000000025', false, public.gr_today() - 12) $$,
  'P0001', 'GR_CONSENT_UNCHANGED', 'gleicher Wert bleibt GR_CONSENT_UNCHANGED');

select * from finish();
rollback;
