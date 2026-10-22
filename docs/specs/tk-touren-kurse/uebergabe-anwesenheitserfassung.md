# Übergabe: Planungshilfe Touren und Kurse → Anwesenheitserfassung

Stand: 22.10.2026 · Version 1.2 · Status: offen · Von: Planungshilfe Touren und Kurse (TK) · An: Anwesenheitserfassung (EZ)
Änderungen v1.2: Bei Absage wird der Einsatz als „abgesagt“ markiert statt gelöscht (Product Owner 22.10.2026).
Änderungen v1.1: Einsatz entsteht mit Status „in Yolawo angelegt“ (nicht bei Freigabe); Kurse mit Referat Ausbildung (Product Owner 22.10.2026).
Änderungen v1.0: Erste Fassung; beantwortet den offenen Punkt der Anwesenheitserfassung „Übernahme geplanter Kurse und Touren als Einsatz“.

Grundlage: docs/specs/tk-touren-kurse/00-steckbrief.md v0.3, 01-erhebung.md v0.3 (B5).

## Entscheidung (Product Owner 22.10.2026)

Die Planungshilfe Touren und Kurse **erzeugt** den Einsatz. Kurs und Tour werden in der Anwesenheitserfassung nicht mehr von Hand angelegt [ANNAHME: Ausnahme Kurse außerhalb von TK, siehe offen]. Zeitpunkt: wenn die Planung den Status „in Yolawo angelegt“ erhält. Referat: Touren bei Touren, Ausbildung bei Kursen.

## Anforderungen an die Anwesenheitserfassung

1. Einsatzarten `course` und `tour` freischalten (Check `ez_events_kind_mvp`), sobald TK umgesetzt wird.
2. Form für `course` und `tour` in `ez_events_shape`: ohne Gruppe, Referat Pflicht, Titel Pflicht, eintägig mit Dauer-Kategorie oder mehrtägig mit Start/Ende, organisierende Person Pflicht [ANNAHME], kein Ort.
3. Spalte `ez_events.tk_plan_id` (uuid, FK auf die Planung, unique, nullable) [ANNAHME: Name].
4. Funktion `ez_upsert_planned_event(p_tk_plan_id, p_kind, p_referat_id, p_title, p_span, p_start_date, p_start_time, p_end_date, p_end_time, p_day_category, p_organizer_person_id, p_persons jsonb)` – security definer, nur aufrufbar aus TK-Funktionen bzw. mit TK-Schreibrecht im Referat; legt an oder aktualisiert; `p_persons` = Liste (person_id, role `trainer`/`helper`), Stand `registered`.
5. Aktualisieren nur, solange keine Anwesenheit `present` existiert; sonst Fehler `EZ_EVENT_LOCKED` (TK zeigt Hinweis).
6. Neuer Stand eines Einsatzes „abgesagt“ (z. B. Spalte `ez_events.cancelled_at` mit Grund, oder Status-Enum) und Funktion `ez_cancel_planned_event(p_tk_plan_id, p_reason)`; abgesagte Einsätze bleiben sichtbar, sind nicht mehr bearbeitbar und zählen nicht für Abrechnung und Auswertung (Product Owner 22.10.2026). [OFFEN] Gilt „abgesagt“ auch für andere Einsatzarten?
7. Lesefunktion `ez_planned_event_state(p_tk_plan_id)` → Einsatz-ID, Anzahl anwesend je Rolle, „durchgeführt“ (mind. eine Leitung `present`) [ANNAHME].
8. Titel: TK erlaubt 90 Zeichen, `ez_events.title` 60 – [OFFEN] verlängern oder TK kürzt.
9. Stände `registered` / `present` / `absent` bei Kurs und Tour wie beim Arbeitseinsatz.

## Offen

- [OFFEN] Teilnehmende von Kurs und Tour: in der Anwesenheitserfassung erfassen (Anmeldung liegt in Yolawo) oder nur Leitung?
- [OFFEN] Kurse, die nicht über TK geplant werden (z. B. Referat Ausbildung, falls nicht in TK): weiter direkt in der Anwesenheitserfassung anlegen?
- [OFFEN] Trainingslager: auch über TK?

## Einarbeitung

- [ ] eingearbeitet in Anwesenheitserfassung (Datei, Version): –
