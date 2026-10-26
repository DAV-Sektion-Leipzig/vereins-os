# Übergabe: Dashboard → Gruppen

Stand: 26.10.2026 · Version 1.0 · Status: offen (Nachtrag Gruppen vor der Umsetzung der Referats-Kennzahlen des Dashboards)
Grundlage: specs/ds-dashboard/00-steckbrief.md v0.11, sichten.md v0.5 (Abschnitte 0 und 4.1), specs/gr-gruppen/spec.md (Abschnitt 2.3 Lesefunktionen, Abschnitt 3 Rechte, R20).

Kennzeichnung: **[ANNAHME]** = Vorschlag, mit dem Product Owner zu bestätigen. **[OFFEN]** = Entscheidung fehlt.

## Entscheidungen des Product Owners (26.10.2026)

- Referent:innen **steuern ihre Gruppen mit dem Dashboard**: Sie treffen anhand der Kennzahlen Entscheidungen. Das heißt nicht unbedingt, dass sie im Vereins OS etwas ändern.
- Im Gruppendetail sehen Referent:innen **Namen und Hinweise** der Gruppen ihres Referats; **keine** Kontaktdaten, kein Geburtsdatum oder Alter, keine Verträge, keine Gesundheitsangaben, keine Fotoerlaubnis.
- Referent:innen bekommen dafür **kein Recht auf das Modul Gruppen**. Die Rechte im Modul Gruppen bleiben, wie sie sind (Reichweite nur „alle“).

## Anforderungen

| Nr | Anforderung | Vorschlag |
|---|---|---|
| G1 | **Lesefunktion Gruppen-Kennzahlen** für das Dashboard (security definer, stable): je Gruppe Name, Referat, heute gültige Trainingszeiten, Teilnehmer:innen heute, Teilnehmer:innen zu einem Stichtag (für Vorjahr), Anzahl „Teilnahme klären“, ohne Notfallkontakt, ohne erziehungsberechtigte Person; Funktionen in Gruppe (Anzahl Trainer:innen, Helfer:innen). Recht: `ad_has_level('DS','read')`; mit Reichweite „Referat“ nur Gruppen der eigenen Referate. | Name z. B. `gr_ds_group_figures(p_date)` |
| G2 | **Lesefunktion Gruppendetail**: Teilnehmer:innen mit Vorname, Rufname, Nachname, Teilnahme seit, Kennzeichen „Teilnahme klären“, „kein Notfallkontakt“, „keine erziehungsberechtigte Person“; Betreuung mit Namen, Funktion, seit. Sonst nichts (entsprechend R20). Recht wie G1. | z. B. `gr_ds_group_detail(p_group)` |
| G3 | **Alter nur intern** für den Betreuungsschlüssel: Altersklasse je Teilnehmer:in zum Datum eines Trainings als interne Funktion (wie `gr_is_adult`), ohne Grant an `authenticated`; die Anwesenheitserfassung bzw. das Dashboard erhält nur das Ergebnis „Schlüssel eingehalten ja/nein“. | gemeinsam mit EZ (Iteration 2) |
| G4 | **Sichtbarkeit:** Personen, die über G2 zurückgegeben werden, werden nicht zusätzlich über `gr_person_visible` sichtbar; G2 liefert nur Namen (wie `gr_group_roster`). | – |
| G5 | **Lizenz gültig bis** der Betreuung kommt nicht aus Gruppen, sondern aus dem Ehrenamtsmanagement (Lesefunktion mit Recht auf DS, nur Qualifikationsart und gültig bis, keine Lizenznummer). | Übergabe DS → EA folgt mit den Stories [ANNAHME] |

## Nicht Teil dieser Übergabe

- Platzzahl je Gruppe (Q-DS3: keine).
- Altersstruktur je Gruppe (sichten.md K14: nicht angezeigt).
- Änderungsrechte für Referent:innen im Modul Gruppen.
