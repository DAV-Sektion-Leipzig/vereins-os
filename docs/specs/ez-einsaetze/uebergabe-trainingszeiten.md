# Übergabe an Gruppen: Trainingszeiten und Lesezugriff für die Anwesenheitserfassung

Stand: 22.10.2026 · Version 1.3 · Von: Anwesenheitserfassung (EZ) · An: Gruppen (GR) · Status: **erledigt (eingearbeitet am 22.10.2026)**
Quelle: specs/ez-einsaetze/00-steckbrief.md (v0.7), 01-erhebung.md (v0.3), 02-stories.md (v0.1)
Änderungen v1.3: Als erledigt markiert. Eingearbeitet in specs/gr-gruppen/00-steckbrief.md v0.7, 01-erhebung.md v0.7 (B10, B11, Tabelle `gr_training_times`, R18–R20) und 02-stories.md v0.4 (US-GR-18 Trainingszeiten pflegen, US-GR-19 Anwesenheitsliste; Anpassungen US-GR-02, -03, -04, -05, -16, -17). Auf Wunsch des Product Owners direkt aus dem Chat Anwesenheitserfassung eingearbeitet.
Änderungen v1.2: G3 um Stichtag ergänzt (Teilnahme und Funktionen gültig am Datum des Einsatzes, Regel R16 der Stories); Anzeige Vor- bzw. Rufname und Nachname; Admin liest; Reihenfolge Gruppen vor Anwesenheitserfassung.
Änderungen v1.1: Modulname Anwesenheitserfassung (vorher Einsätze); Trainingszeit dient als Vorschlag beim Erfassen, Trainings werden nicht vorab erzeugt; Ausfallzeiten (Ferien) nicht im Scope.

## Anlass

Trainings werden in der Anwesenheitserfassung mit den Trainingszeiten der Gruppe als Vorschlag erfasst (Product Owner, 21.10.2026). Ein Training entsteht erst mit der Erfassung; in den Ferien wird einfach nichts erfasst. Im Steckbrief Gruppen (v0.6) war die Trainingszeit ein Textfeld; daraus kann das System keinen Vorschlag machen. Reihenfolge der Umsetzung: Gruppen vor Anwesenheitserfassung (Product Owner, 22.10.2026).

## Anforderungen und Verbleib

| Nr | Anforderung | Eingearbeitet in |
|---|---|---|
| G1 | Trainingszeit strukturiert: je Gruppe 0–n Trainingszeiten mit Wochentag, Beginn, Ende, gültig von (Pflicht), gültig bis (optional); ersetzt das Textfeld. | 01-erhebung v0.7 (C, R18), US-GR-18 |
| G2 | Historie: Änderungen wirken ab „gültig von“; frühere Trainingszeiten bleiben erhalten. | 01-erhebung v0.7 (B10, R19), US-GR-18 AK2 |
| G3 | Lesezugriff zum Stichtag, nur Vorname, Rufname, Nachname und Rolle; Rechte: Gruppen lesen, Anwesenheitserfassung lesen oder Reichweite Referat. | 01-erhebung v0.7 (B11, R20: `gr_group_roster(group_id, date)`, Code `GR_ROSTER_FORBIDDEN`), US-GR-19 |
| G4 | Import: Trainingszeiten der Bestands-Excel (Text) überführen; nicht lesbare Angaben im Prüfbericht. | US-GR-16 AK1, AK3 |
| G5 | Hinweis für Iteration 2 der Anwesenheitserfassung: Alter nur intern berechnet, nie Geburtsdatum anzeigen. | US-GR-19 „Nicht Teil dieser Story“ (vorgemerkt) |

## Offene Punkte

- Erledigt (v1.3): Gruppen lag noch vor der Spec; G1 direkt in Erhebung und Stories eingearbeitet, kein Nachtrag nötig.
- Erledigt (v1.1): Ausfallzeiten (Ferien, Hallenschließung) werden nicht gepflegt.
- Neue Annahmen in Gruppen, vom Product Owner noch zu bestätigen: A11–A13 in specs/gr-gruppen/02-stories.md v0.4.
