# Steckbrief: Ehrenamtsmanagement (EA)

Stand: 22.10.2026 · Version 0.7 · Status: Entwurf · Product Owner: Toni Werner
Änderungen v0.7: Erhebung v0.1 erstellt; dort entschieden: Lizenzfelder (Qualifikationsart, gültig bis, Lizenznummer, DOSB-Lizenz gültig bis, letzte Fortbildung; „Stufe laut Vereinsportal“ und „Jahr Kursverlängerung“ entfallen), Migration über bereinigte CSV, Status ein Eintrag ab Stichtag; offene Frage DOSB-Lizenz erledigt. Wo der Steckbrief abweicht, gilt die Erhebung.
Änderungen v0.6: Qualifikationsarten sind Stammdaten der Administration (spec.md AD v0.6, US-AD-17 bis US-AD-19); Liste geliefert (47, stammdaten-qualifikationsarten.md); Pflege durch Admin und Geschäftsstelle; Gültigkeitsdauern nach Fortbildungsregelung des Bundesverbands; Ablauf zum Jahresende [ANNAHME].
Änderungen v0.5: „ruhend“ bestätigt; Referent:innen setzen alle drei Status mit Wirkung für die ganze Person; Rückkehr Ausgeschiedener über „wieder aktivieren“; Karteileichen (eigenes Tabellenblatt) nicht Teil der Migration.
Änderungen v0.4: Ehrenamtsstatus (aktiv, ruhend, ausgeschieden) als eigener Status; Ausgeschiedene nicht in der Übersicht; Zweck von Geburtsdatum und Geschlecht; je Lizenz eine eigene Lizenznummer.
Änderungen v0.3: Aktivenliste ausgewertet (68 Spalten, siehe migration-aktivenliste.md); Eigenschaftsart mit mehreren Feldern, Kategorien, Jahreseinträge, Ausgaben, externe Zugänge, Trainer- und Jugendleiterausweis in den Scope; Abgleich mit Steckbrief Gruppen v0.2.

**Problem heute:** Die Aktiven werden in einer Excel-Liste im SharePoint geführt (knapp 130 Datensätze, nur Trainer:innen, 68 Spalten), die mehrere Personen gleichzeitig bearbeiten; die Formatierung geht dabei regelmäßig kaputt. Die Liste ist schwer filterbar, hat keine Sichten je Referat und bildet Mehrfacheinträge über feste Spalten ab (Lizenz 1–3, eine Spalte je Fortbildungsjahr, je Markenjahr, je Förderjahr). Ehemalige werden als „Karteileichen“ auf einem eigenen Tabellenblatt mitgeführt. Neue Eigenschaften lassen sich nur umständlich ergänzen, Automatismen (z. B. Hinweis vor Ablauf einer Lizenz) gibt es nicht. Weitere ca. 120 Aktive (Personen mit Amt, Freiwillige in der Geschäftsstelle, bei Arbeitseinsätzen, Europacup usw.) stehen in anderen Listen oder gar nicht. Beispiel: Ob die Lizenz einer Trainerin im Referat Kinder und Jugend bald abläuft, muss die Referentin selbst in der Excel-Liste suchen.

**Ziel / Erfolgsmessung:**
- Alle aktiven und ruhenden Trainer:innen aus der Excel-Liste (ca. 130) sind per Skript migriert; die Excel-Liste ist eingefroren, archiviert und nicht mehr in Gebrauch.
- Nutzer finden Aktive über eine filterbare Tabelle (Ehrenamtsstatus, Referat, Funktion, Amt, Gremium, Qualifikation, Ablaufstatus) und sehen alle für sie lesbaren Eigenschaften einer Person auf einen Blick, gruppiert nach Kategorie.
- Geschäftsstelle und Admin legen neue Eigenschaftsarten mit eigenen Feldern ohne Code-Änderung an.
- Referent:innen pflegen Personen, Ehrenamtsstatus, Qualifikationen und Ablaufdaten ihres Referats selbst im System.
- Abgelaufene und bald ablaufende Qualifikationen (≤ 3 Monate) sind markiert; die Stichtagsliste zum 1. Oktober (Ablauf im Folgejahr) ist jederzeit abrufbar.
- Jede Lizenz der migrierten Aktiven verweist auf eine Qualifikationsart (kein Freitext).
- Die Referate haben das Ehrenamtsmanagement fachlich abgenommen.
- Nach Abnahme von Administration und Ehrenamtsmanagement wird der Regelbetrieb geprüft; die übrigen Module folgen iterativ.
- Ein Zieltermin ist nicht Teil dieses Steckbriefs (Entscheidung Product Owner, 21.10.2026).
- Nach dem MVP: Migration der übrigen ca. 120 Aktiven aus weiteren Listen.

**Nutzer & Rechtevorlagen:**
- Admin (Toni Werner) – Ehrenamtsmanagement verwalten, Reichweite „alle“; liest alle Lesestufen inklusive „vertraulich“; pflegt Stammdaten (Referate, Gremien; Qualifikationsarten in der Administration) und Eigenschaftsarten; führt die Migration aus.
- Geschäftsstelle (3 Mitarbeitende) – Ehrenamtsmanagement verwalten, Reichweite „alle“; liest „alle mit Zugriff“ und „nur Geschäftsstelle und Admin“; legt Eigenschaftsarten (mit Feldern) an; pflegt Qualifikationsarten über die Seiten „Qualifikationsarten“ im Ehrenamtsmanagement (Recht „EA verwalten“, ohne Rechte auf die Administration); pflegt Gremium-Zugehörigkeiten; sieht als Einzige neben dem Admin Personen ohne Referat, ausgeschiedene Personen und die Gremium-Sichten.
- Referent:in (neue Rechtevorlage; gilt auch für Hüttenwart:innen) – Ehrenamtsmanagement bearbeiten, Reichweite „Referat“ (ein oder mehrere Referate, vom Admin zugewiesen); liest Lesestufe „alle mit Zugriff“; legt im eigenen Referat Personen an, pflegt Eigenschaften (insbesondere Qualifikationen und Ablaufdaten) und setzt den Ehrenamtsstatus (aktiv, ruhend, ausgeschieden) für Personen ihres Referats, mit Wirkung für die ganze Person (Product Owner 21.10.2026). Keine Gremium-Sichten, keine Liste ausgeschiedener Personen, keine Eigenschaftsarten und keine Qualifikationsarten anlegen.
- Vorstand – Rechtevorlage ohne Rechte (Startwert unverändert, Konfiguration durch Admin nach MVP).
- Testnutzer – je ein Testzugang pro Rechtevorlage in TEST, neu auch Referent:in (mit mindestens einem Referat).

**Im Scope (MVP):**
- **Ehrenamtsstatus** je Person: aktiv · ruhend · ausgeschieden, manuell gesetzt, mit Datum und Historie (wer, wann). Er gilt für die ganze Person, nicht je Referat. Eine Person erscheint im Ehrenamtsmanagement, sobald sie einen Ehrenamtsstatus hat; Personen ohne Status (z. B. nur Teilnehmer:innen im Modul Gruppen) nicht.
  - Setzen dürfen Geschäftsstelle, Admin und Referent:innen für Personen ihres Referats.
  - Übersicht zeigt standardmäßig „aktiv“ und „ruhend“; „ausgeschieden“ ist ausgeblendet. [ANNAHME] Geschäftsstelle und Admin finden Ausgeschiedene über einen Filter.
  - [ANNAHME] Ist die Person noch in anderen Referaten zugeordnet, nennt das System diese Referate vor dem Setzen auf „ruhend“ oder „ausgeschieden“ und verlangt eine Bestätigung.
  - [ANNAHME] Beim Setzen auf „ausgeschieden“ schlägt das System vor, laufende Ämter und Funktionen zum selben Datum zu beenden, und zeigt nicht zurückgegebene Ausgaben und bestehende externe Zugänge.
  - **Rückkehr:** Ruhende und ausgeschiedene Personen können wieder auf „aktiv“ gesetzt werden; keine neue Person, die Historie bleibt (Product Owner 21.10.2026). [ANNAHME] Referent:innen stoßen beim Anlegen über die Dublettenwarnung auf die ausgeschiedene Person (nur Name und „ausgeschieden seit“) und können sie dort wieder aktivieren und ihrem Referat zuordnen.
- Tabelle der Aktiven mit Suche (Name, Rufname) und Filtern: Ehrenamtsstatus, Referat, Funktion, Amt, Gremium, Qualifikation (Auswahl einer Qualifikationsart, optional Sparte), Ablaufstatus.
- Detailansicht einer Person mit allen lesbaren Eigenschaften und deren Historie (gültig von/bis), gruppiert nach Kategorie.
- Person anlegen (Vorname, Nachname, optional Rufname; Dublettenwarnung aus der Administration, auch gegen ausgeschiedene Personen; Ehrenamtsstatus „aktiv“ als Startwert [ANNAHME]), Eigenschaften pflegen. Kein Löschen in der Oberfläche.
- Eigenschaftsarten anlegen und ändern (Geschäftsstelle, Admin) mit Zweck (Pflicht), Kategorie, 1–n Feldern (Name, Datentyp Text/Zahl/Datum/Jahr/Ja-Nein/Auswahlliste/Qualifikationsart, Pflicht), „sichtbar in“, Lesestufe und Hinweis auf Art. 9 DSGVO. Mehrere gleichzeitig gültige Eigenschaften derselben Art sind möglich (z. B. drei Lizenzen, zwei Schlüssel).
- Drei feste Lesestufen je Eigenschaftsart, durchgesetzt per RLS:
  - „alle mit Zugriff auf das Ehrenamtsmanagement“ (z. B. Kontaktdaten, Qualifikation, Funktion, Ausgaben)
  - „nur Geschäftsstelle und Admin“ (z. B. Führungszeugnis-Einsicht, Bankverbindung, Geburtsdatum, Geschlecht, Förderung)
  - „vertraulich“ (nur mit Rechten auf die Administration, z. B. Hauptamt)
- Startbestand an Eigenschaftsarten aus der Aktivenliste (Details in migration-aktivenliste.md), u. a.: Mitglied, Kontaktdaten, DAV-E-Mail-Adresse, Bankverbindung, Geburtsdatum, Geschlecht, Lizenz, Fortbildung, Weiterbildung, Trainer- und Jugendleiterausweis, Führungszeugnis-Einsicht, Ehrenkodex, Trainervereinbarung, Jugendleiter- und Trainermarke, Förderung, Ausgabe (Schlüssel, Karte, Jahreskarte, Vereinsjacke), Ehrenamtspass, Zugang extern (DAV360, Verteiler usw.), Auszeichnung.
- Geburtsdatum und Geschlecht mit dokumentiertem Zweck: Lizenzanträge und korrekte Ansprache (Product Owner 21.10.2026). Geschlecht: weiblich, männlich, divers, keine Angabe [ANNAHME].
- Jahreseinträge statt Jahresspalten (Fortbildung, Marke, Förderung, Jahreskarte); Filter „für Jahr X noch nicht ausgegeben bzw. beantragt“ [ANNAHME].
- Stammdaten Referate (7): Ausbildung, Touren, Kinder und Jugend, Klettern, Leistungssport, Karl-Stein-Hütte, Sulzenauhütte. Eine Person kann mehreren Referaten zugeordnet sein.
- Zuordnung einer Person zu einem Referat über Funktion oder Amt mit Bezug auf das Referat (z. B. „Trainer:in – Kinder und Jugend“, „Hüttenwart:in – Karl-Stein-Hütte“); endet die Eigenschaft, verschwindet die Person aus der Sicht dieses Referats.
- Sicht je Referat für Referent:innen (lesen und bearbeiten im Rahmen der Lesestufe).
- Funktionen mit Bezug auf eine Gruppe (Gruppenleitung, Trainer:in, Helfer:in) werden im Ehrenamtsmanagement nur angezeigt; gepflegt im Modul Gruppen.
- Stammdaten Gremien (4): Vorstand, Beirat, Ehrenrat, Jugendausschuss. Zugehörigkeit als Amt mit Bezug auf das Gremium; Gremium-Sichten nur lesen, nur für Geschäftsstelle und Admin; Pflege durch Geschäftsstelle und Admin.
- **Qualifikationsarten** kommen aus der Administration (spec.md AD v0.6, US-AD-17 bis US-AD-19):
  - Startbestand 47 Einträge (stammdaten-qualifikationsarten.md) mit Sparte, Typ (Lizenz, Zusatzqualifikation, Lehrgang, Weiterbildung), Lizenzstufe, Spezifikation, Aussteller, DOSB-lizenzfähig, Gültigkeitsdauer und Status (aktuell, historisch).
  - Das Ehrenamtsmanagement hängt die Seiten „Qualifikationsarten“ der Administration unter /ea/qualifikationsarten in seine Navigation ein (nur für „EA verwalten“).
  - Qualifikationen an Personen verweisen auf eine Qualifikationsart (Datentyp „Qualifikationsart“); historische Qualifikationsarten sind nicht neu vergebbar, Altbestand bleibt.
- Lizenz an einer Person mit Feldern: Qualifikationsart (Verweis, nur Typ „Lizenz“), Lizenznummer (DOSB/LFV, je Lizenz eine eigene), Stufe laut Vereinsportal, erworben bzw. verlängert am, gültig bis, letzte Fortbildung, Jahr Kursverlängerung. [ANNAHME] Das Ablaufdatum wird vorbelegt mit dem 31.12. des Jahres „letzte Aus- bzw. Fortbildung + Gültigkeitsdauer der Qualifikationsart“ (nach Fortbildungsregelung des Bundesverbands) und ist manuell änderbar. Eine Verlängerung erzeugt einen neuen Eintrag; der alte bleibt in der Historie.
- Weiterbildungen, Zusatzqualifikationen und Aufbaumodule ebenfalls als Qualifikation mit Verweis auf eine Qualifikationsart; Ablaufdatum nur, wenn die Qualifikationsart eine Gültigkeitsdauer hat.
- Markierungen für Qualifikationen mit Ablaufdatum: „abgelaufen“, „läuft in ≤ 3 Monaten ab“, [ANNAHME] „Trainer:in ohne gültige Lizenz“ (Funktion wird nicht automatisch beendet). [ANNAHME] Gilt für aktive und ruhende Personen, nicht für ausgeschiedene.
- Stichtagsliste 1. Oktober: alle Qualifikationen mit Ablauf im Folgejahr; jederzeit aufrufbar („manuell auslösen“). [ANNAHME] Export als CSV nur mit „verwalten“ (Geschäftsstelle, Admin).
- Einmalige Migration der Aktivenliste per Skript (von Claude Code vorbereitet) nach migration-aktivenliste.md, wiederverwendbar für weitere Listen:
  - nur das Tabellenblatt der aktiven und ruhenden Aktiven; das Blatt der Karteileichen wird nicht migriert
  - harmonisierte Feldnamen je Eigenschaftsart; unklare Felder werden 1:1 übernommen und später bereinigt
  - Spalte „aktiv?“ → Ehrenamtsstatus („ja“ → aktiv, „nein“ → ruhend)
  - Lizenzbezeichnungen der Excel-Liste werden über eine Zuordnungstabelle (Excel-Bezeichnung → Kürzel der Qualifikationsart) aufgelöst; auch historische Qualifikationsarten sind zulässig (Altbestand)
  - Spalten „Gruppe“ und „Gruppenleitung“ nur im Prüfbericht, Übernahme mit dem Gruppen-Import
  - Spalte „Anmerkung“ wird nicht übernommen
  - Entwicklung und Test nur mit fiktiver CSV in TEST
  - Stichtag: Excel-Liste wird eingefroren und vorab bereinigt (Dubletten, Schreibweisen, Lizenzbezeichnungen)
  - Probelauf mit Prüfbericht ohne Schreiben (Fehler, unbekannte Qualifikationsarten, Dublettenverdacht, nicht zerlegbare Adressen, Personen mit mehreren Lizenzen, aber nur einer Lizenznummer), dann Lauf gegen PROD durch den Admin
  - Excel- und CSV-Dateien nie im Repository, nie in TEST
- Funktionspersonen werden ausgeblendet.

**Nicht im Scope:**
- Migration der Karteileichen ([OFFEN], ob überhaupt; siehe Offene Fragen).
- Löschen von Personen in der Oberfläche.
- Ehrenamtsstatus je Referat.
- Geburtstagserinnerung (nach MVP; braucht Entscheidung, ob Referent:innen Geburtstage sehen).
- Einsätze, Anwesenheit, Zeiten, Einsatzserien (→ Modul Einsätze); „TE pro Woche“ bleibt bis dahin ein Feld an der Funktion.
- Veranstaltungen (z. B. Europacup, Bergfilmfestival) und Projektteams (→ Modul Einsätze bzw. später).
- Trainerabrechnung, Übungsleiterpauschale (→ [OFFEN] Modul Finanzen, Modul Einsätze oder eigenes Modul).
- Gruppen, Teilnehmer:innen, Pflege der Gruppen-Funktionen, Sicht für Gruppenleitungen (→ Modul Gruppen).
- Ablage von Dokumenten (Ausweiskopie, unterschriebener Ehrenkodex, Trainervereinbarung); nur Vermerke.
- Steuerung externer Systeme (DAV360, Verteiler); nur Vermerke.
- E-Mail-Benachrichtigung vor Ablauf einer Qualifikation (→ Schnittstellen-Connector).
- Dashboard.
- Import-Oberfläche, Dublettenprüfliste, Zusammenführen von Personen.
- Löschlauf nach 5 Jahren ([OFFEN], Datenmodell vorbereitet; Frist beginnt mit „ausgeschieden“ [ANNAHME]).
- Verpflichtungserklärung zum Datenschutz bei der ersten Anmeldung ([OFFEN], später).
- Frei wählbare Leserechte je Eigenschaftsart und Rechtevorlage (Option B, nach MVP).
- Zugang für Aktive und Gruppenleitungen.
- Konfigurierbares Regelwerk für Ablaufwarnungen (Vorlauf, Stichtag, Erinnerungen).
- Regelwerk Führungszeugnis-Einsicht (Pflicht je Funktion, Erneuerung), bis der Product Owner es liefert.
- Datenmodell und Pflege der Qualifikationsarten selbst (→ Administration).
- Abgleich mit dem Bundesverband (Lizenzstatus, Fortbildungsnachweise).

**Abhängigkeiten:**
- Administration → Ehrenamtsmanagement: Nutzer, Rechtevorlagen, Rechte, Grundstruktur des Personenmodells (liefert). **Nachtrag in der Administration nötig:**
  - Rechtevorlage Referent:in, Reichweite „Referat“ im MVP (ein oder mehrere Referate je Zuweisung), Testzugang Referent:in
  - Lesestufe an der Eigenschaftsart (drei Stufen, erweitert „vertraulich“)
  - Eigenschaftsart mit mehreren Feldern und Kategorie (bestätigt 21.10.2026); der Datentyp „Qualifikationsart“ muss je Feld verfügbar sein
  - Rufname an der Person
  - RLS: Ehrenamtsmanagement zeigt nur Personen mit Ehrenamtsstatus; ausgeschiedene nur für Geschäftsstelle und Admin (präzisiert den Nachtrag aus dem Steckbrief Gruppen „nur Aktive“)
  - Dublettenwarnung berücksichtigt ausgeschiedene Personen und zeigt Referent:innen nur Name und „ausgeschieden seit“ [ANNAHME]
  - Erledigt in spec.md AD v0.6 (21.10.2026): Qualifikationsarten mit Startbestand, Pflegerecht für „EA verwalten“, Datentyp „Qualifikationsart“
- Ehrenamtsmanagement ↔ Gruppen: gemeinsame Personen-Tabelle; Gruppen-Funktionen pflegt das Modul Gruppen, Ehrenamtsmanagement zeigt sie an; Gruppen liest Referate und Personen. Wird eine Person in Gruppen als Trainer:in oder Helfer:in eingetragen, braucht sie einen Ehrenamtsstatus [ANNAHME: Gruppen setzt „aktiv“, falls noch keiner vorhanden]. Spalten „Gruppe“ und „Gruppenleitung“ der Aktivenliste gehen an den Gruppen-Import.
- Ehrenamtsmanagement → Einsätze, Finanzen, Projektmanagement, Aufgabenmanagement: Personen, Eigenschaften, Referate, Gremien, Ehrenamtsstatus (liefert; andere Module lesen, kopieren nicht). Finanzen liest Bankverbindung und Trainervereinbarung.
- Einsätze → Finanzen: Einsätze als Grundlage der Trainerabrechnung (Zuordnung [OFFEN]).
- Schnittstellen-Connector → Ehrenamtsmanagement (nach MVP): E-Mail vor Ablauf einer Qualifikation; Geburtstagserinnerung.
- Migration: Supabase CLI bzw. Skript mit Schlüssel mit vollen Rechten, nur lokal beim Admin; setzt den Startbestand der Qualifikationsarten voraus.
- Extern: Ausbildungsstruktur und Fortbildungsregelung des Bundesverbands ändern sich jährlich; Pflege der Qualifikationsarten durch Geschäftsstelle bzw. Admin.

**Risiken / Besonderheiten:**
- Nachtrag Administration: Reichweite „Referat“, Lesestufen, Ehrenamtsstatus und Eigenschaftsarten mit mehreren Feldern machen Datenmodell und RLS-Regeln deutlich komplexer. Die abgestimmten Stories und die Spec der Administration müssen ergänzt werden, bevor das Ehrenamtsmanagement umgesetzt wird.
- Status für die ganze Person: Eine Referentin kann eine Person, die auch in anderen Referaten tätig ist, für alle auf „ruhend“ oder „ausgeschieden“ setzen (bewusst entschieden, 21.10.2026). Gegenmaßnahme: Hinweis auf die anderen Referate mit Bestätigung [ANNAHME], Historie mit „wer, wann“.
- Manueller Status: Ehrenamtsstatus und Ämter/Funktionen können auseinanderlaufen (z. B. „aktiv“ ohne gültige Funktion, „ruhend“ mit laufender Funktion). [ANNAHME] Kein Automatismus; Filter bzw. Hinweis für solche Fälle.
- Dynamische Felder: Filter und Sortierung über frei definierte Felder sind aufwendiger als über feste Spalten; Filter im MVP auf feste Kriterien (siehe oben) beschränkt [ANNAHME].
- Datenschutz: Statt 4 Nutzern kommen ca. 8–10 Referent:innen und Hüttenwart:innen [ANNAHME] mit Zugriff auf Personendaten hinzu, alle ehrenamtlich. Die Verpflichtung auf Vertraulichkeit ist nicht im MVP.
- Datenschutz: Konflikt zwischen offener Vereinskultur und Datenminimierung. Referent:innen sehen bei einer Person in mehreren Referaten alle Eigenschaften der Lesestufe „alle mit Zugriff“, auch aus fremden Referaten. Gegenmaßnahme: Lesestufen, später Verpflichtungserklärung.
- Datenschutz: Die Dublettenwarnung zeigt Referent:innen Namen ausgeschiedener Personen außerhalb ihres Referats (nur Name und Datum) [ANNAHME]; notwendig für die Rückkehr ohne Dublette.
- Datenschutz: Bankverbindung, Geburtsdatum und Geschlecht nur mit Lesestufe „nur Geschäftsstelle und Admin“; Zweck für Geburtsdatum und Geschlecht dokumentiert. Ausweis: nur Trainer- und Jugendleiterausweis (Nummer, Vermerk Kopie), kein Personalausweis.
- Datenschutz: Karteileichen bleiben bis zu einer Entscheidung in der Excel-Liste; nach Abschalten der Liste dort weiterhin zu löschen bzw. nach 5-Jahres-Regel zu behandeln.
- Datenschutz: Information der Aktiven über die interne Weitergabe ist durch den Product Owner geklärt (21.10.2026).
- Datenschutz: Frei angelegte Eigenschaftsarten laden zum Erfassen sensibler Daten ein; Gegenmaßnahme: Pflichtangabe Zweck, Hinweistext, Lesestufe. Freitext „Anmerkung“ wird nicht migriert.
- Migration: Echte Daten laufen über den Rechner des Admins; Datenqualität der Excel-Liste unklar (Freitext bei Lizenzen, Fortbildungen, Aufbaumodulen, Adressen); nur eine Spalte Lizenznummer für bis zu drei Lizenzen; Excel-Bezeichnungen der Lizenzen müssen vor dem Lauf den 47 Qualifikationsarten zugeordnet werden.
- Ablaufdatum: Laut Fortbildungsregelung des Bundesverbands zählt das Kalenderjahr der letzten Aus- bzw. Fortbildung; die DOSB-Lizenz läuft dagegen 4 Jahre ab Ausstellungsdatum. Beide Daten können voneinander abweichen ([OFFEN], ob beide geführt werden).
- Ablaufwarnung nur im System: Wer nicht hineinschaut, merkt nichts.
- Kein Backup von PROD (akzeptiert); ein Prompt für ein lokales Backup liegt vor (claude/prompts/prod-backup.md). [ANNAHME] Die archivierte Excel-Liste bleibt bis zu ihrer Löschung Notfallquelle für den Stand am Stichtag.
- Begriffe: „Vorstand“ ist Amt, Gremium und Rechtevorlage; „Referent:in“ ist Amt und Rechtevorlage; „aktiv“ ist Ehrenamtsstatus und Status eines Zugangs; „Sparte“ gilt nur für Qualifikationsarten, nicht für Referate. Im Code klar trennen (eigene Tabellen bzw. Bezeichner).

**Offene Fragen:**
- [OFFEN] Karteileichen: später migrieren (z. B. nur, wenn das Ausscheiden weniger als 5 Jahre zurückliegt, mit Status „ausgeschieden“) oder in der Excel-Liste belassen und mit ihr löschen?
- Erledigt 22.10.2026: DOSB-Lizenz als optionales Feld „DOSB-Lizenz gültig bis“ an der Lizenz, ohne Ablaufmarkierung im MVP.
- [OFFEN] Qualifikationsarten mit Klärungsbedarf (stammdaten-qualifikationsarten.md, Abschnitt 6): PSA (vorerst historisch), Trainer*in C Mountainbike Guide & Fahrtechnik, Jugendleiter*in (DOSB-Lizenz, Juleica), nicht im Export enthaltene Qualifikationsarten (z. B. DAV-Skibetreuer*in ab 2027).
- [OFFEN] Regelwerk Führungszeugnis-Einsicht: Pflicht je Funktion, Erneuerungsintervall, weitere Nachweise. Liefert Product Owner.
- [OFFEN] Offene Punkte der Spaltenzuordnung (migration-aktivenliste.md, Abschnitt 5): „LE“, „Jahr Kurs-verlängerung“, Fördergeber, Jahreskarte, Forms/Redaktion/Mailingliste, Amtszeit Jugendausschuss.
- [OFFEN] Ist „Mitarbeiter:in Mitgliederverwaltung“ eine ehrenamtliche Funktion oder ein Hauptamt?
- [OFFEN] Löschlauf nach 5 Jahren: ganz löschen oder Stammdaten behalten; Löschung des Zugangs. Später.
- [OFFEN] Verpflichtungserklärung bei der ersten Anmeldung: Text, Versionierung, erneute Bestätigung (nach MVP, betrifft Administration).
