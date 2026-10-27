# Steckbrief: Schnittstellen-Connector

Stand: 27.10.2026 · Version 0.1 · Kürzel: SC · Priorität: spätestens mit OA (4) [ANNAHME], Start der Erhebung jetzt (Product Owner 27.10.2026) · Ablage: docs/specs/sc-schnittstellen/ · Status: Entwurf · Product Owner: Toni Werner
Grundlage: vision.md (Basis: Administration und Schnittstellen-Connector), modul-landkarte.md v2.18, tech-stack.md (Abschnitte 1 und 4), rollen.md (Rechte-Matrix), glossar.md v1.8 („Basismodul“, „API-Key“), offene-punkte.md v5.19 (Abschnitt SC), querschnitt-administration.md (P8, P9, P10, P16), Anforderungen aus den Steckbriefen und Specs von AD, EA, FI, DS, TK, AM (siehe „Abhängigkeiten“).
Änderungen v0.1: Erster Entwurf (Auftrag Product Owner 27.10.2026: „neues Modul Konnektor, bei dem wir mehrere APIs anbinden können; die Schnittstellen sollen durch die Module im Vereins OS genutzt werden“). Bisher verstreute Anforderungen an SC aus allen Modulen gesammelt; Schnitt des MVP als Vorschlag.

**Problem heute:**
Das Vereins OS spricht heute mit keinem externen Dienst außer Supabase Auth (Login-Mails). Jedes Modul hat Anforderungen an externe Dienste zurückgestellt „bis SC kommt“: Das Ehrenamtsmanagement kann nicht per E-Mail vor dem Ablauf einer Lizenz erinnern, Finanzen nicht vor den Abgabefristen 31.07. und 15.12., der Notfall-Admin meldet sich an, ohne dass jemand davon erfährt, und der 1. Vorsitzende lädt den DATEV-Export jeden Monat als CSV von Hand hoch. Beispiel: Eine Trainer:in-Lizenz läuft am 31.12. ab; die Ablaufwarnung steht nur im Vereins OS, die Trainer:in selbst erfährt es erst, wenn die Geschäftsstelle sie anschreibt. Würde jedes Modul seine Dienste selbst anbinden, lägen Zugangsdaten an mehreren Stellen, und jede Anbindung würde mehrfach gebaut.

**Ziel / Erfolgsmessung:**
- Grundsatz [ANNAHME]: Externe Dienste werden **einmal zentral** im Schnittstellen-Connector angebunden; die Fachmodule nutzen sie über einheitliche Funktionen, ohne den Dienst, seine Adresse oder seinen API-Key zu kennen. Ein neuer Dienst braucht keine Änderung an den Fachmodulen, die ihn nicht nutzen.
- [ANNAHME] MVP: Der Admin sieht auf einer Seite alle angebundenen Dienste mit Zustand (aktiv, gestört, abgelaufen), letztem erfolgreichem Aufruf und Ablaufdatum des API-Keys; er hinterlegt und wechselt API-Keys, ohne Code zu ändern und ohne dass der Key danach noch lesbar ist.
- [ANNAHME] MVP: Mindestens ein Fachmodul versendet über SC eine E-Mail aus einem Ablauf (Vorschlag: Ehrenamtsmanagement, Erinnerung vor Ablauf einer Qualifikation). Messgröße: keine manuellen Erinnerungsmails der Geschäftsstelle mehr für ablaufende Lizenzen.
- [ANNAHME] Kein API-Key läuft unbemerkt ab: Erinnerung an den Admin 30 Tage vorher.
- [OFFEN] Weitere Messgrößen (z. B. Zeitersparnis beim monatlichen DATEV-Import, sobald die DATEV-Anbindung kommt).

**Nutzer & Rechtevorlagen:**
- Admin – SC verwalten (Startwert seit dem Kern der Administration, rollen.md Abschnitt 5): Dienste anbinden, API-Keys hinterlegen und wechseln, Anbindung aktivieren und abschalten, Protokoll der Aufrufe lesen, Testaufruf auslösen.
- Geschäftsstelle – SC: kein Zugriff (Startwert). [OFFEN] Soll die Geschäftsstelle den Zustand der Dienste lesen (z. B. „E-Mail-Versand gestört“), ohne Keys zu pflegen?
- Fachmodule (kein Nutzer): nutzen eine Anbindung über serverseitige Funktionen. Das Recht prüft das **aufrufende Modul** mit dem Recht des angemeldeten Nutzers auf dieses Modul (z. B. „Erinnerung senden“ nur mit EA bearbeiten); ein Recht auf SC ist dafür nicht nötig [ANNAHME].
- Zeitgesteuerte Abläufe (pg_cron, ohne angemeldeten Nutzer, querschnitt P16) nutzen SC ebenfalls; sie laufen als Datenbankfunktion des jeweiligen Moduls.
- [ANNAHME] Je Anbindung legt der Admin fest, **welche Module** sie nutzen dürfen (z. B. DATEV nur für FI). Ein Modul ohne Freigabe erhält eine Fehlermeldung, kein stilles Scheitern.

**Begriffe [ANNAHME: Vorschlag, nach Bestätigung ins Glossar]:**
- **Dienst:** externer Anbieter, mit dem das Vereins OS Daten austauscht (z. B. Gmail, DATEV, Instagram, Umfrage-Dienst).
- **Anbindung:** konfigurierte Verbindung zu einem Dienst im Schnittstellen-Connector (Art, Name, Zustand, API-Key, freigegebene Module). Ein Dienst kann mehrere Anbindungen haben (z. B. zwei Postfächer) [ANNAHME].
- **Aufruf:** einzelne Anfrage eines Moduls über eine Anbindung, mit Ergebnis (erfolgreich, fehlgeschlagen, wartet).
- **Postausgang:** Warteschlange der zu versendenden E-Mails mit Stand (wartet, versendet, fehlgeschlagen).
- „API-Key“ und „Basismodul“ stehen schon im Glossar. [OFFEN] Name des Moduls: Im Auftrag heißt es „Konnektor“, im Glossar und in der Modul-Landkarte „Schnittstellen-Connector“ (Q-SC1).

**Im Scope (MVP) [ANNAHME: Vorschlag, Schnitt mit dem Product Owner klären (Q-SC2)]:**
- **Rahmen für Anbindungen** (generisch): Liste der Anbindungen je Art; Felder Art, Name, Zustand (aktiv, abgeschaltet, gestört), freigegebene Module, Ablaufdatum des API-Keys, zuletzt gewechselt, letzter erfolgreicher Aufruf, letzter Fehler. Eine neue Art von Anbindung kommt per Migration und Edge Function hinzu, die Pflege in der Oberfläche ist für alle Arten gleich.
- **API-Key-Verwaltung** (Erweiterung aus der Administration, querschnitt P10, Seite „Einstellungen“): Key nur hineinschreiben (Supabase Vault), danach nie wieder anzeigen, nur die letzten 4 Zeichen [ANNAHME]; wechseln; Ablaufdatum; Erinnerung an den Admin 30 Tage vor Ablauf [ANNAHME: Frist]. Metadaten in einer Tabelle des Moduls (tech-stack.md 1: „Tabelle im Modul AD“; [OFFEN] Präfix `ad_` oder `sc_`, Q-SC9).
- **Ein Aufrufweg für alle Module:** Fachmodule rufen nie direkt einen Dienst auf, sondern eine Funktion des SC (Datenbankfunktion bzw. Edge Function); nur SC liest den Key aus Vault. Aufrufe laufen ausschließlich serverseitig (modul-landkarte.md, Regeln).
- **Protokoll der Aufrufe:** wer (Modul, ggf. Nutzer), wann, welche Anbindung, Ergebnis, Fehlermeldung des Dienstes; **ohne Inhalte und ohne Personendaten** außer der technischen Kennung des Empfängers [ANNAHME]. Löschung nach 90 Tagen [ANNAHME: Frist].
- **Erste Anbindung: E-Mail-Versand** über das Google-Konto der Sektion (tech-stack.md 4) mit Postausgang: Module legen eine E-Mail in den Postausgang (Empfänger, Vorlage, Link ins Vereins OS); ein Job versendet sie, wiederholt bei Fehlern bis zu 3-mal [ANNAHME] und zeigt fehlgeschlagene Mails dem Admin. Regel aus tech-stack.md 4: keine Personendaten außer Empfängeradresse und kurzem Hinweis mit Link.
- **Vorlagen für E-Mails** je Anlass (Betreff, Text mit Platzhaltern, Ansprache mit „du“); Pflege [OFFEN] (Q-SC6).
- **Testaufruf** je Anbindung durch den Admin (z. B. Test-E-Mail an die eigene Adresse), damit ein gewechselter Key sofort geprüft ist.
- Mobil lesbar ab 375 px.

**Iteration 1 (nach dem MVP, je Anlass im nutzenden Modul) [ANNAHME]:**
- Erste Nutzer des E-Mail-Versands: EA – E-Mail vor Ablauf einer Qualifikation (offene-punkte.md; Vorlauf nach dem Regelwerk der Ablaufwarnung) und Geburtstagserinnerung (offen in EA); AD – Hinweis bei Anmeldung des Notfall-Admins; FI – Erinnerung vor den Abgabefristen (31.07., 15.12.) und an „durchgeführt, nicht abgerechnet, älter als 4 Wochen“. Die Stories dazu gehören in das jeweilige Modul, SC liefert nur den Versand [ANNAHME].
- **Benachrichtigungseinstellungen je Nutzer** (abbestellen je Anlass; querschnitt P9) [OFFEN] ob in SC oder AD.

**Später (eigene Iterationen, sobald das nutzende Modul so weit ist):**
- **DATEV:** Import der Buchungen in den Bereich Budget von Finanzen statt CSV (Q-DS7, B13 der Übergabe DS → FI); Rechenregeln und Prüfungen des Budgets bleiben gleich. [OFFEN] welche Schnittstelle (DATEVconnect, DATEV-Datenservice) und Kosten (Q-SC4).
- **Instagram:** Beiträge aus der Öffentlichkeitsarbeit veröffentlichen (mit OA). [OFFEN] Voraussetzungen (Business-Konto, Meta-App, Prüfung durch Meta) (Q-SC5).
- **Umfrage-Dienst:** Umfragen anlegen und Ergebnisse abholen (mit OA). [OFFEN] welcher Dienst (Q-SC5).
- **Sparkasse:** Überweisungs- und Lastschriftdateien heute als Datei zum manuellen Hochladen (FI); eine direkte Bankschnittstelle (z. B. EBICS) nur nach eigener Entscheidung [ANNAHME: nicht geplant].
- **Yolawo:** Schreib-Schnittstelle für Angebote nur, falls Yolawo eine anbietet ([OFFEN], tk-touren-kurse/00-steckbrief.md).
- **Microsoft Graph** statt Gmail für den Versand über die Vereinsdomain, nach Zustimmung des Bundesverbands (tech-stack.md 4).

**Nicht im Scope:**
- Login-Mails (Einladung, Passwort zurücksetzen): bleiben direkt bei Supabase Auth (00-steckbrief.md AD, Abhängigkeiten).
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
- Extern: Google-Konto der Sektion (SMTP mit App-Passwort), Supabase Vault, Edge Functions, pg_cron; später DATEV, Meta (Instagram), Umfrage-Dienst, ggf. Microsoft Graph.

**Risiken / Besonderheiten:**
- **Secrets:** Keys nur in Supabase Vault; kein Key im Repository, im Frontend, in `.env`-Dateien oder in einer für Nutzer lesbaren Tabelle (CLAUDE.md, modul-landkarte.md). Die Tabelle der Anbindungen enthält nur Metadaten. TEST und PROD haben **getrennte Keys**; in TEST nur Test-Konten bzw. Sandbox der Dienste [ANNAHME].
- **Datenschutz E-Mail:** Für das normale Gmail-Konto gibt es keinen Auftragsverarbeitungsvertrag (tech-stack.md 4). Daher Mails ohne Personendaten außer Empfänger und Link. Empfängeradressen von Aktiven außerhalb von @dav-leipzig.de (Kontakt-E-Mail) sind Personendaten im Postausgang und im Protokoll; Löschfrist [ANNAHME: 90 Tage].
- **Datenschutz DATEV:** Buchungstexte enthalten Namen von Personen; gleiche Regeln wie beim CSV-Import des Bereichs Budget (ds-dashboard/00-steckbrief.md, Risiken). Auftragsverarbeitung mit DATEV klären.
- **Grenzen der Dienste:** Gmail begrenzt den Versand (Tageslimit des Kontos); Supabase Free-Plan begrenzt Aufrufe von Edge Functions. Für ca. 4 bis 30 Nutzer und einige Dutzend Erinnerungen im Monat ausreichend [ANNAHME].
- **Zustellung:** Mails aus einem Gmail-Konto an DAV-Adressen (Microsoft-Tenant) können im Spam landen; vor Go-live testen (tech-stack.md 4).
- **Kosten:** E-Mail über Gmail kostenfrei; DATEV-Schnittstelle, Instagram-Freigabe und Umfrage-Dienst ggf. kostenpflichtig [OFFEN].
- **Nie gegen PROD testen:** Testaufrufe und Seeds nur in TEST; der Seed legt keine echten Keys an.

**Offene Fragen:**
- [OFFEN] **Q-SC1** Name: „Schnittstellen-Connector“ (Glossar, Landkarte, Code `SC`) beibehalten oder in der Oberfläche „Konnektor“ bzw. „Schnittstellen“? Vorschlag: Code bleibt `SC`; in der Oberfläche „Schnittstellen“, weil Nutzer:innen dort Dienste sehen, nicht eine Technik.
- [OFFEN] **Q-SC2** Schnitt des MVP: Rahmen + API-Key-Verwaltung + E-Mail-Versand (Vorschlag), oder zuerst DATEV (größter Handgriff im Monat), oder zuerst Instagram (OA)? Und Zeitpunkt: vor oder nach FI und DS?
- [OFFEN] **Q-SC3** Welche Dienste sollen angebunden werden? Bekannt: E-Mail (Gmail), DATEV, Instagram, Umfrage-Dienst. Weitere (z. B. Kalender, Cloud-Ablage, Messenger, Bundesverband)?
- [OFFEN] **Q-SC4** DATEV: welche Schnittstelle (DATEVconnect, DATEV-Datenservice, Export über die Steuerkanzlei), wer ist Vertragspartner, Kosten? Klärt: 1. Vorsitzender mit der Finanzbuchhaltung.
- [OFFEN] **Q-SC5** Instagram und Umfrage-Dienst: Gibt es ein Business-Konto der Sektion? Welcher Umfrage-Dienst (mit AV-Vertrag, EU-Server)? Klärt: Öffentlichkeitsarbeit.
- [OFFEN] **Q-SC6** Wer pflegt die Texte der E-Mail-Vorlagen: Admin, Geschäftsstelle oder fest im Code?
- [OFFEN] **Q-SC7** Braucht das Vereins OS eingehende Schnittstellen (z. B. Ergebnisse einer Umfrage per Webhook, Anfragen von Dritten)? Vorschlag: nein im MVP.
- [OFFEN] **Q-SC8** Gibt der Admin je Anbindung frei, welche Module sie nutzen dürfen (Vorschlag), oder darf jedes Modul jede Anbindung nutzen?
- [OFFEN] **Q-SC9** Ort der Tabelle für API-Keys: tech-stack.md nennt „Tabelle im Modul AD“ (`ad_api_keys`), der Vorschlag hier ist das Modul SC (`sc_…`), weil nur SC die Keys nutzt. Klärt: Product Owner (technisch, Vorschlag `sc_`).
- [OFFEN] **Q-SC10** Fristen: Erinnerung vor Ablauf eines Keys 30 Tage? Löschung des Protokolls und des Postausgangs nach 90 Tagen?
