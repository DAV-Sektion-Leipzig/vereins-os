# Steckbrief: Dashboard

Stand: 26.10.2026 · Version 0.2 · Kürzel: DS [ANNAHME] · Priorität: Budget-Sicht früh (nach dem Kern der Administration), Referats-Kennzahlen nach EZ und FI · Ablage: docs/specs/ds-dashboard/ · Status: Entwurf · Product Owner: Toni Werner
Grundlage: vision.md v0.4, modul-landkarte.md v2.17, rollen.md v1.3, glossar.md, offene-punkte.md v5.15, specs/fi-finanzen/00-steckbrief.md v0.5 (Nicht im Scope: „Budget-Übersicht, Dashboard: später“), specs/gr-gruppen/00-steckbrief.md v0.7 und specs/ez-einsaetze/00-steckbrief.md v0.9 (Auslastung, Betreuungsschlüssel in Iteration 2), specs/tk-touren-kurse/00-steckbrief.md v0.7 (Kosten- und CO2-Auswertung), Prototyp Budget-Dashboard (Übergabe: prototyp-budget-dashboard.md v1.0), Ideenkatalog ideen-sichten.md v0.1.
Änderungen v0.2: Q-DS1 bis Q-DS4 entschieden (Product Owner 26.10.2026): Buchungsliste wird gespeichert, Referent:innen sehen die Einzelbuchungen ihres Referats; Budget ist ein Bereich von Finanzen, das Dashboard zeigt die Sichten (Übergabe an Finanzen: uebergabe-finanzen.md v1.0); Auslastung = Anwesenheitsquote, Betreuungsschlüssel und Probetrainings (keine Platzzahl); Budget-Sicht früh, Referats-Kennzahlen später.
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
- Referent:in – DS lesen, Reichweite „Referat“ [ANNAHME]: Sicht des eigenen Referats (Budget des Referats **mit Einzelbuchungen** der Budgetposten des Referats, Product Owner 26.10.2026; Kennzahlen der eigenen Gruppen und Einsätze).
- Geschäftsstelle – DS verwalten, Reichweite „alle“ [ANNAHME]: alle Sichten; Einspielen des DATEV-Exports und Pflege der Zuordnung geschehen im Bereich Budget von Finanzen (Q-DS2) [OFFEN Q-DS7: wer].
- Admin – [OFFEN] kein Zugriff auf Budgetzahlen (wie Finanzen) oder lesen.
- Später: Schatzmeister:in und Kassenprüfung (FI-Vorlagen, Q9), Gruppenleitungen mit Reichweite „Gruppe“ (eigene Gruppe).
- Grundsatz [ANNAHME]: Das Dashboard zeigt **Kennzahlen** (Summen, Anzahlen, Quoten), keine Personenlisten. Ausnahme: Einzelbuchungen des Budgets (Q-DS1). Wer Details sehen will, springt in das Fachmodul und sieht dort nur, was die Rechte dieses Moduls erlauben. Eine Sicht zeigt eine Kennzahl nur, wenn die Person in der Reichweite der Sicht berechtigt ist.

**Im Scope (MVP) [ANNAHME: Vorschlag, Schnitt mit dem Product Owner klären]:**
- **Budget-Sicht** (Grundlage: Prototyp Budget-Dashboard). Daten, Import und Pflege liegen im **Bereich Budget von Finanzen** (Q-DS2, Product Owner 26.10.2026; Anforderungen: uebergabe-finanzen.md); das Dashboard zeigt sie je Sicht an. Umfang wie im Prototyp: Finanzplan des Jahres (Budgetposten mit Plan, Einnahme/Ausgabe, Gesamtbudget), Zuordnung Konto → Budgetposten mit Historie (ersetzt `zuordnung.csv` und die Versionsdateien), Einspielen des DATEV-Exports (Kontenblätter als CSV), Berechnung Plan / verbraucht / frei je Budgetposten und Gesamtbudget, Ampel (grün < 80 %, gelb 80–100 %, rot > 100 %), Zeitmarke Datenstand, Einnahmen Plan / erreicht / fehlt noch, nicht zugeordnete Buchungen, Prüfung (Summe je Konto = Kontenübersicht; ausgewertet = Ausgaben − Einnahmen + nicht zugeordnet), Umschlüsseln einzelner Buchungen, Druckansicht für die Vorstandssitzung.
- **Sicht je Referat:** Gesamtbudget(s) des Referats mit Budgetposten und Einzelbuchungen (Datum, Konto, Buchungstext, Beleg, Betrag; Q-DS1); Zuordnung Gesamtbudget → Referat als Stammdaten [OFFEN: Gesamtbudgets ohne Referat, z. B. Geschäftsstelle, Vereinszentrum, Bergfilmfestival, sieht nur der Vorstand].
- **Startseite:** Die Sichten ersetzen den Platzhalter der Startseite (Willkommensgrafik, AD) für Nutzer mit DS-Rechten [ANNAHME].
- Mobil lesbar ab 375 px; Druck/PDF der Sicht.

**Iteration 1 (nach dem MVP, sobald die Quellmodule in Betrieb sind) [ANNAHME]:**
- **Referat Kinder und Jugend – Auslastung der Gruppen** (Q-DS3, Product Owner 26.10.2026) aus drei Kennzahlen: (1) **Anwesenheitsquote** = durchschnittlich anwesende Teilnehmer:innen je Training im Verhältnis zu den Teilnehmer:innen der Gruppe zum Datum des Trainings; (2) **Betreuungsschlüssel** = Anzahl Trainings, bei denen die anwesenden Trainer:innen und Helfer:innen unter dem Mindestverhältnis lagen (Alter nur intern berechnet, nie angezeigt); (3) **Probetrainings** je Gruppe und Monat als Zeichen der Nachfrage. Keine Platzzahl in Gruppen. Dazu: Anzahl Trainings und Absagen je Gruppe und Halbjahr, Betreuung je Gruppe (Trainer:innen mit gültiger förderfähiger Lizenz, Helfer:innen), Probetrainings je Gruppe, Stand der halbjährlichen Abrechnung (bestätigt / offen, Frist).
- **Leistungssport:** wie Kinder und Jugend, dazu Wettkampfbetreuungen und Trainingslager.
- **Touren und Ausbildung:** Planungen je Status, Kostendeckung, Absagen, „durchgeführt, nicht abgerechnet“, CO2 je Jahr (sobald TK Iteration 1).
- **Verknüpfung Budget ↔ Abrechnung:** abgerechnete, noch nicht gebuchte Vergütung als „gebunden“ am Budgetposten „Vergütung Aktive“.
- Weitere Ideen: ideen-sichten.md.

**Nicht im Scope:**
- Finanzbuchhaltung (vision.md, Nicht-Ziel): Das Dashboard bucht nicht und ändert keine Daten in DATEV.
- Eigene Erfassung von Vereinsdaten: Das Dashboard liest nur aus den Fachmodulen (Budgetdaten liegen in Finanzen).
- Frei konfigurierbare Diagramme oder Berichte durch Nutzer (Berichtsbaukasten).
- Personenbezogene Ranglisten (z. B. „wer hat die meisten Einsätze“).
- Daten aus Yolawo (Anmeldungen, Teilnehmerzahlen von Kursen und Touren), Mitgliederverwaltung, Hüttenbelegung: nicht im Vereins OS vorhanden.
- Platzzahl bzw. Höchstzahl je Gruppe (Q-DS3).
- Planung des Finanzplans (Haushaltsaufstellung) im Vereins OS: Der Finanzplan kommt weiter aus der Excel-Datei [ANNAHME].

**Abhängigkeiten:**
- AD → Rechte (Modul DS, Reichweite „Referat“), Referate, Startseite; neu: Stammdaten Gesamtbudget ↔ Referat [ANNAHME] (Übergabe an AD nötig).
- FI → Bereich Budget (Finanzplan, Zuordnung, Buchungen, Berechnung Plan/Ist; Übergabe uebergabe-finanzen.md v1.0, offen); Abrechnungen (Stand, Summen je Referat und Halbjahr, ausgezahlt).
- GR → Gruppen, Teilnahmen zum Stichtag (Anzahl), Verträge (Anzahl, „Teilnahme klären“), Trainingszeiten; nur Anzahlen über Lesefunktionen.
- EZ → Einsätze und Anwesenheit (Anzahlen je Gruppe, Einsatzart, Zeitraum), Absagen, Probetrainings, Betreuungsschlüssel (berechnet).
- EA → Aktive je Referat und Status, Qualifikationen mit Ablaufdatum, fehlende Nachweise (Anzahlen).
- TK → Planungen je Status, Kalkulation, CO2-Bilanz (eingefroren bis zur Einordnung).
- Extern (über FI): DATEV-Export (Kontenblätter CSV, manuell), Excel „Finanzen Sektion JJJJ“ (Blatt „Finanzplan JJJJ“, manuell).
- Richtung: Fachmodule liefern Kennzahlen über eigene Lesefunktionen (je Modul, mit dessen Rechten und Reichweite) [ANNAHME]; DS speichert keine Kopien von Personendaten.

**Risiken / Besonderheiten:**
- **Datenschutz Buchungsdaten:** Der Prototyp lässt die Buchungen bewusst nicht vom Rechner (Content-Security-Policy, keine Speicherung). Im Vereins OS liegen sie in Supabase (EU-Region). Buchungstexte enthalten Namen von Personen (Erstattungen, Vergütungen) und Firmen. Entschieden (Q-DS1, Product Owner 26.10.2026): Die Buchungsliste wird gespeichert; Referent:innen sehen die Einzelbuchungen der Budgetposten ihres Referats. Folgen: Eintrag im Verarbeitungsverzeichnis, Löschfrist [OFFEN Q-DS11], nur Zeilen auf zugeordneten Erfolgskonten speichern (keine Bank-, Kreditoren- und Personenkonten) [ANNAHME, datensparsam].
- **Datenschutz Minderjährige:** Kennzahlen zu Gruppen dürfen keine Rückschlüsse auf einzelne Kinder erlauben (z. B. Altersstruktur einer Gruppe mit 6 Kindern). [OFFEN] Mindestgröße für Anzahlen oder nur Kennzahlen ohne Merkmale der Kinder.
- **Abgrenzung zu Finanzen** (Q-DS2, entschieden): Budget ist ein Bereich von FI; die frühe Budget-Sicht zieht diesen Bereich vor die Abrechnung vor. Das setzt die Rechte für FI (Nachtrag AD v0.10, Reichweite „Referat“) früh voraus.
- **Zahlen müssen stimmen:** Die Prüfungen des Prototyps (Doppelzählung, Vorzeichen, Saldovorträge, netto/brutto, Regelvorrang) müssen 1:1 übernommen werden; Referenzwerte des Erstexports dienen als Abnahmetest (nicht im Repository, da Finanzzahlen der Sektion; öffentliches Repository).
- **Datenstand:** Die Buchhaltung bucht mit Verzug (Erstexport vom 18.10.2026 bis 30.06.2026). Sichten müssen den Datenstand deutlich zeigen, sonst wirken Budgets zu frei.
- **Leistung:** Kennzahlen über mehrere Jahre und Module sollen ohne Wartezeit laden; ggf. vorberechnete Summen [ANNAHME].
- Kosten: keine (Supabase, Cloudflare kostenfrei).

**Offene Fragen:**
- Q-DS1 – **entschieden 26.10.2026:** Buchungsliste wird gespeichert; Referent:innen sehen die Einzelbuchungen ihres Referats.
- Q-DS2 – **entschieden 26.10.2026:** Budget (Finanzplan, Zuordnung, Buchungen) ist ein Bereich von Finanzen; das Dashboard zeigt die Sichten und liest aus allen Modulen.
- Q-DS3 – **entschieden 26.10.2026:** Auslastung = Anwesenheitsquote, Betreuungsschlüssel und Probetrainings; keine Platzzahl.
- Q-DS4 – **entschieden 26.10.2026:** Budget-Sicht früh (nach dem Kern der Administration, Daten liegen heute vor), Referats-Kennzahlen nach EZ und FI. [OFFEN] Anpassung des Arbeitsplans (Reihenfolge: Nachtrag AD v0.10 Rechte FI, Bereich Budget FI, DS).
- [OFFEN] Q-DS5 Welche Referate bekommen welche Sicht? Vorschlag in ideen-sichten.md; Rückmeldung je Referat (Kinder und Jugend, Leistungssport, Klettern, Touren, Ausbildung, Karl-Stein-Hütte, Sulzenauhütte).
- [OFFEN] Q-DS6 Zuordnung Gesamtbudget → Referat: Welche Gesamtbudgets gehören zu welchem Referat? Gesamtbudgets ohne Referat (Geschäftsstelle, Vereinszentrum, Bergfilmfestival …) nur für den Vorstand? Sulzenauhütte hat heute keinen Budgetposten.
- [OFFEN] Q-DS7 Wer spielt den DATEV-Export ein und pflegt die Zuordnung: 1. Vorsitzender, Geschäftsstelle, Schatzmeister:in? Wie oft kommt ein Export (monatlich, quartalsweise)?
- [OFFEN] Q-DS8 Gruppenleitungen: Sollen sie mit Reichweite „Gruppe“ (nach MVP) die Kennzahlen ihrer eigenen Gruppe sehen?
- [OFFEN] Q-DS9 Vergleich mit Vorjahren: Sollen Kennzahlen und Budget mehrere Jahre nebeneinander zeigen (z. B. Trainings je Halbjahr 2026 zu 2027)?
- [OFFEN] Q-DS10 Kürzel „DS“ und Name „Dashboard“ (Oberfläche deutsch: „Übersicht“ oder „Dashboard“?); Begriffe für glossar.md (Sicht, Kennzahl, Budgetposten, Gesamtbudget, Datenstand).
- [OFFEN] Q-DS11 Löschfrist der gespeicherten Buchungen (5 Jahre wie überall, oder nur laufendes Jahr und Vorjahr, da die Belege ohnehin in DATEV liegen)?
- [OFFEN] Q-DS12 Recht für die Budget-Sicht: über das Recht auf DS (Sicht) oder über das Recht auf FI (Bereich Budget)? Referent:innen haben FI heute nur zum Bestätigen von Abrechnungen.
- [OFFEN] Q-DS13 Welche Buchungen sieht ein Referat: nur Buchungen der Budgetposten seiner Gesamtbudgets, oder auch nicht zugeordnete Buchungen auf Konten mit seiner Kontenendziffer (z. B. „… 6“ Kinder und Jugend)?
