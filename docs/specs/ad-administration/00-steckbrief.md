# Steckbrief: Administration (AD)

Stand: 19.10.2026 · Version 0.9 · Status: abgestimmt · Product Owner: Toni Werner

**Problem heute:** Es gibt kein System, in dem Zugänge und Rechte für das Vereins OS vergeben werden. Ohne AD kann kein Fachmodul sicher genutzt werden, denn die Daten von ca. 250 Aktiven – inklusive Abrechnungs- und Bankdaten – dürfen nur berechtigte Nutzer sehen. Beispiel: Denise, Mitarbeiterin der Geschäftsstelle, braucht einen Zugang mit der Rechtevorlage Geschäftsstelle; der 1. Vorsitzende soll weniger sehen. Personen mit Zugang sollen nicht doppelt gepflegt werden (einmal als Nutzer, einmal als Person in EA).

**Ziel / Erfolgsmessung:**
- Alle 4 Nutzer (3 Mitarbeitende der Geschäftsstelle, 1. Vorsitzender) melden sich in PROD an.
- Der Admin legt Personen mit Zugang an (inkl. Dublettenwarnung), weist Rechtevorlagen zu, ändert Rechtevorlagen und sperrt Zugänge – ohne Code-Änderung.
- Je Rechtevorlage gibt es einen funktionierenden Testzugang in TEST.

**Nutzer & Rechtevorlagen:**
- Admin (Toni Werner) – legt Personen an, lädt Nutzer ein, vergibt und entzieht Rechtevorlagen, pflegt Rechtevorlagen, sperrt Zugänge, legt Eigenschaftsarten an und pflegt Eigenschaften von Personen. Vertretung später durch ein:e Mitarbeiter:in der Geschäftsstelle.
- Notfall-Admin – zweiter Zugang mit Vorlage Admin, Login geschaeftsstelle@dav-leipzig.de, an der Funktionsperson „Geschäftsstelle“; nur zum Schutz vor Aussperren.
- Geschäftsstelle (3) – nutzt Login und Startseite; kein Zugriff auf AD.
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
- Startseite als Platzhalter (Willkommensgrafik); sichtbar sind nur die Module, für die der Nutzer Rechte hat.
- Person anlegen (Pflichtfelder: Vorname, Nachname); Login-Adresse ist Pflicht, sobald ein Zugang eingerichtet wird.
- Dublettenprüfung beim manuellen Anlegen per Ähnlichkeit (gleiche E-Mail-Adresse oder gleicher Nachname mit ähnlichem Vorname): Warnung mit Option „trotzdem anlegen“.
- Grundstruktur des Personenmodells: Person (inkl. Art: Mensch / Funktionsperson), Eigenschaftsart, Eigenschaft (Wert, gültig von/bis, Historie). Eigenschaftsart mit Zweck, Datentyp (Text, Datum, Ja/Nein, Auswahlliste), Angabe „sichtbar in“ (Module) und Kennzeichen „vertraulich“. EA baut darauf Oberflächen, Filter und Import.
- Eigenschaftsarten aus AD heraus anlegen und ändern, z. B. Hauptamt. Beim Anlegen Pflichtangabe „Zweck“ und Hinweis, dass keine besonderen Kategorien nach Art. 9 DSGVO erfasst werden.
- Eigenschaften einer Person aus AD heraus pflegen.
- „Sichtbar in“ steuert nur die Anzeige. „Vertraulich“ steuert den Lesezugriff: Vertrauliche Eigenschaften darf nur lesen, wer Rechte auf AD hat (im MVP: Admin); durchgesetzt per RLS. Beispiel: Hauptamt ist vertraulich und nur in AD sichtbar.
- Rechtevorlagen anlegen und ändern: Rechte nur je Modul (lesen / bearbeiten / verwalten / kein Zugriff); Reichweite im MVP immer „alle“.
- Startwerte: Admin = AD verwalten, SC verwalten, EA verwalten; Geschäftsstelle = alle Fachmodule verwalten; Vorstand = Vorlage wird ohne Rechte angelegt, der Admin konfiguriert sie später in der Oberfläche.
- Einer Person eine oder mehrere Rechtevorlagen zuweisen und entziehen.
- Zugang sperren und wieder entsperren. Wirksam spätestens mit Ablauf der laufenden Sitzung (Supabase-Standard, bis zu 1 Stunde). Beim Ausscheiden wird der Zugang gesperrt und die Eigenschaften erhalten ein Enddatum; gelöscht wird nach der 5-Jahres-Regel (EA).
- Notfall-Admin über geschaeftsstelle@dav-leipzig.de als Schutz vor Aussperren; jede Anmeldung wird protokolliert, der Admin sieht in AD einen Hinweis darauf. Die Funktionsperson erscheint nicht in EA.
- Vergabe und Entzug von Rechtevorlagen, Einladungen, Sperren/Entsperren sowie Anmeldungen des Notfall-Admins protokollieren (wer, wem, was, wann); Aufbewahrung 5 Jahre; Protokoll in AD einsehbar.
- Testzugänge je Rechtevorlage per `supabase/seed.sql` in TEST.

**Nicht im Scope:**
- E-Mails aus Fachabläufen (z. B. Erinnerungen, Benachrichtigung über Anmeldung des Notfall-Admins); kommen mit SC.
- Automatische Einladung beim Anlegen oder Import.
- Sofortiges Beenden laufender Sitzungen beim Sperren.
- Befristung der Zuweisung einer Rechtevorlage in der Oberfläche (Datenmodell vorbereitet).
- Rechte je Objekt innerhalb eines Moduls (Ausnahme: Kennzeichen „vertraulich“ an der Eigenschaftsart).
- Einzelrechte sowie Reichweiten Bereich / Gruppe / nur eigene (Datenmodell wird dafür ausgelegt, Pflege nach MVP).
- Testzugang mit Einzelrechten (entfällt, solange es keine Einzelrechte gibt).
- Startkonfiguration der Rechtevorlage Vorstand.
- Löschfunktion in der Oberfläche von AD (Zugänge, Personen, Eigenschaftsarten).
- API-Key-Verwaltung und Erinnerung vor Ablauf eines API-Keys (Erweiterung von AD zusammen mit SC).
- Einstellungen verwalten.
- Personenakte / Hinweise an Personen (Merkposten nach MVP).
- Excel-Import inkl. Prüfliste für Dublettenverdacht und Zusammenführen von Personen (→ EA).
- Filter aktive / ausgeschiedene Personen (→ EA).
- Automatische Löschung nach 5 Jahren (→ EA).
- Login für Aktive (nach MVP).
- SSO (später; Login-Regel @dav-leipzig.de bereitet es vor).
- Automatische Ableitung von Rechten aus Amt oder Funktion.

**Abhängigkeiten:**
- AD → alle Module: Nutzer, Rechtevorlagen, Rechte (liefert).
- AD → EA: AD baut die Grundstruktur des Personenmodells (Person, Eigenschaftsart, Eigenschaft); EA erweitert sie um Oberflächen, Filter, Import und Löschlauf und blendet Funktionspersonen aus. Personen aus dem Import (EA) werden in AD einzeln eingeladen.
- AD ← SC: API-Key-Verwaltung erst mit SC. Login-Mails laufen nicht über SC, sondern direkt über Supabase Auth.
- Extern: Supabase Auth mit Google-Konto der Sektion als SMTP. Einladen von Nutzern nur serverseitig (Edge Function), nicht aus dem Frontend.
- Extern (später): SSO über den Microsoft-Tenant setzt Zustimmung und Mitwirkung des Bundesverbands voraus (Tenant wird dort verwaltet).

**Risiken / Besonderheiten:**
- Zustellung der Login-Mails aus Gmail an Adressen im Microsoft-Tenant vor Go-live testen (Spam-Filter). Fallen sie aus, kann sich niemand neu anmelden oder sein Passwort zurücksetzen.
- Datenschutz: Für das Gmail-Konto gibt es keinen Auftragsverarbeitungsvertrag; deshalb keine Personendaten in Mails außer Empfängeradresse und Link.
- Notfall-Admin: Alle mit Zugriff auf das Postfach der Geschäftsstelle können über „Passwort vergessen“ Admin-Rechte erlangen und vertrauliche Eigenschaften lesen. Risiko akzeptiert (19.10.2026); Gegenmaßnahme: Protokoll und Hinweis an den Admin.
- Gesperrte Nutzer behalten bis zu 1 Stunde Zugriff (bewusst in Kauf genommen).
- Rechte nur je Modul: Die Vorlage Admin hat EA verwalten und darf damit in EA auch Personen löschen und exportieren, sobald EA diese Funktionen bietet. Bewusst in Kauf genommen.
- Datenschutz: Hauptamt und ähnliche Eigenschaften sind Beschäftigtendaten; Schutz über Kennzeichen „vertraulich“ (RLS), nicht nur über „sichtbar in“.
- Datenschutz: Die Rechtevorlage Admin erhält Zugriff auf EA-Daten; damit sieht eine weitere Rolle Personendaten. Das Supabase-Dashboard zeigt technisch alle Daten.
- Datenschutz: Frei angelegte Eigenschaftsarten laden zum Erfassen sensibler Daten ein; Gegenmaßnahme: Pflichtangabe Zweck, Hinweistext.
- Kein Backup von PROD: Verlust von Personen, Zugängen und Rechten ist nicht wiederherstellbar (Risiko akzeptiert).
- Reihenfolge: Das Personenmodell entsteht in AD vor EA; das Datenmodell muss die Erweiterung in EA ohne Umbau erlauben.

**Offene Fragen:**
- [OFFEN] Vertretung des Admin-Zugangs: welche:r Mitarbeiter:in der Geschäftsstelle, ab wann? Kein Blocker.
