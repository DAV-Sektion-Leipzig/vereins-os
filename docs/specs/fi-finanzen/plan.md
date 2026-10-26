# Plan: Finanzen (FI) – Oberfläche

Umsetzungsdatei zu [spec.md](spec.md) v0.2 (Tasks FT11–FT16, [tasks.md](tasks.md)). Die Datenbank (FT01–FT10) ist umgesetzt; dieser Plan hält die technischen Entscheidungen der Oberfläche fest. Stand: 26.10.2026.

## Aufbau

| Bereich | Dateien | Task |
|---|---|---|
| Zugriff, Rahmen, Meldungen | `src/features/fi/access.ts`, `FiLayout.tsx`, `errors.ts`, `rpc.ts`, `labels.ts`, `shared/` | FT11 |
| /fi Abrechnungen | `liste/` (Filter in der Adresse: `hj`, `zustand`, `gruppe`, `hinweis`, `bestaetigen`, `frist`, `seite`) | FT11 |
| /fi/abrechnung/:id | `detail/` (Dialoge Korrektur, Ausnahme, Vertretung, Abgabe; Bestätigen, Abschließen, Zurücknehmen, Verfallen) | FT12 |
| Abrechnungsdokument | `export/documents.ts`, `export/pdf.ts` | FT13 |
| /fi/auszahlungen, /fi/auszahlungen/:id | `auszahlungen/`, `export/payout.ts`, `export/payoutList.ts`, `export/sepa.ts` | FT14 |
| /fi/kletterhalle | `kletterhalle/` | FT15 |

Routen in `src/App.tsx` (Route-ID `fi`). Routenschutz: `loadFiAccess` (FI ≥ lesen in irgendeiner Reichweite), `requireFiManage` für Auszahlungsrunden und Kletterhalle. Schaltflächen nach Rechten (`ad_has_level('FI','manage')`, `ad_my_approve_referate('FI')`, je Referat `can_confirm` aus `fi_get_settlement`); die Datenbank prüft erneut.

## Entscheidungen

| # | Thema | Entscheidung | Grund |
|---|---|---|---|
| P1 | PDF-Bibliothek | `jspdf` 4.2.1 mit `jspdf-autotable` 5.0.9, per dynamischem Import (eigener Chunk, nur beim Erzeugen geladen) | Tabellen mit Seitenumbruch, wiederholtem Kopf und Fußzeile; kein Server nötig (R21: nichts gespeichert) |
| P2 | Schrift im PDF | Helvetica (Standardschrift von jsPDF, WinAnsi mit Umlauten, ß, €, „ “) statt Fira Sans | Fira Sans liegt nur als WOFF/WOFF2 vor; jsPDF braucht TTF. [ANNAHME] ausreichend für Buchhaltung und Ablage; bei Bedarf TTF einbetten |
| P3 | Logo im PDF | Logo light aus `src/assets/brand` unverändert, im Browser über Canvas als PNG eingebettet; ohne Logo weiter, falls das Bild nicht lädt | marke.md 1–3 |
| P4 | Überweisungsdatei | eigene Funktion `buildPain001` (Text-Vorlage, kein XML-Paket); Beträge in Cent summiert; Zeichensatz nach EPC plus Erweiterung der Deutschen Kreditwirtschaft (Umlaute, ß, & * $ %), sonst Akzente entfernt bzw. Leerzeichen; `CreDtTm` in Europe/Berlin mit Zeitzone | R26, R28; Prüfung gegen das XSD pain.001.001.03 bestanden (lokal, siehe Test) |
| P5 | Test der Überweisungsdatei | `npm run fi:export:test` (Node-Testrunner über tsx, wie `ea:migrate:test`): Summe = `CtrlSum`, Zeilen = `NbOfTxs`, IDs, Zeichensatz, Zeitzone; mit `PAIN001_XSD=<Pfad>` zusätzlich Prüfung gegen das Schema mit `xmllint`. Das XSD liegt nicht im Repo | R28; Schema extern |
| P6 | Dateinamen | `Abrechnung_UEL_{JJJJ}_{H}_{Name}.pdf` bzw. `Abrechnungen_UEL_{JJJJ}_{H}.pdf`, `Auszahlliste_UEL_{JJJJ}_{H}_Runde{n}.pdf`, `Ueberweisungen_UEL_{JJJJ}_{H}_Runde{n}.xml`; Name ohne Umlaute | spec.md 6 |
| P7 | Freigabe und Download | nach `fi_release_payout_run` sofort `fi_payout_export` und Download beider Dateien; schlägt die Erzeugung fehl, bleibt die Runde freigegeben und „PDF und XML erneut abrufen“ führt zum gleichen Ergebnis (gleiche IDs, R29) | R28, R29 |
| P8 | Filter „Gruppe“ | Gruppen mit Positionen im Halbjahr aus `fi_settlement_items` (RLS), Namen aus `gr_groups` (nur mit GR- bzw. EA-Leserecht lesbar); ohne lesbare Namen entfällt der Filter | keine weitere Lesefunktion nötig |
| P9 | Auswahl in der Runde | jede Änderung der Auswahl speichert sofort (`fi_set_payout_run_settlements`) und lädt die Vorschau neu | Vorschau = Datenbank (R24) |
| P10 | Zwischensumme je Seite | in der Auszahlliste unter der letzten Zeile jeder Seite, nur bei mehreren Seiten; Summe der Runde in der Fußzeile der Tabelle | C6 |

## Offene Punkte für die Abnahme

- Wortlaut der Erklärung auf dem Abrechnungsdokument (R18, [ANNAHME]) – Konstante `DECLARATION` in `export/documents.ts`.
- Zeichensatz der Sparkasse (R26, [ANNAHME]) – Test mit einer Datei im Online-Banking von TEST-Daten ist nicht möglich; Prüfung durch den Product Owner beim ersten echten Upload in PROD (nach Freigabe des Moduls).
- Modul in `ad_modules` erst bei der Freigabe auf verfügbar setzen (Kachel auf der Startseite).
