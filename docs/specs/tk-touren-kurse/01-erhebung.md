# Erhebung: Planungshilfe Touren und Kurse

Datum: 26.10.2026 · Version 0.8 · Beteiligte: Toni Werner (Product Owner); Referat Touren (über den HTML-Prototyp „Tourenkonzept“ und dessen Übergabe) · Status: Entwurf
Änderungen v0.8: Wiederaufnahme: externe Leitende aus der Planung anlegen; Löschfrist 30 Tage; Satzart auch bei Lizenz-Erwerb im Halbjahr des Startdatums (wie Finanzen); Kurse ein- und mehrtägig nach Lehreinheiten; Titel ungekürzt an den Einsatz; Gemeinschaftstour übergibt die Abrechnungsart „Gemeinschaftstour“ (Product Owner 26.10.2026).
Änderungen v0.7: Organisationspauschale der Gemeinschaftstour trägt vorerst die Sektion; Sätze pflegt vorerst nur der Admin (Product Owner 22.10.2026).
Änderungen v0.6: Gemeinschaftstour mit Organisationspauschale (Vergütungsordnung Ziff. 9.2); Sätze und Pauschalen als Stammdaten der Administration; Stornoregel nicht im Scope (Product Owner 22.10.2026).
Änderungen v0.5: PDF-Übernahme nicht im Scope (Referat überträgt Einreichungen von Hand; Ablösung des HTML-Formulars folgt in Iteration 2); Person mit Freigaberecht darf Planungen auch bearbeiten und Rückfragen stellen (Product Owner 22.10.2026); Stories v0.1 erstellt.
Änderungen v0.4: Freigaberecht vergibt der Admin; MVP Kostenauswertung, CO2-Auswertung Iteration 1, Eingabe durch Tourenleitende Iteration 2 (Product Owner 22.10.2026).
Änderungen v0.3: Lizenz-Stichtag = erster Tag, Trainersatz für die ganze Tour; Freigabe durch Referent:innen mit delegierbarem Freigaberecht; Einreichungen auch für Kurse an tourenreferat@dav-leipzig.de; Einsatz bei Absage „abgesagt“; Ziel Ablösung des HTML-Formulars mit strukturierter Speicherung für Auswertungen (Product Owner 22.10.2026).
Änderungen v0.2: Kurse im Referat Ausbildung (Reichweite Touren und Ausbildung); Einsatz entsteht mit Status „in Yolawo angelegt“; Stichtag der Lizenz = letzter Tag der Tour bzw. des Kurses (Product Owner 22.10.2026).
Änderungen v0.1: Erster Entwurf. Quelle der fachlichen Felder, Formeln, Prüfungen und Texte ist prototyp-tourenkonzept.md (im Folgenden „Prototyp“, mit Abschnittsnummer). Diese Erhebung beschreibt nur, was sich gegenüber dem Prototyp ändert oder neu hinzukommt (Mehrbenutzer, Status, Personen, Einsatz, Abrechnung, Stammdaten).
**Hinweis (26.10.2026):** Die Kennzeichen [ANNAHME] in diesem Dokument hat der Product Owner mit spec.md v0.4 bestätigt oder dort anders entschieden; maßgeblich ist spec.md.

## A. Rechtevorlagen & Rechte

| Rechtevorlage | Reichweite | Lesen | Anlegen / Ändern | Status ändern | Löschen | Sätze pflegen (in der Administration) | Notfallkontakte lesen |
|---|---|---|---|---|---|---|---|
| Geschäftsstelle (TK verwalten) | alle | ja | ja | ja | ja (nur Status Entwurf oder abgesagt) [ANNAHME] | nein (nur Admin, Product Owner 22.10.2026) | ja |
| Referent:in (TK bearbeiten) | Referat: Touren (Führungs-, Gemeinschaftstouren), Ausbildung (Kurse) | Planungen des eigenen Referats | ja, nur eigenes Referat | ja, außer „freigegeben“ (nur mit Freigaberecht) | nein | nein | ja, eigenes Referat |
| Freigabe (TK freigeben) [ANNAHME: eigene Rechtevorlage; vergibt der Admin] | Referat | Planungen des Referats | ja, Planungen des Referats (Product Owner 22.10.2026) | alle Wechsel inkl. freigegeben und Rückfrage | nein | nein | ja, eigenes Referat |
| Admin (TK lesen) | alle | ja | nein | nein | nein | ja (in der Administration) | nein [ANNAHME] |
| Vorstand | – | Startwert ohne Rechte; Ziel lesen | – | – | – | – | nein |
| Tourenleitung | – | kein Zugang im MVP | – | – | – | – | – |

- Rechteprüfung in der Datenbank (RLS über `ad_has_level('TK', …)` und `ad_my_referate('TK', …)`), wie in der Anwesenheitserfassung [ANNAHME].
- Lizenzen der gewählten Leitenden lesen alle mit Lesezugriff auf die Planung, nur für Personen, die in einer lesbaren Planung als Leitung eingetragen sind, oder in der Auswahl (Name, Qualifikationsart, gültig bis; keine weiteren Eigenschaften) [ANNAHME].

## B. Abläufe (inkl. Zustände)

### B1 Planung anlegen
1. Referent:in legt eine Planung an: neu (leer) oder als Kopie einer früheren Planung [ANNAHME]. Einreichungen der Tourenleitenden (PDF per E-Mail) überträgt das Referat von Hand (Product Owner 22.10.2026).
2. Schritte wie im Prototyp (Abschnitt 2, Schritte 1–7). Abweichung Schritt 1: Leitung wird aus den Aktiven gewählt (B3), nicht frei eingetippt.
3. Seitenleiste mit Beitrag, CO2-Bilanz, Fortschritt und Hinweisen wie im Prototyp (Abschnitt 6.4).
4. Speichern jederzeit, auch unvollständig; Status „Entwurf“.

### B2 Einreichung übernehmen – nicht im Scope
PDF-Übernahme entfällt (Product Owner 22.10.2026): Die Ablösung des HTML-Formulars folgt bald in Iteration 2; bis dahin überträgt das Referat Einreichungen von Hand. Die folgenden Punkte bleiben nur als Referenz für eine spätere Übernahme alter Einreichungen.
1. Tourenleitung schickt das PDF aus dem HTML-Formular per E-Mail an tourenreferat@dav-leipzig.de, auch bei Kursen (unverändert, Prototyp Abschnitt 7.4; Product Owner 22.10.2026). Das Referat Touren übernimmt oder leitet Kurs-Einreichungen an das Referat Ausbildung weiter [ANNAHME].
2. Referent:in Touren wählt „Einreichung übernehmen“ und lädt das PDF hoch. Das System liest `DAVTK1:…:DAVTK1END` (Prototyp 7.5), prüft `format = "dav-leipzig-tourenkonzept"` und legt eine Planung im Status „eingereicht“ an. Die PDF-Datei wird nicht gespeichert [ANNAHME].
3. Für jede Zeile „Leitung und Helfende“ schlägt das System Personen mit gleichem Namen aus den Aktiven vor; Referent:in bestätigt die Zuordnung. Ohne Zuordnung bleibt die Zeile als Freitext stehen und wird mit Helfersatz gerechnet; Freigabe nur, wenn alle Leitenden zugeordnet sind [ANNAHME].
4. Lizenz und Lizenzjahr aus dem PDF werden mit dem Ehrenamtsmanagement verglichen; Abweichung als Hinweis.
5. Das System rechnet mit den eigenen Sätzen neu und zeigt Abweichungen zum Beitrag im PDF an.

### B3 Leitung wählen
- Suche über alle Aktiven (Ehrenamtsstatus „aktiv“, ab 2 Zeichen, nur Name) [ANNAHME, wie in der Anwesenheitserfassung].
- Nach der Auswahl: gültige Lizenzen der Person (Qualifikationsart, gültig bis, förderfähig ja/nein); Rolle Leitung, Co-Leitung oder Helfer:in.
- Satzart je Person: Trainer:in, wenn Rolle ≠ Helfer:in und eine förderfähige Lizenz am **ersten Tag** der Tour bzw. des Kurses gültig ist („gültig bis“ ≥ Startdatum); läuft die Lizenz während der Tour ab, gilt der Trainersatz für die ganze Tour, keine tageweise Rechnung (Product Owner 22.10.2026); sonst Helfer:in. Trainer:in auch, wenn die förderfähige Lizenz im Kalenderhalbjahr des Startdatums erworben wurde (gleiche Regel wie Finanzen, Product Owner 26.10.2026). Ersetzt die Regel „Lizenzjahr ≥ Tourjahr“ aus Prototyp 4.3. Beispiel: Lizenz gültig bis 30.10.2027 – Kurs am 15.10.2027 und Tour 29.10.–01.11.2027 Trainersatz, Kurs am 02.11.2027 Helfersatz.
- Person ohne Ehrenamtsstatus (z. B. externe Leitung): wird direkt aus der Planung als Aktive:r mit Funktion Helfer:in angelegt bzw. wieder aktiviert, wie beim Arbeitseinsatz der Anwesenheitserfassung, von allen mit TK bearbeiten (Product Owner 26.10.2026).
- Kontakt-E-Mail und Mobilnummer der Leitung: Vorschlag aus der Eigenschaft Kontaktdaten, je Planung änderbar [ANNAHME].

### B4 Zustände

| Von | Nach | Wer | Bedingung |
|---|---|---|---|
| – | Entwurf | Referent:in, Geschäftsstelle | neu oder Kopie |
| Entwurf | eingereicht | Referent:in, Person mit Freigaberecht, Geschäftsstelle | alle Pflichtangaben erfüllt (Prototyp 6.1) |
| eingereicht | Rückfrage | Referent:in, Person mit Freigaberecht, Geschäftsstelle | Kommentar Pflicht |
| Rückfrage | eingereicht | Referent:in, Person mit Freigaberecht, Geschäftsstelle | Änderung eingearbeitet |
| eingereicht | freigegeben | Referent:in des Referats oder Person mit delegiertem Freigaberecht im Referat (Product Owner 22.10.2026) | Pflichtangaben erfüllt; alle Leitenden Personen zugeordnet |
| freigegeben | in Yolawo angelegt | Referent:in, Geschäftsstelle | optional Yolawo-Link bzw. -Nummer [ANNAHME]; erzeugt den Einsatz (B5; Product Owner 22.10.2026) |
| freigegeben / in Yolawo angelegt | durchgeführt | System bzw. Referent:in | Anwesenheit im Einsatz bestätigt [ANNAHME] oder manuell nach dem Enddatum |
| durchgeführt | abgeschlossen | Geschäftsstelle | Abrechnung in Finanzen erledigt [ANNAHME] |
| jeder Status vor „durchgeführt“ | abgesagt | Referent:in, Person mit Freigaberecht, Geschäftsstelle | Grund Pflicht (z. B. Mindestteilnehmerzahl nicht erreicht); ein vorhandener Einsatz wird als „abgesagt“ markiert (B5) |

Jeder Wechsel mit „wer, wann, Kommentar“ im Verlauf. Nach „freigegeben“ ändern nur Referent:in des Referats, Person mit Freigaberecht und Geschäftsstelle; jede Änderung von Termin, Leitung oder Beitrag erscheint im Verlauf [ANNAHME].

### B5 Einsatz erzeugen (Anwesenheitserfassung)
- Beim Übergang auf „in Yolawo angelegt“ (Product Owner 22.10.2026) ruft TK eine Funktion der Anwesenheitserfassung auf (uebergabe-anwesenheitserfassung.md).
- Inhalt: Einsatzart `course` (Kurs) bzw. `tour` (Führungs- und Gemeinschaftstour), Referat der Planung, Titel (bis 90 Zeichen, ungekürzt), Abrechnungsart „Gemeinschaftstour“ bei Gemeinschaftstouren (Product Owner 26.10.2026), eintägig/mehrtägig, Datum bzw. Start- und Enddatum mit Beginn (Treffzeit) und Ende, Dauer-Kategorie bei eintägig aus der Dauer, organisierende Person = erste Person mit Rolle Leitung, Leitende und Helfende mit Rolle Trainer:in bzw. Helfer:in und Stand „eingetragen“.
- Rolle im Einsatz aus der Satzart (B3), nicht aus der Rolle Co-Leitung.
- Änderungen an Termin oder Leitung werden übertragen, solange kein Stand „anwesend“ gesetzt ist; danach Hinweis an Referent:in [ANNAHME].
- Absage: Der Einsatz wird als „abgesagt“ markiert, nicht gelöscht (Product Owner 22.10.2026); er zählt nicht für Abrechnung und Auswertung. Absage vor „in Yolawo angelegt“: kein Einsatz vorhanden.
- Teilnehmende kommen nicht aus TK (Anmeldung in Yolawo) [OFFEN: ob die Anwesenheitserfassung Teilnehmende bei Kurs und Tour überhaupt erfasst].

### B6 Abrechnung vorbefüllen (Finanzen)
- TK stellt je Planung lesend bereit: Personen mit Satzart, geplante Tage, Halbtage, Lehreinheiten, Organisationspauschale (Tage, Person), Plan-Kosten der Leitung (Positionen mit Menge und Einzelpreis), PKW-Begründung, Gesamtkosten, Beitrag.
- Finanzen nutzt diese Werte als Vorschlag und rechnet mit Ist-Werten (Anwesenheit aus der Anwesenheitserfassung, Belege). TK speichert keine Ist-Kosten.
- Hinweis aus dem Prototyp bleibt: Abrechnung innerhalb von 4 Wochen mit Originalbelegen; Erklärung zur Übungsleiterpauschale muss vorliegen (Nachweis „Bestätigung steuerfreie Einnahmen“ im Ehrenamtsmanagement) – TK zeigt fehlende Nachweise der Leitenden als Hinweis [ANNAHME].

### B7 Yolawo und Ausgaben
- Eingabeblatt, Ausschreibungstext, Zusammenfassung wie Prototyp 7.1–7.3; PDF-Export wie 7.5 ohne eingebettete Daten [ANNAHME: Einbettung nur für den Rückweg ins HTML-Formular nicht nötig].
- Ohne Stornoregel (R11).
- Status „in Yolawo angelegt“ manuell.

### B8 Notfallkontakte löschen
- Täglicher Job: Notfallkontakte von Planungen im Status „durchgeführt“, „abgeschlossen“ oder „abgesagt“ werden 30 Tage nach Enddatum bzw. Absage gelöscht (Product Owner 26.10.2026).

### B9 Auswertungen (Product Owner 22.10.2026)
- **MVP – Kosten:** Liste aller lesbaren Planungen mit Filter Jahr, Referat, Tourtyp, Status; je Planung und als Summe: Vergütung, Organisationspauschale, Kosten der Leitung, sonstige Kosten, Gesamtkosten, Beitrag Mitglieder, Mindest-/Höchstzahl, Ergebnis bei Mindest- und Höchstzahl, „Sektion trägt“ bei Touren ohne Beitrag [ANNAHME: Spalten]. Abgesagte Planungen ausblendbar. CSV-Export nur mit „verwalten“ [ANNAHME].
- **Iteration 1 – CO2:** Summen An- und Abreise, Unterkunft, Verpflegung, je Person; nach Jahr, Referat, Verkehrsmittel; Klimaschutzbudget. Die Daten dafür werden ab dem MVP vollständig erfasst und je Planung berechnet.
- **Iteration 2:** Eingabe durch Tourenleitende (öffentliche Integration oder Zugang), Ablösung des HTML-Formulars.

## C. Daten (Feld | Typ | Pflicht | Beispiel | Quelle)

Einzelfelder, Auswahllisten, Tabellen und Pflichtregeln der Planung: Prototyp Abschnitt 3.1–3.3 (unverändert übernommen, außer den Änderungen unten).

### C1 Planung (Änderungen und Ergänzungen zum Prototyp)

| Feld | Typ | Pflicht | Beispiel | Quelle |
|---|---|---|---|---|
| Referat | Verweis Referat | ja | Touren | neu (Reichweite) |
| Status | Auswahl (B4) | ja | eingereicht | neu |
| Verlauf | Liste (Status, wer, wann, Kommentar) | – | „Rückfrage: Hüttenreservierung bestätigt?“ | neu |
| Satzstand | Verweis auf die verwendeten Sätze (gültig ab) | ja | Sätze ab 01.01.2026 | neu (Prototyp 11.2) |
| Yolawo-Angebot | Text (Link oder Nummer) | nein | – | neu [ANNAHME] |
| Einsatz | Verweis Einsatz der Anwesenheitserfassung | nein | – | neu |
| Leitung und Helfende | Tabelle: Person (Verweis) oder Name (Freitext bis zur Zuordnung), Rolle, Satzart (berechnet), Qualifikation (Verweis auf Lizenz der Person, angezeigt) | mind. 1 Leitung | Vorname Nachname, Leitung, Trainer*in C Bergwandern bis 31.12.2028 | ersetzt `leaders[]` (Prototyp 3.2) |
| E-Mail / Mobilnummer der Leitung | Text | E-Mail ja | – | Prototyp `kontaktMail`, `kontaktTel`; Vorschlag aus Kontaktdaten |
| Notfallkontakt(e) | Name, Telefon je leitender Person | ja für die erste Leitung | – | Prototyp `notfall*`; strukturiert statt Freitext `notfallWeitere` [ANNAHME] |
| Bestätigungen c1–c4 | Ja/Nein | wie Prototyp | – | übernommen; c1 „Lizenzmarke und Ausweiskopie liegen vor“ wird mit dem Ehrenamtsmanagement geprüft statt bestätigt [OFFEN] |

### C2 Sätze und Annahmen (Stammdaten der Administration)

Sätze (Vergütungs- und Reisekostenordnung inkl. Organisationspauschale und Hüttenpauschalen), Zahlungsgebühren, Emissionsfaktoren, CO2-Preis und Grenzwerte sind Stammdaten der **Administration** mit „gültig ab“ und Quelle, pflegbar ohne Code-Änderung (Product Owner 22.10.2026); Pflege vorerst nur durch den Admin (Product Owner 22.10.2026); Geschäftsstelle oder Referent:innen später möglich; Finanzen nutzt dieselben Sätze (Product Owner 22.10.2026). Die Planungshilfe liest sie nur. Übergabe: uebergabe-administration.md v1.4.

| Feld | Typ | Pflicht | Beispiel | Quelle |
|---|---|---|---|---|
| Schlüssel | Text | ja | `rTL` | Prototyp 5.1 |
| Bezeichnung | Text | ja | Tagessatz Trainer/WL | Prototyp 5.1 |
| Wert | Zahl | ja | 50 | Prototyp 5.1 |
| Einheit | Text | ja | € | Prototyp 5.1 |
| Quelle | Text | ja | Vergütungsordnung 2025, Anhang 1 | Prototyp 5.1 |
| gültig ab | Datum | ja | 01.01.2026 [OFFEN: echte Gültigkeit] | neu |

Gleiche Struktur für Zahlungsgebühren (Zahlmethode, %, fix €, aktiv; Prototyp 5.2) und Emissionsfaktoren (Schlüssel, Bezeichnung, Faktor, Einheit, Quelle; Prototyp 5.3). Fest im Code bleiben nur Regeln, keine Beträge [ANNAHME]; die Grenzen 500 km, 1000 km Flug, 45–90 € Hüttenpreis werden ebenfalls Stammdaten [ANNAHME].

### C3 Zuordnung Qualifikationsart → Sportart

| Feld | Typ | Pflicht | Beispiel | Quelle |
|---|---|---|---|---|
| Qualifikationsart | Verweis | ja | Trainer*in C Bergwandern | AD |
| Sportart | Auswahl (Prototyp 3.1 `sportart`) | ja | Bergwandern | Prototyp 4.8 [ANNAHME, nicht vom Referat bestätigt] |

## D. Regeln

- R1: Berechnung von Tagen, Vorschlägen, Vergütung, Kosten, Teilnahmebeitrag, Überschuss, CO2, Kondition nach Prototyp 4.1–4.9; Beispielrechnung Prototyp 4.5 und 4.7 sind Abnahmekriterien.
- R2: Satzart Trainer:in nur mit förderfähiger Lizenz, die am Startdatum der Tour bzw. des Kurses gültig ist oder im Halbjahr des Startdatums erworben wurde, aus dem Ehrenamtsmanagement (B3); gilt dann für die ganze Tour; sonst Helfersatz mit Hinweis „Ohne gültige Lizenz wird der Helfersatz gerechnet“. Ohne erfasste Person wird nicht mehr mit einer Trainerperson gerechnet (ändert Prototyp 4.3 `nTL = 1`) [ANNAHME].
- R3: Jede gespeicherte Kalkulation verweist auf den Satzstand; ändern sich Sätze, rechnen Planungen bis „eingereicht“ mit dem neuen Stand neu, ab „freigegeben“ bleibt der Stand eingefroren [ANNAHME].
- R4: Gemeinschaftstour: keine Tagessätze, keine Lehreinheiten, keine Kosten der Leitung; die **Organisationspauschale wird nach Vergütungsordnung Ziff. 9.2 gezahlt** (Prototyp-Regel „keine Organisationspauschale“ war ein Fehler, Product Owner 22.10.2026); kein Teilnahmebeitrag, die Organisationspauschale trägt vorerst die Sektion (Product Owner 22.10.2026). Sonst wie Prototyp 4.9. Organisationstage wie bei Führungstouren (Prototyp 4.2).
- R11: Keine Stornoregel im System: Feld, Eingabeblatt-Zeile „Anmeldezeitraum & Rückerstattung → Stornoregeln“ und Ausschreibungszeile „Stornierung …“ entfallen (Product Owner 22.10.2026).
- R5: Standard „nur DAV-Mitglieder“; Nichtmitglieder nur mit Begründung (Prototyp 3.1 `auchNM`, `nmGrund`).
- R6: Prüfungen und Warnungen nach Prototyp 6.1–6.3; zusätzlich „Leitung ohne zugeordnete Person“ (blockiert Freigabe) und Hinweis „Lizenz läuft vor Tourbeginn ab“ (Helfersatz) bzw. „Lizenz läuft während der Tour ab – Verlängerung für künftige Touren nötig“ (Trainersatz bleibt).
- R7: Der Status „in Yolawo angelegt“ erzeugt genau einen Einsatz je Planung (B5); spätere Änderungen aktualisieren ihn (bis zur ersten Anwesenheit „anwesend“).
- R8: Notfallkontakte werden nach Frist automatisch gelöscht (B8) und erscheinen nicht in Yolawo-Texten, Listen oder Exporten außer dem PDF für das Referat.
- R10: Alle Angaben einer Planung werden strukturiert in Tabellen gespeichert (Planung, Leitung, Teilstrecken der Anreise, Kostenpositionen, Statusverlauf); keine Ablage als Datei oder JSON-Block. Grundlage für spätere Auswertungen (CO2, Einsätze, Kosten) (Product Owner 22.10.2026).
- R9: Titel max. 90 Zeichen (Prototyp); wird ungekürzt an die Anwesenheitserfassung übergeben (dort 1–90 Zeichen, Product Owner 24.10.2026).
- Kurs nach Lehreinheiten (spec.md R22): Kurse werden ein- und mehrtägig nur nach Lehreinheiten vergütet, ohne Tagessätze und ohne Organisationspauschale; Vorschlag der Lehreinheiten nur bei eintägigen Kursen, bei mehrtägigen ist die Angabe Pflicht (Product Owner 26.10.2026; ändert Prototyp 4.3).

## E. Schnittstellen

| Richtung | Partner | Inhalt | Art |
|---|---|---|---|
| ein | HTML-Formular „Tourenkonzept“ | Einreichung als PDF per E-Mail | manuell (Referat überträgt; Ablösung Iteration 2) |
| ein | Administration | Referate, Rechte, Namenssuche über Aktive, Lizenzen gewählter Personen | Datenbankfunktionen |
| ein | Ehrenamtsmanagement | Qualifikationen (Lizenz, gültig bis, förderfähig), Kontaktdaten der Leitung, Nachweise | über Funktionen der Administration |
| aus | Anwesenheitserfassung | Einsatz Kurs/Tour mit Leitung „eingetragen“ | Datenbankfunktion |
| ein | Anwesenheitserfassung | Stand „durchgeführt“ (Anwesenheit bestätigt) | Lesefunktion [ANNAHME] |
| aus | Finanzen | Planwerte als Vorbelegung der Abrechnung | Lesefunktion |
| aus | Yolawo | Eingabeblatt, Beschreibungstext | manuell kopieren |

## F. Datenschutz

- Kontakt- und Notfalldaten der Leitung: Zweck Freigabe, Abrechnung, Notfall während der Tour; Lesbarkeit nur Referent:in des Referats, Personen mit Freigaberecht und Geschäftsstelle; Notfallkontakte automatisch gelöscht (R8). Notfallkontakte sind Dritte: Hinweis an die Leitung, den Notfallkontakt zu informieren (Prototyp 8.3) bleibt im HTML-Formular und im System.
- Einreichungen per PDF: Das PDF wird nicht im Vereins OS gespeichert; E-Mails mit PDF liegen im Postfach tourenreferat@dav-leipzig.de [OFFEN: Löschung dort].
- Lizenzen sind Eigenschaften mit Lesestufe „alle mit Zugriff“; TK sieht sie nur für gewählte bzw. gesuchte Aktive – neuer Sichtbarkeitspfad, Eintrag im Verarbeitungsverzeichnis.
- Keine Daten von Teilnehmenden in TK (Anmeldung in Yolawo).
- Abfragen im Anmeldeformular (Prototyp 3.3) bleiben Datensparsamkeits-Hinweis („nur abfragen, was gebraucht wird“).
- Aufbewahrung der Planung: 5 Jahre nach Tourende [ANNAHME, wie rollen.md]; Kalkulation als Abrechnungsgrundlage ggf. länger (mit Finanzen klären).

## G. Nicht-funktional

- Mobil ab 375 px lesbar, Status änderbar; Kalkulation bearbeiten optimiert für Desktop [ANNAHME].
- Berechnungen in der Datenbank (gleiche Formeln wie im Browser), Ergebnis auf den Cent identisch zum Prototyp bei dessen Beispieldaten.
- PDF-Erzeugung im Browser, ohne externe Abrufe (wie Prototyp 8.5).
- Mengengerüst: ca. 50 Angebote je Jahr (Prototyp, Anhang 9) [ANNAHME].
- Keine zusätzlichen Betriebskosten.

## Offene Fragen (Frage | Wer klärt | bis wann)

| Frage | Wer klärt | bis wann |
|---|---|---|
| Wer setzt „in Yolawo angelegt“, wenn die Tourenleitung selbst anlegt? | Referat Touren | vor den Stories |
| Spalten und Summen der Kostenauswertung (Vorschlag in B9) bestätigen | Product Owner | bei Abnahme US-TK-20 |
| Iteration 2: öffentliches Formular ohne Login oder Zugang „nur eigene“ – noch anzuschauen | Product Owner | vor Iteration 2 |
| Gemeinschaftstour: Organisationspauschale später von Teilnehmenden zurückholen? (vorerst Sektion) | Product Owner | nach dem MVP |
| Löschfrist Notfallkontakte | Product Owner (Datenschutz) | vor der Spec |
| Externe Leitende ohne Ehrenamtsstatus | Product Owner | vor den Stories |
| Bestätigung c1 durch Prüfung im Ehrenamtsmanagement ersetzen? | Referat Touren | vor den Stories |
| Titel: kürzen auf 60 oder Feld in der Anwesenheitserfassung verlängern | Product Owner | vor der Spec |
| Annahmen des Prototyps (MwSt., Konditionsgrenzen, Technikstufen, Qualifikation → Sportart, Hüttenpreise) | Referat Touren | vor der Spec |
| Anmeldung von Fahrten (Kinder- und Jugendfahrten), Material der Sektion | Product Owner | vor dem Steckbrief v1.0 |
