# Sichten des Dashboards

Stand: 26.10.2026 · Version 0.4 · Status: Entwurf
Änderungen v0.4: Schmale Spalten im Baustein Gruppen (Product Owner 26.10.2026): Spaltenköpfe TN, Anwesenheit, PT; kurze Werte; Legende unter der Liste.
Änderungen v0.3: Herkunft von Gruppenname und Trainingszeit (Modul Gruppen) und Link je Recht festgelegt; Lücke: Referent:innen haben kein Recht auf Gruppen [OFFEN].
Änderungen v0.2: Baustein Gruppen für Referate mit vielen Gruppen (Kinder und Jugend hat über 14; Product Owner 26.10.2026): Status je Gruppe, Sortierung, Filter „Mit Hinweis“ / „Alle“, Zählleiste; Ampel für abgesagte Trainings. Skizze: Artifact „Dashboard Kinder und Jugend“.
Grundlage: 00-steckbrief.md DS v0.10, ideen-sichten.md v0.4 (Ideenkatalog), Entscheidungen Q-DS1 bis Q-DS19.

**Auftrag des Product Owners (26.10.2026):** Die Referate geben keine Rückmeldung. Claude legt die Inhalte fest, als wäre es selbst Referent:in. Alle Festlegungen in dieser Datei sind deshalb **Vorschläge zur Abnahme durch den Product Owner** und als **[FESTLEGUNG]** gekennzeichnet. Schwellenwerte sind [ANNAHME] und sollen nach dem ersten Halbjahr im Betrieb überprüft werden.

---

## 1. Leitfragen einer Referent:in

Als Referent:in öffne ich das Dashboard vor der Referatssitzung, vor der Vorstandssitzung und wenn eine Frist näher rückt. Ich will in einer Minute wissen:

1. **Muss ich etwas tun?** (bestätigen, freigeben, nachfassen)
2. **Reicht mein Geld?** (verbraucht im Verhältnis zum Jahresfortschritt, was kommt noch)
3. **Läuft mein Referat?** (finden die Angebote statt, kommen die Leute, ist genug Betreuung da)
4. **Wie steht der Verein?** (Budget gesamt, damit ich Umschichtungen und Anträge einordnen kann)

Daraus folgt die Reihenfolge jeder Sicht.

## 2. Aufbau jeder Sicht [FESTLEGUNG]

| Block | Inhalt | Regel |
|---|---|---|
| ① **Zu tun** | Anzahl offener Aufgaben aus allen Modulen, jede mit Link ins Fachmodul | erscheint nur, wenn etwas offen ist; sonst eine Zeile „Nichts zu tun.“ |
| ② **Budget meines Referats** | Gesamtbudget(s) des Referats: Plan (aktuell), verbraucht, frei, Ampel, Strich für den Jahresfortschritt, Vorjahr zum gleichen Stichtag, Datenstand | aufklappbar je Budgetposten mit Einzelbuchungen, Hinweisen, Umschichtungen |
| ③ **Mein Referat in Zahlen** | Fachkennzahlen des Referats (Abschnitt 4), immer mit Vorjahreswert | je Referat unterschiedlich; nur Blöcke, für die Daten vorliegen |
| ④ **Budget des Vereins** | alle Gesamtbudgets als Summen mit Ampel, eigenes Referat hervorgehoben | zugeklappt; Klick öffnet die Budgetposten (ohne Einzelbuchungen fremder Referate) |

Regeln für alle Blöcke:
- **Höchstens 6 Kennzahlen je Block** sichtbar; der Rest hinter „mehr“.
- **Vorjahr** als kleine Zahl mit Pfeil (▲ ▼), nie als eigene Spalte; ohne Vorjahreswert „neu“.
- **Ampel** einheitlich mit Form und Farbe (● grün, ▲ gelb, ■ rot) wie im Prototyp; jede Ampel nennt ihre Regel im Tooltip.
- **Jede Zahl ist ein Link** ins Fachmodul (dort gelten dessen Rechte); im Dashboard selbst keine Namen außer bei Einzelbuchungen.
- **Datenstand** steht an jedem Block, der aus einem Import kommt (Budget); Kennzahlen aus den Modulen sind tagesaktuell.
- Mobil ab 375 px: Blöcke untereinander, Tabellen werden zu Karten je Gruppe bzw. Posten.
- Sichtwahl oben: „Mein Referat“ (Standard) und bei mehreren Referaten ein Umschalter; Vorstand, Admin und Geschäftsstelle wählen jedes Referat oder „Verein“.

## 3. Block ① „Zu tun“ – Quellen [FESTLEGUNG]

| Nr | Aufgabe | Für wen | Quelle | ab |
|---|---|---|---|---|
| Z1 | Abrechnungen meines Referats warten auf Bestätigung (Anzahl, Tage bis Frist 31.07./15.12.) | Referent:in mit „freigeben“ | FI | FI-MVP |
| Z2 | Planungen warten auf Freigabe; Rückfragen seit mehr als 7 Tagen offen | Referent:in Touren, Ausbildung | TK | TK-MVP |
| Z3 | Lizenzen von Trainer:innen bzw. Leitenden meines Referats laufen in den nächsten 90 Tagen ab | Referent:in | EA | EA-MVP |
| Z4 | Meine Umschichtungen und Umschlüsselungs-Vorschläge: beantragt, abgelehnt (mit Grund) | Referent:in | FI-Budget | DS-MVP |
| Z5 | Gruppen ohne Trainer:in mit gültiger förderfähiger Lizenz | Referent:in mit Gruppen | GR, EA | GR + EA |
| Z6 | Teilnahmen „klären“ und Teilnehmer:innen ohne Notfallkontakt (Anzahl je Gruppe) | Referent:in mit Gruppen | GR | GR-MVP |
| Z7 | Durchgeführte Touren/Kurse, älter als 4 Wochen, nicht abgerechnet | Referent:in Touren, Ausbildung | TK, FI | FI Iteration 1 |
| Z8 | Offene Anträge (Umschichtung, Umschlüsselung), nicht zugeordnete Buchungen, Datenstand älter als 6 Wochen, unsichere Zuordnungen | Budgetpflege | FI-Budget | DS-MVP |
| Z9 | Abrechnungen zu prüfen, Auszahlungsrunde bereit, fehlende Nachweise und Bankverbindungen | Geschäftsstelle | FI, EA | FI-MVP |

Z5 und Z6 sind Anzahlen; die Namen sieht die Referent:in nur im Modul Gruppen bzw. Ehrenamtsmanagement mit dessen Rechten.

## 4. Block ③ je Referat [FESTLEGUNG]

### 4.1 Gemeinsamer Baustein „Gruppen“ (jedes Referat mit Gruppen: Kinder und Jugend, Leistungssport, Klettern)

Eine Zeile je Gruppe (mobil: eine Karte), Zeitraum: laufendes Halbjahr, Vergleich: gleiches Halbjahr des Vorjahres.

**Herkunft und Link** [FESTLEGUNG]:
- **Gruppenname** = `gr_groups.name` aus dem Modul Gruppen; **Zeile darunter** = die heute gültigen Trainingszeiten der Gruppe (`gr_training_times`, je Wochentag eine; mehrere durch Komma getrennt, z. B. „Mo 16:30–18:00, Do 16:30–18:00“; keine: „keine Trainingszeit“). Geliefert über eine Lesefunktion von Gruppen mit Recht auf DS (wie `gr_groups_for_attendance`, nur Gruppe, Referat, Name, Trainingszeiten, Anzahlen; keine Personendaten).
- **Link der Gruppe:** mit Recht „Gruppen lesen“ auf die Gruppe im Modul Gruppen (`/gr/gruppen/:id`); sonst mit Recht auf die Anwesenheitserfassung auf die Einsätze der Gruppe; sonst kein Link.
- [OFFEN] Referent:innen haben laut Spec Gruppen keinen Zugriff auf Gruppen (Startwerte: Referent:in und Vorstand ohne Rechte; Reichweite in GR nur „alle“; specs/gr-gruppen/spec.md Abschnitt 3). Damit führen die Punkte „Gruppen ohne Trainer:in mit Lizenz“ und „Teilnahme klären / ohne Notfallkontakt“ (Z5, Z6) für Referent:innen ins Leere: Sie sehen die Anzahl, aber nicht, wen es betrifft. Vorschlag: Reichweite „Referat“ für GR lesen (Nachtrag Gruppen und Administration) oder Z5/Z6 für Referent:innen nur als Hinweis „Geschäftsstelle informiert“.

**Schmale Spalten** (Product Owner 26.10.2026): Spaltenköpfe **Status · Gruppe · TN · Anwesenheit · Trainings · Betreuungsschlüssel · PT · Betreuung**; Abkürzungen mit Langform beim Überfahren (`<abbr title>`) und in der Legende unter der Liste. Kurze Werte: Anwesenheit „71 %“ mit „▲ 1 Pkt.“, Trainings „16“ mit „0 abgesagt“, Betreuungsschlüssel „■ 3× darunter“, Betreuung „1 / 0“ (Trainer:innen mit Lizenz / Helfer:innen); „Nachfrage hoch“ nur in der Statusspalte.

**Viele Gruppen** (Kinder und Jugend hat über 14 Gruppen, Product Owner 26.10.2026) [FESTLEGUNG]:
- **Status je Gruppe** = schlechteste Ampel der Zeile: ■ handeln, ▲ beobachten, ◆ Nachfrage hoch (keine Warnung, aber Hinweis), ● ok.
- **Sortierung** nach Status (■, ▲, ◆, ●), dann nach Name.
- **Filter** „Mit Hinweis (n)“ (Standard) und „Alle (n)“; unter der Liste „n Gruppen ohne Hinweis anzeigen“. So stehen bei 15 Gruppen typischerweise 5–8 Zeilen sichtbar, der Rest ist einen Klick entfernt.
- **Zählleiste** über der Liste: Anzahl Gruppen je Status.
- Die Kennzahlen des ganzen Referats (Gruppen, Teilnehmer:innen, Anwesenheitsquote, Trainings, Probetrainings, Fahrten) stehen darüber und werden aus allen Gruppen berechnet, nicht nur aus den sichtbaren.
- Neue Gruppen (ohne Vorjahr) zeigen „neu“ statt Vergleichswert; ihre Teilnehmer:innen werden im Vorjahresvergleich des Referats getrennt ausgewiesen.

| Spalte | Berechnung | Ampel [ANNAHME] |
|---|---|---|
| Status | schlechteste Ampel der Zeile, „Nachfrage hoch“ als eigener Status | ■ ▲ ◆ ● |
| Teilnehmer:innen | laufende Teilnahmen heute | – |
| Anwesenheitsquote | Ø anwesende Teilnehmer:innen je Training ÷ Teilnehmer:innen zum Datum des Trainings | ▲ unter 50 %, ■ unter 30 % |
| Trainings | stattgefunden / abgesagt | ▲ wenn abgesagt > 20 % der angesetzten |
| Betreuungsschlüssel | Trainings unter dem Mindestverhältnis (Glossar) | ▲ ab 1, ■ ab 3 im Halbjahr |
| Probetrainings | Anzahl der letzten 3 Monate | Hinweis „Nachfrage hoch“, wenn ≥ 3 **und** Anwesenheitsquote ≥ 80 % |
| Betreuung | Trainer:innen mit gültiger förderfähiger Lizenz / Helfer:innen | ■ wenn keine Trainer:in mit Lizenz |

Darüber eine Zeile für das ganze Referat: Gruppen, Teilnehmer:innen gesamt, Anwesenheitsquote gesamt (gewichtet nach Teilnehmer:innen), Trainings gesamt, Probetrainings, jeweils mit Vorjahr.

**Wozu:** Zusammen beantworten die Spalten die Auslastung (Q-DS3): Eine Gruppe mit hoher Quote und vielen Probetrainings ist voll (neue Gruppe oder zweite Trainingszeit prüfen); eine Gruppe mit niedriger Quote und keinen Probetrainings schrumpft (zusammenlegen oder Zeit ändern); ein unterschrittener Betreuungsschlüssel heißt: Helfer:in suchen.

### 4.2 Kinder und Jugend

| Nr | Kennzahl | Entscheidung |
|---|---|---|
| – | Baustein Gruppen (4.1) | M (Iteration 1, sobald EZ und GR laufen) |
| K9 | Fahrten im Halbjahr: Tagesausflüge, Mehrtagesfahrten, Ausbildungsfahrten, Trainingslager; Teilnehmende gesamt | M |
| K10 | Stand der halbjährlichen Abrechnung (erstellt / bestätigt / abgegeben / ausgezahlt), Tage bis zur Frist | M (auch in ①) |
| B8 | Vergütung „gebunden“ am Budgetposten „Vergütung Aktive“: ausgezahlt + abgeschlossen, noch nicht gebucht | M |
| K11 | Vergütung je Gruppe im Halbjahr | S |
| K2 | Eintritte und Teilnahmeenden je Halbjahr | S |
| K13 | Einsatzstunden der Aktiven (Trainingseinheiten, Tage) | S |
| K12 | Punktekonto Kletterhalle | W für die Referent:in (Aufgabe der Geschäftsstelle, dort G-Sicht) |
| K14 | Altersstruktur je Gruppe | **W** – bei kleinen Gruppen rückschließbar auf einzelne Kinder (Datenschutz Minderjährige); der Betreuungsschlüssel nutzt das Alter bereits intern |

### 4.3 Leistungssport

Wie 4.2, zusätzlich:

| Nr | Kennzahl | Entscheidung |
|---|---|---|
| L1 | Wettkampfbetreuungen im Halbjahr (Anzahl, Tage) mit Vorjahr | M |
| L2 | Trainingslager (Anzahl, Tage, Teilnehmende) | M |
| L3 | Startgebühren und Reisekosten: über Block ② (Budgetposten), keine eigene Kennzahl | – |

### 4.4 Klettern

| Nr | Kennzahl | Entscheidung |
|---|---|---|
| – | Baustein Gruppen (4.1), wenn das Referat Gruppen hat | M |
| H2 | Arbeitseinsätze im Jahr: Anzahl, Personen, Stunden (inkl. Veranstaltungen wie Europacup) | M |
| H3 | Aktive des Referats nach Ehrenamtsstatus, Neuzugänge im Jahr | S |

### 4.5 Touren und Ausbildung

| Nr | Kennzahl | Entscheidung |
|---|---|---|
| T1 | **Jahresprogramm:** Planungen je Status (eingereicht, Rückfrage, freigegeben, in Yolawo angelegt, durchgeführt, abgesagt) mit Vorjahr | M |
| T1b | Ø Tage von „eingereicht“ bis „freigegeben“ | S |
| T2 | Kostendeckung: Summe der geplanten Ergebnisse bei Mindestzahl, Anzahl Planungen mit Verlust bei Mindestzahl | M |
| B9 | Geplante Vergütung und Kosten aller freigegebenen Planungen gegen das Budget des Referats | M |
| T3 | Absagequote (abgesagt ÷ in Yolawo angelegt) mit Vorjahr | M |
| T6 | Leitende mit gültiger Lizenz; Ablauf in 90 Tagen (in ①) | M |
| T4 | Durchgeführt, nicht abgerechnet, älter als 4 Wochen (in ①) | S (FI Iteration 1) |
| T5 | CO2 je Teilnehmer:in und Tag, Anteil Anreise mit Bahn/Bus | S (TK Iteration 1) |
| T7 | Auslastung der Kurse und Touren (Anmeldungen ÷ Höchstzahl) | **Vorschlag an TK** [OFFEN]: Teilnehmerzahl bei „durchgeführt“ erfassen; bis dahin nicht im Dashboard |

### 4.6 Karl-Stein-Hütte, Sulzenauhütte

| Nr | Kennzahl | Entscheidung |
|---|---|---|
| H2 | Arbeitseinsätze an der Hütte: Anzahl, Personen, Stunden, mit Vorjahr | M |
| H3 | Aktive des Referats nach Ehrenamtsstatus | S |
| H4 | Belegung der Hütte | W (nicht im Vereins OS) |
| – | Sulzenauhütte: kein Block ②, Hinweis „Für die Sulzenauhütte gibt es keinen Budgetposten im Finanzplan.“ | M |

### 4.7 Öffentlichkeitsarbeit

| Nr | Kennzahl | Entscheidung |
|---|---|---|
| – | Block ② Budget | M |
| H3 | Aktive des Referats | S |
| – | Beiträge, Pressemitteilungen, Reichweite | C (mit Modul OA und SC) |

### 4.8 Umwelt und Naturschutz

| Nr | Kennzahl | Entscheidung |
|---|---|---|
| – | Block ② Budget | M |
| T5 | **CO2 aller Planungen des Vereins** (Touren und Kurse) je Jahr, je Teilnehmer:in und Tag, nach Verkehrsmittel; Klimaschutzbudget | S (TK Iteration 1) – die wichtigste Fachkennzahl des Referats |
| – | Anteil der Touren mit Anreise per Bahn/Bus | S |
| H3 | Aktive des Referats | S |

## 5. Sichten ohne Referat [FESTLEGUNG]

### 5.1 Verein (Vorstand, Admin, Geschäftsstelle)

| Nr | Kennzahl | Entscheidung |
|---|---|---|
| V1 | Budget aller Gesamtbudgets mit Ampel; oben die Gesamtbudgets, die schneller als der Jahresfortschritt verbrauchen oder über 100 % liegen | M |
| B2 | Einnahmen: Plan / erreicht / fehlt noch | M |
| B7 | Vorjahr zum gleichen Stichtag (Verein gesamt) | M |
| – | Offene Umschichtungen und Umschlüsselungs-Vorschläge (Anzahl) | M |
| V3 | Teilnehmer:innen in Gruppen gesamt und je Referat, mit Vorjahr | S |
| V2 | Aktive je Referat; Neuzugänge und Ausgeschiedene im Jahr | S |
| V4 | Einsätze und Einsatzstunden des Ehrenamts je Referat | S |
| V5 | Ausgezahlte Vergütung je Referat und Jahr; Anzahl Personen am steuerfreien Höchstbetrag | S |
| V6 | **Jahresbericht:** alle Kennzahlen je Referat als druckbare Seite (Mitgliederversammlung) | C |
| V7 | Kennzahlen für Förderanträge | C [OFFEN: welche Fördergeber, Glossar „Förderung“ offen] |
| B11 | Filter nach Sphäre | C (bleibt im Bereich Budget von FI) |
| – | Druckansicht für die Vorstandssitzung (wie im Prototyp) | M |

### 5.2 Geschäftsstelle (zusätzlich zur Vereinssicht)

Block ① mit Z9 und dazu: G2 Qualifikationen, die in 90 Tagen ablaufen (alle Referate); G3 „Teilnahme klären“ und fehlende Erziehungsberechtigte; G4 Einsätze ohne Anwesenheit älter als 7 Tage; G5 Planungen nach dem Termin noch nicht „durchgeführt“; K12 Punktekonto Kletterhalle (Abgleich steht an) – alle **M**, soweit das Quellmodul läuft.

### 5.3 Budgetpflege

Block ① mit Z8; darunter Prüfung des letzten Imports (Summe je Konto = Kontenübersicht, ausgewertet = Ausgaben − Einnahmen + nicht zugeordnet) – **M**.

### 5.4 Admin

A1 Zugänge nach Status, Einladungen älter als 14 Tage; A2 Anmeldungen des Notfall-Admins im letzten Monat – **S**.

### 5.5 Gruppenleitung (nach dem MVP, Q-DS8)

Nur Baustein Gruppen (4.1) für die eigene Gruppe, ohne Budget und ohne Block ④ – **C**.

## 6. Entscheidungen zum Ideenkatalog (Übersicht)

| Entscheidung | Nummern aus ideen-sichten.md |
|---|---|
| **M** – MVP (Budget) | B1, B2, B3, B4, B5, B7, B12, V1, Z4, Z8, Druckansicht |
| **M** – sobald das Quellmodul läuft (Iteration 1) | K1, K3, K5, K6, K7, K8, K9, K10, B8, L1, L2, H2, T1, T2, T3, T6, B9, G1–G5, Z1–Z3, Z5, Z6, Z9 |
| **S** | B6, K2, K11, K13, H3, T1b, T4, T5, V2–V5, A1, A2 |
| **C** | V6, V7, B11, Gruppenleitung, OA-Kennzahlen |
| **W** | K12 (für Referent:innen), K14, H4, B10 (Verträge: erst mit dem Buchungslauf in FI), T7 (bis TK die Teilnehmerzahl erfasst) |

## 7. Folgen für andere Module

- **EZ, GR, EA, TK, FI:** je eine Lesefunktion mit Recht auf DS für die genannten Kennzahlen (nur Anzahlen, Summen, Quoten). Liste je Modul folgt mit den Stories [ANNAHME: eigene Übergaben je Modul, sobald die Stories stehen].
- **TK:** Vorschlag, die tatsächliche Teilnehmerzahl bei „durchgeführt“ zu erfassen (T7) [OFFEN, Entscheidung im Modul TK].
- **GR:** keine Platzzahl (Q-DS3); Altersstruktur wird nicht angezeigt (K14).
