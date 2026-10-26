# Tasks: Planungshilfe Touren und Kurse (TK)

Umsetzungsdatei zu [spec.md](spec.md) v0.4 (Abschnitt 10, T1–T23) und [plan.md](plan.md). Stand: 26.10.2026.
Schreibweise: `[spec Tn]` = Task der Spec, `[US-TK-nn]` = Story, `[P]` = parallel möglich.

## Stufe 0: Fachliche Einarbeitung (Product Owner)

- [ ] T000 Übergaben einarbeiten: TK → AD v1.8 Punkte 15, 16 in spec.md AD (Nachtrag v0.12); TK → EZ v1.3 Punkt 10 in spec.md EZ (Nachtrag v0.7). Nur mit Auftrag des Product Owners, Branches `docs/…`.

## Stufe 1: Administration für TK

Siehe [AD tasks.md](../ad-administration/tasks.md) Phase 18 (T134–T141). Voraussetzung für alle weiteren Stufen.

## Stufe 2: Datenbank (Branch `tk-datenbank`)

- [ ] T001 [spec T1] Migration Typen und Tabellen `tk_plans`, `tk_plan_leaders` (mit `license_valid_from`), `tk_plan_contacts`, `tk_plan_legs`, `tk_plan_costs`, `tk_plan_results`, `tk_plan_rates`, `tk_plan_history`, `tk_qualification_sports`, `tk_privacy_confirmations`; Checks, Indizes, RLS an, keine Schreib-Grants (US-TK-01, -02, R10)
- [ ] T002 [spec T2] Rechtefunktionen `tk_can_read`, `tk_can_write`, `tk_can_approve` (`ad_can_approve('TK', …)`), `tk_can_manage`, `tk_can_read_contacts`; `tk_person_visible` ersetzt den Platzhalter (gleiche Signatur); Select-Policies
- [ ] T003 [spec T3] Startbestand `tk_qualification_sports` (Prototyp 4.8) über `ad_qualification_types.code`; nicht zuordenbare Bezeichnungen per `raise notice` und hier notieren
- [ ] T004 [spec T4] Trigger: Referat aus Tourtyp (`tk_plan_referat`, P3), Audit, Sperre direkter Statusänderung (`TK_STATUS_DIRECT`)
- [ ] T005 [spec T5] `tk_rates`, `tk_calculate` nach R1–R4, R6, R22; Satzart mit Erwerb im Halbjahr (R2)
- [ ] T006 [P] [spec T6, T20] Testfälle `scripts/tk-calc/cases.json` (Planungen 1–5, 7, 9; Satzwechsel nach `valid_from`; fehlender Satz; Lizenz-Erwerb im Halbjahr); pgTAP `820_tk_calculate.test.sql`
- [ ] T007 [spec T7] `tk_save_plan` (Schritte 1–9 ohne EZ-Aufruf), `tk_copy_plan`, `tk_delete_plan`
- [ ] T008 [spec T8] `tk_change_status` ohne EZ-Aufrufe (submit, query, resubmit, approve mit Satzstand, done, close, cancel ohne Einsatz); publish nur `tk_can_approve` oder `tk_can_manage` (A11)
- [ ] T009 [spec T9] `tk_list_plans`, `tk_get_plan` (inkl. `rates`, Rechte-Kennzeichen), `tk_cost_report`
- [ ] T010 [spec T10] `tk_purge_contacts` (30 Tage, R16) und pg_cron-Job 03:15 Uhr
- [ ] T011 [spec T11] `tk_settlement_draft` (US-TK-24; Lizenz-Felder mit Erwerbsdatum)
- [ ] T012 [spec T23] `tk_create_leader`, `tk_reactivate_leader` (R23)
- [ ] T013 [P] [spec T12] Fehlercodes TK in `ad-administration/contracts/error-codes.md`
- [ ] T014 [spec T15, T18] Seed nach spec.md 9 (Planungen 1–9, ohne Einsatz bei Planung 5 bis Stufe 3); pgTAP `800_tk_structure`, `810_tk_rights` (Sichtbarkeitsmatrix, R19 je Status, R17, R13, Kontaktdaten-RLS, direkte Schreibzugriffe abgelehnt), `830_tk_save_status`, `840_tk_purge_leaders` (Löschjob, R23), `860_tk_volume`

## Stufe 3: Anbindung Anwesenheitserfassung (Branch `tk-ez-anbindung`)

- [ ] T015 [spec T13] EZ T036 (mit `p_remuneration_kind_code`, EZ v1.3) und TK-Anbindung in `tk_change_status` (publish, cancel mit `TK_EZ_LOCKED`) und `tk_save_plan` (Synchronisation, Abrechnungsart, `EZ_SETTLED` wie `EZ_EVENT_LOCKED`); Seed Planung 5 mit Einsatz
- [ ] T016 [spec T14] pgTAP `850_tk_ez.test.sql` zusammen mit EZ T037/T038: Inhalt R15, Gemeinschaftstour mit `COMMUNITY_TOUR`, Sperre nach Anwesenheit und Abrechnung, Absage, Rollback

## Stufe 4: Oberfläche (Branch `tk-oberflaeche`)

- [ ] T017 [spec T20] `src/features/tk/calc.ts` mit `npm run tk:calc:test` gegen `cases.json`
- [ ] T018 [spec T16] Zugriff, Rahmen, Navigation (Planungen · Auswertung), Liste `/tk` mit Filtern und Karten mobil, `/tk/neu`, Kopieren (US-TK-01, -02, -23)
- [ ] T019 [spec T17] `/tk/:id` Schritte 1–7, Seitenleiste (Beitrag, CO2, Fortschritt, Hinweise), Speichern mit `row_version` und Autospeichern, Konfliktdialog, Statusdialoge, Verlauf (US-TK-03 bis -14, -16 bis -18)
- [ ] T020 [spec T23] Dialog „Neue Person anlegen“ und Dublettendialog nach `src/features/shared/` (EZ und TK), Wieder aktivieren (US-TK-03 AK9, AK10)
- [ ] T021 AD T64 Rest: Zeile Planungshilfe in der Vorlagen-Matrix mit „darf freigeben“; Anleitung (Teil Referent:innen und Geschäftsstelle, Screenshots, Version)

## Stufe 5: Ausgaben und Auswertung (Branch `tk-ausgaben-auswertung`)

- [ ] T022 [spec T19] Texte (Eingabeblatt, Ausschreibung, Zusammenfassung) als reine Funktionen mit Test; Reiter „Ausgaben“ mit Kopierknöpfen (US-TK-15, -21)
- [ ] T023 [spec T19] PDF nach Prototyp 7.5; gemeinsame PDF-Hilfen nach `src/lib/pdf.ts`
- [ ] T024 [spec T21] `/tk/auswertung` mit Summenzeile und CSV (Semikolon, UTF-8 mit BOM, nur Geschäftsstelle) (US-TK-20); Anleitung ergänzen

## Stufe 6: Abnahme und Freischalten

- [ ] T025 [spec T22] abnahme-test.md erstellen; Abnahme in TEST mit allen Testzugängen (Desktop und 375 px), Vergleich Planung 1 mit dem Prototyp; Prüfliste Referat Touren eingearbeitet
- [ ] T026 [spec T22] Migration `is_available = true` für TK, nur nach Freigabe des Product Owners

## Abhängigkeiten

- Stufe 1 vor allen Datenbank-Tasks; T000 vor Stufe 1 (AD-Teil) bzw. Stufe 3 (EZ-Teil).
- T005 vor T006, T007; T007 vor T008; T015 nach T007, T008.
- T017 kann parallel zu Stufe 2 beginnen (nur `cases.json` nötig).
- T019 braucht T009; Statusaktionen mit Einsatz erst nach Stufe 3.
