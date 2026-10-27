# Stories: Schnittstellen-Connector

Stand: 27.10.2026 · Version 0.1 · Kürzel: SC · Status: Entwurf
Quellen: 00-steckbrief.md (v0.5), 01-erhebung.md (v0.3, Regeln R1–R16), rollen.md (v1.4), glossar.md (v1.11), tech-stack.md (v0.9).
Umfang: MVP – Rahmen für Anbindungen, API-Key-Verwaltung, E-Mail-Versand über Brevo mit Postausgang und Vorlagen, Protokoll, Erinnerung vor Ablauf eines Keys, Anlass „Anmeldung des Notfall-Admins“ (AD). Nicht: DATEV (Iteration 1), Instagram (Iteration 2), Anlässe der Fachmodule EA und FI (eigene Stories dort).
Änderungen v0.1: Erster Entwurf.

Beispiele sind fiktiv (Personen, Adressen, Keys). Name in der Oberfläche: „Schnittstellen“.

## Zusätzliche Regeln (Ergänzung zu 01-erhebung.md, Abschnitt D)

- **R17 – Nur lesen ohne Recht:** Mit SC lesen (Geschäftsstelle) sind Schaltflächen zum Anlegen, Ändern, Testen, Aktivieren, Abschalten, Erneut senden und Verwerfen nicht sichtbar; die Datenbank lehnt die Aktionen ab („Dafür fehlt dir das Recht.“).
- **R18 – Leere Zustände:** ohne Anbindung „Es ist noch keine Schnittstelle angebunden.“; leerer Postausgang „Keine E-Mails in den letzten 90 Tagen.“; leeres Protokoll „Keine Einträge in den letzten 90 Tagen.“

## Übersicht

| ID | Titel | Priorität | Rechtevorlage | Regeln |
|---|---|---|---|---|
| US-SC-01 | Schnittstellen ansehen | Must | Admin, Geschäftsstelle | R11, R17, R18 |
| US-SC-02 | E-Mail-Anbindung anlegen | Must | Admin | R11, R14, R15 |
| US-SC-03 | Test-E-Mail senden und Anbindung aktivieren | Must | Admin | R3, R4, R15 |
| US-SC-04 | API-Key wechseln | Must | Admin | R3, R11, R15 |
| US-SC-05 | Anbindung abschalten | Must | Admin | R15 |
| US-SC-06 | Module für eine Anbindung freigeben | Must | Admin | R2, R15 |
| US-SC-07 | Vorlage eines Anlasses pflegen | Must | Admin | R8, R9, R15 |
| US-SC-08 | E-Mail in den Postausgang legen | Must | Fachmodul (Funktion) | R2, R5, R8, R10, R16 |
| US-SC-09 | E-Mails versenden und wiederholen | Must | System (Job) | R1, R7, R13 |
| US-SC-10 | Postausgang ansehen, erneut senden, verwerfen | Must | Admin, Geschäftsstelle (lesen) | R12, R17 |
| US-SC-11 | Protokoll ansehen | Must | Admin, Geschäftsstelle | R12, R15 |
| US-SC-12 | Erinnerung vor Ablauf eines API-Keys | Must | System (Job), Admin | R6 |
| US-SC-13 | Hinweis auf Störungen | Should | Admin, Geschäftsstelle | R6, R7 |
| US-SC-14 | E-Mail bei Anmeldung des Notfall-Admins | Must | System, Admin | R2, R5, R8 |
| US-SC-15 | Postausgang und Protokoll nach 90 Tagen löschen | Must | System (Job) | R12 |
| US-SC-16 | Testdaten und Startwerte | Must | – (Seed, Migration) | R14 |

---

### US-SC-01: Schnittstellen ansehen
**Als** Nutzer mit Rechtevorlage Admin oder Geschäftsstelle
**möchte ich** auf der Seite „Schnittstellen“ alle Anbindungen mit Zustand, letztem erfolgreichem Aufruf, Ablaufdatum des Keys und freigegebenen Modulen sehen,
**damit** ich erkenne, ob der E-Mail-Versand funktioniert.
**Priorität:** Must · **Regeln:** R11, R17, R18 · **Abhängig von:** US-SC-16

**Akzeptanzkriterien**
- AK1: Gegeben die Anbindung „E-Mail Sektion“ ist aktiv, wenn ich die Seite öffne, dann sehe ich Art „E-Mail (Brevo)“, Zustand „aktiv“, Key „…k3x9“, letzten erfolgreichen Aufruf und die freigegebenen Module.
- AK2: Gegeben ich habe SC lesen (Geschäftsstelle), wenn ich die Seite öffne, dann sehe ich dieselbe Liste ohne Schaltflächen zum Ändern (R17).
- AK3: Gegeben ich habe kein Recht auf SC (z. B. Referent:in), wenn ich die Adresse der Seite aufrufe, dann erscheint „Dafür fehlt dir das Recht.“ und die Navigation zeigt „Schnittstellen“ nicht.
- AK4: Gegeben es gibt keine Anbindung, wenn ich die Seite öffne, dann steht dort „Es ist noch keine Schnittstelle angebunden.“ (R18).
- AK5: Gegeben irgendein Nutzer liest die Tabelle der Anbindungen über die Datenbank-API, dann enthält das Ergebnis keinen Key und keinen Verweis, mit dem sich der Key aus Vault lesen ließe (R11).

**Nicht Teil dieser Story:** Pflege (US-SC-02 bis US-SC-07); Hinweise auf der Startseite (US-SC-13).

### US-SC-02: E-Mail-Anbindung anlegen
**Als** Admin
**möchte ich** eine Anbindung der Art „E-Mail (Brevo)“ mit Name, Absenderadresse, Absendername, API-Key und optionalem Ablaufdatum anlegen,
**damit** das Vereins OS E-Mails versenden kann, ohne dass der Key im Code oder im Frontend steht.
**Priorität:** Must · **Regeln:** R11, R14, R15 · **Abhängig von:** US-SC-01

**Akzeptanzkriterien**
- AK1: Gegeben ich gebe Name „E-Mail Sektion“, Absender „vereinsos.test@example.org“, Absendername „DAV Leipzig – Vereins OS“ und einen Key ein, wenn ich speichere, dann ist die Anbindung mit Zustand „abgeschaltet“ angelegt, der Key liegt in Vault und es werden nur die letzten 4 Zeichen angezeigt.
- AK2: Gegeben ich lasse Name, Absenderadresse oder Key leer oder die Absenderadresse ist ungültig, wenn ich speichere, dann erscheint am Feld eine Fehlermeldung (z. B. „Bitte gib eine gültige E-Mail-Adresse ein.“) und nichts wird gespeichert.
- AK3: Gegeben ich habe gespeichert, wenn ich die Anbindung erneut öffne, dann ist das Feld „API-Key“ leer mit dem Hinweis „hinterlegt: …k3x9“; der Key ist nicht abrufbar (R11).
- AK4: Gegeben ich habe nur SC lesen, wenn ich versuche, eine Anbindung anzulegen (auch direkt über die Datenbank-API), dann wird abgelehnt (R17).
- AK5: Gegeben ich speichere, dann steht im Protokoll „Anbindung angelegt“ mit Nutzer und Zeitpunkt, ohne Key (R15).

**Nicht Teil dieser Story:** Testaufruf und Aktivieren (US-SC-03); andere Arten als E-Mail (Iterationen).

### US-SC-03: Test-E-Mail senden und Anbindung aktivieren
**Als** Admin
**möchte ich** eine Test-E-Mail an meine Login-Adresse senden und die Anbindung danach aktivieren,
**damit** nur eine geprüfte Anbindung E-Mails aus Abläufen versendet.
**Priorität:** Must · **Regeln:** R3, R4, R15 · **Abhängig von:** US-SC-02

**Akzeptanzkriterien**
- AK1: Gegeben die Anbindung ist abgeschaltet und der Key gültig, wenn ich „Test-E-Mail senden“ wähle, dann geht über Brevo eine E-Mail des Anlasses „Test-E-Mail“ an meine Login-Adresse, und die Seite meldet „Test erfolgreich“.
- AK2: Gegeben der Key ist ungültig, wenn ich „Test-E-Mail senden“ wähle, dann meldet die Seite „Test fehlgeschlagen“ mit der gekürzten Meldung von Brevo (z. B. „Key not found“), der Zustand bleibt, und „aktivieren“ ist nicht möglich.
- AK3: Gegeben der letzte Test nach der letzten Änderung war erfolgreich, wenn ich „aktivieren“ wähle, dann ist die Anbindung „aktiv“; ohne erfolgreichen Test erscheint „Bitte zuerst einen erfolgreichen Test durchführen.“ (R3).
- AK4: Gegeben schon eine E-Mail-Anbindung ist aktiv, wenn ich eine zweite aktiviere, dann erscheint „Es ist schon eine E-Mail-Anbindung aktiv.“ (R4).
- AK5: Gegeben ich habe nur SC lesen, dann sehe ich weder „Test-E-Mail senden“ noch „aktivieren“, und die Funktion lehnt den Aufruf ab (R17).

**Nicht Teil dieser Story:** Test an eine frei wählbare Adresse [ANNAHME: nur an die eigene Login-Adresse].

### US-SC-04: API-Key wechseln
**Als** Admin
**möchte ich** den Key einer Anbindung durch einen neuen ersetzen und das Ablaufdatum ändern,
**damit** ich einen kompromittierten oder ablaufenden Key tauschen kann, ohne Code zu ändern.
**Priorität:** Must · **Regeln:** R3, R11, R15 · **Abhängig von:** US-SC-03

**Akzeptanzkriterien**
- AK1: Gegeben eine aktive Anbindung, wenn ich einen neuen Key speichere, dann ist der alte Key in Vault überschrieben, „zuletzt gewechselt“ zeigt heute und mich, und direkt danach wird eine Test-E-Mail angeboten.
- AK2: Gegeben der Test mit dem neuen Key schlägt fehl, dann wechselt die Anbindung auf „gestört“; wartende E-Mails bleiben im Postausgang (R3, R7).
- AK3: Gegeben die Anbindung war „abgelaufen“, wenn ich einen neuen Key mit neuem Ablaufdatum speichere und der Test erfolgreich ist, dann kann ich sie wieder aktivieren.
- AK4: Gegeben ich habe nur SC lesen, dann kann ich keinen Key speichern (R17).
- AK5: Gegeben ich wechsle den Key, dann steht im Protokoll „Key gewechselt“ mit den letzten 4 Zeichen des neuen Keys, nicht mit dem Key (R15).

**Nicht Teil dieser Story:** Key in Brevo erzeugen oder sperren (macht der Admin im Brevo-Konto).

### US-SC-05: Anbindung abschalten
**Als** Admin
**möchte ich** eine aktive Anbindung abschalten,
**damit** bei einem Problem (z. B. Verdacht auf missbrauchten Key) sofort keine E-Mails mehr hinausgehen.
**Priorität:** Must · **Regeln:** R15 · **Abhängig von:** US-SC-03

**Akzeptanzkriterien**
- AK1: Gegeben eine aktive Anbindung, wenn ich „abschalten“ wähle und bestätige, dann ist sie „abgeschaltet“, und der Job versendet keine E-Mails mehr über sie.
- AK2: Gegeben E-Mails warten im Postausgang, wenn ich abschalte, dann bleiben sie „wartet“ und werden nach erneutem Aktivieren versendet; älter als 7 Tage → „fehlgeschlagen“ mit Grund „zu alt“.
- AK3: Gegeben ich habe nur SC lesen, dann gibt es kein „abschalten“ (R17).
- AK4: Gegeben ich schalte ab, dann steht im Protokoll „Anbindung abgeschaltet“ mit Nutzer und Zeitpunkt.

**Nicht Teil dieser Story:** Löschen einer Anbindung [ANNAHME: kein Löschen im MVP].

### US-SC-06: Module für eine Anbindung freigeben
**Als** Admin
**möchte ich** je Anbindung festlegen, welche Module sie nutzen dürfen,
**damit** ein Modul nur die Dienste nutzt, die es braucht.
**Priorität:** Must · **Regeln:** R2, R15 · **Abhängig von:** US-SC-02

**Akzeptanzkriterien**
- AK1: Gegeben die Anbindung „E-Mail Sektion“, wenn ich die Module AD und SC freigebe und speichere, dann dürfen nur AD und SC E-Mails über sie einstellen.
- AK2: Gegeben EA ist nicht freigegeben, wenn EA eine E-Mail einstellen will, dann erhält EA den Fehler „Die Schnittstelle ist für dieses Modul nicht freigegeben.“ und es entsteht kein Eintrag im Postausgang (R2).
- AK3: Gegeben ich nehme die Freigabe für ein Modul zurück, dann werden schon wartende E-Mails dieses Moduls noch versendet, neue abgelehnt.
- AK4: Gegeben ich habe nur SC lesen, dann sehe ich die Freigaben, kann sie aber nicht ändern (R17).

**Nicht Teil dieser Story:** Freigabe je Anlass statt je Modul.

### US-SC-07: Vorlage eines Anlasses pflegen
**Als** Admin
**möchte ich** Betreff und Text der E-Mail eines Anlasses ändern und mit Beispielwerten ansehen,
**damit** die E-Mails verständlich sind, ohne dass Code geändert wird.
**Priorität:** Must · **Regeln:** R8, R9, R15 · **Abhängig von:** US-SC-16

**Akzeptanzkriterien**
- AK1: Gegeben der Anlass „Anmeldung des Notfall-Admins“ mit erlaubten Platzhaltern `{zeitpunkt}` und `{link}`, wenn ich den Text ändere und speichere, dann gilt der neue Text für alle E-Mails, die danach in den Postausgang kommen.
- AK2: Gegeben ich verwende einen nicht erlaubten Platzhalter (z. B. `{vorname}`), wenn ich speichere, dann erscheint „Der Platzhalter {vorname} ist für diesen Anlass nicht erlaubt.“ und nichts wird gespeichert (R8, R9).
- AK3: Gegeben Betreff länger als 150 oder Text länger als 2.000 Zeichen, wenn ich speichere, dann erscheint eine Fehlermeldung mit der Höchstlänge (R9).
- AK4: Gegeben ich wähle „Vorschau“, dann sehe ich Betreff und Text mit Beispielwerten.
- AK5: Gegeben ich habe nur SC lesen, dann sehe ich die Anlässe ohne Texte und ohne „ändern“ (R17).

**Nicht Teil dieser Story:** Anlässe anlegen oder löschen (nur per Migration des nutzenden Moduls); Formatierung (HTML) [ANNAHME: reiner Text mit Link].

### US-SC-08: E-Mail in den Postausgang legen
**Als** Fachmodul (über die Funktion des SC, im Namen des angemeldeten Nutzers oder eines Jobs)
**möchte ich** eine E-Mail eines eigenen Anlasses an eine Person mit Werten der Platzhalter und einem Schlüssel einstellen,
**damit** ich E-Mails verschicken kann, ohne Dienst, Key oder Adresse zu kennen.
**Priorität:** Must · **Regeln:** R2, R5, R8, R10, R16 · **Abhängig von:** US-SC-06, US-SC-07

**Akzeptanzkriterien**
- AK1: Gegeben AD ist freigegeben und Person 1 hat einen aktiven Zugang, wenn AD den Anlass „Anmeldung des Notfall-Admins“ für Person 1 einstellt, dann liegt eine E-Mail mit Zustand „wartet“ an die Login-Adresse von Person 1 im Postausgang, Text aus der Vorlage, Anrede ohne Namen.
- AK2: Gegeben die Person hat keinen aktiven Zugang, aber eine Kontakt-E-Mail, dann geht die E-Mail an die Kontakt-E-Mail; hat sie keine von beiden, erhält das Modul „Für diese Person ist keine E-Mail-Adresse hinterlegt.“ (R5).
- AK3: Gegeben eine E-Mail mit demselben Schlüssel liegt schon im Postausgang (nicht „verworfen“), wenn das Modul sie erneut einstellt, dann entsteht keine zweite (R10).
- AK4: Gegeben das Modul ist für keine aktive Anbindung freigegeben, dann erhält es „Die Schnittstelle ist für dieses Modul nicht freigegeben.“ (R2).
- AK5: Gegeben ein Modul stellt einen Anlass eines anderen Moduls ein (z. B. EA den Anlass von AD), dann wird abgelehnt; ein Nutzer kann die Funktion nicht direkt aus dem Frontend aufrufen [ANNAHME: nur aus Datenbankfunktionen der Module].

**Nicht Teil dieser Story:** Fachliche Entscheidung, wann eine E-Mail fällig ist (Fachmodul); Abbestellen (R16).

### US-SC-09: E-Mails versenden und wiederholen
**Als** System (Job alle 5 Minuten)
**möchte ich** wartende E-Mails über die aktive Anbindung an Brevo übergeben und bei Fehlern wiederholen,
**damit** E-Mails zuverlässig ankommen und Störungen sichtbar werden.
**Priorität:** Must · **Regeln:** R1, R7, R13 · **Abhängig von:** US-SC-08

**Akzeptanzkriterien**
- AK1: Gegeben eine E-Mail „wartet“ und die Anbindung ist aktiv, wenn der Job läuft, dann übergibt die Edge Function sie an Brevo; nimmt Brevo an, ist sie „versendet“ mit Zeitpunkt, und im Protokoll steht „Versand erfolgreich“.
- AK2: Gegeben Brevo meldet einen Fehler, dann bleibt die E-Mail „wartet“, nächster Versuch nach 15 Minuten, dann nach 1 Stunde; nach dem 3. Fehler ist sie „fehlgeschlagen“ mit der gekürzten Meldung (R7).
- AK3: Gegeben 3 Aufrufe in Folge sind fehlgeschlagen, dann wechselt die Anbindung auf „gestört“ und der Job versendet bis zum nächsten erfolgreichen Test nichts mehr über sie (R7).
- AK4: Gegeben in der laufenden Stunde wurden schon 100 E-Mails übergeben, dann bleiben weitere „wartet“ bis zur nächsten Stunde (R13).
- AK5: Gegeben die Anbindung ist abgeschaltet, gestört oder abgelaufen, dann versendet der Job nichts; der Key wird nur in der Edge Function aus Vault gelesen und nie gespeichert oder protokolliert (R1, R11).

**Nicht Teil dieser Story:** Zustellbestätigungen und Öffnungen aus Brevo (kein Tracking, [ANNAHME]).

### US-SC-10: Postausgang ansehen, erneut senden, verwerfen
**Als** Admin (Geschäftsstelle nur lesen)
**möchte ich** den Postausgang mit Filtern ansehen und fehlgeschlagene E-Mails erneut senden oder verwerfen,
**damit** keine wichtige E-Mail verloren geht.
**Priorität:** Must · **Regeln:** R12, R17 · **Abhängig von:** US-SC-09

**Akzeptanzkriterien**
- AK1: Gegeben E-Mails der letzten 90 Tage, wenn ich den Postausgang öffne, dann sehe ich je E-Mail Anlass, Modul, Empfängeradresse, Zustand, Versuche, letzte Fehlermeldung, eingestellt und versendet am; Filter nach Zustand, Modul, Anlass und Zeitraum.
- AK2: Gegeben eine E-Mail ist „fehlgeschlagen“, wenn ich „erneut senden“ wähle, dann ist sie wieder „wartet“ mit 0 Versuchen; wenn ich „verwerfen“ wähle und bestätige, ist sie „verworfen“.
- AK3: Gegeben ich bin Admin, dann kann ich Betreff und Text einer E-Mail öffnen; mit SC lesen (Geschäftsstelle) sehe ich Betreff und Text nicht und habe keine Aktionen (R17, Erhebung E1).
- AK4: Gegeben eine E-Mail ist „versendet“, dann gibt es kein „erneut senden“ und kein „verwerfen“.
- AK5: Gegeben der Postausgang ist leer, dann steht dort „Keine E-Mails in den letzten 90 Tagen.“ (R18).

**Nicht Teil dieser Story:** E-Mail von Hand schreiben und versenden.

### US-SC-11: Protokoll ansehen
**Als** Admin oder Geschäftsstelle
**möchte ich** das Protokoll der Aufrufe und Änderungen mit Filtern ansehen,
**damit** ich nachvollziehen kann, wer was geändert hat und wann ein Dienst gestört war.
**Priorität:** Must · **Regeln:** R12, R15 · **Abhängig von:** US-SC-02

**Akzeptanzkriterien**
- AK1: Gegeben Einträge der letzten 90 Tage, wenn ich das Protokoll öffne, dann sehe ich Zeitpunkt, Anbindung, Modul, Nutzer oder Job, Art (Test, Versand, Keywechsel, Zustandswechsel, Freigabe, Vorlage), Ergebnis und Meldung; Filter nach Anbindung, Art, Ergebnis und Zeitraum.
- AK2: Gegeben ein Eintrag zu einem Keywechsel, dann enthält er nur die letzten 4 Zeichen des Keys.
- AK3: Gegeben ich habe kein Recht auf SC, dann kann ich das Protokoll weder in der Oberfläche noch über die Datenbank-API lesen.
- AK4: Gegeben niemand, auch nicht der Admin, wählt „ändern“ oder „löschen“ an einem Eintrag, dann gibt es diese Aktionen nicht; die Datenbank lehnt Änderungen ab.

**Nicht Teil dieser Story:** Export des Protokolls.

### US-SC-12: Erinnerung vor Ablauf eines API-Keys
**Als** Admin
**möchte ich** 30 Tage und 7 Tage vor dem Ablaufdatum eines Keys eine E-Mail bekommen,
**damit** kein Key unbemerkt abläuft.
**Priorität:** Must · **Regeln:** R6 · **Abhängig von:** US-SC-08, US-SC-09

**Akzeptanzkriterien**
- AK1: Gegeben eine Anbindung mit Ablaufdatum 30.06.2027, wenn der tägliche Job am 31.05.2027 läuft, dann liegt für jeden Nutzer mit SC verwalten eine E-Mail des Anlasses „Ablauf eines API-Keys“ im Postausgang (Platzhalter: Name der Anbindung, Ablaufdatum, Link); am 23.06.2027 ebenso.
- AK2: Gegeben der Job läuft am selben Tag zweimal, dann entsteht keine zweite E-Mail (Schlüssel aus Anbindung, Ablaufdatum und Stufe 30/7, R10).
- AK3: Gegeben das Ablaufdatum ist erreicht, dann wechselt die Anbindung auf „abgelaufen“ (R6).
- AK4: Gegeben die Anbindung hat kein Ablaufdatum, dann gibt es keine Erinnerung.
- AK5: Gegeben ein Nutzer hat nur SC lesen (Geschäftsstelle), dann erhält er keine E-Mail, sieht aber den Hinweis auf der Seite (US-SC-13).

**Nicht Teil dieser Story:** Erinnerung über andere Wege (z. B. Aufgabe im Aufgabenmanagement).

### US-SC-13: Hinweis auf Störungen
**Als** Admin oder Geschäftsstelle
**möchte ich** oben auf der Seite „Schnittstellen“ und auf der Startseite einen Hinweis sehen, wenn eine Anbindung gestört oder abgelaufen ist, ein Key in den nächsten 30 Tagen abläuft oder E-Mails fehlgeschlagen sind,
**damit** ich eine Störung bemerke, auch wenn keine E-Mail mehr hinausgeht.
**Priorität:** Should · **Regeln:** R6, R7 · **Abhängig von:** US-SC-01, US-SC-09

**Akzeptanzkriterien**
- AK1: Gegeben die Anbindung ist „gestört“, wenn ich die Startseite öffne, dann sehe ich „Der E-Mail-Versand ist gestört. Prüfe die Schnittstellen.“ mit Link.
- AK2: Gegeben 2 E-Mails sind „fehlgeschlagen“, dann zeigt der Hinweis „2 E-Mails konnten nicht versendet werden.“ mit Link zum gefilterten Postausgang.
- AK3: Gegeben alles ist in Ordnung, dann gibt es keinen Hinweis.
- AK4: Gegeben ich habe kein Recht auf SC, dann sehe ich den Hinweis nicht.

**Nicht Teil dieser Story:** Benachrichtigung per E-Mail bei Störung (nicht möglich, wenn der Versand selbst gestört ist).

### US-SC-14: E-Mail bei Anmeldung des Notfall-Admins
**Als** Admin
**möchte ich** bei jeder Anmeldung des Notfall-Admins eine E-Mail bekommen,
**damit** ich eine unerwartete Nutzung des Notfallzugangs sofort bemerke.
**Priorität:** Must · **Regeln:** R2, R5, R8 · **Abhängig von:** US-SC-08; AD (Protokoll „Anmeldung Notfall-Admin“)

**Akzeptanzkriterien**
- AK1: Gegeben der Notfall-Admin meldet sich an und AD ist für die aktive Anbindung freigegeben, dann liegt für jeden anderen Nutzer mit aktivem Zugang und AD verwalten eine E-Mail des Anlasses „Anmeldung des Notfall-Admins“ (Platzhalter `{zeitpunkt}`, `{link}`) im Postausgang.
- AK2: Gegeben der Notfall-Admin selbst, dann erhält er keine E-Mail über die eigene Anmeldung.
- AK3: Gegeben AD ist nicht freigegeben oder es gibt keine aktive Anbindung, dann scheitert die Anmeldung trotzdem nicht; der bisherige Hinweis in AD bleibt (`ad_pending_emergency_logins`), und im Protokoll des SC steht die Ablehnung.
- AK4: Gegeben die E-Mail, dann enthält sie keinen Namen und keine weiteren Personendaten (R8).

**Nicht Teil dieser Story:** Änderung der Bestätigung im AD (`emergency_acknowledged_until`) bleibt wie umgesetzt.

### US-SC-15: Postausgang und Protokoll nach 90 Tagen löschen
**Als** System (täglicher Job)
**möchte ich** E-Mails im Postausgang und Einträge im Protokoll 90 Tage nach dem letzten Zustandswechsel löschen,
**damit** Empfängeradressen nicht länger als nötig gespeichert sind.
**Priorität:** Must · **Regeln:** R12 · **Abhängig von:** US-SC-09

**Akzeptanzkriterien**
- AK1: Gegeben eine E-Mail „versendet“ am 01.01.2027, wenn der Job am 01.04.2027 läuft, dann ist sie gelöscht; eine vom 03.01.2027 bleibt.
- AK2: Gegeben eine E-Mail „wartet“ seit mehr als 90 Tagen (z. B. Anbindung lange abgeschaltet), dann wurde sie vorher nach 7 Tagen „fehlgeschlagen“ und wird 90 Tage danach gelöscht.
- AK3: Gegeben Einträge im Protokoll älter als 90 Tage, dann sind sie gelöscht; Anbindungen, Freigaben und Vorlagen bleiben.
- AK4: Gegeben ein Nutzer, auch der Admin, dann kann er E-Mails und Einträge nicht selbst löschen; nur der Job löscht.

**Nicht Teil dieser Story:** Löschung bei Brevo (Einstellung im Brevo-Konto, Erhebung F).

### US-SC-16: Testdaten und Startwerte
**Als** Product Owner
**möchte ich** in TEST fiktive Daten und Testzugänge für den SC,
**damit** ich alle Stories ohne Echtdaten und ohne echten Key prüfen kann.
**Priorität:** Must · **Regeln:** R14 · **Abhängig von:** –

**Akzeptanzkriterien**
- AK1: Gegeben eine leere Datenbank, wenn die Migrationen laufen, dann gibt es die Anlässe „Test-E-Mail“, „Ablauf eines API-Keys“ (SC) und „Anmeldung des Notfall-Admins“ (AD) mit Starttexten, und `ad_modules.is_available` ist für SC gesetzt.
- AK2: Gegeben die Vorlage „Geschäftsstelle“ hat SC noch ohne Stufe, wenn die Migration läuft, dann erhält sie SC lesen; hat der Admin die Vorlage schon geändert, wird nichts überschrieben.
- AK3: Gegeben der Seed läuft gegen TEST, dann gibt es eine abgeschaltete Anbindung „E-Mail Test“ ohne Key, Absender `vereinsos.test@example.org`, freigegeben für AD und SC, sowie fiktive E-Mails im Postausgang in allen Zuständen; keine echte Adresse außer den Testzugängen `@dav-leipzig.de`.
- AK4: Gegeben der Seed wird gegen PROD gestartet, dann bricht er ab (seed.sh).

**Nicht Teil dieser Story:** Echter Brevo-Key in TEST (hinterlegt der Admin in der Oberfläche, Erhebung E9).
