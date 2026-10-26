# Anleitung Vereins OS

Stand: 26.10.2026 · Version 1.0
Änderungen v1.0: erste Fassung mit Erste Schritte, Anleitungen für Referent:innen, Geschäftsstelle und Admin; Module Administration, Ehrenamtsmanagement, Gruppen, Anwesenheitserfassung, Finanzen.

Das Vereins OS ist das Online-Werkzeug der DAV Sektion Leipzig. Hier pflegen wir Aktive, Gruppen, Einsätze und Abrechnungen an einem Ort.

Diese Anleitung ist in einfacher Sprache geschrieben. Die Bilder zeigen nur **erfundene Testdaten**.

## Welche Anleitung ist für mich?

| Ich bin … | Lies diese Teile |
|---|---|
| **neu im Vereins OS** (alle) | [Erste Schritte](01-erste-schritte.md) |
| **Referent:in oder Hüttenwart:in** | [Erste Schritte](01-erste-schritte.md) und [Anleitung für Referent:innen](02-referentinnen.md) |
| **Mitarbeiter:in der Geschäftsstelle** | [Erste Schritte](01-erste-schritte.md) und [Anleitung für die Geschäftsstelle](03-geschaeftsstelle.md) |
| **Admin** | alle Teile, vor allem die [Anleitung für den Admin](04-admin.md) |
| **Vorstand** | [Erste Schritte](01-erste-schritte.md). Die Rechtevorlage „Vorstand“ hat noch keine Rechte. Sobald der Admin sie einrichtet, kommt hier ein eigener Teil dazu. |

## So hängen die Module zusammen

![Überblick: Administration gibt Rechte; Ehrenamtsmanagement und Gruppen liefern Personen an die Anwesenheitserfassung; die Anwesenheitserfassung liefert an Finanzen](diagramme/ueberblick.png)

## Welche Module gibt es?

Du siehst im Vereins OS nur die Module, für die du Rechte hast.

| Modul | Wofür? | Stand |
|---|---|---|
| Administration | Personen, Zugänge, Rechte und Stammdaten | freigeschaltet |
| Ehrenamtsmanagement | Aktive, Lizenzen und Qualifikationen, Ehrenamtsstatus | freigeschaltet |
| Gruppen | Gruppen, Teilnehmer:innen, Erziehungsberechtigte, Verträge | in Vorbereitung |
| Anwesenheitserfassung | Trainings, Fahrten und andere Einsätze mit Anwesenheit | in Vorbereitung |
| Finanzen | Halbjahresabrechnung der Trainer:innen und Helfer:innen, Auszahlung | in Vorbereitung |
| Planungshilfe Touren und Kurse | Touren und Kurse planen und freigeben | geplant, noch nicht in dieser Anleitung |

„In Vorbereitung“ heißt: Das Modul ist gebaut und wird gerade getestet. Es erscheint auf deiner Startseite, sobald es freigeschaltet ist.

## Hilfe

- Du kommst nicht weiter? Schreib der Geschäftsstelle.
- Du brauchst mehr Rechte oder einen Zugang? Das macht der Admin.
- Wichtige Wörter erklärt die [Wörterliste](01-erste-schritte.md#wichtige-wörter).

---

## Anleitung aktualisieren (für Admin und Entwicklung)

Die Anleitung liegt im Git unter `docs/anleitung/`. Sie wird mit jedem neuen Modul ergänzt.

- **Version:** Die Zeile `Version x.y` oben in dieser Datei. Neues Modul oder neuer Teil: neue Hauptversion (2.0). Kleinere Ergänzungen: neue Unterversion (1.1). Jede Version bekommt eine Zeile „Änderungen“.
- **PDF:** Bei jedem Stand von `main` (= PROD) mit neuer Version erzeugt GitHub ein PDF und legt es als Release `anleitung-v<Version>` ab (Workflow `.github/workflows/anleitung-pdf.yml`). Selbst erzeugen: `npm run anleitung:pdf` (Datei unter `docs/anleitung/dist/`, nicht im Git).
- **Bilder aus der Oberfläche:** `npm run anleitung:screenshots` gegen den lokalen Stack oder eine Vorschau in TEST, nie gegen PROD. Nötig sind der Seed mit `SEED_WITH_EZ=1` und `SEED_WITH_FI=1` und `SEED_TEST_PASSWORD`. Für die Bilder der Finanzen vorher als Geschäftsstelle das 1. Halbjahr 2026 berechnen, als Kim Kinderjugend Tina Trainerin und Hans Helfer bestätigen, als Geschäftsstelle Tina Trainerin abschließen, ihre Abgabe (20.07.2026) erfassen und eine Auszahlungsrunde anlegen. Welche Seiten fotografiert werden, steht in `scripts/anleitung/screenshots.ts`.
- **Ablaufbilder:** Quellen in `docs/anleitung/diagramme/*.mmd` (Mermaid); `npm run anleitung:diagramme` erzeugt die PNG-Dateien daneben.
- **Neues Modul:** Abschnitt in den betroffenen Teilen (je Nutzergruppe) ergänzen, Bilder in `screenshots.ts` eintragen, Tabelle „Welche Module gibt es?“ anpassen, Version erhöhen.
