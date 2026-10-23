---
description: "Tasks für das Modul Ehrenamtsmanagement (EA)"
---

# Tasks: Ehrenamtsmanagement (EA)

**Input**: [plan.md](plan.md) (Stand 23.10.2026), [spec.md](spec.md) v0.2.1 (führend), [02-stories.md](02-stories.md) v0.2.1, [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md), [Constitution](../../../.specify/memory/constitution.md) v1.2.0

**Stand (geprüft 23.10.2026, main @ 7f91854)**: Alle Voraussetzungen aus plan.md sind erfüllt. Die AD-Migrationen bis `20261023001700` liegen auf `main` und in TEST (AD T098). Die Komponenten der Administration, auf die das Ehrenamtsmanagement aufbaut, sind gemergt: Dublettendialog (AD T073), Auswahlfeld Qualifikationsart (T076), Formular der Eigenschaftsart mit Ü1 (T081), Eigenschaftsformular (T082), Eigenschaften im Personendetail (T083). T0a und T0b der Spec entfallen (research.md R-EA-02). Die Oberflächen sind damit nicht mehr blockiert.

**Abweichungen von plan.md und research.md (Umsetzungsdetails, keine fachliche Änderung)**:
- pgTAP-Dateien des Ehrenamtsmanagements beginnen bei `300_`, weil die Administration inzwischen `210_`–`230_` belegt (research.md R-EA-12 nachgezogen).
- Migrationen tragen den Zeitstempel `20261023002100` ff., damit sie nach `20261023001700` sortieren (data-model.md nachgezogen).
- Die Migration für O3 (`ea_check_create`) heißt `20261023002600_ea_check_create.sql`; der Import erhält `…002700`, das Freischalten `…002800`.

**Tests**: Die Constitution verlangt eine test- und spec-getriebene Umsetzung mit pgTAP-Tests je Rechtevorlage (Arbeitsablauf Nr. 4). Vor jeder Migration steht eine Test-Task; die Tests müssen zuerst fehlschlagen. Für das Frontend gilt die Abnahme in TEST (spec T21). Für das Migrationsskript gibt es Unit-Tests ohne Datenbank (research.md R-EA-11).

**Organisation**: Phasen nach den Branches aus plan.md, Abschnitt „Branches“. Phase 2 ist die gemeinsame Datenbank-Grundlage (Branch `ea-datenbank`); danach eine Phase je Branch.

## Format: `- [ ] T### [P?] [US-EA-xx] (spec Tn) Beschreibung`

- **T###**: laufende Task-ID dieser Datei
- **[P]**: parallel ausführbar (andere Datei, keine offene Abhängigkeit)
- **[US-EA-xx]**: Story aus 02-stories.md
- **(spec Tn)**: Task-Nummer aus spec.md Abschnitt 10; „Teil“ bedeutet, dass nur ein Teil dieser spec-Task umgesetzt wird; „O3“ bzw. „O2“ verweisen auf die Entscheidungen in plan.md

## Regeln für alle Tasks

- **Nie gegen PROD.** Alle CLI-Befehle gehen nur gegen vereins-os-test oder gegen den lokalen Stack in der GitHub Action. Vor jedem Befehl mit `--linked` muss `npx supabase projects list` zeigen, dass TEST verknüpft ist. Den Lauf des Migrationsskripts (Probelauf und Lauf, auch gegen TEST) führt ausschließlich der Admin aus; Claude Code bekommt den Secret Key nie (spec.md Abschnitt 7).
- **Kein `supabase config push` und kein `supabase config diff`.**
- **Bestehende Migrationen nicht ändern.** Jede Änderung kommt per neuer Migration; die Ersetzung von `ea_check_create` (O3) erfolgt per `create or replace` mit gleicher Signatur in einer neuen Migration.
- **Keine neue Tabelle, keine neue Policy** (spec.md Abschnitt 2 und 3). Neue Funktionen sind `security invoker` mit `set search_path = public`; Ausnahme `ea_import_volunteers` (`security definer`, `set search_path = ''`, Grant nur an `service_role`). Jede Migration: `revoke all … from public, anon` und `grant … to authenticated` (bzw. `service_role`).
- **Fehlercodes und Meldungen nur aus** [contracts/error-codes.md der Administration](../ad-administration/contracts/error-codes.md) (T002 trägt die neuen Codes dort ein).
- **Keine Echtdaten.** Seed und Beispiel-CSV nur fiktiv; E-Mail-Adressen nur `@example.test`; IBAN nur `DE89370400440532013000` (Fehlerfall „DE00 1234“). Vor jedem Commit die Personendaten-Prüfung aus CLAUDE.md.
- **Fachliche Dateien** (`00-steckbrief.md`, `01-erhebung.md`, `02-stories.md`, `spec.md`, `migration-aktivenliste.md`, `stammdaten-qualifikationsarten.md`, `uebergabe-*.md`) nicht ändern. Widersprüche als `[OFFEN]` melden.
- **Komponenten der Administration** (`src/features/shared/`, `src/features/ad/`) werden eingehängt, nicht kopiert. Änderungen daran nur additiv (neue optionale Props), damit die Administration unverändert weiterläuft; an der Administration wird parallel gearbeitet.
- **Pull Requests**: je Phase ein Branch; der PR nennt Stories, Tasks und die Cloudflare-Vorschau-URL. Auto-Merge nur für Phasen, die ausschließlich Migrationen, Tests, Seed oder Umsetzungsdateien ändern (Phase 2, Phase 15); alle übrigen mergt der Product Owner.

## Phase 1: Vorbereitung (Branch `ea-datenbank`)

**Ziel**: Fehlercodes festgelegt, TEST-Reset geklärt, Umsetzungsdateien aktuell.

- [ ] T001 (spec T8) Fehlercodes in `docs/specs/ad-administration/contracts/error-codes.md`, Abschnitt „Ehrenamtsmanagement“: `EA_IBAN_INVALID` „Die IBAN ist ungültig.“ (R13), `EA_STATUS_DATE` „Bitte ein Datum bis spätestens <TT.MM.JJJJ> wählen.“ (R18, Platzhalter aus `DETAIL`), `EA_STATUS_UNCHANGED` „Die Person hat diesen Status bereits.“ (R19), `EA_LEAVE_PROPERTY` „Diese Angabe kann hier nicht beendet werden.“ (R20), `EA_RENEW_INVALID` „Nur aktuelle Lizenzen und Qualifikationen können verlängert werden; das neue Datum muss nach dem bisherigen liegen.“ (R6); Constraints `ea_referate_name_key`, `ea_gremien_name_key` → „Diese Bezeichnung gibt es bereits.“ (US-EA-14 AK3); `EA_CREATE_FORBIDDEN` und `EA_CREATE_REFERAT_REQUIRED` von „geplant“ auf „umgesetzt (EA)“ setzen, sobald T018 gemergt ist
- [ ] T002 (quickstart.md B) TEST-Reset vor der ersten EA-Migration: **nur auf ausdrücklichen Auftrag des Product Owners.** Vorher prüfen, dass `ad_test_login_domains` leer ist (AD quickstart.md C2) und TEST verknüpft ist; dann `npx supabase db reset --linked` und `supabase/seed.sh`. Ohne Auftrag: Phase 2 wird in CI geprüft; nach TEST kommt sie mit T020

---

## Phase 2: Datenbank-Kern (Branch `ea-datenbank`) 🎯 Grundlage für alle weiteren Phasen

**Ziel**: Stammdaten (25 System-Eigenschaftsarten, 10 Qualifikationsarten), Seed-Umstellung Ü3 mit Personen 19–22, View und Funktionen für Ablauf, Liste, IBAN, Status, Verlängern, neue Prüfung beim Anlegen (O3). Stories: US-EA-16, US-EA-19; Datenbankteil von US-EA-02, 03, 05–12.

**Unabhängiger Test**: GitHub Action `db-tests` grün: Tests der Administration (010–230) unverändert, neue Tests 300–380 grün; Mengentest unter den Grenzen aus spec.md Abschnitt 8.

### Tests (zuerst schreiben, müssen zuerst fehlschlagen)

- [ ] T003 [P] [US-EA-16] (spec T9 Teil) `supabase/tests/database/300_ea_system_types.test.sql`: 25 Arten mit `origin = 'system'` und den `system_key` aus data-model.md; je Art `category`, `read_level`, `relation_kind`, `relation_required`, `allow_multiple`, `visible_in`, `valid_from_label`, `valid_to_label` nach data-model.md (Tabelle „System-Eigenschaftsarten“); Felder je Art mit `key`, `data_type`, `is_required`, `choice_values`, `allowed_qualification_kinds`, `sort_order` in der Reihenfolge von 01-erhebung.md C2; `license` hat `qualification_type` (`{license}`, Pflicht) und `valid_until` (Pflicht) (AK4); jede Art ≥ 1 Feld; zweiter Lauf: die `insert`-Anweisungen der Migration im Test in einem `do`-Block wiederholen (Datei kann pgTAP nicht einlesen); Anzahl Arten und Felder unverändert, ein vorher geänderter `purpose` bleibt erhalten (AK2); Namenskonflikt: Art „Mitglied“ ohne `system_key` anlegen, dann `throws_ok` mit „Eigenschaftsart Mitglied existiert bereits ohne system_key.“ (AK5)
- [ ] T004 [P] [US-EA-16] (spec T9 Teil) `supabase/tests/database/310_ea_qualification_types.test.sql`: 10 neue Einträge EH, RS (`training`, `validity_years = 2`, Sparte „Allgemein“, Aussteller „extern“), AMAK, AMBS, AMHT, AMKS, AMMB, AMSB, AMSH, AMSK (`course`, `validity_years` null, „Jugend und Familie“, „Bundesverband (JDAV)“) mit `status = 'current'`, `level` null, `source_ref` null; Gesamtzahl 57 (47 + 10); zweiter Lauf ändert nichts; Umbenennung in der Oberfläche (z. B. `name` von EH) wird nicht überschrieben (AK3)
- [ ] T005 [P] [US-EA-11] (spec T9 Teil) `supabase/tests/database/320_ea_expiry.test.sql`: `ea_expiry_status`: null → `none`, gestern → `expired`, heute → `expiring`, heute + 3 Monate → `expiring`, heute + 3 Monate + 1 Tag → `valid` (R9); `ea_default_valid_until`: TCSPI (4 Jahre) mit 15.05.2026 ohne Fortbildung → 31.12.2030 (US-EA-07 AK1), mit Fortbildung 10.03.2027 → 31.12.2031 (AK2), Qualifikationsart ohne Gültigkeitsdauer → null (AK5); `ea_v_expiry` je Testzugang: Admin und Geschäftsstelle sehen Lena (19, `expiring`), Max Lizenz (`expired`) und Max Führungszeugnis (`expiring`, `valid_until = issued_on + 3 Jahre`, R10), Toni TCSPI 31.12.2027; Referent:in Klettern sieht Lena und Toni, keine `police_clearance`-Zeile (US-EA-11 AK5) und keine Zeile zu Max (nicht ihr Referat); Vorstand 0 Zeilen; beendete Lizenz (Anton, `valid_to` gesetzt) und Olga (`left`) erscheinen nicht (AK4); Erwartung für das Jahr 2027 aus `current_date` berechnet (research.md R-EA-06, plan.md H2)
- [ ] T006 [P] [US-EA-02] (spec T9 Teil) `supabase/tests/database/330_ea_volunteer_list.test.sql`: Tabelle „Erwartete Ergebnisse“ (spec.md Abschnitt 9): Standardaufruf für Admin und Geschäftsstelle liefert Personen 4, 5, 9, 10, 19, 20, 21, 22; Referent:in Klettern 4, 9, 10, 19, 22; Vorstand leer; `p_trainer_without_license` → nur 20 (R14); `p_status = '{left}'` → Geschäftsstelle 11, Referent:in leer; Person 12 nie; `p_search = 'toni'` enthält 4 (ohne Groß-/Kleinschreibung, auch Rufname); `p_referate` Klettern + `p_function` Trainer:in → 4, 19 (dieselbe Eigenschaft, nicht Karl 10 mit Trainer:in in Ausbildung); `p_gremium` Beirat → 21; `p_qualification_type` TCBO → 19; `p_discipline`; `p_expiry = '{expired}'` → 20; `p_without_assignment` → 5 (Anton: aktiv, nur Lizenz) und ggf. 21 nicht (hat `committee`); Spalten `referate`, `functions` („Trainer:in – Klettern“), `positions`, `license_codes`, `worst_expiry`, `total_count`; Sortierung `lower(last_name)`, dann Rufname/Vorname; `p_limit` 0 und 500 werden auf 1 bzw. 200 begrenzt; `p_offset`
- [ ] T007 [P] [US-EA-06] (spec T9 Teil) `supabase/tests/database/340_ea_iban.test.sql`: `ea_iban_normalize('de89 3704 0044 0532 0130 00')` = `DE89370400440532013000`, null bleibt null; `ea_iban_valid` wahr für die Beispiel-IBAN, falsch für „DE00 1234“, „DE89370400440532013001“ (Prüfsumme), leer und null; Trigger: Geschäftsstelle legt `bank_account` mit Leerzeichen und Kleinbuchstaben an → gespeichert normalisiert (AK3); ungültig → `throws_ok` `EA_IBAN_INVALID`; eine andere Art mit Feld `iban` ohne `system_key = 'bank_account'` bleibt unberührt; Referent:in kann `bank_account` (Lesestufe GST) weder lesen noch anlegen
- [ ] T008 [P] [US-EA-08] (spec T9 Teil) `supabase/tests/database/350_ea_status.test.sql`: `ea_change_volunteer_status`: Geschäftsstelle setzt Toni auf `dormant` ab 01.11.2026 → Status, `volunteer_status_since`, neuer Eintrag in `ea_volunteer_status_history` mit `set_by` (US-EA-08 AK1); gleicher Status → `EA_STATUS_UNCHANGED` (R19); Datum > heute + 1 Jahr → `EA_STATUS_DATE` mit `DETAIL` = Grenzdatum `TT.MM.JJJJ` (R18); `p_status = 'left'` → `EA_STATUS_FORBIDDEN`; Referent:in Klettern bei Anton (5) → `EA_STATUS_FORBIDDEN` (R33 AD, AK5); Vorstand → `EA_STATUS_FORBIDDEN`; Geschäftsstelle setzt Olga (11, `left`) auf `active` (US-EA-10 AK3). `ea_leave`: Geschäftsstelle bei Sven (22) ab 31.12.2026 mit Funktion → Status `left`, `valid_to` der Funktion = 31.12.2026, Ausgabe und Zugang extern unverändert (US-EA-09 AK2); leeres Array erlaubt; fremde Eigenschafts-ID, beendete Eigenschaft oder `valid_from > p_valid_from` → `EA_LEAVE_PROPERTY`, Status unverändert (R20); Referent:in Klettern bei Karl (10) mit Funktion Ausbildung → `EA_LEAVE_PROPERTY`, nichts geändert (AK3); Referent:in bei Karl nur mit Funktion Klettern → erfolgreich, Karl danach für sie unsichtbar (AK5)
- [ ] T009 [P] [US-EA-07] (spec T9 Teil) `supabase/tests/database/360_ea_renew.test.sql`: Geschäftsstelle verlängert Toni TCSPI (e…03) ab 01.11.2027 mit `{"valid_until":"2031-12-31","last_training":"2027-11-01"}` → neue Eigenschaft mit gleicher Qualifikationsart und Lizenznummer `TEST-0001`, `valid_from` 01.11.2027, alte `valid_to` 31.10.2027 (US-EA-07 AK3); mit `p_training = {"year":2027,"title":"Fortbildung Sportklettern"}` entsteht zusätzlich eine `further_training`-Eigenschaft mit `qualification_type` der Lizenz; Datum nicht später → `EA_RENEW_INVALID`; beendete Eigenschaft (Anton e…07) → `EA_RENEW_INVALID`; Art ≠ `license`/`qualification` (T-Shirt-Größe) → `EA_RENEW_INVALID`; historische Qualifikationsart (nach Neuanlage einer Lizenz TCSP durch Seed) → `AD_QUALIFICATION_HISTORIC` (O2, R27 AD); Referent:in Klettern verlängert Lena (19), nicht Anton (5) (AK6); Vorstand abgelehnt
- [ ] T010 [P] (spec T9 Teil) `supabase/tests/database/380_ea_volume.test.sql`: Mengentest nach spec.md Abschnitt 8 und Muster `190_mengentest.test.sql`: 1.000 Personen mit je 30 Eigenschaften (Funktion, Lizenz mit `valid_until`, weitere Arten) in Referat Klettern und anderen; misst als Referent:in `ea_volunteer_list` mit allen Filtern (< 1 s), `ea_v_expiry` für ein Jahr (< 2 s) und das Laden eines Personendetails (`ea_properties` + Historie, < 1 s) über `clock_timestamp()`; Ergebnis mit `ok(...)` und Laufzeit im Meldungstext
- [ ] T011 [US-EA-05] (O3) `supabase/tests/database/140_volunteer_functions.test.sql` anpassen: Vorstand bei `ea_create_volunteer` → `EA_CREATE_FORBIDDEN` statt `AD_FORBIDDEN`; Referent:in ohne erste Zuordnung → `EA_CREATE_REFERAT_REQUIRED` statt `EA_RELATION_REQUIRED`; fremdes Referat unverändert `EA_RELATION_FOREIGN_REFERAT`; gleiche Fälle für `ea_activate_person` (US-EA-10 AK5); Geschäftsstelle ohne Zuordnung weiterhin erlaubt (US-EA-05 AK3)

### Migrationen und Seed

- [ ] T012 [US-EA-16] (spec T1) Migration `supabase/migrations/20261023002100_ea_system_property_types.sql` nach research.md R-EA-03: eine `values`-Liste mit 25 Arten (Name, Zweck, `system_key`, `category`, `read_level`, `relation_kind`, `relation_required`, `allow_multiple`, `visible_in`, `valid_from_label`, `valid_to_label`, Felder als `jsonb`-Array) wörtlich nach 01-erhebung.md C2/C2a und data-model.md; Ablauf in einer Transaktion: (1) Namenskonflikt → `raise exception 'Eigenschaftsart % existiert bereits ohne system_key.'` (A7), (2) `insert … on conflict (system_key) do nothing returning id, system_key` als CTE mit `origin = 'system'`, (3) Felder nur für neu eingefügte Arten mit `sort_order` aus `with ordinality`; Auswahlwerte `gender` {weiblich, männlich, divers, keine Angabe}, `function` {Trainer:in, Helfer:in}, `position` {Referent:in, stellv. Referent:in, Hüttenwart:in}, `role` {Mitglied, Vorsitz}, `item` {Schlüssel NoLimit, Schlüssel K4, K4-Karte, Jahreskarte, Vereinsjacke}, `system` {DAV360, Forms, JDAV Aktiven-Mailverteiler, Redaktion, Mailingliste}; `allowed_qualification_kinds` `{license}` bei `license.qualification_type` und `further_training.qualification_type`, `{add_on,course,training}` bei `qualification.qualification_type`; `employment` mit `read_level = 'confidential'` und `visible_in = '{AD}'`; Tests T003 grün
- [ ] T013 [P] [US-EA-16] (spec T2) Migration `supabase/migrations/20261023002200_ea_qualification_types.sql` nach research.md R-EA-04: `insert into ad_qualification_types (code, name, discipline, kind, validity_years, issuer, status) select … where not exists (… lower(name) = lower(v.name))`; EH „Erste Hilfe“ und RS „Rettungsschwimmer“ (Bezeichnungen nach 01-erhebung.md C4) mit `training`, 2, „Allgemein“, „extern“; acht Aufbaumodule nach spec.md 2.2 mit `course`, null, „Jugend und Familie“, „Bundesverband (JDAV)“; Kürzel-Konflikt bricht gewollt über `ad_qualification_types_code_key` ab; Tests T004 grün
- [ ] T014 [US-EA-19] (spec T3) Seed-Umstellung Ü3 in `supabase/seed.sql` nach research.md R-EA-05: Testarten d…01 (Hauptamt), d…04–d…08 entfernen; Eigenschaften e…01–e…14 verweisen per `(select id from public.ea_property_types where system_key = '…')` auf `employment`, `function`, `position`, `license`, `birth_date`, `contact`; Feldschlüssel unverändert; „T-Shirt-Größe“ (d…02) und „Erste-Hilfe-Kurs am“ (d…03) bleiben; Personen 19–22 (`a…19`–`a…22`, `kind = 'human'`, `created_in = 'AD'` [ANNAHME wie Personen 1–12]) mit Ehrenamtsstatus und je einem Historieneintrag ohne Nutzerkontext; Eigenschaften nach data-model.md „Testdaten“ mit relativen Datumswerten (`current_date + interval '2 months'`, `current_date - interval '34 months'`), Qualifikationsarten über Kürzel TCBO, TCSPI, Referate Klettern, Kinder und Jugend, Gremium Beirat, Beispiel-IBAN; Kopfkommentar aktualisieren. Im selben Commit die AD-Tests anpassen, die auf die entfernten Testarten verweisen (`110_property_types`, `120_properties`, `130_visibility`, `140_volunteer_functions`, `190_mengentest`, `200_seed`, `210_invite_functions`: Art-IDs durch `system_key`-Auflösung ersetzen; `200_seed`: Anzahl Arten, `system_key`-Liste, Personen 16, Historie 9, Eigenschaften nach Seed zählen); Tests 010–230 bleiben grün
- [ ] T015 [US-EA-02] (spec T4) Migration `supabase/migrations/20261023002300_ea_expiry_list.sql`: `ea_expiry_status(date, date default current_date) returns text` (sql, immutable, R9); `ea_default_valid_until(uuid, date, date default null) returns date` (sql, stable, security invoker, R5: `make_date(extract(year from coalesce(p_last_training, p_valid_from))::int + validity_years, 12, 31)`, null ohne `validity_years`); View `ea_v_expiry` mit `security_invoker = true` und Spalten nach spec.md 2.3 (`kind` aus `system_key`, `valid_until` bei `police_clearance` = `issued_on + 3 years`, nur aktuelle Eigenschaften, Personen `active`/`dormant`, `left join ad_qualification_types`); Index `ea_properties_valid_until_idx on ea_properties ((field_values->>'valid_until')) where field_values ? 'valid_until'`; `ea_volunteer_list(p_search text default null, p_status ea_volunteer_status[] default '{active,dormant}', p_referate uuid[] default null, p_function text default null, p_position text default null, p_gremium uuid default null, p_qualification_type uuid default null, p_discipline text default null, p_expiry text[] default null, p_trainer_without_license boolean default false, p_without_assignment boolean default false, p_limit int default 50, p_offset int default 0) returns table (id uuid, first_name text, preferred_name text, last_name text, volunteer_status ea_volunteer_status, volunteer_status_since date, referate text[], functions text[], positions text[], license_codes text[], worst_expiry text, trainer_without_license boolean, total_count bigint)` nach research.md R-EA-07 (CTEs `cur`, `exp`, Aggregation mit `sort_order`, `p_function`/`p_position` mit `p_referate` auf derselben Eigenschaft, `p_limit` auf 1–200 begrenzt, `count(*) over ()`); `revoke … from public, anon`; `grant execute … to authenticated`, `grant select on ea_v_expiry to authenticated`; Tests T005, T006 grün
- [ ] T016 [P] [US-EA-06] (spec T5) Migration `supabase/migrations/20261023002400_ea_iban.sql`: `ea_iban_normalize(text)` (`upper(regexp_replace(p_iban, '\s', '', 'g'))`, null bleibt null); `ea_iban_valid(text)` (plpgsql, immutable: Muster `^[A-Z]{2}[0-9]{2}[A-Z0-9]{11,30}$`, erste vier Zeichen ans Ende, Buchstaben A = 10 … Z = 35, Rest mod 97 abschnittsweise = 1, research.md R-EA-08); Trigger-Funktion `ea_properties_iban()` (plpgsql, security invoker: nur wenn die Art `system_key = 'bank_account'` hat und `new.field_values ? 'iban'`; normalisiert; ungültig → `raise exception 'EA_IBAN_INVALID' using errcode = 'P0001'`); `create trigger ea_properties_iban before insert or update on ea_properties for each row` (läuft alphabetisch vor `ea_properties_validate`); Grants; Tests T007 grün
- [ ] T017 [US-EA-08] (spec T6) Migration `supabase/migrations/20261023002500_ea_status_renew.sql` nach research.md R-EA-09: `ea_change_volunteer_status(uuid, ea_volunteer_status, date)` (liest Status über `ea_persons` nach RLS, nicht lesbar → `EA_STATUS_FORBIDDEN`; `left` → `EA_STATUS_FORBIDDEN`; `p_valid_from > current_date + interval '1 year'` → `EA_STATUS_DATE` mit `detail = to_char(current_date + interval '1 year', 'DD.MM.YYYY')`; gleich → `EA_STATUS_UNCHANGED`; dann `ea_set_volunteer_status`); `ea_leave(uuid, date, uuid[])` (Datum wie oben; **erst** je ID prüfen: gehört zur Person, aktuell, `valid_from <= p_valid_from`, `ea_property_writable(property_type_id, person_id, related_referat_id)`, sonst `EA_LEAVE_PROPERTY` vor jedem Schreiben; dann `update ea_properties set valid_to = p_valid_from`; **zuletzt** `ea_set_volunteer_status(p_person, 'left', p_valid_from)`); `ea_renew_property(uuid, date, jsonb, jsonb default null) returns uuid` (nur `system_key in ('license','qualification')`, aktuell, `p_valid_from > valid_from`, sonst `EA_RENEW_INVALID`; zuerst alte `valid_to = p_valid_from - 1`, dann neue mit `field_values = alt || p_field_values`; bei `p_training` zusätzlich `further_training` mit `year`, `title`, `qualification_type` der Lizenz und `valid_from = p_valid_from`); alle `security invoker`, `set search_path = public`; Grants; Tests T008, T009 grün
- [ ] T018 [US-EA-05] (O3) Migration `supabase/migrations/20261023002600_ea_check_create.sql`: `create or replace function public.ea_check_create(p_property_type uuid, p_referat uuid)` mit gleicher Signatur und gleichen Eigenschaften wie in `20261023001100`; Fälle: ohne EA ≥ bearbeiten (auch Reichweite Referat) → `EA_CREATE_FORBIDDEN`; Reichweite Referat ohne Art oder ohne Referat → `EA_CREATE_REFERAT_REQUIRED`; Referat nicht in `ad_my_referate('EA','edit')` → `EA_RELATION_FOREIGN_REFERAT`; Rechte wie bisher (`revoke … from public, anon, authenticated`, Aufruf nur aus `ea_create_volunteer`/`ea_activate_person`); Tests T011 grün
- [ ] T019 Mengentest T010 grün; Pull Request `ea-datenbank` (Stories US-EA-16, US-EA-19, Datenbankteil 02–12; Tasks T001–T019) mit `gh pr create` und `gh pr merge --auto --merge` (nur Migrationen, Tests, Seed, Umsetzungsdateien); bei rotem Check Ursache melden, nicht erneut anstoßen
- [ ] T020 Nach dem Merge TEST auf Stand bringen (nach Prüfung, dass TEST verknüpft ist): `npx supabase db push --linked --dry-run`, dann ohne `--dry-run`; danach `supabase/seed.sh` gegen TEST nur, wenn T002 beauftragt wurde oder der Product Owner den Seed-Lauf freigibt (die Umstellung Ü3 ändert vorhandene Seed-Daten nur bei neuem Aufbau)

**Checkpoint**: Datenbank vollständig; alle Oberflächen-Phasen und der Import können beginnen.

---

## Phase 3: US-EA-17, US-EA-18 Migrationsskript (Branch `us-ea-17-import`)

**Ziel**: Datenbankfunktion `ea_import_volunteers` und lokales Skript `scripts/ea-migrate/` mit Probelauf, Lauf, Berichten und Beispieldateien.

**Unabhängiger Test**: pgTAP 370 grün; Unit-Tests des Skripts grün; Probelauf des Admins gegen TEST mit `beispiel.csv` ohne Fehler und mit `beispiel-fehler.csv` mit genau zwei Fehlern (quickstart.md D11, D12).

- [ ] T021 [P] [US-EA-17] (spec T9 Teil) `supabase/tests/database/370_ea_import.test.sql`: `authenticated` (Admin-Testzugang) → `throws_ok` „permission denied“; als `service_role`/Eigentümer: Probelauf mit 5 Zeilen nach spec.md Abschnitt 9 schreibt nichts (`written = false`, Personenzahl unverändert) und liefert `counts` je `system_key`; Fehler: Pflichtfeld leer, Referat unbekannt, „Qualifikationsart XYZ unbekannt“, `l1_art` kein Typ Lizenz, IBAN ungültig („Die IBAN ist ungültig.“), Auswahlwert unbekannt (contracts/migration-script.md „Prüfungen“); Warnungen: Dublettenverdacht zu Toni Muster (R3a, `ad_first_names_match`) und innerhalb der Datei, mehr Lizenzen als Nummern, Lizenz ohne „gültig bis“ mit berechnetem Datum, Werte in `gruppe`; mit Fehlern und `p_dry_run = false` wird nichts geschrieben; Lauf ohne Fehler: Personen mit `created_in = 'script'`, `created_by` null, Status `active`/`dormant` ab Stichtag mit einem Historieneintrag, je Referat `function` „Trainer:in“ bei Lizenz sonst „Helfer:in“ mit `training_units_per_week` nur bei Trainer:in (R15), `valid_from` = `aktiv_seit` oder Stichtag, Lizenz mit historischer Art (TCSP) erlaubt (R27 AD), Fortbildungen je Jahr, IBAN normalisiert, `committee` Jugendausschuss, `issued_item`, `external_access` (US-EA-18 AK4); Zählung „gültig von = Stichtag“ (R17)
- [ ] T022 [US-EA-17] (spec T7) Migration `supabase/migrations/20261023002700_ea_import.sql`: `ea_import_volunteers(p_rows jsonb, p_cutoff date, p_dry_run boolean) returns jsonb`, `security definer`, `set search_path = ''`, voll qualifizierte Namen; Ablauf nach research.md R-EA-10: (1) alle Zeilen prüfen, Fehler und Warnungen sammeln (Texte nach contracts/migration-script.md), Typ Lizenz selbst prüfen (R28 ohne Nutzerkontext), Dubletten über `lower(last_name)` + `public.ad_first_names_match` gegen `ea_persons` (`kind = 'human'`) und paarweise in der Datei, E-Mail gegen `ad_accesses.login_email` und `contact.email`/`dav_email`; (2) bei `p_dry_run` oder Fehlern Rückgabe `{"errors":[…],"warnings":[…],"counts":{…},"written":false}`; (3) sonst Schreiben nach der Zuordnungstabelle in contracts/migration-script.md in der Transaktion des Aufrufs, Rückgabe mit `written = true`; `revoke execute … from public, anon, authenticated`; `grant execute … to service_role`; Tests T021 grün
- [ ] T023 [P] [US-EA-17] (spec T20 Teil) `scripts/ea-migrate/columns.ts` (Pflichtspalten der Vorlage nach 01-erhebung.md C3, Muster der Jahresspalten `^(fb|marke|foerderung|jahreskarte)_(\d{4}|vor_2016)$`) und `scripts/ea-migrate/csv.ts` (Lesen mit `csv-parse` UTF-8/Semikolon; Kopfzeile prüfen → `Spalte <name> fehlt.`; Datum `TT.MM.JJJJ` → ISO; „ja/nein“ → boolean; `referate` als Array; `qualifikationen` als Array `{code, date, valid_until, detail}`; Jahresspalten als Objekt; leere Zellen weglassen; Formatfehler als `{row, message}` „Zeile <n>: <Spalte> nicht lesbar“, Zeile ohne den Wert trotzdem übergeben); Rückgabe `{ rows, formatErrors }`
- [ ] T024 [P] [US-EA-17] (spec T20 Teil) `scripts/ea-migrate/report.ts`: Prüf- bzw. Abschlussbericht als Markdown mit Kopf (Datei, Projekt-Ref, Stichtag, Zeitpunkt, Probelauf/Lauf), Abschnitten Fehler, Warnungen, Zusammenfassung (Personen, Eigenschaften je Art, Anzahl „gültig von = Stichtag“); Dateiname `<datei>.pruefbericht.md` bzw. `<datei>.abschlussbericht.md` neben der CSV; nie den Schlüssel oder Header ausgeben
- [ ] T025 [US-EA-18] (spec T20 Teil) `scripts/ea-migrate/index.ts`: Argumente `--file`, `--dry-run` | `--run` (genau eins, sonst Hinweis zum Aufruf), `--cutoff TT.MM.JJJJ` (Standard heute); Abfrage „Projekt-URL:“ sichtbar und „Secret Key:“ verdeckt über `readline` mit stummgeschalteter Ausgabe (research.md R-EA-11; kein `process.env`, keine Datei); leer → „Schlüssel fehlt.“ (AK6); Projekt-Ref aus der URL; `createClient(url, key)` mit dem Service-Client; Probelauf: RPC `ea_import_volunteers(rows, cutoff, true)` → Prüfbericht; `--run`: Rückfrage „Lauf gegen <Projekt-Ref> – zum Bestätigen Projekt-Ref eingeben:“, falsche Eingabe → Abbruch; interner Probelauf, bei Fehlern „Probelauf hat Fehler. Lauf abgebrochen.“; sonst RPC mit `false` → Abschlussbericht; Formatfehler aus T023 fließen in den Bericht und verhindern den Lauf; Exitcode 0 nur bei Probelauf ohne Fehler bzw. geschriebenem Lauf; Fehlermeldungen des Clients ohne Header oder Konfiguration ausgeben
- [ ] T026 [P] [US-EA-17] (spec T20 Teil) Unit-Tests ohne Datenbank mit dem Node-Testrunner (`node --test --import tsx scripts/ea-migrate/*.test.ts`, Script `ea:migrate:test` in `package.json`): `csv.test.ts` (Kopfzeile fehlt, Datum, ja/nein, Listen, Jahresspalten, Formatfehler je Zeile), `report.test.ts` (Abschnitte, Zählungen, kein Schlüssel im Text), `index.test.ts` mit Ersatz für den RPC-Aufruf (Probelauf schreibt Prüfbericht; `--run` mit falscher Ref bricht ab; `--run` bei Fehlern im Probelauf bricht ab; leerer Schlüssel → „Schlüssel fehlt.“); Schritt „Tests des Migrationsskripts“ in `.github/workflows/db-tests.yml` ergänzen (nach „Tests der Edge Functions“, Node über `actions/setup-node@v4` und `npm ci`)
- [ ] T027 [P] [US-EA-17] (spec T20 Teil) Dateien im Repository: `scripts/ea-migrate/vorlage.csv` (nur Kopfzeile nach C3), `scripts/ea-migrate/beispiel.csv` (5 fiktive Zeilen nach spec.md Abschnitt 9: aktiv mit zwei Lizenzen und einer Nummer; ruhend mit abgelaufener historischer Lizenz TCSP und zwei Referaten; Helfer:in ohne Lizenz mit Ausgabe und Zugang extern; Fortbildungen 2019, 2023 und Erste Hilfe; Dublettenverdacht zu Toni Muster; Adressen `@example.test`, IBAN nur die Beispiel-IBAN), `scripts/ea-migrate/beispiel-fehler.csv` (unbekanntes Kürzel, ungültige IBAN); `.gitignore`: `scripts/ea-migrate/*.csv`, `!scripts/ea-migrate/vorlage.csv`, `!scripts/ea-migrate/beispiel.csv`, `!scripts/ea-migrate/beispiel-fehler.csv`, `*.pruefbericht.md`, `*.abschlussbericht.md`; `package.json`: Script `"ea:migrate": "tsx scripts/ea-migrate/index.ts"`, devDependencies `tsx`, `csv-parse`; Personendaten-Prüfung aus CLAUDE.md auf `scripts/`
- [ ] T028 [US-EA-18] Pull Request `us-ea-17-import` (Stories US-EA-17, US-EA-18; Tasks T021–T027; Cloudflare-Vorschau-URL); kein Auto-Merge (`scripts/`, `.github/`, `package.json`). Nach dem Merge: `npx supabase db push --linked` gegen TEST (Prüfung der Verknüpfung). Probelauf und Lauf gegen TEST mit den Beispieldateien (quickstart.md D11, D12) **führt der Admin aus**; Claude Code dokumentiert das Ergebnis nach Rückmeldung in `abnahme-test.md` (T069)

---

## Phase 4: US-EA-01 Navigation und Routenschutz (Branch `us-ea-01-navigation`)

**Ziel**: Routen /ea/*, Modulrahmen mit Navigation nach Rolle, Routenschutz ohne Abfrage von Personendaten, Kachel-Einstieg, Fehlercodes im Frontend.

**Unabhängiger Test**: Vorstand auf /ea → /kein-zugriff ohne Abfrage von `ea_persons` (Netzwerk-Tab); Referent:in sieht „Aktive · Ablauf“ und landet auf /ea/gremien auf /kein-zugriff; Geschäftsstelle sieht sechs Einträge (quickstart.md D1). Kachel erscheint erst nach T022 (Freischalten).

- [ ] T029 [P] [US-EA-01] (spec T10 Teil) `src/lib/rights.ts`: `requireAnyLevel(module, min)` (wie `requireLevel`, über `ad_has_any_level`); `src/lib/errors.ts`: neue Codes `EA_IBAN_INVALID`, `EA_STATUS_DATE` (Platzhalter `<TT.MM.JJJJ>` aus `details`, analog `withField`), `EA_STATUS_UNCHANGED`, `EA_LEAVE_PROPERTY`, `EA_RENEW_INVALID`, `EA_CREATE_FORBIDDEN` (→ `MESSAGES.forbidden`), `EA_CREATE_REFERAT_REQUIRED` („Bitte eine Funktion oder ein Amt in deinem Referat angeben.“), Constraints `ea_referate_name_key`, `ea_gremien_name_key` („Diese Bezeichnung gibt es bereits.“) nach T001
- [ ] T030 [P] [US-EA-01] (spec T10 Teil) `src/features/ea/access.ts`: `loadEaAccess()` (`requireAnyLevel('EA','read')`, dann parallel `hasLevel('EA','edit')`, `hasLevel('EA','manage')`, `rpc('ad_my_referate', { p_module: 'EA', p_min: 'edit' })`) → `EaAccess = { canEdit: boolean; canManage: boolean; myReferate: { id, name }[] | null }` (`null` = Reichweite alle); `requireEaManage()` für Verwaltungsseiten (→ /kein-zugriff); `useEaAccess()` über `useRouteLoaderData('ea')`; keine Abfrage auf Personendaten im Loader (US-EA-01 AK4)
- [ ] T031 [US-EA-01] (spec T10 Teil) `src/features/ea/EaLayout.tsx` nach Muster `AdLayout.tsx`: Navigation nach A6: mit `canManage` „Aktive · Ablauf · Gremien · Eigenschaftsarten · Qualifikationsarten · Referate und Gremien“, sonst „Aktive · Ablauf“; `handle: { moduleName: 'Ehrenamtsmanagement' }`
- [ ] T032 [US-EA-01] (spec T10 Teil) Routen in `src/App.tsx`: `{ id: 'ea', path: 'ea', loader: loadEaAccess, element: <EaLayout /> }` mit `index` → `redirect('/ea/aktive')`, Kinder `aktive`, `aktive/neu`, `aktive/:id`, `ablauf`, `gremien`, `stammdaten`, `eigenschaftsarten*`, `qualifikationsarten*` (zunächst `PlaceholderPage`, Verwaltungsseiten mit `requireEaManage`), `*` → Platzhalter; `src/features/start/modules.ts`: `MODULE_PATHS` um `EA: '/ea'` ergänzen (Kachel erscheint über `ad_my_modules` erst nach `is_available = true`, T022)
- [ ] T033 [P] [US-EA-01] `docs/specs/ad-administration/contracts/routes.md`: Eintrag „/ea/qualifikationsarten*“ durch Verweis auf [contracts/routes.md EA](contracts/routes.md) ersetzen
- [ ] T034 [US-EA-01] `npm run lint`, `npm run build`; Pull Request `us-ea-01-navigation` (Story US-EA-01; Tasks T029–T034; Vorschau-URL); Product Owner mergt

**Checkpoint**: Modulrahmen steht; Phasen 5, 6, 10–13 können parallel beginnen.

---

## Phase 5: US-EA-02, US-EA-03 Übersicht der Aktiven (Branch `us-ea-02-aktive`)

**Ziel**: /ea/aktive mit Suche, Filterleiste, URL-Zustand, Paginierung, mobilen Karten, Ablauf-Badge.

**Unabhängiger Test**: quickstart.md D2, D3 mit Geschäftsstelle und Referent:in; bei 375 px Karten ohne horizontales Scrollen; Filter bleiben nach Neuladen erhalten.

- [ ] T035 [P] [US-EA-11] (spec T11 Teil, T12 Teil) `src/features/ea/AblaufBadge.tsx`: Badge je `expiry_status`: `valid` „gültig“, `expiring` „läuft in ≤ 3 Monaten ab“, `expired` „abgelaufen“, `none` keine Anzeige; Varianten über `Badge` von shadcn/ui; wiederverwendet in Übersicht, Detail und Stichtagsliste
- [ ] T036 [US-EA-02] (spec T11 Teil) `src/features/ea/aktive/data.ts`: `VolunteerFilter` aus der URL (`q`, `status[]`, `referat[]`, `funktion`, `amt`, `gremium`, `qualifikation`, `sparte`, `ablauf[]`, `ohne-lizenz`, `ohne-zuordnung`, `seite`; Muster `readFilter`/`filterHref` der Administration); `loadAktive({ request })`: Zugriff aus `loadEaAccess` (Referent:in: Status ohne `left`, Referate auf eigene begrenzt und vorbelegt, R1, US-EA-03 AK4), parallel `rpc('ea_volunteer_list', { p_search, p_status, p_referate, p_function, p_position, p_gremium, p_qualification_type, p_discipline, p_expiry, p_trainer_without_license, p_without_assignment, p_limit: 50, p_offset })`, `ea_referate` (aktive, `sort_order`), `ea_gremien` (nur `canManage`), `ad_qualification_types` (alle, für Filter und Sparten), Auswahlwerte `function`/`position` aus `ea_property_fields` der Arten `function`/`position`; Ergebnis `{ filter, rows, total, options, failed }`; `VOLUNTEER_STATUS_LABELS` aus der Administration wiederverwenden
- [ ] T037 [US-EA-02] (spec T11 Teil) `src/features/ea/aktive/AktivePage.tsx` (/ea/aktive): Suchfeld (ab 1 Zeichen, URL-Update nach 300 ms Pause über `useSearchParams`), `ResponsiveTable` mit Spalten Name (`personName`, R2) als Link zum Detail, Status mit „seit TT.MM.JJJJ“, Referate, Funktionen und Ämter, Lizenzkürzel, `AblaufBadge` (`worst_expiry`), Kennzeichen „ohne gültige Lizenz“ (`trainer_without_license`); Karten unter 640 px; `Pagination` (50 je Seite, `total_count`); „Keine Aktiven gefunden.“; Knopf „Person anlegen“ nur bei `canEdit` oder `myReferate`; Fehler → `toMessage`
- [ ] T038 [US-EA-03] (spec T11 Teil) `src/features/ea/aktive/Filterleiste.tsx`: Filter Ehrenamtsstatus (Mehrfach; „ausgeschieden“ nur mit `canManage`, R1), Referat (Mehrfach; Referent:in nur eigene, vorbelegt), Funktion, Amt, Qualifikationsart (`QualifikationsartAuswahl` mit allen Status, optional nach Sparte eingeschränkt), Sparte, Ablaufstatus (Mehrfach), „Trainer:in ohne gültige Lizenz“, „aktiv ohne Funktion oder Amt“; Gremium nur mit `canManage`; jede Änderung schreibt die URL (A5) und setzt `seite` zurück; „Filter zurücksetzen“
- [ ] T039 [US-EA-02] `npm run lint`, `npm run build`; Pull Request `us-ea-02-aktive` (Stories US-EA-02, US-EA-03; Tasks T035–T039; Vorschau-URL); Product Owner mergt

---

## Phase 6: US-EA-04, US-EA-11 Personendetail (Branch `us-ea-04-detail`)

**Ziel**: /ea/aktive/:id mit Kopf, Statushistorie, Eigenschaften nach Kategorie mit Bezeichnungen (Ü1), Historie, Ablauf-Badges, Kennzeichen „Trainer:in ohne gültige Lizenz“; Schreibknöpfe als Einhängepunkte für Phasen 8 und 9.

**Unabhängiger Test**: quickstart.md D4 und D9 (Lena, Max im Detail) mit Geschäftsstelle und Referent:in; URL von Anton Muster als Referent:in → Meldung.

- [ ] T040 [US-EA-04] (spec T12 Teil) `src/features/ea/aktive/detail-data.ts`: `loadPersonDetail({ params })`: `ea_persons` (`id, first_name, preferred_name, last_name, kind, volunteer_status, volunteer_status_since`; `maybeSingle`; nicht lesbar oder leer → `{ person: null }` für die Meldung „Diese Person wurde nicht gefunden oder du hast keine Rechte.“, kein Redirect), `ea_volunteer_status_history` (`order set_at desc`, Namen über das Muster `loadUserNames`), Eigenschaften wie `loadPersonProperties` der Administration, aber Arten mit `visible_in` ∋ `EA` (Funktion aus `src/features/ad/personen/data.ts` um einen Parameter `module: ModuleCode = 'AD'` erweitern, additiv), `ea_v_expiry` mit `person_id = eq`, `rpc('ea_volunteer_list', { p_search: null, p_status: ['active','dormant','left'], … })` ist nicht nötig: `trainer_without_license` aus den geladenen Daten ableiten (aktuelle `function` Trainer:in ohne `ea_v_expiry`-Zeile `license` mit `valid_until >= heute`, R14); `writable(property)` = `canManage` oder (`canEdit`/`myReferate` und `related_referat_id` in `myReferate` und `read_level = 'all'`); die Datenbank prüft unabhängig davon
- [ ] T041 [US-EA-04] (spec T12 Teil) `src/features/ea/aktive/PersonDetailPage.tsx` (/ea/aktive/:id): Zurück-Link „Aktive“ (mit Filter-URL aus `state`), Kopf mit Name (R2), Vorname bei abweichendem Rufname, Status-Badge mit „seit TT.MM.JJJJ“, aufklappbare Statushistorie (Status, ab, gesetzt am, von), Kennzeichen „Trainer:in ohne gültige Lizenz“; Knopf „Status ändern“ (Einhängepunkt Phase 9; nur `canEdit` oder Person in `myReferate`); Meldung bei `person = null`
- [ ] T042 [US-EA-04] (spec T12 Teil) `src/features/ea/aktive/EigenschaftenEa.tsx`: Abschnitte je Kategorie in der Reihenfolge des Enums (`CATEGORIES` aus `eigenschaftsarten/data.ts`: Stammdaten, Kontakt, Zuordnung, Qualifikationen, Nachweise, Jahreseinträge, Ausgaben, Zugänge, Sonstiges), nur Kategorien mit Eigenschaften; je Eigenschaft Felder „Bezeichnung: Wert“ (Datum TT.MM.JJJJ, Ja/Nein, Qualifikationsart „Kürzel – Bezeichnung“ mit „(historisch)“), Bezug (Referat/Gremium), „gültig von/bis“ mit `valid_from_label`/`valid_to_label` der Art (Ü1, AK2), `AblaufBadge` für Zeilen aus `ea_v_expiry` (Lizenz, Qualifikation, Führungszeugnis), Historie aufklappbar (frühere Werte, geändert am/von, AK3); aktuelle oben, beendete eingeklappt unter „beendet (n)“; Bezug Gruppe nur lesen mit „Diese Angabe wird im Modul Gruppen gepflegt.“ (AK6); Knöpfe „Ändern“, „Beenden“, „Verlängern“ und „Eigenschaft hinzufügen“ als Props/Slots (Phase 8), nur wenn `writable` (AK4); „Noch keine Eigenschaften.“
- [ ] T043 [US-EA-04] Route `aktive/:id` in `src/App.tsx` auf `loadPersonDetail`/`PersonDetailPage` umstellen; `npm run lint`, `npm run build`; Pull Request `us-ea-04-detail` (Stories US-EA-04, US-EA-11; Tasks T040–T043; Vorschau-URL); Product Owner mergt

---

## Phase 7: US-EA-05, US-EA-10 Person anlegen (Branch `us-ea-05-person-anlegen`)

**Ziel**: /ea/aktive/neu mit erster Zuordnung, Dublettendialog mit „Vorhandene Person öffnen“, „Wieder aktivieren“, „Ins Ehrenamtsmanagement übernehmen“, „Trotzdem anlegen“.

**Unabhängiger Test**: quickstart.md D5 (Nina Neu, ohne Funktion, Anton Muster, Olga Ausgeschieden, Paul Nurgruppe) mit Referent:in und Geschäftsstelle.

- [ ] T044 [US-EA-05] (spec T13 Teil) `src/features/ea/aktive/neu-data.ts`: `loadPersonNeu()` (Zugriff: `canEdit` oder `myReferate`, sonst /kein-zugriff; Arten `function` und `position` mit Feldern über `system_key`; aktive Referate, Referent:in nur eigene); `findSimilarPersons` der Administration wiederverwenden; `createVolunteer({ first, preferred, last, typeId, referatId, fieldValues, validFrom })` → `rpc('ea_create_volunteer', { p_first, p_last, p_preferred, p_property_type, p_referat, p_field_values, p_valid_from })` (ohne Zuordnung: `p_property_type` null); `activatePerson(personId, …)` → `rpc('ea_activate_person', …)`
- [ ] T045 [US-EA-05] (spec T13) `src/features/ea/aktive/PersonNeuPage.tsx` (/ea/aktive/neu) nach Muster `PersonNeu.tsx` der Administration: Vorname, Nachname, Rufname; erste Zuordnung: Art (Funktion | Amt | keine – „keine“ nur für `canManage`), Wert (Auswahlwerte des Feldes `function` bzw. `position`), Referat (Referent:in: nur eigene, Pflicht; sonst optional), „seit“ (Standard heute); R4 AD („Bitte Vorname und Nachname angeben.“) und R3 (Referent:in ohne Funktion oder Amt → Meldung vor dem Aufruf, AK2) im Frontend; Speichern → `findSimilarPersons` → ohne Treffer `createVolunteer` → Detail; `training_units_per_week` nicht abfragen (später im Detail)
- [ ] T046 [US-EA-10] (spec T13 Teil) Dublettendialog in `PersonNeuPage.tsx`: `DublettenDialog` der Administration mit `hitAction`: `is_visible` → „Vorhandene Person öffnen“ (Link /ea/aktive/:id); `volunteer_status = 'left'` → „Wieder aktivieren“ (→ `activatePerson` mit der eingegebenen Zuordnung; Referent:in ohne Zuordnung → `EA_CREATE_REFERAT_REQUIRED`, AK5); `volunteer_status = null` → „Ins Ehrenamtsmanagement übernehmen“ (→ `activatePerson`); „Trotzdem anlegen“ → `createVolunteer`; nach Erfolg Detail der Person (AK1, AK2); nicht sichtbare Treffer zeigen nur Name und „ausgeschieden seit“ (AK4, Verhalten der Komponente)
- [ ] T047 [US-EA-05] `npm run lint`, `npm run build`; Pull Request `us-ea-05-person-anlegen` (Stories US-EA-05, US-EA-10; Tasks T044–T047; Vorschau-URL); Product Owner mergt

---

## Phase 8: US-EA-06, US-EA-07 Eigenschaften pflegen und verlängern (Branch `us-ea-06-eigenschaften`)

**Ziel**: Eigenschaft hinzufügen, ändern, beenden über das Eigenschaftsformular der Administration; Vorbelegung „gültig bis“ (R5); Dialog „Verlängern“ (R6, O2); IBAN-Hinweis.

**Unabhängiger Test**: quickstart.md D6 (Sven: Ausgabe anlegen und beenden, IBAN „DE00 1234“) und D7 (TCSPI 15.05.2026 mit/ohne Fortbildung; Toni verlängern) mit Referent:in und Geschäftsstelle.

- [ ] T048 [US-EA-07] (spec T14 Teil) `src/features/shared/Eigenschaftsformular.tsx` additiv erweitern: optionale Prop `deriveValues?: (draft: { field_values: FieldValues; valid_from: string }, changedKey: string) => Promise<Partial<FieldValues> | null>`; nach Änderung von `qualification_type`, `valid_from` oder `last_training` wird sie aufgerufen und das Ergebnis in Felder geschrieben, die der Nutzer nicht selbst geändert hat (Kennzeichen „vom Nutzer geändert“ je Feld; R5, research.md R-EA-13); ohne die Prop unverändertes Verhalten (Administration)
- [ ] T049 [US-EA-06] (spec T14 Teil) `src/features/ea/aktive/eigenschaften-data.ts`: `saveProperty` der Administration wiederverwenden; `addableTypes(types, access)`: Arten mit `visible_in` ∋ `EA`, bei Referent:in nur `read_level = 'all'` (AK5), `relation_kind = 'group'` ausgeschlossen; `defaultValidUntil(typeKey, fieldValues, validFrom)` → `rpc('ea_default_valid_until', { p_qualification_type, p_valid_from, p_last_training })` nur bei `license`/`qualification`; `checkIban(iban)` → `rpc('ea_iban_valid')` für einen Hinweis vor dem Speichern (die Datenbank prüft beim Schreiben, R13)
- [ ] T050 [US-EA-06] (spec T14) Dialog „Eigenschaft“ in `src/features/ea/aktive/EigenschaftDialog.tsx`, eingehängt in `EigenschaftenEa.tsx`: „Eigenschaft hinzufügen“ (Auswahl der Art aus `addableTypes`, dann `Eigenschaftsformular` mit `restrictReferate` = `myReferate` bei Reichweite Referat, `deriveValues` bei Lizenz/Qualifikation, `QualifikationsartAuswahl` zeigt nur Status „aktuell“ und erlaubte Typen, AK4 US-EA-07); „Ändern“; „Beenden“ (nur `valid_to`, Standard heute, Bezeichnung der Art, AK2); Fehler je Feld und Codes (`EA_IBAN_INVALID`, `EA_RELATION_FOREIGN_REFERAT`, `AD_QUALIFICATION_HISTORIC`) über `toMessage`; nach Erfolg `revalidate`
- [ ] T051 [US-EA-07] (spec T14 Teil, O2) `src/features/ea/aktive/VerlaengernDialog.tsx`: Knopf „Verlängern“ nur bei aktuellen Eigenschaften der Arten `license`/`qualification`, deren Qualifikationsart `status = 'current'` hat (O2) und die `writable` sind; Felder „erworben bzw. verlängert am“ (Pflicht, Standard heute), „letzte Fortbildung“, „gültig bis“ (vorbelegt über `ea_default_valid_until`, änderbar, Kennzeichen „vom Nutzer geändert“), Schalter „Fortbildung anlegen“ mit Jahr (Standard Jahr des Datums) und Titel; Speichern → `rpc('ea_renew_property', { p_property, p_valid_from, p_field_values: { valid_until, last_training }, p_training })`; Fehler `EA_RENEW_INVALID` u. a. über `toMessage`
- [ ] T052 [US-EA-06] `npm run lint`, `npm run build`; prüfen, dass das Eigenschaftsformular in der Administration unverändert arbeitet (Person anlegen/ändern unter /ad); Pull Request `us-ea-06-eigenschaften` (Stories US-EA-06, US-EA-07; Tasks T048–T052; Vorschau-URL); Product Owner mergt

---

## Phase 9: US-EA-08, US-EA-09 Status ändern und Ausscheiden (Branch `us-ea-08-status`)

**Ziel**: Dialog „Status ändern“ mit Bestätigung bei weiteren Referaten (R7) und zweitem Schritt „Ausscheiden“ (R8).

**Unabhängiger Test**: quickstart.md D8 (Toni ruhend; Karl ruhend mit Bestätigung; Sven ausgeschieden zum 31.12.2026) mit Geschäftsstelle und Referent:in.

- [ ] T053 [US-EA-08] (spec T15 Teil) `src/features/ea/aktive/status-data.ts`: `loadStatusContext(personId)` → `rpc('ea_person_referate', { p_person })` und `myReferate` (R7: Referate außerhalb der eigenen; bei Reichweite alle: mehr als ein Referat); `changeStatus(personId, status, validFrom)` → `rpc('ea_change_volunteer_status')`; `leave(personId, validFrom, endIds)` → `rpc('ea_leave')`; `leaveCandidates(properties, types, access)`: aktuelle `function`/`position`/`committee` → `{ property, writable, groupRelation }`; Hinweise: aktuelle `issued_item` („<Gegenstand> – nicht zurückgegeben“) und `external_access` („<System> – läuft“)
- [ ] T054 [US-EA-08] (spec T15) `src/features/ea/aktive/StatusDialog.tsx`, eingehängt über „Status ändern“ in `PersonDetailPage.tsx`: Auswahl aktiv/ruhend/ausgeschieden ohne den aktuellen Status („ausgeschieden → aktiv“ nur `canManage`, spec.md Abschnitt 4), Datum (Standard heute); bei weiteren Referaten Bestätigung „Die Person ist auch in <Referate> tätig. Der Status gilt für alle Referate.“ mit „Bestätigen“/„Abbrechen“ (R7, AK2); Speichern → `changeStatus`; Fehler `EA_STATUS_DATE` (mit Datum aus `details`), `EA_STATUS_UNCHANGED`, `EA_STATUS_FORBIDDEN`; nach Erfolg `revalidate` (AK1, AK3)
- [ ] T055 [US-EA-09] (spec T15 Teil) `src/features/ea/aktive/AusscheidenSchritt.tsx` als zweiter Schritt im `StatusDialog` bei „ausgeschieden“: Checkboxen für schreibbare Kandidaten, vorausgewählt, abwählbar; nicht schreibbare als „wird nicht beendet (anderes Referat)“; Gruppen-Bezug als „im Modul Gruppen beenden“; Hinweise zu Ausgaben und Zugängen extern (AK1, AK3, AK4); Bestätigen → `leave` mit den gewählten IDs; `EA_LEAVE_PROPERTY` und sonstige Fehler → Meldung, Status bleibt (AK6); nach Erfolg zurück zur Übersicht, wenn die Person für den Nutzer unsichtbar wird (Referent:in, AK5), sonst `revalidate`
- [ ] T056 [US-EA-08] `npm run lint`, `npm run build`; Pull Request `us-ea-08-status` (Stories US-EA-08, US-EA-09; Tasks T053–T056; Vorschau-URL); Product Owner mergt

---

## Phase 10: US-EA-12 Stichtagsliste (Branch `us-ea-12-ablauf`)

**Ziel**: /ea/ablauf mit Jahresauswahl, Tabelle aus `ea_v_expiry`, CSV-Export nur mit „verwalten“.

**Unabhängiger Test**: quickstart.md D9 („Ablauf“ 2027, CSV in Excel lesbar) mit Geschäftsstelle; Referent:in sieht nur eigene Referate und keinen Export.

- [ ] T057 [US-EA-12] (spec T16 Teil) `src/features/ea/ablauf/data.ts`: `loadAblauf({ request })`: Jahr aus `?jahr=` (Standard Folgejahr; erlaubt aktuelles Jahr bis +3), `ea_v_expiry` mit `kind in (license, qualification)`, `valid_until gte <jahr>-01-01`, `lte <jahr>-12-31`, `order valid_until`; Namen und Referate je Person über `rpc('ea_volunteer_list', { p_status: ['active','dormant'], p_limit: 200, p_offset })`, bei `total_count > 200` seitenweise nachladen (research.md R-EA-06); Zeilen `{ person, referate, code, name, valid_until, expiry_status }` sortiert nach `valid_until`, dann Name
- [ ] T058 [US-EA-12] (spec T16 Teil) `src/features/ea/ablauf/AblaufPage.tsx` (/ea/ablauf): Jahresauswahl (URL), `ResponsiveTable` mit Name (Link zum Detail), Referate, „Kürzel – Bezeichnung“, gültig bis, `AblaufBadge`; „Im Jahr <jahr> läuft keine Qualifikation ab.“; Knopf „CSV exportieren“ nur `canManage` (AK4)
- [ ] T059 [P] [US-EA-12] (spec T16 Teil) `src/features/ea/ablauf/csv.ts`: `toCsv(rows)` mit BOM `﻿`, Semikolon, Zeilenende CRLF, Felder mit Semikolon, Anführungszeichen oder Zeilenumbruch in Anführungszeichen (verdoppelt); Spalten `Nachname;Vorname;Rufname;Referate;Kürzel;Bezeichnung;gültig bis` (Datum TT.MM.JJJJ, Referate mit „, “); `downloadCsv(name, text)` über `Blob` und `URL.createObjectURL`; Dateiname `ablauf-<jahr>.csv`; keine Kontaktdaten (AK3)
- [ ] T060 [US-EA-12] `npm run lint`, `npm run build`; Pull Request `us-ea-12-ablauf` (Story US-EA-12; Tasks T057–T060; Vorschau-URL); Product Owner mergt

---

## Phase 11: US-EA-13 Gremium-Sichten (Branch `us-ea-13-gremien`)

**Ziel**: /ea/gremien je aktivem Gremium mit aktuellen Mitgliedschaften.

**Unabhängiger Test**: quickstart.md D10 (Greta unter Beirat; leeres Gremium) mit Geschäftsstelle; Referent:in → /kein-zugriff.

- [ ] T061 [US-EA-13] (spec T17) `src/features/ea/gremien/GremienPage.tsx` mit Loader `loadGremien()` in derselben Datei oder `data.ts`: `requireEaManage()`; `ea_gremien` (`is_active`, `sort_order`), `ea_properties` der Art `committee` (über `system_key`) mit `ea_persons(id, first_name, preferred_name, last_name)`, nur aktuelle (`valid_from <= heute`, `valid_to` null oder ≥ heute); je Gremium Tabelle Name (Link /ea/aktive/:id), Rolle (`field_values.role`), seit, bis (mit Bezeichnungen der Art); „Keine Mitglieder eingetragen.“ je Gremium ohne Zeilen; Route in `src/App.tsx`
- [ ] T062 [US-EA-13] `npm run lint`, `npm run build`; Pull Request `us-ea-13-gremien` (Story US-EA-13; Tasks T061–T062; Vorschau-URL); Product Owner mergt

---

## Phase 12: US-EA-14 Referate und Gremien pflegen (Branch `us-ea-14-stammdaten`)

**Ziel**: /ea/stammdaten mit zwei Listen und Formular (Bezeichnung, Reihenfolge, aktiv).

**Unabhängiger Test**: quickstart.md D10 (Referat „Naturschutz“ anlegen, danach in Zuordnungen wählbar; doppelte Bezeichnung → Meldung); Referent:in → /kein-zugriff.

- [ ] T063 [US-EA-14] (spec T18) `src/features/ea/stammdaten/StammdatenPage.tsx` (/ea/stammdaten) mit `data.ts`: Loader `requireEaManage()`, `ea_referate` und `ea_gremien` vollständig (`order sort_order`); zwei Listen mit Bezeichnung, Reihenfolge, Status (aktiv/inaktiv); „Neu“ und „Bearbeiten“ als Inline-Formular (`name` Pflicht, `sort_order` Zahl, `is_active` Schalter); `insert`/`update` direkt (RLS der Administration, R12 AD); Fehler `ea_referate_name_key`/`ea_gremien_name_key` → „Diese Bezeichnung gibt es bereits.“ (AK3); inaktive bleiben in Listen, sind aber nicht mehr neu wählbar (AK4, Verhalten des Eigenschaftsformulars); Route in `src/App.tsx`
- [ ] T064 [US-EA-14] `npm run lint`, `npm run build`; Pull Request `us-ea-14-stammdaten` (Story US-EA-14; Tasks T063–T064; Vorschau-URL); Product Owner mergt

---

## Phase 13: US-EA-15 Eigenschafts- und Qualifikationsarten einhängen (Branch `us-ea-15-arten`)

**Ziel**: /ea/eigenschaftsarten* und /ea/qualifikationsarten* mit den Komponenten der Administration, Schutz `ad_has_level('EA','manage')`.

**Unabhängiger Test**: quickstart.md D10 (Eigenschaftsart „Schlüssel Materiallager“ unter /ea anlegen, danach bei „Eigenschaft hinzufügen“ wählbar); Geschäftsstelle kann „vertraulich“ nicht wählen; Referent:in → /kein-zugriff.

- [ ] T065 [US-EA-15] (spec T19 Teil) Loader der Administration modulfähig machen (additiv): `loadPropertyTypes`, `loadNewPropertyType`, `loadPropertyType`, `loadQualificationTypes`, `loadNewQualificationType`, `loadQualificationType` in `src/features/ad/eigenschaftsarten/data.ts` und `src/features/ad/qualifikationsarten/data.ts` erhalten eine Variante bzw. einen Parameter, der statt `requireLevel('AD','read')` die Prüfung `requireEaManage()` nutzt (z. B. `withAccess(loader, check)`); die Komponenten `EigenschaftsartenListe`, `EigenschaftsartBearbeiten`, `QualifikationsartenListe`, `QualifikationsartFormular` leiten interne Links (`/ad/eigenschaftsarten…`) über einen Basis-Pfad aus `useMatches()`/`handle` oder einer optionalen Prop `basePath` ab (Standard `/ad`); `canEditQualificationTypes()` bleibt (Geschäftsstelle über EA = verwalten); Lesestufe „vertraulich“ nur mit AD (Verhalten der Komponente, AK4)
- [ ] T066 [US-EA-15] (spec T19) Routen `/ea/eigenschaftsarten`, `/neu`, `/:id`, `/ea/qualifikationsarten`, `/neu`, `/:id` in `src/App.tsx` mit den EA-Loadern und denselben Komponenten; Navigation in `EaLayout.tsx` verweist darauf; Platzhalter entfernen
- [ ] T067 [US-EA-15] `npm run lint`, `npm run build`; prüfen, dass /ad/eigenschaftsarten* und /ad/qualifikationsarten* unverändert funktionieren; Pull Request `us-ea-15-arten` (Story US-EA-15; Tasks T065–T067; Vorschau-URL); Product Owner mergt

---

## Phase 14: Abnahme und Querschnitt (Branch `ea-abnahme`)

**Ziel**: Fachliche Abnahme nach quickstart.md D in TEST; Korrekturen aus der Abnahme; Qualitätsprüfung.

- [ ] T068 (spec T21 Teil) TEST auf Stand (nach Prüfung der Verknüpfung): `npx supabase db push --linked`; Seed-Neuaufbau nach quickstart.md B nur auf Auftrag des Product Owners; Cloudflare-Vorschau des Branches
- [ ] T069 (spec T21) Szenarien quickstart.md D1–D10 und D13 mit Admin, Geschäftsstelle, Rita Referentin (Klettern), Vorstand abnehmen, auch bei 375 px; `[PRÜFEN T21]`-Punkte aus research.md (Statement-Timeout beim Import, R-EA-10) nach Rückmeldung des Admins abhaken oder melden; Ergebnis je Story in `docs/specs/ea-ehrenamt/abnahme-test.md` (ohne private Adressen); D11, D12 (Skript) und Ergebnis des Admins dort eintragen
- [ ] T070 [P] (spec T21 Teil) Querschnitt: `npm run lint`, `npm run build`, `npm run ea:migrate:test` ohne Fehler; `npm audit` und Ergebnis melden; Personendaten-Prüfung aus CLAUDE.md auf `docs`, `PRODUCT.md`, `scripts/`, `supabase/seed.sql`; keine Secrets im Diff
- [ ] T071 Korrekturen aus der Abnahme als Tasks T072 ff. hier ergänzen (je Befund: Story, Datei, Änderung) und umsetzen; fachliche Abweichungen als `[OFFEN]` an den Product Owner; Pull Request `ea-abnahme`; Product Owner mergt, sofern Oberfläche enthalten

---

## Phase 15: Freischalten (Branch `ea-freischalten`)

**Ziel**: Modul auf der Startseite sichtbar (US-EA-01 AK1).

- [ ] T072 [US-EA-01] (spec T22) Migration `supabase/migrations/20261023002800_ea_module_available.sql`: `update public.ad_modules set is_available = true where code = 'EA'`; pgTAP in `300_ea_system_types.test.sql` oder neue `390_ea_module.test.sql`: `is_available` für EA wahr, `ad_my_modules()` liefert EA für Geschäftsstelle und Referent:in, nicht für Vorstand; Pull Request mit Auto-Merge (nur Migration und Test)
- [ ] T073 [US-EA-01] Nach dem Merge `npx supabase db push --linked` gegen TEST (Prüfung der Verknüpfung); quickstart.md D14 (Kachel „Ehrenamtsmanagement“ für Geschäftsstelle) abnehmen und in `abnahme-test.md` eintragen
- [ ] T074 (spec T23) **Lauf gegen PROD durch den Admin, nicht durch Claude Code** (quickstart.md E): Excel-Liste zum Stichtag einfrieren, nach `vorlage.csv` übertragen, Probelauf, Korrektur, Lauf, Abschlussbericht prüfen, Excel-Liste archivieren. Voraussetzung: Weg der Migrationen nach PROD (O1 der Administration) geklärt. Claude Code liest keine Dateien daraus und trägt nur die Rückmeldung „erledigt am …“ in `abnahme-test.md` ein

---

## Abhängigkeiten und Reihenfolge

- **Phase 1 → Phase 2**: T001 vor den Frontend-Codes (T029); T002 nur auf Auftrag.
- **Phase 2 blockiert alles Weitere**: Tests T003–T011 parallel; dann T012 → T013, T014 (T014 braucht T012 für die `system_key`-Auflösung); T015 (braucht T012, T014 für die erwarteten Ergebnisse); T016, T017, T018 parallel nach T015; T019, T020 zuletzt.
- **Phase 3** nach Phase 2 (T022 braucht `ea_iban_valid`, `ea_default_valid_until`); T023, T024, T026, T027 parallel zu T021/T022; T025 nach T023, T024.
- **Phase 4** nach Phase 2 (Codes), unabhängig von Phase 3.
- **Phasen 5, 6, 10, 11, 12, 13** nach Phase 4, untereinander parallel (verschiedene Dateien; gemeinsame Datei `src/App.tsx` → Merge-Konflikte je PR auflösen).
- **Phase 7** nach Phase 6 (Detail als Ziel nach dem Anlegen).
- **Phase 8** nach Phase 6 (hängt in `EigenschaftenEa.tsx` ein); T048 parallel vorab möglich.
- **Phase 9** nach Phase 6 (hängt in `PersonDetailPage.tsx` ein).
- **Phase 14** nach Phasen 2–13; **Phase 15** nach Phase 14; T074 nach T073.

### Parallelbeispiel Phase 2

```bash
# Tests zuerst, verschiedene Dateien:
Task: "300_ea_system_types.test.sql" (T003)
Task: "310_ea_qualification_types.test.sql" (T004)
Task: "320_ea_expiry.test.sql" (T005)
Task: "330_ea_volunteer_list.test.sql" (T006)
Task: "340_ea_iban.test.sql" (T007)
Task: "350_ea_status.test.sql" (T008)
Task: "360_ea_renew.test.sql" (T009)
Task: "380_ea_volume.test.sql" (T010)
# danach Migrationen in der Reihenfolge T012 → T013 | T014 → T015 → T016 | T017 | T018
```

### Parallelbeispiel nach Phase 4

```bash
Task: "us-ea-02-aktive" (T035–T039)
Task: "us-ea-04-detail" (T040–T043)
Task: "us-ea-12-ablauf" (T057–T060)
Task: "us-ea-13-gremien" (T061–T062)
Task: "us-ea-14-stammdaten" (T063–T064)
Task: "us-ea-15-arten" (T065–T067)
```

## Umsetzungsstrategie

1. **Datenbank zuerst (Phase 2)**: ein PR mit Auto-Merge; danach ist jede Story in CI nachweisbar.
2. **MVP-Oberfläche**: Phase 4 (Navigation) → Phase 5 (Übersicht) → Phase 6 (Detail). Damit sind US-EA-01, 02, 03, 04, 11 abnehmbar.
3. **Pflege**: Phasen 7, 8, 9 (Anlegen, Eigenschaften, Status) → US-EA-05–10.
4. **Listen und Stammdaten**: Phasen 10–13, parallel zu 7–9 möglich.
5. **Import**: Phase 3 parallel zur Oberfläche; Lauf gegen TEST durch den Admin.
6. **Abnahme und Freischalten**: Phasen 14, 15; T074 durch den Admin.

## Zusammenfassung

| Phase | Branch | Stories | Tasks | Anzahl |
|---|---|---|---|---|
| 1 | ea-datenbank | – | T001–T002 | 2 |
| 2 | ea-datenbank | US-EA-16, 19 (+ DB von 02–12) | T003–T020 | 18 |
| 3 | us-ea-17-import | US-EA-17, 18 | T021–T028 | 8 |
| 4 | us-ea-01-navigation | US-EA-01 | T029–T034 | 6 |
| 5 | us-ea-02-aktive | US-EA-02, 03 | T035–T039 | 5 |
| 6 | us-ea-04-detail | US-EA-04, 11 | T040–T043 | 4 |
| 7 | us-ea-05-person-anlegen | US-EA-05, 10 | T044–T047 | 4 |
| 8 | us-ea-06-eigenschaften | US-EA-06, 07 | T048–T052 | 5 |
| 9 | us-ea-08-status | US-EA-08, 09 | T053–T056 | 4 |
| 10 | us-ea-12-ablauf | US-EA-12 | T057–T060 | 4 |
| 11 | us-ea-13-gremien | US-EA-13 | T061–T062 | 2 |
| 12 | us-ea-14-stammdaten | US-EA-14 | T063–T064 | 2 |
| 13 | us-ea-15-arten | US-EA-15 | T065–T067 | 3 |
| 14 | ea-abnahme | alle | T068–T071 | 4 |
| 15 | ea-freischalten | US-EA-01 (AK1), T23 | T072–T074 | 3 |
| | | | **gesamt** | **74** |
