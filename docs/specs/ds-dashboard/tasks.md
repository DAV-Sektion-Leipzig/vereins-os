# Tasks: Dashboard (DS) mit Bereich Budget (FI)

Stand: 26.10.2026 · Grundlage: spec.md v0.2 (Ready), 02-stories.md DS v0.2, 02-stories.md FI v0.3 (US-FI-22 bis US-FI-29), plan.md · Umsetzungsdatei (pflegt Claude Code)

## Regeln für alle Tasks

- Keine Echtdaten; Tests und Seed nur fiktiv (fiktiver Finanzplan, fiktiver DATEV-Export).
- Nie gegen PROD; Ausrollen nach TEST nur nach Freigabe des Product Owners.
- Keine Buchungstexte in Protokoll, Fehlermeldungen oder Logs.

## Phase 1: Administration (plan.md P1–P5)

- [x] DT01 (spec T1) `supabase/migrations/20261103000100_ad_ds_module.sql`: Modul DS (vor AD), Zeilen DS je Vorlage, Reichweite „Referat“ für DS (R30), `can_maintain_budget` mit Check und Guard, `ad_has_budget_maintain()`
- [x] DT02 (spec T2, Datenbankteil) gleiche Migration: Startwerte DS (Admin, Geschäftsstelle, Vorstand lesen alle; Referent:in lesen Referat), Vorlage „Budgetpflege“, Referate Öffentlichkeitsarbeit und Umwelt und Naturschutz; Fehlercode in `docs/specs/ad-administration/contracts/error-codes.md`
- [x] DT03 (spec T3) pgTAP `supabase/tests/database/700_ds_rights.test.sql`; bestehende Tests an Module, Vorlagen und Referate angepasst

## Phase 2: Datenbank Bereich Budget

- [x] DT05 (spec T5) Migration Typen, Tabellen, RLS, Grants, Indizes (spec 2.1, 2.2, 3)
- [x] DT06 (spec T6) `fi_budget_rule_parse`, `fi_budget_match`, Views (R1–R3, R11)
- [x] DT07 (spec T7) Finanzplan, Gesamtbudgets, neues Jahr (US-FI-22, -23, -29)
- [x] DT08 (spec T8) Zuordnung, Übernahme `zuordnung.csv` (US-FI-24, -25)
- [x] DT09 (spec T9) Import mit Prüfung und Monatssummen (US-FI-26)
- [x] DT10 (spec T10) Umschlüsseln, Vorschläge, Hinweise, Umschichtungen, Markierung Auszahlungsrunde (US-FI-27, US-DS-11 bis -15)
- [x] DT11 (spec T11) Lesefunktionen `ds_budget_*`, `ds_todo` inkl. Vorschau (US-DS-07 bis -10, -16 bis -18)
- [x] DT12 (spec T12) Löschlauf mit pg_cron (US-FI-28)
- [x] DT13 (spec T13) pgTAP Rechenregeln gegen fiktiven Export, Rechte, Zustände, Fehlercodes, Löschlauf

## Phase 3: Oberfläche

- [x] DT14 (spec T14) Parser Excel und DATEV-CSV im Browser mit Unit-Tests (plan.md P6)
- [x] DT15 (spec T15) /dashboard, Postendetail, Dialoge, Vorschau, Druck
- [x] DT16 (spec T16) /dashboard/verein, /dashboard/budget/pflege
- [x] DT04 (spec T4, T2 Oberfläche) Startseite mit Dashboard; Kennzeichen „darf Budget pflegen“ in der Rechtevorlage

## Phase 4: Abschluss

- [ ] DT17 (spec T17) Seed `supabase/seed-ds.sql`, Testzugänge Budgetpflege und Schatzmeisterin Test — Teil 1 mit Phase 3: `seed-ds.sql` (`SEED_WITH_DS=1`, Budgetpflege für Vorstand Test, Finanzplan, Regeln, DATEV-Export, Hinweis, Umschichtung, Vorschlag); offen: Testzugang Schatzmeisterin Test
- [x] DT18 (spec T18) Anleitung: neuer Teil „Budgetpflege“ (05), Abschnitte Dashboard in 01–04, Version 2.0 (mit Phase 3, CLAUDE.md „Anleitung im selben Pull Request“)
- [ ] DT19 (spec T19) abnahme-test.md; `ad_modules.is_available` für DS mit der Freigabe
