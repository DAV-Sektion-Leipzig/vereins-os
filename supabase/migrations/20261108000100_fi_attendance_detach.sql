-- Finanzen (FI), Prüfbericht B-01: Positionen in Abrechnungen im Entwurf blockieren die Pflege der Anwesenheiten nicht.
-- Bisher verhinderte fi_settlement_items.attendance_id (on delete restrict) nach der ersten Halbjahresberechnung
-- das Entfernen einer Person aus einem Einsatz (ez_save_event, ez_upsert_planned_event) mit Fehler 23503, obwohl
-- nach R34 (spec.md EZ) nur Anwesenheiten in abgeschlossenen Abrechnungen gesperrt sind.
--
-- Neu: on delete set null. Die Position bleibt bis zur nächsten Neuberechnung stehen; fi_calculate_half entfernt sie
-- dann (Abgleich je Person, Einsatz und Position, R15) und setzt die Bestätigung der betroffenen Referate zurück (R23).
-- Abgerechnete Anwesenheiten (closed, submitted, expired, paid) bleiben geschützt: ez_save_event (Schritt 10a) und
-- ez_upsert_planned_event lehnen ihr Entfernen über fi_attendance_locked bzw. fi_event_locked mit EZ_SETTLED ab,
-- ez_delete_event über fi_event_locked; ein anderer Löschweg für ez_attendances besteht nicht.
-- event_id bleibt on delete restrict (Pflichtfeld, Teil des Schlüssels); Löschen eines Einsatzes mit Positionen im
-- Entwurf ist offener Punkt (Pull Request zu B-01).

alter table public.fi_settlement_items
  drop constraint fi_settlement_items_attendance_id_fkey;

alter table public.fi_settlement_items
  add constraint fi_settlement_items_attendance_id_fkey
  foreign key (attendance_id) references public.ez_attendances (id) on delete set null;

comment on column public.fi_settlement_items.attendance_id is
  'Anwesenheit der Position; null bei der Organisationspauschale einer nicht anwesenden organisierenden Person oder wenn die Anwesenheit nach der Berechnung entfernt wurde (bis zur nächsten Neuberechnung, Prüfbericht B-01).';
