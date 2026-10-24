---
description: "Tasks für das Modul Gruppen (GR)"
---

# Tasks: Gruppen (GR)

**Input**: [plan.md](plan.md) (Stand 24.10.2026), [spec.md](spec.md) v0.2 (führend), [02-stories.md](02-stories.md) v0.8, [01-erhebung.md](01-erhebung.md) v0.7, [uebergabe-administration.md](uebergabe-administration.md) v1.0, [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md), [Constitution](../../../.specify/memory/constitution.md) v1.2.0

**Voraussetzungen**: Kern der Administration und EA-Migrationen bis `20261024000700` auf `main` (plan.md „Voraussetzungen und Stand“). Ü1 und Ü3 der Übergabe setzt Gruppen vorgezogen um; Ü2 in der Oberfläche.

**Gesperrt**: T18 der Spec (Importskript) bis zur Entscheidung über **O1**. EZ-Pfade von `gr_group_roster` und `gr_groups_for_attendance` sind gebaut, ihre Tests stehen bis **O2** als pgTAP-`todo`.

**Tests**: Die Constitution verlangt test- und spec-getriebene Umsetzung mit pgTAP je Rechtevorlage. Vor jeder Migration steht eine Test-Task; die Tests müssen zuerst fehlschlagen. Dateien 410–495 (research.md R-GR-14). Für das Frontend gilt die Abnahme in TEST (quickstart.md D); für das Importskript Unit-Tests mit `node:test` über `tsx --test`.

**Organisation**: Phasen nach den Branches aus plan.md.

## Format: `- [ ] T### [P?] [US-GR-xx] (spec Tn) Beschreibung`

- **T###**: laufende Task-ID dieser Datei
- **[P]**: parallel ausführbar (andere Datei, keine offene Abhängigkeit)
- **[US-GR-xx]**: Story aus 02-stories.md
- **(spec Tn)**: Task-Nummer aus spec.md Abschnitt 10; „Teil“ = nur ein Teil davon

## Regeln für alle Tasks

- **Nie gegen PROD.** CLI-Befehle nur gegen vereins-os-test (vorher `npx supabase projects list` prüfen) oder gegen den lokalen Stack in der GitHub Action. Kein `supabase config push`, kein `supabase config diff`.
- **Bestehende Migrationen nicht ändern.** Neue Migrationen mit Präfix `20261025`, Dateiname `…_gr_*.sql` (data-model.md „Migrationen“). Objekte der Administration nur per `create or replace` bzw. `alter` in einer GR-Migration.
- Jede Migration: für jede neue Tabelle `enable row level security`, `revoke all … from public, anon, authenticated`, `grant select … to authenticated`, eine Select-Policy; **keine** Insert-/Update-/Delete-Grants oder -Policies auf `gr_`-Tabellen. Für jede Funktion `revoke all … from public, anon, authenticated` und Grant nach der Tabelle in data-model.md („Funktionen: Rechte und Grants“). Alle Funktionen `set search_path = ''` mit voll qualifizierten Namen (research.md R-GR-02).
- Schreibfunktionen: `security definer`, erste Anweisung Rechteprüfung (`GR_FORBIDDEN`), dann Fachprüfungen, dann Schreiben. Fehler `raise exception '<CODE>' using errcode = 'P0001'` (Platzhalter per `detail`). Codes nur aus [contracts/error-codes.md](contracts/error-codes.md).
- „heute“ in GR-Objekten immer `public.gr_today()` (research.md R-GR-03). Ein Zeitraum gilt am Datum D, wenn Beginn ≤ D und (Ende leer oder Ende ≥ D).
- Gesundheitsangaben nie in Views, Lesefunktionen, E-Mail-Listen, Berichten oder Logs (R11).
- Keine Echtdaten: Namen fiktiv, E-Mail nur `@example.test` (Testzugang `@dav-leipzig.de`), IBAN nur `DE89370400440532013000` und Varianten mit gültiger Prüfsumme. `.env.local` nie lesen, anzeigen oder ändern. Den Secret Key nie anfordern, speichern oder verwenden.
- Fachliche Dateien (spec.md, 02-stories.md, uebergabe-*.md usw.) nicht ändern; Widersprüche als `[OFFEN]` melden.
- Commits deutsch, auf dem Branch der Phase. Pull Requests legt Claude Code an (Stories, Tasks, Cloudflare-Vorschau-URL). Auto-Merge nur für PRs mit ausschließlich Migrationen, Tests, Seed und Umsetzungsdateien (CLAUDE.md).
- Oberfläche: deutsch, „du“, Datum `TT.MM.JJJJ` über `formatDate()`, Namen über `personName()` (`src/lib/format.ts`), Fehler über `toMessage()` (`src/lib/errors.ts`), Tabellen über `ResponsiveTable`, ab 375 px ohne horizontales Scrollen, Trefferflächen ≥ 44 px.

---

## Phase 1: Plan (Branch `gr-plan`)

- [x] T001 plan.md, research.md, data-model.md, contracts/ (database-api.md, error-codes.md, routes.md, import-script.md), quickstart.md und tasks.md in `docs/specs/gr-gruppen/` anlegen; GR-Abschnitt in `docs/specs/ad-administration/contracts/error-codes.md` auf die GR-Datei verweisen lassen.

---

## Phase 2: Datenbank-Grundlage (Branch `gr-kern-datenbank`) – US-GR-01, 03, 04, 06–13, 17, 18

**Ziel**: Tabellen, Sichtbarkeit, Schreibfunktionen, Seed. Grundlage aller Oberflächen.

**Unabhängiger Test**: Action `db-tests.yml` grün mit allen Tests der Administration (010–240), des Ehrenamtsmanagements (310–390) und den neuen Tests 410–470.

### Vorbereitung

- [x] T002 Branch `gr-kern-datenbank` von aktuellem `main` anlegen. Prüfen und im PR festhalten, dass vorhanden sind: `gr_person_visible` (Platzhalter), `gr_person_ids`, `ea_property_writable(uuid, uuid, uuid)`, `ea_properties_validate`, `ea_properties_history`, `ad_v_person_overview`, `ea_iban_valid`, `ea_iban_normalize`, `ad_first_names_match`, System-Eigenschaftsarten `birth_date`, `contact`, `member`; Referat „Kinder und Jugend“ in `ea_referate`; letzte Migration `20261024000700`. Fehlt etwas: anhalten und melden.

### Tests (zuerst schreiben, müssen fehlschlagen) ⚠️

- [x] T003 [P] [US-GR-03] (spec T10 Teil) `supabase/tests/database/410_gr_groups.test.sql`:
  - Tabellen `gr_groups`, `gr_training_times` mit RLS, `has_table_privilege('authenticated', …, 'INSERT')` = false für beide;
  - `gr_today()` = `(now() at time zone 'Europe/Berlin')::date`;
  - `gr_save_group` als Geschäftsstelle: anlegen, ändern; Name leer → `GR_GROUP_FIELDS_REQUIRED`; „jugendgruppe test 1“ → `GR_GROUP_NAME_TAKEN`; Name einer aufgelösten Gruppe erlaubt; inaktives Referat → `GR_REFERAT_INACTIVE`; Admin (GR lesen) → `GR_FORBIDDEN`; Änderung an „Altgruppe Test“ → `GR_GROUP_DISSOLVED`;
  - `gr_dissolve_group`: Test 1 → `GR_GROUP_HAS_MEMBERS`; Test 2 (Paula offen) nach Beenden der Teilnahmen → `GR_GROUP_HAS_PENDING`; Datum morgen → `GR_DATE_IN_FUTURE`; leere Gruppe → `dissolved_on` gesetzt, offene Trainingszeiten und `group_function` mit `valid_from <= Datum` enden zum Datum, später beginnende bleiben und stehen in der Rückgabe (A12, plan.md H5);
  - Trainingszeiten: fehlende Felder → `GR_TRAINING_TIME_REQUIRED`; Ende ≤ Beginn → `GR_TRAINING_TIME_END`; „gültig bis“ < „gültig von“ → `GR_VALID_TO_BEFORE_FROM`; Überschneidung Di 17:00–18:00 in Test 1 → `overlap = true`, gespeichert; `gr_change_training_time` mit Datum ≤ `valid_from` bzw. > `valid_to` → `GR_CHANGE_DATE_INVALID`; gültiges „Ändern ab“ → alte endet am Vortag, neue beginnt am Datum mit altem `valid_to`; direktes `update … set weekday` als Eigentümer → `GR_TRAINING_TIME_LOCKED`; `gr_end_training_time` setzt und ändert `valid_to`.
- [x] T004 [P] [US-GR-01] (spec T10 Teil) `supabase/tests/database/420_gr_visibility.test.sql` – Tabelle „Erwartete Ergebnisse“ spec.md 9 je Testzugang:
  - Admin: sieht Kinder 23, 25, 28, 30 und 27 (Pfad AD), Geburtsdatum Kind ja, `gr_health_notes`/`gr_health_note_history`/`gr_health_consents` 0 Zeilen;
  - Geschäftsstelle: sieht 23, 25, 28, 30, nicht 27; Geburtsdatum ja; Gesundheit 23 ja, 25 nein (Widerruf);
  - Rita Referentin, Kim Kinderjugend, Vorstand: keine Zeile aus `gr_memberships`, `gr_guardians`, `gr_emergency_contacts`, `gr_contracts`, `gr_photo_consents`, `gr_pending_admissions`, `gr_training_times`; Kinder nicht in `ea_persons`;
  - Vorstand mit GR lesen (Zuweisung in der Testtransaktion): sieht Kinder, kein Geburtsdatum (`ea_properties` Art `birth_date` 0 Zeilen), keine Gesundheit (`gr_v_memberships.birth_date` null prüft T020);
  - `gr_person_ids('read')` = Menge der Personen mit `gr_person_visible` für alle Seed-Personen (research.md R-GR-06);
  - Person mit nur beendeten Bezügen (27, 31) nur für den Admin sichtbar (Ü4);
  - Teilnehmer:in nicht über EA lesbar (23 für Geschäftsstelle nur über Pfad GR: `ea_person_visible_ea` = false); Erziehungsberechtigter zugleich Trainer (26) im Pfad EA ohne gruppenspezifische Daten (keine Zeile aus `gr_guardians` über EA-Recht allein); nur „Gruppen lesen“ liest Kontaktdaten, nicht Geburtsdatum (Tests aus AD T45).
- [x] T005 [P] [US-GR-06] (spec T10 Teil) `supabase/tests/database/430_gr_admission.test.sql`:
  - `gr_start_admission` neue Person als Geschäftsstelle → `ea_persons.created_in = 'GR'`, Eigenschaften `birth_date` (`valid_from` = Geburtsdatum), `contact` (`valid_from` = heute), `member` nur mit Nummer; ohne Geburtsdatum/Adresse → `GR_PARTICIPANT_FIELDS_REQUIRED`; beide Parameter bzw. keiner → `GR_PERSON_INVALID`; zweite offene Aufnahme → `GR_PENDING_EXISTS`; Person mit laufender Teilnahme an derselben Gruppe → `GR_ALREADY_MEMBER`; aufgelöste Gruppe → `GR_GROUP_DISSOLVED`;
  - mit GR bearbeiten (Testvorlage in der Transaktion) neue Person mit Geburtsdatum → `GR_BIRTH_DATE_FORBIDDEN`;
  - Übernahme einer nicht sichtbaren Person (Person 12 ohne Bezug) mit GR bearbeiten → danach im Pfad GR sichtbar (Ü2); Person `kind = 'function'` → `GR_PERSON_INVALID`;
  - `gr_cancel_admission` löscht die Zeile; Erziehungsberechtigte bleiben zugeordnet; Kind danach nur für Admin sichtbar;
  - `gr_add_guardian`: neue Person ohne Adresse → `GR_GUARDIAN_FIELDS_REQUIRED`; dritte → `GR_GUARDIAN_LIMIT`; doppelt → `GR_GUARDIAN_EXISTS`; `gr_remove_guardian` Jana (Vertragsinhaberin) → `GR_GUARDIAN_IS_HOLDER`;
  - `gr_copy_address` kopiert Straße, PLZ, Ort in `contact` des Kindes (Historie in `ea_property_history`);
  - `gr_add_emergency_contact`: ohne Telefon/E-Mail → `GR_CONTACT_REACHABILITY`; doppelt → `GR_EMERGENCY_EXISTS`; `sort_order` = höchste + 1; `gr_reorder_emergency_contacts` mit unvollständiger Liste → `GR_ORDER_INVALID`, vollständig → 1…n;
  - `gr_update_person`: Mitgliedsnummer leeren → `member` endet zum Vortag (R25); Notfallkontakt ohne Erreichbarkeit → `GR_CONTACT_REACHABILITY`; ohne Pfad-GR-Sichtbarkeit → `GR_FORBIDDEN`.
- [x] T006 [P] [US-GR-08] (spec T10 Teil) `supabase/tests/database/440_gr_membership_contract.test.sql`:
  - `gr_admit` legt Teilnahme und Vertrag an und löscht die offene Aufnahme; ohne Vertrag → `GR_CONTRACT_REQUIRED`; fehlendes Vertragsfeld → `GR_CONTRACT_FIELDS_REQUIRED`; nichts gespeichert bei Fehler;
  - R4: Inhaber:in nicht erziehungsberechtigt → `GR_HOLDER_INVALID`; volljährige Teilnehmer:in (am Vertragsbeginn) als eigene Inhaber:in erlaubt;
  - R5 `DE00 1234` → `GR_IBAN_INVALID`; IBAN wird normalisiert gespeichert; R6 Mandatsreferenz in anderer Schreibweise vorhanden → `GR_MANDATE_TAKEN`; „ABC#1“ → `GR_MANDATE_FORMAT`; 36 Zeichen → `GR_MANDATE_FORMAT`; Kontoinhaber:in 71 Zeichen → `GR_TEXT_TOO_LONG` mit `detail` 70; Verwendungszweck 141 → `GR_TEXT_TOO_LONG` (140); Betrag 0 → `GR_AMOUNT_INVALID`; Unterschriftsdatum morgen → `GR_DATE_IN_FUTURE`;
  - Kind in Gruppe A ohne offene Aufnahme in Gruppe B aufnehmen (US-GR-08 AK4); laufende Teilnahme an derselben Gruppe → `GR_ALREADY_MEMBER`;
  - `gr_add_contract` bei Vertrag ohne Ende → `GR_CONTRACT_EXISTS`; Beginn ≤ größtes Vertragsende → `GR_CONTRACT_EXISTS`; danach erlaubt (R8a);
  - `gr_cancel_contract`: Ende vor Beginn → `GR_CONTRACT_END_BEFORE_START`; mit `p_end_membership` → `left_on` = Vertragsende; ohne → Teilnahme unverändert (R8b);
  - `gr_contract_status`: offen → `active`; Ende ≥ D → `cancelled`; Ende < D → `ended`;
  - `gr_end_membership` vor Eintritt → `GR_LEFT_BEFORE_JOINED`; Vertrag bleibt unverändert;
  - `gr_update_contract` ändert nur die erlaubten Felder; Vertragsbeginn bleibt.
- [x] T007 [P] [US-GR-12] (spec T10 Teil) `supabase/tests/database/450_gr_consents_health.test.sql`:
  - Fotoerlaubnis ohne Eintrag = nein; `gr_set_photo_consent` ohne Datum → `GR_CONSENT_DATE_REQUIRED`; Zukunft → `GR_DATE_IN_FUTURE`; gleicher Wert → `GR_CONSENT_UNCHANGED`; Historie bleibt (zwei Zeilen);
  - `gr_save_health_note` ohne Einwilligung → `GR_HEALTH_CONSENT_REQUIRED`; mit „ja“ speichern; Änderung erzeugt Zeile in `gr_health_note_history`; 2001 Zeichen bzw. leer → `GR_HEALTH_NOTE_INVALID`;
  - Widerruf „nein“: Text und Historie bleiben (als Eigentümer zählen), Geschäftsstelle liest 0 Zeilen; erneut „ja“ → wieder lesbar (R24);
  - Admin, Vorstand mit GR lesen, Rita, Kim: `gr_save_health_note` → `GR_FORBIDDEN`; 0 Zeilen aus allen drei Gesundheitstabellen (R11).
- [x] T008 [P] [US-GR-13] (spec T10 Teil) `supabase/tests/database/460_gr_group_functions.test.sql`:
  - `ea_set_status_from_group` ist für `authenticated` nicht ausführbar (`has_function_privilege` = false);
  - `gr_add_group_function` neue Person → Status `active` seit „seit“, Zeile in `ea_volunteer_status_history`, `status_set = true`; Person ruhend → Status unverändert, `status_hint = 'dormant'`; ausgeschieden → `'left'` (R29);
  - gleiche Funktion, gleiche Person, gleiche Gruppe, überschneidend → `GR_FUNCTION_OVERLAP`; andere Funktion gleichzeitig erlaubt (R28); „bis“ vor „seit“ → `EA_VALID_RANGE`; aufgelöste Gruppe → `GR_GROUP_DISSOLVED`; Funktion außerhalb der Auswahl → `EA_FIELD_CHOICE`;
  - `gr_end_group_function` nur für Art `group_function` (andere Eigenschaft → `GR_FORBIDDEN`), Status bleibt;
  - Person 26 erscheint für die Geschäftsstelle im Ehrenamtsmanagement mit Eigenschaft `group_function` „Trainer:in“ und lesbarem `gr_groups.name`; direktes `update` dieser Eigenschaft als Geschäftsstelle scheitert (R14).
- [x] T009 [P] [US-GR-01] (spec T10 Teil) `supabase/tests/database/470_gr_admin_objects.test.sql`:
  - `ea_properties.related_group_id` FK auf `gr_groups`; Art `group_function` mit Werten aus spec.md 2.2 (`category = 'assignment'`, `read_level = 'all'`, `relation_kind = 'group'`, `relation_required`, `allow_multiple`, `visible_in = {AD,EA,GR}`, `origin = 'system'`, Feld `function` choice mit `{Gruppenleitung,Trainer:in,Helfer:in}`, Pflicht);
  - Trigger R38: Art `group_function` ohne `related_group_id` (als Eigentümer) → `EA_RELATION_REQUIRED`; aufgelöste Gruppe mit `valid_from` nach `dissolved_on` → `GR_GROUP_DISSOLVED`; bei Art mit Bezug Referat wird `related_group_id` auf null gesetzt;
  - Historie schreibt `related_group_id` mit;
  - R39/Ü7: `ea_property_writable(<group_function>, …)` = false für Admin und Geschäftsstelle; direkter Insert der Geschäftsstelle → SQLSTATE `42501`; Admin → `EA_GROUP_RELATION_ONLY_GR` (Test 130 bleibt grün);
  - Ü3: `ad_v_person_overview.has_group_relation` für den Admin true bei 23, 24, 26, 29, 30, false bei 27 und 31 und bei Personen 1–12; `gr_person_has_group_relation` für die Geschäftsstelle null;
  - `gr_has_current_relation`, `gr_is_adult` für `authenticated` nicht ausführbar.

### Migrationen

- [x] T010 [US-GR-03] (spec T1) `supabase/migrations/20261025000100_gr_groups.sql` nach data-model.md Nr. 1 und spec.md 2.1/2.2:
  - `gr_today()`;
  - `gr_groups` („name text, getrimmt, 1–80 Zeichen“; `referat_id` FK `ea_referate(id) on delete restrict`; `dissolved_on date`; Audit); unique `(lower(name)) where dissolved_on is null`; Index `(referat_id)`; Trigger `ad_set_updated`;
  - `gr_training_times` (Check `weekday between 1 and 7`, `ends_at > starts_at`, `valid_to is null or valid_to >= valid_from`; Index `(group_id, weekday)`), Trigger `gr_training_times_guard` (`GR_TRAINING_TIME_LOCKED`) und `ad_set_updated`;
  - RLS: `gr_groups` select `ad_has_level('GR','read') or ad_has_any_level('EA','read')`; `gr_training_times` select `ad_has_level('GR','read')`;
  - `ea_properties.related_group_id`, `ea_property_history.related_group_id`, Teilindex; neue Fassungen `ea_properties_validate`, `ea_properties_history`, `ea_property_writable` (research.md R-GR-07);
  - Art `group_function` mit Feld über eine interne Funktion ohne Nutzerkontext, idempotent `on conflict (system_key) do nothing` (Muster `ea_seed_system_property_types`).
- [x] T011 [US-GR-01] (spec T2) `supabase/migrations/20261025000200_gr_relations.sql` nach data-model.md Nr. 2:
  - Tabellen `gr_pending_admissions`, `gr_memberships` (Check `left_on >= joined_on`), `gr_contracts` (Checks: `ends_on >= starts_on`; `ends_on is null or cancelled_on is not null`; `monthly_amount > 0`; `char_length(account_holder) between 1 and 70`; `mandate_reference ~ '^[A-Za-z0-9+?/:().,'' -]{1,35}$'`; `char_length(purpose) between 1 and 140`; unique `lower(mandate_reference)`), `gr_guardians` (Check Kind ≠ Person, unique; Trigger höchstens zwei → `GR_GUARDIAN_LIMIT`), `gr_emergency_contacts`, `gr_photo_consents`, `gr_health_consents`, `gr_health_notes` (Check 1–2000 Zeichen), `gr_health_note_history` mit Trigger `gr_health_notes_history` (after update);
  - Funktionen `gr_has_current_relation`, `gr_person_visible` (Ersatz), `gr_person_ids` (Ersatz, mengenbasiert), `gr_row_visible`, `gr_is_adult`, `gr_can_read_health`, `gr_contract_status`, `gr_needs_guardian`, `gr_person_has_group_relation`;
  - neue Fassung `ad_v_person_overview` (gleiche Spalten, `has_group_relation` über `gr_person_has_group_relation`);
  - Select-Policies nach data-model.md „Tabellen“.
- [ ] T012 [P] (spec T2 Teil) `docs/specs/gr-gruppen/contracts/error-codes.md`: Status je Code auf „umgesetzt“ setzen, sobald die Migration ihn auslöst (laufend mit T010–T016).
- [x] T013 [US-GR-03] (spec T3) `supabase/migrations/20261025000300_gr_group_functions.sql`: `gr_save_group`, `gr_dissolve_group` (Rückgabe jsonb, plan.md H5), `gr_add_training_time`, `gr_change_training_time`, `gr_end_training_time` nach contracts/database-api.md.
- [x] T014 [US-GR-06] (spec T4) `supabase/migrations/20261025000400_gr_person_functions.sql`: interne `gr_create_person(p_new_person jsonb, p_require text)` und `gr_take_person(p_person uuid)`; `gr_start_admission`, `gr_cancel_admission`, `gr_update_person`, `gr_copy_address`, `gr_add_guardian`, `gr_remove_guardian`, `gr_add_emergency_contact`, `gr_remove_emergency_contact`, `gr_reorder_emergency_contacts`. Kontaktdaten nur anlegen, wenn mindestens ein Kontaktfeld gesetzt ist; eine `contact`-Eigenschaft je Person, Änderungen als Update.
- [x] T015 [US-GR-08] (spec T5) `supabase/migrations/20261025000500_gr_membership_contract.sql`: interne `gr_check_contract(p_membership uuid, p_person uuid, p_contract jsonb)` (R4–R6, R27; IBAN über `ea_iban_normalize`/`ea_iban_valid`); `gr_admit`, `gr_add_contract`, `gr_update_contract`, `gr_cancel_contract`, `gr_end_membership`.
- [x] T016 [US-GR-12] (spec T6) `supabase/migrations/20261025000600_gr_consents_health.sql`: `gr_set_photo_consent`, `gr_set_health_consent`, `gr_save_health_note` (Insert oder Update).
- [x] T017 [US-GR-13] (spec T7) `supabase/migrations/20261025000700_gr_volunteer_functions.sql`: Ü1 `ea_set_status_from_group` (Kennzeichen `ea.status_change`, research.md R-GR-04, ohne Grant); `gr_add_group_function`, `gr_end_group_function` (R28 per `daterange(…,'[]') &&`).

### Seed

- [x] T018 [US-GR-17] (spec T9) `supabase/seed.sql` nach spec.md 9 und research.md R-GR-15:
  - Gruppen `c0000000-…-000000000001`–`…04`: „Jugendgruppe Test 1“ (Kinder und Jugend; Di 16:30–18:00, Do 17:00–18:30 seit 01.09.2025), „Jugendgruppe Test 2“ (Mi 17:00–18:30 bis 31.12.2025, Mi 18:00–19:30 seit 01.01.2026), „Klettergruppe Test“ (Klettern, ohne Trainingszeit), „Altgruppe Test“ (aufgelöst 30.06.2025);
  - Personen 23–32 mit allen Besonderheiten der Tabelle in spec.md 9 (Daten relativ zu `current_date`), Gesundheitsangabe 25 mit Einwilligung „ja“, danach „nein“;
  - Testzugang Kim Kinderjugend `test.kiju@dav-leipzig.de` (Person 32, Auth-Nutzer `b0000000-0000-4000-8000-000000000032`), Vorlage Referent:in mit Referat Kinder und Jugend, Amt Referent:in K+J;
  - Kopfkommentar um Personen 23–32 und Gruppen ergänzen; Personen 1–22 unverändert;
  - `supabase/tests/database/200_seed.test.sql` um Zähler für Personen 23–32 und Gruppen erweitern.
- [ ] T019 Personendaten-Prüfung nach CLAUDE.md über `docs`, `supabase/seed.sql`; PR `gr-kern-datenbank` mit Stories, Spec-Tasks T1–T7, T9, T10 (Teil) und Hinweis auf Ü1/Ü3; Auto-Merge nach grünen Checks.

---

## Phase 3: Lesefunktionen (Branch `us-gr-19-lesefunktionen`) – US-GR-02, 05, 15, 19, 20

**Ziel**: Views und Funktionen für Oberfläche und Anwesenheitserfassung.

**Unabhängiger Test**: pgTAP 480 und 490 grün; EZ-Pfade als `todo` (O2).

- [ ] T020 [P] [US-GR-19] (spec T10 Teil) `supabase/tests/database/480_gr_read_functions.test.sql`:
  - `gr_v_memberships`: Spaltenliste exakt nach contracts/database-api.md; Ben (25) `needs_clarification = true`, `clarify_since` = Vertragsende, `has_emergency_contact = false`; Paula erscheint nicht (keine Teilnahme), aber in `gr_v_pending_admissions` mit `needs_guardian = true`;
  - `gr_group_overview()`: Zeilen ohne „Altgruppe Test“, mit `true` inklusive; `training_times_today` je nach Wochentag von `gr_today()`; Zähler aktiv, klären, kein Notfallkontakt, offen;
  - `gr_guardian_emails(Test 1)`: Janas Adresse genau einmal; Vorstand → `GR_FORBIDDEN`; volljährige Teilnehmer:in mit eigener Adresse (R13);
  - `gr_group_roster`: Schlüssel exakt `group`, `training_times`, `persons` und je Person `person_id`, `first_name`, `preferred_name`, `last_name`, `role` (R20); Test 1 vor 40 Tagen enthält 27; Test 2 vor 90 Tagen enthält 31 als `trainer`; 28 in Test 1 `helper`, in Test 2 `participant`; Altgruppe heute → `GR_GROUP_NOT_FOUND`; Test 2 an einem Mittwoch 2025 17:00–18:30, 2026 18:00–19:30; Vorstand → `GR_ROSTER_FORBIDDEN` (auch bei unbekannter Gruppe); leere Listen statt Fehler bei Klettergruppe;
  - `gr_groups_for_attendance`: mit GR lesen alle nicht aufgelösten Gruppen, sortiert; Vorstand leer;
  - `gr_my_groups` für Person 26 (per `set_config('request.jwt.claims', …)`): Test 1, `trainer`, `{2,4}`;
  - `todo` (O2): Rita → Klettergruppe Liste, Test 1 `GR_ROSTER_FORBIDDEN`; Kim → umgekehrt; Admin mit EZ lesen → beide; `gr_groups_for_attendance` je Referat.
- [ ] T021 [P] [US-GR-01] (spec T10 Teil) `supabase/tests/database/490_gr_volume.test.sql`: in der Transaktion 20 Gruppen, 400 Teilnehmer:innen mit Vertrag, Erziehungsberechtigten und Notfallkontakt; Laufzeit per `clock_timestamp()`: `gr_group_overview` < 1 s, `gr_v_memberships` einer Gruppe < 1 s, `gr_group_roster` < 300 ms, `select … from ea_persons` als Geschäftsstelle (≥ 500 Personen) < 1 s.
- [ ] T022 [US-GR-19] (spec T8) `supabase/migrations/20261025000800_gr_read_functions.sql`: `gr_v_memberships`, `gr_v_pending_admissions` (beide `security_invoker = true`), `gr_group_overview`, `gr_guardian_emails`, `gr_group_roster`, `gr_groups_for_attendance`, `gr_my_groups` nach contracts/database-api.md; EZ-Prüfungen nach research.md R-GR-11.
- [ ] T023 PR `us-gr-19-lesefunktionen` (Spec-Tasks T8, T10 Teil; Hinweis auf O2); Auto-Merge nach grünen Checks.

---

## Phase 4: Übersicht und Navigation (Branch `us-gr-02-uebersicht`) – US-GR-02

**Ziel**: /gr mit Routenschutz. **Unabhängiger Test**: quickstart.md D 1, 2.

- [ ] T024 [US-GR-02] (spec T11) `src/features/gr/access.ts` (Rechte aus `ad_my_modules()` bzw. `ad_has_level` für read/edit/manage), `src/features/gr/GrLayout.tsx` (Navigation „Gruppen · Aufnahmen offen“), `src/features/gr/routes.tsx`; Einbindung in `src/App.tsx`; ohne GR lesen → /kein-zugriff vor jeder Abfrage (contracts/routes.md).
- [ ] T025 [US-GR-02] (spec T11) `src/features/gr/gruppen/GruppenPage.tsx`: `gr_group_overview`, Suche Namensteil, Filter Referat und „aufgelöst“ (URL-Parameter), Hinweiszähler, Leerzustand „Keine Gruppen gefunden.“, Karten ab 375 px; Knopf „Gruppe anlegen“ nur mit edit.
- [ ] T026 [P] [US-GR-02] `src/lib/errors.ts`: alle GR-Codes aus contracts/error-codes.md mit Meldungen; `src/lib/format.ts`: `formatWeekday()`, `formatTime()` (`HH:MM`), `ageFromBirthDate()`.
- [ ] T027 PR `us-gr-02-uebersicht` mit Vorschau-URL; Merge durch den Product Owner.

---

## Phase 5: Gruppe pflegen (Branch `us-gr-03-gruppe`) – US-GR-03, 04, 18

**Unabhängiger Test**: quickstart.md D 3.

- [ ] T028 [US-GR-03] (spec T12) `src/features/gr/gruppen/GruppeFormDialog.tsx` und Route /gr/gruppen/neu: Name, Referat (nur aktive), optional erste Trainingszeit; `gr_save_group`, `gr_add_training_time`; Meldungen R1, R21.
- [ ] T029 [US-GR-18] (spec T12) `src/features/gr/gruppen/TrainingszeitDialog.tsx`: Hinzufügen, „Ändern ab“, Beenden; Hinweis bei `overlap`; Kernfelder nach dem Speichern nicht editierbar (A13).
- [ ] T030 [US-GR-04] (spec T12) `src/features/gr/gruppen/AufloesenDialog.tsx`: Datum (≤ heute), Bestätigung, Anzeige der Rückgabeliste „beginnt nach Auflösung“, Meldungen R9.
- [ ] T031 PR `us-gr-03-gruppe`; Merge durch den Product Owner.

---

## Phase 6: Gruppendetail (Branch `us-gr-05-gruppendetail`) – US-GR-05, 15

**Unabhängiger Test**: quickstart.md D 4.

- [ ] T032 [US-GR-05] (spec T13) `src/features/gr/gruppen/GruppeDetailPage.tsx`: Kopf (Name, Referat, heutige Trainingszeiten, Betreuung); Reiter Teilnehmer:innen (`gr_v_memberships`; Alter nur bei gelesenem Geburtsdatum; Filter alle / „Teilnahme klären“ / „beendet“ nur Admin; Hinweise R2, R7, R17), Betreuung (lesend, Pflege in T038), Trainingszeiten (gültige, künftige „ab TT.MM.JJJJ“, frühere aufklappbar); aufgelöste Gruppe nur lesend; Leerzustände nach spec.md 6.
- [ ] T033 [US-GR-15] (spec T13) `src/features/gr/gruppen/EmailListeButton.tsx`: `gr_guardian_emails`, mit „; “ verbinden, Zwischenablage, Meldung „N Adressen kopiert. Bitte in Blindkopie (BCC) einfügen.“ bzw. „Keine E-Mail-Adressen vorhanden.“
- [ ] T034 PR `us-gr-05-gruppendetail`; Merge durch den Product Owner.

---

## Phase 7: Aufnahme (Branch `us-gr-06-aufnahme`) – US-GR-06–10, 12

**Unabhängiger Test**: quickstart.md D 5.

- [ ] T035 [US-GR-06] (spec T14) `src/features/gr/aufnahme/AufnahmeAssistent.tsx` (Route /gr/gruppen/:id/aufnehmen), fünf Schritte, jeder speichert sofort: 1. Suche über `ea_v_persons` oder neu, Dublettenprüfung `ad_find_similar_persons`, `DublettenDialog` mit `hitAction` „Vorhandene Person übernehmen“ für alle Treffer inkl. `is_visible = false` ab edit (Ü2) → `gr_start_admission`; 2. Erziehungsberechtigte (`gr_add_guardian`, „Adresse übernehmen“ → `gr_copy_address`); 3. Notfallkontakte; 4. Fotoerlaubnis, Einwilligung, Gesundheit (nur edit, Hinweistext spec.md 6); 5. Teilnahme und Vertrag (`gr_admit`). Bei laufender Teilnahme in anderer Gruppe direkt Schritt 5. Neue Person nur mit manage.
- [ ] T036 [US-GR-06] (spec T14) `src/features/gr/aufnahme/AufnahmenPage.tsx` (/gr/aufnahmen): `gr_v_pending_admissions`, „Aufnahme fortsetzen“, „Aufnahme abbrechen“ mit Bestätigung „Die Person wird aus Gruppen entfernt. Ihre Daten bleiben gespeichert.“, Leerzustand „Keine offenen Aufnahmen.“
- [ ] T037 PR `us-gr-06-aufnahme`; Merge durch den Product Owner.

---

## Phase 8: Personendetail (Branch `us-gr-14-person`) – US-GR-07–12, 14

**Unabhängiger Test**: quickstart.md D 6, 7, 9.

- [ ] T038 [US-GR-14] (spec T15) `src/features/gr/personen/PersonPage.tsx` (/gr/personen/:id): Notfallkontakte oben (Reihenfolge, `tel:`/`mailto:`; ohne Kontakt Hinweis und Erziehungsberechtigte mit Kontakt), Stammdaten (Geburtsdatum/Alter nur bei Recht), Erziehungsberechtigte, Teilnahmen mit Verträgen und Historie, Fotoerlaubnis mit Historie; Variante für Erziehungsberechtigte, Notfallkontakte, Betreuer:innen („erziehungsberechtigt für …“, „Notfallkontakt für …“, Funktionen).
- [ ] T039 [US-GR-11] (spec T15) Abschnitte Vertrag kündigen (Rückfrage R8b), Folgevertrag, Teilnahme beenden, Vertrag ändern in `src/features/gr/personen/VertragDialog.tsx`.
- [ ] T040 [US-GR-12] (spec T15) `src/features/gr/personen/GesundheitAbschnitt.tsx`: nur edit; Einwilligung mit Historie, Text, Historie aufklappbar; Meldungen R24.
- [ ] T041 [US-GR-07] (spec T15) Pflege Stammdaten (`gr_update_person`), Erziehungsberechtigte und Notfallkontakte hinzufügen, entfernen, sortieren.
- [ ] T042 PR `us-gr-14-person`; Merge durch den Product Owner.

---

## Phase 9: Betreuung (Branch `us-gr-13-betreuung`) – US-GR-13

**Unabhängiger Test**: quickstart.md D 8.

- [ ] T043 [US-GR-13] (spec T16) `src/features/gr/gruppen/FunktionDialog.tsx` im Reiter Betreuung: Funktion hinzufügen (vorhandene oder neue Person), beenden; Statushinweis aus `status_hint` bzw. Meldung „aktiv gesetzt“.
- [ ] T044 [US-GR-13] (spec T17) Ehrenamtsmanagement: Eigenschaften `group_function` in /ea/aktive/:id nur lesend mit Gruppenname und Text „Diese Angabe wird im Modul Gruppen gepflegt.“; mit Seed in der Vorschau prüfen.
- [ ] T045 PR `us-gr-13-betreuung`; Merge durch den Product Owner.

---

## Phase 10: Import (Branch `us-gr-16-import`) – US-GR-16 ⛔ gesperrt bis O1

- [ ] T046 [P] [US-GR-16] (spec T10 Teil) `supabase/tests/database/495_gr_import.test.sql`: `authenticated` kann `gr_import_groups` nicht ausführen; Probelauf schreibt nichts; Fehler (fehlende Pflichtfelder, ohne Vertrag, ungültige IBAN, doppelte Mandatsreferenz, unbekanntes Referat) blockieren; gleiche Person in zwei Blättern → eine Person, zwei Teilnahmen; `created_in = 'script'`.
- [ ] T047 [US-GR-16] (spec T18) `supabase/migrations/20261025000900_gr_import.sql`: `gr_import_groups` nach contracts/import-script.md, Grant nur `service_role`.
- [ ] T048 [US-GR-16] (spec T18) `scripts/gr-import/` nach contracts/import-script.md (Schlüsseleingabe nach Entscheidung O1); `package.json` Scripts `gr:import`, `gr:import:test`, devDependency `exceljs`; `.gitignore`; `beispiel.xlsx` mit Erzeugungsskript; Unit-Tests für Trainingszeit-Muster, Namensteilung, Telefonzuordnung, Bericht (IBAN gekürzt, keine Gesundheitsangaben).
- [ ] T049 PR `us-gr-16-import`; Merge durch den Product Owner. Probelauf gegen TEST macht der Admin.

---

## Phase 11: Abnahme und Freischalten

- [ ] T050 (Branch `gr-abnahme`) Abnahme in TEST nach quickstart.md D 1–12 mit Admin, Geschäftsstelle, Vorstand, Rita, Kim, auch bei 375 px; Ergebnis in `docs/specs/gr-gruppen/abnahme-test.md`; Anpassungen aus der Abnahme.
- [ ] T051 [P] Querschnitt: `npm run lint`, `npm run build` ohne Fehler; Personendaten-Prüfung nach CLAUDE.md über `docs`, `scripts`, `supabase/seed.sql`.
- [ ] T052 [US-GR-02] (spec T19, Branch `gr-freischalten`) Migration `…_gr_module_available.sql`: `update public.ad_modules set is_available = true where code = 'GR'`; Test in `supabase/tests/database/` ergänzen; nur nach Freigabe des Product Owners.

---

## Abhängigkeiten

- Phase 2 → Phase 3 → Phase 4 → Phasen 5 und 6 → Phasen 7, 8, 9 → Phase 11.
- Phase 10 nach Phase 2, sobald O1 entschieden ist.
- Innerhalb Phase 2: Tests T003–T009 zuerst (parallel); dann T010 → T011 → T013–T017 (in Nummernfolge, je Migration); T018 nach T011; T012 laufend.
- Nach O2 (Variante a oder Umsetzung AD v0.8): `todo`-Tests in T020 scharf schalten, Seed um EZ-Rechte von Admin, Rita und Kim ergänzen.

## Parallel ausführbar

- T003–T009 (je eigene Testdatei).
- T020 und T021.
- T026 parallel zu T024/T025.
- Phasen 5 und 6 nach Phase 4; Phasen 7, 8, 9 nach Phase 6.

## Umsetzungsstrategie

1. **MVP Datenbank:** Phase 2 und 3. Danach sind alle Regeln, Rechte und Lesefunktionen in CI geprüft; die Anwesenheitserfassung kann gegen die Funktionen planen.
2. **MVP Oberfläche:** Phasen 4–8 (Übersicht, Gruppe, Detail, Aufnahme, Person mit Notfallansicht). Damit ist die Excel fachlich ersetzbar.
3. **Ergänzungen:** Phase 9 (Betreuung), Phase 10 (Import nach O1).
4. **Abschluss:** Abnahme und Freischalten (Phase 11).
