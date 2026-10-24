# Spec: Anwesenheitserfassung (EZ)

Version: 0.2 · Status: Entwurf · Stand: 24.10.2026 · Product Owner: Toni Werner
Stories: docs/specs/ez-einsaetze/02-stories.md (US-EZ-01 bis US-EZ-23, v0.4)
Grundlage: 00-steckbrief.md v0.8, 01-erhebung.md v0.4 (R1–R12), 02-stories.md v0.4 (R13–R18, R22–R27), glossar.md v1.6, rollen.md v1.0, tech-stack.md v0.6, spec.md Administration v0.8 (R30, R43–R45, `ea_person_names`, `ea_search_active_persons`, `ez_person_visible`, `ea_create_volunteer`, `ad_locations`), Gruppen 02-stories.md v0.7 (US-GR-19 `gr_group_roster`, US-GR-20 `gr_my_groups`, US-GR-19 AK8 `gr_groups_for_attendance`), Übergaben an Finanzen v1.6 und Ehrenamtsmanagement v1.2, Übergabe aus der Planungshilfe Touren und Kurse v1.2 (`tk-touren-kurse/uebergabe-anwesenheitserfassung.md`; Gegenstück spec.md TK v0.2 R9, R15, T13)
Änderungen v0.2: Abgleich mit dem Forms-Formular (Product Owner 24.10.2026): Training ohne Uhrzeit (R28, Dauer aus der Trainingszeit der Gruppe); Beginn und Ende mehrtägiger Einsätze optional (R4); mindestens eine Teilnehmer:in auch bei Fahrten, Trainingslager und Wettkampfbetreuung (R5); Einsatzart heißt Wettkampfbetreuung (glossar.md v1.6); `EZ_END_TIME` entfällt. Übergabe der Planungshilfe Touren und Kurse v1.2 eingearbeitet, Entscheidungen des Product Owners vom 24.10.2026: Kurs, Tour und Trainingslager im MVP freigeschaltet und auch von Hand anlegbar; Kurs und Tour ohne Gruppe, nur mit Trainer:innen und Helfer:innen (keine Teilnehmenden); Trainingslager wie Mehrtagesfahrt; Titel 1–90 Zeichen für alle Einsatzarten; Stand „abgesagt“ für alle Einsatzarten mit Grund, durch Nutzer mit Schreibrecht, zurücknehmbar, nur ohne anwesende Personen; Einsätze aus der Planungshilfe: Kopf, Absage und Löschen nur über die Planungshilfe, in der Anwesenheitserfassung nur die Anwesenheit. Neu: Spalten `tk_plan_id`, `cancelled_*`, `ez_attendances.from_plan`; Funktionen `ez_cancel_event`, `ez_restore_event`, `ez_upsert_planned_event`, `ez_cancel_planned_event`, `ez_planned_event_state`; Regeln R22–R27; Tasks T18–T21.
Änderungen v0.1: Erster Entwurf.

**Voraussetzungen für die Umsetzung:** Administration Nachtrag v0.8 (T50–T58) und Gruppen bis US-GR-20 sind umgesetzt. Die Anwesenheitserfassung legt keine Tabellen oder Funktionen anderer Module an; sie ersetzt nur den Platzhalter `ez_person_visible` (gleiche Signatur). Die Anbindung der Planungshilfe Touren und Kurse (T19–T21) wird erst zusammen mit TK T13 umgesetzt, weil sie `tk_can_write` der Planungshilfe nutzt; bis dahin bleibt `tk_plan_id` leer.

## 1. Ziel und Scope

**Ziel:** Trainings, Fahrten, Wettkampfbetreuungen, Arbeitseinsätze, Kurse, Touren und Trainingslager mit Anwesenheit zentral und mobil erfassen; Ablösung der Forms-Erfassung durch Geschäftsstelle und Referent:innen. Erfolg: Geschäftsstelle und Referent:innen erfassen in PROD ein Training mit Anwesenheit auf dem Telefon in unter 1 Minute [ANNAHME]; Finanzen kann später alle Daten für die Trainerabrechnung lesen (Übergabe F1), ohne dass etwas nacherfasst werden muss.

**Im Scope (MVP):**
- Einsatzarten Training, Tagesausflug, Mehrtagesfahrt, Ausbildungsfahrt (ein- oder mehrtägig), Wettkampfbetreuung (ein- oder mehrtägig), Arbeitseinsatz, Kurs (ein- oder mehrtägig), Tour (ein- oder mehrtägig), Trainingslager (mehrtägig).
- Anwesenheit je Einsatz mit Rolle (Trainer:in, Helfer:in, Teilnehmer:in) und Stand (eingetragen, anwesend, nicht erschienen); Vorbelegung aus der Gruppe zum Stichtag; Vertretungen; Probetrainings (nur Vorname); Bemerkung. Bei Kurs und Tour nur Trainer:innen und Helfer:innen.
- Organisierende Person bei Fahrten, Trainingslager, Kurs und Tour aus allen Aktiven per Suche.
- Neue Personen beim Arbeitseinsatz anlegen (Aktive, Funktion Helfer:in).
- Korrigieren; Absagen mit Grund und Absage zurücknehmen (alle Einsatzarten); Löschen nur durch die Geschäftsstelle.
- Übernahme von Kursen und Touren aus der Planungshilfe Touren und Kurse: Anlegen, Aktualisieren und Absagen des Einsatzes durch die Planungshilfe; Lesefunktion für den Stand „durchgeführt“ (umgesetzt mit TK T13).
- Liste mit Filtern; Lesen für Admin (und Vorstand, wenn der Admin „lesen“ vergibt).
- Kontrollliste Punktekonto Kletterhalle.
- Warnung bei doppelter Erfassung; Eingaben bleiben bei fehlgeschlagenem Speichern erhalten.
- Vorschlag der eigenen Gruppe (R18).

**Nicht im Scope:**
- Teilnehmende bei Kurs und Tour (Anmeldung und Teilnehmerliste in Yolawo; Product Owner 24.10.2026).
- Lehreinheiten bei Kursen (Erfassung offen, Übergabe an Finanzen).
- Erfassung durch Gruppenleitungen und Trainer:innen mit eigenem Zugang und Reichweite „Gruppe“ (Iteration 1); Ablösung des Forms-Formulars für sie.
- Berechnung von Vergütung, Abrechnungsdokumente, Sperre nach Abgabe des Halbjahres (Finanzen).
- Planung und Kalkulation von Kursen und Touren (Planungshilfe Touren und Kurse); Anmeldung von Fahrten (eigene Spezifikation, Product Owner 24.10.2026).
- Auswertungen auf Gruppenebene, Betreuungsschlüssel (Iteration 2); Einsatzhistorie je Person (Ehrenamtsmanagement, Iteration 2).
- Erwachsenenfahrten; Ausfallzeiten (Ferien); Altdaten aus der Forms-Excel; Abschalttermin des Forms-Formulars.
- QR-Code-Check-in; Offline-Erfassung; Export; Löschlauf nach Frist.

## 2. Datenmodell

Konventionen nach tech-stack.md: Schema `public`, Präfix `ez_`, snake_case, RLS auf jeder Tabelle. Datum und Uhrzeit sind lokale Werte (Europe/Berlin) ohne Zeitzone (`date`, `time`). Audit-Spalten `*_by` = `auth.uid()`, per Default bzw. Trigger, nie vom Frontend.

Typen:
- `ez_event_kind`: `training` (Training), `day_trip` (Tagesausflug), `multi_day_trip` (Mehrtagesfahrt), `training_trip` (Ausbildungsfahrt), `competition` (Wettkampfbetreuung), `work_assignment` (Arbeitseinsatz), `course` (Kurs), `tour` (Tour), `training_camp` (Trainingslager). Alle im MVP anlegbar (Product Owner 24.10.2026); der Check `ez_events_kind_mvp` entfällt.
- `ez_span`: `single` (eintägig), `multi` (mehrtägig).
- `ez_day_category`: `under_8h` (unter 8 Stunden), `at_least_8h` (mindestens 8 Stunden).
- `ez_role`: `trainer` (Trainer:in), `helper` (Helfer:in), `participant` (Teilnehmer:in).
- `ez_attendance_status`: `registered` (eingetragen), `present` (anwesend), `absent` (nicht erschienen).

### ez_events (Einsatz)

| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| kind | ez_event_kind | ja | – | Einsatzart; nach Anlage nicht änderbar (R19) |
| span | ez_span | ja | – | Training, Tagesausflug: immer `single`; Mehrtagesfahrt, Trainingslager: immer `multi`; Ausbildungsfahrt, Wettkampfbetreuung, Arbeitseinsatz, Kurs, Tour: wählbar (Check) |
| referat_id | uuid | ja | – | FK ea_referate(id). Bei Einsätzen mit Gruppe vom Trigger aus der Gruppe gesetzt (Stand bei Anlage); bei Arbeitseinsatz, Kurs und Tour gewählt (aus der Planungshilfe: Referat der Planung). Nach Anlage nicht änderbar (R19) |
| group_id | uuid | nein | null | FK gr_groups(id) on delete restrict. Pflicht bei allen Einsatzarten außer Arbeitseinsatz, Kurs und Tour; dort null (Check). Nach Anlage nicht änderbar (R19) |
| title | text | nein | null | getrimmt, 1–90 Zeichen (Product Owner 24.10.2026); Pflicht außer bei Training; bei Training null (Check) |
| organizer_person_id | uuid | nein | null | FK ea_persons(id) on delete restrict. Pflicht bei Tagesausflug, Mehrtagesfahrt, Ausbildungsfahrt, Trainingslager, Kurs, Tour; sonst null (Check). Beim Setzen Ehrenamtsstatus „aktiv“ (R11) |
| start_date | date | ja | – | Datum (Training, eintägig) bzw. Startdatum (mehrtägig); Stichtag für die Anwesenheitsliste (R16) |
| start_time | time | nein | null | mehrtägig: Abfahrt am Startort, optional; Training und eintägig: null (R3, R28) |
| end_date | date | nein | null | nur mehrtägig, Pflicht, > start_date (R2) |
| end_time | time | nein | null | mehrtägig: Rückkehr am Startort, optional; Training und eintägig: null |
| day_category | ez_day_category | nein | null | Pflicht bei eintägigen Einsätzen außer Training; sonst null |
| location_id | uuid | nein | null | FK ad_locations(id) on delete restrict. Pflicht bei Training; sonst null |
| remark | text | nein | null | Bemerkung, getrimmt, leer → null, max. 500 Zeichen |
| client_request_id | uuid | ja | – | vom Frontend je Formular erzeugt (bei Einsätzen aus der Planungshilfe von `ez_upsert_planned_event`); unique; Schutz gegen doppeltes Speichern (US-EZ-18) |
| tk_plan_id | uuid | nein | null | Planung der Planungshilfe Touren und Kurse, aus der der Einsatz erzeugt wurde; unique, wenn gesetzt; nur bei Kurs und Tour (Check); nur von `ez_upsert_planned_event` gesetzt, nie änderbar. Kein FK auf `tk_plans`, damit die Migration nicht von der Planungshilfe abhängt (wie `tk_plans.ez_event_id`) [ANNAHME: Name aus der Übergabe] |
| cancelled_at / cancelled_by / cancelled_by_person_id | timestamptz / uuid / uuid | nein | null | abgesagt am / von; gesetzt von `ez_cancel_event` bzw. `ez_cancel_planned_event`, geleert von `ez_restore_event` (R22) |
| cancel_reason | text | nein | null | Grund der Absage, getrimmt, 1–500 Zeichen; Pflicht genau dann, wenn `cancelled_at` gesetzt ist (Check) |
| created_at / created_by | timestamptz / uuid | ja / ja | now() / auth.uid() | erfasst am / von (R9) |
| created_by_person_id | uuid | nein | – | FK ea_persons(id); vom Trigger über `ad_accesses.auth_user_id` gesetzt; für die Anzeige „erfasst von“ |
| updated_at / updated_by / updated_by_person_id | timestamptz / uuid / uuid | nein | – | geändert am / von; vom Trigger gesetzt |

Check `ez_events_shape` (R1–R3, je Einsatzart; „leer“ = null):

| Einsatzart | span | group_id | title | organizer | start_time / end_time | end_date | day_category | location_id |
|---|---|---|---|---|---|---|---|---|
| training | single | Pflicht | leer | leer | leer (R28) | leer | leer | Pflicht |
| day_trip | single | Pflicht | Pflicht | Pflicht | leer | leer | Pflicht | leer |
| multi_day_trip | multi | Pflicht | Pflicht | Pflicht | optional | Pflicht, > start_date | leer | leer |
| training_trip | single oder multi | Pflicht | Pflicht | Pflicht | wie day_trip bzw. multi_day_trip | | | leer |
| competition | single oder multi | Pflicht [ANNAHME: nur mit Gruppe] | Pflicht | leer | wie day_trip bzw. multi_day_trip | | | leer |
| work_assignment | single oder multi | leer | Pflicht | leer | wie day_trip bzw. multi_day_trip | | | leer |
| training_camp | multi | Pflicht | Pflicht | Pflicht | optional | Pflicht, > start_date | leer | leer |
| course | single oder multi | leer | Pflicht | Pflicht | wie day_trip bzw. multi_day_trip | | | leer |
| tour | single oder multi | leer | Pflicht | Pflicht | wie day_trip bzw. multi_day_trip | | | leer |

Indizes: `(start_date desc)`, `(referat_id, start_date desc)`, `(group_id, start_date desc)`, `(location_id, start_date) where kind = 'training'`, unique `(client_request_id)`, unique `(tk_plan_id) where tk_plan_id is not null`.

### ez_attendances (Anwesenheit)

| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| event_id | uuid | ja | – | FK ez_events(id) on delete cascade |
| person_id | uuid | ja | – | FK ea_persons(id) on delete restrict; nur `kind = 'human'` |
| role | ez_role | ja | – | Rolle in diesem Einsatz; Teilnehmer:in nur bei Einsätzen mit Gruppe |
| status | ez_attendance_status | ja | 'present' | `registered` nur bei Arbeitseinsatz, Kurs und Tour (R21) |
| is_substitute | boolean | ja | false | vom System gesetzt: Trainer:in/Helfer:in ohne gültige Funktion in der Gruppe am Stichtag (Vertretung); bei Einsätzen ohne Gruppe immer false |
| from_plan | boolean | ja | false | vom System gesetzt: Person kommt aus der Planung der Planungshilfe (`ez_upsert_planned_event`); in der Anwesenheitserfassung ergänzte Personen haben false (R25) |
| created_at / created_by, updated_at / updated_by | | | | Audit |

Unique `(event_id, person_id)` (R17). Index `(person_id)` (für spätere Einsatzhistorie und Löschprüfung).

Bei Training, Fahrten, Trainingslager und Wettkampfbetreuung werden nur angekreuzte Personen gespeichert (Status `present`). Nicht angekreuzte Personen der Gruppe erscheinen nicht in der Tabelle. Bei Arbeitseinsatz, Kurs und Tour werden Personen eingetragen und ihr Stand bestätigt.

### ez_trial_participants (Probetraining)

| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| event_id | uuid | ja | – | FK ez_events(id) on delete cascade |
| first_name | text | ja | – | nur Vorname, getrimmt, 1–30 Zeichen (R6) |
| created_at / created_by | timestamptz / uuid | ja | now() / auth.uid() | |

Probetrainings nur bei Einsätzen mit Gruppe [ANNAHME: auch bei Fahrten möglich, in der Oberfläche nur beim Training angeboten].

### Views (security_invoker = true)

- `ez_v_events`: alle Spalten von `ez_events` plus `is_cancelled` (`cancelled_at is not null`), Anzahl `present` je Rolle, Anzahl `registered` und `absent` sowie Anzahl Probetrainings. Gruppen- und Ortsnamen ergänzen `ez_list_events` und `ez_get_event`, weil `gr_groups` für Nutzer der Anwesenheitserfassung nicht direkt lesbar ist.

### Funktionen (security definer, fester `search_path`, Grants nur an `authenticated`)

Rechte (R13, R14; zentrale Stelle, damit Iteration 1 die Reichweite „Gruppe“ nur hier ergänzt):
- `ez_can_read(p_referat uuid) returns boolean` – stable: `ad_has_level('EZ','read') or p_referat = any(ad_my_referate('EZ','read'))`.
- `ez_can_write(p_referat uuid) returns boolean` – stable: `ad_has_level('EZ','edit') or p_referat = any(ad_my_referate('EZ','edit'))`.
- `ez_can_delete() returns boolean` – stable: `ad_has_level('EZ','manage')`.

Sichtbarkeit von Namen:
- `ez_person_visible(p_person uuid) returns boolean` – ersetzt den Platzhalter der Administration (`create or replace`, gleiche Signatur): wahr, wenn die Person in einem für den Nutzer lesbaren Einsatz (`ez_can_read(referat_id)`) als Anwesenheit, organisierende Person, `created_by_person_id` oder `updated_by_person_id` vorkommt. Abweichung von der Beschreibung in spec.md AD v0.8 (dort zusätzlich Gruppen und Aktive der Referate): nicht nötig, weil Namen vor dem Speichern über `gr_group_roster` und `ea_search_active_persons` kommen (Datensparsamkeit).

Lesen:
- `ez_list_events(p_from date, p_to date, p_referat uuid default null, p_group uuid default null, p_kind ez_event_kind default null, p_limit int default 50, p_offset int default 0) returns setof (…)` – Zeilen aus `ez_v_events`, für die `ez_can_read` gilt, plus `group_name`; Filter auf start_date (bei mehrtägigen zählt der Beginn); Sortierung start_date desc, start_time desc; p_limit 1–200. Zusätzlich `total_count` je Zeile (für Paginierung). Abgesagte Einsätze sind enthalten und an `is_cancelled` erkennbar (R22).
- `ez_get_event(p_id uuid) returns jsonb` – Einsatz mit Gruppenname, Ortsname, Absage (abgesagt am, von, Grund), Kennzeichen „aus der Planungshilfe“ (`tk_plan_id is not null`), Anwesenheiten (id, person_id, role, status, is_substitute, from_plan), Probetrainings; Fehler `EZ_NOT_FOUND`, wenn nicht vorhanden oder nicht lesbar (keine Unterscheidung, damit keine Existenz verraten wird). Namen holt das Frontend über `ea_person_names`.
- `ez_climbing_points_report(p_location uuid, p_from date, p_to date) returns setof (event_id uuid, start_date date, group_name text, participants_present int, trial_count int)` – nur nicht abgesagte Trainings am Ort mit `has_climbing_points = true` und lesbarem Referat; keine Namen (US-EZ-16). Fehler `EZ_LOCATION_NO_POINTS`, wenn der Ort das Kennzeichen nicht hat.

Schreiben (direkte Insert/Update/Delete auf `ez_`-Tabellen sind für `authenticated` nicht erlaubt; alle Schreibvorgänge laufen über diese Funktionen):
- `ez_save_event(p_event jsonb, p_attendances jsonb, p_trials jsonb, p_confirm_duplicate boolean default false) returns uuid` – legt an (ohne `id`) oder ändert (mit `id`), in einer Transaktion:
  1. Rechte: Anlegen nur mit `ez_can_write(referat)`; das Referat ist bei Einsätzen mit Gruppe das Referat der Gruppe (über `gr_groups_for_attendance`), sonst `p_event.referat_id`. Ändern nur, wenn `ez_can_write` für das gespeicherte Referat gilt. Sonst `EZ_FORBIDDEN`.
  2. Idempotenz: existiert ein Einsatz mit gleicher `client_request_id`, gibt die Funktion dessen id zurück, ohne zu schreiben (US-EZ-18 AK2).
  3. Unveränderliche Felder beim Ändern: kind, group_id, referat_id → `EZ_FIELD_LOCKED` (R19). `span` (eintägig/mehrtägig) bleibt änderbar [ANNAHME]; die Form wird erneut geprüft. Abgesagter Einsatz → `EZ_EVENT_CANCELLED` (R22). Einsatz aus der Planungshilfe (`tk_plan_id` gesetzt): jede Änderung an Feldern von `ez_events` außer `remark` [ANNAHME] → `EZ_TK_MANAGED` (R25).
  4. Form nach `ez_events_shape`, Längen, R2 → Fehlercodes aus Abschnitt 5.
  5. Ort aktiv (nur bei Anlage oder Änderung des Orts) → `EZ_LOCATION_INACTIVE` (R12).
  6. Organisierende Person mit Ehrenamtsstatus „aktiv“ (nur bei Anlage oder Änderung) → `EZ_ORGANIZER_NOT_ACTIVE` (R11).
  7. Anwesenheiten (`p_attendances`: Liste von {person_id, role, status}) ersetzen die gespeicherten vollständig (fehlende werden gelöscht, vorhandene aktualisiert, neue angelegt). Prüfungen: R17 (`EZ_DUPLICATE_PERSON`); Teilnehmer:innen müssen am start_date laut `gr_group_roster(group_id, start_date)` Teilnehmer:in der Gruppe sein (`EZ_PARTICIPANT_NOT_IN_GROUP`); Trainer:innen und Helfer:innen müssen laut Roster eine Funktion in der Gruppe haben oder Ehrenamtsstatus „aktiv“ haben (`EZ_PERSON_NOT_ACTIVE`; beim Ändern bleiben bereits gespeicherte Personen erlaubt); `is_substitute` = nicht als Gruppenleitung/Trainer:in/Helfer:in im Roster (nur bei Einsätzen mit Gruppe); Status `registered` nur bei Arbeitseinsatz, Kurs und Tour (`EZ_STATUS_NOT_ALLOWED`); Rolle Teilnehmer:in nicht bei Arbeitseinsatz, Kurs und Tour (`EZ_ROLE_NOT_ALLOWED`). Bei Einsätzen aus der Planungshilfe: Personen mit `from_plan = true` bleiben in der Liste und behalten ihre Rolle, nur ihr Stand ist änderbar; sonst `EZ_TK_MANAGED` (R25) [ANNAHME].
  8. R5 Mindestbesetzung (nicht bei Arbeitseinsatz, Kurs und Tour) → `EZ_MIN_ATTENDANCE`.
  9. Probetrainings (`p_trials`: Liste von Vornamen) ersetzen die gespeicherten; R6; nur beim Training.
  10. R8 Doppelte Erfassung: gibt es einen anderen, nicht abgesagten Einsatz mit gleicher Gruppe, gleichem start_date und gleicher Einsatzart und ist `p_confirm_duplicate = false`, dann Fehler `EZ_DUPLICATE_EVENT` mit Detail `existing_id` nur, wenn der vorhandene Einsatz lesbar ist (US-EZ-17 AK4).
  11. Audit: created_* bei Anlage, updated_* bei Änderung (Trigger).
- `ez_delete_event(p_id uuid)` – nur `ez_can_delete()`, sonst `EZ_DELETE_FORBIDDEN`; Einsatz aus der Planungshilfe → `EZ_TK_MANAGED` (R25); löscht Einsatz mit Anwesenheiten und Probetrainings (cascade); Personen bleiben (R15). Auch abgesagte Einsätze sind löschbar.
- `ez_cancel_event(p_id uuid, p_reason text)` – Absagen (R22, R23): nur `ez_can_write(referat_id)` (`EZ_FORBIDDEN`); Einsatz aus der Planungshilfe → `EZ_TK_MANAGED`; schon abgesagt → `EZ_EVENT_CANCELLED`; Grund leer oder länger als 500 Zeichen → `EZ_CANCEL_REASON`; mindestens eine Anwesenheit `present` → `EZ_CANCEL_NOT_ALLOWED`. Setzt `cancelled_at`, `cancelled_by`, `cancelled_by_person_id`, `cancel_reason`; Anwesenheiten (`registered`, `absent`) und Probetrainings bleiben gespeichert.
- `ez_restore_event(p_id uuid)` – Absage zurücknehmen (R24): nur `ez_can_write(referat_id)`; Einsatz aus der Planungshilfe → `EZ_TK_MANAGED`; nicht abgesagt → ohne Wirkung; leert die `cancelled_*`-Spalten und `cancel_reason`; setzt updated_*. Keine erneute Prüfung auf doppelte Erfassung (R8) [ANNAHME].
- `ez_create_helper(p_event uuid, p_first text, p_last text, p_preferred text default null, p_email text default null) returns uuid` – nur für Arbeitseinsätze (`EZ_KIND_NOT_ALLOWED`) mit `ez_can_write(referat)`; ruft `ea_create_volunteer` mit der Eigenschaftsart `system_key = 'function'` und dem Wert Helfer:in in `p_field_values` [ANNAHME: Feldschlüssel legt die erste EA-Migration fest], Referat des Einsatzes, `p_valid_from = start_date`, `p_contact_email`; legt die Anwesenheit (Rolle Helfer:in, Status `present`) an; gibt die person_id zurück. Fehler aus `ea_create_volunteer` werden durchgereicht (R45 der Administration). Die Dublettenprüfung ruft das Frontend vorher über `ad_find_similar_persons` auf.

Anbindung der Planungshilfe Touren und Kurse (Übergabe TK v1.2; aufgerufen aus `tk_save_plan` und `tk_change_status`, spec.md TK R15; umgesetzt mit TK T13):
- `ez_upsert_planned_event(p_tk_plan_id uuid, p_kind ez_event_kind, p_referat_id uuid, p_title text, p_span ez_span, p_start_date date, p_start_time time, p_end_date date, p_end_time time, p_day_category ez_day_category, p_organizer_person_id uuid, p_persons jsonb) returns uuid` – legt den Einsatz zur Planung an oder aktualisiert ihn (R26):
  1. Rechte: `tk_can_write(p_referat_id)` der Planungshilfe, sonst `EZ_FORBIDDEN`. Die Rechte der Anwesenheitserfassung (`ez_can_write`) werden nicht geprüft, weil der Einsatz im Auftrag der Planungshilfe entsteht.
  2. `p_kind` nur `course` oder `tour` (`EZ_KIND_NOT_ALLOWED`); Form nach `ez_events_shape`, Längen, R2, R11 wie bei `ez_save_event` (gleiche Fehlercodes; die Planungshilfe meldet sie als `TK_EZ_SYNC_FAILED`).
  3. Kein Einsatz mit `tk_plan_id = p_tk_plan_id` → anlegen (`client_request_id` = gen_random_uuid(), `referat_id` = `p_referat_id`). Vorhanden → abgesagt: `EZ_EVENT_CANCELLED`; mit mindestens einer Anwesenheit `present`: `EZ_EVENT_LOCKED` ohne Änderung; sonst Kopf überschreiben (Einsatzart und Referat bleiben, abweichende Werte → `EZ_FIELD_LOCKED`).
  4. `p_persons` = Liste {person_id, role `trainer`/`helper`}: Personen der Liste werden mit `from_plan = true` angelegt (Stand `registered`) bzw. ihre Rolle aktualisiert (eine schon in der Anwesenheitserfassung ergänzte Person wird dabei zu `from_plan = true`); Personen mit `from_plan = true`, die nicht mehr in der Liste stehen, werden entfernt; Personen mit `from_plan = false` bleiben unverändert. R17, R20 (`EZ_PERSON_NOT_ACTIVE`, außer bei bereits gespeicherten Personen).
  5. Audit wie `ez_save_event`; gibt die Einsatz-ID zurück.
- `ez_cancel_planned_event(p_tk_plan_id uuid, p_reason text)` – Absage aus der Planungshilfe (R27): Rechte wie oben; kein Einsatz zur Planung → ohne Wirkung; schon abgesagt → ohne Wirkung; mindestens eine Anwesenheit `present` → `EZ_EVENT_LOCKED` [ANNAHME: gleiche Regel wie beim Absagen in der Anwesenheitserfassung]; sonst wie `ez_cancel_event`.
- `ez_planned_event_state(p_tk_plan_id uuid) returns jsonb` – stable; Rechte `tk_can_read(referat_id)` der Planungshilfe, sonst `EZ_NOT_FOUND`: `event_id`, `is_cancelled`, Anzahl je Stand und Rolle, `is_done` = mindestens eine Person mit Rolle Trainer:in oder Helfer:in `present` [ANNAHME]; ohne Einsatz `null`. Keine Namen.

Trigger:
- `ez_events_before_insert`: setzt bei Einsätzen mit Gruppe `referat_id` aus der Gruppe (ignoriert den gelieferten Wert), `created_by_person_id`.
- `ez_events_before_update`: verhindert Änderung von kind, group_id, referat_id, tk_plan_id, created_* (`EZ_FIELD_LOCKED`); setzt updated_*.
- `ez_attendances_set_audit`: created_*/updated_*.

## 3. Rechte / RLS

Grundsatz: Lesen per RLS über `ez_can_read`; Schreiben nur über die Funktionen aus Abschnitt 2 (keine Insert/Update/Delete-Policies, keine Grants dafür). Namen von Personen nie direkt aus `ea_persons`, nur über `ea_person_names` (Bedingung `ez_person_visible`), `ea_search_active_persons` und `gr_group_roster` (R44 der Administration).

| Rechtevorlage (Startwert) | Lesen | Anlegen | Ändern | Absagen / zurücknehmen | Löschen | Personen anlegen (Arbeitseinsatz) |
|---|---|---|---|---|---|---|
| Admin (EZ lesen, alle) | alle Einsätze | – | – | – | – | – |
| Geschäftsstelle (EZ verwalten, alle) | alle | ja | ja | ja | ja | ja |
| Referent:in (EZ bearbeiten, Referat) | Einsätze ihrer Referate | nur für ihre Referate (Gruppen ihrer Referate bzw. Arbeitseinsatz, Kurs, Tour mit ihrem Referat) | Einsätze ihrer Referate | Einsätze ihrer Referate | – | ja, für ihre Referate |
| Vorstand (Startwert ohne Rechte) | – (mit „EZ lesen“ vom Admin: alle) | – | – | – | – | – |
| Gruppenleitung / Trainer:in | Iteration 1 (Reichweite „Gruppe“) | | | | | |
| Planungshilfe (`tk_can_write` im Referat der Planung) | Stand über `ez_planned_event_state` (mit `tk_can_read`) | Kurs/Tour über `ez_upsert_planned_event` | Kopf und Personen aus der Planung, bis zur ersten Anwesenheit „anwesend“ | Absagen über `ez_cancel_planned_event` | – | – |

Einsätze aus der Planungshilfe: Kopf, Absage und Löschen nur über die Planungshilfe; in der Anwesenheitserfassung nur Stand der Personen, weitere Personen und Bemerkung [ANNAHME] (R25).

| Tabelle / Objekt | Lesen | Anlegen | Ändern | Löschen |
|---|---|---|---|---|
| ez_events | `ez_can_read(referat_id)` | `ez_save_event`, `ez_upsert_planned_event` | `ez_save_event`, `ez_cancel_event`, `ez_restore_event`, `ez_upsert_planned_event`, `ez_cancel_planned_event` | `ez_delete_event` |
| ez_attendances | Einsatz lesbar | `ez_save_event`, `ez_create_helper`, `ez_upsert_planned_event` | `ez_save_event`, `ez_upsert_planned_event` | `ez_save_event` (Ersetzen), `ez_upsert_planned_event`, cascade |
| ez_trial_participants | Einsatz lesbar | `ez_save_event` | `ez_save_event` | `ez_save_event`, cascade |

Gruppen und Anwesenheitslisten: über `gr_groups_for_attendance`, `gr_group_roster`, `gr_my_groups` (Rechteprüfung in Gruppen). Orte: `ad_locations` (lesbar mit aktivem Zugang). Referate: `ea_referate`.

Routenschutz: `/ez/*` ohne `ad_has_any_level('EZ','read')` → /kein-zugriff. Schaltflächen „Neuer Einsatz“, „Bearbeiten“ nur bei `ad_has_any_level('EZ','edit')` bzw. `ez_can_write(referat)` des Einsatzes; „Löschen“ nur bei `ad_has_level('EZ','manage')`.

## 4. Zustände und Übergänge

Einsatz: „erfasst“ oder „abgesagt“ (keine Freigabe im MVP). Löschen entfernt den Einsatz endgültig (nur Geschäftsstelle, nicht bei Einsätzen aus der Planungshilfe).

| Von | Nach | Wer | Bedingung |
|---|---|---|---|
| – | erfasst | Nutzer mit Schreibrecht (`ez_save_event`); Planungshilfe (`ez_upsert_planned_event`) | Planungshilfe nur Kurs und Tour, bei Status „in Yolawo angelegt“ |
| erfasst | abgesagt | Nutzer mit Schreibrecht (`ez_cancel_event`, nicht bei Einsätzen aus der Planungshilfe); Planungshilfe (`ez_cancel_planned_event`) | Grund angegeben; keine Anwesenheit „anwesend“ (R23) |
| abgesagt | erfasst | Nutzer mit Schreibrecht (`ez_restore_event`) | nicht bei Einsätzen aus der Planungshilfe (R24) |
| erfasst, abgesagt | (gelöscht) | Geschäftsstelle (`ez_delete_event`) | nicht bei Einsätzen aus der Planungshilfe |

Anwesenheit:

| Von | Nach | Wer | Bedingung |
|---|---|---|---|
| – | anwesend | Nutzer mit Schreibrecht | Ankreuzen bei Training, Fahrt, Trainingslager, Wettkampfbetreuung; Hinzufügen bei Arbeitseinsatz, Kurs, Tour vor Ort; neue Person beim Arbeitseinsatz |
| – | eingetragen | Nutzer mit Schreibrecht; Planungshilfe (Personen aus der Planung) | nur Arbeitseinsatz, Kurs, Tour (vorab gemeldet) |
| eingetragen | anwesend / nicht erschienen | Nutzer mit Schreibrecht | Arbeitseinsatz, Kurs, Tour; „alle anwesend“ setzt nur „eingetragen“ → „anwesend“ |
| anwesend / nicht erschienen | eingetragen / anwesend / nicht erschienen | Nutzer mit Schreibrecht | Korrektur bei Arbeitseinsatz, Kurs, Tour |
| anwesend | (entfernt) | Nutzer mit Schreibrecht | Haken entfernen bzw. Person entfernen (Korrektur); nicht bei Personen aus der Planung (R25) |
| eingetragen / nicht erschienen | (entfernt) | Planungshilfe | Person steht nicht mehr in der Planung, solange niemand „anwesend“ ist (R26) |

In abgesagten Einsätzen ist keine Änderung der Anwesenheit möglich (R22).

## 5. Geschäftsregeln

R1–R12 aus 01-erhebung.md, R13–R18 und R22–R27 aus 02-stories.md, hier mit Meldung und Fehlercode; R19–R21 neu in der Spec.

- R1 Pflichtfelder je Einsatzart (Tabelle `ez_events_shape`): Wenn ein Pflichtfeld fehlt, dann „Bitte ‚<Feld>‘ angeben.“ (`EZ_FIELD_REQUIRED`, Detail: Feld). Feldnamen: Gruppe, Referat, Titel, Organisierende Person, Datum, Startdatum, Enddatum, Beginn, Ende, Dauer, Ort, Grund.
- R2: Wenn bei mehrtägigen Einsätzen das Enddatum nicht nach dem Startdatum liegt, dann „Das Enddatum muss nach dem Startdatum liegen. Für eintägige Einsätze bitte ‚eintägig‘ wählen.“ (`EZ_END_DATE`).
- R3: Eintägige Einsätze außer Training speichern keine Uhrzeiten, nur die Dauer „unter 8 Stunden“ / „mindestens 8 Stunden“.
- R4: Beginn und Ende mehrtägiger Einsätze sind Abfahrt und Rückkehr am Startort; beide optional (Product Owner 24.10.2026); Hinweise am Feld „Abfahrt am Startort“ / „Rückkehr am Startort“.
- R5: Bei Training, Fahrt, Trainingslager und Wettkampfbetreuung mindestens eine anwesende Person mit Rolle Trainer:in oder Helfer:in und mindestens eine anwesende Teilnehmer:in (Product Owner 24.10.2026), sonst „Bitte mindestens eine Trainer:in oder Helfer:in und eine Teilnehmer:in auswählen.“ (`EZ_MIN_ATTENDANCE`). Gilt nicht bei Arbeitseinsatz, Kurs und Tour.
- R6: Wenn das Probetraining leer oder länger als 30 Zeichen ist, dann „Bitte einen Vornamen eingeben.“ bzw. „Bitte höchstens 30 Zeichen eingeben.“ (`EZ_TRIAL_NAME`). Hinweis am Feld: „Nur Vorname eintragen.“
- R7: Bemerkung optional, höchstens 500 Zeichen, sonst „Die Bemerkung darf höchstens 500 Zeichen haben.“ (`EZ_REMARK_LENGTH`). Hinweis am Feld: „Keine Angaben zu Gesundheit oder anderen sensiblen Daten von Kindern.“
- R8: Wenn für dieselbe Gruppe, dasselbe Datum (start_date) und dieselbe Einsatzart schon ein nicht abgesagter Einsatz besteht, dann Rückfrage „Für diese Gruppe ist an diesem Tag bereits ein Einsatz dieser Art erfasst. Trotzdem speichern?“ (`EZ_DUPLICATE_EVENT`); „Trotzdem speichern“ ruft erneut mit `p_confirm_duplicate = true` auf. Link zum vorhandenen Einsatz nur, wenn lesbar.
- R9: „Erfasst von/am“ und „geändert von/am“ setzt das System; nicht änderbar.
- R10: Bezeichnungen der Einsatzarten in der Oberfläche: Training, Tagesausflug, Mehrtagesfahrt, Ausbildungsfahrt, Wettkampfbetreuung, Trainingslager, Arbeitseinsatz, Kurs, Tour.
- R11: Die organisierende Person muss beim Setzen Ehrenamtsstatus „aktiv“ haben, sonst „Bitte eine aktive Person auswählen.“ (`EZ_ORGANIZER_NOT_ACTIVE`). Auswahl per Suche ab 2 Zeichen; bei gewählter Gruppe stehen deren Gruppenleitung, Trainer:innen und Helfer:innen (aus dem Roster) oben; bei Kurs und Tour die bereits eingetragenen Personen [ANNAHME].
- R12: Nur aktive Orte wählbar; beim Speichern eines inaktiven Orts „Dieser Ort ist nicht mehr aktiv. Bitte einen anderen Ort wählen.“ (`EZ_LOCATION_INACTIVE`). Gespeicherte Einsätze behalten einen inzwischen inaktiven Ort.
- R13: Referent:innen sehen, legen an und ändern nur Einsätze ihrer Referate; bei Einsätzen mit Gruppe gilt das Referat der Gruppe. Sonst „Für diesen Bereich hast du keine Rechte.“ (`EZ_FORBIDDEN`); nicht lesbare Einsätze erscheinen als „Einsatz nicht gefunden.“ (`EZ_NOT_FOUND`).
- R14: Admin und Vorstand (mit „EZ lesen“) lesen nur; Schreibversuche → `EZ_FORBIDDEN`.
- R15: Löschen nur mit „EZ verwalten“, nach Rückfrage „Einsatz und alle Anwesenheiten löschen?“; sonst `EZ_DELETE_FORBIDDEN` („Du darfst Einsätze nicht löschen.“). Anwesenheiten und Probetrainings werden mitgelöscht, Personen nicht.
- R16: Die Anwesenheitsliste zeigt Teilnehmer:innen mit gültiger Teilnahme und Gruppenleitung, Trainer:innen, Helfer:innen mit gültiger Funktion am start_date (Stichtag; mehrtägig = Startdatum). Teilnehmer:innen anderer Gruppen können nicht hinzugefügt werden: „Diese Person ist an diesem Tag nicht Teilnehmer:in der Gruppe.“ (`EZ_PARTICIPANT_NOT_IN_GROUP`).
- R17: Eine Person steht je Einsatz höchstens einmal in der Anwesenheit, sonst „Diese Person ist bereits eingetragen.“ (`EZ_DUPLICATE_PERSON`). Ist eine Person in der Gruppe Teilnehmer:in und Helfer:in, zeigt die Liste sie einmal mit der Rolle aus der Funktion (Helfer:in) vorbelegt; die Rolle ist änderbar.
- R18: Vorschlag der eigenen Gruppe nach `gr_my_groups(start_date)`: genau eine eigene, für den Nutzer beschreibbare Gruppe → vorausgewählt; mehrere → oben in der Auswahl, vorausgewählt die eine, deren Trainingszeit auf den Wochentag fällt [ANNAHME], sonst keine. Der Vorschlag gibt keine Rechte; wählbar sind nur Gruppen aus `gr_groups_for_attendance` mit `ez_can_write(referat_id)`.
- R19 (neu): Einsatzart, Gruppe und Referat sind nach dem Speichern nicht änderbar (bestätigt 22.10.2026; Referat beim Arbeitseinsatz [ANNAHME]); „Einsatzart, Gruppe und Referat können nicht geändert werden. Bitte den Einsatz löschen lassen und neu erfassen.“ (`EZ_FIELD_LOCKED`).
- R20 (neu): Trainer:innen und Helfer:innen ohne Funktion in der Gruppe am Stichtag (Vertretungen, Personen bei Arbeitseinsatz, Kurs und Tour) müssen beim Hinzufügen Ehrenamtsstatus „aktiv“ haben, sonst „Bitte eine aktive Person auswählen.“ (`EZ_PERSON_NOT_ACTIVE`).
- R21 (neu): Status „eingetragen“ gibt es nur bei Arbeitseinsatz, Kurs und Tour (`EZ_STATUS_NOT_ALLOWED`); die Rolle Teilnehmer:in gibt es dort nicht (`EZ_ROLE_NOT_ALLOWED`, „Bei dieser Einsatzart gibt es keine Teilnehmer:innen.“).
- R22: Ein abgesagter Einsatz bleibt in Liste und Detail sichtbar (Kennzeichen „abgesagt“ mit Grund), ist nicht änderbar („Der Einsatz ist abgesagt. Bitte zuerst die Absage zurücknehmen.“, `EZ_EVENT_CANCELLED`) und zählt nicht für Abrechnung, Kontrollliste Kletterhalle und Warnung bei doppelter Erfassung.
- R23: Absagen nur mit Grund (1–500 Zeichen, sonst „Bitte einen Grund mit höchstens 500 Zeichen angeben.“, `EZ_CANCEL_REASON`) und nur, solange niemand „anwesend“ ist, sonst „Der Einsatz hat schon anwesende Personen und kann nicht abgesagt werden.“ (`EZ_CANCEL_NOT_ALLOWED`). Absagen darf, wer den Einsatz ändern darf (R13).
- R24: Eine Absage kann zurückgenommen werden, von Nutzern mit Schreibrecht; danach ist der Einsatz wieder „erfasst“ und änderbar.
- R25: Einsätze aus der Planungshilfe Touren und Kurse: Kopf (Titel, Zeiten, organisierende Person), Personen aus der Planung und ihre Rolle, Absage und Löschen nur über die Planungshilfe; in der Anwesenheitserfassung nur Stand der Personen, weitere Personen und Bemerkung [ANNAHME]. Sonst „Dieser Einsatz kommt aus der Planungshilfe Touren und Kurse. Bitte dort ändern.“ (`EZ_TK_MANAGED`).
- R26: Die Planungshilfe aktualisiert ihren Einsatz nur, solange niemand „anwesend“ ist, sonst `EZ_EVENT_LOCKED` („Der Einsatz ist schon erfasst und wurde nicht geändert.“; die Planungshilfe zeigt `TK_EZ_LOCKED`).
- R27: Sagt die Planungshilfe ab, wird der Einsatz „abgesagt“ mit dem Grund der Planung; mit anwesenden Personen `EZ_EVENT_LOCKED` [ANNAHME].
- R28: Ein Training wird ohne Uhrzeit erfasst; Beginn und Ende ergeben sich aus der Trainingszeit der Gruppe am Datum (Gruppen, `gr_training_times`), die beim Erfassen nur angezeigt wird (Product Owner 24.10.2026).
- Längen: Titel 1–90 Zeichen, sonst „Bitte einen Titel mit höchstens 90 Zeichen eingeben.“ (`EZ_TITLE_LENGTH`).
- Weitere Meldungen: Netzfehler „Die Eingabe wurde nicht gesendet. Bitte bei Verbindung erneut speichern.“; Sitzung abgelaufen „Bitte erneut anmelden.“; Löschen fehlgeschlagen „Der Einsatz konnte nicht gelöscht werden. Bitte erneut versuchen.“; Suche ohne Treffer „Keine aktive Person gefunden.“; unerwartet „Etwas ist schiefgelaufen. Bitte versuche es erneut.“

Fehlercodes neu: `EZ_FORBIDDEN`, `EZ_NOT_FOUND`, `EZ_DELETE_FORBIDDEN`, `EZ_FIELD_REQUIRED`, `EZ_FIELD_LOCKED`, `EZ_END_DATE`, `EZ_TITLE_LENGTH`, `EZ_TRIAL_NAME`, `EZ_REMARK_LENGTH`, `EZ_LOCATION_INACTIVE`, `EZ_LOCATION_NO_POINTS`, `EZ_ORGANIZER_NOT_ACTIVE`, `EZ_PERSON_NOT_ACTIVE`, `EZ_PARTICIPANT_NOT_IN_GROUP`, `EZ_DUPLICATE_PERSON`, `EZ_DUPLICATE_EVENT`, `EZ_MIN_ATTENDANCE`, `EZ_STATUS_NOT_ALLOWED`, `EZ_ROLE_NOT_ALLOWED`, `EZ_KIND_NOT_ALLOWED`, `EZ_EVENT_CANCELLED`, `EZ_CANCEL_REASON`, `EZ_CANCEL_NOT_ALLOWED`, `EZ_TK_MANAGED`, `EZ_EVENT_LOCKED`. `EZ_KIND_NOT_AVAILABLE` entfällt (v0.2). Ergänzung in `docs/specs/ad-administration/contracts/error-codes.md` (gemeinsame Liste) mit deutschem Text je Code.

## 6. Screens und Interaktionen

Allgemein wie Administration: deutsch, „du“, Datum TT.MM.JJJJ, Zeit HH:MM, shadcn/ui, ab 375 px ohne horizontales Scrollen; Namen „Rufname Nachname“, sonst „Vorname Nachname“. Startseite: Kachel „Anwesenheitserfassung“ über `ad_my_modules` (mit `is_available`).

| Route | Zeigt | Aktionen | Leer / Fehler | Story |
|---|---|---|---|---|
| /ez | Liste: Datum bzw. Zeitraum („07.–09.11.2026“), Einsatzart, Gruppe oder Titel, Referat, Anzahl anwesend je Rolle (z. B. „2 T · 1 H · 9 TN“), Kennzeichen „abgesagt“ (Titel durchgestrichen, Anzahl ausgegraut) [ANNAHME: Darstellung]; Filter Zeitraum (Standard: aktuelles Halbjahr; Auswahl „1. Halbjahr JJJJ“, „2. Halbjahr JJJJ“, frei), Referat (nur lesbare), Gruppe, Einsatzart; 50 je Seite; mobil als Karten | Neuer Einsatz; Einsatz öffnen | „Keine Einsätze gefunden.“ | US-EZ-14, -15 |
| /ez/neu | Schritt 1: Einsatzart als große Schaltflächen (Training, Tagesausflug, Mehrtagesfahrt, Ausbildungsfahrt, Wettkampfbetreuung, Trainingslager, Arbeitseinsatz, Kurs, Tour). Schritt 2: Formular je Einsatzart (unten). Schritt 3 (gleiche Seite, unter dem Formular): Anwesenheit | Speichern; Abbrechen | Fehler je Feld; R8-Rückfrage | US-EZ-01, -05, -06, -08, -09, -19, -20, -21 |
| /ez/:id | Kopf (Einsatzart, Gruppe/Titel, Referat, Zeiten, Ort, organisierende Person, Bemerkung, erfasst von/am, geändert von/am; bei Absage Hinweis „Abgesagt am TT.MM.JJJJ von <Name>: <Grund>“; bei Einsätzen aus der Planungshilfe Hinweis „Aus der Planungshilfe Touren und Kurse. Kopf und Personen aus der Planung werden dort geändert.“), Anwesenheit nach Rolle mit Stand und Kennzeichen „Vertretung“ bzw. „aus der Planung“, Probetrainings | Bearbeiten; Absagen (Dialog mit Pflichtfeld „Grund“) bzw. Absage zurücknehmen (mit Rückfrage „Absage zurücknehmen?“); Löschen (nur Geschäftsstelle, mit Rückfrage); bei Arbeitseinsatz, Kurs und Tour direkt „anwesend“/„nicht erschienen“ je Person, „alle anwesend“, „Person hinzufügen“; „Neue Person anlegen“ nur beim Arbeitseinsatz. Abgesagt: nur Absage zurücknehmen und Löschen. Aus der Planungshilfe: kein Absagen, kein Löschen | „Einsatz nicht gefunden.“ | US-EZ-10, -12, -13, -15, -22, -23 |
| /ez/:id/bearbeiten | wie /ez/neu Schritt 2–3, Einsatzart und Gruppe nur angezeigt; bei Einsätzen aus der Planungshilfe Kopf nur angezeigt (außer Bemerkung) | Speichern | wie oben | US-EZ-12, -23 |
| /ez/kletterhalle | Ort (nur aktive und inaktive Orte mit Punktekonto), Zeitraum (Standard: Vormonat); Tabelle je Training: Datum, Gruppe, anwesende Teilnehmer:innen, Probetrainings; Summenzeile | – | „Keine Trainings im Zeitraum.“ | US-EZ-16 |

Formular je Einsatzart:
- **Training:** Gruppe (Auswahl, eigene Gruppe vorbelegt nach R18, eigene Gruppen oben) → Datum (Standard heute; keine Uhrzeit, R28; die Trainingszeit des Wochentags aus dem Roster wird nur angezeigt, z. B. „Trainingszeit: Di 17:00–19:00“) → Ort (Auswahlfeld „Ort“ der Administration) → Anwesenheit → Probetraining (Liste, „Probetraining hinzufügen“) → Bemerkung.
- **Tagesausflug:** Gruppe → Titel → Organisierende Person → Datum → Dauer (zwei Optionen) → Anwesenheit → Bemerkung.
- **Mehrtagesfahrt:** Gruppe → Titel → Organisierende Person → Startdatum, Beginn optional („Abfahrt am Startort“) → Enddatum, Ende optional („Rückkehr am Startort“) → Anwesenheit → Bemerkung.
- **Ausbildungsfahrt, Wettkampfbetreuung:** zuerst „eintägig“ / „mehrtägig“, dann wie Tagesausflug bzw. Mehrtagesfahrt; Wettkampfbetreuung ohne organisierende Person.
- **Trainingslager:** wie Mehrtagesfahrt (Gruppe → Titel → Organisierende Person → Start → Ende → Anwesenheit → Bemerkung).
- **Arbeitseinsatz:** Referat (nur beschreibbare; bei genau einem vorausgewählt) → Titel → eintägig/mehrtägig → Zeiten → Personen eintragen (Suche „Aktive“, Rolle Helfer:in vorbelegt und änderbar, Status „eingetragen“) → Bemerkung.
- **Kurs, Tour:** Referat (nur beschreibbare; bei genau einem vorausgewählt) → Titel → Organisierende Person → eintägig/mehrtägig → Zeiten → Personen eintragen (Suche „Aktive“, Rolle Trainer:in vorbelegt [ANNAHME] und änderbar zu Helfer:in, Status „eingetragen“; keine Teilnehmenden) → Bemerkung. Hinweis oben: „Kurse und Touren aus der Planungshilfe Touren und Kurse werden automatisch angelegt.“ [ANNAHME: Text].

Anwesenheit (Training, Fahrt, Trainingslager, Wettkampfbetreuung):
- Lädt nach Wahl von Gruppe und Datum `gr_group_roster(group_id, start_date)`; bei Datumswechsel neu laden; bereits gesetzte Haken von Personen, die am neuen Datum nicht mehr in der Liste sind, werden entfernt und es erscheint „Die Liste wurde für das neue Datum aktualisiert.“
- Zwei Abschnitte: „Trainer:innen und Helfer:innen“ (Gruppenleitung erscheint mit Rolle Trainer:in vorbelegt [ANNAHME], Trainer:in → Trainer:in, Helfer:in → Helfer:in) und „Teilnehmer:innen“; je Zeile Kontrollkästchen (Touch-Fläche mind. 44 px), Name, Rollenauswahl (nur bei angehakten Trainer:innen/Helfer:innen sichtbar). Alphabetisch nach Nachname. Zähler „n ausgewählt“ je Abschnitt.
- „Person hinzufügen“ (Vertretung): Personensuche „Aktive“ der Administration; Rolle Trainer:in oder Helfer:in wählen; Kennzeichen „Vertretung“.
- Keine Anzeige von Geburtsdatum, Alter oder anderen Angaben.

Organisierende Person: Komponente „Personensuche Aktive“ der Administration; vor der Eingabe Liste der Gruppenleitung, Trainer:innen und Helfer:innen aus dem Roster („Aus der Gruppe“), darunter Suchergebnisse („Alle Aktiven“).

Neue Person beim Arbeitseinsatz (nur in /ez/:id, nach dem ersten Speichern): Dialog Vorname, Nachname, Rufname (optional), E-Mail (optional) → `ad_find_similar_persons` → bei Treffern Dublettendialog der Administration mit „Diese Person eintragen“ (nur Treffer mit Ehrenamtsstatus „aktiv“; sonst Hinweis „Diese Person ist nicht aktiv. Bitte an die Geschäftsstelle wenden.“ [ANNAHME]) / „Trotzdem anlegen“ / „Abbrechen“ → `ez_create_helper`.

Speichern und Netz (US-EZ-18):
- Das Formular erzeugt beim Öffnen eine `client_request_id` und behält sie bis zum Erfolg.
- Entwurf im Browser (`localStorage`, Schlüssel je Nutzer) bei jeder Änderung; enthält nur Feldwerte und Person-IDs, keine Namen; wird nach erfolgreichem Speichern, beim Abbrechen und beim Abmelden gelöscht. Beim erneuten Öffnen von /ez/neu: „Es gibt eine nicht gespeicherte Eingabe vom TT.MM. HH:MM. Fortsetzen?“ (Ja/Verwerfen).
- Netzfehler: Meldung, Formular bleibt; erneutes Speichern mit derselben `client_request_id`.

Navigation EZ: Einsätze · Kontrolle Kletterhalle (nur mit `ad_has_any_level('EZ','edit')` oder Admin).

## 7. Schnittstellen

| Schnittstelle | Richtung | Inhalt |
|---|---|---|
| Administration | AD → EZ | `ad_has_level`, `ad_my_referate`, `ad_has_any_level`, `ad_me`, `ad_modules` (EZ, `is_available` setzt die letzte EZ-Migration bzw. das Freigabeskript), `ad_locations`, `ea_referate`, `ea_person_names`, `ea_search_active_persons`, `ad_find_similar_persons`, `ea_create_volunteer`; Komponenten „Personensuche Aktive“, „Auswahlfeld Ort“, Dublettendialog |
| Administration | EZ → AD | ersetzt `ez_person_visible` (gleiche Signatur); ergänzt Fehlercodes in contracts/error-codes.md |
| Gruppen | GR → EZ | `gr_groups_for_attendance(p_date)` (wählbare Gruppen: id, Name, Referat), `gr_group_roster(group_id, date)` (Trainingszeiten, Namen, Rollen zum Stichtag), `gr_my_groups(p_date)` (eigene Gruppen für den Vorschlag); FK `ez_events.group_id → gr_groups(id)` |
| Ehrenamtsmanagement | EZ → EA | neue Aktive aus Arbeitseinsätzen über `ea_create_volunteer` (`created_in = 'EZ'`); später Einsatzhistorie (E2, Iteration 2, liest `ez_attendances`) |
| Finanzen | EZ → FI | liest später `ez_events`, `ez_attendances` (F1) über eigene Lesefunktionen bzw. Rechte; keine Umsetzung in dieser Spec |
| Planungshilfe Touren und Kurse | TK → EZ | `ez_upsert_planned_event` (bei Status „in Yolawo angelegt“ und bei jedem Speichern danach), `ez_cancel_planned_event` (bei Absage), `ez_planned_event_state` (Stand „durchgeführt“); Inhalt nach spec.md TK R15; Rechte über `tk_can_write` / `tk_can_read` der Planungshilfe. Umsetzung mit TK T13 (Übergabe TK v1.2) |
| Microsoft Forms | – | keine Übernahme; läuft bis Iteration 1 parallel |

## 8. Nicht-funktionale Anforderungen

- RLS auf jeder `ez_`-Tabelle; Schreiben nur über Funktionen; pgTAP-Tests für jede Rechtevorlage.
- Mobil ab 375 px; Training mit 12 Personen in unter 1 Minute erfassbar (Abnahme mit Testzugang auf dem Telefon) [ANNAHME].
- Mengengerüst [ANNAHME]: ca. 13 Gruppen, ca. 1.200 Einsätze und 15.000 Anwesenheiten je Jahr; Liste (50 Zeilen) < 1 s; `ez_save_event` mit 30 Anwesenheiten < 1 s; Kontrollliste eines Monats < 1 s.
- Datum und Zeit ohne Zeitzone, immer Ortszeit Leipzig.
- Keine Personendaten im Browser-Speicher außer Person-IDs im Entwurf (gelöscht nach Speichern bzw. Abmelden).
- Kosten 0 €.
- Datenschutz: Verarbeitungsverzeichnis „Anwesenheitserfassung“ (Zweck: Nachweis, Abrechnung, Kontrolle Punktekonto; Kategorien: Namen, Anwesenheit, Rolle; Minderjährige: nur Name). Löschfrist [OFFEN] mit Finanzen; kein Löschlauf im MVP. Information neuer Personen nach Art. 13 DSGVO [OFFEN].

## 9. Testdaten (supabase/seed.sql, nur TEST, nach den Seeds von Administration und Gruppen)

Voraussetzung: Seed Administration (Testzugänge Admin, Geschäftsstelle, Referent:in „Rita Referentin“ Referat Klettern, Vorstand; Orte „Kletterhalle Test“ mit Punktekonto, „Fels Test“, „Halle alt Test“ inaktiv; Aktive Toni Muster, Karl Zweireferat) und Seed Gruppen (mindestens zwei Gruppen in zwei Referaten). Die Namen der Gruppen hier sind Platzhalter und werden an den Seed Gruppen angepasst [ANNAHME]: „Gruppe Test Klettern“ (Referat Klettern, Trainingszeit Di 17:00–19:00, Trainerin Toni Muster) und „Gruppe Test Jugend“ (Referat Kinder und Jugend). Zusätzlich: Rita Referentin ist Trainerin der „Gruppe Test Klettern“ (für US-EZ-19). Alle Namen fiktiv.

| # | Einsatz | Daten | Anwesenheit | Zweck |
|---|---|---|---|---|
| 1 | Training, Gruppe Test Klettern | 13.10.2026, Kletterhalle Test | Toni Muster (Trainer:in), 5 Teilnehmer:innen; Probetraining „Lena“ | Normalfall, Kontrollliste |
| 2 | Training, Gruppe Test Klettern | 20.10.2026, Kletterhalle Test | Karl Zweireferat (Helfer:in, Vertretung), 4 Teilnehmer:innen | Vertretung, Summe Kontrollliste |
| 3 | Training, Gruppe Test Jugend | 14.10.2026, Fels Test | Trainer:in der Gruppe, 3 Teilnehmer:innen | anderes Referat: für Rita nicht sichtbar |
| 4 | Tagesausflug „Boulderfelsen“, Gruppe Test Klettern | 03.10.2026, mindestens 8 Stunden, organisiert von Toni Muster | 2 Trainer:innen, 6 Teilnehmer:innen | eintägig |
| 5 | Mehrtagesfahrt „Elbsandstein“, Gruppe Test Jugend | 07.11.2026 16:00 – 09.11.2026 18:30, organisiert von Karl Zweireferat | 2 Trainer:innen, 8 Teilnehmer:innen | mehrtägig, Stichtag |
| 6 | Wettkampfbetreuung „Jugendcup Test“, Gruppe Test Klettern | 24.10.2026, unter 8 Stunden | 1 Trainer:in, 3 Teilnehmer:innen | ohne organisierende Person |
| 7 | Arbeitseinsatz „Aufbau Test-Cup“, Referat Klettern | 17.10.2026, mindestens 8 Stunden | 3 eingetragen, 2 anwesend, 1 nicht erschienen | Stände |
| 8 | Ausbildungsfahrt mehrtägig „Alpinfahrt Test“, Gruppe Test Klettern | 01.08.2026 08:00 – 08.08.2026 20:00 | 1 Trainer:in, 1 Helfer:in, 4 Teilnehmer:innen | 2. Halbjahr 2026; Stichtag: eine Teilnehmerin mit Eintrittsdatum 01.09.2026 erscheint nicht in der Anwesenheitsliste und wird beim Speichern mit `EZ_PARTICIPANT_NOT_IN_GROUP` abgelehnt |
| 9 | Kurs „Toprope-Kurs Test“ (von Hand), Referat Klettern | 21.11.2026, mindestens 8 Stunden, organisiert von Toni Muster | Toni Muster (Trainer:in, eingetragen), Karl Zweireferat (Helfer:in, eingetragen) | Kurs ohne Gruppe, keine Teilnehmenden; Rolle Teilnehmer:in → `EZ_ROLE_NOT_ALLOWED` |
| 10 | Trainingslager „Frankenjura Test“, Gruppe Test Klettern | 28.12.2026 09:00 – 02.01.2027 17:00, organisiert von Toni Muster | 1 Trainer:in, 5 Teilnehmer:innen | wie Mehrtagesfahrt |
| 11 | Tagesausflug „Sächsische Schweiz Test“, Gruppe Test Klettern, **abgesagt** (Grund „Wetter“) | 10.10.2026, unter 8 Stunden, organisiert von Toni Muster | keine Anwesenheit | Absage, Rücknahme, `EZ_EVENT_CANCELLED` beim Ändern; fehlt in der Kontrollliste |

Einsätze aus der Planungshilfe (Einsatz mit `tk_plan_id`) legt der Seed der Planungshilfe über `ez_upsert_planned_event` an (TK T14), nicht dieser Seed.

Erwartete Sichtbarkeit (Grundlage pgTAP T9):

| Testzugang | sieht Einsätze | darf schreiben, absagen | darf löschen |
|---|---|---|---|
| Admin (EZ lesen) | 1–11 | nein | nein |
| Geschäftsstelle (EZ verwalten) | 1–11 | alle | ja |
| Referent:in Klettern | 1, 2, 4, 6, 7, 8, 9, 10, 11 | diese | nein |
| Vorstand (ohne EZ) | keine | nein | nein |

Zusätzlich: `ez_person_visible` für Rita liefert Namen der Personen aus 1, 2, 4, 6–11, nicht die Teilnehmer:innen aus 3 und 5; `ez_climbing_points_report(Kletterhalle Test, 01.10.2026, 31.10.2026)` liefert 2 Zeilen mit 5 und 4 Teilnehmer:innen und 1 bzw. 0 Probetrainings.

## 10. Umsetzungs-Tasks

Voraussetzung: Administration T50–T58, Gruppen US-GR-18 bis US-GR-20 (inkl. `gr_groups_for_attendance`).

- [ ] T1: Migration Typen und Tabellen: Enums, `ez_events` mit Check `ez_events_shape` (alle neun Einsatzarten), Spalten `tk_plan_id` und `cancelled_*`, `ez_attendances` mit `from_plan`, `ez_trial_participants`, Indizes, RLS an, Select-Policies, keine Schreib-Grants (US-EZ-01, -05, -06, -08, -09, -20, -21, -22)
- [ ] T2: Migration Rechte- und Sichtbarkeitsfunktionen: `ez_can_read`, `ez_can_write`, `ez_can_delete`, `ez_person_visible` (ersetzt Platzhalter) (US-EZ-14, -15, R13, R14)
- [ ] T3: Migration Trigger: Referat aus Gruppe, Audit inkl. `*_person_id`, Sperre unveränderlicher Felder (R9, R19)
- [ ] T4: Migration `ez_save_event` mit allen Prüfungen aus Abschnitt 2 (Schritte 1–11) und Fehlercodes (US-EZ-01 bis -12, -17, -18)
- [ ] T5: Migration `ez_delete_event`, `ez_create_helper`, `ez_cancel_event`, `ez_restore_event` (US-EZ-11, -13, -22)
- [ ] T6: Migration Lesefunktionen `ez_list_events`, `ez_get_event`, `ez_climbing_points_report`, View `ez_v_events` (US-EZ-14, -15, -16)
- [ ] T7: Fehlercodes in contracts/error-codes.md (Abschnitt 5)
- [ ] T8: Seed nach Abschnitt 9 (US-EZ alle)
- [ ] T9: pgTAP: Sichtbarkeitsmatrix Abschnitt 9; jede Regel R1–R25 mit mindestens einem Fehlerfall (R25 mit einem im Test gesetzten `tk_plan_id`); Idempotenz `client_request_id`; Stichtag (Einsatz 8); direkte Insert/Update/Delete auf `ez_`-Tabellen abgelehnt; `ez_person_visible` nur Namen lesbarer Einsätze; Mengentest Abschnitt 8
- [ ] T10: Frontend Liste /ez mit Filtern und Paginierung (US-EZ-14, -15)
- [ ] T11: Frontend Formular Einsatzart-Auswahl und Formulare je Einsatzart inkl. Gruppenvorschlag (R18) und Anzeige der Trainingszeit (R28) (US-EZ-01, -05, -06, -08, -09, -19, -20, -21)
- [ ] T12: Frontend Anwesenheitsliste aus `gr_group_roster`, Vertretung, Probetraining, Bemerkung (US-EZ-02, -03, -04)
- [ ] T13: Frontend organisierende Person (US-EZ-07)
- [ ] T14: Frontend Detail /ez/:id inkl. Stände bei Arbeitseinsatz, Kurs und Tour, „alle anwesend“, neue Person anlegen (US-EZ-10, -11), Bearbeiten (US-EZ-12), Löschen (US-EZ-13)
- [ ] T15: Frontend Doppel-Warnung, Entwurf im Browser, Netzfehler (US-EZ-17, -18)
- [ ] T16: Frontend Kontrollliste /ez/kletterhalle (US-EZ-16)
- [ ] T17: Abnahme in TEST mit den Testzugängen auf dem Telefon (375 px): Admin, Geschäftsstelle, Referent:in, Vorstand; danach `ad_modules.is_available = true` für EZ per Migration (Freigabe durch den Product Owner)
- [ ] T18: Frontend Absagen und Absage zurücknehmen in /ez/:id, Kennzeichen „abgesagt“ in Liste und Detail; Anzeige von Einsätzen aus der Planungshilfe (Hinweis, gesperrte Felder, Kennzeichen „aus der Planung“) (US-EZ-22, -23)

Anbindung der Planungshilfe Touren und Kurse (erst zusammen mit TK T13, weil `tk_can_write` und `tk_can_read` aus der Planungshilfe genutzt werden):
- [ ] T19: Migration `ez_upsert_planned_event`, `ez_cancel_planned_event`, `ez_planned_event_state`; Grants an `authenticated` (US-EZ-23, R26, R27)
- [ ] T20: pgTAP: Anlegen und Aktualisieren aus der Planung; `from_plan`-Abgleich (Personen aus der Planung entfernen, in EZ ergänzte bleiben); `EZ_EVENT_LOCKED` nach erster Anwesenheit „anwesend“; Absage aus der Planung; `EZ_FORBIDDEN` ohne `tk_can_write`; `ez_planned_event_state` mit und ohne Einsatz
- [ ] T21: Abstimmung mit TK T14 (gemeinsamer Test von `tk_change_status` publish/cancel)

## 11. Annahmen und offene Punkte

Bestätigt vom Product Owner (21./22.10.2026): Modulname und Kürzel; Einsatzarten und Bezeichnungen wie im Forms-Formular; Erfassung je Gruppe; Kinder mit Vor- bzw. Rufname und Nachname; organisierende Person aus allen Aktiven; Zeiten eintägig über Dauer-Kategorie, mehrtägig mit Start und Ende (ab Startort); Orte als Stammdaten, nur Admin pflegt, Startliste bei der Umsetzung; Kontrolle Punktekonto nur Kinder; Löschen nur Geschäftsstelle; Einsatzart und Gruppe nicht änderbar; Standardrolle Helfer:in beim Arbeitseinsatz; keine organisierende Person bei der Wettkampfbetreuung; Stichtag (mehrtägig: Startdatum); Feldlängen; Vorschlag der eigenen Gruppe ohne Rechte; kein Offline-Betrieb.

Bestätigt vom Product Owner (24.10.2026, Übergabe der Planungshilfe Touren und Kurse v1.2): Die Planungshilfe erzeugt den Einsatz Kurs bzw. Tour bei „in Yolawo angelegt“ und sagt ihn bei Absage ab (Stand „abgesagt“ statt Löschen); Kurs, Tour und Trainingslager sind im MVP auch von Hand anlegbar; Kurs und Tour ohne Gruppe, mit Referat, Titel, organisierender Person, Zeiten und nur Trainer:innen und Helfer:innen (keine Teilnehmenden); Trainingslager wie Mehrtagesfahrt (mit Gruppe und Teilnehmer:innen); Titel 1–90 Zeichen für alle Einsatzarten (die Planungshilfe muss nicht mehr kürzen); „abgesagt“ für alle Einsatzarten, mit Grund, durch Nutzer mit Schreibrecht, zurücknehmbar, nur ohne anwesende Personen; Einsätze aus der Planungshilfe: Kopf, Absage und Löschen nur über die Planungshilfe, in der Anwesenheitserfassung nur die Anwesenheit; Stände „eingetragen / anwesend / nicht erschienen“ bei Kurs und Tour wie beim Arbeitseinsatz.

Annahmen (bei Abnahme bestätigen):
- [ANNAHME] Schreiben nur über Datenbankfunktionen (keine direkten Insert/Update-Policies); fachlich keine Auswirkung.
- [ANNAHME] Wettkampfbetreuung nur mit Gruppe.
- [ANNAHME] Referat beim Arbeitseinsatz nach dem Speichern nicht änderbar (wie Gruppe).
- [ANNAHME] „Eintägig/mehrtägig“ (span) nach dem Speichern änderbar, weil es nur die Zeitangaben betrifft; Prüfung der Form erneut.
- [ANNAHME] Gruppenleitung erscheint in der Anwesenheit mit Rolle Trainer:in vorbelegt.
- [ANNAHME] Probetrainings in der Oberfläche nur beim Training.
- [ANNAHME] Neue Person beim Arbeitseinsatz erst nach dem ersten Speichern des Einsatzes (Referat und Datum stehen dann fest).
- [ANNAHME] Dublettentreffer, die nicht aktiv sind, können nicht direkt eingetragen werden (Hinweis an die Geschäftsstelle); Reaktivierung im Ehrenamtsmanagement.
- [ANNAHME] Liste Standard aktuelles Halbjahr; 50 je Seite.
- [ANNAHME] Vorauswahl bei mehreren eigenen Gruppen über den Wochentag der Trainingszeit.
- [ANNAHME] Mengengerüst und Antwortzeiten aus Abschnitt 8.
- [ANNAHME] `ez_person_visible` enger als in spec.md AD v0.8 beschrieben (nur Personen gespeicherter, lesbarer Einsätze).
- [ANNAHME] Namen der Testgruppen werden an den Seed Gruppen angepasst.
- [ANNAHME] Dauer eines Trainings für die Abrechnung = gültige Trainingszeit der Gruppe am Wochentag des Datums (Finanzen liest sie aus Gruppen); ein kürzeres oder längeres Training wird nur in der Bemerkung festgehalten.
- [ANNAHME] Spaltenname `ez_events.tk_plan_id` ohne FK auf `tk_plans` (wie `tk_plans.ez_event_id` in spec.md TK).
- [ANNAHME] Bei Einsätzen aus der Planungshilfe ist in der Anwesenheitserfassung neben der Anwesenheit auch die Bemerkung änderbar; Personen aus der Planung behalten ihre Rolle und können nur über die Planungshilfe entfernt werden (`from_plan`).
- [ANNAHME] Absage aus der Planungshilfe mit anwesenden Personen wird abgelehnt (`EZ_EVENT_LOCKED`), wie das Absagen in der Anwesenheitserfassung (R23, R27).
- [ANNAHME] „Durchgeführt“ (`ez_planned_event_state`) = mindestens eine Person mit Rolle Trainer:in oder Helfer:in „anwesend“.
- [ANNAHME] Rücknahme einer Absage ohne erneute Warnung bei doppelter Erfassung.
- [ANNAHME] Kurs und Tour von Hand: Rolle Trainer:in vorbelegt; Organisierende Person: eingetragene Personen oben.
- [ANNAHME] Darstellung „abgesagt“ in der Liste (Kennzeichen, Titel durchgestrichen); Hinweistext zu Kursen und Touren aus der Planungshilfe.

Offen (kein Blocker für den MVP):
- [OFFEN] Lehreinheiten bei Kursen: erfassen in der Anwesenheitserfassung oder aus der Planungshilfe (Übergabe an Finanzen).
- [OFFEN] Doppelte Erfassung von Kurs und Tour: Ein von Hand angelegter Kurs und ein später aus der Planungshilfe erzeugter Einsatz für dieselbe Veranstaltung werden nicht erkannt (R8 gilt nur für Einsätze mit Gruppe). Hinweis im Formular reicht [ANNAHME], oder Warnung bei gleichem Referat, Datum und Einsatzart?
- [OFFEN] Training einer Gruppe mit mehreren Trainingszeiten am selben Wochentag (z. B. zwei Termine dienstags): Welche Zeit gilt, und wie wird das zweite Training am selben Tag erfasst (R8 warnt)? Auswahl der Trainingszeit beim Erfassen?
- [OFFEN] Abrechnung mehrtägiger Einsätze ohne Beginn bzw. Ende (erster und letzter Tag als Tages- oder Halbtagessatz) – mit Finanzen.
- [OFFEN] Löschfrist der Einsätze und Anwesenheiten (mit Finanzen; Aufbewahrung für Abrechnung).
- [OFFEN] Information nach Art. 13 DSGVO an Personen, die beim Arbeitseinsatz angelegt werden.
- [OFFEN] Sperre nach Abgabe des Halbjahres (Finanzen).
