-- US-EA-16, spec T2 (EA spec.md 2.2): 10 Qualifikationsarten nach docs/specs/ea-ehrenamt/01-erhebung.md C4.
-- Idempotent über die Bezeichnung (lower(name)), ohne Überschreiben (research.md R-EA-04).
-- Ein Kürzel-Konflikt (gleiches Kürzel unter anderer Bezeichnung) bricht gewollt über den Trigger
-- ad_qualification_types_guard (AD_QUALIFICATION_CODE_TAKEN) ab, statt Lücken im Import zu verdecken.

insert into public.ad_qualification_types (code, name, discipline, kind, validity_years, issuer, status)
select v.code, v.name, v.discipline, v.kind, v.validity_years, v.issuer, 'current'
  from (values
    ('EH', 'Erste Hilfe (mind. 9 UE)', 'Allgemein', 'training'::public.ad_qualification_kind, 2::smallint, 'extern'),
    ('RS', 'Rettungsschwimmer', 'Allgemein', 'training', 2, 'extern'),
    ('AMAK', 'JDAV-Aufbaumodul Alpinklettern', 'Jugend und Familie', 'course', null, 'Bundesverband (JDAV)'),
    ('AMBS', 'JDAV-Aufbaumodul Bergsteigen', 'Jugend und Familie', 'course', null, 'Bundesverband (JDAV)'),
    ('AMHT', 'JDAV-Aufbaumodul Hochtouren', 'Jugend und Familie', 'course', null, 'Bundesverband (JDAV)'),
    ('AMKS', 'JDAV-Aufbaumodul Klettersteig', 'Jugend und Familie', 'course', null, 'Bundesverband (JDAV)'),
    ('AMMB', 'JDAV-Aufbaumodul Mountainbike', 'Jugend und Familie', 'course', null, 'Bundesverband (JDAV)'),
    ('AMSB', 'JDAV-Aufbaumodul Skibergsteigen', 'Jugend und Familie', 'course', null, 'Bundesverband (JDAV)'),
    ('AMSH', 'JDAV-Aufbaumodul Skihochtouren', 'Jugend und Familie', 'course', null, 'Bundesverband (JDAV)'),
    ('AMSK', 'JDAV-Aufbaumodul Sportklettern', 'Jugend und Familie', 'course', null, 'Bundesverband (JDAV)')
  ) as v (code, name, discipline, kind, validity_years, issuer)
 where not exists (select 1 from public.ad_qualification_types q where lower(q.name) = lower(v.name));
