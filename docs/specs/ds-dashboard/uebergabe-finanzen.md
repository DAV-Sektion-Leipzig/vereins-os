# Übergabe: Dashboard → Finanzen (Bereich Budget)

Stand: 26.10.2026 · Version 1.2 · Status: offen (einzuarbeiten in den Steckbrief Finanzen als neuer, vorgezogener Bereich)
Änderungen v1.2: B9 (Referat nur Buchungen seiner Budgetposten, Admin liest), B10 (Kennzeichen „darf Budget pflegen“).
Änderungen v1.1: Q-DS7, Q-DS11, Q-DS12 entschieden (B5, B9, B10, B11, neu B13).
Grundlage: specs/ds-dashboard/00-steckbrief.md v0.3 (Q-DS1, Q-DS2, Q-DS4, Q-DS7, Q-DS11, Q-DS12), prototyp-budget-dashboard.md v1.0, specs/fi-finanzen/00-steckbrief.md v0.5.

Kennzeichnung: **[ANNAHME]** = Vorschlag, mit dem Product Owner zu bestätigen. **[OFFEN]** = Entscheidung fehlt.

## Entscheidungen des Product Owners (26.10.2026)

- **Budget ist ein Bereich von Finanzen** (Präfix `fi_`), wie das Abrechnen. Das Modul Dashboard zeigt die Budget-Sicht nur an und liest über Lesefunktionen von Finanzen.
- **Die Buchungsliste wird gespeichert.** Referent:innen sehen die Einzelbuchungen der Budgetposten ihres Referats.
- **Der Bereich Budget kommt früh**, direkt nach dem Kern der Administration und vor der Abrechnung, weil die Daten heute schon vorliegen.

Damit ändert sich im Steckbrief Finanzen v0.5 „Nicht im Scope: … Budget-Übersicht, Dashboard: später“.

## Anforderungen an Finanzen

| Nr | Anforderung | Herkunft |
|---|---|---|
| B1 | **Finanzplan** je Jahr einlesen aus der Excel „Finanzen Sektion JJJJ.xlsx“, Blatt „Finanzplan JJJJ“ (Kopfzeile „Einnahmen“/„Ausgaben“, Spalte „Plan JJJJ“ je Seite, Zeilen „Summe…“ als Kontrollsumme). Abbruch, wenn die Summe der Posten von der Summenzeile abweicht. | Prototyp `build.py` |
| B2 | **Budgetposten** (Art Einnahme/Ausgabe, Name, Plan, Reihenfolge) und **Gesamtbudget** (Gruppierung) je Jahr; doppelte Postennamen über das Gesamtbudget unterscheiden. | Prototyp |
| B3 | **Gesamtbudget ↔ Referat** als Zuordnung (ein Gesamtbudget gehört zu höchstens einem Referat; ohne Referat nur für Vorstand und Geschäftsstelle) [OFFEN Q-DS6: Liste]. | Steckbrief DS |
| B4 | **Zuordnungsregeln** Konto → Budgetposten: Einzelbuchung, Einzelkonto, Hauptkonto, Kontenbereich, optional Kostenstelle (KOST1); Status ok / unsicher / offen / keine Buchung; Hinweis. Regelvorrang und Prüfungen wie im Prototyp (jedes Konto nur einmal; unverständliche Kontonummer = Fehler). Historie mit `valid_from`/`valid_to` und Protokoll (wer, wann, Kommentar) ersetzt die Versionsdateien. | Prototyp |
| B5 | **DATEV-Import** der Kontenblätter (CSV, UTF-8 mit BOM oder Windows-1252, Spalten über Namen): Kontenübersicht und Buchungsliste. Gespeichert werden nur Buchungszeilen auf Konten, die eine Regel trifft (Erfolgskonten und ausdrücklich zugeordnete Konten), keine Bank-, Kreditoren- und Personenkonten [ANNAHME, datensparsam]. Saldovorträge und Buchungen anderer Jahre werden nicht übernommen. Ein neuer Import ersetzt den vorigen des Jahres [ANNAHME]. Export monatlich (Q-DS7). | Prototyp, Q-DS1 |
| B6 | **Prüfung beim Import:** Summe je Konto aus den Einzelbuchungen = Kontenübersicht; ausgewertet = Ausgaben − Einnahmen + nicht zugeordnet. Abweichungen als Warnung sichtbar (Import wird trotzdem übernommen, wie im Prototyp) [ANNAHME]. | Prototyp |
| B7 | **Berechnung:** Ausgabe = Soll − Haben, Einnahme = Haben − Soll; verbraucht/erreicht, frei, Verbrauch in %, Ampel (grün < 80 %, gelb 80–100 %, rot > 100 % oder Ausgaben ohne Budget), Datenstand = letzte Buchung. | Prototyp |
| B8 | **Umschlüsseln** einer einzelnen Buchung oder aller Buchungen eines Kontos mit Grund; sofort gespeichert, mit Protokoll; Warnung, wenn eine umgeschlüsselte Buchung im neuen Import fehlt. | Prototyp |
| B9 | **Lesefunktionen für das Dashboard:** Summen je Budgetposten und Gesamtbudget; Einzelbuchungen (Datum, Konto, Buchungstext, Beleg, Betrag, KOST1) je Budgetposten; nicht zugeordnete Buchungen; Prüfergebnis. Die Lesefunktionen prüfen das Recht auf **DS** (lesen, Reichweite „alle“ oder „Referat“ über B3), nicht auf FI (Q-DS12). Mit Reichweite „Referat“ nur Buchungen, die einem Budgetposten eines Gesamtbudgets des Referats zugeordnet sind; nicht zugeordnete Buchungen nur mit Reichweite „alle“ oder „darf Budget pflegen“ (Q-DS13). Der Admin liest über DS (D5). Gruppenleitungen (Reichweite „Gruppe“) lesen kein Budget (Q-DS8). | Q-DS1, Q-DS2, Q-DS12 |
| B10 | **Rechte:** Import und Pflege der Zuordnung durch den 1. Vorsitzenden, später die Schatzmeister:in, nicht durch die Geschäftsstelle (Q-DS7); Recht dafür: Kennzeichen „darf Budget pflegen“ aus der Administration (Q-DS14; uebergabe-administration.md D6), ohne Rechte auf Abrechnungen und Bankdaten. Lesen über das Recht auf DS (Q-DS12). | Q-DS7, Q-DS12 |
| B11 | **Löschfrist:** Einzelbuchungen bleiben für das laufende Jahr und das Vorjahr; danach automatisch gelöscht, vorher Verdichtung zu Summen je Budgetposten und Monat (bleiben für den Vorjahresvergleich) [ANNAHME: Löschung am 01.01. des übernächsten Jahres]. Eintrag im Verarbeitungsverzeichnis (Buchungstexte enthalten Namen). | Q-DS11 |
| B13 | **Später:** Import über die DATEV-Schnittstelle des Schnittstellen-Connectors statt CSV; Rechenregeln und Prüfungen bleiben gleich. | Q-DS7 |
| B12 | **Abnahme:** fiktiver DATEV-Export im Repository mit allen Sonderfällen (Doppelzählung, Storno, Umbuchung, EB-Wert, anderes Jahr, fehlende Einzelbuchung, Einzelbuchungsregel, Kostenstelle); Vergleich mit den echten Referenzwerten des Erstexports nur lokal durch den Product Owner. | Prototyp |

## Voraussetzungen in der Administration

- Nachtrag v0.10 (FI in der Administration) muss vor dem Bereich Budget umgesetzt sein.
- Modul DS und Startwerte: siehe specs/ds-dashboard/uebergabe-administration.md v1.0.
