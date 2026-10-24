# Steckbrief: Anwesenheitserfassung

Stand: 24.10.2026 · Version 0.9 · Kürzel: EZ · Priorität: nach Gruppen, vor Finanzen · Ablage: docs/specs/ez-einsaetze/ · Status: abgeschlossen, bereit für Stories
Änderungen v0.9: Annahmen bestätigt (Product Owner 24.10.2026): Kürzel EZ und Ablage, Bezeichnungen, Rolle vorbelegt und änderbar, Warnung bei doppelter Erfassung, Eingaben bleiben bei Fehlern erhalten, Funktion Helfer:in für neue Personen.
Änderungen v0.8: Art. 13 DSGVO entschieden (Übergabe aus dem Ehrenamtsmanagement v1.0). Abgleich mit dem Forms-Formular: Training ohne Uhrzeit; Anmeldung von Fahrten als eigene Spezifikation; Einsatzart Wettkampfbetreuung. Übergabe der Planungshilfe Touren und Kurse v1.2 eingearbeitet (Product Owner 24.10.2026): Planungshilfe erzeugt und sagt Kurse und Touren ab; Kurs, Tour und Trainingslager auch von Hand; Kurs und Tour ohne Gruppe und ohne Teilnehmende; Trainingslager wie Mehrtagesfahrt; Stand „abgesagt“ für alle Einsatzarten; offene Frage zur Übernahme erledigt.
Änderungen v0.7: Abweichung von Vergütungsordnung Punkt 7 gestrichen (kein Vorstandsbeschluss nötig, Product Owner 22.10.2026); Abgrenzung zum Modul Touren und Kurse festgelegt (dort Erstellung, Planung und Kalkulation; hier Durchführung und Anwesenheit).
Änderungen v0.6: Reihenfolge Gruppen → Anwesenheitserfassung → Finanzen; Orte als Stammdaten in der Administration; Enduhrzeit bei mehrtägigen Einsätzen; Wettkampfbegleitung ein- oder mehrtägig; Erfassung immer je Gruppe; organisierende Person aus allen Aktiven mit Suche; Kinder mit Vor- und Nachname; Erwachsenenfahrten nicht im Scope; Idee eines eigenen Abrechnungsmoduls.
Änderungen v0.5: Forms-Formular ausgewertet (01-erhebung.md); Zeiten wie heute; Ausbildungsfahrt ein- und mehrtägig; Ort beim Training; Bemerkungsfeld; Anmeldung von Fahrten ins Modul Touren und Kurse.
Änderungen v0.4: Modulname „Anwesenheitserfassung“; Kurse, Touren, Trainingslager im Umfang; Trainingszeit nur als Vorschlag; Reisezeit = Arbeitszeit; Betreuungsschlüssel später; Admin liest.
Änderungen v0.3: Vergütungsordnung eingearbeitet (Trainingseinheit 30 Minuten, Wettkampfbegleitung, Rolle je Anwesenheit, organisierende Person).
Änderungen v0.2: Folgeänderungen ausgeführt; Übergaben angelegt.
Änderungen v0.1: Erster Entwurf.

**Problem heute:**
Trainer:innen erfassen Trainings und Fahrten mobil im Microsoft-Forms-Formular „Anwesenheitserfassung – Jugend“: Art wählen, Gruppe wählen, Kinder und Trainer*innen ankreuzen. Die Antworten landen in einer großen Excel-Tabelle. Daraus werden Abrechnungen nach der Vergütungsordnung (Übungsleiterpauschale, halbjährlich für Kinder und Jugend und Leistungssport) und die Kontrolle der Kletterhalle umständlich von Hand erstellt; Auswertungen fehlen, z. B. wie viele Trainings eine Gruppe hatte oder wie oft ein Kind da war. Helfer:innen werden nicht getrennt von Trainer:innen erfasst. Arbeitseinsätze, Veranstaltungen, Kurse und Touren werden nicht einheitlich erfasst.

**Ziel / Erfolgsmessung:**
- MVP: Einsätze und Anwesenheiten werden zentral in einer eigenen Tabellenstruktur erfasst, so vollständig, dass Finanzen daraus nach der Vergütungsordnung abrechnen kann (Einsatzart, Dauer-Kategorie bzw. Beginn und Ende, Rolle je Person). Geschäftsstelle und Referent:innen können für jeden Einsatz die Anwesenheit eintragen. Der Ablauf entspricht dem heutigen Formular, damit die Umgewöhnung gering bleibt. Das Modul erhebt und speichert; Abrechnung und Auswertung nutzen die Daten in anderen Modulen bzw. Werkzeugen.
- Iteration 1: Das Microsoft-Forms-Formular ist abgelöst: Gruppenleitung und Trainer:innen melden sich an und erfassen für ihre Gruppe je Training die Anwesenheit der Teilnehmer:innen und der Trainer:innen. Das Modul ist dann die „vom Vorstand vorgegebene Form“ des Nachweises der Trainingseinheiten (Vergütungsordnung, Punkt 3) [ANNAHME: Vorstand bestätigt das].

**Nutzer & Rechtevorlagen:**
- Geschäftsstelle – EZ verwalten: alle Einsätze anlegen und ändern, Anwesenheit erfassen und korrigieren, alles lesen.
- Referent:in – EZ bearbeiten, Reichweite „Referat“: Einsätze ihres Referats anlegen (z. B. Arbeitseinsatz, Europacup, Kurs, Tour), Anwesenheit erfassen, Einsätze ihres Referats lesen – bei Gruppen-Einsätzen die der Gruppen ihres Referats.
- Admin – EZ lesen, Reichweite „alle“; pflegt die Stammdaten der Orte in der Administration.
- Vorstand – EZ lesen, Reichweite „alle“; Vorlage startet ohne Rechte, der Admin vergibt sie (rollen.md).
- Gruppenleitung, Trainer:innen (Iteration 1, Reichweite „Gruppe“) – Einsätze ihrer Gruppe anlegen, Anwesenheit erfassen.
- Anlegen von Einsätzen ist ein Recht aus der Rechtevorlage, kein Automatismus aus Amt oder Funktion.

**Im Scope (MVP):**
- Einsatzarten (Bezeichnungen wie im heutigen Formular): Training; Tagesausflug und Mehrtagesfahrt (Ausfahrt); Ausbildungsfahrt (ein- oder mehrtägig; Mehrtageskurs nach Vergütungsordnung); Wettkampfbetreuung (ein- oder mehrtägig); Kurs; Tour; Trainingslager; Arbeitseinsatz. Veranstaltungen wie Europacup und Bergfilmfestival sind Arbeitseinsätze; keine Rechte für Projektteams.
- Einsätze mit Gruppenbezug (Training, Fahrten, Trainingslager, Wettkampfbetreuung) werden immer je Gruppe erfasst; das Referat ergibt sich aus der Gruppe. Kurs, Tour und Arbeitseinsatz gehören direkt zu einem Referat (Product Owner 24.10.2026).
- Kurs und Tour: Durchführung und Anwesenheit von Trainer:innen und Helfer:innen, keine Teilnehmenden (Anmeldung in Yolawo). Die Planungshilfe Touren und Kurse erzeugt den Einsatz, sobald das Angebot in Yolawo angelegt ist, und sagt ihn bei Absage ab; Kurse und Touren ohne Planung werden hier von Hand angelegt (Product Owner 24.10.2026). Trainingslager wie Mehrtagesfahrt.
- Absage: Jeder Einsatz kann mit Grund abgesagt werden und bleibt sichtbar; die Absage ist zurücknehmbar (Product Owner 24.10.2026).
- Training: Datum und Ort aus den Stammdaten der Administration, keine Uhrzeit; die Zeit ergibt sich aus der Trainingszeit der Gruppe (Product Owner 24.10.2026). Ein Training entsteht erst mit der Erfassung; nicht erfasste Termine (z. B. Ferien) sind keine Trainings.
- Fahrten und Wettkampfbetreuung: Titel (1–2 Schlagwörter), organisierende Person (bei Fahrten; Organisationspauschale); eintägig Datum und Dauer „unter 8 Stunden“ / „mindestens 8 Stunden“; mehrtägig Startdatum, Beginn, Enddatum und Ende (Abfahrt und Rückkehr am Startort; Reisezeit = Arbeitszeit). Tages- bzw. Halbtagessätze berechnet Finanzen.
- Organisierende Person: Auswahl aus allen Aktiven mit Suche; ist eine Gruppe gewählt, stehen deren Gruppenleitung, Trainer:innen und Helfer:innen oben.
- Anwesenheit mit Rolle: Trainer:in, Helfer:in oder Teilnehmer:in; Rolle vorbelegt aus der Funktion in der Gruppe bzw. im Referat, je Einsatz änderbar. Ob eine Trainer:in als Trainer:in vergütet wird (förderfähige Lizenz), prüft Finanzen.
- Anwesenheitsliste: Trainer:innen, Helfer:innen und Teilnehmer:innen der Gruppe vorbelegt zum Ankreuzen, angezeigt mit Vorname (bzw. Rufname) und Nachname; weitere Trainer:innen und Helfer:innen (Vertretung) hinzufügbar; Probetraining als Freitext (nur Vorname); Bemerkung als Freitext mit Hinweis, keine sensiblen Angaben über Kinder einzutragen.
- Arbeitseinsatz (und sinngemäß Kurs, Tour): Personen vorab eintragen („eingetragen“), weitere hinzufügen, am Einsatz „anwesend“ bzw. „nicht erschienen“ bestätigen. Beim Arbeitseinsatz können neue Personen angelegt werden und werden als Aktive geführt (Ehrenamtsstatus „aktiv“, Funktion Helfer:in mit Bezug auf das Referat des Einsatzes), mit Dublettenwarnung.
- „Erfasst von“ und „erfasst am“ automatisch; Warnung bei doppelter Erfassung (gleiche Gruppe, Datum, Einsatzart).
- Einfache Listen: Einsätze je Gruppe bzw. Referat und Zeitraum (auch je Abrechnungshalbjahr); Anwesenheit je Einsatz; Anzahl anwesender Teilnehmer:innen (Kinder) je Training, Ort und Zeitraum als Kontrollliste für das Punktekonto der Kletterhalle.
- Erfassung mobil ab 375 px. Kein Offline-Betrieb: Schlägt das Speichern fehl, erscheint ein Hinweis; die Eingabe bleibt im Formular erhalten.
- Erfassung im MVP durch Geschäftsstelle und Referent:innen.

**Nicht im Scope:**
- Erstellung, Planung, Ausschreibung und Kalkulation von Kursen und Touren (Kosten, Ausgaben, Deckungsbeitrag, Material, CO2): Planungshilfe Touren und Kurse. Anmeldung von Fahrten (heute Forms-Formular „Anmeldung Fahrten“ des Jugendreferats: Ziel, Anreise, Kilometer, geplante Tätigkeiten, Trainer:innen, Anzahl Kinder, Material): eigene Spezifikation (Product Owner 24.10.2026).
- Erwachsenenfahrten (später mit gleicher Logik).
- Abrechnung der Vergütung (Übungsleiterpauschale, Trainingseinheiten, Tages- und Halbtagessätze, Organisationspauschale, Abrechnungsdokumente, Prüfung der förderfähigen Lizenz): Modul Finanzen bzw. ein eigenes Abrechnungsmodul [OFFEN]. Die Anwesenheitserfassung liefert Einsatzart, Zeiten bzw. Dauer-Kategorie und Anwesenheit mit Rolle.
- Uhrzeiten bei eintägigen Fahrten (Kategorie genügt).
- Pflege der Orte (Administration) und der Sätze der Vergütungsordnung (Finanzen [ANNAHME]).
- Ehrenamtspauschale; Reisekosten (Reisekostenordnung).
- Hinweis zum Betreuungsschlüssel bei der Erfassung.
- Ausfallzeiten (Ferien, Hallenschließung) in Einsatzserien.
- Abschalttermin des Forms-Formulars.
- Zugang für Gruppenleitungen und Trainer:innen (Iteration 1).
- Auswertungen auf Gruppenebene, z. B. Auslastung, Anzahl Trainings, kritische Situationen beim Betreuungsschlüssel (Iteration 2 oder später).
- Einsatzhistorie und „letzter Einsatz“ je Person (Ehrenamtsmanagement, Iteration 2).
- Einchecken per QR-Code mit Anlegen neuer Personen durch Spontane (späte Iteration).
- Freigabe von Ausfahrten; Zulassung von Touren.
- Anmeldung durch Erziehungsberechtigte.
- Übernahme der Altdaten aus der Forms-Excel.
- Offline-Erfassung.

**Abhängigkeiten:**
- Reihenfolge der Umsetzung: Gruppen → Anwesenheitserfassung → Finanzen (Product Owner 22.10.2026).
- Administration → Anwesenheitserfassung: Zugänge, Rechtevorlagen (inkl. Admin lesen), Reichweite „Referat“, Sichtbarkeitspfad (inkl. Suche über alle Aktiven, nur Name), Anlegen von Aktiven, Stammdaten Orte; für Iteration 1 Reichweite „Gruppe“ und Rechtevorlage Gruppenleitung. Übergabe: uebergabe-rechte-administration.md (v1.2).
- Ehrenamtsmanagement → Anwesenheitserfassung: Aktive (für die organisierende Person), Referate, Funktionen Trainer:in und Helfer:in (Vorbelegung der Rolle).
- Anwesenheitserfassung → Ehrenamtsmanagement: neue Aktive aus Arbeitseinsätzen; Einsatzhistorie und „letzter Einsatz“ (Iteration 2); Nachweise und förderfähige Lizenz für Finanzen. Übergabe: uebergabe-ehrenamtsmanagement.md (v1.2).
- Gruppen → Anwesenheitserfassung: Gruppen mit Referat, Teilnehmer:innen (Vorname bzw. Rufname und Nachname), Gruppenleitung, Trainer:innen, Helfer:innen; strukturierte Trainingszeiten statt Textfeld. Übergabe: uebergabe-trainingszeiten.md (v1.1).
- Anwesenheitserfassung → Gruppen: Auslastung und Anzahl Trainings (Iteration 2).
- Anwesenheitserfassung → Finanzen: Einsätze, Einsatzart, Datum bzw. Start- und Enddatum mit Beginn und Ende (optional), Dauer-Kategorie, organisierende Person, Ort, Anwesenheit mit Rolle als Grundlage der Abrechnung nach der Vergütungsordnung und der Kontrolle der Kletterhalle. Finanzen liest, pflegt nicht. Übergabe: uebergabe-finanzen.md (v1.6). Ob die Abrechnung ein eigenes Modul wird, das in Finanzen aufgeht, ist offen (Navigation später).
- Planungshilfe Touren und Kurse → Anwesenheitserfassung: erzeugt, aktualisiert und sagt Einsätze Kurs und Tour ab; liest den Stand „durchgeführt“. Übergabe: tk-touren-kurse/uebergabe-anwesenheitserfassung.md (v1.2, eingearbeitet in spec.md v0.2).
- Schnittstellen-Connector: keine im MVP.

**Risiken / Besonderheiten:**
- **Daten Minderjähriger für Referent:innen:** Anwesenheitslisten zeigen Teilnehmer:innen mit Vor- und Nachname. Referent:innen haben bisher keinen Zugriff auf Gruppen; das ist ein neuer Sichtbarkeitspfad. Datenminimierung: nur Name, kein Geburtsdatum, keine Kontaktdaten, nie Gesundheitsangaben. Eintrag im Verarbeitungsverzeichnis.
- **Suche über alle Aktiven:** Referent:innen sehen bei der Auswahl der organisierenden Person Namen von Aktiven anderer Referate (nur Name, keine Eigenschaften).
- **Bemerkung als Freitext:** Risiko sensibler Angaben über Kinder; Hinweis am Feld, nur Personen mit Leserecht auf den Einsatz sehen sie.
- **Doppelte Erfassung von Kursen und Touren:** Ein von Hand angelegter Kurs kann später zusätzlich aus der Planungshilfe entstehen; keine automatische Erkennung im MVP [OFFEN, spec.md Abschnitt 11].
- **Abgabefristen der halbjährlichen Abrechnung** (31.07., 15.12.; danach erlischt der Anspruch): Einsätze müssen bis dahin vollständig erfasst sein. Solange das Forms-Formular parallel läuft, ist unklar, welche Quelle gilt.
- **Vergütungsordnung ist jederzeit änderbar** (Vorstand): Sätze und Regeln dürfen nicht im Code stehen; die Anwesenheitserfassung speichert nur Fakten (Zeiten, Kategorie, Rolle), keine Beträge.
- **Vergütungsordnung uneindeutig:** „Referate Jugend und Leistung“ [ANNAHME: Kinder und Jugend, Leistungssport]; „förderfähige Lizenz“ [ANNAHME: DOSB-lizenzfähig]; Satz für eine eintägige Ausbildungsfahrt [OFFEN] (Finanzen).
- **Trainings nur als Vorschlag:** Fehlende Erfassung ist nicht von „kein Training“ zu unterscheiden; Vollständigkeit liegt bei den Erfassenden.
- **Freitext Probetraining:** nur Vorname, Hinweis in der Oberfläche; Löschung mit dem Einsatz [ANNAHME].
- **Anlegen von Personen aus dem Arbeitseinsatz:** Dublettengefahr; Information nach Art. 13 DSGVO durch die erfassende Person, bestätigt per Pflicht-Häkchen mit gespeicherter Bestätigung (Product Owner 22./24.10.2026); Text und Link der Datenschutzhinweise [OFFEN].
- **Löschfrist:** 5 Jahre (rollen.md) gegenüber gesetzlichen Aufbewahrungsfristen für Abrechnungsgrundlagen; Klärung gemeinsam mit Finanzen.
- **Reihenfolge:** Gruppen (inkl. Trainingszeiten) und die Rechte in der Administration müssen vorher umgesetzt sein.
- **Mobile Nutzung** in Halle oder am Fels mit schwachem Netz: kein Offline-Betrieb, Eingaben dürfen bei Fehlern nicht verloren gehen.
- **Kosten:** keine zusätzlichen [ANNAHME].

**Offene Fragen:**
- [OFFEN] Text und Link der Datenschutzhinweise für das Pflicht-Häkchen beim Anlegen neuer Aktiver aus Arbeitseinsätzen (Product Owner).
- [OFFEN] Löschfrist und Aufbewahrung (gemeinsam mit Finanzen).
- [OFFEN] Eigenes Abrechnungsmodul, das in Finanzen aufgeht? (Struktur und Navigation später)
- Bestätigt (24.10.2026): Kürzel EZ und Ablage bleiben; Rolle vorbelegt und änderbar; Stände „eingetragen / anwesend / nicht erschienen“; Bezeichnungen wie im Forms-Formular; Ausbildungsfahrt = Mehrtageskurs; Warnung bei doppelter Erfassung.

**Folgeänderungen in anderen Dokumenten (ausgeführt):**
- v0.2 bis v0.5 (21.10.2026): siehe Versionen der jeweiligen Dateien.
- v0.6 (22.10.2026): 01-erhebung.md v0.2; modul-landkarte.md v1.5; offene-punkte.md v2.4; uebergabe-rechte-administration.md v1.2; uebergabe-finanzen.md v1.4; uebergabe-ehrenamtsmanagement.md v1.2.
- v0.7 (22.10.2026): 01-erhebung.md v0.3; glossar.md v1.5 (Punkt 7 gestrichen; Tagesausflug, Mehrtagesfahrt, Ausbildungsfahrt, Ort, Kalkulation; Kurs und Tour mit Abgrenzung); modul-landkarte.md v1.6 (Touren und Kurse als Planungstool); offene-punkte.md v2.5; uebergabe-finanzen.md v1.5.
- v0.8 (24.10.2026): 01-erhebung.md v0.4; 02-stories.md v0.4; spec.md v0.2; uebergabe-finanzen.md v1.6; uebergabe-gruppen.md v1.0 (neu); glossar.md v1.6 (Absage); modul-landkarte.md v2.7; offene-punkte.md v4.9.
