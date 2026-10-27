# Tasks: Schnittstellen-Connector (SC)

Stand: 27.10.2026 · Grundlage: spec.md v0.2 (Ready), 02-stories.md v0.2 · Umsetzungsdatei (pflegt Claude Code)

Die Tasks folgen spec.md Abschnitt 10 (T1–T19); Entscheidungen in [plan.md](plan.md).

## Regeln für alle Tasks

- Keine Echtdaten, kein echter Key in Repository, Seed oder Tests (R14).
- Nie gegen PROD; Ausrollen nach TEST nur nach Freigabe des Product Owners (supabase/setup/README.md Abschnitt 2a).

## Phase 1: Datenbank und Edge Function

- [x] ST01 (spec T1) `supabase/migrations/20261109000100_sc_tables.sql`: Typen, Tabellen, Indizes, RLS, Spaltenrechte; pg_net
- [x] ST02 (spec T2) Startwert Geschäftsstelle SC lesen, Modulname „Schnittstellen“, Anlässe `sc_test`, `sc_key_expiry` (im selben File); `is_available` → ST13
- [x] ST03 (spec T3) `…0200_sc_admin.sql`: `sc_save_connection`, `sc_set_key` (Vault), `sc_set_state`, `sc_set_modules`
- [x] ST04 (spec T4) `sc_save_occasion`, `sc_preview_occasion`, `sc_occasion_texts`
- [x] ST05 (spec T5) `…0300_sc_enqueue.sql`: `sc_mail_enqueue`, `sc_mail_try_enqueue`, `sc_recipient_email`, `sc_persons_with_level`
- [x] ST06 (spec T6) `…0400_sc_dispatch.sql`: `sc_check_dispatch_secret`, `sc_claim`, `sc_connection_key`, `sc_report`, `sc_test_prepare`, `sc_test_report`
- [x] ST07 (spec T7) `sc_outbox_retry`, `sc_outbox_discard`, `sc_outbox_content`, `sc_status`
- [x] ST08 (spec T8) Jobs `sc-dispatch` (5 Minuten) und `sc-daily` (02:40)
- [x] ST09 (spec T9) Anlass `ad_emergency_login`, Trigger `sc_ad_emergency_login_mail` auf `ad_audit_log`
- [x] ST10 (spec T10) pgTAP `supabase/tests/database/900_sc.test.sql` (113 Prüfungen); `020_persons_rights` um Geschäftsstelle SC lesen ergänzt
- [x] ST11 (spec T11) Edge Function `supabase/functions/sc-send/` (handler, brevo, deps), Deno-Tests `index.test.ts`; `config.toml` `verify_jwt = false`
- [x] ST12 (spec T12) Seed `supabase/seed-sc.sql` über `SEED_WITH_SC=1 supabase/seed.sh`
- [x] ST17 (spec T17) Checkliste `supabase/setup/README.md` Abschnitt 2a; Fehlercodes `SC_*` in `docs/specs/ad-administration/contracts/error-codes.md`

## Phase 2: Oberfläche (Merge durch den Product Owner)

- [x] ST13 (spec T13) `/schnittstellen` (`src/features/sc/`), Kachel auf der Startseite, Reiter „Anbindungen“ mit Dialogen; Migration `20261110000100_sc_available.sql` (`is_available`, `sc_actor_names`)
- [x] ST14 (spec T14) Reiter „Vorlagen“ (Platzhalter zum Einfügen, Zähler, Vorschau)
- [x] ST15 (spec T15) Reiter „Postausgang“ und „Protokoll“ (Filter über die Adresse, 50 je Seite)
- [x] ST16 (spec T16) Hinweiskarte auf der Startseite (nur mit SC lesen)
- [x] ST18 (spec T18) Anleitung v4.0: Admin, Geschäftsstelle, Wörterliste, Ablaufbild `postausgang`; Bilder `sc-*` vorläufig aus der Oberfläche mit simulierten Antworten, neu erzeugen mit dem Workflow „Anleitung: Bilder erzeugen“ (Filter `sc-`), sobald TEST Migrationen und Seed hat
- [ ] ST19 (spec T19) [abnahme-test.md](abnahme-test.md) angelegt; Abnahme in TEST durch den Product Owner

## Abweichungen und Präzisierungen gegenüber spec.md (zur Kenntnis des Product Owners)

- `sc_status()` liefert die Spalten `kind, amount, message` (plan.md P9).
- Neue Spalte `sc_mail_occasions.link_path` für den Platzhalter `{link}` (P5).
- Zusätzliche Funktion `sc_mail_try_enqueue`; nur sie schreibt `enqueue_rejected` ins Protokoll (P4).
- `sc_report` erhält die Fehlerart; 429 zählt nicht für die Störung, übrige 400 zählen als Konfigurationsfehler (P6).
- Test-E-Mails zählen nicht für das Tageslimit (P7).
- `ad_modules.is_available` für SC kommt mit der Oberfläche (ST13), nicht mit T2, damit die Navigation nicht auf eine leere Seite zeigt.
- Zusätzliche Lesefunktion `sc_actor_names(uuid[])` für die Spalte „Von“ im Protokoll (nur mit SC lesen, nur Namen).
- Route `/schnittstellen` statt Modulkürzel (wie `/dashboard`).
