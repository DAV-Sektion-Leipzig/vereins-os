# Contract: Fehlercodes → Meldungen Anwesenheitserfassung

Stand: 24.10.2026 · Grundlage: [spec.md](../spec.md) v0.5, Abschnitt 5 und 2

Diese Liste ist normativ für die Anwesenheitserfassung (Spec T7). Die Meldungstexte stehen wörtlich in spec.md. Die Datenbank meldet `raise exception '<CODE>' using errcode = 'P0001'`; das Frontend bildet die Codes in `src/lib/errors.ts` auf die Meldungen ab. Die gemeinsame Liste [error-codes.md Administration](../../ad-administration/contracts/error-codes.md) verweist im Abschnitt EZ hierher.

**Status:** „geplant (Tn)“ = Spec-Task aus spec.md Abschnitt 10; „umgesetzt“, sobald die Migration auf `main` ist.

## Fehler

| Code | Meldung | Regel | Ausgelöst in | Status |
|---|---|---|---|---|
| `EZ_FORBIDDEN` | Für diesen Bereich hast du keine Rechte. | R13, R14 | alle Schreibfunktionen | geplant (T4, T5) |
| `EZ_NOT_FOUND` | Einsatz nicht gefunden. | R13 | `ez_get_event`, Schreibfunktionen mit `id` | geplant (T4–T6) |
| `EZ_DELETE_FORBIDDEN` | Du darfst Einsätze nicht löschen. | R15 | `ez_delete_event` | geplant (T5) |
| `EZ_FIELD_REQUIRED` | Bitte ‚<Feld>‘ angeben. (Feld in `details`: Gruppe, Referat, Titel, Organisierende Person, Datum, Startdatum, Enddatum, Beginn, Ende, Dauer, Ort, Grund) | R1 | `ez_save_event` | geplant (T4) |
| `EZ_FIELD_LOCKED` | Einsatzart und Gruppe können nicht geändert werden. Bitte den Einsatz löschen lassen und neu erfassen. | R19 | `ez_save_event`, Trigger `ez_events_before_update` | geplant (T3, T4) |
| `EZ_END_DATE` | Das Enddatum muss nach dem Startdatum liegen. Für eintägige Einsätze bitte ‚eintägig‘ wählen. | R2 | `ez_save_event` | geplant (T4) |
| `EZ_TITLE_LENGTH` | Bitte einen Titel mit höchstens 90 Zeichen eingeben. | Längen | `ez_save_event` | geplant (T4) |
| `EZ_TRIAL_NAME` | Leer: „Bitte einen Vornamen eingeben.“ Zu lang: „Bitte höchstens 30 Zeichen eingeben.“ | R6 | `ez_save_event` | geplant (T4) |
| `EZ_REMARK_LENGTH` | Die Bemerkung darf höchstens 500 Zeichen haben. | R7 | `ez_save_event` | geplant (T4) |
| `EZ_LOCATION_INACTIVE` | Dieser Ort ist nicht mehr aktiv. Bitte einen anderen Ort wählen. | R12 | `ez_save_event` | geplant (T4) |
| `EZ_LOCATION_NO_POINTS` | Etwas ist schiefgelaufen. Bitte versuche es erneut. (keine eigene Meldung in spec.md; die Oberfläche bietet nur Orte mit Punktekonto an) | US-EZ-16 | `ez_climbing_points_report` | geplant (T6) |
| `EZ_ORGANIZER_NOT_ACTIVE` | Bitte eine aktive Person auswählen. | R11 | `ez_save_event` | geplant (T4) |
| `EZ_PERSON_NOT_ACTIVE` | Bitte eine aktive Person auswählen. | R20 | `ez_save_event` | geplant (T4) |
| `EZ_PARTICIPANT_NOT_IN_GROUP` | Diese Person ist an diesem Tag nicht Teilnehmer:in der Gruppe. | R16 | `ez_save_event` | geplant (T4) |
| `EZ_DUPLICATE_PERSON` | Diese Person ist bereits eingetragen. | R17 | `ez_save_event`, `ez_reactivate_helper` | geplant (T4, T5) |
| `EZ_DUPLICATE_EVENT` (Rückfrage, kein Abbruch) | Für diese Gruppe ist an diesem Tag bereits ein Einsatz dieser Art erfasst. Trotzdem speichern? | R8 | `ez_save_event` | geplant (T4) |
| `EZ_MIN_ATTENDANCE` | Bitte mindestens eine Trainer:in oder Helfer:in und eine Teilnehmer:in auswählen. | R5 | `ez_save_event` | geplant (T4) |
| `EZ_STATUS_NOT_ALLOWED` | Etwas ist schiefgelaufen. Bitte versuche es erneut. (keine eigene Meldung in spec.md; die Oberfläche bietet „eingetragen“ nur bei Arbeitseinsatz, Kurs und Tour an) | R21 | `ez_save_event` | geplant (T4) |
| `EZ_ROLE_NOT_ALLOWED` | Bei dieser Einsatzart gibt es keine Teilnehmer:innen. | R21 | `ez_save_event` | geplant (T4) |
| `EZ_KIND_NOT_ALLOWED` | Etwas ist schiefgelaufen. Bitte versuche es erneut. (keine eigene Meldung in spec.md; nur bei Aufrufen außerhalb der Oberfläche) | R30, US-EZ-11 | `ez_save_event` (weitere Gruppen), `ez_create_helper`, `ez_reactivate_helper` | geplant (T4, T5) |
| `EZ_GROUP_REFERAT_MISMATCH` | Alle Gruppen müssen zum selben Referat gehören. | R30 | `ez_save_event` | geplant (T4) |
| `EZ_EVENT_CANCELLED` | Der Einsatz ist abgesagt. Bitte zuerst die Absage zurücknehmen. | R22 | `ez_save_event`, `ez_cancel_event`, `ez_create_helper`, `ez_reactivate_helper` | geplant (T4, T5) |
| `EZ_CANCEL_REASON` | Bitte einen Grund mit höchstens 500 Zeichen angeben. | R23 | `ez_cancel_event` | geplant (T5) |
| `EZ_CANCEL_NOT_ALLOWED` | Der Einsatz hat schon anwesende Personen und kann nicht abgesagt werden. | R23 | `ez_cancel_event` | geplant (T5) |
| `EZ_TK_MANAGED` | Dieser Einsatz kommt aus der Planungshilfe Touren und Kurse. Bitte dort ändern. | R25 | `ez_save_event`, `ez_cancel_event`, `ez_restore_event`, `ez_delete_event` | geplant (T4, T5) |
| `EZ_EVENT_LOCKED` | Der Einsatz ist schon erfasst und wurde nicht geändert. | R26, R27 | `ez_upsert_planned_event`, `ez_cancel_planned_event` | zurückgestellt (T19) |
| `EZ_PRIVACY_NOT_CONFIRMED` | Bitte bestätige, dass die Person informiert wurde. | R29 | `ez_create_helper` | geplant (T5) |
| `EZ_PERSON_NOT_INACTIVE` | Diese Person ist bereits aktiv. | R31 | `ez_reactivate_helper` | geplant (T5) |

`EZ_DUPLICATE_EVENT` bricht das Speichern ab und liefert in `details` die `existing_id` nur, wenn der vorhandene Einsatz lesbar ist. „Trotzdem speichern“ ruft `ez_save_event` erneut mit `p_confirm_duplicate = true` auf (R8).

Entfallen gegenüber spec.md v0.1: `EZ_END_TIME`, `EZ_KIND_NOT_AVAILABLE`.

## Weitergereichte Codes anderer Module

| Code | Herkunft | Meldung |
|---|---|---|
| `EA_*` aus `ea_create_volunteer` / `ea_activate_person` (z. B. `EA_CREATE_FORBIDDEN`, `EA_RELATION_FOREIGN_REFERAT`) | Administration | Text aus der gemeinsamen Liste |
| `AD_FORBIDDEN`, `AD_SEARCH_TOO_SHORT` aus `ea_search_active_persons` | Administration | Text aus der gemeinsamen Liste |
| `GR_ROSTER_FORBIDDEN`, `GR_GROUP_NOT_FOUND` aus `gr_group_roster` (Aufruf aus dem Frontend) | Gruppen | Text aus [Gruppen](../../gr-gruppen/contracts/error-codes.md) |

## Nur Frontend (spec.md 5, „Weitere Meldungen“)

| Fall | Meldung |
|---|---|
| Netzfehler beim Speichern | Die Eingabe wurde nicht gesendet. Bitte bei Verbindung erneut speichern. |
| Sitzung abgelaufen | Bitte erneut anmelden. |
| Löschen fehlgeschlagen | Der Einsatz konnte nicht gelöscht werden. Bitte erneut versuchen. |
| Suche ohne Treffer | Keine aktive Person gefunden. |
| unerwartet | Etwas ist schiefgelaufen. Bitte versuche es erneut. |

## Hinweise (keine Fehler)

| Fall | Text | Quelle |
|---|---|---|
| keine Trainingszeit am Wochentag | Für diesen Wochentag ist keine Trainingszeit hinterlegt. | R28 |
| Liste nach Datumswechsel | Die Liste wurde für das neue Datum aktualisiert. | spec.md 6 |
| Entwurf vorhanden | Es gibt eine nicht gespeicherte Eingabe vom TT.MM. HH:MM. Fortsetzen? | spec.md 6 |
| Probetraining | Nur Vorname eintragen. | R6 |
| Bemerkung | Keine Angaben zu Gesundheit oder anderen sensiblen Daten von Kindern. | R7 |
| mehrtägig Beginn / Ende | Abfahrt am Startort / Rückkehr am Startort | R4 |
| Kurs, Tour (Formular oben) | Kurse und Touren aus der Planungshilfe Touren und Kurse werden automatisch angelegt. | spec.md 6 |
| Einsatz aus der Planungshilfe | Aus der Planungshilfe Touren und Kurse. Kopf und Personen aus der Planung werden dort geändert. | spec.md 6 |
| Rückfrage Löschen | Einsatz und alle Anwesenheiten löschen? | R15 |
| Rückfrage Absage zurücknehmen | Absage zurücknehmen? | spec.md 6 |
| Rückfrage Reaktivieren | Diese Person ist ruhend (bzw. ausgeschieden seit TT.MM.JJJJ). Wieder als aktiv eintragen? / Diese Person ist noch nicht als Aktive:r geführt. Als aktiv eintragen? | R31 |
