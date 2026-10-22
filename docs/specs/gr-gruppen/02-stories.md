# User Stories: Gruppen (GR)

Stand: 22.10.2026 · Version 0.7 · Status: Entwurf · Product Owner: Toni Werner
Änderungen v0.7: US-GR-19 um AK8 ergänzt: Lesefunktion `gr_groups_for_attendance(p_date)` liefert der Anwesenheitserfassung die wählbaren Gruppen (ID, Name, Referat) ohne Personendaten; Anforderung aus spec.md Anwesenheitserfassung v0.1, direkt aus dem Chat Anwesenheitserfassung eingearbeitet.
Änderungen v0.6: Neue Story US-GR-20 „Eigene Gruppen für den Vorschlag in der Anwesenheitserfassung“ mit Lesefunktion `gr_my_groups(date)` (nur eigene Funktionen des angemeldeten Nutzers); Anforderung aus der Anwesenheitserfassung (US-EZ-19, R18; Product Owner, 22.10.2026), direkt aus dem Chat Anwesenheitserfassung eingearbeitet.
Änderungen v0.5: A13 bestätigt (Product Owner, 22.10.2026): Trainingszeiten pflegt die Geschäftsstelle fest in Gruppen; Wochentag, Beginn und Ende sind nach dem Speichern nicht änderbar, nur „Ändern ab“ oder „Beenden“; keine eigene Korrekturfunktion. Abgestimmt aus dem Chat Anwesenheitserfassung.
Änderungen v0.4: Übergabe aus der Anwesenheitserfassung (uebergabe-trainingszeiten.md v1.2) eingearbeitet: Trainingszeiten strukturiert mit Historie statt Textfeld (US-GR-02, -03, -04, -05, -16, -17 angepasst; neu US-GR-18 Trainingszeiten pflegen, US-GR-19 Anwesenheitsliste für die Anwesenheitserfassung); Regeln R18–R20; Annahmen A11–A13; Definition of Ready aktualisiert (Referat jetzt im Glossar).
Änderungen v0.3: US-GR-01 um AK6 ergänzt: Admin sieht in der Administration alle Personen, auch Teilnehmer:innen, Erziehungsberechtigte und Notfallkontakte, und pflegt ihre Personendaten (Name, Rufname, Geburtsdatum, Kontaktdaten, Mitgliedsnummer) zentral; Änderungen gelten in allen Modulen (Product Owner, 21.10.2026).
Änderungen v0.2: Annahmen A1–A10 bestätigt (Product Owner, 21.10.2026); R8a präzisiert; Mengengerüst.
Grundlage: 00-steckbrief.md v0.7, 01-erhebung.md v0.7 (Regeln R1–R20), glossar.md v1.5, rollen.md v1.0, spec.md Administration v0.8, specs/ez-einsaetze/uebergabe-trainingszeiten.md v1.3

Oberflächentexte in der Ansprache „du“. „Lesen“, „bearbeiten“, „verwalten“ meinen die Stufe der Rechtevorlage für das Modul Gruppen. Startwerte: Geschäftsstelle „verwalten“, Admin „lesen“, Vorstand „kein Zugriff“.

## Übersicht

| ID | Titel | Priorität | Abhängig von |
|---|---|---|---|
| US-GR-01 | Rechte und Trennung der Sichtbarkeit | Must | Nachtrag Administration (RLS ea_persons/ea_properties) |
| US-GR-02 | Gruppenübersicht | Must | US-GR-01 |
| US-GR-03 | Gruppe anlegen und ändern | Must | US-GR-02 |
| US-GR-04 | Gruppe auflösen | Should | US-GR-03, US-GR-11, US-GR-18 |
| US-GR-05 | Gruppendetail mit Teilnehmerliste | Must | US-GR-03, US-GR-18 |
| US-GR-06 | Teilnehmer:in anlegen oder vorhandene Person wählen | Must | US-GR-05 |
| US-GR-07 | Erziehungsberechtigte pflegen | Must | US-GR-06 |
| US-GR-08 | Vertrag erfassen und Teilnahme anlegen | Must | US-GR-07 |
| US-GR-09 | Notfallkontakte pflegen | Must | US-GR-06 |
| US-GR-10 | Fotoerlaubnis pflegen | Must | US-GR-06 |
| US-GR-11 | Vertrag kündigen und Teilnahme beenden | Must | US-GR-08 |
| US-GR-12 | Gesundheitsangaben pflegen | Must | US-GR-06 |
| US-GR-13 | Gruppenleitung, Trainer:innen und Helfer:innen festlegen | Must | US-GR-03 |
| US-GR-14 | Notfallkontakte unterwegs finden | Must | US-GR-09 |
| US-GR-15 | E-Mail-Adressen einer Gruppe kopieren | Should | US-GR-07 |
| US-GR-16 | Import der Bestands-Excel | Must | US-GR-08, US-GR-09, US-GR-10, US-GR-12, US-GR-18 |
| US-GR-17 | Testdaten in TEST | Must | US-GR-01 |
| US-GR-18 | Trainingszeiten pflegen | Must | US-GR-03 |
| US-GR-19 | Anwesenheitsliste für die Anwesenheitserfassung | Must | US-GR-08, US-GR-13, US-GR-18; Administration v0.8 (Modul EZ, Reichweite Referat) |
| US-GR-20 | Eigene Gruppen für den Vorschlag in der Anwesenheitserfassung | Must | US-GR-13, US-GR-18; Administration (`ad_me()`) |

Empfohlene Umsetzungsreihenfolge: 01 → 17 → 02 → 03 → 18 → 05 → 06 → 07 → 08 → 09 → 10 → 12 → 14 → 11 → 13 → 19 → 20 → 15 → 04 → 16. Die Datenbankteile (Tabellen, RLS) entstehen jeweils mit der ersten Story, die sie braucht; US-GR-01 legt die Rechteprüfung für alle `gr_`-Tabellen fest. US-GR-19 und US-GR-20 müssen vor dem Start der Anwesenheitserfassung (EZ) fertig sein.

---

### US-GR-01: Rechte und Trennung der Sichtbarkeit
**Als** Admin
**möchte ich**, dass Gruppen-Daten nur mit Rechten auf Gruppen sichtbar sind und Personen, die nur in Gruppen vorkommen, im Ehrenamtsmanagement nicht erscheinen,
**damit** Daten von Kindern und Erziehungsberechtigten nur bei den Berechtigten landen.
**Priorität:** Must · **Regeln:** R11, R14 · **Abhängig von:** Nachtrag Administration (RLS für ea_persons und ea_properties nach Zugehörigkeit)
**Akzeptanzkriterien**
- AK1: Gegeben die Migration läuft, wenn sie fertig ist, dann hat die Vorlage Admin für Gruppen die Stufe „lesen“; Geschäftsstelle „verwalten“ und Vorstand „kein Zugriff“ bleiben unverändert.
- AK2: Gegeben eine Teilnehmer:in ohne Amt, Funktion oder Einsatz, wenn ein Nutzer nur mit Rechten auf das Ehrenamtsmanagement Personen liest (Oberfläche oder Datenbankabfrage), dann erhält er diese Person und ihre Eigenschaften nicht (Rechte-Fall).
- AK3: Gegeben eine Person ist Erziehungsberechtigte:r und zugleich Trainer:in, wenn ein Nutzer mit Rechten auf das Ehrenamtsmanagement sie liest, dann sieht er sie als Aktive:n, aber keine gruppenspezifischen Angaben (Teilnahmen der Kinder, Verträge, Notfallkontakte).
- AK4: Gegeben ein Nutzer mit der Vorlage Vorstand ohne Rechte auf Gruppen, wenn er Gruppen-Tabellen abfragt oder eine Gruppen-Seite aufruft, dann erhält er keine Daten bzw. „Für diesen Bereich hast du keine Rechte.“ (Rechte-Fall).
- AK5: Gegeben ein Nutzer mit „Gruppen lesen“, wenn er Daten ändern will, dann lehnt die Datenbank ab (Fehlerfall).
- AK6: Gegeben eine Teilnehmer:in ohne Ehrenamtsstatus, wenn der Admin die Personenübersicht der Administration öffnet, dann sieht er sie mit ihren Personendaten und kann z. B. die Adresse ändern; die Änderung ist sofort in Gruppen sichtbar. Gesundheitsangaben, Verträge und Teilnahmen sieht er dort nicht (nur über Gruppen mit den Rechten aus A).
- AK7: Gegeben ein Nutzer mit Rechten nur auf die Anwesenheitserfassung (z. B. Referent:in), wenn er `gr_`-Tabellen direkt abfragt, dann erhält er keine Daten; Namen von Teilnehmer:innen erhält er nur über US-GR-19 (Rechte-Fall, R20).
**Nicht Teil dieser Story:** Reichweite „Gruppe“ und Zugang für Gruppenleitungen und Trainer:innen (nach MVP); Rechte je Objekt.

### US-GR-02: Gruppenübersicht
**Als** Mitarbeiter:in der Geschäftsstelle
**möchte ich** alle Gruppen mit Referat, Trainingszeiten und Anzahl aktiver Teilnehmer:innen sehen und nach Referat filtern,
**damit** ich schnell die richtige Gruppe finde.
**Priorität:** Must · **Regeln:** R7, R17, R19 · **Abhängig von:** US-GR-01
**Akzeptanzkriterien**
- AK1: Gegeben es gibt Gruppen, wenn ich die Übersicht öffne, dann sehe ich je aktiver Gruppe Name, Referat, die heute gültigen Trainingszeiten (z. B. „Di 16:30–18:00 · Do 17:00–18:30“), Anzahl aktiver Teilnahmen und die Anzahl offener Hinweise („Teilnahme klären“, „Kein Notfallkontakt hinterlegt.“); ohne gültige Trainingszeit steht „Keine Trainingszeit“.
- AK2: Gegeben ich wähle ein Referat oder gebe einen Namensteil ein, wenn die Liste aktualisiert wird, dann sehe ich nur passende Gruppen; aufgelöste Gruppen erscheinen nur mit dem Filter „aufgelöst“.
- AK3: Gegeben keine Gruppe passt, wenn ich filtere, dann erscheint „Keine Gruppen gefunden.“ (leerer Zustand).
- AK4: Gegeben ich habe nur „Gruppen lesen“ (z. B. Admin), wenn ich die Übersicht öffne, dann sehe ich dieselbe Liste, aber keine Schaltflächen zum Anlegen oder Ändern (Rechte-Fall).
- AK5: Die Übersicht ist ab 375 px Breite ohne horizontales Scrollen nutzbar (Tabelle wird zu Karten).
**Nicht Teil dieser Story:** Auslastung/Bedarf (Anwesenheitserfassung, Iteration 2); Export.

### US-GR-03: Gruppe anlegen und ändern
**Als** Mitarbeiter:in der Geschäftsstelle
**möchte ich** eine Gruppe mit Name und Referat anlegen und ändern,
**damit** die Gruppen aus der Excel im Vereins OS geführt werden.
**Priorität:** Must · **Regeln:** R1 · **Abhängig von:** US-GR-02
**Akzeptanzkriterien**
- AK1: Gegeben ich gebe Name und Referat an, wenn ich speichere, dann ist die Gruppe angelegt, erscheint in der Übersicht und ich kann direkt Trainingszeiten hinzufügen (US-GR-18).
- AK2: Gegeben Name oder Referat fehlt, wenn ich speichere, dann erscheint „Bitte Name und Referat angeben.“ und nichts wird gespeichert (Fehlerfall).
- AK3: Gegeben es gibt eine aktive Gruppe mit gleichem Namen (ohne Groß-/Kleinschreibung), wenn ich speichere, dann erscheint „Eine Gruppe mit diesem Namen gibt es bereits.“ (Fehlerfall, R1).
- AK4: Gegeben ich ändere Name oder Referat, wenn ich speichere, dann ist die Änderung sofort in Übersicht und Detail sichtbar.
- AK5: Gegeben ein Nutzer mit „Gruppen lesen“, wenn er eine Gruppe anlegen oder ändern will, dann lehnt die Datenbank ab (Rechte-Fall).
**Nicht Teil dieser Story:** Trainingszeiten (US-GR-18); Auflösen (US-GR-04); Pflege der Referate (Ehrenamtsmanagement); Erwachsenenbereich.

### US-GR-04: Gruppe auflösen
**Als** Mitarbeiter:in der Geschäftsstelle
**möchte ich** eine Gruppe ohne aktive Teilnehmer:innen auflösen,
**damit** sie nicht mehr in der Übersicht erscheint, ihre Historie aber erhalten bleibt.
**Priorität:** Should · **Regeln:** R9 · **Abhängig von:** US-GR-03, US-GR-11, US-GR-18
**Akzeptanzkriterien**
- AK1: Gegeben eine Gruppe ohne aktive Teilnahme, wenn ich „Gruppe auflösen“ mit Datum bestätige, dann ist „aufgelöst am“ gesetzt, die Gruppe erscheint nur noch mit dem Filter „aufgelöst“, und alle Funktionen mit Bezug auf diese Gruppe (Gruppenleitung, Trainer:in, Helfer:in) sowie alle offenen Trainingszeiten enden zum selben Datum [ANNAHME A12].
- AK2: Gegeben die Gruppe hat noch aktive Teilnahmen, wenn ich auflösen will, dann erscheint „Die Gruppe hat noch aktive Teilnehmer:innen.“ und nichts wird geändert (Fehlerfall, R9).
- AK3: Gegeben eine aufgelöste Gruppe, wenn ich sie öffne, dann sehe ich Teilnahmen, Verträge, Funktionen und Trainingszeiten nur lesend.
- AK4: Gegeben ein Nutzer mit „Gruppen lesen“, wenn er auflösen will, dann lehnt die Datenbank ab (Rechte-Fall).
**Nicht Teil dieser Story:** Wiederaufnehmen einer aufgelösten Gruppe; Löschen.

### US-GR-05: Gruppendetail mit Teilnehmerliste
**Als** Mitarbeiter:in der Geschäftsstelle
**möchte ich** in einer Gruppe alle Teilnehmer:innen mit Alter, Vertragsstatus und Hinweisen sehen,
**damit** ich erkenne, wo etwas zu tun ist.
**Priorität:** Must · **Regeln:** R7, R17, R19 · **Abhängig von:** US-GR-03, US-GR-18
**Akzeptanzkriterien**
- AK1: Gegeben eine Gruppe mit Teilnahmen, wenn ich sie öffne, dann sehe ich Kopf (Name, Referat, heute gültige Trainingszeiten, Gruppenleitung, Trainer:innen, Helfer:innen) und je aktiver Teilnahme Vorname, Nachname, Alter (aus Geburtsdatum berechnet), Eintrittsdatum, Vertragsstatus (aktiv / gekündigt zum … / beendet) und Fotoerlaubnis ja/nein.
- AK2: Gegeben das Vertragsende einer offenen Teilnahme ist erreicht, wenn ich die Gruppe öffne, dann steht an der Teilnahme „Vertrag beendet am TT.MM.JJJJ – Teilnahme klären.“; der Filter „Teilnahme klären“ zeigt nur diese Teilnahmen (R17).
- AK3: Gegeben eine aktive Teilnahme ohne Notfallkontakt, wenn ich die Gruppe öffne, dann steht an der Teilnahme „Kein Notfallkontakt hinterlegt.“ (R7).
- AK4: Gegeben die Gruppe hat keine aktive Teilnahme, wenn ich sie öffne, dann erscheint „Noch keine Teilnehmer:innen.“; beendete Teilnahmen zeigt der Filter „beendet“ (leerer Zustand).
- AK5: Gegeben ich habe „Gruppen lesen“, wenn ich die Gruppe öffne, dann sehe ich die Liste, aber keine Gesundheitsangaben und keine Bearbeiten-Schaltflächen (Rechte-Fall, R11).
**Nicht Teil dieser Story:** Anzahl Trainings und Anwesenheit (Anwesenheitserfassung).

### US-GR-06: Teilnehmer:in anlegen oder vorhandene Person wählen
**Als** Mitarbeiter:in der Geschäftsstelle
**möchte ich** beim Aufnehmen in eine Gruppe eine vorhandene Person wählen oder eine neue mit Vorname, Nachname, Geburtsdatum, Adresse und Mitgliedsnummer anlegen,
**damit** jeder Mensch nur einmal erfasst ist, auch wenn er in mehreren Gruppen oder zugleich aktiv ist.
**Priorität:** Must · **Regeln:** R2, R10 · **Abhängig von:** US-GR-05
**Akzeptanzkriterien**
- AK1: Gegeben ich gebe Vorname, Nachname, Geburtsdatum und Adresse (Straße und Hausnummer, PLZ, Ort) ein, wenn ich speichere, dann ist die Person angelegt; die Mitgliedsnummer ist optional.
- AK2: Gegeben eine ähnliche Person existiert (Dublettenprüfung der Administration), wenn ich speichere, dann erscheint die Warnung mit „Trotzdem anlegen“ / „Vorhandene Person übernehmen“ / „Abbrechen“; angezeigt werden nur Vorname, Nachname und Geburtsjahr, keine Angaben aus dem Ehrenamtsmanagement.
- AK3: Gegeben ein Pflichtfeld fehlt, wenn ich speichere, dann erscheint „Bitte Vorname, Nachname, Geburtsdatum und Adresse angeben.“ (Fehlerfall, R2).
- AK4: Gegeben die Person ist schon in einer anderen Gruppe, wenn ich sie übernehme, dann werden Stammdaten, Erziehungsberechtigte, Notfallkontakte, Fotoerlaubnis und Gesundheitsangaben nicht erneut abgefragt; ist sie bereits aktiv in dieser Gruppe, erscheint „Diese Person ist bereits in der Gruppe.“ (Fehlerfall, R10).
- AK5: Gegeben eine Teilnehmer:in unter 18 ohne erziehungsberechtigte Person, wenn ich die Person ansehe, dann erscheint der Hinweis „Bitte mindestens eine erziehungsberechtigte Person angeben.“ (R2).
- AK6: Gegeben ein Nutzer mit „Gruppen lesen“, wenn er eine Person anlegen will, dann lehnt die Datenbank ab (Rechte-Fall).
**Nicht Teil dieser Story:** Teilnahme und Vertrag (US-GR-08); Zusammenführen von Dubletten; Abgleich mit der Mitgliederverwaltung.

### US-GR-07: Erziehungsberechtigte pflegen
**Als** Mitarbeiter:in der Geschäftsstelle
**möchte ich** einer Teilnehmer:in bis zu zwei erziehungsberechtigte Personen mit Adresse, Telefon und E-Mail zuordnen,
**damit** ich weiß, wer Vertragspartner:in und Ansprechperson ist.
**Priorität:** Must · **Regeln:** R3 · **Abhängig von:** US-GR-06
**Akzeptanzkriterien**
- AK1: Gegeben eine Teilnehmer:in, wenn ich eine vorhandene Person wähle oder eine neue mit Vorname, Nachname und Adresse (Telefon und E-Mail optional) anlege, dann ist sie als erziehungsberechtigt zugeordnet.
- AK2: Gegeben Geschwister, wenn ich für das zweite Kind dieselbe erziehungsberechtigte Person wähle, dann wird sie nicht doppelt angelegt; Änderungen an Adresse oder Kontaktdaten gelten für beide Kinder.
- AK3: Gegeben bereits zwei erziehungsberechtigte Personen, wenn ich eine dritte zuordnen will, dann erscheint „Es können höchstens zwei erziehungsberechtigte Personen angegeben werden.“ (Fehlerfall, R3).
- AK4: Gegeben eine erziehungsberechtigte Person, wenn ich an der Teilnehmer:in „Adresse übernehmen“ wähle, dann wird deren Adresse in die Adresse der Teilnehmer:in kopiert; spätere Änderungen werden nicht mitgezogen.
- AK5: Gegeben ein Nutzer mit „Gruppen lesen“, wenn er eine Zuordnung ändern will, dann lehnt die Datenbank ab (Rechte-Fall).
**Nicht Teil dieser Story:** Geburtsdatum von Erziehungsberechtigten (wird nicht erfasst); Mitgliedschaft der Erziehungsberechtigten.

### US-GR-08: Vertrag erfassen und Teilnahme anlegen
**Als** Mitarbeiter:in der Geschäftsstelle
**möchte ich** eine Teilnahme an einer Gruppe nur zusammen mit dem Vertrag anlegen (Vertragsinhaber:in, Beginn, SEPA-Mandat, monatlicher Betrag),
**damit** jedes Kind in der Gruppenliste einen gültigen Vertrag hat und Finanzen später die Lastschrift daraus erzeugen kann.
**Priorität:** Must · **Regeln:** R4, R5, R6, R8, R8a, R16 · **Abhängig von:** US-GR-07
**Akzeptanzkriterien**
- AK1: Gegeben eine Teilnehmer:in mit erziehungsberechtigter Person, wenn ich Eintrittsdatum, Vertragsinhaber:in, Vertragsbeginn, Kontoinhaber:in, IBAN, Mandatsreferenz, Unterschriftsdatum, Verwendungszweck und Betrag je Monat eingebe und speichere, dann entstehen Teilnahme und Vertrag gemeinsam; der Vertrag hat den Status „aktiv“.
- AK2: Gegeben die IBAN-Prüfsumme ist ungültig oder die Mandatsreferenz ist schon vergeben, wenn ich speichere, dann erscheint „Die IBAN ist ungültig.“ bzw. „Diese Mandatsreferenz ist bereits vergeben.“ und weder Teilnahme noch Vertrag werden gespeichert (Fehlerfall, R5, R6, R16).
- AK3: Gegeben die gewählte Vertragsinhaber:in ist nicht erziehungsberechtigt für diese Teilnehmer:in (und die Teilnehmer:in ist minderjährig), wenn ich speichere, dann erscheint „Vertragsinhaber:in muss eine erziehungsberechtigte Person sein.“ (Fehlerfall, R4).
- AK4: Gegeben die Teilnehmer:in ist bereits in Gruppe A, wenn ich sie in Gruppe B aufnehme, dann entstehen eine zweite Teilnahme und ein zweiter, eigener Vertrag; der Vertrag in Gruppe A bleibt unverändert.
- AK5: Gegeben jemand versucht per Datenbankaufruf eine Teilnahme ohne Vertrag oder einen zweiten Vertrag für dieselbe Teilnahme anzulegen, dann lehnt die Datenbank ab mit „Eine Teilnahme kann nur mit einem aktiven Vertrag angelegt werden.“ bzw. „Für diese Teilnahme gibt es bereits einen Vertrag.“ (Fehlerfall, R16, R8a).
- AK6: Gegeben ein Nutzer mit „Gruppen lesen“, wenn er den Vertrag ansieht, dann sieht er alle Vertragsangaben inklusive IBAN, kann aber nichts ändern (Rechte-Fall).
**Nicht Teil dieser Story:** Vertragsübersicht, Buchungslauf, SEPA-Datei (Modul Finanzen); Kündigung (US-GR-11); Erzeugen der Mandatsreferenz (wird manuell eingegeben).

### US-GR-09: Notfallkontakte pflegen
**Als** Mitarbeiter:in der Geschäftsstelle
**möchte ich** je Teilnehmer:in mehrere Notfallkontakte mit Name und Telefon oder E-Mail in einer Reihenfolge erfassen,
**damit** im Notfall klar ist, wen man zuerst erreicht.
**Priorität:** Must · **Regeln:** R7 · **Abhängig von:** US-GR-06
**Akzeptanzkriterien**
- AK1: Gegeben eine Teilnehmer:in, wenn ich eine erziehungsberechtigte Person als Notfallkontakt markiere, dann erscheint sie mit ihren Kontaktdaten in der Liste der Notfallkontakte.
- AK2: Gegeben ich lege einen weiteren Notfallkontakt mit Vorname, Nachname und Telefon oder E-Mail an, wenn ich speichere, dann steht er in der Liste; die Reihenfolge kann ich ändern.
- AK3: Gegeben weder Telefon noch E-Mail sind angegeben, wenn ich speichere, dann erscheint „Bitte Telefon oder E-Mail angeben.“ (Fehlerfall, R7).
- AK4: Gegeben ich entferne den letzten Notfallkontakt einer aktiven Teilnahme, wenn ich speichere, dann ist es erlaubt, aber Gruppe und Teilnehmer:in zeigen „Kein Notfallkontakt hinterlegt.“ (R7).
- AK5: Gegeben ein Nutzer mit „Gruppen lesen“, wenn er Notfallkontakte ändern will, dann lehnt die Datenbank ab (Rechte-Fall).
**Nicht Teil dieser Story:** Beziehung zum Kind (z. B. Oma); Benachrichtigung aus dem System.

### US-GR-10: Fotoerlaubnis pflegen
**Als** Mitarbeiter:in der Geschäftsstelle
**möchte ich** je Teilnehmer:in die Fotoerlaubnis ja/nein mit Datum pflegen,
**damit** vor einer Veröffentlichung klar ist, ob ein Foto des Kindes verwendet werden darf.
**Priorität:** Must · **Regeln:** R12 · **Abhängig von:** US-GR-06
**Akzeptanzkriterien**
- AK1: Gegeben eine neu angelegte Teilnehmer:in, wenn ich sie ansehe, dann ist die Fotoerlaubnis „nein“.
- AK2: Gegeben ich setze die Fotoerlaubnis auf „ja“ mit Datum, wenn ich speichere, dann sind Wert, Datum und ändernde Person gespeichert; frühere Werte bleiben in der Historie sichtbar (Widerruf nachvollziehbar).
- AK3: Gegeben kein Datum ist angegeben, wenn ich „ja“ speichere, dann erscheint „Bitte das Datum der Erlaubnis angeben.“ (Fehlerfall).
- AK4: Gegeben ein Nutzer mit „Gruppen lesen“, wenn er die Fotoerlaubnis sieht, dann kann er sie nicht ändern (Rechte-Fall).
**Nicht Teil dieser Story:** abgestufte Erlaubnis; Nutzung in der Öffentlichkeitsarbeit.

### US-GR-11: Vertrag kündigen und Teilnahme beenden
**Als** Mitarbeiter:in der Geschäftsstelle
**möchte ich** eine Kündigung mit Eingangsdatum und Vertragsende erfassen und die Teilnahme an der Gruppe unabhängig davon beenden,
**damit** Finanzen den Einzug stoppen kann und die Gruppenliste stimmt, ohne andere Gruppen zu berühren.
**Priorität:** Must · **Regeln:** R8, R8b, R17 · **Abhängig von:** US-GR-08
**Akzeptanzkriterien**
- AK1: Gegeben ein aktiver Vertrag, wenn ich Kündigungsdatum und Vertragsende eingebe, dann ist der Status „gekündigt zum TT.MM.JJJJ“ und nach Erreichen des Vertragsendes „beendet“.
- AK2: Gegeben ich speichere ein Vertragsende, wenn die Rückfrage „Endet auch die Teilnahme an der Gruppe?“ erscheint, dann setzt „Ja“ „Teilnahme bis“ auf dasselbe Datum und „Nein“ lässt die Teilnahme offen (R8b).
- AK3: Gegeben die Teilnehmer:in ist auch in Gruppe B, wenn ich den Vertrag in Gruppe A kündige, dann bleiben Teilnahme und Vertrag in Gruppe B unverändert.
- AK4: Gegeben Vertragsende vor Vertragsbeginn oder „Teilnahme bis“ vor Eintrittsdatum, wenn ich speichere, dann erscheint „Das Vertragsende darf nicht vor dem Vertragsbeginn liegen.“ bzw. „‚Teilnahme bis‘ darf nicht vor dem Eintrittsdatum liegen.“ (Fehlerfall, R8).
- AK5: Gegeben ein Vertrag ist beendet und die Teilnahme offen, wenn ich einen neuen Vertrag zur Teilnahme anlegen will, dann ist das möglich und der Hinweis „Teilnahme klären“ verschwindet; der Folgevertrag ersetzt den beendeten als aktiven Vertrag der Teilnahme, der alte bleibt sichtbar.
- AK6: Gegeben ein Nutzer mit „Gruppen lesen“, wenn er kündigen will, dann lehnt die Datenbank ab (Rechte-Fall).
**Nicht Teil dieser Story:** Fristenberechnung für Kündigungen; Austritt aus der Sektion (Mitgliederverwaltung); Buchungslauf.

### US-GR-12: Gesundheitsangaben pflegen
**Als** Mitarbeiter:in der Geschäftsstelle
**möchte ich** gesundheitliche Einschränkungen einer Teilnehmer:in erfassen und lesen,
**damit** sie bei Training und Ausfahrten berücksichtigt werden können.
**Priorität:** Must · **Regeln:** R11 · **Abhängig von:** US-GR-06
**Akzeptanzkriterien**
- AK1: Gegeben ich habe „Gruppen bearbeiten“ oder „verwalten“, wenn ich an der Teilnehmer:in Text zu gesundheitlichen Einschränkungen eingebe und speichere, dann ist er gespeichert und an der Teilnehmer:in sichtbar.
- AK2: Gegeben ich habe nur „Gruppen lesen“ (z. B. Admin), wenn ich die Teilnehmer:in öffne oder die Tabelle per Datenbankabfrage lese, dann erhalte ich keine Gesundheitsangaben; die Oberfläche zeigt den Abschnitt nicht (Rechte-Fall, R11).
- AK3: Gegeben ein Nutzer mit Rechten nur auf das Ehrenamtsmanagement, die Anwesenheitserfassung oder die Administration, wenn er Gesundheitsangaben abfragt, dann erhält er keine Daten (Rechte-Fall).
- AK4: Beim Erfassen erscheint der Hinweis „Nur erfassen, wenn eine schriftliche Einwilligung der Erziehungsberechtigten vorliegt. Nur Angaben, die für Training und Ausfahrten nötig sind.“
- AK5: Gesundheitsangaben erscheinen nicht in der E-Mail-Liste, nicht in der Anwesenheitsliste (US-GR-19), in keinem Export und nicht in E-Mails (Fehlerfall-Absicherung).
**Nicht Teil dieser Story:** Lesen durch Gruppenleitung und Trainer:innen der eigenen Gruppe (nach MVP mit Zugang und Reichweite „Gruppe“); Erfassung der Einwilligung als eigenes Feld [OFFEN].

### US-GR-13: Gruppenleitung, Trainer:innen und Helfer:innen festlegen
**Als** Mitarbeiter:in der Geschäftsstelle
**möchte ich** in einer Gruppe Personen als Gruppenleitung, Trainer:in oder Helfer:in mit Gültigkeit festlegen,
**damit** klar ist, wer die Gruppe betreut, und das Ehrenamtsmanagement diese Personen als Aktive zeigt.
**Priorität:** Must · **Regeln:** R14 · **Abhängig von:** US-GR-03
**Akzeptanzkriterien**
- AK1: Gegeben eine Gruppe, wenn ich eine Person wähle (oder anlege), Funktion (Gruppenleitung / Trainer:in / Helfer:in) und gültig von angebe und speichere, dann steht sie im Kopf der Gruppe; mehrere Personen je Funktion sind möglich.
- AK2: Gegeben ich setze gültig bis, wenn das Datum erreicht ist, dann erscheint die Person nicht mehr im Kopf der Gruppe; die frühere Zuordnung bleibt in der Historie und wird für Einsätze vor diesem Datum weiter in der Anwesenheitsliste geliefert (US-GR-19).
- AK3: Gegeben eine Funktion mit Bezug auf die Gruppe, wenn ein Nutzer mit Rechten auf das Ehrenamtsmanagement die Person öffnet, dann sieht er die Funktion mit Gruppenname, kann sie dort aber nicht ändern: „Diese Funktion wird im Modul Gruppen gepflegt.“ (R14).
- AK4: Gegeben gültig bis liegt vor gültig von, wenn ich speichere, dann erscheint „‚Gültig bis‘ darf nicht vor ‚gültig von‘ liegen.“ (Fehlerfall).
- AK5: Gegeben ein Nutzer mit „Gruppen lesen“, wenn er eine Funktion festlegen will, dann lehnt die Datenbank ab (Rechte-Fall).
**Nicht Teil dieser Story:** Prüfung von Lizenz oder Führungszeugnis-Einsicht (Ehrenamtsmanagement); Rechte für Gruppenleitungen (R7 der Administration: Funktionen bringen keine Rechte); Abrechnung.

### US-GR-14: Notfallkontakte unterwegs finden
**Als** Nutzer mit „Gruppen lesen“ (z. B. Admin im Notfall)
**möchte ich** auf dem Telefon in höchstens zwei Schritten von der Gruppe zu den Notfallkontakten eines Kindes kommen und direkt anrufen,
**damit** ich bei einem Unfall schnell handeln kann.
**Priorität:** Must · **Regeln:** R7, R11 · **Abhängig von:** US-GR-09
**Akzeptanzkriterien**
- AK1: Gegeben ich bin in einer Gruppe, wenn ich ein Kind antippe, dann sehe ich seine Notfallkontakte in der festgelegten Reihenfolge mit Telefonnummer als Anruf-Link (`tel:`) und E-Mail als `mailto:`-Link.
- AK2: Die Ansicht ist ab 375 px Breite ohne horizontales Scrollen nutzbar; Telefonnummern sind ohne Zoomen antippbar.
- AK3: Gegeben das Kind hat keinen Notfallkontakt, wenn ich die Ansicht öffne, dann erscheint „Kein Notfallkontakt hinterlegt.“ und darunter die Erziehungsberechtigten mit Kontaktdaten (Fehlerfall).
- AK4: Gegeben ich habe nur „Gruppen lesen“, wenn ich die Ansicht öffne, dann sehe ich keine Gesundheitsangaben (Rechte-Fall, R11).
**Nicht Teil dieser Story:** Offline-Nutzung (nicht im MVP); Ausfahrten und deren Freigabe; Notfallkontakte in der Anwesenheitserfassung.

### US-GR-15: E-Mail-Adressen einer Gruppe kopieren
**Als** Nutzer mit mindestens „Gruppen lesen“
**möchte ich** die E-Mail-Adressen der Erziehungsberechtigten einer Gruppe auf Knopfdruck kopieren,
**damit** ich eine Nachricht aus meinem eigenen Postfach verschicken kann.
**Priorität:** Should · **Regeln:** R13 · **Abhängig von:** US-GR-07
**Akzeptanzkriterien**
- AK1: Gegeben eine Gruppe mit aktiven Teilnahmen, wenn ich „E-Mail-Adressen kopieren“ wähle, dann liegen die E-Mail-Adressen der Erziehungsberechtigten aller aktiven Teilnahmen ohne Dubletten, getrennt durch Semikolon, in der Zwischenablage; bei volljährigen Teilnehmer:innen deren eigene Adresse.
- AK2: Nach dem Kopieren erscheint „N Adressen kopiert. Bitte in Blindkopie (BCC) einfügen.“
- AK3: Gegeben keine erziehungsberechtigte Person hat eine E-Mail-Adresse, wenn ich kopiere, dann erscheint „Keine E-Mail-Adressen vorhanden.“ (Fehlerfall).
- AK4: Gegeben ein Nutzer ohne Rechte auf Gruppen, wenn er die Funktion aufruft, dann erhält er keine Adressen (Rechte-Fall).
**Nicht Teil dieser Story:** Versand aus dem Vereins OS; Adressen von Notfallkontakten.

### US-GR-16: Import der Bestands-Excel
**Als** Admin (Product Owner)
**möchte ich** die Bestands-Excel einmalig per Skript übernehmen, mit Probelauf und Prüfbericht vorab,
**damit** die Excel abgelöst wird, ohne Daten von Hand abzutippen.
**Priorität:** Must · **Regeln:** R2, R3, R5, R6, R7, R16, R18 · **Abhängig von:** US-GR-08, US-GR-09, US-GR-10, US-GR-12, US-GR-18
**Akzeptanzkriterien**
- AK1: Gegeben eine Excel mit einem Tabellenblatt je Gruppe (Kopf: Gruppenname, Trainingszeit als Text; Spalten wie in 01-erhebung.md C), wenn ich den Probelauf starte, dann wird nichts geschrieben und ein Prüfbericht nennt je Blatt und Zeile: fehlende Pflichtfelder, Zeilen ohne Vertragsdaten (R16), ungültige IBAN, doppelte Mandatsreferenz, nicht teilbare Namen der Erziehungsberechtigten, nicht zuordenbare Notfallkontakt-Zellen (L–O), nicht eindeutig lesbare Trainingszeiten und Dublettenverdacht über alle Blätter.
- AK2: Gegeben der Probelauf ist fehlerfrei, wenn ich den Lauf starte, dann entstehen je Blatt eine Gruppe (Referat aus dem Kopf zugeordnet) mit ihren Trainingszeiten, je Zeile Person, Erziehungsberechtigte:r, Notfallkontakte, Fotoerlaubnis, Gesundheitsangaben, Teilnahme (Eintrittsdatum = Vertragsbeginn) und Vertrag; ein Kind in zwei Blättern wird eine Person mit zwei Teilnahmen und zwei Verträgen; die Adresse des Kindes wird von der erziehungsberechtigten Person übernommen.
- AK3: Gegeben die Trainingszeit im Kopf ist lesbar (z. B. „Mi 18–20 Uhr“ oder „Di + Do 16:30–18:00“), wenn der Lauf sie überführt, dann entsteht je Wochentag eine Trainingszeit mit Beginn, Ende und „gültig von“ = Importdatum [ANNAHME A11]; nicht lesbare Angaben führen nicht zum Abbruch, sondern die Gruppe wird ohne Trainingszeit angelegt und im Bericht zur Nacharbeit durch die Geschäftsstelle (US-GR-18) aufgeführt.
- AK4: Gegeben der Lauf bricht bei einer Zeile ab, wenn das passiert, dann wird nichts aus diesem Lauf gespeichert (alles oder nichts) und der Bericht nennt die Zeile (Fehlerfall).
- AK5: Gegeben das Skript wird gegen ein anderes Projekt als das konfigurierte Ziel gestartet oder die Datei liegt im Repository, dann bricht es ab (Fehlerfall); Entwicklung und Test nur mit fiktiver Datei in TEST.
- AK6: Gegeben das Skript, wenn es ausgeführt wird, dann nur lokal durch den Admin mit technischem Vollzugriff; die Geschäftsstelle kann es nicht auslösen (Rechte-Fall).
- AK7: Der Prüfbericht enthält keine Gesundheitsangaben und keine vollständigen IBANs (nur letzte 4 Stellen).
**Nicht Teil dieser Story:** Importfunktion in der Oberfläche; Spalten „Bedarf“ und „IBAN Korrekt“; Zuordnung von Gruppenleitung, Trainer:innen und Helfer:innen (Nacharbeit über US-GR-13); frühere Trainingszeiten vor dem Import.

### US-GR-17: Testdaten in TEST
**Als** Admin
**möchte ich** in TEST fiktive Gruppen mit typischen Sonderfällen haben,
**damit** ich und die Geschäftsstelle alle Stories ohne Echtdaten abnehmen können.
**Priorität:** Must · **Regeln:** R11, R16, R17, R19, R20 · **Abhängig von:** US-GR-01
**Akzeptanzkriterien**
- AK1: Gegeben `supabase/seed.sh` läuft gegen TEST oder den lokalen Stack, wenn es fertig ist, dann gibt es mindestens zwei Gruppen in zwei Referaten mit fiktiven Teilnehmer:innen, darunter: ein Kind in zwei Gruppen (zwei Verträge), Geschwister mit gemeinsamer erziehungsberechtigter Person, eine erziehungsberechtigte Person, die zugleich Trainer:in ist, eine Jugendliche ab 16, die zugleich Helfer:in ist, ein Vertrag „beendet“ bei offener Teilnahme, ein Kind ohne Notfallkontakt, ein Kind mit Gesundheitsangabe.
- AK2: Trainingszeiten im Seed: eine Gruppe mit zwei Trainingstagen, eine Gruppe mit geänderter Trainingszeit (alte mit „gültig bis“, neue mit „gültig von“), eine Gruppe ohne Trainingszeit; eine Teilnahme mit „Teilnahme bis“ in der Vergangenheit und eine beendete Trainer:innen-Funktion (für Stichtagstests von US-GR-19).
- AK3: IBANs im Seed sind gültige Test-IBANs ohne Bezug zu echten Konten; alle Namen, Adressen und Telefonnummern sind fiktiv.
- AK4: Gegeben der Testzugang Admin („Gruppen lesen“), wenn er das Kind mit Gesundheitsangabe öffnet, dann sieht er sie nicht; der Testzugang Geschäftsstelle sieht sie (Rechte-Fall).
- AK5: Gegeben der Testzugang Referent:in Kinder und Jugend aus der Administration (Anwesenheitserfassung „bearbeiten“, Reichweite Referat), wenn er `gr_group_roster` für eine Gruppe seines Referats bzw. eines anderen Referats aufruft, dann erhält er die Namen bzw. `GR_ROSTER_FORBIDDEN` (Rechte-Fall).
- AK6: Gegeben jemand startet den Seed gegen PROD, dann bricht er mit „Seed in PROD nicht erlaubt.“ ab (Fehlerfall).
**Nicht Teil dieser Story:** Testzugänge für Gruppenleitung und Trainer:innen (nach MVP).

### US-GR-18: Trainingszeiten pflegen
**Als** Mitarbeiter:in der Geschäftsstelle
**möchte ich** je Gruppe eine oder mehrere Trainingszeiten mit Wochentag, Beginn, Ende und Gültigkeit pflegen,
**damit** die Anwesenheitserfassung beim Erfassen eines Trainings Datum und Uhrzeit vorschlagen kann und frühere Zeiten nachvollziehbar bleiben.
**Priorität:** Must · **Regeln:** R18, R19 · **Abhängig von:** US-GR-03
**Akzeptanzkriterien**
- AK1: Gegeben eine Gruppe, wenn ich Wochentag, Beginn, Ende und „gültig von“ angebe und speichere, dann ist die Trainingszeit angelegt und erscheint, sobald „gültig von“ erreicht ist, in Übersicht und Gruppenkopf (z. B. „Mi 18:00–20:00“); mehrere Trainingszeiten je Gruppe sind möglich.
- AK2: Gegeben eine bestehende Trainingszeit, wenn ich „Ändern ab“ mit Datum und neuen Werten speichere, dann setzt das System an der alten Trainingszeit „gültig bis“ auf den Vortag und legt eine neue mit „gültig von“ = Datum an; die alte erscheint unter „Frühere Trainingszeiten“ (R19).
- AK3: Gegeben eine Trainingszeit, wenn ich „Beenden“ mit Datum wähle, dann ist „gültig bis“ gesetzt; ab dem Folgetag erscheint sie nicht mehr als gültig.
- AK4: Gegeben Ende liegt nicht nach Beginn, „gültig bis“ liegt vor „gültig von“ oder ein Pflichtfeld fehlt, wenn ich speichere, dann erscheint „Das Ende muss nach dem Beginn liegen.“, „‚Gültig bis‘ darf nicht vor ‚gültig von‘ liegen.“ bzw. „Bitte Wochentag, Beginn, Ende und ‚gültig von‘ angeben.“ und nichts wird gespeichert (Fehlerfall, R18).
- AK5: Gegeben eine gültige Trainingszeit derselben Gruppe am selben Wochentag überschneidet sich zeitlich, wenn ich speichere, dann erscheint „Diese Trainingszeit überschneidet sich mit einer anderen.“; Speichern bleibt möglich (R19).
- AK6: Gegeben ein Nutzer mit „Gruppen lesen“, wenn er Trainingszeiten anlegen, ändern oder beenden will, dann lehnt die Datenbank ab (Rechte-Fall); Wochentag, Beginn und Ende einer bestehenden Trainingszeit lassen sich auch per Datenbankaufruf nicht überschreiben, nur „gültig bis“ setzen (A13, bestätigt 22.10.2026).
- AK7: Die Pflege ist ab 375 px Breite nutzbar; Wochentag als Auswahl, Uhrzeiten als Zeitfelder.
**Nicht Teil dieser Story:** Ausfallzeiten (Ferien, Hallenschließung) – werden nicht gepflegt; Ort der Trainingszeit (Stammdaten Orte der Administration, in der Anwesenheitserfassung gewählt); automatisches Erzeugen von Trainings (Anwesenheitserfassung erzeugt nichts vorab); eigene Korrekturfunktion für Trainingszeiten (A13).

### US-GR-19: Anwesenheitsliste für die Anwesenheitserfassung
**Als** Referent:in mit Rechten auf die Anwesenheitserfassung
**möchte ich** beim Erfassen eines Trainings die Namen der Teilnehmer:innen, Gruppenleitung, Trainer:innen und Helfer:innen der Gruppe, gültig am Datum des Trainings, vorgeschlagen bekommen,
**damit** ich nur Anwesenheit abhaken muss und keine Kinderdaten außerhalb von Gruppen sichtbar werden.
**Priorität:** Must · **Regeln:** R20 · **Abhängig von:** US-GR-08, US-GR-13, US-GR-18; Administration v0.8 (Modul Anwesenheitserfassung in `ad_modules`, Reichweite Referat für EZ, `ad_my_referate('EZ', …)`)
**Akzeptanzkriterien**
- AK1: Gegeben eine Gruppe meines Referats, wenn die Anwesenheitserfassung `gr_group_roster(group_id, date)` aufruft, dann erhält sie Gruppenname, Referat, die am Datum gültigen Trainingszeiten für dessen Wochentag sowie je Person mit am Datum gültiger Teilnahme oder Funktion: Person-ID, Vorname, Rufname, Nachname und Rolle (`participant`, `group_lead`, `trainer`, `helper`).
- AK2: Gegeben eine Person war am Datum Teilnehmer:in und ist heute ausgetreten bzw. eine Trainer:innen-Funktion begann erst nach dem Datum, wenn die Funktion für das Datum aufgerufen wird, dann ist die erste Person enthalten und die zweite nicht (Stichtag, R20; vom Product Owner für Teilnehmer:innen und Trainer:innen bestätigt 22.10.2026).
- AK3: Gegeben eine Person ist Teilnehmer:in und zugleich Helfer:in derselben Gruppe, wenn die Liste geliefert wird, dann erscheint sie je Rolle einmal; die Anwesenheitserfassung entscheidet über die Darstellung.
- AK4: Die Rückgabe enthält nie Geburtsdatum, Alter, Adresse, Kontaktdaten, Erziehungsberechtigte, Notfallkontakte, Verträge, Bankdaten, Gesundheitsangaben oder Fotoerlaubnis; ein pgTAP-Test prüft die Spaltenliste (R20).
- AK5: Gegeben ein Nutzer mit „Gruppen lesen“, „Anwesenheitserfassung lesen“ (z. B. Admin) oder Reichweite Referat auf das Referat der Gruppe, wenn er die Funktion aufruft, dann erhält er die Liste; gegeben eine Referent:in eines anderen Referats oder ein Nutzer ohne diese Rechte, dann Fehler „Für diesen Bereich hast du keine Rechte.“ (Code `GR_ROSTER_FORBIDDEN`) (Rechte-Fall).
- AK6: Gegeben die Gruppe hat am Datum keine gültige Teilnahme, Funktion oder Trainingszeit, wenn die Funktion aufgerufen wird, dann liefert sie die Gruppe mit leeren Listen, keinen Fehler (leerer Zustand); gegeben die Gruppe existiert nicht oder war am Datum bereits aufgelöst, dann Fehler „Gruppe nicht gefunden.“ (Fehlerfall) [ANNAHME].
- AK7: Die Funktion schreibt nichts und ändert keine Rechte auf `gr_`-Tabellen (Security Definer mit eigener Rechteprüfung; direkter Tabellenzugriff bleibt nach US-GR-01 gesperrt).
- AK8: Gegeben ein Nutzer mit denselben Rechten wie in AK5, wenn die Anwesenheitserfassung `gr_groups_for_attendance(p_date)` aufruft, dann erhält sie alle am Datum nicht aufgelösten Gruppen, für deren Referat der Nutzer liest (Reichweite alle: alle Gruppen; Reichweite Referat: Gruppen seiner Referate), je Gruppe nur Gruppen-ID, Name und Referat (`referat_id`, Referatsname), sortiert nach Name; ohne Rechte eine leere Liste. Keine Personendaten (Rechte-Fall, R20).
**Nicht Teil dieser Story:** Oberfläche der Anwesenheitserfassung; Speichern der Anwesenheit (Anwesenheitserfassung); Alter für den Betreuungsschlüssel (Anwesenheitserfassung, Iteration 2: nur berechnetes Ergebnis, nie Geburtsdatum); Reichweite „Gruppe“ für Gruppenleitungen (nach MVP).

### US-GR-20: Eigene Gruppen für den Vorschlag in der Anwesenheitserfassung
**Als** Trainer:in (im MVP mit Zugang als Referent:in, ab Iteration 1 auch Gruppenleitung und Trainer:innen mit eigenem Zugang)
**möchte ich**, dass die Anwesenheitserfassung weiß, in welchen Gruppen ich am Datum des Einsatzes Gruppenleitung, Trainer:in oder Helfer:in bin,
**damit** sie mir meine Gruppe beim Erfassen vorschlagen kann.
**Priorität:** Must · **Regeln:** R20 (sinngemäß) · **Abhängig von:** US-GR-13, US-GR-18; Administration (`ad_me()` für die eigene Person)
**Akzeptanzkriterien**
- AK1: Gegeben ich bin angemeldet und am 13.10.2026 Trainer:in von „Gruppe 1“ und Helfer:in von „Gruppe 3“, wenn die Anwesenheitserfassung `gr_my_groups('2026-10-13')` aufruft, dann erhält sie je Gruppe: Gruppen-ID, Gruppenname, Referat, meine Funktion (`group_lead`, `trainer`, `helper`) und die Wochentage der am Datum gültigen Trainingszeiten.
- AK2: Gegeben meine Funktion beginnt nach dem Datum oder endete davor oder die Gruppe war am Datum aufgelöst, dann ist die Gruppe nicht enthalten (Stichtag wie R20).
- AK3: Gegeben ich habe keine Funktion in einer Gruppe oder mein Zugang ist nicht „aktiv“, dann liefert die Funktion eine leere Liste, keinen Fehler (leerer Zustand).
- AK4 (Rechte): Die Funktion liefert nur Gruppen der Person des angemeldeten Nutzers (über `ad_me()`); eine andere Person kann nicht abgefragt werden (kein Parameter Person). Sie braucht kein Recht auf Gruppen und gibt keine Namen anderer Personen, keine Teilnehmer:innen und keine Daten aus `gr_`-Tabellen außer Gruppenname, Referat, eigener Funktion und Wochentagen zurück.
- AK5: Die Rückgabe gibt kein Recht zum Erfassen; welche Gruppen erfasst werden dürfen, prüft die Anwesenheitserfassung über ihre Rechte (Reichweite Referat, ab Iteration 1 Gruppe).
- AK6: Ein pgTAP-Test prüft Spaltenliste, Stichtag und dass nur eigene Funktionen geliefert werden.
**Nicht Teil dieser Story:** Oberfläche der Anwesenheitserfassung (US-EZ-19); Reichweite „Gruppe“ (Iteration 1, Administration).

---

## Annahmen

Bestätigt vom Product Owner am 21.10.2026:

| Nr | Annahme | Story |
|---|---|---|
| A1 | Admin erhält „Gruppen lesen“ als Startwert. | US-GR-01 |
| A2 | Dublettenwarnung zeigt nur Vorname, Nachname, Geburtsjahr; keine Daten aus dem Ehrenamtsmanagement. | US-GR-06 |
| A3 | „Adresse übernehmen“ kopiert einmalig, ohne Verknüpfung. | US-GR-07 |
| A4 | Mandatsreferenz wird manuell eingegeben, nicht erzeugt. | US-GR-08 |
| A5 | Fotoerlaubnis „ja“ braucht ein Datum. | US-GR-10 |
| A6 | Rückfrage „Endet auch die Teilnahme an der Gruppe?“ beim Vertragsende. | US-GR-11 |
| A7 | Folgevertrag zu einer offenen Teilnahme möglich; der beendete Vertrag bleibt sichtbar. Präzisiert R8a: höchstens ein **aktiver** Vertrag je Teilnahme. | US-GR-11 |
| A8 | Keine Offline-Nutzung im MVP. | US-GR-14 |
| A9 | E-Mail-Liste enthält bei volljährigen Teilnehmer:innen deren eigene Adresse. | US-GR-15 |
| A10 | Import: Eintrittsdatum = Vertragsbeginn; Prüfbericht ohne Gesundheitsangaben und nur mit letzten 4 IBAN-Stellen. | US-GR-16 |

Bestätigt vom Product Owner am 22.10.2026:

| Nr | Annahme | Story |
|---|---|---|
| A13 | Wochentag, Beginn und Ende einer Trainingszeit sind nach dem Speichern nicht änderbar (nur „Ändern ab“ oder „Beenden“); keine eigene Korrekturfunktion. Die Geschäftsstelle pflegt Trainingszeiten fest in Gruppen. | US-GR-18 |
| – | Stichtag: Die Anwesenheitsliste liefert Teilnehmer:innen und Trainer:innen, Helfer:innen, Gruppenleitung, die am Datum des Einsatzes in der Gruppe waren. | US-GR-19 |

Neu in v0.4, **noch zu bestätigen**:

| Nr | Annahme | Story |
|---|---|---|
| A11 | Import: „gültig von“ der Trainingszeiten = Importdatum; nicht lesbare Trainingszeiten brechen den Import nicht ab. | US-GR-16 |
| A12 | Auflösen einer Gruppe beendet ihre offenen Trainingszeiten zum Auflösungsdatum. | US-GR-04 |
| – | Fehler „Gruppe nicht gefunden.“ bei unbekannter oder am Datum aufgelöster Gruppe. | US-GR-19 |

## Prüfung Definition of Ready (Stand 22.10.2026)

| Kriterium | Status |
|---|---|
| Rechtevorlage, Ziel und Nutzen benannt | erfüllt |
| Akzeptanzkriterien testbar (Given-When-Then) | erfüllt |
| Fehlerfall und Rechte-Fall je Story | erfüllt |
| Begriffe im Glossar | erfüllt (Referat, Trainingszeit, Teilnahme, Anwesenheit in glossar.md v1.6) |
| Datenfelder im Datenmodell der Spec | offen – spec.md Gruppen noch nicht erstellt |
| Regeln per ID referenziert | erfüllt (R1–R20) |
| Keine [OFFEN]-Punkte, Annahmen sichtbar | A1–A10 und A13 bestätigt; **offen:** A11, A12, „Gruppe nicht gefunden.“, Einwilligung als eigenes Feld (US-GR-12) |
| „Nicht Teil dieser Story“ ausgefüllt | erfüllt |

Blocker außerhalb dieses Moduls: Nachtrag RLS in der Administration (US-GR-01), Referate aus dem Ehrenamtsmanagement (US-GR-03), Modul Anwesenheitserfassung und Reichweite Referat in der Administration v0.8 (US-GR-19), `ad_me()` mit Person-ID (US-GR-20, vorhanden).
