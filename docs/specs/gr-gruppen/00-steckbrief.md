# Steckbrief: Gruppen

Stand: 22.10.2026 · Version 0.7 · Kürzel: GR · Priorität: 2 · Ablage: docs/specs/gr-gruppen/
Änderungen v0.7: Übergabe aus der Anwesenheitserfassung (uebergabe-trainingszeiten.md v1.2) eingearbeitet: Trainingszeiten strukturiert (Wochentag, Beginn, Ende, gültig von/bis) mit Historie statt Textfeld; Lesefunktion für die Anwesenheitserfassung zu einem Stichtag (nur Namen); Modul Einsätze heißt Anwesenheitserfassung; Reihenfolge Gruppen vor Anwesenheitserfassung.
Änderungen v0.6: Admin sieht in der Administration alle Personen, auch Teilnehmer:innen, Erziehungsberechtigte und Notfallkontakte, und pflegt ihre Personendaten (Name, Rufname, Geburtsdatum, Kontaktdaten, Mitgliedsnummer) zentral; Änderungen gelten in allen Modulen (Product Owner, 21.10.2026). Ersetzt die Entscheidung vom selben Tag, Personen nur mit Gruppenbezug in der Administration auszublenden.
Änderungen v0.5: Teilnahme nur mit aktivem Vertrag; nach Vertragsende sichtbarer Hinweis „Teilnahme klären“.
Änderungen v0.4: Vertragsende und Ende der Teilnahme sind unabhängig („Teilnahme bis“ statt „Austrittsdatum“, keine Verwechslung mit dem Austritt aus der Sektion); Referat je Gruppe bestätigt; Adresse der Teilnehmer:in beim Import von der ersten erziehungsberechtigten Person, Nacharbeit durch die Geschäftsstelle.
Änderungen v0.3: Gruppen ist die erfassende und pflegende Schicht für alle Daten der Excel, Verträge eingeschlossen; Finanzen liest. Vertrag je Teilnahme (Kind und Gruppe), monatliche Abbuchung, Kündigung je Gruppe. Gesundheitsangaben: Geschäftsstelle im MVP, später Gruppenleitung und Trainer:innen der eigenen Gruppe, nie Helfer:innen. Fotoerlaubnis ja/nein. Freigabe von Ausfahrten nicht im Scope.
Änderungen v0.2: Spalten der Bestands-Excel ausgewertet; Gesundheitsangaben, Fotoerlaubnis, Mitgliedsnummer, Trainingszeit, SEPA-Mandat in den Scope; bis zu zwei Erziehungsberechtigte; Adresse der Teilnehmer:in separat; Abgleich mit Steckbrief Ehrenamtsmanagement v0.2 (Referate, Lesestufen, Modul Einsätze).

**Problem heute:**
Gruppen, Teilnehmer:innen, Erziehungsberechtigte, Notfallkontakte und Beitragsdaten stehen in einer Excel-Datei mit einem Tabellenblatt je Gruppe, die nur wenige Personen einsehen. Die Liste ist reine Datenhaltung: Es lassen sich keine Folgeaktionen ableiten, z. B. nicht schnell alle E-Mail-Adressen der Erziehungsberechtigten einer Gruppe herausziehen oder bei einer Ausfahrt die Notfallkontakte und gesundheitlichen Einschränkungen eines Kindes finden. Ein Kind in zwei Gruppen steht in zwei Tabellenblättern. Gruppenleitung, Trainer:innen und Helfer:innen sind nicht mit den Aktiven im Ehrenamtsmanagement verbunden.

**Ziel / Erfolgsmessung:**
- Die Excel-Datei ist abgelöst: Alle Gruppen, Teilnehmer:innen, Erziehungsberechtigten, Notfallkontakte und Verträge des Kinder- und Jugendbereichs liegen in PROD und werden nur noch dort gepflegt. Kein Abschalttermin festgelegt (Product Owner, 21.10.2026).
- Gruppen liefert der Anwesenheitserfassung Trainingszeiten und Anwesenheitslisten (Product Owner, 22.10.2026: Gruppen wird vor der Anwesenheitserfassung umgesetzt).
- Nutzungsdauer: mindestens bis zur Umstellung der Mitgliederverwaltung auf Salesforce (voraussichtlich Anfang/Mitte 2028).

**Nutzer & Rechtevorlagen:**
- Geschäftsstelle – Gruppen verwalten: alle 3 Mitarbeitenden gleich; pflegen Gruppen, Trainingszeiten, Teilnehmer:innen, Erziehungsberechtigte, Notfallkontakte, Verträge, Bankverbindungen; erfassen und lesen im MVP auch die Gesundheitsangaben (Variante A, Product Owner, 21.10.2026).
- Admin – Gruppen lesen [ANNAHME: Startwert]: Risikomanagement (Notfall auf einer Ausfahrt). Keine Gesundheitsangaben.
- Admin in der Administration – Gesamtübersicht über alle Personen, auch Teilnehmer:innen, Erziehungsberechtigte und Notfallkontakte; pflegt deren Personendaten zentral, damit eine Änderung (z. B. neue Adresse) nicht je Modul nötig ist (Product Owner, 21.10.2026). Gruppenspezifische Angaben (Teilnahme, Vertrag, Notfallkontakt-Zuordnung, Fotoerlaubnis) pflegt er nicht in der Administration; Gesundheitsangaben sieht er nie.
- Vorstand – Vorlage startet ohne Rechte (rollen.md unverändert); der Admin vergibt bei Bedarf „Gruppen lesen“. Mit „lesen“ sind auch Bankverbindungen sichtbar (z. B. Schatzmeister:in zur Kontrolle) – bewusst entschieden. Keine Gesundheitsangaben.
- Nutzer der Anwesenheitserfassung (Geschäftsstelle, Referent:innen für Gruppen ihres Referats, Admin lesen) – lesen über eine eigene Funktion je Gruppe und Stichtag nur Namen von Teilnehmer:innen, Gruppenleitung, Trainer:innen und Helfer:innen sowie die gültige Trainingszeit; dafür ist kein Recht auf Gruppen nötig.
- Gruppenleitung und Trainer:innen (nach MVP, Reichweite „Gruppe“) – lesen die Gesundheitsangaben der eigenen Gruppe; Gruppenleitung fügt zusätzlich Teilnehmer:innen hinzu und markiert sie als ausgeschieden. Helfer:innen lesen nie Gesundheitsangaben (Product Owner, 21.10.2026). Ob Gruppenleitung und Trainer:innen Bankdaten sehen: [OFFEN] für die Iteration mit Zugang.
- Umsetzung im MVP: Gesundheitsangaben ab „Gruppen bearbeiten“ lesbar. Bekommt der Vorstand später „Gruppen bearbeiten“, sieht er sie mit; saubere Trennung erst mit Rechten je Objekt (nach MVP).
- E-Mail-Liste einer Gruppe kopieren: ab „lesen“ [ANNAHME].

**Im Scope (MVP):**
- Gruppen anlegen, ändern, auflösen; nur Kinder- und Jugendbereich. Felder: Name, Referat (bestätigt).
- Trainingszeiten je Gruppe (0–n): Wochentag, Beginn, Ende, gültig von, gültig bis; Änderungen mit Historie (alte Trainingszeit endet, neue beginnt). Ersetzt das bisherige Textfeld „Trainingszeit“ (Übergabe aus der Anwesenheitserfassung, 22.10.2026).
- Teilnehmer:innen einer Gruppe zuordnen und die Teilnahme beenden („Teilnahme bis“); eine Person kann in mehreren Gruppen sein. Das betrifft nur die Gruppe, nie die Mitgliedschaft in der Sektion.
- Je Teilnehmer:in: Vorname, Nachname, Geburtsdatum (Alter wird berechnet), Adresse (separat erfasst, kann der Adresse einer erziehungsberechtigten Person entsprechen), Mitgliedsnummer, Fotoerlaubnis (ja/nein), gesundheitliche Einschränkungen.
- Bis zu zwei Erziehungsberechtigte je Teilnehmer:in: Vorname, Nachname, Adresse, Telefon, E-Mail; kein Geburtsdatum; Vertragsinhaber:in kennzeichnen.
- Notfallkontakte je Teilnehmer:in, mehrere möglich: immer Vorname, Nachname und Telefon oder E-Mail; kann eine erziehungsberechtigte Person sein.
- Vertrag je Teilnahme (je Kind und Gruppe; getrennte Verträge und getrennte Lastschriften je Gruppe; eine Person kann mehrere Verträge haben): Vertragsbeginn, Vertragsinhaber:in, Kontoinhaber:in, IBAN (automatische Prüfung), Mandatsreferenz, Unterschriftsdatum des Mandats, Verwendungszweck, monatlicher Betrag. Laufzeit unbefristet; eine Kündigung beendet den Vertrag dieser Gruppe, andere Verträge bleiben bestehen. Vertragsende und „Teilnahme bis“ werden unabhängig gepflegt. Eine Teilnahme entsteht nur zusammen mit einem aktiven Vertrag; endet der Vertrag bei offener Teilnahme, zeigt das System den Hinweis „Vertrag beendet – Teilnahme klären“.
- Gruppenleitung, Trainer:innen und Helfer:innen je Gruppe festlegen; sichtbar im Ehrenamtsmanagement.
- Lesefunktion für die Anwesenheitserfassung: je Gruppe und Datum die gültige Trainingszeit sowie Teilnehmer:innen mit gültiger Teilnahme und Gruppenleitung, Trainer:innen, Helfer:innen mit gültiger Funktion – nur Vorname, Rufname, Nachname.
- E-Mail-Adressen der Erziehungsberechtigten einer Gruppe als Liste kopieren, für den Versand außerhalb des Vereins OS.
- Einmaliger Import der Bestands-Excel per Skript (ein Tabellenblatt je Gruppe, Dublettenprüfung über alle Blätter; Trainingszeit aus dem Kopf in strukturierte Trainingszeiten überführt); keine Importfunktion in der Oberfläche.

**Nicht im Scope:**
- Erwachsenenbereich (später).
- Zugang und Pflege durch Gruppenleitungen (nach MVP).
- Rundmails aus dem Vereins OS.
- Vertragsübersicht, Buchungslauf / SEPA-Lastschriftlauf (Modul Finanzen; liest die Verträge aus Gruppen).
- Erfassung von Einsätzen, Trainings, Ausfahrten und Anwesenheit (Modul Anwesenheitserfassung); Freigabe von Ausfahrten (vorerst in keinem Modul); Anmeldung von Fahrten (Modul Touren und Kurse).
- Ausfallzeiten (Ferien, Hallenschließung) an Trainingszeiten (Product Owner, 21.10.2026: in den Ferien wird kein Training erfasst).
- Bedarf / Auslastung einer Gruppe: wird als Auswertung in der Anwesenheitserfassung gebaut und später an Gruppen zurückgespielt. Die Excel-Spalte „Bedarf“ wird nicht übernommen [ANNAHME].
- Anzeige der Anzahl Trainings und Einsätze an der Gruppe (mit der Anwesenheitserfassung, Iteration 2).
- Abrechnung von Trainer:innen und Helfer:innen (Modul Finanzen).
- Wartelisten, Anmeldung durch Erziehungsberechtigte.
- Manueller Prüfvermerk „IBAN korrekt“ (ersetzt durch automatische Prüfung).
- Abgleich oder Schnittstelle zur Mitgliederverwaltung.
- Importfunktion in der Oberfläche.

**Abhängigkeiten:**
- Administration ↔ Gruppen: Zugänge, Rechtevorlagen, RLS, Grundstruktur des Personenmodells. Die Administration zeigt alle Personen einschließlich der Personen, die nur in Gruppen vorkommen, und ist der zentrale Ort für deren Personendaten. Nachtrag RLS in der Administration eingearbeitet (spec.md AD v0.7.1).
- Ehrenamtsmanagement ↔ Gruppen: **eine gemeinsame Personen-Tabelle** (Entscheidung Product Owner, 21.10.2026, Variante B).
  - Teilnehmer:innen, Erziehungsberechtigte und Notfallkontakte sind Personen in derselben Tabelle; gruppenspezifische Daten (Teilnahme, Beziehung, Notfallkontakt, Vertrag, Gesundheitsangaben, Fotoerlaubnis, Trainingszeiten) liegen in eigenen Tabellen mit Präfix `gr_`.
  - Das Ehrenamtsmanagement zeigt nur Aktive; Personen, die nur in Gruppen vorkommen, sind dort nicht sichtbar – per RLS.
  - Ein Mensch kann beides sein (Erziehungsberechtigte:r und Trainer:in; Jugendliche:r ab 16 als Teilnehmer:in und Helfer:in) und existiert dann nur einmal.
  - Gruppenleitung, Trainer:in, Helfer:in: Gruppen ist führend; gespeichert als Funktion mit Bezug auf die Gruppe [ANNAHME]; im Ehrenamtsmanagement nur lesbar.
  - Referat: Jede Gruppe wird einem Referat zugeordnet (z. B. „Jugendgruppe“ → Kinder und Jugend).
- Gruppen → Finanzen: Teilnahme, Ausscheiden, Vertrag, Mandat, monatlicher Betrag, Bankverbindung als Grundlage für Vertragsübersicht und monatlichen Buchungslauf (Einzug, eine Lastschrift je Vertrag). Finanzen liest, pflegt nicht. Das Datenmodell der Verträge muss den SEPA-Export ohne Umbau tragen.
- Gruppen → Anwesenheitserfassung: Gruppen mit Referat, Trainingszeiten (Vorschlag beim Erfassen eines Trainings), Anwesenheitsliste je Stichtag (nur Namen). Quelle: specs/ez-einsaetze/uebergabe-trainingszeiten.md v1.2 (eingearbeitet 22.10.2026). Zurück (Iteration 2): Auslastung/Bedarf und Anzahl Trainings.
- Gruppen → Öffentlichkeitsarbeit (später): Fotoerlaubnis.
- Schnittstellen-Connector: keine im MVP.
- Reihenfolge: braucht Personenmodell und Nachtrag RLS aus der Administration sowie Referate; kommt vor der Anwesenheitserfassung.

**Risiken / Besonderheiten:**
- **Gesundheitsdaten Minderjähriger** (Art. 9 DSGVO): eigene Tabelle, eigene RLS-Regel, nie über „Gruppen lesen“ sichtbar. Verarbeitung braucht eine ausdrückliche Einwilligung der Erziehungsberechtigten [OFFEN: im bestehenden Vertrag enthalten?]. Im MVP liest nur die Geschäftsstelle; der eigentliche Zweck (Information der Gruppenleitung und Trainer:innen auf Ausfahrten) ist erst mit deren Zugang erfüllt.
- **Daten Minderjähriger und Dritter:** Datenumfang wie oben begrenzt. Rechtsgrundlage für Teilnehmer:innen und Erziehungsberechtigte: bestehender Vertrag. [OFFEN] Rechtsgrundlage für Notfallkontakte, die keine Erziehungsberechtigten sind.
- **Namen von Kindern in der Anwesenheitserfassung:** Referent:innen sehen über die Lesefunktion Vor- und Nachnamen der Teilnehmer:innen der Gruppen ihres Referats, ohne Rechte auf Gruppen. Nur Namen; Eintrag im Verarbeitungsverzeichnis.
- **Fotoerlaubnis** ist eine Einwilligung: widerrufbar, Datum der Erteilung bzw. des Widerrufs nachhalten [ANNAHME].
- **Bankverbindungen und Mandate:** sichtbar für alle mit „Gruppen lesen“ (bewusst entschieden). Eintrag im Verarbeitungsverzeichnis.
- **Löschfrist:** 5 Jahre nach dem späteren Datum aus Ende der letzten Teilnahme und Ende des letzten Vertrags [ANNAHME]. Gesetzliche Aufbewahrungsfristen für Vertrags- und Lastschriftdaten können länger sein (Klärung mit Finanzen). Gesundheitsangaben ggf. früher löschen [OFFEN]. Personen, die zugleich Aktive sind, werden nicht gelöscht.
- **RLS-Aufwand:** gemeinsame Personen-Tabelle braucht Sichtbarkeit je Zugehörigkeit (Gruppen / Ehrenamtsmanagement / Anwesenheitserfassung) und eine eigene Regel für Gesundheitsangaben.
- **Import per Skript:** läuft mit technischem Vollzugriff auf PROD, inkl. Gesundheitsdaten; Product Owner führt es aus [ANNAHME]; Excel nie im Repo, nie in TEST. Datenqualität: Name der erziehungsberechtigten Person in einem Feld, Notfallkontakte ohne Spaltenüberschriften, Adresse der Teilnehmer:in fehlt (wird von der ersten erziehungsberechtigten Person übernommen; Nacharbeit durch die Geschäftsstelle); Trainingszeit als Freitext (nicht lesbare Angaben im Prüfbericht, Nacharbeit durch die Geschäftsstelle).
- **Backup:** Prompt für tägliches, verschlüsseltes lokales Backup liegt vor (claude/prompts/prod-backup.md). Das Backup enthält Gesundheits- und Bankdaten.
- **Gesamtübersicht des Admins:** Der Admin sieht Daten von Kindern und Dritten (Name, Geburtsdatum, Adresse, Kontaktdaten) in der Administration. Bewusst entschieden zugunsten zentraler Pflege; Kreis klein halten (heute nur Product Owner, später Vertretung aus der Geschäftsstelle); im Verarbeitungsverzeichnis als Zugriffsberechtigung aufführen.
- **Doppelte Datenhaltung** zur Mitgliederverwaltung (Name, Geburtsdatum, Adresse, Mitgliedsnummer), ohne Abgleich; bewusst akzeptiert.
- **E-Mail-Liste kopieren:** Daten verlassen das Vereins OS; Versand nur in Blindkopie (BCC), Hinweis in der Oberfläche [ANNAHME].
- **Mobile Nutzung im Notfall:** Notfallkontakte müssen unterwegs auf dem Telefon schnell auffindbar sein (ab 375 px).
- **Kosten:** keine zusätzlichen; Free-Plan (500 MB) [ANNAHME] ausreichend.

**Offene Fragen:**
- [OFFEN] Ist die ausdrückliche Einwilligung zur Verarbeitung der Gesundheitsangaben im bestehenden Vertrag bzw. Anmeldebogen enthalten?
- [OFFEN] Bankdaten für Gruppenleitung und Trainer:innen nach MVP sichtbar? (Datenminimierung: eher nein)
- [OFFEN] Rechtsgrundlage für Notfallkontakte, die keine Erziehungsberechtigten sind.
- [OFFEN] Beginn der 5-Jahres-Frist und Verhältnis zu gesetzlichen Aufbewahrungsfristen (gemeinsam mit Finanzen); frühere Löschung der Gesundheitsangaben nach Ausscheiden?
- [OFFEN] Dublettenwarnung beim Anlegen von Teilnehmer:innen, Erziehungsberechtigten und Notfallkontakten gegen alle Personen (inkl. Aktive)? Ergebnis darf keine Daten aus dem jeweils anderen Modul preisgeben. (Funktion `ad_find_similar_persons` nach R40 der Administration steht bereit.)

**Folgeänderungen in anderen Dokumenten:**
- glossar.md, rollen.md, modul-landkarte.md, spec.md Administration: erledigt bis v0.6.
- v0.7 (22.10.2026): Trainingszeit im Glossar bereits strukturiert beschrieben (glossar.md v1.5); 01-erhebung.md v0.7 und 02-stories.md v0.4 angepasst; Übergabe uebergabe-trainingszeiten.md als eingearbeitet markiert; offene-punkte.md (Abschnitt GR) aktualisiert.
