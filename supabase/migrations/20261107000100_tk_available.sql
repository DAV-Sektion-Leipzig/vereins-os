-- Freigabe Planungshilfe Touren und Kurse (TK) auf Startseite und Navigation (spec T22, tasks.md T026;
-- Entscheidung Product Owner 27.10.2026 nach der Abnahme in TEST, tk-touren-kurse/abnahme-test.md).
-- Sichtbar ist die Kachel nur mit Recht auf das Modul (ad_my_modules).

update public.ad_modules set is_available = true where code = 'TK';
