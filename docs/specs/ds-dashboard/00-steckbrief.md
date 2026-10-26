# Steckbrief: Dashboard

Stand: 26.10.2026 · Version 0.11 · Kürzel: DS [ANNAHME] · Priorität: Budget-Sicht früh (nach dem Kern der Administration), Referats-Kennzahlen nach EZ und FI · Ablage: docs/specs/ds-dashboard/ · Status: Entwurf · Product Owner: Toni Werner
Grundlage: vision.md v0.4, modul-landkarte.md v2.17, rollen.md v1.3, glossar.md, offene-punkte.md v5.15, specs/fi-finanzen/00-steckbrief.md v0.5 (Nicht im Scope: „Budget-Übersicht, Dashboard: später“), specs/gr-gruppen/00-steckbrief.md v0.7 und specs/ez-einsaetze/00-steckbrief.md v0.9 (Auslastung, Betreuungsschlüssel in Iteration 2), specs/tk-touren-kurse/00-steckbrief.md v0.7 (Kosten- und CO2-Auswertung), Prototyp Budget-Dashboard (Übergabe: prototyp-budget-dashboard.md v1.0), Ideenkatalog ideen-sichten.md v0.1.
Änderungen v0.11: Grundsatz (Product Owner 26.10.2026): Referent:innen steuern ihre Gruppen mit dem Dashboard (Entscheidungen anhand der Kennzahlen); Gruppendetail mit Namen und Hinweisen über das Recht auf das Dashboard; Übergabe an Gruppen (uebergabe-gruppen.md v1.0).
Änderungen v0.10: Q-DS5 und Q-DS19 entschieden (Product Owner 26.10.2026): Die Referate geben keine Rückmeldung; Claude legt die Sichten als Referent:in fest (sichten.md v0.4, zur Abnahme); Vorjahresvergleich nur mit dem Vorjahr; Gesamtbudgets ohne Referat bestätigt.
Änderungen v0.9: Q-DS18 entschieden (Product Owner 26.10.2026): Referent:innen schichten den Plan nur um (Summe des Gesamtbudgets bleibt gleich), die Budgetpflege bestätigt.
Änderungen v0.8: Q-DS15 bis Q-DS17 entschieden (Product Owner 26.10.2026): Jede Referent:in sieht das gesamte Budget des Vereins (Summen aller Gesamtbudgets), Einzelbuchungen nur des eigenen Referats; sie pflegt nur ihr eigenes Budget: Hinweise und Plan; Umschlüsseln nur als Vorschlag an die Budgetpflege. Tabelle „Sichtbarkeit der Gesamtbudgets“ wird zu „Gesamtbudgets und Referate“.
Änderungen v0.7: Q-DS6 entschieden (Product Owner 26.10.2026): Gesamtbudgets je Referat; „Veranstaltungen“ und „Fördermittel“ für alle mit „Dashboard lesen“; neue Referate Öffentlichkeitsarbeit und Umwelt und Naturschutz; Sulzenauhütte ohne Budget-Sicht.
Änderungen v0.6: Q-DS9 entschieden (Product Owner 26.10.2026): Vorjahresvergleich für Budget und Kennzahlen.
Änderungen v0.5: Q-DS10 entschieden (Product Owner 26.10.2026): Name in der Oberfläche bleibt „Dashboard“; Begriffe im Glossar v1.7.
Änderungen v0.4: Q-DS8, Q-DS13, Q-DS14 und D5 entschieden (Product Owner 26.10.2026): Budgetpflege über ein Kennzeichen „darf Budget pflegen“; der Admin sieht über „Dashboard lesen“ auch die Budget-Sicht; ein Referat sieht nur Buchungen seiner Budgetposten; Gruppenleitungen später mit Kennzahlen der eigenen Gruppe ohne Budget.
Änderungen v0.3: Q-DS7, Q-DS11, Q-DS12 entschieden (Product Owner 26.10.2026): eigenes Recht „Dashboard lesen“ (Modul DS, Reichweite „Referat“); Einzelbuchungen bleiben laufendes Jahr und Vorjahr, danach nur Summen; Export und Zuordnung pflegt der 1. Vorsitzende, später die Schatzmeister:in, künftig Import über die DATEV-Schnittstelle des Schnittstellen-Connectors; Export monatlich. Übergabe an die Administration (uebergabe-administration.md v1.0); neue Frage Q-DS14.
Änderungen v0.2: Q-DS1 bis Q-DS4 entschieden (Product Owner 26.10.2026): Buchungsliste wird gespeichert, Referent:innen sehen die Einzelbuchungen ihres Referats; Budget ist ein Bereich von Finanzen, das Dashboard zeigt die Sichten (Übergabe an Finanzen: uebergabe-finanzen.md v1.0); Auslastung = Anwesenheitsquote, Betreuungsschlüssel und Probetrainings (keine Platzzahl); Budget-Sicht früh, Referats-Kennzahlen später.
Änderungen v0.1: Erster Entwurf (Product Owner 26.10.2026): Grundlage ist das Budget-Dashboard des 1. Vorsitzenden (offline, DATEV-Export); darüber Sichten für einzelne Referate, z. B. Auslastung der Gruppen für das Referat Kinder und Jugend.

**Problem heute:**
Der 1. Vorsitzende wertet den Finanzplan mit einem eigenen, offline laufenden Budget-Dashboard aus (eine HTML-Datei, DATEV-Kontenblätter als CSV hineinziehen, Zuordnung Konto → Budgetposten in einer CSV-Datei). Nur er sieht das Ergebnis; Referent:innen erfahren den Stand ihres Budgets auf Nachfrage oder in der Vorstandssitzung als Ausdruck. Kennzahlen aus der Vereinsarbeit (z. B. wie voll eine Gruppe ist, wie viele Trainings stattfanden, welche Lizenzen ablaufen) gibt es heute gar nicht oder nur durch Zählen in Excel-Listen. Beispiel: Das Referat Kinder und Jugend kann nicht sehen, welche Gruppe regelmäßig nur halb besucht ist und welche bei jedem Training voll ist.

**Ziel / Erfolgsmessung:**
- Grundsatz (Product Owner 26.10.2026): Referent:innen **steuern ihre Gruppen mit dem Dashboard** – sie erkennen an den Kennzahlen, wo sie eingreifen müssen, und entscheiden (Betreuung, Trainingszeit, neue Gruppe, Zusammenlegen); das Dashboard selbst ändert keine Daten der Fachmodule.
- [ANNAHME] MVP: Jede Referent:in sieht nach dem Login den Stand des gesamten Budgets des Vereins mit ihrem Referat im Detail (Plan, verbraucht, frei, Datenstand; Q-DS15), ohne beim 1. Vorsitzenden nachzufragen. Messgröße: keine Ausdrucke oder Mails mit Budgetständen mehr für Referate.
- [ANNAHME] MVP: Das Budget-Dashboard des 1. Vorsitzenden ist im Vereins OS abgebildet (gleiche Zahlen wie der Prototyp, inkl. Prüfung „Summe je Konto = Kontenübersicht“), die HTML-Datei wird nicht mehr fortgeführt.
- [ANNAHME] Iteration 1: Das Referat Kinder und Jugend sieht je Gruppe die Auslastung und die Anzahl Trainings je Halbjahr, sobald Gruppen und Anwesenheitserfassung in Betrieb sind.
- [OFFEN] Weitere Messgrößen (z. B. Vorbereitung Vorstandssitzung oder Jahresbericht in Minuten).

**Nutzer & Rechtevorlagen:**
- Recht (Q-DS12, Product Owner 26.10.2026): eigenes Modul **DS** in der Administration mit Stufe „lesen“ und Reichweite „alle“ oder „Referat“. Die Sichten lesen die Daten der Fachmodule über Lesefunktionen, die das Recht auf DS prüfen; ein Recht auf DS gibt keine Rechte in den Fachmodulen.
- Vorstand – DS lesen, Reichweite „alle“ [ANNAHME]: Gesamtsicht (Budget aller Gesamtbudgets, Kennzahlen aller Referate).
- Referent:in – DS lesen, Reichweite „Referat“ [ANNAHME]: **gesamtes Budget des Vereins** (Plan / verbraucht / frei aller Gesamtbudgets und Budgetposten, Q-DS15 (Product Owner 26.10.2026)); **Einzelbuchungen nur der Budgetposten des eigenen Referats** (Q-DS13, Q-DS15); **pflegt nur das eigene Budget**: Hinweise und Plan der Budgetposten des eigenen Referats (Q-DS16), Umschlüsseln nur als Vorschlag an die Budgetpflege (Q-DS17); Kennzahlen der eigenen Gruppen und Einsätze.
- Geschäftsstelle – DS lesen, Reichweite „alle“ [ANNAHME]: alle Sichten; pflegt das Budget nicht (Q-DS7).
- Budgetpflege (Q-DS7, Product Owner 26.10.2026): Den DATEV-Export spielt der **1. Vorsitzende** ein und pflegt die Zuordnung, später die **Schatzmeister:in** (eigene Rechtevorlage nach dem MVP); beides im Bereich Budget von Finanzen. Künftig kommt der Export über die **DATEV-Schnittstelle des Schnittstellen-Connectors** (SC) statt als CSV. Recht dafür (Q-DS14, Product Owner 26.10.2026): Kennzeichen **„darf Budget pflegen“** an der Zuweisung, wie „darf freigeben“; es gibt keine Rechte auf Abrechnungen und Bankdaten [ANNAHME: Kennzeichen am Recht auf DS].
- Admin – DS lesen, Reichweite „alle“ (D5, Product Owner 26.10.2026): sieht alle Sichten **einschließlich Budget und Einzelbuchungen**, obwohl der Admin sonst keinen Zugriff auf Finanzen hat. Folge: Auch der Notfall-Admin (Postfach der Geschäftsstelle) sieht die Budget-Sicht [ANNAHME: hingenommen].
- Später: Schatzmeister:in (mit „darf Budget pflegen“) und Kassenprüfung (FI-Vorlagen, Q9); **Gruppenleitungen** mit Reichweite „Gruppe“: Kennzahlen der eigenen Gruppe (Anwesenheitsquote, Trainings, Betreuungsschlüssel, Probetrainings), **ohne Budget und Buchungen** (Q-DS8, Product Owner 26.10.2026).
- Grundsatz [ANNAHME]: Das Dashboard zeigt **Kennzahlen** (Summen, Anzahlen, Quoten), keine Personenlisten. Ausnahmen: Einzelbuchungen des Budgets (Q-DS1) und das Gruppendetail mit Namen und Hinweisen (Product Owner 26.10.2026). Wer Details sehen will, springt in das Fachmodul und sieht dort nur, was die Rechte dieses Moduls erlauben. Eine Sicht zeigt eine Kennzahl nur, wenn die Person in der Reichweite der Sicht berechtigt ist.

**Im Scope (MVP) [ANNAHME: Vorschlag, Schnitt mit dem Product Owner klären]:**
- **Budget-Sicht** (Grundlage: Prototyp Budget-Dashboard). Daten, Import und Pflege liegen im **Bereich Budget von Finanzen** (Q-DS2, Product Owner 26.10.2026; Anforderungen: uebergabe-finanzen.md); das Dashboard zeigt sie je Sicht an. Umfang wie im Prototyp: Finanzplan des Jahres (Budgetposten mit Plan, Einnahme/Ausgabe, Gesamtbudget), Zuordnung Konto → Budgetposten mit Historie (ersetzt `zuordnung.csv` und die Versionsdateien), Einspielen des DATEV-Exports (Kontenblätter als CSV), Berechnung Plan / verbraucht / frei je Budgetposten und Gesamtbudget, Ampel (grün < 80 %, gelb 80–100 %, rot > 100 %), Zeitmarke Datenstand, Einnahmen Plan / erreicht / fehlt noch, nicht zugeordnete Buchungen, Prüfung (Summe je Konto = Kontenübersicht; ausgewertet = Ausgaben − Einnahmen + nicht zugeordnet), Umschlüsseln einzelner Buchungen, Druckansicht für die Vorstandssitzung.
- **Vorjahresvergleich Budget** (Q-DS9, Product Owner 26.10.2026): je Gesamtbudget und Budgetposten **nur das Vorjahr** (Q-DS19) zum gleichen Stichtag (Datenstand des laufenden Jahres, z. B. 30.06.2027 gegen 30.06.2026) und das Ergebnis des ganzen Vorjahres; Grundlage sind die Summen je Budgetposten und Monat (bleiben nach Q-DS11 erhalten). Budgetposten werden über den gleichen Namen und das gleiche Gesamtbudget verglichen [ANNAHME]; neue oder umbenannte Posten erscheinen ohne Vorjahreswert.
- **Budget-Sicht für alle mit „Dashboard lesen“** (Q-DS15): alle Gesamtbudgets und Budgetposten mit Summen; das eigene Referat ist hervorgehoben bzw. oben [ANNAHME]. Einzelbuchungen sieht eine Referent:in nur bei den Budgetposten ihres Referats und bei Gesamtbudgets für alle (Veranstaltungen, Fördermittel) [ANNAHME]; Vorstand, Admin, Geschäftsstelle und Budgetpflege sehen alle Einzelbuchungen. Nicht zugeordnete Buchungen sehen nur Vorstand, Admin, Geschäftsstelle und die Budgetpflege (Q-DS13).
- **Pflege durch die Referent:in** (Q-DS16, Q-DS17): (1) **Hinweis** je Budgetposten des eigenen Referats (z. B. „Rechnung Trainingslager kommt im August“), sichtbar für alle mit Budget-Sicht; (2) **Plan umschichten** (Q-DS18 (Product Owner 26.10.2026)): zwischen Budgetposten des eigenen Gesamtbudgets, die Summe des Gesamtbudgets bleibt gleich; nur zwischen Posten gleicher Art (Ausgabe ↔ Ausgabe, Einnahme ↔ Einnahme) [ANNAHME]; mit Grund; Stand beantragt → bestätigt / abgelehnt durch die **Budgetpflege**; erst bestätigt zählt sie. Die Sicht zeigt beschlossenen Plan (Excel) und aktuellen Plan (beschlossen + bestätigte Umschichtungen) nebeneinander; (3) **Umschlüsselung vorschlagen** für eine Buchung des eigenen Referats (Ziel-Budgetposten, Grund); die Budgetpflege nimmt an oder lehnt ab; bis dahin zählt die Buchung beim bisherigen Posten. Zuordnung der Konten, Import und Umschlüsseln bleiben bei der Budgetpflege.
- **Startseite:** Die Sichten ersetzen den Platzhalter der Startseite (Willkommensgrafik, AD) für Nutzer mit DS-Rechten [ANNAHME].
- Mobil lesbar ab 375 px; Druck/PDF der Sicht.

**Iteration 1 (nach dem MVP, sobald die Quellmodule in Betrieb sind) [ANNAHME]:**
- **Referat Kinder und Jugend – Auslastung der Gruppen** (Q-DS3, Product Owner 26.10.2026) aus drei Kennzahlen: (1) **Anwesenheitsquote** = durchschnittlich anwesende Teilnehmer:innen je Training im Verhältnis zu den Teilnehmer:innen der Gruppe zum Datum des Trainings; (2) **Betreuungsschlüssel** = Anzahl Trainings, bei denen die anwesenden Trainer:innen und Helfer:innen unter dem Mindestverhältnis lagen (Alter nur intern berechnet, nie angezeigt); (3) **Probetrainings** je Gruppe und Monat als Zeichen der Nachfrage. Keine Platzzahl in Gruppen. Dazu: Anzahl Trainings und Absagen je Gruppe und Halbjahr, Betreuung je Gruppe (Trainer:innen mit gültiger förderfähiger Lizenz, Helfer:innen), Probetrainings je Gruppe, Stand der halbjährlichen Abrechnung (bestätigt / offen, Frist).
- **Vorjahresvergleich Kennzahlen** (Q-DS9): jede Kennzahl je Halbjahr bzw. Jahr neben dem gleichen Zeitraum des Vorjahres (z. B. Trainings 1. Halbjahr 2027 gegen 1. Halbjahr 2026); im laufenden Zeitraum bis zum gleichen Tag [ANNAHME]. Gruppen ohne Vorjahr (neu gegründet) ohne Vergleichswert; aufgelöste Gruppen nur im Vorjahr.
- **Leistungssport:** wie Kinder und Jugend, dazu Wettkampfbetreuungen und Trainingslager.
- **Touren und Ausbildung:** Planungen je Status, Kostendeckung, Absagen, „durchgeführt, nicht abgerechnet“, CO2 je Jahr (sobald TK Iteration 1).
- **Verknüpfung Budget ↔ Abrechnung:** abgerechnete, noch nicht gebuchte Vergütung als „gebunden“ am Budgetposten „Vergütung Aktive“.
- **Inhalt und Aufbau der Sichten:** sichten.md v0.5 (Festlegung durch Claude als Referent:in im Auftrag des Product Owners, Q-DS5): je Sicht ① Zu tun, ② Budget meines Referats, ③ Mein Referat in Zahlen, ④ Budget des Vereins; Bausteine je Referat; Entscheidung M/S/C/W zu jedem Eintrag des Ideenkatalogs (ideen-sichten.md).

**Gesamtbudgets und Referate** (Q-DS6, Q-DS15 (Product Owner 26.10.2026); Namen wie im Finanzplan 2026). Die Summen aller Gesamtbudgets sieht jede:r mit „Dashboard lesen“; die Tabelle legt fest, wer **Einzelbuchungen** sieht und wer das Gesamtbudget **pflegt** (Hinweise, Plan):

| Gesamtbudget (Finanzplan 2026) | Einzelbuchungen und Pflege (Hinweise, Plan) | Hinweis |
|---|---|---|
| Kinder und Jugend | Referat Kinder und Jugend | inkl. „Vergütung Aktive“, „Ausbildung KiJu“ |
| Leistungssport | Referat Leistungssport | inkl. „Vergütung Aktive“ |
| Klettern | Referat Klettern | – |
| Touren | Referat Touren | – |
| Ausbildung | Referat Ausbildung | – |
| Karl-Stein-Hütte | Referat Karl-Stein-Hütte | – |
| Öffentlichkeitsarbeit | Referat Öffentlichkeitsarbeit (**neu**) | neues Referat in den Stammdaten der Administration |
| Umwelt und Naturschutz | Referat Umwelt und Naturschutz (**neu**) | neues Referat in den Stammdaten der Administration |
| Veranstaltungen | Einzelbuchungen: **alle** mit „Dashboard lesen“; Pflege: Budgetpflege | Jugend Cup, Europa Cup, Bergfilmfestival |
| Fördermittel | Einzelbuchungen: **alle** mit „Dashboard lesen“; Pflege: Budgetpflege | nur Einnahmen |
| Geschäftsstelle & Verwaltung | ohne Referat: Einzelbuchungen Vorstand, Admin, Geschäftsstelle; Pflege Budgetpflege (bestätigt 26.10.2026) | inkl. Spenden, Ehrenamtspauschale |
| Mitgliederverwaltung | ohne Referat | – |
| Ausleihe/Bibliothek | ohne Referat | – |
| Rücklagen | ohne Referat | kalkulatorisch („keine Buchung“) |
| Vereinszentrum | ohne Referat | – |
| – (Sulzenauhütte) | kein eigenes Budget; das Referat sieht wie alle die Summen des Vereins | kein Budgetposten im Finanzplan; Konten bleiben „nicht zugeordnet“ |

Neue Gesamtbudgets eines späteren Finanzplans bekommen ihr Referat bei der Budgetpflege; ohne Angabe gelten sie als „ohne Referat“ [ANNAHME].

**Nicht im Scope:**
- Finanzbuchhaltung (vision.md, Nicht-Ziel): Das Dashboard bucht nicht und ändert keine Daten in DATEV.
- Eigene Erfassung von Vereinsdaten: Das Dashboard liest nur aus den Fachmodulen (Budgetdaten liegen in Finanzen).
- Frei konfigurierbare Diagramme oder Berichte durch Nutzer (Berichtsbaukasten).
- Personenbezogene Ranglisten (z. B. „wer hat die meisten Einsätze“).
- Daten aus Yolawo (Anmeldungen, Teilnehmerzahlen von Kursen und Touren), Mitgliederverwaltung, Hüttenbelegung: nicht im Vereins OS vorhanden.
- Platzzahl bzw. Höchstzahl je Gruppe (Q-DS3).
- Planung des Finanzplans (Haushaltsaufstellung) im Vereins OS: Der Finanzplan kommt weiter aus der Excel-Datei [ANNAHME].

**Abhängigkeiten:**
- AD → neues Modul DS mit Reichweite „Referat“, Startwerte der Rechtevorlagen, Referate, Startseite (Übergabe uebergabe-administration.md v1.0, offen).
- FI → Bereich Budget (Finanzplan, Zuordnung, Buchungen, Berechnung Plan/Ist; Übergabe uebergabe-finanzen.md v1.0, offen); Abrechnungen (Stand, Summen je Referat und Halbjahr, ausgezahlt).
- GR → Gruppen, Trainingszeiten, Kennzahlen und Gruppendetail (Namen der Teilnehmer:innen und Betreuung, Hinweise; keine Kontaktdaten, Geburtsdaten, Verträge, Gesundheitsangaben) über Lesefunktionen mit Recht auf das Dashboard (Übergabe uebergabe-gruppen.md v1.0, offen).
- EZ → Einsätze und Anwesenheit (Anzahlen je Gruppe, Einsatzart, Zeitraum), Absagen, Probetrainings, Betreuungsschlüssel (berechnet).
- EA → Aktive je Referat und Status, Qualifikationen mit Ablaufdatum, fehlende Nachweise (Anzahlen).
- TK → Planungen je Status, Kalkulation, CO2-Bilanz (eingefroren bis zur Einordnung).
- SC → DATEV-Schnittstelle für den Import der Buchungen (später; bis dahin CSV).
- Extern (über FI): DATEV-Export (Kontenblätter CSV, manuell, monatlich), Excel „Finanzen Sektion JJJJ“ (Blatt „Finanzplan JJJJ“, manuell).
- Richtung: Fachmodule liefern Kennzahlen über eigene Lesefunktionen (je Modul, mit dessen Rechten und Reichweite) [ANNAHME]; DS speichert keine Kopien von Personendaten.

**Risiken / Besonderheiten:**
- **Datenschutz Buchungsdaten:** Der Prototyp lässt die Buchungen bewusst nicht vom Rechner (Content-Security-Policy, keine Speicherung). Im Vereins OS liegen sie in Supabase (EU-Region). Buchungstexte enthalten Namen von Personen (Erstattungen, Vergütungen) und Firmen. Entschieden (Q-DS1, Product Owner 26.10.2026): Die Buchungsliste wird gespeichert; Referent:innen sehen die Einzelbuchungen der Budgetposten ihres Referats. Löschfrist (Q-DS11, Product Owner 26.10.2026): Einzelbuchungen bleiben für das laufende Jahr und das Vorjahr gespeichert; danach werden sie automatisch gelöscht, es bleiben nur Summen je Budgetposten und Monat (z. B. Buchungen 2026 werden am 01.01.2028 gelöscht) [ANNAHME: Stichtag]. Folgen: Eintrag im Verarbeitungsverzeichnis, nur Zeilen auf zugeordneten Erfolgskonten speichern (keine Bank-, Kreditoren- und Personenkonten) [ANNAHME, datensparsam].
- **Datenschutz Minderjährige:** Kennzahlen zu Gruppen dürfen keine Rückschlüsse auf einzelne Kinder erlauben (z. B. Altersstruktur einer Gruppe mit 6 Kindern). [OFFEN] Mindestgröße für Anzahlen oder nur Kennzahlen ohne Merkmale der Kinder.
- **Abgrenzung zu Finanzen** (Q-DS2, entschieden): Budget ist ein Bereich von FI; die frühe Budget-Sicht zieht diesen Bereich vor die Abrechnung vor. Das setzt die Rechte für FI (Nachtrag AD v0.10, Reichweite „Referat“) früh voraus.
- **Zahlen müssen stimmen:** Die Prüfungen des Prototyps (Doppelzählung, Vorzeichen, Saldovorträge, netto/brutto, Regelvorrang) müssen 1:1 übernommen werden; Referenzwerte des Erstexports dienen als Abnahmetest (nicht im Repository, da Finanzzahlen der Sektion; öffentliches Repository).
- **Datenstand:** Ein neuer Export kommt **monatlich** (Q-DS7, Product Owner 26.10.2026); ist der Datenstand älter als 6 Wochen, zeigt die Budget-Sicht einen Hinweis [ANNAHME: Grenze]. Die Buchhaltung bucht mit Verzug (Erstexport vom 18.10.2026 bis 30.06.2026). Sichten müssen den Datenstand deutlich zeigen, sonst wirken Budgets zu frei.
- **Leistung:** Kennzahlen über mehrere Jahre und Module sollen ohne Wartezeit laden; ggf. vorberechnete Summen [ANNAHME].
- Kosten: keine (Supabase, Cloudflare kostenfrei).

**Offene Fragen:**
- Q-DS1 – **entschieden 26.10.2026:** Buchungsliste wird gespeichert; Referent:innen sehen die Einzelbuchungen ihres Referats.
- Q-DS2 – **entschieden 26.10.2026:** Budget (Finanzplan, Zuordnung, Buchungen) ist ein Bereich von Finanzen; das Dashboard zeigt die Sichten und liest aus allen Modulen.
- Q-DS3 – **entschieden 26.10.2026:** Auslastung = Anwesenheitsquote, Betreuungsschlüssel und Probetrainings; keine Platzzahl.
- Q-DS4 – **entschieden 26.10.2026:** Budget-Sicht früh (nach dem Kern der Administration, Daten liegen heute vor), Referats-Kennzahlen nach EZ und FI. [OFFEN] Anpassung des Arbeitsplans (Reihenfolge: Nachtrag AD v0.10 Rechte FI, Bereich Budget FI, DS).
- Q-DS5 – **entschieden 26.10.2026:** keine Rückmeldung der Referate; Claude legt die Sichten als Referent:in fest (sichten.md), der Product Owner nimmt ab.
- Q-DS6 – **entschieden 26.10.2026:** siehe Tabelle „Sichtbarkeit der Gesamtbudgets“; neue Referate Öffentlichkeitsarbeit und Umwelt und Naturschutz (Übergabe an die Administration D10).
- Q-DS7 – **entschieden 26.10.2026:** 1. Vorsitzender, später Schatzmeister:in; künftig über die DATEV-Schnittstelle des Schnittstellen-Connectors; Export monatlich.
- Q-DS8 – **entschieden 26.10.2026:** ja, Kennzahlen der eigenen Gruppe, ohne Budget (nach dem MVP, mit Reichweite „Gruppe“).
- Q-DS9 – **entschieden 26.10.2026:** Vorjahresvergleich für Budget und Kennzahlen.
- Q-DS19 – **entschieden 26.10.2026:** nur das Vorjahr, kein Vergleich über mehrere Jahre.
- Q-DS10 – **entschieden 26.10.2026:** Name in der Oberfläche „Dashboard“; Begriffe Dashboard, Sicht, Kennzahl, Budgetposten, Gesamtbudget, Zuordnung (Budget), Buchung, umschlüsseln, Datenstand im Glossar v1.7. Kürzel DS bleibt [ANNAHME] bis zur Umsetzung.
- Q-DS11 – **entschieden 26.10.2026:** Einzelbuchungen laufendes Jahr und Vorjahr, danach nur Summen je Budgetposten und Monat.
- Q-DS12 – **entschieden 26.10.2026:** eigenes Recht „Dashboard lesen“ (Modul DS, Reichweite „Referat“).
- Q-DS13 – **entschieden 26.10.2026:** nur Buchungen der Budgetposten des Referats.
- Q-DS14 – **entschieden 26.10.2026:** Kennzeichen „darf Budget pflegen“ (Nachtrag der Administration) für Import, Zuordnung, Umschlüsseln und alle Gesamtbudgets.
- Q-DS15 – **entschieden 26.10.2026:** Jede Referent:in sieht das gesamte Budget des Vereins als Summen; Einzelbuchungen nur des eigenen Referats.
- Q-DS16 – **entschieden 26.10.2026:** Referent:innen pflegen nur ihr eigenes Budget: Hinweise und Plan (Plan nur umschichten, Q-DS18).
- Q-DS17 – **entschieden 26.10.2026:** Umschlüsseln durch Referent:innen nur als Vorschlag an die Budgetpflege.
- Q-DS18 – **entschieden 26.10.2026:** nur umschichten innerhalb des Gesamtbudgets (Summe bleibt), Bestätigung durch die Budgetpflege. [ANNAHME] Beim erneuten Einlesen der Excel bleiben bestätigte Umschichtungen erhalten, solange beide Budgetposten noch existieren; sonst Hinweis an die Budgetpflege. Ändert sich die Summe des Gesamtbudgets in der Excel, gilt die Umschichtung weiter als Betrag.
- D5 – **entschieden 26.10.2026:** Der Admin sieht über „Dashboard lesen“ auch die Budget-Sicht.
