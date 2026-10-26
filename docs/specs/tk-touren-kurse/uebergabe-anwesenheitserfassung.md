# Übergabe: Planungshilfe Touren und Kurse → Anwesenheitserfassung

Stand: 26.10.2026 · Version 1.3 · Status: eingearbeitet (26.10.2026) · Von: Planungshilfe Touren und Kurse (TK) · An: Anwesenheitserfassung (EZ)
Änderungen v1.3: Punkt 10 neu: Abrechnungsart des Einsatzes bei Gemeinschaftstouren übergibt die Planungshilfe (Product Owner 26.10.2026); Punkte 1–9 in spec.md EZ v0.2 eingearbeitet (24.10.2026), Punkt 8 erledigt (90 Zeichen).
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
10. **Abrechnungsart (neu v1.3, Product Owner 26.10.2026):** Die Einsatzart `tour` umfasst Führungs- und Gemeinschaftstouren; die Vorbelegung (`ad_remuneration_default_at('tour', …)` = „Mehrtageskurse, Führungstouren, Trainingslager“) passt für Gemeinschaftstouren nicht. `ez_upsert_planned_event` erhält einen zusätzlichen Parameter `p_remuneration_kind_code text default null` (Code aus `ad_remuneration_kinds`, z. B. `COMMUNITY_TOUR`): null → Vorbelegung wie bisher (nur beim Anlegen); gesetzt → Abrechnungsart des Einsatzes wird beim Anlegen und bei jedem Aktualisieren auf diesen Wert gesetzt (nicht bei `fi_event_locked`, dann `EZ_SETTLED`); unbekannter oder inaktiver Code → `EZ_REMUNERATION_INACTIVE`. Die Planungshilfe übergibt `COMMUNITY_TOUR` bei Gemeinschaftstouren, sonst null (spec.md TK v0.3 R15). Die Annahme in spec.md EZ Abschnitt 11 („Abrechnungsart in der Anwesenheitserfassung änderbar, z. B. Gemeinschaftstour statt Führungstour“) bleibt für Einzelfälle bestehen.

## Offen

- [OFFEN] Teilnehmende von Kurs und Tour: in der Anwesenheitserfassung erfassen (Anmeldung liegt in Yolawo) oder nur Leitung?
- [OFFEN] Kurse, die nicht über TK geplant werden (z. B. Referat Ausbildung, falls nicht in TK): weiter direkt in der Anwesenheitserfassung anlegen?
- [OFFEN] Trainingslager: auch über TK?

## Einarbeitung

- [x] Punkte 1–9 eingearbeitet in Anwesenheitserfassung: specs/ez-einsaetze/spec.md v0.2 (24.10.2026; `tk_plan_id`, `cancelled_*`, `ez_upsert_planned_event`, `ez_cancel_planned_event`, `ez_planned_event_state`, R22–R27); offene Punkte dort entschieden (Kurs und Tour ohne Teilnehmende; Kurse und Touren ohne Planung von Hand; Trainingslager nicht über TK; Product Owner 24.10.2026).
- [x] Punkt 10 eingearbeitet in Anwesenheitserfassung: specs/ez-einsaetze/spec.md v0.7 (26.10.2026; Signatur `ez_upsert_planned_event`, R26a).
