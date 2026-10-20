# Data Model: Administration (AD)

Stand: 20.10.2026 · Phase 1 zu [plan.md](plan.md) · Grundlage: [spec.md](spec.md) v0.5

Führend ist spec.md: Abschnitt 2 legt Spalten, Typen und Defaults fest, Abschnitt 3 die RLS. Diese Datei wiederholt die Spalten nicht. Sie beschreibt, **wie** sie umgesetzt werden: Migrationsdatei, Constraints, Trigger, Policies und Grants. Technische Begründungen stehen in [research.md](research.md).

## Migrationsdateien

| Datei (Vorschlag) | spec-Task | Story (tasks.md) | Inhalt |
|---|---|---|---|
| `supabase/migrations/20261020000100_ad_foundation.sql` | T1 | US-AD-01 | Erweiterungen, Enums, `ad_modules`, `ad_user_level`, `ad_has_level` |
| `…000200_ea_persons.sql` | T2 Teil | US-AD-01 | `ea_persons`, `ea_v_persons`, Policies |
| `…000300_ad_rights.sql` | T3 | US-AD-01 | Vorlagen, Rechte, Zuweisungen, `ad_accesses`, Startvorlagen, `ad_my_modules`, `ad_assign_template`, `ad_revoke_template` |
| `…000400_ad_audit_log.sql` | T4 Teil | US-AD-01 | `ad_audit_log` |
| `…000500_ad_auth_triggers.sql` | T5 | US-AD-01 | Trigger auf `auth.users`, `ad_test_login_domains`, `ad_login_email_allowed`, `ad_accesses_guard` (R1, R20) |
| `…000600_ad_me.sql` | T6 Teil | US-AD-02 | `ad_me()` |
| `…000700_ad_person_overview.sql` | T6 Teil | US-AD-06 | `ad_v_person_overview` |
| `…000800_ad_find_similar_persons.sql` | T8 | US-AD-07 | `ad_find_similar_persons` |
| `…000900_ea_property_types.sql` | T2 Teil | US-AD-12 | `ea_property_types` mit Trigger |
| `…001000_ea_properties.sql` | T2 Teil | US-AD-13 | `ea_properties`, `ea_property_history`, Trigger |
| `…001100_ad_invite_functions.sql` | T4 Teil | US-AD-08 | `ad_apply_invite`, `ad_revert_invite`, `ad_apply_email_change` |
| `…001200_ad_lock_functions.sql` | T4 Teil | US-AD-09 | `ad_apply_lock`, `ad_apply_unlock` |
| `…001300_ad_audit_retention.sql` | T4 Teil | US-AD-14 | pg_cron-Job, View `ad_v_audit_log` |
| `…001400_ad_emergency_notice.sql` | T4 Teil | US-AD-15 | `ad_notice_acks`, `ad_pending_emergency_logins`, `ad_acknowledge_emergency` |

Jede Migration enthält für die Tabellen, die sie anlegt, `enable row level security`, die Policies, `revoke all … from anon, public` und `grant … to authenticated`.

## Enums (T1)

Fünf Enums mit Werten exakt nach spec.md: `ad_level` (Reihenfolge `none` < `read` < `edit` < `manage` für den Vergleich), `ad_access_status`, `ea_data_type`, `ea_person_kind`, `ad_audit_action` (inkl. `email_changed`). Dazu `grant usage on type … to authenticated`.

## Tabellen

### ad_modules (T1)
- Stammdaten: AD (`is_available = true`), dazu SC, EA, GR, FI, OA, PM, GS, AM (`false`). Namen nach glossar.md.
- Policy: `select` für alle angemeldeten Nutzer. Kein Schreibrecht.

### ea_persons (T2)
- Trigger `ea_persons_normalize` (before insert/update) trimmt Vor- und Nachnamen. Ist danach einer leer → `AD_NAME_REQUIRED` (R4). Zusätzlich die Checks `btrim(…) <> ''`.
- Policies:
  - select: `ad_has_level('AD','read') or (ad_has_level('EA','read') and kind = 'human')`
  - insert/update: `ad_has_level('AD','edit') or (ad_has_level('EA','edit') and kind = 'human')`
- Grants: `select`, `insert/update (first_name, last_name, kind)`.

### ea_property_types (T2)
- Unique-Index `lower(name)` (`ea_property_types_name_key`)
- Checks: Zweck nicht leer; `choice_values` genau dann gesetzt und nicht leer, wenn `data_type = 'choice'`; `origin in ('system','custom')`; `cardinality(visible_in) >= 1`.
- Trigger `ea_property_types_guard` (before insert/update) prüft:
  - `visible_in` enthält nur Codes aus `ad_modules`.
  - Datentyp nicht änderbar, solange Eigenschaften dieser Art existieren → `EA_DATA_TYPE_LOCKED`.
  - Auswahlwerte dürfen nicht entfernt werden → `EA_CHOICE_VALUE_REMOVED`.
  - `confidential` setzen oder ändern nur mit AD ≥ edit → `EA_CONFIDENTIAL_FORBIDDEN`.
  - setzt `updated_at`/`updated_by`.
- Policies:
  - select: `ad_has_level('AD','read') or (ad_has_level('EA','read') and not confidential)`
  - insert/update: `ad_has_level('AD','edit') or (ad_has_level('EA','manage') and not confidential)`

### ea_properties (T2)
- Check `ea_properties_valid_range` (`valid_to >= valid_from`).
- Trigger `ea_properties_validate`: genau die zum Datentyp passende Wertspalte ist gefüllt, bei `choice` liegt der Wert in `choice_values`; sonst `EA_VALUE_TYPE`. Setzt `updated_*`.
- Trigger `ea_properties_history` (after update, security definer) schreibt die alte Fassung.
- Policies:
  - select: `ad_has_level('AD','read') or (ad_has_level('EA','read') and nicht vertraulich and Person human)`
  - insert/update: dasselbe mit `edit`
- „Beendet“ wird nicht gespeichert, sondern berechnet: `valid_to < current_date`.

### ea_property_history (T2)
Policy select über `exists` auf `ea_properties` (erbt dessen RLS). Grant nur `select`.

### ea_v_persons (T2)
`security_invoker = true`, `where kind = 'human'`; `grant select to authenticated`.

### ad_templates / ad_template_rights (T3)
- `ad_templates`: Unique-Index `lower(name)` (`ad_templates_name_key`).
- `ad_template_rights`:
  - Checks `object is null`, `scope = 'all'`.
  - Unique-Index `(template_id, module_code, coalesce(object,''))`.
  - Grant nur `update (level)`.
- Trigger `ad_templates_init_rights` (after insert): legt je Modul eine Zeile mit `none` an.
- Startvorlagen per Migration, idempotent.
- Policies: select bei AD ≥ read, insert/update bei AD ≥ edit.

### ad_template_assignments (T3)
- Partieller Unique-Index `(person_id, template_id) where revoked_at is null`.
- select bei AD ≥ read. Kein Schreib-Grant; geschrieben wird nur über `ad_assign_template` und `ad_revoke_template` (security definer, prüfen AD ≥ edit, schreiben das Protokoll). Erneutes Zuweisen erzeugt keinen zweiten Eintrag.
- Wirksam: `revoked_at is null`, und `current_date` liegt in [`valid_from`, `valid_to`]; null bedeutet offen.

### ad_accesses (T3)
- Constraints:
  - FK `auth_user_id` → `auth.users(id)` **on delete set null**
  - `ad_accesses_login_email_key` (unique)
  - unique `person_id`
  - unique `auth_user_id`
  - partieller Unique-Index `where is_emergency`
- Kein Check-Constraint für R1 (spec.md v0.5).
- Trigger `ad_accesses_guard` (T5, before insert or update of login_email):
  - R1: `ad_login_email_allowed(new.login_email)` ist falsch → `AD_EMAIL_DOMAIN`.
  - R20 (nur update):
  - Status `none` → erlaubt (direkt aus der Oberfläche).
  - Status `invited` → nur erlaubt, wenn die Änderung aus `ad_apply_email_change` kommt (transaktionslokales Kennzeichen `set_config('ad.email_change', 'on', true)`); sonst `AD_EMAIL_CHANGE_VIA_FUNCTION`.
  - Status `active` oder `locked` → `AD_EMAIL_LOCKED`.
- Policies: select bei AD ≥ read; insert/update bei AD ≥ edit.
- Grants: `select`, `insert (person_id, login_email)`, `update (login_email)`.

### ad_test_login_domains (T5, nur TEST befüllt)
- Spalten nach spec.md v0.5 (`domain citext` PK, ohne „@“, `created_at`).
- `enable row level security`; `revoke all … from anon, authenticated, public`; keine Grants (spec.md v0.5). Zugriff nur über `ad_login_email_allowed` (security definer) und den SQL-Editor im Dashboard.
- Keine Policies, keine Grants – zulässig nach der Ausnahme in Constitution III (Version 1.1.1) für Tabellen ohne Nutzerzugriff.
- Wird nie per Migration, Seed oder Repo befüllt. `prod-bootstrap.sql` (T24) bricht ab, wenn die Tabelle Einträge hat.

### ad_audit_log, ad_notice_acks (T4)
- `ad_audit_log`: select bei AD ≥ read, Grant nur `select`. `actor_user_id` ohne FK auf `auth.users`, damit das Löschen von Auth-Einträgen (Aufräumen in `ad-invite`, `change_email`) nicht an Protokolleinträgen scheitert und das Protokoll vollständig bleibt. Geschrieben wird nur über security-definer-Funktionen und Trigger, gelöscht nur durch den pg_cron-Job um 01:15 UTC.
- `ad_notice_acks`: Policies auf die eigene Zeile (`user_id = auth.uid()`). FK `user_id` → `auth.users` **on delete cascade**, damit das Löschen von Test-Auth-Nutzern beim Aufräumen nicht scheitert.
- `ad_pending_emergency_logins()`, `ad_acknowledge_emergency()`: prüfen AD ≥ read.

## Funktionen

| Funktion | Art | Grant | Task |
|---|---|---|---|
| `ad_user_level(text)`, `ad_has_level(text, ad_level)` | security definer, stable, plpgsql | authenticated | T1 |
| `ad_my_modules()` | security definer, stable | authenticated | T3 |
| `ad_assign_template`, `ad_revoke_template` | security definer | authenticated | T3 |
| `ad_pending_emergency_logins`, `ad_acknowledge_emergency` | security definer | authenticated | T4 |
| `ad_apply_invite(p_person, p_auth_user, p_actor)` | security definer | service_role | T4 (genutzt in T9) |
| `ad_revert_invite(p_person, p_status, p_auth_user, p_last_invited_at)` | security definer | service_role | T4 (genutzt in T9) |
| `ad_apply_lock(p_person, p_actor)`, `ad_apply_unlock(p_person, p_actor)` | security definer | service_role | T4 (genutzt in T10) |
| `ad_apply_email_change(p_person, p_new_email, p_actor)` | security definer | service_role | T4 (genutzt in T10) |
| `ad_me()` | security definer, stable | authenticated | T6 |
| `ad_login_email_allowed(citext)` | security definer, stable | service_role (Edge Functions); Trigger ruft sie direkt | T5 |
| `ad_find_similar_persons(text, text, text)` | security invoker, stable | authenticated | T8 |
| Trigger-Funktionen | security definer bzw. invoker | keiner | T2, T3, T5 |

Alle security-definer-Funktionen haben `set search_path = ''` und nutzen voll qualifizierte Namen.

## Zustände Zugang (spec.md Abschnitt 4)

| Übergang | Umgesetzt in |
|---|---|
| kein Zugang → eingeladen | `ad-invite` → `ad_apply_invite`; zusätzlich Trigger `after insert on auth.users` (Einladung über das Dashboard). Bei Fehler der Auth-Admin-API: `ad-invite` löscht einen neu angelegten Auth-Eintrag und ruft `ad_revert_invite` (Stand vor dem Aufruf, kein Protokoll) |
| eingeladen → eingeladen | `ad-invite` |
| eingeladen → kein Zugang | `ad-access` change_email → Auth-Eintrag löschen → `ad_apply_email_change` (neue Adresse, `auth_user_id` null, Status `none`, Protokoll `email_changed`) |
| eingeladen → aktiv | Trigger `after update of encrypted_password` (erstes Passwort) |
| eingeladen/aktiv → gesperrt | `ad-access` lock → `ad_apply_lock` |
| gesperrt → aktiv / eingeladen | `ad-access` unlock → `ad_apply_unlock`; die Richtung hängt davon ab, ob `encrypted_password` gefüllt ist |

## Testdaten

Nach spec.md Abschnitt 9. Umsetzung mit `supabase/seed.sh` und `supabase/seed.sql`, siehe research.md R-10.
