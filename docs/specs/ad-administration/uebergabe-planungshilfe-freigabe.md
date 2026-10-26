# Übergabe: Administration → Planungshilfe Touren und Kurse (Freigaberecht)

Stand: 26.10.2026 · Version 1.0 · Status: offen (Planungshilfe eingefroren; Einarbeitung bei der Wiederaufnahme) · Von: Administration (AD, Nachtrag v0.10) · An: Planungshilfe Touren und Kurse (TK)
Grundlage: spec.md AD v0.10.0 (R30, R50, T59, T68); querschnitt-administration.md Q1 (Product Owner 24.10.2026); Entscheidung Product Owner 26.10.2026 im Chat Finanzen
Änderungen v1.0: Erste Fassung.

## Anlass

Q1 ist entschieden: Freigaben sind eine eigene Aktion im Rechtemodell, nicht ein Modul ohne Seiten. Mit dem Nachtrag v0.10 der Administration (für Finanzen) entfällt das Modul **TKF** aus Nachtrag v0.9, bevor es umgesetzt wurde. Die Spec der Planungshilfe (v0.2) verweist noch auf TKF.

## Änderungen für die Planungshilfe

- **P1 – Freigaberecht:** statt `ad_my_referate('TKF','edit')` gilt `ad_can_approve('TK', referat)` bzw. `ad_my_approve_referate('TK')` (R50 AD). Die Funktion `tk_can_approve` der Planungshilfe ist darauf umzustellen.
- **P2 – Vorlage „Freigabe Touren und Kurse“:** hat jetzt TK `edit` + „darf freigeben“ mit Reichweite „Referat“ (vorher TKF `edit`). Wer sie hat, darf Planungen des Referats bearbeiten und freigeben – wie bisher entschieden. Eine eigene Prüfung „TKF ohne TK“ entfällt.
- **P3 – Lesen:** `ea_search_active_persons` und `ea_person_licenses` prüfen nur noch TK-Rechte (die Freigabe-Vorlage hat TK bearbeiten). `ad_my_modules` braucht keine Sonderregel mehr.
- **P4 – Oberfläche Administration:** Die Vorlagen-Matrix hat keine Zeile „Freigabe Touren und Kurse“ mehr, sondern ein Kontrollkästchen „darf freigeben“ in der Zeile Planungshilfe.
- **P5 – Tests und Seed:** Erwartete Ergebnisse der Planungshilfe mit Fritz Freigabe (nur Vorlage Freigabe) anpassen: `ad_my_referate('TK','edit')` = {Touren}, `ad_my_approve_referate('TK')` = {Touren} (spec.md AD Abschnitt 9).

## Einarbeitung

- [ ] eingearbeitet in Planungshilfe Touren und Kurse (Datei, Version): –
