# Contract: Datenbank-Schnittstelle AD (PostgREST)

Das Frontend greift mit dem Publishable Key und dem JWT des Nutzers direkt zu; Schutz nur über RLS ([data-model.md](../data-model.md)). Spalten und Typen: [spec.md](../spec.md) Abschnitt 2.

## Lesen (Tabellen/Views)

| Objekt | genutzt von | Filter/Sortierung |
|---|---|---|
| `ad_modules` | Kopfzeile, Rechtevorlagen-Matrix, „sichtbar in“ | `order=sort_order` |
| `ad_v_person_overview` | /ad | Suche `or(first_name.ilike.*x*,last_name.ilike.*x*)`, Filter `access_status=eq.…`, `order=last_name,first_name` |
| `ea_persons`, `ad_accesses` | /ad/personen/:id | `id=eq.…` bzw. `person_id=eq.…` |
| `ad_template_assignments` (+ `ad_templates`) | /ad/personen/:id | wirksame Zuweisungen (`revoked_at=is.null`) |
| `ea_properties` (+ `ea_property_types`, `ea_property_history`) | /ad/personen/:id | Art mit `visible_in` ∋ `AD`; aktuelle zuerst |
| `ad_templates` (+ Anzahl Zuweisungen), `ad_template_rights` | /ad/rechtevorlagen… | `order=name` |
| `ea_property_types` | /ad/eigenschaftsarten… | `order=name` |
| `ad_audit_log` | /ad/protokoll | `order=occurred_at.desc`, `range` 50 je Seite |

Anzeigenamen für „ausgeführt von“ im Protokoll: über `ad_accesses.auth_user_id → ea_persons` (View oder Join; Umsetzung in T22).

## Schreiben (direkt)

| Objekt | Operation | Spalten |
|---|---|---|
| `ea_persons` | insert, update | `first_name`, `last_name` (`kind` nur durch AD; im MVP nicht in der Oberfläche) |
| `ad_accesses` | insert, update | `person_id`, `login_email` (Update nur bei Status `none`/`invited`, sonst `AD_EMAIL_LOCKED`, R20) |
| `ad_templates` | insert, update | `name`, `description` |
| `ad_template_rights` | update | `level` |
| `ea_property_types` | insert, update | `name`, `purpose`, `data_type`, `choice_values`, `visible_in`, `confidential` |
| `ea_properties` | insert, update | `person_id`, `property_type_id`, `value_*`, `valid_from`, `valid_to` |

## RPC

| Funktion | Parameter | Rückgabe | Story |
|---|---|---|---|
| `ad_me` | – | `person_id, first_name, last_name, access_status` | Kopfzeile, Startseite |
| `ad_my_modules` | – | `code, name, level` | US-AD-05 |
| `ad_has_level` | `p_module, p_min` | boolean | Routenschutz, Edge Functions |
| `ad_find_similar_persons` | `p_first, p_last, p_email` | `ea_persons[]` | US-AD-07 |
| `ad_assign_template` | `p_person, p_template` | void | US-AD-11 |
| `ad_revoke_template` | `p_person, p_template` | void | US-AD-11 |
| `ad_pending_emergency_logins` | – | `count, last_at` | US-AD-15 |
| `ad_acknowledge_emergency` | – | void | US-AD-15 |
