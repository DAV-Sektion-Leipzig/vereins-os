# Data Model: Ehrenamtsmanagement (EA)

Stand: 22.10.2026 · Phase 1 zu [plan.md](plan.md) · Grundlage: [spec.md](spec.md) v0.2, Abschnitte 2 und 3

Führend ist spec.md. Das Ehrenamtsmanagement legt **keine Tabellen** an. Es arbeitet auf den Tabellen der Administration ([data-model.md Administration](../ad-administration/data-model.md)) mit deren RLS. Diese Datei beschreibt, **welche** Objekte das Ehrenamtsmanagement ergänzt: Migrationsdateien, Stammdaten, View, Funktionen, Trigger und Grants. Begründungen stehen in [research.md](research.md).

## Migrationsdateien

Präfix `20261024`, nach allen Kern-Migrationen der Administration (letzte: `20261023001700`; research.md R-EA-01). Reihenfolge = Dateiname.

| Datei | spec-Task | Inhalt |
|---|---|---|
| `…000100_ea_system_property_types.sql` | T1 | 25 System-Eigenschaftsarten mit Feldern und Bezeichnungen (C2, C2a) |
| `…000200_ea_qualification_types.sql` | T2 | 10 Qualifikationsarten (C4) |
| `…000300_ea_expiry_list.sql` | T4 | `ea_expiry_status`, `ea_default_valid_until`, View `ea_v_expiry`, `ea_volunteer_list`, Index `ea_properties_valid_until_idx` |
| `…000400_ea_iban.sql` | T5 | `ea_iban_normalize`, `ea_iban_valid`, Trigger `ea_properties_iban` |
| `…000500_ea_status_renew.sql` | T6 | `ea_change_volunteer_status`, `ea_leave`, `ea_renew_property` |
| `…000600_ea_check_create.sql` | O3 | `ea_check_create` neu (`create or replace`): `EA_CREATE_FORBIDDEN`, `EA_CREATE_REFERAT_REQUIRED` |
| `…000700_ea_import.sql` | T7 | `ea_import_volunteers` (nur `service_role`) |
| `…000800_ea_module_available.sql` | T22 | `ad_modules.is_available = true` für EA (erst nach der Abnahme, eigener Branch) |

Jede Migration widerruft für die Funktionen, die sie anlegt, zuerst die Rechte: `revoke execute … from public, anon`. Danach vergibt sie `grant execute … to authenticated` (Ausnahme T7: nur `service_role`) bzw. `grant select on ea_v_expiry to authenticated` (R-02 AD). Alle Funktionen haben einen festen `search_path` (spec.md 2.3); security-definer-Funktionen nutzen `set search_path = ''` und voll qualifizierte Namen.

## Stammdaten

### System-Eigenschaftsarten (T1)

25 Zeilen in `ea_property_types` mit `origin = 'system'` und je ≥ 1 Zeile in `ea_property_fields`. Inhalt verbindlich nach 01-erhebung.md C2 und C2a, Abbildung der Spalten nach spec.md 2.1.

| system_key | category | read_level | relation_kind (required) | allow_multiple | visible_in | Felder (`key`: Typ, * = Pflicht) | valid_from_label / valid_to_label |
|---|---|---|---|---|---|---|---|
| `member` | master_data | all | none | false | AD, EA, GR | `is_member`: boolean*, `member_number`: text | seit / bis |
| `birth_date` | master_data | office | none | false | AD, EA, GR | `date`: date* | – / – |
| `gender` | master_data | office | none | false | AD, EA | `gender`: choice* | – / – |
| `contact` | contact | all | none | false | AD, EA, GR | `email`, `phone_mobile`, `phone_landline`, `street`, `postal_code`, `city`, `dav_email`: text | – / – |
| `bank_account` | master_data | office | none | false | AD, EA | `account_holder`: text*, `iban`: text* | – / – |
| `function` | assignment | all | referat (false) | true | AD, EA | `function`: choice*, `training_units_per_week`: number | seit / bis |
| `position` | assignment | all | referat (false) | true | AD, EA | `position`: choice* | Amtszeit von / Amtszeit bis |
| `committee` | assignment | all | gremium (true) | true | AD, EA | `role`: choice* | seit / bis |
| `license` | qualification | all | none | true | AD, EA | `qualification_type`: qualification_type* {license}, `valid_until`: date*, `license_number`: text, `dosb_valid_until`: date, `last_training`: date | erworben bzw. verlängert am / beendet am |
| `qualification` | qualification | all | none | true | AD, EA | `qualification_type`: qualification_type* {add_on, course, training}, `valid_until`: date, `detail`: text | erworben bzw. verlängert am / beendet am |
| `further_training` | qualification | all | none | true | AD, EA | `year`: year*, `title`: text*, `qualification_type`: qualification_type {license} | Datum / – |
| `id_card` | proof | all | none | true | AD, EA | `card_number`: text*, `copy_available`: boolean | ausgestellt am / ungültig ab |
| `police_clearance` | proof | office | none | false | AD, EA | `issued_on`: date* | eingesehen am / – |
| `code_of_conduct` | proof | all | none | false | AD, EA | `signed`: boolean* | unterschrieben am / beendet am |
| `trainer_agreement` | proof | office | none | false | AD, EA | `signed`: boolean* | unterschrieben am / beendet am |
| `tax_free_confirmation` | proof | office | none | true | AD, EA | `year`: year | abgegeben am / – |
| `volunteer_allowance_declaration` | proof | office | none | true | AD, EA | `year`: year* | abgegeben am / – |
| `license_stamp` | yearly | all | none | true | AD, EA | `year`: year* | ausgegeben am / – |
| `funding` | yearly | office | none | true | AD, EA | `year`: year*, `applied`: boolean*, `funder`: text | – / – |
| `issued_item` | issue | all | none | true | AD, EA | `item`: choice*, `number`: text, `year`: year | ausgegeben am / zurückgegeben am |
| `volunteer_pass` | issue | all | none | true | AD, EA | `valid_until`: date | ausgegeben am / – |
| `external_access` | external_access | all | none | true | AD, EA | `system`: choice* | seit / bis |
| `award` | other | all | none | true | AD, EA | `kind`: text* | verliehen am / – |
| `employment` | other | confidential | none | true | AD | `title`: text* | seit / bis |
| `volunteer_agreement` | proof | office | none | false | AD, EA | `signed`: boolean* | unterschrieben am / beendet am |

„–“ = null (Standardbezeichnung). Namen, Zweck, Feldbezeichnungen und Auswahlwerte stehen wörtlich in C2. Auswahlwerte: `gender` {weiblich, männlich, divers, keine Angabe}; `function` {Trainer:in, Helfer:in}; `position` {Referent:in, stellv. Referent:in, Hüttenwart:in}; `role` {Mitglied, Vorsitz}; `item` {Schlüssel NoLimit, Schlüssel K4, K4-Karte, Jahreskarte, Vereinsjacke}; `system` {DAV360, Forms, JDAV Aktiven-Mailverteiler, Redaktion, Mailingliste}.

Von anderen Modulen genutzte Schlüssel (dürfen sich nicht ändern): `birth_date.date`, `contact.email`, `contact.dav_email` (Administration); `function.function` = „Helfer:in“ (AD v0.8, Anwesenheitserfassung); `license.qualification_type`, `license.valid_until` (AD v0.9, Planungshilfe); Nachweise Nr. 5, 15–17, 25 (Finanzen).

### Qualifikationsarten (T2)

10 Zeilen in `ad_qualification_types` nach spec.md 2.2 und 01-erhebung.md C4: EH, RS (`training`, 2 Jahre, Allgemein, extern); AMAK, AMBS, AMHT, AMKS, AMMB, AMSB, AMSH, AMSK (`course`, Jugend und Familie, Bundesverband (JDAV)). `status = 'current'`, `source_ref`, `level` null.

## View

### ea_v_expiry (T4)

- `create view … with (security_invoker = true)`; Spalten nach spec.md 2.3 (`person_id`, `property_id`, `property_type_id`, `system_key`, `kind`, `qualification_type_id`, `qualification_code`, `qualification_name`, `discipline`, `valid_until`, `expiry_status`).
- Zeilen: aktuelle Eigenschaften der Arten `license`, `qualification`, `police_clearance` von Personen mit Status `active` oder `dormant`. Bei `police_clearance` ist `valid_until = issued_on + 3 Jahre` (R10).
- Lesen: `grant select … to authenticated`. Welche Zeilen sichtbar sind, entscheidet die RLS auf `ea_properties` und `ea_persons` (R29 AD, R32 AD).

## Funktionen

| Funktion | Art | Grant | Migration | Regeln |
|---|---|---|---|---|
| `ea_expiry_status(date, date default current_date) returns text` | sql, immutable | authenticated | T4 | R9 |
| `ea_default_valid_until(uuid, date, date default null) returns date` | sql, stable, security invoker | authenticated | T4 | R5 |
| `ea_volunteer_list(p_search, p_status, p_referate, p_function, p_position, p_gremium, p_qualification_type, p_discipline, p_expiry, p_trainer_without_license, p_without_assignment, p_limit, p_offset) returns table (…)` | sql, stable, security invoker | authenticated | T4 | R1, R2, R14, R32 AD |
| `ea_iban_normalize(text) returns text` | sql, immutable | authenticated | T5 | R13 |
| `ea_iban_valid(text) returns boolean` | plpgsql, immutable | authenticated | T5 | R13 |
| `ea_change_volunteer_status(uuid, ea_volunteer_status, date) returns void` | plpgsql, security invoker | authenticated | T6 | R18, R19, R33 AD |
| `ea_leave(uuid, date, uuid[]) returns void` | plpgsql, security invoker | authenticated | T6 | R8, R18, R20, R33 AD |
| `ea_renew_property(uuid, date, jsonb, jsonb default null) returns uuid` | plpgsql, security invoker | authenticated | T6 | R6 |
| `ea_import_volunteers(jsonb, date, boolean) returns jsonb` | plpgsql, security definer | **nur service_role** | T7 | R13, R15–R17 |
| Trigger-Funktion `ea_properties_iban()` | plpgsql, security invoker | keiner | T5 | R13 |

Parameter, Rückgaben und Fehlercodes: [contracts/database-api.md](contracts/database-api.md).

Genutzt aus der Administration, unverändert: `ea_set_volunteer_status`, `ea_person_referate`, `ea_create_volunteer`, `ea_activate_person`, `ad_find_similar_persons`, `ad_first_names_match`, `ad_my_referate`, `ad_has_level`, `ad_has_any_level`, `ea_property_writable`, `ea_save_property_type`.

## Trigger

| Trigger | Tabelle | Zeitpunkt | Wirkung |
|---|---|---|---|
| `ea_properties_iban` | `ea_properties` | before insert or update, for each row | bei `system_key = 'bank_account'`: IBAN normalisieren; ungültig → `EA_IBAN_INVALID`. Läuft alphabetisch vor `ea_properties_validate` der Administration. |

## Indizes

- `ea_properties_valid_until_idx` on `ea_properties ((field_values->>'valid_until')) where field_values ? 'valid_until'` (T4).

## Zustände

Ehrenamtsstatus nach spec.md Abschnitt 4. Jeder Wechsel läuft über `ea_set_volunteer_status`, `ea_create_volunteer` oder `ea_activate_person` (Administration) und schreibt `ea_volunteer_status_history`. Die Funktionen des Ehrenamtsmanagements (`ea_change_volunteer_status`, `ea_leave`) prüfen nur zusätzlich (R18–R20) und rufen dann `ea_set_volunteer_status` auf.

Ablaufstatus: berechnet, nie gespeichert (`ea_expiry_status`).

## Testdaten

Seed nach spec.md Abschnitt 9 (research.md R-EA-05): Umstellung der Personen 2–12 auf System-Eigenschaftsarten; Personen 19–22 mit festen UUIDs. Erwartete Ergebnisse sind die Grundlage der pgTAP-Tests (research.md R-EA-12).

| # | Person | UUID (Muster der Administration) | Ehrenamtsstatus | Eigenschaften (System-Eigenschaftsart) |
|---|---|---|---|---|
| 19 | Lena Lizenz | `…19` | aktiv seit 01.01.2024 | `function` Trainer:in (Klettern); `license` TCBO, `TEST-0019`, gültig von 01.06.2022, `valid_until` = heute + 2 Monate |
| 20 | Max Abgelaufen | `…20` | aktiv seit 01.01.2020 | `function` Trainer:in (Kinder und Jugend); `license` TCSPI, gültig von 01.05.2021, `valid_until` 31.12.2025; `police_clearance` `issued_on` = heute − 34 Monate, gültig von = `issued_on` + 7 Tage |
| 21 | Greta Gremium | `…21` | aktiv seit 01.01.2023 | `committee` Beirat, Mitglied, seit 01.07.2023 |
| 22 | Sven Schlüssel | `…22` | aktiv seit 01.01.2025 | `function` Helfer:in (Klettern); `issued_item` Schlüssel K4, `TEST-K4-22`, gültig von 01.02.2025; `external_access` DAV360 seit 01.02.2025; `bank_account` Sven Schlüssel, DE89370400440532013000 |
