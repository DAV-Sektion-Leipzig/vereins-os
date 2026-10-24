# Contract: Datenbank-Schnittstelle AD (PostgREST)

Stand: 22.10.2026 · Umfang Kern bis v0.7.1 ([plan.md](../plan.md)). Das Frontend greift mit dem Publishable Key und dem JWT des Nutzers direkt zu; Schutz nur über RLS ([data-model.md](../data-model.md)). Spalten und Typen: [spec.md](../spec.md) Abschnitt 2.

## Lesen (Tabellen/Views)

| Objekt | genutzt von | Filter/Sortierung |
|---|---|---|
| `ad_modules` | Kopfzeile, Rechtevorlagen-Matrix, „sichtbar in“ | `order=sort_order` |
| `ad_v_person_overview` | /ad | Suche `or(first_name.ilike.*x*,preferred_name.ilike.*x*,last_name.ilike.*x*)`, Filter Zugangsstatus und Zugehörigkeit, `order=last_name,first_name`, `range` 50 je Seite mit `count=exact` |
| `ea_persons`, `ad_accesses` | /ad/personen/:id | `id=eq.…` bzw. `person_id=eq.…` |
| `ad_template_assignments` (+ `ad_templates`, `ad_assignment_referate`, `ea_referate`) | /ad/personen/:id | wirksame Zuweisungen (`revoked_at=is.null`) mit Referaten |
| `ea_properties` (+ `ea_property_types`, `ea_property_fields`, `ea_property_history`, `ea_referate`, `ea_gremien`) | /ad/personen/:id | Art mit `visible_in` ∋ `AD`; gruppiert nach Kategorie; aktuelle zuerst |
| `ad_templates` (+ Anzahl wirksamer Zuweisungen), `ad_template_rights` | /ad/rechtevorlagen… | `order=name` |
| `ea_property_types` (+ `ea_property_fields`) | /ad/eigenschaftsarten… | `order=name`; Felder `order=sort_order` |
| `ad_qualification_types` | /ad/qualifikationsarten…, Auswahlfeld „Qualifikationsart“ | Filter Sparte, Typ, Status (Standard `current`); Suche Bezeichnung/Kürzel; `order=discipline,name` |
| `ea_referate`, `ea_gremien` | Zuweisung, Eigenschaftsformular | `is_active=eq.true` für neue Auswahl; `order=sort_order` |
| `ad_audit_log` | /ad/protokoll | `order=occurred_at.desc`, `range` 50 je Seite |

Anzeigenamen für „ausgeführt von“ im Protokoll: über `ad_accesses.auth_user_id → ea_persons` (Umsetzung in T22).

## Schreiben (direkt)

| Objekt | Operation | Spalten |
|---|---|---|
| `ea_persons` | insert (nur AD ≥ edit), update | `first_name`, `last_name`, `preferred_name` (`kind` nur durch AD; im MVP nicht in der Oberfläche) |
| `ad_accesses` | insert, update | `person_id`, `login_email` (direktes Update nur bei Status `none`; bei `invited` über `ad-access` `change_email`; bei `active`/`locked` `AD_EMAIL_LOCKED`, R20) |
| `ad_templates` | insert, update | `name`, `description` |
| `ad_template_rights` | update | `level`, `scope` (R30: `referat` nur bei EA) |
| `ad_qualification_types` | insert, update | alle fachlichen Spalten außer `source_ref` |
| `ea_referate`, `ea_gremien` | insert, update | `name`, `sort_order`, `is_active` (Oberfläche folgt mit EA) |
| `ea_properties` | insert, update | `person_id`, `property_type_id`, `field_values`, `related_referat_id`, `related_gremium_id`, `valid_from`, `valid_to` |

Eigenschaftsarten werden nicht direkt geschrieben, sondern über `ea_save_property_type` (RPC).

## RPC

| Funktion | Parameter | Rückgabe | Story |
|---|---|---|---|
| `ad_me` | – | `person_id, first_name, last_name, preferred_name, access_status` | Kopfzeile, Startseite |
| `ad_my_modules` | – | `code, name, level` | US-AD-05 |
| `ad_has_level` | `p_module, p_min` | boolean | Routenschutz, Edge Functions |
| `ad_has_any_level` | `p_module, p_min` | boolean | Navigation, Routenschutz /ea |
| `ad_my_referate` | `p_module, p_min` | uuid[] | Eigenschaftsformular (eigene Referate) |
| `ad_can_edit_qualification_types` | – | boolean | US-AD-17 |
| `ad_qualification_usage` | `p_id` | int | US-AD-17 |
| `ad_find_similar_persons` | `p_first, p_last, p_email` | `person_id, first_name, last_name, preferred_name, birth_year, volunteer_status, left_since, is_visible` | US-AD-07, US-AD-25 |
| `ad_assign_template` | `p_person, p_template, p_referate?` | void | US-AD-11, US-AD-21 |
| `ad_set_assignment_referate` | `p_assignment, p_referate` | void | US-AD-21 |
| `ad_revoke_template` | `p_person, p_template` | void | US-AD-11 |
| `ea_save_property_type` | `p_type` (jsonb), `p_fields` (jsonb-Array) | uuid | US-AD-12, US-AD-19, US-AD-22 |
| `ea_set_volunteer_status` | `p_person, p_status, p_valid_from?` | void | US-AD-23 (Oberfläche in EA) |
| `ea_person_referate` | `p_person` | `id, name` | US-AD-23 (Oberfläche in EA) |
| `ea_create_volunteer` | `p_first, p_last, p_preferred, p_property_type, p_referat, p_field_values, p_valid_from, p_contact_email?` (seit v0.8.1) | uuid | US-AD-23 (Oberfläche in EA), US-AD-30 |
| `ea_activate_person` | `p_person, p_property_type, p_referat, p_field_values, p_valid_from` | void | US-AD-23, US-AD-25, US-AD-30 (EZ-Weg seit v0.8.1) |
| `ad_pending_emergency_logins` | – | `count, last_at` | US-AD-15 |
| `ad_acknowledge_emergency` | – | void | US-AD-15 |

Nachtrag v0.8 (seit 24.10.2026, tasks.md Phase 15):

| Objekt | Parameter / Spalten | Rückgabe | Story |
|---|---|---|---|
| `ad_locations` (Tabelle) | `id, name, has_climbing_points, is_active, created_*, updated_*`; schreiben `name, has_climbing_points, is_active` | – | US-AD-27 |
| `ad_can_edit_locations` | – | boolean | US-AD-27 |
| `ea_person_names` | `p_ids` (höchstens 500) | `id, first_name, preferred_name, last_name` | US-AD-29 |
| `ea_search_active_persons` | `p_query` (≥ 2 Zeichen), `p_limit` (1–50, Standard 20) | `id, first_name, preferred_name, last_name` | US-AD-29 |
| `ez_person_visible` | `p_person` | boolean (Platzhalter false) | US-AD-29 |

Nicht umgesetzt (Nachtrag v0.9): `ea_person_licenses`, `ad_rates_at`, `ad_can_edit_rates`, `ad_can_read_rates`.
