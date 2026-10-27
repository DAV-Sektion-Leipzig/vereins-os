# Contract: Migrationsskript der Aktivenliste

Stand: 22.10.2026 · zu [plan.md](../plan.md) · Grundlage: [spec.md](../spec.md) Abschnitt 7, [01-erhebung.md](../01-erhebung.md) C3, R15–R17, [migration-aktivenliste.md](../migration-aktivenliste.md)

Schlüssel nach spec.md v0.2.1 Abschnitt 7: verdeckte Eingabe beim Start, nie gespeichert. Ausführung nur durch den Admin.

## Aufruf

```
npm run ea:migrate -- --file <pfad> --dry-run [--cutoff TT.MM.JJJJ]
npm run ea:migrate -- --file <pfad> --run     [--cutoff TT.MM.JJJJ]
```

| Fall | Verhalten |
|---|---|
| Start | Abfrage „Projekt-URL:“ (sichtbar) und „Secret Key:“ (verdeckt) [ANNAHME: Wortlaut]; leere oder ungültige URL → Abbruch mit Hinweis |
| Secret Key leer | Abbruch „Schlüssel fehlt.“ (US-EA-18 AK6) |
| weder `--dry-run` noch `--run` bzw. beide | Abbruch mit Hinweis zum Aufruf |
| Pflichtspalte der Vorlage fehlt | Abbruch „Spalte <name> fehlt.“, kein Bericht (US-EA-17 AK5) |
| `--dry-run` | RPC `ea_import_volunteers(rows, cutoff, true)` → `<datei>.pruefbericht.md` |
| `--run` | Rückfrage „Lauf gegen <Projekt-Ref> – zum Bestätigen Projekt-Ref eingeben:“; falsche Eingabe → Abbruch; interner Probelauf; bei Fehlern „Probelauf hat Fehler. Lauf abgebrochen.“; sonst RPC mit `p_dry_run = false` → `<datei>.abschlussbericht.md` |

Exitcode 0 nur bei einem Probelauf ohne Fehler bzw. bei einem geschriebenen Lauf.

### Wiederholungsschutz und Fehler beim Lauf (Befund B-07, Migration `20261108000400_ea_import_once.sql`)

Der Import ist einmalig. Gibt es bereits Personen mit `created_in = 'script'`, legt ein zweiter Lauf nichts an:

| Fall | Datenbank | Skript |
|---|---|---|
| Probelauf nach erfolgtem Import | Fehler im Bericht mit `row = 0`, `code = 'EA_IMPORT_ALREADY_RUN'`: „Der Import wurde bereits ausgeführt (<n> Personen aus dem Migrationsskript vorhanden). Ein zweiter Lauf würde alle Personen doppelt anlegen.“ | Ausgabe „Der Import wurde bereits ausgeführt. Ein zweiter Lauf würde alle Personen doppelt anlegen.“; bei `--run` danach „Probelauf hat Fehler. Lauf abgebrochen.“ |
| schreibender Aufruf nach erfolgtem Import | `raise exception 'EA_IMPORT_ALREADY_RUN'` (SQLSTATE `P0001`), nichts geschrieben; gleichzeitige Läufe sperren sich gegenseitig (`pg_advisory_xact_lock`) | „Der Import wurde bereits ausgeführt. Ein zweiter Lauf würde alle Personen doppelt anlegen. Lauf abgebrochen, nichts geschrieben.“ |
| schreibender Aufruf, Datenbank antwortet mit Fehler (Fehlercode vorhanden) | Transaktion zurückgerollt (A3) | „Aufruf fehlgeschlagen, nichts geschrieben: <Meldung>“ |
| schreibender Aufruf ohne auswertbare Antwort (Netzwerk, Timeout, Gateway) | Ergebnis unbekannt: die Transaktion kann durchgelaufen sein | „Aufruf fehlgeschlagen: <Meldung>. Ergebnis unbekannt – bitte in TEST bzw. PROD prüfen, bevor der Lauf wiederholt wird.“ |

Alle Fälle enden mit Exitcode 1.

## Übergabe an die Datenbank

`p_rows` ist ein JSON-Array, je CSV-Zeile ein Objekt:
- `row` = Zeilennummer der Datei, Kopfzeile = 1.
- Spaltennamen unverändert.
- Datum als `YYYY-MM-DD`; ja/nein als boolean.
- `referate` als Array von Namen; `qualifikationen` als Array von Objekten `{code, date, valid_until, detail}`.
- Jahresspalten als Objekt `{"fb": {"2019": "…"}, "marke": {…}, "foerderung": {…}, "jahreskarte": {…}}`; `fb_vor_2016` als Jahr `2015` mit Titelzusatz.
- Leere Zellen fehlen im Objekt.

Formatfehler (Datum nicht lesbar, ja/nein erwartet) meldet das Skript vor dem RPC-Aufruf als Fehler mit Zeilennummer. Die Zeile wird dann trotzdem übergeben, ohne den fehlerhaften Wert, damit der Bericht alle übrigen Befunde enthält. Ein Lauf ist bei Formatfehlern nicht möglich.

## Zuordnung CSV → Personenmodell (beim Schreiben)

Stichtag = `p_cutoff`. „gv“ = `valid_from`, „gb“ = `valid_to`. Eigenschaftsarten über `system_key` (data-model.md).

| CSV | Ziel | Werte |
|---|---|---|
| `nachname`, `vorname`, `rufname` | `ea_persons` | `kind = 'human'`, `created_in = 'script'`, `created_by = null` |
| `aktiv` | Ehrenamtsstatus | ja → `active`, nein → `dormant`; `volunteer_status_since` = Stichtag; ein Eintrag in `ea_volunteer_status_history` |
| `referate` (+ `aktiv_seit`, `te_pro_woche`) | `function`, je Referat eine Eigenschaft | `function` = „Trainer:in“, wenn mindestens eine Lizenz (L1–L3, auch abgelaufen), sonst „Helfer:in“ (R15); `related_referat_id`; gv = `aktiv_seit` oder Stichtag; `training_units_per_week` nur bei Trainer:in |
| `mitgliedsnummer` | `member` | `is_member = true`, `member_number`; gv = Stichtag |
| `geburtsdatum` | `birth_date` | `date`; gv = Stichtag |
| `geschlecht` | `gender` | Auswahlwert; gv = Stichtag |
| `email` … `dav_email` | `contact` (eine Eigenschaft) | Feldschlüssel nach C2 Nr. 4; gv = Stichtag |
| `kontoinhaber`, `iban` | `bank_account` | `iban` normalisiert (R13); gv = Stichtag |
| `l<n>_art`, `_nummer`, `_gueltig_bis`, `_dosb_gueltig_bis`, `_letzte_fb`, `_erworben_am` | `license`, je n eine Eigenschaft | `qualification_type` (Kürzel oder Bezeichnung, auch historisch, Typ Lizenz), `license_number`, `valid_until` (leer → `ea_default_valid_until`, Warnung), `dosb_valid_until`, `last_training`; gv = `erworben_am` oder Stichtag |
| `qualifikationen` | `qualification`, je Eintrag | `qualification_type`, `valid_until`, `detail`; gv = Datum oder Stichtag |
| `fb_<jahr>`, `fb_vor_2016` | `further_training`, je gefüllter Zelle | `year`, `title` = Zellinhalt (bei „vor 2016“: Zusatz „vor 2016“); gv = 01.01. des Jahres |
| `ausweis_nr`, `ausweis_kopie` | `id_card` | `card_number`, `copy_available`; gv = Stichtag |
| `fz_ausgestellt`, `fz_eingesehen` | `police_clearance` | `issued_on`; gv = `fz_eingesehen` oder Stichtag (Bericht zählt) |
| `ehrenkodex`, `trainervereinbarung` | `code_of_conduct`, `trainer_agreement` | `signed = true`; gv = Datum |
| `marke_<jahr>` | `license_stamp` | `year`; gv = Datum |
| `foerderung_<jahr>` | `funding` | `year`, `applied` |
| `jahreskarte_<jahr>` | `issued_item` | `item` = „Jahreskarte“, `year`; gv = Datum |
| `ehrenamtspass_ausgegeben`, `ehrenamtspass_gueltig_bis` | `volunteer_pass` | `valid_until`; gv = ausgegeben |
| `schluessel_nolimit`, `schluessel_k4`, `k4_karte`, `vereinsjacke` (+ `<spalte>_am`) | `issued_item` | `item` je Spalte, `number` (außer „x“); gv = `<spalte>_am` oder Stichtag |
| `dav360`, `forms`, `jdav_verteiler`, `redaktion`, `mailingliste` | `external_access` | `system` je Spalte; gv = Datum oder Stichtag („x“) |
| `jugendausschuss` (+ `_seit`) | `committee` | ja → Gremium Jugendausschuss, `role` = „Mitglied“; gv = `_seit` oder Stichtag |
| `auszeichnung_art`, `auszeichnung_datum` | `award` | `kind`; gv = Datum oder Stichtag |
| `gruppe`, `gruppenleitung` | – | nur Warnung im Bericht (Gruppen-Import) |

`[OFFEN]`-Punkte aus 01-erhebung.md (Fördergeber, Jahreskarte, Systeme) betreffen nur die Bedeutung, nicht die 1:1-Übernahme.

## Prüfungen (Fehler verhindern den Lauf, Warnungen nicht)

| Prüfung | Art | Meldung im Bericht |
|---|---|---|
| Nachname, Vorname, aktiv leer | Fehler | „Zeile <n>: <Spalte> fehlt“ |
| Referat unbekannt oder inaktiv | Fehler | „Zeile <n>: Referat <wert> unbekannt“ |
| Qualifikationsart unbekannt | Fehler | „Zeile <n>: Qualifikationsart <wert> unbekannt“ (US-EA-17 AK2) |
| `l*_art` kein Typ Lizenz | Fehler | „Zeile <n>: <wert> ist keine Lizenz“ |
| IBAN ungültig | Fehler | „Zeile <n>: Die IBAN ist ungültig.“ |
| Auswahlwert unbekannt (Geschlecht u. a.) | Fehler | „Zeile <n>: Wert <wert> für <Feld> unbekannt“ |
| Datum oder ja/nein nicht lesbar (Skript) | Fehler | „Zeile <n>: <Spalte> nicht lesbar“ |
| Import bereits ausgeführt (Personen mit `created_in = 'script'` vorhanden) | Fehler (Code `EA_IMPORT_ALREADY_RUN`) | „Der Import wurde bereits ausgeführt (<n> Personen aus dem Migrationsskript vorhanden). Ein zweiter Lauf würde alle Personen doppelt anlegen.“ |
| Dublettenverdacht (Datenbank oder Datei) | Warnung | „Zeile <n>: Dublettenverdacht zu <Name> (vorhanden \| Zeile <m>)“ (US-EA-17 AK3) |
| mehr Lizenzen als Lizenznummern | Warnung | „Zeile <n>: <k> Lizenzen, <m> Lizenznummern“ |
| Lizenz ohne „gültig bis“ | Warnung | „Zeile <n>: Lizenz <code> ohne gültig bis, berechnet <datum>“ |
| Werte in `gruppe`/`gruppenleitung` | Warnung | „Zeile <n>: Gruppe <wert>“ |
| Anzahl Eigenschaften mit gv = Stichtag | Zählung | im Abschnitt „Zusammenfassung“ (R17) |

Wortlaut: Fest vorgegeben sind nur „Qualifikationsart <wert> unbekannt“ und „Dublettenverdacht“ (US-EA-17), „Spalte <name> fehlt.“, „Schlüssel fehlt.“, „Probelauf hat Fehler. Lauf abgebrochen.“ und die Rückfrage (spec.md Abschnitt 7). Die übrigen Texte sind ein Vorschlag [ANNAHME] für einen Bericht, den nur der Admin liest.

## Berichte

Markdown neben der CSV, mit Abschnitten Kopf (Datei, Projekt-Ref, Stichtag, Zeitpunkt, Probelauf/Lauf), Fehler, Warnungen, Zusammenfassung (Personen, Eigenschaften je Art, gv = Stichtag). Sie enthalten Namen und bleiben lokal (`.gitignore`).

## Dateien im Repository

- `scripts/ea-migrate/vorlage.csv`: nur Kopfzeile.
- `scripts/ea-migrate/beispiel.csv`: 5 fiktive Zeilen nach spec.md Abschnitt 9.
- `scripts/ea-migrate/beispiel-fehler.csv`: unbekanntes Kürzel, ungültige IBAN.

Fiktive Namen; IBAN nur `DE89370400440532013000`; E-Mail-Adressen nur `@example.test` (CLAUDE.md, Personendaten-Prüfung).
