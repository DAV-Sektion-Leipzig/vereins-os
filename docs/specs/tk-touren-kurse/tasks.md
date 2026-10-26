# Tasks: Planungshilfe Touren und Kurse (TK)

Umsetzungsdatei zu [spec.md](spec.md) v0.4 (Abschnitt 10, T1–T23) und [plan.md](plan.md). Stand: 26.10.2026.
Schreibweise: `[spec Tn]` = Task der Spec, `[US-TK-nn]` = Story, `[P]` = parallel möglich.

## Stufe 0: Fachliche Einarbeitung (Product Owner)

- [ ] T000 Übergaben einarbeiten: TK → AD v1.8 Punkte 15, 16 in spec.md AD (Nachtrag v0.12); TK → EZ v1.3 Punkt 10 in spec.md EZ (Nachtrag v0.7). Nur mit Auftrag des Product Owners, Branches `docs/…`.

## Stufe 1: Administration für TK

Siehe [AD tasks.md](../ad-administration/tasks.md) Phase 18 (T134–T141). Voraussetzung für alle weiteren Stufen.

## Stufe 2: Datenbank (Branch `tk-datenbank`)

- [x] T001 [spec T1] `20261105000100_tk_tables.sql`: Migration Typen und Tabellen `tk_plans`, `tk_plan_leaders` (mit `license_valid_from`), `tk_plan_contacts`, `tk_plan_legs`, `tk_plan_costs`, `tk_plan_results`, `tk_plan_rates`, `tk_plan_history`, `tk_qualification_sports`, `tk_privacy_confirmations`; Checks, Indizes, RLS an, keine Schreib-Grants (US-TK-01, -02, R10)
- [x] T002 [spec T2] `20261105000100_tk_tables.sql`: Rechtefunktionen `tk_can_read`, `tk_can_write`, `tk_can_approve` (`ad_can_approve('TK', …)`), `tk_can_manage`, `tk_can_read_contacts`; `tk_person_visible` ersetzt den Platzhalter (gleiche Signatur); Select-Policies
- [x] T003 [spec T3] `20261105000200_tk_triggers.sql`: Startbestand `tk_qualification_sports` (Prototyp 4.8) über `ad_qualification_types.code` (10 Arten). Zuordnung „Trainer*in C Sportklettern“ → TCSPI, TCSP und KS (alle Sportklettern Breitensport) [ANNAHME, Prüfliste Referat Touren Nr. 4]; alle Kürzel gefunden
- [x] T004 [spec T4] `20261105000200_tk_triggers.sql`: Trigger: Referat aus Tourtyp (`tk_plan_referat`, P3), Audit, Sperre direkter Statusänderung (`TK_STATUS_DIRECT`)
- [x] T005 [spec T5] `20261105000300_tk_calculate.sql`: `tk_rates`, `tk_calculate` nach R1–R4, R6, R22; Satzart mit Erwerb im Halbjahr (R2)
- [x] T006 [P] [spec T6] pgTAP `820_tk_calculate.test.sql` (40 Prüfungen: Planungen 1–5, 7, 9 mit den Werten aus Prototyp 4.5/4.7, Satzwechsel 2028, fehlender Satz, Lizenz-Erwerb im Halbjahr, Warnungen). `scripts/tk-calc/cases.json` mit denselben Werten folgt mit T017 (Oberfläche)
- [x] T007 [spec T7] `20261105000400_tk_save.sql`: `tk_save_plan` (Schritte 1–9 ohne EZ-Aufruf), `tk_copy_plan`, `tk_delete_plan`
- [x] T008 [spec T8] `20261105000500_tk_status.sql` (publish setzt nur den Status; Einsatz mit T015): `tk_change_status` ohne EZ-Aufrufe (submit, query, resubmit, approve mit Satzstand, done, close, cancel ohne Einsatz); publish nur `tk_can_approve` oder `tk_can_manage` (A11)
- [x] T009 [spec T9] `20261105000600_tk_read.sql`: `tk_list_plans`, `tk_get_plan` (inkl. `rates`, Rechte-Kennzeichen), `tk_cost_report`
- [x] T010 [spec T10] `20261105000700_tk_purge_leaders.sql`: `tk_purge_contacts` (30 Tage, R16) und pg_cron-Job 03:15 Uhr
- [x] T011 [spec T11] `20261105000600_tk_read.sql`: `tk_settlement_draft` (US-TK-24; Lizenz-Felder mit Erwerbsdatum)
- [x] T012 [spec T23] `20261105000700_tk_purge_leaders.sql`: `tk_create_leader`, `tk_reactivate_leader` (R23)
- [x] T013 [P] [spec T12] (zusätzlich technisch `TK_FIELD_INVALID`, `TK_REFERAT_MISSING`, `TK_FIELD_LOCKED`) Fehlercodes TK in `ad-administration/contracts/error-codes.md`
- [x] T014 [spec T15, T18] Seed `supabase/seed-tk.sql` (nur TEST, `SEED_WITH_TK=1`, nicht in CI) nach spec.md 9 (Planungen 1–9, ohne Einsatz bei Planung 5 bis Stufe 3); pgTAP legen ihre Daten selbst an: `800_tk_structure`, `810_tk_rights` (Sichtbarkeitsmatrix, R19 je Status, R17, R13, Kontaktdaten-RLS, direkte Schreibzugriffe abgelehnt), `830_tk_save_status`, `840_tk_purge_leaders` (Löschjob, R23), `860_tk_volume`

## Stufe 3: Anbindung Anwesenheitserfassung (Branch `tk-ez-anbindung`)

- [x] T015 [spec T13] `20261106000100_ez_planned_event.sql`, `20261106000200_tk_ez.sql` (`tk_ez_sync`; Seed Planung 5 mit Einsatz): EZ T036 (mit `p_remuneration_kind_code`, EZ v1.3) und TK-Anbindung in `tk_change_status` (publish, cancel mit `TK_EZ_LOCKED`) und `tk_save_plan` (Synchronisation, Abrechnungsart, `EZ_SETTLED` wie `EZ_EVENT_LOCKED`); Seed Planung 5 mit Einsatz
- [x] T016 [spec T14] (30 Prüfungen) pgTAP `850_tk_ez.test.sql` zusammen mit EZ T037/T038: Inhalt R15, Gemeinschaftstour mit `COMMUNITY_TOUR`, Sperre nach Anwesenheit und Abrechnung, Absage, Rollback

## Stufe 4: Oberfläche (Branch `tk-oberflaeche`)

- [x] T017 [spec T20] `src/features/tk/calc.ts` mit `npm run tk:calc:test` (`scripts/tk-calc/calc.test.ts`, gleiche Werte wie pgTAP 820; statt einer eigenen `cases.json`)
- [x] T018 [spec T16] `src/features/tk/` (access, TkLayout, liste/, neu/): Zugriff, Rahmen, Navigation (Planungen · Auswertung), Liste `/tk` mit Filtern und Karten mobil, `/tk/neu`, Kopieren (US-TK-01, -02, -23)
- [x] T019 [spec T17] `detail/PlanungPage.tsx`, `steps.tsx`, `Seitenleiste.tsx`, `Verlauf.tsx` (Wortlaut der Bestätigungen c2–c4 [ANNAHME], Prototyp nennt nur Kurzbezeichnungen): `/tk/:id` Schritte 1–7, Seitenleiste (Beitrag, CO2, Fortschritt, Hinweise), Speichern mit `row_version` und Autospeichern, Konfliktdialog, Statusdialoge, Verlauf (US-TK-03 bis -14, -16 bis -18)
- [x] T020 [spec T23] `detail/NeueLeitungDialog.tsx` mit gemeinsamem `DublettenDialog`, Wieder aktivieren (US-TK-03 AK9, AK10). Abweichung von plan.md P8: eigene Fassung statt Verschieben des EZ-Dialogs (EZ speichert dabei die Anwesenheit, TK nur die Person); EZ unverändert
- [ ] T021 AD T64 Rest: Zeile Planungshilfe in der Vorlagen-Matrix mit „darf freigeben“ – erledigt (schon mit AD T129, `APPROVE_MODULES`); Anleitung (Teil Referent:innen und Geschäftsstelle, Screenshots, Version) folgt mit Stufe 5 vor dem Freischalten, weil das Modul bis dahin nicht sichtbar ist

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
