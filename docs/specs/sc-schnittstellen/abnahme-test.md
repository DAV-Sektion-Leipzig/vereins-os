# Abnahme-Test: Schnittstellen-Connector (SC) – MVP E-Mail über Brevo

Umsetzungsdatei zu Spec T19 ([tasks.md](tasks.md), ST19). Grundlage: spec.md v0.2 Abschnitte 6 und 9, [plan.md](plan.md). Stand: 27.10.2026.

Legende: **erledigt** = von Claude Code geprüft · **offen (PO)** = mit Testzugang in der Vorschau gegen TEST, führt der Product Owner aus · **wartet** = Voraussetzung fehlt.

## 1. Voraussetzungen

| Punkt | Stand |
|---|---|
| Migrationen `20261109000100`–`…0400` und `20261110000100` in TEST | offen (PO, Weg nach O1) |
| Edge Function `sc-send` in TEST ohne JWT-Prüfung des Gateways bereitgestellt | offen (PO, supabase/setup/README.md Abschnitt 2a) |
| Vault in TEST: `sc_dispatch_url`, `sc_dispatch_secret`, `sc_app_url` (Vorschau-Adresse) | offen (PO) |
| Brevo: eigener API-Key für TEST, IP-Beschränkung für API-Keys aus | offen (PO) |
| Seed `SEED_WITH_SC=1 supabase/seed.sh` in TEST (nach `seed.sql`) | offen (PO) |
| Testzugänge: Admin (`test.admin@`), Geschäftsstelle (`test.geschaeftsstelle@`), Notfall-Admin (`test.notfall@`), Referent:in (`test.referent@`) | vorhanden (seed.sql) |

## 2. Automatische Prüfungen

| Prüfung | Ergebnis |
|---|---|
| `db-tests`: pgTAP `900_sc` (Rechte, Key, Freigaben, Vorlagen, Postausgang, Versand, Grenzen, Notfall-Admin, Jobs, Namen) | erledigt (grün, PR #104; Erweiterung ST13 in diesem PR) |
| Deno-Tests `sc-send` (14, Brevo simuliert) | erledigt (PR #104) |
| `tsc -b`, `oxlint`, `vite build` | erledigt |
| Oberfläche lokal im Browser (Playwright, simulierte Antworten) als Admin und Geschäftsstelle, 1280 px und 375 px | erledigt |

## 3. Fachliche Abnahme (Vorschau gegen TEST)

| # | Testzugang | Schritt | Erwartet | Ergebnis |
|---|---|---|---|---|
| 1 | Referent:in | `/schnittstellen` | „Kein Zugriff“; Startseite ohne Kachel „Schnittstellen“ | offen (PO) |
| 2 | Geschäftsstelle | `/schnittstellen` | Anbindung „E-Mail Test“ (abgeschaltet), keine Schaltflächen; Vorlagen ohne Text; Postausgang ohne „Inhalt“ | offen (PO) |
| 3 | Admin | Anbindung „E-Mail Test“ → „Key hinterlegen“ mit dem TEST-Key von Brevo | „hinterlegt: …“ mit 4 Zeichen; Key nicht mehr sichtbar | offen (PO) |
| 4 | Admin | „aktivieren“ vor dem Test | „Bitte zuerst einen erfolgreichen Test durchführen.“ (R3) | offen (PO) |
| 5 | Admin | „Test-E-Mail senden“ | „Test erfolgreich“; E-Mail im Posteingang von `test.admin@` (nicht Junk); Absender `noreply@vereinsos.dav-leipzig.de` | offen (PO) |
| 6 | Admin | „aktivieren“ | Zustand „aktiv“ | offen (PO) |
| 7 | Admin | Vorlage „Anmeldung des Notfall-Admins“: `{vorname}` einfügen, speichern | „Der Platzhalter {vorname} ist für diesen Anlass nicht erlaubt.“ (R8) | offen (PO) |
| 8 | Notfall-Admin | anmelden | nach höchstens 10 Minuten E-Mail „Anmeldung des Notfall-Admins“ bei `test.admin@` (ohne Namen); Postausgang „versendet“ | offen (PO) |
| 9 | Admin | Postausgang: fehlgeschlagene Seed-E-Mail „erneut senden“ | Zustand „wartet“, danach „versendet“ | offen (PO) |
| 10 | Admin | „Key wechseln“ mit ungültigem Key, „Test-E-Mail senden“ | „gestört“, Fehler „401 …“; Hinweis auf der Startseite (auch Geschäftsstelle) | offen (PO) |
| 11 | Admin | gültigen Key wieder hinterlegen, Test | wieder „aktiv“ | offen (PO) |
| 12 | Admin | Protokoll | Einträge zu Key, Test, Versand, Vorlage; Key und Inhalt nie sichtbar | offen (PO) |
| 13 | alle | 375 px | Seiten ohne waagerechtes Scrollen bedienbar | offen (PO) |
