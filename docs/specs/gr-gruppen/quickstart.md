# Quickstart: Validierung GR

Stand: 24.10.2026 · Phase 1 zu [plan.md](plan.md) · Grundlage: [spec.md](spec.md) v0.2, [02-stories.md](02-stories.md) v0.8

Die Datenbanktests laufen automatisch in der GitHub Action mit lokalem Stack. Die fachliche Abnahme läuft in **vereins-os-test**. Kein Schritt dieser Anleitung wird von Claude Code gegen PROD ausgeführt. Den Import gegen PROD (Abschnitt E) macht der Admin selbst.

## A. Voraussetzungen

| # | Prüfung | Erwartet |
|---|---|---|
| 1 | Kern der Administration und erste EA-Migrationen auf `main` | Migrationen bis `20261024000700` – erledigt (24.10.2026) |
| 2 | Platzhalter `gr_person_visible` liefert `false` | wird in Migration `…000200` ersetzt |
| 3 | Ü5 (AD v0.8 T50, R30 für EZ) | offen → plan.md O2; EZ-Pfade in pgTAP als `todo` |
| 4 | O1 (Schlüssel des Importskripts) | offen → T18 gesperrt |

## B. TEST auf Stand bringen

Ausführung durch den Product Owner oder auf seinen ausdrücklichen Auftrag.

| # | Schritt | Erwartet |
|---|---|---|
| 1 | `npx supabase projects list`: verknüpftes Projekt prüfen | vereins-os-test, nicht PROD |
| 2 | `npx supabase db push --linked --dry-run`, dann ohne `--dry-run` | nur die Migrationen `20261025…_gr_*` |
| 3 | `supabase/seed.sh` | Gruppen „Jugendgruppe Test 1/2“, „Klettergruppe Test“, „Altgruppe Test“; Personen 23–32; Testzugang test.kiju@dav-leipzig.de |

## C. Datenbanktests (GitHub Action)

| # | Schritt | Erwartet |
|---|---|---|
| 1 | Pull Request des Branches `gr-kern-datenbank` öffnen | Workflow `db-tests.yml` startet |
| 2 | `supabase test db` | alle Tests grün: Administration (010–240), Ehrenamtsmanagement (310–390), Gruppen ab 410 (research.md R-GR-14) |
| 3 | Tabelle „Erwartete Ergebnisse“ spec.md 9 | Zeilen Admin, Geschäftsstelle, Vorstand, Vorstand mit GR lesen erfüllt; Zeilen mit EZ-Rechten als `todo` (O2) |
| 4 | Stichtage spec.md 9 | 27 im Roster Test 1 vor 40 Tagen; 31 als `trainer` in Test 2 vor 90 Tagen; Altgruppe → `GR_GROUP_NOT_FOUND`; Test 2 mittwochs 2025 17:00–18:30, 2026 18:00–19:30 |
| 5 | Gesundheitsangaben | über Admin, Vorstand mit GR lesen, Pfad AD und EA: 0 Zeilen; Person 25 (Widerruf) auch für die Geschäftsstelle 0 Zeilen |
| 6 | Mengentest `490_gr_volume` (20 Gruppen, 400 Teilnehmer:innen) | `gr_group_overview` und Gruppendetail < 1 s; `gr_group_roster` < 300 ms; Personenliste mit 500 Personen im Pfad GR < 1 s |

## D. Fachliche Abnahme in TEST

Frontend über die Cloudflare-Vorschau des jeweiligen Branches. Testzugänge: Admin, Geschäftsstelle, Vorstand, Rita Referentin, Kim Kinderjugend.

| # | Story | Testzugang | Schritt | Erwartet |
|---|---|---|---|---|
| 1 | US-GR-01, 02 | alle | /gr öffnen | Geschäftsstelle und Admin sehen die Übersicht; Vorstand, Rita, Kim → /kein-zugriff ohne Datenabfrage |
| 2 | US-GR-02 | Geschäftsstelle | Übersicht, Filter Referat, „aufgelöst“, 375 px | Zähler „Teilnahme klären“ (Ben), „Kein Notfallkontakt“ (Ben), „Aufnahme offen“ (Paula); Karten ohne horizontales Scrollen |
| 3 | US-GR-03, 04, 18 | Geschäftsstelle | Gruppe anlegen (doppelter Name, inaktives Referat); Trainingszeit „Ändern ab“; zweite Trainingszeit am selben Wochentag (wird abgelehnt), zweiter Wochentag (wird gespeichert); Gruppe mit Teilnehmer:innen auflösen | Meldungen R1, R21, R19, R9; Auflösen einer leeren Gruppe beendet Funktionen und Trainingszeiten |
| 4 | US-GR-05, 15 | Geschäftsstelle, Admin | Jugendgruppe Test 1 öffnen; E-Mail-Adressen kopieren | Admin ohne Alter und Geburtsdatum nur, wenn ohne Lesestufe; Janas Adresse genau einmal |
| 5 | US-GR-06–10, 12 | Geschäftsstelle | Kind aufnehmen: Dublette „Mia Fiktiv“; Abbruch nach Schritt 2; fortsetzen; Vertrag mit ungültiger IBAN, doppelter Mandatsreferenz | Dublettendialog mit „Vorhandene Person übernehmen“; Person unter „Aufnahmen offen“; Meldungen R5, R6, R27 |
| 6 | US-GR-11 | Geschäftsstelle | Vertrag von Mia kündigen (Rückfrage „Endet auch die Teilnahme …?“); Folgevertrag für Ben | Status „gekündigt zum …“; Ben ohne Hinweis „Teilnahme klären“ |
| 7 | US-GR-12 | Geschäftsstelle, Admin | Gesundheit bei Mia lesen; Einwilligung „nein“ setzen; Admin öffnet Mia | Text danach nicht mehr lesbar; Admin sieht den Abschnitt nie |
| 8 | US-GR-13 | Geschäftsstelle | Trainer:in zu Test 2 hinzufügen (Person ohne Status, Person ruhend) | Status „aktiv“ bzw. Hinweis „ruhend“; in /ea nur lesend mit Gruppenname |
| 9 | US-GR-14 | Geschäftsstelle, Smartphone 375 px | /gr → Test 1 → Mia | Notfallkontakte oben, `tel:`-Links antippbar |
| 10 | US-GR-19, 20 | per SQL im Test bzw. später aus der Anwesenheitserfassung | `gr_group_roster`, `gr_groups_for_attendance`, `gr_my_groups` | nur Namen und Rollen; EZ-Pfade nach O2 |
| 11 | US-GR-16 | Admin gegen TEST | Probelauf und Lauf mit `scripts/gr-import/beispiel.xlsx` | erst nach O1; Prüfbericht ohne Gesundheitsangaben, IBAN gekürzt |
| 12 | US-GR-17 | – | Seed-Daten prüfen | nur fiktive Namen und Adressen, Beispiel-IBANs |
| 13 | US-GR-02 | Geschäftsstelle | nach T19 in TEST: Startseite | Kachel „Gruppen“ |

## E. Import gegen PROD (nur der Admin, nach O1)

Claude Code führt diesen Abschnitt nicht aus und liest keine Dateien daraus.

1. Bestands-Excel außerhalb des Repositorys ablegen.
2. Schlüssel nach der Entscheidung zu O1 bereitstellen.
3. Probelauf, Korrektur, erneuter Probelauf bis ohne Fehler.
4. `--run`, Rückfrage mit der Ref von PROD bestätigen.
5. Abschlussbericht prüfen; Excel und Berichte bleiben lokal beim Admin.
