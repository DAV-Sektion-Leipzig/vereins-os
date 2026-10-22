# Erhebung: Anwesenheitserfassung

Datum: 22.10.2026 · Version 0.3 · Beteiligte: Toni Werner (Product Owner), Claude (Requirements Engineer)
Quellen: Microsoft-Forms-Formular „Anwesenheitserfassung – Jugend“ (Screenshots des Product Owners, 21.10.2026; nicht im Projekt abgelegt, weil sie echte Namen von Kindern und Trainer:innen zeigen); Steckbrief v0.7; Vergütungsordnung der Sektion (2025_DAV_Leipzig_FO_VGO).
Änderungen v0.3: Kein Vorstandsbeschluss zu Vergütungsordnung Punkt 7 nötig (R4); Kurs und Tour: Planung und Kalkulation im Modul Touren und Kurse, Durchführung hier; im MVP Anlegen in der Anwesenheitserfassung [ANNAHME]; Glossarbegriffe ergänzt (glossar.md v1.5).
Änderungen v0.2: Orte in der Administration; Enduhrzeit bei mehrtägigen Einsätzen; Wettkampfbegleitung ein- oder mehrtägig; organisierende Person aus allen Aktiven; Erfassung immer je Gruppe; Kinder mit Vor- und Nachname; Erwachsenenfahrten nicht im Scope; Reihenfolge Gruppen → Anwesenheitserfassung → Finanzen.
Änderungen v0.1: Ist-Formular ausgewertet; Entscheidungen vom 21.10.2026.

## A. Rechtevorlagen & Rechte

| Rechtevorlage | Reichweite | Lesen | Einsatz anlegen | Anwesenheit erfassen | Ändern / Korrigieren | Personen anlegen (Arbeitseinsatz) |
|---|---|---|---|---|---|---|
| Admin | alle | ja | nein | nein | nein | nein |
| Geschäftsstelle (EZ verwalten) | alle | ja | ja | ja | ja | ja |
| Referent:in (EZ bearbeiten) | Referat | ja | ja | ja | ja [ANNAHME: Einsätze des Referats] | ja |
| Vorstand | alle (vom Admin vergeben) | ja | nein | nein | nein | nein |
| Gruppenleitung / Trainer:in (Iteration 1) | Gruppe | ja | ja | ja | ja [ANNAHME] | nein [ANNAHME] |

Orte (Trainingsorte) pflegt der Admin in der Administration. Quelle: Steckbrief v0.7, rollen.md v1.0.

## B. Abläufe (inkl. Zustände)

**Ist-Ablauf (Forms):** Anmeldung mit Microsoft-Konto (Name und E-Mail der erfassenden Person werden gespeichert) → Art wählen → je nach Art Detailseite → Gruppe wählen → Kinder und Trainer*innen der Gruppe ankreuzen → „weitere Trainer*innen und/oder Bemerkung?“ → Absenden. Die Anmeldung von Fahrten läuft über ein zweites Formular (künftig Modul Touren und Kurse).

**Soll-Abläufe (MVP):** Einsätze mit Gruppenbezug werden immer je Gruppe erfasst.

- **B1 Training erfassen:** Einsatzart „Training“ → Gruppe → Datum → Beginn und Ende aus der Trainingszeit (änderbar) → Ort → Anwesenheit: Teilnehmer:innen und Trainer:innen/Helfer:innen der Gruppe ankreuzen (Rolle vorbelegt) → optional Vertretung hinzufügen, Probetraining (Vorname), Bemerkung → Speichern.
- **B2 Eintägigen Einsatz erfassen** (Tagesausflug, Ausbildungsfahrt eintägig, Wettkampfbegleitung eintägig): Einsatzart → Gruppe → Titel, organisierende Person (bei Fahrten) → Datum, Dauer „unter 8 Stunden“ / „mindestens 8 Stunden“ → Anwesenheit → Bemerkung → Speichern.
- **B3 Mehrtägigen Einsatz erfassen** (Mehrtagesfahrt, Ausbildungsfahrt mehrtägig, Wettkampfbegleitung mehrtägig): Einsatzart → Gruppe → Titel, organisierende Person (bei Fahrten) → Startdatum, Beginn (Abfahrt am Startort), Enddatum, Ende (Rückkehr am Startort) → Anwesenheit → Bemerkung → Speichern.
- **B4 Kurs, Tour, Trainingslager erfassen:** Einsatzart → Referat → Titel → Zeiten (eintägig Datum und Dauer-Kategorie, mehrtägig Start und Ende) → Personen eintragen (Leitung, Trainer:innen, Helfer:innen, Teilnehmende [ANNAHME]) → Anwesenheit bestätigen → Speichern. Planung und Kalkulation im Modul Touren und Kurse; Übernahme von dort [OFFEN], bis dahin Anlegen hier [ANNAHME]. Lehreinheiten bei Kursen: [OFFEN].
- **B5 Arbeitseinsatz:** anlegen (Titel, Referat, Datum, Dauer) → Personen eintragen („eingetragen“) → nach dem Einsatz „anwesend“ bzw. „nicht erschienen“ setzen; neue Personen anlegen (Aktive, Funktion Helfer:in).
- **B6 Korrigieren:** gespeicherten Einsatz öffnen, Felder und Anwesenheit ändern [ANNAHME: Änderung mit „geändert von / am“].
- **B7 Organisierende Person wählen:** Suchfeld über alle Aktiven (Ehrenamtsstatus „aktiv“); ist eine Gruppe gewählt, stehen deren Gruppenleitung, Trainer:innen und Helfer:innen oben.

**Zustände Einsatz:** [ANNAHME] nur „erfasst“; keine Freigabe im MVP. Sperre nach Abgabe des Halbjahres: [OFFEN] (Finanzen).
**Zustände Anwesenheit:** eingetragen · anwesend · nicht erschienen (bei Training direkt „anwesend“ beim Ankreuzen).

## C. Daten (Feld | Typ | Pflicht | Beispiel | Quelle)

**Einsatz**

| Feld | Typ | Pflicht | Beispiel | Quelle |
|---|---|---|---|---|
| Einsatzart | Auswahl: Training, Tagesausflug, Mehrtagesfahrt, Ausbildungsfahrt, Wettkampfbegleitung, Kurs, Tour, Trainingslager, Arbeitseinsatz | ja | Training | Forms „Art“ (erweitert) |
| Ein-/mehrtägig | Auswahl | ja bei Ausbildungsfahrt, Wettkampfbegleitung, Kurs, Tour | mehrtägig | Product Owner 21./22.10.2026 |
| Referat | Verweis Referat | ja | Kinder und Jugend | über Gruppe oder Auswahl |
| Gruppe | Verweis Gruppe | ja bei Training, Fahrten und Wettkampfbegleitung | Gruppe 1 | Forms „Gruppe“; Erfassung immer je Gruppe |
| Titel | Text, 1–2 Schlagwörter | ja außer bei Training | Kletterwochenende Elbsandstein | Forms „Titel“ |
| Organisierende Person | Verweis Person (Aktive:r) mit Suche | ja bei Fahrten; optional bei Tour und Trainingslager [ANNAHME] | Trainerin der Gruppe | Forms „Wer hat die Ausfahrt organisiert?“ |
| Datum | Datum | ja bei Training und eintägig | 14.10.2026 | Forms |
| Beginn, Ende (Training) | Uhrzeit | ja | 17:00–19:00 | Trainingszeit (Gruppen) als Vorschlag |
| Ort (Training) | Verweis Ort (Stammdaten der Administration) | ja | [Werte pflegt der Admin] | Forms „Ort“ |
| Dauer (eintägig) | Auswahl: unter 8 Stunden / mindestens 8 Stunden | ja bei eintägigen Einsätzen außer Training | mindestens 8 Stunden | Forms „Dauer“ |
| Startdatum, Beginn | Datum, Uhrzeit | ja bei mehrtägig | 07.11.2026, 16:00 | Forms |
| Enddatum, Ende | Datum, Uhrzeit | ja bei mehrtägig | 09.11.2026, 18:30 | Forms (Enddatum); Uhrzeit neu |
| Bemerkung | Text | nein | „Halle wegen Wettkampf halb gesperrt“ | Forms „Bemerkung“ |
| Erfasst von, erfasst am | Verweis Nutzer, Zeitstempel | automatisch | – | Forms (Name, E-Mail) |

**Anwesenheit**

| Feld | Typ | Pflicht | Beispiel | Quelle |
|---|---|---|---|---|
| Person | Verweis Person; Anzeige Vorname (bzw. Rufname) und Nachname | ja | Kind A Muster | Forms „Kinder Gruppe X“, „Trainer*innen Gruppe X“ |
| Rolle | Auswahl: Trainer:in, Helfer:in, Teilnehmer:in | ja | Trainer:in | neu (Vergütungsordnung) |
| Stand | Auswahl: eingetragen, anwesend, nicht erschienen | ja | anwesend | Steckbrief |
| Vertretung | Ja/Nein (Person nicht aus der Gruppe) | automatisch | ja | Forms „weitere Trainer*innen“ |
| Probetraining | Text (nur Vorname), je Einsatz 0–n | nein | Lena | Steckbrief |

**Ort (Stammdaten, Administration)**

| Feld | Typ | Pflicht | Beispiel | Quelle |
|---|---|---|---|---|
| Bezeichnung | Text | ja | Kletterhalle [Name] | Product Owner 22.10.2026 |
| Punktekonto Kletterhalle | Ja/Nein | ja | ja | [ANNAHME: für die Kontrollliste] |
| Status | aktiv / inaktiv | ja | aktiv | [ANNAHME: nie löschen, wie andere Stammdaten] |

## D. Regeln

- **R1:** Die Einsatzart bestimmt die Pflichtfelder: Training → Gruppe, Datum, Beginn, Ende, Ort; eintägig → (Gruppe bei Gruppen-Einsätzen), Titel, organisierende Person (bei Fahrten), Datum, Dauer-Kategorie; mehrtägig → (Gruppe bei Gruppen-Einsätzen), Titel, organisierende Person (bei Fahrten), Startdatum, Beginn, Enddatum, Ende.
- **R2:** Bei mehrtägigen Einsätzen liegt das Enddatum nach dem Startdatum, sonst Fehlermeldung „Das Enddatum muss nach dem Startdatum liegen. Für eintägige Einsätze bitte ‚eintägig‘ wählen.“
- **R3:** Eintägige Einsätze (außer Training) haben keine Uhrzeiten, nur die Kategorie unter / mindestens 8 Stunden.
- **R4:** Beginn und Ende bei mehrtägigen Einsätzen sind Abfahrt und Rückkehr am Startort (Reisezeit = Arbeitszeit). Der Hinweis im heutigen Formular („bei Erwachsenenfahrten Ankunftszeit am Zielort“) entfällt.
- **R5:** Je Einsatz mindestens eine anwesende Person mit Rolle Trainer:in oder Helfer:in; bei Training mindestens eine anwesende Teilnehmer:in [ANNAHME, wie Pflichtfelder im Forms].
- **R6:** Probetraining nur Vorname; keine weiteren Angaben.
- **R7:** Bemerkung ist optional; Hinweis am Feld: „Keine Angaben zu Gesundheit oder anderen sensiblen Daten von Kindern.“
- **R8:** Gibt es für dieselbe Gruppe, dasselbe Datum und dieselbe Einsatzart bereits einen Einsatz, erscheint die Warnung „Für diese Gruppe ist an diesem Tag bereits ein Einsatz dieser Art erfasst. Trotzdem speichern?“ [ANNAHME].
- **R9:** „Erfasst von“ und „erfasst am“ setzt das System; nicht änderbar.
- **R10:** Bezeichnungen der Einsatzarten in der Oberfläche wie im Forms-Formular (Tagesausflug, Mehrtagesfahrt, Ausbildungsfahrt …) [ANNAHME].
- **R11:** Organisierende Person: Auswahl nur aus Personen mit Ehrenamtsstatus „aktiv“, per Suche; bei gewählter Gruppe werden deren Gruppenleitung, Trainer:innen und Helfer:innen zuerst angezeigt.
- **R12:** Auswahl des Orts nur aus aktiven Orten der Stammdaten.

## E. Schnittstellen

- Keine externen Schnittstellen im MVP. Das Forms-Formular läuft bis Iteration 1 parallel; keine Übernahme der Altdaten.
- Intern: Gruppen (Gruppen, Teilnehmer:innen, Funktionen, Trainingszeiten), Ehrenamtsmanagement (Aktive, Funktionen), Administration (Rechte, Stammdaten Orte), Finanzen (liest Einsätze und Anwesenheit).
- Modul Touren und Kurse (eigenständiges Planungstool: Erstellung, Planung, Kalkulation inkl. Deckungsbeitrag, Material, CO2; Anmeldung von Fahrten): Übernahme eines geplanten Kurses, einer Tour oder einer angemeldeten Fahrt als Einsatz [OFFEN].

## F. Datenschutz

- Teilnehmer:innen sind Minderjährige. Anzeige in der Anwesenheitsliste mit Vorname (bzw. Rufname) und Nachname, damit eindeutig ausgewählt werden kann; keine weiteren Daten.
- Suche nach der organisierenden Person zeigt Namen aller Aktiven; das erweitert den Sichtbarkeitspfad für Referent:innen über das eigene Referat hinaus (nur Name). Übergabe an die Administration (A3).
- Bemerkung als Freitext: Risiko sensibler Angaben; Hinweis am Feld (R7).
- Screenshots mit echten Namen werden nicht im Projekt oder Repository abgelegt; Testdaten nur fiktiv.

## G. Nicht-funktional

- Mobil ab 375 px; Erfassung eines Trainings mit wenigen Schritten, Ziel unter 1 Minute [ANNAHME].
- Kein Offline-Betrieb; bei fehlgeschlagenem Speichern Hinweis, Eingaben bleiben erhalten.
- Ablauf wie im Forms-Formular (Art → Details → Gruppe → Anwesenheit) [ANNAHME].
- Suche nach Personen ab 2 Zeichen, Ergebnis sofort [ANNAHME].

## Offene Fragen (Frage | Wer klärt | bis wann)

| Frage | Wer klärt | bis wann |
|---|---|---|
| Übernahme geplanter Kurse und Touren sowie angemeldeter Fahrten aus dem Modul Touren und Kurse; Lehreinheiten bei Kursen | Product Owner (Chat Touren und Kurse) | vor den Stories für Kurs und Tour |
| Welcher Satz gilt für eine eintägige Ausbildungsfahrt? Satz der Wettkampfbegleitung je Tag? | Finanzen | vor Spec Finanzen |
| Einsätze nach Abgabe des Halbjahres sperren? | Finanzen | vor Spec Finanzen |
| Erledigt 22.10.2026: Ortsliste (Administration), Enduhrzeit mehrtägig, Wettkampfbegleitung mehrtägig, organisierende Person, Anzeige der Kinder, Erwachsenenfahrten, Reihenfolge, Vorstandsbeschluss Punkt 7 (nicht nötig), Glossarbegriffe | – | – |
