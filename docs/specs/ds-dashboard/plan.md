# Plan: Dashboard (DS) mit Bereich Budget (FI)

Umsetzungsdatei zu [spec.md](spec.md) v0.2 (Ready, 26.10.2026); Tasks in [tasks.md](tasks.md). Hält die technischen Entscheidungen fest; fachlich gilt die Spec.

## Phasen und Branches

| Phase | Inhalt | Tasks (spec) | Merge |
|---|---|---|---|
| 1 | Administration: Modul DS, Reichweite „Referat“, Kennzeichen „darf Budget pflegen“, Vorlage „Budgetpflege“, neue Referate | T1–T3 | Auto-Merge (nur Migration, pgTAP, Umsetzungsdateien) |
| 2 | Datenbank Bereich Budget: Tabellen, Regeln, Finanzplan, Zuordnung, Import, Pflege, Lesefunktionen, Löschlauf | T5–T13 | Auto-Merge |
| 3 | Oberfläche: Parser im Browser, /dashboard, Postendetail, /dashboard/verein, /dashboard/budget/pflege, Kennzeichen in der Rechtevorlage, Startseite | T4, T14–T16 | Product Owner |
| 4 | Seed, Anleitung, Abnahmetest; `ad_modules.is_available` für DS erst mit der Freigabe | T17–T19 | Product Owner |

## Entscheidungen

| # | Thema | Entscheidung | Grund |
|---|---|---|---|
| P1 | Reihenfolge im Menü | DS bekommt `sort_order` vor AD (Menüpunkt „Dashboard“ an erster Stelle, US-DS-20 AK3); bestehende Module rücken um eins | Startseite zeigt das Dashboard zuerst |
| P2 | Kennzeichen | Spalte `ad_template_rights.can_maintain_budget` (analog `can_approve`); nur Modul DS, Stufe ≠ none, Reichweite „alle“ (Check und Guard, Fehler `AD_BUDGET_MAINTAIN_NOT_ALLOWED`) | uebergabe-administration.md D6 |
| P3 | Vorlage „Budgetpflege“ | eigene Rechtevorlage mit DS lesen (alle) + Kennzeichen; Zuweisung an 1. Vorsitzenden und Schatzmeister:in durch den Admin in der Oberfläche (keine Personen in der Migration) | keine Personendaten in Migrationen |
| P4 | Startwerte | nur Zeilen, die noch „kein Zugriff“ mit Reichweite „alle“ haben, werden gesetzt (wie EZ, T50) | überschreibt keine Änderungen des Admins |
| P5 | Neue Referate | „Öffentlichkeitsarbeit“ (8) und „Umwelt und Naturschutz“ (9), `semiannual_settlement = false`, idempotent über den Namen | D10 |
| P6 | Dateien lesen | im Browser: DATEV-CSV und `zuordnung.csv` mit eigenem Parser ohne Abhängigkeiten (`src/features/ds/budget/parse/`, UTF-8 mit BOM oder Windows-1252, Spalten über Namen); Excel mit `read-excel-file` 9.3 (MIT, dynamischer Import als eigener Chunk, ca. 45 kB). Unit-Tests `npm run ds:budget:test` | spec.md Abschnitt 1 |
| P7 | Tests lokal | `supabase start` ohne Edge-Runtime und Studio, `supabase db reset`, `SEED_TEST_PASSWORD=… supabase/seed.sh`, `supabase test db supabase/tests/database` | wie CI (db-tests.yml Block B) |
| P8 | Gesamtbudget eines Postens ändern | zusätzliche Funktion `fi_budget_item_move(p_item, p_group_name)`; leere Gesamtbudgets werden entfernt | der Finanzplan kennt keine Gesamtbudgets; beim ersten Jahr ohne `zuordnung.csv` braucht die Budgetpflege einen Weg, Posten zu gruppieren |
| P9 | Migrationen Phase 2 | `20261105100100` Tabellen, RLS · `…0200` Kontoangaben, Regelvorrang, View `fi_budget_assigned` · `…0300` Finanzplan, Gesamtbudgets, Regeln, `zuordnung.csv`, neues Jahr · `…0400` DATEV-Import · `…0500` Umschlüsseln, Vorschläge, Hinweise, Umschichtungen, Markierung · `…0600` Lesefunktionen `ds_budget_*`, `ds_todo` · `…0700` Löschlauf (pg_cron täglich 03:15) | Zeitstempel nach den TK-Migrationen (`20261104…`) |
| P10 | Vorschau (R18) | berechnet in `fi_budget_preview(year, referat)`, nur beim ersten Posten „Vergütung Aktive“ eines Gesamtbudgets des Referats; Runden und Abrechnungen getrennt (`preview_runs`, `preview_settlements`) | spec R18 Umsetzung |
| P11 | Vorjahr nach Löschlauf (R20) | `fi_budget_item_sums` nutzt Einzelbuchungen, ohne sie die Monatssummen bis zum letzten vollen Monat; Monatssummen werden über die Regeln ohne Einzelbuchungsmerkmale zugeordnet | spec R20 [ANNAHME] |
| P12 | Zu tun | eigene Anträge und Vorschläge: offen oder in den letzten 14 Tagen entschieden [ANNAHME]; Datenstand alt ab 42 Tagen nur für das laufende Jahr | US-DS-17, R23 |
| P13 | Auszahlungsrunden in der Budgetpflege | zusätzliche Lesefunktion `ds_budget_payout_runs(p_year)` (Migration `20261106100100`, nach den TK-Migrationen `20261106…`): freigegebene Runden mit „gebucht“ (Abgleich oder Markierung), nur Budgetpflege, ohne Personen | R18; die Budgetpflege hat nicht unbedingt FI-Rechte |
| P14 | Startseite | Dashboard-Block (Zu tun, Kacheln) über den Modulen nur, wenn DS in `ad_my_modules` steht, also erst mit `is_available` (Phase 4); bis dahin `/dashboard` nur über die Adresse | US-DS-20; PROD zeigt vor der Freigabe nichts Neues |
| P15 | Kennzeichen in der Rechtevorlage | in der Spalte „darf freigeben“ steht beim Dashboard „Budget pflegen“; nur mit Stufe und Reichweite „alle“; Reichweite „Referat“ auch für DS wählbar | DS D6, P2 |
| P16 | Sicht | Referent:innen: ihre Referate und „Verein“; Reichweite „alle“: alle Referate mit Budget und „Verein“; Gesamtbudgets mit Ausgaben vor reinen Einnahmen | spec 6 |

## Offene Punkte für die Abnahme

- Bestehende Tests, die Module, Vorlagen oder Referate abzählen, werden an den neuen Stand angepasst (kein Überspringen).
- Kennzeichen „darf Budget pflegen“ in der Oberfläche der Rechtevorlagen kommt mit Phase 3; bis dahin setzt es nur der Admin über die Startwerte (Vorlage „Budgetpflege“).
