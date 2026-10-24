# Übergabe: Planungshilfe Touren und Kurse → Finanzen

Stand: 22.10.2026 · Version 1.3 · Status: eingearbeitet (24.10.2026) · Von: Planungshilfe Touren und Kurse (TK) · An: Finanzen (FI)
Änderungen v1.3: Satztabelle liegt in der Administration; Gemeinschaftstour mit Organisationspauschale (Vergütungsordnung Ziff. 9.2) (Product Owner 22.10.2026).
Änderungen v1.2: Lizenz-Stichtag = Startdatum, Trainersatz für die ganze Tour; abgesagte Einsätze zählen nicht (Product Owner 22.10.2026).
Änderungen v1.1: Satzart Trainer:in nur mit Lizenz, die am letzten Tag der Tour bzw. des Kurses gültig ist (Product Owner 22.10.2026); Kurse im Referat Ausbildung.
Änderungen v1.0: Erste Fassung.

Grundlage: docs/specs/tk-touren-kurse/00-steckbrief.md v0.6, 01-erhebung.md v0.6 (B6, C2).

## Entscheidung (Product Owner 22.10.2026)

Die Planungshilfe **befüllt die Abrechnung vor**, Finanzen rechnet ab. Kalkulation (Planung) in TK, Vergütung und Kostenerstattung (Ist) in Finanzen. Damit ist der offene Punkt „Abgrenzung Kalkulation zu Abrechnung“ entschieden.

## Was TK liefert (lesend, je Planung)

| Angabe | Beispiel (Prototyp) |
|---|---|
| Planung, Tourtyp, Referat, Termin, Status, Einsatz-ID | Führungstour, Touren, 12.–16.07.2027, durchgeführt |
| je Person: Person-ID, Rolle, Satzart (Trainer:in/Helfer:in), Grund bei Helfersatz | Leitung, Trainer:in |
| geplante Tagessätze, Halbtagessätze, Lehreinheiten | 5 / 0 / – |
| Organisationspauschale: Tage, Person | 5, erste Leitung [ANNAHME] |
| Plan-Kosten der Leitung: Position, Menge, Einzelpreis | Bahnfahrt 2 × 105 €; Halbpension 5 × 45 € |
| PKW-Begründung, Genehmigungshinweise (PKW > 500 km, Übernachtung > 70 €) | – |
| Gesamtkosten, Beitrag Mitglieder/Nichtmitglieder, Mindest-/Höchstzahl | 735 €, 160 €, 5/8 |
| Satzstand der Kalkulation | Sätze ab … |

Finanzen nutzt diese Werte als **Vorschlag**; maßgeblich sind Anwesenheit (Anwesenheitserfassung) und Belege. TK speichert keine Ist-Kosten und keine Beträge der Auszahlung.

## Anforderungen an Finanzen

1. Abrechnung „Kurs / Führungstour“ mit Vorbelegung aus TK (Lesefunktion `tk_settlement_draft(p_plan_id)` [ANNAHME: Name, Funktion entsteht in TK]).
2. Erstattung der Reisekosten nach Reisekostenordnung (PKW 0,20 €/km, Übernachtung max. 70 €, Pauschalen Sulzenauhütte 240 €, Karl-Stein-Hütte 60 €) – [OFFEN] gehört die Reisekostenabrechnung zu Finanzen? (heute Formulare „Reisekosten“ und „Kostenabrechnung“).
3. Gemeinsame Satztabelle: Die Sätze der Vergütungsordnung (Tages-, Halbtagessätze Trainer:in/Helfer:in, Organisationspauschale, Lehreinheit) und der Reisekostenordnung liegen als Stammdaten mit „gültig ab“ in der **Administration** (Product Owner 22.10.2026; Übergabe an die Administration v1.4). Finanzen liest sie dort und pflegt keine eigene Tabelle; die Annahme „Sätze pflegbar in Finanzen“ entfällt.
4. Frist „Abrechnung innerhalb von 4 Wochen nach der Tour“ (Prototyp) – Erinnerung in Finanzen? [OFFEN]
5. Stichtag Lizenz: TK rechnet den Trainersatz, wenn die förderfähige Lizenz am Startdatum gültig ist (taggenau); läuft sie während der Tour ab, gilt der Trainersatz für die ganze Tour, keine tageweise Rechnung (Product Owner 22.10.2026). Finanzen sollte dieselbe Regel anwenden; [OFFEN] Verhältnis zur Regel „Vergütung ab dem Abrechnungshalbjahr des Lizenzerwerbs“ (Vergütungsordnung, glossar.md „Trainer:in“).
6. Abgesagte Planungen und Einsätze (Stand „abgesagt“) werden nicht abgerechnet; [OFFEN] Erstattung bereits angefallener Kosten der Leitung (z. B. Stornogebühren) bei Absage.
7. Gemeinschaftstour: Die Organisationspauschale wird nach Vergütungsordnung Ziff. 9.2 gezahlt (Product Owner 22.10.2026); TK liefert Organisationstage und Person, keine Tagessätze.

## Einarbeitung

- [x] eingearbeitet in Finanzen (Datei, Version): specs/fi-finanzen/00-steckbrief.md v0.1 (24.10.2026). Punkte 1, 2, 4, 6, 7 in Iteration 1 (Kurs und Tour, Reisekosten, Kosten bei Absage von Hand, Liste nach 4 Wochen); Punkt 3 übernommen; Punkt 5: Trainersatz bei Lizenz am Startdatum oder Erwerb im selben Abrechnungshalbjahr (Product Owner 24.10.2026). Antwort an die Planungshilfe: specs/fi-finanzen/uebergabe-planungshilfe.md v1.0.
