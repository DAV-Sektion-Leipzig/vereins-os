# Tasks: Finanzen (FI)

Stand: 26.10.2026 · Grundlage: spec.md v0.2 (Ready), 02-stories.md v0.1 · Umsetzungsdatei (pflegt Claude Code)

Die Tasks folgen spec.md Abschnitt 10 (T1–T16). Ein eigener Spec-Kit-Plan entsteht für die Oberfläche; die Datenbank folgt der Spec direkt.

## Regeln für alle Tasks

- Voraussetzungen: Administration Nachtrag v0.10 (PR #51), Anwesenheitserfassung Nachtrag v0.6 (PR #52).
- Keine Echtdaten; Tests und Seed nur fiktiv, IBAN nur `DE89370400440532013000`.
- Nie gegen PROD; Ausrollen nach TEST nur nach Freigabe des Product Owners.

## Phase 1: Datenbank (Branch `fi-kern-datenbank`)

- [x] FT01 (spec T1) `supabase/migrations/20261031000100_fi_tables.sql`: Typen, Tabellen (inkl. `fi_run_counters`, `has_new_events`, `bank_check`), Rechtefunktionen, RLS (nur lesen), Trigger für Satz und Betrag (R9), Summe, Audit
- [x] FT02 (spec T2) `supabase/migrations/20261031000200_fi_visibility_hints.sql`: `fi_person_visible`, `fi_attendance_locked`, `fi_event_locked` ersetzt; interne Hinweise `fi_person_flags`, `fi_settlement_info` (R11–R14; Referent:innen nur Ja/Nein)
- [x] FT03 (spec T3) `supabase/migrations/20261031000300_fi_calculate.sql`: `fi_calculate_half` (R1–R10, R15, R23)
- [x] FT04 (spec T4) `supabase/migrations/20261031000400_fi_read.sql`: `fi_list_settlements`, `fi_get_settlement`, `fi_settlement_document`
- [x] FT05 (spec T5) `supabase/migrations/20261031000500_fi_workflow.sql`: Korrektur, Ausnahme, Bestätigung, Vertretung, Abschluss, Rücknahme, Abgabe, Verfall
- [x] FT06 (spec T6) `supabase/migrations/20261031000600_fi_payout.sql`: Auszahlungsrunden, Freigabe, `fi_payout_export`, `fi_list_payout_runs`
- [x] FT07 (spec T7) `supabase/migrations/20261031000700_fi_climbing.sql`: Abgleich Punktekonto
- [x] FT08 (spec T8) Fehlercodes `FI_*` in `docs/specs/ad-administration/contracts/error-codes.md`; `ad_modules.is_available` für FI erst mit der Freigabe
- [x] FT09 (spec T9) pgTAP `610_fi_structure.test.sql`, `620_fi_flow.test.sql`
- [x] FT10 (spec T10) Seed `supabase/seed-fi.sql` mit `SEED_WITH_FI=1 supabase/seed.sh` (Personen 601–606, Einsätze im 1. Halbjahr 2026, Leistungsgruppe Test, Testzugänge Lea Leistung `test.leistung@dav-leipzig.de` und Gerd Geschäftsstelle `test.geschaeftsstelle2@dav-leipzig.de`); erwartete Beträge im Kopf der Datei. Ausführen in TEST durch den Product Owner (`.env.local`)

## Phase 2: Oberfläche (je eigener Branch, Merge durch den Product Owner)

- [x] FT11 (spec T11) /fi Liste mit Filtern und Mehrfachaktionen (`src/features/fi/liste/`, Rahmen `FiLayout.tsx`, `access.ts`)
- [x] FT12 (spec T12) /fi/abrechnung/:id mit Dialogen (`src/features/fi/detail/`)
- [x] FT13 (spec T13) Abrechnungsdokument (PDF) (`src/features/fi/export/documents.ts`; jsPDF, plan.md P1–P3)
- [x] FT14 (spec T14) /fi/auszahlungen; Auszahlliste (PDF) und Überweisungsdatei (XML) mit Schema-Test (`src/features/fi/auszahlungen/`, `export/`; Test `npm run fi:export:test`, XSD optional über `PAIN001_XSD`)
- [x] FT15 (spec T15) /fi/kletterhalle (`src/features/fi/kletterhalle/`)
- [ ] FT16 (spec T16) abnahme-test.md (angelegt), Abnahme in TEST (Product Owner)

## Abweichungen und Präzisierungen gegenüber spec.md (zur Kenntnis des Product Owners)

- Hinweise je Abrechnung werden über interne Funktionen berechnet, die nur Ja/Nein-Werte liefern; so sehen Referent:innen den Hinweis „Bankverbindung fehlt“, ohne Zugriff auf `ea_person_finance_data` (R31, R55).
- Prüfwert der Bankverbindung (`fi_payout_lines.bank_check`, md5 der IBAN) für den Hinweis „Bankverbindung seit der Freigabe geändert“ (R21); keine IBAN gespeichert.
- Positionen ohne Gruppe bilden je Referat eine Auszahlzeile (R24); Check auf genau Gruppe oder Referat.
- Kurse (Lehreinheiten) werden in der Berechnung noch nicht berücksichtigt (Iteration 1).
- Neuer Fehlercode `FI_PERIOD_INVALID` (ungültiges Halbjahr; nur Programmierfehler).
