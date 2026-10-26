-- Freigabe Dashboard (DS) auf Startseite und Navigation (Entscheidung Product Owner 27.10.2026 nach der Abnahme in
-- TEST, ds-dashboard/abnahme-test.md; tasks.md DT19). Sichtbar ist das Dashboard nur mit Recht auf DS (ad_my_modules);
-- die Startseite zeigt dann „Zu tun“ und das Budget (US-DS-20).

update public.ad_modules set is_available = true where code = 'DS';
