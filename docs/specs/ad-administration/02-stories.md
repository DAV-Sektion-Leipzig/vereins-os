# User Stories: Administration (AD)

Stand: 19.10.2026 · Version 0.2 · Status: Ready · Product Owner: Toni Werner
Grundlage: 00-steckbrief.md v0.9, 01-erhebung.md v0.4 (Regeln R1–R19), glossar.md v0.4, rollen.md v0.6, spec.md v0.1

Oberflächentexte in der Ansprache „du“.

## Übersicht

| ID | Titel | Priorität | Abhängig von |
|---|---|---|---|
| US-AD-01 | Ersteinrichtung PROD (Admin, Vorlagen, Notfall-Admin) | Must | – |
| US-AD-02 | Anmelden und abmelden | Must | US-AD-01 |
| US-AD-03 | Einladung annehmen und Passwort setzen | Must | US-AD-08 |
| US-AD-04 | Passwort vergessen | Must | US-AD-02 |
| US-AD-05 | Startseite mit Modulen nach Rechten | Must | US-AD-02 |
| US-AD-06 | Übersicht Personen und Zugänge | Must | US-AD-01 |
| US-AD-07 | Person anlegen mit Dublettenwarnung | Must | US-AD-06 |
| US-AD-08 | Zugang einrichten und einladen | Must | US-AD-07, US-AD-11 |
| US-AD-09 | Zugang sperren und entsperren | Must | US-AD-08 |
| US-AD-10 | Rechtevorlage anlegen und ändern | Must | US-AD-01 |
| US-AD-11 | Rechtevorlage zuweisen und entziehen | Must | US-AD-10 |
| US-AD-12 | Eigenschaftsart anlegen und ändern | Must | US-AD-01 |
| US-AD-13 | Eigenschaften einer Person pflegen | Must | US-AD-12 |
| US-AD-14 | Protokoll einsehen | Should | US-AD-08 |
| US-AD-15 | Notfall-Admin nutzen und nachvollziehen | Must | US-AD-01, US-AD-14 |
| US-AD-16 | Testzugänge in TEST | Must | US-AD-01 |

Empfohlene Umsetzungsreihenfolge: 01 → 10 → 02 → 05 → 06 → 07 → 12 → 13 → 11 → 08 → 03 → 04 → 09 → 14 → 15 → 16.

---

### US-AD-01: Ersteinrichtung PROD
**Als** Admin
**möchte ich**, dass beim ersten Aufsetzen von PROD mein Zugang, die Start-Rechtevorlagen und der Notfall-Admin vorhanden sind,
**damit** ich ohne vorhandenen Admin überhaupt starten kann.
**Priorität:** Must · **Regeln:** R6, R14, R15 · **Abhängig von:** –
**Akzeptanzkriterien**
- AK1: Gegeben eine leere Datenbank, wenn die Migrationen laufen, dann gibt es die Rechtevorlagen „Admin“ (AD, SC, EA verwalten), „Geschäftsstelle“ (EA, GR, FI, OA, PM, GS, AM verwalten) und „Vorstand“ (überall kein Zugriff).
- AK2: Gegeben die Migrationen sind gelaufen, wenn das Einrichtungsskript für PROD ausgeführt wird, dann existieren die Person Toni Werner mit Zugang (Login-Adresse als Parameter, Vorlagen Admin und Vorstand) und die Funktionsperson „Geschäftsstelle / Notfall-Admin“ mit Zugang geschaeftsstelle@dav-leipzig.de und Vorlage Admin, beide im Status „kein Zugang“. Die erste Einladung (Toni Werner) erfolgt einmalig über das Supabase-Dashboard, alle weiteren über US-AD-08.
- AK3: Gegeben das Einrichtungsskript wurde schon ausgeführt, wenn es erneut läuft, dann entstehen keine doppelten Personen, Zugänge oder Vorlagen (Fehlerfall).
- AK4: Gegeben ein Nutzer ohne AD-Rechte, wenn er versucht, die Vorlage „Admin“ zu ändern, dann lehnt die Datenbank ab (Rechte-Fall).
**Nicht Teil dieser Story:** Testdaten in TEST (US-AD-16); Konfiguration der Vorlage Vorstand.

### US-AD-02: Anmelden und abmelden
**Als** Nutzer mit beliebiger Rechtevorlage
**möchte ich** mich mit Login-Adresse und Passwort an- und abmelden,
**damit** ich das Vereins OS nutzen kann und niemand sonst an meinem Gerät.
**Priorität:** Must · **Regeln:** R5, R10, R18 · **Abhängig von:** US-AD-01
**Akzeptanzkriterien**
- AK1: Gegeben ein Zugang im Status „aktiv“, wenn ich Login-Adresse und richtiges Passwort eingebe, dann lande ich auf der Startseite.
- AK2: Gegeben ein falsches Passwort oder eine unbekannte Adresse, wenn ich mich anmelde, dann erscheint „Anmeldung fehlgeschlagen. Bitte E-Mail-Adresse und Passwort prüfen.“ (Fehlerfall).
- AK3: Gegeben ein Zugang im Status „gesperrt“, wenn ich mich mit richtigem Passwort anmelde, dann erscheint dieselbe Meldung wie in AK2 und ich bin nicht angemeldet (Rechte-Fall, R10, R18).
- AK4: Gegeben ich bin angemeldet, wenn ich „Abmelden“ wähle, dann bin ich abgemeldet und lande auf der Login-Seite.
- AK5: Gegeben ich bin nicht angemeldet, wenn ich eine interne Seite direkt aufrufe, dann werde ich zur Login-Seite geleitet.
**Nicht Teil dieser Story:** Selbstregistrierung (gibt es nicht); SSO; „Passwort vergessen“ (US-AD-04).

### US-AD-03: Einladung annehmen und Passwort setzen
**Als** eingeladene Person
**möchte ich** über den Link in der Einladung mein Passwort selbst setzen,
**damit** ich meinen Zugang nutzen kann, ohne dass jemand anderes mein Passwort kennt.
**Priorität:** Must · **Regeln:** R19 · **Abhängig von:** US-AD-08
**Akzeptanzkriterien**
- AK1: Gegeben ein Zugang im Status „eingeladen“, wenn ich den Link öffne und ein Passwort mit mindestens 8 Zeichen zweimal gleich eingebe, dann ist der Zugang „aktiv“ und ich lande auf der Startseite.
- AK2: Gegeben ein Passwort mit weniger als 8 Zeichen, wenn ich speichere, dann erscheint „Das Passwort muss mindestens 8 Zeichen lang sein.“ (Fehlerfall).
- AK3: Gegeben ein abgelaufener oder bereits benutzter Link, wenn ich ihn öffne, dann erscheint „Der Link ist abgelaufen oder ungültig. Bitte wende dich an den Admin.“ (Fehlerfall).
- AK4: Gegeben der Zugang wurde nach dem Versand gesperrt, wenn ich den Link öffne, dann kann ich kein Passwort setzen und erhalte dieselbe Meldung wie in AK3 (Rechte-Fall).
- AK5: Die Einladungs-Mail enthält nur Empfängeradresse, einen kurzen Hinweistext und den Link, keine weiteren Personendaten.
**Nicht Teil dieser Story:** Versand der Einladung (US-AD-08).

### US-AD-04: Passwort vergessen
**Als** Nutzer mit beliebiger Rechtevorlage
**möchte ich** mein Passwort selbst über einen Link per E-Mail zurücksetzen,
**damit** ich ohne den Admin wieder Zugang bekomme.
**Priorität:** Must · **Regeln:** R18, R19, R10 · **Abhängig von:** US-AD-02
**Akzeptanzkriterien**
- AK1: Gegeben ich gebe auf „Passwort vergessen“ eine Login-Adresse ein, wenn ich absende, dann erscheint immer „Wenn ein Zugang zu dieser Adresse besteht, haben wir dir eine E-Mail mit einem Link geschickt.“ – unabhängig davon, ob die Adresse existiert (R18).
- AK2: Gegeben ein aktiver Zugang, wenn ich den Link öffne und ein neues Passwort mit mindestens 8 Zeichen setze, dann kann ich mich mit dem neuen Passwort anmelden.
- AK3: Gegeben ein abgelaufener Link, wenn ich ihn öffne, dann erscheint „Der Link ist abgelaufen oder ungültig. Bitte fordere einen neuen an.“ (Fehlerfall).
- AK4: Gegeben ein gesperrter Zugang, wenn ich das Passwort zurücksetze, dann bleibt der Zugang gesperrt und eine Anmeldung ist nicht möglich (Rechte-Fall).
**Nicht Teil dieser Story:** Zurücksetzen durch den Admin.

### US-AD-05: Startseite mit Modulen nach Rechten
**Als** Nutzer mit beliebiger Rechtevorlage
**möchte ich** nach dem Login eine Startseite sehen, die nur die Module zeigt, für die ich Rechte habe,
**damit** ich mich schnell zurechtfinde und nicht auf Bereiche stoße, die ich nicht nutzen darf.
**Priorität:** Must · **Regeln:** R5, R6 · **Abhängig von:** US-AD-02
**Akzeptanzkriterien**
- AK1: Gegeben ich habe die Vorlage Admin, wenn ich die Startseite öffne, dann sehe ich die Willkommensgrafik und einen Einstieg zu AD; Einstiege zu Modulen, die noch nicht umgesetzt sind, werden nicht angezeigt.
- AK2: Gegeben ich habe nur die Vorlage Vorstand ohne Rechte, wenn ich die Startseite öffne, dann sehe ich die Willkommensgrafik und den Hinweis „Für dich sind noch keine Module freigeschaltet.“
- AK3: Gegeben ich habe keine Rechte auf AD, wenn ich eine AD-Seite direkt über die Adresse aufrufe, dann erscheint „Für diesen Bereich hast du keine Rechte.“ und es werden keine Daten geladen (Rechte-Fall).
- AK4: Gegeben mir wurde eine Vorlage entzogen, wenn meine laufende Sitzung abläuft (spätestens nach 1 Stunde), dann zeigt die Startseite das Modul nicht mehr (Fehlerfall: veraltete Sitzung).
- AK5: Die Startseite ist ab 375 px Breite ohne horizontales Scrollen nutzbar.
**Nicht Teil dieser Story:** Inhalte der Fachmodule; Dashboard.

### US-AD-06: Übersicht Personen und Zugänge
**Als** Admin
**möchte ich** in AD eine Liste aller Personen mit Zugangsstatus und Rechtevorlagen sehen und nach Namen suchen,
**damit** ich gezielt Personen einladen, sperren und pflegen kann – auch die aus dem Import.
**Priorität:** Must · **Regeln:** R11, R15 · **Abhängig von:** US-AD-01
**Akzeptanzkriterien**
- AK1: Gegeben es gibt Personen, wenn ich die Übersicht öffne, dann sehe ich je Person Vorname, Nachname, Login-Adresse (falls vorhanden), Zugangsstatus (kein Zugang / eingeladen / aktiv / gesperrt) und zugewiesene Vorlagen.
- AK2: Gegeben die Übersicht, wenn ich nach Zugangsstatus filtere oder einen Namensteil eingebe, dann sehe ich nur passende Personen.
- AK3: Gegeben die Funktionsperson „Geschäftsstelle“, wenn ich die Übersicht öffne, dann ist sie als „Funktionsperson“ gekennzeichnet.
- AK4: Gegeben keine Person passt zum Filter, wenn ich suche, dann erscheint „Keine Personen gefunden.“ (leerer Zustand / Fehlerfall).
- AK5: Gegeben ein Nutzer mit der Vorlage Geschäftsstelle, wenn er die Übersicht aufruft oder Zugänge per Datenbankabfrage liest, dann erhält er keine Daten (Rechte-Fall).
**Nicht Teil dieser Story:** Filter aktiv/ausgeschieden nach Eigenschaften (EA); Export.

### US-AD-07: Person anlegen mit Dublettenwarnung
**Als** Admin
**möchte ich** eine Person mit Vorname und Nachname anlegen und vor ähnlichen vorhandenen Personen gewarnt werden,
**damit** keine Dubletten entstehen.
**Priorität:** Must · **Regeln:** R3, R4, R1, R2 · **Abhängig von:** US-AD-06
**Akzeptanzkriterien**
- AK1: Gegeben ich gebe Vorname und Nachname ein und es gibt keine ähnliche Person, wenn ich speichere, dann ist die Person angelegt mit Art „Mensch“ und Status „kein Zugang“; angelegt am/von sind gesetzt.
- AK2: Gegeben Vorname oder Nachname fehlt, wenn ich speichere, dann erscheint „Bitte Vorname und Nachname angeben.“ und nichts wird gespeichert (Fehlerfall).
- AK3: Gegeben es existiert „Toni Werner“, wenn ich „Anton Werner“ anlege oder eine bereits vorkommende E-Mail-Adresse eingebe, dann erscheint eine Warnung mit den ähnlichen Personen und den Optionen „Trotzdem anlegen“, „Vorhandene Person öffnen“ und „Abbrechen“.
- AK4: Gegeben ich wähle „Trotzdem anlegen“, wenn ich bestätige, dann wird die Person angelegt.
- AK5: Gegeben ich gebe optional eine Login-Adresse ein, wenn sie nicht auf @dav-leipzig.de endet oder bereits vergeben ist, dann erscheinen die Meldungen aus R1 bzw. R2 (Fehlerfall).
- AK6: Gegeben ein Nutzer ohne AD-Rechte, wenn er per Datenbankaufruf eine Person über AD anlegen will, dann lehnt die Datenbank ab; Personen anlegen ist nur mit AD- oder EA-Rechten mindestens „bearbeiten“ erlaubt (Rechte-Fall).
**Nicht Teil dieser Story:** Excel-Import, Dublettenprüfliste und Zusammenführen (EA); Löschen.

### US-AD-08: Zugang einrichten und einladen
**Als** Admin
**möchte ich** einer Person eine Login-Adresse geben und sie auf Knopfdruck einladen bzw. erneut einladen,
**damit** sie ihren Zugang selbst aktivieren kann und nie automatisch Einladungen verschickt werden.
**Priorität:** Must · **Regeln:** R1, R2, R11, R13, R17 · **Abhängig von:** US-AD-07, US-AD-11
**Akzeptanzkriterien**
- AK1: Gegeben eine Person mit gültiger Login-Adresse und mindestens einer Vorlage, wenn ich „Einladen“ klicke, dann verschickt Supabase Auth die Einladung, der Status wird „eingeladen“, „zuletzt eingeladen am“ wird gesetzt und ein Protokolleintrag „eingeladen“ entsteht.
- AK2: Gegeben eine Person ohne zugewiesene Vorlage, wenn ich einladen will, dann ist „Einladen“ nicht möglich und es erscheint „Bitte zuerst mindestens eine Rechtevorlage zuweisen.“ (Fehlerfall, R17).
- AK3: Gegeben eine Login-Adresse, die nicht auf @dav-leipzig.de endet, wenn ich speichere, dann erscheint „Zugang nur mit Adresse @dav-leipzig.de möglich.“; ist sie bereits vergeben, erscheint „Diese Login-Adresse ist bereits vergeben.“ (Fehlerfall, R1, R2).
- AK4: Gegeben der Status ist „eingeladen“, wenn ich „Erneut einladen“ klicke, dann wird eine neue Einladung verschickt, „zuletzt eingeladen am“ aktualisiert und protokolliert.
- AK5: Gegeben der Mailversand schlägt fehl, wenn ich einlade, dann erscheint „Die Einladung konnte nicht verschickt werden. Bitte später erneut versuchen.“ und der Status bleibt unverändert (Fehlerfall).
- AK6: Gegeben ein Aufrufer ohne AD-Rechte, wenn er die Edge Function „Nutzer einladen“ aufruft, dann lehnt sie ohne Einladung ab (Rechte-Fall).
**Nicht Teil dieser Story:** automatische Einladung beim Anlegen oder Import; Annahme der Einladung (US-AD-03).

### US-AD-09: Zugang sperren und entsperren
**Als** Admin
**möchte ich** einen Zugang sperren und wieder entsperren,
**damit** ausgeschiedene Personen keinen Zugriff mehr haben, ihre Daten aber erhalten bleiben.
**Priorität:** Must · **Regeln:** R10, R12, R13 · **Abhängig von:** US-AD-08
**Akzeptanzkriterien**
- AK1: Gegeben ein Zugang „aktiv“ oder „eingeladen“, wenn ich „Sperren“ wähle und bestätige, dann ist der Status „gesperrt“, gesperrt am/von ist gesetzt, ein Protokolleintrag entsteht und eine neue Anmeldung ist nicht möglich.
- AK2: Gegeben ein gesperrter Zugang, dessen Person schon ein Passwort gesetzt hatte, wenn ich „Entsperren“ wähle, dann ist der Status „aktiv“ und protokolliert.
- AK3: Gegeben ein gesperrter Zugang ohne gesetztes Passwort, wenn ich entsperre, dann ist der Status „eingeladen“ und ich kann erneut einladen.
- AK4: Gegeben ein Nutzer ist angemeldet, wenn ich seinen Zugang sperre, dann endet sein Zugriff spätestens mit Ablauf der Sitzung (bis zu 1 Stunde); ein Hinweis beim Sperren nennt dies.
- AK5: Gegeben ein Nutzer ohne AD-Rechte, wenn er einen Zugang sperren will, dann lehnt das System ab (Rechte-Fall).
- AK6: Beim Sperren wird nichts gelöscht; Eigenschaften und Rechtevorlagen bleiben erhalten (Fehlerfall-Absicherung, R12).
**Nicht Teil dieser Story:** sofortiges Beenden laufender Sitzungen; Löschen von Zugängen; Enddatum an Eigenschaften (US-AD-13).

### US-AD-10: Rechtevorlage anlegen und ändern
**Als** Admin
**möchte ich** Rechtevorlagen mit einer Stufe je Modul anlegen und ändern,
**damit** ich Rechte ohne Code-Änderung anpassen kann, z. B. für den Vorstand.
**Priorität:** Must · **Regeln:** R6 · **Abhängig von:** US-AD-01
**Akzeptanzkriterien**
- AK1: Gegeben ich gebe einen Namen, optional eine Beschreibung und je Modul (AD, SC, EA, GR, FI, OA, PM, GS, AM) eine Stufe (kein Zugriff / lesen / bearbeiten / verwalten) an, wenn ich speichere, dann ist die Vorlage angelegt.
- AK2: Gegeben eine Vorlage mit diesem Namen existiert, wenn ich speichere, dann erscheint „Eine Rechtevorlage mit diesem Namen gibt es bereits.“ (Fehlerfall).
- AK3: Gegeben ich ändere die Stufe eines Moduls in der Vorlage Vorstand, wenn ich speichere, dann gilt sie für alle Personen mit dieser Vorlage spätestens nach Ablauf ihrer Sitzung.
- AK4: Gegeben ein Nutzer ohne AD-Rechte, wenn er eine Vorlage ändern will, dann lehnt die Datenbank ab (Rechte-Fall).
**Nicht Teil dieser Story:** Rechte je Objekt, Reichweiten, Einzelrechte; Löschen von Vorlagen.

### US-AD-11: Rechtevorlage zuweisen und entziehen
**Als** Admin
**möchte ich** einer Person eine oder mehrere Rechtevorlagen zuweisen und entziehen,
**damit** sie genau die Rechte bekommt, die sie braucht.
**Priorität:** Must · **Regeln:** R5, R6, R7, R13 · **Abhängig von:** US-AD-10
**Akzeptanzkriterien**
- AK1: Gegeben eine Person, wenn ich ihr die Vorlagen Geschäftsstelle und Vorstand zuweise, dann hat sie je Modul die höhere Stufe beider Vorlagen; jede Zuweisung wird mit zugewiesen am/von protokolliert.
- AK2: Gegeben eine zugewiesene Vorlage, wenn ich sie entziehe, dann wirkt das spätestens nach Ablauf der Sitzung und wird protokolliert.
- AK3: Gegeben die Vorlage ist der Person bereits zugewiesen, wenn ich sie erneut zuweisen will, dann wird sie nicht doppelt angelegt und nicht erneut angeboten (Fehlerfall).
- AK4: Gegeben eine Person ohne aktiven Zugang mit zugewiesener Vorlage, wenn Daten abgefragt werden, dann wirken keine Rechte (R5).
- AK5: Gegeben ein Nutzer ohne AD-Rechte, wenn er eine Vorlage zuweisen will, dann lehnt die Datenbank ab (Rechte-Fall).
**Nicht Teil dieser Story:** Befristung in der Oberfläche; Ableitung von Rechten aus Eigenschaften (R7).

### US-AD-12: Eigenschaftsart anlegen und ändern
**Als** Admin
**möchte ich** Eigenschaftsarten mit Zweck, Datentyp, „sichtbar in“ und „vertraulich“ anlegen und ändern,
**damit** ich Angaben wie Hauptamt erfassen kann, ohne die Datenstruktur zu ändern.
**Priorität:** Must · **Regeln:** R8, R9 · **Abhängig von:** US-AD-01
**Akzeptanzkriterien**
- AK1: Gegeben ich gebe Name, Zweck, Datentyp (Text / Datum / Ja/Nein / Auswahlliste), „sichtbar in“ (mind. ein Modul) und „vertraulich“ an, wenn ich speichere, dann ist die Eigenschaftsart angelegt; beim Anlegen wird der Hinweis angezeigt: „Erfasse keine Gesundheitsdaten, Religion, politische Meinung oder andere besondere Kategorien nach Art. 9 DSGVO.“
- AK2: Gegeben der Zweck fehlt oder eine Auswahlliste hat keine Auswahlwerte, wenn ich speichere, dann erscheint „Bitte einen Zweck angeben.“ bzw. „Bitte mindestens einen Auswahlwert angeben.“ (Fehlerfall, R9).
- AK3: Gegeben der Name existiert bereits, wenn ich speichere, dann erscheint „Eine Eigenschaftsart mit diesem Namen gibt es bereits.“ (Fehlerfall).
- AK4: Gegeben es gibt schon Eigenschaften dieser Art, wenn ich den Datentyp ändern will, dann erscheint „Der Datentyp kann nicht geändert werden, solange Eigenschaften dieser Art existieren.“; Auswahlwerte können ergänzt, aber nicht entfernt werden („Auswahlwerte können ergänzt, aber nicht entfernt werden.“) (Fehlerfall).
- AK5: Gegeben ein Nutzer ohne AD-Rechte (z. B. Geschäftsstelle mit EA verwalten), wenn er das Kennzeichen „vertraulich“ setzen oder ändern will, dann lehnt die Datenbank ab; „vertraulich“ setzt nur, wer AD-Rechte hat (Rechte-Fall).
**Nicht Teil dieser Story:** Löschen von Eigenschaftsarten; Oberfläche für Eigenschaftsarten in EA; weitere Datentypen (Zahl, Datei).

### US-AD-13: Eigenschaften einer Person pflegen
**Als** Admin
**möchte ich** an einer Person Eigenschaften mit Gültigkeit anlegen, ändern und beenden und frühere Werte sehen,
**damit** z. B. das Hauptamt von Denise oder ihr Ausscheiden nachvollziehbar erfasst ist.
**Priorität:** Must · **Regeln:** R7, R8, R12 · **Abhängig von:** US-AD-12
**Akzeptanzkriterien**
- AK1: Gegeben eine Person, wenn ich Eigenschaftsart, Wert (passend zum Datentyp) und gültig von angebe und speichere, dann ist die Eigenschaft angelegt; geändert am/von sind gesetzt.
- AK2: Gegeben eine bestehende Eigenschaft, wenn ich den Wert ändere oder gültig bis setze, dann bleibt die frühere Fassung mit geändert am/von in der Historie sichtbar.
- AK3: Gegeben gültig bis liegt vor gültig von oder der Wert passt nicht zum Datentyp, wenn ich speichere, dann erscheint „‚Gültig bis‘ darf nicht vor ‚gültig von‘ liegen.“ bzw. „Der Wert passt nicht zum Datentyp der Eigenschaftsart.“ (Fehlerfall).
- AK4: Gegeben eine vertrauliche Eigenschaft (z. B. Hauptamt), wenn ein Nutzer mit der Vorlage Geschäftsstelle Eigenschaften dieser Person per Oberfläche oder Datenbankabfrage liest, dann erhält er die vertrauliche Eigenschaft nicht (Rechte-Fall, R8).
- AK5: Gegeben ich gebe einer Person die Eigenschaft Hauptamt oder eine Funktion, wenn ich speichere, dann ändert sich an ihren Rechten nichts (R7).
- AK6: In der Ansicht einer Person zeigt AD alle Eigenschaftsarten, deren „sichtbar in“ AD enthält; Eigenschaften mit gültig bis in der Vergangenheit erscheinen als „beendet“.
**Nicht Teil dieser Story:** Pflege-Oberflächen, Filter und Import in EA; Löschung nach 5 Jahren (EA).

### US-AD-14: Protokoll einsehen
**Als** Admin
**möchte ich** das Protokoll der Einladungen, Rechtevergaben, Sperren und Anmeldungen des Notfall-Admins einsehen,
**damit** ich nachvollziehen kann, wer wem wann welche Rechte gegeben hat.
**Priorität:** Should · **Regeln:** R13, R16 · **Abhängig von:** US-AD-08
**Akzeptanzkriterien**
- AK1: Gegeben es gibt Protokolleinträge, wenn ich das Protokoll öffne, dann sehe ich Zeitpunkt, ausgeführt von, betroffene Person, Aktion und Details, neueste zuerst.
- AK2: Gegeben ein Eintrag ist älter als 5 Jahre, wenn der tägliche Löschlauf läuft, dann ist der Eintrag gelöscht.
- AK3: Gegeben es gibt noch keine Einträge, wenn ich das Protokoll öffne, dann erscheint „Noch keine Einträge.“ (leerer Zustand).
- AK4: Gegeben ein Nutzer (auch Admin), wenn er einen Protokolleintrag ändern oder löschen will, dann lehnt die Datenbank ab; Einträge entstehen nur durch das System (Fehlerfall / Manipulationsschutz).
- AK5: Gegeben ein Nutzer ohne AD-Rechte, wenn er das Protokoll lesen will, dann erhält er keine Daten (Rechte-Fall).
**Nicht Teil dieser Story:** Export des Protokolls; Protokoll von Änderungen an Eigenschaften (dafür Historie, US-AD-13).

### US-AD-15: Notfall-Admin nutzen und nachvollziehen
**Als** Admin
**möchte ich** einen Notfall-Admin über geschaeftsstelle@dav-leipzig.de haben und jede seiner Anmeldungen sehen,
**damit** ich mich nicht aussperre und Missbrauch erkenne.
**Priorität:** Must · **Regeln:** R14, R15, R16 · **Abhängig von:** US-AD-01, US-AD-14
**Akzeptanzkriterien**
- AK1: Gegeben der Notfall-Admin ist aktiv, wenn sich jemand mit geschaeftsstelle@dav-leipzig.de anmeldet, dann hat er dieselben Rechte wie die Vorlage Admin und es entsteht ein Protokolleintrag „Anmeldung Notfall-Admin“.
- AK2: Gegeben es gab seit meinem letzten „Zur Kenntnis genommen“ Anmeldungen des Notfall-Admins, wenn ich AD öffne, dann sehe ich einen Hinweis mit Anzahl und Zeitpunkt der letzten Anmeldung und kann ihn mit „Zur Kenntnis genommen“ ausblenden.
- AK3: Gegeben die Funktionsperson „Geschäftsstelle“, wenn Personen für EA abgefragt werden (z. B. über die Personenliste für Fachmodule), dann ist sie nicht enthalten und fällt nicht unter die 5-Jahres-Löschung (R15).
- AK4: Gegeben die Anmeldung erfolgt nach „Passwort vergessen“, wenn sich der Notfall-Admin anmeldet, dann wird sie ebenfalls protokolliert (Fehlerfall: Umgehung).
- AK5: Gegeben ein Nutzer ohne AD-Rechte, wenn er Protokolleinträge des Notfall-Admins lesen oder den Hinweis abrufen will, dann erhält er keine Daten (Rechte-Fall).
**Nicht Teil dieser Story:** E-Mail-Benachrichtigung (mit SC); Vertretung des Admins.

### US-AD-16: Testzugänge in TEST
**Als** Admin
**möchte ich** in TEST je Rechtevorlage einen Testzugang mit fiktiven Daten haben,
**damit** ich und die Geschäftsstelle jede Sicht abnehmen können, ohne Echtdaten zu nutzen.
**Priorität:** Must · **Regeln:** R6, R8 · **Abhängig von:** US-AD-01
**Akzeptanzkriterien**
- AK1: Gegeben eine leere TEST-Datenbank, wenn `supabase/seed.sql` läuft, dann gibt es aktive Testzugänge für Admin, Geschäftsstelle und Vorstand sowie 5–10 fiktive Personen mit Eigenschaften, darunter eine vertrauliche (Hauptamt) und ein Dublettenpaar („Toni Muster“ / „Anton Muster“), siehe spec.md Abschnitt 9.
- AK2: Gegeben der Testzugang Geschäftsstelle, wenn er Personen liest, dann sieht er keine vertraulichen Eigenschaften (Rechte-Fall).
- AK3: Die Passwörter der Testzugänge stehen nicht im Repository, sondern werden beim Seed aus einer Umgebungsvariable bzw. einem GitHub-Secret gesetzt.
- AK4: Gegeben jemand versucht, den Seed gegen PROD auszuführen, wenn das Skript startet, dann bricht es mit „Seed nur für TEST erlaubt.“ ab (Fehlerfall; Prüfung über die Projektkennung).
**Nicht Teil dieser Story:** Testzugang mit Einzelrechten; Abnahme der Fachmodule.

---

## Prüfung Definition of Ready (Stand 19.10.2026)

| Kriterium | Status |
|---|---|
| Rechtevorlage, Ziel und Nutzen benannt | erfüllt für alle Stories |
| Akzeptanzkriterien testbar (Given-When-Then) | erfüllt |
| Fehlerfall und Rechte-Fall je Story | erfüllt |
| Begriffe im Glossar | erfüllt (glossar.md v0.4) |
| Datenfelder im Datenmodell der Spec | erfüllt (spec.md Abschnitt 2) |
| Regeln per ID referenziert | erfüllt (R1–R19) |
| Keine [OFFEN]-Punkte, Annahmen sichtbar | erfüllt; Annahmen vom Product Owner am 19.10.2026 bestätigt; technische Annahmen in spec.md Abschnitt 11 |
| „Nicht Teil dieser Story“ ausgefüllt | erfüllt |
