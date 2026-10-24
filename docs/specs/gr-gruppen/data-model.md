# Data Model: Gruppen (GR)

Stand: 24.10.2026 · Normativ für Spalten, Typen, Checks und Regeln ist [spec.md](spec.md) Abschnitt 2 und 3. Diese Datei ordnet sie den Migrationen zu und nennt, was sich an Objekten der Administration ändert. Entscheidungen: [research.md](research.md).

## Migrationen

| Nr | Datei | Spec-Task | Inhalt |
|---|---|---|---|
| 1 | `20261025000100_gr_groups.sql` | T1 | `gr_today`; `gr_groups`, `gr_training_times` mit Checks, Indizes, Trigger `gr_training_times_guard` (Sperre Kernfelder) und Audit-Trigger; RLS und Policies; `ea_properties.related_group_id`, `ea_property_history.related_group_id`; neue Fassungen `ea_properties_validate`, `ea_properties_history`, `ea_property_writable` (R38, R39, Ü7); System-Eigenschaftsart `group_function` (ohne Nutzerkontext, `on conflict (system_key) do nothing`) |
| 2 | `20261025000200_gr_relations.sql` | T2 | `gr_pending_admissions`, `gr_memberships`, `gr_contracts`, `gr_guardians` (Trigger höchstens zwei, R3), `gr_emergency_contacts`, `gr_photo_consents`, `gr_health_consents`, `gr_health_notes`, `gr_health_note_history` (Trigger `gr_health_notes_history`); Hilfsfunktionen `gr_has_current_relation`, `gr_person_visible` (Ersatz), `gr_person_ids` (Ersatz, mengenbasiert), `gr_row_visible`, `gr_is_adult`, `gr_can_read_health`, `gr_contract_status`, `gr_needs_guardian`; Ü3: `gr_person_has_group_relation`, neue Fassung `ad_v_person_overview`; RLS und Policies |
| 3 | `20261025000300_gr_group_functions.sql` | T3 | `gr_save_group`, `gr_dissolve_group`, `gr_add_training_time`, `gr_change_training_time`, `gr_end_training_time` |
| 4 | `20261025000400_gr_person_functions.sql` | T4 | interne Hilfen `gr_create_person` (aus `p_new_person`), `gr_take_person` (Übernahmeregel); `gr_start_admission`, `gr_cancel_admission`, `gr_update_person`, `gr_copy_address`, `gr_add_guardian`, `gr_remove_guardian`, `gr_add_emergency_contact`, `gr_remove_emergency_contact`, `gr_reorder_emergency_contacts` |
| 5 | `20261025000500_gr_membership_contract.sql` | T5 | interne Hilfe `gr_check_contract` (R4–R6, R27); `gr_admit`, `gr_add_contract`, `gr_update_contract`, `gr_cancel_contract`, `gr_end_membership` |
| 6 | `20261025000600_gr_consents_health.sql` | T6 | `gr_set_photo_consent`, `gr_set_health_consent`, `gr_save_health_note` |
| 7 | `20261025000700_gr_volunteer_functions.sql` | T7 | Ü1 `ea_set_status_from_group`; `gr_add_group_function`, `gr_end_group_function` |
| 8 | `20261025000800_gr_read_functions.sql` | T8 | Views `gr_v_memberships`, `gr_v_pending_admissions`; `gr_group_overview`, `gr_guardian_emails`, `gr_group_roster`, `gr_groups_for_attendance`, `gr_my_groups` |
| 9 | `20261025000900_gr_import.sql` | T18 | `gr_import_groups` (nur `service_role`) |
| 10 | `2026…_gr_module_available.sql` | T19 | `update ad_modules set is_available = true where code = 'GR'` nach Abnahme |

Jede Migration: `revoke all … from public, anon, authenticated` und danach ausdrückliche Grants nur an `authenticated` (Ausnahmen unten).

## Tabellen (spec.md 2.1)

| Tabelle | PK | Wichtigste Regeln | Select-Policy (spec.md 3) | Grant |
|---|---|---|---|---|
| `gr_groups` | `id` uuid | unique `lower(name)` where `dissolved_on is null` (R1); FK `referat_id` restrict | `ad_has_level('GR','read') or ad_has_any_level('EA','read')` | select |
| `gr_training_times` | `id` uuid | `weekday` 1–7; `ends_at > starts_at`; `valid_to >= valid_from`; Kernfelder gesperrt (Trigger) | `ad_has_level('GR','read')` | select |
| `gr_pending_admissions` | `person_id` | eine je Person | `ad_has_level('GR','read')` | select |
| `gr_memberships` | `id` uuid | `left_on >= joined_on`; keine Überschneidung je Person und Gruppe (R10, in `gr_admit`) | `gr_row_visible(person_id)` | select |
| `gr_contracts` | `id` uuid | `ends_on >= starts_on`; `ends_on` ⇒ `cancelled_on`; `monthly_amount > 0`; unique `lower(mandate_reference)`; Längen und Zeichensatz SEPA (Checks) | `gr_row_visible(<Teilnehmer:in der Teilnahme>)` | select |
| `gr_guardians` | `id` uuid | unique (Kind, Person); Kind ≠ Person; höchstens zwei (Trigger) | `gr_row_visible(child_person_id)` | select |
| `gr_emergency_contacts` | `id` uuid | unique (Kind, Person); Kind ≠ Person | `gr_row_visible(child_person_id)` | select |
| `gr_photo_consents` | `id` bigint identity | `effective_on <= gr_today()` (Funktion) | `gr_row_visible(person_id)` | select |
| `gr_health_consents` | `id` bigint identity | wie oben | `gr_person_visible(person_id,'edit')` | select |
| `gr_health_notes` | `person_id` | `note` 1–2000 Zeichen | `gr_can_read_health(person_id)` | select |
| `gr_health_note_history` | `id` bigint identity | nur durch Trigger | `gr_can_read_health(person_id)` | select |

Keine Insert-, Update- oder Delete-Policy und kein solcher Grant (research.md R-GR-08). Audit-Spalten: `created_at`/`created_by` per Default; `updated_at`/`updated_by` per Trigger `ad_set_updated` (vorhanden).

Hinweis zu `gr_contracts`: Die Policy braucht die Person der Teilnahme. Umsetzung als `exists (select 1 from gr_memberships m where m.id = membership_id)`; die Policy auf `gr_memberships` greift dabei mit.

## Zustände (spec.md 4)

- Gruppe: aktiv → aufgelöst (`dissolved_on` gesetzt, nicht zurücksetzbar).
- Aufnahme offen → Teilnahme (`gr_admit`) oder abgebrochen (Zeile gelöscht).
- Teilnahme: aktiv am Datum D, wenn `joined_on <= D and (left_on is null or left_on >= D)`; „laufend“ für Sichtbarkeit: `left_on is null or left_on >= gr_today()`.
- Vertrag: `gr_contract_status(ends_on, D)` → `active` | `cancelled` | `ended`.
- „Teilnahme klären“ (R17): laufende Teilnahme ohne Vertrag mit Status `active` oder `cancelled`.
- Fotoerlaubnis und Einwilligung: aktueller Stand = Zeile mit größtem (`effective_on`, `created_at`); keine Zeile = nein.

## Änderungen an Objekten der Administration

| Objekt | Änderung | Migration | Quelle |
|---|---|---|---|
| `ea_properties` | Spalte `related_group_id` FK `gr_groups(id)` on delete restrict, Teilindex | 1 | spec.md 2.2 |
| `ea_property_history` | Spalte `related_group_id` | 1 | spec.md 2.2 |
| `ea_properties_validate()` | neuer Zweig `group`; `related_group_id := null` in den übrigen Zweigen; `GR_GROUP_DISSOLVED` | 1 | R38 |
| `ea_properties_history()` | `related_group_id` vergleichen und schreiben | 1 | R38 |
| `ea_property_writable(uuid, uuid, uuid)` | `group` → immer false | 1 | R39, Ü7 |
| `ea_property_types` (Daten) | System-Eigenschaftsart `group_function` mit Feld `function` (choice: Gruppenleitung, Trainer:in, Helfer:in, Pflicht) | 1 | spec.md 2.2 |
| `gr_person_visible(uuid, ad_level)` | echte Regel statt `false` | 2 | spec.md 2.3, Ü4 |
| `gr_person_ids(ad_level)` | mengenbasiert | 2 | research.md R-GR-06 |
| `ad_v_person_overview` | `has_group_relation` über `gr_person_has_group_relation` statt `created_in = 'GR'` | 2 | Ü3 |
| `ea_set_status_from_group(uuid, date)` | neu, ohne Grant | 7 | Ü1 |

## Funktionen: Rechte und Grants

| Funktion | Art | Grant |
|---|---|---|
| `gr_today` | stable | authenticated |
| `gr_has_current_relation`, `gr_is_adult`, `ea_set_status_from_group`, interne Hilfen (`gr_create_person`, `gr_take_person`, `gr_check_contract`) | security definer | keiner |
| `gr_person_visible`, `gr_person_ids`, `gr_row_visible`, `gr_can_read_health`, `gr_contract_status`, `gr_needs_guardian`, `gr_person_has_group_relation` | security definer bzw. immutable | authenticated (Policies und Views laufen als Aufrufer) |
| Schreibfunktionen aus spec.md 2.3 | security definer, Rechteprüfung zuerst | authenticated |
| `gr_group_overview` | security invoker | authenticated |
| `gr_guardian_emails`, `gr_group_roster`, `gr_groups_for_attendance`, `gr_my_groups` | security definer, eigene Rechteprüfung | authenticated |
| `gr_import_groups` | security definer | nur `service_role` |

Signaturen, Parameter und Rückgaben: [contracts/database-api.md](contracts/database-api.md).

## Personenangaben (spec.md 2.2)

| Angabe | `system_key` | Feld | Regel |
|---|---|---|---|
| Geburtsdatum | `birth_date` | `date` | eine Eigenschaft, `valid_from` = Geburtsdatum; schreiben nur mit GR verwalten (`GR_BIRTH_DATE_FORBIDDEN`) |
| Adresse, Telefon mobil/Festnetz, E-Mail | `contact` | `street`, `postal_code`, `city`, `phone_mobile`, `phone_landline`, `email` | eine Eigenschaft je Person, `valid_from` = Anlagedatum; Änderung als Update (Historie über Trigger) |
| Mitgliedsnummer | `member` | `is_member` = true, `member_number` | nur mit Nummer; Leeren beendet die Eigenschaft zum Vortag (R25) |
| Funktion in Gruppe | `group_function` | `function` | Bezug `related_group_id`; Lesefunktionen bilden auf `group_lead`, `trainer`, `helper` ab |
