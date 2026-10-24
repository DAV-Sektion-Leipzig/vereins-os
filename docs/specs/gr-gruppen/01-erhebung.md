# Erhebung: Gruppen

Datum: 24.10.2026 · Version 0.8.1 · Beteiligte: Toni Werner (Product Owner), Claude (Requirements Engineering)
Änderungen v0.8.1: Wortlaut der Ablehnung in R19 festgelegt (Product Owner, 24.10.2026).
Änderungen v0.8: Übergabe aus der Anwesenheitserfassung (uebergabe-gruppen.md v1.0, G6–G9) eingearbeitet: höchstens eine Trainingszeit je Gruppe und Wochentag (Product Owner, 24.10.2026); Verstoß wird abgelehnt statt Hinweis (B10, R19); Import bei zwei Zeiten am selben Wochentag (B9); `gr_group_roster` mit höchstens einer Trainingszeit (B11, C).
Änderungen v0.7: Übergabe aus der Anwesenheitserfassung (uebergabe-trainingszeiten.md v1.2) eingearbeitet: Tabelle `gr_training_times` statt Textfeld (B10, C, R18–R19); Lesefunktion `gr_group_roster` je Gruppe und Stichtag für die Anwesenheitserfassung (B11, R20); Import der Trainingszeit; Schnittstelle zur Anwesenheitserfassung.
Änderungen v0.6: Admin sieht in der Administration alle Personen, auch Teilnehmer:innen, Erziehungsberechtigte und Notfallkontakte, und pflegt ihre Personendaten (Name, Rufname, Geburtsdatum, Kontaktdaten, Mitgliedsnummer) zentral; Änderungen gelten in allen Modulen (Product Owner, 21.10.2026).
Änderungen v0.5: Mengengerüst (ca. 13 Gruppen, 150–200 Teilnehmer:innen); Löschlauf nach MVP, Datenmodell vorbereitet; Annahmen A1–A10 aus 02-stories.md bestätigt (Product Owner, 21.10.2026).
Änderungen v0.4: Teilnahme nur mit aktivem Vertrag anlegbar; nach Vertragsende sichtbarer Hinweis an der Teilnahme.
Änderungen v0.3: Vertragsende und Ende der Teilnahme entkoppelt; Feld „Teilnahme bis“ statt „Austrittsdatum“; Referat bestätigt; Import-Regel Adresse bestätigt.
Änderungen v0.2: Gesundheitsangaben Variante A, Trainer:innen lesen mit, Helfer:innen nie; Notfallkontakt-Spalten L–O; Fotoerlaubnis ja/nein; Vertrag je Teilnahme mit Kündigung; monatlicher Betrag.
Grundlage: 00-steckbrief.md v0.7, Bestands-Excel „Vorlage_Gruppe.xlsx“ (nur Spaltenüberschriften), glossar.md v1.5, rollen.md v1.0, tech-stack.md v0.6, spec.md Administration v0.7.1, Steckbrief Ehrenamtsmanagement v0.6, specs/ez-einsaetze/uebergabe-trainingszeiten.md v1.2, specs/ez-einsaetze/uebergabe-gruppen.md v1.0

## A. Rechtevorlagen & Rechte

Stufen nach rollen.md. Reichweite im MVP „alle“.

| Rechtevorlage | Gruppen | Gesundheitsangaben | Bankverbindung / Mandat | Bemerkung |
|---|---|---|---|---|
| Geschäftsstelle | verwalten | erfassen, lesen (MVP) | lesen, pflegen | E-Mail-Liste kopieren; Trainingszeiten pflegen |
| Admin | lesen [ANNAHME: Startwert] | nein | lesen | Risikomanagement. Zusätzlich in der Administration: alle Personen inkl. Teilnehmer:innen, Erziehungsberechtigte, Notfallkontakte sehen und deren Personendaten pflegen |
| Vorstand | kein Zugriff (Startwert); Admin vergibt „lesen“ | nein | lesen, sobald „lesen“ vergeben | z. B. Schatzmeister:in |
| Nutzer der Anwesenheitserfassung (EZ ≥ lesen; Referent:innen mit Reichweite Referat) | kein Recht auf Gruppen nötig; nur Lesefunktion `gr_group_roster` (B11) | nein | nein | nur Namen und Trainingszeit |
| Gruppenleitung (nach MVP) | Reichweite „Gruppe“: lesen; Teilnehmer:innen hinzufügen, als ausgeschieden markieren | lesen, nur eigene Gruppe | [OFFEN] | braucht Zugang für Aktive und Reichweite „Gruppe“ |
| Trainer:in (nach MVP) | Reichweite „Gruppe“: lesen [ANNAHME] | lesen, nur eigene Gruppe | [OFFEN] | auf Ausfahrten dabei |
| Helfer:in | – | nie | – | Product Owner, 21.10.2026 |

Regeln:
- Gesundheitsangaben sind nie über die Stufe „Gruppen lesen“ sichtbar; im MVP ab „Gruppen bearbeiten“; eigene RLS-Regel (D, R11). Hinweis: Erhält der Vorstand später „Gruppen bearbeiten“, sieht er sie mit; saubere Trennung erst mit Rechten je Objekt.
- Funktionen mit Gruppenbezug (Gruppenleitung, Trainer:in, Helfer:in) pflegt nur, wer „Gruppen bearbeiten“ hat; im Ehrenamtsmanagement sind sie nur lesbar.
- Trainingszeiten pflegt, wer „Gruppen bearbeiten“ hat; lesen alle mit „Gruppen lesen“ und über `gr_group_roster` die Nutzer der Anwesenheitserfassung.

## B. Abläufe (inkl. Zustände)

**B1 Gruppe anlegen, ändern, auflösen**
1. Geschäftsstelle legt Gruppe mit Name und Referat an; Trainingszeiten optional direkt im selben Dialog (B10).
2. Ändern jederzeit.
3. Auflösen: nur wenn keine aktive Teilnahme mehr besteht (R9); setzt „aufgelöst am“, beendet die Funktionen mit Gruppenbezug und offene Trainingszeiten zum selben Datum.

Zustände Gruppe: aktiv → aufgelöst. [ANNAHME] Wiederaufnehmen nicht vorgesehen.

**B2 Teilnehmer:in aufnehmen**
1. Geschäftsstelle öffnet die Gruppe, wählt „Teilnehmer:in hinzufügen“.
2. Suche nach vorhandener Person (auch Aktive, z. B. Jugendliche:r, die/der bereits Helfer:in ist) oder neu anlegen mit Dublettenwarnung.
3. Stammdaten erfassen bzw. ergänzen: Geburtsdatum, Adresse, Mitgliedsnummer.
4. Teilnahme mit Eintrittsdatum und Vertrag (B5) in einem Schritt anlegen; ohne Vertrag keine Teilnahme (R16).
5. Erziehungsberechtigte (B3), Notfallkontakte (B4), Fotoerlaubnis und Gesundheitsangaben erfassen. [ANNAHME] Die Vertragsinhaber:in (B3) muss vor dem Speichern des Vertrags existieren; der Dialog führt daher B3 vor B5.

Ist die Person bereits in einer anderen Gruppe, entsteht nur eine weitere Teilnahme mit eigenem Vertrag; Stammdaten, Erziehungsberechtigte, Notfallkontakte, Fotoerlaubnis und Gesundheitsangaben gelten für die Person und werden nicht erneut erfasst.

Zustände Teilnahme: aktiv → beendet („Teilnahme bis“ erreicht). Betrifft nur die Gruppe, nie die Mitgliedschaft in der Sektion.

**B3 Erziehungsberechtigte zuordnen**
1. Vorhandene Person suchen (z. B. Geschwisterkind hat dieselben Eltern; Elternteil ist Trainer:in) oder neu anlegen.
2. Zuordnung zur Teilnehmer:in; höchstens zwei (R3).
3. Adresse der Teilnehmer:in kann per Knopf „Adresse übernehmen“ von einer erziehungsberechtigten Person kopiert werden [ANNAHME: Kopie, keine Verknüpfung].

**B4 Notfallkontakte pflegen**
1. Erziehungsberechtigte Person als Notfallkontakt markieren oder weitere Person anlegen (Name, Telefon und/oder E-Mail).
2. Reihenfolge festlegen [ANNAHME: wer zuerst angerufen wird].

**B5 Vertrag erfassen**
Je Teilnahme genau ein Vertrag; zwei Gruppen = zwei Verträge = zwei Lastschriften. Laufzeit unbefristet, Abbuchung monatlich.
1. Vertrag zur Teilnahme anlegen: Vertragsinhaber:in (eine der erziehungsberechtigten Personen), Vertragsbeginn, Kontoinhaber:in, IBAN, Mandatsreferenz, Unterschriftsdatum, Verwendungszweck, Betrag.
2. IBAN wird beim Speichern geprüft (R5).

Zustände Vertrag: aktiv → gekündigt (Kündigungsdatum und Vertragsende gesetzt, Ende in der Zukunft) → beendet (Vertragsende erreicht). Vertragsende und „Teilnahme bis“ sind unabhängig (Product Owner, 21.10.2026).

**B6 Kündigung eines Vertrags / Ende einer Teilnahme**
1. Geschäftsstelle erfasst die Kündigung am Vertrag: Kündigungsdatum (Eingang) und Vertragsende.
2. Unabhängig davon setzt die Geschäftsstelle bei Bedarf „Teilnahme bis“ an der Teilnahme. [ANNAHME] Beim Erfassen des Vertragsendes fragt das System: „Endet auch die Teilnahme an der Gruppe?“ (Ja setzt dasselbe Datum, Nein lässt die Teilnahme offen).
3. Teilnahmen und Verträge in anderen Gruppen bleiben unverändert.
4. Finanzen sieht Vertragsende (Grundlage, um den Einzug zu beenden).
5. Ist das Vertragsende erreicht und die Teilnahme noch offen, zeigt Gruppe und Teilnehmer:in den Hinweis „Vertrag beendet am TT.MM.JJJJ – Teilnahme klären.“ (R17). Die Geschäftsstelle entscheidet: neuen Vertrag anlegen oder „Teilnahme bis“ setzen.

**B7 Gruppenleitung, Trainer:innen, Helfer:innen festlegen**
1. In der Gruppe Person aus den Aktiven auswählen (oder neu anlegen) und Funktion wählen: Gruppenleitung, Trainer:in, Helfer:in.
2. Gültig von (Pflicht), gültig bis (optional). Mehrere Personen je Funktion möglich.
3. Im Ehrenamtsmanagement erscheint die Funktion mit Bezug auf die Gruppe; dadurch ist die Person dort als Aktive:r sichtbar.

**B8 E-Mail-Liste kopieren**
1. In der Gruppe „E-Mail-Adressen kopieren“.
2. Ergebnis: E-Mail-Adressen der Erziehungsberechtigten aller aktiven Teilnahmen, ohne Dubletten, getrennt durch Semikolon, in die Zwischenablage.
3. Hinweis: „Bitte in Blindkopie (BCC) einfügen.“

**B9 Import der Bestands-Excel (einmalig, Skript)**
1. Excel wird eingefroren und vorab bereinigt.
2. Probelauf ohne Schreiben mit Prüfbericht: Zeilen ohne Vertragsdaten (R16), fehlende Pflichtfelder, ungültige IBAN, Dublettenverdacht über alle Tabellenblätter, nicht aufteilbare Namen, nicht lesbare Trainingszeit im Kopf.
3. Lauf gegen PROD durch den Product Owner [ANNAHME]; Entwicklung und Test nur mit fiktiver Datei in TEST.
4. Adresse der Teilnehmer:in wird von der ersten erziehungsberechtigten Person übernommen (bestätigt).
5. Trainingszeit aus dem Kopf (Freitext, z. B. „Mittwochs 18:00 bis 20:00“) wird in eine oder mehrere Trainingszeiten (Wochentag, Beginn, Ende, gültig von = Importdatum [ANNAHME]) überführt, je Wochentag höchstens eine (R19); nicht eindeutig lesbare Angaben stehen im Prüfbericht und werden nicht angelegt. Nennt der Kopf für denselben Wochentag zwei Zeiten, wird für diesen Wochentag keine Trainingszeit übernommen und das Tabellenblatt im Prüfbericht aufgeführt (v0.8) [OFFEN: nur dieser Wochentag entfällt oder die ganze Gruppe ohne Trainingszeit; Vorschlag: nur dieser Wochentag, Warnung ohne Abbruch].
6. Nacharbeit in der Oberfläche durch die Geschäftsstelle: Adressen prüfen, Trainingszeiten ergänzen, Gruppenleitung/Trainer:innen/Helfer:innen zuordnen.

**B10 Trainingszeiten pflegen (neu v0.7)**
1. In der Gruppe „Trainingszeit hinzufügen“: Wochentag, Beginn, Ende, gültig von (Vorschlag: heute), gültig bis (optional). Je Wochentag höchstens eine gültige Trainingszeit; mehrere Wochentage je Gruppe möglich (z. B. dienstags und donnerstags). Gibt es für den Wochentag im Gültigkeitszeitraum schon eine Trainingszeit, wird abgelehnt; geändert wird die bestehende mit „Ändern ab“ (R19, v0.8).
2. Ändern einer bestehenden Trainingszeit (z. B. neue Uhrzeit ab 01.01.2027): „Ändern ab“ mit Datum; das System setzt an der alten Trainingszeit „gültig bis“ auf den Vortag und legt eine neue mit „gültig von“ = Datum an (Historie, R19).
3. Beenden: „gültig bis“ setzen.
4. Anzeige: nur am heutigen Tag gültige Trainingszeiten; Historie aufklappbar.

**B11 Anwesenheitsliste für die Anwesenheitserfassung (neu v0.7)**
1. Die Anwesenheitserfassung ruft `gr_group_roster(group_id, date)` auf.
2. Rückgabe: Gruppe (Name, Referat), am Datum gültige Trainingszeit für den Wochentag (höchstens eine, v0.8), Teilnehmer:innen mit am Datum gültiger Teilnahme sowie Gruppenleitung, Trainer:innen und Helfer:innen mit am Datum gültiger Funktion – jeweils Person-ID, Vorname, Rufname, Nachname, Rolle.
3. Rechteprüfung in der Funktion (R20).

## C. Daten

**Gruppe** (`gr_groups`)

| Feld | Typ | Pflicht | Beispiel | Quelle |
|---|---|---|---|---|
| Name | Text | ja | Gruppe 1 | Excel F1 |
| Referat | Auswahl (Referate) | ja | Kinder und Jugend | Excel C1 „Jugendgruppe“ → Kinder und Jugend |
| aufgelöst am | Datum | nein | – | neu |

Das Textfeld „Trainingszeit“ entfällt (v0.7); Excel H1 wird beim Import nach `gr_training_times` überführt. Excel J1/K1 „Bedarf“ wird nicht übernommen (→ Anwesenheitserfassung, Iteration 2).

**Trainingszeit** (`gr_training_times`, neu v0.7)

| Feld | Typ | Pflicht | Beispiel | Quelle |
|---|---|---|---|---|
| Gruppe | Verweis | ja | Gruppe 1 | – |
| Wochentag | Zahl 1–7 (ISO, 1 = Montag) | ja | 3 (Mittwoch) | Excel H1 |
| Beginn | Uhrzeit | ja | 18:00 | Excel H1 |
| Ende | Uhrzeit | ja | 20:00 | Excel H1 |
| gültig von | Datum | ja | 01.09.2026 | Import: Importdatum [ANNAHME] |
| gültig bis | Datum | nein | – | neu |

**Teilnehmer:in** (Person + gruppenspezifische Angaben)

| Feld | Typ | Pflicht | Beispiel | Quelle |
|---|---|---|---|---|
| Vorname | Text | ja | Mia | Excel B (Person) |
| Nachname | Text | ja | Beispiel | Excel C (Person) |
| Geburtsdatum | Datum | ja | 14.05.2014 | Excel D |
| Alter | berechnet | – | 12 | Excel E (nicht gespeichert) |
| Mitgliedsnummer | Text | nein [ANNAHME] | 123456 | Excel F |
| Adresse: Straße und Hausnummer, PLZ, Ort | Text | ja | Musterweg 1, 04109 Leipzig | neu; Import: von erster erziehungsberechtigter Person übernommen |
| Fotoerlaubnis | Ja/Nein + Datum der letzten Änderung | ja, Standard „nein“ | ja, seit 01.09.2026 | Excel X |
| gesundheitliche Einschränkungen | Text (frei) | nein | – | Excel W; eigene Tabelle, eigene RLS |

**Teilnahme** (`gr_memberships`)

| Feld | Typ | Pflicht | Beispiel | Quelle |
|---|---|---|---|---|
| Gruppe | Verweis | ja | Gruppe 1 | Tabellenblatt |
| Person | Verweis | ja | Mia Beispiel | Zeile |
| Eintrittsdatum | Datum | ja | 01.09.2026 | Import: Vertragsbeginn [ANNAHME] |
| Teilnahme bis | Datum | nein | – | neu |

**Erziehungsberechtigte:r** (Person + Zuordnung `gr_guardians`)

| Feld | Typ | Pflicht | Beispiel | Quelle |
|---|---|---|---|---|
| Vorname | Text | ja | Jana | Excel G (ein Feld „Name Erziehungsb.“, muss geteilt werden) |
| Nachname | Text | ja | Beispiel | Excel G |
| Adresse | Text | ja | Musterweg 1, 04109 Leipzig | Excel H–I |
| Telefon | Text | nein [ANNAHME] | 0341 123456 | Excel J |
| E-Mail | Text | nein [ANNAHME] | jana@example.org | Excel K |
| Vertragsinhaber:in | Kennzeichen am Vertrag | – | ja | neu |

Höchstens zwei je Teilnehmer:in. Die Excel enthält nur eine Person je Zeile.

**Notfallkontakt** (`gr_emergency_contacts`)

| Feld | Typ | Pflicht | Beispiel | Quelle |
|---|---|---|---|---|
| Vorname, Nachname | Person (auch erziehungsberechtigte Person) | ja | Erika Beispiel | Excel L–O |
| Telefon | Text | eins von beiden | 0171 1234567 | Excel L–O |
| E-Mail | Text | eins von beiden | – | Excel L–O |
| Reihenfolge | Zahl | ja | 1 | neu [ANNAHME] |

**Vertrag** (`gr_contracts`)

| Feld | Typ | Pflicht | Beispiel | Quelle |
|---|---|---|---|---|
| Teilnahme | Verweis, eindeutig (ein Vertrag je Teilnahme) | ja | Mia – Gruppe 1 | Tabellenblatt + Zeile |
| Vertragsinhaber:in | Verweis Person | ja | Jana Beispiel | neu |
| Vertragsbeginn | Datum | ja | 01.09.2026 | Excel V |
| Kündigungsdatum | Datum | nein | 15.10.2026 | neu |
| Vertragsende | Datum | nein | 31.12.2026 | neu |
| Kontoinhaber:in | Text | ja | Jana Beispiel | Excel P |
| IBAN | Text, geprüft | ja | DE89 3704 0044 0532 0130 00 | Excel Q |
| Mandatsreferenz | Text, eindeutig | ja | GR-2026-0001 | Excel R |
| Unterschriftsdatum Mandat | Datum | ja | 28.08.2026 | Excel S |
| Verwendungszweck | Text | ja | Beitrag Jugendgruppe 1 | Excel T |
| Betrag je Monat | Dezimal (EUR) | ja | 15,00 | Excel U |

Excel Y „IBAN Korrekt“ wird nicht übernommen; die Prüfung erfolgt automatisch.

Import Excel L–O: Die Spalten haben keine Überschriften; jeder Notfallkontakt besteht aus Vorname, Nachname und Telefon oder E-Mail. Das Skript ordnet im Probelauf zu und listet nicht eindeutig zuordenbare Zellen im Prüfbericht.

**Funktion mit Gruppenbezug** (Eigenschaft im Personenmodell [ANNAHME])

| Feld | Typ | Pflicht | Beispiel | Quelle |
|---|---|---|---|---|
| Person | Verweis (Aktive) | ja | Toni Werner | neu (nicht in Excel) |
| Funktion | Auswahl: Gruppenleitung, Trainer:in, Helfer:in | ja | Trainer:in | neu |
| Gruppe | Verweis | ja | Gruppe 1 | neu |
| gültig von / bis | Datum | von: ja | 01.09.2026 – | neu |

**Rückgabe `gr_group_roster(group_id, date)`** (neu v0.7)

| Feld | Typ | Beschreibung |
|---|---|---|
| group_id, group_name, referat_id | uuid, Text, uuid | Gruppe |
| training_times | Liste (Beginn, Ende) | am Datum gültige Trainingszeit für den Wochentag des Datums, höchstens ein Eintrag (R19, v0.8); leer, wenn keine |
| person_id | uuid | Person |
| first_name, preferred_name, last_name | Text | nur Namen |
| role | Auswahl: participant, group_lead, trainer, helper | Teilnehmer:in bzw. Funktion in der Gruppe |

Ablage der Personenangaben [ANNAHME]: Vorname und Nachname in `ea_persons`; Geburtsdatum, Adresse, Telefon, E-Mail und Mitgliedsnummer als Eigenschaften im Personenmodell (ein Mensch wird nur einmal gepflegt, auch wenn er Aktive:r ist); alle gruppenspezifischen Angaben in `gr_`-Tabellen. Endgültig in der Spec.

## D. Regeln

- R1: Wenn eine aktive Gruppe mit gleichem Namen existiert, dann Fehlermeldung „Eine Gruppe mit diesem Namen gibt es bereits.“ [ANNAHME]
- R2: Wenn Vorname, Nachname, Geburtsdatum oder Adresse der Teilnehmer:in fehlen, dann Fehlermeldung „Bitte Vorname, Nachname, Geburtsdatum und Adresse angeben.“ Wenn die Teilnehmer:in unter 18 ist und keine erziehungsberechtigte Person hat, dann Hinweis „Bitte mindestens eine erziehungsberechtigte Person angeben.“ [ANNAHME: Hinweis, keine Sperre, wegen Import]
- R3: Wenn bereits zwei erziehungsberechtigte Personen zugeordnet sind, dann Fehlermeldung „Es können höchstens zwei erziehungsberechtigte Personen angegeben werden.“
- R4: Ein Vertrag hat genau eine:n Vertragsinhaber:in; sie/er muss erziehungsberechtigt für die Teilnehmer:in sein oder – bei Volljährigkeit – die Teilnehmer:in selbst. Sonst „Vertragsinhaber:in muss eine erziehungsberechtigte Person sein.“
- R5: Wenn die IBAN-Prüfsumme ungültig ist, dann Fehlermeldung „Die IBAN ist ungültig.“
- R6: Wenn die Mandatsreferenz bereits vergeben ist, dann Fehlermeldung „Diese Mandatsreferenz ist bereits vergeben.“
- R7: Ein Notfallkontakt braucht Telefon oder E-Mail; sonst „Bitte Telefon oder E-Mail angeben.“ Hat eine aktive Teilnahme keinen Notfallkontakt, dann Hinweis „Kein Notfallkontakt hinterlegt.“ in Gruppe und Teilnehmer:in [ANNAHME].
- R8a: Ein Vertrag gehört zu genau einer Teilnahme; je Teilnahme höchstens ein **aktiver oder gekündigter** Vertrag: „Für diese Teilnahme gibt es bereits einen Vertrag.“ Nach Vertragsende ist ein Folgevertrag möglich; beendete Verträge bleiben sichtbar (bestätigt, A7).
- R8b: Vertragsende und „Teilnahme bis“ sind unabhängig; keine automatische Kopplung. Beim Setzen des Vertragsendes Rückfrage nach B6 [ANNAHME].
- R8: Wenn „Teilnahme bis“ vor dem Eintrittsdatum liegt, dann „‚Teilnahme bis‘ darf nicht vor dem Eintrittsdatum liegen.“ (gleich für Vertragsende/-beginn).
- R9: Wenn eine Gruppe aktive Teilnahmen hat, dann kann sie nicht aufgelöst werden: „Die Gruppe hat noch aktive Teilnehmer:innen.“
- R10: Wenn eine Person bereits aktive Teilnahme an derselben Gruppe hat, dann „Diese Person ist bereits in der Gruppe.“
- R11: Gesundheitsangaben liest und schreibt im MVP nur, wer mindestens „Gruppen bearbeiten“ hat; nie über „Gruppen lesen“. Nach MVP zusätzlich lesen: Gruppenleitung und Trainer:innen der eigenen Gruppe; Helfer:innen nie. Durchsetzung per RLS auf eigener Tabelle.
- R12: Fotoerlaubnis ist standardmäßig „nein“; jede Änderung speichert Datum und ändernde Person.
- R13: Die E-Mail-Liste enthält nur Adressen der Erziehungsberechtigten aktiver Teilnahmen [ANNAHME: bei volljährigen Teilnehmer:innen deren eigene Adresse].
- R14: Funktionen mit Gruppenbezug können im Ehrenamtsmanagement nicht geändert werden; Meldung „Diese Funktion wird im Modul Gruppen gepflegt.“
- R15: Löschung 5 Jahre nach Ende der letzten Teilnahme bzw. des letzten Vertrags [ANNAHME]; eine Person wird nur gelöscht, wenn sie keine andere gültige oder aufbewahrungspflichtige Zugehörigkeit hat (Aktive:r, andere Gruppe, Erziehungsberechtigte:r eines anderen Kindes).
- R16: Wenn eine Teilnahme ohne Vertrag gespeichert werden soll, dann Fehlermeldung „Eine Teilnahme kann nur mit einem aktiven Vertrag angelegt werden.“ (Product Owner, 21.10.2026)
- R17: Wenn das Vertragsende einer offenen Teilnahme erreicht ist, dann Hinweis „Vertrag beendet am TT.MM.JJJJ – Teilnahme klären.“ in Gruppenliste und Detail; zusätzlich Filter „Teilnahme klären“ in der Gruppe [ANNAHME]. Kein automatisches Beenden der Teilnahme.
- **R18 (neu v0.7):** Wenn das Ende einer Trainingszeit nicht nach dem Beginn liegt, dann „Das Ende muss nach dem Beginn liegen.“; wenn „gültig bis“ vor „gültig von“ liegt, dann „‚Gültig bis‘ darf nicht vor ‚gültig von‘ liegen.“; Wochentag, Beginn, Ende und gültig von sind Pflicht: „Bitte Wochentag, Beginn, Ende und ‚gültig von‘ angeben.“
- **R19 (neu v0.7, geändert v0.8):** Trainingszeiten werden nicht überschrieben: Eine Änderung von Wochentag, Beginn oder Ende beendet die alte Trainingszeit zum Vortag und legt eine neue an. Je Gruppe und Wochentag gibt es an jedem Datum höchstens eine gültige Trainingszeit (keine zwei Trainingszeiten derselben Gruppe am selben Wochentag mit sich überschneidender Gültigkeit, unabhängig von der Uhrzeit); mehrere Wochentage bleiben möglich (Product Owner, 24.10.2026). Wenn Anlegen oder „Ändern ab“ das verletzt, dann wird abgelehnt: „Für diesen Wochentag gibt es in diesem Zeitraum bereits eine Trainingszeit. Bitte die bestehende mit ‚Ändern ab‘ anpassen.“ (Wortlaut Product Owner, 24.10.2026). Der frühere Hinweis auf Überschneidung entfällt (v0.8). [OFFEN: Gilt die Ablehnung auch, wenn das „gültig bis“ einer Trainingszeit nachträglich so verlängert wird, dass sie sich mit einer späteren am selben Wochentag überschneidet? Vorschlag: ja, gleiche Ablehnung.]
- **R20 (neu v0.7):** `gr_group_roster` liefert nur Namen und Rollen, nie Geburtsdatum, Kontaktdaten, Erziehungsberechtigte, Notfallkontakte, Verträge, Bankdaten, Gesundheitsangaben oder Fotoerlaubnis. Aufruf erlaubt, wenn der Nutzer `ad_has_level('GR','read')` oder `ad_has_level('EZ','read')` hat oder die Gruppe zu einem Referat aus `ad_my_referate('EZ','read')` gehört; sonst Fehler „Für diesen Bereich hast du keine Rechte.“ (Code `GR_ROSTER_FORBIDDEN`). Teilnahme gilt am Datum, wenn Eintrittsdatum ≤ Datum und („Teilnahme bis“ leer oder ≥ Datum); Funktionen und Trainingszeiten entsprechend über gültig von/bis.

## E. Schnittstellen

| Modul / System | Richtung | Daten | Stand |
|---|---|---|---|
| Administration | ↔ | Zugänge, Rechtevorlagen, `ad_has_level`, `ad_my_referate`, Personenmodell; zentrale Pflege der Personendaten aller Personen durch den Admin | Nachtrag RLS eingearbeitet (spec.md AD v0.7.1) |
| Ehrenamtsmanagement | ↔ | Personen (gemeinsam), Referate (→ Gruppen), Funktionen mit Gruppenbezug (Gruppen →, nur lesbar) | |
| Anwesenheitserfassung | Gruppen → | `gr_group_roster(group_id, date)`: Gruppe, Referat, gültige Trainingszeiten, Namen und Rollen zum Stichtag; Gruppen und Trainingszeiten als Vorschlag beim Erfassen eines Trainings | neu v0.7 (Übergabe v1.2); Anwesenheitserfassung wird nach Gruppen umgesetzt |
| Anwesenheitserfassung | → Gruppen (später) | Auslastung/Bedarf, Anzahl Trainings | Iteration 2 |
| Finanzen | Gruppen → | Teilnahme, Teilnahme bis, Vertrag (je Teilnahme), Kündigung, Mandat, Betrag je Monat, Bankverbindung | Finanzen liest; baut Vertragsübersicht und SEPA-Lastschrift (eine je Vertrag, monatlich) |
| Öffentlichkeitsarbeit | Gruppen → (später) | Fotoerlaubnis | nach MVP |
| Bestands-Excel | → Gruppen | einmaliger Import per Skript | Product Owner |
| Mitgliederverwaltung | keine | – | bewusst ohne Abgleich |

## F. Datenschutz

- **Betroffene:** Minderjährige Teilnehmer:innen, Erziehungsberechtigte, Notfallkontakte (Dritte).
- **Besondere Kategorie (Art. 9 DSGVO):** gesundheitliche Einschränkungen. Rechtsgrundlage: ausdrückliche Einwilligung der Erziehungsberechtigten [OFFEN: im Vertrag vorhanden?]. Eigene Tabelle, eigene RLS, nicht in E-Mail-Liste, nicht in Exporten, nicht in `gr_group_roster`, Zugriff minimal.
- **Rechtsgrundlage übrige Daten:** Vertrag (Art. 6 Abs. 1 b); Notfallkontakte ohne Vertragsbeziehung [OFFEN].
- **Fotoerlaubnis:** Einwilligung (Art. 6 Abs. 1 a), widerrufbar; Stand mit Datum.
- **Bankdaten:** sichtbar ab „Gruppen lesen“ (bewusst entschieden).
- **Gesamtübersicht des Admins:** Der Admin sieht in der Administration alle Personen mit ihren Personendaten, auch Kinder und Notfallkontakte (bewusst entschieden, 21.10.2026). Nicht über die Administration sichtbar: Gesundheitsangaben (eigene Tabelle, R11).
- **Anwesenheitserfassung:** Referent:innen und Geschäftsstelle sehen über `gr_group_roster` Namen der Teilnehmer:innen der Gruppen ihres Referats bzw. aller Gruppen (R20); Eintrag im Verarbeitungsverzeichnis.
- **Weitergabe:** E-Mail-Liste nur mit Hinweis auf Blindkopie; keine Rundmails aus dem System.
- **Löschung:** R15; Löschlauf nicht im MVP, Datenmodell vorbereitet (wie Ehrenamtsmanagement, Product Owner 21.10.2026). Vor Einführung klären: Abgleich mit gesetzlichen Aufbewahrungsfristen in Finanzen; Gesundheitsangaben direkt nach Ende der letzten Teilnahme löschen?
- **Backups:** enthalten Gesundheits- und Bankdaten; verschlüsselt (claude/prompts/prod-backup.md).
- **Import:** Echtdaten nur auf dem Rechner des Product Owners; nie im Repo, nie in TEST.
- **Verarbeitungsverzeichnis:** Eintrag „Gruppen Kinder und Jugend“ mit Zweck, Kategorien, Fristen, Zugriffsberechtigten.

## G. Nicht-funktional

- Mobil ab 375 px; Notfallkontakte einer Teilnehmer:in in höchstens zwei Schritten aus der Gruppe erreichbar, Telefonnummer als anklickbarer Link (`tel:`).
- Mengengerüst: ca. 13 Gruppen, 150–200 Teilnehmer:innen, dazu ca. 300 Erziehungsberechtigte und Notfallkontakte [ANNAHME]; Antwortzeit Gruppenübersicht und Gruppendetail < 1 s; `gr_group_roster` < 300 ms [ANNAHME]; keine Paginierung nötig.
- RLS auf jeder Tabelle; Tests (pgTAP) für jede Rechtevorlage, insbesondere: Gesundheitsangaben nicht lesbar mit „Gruppen lesen“; Teilnehmer:innen nicht sichtbar mit „Ehrenamtsmanagement lesen“; `gr_group_roster` liefert für Referent:innen nur Gruppen ihres Referats und nur Namen.
- Kosten: 0 €.
- Testdaten nur fiktiv (Seed), inkl. Kind in zwei Gruppen, Elternteil zugleich Trainer:in, Jugendliche:r zugleich Helfer:in, Gruppe mit zwei Trainingszeiten und einer geänderten Trainingszeit (Historie).

## Offene Fragen

| Frage | Wer klärt | bis wann |
|---|---|---|
| Bankdaten für Gruppenleitung und Trainer:innen nach MVP sichtbar? | Product Owner | vor Iteration Zugang Gruppenleitung |
| Ausdrückliche Einwilligung für Gesundheitsangaben im bestehenden Vertrag enthalten? | Product Owner | vor Go-live |
| Rechtsgrundlage für Notfallkontakte ohne Erziehungsberechtigung | Product Owner (Datenschutz) | vor Go-live |
| Beginn der 5-Jahres-Frist, gesetzliche Aufbewahrung Vertrags-/Mandatsdaten, Löschung Gesundheitsangaben | Product Owner mit Finanzen | vor Einführung des Löschlaufs (nach MVP) |
| Dublettenwarnung modulübergreifend ohne Datenpreisgabe | Claude (Spec) | spec.md |
| Ablehnung auch beim nachträglichen Verlängern von „gültig bis“ (R19)? | Product Owner | vor Umsetzung (Migration Gruppen) |
| Import: bei zwei Zeiten am selben Wochentag nur diesen Wochentag oder die ganze Gruppe ohne Trainingszeit (B9)? | Product Owner | vor Import (US-GR-16) |
