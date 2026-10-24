# Data Model: Anwesenheitserfassung (EZ)

Stand: 24.10.2026 · Normativ für Spalten, Typen, Checks und Regeln ist [spec.md](spec.md) Abschnitt 2 und 3. Diese Datei ordnet sie den Migrationen zu und nennt technische Ergänzungen. Entscheidungen: [research.md](research.md).

## Migrationen

| Nr | Datei | Spec-Task | Inhalt |
|---|---|---|---|
| 1 | `20261028000100_ez_tables.sql` | T1, T2 (Teil) | Typen `ez_event_kind`, `ez_span`, `ez_day_category`, `ez_role`, `ez_attendance_status`; `ez_can_read`, `ez_can_write`, `ez_can_delete`; Tabellen `ez_events` (Check `ez_events_shape`), `ez_event_groups`, `ez_attendances`, `ez_trial_participants` mit Indizes; RLS, Select-Policies, `grant select` |
| 2 | `20261028000200_ez_visibility.sql` | T2 | `ez_person_visible` (Ersatz des Platzhalters, gleiche Signatur) |
| 3 | `20261028000300_ez_triggers.sql` | T3 | `ez_events_before_insert`, `ez_events_before_update`, `ez_attendances_set_audit` (Probetrainings nur per Default, sie werden ersetzt statt geändert); interne Hilfe `ez_my_person_id()` |
| 4 | `20261028000400_ez_save_event.sql` | T4 | interne Hilfe `ez_roster`; `ez_save_event` |
| 5 | `20261028000500_ez_event_functions.sql` | T5 | Tabelle `ez_privacy_confirmations` (RLS, Select-Policy); interne Hilfen `ez_load_event`, `ez_check_helper_event`; `ez_delete_event`, `ez_cancel_event`, `ez_restore_event`, `ez_create_helper`, `ez_reactivate_helper` |
| 6 | `20261028000600_ez_read_functions.sql` | T6 | View `ez_v_events`; interne Hilfe `ez_group_label`; `ez_list_events`, `ez_get_event`, `ez_climbing_points_report` |
| 7 | `2026…_ez_module_available.sql` | T17 | `update ad_modules set is_available = true where code = 'EZ'` – erst nach Abnahme und Freigabe |
| 8 | `2026…_ez_planned_events.sql` | T19 (zurückgestellt) | `ez_upsert_planned_event`, `ez_cancel_planned_event`, `ez_planned_event_state` – mit TK T13 |

Jede Migration: `revoke all … from public, anon, authenticated` und danach ausdrückliche Grants nur an `authenticated`.

## Tabellen (spec.md 2)

| Tabelle | PK | Wichtigste Regeln | Select-Policy (spec.md 3) | Grant |
|---|---|---|---|---|
| `ez_events` | `id` uuid | Check `ez_events_shape` (Tabelle spec.md 2); `title` 1–90 getrimmt; `remark` ≤ 500; `cancel_reason` 1–500 genau dann, wenn `cancelled_at` gesetzt; `end_date > start_date`; `tk_plan_id` nur bei `course`/`tour`; FK `referat_id`, `group_id`, `organizer_person_id`, `location_id` on delete restrict; unique `client_request_id`, unique `tk_plan_id` (wenn gesetzt) | `ez_can_read(referat_id)` | select |
| `ez_event_groups` | (`event_id`, `group_id`) | FK `event_id` cascade, `group_id` restrict; Prüfungen (nur `competition`, ≠ erste Gruppe, gleiches Referat) in `ez_save_event` | Einsatz lesbar (`exists` auf `ez_events`) | select |
| `ez_attendances` | `id` uuid | unique (`event_id`, `person_id`); FK `person_id` restrict; Check `status <> 'registered'` bzw. `role <> 'participant'` je Einsatzart in `ez_save_event` (Einsatzart steht in `ez_events`) | Einsatz lesbar | select |
| `ez_trial_participants` | `id` uuid | `first_name` getrimmt 1–30 (Check) | Einsatz lesbar | select |
| `ez_privacy_confirmations` | `id` uuid | `notice_version` 1–50; FK `person_id` cascade, `event_id` set null | `ez_can_delete()` | select |

Keine Insert-, Update- oder Delete-Policy und kein solcher Grant.

### Check `ez_events_shape`

Als ein Check je Einsatzart (`case kind when …`), Bedingungen nach der Tabelle in spec.md 2. Zusätzlich:
- `span = 'single'` ⇒ `end_date`, `start_time`, `end_time` null; außer Training `day_category` not null.
- `span = 'multi'` ⇒ `end_date > start_date`, `day_category` null.
- `kind = 'training'` ⇒ `span = 'single'`, `location_id` not null, `start_time`/`end_time` null.

### Indizes

Aus spec.md 2: `(start_date desc)`, `(referat_id, start_date desc)`, `(group_id, start_date desc)`, `(location_id, start_date) where kind = 'training'`, unique `(client_request_id)`, unique `(tk_plan_id) where tk_plan_id is not null`; `ez_attendances (person_id)`.
Technisch ergänzt (plan.md H6): `ez_events (organizer_person_id) where organizer_person_id is not null`, `ez_events (created_by_person_id)`, `ez_events (updated_by_person_id) where updated_by_person_id is not null`, `ez_event_groups (group_id)`, `ez_trial_participants (event_id)`, `ez_privacy_confirmations (person_id)`.

## Zustände (spec.md 4)

- Einsatz: „erfasst“ (`cancelled_at is null`) ↔ „abgesagt“ (`cancelled_at` gesetzt). Löschen nur `ez_delete_event`.
- Anwesenheit: `registered` | `present` | `absent`; `registered` nur bei `work_assignment`, `course`, `tour`.
- „aus der Planungshilfe“ = `tk_plan_id is not null`; Personen aus der Planung = `from_plan = true`.

## Funktionen: Rechte und Grants

| Funktion | Art | Grant |
|---|---|---|
| `ez_can_read(uuid)`, `ez_can_write(uuid)`, `ez_can_delete()` | security definer, stable | authenticated |
| `ez_person_visible(uuid)` | security definer, stable | authenticated (bleibt aus AD) |
| `ez_my_person_id()`, `ez_roster(…)`, `ez_load_event(…)`, `ez_check_helper_event(…)`, `ez_group_label(…)`, Triggerfunktionen | security definer | keiner |
| `ez_save_event`, `ez_delete_event`, `ez_cancel_event`, `ez_restore_event`, `ez_create_helper`, `ez_reactivate_helper` | security definer, Rechteprüfung zuerst | authenticated |
| `ez_list_events`, `ez_get_event`, `ez_climbing_points_report` | security definer, stable, Filter `ez_can_read` | authenticated |
| View `ez_v_events` | security_invoker | select an authenticated |

Signaturen, Parameter und Rückgaben: [contracts/database-api.md](contracts/database-api.md).

## Objekte anderer Module

| Objekt | Nutzung durch EZ | Änderung |
|---|---|---|
| `ez_person_visible(uuid)` (AD) | Ersatz | `create or replace`, gleiche Signatur |
| `ad_has_level`, `ad_my_referate`, `ad_has_any_level`, `ad_accesses` | Rechte, Audit-Person | keine |
| `ad_locations` | FK, aktiv-Prüfung (R12), Punktekonto (US-EZ-16) | keine |
| `ea_persons`, `ea_referate` | FK; `volunteer_status` für R11, R20, R31 | keine |
| `ea_create_volunteer`, `ea_activate_person`, `ea_property_types` (`system_key = 'function'`) | neue bzw. wieder aktive Helfer:innen | keine |
| `gr_groups` | FK `group_id`; Name in Lesefunktionen | keine |
| `gr_groups_for_attendance`, `gr_group_roster` | wählbare Gruppen, Stichtag, Funktionen | keine |
