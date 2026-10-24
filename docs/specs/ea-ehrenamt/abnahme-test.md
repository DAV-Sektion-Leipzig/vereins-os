# Abnahme-Test: Ehrenamtsmanagement

Umsetzungsdatei (Phase 14 und 15 in [tasks.md](tasks.md), T053–T055). Grundlage: [quickstart.md](quickstart.md) Abschnitt D. Stand: 24.10.2026. Ohne Personendaten außer den fiktiven Seed-Namen.

Legende: **bestanden** = vom Product Owner in TEST geprüft · **erledigt** = von Claude Code geprüft · **offen (PO)** = führt der Product Owner aus.

## 1. Stand in TEST

| Punkt | Stand |
|---|---|
| Frontend | Produktionsadresse `https://vereins-os.sektion-leipzig.workers.dev` (Build-Variablen TEST), Stand `main` nach PR #7 (US-EA-12 bis US-EA-15, US-EA-17/18) |
| Migrationen | `20261024000700_ea_import.sql` am 24.10.2026 per `npx supabase db push` eingespielt (Probelauf zeigte nur diese Datei); TEST verknüpft laut `npx supabase projects list` |
| Testzugänge | Admin, Geschäftsstelle, Vorstand, Referent:in (Rita Referentin, Klettern) aus dem Seed |

## 2. Fachliche Abnahme (T053, quickstart.md D)

| # | Story | Zugang | Ergebnis |
|---|---|---|---|
| 1 | US-EA-01 AK2–AK5 | alle vier | bestanden (24.10.2026) |
| 2 | US-EA-02 | Geschäftsstelle, Referent:in, 375 px | bestanden (24.10.2026) |
| 3 | US-EA-03 | Geschäftsstelle, Referent:in | bestanden (24.10.2026) |
| 4 | US-EA-04 | Geschäftsstelle, Referent:in | bestanden (24.10.2026) |
| 5 | US-EA-05, US-EA-10 | Referent:in, Geschäftsstelle | bestanden (24.10.2026) |
| 6 | US-EA-06 | Referent:in, Geschäftsstelle | bestanden (24.10.2026) |
| 7 | US-EA-07 | Geschäftsstelle | bestanden (24.10.2026) |
| 8 | US-EA-08, US-EA-09 | Geschäftsstelle, Referent:in | bestanden (24.10.2026) |
| 9 | US-EA-11, US-EA-12 | Geschäftsstelle, Referent:in | bestanden (24.10.2026) |
| 10 | US-EA-13, 14, 15 | Geschäftsstelle | bestanden (24.10.2026) |
| 11 | US-EA-17 | Admin, Skript gegen TEST | bestanden (24.10.2026): Prüfbericht für `beispiel.csv` ohne Fehler, für `beispiel-fehler.csv` mit den zwei erwarteten Fehlern |
| 12 | US-EA-18 | Admin, Skript gegen TEST | bestanden (24.10.2026): Abschlussbericht, 5 Personen angelegt |
| 13 | US-EA-19 | – | erledigt: Seed nur mit fiktiven Namen, Adressen `example.test`, Beispiel-IBAN (Personendaten-Prüfung ohne Treffer) |
| 14 | US-EA-01 AK1 | Geschäftsstelle | offen (PO): nach T055 in TEST, Startseite zeigt die Kachel „Ehrenamtsmanagement“ |

Anpassungen aus der Abnahme: keine.

Nach Schritt 12 sind die 5 Beispielpersonen in TEST. Für eine erneute Abnahme wird TEST nach quickstart.md Abschnitt B neu aufgebaut.

## 3. Querschnitt (T054) – erledigt

Geprüft auf `main` nach PR #7 (24.10.2026).

| Prüfung | Ergebnis |
|---|---|
| `npm run lint` | keine Fehler; Warnungen nur in `.claude/skills/impeccable/scripts/*` (fremde Skripte, kein Projektcode) |
| `npm run build` | ohne Fehler; Hinweis auf Chunk-Größe > 500 kB (bekannt) |
| `npm run ea:migrate:test` | 15 von 15 bestanden |
| Personendaten-Prüfung nach CLAUDE.md über `docs`, `scripts`, `supabase/seed.sql` | keine IBAN außer der Beispiel-IBAN, keine Adressen außerhalb `@dav-leipzig.de`, `example.test`, `example.org` |

## 4. Freischalten (T055)

| Punkt | Stand |
|---|---|
| Migration `20261024000800_ea_module_available.sql` | setzt `ad_modules.is_available = true` für EA |
| Tests | `010_foundation` (verfügbar: AD und EA), `020_persons_rights` (Admin sieht AD und EA), `070_scope_referate` (Prüfung „keine Kachel“ blendet EA vorübergehend aus) |
| TEST | offen (PO): nach dem Merge `npx supabase db push` gegen TEST, dann D 14 |
| PROD | nicht Claude Code: Lauf nach quickstart.md Abschnitt E, nach Klärung des Wegs der Migrationen nach PROD (O1 der Administration) |
