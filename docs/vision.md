# Vision: Vereins OS

Stand: 19.10.2026 · Version 0.4 · Product Owner: Toni Werner

## Leitsatz

Für die Geschäftsstelle, Personen mit Amt und Aktive der Sektion, die Personen, Einsätze und wiederkehrende Abläufe heute in unflexiblen, unverknüpften Excel-Listen pflegen, ist das Vereins OS ein modulares Arbeitsinstrument, das diese Daten zentral hält und wiederkehrende Abläufe automatisiert – z. B. einen monatlichen Buchungslauf für Verträge, der an Finanzbuchhaltung bzw. Sparkasse übergeben wird.

## Ausgangslage

- Daten zu Trainer:innen und anderen Aktiven liegen in einer Excel-Liste, die laufend angepasst wird. Sie ist wenig flexibel und nicht mit anderen Daten verknüpft.
- Teilnehmer der Gruppen werden ebenfalls in Excel-Listen geführt.
- Diese Daten werden bewusst getrennt von der Mitgliederverwaltung gehalten.
- Aktuell über 150 Aktive in Training, Jugend und Ausbildung. Mit weiteren Bereichen (z. B. Bergfilmfestival, Europacup) ca. 250 Aktive, jeweils mit Kontaktdaten und letztem Einsatz.
- Der monatliche Buchungslauf für Verträge dauert ca. 30 Minuten und wird manuell erstellt.
- Kein System am Markt bildet die Kernbereiche flexibel ab.

Typische Arbeiten, die das Vereins OS unterstützen soll:
- Aktive für den nächsten Arbeitseinsatz auswählen
- Trainer:innen abrechnen und daraus Überweisungslisten für DATEV erstellen
- Verträge im Bereich Kinder und Jugend nachhalten
- Gruppen mit Gruppenleitung und Teilnehmern führen
- Umfragen über Schnittstellen erstellen
- Pressemitteilungen und Instagram-Beiträge erstellen
- Aufgaben mit Erinnerungen verwalten und aktuell halten

Schwerpunkte: Ehrenamtsmanagement, Gruppen, Finanzen, Öffentlichkeitsarbeit, Projektmanagement, Geschäftsstellenmanagement; Aufgabenmanagement übergreifend. Basis: Administration und Schnittstellen-Connector. Details in modul-landkarte.md.

## Zielgruppen

| Zielgruppe | Phase | Nutzung |
|---|---|---|
| Mitarbeitende der Geschäftsstelle (3) | MVP | Hauptnutzer, tägliche Arbeit |
| Vorstand (1. Vorsitzender) | MVP | Nutzer, Product Owner und Admin |
| Weitere Personen mit Amt | nach MVP | [OFFEN] Umfang und Zeitpunkt des Rollouts |
| Aktive | nach MVP | im MVP nur als Datensätze, keine eigene Anmeldung |

## Ziele für 12 Monate

| # | Ziel | Messgröße |
|---|---|---|
| Z1 | Excel-Liste der Aktiven abgelöst | Alle ca. 250 Aktiven im Vereins OS gepflegt, Excel-Liste wird nicht mehr fortgeführt [ANNAHME: Ziel bestätigt] |
| Z2 | Monatlicher Buchungslauf für Verträge automatisiert | Aufwand pro Lauf von ca. 30 Min. auf ca. 1 Min. |
| Z3 | Aufgaben der Geschäftsstelle mit Erinnerungen im System | [OFFEN] Messgröße. Risiko: AM hat Priorität 5 |
| Z4 | Betrieb ohne laufende Kosten | 0 €/Monat in den ersten 6 Monaten |

## Prinzipien für alle Module

- Automatisieren vor manuell erfassen: wiederkehrende Abläufe laufen per Knopfdruck oder zeitgesteuert.
- Daten einmal pflegen, modulübergreifend nutzen (Verknüpfung statt Einzellisten).
- Flexibel auf der Person: neue Eigenschaftsarten ohne Änderung der Datenstruktur, mit Gültigkeit und Historie.
- Geringe Kosten: nur kostenfreie Pläne, solange kein Budget freigegeben ist.
- Einfach: bedienbar ohne Schulung durch die Geschäftsstelle.
- Mobil nutzbar (ab 375 px Breite).
- Datensparsam: nur Daten speichern, die ein konkreter Ablauf braucht.

## Nicht-Ziele

- Keine Finanzbuchhaltung (das Vereins OS übergibt Daten, bucht aber nicht).
- Keine Mitgliederverwaltung („Mitglied ja/nein“ ist nur eine Eigenschaft der Person).
- Im MVP keine Anmeldung von Aktiven.
- Keine kostenpflichtigen Dienste in den ersten 6 Monaten.

## Rahmenbedingungen

- Budget: 0 € laufend; nur kostenfreie Pläne (Supabase, Cloudflare, GitHub, Gmail). Nach ca. 6 Monaten ggf. zusätzliches Budget.
- Umsetzung mit Claude Code; das Projekt ist zugleich Testprojekt für diese Arbeitsweise.
- Betrieb und Pflege: Product Owner (Toni Werner) [ANNAHME]; Vertretung als Admin später durch ein:e Mitarbeiter:in der Geschäftsstelle.
- Supabase Free-Plan pausiert Projekte nach 7 Tagen geringer Aktivität und bietet keine herunterladbaren Backups.
- Kein Zugriff auf DNS der Domain dav-leipzig.de und keinen Mailversand über den Microsoft-Tenant (verwaltet vom Bundesverband).
- Mit Echtdaten ist die Sektion Verantwortliche im Sinne der DSGVO: Auftragsverarbeitungsverträge, EU-Region, Eintrag im Verarbeitungsverzeichnis nötig (Details in tech-stack.md).
- Zuständig für Datenschutz im Vereins OS: Toni Werner (Product Owner, 1. Vorsitzender).

Bestätigt vom Product Owner am 19.10.2026: bedienbar ohne Schulung, mobil ab 375 px, datensparsam.

## Offene Fragen

Alle offenen Fragen sind den Modulen zugeordnet und stehen in offene-punkte.md (Z3 → AM, Rollout → übergreifend, Vertrag und Buchungslauf → FI).
