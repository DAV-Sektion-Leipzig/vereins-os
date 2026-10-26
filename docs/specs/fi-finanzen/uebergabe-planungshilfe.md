# Übergabe: Finanzen → Planungshilfe Touren und Kurse

Stand: 24.10.2026 · Version 1.0 · Status: offen (Planungshilfe eingefroren; Einarbeitung bei der Wiederaufnahme) · Von: Finanzen (FI) · An: Planungshilfe Touren und Kurse (TK)
Grundlage: docs/specs/fi-finanzen/00-steckbrief.md v0.1; specs/tk-touren-kurse/uebergabe-finanzen.md v1.3
Änderungen v1.0: Erste Fassung.

## Anlass

Die Übergabe TK → FI v1.3 ist in Finanzen eingearbeitet (Steckbrief v0.1). Antworten und Folgen für die Planungshilfe:

- **T1 – Zeitpunkt:** Abrechnung von Kurs und Tour kommt mit Iteration 1 von Finanzen; die Vorbelegung über `tk_settlement_draft` nutzt Finanzen, sobald die Planungshilfe umgesetzt ist. Finanzen hängt für den Start nicht von der Planungshilfe ab.
- **T2 – Lizenz-Regel (Product Owner 24.10.2026):** Finanzen zahlt den Trainersatz, wenn am Startdatum eine förderfähige Lizenz gültig ist (dann für den ganzen Einsatz) **oder** die Lizenz im selben Abrechnungshalbjahr erworben wurde. Die Planungshilfe prüft nur das Startdatum; eine im Halbjahr vor dem Startdatum erworbene Lizenz ist dort gültig, eine danach erworbene nicht. Abweichungen sind möglich, weil die Planung nur Vorschlag ist; [OFFEN] ob die Planungshilfe die Regel angleicht.
- **T3 – Abrechnungsart:** Einsätze aus der Planungshilfe erhalten die Abrechnungsart aus der Vorbelegung je Einsatzart (Stammdaten der Administration; Übergabe FI → AD v1.0, A2; FI → EZ v1.0, Z1). Gemeinschaftstour: nur Organisationspauschale (Ziff. 9.2).
- **T4 – Reisekosten und Kostenerstattung:** gehören zu Finanzen, mit Iteration 1 (Product Owner 24.10.2026). Die Plan-Kosten der Leitung aus der Planungshilfe sind Vorschlag; maßgeblich sind die Belege.
- **T5 – Kosten bei Absage:** Erstattung bereits angefallener Kosten (z. B. Stornogebühren) als Einzelfall von Hand in Finanzen (Iteration 1); keine Vergütung nach Sätzen für abgesagte Einsätze.
- **T6 – Frist „Abrechnung innerhalb von 4 Wochen“:** in Finanzen als Liste „durchgeführt, noch nicht abgerechnet, älter als 4 Wochen“ (Iteration 1); E-Mail erst mit dem Schnittstellen-Connector.
- **T7 – Sperre:** Ist ein Einsatz abgerechnet, lehnt die Anwesenheitserfassung auch Änderungen aus der Planungshilfe an abrechnungsrelevanten Daten ab (Übergabe FI → EZ v1.0, Z3).

## Einarbeitung

- [ ] eingearbeitet in Planungshilfe Touren und Kurse (Datei, Version): –
