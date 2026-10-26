# Abnahme-Test: Anwesenheitserfassung (EZ) v0.5

Umsetzungsdatei zu Spec T17 ([tasks.md](tasks.md), Phase „Abnahme“). Grundlage: [quickstart.md](quickstart.md) Abschnitte B–D, spec.md v0.5 Abschnitt 9. Stand: 26.10.2026 (Abnahme vom Product Owner als erfolgt erklärt; Einzelschritte nicht einzeln protokolliert).

Legende: **erledigt** = von Claude Code geprüft, Ergebnis festgehalten · **offen (PO)** = nur mit Testzugang auf dem Telefon prüfbar, führt der Product Owner aus und trägt das Ergebnis ein · **wartet** = Voraussetzung fehlt.

## 1. Voraussetzungen

| Punkt | Stand |
|---|---|
| AD T120 (Oberfläche EZ-Rechte, Orte) | erledigt |
| AD T121 (Ausrollen nach TEST) | erledigt |
| Migrationen `20261028…_ez_*` in TEST | erledigt |
| Seed in TEST (Einsätze 1–11) | erledigt (PO 26.10.2026) |
| [OFFEN] Text und Link der Datenschutzhinweise, `notice_version` (plan.md O4) | weiter offen (PO), nicht Bedingung der Abnahme |

## 2. Datenbanktests (CI)

| Prüfung | Ergebnis |
|---|---|
| `db-tests` grün auf `ez-kern-datenbank` (510–590) | erledigt (grün auf `main`) |
| Mengentest (spec.md 8) | erledigt (590, grün auf `main`) |

## 3. Fachliche Abnahme (Telefon, 375 px)

| # | Testzugang | Schritt (quickstart.md D) | Erwartet | Ergebnis |
|---|---|---|---|---|
| 1 | alle | /ez | Sichtbarkeit nach spec.md 9 | erledigt (PO 26.10.2026, ohne Einzelprotokoll) |
| 2 | Rita | Training mit 12 Personen erfassen | < 1 Minute, Gruppe vorgeschlagen | erledigt (PO 26.10.2026, ohne Einzelprotokoll) |
| 3 | Rita | doppeltes Training | Rückfrage R8 | erledigt (PO 26.10.2026, ohne Einzelprotokoll) |
| 4 | Geschäftsstelle | Fahrten, Wettkampfbetreuung (2 Gruppen), Trainingslager | Meldungen R1, R2, R5, R30 | erledigt (PO 26.10.2026, ohne Einzelprotokoll) |
| 5 | Rita | Arbeitseinsatz, neue Person, Dublette, Reaktivieren | R29, Dublettendialog, R31 (Wortlaut bestätigen) | erledigt (PO 26.10.2026, ohne Einzelprotokoll) |
| 6 | Geschäftsstelle | Korrigieren, Löschen | R19, R15 | erledigt (PO 26.10.2026, ohne Einzelprotokoll) |
| 7 | Rita | Kurs von Hand | keine Teilnehmenden | erledigt (PO 26.10.2026, ohne Einzelprotokoll) |
| 8 | Rita | Absagen, Rücknahme | R22–R24 | erledigt (PO 26.10.2026, ohne Einzelprotokoll) |
| 9 | Rita | Kontrollliste Oktober 2026 | 2 Zeilen, Summe | erledigt (PO 26.10.2026, ohne Einzelprotokoll) |
| 10 | Rita | Netzfehler, Entwurf | Eingabe bleibt, kein Doppel | erledigt (PO 26.10.2026, ohne Einzelprotokoll) |
| 11 | Admin | Einsatz ansehen | nur lesen | erledigt (PO 26.10.2026, ohne Einzelprotokoll) |
| 12 | Vorstand | /ez | /kein-zugriff | erledigt (PO 26.10.2026, ohne Einzelprotokoll) |

## 4. Freischalten

Erst nach Abschnitt 3 und ausdrücklicher Freigabe des Product Owners: Migration `…_ez_module_available.sql` (`is_available = true`), Pull Request `ez-freischalten`.

| Punkt | Stand |
|---|---|
| Freigabe PO | erledigt (26.10.2026) |
| Migration gemergt | erledigt (`20261101000100_gr_ez_fi_available.sql`, PR #60, gemeinsam mit GR und FI) |
| Kachel auf der Startseite in TEST | Migration in TEST eingespielt 26.10.2026 |

## 5. Ergebnis

Abnahme vom Product Owner am 26.10.2026 als erfolgt erklärt, zusammen mit der Abnahme Finanzen (fi-finanzen/abnahme-test.md, dort u. a. Feld „Vergütung“ und Sperre „abgerechnet“). Die Schritte aus Abschnitt 3 wurden nicht einzeln protokolliert. Weiter offen: Datenschutzhinweise (plan.md O4); Anbindung der Planungshilfe (T036–T038, Planungshilfe eingefroren).
