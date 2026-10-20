# Erhebung: Administration (AD)

Datum: 20.10.2026 · Version 0.7 · Status: abgestimmt · Beteiligte: Toni Werner (Product Owner, Admin), Claude (Requirements Engineering)

Grundlage: 00-steckbrief.md v0.9, glossar.md v0.4, rollen.md v0.6, tech-stack.md.

## A. Rechtevorlagen & Rechte

| Rechtevorlage | AD | SC | EA | GR | FI | OA | PM | GS | AM |
|---|---|---|---|---|---|---|---|---|---|
| Admin | verwalten | verwalten | verwalten | – | – | – | – | – | – |
| Geschäftsstelle | – | – | verwalten | verwalten | verwalten | verwalten | verwalten | verwalten | verwalten |
| Vorstand | – | – | – | – | – | – | – | – | – |

- Vorstand: Vorlage wird ohne Rechte angelegt; der Admin konfiguriert sie später in der Oberfläche.
- Stufen: lesen = ansehen · bearbeiten = anlegen und ändern · verwalten = zusätzlich löschen, exportieren, Abläufe auslösen.
- Rechte nur je Modul, Reichweite immer „alle“. Einzige Ausnahme: vertrauliche Eigenschaften (siehe R8).
- AD verwalten umfasst: Personen anlegen, Zugänge einladen/sperren/entsperren, Rechtevorlagen pflegen und zuweisen, Eigenschaftsarten anlegen und ändern, Eigenschaften pflegen, vertrauliche Eigenschaften lesen, Protokoll einsehen.
- Eine Person kann mehrere Vorlagen haben; Rechte addieren sich (R6).
- Toni Werner hat im MVP die Vorlagen Admin und Vorstand.
- Notfall-Admin: zweiter Zugang mit Vorlage Admin, Login-Adresse geschaeftsstelle@dav-leipzig.de, hängt an der Funktionsperson „Geschäftsstelle“ (R14, R15).

## B. Abläufe (inkl. Zustände)

### B1 Person anlegen (manuell, in AD)
1. Admin gibt Vorname, Nachname und optional Login-Adresse ein.
2. System prüft auf Dubletten (R3). Bei Verdacht: Warnung mit Liste ähnlicher Personen; Admin wählt „trotzdem anlegen“ oder „abbrechen“ bzw. öffnet die vorhandene Person.
3. Person ist angelegt, Zugangsstatus „kein Zugang“.

### B2 Zugang einrichten und einladen
1. Admin öffnet eine Person (manuell angelegt oder aus dem Import in EA).
2. Admin trägt die Login-Adresse ein (R1, R2) und weist mindestens eine Rechtevorlage zu. Ohne Vorlage ist keine Einladung möglich (R17).
3. Admin klickt „Einladen“. Supabase Auth sendet die Einladungs-Mail.
4. Status „eingeladen“. Der Nutzer setzt über den Link sein Passwort → Status „aktiv“. Ein geöffneter Link ohne gespeichertes Passwort ändert den Status nicht.
5. Ersteinrichtung: Die erste Einladung (Admin) erfolgt einmalig über das Supabase-Dashboard; der Status wechselt dabei ebenfalls auf „eingeladen“.

### B3 Einladung erneut senden
Bei Status „eingeladen“ (z. B. Link abgelaufen): Admin klickt „Erneut einladen“.
Ist die Login-Adresse falsch, ändert der Admin sie. Die Einladung wird damit zurückgenommen (alter Link ungültig, Status „kein Zugang“); danach lädt der Admin an die neue Adresse ein (R20).

### B4 Passwort vergessen
Nutzer klickt auf der Login-Seite „Passwort vergessen“, gibt seine Login-Adresse ein und setzt das Passwort über den Link selbst. Kein Eingriff des Admins. Die Seite meldet nicht, ob die Adresse existiert (R18).

### B5 Rechtevorlage zuweisen / entziehen
Admin weist einer Person Vorlagen zu oder entzieht sie. Wirksam spätestens mit Ablauf der laufenden Sitzung (bis zu 1 Stunde). Keine Befristung in der Oberfläche (nach MVP); das Datenmodell sieht gültig von/bis bereits vor.

### B6 Zugang sperren / entsperren
Admin sperrt einen Zugang (z. B. Ausscheiden). Kein neuer Login möglich; laufende Sitzung endet spätestens nach Ablauf (bis zu 1 Stunde). Entsperren stellt den vorherigen Zustand wieder her. Eine Einladung zurückziehen = Zugang im Status „eingeladen“ sperren.

### B7 Ausscheiden
Zugang sperren (B6) und Eigenschaften mit Enddatum versehen. Keine Löschung in AD; Löschung nach der 5-Jahres-Regel durch EA.

### B8 Rechtevorlage anlegen / ändern
Admin legt eine Vorlage mit Namen an und setzt je Modul eine Stufe. Änderungen wirken für alle Personen mit dieser Vorlage, spätestens mit Ablauf der laufenden Sitzung.

### B9 Eigenschaftsart anlegen / ändern
Admin gibt Name, Zweck (Pflicht), Datentyp (Text, Datum, Ja/Nein, Auswahlliste), bei Auswahlliste die Auswahlwerte, „sichtbar in“ und „vertraulich“ an. Beim Anlegen erscheint der Hinweis zu Art. 9 DSGVO.

### B10 Eigenschaft einer Person pflegen
Admin legt an einer Person eine Eigenschaft an (Eigenschaftsart, Wert, gültig von, optional gültig bis) oder beendet sie (gültig bis setzen). Frühere Werte bleiben als Historie erhalten.

### B11 Notfall-Zugang nutzen
1. Ist der Admin nicht erreichbar oder ausgesperrt, meldet sich jemand mit Zugriff auf das Postfach geschaeftsstelle@dav-leipzig.de als Notfall-Admin an (ggf. über „Passwort vergessen“).
2. Das System protokolliert jede Anmeldung des Notfall-Admins (R16).
3. Der Admin sieht beim nächsten Aufruf von AD einen Hinweis auf Anmeldungen des Notfall-Admins seit seinem letzten Besuch (kein E-Mail-Versand im MVP).

### B12 Protokoll einsehen
Admin öffnet in AD das Protokoll und sieht die Einträge, neueste zuerst.

### Zustände Zugang

| Von | Nach | Wer | Bedingung |
|---|---|---|---|
| kein Zugang | eingeladen | Admin | Login-Adresse gültig (R1, R2), mind. eine Vorlage zugewiesen (R17) |
| kein Zugang | eingeladen | System | Einladung über das Supabase-Dashboard (Ersteinrichtung) |
| eingeladen | eingeladen | Admin | erneut einladen |
| eingeladen | kein Zugang | Admin | Login-Adresse geändert; alter Link ungültig (R20) |
| eingeladen | aktiv | Nutzer | Passwort über Einladungslink gesetzt |
| eingeladen | gesperrt | Admin | Einladung zurückziehen |
| aktiv | gesperrt | Admin | – (R10) |
| gesperrt | aktiv | Admin | Nutzer hatte bereits ein Passwort gesetzt |
| gesperrt | eingeladen | Admin | Nutzer hatte noch kein Passwort gesetzt |

## C. Daten (Feld | Typ | Pflicht | Beispiel | Quelle)

### Person
| Feld | Typ | Pflicht | Beispiel | Quelle |
|---|---|---|---|---|
| Vorname | Text | ja | Denise | Admin / Import (EA) |
| Nachname | Text | ja | Muster | Admin / Import (EA) |
| Art | Mensch / Funktionsperson | ja (Default Mensch) | Funktionsperson | Admin / System |
| angelegt am / von | Zeitstempel / Nutzer | ja | 19.10.2026, Toni Werner | System |

Alle weiteren Angaben (Kontaktadresse, Hauptamt, Funktion …) sind Eigenschaften. Funktionsperson „Geschäftsstelle“: Vorname „Geschäftsstelle“, Nachname „Notfall-Admin“.

### Zugang
| Feld | Typ | Pflicht | Beispiel | Quelle |
|---|---|---|---|---|
| Person | Verweis | ja | Denise Muster | Admin |
| Login-Adresse | E-Mail (@dav-leipzig.de) | ja | denise.muster@dav-leipzig.de | Admin |
| Status | kein Zugang / eingeladen / aktiv / gesperrt | ja | eingeladen | System |
| zuletzt eingeladen am | Zeitstempel | nein | 19.10.2026 14:00 | System |
| gesperrt am / von | Zeitstempel / Nutzer | nein | – | System |
| Supabase-Auth-ID | technisch | ja ab Einladung | – | Supabase Auth |

### Eigenschaftsart
| Feld | Typ | Pflicht | Beispiel | Quelle |
|---|---|---|---|---|
| Name | Text, eindeutig | ja | Hauptamt | Admin / Geschäftsstelle / System |
| Zweck | Text | ja | Zuordnung der Mitarbeitenden der Geschäftsstelle | Admin |
| Datentyp | Text / Datum / Ja/Nein / Auswahlliste | ja | Text | Admin |
| Auswahlwerte | Liste von Texten | ja bei Auswahlliste | C, B, A | Admin |
| sichtbar in | Liste von Modulen | ja | AD | Admin |
| vertraulich | Ja/Nein | ja (Default nein) | ja | Admin |
| Herkunft | System / angelegt | ja | angelegt | System |

### Eigenschaft
| Feld | Typ | Pflicht | Beispiel | Quelle |
|---|---|---|---|---|
| Person | Verweis | ja | Denise Muster | Admin |
| Eigenschaftsart | Verweis | ja | Hauptamt | Admin |
| Wert | je Datentyp | ja | Mitarbeiterin Geschäftsstelle | Admin |
| gültig von | Datum | ja | 01.03.2024 | Admin |
| gültig bis | Datum | nein | – | Admin |
| geändert am / von | Zeitstempel / Nutzer | ja | – | System |

### Rechtevorlage
| Feld | Typ | Pflicht | Beispiel | Quelle |
|---|---|---|---|---|
| Name | Text, eindeutig | ja | Geschäftsstelle | Admin |
| Beschreibung | Text | nein | Hauptamtliche Mitarbeitende | Admin |
| Stufe je Modul | kein Zugriff / lesen / bearbeiten / verwalten | ja | FI: verwalten | Admin |

### Zuweisung Rechtevorlage
| Feld | Typ | Pflicht | Beispiel | Quelle |
|---|---|---|---|---|
| Person | Verweis | ja | Denise Muster | Admin |
| Rechtevorlage | Verweis | ja | Geschäftsstelle | Admin |
| gültig von / bis | Datum | nein; nur Datenmodell, nicht in der Oberfläche (MVP) | – | System |
| zugewiesen am / von | Zeitstempel / Nutzer | ja | – | System |

### Protokoll
| Feld | Typ | Pflicht | Beispiel | Quelle |
|---|---|---|---|---|
| Zeitpunkt | Zeitstempel | ja | 19.10.2026 14:00 | System |
| ausgeführt von | Nutzer | ja | Toni Werner | System |
| betroffene Person | Verweis | ja | Denise Muster | System |
| Aktion | eingeladen / Login-Adresse geändert / Vorlage zugewiesen / Vorlage entzogen / gesperrt / entsperrt / Anmeldung Notfall-Admin | ja | Vorlage zugewiesen | System |
| Details | Text | nein | Geschäftsstelle | System |

## D. Regeln

- R1: Login-Adresse muss auf @dav-leipzig.de enden, sonst Fehlermeldung „Zugang nur mit Adresse @dav-leipzig.de möglich.“ Nur in TEST kann der Product Owner für die Abnahme zusätzliche Domains freigeben (eigene private Adressen).
- R2: Login-Adresse ist eindeutig über alle Zugänge, sonst Fehlermeldung „Diese Login-Adresse ist bereits vergeben.“
- R3: Beim manuellen Anlegen einer Person zeigt das System eine Dublettenwarnung, wenn die eingegebene Login-Adresse bereits als Login-Adresse vorkommt (Kontaktadressen prüft EA beim Import) oder der Nachname gleich und der Vorname ähnlich ist (z. B. Toni/Anton, Tippfehler). Option „trotzdem anlegen“. Die genaue Schwelle legt die Umsetzung fest; Abnahme in TEST mit Beispielen.
- R4: Vorname und Nachname sind Pflicht.
- R5: Rechte wirken nur mit Zugang im Status „aktiv“.
- R6: Die Rechte einer Person sind die Summe aller zugewiesenen Vorlagen; je Modul gilt die höchste Stufe. Es gibt keine Verbote.
- R7: Eine Eigenschaft (Amt, Funktion, Hauptamt …) bringt keine Rechte mit.
- R8: Vertrauliche Eigenschaften darf nur lesen, wer AD-Rechte hat; durchgesetzt per RLS.
- R9: Eine Eigenschaftsart ohne Zweck kann nicht gespeichert werden; eine Auswahlliste ohne Auswahlwerte ebenfalls nicht.
- R10: Gesperrte Zugänge können sich nicht anmelden; die laufende Sitzung endet spätestens nach Ablauf (bis zu 1 Stunde).
- R11: Einladungen gehen nur auf Knopfdruck des Admins raus, nie automatisch.
- R12: In AD wird nichts gelöscht; Ausscheiden = Sperren + Enddatum an Eigenschaften.
- R13: Vergabe/Entzug von Vorlagen, Einladungen, Sperren und Entsperren werden protokolliert. Protokolleinträge werden 5 Jahre aufbewahrt und danach automatisch gelöscht.
- R14: Schutz vor Aussperren über einen Notfall-Admin mit Login-Adresse geschaeftsstelle@dav-leipzig.de und Vorlage Admin.
- R15: Funktionspersonen erscheinen nicht in EA (keine Anzeige, keine Filter, kein Import-Abgleich, nicht in Auswertungen) und fallen nicht unter die 5-Jahres-Löschung.
- R16: Jede Anmeldung des Notfall-Admins wird protokolliert; der Admin sieht in AD einen Hinweis darauf.
- R17: Eine Einladung ist nur möglich, wenn der Person mindestens eine Rechtevorlage zugewiesen ist.
- R18: Login und „Passwort vergessen“ verraten nicht, ob eine Login-Adresse existiert oder gesperrt ist.
- R19: Passwörter haben mindestens 8 Zeichen; keine weiteren Zeichenregeln. Beide Eingaben müssen übereinstimmen.
- R20: Die Login-Adresse ist nur bis zur Aktivierung des Zugangs änderbar (Status „kein Zugang“ oder „eingeladen“). Eine Änderung bei „eingeladen“ nimmt die Einladung zurück: alter Link ungültig, Status „kein Zugang“, danach neu einladen.

## E. Schnittstellen

| Schnittstelle | Richtung | Zweck |
|---|---|---|
| Supabase Auth | AD ↔ Auth | Login, Einladung, Passwort zurücksetzen, Sperren |
| Edge Function „Nutzer einladen“ | Frontend → Function → Auth | Einladung mit Service-Schlüssel, nur serverseitig; prüft AD-Rechte des Aufrufers |
| Google-Konto (SMTP) | Auth → Gmail | Versand der Login-Mails |
| EA | AD → EA | Person, Eigenschaftsart, Eigenschaft (Grundstruktur); Funktionspersonen ausgeschlossen |
| alle Module | AD → Module | Rechte für RLS und Navigation |

## F. Datenschutz

- Verarbeitete Daten: Name, Login-Adresse, Zugangsstatus, Rechtevorlagen, Eigenschaften, Protokoll.
- Hauptamt = Beschäftigtendaten; Eigenschaftsart vertraulich (R8).
- Mails enthalten keine Personendaten außer Empfängeradresse und Link (Gmail ohne Auftragsverarbeitungsvertrag).
- Auftragsverarbeitungsvertrag mit Supabase und Cloudflare; Eintrag im Verarbeitungsverzeichnis (Product Owner).
- Admin sieht über EA verwalten Personendaten; Supabase-Dashboard zeigt technisch alles (nur Admin).
- Hinweistext Art. 9 DSGVO beim Anlegen von Eigenschaftsarten.
- Protokoll: Aufbewahrung 5 Jahre (R13).
- Notfall-Admin: Alle mit Zugriff auf das Postfach der Geschäftsstelle können über „Passwort vergessen“ Admin-Rechte erlangen und vertrauliche Daten lesen, auch Beschäftigtendaten der Kolleg:innen. Risiko akzeptiert (Product Owner, 19.10.2026); Gegenmaßnahme: Protokoll und Hinweis an den Admin (R16).
- Löschung des Zugangs (Supabase-Auth-Eintrag), wenn die Person nach der 5-Jahres-Regel gelöscht wird: wird in EA geklärt (offene-punkte.md).

## G. Nicht-funktional

- Bedienbar ohne Schulung, Oberfläche deutsch, mobil ab 375 px.
- RLS auf jeder Tabelle; Rechteprüfung nie nur im Frontend.
- Supabase begrenzt Auth-Mails mit eigenem SMTP auf 30 pro Stunde; ausreichend.
- Sitzungsdauer: Supabase-Standard (Zugriffstoken bis zu 1 Stunde).
- Passwort: mindestens 8 Zeichen, keine Zeichenregeln (R19).
- Kosten: 0 €.

## Offene Fragen

| Frage | Wer klärt | bis wann |
|---|---|---|
| Vertretung des Admin-Zugangs (wer, ab wann) | Toni Werner | kein Blocker |
| Löschung des Zugangs bei Löschung der Person (5-Jahres-Regel) | EA | Steckbrief EA |
| Weg der Migrationen nach PROD (manuell oder GitHub Action) | Toni Werner | vor dem ersten PROD-Deployment |
