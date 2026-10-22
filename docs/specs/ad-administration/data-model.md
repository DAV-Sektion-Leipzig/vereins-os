# Data Model: Administration (AD)

Stand: 22.10.2026 · Phase 1 zu [plan.md](plan.md) · Grundlage: [spec.md](spec.md) v0.9, Umfang Kern bis v0.7.1

Führend ist spec.md: Abschnitt 2 legt Spalten, Typen und Defaults fest, Abschnitt 3 die RLS. Diese Datei wiederholt die Spalten nicht. Sie beschreibt, **wie** sie umgesetzt werden: Migrationsdatei, Constraints, Trigger, Policies und Grants. Technische Begründungen stehen in [research.md](research.md). Nicht im Kern: alles, was spec.md mit „v0.8“ oder „v0.9“ markiert (plan.md, Abschnitt „Abgrenzung“).

## Migrationsdateien

Ausgerollt in TEST (nicht ändern; Änderungen nur per neuer Migration):

| Datei | spec-Task | Inhalt |
|---|---|---|
| `20261020000100_ad_foundation.sql` | T1 | Erweiterungen, Enums, `ad_modules`, `ad_user_level`, `ad_has_level` |
| `20261020000200_ea_persons.sql` | T2 Teil | `ea_persons`, `ea_v_persons`, Policies (in T38 ersetzt) |
| `20261020000300_ad_rights.sql` | T3 | Vorlagen, Rechte, Zuweisungen, `ad_accesses`, Startvorlagen, `ad_my_modules`, `ad_assign_template`, `ad_revoke_template` |
| `20261020000400_ad_audit_log.sql` | T4 Teil | `ad_audit_log` |
| `20261020000500_ad_auth_triggers.sql` | T5 | Trigger auf `auth.users`, `ad_test_login_domains`, `ad_login_email_allowed`, `ad_accesses_guard` (R1, R20) |
| `20261020000600_ad_me.sql` | T6 Teil | `ad_me()` |

Neu im Kern (Branch `ad-kern-datenbank`, Reihenfolge = Dateiname; die Startvorlagen (T40) stehen vor den Eigenschaftsarten, weil der Seed die Vorlage Referent:in braucht):

| Datei | spec-Task | Inhalt |
|---|---|---|
| `20261023000100_ad_kern_enums.sql` | T26, T33, T35, T37 | neue Werte `ea_data_type` (`number`, `year`, `qualification_type`), `ad_audit_action` (`referate_changed`); neue Enums `ad_scope`, `ea_read_level`, `ea_relation_kind`, `ea_property_category`, `ea_volunteer_status`, `ad_qualification_kind`, `ad_license_level`, `ad_qualification_status` (research.md R-17) |
| `…000200_ea_referate_gremien.sql` | T34, T26 Teil | `ad_has_active_access()`; `ea_referate` (7), `ea_gremien` (4) mit Startbestand |
| `…000300_ad_scope.sql` | T33 | Umstellung `ad_template_rights.scope`, Check R30 (nur EA), `ad_assignment_referate`, `ad_my_referate`, `ad_has_any_level`, neue Fassungen `ad_user_level`, `ad_my_modules`, `ad_assign_template` (mit `p_referate`), `ad_set_assignment_referate` |
| `…000400_ad_qualification_types.sql` | T26 | `ad_qualification_types`, Trigger (R21–R24, Kürzel groß), `ad_can_edit_qualification_types()` |
| `…000500_ad_qualification_types_data.sql` | T27 | Startbestand 47 Qualifikationsarten |
| `…000600_ea_persons_v07.sql` | T37 | neue Spalten `ea_persons`, `ea_volunteer_status_history`, Trigger `ea_persons_guard` |
| `…000700_ad_start_templates_v07.sql` | T40 | Vorlage „Referent:in“ (EA `edit`, scope `referat`), Admin GR `read` |
| `…000800_ea_property_types.sql` | T35 | `ea_property_types`, `ea_property_fields`, Trigger, `ea_save_property_type` |
| `…000900_ea_properties.sql` | T36 | `ea_properties`, `ea_property_history`, Trigger `ea_properties_validate`, `ea_properties_history` |
| `…001000_ea_visibility.sql` | T38 | Sichtbarkeitsfunktionen, Policies auf `ea_persons` (ersetzt), `ea_volunteer_status_history`, `ea_property_types`, `ea_property_fields`, `ea_properties`, `ea_property_history` |
| `…001100_ea_volunteer_functions.sql` | T39 | `ea_set_volunteer_status`, `ea_person_referate`, `ea_create_volunteer` (Kern-Signatur), `ea_activate_person` |
| `…001200_ad_person_overview.sql` | T6 Teil, T41, T26 Teil | `ad_v_person_overview`, neue Fassung `ad_me()` (mit Rufname), `ad_qualification_usage` |
| `…001300_ad_find_similar_persons.sql` | T8, T43 | `ad_find_similar_persons` nach R40 |
| `…001400_ad_emergency_notice.sql` | T4 Teil | `ad_notice_acks`, `ad_pending_emergency_logins`, `ad_acknowledge_emergency`, pg_cron-Job 01:15 UTC |

Danach (Branch `us-ad-08-zugang`):

| Datei | spec-Task | Inhalt |
|---|---|---|
| `…001500_ad_invite_functions.sql` | T4 Teil | `ad_apply_invite`, `ad_revert_invite`, `ad_apply_email_change` |
| `…001600_ad_lock_functions.sql` | T4 Teil | `ad_apply_lock`, `ad_apply_unlock` |

Danach (Branch `us-ad-14-protokoll`):

| Datei | spec-Task | Inhalt |
|---|---|---|
| `…001700_ad_audit_view.sql` | T4 Teil | View `ad_v_audit_log` mit Namen von Akteur und betroffener Person |

Jede Migration enthält für die Objekte, die sie anlegt, `enable row level security`, die Policies, `revoke all … from anon, public` und `grant … to authenticated` (interne Funktionen nur an `service_role`). Alle security-definer-Funktionen haben `set search_path = ''` und nutzen voll qualifizierte Namen.

## Enums

Bestehend (T1): `ad_level` (`none` < `read` < `edit` < `manage`), `ad_access_status`, `ea_data_type`, `ea_person_kind`, `ad_audit_action`. Neu und erweitert nach spec.md Abschnitt 2 (Migration `…000100`, research.md R-17); `ad_scope` im Kern nur `all`, `referat` (`group` folgt mit A6). Je Enum `grant usage on type … to authenticated`.

## Tabellen

### ad_modules (T1, unverändert)
- 9 Zeilen: AD (`is_available = true`), SC, EA, GR, FI, OA, PM, GS, AM. Keine Spalte `is_hidden`, keine Zeilen EZ, TK, TKF im Kern.
- Policy: `select` für alle angemeldeten Nutzer. Kein Schreibrecht.

### ea_referate, ea_gremien (T34)
- Unique-Index `lower(name)` (`ea_referate_name_key`, `ea_gremien_name_key`); Trigger `ad_set_updated` für `updated_*`.
- Startbestand per Migration, idempotent (`on conflict do nothing` über `lower(name)`): Referate Ausbildung, Touren, Kinder und Jugend, Klettern, Leistungssport, Karl-Stein-Hütte, Sulzenauhütte (sort_order 1–7); Gremien Vorstand, Beirat, Ehrenrat, Jugendausschuss.
- Policies: select `ad_has_active_access()`; insert/update `ad_has_level('AD','edit') or ad_has_level('EA','manage')`. Kein Delete.

### ad_template_rights (T3, T33)
- `scope` als `ad_scope` (research.md R-18); Check `ad_template_rights_scope_allowed`: `scope = 'all' or (scope = 'referat' and module_code = 'EA')`. Trigger `ad_template_rights_guard` meldet vorab `AD_SCOPE_NOT_ALLOWED`.
- Grant `update (level, scope)` (bisher nur `level`).

### ad_assignment_referate (T33)
- PK `(assignment_id, referat_id)`; FK `assignment_id` on delete cascade, FK `referat_id`.
- Policy: select `ad_has_level('AD','read')`. Kein Schreib-Grant; geschrieben nur von `ad_assign_template` und `ad_set_assignment_referate` (security definer, prüfen AD ≥ edit und R31: Vorlage mit einem Recht `scope = 'referat'` → mindestens ein aktives Referat, sonst `AD_REFERAT_REQUIRED`; sonst keine Referate).

### ad_qualification_types (T26, T27)
- Checks nach spec.md (R21–R24) mit Namen; Unique-Indizes `ad_qualification_types_name_key` (`lower(name)`), `…_code_key` (`lower(code) where code is not null`), `…_source_ref_key`; Index `(discipline, kind)`.
- Trigger `ad_qualification_types_guard` (before insert/update): trimmt, Kürzel → Großbuchstaben, meldet `AD_QUALIFICATION_NAME_REQUIRED`, `…_NAME_TAKEN`, `…_CODE_TAKEN`, `…_CODE_FORMAT`, `…_LEVEL_REQUIRED`, `…_VALIDITY`; leert `level` bei anderen Typen als Lizenz und `validity_years` bei Zusatzqualifikation und Lehrgang; `source_ref` nur ohne Nutzerkontext änderbar; setzt `updated_*`.
- Policies: select `ad_has_active_access()`; insert/update `ad_can_edit_qualification_types()`. Kein Delete.

### ea_persons (T2, T37, T38)
- Neue Spalten nach spec.md: `preferred_name`, `created_in` (Check `in ('AD','EA','GR','script')`, Default `'AD'`), `volunteer_status`, `volunteer_status_since` (Check beide null oder beide gesetzt), Check `kind = 'function'` → `volunteer_status is null`. Indizes `gin (preferred_name gin_trgm_ops)`, `(volunteer_status) where volunteer_status is not null`.
- `ea_persons_normalize` trimmt zusätzlich den Rufname (leer → null).
- Trigger `ea_persons_guard` (research.md R-23): `kind`, `created_in` unveränderlich; Ehrenamtsstatus nur ohne Nutzerkontext oder mit Kennzeichen `ea.status_change`.
- Policies (T38, ersetzen die bisherigen):
  - select: `ea_person_visible(id)`
  - insert: `ad_has_level('AD','edit') and created_in = 'AD' and volunteer_status is null`
  - update: `ad_has_level('AD','edit') or ea_person_visible_ea(id, 'edit') or gr_person_visible(id, 'edit')` (using und with check)
- Grants: `select`, `insert (first_name, last_name, preferred_name, kind)`, `update (first_name, last_name, preferred_name)`.

### ea_volunteer_status_history (T37)
- Index `(person_id, set_at desc)`. Policy select `ea_person_visible(person_id)`. Kein Schreib-Grant; geschrieben von den EA-Funktionen (T39) und ohne Nutzerkontext (Seed, Migrationsskript).

### ea_property_types, ea_property_fields (T35)
- `ea_property_types`: Unique-Index `lower(name)` (`ea_property_types_name_key`), unique `system_key`; Checks Zweck nicht leer (`EA_PURPOSE_REQUIRED` im Trigger), `cardinality(visible_in) >= 1`, `origin in ('system','custom')`, `relation_required` nur bei `relation_kind <> 'none'`.
- `ea_property_fields`: Unique `(property_type_id, key)`, Unique-Index `(property_type_id, lower(label))` (`ea_property_fields_label_key`); Check `key ~ '^[a-z][a-z0-9_]{0,39}$'`; Check `choice_values` genau bei `choice` mit ≥ 1 Wert (`EA_CHOICE_VALUES_REQUIRED` im Trigger); Check `allowed_qualification_kinds` nur bei `qualification_type`.
- Trigger nach research.md R-21. RPC `ea_save_property_type(p_type jsonb, p_fields jsonb)` (security invoker) speichert Art und Felder in einer Transaktion und prüft R9 (`EA_NO_FIELDS`).
- Policies (T38): select `ad_has_level('AD','read') or ((ad_has_any_level('EA','read') or ad_has_level('GR','read')) and read_level <> 'confidential')` (bei Feldern über die Art); insert/update `ad_has_level('AD','edit') or (ad_has_level('EA','manage') and read_level <> 'confidential')`. Kein Delete.

### ea_properties, ea_property_history (T36)
- Check `ea_properties_valid_range` (`valid_to >= valid_from`); Check genau eine Bezugsspalte passend zur Art (im Trigger, weil art-abhängig).
- Indizes `(person_id)`, `(property_type_id)`, `(related_referat_id) where related_referat_id is not null`, `(related_gremium_id) where related_gremium_id is not null`, `gin (field_values jsonb_path_ops)`.
- Trigger `ea_properties_validate` (before insert/update) nach research.md R-20; setzt `updated_*`. Trigger `ea_properties_history` (after update, security definer) schreibt die alte Fassung.
- Policies (T38) nach research.md R-22. „Beendet“ wird berechnet: `valid_to < current_date`.

### ad_templates, ad_template_assignments, ad_accesses, ad_test_login_domains, ad_audit_log (T3–T5, unverändert)
- Wie bisher umgesetzt (Migrationen `…0300`–`…0500`). `ad_audit_log` bekommt nur den Enum-Wert `referate_changed`.

### ad_notice_acks (T4 Teil, `…001400`)
- Policies auf die eigene Zeile (`user_id = auth.uid()`). FK `user_id` → `auth.users` on delete cascade.

## Views

- `ea_v_persons` (T2, unverändert): `security_invoker = true`, `where kind = 'human'`; welche Zeilen sichtbar sind, entscheidet die RLS auf `ea_persons`.
- `ad_v_person_overview` (T41): `security_invoker = true`; Spalten nach spec.md Abschnitt 2 (Person mit Rufname, Art, Login-Adresse, Zugangsstatus `coalesce(status,'none')`, Ehrenamtsstatus, `created_in`, Gruppenbezug `created_in = 'GR'` bis zur ersten GR-Migration, wirksame Vorlagen mit Referaten als Text). Lesen nur über die RLS der Basistabellen.

## Funktionen

| Funktion | Art | Grant | Migration |
|---|---|---|---|
| `ad_user_level`, `ad_has_level` | security definer, stable | authenticated | T1; `ad_user_level` neu in T33 (nur scope `all`) |
| `ad_my_referate(text, ad_level)`, `ad_has_any_level(text, ad_level)` | security definer, stable | authenticated | T33 |
| `ad_has_active_access()` | security definer, stable | authenticated | T34 |
| `ad_my_modules()` | security definer, stable | authenticated | T3; neu in T33 |
| `ad_assign_template(uuid, uuid, uuid[])`, `ad_set_assignment_referate(uuid, uuid[])`, `ad_revoke_template` | security definer | authenticated | T33 bzw. T3 |
| `ad_can_edit_qualification_types()` | security definer, stable | authenticated | T26 |
| `ad_qualification_usage(uuid)` | security definer, stable | authenticated | T41 (nach `ea_properties`) |
| `ea_save_property_type(jsonb, jsonb)` | security invoker | authenticated | T35 |
| `ea_person_in_referate`, `ea_person_visible_ad`, `ea_person_visible_ea`, `gr_person_visible`, `ea_person_visible`, `ea_property_readable`, `ea_property_writable` | security definer, stable | authenticated | T38 |
| `ea_set_volunteer_status`, `ea_person_referate`, `ea_create_volunteer(text, text, text, uuid, uuid, jsonb, date)`, `ea_activate_person` | security definer | authenticated | T39 |
| `ad_me()` | security definer, stable | authenticated | T6; neu in T41 (`drop` und neu, weil die Rückgabe wächst) |
| `ad_find_similar_persons(text, text, text)` | security definer, stable | authenticated | T43 |
| `ad_pending_emergency_logins()`, `ad_acknowledge_emergency()` | security definer | authenticated | T4 (`…001400`) |
| `ad_apply_invite`, `ad_revert_invite`, `ad_apply_email_change`, `ad_apply_lock`, `ad_apply_unlock` | security definer | service_role | T4 (`…001500`, `…001600`) |
| `ad_login_email_allowed(citext)` | security definer, stable | service_role | T5 |
| Trigger-Funktionen | security definer bzw. invoker | keiner | je Migration |

`ea_create_volunteer` im Kern: erlaubt mit `ad_has_level('EA','edit')` oder `p_referat = any(ad_my_referate('EA','edit'))`; mit Reichweite „alle“ sind `p_property_type` und `p_referat` optional, mit Reichweite Referat Pflicht; `created_in = 'EA'`. Die Erweiterung um EZ (`p_contact_email`, `created_in = 'EZ'`) folgt mit T53 per neuer Migration.

## Zustände

Zugang: unverändert nach spec.md Abschnitt 4 (Umsetzung über `ad-invite`, `ad-access`, Trigger auf `auth.users`, siehe research.md R-06, R-07). Ehrenamtsstatus: nur über `ea_set_volunteer_status`, `ea_create_volunteer`, `ea_activate_person`; jeder Wechsel schreibt `ea_volunteer_status_history`.

## Testdaten

Nach spec.md Abschnitt 9, Personen 1–12 (research.md R-10, R-26). Erwartete Sichtbarkeit im Kern (Grundlage der pgTAP-Tests T45):

| Testzugang | sieht Personen | sieht nicht |
|---|---|---|
| Admin | 1–12, alle Lesestufen | – |
| Geschäftsstelle | 4, 5, 9, 10, 11; Lesestufen „alle mit Zugriff“ und „nur Geschäftsstelle und Admin“ | 1–3, 6–8, 12; vertrauliche Eigenschaften |
| Referent:in (Klettern) | 4, 9, 10 (bei 10 auch die Funktion im Referat Ausbildung, nur lesen) | 5, 11, 12, alle ohne Ehrenamtsstatus; Geburtsdatum; vertrauliche Eigenschaften |
| Vorstand | niemanden | alle |
