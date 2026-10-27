# Erhebung: Schnittstellen-Connector

Datum: 27.10.2026 · Version 0.1 · Status: Entwurf · Beteiligte: Toni Werner (Product Owner)
Grundlage: 00-steckbrief.md v0.3, tech-stack.md v0.8 (Abschnitte 1 und 4), querschnitt-administration.md (P8, P9, P10, P16), spec.md AD (Zugänge, Protokoll, Notfall-Admin), spec.md EA (Kontakt-E-Mail, Ablaufwarnung).
Änderungen v0.1: Erster Entwurf für den MVP (Q-SC2, Product Owner 27.10.2026): Rahmen für Anbindungen, API-Key-Verwaltung, E-Mail-Versand mit Postausgang und Vorlagen, Protokoll. DATEV (Iteration 1) und Instagram (Iteration 2) nur in Abschnitt E.

Begriffe nach glossar.md v1.10 (u. a. Schnittstellen-Connector, API-Key, Basismodul). Neu und noch nicht im Glossar [ANNAHME: Begriffe nach Steckbrief]: **Dienst**, **Anbindung**, **Aufruf**, **Postausgang**, dazu **Anlass** (Grund einer E-Mail mit eigener Vorlage, z. B. „Ablauf eines API-Keys“).

**Zuschnitt:** SC transportiert nur. Wann eine E-Mail fällig ist und an wen, entscheidet das Fachmodul; SC kennt keine Fachdaten (keine Qualifikationen, Abrechnungen, Buchungen). Tabellen mit Präfix `sc_` (Q-SC9).

## A. Rechtevorlagen & Rechte

| Rechtevorlage | Recht | Was | Reichweite |
|---|---|---|---|
| Admin (auch Notfall-Admin) | SC verwalten (Startwert) | Anbindungen anlegen, ändern, abschalten; API-Key hinterlegen und wechseln; Module freigeben; Vorlagen der Anlässe pflegen (Q-SC6); Postausgang und Protokoll lesen; fehlgeschlagene E-Mail erneut senden oder verwerfen; Testaufruf | alle |
| Geschäftsstelle | – (Startwert) | kein Zugriff; [OFFEN] Zustand der Anbindungen lesen (E1) | – |
| Referent:in, Vorstand, Freigabe Touren und Kurse | – | kein Zugriff | – |
| Fachmodul (über eine Funktion) | Recht des angemeldeten Nutzers im Fachmodul | legt eine E-Mail eines eigenen Anlasses in den Postausgang; nur wenn die Anbindung für dieses Modul freigegeben ist (Q-SC8) | – |
| Zeitgesteuerter Ablauf (pg_cron) | ohne Nutzer | wie Fachmodul; läuft als Datenbankfunktion des Fachmoduls | – |

- Stufen in SC [ANNAHME]: **lesen** = Anbindungen, Zustand, Postausgang (ohne Inhalt), Protokoll ansehen; **bearbeiten** = zusätzlich Vorlagen pflegen, erneut senden, Testaufruf; **verwalten** = zusätzlich Anbindungen anlegen, Keys hinterlegen, Module freigeben, abschalten.
- Ein Recht auf SC gibt keine Rechte in den Fachmodulen; ein Recht in einem Fachmodul gibt kein Recht auf SC.
- Den API-Key liest **niemand** über die Oberfläche oder die Datenbank-API, auch nicht der Admin; nur die Edge Function des SC liest ihn aus Vault.
- Die Seite „Schnittstellen“ erscheint in der Navigation nur mit Recht auf SC (`ad_modules.is_available` für SC wird mit der ersten Oberfläche gesetzt, Muster wie DS und TK).

## B. Abläufe (inkl. Zustände)

**B1 – E-Mail-Anbindung einrichten** (Admin, einmalig je Umgebung)
1. Seite „Schnittstellen“ → „Anbindung anlegen“ → Art „E-Mail (SMTP)“ (im MVP die einzige Art).
2. Angaben: Name, Absenderadresse, Absendername, Server und Port (Vorgabe Google: smtp.gmail.com, 465), Benutzername, App-Passwort (= API-Key), Ablaufdatum des Keys (optional; ein Google-App-Passwort läuft nicht ab), freigegebene Module.
3. Speichern → App-Passwort geht nach Vault, angezeigt werden nur die letzten 4 Zeichen; Zustand „abgeschaltet“.
4. Testaufruf: Test-E-Mail an die Login-Adresse des Admins. Erfolg → „aktivieren“ möglich; Fehler → Meldung des Dienstes (z. B. „Anmeldung abgelehnt“), Zustand bleibt.
5. TEST und PROD haben je eigene Anbindungen mit eigenen Keys; der Seed legt in TEST eine Anbindung ohne gültigen Key an (R14).

**Zustände einer Anbindung**

| Von | Nach | Wer | Bedingung |
|---|---|---|---|
| – | abgeschaltet | Admin | angelegt |
| abgeschaltet | aktiv | Admin | Key hinterlegt, letzter Testaufruf erfolgreich (R3) |
| aktiv | abgeschaltet | Admin | – (E-Mails im Postausgang warten) |
| aktiv | gestört | System | 3 Aufrufe in Folge fehlgeschlagen (R7) [ANNAHME: Zahl] |
| gestört | aktiv | Admin | erfolgreicher Testaufruf (z. B. nach Wechsel des Keys) |
| aktiv | abgelaufen | System | Ablaufdatum des Keys erreicht (R6) |
| abgelaufen | aktiv | Admin | neuer Key mit neuem Ablaufdatum, Testaufruf erfolgreich |

**B2 – API-Key wechseln** (Admin)
Neuen Key eingeben (alter Key wird in Vault überschrieben), optional neues Ablaufdatum; „zuletzt gewechselt“ = heute; Testaufruf folgt direkt. Der alte Key ist danach nicht mehr abrufbar.

**B3 – Module freigeben** (Admin, Q-SC8)
Je Anbindung Häkchen je Modul (AD, EA, GR, EZ, TK, FI, DS, …). Entfernen der Freigabe: neue E-Mails dieses Moduls werden abgelehnt (R2); bereits im Postausgang liegende werden noch versendet [ANNAHME].

**B4 – Vorlage eines Anlasses pflegen** (Admin, Q-SC6)
1. Anlässe legt das nutzende Modul per Migration an (Code, Modul, Beschreibung, erlaubte Platzhalter, Starttext). Der Admin kann keine Anlässe anlegen oder löschen, nur Texte ändern [ANNAHME].
2. Admin ändert Betreff und Text; erlaubte Platzhalter werden angezeigt (z. B. `{link}`, `{frist}`); unbekannte Platzhalter → Fehlermeldung (R9).
3. Vorschau mit Beispielwerten; Speichern gilt für E-Mails, die danach in den Postausgang kommen.
4. Ansprache mit „du“; keine Personendaten außer Empfängeradresse, kurzem Hinweis und Link (R8).

**B5 – E-Mail versenden** (Fachmodul → Postausgang → Versand)
1. Ein Fachmodul ruft die Funktion des SC auf: Anlass, Empfänger (Person), Werte der Platzhalter, Bezug (z. B. Kennung der Eigenschaft), Schlüssel gegen Doppelversand.
2. SC prüft Freigabe (R2) und Schlüssel (R10), ermittelt die Adresse (R5), setzt den Text aus der Vorlage zusammen und legt die E-Mail mit „wartet“ in den Postausgang.
3. Ein Job versendet wartende E-Mails alle 5 Minuten [ANNAHME: Takt] über die aktive Anbindung.

**Zustände einer E-Mail im Postausgang**

| Von | Nach | Wer | Bedingung |
|---|---|---|---|
| – | wartet | Fachmodul | R2, R5, R10 erfüllt |
| wartet | versendet | System | Dienst hat die E-Mail angenommen |
| wartet | wartet | System | Fehler, Versuch 1 oder 2; nächster Versuch nach 15 Minuten, dann nach 1 Stunde (R7) [ANNAHME] |
| wartet | fehlgeschlagen | System | 3. Versuch fehlgeschlagen oder Adresse abgelehnt |
| fehlgeschlagen | wartet | Admin | „erneut senden“ |
| wartet, fehlgeschlagen | verworfen | Admin | „verwerfen“ |
| alle | gelöscht | System | 90 Tage nach dem letzten Zustandswechsel (R12) |

Ist die Anbindung abgeschaltet, gestört oder abgelaufen, bleiben E-Mails „wartet“ und gehen nach dem Aktivieren hinaus; älter als 7 Tage → „fehlgeschlagen“ mit Grund „zu alt“ [ANNAHME].

**B6 – Erinnerung vor Ablauf eines API-Keys** (System, täglich)
30 Tage vor dem Ablaufdatum (Q-SC10) und erneut 7 Tage vorher [ANNAHME] E-Mail des Anlasses „Ablauf eines API-Keys“ an alle Nutzer mit SC verwalten; zusätzlich Hinweis auf der Seite „Schnittstellen“. Betrifft der Ablauf die E-Mail-Anbindung selbst, geht die E-Mail noch über sie hinaus, solange sie gültig ist.

**B7 – Störung sichtbar machen** (System)
Gestörte, abgelaufene oder bald ablaufende Anbindungen und fehlgeschlagene E-Mails zeigt die Seite „Schnittstellen“ oben als Hinweis; zusätzlich ein Hinweis auf der Startseite für Nutzer mit SC verwalten [ANNAHME]. Eine E-Mail über die gestörte Anbindung selbst ist nicht möglich.

**B8 – Protokoll und Postausgang ansehen** (Admin)
Liste mit Filter (Anbindung, Modul, Anlass, Ergebnis, Zeitraum); E-Mails ohne Text, nur Anlass, Empfängeradresse, Zustand, Versuche, letzte Fehlermeldung.

**B9 – Erste Anlässe im MVP** [ANNAHME, E3]
- SC „Test-E-Mail“ (B1, B2).
- SC „Ablauf eines API-Keys“ (B6).
- AD „Anmeldung des Notfall-Admins“: E-Mail an alle Admins außer dem Notfall-Admin bei jeder Anmeldung des Notfall-Admins (bisher nur Hinweis in AD über `ad_pending_emergency_logins`).
- Danach je Fachmodul eigene Stories: EA „Ablauf einer Qualifikation“, FI „Abgabefrist der Abrechnung“, FI „durchgeführt, nicht abgerechnet“; später AM.

## C. Daten (Feld | Typ | Pflicht | Beispiel | Quelle)

**Anbindung** (`sc_connections`)

| Feld | Typ | Pflicht | Beispiel | Quelle |
|---|---|---|---|---|
| Art | Auswahl (MVP: E-Mail (SMTP)) | ja | E-Mail (SMTP) | Migration |
| Name | Text | ja | „E-Mail Sektion“ | Admin |
| Zustand | aktiv, abgeschaltet, gestört, abgelaufen | ja | aktiv | System / Admin |
| Einstellungen der Art | je Art (E-Mail: Absenderadresse, Absendername, Server, Port, Benutzer) | ja | vereinsos.test@example.org, „DAV Leipzig – Vereins OS“, smtp.gmail.com, 465 | Admin |
| Verweis auf den Key | Kennung des Eintrags in Vault | ja (zum Aktivieren) | – (nie angezeigt) | System |
| Letzte 4 Zeichen | Text | nein | „…k3x9“ | System |
| Ablaufdatum des Keys | Datum | nein | 30.06.2027 | Admin |
| Zuletzt gewechselt | Zeitpunkt, Nutzer | ja | 27.10.2026, Admin | System |
| Letzter erfolgreicher Aufruf | Zeitpunkt | nein | 27.10.2026 10:15 | System |
| Letzter Fehler | Zeitpunkt, Meldung | nein | „535 Anmeldung abgelehnt“ | System |
| Fehler in Folge | Zahl | ja | 0 | System |

**Freigabe** (`sc_connection_modules`): Anbindung, Modul (`ad_modules.code`), freigegeben von, am.

**Anlass** (`sc_mail_occasions`)

| Feld | Typ | Pflicht | Beispiel | Quelle |
|---|---|---|---|---|
| Code | Text | ja | `ad_emergency_login` | Migration des Moduls |
| Modul | Modulcode | ja | AD | Migration |
| Beschreibung | Text | ja | „Der Notfall-Admin hat sich angemeldet.“ | Migration |
| Erlaubte Platzhalter | Liste | ja | `{link}`, `{zeitpunkt}` | Migration |
| Betreff | Text | ja | „Vereins OS: Anmeldung des Notfall-Admins“ | Starttext Migration, danach Admin |
| Text | Text | ja | „Hallo, der Notfall-Admin hat sich am {zeitpunkt} angemeldet. Prüfe die Anmeldung: {link}“ | Starttext Migration, danach Admin |
| Geändert von, am | Nutzer, Zeitpunkt | ja | Admin, 27.10.2026 | System |

**E-Mail im Postausgang** (`sc_outbox`)

| Feld | Typ | Pflicht | Beispiel | Quelle |
|---|---|---|---|---|
| Anlass | Verweis | ja | `ad_emergency_login` | Fachmodul |
| Empfänger | Person (Verweis) und Adresse zum Zeitpunkt des Einstellens | ja | Person 1, test.admin@dav-leipzig.de | Fachmodul / SC (R5) |
| Betreff, Text | Text (zusammengesetzt) | ja | – | SC aus Vorlage |
| Schlüssel | Text | ja | `ad_emergency_login:2026-10-27T10:15:<Person>` | Fachmodul (R10) |
| Zustand | wartet, versendet, fehlgeschlagen, verworfen | ja | wartet | System / Admin |
| Versuche, nächster Versuch, letzte Fehlermeldung | Zahl, Zeitpunkt, Text | ja/nein | 1, 10:30, „Zeitüberschreitung“ | System |
| Eingestellt von | Modul, Nutzer oder Job | ja | AD, Job | System |
| Versendet am | Zeitpunkt | nein | 27.10.2026 10:20 | System |

**Protokoll** (`sc_call_log`): Zeitpunkt, Anbindung, Modul, Nutzer oder Job, Art des Aufrufs (Test, Versand, Keywechsel, Zustandswechsel), Ergebnis, Meldung des Dienstes (gekürzt, ohne Inhalte), Bezug auf die E-Mail im Postausgang. Löschung nach 90 Tagen (R12).

## D. Regeln (R1, R2 …)

- **R1** Externe Dienste ruft nur SC auf, nur serverseitig (Edge Function); kein Fachmodul und kein Frontend spricht einen Dienst direkt an.
- **R2** Ein Modul darf eine Anbindung nur nutzen, wenn der Admin sie für dieses Modul freigegeben hat; sonst Fehlermeldung „Die Schnittstelle ist für dieses Modul nicht freigegeben.“
- **R3** Aktivieren nur mit hinterlegtem Key und erfolgreichem Testaufruf nach der letzten Änderung von Key oder Einstellungen; sonst „Bitte zuerst einen erfolgreichen Test durchführen.“
- **R4** Je Art ist höchstens eine Anbindung aktiv [ANNAHME]; Aktivieren einer zweiten → „Es ist schon eine E-Mail-Anbindung aktiv.“
- **R5** Adresse: Login-Adresse des Zugangs, wenn die Person einen aktiven Zugang hat; sonst Kontakt-E-Mail (Eigenschaft `system_key = 'contact'`); ohne Adresse wird die E-Mail nicht eingestellt und das Fachmodul erhält den Fehler „Für diese Person ist keine E-Mail-Adresse hinterlegt.“ [ANNAHME; E4]
- **R6** Ist das Ablaufdatum erreicht, wechselt die Anbindung auf „abgelaufen“; Erinnerung 30 und 7 Tage vorher (B6).
- **R7** Bis zu 3 Versuche je E-Mail (sofort, nach 15 Minuten, nach 1 Stunde); nach 3 Fehlern in Folge über alle E-Mails wird die Anbindung „gestört“ [ANNAHME].
- **R8** E-Mails enthalten keine Personendaten außer Empfängeradresse, kurzem Hinweis und Link ins Vereins OS (tech-stack.md 4); Platzhalter für Namen, Geburtsdaten, Gesundheitsangaben, Bankdaten gibt es nicht [ANNAHME, E2].
- **R9** Eine Vorlage darf nur die erlaubten Platzhalter ihres Anlasses enthalten; Betreff höchstens 150 Zeichen, Text höchstens 2.000 Zeichen [ANNAHME].
- **R10** Gibt es für einen Schlüssel schon eine E-Mail im Postausgang (außer „verworfen“), wird keine zweite eingestellt (kein Doppelversand bei wiederholtem Job).
- **R11** Der API-Key ist nach dem Speichern für niemanden mehr lesbar; angezeigt werden nur die letzten 4 Zeichen.
- **R12** Postausgang und Protokoll werden 90 Tage nach dem letzten Zustandswechsel automatisch gelöscht (Q-SC10).
- **R13** Höchstens 100 E-Mails je Stunde über eine Anbindung [ANNAHME, E5]; darüber bleiben sie „wartet“.
- **R14** Kein echter Key im Repository, im Seed oder in TEST-Daten aus PROD; der Seed legt in TEST eine abgeschaltete Anbindung ohne Key an.
- **R15** Änderungen an Anbindungen, Keys, Freigaben und Vorlagen stehen im Protokoll (wer, wann, was; ohne Key).

## E. Schnittstellen

| Dienst | Richtung | Was | Wann / Stand |
|---|---|---|---|
| Google-Konto der Sektion (SMTP, App-Passwort) | SC → Dienst | E-Mails aus dem Postausgang | MVP |
| Supabase Vault | SC intern | Ablage der Keys | MVP |
| pg_cron | intern | Versand-Job (5 Minuten), Ablauf-Prüfung (täglich), Löschlauf (täglich) | MVP |
| AD | AD → SC | Zugänge (Login-Adresse), Module, Rechte; Anlass „Anmeldung des Notfall-Admins“ | MVP |
| EA | EA → SC | Kontakt-E-Mail (Eigenschaft); später Anlass „Ablauf einer Qualifikation“ | Adresse MVP, Anlass danach |
| FI | FI → SC | Anlässe Fristen und „nicht abgerechnet“ | nach dem MVP |
| DATEV | Dienst → SC → FI | Buchungen für den Bereich Budget | Iteration 1 (Q-SC4) |
| Instagram (Meta) | SC → Dienst | Beiträge der Öffentlichkeitsarbeit | Iteration 2 (Q-SC5) |

## F. Datenschutz

- Gespeichert werden Empfängeradressen und Texte der E-Mails im Postausgang sowie das Protokoll, je 90 Tage; danach automatische Löschung.
- Für das normale Gmail-Konto gibt es keinen Auftragsverarbeitungsvertrag; deshalb R8 (keine Personendaten im Inhalt).
- Empfänger:innen ohne DAV-Adresse (Kontakt-E-Mail von Aktiven) erhalten E-Mails über ein Gmail-Konto; Eintrag im Verarbeitungsverzeichnis der Sektion ergänzen (Product Owner).
- Den Inhalt einer E-Mail sieht nur der Admin im Postausgang [ANNAHME]; Lesestufe für die Geschäftsstelle siehe E1.
- Keys liegen nur in Vault; Fehlermeldungen des Dienstes werden gekürzt gespeichert und dürfen keinen Key enthalten.

## G. Nicht-funktional

- Versand innerhalb von 10 Minuten nach dem Einstellen, wenn die Anbindung aktiv ist [ANNAHME].
- Seite „Schnittstellen“ mobil nutzbar ab 375 px.
- Grenzen: Gmail-Tageslimit (normales Konto ca. 500 Empfänger je Tag), Supabase Free-Plan für Edge Functions; für erwartete Mengen (einige Dutzend E-Mails im Monat) ausreichend.
- Zustellung an DAV-Adressen (Microsoft-Tenant) vor dem Go-live testen (Spam-Filter, tech-stack.md 4).
- Nie gegen PROD testen; Testaufrufe nur in TEST mit einem Testkonto.

## Offene Fragen (Frage | Wer klärt | bis wann)

| Nr | Frage | Wer klärt | bis wann |
|---|---|---|---|
| E1 | Soll die Geschäftsstelle den Zustand der Schnittstellen und den Postausgang **lesen** (Startwert SC lesen), damit sie Störungen bemerkt, auch wenn der Admin nicht da ist? Vorschlag: ja, ohne Inhalt der E-Mails. | Product Owner | vor den Stories |
| E2 | Anrede mit Vornamen („Hallo Erika,“) oder ohne Namen („Hallo,“)? Der Vorname wäre ein Personendatum im Gmail-Konto ohne AV-Vertrag. Vorschlag: ohne Namen. | Product Owner | vor den Stories |
| E3 | Erste Anlässe im MVP: Test-E-Mail, Ablauf eines API-Keys und Anmeldung des Notfall-Admins (Vorschlag), oder gleich auch EA „Ablauf einer Qualifikation“? | Product Owner | vor den Stories |
| E4 | Adresse: Login-Adresse vor Kontakt-E-Mail (Vorschlag R5), oder soll das Fachmodul die Adressart wählen? | Product Owner | vor der Spec |
| E5 | Absender: Welches Google-Konto bzw. welche Absenderadresse und welcher Absendername (z. B. „DAV Leipzig – Vereins OS“)? Gibt es für TEST ein eigenes Testkonto? | Product Owner | vor der Abnahme in TEST |
| E6 | Abbestellen: Dürfen Nutzer einzelne Anlässe abbestellen (querschnitt P9), oder gehen Erinnerungen immer hinaus? Vorschlag: im MVP kein Abbestellen. | Product Owner | vor den Stories |
| E7 | Annahmen zu Zahlen bestätigen: 3 Versuche (sofort, 15 Minuten, 1 Stunde), Takt 5 Minuten, „zu alt“ nach 7 Tagen, zweite Erinnerung 7 Tage vor Ablauf, höchstens 100 E-Mails je Stunde. | Product Owner | vor der Spec |
