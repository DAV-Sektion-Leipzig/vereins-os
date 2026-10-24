# Abnahme-Test: Anwesenheitserfassung (EZ) v0.5

Umsetzungsdatei zu Spec T17 ([tasks.md](tasks.md), Phase „Abnahme“). Grundlage: [quickstart.md](quickstart.md) Abschnitte B–D, spec.md v0.5 Abschnitt 9. Stand: 24.10.2026 (vorbereitet, noch nicht durchgeführt).

Legende: **erledigt** = von Claude Code geprüft, Ergebnis festgehalten · **offen (PO)** = nur mit Testzugang auf dem Telefon prüfbar, führt der Product Owner aus und trägt das Ergebnis ein · **wartet** = Voraussetzung fehlt.

## 1. Voraussetzungen

| Punkt | Stand |
|---|---|
| AD T120 (Oberfläche EZ-Rechte, Orte) | wartet |
| AD T121 (Ausrollen nach TEST) | wartet |
| Migrationen `20261028…_ez_*` in TEST | wartet (Freigabe PO) |
| Seed in TEST (Einsätze 1–11) | wartet (Freigabe PO) |
| [OFFEN] Text und Link der Datenschutzhinweise, `notice_version` (plan.md O4) | wartet (PO) |

## 2. Datenbanktests (CI)

| Prüfung | Ergebnis |
|---|---|
| `db-tests` grün auf `ez-kern-datenbank` (510–590) | offen |
| Mengentest (spec.md 8) | offen |

## 3. Fachliche Abnahme (Telefon, 375 px)

| # | Testzugang | Schritt (quickstart.md D) | Erwartet | Ergebnis |
|---|---|---|---|---|
| 1 | alle | /ez | Sichtbarkeit nach spec.md 9 | offen (PO) |
| 2 | Rita | Training mit 12 Personen erfassen | < 1 Minute, Gruppe vorgeschlagen | offen (PO) |
| 3 | Rita | doppeltes Training | Rückfrage R8 | offen (PO) |
| 4 | Geschäftsstelle | Fahrten, Wettkampfbetreuung (2 Gruppen), Trainingslager | Meldungen R1, R2, R5, R30 | offen (PO) |
| 5 | Rita | Arbeitseinsatz, neue Person, Dublette, Reaktivieren | R29, Dublettendialog, R31 (Wortlaut bestätigen) | offen (PO) |
| 6 | Geschäftsstelle | Korrigieren, Löschen | R19, R15 | offen (PO) |
| 7 | Rita | Kurs von Hand | keine Teilnehmenden | offen (PO) |
| 8 | Rita | Absagen, Rücknahme | R22–R24 | offen (PO) |
| 9 | Rita | Kontrollliste Oktober 2026 | 2 Zeilen, Summe | offen (PO) |
| 10 | Rita | Netzfehler, Entwurf | Eingabe bleibt, kein Doppel | offen (PO) |
| 11 | Admin | Einsatz ansehen | nur lesen | offen (PO) |
| 12 | Vorstand | /ez | /kein-zugriff | offen (PO) |

## 4. Freischalten

Erst nach Abschnitt 3 und ausdrücklicher Freigabe des Product Owners: Migration `…_ez_module_available.sql` (`is_available = true`), Pull Request `ez-freischalten`.

| Punkt | Stand |
|---|---|
| Freigabe PO | offen |
| Migration gemergt | offen |
| Kachel auf der Startseite in TEST | offen (PO) |
