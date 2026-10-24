-- US-EA-01 AK1 (spec T22, T055): Ehrenamtsmanagement auf der Startseite und in der Navigation freischalten.
-- Nach der Abnahme in TEST (T053, quickstart.md D 1–13). Sichtbar ist die Kachel nur mit Recht auf EA (ad_my_modules).

update public.ad_modules set is_available = true where code = 'EA';
