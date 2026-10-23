---
description: "Tasks für das Modul Ehrenamtsmanagement (EA)"
---

# Tasks: Ehrenamtsmanagement (EA)

**Input**: [plan.md](plan.md) (Stand 23.10.2026), [spec.md](spec.md) v0.2.1 (führend), [02-stories.md](02-stories.md) v0.2.1, [01-erhebung.md](01-erhebung.md) v0.5 (C2, C2a, C3, C4 verbindlich), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md), [Constitution](../../../.specify/memory/constitution.md) v1.2.0

**Voraussetzungen**: Kern der Administration auf `main` (Datenbank bis `20261023001700`, Seed Personen 1–12, Komponenten DublettenDialog, Eigenschaftsformular, QualifikationsartAuswahl, Seiten Eigenschafts- und Qualifikationsarten). Ü1, Ü2 und R3a sind umgesetzt; die Spec-Tasks T0a und T0b entfallen (plan.md).

**Tests**: Die Constitution verlangt test- und spec-getriebene Umsetzung mit pgTAP je Rechtevorlage (Arbeitsablauf Nr. 4). Vor jeder Migration steht eine Test-Task; die Tests müssen zuerst fehlschlagen. Dateien ab `310_` (010–230 gehören der Administration). Für das Frontend gilt die Abnahme in TEST (T21 der Spec); für das Migrationsskript Unit-Tests mit `node:test` über `tsx --test` (ohne Datenbank, ohne neue Test-Bibliothek).

**Organisation**: Phasen nach den Branches aus plan.md. Phase 2 ist die gemeinsame Datenbank-Grundlage (Branch `ea-datenbank`); danach eine Phase je Branch.

## Format: `- [ ] T### [P?] [US-EA-xx] (spec Tn) Beschreibung`

- **T###**: laufende Task-ID dieser Datei
- **[P]**: parallel ausführbar (andere Datei, keine offene Abhängigkeit)
- **[US-EA-xx]**: Story aus 02-stories.md
- **(spec Tn)**: Task-Nummer aus spec.md Abschnitt 10; „Teil“ = nur ein Teil davon

## Regeln für alle Tasks

- **Nie gegen PROD.** CLI-Befehle nur gegen vereins-os-test (vorher `npx supabase projects list` prüfen) oder gegen den lokalen Stack in der GitHub Action.
- **Kein `supabase config push`, kein `supabase config diff`.**
- **Bestehende Migrationen nicht ändern.** Neue Migrationen mit Präfix `20261024`, Dateiname `…_ea_*.sql` (data-model.md).
- Jede Migration: für jede neue Funktion bzw. View `revoke all … from public, anon` und `grant execute`/`grant select … to authenticated`; Ausnahme `ea_import_volunteers` nur `service_role`. security-definer-Funktionen mit `set search_path = ''` und voll qualifizierten Namen; security-invoker-Funktionen mit `set search_path = public`.
- Fachliche Fehler: `raise exception '<CODE>' using errcode = 'P0001'` (Detail für Platzhalter per `using detail = …`). Codes und Meldungen nur aus [error-codes.md der Administration](../ad-administration/contracts/error-codes.md).
- Keine Echtdaten: Namen fiktiv, E-Mail nur `@example.test`, IBAN nur `DE89370400440532013000`. `.env.local` nie lesen, anzeigen oder ändern. **Den Secret Key nie anfordern, speichern oder verwenden** (spec.md Abschnitt 7).
- Fachliche Dateien (spec.md, 02-stories.md usw.) nicht ändern; Widersprüche als `[OFFEN]` melden.
- Commits deutsch, auf dem Branch der Phase. Pull Requests legt Claude Code an (Stories, Tasks, Cloudflare-Vorschau-URL). Auto-Merge nur für PRs mit ausschließlich Migrationen, Tests, Seed und Umsetzungsdateien (CLAUDE.md).
- Oberfläche: deutsch, „du“, Datum `TT.MM.JJJJ` über `formatDate()`, Namen über `personName()` (`src/lib/format.ts`), Fehler über `toMessage()` (`src/lib/errors.ts`), Tabellen über `ResponsiveTable`, Blättern über `Pagination` (`src/components/`), ab 375 px ohne horizontales Scrollen.

---

## Phase 1: Vorbereitung (Branch `ea-datenbank`)

- [ ] T001 Branch `ea-datenbank` von aktuellem `main` anlegen. Prüfen und im PR festhalten, dass auf `main` vorhanden sind: Spalten `ea_property_types.valid_from_label`/`valid_to_label`, Funktionen `ad_first_names_match`, `ea_check_create`, `ea_set_volunteer_status`, `ea_create_volunteer`, `ea_activate_person`, `ea_property_writable`, Migration `20261023001700_ad_audit_view.sql`. Fehlt etwas: anhalten und melden.

---

## Phase 2: Datenbank-Grundlage (Branch `ea-datenbank`) – US-EA-16, US-EA-19 und Datenbankteil weiterer Stories

**Ziel**: Startbestand, Seed, View und Funktionen, auf denen alle Oberflächen aufbauen.

**Unabhängiger Test**: Action `db-tests.yml` grün mit allen Tests der Administration (010–230, nach Anpassung von 140 und 200) und den neuen Tests 310–375, 390.

### Tests (zuerst schreiben, müssen fehlschlagen) ⚠️

- [ ] T002 [P] [US-EA-16] (spec T9 Teil) `supabase/tests/database/310_ea_system_types.test.sql`:
  - genau 25 Zeilen `ea_property_types` mit `origin = 'system'` und den 25 `system_key` aus data-model.md; je Art `category`, `read_level`, `relation_kind`, `relation_required`, `allow_multiple`, `visible_in`, `valid_from_label`, `valid_to_label` exakt nach der Tabelle in data-model.md;
  - Feldschlüssel, Datentypen, Pflicht und `sort_order` je Art nach data-model.md; Auswahlwerte exakt (`gender`, `function`, `position`, `role`, `item`, `system`); `allowed_qualification_kinds`: `license.qualification_type` = `{license}`, `qualification.qualification_type` = `{add_on,course,training}`, `further_training.qualification_type` = `{license}`;
  - `employment`: `read_level = 'confidential'`, `visible_in = {AD}`;
  - jede Art hat ≥ 1 Feld;
  - Idempotenz: die interne Funktion `ea_seed_system_property_types()` (T011) in der Testtransaktion erneut aufrufen → weiterhin 25 Arten, keine doppelten Felder; eine zwischendurch per `update` geänderte Bezeichnung (`valid_from_label`) bleibt erhalten;
  - Konflikt (A7): Art „Mitglied“ ohne `system_key` anlegen (nach `delete` der Systemart innerhalb der Testtransaktion) und die Funktion erneut aufrufen → `throws_ok` mit Meldung `Eigenschaftsart Mitglied existiert bereits ohne system_key.`
- [ ] T003 [P] [US-EA-16] (spec T9 Teil) `supabase/tests/database/320_ea_qualification_types.test.sql`: EH, RS (`kind = 'training'`, `validity_years = 2`, `discipline = 'Allgemein'`, `issuer = 'extern'`), AMAK, AMBS, AMHT, AMKS, AMMB, AMSB, AMSH, AMSK (`kind = 'course'`, `validity_years` null, `discipline = 'Jugend und Familie'`, `issuer = 'Bundesverband (JDAV)'`) mit Bezeichnungen nach spec.md 2.2; alle `status = 'current'`; insgesamt 57 Zeilen; zweiter Aufruf von `ea_seed_qualification_types()` ändert nichts, eine geänderte Bezeichnung wird nicht überschrieben.
- [ ] T004 [P] [US-EA-11] (spec T9 Teil) `supabase/tests/database/330_ea_expiry.test.sql`:
  - `ea_expiry_status`: null → `none`; gestern → `expired`; heute → `expiring`; heute + 3 Monate → `expiring`; heute + 3 Monate + 1 Tag → `valid` (R9);
  - `ea_default_valid_until` (R5): TCSPI, 15.05.2026, ohne Fortbildung → 31.12.2030; mit letzter Fortbildung 10.03.2027 → 31.12.2031; Zusatzqualifikation ohne Gültigkeitsdauer → null (US-EA-07 AK1, AK2, AK5);
  - `ea_v_expiry` je Testzugang nach spec.md Abschnitt 9: Person 19 `expiring`; Person 20 Lizenz `expired`, Führungszeugnis `expiring` mit `valid_until = issued_on + 3 Jahre` (R10); Referent:in Klettern sieht keine Zeile `police_clearance` und nur Zeilen der Personen aus {4, 10, 19, 22}; Vorstand keine Zeile; beendete Eigenschaften und Person 11 (ausgeschieden) nie; Erwartungen zum Jahr 2027 aus `current_date` berechnet (research.md R-EA-06).
- [ ] T005 [P] [US-EA-02] (spec T9 Teil) `supabase/tests/database/340_ea_volunteer_list.test.sql`:
  - `ea_volunteer_list()` ohne Parameter je Testzugang exakt nach spec.md Abschnitt 9 (Admin und Geschäftsstelle 4, 5, 9, 10, 19, 20, 21, 22; Referent:in 4, 9, 10, 19, 22; Vorstand keine); Person 12 für niemanden;
  - `p_status => '{left}'`: Geschäftsstelle Person 11, Referent:in keine (R1);
  - `p_trainer_without_license => true`: Person 20, nicht 19 (R14, US-EA-03 AK2);
  - `p_search => 'toni'` liefert Person 4 (Teilwort, ohne Groß-/Kleinschreibung); `p_referate`, `p_function`, `p_position`, `p_gremium` (Person 21 bei Beirat), `p_qualification_type`, `p_discipline`, `p_expiry`, `p_without_assignment` je mit einem Treffer- und einem Nicht-Treffer-Fall; Kombination = Schnittmenge;
  - Spalten: `referate` sortiert nach `sort_order`; `functions` enthält „Trainer:in – Klettern“ bei Person 4; `license_codes` = `{TCSPI}` bei Person 4; `worst_expiry`; `total_count` = Gesamtzahl unabhängig von `p_limit`; `p_limit => 500` wird auf 200 begrenzt; Sortierung Nachname, Ruf- bzw. Vorname.
- [ ] T006 [P] [US-EA-06] (spec T9 Teil) `supabase/tests/database/350_ea_iban.test.sql`: `ea_iban_valid('DE89 3704 0044 0532 0130 00')` = true; `ea_iban_valid('DE00 1234')` = false; falsche Prüfziffer = false; `ea_iban_normalize(' de89 3704 0044 0532 0130 00 ')` = `DE89370400440532013000`; Trigger: Geschäftsstelle speichert Bankverbindung mit Leerzeichen → gespeichert ohne Leerzeichen in Großbuchstaben; ungültige IBAN → `EA_IBAN_INVALID` (US-EA-06 AK3); andere Eigenschaftsarten mit einem Feld `iban` sind nicht betroffen.
- [ ] T007 [P] [US-EA-08] (spec T9 Teil) `supabase/tests/database/360_ea_status.test.sql`:
  - `ea_change_volunteer_status`: Geschäftsstelle setzt Person 4 auf `dormant` ab 01.11.2026 → Status, `volunteer_status_since` und neuer Eintrag in `ea_volunteer_status_history` (US-EA-08 AK1); gleicher Status → `EA_STATUS_UNCHANGED` (R19); Datum > heute + 1 Jahr → `EA_STATUS_DATE` mit Detail des Grenzdatums `TT.MM.JJJJ` (R18); `left` → `EA_STATUS_FORBIDDEN`; Referent:in Klettern für Person 5 → `EA_STATUS_FORBIDDEN` (R33 AD); Vorstand → `EA_STATUS_FORBIDDEN`; Geschäftsstelle setzt Person 11 auf `active` (US-EA-10 AK3);
  - `ea_leave`: Geschäftsstelle bei Person 22 mit der Funktion → Status `left`, Funktion `valid_to` = Datum, Ausgabe und Zugang extern unverändert (US-EA-09 AK1, AK2); Referent:in Klettern bei Person 10 mit beiden Funktionen → `EA_LEAVE_PROPERTY` und nichts geändert (R20); nur mit der Klettern-Funktion → erfolgreich, Person 10 danach für die Referent:in unsichtbar (US-EA-09 AK5); ID einer anderen Person bzw. bereits beendete Eigenschaft bzw. `valid_from` nach dem Datum → `EA_LEAVE_PROPERTY`; leeres Array erlaubt.
- [ ] T008 [P] [US-EA-07] (spec T9 Teil) `supabase/tests/database/370_ea_renew.test.sql`: Geschäftsstelle verlängert die Lizenz von Person 4 mit `p_valid_from = 2027-11-01`, `p_field_values = {"valid_until":"2031-12-31","last_training":"2027-11-01"}`, `p_training = {"year":2027,"title":"Fortbildung Test"}` → neue Lizenz mit gleicher Qualifikationsart und Lizenznummer `TEST-0001`, alte `valid_to = 2027-10-31`, eine `further_training`-Eigenschaft mit `qualification_type` der Lizenz (US-EA-07 AK3); Datum nicht später als das alte `valid_from` → `EA_RENEW_INVALID`; beendete Eigenschaft → `EA_RENEW_INVALID`; Art `bank_account` → `EA_RENEW_INVALID`; Referent:in Klettern für Person 5 → abgelehnt (US-EA-07 AK6); historische Qualifikationsart (Person 5, TCSP) als Geschäftsstelle → `AD_QUALIFICATION_HISTORIC`.
- [ ] T009 [P] [US-EA-05] (O3) `supabase/tests/database/375_ea_create.test.sql`: Vorstand ruft `ea_create_volunteer` und `ea_activate_person` → `EA_CREATE_FORBIDDEN`; Referent:in Klettern ohne Eigenschaftsart oder ohne Referat → `EA_CREATE_REFERAT_REQUIRED`; mit Referat Ausbildung → `EA_RELATION_FOREIGN_REFERAT`; mit Funktion Helfer:in im Referat Klettern → Person mit Status `active` ab heute, `created_in = 'EA'` (US-EA-05 AK1); Geschäftsstelle ohne Zuordnung → erfolgreich (US-EA-05 AK3); Referent:in reaktiviert Person 11 mit Funktion Trainer:in Klettern → Status `active`, keine neue Person, Historie mit drei Einträgen (US-EA-10 AK1). Dazu in `supabase/tests/database/140_volunteer_functions.test.sql` die erwarteten Codes `EA_RELATION_REQUIRED` (Zeile „Referent:in nur mit erster Zuordnung“) → `EA_CREATE_REFERAT_REQUIRED` und `AD_FORBIDDEN` (Zeile „Vorstand legt nicht an“) → `EA_CREATE_FORBIDDEN` ändern.
- [ ] T010 [P] [US-EA-02] (spec T9 Teil) `supabase/tests/database/390_ea_volume.test.sql` nach dem Muster von `190_mengentest.test.sql` (research.md R-27 AD): 1.000 Personen mit Ehrenamtsstatus, je 30 Eigenschaften (u. a. Funktionen mit Referaten, Lizenzen mit `valid_until`); als Referent:in Klettern `ea_volunteer_list` mit allen Filtern < 1 s, `select … from ea_v_expiry` für ein Jahr < 2 s, Eigenschaften einer Person < 1 s (spec.md Abschnitt 8); Messung mit `clock_timestamp()`.

### Umsetzung

- [ ] T011 [US-EA-16] (spec T1) Migration `supabase/migrations/20261024000100_ea_system_property_types.sql` nach research.md R-EA-03 und data-model.md:
  - interne Funktion `public.ea_seed_system_property_types()` (security definer, `set search_path = ''`, `revoke all … from public, anon, authenticated`, kein Grant), die am Ende der Migration einmal aufgerufen wird;
  - Daten als `values`-Liste je Art (Name, Zweck wörtlich aus 01-erhebung.md C2, `system_key`, Kategorie, Lesestufe, Bezug, Bezug Pflicht, mehrfach, `visible_in`, Bezeichnungen aus C2a, Felder als `jsonb`-Array mit `key`, `label`, `data_type`, `is_required`, `choice_values`, `allowed_qualification_kinds`);
  - zuerst Konfliktprüfung (A7): Art mit gleichem `lower(name)` und `system_key is null` → `raise exception 'Eigenschaftsart % existiert bereits ohne system_key.', name`;
  - `insert … on conflict (system_key) do nothing returning id, system_key` als CTE; Felder nur für neu eingefügte Arten, `sort_order` über `with ordinality`;
  - Tests T002 grün.
- [ ] T012 [US-EA-16] (spec T2) Migration `…20261024000200_ea_qualification_types.sql` nach research.md R-EA-04: interne Funktion `public.ea_seed_qualification_types()` (wie T011, kein Grant), `insert … select … where not exists (select 1 from public.ad_qualification_types where lower(name) = lower(v.name))`; Aufruf am Ende; Tests T003 grün.
- [ ] T013 [US-EA-19] (spec T3) `supabase/seed.sql` nach research.md R-EA-05:
  - Testarten „Funktion (Test)“, „Amt (Test)“, „Lizenz (Test)“, „Geburtsdatum (Test)“, „Kontaktdaten (Test)“, „Hauptamt“ entfernen; alle Eigenschaften der Personen 2–12 verweisen über `(select id from public.ea_property_types where system_key = '…')` auf `function`, `position`, `license`, `birth_date`, `contact`, `employment`; Feldschlüssel unverändert; Kommentar in Zeile 9 („Testarten mit system_key … gelten nur bis zur ersten EA-Migration“) entfernen;
  - Personen 19–22 nach data-model.md (feste UUIDs im Muster der Personen 9–12), Ehrenamtsstatus mit je einem Eintrag in `ea_volunteer_status_history`, Datumswerte relativ zu `current_date` (Lena: `valid_until = current_date + interval '2 months'`; Max: `issued_on = current_date - interval '34 months'`, `valid_from = issued_on + 7`);
  - `supabase/tests/database/200_seed.test.sql` an die neue Zahl der Personen (16) und Eigenschaftsarten (25 System + 2 Test) anpassen; die Sichtbarkeits- und Dublettentests 130, 160 bleiben unverändert grün.
- [ ] T014 [US-EA-11] (spec T4) Migration `…20261024000300_ea_expiry_list.sql` nach spec.md 2.3, data-model.md und research.md R-EA-06/R-EA-07: `ea_expiry_status(date, date default current_date)` (sql, immutable), `ea_default_valid_until(uuid, date, date default null)` (sql, stable, security invoker; `make_date(extract(year from coalesce(p_last_training, p_valid_from))::int + validity_years, 12, 31)`), View `ea_v_expiry` (`security_invoker = true`, `grant select … to authenticated`), `ea_volunteer_list(…)` (sql, stable, security invoker; Parameter und Rückgabe exakt nach contracts/database-api.md), Index `ea_properties_valid_until_idx`; Tests T004, T005 grün.
- [ ] T015 [US-EA-06] (spec T5) Migration `…20261024000400_ea_iban.sql` nach research.md R-EA-08: `ea_iban_normalize`, `ea_iban_valid` (mod 97 abschnittsweise), Trigger `ea_properties_iban` (before insert or update for each row, nur bei `system_key = 'bank_account'` und `field_values ? 'iban'`); Tests T006 grün.
- [ ] T016 [US-EA-08] (spec T6) Migration `…20261024000500_ea_status_renew.sql` nach spec.md 2.3 und research.md R-EA-09: `ea_change_volunteer_status`, `ea_leave` (erst Eigenschaften prüfen und beenden, dann `ea_set_volunteer_status`), `ea_renew_property` (erst altes `valid_to`, dann neue Eigenschaft, optional `further_training`); alle security invoker; Tests T007, T008 grün.
- [ ] T017 [US-EA-05] (O3) Migration `…20261024000600_ea_check_create.sql`: `create or replace function public.ea_check_create(p_property_type uuid, p_referat uuid)` mit gleicher Signatur und Eigenschaften (security definer, stable, `set search_path = ''`, kein Grant); `AD_FORBIDDEN` → `EA_CREATE_FORBIDDEN`, `EA_RELATION_REQUIRED` → `EA_CREATE_REFERAT_REQUIRED`, `EA_RELATION_FOREIGN_REFERAT` unverändert; Tests T009 grün.
- [ ] T018 (spec T8) [contracts/error-codes.md der Administration](../ad-administration/contracts/error-codes.md), Abschnitt „Ehrenamtsmanagement“: `EA_IBAN_INVALID`, `EA_STATUS_DATE`, `EA_STATUS_UNCHANGED`, `EA_LEAVE_PROPERTY`, `EA_RENEW_INVALID` mit den Meldungen aus contracts/database-api.md (Status „umgesetzt“); Status von `EA_CREATE_FORBIDDEN`, `EA_CREATE_REFERAT_REQUIRED` auf „umgesetzt“.
- [ ] T019 Pull Request `ea-datenbank` (Auto-Merge, nur Migrationen, Tests, Seed, Umsetzungsdateien). Nach dem Merge: Product Owner setzt TEST zurück bzw. beauftragt Claude Code ausdrücklich (quickstart.md B); danach `npx supabase db push --linked --dry-run` (zeigt nur `20261024…`), `db push`, `supabase/seed.sh`.

**Checkpoint**: Datenbank und Seed des Ehrenamtsmanagements in TEST.

---

## Phase 3: US-EA-17, US-EA-18 Migration der Aktivenliste (Branch `us-ea-17-import`)

**Ziel**: Datenbankfunktion für den Import und lokales Skript mit Probelauf, Lauf und Berichten.

**Unabhängiger Test**: pgTAP 380 grün; `npm run ea:migrate:test` grün; Probelauf und Lauf des Admins gegen TEST mit den Beispieldateien nach quickstart.md D 11–12.

- [ ] T020 [P] [US-EA-17] (spec T9 Teil) `supabase/tests/database/380_ea_import.test.sql`: `authenticated` (test.admin) erhält beim Aufruf von `ea_import_volunteers` einen Rechtefehler; als `service_role` ohne `auth.uid()`: Probelauf mit 5 Beispielzeilen (als JSON wie das Skript sie liefert) → `written = false`, keine neuen Personen, `counts` je Art; Fehlerfälle unbekanntes Kürzel (`Zeile <n>: Qualifikationsart <wert> unbekannt`), `l1_art` ohne Typ Lizenz, unbekanntes Referat, ungültige IBAN, fehlender Nachname; Warnungen Dublettenverdacht zu Toni Muster und innerhalb der Datei, mehr Lizenzen als Nummern, Lizenz ohne „gültig bis“ (berechnet), `gruppe`; Lauf ohne Fehler → Personen mit `created_in = 'script'`, Status `active`/`dormant` ab Stichtag mit einem Historieneintrag, Funktion Trainer:in je Referat bei mindestens einer Lizenz, sonst Helfer:in (R15), historische Qualifikationsart TCSP erlaubt; Lauf mit einem Fehler schreibt nichts (A3).
- [ ] T021 [US-EA-17] (spec T7) Migration `…20261024000700_ea_import.sql` nach spec.md Abschnitt 7, research.md R-EA-10 und der Zuordnung in contracts/migration-script.md: `ea_import_volunteers(p_rows jsonb, p_cutoff date, p_dry_run boolean) returns jsonb`, security definer, `set search_path = ''`; `revoke execute … from public, anon, authenticated`; `grant execute … to service_role`; Dublettenverdacht über `public.ad_first_names_match`; Typprüfung Lizenz selbst; Tests T020 grün.
- [ ] T022 [P] [US-EA-17] (spec T20 Teil) `scripts/ea-migrate/columns.ts` (Pflichtspalten der Vorlage C3, Muster der Jahresspalten `^(fb|marke|foerderung|jahreskarte)_(\d{4})$` und `fb_vor_2016`) und `scripts/ea-migrate/vorlage.csv` (nur Kopfzeile, Semikolon, UTF-8).
- [ ] T023 [P] [US-EA-17] (spec T20 Teil) `scripts/ea-migrate/csv.ts`: CSV mit `csv-parse` lesen (Semikolon, Kopfzeile Pflicht), fehlende Spalte → Abbruch „Spalte <name> fehlt.“; Zeile in die Form aus contracts/migration-script.md („Übergabe an die Datenbank“) umwandeln; Formatfehler mit Zeilennummer sammeln.
- [ ] T024 [P] [US-EA-17] (spec T20 Teil) `scripts/ea-migrate/report.ts`: Prüf- bzw. Abschlussbericht als Markdown mit den Abschnitten aus contracts/migration-script.md; der Secret Key kommt im Bericht nie vor.
- [ ] T025 [US-EA-18] (spec T20 Teil) `scripts/ea-migrate/index.ts` nach spec.md v0.2.1 Abschnitt 7 und research.md R-EA-11: Argumente `--file`, `--dry-run`/`--run`, `--cutoff TT.MM.JJJJ`; Abfrage „Projekt-URL:“ sichtbar und „Secret Key:“ verdeckt über `node:readline` (Ausgabe während der Eingabe stummgeschaltet), kein Lesen aus `process.env` oder Dateien; leerer Schlüssel → „Schlüssel fehlt.“; `--run`: Rückfrage „Lauf gegen <Projekt-Ref> – zum Bestätigen Projekt-Ref eingeben:“, interner Probelauf, bei Fehlern „Probelauf hat Fehler. Lauf abgebrochen.“; Bericht `<datei>.pruefbericht.md` bzw. `<datei>.abschlussbericht.md` neben der CSV; Exitcodes nach contracts/migration-script.md.
- [ ] T026 [P] [US-EA-17] (spec T20 Teil) `scripts/ea-migrate/beispiel.csv` (5 fiktive Zeilen nach spec.md Abschnitt 9) und `scripts/ea-migrate/beispiel-fehler.csv` (unbekanntes Kürzel, ungültige IBAN); Namen fiktiv, E-Mail `@example.test`, IBAN nur `DE89370400440532013000`.
- [ ] T027 [P] [US-EA-17] (spec T20 Teil) Unit-Tests `scripts/ea-migrate/*.test.ts` mit `node:test`: Kopfzeile ohne Pflichtspalte, Datumsumwandlung, ja/nein, Liste `qualifikationen`, Jahresspalten, Formatfehler mit Zeilennummer, Bericht ohne Schlüssel; RPC-Aufruf durch eine Ersatzfunktion.
- [ ] T028 [US-EA-18] (spec T20 Teil) `package.json`: devDependencies `tsx`, `csv-parse`; Skripte `"ea:migrate": "tsx scripts/ea-migrate/index.ts"`, `"ea:migrate:test": "tsx --test scripts/ea-migrate/"`; `.gitignore`: `scripts/ea-migrate/*.csv`, `!scripts/ea-migrate/vorlage.csv`, `!scripts/ea-migrate/beispiel.csv`, `!scripts/ea-migrate/beispiel-fehler.csv`, `*.pruefbericht.md`, `*.abschlussbericht.md` (US-EA-18 AK5); `npm run lint` ohne Fehler.
- [ ] T029 [US-EA-17] Pull Request `us-ea-17-import` (kein Auto-Merge, weil `package.json` und Skript); im PR die Anleitung für den Admin: Probelauf und Lauf gegen TEST mit `beispiel.csv` und `beispiel-fehler.csv` (quickstart.md D 11–12). Claude Code führt das Skript nicht gegen eine Datenbank aus.

**Checkpoint**: Migration der Aktivenliste ist in TEST geprüft.

---

## Phase 4: US-EA-01 Navigation (Branch `us-ea-01-navigation`)

**Ziel**: Modul unter /ea mit Routenschutz und Navigation je Rolle.

**Unabhängiger Test**: Geschäftsstelle sieht sechs Navigationspunkte, Referent:in zwei; Vorstand und Referent:in landen bei /ea/gremien bzw. /ea/eigenschaftsarten auf /kein-zugriff, ohne dass Personendaten abgefragt werden (US-EA-01 AK2–AK5).

- [ ] T030 [P] [US-EA-01] (spec T10 Teil) `src/lib/errors.ts`: Meldungen für `EA_IBAN_INVALID`, `EA_STATUS_DATE` (Detail = Datum in den Platzhalter `<TT.MM.JJJJ>`), `EA_STATUS_UNCHANGED`, `EA_LEAVE_PROPERTY`, `EA_RENEW_INVALID`, `EA_CREATE_FORBIDDEN`, `EA_CREATE_REFERAT_REQUIRED` wörtlich aus contracts/error-codes.md der Administration.
- [ ] T031 [US-EA-01] (spec T10) `src/features/ea/access.ts`: Loader `loadEaAccess` (`requireSession`, dann `hasAnyLevel('EA','read')`, sonst `redirect('/kein-zugriff')`; liefert `{ canManage: hasLevel('EA','manage'), canEdit: hasLevel('EA','edit'), myReferate: rpc('ad_my_referate', {p_module:'EA', p_min:'edit'}) }`) und `requireEaManage` (sonst `/kein-zugriff`), nach dem Muster von `src/features/ad/access.ts`.
- [ ] T032 [US-EA-01] (spec T10) `src/features/ea/EaLayout.tsx`: Navigation nach A6 – mit `canManage`: Aktive · Ablauf · Gremien · Eigenschaftsarten · Qualifikationsarten · Referate und Gremien; sonst: Aktive · Ablauf; Muster `src/features/ad/AdLayout.tsx`.
- [ ] T033 [US-EA-01] (spec T10) Routen in `src/App.tsx`: `ea` mit `loader: loadEaAccess`, `element: <EaLayout />`; `index` → `redirect('/ea/aktive')`; Platzhalter für die Unterseiten (`PlaceholderPage`), die die folgenden Phasen ersetzen; `src/features/start/modules.ts`: `MODULE_PATHS` um `EA: '/ea'` ergänzen.

**Checkpoint**: /ea erreichbar und geschützt.

---

## Phase 5: US-EA-02, US-EA-03 Übersicht der Aktiven (Branch `us-ea-02-aktive`)

**Ziel**: Tabelle der Aktiven mit Suche, Filtern, URL-Zustand und Blättern.

**Unabhängiger Test**: US-EA-02 AK1–AK5 und US-EA-03 AK1–AK5 mit Geschäftsstelle und Referent:in in der Vorschau.

- [ ] T034 [US-EA-02] (spec T11) `src/features/ea/aktive/data.ts`: `readFilter(url)`/`filterHref(filter, page)` für Suche, Status, Referate, Funktion, Amt, Gremium, Qualifikationsart, Sparte, Ablauf, „ohne gültige Lizenz“, „ohne Funktion oder Amt“, Seite (A5); Loader `loadVolunteers` mit `rpc('ea_volunteer_list', …)`, `p_limit = PAGE_SIZE`, `p_offset`; Auswahllisten (`ea_referate`, `ea_gremien` nur bei `canManage`, `ad_qualification_types`); Referent:in: Referatsfilter vorbelegt mit `myReferate`, ohne Status „ausgeschieden“ und ohne Gremium (R1, US-EA-03 AK4).
- [ ] T035 [US-EA-02] (spec T11) `src/features/ea/aktive/AktivePage.tsx`: Suche ab 1 Zeichen mit 300 ms Verzögerung; Spalten Name (`personName`), Status mit „seit TT.MM.JJJJ“, Referate, Funktionen und Ämter, Lizenzkürzel, Ablauf-Badge (`worst_expiry`: abgelaufen / läuft in ≤ 3 Monaten ab / gültig / –), Kennzeichen „ohne gültige Lizenz“; Zeile öffnet /ea/aktive/:id; „Person anlegen“ nur mit `canEdit` oder eigenen Referaten; leer: „Keine Aktiven gefunden.“; `ResponsiveTable` und `Pagination`.
- [ ] T036 [P] [US-EA-03] (spec T11) `src/features/ea/aktive/Filterleiste.tsx`: Filter nach T034, mobil einklappbar; `src/features/ea/shared/AblaufBadge.tsx` (wird in Phase 6 und 10 wiederverwendet).

**Checkpoint**: Aktive finden und filtern.

---

## Phase 6: US-EA-04, US-EA-11 Person im Detail (Branch `us-ea-04-detail`)

**Ziel**: Detail mit Kopf, Statushistorie, Eigenschaften nach Kategorie und Ablaufstatus.

**Unabhängiger Test**: US-EA-04 AK1–AK6 und US-EA-11 AK1–AK5 mit Geschäftsstelle und Referent:in.

- [ ] T037 [US-EA-04] (spec T12) `src/features/ad/personen/data.ts` und `src/features/ad/personen/EigenschaftenAbschnitt.tsx` minimal erweitern, statt sie zu kopieren: `loadPersonProperties(personId, module = 'AD')` filtert `visible_in` nach dem Modul; `EigenschaftenAbschnitt` erhält optionale Props `module` und `renderExtra(property)` (Platz für Badge und zusätzliche Aktionen); Verhalten unter /ad unverändert.
- [ ] T038 [US-EA-04] (spec T12) `src/features/ea/aktive/data.ts`: Loader `loadVolunteerDetail` (Person aus `ea_persons`; nicht lesbar → Meldung „Diese Person wurde nicht gefunden oder du hast keine Rechte.“; Statushistorie aus `ea_volunteer_status_history`; Eigenschaften über `loadPersonProperties(id, 'EA')`; Ablauf aus `ea_v_expiry?person_id=eq.…`; Kennzeichen „Trainer:in ohne gültige Lizenz“ aus den geladenen Daten: aktuelle Funktion Trainer:in und keine Zeile `kind = 'license'` mit `valid_until >= heute` in `ea_v_expiry` (R14)).
- [ ] T039 [US-EA-04] (spec T12) `src/features/ea/aktive/PersonDetailPage.tsx` (/ea/aktive/:id): Kopf mit Name, Rufname, Status-Badge „aktiv seit TT.MM.JJJJ“, aufklappbare Statushistorie (wer, wann), Kennzeichen „Trainer:in ohne gültige Lizenz“; darunter `EigenschaftenAbschnitt` mit `module = 'EA'` und `renderExtra` = `AblaufBadge` bei `license`, `qualification`, `police_clearance`; Gruppen-Bezug nur lesen mit „Diese Angabe wird im Modul Gruppen gepflegt.“ (AK6).

**Checkpoint**: Detail mit Ablaufstatus.

---

## Phase 7: US-EA-05, US-EA-10 Person anlegen, Rückkehr und Übernahme (Branch `us-ea-05-person-anlegen`)

**Unabhängiger Test**: US-EA-05 AK1–AK6 und US-EA-10 AK1–AK5.

- [ ] T040 [US-EA-05] (spec T13) `src/features/ea/aktive/PersonNeuPage.tsx` (/ea/aktive/neu, Loader prüft `canEdit` oder eigene Referate): Vorname, Nachname, Rufname; erste Zuordnung Art (Funktion oder Amt über `system_key` `function`/`position`), Wert (Auswahlwerte der Art), Referat (Referent:in: nur `myReferate`, Pflicht; Geschäftsstelle/Admin: optional), „seit“ (Standard heute); R4 und R3 vor dem Aufruf prüfen; Speichern → `findSimilarPersons` → bei Treffern `DublettenDialog`, sonst `rpc('ea_create_volunteer')` → Detail.
- [ ] T041 [US-EA-10] (spec T13) Aktionen im `DublettenDialog` über `hitAction`: „Vorhandene Person öffnen“ (`is_visible`, Link /ea/aktive/:id), „Wieder aktivieren“ (`volunteer_status = 'left'`), „Ins Ehrenamtsmanagement übernehmen“ (ohne Status) → `rpc('ea_activate_person')` mit der eingegebenen Zuordnung; danach Detail; Fehler über `toMessage` (u. a. `EA_CREATE_REFERAT_REQUIRED`).

**Checkpoint**: Anlegen ohne Dubletten.

---

## Phase 8: US-EA-06, US-EA-07 Eigenschaften pflegen, Lizenz verlängern (Branch `us-ea-06-eigenschaften`)

**Unabhängiger Test**: US-EA-06 AK1–AK6 und US-EA-07 AK1–AK6.

- [ ] T042 [US-EA-06] (spec T14) Im Detail (T039) „Eigenschaft hinzufügen“, „Ändern“, „Beenden“ über `Eigenschaftsformular` und `saveProperty`: nur Arten mit `visible_in` ∋ `EA`; für Referent:innen nur `read_level = 'all'` (AK5) und `restrictReferate = myReferate` (AK4); Knöpfe nur, wenn `rpc('ea_property_writable', …)` wahr ist; „Beenden“ setzt `valid_to` (Datum, Standard heute).
- [ ] T043 [US-EA-07] (spec T14) Vorbelegung „gültig bis“ (R5) im `Eigenschaftsformular` für `system_key` `license` und `qualification`: bei Änderung von Qualifikationsart, „gültig von“ oder „letzte Fortbildung“ `rpc('ea_default_valid_until')`, solange der Nutzer das Feld nicht selbst geändert hat; Umsetzung als optionale Prop des Formulars (z. B. `onDerive`), damit /ad unverändert bleibt.
- [ ] T044 [US-EA-07] (spec T14) `src/features/ea/aktive/VerlaengernDialog.tsx`: „erworben bzw. verlängert am“ (Pflicht), „letzte Fortbildung“, „gültig bis“ (vorbelegt nach R5), optional „Fortbildung anlegen“ (Jahr, Titel) → `rpc('ea_renew_property')`; Knopf „Verlängern“ nur bei aktuellen `license`/`qualification`, deren Qualifikationsart `status = 'current'` hat (spec.md v0.2.1, O2).

**Checkpoint**: Eigenschaften mit Historie pflegbar.

---

## Phase 9: US-EA-08, US-EA-09 Status ändern und Ausscheiden (Branch `us-ea-08-status`)

**Unabhängiger Test**: US-EA-08 AK1–AK5 und US-EA-09 AK1–AK6.

- [ ] T045 [US-EA-08] (spec T15) `src/features/ea/aktive/StatusDialog.tsx`: Auswahl aktiv/ruhend/ausgeschieden ohne den aktuellen Status, Datum (Standard heute); vor dem Speichern `rpc('ea_person_referate')` und Bestätigung nach R7 („Die Person ist auch in <Referate> tätig. Der Status gilt für alle Referate.“), wenn Referate außerhalb von `myReferate` liegen (Reichweite „alle“: mehr als ein Referat); Speichern → `rpc('ea_change_volunteer_status')`.
- [ ] T046 [US-EA-09] (spec T15) `src/features/ea/aktive/AusscheidenSchritt.tsx` (zweiter Schritt bei „ausgeschieden“, R8): aktuelle `function`, `position`, `committee` mit `ea_property_writable` vorausgewählt (abwählbar); nicht schreibbare als „wird nicht beendet (anderes Referat)“; Bezug Gruppe als „im Modul Gruppen beenden“; aktuelle `issued_item` und `external_access` als Hinweise; Speichern → `rpc('ea_leave')`; Fehler „Etwas ist schiefgelaufen. Bitte versuche es erneut.“ bzw. `toMessage`.

**Checkpoint**: Statuswechsel vollständig.

---

## Phase 10: US-EA-12 Stichtagsliste (Branch `us-ea-12-ablauf`)

**Unabhängiger Test**: US-EA-12 AK1–AK5; die exportierte Datei öffnet sich in Excel mit Umlauten und Spalten.

- [ ] T047 [US-EA-12] (spec T16) `src/features/ea/ablauf/AblaufPage.tsx` mit Loader: Jahr aus der URL (Standard Folgejahr, Auswahl aktuelles Jahr bis +3); `ea_v_expiry` mit `kind=in.(license,qualification)` und `valid_until` im Jahr; Referate über `ea_volunteer_list` (research.md R-EA-06); Spalten Name, Referate, „Kürzel – Bezeichnung“, gültig bis, `AblaufBadge`; sortiert nach gültig bis, Name; leer: „Im Jahr <jahr> läuft keine Qualifikation ab.“
- [ ] T048 [P] [US-EA-12] (spec T16) `src/features/ea/ablauf/csv.ts`: `ablauf-<jahr>.csv`, UTF-8 mit BOM, Semikolon, Spalten Nachname; Vorname; Rufname; Referate; Kürzel; Bezeichnung; gültig bis (TT.MM.JJJJ); Werte mit Semikolon oder Anführungszeichen quoten; Knopf „CSV exportieren“ nur mit `canManage`.

---

## Phase 11: US-EA-13 Gremium-Sichten (Branch `us-ea-13-gremien`)

**Unabhängiger Test**: US-EA-13 AK1–AK4.

- [ ] T049 [US-EA-13] (spec T17) `src/features/ea/gremien/GremienPage.tsx` (Loader `requireEaManage`): je aktivem Gremium (`sort_order`) die aktuellen `committee`-Eigenschaften mit Name (Link zum Detail), Rolle, seit, bis; leer: „Keine Mitglieder eingetragen.“

---

## Phase 12: US-EA-14 Referate und Gremien pflegen (Branch `us-ea-14-stammdaten`)

**Unabhängiger Test**: US-EA-14 AK1–AK5.

- [ ] T050 [US-EA-14] (spec T18) `src/features/ea/stammdaten/StammdatenPage.tsx` (/ea/stammdaten, Loader `requireEaManage`): zwei Listen Referate und Gremien mit Bezeichnung, Reihenfolge, Status; „Neu“ und „Bearbeiten“ (Bezeichnung, Reihenfolge, aktiv) per Insert/Update auf `ea_referate`/`ea_gremien`; Unique-Verletzung `ea_referate_name_key`/`ea_gremien_name_key` → „Diese Bezeichnung gibt es bereits.“ (Eintrag in `src/lib/errors.ts`, falls noch nicht vorhanden).

---

## Phase 13: US-EA-15 Eigenschafts- und Qualifikationsarten unter /ea (Branch `us-ea-15-arten`)

**Unabhängiger Test**: US-EA-15 AK1–AK5; unter /ad bleibt alles unverändert.

- [ ] T051 [US-EA-15] (spec T19) `src/features/ad/eigenschaftsarten/`: Prop `basePath` (Standard `/ad/eigenschaftsarten`) in `EigenschaftsartenListe.tsx` und `EigenschaftsartBearbeiten.tsx` statt der fest eingebauten Pfade (Zeilen mit `/ad/eigenschaftsarten`); Loader in `data.ts` mit Parameter für die Rechteprüfung (`AD ≥ read` bzw. `EA = manage`), `redirect` auf `basePath`.
- [ ] T052 [US-EA-15] (spec T19) `src/features/ad/qualifikationsarten/data.ts`: Loader mit Parameter für die Rechteprüfung wie T051; Routen in `src/App.tsx` unter `ea`: `eigenschaftsarten`, `eigenschaftsarten/neu`, `eigenschaftsarten/:id`, `qualifikationsarten`, `qualifikationsarten/neu`, `qualifikationsarten/:id` mit `basePath = '/ea/…'` und Prüfung `EA = manage`.

---

## Phase 14: Abnahme (Branch `ea-abnahme`)

- [ ] T053 (spec T21) Abnahme in TEST nach quickstart.md D 1–13 mit Admin, Geschäftsstelle, Referent:in (Klettern), Vorstand, auch bei 375 px; Ergebnis in `docs/specs/ea-ehrenamt/abnahme-test.md` (ohne Personendaten außer Seed-Namen); Anpassungen aus der Abnahme auf diesem Branch.
- [ ] T054 [P] Querschnitt: `npm run lint`, `npm run build`, `npm run ea:migrate:test` ohne Fehler; Personendaten-Prüfung nach CLAUDE.md über `docs`, `scripts`, `supabase/seed.sql`.

---

## Phase 15: Freischalten (Branch `ea-freischalten`)

- [ ] T055 [US-EA-01] (spec T22) Migration `…20261024000800_ea_module_available.sql`: `update public.ad_modules set is_available = true where code = 'EA'`; Test in `supabase/tests/database/010_foundation.test.sql` anpassen (nur AD und EA `is_available`); danach in TEST US-EA-01 AK1 prüfen (quickstart.md D 14).

**Nicht Claude Code**: spec T23 – Lauf gegen PROD durch den Admin nach quickstart.md E, nach Klärung des Wegs der Migrationen nach PROD (O1 der Administration).

---

## Abhängigkeiten und Reihenfolge

- Phase 1 → Phase 2 → alle weiteren. Phase 3 hängt nur von Phase 2 ab und kann parallel zu Phase 4–13 laufen.
- Phase 4 vor allen Oberflächen. Phase 5, 6, 10, 11, 12, 13 nach Phase 4 unabhängig voneinander. Phase 7, 8, 9 nach Phase 6 (nutzen das Detail).
- Phase 14 nach allen Phasen 2–13; Phase 15 zuletzt.
- Innerhalb Phase 2: Tests T002–T010 parallel; danach T011 → T012 → T013 (Seed braucht die Systemarten) → T014 → T015 → T016 → T017 → T018 → T019.
- Innerhalb Phase 3: T020 → T021; T022–T024, T026, T027 parallel; T025 nach T022–T024; T028, T029 zuletzt.

## Parallele Arbeit (Beispiele)

- Phase 2: T002, T003, T004, T005, T006, T007, T008, T009, T010 (je eigene Testdatei).
- Phase 3: T022, T023, T024, T026, T027.
- Nach Phase 4: Branches der Phasen 5, 6, 10, 11, 12, 13 gleichzeitig.

## Umsetzungsstrategie

1. **MVP-Kern**: Phase 1–2 (Datenbank und Seed), dann Phase 4–6 (Navigation, Übersicht, Detail mit Ablauf). Damit sind Aktive in TEST auffindbar und prüfbar.
2. **Pflege**: Phase 7–9.
3. **Listen und Stammdaten**: Phase 10–13.
4. **Migration der Aktivenliste**: Phase 3 parallel, Abnahme durch den Admin gegen TEST.
5. **Abnahme und Freischalten**: Phase 14–15; danach Lauf gegen PROD durch den Admin.
