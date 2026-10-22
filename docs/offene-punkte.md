# Offene Punkte je Modul: Vereins OS

Stand: 22.10.2026 · Version 2.9
Änderungen v2.9: Spec Anwesenheitserfassung v0.1 (Entwurf) erstellt; Gruppen-Stories v0.7 mit `gr_groups_for_attendance` (US-GR-19 AK8); Annahmen der Spec bei EZ eingetragen.
Änderungen v2.8: Vorschlag der eigenen Gruppe beim Erfassen (US-EZ-19, R18; neue Gruppen-Story US-GR-20 `gr_my_groups`); Gruppe nicht änderbar und Stichtag bei mehrtägigen Einsätzen bestätigt; Orte pflegt nur der Admin.
Änderungen v2.7: Entscheidungen des Product Owners eingetragen: Annahmen der Stories Anwesenheitserfassung bestätigt (EZ 02-stories.md v0.2); A13 Gruppen bestätigt (GR 02-stories.md v0.5); Startliste der Orte gibt der Product Owner bei der Umsetzung mit.
Änderungen v2.6: Übergaben aus der Anwesenheitserfassung an Administration (v1.3) und Gruppen (v1.3) als eingearbeitet gestrichen (spec.md AD v0.8; Gruppen Steckbrief v0.7, Erhebung v0.7, Stories v0.4); daraus folgende offene Punkte und Annahmen bei AD, GR und EZ eingetragen; Stories EZ v0.1 vermerkt.
Änderungen v2.5: Vorstandsbeschluss zu Vergütungsordnung Punkt 7 gestrichen (nicht nötig); Abgrenzung Touren und Kurse (eigenständiges Planungstool mit Kalkulation) zu EZ und FI festgehalten; Glossar-Ergänzungen für EZ erledigt; EZ hat keine Blocker mehr vor der Spec.
Änderungen v2.4: Anwesenheitserfassung: offene Fragen aus der Erhebung beantwortet; Übergaben an AD v1.2, EA v1.2, FI v1.4; Idee Abrechnungsmodul bei FI; Merkposten Erwachsenenfahrten.
Änderungen v2.3: Anwesenheitserfassung: Forms-Formular ausgewertet (01-erhebung.md v0.1); Touren und Kurse übernimmt die Anmeldung von Fahrten; neue FI-Punkte; Übergabe an FI v1.3.

Jeder Abschnitt wird beim Steckbrief des Moduls in „Offene Fragen“ übernommen und dort geklärt. Erledigte Punkte werden hier gestrichen.

## AD – Administration (Priorität 0)

- [OFFEN] Vertretung des Admin-Zugangs: welche:r Mitarbeiter:in der Geschäftsstelle, ab wann? Kein Blocker. (00-steckbrief.md AD)
- [OFFEN] Weg der Migrationen nach PROD: manuell durch den Product Owner oder GitHub Action beim Merge auf main? Vor dem ersten PROD-Deployment. (spec.md AD Abschnitt 11)
- Erledigt 21.10.2026: Nachtrag Personenmodell (spec.md AD v0.7.1) freigegeben; Umsetzung kann mit T33 wieder aufgenommen werden. Verbleibende Annahmen v0.7 in spec.md Abschnitt 11 (bei Abnahme bestätigen).
- [ANNAHME] Annahmen aus spec.md AD v0.6 bei Abnahme bestätigen: Qualifikationsarten lesbar für alle Nutzer mit aktivem Zugang; Gültigkeitsdauer-Änderung ohne Rückwirkung; Sparte und Aussteller als Text mit Vorschlägen; keine Protokollierung von Änderungen an Qualifikationsarten; PSA vorerst historisch.
- Aus dem Nachtrag v0.8 (Anwesenheitserfassung, Übergabe eingearbeitet 22.10.2026):
  - Startbestand der Orte: gibt der Product Owner bei der Umsetzung mit (Migration T51; entschieden 22.10.2026).
  - Pflege der Orte: nur Admin (entschieden 22.10.2026); `ad_can_edit_locations()` bleibt `ad_has_level('AD','edit')`.
  - [OFFEN] Stories für den Nachtrag v0.8 (US-AD-27 ff.) nachziehen oder Abnahme über T56/T58 genügen lassen?
  - [ANNAHME] Annahmen v0.8 bei Abnahme bestätigen (spec.md Abschnitt 11): kein vierter RLS-Pfad, Namen nur über `ea_person_names` und `ea_search_active_persons`; `ez_person_visible` als Platzhalter; Suche nur über Status „aktiv“, ab 2 Zeichen, höchstens 50 Treffer; aus der Anwesenheitserfassung angelegte Personen erhalten genau die Funktion Helfer:in; System-Schlüssel `function` und `contact`; Kennzeichen „Punktekonto Kletterhalle“ am Ort; höchstens 500 IDs je Aufruf.
  - Vorgemerkt für Iteration 1 der Anwesenheitserfassung: Reichweite „Gruppe“ (A6), Rechtevorlage Gruppenleitung (A7). [OFFEN] Eigene Rechtevorlage für Trainer:innen oder dieselbe wie Gruppenleitung?

## EA – Ehrenamtsmanagement (Priorität 1)

Steckbrief: docs/specs/ea-ehrenamt/00-steckbrief.md (Version 0.6, 21.10.2026) · Spaltenzuordnung: migration-aktivenliste.md (Version 0.4) · Qualifikationsarten: stammdaten-qualifikationsarten.md (Version 0.2)

- [OFFEN] Karteileichen (eigenes Tabellenblatt): später migrieren (nur Ausscheiden < 5 Jahre, Status „ausgeschieden“) oder mit der Excel-Liste löschen?
- [OFFEN] DOSB-Lizenz: zusätzlich ein Feld „DOSB-Lizenz gültig bis“ (4 Jahre ab Ausstellung) an der Lizenz führen?
- [OFFEN] Qualifikationsarten mit Klärungsbedarf: PSA, Trainer*in C Mountainbike Guide & Fahrtechnik, Jugendleiter*in (DOSB-Lizenz, Juleica), nicht im Export enthaltene Qualifikationsarten (z. B. DAV-Skibetreuer*in ab 2027). (stammdaten-qualifikationsarten.md Abschnitt 6)
- [OFFEN] Zuordnung Lizenzbezeichnungen der Excel-Liste → Kürzel der Qualifikationsart: wird im Migrationsskript festgelegt (Product Owner, 21.10.2026), nachdem der Product Owner das Tabellenblatt der Aktiven gesichtet hat.
- [OFFEN] Führungszeugnis-Einsicht: Für welche Funktionen ist sie Pflicht? Gibt es weitere Nachweise? (Erneuerung alle 3 Jahre entschieden.)
- [OFFEN] Bedeutung „LE“ (Spalte N), Unterschied „Jahr Kurs-verlängerung“ zu „Letzte FB“ (beide Felder werden zunächst 1:1 übernommen). Hinweis: Die Vergütungsordnung kennt „Lehreinheit“ (1 h, Kurse); prüfen, ob „LE“ das meint.
- [OFFEN] Förderung: Fördergeber und Förderart.
- [OFFEN] Jahreskarte wofür; Forms, Redaktion, Mailingliste: welche Systeme?
- [OFFEN] Amtszeit Jugendausschuss (fehlt in der Aktivenliste).
- [OFFEN] Ist „Mitarbeiter:in Mitgliederverwaltung“ eine ehrenamtliche Funktion oder ein Hauptamt? (glossar.md)
- [OFFEN] Löschlauf nach 5 Jahren: Person ganz löschen oder Stammdaten behalten; Löschung des Zugangs (Supabase-Auth-Eintrag). Später betrachten; Grundsatz aus GR: nur löschen, wenn kein Modul die Person mehr braucht. (rollen.md, spec.md AD Abschnitt 2)
- Hinweis aus AD (v0.7): Das Datenmodell für Ehrenamtsstatus, Referate, Gremien, Lesestufen und Eigenschaftsarten mit Feldern sowie die Funktionen `ea_set_volunteer_status`, `ea_create_volunteer`, `ea_activate_person`, `ea_person_referate` entstehen in AD (spec.md v0.7). EA baut darauf die Oberflächen und legt die System-Eigenschaftsarten an (u. a. Geburtsdatum mit `system_key = 'birth_date'`).
- Hinweis aus AD (v0.8): Die erste EA-Migration legt die System-Eigenschaftsarten Funktion und Kontaktdaten mit `system_key = 'function'` bzw. `'contact'` an [ANNAHME]; `ea_create_volunteer` und `ad_find_similar_persons` nutzen sie für Personen aus der Anwesenheitserfassung.
- **Übergabe aus EZ (offen, v1.2):** specs/ez-einsaetze/uebergabe-ehrenamtsmanagement.md – Aktive aus Arbeitseinsätzen (Status „aktiv“, Funktion Helfer:in mit Bezug Referat); Einsatzhistorie und letzter Einsatz je Person (Iteration 2); Feld „TE pro Woche“ prüfen; Nachweise „Bestätigung steuerfreie Einnahmen“ und „Erklärung zur Ehrenamtspauschale“; förderfähige Lizenz mit Erwerbsdatum; Aktive als Auswahl für die organisierende Person.

## GR – Gruppen (Priorität 2)

- [OFFEN] Welche Daten zu Teilnehmer:innen werden gespeichert (Minderjährige, ggf. Eltern als Kontakt)? (modul-landkarte.md)
- [OFFEN] Nutzen FI und OA Gruppendaten, und welche? (modul-landkarte.md)
- Hinweis aus EA: Gruppenleitungen sollen Kontaktdaten der Aktiven ihrer Gruppe sehen, aber nicht deren Zugehörigkeit zu anderen Gruppen.
- Hinweis aus EA: Spalten „Gruppe“ und „Gruppenleitung“ der Aktivenliste werden im EA-Prüfbericht ausgegeben und mit dem Gruppen-Import übernommen.
- Hinweis aus EA (v0.4): Sichtbarkeit im Ehrenamtsmanagement hängt am Ehrenamtsstatus. Wer in Gruppen als Trainer:in, Helfer:in oder Gruppenleitung eingetragen wird, braucht einen Ehrenamtsstatus [ANNAHME: Gruppen setzt „aktiv“, falls keiner vorhanden].
- Hinweis aus AD (v0.6): Prüfung „Trainer:in braucht gültige Lizenz“ liest die Qualifikationsarten aus AD (ad_qualification_types).
- Hinweis aus AD (v0.7): Die erste GR-Migration ersetzt `gr_person_visible` (Platzhalter, gleiche Signatur), ergänzt `ea_properties.related_group_id` und `ea_property_history.related_group_id`, die Schreibregel R39 und eine Funktion zum Anlegen von Personen mit Gruppenbezug; drei Tests aus der Übergabe laufen erst danach (spec.md AD T45). Übergabe uebergabe-nachtrag-administration.md ist eingearbeitet.
- Hinweis aus EZ (22.10.2026): Gruppen kommt vor der Anwesenheitserfassung; US-GR-19 (`gr_group_roster`, `gr_groups_for_attendance`) und US-GR-20 (`gr_my_groups`, eigene Gruppen für den Vorschlag) müssen vor dem Start der Anwesenheitserfassung fertig sein.
- Aus der Übergabe der Anwesenheitserfassung (eingearbeitet 22.10.2026, 02-stories.md v0.7), vom Product Owner zu bestätigen:
  - [ANNAHME] A11: Import – „gültig von“ der Trainingszeiten = Importdatum; nicht lesbare Trainingszeiten brechen den Import nicht ab.
  - [ANNAHME] A12: Auflösen einer Gruppe beendet ihre offenen Trainingszeiten zum Auflösungsdatum.
  - [ANNAHME] Fehler „Gruppe nicht gefunden.“ bei unbekannter oder am Datum aufgelöster Gruppe (US-GR-19).

## EZ – Anwesenheitserfassung (Priorität 2b – nach Gruppen, vor Finanzen)

Steckbrief: docs/specs/ez-einsaetze/00-steckbrief.md (Version 0.7, abgeschlossen) · Erhebung: 01-erhebung.md (Version 0.3, 22.10.2026) · Stories: 02-stories.md (Version 0.3, 22.10.2026; Training, Fahrten, Wettkampfbegleitung, Arbeitseinsätze) · Spec: spec.md (Version 0.1, Entwurf, 22.10.2026) · Übergaben: uebergabe-rechte-administration.md (v1.3, erledigt), uebergabe-trainingszeiten.md (v1.3, erledigt), uebergabe-ehrenamtsmanagement.md (v1.2, offen), uebergabe-finanzen.md (v1.5, offen)

Keine Blocker vor der Spec. Für Kurs und Tour:
- [OFFEN] Wie wird aus einem im Modul Touren und Kurse geplanten Kurs bzw. einer Tour ein Einsatz (Übernahme oder Anlegen in EZ)? Klärung im Chat Touren und Kurse; bis dahin legt EZ Kurse und Touren selbst an [ANNAHME]. Stories für Kurs, Tour und Trainingslager folgen danach.

Vor Status „Ready“ der Spec zu bestätigen (02-stories.md v0.3, spec.md v0.1 Abschnitt 11):
- [ANNAHME] Wettkampfbegleitung nur mit Gruppe; „alle anwesend“ lässt „nicht erschienen“ unverändert; Probetrainings nicht in der Summe der Kontrollliste; Vorauswahl bei mehreren eigenen Gruppen über den Wochentag der Trainingszeit; Warnung ohne Link bei nicht lesbarem Einsatz; Schutz gegen Doppel-Speichern; Entwurf im Browser nur mit Person-IDs.
- [ANNAHME] aus der Spec: Schreiben nur über Datenbankfunktionen; Referat beim Arbeitseinsatz nicht änderbar; eintägig/mehrtägig änderbar; Gruppenleitung mit Rolle Trainer:in vorbelegt; Probetraining nur beim Training; Teilnehmer:in nur beim Training Pflicht; neue Person erst nach erstem Speichern des Arbeitseinsatzes; nicht aktive Dublettentreffer nicht direkt eintragbar; Liste Standard aktuelles Halbjahr; Mengengerüst; `ez_person_visible` enger als in spec.md AD v0.8.

In der Spec oder später:
- [OFFEN] Information nach Art. 13 DSGVO an Personen, die aus einem Arbeitseinsatz angelegt werden.
- [OFFEN] Löschfrist der Einsätze gegenüber Aufbewahrungsfristen für Abrechnungsgrundlagen (gemeinsam mit FI).
- [ANNAHME] bei der Spec bestätigen: Kürzel EZ und Ablage docs/specs/ez-einsaetze/ bleiben; Rolle vorbelegt aus der Funktion und je Einsatz änderbar; Stände „eingetragen / anwesend / nicht erschienen“; Trainingszeit nur als Vorschlag; Bezeichnungen wie im Forms-Formular; Ausbildungsfahrt = Mehrtageskurs; Warnung bei doppelter Erfassung; Kennzeichen „Punktekonto Kletterhalle“ am Ort.
- Hinweis aus AD (v0.8): Die erste Migration der Anwesenheitserfassung ersetzt `ez_person_visible` (Platzhalter, gleiche Signatur) und setzt `ad_modules.is_available` für EZ erst mit der Freigabe. Namen nur über `ea_person_names`, `ea_search_active_persons` und `gr_group_roster`, nie direkt aus `ea_persons`. Neue Personen beim Arbeitseinsatz über `ad_find_similar_persons` und `ea_create_volunteer` (`created_in = 'EZ'`). Orte über `ad_locations` (nur aktive wählbar).
- Hinweis aus GR (v0.7): `gr_group_roster(group_id, date)` liefert Gruppe, Referat, gültige Trainingszeiten des Wochentags und je Person ID, Vorname, Rufname, Nachname, Rolle (`participant`, `group_lead`, `trainer`, `helper`); eine Person kann mit zwei Rollen erscheinen – EZ entscheidet über die Darstellung.
- Hinweis aus EA: „TE pro Woche“ ist bis dahin ein Feld an der Funktion Trainer:in.

## Touren und Kurse (neu, Idee; Arbeitstitel [ANNAHME])

- [OFFEN] Steckbrief in eigenem Chat (Product Owner, 21.10.2026). Vom Referat Touren angeregt.
- Festgelegt 22.10.2026 (Product Owner): eigenständiges Planungstool für Erstellung, Planung, Kalkulation und Berechnung von Kursen und Touren – u. a. CO2-Berechnung, Deckungsbeitrag, Kosten, Ausgaben, benötigtes Material. Der Product Owner liefert einen HTML-Prototyp (mit Claude erstellt) des Referenten Touren.
- Hinweis aus EZ (21.10.2026): Das Modul übernimmt auch die Anmeldung von Fahrten, einschließlich Kinder- und Jugendfahrten (heute eigenes Forms-Formular des Referats Kinder und Jugend; Screenshots liegen beim Product Owner).
- [OFFEN] Übergang zur Anwesenheitserfassung: Wird ein geplanter Kurs bzw. eine Tour als Einsatz übernommen? Durchführung und Anwesenheit werden in EZ erfasst.
- [OFFEN] Abgrenzung zu Finanzen: Kalkulation (Planung) hier, Vergütung nach der Vergütungsordnung in Finanzen [ANNAHME]; Kostendeckung von Führungstouren (Vergütungsordnung Punkt 9.1).
- [OFFEN] Kürzel, Hauptnutzer, Priorität.

## FI – Finanzen (Priorität 3 – nach der Anwesenheitserfassung)

- [OFFEN] Struktur: Abrechnung als eigenes Modul, das in Finanzen aufgeht? (Idee Product Owner 22.10.2026; mit der Navigation entscheiden)
- [OFFEN] Was ist ein „Vertrag“ im Bereich Kinder und Jugend? Wird er in FI oder GR geführt, hängt er an einer Gruppe? (vision.md, glossar.md, modul-landkarte.md)
- [OFFEN] Richtung des Buchungslaufs (Auszahlung oder Einzug) und Empfänger der Mails. (vision.md)
- [OFFEN] Übergabe: DATEV-Buchungsexport oder SEPA-Datei; Datei-Export oder Schnittstelle über SC? (vision.md, modul-landkarte.md)
- [OFFEN] Aufbewahrungsfristen für Abrechnungsdaten (Steuer, Buchhaltung) gegenüber der 5-Jahres-Regel. (rollen.md)
- [OFFEN] Rundung angebrochener Trainingseinheiten (30 Minuten); Satz der Wettkampfbegleitung je Wettkampf oder je Tag (jetzt auch mehrtägig); halbjährliche Abrechnungsdokumente auch für andere Referate als Kinder und Jugend und Leistungssport?
- [OFFEN] Eintägige Ausbildungsfahrt: Satz der Mehrtageskurse oder der Fahrten; Einsätze nach Abgabe des Halbjahres sperren?
- [OFFEN] Ehrenamtspauschale (Antrag, Vorstandsbeschluss, Vereinbarung, jährliche Erklärung): Abbildung in FI?
- [OFFEN] Abgrenzung zum Modul Touren und Kurse: Kalkulation dort, Vergütung hier [ANNAHME].
- Hinweis aus EA: Bankverbindung der Aktiven und Trainervereinbarung liegen im Ehrenamtsmanagement.
- Hinweis aus EZ: Trainerabrechnung liegt in FI (entschieden 21.10.2026); die Anwesenheitserfassung erhebt und speichert nur. Regeln und Sätze der Übungsleiterpauschale stehen in der Vergütungsordnung (Anhang 1); Sätze pflegbar in FI [ANNAHME]. Abrechnungszeitraum bei Fahrten ab Startort (Reisezeit = Arbeitszeit; kein Vorstandsbeschluss nötig). Zeiten: eintägig Kategorie; mehrtägig Start und Ende mit Datum und Uhrzeit.
- **Übergabe aus EZ (offen, v1.5):** specs/ez-einsaetze/uebergabe-finanzen.md – Datengrundlage aus der Anwesenheitserfassung, Zuordnung Einsatzart → Abrechnungsart, Sätze der Vergütungsordnung, Tages- und Halbtagessätze aus Kategorie bzw. Start und Ende, förderfähige Lizenz, halbjährliche Abrechnung mit Fristen 31.07./15.12., Kontrolle des Punktekontos der Kletterhalle (nur Kinder, je Ort).

## OA – Öffentlichkeitsarbeit (Priorität 4)

- [OFFEN] Gehören Umfragen zu OA? Welcher Umfrage-Dienst? (modul-landkarte.md)
- [OFFEN] Weitere Abhängigkeiten zu anderen Modulen. (modul-landkarte.md)

## SC – Schnittstellen-Connector (spätestens mit OA)

- [OFFEN] API-Key-Verwaltung als Erweiterung von AD: Felder, Anzeige der letzten Zeichen, Erinnerung vor Ablauf per E-Mail. (modul-landkarte.md, 00-steckbrief.md AD)
- Weitere Anforderungen kommen aus EA (E-Mail vor Ablauf einer Qualifikation, Geburtstagserinnerung), FI (DATEV/Sparkasse) und OA (Instagram, Umfragen).

## PM, GS, AM – Projekt-, Geschäftsstellen-, Aufgabenmanagement (Priorität 5)

- [OFFEN] Inhalt, Hauptnutzer und Abgrenzung von PM gegenüber GS. (modul-landkarte.md)
- [OFFEN] Werden Aufgaben nur Nutzern oder auch Personen ohne Login zugewiesen? (modul-landkarte.md)
- [OFFEN] Messgröße für Vision-Ziel Z3 (Aufgaben mit Erinnerungen). (vision.md)

## Übergreifend

- [OFFEN] Zeitpunkt und Umfang des Rollouts sowie Rechte und Reichweiten für weitere Personen mit Amt, Gruppenleitungen und Aktive. Teilweise geklärt: Referent:innen und Hüttenwart:innen im MVP; Reihenfolge der Zugänge (E6, 21.10.2026); Gruppenleitungen und Trainer:innen erhalten Zugang mit Iteration 1 von EZ. (vision.md, rollen.md)
- [OFFEN] Navigation und Modulstruktur (u. a. Finanzen/Abrechnung, Touren und Kurse).
- [OFFEN] Verpflichtungserklärung zum Datenschutz bei der ersten Anmeldung: Text, Versionierung, erneute Bestätigung bei neuer Version (nach MVP; betrifft AD).
- [OFFEN] Weitere Logodateien der Sektion: light negativ Weiß (SVG), classic (SVG), brand (Edelweiß quadratisch) für Favicon und App-Symbol. (marke.md)
- [OFFEN] Themenlogo „DAV …“ für das Vereins OS: gewünscht und mit dem Bundesverband abzustimmen? (marke.md)
- Hinweis: Projektdokumente werden in parallelen Sitzungen bearbeitet. Vor jedem Schreiben neu einlesen und zusammenführen (Glossar wurde am 21.10.2026 zweimal überschrieben und wiederhergestellt).
- Hinweis: Screenshots mit echten Personendaten (z. B. Forms-Formulare mit Namen von Kindern) werden nicht im Projekt oder Repository abgelegt.

## Merkposten nach MVP

- Personenakte / Hinweise an Personen (Zweck, Inhalt, Leserechte, Löschfrist klären; DSGVO Art. 15).
- Einzelrechte, Rechte je Objekt, Reichweiten Gruppe / nur eigene; Rechtevorlage für Gruppenleitungen.
- Frei wählbare Leserechte je Eigenschaftsart und Rechtevorlage (Option B, EA).
- Filter über frei definierte Felder (EA).
- Dashboard (EA).
- Geburtstagserinnerung (EA; Entscheidung, ob Referent:innen Geburtstage sehen; ggf. mit SC).
- Löschen von Personen in der Oberfläche (EA).
- Löschlauf für Personen über alle Module (nur löschen, wenn kein Pfad die Person mehr braucht; A8 der Übergabe GR).
- Bereinigung doppelter Felder aus der Migration, z. B. „Jahr Kursverlängerung“ / „letzte Fortbildung“ (EA).
- E-Mail vor Ablauf einer Qualifikation; konfigurierbares Regelwerk für Ablaufwarnungen (Vorlauf, Stichtag) (EA, mit SC).
- Migration der übrigen ca. 120 Aktiven aus weiteren Listen (EA).
- Befristung der Zuweisung einer Rechtevorlage in der Oberfläche.
- Startkonfiguration der Rechtevorlage Vorstand (Admin konfiguriert in der Oberfläche).
- E-Mail-Benachrichtigung bei Anmeldung des Notfall-Admins (mit SC).
- Einstellungen verwalten (AD).
- Jährlicher Abgleich der Qualifikationsarten mit Ausbildungsstruktur und Fortbildungsregelung des Bundesverbands (Geschäftsstelle; ggf. Aufgabe in AM).
- SSO über den Microsoft-Tenant (Zustimmung und Mitwirkung des Bundesverbands nötig).
- Login für Aktive und Gruppenleitungen.
- Login-Adresse nach der Aktivierung ändern (z. B. Namensänderung).
- Supabase MCP erneut prüfen (OAuth mit projektgebundener URL).
- Sicherheitshinweis in shadcn-CLI (braces) vor Go-live mit `npm audit` prüfen.
- Vorschau-URLs mit Cloudflare Access schützen.
- Bundle-Größe (Chunk > 500 kB) vor Go-live prüfen, ggf. Routen bei Bedarf laden (mobil ab 375 px).
- Startseite: Unterscheidbarkeit der Modul-Einträge (Symbol oder Zweckzeile), spätestens mit dem zweiten Modul.
- GitHub: gemeinsames Konto DAVLeipzig in eine Organisation überführen.
- Erfassung durch Gruppenleitungen und Trainer:innen mit Reichweite „Gruppe“; Ablösung des Forms-Formulars (EZ, Iteration 1; AD vorgemerkt in spec.md v0.8 Abschnitt 11).
- Auswertungen auf Gruppenebene: Auslastung, Bedarf, Anzahl Trainings, Rückspielen an Gruppen; kritische Situationen beim Betreuungsschlüssel visuell darstellen (Alter der Kinder nur intern berechnet, nie Geburtsdatum anzeigen) (EZ, Iteration 2 oder später).
- Erwachsenenfahrten in der Anwesenheitserfassung (gleiche Logik wie Kinder- und Jugendfahrten) (EZ, später).
- Einsatzhistorie und letzter Einsatz je Person im Ehrenamtsmanagement (EA, Iteration 2).
- Einchecken per QR-Code bei Arbeitseinsätzen mit Anlegen neuer Personen durch Spontane (EZ, späte Iteration; öffentliche Seite, DSGVO und Missbrauchsschutz klären).
- Kletterhalle im Vereinszentrum: Erfassung bzw. Kontrolle neu betrachten (EZ, FI).
- Erinnerung vor den Abgabefristen der halbjährlichen Abrechnung (31.07., 15.12.) (FI, ggf. mit SC oder AM).

## Erledigt am 19.10.2026

| Punkt | Entscheidung |
|---|---|
| Spec Kit und `docs/specs/<modul>/` | bestätigt: `docs/specs/<modul>/` führend, Spec Kit erzeugt plan.md und tasks.md |
| Tabellen-Präfix oder Schema | Präfix nach Modulkürzel, kein eigenes Schema |
| Backup PROD | nicht im Scope, Risiko akzeptiert |
| Auftragsverarbeitungsvertrag Cloudflare | schließt der Product Owner ab |
| Zuständig für Datenschutz | Toni Werner |
| Vorstand vs. Geschäftsstelle | unterschiedliche, konfigurierbare Rechtevorlagen; Vorstand grundsätzlich weniger Rechte |
| Zählen bezahlte Trainer:innen als Aktive? | ja, wenn kein Anstellungsverhältnis (Ehrenamt kann vergütet sein; Hauptamt = Anstellung) |
| Nutzer und Person | jeder Zugang hängt an einer Person; AD baut die Grundstruktur des Personenmodells |
| Rechte im MVP | nur Rechtevorlagen je Modul, Reichweite „alle“; Admin hat AD, SC, EA verwalten (am 21.10.2026 ergänzt um Reichweite „Referat“ und Admin „Gruppen lesen“) |
| Startkonfiguration Vorstand (AD) | Vorlage ohne Rechte; Konfiguration durch den Admin nach MVP |
| Erinnerung vor Ablauf eines API-Keys (AD) | verschoben zu SC |
| Schutz vor Aussperren | Notfall-Admin über geschaeftsstelle@dav-leipzig.de; Risiko des gemeinsamen Postfachs akzeptiert |
| Login-Mails | Supabase Auth mit Gmail als SMTP; Einladung nur auf Knopfdruck |
| Login-Adresse bei „eingeladen“ ändern (AD) | nimmt die Einladung zurück; alter Link ungültig |
| Fehlgeschlagene Einladungs-Mail (AD) | ad-invite räumt auf, Status bleibt |
| Abnahme Mail-Abläufe in TEST (AD) | eigene private Adressen des Product Owners; zusätzliche Domain nur in TEST (ad_test_login_domains); Aufräumen im TEST-Dashboard (20.10.2026) |
| Schrift im Vereins OS | Fira Sans (DAV-Vorgabe für den Online-Bereich), selbst gehostet; keine Meta-Webfont-Lizenz nötig (20.10.2026) |

## Erledigt am 21.10.2026 (Steckbrief EA)

| Punkt | Entscheidung |
|---|---|
| Kann jemand Trainer:in ohne Lizenz sein? | nein; ohne Lizenz heißt die Funktion Helfer:in |
| Ist „Bereich“ nötig? | ersetzt durch „Referat“ (7 Referate); dazu „Gremium“ (4 Gremien, Sicht nur lesen) |
| Excel-Import | keine Import-Funktion; einmalige Migration per Skript (von Claude Code vorbereitet), wiederverwendbar; Zusammenführen entfällt im MVP |
| Einsätze in EA | nicht im MVP; eigenes Modul (seit 21.10.2026 Anwesenheitserfassung) |
| Referent:innen im MVP | ja, Rechtevorlage Referent:in mit Reichweite „Referat“, lesen und bearbeiten, Personen anlegen; Hüttenwart:innen ebenso |
| Zuordnung zum Referat | über Funktion bzw. Amt mit Bezug auf das Referat |
| Gremium-Sichten | nur Geschäftsstelle und Admin, nicht Referent:innen |
| Personen ohne Referat | nur Geschäftsstelle und Admin |
| Löschen in der Oberfläche | nicht im MVP |
| Leserechte je Eigenschaftsart | drei feste Lesestufen im MVP (Option A); frei wählbar später |
| Ablaufwarnung | nur Anzeige im System: ≤ 3 Monate vor Ablauf, Stichtagsliste 1. Oktober, jederzeit abrufbar; E-Mail später über SC |
| Weiterbildungen | haben ein Ablaufdatum, wenn die Qualifikationsart eine Gültigkeitsdauer hat; Gültigkeitsdauer je Qualifikationsart (Werte am 21.10.2026 korrigiert: Trainer C und B 4 Jahre, Trainer A 2 Jahre) |
| Dashboard EA | nicht im MVP |
| Zieltermin EA | nicht Teil des Steckbriefs |
| Verpflichtungserklärung bei Erstanmeldung | nicht im MVP, offen für später |
| Information der Aktiven (Art. 13 DSGVO) | geklärt durch Product Owner |
| Spaltenüberschriften Aktivenliste | geliefert; Zuordnung in migration-aktivenliste.md |
| Ausweis in der Aktivenliste | Trainer- und Jugendleiterausweis, kein Personalausweis; Ausweisnummer und „Kopie liegt vor“ (ja/nein) |
| Eigenschaftsart mit mehreren Feldern | ja, als Nachtrag in die Administration |
| Förderung | Jahreseintrag: Förderung für die Person beantragt ja/nein |
| Spalte „Anmerkung“ | wird nicht migriert |
| „Jahr Kurs-verlängerung“ / „Letzte FB“ | beide 1:1 übernehmen, später bereinigen |
| Aktiv / ausgeschieden | eigener Ehrenamtsstatus: aktiv, ruhend, ausgeschieden; Ausgeschiedene nicht in der Übersicht |
| Zweck Geburtsdatum und Geschlecht | Lizenzanträge, korrekte Ansprache; Geburtstagserinnerung später |
| Lizenznummer | je Lizenz eine eigene Nummer |
| Begriff „ruhend“ | bestätigt |
| Wer setzt den Ehrenamtsstatus? | Geschäftsstelle, Admin und Referent:innen (alle drei Status) für Personen ihres Referats; Wirkung für die ganze Person |
| Rückkehr Ausgeschiedener | Status wieder auf „aktiv“, keine neue Person |
| Karteileichen | stehen auf eigenem Tabellenblatt; nicht Teil der Migration der Aktivenliste |

## Erledigt am 21.10.2026 (Qualifikationsarten, AD v0.6)

| Punkt | Entscheidung |
|---|---|
| Liste der Qualifikationsarten | geliefert: 47 Einträge aus den Exporten des Bundesverbands, ergänzt um Fortbildungsintervalle (stammdaten-qualifikationsarten.md v0.2) |
| Wo werden Qualifikationsarten gepflegt? | als Stammdaten in der Administration (US-AD-17 bis US-AD-19); EA und spätere Module greifen per Verweis darauf zu |
| Wer pflegt Qualifikationsarten? | Admin und Geschäftsstelle; die Geschäftsstelle über „EA verwalten“ ohne Rechte auf AD |
| Begriff für Klettersport, Bergsport Sommer usw. | „Sparte“: Klassifizierung des Bundesverbands nur für Qualifikationsarten, kein Bezug zu Referaten |
| Historische Qualifikationsarten | werden angelegt, sind nicht neu vergebbar; Altbestand bleibt |
| Gültigkeitsdauer: nach x Jahren oder zum Jahresende? | zum 31.12. des Jahres „letzte Aus- bzw. Fortbildung + Gültigkeitsdauer“ nach Fortbildungsregelung des Bundesverbands [ANNAHME] |
| Definition Aufbaumodul | fachsportliche JDAV-Schulung für Jugendleiter:innen (glossar.md v1.1) |

## Erledigt am 21.10.2026 (Nachtrag Personenmodell, AD v0.7)

| Punkt | Entscheidung |
|---|---|
| Nachtrag aus EA (Referent:in, Reichweite Referat, Lesestufen, Felder, Kategorie, Rufname, Ehrenamtsstatus, Dublettenwarnung) | eingearbeitet in spec.md AD v0.7, 02-stories.md v0.8 (US-AD-20 bis US-AD-26), rollen.md v0.8, Steckbrief AD v1.1; Freigabe offen (siehe AD) |
| Nachtrag aus GR (Übergabe v1.0: E1–E6, A1–A8, Tests) | eingearbeitet; Sichtbarkeit je Pfad AD/EA/GR, Admin „Gruppen lesen“, Anlegen durch GR, Bezug Gruppe durch die erste GR-Migration |
| Gemeinsame Personen-Tabelle | ja (E1) |
| Wer erscheint in AD, EA, GR? | AD (Admin): alle Personen (ersetzt E2, 21.10.2026); EA: Ehrenamtsstatus; GR: Gruppenbezug (E3, E4) |
| Erneuerung Führungszeugnis-Einsicht | alle 3 Jahre (Product Owner, 21.10.2026); Markierung „läuft ab“ analog zu Qualifikationen [ANNAHME] |
| Gruppen-Doku an „Admin sieht alle“ angepasst | erledigt (Steckbrief GR v0.6, Übergabe) |
| Freigabe Nachtrag | freigegeben; Übernahme von Personen durch Referent:innen erlaubt; Lesestufe „nur Geschäftsstelle und Admin“ = „verwalten“ im Modul |
| Admin und Gruppen | Startwert „Gruppen lesen“ (E5) |
| Reihenfolge der Zugänge | Referent:innen und Vorstand, dann Gruppenleitungen, dann Stellvertretungen und weitere Trainer:innen; nie Erziehungsberechtigte und Teilnehmer:innen (E6) |

## Erledigt am 21.10.2026 (Steckbrief EZ)

| Punkt | Entscheidung |
|---|---|
| Trainerabrechnung: FI, EZ oder eigenes Modul? | Finanzen; die Anwesenheitserfassung erhebt und speichert nur |
| Ist eine Person mit nur einem Einsatz Aktive:r? | ja; neu angelegte Personen aus Arbeitseinsätzen erhalten Ehrenamtsstatus „aktiv“ (Gewinnung für weitere Mitarbeit) |
| Veranstaltungen und Projektteams | Europacup, Bergfilmfestival als Arbeitseinsätze eines Referats; keine eigenen Rechte für Projektteams |
| Abgrenzung zu Gruppen | Trainingszeiten und Gruppen in GR; Einsätze, Ausfahrten und Anwesenheit in EZ |
| Zugang für Gruppenleitungen und Trainer:innen | nicht im MVP; Iteration 1 (Reichweite „Gruppe“) |
| Wer liest Einsätze? | Geschäftsstelle alle; Referent:innen nur ihr Referat bzw. die Gruppen ihres Referats; Vorstand alle (Admin vergibt); Admin lesen |
| Auswertungen | MVP einfache Listen; Gruppenebene Iteration 2; Einsatzhistorie je Person im EA, Iteration 2 |
| Probetraining | Freitext, nur Vorname |
| Vertretung in einer anderen Gruppe | Trainer:innen anderer Gruppen in die Anwesenheit hinzufügbar |
| Dauer | je Einsatz; Trainings mit Beginn und Ende aus den Trainingszeiten der Gruppe; Abrechnung in FI |
| Kletterhalle | nur Kontrolle des Punktekontos bzw. der Rechnungen über die Anwesenheit der Kinder; Trainer:innen werden nicht abgebucht |
| Offline-Erfassung | nicht nötig; Hinweis bei fehlgeschlagenem Senden |
| QR-Code-Check-in | späte Iteration |
| Nicht im Scope | Abrechnung, Freigabe von Ausfahrten, Anmeldung durch Erziehungsberechtigte, Altdaten aus der Forms-Excel, Abschalttermin des Forms-Formulars, Ausfallzeiten (Ferien) |

## Erledigt am 21.10.2026 (Vergütungsordnung)

| Punkt | Entscheidung / Quelle |
|---|---|
| Berechnungsregel Trainingseinheit | 1 Trainingseinheit = 30 Minuten (Vergütungsordnung); Beispiel 2 Stunden = 4 TE stimmig; die Angabe 55 Minuten war falsch |
| Tabelle der Sätze | geliefert: Anhang 1 der Vergütungsordnung (Trainingseinheit, Fahrten, Wettkampfbegleitung, Kurse, Mehrtageskurse/Führungstouren/Trainingslager); in uebergabe-finanzen.md übernommen |
| Übungsleiterpauschale: Regeln und Umfang | Vergütungsordnung: Abrechnungsarten, Trainer:in vs. Helfer:in, förderfähige Lizenz, Bestätigung vor erster Zahlung, halbjährliche Abrechnung mit Fristen |
| Rolle je Anwesenheit | Trainer:in oder Helfer:in wird je Einsatz erfasst, weil die Sätze sich unterscheiden |
| Begriff „Tour“ | eigener Begriff (Gemeinschafts- und Führungstour im Tourenprogramm), nicht mehr Synonym für Ausfahrt |

## Erledigt am 21.10.2026 (Abschluss Steckbrief Anwesenheitserfassung)

| Punkt | Entscheidung |
|---|---|
| Modulname | „Anwesenheitserfassung“ (statt „Einsätze“ bzw. „Einsatzerhebung“) |
| Kurse, Touren, Mehrtageskurse, Trainingslager | werden in der Anwesenheitserfassung erfasst (Durchführung und Anwesenheit) |
| Betreuungsschlüssel | kein Hinweis bei der Erfassung; kritische Situationen in späterer Auswertung visuell |
| Abrechnungszeitraum bei Fahrten | immer ab Startort, An- und Abreise zählen (Reisezeit = Arbeitszeit) |
| Abschalttermin Forms-Formular | nicht im Scope |
| Ausfallzeiten (Ferien) in Einsatzserien | nicht im Scope; nicht erfasste Termine sind keine Trainings |
| Trainer:innen beim Punktekonto | werden nicht abgebucht |
| Admin liest Anwesenheitserfassung | ja |

## Erledigt am 21.10.2026 (Forms-Formular, Erhebung EZ v0.1)

| Punkt | Entscheidung |
|---|---|
| Screenshots des Forms-Formulars | geliefert und in 01-erhebung.md ausgewertet; nicht im Projekt abgelegt (echte Namen) |
| Braucht ein Training einen Ort? | ja, Auswahlliste wie im heutigen Formular |
| Zeiten bei Fahrten | wie heute: eintägig Kategorie unter / mindestens 8 Stunden; mehrtägig Startdatum, Beginn, Enddatum |
| Ausbildungsfahrt | ein- oder mehrtägig, gleiche Abfrage wie Fahrten |
| Bemerkungsfeld | wird übernommen, mit Hinweis (keine sensiblen Angaben über Kinder) |
| Anmeldung von Fahrten | nicht in der Anwesenheitserfassung; gehört ins Modul Touren und Kurse, auch Kinder- und Jugendfahrten |

## Erledigt am 22.10.2026 (Erhebung EZ v0.2 und v0.3)

| Punkt | Entscheidung |
|---|---|
| Ortsliste | Stammdaten in der Administration, gepflegt vom Admin |
| Enduhrzeit bei mehrtägigen Einsätzen | wird erfasst (Pflicht) |
| Wettkampfbegleitung | ein- oder mehrtägig |
| Organisierende Person | Auswahl aus allen Aktiven mit Suche; bei gewählter Gruppe deren Personen zuerst |
| Erfassung von Gruppen-Einsätzen | immer je Gruppe |
| Anzeige der Kinder | Vor- (bzw. Ruf-) und Nachname |
| Erwachsenenfahrten | nicht im Scope; später mit gleicher Logik |
| Reihenfolge | Gruppen → Anwesenheitserfassung → Finanzen |
| Vorstandsbeschluss zu Vergütungsordnung Punkt 7 | nicht nötig; die angenommene Abweichung war eine Fehlinterpretation (Product Owner); Reisezeit = Arbeitszeit gilt |
| Abgrenzung Touren und Kurse | eigenständiges Planungstool (Erstellung, Planung, Kalkulation inkl. CO2, Deckungsbeitrag, Material); Durchführung und Anwesenheit in EZ |
| Glossar-Ergänzungen EZ | Tagesausflug, Mehrtagesfahrt, Ausbildungsfahrt, Ort, Kalkulation (glossar.md v1.5) |

## Erledigt am 22.10.2026 (Übergaben aus EZ an Administration und Gruppen)

| Punkt | Entscheidung / Verbleib |
|---|---|
| Übergabe Rechte, Personen, Orte (uebergabe-rechte-administration.md v1.3) | eingearbeitet in spec.md AD v0.8: Modul EZ in `ad_modules`, Startwerte (Admin lesen, Geschäftsstelle verwalten, Referent:in bearbeiten mit Reichweite Referat, Vorstand ohne), Reichweite „Referat“ für EA und EZ (R30), Namensfunktionen statt viertem RLS-Pfad (R44), Anlegen von Helfer:innen aus Arbeitseinsätzen (R45), Stammdaten Orte `ad_locations` (R43), Tasks T50–T58; Reichweite „Gruppe“ und Vorlage Gruppenleitung für Iteration 1 vorgemerkt |
| Übergabe Trainingszeiten und Lesezugriff (uebergabe-trainingszeiten.md v1.3) | eingearbeitet in Gruppen: Steckbrief v0.7, Erhebung v0.7 (Tabelle `gr_training_times`, B10, B11, R18–R20), Stories v0.4 (US-GR-18 Trainingszeiten pflegen, US-GR-19 Anwesenheitsliste) |
| Lesezugriff der Anwesenheitserfassung auf Gruppen | über `gr_group_roster(group_id, date)` mit Stichtag; nur Namen und Rollen; kein Recht auf Gruppen nötig; Fehlercode `GR_ROSTER_FORBIDDEN` |
| Einarbeitung direkt aus dem Chat Anwesenheitserfassung | auf Wunsch des Product Owners (22.10.2026), Ausnahme von der Regel „Dokumente anderer Module nicht direkt ändern“ |
| Annahmen Stories Anwesenheitserfassung (v0.1) | bestätigt: Löschen nur Geschäftsstelle; Einsatzart nicht änderbar; Standardrolle Helfer:in beim Arbeitseinsatz; keine organisierende Person bei der Wettkampfbegleitung; Stichtag für Teilnehmer:innen und Trainer:innen; Feldlängen Titel 60, Probetraining 30, Bemerkung 500 Zeichen (EZ 02-stories.md v0.2) |
| Korrektur von Trainingszeiten (Gruppen A13) | keine eigene Korrekturfunktion; Trainingszeiten werden fest in Gruppen gepflegt, Änderungen nur über „Ändern ab“ oder „Beenden“ (GR 02-stories.md v0.5) |
| Startbestand der Orte | gibt der Product Owner bei der Umsetzung mit (Migration der Administration, T51) |
| Gruppe eines Einsatzes ändern | nicht änderbar, wie die Einsatzart |
| Stichtag bei mehrtägigen Einsätzen | Startdatum |
| Pflege der Orte | nur Admin |
| Vorschlag der eigenen Gruppe | wer selbst Gruppenleitung, Trainer:in oder Helfer:in ist, bekommt seine Gruppe vorbelegt; der Vorschlag gibt keine zusätzlichen Rechte (US-EZ-19, R18; Gruppen US-GR-20) |
