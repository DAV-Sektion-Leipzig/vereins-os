# User Stories: Ehrenamtsmanagement (EA)

Stand: 23.10.2026 · Version 0.2.1 · Status: Entwurf · Product Owner: Toni Werner
Grundlage: 01-erhebung.md v0.5 (Regeln R1–R17 EA), specs/ad-administration/spec.md v0.9 (Regeln „… AD“), glossar.md v1.5
Änderungen v0.2.1: US-EA-18 AK6 – Schlüssel wird verdeckt im Terminal abgefragt, nie in einer Datei (Product Owner 23.10.2026).
Änderungen v0.2: Annahmen A1–A7 vom Product Owner bestätigt (22.10.2026); Spec v0.1 erstellt.
Änderungen v0.1: Ersterstellung (US-EA-01 bis US-EA-19).

Hinweise:
- „R… AD“ = Regel der Administration (spec.md AD Abschnitt 5); „R…“ ohne Zusatz = Regel der Erhebung Ehrenamtsmanagement (Abschnitt D).
- Testpersonen: Seed der Administration (Nr. 1–12, u. a. Toni Muster, Anton Muster, Rita Referentin – Referat Klettern, Karl Zweireferat, Olga Ausgeschieden, Paul Nurgruppe) und Ergänzung des Ehrenamtsmanagements (Nr. 19–22, Spec Abschnitt 9): Lena Lizenz (Lizenz läuft in 2 Monaten ab), Max Abgelaufen (Trainer:in mit abgelaufener Lizenz, Referat Kinder und Jugend), Greta Gremium (Mitglied Beirat, ohne Referat), Sven Schlüssel (Helfer:in Klettern, Schlüssel K4 nicht zurückgegeben, Zugang DAV360).
- „Geschäftsstelle“, „Admin“, „Referent:in“, „Vorstand“ meinen Nutzer mit der gleichnamigen Rechtevorlage (Testzugänge aus dem Seed der Administration).
- Alle Stories setzen den Kern der Administration (T1–T49) und die Übergabe Ü1/Ü2 (uebergabe-administration.md) voraus, soweit nicht anders genannt.

## Übersicht

| Story | Titel | Priorität |
|---|---|---|
| US-EA-01 | Modul freischalten und Navigation | Must |
| US-EA-02 | Übersicht der Aktiven mit Suche | Must |
| US-EA-03 | Übersicht filtern | Must |
| US-EA-04 | Person im Detail ansehen | Must |
| US-EA-05 | Person anlegen | Must |
| US-EA-06 | Eigenschaften pflegen | Must |
| US-EA-07 | Lizenz und Qualifikation erfassen und verlängern | Must |
| US-EA-08 | Ehrenamtsstatus ändern | Must |
| US-EA-09 | Ausscheiden | Must |
| US-EA-10 | Rückkehr und Übernahme | Must |
| US-EA-11 | Ablaufstatus anzeigen | Must |
| US-EA-12 | Stichtagsliste | Must |
| US-EA-13 | Gremium-Sichten | Should |
| US-EA-14 | Referate und Gremien pflegen | Should |
| US-EA-15 | Eigenschaftsarten und Qualifikationsarten im Ehrenamtsmanagement | Must |
| US-EA-16 | Startbestand System-Eigenschaftsarten und Qualifikationsarten | Must |
| US-EA-17 | Migration: Probelauf mit Prüfbericht | Must |
| US-EA-18 | Migration: Lauf gegen PROD | Must |
| US-EA-19 | Testdaten des Ehrenamtsmanagements | Must |

---

### US-EA-01: Modul freischalten und Navigation
**Als** Nutzer mit Rechten im Ehrenamtsmanagement
**möchte ich** das Modul auf der Startseite finden und darin navigieren,
**damit** ich ohne Umweg zu Aktiven, Listen und Stammdaten komme.
**Priorität:** Must · **Regeln:** R5 AD, R30 AD · **Abhängig von:** Administration T33, T40
**Akzeptanzkriterien**
- AK1: Gegeben das Modul ist freigeschaltet (`ad_modules.is_available` für EA = true), wenn Geschäftsstelle, Admin oder Referent:in die Startseite öffnet, dann erscheint die Kachel „Ehrenamtsmanagement“.
- AK2: Gegeben Geschäftsstelle oder Admin, wenn sie das Modul öffnen, dann zeigt die Navigation „Aktive“, „Ablauf“, „Gremien“, „Eigenschaftsarten“, „Qualifikationsarten“, „Referate und Gremien“.
- AK3: Gegeben Referent:in, wenn sie das Modul öffnet, dann zeigt die Navigation nur „Aktive“ und „Ablauf“.
- AK4 (Rechte): Gegeben Vorstand (kein Recht), wenn er /ea direkt aufruft, dann landet er auf /kein-zugriff und es wird keine Abfrage auf Personendaten ausgeführt.
- AK5 (Rechte): Gegeben Referent:in, wenn sie /ea/gremien oder /ea/eigenschaftsarten direkt aufruft, dann landet sie auf /kein-zugriff.
**Nicht Teil dieser Story:** Inhalte der Seiten (eigene Stories).

### US-EA-02: Übersicht der Aktiven mit Suche
**Als** Geschäftsstelle oder Referent:in
**möchte ich** alle für mich sichtbaren Aktiven in einer Tabelle sehen und nach Namen suchen,
**damit** ich eine Person schnell finde, statt in der Excel-Liste zu suchen.
**Priorität:** Must · **Regeln:** R1, R2, R32 AD, R34 AD · **Abhängig von:** US-EA-01
**Akzeptanzkriterien**
- AK1: Gegeben Geschäftsstelle, wenn sie „Aktive“ öffnet, dann sieht sie alle Personen mit Status „aktiv“ oder „ruhend“ mit Name (R2), Ehrenamtsstatus mit „seit“, Referaten, Funktionen und Ämtern, Lizenzkürzeln und dem schlechtesten Ablaufstatus; Olga Ausgeschieden erscheint nicht.
- AK2: Gegeben Referent:in Klettern, wenn sie „Aktive“ öffnet, dann sieht sie Toni Muster, Rita Referentin, Karl Zweireferat, Lena Lizenz und Sven Schlüssel, nicht Anton Muster (nur Ausbildung), Max Abgelaufen, Greta Gremium, Olga Ausgeschieden und Paul Nurgruppe.
- AK3: Gegeben die Suche „toni“, wenn Geschäftsstelle sucht, dann erscheinen Personen, deren Vor-, Ruf- oder Nachname „toni“ enthält (ohne Groß-/Kleinschreibung), darunter Toni Muster.
- AK4 (leer): Gegeben eine Suche ohne Treffer, dann erscheint „Keine Aktiven gefunden.“
- AK5: Gegeben eine Bildschirmbreite von 375 px, dann wird die Tabelle als Karten ohne horizontales Scrollen angezeigt; 50 Einträge je Seite mit Blättern.
**Nicht Teil dieser Story:** Filter (US-EA-03), Export.

### US-EA-03: Übersicht filtern
**Als** Geschäftsstelle oder Referent:in
**möchte ich** die Übersicht nach Status, Zuordnung, Qualifikation und Ablauf filtern,
**damit** ich z. B. alle Trainer:innen eines Referats ohne gültige Lizenz sehe.
**Priorität:** Must · **Regeln:** R1, R9, R14, R34 AD · **Abhängig von:** US-EA-02, US-EA-11
**Akzeptanzkriterien**
- AK1: Gegeben die Filter Ehrenamtsstatus, Referat, Funktion, Amt, Qualifikation (Qualifikationsart, optional eingeschränkt nach Sparte), Ablaufstatus, „Trainer:in ohne gültige Lizenz“ und „aktiv ohne Funktion oder Amt“, wenn Filter kombiniert werden, dann zeigt die Liste die Schnittmenge.
- AK2: Gegeben Filter „Trainer:in ohne gültige Lizenz“, wenn Geschäftsstelle ihn setzt, dann erscheint Max Abgelaufen, nicht Lena Lizenz.
- AK3: Gegeben Geschäftsstelle, wenn sie im Statusfilter „ausgeschieden“ dazunimmt, dann erscheint Olga Ausgeschieden mit „ausgeschieden seit 30.06.2025“.
- AK4 (Rechte): Gegeben Referent:in, dann bietet der Statusfilter „ausgeschieden“ nicht an und der Filter „Gremium“ fehlt; der Referatsfilter enthält nur ihre Referate und ist mit allen eigenen Referaten vorbelegt.
- AK5: Gegeben gesetzte Filter, wenn der Nutzer die Seite neu lädt, dann bleiben die Filter erhalten (in der URL).
**Nicht Teil dieser Story:** Filter über frei angelegte Felder (nach MVP).

### US-EA-04: Person im Detail ansehen
**Als** Geschäftsstelle oder Referent:in
**möchte ich** alle für mich lesbaren Angaben einer Person nach Kategorie sehen,
**damit** ich ihren Stand auf einen Blick erfasse.
**Priorität:** Must · **Regeln:** R2, R9, R29 AD, R39 AD, R41 AD · **Abhängig von:** US-EA-02, Ü1
**Akzeptanzkriterien**
- AK1: Gegeben Geschäftsstelle öffnet Toni Muster, dann zeigt der Kopf Name, Rufname, Ehrenamtsstatus „aktiv seit 01.03.2025“ und eine aufklappbare Statushistorie; darunter Eigenschaften mit „sichtbar in“ EA, gruppiert nach Kategorie in der Reihenfolge Stammdaten, Kontakt, Zuordnung, Qualifikationen, Nachweise, Jahreseinträge, Ausgaben, Zugänge, Sonstiges.
- AK2: Gegeben eine Eigenschaftsart mit Bezeichnungen für „gültig von/bis“ (Ü1), dann zeigt die Eigenschaft diese Bezeichnungen (z. B. „ausgegeben am“).
- AK3: Gegeben aktuelle und beendete Eigenschaften, dann stehen aktuelle oben, beendete mit Kennzeichen „beendet“; je Eigenschaft ist die Historie früherer Werte aufklappbar (wer, wann).
- AK4 (Rechte): Gegeben Referent:in Klettern öffnet Karl Zweireferat, dann sieht sie auch seine Funktion im Referat Ausbildung, aber ohne Bearbeiten-Knopf, und sieht kein Geburtsdatum.
- AK5 (Rechte): Gegeben Referent:in ruft die URL von Anton Muster direkt auf, dann erscheint „Diese Person wurde nicht gefunden oder du hast keine Rechte.“
- AK6: Gegeben eine Funktion mit Bezug auf eine Gruppe, dann ist sie nur lesbar mit Hinweis „Diese Angabe wird im Modul Gruppen gepflegt.“
**Nicht Teil dieser Story:** Einsatzhistorie (Iteration 2), Bearbeiten (US-EA-06).

### US-EA-05: Person anlegen
**Als** Geschäftsstelle oder Referent:in
**möchte ich** eine neue Aktive mit erster Zuordnung anlegen,
**damit** sie sofort in der Sicht ihres Referats erscheint.
**Priorität:** Must · **Regeln:** R3, R4, R4 AD, R40 AD, R41 AD · **Abhängig von:** US-EA-02, Administration T39, T43, T49
**Akzeptanzkriterien**
- AK1: Gegeben Referent:in Klettern, wenn sie Vorname „Nina“, Nachname „Neu“ und Funktion „Helfer:in“ im Referat Klettern eingibt und speichert, dann wird die Person mit Status „aktiv“ ab heute angelegt und das Detail geöffnet.
- AK2 (Fehler): Gegeben Referent:in ohne Funktion oder Amt, wenn sie speichert, dann erscheint „Bitte eine Funktion oder ein Amt in deinem Referat angeben.“; die Referatsauswahl enthält nur Klettern.
- AK3: Gegeben Geschäftsstelle, wenn sie eine Person ohne Zuordnung anlegt, dann wird sie mit Status „aktiv“ angelegt (z. B. für eine spätere Gremium-Mitgliedschaft).
- AK4: Gegeben Eingabe „Anton“ „Muster“, wenn gespeichert wird, dann erscheint der Dublettendialog mit Toni Muster und Anton Muster (Vorname, Rufname, Nachname; Geburtsjahr nur für Geschäftsstelle und Admin) und den Aktionen nach US-EA-10, „Trotzdem anlegen“ und „Abbrechen“.
- AK5 (Fehler): Gegeben leerer Nachname, dann „Bitte Vorname und Nachname angeben.“
- AK6 (Rechte): Gegeben Vorstand, dann gibt es keinen Knopf „Person anlegen“; ein direkter Aufruf von `ea_create_volunteer` wird abgelehnt (`EA_CREATE_FORBIDDEN`).
**Nicht Teil dieser Story:** weitere Eigenschaften beim Anlegen (danach im Detail), Löschen.

### US-EA-06: Eigenschaften pflegen
**Als** Geschäftsstelle oder Referent:in
**möchte ich** Eigenschaften einer Person hinzufügen, ändern und beenden,
**damit** die Angaben aktuell bleiben, ohne die Historie zu verlieren.
**Priorität:** Must · **Regeln:** R12, R13, R35–R38 AD, R41 AD, R42 AD · **Abhängig von:** US-EA-04, Administration T47
**Akzeptanzkriterien**
- AK1: Gegeben Referent:in Klettern bei Sven Schlüssel, wenn sie „Eigenschaft hinzufügen“ → „Ausgabe“ wählt, Gegenstand „Schlüssel NoLimit“, „ausgegeben am“ heute, und speichert, dann erscheint die Ausgabe unter „Ausgaben“.
- AK2: Gegeben die Ausgabe Schlüssel K4 von Sven Schlüssel, wenn die Geschäftsstelle „Beenden“ mit Datum heute wählt, dann ist „zurückgegeben am“ = heute und die Ausgabe gilt als beendet.
- AK3 (Fehler): Gegeben Bankverbindung mit IBAN „DE00 1234“, wenn die Geschäftsstelle speichert, dann erscheint „Die IBAN ist ungültig.“; eine gültige IBAN wird ohne Leerzeichen in Großbuchstaben gespeichert.
- AK4 (Rechte): Gegeben Referent:in Klettern, wenn sie bei Karl Zweireferat eine Funktion mit Referat Ausbildung anlegen will, dann bietet die Auswahl nur Klettern an; ein direkter Schreibversuch wird abgelehnt (`EA_RELATION_FOREIGN_REFERAT`).
- AK5 (Rechte): Gegeben Referent:in, dann bietet „Eigenschaft hinzufügen“ keine Arten mit Lesestufe „nur Geschäftsstelle und Admin“ oder „vertraulich“ an.
- AK6: Gegeben eine Änderung eines Werts, dann steht die vorige Fassung mit „wer, wann“ in der Historie.
**Nicht Teil dieser Story:** Lizenz-Vorbelegung und Verlängern (US-EA-07), Löschen von Eigenschaften.

### US-EA-07: Lizenz und Qualifikation erfassen und verlängern
**Als** Geschäftsstelle oder Referent:in
**möchte ich** Lizenzen mit vorbelegtem Ablaufdatum erfassen und nach einer Fortbildung verlängern,
**damit** Ablaufdaten stimmen und die Historie erhalten bleibt.
**Priorität:** Must · **Regeln:** R5, R6, R25 AD, R27 AD, R28 AD · **Abhängig von:** US-EA-06, US-EA-16
**Akzeptanzkriterien**
- AK1: Gegeben neue Lizenz mit Qualifikationsart TCSPI (Gültigkeitsdauer 4) und „erworben am“ 15.05.2026 ohne letzte Fortbildung, dann ist „gültig bis“ mit 31.12.2030 vorbelegt und änderbar.
- AK2: Gegeben zusätzlich „letzte Fortbildung“ 10.03.2027, dann ist „gültig bis“ mit 31.12.2031 vorbelegt.
- AK3: Gegeben die Lizenz TCSPI von Toni Muster, wenn die Geschäftsstelle „Verlängern“ mit Datum 01.11.2027 und letzter Fortbildung 01.11.2027 wählt, dann entsteht eine neue Lizenz (gleiche Qualifikationsart und Lizenznummer, gültig bis 31.12.2031, erworben bzw. verlängert am 01.11.2027); die alte endet am 31.10.2027; optional wird eine Fortbildung (Jahr 2027) angelegt.
- AK4 (Fehler): Gegeben eine historische Qualifikationsart, dann ist sie bei Neuanlage nicht wählbar; ein direkter Schreibversuch liefert „Diese Qualifikationsart ist historisch und kann nicht neu vergeben werden.“
- AK5: Gegeben Qualifikation mit Qualifikationsart ohne Gültigkeitsdauer (z. B. Zusatzqualifikation Sportklettern Outdoor), dann bleibt „gültig bis“ leer.
- AK6 (Rechte): Gegeben Referent:in, dann darf sie Lizenzen für Personen ihres Referats erfassen und verlängern, nicht für Anton Muster.
**Nicht Teil dieser Story:** Abgleich mit dem Bundesverband, Ablaufmarkierung (US-EA-11), DOSB-Ablaufmarkierung.

### US-EA-08: Ehrenamtsstatus ändern
**Als** Geschäftsstelle oder Referent:in
**möchte ich** eine Person auf „ruhend“ oder wieder auf „aktiv“ setzen,
**damit** die Übersicht den tatsächlichen Stand zeigt.
**Priorität:** Must · **Regeln:** R7, R33 AD · **Abhängig von:** US-EA-04, Administration T39
**Akzeptanzkriterien**
- AK1: Gegeben Geschäftsstelle bei Toni Muster, wenn sie „Status ändern“ → „ruhend“ ab 01.11.2026 speichert, dann zeigt das Detail „ruhend seit 01.11.2026“ und die Historie einen neuen Eintrag mit wer und wann.
- AK2: Gegeben Referent:in Klettern bei Karl Zweireferat (auch Referat Ausbildung), wenn sie „ruhend“ wählt, dann erscheint vor dem Speichern „Die Person ist auch in Ausbildung tätig. Der Status gilt für alle Referate.“ mit „Bestätigen“ und „Abbrechen“.
- AK3: Gegeben Anton Muster (ruhend), wenn die Geschäftsstelle „aktiv“ ab heute setzt, dann erscheint er wieder als aktiv.
- AK4 (Fehler): Gegeben ein Datum in der Zukunft von mehr als einem Jahr, dann „Bitte ein Datum bis spätestens <heute + 1 Jahr> wählen.“ [ANNAHME]
- AK5 (Rechte): Gegeben Referent:in Klettern ruft `ea_set_volunteer_status` für Anton Muster auf, dann Fehler „Du darfst den Status dieser Person nicht ändern.“
**Nicht Teil dieser Story:** „ausgeschieden“ (US-EA-09), Rückkehr Ausgeschiedener (US-EA-10).

### US-EA-09: Ausscheiden
**Als** Geschäftsstelle oder Referent:in
**möchte ich** eine Person auf „ausgeschieden“ setzen und dabei laufende Zuordnungen beenden,
**damit** nichts vergessen wird (Ämter, Schlüssel, Zugänge).
**Priorität:** Must · **Regeln:** R7, R8, R33 AD, R34 AD, R41 AD · **Abhängig von:** US-EA-08
**Akzeptanzkriterien**
- AK1: Gegeben Geschäftsstelle bei Sven Schlüssel, wenn sie „ausgeschieden“ ab 31.12.2026 wählt, dann listet der Dialog die laufende Funktion Helfer:in (Klettern) vorausgewählt zum Beenden und zeigt die Hinweise „Schlüssel K4 – nicht zurückgegeben“ und „Zugang extern DAV360 – läuft“.
- AK2: Gegeben der Nutzer bestätigt, dann ist der Status „ausgeschieden seit 31.12.2026“ und die ausgewählten Eigenschaften haben „gültig bis“ 31.12.2026; abgewählte bleiben unverändert.
- AK3 (Rechte): Gegeben Referent:in Klettern bei Karl Zweireferat, dann ist nur die Funktion im Referat Klettern auswählbar; die Funktion im Referat Ausbildung erscheint als „wird nicht beendet (anderes Referat)“; zusätzlich gilt AK2 aus US-EA-08.
- AK4: Gegeben Gruppen-Funktionen, dann erscheinen sie nur als Hinweis „im Modul Gruppen beenden“.
- AK5 (Rechte): Gegeben die Person ist ausgeschieden, dann verschwindet sie aus der Sicht der Referent:in; die Geschäftsstelle findet sie über den Statusfilter.
- AK6 (Fehler): Gegeben das Beenden einer Eigenschaft schlägt fehl, dann bleibt der Status unverändert und es erscheint „Etwas ist schiefgelaufen. Bitte versuche es erneut.“ (Status und Beenden in einer Transaktion [ANNAHME]).
**Nicht Teil dieser Story:** Sperren des Zugangs (Administration), Löschen.

### US-EA-10: Rückkehr und Übernahme
**Als** Geschäftsstelle oder Referent:in
**möchte ich** ausgeschiedene Personen wieder aktivieren und Personen aus anderen Modulen übernehmen,
**damit** kein Mensch doppelt angelegt wird.
**Priorität:** Must · **Regeln:** R3 AD, R33 AD, R40 AD · **Abhängig von:** US-EA-05, Administration T39
**Akzeptanzkriterien**
- AK1: Gegeben Referent:in Klettern legt „Olga“ „Ausgeschieden“ an, wenn der Dublettendialog den Treffer „ausgeschieden seit 30.06.2025“ zeigt und sie „Wieder aktivieren“ mit Funktion Trainer:in im Referat Klettern wählt, dann ist Olga wieder „aktiv“ ab heute, die Historie bleibt, und es entsteht keine neue Person.
- AK2: Gegeben Treffer Paul Nurgruppe (ohne Ehrenamtsstatus), wenn die Geschäftsstelle „Ins Ehrenamtsmanagement übernehmen“ mit Funktion Helfer:in wählt, dann erscheint Paul in der Übersicht als aktiv.
- AK3: Gegeben Geschäftsstelle bei Olga (über Statusfilter), wenn sie „Status ändern“ → „aktiv“ wählt, dann ist Olga aktiv ohne neue Zuordnung.
- AK4 (Rechte): Gegeben Referent:in, dann zeigt der Dublettendialog bei nicht sichtbaren Treffern nur Vorname, Rufname, Nachname und ggf. „ausgeschieden seit“, keine Eigenschaften.
- AK5 (Fehler): Gegeben „Wieder aktivieren“ ohne Funktion oder Amt durch Referent:in, dann „Bitte eine Funktion oder ein Amt in deinem Referat angeben.“
**Nicht Teil dieser Story:** Zusammenführen von Dubletten.

### US-EA-11: Ablaufstatus anzeigen
**Als** Geschäftsstelle oder Referent:in
**möchte ich** abgelaufene und bald ablaufende Qualifikationen markiert sehen,
**damit** ich rechtzeitig an Fortbildungen erinnern kann.
**Priorität:** Must · **Regeln:** R9, R10, R14 · **Abhängig von:** US-EA-04, US-EA-07
**Akzeptanzkriterien**
- AK1: Gegeben Lena Lizenz (gültig bis in 2 Monaten), dann zeigt das Detail an der Lizenz „läuft in ≤ 3 Monaten ab“ und die Übersicht diesen Status.
- AK2: Gegeben Max Abgelaufen (gültig bis 31.12.2025), dann zeigt die Lizenz „abgelaufen“ und die Person das Kennzeichen „Trainer:in ohne gültige Lizenz“; die Funktion bleibt bestehen.
- AK3: Gegeben Führungszeugnis-Einsicht mit Ausstellungsdatum vor 2 Jahren und 10 Monaten, dann „läuft in ≤ 3 Monaten ab“ (Ablauf = Ausstellungsdatum + 3 Jahre).
- AK4: Gegeben eine beendete Lizenz oder eine ausgeschiedene Person, dann keine Markierung.
- AK5 (Rechte): Gegeben Referent:in, dann sieht sie keine Markierung zur Führungszeugnis-Einsicht (Lesestufe „nur Geschäftsstelle und Admin“).
**Nicht Teil dieser Story:** E-Mail vor Ablauf (Schnittstellen-Connector, nach MVP), DOSB-Ablauf.

### US-EA-12: Stichtagsliste
**Als** Geschäftsstelle
**möchte ich** zum 1. Oktober alle Qualifikationen sehen und exportieren, die im Folgejahr ablaufen,
**damit** ich Fortbildungen planen und die Referate informieren kann.
**Priorität:** Must · **Regeln:** R11 · **Abhängig von:** US-EA-11
**Akzeptanzkriterien**
- AK1: Gegeben Seite „Ablauf“, dann ist das Jahr mit dem Folgejahr vorbelegt und die Liste zeigt je Qualifikation Name, Referate, Qualifikationsart (Kürzel – Bezeichnung), gültig bis, Ablaufstatus; sortiert nach gültig bis, dann Name.
- AK2: Gegeben Jahr 2027, dann erscheint Toni Muster mit TCSPI, gültig bis 31.12.2027.
- AK3: Gegeben Geschäftsstelle, wenn sie „CSV exportieren“ wählt, dann erhält sie eine Datei `ablauf-<jahr>.csv` (UTF-8, Semikolon) mit Name, Referate, Kürzel, Bezeichnung, gültig bis – ohne Kontaktdaten.
- AK4 (Rechte): Gegeben Referent:in, dann sieht sie nur Personen ihrer Referate und keinen Export-Knopf.
- AK5 (leer): Gegeben kein Ablauf im Jahr, dann „Im Jahr <jahr> läuft keine Qualifikation ab.“
**Nicht Teil dieser Story:** automatische Erinnerung, konfigurierbarer Stichtag.

### US-EA-13: Gremium-Sichten
**Als** Geschäftsstelle
**möchte ich** je Gremium die aktuellen Mitglieder sehen,
**damit** ich die Zusammensetzung von Vorstand, Beirat, Ehrenrat und Jugendausschuss kenne.
**Priorität:** Should · **Regeln:** R38 AD · **Abhängig von:** US-EA-06, US-EA-16
**Akzeptanzkriterien**
- AK1: Gegeben Seite „Gremien“, dann zeigt sie je aktivem Gremium die heute gültigen Mitgliedschaften mit Name, Rolle, seit, bis.
- AK2: Gegeben Greta Gremium (Beirat, Mitglied), dann erscheint sie unter Beirat; ein Klick öffnet ihr Detail.
- AK3: Gegeben Gremium ohne Mitglieder, dann „Keine Mitglieder eingetragen.“
- AK4 (Rechte): Gegeben Referent:in, dann keine Seite „Gremien“ (US-EA-01 AK5); eine Gremium-Mitgliedschaft anlegen ist für sie nicht möglich.
**Nicht Teil dieser Story:** Pflege der Mitgliedschaft (über Personendetail, US-EA-06), Amtszeiten-Erinnerung.

### US-EA-14: Referate und Gremien pflegen
**Als** Geschäftsstelle oder Admin
**möchte ich** Referate und Gremien anlegen, umbenennen und inaktiv setzen,
**damit** die Stammdaten der Organisation stimmen.
**Priorität:** Should · **Regeln:** R12 AD, R38 AD · **Abhängig von:** Administration T34
**Akzeptanzkriterien**
- AK1: Gegeben Seite „Referate und Gremien“, dann zwei Listen mit Bezeichnung, Reihenfolge, Status (aktiv/inaktiv).
- AK2: Gegeben ein neues Referat „Naturschutz“, wenn gespeichert, dann ist es in Zuordnungen wählbar.
- AK3 (Fehler): Gegeben eine bereits vorhandene Bezeichnung (ohne Groß-/Kleinschreibung), dann „Diese Bezeichnung gibt es bereits.“
- AK4: Gegeben ein inaktives Referat, dann ist es nicht neu wählbar; vorhandene Zuordnungen bleiben sichtbar.
- AK5 (Rechte): Gegeben Referent:in, dann kein Zugriff (/kein-zugriff).
**Nicht Teil dieser Story:** Löschen.

### US-EA-15: Eigenschaftsarten und Qualifikationsarten im Ehrenamtsmanagement
**Als** Geschäftsstelle
**möchte ich** Eigenschaftsarten und Qualifikationsarten im Ehrenamtsmanagement pflegen,
**damit** ich neue Angaben ohne Code-Änderung und ohne Rechte auf die Administration ergänze.
**Priorität:** Must · **Regeln:** R9 AD, R21–R29 AD, R36 AD · **Abhängig von:** Administration T30, T46, Ü1
**Akzeptanzkriterien**
- AK1: Gegeben Geschäftsstelle, dann sind die Seiten der Administration unter /ea/eigenschaftsarten und /ea/qualifikationsarten mit denselben Funktionen erreichbar (Komponenten der Administration).
- AK2: Gegeben neue Eigenschaftsart „Schlüssel Materiallager“ mit Feld „Nummer“ (Text), Kategorie Ausgaben, Bezeichnungen „ausgegeben am / zurückgegeben am“, Lesestufe „alle“, wenn gespeichert, dann ist sie bei „Eigenschaft hinzufügen“ wählbar.
- AK3: Gegeben eine System-Eigenschaftsart, dann ist `system_key` nicht sichtbar änderbar; Felder und Auswahlwerte können ergänzt werden.
- AK4 (Rechte): Gegeben Geschäftsstelle, dann ist die Lesestufe „vertraulich“ nicht wählbar („Nur mit Rechten auf die Administration möglich.“).
- AK5 (Rechte): Gegeben Referent:in, dann kein Zugriff.
**Nicht Teil dieser Story:** neue Logik der Formulare (Administration).

### US-EA-16: Startbestand System-Eigenschaftsarten und Qualifikationsarten
**Als** Admin
**möchte ich**, dass die erste Migration des Ehrenamtsmanagements die System-Eigenschaftsarten und fehlenden Qualifikationsarten anlegt,
**damit** TEST und PROD denselben Startbestand haben und andere Module sich auf die Schlüssel verlassen können.
**Priorität:** Must · **Regeln:** – (01-erhebung.md C2, C2a, C4) · **Abhängig von:** Administration T27, T35, Ü1
**Akzeptanzkriterien**
- AK1: Gegeben eine leere Datenbank nach den Migrationen der Administration, wenn die Migration läuft, dann existieren 25 Eigenschaftsarten mit `origin = 'system'`, den `system_key`, Feldschlüsseln, Kategorien, Lesestufen, Bezügen und Bezeichnungen aus C2/C2a.
- AK2: Gegeben die Migration läuft zweimal, dann ändert sich nichts (idempotent über `system_key`, ohne Überschreiben von Änderungen aus der Oberfläche).
- AK3: Gegeben die Migration, dann existieren die Qualifikationsarten EH, RS und acht Aufbaumodule nach C4, idempotent über die Bezeichnung.
- AK4: Gegeben die Eigenschaftsart `license`, dann hat sie die Felder `qualification_type` (nur Typ Lizenz, Pflicht) und `valid_until` (Pflicht) – Voraussetzung für `ea_person_licenses` (Administration v0.9).
- AK5 (Fehler): Gegeben eine Eigenschaftsart gleichen Namens existiert schon ohne `system_key`, dann bricht die Migration mit klarer Meldung ab („Eigenschaftsart <Name> existiert bereits ohne system_key.“) [ANNAHME].
**Nicht Teil dieser Story:** Testdaten (US-EA-19).

### US-EA-17: Migration: Probelauf mit Prüfbericht
**Als** Admin
**möchte ich** die bereinigte CSV der Aktivenliste prüfen lassen, ohne etwas zu schreiben,
**damit** ich Fehler vor dem Lauf gegen PROD korrigieren kann.
**Priorität:** Must · **Regeln:** R15, R16, R17, R13 · **Abhängig von:** US-EA-16
**Akzeptanzkriterien**
- AK1: Gegeben eine CSV nach Vorlage C3, wenn der Admin `npm run ea:migrate -- --file <pfad> --dry-run` mit Verbindung zu einer Datenbank ausführt, dann wird nichts geschrieben und ein Prüfbericht `<datei>.pruefbericht.md` neben der CSV erzeugt.
- AK2: Gegeben eine Zeile mit unbekanntem Kürzel in `l1_art`, dann listet der Bericht „Zeile <n>: Qualifikationsart <wert> unbekannt“ als Fehler.
- AK3: Gegeben Personen mit ähnlichem Namen zu vorhandenen Personen oder innerhalb der Datei, dann listet der Bericht „Dublettenverdacht“ (Warnung).
- AK4: Gegeben der Bericht, dann enthält er zusätzlich: Personen mit mehr Lizenzen als Lizenznummern, ungültige Daten und IBAN, Werte aus `gruppe`/`gruppenleitung`, Anzahl Eigenschaften je Art, Anzahl Einträge mit „gültig von“ = Stichtag.
- AK5 (Fehler): Gegeben fehlende Pflichtspalte in der Kopfzeile, dann Abbruch „Spalte <name> fehlt.“ ohne Bericht.
- AK6: Gegeben die fiktive Beispiel-CSV aus dem Repository, dann läuft der Probelauf gegen TEST fehlerfrei (Entwicklung nur mit fiktiven Daten).
**Nicht Teil dieser Story:** Schreiben (US-EA-18), Excel lesen.

### US-EA-18: Migration: Lauf gegen PROD
**Als** Admin
**möchte ich** die geprüfte CSV in PROD übernehmen,
**damit** die Excel-Liste eingefroren und archiviert werden kann.
**Priorität:** Must · **Regeln:** R15, R16, R17, R27 AD · **Abhängig von:** US-EA-17
**Akzeptanzkriterien**
- AK1: Gegeben ein Probelauf ohne Fehler, wenn der Admin `npm run ea:migrate -- --file <pfad> --run` ausführt und die Rückfrage mit dem Namen des Supabase-Projekts bestätigt, dann werden Personen, Ehrenamtsstatus und Eigenschaften nach C3 angelegt (`created_in = 'script'`).
- AK2: Gegeben Fehler im Probelauf, dann startet der Lauf nicht („Probelauf hat Fehler. Lauf abgebrochen.“).
- AK3: Gegeben ein Fehler während des Laufs, dann wird nichts geschrieben (eine Transaktion für den ganzen Lauf [ANNAHME]).
- AK4: Gegeben eine Zeile mit `aktiv = nein`, zwei Referaten und einer abgelaufenen Lizenz, dann entstehen: Status „ruhend“ ab Stichtag, je Referat Funktion „Trainer:in“ ab `aktiv_seit`, Lizenz mit historischer oder aktueller Qualifikationsart.
- AK5: Gegeben der Lauf ist fertig, dann enthält ein Abschlussbericht die Anzahl angelegter Personen und Eigenschaften je Art; die CSV-Dateien liegen nie im Repository (`.gitignore` für `*.csv` im Migrationsordner außer `beispiel.csv`).
- AK6 (Rechte): Gegeben der Admin gibt bei der verdeckten Abfrage keinen Schlüssel mit vollen Rechten (Secret Key) ein, dann Abbruch „Schlüssel fehlt.“; der Schlüssel steht nie in einer Datei, im Bericht oder in der Ausgabe.
**Nicht Teil dieser Story:** Karteileichen, weitere Listen (nach MVP; das Skript ist wiederverwendbar).

### US-EA-19: Testdaten des Ehrenamtsmanagements
**Als** Product Owner
**möchte ich** in TEST fiktive Aktive für alle Fälle des Ehrenamtsmanagements,
**damit** ich jede Story mit den Testzugängen abnehmen kann.
**Priorität:** Must · **Regeln:** – · **Abhängig von:** US-EA-16, Administration T48
**Akzeptanzkriterien**
- AK1: Gegeben `supabase/seed.sh`, dann verwenden die Seed-Personen der Administration die System-Eigenschaftsarten (Funktion, Amt, Lizenz, Geburtsdatum, Kontaktdaten) statt der Testarten mit demselben `system_key` (Übergabe Ü3).
- AK2: Gegeben der Seed, dann existieren zusätzlich die Personen 19–22 nach Spec Abschnitt 9 mit relativen Datumswerten (z. B. Lizenz von Lena Lizenz gültig bis heute + 2 Monate).
- AK3: Gegeben der Seed läuft gegen PROD, dann Abbruch (bestehende Sperre der Administration).
- AK4: Gegeben der Seed, dann enthält er nur fiktive Namen und Adressen.
**Nicht Teil dieser Story:** neue Testzugänge (bestehende reichen).

## Annahmen der Stories

Bestätigt vom Product Owner am 22.10.2026 (Kennzeichen [ANNAHME] bleibt zur Nachvollziehbarkeit im Text der Stories):

- A1: Status-Datum höchstens ein Jahr in der Zukunft (US-EA-08 AK4).
- A2: Ausscheiden und Beenden der Eigenschaften in einer Transaktion über eine Datenbankfunktion des Ehrenamtsmanagements (US-EA-09 AK6).
- A3: Migration in einer Transaktion für den ganzen Lauf (US-EA-18 AK3; ersetzt „je Person“ in R16 der Erhebung).
- A4: Aufruf des Migrationsskripts über `npm run ea:migrate` mit Bestätigung des Projektnamens.
- A5: Filter bleiben in der URL erhalten; 50 Einträge je Seite.
- A6: Navigation des Moduls wie in US-EA-01 AK2/AK3.
- A7: Abbruch der Migration der System-Eigenschaftsarten bei Namenskonflikt (US-EA-16 AK5).
