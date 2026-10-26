# Stories: Finanzen

Stand: 26.10.2026 · Version 0.2.1 · Kürzel: FI · Status: Entwurf
Quellen: 00-steckbrief.md (v0.5, abgeschlossen), 01-erhebung.md (v0.5, Regeln R1–R30), rollen.md (v1.2), glossar.md (v1.6; Vorschläge im Steckbrief), Übergaben an Administration (v1.3, A1–A10), Anwesenheitserfassung (v1.2, Z1–Z5), Planungshilfe (v1.0)
Umfang: MVP – halbjährliche Abrechnung (Kinder und Jugend, Leistungssport), Bestätigung durch Referent:innen, Abschluss mit Abrechnungsdokument, Abgabe, Auszahlungsrunde mit Auszahlliste (PDF) und Überweisungsdatei (XML), Abgleich Punktekonto Kletterhalle. Iteration 1 (Kurs, Tour, Einzelabrechnung, Reisekosten, Storno einer Runde) nicht enthalten.
Änderungen v0.2.1: Nach der Vorlage der Sparkasse: Fälligkeitstag = Erstellen + 3 Tage, Verwendungszweck nach Vorlage, Zusatzbetrag (AK in US-FI-18, R47).
Änderungen v0.2: Nachtrag Buchungslauf Verträge (01-erhebung.md v0.7, Abschnitt H, R34–R46): US-FI-18 bis US-FI-21 (Entwurf; offene Punkte R41, R44 und die Vorlage der Sparkasse vor der Spec).
Änderungen v0.1: Erster Entwurf; Sichtbarkeit für Referent:innen (ganze Abrechnung), Abgabe nach der Frist mit Begründung und Verfall von Hand bestätigt (Product Owner 26.10.2026).

Beispiele sind fiktiv (Personen, Gruppen, Beträge); IBAN nur `DE89370400440532013000`.

## Zusätzliche Regeln (Ergänzung zu 01-erhebung.md, Abschnitt D)

- **R31 – Sichtbarkeit Referent:in:** Eine Referent:in sieht Abrechnungen mit mindestens einer Position ihrer Referate, und zwar die **ganze Abrechnung** (alle Positionen, auch anderer Referate, Summen und Hinweise) (Product Owner 26.10.2026); bestätigen kann sie nur die Positionen ihrer Referate. Keine Bankverbindung, keine Daten der Nachweise und Lizenzen, keine Auszahlungsrunden. Andere Abrechnungen erscheinen weder in Listen noch per direktem Aufruf.
- **R32 – Nur lesen außerhalb der Rechte:** Nutzer ohne „FI verwalten“ sehen keine Schaltflächen zum Berechnen, Korrigieren, Abschließen, Erfassen der Abgabe und für Auszahlungsrunden; Schreibversuche lehnt die Datenbank ab.
- **R33 – Verlauf:** Bestätigen, Zurücknehmen einer Bestätigung, Korrektur, Abschluss, Rücknahme, Abgabe, Verfall und Auszahlung werden je Abrechnung mit „wer, wann“ gespeichert und angezeigt [ANNAHME].

## Übersicht

| ID | Titel | Priorität | Rechtevorlage |
|---|---|---|---|
| US-FI-01 | Halbjahresabrechnung berechnen | Must | Geschäftsstelle |
| US-FI-02 | Trainingseinheiten berechnen | Must | Geschäftsstelle |
| US-FI-03 | Tages-, Halbtages- und Tagessätze der Wettkampfbetreuung berechnen | Must | Geschäftsstelle |
| US-FI-04 | Satz Trainer:in nach förderfähiger Lizenz | Must | Geschäftsstelle |
| US-FI-05 | Hinweise zu Voraussetzungen und Höchstbetrag | Must | Geschäftsstelle, Referent:in |
| US-FI-06 | Abrechnungen auflisten und ansehen | Must | Geschäftsstelle, Referent:in |
| US-FI-07 | Position korrigieren | Must | Geschäftsstelle |
| US-FI-08 | Abrechnung bestätigen („sachlich richtig“) | Must | Referent:in |
| US-FI-09 | Bestätigen in Vertretung | Should | Geschäftsstelle |
| US-FI-10 | Abrechnung abschließen und Abrechnungsdokument drucken | Must | Geschäftsstelle |
| US-FI-11 | Abschluss zurücknehmen | Should | Geschäftsstelle |
| US-FI-12 | Abgabe und Verfall erfassen | Must | Geschäftsstelle |
| US-FI-13 | Abgerechnete Einsätze schützen | Must | System (Anwesenheitserfassung) |
| US-FI-14 | Auszahlungsrunde zusammenstellen | Must | Geschäftsstelle |
| US-FI-15 | Auszahlungsrunde freigeben: Auszahlliste und Überweisungsdatei | Must | Geschäftsstelle |
| US-FI-16 | Dateien einer Runde erneut abrufen | Should | Geschäftsstelle |
| US-FI-17 | Abgleich Punktekonto Kletterhalle | Should | Geschäftsstelle |

Voraussetzungen aller Stories: Nachtrag der Administration nach Übergabe FI → AD (A1–A10, Aktion „freigeben“ aus Q1) und Nachtrag der Anwesenheitserfassung nach Übergabe FI → EZ (Z1–Z3).

---

### US-FI-01: Halbjahresabrechnung berechnen

**Als** Mitarbeiter:in der Geschäftsstelle
**möchte ich** für ein Abrechnungshalbjahr alle Abrechnungen auf Knopfdruck berechnen lassen,
**damit** ich nichts mehr aus der Excel-Tabelle übertragen muss.
**Priorität:** Must · **Regeln:** R1, R2, R9, R10, R15, R24, R32 · **Abhängig von:** Übergabe AD A1–A3, A6, A7; Übergabe EZ Z1, Z2

**Akzeptanzkriterien**
- AK1: Gegeben im 1. Halbjahr 2026 war Trainerin A an drei nicht abgesagten Trainings der Gruppe X (Referat Kinder und Jugend) „anwesend“, wenn ich „1. Halbjahr 2026 berechnen“ wähle, dann entsteht für Trainerin A eine Abrechnung im Zustand „Entwurf“ mit drei Positionen, je mit Gruppe X.
- AK2: Abgesagte Einsätze, Einsätze mit „keine Vergütung“, Anwesenheiten „eingetragen“ oder „nicht erschienen“ und Teilnehmer:innen erzeugen keine Position (R1).
- AK3: Einsätze von Referaten ohne Kennzeichen „halbjährliche Abrechnung“ (z. B. Klettern) werden nicht berücksichtigt (R2).
- AK4: Gegeben Trainerin A hat eine abgeschlossene Abrechnung für das Halbjahr, wenn ich erneut berechne, dann bleibt diese unverändert; ein neuer, noch nicht abgerechneter Einsatz erscheint als Hinweis „nicht abgerechnete Einsätze“ (R15).
- AK5 (Fehler): Gegeben für eine Position fehlt der Satz in den Stammdaten, dann wird die Position ohne Betrag mit Hinweis „Satz fehlt“ angelegt, und die Abrechnung kann nicht abgeschlossen werden (R9).
- AK6 (Rechte): Gegeben ich habe die Vorlage Referent:in, dann sehe ich die Schaltfläche „berechnen“ nicht, und ein direkter Aufruf wird mit „Für diesen Bereich hast du keine Rechte.“ abgelehnt (R32).

**Nicht Teil dieser Story:** Einzelabrechnung von Kurs und Tour (Iteration 1); Berechnung der Mengen (US-FI-02, US-FI-03).

---

### US-FI-02: Trainingseinheiten berechnen

**Als** Mitarbeiter:in der Geschäftsstelle
**möchte ich**, dass Trainings nach der Trainingszeit der Gruppe in Trainingseinheiten umgerechnet werden,
**damit** die Vergütung der Vergütungsordnung entspricht.
**Priorität:** Must · **Regeln:** R3, R4, R9 · **Abhängig von:** US-FI-01; Übergabe EZ Z2 (Dauer der Trainingszeit)

**Akzeptanzkriterien**
- AK1: Gegeben die Gruppe X hat dienstags 17:00–19:00, wenn ein Training am Dienstag abgerechnet wird, dann ist die Menge 4 TE und der Betrag für eine Trainerin 4 × 6,00 € = 24,00 €.
- AK2: Gegeben die Trainingszeit ist 17:00–18:15, dann ist die Menge 3 TE (angebrochene TE aufgerundet, R3).
- AK3: Gegeben die Gruppe hat am Wochentag des Trainings keine Trainingszeit, dann ist die Menge 0 mit Hinweis „ohne Trainingszeit“ (R4).
- AK4: Gegeben der Satz der Trainingseinheit ändert sich zum 01.04.2026, dann wird ein Training am 31.03. mit dem alten und eines am 01.04. mit dem neuen Satz abgerechnet (R9).
- AK5 (Rechte): Eine Referent:in sieht die Menge und den Satz der Positionen ihres Referats, kann sie aber nicht ändern.

**Nicht Teil dieser Story:** abweichende Dauer einzelner Trainings (nur Bemerkung in der Anwesenheitserfassung).

---

### US-FI-03: Tages-, Halbtages- und Tagessätze der Wettkampfbetreuung berechnen

**Als** Mitarbeiter:in der Geschäftsstelle
**möchte ich**, dass Fahrten, Ausbildungsfahrten, Trainingslager und Wettkampfbetreuungen nach Tagen abgerechnet werden,
**damit** ich Tage und Halbtage nicht von Hand zählen muss.
**Priorität:** Must · **Regeln:** R5, R6, R7, R10 · **Abhängig von:** US-FI-01

**Akzeptanzkriterien**
- AK1: Gegeben ein Tagesausflug mit Kategorie „unter 8 Stunden“, dann erhält eine Trainerin den Halbtagessatz der Fahrten (15,00 €), mit „mindestens 8 Stunden“ den Tagessatz (30,00 €).
- AK2: Gegeben eine Mehrtagesfahrt Fr 16:00 bis So 15:00, dann gilt: Freitag 8 h = Tagessatz, Samstag Tagessatz, Sonntag 15 h = Tagessatz; mit Rückkehr So 06:00 ist der Sonntag ein Halbtagessatz (R5).
- AK3: Gegeben eine Mehrtagesfahrt ohne Beginn und Ende, dann zählen alle Tage als Tagessatz und die Position trägt den Hinweis „ohne Uhrzeit“ (R5).
- AK4: Gegeben eine Wettkampfbetreuung Sa–So, dann erhält ein Helfer 2 × 40,00 € = 80,00 €, unabhängig von Uhrzeiten (R6).
- AK5: Gegeben die organisierende Person einer Mehrtagesfahrt über 3 Tage ist auch als Trainerin anwesend, dann erhält sie zusätzlich eine Position Organisationspauschale 3 × 10,00 € (R7).
- AK6: Gegeben eine eintägige Ausbildungsfahrt, dann gelten die Sätze der Abrechnungsart, die der Einsatz trägt (Vorbelegung: Mehrtageskurse).

**Nicht Teil dieser Story:** Reisekosten (Iteration 1); Kurs mit Lehreinheiten (Iteration 1).

---

### US-FI-04: Satz Trainer:in nach förderfähiger Lizenz

**Als** Mitarbeiter:in der Geschäftsstelle
**möchte ich**, dass der Satz Trainer:in nur mit förderfähiger Lizenz berechnet wird,
**damit** die Regel der Vergütungsordnung eingehalten wird, ohne dass ich Lizenzen nachschlage.
**Priorität:** Must · **Regeln:** R8 · **Abhängig von:** US-FI-01; Übergabe AD A8 (Lizenzen mit gültig von/bis, förderfähig)

**Akzeptanzkriterien**
- AK1: Gegeben Trainerin A hat eine förderfähige Lizenz, gültig bis 31.12.2027, dann werden ihre Positionen als Trainer:in mit Satz Trainer:in berechnet.
- AK2: Gegeben Trainer B hat die förderfähige Lizenz am 15.05.2026 erworben, dann gilt für alle seine Einsätze im 1. Halbjahr 2026 (auch vor dem 15.05.) der Satz Trainer:in.
- AK3: Gegeben die Lizenz von Trainerin C lief am 31.03.2026 ab, dann gilt ab dem 01.04.2026 der Satz Helfer:in mit Hinweis „keine förderfähige Lizenz“; eine Mehrtagesfahrt mit Start 30.03. bleibt ganz beim Satz Trainer:in.
- AK4: Gegeben Trainerin D ist als Trainer:in erfasst, hat aber nur eine nicht förderfähige Qualifikation, dann gilt der Satz Helfer:in mit Hinweis; die Geschäftsstelle kann ihn als Ausnahme mit Begründung der Referent:in korrigieren (US-FI-07).
- AK5 (Rechte): Eine Referent:in sieht den Hinweis „keine förderfähige Lizenz“, aber keine Lizenzdaten (Qualifikationsart, Nummer, Datum) (R31).

**Nicht Teil dieser Story:** Pflege der Lizenzen (Ehrenamtsmanagement).

---

### US-FI-05: Hinweise zu Voraussetzungen und Höchstbetrag

**Als** Mitarbeiter:in der Geschäftsstelle
**möchte ich** je Abrechnung sehen, was für die Auszahlung fehlt und ob der steuerfreie Höchstbetrag überschritten wird,
**damit** ich fehlende Unterlagen rechtzeitig anfordere.
**Priorität:** Must · **Regeln:** R11–R14, R31 · **Abhängig von:** US-FI-01; Übergabe AD A4, A8

**Akzeptanzkriterien**
- AK1: Gegeben für Trainerin A liegt keine Bestätigung steuerfreie Einnahmen für 2026 vor, dann zeigt die Abrechnung „Bestätigung steuerfreie Einnahmen 2026 fehlt“ (R12).
- AK2: Gegeben es fehlen Bankverbindung oder Trainervereinbarung, dann erscheinen „Bankverbindung fehlt“ bzw. „Trainervereinbarung fehlt“ (R13, R14).
- AK3: Gegeben Trainerin A wurden im Jahr 2026 bereits 3.200,00 € ausgezahlt und die neue Abrechnung beträgt 200,00 € mit Abgabefrist 2026, dann erscheint „Höchstbetrag überschritten (3.400,00 € von 3.300,00 €)“; abschließen bleibt möglich (R11).
- AK4: Die Liste der Abrechnungen lässt sich nach „mit Hinweis“ filtern.
- AK5 (Rechte): Eine Referent:in sieht die Hinweise der Abrechnungen mit Positionen ihres Referats, aber keine Bankverbindung und keine Daten der Nachweise (R31).

**Nicht Teil dieser Story:** E-Mail an die Person (Schnittstellen-Connector, später).

---

### US-FI-06: Abrechnungen auflisten und ansehen

**Als** Mitarbeiter:in der Geschäftsstelle oder Referent:in
**möchte ich** die Abrechnungen eines Halbjahres als Liste und je Person im Detail sehen,
**damit** ich den Stand überblicke und einzelne Abrechnungen prüfen kann.
**Priorität:** Must · **Regeln:** R31, R32, R33 · **Abhängig von:** US-FI-01

**Akzeptanzkriterien**
- AK1: Gegeben ich wähle „1. Halbjahr 2026“, dann sehe ich je Abrechnung Name, Gruppe(n), Betrag, Zustand und Hinweise; Filter nach Zustand, Gruppe und „mit Hinweis“; Standard ist das aktuelle Halbjahr.
- AK2: Im Detail sehe ich die Positionen mit Datum, Einsatz, Gruppe, Rolle, Satzart, Menge, Satz, Betrag, Korrekturen mit Begründung, Summe je Gruppe und gesamt sowie den Verlauf (R33).
- AK3: Gegeben für das Halbjahr gibt es noch keine Abrechnungen, dann erscheint „Für dieses Halbjahr gibt es noch keine Abrechnungen.“ und (nur mit „FI verwalten“) die Schaltfläche „berechnen“.
- AK4 (Rechte): Gegeben ich bin Referent:in Kinder und Jugend, dann sehe ich nur Abrechnungen mit mindestens einer Position meines Referats, diese aber ganz (auch Positionen des Leistungssports) (R31); eine Abrechnung nur mit Positionen des Leistungssports erscheint nicht, auch nicht per direktem Link („Abrechnung nicht gefunden.“).
- AK5: Die Liste ist ab 375 px Breite bedienbar (Name, Betrag, Zustand; Details aufklappbar).

**Nicht Teil dieser Story:** Export als Tabelle (später).

---

### US-FI-07: Position korrigieren

**Als** Mitarbeiter:in der Geschäftsstelle
**möchte ich** Satzart oder Menge einer Position mit Begründung korrigieren,
**damit** Ausnahmen und fehlende Angaben richtig abgerechnet werden.
**Priorität:** Must · **Regeln:** R16, R23 · **Abhängig von:** US-FI-06

**Akzeptanzkriterien**
- AK1: Gegeben eine Position ohne Trainingszeit mit Menge 0, wenn ich Menge 3 und die Begründung „Training 17:00–18:30 laut Gruppenleitung“ eingebe, dann wird der Betrag neu berechnet; berechneter und korrigierter Wert sind sichtbar.
- AK2: Gegeben eine Position mit Satz Helfer:in wegen fehlender Lizenz, wenn ich „Satz Trainer:in“ mit Begründung „Ausnahme, Begründung Referentin Kinder und Jugend vom 20.06.“ wähle, dann gilt der Satz Trainer:in.
- AK3: Gegeben eine Mehrtagesfahrt ohne Uhrzeit, wenn ich den letzten Tag auf Halbtagessatz setze und begründe, dann sinkt der Betrag entsprechend.
- AK4 (Fehler): Gegeben ich lasse die Begründung leer, dann wird nicht gespeichert und es erscheint „Bitte eine Begründung angeben.“
- AK5: Gegeben die Abrechnung war „bestätigt“, wenn ich eine Position korrigiere, dann fällt die Bestätigung des betroffenen Referats zurück und die Abrechnung ist wieder „Entwurf“ (R23).
- AK6 (Rechte): Gegeben die Abrechnung ist abgeschlossen oder ich habe nur die Vorlage Referent:in, dann ist keine Korrektur möglich.

**Nicht Teil dieser Story:** Positionen von Hand hinzufügen (Iteration 1).

---

### US-FI-08: Abrechnung bestätigen („sachlich richtig“)

**Als** Referent:in
**möchte ich** die Abrechnungen meines Referats prüfen und als sachlich richtig bestätigen,
**damit** das Vier-Augen-Prinzip eingehalten ist und die Geschäftsstelle abschließen kann.
**Priorität:** Must · **Regeln:** R23, R31, R33 · **Abhängig von:** US-FI-06; Übergabe AD A7 (Aktion „freigeben“, Reichweite „Referat“)

**Akzeptanzkriterien**
- AK1: Gegeben ich bin Referent:in Kinder und Jugend und es gibt Abrechnungen im Entwurf mit Positionen meines Referats, dann zeigt der Filter „zu bestätigen“ genau diese.
- AK2: Wenn ich eine oder mehrere Abrechnungen markiere und „bestätigen“ wähle, dann werden die Positionen meines Referats mit meinem Namen und Zeitpunkt bestätigt; hat die Abrechnung keine Positionen anderer Referate, ist sie „bestätigt“.
- AK3: Gegeben eine Abrechnung hat Positionen aus Kinder und Jugend und Leistungssport, dann ist sie erst „bestätigt“, wenn beide Referate bestätigt haben; bis dahin zeigt sie „bestätigt: Kinder und Jugend; offen: Leistungssport“.
- AK4: Ich kann zu einer Position mit Hinweis „keine förderfähige Lizenz“ eine Begründung für eine Ausnahme eintragen; die Geschäftsstelle sieht sie bei der Korrektur.
- AK5 (Fehler): Gegeben ich bin zugleich die Person, die die Abrechnung später abschließen würde, dann ist das kein Fehler beim Bestätigen; die Prüfung erfolgt beim Abschluss (US-FI-10 AK4).
- AK6 (Rechte): Gegeben ich habe Rechte nur für das Referat Klettern, dann kann ich keine Abrechnung bestätigen, die nur Positionen von Kinder und Jugend hat (Datenbank lehnt ab).

**Nicht Teil dieser Story:** Bestätigung zurücknehmen durch die Referent:in [ANNAHME: nicht im MVP; die Geschäftsstelle setzt per Korrektur auf Entwurf].

---

### US-FI-09: Bestätigen in Vertretung

**Als** Mitarbeiter:in der Geschäftsstelle
**möchte ich** eine Abrechnung stellvertretend bestätigen, wenn keine Referent:in des Referats verfügbar ist,
**damit** die Abgabefrist eingehalten werden kann.
**Priorität:** Should · **Regeln:** R23, R33 · **Abhängig von:** US-FI-08

**Akzeptanzkriterien**
- AK1: Wenn ich „in Vertretung bestätigen“ wähle, eine Begründung (1–500 Zeichen) eingebe und bestätige, dann gilt das Referat als bestätigt mit Vermerk „in Vertretung“ und meinem Namen.
- AK2 (Fehler): Gegeben ich lasse die Begründung leer, dann erscheint „Bitte eine Begründung angeben.“
- AK3: Gegeben ich habe in Vertretung bestätigt, dann kann ich dieselbe Abrechnung nicht abschließen; eine zweite Person der Geschäftsstelle schließt ab (US-FI-10 AK4).
- AK4: Die Vertretung erscheint im Verlauf und auf der Auszahlliste unter „sachl. richtig“ als „in Vertretung: Name, Datum“.
- AK5 (Rechte): Referent:innen sehen „in Vertretung bestätigen“ nicht.

**Nicht Teil dieser Story:** Prüfung, ob die Referent:in tatsächlich abwesend ist.

---

### US-FI-10: Abrechnung abschließen und Abrechnungsdokument drucken

**Als** Mitarbeiter:in der Geschäftsstelle
**möchte ich** bestätigte Abrechnungen abschließen und das Abrechnungsdokument zur Unterschrift drucken,
**damit** die Person unterschreiben kann und die Abrechnung nicht mehr verändert wird.
**Priorität:** Must · **Regeln:** R9, R17, R18, R23, R33 · **Abhängig von:** US-FI-08; US-FI-13

**Akzeptanzkriterien**
- AK1: Gegeben eine Abrechnung ist „bestätigt“, wenn ich „abschließen“ wähle, dann ist sie „abgeschlossen“, und ich kann das Abrechnungsdokument als PDF (A4) öffnen.
- AK2: Das Dokument enthält Name, Halbjahr, Positionen mit Datum, Gruppe, Einsatz, Menge, Satz, Betrag, Korrekturen mit Begründung, Summe je Gruppe und gesamt, Abgabefrist mit Hinweis auf das Erlöschen des Anspruchs, die Erklärung zum Freibetrag, Ort, Datum und Unterschriftsfeld; keine Bankdaten (R18).
- AK3: Ich kann mehrere Abrechnungen auf einmal abschließen und die Dokumente als eine PDF-Datei (eine Person je Seite) drucken.
- AK4 (Fehler): Gegeben die Abrechnung ist nicht von allen Referaten bestätigt, oder ich selbst habe sie bestätigt, oder eine Position hat keinen Satz, dann wird nicht abgeschlossen und es erscheint „Die Abrechnung ist noch nicht von allen Referaten bestätigt.“ bzw. „Du hast diese Abrechnung bestätigt. Eine andere Person muss abschließen.“ bzw. „Für eine Position fehlt der Satz.“
- AK5: Nach dem Abschluss sind die Anwesenheiten der Positionen in der Anwesenheitserfassung gesperrt (US-FI-13).
- AK6 (Rechte): Referent:innen sehen „abschließen“ nicht; Schreibversuche lehnt die Datenbank ab.

**Nicht Teil dieser Story:** elektronische Unterschrift; Versand an die Person.

---

### US-FI-11: Abschluss zurücknehmen

**Als** Mitarbeiter:in der Geschäftsstelle
**möchte ich** den Abschluss einer noch nicht abgegebenen Abrechnung zurücknehmen,
**damit** ich einen Fehler korrigieren kann.
**Priorität:** Should · **Regeln:** R17, R33 · **Abhängig von:** US-FI-10

**Akzeptanzkriterien**
- AK1: Gegeben die Abrechnung ist „abgeschlossen“, wenn ich „Abschluss zurücknehmen“ wähle und bestätige, dann ist sie wieder „Entwurf“, die Bestätigungen entfallen und die Sperre in der Anwesenheitserfassung ist aufgehoben.
- AK2: Vor der Rücknahme erscheint „Das gedruckte Abrechnungsdokument wird ungültig. Fortfahren?“
- AK3 (Fehler): Gegeben die Abrechnung ist „abgegeben“, „verfallen“ oder „ausgezahlt“, dann ist keine Rücknahme möglich („Diese Abrechnung kann nicht mehr zurückgenommen werden.“).
- AK4 (Rechte): Nur mit „FI verwalten“.

**Nicht Teil dieser Story:** Rücknahme nach der Auszahlung (Iteration 1, Storno).

---

### US-FI-12: Abgabe und Verfall erfassen

**Als** Mitarbeiter:in der Geschäftsstelle
**möchte ich** eintragen, wann das unterschriebene Abrechnungsdokument eingegangen ist, und nicht abgegebene Abrechnungen nach der Frist als verfallen markieren,
**damit** nur fristgerecht abgegebene Abrechnungen ausgezahlt werden.
**Priorität:** Must · **Regeln:** R19, R33 · **Abhängig von:** US-FI-10; Übergabe AD A5

**Akzeptanzkriterien**
- AK1: Gegeben die Abrechnung ist „abgeschlossen“, wenn ich „abgegeben am 20.07.2026“ eintrage, dann ist sie „abgegeben“.
- AK2: Gegeben die Frist für das 1. Halbjahr ist der 31.07., wenn ich „abgegeben am 02.08.2026“ eintrage, dann erscheint „Die Frist ist abgelaufen. Der Anspruch ist erloschen. Trotzdem als abgegeben erfassen?“; mit Bestätigung und Begründung wird gespeichert.
- AK3: Nach Ablauf der Frist zeigt der Filter „Frist abgelaufen“ alle abgeschlossenen, nicht abgegebenen Abrechnungen; ich kann sie (einzeln oder markiert) als „verfallen“ setzen.
- AK4 (Fehler): Gegeben das Abgabedatum liegt in der Zukunft, dann erscheint „Das Datum darf nicht in der Zukunft liegen.“
- AK5 (Rechte): Nur mit „FI verwalten“.

**Nicht Teil dieser Story:** Erinnerung an die Frist per E-Mail (später).

---

### US-FI-13: Abgerechnete Einsätze schützen

**Als** Mitarbeiter:in der Geschäftsstelle
**möchte ich**, dass abgerechnete Anwesenheiten in der Anwesenheitserfassung nicht mehr geändert werden können,
**damit** Abrechnung und Einsätze übereinstimmen.
**Priorität:** Must · **Regeln:** R17 · **Abhängig von:** Übergabe EZ Z3 (`fi_attendance_locked`)

**Akzeptanzkriterien**
- AK1: Gegeben die Anwesenheit von Trainerin A beim Training am 14.04.2026 steckt in einer abgeschlossenen Abrechnung, wenn jemand in der Anwesenheitserfassung ihre Anwesenheit entfernt oder den Einsatz absagt oder löscht, dann wird abgelehnt mit „Dieser Einsatz ist abgerechnet. Änderungen nur nach Rücknahme des Abschlusses in Finanzen.“
- AK2: Datum, Zeiten, Dauer-Kategorie, Abrechnungsart und organisierende Person dieses Einsatzes sind ebenfalls gesperrt.
- AK3: Die Bemerkung und Anwesenheiten anderer, nicht abgerechneter Personen bleiben änderbar.
- AK4: Nach Rücknahme des Abschlusses (US-FI-11) ist die Änderung wieder möglich.
- AK5 (Rechte): Die Sperre gilt für alle Rechtevorlagen, auch für „EZ verwalten“.

**Nicht Teil dieser Story:** Anzeige in der Anwesenheitserfassung, in welcher Abrechnung die Anwesenheit steckt (Vorschlag für den Nachtrag EZ).

---

### US-FI-14: Auszahlungsrunde zusammenstellen

**Als** Mitarbeiter:in der Geschäftsstelle
**möchte ich** aus abgegebenen Abrechnungen eine Auszahlungsrunde zusammenstellen,
**damit** ich mehrmals im Halbjahr auszahlen kann, sobald Abrechnungen vorliegen.
**Priorität:** Must · **Regeln:** R12–R14, R20, R24, R25, R30 · **Abhängig von:** US-FI-12; Übergabe AD A8, A10

**Akzeptanzkriterien**
- AK1: Gegeben für das 1. Halbjahr 2026 gibt es schon zwei freigegebene Runden, wenn ich „neue Auszahlungsrunde“ wähle, dann entsteht „Runde 3“ im Entwurf mit Ausführungsdatum nächster Bankarbeitstag; vorgeschlagen sind alle abgegebenen, noch nicht ausgezahlten Abrechnungen.
- AK2: Die Vorschau zeigt je Person und Gruppe eine Auszahlzeile (Zuname, Vorname, Betrag, Gruppe) und die Summe; Trainerin A mit Gruppe X (120,00 €) und Gruppe Y (40,00 €) erscheint in zwei Zeilen (R24).
- AK3: Abrechnungen ohne Bankverbindung, Bestätigung steuerfreie Einnahmen oder Trainervereinbarung sind nicht wählbar und mit Grund aufgeführt (R12–R14).
- AK4: Ich kann einzelne Abrechnungen abwählen; eine Abrechnung kann nicht gleichzeitig in zwei Runden im Entwurf stehen (R25).
- AK5 (Fehler): Gegeben das Ausführungsdatum liegt in der Vergangenheit, dann erscheint „Das Ausführungsdatum darf nicht in der Vergangenheit liegen.“ (R30).
- AK6 (Rechte): Referent:innen sehen den Bereich Auszahlungen nicht.

**Nicht Teil dieser Story:** Freigabe (US-FI-15).

---

### US-FI-15: Auszahlungsrunde freigeben: Auszahlliste und Überweisungsdatei

**Als** Mitarbeiter:in der Geschäftsstelle
**möchte ich** eine Auszahlungsrunde freigeben und dabei Auszahlliste und Überweisungsdatei erhalten,
**damit** ich die Überweisungen im Online-Banking hochladen und die Liste in der Buchhaltung ablegen kann.
**Priorität:** Must · **Regeln:** R20, R21, R24, R26–R28 · **Abhängig von:** US-FI-14; Übergabe AD A10

**Akzeptanzkriterien**
- AK1: Gegeben „Runde 3“ im Entwurf mit 17 Auszahlzeilen und Summe 3.434,00 €, wenn ich „freigeben“ wähle und bestätige, dann ist die Runde „freigegeben“, die enthaltenen Abrechnungen sind „ausgezahlt“, und ich erhalte die Auszahlliste (PDF) und die Überweisungsdatei (XML).
- AK2: Die Auszahlliste hat den Titel „Auszahlliste Übungsleitervergütung 1. Hj. 2026 – Runde 3“, das Sachkonto, je Auszahlzeile Zuname, Vorname, Auszahlungsbetrag und Gruppe (sortiert nach Gruppe, dann Name), die Summe, unter „sachl. richtig“ die Bestätigungen (je Referat Name, Datum) und leere Felder „gf Vorstand“ und „angewiesen“; keine IBANs (C6, R27).
- AK3: Die Überweisungsdatei ist pain.001.001.03 nach C7: eine Zahlungsgruppe mit Auftraggeber und Konto der Sektion, Ausführungsdatum, je Auszahlzeile Betrag, Kontoinhaber:in, IBAN und Verwendungszweck „ÜL-Vergütung 1. Hj 2026 Gruppe X“; `NbOfTxs` = 17 und `CtrlSum` = 3434.00 wie die Auszahlliste (R26, R28). Die Datei besteht die Schema-Prüfung.
- AK4 (Fehler): Gegeben die Angaben der Sektion (Name, IBAN, BIC) fehlen, dann wird nicht freigegeben und es erscheint „Die Angaben der Sektion für die Auszahlung fehlen. Bitte den Admin informieren.“
- AK5 (Fehler): Gegeben eine Bankverbindung ist seit der Zusammenstellung entfernt worden, dann wird nicht freigegeben und die betroffene Zeile wird genannt („Bankverbindung fehlt: Name“).
- AK6 (Rechte): Nur mit „FI verwalten“; Name und IBAN werden nicht in Finanzen gespeichert (R21).

**Nicht Teil dieser Story:** Hochladen bei der Bank (manuell); Storno einer Runde (Iteration 1).

---

### US-FI-16: Dateien einer Runde erneut abrufen

**Als** Mitarbeiter:in der Geschäftsstelle
**möchte ich** Auszahlliste und Überweisungsdatei einer freigegebenen Runde später erneut herunterladen,
**damit** ich eine verlorene Datei ersetzen kann.
**Priorität:** Should · **Regeln:** R21, R29 · **Abhängig von:** US-FI-15

**Akzeptanzkriterien**
- AK1: In der Liste der Auszahlungsrunden (Halbjahr, Nummer, Ausführungsdatum, Anzahl, Summe, freigegeben am/von) kann ich je freigegebener Runde PDF und XML abrufen.
- AK2: Die erneut erzeugte XML hat dieselbe Nachrichten-ID, dieselben Ende-zu-Ende-IDs, Beträge und Verwendungszwecke wie bei der Freigabe.
- AK3: Vor dem XML-Download erscheint „Diese Runde ist bereits freigegeben. Die Überweisungsdatei nicht erneut hochladen.“
- AK4: Gegeben eine Bankverbindung hat sich seit der Freigabe geändert, dann erscheint zusätzlich „Bankverbindung seit der Freigabe geändert: Name“ (R21).
- AK5 (Rechte): Nur mit „FI verwalten“.

**Nicht Teil dieser Story:** Speichern der Dateien im Vereins OS.

---

### US-FI-17: Abgleich Punktekonto Kletterhalle

**Als** Mitarbeiter:in der Geschäftsstelle
**möchte ich** die Rechnung der Kletterhalle mit der Anzahl anwesender Kinder vergleichen,
**damit** ich falsche Abbuchungen erkenne.
**Priorität:** Should · **Regeln:** – (Erhebung B6) · **Abhängig von:** Anwesenheitserfassung US-EZ-16 (`ez_climbing_points_report`), Übergabe EZ Z2 (Lesen mit FI-Rechten)

**Akzeptanzkriterien**
- AK1: Gegeben ich wähle „Kletterhalle Test“ und Oktober 2026, dann sehe ich je Training Datum, Gruppe, Anzahl anwesender Teilnehmer:innen, Anzahl Probetrainings sowie die Summe ohne und mit Probetrainings.
- AK2: Wenn ich die Anzahl laut Rechnung (51) und die Rechnungsnummer eingebe, dann zeigt das System die Abweichung zu beiden Summen und speichert den Abgleich mit Bemerkung.
- AK3: Gespeicherte Abgleiche erscheinen in einer Liste (Ort, Zeitraum, Werte, Abweichung, erfasst von/am).
- AK4 (Fehler): Gegeben der Ort hat kein Kennzeichen „Punktekonto Kletterhalle“, dann ist er nicht wählbar; ohne Trainings im Zeitraum erscheint „Keine Trainings im Zeitraum.“
- AK5 (Rechte): Nur mit „FI verwalten“; keine Namen von Kindern.

**Nicht Teil dieser Story:** Entscheidung, ob Probetrainings zählen (Iteration 1).

## Nachtrag v0.2: Buchungslauf Verträge

Grundlage: 01-erhebung.md v0.7, Abschnitt H (R34–R46). Beispiele fiktiv: Jugendgruppe Test 1 mit 3 Verträgen à 35,00 €, Jugendgruppe Test 2 mit 2 Verträgen à 40,00 €; Stichtag 01.11.2026; Buchungslauf erstellt am Mittwoch, 02.12.2026.

### US-FI-18: Buchungslauf zusammenstellen

**Als** Mitarbeiter:in der Geschäftsstelle
**möchte ich** für einen Monat alle einzuziehenden Verträge mit einem Klick zusammenstellen und prüfen,
**damit** ich die Gruppenbeiträge nicht mehr von Hand zusammensuchen muss.
**Priorität:** Must · **Regeln:** R34, R35, R37, R38, R39, R47 · **Abhängig von:** Übergabe FI → GR v1.0 (G1), FI → AD v1.4 (A11, A13)

**Akzeptanzkriterien**
- AK1: Gegeben 5 Verträge sind am 01.12.2026 aktiv, wenn ich „Neuer Buchungslauf“ für Dezember 2026 wähle, dann zeigt die Vorschau 5 Lastschriften mit Teilnehmer:in, Gruppe, Vertragsinhaber:in, Mandatsreferenz, Betrag, Erst-/Folgelastschrift, Summen je Gruppe (105,00 € und 80,00 €) und gesamt (185,00 €).
- AK2: Gegeben ein Vertrag beginnt am 15.12.2026, dann ist er im Dezember nicht enthalten und im Januar 2027 mit vollem Betrag enthalten (R34).
- AK3: Gegeben ein Vertrag ist zum 10.12.2026 gekündigt, dann ist er im Dezember mit vollem Betrag enthalten und im Januar nicht (R34).
- AK4: Gegeben ein Vertrag beginnt am 01.12.2026 (nach dem Stichtag) und wurde noch nie eingezogen, dann ist er Erstlastschrift; ein Vertrag mit Beginn 01.09.2026 (vor dem Stichtag) ist Folgelastschrift (R38).
- AK5: Der Fälligkeitstag ist mit dem 05.12.2026 vorbelegt (erstellt + 3 Tage; Samstag → Montag 07.12.2026) und änderbar; ein Datum ohne einen Bankarbeitstag Vorlauf wird abgelehnt (R39).
- AK5a: Ich erfasse bei einer Lastschrift einen Zusatzbetrag von 70,00 € mit Text „und rückwirkend bis Oktober 2026“ und Begründung; die Lastschrift beträgt 105,00 €, der Verwendungszweck lautet „Jugendgruppe Test 1 Beitragszahlung Dezember 2026 und rückwirkend bis Oktober 2026“; ohne Text oder Begründung „Bitte Text und Begründung angeben.“ (R47).
- AK6: Ich kann eine Lastschrift abwählen; die Summen ändern sich; der Vertrag bleibt für Dezember offen.
- AK7 (Fehler): Gegeben das Mandat ist nach dem Fälligkeitstag unterschrieben, dann erscheint der Vertrag unter „Ausgeschlossen“ mit „Mandat noch nicht unterschrieben“ (R37).
- AK8 (Rechte): Nur mit „FI verwalten“; ohne dieses Recht /kein-zugriff.

### US-FI-19: Buchungslauf freigeben: Lastschriftdatei und Einzugsliste

**Als** Mitarbeiter:in der Geschäftsstelle
**möchte ich** den geprüften Buchungslauf freigeben und die Dateien erhalten,
**damit** ich die Lastschriften bei der Sparkasse hochladen und die Liste in der Buchhaltung ablegen kann.
**Priorität:** Must · **Regeln:** R40–R43, R45

**Akzeptanzkriterien**
- AK1: Wenn ich „Freigeben“ wähle, dann fragt das System „Buchungslauf Dezember 2026 mit 5 Lastschriften über 185,00 € freigeben? Fälligkeit 07.12.2026.“; nach Bestätigung erhalte ich `Lastschriften_Vertraege_2026_12_Lauf1.xml` und `Einzugsliste_Vertraege_2026_12_Lauf1.pdf` [ANNAHME: Dateinamen].
- AK2: Die Lastschriftdatei enthält je Sequenz eine Zahlungsgruppe; `CtrlSum` = 185.00, `NbOfTxs` = 5; Gläubiger-ID, Mandatsreferenz und Unterschriftsdatum je Lastschrift; Verwendungszweck „Jugendgruppe Test 1 Beitragszahlung Dezember 2026“ (R40, R42).
- AK3: Die Einzugsliste zeigt je Lastschrift die IBAN gekürzt (`•••• 3000`), Summen je Gruppe und gesamt; gesamt = Summe der Datei (R41).
- AK4: Nach der Freigabe sind die 5 Verträge für Dezember eingezogen; ein neuer Lauf für Dezember enthält sie nicht (R35).
- AK5 (Fehler): Fehlt die Gläubiger-ID, dann „Die Angaben der Sektion für den Einzug fehlen. Bitte den Admin informieren.“; ohne Lastschriften „Der Buchungslauf enthält keine Lastschriften.“ (R45).
- AK6 (Datenschutz): Nach dem Download Hinweis zum Löschen der Datei; IBAN und Kontoinhaber:in sind nicht in Finanzen gespeichert (R43).

### US-FI-20: Nachtrag für einen Monat

**Als** Mitarbeiter:in der Geschäftsstelle
**möchte ich** später erfasste oder abgewählte Verträge im selben Monat nachträglich einziehen,
**damit** kein Beitrag verloren geht und keiner doppelt eingezogen wird.
**Priorität:** Must · **Regeln:** R35

**Akzeptanzkriterien**
- AK1: Gegeben Lauf 1 für Dezember ist freigegeben und danach wird ein Vertrag mit Beginn 01.12.2026 erfasst, wenn ich einen neuen Buchungslauf für Dezember erstelle, dann heißt er „Lauf 2“ und enthält nur diesen Vertrag.
- AK2: Gegeben alle aktiven Verträge sind für Dezember eingezogen, dann zeigt ein neuer Lauf „Keine Verträge zum Einziehen.“
- AK3 (Fehler): Ein Vertrag aus einem Entwurf erscheint in keinem anderen Lauf desselben Monats.

### US-FI-21: Buchungsläufe ansehen und Dateien erneut abrufen

**Als** Mitarbeiter:in der Geschäftsstelle
**möchte ich** frühere Buchungsläufe sehen und ihre Dateien erneut erzeugen,
**damit** ich bei Rückfragen der Buchhaltung oder einem fehlgeschlagenen Upload nicht neu anfangen muss.
**Priorität:** Should · **Regeln:** R40, R43

**Akzeptanzkriterien**
- AK1: Die Liste zeigt je Lauf Monat, Nummer, Fälligkeitstag, Zustand, Anzahl, Summe, freigegeben am/von.
- AK2: Erneuter Abruf erzeugt Dateien mit gleichen IDs und Beträgen und warnt „Dieser Buchungslauf ist bereits freigegeben. Die Lastschriftdatei nicht erneut hochladen.“
- AK3: Hat sich eine Bankverbindung seit der Freigabe geändert, erscheint der Hinweis mit Namen (R43).

**Nicht Teil dieses Nachtrags:** Rücklastschriften, Storno eines freigegebenen Laufs, Vorabinformation, Mandatsänderung (R44, offen).

