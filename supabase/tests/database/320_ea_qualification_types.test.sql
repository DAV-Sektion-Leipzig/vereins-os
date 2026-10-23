-- US-EA-16 (EA spec T9 Teil, T2): 10 Qualifikationsarten nach 01-erhebung.md C4; idempotent über die Bezeichnung.
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

select is((select count(*)::int from public.ad_qualification_types), 57, '47 aus der Administration + 10 (AK3)');
select results_eq(
  $$ select code, name, discipline, kind::text, validity_years::int, issuer, status::text, level::text, source_ref
       from public.ad_qualification_types
      where code in ('EH', 'RS', 'AMAK', 'AMBS', 'AMHT', 'AMKS', 'AMMB', 'AMSB', 'AMSH', 'AMSK')
      order by code collate "C" $$,
  $$ values
     ('AMAK'::text, 'JDAV-Aufbaumodul Alpinklettern'::text, 'Jugend und Familie'::text, 'course'::text, null::int, 'Bundesverband (JDAV)'::text, 'current'::text, null::text, null::text),
     ('AMBS', 'JDAV-Aufbaumodul Bergsteigen', 'Jugend und Familie', 'course', null, 'Bundesverband (JDAV)', 'current', null, null),
     ('AMHT', 'JDAV-Aufbaumodul Hochtouren', 'Jugend und Familie', 'course', null, 'Bundesverband (JDAV)', 'current', null, null),
     ('AMKS', 'JDAV-Aufbaumodul Klettersteig', 'Jugend und Familie', 'course', null, 'Bundesverband (JDAV)', 'current', null, null),
     ('AMMB', 'JDAV-Aufbaumodul Mountainbike', 'Jugend und Familie', 'course', null, 'Bundesverband (JDAV)', 'current', null, null),
     ('AMSB', 'JDAV-Aufbaumodul Skibergsteigen', 'Jugend und Familie', 'course', null, 'Bundesverband (JDAV)', 'current', null, null),
     ('AMSH', 'JDAV-Aufbaumodul Skihochtouren', 'Jugend und Familie', 'course', null, 'Bundesverband (JDAV)', 'current', null, null),
     ('AMSK', 'JDAV-Aufbaumodul Sportklettern', 'Jugend und Familie', 'course', null, 'Bundesverband (JDAV)', 'current', null, null),
     ('EH', 'Erste Hilfe (mind. 9 UE)', 'Allgemein', 'training', 2, 'extern', 'current', null, null),
     ('RS', 'Rettungsschwimmer', 'Allgemein', 'training', 2, 'extern', 'current', null, null)
  $$, 'Kürzel, Bezeichnung, Sparte, Typ, Gültigkeitsdauer, Aussteller nach C4');

-- zweiter Lauf über die interne Funktion der Migration ändert nichts
select lives_ok($$ select public.ea_seed_qualification_types() $$, 'zweiter Lauf ohne Fehler');
select is((select count(*)::int from public.ad_qualification_types), 57, 'zweiter Lauf legt nichts doppelt an');

-- Änderung aus der Oberfläche bleibt: Gültigkeitsdauer von EH auf 3 gesetzt, zweiter Lauf lässt sie
update public.ad_qualification_types set validity_years = 3 where code = 'EH';
select public.ea_seed_qualification_types();
select is((select validity_years::int from public.ad_qualification_types where code = 'EH'), 3, 'kein Überschreiben (AK3)');

-- Umbenennung: der nächste Lauf legt nichts unter dem alten Kürzel an, sondern bricht gewollt ab (R-EA-04)
update public.ad_qualification_types set name = 'Erste Hilfe' where code = 'EH';
select throws_ok($$ select public.ea_seed_qualification_types() $$, 'P0001', 'AD_QUALIFICATION_CODE_TAKEN',
  'Kürzel-Konflikt bricht ab statt still auszulassen');

select ok(not has_function_privilege('authenticated', 'public.ea_seed_qualification_types()', 'EXECUTE'),
  'ea_seed_qualification_types nicht für authenticated');

select * from finish();
rollback;
