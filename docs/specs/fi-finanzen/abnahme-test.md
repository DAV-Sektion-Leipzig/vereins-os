# Abnahme-Test: Finanzen (FI) v0.2

Umsetzungsdatei zu Spec T16 ([tasks.md](tasks.md), FT16). Grundlage: spec.md v0.2 Abschnitte 6 und 9, [plan.md](plan.md). Stand: 26.10.2026 (durchgeführt; Abnahme durch den Product Owner am 26.10.2026).

Legende: **erledigt** = von Claude Code geprüft · **offen (PO)** = mit Testzugang in der Vorschau gegen TEST, führt der Product Owner aus · **wartet** = Voraussetzung fehlt.

## 1. Voraussetzungen

| Punkt | Stand |
|---|---|
| Migrationen FI (`20261031…`) und Nachträge AD v0.10, EZ v0.6 in TEST | erledigt |
| Seed `SEED_WITH_FI=1 supabase/seed.sh` in TEST | erledigt (PO 26.10.2026) |
| Oberfläche AD v0.10 (PR #55: Sätze, Abrechnungsarten, Auszahlung, „darf freigeben“) gemergt | erledigt |
| Oberfläche EZ v0.6 (PR #56: Feld „Vergütung“, „abgerechnet“) gemergt | erledigt |

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
| 1 | Geschäftsstelle | /fi, 1. Halbjahr 2026, „Berechnen“ | Abrechnungen 1–7 im Entwurf; Beträge wie im Kopf von `seed-fi.sql` | erledigt (PO 26.10.2026) |
| 2 | Geschäftsstelle | Clara Ablauf öffnen | 13.04. Helfer:in mit „keine förderfähige Lizenz“, Fahrt 3 Tagessätze „ohne Uhrzeit“ | erledigt (PO 26.10.2026) |
| 3 | Geschäftsstelle | Mira Ohnezeit: Position korrigieren (Menge 3, Begründung) | Betrag neu, Korrektur mit Begründung sichtbar, Verlauf | erledigt (PO 26.10.2026) |
| 4 | Kim Kinderjugend | /fi | sieht 1, 3, 5, 6, 7; Filter „zu bestätigen“; keine Bankdaten | erledigt (PO 26.10.2026) |
| 5 | Kim Kinderjugend | Clara: „Ausnahme begründen“, dann mehrere markieren, „Bestätigen“ | Bestätigung K&J gesetzt; Paul bleibt Entwurf (LS fehlt) | erledigt (PO 26.10.2026) |
| 6 | Lea Leistung | /fi, Paul und Hans bestätigen | sieht 2, 4, 6; Paul danach „bestätigt“ | erledigt (PO 26.10.2026) |
| 7 | Geschäftsstelle | Ben: Leistungssport „In Vertretung bestätigen“ mit Grund | Bestätigung „in Vertretung“ | erledigt (PO 26.10.2026) |
| 8 | Geschäftsstelle (dieselbe Person) | Ben abschließen | „Du hast diese Abrechnung bestätigt. Eine andere Person muss abschließen.“ | erledigt (PO 26.10.2026) |
| 9 | Gerd Geschäftsstelle | Ben, Tina, Hans, Paul abschließen; Abrechnungsdokumente drucken | ein PDF, eine Person je Seite, Summe je Gruppe, Frist, Erklärung, Unterschriftsfeld | erledigt (PO 26.10.2026) |
| 10 | Anwesenheitserfassung | Training von Tina öffnen | Kennzeichen „abgerechnet“, Datum und Person gesperrt, Löschen ausgegraut | erledigt (PO 26.10.2026) |
| 11 | Geschäftsstelle | Abgabe erfassen (heute); bei einer Abrechnung Datum nach der Frist | Rückfrage mit Pflichtbegründung | erledigt (PO 26.10.2026) |
| 12 | Geschäftsstelle | /fi/auszahlungen „Neue Runde“ (1. Halbjahr 2026) | Olga nicht auszahlbar mit Grund; 5 Auszahlzeilen (Paul zweimal) | erledigt (PO 26.10.2026) |
| 13 | Geschäftsstelle | „Freigeben“ | Rückfrage mit Anzahl und Summe; Download Auszahlliste und Überweisungsdatei; Hinweis „Datei löschen“ | erledigt (PO 26.10.2026) |
| 14 | Geschäftsstelle | PDF und XML vergleichen | Summe der Liste = `CtrlSum`, Zeilen = `NbOfTxs`, „sachl. richtig“ mit Bestätigungen | erledigt (PO 26.10.2026) |
| 15 | Geschäftsstelle | „PDF und XML erneut abrufen“ | Warnung „bereits freigegeben“; gleiche Nachrichten-ID | erledigt (PO 26.10.2026) |
| 16 | Geschäftsstelle | /fi/kletterhalle, Ort mit Punktekonto, Vormonat; Anzahl laut Rechnung eingeben, speichern | Abweichung angezeigt; Abgleich in der Liste | erledigt (PO 26.10.2026) |
| 17 | Admin, Vorstand | /fi | /kein-zugriff | erledigt (PO 26.10.2026) |
| 18 | alle | Telefon, 375 px | keine horizontale Verschiebung; Karten statt Tabelle | erledigt (PO 26.10.2026) |
| 19 | PO | Wortlaut der Erklärung (R18) und Zeichensatz der Sparkasse (R26) | bestätigt oder geändert | erledigt (PO 26.10.2026) |

## 4. Befunde

| # | Befund | Ergebnis |
|---|---|---|
| B1 | Auszahlungsrunde zeigte keine Abrechnung, obwohl eine abgeschlossen war: Runden nehmen nur abgegebene Abrechnungen (spec.md 4); die Oberfläche erklärte das nicht | PR #58: Hinweis auf abgeschlossene, nicht abgegebene Abrechnungen mit Link |
| B2 | Hinweis-Abzeichen mit langem Text abgeschnitten | PR #58: Umbruch |

## 5. Ergebnis

Abgenommen am 26.10.2026 (Product Owner). Die Freigabe des Moduls (`ad_modules.is_available`) folgt gesondert.
