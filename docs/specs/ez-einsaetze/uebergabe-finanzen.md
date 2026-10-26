# Übergabe an Finanzen: Trainerabrechnung, Vergütungsordnung, Kontrolle Kletterhalle

Stand: 24.10.2026 · Version 1.6 · Von: Anwesenheitserfassung (EZ) · An: Finanzen (FI) · Status: eingearbeitet (24.10.2026, specs/fi-finanzen/00-steckbrief.md v0.1, 01-erhebung.md v0.1)
Quelle: specs/ez-einsaetze/00-steckbrief.md (v0.8), 01-erhebung.md (v0.4), spec.md (v0.2); Vergütungsordnung der Sektion (2025_DAV_Leipzig_FO_VGO, Beschluss 21.11.2023, ergänzt 11.12.2025; vom Product Owner am 21.10.2026 geliefert)
Änderungen v1.6: Training ohne Uhrzeit (Dauer aus der Trainingszeit der Gruppe); Beginn und Ende mehrtägiger Einsätze optional; Einsatzart heißt Wettkampfbetreuung. Abgesagte Einsätze zählen nicht für die Abrechnung; Kurs und Tour nur mit Trainer:innen und Helfer:innen (keine Teilnehmenden), auch aus der Planungshilfe Touren und Kurse erzeugt; Trainingslager mit Gruppe wie Mehrtagesfahrt (Product Owner 24.10.2026).
Änderungen v1.5: Hinweis auf Abweichung von Vergütungsordnung Punkt 7 und Vorstandsbeschluss gestrichen (Product Owner 22.10.2026: Fehlinterpretation); Abgrenzung zum Modul Touren und Kurse (Kalkulation dort, Vergütung hier [ANNAHME]).
Änderungen v1.4: Mehrtägige Einsätze mit Enduhrzeit; Wettkampfbegleitung ein- oder mehrtägig; Erwachsenenfahrten nicht im Scope; Reihenfolge Gruppen → Anwesenheitserfassung → Finanzen; Idee eines eigenen Abrechnungsmoduls.
Änderungen v1.3: Zeiten bei Fahrten wie im Forms-Formular; Ausbildungsfahrt; Ort beim Training; Zuordnung der Einsatzarten.
Änderungen v1.2: Modulname Anwesenheitserfassung; Abrechnungszeitraum ab Startort; Punktekonto nur Kinder.
Änderungen v1.1: Vergütungsordnung eingearbeitet.

## Anlass

Die Anwesenheitserfassung erhebt und speichert nur. Die Vergütung wird in Finanzen abgerechnet (Product Owner, 21.10.2026). Grundlage ist die Vergütungsordnung; der Vorstand kann sie jederzeit ändern. Reihenfolge der Umsetzung: Gruppen → Anwesenheitserfassung → Finanzen. Der Product Owner erwägt, die Abrechnung als eigenes Modul zu führen, das in Finanzen aufgeht (Struktur und Navigation später). Das eigenständige Modul Touren und Kurse übernimmt Erstellung, Planung und Kalkulation (Kosten, Ausgaben, Deckungsbeitrag, Material, CO2) von Kursen und Touren; die Vergütung nach der Durchführung bleibt Aufgabe von Finanzen [ANNAHME].

## Anforderungen

- **F1 – Datengrundlage:** Finanzen liest aus der Anwesenheitserfassung: Einsatz (Einsatzart, Referat, Gruppe, Titel, organisierende Person; Training: Datum, Ort – ohne Uhrzeit; eintägig: Datum und Dauer-Kategorie „unter 8 Stunden“ / „mindestens 8 Stunden“; mehrtägig: Startdatum, Enddatum, Beginn und Ende optional) und Anwesenheit je Person mit Rolle (Trainer:in, Helfer:in, Teilnehmer:in). Finanzen pflegt diese Daten nicht.
- **F2 – Zuordnung Einsatzart → Abrechnungsart:**

| Einsatzart (Oberfläche) | Abrechnungsart (Vergütungsordnung) |
|---|---|
| Training | Trainingseinheiten (Dauer aus der Trainingszeit der Gruppe am Wochentag des Datums, Modul Gruppen; höchstens eine je Gruppe und Wochentag; Product Owner 24.10.2026) |
| Tagesausflug, Mehrtagesfahrt | Kinder- und Jugendfahrten, Gruppenfahrten |
| Ausbildungsfahrt (ein- oder mehrtägig) | Mehrtageskurse [ANNAHME; eintägig: [OFFEN]] |
| Wettkampfbetreuung (ein- oder mehrtägig) | Wettkampfbetreuung [OFFEN: Satz je Tag?] |
| Kurs | Kurse (Lehreinheiten) [OFFEN: Erfassung der Lehreinheiten] |
| Tour | Führungstour wie Mehrtageskurs; Gemeinschaftstour nur Organisationspauschale |
| Trainingslager | Mehrtageskurse/Trainingslager |
| Arbeitseinsatz | keine Übungsleiterpauschale |

  Abgesagte Einsätze (Stand „abgesagt“, `ez_events.cancelled_at`) zählen nicht. Bei Kurs und Tour erfasst die Anwesenheitserfassung nur Trainer:innen und Helfer:innen mit Stand „anwesend“, keine Teilnehmenden; Einsätze aus der Planungshilfe Touren und Kurse sind an `ez_events.tk_plan_id` erkennbar (Planwerte als Vorbelegung liefert die Planungshilfe, Übergabe TK → FI v1.3).

  TJB-Vorbereitungswochenende und Alpinfahrt gelten als Mehrtageskurs (Ausbildungsfahrt). Unterschieden nach Trainer:in und Helfer:in. Erwachsenenfahrten sind nicht im Scope.
- **F3 – Sätze (Stand Anhang 1), pflegbar ohne Code-Änderung, mit gültig ab:**

| Abrechnungsart | Position | Trainer:in | Helfer:in | ohne Rolle |
|---|---|---|---|---|
| Training | Trainingseinheit (30 Minuten) | 6,00 € | 4,00 € | – |
| Kinder- und Jugendfahrten, Gruppenfahrten | Tagessatz (ab 8 h) | 30,00 € | 20,00 € | – |
| | Halbtagessatz (unter 8 h) | 15,00 € | 10,00 € | – |
| | Organisationspauschale pro Tag | – | – | 10,00 € |
| Wettkampfbetreuung | Satz [ANNAHME: je Wettkampf bzw. Tag] | 50,00 € | 40,00 € | – |
| Kurse | Lehreinheit (1 h) | – | – | 15,00 € |
| Mehrtageskurse, Führungstouren, Trainingslager | Tagessatz (ab 8 h) | 50,00 € | 40,00 € | – |
| | Halbtagessatz (unter 8 h) | 25,00 € | 20,00 € | – |
| | Organisationspauschale pro Tag | – | – | 10,00 € |

  Die Sätze könnte auch das Modul Touren und Kurse für die Kalkulation nutzen [ANNAHME]; gepflegt werden sie an einer Stelle.
- **F4 – Tages- und Halbtagessatz:** Eintägig aus der erfassten Kategorie (unter 8 Stunden = Halbtagessatz, mindestens 8 Stunden = Tagessatz). Mehrtägig aus Startdatum/Beginn und Enddatum/Ende: erster Tag ab Beginn bis 24:00, letzter Tag ab 0:00 bis Ende, Zwischentage als Tagessatz [ANNAHME: Berechnungsweise]. Beginn und Ende sind Abfahrt und Rückkehr am Startort (Reisezeit = Arbeitszeit); sie sind optional (Product Owner 24.10.2026) – [OFFEN] Satz für ersten und letzten Tag, wenn sie fehlen. Reisekosten nach Reisekostenordnung, nicht Teil dieser Abrechnung.
- **F5 – Vergütung als Trainer:in:** nur mit förderfähiger Lizenz, ab dem Abrechnungshalbjahr des Lizenzerwerbs; Ausnahmen mit Begründung der verantwortlichen Referent:in. Prüfung gegen die Qualifikationen im Ehrenamtsmanagement [ANNAHME: förderfähig = Qualifikationsart DOSB-lizenzfähig]. Sonst Satz Helfer:in [ANNAHME].
- **F6 – Voraussetzung der Auszahlung:** Bestätigung steuerfreie Einnahmen liegt vor der ersten Zahlung vor (Nachweis im Ehrenamtsmanagement). Steuerfreier Höchstbetrag je Kalenderjahr nach § 3 EStG; Überschreiten ist sichtbar zu machen [ANNAHME].
- **F7 – Halbjährliche Abrechnung:** Für die Referate Kinder und Jugend und Leistungssport [ANNAHME: = „Jugend und Leistung“] je Halbjahr ein Abrechnungsdokument je Person zur Unterschrift; Abgabe bis 31.07. bzw. 15.12., danach erlischt der Anspruch. Andere Referate: [OFFEN].
- **F8 – Kontrolle Kletterhalle:** Die Kletterhalle bucht je Training und Kind Punkte von einem Punktekonto ab und stellt Rechnungen; Trainer:innen werden nicht abgebucht. Abgleich zwischen anwesenden Teilnehmer:innen je Training und Ort (Orte mit Kennzeichen „Punktekonto Kletterhalle“, Stammdaten der Administration) und Punktekonto bzw. Rechnung. Die Anwesenheitserfassung liefert im MVP die Liste „Anzahl anwesender Teilnehmer:innen je Training, Ort und Zeitraum“; der Abgleich selbst ist ein Kontrollmodus in Finanzen [ANNAHME].
- **F9 – Ehrenamtspauschale:** wird nicht aus Einsätzen berechnet (Antrag, Vorstandsbeschluss, Vereinbarung, jährliche Erklärung). Abbildung in Finanzen [OFFEN].

## Offene Punkte

- [OFFEN] Rundung angebrochener Trainingseinheiten (z. B. 75 Minuten = 2 oder 3 TE?).
- [OFFEN] Eintägige Ausbildungsfahrt: Halbtages- bzw. Tagessatz der Mehrtageskurse oder der Fahrten?
- [OFFEN] Wettkampfbetreuung: Satz je Wettkampf, je Tag oder mit Tages-/Halbtagessatz – jetzt auch mehrtägig?
- [OFFEN] Ort der Pflege der Sätze: Finanzen (Vorschlag) oder Administration.
- [OFFEN] Eigenes Abrechnungsmodul, das in Finanzen aufgeht?
- [OFFEN] Abgrenzung zum Modul Touren und Kurse: Kalkulation dort, Vergütung hier [ANNAHME]; Kostendeckung von Führungstouren (Punkt 9.1) eher dort?
- [OFFEN] Einsätze nach Abgabe des Halbjahres sperren?
- [OFFEN] Aufbewahrungsfrist der Einsätze als Abrechnungsgrundlage gegenüber der 5-Jahres-Regel.
- Erledigt (v1.5): kein Vorstandsbeschluss zu Punkt 7 nötig.
- Erledigt (v1.4): letzter Tag mehrtägiger Einsätze – Enduhrzeit wird erfasst.
- Erledigt (v1.3): Zeiten bei Fahrten wie im heutigen Formular.
- Erledigt (v1.2): Abrechnungszeitraum ab Startort; Trainer:innen werden nicht vom Punktekonto abgebucht.
- Erledigt (v1.1): Trainingseinheit = 30 Minuten; Tabelle der Sätze geliefert (Anhang 1).

## Folgeänderungen in Finanzen (durch den Chat Finanzen)

- Beim Steckbrief Finanzen F1–F9 übernehmen.
- Nach dem Einarbeiten: diese Übergabe als erledigt markieren.
- [x] Eingearbeitet am 24.10.2026 in specs/fi-finanzen/00-steckbrief.md v0.1 und 01-erhebung.md v0.1 (F1–F9 übernommen; Entscheidungen des Product Owners: TE aufrunden, Wettkampfbetreuung je Kalendertag, ohne Uhrzeit Tagessatz mit Korrektur, Lizenz am Datum oder Erwerb im Halbjahr, Sperre nach Freigabe, halbjährlich nur Kinder und Jugend und Leistungssport, Sätze und Abrechnungsarten in der Administration, Ehrenamtspauschale später; offen: eintägige Ausbildungsfahrt als Startwert der Vorbelegung). Folgen für die Anwesenheitserfassung: specs/fi-finanzen/uebergabe-anwesenheitserfassung.md v1.0.
