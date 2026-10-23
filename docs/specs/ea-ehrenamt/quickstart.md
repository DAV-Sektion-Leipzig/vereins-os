# Quickstart: Validierung EA

Stand: 22.10.2026 · Phase 1 zu [plan.md](plan.md) · Grundlage: [spec.md](spec.md) v0.2, [02-stories.md](02-stories.md) v0.2

Die Datenbanktests laufen automatisch in der GitHub Action mit lokalem Stack. Die fachliche Abnahme läuft in **vereins-os-test**. Kein Schritt dieser Anleitung wird von Claude Code gegen PROD ausgeführt. Den Lauf gegen PROD (Abschnitt E) macht der Admin selbst.

## A. Voraussetzungen

| # | Prüfung | Erwartet |
|---|---|---|
| 1 | Kern der Administration auf `main` (Datenbank) | Migrationen bis `…001400`, Seed Personen 1–12 – erledigt (23.10.2026) |
| 2 | Ü1, Ü2, R3a im Kern (research.md R-EA-02) | erledigt; T0a/T0b entfallen |
| 3 | Komponenten der Administration für die Oberflächen | AD tasks.md T073, T076, T081, T082 (offen) |

## B. TEST vor der ersten EA-Migration zurücksetzen

Entscheidung des Product Owners (spec.md AD Abschnitt 9). Ausführung durch den Product Owner oder auf seinen ausdrücklichen Auftrag.

| # | Schritt | Erwartet |
|---|---|---|
| 1 | Prüfen, dass die Testdomain der Mail-Abnahme in `ad_test_login_domains` und die zugehörigen Testpersonen entfernt sind (AD quickstart.md C2) | leer |
| 2 | Mit `npx supabase projects list` prüfen, dass vereins-os-test verknüpft ist | TEST, nicht PROD |
| 3 | Datenbank neu aus allen Migrationen aufbauen (`npx supabase db reset --linked`) | alle Migrationen inkl. EA ohne Fehler |
| 4 | `supabase/seed.sh` mit dem umgestellten Seed | Personen 1–12 und 19–22, Testzugänge neu angelegt |

## C. Datenbanktests (GitHub Action)

| # | Schritt | Erwartet |
|---|---|---|
| 1 | Pull Request des Branches `ea-datenbank` öffnen | Workflow `db-tests.yml` startet |
| 2 | Seed gegen den lokalen Stack | 25 System-Eigenschaftsarten, 57 Qualifikationsarten (47 + 10), Personen 1–12 und 19–22 |
| 3 | `supabase test db` | alle Tests grün, die der Administration (010–230) und die neuen ab 310 (research.md R-EA-12) |
| 4 | Mengentest `390_ea_volume` | `ea_volunteer_list` (Referent:in, alle Filter) < 1 s, `ea_v_expiry` ein Jahr < 2 s, Detail < 1 s |

## D. Fachliche Abnahme in TEST (T21)

Bereitstellung: `npx supabase db push --linked --dry-run`, dann ohne `--dry-run` (nur EA-Migrationen; research.md R-EA-01); Frontend über die Cloudflare-Vorschau des Branches. Testzugänge aus dem Seed: Admin, Geschäftsstelle, Rita Referentin (Klettern), Vorstand.

| # | Story | Testzugang | Schritt | Erwartet |
|---|---|---|---|---|
| 1 | US-EA-01 AK2–AK5 | alle vier | /ea öffnen; /ea/gremien und /ea/eigenschaftsarten direkt aufrufen | Navigation nach Rolle; Vorstand und Referent:in auf /kein-zugriff |
| 2 | US-EA-02 | Geschäftsstelle, Referent:in | „Aktive“ öffnen, „toni“ suchen, 375 px | Listen nach spec.md Abschnitt 9; Karten ohne horizontales Scrollen |
| 3 | US-EA-03 | Geschäftsstelle, Referent:in | Filter „Trainer:in ohne gültige Lizenz“, Status „ausgeschieden“, neu laden | Max Abgelaufen; Olga „ausgeschieden seit 30.06.2025“; Filter bleiben; Referent:in ohne „ausgeschieden“ und ohne Gremium |
| 4 | US-EA-04 | Geschäftsstelle, Referent:in | Toni Muster, Karl Zweireferat, URL von Anton Muster | Kategorien und Bezeichnungen; Karl: Ausbildung ohne Bearbeiten, kein Geburtsdatum; Anton: Meldung „nicht gefunden“ |
| 5 | US-EA-05, 10 | Referent:in, Geschäftsstelle | Nina Neu anlegen; ohne Funktion speichern; „Anton Muster“, „Olga Ausgeschieden“ anlegen; Paul Nurgruppe übernehmen | Akzeptanzkriterien US-EA-05 und US-EA-10 |
| 6 | US-EA-06 | Referent:in, Geschäftsstelle | Ausgabe bei Sven anlegen und beenden; IBAN „DE00 1234“ | Akzeptanzkriterien US-EA-06 |
| 7 | US-EA-07 | Geschäftsstelle | TCSPI erfassen (15.05.2026, mit/ohne Fortbildung); Toni verlängern | 31.12.2030 bzw. 31.12.2031; alte Lizenz endet 31.10.2027 |
| 8 | US-EA-08, 09 | Geschäftsstelle, Referent:in | Toni ruhend; Karl ruhend (Bestätigung); Sven ausgeschieden zum 31.12.2026 | Akzeptanzkriterien US-EA-08 und US-EA-09 |
| 9 | US-EA-11, 12 | Geschäftsstelle, Referent:in | Lena, Max im Detail; „Ablauf“ 2027; CSV exportieren | Badges; Toni TCSPI 31.12.2027; `ablauf-2027.csv` in Excel lesbar (Umlaute, Spalten) |
| 10 | US-EA-13, 14, 15 | Geschäftsstelle | Gremien; Referat „Naturschutz“; Eigenschaftsart „Schlüssel Materiallager“ | Akzeptanzkriterien US-EA-13 bis 15 |
| 11 | US-EA-17 | Admin gegen TEST (Secret Key von TEST verdeckt eingeben) | `npm run ea:migrate -- --file scripts/ea-migrate/beispiel.csv --dry-run`; ebenso `beispiel-fehler.csv` | Prüfbericht ohne Fehler bzw. mit den zwei Fehlern |
| 12 | US-EA-18 | Admin, gegen TEST | `--run` mit `beispiel.csv`, Rückfrage mit der Ref von TEST | Abschlussbericht; 5 Personen mit `created_in = 'script'` |
| 13 | US-EA-19 | – | Seed-Daten prüfen | nur fiktive Namen, Adressen `example.test`, Beispiel-IBAN |
| 14 | US-EA-01 AK1 | Geschäftsstelle | nach T22 in TEST: Startseite | Kachel „Ehrenamtsmanagement“ |

Nach Schritt 12 sind die 5 Beispielpersonen in TEST. Für eine erneute Abnahme wird TEST nach Abschnitt B neu aufgebaut.

## E. Lauf gegen PROD (T23, nur der Admin)

Claude Code führt diesen Abschnitt nicht aus und liest keine Dateien daraus.

1. Excel-Liste zum Stichtag einfrieren, nach `vorlage.csv` übertragen (migration-aktivenliste.md). Die Datei liegt außerhalb des Repositorys oder ist durch `.gitignore` geschützt.
2. Secret Key von PROD im Supabase-Dashboard kopieren und erst bei der Abfrage des Skripts verdeckt einfügen; nicht in eine Datei oder Notiz kopieren.
3. Probelauf, Korrektur, erneuter Probelauf bis ohne Fehler.
4. `--run`, Rückfrage mit der Ref von PROD bestätigen.
5. Abschlussbericht prüfen, Excel-Liste archivieren (B10 der Erhebung). CSV und Berichte bleiben lokal beim Admin (01-erhebung.md F).
