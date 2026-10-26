# Abnahme-Test: Finanzen (FI) v0.2

Umsetzungsdatei zu Spec T16 ([tasks.md](tasks.md), FT16). Grundlage: spec.md v0.2 Abschnitte 6 und 9, [plan.md](plan.md). Stand: 26.10.2026 (vorbereitet, noch nicht durchgeführt).

Legende: **erledigt** = von Claude Code geprüft · **offen (PO)** = mit Testzugang in der Vorschau gegen TEST, führt der Product Owner aus · **wartet** = Voraussetzung fehlt.

## 1. Voraussetzungen

| Punkt | Stand |
|---|---|
| Migrationen FI (`20261031…`) und Nachträge AD v0.10, EZ v0.6 in TEST | erledigt |
| Seed `SEED_WITH_FI=1 supabase/seed.sh` in TEST | offen (PO) |
| Oberfläche AD v0.10 (PR #55: Sätze, Abrechnungsarten, Auszahlung, „darf freigeben“) gemergt | wartet |
| Oberfläche EZ v0.6 (PR #56: Feld „Vergütung“, „abgerechnet“) gemergt | wartet |

## 2. Automatische Prüfungen

| Prüfung | Ergebnis |
|---|---|
| `db-tests` (pgTAP 290–293, 560, 610, 620) | erledigt (grün, PR #53) |
| `npm run fi:export:test` (Überweisungsdatei: Summe, Anzahl, IDs, Zeichensatz) | erledigt (6 von 6) |
| Prüfung gegen XSD pain.001.001.03 (`PAIN001_XSD`, xmllint) | erledigt (lokal) |
| `tsc -b`, `vite build` | erledigt |

## 3. Fachliche Abnahme (Vorschau gegen TEST)

| # | Testzugang | Schritt | Erwartet (spec.md 9) | Ergebnis |
|---|---|---|---|---|
| 1 | Geschäftsstelle | /fi, 1. Halbjahr 2026, „Berechnen“ | Abrechnungen 1–7 im Entwurf; Beträge wie im Kopf von `seed-fi.sql` | offen (PO) |
| 2 | Geschäftsstelle | Clara Ablauf öffnen | 13.04. Helfer:in mit „keine förderfähige Lizenz“, Fahrt 3 Tagessätze „ohne Uhrzeit“ | offen (PO) |
| 3 | Geschäftsstelle | Mira Ohnezeit: Position korrigieren (Menge 3, Begründung) | Betrag neu, Korrektur mit Begründung sichtbar, Verlauf | offen (PO) |
| 4 | Kim Kinderjugend | /fi | sieht 1, 3, 5, 6, 7; Filter „zu bestätigen“; keine Bankdaten | offen (PO) |
| 5 | Kim Kinderjugend | Clara: „Ausnahme begründen“, dann mehrere markieren, „Bestätigen“ | Bestätigung K&J gesetzt; Paul bleibt Entwurf (LS fehlt) | offen (PO) |
| 6 | Lea Leistung | /fi, Paul und Hans bestätigen | sieht 2, 4, 6; Paul danach „bestätigt“ | offen (PO) |
| 7 | Geschäftsstelle | Ben: Leistungssport „In Vertretung bestätigen“ mit Grund | Bestätigung „in Vertretung“ | offen (PO) |
| 8 | Geschäftsstelle (dieselbe Person) | Ben abschließen | „Du hast diese Abrechnung bestätigt. Eine andere Person muss abschließen.“ | offen (PO) |
| 9 | Gerd Geschäftsstelle | Ben, Tina, Hans, Paul abschließen; Abrechnungsdokumente drucken | ein PDF, eine Person je Seite, Summe je Gruppe, Frist, Erklärung, Unterschriftsfeld | offen (PO) |
| 10 | Anwesenheitserfassung | Training von Tina öffnen | Kennzeichen „abgerechnet“, Datum und Person gesperrt, Löschen ausgegraut | offen (PO) |
| 11 | Geschäftsstelle | Abgabe erfassen (heute); bei einer Abrechnung Datum nach der Frist | Rückfrage mit Pflichtbegründung | offen (PO) |
| 12 | Geschäftsstelle | /fi/auszahlungen „Neue Runde“ (1. Halbjahr 2026) | Olga nicht auszahlbar mit Grund; 5 Auszahlzeilen (Paul zweimal) | offen (PO) |
| 13 | Geschäftsstelle | „Freigeben“ | Rückfrage mit Anzahl und Summe; Download Auszahlliste und Überweisungsdatei; Hinweis „Datei löschen“ | offen (PO) |
| 14 | Geschäftsstelle | PDF und XML vergleichen | Summe der Liste = `CtrlSum`, Zeilen = `NbOfTxs`, „sachl. richtig“ mit Bestätigungen | offen (PO) |
| 15 | Geschäftsstelle | „PDF und XML erneut abrufen“ | Warnung „bereits freigegeben“; gleiche Nachrichten-ID | offen (PO) |
| 16 | Geschäftsstelle | /fi/kletterhalle, Ort mit Punktekonto, Vormonat; Anzahl laut Rechnung eingeben, speichern | Abweichung angezeigt; Abgleich in der Liste | offen (PO) |
| 17 | Admin, Vorstand | /fi | /kein-zugriff | offen (PO) |
| 18 | alle | Telefon, 375 px | keine horizontale Verschiebung; Karten statt Tabelle | offen (PO) |
| 19 | PO | Wortlaut der Erklärung (R18) und Zeichensatz der Sparkasse (R26) | bestätigt oder geändert | offen (PO) |
