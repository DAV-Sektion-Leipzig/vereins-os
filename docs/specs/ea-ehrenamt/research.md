# Research: Ehrenamtsmanagement (EA)

Stand: 22.10.2026 · Phase 0 zu [plan.md](plan.md) · Grundlage: [spec.md](spec.md) v0.2 (Ready), [spec.md Administration](../ad-administration/spec.md) v0.9.2, [research.md Administration](../ad-administration/research.md)

Hier steht nur, *wie* umgesetzt wird. Was fachlich entschieden ist, steht in spec.md (Abschnitte 2–9, Annahmen in Abschnitt 11). Die Konventionen der Administration gelten unverändert: Fehlercodes (R-03 AD), Grants (R-02 AD), Tests in CI (R-11 AD), Seed (R-10 AD), Frontend (R-14, R-28 AD). Punkte, die bei der Abnahme in TEST zu prüfen sind, tragen den Vermerk `[PRÜFEN T21]`.

---

## R-EA-01 Abhängigkeit vom Kern der Administration und Reihenfolge der Migrationen

- **Entscheidung:** Das Ehrenamtsmanagement beginnt mit der Datenbank erst, wenn der Datenbankteil des Kerns der Administration auf `main` liegt: T35–T41, T43, T48 (Branch `ad-kern-datenbank`, Migrationen bis `20261023001400`). Die Oberflächen beginnen, wenn die Komponenten der Administration vorliegen: Auswahlfeld Qualifikationsart (T30), Eigenschaftsarten (T46), Eigenschaftsformular (T47), Dublettendialog (T49).
- **Dateinamen:** Die Migrationen des Ehrenamtsmanagements tragen den Zeitstempel ihres Anlagetags und das Präfix `ea_` (spec.md Abschnitt 2), z. B. `2026MMDD000100_ea_system_property_types.sql`. Sie müssen nach allen Kern-Migrationen der Administration sortieren.
- **Achtung bei `db push`:** `supabase db push` bricht ab, wenn lokal eine Migration liegt, die älter ist als die letzte schon in TEST angewendete. Die noch offenen AD-Migrationen `…001500`–`…001700` (Branches `us-ad-08-zugang`, `us-ad-14-protokoll`) sollten deshalb vor der ersten EA-Migration in TEST sein. Sonst ist für sie einmal `supabase db push --linked --include-all` nötig. Das geht, weil sie nur neue Funktionen und Views anlegen, die von keiner EA-Migration abhängen.
- **Begründung:** Das Ehrenamtsmanagement legt keine Tabellen an (spec.md Abschnitt 2). Alle Objekte, auf die es schreibt oder Policies stützt, entstehen im Kern.

## R-EA-02 Übergabe Ü1 und Ü2 (T0a, T0b entfallen)

- Geprüft am 23.10.2026 (main @ 9e05a8b): Der Kern der Administration enthält Ü1 (`ea_property_types.valid_from_label`, `valid_to_label`, Check ≤ 40, `EA_LABEL_TOO_LONG`; Migration `20261023000800`), Ü2 (`birth_year` nach Lesestufe der Art `birth_date`; `20261023001300`) und R3a (`ad_first_names_match`, ebenda). T0a und T0b entfallen.
- Die Oberflächen-Teile von Ü1 und Ü2 (Formular der Eigenschaftsart, Eigenschaftsformular, Anzeige, Dublettendialog) baut die Administration (T073, T081–T083), nicht das Ehrenamtsmanagement.

## R-EA-03 Migration der System-Eigenschaftsarten (T1)

- **Daten in der Migration:** 25 Arten aus 01-erhebung.md C2 und Bezeichnungen aus C2a als `values`-Liste in SQL. Die Felder stehen je Art als `jsonb`-Array in derselben Liste (Schlüssel, Bezeichnung, Typ, Pflicht, Auswahlwerte, erlaubte Typen). So steht jede Art in einer Zeile und lässt sich gut gegen C2 prüfen.
- **Ablauf in einer Transaktion:**
  1. Namenskonflikt prüfen (A7): Gibt es eine Art mit gleichem `lower(name)` ohne `system_key`, folgt `raise exception 'Eigenschaftsart % existiert bereits ohne system_key.'` Eine Art mit gleichem Namen *und* gleichem `system_key` ist kein Konflikt (zweiter Lauf).
  2. Arten einfügen: `insert into ea_property_types … on conflict (system_key) do nothing returning id, system_key`, als CTE.
  3. Felder nur für die in Schritt 2 neu eingefügten Arten (Join auf das CTE): `sort_order` = Position im Array (`with ordinality`).
- **Ohne Nutzerkontext:** Die Migration läuft als Eigentümer ohne `auth.uid()`. Die Trigger der Administration erlauben dann `system_key` und `read_level = 'confidential'` (Nr. 24 Hauptamt) (R-21 AD). `ea_save_property_type` wird nicht genutzt, weil es RLS und Nutzerkontext voraussetzt. R9 (mindestens ein Feld) ist durch die Daten erfüllt; pgTAP prüft das.
- **Werte:**
  - `origin = 'system'`.
  - `visible_in = {AD,EA}`, zusätzlich `GR` bei `member`, `birth_date`, `contact`; `employment` nur `{AD}` (spec.md 2.1).
  - Auswahlwerte als `text[]`, z. B. `{weiblich,männlich,divers,keine Angabe}`.
  - Bei Nr. 8 die Auswahl „Mitglied, Vorsitz“: „Vorsitz“ steht in C2 mit [ANNAHME], spec.md Abschnitt 11 bestätigt die Annahmen; es wird übernommen.
- **Alternative verworfen:** Arten einzeln mit `do $$ … $$`-Blöcken anlegen. Das wäre länger und schwerer gegen C2 zu prüfen.

## R-EA-04 Migration der Qualifikationsarten (T2)

- `insert into ad_qualification_types (code, name, discipline, kind, validity_years, issuer, status) select … where not exists (select 1 from ad_qualification_types where lower(name) = lower(v.name))`. Damit wird idempotent über die Bezeichnung angelegt und nichts überschrieben (spec.md 2.2).
- Ein Kürzel-Konflikt (gleiches Kürzel unter anderer Bezeichnung) bricht die Migration über den Unique-Index `ad_qualification_types_code_key` ab. Das ist gewollt: Eine stille Auslassung würde Lücken im Import verdecken.
- Checks der Administration: `kind = 'training'` mit `validity_years = 2` und `kind = 'course'` mit `null` sind nach R24 AD zulässig; `level` bleibt null (R23 AD).

## R-EA-05 Seed-Umstellung und Personen 19–22 (T3)

- Voraussetzung: Der Seed der Administration mit den Personen 1–12 und den Testarten ist fertig (AD T48).
- **Umstellung (Ü3):** Die Testarten „Funktion (Test)“, „Amt (Test)“, „Lizenz (Test)“, „Geburtsdatum (Test)“, „Kontaktdaten (Test)“ und „Hauptamt“ werden aus `seed.sql` entfernt. Eigenschaften verweisen per `(select id from public.ea_property_types where system_key = '…')` auf die System-Eigenschaftsarten. Die Feldschlüssel bleiben unverändert (AD T48, v0.7.2). „T-Shirt-Größe“ und „Erste-Hilfe-Kurs am“ bleiben Testarten.
- **Bezugsspalte:** Die Funktion hat in C2 einen *optionalen* Bezug (Referat), „Funktion (Test)“ hatte einen Pflichtbezug. Die Seed-Eigenschaften haben alle ein Referat; die Umstellung ändert daran nichts.
- **Personen 19–22:** feste UUIDs im Muster der Administration (`…19` bis `…22`), damit pgTAP sie ansprechen kann (R-26 AD). Datumswerte relativ zu `current_date` (spec.md Abschnitt 9). Qualifikationsarten über das Kürzel (`TCBO`, `TCSPI` liegen im Startbestand). Der Ehrenamtsstatus wird ohne Nutzerkontext direkt gesetzt, mit je einem Eintrag in `ea_volunteer_status_history` (R-23 AD).
- **TEST zurücksetzen:** Vor der ersten EA-Migration wird TEST neu aufgebaut (Entscheidung Product Owner, spec.md AD Abschnitt 9, „TEST vor der ersten EA-Migration“). Das macht der Product Owner bzw. Claude Code nur auf ausdrücklichen Auftrag. Zuerst wird geprüft, dass die Testdomain der Mail-Abnahme entfernt ist (quickstart.md B).

## R-EA-06 Ablaufstatus und Stichtagsliste (T4)

- `ea_expiry_status` ist `immutable` und wird in SQL und pgTAP genutzt. Die Grenze „3 Monate“ ist fest (R9).
- **View `ea_v_expiry`** mit `security_invoker = true` (spec.md 2.3):
  - Basis `ea_properties p` join `ea_property_types t` (`t.system_key in ('license','qualification','police_clearance')`), join `ea_persons` (`volunteer_status in ('active','dormant')`), left join `ad_qualification_types q on q.id = (p.field_values->>'qualification_type')::uuid`.
  - Nur aktuelle Eigenschaften (Definition „aktuell“, spec.md Abschnitt 2).
  - Die RLS auf `ea_properties` und `ea_persons` gilt für den Aufrufer. Deshalb sieht eine Referent:in keine Zeile zur Führungszeugnis-Einsicht (Lesestufe GST) und nur Personen ihrer Referate (US-EA-11 AK5, US-EA-12 AK4).
- **Stichtagsliste:** Abfrage `ea_v_expiry?kind=in.(license,qualification)&valid_until=gte.<jahr>-01-01&valid_until=lte.<jahr>-12-31`. Die Referate der Zeilen kommen aus `ea_volunteer_list` (Spalte `referate`), damit es nur eine Quelle für „Referate einer Person“ gibt. Das Frontend lädt dazu `ea_volunteer_list` einmal mit `p_limit = 200` und ordnet zu; bei mehr als 200 Aktiven wird seitenweise nachgeladen.
- **Index:** `create index ea_properties_valid_until_idx on ea_properties ((field_values->>'valid_until')) where field_values ? 'valid_until'` (spec.md 2.3).
- **Tests mit relativem Datum:** Welche Zeilen im Jahr 2027 erscheinen, hängt vom Tag des Testlaufs ab (Lena: heute + 2 Monate; Max: Führungszeugnis heute − 34 Monate). pgTAP berechnet die Erwartung deshalb aus `current_date`, statt eine feste Liste zu prüfen (spec.md Abschnitt 9: „falls heute + 2 Monate in 2027“).

## R-EA-07 Liste der Aktiven `ea_volunteer_list` (T4)

- `language sql`, `stable`, `security invoker`. Die RLS entscheidet über Personen und Eigenschaften (spec.md Abschnitt 3).
- **Aufbau:**
  1. CTE `cur`: aktuelle Eigenschaften der Arten `function`, `position`, `committee`, `license` der Kandidaten.
  2. CTE `exp`: schlechtester Ablaufstatus je Person aus `ea_v_expiry`. Reihenfolge über `case expiry_status when 'expired' then 3 when 'expiring' then 2 when 'valid' then 1 else 0 end`.
  3. Aggregation je Person: `referate` = `array_agg(distinct r.name order by …)`. Weil `distinct` und `order by` auf eine andere Spalte nicht zusammen gehen, wird erst eine Unterabfrage mit `distinct` auf `(sort_order, name)` gebildet und dann nach `sort_order` aggregiert.
  4. Filter.
  5. `count(*) over ()` als `total_count`, dann `order by lower(last_name), lower(coalesce(preferred_name, first_name))`, `limit`/`offset`.
- **Anzeige „Funktion – Referat“:** `functions` und `positions` enthalten Werte wie „Trainer:in – Klettern“ (spec.md 2.3). Ohne Referat steht nur der Wert.
- **Parameterprüfung:** `p_limit` außerhalb 1–200 wird auf die Grenze gesetzt, kein Fehler. Leerer Suchbegriff nach dem Trimmen gilt als kein Filter. `p_function`/`p_position` mit `p_referate`: dieselbe Eigenschaft muss beide Bedingungen erfüllen (spec.md 2.3), umgesetzt als ein `exists` über `cur`.
- **Suche:** `ilike '%' || p_search || '%'` auf Vor-, Ruf- und Nachname. Die Trigramm-Indizes der Administration (`gin … gin_trgm_ops`) werden dabei genutzt.
- **Leistung (spec.md Abschnitt 8):** Die Lese-Policies der Administration werten die Sichtbarkeit über Mengenfunktionen (`ea_person_ids_ea`, `ea_readable_type_ids`) einmal je Abfrage aus, nicht je Zeile (R-19 AD, Mengentest der Administration: 4 ms statt 2,8 s). `ea_volunteer_list` und `ea_v_expiry` sind `security invoker` und profitieren davon. In eigenen Abfragen ruft das Ehrenamtsmanagement `ea_person_visible`/`ea_property_readable` nicht je Zeile auf. Der Mengentest (R-EA-12) misst das Ergebnis; Ziel < 1 s bei 1.000 Personen × 30 Eigenschaften.

## R-EA-08 IBAN (T5)

- `ea_iban_normalize`: `upper(regexp_replace(p_iban, '\s', '', 'g'))`; null bleibt null.
- `ea_iban_valid`, Prüfsumme nach ISO 13616:
  1. Normalisieren und gegen das Muster `^[A-Z]{2}[0-9]{2}[A-Z0-9]{11,30}$` prüfen.
  2. Die ersten vier Zeichen ans Ende stellen.
  3. Buchstaben ersetzen: `A` = 10 … `Z` = 35, z. B. per `string_agg` über `regexp_split_to_table`.
  4. Rest mod 97 abschnittsweise berechnen (je 9 Ziffern), damit kein großer `numeric` nötig ist. Gültig, wenn der Rest 1 ist.
- **Trigger `ea_properties_iban`** (`before insert or update`, `security invoker`): läuft nur bei Arten mit `system_key = 'bank_account'` und `field_values ? 'iban'`.
  - PostgreSQL führt Trigger desselben Zeitpunkts alphabetisch aus. `ea_properties_iban` läuft deshalb vor `ea_properties_validate` (spec.md 2.3).
  - Ungültig → `raise exception 'EA_IBAN_INVALID' using errcode = 'P0001'`.
  - Der Trigger braucht die Art. Er liest `ea_property_types.system_key` über die `property_type_id`; die Art ist für jeden lesbar, der die Eigenschaft schreiben darf.
- **Beispiel-IBAN:** Seed und pgTAP nutzen nur `DE89370400440532013000` (CLAUDE.md). Den Fehlerfall prüft „DE00 1234“ (US-EA-06 AK3).

## R-EA-09 Status ändern, Ausscheiden, Verlängern (T6)

- **`ea_change_volunteer_status`** (`security invoker`):
  - Liest den aktuellen Status über `ea_persons`, nach RLS. Ist die Person nicht lesbar, folgt `EA_STATUS_FORBIDDEN` (gleiche Meldung wie R33 AD, keine Auskunft über die Existenz).
  - Prüft dann `EA_STATUS_FORBIDDEN` (bei `left`), `EA_STATUS_DATE` (Detail = Grenzdatum `TT.MM.JJJJ` für den Platzhalter in R18) und `EA_STATUS_UNCHANGED`.
  - Zuletzt `ea_set_volunteer_status` (security definer, prüft R33 AD selbst).
- **`ea_leave`** – Reihenfolge in der Transaktion: **erst die Eigenschaften beenden, dann den Status setzen.**
  - **Grund:** Für eine Referent:in endet die Sichtbarkeit mit dem Status „ausgeschieden“ (`ea_person_visible_ea` verlangt `volunteer_status <> 'left'`). Die Updates auf `ea_properties` liefen dann gegen die RLS ins Leere. Fachlich ist das Ergebnis dasselbe (eine Transaktion, A2).
  - Vor jedem Update prüft die Funktion je ID: Eigenschaft gehört zur Person, ist aktuell, `valid_from <= p_valid_from` und `ea_property_writable(type, person, referat)`. Sonst `EA_LEAVE_PROPERTY` (R20), bevor irgendetwas geschrieben ist.
  - Leeres Array erlaubt (nichts beenden).
- **`ea_renew_property`:** Zuerst bekommt die alte Eigenschaft `valid_to = p_valid_from - 1`, dann wird die neue eingefügt. So sieht die Prüfung R37 AD (`allow_multiple`) keine Überschneidung, falls eine Art später auf „nur einer“ umgestellt wird.
  - `field_values = alt || p_field_values`. Damit bleiben Qualifikationsart und Lizenznummer erhalten, neue Werte (`valid_until`, `last_training`) überschreiben.
  - Optional folgt eine `further_training`-Eigenschaft mit `{"year", "title", "qualification_type"}`.
- **Historische Qualifikationsart beim Verlängern:** Die neue Eigenschaft setzt das Feld Qualifikationsart neu. Der Trigger der Administration lehnt eine historische Art deshalb mit `AD_QUALIFICATION_HISTORIC` ab (R27 AD). Die Oberfläche zeigt den Knopf „Verlängern“ deshalb nur bei Qualifikationsarten mit Status „aktuell“ (Entscheidung Product Owner 23.10.2026, plan.md O2).

## R-EA-10 Import `ea_import_volunteers` (T7)

- **Rechte:** `security definer`, `set search_path = ''`. `revoke execute … from public, anon, authenticated`; `grant execute … to service_role`. Das ist dasselbe Muster wie `ad_apply_*` der Administration (R-02 AD). pgTAP prüft, dass `authenticated` die Funktion nicht ausführen kann.
- **Ohne Nutzerkontext:** Aufruf über den Service-Client, `auth.uid()` ist null. Die Trigger erlauben deshalb das Setzen des Ehrenamtsstatus, `created_in = 'script'` und historische Qualifikationsarten (R27 AD).
  - R28 (erlaubte Typen) prüft der Trigger ohne Nutzerkontext nicht (R-20 AD). Den Typ „Lizenz“ für `l*_art` prüft deshalb die Funktion selbst.
- **Dublettenverdacht:** `ad_find_similar_persons` prüft Rechte des Aufrufers und liefert ohne Nutzerkontext `AD_FORBIDDEN`. Der Import wendet deshalb die Namensregel R3a direkt an: gleicher Nachname ohne Groß-/Kleinschreibung und `ad_first_names_match` auf Vor- oder Rufname. Verglichen wird gegen `ea_persons` (`kind = 'human'`) und paarweise innerhalb der Datei. E-Mail-Gleichheit gegen Login-Adressen und `contact.email`/`dav_email` ergänzt die Prüfung.
- **Ablauf:**
  1. Alle Zeilen prüfen und Fehler bzw. Warnungen sammeln.
  2. Ist `p_dry_run = true` oder gibt es Fehler: Rückgabe ohne Schreiben (`written = false`).
  3. Sonst schreiben, alles in der einen Transaktion des RPC-Aufrufs (A3). Ein Fehler beim Schreiben bricht ab; nichts bleibt stehen.
- **Zuordnung CSV → Eigenschaften:** Vorlage C3 und R15–R17. Die Zuordnung steht als Tabelle in [contracts/migration-script.md](contracts/migration-script.md).
- **Statement-Timeout:** `[PRÜFEN T21]` Der Lauf mit 300 Zeilen bleibt unter dem Timeout der Rolle `service_role` in Supabase (spec.md Abschnitt 8: < 60 s). Bei Überschreitung wird der Probelauf in TEST mit 300 fiktiven Zeilen wiederholt und der Wert gemeldet; die Datei wird nicht aufgeteilt (A3 verlangt eine Transaktion).

## R-EA-11 Migrationsskript `scripts/ea-migrate/` (T20)

- TypeScript mit `tsx`. Neue devDependencies: `tsx`, `csv-parse`; `@supabase/supabase-js` ist schon da. Alles kostenfrei.
- `package.json`: `"ea:migrate": "tsx scripts/ea-migrate/index.ts"`.
- **Aufteilung:**
  - `index.ts`: Argumente, Rückfrage, Ablauf.
  - `csv.ts`: Lesen, Kopfzeile prüfen, Datum `TT.MM.JJJJ` → ISO, „ja/nein“, Listen, Jahresspalten per Regex `^(fb|marke|foerderung|jahreskarte)_(\d{4}|vor_2016)$`.
  - `report.ts`: Prüf- bzw. Abschlussbericht als Markdown.
  - `columns.ts`: Pflichtspalten der Vorlage.
- **Formatfehler** meldet das Skript selbst als Fehler im Bericht, mit Zeilennummer. Die Datenbank bekommt nur Zeilen in fester Form (`row`, ISO-Daten, Arrays).
- **Bestätigung vor `--run`:** Das Skript liest die Project Ref aus der eingegebenen Projekt-URL (`https://<ref>.supabase.co`) und verlangt die Eingabe der Ref (A4). Danach folgt intern ein Probelauf; bei Fehlern bricht es ab.
- **Schlüssel (spec.md v0.2.1, Entscheidung Product Owner 23.10.2026):** Abfrage beim Start mit Node `readline`; die Eingabe des Secret Keys wird nicht angezeigt (Ausgabe stummgeschaltet, wie bei einer Passwortabfrage). Der Wert lebt nur in einer Variablen des Prozesses, wird an `createClient` übergeben und nie geloggt; Fehlermeldungen des Clients werden vor der Ausgabe nicht um Header oder Konfiguration ergänzt. Es gibt keinen Rückgriff auf `process.env` oder Dateien, damit der Schlüssel nicht versehentlich dauerhaft abgelegt wird. Die Projekt-URL wird sichtbar abgefragt (kein Geheimnis).
- **Claude Code** führt das Skript nicht aus und bekommt den Schlüssel nie. Probelauf und Lauf gegen TEST mit den Beispieldateien (T20, Abnahme) und gegen PROD (T23) macht der Admin. Claude Code prüft das Skript ohne Datenbank: Lesen der CSV, Formatprüfung und Bericht über Unit-Tests mit einem Ersatz für den RPC-Aufruf.
- **`.gitignore`:** `scripts/ea-migrate/*.csv` mit Ausnahmen `!scripts/ea-migrate/vorlage.csv`, `!scripts/ea-migrate/beispiel.csv`, `!scripts/ea-migrate/beispiel-fehler.csv`; dazu `*.pruefbericht.md`, `*.abschlussbericht.md`. `.env*` ist schon ausgeschlossen.

## R-EA-12 Tests (T9)

- **Dateien:** pgTAP-Dateien ab `210_` unter `supabase/tests/database/` (`200_seed` gehört der Administration), damit sie nach den Tests der Administration laufen. Je Bereich eine Datei; je Datei `begin; … rollback;` und Rollenwechsel über die Seed-Testzugänge (R-11 AD).
  - `210_ea_system_types.test.sql`: 25 Arten, Felder, Bezeichnungen; zweiter Lauf ohne Änderung; Namenskonflikt bricht ab.
  - `220_ea_qualification_types.test.sql`: 10 Einträge; idempotent.
  - `230_ea_expiry.test.sql`: `ea_expiry_status` Grenzfälle; `ea_default_valid_until` (US-EA-07 AK1, AK2, AK5); `ea_v_expiry` je Testzugang.
  - `240_ea_volunteer_list.test.sql`: Tabelle „Erwartete Ergebnisse“ (spec.md Abschnitt 9), Filter, Status `{left}`, Person 12 nie.
  - `250_ea_iban.test.sql`: Prüfsumme, Normalisierung, Trigger.
  - `260_ea_status.test.sql`: R18–R20, R33 AD, Vorstand; `ea_leave` als Referent:in bei Karl Zweireferat (fremdes Referat → `EA_LEAVE_PROPERTY`, nichts geändert).
  - `270_ea_renew.test.sql`: R6 (US-EA-07 AK3), `EA_RENEW_INVALID`.
  - `280_ea_import.test.sql`: Rechte (authenticated abgelehnt), Probelauf schreibt nichts, Fehler- und Warnfälle, Lauf schreibt alles.
  - `290_ea_volume.test.sql`: Mengentest nach spec.md Abschnitt 8 (Muster R-27 AD), misst `ea_volunteer_list` als Referent:in mit allen Filtern, `ea_v_expiry` für ein Jahr und ein Personendetail.
- **Bestehende Tests:** Die Tests der Administration (010–200) laufen nach der Seed-Umstellung unverändert grün (spec.md T3). `200_seed.test.sql` prüft die Testarten des Seeds der Administration; zählt er Eigenschaftsarten, wird er mit der Seed-Umstellung angepasst (gleicher Pull Request).

## R-EA-13 Frontend

- **Ablage:** `src/features/ea/` mit `EaLayout.tsx` (Navigation nach A6) und je Bereich einem Ordner: `aktive/`, `ablauf/`, `gremien/`, `stammdaten/`. Die Seiten Eigenschafts- und Qualifikationsarten werden nicht kopiert; die Routen /ea/eigenschaftsarten* und /ea/qualifikationsarten* hängen die Seiten-Komponenten der Administration aus `src/features/ad/…` bzw. `src/features/shared/` ein (US-EA-15 AK1).
- **Routenschutz:** Loader nach R-14 AD. /ea/* verlangt `ad_has_any_level('EA','read')`, die Verwaltungsseiten zusätzlich `ad_has_level('EA','manage')`. Ohne Recht geht es auf /kein-zugriff, bevor Personendaten abgefragt werden (US-EA-01 AK4, AK5).
- **URL-Zustand (A5):** Filter, Suche und Seite als Suchparameter (`useSearchParams`). Die Suche aktualisiert die URL nach 300 ms Pause.
- **Vorbelegung „gültig bis“ (R5):** Das Frontend ruft `ea_default_valid_until` per RPC auf, wenn sich Qualifikationsart, „gültig von“ oder „letzte Fortbildung“ ändern. Ein Kennzeichen „vom Nutzer geändert“ verhindert danach das Überschreiben. Die Formel steht damit nur in der Datenbank, und der Import nutzt dieselbe Funktion.
- **CSV-Export:** im Browser erzeugt (`Blob` mit BOM `﻿`, Semikolon, Felder mit Semikolon oder Anführungszeichen in Anführungszeichen). Kein Serveraufruf; die Daten sind schon geladen und nach RLS gefiltert (spec.md Abschnitt 3).
- **Neue Fehlercodes:** in `src/lib/errors.ts`; `EA_STATUS_DATE` setzt das Detail in den Platzhalter `<TT.MM.JJJJ>` ein.
- **Mobil:** Tabellen unter 640 px als Karten (R-14 AD), Komponente `ResponsiveTable` der Administration.

## R-EA-14 Freischalten (T22)

- Migration `…_ea_module_available.sql`: `update ad_modules set is_available = true where code = 'EA'`.
- Die Abnahme in TEST (T21) prüft US-EA-01 AK1 (Kachel auf der Startseite) erst danach. Alle übrigen Stories sind ohne Freischaltung prüfbar, weil der Routenschutz `ad_has_any_level` nutzt, nicht `is_available`. Reihenfolge: Abnahme aller übrigen Kriterien, dann T22 in TEST, dann AK1.
- Der Weg nach PROD folgt O1 der Administration (offen).
