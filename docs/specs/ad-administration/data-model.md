# Data Model: Administration (AD)

Stand: 19.10.2026 · Phase 1 zu [plan.md](plan.md) · Grundlage: [spec.md](spec.md) v0.3

Führend ist spec.md: Abschnitt 2 legt Spalten, Typen und Defaults fest, Abschnitt 3 die RLS. Diese Datei wiederholt die Spalten nicht. Sie beschreibt, **wie** sie umgesetzt werden: Migrationsdatei, Constraints, Trigger, Policies und Grants. Technische Begründungen stehen in [research.md](research.md).

## Migrationsdateien

| Datei (Vorschlag) | Task | Inhalt |
|---|---|---|
| `supabase/migrations/20261020000100_ad_foundation.sql` | T1 | Erweiterungen `citext`, `pg_trgm`, `pg_cron`; Enums; `ad_modules` + Stammdaten; `ad_user_level`, `ad_has_level` (plpgsql) |
| `…000200_ea_person_model.sql` | T2 | `ea_persons`, `ea_property_types`, `ea_properties`, `ea_property_history`, Trigger, View `ea_v_persons`, Policies |
| `…000300_ad_rights.sql` | T3 | `ad_templates`, `ad_template_rights`, `ad_template_assignments`, `ad_accesses` (inkl. R20-Trigger), Startvorlagen, `ad_my_modules`, `ad_assign_template`, `ad_revoke_template`, Policies |
| `…000400_ad_audit.sql` | T4 | `ad_audit_log`, `ad_notice_acks`, `ad_pending_emergency_logins`, `ad_acknowledge_emergency`, pg_cron-Job, Policies; interne `ad_apply_invite`, `ad_apply_lock`, `ad_apply_unlock` |
| `…000500_ad_auth_triggers.sql` | T5 | drei Trigger auf `auth.users` |
| `…000600_ad_overview_me.sql` | T6 | View `ad_v_person_overview`, Funktion `ad_me()` |
| `…000700_ad_find_similar_persons.sql` | T8 | `ad_find_similar_persons` |

Jede Migration enthält für die Tabellen, die sie anlegt, `enable row level security`, die Policies, `revoke all … from anon, public` und `grant … to authenticated`.

## Enums (T1)

Fünf Enums mit Werten exakt nach spec.md: `ad_level` (Reihenfolge `none` < `read` < `edit` < `manage` für den Vergleich), `ad_access_status`, `ea_data_type`, `ea_person_kind`, `ad_audit_action`. Dazu `grant usage on type … to authenticated`.

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
  - `ad_accesses_login_email_key` (unique)
  - `ad_accesses_login_email_domain` (`like '%@dav-leipzig.de'`)
  - unique `person_id`
  - unique `auth_user_id`
  - partieller Unique-Index `where is_emergency`
- Trigger `ad_accesses_guard` (before update of login_email): Status nicht in (`none`, `invited`) → `AD_EMAIL_LOCKED` (R20).
- Policies: select bei AD ≥ read; insert/update bei AD ≥ edit.
- Grants: `select`, `insert (person_id, login_email)`, `update (login_email)`.

### ad_audit_log, ad_notice_acks (T4)
- `ad_audit_log`: select bei AD ≥ read, Grant nur `select`. Geschrieben wird nur über security-definer-Funktionen und Trigger, gelöscht nur durch den pg_cron-Job um 01:15 UTC.
- `ad_notice_acks`: Policies auf die eigene Zeile (`user_id = auth.uid()`).
- `ad_pending_emergency_logins()`, `ad_acknowledge_emergency()`: prüfen AD ≥ read.

## Funktionen

| Funktion | Art | Grant | Task |
|---|---|---|---|
| `ad_user_level(text)`, `ad_has_level(text, ad_level)` | security definer, stable, plpgsql | authenticated | T1 |
| `ad_my_modules()` | security definer, stable | authenticated | T3 |
| `ad_assign_template`, `ad_revoke_template` | security definer | authenticated | T3 |
| `ad_pending_emergency_logins`, `ad_acknowledge_emergency` | security definer | authenticated | T4 |
| `ad_apply_invite(p_person, p_auth_user, p_actor)` | security definer | service_role | T4 (genutzt in T9) |
| `ad_apply_lock(p_person, p_actor)`, `ad_apply_unlock(p_person, p_actor)` | security definer | service_role | T4 (genutzt in T10) |
| `ad_me()` | security definer, stable | authenticated | T6 |
| `ad_find_similar_persons(text, text, text)` | security invoker, stable | authenticated | T8 |
| Trigger-Funktionen | security definer bzw. invoker | keiner | T2, T3, T5 |

Alle security-definer-Funktionen haben `set search_path = ''` und nutzen voll qualifizierte Namen.

## Zustände Zugang (spec.md Abschnitt 4)

| Übergang | Umgesetzt in |
|---|---|
| kein Zugang → eingeladen | `ad-invite` → `ad_apply_invite`; zusätzlich Trigger `after insert on auth.users` (Einladung über das Dashboard) |
| eingeladen → eingeladen | `ad-invite` (ggf. vorher E-Mail im Auth-Nutzer anpassen, R20) |
| eingeladen → aktiv | Trigger `after update of encrypted_password` (erstes Passwort) |
| eingeladen/aktiv → gesperrt | `ad-access` lock → `ad_apply_lock` |
| gesperrt → aktiv / eingeladen | `ad-access` unlock → `ad_apply_unlock`; die Richtung hängt davon ab, ob `encrypted_password` gefüllt ist |

## Testdaten

Nach spec.md Abschnitt 9. Umsetzung mit `supabase/seed.sh` und `supabase/seed.sql`, siehe research.md R-10.
