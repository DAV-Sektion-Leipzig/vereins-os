# Steckbrief: Administration (AD)

Stand: 21.10.2026 · Version 1.1 · Status: abgestimmt (Nachtrag freigegeben am 21.10.2026) · Product Owner: Toni Werner
Änderungen v1.1 (21.10.2026): Nachtrag Personenmodell aus Ehrenamtsmanagement und Gruppen (spec.md v0.7): Rechtevorlage Referent:in mit Reichweite „Referat“, Referate und Gremien, Lesestufen, Eigenschaftsart mit mehreren Feldern, Rufname, Ehrenamtsstatus, gemeinsame Personen-Tabelle mit Sichtbarkeit je Modul, Admin „Gruppen lesen“, Dublettenwarnung modulübergreifend.
Änderungen v1.0 (21.10.2026): Stammdaten Qualifikationsarten (Pflege durch Admin und Geschäftsstelle, Startbestand, Datentyp „Qualifikationsart“) in den Scope.

**Problem heute:** Es gibt kein System, in dem Zugänge und Rechte für das Vereins OS vergeben werden. Ohne AD kann kein Fachmodul sicher genutzt werden, denn die Daten von ca. 250 Aktiven und 150–200 Kindern und Jugendlichen in Gruppen – inklusive Abrechnungs- und Bankdaten – dürfen nur berechtigte Nutzer sehen. Beispiel: Denise, Mitarbeiterin der Geschäftsstelle, braucht einen Zugang mit der Rechtevorlage Geschäftsstelle; der 1. Vorsitzende soll weniger sehen; die Referentin Kinder und Jugend soll nur die Aktiven ihres Referats sehen. Personen sollen nicht doppelt gepflegt werden (als Nutzer, als Aktive:r, als Erziehungsberechtigte:r). Die Liste der Qualifikationsarten des Bundesverbands existiert nur als Datei; ohne zentrale Pflege würden Lizenzen an Personen als Freitext erfasst und Ablauf, Filter und Stichtagsliste in EA funktionierten nicht zuverlässig.

**Ziel / Erfolgsmessung:**
- Alle 4 Nutzer (3 Mitarbeitende der Geschäftsstelle, 1. Vorsitzender) melden sich in PROD an; danach schrittweise die Referent:innen und Hüttenwart:innen.
- Der Admin legt Personen mit Zugang an (inkl. Dublettenwarnung), weist Rechtevorlagen zu (bei Referent:innen mit Referaten), ändert Rechtevorlagen und sperrt Zugänge – ohne Code-Änderung.
- Je Rechtevorlage gibt es einen funktionierenden Testzugang in TEST.
- Die 47 Qualifikationsarten liegen in TEST und PROD vor; Admin und Geschäftsstelle ergänzen und ändern sie ohne Code-Änderung.
- Jede Person ist nur in den Modulen lesbar, zu denen sie gehört; nachgewiesen mit der Sichtbarkeitsmatrix in TEST.

**Nutzer & Rechtevorlagen:**
- Admin (Toni Werner) – legt Personen an, lädt Nutzer ein, vergibt und entzieht Rechtevorlagen (inkl. Referate), pflegt Rechtevorlagen, sperrt Zugänge, legt Eigenschaftsarten an, pflegt Eigenschaften von Personen und Qualifikationsarten; liest Gruppen (Risikomanagement). Vertretung später durch ein:e Mitarbeiter:in der Geschäftsstelle.
- Notfall-Admin – zweiter Zugang mit Vorlage Admin, Login geschaeftsstelle@dav-leipzig.de, an der Funktionsperson „Geschäftsstelle“; nur zum Schutz vor Aussperren.
- Geschäftsstelle (3) – nutzt Login und Startseite; kein Zugriff auf AD; pflegt Qualifikationsarten über „EA verwalten“ (Seiten im Ehrenamtsmanagement, sobald EA verfügbar ist).
- Referent:in (neu v1.1; auch Hüttenwart:innen) – nutzt Login und Startseite; kein Zugriff auf AD; im Ehrenamtsmanagement „bearbeiten“ mit Reichweite „Referat“.
- Vorstand (1. Vorsitzender) – nutzt Login und Startseite; kein Zugriff auf AD.
- Testnutzer – je ein Zugang pro Rechtevorlage, nur in TEST mit fiktiven Daten.

**Im Scope (MVP):**
- Login mit E-Mail-Adresse und Passwort über Supabase Auth; keine Selbstregistrierung.
- Einladungsverwaltung in AD: Übersicht der Personen mit Zugangsstatus; Einladung nur auf Knopfdruck je Person, nie automatisch beim Anlegen oder Import; Einladung erneut senden.
- Einladung per E-Mail aus Supabase Auth: Der Nutzer setzt sein Passwort selbst über den Link. Der Admin kennt das Passwort nie.
- Passwort vergessen: Der Nutzer setzt sein Passwort selbst über einen Link per E-Mail zurück (Supabase Auth).
- Passwortregeln: mindestens 8 Zeichen, keine Zeichenregeln (SSO löst später ab).
- Versand der Login-Mails über das Google-Konto der Sektion als SMTP in Supabase Auth (siehe tech-stack.md). Mails enthalten nur Empfängeradresse, kurzen Hinweistext und Link.
- Zugang nur mit Adresse @dav-leipzig.de; das System lehnt andere Adressen mit Fehlermeldung ab. Grund: spätere Umstellung auf SSO.
- Login-Adresse gehört zum Zugang, Kontaktadresse ist eine Eigenschaft der Person (getrennt gehalten).
- Startseite als Platzhalter (Willkommensgrafik); sichtbar sind nur die Module, für die der Nutzer Rechte hat (beide Reichweiten).
- Person anlegen (Pflichtfelder: Vorname, Nachname; optional Rufname); Login-Adresse ist Pflicht, sobald ein Zugang eingerichtet wird.
- Dublettenprüfung beim Anlegen per Ähnlichkeit (gleiche E-Mail-Adresse oder gleicher Nachname mit ähnlichem Vor- bzw. Rufnamen) über alle Personen aller Module; Treffer zeigen nur Vorname, Nachname, Rufname, Geburtsjahr und „ausgeschieden seit“; Option „trotzdem anlegen“.
- Grundstruktur des Personenmodells: **eine gemeinsame Personen-Tabelle** für alle Module (Person mit Art Mensch / Funktionsperson, Rufname, Ehrenamtsstatus), Eigenschaftsart, Feld, Eigenschaft (Werte der Felder, Bezug, gültig von/bis, Historie). EA und GR bauen darauf Oberflächen, Filter, Import und gruppenspezifische Tabellen.
- Eigenschaftsarten aus AD heraus anlegen und ändern, z. B. Hauptamt: Zweck (Pflicht), Kategorie, Lesestufe, Bezug (Referat, Gremium; Gruppe mit GR), „sichtbar in“, „nur ein gültiger Eintrag“ und ein oder mehrere Felder (Text, Zahl, Datum, Jahr, Ja/Nein, Auswahlliste, Qualifikationsart). Hinweis, dass keine besonderen Kategorien nach Art. 9 DSGVO erfasst werden.
- Eigenschaften einer Person aus AD heraus pflegen.
- **Lesestufen** je Eigenschaftsart (ersetzt das Kennzeichen „vertraulich“): „alle mit Zugriff“, „nur Geschäftsstelle und Admin“, „vertraulich“ (nur mit Rechten auf AD); durchgesetzt per RLS. „Sichtbar in“ steuert nur die Anzeige. Beispiel: Hauptamt ist vertraulich; Führungszeugnis-Einsicht „nur Geschäftsstelle und Admin“.
- **Sichtbarkeit je Modul** per RLS: AD (Admin) zeigt immer alle Personen aller Module, damit Vollständigkeit herstellbar ist (Entscheidung 21.10.2026); Personenübersicht mit Filter „Zugehörigkeit“ und Paginierung; EA zeigt Personen mit Ehrenamtsstatus (Ausgeschiedene nur Geschäftsstelle und Admin; Referent:innen nur ihre Referate); GR zeigt Personen mit Gruppenbezug. Personen nur aus Gruppen sind in EA nicht sichtbar.
- **Ehrenamtsstatus** (aktiv, ruhend, ausgeschieden): Datenmodell mit Historie und Datenbankfunktionen zum Setzen, Anlegen mit erster Zuordnung und Wiederaktivieren; Oberflächen in EA. In AD nur Anzeige.
- **Referate** (7) und **Gremien** (4) als Stammdaten per Migration.
- Rechtevorlagen anlegen und ändern: Rechte je Modul (lesen / bearbeiten / verwalten / kein Zugriff); Reichweite „alle“ oder – nur für EA – „Referat“.
- Startwerte: Admin = AD, SC, EA verwalten, Gruppen lesen; Geschäftsstelle = alle Fachmodule verwalten; Referent:in = EA bearbeiten mit Reichweite Referat; Vorstand = Vorlage ohne Rechte, der Admin konfiguriert sie später in der Oberfläche.
- Einer Person eine oder mehrere Rechtevorlagen zuweisen und entziehen; bei Reichweite „Referat“ mindestens ein Referat wählen und später ändern (protokolliert).
- Zugang sperren und wieder entsperren. Wirksam spätestens mit Ablauf der laufenden Sitzung (Supabase-Standard, bis zu 1 Stunde). Beim Ausscheiden wird der Zugang gesperrt und der Ehrenamtsstatus „ausgeschieden“ gesetzt (EA); gelöscht wird nach der 5-Jahres-Regel (nach MVP).
- Notfall-Admin über geschaeftsstelle@dav-leipzig.de als Schutz vor Aussperren; jede Anmeldung wird protokolliert, der Admin sieht in AD einen Hinweis darauf. Die Funktionsperson erscheint nicht in EA und GR.
- Vergabe und Entzug von Rechtevorlagen, Änderung der Referate, Einladungen, Sperren/Entsperren sowie Anmeldungen des Notfall-Admins protokollieren (wer, wem, was, wann); Aufbewahrung 5 Jahre; Protokoll in AD einsehbar.
- Testzugänge je Rechtevorlage (inkl. Referent:in) per `supabase/seed.sql` in TEST.
- **Qualifikationsarten** (Stammdaten für Lizenzen, Zusatzqualifikationen, Lehrgänge, Weiterbildungen):
  - Liste mit Suche und Filtern (Sparte, Typ, Status); anlegen, ändern, auf „historisch“ setzen; kein Löschen.
  - Felder: Kürzel, Bezeichnung, Sparte (Klassifizierung des Bundesverbands, ohne Bezug zu Referaten), Typ, Lizenzstufe, Spezifikation, Aussteller, DOSB-lizenzfähig, Gültigkeitsdauer in Jahren, Status, Hinweis, Quell-ID.
  - Pflege durch Admin (in AD) und Geschäftsstelle (über „EA verwalten“); lesen alle Nutzer mit aktivem Zugang.
  - Startbestand 47 Einträge per Migration in TEST und PROD (specs/ea-ehrenamt/stammdaten-qualifikationsarten.md).
  - Datentyp „Qualifikationsart“ je Feld: Eigenschaften verweisen auf eine Qualifikationsart; historische sind nicht neu vergebbar.

**Nicht im Scope:**
- E-Mails aus Fachabläufen (z. B. Erinnerungen, Benachrichtigung über Anmeldung des Notfall-Admins); kommen mit SC.
- Automatische Einladung beim Anlegen oder Import.
- Sofortiges Beenden laufender Sitzungen beim Sperren.
- Befristung der Zuweisung einer Rechtevorlage in der Oberfläche (Datenmodell vorbereitet).
- Rechte je Objekt innerhalb eines Moduls (Ausnahmen: Lesestufe an der Eigenschaftsart; Pflegerecht für Qualifikationsarten über „EA verwalten“).
- Einzelrechte sowie Reichweiten „Gruppe“ und „nur eigene“; Reichweite „Referat“ für andere Module als EA (Datenmodell ausgelegt, nach MVP).
- Testzugang mit Einzelrechten (entfällt, solange es keine Einzelrechte gibt).
- Startkonfiguration der Rechtevorlage Vorstand.
- Löschfunktion in der Oberfläche von AD (Zugänge, Personen, Eigenschaftsarten, Felder, Qualifikationsarten, Referate, Gremien).
- API-Key-Verwaltung und Erinnerung vor Ablauf eines API-Keys (Erweiterung von AD zusammen mit SC).
- Einstellungen verwalten.
- Personenakte / Hinweise an Personen (Merkposten nach MVP).
- Excel-Import inkl. Prüfliste für Dublettenverdacht und Zusammenführen von Personen (→ EA bzw. Migrationsskripte).
- Oberflächen für Ehrenamtsstatus, Sicht je Referat, Gremium-Sichten, Pflege von Referaten und Gremien (→ EA).
- Gruppen, Teilnahme, Erziehungsberechtigte, Notfallkontakte, Verträge, Gesundheitsangaben (→ GR).
- Automatische Löschung nach 5 Jahren (→ nach MVP, alle Module).
- Ablaufdaten, Ablaufstatus, Stichtagsliste und Fortbildungen an Personen (→ EA).
- Abgleich der Qualifikationsarten mit dem Bundesverband.
- Login für Aktive und Gruppenleitungen (nach MVP).
- SSO (später; Login-Regel @dav-leipzig.de bereitet es vor).
- Automatische Ableitung von Rechten aus Amt oder Funktion.

**Abhängigkeiten:**
- AD → alle Module: Nutzer, Rechtevorlagen, Rechte, Reichweiten (liefert).
- AD → EA: AD baut das Personenmodell inkl. Ehrenamtsstatus, Referate, Gremien und die Sichtbarkeit im Pfad EA; EA baut Oberflächen, Filter, Migration der Aktivenliste und die System-Eigenschaftsarten. Personen aus der Migration werden in AD einzeln eingeladen.
- AD ↔ GR: gemeinsame Personen-Tabelle; AD legt den Platzhalter für die Sichtbarkeit im Pfad GR an, GR ersetzt ihn und ergänzt den Bezug auf Gruppen (Übergabe aus GR, 21.10.2026).
- AD → EA, GR, EZ: Qualifikationsarten (liefert); EA hängt die Pflegeseiten für die Geschäftsstelle in seine Navigation ein. Die Migration der Aktivenliste setzt den Startbestand voraus.
- AD ← SC: API-Key-Verwaltung erst mit SC. Login-Mails laufen nicht über SC, sondern direkt über Supabase Auth.
- Extern: Supabase Auth mit Google-Konto der Sektion als SMTP. Einladen von Nutzern nur serverseitig (Edge Function), nicht aus dem Frontend.
- Extern: Ausbildungsstruktur und Fortbildungsregelung des Bundesverbands (Quelle der Qualifikationsarten; ändert sich jährlich).
- Extern (später): SSO über den Microsoft-Tenant setzt Zustimmung und Mitwirkung des Bundesverbands voraus (Tenant wird dort verwaltet).

**Risiken / Besonderheiten:**
- Zustellung der Login-Mails aus Gmail an Adressen im Microsoft-Tenant vor Go-live testen (Spam-Filter). Fallen sie aus, kann sich niemand neu anmelden oder sein Passwort zurücksetzen.
- Datenschutz: Für das Gmail-Konto gibt es keinen Auftragsverarbeitungsvertrag; deshalb keine Personendaten in Mails außer Empfängeradresse und Link.
- Notfall-Admin: Alle mit Zugriff auf das Postfach der Geschäftsstelle können über „Passwort vergessen“ Admin-Rechte erlangen und vertrauliche Eigenschaften lesen. Risiko akzeptiert (19.10.2026); Gegenmaßnahme: Protokoll und Hinweis an den Admin.
- Gesperrte Nutzer behalten bis zu 1 Stunde Zugriff (bewusst in Kauf genommen).
- Rechte nur je Modul: Die Vorlage Admin hat EA verwalten und darf damit in EA auch Personen löschen und exportieren, sobald EA diese Funktionen bietet. Bewusst in Kauf genommen.
- Komplexität: Sichtbarkeit je Pfad, Reichweite „Referat“ und Lesestufen machen die RLS-Regeln deutlich komplexer und langsamer; Gegenmaßnahme: Sichtbarkeitsmatrix als Datenbanktest, Mengentest mit 1.000 Personen.
- Umsetzungsstand: `ea_persons` ist in TEST bereits angelegt; Änderungen nur per neuer Migration. Die Umsetzung ist pausiert, bis der Nachtrag freigegeben ist.
- Datenschutz: Hauptamt und ähnliche Eigenschaften sind Beschäftigtendaten; Schutz über Lesestufe „vertraulich“ (RLS), nicht nur über „sichtbar in“.
- Datenschutz: Die Rechtevorlage Admin sieht alle Personen aller Module mit allen Eigenschaften, auch Kontaktdaten und Geburtsdatum von Kindern (keine Gesundheitsangaben, diese liegen im Modul Gruppen); dasselbe gilt für den Notfall-Admin über das Postfach der Geschäftsstelle. Das Supabase-Dashboard zeigt technisch alle Daten.
- Datenschutz: Mit der Vorlage Referent:in sehen ca. 8–10 ehrenamtliche Nutzer Personendaten ihres Referats. Über „Ins Ehrenamtsmanagement übernehmen“ können sie eine Person aus Gruppen übernehmen und sehen danach deren gemeinsame Kontaktdaten (bestätigt 21.10.2026).
- Datenschutz: Die Dublettenwarnung zeigt Namen und Geburtsjahr auch von Personen aus anderen Modulen (z. B. Kindern); notwendig, damit ein Mensch nur einmal existiert.
- Datenschutz: Frei angelegte Eigenschaftsarten laden zum Erfassen sensibler Daten ein; Gegenmaßnahme: Pflichtangabe Zweck, Lesestufe, Hinweistext.
- Qualifikationsarten enthalten keine Personendaten; „Verwendet bei n Personen“ zeigt nur eine Zahl. Bis EA verfügbar ist, pflegt nur der Admin.
- Änderungen der Gültigkeitsdauer wirken nicht rückwirkend; Stammdaten und Altbestand können auseinanderlaufen.
- Kein Backup von PROD: Verlust von Personen, Zugängen und Rechten ist nicht wiederherstellbar (Risiko akzeptiert); ein Prompt für ein lokales Backup liegt vor (claude/prompts/prod-backup.md).
- Reihenfolge: Das Personenmodell entsteht in AD vor EA und GR; das Datenmodell muss die Erweiterungen ohne Umbau erlauben.

**Offene Fragen:**
- [OFFEN] Vertretung des Admin-Zugangs: welche:r Mitarbeiter:in der Geschäftsstelle, ab wann? Kein Blocker.
- Erledigt 21.10.2026: Nachtrag freigegeben; Admin sieht alle Personen; Übernahme von Personen aus Gruppen durch Referent:innen erlaubt; Lesestufe „nur Geschäftsstelle und Admin“ = „verwalten“ im jeweiligen Modul.
