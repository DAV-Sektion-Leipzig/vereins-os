# Abnahme-Test: Dashboard (DS) mit Bereich Budget v0.2

Umsetzungsdatei zu Spec T19 ([tasks.md](tasks.md), DT19). Grundlage: spec.md v0.2 Abschnitte 6 und 9, [plan.md](plan.md). Stand: 27.10.2026 (durchgeführt; Abnahme durch den Product Owner am 27.10.2026).

Legende: **erledigt** = von Claude Code geprüft · **offen (PO)** = mit Testzugang in der Vorschau gegen TEST, führt der Product Owner aus · **wartet** = Voraussetzung fehlt.

## 1. Voraussetzungen

| Punkt | Stand |
|---|---|
| Migrationen DS/Budget (`20261103000100`, `20261105100100`–`…0700`, `20261106100100`) in TEST (`npx supabase db push --linked`, ggf. `--include-all`) | erledigt (PO 27.10.2026, TEST war aktuell) |
| Seed `SEED_WITH_DS=1 supabase/seed.sh` in TEST (nach `seed.sql`; für Schritt 10 auch `SEED_WITH_FI=1`) | erledigt (PO 27.10.2026; alte Budgetdaten 2026/2027 vorher gelöscht) |
| Oberfläche Phase 3 (PR #79) gemergt | erledigt |
| Testzugänge: Vorstand Test (`test.vorstand@`, Budgetpflege), Schatzmeisterin Test (`test.schatzmeisterin@`, Budgetpflege), Kim Kinderjugend (`test.kiju@`, Referent:in K&J), Rita Referentin (`test.referent@`, Klettern), Geschäftsstelle, Admin | erledigt (Seed 27.10.2026) |

## 2. Automatische Prüfungen

| Prüfung | Ergebnis |
|---|---|
| `db-tests`: pgTAP `700_ds_rights` (34) und `710_fi_budget_flow` (Rechenregeln gegen fiktiven Export, Rechte, Zustände, Fehlercodes, Vorschau, Vorjahr, Löschlauf) | erledigt (grün, PR #73, #76, #79) |
| `npm run ds:budget:test` (Parser Excel-Blatt, DATEV-CSV, `zuordnung.csv`, Zeichensatz) | erledigt (9 von 9) |
| `tsc -b`, `oxlint`, `vite build` | erledigt (PR #79) |
| Seed `seed-ds.sql` lokal zweimal (idempotent), mit EZ, FI und TK | erledigt |
| Oberfläche lokal im Browser (Playwright) mit Kim Kinderjugend, Vorstand Test, Admin | erledigt (PR #79) |

## 3. Fachliche Abnahme (Vorschau gegen TEST)

Erwartete Zahlen gelten für den Seed im laufenden Jahr J (Datenstand 30.09.J).

| # | Testzugang | Schritt | Erwartet | Ergebnis |
|---|---|---|---|---|
| 1 | Kim Kinderjugend | `/dashboard` | Sicht „Mein Referat: Kinder und Jugend“; Kacheln Plan 36.000 €, verbraucht 23.950 €; Zeilen Vergütung Aktive, Fahrten und Freizeiten (Hinweis „Herbstfreizeit …“), Material Jugend (▲ knapp); Strich bei 75 % | erledigt (PO 27.10.2026) |
| 2 | Kim Kinderjugend | Zeile „Vergütung Aktive“ | Vorschau +1.250 € schraffiert, „nicht im Ist“; Ist 15.600 € (R18) | erledigt (PO 27.10.2026) |
| 3 | Kim Kinderjugend | Budget des Vereins → Klettern → Material Klettern | nur Summen, „Einzelbuchungen siehst du nur für dein Referat.“ (R13) | erledigt (PO 27.10.2026) |
| 4 | Kim Kinderjugend | Fahrten und Freizeiten öffnen | Einzelbuchungen inkl. Storno −150 €; Suche und Sortierung | erledigt (PO 27.10.2026) |
| 5 | Kim Kinderjugend | Hinweis ändern; 501 Zeichen | gespeichert; bei 501 Zeichen Meldung „Der Hinweis darf höchstens 500 Zeichen haben.“ | erledigt (PO 27.10.2026) |
| 6 | Kim Kinderjugend | Umschichtung Vergütung Aktive → Fahrten 30.000 € | „Der Betrag ist höher als der Plan von ‚Vergütung Aktive‘.“ (R15) | erledigt (PO 27.10.2026) |
| 7 | Rita Referentin | `/dashboard`, Material Klettern | „Startgebühr Bouldercup“ mit „Vorschlag offen“; Umbuchung +200 € sichtbar | erledigt (PO 27.10.2026) |
| 8 | Vorstand Test | Budgetpflege → Anträge | Umschichtung von Kim bestätigen; eigene Umschichtung (Wettkämpfe → Material Klettern) zeigt nur „Zurückziehen“ | erledigt (PO 27.10.2026) |
| 9 | Schatzmeisterin Test | Budgetpflege → Anträge | Umschichtung von Vorstand Test bestätigen; Vorschlag von Rita „Annehmen (diese Buchung)“ → Buchung bei Wettkämpfe (Vier-Augen-Prinzip) | erledigt (PO 27.10.2026) |
| 10 | Schatzmeisterin Test | Budgetpflege → Import, Auszahlungsrunden | Runde 901 „gebucht (Abgleich)“, Runde 902 „noch nicht gebucht“; „Als gebucht markieren“ → Vorschau bei K&J weg | erledigt (PO 27.10.2026) |
| 11 | Schatzmeisterin Test | `/dashboard/verein` | nicht zugeordnet: Bürobedarf 312,50 €; Prüfung: „Export unvollständig: Konto 6340 6“; unsichere Regeln 4000–7999 und 6350 7; Leistungssport mit zwei „Vergütung Aktive“ in eigenen Gesamtbudgets | erledigt (PO 27.10.2026) |
| 12 | Schatzmeisterin Test | Zuordnung: neue Regel „6350 7“ ohne Änderung | „Für diese Kontoangabe gibt es schon eine gültige Regel. (6350 7)“; Regel 6350 7 auf „ok“ ändern → im Verlauf alte Regel beendet | erledigt (PO 27.10.2026) |
| 13 | Schatzmeisterin Test | Finanzplan: echte Struktur der Excel „Finanzen Sektion JJJJ.xlsx“ mit fiktiven Zahlen oder einer Kopie ohne Personendaten | Vorschau mit neuen/geänderten Posten; bei falscher Summenzeile „Die Summe der Budgetposten passt nicht …“ | erledigt (PO 27.10.2026) |
| 14 | Schatzmeisterin Test | Import: DATEV-Kontenblätter (Testexport ohne Echtdaten bzw. fiktiv) | Vorschau mit Zählung und Prüfung; Übernehmen ersetzt den Import | erledigt (PO 27.10.2026) |
| 15 | Vorstand Test | Jahr J+1 | Datenstand 10.03.J+1; Vorjahr am gleichen Tag mit ▲/▼ (Vergütung Aktive K&J 7.800 €) (R20) | erledigt (PO 27.10.2026) |
| 16 | Vorstand Test | „Drucken“ | A4 quer, alle Gesamtbudgets aufgeklappt, Datenstand und Druckdatum (US-DS-19) | erledigt (PO 27.10.2026) |
| 17 | Admin | Rechtevorlage „Budgetpflege“, „Referent:in“ | DS lesen + „Budget pflegen“; Referent:in DS lesen, Reichweite Referat; „Budget pflegen“ bei Reichweite Referat gesperrt | erledigt (PO 27.10.2026) |
| 18 | Person ohne DS (z. B. Freigabe Touren und Kurse) | `/dashboard` | /kein-zugriff | erledigt (PO 27.10.2026) |
| 19 | alle | Telefon, 375 px | Kacheln untereinander, Zeilen als Karten, keine horizontale Verschiebung | erledigt (PO 27.10.2026) |
| 20 | PO | Meldungstexte [OFFEN] in `contracts/error-codes.md` (Bereich Budget) | bestätigt oder geändert | offen (PO): mit der Abnahme nicht ausdrücklich bestätigt; Oberfläche nutzt die Vorschläge |

## 4. Befunde

| # | Befund | Ergebnis |
|---|---|---|
| – | noch keine | – |

## 5. Ergebnis

Abgenommen am 27.10.2026 (Product Owner). Die Schritte aus Abschnitt 3 wurden nicht einzeln protokolliert. Freigabe des Moduls mit `20261107000100_ds_available.sql`; danach zeigt die Startseite das Dashboard (US-DS-20). Offen: Schritt 20 (Meldungstexte).

Vor Echtdaten (Finanzplan und DATEV-Export der Sektion in PROD) offen: Eintrag im Verarbeitungsverzeichnis (01-erhebung.md F), rollen.md (Spalte DS, Vorlage Budgetpflege; uebergabe-administration.md D5) – beides fachliche Dokumente, Auftrag des Product Owners nötig.
