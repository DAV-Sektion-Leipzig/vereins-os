# Plan: Schnittstellen-Connector (SC) – MVP E-Mail über Brevo

Umsetzungsdatei zu [spec.md](spec.md) v0.2 (Ready, 27.10.2026); Tasks in [tasks.md](tasks.md). Hält die technischen Entscheidungen fest; fachlich gilt die Spec.

## Phasen

| Phase | Inhalt | Tasks (spec) | Merge |
|---|---|---|---|
| 1 | Datenbank (Tabellen, RLS, Funktionen, Jobs, Trigger Notfall-Admin), pgTAP, Edge Function `sc-send` mit Deno-Tests, Seed, Fehlercodes, Einrichtungs-Checkliste | T1–T12, T17 | Product Owner (Edge Function) |
| 2 | Oberfläche `/schnittstellen` (vier Reiter), Hinweis auf der Startseite, `ad_modules.is_available` für SC, Anleitung, Abnahmetest | T13–T16, T18, T19 | Product Owner |

## Entscheidungen

| # | Thema | Entscheidung | Grund |
|---|---|---|---|
| P1 | Migrationen | `20261109000100` Typen, Tabellen, RLS, Spaltenrechte, Startwert Geschäftsstelle, Anlässe SC · `…0200` Pflege, Vorlagen, Postausgang, Hinweise · `…0300` Einstellen, Empfänger, Anlass AD, Trigger · `…0400` Funktionen der Edge Function, Jobs | je Thema eine Datei |
| P2 | Key | Vault-Eintrag `sc_connection_<id>`; Lesen in `sc_set_key` über `vault.decrypted_secrets` (für `postgres` freigegeben), Schreiben über `vault.create_secret`/`update_secret` | R11; keine Spalte für den Key |
| P3 | Zeitvergleich für R3 | `config_changed_at` und `last_test_ok_at` mit `clock_timestamp()`, damit Test und Änderung auch in derselben Transaktion eine Reihenfolge haben | pgTAP läuft in einer Transaktion |
| P4 | Protokoll bei Ablehnung | `sc_mail_enqueue` wirft den Fehler an das Modul (die Transaktion des Moduls entscheidet); `sc_mail_try_enqueue` fängt ihn und schreibt `enqueue_rejected` – für Trigger und Jobs | ein Fehler rollt sonst auch den Protokolleintrag zurück |
| P5 | Link | Spalte `sc_mail_occasions.link_path`; `{link}` = Vault `sc_app_url` (ohne Eintrag `http://localhost:5173`) + Pfad; Module übergeben `{link}` nicht | A6 |
| P6 | Fehlerarten | Edge Function ordnet zu: 400 mit Empfängerbezug → `recipient` (sofort fehlgeschlagen), übrige 400, 401, 403 → `auth`, 429 → `rate`, sonst und Zeitüberschreitung → `server`. Für die Störung zählen `auth` und `server`, nicht `rate` und `recipient` | spec 4, A7 |
| P7 | Grenzen | `sc_claim` zählt versendete E-Mails der Stunde bzw. des Tages (Europe/Berlin) und laufende Sperren; Test-E-Mails zählen nicht | R13; Test-E-Mails sind selten |
| P8 | Gateway | `sc-send` mit `verify_jwt = false` (config.toml, beim Bereitstellen `--no-verify-jwt`); Job über Header `x-sc-dispatch-secret` (Vergleich mit Vault), Test über JWT (`getUser`, `ad_has_level('SC','edit')`) | der Job hat kein JWT |
| P9 | Hinweise | `sc_status()` liefert `(kind, amount, message)` statt `(kind, count, text)` (Spaltennamen ohne Konflikt mit SQL-Namen) | technisch |
| P10 | Modulname | `ad_modules.name` für SC = „Schnittstellen“ (Q-SC1) | Navigation |
| P11 | Tests lokal | ohne Docker: Postgres 16 mit pgTAP und pg_cron, Platzhalter für `auth`, `vault`, `net`; vollständig in CI (`db-tests`) | Docker-Registries in der Cloud-Umgebung nicht erreichbar |

## Offene Punkte für die Abnahme

- Bereitstellung der Edge Function und der Migrationen nach TEST und PROD folgt O1 (supabase/setup/README.md Abschnitt 2).
- Die Seed-Zeile „Anmeldung des Notfall-Admins“ (seed.sql) löst in TEST beim Seed einen Protokolleintrag `enqueue_rejected` aus, solange keine Anbindung für AD freigegeben ist; das ist gewollt (AK3).
