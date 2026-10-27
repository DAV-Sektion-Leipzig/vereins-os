# Steckbrief: Schnittstellen-Connector

Stand: 27.10.2026 · Version 0.6.2 · Kürzel: SC · Priorität: MVP jetzt, Finanzen und Dashboard sind umgesetzt (Product Owner 27.10.2026) · Ablage: docs/specs/sc-schnittstellen/ · Status: Entwurf · Product Owner: Toni Werner
Grundlage: vision.md (Basis: Administration und Schnittstellen-Connector), modul-landkarte.md v2.18, tech-stack.md (Abschnitte 1 und 4), rollen.md (Rechte-Matrix), glossar.md v1.8 („Basismodul“, „API-Key“), offene-punkte.md v5.19 (Abschnitt SC), querschnitt-administration.md (P8, P9, P10, P16), Anforderungen aus den Steckbriefen und Specs von AD, EA, FI, DS, TK, AM (siehe „Abhängigkeiten“).
Änderungen v0.6.2: Spec v0.2 Ready (Product Owner 27.10.2026).
Änderungen v0.6.1: Spec v0.1 (Entwurf, Tasks T1–T19).
Änderungen v0.6: Erhebung E8 bis E11 entschieden (Product Owner 27.10.2026): Absender `noreply@vereinsos.dav-leipzig.de`, Brevo-Konto angelegt, kostenloser Tarif mit höchstens 300 E-Mails am Tag, Login-Mails nicht im Scope (entfallen mit SSO).
Änderungen v0.5.1: Stories v0.1 (US-SC-01 bis US-SC-16).
Änderungen v0.5: E-Mail-Versand über **Brevo** statt Google-Konto (Erhebung E5, Product Owner 27.10.2026); E2 bis E7 der Erhebung entschieden.
Änderungen v0.4: Geschäftsstelle liest den SC (E1 der Erhebung, Product Owner 27.10.2026).
Änderungen v0.3: Q-SC6, Q-SC8, Q-SC9, Q-SC10 und Zeitpunkt entschieden (Product Owner 27.10.2026): Texte der E-Mail-Vorlagen pflegt der Admin; der Admin gibt je Anbindung die nutzenden Module frei; Tabellen der API-Keys im Modul SC (`sc_`); Erinnerung 30 Tage vor Ablauf, Löschung von Protokoll und Postausgang nach 90 Tagen; MVP jetzt. Erhebung v0.1.
Änderungen v0.2: Q-SC1 bis Q-SC4 entschieden (Product Owner 27.10.2026): Name in der Oberfläche „Schnittstellen“, Code bleibt `SC`; MVP = E-Mail-Versand, danach Iteration 1 DATEV, Iteration 2 Instagram; vorerst keine weiteren Dienste; DATEV klärt der Product Owner zu gegebener Zeit (vor Iteration 1).
Änderungen v0.1: Erster Entwurf (Auftrag Product Owner 27.10.2026: „neues Modul Konnektor, bei dem wir mehrere APIs anbinden können; die Schnittstellen sollen durch die Module im Vereins OS genutzt werden“). Bisher verstreute Anforderungen an SC aus allen Modulen gesammelt; Schnitt des MVP als Vorschlag.

**Problem heute:**
Das Vereins OS spricht heute mit keinem externen Dienst außer Supabase Auth (Login-Mails). Jedes Modul hat Anforderungen an externe Dienste zurückgestellt „bis SC kommt“: Das Ehrenamtsmanagement kann nicht per E-Mail vor dem Ablauf einer Lizenz erinnern, Finanzen nicht vor den Abgabefristen 31.07. und 15.12., der Notfall-Admin meldet sich an, ohne dass jemand davon erfährt, und der 1. Vorsitzende lädt den DATEV-Export jeden Monat als CSV von Hand hoch. Beispiel: Eine Trainer:in-Lizenz läuft am 31.12. ab; die Ablaufwarnung steht nur im Vereins OS, die Trainer:in selbst erfährt es erst, wenn die Geschäftsstelle sie anschreibt. Würde jedes Modul seine Dienste selbst anbinden, lägen Zugangsdaten an mehreren Stellen, und jede Anbindung würde mehrfach gebaut.

**Ziel / Erfolgsmessung:**
- Grundsatz [ANNAHME]: Externe Dienste werden **einmal zentral** im Schnittstellen-Connector angebunden; die Fachmodule nutzen sie über einheitliche Funktionen, ohne den Dienst, seine Adresse oder seinen API-Key zu kennen. Ein neuer Dienst braucht keine Änderung an den Fachmodulen, die ihn nicht nutzen.
- [ANNAHME] MVP: Der Admin sieht auf einer Seite alle angebundenen Dienste mit Zustand (aktiv, gestört, abgelaufen), letztem erfolgreichem Aufruf und Ablaufdatum des API-Keys; er hinterlegt und wechselt API-Keys, ohne Code zu ändern und ohne dass der Key danach noch lesbar ist.
- MVP (Erhebung E3, Product Owner 27.10.2026): Das Vereins OS versendet über SC die E-Mails „Test-E-Mail“, „Ablauf eines API-Keys“ und „Anmeldung des Notfall-Admins“ (AD). Danach als erster Anlass eines Fachmoduls: Erinnerung vor Ablauf einer Qualifikation (EA); Messgröße [ANNAHME]: keine manuellen Erinnerungsmails der Geschäftsstelle mehr für ablaufende Lizenzen.
- Kein API-Key läuft unbemerkt ab: Erinnerung an den Admin 30 Tage vorher (Q-SC10, Product Owner 27.10.2026).
- [OFFEN] Weitere Messgrößen (z. B. Zeitersparnis beim monatlichen DATEV-Import, sobald die DATEV-Anbindung kommt).

**Nutzer & Rechtevorlagen:**
- Admin – SC verwalten (Startwert seit dem Kern der Administration, rollen.md Abschnitt 5): Dienste anbinden, API-Keys hinterlegen und wechseln, Anbindung aktivieren und abschalten, Protokoll der Aufrufe lesen, Testaufruf auslösen.
- Geschäftsstelle – SC lesen (neuer Startwert, E1, Product Owner 27.10.2026): Zustand der Anbindungen, Störungen, Postausgang ohne Inhalt der E-Mails, Protokoll; keine Pflege, keine Keys.
- Fachmodule (kein Nutzer): nutzen eine Anbindung über serverseitige Funktionen. Das Recht prüft das **aufrufende Modul** mit dem Recht des angemeldeten Nutzers auf dieses Modul (z. B. „Erinnerung senden“ nur mit EA bearbeiten); ein Recht auf SC ist dafür nicht nötig [ANNAHME].
- Zeitgesteuerte Abläufe (pg_cron, ohne angemeldeten Nutzer, querschnitt P16) nutzen SC ebenfalls; sie laufen als Datenbankfunktion des jeweiligen Moduls.
- Je Anbindung legt der Admin fest, **welche Module** sie nutzen dürfen (Q-SC8, Product Owner 27.10.2026; z. B. DATEV nur für FI). Ein Modul ohne Freigabe erhält eine Fehlermeldung, kein stilles Scheitern.

**Begriffe** (im Glossar seit v1.12, Product Owner 27.10.2026):
- **Dienst:** externer Anbieter, mit dem das Vereins OS Daten austauscht (z. B. Brevo, DATEV, Instagram, Umfrage-Dienst).
- **Anbindung:** konfigurierte Verbindung zu einem Dienst im Schnittstellen-Connector (Art, Name, Zustand, API-Key, freigegebene Module). Ein Dienst kann mehrere Anbindungen haben (z. B. zwei Postfächer) [ANNAHME].
- **Aufruf:** einzelne Anfrage eines Moduls über eine Anbindung, mit Ergebnis (erfolgreich, fehlgeschlagen, wartet).
- **Postausgang:** Warteschlange der zu versendenden E-Mails mit Stand (wartet, versendet, fehlgeschlagen).
- „API-Key“ und „Basismodul“ stehen schon im Glossar.
- **Name** (Q-SC1, Product Owner 27.10.2026): Modul „Schnittstellen-Connector“, Code `SC`; Name in der Oberfläche **„Schnittstellen“** (Glossar v1.9).

**Im Scope (MVP)** (Q-SC2, Product Owner 27.10.2026: zuerst E-Mail-Versand; Einzelheiten [ANNAHME] bis zur Erhebung):
- **Rahmen für Anbindungen** (generisch): Liste der Anbindungen je Art; Felder Art, Name, Zustand (aktiv, abgeschaltet, gestört), freigegebene Module, Ablaufdatum des API-Keys, zuletzt gewechselt, letzter erfolgreicher Aufruf, letzter Fehler. Eine neue Art von Anbindung kommt per Migration und Edge Function hinzu, die Pflege in der Oberfläche ist für alle Arten gleich.
- **API-Key-Verwaltung** (Erweiterung aus der Administration, querschnitt P10, Seite „Einstellungen“): Key nur hineinschreiben (Supabase Vault), danach nie wieder anzeigen, nur die letzten 4 Zeichen [ANNAHME]; wechseln; Ablaufdatum; Erinnerung an den Admin 30 Tage vor Ablauf (Q-SC10). Metadaten in Tabellen des Moduls SC mit Präfix `sc_` (Q-SC9, Product Owner 27.10.2026; tech-stack.md angepasst).
- **Ein Aufrufweg für alle Module:** Fachmodule rufen nie direkt einen Dienst auf, sondern eine Funktion des SC (Datenbankfunktion bzw. Edge Function); nur SC liest den Key aus Vault. Aufrufe laufen ausschließlich serverseitig (modul-landkarte.md, Regeln).
- **Protokoll der Aufrufe:** wer (Modul, ggf. Nutzer), wann, welche Anbindung, Ergebnis, Fehlermeldung des Dienstes; **ohne Inhalte und ohne Personendaten** außer der technischen Kennung des Empfängers [ANNAHME]. Löschung nach 90 Tagen (Q-SC10).
- **Erste Anbindung: E-Mail-Versand** über **Brevo** (Dienst für transaktionale E-Mails; Erhebung E5, Product Owner 27.10.2026) mit Postausgang: Module legen eine E-Mail in den Postausgang (Empfänger, Vorlage, Link ins Vereins OS); ein Job versendet sie, wiederholt bei Fehlern bis zu 3-mal [ANNAHME] und zeigt fehlgeschlagene Mails dem Admin. Regel aus tech-stack.md 4: keine Personendaten außer Empfängeradresse und kurzem Hinweis mit Link; Anrede ohne Namen (Erhebung E2).
- **Vorlagen für E-Mails** je Anlass (Betreff, Text mit Platzhaltern, Ansprache mit „du“); die Texte pflegt der **Admin** (Q-SC6, Product Owner 27.10.2026).
- **Testaufruf** je Anbindung durch den Admin (z. B. Test-E-Mail an die eigene Adresse), damit ein gewechselter Key sofort geprüft ist.
- Mobil lesbar ab 375 px.

**Nutzung des E-Mail-Versands in den Fachmodulen (nach dem MVP, je Anlass im nutzenden Modul) [ANNAHME]:**
- Erste Nutzer des E-Mail-Versands: EA – E-Mail vor Ablauf einer Qualifikation (offene-punkte.md; Vorlauf nach dem Regelwerk der Ablaufwarnung) und Geburtstagserinnerung (offen in EA); AD – Hinweis bei Anmeldung des Notfall-Admins; FI – Erinnerung vor den Abgabefristen (31.07., 15.12.) und an „durchgeführt, nicht abgerechnet, älter als 4 Wochen“. Die Stories dazu gehören in das jeweilige Modul, SC liefert nur den Versand [ANNAHME].
- **Benachrichtigungseinstellungen je Nutzer** (abbestellen je Anlass; querschnitt P9) [OFFEN] ob in SC oder AD.

**Iteration 1 – DATEV** (Q-SC2, Product Owner 27.10.2026):
- Import der Buchungen in den Bereich Budget von Finanzen statt CSV (Q-DS7, B13 der Übergabe DS → FI); Rechenregeln und Prüfungen des Budgets bleiben gleich.
- Schnittstelle, Vertragspartner und Kosten klärt der Product Owner zu gegebener Zeit, spätestens vor Beginn der Iteration (Q-SC4).

**Iteration 2 – Instagram** (Q-SC2, Product Owner 27.10.2026):
- Beiträge aus der Öffentlichkeitsarbeit veröffentlichen (mit OA). [OFFEN] Voraussetzungen (Business-Konto, Meta-App, Prüfung durch Meta) (Q-SC5).

**Vorerst keine weiteren Dienste** (Q-SC3, Product Owner 27.10.2026). Merkposten ohne Reihenfolge, nur nach eigener Entscheidung:
- **Umfrage-Dienst:** Umfragen anlegen und Ergebnisse abholen (mit OA). [OFFEN] welcher Dienst (Q-SC5).
- **Sparkasse:** Überweisungs- und Lastschriftdateien bleiben Dateien zum manuellen Hochladen (FI); keine direkte Bankschnittstelle.
- **Yolawo:** Schreib-Schnittstelle für Angebote nur, falls Yolawo eine anbietet (tk-touren-kurse/00-steckbrief.md).
- **Microsoft Graph** statt Brevo für den Versand über die Vereinsdomain, nach Zustimmung des Bundesverbands (tech-stack.md 4).

**Nicht im Scope:**
- Login-Mails (Einladung, Passwort zurücksetzen): bleiben direkt bei Supabase Auth und entfallen mit SSO (Erhebung E11, Product Owner 27.10.2026).
- Fachlogik der nutzenden Module: wann eine Erinnerung fällig ist, welche Buchungen importiert werden oder was ein Instagram-Beitrag enthält, entscheidet das Fachmodul; SC transportiert nur.
- Eingehende Schnittstellen, über die externe Dienste Daten in das Vereins OS schreiben (Webhooks, eigene API für Dritte) [ANNAHME; Q-SC7].
- Schnittstelle zur Mitgliederverwaltung bzw. zu Salesforce (glossar.md: keine Schnittstelle; querschnitt P18).
- Massenversand und Newsletter an Mitglieder (keine Mitgliederdaten im Vereins OS) [ANNAHME].
- Frei konfigurierbare Anbindungen durch Nutzer ohne Code (z. B. beliebige URL mit Key eintragen); jede Art von Anbindung wird programmiert und per Pull Request freigegeben [ANNAHME].

**Abhängigkeiten:**
- AD → SC: Modul SC mit Rechtevorlagen (Startwert Admin SC verwalten, besteht seit dem Kern), Zugänge und Login-Adressen als Empfänger, Seite „Einstellungen“; Kontakt-E-Mail als Eigenschaft (`system_key = 'contact'`, querschnitt P9). [OFFEN] ob `ad_modules.is_available` für SC erst mit der ersten Oberfläche gesetzt wird (Muster wie DS, TK).
- SC → AD: API-Key-Verwaltung (bisher als „nach MVP bzw. mit SC“ in AD zurückgestellt; offene-punkte.md: Erinnerung vor Ablauf eines API-Keys „verschoben zu SC“); E-Mail bei Anmeldung des Notfall-Admins.
- SC → EA: E-Mail vor Ablauf einer Qualifikation; Geburtstagserinnerung (ea-ehrenamt/00-steckbrief.md, 01-erhebung.md „nach MVP“).
- SC → FI: Erinnerungen (Fristen, „nicht abgerechnet“); DATEV-Import für den Bereich Budget (statt CSV); ggf. Übergabe des Buchungslaufs (fi-finanzen/00-steckbrief.md, offene Fragen).
- SC → DS: indirekt über FI (DATEV-Import, Datenstand); Kennzahlen der Öffentlichkeitsarbeit später (sichten.md, „C“).
- SC → OA: Instagram, Umfrage-Dienst.
- SC → AM: E-Mail-Versand für Erinnerungen an Aufgaben, auch an Personen ohne Zugang (querschnitt P8, Q7).
- SC → TK: keine im MVP (Yolawo nur manuell).
- Extern: Brevo (API-Key), Supabase Vault, Edge Functions, pg_cron; später DATEV, Meta (Instagram), Umfrage-Dienst, ggf. Microsoft Graph.

**Risiken / Besonderheiten:**
- **Secrets:** Keys nur in Supabase Vault; kein Key im Repository, im Frontend, in `.env`-Dateien oder in einer für Nutzer lesbaren Tabelle (CLAUDE.md, modul-landkarte.md). Die Tabelle der Anbindungen enthält nur Metadaten. TEST und PROD haben **getrennte Keys**; in TEST nur Test-Konten bzw. Sandbox der Dienste [ANNAHME].
- **Datenschutz E-Mail:** Brevo ist Auftragsverarbeiter; das Konto der Sektion ist angelegt, Auftragsverarbeitungsvertrag prüft der Product Owner (Erhebung E9). Mails bleiben trotzdem ohne Personendaten außer Empfänger und Link, Anrede ohne Namen (Erhebung E2). Empfängeradressen von Aktiven außerhalb von @dav-leipzig.de (Kontakt-E-Mail) sind Personendaten im Postausgang und im Protokoll; Löschfrist 90 Tage (Q-SC10).
- **Datenschutz DATEV:** Buchungstexte enthalten Namen von Personen; gleiche Regeln wie beim CSV-Import des Bereichs Budget (ds-dashboard/00-steckbrief.md, Risiken). Auftragsverarbeitung mit DATEV klären.
- **Grenzen der Dienste:** kostenloser Brevo-Tarif mit höchstens **300 E-Mails am Tag** (Erhebung E10, R13), TEST und PROD im selben Konto; Supabase Free-Plan begrenzt Aufrufe von Edge Functions. Für ca. 4 bis 30 Nutzer und einige Dutzend Erinnerungen im Monat ausreichend [ANNAHME].
- **Zustellung:** Absender `noreply@vereinsos.dav-leipzig.de`, Domain in Brevo eingerichtet (Erhebung E8); Zustellung an DAV-Adressen (Microsoft-Tenant) vor Go-live in TEST prüfen.
- **Kosten:** Brevo im kostenlosen Tarif (Erhebung E10); DATEV-Schnittstelle, Instagram-Freigabe und Umfrage-Dienst ggf. kostenpflichtig [OFFEN].
- **Nie gegen PROD testen:** Testaufrufe und Seeds nur in TEST; der Seed legt keine echten Keys an.

**Offene Fragen:**
- Q-SC1 – **entschieden 27.10.2026:** Name in der Oberfläche „Schnittstellen“; Modul „Schnittstellen-Connector“, Code `SC`.
- Q-SC2 – **entschieden 27.10.2026:** MVP = E-Mail-Versand (mit Rahmen und API-Key-Verwaltung); Iteration 1 DATEV; Iteration 2 Instagram. Zeitpunkt (Product Owner 27.10.2026): MVP jetzt; Finanzen und Dashboard sind umgesetzt.
- Q-SC3 – **entschieden 27.10.2026:** vorerst keine weiteren Dienste.
- Q-SC4 – **zurückgestellt 27.10.2026:** DATEV-Schnittstelle, Vertragspartner und Kosten klärt der Product Owner zu gegebener Zeit, spätestens vor Iteration 1; kein Hindernis für den MVP.
- [OFFEN] **Q-SC5** Instagram (Iteration 2) und Umfrage-Dienst (Merkposten): Gibt es ein Business-Konto der Sektion? Welcher Umfrage-Dienst (mit AV-Vertrag, EU-Server)? Klärt: Öffentlichkeitsarbeit, vor Iteration 2.
- Q-SC6 – **entschieden 27.10.2026:** Die Texte der E-Mail-Vorlagen pflegt der Admin.
- [OFFEN] **Q-SC7** Braucht das Vereins OS eingehende Schnittstellen (z. B. Ergebnisse einer Umfrage per Webhook, Anfragen von Dritten)? Vorschlag: nein im MVP.
- Q-SC8 – **entschieden 27.10.2026:** Der Admin gibt je Anbindung frei, welche Module sie nutzen dürfen.
- Q-SC9 – **entschieden 27.10.2026:** Tabellen der API-Keys im Modul SC (Präfix `sc_`), nicht `ad_api_keys`.
- Q-SC10 – **entschieden 27.10.2026:** Erinnerung 30 Tage vor Ablauf eines Keys; Protokoll und Postausgang werden nach 90 Tagen gelöscht.
- Fragen zu Einzelheiten des MVP: 01-erhebung.md, „Offene Fragen“ (alle entschieden, 27.10.2026).
