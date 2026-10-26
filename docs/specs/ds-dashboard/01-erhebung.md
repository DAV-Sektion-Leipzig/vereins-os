# Erhebung: Dashboard

Datum: 26.10.2026 · Version 0.1 · Status: Entwurf · Beteiligte: Toni Werner (Product Owner); Claude als Referent:in für die Festlegung der Sichten (Auftrag des Product Owners)
Grundlage: 00-steckbrief.md v0.13, sichten.md v0.8, prototyp-budget-dashboard.md v1.0, uebergabe-finanzen.md v1.7, uebergabe-administration.md v1.3, uebergabe-gruppen.md v1.0, Skizze „Dashboard Kinder und Jugend“ (Übersicht und Gruppendetail).
Änderungen v0.1: Erster Entwurf für den MVP (Budget-Sicht, Budgetpflege, Pflege durch Referent:innen). Referats-Kennzahlen und Gruppendetail (Iteration 1) nur in Abschnitt B9.

Begriffe nach glossar.md v1.7 (u. a. Dashboard, Sicht, Kennzahl, Budgetposten, Gesamtbudget, Zuordnung (Budget), Buchung, umschlüsseln, umschichten, Datenstand, Budgetpflege, Anwesenheitsquote).

**Zuschnitt (Q-DS2):** Daten, Import und Pflege des Budgets gehören zum **Bereich Budget von Finanzen** (Tabellen mit Präfix `fi_`). Das Dashboard (DS) zeigt die Sichten an und speichert selbst keine Fachdaten [ANNAHME]. Abschnitt C nennt deshalb bei jeder Tabelle das Modul.

## A. Rechtevorlagen & Rechte

| Rechtevorlage | Recht | Was | Reichweite |
|---|---|---|---|
| Referent:in | DS lesen | gesamtes Budget des Vereins als Summen; Einzelbuchungen und Pflege (Hinweis, Umschichtung beantragen, Umschlüsselung vorschlagen) nur für Gesamtbudgets des eigenen Referats und für Gesamtbudgets „alle“ (nur lesen) | Referat |
| Vorstand | DS lesen | gesamtes Budget mit allen Einzelbuchungen, nicht zugeordnete Buchungen, Druckansicht | alle |
| Geschäftsstelle | DS lesen | wie Vorstand; pflegt das Budget **nicht** (Q-DS7) | alle |
| Admin (auch Notfall-Admin) | DS lesen | wie Vorstand (D5) | alle |
| Budgetpflege (neu) | DS lesen + Kennzeichen „darf Budget pflegen“ | Finanzplan einlesen, Gesamtbudgets einem Referat zuordnen, Zuordnung pflegen, DATEV-Export einspielen, umschlüsseln, Umschichtungen und Vorschläge bestätigen oder ablehnen, Hinweise zu allen Budgetposten | alle |
| Gruppenleitung (nach MVP) | DS lesen | nur Kennzahlen der eigenen Gruppe, kein Budget (Q-DS8) | Gruppe |

- Ein Recht auf DS gibt keine Rechte in den Fachmodulen; die Lesefunktionen für das Dashboard prüfen das Recht auf DS (Q-DS12).
- Startwert: Die Vorlage „Budgetpflege“ erhält der 1. Vorsitzende, später die Schatzmeister:in (uebergabe-administration.md D6).
- Wer Budgetpflege hat und zugleich Referent:in ist, bestätigt keine eigene Umschichtung [ANNAHME: Vier-Augen-Prinzip wie in FI]; dann bestätigt eine zweite Person mit Budgetpflege oder der Vorstand [OFFEN: Vertretung, solange es nur eine Person mit Budgetpflege gibt].

## B. Abläufe (inkl. Zustände)

**B1 – Finanzplan einlesen** (Budgetpflege, einmal je Jahr, bei Änderung erneut)
1. Excel „Finanzen Sektion JJJJ.xlsx“ hochladen; das System sucht das Blatt „Finanzplan JJJJ“ (bei mehreren: Auswahl).
2. Lesen wie `build.py`: Kopfzeile mit „Einnahmen“ und „Ausgaben“, je Seite Spalte „Plan JJJJ“, Zeilen „Summe…“ als Kontrollsumme (R10).
3. Vorschau: Budgetposten je Art mit Plan, Summenprüfung ✓/✗, neue und entfallene Posten gegenüber dem letzten Einlesen.
4. Übernehmen → Budgetposten des Jahres mit **beschlossenem Plan**. Bestätigte Umschichtungen bleiben erhalten, solange beide Posten bestehen; sonst Hinweis (R15).

**B2 – Gesamtbudgets und Referate** (Budgetpflege)
Jeder Budgetposten gehört zu einem Gesamtbudget; jedes Gesamtbudget hat die Sichtbarkeit **Referat** (genau eines), **alle** oder **ohne Referat** (R22). Startwerte nach 00-steckbrief.md Tabelle „Gesamtbudgets und Referate“.

**B3 – Zuordnung pflegen** (Budgetpflege)
Regeln Konto → Budgetposten anlegen, ändern, beenden: Einzelkonto („6326 6“), Hauptkonto („6326“), Kontenbereich („4000-7999“), mehrere mit Komma, optional Kostenstelle; Status ok / unsicher / offen / keine Buchung; Hinweis. Jede Änderung mit Kommentar; Historie mit `valid_from`/`valid_to` statt Versionsdateien (R11, R24). Erstbestand: Übernahme der `zuordnung.csv` des Prototyps (B8).

**B4 – DATEV-Export einspielen** (Budgetpflege, monatlich)
1. CSV der Kontenblätter hochladen.
2. Lesen: Kontenübersicht und Buchungsliste, Spalten über Namen, UTF-8 mit BOM oder Windows-1252.
3. Filtern: nur Buchungsjahr = Budgetjahr, ohne Saldovorträge (R4); gespeichert werden nur Zeilen auf Konten, die eine Regel trifft (R1).
4. Prüfen (R8): Summe je Konto = Kontenübersicht; ausgewertet = Ausgaben − Einnahmen + nicht zugeordnet; umgeschlüsselte Buchungen wiedergefunden.
5. Ergebnis anzeigen (Zeilen gelesen, gespeichert, ignoriert; Datenstand; Warnungen) → übernehmen. Der Import ersetzt den vorigen Import desselben Jahres (R9).

**B5 – Budget-Sicht ansehen** (alle mit DS lesen)
Block ② „Budget meines Referats“ und Block ④ „Budget des Vereins“ nach sichten.md: Plan (aktuell und beschlossen), verbraucht/erreicht, frei, Verbrauch in %, Ampel (R6), Strich für den Jahresfortschritt (R7), Vorjahr zum gleichen Stichtag (R20), Datenstand, Hinweise, Vorschau (R18). Klick auf einen Budgetposten → Einzelbuchungen, soweit berechtigt (R13).

**B6 – Umschichtung** (Referent:in beantragt, Budgetpflege bestätigt)

| Von | Nach | Wer | Bedingung |
|---|---|---|---|
| – | beantragt | Referent:in des Referats (oder Budgetpflege) | R15 erfüllt, Grund angegeben |
| beantragt | zurückgezogen | Antragsteller:in | – |
| beantragt | bestätigt | Budgetpflege | R15 weiterhin erfüllt; nicht eigener Antrag |
| beantragt | abgelehnt | Budgetpflege | Grund angegeben |
| bestätigt | – | – | endgültig; Rückgängig nur über eine neue Umschichtung in Gegenrichtung |

Die Budgetpflege kann auch direkt umschichten (Zustand sofort „bestätigt“) [ANNAHME].

**B7 – Umschlüsselung** (Referent:in schlägt vor, Budgetpflege entscheidet)

| Von | Nach | Wer | Bedingung |
|---|---|---|---|
| – | vorgeschlagen | Referent:in | Buchung gehört zu einem Budgetposten des eigenen Referats (R16); Ziel-Budgetposten und Grund angegeben |
| vorgeschlagen | zurückgezogen | Vorschlagende:r | – |
| vorgeschlagen | angenommen | Budgetpflege | erzeugt eine Zuordnungsregel für die einzelne Buchung (oder das ganze Konto, wenn die Budgetpflege das wählt) |
| vorgeschlagen | abgelehnt | Budgetpflege | Grund angegeben |

Die Budgetpflege schlüsselt auch direkt um (wie im Prototyp, „⇄“). Bis zur Annahme zählt die Buchung beim bisherigen Posten.

**B8 – Übernahme aus dem Prototyp** (einmalig, Budgetpflege)
`zuordnung.csv` (Spalten Konto; Kontobezeichnung; Art; Gesamtbudget; Budgetposten; Kostenstelle; Status; Hinweis; Datum; Beleg; Betrag; Buchungstext) einlesen, mit denselben Prüfungen wie `lese_zuordnung` in `build.py`; Ergebnis: Zuordnungsregeln mit Status und Hinweis, Gesamtbudgets. Die Versionsdateien des Prototyps werden nicht übernommen [ANNAHME].

**B9 – Iteration 1 (Stichpunkte, Stories folgen mit den Übergaben an GR, EZ, EA, TK):** Block ① „Zu tun“ vollständig (Z1–Z9), Block ③ je Referat mit Baustein Gruppen (Status, Filter „Mit Hinweis“, Ampeln), Gruppendetail mit Steuerungshinweisen, Namen und Hinweisen, Verlauf über 4 Halbjahre; Sichten Touren/Ausbildung, Hütten, Umwelt; Sichten Verein und Geschäftsstelle mit Kennzahlen aus den Modulen.

**B10 – Neues Budgetjahr** (Budgetpflege)
Finanzplan des neuen Jahres einlesen (B1); Gesamtbudgets und Zuordnungsregeln werden aus dem Vorjahr übernommen und können angepasst werden [ANNAHME]; Einzelbuchungsregeln (Umschlüsselungen) gelten nur in ihrem Jahr. Jahreswahl in der Budget-Sicht: laufendes Jahr und Vorjahr (R19, R20).

## C. Daten (Feld | Typ | Pflicht | Beispiel | Quelle)

Alle Tabellen im **Bereich Budget von Finanzen** (`fi_budget_…`) [ANNAHME: Namen bei der Spec]; das Dashboard speichert keine Fachdaten.

**Finanzplan je Jahr**
| Feld | Typ | Pflicht | Beispiel | Quelle |
|---|---|---|---|---|
| Jahr | Zahl | ja | 2026 | Blattname |
| Datei, Blatt | Text | ja | „Finanzen Sektion 2026.xlsx“, „Finanzplan 2026“ | Upload |
| Summen Einnahmen/Ausgaben laut Excel | Betrag | nein | – | Summenzeilen |
| eingelesen am, von | Zeitpunkt, Person | ja | 26.10.2026, Budgetpflege | System |

**Gesamtbudget**: Jahr, Name (Text, ja, „Kinder und Jugend“), Sichtbarkeit (referat / alle / ohne, ja), Referat (Verweis, wenn Sichtbarkeit = referat), Reihenfolge.

**Budgetposten**: Jahr, Art (Einnahme/Ausgabe, ja), Name (Text, ja, genau wie in der Excel, z. B. „Vergütung Aktive“), Gesamtbudget (Verweis, ja), beschlossener Plan (Betrag in Cent, nein; leer = „kein Plan“), Excel-Zeile, Reihenfolge, Kennzeichen „keine Buchung“ (z. B. Auflösung Rücklagen).

**Zuordnungsregel**: Typ (Einzelbuchung / Konto / Hauptkonto / Bereich), Kontoangabe (Text, ja, „6326 6“), Kostenstelle (Text, nein, „3“), Budgetposten (Verweis, nein; leer = bewusst „nicht zugeordnet“), Status (ok / unsicher / offen / keine Buchung), Hinweis (Text, nein), Kontobezeichnung (nur Info), bei Einzelbuchung zusätzlich Datum, Beleg, Betrag mit S/H, Buchungstext; `valid_from`, `valid_to`, geändert von, Kommentar.

**Import**: Jahr, Dateiname, Exportzeit (aus Zeile 1), Datenstand (letzte Buchung), Zeilen gelesen / gespeichert / ignoriert, Prüfergebnis je Konto, Warnungen, eingespielt am und von.

**Buchung** (nur Zeilen auf Konten mit Regel, R1): Import, Konto (Hauptkonto + Unterkonto), Datum, BU, Gegenkonto, Beschriftung Gegenkonto, Buchungstext, Beleg (Belegfeld 1), Soll (Cent), Haben (Cent), KOST1. Personenbezug: Buchungstext kann Namen enthalten (F).

**Kontensumme je Monat**: Jahr, Monat, Konto, KOST1, Soll, Haben – Grundlage des Vorjahresvergleichs und bleibt nach der Löschung der Einzelbuchungen (R19).

**Umschichtung**: Jahr, von Budgetposten, nach Budgetposten, Betrag (Cent, > 0), Grund (Text, ja), Zustand (B6), beantragt von/am, entschieden von/am, Ablehnungsgrund.

**Umschlüsselungs-Vorschlag**: Buchung (Merkmale wie Einzelbuchungsregel), bisheriger und vorgeschlagener Budgetposten, Grund, Zustand (B7), von/am, entschieden von/am, Ablehnungsgrund.

**Hinweis je Budgetposten**: Budgetposten, Text (≤ 500 Zeichen), von, am; Historie.

**Vorschau (nicht gespeichert, berechnet)**: je Budgetposten „Vergütung Aktive“ eines Referats die Summe der abgeschlossenen und ausgezahlten Abrechnungen, die noch nicht gebucht sind (R18).

## D. Regeln (R1, R2 …)

- **R1 – Keine Doppelzählung:** Gezählt und gespeichert werden nur Buchungszeilen, deren Konto eine Zuordnungsregel trifft; die Auffangregel `4000-7999` (Erfolgskonten) gehört zum Erstbestand. Bank-, Kreditoren-, Sammel- und Personenkonten werden ignoriert.
- **R2 – Regelvorrang:** Einzelbuchung vor Einzelkonto vor Hauptkonto vor Kontenbereich (engster zuerst); mit Kostenstelle vor ohne. Trifft nur ein Bereich ohne Budgetposten, ist die Buchung „nicht zugeordnet“.
- **R3 – Vorzeichen:** Ausgabe = Soll − Haben, Einnahme = Haben − Soll; Stornos und Rücklastschriften mindern; Umbuchungen zwischen Budgetkonten zählen auf beiden Seiten mit eigenem Vorzeichen.
- **R4 – Ausschlüsse:** Saldovorträge („EB-Wert“, Gegenkonto „Saldenvortr…“) und Buchungen außerhalb des Budgetjahres zählen nicht und werden nicht gespeichert; ihre Anzahl erscheint im Import-Ergebnis.
- **R5 – Netto/brutto:** wie auf dem Erfolgskonto gebucht; der Plan gilt als gleiche Basis.
- **R6 – Ampel (Ausgaben):** ● unter 80 %, ▲ 80–100 %, ■ über 100 % oder Ausgaben ohne Plan; Grundlage nur gebuchte Beträge, Bezug ist der **aktuelle Plan**. Einnahmen: Anzeige „erreicht“ und „fehlt noch“; Posten mit „keine Buchung“ zählen nicht bei „fehlt noch“.
- **R7 – Jahresfortschritt:** Strich bei (Tag des Datenstands im Jahr ÷ Tage des Jahres); umschaltbar auf „heute“ [ANNAHME: wie im Prototyp].
- **R8 – Prüfung beim Import:** Weicht die Summe der Einzelbuchungen eines Kontos von der Kontenübersicht ab, erscheint die Warnung „Export unvollständig: Konto … – Kontenübersicht … €, Einzelbuchungen … €“; der Import wird trotzdem übernommen, die Warnung bleibt in der Budget-Sicht der Budgetpflege sichtbar, bis ein Import ohne Abweichung kommt.
- **R9 – Ersetzen:** Ein Import ersetzt alle Buchungen desselben Jahres aus dem vorigen Import. Findet sich eine umgeschlüsselte Buchung (Einzelbuchungsregel) nicht wieder, erscheint die Warnung „Umgeschlüsselte Buchung vom … nicht mehr im Export“.
- **R10 – Finanzplan:** Weicht die Summe der Posten einer Seite um mehr als 0,01 € von der Summenzeile ab, wird nicht übernommen: „Summe der Ausgaben … € weicht von der Summenzeile … € ab.“ Doppelte Postennamen gehören zum Gesamtbudget des Postens darüber (wie im Prototyp), mit Hinweis.
- **R11 – Zuordnung gültig:** Jede Kontoangabe darf je Jahr nur einmal vorkommen (gleiche Kostenstelle); unverständliche Angaben werden abgelehnt: „‚…‘ ist keine Kontonummer. Bitte wie im DATEV-Export schreiben, z. B. ‚6326 3‘.“
- **R12 – Summen für alle:** Die Summen aller Gesamtbudgets und Budgetposten sieht jede:r mit DS lesen, unabhängig von der Reichweite (Q-DS15).
- **R13 – Einzelbuchungen:** mit Reichweite „Referat“ nur bei Budgetposten von Gesamtbudgets des eigenen Referats und von Gesamtbudgets „alle“; mit Reichweite „alle“ oder Budgetpflege alle.
- **R14 – Nicht zugeordnete Buchungen:** nur Reichweite „alle“ und Budgetpflege.
- **R15 – Umschichtung:** beide Budgetposten im selben Gesamtbudget, im selben Jahr, gleiche Art; Betrag > 0 und ≤ aktueller Plan des abgebenden Postens; die Summe des Gesamtbudgets bleibt gleich. Referent:innen nur für Gesamtbudgets des eigenen Referats. Fehler: „Umschichten geht nur zwischen Posten desselben Gesamtbudgets und derselben Art.“ / „Der Betrag ist höher als der Plan von ‚…‘.“
- **R16 – Umschlüsselungs-Vorschlag:** nur für Buchungen, die einem Budgetposten des eigenen Referats zugeordnet sind; Ziel kann jeder Budgetposten desselben Jahres sein; je Buchung höchstens ein offener Vorschlag.
- **R17 – Hinweis:** Referent:innen für Budgetposten des eigenen Referats, Budgetpflege für alle; sichtbar für alle mit Budget-Sicht; Historie.
- **R18 – Vorschau:** abgeschlossene und ausgezahlte Abrechnungen eines Referats (Finanzen), deren Auszahlungsrunde noch nicht als Buchung auf dem Konto des Budgetpostens „Vergütung Aktive“ im Import steht [ANNAHME: Abgleich über Betrag und Datum der Auszahlungsrunde; Detail mit der Spec]; wird nie zu verbraucht, frei oder Ampel gerechnet; Hinweis ▲ „mit Vorschau über Plan“, wenn Ist + Vorschau > aktueller Plan.
- **R19 – Löschfrist:** Einzelbuchungen, Umschlüsselungs-Vorschläge und Einzelbuchungsregeln des Jahres J werden am 01.01. des Jahres J+2 automatisch gelöscht; Kontensummen je Monat, Finanzplan, Budgetposten, Umschichtungen und Hinweise bleiben 5 Jahre [ANNAHME].
- **R20 – Vorjahr:** Vergleichswert = Summe des Vorjahres bis zum gleichen Tag und Monat wie der Datenstand, sowie das ganze Vorjahr; Budgetposten zweier Jahre werden über Name und Gesamtbudget verknüpft; ohne Treffer „neu“.
- **R21 – Budgetpflege:** Pflegeaktionen nur mit dem Kennzeichen „darf Budget pflegen“; Prüfung in der Datenbank. Ohne Recht: „Für diesen Bereich hast du keine Rechte.“
- **R22 – Sichtbarkeit eines Gesamtbudgets:** Referat / alle / ohne Referat; ohne Angabe „ohne Referat“.
- **R23 – Datenstand alt:** Ist der Datenstand älter als 6 Wochen, sieht die Budgetpflege unter „Zu tun“ „Neuen DATEV-Export einspielen (Datenstand …)“; alle anderen sehen den Datenstand neben dem Budget.
- **R24 – Protokoll:** Finanzplan einlesen, Import, Zuordnung ändern, umschlüsseln, Umschichtung und Vorschlag (alle Zustandswechsel), Hinweis: je mit wer, wann, was; 5 Jahre.

## E. Schnittstellen

| Modul / extern | Richtung | Was | Wann |
|---|---|---|---|
| DATEV (Export Kontenblätter CSV) | → FI Budget | Buchungen und Kontenübersicht | monatlich, manuell; später über die DATEV-Schnittstelle des Schnittstellen-Connectors (B13 der Übergabe) |
| Excel „Finanzen Sektion JJJJ“ | → FI Budget | Finanzplan | jährlich, manuell |
| Prototyp `zuordnung.csv` | → FI Budget | Erstbestand Zuordnung | einmalig |
| AD | → DS, FI | Recht DS, Kennzeichen „darf Budget pflegen“, Referate, Startseite | Nachtrag AD (uebergabe-administration.md) |
| FI (Abrechnung) | → DS | Vorschau abgerechneter Vergütung; Abrechnungen zur Bestätigung (Z1) | MVP |
| FI (Budget) | → DS | Lesefunktionen Summen, Einzelbuchungen, Vorjahr, Anträge | MVP |
| GR, EZ, EA, TK | → DS | Kennzahlen und Gruppendetail | Iteration 1 |

## F. Datenschutz

- Buchungstexte enthalten Namen von Personen (Erstattungen, Vergütungen) und Firmen. Gespeichert werden nur Zeilen auf zugeordneten Erfolgskonten (R1), Einzelbuchungen höchstens bis Ende des Vorjahres (R19). Referent:innen sehen Einzelbuchungen nur ihres Referats (R13).
- Eintrag im Verarbeitungsverzeichnis: Zweck Budgetüberwachung; Kategorien Buchungsdaten mit Namen; Empfänger Vorstand, Geschäftsstelle, Admin, Referent:innen (eigenes Referat); Löschfrist R19 [OFFEN: Eintrag durch den Product Owner].
- Die Excel und die DATEV-CSV werden nach dem Einlesen nicht als Datei gespeichert [ANNAHME].
- Im öffentlichen Repository nur fiktive Finanzpläne und Exporte (Tests, Seed); echte Referenzwerte des Erstexports prüft der Product Owner lokal.

## G. Nicht-funktional

- Budget-Sicht lädt in unter 2 Sekunden bei einem Jahr mit ca. 6.000 Exportzeilen (davon ca. 1.300 gespeichert) [ANNAHME].
- Import einer Datei bis 5 MB im Browser oder in einer Edge Function [OFFEN: Ort der Verarbeitung bei der Spec]; Ergebnis identisch mit `build.py` und dem Prototyp (Abnahme mit fiktivem Export, alle Sonderfälle aus prototyp-budget-dashboard.md Abschnitt 4).
- Beträge in Cent (ganzzahlig), Rundung kaufmännisch.
- Mobil ab 375 px lesbar; Pflege (Import, Zuordnung) am Arbeitsplatz.
- Druckansicht A4 quer für die Vorstandssitzung.

## Offene Fragen (Frage | Wer klärt | bis wann)

| Frage | Wer klärt | bis wann |
|---|---|---|
| Vertretung beim Bestätigen von Umschichtungen, solange nur der 1. Vorsitzende Budgetpflege hat (eigener Antrag als Referent:in?) | Product Owner | vor der Spec |
| Abgleich „noch nicht gebucht“ für die Vorschau (R18): über die Auszahlungsrunde und welches Konto | Product Owner, Geschäftsstelle | vor der Spec |
| Verarbeitung des Imports im Browser oder in einer Edge Function | Claude Code (Spec), Product Owner | Spec |
| Eintrag im Verarbeitungsverzeichnis | Product Owner | vor Echtdaten |
| Werden Gesamtbudgets und Zuordnung beim neuen Jahr übernommen (B10)? | Product Owner | vor der Spec |
