# Steckbrief: Finanzen

Stand: 25.10.2026 · Version 0.2 · Kürzel: FI · Priorität: 3 – nach der Anwesenheitserfassung · Ablage: docs/specs/fi-finanzen/ · Status: Entwurf, MVP-Schnitt bestätigt (Product Owner 24.10.2026)
Grundlage: vision.md v0.4, modul-landkarte.md v2.8, rollen.md v1.1, glossar.md v1.6, offene-punkte.md v5.5, querschnitt-administration.md v0.1 (P1, P3, P6, P7, P11–P17, Q4–Q6, Q9), arbeitsplan.md v0.3 (Schritt 10), specs/ez-einsaetze/uebergabe-finanzen.md v1.6 (F1–F9), specs/tk-touren-kurse/uebergabe-finanzen.md v1.3 (Punkte 1–7), specs/ez-einsaetze/spec.md v0.5 (Abschnitte 2 und 7), specs/ad-administration/spec.md v0.9 (Nachtrag v0.9, Sätze und Pauschalen), specs/ea-ehrenamt/spec.md v0.2.1 und 01-erhebung.md v0.5 (C2 Nr. 5, 9, 15, 16)
Änderungen v0.2: Offene Fragen mit dem Product Owner geklärt (25.10.2026): Vier-Augen-Prinzip – Referent:in bestätigt die Abrechnungen ihres Referats, die Geschäftsstelle gibt frei; damit Referent:innen schon im MVP Nutzer von Finanzen (Reichweite „Referat“, ohne Bankdaten; ändert Q9); Trainervereinbarung ist Voraussetzung der Auszahlung; Training ohne Trainingszeit 0 TE mit Hinweis; eintägige Ausbildungsfahrt mit Sätzen der Mehrtageskurse; Abrechnungsart wählt, wer den Einsatz anlegen darf.
Änderungen v0.1: Erster Entwurf. Q4, Q5, Q6, Q9 und P7 entschieden; MVP-Schnitt bestätigt; Übergaben der Anwesenheitserfassung (v1.6) und der Planungshilfe Touren und Kurse (v1.3) eingearbeitet; Fachfragen zu Trainingseinheiten, Wettkampfbetreuung, mehrtägigen Einsätzen, Lizenz, Sperre, Ehrenamtspauschale, Auszahlung, Reisekosten entschieden (Product Owner 24.10.2026).

**Problem heute:**
Trainer:innen und Helfer:innen werden aus der großen Excel-Tabelle des Microsoft-Forms-Formulars „Anwesenheitserfassung – Jugend“ von Hand abgerechnet: Trainingseinheiten zählen, Tages- und Halbtagessätze bestimmen, Lizenzen und Nachweise in der Aktivenliste nachschlagen, halbjährliche Abrechnungsdokumente erstellen und daraus Überweisungen vorbereiten. Beispiel: Für das 2. Halbjahr muss die Geschäftsstelle für jede Trainerin der Referate Kinder und Jugend und Leistungssport alle Trainings und Fahrten zusammensuchen, prüfen, ob die Lizenz förderfähig war und die Bestätigung steuerfreie Einnahmen vorliegt, und das Dokument bis 15.12. zur Unterschrift bringen. Die Rechnungen der Kletterhalle (Punktekonto) werden ohne verlässliche Zählung der anwesenden Kinder geprüft. Der monatliche Buchungslauf für Verträge dauert ca. 30 Minuten und wird manuell erstellt (später).

**Ziel / Erfolgsmessung:**
- MVP: Die halbjährliche Abrechnung der Referate Kinder und Jugend und Leistungssport entsteht vollständig aus der Anwesenheitserfassung, ohne Übertragung aus Excel: Abrechnung je Person mit Positionen, Hinweisen (Lizenz, Nachweis, Höchstbetrag, fehlende Zeiten), Abrechnungsdokument zur Unterschrift und SEPA-Überweisungsdatei. Messgröße: Aufwand je Abrechnungshalbjahr [OFFEN: heutiger Aufwand, Zielwert; Vorschlag: höchstens 2 Stunden für alle Personen eines Halbjahres].
- MVP: Abgleich des Punktekontos der Kletterhalle je Rechnung in wenigen Minuten (Anzahl anwesender Kinder je Ort und Zeitraum gegen die Rechnung) [ANNAHME: Messgröße unter 10 Minuten je Rechnung].
- Später (Vision Z2): Monatlicher Buchungslauf für Verträge von ca. 30 Minuten auf ca. 1 Minute.

**Nutzer & Rechtevorlagen:**
- Geschäftsstelle – FI verwalten (Reichweite „alle“): Abrechnungen erstellen, korrigieren, nach Bestätigung freigeben, Abgabe und Verfall erfassen, Überweisungsdatei erzeugen, Abgleich Kletterhalle.
- Referent:in – FI mit Reichweite „Referat“ und Aktion „freigeben“ (Q1) [ANNAHME: Stufe „lesen“ plus „freigeben“; Umsetzung in der Administration]: Abrechnungen ihres Referats (nur Positionen des eigenen Referats) ansehen, Ausnahme (Lizenz) begründen, als sachlich richtig **bestätigen** (Vier-Augen-Prinzip, Product Owner 25.10.2026). Keine Bankverbindung, keine Überweisungsdatei, keine Beträge aus anderen Referaten. Im MVP wirksam für Kinder und Jugend und Leistungssport. Q9 damit geändert: MVP-Nutzer sind Geschäftsstelle und Referent:innen.
- Admin – kein Zugriff auf Finanzen (rollen.md); pflegt in der Administration die Sätze, die Abrechnungsarten mit Vorbelegung je Einsatzart, den steuerfreien Höchstbetrag und die Abgabefristen (Product Owner 24.10.2026, Q6).
- Vorstand – startet ohne Rechte (rollen.md).
- Nach dem MVP: Schatzmeister:in und Kassenprüfung als eigene Rechtevorlagen (FI lesen), Zeitpunkt mit dem Rollout; Trainer:innen mit Reichweite „nur eigene“ (Querschnitt P3) [OFFEN: ob und wann].
- Struktur (Q5, Product Owner 24.10.2026): **ein Modul FI**; die Abrechnung ist ein Bereich von Finanzen, kein eigenes Modul. Präfix `fi_`. Spätere Bereiche (Buchungslauf, Budget) im selben Modul.

**Im Scope (MVP):**
- **Halbjährliche Abrechnung** (Abrechnungshalbjahr) für die Referate Kinder und Jugend und Leistungssport (Product Owner 24.10.2026): Grundlage sind nicht abgesagte Einsätze mit Vergütung, Anwesenheit „anwesend“ und Rolle Trainer:in oder Helfer:in aus der Anwesenheitserfassung (F1). Einsatzarten: Training, Tagesausflug, Mehrtagesfahrt, Ausbildungsfahrt, Trainingslager, Wettkampfbetreuung.
- **Abrechnungsart je Einsatz** (Product Owner 24.10.2026): Die Tabelle aus Anhang 1 der Vergütungsordnung (Abrechnungsarten mit Positionen und Sätzen je Rolle) liegt als Stammdaten in der Administration, mit „gültig ab“. Je Einsatzart (eintägig/mehrtägig) ist eine Abrechnungsart vorbelegt oder „keine Vergütung“; beim Anlegen eines Einsatzes in der Anwesenheitserfassung wird gewählt, welche Abrechnungsart gilt bzw. ob eine Vergütung vorgesehen ist. Finanzen rechnet nach der Abrechnungsart des Einsatzes ab (F2, F3; Übergaben an Administration und Anwesenheitserfassung).
- **Berechnung:**
  - Training: Trainingseinheiten aus der Trainingszeit der Gruppe am Wochentag des Datums (Modul Gruppen); angebrochene Trainingseinheiten werden **aufgerundet** (75 Minuten = 3 TE; Product Owner 24.10.2026).
  - Eintägige Einsätze: Tages- bzw. Halbtagessatz aus der Dauer-Kategorie (F4).
  - Mehrtägige Einsätze: erster Tag ab Beginn bis 24:00, letzter Tag ab 0:00 bis Ende, Zwischentage als Tagessatz, unter 8 Stunden Halbtagessatz (F4) [ANNAHME: Berechnungsweise, Übergabe EZ v1.6]. Fehlen Beginn oder Ende, gilt der Tag als Tagessatz, mit Hinweis „ohne Uhrzeit“; die Geschäftsstelle kann auf Halbtagessatz korrigieren (Product Owner 24.10.2026).
  - Wettkampfbetreuung: Satz **je Kalendertag** des Einsatzes, unabhängig von Stunden (Product Owner 24.10.2026).
  - Organisationspauschale je Tag für die organisierende Person, wo die Abrechnungsart sie vorsieht (Fahrten, Mehrtageskurse/Trainingslager).
  - Satzstand: Sätze gültig am Datum (mehrtägig: Startdatum) des Einsatzes [ANNAHME].
- **Satz Trainer:in nur mit förderfähiger Lizenz** (F5, TK Punkt 5; Product Owner 24.10.2026: beide Regeln kombiniert): Trainersatz, wenn am Datum (mehrtägig: Startdatum, dann für den ganzen Einsatz) eine förderfähige Lizenz gültig ist **oder** sie im selben Abrechnungshalbjahr erworben wurde (wirkt ab Beginn des Halbjahres). Sonst Satz Helfer:in [ANNAHME, Übergabe EZ F5]. Ausnahme mit Begründung der verantwortlichen Referent:in (erfasst von der Geschäftsstelle). Förderfähig = Qualifikationsart DOSB-lizenzfähig [ANNAHME, spec.md AD v0.9].
- **Training ohne Trainingszeit** am Wochentag: Position mit 0 Trainingseinheiten und Hinweis; die Geschäftsstelle trägt die Menge mit Begründung ein (Product Owner 25.10.2026).
- **Korrektur je Position** mit Begründung (z. B. Halbtag statt Tag, Ausnahme Lizenz, Training ohne Trainingszeit).
- **Hinweise** je Abrechnung: keine Bestätigung steuerfreie Einnahmen für das Jahr, keine Trainervereinbarung, keine Bankverbindung, steuerfreier Höchstbetrag überschritten (F6), Einsatz ohne Uhrzeit, Training ohne Trainingszeit.
- **Bestätigung durch die Referent:in** (Vier-Augen-Prinzip, Product Owner 25.10.2026): Die Referent:in bestätigt die Positionen ihres Referats als sachlich richtig; betrifft eine Abrechnung mehrere Referate, bestätigt jede zuständige Referent:in ihren Teil [ANNAHME]. Erst danach kann die Geschäftsstelle freigeben.
- **Freigabe und Abrechnungsdokument:** Freigegebene Abrechnung je Person und Halbjahr als Dokument zur Unterschrift (PDF zum Ausdrucken) (F7). Mit der Freigabe werden die abgerechneten Anwesenheiten in der Anwesenheitserfassung gesperrt (Product Owner 24.10.2026); Korrektur nur über Rücknahme der Freigabe in Finanzen.
- **Abgabe und Frist:** Geschäftsstelle trägt „unterschrieben abgegeben am“ ein; Abgabefristen 31.07. (1. Halbjahr) und 15.12. (2. Halbjahr) als Stammdaten der Administration (Q6); danach erlischt der Anspruch (F7).
- **SEPA-Überweisungsdatei** (Product Owner 24.10.2026) für abgegebene Abrechnungen mit Bankverbindung, Bestätigung steuerfreie Einnahmen und Trainervereinbarung (Voraussetzung, Product Owner 25.10.2026); zum Hochladen im Online-Banking der Sparkasse (manuell).
- **Abgleich Punktekonto Kletterhalle** (F8): je Ort mit Kennzeichen „Punktekonto Kletterhalle“ und Zeitraum Anzahl anwesender Teilnehmer:innen (Kinder) aus der Anwesenheitserfassung gegen die Werte der Rechnung; Abweichung sichtbar; Summe mit und ohne Probetrainings getrennt, bis die Geschäftsstelle klärt, ob die Halle Probetrainings abbucht. Keine Namen.
- **Lesepfad Personendaten** (P7, Product Owner 24.10.2026): eigene Lesefunktion mit festen Spalten für Nutzer mit Rechten auf Finanzen (Bankverbindung, Trainervereinbarung, Bestätigung steuerfreie Einnahmen, förderfähige Lizenzen mit gültig von/bis); unabhängig von Rechten auf das Ehrenamtsmanagement (Übergabe an die Administration). Namen über `ea_person_names`, erweitert um Finanzen (Q2).
- Bedienung am Arbeitsplatz der Geschäftsstelle; Listen mobil lesbar ab 375 px (vision.md).

**Iteration 1 (nach dem MVP, bestätigt 24.10.2026):**
- Abrechnung von **Kurs und Tour** als Einzelabrechnung aus der Anwesenheitserfassung (Lehreinheiten, Tage, Organisationspauschale von Hand; Gemeinschaftstour nur Organisationspauschale nach Ziff. 9.2, TK Punkt 7); **Vorbelegung aus der Planungshilfe** (`tk_settlement_draft`, TK Punkt 1), sobald die Planungshilfe umgesetzt ist. Finanzen hängt für den Start nicht von der Planungshilfe ab.
- Einzelabrechnung vergüteter Einsätze **anderer Referate** (z. B. Arbeitseinsatz Bergfilmfestival mit Vergütung).
- **Reisekosten und Kostenerstattung** nach Reisekostenordnung (TK Punkt 2; Sätze `rKm`, `rUe`, `rSH`, `rKSH` in der Administration); Belege bleiben außerhalb (keine Dokumentablage).
- **Kosten bei Absage** (z. B. Stornogebühren der Leitung) als Einzelfall von Hand (TK Punkt 6).
- **Liste „durchgeführt, noch nicht abgerechnet, älter als 4 Wochen“** für Kurs und Tour (TK Punkt 4); E-Mail-Erinnerung erst mit dem Schnittstellen-Connector.

**Nicht im Scope:**
- Monatlicher Buchungslauf für Verträge (Einzug, Modul Gruppen), Budget-Übersicht, Dashboard: später, eigene Iterationen.
- Ehrenamtspauschale (F9): nicht im MVP, später als eigene Abrechnungsart mit Betrag von Hand (Product Owner 24.10.2026); Nachweise liegen im Ehrenamtsmanagement.
- Finanzbuchhaltung, Buchung, DATEV-Buchungsexport (vision.md: Nicht-Ziel; Übergabe an die Finanzbuchhaltung).
- Pflege der Sätze, Abrechnungsarten, Fristen und des Höchstbetrags (Administration, nur Admin).
- Pflege von Einsätzen und Anwesenheiten (Anwesenheitserfassung, F1); Kalkulation von Kursen und Touren (Planungshilfe).
- Elektronische Unterschrift; Ablage der unterschriebenen Dokumente und Belege im Vereins OS.
- Erwachsenenfahrten (Anwesenheitserfassung: nicht im Scope).
- Förderanträge (Jahreseintrag Förderung im Ehrenamtsmanagement).

**Abhängigkeiten:**
- Administration → FI: Modul FI in `ad_modules` mit Startwerten; Sätze über `ad_rates_at` (vorhanden ab Nachtrag v0.9; fehlende Schlüssel für Trainingseinheit, Fahrten, Wettkampfbetreuung, Höchstbetrag); **neu:** Abrechnungsarten mit Positionen und Vorbelegung je Einsatzart, Abgabefristen, Kennzeichen „halbjährliche Abrechnung“ am Referat, Lesefunktion Personendaten für Finanzen, `ea_person_names` für Finanzen → **uebergabe-administration.md**. Die Sätze (T60, T61) werden mit Finanzen vorgezogen, falls die Planungshilfe später kommt (querschnitt-administration.md 4).
- Anwesenheitserfassung → FI: Einsätze und Anwesenheit mit Rolle (F1), Dauer des Trainings aus der Trainingszeit, Anzahl Kinder je Training und Ort (`ez_climbing_points_report`); **neu:** Abrechnungsart am Einsatz, Lesefunktion für Nutzer mit Rechten auf Finanzen, Sperre abgerechneter Anwesenheiten → **uebergabe-anwesenheitserfassung.md** (Spec EZ v0.5 ist Ready; Nachtrag nötig).
- Ehrenamtsmanagement → FI: Bankverbindung (`bank_account`), Trainervereinbarung (`trainer_agreement`), Bestätigung steuerfreie Einnahmen (`tax_free_confirmation`, Feld „für Jahr“), Lizenz (`license`, gültig von = Erwerb) – gelesen nur über die Lesefunktion der Administration.
- Gruppen → FI: Trainingszeiten (über die Anwesenheitserfassung); Verträge erst mit dem Buchungslauf (später).
- Planungshilfe Touren und Kurse → FI: Vorbelegung `tk_settlement_draft` (Iteration 1); Hinweise zurück → **uebergabe-planungshilfe.md**.
- Extern: Sparkasse (SEPA-Datei, manuell hochgeladen), Finanzbuchhaltung (Belege), Kletterhalle (Rechnung, manuell).

**Risiken / Besonderheiten:**
- Datenschutz: Bankverbindungen und Nachweise sind Lesestufe „nur Geschäftsstelle und Admin“; Lesefunktion mit festen Spalten statt Lesepfad (P7). Referent:innen sehen nur Positionen ihres Referats und Hinweise (z. B. „Nachweis fehlt“), keine Bankdaten und keine Daten der Nachweise selbst [ANNAHME]. Die SEPA-Datei enthält IBANs und wird nur heruntergeladen, nicht gespeichert [ANNAHME]. Abgleich Kletterhalle ohne Namen von Kindern. Eintrag im Verarbeitungsverzeichnis (Trainerabrechnung).
- Aufbewahrung (Q4, Product Owner 24.10.2026): **5 Jahre wie überall** (rollen.md), auch für Abrechnungen und die abgerechneten Einsätze. [ANNAHME] Die steuerlich aufbewahrungspflichtigen Belege (unterschriebenes Abrechnungsdokument, Kontoauszug) liegen in der Finanzbuchhaltung, nicht im Vereins OS. Hinweis: Für Buchungsbelege gelten nach § 147 AO längere Fristen; die Annahme sollte die Schatzmeister:in bestätigen.
- Fachliche Komplexität: Berechnungsregeln (Lizenz, Halbtage, Rundung) müssen mit der Vergütungsordnung übereinstimmen; der Vorstand kann sie jederzeit ändern → Sätze und Zuordnung konfigurierbar, Regeln mit pgTAP-Tests.
- Abhängigkeit von einem Nachtrag der Anwesenheitserfassung (Spec Ready, in Umsetzung): Abrechnungsart am Einsatz und Sperre sollten vor der Abnahme von EZ in TEST feststehen, damit keine Einsätze ohne Abrechnungsart entstehen [ANNAHME: Vorbelegung aus der Einsatzart für Altbestand].
- Kosten: keine (SEPA-Datei statt Bankschnittstelle; kein externer Dienst).
- Steuerliche Einordnung: Vergütung bei Arbeitseinsätzen (z. B. Bergfilmfestival) ist keine Übungsleiterpauschale; Ehrenamtspauschale setzt einen Vorstandsbeschluss voraus [OFFEN].

**Glossar – Vorschläge (Begriffe neu oder zu schärfen, Übernahme durch den Product Owner):**
- **Abrechnungsart:** Art der Vergütung nach Anhang 1 der Vergütungsordnung (Trainingseinheiten; Kinder- und Jugendfahrten/Gruppenfahrten; Wettkampfbetreuung; Kurse; Mehrtageskurse/Führungstouren/Trainingslager; Ehrenamtspauschale später) mit Positionen und Sätzen je Rolle; Stammdaten der Administration; am Einsatz gewählt, vorbelegt aus der Einsatzart. Nicht verwechseln mit: Einsatzart.
- **Position:** einzelne Zeile einer Abrechnung (Einsatz, Rolle, Menge, Satz, Betrag), ggf. mit Korrektur und Begründung.
- **Abrechnungsdokument:** Ausdruck einer freigegebenen Abrechnung je Person und Abrechnungshalbjahr zur Unterschrift; der unterschriebene Ausdruck ist Beleg der Finanzbuchhaltung.
- **Abgabe:** Eingang des unterschriebenen Abrechnungsdokuments in der Geschäftsstelle (Datum); nach der Abgabefrist erlischt der Anspruch.
- **Überweisungsdatei:** SEPA-Datei mit Überweisungen für abgegebene Abrechnungen, zum Hochladen im Online-Banking. Nicht verwechseln mit: Buchungslauf (Einzug für Verträge).
- **Abgleich Punktekonto:** Vergleich der Anzahl anwesender Teilnehmer:innen je Ort und Zeitraum mit der Rechnung der Kletterhalle.
- **Steuerfreier Höchstbetrag:** Jahreshöchstbetrag der Übungsleiterpauschale nach § 3 Nr. 26 EStG; Grenzwert in den Sätzen der Administration.
- **Ausnahme (Lizenz):** Satz Trainer:in ohne förderfähige Lizenz, begründet von der verantwortlichen Referent:in.
- **Kostenerstattung / Reisekosten / Reisekostenordnung:** bisher nur in „Nicht verwechseln mit“; Definition mit Iteration 1.
- **Satz:** Betrag je Einheit aus den Stammdaten „Sätze und Pauschalen“ (bisher ohne eigenen Eintrag).
- Zu prüfen: „Trainingseinheit“ – [ANNAHME: Rundung offen] ersetzen durch „angebrochene Trainingseinheiten werden aufgerundet“; „Wettkampfbetreuung“ – [ANNAHME: Satz je Wettkampf bzw. Tag] ersetzen durch „Satz je Kalendertag“; „Trainer:in“ – Regel „ab dem Abrechnungshalbjahr des Lizenzerwerbs“ um den Stichtag ergänzen; „Abrechnung“ – [OFFEN: ggf. eigenes Abrechnungsmodul] erledigt (Bereich von Finanzen).

**Entschieden 25.10.2026 (Product Owner):** Startwert der Vorbelegung für die eintägige Ausbildungsfahrt = Sätze der Mehrtageskurse; Training ohne Trainingszeit = 0 TE mit Hinweis und Korrektur; Trainervereinbarung ist Voraussetzung der Auszahlung; Vier-Augen-Prinzip mit Bestätigung durch die Referent:in; Abrechnungsart am Einsatz wählt, wer den Einsatz anlegen darf.

**Offene Fragen:**
- [OFFEN] Steuerfreier Höchstbetrag: maßgeblich das Jahr des Einsatzes oder der Auszahlung (Zuflussprinzip)? Wer: Schatzmeister:in, vor der Spec.
- [OFFEN] SEPA: Auftraggeberkonto der Sektion (Ort der Pflege, Vorschlag Administration), Format laut Sparkasse [ANNAHME: pain.001 nach DK-Standard, Version mit der Sparkasse prüfen], Verwendungszweck, Sammelbuchung. Wer: Geschäftsstelle mit Sparkasse.
- [OFFEN] Zählen Probetrainings für die Kletterhalle (werden sie abgebucht)? Wer: Geschäftsstelle.
- [OFFEN] Ausnahme bei fehlender Referent:in (Amt unbesetzt, Abwesenheit vor der Frist): wer bestätigt? Vorschlag: stellvertretende Referent:in mit derselben Vorlage, sonst Geschäftsstelle mit Begründung. Wer: Product Owner.
- [OFFEN] Steuerliche Einordnung einer Vergütung bei Arbeitseinsätzen. Wer: Schatzmeister:in.
- [OFFEN] Zielwert der Erfolgsmessung (heutiger Aufwand je Halbjahr). Wer: Geschäftsstelle.
- [OFFEN] Bestätigung der Annahme zu Q4 (Belege in der Finanzbuchhaltung, 5 Jahre im Vereins OS). Wer: Schatzmeister:in.
- Buchungslauf (später): Übergabeformat (DATEV-Buchungsexport oder SEPA-Datei, Datei oder Schnittstelle über SC) und Empfänger der Mails bleiben offen (offene-punkte.md); Richtung (Einzug) und Vertrag sind im Glossar festgelegt.
