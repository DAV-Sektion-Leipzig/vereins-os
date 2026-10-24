# Contract: Datenbank-API Gruppen

Stand: 24.10.2026 · Normativ für Verhalten und Regeln: [spec.md](../spec.md) 2.3 und 5. Hier stehen Signaturen, Rechte, Rückgaben und Fehlercodes in Kurzform, wie Frontend, Skript und andere Module sie aufrufen. Codes: [error-codes.md](error-codes.md).

Konventionen: Aufruf per `supabase.rpc('<name>', {…})`; Datum als `YYYY-MM-DD`, Uhrzeit als `HH:MM`; leere Strings in jsonb gelten als `null`. „edit“ = `ad_has_level('GR','edit')`, „manage“ = `ad_has_level('GR','manage')`, „read“ = `ad_has_level('GR','read')`.

## Hilfsfunktionen (für Policies, Views und Frontend)

| Funktion | Rückgabe | Grant | Hinweis |
|---|---|---|---|
| `gr_today()` | date | authenticated | heute in Europe/Berlin |
| `gr_person_visible(p_person uuid, p_min ad_level default 'read')` | boolean | authenticated | Ersatz des Platzhalters; Pfad GR (Ü4) |
| `gr_row_visible(p_person uuid)` | boolean | authenticated | read und (Pfad GR oder AD ≥ read) |
| `gr_can_read_health(p_person uuid)` | boolean | authenticated | Pfad GR mit edit und Einwilligung „ja“ |
| `gr_contract_status(p_ends_on date, p_date date)` | text `active`/`cancelled`/`ended` | authenticated | immutable |
| `gr_needs_guardian(p_person uuid)` | boolean, null ohne Sichtbarkeit | authenticated | R2-Hinweis ohne Alter (research.md R-GR-09) |
| `gr_person_has_group_relation(p_person uuid)` | boolean, null ohne AD ≥ read | authenticated | nur für `ad_v_person_overview` (Ü3) |
| `gr_user_name(p_user uuid)` | text, null ohne GR lesen | authenticated | „angelegt von“ in `gr_v_pending_admissions` |
| `gr_weekday_label(p_weekday smallint)` | text `Mo`…`So` | authenticated | immutable |
| `gr_has_current_relation(p_person uuid)` | boolean | – | intern |
| `gr_is_adult(p_person uuid, p_date date)` | boolean | – | intern |
| `ea_set_status_from_group(p_person uuid, p_valid_from date)` | boolean (gesetzt) | – | intern (Ü1) |

## Gruppen und Trainingszeiten (edit)

| Funktion | Rückgabe | Fehler |
|---|---|---|
| `gr_save_group(p_id uuid, p_name text, p_referat_id uuid)` | uuid | `GR_FORBIDDEN`, `GR_GROUP_FIELDS_REQUIRED`, `GR_GROUP_NAME_TAKEN`, `GR_REFERAT_INACTIVE`, `GR_GROUP_DISSOLVED`, `GR_GROUP_NOT_FOUND` |
| `gr_dissolve_group(p_id uuid, p_dissolved_on date)` | jsonb `{"starts_after_dissolution": [{"kind": "function"\|"training_time", "id"}]}` | `GR_FORBIDDEN`, `GR_GROUP_HAS_MEMBERS`, `GR_GROUP_HAS_PENDING`, `GR_DATE_IN_FUTURE`, `GR_GROUP_DISSOLVED` |
| `gr_add_training_time(p_group uuid, p_weekday smallint, p_starts time, p_ends time, p_valid_from date, p_valid_to date default null)` | jsonb `{"id"}` (v0.3 ohne `overlap`) | `GR_FORBIDDEN`, `GR_TRAINING_TIME_REQUIRED`, `GR_TRAINING_TIME_END`, `GR_VALID_TO_BEFORE_FROM`, `GR_GROUP_DISSOLVED` |
| `gr_change_training_time(p_id uuid, p_from date, p_weekday smallint, p_starts time, p_ends time)` | jsonb `{"id"}` | wie oben, `GR_CHANGE_DATE_INVALID` |
| `gr_end_training_time(p_id uuid, p_valid_to date)` | void | `GR_FORBIDDEN`, `GR_VALID_TO_BEFORE_FROM`, `GR_TRAINING_TIME_WEEKDAY_EXISTS`, `GR_GROUP_DISSOLVED` |

Hinweis `gr_dissolve_group`: spec.md 2.3 nennt Rückgabe `void` und zugleich die Rückgabe „beginnt nach Auflösung“ im Bericht. Umgesetzt als jsonb mit leerer Liste im Normalfall; die Oberfläche zeigt die Liste nur, wenn sie nicht leer ist [ANNAHME Umsetzung, kommt laut Spec praktisch nicht vor].

## Personen und Aufnahme (edit; neue Teilnehmer:in: manage)

`p_new_person jsonb`: `first_name`, `last_name`, `preferred_name`, `birth_date`, `street`, `postal_code`, `city`, `phone_mobile`, `phone_landline`, `email`, `member_number`.

| Funktion | Rückgabe | Fehler |
|---|---|---|
| `gr_start_admission(p_group uuid, p_person_id uuid default null, p_new_person jsonb default null)` | uuid (Person) | `GR_FORBIDDEN`, `GR_PERSON_INVALID`, `GR_PARTICIPANT_FIELDS_REQUIRED`, `GR_BIRTH_DATE_FORBIDDEN`, `GR_PENDING_EXISTS`, `GR_ALREADY_MEMBER`, `GR_GROUP_DISSOLVED`, `AD_NAME_REQUIRED` |
| `gr_cancel_admission(p_person uuid)` | void | `GR_FORBIDDEN` |
| `gr_update_person(p_person uuid, p_data jsonb)` | void | `GR_FORBIDDEN`, `GR_BIRTH_DATE_FORBIDDEN`, `GR_PARTICIPANT_FIELDS_REQUIRED`, `GR_GUARDIAN_FIELDS_REQUIRED`, `GR_CONTACT_REACHABILITY`, `AD_NAME_REQUIRED` |
| `gr_copy_address(p_child uuid, p_from_guardian uuid)` | void | `GR_FORBIDDEN`, `GR_PERSON_INVALID` |
| `gr_add_guardian(p_child uuid, p_person_id uuid default null, p_new_person jsonb default null)` | uuid (Person) | `GR_FORBIDDEN`, `GR_PERSON_INVALID`, `GR_GUARDIAN_FIELDS_REQUIRED`, `GR_GUARDIAN_LIMIT`, `GR_GUARDIAN_EXISTS` |
| `gr_remove_guardian(p_child uuid, p_guardian uuid)` | void | `GR_FORBIDDEN`, `GR_GUARDIAN_IS_HOLDER` |
| `gr_add_emergency_contact(p_child uuid, p_person_id uuid default null, p_new_person jsonb default null)` | uuid (Person) | `GR_FORBIDDEN`, `GR_PERSON_INVALID`, `GR_CONTACT_REACHABILITY`, `GR_EMERGENCY_EXISTS` |
| `gr_remove_emergency_contact(p_child uuid, p_contact uuid)` | void | `GR_FORBIDDEN` |
| `gr_reorder_emergency_contacts(p_child uuid, p_contact_ids uuid[])` | void | `GR_FORBIDDEN`, `GR_ORDER_INVALID` |

## Teilnahme und Vertrag (edit)

`p_contract jsonb`: `holder_person_id`, `starts_on`, `account_holder`, `iban`, `mandate_reference`, `mandate_signed_on`, `purpose`, `monthly_amount` (alle Pflicht).

| Funktion | Rückgabe | Fehler |
|---|---|---|
| `gr_admit(p_person uuid, p_group uuid, p_joined_on date, p_contract jsonb)` | uuid (Teilnahme) | `GR_FORBIDDEN`, `GR_CONTRACT_REQUIRED`, `GR_ALREADY_MEMBER`, `GR_GROUP_DISSOLVED`, Vertragscodes |
| `gr_add_contract(p_membership uuid, p_contract jsonb)` | uuid (Vertrag) | `GR_FORBIDDEN`, `GR_CONTRACT_EXISTS`, Vertragscodes |
| `gr_update_contract(p_contract uuid, p_data jsonb)` | void | `GR_FORBIDDEN`, Vertragscodes |
| `gr_cancel_contract(p_contract uuid, p_cancelled_on date, p_ends_on date, p_end_membership boolean)` | void | `GR_FORBIDDEN`, `GR_CONTRACT_END_BEFORE_START`, `GR_LEFT_BEFORE_JOINED` |
| `gr_end_membership(p_membership uuid, p_left_on date)` | void | `GR_FORBIDDEN`, `GR_LEFT_BEFORE_JOINED` |

Vertragscodes: `GR_CONTRACT_FIELDS_REQUIRED`, `GR_HOLDER_INVALID`, `GR_IBAN_INVALID`, `GR_MANDATE_TAKEN`, `GR_MANDATE_FORMAT`, `GR_TEXT_TOO_LONG`, `GR_AMOUNT_INVALID`, `GR_DATE_IN_FUTURE`.

## Fotoerlaubnis, Einwilligung, Gesundheit

| Funktion | Recht | Rückgabe | Fehler |
|---|---|---|---|
| `gr_set_photo_consent(p_person uuid, p_granted boolean, p_effective_on date)` | Pfad GR edit | void | `GR_FORBIDDEN`, `GR_CONSENT_DATE_REQUIRED`, `GR_DATE_IN_FUTURE`, `GR_CONSENT_UNCHANGED` |
| `gr_set_health_consent(p_person uuid, p_granted boolean, p_effective_on date)` | Pfad GR edit | void | wie oben |
| `gr_save_health_note(p_person uuid, p_note text)` | `gr_can_read_health` | void | `GR_FORBIDDEN`, `GR_HEALTH_CONSENT_REQUIRED`, `GR_HEALTH_NOTE_INVALID` |

## Funktionen in Gruppen (edit)

| Funktion | Rückgabe | Fehler |
|---|---|---|
| `gr_add_group_function(p_group uuid, p_function text, p_valid_from date, p_valid_to date default null, p_person_id uuid default null, p_new_person jsonb default null)` | jsonb `{"property_id", "status_hint": null\|"dormant"\|"left", "status_set": bool}` | `GR_FORBIDDEN`, `GR_PERSON_INVALID`, `GR_GROUP_DISSOLVED`, `GR_FUNCTION_OVERLAP`, `EA_VALID_RANGE`, `AD_NAME_REQUIRED` |
| `gr_end_group_function(p_property uuid, p_valid_to date)` | void | `GR_FORBIDDEN`, `GR_FUNCTION_OVERLAP`, `EA_VALID_RANGE` |

`p_function` ∈ `Gruppenleitung`, `Trainer:in`, `Helfer:in` (Auswahlwerte der Eigenschaftsart `group_function`).

## Lesen: Views und Funktionen

| Objekt | Art | Recht | Inhalt |
|---|---|---|---|
| `gr_v_memberships` | View, security invoker | RLS | `membership_id`, `group_id`, `person_id`, `first_name`, `preferred_name`, `last_name`, `joined_on`, `left_on`, `birth_date` (null ohne Lesestufe), `contract_id`, `contract_status`, `contract_ends_on`, `photo_consent`, `needs_clarification`, `clarify_since` (größtes Vertragsende), `has_emergency_contact`, `needs_guardian` |
| `gr_v_pending_admissions` | View, security invoker | RLS | `person_id`, Name, `group_id`, `group_name`, `created_at`, `created_by_name`, `needs_guardian` |
| `gr_group_overview(p_include_dissolved boolean default false)` | security invoker | RLS | `id`, `name`, `referat_id`, `referat_name`, `dissolved_on`, `training_times_today`, `active_count`, `clarify_count`, `no_emergency_count`, `pending_count` |
| `gr_guardian_emails(p_group uuid)` | security definer | read, sonst `GR_FORBIDDEN` | setof text, sortiert, ohne Dubletten (R13) |
| `gr_group_roster(p_group_id uuid, p_date date)` | security definer | read oder EZ read oder EZ-Referat der Gruppe; sonst `GR_ROSTER_FORBIDDEN`; danach `GR_GROUP_NOT_FOUND` | jsonb `{"group": {"id","name","referat_id","referat_name"}, "training_times": [{"starts_at","ends_at"}], "persons": [{"person_id","first_name","preferred_name","last_name","role"}]}` |
| `gr_groups_for_attendance(p_date date)` | security definer | read oder EZ read: alle; EZ-Referat: eigene; sonst leer | `group_id`, `group_name`, `referat_id`, `referat_name` |
| `gr_my_groups(p_date date)` | security definer | eigene Person aus `ad_me()`, Zugang aktiv | `group_id`, `group_name`, `referat_id`, `referat_name`, `function`, `weekdays smallint[]` |

`role`/`function` ∈ `group_lead`, `trainer`, `helper`, `participant`. Die drei Funktionen für die Anwesenheitserfassung liefern nie Geburtsdatum, Alter, Kontaktdaten, Erziehungsberechtigte, Notfallkontakte, Verträge, Bankdaten, Gesundheitsangaben oder Fotoerlaubnis (R20). Die EZ-Pfade greifen erst mit Ü5 (plan.md O2).

## Direkt lesbare Tabellen

Alle `gr_`-Tabellen sind nach den Policies aus [data-model.md](../data-model.md) per `select` lesbar, z. B. Trainingszeiten und Historien. Personenangaben (Geburtsdatum, Kontaktdaten, Mitgliedsnummer, Funktionen) liest das Frontend aus `ea_properties` über die RLS der Administration.

## Import (nur `service_role`)

`gr_import_groups(p_rows jsonb, p_import_date date, p_dry_run boolean) returns jsonb` → `{"errors": [{"sheet","row","message"}], "warnings": […], "counts": {…}, "written": bool}`. Aufbau von `p_rows`: [import-script.md](import-script.md).
