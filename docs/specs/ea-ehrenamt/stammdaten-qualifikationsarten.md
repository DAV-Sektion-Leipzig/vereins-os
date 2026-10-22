# Stammdaten Qualifikationsarten: Ehrenamtsmanagement

Stand: 21.10.2026 · Version 0.2 · Status: abgestimmt (Product Owner 21.10.2026)
Bezug: glossar.md v1.1 (Qualifikationsart, Qualifikationstyp, Sparte, Lizenzstufe, Spezifikation, Gültigkeitsdauer), specs/ad-administration/spec.md v0.6 (Tabelle ad_qualification_types, Startbestand T27), specs/ea-ehrenamt/00-steckbrief.md v0.6, migration-aktivenliste.md
Änderungen v0.2: Pflege in der Administration durch Admin und Geschäftsstelle; „Art“ heißt „Typ“ (Qualifikationstyp); Sparte als Klassifizierung des Bundesverbands; Widersprüche W1–W6 geklärt bzw. übernommen; offene Fragen aktualisiert.

**Verwendung:** Abschnitt 3 ist der Startbestand der Tabelle `ad_qualification_types` (Migration T27, Abgleich über Quell-ID). Spalten → Datenbank: Quell-ID → source_ref, Kürzel → code, Bezeichnung → name, Sparte (Überschrift 3.x) → discipline, Typ → kind (Lizenz = license, ZQ = add_on, Lehrgang = course, Weiterbildung = training), Stufe → level (V = pre, – = none bei Lizenz, sonst null), Spezifikation → specification, Aussteller → issuer, DOSB → dosb_eligible (ja = true, nein = false, n. g./– = null), FB-Intervall → validity_years (– = null), Status → status (aktuell = current, historisch = historic; Zusatz [ANNAHME] entfällt; [OFFEN] = historic), Hinweis → note (ohne Markierungen [ANNAHME]/[OFFEN]).
**Pflege:** ab Inbetriebnahme nur noch im Vereins OS (Administration bzw. Ehrenamtsmanagement → Qualifikationsarten); diese Datei ist danach nur der historische Startbestand.
**Sparte:** Klassifizierung des Bundesverbands (Klettersport, Bergsport Sommer, Berg- und Klettersport Winter, Jugend und Familie); gilt nur für Qualifikationsarten, kein Bezug zu Referaten.

## 1. Quellen

- **Q1:** 4 CSV-Exporte (Product Owner, 21.10.2026), Ordner `/public/Personen/Qualifikationen/…`: Klettersport (16), Bergsport Sommer (18), Berg- und Klettersport Winter (11), Jugend und Familie (2) = 47 Einträge. Spalte „Quell-ID“ = `id` aus dem Export.
- **Q2:** Fortbildungsregelung 2026/2027 des Bundesverbands: https://ausbildung.alpenverein.de/page.aspx?name=Fortbildungsregelung%202027
- **Q3:** DOSB/BLSV-Lizenzen: https://ausbildung.alpenverein.de/page.aspx?name=DOSB/BLSV-Lizenzen%20und%20IVSI
- **Q4:** DAV-Ausweise: https://ausbildung.alpenverein.de/page.aspx?name=DAV-Ausweise
- **Q5:** Ausbildungsstruktur 2026/2027 (Bergsport Sommer, Bergsport Winter, Klettersport, Mountainbike): https://www.alpenverein.de/verband/bergsport/bildung/aus-und-fortbildung-trainer-dav
- **Q6:** JDAV-Rahmenkonzeption Bildung (Stand 22.02.2025): https://www.jdav.de/files/jdav_rahmenkonzeption_aktualisierung_2025-02-22.pdf

## 2. Regeln aus den Quellen

- **R1 Fortbildungsintervall (Q2):** Wanderleiter*in 5 Jahre · Kletterbetreuer*in, Skibetreuer*in 4 · Trainer*in C / Fachübungsleiter*in 4 · Trainer*in B / Übungsleiter*in B 4 · Freeride Guide, Routenbauer*in 4 · Familiengruppenleiter*in 3 · Trainer*in A 2.
- **R2 Fälligkeit (Q2):** Fortbildung nötig im Kalenderjahr „Jahr der letzten Aus-/Fortbildung + Intervall“ (Beispiel 2027: letzte Fortbildung 2023, Intervall 4 → Fortbildung 2027 nötig). [ANNAHME] Ablaufdatum im Vereins OS = 31.12. dieses Jahres.
- **R3 Nachholen (Q2):** Fortbildung verpasst → im Folgejahr zwei Fortbildungen, höchstens eine davon als Webinar. Ausnahme Kletterbetreuer*in: eine 2,5-tägige Präsenzfortbildung mit Sicherungsinhalten.
- **R4 Mehrfach-Verlängerung (Q2):** Eine Fortbildung kann mehrere Lizenzen gleichzeitig verlängern. Webinare zählen nur im Wechsel mit Präsenzfortbildungen.
- **R5 DAV-Ausweis (Q4):** je Ausbildungsrichtung ein eigener Ausweis; gültig nur mit aktueller Jahresmarke. Für Zusatzqualifikationen gibt es keinen Ausweis. Voraussetzung: Erste-Hilfe-Nachweis mit mind. 9 Unterrichtseinheiten, nicht älter als 2 Jahre.
- **R6 DOSB-Lizenz (Q3):** Antrag nur über die Sektion beim Landesverband; gültig 4 Jahre ab Ausstellungsdatum; Verlängerung um 4 Jahre, frühestens 3 Monate vor Ablauf, nur bei erfüllter DAV-Fortbildungspflicht. Mountainbike-Lizenzen stellt nur der Bund Deutscher Radfahrer aus.
- **R7 Jugendleiter*in (Q6):** jährliche Fortbildungspflicht (Fortbildung oder Aufbaumodul) für die Jahresmarke; Marke über die Jugendreferent*in. Alle 3 Jahre zählt eine Fortbildung aus dem DAV-Ausbildungsprogramm bzw. eine Trainer-Fortbildung. Wiedererlangung: ≤ 2 Kalenderjahre ohne Fortbildung → 1 Fortbildung; ≥ 3 → 2 Fortbildungen in einem Jahr, davon eine pädagogische; > 6 → erneute Grundausbildung empfohlen.

## 3. Tabelle Qualifikationsarten

Legende Typ: **Lizenz** = DAV-/JDAV-Ausweis mit Jahresmarke · **ZQ** = Zusatzqualifikation (kein Ausweis, R5) · **Lehrgang** = Ausbildungsbaustein ohne eigene Lizenz · **Weiterbildung** = siehe Glossar.
Lizenzstufe: C, B, A wie Glossar; zusätzlich **V** = Vorstufenqualifikation (Q5) und **–** = ohne Stufe.
DOSB: ja = laut Q3 DOSB-lizenzfähig · nein = laut Q3 ausdrücklich nicht · n. g. = in Q3 nicht genannt.
Status: **aktuell** = in Ausbildungsstruktur 2026/2027 (Q5) · **historisch** = in Q1 als „alt“/„bis 2018“ markiert oder nicht mehr in Q5; nur für Migration und Historie, bei Neuanlage nicht wählbar [ANNAHME].

### 3.1 Klettersport

| Quell-ID | Kürzel | Bezeichnung | Typ | Stufe | Spezifikation | Aussteller | DOSB | FB-Intervall (J.) | Status | Hinweis |
|---|---|---|---|---|---|---|---|---|---|---|
| 2325 | KB | Kletterbetreuer*in Breitensport | Lizenz | V | Sportklettern Breitensport | Bundesverband | nein | 4 | aktuell | R3-Ausnahme |
| 20635 | TCSPI | Trainer*in C Sportklettern Breitensport Indoor | Lizenz | C | Sportklettern Breitensport Indoor | Bundesverband | ja | 4 | aktuell | – |
| 2317 | TCBO | Trainer*in C Bouldern Breitensport Indoor | Lizenz | C | Bouldern Breitensport Indoor | Bundesverband | ja | 4 | aktuell | – |
| 2318 | TCLS | Trainer*in C Sportklettern Leistungssport | Lizenz | C | Sportklettern Leistungssport | Bundesverband | ja | 4 | aktuell | – |
| 2315 | TCBM | Trainer*in C Klettern für Menschen mit Behinderungen | Lizenz | C | Klettern für Menschen mit Behinderungen | Bundesverband | ja | 4 | aktuell | – |
| 2314 | TBSP | Trainer*in B Sportklettern Breitensport | Lizenz | B | Sportklettern Breitensport | Bundesverband | ja | 4 | aktuell | – |
| 2313 | TBLS | Trainer*in B Sportklettern Leistungssport | Lizenz | B | Sportklettern Leistungssport | Bundesverband | ja | 4 | aktuell | – |
| 19937 | TALS | Trainer*in A Sportklettern Leistungssport | Lizenz | A | Sportklettern Leistungssport | Bundesverband | ja | 2 | aktuell | – |
| 2319 | RB | Routenbauer*in Breitensport | Lizenz | – | Routenbau Breitensport | Bundesverband | nein | 4 | aktuell | – |
| 2321 | ZQOS | Zusatzqualifikation Sportklettern Outdoor | ZQ | – | Sportklettern Outdoor | Bundesverband | – | – | aktuell | kein eigenes Ablaufdatum [ANNAHME] |
| 2322 | ZQOB | Zusatzqualifikation Bouldern Outdoor | ZQ | – | Bouldern Outdoor | Bundesverband | – | – | aktuell | wie ZQOS |
| 2320 | ZQTD | Zusatzqualifikation Traditionelles Klettern | ZQ | – | Traditionelles Klettern | Bundesverband | – | – | aktuell | wie ZQOS |
| 2316 | TCSP | Trainer*in C Sportklettern Breitensport (bis 2018) | Lizenz | C | Sportklettern Breitensport | Bundesverband | ja | 4 | historisch | – |
| 20634 | KS | Trainer*in C Sportklettern Breitensport (alt) | Lizenz | C | Sportklettern Breitensport | Bundesverband | ja | 4 | historisch | – |
| 20633 | TC | Trainer*in C Sportklettern Leistungssport (alt) | Lizenz | C | Sportklettern Leistungssport | Bundesverband | ja | 4 | historisch | – |
| 19936 | TBLSF | Trainer*in B Wettkampfklettern (alt) | Lizenz | B | Wettkampfklettern | Bundesverband | n. g. | 4 | historisch | – |

### 3.2 Bergsport Sommer

| Quell-ID | Kürzel | Bezeichnung | Typ | Stufe | Spezifikation | Aussteller | DOSB | FB-Intervall (J.) | Status | Hinweis |
|---|---|---|---|---|---|---|---|---|---|---|
| 2303 | WL | Wanderleiter*in | Lizenz | V | Bergwandern | Bundesverband | nein | 5 | aktuell | Fortbildungspflicht seit 2025, erste Prüfung bei Jahresmarke 2028; externe Fortbildungen zählen nicht |
| 2302 | TCBW | Trainer*in C Bergwandern | Lizenz | C | Bergwandern | Bundesverband | ja | 4 | aktuell | – |
| 2301 | TCBS | Trainer*in C Bergsteigen | Lizenz | C | Bergsteigen | Bundesverband | ja | 4 | aktuell | – |
| 19933 | TCKS | Trainer*in C Klettersteig | Lizenz | C | Klettersteig | Bundesverband | ja | 4 | aktuell | – |
| 19934 | TCAK | Trainer*in C Alpinklettern | Lizenz | C | Alpinklettern | Bundesverband | ja | 4 | aktuell | – |
| 2306 | TCMG | Trainer*in C MTB Guide | Lizenz | C | Mountainbike Guide | Bundesverband | nein | 4 | aktuell | DOSB nur über Bund Deutscher Radfahrer |
| 2307 | TCMF | Trainer*in C MTB Fahrtechnik | Lizenz | C | Mountainbike Fahrtechnik | Bundesverband | nein | 4 | aktuell | wie TCMG |
| 2308 | TCMGF | Trainer*in C Mountainbike Guide & Fahrtechnik | Lizenz | C | Mountainbike Guide und Fahrtechnik | Bundesverband | nein | 4 | aktuell | [OFFEN] eigene Lizenz oder TCMG + TCMF? |
| 2297 | TBHT | Trainer*in B Hochtouren | Lizenz | B | Hochtouren | Bundesverband | ja | 4 | aktuell | – |
| 2298 | TBAK | Trainer*in B Alpinklettern | Lizenz | B | Alpinklettern | Bundesverband | ja | 4 | aktuell | – |
| 2299 | TBPK | Trainer*in B Plaisirklettern | Lizenz | B | Plaisirklettern | Bundesverband | ja | 4 | aktuell | Ausbildung 2027 nicht angeboten; Lizenz bleibt gültig |
| 2300 | TBKS | Trainer*in B Klettersteig | Lizenz | B | Klettersteig | Bundesverband | ja | 4 | aktuell | – |
| 2305 | TBMC | Trainer*in B MTB Coach | Lizenz | B | Mountainbike Coach | Bundesverband | nein | 4 | aktuell | wie TCMG |
| 20636 | UBPR | Übungsleiter*in B Bergwandern in der Prävention | Lizenz | B | Bergwandern Prävention | Bundesverband | ja | 4 | aktuell | – |
| 2312 | TBS | Qualifizierungslehrgang Alpin | Lehrgang | – | Alpin | Bundesverband | – | – | aktuell | Zugang für Trainer*innen Klettersport zu alpinen C-/B-Stufen; keine Lizenz |
| 2310 | ZQLB | Zusatzqualifikation Leistungsbergsteigen | ZQ | – | Leistungsbergsteigen | Bundesverband | – | – | historisch [ANNAHME] | nicht in Q5 |
| 19941 | MTB | Fachübungsleiter*in Mountainbike | Lizenz | C | Mountainbike Guide | Bundesverband | nein | 4 | historisch | gleichgesetzt mit Trainer*in C Mountainbike Guide |
| 19942 | PSA | Persönliche Schutzausrüstung | Weiterbildung [ANNAHME] | – | PSA-Prüfung | [OFFEN] | – | [OFFEN] | [OFFEN] | keine DAV-Lizenz; Prüfintervall und Aussteller klären |

### 3.3 Berg- und Klettersport Winter

| Quell-ID | Kürzel | Bezeichnung | Typ | Stufe | Spezifikation | Aussteller | DOSB | FB-Intervall (J.) | Status | Hinweis |
|---|---|---|---|---|---|---|---|---|---|---|
| 19944 | SK | Fachübungsleiter*in Skilauf | Lizenz | – | Skilauf | Bundesverband | nein | 4 | aktuell | BLSV-Lizenz nur in Bayern |
| 2294 | TCSB | Trainer*in C Skibergsteigen | Lizenz | C | Skibergsteigen | Bundesverband | ja | 4 | aktuell | – |
| 146324 | TCSS | Trainer*in C Schneeschuhbergsteigen | Lizenz | C | Schneeschuhbergsteigen | Bundesverband | ja | 4 | aktuell | seit 2025; DOSB laut Seite Bergsport Winter |
| 146321 | TCEK | Trainer*in C Eisklettern | Lizenz | C | Eisklettern | Bundesverband | n. g. | 4 | aktuell | – |
| 2291 | TBSH | Trainer*in B Skihochtour | Lizenz | B | Skihochtour | Bundesverband | ja | 4 | aktuell | – |
| 2292 | TBEK [ANNAHME] | Trainer*in B Eisklettern | Lizenz | B | Eisklettern | Bundesverband | ja | 4 | aktuell [ANNAHME] | Kürzel fehlt in Q1; in Q3 „Eisfallklettern“; nicht in Struktur 2027 |
| 2290 | FRG | DAV Freeride Guide | Lizenz | – | Freeride | Bundesverband | nein | 4 | aktuell | – |
| 2293 | LL | Fachübungsleiter*in Skilanglauf | Lizenz | – | Skilanglauf | Bundesverband | nein | 4 | historisch [ANNAHME] | nicht in Q5 |
| 2296 | ZQSS | Zusatzqualifikation Schneeschuhbergsteigen | ZQ | – | Schneeschuhbergsteigen | Bundesverband | – | – | historisch | 2025 abgelöst durch TCSS; Nachqualifizierung möglich |
| 19931 | ZQEIS | Zusatzqualifikation Eisfallklettern (alt) | ZQ | – | Eisfallklettern | Bundesverband | – | – | historisch | – |
| 19932 | ZQFR | Zusatzqualifikation Freeride (alt) | ZQ | – | Freeride | Bundesverband | – | – | historisch | – |

### 3.4 Jugend und Familie

| Quell-ID | Kürzel | Bezeichnung | Typ | Stufe | Spezifikation | Aussteller | DOSB | FB-Intervall (J.) | Status | Hinweis |
|---|---|---|---|---|---|---|---|---|---|---|
| 2304 | FGL | Familiengruppenleiter*in | Lizenz | V | Familienbergsteigen | Bundesverband | nein | 3 | aktuell | Q5 kennt Varianten Wandern und Klettern [OFFEN] |
| 2326 | JL [ANNAHME] | Jugendleiter*in | Lizenz | – | Jugendarbeit | Bundesverband (JDAV) | [OFFEN] | 1 | aktuell | R7; Kürzel fehlt in Q1 |

## 4. In der Ausbildungsstruktur, aber nicht im Export

Nur bei Bedarf anlegen; Entscheidung Product Owner.

| Bezeichnung | Sparte | Stufe | Quelle |
|---|---|---|---|
| DAV-Skibetreuer*in (eigene Lizenz, ab 16) | Winter | V | Q5, ab Kursjahr 2027 |
| Trainer*in C Skibergsteigen Leistungssport | Winter | C | Q5 |
| Mountainbike-Leiter*in (Mittelgebirge) | Sommer | V | Q5, seit 2025 |
| Trainer*in C Sportklettern Breitensport (Lehrgang 2) | Klettersport | C | Q5, Q3 |
| Routenbauer*in Leistungssport (Lead, Bouldern) | Klettersport | – | Q5 |
| Zusatzqualifikation Outdoor Inklusiv | Klettersport | ZQ | Q5 |
| Familiengruppenleiter*in Klettern / Wandern | Jugend und Familie | V | Q5 |
| JDAV-Aufbaumodule (Alpinklettern, Bergsteigen, Hochtouren, Klettersteig, Mountainbike, Skibergsteigen, Skihochtouren, Sportklettern) | Jugend und Familie | – | Q6 |
| Übungsleiterlizenz Landessportbund | – (Aussteller Landessportbund) | – | glossar.md |
| Erste Hilfe (mind. 9 UE) | – | Weiterbildung | Q4 |

## 5. Widersprüche zum Glossar (Stand v0.2)

- **W1 Gültigkeitsdauer:** im Glossar v1.1 korrigiert (C und B 4 Jahre, A 2 Jahre usw.).
- **W2 Zwei Ablaufdaten:** [OFFEN] im Steckbrief EA v0.6 (DOSB-Lizenz zusätzlich führen?).
- **W3 Lizenzstufe:** im Glossar v1.1 um Vorstufe und „ohne Stufe“ erweitert.
- **W4 Ablaufdatum:** im Glossar v1.1 geklärt: Ablaufdatum nur, wenn die Qualifikationsart eine Gültigkeitsdauer hat.
- **W5 Fortbildung:** im Glossar v1.1 übernommen (eine Fortbildung kann mehrere Lizenzen verlängern); Umsetzung im Ehrenamtsmanagement.
- **W6 Aufbaumodul:** im Glossar v1.1 definiert (JDAV).

## 6. Offene Fragen

| Frage | Wer klärt | bis wann |
|---|---|---|
| [OFFEN] Beide Ablaufdaten führen (Jahresmarke nach Fortbildungsregelung und DOSB-Lizenz)? | Product Owner | vor Spec EA |
| [OFFEN] PSA: aufnehmen (Weiterbildung mit Prüfintervall, Aussteller) oder historisch lassen? Bis dahin historisch. | Product Owner | vor Migration |
| [OFFEN] Trainer*in C Mountainbike Guide & Fahrtechnik: eigene Qualifikationsart oder TCMG + TCMF? | Product Owner | vor Migration |
| [OFFEN] Jugendleiter*in: DOSB-Lizenz/Juleica mitführen? | Product Owner, Jugendreferent*in | vor Spec EA |
| [OFFEN] Einträge aus Abschnitt 4 (nicht im Export) anlegen? Kann nach Inbetriebnahme in der Oberfläche geschehen. | Product Owner, Geschäftsstelle | jederzeit |

Erledigt am 21.10.2026: Historische Qualifikationsarten werden angelegt, sind aber nicht neu vergebbar; Pflege durch Admin und Geschäftsstelle in der Administration; Sparte bleibt Klassifizierung des Bundesverbands.
