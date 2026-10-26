# Abnahme-Test: Planungshilfe Touren und Kurse (TK) v0.4

Umsetzungsdatei zu Spec T22 ([tasks.md](tasks.md), T025). Grundlage: spec.md v0.4 Abschnitte 4–6 und 9, Stories v0.5, [plan.md](plan.md). Stand: 27.10.2026 (durchgeführt; Abnahme durch den Product Owner am 27.10.2026; freigeschaltet).

Legende: **erledigt** = von Claude Code geprüft · **offen (PO)** = mit Testzugang gegen TEST, führt der Product Owner aus · **wartet** = Voraussetzung fehlt.

Zugänge (fiktiv, Seed): `test.touren@` Tina Touren (Referent:in Touren + Freigabe), `test.ausbildung@` Alex Ausbildung (Referent:in Ausbildung, ohne Freigabe), `test.freigabe@` Fritz Freigabe (nur Freigabe Touren), `test.geschaeftsstelle@` Anna Fiktiv, `test.admin@` Test Admin, `test.vorstand@` Bernd Beispiel. Passwort wie bei den übrigen Testzugängen.

Bis zur Freischaltung hat die Planungshilfe **keine Kachel**: `/tk` direkt aufrufen (TEST bzw. https://vereins-os.sektion-leipzig.workers.dev/tk nach dem Rollout von main – dort aber nur mit TEST-Daten, nie PROD).

## 1. Voraussetzungen

| Punkt | Stand |
|---|---|
| Nachträge AD v0.9/v0.12 (`20261104…`) und EZ v0.7 in TEST | erledigt (PR #74, #77) |
| Datenbank TK (`20261105…`, `20261106…`) in TEST | erledigt (PR #75, #77) |
| Seed `SEED_WITH_TK=1 supabase/seed.sh` in TEST (Planungen 1–9, Einsatz zu Planung 5) | erledigt (27.10.2026) |
| Oberfläche Stufe 4 und 5 gemergt (PR #80, #82) | erledigt |
| Prüfliste Referat Touren ([pruefliste-referat-touren.md](pruefliste-referat-touren.md)) zurück | wartet – kein Hindernis für die Freischaltung (Product Owner 27.10.2026); Werte des Prototyps gelten bis dahin |

## 2. Automatische Prüfungen

| Prüfung | Ergebnis |
|---|---|
| `db-tests`: pgTAP 294 (AD), 800–860 (TK, 250 Prüfungen) | erledigt (grün) |
| `npm run tk:calc:test` (Kalkulation und Texte, 13 Tests; gleiche Werte wie pgTAP 820) | erledigt |
| `tsc -b`, `oxlint`, `vite build` | erledigt |
| Prototyp-Beispiel (Planung 1): 735 €, Vorschlag 160 €, ab 5 TN, 18,71 € / 470,93 €, CO2 564,3 kg, 79,00 € | erledigt (Datenbank und calc.ts) |

## 3. Fachliche Abnahme (TEST, Desktop und 375 px)

| # | Zugang | Schritt | Erwartet | Ergebnis |
|---|---|---|---|---|
| 1 | Tina | `/tk` | Planungen 1, 3, 4, 5, 7 (nicht den Kurs, nicht abgesagt/abgeschlossen); Filter Status „alle“ zeigt auch 6, 8 | erledigt (PO 27.10.2026) |
| 2 | Tina | 375 px: `/tk` | Karten statt Tabelle, ohne horizontales Scrollen | erledigt (PO 27.10.2026) |
| 3 | Tina | „Hüttentour Stubaier Alpen (Test)“ öffnen | Seitenleiste: 160 € (kostendeckend), ab 5 TN, CO2 Tour 564 kg, je Person ≈ 100 kg, Klimaschutzbudget 79,00 €; Fortschritt „alles ausgefüllt“ | erledigt (PO 27.10.2026) |
| 4 | Tina | Hüttentour: Schritt 6, eigenen Beitrag 150 € eintragen, 2 s warten | Hinweis „Beitrag liegt unter dem Vorschlag“; „Gespeichert … Uhr“; danach wieder leeren | erledigt (PO 27.10.2026) |
| 5 | Tina | Hüttentour: „Freigeben“ mit Kommentar, dann Reiter „Verlauf“ | Status „freigegeben“; Verlauf „freigegeben von Tina Touren“; Schritt 6 „Satzstand eingefroren“ | erledigt (PO 27.10.2026) |
| 6 | Tina | Reiter „Ausgaben“: Eingabeblatt, Ausschreibungstext, „PDF herunterladen“ | Kopieren je Feld; Text ohne Stornoregel, mit „Mitgliedschaft im DAV“; PDF `Tourenkonzept_2027-07-12_Huettentour-…pdf` mit Statuskasten, Abschnitten 1–9, Seitenzahlen | erledigt (PO 27.10.2026) |
| 7 | Tina | „In Yolawo angelegt“ mit Nummer „YLW-TEST“ | Status „in Yolawo angelegt“; in `/ez` ein Einsatz Tour 12.–16.07.2027 mit Bernd Berg (Trainer:in, eingetragen) | erledigt (PO 27.10.2026) |
| 8 | Tina | Hüttentour: Termin auf 13.07. ändern | Einsatz in `/ez` mit neuem Beginn; Verlauf „Geändert: Beginn“ | erledigt (PO 27.10.2026) |
| 9 | Geschäftsstelle | in `/ez` beim Einsatz Bernd Berg „anwesend“ setzen; dann in der Planung Titel ändern | Planung gespeichert, Hinweis „Der Einsatz ist schon erfasst …“; Einsatz unverändert | erledigt (PO 27.10.2026) |
| 10 | Tina | `/tk/neu`: Kurs anlegen | „Für Kurse ist das Referat Ausbildung zuständig …“ | erledigt (PO 27.10.2026) |
| 11 | Tina | Neue Führungstour anlegen, „Einreichen“ | „Noch n Angaben offen.“ mit Liste; Schritt mit der ersten fehlenden Angabe öffnet sich | erledigt (PO 27.10.2026) |
| 12 | Tina | Schritt 1: „Neue Person anlegen“ ohne Häkchen, dann mit Häkchen | ohne: Meldung; mit: Person als Helfer:in eingetragen (Helfersatz); in `/ea` aktiv im Referat Touren | erledigt (PO 27.10.2026) |
| 13 | Tina | Schritt 3: Teilstrecke PKW mit 2 Personen, 1 Fahrzeug, 300 km | Fahrzeuge-Feld nur bei PKW; Hinweise Fahrgemeinschaft und Leipziger Richtwert | erledigt (PO 27.10.2026) |
| 14 | Alex | `/tk` | nur „Vorstieg am Fels (Test)“ und „Grundkurs Hochtouren (Test)“; kein Knopf „Freigeben“ | erledigt (PO 27.10.2026) |
| 15 | Alex | „Grundkurs Hochtouren (Test)“: Schritt 6 | nur Lehreinheiten, kein Vorschlag, als fehlend markiert; 20 eintragen → Vergütung 300 € (nur Bernd) | erledigt (PO 27.10.2026) |
| 16 | Fritz | `/tk` | wie Tina (Referat Touren); darf freigeben und bearbeiten | erledigt (PO 27.10.2026) |
| 17 | Geschäftsstelle | „Sächsische Schweiz (Test)“ | Gemeinschaftstour: Organisationspauschale 30 €, „Sektion trägt“ 30 €; in `/ez` Abrechnungsart „Gemeinschaftstour“ | erledigt (PO 27.10.2026) |
| 18 | Geschäftsstelle | „Familienwanderung (Test)“ | ohne Beitrag, „Sektion trägt“ = Gesamtkosten | erledigt (PO 27.10.2026) |
| 19 | Geschäftsstelle | „Absage (Test)“ löschen | gelöscht (abgesagt ohne Einsatz) | erledigt (PO 27.10.2026) |
| 20 | Geschäftsstelle | `/tk/auswertung?jahr=2027`, „CSV herunterladen“ | Summenzeile; CSV mit Semikolon, Umlaute korrekt in Excel; keine Kontaktdaten | erledigt (PO 27.10.2026) |
| 21 | Tina | `/tk/auswertung` | kein CSV-Knopf; nur Planungen des Referats Touren | erledigt (PO 27.10.2026) |
| 22 | Admin | `/tk`, eine Planung öffnen | lesen ohne Kontakt- und Notfalldaten, keine Statusknöpfe, keine Bearbeitung | erledigt (PO 27.10.2026) |
| 23 | Vorstand | `/tk` | „Kein Zugriff …“ | erledigt (PO 27.10.2026) |
| 24 | Admin | `/ad/rechtevorlagen` „Freigabe Touren und Kurse“ | Zeile Planungshilfe: bearbeiten, Reichweite Referat, „darf freigeben“ | erledigt (PO 27.10.2026) |
| 25 | zwei Fenster | dieselbe Planung zweimal öffnen, in beiden ändern | im zweiten Fenster „Die Planung wurde inzwischen von … geändert“ mit „Neu laden“ | erledigt (PO 27.10.2026) |

## 4. Zur Bestätigung bei der Abnahme

- Wortlaut der Bestätigungen c2–c4 in Schritt 7 [ANNAHME]; c1 aus dem Prototyp.
- Meldungstexte ohne Vorgabe in der Spec [ANNAHME]: `TK_STATUS_NOT_ALLOWED`, `TK_DELETE_FORBIDDEN`, `TK_EZ_SYNC_FAILED`, `TK_FIELD_INVALID`.
- Zuordnung „Trainer*in C Sportklettern“ → TCSPI, TCSP, KS (Prüfliste Nr. 4).
- Datenschutzhinweis beim Anlegen externer Leitender: Text und Link wie in der Anwesenheitserfassung, Kennung `entwurf` [OFFEN].
- Werte des Prototyps als Startbestand der Sätze, bis die Prüfliste des Referats Touren zurück ist.

## 5. Bilder der Anleitung

Die Bilder für die Abschnitte „Planungshilfe“ (Anleitung v3.0) stehen in `scripts/anleitung/screenshots.ts` (`tk-…`). Erzeugen gegen TEST bzw. die Vorschau, nie PROD:

```bash
ANLEITUNG_URL=https://<vorschau>-vereins-os.sektion-leipzig.workers.dev SEED_TEST_PASSWORD=… npm run anleitung:screenshots -- tk-
```

Danach die Bilder in `docs/anleitung/02-referentinnen.md` und `03-geschaeftsstelle.md` einbinden und den Hinweis „Bilder folgen“ entfernen (Claude Code, nach Ablage der Bilder).

## 6. Freischaltung (T026)

Freigabe durch den Product Owner am 27.10.2026: Migration `20261107000100_tk_available.sql`, `update public.ad_modules set is_available = true where code = 'TK'`, Anleitung „in Vorbereitung“ entfernen. PROD-Rollout der Migrationen ist weiterhin [OFFEN] O1.
