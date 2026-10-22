# Contract: Datenbank-Schnittstelle EA (PostgREST)

Stand: 22.10.2026 · zu [plan.md](../plan.md) · Grundlage: [spec.md](../spec.md) v0.2, Abschnitte 2, 3, 5, 6

Das Frontend greift mit dem Publishable Key und dem JWT des Nutzers zu. Schutz entsteht nur über die RLS der Administration ([data-model.md Administration](../../ad-administration/data-model.md)). Objekte der Administration, die hier nur genutzt werden, beschreibt [database-api.md Administration](../../ad-administration/contracts/database-api.md).

## Lesen (Tabellen/Views)

| Objekt | genutzt von | Filter/Sortierung |
|---|---|---|
| `ea_v_expiry` | /ea/ablauf, Ablauf-Badges im Detail | Stichtagsliste: `kind=in.(license,qualification)`, `valid_until` im Jahr, `order=valid_until`; Detail: `person_id=eq.…` |
| `ea_persons` | /ea/aktive/:id (Kopf) | `id=eq.…`; nicht lesbar → Meldung „Diese Person wurde nicht gefunden oder du hast keine Rechte.“ |
| `ea_volunteer_status_history` | Detail, Statushistorie | `person_id=eq.…`, `order=set_at.desc` |
| `ea_properties` (+ `ea_property_types`, `ea_property_fields`, `ea_property_history`, `ea_referate`, `ea_gremien`, `ad_qualification_types`) | Detail | `person_id=eq.…`; Arten mit `visible_in` ∋ `EA`; gruppiert nach `category` (Reihenfolge des Enums); aktuelle vor beendeten |
| `ea_properties` (+ `ea_persons`, `ea_gremien`) | /ea/gremien | Art `system_key=eq.committee`, aktuell; gruppiert nach Gremium (`sort_order`, nur `is_active`) |
| `ea_referate`, `ea_gremien` | /ea/stammdaten, Filter, Auswahl im Formular | Auswahl: `is_active=eq.true`, `order=sort_order`; Pflege: alle |
| `ea_property_types` (+ Felder) | „Eigenschaft hinzufügen“ | `visible_in=cs.{EA}`; für Referent:in zusätzlich `read_level=eq.all` (spec.md Abschnitt 6) |
| `ad_qualification_types` | Filter Qualifikation und Sparte | `status=eq.current` für Neuanlage; Filter: alle |

## Schreiben (direkt)

| Objekt | Operation | Spalten | Story |
|---|---|---|---|
| `ea_properties` | insert, update | über das Eigenschaftsformular der Administration; Beenden = update `valid_to` | US-EA-06, 07 |
| `ea_referate`, `ea_gremien` | insert, update | `name`, `sort_order`, `is_active` | US-EA-14 |
| `ea_property_types`, `ea_property_fields` | über RPC `ea_save_property_type` (Administration) | – | US-EA-15 |

## RPC

| Funktion | Parameter | Rückgabe | Fehler | Story |
|---|---|---|---|---|
| `ea_volunteer_list` | `p_search text`, `p_status ea_volunteer_status[]` (Standard `{active,dormant}`), `p_referate uuid[]`, `p_function text`, `p_position text`, `p_gremium uuid`, `p_qualification_type uuid`, `p_discipline text`, `p_expiry text[]`, `p_trainer_without_license boolean`, `p_without_assignment boolean`, `p_limit int` (50; 1–200), `p_offset int` (0) | `id, first_name, preferred_name, last_name, volunteer_status, volunteer_status_since, referate text[], functions text[], positions text[], license_codes text[], worst_expiry text, trainer_without_license boolean, total_count bigint` | – (RLS filtert) | US-EA-02, 03, 11, 12 |
| `ea_expiry_status` | `p_valid_until date`, `p_today date` | `'none' \| 'valid' \| 'expiring' \| 'expired'` | – | US-EA-11 |
| `ea_default_valid_until` | `p_qualification_type uuid`, `p_valid_from date`, `p_last_training date` | date oder null | – | US-EA-07 |
| `ea_iban_valid` | `p_iban text` | boolean | – | US-EA-06 (Hinweis im Formular) |
| `ea_change_volunteer_status` | `p_person uuid`, `p_status ea_volunteer_status`, `p_valid_from date` | void | `EA_STATUS_FORBIDDEN`, `EA_STATUS_DATE` (Detail: Grenzdatum TT.MM.JJJJ), `EA_STATUS_UNCHANGED` | US-EA-08, 10 |
| `ea_leave` | `p_person uuid`, `p_valid_from date`, `p_end_property_ids uuid[]` | void | `EA_STATUS_FORBIDDEN`, `EA_STATUS_DATE`, `EA_LEAVE_PROPERTY` | US-EA-09 |
| `ea_renew_property` | `p_property uuid`, `p_valid_from date`, `p_field_values jsonb`, `p_training jsonb` (`{"year": int, "title": text}` oder null) | uuid (neue Eigenschaft) | `EA_RENEW_INVALID`, Fehler des Triggers (`EA_FIELD_REQUIRED`, `AD_QUALIFICATION_HISTORIC` …) | US-EA-07 |
| `ea_import_volunteers` | `p_rows jsonb`, `p_cutoff date`, `p_dry_run boolean` | `{"errors":[{"row","message"}], "warnings":[{"row","message"}], "counts":{…}, "written":bool}` | nur `service_role`; für `authenticated` „permission denied“ | US-EA-17, 18 |

Genutzt aus der Administration: `ea_create_volunteer`, `ea_activate_person` (US-EA-05, 10), `ad_find_similar_persons` (US-EA-05, 10), `ea_person_referate` (R7), `ea_property_writable` (Auswahl beim Ausscheiden, R8), `ad_my_referate('EA','edit')`, `ad_has_level`, `ad_has_any_level` (Navigation, Knöpfe).

## Fehlercodes

Neue Codes nach spec.md Abschnitt 5. Spec-Task T8 trägt sie in [error-codes.md der Administration](../../ad-administration/contracts/error-codes.md) ein, Abschnitt „Ehrenamtsmanagement“. Sie sind dort normativ.

| Code | Meldung | Regel |
|---|---|---|
| `EA_IBAN_INVALID` | Die IBAN ist ungültig. | R13 |
| `EA_STATUS_DATE` | Bitte ein Datum bis spätestens <TT.MM.JJJJ> wählen. | R18 |
| `EA_STATUS_UNCHANGED` | Die Person hat diesen Status bereits. | R19 |
| `EA_LEAVE_PROPERTY` | Diese Angabe kann hier nicht beendet werden. | R20 |
| `EA_RENEW_INVALID` | Nur aktuelle Lizenzen und Qualifikationen können verlängert werden; das neue Datum muss nach dem bisherigen liegen. | R6 |

Zusätzlich (Entscheidung Product Owner 23.10.2026, plan.md O3): `ea_create_volunteer` und `ea_activate_person` melden `EA_CREATE_FORBIDDEN` („Für diesen Bereich hast du keine Rechte.“) und `EA_CREATE_REFERAT_REQUIRED` („Bitte eine Funktion oder ein Amt in deinem Referat angeben.“); die Prüfung ersetzt eine Migration des Ehrenamtsmanagements.
