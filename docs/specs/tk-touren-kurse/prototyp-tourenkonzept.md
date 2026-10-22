# Übergabe: Tourenkonzept (DAV Sektion Leipzig)

Stand dieser Übergabe: 22.10.2026. Grundlage: die Datei `Tourenkonzept.html` bzw. `Tourenkonzept_DAV-Leipzig.html` in diesem Stand und der Chatverlauf, in dem das Formular entstanden ist.

Kennzeichnung: **[UNBEKANNT]** = nicht sicher bekannt. **[ANNAHME]** = Annahme, nicht festgelegt oder nicht belegt.

---

## 1. Zweck und Stand

**Zweck.** Tourenleitende der DAV Sektion Leipzig planen mit dem Formular eine Tour oder einen Kurs und kalkulieren einen kostendeckenden Teilnahmebeitrag nach Vergütungs- und Reisekostenordnung der Sektion. Das Formular erzeugt daraus die Angaben für das Buchungssystem Yolawo (Eingabeblatt und Ausschreibungstext), eine CO2-Bilanz der Anreise und ein PDF, das per E-Mail an das Tourenreferat geht. Das Tourenreferat öffnet das PDF wieder im Formular, prüft die Tour und legt das Angebot in Yolawo an, oder die Tourenleitung legt es selbst an.

**Stand.**

| Punkt | Wert |
|---|---|
| Sichtbarer Stand im Formular | „Stand: Oktober 2026“ (Kopfzeile und Fußzeile) |
| Datenformat der Einreichung | `format: "dav-leipzig-tourenkonzept"`, `version: 1` |
| localStorage-Schlüssel | `dav-lpz-tourenkonzept-v1` |
| Letzte fachliche Änderung | 22.10.2026: „nur DAV-Mitglieder“ ist Standard |
| Dateien | `Tourenkonzept.html` (Quelldatei, wird als claude.ai-Vorschau veröffentlicht, enthält bewusst keinen `<!doctype>`/`<head>`-Rahmen); `Tourenkonzept_DAV-Leipzig.html` (eigenständige Datei für die Website, ca. 477 KB, mit vollständigem HTML-Rahmen) |
| Interne Versionsnummer der Anwendung | keine; nur `FORMAT_VERSION = 1` für das Einreichungsformat |

**Wer es nutzt.**

| Rolle | Nutzung |
|---|---|
| Tourenleitende (Trainer*innen, Wanderleiter*innen, Helfende) | füllen das Formular aus, erstellen das PDF, senden es per E-Mail |
| Tourenreferat | öffnet eingereichte PDFs („Einreichung öffnen“), prüft, legt Angebote in Yolawo an, pflegt die „Sätze und Annahmen“ (durch Ändern der HTML-Datei) |
| Geschäftsstelle | [UNBEKANNT] keine direkte Nutzung des Formulars vorgesehen; Abrechnung nach der Tour läuft über separate Formulare (Abschnitt 2) |
| Vorstand | beschließt Vergütungsordnung und Reisekostenordnung, deren Sätze im Formular stehen; keine direkte Nutzung vorgesehen |

**Ausdrücklich nicht Ziel (so im Chat entschieden oder festgestellt).**

- Kein automatischer Import nach Yolawo: Yolawo bietet keinen Import von Angeboten (CSV/Excel), nur Exporte. Das Angebot wird von Hand anhand des Eingabeblatts angelegt.
- Keine zentrale Datenhaltung und kein Server: Eine Variante mit Datenbank auf claude.ai wurde verworfen (Konten für alle Tourenleitenden nötig, personenbezogene Daten bei einem Drittanbieter). Ein Upload über einen OneDrive-Dateianforderungslink war kurz umgesetzt und wurde zugunsten von PDF plus E-Mail verworfen.
- Keine Abrechnung nach der Tour im Formular (dafür gibt es die Formulare „Reisekosten“ und „Kostenabrechnung“ der Sektion).
- Keine Anmeldung von Teilnehmenden (läuft in Yolawo).
- Keine Prüfung der DAV-Mitgliedschaft (läuft über Anmeldefragen in Yolawo und die Geschäftsstelle; [UNBEKANNT] wie genau).

---

## 2. Ablauf

| Nr. | Wer | Schritt | Im Formular |
|---|---|---|---|
| 1 | Tourenleitung | Tour möglichst mindestens sechs Monate vor Beginn planen; bei Hütten vorher Verfügbarkeit und Stornobedingungen klären | Warnung, wenn Beginn weniger als 6 Monate entfernt ist |
| 2 | Tourenleitung | Formular öffnen (lokale HTML-Datei oder Download von der Website). Ein gespeicherter Entwurf wird automatisch geladen, sonst das Beispiel | Start: Entwurf aus localStorage oder „Beispiel laden“-Daten |
| 3 | Tourenleitung | Schritte 1 bis 7 ausfüllen; Seitenleiste zeigt Beitrag, CO2-Bilanz, Fortschritt | Abschnitt 3 und 6 |
| 4 | Tourenleitung | In Schritt 7 „Wer legt das Angebot in Yolawo an?“ wählen: „Das Tourenreferat“ (Standard) oder „Ich selbst, mit eigenem Yolawo-Zugang“. Das Formular wird in beiden Fällen vollständig ausgefüllt und eingereicht | Feld `ylw` |
| 5 | Tourenleitung | „PDF erstellen“ (Kopfleiste, Handy-Leiste oder Reiter „Einreichen“). Alle offenen Pflichtfelder werden rot markiert; das PDF entsteht auch unvollständig, mit Hinweis | Abschnitt 7 |
| 6 | Tourenleitung | „E-Mail-Entwurf öffnen“ (mailto an tourenreferat@dav-leipzig.de mit Betreff und Text), PDF und ggf. eigenes Titelfoto von Hand anhängen. Ausweg ohne PDF: „Zusammenfassung kopieren“ in die E-Mail | Abschnitt 7 |
| 7 | Tourenreferat | „Einreichung öffnen“ → PDF auswählen. Das Formular liest die eingebetteten Daten, zeigt alles ausgefüllt und rechnet mit den Sätzen der eigenen Formularversion. Die geöffnete Einreichung wird nicht im Browser gespeichert; der eigene Entwurf bleibt erhalten. Optional „Als meinen Entwurf übernehmen“ | Abschnitt 7, 8 |
| 8 | Tourenreferat | Prüfung und Freigabe (Zulassung der Touren durch das Tourenreferat laut Vergütungsordnung Ziff. 9); Rückfragen an die Tourenleitung | [UNBEKANNT] kein Freigabestatus im Formular; läuft außerhalb (E-Mail) |
| 9 | Tourenreferat oder Tourenleitung | Angebot in Yolawo anlegen, Feld für Feld nach dem Reiter „Yolawo-Eingabeblatt“ (jedes Feld einzeln kopierbar), Beschreibung aus dem Reiter „Beschreibungstext“ (Überschriften in Yolawo fett setzen) | Abschnitt 7 |
| 10 | Tourenleitung | Tour durchführen; DAV-Notfallkarte mitführen (Notruf 112, danach DAV-Notfall-Hotline +49 89 30657092) | Bestätigung `c4` |
| 11 | Tourenleitung | Nach der Tour: Abrechnung innerhalb von 4 Wochen mit den Formularen „Reisekosten“ und „Kostenabrechnung“ und Originalbelegen; Erklärung zur Übungsleiterpauschale muss vorliegen; besondere Vorkommnisse an das Tourenreferat melden; freiwillig Dreizeiler mit Foto an oeffentlichkeitsreferat@dav-leipzig.de oder Artikel an redaktion@dav-leipzig.de; optional Feedbackbogen an Teilnehmende (Link kommt vom Referat) | nur als Hinweistext und Bestätigungen `c2`, `c3`, Option `evaluation` |
| 12 | Tourenreferat / Geschäftsstelle | Genehmigung und Auszahlung (laut Folien des Tourenleitertreffens 16.10.2025: „Referat + GS“) | außerhalb des Formulars |
| 13 | Tourenreferat | Notfallkontakte nach Abschluss der Tour löschen (so steht es im Datenschutzhinweis des Formulars) | außerhalb; [UNBEKANNT] ob vom Vorstand bestätigt |

---

## 3. Datenmodell

### 3.1 Einzelfelder

Spalten: Schritt · Feldname im Code (`id` bzw. `name` bei Radiogruppen) · Bezeichnung · Typ · Pflicht · Wertebereich/Auswahl · Standard · Sichtbarkeit · Ziel in Yolawo.

„öffentlich“ = erscheint im Ausschreibungstext oder in Yolawo. „intern“ = nur PDF/Zusammenfassung für das Tourenreferat.

Gespeichert werden Einzelfelder unter `f.<id>` (Strings, Checkboxen als Boolean), Radiogruppen unter `r.<name>`, Checkbox-Gruppen unter `c.zusatz` / `c.fragen`.

| Schritt | Feld | Bezeichnung | Typ | Pflicht | Wertebereich / Auswahl | Standard | Sichtbarkeit | Ziel in Yolawo |
|---|---|---|---|---|---|---|---|---|
| 1 | `typ` (Radio) | Tourtyp | Auswahl | ja | `Führungstour`, `Kurs` (Anzeige „Kurs / Ausbildungstour“), `Gemeinschaftstour` | keine Auswahl | öffentlich | Kategorien (Kurs → „Führungstour“ und „Kurs“) |
| 1 | `gtGrund` | Begründung für die Gemeinschaftstour | Textarea | ja, nur bei Gemeinschaftstour (sonst ausgeblendet) | Freitext | leer | intern | – |
| 1 | `leaders[]` | Leitung und Helfende | Tabelle (3.2) | mindestens eine Person mit Name und Qualifikation | siehe 3.2 | eine leere Zeile | Name, Qualifikation, Rolle öffentlich; Lizenzjahr intern | Teil der Beschreibung („Leitung“) |
| 1 | `kontaktMail` | E-Mail der Tourenleitung | E-Mail | ja | Freitext (keine Formatprüfung, `novalidate`) | leer | intern | – |
| 1 | `kontaktTel` | Mobilnummer für die Tour | Telefon | nein | Freitext | leer | intern | – |
| 1 | `notfallName` | Notfallkontakt | Text | ja | Freitext | leer | intern | – |
| 1 | `notfallTel` | Telefon Notfallkontakt | Telefon | ja | Freitext | leer | intern | – |
| 1 | `notfallWeitere` | Notfallkontakte weiterer Leitender und Helfender | Text | nein | Freitext („Leitende Person: Name Notfallkontakt, Telefon“) | leer | intern | – |
| 2 | `titel` | Titel | Text | ja | max. 90 Zeichen (`maxlength`) | leer | öffentlich | Angebot → Titel |
| 2 | `sportart` | Sportart | Auswahl | ja | `Wandern`, `Sport- und Langstreckenwandern`, `Bergwandern`, `Bergsteigen`, `Klettersteig`, `Klettern`, `Alpinklettern`, `Bouldern`, `Hochtour`, `Skitour`, `Schneeschuhtour`, `Skilanglauf`, `Ski alpin`, `Mountainbike`, `Sonstiges` | leer („Bitte wählen“) | öffentlich | Kategorien |
| 2 | `c.zusatz` (Checkboxen) | Zielgruppe / Reihe | Mehrfachauswahl | nein | Wert/Anzeige: `Familienwanderungen`/„Familie“, `Flinke Füße`/„Flinke Füße“, `Einsteiger`/„Einsteiger*innen“, `FLINTA*`/„FLINTA*“ | keine | öffentlich | Kategorien |
| 2 | `region` | Gebiet / Region | Text | ja | Freitext | leer | öffentlich | Beschreibung |
| 2 | `stuetzpunkt` | Stützpunkt / Unterkunft | Text | nein | Freitext | leer | öffentlich | Beschreibung |
| 2 | `teaser` | Kurzbeschreibung | Textarea | ja | Freitext (2–4 Sätze empfohlen) | leer | öffentlich | Beschreibung (erster Absatz) |
| 2 | `programm` | Ablauf / Programm | Textarea | nein | Freitext | leer | öffentlich | Beschreibung („Ablauf“) |
| 2 | `bild` (Radio) | Titelbild | Auswahl | ja | `eigen` („Eigenes Foto, wird mitgeschickt“), `referat` („Referat wählt ein Bild“) | keine Auswahl | öffentlich (Bild) | Angebot → Titelbild |
| 2 | `bildrechte` | Bildrechte | Text | ja, nur bei `bild = eigen` (sonst ausgeblendet) | Freitext („Foto: Vorname Nachname“) | leer | öffentlich (letzte Zeile der Beschreibung) | Beschreibung / Titelbild |
| 3 | `dStart` | Beginn | Datum (`YYYY-MM-DD`) | ja | – | leer | öffentlich | Termin → Beginn (Datum) |
| 3 | `tStart` | Treffzeit | Uhrzeit (`HH:MM`) | ja | – | leer | öffentlich | Termin → Beginn (Uhrzeit) |
| 3 | `dEnd` | Ende | Datum | ja | – | leer | öffentlich | Termin → Ende (Datum) |
| 3 | `tEnd` | Voraussichtliches Ende | Uhrzeit | nein | – | leer | öffentlich (nur Yolawo) | Termin → Ende (Uhrzeit) |
| 3 | `treffpunkt` | Treffpunkt | Text | ja | Freitext | leer | öffentlich | Termin → Ort |
| 3 | `koord` | Adresse oder Koordinaten | Text | nein | Freitext | leer | öffentlich | Termin → Ort (zweite Zeile) |
| 3 | `vorbesprechung` | Vorbesprechung | Auswahl | nein | `keine` („Nicht erforderlich, Infos per E-Mail“), `online` („Online“), `praesenz` („In der Geschäftsstelle“) | `keine` | öffentlich | Beschreibung |
| 3 | `vbDatum` | Datum der Vorbesprechung | Datum+Uhrzeit (`datetime-local`) | nein; nur sichtbar, wenn nicht `keine` | – | leer | öffentlich | Beschreibung |
| 3 | `oev` (Radio) | Anreise mit öffentlichen Verkehrsmitteln | Auswahl | ja | `gemeinsam` („Gemeinsame Anreise mit Bahn/Bus geplant“), `moeglich` („Möglich, jede*r reist selbst an“), `nein` („Nicht sinnvoll möglich“) | keine Auswahl | öffentlich | Beschreibung |
| 3 | `anreise` | Anreisehinweise | Textarea | nein | Freitext | leer | öffentlich | Beschreibung |
| 3 | `co2[]` | Geplante An- und Abreise | Tabelle (3.2) | ja: mindestens eine Zeile mit km > 0 und (bei PKW/E-PKW/Kleinbus) Fahrzeuge > 0, sonst Personen > 0 | siehe 3.2 | eine leere Zeile (Bahn Fernverkehr, hin und zurück) | intern; aggregierter Wert je Person öffentlich | Beschreibung („Klimabilanz: …“) |
| 3 | `unterkunft` | Unterkunft | Auswahl | nein | `keine` („keine Übernachtung“), `huette` („DAV-Hütte“), `svh` („Selbstversorgerhütte / Ferienwohnung“), `hotel` („Pension / Hotel“), `camping` („Zelt / Camping“) | `keine` | intern | – |
| 3 | `naechte` | Nächte | Zahl ≥ 0 | nein | – | automatisch vorgeschlagen (4.2) | intern | – |
| 3 | `co2Pers` | Personen gesamt (Planung) | Zahl ≥ 0 | nein | – | automatisch vorgeschlagen (4.2) | intern | – |
| 3 | `oevTreff` | Treffpunkt höchstens 1,5 km von ÖPV-Haltestelle | Checkbox | nein | – | aus | intern | – |
| 4 | `gehzeit` | Max. Gehzeit pro Tag (h) | Zahl ≥ 0, Schritt 0,5 | nein | – | leer | öffentlich | Beschreibung („Etappen“) |
| 4 | `hmAuf` | Max. Höhenmeter ↑ pro Tag | Zahl ≥ 0, Schritt 50 | nein | – | leer | öffentlich | Beschreibung |
| 4 | `hmAb` | Max. Höhenmeter ↓ pro Tag | Zahl ≥ 0, Schritt 50 | nein | – | leer | öffentlich | Beschreibung |
| 4 | `km` | Max. Strecke pro Tag (km) | Zahl ≥ 0, Schritt 1 | nein | – | leer | öffentlich | Beschreibung |
| 4 | `kond` (Radio) | Kondition | Auswahl | ja | `gering`, `mittel`, `groß`, `sehr groß` | keine Auswahl | öffentlich | Beschreibung |
| 4 | `tech` (Radio) | Technik | Auswahl | ja | `leicht`, `mittel`, `schwer`, `sehr schwer` | keine Auswahl | öffentlich | Beschreibung |
| 4 | `grad` | Schwierigkeitsangabe der Sportart | Text | nein | Freitext (z. B. „T3, UIAA II, Klettersteig C, Hochtour WS, Skitour ZS-“) | leer | öffentlich | Beschreibung |
| 4 | `vorauss` | Voraussetzungen | Textarea | ja | Freitext | leer | öffentlich | Beschreibung |
| 4 | `auchNM` | Ausnahme: auch Nichtmitglieder zulassen | Checkbox | nein | – | aus (= nur DAV-Mitglieder) | öffentlich (Wirkung: Tarif, Voraussetzung) | Tarif „Nichtmitglied“ ja/nein |
| 4 | `nmGrund` | Begründung der Ausnahme und Rücksprache | Text | ja, nur wenn `auchNM` an und keine Gemeinschaftstour | Freitext | leer | intern | – |
| 4 | `ausruestung` | Ausrüstung | Textarea | ja | Freitext | leer | öffentlich | Beschreibung |
| 5 | `minTN` | Min. Teilnehmende | Zahl, `min=1` | ja | – | leer | öffentlich | kein Yolawo-Feld; steht in der Beschreibung |
| 5 | `maxTN` | Max. Teilnehmende | Zahl, `min=1` | ja | – | leer | öffentlich | Buchungsoption → Kapazität |
| 5 | `anmeldeschluss` | Anmeldeschluss | Datum | ja | – | leer | öffentlich | Buchungszeitraum → Ende (23:59 Uhr) |
| 5 | `warteliste` | Warteliste | Auswahl | nein | `ja` („ja, aktivieren“), `nein` | `ja` | – | Buchungsoption → Warteliste |
| 5 | (fest) | Zahlungsart | Anzeige | – | „Onlinezahlung bei der Buchung“ | – | öffentlich | Zahlung → Onlinezahlung |
| 5 | (fest) | Rückerstattung bei Stornierung | Anzeige | – | „Sektionsstandard: bis 4 Wochen vorher 90 %, bis 2 Wochen vorher 50 %, danach keine Erstattung“ | – | öffentlich | Anmeldezeitraum & Rückerstattung → Stornoregeln |
| 5 | `stornoUnterkunft` | Stornobedingungen der Unterkunft | Text | nein | Freitext | leer | intern | – |
| 5 | `c.fragen` (Checkboxen) | Fragen im Anmeldeformular | Mehrfachauswahl | nein | siehe Tabelle 3.3 | 6 von 11 vorausgewählt (3.3) | – | Anmeldeformular → zusätzliche Fragen |
| 5 | `frageEigen` | Weitere Frage | Text | nein | Freitext | leer | – | Anmeldeformular |
| 6 | `tageVoll` | Tagessätze (ab 8 h) | Zahl ≥ 0 | nein | – | automatisch (4.2) | intern | – |
| 6 | `tageHalb` | Halbtagessätze (unter 8 h) | Zahl ≥ 0 | nein | – | automatisch (4.2) | intern | – |
| 6 | `lehrStd` | Lehreinheiten à 1 h | Zahl ≥ 0 | nein; nur sichtbar bei eintägigem Kurs | – | automatisch (4.2) | intern | – |
| 6 | `orgTage` | Tage Organisationspauschale | Zahl ≥ 0 | nein | – | automatisch (4.2) | intern | – |
| 6 | `t.tblLeit[]` | Kosten der Leitung | Tabelle (3.2) | nein | – | eine leere Zeile | intern | – |
| 6 | `pkwGrund` | Begründung für die PKW-Fahrt | Text | ja, nur wenn eine Zeile in „Kosten der Leitung“ mit „PKW“ beginnt (keine Gemeinschaftstour) | Freitext | leer | intern | – |
| 6 | `t.tblFix[]` | Sonstige Tourkosten | Tabelle (3.2) | nein | – | keine Zeile | intern | – |
| 6 | `t.tblTN[]` | Im Beitrag enthaltene Leistungen je Teilnehmer*in | Tabelle (3.2) | nein | – | eine leere Zeile | Bezeichnungen öffentlich | Tarif-Beschreibung, Beschreibung |
| 6 | `t.tblSelbst[]` | Selbst zu zahlen | Tabelle (3.2) | nein | – | eine leere Zeile | öffentlich | Beschreibung |
| 6 | `ohneBeitrag` | Ohne Teilnahmebeitrag | Checkbox | nein; nur sichtbar bei Tagestour mit Zielgruppe „Familienwanderungen“ und keiner Gemeinschaftstour | – | aus | öffentlich (Wirkung) | Tarife entfallen |
| 6 | `preisM` | Beitrag DAV-Mitglieder (€) | Zahl ≥ 0, Schritt 5 | nein (leer = berechneter Vorschlag) | – | leer | öffentlich | Tarif „DAV-Mitglied“ |
| 6 | `preisN` | Beitrag Nichtmitglieder (€) | Zahl ≥ 0, Schritt 5 | nein; nur sichtbar bei `auchNM` | – | leer | öffentlich | Tarif „Nichtmitglied“ |
| 7 | `ylw` (Radio) | Wer legt das Angebot in Yolawo an? | Auswahl | als Pflicht markiert, wird aber nicht geprüft (immer vorbelegt) | `referat` („Das Tourenreferat“), `tl` („Ich selbst, mit eigenem Yolawo-Zugang“) | `referat` | intern | – |
| 7 | `hinweise` | Hinweise für das Referat | Textarea | nein | Freitext | leer | intern | – |
| 7 | `c1` | Bestätigung Lizenz („Meine Qualifikation ist für diese Tour gültig. Lizenzmarke und Ausweiskopie liegen in der Geschäftsstelle.“) | Checkbox | ja; bei Gemeinschaftstour ausgeblendet | – | aus | intern | – |
| 7 | `c2` | Bestätigung Kalkulation/Abrechnung | Checkbox | ja; bei Gemeinschaftstour ausgeblendet | – | aus | intern | – |
| 7 | `c3` | Bestätigung ÜL-Erklärung | Checkbox | ja; bei Gemeinschaftstour ausgeblendet | – | aus | intern | – |
| 7 | `c4` | Bestätigung Notfallkarte | Checkbox | ja | – | aus | intern | – |
| 7 | `evaluation` | Nach der Tour einen Feedbackbogen senden | Checkbox | nein | – | aus | intern | – |

Hinweis: Mit `novalidate` am Formular werden `min`, `max`, `step` und `type="email"` vom Browser **nicht** erzwungen. Geprüft wird nur, was in Abschnitt 6 steht.

### 3.2 Tabellen

**Leitung und Helfende** (`leaders[]`)

| Spalte | Schlüssel | Typ | Auswahl / Bereich | Standard |
|---|---|---|---|---|
| Name | `name` | Text | Freitext | leer |
| Qualifikation | `qual` | Auswahl | `Trainer*in C Bergwandern`, `Trainer*in C Bergsteigen`, `Trainer*in B Hochtouren`, `Trainer*in C Skibergsteigen`, `Trainer*in C Sportklettern`, `Trainer*in B Alpinklettern`, `Wanderleiter*in`, `Übungsleiter*in B Prävention`, `Trainer*in in Ausbildung`, `ohne DAV-Qualifikation` | leer („Bitte wählen“) |
| Rolle | `rolle` | Auswahl | `Leitung`, `Co-Leitung`, `Helfer*in` | `Leitung` |
| Lizenz gültig bis | `lizenz` | Zahl (Jahr) | Attribute `min=2024`, `max=2035` (nicht erzwungen) | leer |

**Geplante An- und Abreise** (`co2[]`)

| Spalte | Schlüssel | Typ | Auswahl / Bereich | Standard |
|---|---|---|---|---|
| Verkehrsmittel | `mode` | Auswahl | `bahnFV`, `bahnNV`, `bus`, `linienbus`, `tram`, `pkw`, `epkw`, `van`, `flug`, `rad` (Bezeichnungen in Abschnitt 5.3) | `bahnFV` |
| Strecke | `l` | Text | Freitext | leer |
| km einfach | `km` | Zahl ≥ 0 | – | leer |
| Personen | `p` | Zahl ≥ 0 | – | leer; beim Hinzufügen über „+ Teilstrecke“ der Wert von `co2Pers` |
| Fahrzeuge | `f` | Zahl ≥ 0 | nur aktiv bei `pkw`, `epkw`, `van` | leer |
| hin und zurück | `rt` | Boolean | – | `true` |
| kg CO2e | (berechnet) | – | – | – |

**Kosten der Leitung** (`t.tblLeit[]`), **Sonstige Tourkosten** (`t.tblFix[]`), **Leistungen je TN** (`t.tblTN[]`), **Selbst zu zahlen** (`t.tblSelbst[]`): gleicher Aufbau.

| Spalte | Schlüssel | Typ | Hinweis |
|---|---|---|---|
| Position / Leistung / Kosten | `l` | Text | |
| Menge | `m` | Zahl ≥ 0 | |
| Einzelpreis € (bei „Selbst zu zahlen“: „ca. € je Einheit“) | `p` | Zahl ≥ 0 | |
| Summe (bei Leistungen: „je TN“, bei Selbst: „ca. je TN“) | (berechnet `m × p`) | – | |

Schnellknöpfe für „Kosten der Leitung“ (fügen eine Zeile ein):

| Knopf | `l` | `m` | `p` |
|---|---|---|---|
| + PKW-Fahrt | `PKW-Fahrt hin und zurück (km)` | leer | Satz `rKm` (0,20) |
| + Übernachtung | `Übernachtung (Nächte)` | max(Tage − 1, 1) | leer |
| + Pauschale Sulzenauhütte | `Fahrtpauschale Sulzenauhütte` | 1 | Satz `rSH` (240) |
| + Pauschale Karl-Stein-Hütte | `Fahrtpauschale Karl-Stein-Hütte` | 1 | Satz `rKSH` (60) |

Schnellknöpfe für „Selbst zu zahlen“:

| Knopf | `l` | `m` | `p` |
|---|---|---|---|
| + Hütte Ü+HP | `Übernachtung (Lager) und Halbpension auf der Hütte, Mitglieder` | max(Tage − 1, 1) | 63,5 |
| + Getränke, Dusche, Abgaben | `Getränke, Dusche, Nächtigungsabgabe` | max(Tage, 1) | 15 |

### 3.3 Fragen im Anmeldeformular (`c.fragen`)

| Wert (wird nach Yolawo übernommen) | Anzeige | vorausgewählt |
|---|---|---|
| `DAV-Mitgliedschaft (Sektion Leipzig / andere Sektion / kein Mitglied)` | DAV-Mitgliedschaft | ja |
| `Mitgliedsnummer` | Mitgliedsnummer | ja |
| `Mobilnummer` | Mobilnummer | ja |
| `Notfallkontakt (Name, Telefon)` | Notfallkontakt | ja |
| `Geburtsdatum` | Geburtsdatum | nein |
| `Hinweise an die Tourenleitung (z. B. gesundheitlich)` | Hinweise an die Leitung | ja |
| `Verpflegungswunsch (z. B. vegetarisch)` | Verpflegung | nein |
| `Bahn-Ermäßigung (BahnCard, Deutschlandticket)` | Bahn-Ermäßigung | nein |
| `Einwilligung: Kontaktdaten für Fahrgemeinschaften weitergeben` | Fahrgemeinschaften | nein |
| `Einwilligung: Ausschreibung und Voraussetzungen gelesen` | Voraussetzungen gelesen | ja |
| `Tourenerfahrung: bisherige Touren mit Ziel, Schwierigkeit, geführt/selbst organisiert (Textfeld)` | Tourenerfahrung | nein |

Bei „nur DAV-Mitglieder“ (Standard) wird im Eingabeblatt aus der ersten Frage der Teil ` / kein Mitglied` entfernt. Vor- und Nachname, E-Mail und Tarif fragt Yolawo laut Formulartext immer ab.

### 3.4 Datenobjekt (TypeScript)

So erzeugt `collect()` die Daten; `submission()` legt sie in einen Umschlag. Alle Einzelfelder unter `f` sind Strings (Wert des Eingabefelds), Checkboxen Booleans.

```ts
type Radio = string; // '' wenn nichts gewählt

interface TourenkonzeptDaten {
  f: {
    // Schritt 1
    gtGrund?: string; kontaktMail?: string; kontaktTel?: string;
    notfallName?: string; notfallTel?: string; notfallWeitere?: string;
    // Schritt 2
    titel?: string; sportart?: string; region?: string; stuetzpunkt?: string;
    teaser?: string; programm?: string; bildrechte?: string;
    // Schritt 3
    dStart?: string; tStart?: string; dEnd?: string; tEnd?: string;   // 'YYYY-MM-DD' / 'HH:MM'
    treffpunkt?: string; koord?: string;
    vorbesprechung?: 'keine' | 'online' | 'praesenz'; vbDatum?: string; // 'YYYY-MM-DDTHH:MM'
    anreise?: string;
    unterkunft?: 'keine' | 'huette' | 'svh' | 'hotel' | 'camping';
    naechte?: string; co2Pers?: string; oevTreff?: boolean;
    // Schritt 4
    gehzeit?: string; hmAuf?: string; hmAb?: string; km?: string; grad?: string;
    vorauss?: string; auchNM?: boolean; nmGrund?: string; ausruestung?: string;
    // Schritt 5
    minTN?: string; maxTN?: string; anmeldeschluss?: string;
    warteliste?: 'ja' | 'nein'; stornoUnterkunft?: string; frageEigen?: string;
    // Schritt 6
    tageVoll?: string; tageHalb?: string; lehrStd?: string; orgTage?: string;
    pkwGrund?: string; ohneBeitrag?: boolean; preisM?: string; preisN?: string;
    // Schritt 7
    hinweise?: string; c1?: boolean; c2?: boolean; c3?: boolean; c4?: boolean; evaluation?: boolean;
  };
  r: {
    typ: '' | 'Führungstour' | 'Kurs' | 'Gemeinschaftstour';
    bild: '' | 'eigen' | 'referat';
    oev: '' | 'gemeinsam' | 'moeglich' | 'nein';
    kond: '' | 'gering' | 'mittel' | 'groß' | 'sehr groß';
    tech: '' | 'leicht' | 'mittel' | 'schwer' | 'sehr schwer';
    ylw: '' | 'referat' | 'tl';
  };
  c: {
    zusatz: Array<'Familienwanderungen' | 'Flinke Füße' | 'Einsteiger' | 'FLINTA*'>;
    fragen: string[]; // Werte aus Tabelle 3.3
  };
  leaders: Array<{ name: string; qual: string; rolle: 'Leitung' | 'Co-Leitung' | 'Helfer*in'; lizenz: string }>;
  co2: Array<{ mode: 'bahnFV'|'bahnNV'|'bus'|'linienbus'|'tram'|'pkw'|'epkw'|'van'|'flug'|'rad';
               l: string; km: number; p: number; f: number; rt: boolean }>;
  t: {
    tblLeit: Kostenzeile[]; tblFix: Kostenzeile[]; tblTN: Kostenzeile[]; tblSelbst: Kostenzeile[];
  };
  touched: string[]; // Felder mit automatischem Vorschlag, die die Person selbst geändert hat
  sample: boolean;   // true, solange das Beispiel unverändert geladen ist
}
interface Kostenzeile { l: string; m: number; p: number }

interface Einreichung {            // Inhalt im PDF (Abschnitt 7.4)
  format: 'dav-leipzig-tourenkonzept';
  version: 1;
  gespeichert: string;             // ISO-Zeitstempel
  titel: string; beginn: string;   // Kopie von f.titel, f.dStart
  leitung: string;                 // Namen der Leitenden, kommagetrennt
  vollstaendig: boolean;
  fehlend: string[];               // Bezeichnungen fehlender Pflichtangaben
  daten: TourenkonzeptDaten;
}
```

Werte, die `touched` enthalten kann: `tageVoll`, `tageHalb`, `orgTage`, `lehrStd`, `naechte`, `co2Pers`.

### 3.5 Beispiel aus „Beispiel laden“ (Konstante `SAMPLE`)

Exakt die Konstante aus dem Code, als JSON. Personendaten sind Platzhalter.

```json
{
  "sample": true,
  "f": {
    "kontaktMail": "vorname.nachname@dav-leipzig.de",
    "kontaktTel": "+49 170 0000000",
    "notfallName": "Vorname Nachname",
    "notfallTel": "+49 171 0000000",
    "titel": "Hüttentour in den Stubaier Alpen (Beispiel)",
    "sportart": "Bergwandern",
    "region": "Stubaier Alpen, Tirol",
    "stuetzpunkt": "Sulzenauhütte (2.191 m)",
    "teaser": "Fünf Tage unterwegs rund um unsere Sulzenauhütte: Gletscherblicke, Bergseen und aussichtsreiche Übergänge im Hochstubai. Wir wohnen auf der Hütte und starten jeden Tag zu einer neuen Tour.",
    "programm": "Tag 1: Aufstieg von der Grawa-Alm zur Sulzenauhütte\nTag 2–4: Tagestouren, z. B. Peiljoch, Grünausee, Mairspitze\nTag 5: Abstieg und Heimreise",
    "bildrechte": "Foto: Vorname Nachname",
    "dStart": "2027-07-12",
    "tStart": "11:00",
    "dEnd": "2027-07-16",
    "tEnd": "15:00",
    "treffpunkt": "Talstation Grawa-Alm, Neustift im Stubaital",
    "koord": "47.0566, 11.2066",
    "vorbesprechung": "online",
    "vbDatum": "2027-06-14T19:00",
    "anreise": "Vorschlag: gemeinsame Bahnfahrt ab Leipzig Hbf am Vortag, weiter mit dem Stubaitalbus bis Grawa-Alm. Fahrgemeinschaften über Moobly.",
    "gehzeit": "7",
    "hmAuf": "1000",
    "hmAb": "1000",
    "km": "14",
    "grad": "T2–T3",
    "vorauss": "Kondition für bis zu 7 h Gehzeit und 1.000 Hm im Auf- und Abstieg\nTrittsicherheit und Schwindelfreiheit\nBergwandererfahrung auf roten Wegen",
    "ausruestung": "Bergschuhe mit Profilsohle, Wanderstöcke, Regen- und Wärmeschutz, Sonnenschutz, Erste-Hilfe-Set, Hüttenschlafsack, Stirnlampe",
    "minTN": "5",
    "maxTN": "8",
    "anmeldeschluss": "2027-05-15",
    "warteliste": "ja",
    "unterkunft": "huette",
    "oevTreff": true,
    "stornoUnterkunft": "Gruppenreservierung kostenfrei stornierbar bis 30 Tage vor Anreise",
    "tageVoll": "5",
    "tageHalb": "0",
    "orgTage": "5",
    "hinweise": "Beispiel aus den Folien zum Tourenleitertreffen: Gesamtkosten 735 €, Mindestteilnehmerzahl 5, Beitrag 150 € (dort noch ohne Zahlungsgebühren)."
  },
  "r": { "typ": "Führungstour", "bild": "eigen", "oev": "gemeinsam", "kond": "groß", "tech": "mittel" },
  "c": { "zusatz": [] },
  "leaders": [ { "name": "Vorname Nachname", "qual": "Trainer*in C Bergwandern", "rolle": "Leitung", "lizenz": "2028" } ],
  "t": {
    "tblLeit": [
      { "l": "Bahnfahrt hin und zurück", "m": 2, "p": 105 },
      { "l": "Halbpension Hütte", "m": 5, "p": 45 },
      { "l": "Übernachtung Hütte (Freiplatz 5+1)", "m": 5, "p": 0 }
    ],
    "tblFix": [],
    "tblTN": [],
    "tblSelbst": [
      { "l": "Übernachtung (Lager) und Halbpension auf der Hütte, Mitglieder", "m": 4, "p": 63.5 },
      { "l": "Bahnfahrt Leipzig–Neustift hin und zurück", "m": 1, "p": 210 },
      { "l": "Getränke und Tourenproviant", "m": 5, "p": 15 }
    ]
  },
  "co2": [
    { "mode": "bahnFV", "l": "Leipzig–Innsbruck", "km": 650, "p": 9, "rt": true },
    { "mode": "linienbus", "l": "Innsbruck–Grawa-Alm (Stubaitalbus)", "km": 30, "p": 9, "rt": true }
  ],
  "touched": ["tageVoll", "tageHalb", "orgTage"]
}
```

Beim Laden ergänzt das Formular: `r.ylw = "referat"`, die vorausgewählten Anmeldefragen (3.3, weil `c.fragen` fehlt), `naechte = 4` und `co2Pers = 9` (automatische Vorschläge), leere Zeile in `tblTN`. `auchNM` fehlt → „nur DAV-Mitglieder“.

---

## 4. Berechnungen

Alle Werte kommen aus den Feldern; leere oder ungültige Zahlen zählen als 0 (`num()`). Tage werden immer mit Uhrzeit 12:00 gerechnet, um Zeitzonenfehler zu vermeiden.

### 4.1 Tage und Termin

- `days = round((dEnd − dStart) / 1 Tag) + 1`, nur wenn beide Daten gesetzt sind; Ergebnis ≤ 0 → 0.
- `hoursDay1 = (tEnd − tStart)` in Stunden; nur wenn beide Zeiten gesetzt sind; Ergebnis ≤ 0 → `null`.
- Eventart (nur Anzeige): 1 Tag → „Tagestour“, 2–3 Tage → „Wochenendtour“, mehr → „Mehrtagestour“ (unabhängig vom Wochentag).
- `tourYear` = Jahr von `dStart`, sonst aktuelles Jahr.

### 4.2 Automatische Vorschläge (überschreiben nur, solange das Feld nicht in `touched` steht)

| Feld | Vorschlag |
|---|---|
| `tageVoll` | mehrtägig: `days`; eintägig: 1, wenn `hoursDay1 ≥ 8`, sonst 0 |
| `tageHalb` | mehrtägig: 0; eintägig: `1 − tageVoll` |
| `orgTage` | mehrtägig: `days`; eintägig: 0 |
| `naechte` | `unterkunft = keine` → 0, sonst `max(days − 1, 0)` |
| `co2Pers` | nur wenn `maxTN` > 0: `maxTN + max(Anzahl Leitende mit Name oder Qualifikation, 1)` |
| `lehrStd` | nur eintägig und `hoursDay1` gesetzt: `max(0, floor(hoursDay1))` |

Hinweis: Der Vorschlag für Tagessätze zählt alle Kalendertage, obwohl laut Vergütungsordnung der Abrechnungszeitraum am Zielort beginnt. Die Person muss An- und Abreisetage selbst abziehen (Hinweistext im Formular).

### 4.2a Kategorien für Yolawo

`Kurs` → `Führungstour`, `Kurs`; sonst der Tourtyp; dazu Sportart und alle gewählten Werte aus `c.zusatz`, in dieser Reihenfolge.

### 4.3 Vergütung der Leitung

- Personen = Leitende mit Name **oder** Qualifikation.
- Trainersatz für Person `l`, wenn **alle** gelten: `rolle ≠ Helfer*in`; `qual` nicht leer, nicht `Trainer*in in Ausbildung`, nicht `ohne DAV-Qualifikation`; `lizenz` gesetzt und `lizenz ≥ tourYear`. Sonst Helfersatz.
- `nTL` = Anzahl Personen mit Trainersatz; **wenn keine Person erfasst ist, wird `nTL = 1` gesetzt**. `nH` = übrige Personen.
- Eintägiger Kurs (`typ = Kurs` und `days = 1`): `honorar = nTL × lehrStd × rLE`. Helfende erhalten 0. Organisationspauschale = 0.
- Sonst: `honorar = nTL × (tageVoll × rTL + tageHalb × rTLh) + nH × (tageVoll × rH + tageHalb × rHh)`. Alle Personen bekommen dieselbe Anzahl Tage.
- `org = orgTage × rOrg` (einmal je Tour, nicht je Person).
- Gemeinschaftstour: `honorar = 0`, `org = 0`.

### 4.4 Kosten

- `leit = Σ (m × p)` über „Kosten der Leitung“ (0 bei Gemeinschaftstour)
- `fix = Σ (m × p)` über „Sonstige Tourkosten“ (0 bei Gemeinschaftstour)
- `varTN = Σ (m × p)` über „Leistungen je TN“ (0 bei Gemeinschaftstour)
- `selbst = Σ (m × p)` über „Selbst zu zahlen“ (nur Information, geht nicht in den Beitrag)
- `kosten = honorar + org + leit + fix`

PKW-km, Übernachtungsgrenze, Freiplatz und Hüttenpauschalen werden **nicht automatisch gerechnet**. Sie stehen als Schnellknöpfe (3.2), Hinweistexte und Warnungen (Abschnitt 6) zur Verfügung. Die Person trägt die Menge selbst ein, z. B. PKW: Menge = km, Preis = 0,20.

### 4.5 Teilnahmebeitrag

1. Zahlmethoden: alle aktiven aus „Sätze und Annahmen“. Für jede: `p = Prozent / 100 × (1 + MwSt)`, `f = fix × (1 + MwSt)`, MwSt = `rVat / 100`.
2. `need(m) = (kosten / minTN + varTN + m.f) / (1 − m.p)`.
3. Gewählt wird die Methode mit dem **größten** `need` („teuerste aktive Zahlmethode“). Keine aktive Methode → `p = 0`, `f = 0`.
4. `roh = need(gewählt)`, nur wenn `minTN > 0`, sonst `NaN`.
5. `vorschlag = ceil(roh / rund − 1e−9) × rund` mit `rund = rRund` (5); bei `frei` = 0.
6. `pM` = eigener Wert aus `preisM`, falls eingetragen, sonst `vorschlag`.
7. Nichtmitglieder: `vorschlagN = ceil(pM × (1 + rNM / 100) / rund − 1e−9) × rund`. **Grundlage ist `pM`**, also auch ein eigener Mitgliederbeitrag. `pN` = eigener Wert aus `preisN`, sonst `vorschlagN`; bei „nur DAV-Mitglieder“ `pN = null`.
8. `frei` = Gemeinschaftstour **oder** (`ohneBeitrag` an und erlaubt: Tagestour mit Zielgruppe `Familienwanderungen`).
9. Netto je Teilnahme: `netto(p) = p × (1 − fee.p) − fee.f` (bei p ≤ 0: 0). `dbTN = netto(pM) − varTN`.
10. Kostendeckend ab: `breakEven = ceil(kosten / dbTN − 1e−9)` (nur bei dbTN > 0).
11. Zahlungsgebühren bei Mindestanzahl: `minTN × (pM − netto(pM))`.
12. Ein eigener Beitrag unter `vorschlag` löst eine Warnung aus (Abschnitt 6), wird aber übernommen.

Rundungsreihenfolge: Gebühr wird ungerundet eingerechnet, erst `roh` wird auf volle 5 € aufgerundet; der Nichtmitgliederbeitrag wird aus dem gerundeten Mitgliederbeitrag berechnet und erneut aufgerundet. Anzeigen runden auf ganze Euro bzw. 2 Nachkommastellen (`toLocaleString('de-DE')`).

**Durchgerechnetes Beispiel (Beispieldaten):**

| Größe | Rechnung | Ergebnis |
|---|---|---|
| honorar | 1 Trainer × 5 × 50 € | 250 € |
| org | 5 × 10 € | 50 € |
| leit | 2 × 105 + 5 × 45 + 5 × 0 | 435 € |
| kosten | 250 + 50 + 435 + 0 | 735 € |
| SEPA | (147 + 0,4165) / (1 − 0,01785) | 150,10 € |
| Karte | (147 + 0,2975) / (1 − 0,03451) | 152,56 € |
| PayPal (größter Wert) | (147 + 0,6902) / (1 − 0,05355) | 156,05 € |
| vorschlag | ceil(156,05 / 5) × 5 | **160 €** |
| Nichtmitglieder (nur bei Ausnahme) | ceil(160 × 1,3 / 5) × 5 = ceil(41,6) × 5 | 210 € |
| netto(160) | 160 × 0,94645 − 0,6902 | 150,74 € |
| breakEven | ceil(735 / 150,74) | 5 TN |
| Ergebnis bei 5 TN | 5 × 150,74 − 735 | 18,71 € |
| Ergebnis bei 8 TN | 8 × 150,74 − 735 | 470,93 € |
| Zahlungsgebühren bei 5 TN | 5 × (160 − 150,74) | 46,29 € |
| selbst je TN | 4 × 63,5 + 1 × 210 + 5 × 15 | 539 € |

### 4.6 Überschuss bei voller Belegung

`ergMin = minTN × dbTN − kosten`, `ergMax = maxTN × dbTN − kosten`. Ist `ergMax > 0` und `maxTN > minTN`, zeigt das Formular: „Bei voller Belegung bleiben … übrig. Der Überschuss bleibt bei der Sektion und gleicht Touren ohne Überschuss aus.“ Status „kostendeckend“, wenn `ergMin ≥ −0,005`, sonst „nicht gedeckt“.

### 4.7 CO2

Faktoren in Abschnitt 5.3.

- Je Teilstrecke: `kg = km × (rt ? 2 : 1) × (Fahrzeugmodus ? f : p) × Faktor / 1000`. Fahrzeugmodus (g je Fahrzeug-km) = `pkw`, `epkw`, `van`; alle anderen g je Personen-km. Unbekannter Modus → 0.
- `mob` = Summe aller Teilstrecken.
- `stay = naechte × co2Pers × Faktor(unterkunft)`, 0 bei `keine`.
- `food = co2Pers × days × (naechte > 0 ? 4,7 : 1,6)`; 0, wenn `days = 0`.
- `tour = mob + food + (unterkunft = huette ? 0 : stay)` (DAV-Hütten werden der Hütten-Sektion zugerechnet).
- `all = mob + stay + food`; je Person `all / co2Pers`; je Person und Tag `all / co2Pers / days`.
- Klimaschutzbudget = `tour / 1000 × rCO2` (€).
- Statusanzeige: Anteil von PKW, E-PKW, Kleinbus und Flug an `mob` < 25 % → „überwiegend ÖPV“, < 50 % → „gemischt“, sonst „überwiegend PKW/Flug“; ohne Anreise „Anreise fehlt“.
- Leipziger Richtwert: `lim = rKmTag1 + max(days − 1, 0) × rKmTagN`. Hinweis, wenn eine Teilstrecke mit `pkw`, `epkw` oder `van` km einfach > `lim` hat.

Beispieldaten: Bahn 650 × 2 × 9 × 26 / 1000 = 304,2 kg; Bus 30 × 2 × 9 × 90 / 1000 = 48,6 kg; `mob` 352,8 kg; `stay` 4 × 9 × 9,32 = 335,52 kg (Hütte, nicht im Tourbudget); `food` 9 × 5 × 4,7 = 211,5 kg; `tour` 564,3 kg; je Person 899,82 / 9 ≈ 100 kg; je Person und Tag ≈ 20 kg; Budget 564,3 / 1000 × 140 = 79,00 €; Richtwert 150 + 4 × 100 = 550 km.

### 4.8 Kondition und Technik

- Kondition-Vorschlag aus `g = gehzeit`, `h = max(hmAuf, hmAb)`, nur wenn `g` oder `h` > 0: `g > 8 oder h > 1500` → „sehr groß“; `g > 6 oder h > 1000` → „groß“; `g > 4 oder h > 500` → „mittel“; sonst „gering“. Weicht die gewählte Kondition ab, erscheint „Nach Gehzeit und Höhenmetern passt eher „…“.“ Beispiel: 7 h, 1.000 Hm → „groß“, keine Abweichung.
- Technik: keine automatische Prüfung. Die Skala ist nur beschrieben (Abschnitt 3.1 und Formulartexte: leicht = blaue Wege, T1, bis UIAA III, Klettersteig A/B; mittel = rote Wege, T2–T3, bis UIAA IV, KS C, Hochtour L/WS; schwer = schwarze Wege, T4, bis UIAA VI, KS D, Hochtour ZS; sehr schwer = alpine Routen, T5–T6, darüber, KS E, S und schwerer). [ANNAHME] Diese Zuordnung und die Konditionsgrenzen sind eigene Vorschläge aus dem Chat, kein DAV-Standard.
- Qualifikationsprüfung (nur Hinweis): Keine der nicht helfenden Personen hat eine Qualifikation, die die Sportart abdeckt → Hinweis. Abdeckung ([ANNAHME], eigene Zuordnung im Chat):

| Qualifikation | deckt ab |
|---|---|
| Trainer*in C Bergwandern | Wandern, Sport- und Langstreckenwandern, Bergwandern |
| Trainer*in C Bergsteigen | Wandern, Sport- und Langstreckenwandern, Bergwandern, Bergsteigen, Klettersteig |
| Trainer*in B Hochtouren | Wandern, Bergwandern, Bergsteigen, Klettersteig, Hochtour |
| Trainer*in C Skibergsteigen | Skitour, Schneeschuhtour |
| Trainer*in C Sportklettern | Klettern, Bouldern |
| Trainer*in B Alpinklettern | Klettern, Alpinklettern, Bergsteigen, Klettersteig |
| Wanderleiter*in | Wandern, Sport- und Langstreckenwandern |
| Übungsleiter*in B Prävention | Wandern |

### 4.9 Gemeinschaftstour

- Kein Teilnahmebeitrag, keine Vergütung, keine Organisationspauschale, keine Erstattung (`frei = true`, `kosten`-Bestandteile 0).
- Ausgeblendet: Vergütung, Kosten der Leitung, Sonstige Tourkosten, Leistungen je TN, Preisfelder, Bestätigungen `c1`–`c3`, „Ohne Teilnahmebeitrag“, Begründung Nichtmitglieder, PKW-Begründung.
- Eingeblendet und Pflicht: `gtGrund`.
- Sichtbar bleibt „Selbst zu zahlen“ (Information für die Ausschreibung).
- Ausschreibungstext: „Gemeinschaftstour ohne Teilnahmebeitrag. Alle Kosten tragen die Teilnehmenden selbst.“; keine Stornozeile, keine Mindestteilnehmer-Zeile.
- Warnungen zu PKW > 500 km, Übernachtung > 70 € und Lizenz entfallen.
- Eingabeblatt: Tarife „kein Tarif nötig (kostenlos)“ bzw. „nicht anlegen (nur Mitglieder)“, Zahlung und Storno „entfällt“.

---

## 5. Sätze und Annahmen

### 5.1 Sätze

Alle Werte sind Standardwerte (`value`-Attribute) in der HTML-Datei.

| Feld | Bezeichnung | Wert | Einheit | Quelle | Gültig ab |
|---|---|---|---|---|---|
| `rTL` | Tagessatz Trainer/WL | 50 | € | Vergütungsordnung 2025 (Finanzordnung), Anhang 1, „Mehrtageskurse/Führungstouren/Trainingslager“ | [UNBEKANNT]; Beschluss Vorstand 21.11.2023, Ziff. 9–11 der Auszahlungsmodalitäten ergänzt 11.12.2025 |
| `rTLh` | Halbtagessatz Trainer/WL | 25 | € | wie oben | wie oben |
| `rH` | Tagessatz Helfer | 40 | € | wie oben | wie oben |
| `rHh` | Halbtagessatz Helfer | 20 | € | wie oben | wie oben |
| `rOrg` | Organisationspauschale je Tag | 10 | € | wie oben | wie oben |
| `rLE` | Lehreinheit Kurs (1 h) | 15 | € | Vergütungsordnung 2025, Anhang 1, „Kurse“ | wie oben |
| `rKm` | PKW je km | 0,20 | €/km | Reisekostenordnung 2023, Ziff. 9 | in Kraft 11.04.2023 (Ziff. 2 geändert 07.01.2025) |
| – | Zuschlag Mitfahrende | bis 0,05 | €/km | Reisekostenordnung Ziff. 9 | nur als Hinweistext, kein Satzfeld |
| `rUe` | Übernachtung max. je Nacht | 70 | € | Reisekostenordnung Ziff. 2 (geändert 07.01.2025) | 07.01.2025 |
| `rSH` | Fahrtpauschale Sulzenauhütte | 240 | € | Reisekostenordnung Ziff. 9 | 11.04.2023 |
| `rKSH` | Fahrtpauschale Karl-Stein-Hütte | 60 | € | Reisekostenordnung Ziff. 9 | 11.04.2023 |
| `rNM` | Aufschlag Nichtmitglieder | 30 | % | Festlegung Tourenreferat (Chat, 11.10.2026) | [UNBEKANNT] |
| `rRund` | Runden auf volle € | 5 | € | Festlegung Tourenreferat (Chat, 11.10.2026); Folienbeispiel 147 € → 150 € | [UNBEKANNT] |
| `rVat` | MwSt. auf Zahlungsgebühren | 19 | % | [ANNAHME]: Screenshot der Yolawo-Gebühren sagt „zzgl. MwSt.“, der Satz 19 % ist angenommen | – |
| `rCO2` | Interner CO2-Preis | 140 | €/t | DAV-Klimaschutzkonzept (Fassung HV 22.11.2025), Haushaltsjahre 2025–2027 | 2025 |
| `rKmTag1` | Leipziger Richtwert PKW-Entfernung 1. Tag | 150 | km | Festlegung Tourenreferat (Chat, 11.10.2026), angelehnt an die Anreiseregelung der Sektion Köln | ab 2027, nicht verbindlich, nach einem Jahr auswerten |
| `rKmTagN` | … je weiterem Tag | 100 | km | wie oben | wie oben |
| – | PKW über 500 km nur mit Genehmigung | 500 | km | Reisekostenordnung Ziff. 6 | fest im Code |
| – | Hüttenpreis-Plausibilität Ü+HP | 45–90 | € | [ANNAHME] aus Recherche Hüttenpreise 2026 | fest im Code |

### 5.2 Zahlungsgebühren (Yolawo, zzgl. MwSt.)

Quelle: Screenshot der Yolawo-Zahlmethoden, vom Tourenreferat im Chat geliefert (Oktober 2026).

| Feld (aktiv / % / fix) | Zahlmethode | % | fix € | aktiv |
|---|---|---|---|---|
| `feSepaOn` / `feSepaP` / `feSepaF` | SEPA-Lastschrift | 1,5 | 0,35 | ja |
| `feCardOn` / `feCardP` / `feCardF` | Kredit- / Debitkarte | 2,9 | 0,25 | ja |
| `fePaypalOn` / `fePaypalP` / `fePaypalF` | PayPal | 4,5 | 0,58 | ja |
| `feKlarnaOn` / `feKlarnaP` / `feKlarnaF` | Klarna | 4,3 | 0,35 | nein |
| `feUebOn` / `feUebP` / `feUebF` | Überweisung (online, nicht freigeschaltet) | 1,9 | 0,35 | nein |

### 5.3 Emissionsfaktoren

| Schlüssel | Bezeichnung | Faktor | Einheit | Quelle |
|---|---|---|---|---|
| `bahnFV` | Bahn Fernverkehr | 26 | g je Personen-km | Umweltbundesamt, TREMOD 6.71B, Bezugsjahr 2024, inkl. Vorkette |
| `bahnNV` | Bahn Nahverkehr | 44 | g je Personen-km | UBA wie oben |
| `bus` | Fernbus / Reisebus | 30 | g je Personen-km | UBA Fernlinienbus; für Reisebus [ANNAHME] Näherung |
| `linienbus` | Linienbus Nahverkehr | 90 | g je Personen-km | UBA |
| `tram` | Straßenbahn / U-Bahn | 42 | g je Personen-km | UBA |
| `pkw` | PKW (Verbrenner) | 230 | g je Fahrzeug-km | abgeleitet: UBA 164 g/Pkm × 1,4 Personen |
| `epkw` | PKW (Elektro) | 98 | g je Fahrzeug-km | abgeleitet: UBA 70 g/Pkm × 1,4 Personen |
| `van` | Kleinbus / Sektionsbus | 232 | g je Fahrzeug-km | Klima-Rechner der DAV-Sektion Köln (9-Sitzer/Van) |
| `flug` | Flug | 290 | g je Personen-km | UBA Flug Inland (laut Recherche inkl. Nicht-CO2-Effekte) |
| `rad` | Fahrrad / zu Fuß | 0 | g je Personen-km | [ANNAHME] |
| `huette` | Übernachtung DAV-Hütte | 9,32 | kg je Person und Nacht | Klima-Rechner Sektion Köln |
| `svh` | Übernachtung Selbstversorgerhütte / Ferienwohnung | 9,32 | kg je Person und Nacht | [ANNAHME] wie Hütte |
| `hotel` | Übernachtung Pension / Hotel | 16,8 | kg je Person und Nacht | Klima-Rechner Sektion Köln |
| `camping` | Übernachtung Zelt / Camping | 4,5 | kg je Person und Nacht | Klima-Rechner Sektion Köln |
| `mitUe` | Verpflegung je Tag mit Übernachtung | 4,7 | kg je Person und Tag | Klima-Rechner Sektion Köln |
| `ohneUe` | Verpflegung je Tag ohne Übernachtung | 1,6 | kg je Person und Tag | Klima-Rechner Sektion Köln |

Die DAV-eigenen Faktoren des Bilanzierungstools (Code Gaia) sind nicht öffentlich und nicht eingetragen.

Im Code stehen die Faktoren in den Konstanten `MODES`, `STAY`, `FOOD`; die Eingabefelder (`cf_<schlüssel>`) werden daraus erzeugt.

### 5.4 Weitere fest im Code hinterlegte Werte

| Was | Wert | Ort im Code |
|---|---|---|
| Stornoregel | „bis 4 Wochen vor Beginn 90 % Rückerstattung, bis 2 Wochen vor Beginn 50 %, danach keine Erstattung“ | `stornoText()` |
| Empfänger | tourenreferat@dav-leipzig.de | `MAIL_TO` |
| Ausnahme „ohne Beitrag“ | nur Zielgruppe `Familienwanderungen` als Tagestour | `FREI_KAT`, `freiErlaubt()` |
| Qualifikationen ohne Trainersatz | `''`, `Trainer*in in Ausbildung`, `ohne DAV-Qualifikation` | `OHNE_LIZENZ` |
| Hüttenrichtwerte 2026 (nur Infotext) | Kat. I Mitglieder max. Lager 15 €, Mehrbettzimmer 25 €, Zweibettzimmer 36 €; Nichtmitglieder mind. 12 € mehr; HP meist 42–50 €; Sulzenauhütte HP 47,50 €, Lager + HP 63,50 €; Dresdner Hütte 50 €, Johannishütte 42 €; Bergsteigeressen max. 11 €; Nächtigungsabgabe Tirol ca. 1–3 €; Planwert Nebenkosten 15 €/Tag; Taschachhaus 2027: 18 / 30 / 44 € | HTML-Text in Schritt 6 |

### 5.5 Sperre „Sätze bearbeiten“

- Beim Start werden alle Eingaben in „Sätze und Annahmen“ deaktiviert (`disabled`). Es gibt **kein Passwort**, nur einen Knopf „Sätze bearbeiten“, der sie für die laufende Sitzung freigibt.
- Geänderte Sätze werden **nicht gespeichert** (weder im Entwurf noch in der Einreichung) und gelten nur bis zum Neuladen.
- Dauerhafte Änderung: in der HTML-Datei (`value`-Attribute bzw. Konstanten `MODES`, `STAY`, `FOOD`), danach `Tourenkonzept_DAV-Leipzig.html` neu erzeugen und verteilen.
- Wer ändern darf: laut Formular „pflegt das Referat“. Die Vergütungs- und Reisekostensätze beschließt der Vorstand. Technisch kann jede Person mit der Datei die Werte ändern.
- Folge: Ein PDF zeigt die Zahlen, mit denen die Tourenleitung gerechnet hat. Beim Öffnen rechnet das Formular mit den Sätzen der dort geöffneten Version neu.

---

## 6. Prüfungen und Hinweise

### 6.1 Pflichtangaben (`checks()`)

Jede Pflichtangabe zählt einmal; Fortschritt = erfüllt / gesamt. Ausgeblendete Felder werden nicht geprüft.

| Bezeichnung in „fehlt“ | Bedingung |
|---|---|
| Begründung Gemeinschaftstour | `gtGrund` leer und Tourtyp Gemeinschaftstour |
| E-Mail Tourenleitung | `kontaktMail` leer |
| Notfallkontakt Name | `notfallName` leer |
| Notfallkontakt Telefon | `notfallTel` leer |
| Titel | `titel` leer |
| Sportart | `sportart` leer |
| Gebiet / Region | `region` leer |
| Kurzbeschreibung | `teaser` leer |
| Beginn (Datum) | `dStart` leer |
| Treffzeit | `tStart` leer |
| Ende (Datum) | `dEnd` leer |
| Treffpunkt | `treffpunkt` leer |
| Voraussetzungen | `vorauss` leer |
| Begründung Nichtmitglieder | `nmGrund` leer, `auchNM` an, keine Gemeinschaftstour |
| Ausrüstung | `ausruestung` leer |
| Mindestanzahl Teilnehmende | `minTN` leer |
| Höchstanzahl Teilnehmende | `maxTN` leer |
| Anmeldeschluss | `anmeldeschluss` leer |
| Begründung PKW-Fahrt | `pkwGrund` leer, Zeile in „Kosten der Leitung“ beginnt mit „PKW“, keine Gemeinschaftstour |
| Bestätigung Lizenz / Kalkulation / ÜL-Erklärung | `c1` / `c2` / `c3` nicht gesetzt (nicht bei Gemeinschaftstour) |
| Bestätigung Notfallkarte | `c4` nicht gesetzt |
| Tourtyp, Titelbild, Anreise mit ÖPNV, Kondition, Technik | Radiogruppe ohne Auswahl |
| Leitung mit Qualifikation | keine Person mit Name **und** Qualifikation |
| Bildrechte | `bild = eigen` und `bildrechte` leer |
| Geplante An- und Abreise (CO2) | keine Teilstrecke mit km > 0 und Personen bzw. Fahrzeugen > 0 |

Nur in der Schritt-Übersicht (nicht in `fehlend` des PDFs): „Beitrag (Mindestanzahl in Schritt 5 fehlt)“ bei Schritt 6, wenn weder Gemeinschaftstour noch „ohne Beitrag“ noch ein berechenbarer Beitrag vorliegt.

Rote Markierung eines Pflichtfelds erst nach der ersten Eingabe darin; „PDF erstellen“, Klick auf einen offenen Schritt und der Knopf „x offen“ (Handy) markieren alle offenen Felder.

### 6.2 Warnungen (Liste „Hinweise“ in der Seitenleiste)

| Auslöser | Text |
|---|---|
| `minTN > maxTN` | Mindestanzahl ist größer als Höchstanzahl |
| `anmeldeschluss ≥ dStart` | Anmeldeschluss liegt nicht vor Tourbeginn |
| Beginn weniger als 6 Monate (6 × 30,4 Tage) ab heute; gilt für alle Touren | Weniger als 6 Monate bis Tourbeginn |
| `dEnd < dStart` | Ende liegt vor Beginn |
| Teilstrecke Flug mit 0 < km < 1000 | Flug unter 1000 km: nach DAV-Selbstverpflichtung ausgeschlossen |
| Summe der Mengen aller PKW-Zeilen in „Kosten der Leitung“ > 500 (keine Gemeinschaftstour) | PKW über 500 km: vorher vom geschäftsführenden Vorstand genehmigen lassen |
| Zeile mit „Übernachtung“ in „Kosten der Leitung“ und Einzelpreis > `rUe` (keine Gemeinschaftstour) | Übernachtung über 70 € pro Nacht: vorher Zustimmung einholen |
| Person mit Qualifikation, Rolle nicht Helfer*in, ohne Trainersatz (keine Gemeinschaftstour) | Ohne gültige Lizenz oder Jahresangabe wird der Helfersatz gerechnet |
| eigener Beitrag `pM` < `vorschlag` (nicht bei `frei`) | Beitrag liegt unter dem kostendeckenden Vorschlag |

### 6.3 Hinweise an den Feldern

| Ort | Auslöser | Text |
|---|---|---|
| Schritt 1 | Führungstour/Kurs, keine nicht helfende Person deckt die Sportart ab | „Keine der angegebenen Qualifikationen deckt **{Sportart}** als Führungstour ab. Bitte Qualifikation, Sportart oder Tourtyp prüfen.“ |
| Schritt 1 | Lizenzjahr < Tourjahr | „Mindestens eine Lizenz läuft vor dem Tourjahr {Jahr} ab.“ |
| Schritt 3 | Tage > 0 | „{Eventart}, {n} Tag(e)[, ca. {h} h]“ |
| Schritt 3 | PKW/E-PKW/Kleinbus mit Personen ÷ Fahrzeuge < 3 | „PKW-Fahrgemeinschaften möglichst mit mindestens 3 Personen je Fahrzeug (Leitlinien des DAV: erst ÖPV, dann Fahrgemeinschaft).“ |
| Schritt 3 | Teilstrecke PKW/E-PKW/Kleinbus km > Richtwert | „Die PKW-Strecke liegt über dem Leipziger Richtwert von {lim} km für {n} Tag(e) ({rKmTag1} km plus {rKmTagN} km je weiterem Tag). Bitte prüfe eine Anreise mit Bahn und Bus oder begründe die Entfernung in den Hinweisen.“ |
| Schritt 3 | Unterkunft DAV-Hütte und `stay` > 0 | „Übernachtungen auf DAV-Hütten ({kg}) rechnet das DAV-Bilanzierungstool der Sektion zu, der die Hütte gehört. Sie zählen deshalb nicht zum Klimaschutzbudget dieser Tour.“ |
| Schritt 4 | Kondition weicht vom Vorschlag ab | „Nach Gehzeit und Höhenmetern passt eher „{Vorschlag}“.“ |
| Schritt 5 | `minTN > maxTN` | „Die Mindestanzahl ist größer als die Höchstanzahl.“ |
| Schritt 6 | Personen mit Helfersatz (`nH > 0`) | „{n} Person(en) wird/werden mit dem Helfersatz gerechnet (Rolle Helfer*in oder keine gültige Lizenz).“; bei eintägigem Kurs: „… bei eintägigen Kursen nicht vergütet (Lehreinheiten nur mit gültiger Lizenz).“ |
| Schritt 6 | Summe PKW-km > 500 | „Fahrten mit dem eigenen PKW über 500 km muss der geschäftsführende Vorstand vorher genehmigen.“ |
| Schritt 6 | Unterkunft DAV-Hütte, `minTN ≥ 5`, Übernachtungszeile der Leitung mit Preis > 0 | „Auf Alpenvereinshütten übernachtet die Leitung ab 5 Teilnehmenden kostenlos („5 plus 1“). Prüfe, ob die Übernachtungskosten der Leitung entfallen.“ |
| Schritt 6 | Zeile in „Selbst zu zahlen“ mit „hütte“ und „Halbpension“/„HP“ im Text, Preis < 45 oder > 90 | „Übernachtung mit Halbpension auf Alpenvereinshütten kostet für Mitglieder 2026 meist 60–68 € pro Nacht. Bitte den Wert prüfen.“ |
| Schritt 6 | Gemeinschaftstour | „Gemeinschaftstour: kein Teilnahmebeitrag, keine Vergütung und keine Erstattung durch die Sektion. Gib unten nur an, welche Kosten die Teilnehmenden selbst tragen.“ |
| Schritt 6 | „ohne Beitrag“ | „Ohne Teilnahmebeitrag trägt die Sektion {kosten}.“ |
| Schritt 6 | Überschuss (4.6) | „Bei voller Belegung bleiben {ergMax} übrig. …“ |
| Schritt 6 | Beitrag wird berechnet | „Zahlungsgebühren gerechnet mit {Methode} (teuerste aktive Zahlmethode, inkl. MwSt.).“ |

### 6.4 Statusanzeigen

| Anzeige | Werte |
|---|---|
| Teilnahmebeitrag (Pill) | „ohne Zahlung“ (Gemeinschaftstour), „Mindestanzahl fehlt“, „Sektion trägt Kosten“ (ohne Beitrag), „kostendeckend“, „nicht gedeckt“ |
| CO2-Bilanz (Pill) | „Anreise fehlt“, „überwiegend ÖPV“, „gemischt“, „überwiegend PKW/Flug“ |
| Fortschritt | „{erfüllt}/{gesamt}“, Balken, Liste der Schritte 1–7 mit „fertig“ oder „{n} offen“ (Tooltip: offene Bezeichnungen) |
| Speicherstatus | „Entwurf in diesem Browser gespeichert, {HH:MM} Uhr.“ / „Beispiel geladen. Sobald du etwas änderst, wird daraus dein Entwurf.“ / „Geöffnete Einreichung: wird nicht in diesem Browser gespeichert.“ / „Dieser Browser erlaubt kein Speichern. Erstelle zwischendurch ein PDF, damit nichts verloren geht.“ |
| Handy-Leiste (≤ 960 px) | Beitrag Mitglieder, „{n} offen“ bzw. „alles ausgefüllt“, Knopf „PDF“ |

---

## 7. Ausgaben

### 7.1 Yolawo-Eingabeblatt (`yolawoFields()`)

| Gruppe | Feld | Inhalt / Formatierung |
|---|---|---|
| Angebot | Angebotstyp | fest „Ausfahrt, Reise, Tour“ (Yolawo-Typ `TOUR`) |
| Angebot | Titel | `titel` |
| Angebot | Kategorien | siehe 4.2a, kommagetrennt |
| Angebot | Titelbild | `eigen` → „Foto der Tourenleitung (Anhang), {bildrechte oder ‚Bildrechte fehlen‘}“; `referat` → „Referat wählt ein Bild“ |
| Angebot | Beschreibung | Verweis „→ Reiter „Beschreibungstext“ (Überschriften fett setzen)“ |
| Buchungsoption | Typ | fest „Einzeltermin“ |
| Termin | Beginn | `dStart` als „Mo., 12.07.2027“, dazu „, {tStart} Uhr“ |
| Termin | Ende | `dEnd` entsprechend, mit `tEnd` |
| Termin | Ort | `treffpunkt` und `koord`, zeilenweise |
| Buchungsoption | Kapazität | `maxTN` |
| Buchungsoption | Buchungszeitraum Ende | `anmeldeschluss` als Datum, „, 23:59 Uhr“ |
| Buchungsoption | Warteliste | „aktiv“ / „aus“ |
| Tarif | „DAV-Mitglied“ | `pM` mit 2 Nachkommastellen; zweite Zeile „Beschreibung: Im Tarif enthalten sind: Touren-/Kursleitung, Organisation[, Leistungen je TN]“; bei `frei`: „kein Tarif nötig (kostenlos)“ |
| Tarif | „Nichtmitglied“ | Standard: „nicht anlegen (nur Mitglieder)“; Ausnahme: `pN` und Beschreibung wie oben |
| Zahlung | Zahlungsart | „Onlinezahlung“ bzw. „entfällt“ |
| Anmeldezeitraum & Rückerstattung | Stornoregeln | Stornotext (5.4) bzw. „entfällt“ |
| Anmeldeformular | Zusätzliche Fragen | gewählte Fragen und `frageEigen`, zeilenweise |
| Intern, kein Yolawo-Feld | Mindestanzahl | „{minTN} (steht im Beschreibungstext; Absage prüfen am {Anmeldeschluss})“ |

Leere Felder erscheinen rot als „fehlt“. Jedes Feld hat einen Knopf „Kopieren“.

Gesicherte Yolawo-Fakten aus der Recherche im Chat (11.10.2026): kein Angebotsimport; kein Feld für Mindestteilnehmende; Tarife bestehen aus Titel, Beschreibung, Betrag; Warteliste mit 48 h Annahmefrist; Stornoregeln als Prozent-Erstattung nach Fristen; Buchungsoption „Einzeltermin“. [UNBEKANNT] ob die Feldbezeichnungen genau denen der Yolawo-Verwaltungsoberfläche entsprechen; sie stammen aus dem öffentlichen Buchungs-Widget und der Yolawo-Hilfe.

### 7.2 Ausschreibungstext (`descText()`)

Vorlage; Zeilen in eckigen Klammern nur, wenn Werte vorhanden bzw. Bedingung erfüllt. Leerzeilen trennen Abschnitte; die Abschnittsüberschriften sollen in Yolawo fett gesetzt werden.

```
[{teaser}]

[Ablauf
{programm}]

Tourdaten (Kurzinfo)
Termin: {Mo., 12.07.2027 bis Fr., 16.07.2027 | eintägig nur das Datum}
[Tourenart: {sportart}]
[Tourtyp: {Führungstour | Führungstour / Kurs | Gemeinschaftstour}]
[Schwierigkeit Kondition: {kond}]
[Schwierigkeit Technik: {tech}[ ({grad})]]
[Etappen: {bis {gehzeit} h Gehzeit}, {hmAuf} Hm ↑, {hmAb} Hm ↓, {km} km pro Tag]
[Teilnehmende: {minTN|?} bis {maxTN|?}]
[Klimabilanz: ca. {kg je Person} CO2e pro Person (An- und Abreise {kg}, Unterkunft und Verpflegung {kg})]
[Gebiet: {region}[, Stützpunkt {stuetzpunkt}]]

[Voraussetzungen
{vorauss}
[Mitgliedschaft im DAV]            ← bei „nur DAV-Mitglieder“]

[Ausrüstung
{ausruestung}]

Kosten
{Gemeinschaftstour: „Gemeinschaftstour ohne Teilnahmebeitrag. Alle Kosten tragen die Teilnehmenden selbst.“
 | ohne Beitrag: „Für die Teilnahme wird kein Beitrag erhoben.“
 | sonst: „Teilnahmebeitrag: {pM} für DAV-Mitglieder[ / {pN} für Nichtmitglieder]“}
[Im Beitrag enthalten: Leitung und Organisation[, {Leistungen je TN}]]          ← nicht bei frei
[Zusätzlich selbst zu zahlen (ca.): {Position}[ ca. {m×p}]; …]
[Mindestteilnehmerzahl: {minTN}. Wird sie bis zum Anmeldeschluss nicht erreicht, sagen wir die Tour ab und erstatten bereits gezahlte Beiträge.]   ← nicht bei frei
[Anmeldeschluss: {Datum}]
[Stornierung: Bis 4 Wochen vor Beginn 90 % Rückerstattung, bis 2 Wochen vor Beginn 50 %, danach keine Erstattung. Sagen wir die Tour ab, erhaltet ihr den vollen Beitrag zurück.]   ← nicht bei frei

[Leitung
{Name} ({Qualifikation ohne „*in“, entfällt bei „ohne DAV-Qualifikation“})[, {Rolle, wenn nicht Leitung}]
…]

Vorbesprechung
{keine: „Eine Vorbesprechung ist nicht erforderlich. Alle wichtigen Informationen erhaltet ihr rechtzeitig vor der Tour per E-Mail.“
 | online: „Online-Vorbesprechung[ am {Mi., 14.06.2027, 19:00} Uhr].“
 | praesenz: „Vorbesprechung in der Geschäftsstelle[ am … Uhr].“}

Treffpunkt
Treffpunkt: {treffpunkt | …}
Treffzeit: {tStart} Uhr | …

[Öffentliche Anreise & Fahrgemeinschaften
{gemeinsam: „Eine gemeinsame Anreise mit öffentlichen Verkehrsmitteln ist vorgesehen.“
 | moeglich: „Die Anreise mit öffentlichen Verkehrsmitteln ist möglich.“
 | nein: „Eine Anreise mit öffentlichen Verkehrsmitteln ist nicht sinnvoll möglich. Fahrgemeinschaften könnt ihr über Moobly bilden.“}
[{anreise}]]

[{bildrechte}]                      ← nur bei eigenem Foto
```

### 7.3 Zusammenfassung (Reiter „Einreichen“ → „Zusammenfassung kopieren“, `mailText()`)

```
TOURENKONZEPT: {titel | (ohne Titel)}
Eingereicht am {heute}
Yolawo-Eingabe durch: {Tourenreferat | Tourenleitung (selbst)}

LEITUNG
- {Name}, {Qualifikation | Qualifikation fehlt}, {Rolle}, Lizenz bis {Jahr | ?}
Kontakt: {kontaktMail}, {kontaktTel}
Notfallkontakt Tourenleitung: {notfallName}, {notfallTel} | FEHLT
[Notfallkontakte weitere: {notfallWeitere}]
[Begründung Gemeinschaftstour: {gtGrund}]

YOLAWO-FELDER
{Gruppe} · {Feld}: {Wert | FEHLT}      ← je Zeile aus 7.1

KALKULATION
{Gemeinschaftstour: „Gemeinschaftstour: keine Kalkulation, keine Vergütung oder Erstattung“
 | Vergütung Leitung: {honorar} ({n Lehreinheiten | n Tagessätze, n Halbtagessätze}[, davon n mit Helfersatz])}
[PKW-Begründung: {pkwGrund | FEHLT}]
Organisationspauschale: {org} ({Tage} Tage)
[Kosten der Leitung: {leit}
- {Position}: {m} × {p} = {m×p}]
[Sonstige Tourkosten: …] [Leistungen je TN: …]
Gesamtkosten (fix): {kosten}
{ohne Beitrag: „Teilnahmebeitrag: ohne Beitrag (Familienwanderung als Tagestour)“
 | Kostendeckender Beitrag bei {minTN} TN: {vorschlag} (rechnerisch {roh} inkl. Zahlungsgebühren)
   Gewählter Beitrag: {pM} Mitglieder[ / {pN} Nichtmitglieder]
   Kostendeckung ab {breakEven} TN; Ergebnis bei {minTN} TN: {ergMin}, bei {maxTN} TN: {ergMax}}

CO2-BILANZ (Planung)
- {Verkehrsmittel} ({Strecke}): {km} km {hin und zurück | einfach}, {n Fahrzeug(e), n Personen | n Personen} = {kg}
An- und Abreise: {kg}
[Unterkunft: {kg} ({n} Nächte, {Unterkunftsart}[, wird der Hütten-Sektion zugerechnet])]
Verpflegung: {kg}
Tour gesamt (Sektionsbilanz): {kg}; je Person {kg} bei {n} Personen
Klimaschutzbudget bei {rCO2} €/t: {€}
Treffpunkt ≤ 1,5 km von ÖPV-Haltestelle: {ja | nein}

INTERN
{Teilnahme: nur DAV-Mitglieder | Ausnahme Nichtmitglieder: {nmGrund | Begründung FEHLT}}
Stornobedingungen Unterkunft: {stornoUnterkunft | –}
Hinweise: {hinweise | –}
Bestätigungen: Lizenz {ja|nein}, Abrechnung {…}, ÜL-Erklärung {…}, Notfallkarte {…}   ← ausgeblendete fehlen
Feedbackbogen nach der Tour: {ja | nein}

––– BESCHREIBUNGSTEXT –––
{Ausschreibungstext aus 7.2}
```

Mehr als eine Leerzeile in Folge wird auf eine reduziert.

### 7.4 E-Mail-Entwurf

| Teil | Inhalt |
|---|---|
| Empfänger | tourenreferat@dav-leipzig.de (Konstante `MAIL_TO`) |
| Betreff | „Tourenkonzept: {titel \| neue Tour}[ ({Termin wie im Ausschreibungstext})]“ |
| Text | „Hallo Tourenreferat,⏎⏎anbei mein Tourenkonzept als PDF[ und das Titelfoto].⏎⏎Viele Grüße⏎{Name der ersten Person mit Name}“ |
| Technik | `mailto:`-Link mit `encodeURIComponent`; Anhänge sind über `mailto` nicht möglich, PDF und Foto hängt die Person selbst an. Adresse und Betreff gibt es zusätzlich als Kopierknöpfe. |

### 7.5 PDF

**Erzeugung.** jsPDF 2.5.1 (eingebettet, Abschnitt 9), `new jsPDF({unit:'mm', format:'a4', compress:false})`, Schrift Helvetica (Standardschrift, nur WinAnsi-Zeichen). Text wird vorher mit `pdfSafe()` bereinigt: Unicode-Normalisierung NFC; ↑ → „auf“, ↓ → „ab“, ✓ → „ja“, ✗ → „nein“, ≤ → „<=“, → → „->“; schmale/geschützte Leerzeichen → Leerzeichen; alle übrigen Zeichen außerhalb Latin-1 und `€„“”‚‘’–—…•` → „?“.

**Dateiname.** `Tourenkonzept_{dStart | ohne-Datum}_{slug(titel) | ohne-Titel}.pdf`; `slug`: ä→ae, ö→oe, ü→ue, ß→ss (auch Großbuchstaben), alle anderen Nicht-Alphanumerischen → „-“, höchstens 60 Zeichen.

**Speichern.** In der claude.ai-Vorschau über die Plattformfunktion `window.claude.use('downloads').save(...)` (mit Bestätigung), sonst als Browser-Download über einen `blob:`-Link.

**Aufbau (A4, Rand 18 mm, Fußzeile „Tourenkonzept · {Titel}“ und „Seite x von y“):**

1. Kopfzeile „DAV SEKTION LEIPZIG · TOURENKONZEPT · EINREICHUNG AN DAS TOURENREFERAT“, Titel, Zeile mit Termin · Tourtyp · Sportart · Region
2. Statuskasten: „Vollständig ausgefüllt.“ (grün) oder „Noch unvollständig. Es fehlen: …“ (gelb)
3. Erstellt am, Yolawo-Eingabe durch
4. **Leitung und Kontakt**: je Person Rolle, Name, Qualifikation, Lizenz; E-Mail; Mobilnummer; Notfallkontakt; ggf. weitere Notfallkontakte und Begründung Gemeinschaftstour
5. **Yolawo-Eingabeblatt**: alle Felder aus 7.1 (Beschreibung: „siehe Ausschreibungstext am Ende“)
6. **Kalkulation**: Vergütung, Organisationspauschale, Kosten der Leitung mit Positionen, sonstige Kosten, Leistungen je TN, PKW-Begründung, Gesamtkosten, kostendeckender Beitrag (mit Methode), gewählter Beitrag, Ergebnis; „Selbst zu zahlen je TN“ mit Positionen. Bei Gemeinschaftstour nur der Satz „Gemeinschaftstour: kein Teilnahmebeitrag, keine Vergütung und keine Erstattung durch die Sektion.“
7. **CO2-Bilanz (Planung)**: wie in 7.3
8. **Intern**: Teilnahme/Ausnahme, Stornobedingungen Unterkunft, Hinweise, Bestätigungen („bestätigt“/„nicht bestätigt“, ausgeblendete fehlen), Feedbackbogen
9. **Ausschreibungstext**: Zeilen aus 7.2; eine Zeile gilt als Überschrift (fett, 11 pt), wenn davor eine Leerzeile steht, sie kürzer als 45 Zeichen ist, nicht auf `: . ! ?` endet und kein „: “ enthält

Dokumenteigenschaften: Titel „Tourenkonzept: {Titel}“, Thema „Tourenkonzept DAV Sektion Leipzig“, Autor = Namen der Leitung, Ersteller „Tourenkonzept-Formular DAV Sektion Leipzig“.

**Eingebettete Formulardaten.**

- Inhalt: das Objekt `Einreichung` (3.4) inklusive **aller** Formulardaten (also auch Kontakt- und Notfalldaten), als JSON.
- Kodierung: JSON → UTF-8 → Base64. Eingerahmt als `DAVTK1:{base64}:DAVTK1END`.
- Ablage: `doc.addMetadata(payload, 'https://www.dav-leipzig.de/tourenkonzept/')`. Im erzeugten PDF steht das unkomprimiert in einem XMP-Metadatenstrom (`/Type /Metadata /Subtype /XML`), als `<jspdf:metadata>DAVTK1:…:DAVTK1END</jspdf:metadata>` mit `xmlns:jspdf="https://www.dav-leipzig.de/tourenkonzept/"`. (Geprüft an einem erzeugten PDF.) Fehlt `addMetadata`, würde der Code ersatzweise das Dokumentfeld „Keywords“ nutzen; das kommt mit der eingebetteten jsPDF-Version nicht vor.
- Einlesen („Einreichung öffnen“): Datei als ArrayBuffer lesen (max. 25 MB). Beginnt sie mit `%PDF-`, wird sie als Latin-1 dekodiert und mit dem regulären Ausdruck `DAVTK1:([A-Za-z0-9+/=]+):DAVTK1END` durchsucht; Base64 → UTF-8 → JSON. Sonst wird die Datei direkt als JSON gelesen (Altformat aus einer kurzzeitig vorhandenen JSON-Einreichung). Gültig nur mit `format = "dav-leipzig-tourenkonzept"` und vorhandenem `daten`.
- Versionierung: `version` wird geschrieben, beim Einlesen aber **nicht ausgewertet**. Es gibt keine Migrationslogik. `apply()` übernimmt nur Schlüssel, die es in der aktuellen Version als Feld gibt; unbekannte Schlüssel werden ignoriert, ungültige Auswahlwerte auf den ersten Eintrag zurückgesetzt, ungültige Verkehrsmittel auf `bahnFV`.
- Folgen für ältere Stände (aus dem Chatverlauf bekannt): frühere Felder `notfallBez` (Beziehung), `nurMitglieder`, `storno`/`stornoEigen` (wählbare Stornoregel), `zahlung` (wählbare Zahlungsart) werden ignoriert. Ein älterer Entwurf, der Nichtmitglieder zuließ (`nurMitglieder` aus), öffnet sich jetzt als „nur DAV-Mitglieder“.
- Wird ein PDF nachbearbeitet oder neu gedruckt, gehen die eingebetteten Daten in der Regel verloren; dann ist es „kein PDF aus diesem Formular“.

---

## 8. Speicherung und Datenschutz

### 8.1 Browser-Speicher

| Schlüssel | Inhalt | Wann |
|---|---|---|
| `dav-lpz-tourenkonzept-v1` | Ergebnis von `collect()` (3.4) als JSON, inkl. Kontakt- und Notfalldaten | nach jeder Änderung (`update()` → `save()`), außer bei geöffneter Einreichung |
| `dav-lpz-tourenkonzept-guide` | `auf` / `zu` (Anleitung auf- oder zugeklappt) | beim Auf-/Zuklappen |

- Start: Ist ein Entwurf ohne `sample: true` gespeichert, wird er geladen; sonst das Beispiel. Fehler beim Laden → leeres Formular.
- „Formular leeren“ löscht `dav-lpz-tourenkonzept-v1` (mit Rückfrage).
- **Nie gespeichert**: die Sätze in „Sätze und Annahmen“ (inkl. Emissionsfaktoren und Gebühren), geöffnete Einreichungen (bis „Als meinen Entwurf übernehmen“), Dateien/Fotos.
- „Beispiel laden“ und „Formular leeren“ fragen nach, wenn ein eigener Entwurf vorhanden ist. Sobald man im Beispiel etwas ändert, wird es zum Entwurf (`sample: false`).

### 8.2 Kontakt- und Notfalldaten

- Erhoben: E-Mail, Mobilnummer der Tourenleitung; Name und Telefon des Notfallkontakts; Freitext für weitere Notfallkontakte. Das Feld „Beziehung“ wurde auf Wunsch des Tourenreferats entfernt.
- Nicht veröffentlicht, nicht in Yolawo. Sie stehen im PDF (sichtbar und eingebettet) und in der Zusammenfassung.
- Verbleib: im Browser der Tourenleitung (localStorage), im PDF beim Tourenreferat (E-Mail).
- Löschung: laut Formular „Das Tourenreferat löscht die Notfallkontakte nach Abschluss der Tour.“ [UNBEKANNT] ob Vorstand/Datenschutz dies bestätigt haben; technisch gibt es dafür nichts im Formular.

### 8.3 Datenschutzhinweise im Formular (wörtlich)

- Schritt 1, „Datenschutz“: „Deine Kontaktdaten und die Notfallkontakte werden nicht veröffentlicht und nicht nach Yolawo übertragen. Sie gehen mit dem PDF nur an das Tourenreferat und werden dort für Freigabe, Abrechnung und den Notfall während der Tour verwendet. Das Tourenreferat löscht die Notfallkontakte nach Abschluss der Tour.“ / „Das Formular sendet selbst keine Daten. Dein Entwurf wird nur in diesem Browser gespeichert. Auf einem fremden oder gemeinsam genutzten Rechner bitte nach dem Versand „Formular leeren“.“
- Unter „Notfallkontakte weiterer …“: „Nur Name und Telefonnummer. Bitte informiere deinen Notfallkontakt, dass du die Angaben an das Tourenreferat weitergibst.“
- Nach erfolgreichem PDF: „… Auf einem fremden oder gemeinsam genutzten Rechner danach „Formular leeren“, damit Kontakt- und Notfalldaten nicht im Browser bleiben.“
- Schritt 5, Hinweise: „Frag nur ab, was du für die Tour wirklich brauchst. Das Geburtsdatum z. B. nur bei Altersgrenzen.“
- Fußzeile: „Eingaben werden nur in diesem Browser gespeichert; das Formular sendet keine Daten.“
- Anleitung: „Dein Entwurf wird automatisch in diesem Browser gespeichert. Das Formular sendet selbst keine Daten.“

### 8.4 Bildrechte

Bei eigenem Foto ist „Bildrechte“ Pflicht; Hinweis „Nur Bilder verwenden, an denen du die Rechte hast.“; Hinweise zu Schritt 2: „möglichst Querformat, ohne erkennbare Personen oder nur mit deren Einverständnis. Bildrechte sind Pflicht; KI-Bilder bitte als solche kennzeichnen.“ Das Foto selbst wird nicht ins Formular geladen, sondern per E-Mail angehängt.

### 8.5 Technische Schutzmaßnahmen

- Keine Abrufe fremder Server: Google Fonts entfernt, jsPDF eingebettet.
- Content-Security-Policy als `<meta>`: `default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; img-src data: blob:; connect-src blob: data:; base-uri 'none'; form-action 'none'`; dazu `referrer: no-referrer`. Die Meta-CSP greift nur in der eigenständigen Datei; in der claude.ai-Vorschau steht sie im `<body>` und ist wirkungslos (dort gilt die CSP der Plattform).
- Alle nutzergenerierten Texte, die als HTML ausgegeben werden, laufen über `esc()` (`& < >`); Auswahlwerte aus Dateien werden beim Laden mit `CSS.escape` bzw. Positivlisten geprüft.

---

## 9. Technik

### 9.1 Bibliotheken

| Bibliothek | Version | Herkunft | Hinweis |
|---|---|---|---|
| jsPDF (UMD-Build `jspdf.umd.min.js`) | 2.5.1 | ursprünglich cdnjs, jetzt unverändert inline eingebettet | MIT-Lizenz; SHA-512 `qZvrmS2ekKPF2mSznTQsxqPgnpkI4DNTlrdUmTzrDgektczlKNRRhy5X5AAOnx5S09ydFYWWNSfcEqDTTHgtNA==` (mit dem cdnjs-Wert abgeglichen); genutzt: `jsPDF`, `text`, `splitTextToSize`, `rect`, `line`, `addPage`, `setDocumentProperties`, `addMetadata`, `output('blob')` |

Sonst keine Bibliotheken, kein Build-Schritt. Schriften: CSS nennt „Barlow Semi Condensed“, „Atkinson Hyperlegible“, „IBM Plex Mono“, lädt sie aber nicht; es greifen die Ersatzschriften (Roboto Condensed, Arial Narrow, Segoe UI, system-ui usw.).

[UNBEKANNT] ob für jsPDF 2.5.1 Schwachstellen bekannt sind, die diese Nutzung betreffen; das wurde im Chat nicht geprüft. `addImage` und `html` werden nicht verwendet.

### 9.2 Aufbau des Codes

Eine HTML-Datei: Stile (`<style>`), Markup (Schritte `#s1`…`#s7`, Einstellungen `#settings`, Seitenleiste `<aside>`, Ergebnis `#out`, Handy-Leiste `#mbar`), jsPDF-Skript, Anwendungsskript als IIFE.

**Zustand.** Der Zustand liegt im DOM (Eingabefelder). Es gibt kein Zustandsobjekt; `collect()` liest das DOM in das Datenobjekt (3.4), `apply(o)` schreibt es zurück. Zusätzliche Variablen: `touched` (Set), `persist` (bei geöffneter Einreichung `false`), `lastMiss`, `confirmAction`.

**Ablauf.** Jedes `input`- und `change`-Ereignis im Formular ruft `update()` auf: Vorschläge (`suggestDays`), Berechnung (`calc`, `calcCO2`), Sichtbarkeit, Prüfungen (`checks`), alle Ausgaben neu rendern, `save()`.

| Funktion | Aufgabe |
|---|---|
| `leaderRow`, `costRow`, `co2Row` | Tabellenzeilen erzeugen |
| `rows`, `leaders`, `co2Rows` | Tabellen auslesen |
| `collect`, `apply`, `save` | Datenobjekt lesen/schreiben/speichern |
| `days`, `hoursDay1`, `tourYear`, `suggestDays` | Termin und Vorschläge |
| `trainerSatz`, `freiErlaubt`, `pkwRows` | Regeln |
| `calc`, `calcCO2`, `co2Kg` | Berechnungen (4.3–4.7) |
| `checks` | Pflichtangaben und Warnungen (6) |
| `descText`, `yolawoFields`, `mailText`, `co2Mail`, `inclText`, `stornoText`, `fragenList`, `categories`, `leitungTxt` | Texte und Ausgaben (7) |
| `update` | zentrales Neuberechnen und Rendern |
| `submission`, `buildPdf`, `saveFile`, `b64`, `unb64`, `pdfSafe`, `slug` | Einreichung und PDF |
| `markMissing`, `focusEl`, `askConfirm`, `showConfirm`, `clearAll` | Bedienung |

### 9.3 Browseranforderungen

Genutzt werden u. a.: `Object.hasOwn`, optionale Verkettung `?.`, `??`, `TextEncoder`/`TextDecoder('latin1')`, `CSS.escape`, `navigator.clipboard`, `localStorage`, Eingabetypen `date`, `time`, `datetime-local`; CSS `:has()` (nur Optik der Auswahlkarten). [ANNAHME] Damit sind aktuelle Chromium-, Firefox- und Safari-Versionen nötig; getestet wurde nur mit Microsoft Edge (Chromium, headless). Dezimalkomma in Zahlenfeldern hängt von der Spracheinstellung des Browsers ab.

### 9.4 Bekannte Fehler und Schwächen

- Reiter im Ergebnisbereich sind für Screenreader nicht vollständig ausgezeichnet (kein `aria-controls`/`tabpanel`).
- Löschen einer Tabellenzeile (✕) ohne Rückgängig.
- Tagessatz-Vorschlag zählt An- und Abreisetage mit (4.2).
- „Wochenendtour“ = 2–3 Tage, unabhängig vom Wochentag.
- Sechs-Monats-Warnung gilt für alle Touren; die Rundmail an die Tourenleitenden nennt die Frist nur für Mehrtagestouren (offen, Abschnitt 11).
- Freiplatz-Hinweis hängt an der Unterkunftsart aus dem CO2-Abschnitt (`unterkunft = huette`).
- Nichtmitgliederbeitrag wird aus dem (ggf. selbst eingetragenen) Mitgliederbeitrag berechnet.
- Ohne erfasste Person rechnet die Vergütung mit einer Trainerperson (`nTL = 1`).
- `ylw` ist als Pflicht markiert, wird aber nicht geprüft (immer vorbelegt).
- `fehlend` im PDF enthält nicht den Schritt-6-Hinweis „Beitrag (Mindestanzahl …)“.
- Keine Migration älterer Einreichungen (7.5).
- Freigeschaltete Sätze gehen beim Neuladen verloren; ein PDF enthält die verwendeten Sätze nicht.
- CO2-Verpflegung rechnet bei Übernachtung jeden Tag mit dem Faktor „mit Übernachtung“.
- PKW-Erkennung in „Kosten der Leitung“ nur über den Text am Zeilenanfang („PKW…“), Übernachtung über das Wort „Übernachtung“, Hütte/HP in „Selbst zu zahlen“ über „hütte“ und „Halbpension“/„HP“.

---

## 10. Entscheidungen und Herkunft

„Tourenreferat“ = Festlegung durch den Tourenreferenten im Chat. „Vorstand“ = beschlossene Ordnungen. „Eigene Annahme“ = Vorschlag aus dem Chat, vom Tourenreferat nicht ausdrücklich bestätigt, sondern nur übernommen.

| Entscheidung | Begründung | Verworfene Alternativen | Wer |
|---|---|---|---|
| Kalkulation auf die Mindestanzahl | Vergütungsordnung Ziff. 9.1: Beiträge „in Abhängigkeit der voraussichtlichen Teilnehmeranzahl ausreichend bemessen“; Folienbeispiel 735 € ÷ 5 TN | Kalkulation auf erwartete oder höhere Anzahl (im Chat angesprochen) | Grundlage Vorstand/Folien; Umsetzung eigene Annahme, vom Tourenreferat akzeptiert |
| Überschuss bei voller Belegung bleibt bei der Sektion | gleicht Touren ohne Überschuss aus | Mindestanzahl höher ansetzen; Hinweis „prüfe Mindestanzahl“ (entfernt) | Tourenreferat |
| Nur Onlinezahlung | Vorgabe | wählbar Überweisung/Barzahlung (entfernt) | Tourenreferat |
| Gebühren mit der teuersten aktiven Zahlmethode | Teilnehmende wählen die Methode selbst | Durchschnitt; günstigste Methode | eigene Annahme |
| PayPal bleibt aktiv | Vorgabe; macht das Beispiel 160 € statt 155 € | PayPal in Yolawo abschalten | Tourenreferat |
| MwSt. 19 % auf Gebühren | Screenshot „zzgl. MwSt.“ | – | eigene Annahme |
| Nichtmitglieder +30 %, auf 5 € gerundet | feste Regel statt bisher +20 € bis +50 % | – | Tourenreferat |
| Standard „nur DAV-Mitglieder“; Nichtmitglieder nur als Ausnahme (z. B. Schnupperangebote) nach Rücksprache, mit Begründung | Vorgabe (22.10.2026) | frei wählbar „Nur für DAV-Mitglieder“ | Tourenreferat |
| Gemeinschaftstour ganz ohne Zahlung: kein Beitrag, keine Vergütung, keine Organisationspauschale, keine Erstattung, keine Kostentabellen | Leitende sollen keine Vergütung oder Erstattung bekommen; keine Vorgaben zur Kostenumlage | Organisationspauschale nach Vergütungsordnung Ziff. 9.2; Umlage der Auslagen auf Teilnehmende (beides zeitweise umgesetzt) | Tourenreferat; **weicht von Vergütungsordnung Ziff. 9.2 ab**, Anpassung durch Vorstand offen |
| Ohne Beitrag nur Familienwanderungen als Tagestour | Folienbeispiel „kein Beitrag bei Tagestour“ vs. Kostendeckung; Kompromiss | alle Tagestouren ohne Beitrag | Tourenreferat (auf Empfehlung) |
| Storno nach Sektionsstandard 90/50 %, fest | in Yolawo häufig genutzt | wählbare/abweichende Regel (entfernt) | Tourenreferat |
| Eintägige Kurse nach Lehreinheiten | Vergütungsordnung Anhang 1 „Kurse: Lehreinheit (1 h) 15 €“ | Tagessätze | Vorstand (Ordnung) |
| Trainersatz nur mit gültiger förderfähiger Lizenz, sonst Helfersatz | Vergütungsordnung Ziff. 11 | – | Vorstand (Ordnung); Auslegung „Lizenzjahr leer = Helfersatz“ eigene Annahme |
| Leipziger Richtwert PKW: 150 km + 100 km je weiterem Tag, ab 2027, nicht verbindlich, nach einem Jahr auswerten | angelehnt an Anreiseregelung der Sektion Köln; DAV gibt kein Tourenbudget vor | verbindliche Grenze; kein Richtwert | Tourenreferat (auf Empfehlung) |
| CO2-Faktoren UBA 2024 und Klima-Rechner Köln | DAV-Faktoren nicht öffentlich | – | eigene Annahme |
| DAV-Hütten nicht ins Tourbudget | DAV-Bilanzierungstool rechnet sie der Hütten-Sektion zu (Emissionsbericht 2022) | – | eigene Annahme auf Basis DAV-Dokument |
| Einreichung als PDF per E-Mail, Daten im PDF eingebettet | keine neuen Konten, Daten bleiben im Verein | claude.ai-Datenbank; JSON-Datei mit OneDrive-Upload | Tourenreferat |
| Formular immer vollständig einreichen, auch bei eigener Yolawo-Eingabe | Kalkulation, Notfallkontakte, CO2-Bilanz | – | Tourenreferat |
| Notfallkontakt Pflicht, nur Name und Telefon | Krisenfall; Datensparsamkeit | Feld „Beziehung“ (entfernt) | Tourenreferat |
| Keine externen Abrufe (jsPDF eingebettet, keine Google Fonts) | Datenschutz | jsPDF vom CDN mit Prüfsumme (zwischenzeitlich) | Tourenreferat („Datenschutz beachten“) |
| Sätze nicht im Entwurf/PDF speichern, Sperre in der Oberfläche | alte Entwürfe dürfen neue Sätze nicht überschreiben; Versehen vermeiden | – | eigene Annahme |
| Kondition-Grenzen, Technik-Zuordnung, Qualifikation-Sportart-Zuordnung, Hüttenpreis-Plausibilität 45–90 € | Vergleichbarkeit, Hinweise | – | eigene Annahme |
| Sechs Monate Vorlauf | Folien Tourenleitertreffen: „bestenfalls mind. 6 Monate im Voraus“ | nur Mehrtagestouren | Folien; Geltungsbereich offen |
| Upload-Datei mit vollständigem HTML-Rahmen getrennt von der Vorschau-Datei | Umlaute/Darstellung beim lokalen Öffnen | – | eigene Annahme |

---

## 11. Offen und Ideen

### 11.1 Offen (aus dem Chat)

- Vorstand: Vergütungsordnung Ziff. 9.2 an „Gemeinschaftstour ohne Zahlung“ anpassen.
- Vorstand/Datenschutz: Löschfrist für Notfallkontakte bestätigen.
- DAV-eigene CO2-Faktoren beim Bundesverband anfragen und eintragen.
- Hüttentarife 2027 (neue Obergrenzen) prüfen, sobald veröffentlicht.
- Sechs-Monats-Warnung: für alle Touren oder nur Mehrtagestouren?
- „Buchung auf Anfrage“ in Yolawo: angekündigt; im Widget-Code gibt es bereits die Teilnahmestatus „angefragt“, „abgelehnt“, „zurückgezogen“. Danach ggf. Feld „Anmeldung nur nach Freigabe durch die Tourenleitung“ ergänzen (angeboten, nicht umgesetzt).
- Upload der neuen `Tourenkonzept_DAV-Leipzig.html` auf die Website (Pimcore); alten Link auf die Muster-Tourenausschreibung ersetzen.
- Test mit zwei bis drei Tourenleitenden.
- Barrierefreiheit der Reiter, Rückgängig beim Löschen.

### 11.2 Für eine Mehrbenutzer-Version (React + TypeScript, Supabase) – Ideen, nicht umgesetzt

Alle Punkte in diesem Abschnitt sind **[ANNAHME]**: Vorschläge, die sich aus dem Chat ergeben, nicht festgelegt.

| Thema | Heute | Vorschlag |
|---|---|---|
| Einreichung | PDF per E-Mail, Daten im PDF | Datensatz mit Status; PDF nur noch als Export |
| Status einer Tour | keiner | z. B. Entwurf → eingereicht → Rückfrage → freigegeben → in Yolawo angelegt → durchgeführt → abgerechnet → archiviert |
| Rollen | keine | Tourenleitung (eigene Touren), Tourenreferat (alle Touren, Freigabe), Geschäftsstelle (Abrechnung), ggf. Vorstand (lesen). Im Herbsttreffen 2026 wurde für das Referat ein Modell mit vier Rollen besprochen: Referatsleitung (gewählt), Bergsport und Yolawo, Familien und Gruppen, Team und Ausbildung |
| RLS | – | Notfall- und Kontaktdaten nur für die eigene Tourenleitung und das Tourenreferat; öffentliche Felder getrennt von internen |
| Sätze | im HTML, Sperre nur Oberfläche | eigene Tabelle mit Gültig-ab-Datum und Versionsnummer; jede Kalkulation speichert die verwendete Satzversion; Änderung nur durch berechtigte Rolle |
| Kalkulation | im Browser | gleiche Formeln serverseitig nachrechnen (Abschnitt 4) |
| Freigabe | außerhalb (E-Mail) | Freigabe im System mit Kommentar und Verlauf |
| Yolawo | von Hand nach Eingabeblatt | [UNBEKANNT] ob Yolawo eine Schreib-Schnittstelle anbietet; im Chat wurde nur die öffentliche Lese-API des Buchungs-Widgets (`api.yolawo.de/widgets/{id}/offers`) genutzt. Bis dahin Eingabeblatt beibehalten |
| Anmeldung | in Yolawo | bleibt in Yolawo |
| Nach der Tour | separate Formulare (Reisekosten, Kostenabrechnung), freiwillige Berichte | Abrechnung, Ist-Teilnehmerzahl, Ist-Anreise für die CO2-Bilanz, Vorkommnisse, Feedback als Schritte im System |
| Löschung | Hinweis „nach Abschluss der Tour“ | automatische Löschung der Notfallkontakte nach Status „durchgeführt“ + Frist |
| Stammdaten | Felder je Tour | Profil der Tourenleitung (Kontakt, Qualifikation, Lizenzjahr, DAV-Mail-Adresse, Notfallkontakt) einmal pflegen; Übersicht der aktiven Tourenleitenden nur mit Einwilligung (beim Herbsttreffen 2026 als Aufgabe genannt) |
| Fotos | Anhang per E-Mail | Upload mit Bildrechte-Angabe |

---

## Anhang: Stellen, an denen ich unsicher bin

1. Feldbezeichnungen in der Yolawo-Verwaltung: aus Widget-Code und Hilfe abgeleitet, nicht in der Verwaltungsoberfläche geprüft.
2. MwSt.-Satz 19 % auf die Zahlungsgebühren: angenommen.
3. Gültig-ab-Daten der Vergütungsordnung 2025 und der Festlegungen des Tourenreferats.
4. Ob „Löschung der Notfallkontakte nach Abschluss der Tour“ vom Vorstand oder Datenschutz bestätigt ist.
5. Faktor Flug 290 g/Pkm: laut Recherche UBA inkl. Nicht-CO2-Effekte; die Originaltabelle wurde nicht selbst geprüft.
6. Reisebus mit dem Fernbus-Faktor (30 g/Pkm) und Selbstversorgerhütte mit dem Hütten-Faktor: Näherungen.
7. Zuordnung Qualifikation → Sportart, Konditionsgrenzen, Technik-Stufen: eigene Vorschläge, nicht mit dem Referat im Einzelnen abgestimmt.
8. Browserunterstützung: nur in Chromium (Edge) getestet.
9. Zahl „rund 50 Angebote“ und Hüttenpreise 2026: Stand der Recherche vom 11.10.2026; die Hüttenpreise ändern sich 2027.
10. Wie die Mitgliedschaft der Teilnehmenden geprüft wird (Yolawo-Frage, Geschäftsstelle).
11. Ob die Geschäftsstelle das Formular künftig nutzen soll.
12. Vollständige Schwachstellenlage von jsPDF 2.5.1.
