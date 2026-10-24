---
description: "Tasks für das Modul Anwesenheitserfassung (EZ)"
---

# Tasks: Anwesenheitserfassung (EZ)

**Input**: [plan.md](plan.md) (Stand 24.10.2026), [spec.md](spec.md) v0.5 (führend), [02-stories.md](02-stories.md) v0.6, [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md), [Constitution](../../../.specify/memory/constitution.md) v1.2.0

**Voraussetzungen**: AD Nachtrag v0.8.2 (Datenbank) und Gruppen bis v0.3.1 auf `main` (plan.md „Voraussetzungen und Stand“). Für die Oberfläche fehlen die Komponenten aus AD T120 (plan.md O2); für die Abnahme AD T120 und T121.

**Zurückgestellt**: Spec T19–T21 (Anbindung der Planungshilfe) bis TK T13. **Wartet auf den Product Owner**: T17 (Freischalten).

**Tests**: Die Constitution verlangt test- und spec-getriebene Umsetzung mit pgTAP je Rechtevorlage. Vor jeder Migration steht eine Test-Task. Dateien 510–590 (research.md R-EZ-15); die Testdaten aus spec.md 9 legt jede Datei in ihrer Transaktion selbst an (plan.md O3 a). Für das Frontend gilt die Abnahme in TEST (quickstart.md D, abnahme-test.md) sowie `npm run lint` und `npm run build`.

**Organisation**: Phasen nach den Branches aus plan.md. Die Oberfläche (Phasen 4–9) entsteht als Stapel auf vier Branches (plan.md „Branches“): `us-ez-14-liste` (T019–T021), `us-ez-10-detail` (T022 Teil, T029–T031), `us-ez-01-erfassen` (T022–T028), `us-ez-16-kletterhalle` (T032); der Pull Request zielt auf den Vorgänger, bis dieser gemergt ist.

## Format: `- [ ] T### [P?] [US-EZ-xx] (spec Tn) Beschreibung`

- **T###**: laufende Task-ID dieser Datei
- **[P]**: parallel ausführbar (andere Datei, keine offene Abhängigkeit)
- **[US-EZ-xx]**: Story aus 02-stories.md
- **(spec Tn)**: Task-Nummer aus spec.md Abschnitt 10; „Teil“ = nur ein Teil davon

## Regeln für alle Tasks

- **Nie gegen PROD.** Keine Befehle gegen TEST ohne ausdrückliche Freigabe des Product Owners. Kein `supabase config push`, kein `supabase config diff`. `.env.local` nie lesen.
- **Bestehende Migrationen nicht ändern.** Neue Migrationen mit Präfix `20261028`, Dateiname `…_ez_*.sql`. Objekte anderer Module nur `ez_person_visible` per `create or replace` (gleiche Signatur).
- Jede Migration: für jede neue Tabelle `enable row level security`, `revoke all … from public, anon, authenticated`, `grant select … to authenticated`, eine Select-Policy; **keine** Insert-/Update-/Delete-Grants oder -Policies auf `ez_`-Tabellen. Jede Funktion `revoke all … from public, anon, authenticated` und Grant nach data-model.md. Alle Funktionen `set search_path = ''`, voll qualifizierte Namen.
- Schreibfunktionen: `security definer`, erste Prüfung Rechte, dann Fachprüfungen, dann Schreiben. Fehler `raise exception '<CODE>' using errcode = 'P0001'`, Zusatz per `detail` (research.md R-EZ-04). Codes nur aus [contracts/error-codes.md](contracts/error-codes.md).
- Namen nie direkt aus `ea_persons` lesen (R44 AD); nur `ea_person_names`, `ea_search_active_persons`, `gr_group_roster`.
- Keine Echtdaten: Namen fiktiv. Keine Personendaten im Browser-Speicher außer Person-IDs im Entwurf.
- Fachliche Dateien (spec.md, 02-stories.md, uebergabe-*.md usw.) nicht ändern; Widersprüche als `[OFFEN]` melden.
- Code anderer Module (`gr_*`, `ad_*`, `ea_*`, `tk_*`) nicht ändern; sonst Übergabe `uebergabe-<modul>-umsetzung.md`.
- Commits deutsch. Pull Requests nennen Stories, Spec-Tasks, bei Oberfläche die Cloudflare-Vorschau-URL. Auto-Merge nur für PRs mit ausschließlich Migrationen, EZ-Tests, Seed und Umsetzungsdateien.
- Oberfläche: deutsch, „du“, Datum `TT.MM.JJJJ` über `formatDate()`, Namen über `personName()` (`src/lib/format.ts`), Fehler über `toMessage()` (`src/lib/errors.ts`), Tabellen über `ResponsiveTable`, ab 375 px ohne horizontales Scrollen, Trefferflächen ≥ 44 px.

---

## Phase 1: Plan (Branch `ez-plan`)

- [x] T001 plan.md, research.md, data-model.md, contracts/ (database-api.md, error-codes.md, routes.md), quickstart.md, tasks.md und abnahme-test.md in `docs/specs/ez-einsaetze/` anlegen; Voraussetzungen auf `main` gegen spec.md abgleichen (plan.md, O1–O4, H1–H7).

---

## Phase 2: Datenbank (Branch `ez-kern-datenbank`) – alle Stories, Datenbankteil

**Ziel**: Tabellen, Rechte, Sichtbarkeit, Schreib- und Lesefunktionen.

**Unabhängiger Test**: Action `db-tests.yml` grün mit allen vorhandenen Tests und den neuen Tests 510–590.

### Vorbereitung

- [x] T002 Branch `ez-kern-datenbank` von aktuellem `origin/main` anlegen; prüfen, dass `ez_person_visible(uuid)` (Platzhalter), `ea_person_names`, `ea_create_volunteer(text, text, text, uuid, uuid, jsonb, date, text)`, `ea_activate_person`, `gr_group_roster`, `gr_groups_for_attendance`, `ad_locations` und die Art `system_key = 'function'` vorhanden sind und die letzte Migration `20261027000100` ist. Fehlt etwas: anhalten und melden.

### Tests (zuerst schreiben, müssen fehlschlagen) ⚠️

- [x] T003 [P] [US-EZ-01] (spec T9 Teil) `supabase/tests/database/510_ez_structure.test.sql`: Typen mit allen Werten aus spec.md 2; Tabellen `ez_events`, `ez_event_groups`, `ez_attendances`, `ez_trial_participants`, `ez_privacy_confirmations` mit RLS; `has_table_privilege('authenticated', …, 'INSERT'|'UPDATE'|'DELETE')` = false, `anon` ohne `SELECT`; direkter Insert als Geschäftsstelle → `42501`; Funktionen aus data-model.md mit Grant an `authenticated`, interne ohne; `ez_can_read/write/delete` je Testzugang (Admin: lesen alle, nicht schreiben; Geschäftsstelle: alles; Rita: nur Referat Klettern lesen/schreiben, nicht löschen; Vorstand: nichts); Check `ez_events_shape` als Eigentümer für jede Einsatzart mit einem gültigen und einem ungültigen Datensatz (`23514`).
- [x] T004 [P] [US-EZ-14] [US-EZ-15] (spec T9 Teil) `supabase/tests/database/520_ez_visibility.test.sql`: Testdaten nach spec.md 9 in der Transaktion (Gruppen `c…03` „Klettergruppe Test“ und `c…01` „Jugendgruppe Test 1“, Personen ab 33, Funktionen Toni Muster (4) und Rita (9) als Trainer:in in `c…03`, Trainingszeit Di 17:00–19:00, Einsätze 1–11 mit UUIDs `f0000000-…`, `on conflict do nothing`); Sichtbarkeitsmatrix: Admin und Geschäftsstelle 1–11, Rita 1, 2, 4, 6–11, Vorstand keine (über `ez_events`, `ez_v_events`, `ez_list_events`); `ez_attendances`, `ez_event_groups`, `ez_trial_participants` nur für lesbare Einsätze; `ez_person_visible` für Rita: Personen aus 1, 2, 4, 6–11 wahr, Teilnehmer:innen nur aus 3 und 5 falsch; über `ea_person_names` dieselbe Menge; ohne Nutzerkontext `false` (Test 270 bleibt gültig); Vorstand mit „EZ lesen“ (in der Transaktion) sieht 1–11.
- [x] T005 [P] [US-EZ-01] [US-EZ-02] [US-EZ-05] [US-EZ-06] [US-EZ-08] [US-EZ-09] [US-EZ-17] [US-EZ-18] [US-EZ-20] [US-EZ-21] (spec T9 Teil) `supabase/tests/database/530_ez_save_event.test.sql` mit Aufrufen von `ez_save_event` als Rita bzw. Geschäftsstelle:
  - R1: je Einsatzart fehlendes Pflichtfeld → `EZ_FIELD_REQUIRED` mit `detail` (Gruppe, Referat, Titel, Organisierende Person, Datum, Startdatum, Enddatum, Dauer, Ort); R2 → `EZ_END_DATE`; R3/R28: Uhrzeiten bei Training und eintägig werden `null`; Titel 91 Zeichen → `EZ_TITLE_LENGTH`; Bemerkung 501 → `EZ_REMARK_LENGTH`; Probetraining leer/31 Zeichen → `EZ_TRIAL_NAME`; Probetraining außerhalb Training wird ignoriert;
  - R5: ohne Trainer:in bzw. ohne Teilnehmer:in → `EZ_MIN_ATTENDANCE`; Arbeitseinsatz, Kurs, Tour ohne Personen erlaubt;
  - R11: organisierende Person ruhend → `EZ_ORGANIZER_NOT_ACTIVE`; R12: „Halle alt Test“ → `EZ_LOCATION_INACTIVE`; gespeicherter Einsatz mit inaktiv gewordenem Ort bleibt änderbar;
  - R13/R14: Rita mit Gruppe Jugendgruppe Test 1 → `EZ_FORBIDDEN`; Arbeitseinsatz im Referat Kinder und Jugend → `EZ_FORBIDDEN`; Admin → `EZ_FORBIDDEN`; Ändern eines nicht lesbaren Einsatzes → `EZ_NOT_FOUND`;
  - R16: Teilnehmer:in einer anderen Gruppe → `EZ_PARTICIPANT_NOT_IN_GROUP`; Stichtag Einsatz 8 (01.08.2026): Teilnehmerin mit Eintritt 01.09.2026 → `EZ_PARTICIPANT_NOT_IN_GROUP`;
  - R17: Person doppelt → `EZ_DUPLICATE_PERSON`; R20: Vertretung ruhend → `EZ_PERSON_NOT_ACTIVE`, aktiv → `is_substitute = true`; Trainer:in der Gruppe → `is_substitute = false`; beim Ändern bleibt eine gespeicherte, inzwischen ruhende Vertretung erlaubt;
  - R21: `registered` beim Training → `EZ_STATUS_NOT_ALLOWED`; Teilnehmer:in bei Kurs → `EZ_ROLE_NOT_ALLOWED`;
  - R19: Ändern von `kind`, `group_id`, Referat bei Gruppe → `EZ_FIELD_LOCKED`; „eintägig → mehrtägig“ erlaubt; Referat eines Arbeitseinsatzes ändern auf beschreibbares Referat erlaubt, auf fremdes → `EZ_FORBIDDEN`;
  - R30: Wettkampfbetreuung mit zweiter Gruppe gleichen Referats; anderes Referat → `EZ_GROUP_REFERAT_MISMATCH`; `additional_group_ids` beim Training → `EZ_KIND_NOT_ALLOWED`; Teilnehmer:in der zweiten Gruppe erlaubt; weitere Gruppen ändern → `EZ_FIELD_LOCKED`;
  - R8: zweites Training gleiche Gruppe und Tag → `EZ_DUPLICATE_EVENT` mit `existing_id`; mit `p_confirm_duplicate` gespeichert; abgesagter vorhandener Einsatz zählt nicht; `detail` leer, wenn der vorhandene Einsatz nicht lesbar ist;
  - Idempotenz: zweiter Aufruf mit gleicher `client_request_id` liefert dieselbe `id`, keine zweite Zeile;
  - R9: `created_by`, `created_by_person_id` (Rita = Person 9), `updated_*` beim Ändern; direktes `update … set kind` als Eigentümer → `EZ_FIELD_LOCKED`;
  - Ersetzen: fehlende Anwesenheiten gelöscht, Rolle geändert, neue angelegt; Probetrainings ersetzt.
- [x] T006 [P] [US-EZ-10] [US-EZ-11] [US-EZ-13] [US-EZ-22] (spec T9 Teil) `supabase/tests/database/540_ez_event_functions.test.sql`:
  - `ez_delete_event`: Rita → `EZ_DELETE_FORBIDDEN`; Geschäftsstelle löscht samt Anwesenheiten und Probetrainings, Personen bleiben (R15); abgesagter Einsatz löschbar;
  - `ez_cancel_event`: Grund leer/501 → `EZ_CANCEL_REASON`; mit `present` → `EZ_CANCEL_NOT_ALLOWED`; Admin → `EZ_FORBIDDEN`; erfolgreich: `cancelled_*` gesetzt, `registered`/`absent` bleiben; zweimal → `EZ_EVENT_CANCELLED`; danach `ez_save_event` → `EZ_EVENT_CANCELLED` (R22);
  - `ez_restore_event`: leert `cancelled_*` und `cancel_reason`; ohne Absage ohne Wirkung; keine R8-Prüfung (R24);
  - `ez_create_helper` (R29): ohne Häkchen bzw. ohne `notice_version` → `EZ_PRIVACY_NOT_CONFIRMED`, keine neue Person; beim Training → `EZ_KIND_NOT_ALLOWED`; mit Häkchen als Rita: Person mit `volunteer_status = 'active'`, Eigenschaft Funktion „Helfer:in“ im Referat des Einsatzes ab `start_date`, `created_in = 'EA'` (Rita und Geschäftsstelle haben EA-Rechte; der EZ-Weg ist in AD-Test 280 geprüft), Anwesenheit `helper`/`present`, Zeile in `ez_privacy_confirmations`; Rita liest `ez_privacy_confirmations` nicht, Geschäftsstelle schon;
  - `ez_reactivate_helper` (R31): ruhende Person (5), ausgeschiedene (11), Person ohne Ehrenamtsstatus → aktiv mit Historie und Funktion Helfer:in, Anwesenheit; aktive Person → `EZ_PERSON_NOT_INACTIVE`; schon eingetragen → `EZ_DUPLICATE_PERSON`; Person zuletzt in anderem Referat aktiv → erlaubt;
  - R25: Einsatz mit im Test gesetztem `tk_plan_id` (als Eigentümer): `ez_save_event` mit geänderter Bemerkung erlaubt, mit geändertem Titel → `EZ_TK_MANAGED`; Person mit `from_plan = true` entfernen → `EZ_TK_MANAGED`, ihren Stand ändern erlaubt; `ez_cancel_event`, `ez_restore_event`, `ez_delete_event` → `EZ_TK_MANAGED`.
- [x] T007 [P] [US-EZ-14] [US-EZ-15] [US-EZ-16] (spec T9 Teil) `supabase/tests/database/550_ez_read_functions.test.sql`: mit den Testdaten aus T004: `ez_list_events` Filter Zeitraum, Referat, Gruppe (auch weitere Gruppe), Einsatzart; Zähler je Rolle; `total_count`; `p_limit` 500 → 200 Zeilen höchstens; Sortierung; abgesagter Einsatz 11 mit `is_cancelled`; `ez_get_event` mit Gruppen, Ortsname, Anwesenheiten, Probetrainings, `can_write`/`can_delete` je Testzugang; nicht lesbar → `EZ_NOT_FOUND`; `ez_climbing_points_report(Kletterhalle Test, 01.10.2026, 31.10.2026)` → 2 Zeilen (5/1, 4/0), ohne Namen; „Fels Test“ → `EZ_LOCATION_NO_POINTS`; abgesagtes Training fehlt.
- [x] T008 [P] (spec T9 Teil) `supabase/tests/database/590_ez_volume.test.sql`: 1.200 Einsätze (Arbeitseinsätze, ohne Gruppen) mit 15.000 Anwesenheiten in der Transaktion (als Eigentümer); `ez_list_events` 50 Zeilen < 1 s; `ez_save_event` mit 30 Anwesenheiten < 1 s; Kontrollliste eines Monats < 1 s; `ea_person_names` für 50 IDs als Rita < 1 s (Anhaltspunkt aus CI, `clock_timestamp()`).

### Migrationen

- [x] T009 [US-EZ-01] (spec T1, T2 Teil) `supabase/migrations/20261028000100_ez_tables.sql` nach data-model.md Nr. 1: Typen; `ez_can_read`, `ez_can_write`, `ez_can_delete`; `ez_events` mit allen Spalten aus spec.md 2 („title getrimmt, 1–90 Zeichen“, „remark … max. 500 Zeichen“, „cancel_reason 1–500 Zeichen; Pflicht genau dann, wenn cancelled_at gesetzt ist“, `tk_plan_id` nur bei Kurs und Tour) und Check `ez_events_shape`; `ez_event_groups`; `ez_attendances` („status default 'present'“, `is_substitute`, `from_plan` default false, unique `(event_id, person_id)`); `ez_trial_participants` („first_name 1–30 Zeichen“); Indizes aus data-model.md; RLS, Select-Policies, Grants.
- [x] T010 [US-EZ-14] (spec T2) `supabase/migrations/20261028000200_ez_visibility.sql`: `ez_person_visible` per `create or replace` nach research.md R-EZ-08.
- [x] T011 [US-EZ-12] (spec T3) `supabase/migrations/20261028000300_ez_triggers.sql`: `ez_my_person_id()`; Trigger `ez_events_before_insert` (Referat aus der Gruppe, `created_by_person_id`), `ez_events_before_update` (`EZ_FIELD_LOCKED` nach research.md R-EZ-10, `updated_*`), `ez_attendances_set_audit`, Audit für `ez_trial_participants`.
- [x] T012 [US-EZ-01] (spec T4) `supabase/migrations/20261028000400_ez_save_event.sql`: `ez_save_event` nach spec.md 2 Schritte 1–11 und research.md R-EZ-05, -06, -07, -11, -12; Fehlercodes nach contracts/database-api.md.
- [x] T013 [US-EZ-11] (spec T5) `supabase/migrations/20261028000500_ez_event_functions.sql`: `ez_privacy_confirmations` („notice_version 1–50 Zeichen“, RLS, Select-Policy `ez_can_delete()`); `ez_delete_event`, `ez_cancel_event`, `ez_restore_event`, `ez_create_helper`, `ez_reactivate_helper` nach research.md R-EZ-14.
- [x] T014 [US-EZ-14] (spec T6) `supabase/migrations/20261028000600_ez_read_functions.sql`: View `ez_v_events` (`security_invoker`), `ez_list_events`, `ez_get_event`, `ez_climbing_points_report` nach contracts/database-api.md.

### Fehlercodes

- [x] T015 [P] (spec T7) `docs/specs/ad-administration/contracts/error-codes.md`: Abschnitt „Anwesenheitserfassung (EZ)“ durch die vollständige Liste nach spec.md v0.5 mit Verweis auf [contracts/error-codes.md](contracts/error-codes.md) ersetzen; `EZ_END_TIME`, `EZ_KIND_NOT_AVAILABLE` entfernen; offenen Punkt zu fehlenden Meldungen aktualisieren. Sonst nichts in `ad-administration/` ändern. Status in contracts/error-codes.md auf „umgesetzt“.
- [x] T016 Personendaten-Prüfung nach CLAUDE.md; PR `ez-kern-datenbank` (#37) mit Stories, Spec-Tasks T1–T7, T9; Auto-Merge nach grünen Checks (gemergt 24.10.2026, 1.363 Tests grün).

---

## Phase 3: Seed (Branch `ez-seed`, PR #42) – entschieden 24.10.2026 (plan.md O3)

- [x] T017 [US-EZ-01] (spec T8) `supabase/seed-ez.sql` (statt Abschnitt in `seed.sql`; `seed.sh` lädt sie mit `SEED_WITH_EZ=1`) nach spec.md 9 und research.md R-EZ-16 (gleiche Daten und UUIDs wie T004); Nutzerkontext Geschäftsstelle für `created_by`.
- [x] T018 Übergabe `docs/specs/ez-einsaetze/uebergabe-seed-umsetzung.md` (39 Prüfungen in 10 Dateien anderer Module); entschieden: Vorschlag (a), keine Änderung an fremden Tests; PR ohne Auto-Merge (`seed.sh`).

---

## Phase 4: Liste (Branch `us-ez-14-liste`) – US-EZ-14, 15

**Unabhängiger Test**: /ez in der Vorschau mit allen Testzugängen (quickstart.md D 1, 11).

- [x] T019 [US-EZ-14] (spec T10 Teil) `src/lib/errors.ts`: EZ-Codes aus contracts/error-codes.md; `toMessage` mit `details` für `EZ_FIELD_REQUIRED`.
- [x] T020 [US-EZ-14] (spec T10 Teil) `src/features/ez/access.ts`, `labels.ts` (Einsatzarten, Rollen, Stände, Dauer), `EzLayout.tsx` (Navigation „Einsätze“, „Kontrolle Kletterhalle“), Routen in `src/App.tsx` mit Routenschutz nach contracts/routes.md.
- [x] T021 [US-EZ-14] [US-EZ-15] (spec T10) `src/features/ez/liste/EinsaetzePage.tsx`, `data.ts`: `ez_list_events` mit Filtern (Halbjahr Standard, Referat, Gruppe, Einsatzart), 50 je Seite (`Pagination`), mobil Karten, Zähler „2 T · 1 H · 9 TN“, Kennzeichen „abgesagt“, Leerzustand; „Neuer Einsatz“ nur mit `ad_has_any_level('EZ','edit')`.

---

## Phase 5: Training (Branch `us-ez-01-training`) – US-EZ-01–04, 17, 18, 19

**Unabhängiger Test**: quickstart.md D 2, 3, 10.

- [x] T022 [US-EZ-01] (O2) `src/features/ez/shared/OrtAuswahl.tsx` (aktive Orte aus `ad_locations`, gespeicherter inaktiver Ort bleibt angezeigt) und `AktivenSuche.tsx` (`ea_search_active_persons` ab 2 Zeichen, Vorschlagsliste „Aus der Gruppe“, „Keine aktive Person gefunden.“).
- [x] T023 [US-EZ-01] [US-EZ-19] (spec T11 Teil) `src/features/ez/erfassen/EinsatzNeuPage.tsx`, `EinsatzartAuswahl.tsx`, `EinsatzFormular.tsx` (Training): Gruppe aus `gr_groups_for_attendance` gefiltert auf beschreibbare Referate, Vorschlag nach `gr_my_groups` (R18), Datum Standard heute, Anzeige „Trainingszeit: Di 17:00–19:00“ bzw. Hinweis R28, Ort, Bemerkung mit Hinweis R7.
- [x] T024 [US-EZ-02] [US-EZ-03] [US-EZ-04] (spec T12) `src/features/ez/erfassen/Anwesenheit.tsx`, `Probetrainings.tsx`: Roster laden und bei Datumswechsel neu laden (Hinweis), Mehrfachzeilen zusammenfassen (plan.md H1), zwei Abschnitte mit Zähler, Rolle nur bei angehakten Betreuer:innen, Vertretung über `AktivenSuche`, Probetrainings mit Hinweis R6.
- [x] T025 [US-EZ-17] [US-EZ-18] (spec T15) `src/features/ez/erfassen/draft.ts` und Speichern: `client_request_id` je Formular, Entwurf nach research.md R-EZ-18 mit Rückfrage „Fortsetzen?“, Netzfehler-Meldung, R8-Rückfrage mit Link nur bei `existing_id`, „Trotzdem speichern“.

---

## Phase 6: Fahrten (Branch `us-ez-05-fahrten`) – US-EZ-05–08, 21

- [x] T026 [US-EZ-05] [US-EZ-06] [US-EZ-08] [US-EZ-21] (spec T11 Teil) `EinsatzFormular.tsx`: Tagesausflug, Mehrtagesfahrt, Ausbildungsfahrt und Wettkampfbetreuung (eintägig/mehrtägig), Trainingslager; Hinweise R4; „Weitere Gruppe hinzufügen“ (nur gleiches Referat, R30) mit Anwesenheitsliste aller Gruppen, je Person einmal.
- [x] T027 [US-EZ-07] (spec T13) organisierende Person mit `AktivenSuche`: vor der Eingabe Gruppenleitung, Trainer:innen, Helfer:innen aus dem Roster („Aus der Gruppe“), darunter „Alle Aktiven“.

---

## Phase 7: Arbeitseinsatz, Kurs, Tour, Detail (Branch `us-ez-09-arbeitseinsatz`) – US-EZ-09–13, 20

- [x] T028 [US-EZ-09] [US-EZ-20] (spec T11 Teil) `EinsatzFormular.tsx`, `PersonenEintragen.tsx`: Arbeitseinsatz, Kurs, Tour mit Referat (nur beschreibbare, bei einem vorausgewählt), Personen eintragen (Rolle Helfer:in bzw. Trainer:in vorbelegt, Stand „eingetragen“), Hinweis Planungshilfe bei Kurs/Tour.
- [x] T029 [US-EZ-10] [US-EZ-12] [US-EZ-13] [US-EZ-15] (spec T14) `src/features/ez/detail/EinsatzDetailPage.tsx`, `EinsatzBearbeitenPage.tsx`: Kopf mit Namen über `ea_person_names`, Anwesenheit nach Rolle mit Kennzeichen „Vertretung“, Stände „anwesend“/„nicht erschienen“ direkt, „alle anwesend“ (nur `registered` → `present`), „Person hinzufügen“; Bearbeiten mit gesperrter Einsatzart und Gruppe; Löschen mit Rückfrage nur bei `can_delete`; nur lesen ohne `can_write`.
- [x] T030 [US-EZ-11] (spec T14 Teil) `src/features/ez/detail/NeuePersonDialog.tsx`, `src/features/ez/config.ts` (Link und `notice_version`, plan.md O4): Dialog mit Pflicht-Häkchen R29 → `ad_find_similar_persons` → `DublettenDialog` mit „Diese Person eintragen“ (aktiv: `ez_save_event`; ruhend/ausgeschieden/ohne Status: Rückfrage R31 → `ez_reactivate_helper`) / „Trotzdem anlegen“ → `ez_create_helper`.

---

## Phase 8: Absage (Branch `us-ez-22-absage`) – US-EZ-22, 23 (Anzeige)

- [x] T031 [US-EZ-22] [US-EZ-23] (spec T18) `src/features/ez/detail/AbsageDialog.tsx`, Detail und Liste: Absagen mit Pflichtfeld Grund, Absage zurücknehmen mit Rückfrage, Hinweis „Abgesagt am … von …: …“, abgesagt nur Rücknahme und Löschen; Einsätze aus der Planungshilfe mit Hinweis, gesperrtem Kopf außer Bemerkung, Kennzeichen „aus der Planung“, ohne Absagen und Löschen.

---

## Phase 9: Kontrollliste (Branch `us-ez-16-kletterhalle`) – US-EZ-16

- [x] T032 [US-EZ-16] (spec T16) `src/features/ez/kletterhalle/KletterhallePage.tsx`: Ort (aktive und inaktive mit Punktekonto), Zeitraum Standard Vormonat, Tabelle Datum, Gruppe, Teilnehmer:innen, Probetrainings, Summenzeile, Leerzustand.

---

## Phase 10: Abschluss

- [x] T033 [P] Querschnitt je Oberflächen-PR: `npm run lint`, `npm run build` ohne Fehler; Personendaten-Prüfung nach CLAUDE.md.
- [ ] T034 (spec T17, Branch `ez-abnahme`) nach AD T120/T121 und Freigabe des Product Owners: Migrationen und Seed nach TEST (quickstart.md B), Abnahme nach quickstart.md D mit den Testzugängen auf dem Telefon; Ergebnisse in abnahme-test.md.
- [ ] T035 (spec T17, Branch `ez-freischalten`) Migration `…_ez_module_available.sql`: `update public.ad_modules set is_available = true where code = 'EZ'` mit Test; nur nach ausdrücklicher Freigabe des Product Owners.

---

## Zurückgestellt (mit TK T13)

- [ ] T036 [US-EZ-23] (spec T19) Migration `ez_upsert_planned_event`, `ez_cancel_planned_event`, `ez_planned_event_state`; Grants an `authenticated` (R26, R27).
- [ ] T037 [US-EZ-23] (spec T20) pgTAP: Anlegen und Aktualisieren aus der Planung; `from_plan`-Abgleich; `EZ_EVENT_LOCKED` nach erster Anwesenheit „anwesend“; Absage aus der Planung; `EZ_FORBIDDEN` ohne `tk_can_write`; `ez_planned_event_state` mit und ohne Einsatz.
- [ ] T038 [US-EZ-23] (spec T21) Abstimmung mit TK T14 (gemeinsamer Test von `tk_change_status` publish/cancel).

---

## Abhängigkeiten

- Phase 2 → Phase 3 (Seed, nach Entscheidung PO) und Phase 4 → 5 → 6 → 7 → 8; Phase 9 nach Phase 4.
- Innerhalb Phase 2: Tests T003–T008 zuerst (parallel); dann T009 → T010 → T011 → T012 → T013 → T014; T015 parallel.
- Phase 5 braucht T022 (O2) bzw. die Komponenten aus AD T120.
- T034, T035 nach AD T120, T121 und Freigabe des Product Owners.

## Parallel ausführbar

- T003–T008 (je eigene Testdatei), T015.
- Phase 9 parallel zu Phasen 5–8.

## Umsetzungsstrategie

1. **MVP Datenbank:** Phase 2. Alle Regeln, Rechte und Lesefunktionen sind in CI geprüft.
2. **MVP Oberfläche:** Phasen 4 und 5 (Liste, Training mit Anwesenheit). Damit ist der häufigste Fall des Forms-Formulars ersetzt.
3. **Ergänzungen:** Phasen 6–9.
4. **Abschluss:** Seed in TEST, Abnahme, Freischalten (Phase 3, 10) nach Freigabe.
