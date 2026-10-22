# Spaltenzuordnung Aktivenliste → Ehrenamtsmanagement

Stand: 21.10.2026 · Version 0.4 · Entwurf · Quelle: Vorlage_Aktiven_Liste.xlsx (nur Kopfzeile, 68 Spalten, keine Personendaten)
Zweck: Grundlage für Abschnitt C (Daten) in 01-erhebung.md und für das Migrationsskript. Lesestufen: **alle** = alle mit Zugriff auf das Ehrenamtsmanagement · **GST** = nur Geschäftsstelle und Admin · **vertr.** = vertraulich.
Umfang: nur das Tabellenblatt der aktiven und ruhenden Aktiven. Das Tabellenblatt der Karteileichen (Ausgeschiedene) wird nicht migriert ([OFFEN], ob später).
Änderungen v0.4: „ruhend“ bestätigt; Karteileichen-Blatt ausgenommen; Spalte „aktiv?“ eindeutig („nein“ = ruhend).
Änderungen v0.3: Spalte „aktiv?“ → Ehrenamtsstatus; Zweck von Geburtsdatum und Geschlecht geklärt; je Lizenz eine eigene Lizenznummer.

## 1. Strukturelle Folgen

1. **Eigenschaftsart mit mehreren Feldern** (bestätigt, Product Owner 21.10.2026). Eine Eigenschaftsart hat 1–n Felder (Name, Datentyp, Pflicht); Geschäftsstelle und Admin legen sie ohne Code-Änderung an. Jede Eigenschaft bleibt eine Zeile, RLS je Eigenschaftsart bleibt möglich. → **Nachtrag Administration**
2. **Mehrere gleichzeitig gültige Eigenschaften derselben Art** (bis zu 3 Lizenzen mit je eigener Lizenznummer, mehrere Schlüssel, mehrere Fortbildungen). Die festen Spalten L1–L3 entfallen.
3. **Jahresspalten werden zu Einträgen** mit Jahr (Fortbildung 2016 … 2026, Förderung, Marke, Jahreskarte). Neue Jahre brauchen keine neue Spalte.
4. **Kategorie an der Eigenschaftsart** (nur Anzeige): Stammdaten, Kontakt, Zuordnung, Qualifikationen, Nachweise, Jahreseinträge, Ausgaben, Zugänge, Sonstiges. [ANNAHME]
5. **Ehrenamtsstatus** (aktiv · ruhend · ausgeschieden) ist ein eigener, manuell gesetzter Status mit Datum und Historie, gültig für die ganze Person (Product Owner 21.10.2026). Er wird nicht aus Ämtern und Funktionen abgeleitet.
6. **Abgeleitete Werte werden nicht gespeichert:** „nächste FB“ (aus dem Ablaufdatum).
7. **Hinweis beim Ausscheiden** [ANNAHME]: noch nicht zurückgegebene Ausgaben (Schlüssel, Karte) und bestehende externe Zugänge bzw. Verteiler anzeigen.
8. **Unklare Felder werden 1:1 übernommen** und später bereinigt oder abgelöst (Product Owner 21.10.2026), z. B. „Jahr Kurs-verlängerung“.

## 2. Zuordnung je Spalte

### Stammdaten, Status und Mitgliedschaft

| Spalte | Überschrift | Ziel | Lesestufe | Hinweis |
|---|---|---|---|---|
| A | Zuname | Person: Nachname (Pflicht) | alle | – |
| B | Vorname | Person: Vorname (Pflicht) | alle | – |
| C | Rufname | Person: Rufname (optional) | alle | Anzeige bevorzugt Rufname [ANNAHME]; Feld fehlt in der Administration (Nachtrag) |
| D | Mitgliedsnummer | Eigenschaft Mitglied (ja/nein, Mitgliedsnummer) | alle | Mitglied = ja, wenn Nummer vorhanden [ANNAHME] |
| E | aktiv? | Ehrenamtsstatus: „ja“ → aktiv, „nein“ → ruhend; gültig ab = Stichtag der Migration | alle | Ausgeschiedene stehen auf einem eigenen Blatt und sind nicht betroffen; andere Werte im Prüfbericht |
| AE | Geburtsdatum | Eigenschaft Geburtsdatum | GST [ANNAHME] | Zweck: Lizenzanträge; später Geburtstagserinnerung |
| neu | Geschlecht | Eigenschaft Geschlecht (Auswahl: weiblich, männlich, divers, keine Angabe) | GST [ANNAHME] | Zweck: Lizenzanträge, korrekte Ansprache; nicht in der Liste, wird nachgepflegt |

### Kontakt und Bankverbindung

| Spalte | Überschrift | Ziel | Lesestufe | Hinweis |
|---|---|---|---|---|
| Z | Mail-Adresse | Kontaktdaten: E-Mail (Kontaktadresse) | alle | – |
| AA | Telefon FN | Kontaktdaten: Telefon Festnetz | alle | – |
| AB | Telefon mobil | Kontaktdaten: Telefon mobil | alle | – |
| AC | Adresse | Kontaktdaten: Straße, PLZ, Ort | alle [ANNAHME] | Skript teilt den Freitext auf; nicht zerlegbare Adressen im Prüfbericht |
| AQ | DAV-Email | Kontaktdaten: DAV-E-Mail-Adresse | alle | [ANNAHME] @dav-leipzig.de; Vorschlag als Login-Adresse beim Einladen, kein automatischer Zugang |
| AD | IBAN | Bankverbindung (Kontoinhaber:in, IBAN) | GST | Grundlage Trainerabrechnung (Modul Finanzen); automatische IBAN-Prüfung wie im Modul Gruppen |

### Zuordnung zu Referat, Gruppe, Gremium

| Spalte | Überschrift | Ziel | Lesestufe | Hinweis |
|---|---|---|---|---|
| I | Referat | Funktion mit Bezug auf Referat | alle | Werte gegen die 7 Referate prüfen; Funktion Trainer:in bei gültiger Lizenz, sonst Helfer:in [ANNAHME] |
| H | Gruppe | nicht in der EA-Migration | – | Modul Gruppen ist führend; Werte im Prüfbericht für den Gruppen-Import [ANNAHME] |
| AR | Gruppenleitung | nicht in der EA-Migration | – | wie Spalte H |
| AS | Jugendausschuss | Amt „Mitglied – Jugendausschuss“ (Gremium) | alle (Gremium-Sicht nur GST) | [OFFEN] Amtszeit fehlt in der Liste |
| BO | Aktiv seit | gültig von der Funktion und erster Eintrag im Ehrenamtsstatus „aktiv“ [ANNAHME] | alle | – |
| J | TE pro Woche | Feld „Trainingseinheiten pro Woche“ an der Funktion Trainer:in [ANNAHME] | alle | später durch Modul Einsätze ersetzt |

### Qualifikationen

| Spalte | Überschrift | Ziel | Lesestufe | Hinweis |
|---|---|---|---|---|
| M | Ausbildung | Qualifikation: Qualifikationsart | alle | Freitext → Zuordnung zu Stammdaten im Probelauf |
| F | DOSB-Lizenz-Nr. / LFV-Lizenznummer | Feld Lizenznummer an der Lizenz | alle | Jede Lizenz hat eine eigene Nummer. Die Liste hat nur eine Spalte: Nummer wird der Lizenz L1 zugeordnet [ANNAHME]; Nummern für L2/L3 nachpflegen, Prüfbericht listet Personen mit mehreren Lizenzen |
| N | L. Stufe laut Vereinsportal (absolvierte LE) | Feld an der Lizenz: Stufe laut Vereinsportal, Lerneinheiten | alle | [OFFEN] Bedeutung „LE“ (Lerneinheiten?) |
| O, R, U | L1–L3 gültig bis | je Lizenz eine Qualifikation mit Ablaufdatum | alle | – |
| P, S, V | L1–L3 Letzte FB | Feld „letzte Fortbildung“ (Datum) an der Lizenz | alle | – |
| Q, T, W | L1–L3 nächste FB | nicht übernehmen (berechnet) | – | – |
| AF | Jahr Kurs-verlängerung | Feld „Jahr Kursverlängerung“ (Jahr) an der Lizenz | alle | 1:1 übernommen; [OFFEN] Unterschied zu „Letzte FB“, später bereinigen |
| AT | Aufbaumodule | Qualifikation, Qualifikationsart „Aufbaumodul …“ mit Datum | alle | Freitext mit mehreren Modulen wird aufgeteilt; [OFFEN] Definition |
| AU–BF | Fortbildung <2016 … Fortbildungen 2026 (12 Spalten) | je Fortbildung ein Eintrag: Titel, Datum bzw. Jahr, Bezug auf Lizenz [ANNAHME] | alle | Inhalt der Zellen unbekannt (Freitext?) |
| BJ | 1. Hilfe Kurs | Weiterbildung Erste Hilfe: Datum, Ablaufdatum | alle | – |
| BK | Rettungsschwimmer | Weiterbildung Rettungsschwimmer: Stufe [ANNAHME], Datum, Ablaufdatum | alle | – |

### Ausweis, Nachweise und unterschriebene Dokumente

| Spalte | Überschrift | Ziel | Lesestufe | Hinweis |
|---|---|---|---|---|
| G | Ausweis Nr. | Trainer- und Jugendleiterausweis: Feld Ausweisnummer | alle [ANNAHME] | kein Personalausweis (Product Owner 21.10.2026) |
| Y | Kopie Ausweis in der GST/Online | Trainer- und Jugendleiterausweis: Feld „Kopie liegt vor“ (ja/nein) | alle [ANNAHME] | Kopie wird für Lizenzanträge bei Landessportbund bzw. Stadtsportbund gebraucht; die Kopie selbst liegt nicht im Vereins OS |
| BI | Führungszeugnis Ausstellungsdatum | Nachweis Führungszeugnis-Einsicht: Ausstellungsdatum, eingesehen am | GST | „eingesehen am“ fehlt in der Liste |
| AH | Ehrenkodex | Nachweis Ehrenkodex unterschrieben (Datum) | alle [ANNAHME] | – |
| AI | ÜL-Vertrag | Nachweis Trainervereinbarung unterschrieben (Datum) | GST [ANNAHME] | Begriff „Trainervereinbarung“ [ANNAHME], weil „Vertrag“ im Glossar der Vertrag im Kinder- und Jugendbereich ist |

### Jahreseinträge (je Jahr ein Eintrag)

| Spalte | Überschrift | Ziel | Lesestufe | Hinweis |
|---|---|---|---|---|
| X | JL/Trainermarke 2026 | Jugendleiter- und Trainermarke: Jahr, ausgegeben am | alle | Filter „Marke für Jahr X noch nicht ausgegeben“ [ANNAHME] |
| K, L | Förderung 2025 / 2026 | Förderung: Jahr, für Person beantragt (ja/nein) | GST [ANNAHME] | [OFFEN] Fördergeber und Förderart |
| BG, BH | Jahreskarte 2025 / 2026 | Ausgabe Jahreskarte: Jahr, ausgegeben am | alle | [OFFEN] Jahreskarte wofür? |
| BN | Ehrenamtspass 2026 | Ehrenamtspass: ausgegeben am, gültig bis | alle | – |

### Ausgaben

| Spalte | Überschrift | Ziel | Lesestufe | Hinweis |
|---|---|---|---|---|
| AJ | Schlüssel NoLimit | Ausgabe: Gegenstand, Nummer [ANNAHME], ausgegeben am, zurückgegeben am | alle [ANNAHME] | – |
| AK | Schlüssel K4 | wie AJ | alle | – |
| AL | K4-Karte | wie AJ | alle | – |
| BM | Vereins Jacke | Ausgabe Vereinsjacke: ausgegeben am | alle | – |

### Externe Zugänge und Verteiler (nur Vermerk, keine Steuerung der Systeme)

| Spalte | Überschrift | Ziel | Lesestufe | Hinweis |
|---|---|---|---|---|
| AM | DAV360 | Zugang extern: System, seit, bis | alle | – |
| AN | Forms | wie AM | alle | [OFFEN] welches Forms (Microsoft Forms?) |
| AO | JDAV Aktiven Mailverteiler | Zugang extern (Verteiler): Name, seit, bis | alle | – |
| AP | Redaktion | wie AM | alle | [OFFEN] Redaktion wofür? |
| BL | Mailingliste | wie AO | alle | [OFFEN] Unterschied zu AO |

### Sonstiges

| Spalte | Überschrift | Ziel | Lesestufe | Hinweis |
|---|---|---|---|---|
| BP | let. Auszeich. | Auszeichnung: Art, Datum | alle | – |
| AG | Anmerkung | nicht übernehmen | – | Entscheidung Product Owner 21.10.2026 |

## 3. Datenschutz

- **Ausweis:** Trainer- und Jugendleiterausweis, kein Personalausweis; nur Nummer und Vermerk „Kopie liegt vor“.
- **IBAN:** nur Lesestufe GST; Referent:innen sehen sie nicht.
- **Geburtsdatum, Geschlecht:** Zweck dokumentiert (Lizenzanträge, korrekte Ansprache, später Geburtstagserinnerung); Lesestufe GST [ANNAHME]. Eine Geburtstagserinnerung für Referent:innen würde das Geburtsdatum (oder nur Tag und Monat) für sie sichtbar machen → bei Umsetzung neu entscheiden.
- **Anmerkung:** wird nicht migriert.
- **Karteileichen:** werden nicht migriert; bleiben bis zur Entscheidung in der Excel-Liste.

## 4. Abhängigkeiten

- **Administration:** Eigenschaftsart mit mehreren Feldern, Kategorie, Rufname (Nachtrag); Sichtbarkeit im Ehrenamtsmanagement über Ehrenamtsstatus statt „nur Aktive“.
- **Gruppen:** Spalten H und AR gehen an den Gruppen-Import; die Funktion mit Bezug auf die Gruppe legt das Modul Gruppen an.
- **Finanzen:** Bankverbindung, Trainervereinbarung.
- **Einsätze:** „TE pro Woche“ wird später durch erfasste Einsätze ersetzt.

## 5. Offene Fragen

- [OFFEN] Karteileichen: später migrieren (nur Ausscheiden < 5 Jahre, Status „ausgeschieden“) oder mit der Excel-Liste löschen?
- [OFFEN] Bedeutung „LE“ in Spalte N; Definition Aufbaumodul; Unterschied „Jahr Kurs-verlängerung“ zu „Letzte FB“.
- [OFFEN] Förderung: Fördergeber und Förderart.
- [OFFEN] Jahreskarte wofür; Forms, Redaktion, Mailingliste: welche Systeme?
- [OFFEN] Amtszeit Jugendausschuss (fehlt in der Liste).
