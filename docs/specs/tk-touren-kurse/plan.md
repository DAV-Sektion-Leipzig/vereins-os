# Plan: Planungshilfe Touren und Kurse (TK)

Umsetzungsdatei zu [spec.md](spec.md) v0.4 (Ready, 26.10.2026), [02-stories.md](02-stories.md) v0.5 (US-TK-01 bis US-TK-24) und den Übergaben dieses Ordners. Tasks in [tasks.md](tasks.md). Stand: 26.10.2026.

## Summary

Das Erhebungsformular des Prototyps „Tourenkonzept“ wird vollständig im Vereins OS umgesetzt, und zwar mit:
- Status und Freigabe,
- Leitung aus den Aktiven, externe Leitende über R23,
- Kalkulation in der Datenbank mit einer Kopie in TypeScript für die Live-Anzeige,
- CO2-Bilanz je Planung,
- Ausgaben für Yolawo und PDF,
- Kostenauswertung,
- Einsatz in der Anwesenheitserfassung.

Alle Angaben liegen strukturiert in `tk_`-Tabellen. Geschrieben wird nur über `security definer`-Funktionen.

## Reihenfolge und Branches

| # | Branch | Inhalt | Merge | Voraussetzung |
|---|---|---|---|---|
| 0 | `docs/ad-nachtrag-v012-tk`, `docs/ez-nachtrag-v07-tk` | Übergaben TK → AD v1.8 (Punkte 15, 16) und TK → EZ v1.3 (Punkt 10) in spec.md AD und spec.md EZ einarbeiten | Product Owner (fachlich) | Auftrag des Product Owners |
| 1 | `ad-nachtrag-v09-tk` | Rest der Administration für TK, siehe AD tasks.md Phase 18 (T134–T141) | Auto-Merge (nur Migrationen, Tests, Seed, Umsetzungsdateien) | 0 (AD) |
| 2 | `tk-datenbank` | TK-Tabellen, Rechte, Kalkulation, Speichern, Status, Lesen, Löschjob, Personen anlegen, Seed, pgTAP (T001–T014) | Auto-Merge | 1 |
| 3 | `tk-ez-anbindung` | `ez_upsert_planned_event` mit Abrechnungsart, `ez_cancel_planned_event`, `ez_planned_event_state` (EZ T036–T038), TK-Anbindung in `tk_save_plan` und `tk_change_status` (T015–T016) | Auto-Merge | 0 (EZ), 2 |
| 4 | `tk-oberflaeche` | Liste, Neu, Planung mit Schritten 1–7, Seitenleiste, Autospeichern, Statusdialoge, `calc.ts`, Zeile Planungshilfe in der Vorlagen-Matrix (AD T64 Rest), Anleitung (T017–T021) | Product Owner | 2 (3 für die Statusaktionen mit Einsatz) |
| 5 | `tk-ausgaben-auswertung` | Eingabeblatt, Ausschreibungstext, Zusammenfassung, PDF, Kostenauswertung mit CSV, Anleitung (T022–T024) | Product Owner | 4 |
| 6 | `tk-freischalten` | Abnahme in TEST, danach `is_available = true` (T025–T026) | Auto-Merge (Migration) nach Freigabe | 5, Abnahme |

TEST-Rollout jeder Datenbank-Stufe nach dem Merge mit `npx supabase db push --linked` (nur nach Prüfung `supabase/.temp/project-ref` = TEST). PROD: [OFFEN] O1 (siehe unten).

## Technischer Rahmen

- **Datenbank:** PostgreSQL 17 (Supabase). Migrationen `supabase/migrations/202611040001xx_ad_tk_*.sql` (Stufe 1), `202611050001xx_tk_*.sql` (Stufe 2), `202611060001xx_tk_ez_*.sql` (Stufe 3); eigene Datumsnummern, weil das Dashboard parallel `20261103…` nutzt. pgTAP-Dateien `294_ad_tk.test.sql` (Stufe 1) und `800_`–`860_tk_*.test.sql` (700er nutzt das Dashboard). Lokal mit der Postgres.app-Umgebung (Skripte im Scratchpad), in CI über `db-tests`.
- **Frontend:** React 19, Vite, TypeScript, shadcn/ui, react-router Loader, sonner, ResponsiveTable wie EZ und FI. Ordner `src/features/tk/` (die Spec nennt `src/modules/tk/`; das Repo führt Module unter `src/features/`, technische Abweichung ohne fachliche Wirkung).
- **Keine neuen Pakete.** PDF mit `jspdf` 4.2.1 und `jspdf-autotable` 5.0.9 (schon vorhanden, dynamischer Import).

## Entscheidungen

| # | Thema | Entscheidung | Grund |
|---|---|---|---|
| P1 | Kalkulation doppelt | `tk_calculate` (PL/pgSQL) ist maßgeblich (R1). `src/features/tk/calc.ts` ist eine reine Funktion ohne Supabase und dient nur der Live-Anzeige. Beide laufen gegen dieselben Testfälle aus `scripts/tk-calc/cases.json` (Planungen 1–5, 7, 9 aus spec.md 9 mit erwarteten Werten). Die TS-Seite testet `npm run tk:calc:test` (tsx --test), die SQL-Seite pgTAP `820_tk_calculate.test.sql` mit denselben Werten. | spec.md 8, T6/T20: Werte auf den Cent gleich |
| P2 | Rundung | `numeric` in SQL, Cent-Ganzzahlen in TS (wie FI `toCents`); Beitrag `ceil(roh / rRund − 1e−9) × rRund`; CO2 auf 0,01 kg | R1 |
| P3 | Referat aus Tourtyp | `tk_plan_referat(plan_type)` löst die Referate über den Namen in `ea_referate` auf („Ausbildung“, „Touren“; Startbestand der Migration `…23000200`). Fehlt der Name: Fehler `TK_REFERAT_MISSING` beim Anlegen, ohne festes UUID. | R12; robuster als feste IDs [ANNAHME der Spec ersetzt, technisch] |
| P4 | Sätze | `tk_rates(p_plan_id)` liefert die Sätze als `jsonb` (eingefroren aus `tk_plan_rates` oder `ad_rates_at`). Frontend liest denselben Stand über `tk_get_plan` (Schlüssel `rates`). | R3, eine Quelle für beide Rechnungen |
| P5 | Speichern | Ein Aufruf `tk_save_plan` je Speichern mit ganzer Planung, Unterlisten ersetzen; Autospeichern 2 s nach der letzten Änderung (Debounce), nur wenn bearbeitbar; `row_version` gegen gleichzeitiges Bearbeiten; bei Netzfehler bleiben die Eingaben im Speicher, nicht im Browser-Speicher | R20, spec.md 6 |
| P6 | Live-Anzeige | `calc.ts` rechnet bei jeder Eingabe; nach dem Speichern ersetzt das Ergebnis der Datenbank die Anzeige. Bei Abweichung gilt die Datenbank, die Seitenleiste zeigt den Wert der Datenbank. | R1 |
| P7 | Löschjob | `tk_purge_contacts()` täglich 03:15 Uhr über `cron.schedule` wie `ad_emergency_notice` (pg_cron; lokal Stub). Frist 30 Tage. | R16 |
| P8 | Externe Leitende | `tk_create_leader` und `tk_reactivate_leader` rufen `ea_create_volunteer` und `ea_activate_person` mit dem TK-Pfad (AD Stufe 1). Dialog und Dublettendialog aus der Anwesenheitserfassung werden nach `src/features/shared/` verschoben und von EZ und TK genutzt. | R23; einmal bauen |
| P9 | EZ-Anbindung | `ez_upsert_planned_event` erhält `p_remuneration_kind_code text default null` (EZ v1.3 Punkt 10). Stufe 3 legt die EZ-Funktionen und die TK-Anbindung in einem Branch an, weil sich `tk_can_write` und `ez_upsert_planned_event` gegenseitig brauchen. | Spec Voraussetzung 2 |
| P10 | Ausgaben | Die Texte (Eingabeblatt, Ausschreibung, Zusammenfassung) sind reine Funktionen in `src/features/tk/ausgaben/texts.ts`, gebaut nach Prototyp 7.1–7.3 ohne Stornoregel und mit Test (`scripts/tk-calc/texts.test.ts`). PDF nach Prototyp 7.5 mit den gemeinsamen Hilfen aus `src/features/fi/export/pdf.ts`, verschoben nach `src/lib/pdf.ts`. | R11, R14 |
| P11 | Qualifikation → Sportart | Startbestand `tk_qualification_sports` per Migration über die Kürzel der Qualifikationsarten (`ad_qualification_types.code`); nicht zuordenbare Prototyp-Bezeichnungen meldet die Migration per `raise notice`; sie werden bei T003 in tasks.md notiert. | spec.md 2, C3 |
| P12 | Fehlercodes | Neue Codes im Abschnitt TK von `ad-administration/contracts/error-codes.md`; Texte im Frontend in `src/features/tk/errors.ts` | spec.md 5 |
| P13 | Mengentest | pgTAP `860_tk_volume.test.sql`: 60 Planungen mit je 10 Leitenden, 10 Teilstrecken, 40 Kostenzeilen; `tk_save_plan` und `tk_list_plans` unter 1 s (lokal gemessen, in CI nur Funktion) | spec.md 8 |

## Constitution Check

| Prinzip | Ergebnis |
|---|---|
| Fachliche Quelle | setzt spec.md v0.4 um; Abweichungen nur technisch (P3, `src/features`) |
| Offene Punkte | O1–O3 unten, nicht entschieden |
| Sicherheit in der DB | RLS auf allen `tk_`-Tabellen, nur `select`-Policies; Grants nur an `authenticated`; `tk_purge_contacts` ohne Grant; Kontaktdaten in eigener Tabelle mit eigener Policy |
| Personenmodell | keine Personenangaben in `tk_`-Tabellen außer Kontakt- und Notfalldaten je Planung (R8, R16); Namen nur über `ea_person_names` |
| Daten und Umgebungen | Seed fiktiv (spec.md 9), nie gegen PROD |
| Kostenfrei, mobil | keine neuen Dienste oder Pakete; ab 375 px lesbar, Kalkulation am Desktop |

## Offene Punkte

- **O1** [OFFEN] Migrationen nach PROD (übergreifend, offene-punkte.md): bis zur Entscheidung nur TEST.
- **O2** [OFFEN] Text und Link des Datenschutzhinweises (gemeinsam mit EZ); bis dahin die Konfiguration der Anwesenheitserfassung.
- **O3** [OFFEN] Prüfliste Referat Touren: Werte des Prototyps bleiben Startbestand; Änderungen als neue Sätze oder Änderung der Startbestand-Migration vor der Freigabe.
