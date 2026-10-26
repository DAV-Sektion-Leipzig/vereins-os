# Steckbrief: Dashboard

Stand: 26.10.2026 · Version 0.1 · Kürzel: DS [ANNAHME] · Priorität: [OFFEN] · Ablage: docs/specs/ds-dashboard/ · Status: Entwurf · Product Owner: Toni Werner
Grundlage: vision.md v0.4, modul-landkarte.md v2.17, rollen.md v1.3, glossar.md, offene-punkte.md v5.15, specs/fi-finanzen/00-steckbrief.md v0.5 (Nicht im Scope: „Budget-Übersicht, Dashboard: später“), specs/gr-gruppen/00-steckbrief.md v0.7 und specs/ez-einsaetze/00-steckbrief.md v0.9 (Auslastung, Betreuungsschlüssel in Iteration 2), specs/tk-touren-kurse/00-steckbrief.md v0.7 (Kosten- und CO2-Auswertung), Prototyp Budget-Dashboard (Übergabe: prototyp-budget-dashboard.md v1.0), Ideenkatalog ideen-sichten.md v0.1.
Änderungen v0.1: Erster Entwurf (Product Owner 26.10.2026): Grundlage ist das Budget-Dashboard des 1. Vorsitzenden (offline, DATEV-Export); darüber Sichten für einzelne Referate, z. B. Auslastung der Gruppen für das Referat Kinder und Jugend.

**Problem heute:**
Der 1. Vorsitzende wertet den Finanzplan mit einem eigenen, offline laufenden Budget-Dashboard aus (eine HTML-Datei, DATEV-Kontenblätter als CSV hineinziehen, Zuordnung Konto → Budgetposten in einer CSV-Datei). Nur er sieht das Ergebnis; Referent:innen erfahren den Stand ihres Budgets auf Nachfrage oder in der Vorstandssitzung als Ausdruck. Kennzahlen aus der Vereinsarbeit (z. B. wie voll eine Gruppe ist, wie viele Trainings stattfanden, welche Lizenzen ablaufen) gibt es heute gar nicht oder nur durch Zählen in Excel-Listen. Beispiel: Das Referat Kinder und Jugend kann nicht sehen, welche Gruppe regelmäßig nur halb besucht ist und welche bei jedem Training voll ist.

**Ziel / Erfolgsmessung:**
- [ANNAHME] MVP: Jede Referent:in sieht nach dem Login den Stand des Budgets ihres Referats (Plan, verbraucht, frei, Datenstand), ohne beim 1. Vorsitzenden nachzufragen. Messgröße: keine Ausdrucke oder Mails mit Budgetständen mehr für Referate.
- [ANNAHME] MVP: Das Budget-Dashboard des 1. Vorsitzenden ist im Vereins OS abgebildet (gleiche Zahlen wie der Prototyp, inkl. Prüfung „Summe je Konto = Kontenübersicht“), die HTML-Datei wird nicht mehr fortgeführt.
- [ANNAHME] Iteration 1: Das Referat Kinder und Jugend sieht je Gruppe die Auslastung und die Anzahl Trainings je Halbjahr, sobald Gruppen und Anwesenheitserfassung in Betrieb sind.
- [OFFEN] Weitere Messgrößen (z. B. Vorbereitung Vorstandssitzung oder Jahresbericht in Minuten).

**Nutzer & Rechtevorlagen:**
- Vorstand – DS lesen, Reichweite „alle“ [ANNAHME]: Gesamtsicht (Budget aller Gesamtbudgets, Kennzahlen aller Referate).
- Referent:in – DS lesen, Reichweite „Referat“ [ANNAHME]: Sicht des eigenen Referats (Budget des Referats, Kennzahlen der eigenen Gruppen und Einsätze).
- Geschäftsstelle – DS verwalten, Reichweite „alle“ [ANNAHME]: alle Sichten; Budget einspielen (DATEV-Export), Zuordnung pflegen [OFFEN: Geschäftsstelle oder nur 1. Vorsitzender/Schatzmeister:in].
- Admin – [OFFEN] kein Zugriff auf Budgetzahlen (wie Finanzen) oder lesen.
- Später: Schatzmeister:in und Kassenprüfung (FI-Vorlagen, Q9), Gruppenleitungen mit Reichweite „Gruppe“ (eigene Gruppe).
- Grundsatz [ANNAHME]: Das Dashboard zeigt **Kennzahlen** (Summen, Anzahlen, Quoten), keine Personenlisten. Wer Details sehen will, springt in das Fachmodul und sieht dort nur, was die Rechte dieses Moduls erlauben. Eine Sicht zeigt eine Kennzahl nur, wenn die Person in der Reichweite der Sicht berechtigt ist.

**Im Scope (MVP) [ANNAHME: Vorschlag, Schnitt mit dem Product Owner klären]:**
- **Budget** (Grundlage: Prototyp Budget-Dashboard): Finanzplan des Jahres (Budgetposten mit Plan, Einnahme/Ausgabe, Gesamtbudget), Zuordnung Konto → Budgetposten mit Historie (ersetzt `zuordnung.csv` und die Versionsdateien), Einspielen des DATEV-Exports (Kontenblätter als CSV), Berechnung Plan / verbraucht / frei je Budgetposten und Gesamtbudget, Ampel (grün < 80 %, gelb 80–100 %, rot > 100 %), Zeitmarke Datenstand, Einnahmen Plan / erreicht / fehlt noch, nicht zugeordnete Buchungen, Prüfung (Summe je Konto = Kontenübersicht; ausgewertet = Ausgaben − Einnahmen + nicht zugeordnet), Umschlüsseln einzelner Buchungen, Druckansicht für die Vorstandssitzung.
- **Sicht je Referat:** Gesamtbudget(s) des Referats mit Budgetposten; Zuordnung Gesamtbudget → Referat als Stammdaten [OFFEN: Gesamtbudgets ohne Referat, z. B. Geschäftsstelle, Vereinszentrum, Bergfilmfestival, sieht nur der Vorstand].
- **Startseite:** Die Sichten ersetzen den Platzhalter der Startseite (Willkommensgrafik, AD) für Nutzer mit DS-Rechten [ANNAHME].
- Mobil lesbar ab 375 px; Druck/PDF der Sicht.

**Iteration 1 (nach dem MVP, sobald die Quellmodule in Betrieb sind) [ANNAHME]:**
- **Referat Kinder und Jugend:** Auslastung der Gruppen (Definition [OFFEN], siehe Offene Fragen), Anzahl Trainings und Absagen je Gruppe und Halbjahr, Betreuungsschlüssel (Anzahl Trainings unterhalb des Schlüssels, Alter nur intern berechnet), Betreuung je Gruppe (Trainer:innen mit gültiger förderfähiger Lizenz, Helfer:innen), Probetrainings je Gruppe, Stand der halbjährlichen Abrechnung (bestätigt / offen, Frist).
- **Leistungssport:** wie Kinder und Jugend, dazu Wettkampfbetreuungen und Trainingslager.
- **Touren und Ausbildung:** Planungen je Status, Kostendeckung, Absagen, „durchgeführt, nicht abgerechnet“, CO2 je Jahr (sobald TK Iteration 1).
- **Verknüpfung Budget ↔ Abrechnung:** abgerechnete, noch nicht gebuchte Vergütung als „gebunden“ am Budgetposten „Vergütung Aktive“.
- Weitere Ideen: ideen-sichten.md.

**Nicht im Scope:**
- Finanzbuchhaltung (vision.md, Nicht-Ziel): Das Dashboard bucht nicht und ändert keine Daten in DATEV.
- Eigene Erfassung von Vereinsdaten: Das Dashboard liest nur aus den Fachmodulen (Ausnahme Budget: Finanzplan, Zuordnung, DATEV-Export [OFFEN: in DS oder in FI]).
- Frei konfigurierbare Diagramme oder Berichte durch Nutzer (Berichtsbaukasten).
- Personenbezogene Ranglisten (z. B. „wer hat die meisten Einsätze“).
- Daten aus Yolawo (Anmeldungen, Teilnehmerzahlen von Kursen und Touren), Mitgliederverwaltung, Hüttenbelegung: nicht im Vereins OS vorhanden.
- Planung des Finanzplans (Haushaltsaufstellung) im Vereins OS: Der Finanzplan kommt weiter aus der Excel-Datei [ANNAHME].

**Abhängigkeiten:**
- AD → Rechte (Modul DS, Reichweite „Referat“), Referate, Startseite; neu: Stammdaten Gesamtbudget ↔ Referat [ANNAHME] (Übergabe an AD nötig).
- FI → Abrechnungen (Stand, Summen je Referat und Halbjahr, ausgezahlt), ggf. Bereich Budget [OFFEN, Q-DS2].
- GR → Gruppen, Teilnahmen zum Stichtag (Anzahl), Verträge (Anzahl, „Teilnahme klären“), Trainingszeiten; nur Anzahlen über Lesefunktionen.
- EZ → Einsätze und Anwesenheit (Anzahlen je Gruppe, Einsatzart, Zeitraum), Absagen, Probetrainings, Betreuungsschlüssel (berechnet).
- EA → Aktive je Referat und Status, Qualifikationen mit Ablaufdatum, fehlende Nachweise (Anzahlen).
- TK → Planungen je Status, Kalkulation, CO2-Bilanz (eingefroren bis zur Einordnung).
- Extern: DATEV-Export (Kontenblätter CSV, manuell), Excel „Finanzen Sektion JJJJ“ (Blatt „Finanzplan JJJJ“, manuell).
- Richtung: Fachmodule liefern Kennzahlen über eigene Lesefunktionen (je Modul, mit dessen Rechten und Reichweite) [ANNAHME]; DS speichert keine Kopien von Personendaten.

**Risiken / Besonderheiten:**
- **Datenschutz Buchungsdaten:** Der Prototyp lässt die Buchungen bewusst nicht vom Rechner (Content-Security-Policy, keine Speicherung). Im Vereins OS liegen sie in Supabase (EU-Region). Buchungstexte enthalten Namen von Personen (Erstattungen, Vergütungen) und Firmen. [OFFEN, Q-DS1]: nur Summen je Konto und Monat speichern oder Einzelbuchungen; wer sieht Einzelbuchungen.
- **Datenschutz Minderjährige:** Kennzahlen zu Gruppen dürfen keine Rückschlüsse auf einzelne Kinder erlauben (z. B. Altersstruktur einer Gruppe mit 6 Kindern). [OFFEN] Mindestgröße für Anzahlen oder nur Kennzahlen ohne Merkmale der Kinder.
- **Abgrenzung zu Finanzen:** Der Steckbrief FI nennt „Budget-Übersicht, Dashboard“ als spätere Iteration von FI. Ein eigenes Modul DS ändert diese Zuordnung (Q-DS2).
- **Zahlen müssen stimmen:** Die Prüfungen des Prototyps (Doppelzählung, Vorzeichen, Saldovorträge, netto/brutto, Regelvorrang) müssen 1:1 übernommen werden; Referenzwerte des Erstexports dienen als Abnahmetest (nicht im Repository, da Finanzzahlen der Sektion; öffentliches Repository).
- **Datenstand:** Die Buchhaltung bucht mit Verzug (Erstexport vom 18.10.2026 bis 30.06.2026). Sichten müssen den Datenstand deutlich zeigen, sonst wirken Budgets zu frei.
- **Leistung:** Kennzahlen über mehrere Jahre und Module sollen ohne Wartezeit laden; ggf. vorberechnete Summen [ANNAHME].
- Kosten: keine (Supabase, Cloudflare kostenfrei).

**Offene Fragen:**
- [OFFEN] Q-DS1 Buchungsdaten: Bleibt der DATEV-Export offline (Prototyp weiter nutzen, Vereins OS übernimmt nur Summen je Budgetposten) oder wird die Buchungsliste im Vereins OS gespeichert? Wenn gespeichert: Sehen Referent:innen die Einzelbuchungen ihres Referats (Datum, Buchungstext, Betrag) oder nur Summen?
- [OFFEN] Q-DS2 Modulzuschnitt: Eigenes Modul Dashboard (DS) mit Bereich Budget, oder Budget als Bereich von Finanzen (wie im Steckbrief FI vorgesehen) und DS nur als Anzeige der Sichten? Vorschlag: Budgetdaten (Finanzplan, Zuordnung, Buchungen) in FI, Sichten in DS.
- [OFFEN] Q-DS3 Auslastung einer Gruppe: Was heißt „Auslastung“? (a) Teilnehmer:innen im Verhältnis zur Platzzahl der Gruppe (Platzzahl gibt es heute nicht in Gruppen; neues Feld nötig), (b) durchschnittlich anwesende Kinder je Training im Verhältnis zu den Teilnehmer:innen zum Stichtag (Anwesenheitsquote), (c) Betreuer:innen im Verhältnis zu den anwesenden Kindern (Betreuungsschlüssel), oder mehrere davon.
- [OFFEN] Q-DS4 MVP-Schnitt und Priorität: Budget zuerst (Daten liegen heute schon vor, unabhängig von GR und EZ) und Referats-Kennzahlen mit Iteration 1? Einordnung in die Reihenfolge AD → EA → GR → EZ → FI.
- [OFFEN] Q-DS5 Welche Referate bekommen welche Sicht? Vorschlag in ideen-sichten.md; Rückmeldung je Referat (Kinder und Jugend, Leistungssport, Klettern, Touren, Ausbildung, Karl-Stein-Hütte, Sulzenauhütte).
- [OFFEN] Q-DS6 Zuordnung Gesamtbudget → Referat: Welche Gesamtbudgets gehören zu welchem Referat? Gesamtbudgets ohne Referat (Geschäftsstelle, Vereinszentrum, Bergfilmfestival …) nur für den Vorstand? Sulzenauhütte hat heute keinen Budgetposten.
- [OFFEN] Q-DS7 Wer spielt den DATEV-Export ein und pflegt die Zuordnung: 1. Vorsitzender, Geschäftsstelle, Schatzmeister:in? Wie oft kommt ein Export (monatlich, quartalsweise)?
- [OFFEN] Q-DS8 Gruppenleitungen: Sollen sie mit Reichweite „Gruppe“ (nach MVP) die Kennzahlen ihrer eigenen Gruppe sehen?
- [OFFEN] Q-DS9 Vergleich mit Vorjahren: Sollen Kennzahlen und Budget mehrere Jahre nebeneinander zeigen (z. B. Trainings je Halbjahr 2026 zu 2027)?
- [OFFEN] Q-DS10 Kürzel „DS“ und Name „Dashboard“ (Oberfläche deutsch: „Übersicht“ oder „Dashboard“?); Begriffe für glossar.md (Sicht, Kennzahl, Budgetposten, Gesamtbudget, Datenstand).
