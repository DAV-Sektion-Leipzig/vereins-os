# Übergabe: Dashboard → Finanzen (Bereich Budget)

Stand: 26.10.2026 · Version 1.6 · Status: offen (einzuarbeiten in den Steckbrief Finanzen als neuer, vorgezogener Bereich)
Änderungen v1.6: B16 nach Q-DS18 (Umschichtung mit Bestätigung durch die Budgetpflege).
Änderungen v1.5: Q-DS15 bis Q-DS17: Summen für alle, Einzelbuchungen je Referat (B9), Pflege durch Referent:innen (neu B15 Hinweise, B16 Plan ändern, B17 Vorschlag Umschlüsselung), B3 und B10 angepasst.
Änderungen v1.4: B3 nach Q-DS6 (Sichtbarkeit je Gesamtbudget: Referat, alle, ohne Referat).
Änderungen v1.3: neu B14 Vorjahresvergleich (Q-DS9).
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
| B3 | **Referat je Gesamtbudget** (Q-DS6, Q-DS15, entschieden 26.10.2026): Referat (genau eines), **alle** oder **ohne Referat**. Es bestimmt, wer Einzelbuchungen sieht und wer pflegt; die Summen sieht jede:r mit „Dashboard lesen“. Pflege durch die Budgetpflege, je Jahr; Startwerte nach der Tabelle im Steckbrief DS („Sichtbarkeit der Gesamtbudgets“). Neues Gesamtbudget ohne Angabe = ohne Referat [ANNAHME]. | Steckbrief DS |
| B4 | **Zuordnungsregeln** Konto → Budgetposten: Einzelbuchung, Einzelkonto, Hauptkonto, Kontenbereich, optional Kostenstelle (KOST1); Status ok / unsicher / offen / keine Buchung; Hinweis. Regelvorrang und Prüfungen wie im Prototyp (jedes Konto nur einmal; unverständliche Kontonummer = Fehler). Historie mit `valid_from`/`valid_to` und Protokoll (wer, wann, Kommentar) ersetzt die Versionsdateien. | Prototyp |
| B5 | **DATEV-Import** der Kontenblätter (CSV, UTF-8 mit BOM oder Windows-1252, Spalten über Namen): Kontenübersicht und Buchungsliste. Gespeichert werden nur Buchungszeilen auf Konten, die eine Regel trifft (Erfolgskonten und ausdrücklich zugeordnete Konten), keine Bank-, Kreditoren- und Personenkonten [ANNAHME, datensparsam]. Saldovorträge und Buchungen anderer Jahre werden nicht übernommen. Ein neuer Import ersetzt den vorigen des Jahres [ANNAHME]. Export monatlich (Q-DS7). | Prototyp, Q-DS1 |
| B6 | **Prüfung beim Import:** Summe je Konto aus den Einzelbuchungen = Kontenübersicht; ausgewertet = Ausgaben − Einnahmen + nicht zugeordnet. Abweichungen als Warnung sichtbar (Import wird trotzdem übernommen, wie im Prototyp) [ANNAHME]. | Prototyp |
| B7 | **Berechnung:** Ausgabe = Soll − Haben, Einnahme = Haben − Soll; verbraucht/erreicht, frei, Verbrauch in %, Ampel (grün < 80 %, gelb 80–100 %, rot > 100 % oder Ausgaben ohne Budget), Datenstand = letzte Buchung. | Prototyp |
| B8 | **Umschlüsseln** einer einzelnen Buchung oder aller Buchungen eines Kontos mit Grund; sofort gespeichert, mit Protokoll; Warnung, wenn eine umgeschlüsselte Buchung im neuen Import fehlt. | Prototyp |
| B9 | **Lesefunktionen für das Dashboard** (Q-DS12, Q-DS13, Q-DS15): Summen je Budgetposten und Gesamtbudget (Plan beschlossen und geändert, verbraucht, frei, Hinweise) für **alle** mit DS lesen, unabhängig von der Reichweite; Einzelbuchungen (Datum, Konto, Buchungstext, Beleg, Betrag, KOST1) mit Reichweite „Referat“ nur für Budgetposten der eigenen Referate und für Gesamtbudgets „alle“, mit Reichweite „alle“ oder „darf Budget pflegen“ für alle; nicht zugeordnete Buchungen nur mit Reichweite „alle“ oder „darf Budget pflegen“. Gruppenleitungen (Reichweite „Gruppe“) lesen kein Budget (Q-DS8). | Q-DS12, Q-DS13, Q-DS15 |
| B10 | **Rechte:** Import, Zuordnung, Umschlüsseln und Pflege aller Gesamtbudgets mit „darf Budget pflegen“ (1. Vorsitzender, später Schatzmeister:in; nicht die Geschäftsstelle; Q-DS7, Q-DS14). Referent:innen (DS lesen, Reichweite „Referat“) pflegen B15 und B16 für Gesamtbudgets ihres Referats und schlagen nach B17 vor (Q-DS16, Q-DS17). | Q-DS7, Q-DS14, Q-DS16, Q-DS17 |
| B11 | **Löschfrist:** Einzelbuchungen bleiben für das laufende Jahr und das Vorjahr; danach automatisch gelöscht, vorher Verdichtung zu Summen je Budgetposten und Monat (bleiben für den Vorjahresvergleich) [ANNAHME: Löschung am 01.01. des übernächsten Jahres]. Eintrag im Verarbeitungsverzeichnis (Buchungstexte enthalten Namen). | Q-DS11 |
| B13 | **Später:** Import über die DATEV-Schnittstelle des Schnittstellen-Connectors statt CSV; Rechenregeln und Prüfungen bleiben gleich. | Q-DS7 |
| B14 | **Vorjahresvergleich** (Q-DS9, Product Owner 26.10.2026): Summen je Budgetposten und Monat bleiben über die Löschfrist der Einzelbuchungen hinaus erhalten [OFFEN: wie viele Jahre]; Lesefunktion liefert je Budgetposten und Gesamtbudget das Vorjahr bis zum gleichen Stichtag (Datenstand des laufenden Jahres) und das ganze Vorjahr; Verknüpfung der Budgetposten zweier Jahre über Name und Gesamtbudget [ANNAHME], neue Posten ohne Vorjahreswert. | Q-DS9 |
| B15 | **Hinweis je Budgetposten** (Q-DS16): Text, wer, wann; pflegt die Referent:in des Referats oder die Budgetpflege; sichtbar für alle mit Budget-Sicht; Historie. Ersetzt für Referent:innen den Hinweis der Zuordnung im Prototyp nicht (der bleibt bei der Budgetpflege) [ANNAHME]. | Q-DS16 |
| B16 | **Plan umschichten** (Q-DS16, Q-DS18, entschieden 26.10.2026): Referent:in beantragt eine Umschichtung (Betrag von Budgetposten A nach B, beide im Gesamtbudget ihres Referats, gleiche Art [ANNAHME]) mit Grund; die Summe des Gesamtbudgets bleibt gleich. Stand beantragt → bestätigt / abgelehnt (mit Grund) durch die Budgetpflege; Liste offener Anträge für die Budgetpflege. Aktueller Plan = beschlossener Plan (Excel) + bestätigte Umschichtungen; beide werden angezeigt und im Vorjahresvergleich verwendet [ANNAHME: Vergleich mit aktuellem Plan]. Beim erneuten Einlesen der Excel bleiben bestätigte Umschichtungen erhalten, solange beide Posten existieren; sonst Hinweis [ANNAHME]. Die Budgetpflege darf direkt umschichten [ANNAHME]. | Q-DS16, Q-DS18 |
| B17 | **Vorschlag Umschlüsselung** (Q-DS17): Referent:in schlägt für eine Buchung eines Budgetpostens ihres Referats einen anderen Budgetposten mit Grund vor; Stand vorgeschlagen → angenommen / abgelehnt (mit Grund); erst „angenommen“ wirkt wie B8; Liste offener Vorschläge für die Budgetpflege. | Q-DS17 |
| B12 | **Abnahme:** fiktiver DATEV-Export im Repository mit allen Sonderfällen (Doppelzählung, Storno, Umbuchung, EB-Wert, anderes Jahr, fehlende Einzelbuchung, Einzelbuchungsregel, Kostenstelle); Vergleich mit den echten Referenzwerten des Erstexports nur lokal durch den Product Owner. | Prototyp |

## Voraussetzungen in der Administration

- Nachtrag v0.10 (FI in der Administration) muss vor dem Bereich Budget umgesetzt sein.
- Modul DS und Startwerte: siehe specs/ds-dashboard/uebergabe-administration.md v1.0.
