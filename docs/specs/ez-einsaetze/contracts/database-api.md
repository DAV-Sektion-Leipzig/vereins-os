# Contract: Datenbank-API Anwesenheitserfassung

Stand: 24.10.2026 · Normativ für Verhalten und Regeln: [spec.md](../spec.md) 2 und 5. Hier stehen Signaturen, Rechte, Rückgaben und Fehlercodes in Kurzform, wie das Frontend sie aufruft. Codes: [error-codes.md](error-codes.md).

Konventionen: Aufruf per `supabase.rpc('<name>', {…})`; Datum `YYYY-MM-DD`, Uhrzeit `HH:MM`; leere Strings gelten als `null`. Fehler als `P0001` mit Code in `message` und Zusatz in `details` (research.md R-EZ-04).

## Rechte

| Funktion | Rückgabe | Regel |
|---|---|---|
| `ez_can_read(p_referat uuid)` | boolean | `ad_has_level('EZ','read') or p_referat = any(ad_my_referate('EZ','read'))` |
| `ez_can_write(p_referat uuid)` | boolean | wie oben mit `edit` |
| `ez_can_delete()` | boolean | `ad_has_level('EZ','manage')` |
| `ez_person_visible(p_person uuid)` | boolean | Person in einem lesbaren Einsatz (Anwesenheit, organisierende Person, erfasst/geändert von) |

## Schreiben

### `ez_save_event(p_event jsonb, p_attendances jsonb, p_trials jsonb, p_confirm_duplicate boolean default false) returns uuid`

`p_event`:

| Schlüssel | Typ | Hinweis |
|---|---|---|
| `id` | uuid | fehlt beim Anlegen |
| `client_request_id` | uuid | Pflicht beim Anlegen |
| `kind` | `ez_event_kind` | Pflicht |
| `span` | `single`/`multi` | bei Training, Tagesausflug, Mehrtagesfahrt, Trainingslager von der Funktion gesetzt |
| `referat_id` | uuid | nur bei Arbeitseinsatz, Kurs, Tour; sonst aus der Gruppe |
| `group_id` | uuid | Pflicht außer bei Arbeitseinsatz, Kurs, Tour |
| `additional_group_ids` | uuid[] | nur Wettkampfbetreuung, nur beim Anlegen (R30) |
| `title`, `organizer_person_id`, `start_date`, `start_time`, `end_date`, `end_time`, `day_category`, `location_id`, `remark` | | nach Check `ez_events_shape` |

`p_attendances`: `[{"person_id", "role": "trainer"|"helper"|"participant", "status": "registered"|"present"|"absent"}]` (Status ohne Angabe: `present`). Ersetzt die gespeicherten vollständig.
`p_trials`: `["Vorname", …]`, nur beim Training; ersetzt die gespeicherten.

Rückgabe: `id` des Einsatzes (bei gleicher `client_request_id` die vorhandene).

Fehler (Reihenfolge der Prüfung): `EZ_NOT_FOUND` (Ändern, nicht lesbar), `EZ_FORBIDDEN`, `EZ_KIND_NOT_ALLOWED` (weitere Gruppen außerhalb der Wettkampfbetreuung), `EZ_GROUP_REFERAT_MISMATCH`, `EZ_FIELD_LOCKED`, `EZ_EVENT_CANCELLED`, `EZ_TK_MANAGED`, `EZ_FIELD_REQUIRED` (`details` = Feld), `EZ_TITLE_LENGTH`, `EZ_END_DATE`, `EZ_REMARK_LENGTH`, `EZ_LOCATION_INACTIVE`, `EZ_ORGANIZER_NOT_ACTIVE`, `EZ_DUPLICATE_PERSON`, `EZ_ROLE_NOT_ALLOWED`, `EZ_STATUS_NOT_ALLOWED`, `EZ_PARTICIPANT_NOT_IN_GROUP`, `EZ_PERSON_NOT_ACTIVE` (`details` = person_id), `EZ_MIN_ATTENDANCE`, `EZ_TRIAL_NAME`, `EZ_DUPLICATE_EVENT` (`details` = `existing_id` oder leer).

### Weitere

| Funktion | Rückgabe | Rechte | Fehler |
|---|---|---|---|
| `ez_delete_event(p_id uuid)` | void | `ez_can_delete()` | `EZ_NOT_FOUND`, `EZ_DELETE_FORBIDDEN`, `EZ_TK_MANAGED` |
| `ez_cancel_event(p_id uuid, p_reason text)` | void | `ez_can_write(referat_id)` | `EZ_NOT_FOUND`, `EZ_FORBIDDEN`, `EZ_TK_MANAGED`, `EZ_EVENT_CANCELLED`, `EZ_CANCEL_REASON`, `EZ_CANCEL_NOT_ALLOWED` |
| `ez_restore_event(p_id uuid)` | void | `ez_can_write(referat_id)` | `EZ_NOT_FOUND`, `EZ_FORBIDDEN`, `EZ_TK_MANAGED`; nicht abgesagt → ohne Wirkung |
| `ez_create_helper(p_event uuid, p_first text, p_last text, p_preferred text default null, p_email text default null, p_privacy_confirmed boolean default false, p_notice_version text default null)` | uuid (person_id) | `ez_can_write(referat_id)` | `EZ_NOT_FOUND`, `EZ_KIND_NOT_ALLOWED`, `EZ_FORBIDDEN`, `EZ_EVENT_CANCELLED`, `EZ_PRIVACY_NOT_CONFIRMED`; Fehler aus `ea_create_volunteer` unverändert |
| `ez_reactivate_helper(p_event uuid, p_person uuid)` | void | `ez_can_write(referat_id)` | `EZ_NOT_FOUND`, `EZ_KIND_NOT_ALLOWED`, `EZ_FORBIDDEN`, `EZ_EVENT_CANCELLED`, `EZ_PERSON_NOT_INACTIVE`, `EZ_DUPLICATE_PERSON`; Fehler aus `ea_activate_person` unverändert |

## Lesen

### `ez_list_events(p_from date, p_to date, p_referat uuid default null, p_group uuid default null, p_kind ez_event_kind default null, p_limit int default 50, p_offset int default 0)`

Rückgabe je Zeile: alle Spalten von `ez_v_events` (darunter `is_cancelled`, `present_trainer`, `present_helper`, `present_participant`, `registered_count`, `absent_count`, `trial_count`), dazu `group_name` („A + B“ bei mehreren Gruppen), `referat_name`, `total_count`. Filter auf `start_date` zwischen `p_from` und `p_to` (beide inklusive); `p_group` trifft erste und weitere Gruppen. Sortierung `start_date desc, start_time desc nulls last, created_at desc`.

### `ez_get_event(p_id uuid) returns jsonb`

```json
{
  "event": { "…alle Spalten von ez_events…", "is_cancelled": false, "from_planning": false },
  "groups": [{ "id": "…", "name": "Klettergruppe Test", "is_primary": true }],
  "referat_name": "Klettern",
  "location_name": "Kletterhalle Test",
  "can_write": true,
  "can_delete": false,
  "attendances": [{ "id": "…", "person_id": "…", "role": "trainer", "status": "present", "is_substitute": false, "from_plan": false }],
  "trials": [{ "id": "…", "first_name": "Lena" }]
}
```

Fehler: `EZ_NOT_FOUND` (nicht vorhanden oder nicht lesbar). Namen holt das Frontend über `ea_person_names` (Anwesenheiten, organisierende Person, `created_by_person_id`, `updated_by_person_id`, `cancelled_by_person_id`).

### `ez_climbing_points_report(p_location uuid, p_from date, p_to date)`

Rückgabe: `event_id uuid, start_date date, group_name text, participants_present int, trial_count int`, sortiert nach Datum. Fehler: `EZ_LOCATION_NO_POINTS`.

## Aus anderen Modulen (nur Aufruf)

| Funktion | Modul | Zweck |
|---|---|---|
| `gr_groups_for_attendance(p_date)` | GR | wählbare Gruppen (lesbar); beschreibbar filtert das Frontend über die eigenen EZ-Referate |
| `gr_group_roster(p_group_id, p_date)` | GR | Anwesenheitsliste, Trainingszeit am Wochentag |
| `gr_my_groups(p_date)` | GR | Vorschlag der eigenen Gruppe (R18) |
| `ea_person_names(p_ids)` | AD | Namen (≤ 500 IDs) |
| `ea_search_active_persons(p_query, p_limit)` | AD | Suche „Aktive“ |
| `ad_find_similar_persons(p_first, p_last, p_email)` | AD | Dublettenprüfung |
| `ad_locations` (Tabelle) | AD | Orte |
| `ea_referate` (Tabelle) | AD | Referate |

## Anbindung der Planungshilfe (TK)

Migrationen `20261106000100_ez_planned_event.sql`, Härtung `20261108000200_ez_planned_event_hardening.sql` (Befund S-02, Sicherheits-Review).

| Funktion | Rückgabe | Aufruf | Rechte und Prüfungen | Fehler |
|---|---|---|---|---|
| `ez_upsert_planned_event(p_tk_plan_id, p_kind, p_referat_id, p_title, p_span, p_start_date, p_start_time, p_end_date, p_end_time, p_day_category, p_organizer_person_id, p_persons jsonb, p_remuneration_kind_code text default null)` | uuid (Einsatz) | **nur intern** über `tk_ez_sync` (aus `tk_save_plan`, `tk_change_status` publish); kein `execute` für `authenticated` | `tk_can_write(p_referat_id)`; Planung vorhanden, `tk_plans.referat_id = p_referat_id`, Status `approved` (Übergang zu „in Yolawo angelegt“) oder `published` | `EZ_FORBIDDEN`, `EZ_KIND_NOT_ALLOWED`, `EZ_FIELD_REQUIRED`, `EZ_TITLE_LENGTH`, `EZ_END_DATE`, `EZ_EVENT_CANCELLED`, `EZ_EVENT_LOCKED`, `EZ_SETTLED`, `EZ_FIELD_LOCKED`, `EZ_REMUNERATION_INACTIVE`, `EZ_ORGANIZER_NOT_ACTIVE`, `EZ_ROLE_NOT_ALLOWED`, `EZ_DUPLICATE_PERSON`, `EZ_PERSON_NOT_ACTIVE` |
| `ez_cancel_planned_event(p_tk_plan_id uuid, p_reason text)` | void | **nur intern** über `tk_change_status` cancel; kein `execute` für `authenticated` | `tk_can_write(referat_id)` des Einsatzes | `EZ_FORBIDDEN`, `EZ_EVENT_LOCKED`, `EZ_SETTLED`, `EZ_CANCEL_REASON` |
| `ez_planned_event_state(p_tk_plan_id uuid)` | jsonb oder null | Frontend der Planungshilfe (`authenticated`) | `tk_can_read(referat_id)` | `EZ_NOT_FOUND` |

`ez_events.tk_plan_id` verweist per Fremdschlüssel `ez_events_tk_plan_id_fkey` auf `tk_plans(id)` (`on delete restrict`; `tk_delete_plan` löscht ohnehin nur Planungen ohne Einsatz). Gibt es beim Lauf der Migration verwaiste Werte, bleibt der Fremdschlüssel `not valid` (gilt für neue und geänderte Zeilen) und die Migration meldet die Anzahl per NOTICE.
