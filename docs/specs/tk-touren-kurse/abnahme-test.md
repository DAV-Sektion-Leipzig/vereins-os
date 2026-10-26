# Abnahme-Test: Planungshilfe Touren und Kurse (TK) v0.4

Umsetzungsdatei zu Spec T22 ([tasks.md](tasks.md), T025). Grundlage: spec.md v0.4 Abschnitte 4–6 und 9, Stories v0.5, [plan.md](plan.md). Stand: 27.10.2026.

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
| Prüfliste Referat Touren ([pruefliste-referat-touren.md](pruefliste-referat-touren.md)) zurück | wartet |

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
| 1 | Tina | `/tk` | Planungen 1, 3, 4, 5, 7 (nicht den Kurs, nicht abgesagt/abgeschlossen); Filter Status „alle“ zeigt auch 6, 8 | offen (PO) |
| 2 | Tina | 375 px: `/tk` | Karten statt Tabelle, ohne horizontales Scrollen | offen (PO) |
| 3 | Tina | „Hüttentour Stubaier Alpen (Test)“ öffnen | Seitenleiste: 160 € (kostendeckend), ab 5 TN, CO2 Tour 564 kg, je Person ≈ 100 kg, Klimaschutzbudget 79,00 €; Fortschritt „alles ausgefüllt“ | offen (PO) |
| 4 | Tina | Hüttentour: Schritt 6, eigenen Beitrag 150 € eintragen, 2 s warten | Hinweis „Beitrag liegt unter dem Vorschlag“; „Gespeichert … Uhr“; danach wieder leeren | offen (PO) |
| 5 | Tina | Hüttentour: „Freigeben“ mit Kommentar, dann Reiter „Verlauf“ | Status „freigegeben“; Verlauf „freigegeben von Tina Touren“; Schritt 6 „Satzstand eingefroren“ | offen (PO) |
| 6 | Tina | Reiter „Ausgaben“: Eingabeblatt, Ausschreibungstext, „PDF herunterladen“ | Kopieren je Feld; Text ohne Stornoregel, mit „Mitgliedschaft im DAV“; PDF `Tourenkonzept_2027-07-12_Huettentour-…pdf` mit Statuskasten, Abschnitten 1–9, Seitenzahlen | offen (PO) |
| 7 | Tina | „In Yolawo angelegt“ mit Nummer „YLW-TEST“ | Status „in Yolawo angelegt“; in `/ez` ein Einsatz Tour 12.–16.07.2027 mit Bernd Berg (Trainer:in, eingetragen) | offen (PO) |
| 8 | Tina | Hüttentour: Termin auf 13.07. ändern | Einsatz in `/ez` mit neuem Beginn; Verlauf „Geändert: Beginn“ | offen (PO) |
| 9 | Geschäftsstelle | in `/ez` beim Einsatz Bernd Berg „anwesend“ setzen; dann in der Planung Titel ändern | Planung gespeichert, Hinweis „Der Einsatz ist schon erfasst …“; Einsatz unverändert | offen (PO) |
| 10 | Tina | `/tk/neu`: Kurs anlegen | „Für Kurse ist das Referat Ausbildung zuständig …“ | offen (PO) |
| 11 | Tina | Neue Führungstour anlegen, „Einreichen“ | „Noch n Angaben offen.“ mit Liste; Schritt mit der ersten fehlenden Angabe öffnet sich | offen (PO) |
| 12 | Tina | Schritt 1: „Neue Person anlegen“ ohne Häkchen, dann mit Häkchen | ohne: Meldung; mit: Person als Helfer:in eingetragen (Helfersatz); in `/ea` aktiv im Referat Touren | offen (PO) |
| 13 | Tina | Schritt 3: Teilstrecke PKW mit 2 Personen, 1 Fahrzeug, 300 km | Fahrzeuge-Feld nur bei PKW; Hinweise Fahrgemeinschaft und Leipziger Richtwert | offen (PO) |
| 14 | Alex | `/tk` | nur „Vorstieg am Fels (Test)“ und „Grundkurs Hochtouren (Test)“; kein Knopf „Freigeben“ | offen (PO) |
| 15 | Alex | „Grundkurs Hochtouren (Test)“: Schritt 6 | nur Lehreinheiten, kein Vorschlag, als fehlend markiert; 20 eintragen → Vergütung 300 € (nur Bernd) | offen (PO) |
| 16 | Fritz | `/tk` | wie Tina (Referat Touren); darf freigeben und bearbeiten | offen (PO) |
| 17 | Geschäftsstelle | „Sächsische Schweiz (Test)“ | Gemeinschaftstour: Organisationspauschale 30 €, „Sektion trägt“ 30 €; in `/ez` Abrechnungsart „Gemeinschaftstour“ | offen (PO) |
| 18 | Geschäftsstelle | „Familienwanderung (Test)“ | ohne Beitrag, „Sektion trägt“ = Gesamtkosten | offen (PO) |
| 19 | Geschäftsstelle | „Absage (Test)“ löschen | gelöscht (abgesagt ohne Einsatz) | offen (PO) |
| 20 | Geschäftsstelle | `/tk/auswertung?jahr=2027`, „CSV herunterladen“ | Summenzeile; CSV mit Semikolon, Umlaute korrekt in Excel; keine Kontaktdaten | offen (PO) |
| 21 | Tina | `/tk/auswertung` | kein CSV-Knopf; nur Planungen des Referats Touren | offen (PO) |
| 22 | Admin | `/tk`, eine Planung öffnen | lesen ohne Kontakt- und Notfalldaten, keine Statusknöpfe, keine Bearbeitung | offen (PO) |
| 23 | Vorstand | `/tk` | „Kein Zugriff …“ | offen (PO) |
| 24 | Admin | `/ad/rechtevorlagen` „Freigabe Touren und Kurse“ | Zeile Planungshilfe: bearbeiten, Reichweite Referat, „darf freigeben“ | offen (PO) |
| 25 | zwei Fenster | dieselbe Planung zweimal öffnen, in beiden ändern | im zweiten Fenster „Die Planung wurde inzwischen von … geändert“ mit „Neu laden“ | offen (PO) |

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

Erst nach Abnahme und ausdrücklicher Freigabe durch den Product Owner: Migration `update public.ad_modules set is_available = true where code = 'TK'`, Anleitung „in Vorbereitung“ entfernen. PROD-Rollout der Migrationen ist weiterhin [OFFEN] O1.
