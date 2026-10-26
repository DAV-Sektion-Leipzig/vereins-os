# Erhebung: Finanzen

Datum: 26.10.2026 · Version 0.7.1 · Status: Entwurf · Beteiligte: Toni Werner (Product Owner); Vorlagen der Geschäftsstelle: Auszahlliste (PDF) und SEPA-Datei (XML) einer Auszahlung der Übungsleitervergütung, Lastschriftdatei der Gruppenbeiträge Oktober 2026 (Muster mit Echtdaten, nicht im Repository)
Grundlage: 00-steckbrief.md v0.4; specs/ez-einsaetze/uebergabe-finanzen.md v1.6 (F1–F9); specs/tk-touren-kurse/uebergabe-finanzen.md v1.3; specs/ez-einsaetze/spec.md v0.5; specs/ad-administration/spec.md v0.9; specs/ea-ehrenamt/01-erhebung.md v0.5 (C2); Vergütungsordnung (Beschluss 21.11.2023, ergänzt 11.12.2025, Anhang 1)
Änderungen v0.7.1: Vorlage der Lastschriftdatei der Sparkasse eingearbeitet (Product Owner 26.10.2026): pain.008.001.02 bestätigt (C11), Verwendungszweck nach Vorlage (R42), Vorlauf ein Bankarbeitstag bestätigt (R39); Fälligkeitstag = Erstellen + 3 Tage statt Stammdatum (R39, A12 entfällt); Sachkonto der Gruppenbeiträge als Eingabefeld der Administration (R41, A11); Nachzahlung als Zusatzbetrag mit Text (R47); Erst-/Folgelastschrift bleibt (R38), obwohl die Vorlage nur Folgelastschriften enthält.
Änderungen v0.7: **Nachtrag Buchungslauf Verträge** (Abschnitt H, Product Owner 26.10.2026): monatlicher Einzug der Verträge aus dem Modul Gruppen als SEPA-Lastschriftdatei (pain.008) mit Einzugsliste (PDF); Verträge aktiv am 1. des Monats mit vollem Monatsbetrag; je Vertrag und Monat höchstens ein Einzug, Nachtrag im selben Monat; Erst- und Folgelastschrift mit Stichtag für Bestandsverträge; Fälligkeitstag und Gläubiger-Identifikationsnummer als Stammdaten der Administration; Geschäftsstelle erstellt und gibt allein frei; Einzugsliste mit gekürzter IBAN; Rücklastschriften später. Regeln R34–R46. Damit ist der offene Punkt „Buchungslauf: DATEV oder SEPA“ für Verträge entschieden (SEPA-Datei).
Änderungen v0.6: Bestätigt (Product Owner 26.10.2026): Abgabe nach der Frist mit Rückfrage und Begründung (R19), Verfall von Hand (B4); Referent:innen sehen die ganze Abrechnung (02-stories.md R31).
Änderungen v0.5: Offene Fragen in Iteration 1 verschoben (Product Owner 26.10.2026); im MVP kein Storno einer Auszahlungsrunde [ANNAHME].
Änderungen v0.4: Vorlagen der Geschäftsstelle eingearbeitet (Product Owner 26.10.2026): Auszahlung in **Auszahlungsrunden**; die Freigabe einer Runde erzeugt **Auszahlliste (PDF)** für die Ablage in der Buchhaltung und **Überweisungsdatei (XML, pain.001.001.03)** für die Sparkasse (B5, C3, C6, C7, R24–R30); je Person und Gruppe eine Zeile und eine Überweisung; „sachlich richtig“ auf der Auszahlliste = Bestätigung im Vereins OS. Begriff: Die einzelne Abrechnung wird **abgeschlossen** (bisher „freigegeben“), freigegeben wird nur die Auszahlungsrunde [ANNAHME: Begriff, damit „Freigabe“ eindeutig bleibt].
Änderungen v0.3: Höchstbetrag im Jahr der Auszahlung (R11), Vertretung bei der Bestätigung (R23), Erklärung auf dem Abrechnungsdokument (R18), Belege in der Finanzbuchhaltung bestätigt (F) (Product Owner 25.10.2026).
Änderungen v0.2: Entscheidungen des Product Owners vom 25.10.2026 eingearbeitet: Bestätigung durch die Referent:in (Zustand „bestätigt“, Abschnitt A, B3a, R23), Trainervereinbarung als Voraussetzung (R14), Training ohne Trainingszeit (R4), Probetrainings getrennt (B6).
Änderungen v0.1: Erster Entwurf für den MVP (halbjährliche Abrechnung, Überweisungsdatei, Abgleich Punktekonto). Iteration 1 nur in Stichpunkten (Abschnitt B7).

Begriffe nach glossar.md; neue Begriffe (Abrechnungsart, Position, Abrechnungsdokument, abschließen, Abgabe, Auszahlungsrunde, Auszahlliste, Auszahlzeile, Überweisungsdatei, Abgleich Punktekonto, steuerfreier Höchstbetrag) als Vorschlag im Steckbrief.

## A. Rechtevorlagen & Rechte

| Rechtevorlage | FI | Was | Reichweite |
|---|---|---|---|
| Geschäftsstelle | verwalten | Abrechnungen erstellen, neu berechnen, korrigieren, abschließen, Abschluss zurücknehmen, Abrechnungsdokument drucken, Abgabe und Verfall erfassen, Auszahlungsrunde zusammenstellen und freigeben (Auszahlliste und Überweisungsdatei), Abgleich Punktekonto | alle |
| Admin | – | kein Zugriff auf Finanzen; pflegt Sätze, Abrechnungsarten, Vorbelegung, Fristen, Höchstbetrag, Angaben der Sektion für die Auszahlung in der Administration | – |
| Referent:in | lesen + Aktion „freigeben“ (Q1) [ANNAHME: Stufe] | Abrechnungen ihres Referats ansehen (ganze Abrechnung, sobald sie eine Position des eigenen Referats hat; Hinweise ohne Nachweisdaten; Product Owner 26.10.2026), Ausnahme (Lizenz) begründen, Positionen ihres Referats bestätigen; keine Bankverbindung, keine Auszahlungsrunde, kein Abgleich Punktekonto | Referat (MVP: Kinder und Jugend, Leistungssport) |
| Vorstand | – | Startwert ohne Rechte; unterschreibt die Auszahlliste auf Papier („gf Vorstand“) | – |
| Schatzmeister:in, Kassenprüfung (nach MVP) | lesen [ANNAHME] | Abrechnungen und Auszahlungsrunden einsehen | alle |

- Vier-Augen-Prinzip (Product Owner 25.10.2026): Die Referent:in bestätigt, die Geschäftsstelle schließt ab und gibt die Auszahlungsrunde frei. Die Bestätigung ist die Unterschrift „sachlich richtig“ der Auszahlliste (Product Owner 26.10.2026); „gf Vorstand“ und „angewiesen“ werden weiter auf Papier unterschrieben.
- Das Bestätigen der Referent:in ist die eigene Aktion „freigeben“ nach Q1 mit Reichweite „Referat“ [ANNAHME: Zuordnung]. Abschließen und Freigeben der Auszahlungsrunde durch die Geschäftsstelle sind Teil von „verwalten“ (rollen.md 5: Abläufe auslösen) [ANNAHME].
- Eine Person der Geschäftsstelle, die zugleich Referent:in ist, darf nicht dieselbe Abrechnung bestätigen und abschließen [ANNAHME].
- Personendaten (Bankverbindung, Nachweise, Lizenzen) liest Finanzen nur über die Lesefunktion der Administration (Übergabe FI → AD, A8); Referent:innen erhalten daraus nur die berechneten Hinweise, nicht die Daten; Namen über `ea_person_names` (A9).
- Einsätze und Anwesenheiten liest Finanzen über eine Lesefunktion der Anwesenheitserfassung mit FI-Rechten (Übergabe FI → EZ, Z2).

## B. Abläufe (inkl. Zustände)

Überblick: Abrechnung je Person und Halbjahr berechnen → Referent:in bestätigt → Geschäftsstelle schließt ab (Abrechnungsdokument zur Unterschrift, Sperre) → Person gibt unterschrieben ab → Geschäftsstelle stellt eine Auszahlungsrunde zusammen und gibt sie frei → Auszahlliste (PDF) und Überweisungsdatei (XML).

**B1 – Halbjahresabrechnung erstellen**
1. Geschäftsstelle wählt das Abrechnungshalbjahr (1. Halbjahr 01.01.–30.06., 2. Halbjahr 01.07.–31.12.).
2. Das System sucht alle nicht abgesagten Einsätze mit Abrechnungsart der Referate mit Kennzeichen „halbjährliche Abrechnung“ (Kinder und Jugend, Leistungssport), deren Datum (mehrtägig: Startdatum) im Halbjahr liegt (R1, R2).
3. Je Person mit Anwesenheit „anwesend“ als Trainer:in oder Helfer:in entsteht eine Abrechnung im Zustand **Entwurf** mit einer Position je Einsatz und Satz (R3–R10). Jede Position trägt die Gruppe des Einsatzes (R24).
4. Hinweise je Abrechnung und Position (R11–R14).
5. Für Personen, die schon eine Abrechnung für das Halbjahr haben, werden nur Entwürfe neu berechnet; abgeschlossene Abrechnungen bleiben unverändert (R15). Neue Anwesenheiten nach dem Abschluss erscheinen als Hinweis „nicht abgerechnete Einsätze“ [ANNAHME].

**B2 – Prüfen und korrigieren**
- Liste der Abrechnungen des Halbjahres: Person, Referat(e), Gruppe(n), Betrag, Hinweise, Zustand; Filter nach Zustand und Hinweis.
- Je Position Korrektur mit Pflichtbegründung: Satz Trainer:in statt Helfer:in (Ausnahme Lizenz, Begründung der Referent:in), Halbtagessatz statt Tagessatz, Menge (z. B. Trainingseinheiten bei Training ohne Trainingszeit) (R16).
- Korrekturen bleiben bei erneuter Berechnung erhalten, solange der Einsatz unverändert in der Abrechnung steckt [ANNAHME].

**B3a – Bestätigen durch die Referent:in („sachlich richtig“)**
- Referent:in sieht die Abrechnungen mit Positionen ihres Referats (Filter: zu bestätigen), begründet ggf. Ausnahmen (Lizenz) und bestätigt die Positionen ihres Referats.
- Sind alle beteiligten Referate bestätigt → Zustand **bestätigt**. Ändert die Geschäftsstelle danach eine Position oder wird neu berechnet, fällt die Bestätigung des betroffenen Referats zurück → **Entwurf** [ANNAHME].

**B3 – Abschließen**
- Geschäftsstelle schließt eine oder mehrere bestätigte Abrechnungen ab → Zustand **abgeschlossen**. Die Anwesenheiten der Positionen werden in der Anwesenheitserfassung gesperrt (R17).
- Abrechnungsdokument je Person als PDF zum Ausdrucken (R18); Unterschrift der Person auf Papier.
- Rücknahme des Abschlusses → zurück zu **Entwurf** (Bestätigungen entfallen), Sperre aufgehoben; nur vor der Abgabe [ANNAHME].

**B4 – Abgabe und Frist**
- Geschäftsstelle trägt „unterschrieben abgegeben am“ ein → Zustand **abgegeben**. Liegt das Datum nach der Abgabefrist, fragt das System nach (R19).
- Nach Ablauf der Frist ohne Abgabe: Liste „Frist abgelaufen“; die Geschäftsstelle setzt **verfallen** (Product Owner 26.10.2026: von Hand, kein automatischer Wechsel). Verfallene Abrechnungen werden nicht ausgezahlt; die Sperre bleibt [ANNAHME].

**B5 – Auszahlungsrunde (Product Owner 26.10.2026)**
1. Geschäftsstelle legt für ein Abrechnungshalbjahr eine neue Auszahlungsrunde an (Nummer fortlaufend je Halbjahr: Runde 1, 2, 3 …) und wählt das Ausführungsdatum.
2. Das System schlägt alle abgegebenen, noch nicht ausgezahlten Abrechnungen des Halbjahres vor; die Geschäftsstelle kann einzelne abwählen. Ausgeschlossen mit Hinweis: ohne Bankverbindung, ohne Bestätigung steuerfreie Einnahmen für das Jahr, ohne Trainervereinbarung (R12–R14), Betrag 0.
3. Vorschau: Auszahlzeilen je Person und Gruppe (R24) mit Summe; Hinweis auf geänderte Bankverbindungen seit der letzten Auszahlung [ANNAHME].
4. **Freigeben** der Runde → Zustand **freigegeben**; das System erzeugt in einem Schritt:
   - **Auszahlliste (PDF)** für die Ablage in der Buchhaltung (C6, R27),
   - **Überweisungsdatei (XML, pain.001.001.03)** für das Online-Banking der Sparkasse (C7, R26),
   beide mit denselben Zeilen und derselben Summe (R28). Die enthaltenen Abrechnungen werden **ausgezahlt** (in Runde n, Ausführungsdatum).
5. Geschäftsstelle lädt die XML im Online-Banking hoch, druckt die Auszahlliste, holt die Unterschriften „gf Vorstand“ und „angewiesen“ ein und gibt sie mit dem Kontoauszug an die Buchhaltung (außerhalb des Vereins OS).
6. Erneuter Download beider Dateien einer freigegebenen Runde ist möglich, mit Warnung „Diese Runde ist bereits freigegeben. Die Überweisungsdatei nicht erneut hochladen.“ (R29).
- Rücknahme einer freigegebenen Runde, wenn die Bank die Datei ablehnt: Iteration 1 (Vorschlag: Runde stornieren → Abrechnungen wieder „abgegeben“, neue Runde). Im MVP kein Storno [ANNAHME].

**B6 – Abgleich Punktekonto Kletterhalle**
- Geschäftsstelle wählt Ort (nur Orte mit Kennzeichen „Punktekonto Kletterhalle“) und Zeitraum der Rechnung.
- Das System zeigt je Training: Datum, Gruppe, Anzahl anwesender Teilnehmer:innen, Anzahl Probetrainings; Summe ohne und mit Probetrainings (aus `ez_climbing_points_report`).
- Geschäftsstelle gibt die Anzahl bzw. Punkte laut Rechnung und die Rechnungsnummer ein; das System zeigt die Abweichung. Der Abgleich wird gespeichert (Datum, Ort, Zeitraum, Werte, Bemerkung) [ANNAHME]. Keine Namen.
- Zählen Probetrainings für die Halle mit? Klärung in Iteration 1; im MVP beide Summen (Product Owner 25./26.10.2026).

**B7 – Iteration 1 (Stichpunkte, Erhebung folgt)**
- Einzelabrechnung je Einsatz (Kurs, Tour, vergütete Einsätze anderer Referate) mit Lehreinheiten, Tagen, Organisationspauschale von Hand; Vorbelegung aus der Planungshilfe (`tk_settlement_draft`); Gemeinschaftstour nur Organisationspauschale; Auszahlung über dieselben Auszahlungsrunden [ANNAHME].
- Reisekosten und Kostenerstattung nach Reisekostenordnung; Kosten bei Absage von Hand.
- Liste „durchgeführt, noch nicht abgerechnet, älter als 4 Wochen“.

**Zustände der Abrechnung**

| Von | Nach | Wer | Bedingung |
|---|---|---|---|
| – | Entwurf | Geschäftsstelle | Berechnung (B1) |
| Entwurf | Entwurf | Geschäftsstelle | neu berechnen, korrigieren |
| Entwurf | bestätigt | Referent:in(nen) | alle beteiligten Referate bestätigt (R23) |
| bestätigt | Entwurf | Geschäftsstelle / System | Korrektur oder Neuberechnung nach der Bestätigung |
| bestätigt | abgeschlossen | Geschäftsstelle | Betrag > 0 [ANNAHME]; nicht dieselbe Person wie bei der Bestätigung; Sperre der Anwesenheiten |
| abgeschlossen | Entwurf | Geschäftsstelle | Rücknahme vor der Abgabe; Sperre aufgehoben |
| abgeschlossen | abgegeben | Geschäftsstelle | Abgabedatum eingetragen |
| abgeschlossen | verfallen | Geschäftsstelle | Frist abgelaufen ohne Abgabe |
| abgegeben | ausgezahlt | System | Freigabe der Auszahlungsrunde (B5) |
| Entwurf | – (gelöscht) | Geschäftsstelle | Entwurf verwerfen [ANNAHME] |

**Zustände der Auszahlungsrunde**

| Von | Nach | Wer | Bedingung |
|---|---|---|---|
| – | Entwurf | Geschäftsstelle | Runde anlegen, Abrechnungen wählen, Ausführungsdatum |
| Entwurf | Entwurf | Geschäftsstelle | Auswahl ändern |
| Entwurf | freigegeben | Geschäftsstelle | mindestens eine Auszahlzeile; Angaben der Sektion vollständig (A10); erzeugt PDF und XML |
| Entwurf | – (gelöscht) | Geschäftsstelle | Runde verwerfen |
| freigegeben | storniert | Geschäftsstelle | Iteration 1, bei Ablehnung durch die Bank |

## C. Daten (Feld | Typ | Pflicht | Beispiel | Quelle)

Tabellen mit Präfix `fi_` (Namen [ANNAHME], Festlegung in der Spec). Beispiele fiktiv.

**C1 – Abrechnung (`fi_settlements`)**

| Feld | Typ | Pflicht | Beispiel | Quelle |
|---|---|---|---|---|
| Person | Verweis Person | ja | Trainerin A | Anwesenheitserfassung |
| Abrechnungshalbjahr | Jahr + Halbjahr | ja | 2026 / 1 | Auswahl |
| Zustand | Auswahl (Entwurf, bestätigt, abgeschlossen, abgegeben, verfallen, ausgezahlt) | ja | abgegeben | System |
| Bestätigung je Referat | Referat, bestätigt am / von, Vertretung mit Begründung | nein | Kinder und Jugend, 10.07.2026 | Referent:in |
| Betrag | Zahl (€) | ja | 312,00 | berechnet |
| abgeschlossen am / von | Zeitpunkt / Nutzer | nein | 12.07.2026 | System |
| abgegeben am | Datum | nein | 20.07.2026 | Geschäftsstelle |
| verfallen am / von | Datum / Nutzer | nein | – | Geschäftsstelle |
| Auszahlungsrunde | Verweis | nein | 1. Hj. 2026, Runde 3 | System |
| Hinweise | berechnet, nicht gespeichert [ANNAHME] | – | „keine Bestätigung 2026“ | R11–R14 |

**C2 – Position (`fi_settlement_items`)**

| Feld | Typ | Pflicht | Beispiel | Quelle |
|---|---|---|---|---|
| Abrechnung | Verweis | ja | – | System |
| Einsatz / Anwesenheit | Verweis | ja | Training Gruppe X, 14.04.2026 | Anwesenheitserfassung |
| Gruppe | Verweis Gruppe | nein (Pflicht bei Einsätzen mit Gruppe) | Gruppe X | Einsatz (R24) |
| Abrechnungsart, Position | Verweis | ja | Trainingseinheiten / Trainingseinheit | Einsatz, Administration |
| Rolle (erfasst) | Trainer:in, Helfer:in | ja | Trainer:in | Anwesenheitserfassung |
| Satzart (abgerechnet) | Trainer:in, Helfer:in, ohne Rolle | ja | Helfer:in (keine förderfähige Lizenz) | R8 |
| Menge | Zahl | ja | 3 (TE) | R3–R7 |
| Satz | Zahl (€) | ja | 6,00 | `ad_rates_at` am Einsatzdatum |
| Betrag | Zahl (€) | ja | 18,00 | Menge × Satz |
| Korrektur: Satzart, Menge, Begründung | Auswahl, Zahl, Text 1–500 | nein (Begründung Pflicht bei Korrektur) | „Ausnahme Lizenz, Begründung Referentin K&J vom 20.06.“ | R16 |
| Hinweis-Kennzeichen | ohne Uhrzeit, ohne Trainingszeit | nein | ohne Uhrzeit | R5, R4 |

Organisationspauschale als eigene Position der organisierenden Person (Menge = Tage).

**C3 – Auszahlungsrunde (`fi_payout_runs`)**

| Feld | Typ | Pflicht | Beispiel | Quelle |
|---|---|---|---|---|
| Abrechnungshalbjahr | Jahr + Halbjahr | ja | 2026 / 1 | Auswahl |
| Nummer | ganze Zahl, fortlaufend je Halbjahr | ja | 3 | System (R25) |
| Zustand | Auswahl (Entwurf, freigegeben, storniert) | ja | freigegeben | System |
| Ausführungsdatum | Datum | ja | 01.08.2026 | Geschäftsstelle |
| Nachrichten-ID, Zahlungs-ID | Text, eindeutig, max. 35 Zeichen | ja (bei Freigabe) | FI-2026-1-03 [ANNAHME: Aufbau] | System (R26) |
| Anzahl Auszahlzeilen, Summe | Zahl | ja | 17 / 3.434,00 € (Muster der Geschäftsstelle) | System |
| freigegeben am / von | Zeitpunkt / Nutzer | nein | 28.07.2026 | System |
| Sachkonto | Text | ja | aus den Angaben der Sektion (A10) | Administration |

**C3a – Auszahlzeile (`fi_payout_lines`)**

| Feld | Typ | Pflicht | Beispiel | Quelle |
|---|---|---|---|---|
| Auszahlungsrunde, Abrechnung | Verweis | ja | – | System |
| Gruppe | Verweis Gruppe bzw. Referat (ohne Gruppe) | ja | Gruppe X | Positionen (R24) |
| Betrag | Zahl (€) | ja | 264,00 | Summe der Positionen der Person in dieser Gruppe |
| Verwendungszweck | Text, max. 140 Zeichen | ja | „ÜL-Vergütung 1. Hj 2026 Gruppe X“ | R26 |
| Ende-zu-Ende-ID | Text, eindeutig, max. 35 Zeichen | ja | FI-2026-1-03-0001 [ANNAHME: Aufbau] | System |

Name und IBAN der Empfänger:in werden nicht gespeichert, sondern beim Erzeugen gelesen (R21).

**C4 – Abgleich Punktekonto (`fi_climbing_checks`)**

| Feld | Typ | Pflicht | Beispiel | Quelle |
|---|---|---|---|---|
| Ort | Verweis `ad_locations` | ja | Kletterhalle Test | Administration |
| Zeitraum von / bis | Datum | ja | 01.10.–31.10.2026 | Geschäftsstelle |
| Anzahl laut Anwesenheitserfassung | Zahl | ja | 48 | `ez_climbing_points_report` |
| Anzahl bzw. Punkte laut Rechnung | Zahl | ja | 51 | Rechnung |
| Rechnungsnummer | Text | nein | TEST-2026-10 | Rechnung |
| Bemerkung | Text 0–500 | nein | „3 Probetrainings?“ | Geschäftsstelle |
| erfasst am / von | Zeitpunkt / Nutzer | ja | – | System |

**C5 – Gelesen, nicht gespeichert**
- Aus der Administration: Sätze (`ad_rates_at`), Abrechnungsarten und Vorbelegung (A1, A2), Höchstbetrag (A4), Fristen (A5), Kennzeichen am Referat (A6), Angaben der Sektion für die Auszahlung (A10: Name, IBAN, BIC, Sachkonto).
- Aus dem Ehrenamtsmanagement (über A8): Kontoinhaber:in, IBAN; Trainervereinbarung (Datum); Bestätigung steuerfreie Einnahmen (Jahr, Abgabedatum); förderfähige Lizenzen (gültig von, gültig bis).
- Aus der Anwesenheitserfassung (über Z2): Einsatz, Gruppe, Anwesenheit, Dauer der Trainingszeit.
- Aus Gruppen: Name der Gruppe (über die Lesefunktion der Anwesenheitserfassung) [ANNAHME].

**C6 – Auszahlliste (PDF), nach der Vorlage der Geschäftsstelle**

| Bereich | Inhalt |
|---|---|
| Titel | „Auszahlliste Übungsleitervergütung {1./2.} Hj. {Jahr}“, dazu „Runde {Nummer}“ [ANNAHME: Rundennummer im Titel] |
| Kopf rechts | „Konto“ mit dem Sachkonto aus den Angaben der Sektion (A10) |
| Tabelle | Spalten Zuname, Vorname, Auszahlungsbetrag (€), Gruppe; eine Zeile je Auszahlzeile (Person und Gruppe); Sortierung nach Gruppe (natürliche Reihenfolge: Gruppe 1, 2 … 10), dann Zuname, Vorname [ANNAHME] |
| Summen | Zwischensumme je Spalte bzw. Seite, Summe der Runde; Summe = Summe der Überweisungsdatei (R28) |
| Unterschriften | „sachl. richtig“: gefüllt mit den Bestätigungen im Vereins OS (je Referat Name, Datum; Vertretung durch die Geschäftsstelle gekennzeichnet) (Product Owner 26.10.2026); „gf Vorstand“ und „angewiesen“: leere Felder für die Unterschrift auf Papier |
| Fuß | Ausführungsdatum, Nachrichten-ID der Überweisungsdatei, „freigegeben am … von …“ [ANNAHME] |
| Format | A4 quer wie die Vorlage; keine IBANs; Layout nach marke.md |

**C7 – Überweisungsdatei (XML), nach der Vorlage der Geschäftsstelle**

Format ISO 20022 **pain.001.001.03** (SEPA-Überweisung), UTF-8, eine Sammelüberweisung je Runde (Product Owner 26.10.2026: Format der Sparkasse laut Vorlage).

| Element | Inhalt |
|---|---|
| `GrpHdr/MsgId` | Nachrichten-ID der Runde, eindeutig, max. 35 Zeichen |
| `GrpHdr/CreDtTm` | Zeitpunkt der Freigabe mit Zeitzone |
| `GrpHdr/NbOfTxs`, `GrpHdr/CtrlSum` | Anzahl Auszahlzeilen, Summe (2 Nachkommastellen, Punkt) |
| `GrpHdr/InitgPty/Nm` | Name der Sektion (A10) |
| `PmtInf/PmtInfId` | Zahlungs-ID der Runde |
| `PmtInf/PmtMtd` | `TRF` |
| `PmtInf/NbOfTxs`, `PmtInf/CtrlSum` | wie Kopf (eine Zahlungsgruppe je Datei) |
| `PmtInf/PmtTpInf/SvcLvl/Cd` | `SEPA` |
| `PmtInf/ReqdExctnDt` | Ausführungsdatum |
| `PmtInf/Dbtr/Nm`, `DbtrAcct/Id/IBAN`, `DbtrAgt/FinInstnId/BIC` | Name, IBAN und BIC der Sektion (A10) |
| `CdtTrfTxInf/PmtId/EndToEndId` | Ende-zu-Ende-ID der Auszahlzeile |
| `CdtTrfTxInf/Amt/InstdAmt` (`Ccy="EUR"`) | Betrag der Auszahlzeile |
| `CdtTrfTxInf/Cdtr/Nm` | Kontoinhaber:in aus der Bankverbindung (max. 70 Zeichen) |
| `CdtTrfTxInf/CdtrAcct/Id/IBAN` | IBAN aus der Bankverbindung; kein BIC der Empfänger:in (wie Vorlage) |
| `CdtTrfTxInf/RmtInf/Ustrd` | Verwendungszweck „ÜL-Vergütung {1/2}. Hj {Jahr} {Gruppe}“ (R26) |

Kein `BtchBookg` (Sammelbuchung nach Voreinstellung der Bank, wie Vorlage), keine Adressen, keine Kategorie.

## D. Regeln (R1, R2 …)

- **R1 – Grundlage:** Abgerechnet werden nur Anwesenheiten mit Stand „anwesend“ und Rolle Trainer:in oder Helfer:in an nicht abgesagten Einsätzen mit Abrechnungsart (≠ „keine Vergütung“). Teilnehmer:innen nie (F1, F2).
- **R2 – Halbjahr:** Ein Einsatz gehört zum Halbjahr seines Datums bzw. Startdatums, auch wenn er über die Halbjahresgrenze reicht [ANNAHME]. Im MVP nur Referate mit Kennzeichen „halbjährliche Abrechnung“.
- **R3 – Trainingseinheiten:** Menge = Dauer der Trainingszeit der Gruppe am Wochentag in Minuten / 30, **aufgerundet** (Product Owner 24.10.2026). Beispiel: 17:00–18:15 = 3 TE.
- **R4 – Training ohne Trainingszeit:** Menge 0 mit Hinweis „ohne Trainingszeit“; die Geschäftsstelle korrigiert die Menge mit Begründung (Product Owner 25.10.2026).
- **R5 – Tages- und Halbtagessätze:** eintägig nach Dauer-Kategorie (unter 8 Stunden = Halbtagessatz, mindestens 8 Stunden = Tagessatz). Mehrtägig: erster Tag Beginn bis 24:00, letzter Tag 0:00 bis Ende, Zwischentage Tagessatz; je Tag unter 8 Stunden = Halbtagessatz [ANNAHME: Berechnungsweise, F4]. Fehlt Beginn bzw. Ende, zählt der erste bzw. letzte Tag als Tagessatz mit Hinweis „ohne Uhrzeit“ (Product Owner 24.10.2026).
- **R6 – Wettkampfbetreuung:** Satz je Kalendertag von Startdatum bis Enddatum, unabhängig von Stunden (Product Owner 24.10.2026).
- **R7 – Organisationspauschale:** je Tag des Einsatzes für die organisierende Person, wenn die Abrechnungsart die Position vorsieht; zusätzlich zu ihrem Tagessatz, wenn sie auch als Trainer:in oder Helfer:in anwesend ist [ANNAHME]. Halbtage zählen als Tag [ANNAHME].
- **R8 – Satzart Trainer:in:** Rolle Trainer:in wird mit Satz Trainer:in abgerechnet, wenn am Datum (mehrtägig: Startdatum, gilt dann für den ganzen Einsatz) eine förderfähige Lizenz gültig ist oder eine förderfähige Lizenz im selben Abrechnungshalbjahr erworben wurde (gültig von im Halbjahr) (Product Owner 24.10.2026). Sonst Satz Helfer:in mit Hinweis „keine förderfähige Lizenz“ [ANNAHME, F5]. Förderfähig = DOSB-lizenzfähig [ANNAHME, AD v0.9].
- **R9 – Satzstand:** Satz aus `ad_rates_at` am Datum bzw. Startdatum des Einsatzes [ANNAHME]. Fehlt ein Satz, wird die Position mit Hinweis „Satz fehlt“ ohne Betrag angelegt und die Abrechnung kann nicht abgeschlossen werden [ANNAHME].
- **R10 – Eine Person, ein Einsatz:** je Einsatz und Person höchstens eine Position je Position der Abrechnungsart (z. B. Tagessatz und Organisationspauschale); bei Wettkampfbetreuung mit mehreren Gruppen nur einmal.
- **R11 – Steuerfreier Höchstbetrag:** Liegt die Summe aller abgeschlossenen, abgegebenen und ausgezahlten Abrechnungen der Person im Kalenderjahr zuzüglich dieser Abrechnung über dem Höchstbetrag, Hinweis „Höchstbetrag überschritten“; keine Sperre [ANNAHME, F6]. Maßgeblich ist das **Jahr der Auszahlung** (Zuflussprinzip; Ausführungsdatum der Runde, bei noch nicht ausgezahlten Abrechnungen das Jahr des Endes der Abgabefrist [ANNAHME]); Höchstbetrag aus `ad_rates_at` am 31.12. dieses Jahres, Startwert 3.300 € ab 01.01.2026 (Product Owner 25.10.2026).
- **R12 – Bestätigung steuerfreie Einnahmen:** Ohne Bestätigung mit „für Jahr“ = Jahr der Abrechnung (bzw. ohne Jahr, abgegeben vor der Auszahlung [ANNAHME]) Hinweis; die Abrechnung kann abgeschlossen, aber nicht in eine Auszahlungsrunde übernommen werden (F6).
- **R13 – Bankverbindung:** Ohne Bankverbindung Hinweis; nicht in eine Auszahlungsrunde.
- **R14 – Trainervereinbarung:** Voraussetzung der Auszahlung (Product Owner 25.10.2026): ohne gültige Trainervereinbarung Hinweis; die Abrechnung kann bestätigt und abgeschlossen, aber nicht in eine Auszahlungsrunde übernommen werden. Gilt für Trainer:innen und Helfer:innen [ANNAHME].
- **R15 – Neu berechnen:** nur Entwürfe; abgeschlossene und spätere Zustände bleiben unverändert.
- **R16 – Korrektur:** Jede Abweichung vom berechneten Wert braucht eine Begründung (1–500 Zeichen), sonst Fehlermeldung „Bitte eine Begründung angeben.“; berechneter und korrigierter Wert bleiben sichtbar.
- **R17 – Sperre:** Ab dem Abschluss sind die abgerechneten Anwesenheiten und die abrechnungsrelevanten Kopfdaten des Einsatzes in der Anwesenheitserfassung gesperrt (Product Owner 24.10.2026; Übergabe FI → EZ, Z3). Rücknahme des Abschlusses hebt die Sperre auf.
- **R18 – Abrechnungsdokument:** enthält Person (Name, ohne Bankdaten [ANNAHME]), Halbjahr, Positionen mit Datum, Gruppe, Einsatz, Menge, Satz, Betrag, Korrekturen mit Begründung, Summe je Gruppe und gesamt, Abgabefrist, Hinweis auf das Erlöschen des Anspruchs, Erklärung der Person zum Freibetrag (Product Owner 25.10.2026; Wortlaut [ANNAHME]: „Ich versichere, dass die Angaben richtig sind und die Vergütung zusammen mit anderen Einnahmen aus nebenberuflicher Tätigkeit nach § 3 Nr. 26 EStG den Freibetrag im Kalenderjahr nicht übersteigt. Änderungen teile ich der Sektion unverzüglich mit.“), Ort, Datum, Unterschriftsfeld. Layout nach marke.md.
- **R19 – Frist:** Abgabefrist aus den Stammdaten der Administration (Start: 31.07. für das 1., 15.12. für das 2. Halbjahr). Abgabe nach der Frist: Rückfrage „Die Frist ist abgelaufen. Der Anspruch ist erloschen. Trotzdem als abgegeben erfassen?“ Mit Bestätigung und Pflichtbegründung wird gespeichert (Ausnahme, Product Owner 26.10.2026).
- **R20 – Auszahlung:** Eine Abrechnung ist höchstens in einer freigegebenen Auszahlungsrunde; danach nicht mehr änderbar.
- **R21 – Datensparsamkeit:** Name der Kontoinhaber:in und IBAN werden nur beim Erzeugen der Überweisungsdatei gelesen und nicht in Finanzen gespeichert; die Dateien werden nicht gespeichert, sondern bei jedem Download aus den gespeicherten Auszahlzeilen neu erzeugt [ANNAHME]. Hat sich eine Bankverbindung seit der Freigabe geändert, erscheint vor dem erneuten Download ein Hinweis [ANNAHME].
- **R22 – Aufbewahrung:** Abrechnungen, Positionen, Auszahlungsrunden, Auszahlzeilen und Abgleiche werden 5 Jahre nach Ende des Kalenderjahres der Auszahlung bzw. des Verfalls gelöscht [ANNAHME: Beginn der Frist] (Q4, Product Owner 24.10.2026: 5 Jahre wie überall). Auszahlliste und Kontoauszug als Belege liegen in der Finanzbuchhaltung.
- **R23 – Bestätigung (Vier-Augen-Prinzip):** Abschließen ist erst möglich, wenn für jedes Referat mit Positionen in der Abrechnung eine Referent:in mit Reichweite dieses Referats bestätigt hat; sonst „Die Abrechnung ist noch nicht von allen Referaten bestätigt.“ [ANNAHME: Wortlaut]. Die abschließende Person darf nicht die bestätigende sein. Vertretung (Product Owner 25.10.2026): bestätigen darf jede Person mit der Vorlage Referent:in für dieses Referat (auch stellvertretend); ist niemand da, bestätigt eine zweite Person der Geschäftsstelle mit Pflichtbegründung (1–500 Zeichen), die im Verlauf und auf der Auszahlliste sichtbar bleibt.
- **R24 – Auszahlzeile je Person und Gruppe (Product Owner 26.10.2026):** Je Abrechnung entsteht eine Auszahlzeile je Gruppe ihrer Positionen (Betrag = Summe dieser Positionen) und daraus je eine Überweisung. Wettkampfbetreuung mit mehreren Gruppen zählt zur ersten Gruppe des Einsatzes [ANNAHME]; Positionen ohne Gruppe (Iteration 1) bilden eine Zeile je Referat [ANNAHME]. Höchstbetrag (R11) und Voraussetzungen (R12–R14) gelten je Person.
- **R25 – Nummer der Runde:** fortlaufend je Abrechnungshalbjahr ab 1; eine verworfene Runde im Entwurf gibt ihre Nummer nicht frei [ANNAHME]. Eine Abrechnung kann nur in einer Runde im Entwurf gleichzeitig stehen.
- **R26 – Überweisungsdatei:** Aufbau nach C7 (pain.001.001.03 wie die Vorlage der Sparkasse). IDs eindeutig, max. 35 Zeichen, nur Buchstaben, Ziffern und Bindestrich [ANNAHME: Aufbau aus Halbjahr, Rundennummer und laufender Nummer]. Verwendungszweck „ÜL-Vergütung {1/2}. Hj {Jahr} {Name der Gruppe}“, höchstens 140 Zeichen, sonst gekürzt; Umlaute wie in der Vorlage zulässig [ANNAHME: Zeichensatz der Sparkasse]. Beträge mit Punkt und 2 Nachkommastellen. Freigabe nur, wenn Name, IBAN und BIC der Sektion vorhanden sind; sonst „Die Angaben der Sektion für die Auszahlung fehlen. Bitte den Admin informieren.“ [ANNAHME: Wortlaut].
- **R27 – Auszahlliste:** Aufbau nach C6; enthält keine Bankdaten der Empfänger:innen.
- **R28 – Gleichheit:** Auszahlliste und Überweisungsdatei einer Runde enthalten dieselben Auszahlzeilen in derselben Reihenfolge; Summe der Liste = `CtrlSum`, Anzahl Zeilen = `NbOfTxs`. Die Summe erscheint als eine Buchung auf dem Kontoauszug und ist damit gegen die Auszahlliste prüfbar.
- **R29 – Erneuter Download:** PDF und XML einer freigegebenen Runde jederzeit erneut abrufbar, mit derselben Nachrichten-ID und denselben Ende-zu-Ende-IDs; vor dem XML-Download Warnung „Diese Runde ist bereits freigegeben. Die Überweisungsdatei nicht erneut hochladen.“
- **R30 – Ausführungsdatum:** nicht in der Vergangenheit; Standard nächster Bankarbeitstag [ANNAHME].

## E. Schnittstellen

| Schnittstelle | Richtung | Inhalt |
|---|---|---|
| Administration | AD → FI | `ad_has_level('FI', …)`, `ad_modules` (FI), `ad_rates_at`, Abrechnungsarten und Vorbelegung, Fristen, Kennzeichen am Referat, Angaben der Sektion für die Auszahlung (Name, IBAN, BIC, Sachkonto), Lesefunktion Personendaten, `ea_person_names` (Übergabe FI → AD, A1–A10) |
| Anwesenheitserfassung | EZ → FI | Lesefunktion Abrechnungsgrundlage mit FI-Rechten inkl. Gruppe und Gruppenname, `ez_climbing_points_report` mit FI-Rechten (Z2) |
| Anwesenheitserfassung | FI → EZ | Sperre über `fi_attendance_locked` (Platzhalter in EZ, ersetzt von FI) (Z3); Abrechnungsart am Einsatz (Z1) |
| Planungshilfe Touren und Kurse | TK → FI | `tk_settlement_draft` (Iteration 1); Übergabe FI → TK v1.0 |
| Sparkasse | FI → extern | Überweisungsdatei pain.001.001.03 nach C7, manueller Upload im Online-Banking (Product Owner 26.10.2026) |
| Finanzbuchhaltung | FI → extern | Auszahlliste (PDF, mit Unterschriften auf Papier) und Kontoauszug als Beleg; unterschriebene Abrechnungsdokumente; kein DATEV-Export im MVP |
| Kletterhalle | extern → FI | Rechnung, manuelle Eingabe der Werte |

## F. Datenschutz

- Zweck: Vergütung nach der Vergütungsordnung und Kontrolle der Rechnungen der Kletterhalle. Eintrag im Verarbeitungsverzeichnis (Trainerabrechnung, Bankverbindung, Auszahlung).
- Zugriff im MVP: Geschäftsstelle (FI verwalten) und Referent:innen (Reichweite „Referat“, ohne Bankdaten und ohne Nachweisdaten, nur Hinweise). Bankverbindung und Nachweise nur über die Lesefunktion mit festen Spalten (A8); keine Lizenznummern, keine weiteren Eigenschaften.
- Keine Daten von Teilnehmer:innen außer Anzahlen (Abgleich Punktekonto).
- Überweisungsdatei nur als Download, nicht gespeichert; Name der Kontoinhaber:in und IBAN nicht in Finanzen gespeichert (R21). Die Datei landet im Download-Ordner des Arbeitsplatzes; Hinweis, sie nach dem Hochladen zu löschen [ANNAHME].
- Auszahlliste und Abrechnungsdokument ohne Bankdaten.
- Echtdaten (z. B. die Vorlagen der Geschäftsstelle) nie im Repository oder in TEST; Tests nur mit fiktiven Daten und der Beispiel-IBAN.
- Aufbewahrung 5 Jahre (R22); Belege in der Finanzbuchhaltung (bestätigt vom Product Owner 25.10.2026).
- Freitexte (Begründung, Bemerkung) mit Hinweis, keine sensiblen Angaben einzutragen.

## G. Nicht-funktional

- Mengengerüst [ANNAHME]: ca. 130 Trainer:innen und Helfer:innen je Halbjahr; ca. 30 Gruppen; ca. 1.500 Trainings und 4.000 abrechenbare Anwesenheiten je Halbjahr; 3–6 Auszahlungsrunden je Halbjahr mit bis zu 150 Auszahlzeilen.
- Berechnung eines Halbjahres unter 10 Sekunden; Liste der Abrechnungen unter 2 Sekunden; Erzeugen von PDF und XML einer Runde unter 5 Sekunden [ANNAHME].
- Berechnung in der Datenbank (nachvollziehbar, mit pgTAP-Tests je Regel R3–R11, R24, R28).
- Die XML wird gegen das Schema pain.001.001.03 geprüft (Test mit fiktiven Daten) [ANNAHME].
- Bedienung vor allem am Arbeitsplatz; Listen mobil lesbar ab 375 px; Abrechnungsdokument PDF A4 hoch, Auszahlliste PDF A4 quer.
- Keine laufenden Kosten; keine externe Bankschnittstelle.

## H. Nachtrag v0.7: Buchungslauf Verträge (Product Owner 26.10.2026)

**Anlass:** Die Geschäftsstelle erstellt den monatlichen Einzug der Gruppenbeiträge heute von Hand (ca. 30 Minuten, 00-steckbrief.md). Die Verträge mit SEPA-Mandat liegen seit dem Modul Gruppen im Vereins OS (`gr_contracts`, glossar.md „Vertrag“, „Mandatsreferenz“). Ziel: Buchungslauf in ca. 1 Minute (Vision Z2), ohne Abtippen.

**Rechte:** nur „FI verwalten“ (Geschäftsstelle). Referent:innen, Admin und Vorstand sehen keine Buchungsläufe. Die Geschäftsstelle erstellt und gibt allein frei, kein Vier-Augen-Prinzip (Product Owner 26.10.2026).

**H1 – Buchungslauf erstellen**
1. Die Geschäftsstelle wählt „Neuer Buchungslauf“ und den **Monat** (Standard: der Monat, dessen Fälligkeitstag als nächster erreichbar ist [ANNAHME]).
2. Das System schlägt den **Fälligkeitstag** vor: **Tag des Erstellens + 3 Tage** (Product Owner 26.10.2026); fällt er auf Samstag oder Sonntag, der nächste Bankarbeitstag (Mo–Fr; Feiertage nicht berücksichtigt [ANNAHME]). Er ist änderbar und muss mindestens einen Bankarbeitstag nach heute liegen (R39).
3. Das System stellt alle Verträge zusammen, die am **1. des Monats aktiv** sind (Vertragsbeginn ≤ 1., Vertragsende leer oder ≥ 1.) und für diesen Monat **noch nicht eingezogen** wurden (R34, R35). Je Vertrag eine Lastschrift über den **vollen Monatsbetrag** (kein anteiliger Betrag).
4. Vorschau: Lastschriften je Gruppe mit Teilnehmer:in, Vertragsinhaber:in, Mandatsreferenz, Betrag, Erst- oder Folgelastschrift; Summe je Gruppe und gesamt; Anzahl. Ausgeschlossene Verträge mit Grund (R37).
5. Die Geschäftsstelle kann einzelne Lastschriften abwählen (z. B. Klärung mit Eltern) [ANNAHME]; abgewählte Verträge bleiben für diesen Monat offen und kommen in einen Nachtrag.
5a. Die Geschäftsstelle kann bei einer Lastschrift einen **Zusatzbetrag** für eine Nachzahlung mit Text für den Verwendungszweck und Begründung erfassen (R47; Product Owner 26.10.2026, Vorlage: „… und rückwirkend bis Mai 2025“).
6. Ein Buchungslauf im Entwurf kann verworfen werden; die Verträge werden wieder frei.

**H2 – Freigeben**
1. „Freigeben“ mit Rückfrage „Buchungslauf {Monat} mit {Anzahl} Lastschriften über {Summe} freigeben? Fälligkeit {Datum}.“
2. Danach erzeugt der Browser die **Lastschriftdatei** (XML, pain.008, R40) und die **Einzugsliste** (PDF, R41) aus denselben Daten (Summe der Liste = Summe der Datei). Nichts davon wird gespeichert; gespeichert werden nur die Einzüge ohne IBAN (R43).
3. Hinweis nach dem Download: „Bitte die Lastschriftdatei nach dem Hochladen im Online-Banking von diesem Rechner löschen.“ (wie die Überweisungsdatei).
4. Erneuter Abruf einer freigegebenen Datei mit gleichen IDs und Warnung „Dieser Buchungslauf ist bereits freigegeben. Die Lastschriftdatei nicht erneut hochladen.“ (wie R29).

**H3 – Nachtrag**
Für denselben Monat ist ein weiterer Buchungslauf möglich (**Nachtrag**, fortlaufend nummeriert: Lauf 1, 2 … je Monat). Er enthält nur Verträge, die für den Monat noch nicht eingezogen wurden, z. B. später erfasste oder im ersten Lauf abgewählte Verträge (R35).

**H4 – Später (nicht in diesem Nachtrag)**
Rücklastschriften (Rückgabe, Gebühr, erneuter Einzug) [OFFEN, Iteration später]; Storno eines freigegebenen Buchungslaufs; Vorabinformation der Zahlungspflichtigen aus dem Vereins OS; DATEV-Buchungsexport; Lastschriften für andere Anlässe (z. B. Kurse).

**C8 – Buchungslauf (`fi_collection_runs`) [ANNAHME: Namen]**

| Feld | Typ | Pflicht | Beispiel | Quelle |
|---|---|---|---|---|
| Monat | Datum (1. des Monats) | ja | 01.11.2026 | Auswahl |
| Nummer | Zahl je Monat ab 1 | ja | 1 | System (R35) |
| Zustand | Entwurf / freigegeben | ja | Entwurf | System |
| Fälligkeitstag | Datum | ja | 05.11.2026 | Erstellen + 3 Tage, änderbar (R39) |
| Nachrichten-ID, Zahlungs-IDs | Text ≤ 35 | bei Freigabe | FI-L-2026-11-01-AB12CD34 | System (R40) |
| Anzahl, Summe (gesamt, je Erst-/Folgelastschrift) | Zahl, Betrag | bei Freigabe | 84 / 2.940,00 € | System |
| freigegeben am, von | Zeitpunkt, Person | bei Freigabe | | System |

**C9 – Einzug (`fi_collections`), je Vertrag und Monat**

| Feld | Typ | Pflicht | Beispiel | Quelle |
|---|---|---|---|---|
| Buchungslauf | Bezug | ja | | System |
| Vertrag | Bezug `gr_contracts` | ja | | Gruppen |
| Monat | Datum | ja | 01.11.2026 | Buchungslauf |
| Monatsbetrag | Betrag > 0 | ja | 21,00 € | Monatsbetrag des Vertrags am Erstellen |
| Zusatzbetrag, Zusatztext, Begründung | Betrag > 0, Text ≤ 60, Text 1–500 | nein | 252,00 €, „und rückwirkend bis Mai 2025“ | Geschäftsstelle (R47) |
| Betrag | Betrag > 0 | ja | 273,00 € | Monatsbetrag + Zusatzbetrag |
| Sequenz | Erst- / Folgelastschrift | ja | Folgelastschrift | System (R38) |
| Mandatsreferenz, Unterschriftsdatum Mandat | Text, Datum | ja | GR-2026-0001 | Vertrag, Stand der Freigabe |
| Gruppe (Name zur Freigabe) | Text | ja | Jugendgruppe Test 1 | Gruppen |
| Verwendungszweck | Text ≤ 140 | ja | Jugendgruppe Test 1 Beitragszahlung November 2026 | R42 |
| Ende-zu-Ende-ID | Text ≤ 35 | ja | FI-L-2026-11-01-0001 | System |
| Prüfwert Bankverbindung | Text | ja | – | System (R43; keine IBAN) |

Je Vertrag und Monat höchstens ein Einzug in einem Entwurf oder freigegebenen Lauf (eindeutig).

**C10 – Einzugsliste (PDF)**

| Bereich | Inhalt |
|---|---|
| Titel | „Einzugsliste Verträge {Monat JJJJ} – Lauf {Nummer}“ |
| Kopf | Name der Sektion, Gläubiger-Identifikationsnummer, Fälligkeitstag, Sachkonto der Gruppenbeiträge (Administration, R41) |
| Tabelle | je Lastschrift: Teilnehmer:in (Nachname, Vorname), Gruppe, Vertragsinhaber:in, Mandatsreferenz, IBAN gekürzt (`•••• 1234`, Product Owner 26.10.2026), Erst-/Folgelastschrift, Betrag (bei Zusatzbetrag mit Zusatztext); sortiert nach Gruppe (natürliche Reihenfolge), dann Nachname, Vorname |
| Summen | je Gruppe, je Seite, gesamt; gesamt = Summe der Lastschriftdatei |
| Fuß | Nachrichten-ID, freigegeben am … von … |
| Format | A4 quer, Layout nach marke.md; keine vollständige IBAN |

**C11 – Lastschriftdatei (XML)**

Format ISO 20022 **pain.008.001.02** (SEPA-Basislastschrift CORE), UTF-8, wie die Vorlage der Geschäftsstelle (Lastschriftdatei Oktober 2026 der Sparkasse, Product Owner 26.10.2026). Aufbau der Vorlage: eine Zahlungsgruppe, `SeqTp` = `RCUR` für alle Lastschriften, IDs als 12-stellige Ziffernfolgen, `DbtrAgt` = `NOTPROVIDED`, kein `BtchBookg`, kein `ChrgBr`.

| Element | Inhalt |
|---|---|
| `GrpHdr/MsgId`, `CreDtTm`, `NbOfTxs`, `CtrlSum`, `InitgPty/Nm` | Nachrichten-ID, Zeitpunkt der Freigabe (Europe/Berlin), Anzahl, Summe, Name der Sektion |
| `PmtInf` | **je Sequenz eine Zahlungsgruppe** (`FRST`, `RCUR`), nur wenn Lastschriften dieser Sequenz vorhanden sind; je `PmtInfId`, `PmtMtd` = `DD`, `NbOfTxs`, `CtrlSum` |
| `PmtTpInf` | `SvcLvl/Cd` = `SEPA`, `LclInstrm/Cd` = `CORE`, `SeqTp` = `FRST` bzw. `RCUR` |
| `ReqdColltnDt` | Fälligkeitstag |
| `Cdtr/Nm`, `CdtrAcct/Id/IBAN`, `CdtrAgt/FinInstnId/BIC` | Name, IBAN, BIC der Sektion (Angaben der Sektion, AD) |
| `CdtrSchmeId` | Gläubiger-Identifikationsnummer der Sektion (`Id/PrvtId/Othr/Id`, `SchmeNm/Prtry` = `SEPA`) |
| `DrctDbtTxInf/PmtId/EndToEndId` | Ende-zu-Ende-ID (Aufbau nach R40; die Vorlage verwendet Ziffernfolgen, beides ist zulässig) |
| `InstdAmt` (`Ccy="EUR"`) | Betrag mit Punkt und 2 Nachkommastellen |
| `MndtRltdInf/MndtId`, `DtOfSgntr` | Mandatsreferenz, Unterschriftsdatum |
| `MndtRltdInf/AmdmntInd` | [OFFEN] Mandatsänderung (R44) |
| `DbtrAgt/FinInstnId/Othr/Id` | `NOTPROVIDED` (kein BIC der Zahlungspflichtigen, wie Vorlage) |
| `Dbtr/Nm`, `DbtrAcct/Id/IBAN` | Kontoinhaber:in und IBAN aus dem Vertrag (max. 70 Zeichen; Zeichensatz wie R26) |
| `RmtInf/Ustrd` | Verwendungszweck (R42) |

**Regeln**

- **R34 – Auswahl:** Eingezogen werden Verträge, die am 1. des Monats aktiv sind: Vertragsbeginn ≤ 1. des Monats und (Vertragsende leer oder ≥ 1. des Monats). Beginnt ein Vertrag im laufenden Monat, ist der erste Einzug im Folgemonat; endet er im Monat, wird dieser Monat noch eingezogen. Immer der volle Monatsbetrag des Vertrags (Stand beim Erstellen bzw. letzten Aktualisieren des Entwurfs); keine anteiligen Beträge (Product Owner 26.10.2026). Teilnahme und Gruppe spielen dafür keine Rolle (Vertragsende und „Teilnahme bis“ sind unabhängig, spec.md GR R8b).
- **R35 – Einmal je Monat, Nachtrag:** Je Vertrag und Monat höchstens ein Einzug. Ein weiterer Buchungslauf für denselben Monat (Nachtrag) enthält nur Verträge ohne Einzug in diesem Monat. Ein Vertrag, der in einem Entwurf steht, ist für andere Läufe desselben Monats gesperrt (Product Owner 26.10.2026). Nummer je Monat fortlaufend, nicht wieder vergeben.
- **R36 – Nachholen:** Für vergangene Monate ist kein Buchungslauf möglich [ANNAHME]; nicht eingezogene Monate holt die Geschäftsstelle außerhalb nach. Frühester Monat: Monat des Stichtags (R38).
- **R37 – Ausgeschlossen mit Grund:** Unterschriftsdatum des Mandats nach dem Fälligkeitstag („Mandat noch nicht unterschrieben“); Zeichen der Kontoinhaber:in nicht darstellbar (wird ersetzt, kein Ausschluss, R26). Weitere Gründe [OFFEN] (z. B. Teilnahme klären, Gruppe aufgelöst – nach heutigem Stand kein Ausschluss).
- **R38 – Erst- und Folgelastschrift:** Bestätigt 26.10.2026, obwohl die Vorlage der Sparkasse nur Folgelastschriften enthält. Erstlastschrift (`FRST`), wenn der Vertrag im Vereins OS noch keinen freigegebenen Einzug hat **und** sein Vertragsbeginn am oder nach dem **Stichtag** liegt; sonst Folgelastschrift (`RCUR`). Der Stichtag (Beginn der Buchungsläufe im Vereins OS) ist ein Stammdatum der Administration, einmal vom Admin gesetzt; Verträge mit Beginn davor gelten als bereits eingezogen (Product Owner 26.10.2026).
- **R39 – Fälligkeitstag:** Vorschlag = Tag des Erstellens + 3 Kalendertage [ANNAHME: Kalendertage], verschoben auf den nächsten Bankarbeitstag (Mo–Fr) (Product Owner 26.10.2026). Änderbar. Mindestens ein Bankarbeitstag nach heute (Vorlage: erstellt 06.10., fällig 07.10.), sonst „Der Fälligkeitstag muss mindestens einen Bankarbeitstag in der Zukunft liegen.“ Kein Stammdatum in der Administration.
- **R40 – IDs:** Nachrichten-ID `FI-L-{JJJJ}-{MM}-{Lauf, 2-stellig}-{8 Zeichen Zufall}`, Zahlungs-IDs mit Zusatz `-FRST` bzw. `-RCUR`, Ende-zu-Ende-ID `{Nachrichten-ID ohne Zufallsteil}-{laufende Nummer, 4-stellig}`; nur Buchstaben, Ziffern, Bindestrich, max. 35 Zeichen [ANNAHME, wie R26].
- **R41 – Einzugsliste:** nach C10, mit gekürzter IBAN (letzte 4 Stellen). Sachkonto der Gruppenbeiträge als eigenes Eingabefeld bei den Angaben der Sektion in der Administration (Product Owner 26.10.2026).
- **R42 – Verwendungszweck:** nach der Vorlage „{Name der Gruppe} Beitragszahlung {Monat ausgeschrieben} {JJJJ}“, z. B. „Gruppe 1 Beitragszahlung Oktober 2026“; bei Zusatzbetrag mit angehängtem Zusatztext (R47); auf 140 Zeichen gekürzt. Der Verwendungszweck am Vertrag (`gr_contracts.purpose`) wird für die Lastschrift nicht verwendet [ANNAHME].
- **R43 – Datenschutz:** Kontoinhaber:in und IBAN werden nur zum Erzeugen der Datei gelesen (Lesefunktion der Gruppen nur mit „FI verwalten“) und nicht in Finanzen gespeichert; gespeichert wird ein Prüfwert. Beim erneuten Abruf Hinweis „Bankverbindung seit Freigabe geändert“ (wie R21). Einzüge werden 5 Jahre nach Ende des Kalenderjahres aufbewahrt [ANNAHME, wie Q4; Belege in der Finanzbuchhaltung].
- **R44 – Mandatsänderung [OFFEN]:** Ändert die Geschäftsstelle nach einem Einzug IBAN, Kontoinhaber:in oder Mandatsreferenz eines Vertrags, verlangt das SEPA-Verfahren je nach Fall ein Änderungskennzeichen mit den bisherigen Angaben. Vorschlag: im Nachtrag nicht abbilden; die Vorschau zeigt den Hinweis „Bankverbindung seit dem letzten Einzug geändert“, die Geschäftsstelle klärt mit der Sparkasse. Klären mit der Sparkasse.
- **R45 – Freigabe:** nur Entwurf mit mindestens einer Lastschrift („Der Buchungslauf enthält keine Lastschriften.“); Gläubiger-ID, Name, IBAN und BIC der Sektion vorhanden („Die Angaben der Sektion für den Einzug fehlen. Bitte den Admin informieren.“); Fälligkeitstag nach R39. Danach gilt der Monat für die enthaltenen Verträge als eingezogen. Kein Storno [ANNAHME, wie Auszahlungsrunde].
- **R47 – Zusatzbetrag (Nachzahlung):** Im Entwurf kann die Geschäftsstelle je Lastschrift einen Zusatzbetrag (> 0, höchstens 2 Nachkommastellen) mit Zusatztext (1–60 Zeichen, wird an den Verwendungszweck angehängt) und Begründung (1–500 Zeichen) erfassen; Betrag der Lastschrift = Monatsbetrag + Zusatzbetrag. Die Einzugsliste zeigt den Zusatzbetrag mit Text getrennt. Ändern und Entfernen nur im Entwurf. Fehlt Text oder Begründung: „Bitte Text und Begründung angeben.“ (Product Owner 26.10.2026).
- **R46 – Änderungen nach der Freigabe:** Kündigung oder Betragsänderung nach der Freigabe ändern den Einzug nicht; die Geschäftsstelle erstattet bei Bedarf außerhalb [ANNAHME].

**Schnittstellen (Ergänzung zu E)**

| Modul | Richtung | Inhalt |
|---|---|---|
| Gruppen | GR → FI | Lesefunktion Verträge für den Einzug mit „FI verwalten“ (Übergabe FI → GR v1.0, G1–G3) |
| Administration | AD → FI | Gläubiger-Identifikationsnummer und Sachkonto der Gruppenbeiträge bei den Angaben der Sektion, Stichtag erster Buchungslauf (Übergabe FI → AD v1.4, A11, A13) |
| Sparkasse | FI → extern | Lastschriftdatei pain.008 (manueller Upload) |

**Begriffe (Vorschlag für glossar.md)**

| Begriff | Definition | Nicht verwechseln mit |
|---|---|---|
| Einzug | Eine Lastschrift für einen Vertrag und einen Monat. | Abrechnung; Auszahlzeile |
| Lastschriftdatei | SEPA-Datei (pain.008) eines Buchungslaufs mit einer Lastschrift je Einzug, zum Hochladen im Online-Banking. | Überweisungsdatei |
| Einzugsliste | PDF eines Buchungslaufs für die Buchhaltung mit allen Einzügen und Summen. | Auszahlliste |
| Fälligkeitstag | Tag, an dem die Lastschriften dem Konto belastet werden. | Ausführungsdatum (Überweisung) |
| Gläubiger-Identifikationsnummer | Kennung der Sektion als Lastschrift-Empfängerin (Bundesbank). | Mandatsreferenz |
| Erstlastschrift / Folgelastschrift | erster bzw. weiterer Einzug aus einem Mandat. | – |
| Nachtrag (Buchungslauf) | weiterer Buchungslauf für einen Monat mit noch nicht eingezogenen Verträgen. | Storno |

## Offene Fragen (Frage | Wer klärt | bis wann)

| Frage | Wer klärt | bis wann |
|---|---|---|
| Wortlaut der Erklärung auf dem Abrechnungsdokument prüfen (R18, [ANNAHME]) | Product Owner | Abnahme MVP |
| Rücknahme einer freigegebenen Runde bei Ablehnung durch die Bank | Geschäftsstelle mit Sparkasse | Iteration 1 |
| Zählen Probetrainings für die Kletterhalle (B6)? | Geschäftsstelle | Iteration 1 |
| Sonderfälle im heutigen Ablauf (z. B. Nachzahlungen, Rückforderungen) | Geschäftsstelle | Iteration 1 |
| Mandatsänderung nach einem Einzug (R44) | Geschäftsstelle mit Sparkasse | vor der Spec Buchungslauf |
| Stichtag des ersten Buchungslaufs (R38) | Geschäftsstelle | vor der Umsetzung |
| Rücklastschriften (H4) | Geschäftsstelle | später |
