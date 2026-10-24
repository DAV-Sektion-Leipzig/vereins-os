# Übergabe an Gruppen: höchstens eine Trainingszeit je Gruppe und Wochentag

Stand: 24.10.2026 · Version 1.1 · Von: Anwesenheitserfassung (EZ) · An: Gruppen (GR) · Status: **erledigt (eingearbeitet am 24.10.2026)**
Quelle: specs/ez-einsaetze/spec.md v0.2 (R28), 02-stories.md v0.4 (US-EZ-01); Entscheidung des Product Owners vom 24.10.2026 (Abgleich mit dem Forms-Formular „Anwesenheitserfassung – Jugend“)
Änderungen v1.1: Als erledigt markiert. G6–G9 eingearbeitet in specs/gr-gruppen/spec.md v0.3/v0.3.1 (R19, `GR_TRAINING_TIME_WEEKDAY_EXISTS`) und umgesetzt (Migration `20261027000100_gr_training_time_weekday.sql`, Trainingszeit-Dialog).
Änderungen v1.0: Erste Fassung.

## Anlass

Ein Training wird in der Anwesenheitserfassung ohne Uhrzeit erfasst (nur Gruppe, Datum, Ort). Beginn und Ende ergeben sich aus der Trainingszeit der Gruppe am Wochentag des Datums; Finanzen berechnet daraus die Trainingseinheiten. Damit das eindeutig ist, gilt (Product Owner 24.10.2026): An einer Gruppe wird gepflegt, an welchen Wochentagen sie trainiert, und je Wochentag genau eine Uhrzeit. Das gilt für alle Gruppen, unabhängig vom Referat: Kinder- und Jugendgruppen haben meist einen Trainingstag, Leistungssportgruppen mehrere Tage, aber auch dort je Tag nur eine Trainingszeit.

Heute erlaubt Gruppen mehrere Trainingszeiten je Gruppe am selben Wochentag; bei zeitlicher Überschneidung erscheint nur ein Hinweis (spec.md GR R19, 02-stories.md US-GR-18 AK1 und AK5). Das ist bereits umgesetzt (Migration `gr_training_times`, Funktionen `gr_add_training_time`, `gr_change_training_time`).

## Anforderungen

| Nr | Anforderung | Eingearbeitet in |
|---|---|---|
| G6 | Je Gruppe und Wochentag gibt es an jedem Datum höchstens eine gültige Trainingszeit (keine zwei Trainingszeiten derselben Gruppe am selben Wochentag mit sich überschneidender Gültigkeit). Mehrere Wochentage je Gruppe bleiben möglich. | spec.md GR v0.3 (R19) |
| G7 | Anlegen oder „Ändern ab“, das G6 verletzt, wird abgelehnt statt mit Hinweis gespeichert. Vorschlag für die Meldung: „Für diesen Wochentag gibt es bereits eine Trainingszeit. Bitte die bestehende mit ‚Ändern ab‘ anpassen.“; Fehlercode nach Wahl von Gruppen [Vorschlag: `GR_TRAINING_TIME_WEEKDAY_EXISTS`]. Der bisherige Hinweis auf Überschneidung (R19, US-GR-18 AK5) entfällt. | spec.md GR v0.3 |
| G8 | Import: Enthält die Bestands-Excel für eine Gruppe zwei Zeiten am selben Wochentag, wird nur eine übernommen [Vorschlag: keine] und die Zeile im Prüfbericht ausgegeben. | spec.md GR v0.3 |
| G9 | Folge für `gr_group_roster(group_id, date)`: `training_times` enthält höchstens einen Eintrag (am Datum gültige Trainingszeit des Wochentags). Signatur und Rückgabeform bleiben unverändert. | spec.md GR v0.3 |

Die Anforderungen setzen eine Migration in Gruppen voraus (z. B. Ausschluss-Constraint oder Prüfung in den Funktionen). Wie Gruppen das umsetzt, entscheidet die Umsetzung von Gruppen.

## Offene Punkte

- Erledigt (v1.1): Der Seed von Gruppen läuft mit der neuen Prüfung ohne Änderung durch (Migration `20261027000100_gr_training_time_weekday.sql`, pgTAP 410 und 480 angepasst).

## Einarbeitung

- [x] eingearbeitet in Gruppen: spec.md v0.3/v0.3.1, 02-stories.md, Migration `20261027000100_gr_training_time_weekday.sql` (24.10.2026)
