# Ideenkatalog: Sichten und Kennzahlen des Dashboards

Stand: 26.10.2026 · Version 0.3 · Status: Entwurf zur Auswahl durch den Product Owner und die Referate
Änderungen v0.3: Q-DS9 (Vorjahresvergleich für Budget und Kennzahlen) eingearbeitet: B7 als Must; alle Kennzahlen mit Vorjahreswert.
Änderungen v0.2: Entscheidungen Q-DS1 (Referat sieht Einzelbuchungen), Q-DS2 (Budget in FI) und Q-DS3 (Auslastung ohne Platzzahl) eingearbeitet.
Grundlage: Steckbriefe, Specs und Merkposten der Module AD, EA, GR, EZ, TK, FI (Stand 26.10.2026); 00-steckbrief.md DS v0.1.

Alle Ideen sind Vorschläge [ANNAHME]. Spalte **ab** = frühester Zeitpunkt, zu dem die Daten im Vereins OS vorliegen (Modul und Iteration). Spalte **Datenschutz** nennt, was beachtet werden muss. Grundsatz: Das Dashboard zeigt Anzahlen, Summen und Quoten; Personenlisten bleiben im Fachmodul. Jede Kennzahl zeigt den Wert des gleichen Zeitraums im Vorjahr daneben (Q-DS9, Product Owner 26.10.2026), sobald Daten für das Vorjahr vorliegen.

Kürzel der Priorität für die Rückmeldung: **M** = Must (MVP), **S** = Should (Iteration 1), **C** = Could (später), **W** = Won't.

---

## 1. Budget (Grundlage: Prototyp Budget-Dashboard)

| Nr | Kennzahl | Sicht | Quelle | ab | Datenschutz |
|---|---|---|---|---|---|
| B1 | Plan / verbraucht / frei / Verbrauch in % je Budgetposten und Gesamtbudget, Ampel, Zeitmarke | Vorstand (alle), Referat (eigene Gesamtbudgets) | DATEV-Export + Finanzplan | DS-MVP | Summen unkritisch |
| B2 | Einnahmen Plan / erreicht / fehlt noch | Vorstand, Referat | DATEV-Export | DS-MVP | – |
| B3 | Verbrauch im Verhältnis zum abgelaufenen Jahr („schneller als geplant“) als Hinweis | Referat | B1 | DS-MVP | – |
| B4 | Einzelbuchungen je Budgetposten | Geschäftsstelle, Vorstand, Referat (eigene Budgetposten; Q-DS1 entschieden) | DATEV-Export (FI) | DS-MVP | Buchungstexte enthalten Namen; Einzelbuchungen laufendes Jahr + Vorjahr (Q-DS11) |
| B5 | Nicht zugeordnete Buchungen, Prüfung des Exports | Geschäftsstelle, Vorstand | DATEV-Export | DS-MVP | – |
| B6 | Monatsverlauf je Gesamtbudget (kumuliert gegen Plan-Linie) | Vorstand, Referat | DATEV-Export | DS-MVP oder S | – |
| B7 | Vergleich mit dem Vorjahr (gleicher Stichtag und ganzes Vorjahr) je Gesamtbudget und Budgetposten (Q-DS9, entschieden) | Vorstand, Referat | Summen je Budgetposten und Monat (FI) | DS-MVP | Summen je Monat bleiben, Einzelbuchungen nur Vorjahr (Q-DS11) |
| B8 | „Gebunden“: abgerechnete und freigegebene, noch nicht gebuchte Vergütung am Budgetposten „Vergütung Aktive“ | Referat Kinder und Jugend, Leistungssport; Vorstand | FI (Auszahlungsrunden) | FI-MVP | nur Summen |
| B9 | Planwerte der Touren und Kurse (Kosten, Beiträge) gegen das Budget Touren/Ausbildung | Referat Touren, Ausbildung | TK (Kalkulation) | TK-MVP | – |
| B10 | Einnahmen aus Verträgen (monatlicher Einzug) gegen Plan | Vorstand, Kinder und Jugend | GR (Verträge), später FI-Buchungslauf | später | nur Summen |
| B11 | Sphären (ideell, Zweckbetrieb, wGB) als Filter bzw. Summe | Vorstand, Schatzmeister:in | KOST1 | DS-MVP | – |

## 2. Referat Kinder und Jugend (gleiche Sicht für Leistungssport und Klettergruppen)

| Nr | Kennzahl | Quelle | ab | Datenschutz |
|---|---|---|---|---|
| K1 | **Auslastung je Gruppe** (Q-DS3 entschieden): Anwesenheitsquote = Ø anwesende Teilnehmer:innen je Training / Teilnehmer:innen zum Datum; zusammen mit K5 (Probetrainings) und K6 (Betreuungsschlüssel). Darstellung je Gruppe als Balken; Grenzwerte für Hinweise [OFFEN] | GR, EZ | EZ-MVP + GR | nur Anzahlen |
| K2 | Teilnehmer:innen je Gruppe zum Stichtag, Eintritte und Teilnahmeenden je Halbjahr | GR | GR-MVP | nur Anzahlen |
| K3 | Anzahl Trainings je Gruppe und Halbjahr; Anzahl Trainings gegen Trainingszeiten (wie viele mögliche Termine wurden erfasst) | EZ, GR (Trainingszeiten) | EZ-MVP | – |
| K4 | Abgesagte Einsätze je Gruppe mit Grund (Anzahl) | EZ | EZ-MVP | – |
| K5 | Probetrainings je Gruppe und Monat (Nachfrage-Indikator, solange es keine Warteliste gibt) | EZ (Freitext, nur Anzahl) | EZ-MVP | nur Anzahl, kein Vorname |
| K6 | Trainings unterhalb des Betreuungsschlüssels (Anzahl, je Gruppe) | EZ, GR (Alter intern) | EZ Iteration 2 | Alter nie anzeigen; nur Ergebnis |
| K7 | Betreuung je Gruppe: Anzahl Trainer:innen mit gültiger förderfähiger Lizenz, Helfer:innen; Lizenz läuft in den nächsten 6 Monaten ab (Anzahl) | GR (Funktionen), EA (Qualifikationen) | EA-MVP + GR | Anzahl; Namen im Fachmodul |
| K8 | „Teilnahme klären“ (Vertrag beendet, Teilnahme läuft), fehlender Notfallkontakt, fehlende Fotoerlaubnis (Anzahl je Gruppe) | GR | GR-MVP | Anzahl; Namen im Fachmodul |
| K9 | Fahrten: Anzahl Tagesausflüge, Mehrtagesfahrten, Ausbildungsfahrten, Trainingslager und Teilnehmende je Halbjahr | EZ | EZ-MVP | – |
| K10 | Stand der halbjährlichen Abrechnung: Abrechnungen erstellt / bestätigt / abgeschlossen / abgegeben / ausgezahlt; Tage bis zur Frist (31.07., 15.12.) | FI | FI-MVP | nur Anzahlen |
| K11 | Vergütung je Gruppe und Halbjahr (Summe) | FI | FI-MVP | nur Summen je Gruppe |
| K12 | Kletterhalle Punktekonto: Besuche der Kinder je Ort und Monat | EZ | EZ-MVP | – |
| K13 | Einsatzstunden der Aktiven je Gruppe (Trainingseinheiten, Tage) | EZ, FI | EZ-MVP | Summe, keine Rangliste |
| K14 | Altersstruktur je Gruppe (Altersklassen) | GR | GR-MVP | [OFFEN] nur ab Mindestgröße; nur für GR-Berechtigte |

## 3. Referat Leistungssport (zusätzlich zu 2.)

| Nr | Kennzahl | Quelle | ab |
|---|---|---|---|
| L1 | Wettkampfbetreuungen je Halbjahr (Anzahl, Tage) | EZ | EZ-MVP |
| L2 | Trainingslager (Anzahl, Tage, Teilnehmende) | EZ | EZ-MVP |
| L3 | Startgebühren und Reisekosten gegen Budget (Budgetposten) | DATEV-Export | DS-MVP |

## 4. Referate Touren und Ausbildung

| Nr | Kennzahl | Quelle | ab | Datenschutz |
|---|---|---|---|---|
| T1 | Planungen je Status (Entwurf … abgeschlossen) als „Pipeline“, Dauer von „eingereicht“ bis „freigegeben“ | TK | TK-MVP | – |
| T2 | Kostendeckung je Tourtyp und Jahr (Ergebnis bei Mindest- und Höchstzahl) | TK | TK-MVP | – |
| T3 | Absagequote der Touren und Kurse | TK, EZ | TK-MVP | – |
| T4 | Durchgeführt, noch nicht abgerechnet, älter als 4 Wochen (Anzahl) | TK, FI | FI Iteration 1 | – |
| T5 | CO2 je Jahr, Referat, Verkehrsmittel; Klimaschutzbudget | TK | TK Iteration 1 | – |
| T6 | Aktive Tourenleitende und Kursleitende mit gültiger Lizenz, Ablauf in den nächsten 6 Monaten | EA | EA-MVP | Anzahl |
| T7 | Auslastung der Kurse und Touren (Anmeldungen / Höchstzahl) | Yolawo – nicht im Vereins OS | [OFFEN] Teilnehmerzahl bei „durchgeführt“ eintragen? | – |

## 5. Referat Klettern, Hütten (Karl-Stein-Hütte, Sulzenauhütte)

| Nr | Kennzahl | Quelle | ab |
|---|---|---|---|
| H1 | Budget der Hütte bzw. des Referats (B1) | DATEV-Export | DS-MVP |
| H2 | Arbeitseinsätze an der Hütte bzw. im Referat: Anzahl, Personen, Stunden | EZ | EZ-MVP |
| H3 | Aktive des Referats nach Ehrenamtsstatus | EA | EA-MVP |
| H4 | Belegung der Hütte | nicht im Vereins OS | W [ANNAHME] |

## 6. Vorstand (Gesamtsicht)

| Nr | Kennzahl | Quelle | ab |
|---|---|---|---|
| V1 | Budget aller Gesamtbudgets (B1, B2) mit Ampel; Druck für die Vorstandssitzung | DATEV-Export | DS-MVP |
| V2 | Aktive je Referat und Ehrenamtsstatus; Neuzugänge und Ausgeschiedene im Jahr | EA | EA-MVP |
| V3 | Teilnehmer:innen in Gruppen gesamt und je Referat, Entwicklung über die Halbjahre | GR | GR-MVP |
| V4 | Einsätze und Einsatzstunden des Ehrenamts je Referat (für Jahresbericht und Mitgliederversammlung) | EZ | EZ-MVP |
| V5 | Ausgezahlte Vergütung je Referat und Jahr; Anzahl Personen am steuerfreien Höchstbetrag | FI | FI-MVP |
| V6 | Kennzahlen für den Jahresbericht als PDF oder Tabelle (eine Seite je Referat) | alle | C |
| V7 | Kennzahlen für Förderanträge (z. B. Anzahl lizenzierter Trainer:innen, Trainingsstunden, Teilnehmende nach Altersklassen) [OFFEN: welche Förderer, welche Zahlen] | EA, EZ, GR | C |

## 7. Geschäftsstelle (Arbeitsvorrat statt Kennzahl)

| Nr | Kennzahl | Quelle | ab | Hinweis |
|---|---|---|---|---|
| G1 | Zu erledigen: Abrechnungen zu prüfen, Auszahlungsrunde bereit, Hinweise (fehlende Bankverbindung, Trainervereinbarung, Bestätigung steuerfreie Einnahmen) | FI | FI-MVP | Abgrenzung zu GS/AM (Aufgaben) [OFFEN] |
| G2 | Qualifikationen, die in den nächsten 3 Monaten ablaufen | EA | EA-MVP | – |
| G3 | „Teilnahme klären“ und Teilnehmer:innen ohne Erziehungsberechtigte | GR | GR-MVP | – |
| G4 | Einsätze ohne Anwesenheit (angelegt, aber nicht erfasst) | EZ | EZ-MVP | – |
| G5 | Planungen „in Yolawo angelegt“, aber Termin vorbei und nicht „durchgeführt“ | TK | TK-MVP | – |
| G6 | Datenstand des Budgets älter als 6 Wochen → Hinweis „neuen Export einspielen“ (Export monatlich, Q-DS7) | DS | DS-MVP | Hinweis an den 1. Vorsitzenden bzw. die Schatzmeister:in |

## 8. Admin

| Nr | Kennzahl | Quelle | ab |
|---|---|---|---|
| A1 | Zugänge nach Status (eingeladen, aktiv, gesperrt), Einladungen älter als 14 Tage | AD | AD-MVP |
| A2 | Anmeldungen des Notfall-Admins | AD | AD-MVP |

---

## Fragen an die Referate (Vorschlag für die Erhebung)

1. Welche drei Zahlen schaust du heute am häufigsten nach – und wo?
2. Welche Entscheidung würdest du mit einer Kennzahl anders oder früher treffen (z. B. Gruppe zusammenlegen, Trainer:in suchen, Budget umschichten)?
3. Wie oft brauchst du die Zahlen (laufend, vor der Referatssitzung, halbjährlich, für den Jahresbericht)?
4. Wer außer dir soll die Sicht des Referats sehen (Stellvertretung, Gruppenleitungen, Jugendausschuss)?
