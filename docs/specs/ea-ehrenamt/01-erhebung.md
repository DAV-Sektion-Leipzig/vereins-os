# Erhebung: Ehrenamtsmanagement (EA)

Datum: 22.10.2026 · Version 0.5 · Status: Entwurf · Beteiligte: Toni Werner (Product Owner), Claude (Requirements Engineer)
Grundlage: 00-steckbrief.md v0.6, migration-aktivenliste.md v0.4, stammdaten-qualifikationsarten.md v0.2, specs/ad-administration/spec.md v0.9 (Kern bis v0.7.1, Nachträge v0.8/v0.9), specs/ez-einsaetze/uebergabe-ehrenamtsmanagement.md v1.2, glossar.md v1.5, tech-stack.md v0.6
Änderungen v0.5: R16 – Lauf in einer Transaktion für die ganze Datei (statt je Person); Testdaten über System-Eigenschaftsarten (Übergabe Ü3 an die Administration); Stories v0.1 erstellt.
Änderungen v0.4: Qualifikationsarten Erste Hilfe, Rettungsschwimmer (je 2 Jahre) und JDAV-Aufbaumodule (Lehrgang) für die erste Migration entschieden; Annahmen R4, R10, R11 und Lesestufen Nr. 12, 14 bestätigt; Art. 13 DSGVO für Personen aus Arbeitseinsätzen entschieden (Übergabe an die Anwesenheitserfassung).
Änderungen v0.3: Eigenschaftsart „Vereinbarung ehrenamtliche Tätigkeit“ (C2 Nr. 25); Statusdialog beim Ausscheiden (R7, R8) und Pflegerechte der Referent:innen (R12) bestätigt.
Änderungen v0.2: Bezeichnungen für „gültig von/bis“ je Eigenschaftsart (C2a, Übergabe an die Administration Ü1); Startwerte Funktion und Amt; Geburtsjahr in der Dublettenwarnung nur für Geschäftsstelle und Admin (Übergabe Ü2); drei offene Fragen erledigt.
Änderungen v0.1: Ersterstellung. Abgleich mit der Spec der Administration (Abschnitt 0); Entscheidungen des Product Owners vom 22.10.2026 zur Migration (Funktion aus Lizenz, ein Statuseintrag ab Stichtag, Feld „DOSB-Lizenz gültig bis“, Felder der Lizenz, Eingabe über bereinigte CSV, Fortbildungen je Jahr); Übergabe der Anwesenheitserfassung v1.2 (E1–E6) eingearbeitet.

Legende Lesestufen: **alle** = alle mit Zugriff auf das Ehrenamtsmanagement · **GST** = nur Geschäftsstelle und Admin · **vertr.** = vertraulich.

## 0. Abgleich mit der Administration

Datenmodell, Rechte und Sichtbarkeit des Personenmodells liegen in der Administration (spec.md AD). Das Ehrenamtsmanagement nutzt sie und ändert sie nicht.

| Thema | Festgelegt in der Administration | Aufgabe des Ehrenamtsmanagements |
|---|---|---|
| Person, Rufname, Ehrenamtsstatus mit Historie | `ea_persons`, `ea_volunteer_status_history` (T37) | Oberflächen, Statusdialog |
| Referate (7), Gremien (4) | `ea_referate`, `ea_gremien` mit Startbestand (T34); Pflege AD ≥ bearbeiten oder EA = verwalten | Pflegeseiten /ea/referate, /ea/gremien |
| Eigenschaftsarten mit Feldern, Kategorie, Lesestufe, Bezug, `system_key` | `ea_property_types`, `ea_property_fields`, `ea_save_property_type` (T35) | Startbestand der System-Eigenschaftsarten (C2); Pflegeseiten unter /ea |
| Eigenschaften mit Historie, Validierung je Feld | `ea_properties`, `ea_property_history`, Trigger (T36; R27, R28, R35–R38) | Anzeige, Pflege, Verlängern, Ablaufstatus |
| Sichtbarkeit, Lesestufen, Reichweite „Referat“ | R29–R34, R41, R42; Funktionen `ea_person_visible*`, `ea_property_readable/writable` (T38) | nur nutzen; keine eigenen Lesepfade |
| Status setzen, anlegen, reaktivieren | `ea_set_volunteer_status`, `ea_person_referate`, `ea_create_volunteer`, `ea_activate_person` (T39) | Dialoge und Abläufe (B3, B5, B6) |
| Dublettenwarnung | `ad_find_similar_persons` (R3, R40; T43), Komponente Dublettendialog (T49) | Aktionen „Wieder aktivieren“, „Ins Ehrenamtsmanagement übernehmen“ |
| Qualifikationsarten | `ad_qualification_types`, Startbestand 47, Seiten und Komponenten (T26–T30) | Einhängen unter /ea/qualifikationsarten; Ergänzung fehlender Arten für die Migration (C4) |
| Wiederverwendbare Komponenten | Eigenschaftsformular, Auswahlfeld Qualifikationsart, Dublettendialog (T46, T47, T49) | nutzen |
| Rechtevorlage Referent:in, Testzugänge, Seed 1–12 | T40, T48 | Abnahme mit diesen Zugängen |
| Namen und Lizenzen für andere Module | `ea_person_names`, `ea_search_active_persons` (v0.8), `ea_person_licenses` (v0.9) | `system_key` und Feldschlüssel passend festlegen (C2) |

Nicht in der Administration, also hier zu erheben: Oberflächen, Startbestand der System-Eigenschaftsarten, Ablaufstatus und Stichtagsliste, Migrationsskript.

## A. Rechtevorlagen & Rechte

| Rechtevorlage | Recht EA (Reichweite) | Darf im Ehrenamtsmanagement |
|---|---|---|
| Admin | verwalten (alle); dazu AD verwalten | alles wie Geschäftsstelle; liest zusätzlich Lesestufe „vertraulich“ (Pfad AD); legt vertrauliche Eigenschaftsarten an; führt die Migration aus |
| Geschäftsstelle | verwalten (alle) | alle Personen mit Ehrenamtsstatus inkl. ausgeschiedener; Lesestufen „alle“ und „GST“; Personen anlegen (auch ohne Referat), Eigenschaften pflegen, Status setzen; Eigenschaftsarten, Qualifikationsarten, Referate und Gremien pflegen; Gremium-Sichten; Stichtagsliste mit CSV-Export |
| Referent:in (gilt auch für Hüttenwart:innen) | bearbeiten (Referat) | Personen mit Status „aktiv“ oder „ruhend“ und heute gültiger Eigenschaft mit Bezug auf eines der eigenen Referate (R32 AD); Lesestufe „alle“; Personen anlegen nur mit erster Zuordnung zu einem eigenen Referat; Zuordnungen nur zu eigenen Referaten pflegen (R41 AD); übrige Eigenschaften der Lesestufe „alle“ pflegen [ANNAHME, siehe R12]; Status setzen (alle drei, Wirkung für die ganze Person); Stichtagsliste ohne Export |
| Vorstand | kein Zugriff | – (Startwert; Konfiguration durch den Admin nach MVP) |

Testzugänge: aus dem Seed der Administration (Admin, Geschäftsstelle, Rita Referentin – Referat Klettern, Vorstand). Kein zusätzlicher Testzugang nötig [ANNAHME].

## B. Abläufe

### B1 Aktive finden (Übersicht)
1. Nutzer öffnet „Ehrenamtsmanagement“. Die Übersicht zeigt Personen mit Status „aktiv“ und „ruhend“, die er lesen darf; Referent:innen standardmäßig gefiltert auf ihre Referate (entspricht der „Sicht je Referat“).
2. Suche über Vor-, Ruf- und Nachname. Filter: Ehrenamtsstatus, Referat, Funktion, Amt, Gremium (nur GST), Qualifikation (Qualifikationsart, optional Sparte), Ablaufstatus, „Trainer:in ohne gültige Lizenz“, „aktiv ohne Funktion oder Amt“ [ANNAHME].
3. Spalten: Name, Ehrenamtsstatus (mit „seit“), Referate, Funktionen und Ämter, Lizenzen (Kürzel), schlechtester Ablaufstatus.
4. Geschäftsstelle und Admin können „ausgeschieden“ im Statusfilter dazunehmen.

### B2 Person ansehen (Detail)
Kopf: Name, Rufname, Ehrenamtsstatus mit „seit“ und Historie. Darunter alle lesbaren Eigenschaften mit „sichtbar in“ = EA, gruppiert nach Kategorie; aktuelle oben, beendete als „beendet“; Historie je Eigenschaft aufklappbar. Qualifikationen mit Ablaufstatus. Gruppen-Funktionen nur lesen mit Hinweis „Diese Angabe wird im Modul Gruppen gepflegt.“ (R39 AD). Iteration 2: Einsätze der Person und „letzter Einsatz“ (E2).

### B3 Person anlegen
1. Eingabe Vorname, Nachname, optional Rufname, dazu die erste Zuordnung (Funktion oder Amt mit Referat). Für Referent:innen Pflicht und nur eigene Referate; für Geschäftsstelle und Admin optional (z. B. nur Gremium).
2. Dublettenprüfung (`ad_find_similar_persons`). Bei Treffern Dialog mit Aktionen je Treffer: „Vorhandene Person öffnen“ (sichtbar), „Wieder aktivieren“ (ausgeschieden), „Ins Ehrenamtsmanagement übernehmen“ (ohne Ehrenamtsstatus, z. B. nur aus Gruppen), dazu „Trotzdem anlegen“ und „Abbrechen“.
3. Speichern über `ea_create_volunteer`: Person mit Status „aktiv“ ab heute (Product Owner 22.10.2026). Danach öffnet sich das Detail.

### B4 Eigenschaft pflegen
- Hinzufügen und Ändern über das Eigenschaftsformular der Administration; Beenden setzt „gültig bis“.
- **Lizenz neu:** „gültig bis“ wird vorbelegt mit dem 31.12. des Jahres „Jahr von ‚gültig von‘ bzw. ‚letzte Fortbildung‘ + Gültigkeitsdauer der Qualifikationsart“; änderbar (R5).
- **Lizenz verlängern:** Aktion an einer Lizenz. Neuer Eintrag mit derselben Qualifikationsart und Lizenznummer, neuem „gültig bis“ und „letzte Fortbildung“; der alte Eintrag endet am Vortag (R6). Optional wird zugleich eine Fortbildung angelegt [ANNAHME].
- Weitere Qualifikationen (Zusatzqualifikation, Lehrgang, Weiterbildung, Aufbaumodul) ebenso; „gültig bis“ nur, wenn die Qualifikationsart eine Gültigkeitsdauer hat.

### B5 Ehrenamtsstatus ändern
1. Aktion „Status ändern“ mit neuem Status und Datum (Standard heute).
2. Ist die Person über Funktion oder Amt weiteren Referaten zugeordnet (außer denen des Nutzers), nennt der Dialog diese (`ea_person_referate`) und verlangt eine Bestätigung (R7).
3. Bei „ausgeschieden“ zusätzlich (R8):
   - laufende Funktionen, Ämter und Gremium-Mitgliedschaften, die der Nutzer ändern darf, sind zum Beenden zum selben Datum vorausgewählt (abwählbar); andere werden nur genannt;
   - Gruppen-Funktionen werden nur genannt („im Modul Gruppen beenden“);
   - Ausgaben ohne „zurückgegeben“ und laufende Zugänge extern werden als Hinweis gezeigt (keine Aktion).
4. Speichern: `ea_set_volunteer_status`, danach die gewählten Eigenschaften beenden.

### B6 Rückkehr
- Ruhend → aktiv: über „Status ändern“.
- Ausgeschieden → aktiv: Geschäftsstelle und Admin über „Status ändern“; Referent:innen über die Dublettenwarnung beim Anlegen („Wieder aktivieren“ mit Zuordnung zu einem eigenen Referat, `ea_activate_person`). Historie bleibt.

### B7 Ablauf überwachen
- Markierung an jeder Qualifikation mit „gültig bis“ und an der Führungszeugnis-Einsicht (R9, R10).
- Filter „Ablaufstatus“ in der Übersicht.
- Stichtagsliste (R11): Seite „Ablauf im Jahr …“ mit allen Qualifikationen, deren „gültig bis“ im gewählten Jahr liegt (Standard: Folgejahr), jederzeit aufrufbar; CSV-Export nur Geschäftsstelle und Admin.

### B8 Gremium-Sichten (nur Geschäftsstelle und Admin)
Je Gremium Liste der heute gültigen Mitgliedschaften mit Rolle, seit, bis; Pflege über das Personendetail.

### B9 Stammdaten pflegen (Geschäftsstelle, Admin)
- Eigenschaftsarten: Seiten der Administration unter /ea/eigenschaftsarten eingehängt [ANNAHME]; System-Eigenschaftsarten (C2) sind änderbar wie andere (Felder ergänzen, Auswahlwerte ergänzen), `system_key` nicht.
- Qualifikationsarten: /ea/qualifikationsarten (AD).
- Referate und Gremien: Bezeichnung, Reihenfolge, aktiv/inaktiv; kein Löschen.

### B10 Migration der Aktivenliste (einmalig, Admin)
1. Product Owner friert die Excel-Liste zum Stichtag ein und überträgt sie in die bereinigte CSV-Vorlage (C3). Grundlage für die Übertragung: migration-aktivenliste.md.
2. Probelauf ohne Schreiben gegen PROD: Prüfbericht (R16).
3. Korrektur der CSV, erneuter Probelauf.
4. Lauf gegen PROD durch den Admin (lokal, Schlüssel mit vollen Rechten, ohne Nutzerkontext).
5. Excel-Liste wird archiviert und nicht mehr genutzt.

### Zustände

Ehrenamtsstatus: siehe spec.md AD Abschnitt 4 (aktiv, ruhend, ausgeschieden; kein Zurück auf „kein Status“).

Ablaufstatus einer Qualifikation (berechnet, nicht gespeichert):

| Ablaufstatus | Bedingung (heute = Stichtag der Anzeige) |
|---|---|
| gültig | „gültig bis“ > heute + 3 Monate |
| läuft in ≤ 3 Monaten ab | heute ≤ „gültig bis“ ≤ heute + 3 Monate |
| abgelaufen | „gültig bis“ < heute |
| ohne Ablauf | kein „gültig bis“ |

Nur für aktuelle Eigenschaften (nicht beendet) von Personen mit Status „aktiv“ oder „ruhend“.

## C. Daten

### C1 Person
Aus der Administration: Vorname (Pflicht), Nachname (Pflicht), Rufname, Ehrenamtsstatus mit „seit“, `created_in`. Keine weiteren Spalten.

### C2 System-Eigenschaftsarten (Startbestand per Migration des Ehrenamtsmanagements)

Alle: `origin = 'system'`, Zweck wie angegeben, „sichtbar in“ mindestens AD und EA. `system_key` nur per Migration. Felder in der Form `schlüssel` (Bezeichnung, Typ, Pflicht). „gültig von/bis“ ist die Gültigkeit der Eigenschaft (Administration); wo kein eigenes Datumsfeld genannt ist, steht dort das Datum des Ereignisses (z. B. ausgegeben am = gültig von, zurückgegeben am = gültig bis). Die Oberfläche zeigt dafür die Bezeichnungen aus C2a (Entscheidung 22.10.2026).

| Nr | Eigenschaftsart | system_key | Kategorie | Lesestufe | Bezug | mehrfach | Felder | Zweck | Quelle |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Mitglied | `member` | Stammdaten | alle | – | nein | `is_member` (Mitglied, Ja/Nein, Pflicht); `member_number` (Mitgliedsnummer, Text) | Abgleich mit der Mitgliederverwaltung | D |
| 2 | Geburtsdatum | `birth_date` | Stammdaten | GST | – | nein | `date` (Geburtsdatum, Datum, Pflicht) | Lizenzanträge | AE |
| 3 | Geschlecht | `gender` | Stammdaten | GST | – | nein | `gender` (Geschlecht, Auswahl: weiblich, männlich, divers, keine Angabe, Pflicht) | Lizenzanträge, korrekte Ansprache | neu |
| 4 | Kontaktdaten | `contact` | Kontakt | alle | – | nein | `email` (E-Mail, Text); `phone_mobile` (Telefon mobil, Text); `phone_landline` (Telefon Festnetz, Text); `street` (Straße und Hausnummer, Text); `postal_code` (PLZ, Text); `city` (Ort, Text); `dav_email` (DAV-E-Mail-Adresse, Text) | Erreichbarkeit | Z, AA, AB, AC, AQ |
| 5 | Bankverbindung | `bank_account` | Stammdaten | GST | – | nein | `account_holder` (Kontoinhaber:in, Text, Pflicht); `iban` (IBAN, Text, Pflicht, Prüfung R13) | Trainerabrechnung (Modul Finanzen) | AD |
| 6 | Funktion | `function` | Zuordnung | alle | Referat (optional) | ja | `function` (Funktion, Auswahl: Trainer:in, Helfer:in, Pflicht); `training_units_per_week` (Trainingseinheiten pro Woche, Zahl) | Zuordnung zu Referaten | I, J, BO |
| 7 | Amt | `position` | Zuordnung | alle | Referat (optional) | ja | `position` (Amt, Auswahl: Referent:in, stellv. Referent:in, Hüttenwart:in, Pflicht) | Gewählte Verantwortung; Amtszeit = gültig von/bis | – |
| 8 | Gremium | `committee` | Zuordnung | alle | Gremium (Pflicht) | ja | `role` (Rolle, Auswahl: Mitglied, Vorsitz [ANNAHME], Pflicht) | Zusammensetzung der Gremien | AS |
| 9 | Lizenz | `license` | Qualifikationen | alle | – | ja | `qualification_type` (Qualifikationsart, nur Typ Lizenz, Pflicht); `valid_until` (gültig bis, Datum, Pflicht); `license_number` (Lizenznummer, Text); `dosb_valid_until` (DOSB-Lizenz gültig bis, Datum); `last_training` (letzte Fortbildung, Datum). gültig von = erworben bzw. verlängert am | Nachweis der Trainerlizenz; Vergütung (förderfähig) | F, L1–L3 |
| 10 | Qualifikation | `qualification` | Qualifikationen | alle | – | ja | `qualification_type` (Qualifikationsart, Typen Zusatzqualifikation, Lehrgang, Weiterbildung, Pflicht); `valid_until` (gültig bis, Datum); `detail` (Angabe, Text, z. B. Stufe Rettungsschwimmer). gültig von = erworben am | Weitere Befähigungen | AT, BJ, BK |
| 11 | Fortbildung | `further_training` | Qualifikationen | alle | – | ja | `year` (Jahr, Jahr, Pflicht); `title` (Titel, Text, Pflicht); `qualification_type` (verlängerte Lizenz, Qualifikationsart, nur Typ Lizenz). gültig von = Datum der Fortbildung | Fortbildungspflicht | AU–BF |
| 12 | Trainer- und Jugendleiterausweis | `id_card` | Nachweise | alle | – | ja | `card_number` (Ausweisnummer, Text, Pflicht); `copy_available` (Kopie liegt vor, Ja/Nein) | Lizenzanträge Landes- und Stadtsportbund | G, Y |
| 13 | Führungszeugnis-Einsicht | `police_clearance` | Nachweise | GST | – | nein | `issued_on` (Ausstellungsdatum, Datum, Pflicht). gültig von = eingesehen am | Kinderschutz; Erneuerung alle 3 Jahre | BI |
| 14 | Ehrenkodex | `code_of_conduct` | Nachweise | alle | – | nein | `signed` (unterschrieben, Ja/Nein, Pflicht). gültig von = unterschrieben am | Kinderschutz | AH |
| 15 | Trainervereinbarung | `trainer_agreement` | Nachweise | GST | – | nein | `signed` (unterschrieben, Ja/Nein, Pflicht). gültig von = unterschrieben am | Trainerabrechnung | AI |
| 16 | Bestätigung steuerfreie Einnahmen | `tax_free_confirmation` | Nachweise | GST | – | ja | `year` (für Jahr, Jahr). gültig von = abgegeben am | Voraussetzung der Übungsleiterpauschale (E4) | neu |
| 17 | Erklärung zur Ehrenamtspauschale | `volunteer_allowance_declaration` | Nachweise | GST | – | ja | `year` (für Jahr, Jahr, Pflicht). gültig von = abgegeben am | Voraussetzung der Ehrenamtspauschale (E4) | neu |
| 18 | Jugendleiter- und Trainermarke | `license_stamp` | Jahreseinträge | alle | – | ja | `year` (Jahr, Jahr, Pflicht). gültig von = ausgegeben am | Gültigkeit des Ausweises | X |
| 19 | Förderung | `funding` | Jahreseinträge | GST | – | ja | `year` (Jahr, Jahr, Pflicht); `applied` (beantragt, Ja/Nein, Pflicht); `funder` (Fördergeber, Text) | Förderanträge | K, L |
| 20 | Ausgabe | `issued_item` | Ausgaben | alle | – | ja | `item` (Gegenstand, Auswahl: Schlüssel NoLimit, Schlüssel K4, K4-Karte, Jahreskarte, Vereinsjacke, Pflicht); `number` (Nummer, Text); `year` (Jahr, Jahr, bei Jahreskarte). gültig von = ausgegeben am, gültig bis = zurückgegeben am | Rückgabe beim Ausscheiden | AJ, AK, AL, BG, BH, BM |
| 21 | Ehrenamtspass | `volunteer_pass` | Ausgaben | alle | – | ja | `valid_until` (gültig bis, Datum). gültig von = ausgegeben am | Vergünstigungen für Ehrenamtliche | BN |
| 22 | Zugang extern | `external_access` | Zugänge | alle | – | ja | `system` (System, Auswahl: DAV360, Forms, JDAV Aktiven-Mailverteiler, Redaktion, Mailingliste, Pflicht). gültig von/bis = seit/bis | Entzug beim Ausscheiden | AM, AN, AO, AP, BL |
| 23 | Auszeichnung | `award` | Sonstiges | alle | – | ja | `kind` (Art, Text, Pflicht). gültig von = Datum | Ehrungen | BP |
| 24 | Hauptamt | `employment` | Sonstiges | vertr. | – | ja | `title` (Bezeichnung, Text, Pflicht); sichtbar nur in AD | Zuordnung der hauptamtlich Beschäftigten | – |
| 25 | Vereinbarung ehrenamtliche Tätigkeit | `volunteer_agreement` | Nachweise | GST | – | nein | `signed` (unterschrieben, Ja/Nein, Pflicht). gültig von = unterschrieben am | Voraussetzung der Ehrenamtspauschale (E4) | neu |

Hinweise:
- Nr. 4 `email`, Nr. 6 `function` mit Wert „Helfer:in“ und Bezug Referat, Nr. 9 `qualification_type` und `valid_until` sind die Schlüssel, die die Nachträge v0.8 und v0.9 der Administration voraussetzen (`ea_create_volunteer`, `ea_person_licenses`).
- Nr. 6–8 sind getrennte Arten, weil jede Eigenschaftsart genau einen Bezug hat (W1). Gruppen-Funktionen legt das Modul Gruppen als eigene Art an.
- Nr. 11 verweist auf die Qualifikationsart der verlängerten Lizenz statt auf die Lizenz-Eigenschaft (W2; das Modell kennt keinen Verweis zwischen Eigenschaften).
- Nr. 2–5, 13, 15–17, 19, 25 mit Lesestufe GST; Nr. 12, 14 „alle“ (Product Owner 22.10.2026).
- Kategorie „Stammdaten“ für Bankverbindung statt „Kontakt“ [ANNAHME].

### C2a Bezeichnungen für „gültig von / gültig bis“

Je Eigenschaftsart optional zwei Bezeichnungen (höchstens 40 Zeichen); leer = „gültig von“ bzw. „gültig bis“. Pflege im Formular der Eigenschaftsart. Setzt Ü1 der Übergabe an die Administration voraus.

| Nr | Eigenschaftsart | gültig von | gültig bis |
|---|---|---|---|
| 1 | Mitglied | seit | bis |
| 6, 8 | Funktion, Gremium | seit | bis |
| 7 | Amt | Amtszeit von | Amtszeit bis |
| 9, 10 | Lizenz, Qualifikation | erworben bzw. verlängert am | beendet am |
| 11 | Fortbildung | Datum | – |
| 12 | Trainer- und Jugendleiterausweis | ausgestellt am | ungültig ab |
| 13 | Führungszeugnis-Einsicht | eingesehen am | – |
| 14, 15, 25 | Ehrenkodex, Trainervereinbarung, Vereinbarung ehrenamtliche Tätigkeit | unterschrieben am | beendet am |
| 16, 17 | Nachweise der Vergütungsordnung | abgegeben am | – |
| 18, 21 | Marke, Ehrenamtspass | ausgegeben am | – |
| 20 | Ausgabe | ausgegeben am | zurückgegeben am |
| 22, 24 | Zugang extern, Hauptamt | seit | bis |
| 23 | Auszeichnung | verliehen am | – |

„–“ = Standardbezeichnung. Übrige Arten (2–5, 19) ohne eigene Bezeichnung.

### C3 Eingabe der Migration (bereinigte CSV)

Eine Zeile je Person, UTF-8, Trennzeichen Semikolon, Datum TT.MM.JJJJ, leere Zelle = keine Angabe. Der Product Owner überträgt die Excel-Liste in diese Vorlage (Entscheidung 22.10.2026). Die Vorlage selbst (nur Kopfzeile) liegt im Repository; befüllte Dateien nie.

| Spalten | Inhalt | Ziel |
|---|---|---|
| `nachname`, `vorname`, `rufname` | Pflicht, Pflicht, optional | Person |
| `aktiv` | ja / nein | Status „aktiv“ bzw. „ruhend“ ab Stichtag (ein Eintrag, Entscheidung 22.10.2026) |
| `aktiv_seit` | Datum | gültig von der Funktion; leer → Stichtag |
| `referate` | Namen der Referate, getrennt durch „,“ | je Referat eine Funktion (R15) |
| `te_pro_woche` | Zahl | Feld an der Funktion Trainer:in |
| `mitgliedsnummer` | Text | Mitglied (ja, wenn gefüllt) |
| `geburtsdatum`, `geschlecht` | Datum; weiblich/männlich/divers/keine Angabe | Nr. 2, 3 |
| `email`, `telefon_mobil`, `telefon_festnetz`, `strasse`, `plz`, `ort`, `dav_email` | Text | Nr. 4 (Adresse bereits zerlegt) |
| `kontoinhaber`, `iban` | Text | Nr. 5 |
| `l1_art`, `l1_nummer`, `l1_gueltig_bis`, `l1_dosb_gueltig_bis`, `l1_letzte_fb`, `l1_erworben_am`; ebenso `l2_*`, `l3_*` | Kürzel der Qualifikationsart (oder Bezeichnung aus der Zuordnungstabelle), Text, Datum … | je Lizenz eine Eigenschaft Nr. 9; `erworben_am` leer → Stichtag |
| `qualifikationen` | Liste „Kürzel:Datum:gültig bis:Angabe“, getrennt durch „,“ | je Eintrag Nr. 10 (Aufbaumodule, Erste Hilfe, Rettungsschwimmer, Zusatzqualifikationen) |
| `fb_vor_2016`, `fb_2016` … `fb_2026` | Freitext 1:1 | je gefüllter Zelle Nr. 11 (Jahr = Spaltenjahr; „vor 2016“ → 2015 mit Titelzusatz „vor 2016“); gültig von = 01.01. des Jahres |
| `ausweis_nr`, `ausweis_kopie` | Text; ja/nein | Nr. 12 |
| `fz_ausgestellt`, `fz_eingesehen` | Datum | Nr. 13 (eingesehen leer → Stichtag, Prüfbericht) |
| `ehrenkodex`, `trainervereinbarung` | Datum | Nr. 14, 15 |
| `marke_<jahr>`, `foerderung_<jahr>`, `jahreskarte_<jahr>` | Datum; ja/nein; Datum | Nr. 18, 19, 20 |
| `ehrenamtspass_ausgegeben`, `ehrenamtspass_gueltig_bis` | Datum | Nr. 21 |
| `schluessel_nolimit`, `schluessel_k4`, `k4_karte`, `vereinsjacke` | Nummer oder „x“; optional `<spalte>_am` (Datum) | Nr. 20; ohne Datum gültig von = Stichtag |
| `dav360`, `forms`, `jdav_verteiler`, `redaktion`, `mailingliste` | „x“ oder Datum seit | Nr. 22 |
| `jugendausschuss` | ja/nein; optional `jugendausschuss_seit` | Nr. 8 (Gremium Jugendausschuss, Mitglied) |
| `auszeichnung_art`, `auszeichnung_datum` | Text; Datum | Nr. 23 |
| `gruppe`, `gruppenleitung` | Text | nur Prüfbericht (Gruppen-Import) |

Nicht übernommen: „Anmerkung“, „nächste FB“, „Stufe laut Vereinsportal“, „Jahr Kurs-verlängerung“ (Entscheidung 22.10.2026: Lizenz ohne Altfelder).

### C4 Qualifikationsarten für die Migration
Das Skript akzeptiert in `l*_art` und `qualifikationen` jedes Kürzel aus `ad_qualification_types`, auch historische (Altbestand, R27 AD). Die erste Migration des Ehrenamtsmanagements legt zusätzlich an (idempotent über die Bezeichnung, ohne Überschreiben; Entscheidung Product Owner 22.10.2026):

| Kürzel | Bezeichnung | Sparte | Typ | Gültigkeitsdauer | Aussteller | Hinweis |
|---|---|---|---|---|---|---|
| EH | Erste Hilfe (mind. 9 UE) | Allgemein | Weiterbildung | 2 | extern | Voraussetzung DAV-Ausweis (stammdaten-qualifikationsarten.md R5) |
| RS | Rettungsschwimmer | Allgemein | Weiterbildung | 2 | extern | Stufe im Feld „Angabe“ |
| AMAK, AMBS, AMHT, AMKS, AMMB, AMSB, AMSH, AMSK | JDAV-Aufbaumodul Alpinklettern, Bergsteigen, Hochtouren, Klettersteig, Mountainbike, Skibergsteigen, Skihochtouren, Sportklettern | Jugend und Familie | Lehrgang | – | Bundesverband (JDAV) | glossar.md „Aufbaumodul“ |

[ANNAHME] Kürzel, Sparte „Allgemein“ (neuer Wert; Sparte ist Text mit Vorschlägen, AD) und Aussteller „extern“ wie vorgeschlagen. Die acht Aufbaumodule sind je eine Qualifikationsart (Kürzel in der Reihenfolge der Bezeichnungen).

## D. Regeln

Regeln der Administration gelten unverändert (R1–R42 AD). Zusätzlich:

- R1: Die Übersicht zeigt standardmäßig Status „aktiv“ und „ruhend“; „ausgeschieden“ nur auf Wunsch und nur mit EA = verwalten (R34 AD).
- R2: Anzeige der Namen „Rufname Nachname“, sonst „Vorname Nachname“ (AD).
- R3: Personen anlegen: Referent:innen nur mit erster Zuordnung (Funktion oder Amt) zu einem eigenen Referat; sonst „Bitte eine Funktion oder ein Amt in deinem Referat angeben.“
- R4: Neue Personen erhalten Status „aktiv“ ab dem Tag der Anlage (Product Owner 22.10.2026).
- R5: Vorbelegung „gültig bis“ einer Lizenz bzw. Qualifikation mit Gültigkeitsdauer: 31.12. des Jahres (Jahr der letzten Fortbildung, sonst Jahr von „gültig von“) + Gültigkeitsdauer; manuell änderbar. Ohne Gültigkeitsdauer bleibt das Feld leer.
- R6: Verlängern erzeugt einen neuen Eintrag; der bisherige endet am Vortag des neuen „gültig von“. Kein Überschreiben.
- R7: Status „ruhend“ oder „ausgeschieden“ für eine Person, die auch in Referaten außerhalb der eigenen zugeordnet ist: Bestätigung „Die Person ist auch in <Referate> tätig. Der Status gilt für alle Referate.“ (Product Owner 22.10.2026)
- R8: Beim Setzen auf „ausgeschieden“ werden laufende Funktionen, Ämter und Gremium-Mitgliedschaften, die der Nutzer ändern darf, zum selben Datum beendet (vorausgewählt, abwählbar); nicht zurückgegebene Ausgaben und laufende Zugänge extern werden angezeigt (Product Owner 22.10.2026).
- R9: Ablaufstatus nach Abschnitt B; Grenze 3 Monate fest im MVP.
- R10: Führungszeugnis-Einsicht gilt 3 Jahre ab Ausstellungsdatum; Ablaufstatus wie bei Qualifikationen; maßgeblich ist das Ausstellungsdatum, nicht die Einsicht (Product Owner 22.10.2026).
- R11: Stichtagsliste: alle aktuellen Lizenzen und Qualifikationen mit „gültig bis“ im gewählten Kalenderjahr von Personen mit Status „aktiv“ oder „ruhend“, die der Nutzer lesen darf; CSV-Export nur mit EA = verwalten (Product Owner 22.10.2026).
- R12: Eigenschaften pflegen dürfen alle, die sie lesen dürfen und EA ≥ bearbeiten haben (R42 AD); Referent:innen also alle Arten der Lesestufe „alle“ für Personen ihrer Referate, Zuordnungen nur zu eigenen Referaten (R41 AD) (Product Owner 22.10.2026).
- R13: IBAN: Leerzeichen werden entfernt, Großbuchstaben; Prüfsumme nach ISO 13616; sonst „Die IBAN ist ungültig.“
- R14: Markierung „Trainer:in ohne gültige Lizenz“: Person mit aktueller Funktion Trainer:in und ohne aktuelle Lizenz mit „gültig bis“ ≥ heute. Die Funktion wird nicht automatisch beendet.
- R15 (Migration, Funktion): Je Referat in `referate` eine Funktion mit Bezug auf das Referat: „Trainer:in“, wenn mindestens eine Lizenz (L1–L3, auch abgelaufen) angegeben ist, sonst „Helfer:in“ (Entscheidung 22.10.2026). Abgelaufene erscheinen danach mit R14.
- R16 (Migration, Prüfbericht): Der Probelauf schreibt nichts und listet je Zeile: Pflichtfehler, unbekannte Referate und Qualifikationsarten, ungültige Daten und IBAN, Dublettenverdacht (`ad_find_similar_persons`-Logik gegen PROD und innerhalb der Datei), Personen mit mehreren Lizenzen und weniger Lizenznummern, Werte aus `gruppe`/`gruppenleitung`, Anzahl angelegter Eigenschaften je Art. Der Lauf startet nicht, wenn der Probelauf Fehler hat; er läuft in einer Transaktion für die ganze Datei (alles oder nichts) [ANNAHME].
- R17 (Migration, Herkunft): `created_in = 'script'`; Eigenschaften ohne bekanntes Datum erhalten „gültig von“ = Stichtag; der Prüfbericht zählt diese Fälle.

## E. Schnittstellen

| Richtung | Modul | Inhalt |
|---|---|---|
| nutzt | Administration | Personenmodell, Funktionen und Komponenten nach Abschnitt 0; Ergänzungen Ü1 (Bezeichnungen „gültig von/bis“) und Ü2 (Geburtsjahr in der Dublettenwarnung) laut uebergabe-administration.md |
| liefert | Gruppen | Personen, Referate; Gruppen setzt „aktiv“ für Trainer:innen und Helfer:innen ohne Status [ANNAHME GR]; Spalten „Gruppe“, „Gruppenleitung“ im Prüfbericht für den Gruppen-Import |
| liefert | Anwesenheitserfassung | E1: aus einem Arbeitseinsatz angelegte Personen erhalten Status „aktiv“ und Funktion „Helfer:in“ mit Bezug auf das Referat (Funktion `ea_create_volunteer`, Nachtrag v0.8 AD; nutzt `function`, `contact.email` aus C2). E6: Auswahl der organisierenden Person über `ea_search_active_persons` (AD v0.8). E2: Einsatzhistorie im Detail (Iteration 2). E3: „TE pro Woche“ bleibt Feld an der Funktion |
| liefert | Planungshilfe Touren und Kurse | Lizenzen über `ea_person_licenses` (AD v0.9) aus Nr. 9 |
| liefert | Finanzen | Bankverbindung, Trainervereinbarung, Bestätigung steuerfreie Einnahmen, Erklärung zur Ehrenamtspauschale (E4); förderfähige Lizenz mit Erwerbsdatum = gültig von der Lizenz (E5); Lesepfad für Nutzer nur mit Finanzen-Rechten offen (Querschnitt P7) |
| nach MVP | Schnittstellen-Connector | E-Mail vor Ablauf, Geburtstagserinnerung |

## F. Datenschutz

- Lesestufen nach C2; Bankverbindung, Geburtsdatum, Geschlecht, Führungszeugnis-Einsicht, Trainervereinbarung, Nachweise der Vergütungsordnung, Förderung nur GST; Hauptamt vertraulich.
- Referent:innen sehen bei Personen in mehreren Referaten alle Eigenschaften der Lesestufe „alle“ (bewusst, Steckbrief).
- Dublettenwarnung: Geburtsjahr eines Treffers nur für Geschäftsstelle und Admin; Referent:innen sehen Vorname, Rufname, Nachname und „ausgeschieden seit“ (Entscheidung 22.10.2026, Übergabe Ü2 an die Administration).
- Führungszeugnis: nur Ausstellungsdatum und Einsicht, nie Inhalt. Kein Personalausweis.
- Migration: Excel und CSV nur lokal beim Admin, nie im Repository oder in TEST; Entwicklung mit fiktiver CSV; Prüfbericht enthält Namen und bleibt lokal.
- CSV-Export der Stichtagsliste nur Geschäftsstelle und Admin; enthält Name, Qualifikationsart, gültig bis, Referate – keine Kontaktdaten (Product Owner 22.10.2026).
- Neue Eigenschaftsarten: Zweck Pflicht, Hinweis Art. 9 DSGVO (AD).
- Personen aus Arbeitseinsätzen: Information nach Art. 13 DSGVO beim Anlegen – die anlegende Person bestätigt per Häkchen, die Person mündlich informiert und auf die Datenschutzhinweise der Sektion (Link) verwiesen zu haben; Text liefert der Product Owner; Umsetzung in der Anwesenheitserfassung (Product Owner 22.10.2026), Übergabe uebergabe-anwesenheitserfassung.md.
- Ausgeschiedene: bleiben gespeichert; Löschlauf nach 5 Jahren nach MVP.

## G. Nicht-funktional

- Mengengerüst: ca. 250 Aktive (130 aus der Migration, 120 später), 1.000 Personen insgesamt, je Person bis 30 Eigenschaften [ANNAHME].
- Übersicht mit Filtern < 1 s, Detail < 1 s, Stichtagsliste < 2 s.
- Mobil ab 375 px; Tabellen werden zu Karten.
- Migrationsskript wiederverwendbar für weitere Listen (gleiche CSV-Vorlage), läuft lokal mit Node/TypeScript und Supabase-Client [ANNAHME].
- Kosten 0 €.

## Übergabe aus der Anwesenheitserfassung (v1.2) – Verbleib

| Nr | Inhalt | Verbleib |
|---|---|---|
| E1 | Aktive aus Arbeitseinsätzen | Abschnitt E; Anlage über `ea_create_volunteer` (AD v0.8) mit `function` = Helfer:in und `contact.email` (C2 Nr. 4, 6) |
| E2 | Einsatzhistorie, letzter Einsatz | Iteration 2 (B2); Merkposten |
| E3 | TE pro Woche | bleibt Feld `training_units_per_week` an der Funktion (C2 Nr. 6); Prüfung mit der Anwesenheitserfassung |
| E4 | Nachweise Vergütungsordnung | C2 Nr. 16, 17, 25; „Vereinbarung ehrenamtliche Tätigkeit“ getrennt von der Trainervereinbarung (Product Owner 22.10.2026) |
| E5 | förderfähige Lizenz, Erwerbsdatum | gültig von der Lizenz = erworben bzw. verlängert am; förderfähig = DOSB-lizenzfähig (AD v0.9, [ANNAHME]) |
| E6 | Aktive als Auswahl | `ea_search_active_persons` (AD v0.8) |

## Offene Fragen

| Frage | Wer klärt | bis wann |
|---|---|---|
| [OFFEN] Karteileichen später migrieren? | Product Owner | nach MVP |
| [OFFEN] Fördergeber und Förderart; Jahreskarte wofür; Systeme Forms, Redaktion, Mailingliste | Product Owner | jederzeit (Werte 1:1 übernommen) |
| [OFFEN] Amtszeit Jugendausschuss | Product Owner | bei Bereinigung |
| [OFFEN] „Mitarbeiter:in Mitgliederverwaltung“ ehrenamtlich oder Hauptamt? | Product Owner | vor Migration der übrigen Listen |
| [OFFEN] Regelwerk Führungszeugnis-Einsicht (Pflicht je Funktion) | Product Owner | nach MVP |
| [OFFEN] Text des Hinweises nach Art. 13 DSGVO und Link auf die Datenschutzhinweise der Sektion | Product Owner | vor Start Anwesenheitserfassung |

Erledigt am 22.10.2026 (Product Owner):
- Funktion bei der Migration: Lizenz (auch abgelaufen) → Trainer:in, sonst Helfer:in.
- Ehrenamtsstatus bei der Migration: ein Eintrag ab Stichtag; „Aktiv seit“ nur als gültig von der Funktion.
- DOSB-Lizenz: optionales Feld „DOSB-Lizenz gültig bis“, ohne Ablaufmarkierung im MVP; Excel-Spalten „gültig bis“ = Ablauf nach Fortbildungsregelung.
- Lizenz: Pflicht Qualifikationsart und gültig bis; optional Lizenznummer, DOSB-Lizenz gültig bis, letzte Fortbildung; Erwerbsdatum = gültig von; „Stufe laut Vereinsportal“ und „Jahr Kursverlängerung“ entfallen.
- Eingabe der Migration: bereinigte CSV mit festen Spalten statt Excel direkt.
- Fortbildungen der Vorjahre: je Jahr ein Eintrag.
- Bezeichnungen für „gültig von/bis“ je Eigenschaftsart (C2a; Übergabe Ü1 an die Administration).
- Startwerte: Funktion Trainer:in, Helfer:in; Amt Referent:in, stellv. Referent:in, Hüttenwart:in; weitere Werte ergänzt die Geschäftsstelle bei Bedarf.
- Dublettenwarnung: Geburtsjahr nur für Geschäftsstelle und Admin (W3; Übergabe Ü2 an die Administration).
- Vereinbarung über die ehrenamtliche Tätigkeit: eigener Nachweis (C2 Nr. 25).
- Ausscheiden: laufende Funktionen, Ämter und Gremium-Mitgliedschaften vorausgewählt zum Beenden, abwählbar; Hinweis auf Ausgaben und externe Zugänge; Bestätigung bei weiteren Referaten (R7, R8).
- Referent:innen pflegen alle Eigenschaften der Lesestufe „alle“ für Personen ihrer Referate; Zuordnungen nur zu eigenen Referaten (R12).
