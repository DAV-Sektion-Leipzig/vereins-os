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

-- zweiter Lauf (gleiche Anweisung wie in der Migration) ändert nichts
create function pg_temp.rerun() returns void language sql as $$
  insert into public.ad_qualification_types (code, name, discipline, kind, validity_years, issuer, status)
  select v.code, v.name, v.discipline, v.kind, v.validity_years, v.issuer, 'current'
    from (values
      ('EH', 'Erste Hilfe (mind. 9 UE)', 'Allgemein', 'training'::public.ad_qualification_kind, 2::smallint, 'extern'),
      ('RS', 'Rettungsschwimmer', 'Allgemein', 'training', 2, 'extern'),
      ('AMAK', 'JDAV-Aufbaumodul Alpinklettern', 'Jugend und Familie', 'course', null, 'Bundesverband (JDAV)')
    ) as v (code, name, discipline, kind, validity_years, issuer)
   where not exists (select 1 from public.ad_qualification_types q where lower(q.name) = lower(v.name))
$$;
select lives_ok($$ select pg_temp.rerun() $$, 'zweiter Lauf ohne Fehler');
select is((select count(*)::int from public.ad_qualification_types), 57, 'zweiter Lauf legt nichts doppelt an');

-- Änderung aus der Oberfläche bleibt: Gültigkeitsdauer von EH auf 3 gesetzt, zweiter Lauf lässt sie
update public.ad_qualification_types set validity_years = 3 where code = 'EH';
select pg_temp.rerun();
select is((select validity_years::int from public.ad_qualification_types where code = 'EH'), 3, 'kein Überschreiben (AK3)');

-- Umbenennung: der zweite Lauf legt nichts Neues unter dem alten Kürzel an, sondern bricht gewollt ab (R-EA-04)
update public.ad_qualification_types set name = 'Erste Hilfe' where code = 'EH';
select throws_ok($$ select pg_temp.rerun() $$, 'P0001', 'AD_QUALIFICATION_CODE_TAKEN',
  'Kürzel-Konflikt bricht ab statt still auszulassen');

select * from finish();
rollback;
