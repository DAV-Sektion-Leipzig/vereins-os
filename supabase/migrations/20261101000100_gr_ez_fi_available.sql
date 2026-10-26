-- Freigabe Gruppen (GR), Anwesenheitserfassung (EZ) und Finanzen (FI) auf Startseite und Navigation
-- (Entscheidung Product Owner 26.10.2026 nach der Abnahme Finanzen in TEST, fi-finanzen/abnahme-test.md).
-- Sichtbar ist eine Kachel nur mit Recht auf das Modul (ad_my_modules).

update public.ad_modules set is_available = true where code in ('GR', 'EZ', 'FI');
