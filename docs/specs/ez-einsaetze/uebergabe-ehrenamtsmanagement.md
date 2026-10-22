# Übergabe an das Ehrenamtsmanagement: Aktive aus der Anwesenheitserfassung, Einsatzhistorie, Nachweise der Vergütungsordnung

Stand: 22.10.2026 · Version 1.3 · Von: Anwesenheitserfassung (EZ) · An: Ehrenamtsmanagement (EA) · Status: erledigt
Quelle: specs/ez-einsaetze/00-steckbrief.md (v0.6); Vergütungsordnung der Sektion (2025_DAV_Leipzig_FO_VGO)
Änderungen v1.3: Als erledigt markiert; eingearbeitet in specs/ea-ehrenamt/01-erhebung.md v0.1 (C2 Nr. 4, 6, 9, 16, 17; Abschnitt „Übergabe … – Verbleib“). Offene Punkte (Art. 13 DSGVO, Vereinbarung über die ehrenamtliche Tätigkeit) werden im Ehrenamtsmanagement weitergeführt.
Änderungen v1.2: Modulname Anwesenheitserfassung (vorher Einsätze); E6 (Aktive als Auswahl für die organisierende Person) ergänzt.
Änderungen v1.1: E4 (Nachweise aus der Vergütungsordnung) und E5 (förderfähige Lizenz) ergänzt.

## Anforderungen

- **E1 – Aktive aus Arbeitseinsätzen (MVP Anwesenheitserfassung):** Personen, die beim Arbeitseinsatz neu angelegt werden, erhalten Ehrenamtsstatus „aktiv“ und die Funktion Helfer:in mit Bezug auf das Referat des Einsatzes. Sie erscheinen damit im Ehrenamtsmanagement wie andere Aktive. Entscheidung Product Owner, 21.10.2026: Auch eine einmalige Helferin wird als Aktive geführt, um sie für weitere Mitarbeit zu gewinnen.
- **E2 – Einsatzhistorie und letzter Einsatz (Iteration 2):** An der Person im Ehrenamtsmanagement: Liste ihrer Einsätze (Datum, Einsatzart, Gruppe bzw. Titel, Referat, Rolle, anwesend) und Datum des letzten Einsatzes. Daten liest das Ehrenamtsmanagement aus der Anwesenheitserfassung. Sichtbarkeit nach den Rechten im Ehrenamtsmanagement [ANNAHME].
- **E3 – „TE pro Woche“:** Das Feld an der Funktion Trainer:in bleibt vorerst; prüfen, ob es durch die Trainingszeiten der Gruppen und die erfassten Einsätze entfallen kann. Hinweis: Eine Trainingseinheit hat 30 Minuten (Vergütungsordnung).
- **E4 – Nachweise aus der Vergütungsordnung:** zwei Eigenschaftsarten der Kategorie Nachweise [ANNAHME: Lesestufe „nur Geschäftsstelle und Admin“]:
  - „Bestätigung steuerfreie Einnahmen“ (Übungsleiterpauschale): Datum der Abgabe; Voraussetzung jeder Auszahlung, vor der ersten Zahlung.
  - „Erklärung zur Ehrenamtspauschale“: Jahr bzw. Datum der Abgabe; bei wiederkehrender Zahlung jährlich zu erneuern.
  Prüfen, ob „Trainervereinbarung“ und die „Vereinbarung über die ehrenamtliche Tätigkeit“ (Ehrenamtspauschale) getrennte Nachweise sind.
- **E5 – Förderfähige Lizenz:** Finanzen prüft für die Vergütung als Trainer:in, ob eine förderfähige Lizenz vorliegt und seit wann (Abrechnungshalbjahr des Lizenzerwerbs). Das Ehrenamtsmanagement muss dafür an der Lizenz das Erwerbsdatum führen [ANNAHME: vorhanden als „gültig von“] und die Kennzeichnung „förderfähig“ lesbar machen [ANNAHME: = DOSB-lizenzfähig der Qualifikationsart].
- **E6 – Aktive als Auswahl (MVP Anwesenheitserfassung):** Die organisierende Person einer Fahrt wird aus allen Personen mit Ehrenamtsstatus „aktiv“ per Suche gewählt (nur Name; Sichtbarkeit über die Administration, Übergabe A3).

## Offene Punkte

- [OFFEN] Information nach Art. 13 DSGVO an Personen, die aus einem Arbeitseinsatz angelegt werden: wie und durch wen?
- [OFFEN] „Förderfähige Lizenz“ = Kennzeichen „DOSB-lizenzfähig“?

## Folgeänderungen im Ehrenamtsmanagement (durch den Chat Ehrenamtsmanagement)

- Steckbrief EA: E1 bei Personen ohne Referat bzw. Anlegen berücksichtigen; E2 als Iteration 2 vormerken; E4 als System-Eigenschaftsarten bzw. Startbestand prüfen; E5 mit der Migration der Lizenzen abgleichen.
- Nach dem Einarbeiten: diese Übergabe als erledigt markieren.
