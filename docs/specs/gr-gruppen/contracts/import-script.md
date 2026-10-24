# Contract: Importskript Gruppen

Stand: 24.10.2026 · Normativ: [spec.md](../spec.md) Abschnitt 7 und US-GR-16. **Gesperrt bis zur Entscheidung über O1** ([plan.md](../plan.md)): Art der Schlüsseleingabe.

## Aufruf

```text
npm run gr:import -- --file <pfad> --dry-run
npm run gr:import -- --file <pfad> --run [--import-date TT.MM.JJJJ]
```

- `--import-date`: Standard heute; „gültig von“ der Trainingszeiten und Datum von Fotoerlaubnis und Einwilligung (A11).
- Liegt die Datei im Repository-Verzeichnis: Abbruch „Die Datei darf nicht im Repository liegen.“
- `--run` führt vorher einen Probelauf aus (Fehler → „Probelauf hat Fehler. Lauf abgebrochen.“) und fragt „Lauf gegen <Projekt-Ref> – zum Bestätigen Projekt-Ref eingeben:“.
- Schlüssel: laut spec.md aus `.env.migration.local` (`SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`); fehlt er: „Schlüssel fehlt.“ **[OFFEN] O1**: Vorschlag ist die verdeckte Abfrage beim Start wie beim EA-Skript (EA spec.md v0.2.1 Abschnitt 7).

## Ablauf

1. Excel mit `exceljs` lesen; je Tabellenblatt eine Gruppe (F1 Name, C1 Referat, H1 Trainingszeit).
2. Zeilen ab der ersten Datenzeile [ANNAHME: Zeile 3] in Spalten B–X nach spec.md 7 zerlegen; Namen der Erziehungsberechtigten am letzten Leerzeichen teilen; Telefon nach Vorwahl mobil/Festnetz.
3. Trainingszeit-Freitext nach den Mustern aus spec.md 7 in Wochentag, Beginn, Ende zerlegen; nicht eindeutig → Warnung, Gruppe ohne Trainingszeit. Zwei Zeiten am selben Wochentag → für diesen Wochentag keine Trainingszeit, Warnung im Prüfbericht beim Tabellenblatt (spec.md v0.3 Abschnitt 7, G8) [OFFEN spec.md 11: nur dieser Wochentag oder ganze Gruppe ohne Trainingszeit].
4. Strukturierte Zeilen an `gr_import_groups(p_rows, p_import_date, p_dry_run)` übergeben; die Datenbank prüft und schreibt alles in einer Transaktion.
5. Bericht `<datei>.pruefbericht.md` bzw. `<datei>.abschlussbericht.md` neben der Excel schreiben.

## `p_rows` (jsonb)

```json
[{
  "sheet": "Gruppe A",
  "group": {"name": "…", "referat": "Kinder und Jugend",
            "training_times": [{"weekday": 2, "starts_at": "16:30", "ends_at": "18:00"}],
            "training_time_warning": null},
  "rows": [{
    "row": 3,
    "child": {"first_name", "last_name", "birth_date", "member_number"},
    "guardian": {"first_name", "last_name", "street", "postal_code", "city",
                 "phone_mobile", "phone_landline", "email"},
    "emergency_contacts": [{"first_name", "last_name", "phone_mobile", "phone_landline", "email"}],
    "contract": {"account_holder", "iban", "mandate_reference", "mandate_signed_on",
                 "purpose", "monthly_amount", "starts_on"},
    "health_note": "…",
    "photo_consent": true,
    "warnings": ["…"]
  }]
}]
```

Zuordnung der Spalten und Regeln (Dubletten, Fehler, Warnungen): spec.md 7. Personen erhalten `created_in = 'script'`.

## Bericht

- Fehler (blockieren) und Warnungen je Blatt und Zeile; Zähler (Gruppen, Trainingszeiten, Personen neu/vorhanden, Teilnahmen, Verträge).
- Keine Gesundheitsangaben; IBAN nur mit den letzten 4 Stellen (A10).

## Repository

- `scripts/gr-import/` mit `index.ts`, `run.ts`, `sheet.ts`, `training-times.ts`, `report.ts` und Tests (`*.test.ts`, `npm run gr:import:test`).
- `scripts/gr-import/beispiel.xlsx` (fiktiv, alle Fälle) und das Erzeugungsskript dazu (research.md R-GR-13).
- `.gitignore`: `scripts/gr-import/*.xlsx` außer `beispiel.xlsx`, `*.pruefbericht.md`, `*.abschlussbericht.md`.
