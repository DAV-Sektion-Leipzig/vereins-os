# Erhebung: Finanzen

Datum: 24.10.2026 · Version 0.1 · Status: Entwurf · Beteiligte: Toni Werner (Product Owner); Geschäftsstelle und Schatzmeister:in noch nicht befragt [OFFEN]
Grundlage: 00-steckbrief.md v0.1 (MVP-Schnitt, Entscheidungen 24.10.2026); specs/ez-einsaetze/uebergabe-finanzen.md v1.6 (F1–F9); specs/tk-touren-kurse/uebergabe-finanzen.md v1.3; specs/ez-einsaetze/spec.md v0.5; specs/ad-administration/spec.md v0.9; specs/ea-ehrenamt/01-erhebung.md v0.5 (C2); Vergütungsordnung (Beschluss 21.11.2023, ergänzt 11.12.2025, Anhang 1)
Änderungen v0.1: Erster Entwurf für den MVP (halbjährliche Abrechnung, Überweisungsdatei, Abgleich Punktekonto). Iteration 1 nur in Stichpunkten (Abschnitt B7).

Begriffe nach glossar.md; neue Begriffe (Abrechnungsart, Position, Abrechnungsdokument, Abgabe, Überweisungsdatei, Abgleich Punktekonto, steuerfreier Höchstbetrag) als Vorschlag im Steckbrief.

## A. Rechtevorlagen & Rechte

| Rechtevorlage | FI | Was | Reichweite |
|---|---|---|---|
| Geschäftsstelle | verwalten | Abrechnungen erstellen, neu berechnen, korrigieren, freigeben, Freigabe zurücknehmen, Abgabe und Verfall erfassen, Abrechnungsdokument drucken, Überweisungsdatei erzeugen, Abgleich Punktekonto | alle |
| Admin | – | kein Zugriff auf Finanzen; pflegt Sätze, Abrechnungsarten, Vorbelegung, Fristen, Höchstbetrag in der Administration | – |
| Referent:in | – | im MVP kein Zugriff; Begründung einer Ausnahme (Lizenz) gibt sie der Geschäftsstelle außerhalb des Vereins OS | – |
| Vorstand | – | Startwert ohne Rechte | – |
| Schatzmeister:in, Kassenprüfung (nach MVP) | lesen [ANNAHME] | Abrechnungen und Überweisungsdateien einsehen; ggf. „freigeben“ als eigene Aktion (Q1) | alle |

- „Freigeben“ und „Überweisungsdatei erzeugen“ sind im MVP Teil von „verwalten“ (rollen.md 5: Abläufe auslösen) [ANNAHME]. [OFFEN] Vier-Augen-Prinzip.
- Personendaten (Bankverbindung, Nachweise, Lizenzen) liest Finanzen nur über die Lesefunktion der Administration (Übergabe FI → AD, A8); Namen über `ea_person_names` (A9).
- Einsätze und Anwesenheiten liest Finanzen über eine Lesefunktion der Anwesenheitserfassung mit FI-Rechten (Übergabe FI → EZ, Z2).

## B. Abläufe (inkl. Zustände)

**B1 – Halbjahresabrechnung erstellen**
1. Geschäftsstelle wählt das Abrechnungshalbjahr (1. Halbjahr 01.01.–30.06., 2. Halbjahr 01.07.–31.12.).
2. Das System sucht alle nicht abgesagten Einsätze mit Abrechnungsart der Referate mit Kennzeichen „halbjährliche Abrechnung“ (Kinder und Jugend, Leistungssport), deren Datum (mehrtägig: Startdatum) im Halbjahr liegt (R1, R2).
3. Je Person mit Anwesenheit „anwesend“ als Trainer:in oder Helfer:in entsteht eine Abrechnung im Zustand **Entwurf** mit einer Position je Einsatz und Satz (R3–R10).
4. Hinweise je Abrechnung und Position (R11–R14).
5. Für Personen, die schon eine Abrechnung für das Halbjahr haben, werden nur Entwürfe neu berechnet; freigegebene Abrechnungen bleiben unverändert (R15). Neue Anwesenheiten nach der Freigabe erscheinen als Hinweis „nicht abgerechnete Einsätze“ [ANNAHME].

**B2 – Prüfen und korrigieren**
- Liste der Abrechnungen des Halbjahres: Person, Referat(e), Betrag, Hinweise, Zustand; Filter nach Zustand und Hinweis.
- Je Position Korrektur mit Pflichtbegründung: Satz Trainer:in statt Helfer:in (Ausnahme Lizenz, Begründung der Referent:in), Halbtagessatz statt Tagessatz, Menge (z. B. Trainingseinheiten bei Training ohne Trainingszeit) (R16).
- Korrekturen bleiben bei erneuter Berechnung erhalten, solange der Einsatz unverändert in der Abrechnung steckt [ANNAHME].

**B3 – Freigeben**
- Geschäftsstelle gibt eine oder mehrere Abrechnungen frei → Zustand **freigegeben**. Die Anwesenheiten der Positionen werden in der Anwesenheitserfassung gesperrt (R17).
- Abrechnungsdokument je Person als PDF zum Ausdrucken (Abschnitt C, R18); Unterschrift auf Papier.
- Rücknahme der Freigabe → zurück zu **Entwurf**, Sperre aufgehoben; nur vor der Abgabe [ANNAHME].

**B4 – Abgabe und Frist**
- Geschäftsstelle trägt „unterschrieben abgegeben am“ ein → Zustand **abgegeben**. Liegt das Datum nach der Abgabefrist, fragt das System nach (R19).
- Nach Ablauf der Frist ohne Abgabe: Liste „Frist abgelaufen“; die Geschäftsstelle setzt **verfallen** [ANNAHME: manuell, kein automatischer Wechsel]. Verfallene Abrechnungen werden nicht ausgezahlt; die Sperre bleibt [ANNAHME].

**B5 – Überweisungsdatei erzeugen**
- Geschäftsstelle wählt abgegebene Abrechnungen (Standard: alle abgegebenen, noch nicht ausgezahlten) und das Ausführungsdatum.
- Ausgeschlossen mit Hinweis: ohne Bankverbindung, ohne Bestätigung steuerfreie Einnahmen für das Jahr (R12, R13), Betrag 0.
- Das System erzeugt die SEPA-Datei (Download) und setzt die enthaltenen Abrechnungen auf **ausgezahlt** (in Datei übernommen am, Ausführungsdatum) (R20). Die Geschäftsstelle lädt die Datei im Online-Banking hoch (außerhalb des Vereins OS).
- [OFFEN] Rücknahme, wenn die Bank die Datei ablehnt (Vorschlag: Überweisungsdatei stornieren → Abrechnungen wieder „abgegeben“).

**B6 – Abgleich Punktekonto Kletterhalle**
- Geschäftsstelle wählt Ort (nur Orte mit Kennzeichen „Punktekonto Kletterhalle“) und Zeitraum der Rechnung.
- Das System zeigt je Training: Datum, Gruppe, Anzahl anwesender Teilnehmer:innen, Anzahl Probetrainings, Summe (aus `ez_climbing_points_report`).
- Geschäftsstelle gibt die Anzahl bzw. Punkte laut Rechnung und die Rechnungsnummer ein; das System zeigt die Abweichung. Der Abgleich wird gespeichert (Datum, Ort, Zeitraum, Werte, Bemerkung) [ANNAHME]. Keine Namen.
- [OFFEN] Zählen Probetrainings für die Halle mit? (Kontrollliste zeigt sie getrennt, spec.md EZ.)

**B7 – Iteration 1 (Stichpunkte, Erhebung folgt)**
- Einzelabrechnung je Einsatz (Kurs, Tour, vergütete Einsätze anderer Referate) mit Lehreinheiten, Tagen, Organisationspauschale von Hand; Vorbelegung aus der Planungshilfe (`tk_settlement_draft`); Gemeinschaftstour nur Organisationspauschale.
- Reisekosten und Kostenerstattung nach Reisekostenordnung; Kosten bei Absage von Hand.
- Liste „durchgeführt, noch nicht abgerechnet, älter als 4 Wochen“.

**Zustände der Abrechnung**

| Von | Nach | Wer | Bedingung |
|---|---|---|---|
| – | Entwurf | Geschäftsstelle | Berechnung (B1) |
| Entwurf | Entwurf | Geschäftsstelle | neu berechnen, korrigieren |
| Entwurf | freigegeben | Geschäftsstelle | Betrag > 0 [ANNAHME]; Sperre der Anwesenheiten |
| freigegeben | Entwurf | Geschäftsstelle | Rücknahme vor der Abgabe; Sperre aufgehoben |
| freigegeben | abgegeben | Geschäftsstelle | Abgabedatum eingetragen |
| freigegeben | verfallen | Geschäftsstelle | Frist abgelaufen ohne Abgabe |
| abgegeben | ausgezahlt | System | in Überweisungsdatei übernommen |
| Entwurf | – (gelöscht) | Geschäftsstelle | Entwurf verwerfen [ANNAHME] |

## C. Daten (Feld | Typ | Pflicht | Beispiel | Quelle)

Tabellen mit Präfix `fi_` (Namen [ANNAHME], Festlegung in der Spec).

**C1 – Abrechnung (`fi_settlements`)**

| Feld | Typ | Pflicht | Beispiel | Quelle |
|---|---|---|---|---|
| Person | Verweis Person | ja | Trainerin A | Anwesenheitserfassung |
| Abrechnungshalbjahr | Jahr + Halbjahr | ja | 2026 / 2 | Auswahl |
| Zustand | Auswahl (Entwurf, freigegeben, abgegeben, verfallen, ausgezahlt) | ja | freigegeben | System |
| Betrag | Zahl (€) | ja | 312,00 | berechnet |
| freigegeben am / von | Zeitpunkt / Nutzer | nein | 01.12.2026 | System |
| abgegeben am | Datum | nein | 10.12.2026 | Geschäftsstelle |
| verfallen am / von | Datum / Nutzer | nein | – | Geschäftsstelle |
| Überweisungsdatei | Verweis | nein | – | System |
| Hinweise | berechnet, nicht gespeichert [ANNAHME] | – | „keine Bestätigung 2026“ | R11–R14 |

**C2 – Position (`fi_settlement_items`)**

| Feld | Typ | Pflicht | Beispiel | Quelle |
|---|---|---|---|---|
| Abrechnung | Verweis | ja | – | System |
| Einsatz / Anwesenheit | Verweis | ja | Training Gruppe X, 14.10.2026 | Anwesenheitserfassung |
| Abrechnungsart, Position | Verweis | ja | Trainingseinheiten / Trainingseinheit | Einsatz, Administration |
| Rolle (erfasst) | Trainer:in, Helfer:in | ja | Trainer:in | Anwesenheitserfassung |
| Satzart (abgerechnet) | Trainer:in, Helfer:in, ohne Rolle | ja | Helfer:in (keine förderfähige Lizenz) | R8 |
| Menge | Zahl | ja | 3 (TE) | R3–R7 |
| Satz | Zahl (€) | ja | 6,00 | `ad_rates_at` am Einsatzdatum |
| Betrag | Zahl (€) | ja | 18,00 | Menge × Satz |
| Korrektur: Satzart, Menge, Begründung | Auswahl, Zahl, Text 1–500 | nein (Begründung Pflicht bei Korrektur) | „Ausnahme Lizenz, Begründung Referentin K&J vom 20.11.“ | R16 |
| Hinweis-Kennzeichen | ohne Uhrzeit, ohne Trainingszeit | nein | ohne Uhrzeit | R5, R4 |

Organisationspauschale als eigene Position der organisierenden Person (Menge = Tage).

**C3 – Überweisungsdatei (`fi_payment_files`)**

| Feld | Typ | Pflicht | Beispiel | Quelle |
|---|---|---|---|---|
| erzeugt am / von | Zeitpunkt / Nutzer | ja | 18.12.2026 | System |
| Ausführungsdatum | Datum | ja | 20.12.2026 | Geschäftsstelle |
| Anzahl, Summe | Zahl | ja | 87 / 21.450,00 € | System |
| Verwendungszweck | Text | ja | „Übungsleiterpauschale 2. Hj. 2026“ [ANNAHME] | System |

Die Datei selbst und die IBANs werden nicht gespeichert (R21) [ANNAHME].

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
- Aus der Administration: Sätze (`ad_rates_at`), Abrechnungsarten und Vorbelegung (A1, A2), Höchstbetrag (A4), Fristen (A5), Kennzeichen am Referat (A6), Auftraggeberkonto (A10).
- Aus dem Ehrenamtsmanagement (über A8): Kontoinhaber:in, IBAN; Trainervereinbarung (Datum); Bestätigung steuerfreie Einnahmen (Jahr, Abgabedatum); förderfähige Lizenzen (gültig von, gültig bis).
- Aus der Anwesenheitserfassung (über Z2): Einsatz, Anwesenheit, Dauer der Trainingszeit.

## D. Regeln (R1, R2 …)

- **R1 – Grundlage:** Abgerechnet werden nur Anwesenheiten mit Stand „anwesend“ und Rolle Trainer:in oder Helfer:in an nicht abgesagten Einsätzen mit Abrechnungsart (≠ „keine Vergütung“). Teilnehmer:innen nie (F1, F2).
- **R2 – Halbjahr:** Ein Einsatz gehört zum Halbjahr seines Datums bzw. Startdatums, auch wenn er über die Halbjahresgrenze reicht [ANNAHME]. Im MVP nur Referate mit Kennzeichen „halbjährliche Abrechnung“.
- **R3 – Trainingseinheiten:** Menge = Dauer der Trainingszeit der Gruppe am Wochentag in Minuten / 30, **aufgerundet** (Product Owner 24.10.2026). Beispiel: 17:00–18:15 = 3 TE.
- **R4 – Training ohne Trainingszeit:** [OFFEN] Vorschlag: Menge 0 mit Hinweis „ohne Trainingszeit“; Geschäftsstelle korrigiert die Menge mit Begründung.
- **R5 – Tages- und Halbtagessätze:** eintägig nach Dauer-Kategorie (unter 8 Stunden = Halbtagessatz, mindestens 8 Stunden = Tagessatz). Mehrtägig: erster Tag Beginn bis 24:00, letzter Tag 0:00 bis Ende, Zwischentage Tagessatz; je Tag unter 8 Stunden = Halbtagessatz [ANNAHME: Berechnungsweise, F4]. Fehlt Beginn bzw. Ende, zählt der erste bzw. letzte Tag als Tagessatz mit Hinweis „ohne Uhrzeit“ (Product Owner 24.10.2026).
- **R6 – Wettkampfbetreuung:** Satz je Kalendertag von Startdatum bis Enddatum, unabhängig von Stunden (Product Owner 24.10.2026).
- **R7 – Organisationspauschale:** je Tag des Einsatzes für die organisierende Person, wenn die Abrechnungsart die Position vorsieht; zusätzlich zu ihrem Tagessatz, wenn sie auch als Trainer:in oder Helfer:in anwesend ist [ANNAHME]. Halbtage zählen als Tag [ANNAHME].
- **R8 – Satzart Trainer:in:** Rolle Trainer:in wird mit Satz Trainer:in abgerechnet, wenn am Datum (mehrtägig: Startdatum, gilt dann für den ganzen Einsatz) eine förderfähige Lizenz gültig ist oder eine förderfähige Lizenz im selben Abrechnungshalbjahr erworben wurde (gültig von im Halbjahr) (Product Owner 24.10.2026). Sonst Satz Helfer:in mit Hinweis „keine förderfähige Lizenz“ [ANNAHME, F5]. Förderfähig = DOSB-lizenzfähig [ANNAHME, AD v0.9].
- **R9 – Satzstand:** Satz aus `ad_rates_at` am Datum bzw. Startdatum des Einsatzes [ANNAHME]. Fehlt ein Satz, wird die Position mit Hinweis „Satz fehlt“ ohne Betrag angelegt und die Abrechnung kann nicht freigegeben werden [ANNAHME].
- **R10 – Eine Person, ein Einsatz:** je Einsatz und Person höchstens eine Position je Position der Abrechnungsart (z. B. Tagessatz und Organisationspauschale); bei Wettkampfbetreuung mit mehreren Gruppen nur einmal.
- **R11 – Steuerfreier Höchstbetrag:** Liegt die Summe aller freigegebenen, abgegebenen und ausgezahlten Abrechnungen der Person im Kalenderjahr zuzüglich dieser Abrechnung über dem Höchstbetrag, Hinweis „Höchstbetrag überschritten“; keine Sperre [ANNAHME, F6]. [OFFEN] Jahr des Einsatzes oder der Auszahlung.
- **R12 – Bestätigung steuerfreie Einnahmen:** Ohne Bestätigung mit „für Jahr“ = Jahr der Abrechnung (bzw. ohne Jahr, abgegeben vor der Auszahlung [ANNAHME]) Hinweis; die Abrechnung kann freigegeben, aber nicht in die Überweisungsdatei übernommen werden (F6).
- **R13 – Bankverbindung:** Ohne Bankverbindung Hinweis; nicht in die Überweisungsdatei.
- **R14 – Trainervereinbarung:** [OFFEN] Voraussetzung der Auszahlung oder nur Hinweis.
- **R15 – Neu berechnen:** nur Entwürfe; freigegebene und spätere Zustände bleiben unverändert.
- **R16 – Korrektur:** Jede Abweichung vom berechneten Wert braucht eine Begründung (1–500 Zeichen), sonst Fehlermeldung „Bitte eine Begründung angeben.“; berechneter und korrigierter Wert bleiben sichtbar.
- **R17 – Sperre:** Ab der Freigabe sind die abgerechneten Anwesenheiten und die abrechnungsrelevanten Kopfdaten des Einsatzes in der Anwesenheitserfassung gesperrt (Product Owner 24.10.2026; Übergabe FI → EZ, Z3). Rücknahme der Freigabe hebt die Sperre auf.
- **R18 – Abrechnungsdokument:** enthält Person (Name, ohne Bankdaten [ANNAHME]), Halbjahr, Positionen mit Datum, Einsatz, Menge, Satz, Betrag, Korrekturen mit Begründung, Summe, Abgabefrist, Hinweis auf das Erlöschen des Anspruchs, Unterschriftsfeld. Inhalt und Wortlaut mit dem heutigen Dokument abgleichen [OFFEN: Vorlage liefert die Geschäftsstelle].
- **R19 – Frist:** Abgabefrist aus den Stammdaten der Administration (Start: 31.07. für das 1., 15.12. für das 2. Halbjahr). Abgabe nach der Frist: Rückfrage „Die Frist ist abgelaufen. Der Anspruch ist erloschen. Trotzdem als abgegeben erfassen?“ [ANNAHME: Ausnahme möglich mit Begründung].
- **R20 – Auszahlung:** Eine Abrechnung ist höchstens in einer Überweisungsdatei; danach nicht mehr änderbar.
- **R21 – Datensparsamkeit:** IBANs werden nur beim Erzeugen der Datei gelesen und nicht in Finanzen gespeichert [ANNAHME].
- **R22 – Aufbewahrung:** Abrechnungen, Positionen, Überweisungsdateien und Abgleiche werden 5 Jahre nach Ende des Kalenderjahres der Auszahlung bzw. des Verfalls gelöscht [ANNAHME: Beginn der Frist] (Q4, Product Owner 24.10.2026: 5 Jahre wie überall).

## E. Schnittstellen

| Schnittstelle | Richtung | Inhalt |
|---|---|---|
| Administration | AD → FI | `ad_has_level('FI', …)`, `ad_modules` (FI), `ad_rates_at`, Abrechnungsarten und Vorbelegung, Fristen, Kennzeichen am Referat, Lesefunktion Personendaten, `ea_person_names` (Übergabe FI → AD v1.0, A1–A10) |
| Anwesenheitserfassung | EZ → FI | Lesefunktion Abrechnungsgrundlage mit FI-Rechten, `ez_climbing_points_report` mit FI-Rechten (Z2) |
| Anwesenheitserfassung | FI → EZ | Sperre über `fi_attendance_locked` (Platzhalter in EZ, ersetzt von FI) (Z3); Abrechnungsart am Einsatz (Z1) |
| Planungshilfe Touren und Kurse | TK → FI | `tk_settlement_draft` (Iteration 1); Übergabe FI → TK v1.0 |
| Sparkasse | FI → extern | SEPA-Überweisungsdatei, manueller Upload; [OFFEN] Format/Version, Auftraggeberkonto |
| Finanzbuchhaltung | FI → extern | unterschriebene Abrechnungsdokumente (Papier) als Beleg; kein DATEV-Export im MVP |
| Kletterhalle | extern → FI | Rechnung, manuelle Eingabe der Werte |

## F. Datenschutz

- Zweck: Vergütung nach der Vergütungsordnung und Kontrolle der Rechnungen der Kletterhalle. Eintrag im Verarbeitungsverzeichnis (Trainerabrechnung, Bankverbindung).
- Zugriff im MVP nur Geschäftsstelle (FI verwalten). Bankverbindung und Nachweise nur über die Lesefunktion mit festen Spalten (A8); keine Lizenznummern, keine weiteren Eigenschaften.
- Keine Daten von Teilnehmer:innen außer Anzahlen (Abgleich Punktekonto).
- SEPA-Datei nur als Download, nicht gespeichert; IBANs nicht in Finanzen gespeichert (R21).
- Abrechnungsdokument ohne Bankdaten [ANNAHME].
- Aufbewahrung 5 Jahre (R22); Belege in der Finanzbuchhaltung [ANNAHME, Steckbrief].
- Freitexte (Begründung, Bemerkung) mit Hinweis, keine sensiblen Angaben einzutragen.

## G. Nicht-funktional

- Mengengerüst [ANNAHME]: ca. 130 Trainer:innen und Helfer:innen je Halbjahr; ca. 30 Gruppen; ca. 1.500 Trainings und 4.000 abrechenbare Anwesenheiten je Halbjahr.
- Berechnung eines Halbjahres unter 10 Sekunden; Liste der Abrechnungen unter 2 Sekunden [ANNAHME].
- Berechnung in der Datenbank (nachvollziehbar, mit pgTAP-Tests je Regel R3–R11).
- Bedienung vor allem am Arbeitsplatz; Listen mobil lesbar ab 375 px; Abrechnungsdokument als PDF A4.
- Keine laufenden Kosten; keine externe Bankschnittstelle.

## Offene Fragen (Frage | Wer klärt | bis wann)

| Frage | Wer klärt | bis wann |
|---|---|---|
| Startwerte der Vorbelegung je Einsatzart, v. a. eintägige Ausbildungsfahrt | Product Owner | vor der Spec |
| Training ohne Trainingszeit (R4) | Product Owner | vor den Stories |
| Höchstbetrag: Jahr des Einsatzes oder der Auszahlung; aktueller Betrag (R11, A4) | Schatzmeister:in | vor der Spec |
| Trainervereinbarung als Voraussetzung (R14) | Product Owner | vor den Stories |
| SEPA: Format/Version, Auftraggeberkonto, Verwendungszweck, Sammelbuchung; Rücknahme bei Ablehnung | Geschäftsstelle mit Sparkasse | vor der Spec |
| Vier-Augen-Prinzip bei Freigabe oder Auszahlung | Product Owner mit Vorstand | vor dem Rollout an weitere Nutzer |
| Vorlage des heutigen Abrechnungsdokuments (R18) | Geschäftsstelle | vor den Stories |
| Zählen Probetrainings für die Kletterhalle (B6)? | Geschäftsstelle | vor den Stories |
| Bestätigung der Annahme Q4 (Belege in der Finanzbuchhaltung) | Schatzmeister:in | vor der Spec |
| Steuerliche Einordnung einer Vergütung bei Arbeitseinsätzen | Schatzmeister:in | vor Iteration 1 |
| Wer wählt die Abrechnungsart eines Einsatzes (Übergabe FI → EZ) | Product Owner | mit dem Nachtrag EZ |
| Befragung Geschäftsstelle zum heutigen Ablauf (Aufwand, Sonderfälle) | Product Owner | vor den Stories |
