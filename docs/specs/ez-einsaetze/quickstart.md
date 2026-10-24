# Quickstart: Validierung EZ

Stand: 24.10.2026 · Phase 1 zu [plan.md](plan.md) · Grundlage: [spec.md](spec.md) v0.5, [02-stories.md](02-stories.md) v0.6

Die Datenbanktests laufen automatisch in der GitHub Action mit lokalem Stack. Die fachliche Abnahme läuft in **vereins-os-test** (Ergebnisse in [abnahme-test.md](abnahme-test.md)). Kein Schritt dieser Anleitung wird von Claude Code gegen PROD ausgeführt; gegen TEST nur nach ausdrücklicher Freigabe des Product Owners.

## A. Voraussetzungen

| # | Prüfung | Erwartet |
|---|---|---|
| 1 | AD Nachtrag v0.8.2 (Datenbank) und Gruppen bis v0.3.1 auf `main` | Migrationen bis `20261027000100` – erledigt (24.10.2026) |
| 2 | Platzhalter `ez_person_visible` liefert `false` | wird in Migration `20261028000200` ersetzt |
| 3 | AD T120 (Oberfläche EZ-Rechte, Orte, Komponenten) | offen → O2; Voraussetzung für die Abnahme |
| 4 | AD T121 (Ausrollen nach TEST) | offen; Voraussetzung für B und D |

## B. TEST auf Stand bringen

Ausführung durch den Product Owner oder auf seinen ausdrücklichen Auftrag.

| # | Schritt | Erwartet |
|---|---|---|
| 1 | `npx supabase projects list`: verknüpftes Projekt prüfen | vereins-os-test, nicht PROD |
| 2 | `npx supabase db push --linked --dry-run`, dann ohne `--dry-run` | nur die Migrationen `20261028…_ez_*` (und noch nicht ausgerollte anderer Module nach deren Freigabe) |
| 3 | `supabase/seed.sh` | Einsätze 1–11 aus spec.md 9; Personen 33 ff.; Trainingszeit Di 17:00–19:00 der Klettergruppe Test |

## C. Datenbanktests (GitHub Action)

| # | Schritt | Erwartet |
|---|---|---|
| 1 | Pull Request des Branches `ez-kern-datenbank` öffnen | Workflow `db-tests.yml` startet |
| 2 | `supabase test db` | alle Tests grün: Administration (010–280), Ehrenamtsmanagement (310–390), Gruppen (410–495), Anwesenheitserfassung (510–590) |
| 3 | Sichtbarkeitsmatrix spec.md 9 | Admin und Geschäftsstelle sehen 1–11; Rita sieht 1, 2, 4, 6–11; Vorstand keine |
| 4 | `ez_person_visible` für Rita | Namen aus 1, 2, 4, 6–11, nicht die Teilnehmer:innen aus 3 und 5 |
| 5 | Kontrollliste Kletterhalle Test 01.–31.10.2026 | 2 Zeilen: 5 bzw. 4 Teilnehmer:innen, 1 bzw. 0 Probetrainings |
| 6 | Stichtag Einsatz 8 | Teilnehmerin mit Eintritt 01.09.2026 fehlt im Roster vom 01.08.2026; Speichern mit ihr → `EZ_PARTICIPANT_NOT_IN_GROUP` |
| 7 | Mengentest `590_ez_volume` | Liste 50 Zeilen < 1 s; `ez_save_event` mit 30 Anwesenheiten < 1 s; Kontrollliste eines Monats < 1 s |

## D. Fachliche Abnahme in TEST

Frontend über die Cloudflare-Vorschau des jeweiligen Branches (bzw. `main` nach Merge), mobil 375 px. Testzugänge: Admin, Geschäftsstelle, Rita Referentin (Referat Klettern), Vorstand. Ablauf und Ergebnisfelder: [abnahme-test.md](abnahme-test.md).

| # | Story | Testzugang | Schritt | Erwartet |
|---|---|---|---|---|
| 1 | US-EZ-14, 15 | alle | /ez öffnen | Geschäftsstelle und Admin sehen 1–11, Rita ohne 3 und 5, Vorstand → /kein-zugriff |
| 2 | US-EZ-01–04, 19 | Rita, Telefon | Training Klettergruppe Test, Dienstag, Kletterhalle Test, 1 Trainerin + 5 Kinder, Probetraining „Lena“ | Gruppe vorgeschlagen (R18), „Trainingszeit: Di 17:00–19:00“, gespeichert in < 1 Minute |
| 3 | US-EZ-17 | Rita | dasselbe Training noch einmal | Rückfrage R8 mit Link; „Trotzdem speichern“ speichert |
| 4 | US-EZ-05, 06, 07, 08, 21 | Geschäftsstelle | Tagesausflug, Mehrtagesfahrt, Wettkampfbetreuung mit zwei Gruppen, Trainingslager | Meldungen R1, R2, R5, R30; organisierende Person aus der Gruppe oben |
| 5 | US-EZ-09–11 | Rita | Arbeitseinsatz anlegen, Personen eintragen, Stände setzen, neue Person ohne/mit Häkchen, Dublette „Toni Muster“, ruhende Person | R29-Meldung ohne Häkchen; Dublettendialog; Rückfrage R31 |
| 6 | US-EZ-12, 13 | Geschäftsstelle | Einsatz 2 korrigieren; Einsatzart ändern versuchen; Einsatz löschen | R19 gesperrt; Löschen mit Rückfrage; Rita sieht kein „Löschen“ |
| 7 | US-EZ-20 | Rita | Kurs von Hand mit Teilnehmer:in versuchen | keine Teilnehmenden auswählbar |
| 8 | US-EZ-22 | Rita | Einsatz 11 bearbeiten; Absage zurücknehmen; neuen Einsatz ohne Anwesende absagen; Einsatz 1 absagen | `EZ_EVENT_CANCELLED`; Rücknahme; Absage mit Grund; `EZ_CANCEL_NOT_ALLOWED` |
| 9 | US-EZ-16 | Rita | /ez/kletterhalle, Oktober 2026 | 2 Zeilen, Summenzeile |
| 10 | US-EZ-18 | Rita | Flugmodus beim Speichern; Seite neu laden | Meldung Netzfehler, Formular bleibt; Entwurf „Fortsetzen?“; kein doppelter Einsatz |
| 11 | US-EZ-15 | Admin | Einsatz öffnen | nur lesen, keine Schaltflächen |
| 12 | – | Geschäftsstelle | nach Freischalten (T17): Startseite | Kachel „Anwesenheitserfassung“ |
