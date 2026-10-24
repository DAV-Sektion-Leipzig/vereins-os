# User Stories: Administration (AD)

Stand: 24.10.2026 · Version 0.9 · Status: Ready (Nachtrag freigegeben am 21.10.2026; Nachtrag v0.8 Anwesenheitserfassung freigegeben am 24.10.2026) · Product Owner: Toni Werner
Änderungen v0.9 (24.10.2026): Nachtrag Anwesenheitserfassung (spec.md v0.9.4, Nachtrag v0.8.1): US-AD-27 bis US-AD-30 (Orte, Rechte EZ in Rechtevorlagen, Namen für die Anwesenheitserfassung, Helfer:innen beim Arbeitseinsatz anlegen oder wieder aktiv eintragen).
Änderungen v0.8.2 (23.10.2026): US-AD-06 AK5 an R32 angeglichen; US-AD-07 AK5 mit Vorabprüfung der Login-Adresse (Entscheidungen Product Owner aus dem Review des Kerns, spec.md v0.9.3).
Grundlage: 00-steckbrief.md v1.1, 01-erhebung.md v0.7 (Regeln R1–R20), spec.md v0.7.1 (Regeln R21–R42), glossar.md v1.1, rollen.md v0.8
Änderungen v0.7 (21.10.2026): US-AD-17 bis US-AD-19 (Qualifikationsarten) ergänzt.
Änderungen v0.8 (21.10.2026): Nachtrag Personenmodell aus EA und GR: US-AD-20 bis US-AD-26; Hinweise in US-AD-12, US-AD-13, US-AD-19.
Änderungen v0.8.1 (21.10.2026): Admin sieht alle Personen aller Module (US-AD-06, US-AD-23 AK7, US-AD-25 AK2).

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
| US-AD-17 | Qualifikationsarten verwalten | Must | US-AD-01 |
| US-AD-18 | Startbestand Qualifikationsarten | Must | US-AD-17 |
| US-AD-19 | Qualifikationsart als Datentyp eines Felds | Must | US-AD-12, US-AD-17 |
| US-AD-20 | Rechtevorlage mit Reichweite „Referat“ (Referent:in) | Must | US-AD-10 |
| US-AD-21 | Referate bei der Zuweisung festlegen | Must | US-AD-11, US-AD-20 |
| US-AD-22 | Eigenschaftsart mit Feldern, Kategorie, Lesestufe und Bezug | Must | US-AD-12, US-AD-17 |
| US-AD-23 | Sichtbarkeit von Personen je Modul und Ehrenamtsstatus (Datenbank) | Must | US-AD-21, US-AD-22 |
| US-AD-24 | Rufname | Should | US-AD-07 |
| US-AD-25 | Dublettenwarnung modulübergreifend | Must | US-AD-07, US-AD-23 |
| US-AD-26 | Testzugang Referent:in und Seed v0.7 | Must | US-AD-16, US-AD-23 |
| US-AD-27 | Orte pflegen (v0.8) | Must | US-AD-01 |
| US-AD-28 | Rechte für die Anwesenheitserfassung in Rechtevorlagen (v0.8) | Must | US-AD-20, US-AD-21 |
| US-AD-29 | Namen von Personen für die Anwesenheitserfassung (v0.8) | Must | US-AD-23, US-AD-28 |
| US-AD-30 | Helfer:innen beim Arbeitseinsatz anlegen oder wieder aktiv eintragen (v0.8) | Must | US-AD-25, US-AD-28 |

Empfohlene Umsetzungsreihenfolge: 01 → 02 → 05 → 10 → 06 → 07 → 12 → 13 → 11 → 08 → 03 → 04 → 09 → 14 → 15 → 16 → 17 → 18 → 19. Die Datenbankteile von US-AD-10 und US-AD-11 entstehen bereits mit US-AD-01; Login und Grundgerüst (US-AD-02, US-AD-05) kommen vor den Oberflächen der übrigen Stories. US-AD-17 bis US-AD-19 können nach US-AD-13 jederzeit folgen; sie müssen vor der Migration der Aktivenliste (EA) fertig sein.
Nachtrag v0.7: Da `ea_property_types` und `ea_properties` noch nicht umgesetzt sind, werden US-AD-12, US-AD-13 und US-AD-19 direkt in der Form von US-AD-22 gebaut. Reihenfolge ab dem aktuellen Stand (US-AD-01, 02, 05 erledigt): 20 → 10 → 21 → 11 → 22 (mit 12, 19) → 23 → 13 → 24 → 06 → 07 mit 25 → 08 → 03 → 04 → 09 → 14 → 15 → 16 mit 26 → 17 → 18. US-AD-23 muss vor der ersten GR-Migration fertig sein.

---

### US-AD-01: Ersteinrichtung PROD
**Als** Admin
**möchte ich**, dass beim ersten Aufsetzen von PROD mein Zugang, die Start-Rechtevorlagen und der Notfall-Admin vorhanden sind,
**damit** ich ohne vorhandenen Admin überhaupt starten kann.
**Priorität:** Must · **Regeln:** R6, R14, R15 · **Abhängig von:** –
**Akzeptanzkriterien**
- AK1: Gegeben eine leere Datenbank, wenn die Migrationen laufen, dann gibt es die Rechtevorlagen „Admin“ (AD, SC, EA verwalten), „Geschäftsstelle“ (EA, GR, FI, OA, PM, GS, AM verwalten) und „Vorstand“ (überall kein Zugriff). (v0.7: zusätzlich „Referent:in“ und „Admin“ mit GR lesen, siehe US-AD-20.)
- AK2: Gegeben die Migrationen sind gelaufen, wenn das Einrichtungsskript für PROD ausgeführt wird, dann existieren die Person Toni Werner mit Zugang (Login-Adresse als Parameter, Vorlagen Admin und Vorstand) und die Funktionsperson „Geschäftsstelle / Notfall-Admin“ mit Zugang geschaeftsstelle@dav-leipzig.de und Vorlage Admin, beide im Status „kein Zugang“. Die erste Einladung (Toni Werner) erfolgt einmalig über das Supabase-Dashboard; der Zugang wechselt dabei auf „eingeladen“ und nach dem Setzen des Passworts auf „aktiv“. Alle weiteren Einladungen laufen über US-AD-08.
- AK5: Gegeben die erste Einladung über das Dashboard, wenn Toni Werner die Mail an seine reale Adresse @dav-leipzig.de erhält, dann liegt sie im Posteingang (nicht Junk/Quarantäne); ebenso eine „Passwort vergessen“-Mail (Zustellungstest).
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
- AK2: Gegeben ein Passwort mit weniger als 8 Zeichen, wenn ich speichere, dann erscheint „Das Passwort muss mindestens 8 Zeichen lang sein.“; gegeben zwei verschiedene Eingaben, dann erscheint „Die Passwörter stimmen nicht überein.“ (Fehlerfall).
- AK6: Gegeben ich öffne den Link, setze aber kein Passwort, wenn ich die Seite verlasse, dann bleibt der Zugang „eingeladen“.
- AK7: Gegeben der Admin hat die Login-Adresse nach dem Versand geändert, wenn ich den alten Link öffne, dann erscheint die Meldung aus AK3 (Fehlerfall, R20).
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
- AK2: Gegeben ich habe nur die Vorlage Vorstand ohne Rechte, wenn ich die Startseite öffne, dann sehe ich die Willkommensgrafik und den Hinweis „Für dich sind noch keine Module freigeschaltet.“ mit dem Zusatz „Wende dich an den Admin, wenn du Zugriff brauchst.“ (ergänzt 21.10.2026, Entscheidung Product Owner)
- AK3: Gegeben ich habe keine Rechte auf AD, wenn ich eine AD-Seite direkt über die Adresse aufrufe, dann erscheint „Für diesen Bereich hast du keine Rechte.“ und es werden keine Daten geladen (Rechte-Fall).
- AK4: Gegeben mir wurde eine Vorlage entzogen, wenn meine laufende Sitzung abläuft (spätestens nach 1 Stunde), dann zeigt die Startseite das Modul nicht mehr (Fehlerfall: veraltete Sitzung).
- AK5: Die Startseite ist ab 375 px Breite ohne horizontales Scrollen nutzbar.
**Nicht Teil dieser Story:** Inhalte der Fachmodule; Dashboard.

### US-AD-06: Übersicht Personen und Zugänge
**Als** Admin
**möchte ich** in AD eine Liste aller Personen mit Zugangsstatus und Rechtevorlagen sehen und nach Namen suchen,
**damit** ich gezielt Personen einladen, sperren und pflegen kann – auch die aus dem Import.
**Priorität:** Must · **Regeln:** R11, R15, R32 · **Abhängig von:** US-AD-01
**Akzeptanzkriterien**
- AK1: Gegeben es gibt Personen, wenn ich die Übersicht öffne, dann sehe ich je Person Vorname, Nachname, Login-Adresse (falls vorhanden), Zugangsstatus (kein Zugang / eingeladen / aktiv / gesperrt) und zugewiesene Vorlagen. (v0.7.1: zusätzlich Rufname, Ehrenamtsstatus und Referate; alle Personen aller Module, Filter „Zugehörigkeit“ und Paginierung 50 je Seite.)
- AK2: Gegeben die Übersicht, wenn ich nach Zugangsstatus filtere oder einen Namensteil eingebe, dann sehe ich nur passende Personen.
- AK3: Gegeben die Funktionsperson „Geschäftsstelle“, wenn ich die Übersicht öffne, dann ist sie als „Funktionsperson“ gekennzeichnet.
- AK4: Gegeben keine Person passt zum Filter, wenn ich suche, dann erscheint „Keine Personen gefunden.“ (leerer Zustand / Fehlerfall).
- AK5: Gegeben ein Nutzer mit der Vorlage Geschäftsstelle, wenn er die Übersicht /ad aufruft, dann landet er auf /kein-zugriff ohne Datenabfrage; liest er `ad_v_person_overview` oder Zugänge per Datenbankabfrage, dann erhält er nur Personen seines Pfads (EA, R32) und keine Zugangsdaten (Rechte-Fall). (v0.9.3: an R32 angeglichen, Entscheidung Product Owner 23.10.2026.)
**Nicht Teil dieser Story:** Filter aktiv/ausgeschieden nach Eigenschaften (EA); Export.

### US-AD-07: Person anlegen mit Dublettenwarnung
**Als** Admin
**möchte ich** eine Person mit Vorname und Nachname anlegen und vor ähnlichen vorhandenen Personen gewarnt werden,
**damit** keine Dubletten entstehen.
**Priorität:** Must · **Regeln:** R3, R4, R1, R2 · **Abhängig von:** US-AD-06
**Akzeptanzkriterien**
- AK1: Gegeben ich gebe Vorname und Nachname ein und es gibt keine ähnliche Person, wenn ich speichere, dann ist die Person angelegt mit Art „Mensch“ und Status „kein Zugang“; angelegt am/von sind gesetzt.
- AK2: Gegeben Vorname oder Nachname fehlt, wenn ich speichere, dann erscheint „Bitte Vorname und Nachname angeben.“ und nichts wird gespeichert (Fehlerfall).
- AK3: Gegeben es existiert „Toni Werner“, wenn ich „Anton Werner“ anlege oder eine bereits vorkommende E-Mail-Adresse eingebe, dann erscheint eine Warnung mit den ähnlichen Personen und den Optionen „Trotzdem anlegen“, „Vorhandene Person öffnen“ und „Abbrechen“. (v0.7: Trefferdaten und Optionen nach US-AD-25.)
- AK4: Gegeben ich wähle „Trotzdem anlegen“, wenn ich bestätige, dann wird die Person angelegt.
- AK5: Gegeben ich gebe optional eine Login-Adresse ein, wenn sie nicht auf @dav-leipzig.de endet oder bereits vergeben ist, dann erscheinen die Meldungen aus R1 bzw. R2 und die Person wird nicht angelegt (Prüfung vor dem Anlegen über `ad_login_email_ok`, v0.9.3) (Fehlerfall).
- AK6: Gegeben ein Nutzer ohne AD-Rechte, wenn er per Datenbankaufruf eine Person über AD anlegen will, dann lehnt die Datenbank ab; Personen anlegen ist nur mit AD- oder EA-Rechten mindestens „bearbeiten“ erlaubt (Rechte-Fall). (v0.7: zusätzlich GR ≥ bearbeiten über die GR-Funktion; Referent:innen nur über `ea_create_volunteer`.)
**Nicht Teil dieser Story:** Excel-Import, Dublettenprüfliste und Zusammenführen (EA); Löschen.

### US-AD-08: Zugang einrichten und einladen
**Als** Admin
**möchte ich** einer Person eine Login-Adresse geben und sie auf Knopfdruck einladen bzw. erneut einladen,
**damit** sie ihren Zugang selbst aktivieren kann und nie automatisch Einladungen verschickt werden.
**Priorität:** Must · **Regeln:** R1, R2, R11, R13, R17, R20 · **Abhängig von:** US-AD-07, US-AD-11
**Akzeptanzkriterien**
- AK1: Gegeben eine Person mit gültiger Login-Adresse und mindestens einer Vorlage, wenn ich „Einladen“ klicke, dann verschickt Supabase Auth die Einladung, der Status wird „eingeladen“, „zuletzt eingeladen am“ wird gesetzt und ein Protokolleintrag „eingeladen“ entsteht.
- AK2: Gegeben eine Person ohne zugewiesene Vorlage, wenn ich einladen will, dann ist „Einladen“ nicht möglich und es erscheint „Bitte zuerst mindestens eine Rechtevorlage zuweisen.“ (Fehlerfall, R17).
- AK3: Gegeben eine Login-Adresse, die nicht auf @dav-leipzig.de endet, wenn ich speichere, dann erscheint „Zugang nur mit Adresse @dav-leipzig.de möglich.“; ist sie bereits vergeben, erscheint „Diese Login-Adresse ist bereits vergeben.“ (Fehlerfall, R1, R2).
- AK4: Gegeben der Status ist „eingeladen“, wenn ich „Erneut einladen“ klicke, dann wird eine neue Einladung verschickt, „zuletzt eingeladen am“ aktualisiert und protokolliert.
- AK5: Gegeben der Mailversand schlägt fehl, wenn ich einlade, dann erscheint „Die Einladung konnte nicht verschickt werden. Bitte später erneut versuchen.“, der Status bleibt unverändert und in Supabase Auth bleibt kein neu angelegter Eintrag zurück (Fehlerfall).
- AK6: Gegeben ein Aufrufer ohne AD-Rechte, wenn er die Edge Function „Nutzer einladen“ aufruft, dann lehnt sie ohne Einladung ab (Rechte-Fall).
- AK7: Gegeben der Status ist „eingeladen“, wenn ich die Login-Adresse ändere und speichere, dann ist der alte Einladungslink ungültig, der Status ist „kein Zugang“, es erscheint „Die Login-Adresse wurde geändert. Bitte die Einladung erneut senden.“, ein Protokolleintrag „Login-Adresse geändert“ entsteht, und „Einladen“ schickt die Einladung an die neue Adresse; gegeben der Status ist „aktiv“ oder „gesperrt“, wenn ich die Login-Adresse ändern will, dann erscheint „Die Login-Adresse kann nur vor der Aktivierung des Zugangs geändert werden.“ (R20, Fehlerfall).
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
**Nicht Teil dieser Story:** sofortiges Beenden laufender Sitzungen; Löschen von Zugängen; Enddatum an Eigenschaften (US-AD-13); Ehrenamtsstatus „ausgeschieden“ (EA).

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
**Nicht Teil dieser Story:** Rechte je Objekt, Einzelrechte; Reichweite „Referat“ (US-AD-20); Löschen von Vorlagen.

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
**Nicht Teil dieser Story:** Befristung in der Oberfläche; Ableitung von Rechten aus Eigenschaften (R7); Referate je Zuweisung (US-AD-21).

### US-AD-12: Eigenschaftsart anlegen und ändern
**Als** Admin
**möchte ich** Eigenschaftsarten mit Zweck, Datentyp, „sichtbar in“ und „vertraulich“ anlegen und ändern,
**damit** ich Angaben wie Hauptamt erfassen kann, ohne die Datenstruktur zu ändern.
**Priorität:** Must · **Regeln:** R8, R9 · **Abhängig von:** US-AD-01
**Hinweis v0.7:** Wird in der Form von US-AD-22 umgesetzt: Datentyp und Auswahlwerte gehören zu den Feldern; „vertraulich“ ist die Lesestufe „vertraulich“. Die Akzeptanzkriterien gelten sinngemäß je Feld bzw. für die Lesestufe.
**Akzeptanzkriterien**
- AK1: Gegeben ich gebe Name, Zweck, Datentyp (Text / Datum / Ja/Nein / Auswahlliste; Qualifikationsart siehe US-AD-19), „sichtbar in“ (mind. ein Modul) und „vertraulich“ an, wenn ich speichere, dann ist die Eigenschaftsart angelegt; beim Anlegen wird der Hinweis angezeigt: „Erfasse keine Gesundheitsdaten, Religion, politische Meinung oder andere besondere Kategorien nach Art. 9 DSGVO.“
- AK2: Gegeben der Zweck fehlt oder eine Auswahlliste hat keine Auswahlwerte, wenn ich speichere, dann erscheint „Bitte einen Zweck angeben.“ bzw. „Bitte mindestens einen Auswahlwert angeben.“ (Fehlerfall, R9).
- AK3: Gegeben der Name existiert bereits, wenn ich speichere, dann erscheint „Eine Eigenschaftsart mit diesem Namen gibt es bereits.“ (Fehlerfall).
- AK4: Gegeben es gibt schon Eigenschaften dieser Art, wenn ich den Datentyp ändern will, dann erscheint „Der Datentyp kann nicht geändert werden, solange Eigenschaften dieser Art existieren.“; Auswahlwerte können ergänzt, aber nicht entfernt werden („Auswahlwerte können ergänzt, aber nicht entfernt werden.“) (Fehlerfall).
- AK5: Gegeben ein Nutzer ohne AD-Rechte (z. B. Geschäftsstelle mit EA verwalten), wenn er das Kennzeichen „vertraulich“ setzen oder ändern will, dann lehnt die Datenbank ab; „vertraulich“ setzt nur, wer AD-Rechte hat (Rechte-Fall).
**Nicht Teil dieser Story:** Löschen von Eigenschaftsarten; Oberfläche für Eigenschaftsarten in EA; mehrere Felder, Kategorie, Bezug (US-AD-22); Datentyp Datei.

### US-AD-13: Eigenschaften einer Person pflegen
**Als** Admin
**möchte ich** an einer Person Eigenschaften mit Gültigkeit anlegen, ändern und beenden und frühere Werte sehen,
**damit** z. B. das Hauptamt von Denise oder ihr Ausscheiden nachvollziehbar erfasst ist.
**Priorität:** Must · **Regeln:** R7, R8, R12, R29, R35 · **Abhängig von:** US-AD-12
**Hinweis v0.7:** Eingabe über das Eigenschaftsformular (Felder der Eigenschaftsart, ggf. Bezug); „Wert“ bedeutet die Werte aller Felder.
**Akzeptanzkriterien**
- AK1: Gegeben eine Person, wenn ich Eigenschaftsart, Wert (passend zum Datentyp) und gültig von angebe und speichere, dann ist die Eigenschaft angelegt; geändert am/von sind gesetzt.
- AK2: Gegeben eine bestehende Eigenschaft, wenn ich den Wert ändere oder gültig bis setze, dann bleibt die frühere Fassung mit geändert am/von in der Historie sichtbar.
- AK3: Gegeben gültig bis liegt vor gültig von oder der Wert passt nicht zum Datentyp, wenn ich speichere, dann erscheint „‚Gültig bis‘ darf nicht vor ‚gültig von‘ liegen.“ bzw. „Der Wert passt nicht zum Datentyp der Eigenschaftsart.“ (v0.7: „Der Wert für ‚<Feld>‘ passt nicht zum Datentyp.“) (Fehlerfall).
- AK4: Gegeben eine vertrauliche Eigenschaft (z. B. Hauptamt), wenn ein Nutzer mit der Vorlage Geschäftsstelle Eigenschaften dieser Person per Oberfläche oder Datenbankabfrage liest, dann erhält er die vertrauliche Eigenschaft nicht (Rechte-Fall, R8).
- AK5: Gegeben ich gebe einer Person die Eigenschaft Hauptamt oder eine Funktion, wenn ich speichere, dann ändert sich an ihren Rechten nichts (R7).
- AK6: In der Ansicht einer Person zeigt AD alle Eigenschaftsarten, deren „sichtbar in“ AD enthält; Eigenschaften mit gültig bis in der Vergangenheit erscheinen als „beendet“.
**Nicht Teil dieser Story:** Pflege-Oberflächen, Filter und Import in EA; Löschung nach 5 Jahren (EA).

### US-AD-14: Protokoll einsehen
**Als** Admin
**möchte ich** das Protokoll der Einladungen, Rechtevergaben, Sperren und Anmeldungen des Notfall-Admins einsehen,
**damit** ich nachvollziehen kann, wer wem wann welche Rechte gegeben hat.

Aktionen im Protokoll: eingeladen, Login-Adresse geändert, Vorlage zugewiesen, Vorlage entzogen, Referate geändert (v0.7), gesperrt, entsperrt, Anmeldung Notfall-Admin.
**Priorität:** Should · **Regeln:** R13, R16 · **Abhängig von:** US-AD-08
**Akzeptanzkriterien**
- AK1: Gegeben es gibt Protokolleinträge, wenn ich das Protokoll öffne, dann sehe ich Zeitpunkt, ausgeführt von, betroffene Person, Aktion und Details, neueste zuerst.
- AK2: Gegeben ein Eintrag ist älter als 5 Jahre, wenn der tägliche Löschlauf läuft, dann ist der Eintrag gelöscht.
- AK3: Gegeben es gibt noch keine Einträge, wenn ich das Protokoll öffne, dann erscheint „Noch keine Einträge.“ (leerer Zustand).
- AK4: Gegeben ein Nutzer (auch Admin), wenn er einen Protokolleintrag ändern oder löschen will, dann lehnt die Datenbank ab; Einträge entstehen nur durch das System (Fehlerfall / Manipulationsschutz).
- AK5: Gegeben ein Nutzer ohne AD-Rechte, wenn er das Protokoll lesen will, dann erhält er keine Daten (Rechte-Fall).
**Nicht Teil dieser Story:** Export des Protokolls; Protokoll von Änderungen an Eigenschaften (dafür Historie, US-AD-13); Protokoll von Änderungen an Qualifikationsarten; Wechsel des Ehrenamtsstatus (eigene Historie).

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
- AK1: Gegeben eine leere TEST-Datenbank oder ein lokaler Stack, wenn `supabase/seed.sh` läuft, dann gibt es aktive Testzugänge für Admin, Geschäftsstelle und Vorstand sowie 5–10 fiktive Personen mit Eigenschaften, darunter eine vertrauliche (Hauptamt) und ein Dublettenpaar („Toni Muster“ / „Anton Muster“), siehe spec.md Abschnitt 9. (v0.7: Erweiterung in US-AD-26.)
- AK2: Gegeben der Testzugang Geschäftsstelle, wenn er Personen liest, dann sieht er keine vertraulichen Eigenschaften (Rechte-Fall).
- AK3: Die Passwörter der Testzugänge stehen nicht im Repository, sondern werden beim Seed aus `SEED_TEST_PASSWORD` (lokal `.env.local`, CI: GitHub-Secret) gesetzt.
- AK4: Gegeben jemand versucht, den Seed gegen PROD auszuführen, wenn das Skript startet, dann bricht es mit „Seed in PROD nicht erlaubt.“ ab (Fehlerfall; Prüfung über die Project Ref).
**Nicht Teil dieser Story:** Testzugang mit Einzelrechten; Abnahme der Fachmodule.

### US-AD-17: Qualifikationsarten verwalten
**Als** Admin (in AD) bzw. Nutzer mit der Vorlage Geschäftsstelle (in EA, über „EA verwalten“)
**möchte ich** Qualifikationsarten mit Sparte, Typ, Lizenzstufe, Spezifikation, Aussteller, DOSB-Kennzeichen, Gültigkeitsdauer und Status anlegen und ändern,
**damit** EA und spätere Module mit einer einheitlichen, gepflegten Liste arbeiten, z. B. wenn der Bundesverband 2027 „DAV-Skibetreuer*in“ einführt.
**Priorität:** Must · **Regeln:** R12, R21–R26 · **Abhängig von:** US-AD-01
**Akzeptanzkriterien**
- AK1: Gegeben es gibt Qualifikationsarten, wenn ich „Qualifikationsarten“ öffne, dann sehe ich je Eintrag Kürzel, Bezeichnung, Typ, Lizenzstufe, Gültigkeitsdauer und Status, gruppiert nach Sparte; ich kann nach Bezeichnung oder Kürzel suchen und nach Sparte, Typ und Status filtern; Standardfilter ist Status „aktuell“.
- AK2: Gegeben ich fülle Bezeichnung, Sparte, Typ und Aussteller aus und – bei Typ „Lizenz“ – Lizenzstufe und Gültigkeitsdauer, wenn ich speichere, dann ist die Qualifikationsart mit Status „aktuell“ angelegt; angelegt am/von sind gesetzt.
- AK3: Gegeben die Bezeichnung oder das Kürzel ist bereits vergeben, wenn ich speichere, dann erscheint „Eine Qualifikationsart mit dieser Bezeichnung gibt es bereits.“ bzw. „Dieses Kürzel ist bereits vergeben.“; gegeben Typ „Lizenz“ ohne Lizenzstufe oder ohne gültige Gültigkeitsdauer, dann erscheint „Bitte eine Lizenzstufe wählen.“ bzw. „Bitte eine Gültigkeitsdauer in Jahren angeben (1–10).“ (Fehlerfall, R21–R24).
- AK4: Gegeben eine Qualifikationsart ist an Personen vergeben, wenn ich sie auf „historisch“ setze, dann bleiben die vorhandenen Eigenschaften unverändert, neue Eigenschaften können sie nicht mehr wählen, und die Detailansicht zeigt „Verwendet bei n Personen“ (R25).
- AK5: Gegeben ich ändere die Gültigkeitsdauer, wenn ich speichere, dann erscheint „Die Änderung gilt für neue Einträge. Vorhandene Ablaufdaten bleiben unverändert.“ und vorhandene Eigenschaften bleiben unverändert (R26).
- AK6: Gegeben ein Nutzer mit der Vorlage Vorstand (ohne AD ≥ bearbeiten und ohne EA verwalten), wenn er per Datenbankaufruf eine Qualifikationsart anlegt oder ändert, dann lehnt die Datenbank ab; gegeben der Testzugang Geschäftsstelle, wenn er per Datenbankaufruf eine Qualifikationsart ändert, dann ist das erlaubt; die Seiten unter /ad bleiben für ihn gesperrt (Rechte-Fall).
- AK7: Es gibt keine Funktion zum Löschen; ein Löschversuch per Datenbankaufruf wird abgelehnt (R12).
**Nicht Teil dieser Story:** Startbestand (US-AD-18); Verweis aus Eigenschaften (US-AD-19); Ablaufdaten und Stichtagsliste (EA); Protokoll der Änderungen.

### US-AD-18: Startbestand Qualifikationsarten
**Als** Admin
**möchte ich**, dass die 47 Qualifikationsarten aus stammdaten-qualifikationsarten.md per Migration in TEST und PROD angelegt werden,
**damit** die Migration der Aktivenliste und die Erfassung in EA sofort darauf verweisen können.
**Priorität:** Must · **Regeln:** R21–R25 · **Abhängig von:** US-AD-17
**Akzeptanzkriterien**
- AK1: Gegeben eine leere Tabelle, wenn die Migrationen laufen, dann gibt es 47 Qualifikationsarten mit den Werten der Liste (Kürzel, Bezeichnung, Sparte, Typ, Lizenzstufe, Spezifikation, Aussteller, DOSB, Gültigkeitsdauer, Status, Hinweis, Quell-ID): 36 aktuell, 11 historisch (inkl. PSA bis zur Entscheidung).
- AK2: Gegeben der Admin hat nach der Migration einen Eintrag geändert, wenn die Migration erneut läuft (z. B. frischer lokaler Stack mit Seed und anschließender Migration), dann wird nichts überschrieben und nichts doppelt angelegt (Abgleich über Quell-ID; Fehlerfall).
- AK3: Die Migration enthält keine Personendaten und läuft deshalb – anders als der Seed – auch in PROD.
- AK4: Gegeben ein Nutzer ohne Pflegerecht (Vorlage Vorstand), wenn er die Startwerte per Datenbankaufruf ändern will, dann lehnt die Datenbank ab (Rechte-Fall).
**Nicht Teil dieser Story:** Qualifikationsarten aus Abschnitt 4 der Stammdatenliste (nur nach Entscheidung des Product Owners); Abgleich mit dem Bundesverband.

### US-AD-19: Qualifikationsart als Datentyp eines Felds
**Als** Admin
**möchte ich** einem Feld einer Eigenschaftsart den Datentyp „Qualifikationsart“ geben und die erlaubten Typen einschränken,
**damit** EA an Personen auf eine Qualifikationsart verweist statt Freitext zu speichern.
**Priorität:** Must · **Regeln:** R27, R28 · **Abhängig von:** US-AD-12, US-AD-17
**Hinweis v0.7:** Der Datentyp gilt je Feld (US-AD-22); der Verweis liegt im Wert der Eigenschaft.
**Akzeptanzkriterien**
- AK1: Gegeben ich lege eine Eigenschaftsart an, wenn ich für ein Feld den Datentyp „Qualifikationsart“ wähle, dann kann ich optional die erlaubten Typen einschränken (z. B. nur „Lizenz“) und speichern.
- AK2: Gegeben eine Eigenschaft mit einem solchen Feld, wenn ich einen Wert erfasse, dann wähle ich aus einer durchsuchbaren Liste der Qualifikationsarten mit Status „aktuell“ und erlaubtem Typ (Anzeige „Kürzel – Bezeichnung“, gruppiert nach Sparte); gespeichert wird der Verweis.
- AK3: Gegeben eine historische Qualifikationsart, wenn ich sie einer Person neu zuordnen will (auch per Datenbankaufruf), dann erscheint „Diese Qualifikationsart ist historisch und kann nicht neu vergeben werden.“ (Fehlerfall, R27); vorhandene Eigenschaften mit dieser Qualifikationsart bleiben gültig, sind weiter änderbar (z. B. gültig bis) und werden mit „(historisch)“ angezeigt.
- AK4: Gegeben eine Qualifikationsart mit nicht erlaubtem Typ, wenn ich sie speichere, dann erscheint „Dieser Typ von Qualifikation ist hier nicht erlaubt.“ (Fehlerfall, R28).
- AK5: Gegeben ein Nutzer mit EA ≥ bearbeiten, wenn er eine Eigenschaft mit einem solchen Feld an einer Person anlegt, dann gelten dieselben Rechte wie für jede andere Eigenschaft; Rechte auf AD braucht er nicht (Rechte-Fall).
- AK6: Gegeben die Bezeichnung einer Qualifikationsart wird geändert, wenn ich eine Person ansehe, die darauf verweist, dann sehe ich die neue Bezeichnung (Verweis, keine Kopie).
**Nicht Teil dieser Story:** Oberfläche zur Lizenzerfassung in EA; Ablaufberechnung; Fortbildungen.

### US-AD-20: Rechtevorlage mit Reichweite „Referat“ (Referent:in)
**Als** Admin
**möchte ich** je Modul neben der Stufe auch die Reichweite („alle“ oder „Referat“) festlegen und eine Startvorlage „Referent:in“ mit „EA bearbeiten, Reichweite Referat“ haben,
**damit** Referent:innen und Hüttenwart:innen nur die Aktiven ihres Referats sehen und pflegen.
**Priorität:** Must · **Regeln:** R6, R7, R30 · **Abhängig von:** US-AD-10
**Akzeptanzkriterien**
- AK1: Gegeben die Migrationen v0.7 sind gelaufen, wenn ich die Rechtevorlagen öffne, dann gibt es zusätzlich „Referent:in“ (EA bearbeiten, Reichweite Referat; übrige Module kein Zugriff) und die Vorlage „Admin“ hat zusätzlich „Gruppen lesen“.
- AK2: Gegeben ich bearbeite eine Vorlage, wenn ich für EA die Reichweite „Referat“ wähle und speichere, dann ist sie gespeichert und gilt für alle Personen mit dieser Vorlage spätestens nach Ablauf ihrer Sitzung.
- AK3: Gegeben ich wähle für ein anderes Modul als EA die Reichweite „Referat“, wenn ich speichere, dann erscheint „Die Reichweite ‚Referat‘ ist nur im Ehrenamtsmanagement möglich.“ und nichts wird gespeichert (Fehlerfall, R30).
- AK4: Gegeben ein Nutzer hat nur die Vorlage Referent:in, wenn Rechte geprüft werden, dann gilt EA nicht als „alle lesen“ (`ad_has_level('EA','read')` ist falsch), `ad_my_referate('EA','read')` liefert seine Referate und die Startseite zeigt EA, sobald das Modul verfügbar ist.
- AK5: Gegeben ein Nutzer ohne AD-Rechte, wenn er die Reichweite einer Vorlage per Datenbankaufruf ändern will, dann lehnt die Datenbank ab (Rechte-Fall).
**Nicht Teil dieser Story:** Reichweiten „Gruppe“ und „nur eigene“; Einzelrechte; Zuweisung der Referate (US-AD-21).

### US-AD-21: Referate bei der Zuweisung festlegen
**Als** Admin
**möchte ich** beim Zuweisen einer Vorlage mit Reichweite „Referat“ ein oder mehrere Referate wählen und später ändern,
**damit** z. B. der Hüttenwart der Karl-Stein-Hütte nur sein Referat sieht und eine Referentin mit zwei Referaten beide.
**Priorität:** Must · **Regeln:** R13, R31 · **Abhängig von:** US-AD-11, US-AD-20
**Akzeptanzkriterien**
- AK1: Gegeben eine Person ohne Vorlage, wenn ich ihr „Referent:in“ mit den Referaten Klettern und Ausbildung zuweise, dann ist die Zuweisung mit beiden Referaten gespeichert und ein Protokolleintrag „Vorlage zugewiesen“ nennt Vorlage und Referate.
- AK2: Gegeben ich weise „Referent:in“ ohne Referat zu, wenn ich speichere, dann erscheint „Bitte mindestens ein Referat auswählen.“ und nichts wird gespeichert (Fehlerfall, R31).
- AK3: Gegeben eine bestehende Zuweisung mit Referat Klettern, wenn ich das Referat auf Touren ändere, dann gilt der Datenzugriff sofort für Touren statt Klettern und ein Protokolleintrag „Referate geändert“ nennt vorher und nachher.
- AK4: Gegeben eine Vorlage ohne Reichweite „Referat“ (z. B. Geschäftsstelle), wenn ich sie zuweise, dann wird keine Referatsauswahl angezeigt und keine Referate gespeichert.
- AK5: Gegeben ein inaktives Referat, wenn ich Referate auswähle, dann wird es nicht angeboten (Fehlerfall).
- AK6: Gegeben ein Nutzer ohne AD-Rechte, wenn er Referate einer Zuweisung per Datenbankaufruf ändern will, dann lehnt die Datenbank ab (Rechte-Fall).
**Nicht Teil dieser Story:** Pflege der Referate selbst (Oberfläche in EA); automatische Ableitung der Referate aus dem Amt Referent:in (R7).

### US-AD-22: Eigenschaftsart mit Feldern, Kategorie, Lesestufe und Bezug
**Als** Admin (in AD; die Geschäftsstelle später in EA über „EA verwalten“)
**möchte ich** eine Eigenschaftsart mit Zweck, Kategorie, Lesestufe, optionalem Bezug (Referat oder Gremium) und einem oder mehreren Feldern anlegen und ändern,
**damit** z. B. eine Lizenz mit Qualifikationsart, Lizenznummer und gültig bis als ein Eintrag erfasst wird und die Führungszeugnis-Einsicht nur Geschäftsstelle und Admin lesen.
**Priorität:** Must · **Regeln:** R9, R27–R29, R35–R38 · **Abhängig von:** US-AD-12, US-AD-17
**Akzeptanzkriterien**
- AK1: Gegeben ich gebe Name, Zweck, Kategorie „Qualifikationen“, Lesestufe „alle mit Zugriff“ und die Felder „Qualifikationsart“ (Qualifikationsart, nur Typ Lizenz, Pflicht), „Lizenznummer“ (Text) und „gültig bis“ (Datum) an, wenn ich speichere, dann ist die Eigenschaftsart mit drei Feldern angelegt; beim Anlegen erscheint der Hinweis zu Art. 9 DSGVO.
- AK2: Gegeben die Eigenschaftsart hat kein Feld, der Zweck fehlt oder ein Feld vom Typ Auswahlliste hat keine Werte, wenn ich speichere, dann erscheint „Bitte mindestens ein Feld anlegen.“, „Bitte einen Zweck angeben.“ bzw. „Bitte mindestens einen Auswahlwert angeben.“ (Fehlerfall, R9).
- AK3: Gegeben es gibt Eigenschaften dieser Art, wenn ich den Datentyp eines Felds oder den Bezug ändern oder ein neues Pflichtfeld anlegen will, dann erscheinen die Meldungen aus R36 bzw. „Der Bezug kann nicht geändert werden, solange Eigenschaften dieser Art existieren.“; ein neues optionales Feld wird gespeichert (Fehlerfall).
- AK4: Gegeben eine Eigenschaftsart mit Bezug „Referat“ und „Bezug Pflicht“, wenn eine Eigenschaft ohne Referat gespeichert wird, dann erscheint „Bitte ein Referat (bzw. Gremium, Gruppe) wählen.“ (Fehlerfall, R38); gegeben „nur ein gültiger Eintrag“, wenn eine zweite gültige Eigenschaft im selben Zeitraum gespeichert wird, dann erscheint die Meldung aus R37.
- AK5: Gegeben ein Nutzer mit „EA verwalten“ ohne AD-Rechte (Geschäftsstelle), wenn er per Datenbankaufruf die Lesestufe „vertraulich“ setzt, dann lehnt die Datenbank mit „Nur mit Rechten auf die Administration möglich.“ ab; die Lesestufen „alle mit Zugriff“ und „nur Geschäftsstelle und Admin“ darf er setzen (Rechte-Fall, R29).
- AK6: Gegeben ein Nutzer mit der Vorlage Vorstand oder Referent:in, wenn er per Datenbankaufruf eine Eigenschaftsart anlegt, dann lehnt die Datenbank ab (Rechte-Fall).
**Nicht Teil dieser Story:** Oberfläche für Eigenschaftsarten in EA; Bezug „Gruppe“ (mit der ersten GR-Migration); Löschen von Eigenschaftsarten und Feldern; Datentyp Datei.

### US-AD-23: Sichtbarkeit von Personen je Modul und Ehrenamtsstatus (Datenbank)
**Als** Admin
**möchte ich**, dass jede Person und jede Eigenschaft nur über die Module lesbar ist, zu denen die Person gehört, und dass der Ehrenamtsstatus mit Historie gespeichert wird,
**damit** Kinder aus Gruppen nicht in AD oder EA auftauchen, Referent:innen nur ihr Referat sehen und Ausgeschiedene nur Geschäftsstelle und Admin.
**Priorität:** Must · **Regeln:** R15, R29, R32–R34, R39, R41, R42 · **Abhängig von:** US-AD-21, US-AD-22
**Akzeptanzkriterien**
- AK1: Gegeben der Seed v0.7, wenn die Testzugänge Admin, Geschäftsstelle, Referent:in (Klettern) und Vorstand Personen und Eigenschaften abfragen, dann entspricht das Ergebnis der Tabelle „Erwartete Sichtbarkeit“ in spec.md Abschnitt 9.
- AK2: Gegeben Toni Muster (aktiv, Referat Klettern), wenn die Referentin Klettern ihn über `ea_set_volunteer_status` auf „ruhend“ setzt, dann ist er weiter für sie sichtbar und die Historie enthält Status, Datum und wer; setzt sie ihn auf „ausgeschieden“, dann sieht sie ihn nicht mehr, die Geschäftsstelle schon.
- AK3: Gegeben Anton Muster (nur Referat Ausbildung), wenn die Referentin Klettern seinen Status ändern will, dann erscheint „Du darfst den Status dieser Person nicht ändern.“ (Fehlerfall, R33).
- AK4: Gegeben die Referentin Klettern, wenn sie über `ea_create_volunteer` eine Person mit Funktion im Referat Klettern anlegt, dann ist die Person mit Status „aktiv“ angelegt und für sie sichtbar; mit Referat Ausbildung erscheint „Du kannst nur Zuordnungen zu deinen Referaten pflegen.“ (Fehlerfall, R41).
- AK5: Gegeben Karl Zweireferat (Klettern und Ausbildung), wenn die Referentin Klettern ihn liest, dann sieht sie beide Funktionen, aber kein Geburtsdatum; die Funktion im Referat Ausbildung kann sie nicht ändern; die Geschäftsstelle sieht das Geburtsdatum, vertrauliche Eigenschaften sieht nur der Admin (Rechte-Fall, R29, R41, R42).
- AK6: Gegeben ein Nutzer mit EA-Rechten, wenn er `volunteer_status` an ea_persons direkt ändern will, dann lehnt die Datenbank ab (Rechte-Fall).
- AK7: Gegeben Paul Nurgruppe (nur Gruppenbezug, kein Zugang, kein Ehrenamtsstatus), wenn Geschäftsstelle (nur über EA) oder Referent:in Personen oder Eigenschaften abfragen, dann ist er nicht enthalten; der Admin sieht ihn mit allen Eigenschaften (Rechte-Fall, R32, v0.7.1).
**Nicht Teil dieser Story:** Oberflächen für Ehrenamtsstatus, Sicht je Referat, Rückkehr und Bestätigungsdialog (EA); Pfad GR (erste GR-Migration); Löschlauf.

### US-AD-24: Rufname
**Als** Admin
**möchte ich** an einer Person einen Rufnamen pflegen,
**damit** Personen so angezeigt und gefunden werden, wie sie angesprochen werden (z. B. Anton → Toni).
**Priorität:** Should · **Regeln:** R4 · **Abhängig von:** US-AD-07
**Akzeptanzkriterien**
- AK1: Gegeben die Person Anton Muster, wenn ich den Rufnamen „Toni“ speichere, dann wird sie in Übersicht, Personendetail und (bei eigenem Zugang) in der Kopfzeile als „Toni Muster“ angezeigt; der Vorname bleibt „Anton“.
- AK2: Gegeben die Personenübersicht, wenn ich „Toni“ suche, dann finde ich die Person auch über den Rufnamen.
- AK3: Gegeben ich speichere einen Rufnamen, der nur aus Leerzeichen besteht, wenn ich speichere, dann wird kein Rufname gespeichert und die Anzeige nutzt den Vornamen (Fehlerfall).
- AK4: Gegeben ein Nutzer, der die Person nicht mit mindestens „bearbeiten“ lesen darf, wenn er den Rufnamen per Datenbankaufruf ändern will, dann lehnt die Datenbank ab (Rechte-Fall).
**Nicht Teil dieser Story:** Pflichtangabe Rufname; Rufname im Migrationsskript (EA).

### US-AD-25: Dublettenwarnung modulübergreifend
**Als** Nutzer mit AD-, EA- oder GR-Rechten mindestens „bearbeiten“
**möchte ich** beim Anlegen einer Person auch vor ähnlichen Personen aus anderen Modulen gewarnt werden, ohne deren Daten zu sehen,
**damit** ein Mensch nur einmal existiert, z. B. wenn eine Mutter aus einer Jugendgruppe Helferin wird.
**Priorität:** Must · **Regeln:** R3, R40 · **Abhängig von:** US-AD-07, US-AD-23
**Akzeptanzkriterien**
- AK1: Gegeben Olga Ausgeschieden existiert, wenn die Referentin Klettern „Olga Ausgeschieden“ anlegen will, dann zeigt der Dialog nur Vorname, Nachname, Rufname, Geburtsjahr (falls vorhanden) und „ausgeschieden seit 30.06.2025“ und bietet in EA „Wieder aktivieren“ statt „Vorhandene Person öffnen“.
- AK2: Gegeben Paul Nurgruppe existiert nur mit Gruppenbezug, wenn die Referentin Klettern „Paul Nurgruppe“ anlegen will, dann erscheint der Treffer mit Name und ggf. Geburtsjahr, ohne „Vorhandene Person öffnen“ und ohne Kontaktdaten, mit „Ins Ehrenamtsmanagement übernehmen“; legt der Admin ihn an, bietet der Dialog „Vorhandene Person öffnen“ (Admin sieht alle Personen).
- AK3: Gegeben ein Aufruf von `ad_find_similar_persons`, wenn die Funktion Treffer liefert, dann enthält das Ergebnis nur die Spalten aus spec.md Abschnitt 2; keine Eigenschaften, keine Kontaktdaten, keine Zugehörigkeiten (Datenschutz, R40).
- AK4: Gegeben keine ähnliche Person, wenn ich speichere, dann wird die Person ohne Dialog angelegt.
- AK5: Gegeben ein Nutzer ohne Rechte „bearbeiten“ in AD, EA oder GR (z. B. Vorstand), wenn er die Funktion aufruft, dann lehnt die Datenbank ab (Rechte-Fall).
**Nicht Teil dieser Story:** Zusammenführen von Personen; Oberfläche „Wieder aktivieren“ (EA, nutzt `ea_activate_person`).

### US-AD-26: Testzugang Referent:in und Seed v0.7
**Als** Admin
**möchte ich** in TEST einen Testzugang Referent:in und fiktive Personen mit Ehrenamtsstatus, Referaten und einer Person nur aus Gruppen haben,
**damit** wir die Sichtbarkeit je Rechtevorlage abnehmen können, ohne Echtdaten zu nutzen.
**Priorität:** Must · **Regeln:** R29, R32 · **Abhängig von:** US-AD-16, US-AD-23
**Akzeptanzkriterien**
- AK1: Gegeben eine leere TEST-Datenbank oder ein lokaler Stack, wenn `supabase/seed.sh` läuft, dann gibt es zusätzlich den aktiven Testzugang test.referent@dav-leipzig.de (Vorlage Referent:in, Referat Klettern), die Personen 9–12 und die Testeigenschaftsarten aus spec.md Abschnitt 9.
- AK2: Gegeben der Seed, wenn ich mich mit dem Testzugang Referent:in anmelde, dann sehe ich nur die Personen aus der Tabelle „Erwartete Sichtbarkeit“.
- AK3: Gegeben der Testzugang Referent:in, wenn er AD-Seiten aufruft, dann erscheint „Für diesen Bereich hast du keine Rechte.“ (Rechte-Fall).
- AK4: Gegeben jemand versucht, den Seed gegen PROD auszuführen, wenn das Skript startet, dann bricht es mit „Seed in PROD nicht erlaubt.“ ab (Fehlerfall).
**Nicht Teil dieser Story:** Abnahme der EA-Oberflächen; Testzugang Gruppenleitung.

### US-AD-27: Orte pflegen
**Als** Admin
**möchte ich** Orte anlegen, ändern und inaktiv setzen,
**damit** die Anwesenheitserfassung beim Training einen Ort aus einer gepflegten Liste anbietet und die Anwesenheit an Kletterhallen mit Punktekonto auswerten kann.
**Priorität:** Must · **Regeln:** R43 · **Abhängig von:** US-AD-01 · **Nachtrag:** v0.8 (Übergabe EZ A8)
**Akzeptanzkriterien**
- AK1: Gegeben keine Orte, wenn ich /ad/orte öffne, dann erscheint „Noch keine Orte angelegt.“
- AK2: Gegeben ich lege „Kletterhalle Test“ mit „Punktekonto Kletterhalle“ = Ja an, wenn ich speichere, dann steht der Ort aktiv in der Liste.
- AK3: Gegeben ich lasse die Bezeichnung leer, wenn ich speichere, dann erscheint „Bitte eine Bezeichnung angeben.“ (Fehlerfall).
- AK4: Gegeben „Kletterhalle Test“ existiert, wenn ich „kletterhalle test“ anlege, dann erscheint „Einen Ort mit dieser Bezeichnung gibt es bereits.“ (Fehlerfall).
- AK5: Gegeben ein aktiver Ort, wenn ich ihn auf „inaktiv“ setze, dann blendet ihn der Filter „aktiv“ aus und das Auswahlfeld „Ort“ bietet ihn nicht mehr an; vorhandene Einsätze behalten ihn. Löschen gibt es nicht.
- AK6: Gegeben die Geschäftsstelle, wenn sie einen Ort per Datenbankaufruf anlegen oder ändern will, dann lehnt die Datenbank ab; lesen darf jeder Nutzer mit aktivem Zugang (Rechte-Fall).
**Nicht Teil dieser Story:** Startbestand der Orte (vor der Freigabe der Anwesenheitserfassung); Pflege durch die Geschäftsstelle; Auswertung des Punktekontos (Anwesenheitserfassung).

### US-AD-28: Rechte für die Anwesenheitserfassung in Rechtevorlagen
**Als** Admin
**möchte ich** in den Rechtevorlagen die Zeile Anwesenheitserfassung mit Reichweite „alle“ oder „Referat“ sehen und setzen,
**damit** Referent:innen Einsätze nur in ihren Referaten erfassen und die Geschäftsstelle alle Einsätze verwaltet.
**Priorität:** Must · **Regeln:** R30, R31 · **Abhängig von:** US-AD-20, US-AD-21 · **Nachtrag:** v0.8 (Übergabe EZ A1, A2, A5)
**Akzeptanzkriterien**
- AK1: Gegeben die Startvorlagen, wenn ich sie öffne, dann steht die Zeile Anwesenheitserfassung direkt nach Gruppen mit: Admin „lesen“, Geschäftsstelle „verwalten“, Referent:in „bearbeiten“ mit Reichweite „Referat“, Vorstand „kein Zugriff“.
- AK2: Gegeben die Vorlage Referent:in, wenn ich für die Anwesenheitserfassung die Reichweite „Referat“ speichere, dann wird sie gespeichert; für Gruppen erscheint „Die Reichweite ‚Referat‘ ist nur im Ehrenamtsmanagement und in der Anwesenheitserfassung möglich.“ (Fehlerfall, R30).
- AK3: Gegeben Rita Referentin hat die Vorlage Referent:in mit Referat Klettern, wenn die Anwesenheitserfassung ihre Referate abfragt, dann gilt Klettern; die Referate der Zuweisung gelten für Ehrenamtsmanagement und Anwesenheitserfassung gemeinsam (R31).
- AK4: Gegeben ich lege eine neue Vorlage an, wenn ich sie speichere, dann hat sie für die Anwesenheitserfassung „kein Zugriff“; Änderungen des Admins an den Startvorlagen überschreibt die Migration nicht.
- AK5: Gegeben die Anwesenheitserfassung ist noch nicht freigegeben, wenn sich ein Nutzer mit EZ-Rechten anmeldet, dann erscheint keine Kachel Anwesenheitserfassung.
- AK6: Gegeben ein Nutzer ohne AD-Rechte, wenn er die Rechte einer Vorlage per Datenbankaufruf ändern will, dann lehnt die Datenbank ab (Rechte-Fall).
**Nicht Teil dieser Story:** Reichweite „Gruppe“ und Vorlage Gruppenleitung (Iteration 1 der Anwesenheitserfassung); Freigabe des Moduls.

### US-AD-29: Namen von Personen für die Anwesenheitserfassung
**Als** Referent:in mit Rechten in der Anwesenheitserfassung
**möchte ich** Aktive über ihren Namen finden und die Namen der Personen in meinen Einsätzen sehen,
**damit** ich organisierende Personen und Vertretungen eintragen kann, ohne weitere Daten der Personen zu sehen.
**Priorität:** Must · **Regeln:** R44 · **Abhängig von:** US-AD-23, US-AD-28 · **Nachtrag:** v0.8 (Übergabe EZ A3)
**Akzeptanzkriterien**
- AK1: Gegeben die Geschäftsstelle sucht „Muster“, wenn die Suche über alle Aktiven läuft, dann erscheint Toni Muster (aktiv), nicht Anton Muster (ruhend); angezeigt werden nur Vorname, Rufname und Nachname.
- AK2: Gegeben ich gebe „M“ ein, wenn die Suche startet, dann erscheint „Bitte mindestens 2 Zeichen eingeben.“ (Fehlerfall).
- AK3: Gegeben mehr als 50 passende Aktive, wenn ich suche, dann erscheinen höchstens 50 Treffer.
- AK4: Gegeben eine Liste von Personen-IDs, wenn die Anwesenheitserfassung ihre Namen abfragt, dann liefert die Datenbank nur Namen von Personen, die ich über einen Pfad oder über meine Einsätze sehen darf; andere IDs werden ohne Fehler ausgelassen, Funktionspersonen nie geliefert.
- AK5: Gegeben der Admin (Anwesenheitserfassung nur lesen) oder der Vorstand, wenn er die Suche über alle Aktiven aufruft, dann lehnt die Datenbank ab (Rechte-Fall).
- AK6: Gegeben 300 Aktive, wenn ich suche, dann kommt das Ergebnis in weniger als 300 ms.
**Nicht Teil dieser Story:** Oberfläche der Anwesenheitserfassung; Inhalt von `ez_person_visible` (legt die Anwesenheitserfassung fest); Eigenschaften, Kontaktdaten, Ehrenamtsstatus.

### US-AD-30: Helfer:innen beim Arbeitseinsatz anlegen oder wieder aktiv eintragen
**Als** Referent:in mit Rechten in der Anwesenheitserfassung
**möchte ich** beim Arbeitseinsatz neue Helfer:innen anlegen und ruhende, ausgeschiedene oder bisher nicht aktive Personen direkt wieder aktiv eintragen,
**damit** alle Helfer:innen eines Einsatzes erfasst sind und ein Mensch nur einmal existiert.
**Priorität:** Must · **Regeln:** R3, R40, R45, R45a · **Abhängig von:** US-AD-25, US-AD-28 · **Nachtrag:** v0.8 (Übergabe EZ A4, A9)
**Akzeptanzkriterien**
- AK1: Gegeben Rita Referentin (Klettern), wenn sie beim Arbeitseinsatz im Referat Klettern eine neue Person mit Vor- und Nachname anlegt, dann hat die Person Ehrenamtsstatus „aktiv“, die Funktion Helfer:in im Referat Klettern und als Anlagemodul die Anwesenheitserfassung; eine Kontakt-E-Mail ist optional.
- AK2: Gegeben eine ähnliche Person existiert, wenn Rita die neue Person anlegen will, dann zeigt der Dublettendialog die Treffer nach R40 mit „Diese Person eintragen“.
- AK3: Gegeben Olga Ausgeschieden, wenn Rita sie beim Arbeitseinsatz im Referat Klettern einträgt, dann ist Olga „aktiv“ mit Eintrag in der Historie und hat die Funktion Helfer:in im Referat Klettern; das gilt auch, wenn sie zuletzt in einem anderen Referat aktiv war.
- AK4: Gegeben Paul Nurgruppe ohne Ehrenamtsstatus, wenn Rita ihn beim Arbeitseinsatz einträgt, dann ist er „aktiv“ mit der Funktion Helfer:in im Referat Klettern.
- AK5: Gegeben ein Arbeitseinsatz im Referat Ausbildung, wenn Rita dort eine Person anlegt oder wieder aktiv einträgt, dann erscheint „Du kannst nur Zuordnungen zu deinen Referaten pflegen.“ (Fehlerfall).
- AK6: Gegeben Rita will über die Anwesenheitserfassung eine andere Funktion als Helfer:in setzen (z. B. Trainer:in), wenn sie speichert, dann erscheint „Für diesen Bereich hast du keine Rechte.“ (Fehlerfall).
- AK7: Gegeben der Vorstand ohne Rechte in der Anwesenheitserfassung, wenn er eine Person anlegen oder wieder aktiv eintragen will, dann lehnt die Datenbank ab (Rechte-Fall).
**Nicht Teil dieser Story:** Oberfläche der Anwesenheitserfassung; Bestätigung „Person informiert“ (spec.md EZ R29); Anwesenheit am Einsatz.

---

## Prüfung Definition of Ready (Stand 21.10.2026)

| Kriterium | Status |
|---|---|
| Rechtevorlage, Ziel und Nutzen benannt | erfüllt für alle Stories |
| Akzeptanzkriterien testbar (Given-When-Then) | erfüllt |
| Fehlerfall und Rechte-Fall je Story | erfüllt |
| Begriffe im Glossar | erfüllt (glossar.md v1.1: Referat, Gremium, Lesestufe, Feld, Kategorie, Ehrenamtsstatus, Rufname, Reichweite); „Pfad“ (AD, EA, GR) ist nur in spec.md Abschnitt 3 definiert |
| Datenfelder im Datenmodell der Spec | erfüllt (spec.md v0.7 Abschnitt 2) |
| Regeln per ID referenziert | erfüllt (R1–R42) |
| Keine [OFFEN]-Punkte, Annahmen sichtbar | US-AD-01 bis US-AD-19 erfüllt; US-AD-20 bis US-AD-26: Annahmen v0.7 in spec.md Abschnitt 11, Freigabe durch den Product Owner offen |
| „Nicht Teil dieser Story“ ausgefüllt | erfüllt |
