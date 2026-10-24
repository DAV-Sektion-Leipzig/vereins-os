# Stories: Anwesenheitserfassung

Stand: 24.10.2026 · Version 0.4 · Kürzel: EZ · Status: Entwurf
Quellen: 00-steckbrief.md (v0.8), 01-erhebung.md (v0.4, Regeln R1–R12), rollen.md (v1.0), glossar.md (v1.6), Übergaben an AD (v1.3, eingearbeitet in spec.md AD v0.8), GR (v1.3, eingearbeitet in Gruppen 02-stories.md v0.4; Nachtrag `gr_my_groups` in v0.6), EA (v1.2), FI (v1.6); Übergabe aus der Planungshilfe Touren und Kurse (v1.2, `tk-touren-kurse/uebergabe-anwesenheitserfassung.md`)
Umfang: Training, Fahrten (Tagesausflug, Mehrtagesfahrt, Ausbildungsfahrt), Wettkampfbetreuung, Trainingslager, Arbeitseinsatz, Kurs, Tour, Absage, Übernahme aus der Planungshilfe Touren und Kurse, Listen.
Änderungen v0.4: Abgleich mit dem Forms-Formular (Product Owner 24.10.2026): Training ohne Uhrzeit (R28, US-EZ-01); Beginn und Ende mehrtägiger Einsätze optional (US-EZ-06, -21); mindestens eine Teilnehmer:in auch bei Fahrten und Wettkampfbetreuung (AK in US-EZ-05, -08); Einsatzart heißt Wettkampfbetreuung. Übergabe der Planungshilfe Touren und Kurse v1.2 eingearbeitet (Product Owner, 24.10.2026): neue Stories US-EZ-20 (Kurs oder Tour von Hand erfassen), US-EZ-21 (Trainingslager erfassen), US-EZ-22 (Einsatz absagen und Absage zurücknehmen), US-EZ-23 (Kurs oder Tour aus der Planungshilfe übernehmen); neue Regeln R22–R27; Titel bis 90 Zeichen (US-EZ-05 AK4); Stände „eingetragen“ auch bei Kurs und Tour.
Änderungen v0.3: Neue Story US-EZ-19 und Regel R18: Wer selbst Gruppenleitung, Trainer:in oder Helfer:in ist, bekommt beim Erfassen seine eigene Gruppe vorgeschlagen (Vorbelegung); der Vorschlag gibt keine zusätzlichen Rechte (Product Owner, 22.10.2026). Bestätigt: Gruppe nach dem Speichern nicht änderbar; Stichtag bei mehrtägigen Einsätzen = Startdatum; Orte pflegt nur der Admin.
Änderungen v0.2: Annahmen bestätigt (Product Owner, 22.10.2026): Löschen nur durch die Geschäftsstelle (R15), Stichtag für Teilnehmer:innen und Trainer:innen (R16), Einsatzart nicht änderbar, Standardrolle Helfer:in beim Arbeitseinsatz, keine organisierende Person bei der Wettkampfbegleitung, Feldlängen Titel 60, Probetraining 30, Bemerkung 500 Zeichen. Verweise auf die Lesefunktion `gr_group_roster` (Gruppen) und die Startliste der Orte ergänzt.
Änderungen v0.1: Erster Entwurf.

## Zusätzliche Regeln (Ergänzung zu 01-erhebung.md, Abschnitt D)

- **R13:** Referent:innen sehen und bearbeiten nur Einsätze ihrer Referate; bei Einsätzen mit Gruppe gilt das Referat der Gruppe. Andere Einsätze erscheinen weder in Listen noch per direktem Aufruf.
- **R14:** Admin und Vorstand haben nur Leserechte; Schaltflächen zum Anlegen, Ändern und Löschen werden nicht angezeigt, Schreibversuche lehnt die Datenbank ab.
- **R15:** Löschen eines Einsatzes nur mit „EZ verwalten“ (Geschäftsstelle), mit Rückfrage (bestätigt 22.10.2026); Anwesenheiten und Probetrainings werden mit gelöscht.
- **R16:** In der Anwesenheitsliste erscheinen Teilnehmer:innen mit gültiger Teilnahme am Datum des Einsatzes sowie Trainer:innen, Helfer:innen und Gruppenleitung der Gruppe mit gültiger Funktion an diesem Datum (Stichtag, bestätigt 22.10.2026). Quelle: `gr_group_roster(group_id, date)` (Gruppen, US-GR-19). Bei mehrtägigen Einsätzen gilt das Startdatum (bestätigt 22.10.2026).
- **R17:** Eine Person kann je Einsatz nur einmal in der Anwesenheit stehen.
- **R18:** Ist die erfassende Person am Datum des Einsatzes Gruppenleitung, Trainer:in oder Helfer:in einer Gruppe, wird diese Gruppe beim Erfassen vorgeschlagen (Vorbelegung, änderbar). Der Vorschlag ist eine Eingabehilfe gegen Fehleingaben, kein Recht: Wählbar sind nur Gruppen, für die die Rechtevorlage der Person das Erfassen erlaubt (R13; ab Iteration 1 Reichweite „Gruppe“). Quelle: `gr_my_groups(date)` (Gruppen, US-GR-20).
- **R28:** Ein Training wird ohne Uhrzeit erfasst; die Zeit ergibt sich aus der Trainingszeit der Gruppe (Product Owner 24.10.2026).
- **R22:** Jeder Einsatz kann abgesagt werden (alle Einsatzarten, Product Owner 24.10.2026). Ein abgesagter Einsatz bleibt in Liste und Detail sichtbar (mit Grund), ist nicht änderbar und zählt nicht für Abrechnung, Kontrollliste Kletterhalle und Warnung bei doppelter Erfassung.
- **R23:** Absagen darf, wer den Einsatz ändern darf (R13), nur mit Grund und nur, solange niemand „anwesend“ ist (Product Owner 24.10.2026).
- **R24:** Eine Absage kann von Nutzern mit Schreibrecht zurückgenommen werden; danach ist der Einsatz wieder änderbar (Product Owner 24.10.2026).
- **R25:** Einsätze, die die Planungshilfe Touren und Kurse erzeugt hat: Kopf (Titel, Zeiten, organisierende Person), Personen aus der Planung, Absage und Löschen nur über die Planungshilfe; in der Anwesenheitserfassung nur die Anwesenheit (Stand setzen, Personen ergänzen) (Product Owner 24.10.2026).
- **R26:** Die Planungshilfe legt den Einsatz Kurs bzw. Tour an, sobald die Planung den Status „in Yolawo angelegt“ hat, und aktualisiert ihn nur, solange niemand „anwesend“ ist (Übergabe TK v1.2).
- **R27:** Sagt die Planungshilfe die Planung ab, wird der Einsatz als „abgesagt“ markiert, nicht gelöscht (Übergabe TK v1.2).

## Übersicht

| ID | Titel | Priorität | Rechtevorlage |
|---|---|---|---|
| US-EZ-01 | Training erfassen | Must | Geschäftsstelle, Referent:in |
| US-EZ-02 | Anwesenheit im Training ankreuzen | Must | Geschäftsstelle, Referent:in |
| US-EZ-03 | Vertretung hinzufügen | Must | Geschäftsstelle, Referent:in |
| US-EZ-04 | Probetraining und Bemerkung erfassen | Should | Geschäftsstelle, Referent:in |
| US-EZ-05 | Eintägige Fahrt erfassen | Must | Geschäftsstelle, Referent:in |
| US-EZ-06 | Mehrtägige Fahrt erfassen | Must | Geschäftsstelle, Referent:in |
| US-EZ-07 | Organisierende Person suchen | Must | Geschäftsstelle, Referent:in |
| US-EZ-08 | Wettkampfbetreuung erfassen | Must | Geschäftsstelle, Referent:in |
| US-EZ-09 | Arbeitseinsatz anlegen und Personen eintragen | Must | Geschäftsstelle, Referent:in |
| US-EZ-10 | Anwesenheit beim Arbeitseinsatz bestätigen | Must | Geschäftsstelle, Referent:in |
| US-EZ-11 | Neue Person beim Arbeitseinsatz anlegen | Must | Geschäftsstelle, Referent:in |
| US-EZ-12 | Einsatz korrigieren | Must | Geschäftsstelle, Referent:in |
| US-EZ-13 | Einsatz löschen | Should | Geschäftsstelle |
| US-EZ-14 | Einsätze auflisten und filtern | Must | alle mit EZ-Rechten |
| US-EZ-15 | Einsatz ansehen (nur lesen) | Must | Admin, Vorstand |
| US-EZ-16 | Kontrollliste Punktekonto Kletterhalle | Should | Geschäftsstelle, Referent:in |
| US-EZ-17 | Warnung bei doppelter Erfassung | Should | Geschäftsstelle, Referent:in |
| US-EZ-18 | Eingabe bei fehlgeschlagenem Speichern behalten | Must | Geschäftsstelle, Referent:in |
| US-EZ-19 | Eigene Gruppe beim Erfassen vorschlagen | Must | Referent:in (MVP), Gruppenleitung und Trainer:innen (Iteration 1) |
| US-EZ-20 | Kurs oder Tour von Hand erfassen | Must | Geschäftsstelle, Referent:in |
| US-EZ-21 | Trainingslager erfassen | Must | Geschäftsstelle, Referent:in |
| US-EZ-22 | Einsatz absagen und Absage zurücknehmen | Must | Geschäftsstelle, Referent:in |
| US-EZ-23 | Kurs oder Tour aus der Planungshilfe übernehmen | Must | Planungshilfe Touren und Kurse (System); Geschäftsstelle, Referent:in (Anwesenheit) |

---

### US-EZ-01: Training erfassen

**Als** Mitarbeiter:in der Geschäftsstelle oder Referent:in
**möchte ich** für eine Gruppe ein Training mit Datum, Zeiten und Ort anlegen,
**damit** das Training als Einsatz gespeichert ist und abgerechnet werden kann.
**Priorität:** Must · **Regeln:** R1, R9, R10, R12, R13, R28 · **Abhängig von:** Gruppen US-GR-18 (Trainingszeiten), US-GR-19 (`gr_group_roster`); Administration spec.md v0.8 (Rechte EZ, Orte `ad_locations`)

**Akzeptanzkriterien**
- AK1: Gegeben die Gruppe „Gruppe 1“ hat die Trainingszeit dienstags 17:00–19:00, wenn ich „Training“ und „Gruppe 1“ wähle und das Datum Dienstag, 13.10.2026 eingebe, dann wird „Trainingszeit: Di 17:00–19:00“ angezeigt; eine Uhrzeit wird nicht abgefragt (R28).
- AK2: Gegeben ich habe Gruppe, Datum und einen aktiven Ort gewählt, wenn ich speichere, dann entsteht ein Einsatz „Training“ mit Referat der Gruppe, „erfasst von“ = ich und „erfasst am“ = jetzt.
- AK3: Gegeben die Gruppe hat für den gewählten Wochentag keine Trainingszeit, wenn ich das Datum eingebe, dann erscheint der Hinweis „Für diesen Wochentag ist keine Trainingszeit hinterlegt.“; speichern ist trotzdem möglich [ANNAHME].
- AK4 (Fehler): Gegeben der Ort ist nicht gewählt, wenn ich speichere, dann wird nicht gespeichert und es erscheint „Bitte Ort wählen.“
- AK5 (Rechte): Gegeben ich habe die Vorlage Referent:in mit Referat Klettern, wenn ich eine Gruppe wählen will, dann werden nur Gruppen des Referats Klettern angeboten.
- AK6: In der Ortsauswahl erscheinen nur aktive Orte.

**Nicht Teil dieser Story:** Anwesenheit ankreuzen (US-EZ-02); automatisches Anlegen von Trainings aus der Trainingszeit; Erfassung durch Gruppenleitungen und Trainer:innen (Iteration 1).

---

### US-EZ-02: Anwesenheit im Training ankreuzen

**Als** Mitarbeiter:in der Geschäftsstelle oder Referent:in
**möchte ich** die Personen der Gruppe als vorbelegte Liste sehen und die Anwesenden ankreuzen,
**damit** die Anwesenheit schnell und vollständig erfasst ist.
**Priorität:** Must · **Regeln:** R5, R16, R17 · **Abhängig von:** US-EZ-01, Gruppen US-GR-19 (`gr_group_roster`)

**Akzeptanzkriterien**
- AK1: Gegeben ich erfasse ein Training für „Gruppe 1“ am 13.10.2026, dann zeigt die Liste zwei Bereiche: Teilnehmer:innen mit gültiger Teilnahme an diesem Tag und Trainer:innen/Helfer:innen/Gruppenleitung der Gruppe mit gültiger Funktion an diesem Tag, jeweils mit Vorname (bzw. Rufname) und Nachname, alphabetisch nach Nachname.
- AK2: Gegeben ich kreuze eine Person an, dann wird sie mit Stand „anwesend“ und der vorbelegten Rolle gespeichert (Teilnehmer:in; Trainer:in bzw. Helfer:in aus der Funktion in der Gruppe).
- AK3: Gegeben eine angekreuzte Trainerin hat im Einsatz als Helferin gearbeitet, wenn ich ihre Rolle auf „Helfer:in“ ändere und speichere, dann wird die Rolle „Helfer:in“ für diesen Einsatz gespeichert; die Funktion in der Gruppe bleibt unverändert.
- AK4 (Fehler): Gegeben keine Person mit Rolle Trainer:in oder Helfer:in oder keine Teilnehmer:in ist angekreuzt, wenn ich speichere, dann erscheint „Bitte mindestens eine Trainer:in oder Helfer:in und eine Teilnehmer:in auswählen.“ und es wird nicht gespeichert.
- AK5 (Rechte/Datenschutz): Gegeben ich habe die Vorlage Referent:in, dann sehe ich zu Teilnehmer:innen nur den Namen – kein Geburtsdatum, keine Kontaktdaten, keine Gesundheitsangaben.
- AK6 (Stichtag): Gegeben ein Kind ist seit 01.10.2026 nicht mehr in der Gruppe und ein Trainer erst ab 15.10.2026 eingetragen, wenn ich ein Training vom 13.10.2026 erfasse oder nachtrage, dann steht der Trainer nicht in der Liste und das Kind nur, wenn seine Teilnahme am 13.10.2026 gültig war (R16).

**Nicht Teil dieser Story:** Vertretung (US-EZ-03); Probetraining und Bemerkung (US-EZ-04); Hinweis zum Betreuungsschlüssel.

---

### US-EZ-03: Vertretung hinzufügen

**Als** Mitarbeiter:in der Geschäftsstelle oder Referent:in
**möchte ich** eine Trainer:in oder Helfer:in, die nicht zur Gruppe gehört, zur Anwesenheit hinzufügen,
**damit** auch Vertretungen erfasst und abgerechnet werden.
**Priorität:** Must · **Regeln:** R11 (Suche), R17 · **Abhängig von:** US-EZ-02, Administration spec.md v0.8 (`ea_search_active_persons`)

**Akzeptanzkriterien**
- AK1: Gegeben ich klicke „Person hinzufügen“, wenn ich mindestens 2 Zeichen eines Namens eingebe, dann zeigt die Suche Aktive (Ehrenamtsstatus „aktiv“) mit Vorname, Rufname und Nachname.
- AK2: Gegeben ich wähle eine gefundene Person und die Rolle „Trainer:in“, wenn ich speichere, dann steht sie mit Stand „anwesend“, Rolle „Trainer:in“ und Kennzeichen „Vertretung“ in der Anwesenheit.
- AK3 (Fehler): Gegeben die Person steht bereits in der Anwesenheit, wenn ich sie erneut hinzufüge, dann erscheint „Diese Person ist bereits eingetragen.“
- AK4 (Rechte): Gegeben ich habe die Vorlage Referent:in, dann zeigt die Suche nur Namen und keine weiteren Angaben zur Person.

**Nicht Teil dieser Story:** Anlegen neuer Personen (nur beim Arbeitseinsatz, US-EZ-11); Hinzufügen von Teilnehmer:innen anderer Gruppen.

---

### US-EZ-04: Probetraining und Bemerkung erfassen

**Als** Mitarbeiter:in der Geschäftsstelle oder Referent:in
**möchte ich** Kinder im Probetraining mit Vornamen und eine Bemerkung zum Einsatz erfassen,
**damit** auch Probetrainings und Besonderheiten dokumentiert sind.
**Priorität:** Should · **Regeln:** R6, R7 · **Abhängig von:** US-EZ-01

**Akzeptanzkriterien**
- AK1: Gegeben ich erfasse ein Training, wenn ich „Probetraining hinzufügen“ wähle und „Lena“ eingebe, dann wird ein Probetraining mit Vorname „Lena“ am Einsatz gespeichert; es entsteht keine Person.
- AK2: Am Feld Probetraining steht der Hinweis „Nur Vorname eintragen.“; die Eingabe ist auf 30 Zeichen begrenzt.
- AK3: Am Feld Bemerkung steht der Hinweis „Keine Angaben zu Gesundheit oder anderen sensiblen Daten von Kindern.“; die Bemerkung ist optional und auf 500 Zeichen begrenzt.
- AK4 (Fehler): Gegeben das Feld Probetraining ist leer, wenn ich „hinzufügen“ bestätige, dann erscheint „Bitte einen Vornamen eingeben.“
- AK5 (Rechte): Gegeben ich habe nur Leserechte (Admin, Vorstand), dann sehe ich Probetrainings und Bemerkung, kann sie aber nicht ändern.

**Nicht Teil dieser Story:** Übernahme eines Probetrainings als Teilnehmer:in (Modul Gruppen).

---

### US-EZ-05: Eintägige Fahrt erfassen

**Als** Mitarbeiter:in der Geschäftsstelle oder Referent:in
**möchte ich** einen Tagesausflug oder eine eintägige Ausbildungsfahrt einer Gruppe mit Dauer-Kategorie erfassen,
**damit** Finanzen den Tages- bzw. Halbtagessatz abrechnen kann.
**Priorität:** Must · **Regeln:** R1, R3, R5, R9, R10, R13 · **Abhängig von:** US-EZ-02 (Anwesenheitsliste), US-EZ-07 (organisierende Person)

**Akzeptanzkriterien**
- AK1: Gegeben ich wähle „Tagesausflug“ und „Gruppe 1“, dann muss ich Titel, organisierende Person, Datum und Dauer („unter 8 Stunden“ / „mindestens 8 Stunden“) angeben; Uhrzeiten werden nicht abgefragt.
- AK2: Gegeben ich wähle „Ausbildungsfahrt“ und „eintägig“, dann gelten dieselben Felder wie beim Tagesausflug.
- AK3: Gegeben alle Pflichtfelder und die Anwesenheit sind ausgefüllt, wenn ich speichere, dann entsteht ein Einsatz mit Einsatzart, Gruppe, Referat der Gruppe, Titel, organisierender Person, Datum und Dauer-Kategorie.
- AK4 (Fehler): Gegeben der Titel fehlt oder ist länger als 90 Zeichen (Product Owner 24.10.2026), wenn ich speichere, dann erscheint „Bitte einen Titel mit höchstens 90 Zeichen eingeben.“
- AK5 (Rechte): Gegeben ich habe die Vorlage Referent:in mit Referat Kinder und Jugend, dann kann ich Fahrten nur für Gruppen dieses Referats anlegen.
- AK6 (Fehler): Gegeben keine Teilnehmer:in oder keine Trainer:in bzw. Helfer:in ist angekreuzt, wenn ich speichere, dann erscheint „Bitte mindestens eine Trainer:in oder Helfer:in und eine Teilnehmer:in auswählen.“ (R5, Product Owner 24.10.2026).

**Nicht Teil dieser Story:** Anmeldung und Planung der Fahrt (Modul Touren und Kurse); Erwachsenenfahrten; Berechnung der Vergütung (Finanzen).

---

### US-EZ-06: Mehrtägige Fahrt erfassen

**Als** Mitarbeiter:in der Geschäftsstelle oder Referent:in
**möchte ich** eine Mehrtagesfahrt oder mehrtägige Ausbildungsfahrt mit Start und Ende erfassen,
**damit** Finanzen die Tage einschließlich An- und Abreise abrechnen kann.
**Priorität:** Must · **Regeln:** R1, R2, R4, R5, R9, R13 · **Abhängig von:** US-EZ-02, US-EZ-07

**Akzeptanzkriterien**
- AK1: Gegeben ich wähle „Mehrtagesfahrt“, dann muss ich Titel, organisierende Person, Startdatum und Enddatum angeben; Beginn und Ende sind optional (Product Owner 24.10.2026).
- AK2: Am Feld Beginn steht der Hinweis „Abfahrt am Startort“, am Feld Ende „Rückkehr am Startort“.
- AK3: Gegeben Startdatum 07.11.2026 16:00 und Enddatum 09.11.2026 18:30, wenn ich speichere, dann wird der Einsatz mit beiden Zeitpunkten gespeichert und in Listen als „07.–09.11.2026“ angezeigt.
- AK4 (Fehler): Gegeben das Enddatum liegt nicht nach dem Startdatum, wenn ich speichere, dann erscheint „Das Enddatum muss nach dem Startdatum liegen. Für eintägige Einsätze bitte ‚eintägig‘ wählen.“
- AK5 (Rechte): Gegeben ich habe nur Leserechte, dann sehe ich die Fahrt, aber keine Schaltfläche „Bearbeiten“.

**Nicht Teil dieser Story:** Uhrzeiten je Zwischentag; Berechnung von Tages- und Halbtagessätzen (Finanzen).

---

### US-EZ-07: Organisierende Person suchen

**Als** Mitarbeiter:in der Geschäftsstelle oder Referent:in
**möchte ich** die organisierende Person einer Fahrt per Suche auswählen, mit den Personen der Gruppe zuerst,
**damit** die Organisationspauschale der richtigen Person zugeordnet wird.
**Priorität:** Must · **Regeln:** R11 · **Abhängig von:** Administration spec.md v0.8 (`ea_search_active_persons`, Komponente „Personensuche Aktive“), Übergabe EA (E6)

**Akzeptanzkriterien**
- AK1: Gegeben ich habe „Gruppe 1“ gewählt, wenn ich das Feld „Organisierende Person“ öffne, dann stehen Gruppenleitung, Trainer:innen und Helfer:innen von Gruppe 1 oben.
- AK2: Gegeben ich tippe mindestens 2 Zeichen, dann durchsucht das Feld alle Personen mit Ehrenamtsstatus „aktiv“ nach Vor-, Ruf- und Nachname.
- AK3: Gegeben eine Person ist „ruhend“ oder „ausgeschieden“, dann erscheint sie nicht in der Suche.
- AK4 (Fehler): Gegeben die Suche findet niemanden, dann erscheint „Keine aktive Person gefunden.“
- AK5 (Rechte/Datenschutz): Gegeben ich habe die Vorlage Referent:in, dann zeigt die Suche auch Aktive anderer Referate, aber nur mit Namen.

**Nicht Teil dieser Story:** Anlegen neuer Personen; organisierende Person bei Training, Wettkampfbetreuung und Arbeitseinsatz.

---

### US-EZ-08: Wettkampfbetreuung erfassen

**Als** Mitarbeiter:in der Geschäftsstelle oder Referent:in
**möchte ich** eine ein- oder mehrtägige Wettkampfbetreuung einer Gruppe erfassen,
**damit** die Begleitung nach dem Satz der Vergütungsordnung abgerechnet werden kann.
**Priorität:** Must · **Regeln:** R1, R2, R3, R4, R5, R13 · **Abhängig von:** US-EZ-02, US-EZ-05, US-EZ-06

**Akzeptanzkriterien**
- AK1: Gegeben ich wähle „Wettkampfbetreuung“, dann muss ich „eintägig“ oder „mehrtägig“ wählen; die weiteren Felder entsprechen US-EZ-05 bzw. US-EZ-06, ohne organisierende Person (bestätigt 22.10.2026).
- AK2: Gegeben eintägig mit Gruppe, Titel „Jugendcup Dresden“, Datum und Dauer-Kategorie, wenn ich speichere, dann entsteht ein Einsatz „Wettkampfbetreuung“.
- AK3: In der Anwesenheit sind Trainer:innen, Helfer:innen und Teilnehmer:innen der Gruppe vorbelegt (wie US-EZ-02); betreute Teilnehmer:innen werden angekreuzt; mindestens eine Teilnehmer:in und eine Trainer:in oder Helfer:in sind Pflicht (R5, Product Owner 24.10.2026).
- AK4 (Fehler): Gegeben „mehrtägig“ und Enddatum vor Startdatum, wenn ich speichere, dann erscheint die Fehlermeldung aus R2.
- AK5 (Rechte): Gegeben ich habe die Vorlage Referent:in mit Referat Leistungssport, dann kann ich Wettkampfbetreuungen nur für Gruppen dieses Referats anlegen.

**Nicht Teil dieser Story:** Wettkampfbetreuung ohne Gruppe [ANNAHME: nicht im MVP]; Arbeitseinsätze bei eigenen Wettkämpfen der Sektion (US-EZ-09).

---

### US-EZ-09: Arbeitseinsatz anlegen und Personen eintragen

**Als** Mitarbeiter:in der Geschäftsstelle oder Referent:in
**möchte ich** einen Arbeitseinsatz meines Referats anlegen und vorab gemeldete Personen eintragen,
**damit** ich vor Ort nur noch die Anwesenheit bestätigen muss.
**Priorität:** Must · **Regeln:** R1, R3, R13, R17 · **Abhängig von:** Administration spec.md v0.8 (Reichweite Referat, `ea_search_active_persons`)

**Akzeptanzkriterien**
- AK1: Gegeben ich wähle „Arbeitseinsatz“, dann muss ich Referat, Titel und Zeiten angeben (eintägig: Datum und Dauer-Kategorie; mehrtägig: Start und Ende); eine Gruppe wird nicht abgefragt.
- AK2: Gegeben ich habe die Vorlage Referent:in mit den Referaten Klettern und Ausbildung, dann kann ich als Referat nur Klettern oder Ausbildung wählen.
- AK3: Gegeben ich suche und wähle eine aktive Person, dann wird sie mit Stand „eingetragen“ und Rolle „Helfer:in“ (Standardrolle beim Arbeitseinsatz, bestätigt 22.10.2026; je Person änderbar) gespeichert.
- AK4: Gegeben ich lege den Einsatz „Europacup Aufbau“ mit 12 eingetragenen Personen an, dann zeigt die Detailansicht „12 eingetragen, 0 anwesend“.
- AK5 (Fehler): Gegeben der Titel fehlt, wenn ich speichere, dann erscheint „Bitte einen Titel eingeben.“

**Nicht Teil dieser Story:** Anwesenheit bestätigen (US-EZ-10); neue Personen anlegen (US-EZ-11); Einchecken per QR-Code; Rechte für Projektteams.

---

### US-EZ-10: Anwesenheit beim Arbeitseinsatz bestätigen

**Als** Mitarbeiter:in der Geschäftsstelle oder Referent:in
**möchte ich** bei eingetragenen Personen „anwesend“ oder „nicht erschienen“ setzen und Spontane ergänzen,
**damit** feststeht, wer tatsächlich mitgearbeitet hat.
**Priorität:** Must · **Regeln:** R17 · **Abhängig von:** US-EZ-09

**Akzeptanzkriterien**
- AK1: Gegeben eine Person steht mit „eingetragen“ im Einsatz, wenn ich „anwesend“ wähle, dann wird der Stand auf „anwesend“ gesetzt.
- AK2: Gegeben eine Person ist nicht gekommen, wenn ich „nicht erschienen“ wähle, dann bleibt sie mit diesem Stand im Einsatz.
- AK3: Gegeben eine bereits erfasste aktive Person kommt spontan, wenn ich sie über die Suche hinzufüge, dann steht sie direkt mit Stand „anwesend“ im Einsatz.
- AK4: Gegeben ich wähle „alle anwesend“, dann werden alle Personen mit Stand „eingetragen“ auf „anwesend“ gesetzt; „nicht erschienen“ bleibt unverändert [ANNAHME].
- AK5 (Rechte): Gegeben der Einsatz gehört zu einem Referat, das nicht meines ist, dann kann ich ihn nicht öffnen.

**Nicht Teil dieser Story:** Anlegen neuer Personen (US-EZ-11).

---

### US-EZ-11: Neue Person beim Arbeitseinsatz anlegen

**Als** Mitarbeiter:in der Geschäftsstelle oder Referent:in
**möchte ich** eine Person, die noch nicht im Vereins OS ist, direkt beim Arbeitseinsatz anlegen,
**damit** sie erfasst ist und als Aktive für weitere Mitarbeit gewonnen werden kann.
**Priorität:** Must · **Regeln:** R17 · **Abhängig von:** US-EZ-09, Administration spec.md v0.8 (R45, `ad_find_similar_persons`, `ea_create_volunteer`), Übergabe EA (E1)

**Akzeptanzkriterien**
- AK1: Gegeben die Suche findet die Person nicht, wenn ich „Neue Person anlegen“ wähle, dann gebe ich Vorname, Nachname und optional Rufname und Kontaktadresse ein.
- AK2: Gegeben eine ähnliche Person existiert bereits (auch ausgeschieden), wenn ich speichere, dann erscheint die Dublettenwarnung mit Vorname, Nachname, Rufname, Geburtsjahr und „ausgeschieden seit“; ich kann „Diese Person eintragen“ wählen (vorhandene Person auf die Anwesenheitsliste, ohne Neuanlage) oder trotzdem neu anlegen.
- AK3: Gegeben ich lege die Person an, dann erhält sie Ehrenamtsstatus „aktiv“ und die Funktion Helfer:in mit Bezug auf das Referat des Einsatzes und steht mit Stand „anwesend“ im Einsatz.
- AK4 (Fehler): Gegeben Vor- oder Nachname fehlt, wenn ich speichere, dann erscheint „Bitte Vor- und Nachnamen eingeben.“
- AK5 (Rechte): Gegeben ich habe nur Leserechte, dann wird „Neue Person anlegen“ nicht angezeigt.

**Nicht Teil dieser Story:** Information der neuen Person nach Art. 13 DSGVO [OFFEN]; Pflege weiterer Eigenschaften (Ehrenamtsmanagement); Wieder-Aktivieren Ausgeschiedener (Ehrenamtsmanagement).

---

### US-EZ-12: Einsatz korrigieren

**Als** Mitarbeiter:in der Geschäftsstelle oder Referent:in
**möchte ich** einen gespeicherten Einsatz und seine Anwesenheit ändern,
**damit** Fehler bei der Erfassung behoben werden können.
**Priorität:** Must · **Regeln:** R1–R7, R9, R13, R14 · **Abhängig von:** US-EZ-01 bis US-EZ-10

**Akzeptanzkriterien**
- AK1: Gegeben ich öffne einen Einsatz meines Referats, wenn ich „Bearbeiten“ wähle, dann kann ich alle Felder und die Anwesenheit ändern; Einsatzart und Gruppe sind nicht änderbar (bestätigt 22.10.2026).
- AK2: Gegeben ich speichere eine Änderung, dann werden „geändert von“ und „geändert am“ gesetzt; „erfasst von“ und „erfasst am“ bleiben unverändert.
- AK3 (Fehler): Gegeben die Änderung verletzt eine Pflichtregel (z. B. Enddatum vor Startdatum), wenn ich speichere, dann erscheint die zugehörige Fehlermeldung und der alte Stand bleibt erhalten.
- AK4 (Rechte): Gegeben ich habe die Vorlage Vorstand oder Admin, dann sehe ich keine Schaltfläche „Bearbeiten“, und ein direkter Schreibversuch wird von der Datenbank abgelehnt.

**Nicht Teil dieser Story:** Sperre nach Abgabe des Halbjahres [OFFEN, Finanzen]; Änderungsverlauf je Feld.

---

### US-EZ-13: Einsatz löschen

**Als** Mitarbeiter:in der Geschäftsstelle
**möchte ich** einen versehentlich angelegten Einsatz löschen,
**damit** er nicht in Listen und Abrechnung erscheint.
**Priorität:** Should · **Regeln:** R15 · **Abhängig von:** US-EZ-01

**Akzeptanzkriterien**
- AK1: Gegeben ich habe „EZ verwalten“, wenn ich „Löschen“ wähle, dann erscheint die Rückfrage „Einsatz und alle Anwesenheiten löschen?“.
- AK2: Gegeben ich bestätige, dann sind Einsatz, Anwesenheiten und Probetrainings gelöscht; angelegte Personen bleiben erhalten.
- AK3 (Rechte): Gegeben ich habe die Vorlage Referent:in, dann wird „Löschen“ nicht angezeigt und ein direkter Löschversuch wird von der Datenbank abgelehnt (Referent:innen korrigieren, löschen aber nicht; bestätigt 22.10.2026).
- AK4 (Fehler): Gegeben das Löschen scheitert technisch, dann erscheint „Der Einsatz konnte nicht gelöscht werden. Bitte erneut versuchen.“ und der Einsatz bleibt unverändert.

**Nicht Teil dieser Story:** Papierkorb oder Wiederherstellen.

---

### US-EZ-14: Einsätze auflisten und filtern

**Als** Nutzer mit Rechten auf die Anwesenheitserfassung
**möchte ich** Einsätze nach Gruppe, Referat, Einsatzart und Zeitraum filtern,
**damit** ich prüfen kann, was erfasst ist, z. B. vor der Abgabe der halbjährlichen Abrechnung.
**Priorität:** Must · **Regeln:** R13, R14 · **Abhängig von:** US-EZ-01

**Akzeptanzkriterien**
- AK1: Gegeben ich öffne die Liste, dann sehe ich je Einsatz Datum bzw. Zeitraum, Einsatzart, Gruppe oder Titel, Referat und Anzahl anwesender Personen getrennt nach Rolle; neueste zuerst.
- AK2: Gegeben ich wähle den Filter „1. Halbjahr 2026“, dann erscheinen nur Einsätze mit Datum bzw. Beginn vom 01.01. bis 30.06.2026.
- AK3: Gegeben ich wähle eine Gruppe, dann erscheinen nur Einsätze dieser Gruppe.
- AK4 (Rechte): Gegeben ich habe die Vorlage Referent:in mit Referat Klettern, dann erscheinen nur Einsätze des Referats Klettern.
- AK5: Gegeben kein Einsatz passt zu den Filtern, dann erscheint „Keine Einsätze gefunden.“
- AK6: Die Liste ist ab 375 px Breite ohne waagerechtes Scrollen nutzbar.

**Nicht Teil dieser Story:** Export; Auswertungen auf Gruppenebene (Iteration 2); Einsatzhistorie je Person (Ehrenamtsmanagement).

---

### US-EZ-15: Einsatz ansehen (nur lesen)

**Als** Admin oder Vorstand
**möchte ich** Einsätze und ihre Anwesenheit ansehen, ohne sie ändern zu können,
**damit** ich mir einen Überblick verschaffen kann (z. B. Risikomanagement bei einer Fahrt).
**Priorität:** Must · **Regeln:** R14 · **Abhängig von:** US-EZ-14, Administration spec.md v0.8 (Startwerte EZ)

**Akzeptanzkriterien**
- AK1: Gegeben ich habe die Vorlage Admin, dann sehe ich alle Einsätze aller Referate mit Anwesenheit, Probetrainings und Bemerkung.
- AK2: Gegeben ich habe die Vorlage Vorstand ohne EZ-Rechte (Startwert), dann ist die Anwesenheitserfassung auf der Startseite nicht sichtbar.
- AK3 (Rechte): Gegeben ich habe nur „EZ lesen“, dann werden „Neuer Einsatz“, „Bearbeiten“ und „Löschen“ nicht angezeigt, und Schreibversuche lehnt die Datenbank ab.
- AK4: Gegeben ich habe „EZ lesen“, dann sehe ich zu Personen nur den Namen.

**Nicht Teil dieser Story:** Konfiguration der Vorlage Vorstand (Administration).

---

### US-EZ-16: Kontrollliste Punktekonto Kletterhalle

**Als** Mitarbeiter:in der Geschäftsstelle oder Referent:in
**möchte ich** für einen Zeitraum die Anzahl anwesender Kinder je Training an Orten mit Punktekonto sehen,
**damit** ich die Rechnung der Kletterhalle prüfen kann.
**Priorität:** Should · **Regeln:** R12, R13 · **Abhängig von:** US-EZ-02, Administration spec.md v0.8 (`ad_locations.has_climbing_points`)

**Akzeptanzkriterien**
- AK1: Gegeben ich wähle Zeitraum Oktober 2026 und einen Ort mit Kennzeichen „Punktekonto Kletterhalle“, dann sehe ich je Training Datum, Gruppe und Anzahl anwesender Teilnehmer:innen sowie die Summe.
- AK2: Probetrainings werden getrennt ausgewiesen und nicht in der Summe der Teilnehmer:innen gezählt [ANNAHME].
- AK3: Trainer:innen und Helfer:innen werden nicht gezählt.
- AK4 (Rechte): Gegeben ich habe die Vorlage Referent:in, dann enthält die Liste nur Trainings der Gruppen meines Referats.
- AK5: Gegeben im Zeitraum gibt es keine Trainings an dem Ort, dann erscheint „Keine Trainings im Zeitraum.“

**Nicht Teil dieser Story:** Abgleich mit der Rechnung (Finanzen); Namen der Kinder in der Liste.

---

### US-EZ-17: Warnung bei doppelter Erfassung

**Als** Mitarbeiter:in der Geschäftsstelle oder Referent:in
**möchte ich** gewarnt werden, wenn für eine Gruppe am selben Tag bereits ein Einsatz derselben Art erfasst ist,
**damit** Trainings nicht doppelt abgerechnet werden.
**Priorität:** Should · **Regeln:** R8 · **Abhängig von:** US-EZ-01, US-EZ-05, US-EZ-08

**Akzeptanzkriterien**
- AK1: Gegeben für „Gruppe 1“ ist am 13.10.2026 ein Training erfasst, wenn ich ein weiteres Training für Gruppe 1 am 13.10.2026 speichern will, dann erscheint „Für diese Gruppe ist an diesem Tag bereits ein Einsatz dieser Art erfasst. Trotzdem speichern?“ mit Link zum vorhandenen Einsatz.
- AK2: Gegeben ich bestätige „Trotzdem speichern“, dann wird der zweite Einsatz gespeichert.
- AK3: Gegeben ich breche ab, dann bleibt die Eingabe im Formular erhalten.
- AK4 (Rechte): Gegeben der vorhandene Einsatz ist für mich nicht lesbar, dann erscheint die Warnung ohne Link [ANNAHME].

**Nicht Teil dieser Story:** Zusammenführen doppelter Einsätze.

---

### US-EZ-18: Eingabe bei fehlgeschlagenem Speichern behalten

**Als** Mitarbeiter:in der Geschäftsstelle oder Referent:in, mobil in Halle oder am Fels
**möchte ich**, dass meine Eingaben bei fehlgeschlagenem Speichern erhalten bleiben,
**damit** ich bei schlechtem Netz nichts neu eingeben muss.
**Priorität:** Must · **Regeln:** – · **Abhängig von:** US-EZ-01 bis US-EZ-11

**Akzeptanzkriterien**
- AK1: Gegeben keine Verbindung beim Speichern, dann erscheint „Die Eingabe wurde nicht gesendet. Bitte bei Verbindung erneut speichern.“ und alle Eingaben bleiben im Formular.
- AK2: Gegeben die Verbindung ist wieder da, wenn ich erneut speichere, dann wird der Einsatz genau einmal gespeichert [ANNAHME: Schutz gegen Doppel-Speichern].
- AK3 (Fehler): Gegeben meine Sitzung ist abgelaufen, wenn ich speichere, dann erscheint „Bitte erneut anmelden.“ und die Eingaben bleiben bis zur erneuten Anmeldung im Browser erhalten [ANNAHME].
- AK4 (Rechte): Gegeben meine Rechte wurden zwischenzeitlich entzogen, wenn ich speichere, dann wird nicht gespeichert und es erscheint „Keine Berechtigung für diesen Einsatz.“

**Nicht Teil dieser Story:** Offline-Erfassung mit späterem automatischem Senden.

---

### US-EZ-19: Eigene Gruppe beim Erfassen vorschlagen

**Als** Referent:in, die/der selbst Trainer:in einer Gruppe ist (ab Iteration 1: als Gruppenleitung oder Trainer:in mit eigenem Zugang),
**möchte ich** beim Erfassen meine eigene Gruppe bereits vorgeschlagen bekommen,
**damit** ich schneller erfasse und nicht versehentlich eine falsche Gruppe wähle.
**Priorität:** Must · **Regeln:** R13, R18 · **Abhängig von:** US-EZ-01, US-EZ-05, US-EZ-06, US-EZ-08; Gruppen US-GR-20 (`gr_my_groups`); Administration (`ad_me()` liefert die eigene Person)

**Akzeptanzkriterien**
- AK1: Gegeben ich bin am 13.10.2026 Trainer:in von genau einer Gruppe („Gruppe 1“), wenn ich einen Einsatz mit Gruppe (Training, Fahrt, Wettkampfbetreuung) für dieses Datum anlege, dann ist „Gruppe 1“ vorausgewählt und die Anwesenheitsliste von Gruppe 1 geladen.
- AK2: Gegeben ich bin in mehreren Gruppen eingetragen, dann stehen meine Gruppen oben in der Auswahl; vorausgewählt ist die Gruppe, deren Trainingszeit auf den Wochentag des Datums fällt, falls es genau eine solche gibt [ANNAHME]; sonst ist keine Gruppe vorausgewählt.
- AK3: Gegeben ich bin in keiner Gruppe eingetragen (z. B. Mitarbeiter:in der Geschäftsstelle), dann ist keine Gruppe vorausgewählt und die Auswahl zeigt alle Gruppen, für die ich Rechte habe.
- AK4: Gegeben eine Gruppe ist vorausgewählt, wenn ich eine andere Gruppe wähle, für die meine Rechtevorlage das Erfassen erlaubt, dann wird die Anwesenheitsliste der gewählten Gruppe geladen.
- AK5 (Rechte): Gegeben ich bin Trainer:in einer Gruppe eines Referats, für das ich keine Rechte habe, dann wird diese Gruppe nicht vorgeschlagen und kann nicht gewählt werden; ein direkter Speicherversuch wird von der Datenbank abgelehnt (der Vorschlag gibt kein Recht).
- AK6: Gegeben meine Funktion in der Gruppe beginnt erst nach dem Datum des Einsatzes oder endete davor, dann wird die Gruppe für dieses Datum nicht vorgeschlagen (Stichtag wie R16).
- AK7 (Fehler): Gegeben der Vorschlag kann nicht geladen werden, dann bleibt die Gruppenauswahl leer und nutzbar; es erscheint kein Fehler, der das Erfassen blockiert.

**Nicht Teil dieser Story:** Reichweite „Gruppe“ und Zugang für Gruppenleitungen und Trainer:innen (Iteration 1, Administration A6/A7); Vorschlag eines Referats beim Arbeitseinsatz; Vorschlag des Datums aus der nächsten Trainingszeit.

---

### US-EZ-20: Kurs oder Tour von Hand erfassen

**Als** Mitarbeiter:in der Geschäftsstelle oder Referent:in
**möchte ich** einen Kurs oder eine Tour, die nicht über die Planungshilfe geplant wurde, direkt anlegen und Leitung und Helfende eintragen,
**damit** auch diese Einsätze erfasst und abgerechnet werden können.
**Priorität:** Must · **Regeln:** R1, R2, R3, R11, R13, R17, R20, R21 · **Abhängig von:** US-EZ-07 (Personensuche), US-EZ-09/-10 (Eintragen und Bestätigen wie beim Arbeitseinsatz)

**Akzeptanzkriterien**
- AK1: Gegeben ich wähle „Kurs“ oder „Tour“, dann muss ich Referat, Titel, organisierende Person und Zeiten angeben (eintägig: Datum und Dauer-Kategorie; mehrtägig: Start und Ende am Startort); eine Gruppe und ein Ort werden nicht abgefragt (Product Owner 24.10.2026).
- AK2: Gegeben ich trage Personen über die Suche „Aktive“ ein, dann stehen sie mit Stand „eingetragen“ und Rolle Trainer:in [ANNAHME: vorbelegt] oder Helfer:in im Einsatz; am Termin setze ich „anwesend“ oder „nicht erschienen“ wie beim Arbeitseinsatz.
- AK3: Gegeben ich speichere Kurs „Toprope-Kurs“ im Referat Klettern am 21.11.2026 mit Dauer „mindestens 8 Stunden“ und zwei eingetragenen Personen, dann entsteht ein Einsatz „Kurs“ mit diesen Angaben und ohne Teilnehmende.
- AK4 (Fehler): Gegeben ich versuche, eine Person mit Rolle Teilnehmer:in einzutragen, dann erscheint „Bei dieser Einsatzart gibt es keine Teilnehmer:innen.“ (Teilnehmende sind in Yolawo angemeldet, Product Owner 24.10.2026).
- AK5 (Rechte): Gegeben ich habe die Vorlage Referent:in mit Referat Klettern, dann kann ich als Referat nur Klettern wählen.

**Nicht Teil dieser Story:** Teilnehmende und Anmeldung (Yolawo); Lehreinheiten [OFFEN]; Planung und Kalkulation (Planungshilfe Touren und Kurse); neue Personen anlegen (nur beim Arbeitseinsatz).

---

### US-EZ-21: Trainingslager erfassen

**Als** Mitarbeiter:in der Geschäftsstelle oder Referent:in
**möchte ich** ein Trainingslager einer Gruppe mit Start und Ende erfassen,
**damit** Finanzen es nach dem Satz für Mehrtageskurse/Trainingslager abrechnen kann.
**Priorität:** Must · **Regeln:** R1, R2, R4, R5, R8, R11, R13, R16, R18 · **Abhängig von:** US-EZ-02, US-EZ-06, US-EZ-07

**Akzeptanzkriterien**
- AK1: Gegeben ich wähle „Trainingslager“, dann sind die Felder wie bei der Mehrtagesfahrt: Gruppe, Titel, organisierende Person, Startdatum mit optionalem Beginn („Abfahrt am Startort“), Enddatum mit optionalem Ende („Rückkehr am Startort“) (Product Owner 24.10.2026).
- AK2: Die Anwesenheitsliste der Gruppe zum Startdatum ist vorbelegt; Trainer:innen, Helfer:innen und Teilnehmer:innen werden angekreuzt (wie US-EZ-02).
- AK3: Gegeben Trainingslager „Frankenjura“ der Gruppe 1 vom 28.12.2026 09:00 bis 02.01.2027 17:00, wenn ich speichere, dann entsteht ein Einsatz „Trainingslager“ und erscheint in Listen als „28.12.2026–02.01.2027“.
- AK4 (Fehler): Gegeben das Enddatum liegt nicht nach dem Startdatum, dann erscheint die Fehlermeldung aus R2.
- AK5 (Rechte): Gegeben ich habe die Vorlage Referent:in mit Referat Leistungssport, dann kann ich Trainingslager nur für Gruppen dieses Referats anlegen.

**Nicht Teil dieser Story:** Planung des Trainingslagers in der Planungshilfe; eintägige Trainingslager.

---

### US-EZ-22: Einsatz absagen und Absage zurücknehmen

**Als** Mitarbeiter:in der Geschäftsstelle oder Referent:in
**möchte ich** einen Einsatz, der nicht stattfindet, mit Grund absagen und eine irrtümliche Absage zurücknehmen,
**damit** nachvollziehbar bleibt, was geplant war, ohne dass der Einsatz abgerechnet wird.
**Priorität:** Must · **Regeln:** R13, R14, R22, R23, R24, R25 · **Abhängig von:** US-EZ-01 bis US-EZ-09, US-EZ-20, US-EZ-21

**Akzeptanzkriterien**
- AK1: Gegeben ein Einsatz meines Referats ohne anwesende Personen, wenn ich „Absagen“ wähle und den Grund „Wetter“ eingebe, dann ist der Einsatz „abgesagt“; Liste und Detail zeigen das Kennzeichen „abgesagt“ und im Detail „Abgesagt am TT.MM.JJJJ von <Name>: Wetter“.
- AK2: Gegeben der Einsatz ist abgesagt, dann kann ich ihn nicht bearbeiten; angezeigt werden nur „Absage zurücknehmen“ und (für die Geschäftsstelle) „Löschen“.
- AK3: Gegeben ich wähle „Absage zurücknehmen“ und bestätige die Rückfrage, dann ist der Einsatz wieder „erfasst“ und änderbar; eingetragene Personen sind unverändert.
- AK4: Gegeben ein abgesagtes Training am Ort mit Punktekonto, dann erscheint es nicht in der Kontrollliste Kletterhalle und löst keine Warnung bei doppelter Erfassung aus.
- AK5 (Fehler): Gegeben eine Person steht mit „anwesend“ im Einsatz, wenn ich absagen will, dann erscheint „Der Einsatz hat schon anwesende Personen und kann nicht abgesagt werden.“; gegeben der Grund fehlt, dann erscheint „Bitte einen Grund mit höchstens 500 Zeichen angeben.“
- AK6 (Rechte): Gegeben ich habe nur Leserechte (Admin, Vorstand), dann sehe ich Absage und Grund, aber keine Schaltflächen „Absagen“ oder „Absage zurücknehmen“.
- AK7 (Planungshilfe): Gegeben der Einsatz kommt aus der Planungshilfe, dann werden „Absagen“ und „Löschen“ nicht angezeigt; Absagen geht nur über die Planungshilfe (R25).

**Nicht Teil dieser Story:** Benachrichtigung der eingetragenen Personen; Absage einzelner Tage eines mehrtägigen Einsatzes.

---

### US-EZ-23: Kurs oder Tour aus der Planungshilfe übernehmen

**Als** Referent:in Touren oder Ausbildung bzw. Mitarbeiter:in der Geschäftsstelle
**möchte ich**, dass ein geplanter Kurs bzw. eine geplante Tour automatisch als Einsatz in der Anwesenheitserfassung entsteht, sobald das Angebot in Yolawo angelegt ist,
**damit** Leitung und Helfende nicht doppelt erfasst werden und am Termin nur noch die Anwesenheit bestätigt wird.
**Priorität:** Must · **Regeln:** R17, R20, R21, R22, R25, R26, R27 · **Abhängig von:** US-EZ-20; Planungshilfe Touren und Kurse US-TK-16, US-TK-17 (spec.md TK R15, T13)

**Akzeptanzkriterien**
- AK1: Gegeben eine Tour mit zwei Leitenden erhält in der Planungshilfe den Status „in Yolawo angelegt“, dann entsteht ein Einsatz „Tour“ mit Referat, Titel (bis 90 Zeichen, ungekürzt), Zeiten und organisierender Person aus der Planung; die Leitenden stehen mit Stand „eingetragen“ und Rolle Trainer:in bzw. Helfer:in im Einsatz.
- AK2: Gegeben die Planung wird geändert und noch niemand ist „anwesend“, dann übernimmt der Einsatz die Änderung; in der Anwesenheitserfassung ergänzte Personen bleiben erhalten.
- AK3: Gegeben mindestens eine Person ist „anwesend“, wenn die Planung geändert wird, dann bleibt der Einsatz unverändert und die Planungshilfe zeigt „Der Einsatz ist schon erfasst und wurde nicht geändert. Bitte in der Anwesenheitserfassung anpassen.“
- AK4: Gegeben die Planung wird abgesagt und niemand ist „anwesend“, dann ist der Einsatz „abgesagt“ mit dem Grund aus der Planung und bleibt sichtbar.
- AK5: Gegeben ich öffne den Einsatz in der Anwesenheitserfassung, dann sehe ich den Hinweis „Aus der Planungshilfe Touren und Kurse. Kopf und Personen aus der Planung werden dort geändert.“; ich kann den Stand setzen und weitere Personen ergänzen, aber Kopf und Personen aus der Planung nicht ändern; „Absagen“ und „Löschen“ werden nicht angezeigt.
- AK6 (Rechte): Gegeben eine Person ohne Schreibrecht in der Planungshilfe für das Referat, dann kann sie keinen Einsatz über die Planungshilfe anlegen oder ändern; die Datenbank lehnt den Aufruf ab.
- AK7: Die Planungshilfe kann abfragen, ob der Einsatz durchgeführt ist (mindestens eine Leitung oder Helfer:in „anwesend“ [ANNAHME]); sie erhält dabei keine Namen.

**Nicht Teil dieser Story:** Teilnehmende aus Yolawo; Rücknahme einer Absage aus der Planungshilfe (Status „abgesagt“ ist dort endgültig); Planung, Kalkulation und Freigabe (Planungshilfe).

---

## Prüfung gegen die Definition of Ready

- Rechtevorlage, Ziel, Nutzen, Akzeptanzkriterien (Given-When-Then, Fehler- und Rechte-Fall) und „Nicht Teil dieser Story“: in allen Stories enthalten.
- Begriffe im Glossar (v1.5): erfüllt.
- Datenfelder im Datenmodell der Spec: **offen**, entsteht mit spec.md.
- Keine [OFFEN]-Punkte in den Stories: **nicht erfüllt** für US-EZ-11 (Art. 13 DSGVO, als „Nicht Teil“ ausgelagert) und US-EZ-12 (Sperre nach Halbjahr, ausgelagert). Beide blockieren die Umsetzung nicht.
- Bestätigt vom Product Owner (22.10.2026): R15 (Löschen nur Geschäftsstelle), R16 (Stichtag für Teilnehmer:innen und Trainer:innen; bei mehrtägigen Einsätzen Startdatum), R18 (Vorschlag der eigenen Gruppe ohne zusätzliche Rechte), Rolle „Helfer:in“ als Standard beim Arbeitseinsatz, keine organisierende Person bei Wettkampfbetreuung, Einsatzart und Gruppe nach dem Speichern nicht änderbar, Feldlängen (Titel 60, Probetraining 30, Bemerkung 500 Zeichen), Orte pflegt nur der Admin.
- Noch offene Annahmen (bei der Spec bestätigen): Wettkampfbetreuung nur mit Gruppe; „alle anwesend“ lässt „nicht erschienen“ unverändert; Probetrainings nicht in der Summe der Kontrollliste; Warnung ohne Link bei nicht lesbarem Einsatz; Schutz gegen Doppel-Speichern; Eingaben bei abgelaufener Sitzung im Browser behalten; Vorauswahl bei mehreren eigenen Gruppen über den Wochentag der Trainingszeit (US-EZ-19 AK2).
- Bestätigt vom Product Owner (24.10.2026): Kurs, Tour und Trainingslager auch von Hand; Kurs und Tour ohne Gruppe und ohne Teilnehmende; Trainingslager wie Mehrtagesfahrt; Titel bis 90 Zeichen; Absage für alle Einsatzarten mit Grund, durch Nutzer mit Schreibrecht, zurücknehmbar; Einsätze aus der Planungshilfe in der Anwesenheitserfassung nur für die Anwesenheit.
- Noch offene Annahmen aus v0.4: Rolle Trainer:in vorbelegt bei Kurs und Tour (US-EZ-20 AK2); „durchgeführt“ = mindestens eine Leitung oder Helfer:in anwesend (US-EZ-23 AK7).
- Voraussetzungen aus anderen Modulen: eingearbeitet in Gruppen (US-GR-18, US-GR-19, US-GR-20) und Administration (spec.md v0.8, T50–T58); müssen vor der Anwesenheitserfassung umgesetzt sein. US-EZ-23 zusätzlich: Planungshilfe Touren und Kurse (spec.md TK T1–T8), umgesetzt zusammen mit TK T13.
- Startbestand der Orte: liefert der Product Owner bei der Umsetzung (Migration der Administration, T51).
