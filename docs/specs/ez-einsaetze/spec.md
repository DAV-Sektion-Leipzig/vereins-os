# Spec: Anwesenheitserfassung (EZ)

Version: 0.1 · Status: Entwurf · Stand: 22.10.2026 · Product Owner: Toni Werner
Stories: docs/specs/ez-einsaetze/02-stories.md (US-EZ-01 bis US-EZ-19, v0.3)
Grundlage: 00-steckbrief.md v0.7, 01-erhebung.md v0.3 (R1–R12), 02-stories.md v0.3 (R13–R18), glossar.md v1.5, rollen.md v1.0, tech-stack.md v0.6, spec.md Administration v0.8 (R30, R43–R45, `ea_person_names`, `ea_search_active_persons`, `ez_person_visible`, `ea_create_volunteer`, `ad_locations`), Gruppen 02-stories.md v0.7 (US-GR-19 `gr_group_roster`, US-GR-20 `gr_my_groups`, US-GR-19 AK8 `gr_groups_for_attendance`), Übergaben an Finanzen v1.5 und Ehrenamtsmanagement v1.2
Änderungen v0.1: Erster Entwurf.

**Voraussetzungen für die Umsetzung:** Administration Nachtrag v0.8 (T50–T58) und Gruppen bis US-GR-20 sind umgesetzt. Die Anwesenheitserfassung legt keine Tabellen oder Funktionen anderer Module an; sie ersetzt nur den Platzhalter `ez_person_visible` (gleiche Signatur).

## 1. Ziel und Scope

**Ziel:** Trainings, Fahrten, Wettkampfbegleitungen und Arbeitseinsätze mit Anwesenheit zentral und mobil erfassen; Ablösung der Forms-Erfassung durch Geschäftsstelle und Referent:innen. Erfolg: Geschäftsstelle und Referent:innen erfassen in PROD ein Training mit Anwesenheit auf dem Telefon in unter 1 Minute [ANNAHME]; Finanzen kann später alle Daten für die Trainerabrechnung lesen (Übergabe F1), ohne dass etwas nacherfasst werden muss.

**Im Scope (MVP):**
- Einsatzarten Training, Tagesausflug, Mehrtagesfahrt, Ausbildungsfahrt (ein- oder mehrtägig), Wettkampfbegleitung (ein- oder mehrtägig), Arbeitseinsatz.
- Anwesenheit je Einsatz mit Rolle (Trainer:in, Helfer:in, Teilnehmer:in) und Stand (eingetragen, anwesend, nicht erschienen); Vorbelegung aus der Gruppe zum Stichtag; Vertretungen; Probetrainings (nur Vorname); Bemerkung.
- Organisierende Person bei Fahrten aus allen Aktiven per Suche.
- Neue Personen beim Arbeitseinsatz anlegen (Aktive, Funktion Helfer:in).
- Korrigieren; Löschen nur durch die Geschäftsstelle.
- Liste mit Filtern; Lesen für Admin (und Vorstand, wenn der Admin „lesen“ vergibt).
- Kontrollliste Punktekonto Kletterhalle.
- Warnung bei doppelter Erfassung; Eingaben bleiben bei fehlgeschlagenem Speichern erhalten.
- Vorschlag der eigenen Gruppe (R18).

**Nicht im Scope:**
- Einsatzarten Kurs, Tour, Trainingslager: im Datenmodell vorgesehen, Anlegen per Check gesperrt, bis die Übernahme aus dem Modul Touren und Kurse geklärt ist und Stories vorliegen.
- Erfassung durch Gruppenleitungen und Trainer:innen mit eigenem Zugang und Reichweite „Gruppe“ (Iteration 1); Ablösung des Forms-Formulars für sie.
- Berechnung von Vergütung, Abrechnungsdokumente, Sperre nach Abgabe des Halbjahres (Finanzen).
- Planung, Kalkulation und Anmeldung von Fahrten, Kursen, Touren (Modul Touren und Kurse).
- Auswertungen auf Gruppenebene, Betreuungsschlüssel (Iteration 2); Einsatzhistorie je Person (Ehrenamtsmanagement, Iteration 2).
- Erwachsenenfahrten; Ausfallzeiten (Ferien); Altdaten aus der Forms-Excel; Abschalttermin des Forms-Formulars.
- QR-Code-Check-in; Offline-Erfassung; Export; Löschlauf nach Frist.

## 2. Datenmodell

Konventionen nach tech-stack.md: Schema `public`, Präfix `ez_`, snake_case, RLS auf jeder Tabelle. Datum und Uhrzeit sind lokale Werte (Europe/Berlin) ohne Zeitzone (`date`, `time`). Audit-Spalten `*_by` = `auth.uid()`, per Default bzw. Trigger, nie vom Frontend.

Typen:
- `ez_event_kind`: `training` (Training), `day_trip` (Tagesausflug), `multi_day_trip` (Mehrtagesfahrt), `training_trip` (Ausbildungsfahrt), `competition` (Wettkampfbegleitung), `work_assignment` (Arbeitseinsatz), `course` (Kurs), `tour` (Tour), `training_camp` (Trainingslager). Die letzten drei sind im MVP gesperrt (Check `ez_events_kind_mvp`).
- `ez_span`: `single` (eintägig), `multi` (mehrtägig).
- `ez_day_category`: `under_8h` (unter 8 Stunden), `at_least_8h` (mindestens 8 Stunden).
- `ez_role`: `trainer` (Trainer:in), `helper` (Helfer:in), `participant` (Teilnehmer:in).
- `ez_attendance_status`: `registered` (eingetragen), `present` (anwesend), `absent` (nicht erschienen).

### ez_events (Einsatz)

| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| kind | ez_event_kind | ja | – | Einsatzart; nach Anlage nicht änderbar (R19) |
| span | ez_span | ja | – | Training, Tagesausflug: immer `single`; Mehrtagesfahrt: immer `multi`; Ausbildungsfahrt, Wettkampfbegleitung, Arbeitseinsatz: wählbar (Check) |
| referat_id | uuid | ja | – | FK ea_referate(id). Bei Einsätzen mit Gruppe vom Trigger aus der Gruppe gesetzt (Stand bei Anlage); beim Arbeitseinsatz gewählt. Nach Anlage nicht änderbar (R19) |
| group_id | uuid | nein | null | FK gr_groups(id) on delete restrict. Pflicht bei allen Einsatzarten außer Arbeitseinsatz; beim Arbeitseinsatz null (Check). Nach Anlage nicht änderbar (R19) |
| title | text | nein | null | getrimmt, 1–60 Zeichen; Pflicht außer bei Training; bei Training null (Check) |
| organizer_person_id | uuid | nein | null | FK ea_persons(id) on delete restrict. Pflicht bei Tagesausflug, Mehrtagesfahrt, Ausbildungsfahrt; sonst null (Check). Beim Setzen Ehrenamtsstatus „aktiv“ (R11) |
| start_date | date | ja | – | Datum (Training, eintägig) bzw. Startdatum (mehrtägig); Stichtag für die Anwesenheitsliste (R16) |
| start_time | time | nein | null | Training: Beginn; mehrtägig: Abfahrt am Startort; eintägig sonst null (R3) |
| end_date | date | nein | null | nur mehrtägig, Pflicht, > start_date (R2) |
| end_time | time | nein | null | Training: Ende (> start_time); mehrtägig: Rückkehr am Startort; eintägig sonst null |
| day_category | ez_day_category | nein | null | Pflicht bei eintägigen Einsätzen außer Training; sonst null |
| location_id | uuid | nein | null | FK ad_locations(id) on delete restrict. Pflicht bei Training; sonst null |
| remark | text | nein | null | Bemerkung, getrimmt, leer → null, max. 500 Zeichen |
| client_request_id | uuid | ja | – | vom Frontend je Formular erzeugt; unique; Schutz gegen doppeltes Speichern (US-EZ-18) |
| created_at / created_by | timestamptz / uuid | ja / ja | now() / auth.uid() | erfasst am / von (R9) |
| created_by_person_id | uuid | nein | – | FK ea_persons(id); vom Trigger über `ad_accesses.auth_user_id` gesetzt; für die Anzeige „erfasst von“ |
| updated_at / updated_by / updated_by_person_id | timestamptz / uuid / uuid | nein | – | geändert am / von; vom Trigger gesetzt |

Check `ez_events_shape` (R1–R3, je Einsatzart; „leer“ = null):

| Einsatzart | span | group_id | title | organizer | start_time / end_time | end_date | day_category | location_id |
|---|---|---|---|---|---|---|---|---|
| training | single | Pflicht | leer | leer | Pflicht, end > start | leer | leer | Pflicht |
| day_trip | single | Pflicht | Pflicht | Pflicht | leer | leer | Pflicht | leer |
| multi_day_trip | multi | Pflicht | Pflicht | Pflicht | Pflicht | Pflicht, > start_date | leer | leer |
| training_trip | single oder multi | Pflicht | Pflicht | Pflicht | wie day_trip bzw. multi_day_trip | | | leer |
| competition | single oder multi | Pflicht [ANNAHME: nur mit Gruppe] | Pflicht | leer | wie day_trip bzw. multi_day_trip | | | leer |
| work_assignment | single oder multi | leer | Pflicht | leer | wie day_trip bzw. multi_day_trip | | | leer |

Indizes: `(start_date desc)`, `(referat_id, start_date desc)`, `(group_id, start_date desc)`, `(location_id, start_date) where kind = 'training'`, unique `(client_request_id)`.

### ez_attendances (Anwesenheit)

| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| event_id | uuid | ja | – | FK ez_events(id) on delete cascade |
| person_id | uuid | ja | – | FK ea_persons(id) on delete restrict; nur `kind = 'human'` |
| role | ez_role | ja | – | Rolle in diesem Einsatz; Teilnehmer:in nur bei Einsätzen mit Gruppe |
| status | ez_attendance_status | ja | 'present' | `registered` nur beim Arbeitseinsatz |
| is_substitute | boolean | ja | false | vom System gesetzt: Trainer:in/Helfer:in ohne gültige Funktion in der Gruppe am Stichtag (Vertretung) |
| created_at / created_by, updated_at / updated_by | | | | Audit |

Unique `(event_id, person_id)` (R17). Index `(person_id)` (für spätere Einsatzhistorie und Löschprüfung).

Bei Training, Fahrten und Wettkampfbegleitung werden nur angekreuzte Personen gespeichert (Status `present`). Nicht angekreuzte Personen der Gruppe erscheinen nicht in der Tabelle.

### ez_trial_participants (Probetraining)

| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| event_id | uuid | ja | – | FK ez_events(id) on delete cascade |
| first_name | text | ja | – | nur Vorname, getrimmt, 1–30 Zeichen (R6) |
| created_at / created_by | timestamptz / uuid | ja | now() / auth.uid() | |

Probetrainings nur bei Einsätzen mit Gruppe [ANNAHME: auch bei Fahrten möglich, in der Oberfläche nur beim Training angeboten].

### Views (security_invoker = true)

- `ez_v_events`: alle Spalten von `ez_events` plus Anzahl `present` je Rolle, Anzahl `registered` und `absent` sowie Anzahl Probetrainings. Gruppen- und Ortsnamen ergänzen `ez_list_events` und `ez_get_event`, weil `gr_groups` für Nutzer der Anwesenheitserfassung nicht direkt lesbar ist.

### Funktionen (security definer, fester `search_path`, Grants nur an `authenticated`)

Rechte (R13, R14; zentrale Stelle, damit Iteration 1 die Reichweite „Gruppe“ nur hier ergänzt):
- `ez_can_read(p_referat uuid) returns boolean` – stable: `ad_has_level('EZ','read') or p_referat = any(ad_my_referate('EZ','read'))`.
- `ez_can_write(p_referat uuid) returns boolean` – stable: `ad_has_level('EZ','edit') or p_referat = any(ad_my_referate('EZ','edit'))`.
- `ez_can_delete() returns boolean` – stable: `ad_has_level('EZ','manage')`.

Sichtbarkeit von Namen:
- `ez_person_visible(p_person uuid) returns boolean` – ersetzt den Platzhalter der Administration (`create or replace`, gleiche Signatur): wahr, wenn die Person in einem für den Nutzer lesbaren Einsatz (`ez_can_read(referat_id)`) als Anwesenheit, organisierende Person, `created_by_person_id` oder `updated_by_person_id` vorkommt. Abweichung von der Beschreibung in spec.md AD v0.8 (dort zusätzlich Gruppen und Aktive der Referate): nicht nötig, weil Namen vor dem Speichern über `gr_group_roster` und `ea_search_active_persons` kommen (Datensparsamkeit).

Lesen:
- `ez_list_events(p_from date, p_to date, p_referat uuid default null, p_group uuid default null, p_kind ez_event_kind default null, p_limit int default 50, p_offset int default 0) returns setof (…)` – Zeilen aus `ez_v_events`, für die `ez_can_read` gilt, plus `group_name`; Filter auf start_date (bei mehrtägigen zählt der Beginn); Sortierung start_date desc, start_time desc; p_limit 1–200. Zusätzlich `total_count` je Zeile (für Paginierung).
- `ez_get_event(p_id uuid) returns jsonb` – Einsatz mit Gruppenname, Ortsname, Anwesenheiten (id, person_id, role, status, is_substitute), Probetrainings; Fehler `EZ_NOT_FOUND`, wenn nicht vorhanden oder nicht lesbar (keine Unterscheidung, damit keine Existenz verraten wird). Namen holt das Frontend über `ea_person_names`.
- `ez_climbing_points_report(p_location uuid, p_from date, p_to date) returns setof (event_id uuid, start_date date, start_time time, group_name text, participants_present int, trial_count int)` – nur Trainings am Ort mit `has_climbing_points = true` und lesbarem Referat; keine Namen (US-EZ-16). Fehler `EZ_LOCATION_NO_POINTS`, wenn der Ort das Kennzeichen nicht hat.

Schreiben (direkte Insert/Update/Delete auf `ez_`-Tabellen sind für `authenticated` nicht erlaubt; alle Schreibvorgänge laufen über diese Funktionen):
- `ez_save_event(p_event jsonb, p_attendances jsonb, p_trials jsonb, p_confirm_duplicate boolean default false) returns uuid` – legt an (ohne `id`) oder ändert (mit `id`), in einer Transaktion:
  1. Rechte: Anlegen nur mit `ez_can_write(referat)`; das Referat ist bei Einsätzen mit Gruppe das Referat der Gruppe (über `gr_groups_for_attendance`), sonst `p_event.referat_id`. Ändern nur, wenn `ez_can_write` für das gespeicherte Referat gilt. Sonst `EZ_FORBIDDEN`.
  2. Idempotenz: existiert ein Einsatz mit gleicher `client_request_id`, gibt die Funktion dessen id zurück, ohne zu schreiben (US-EZ-18 AK2).
  3. Unveränderliche Felder beim Ändern: kind, group_id, referat_id → `EZ_FIELD_LOCKED` (R19). `span` (eintägig/mehrtägig) bleibt änderbar [ANNAHME]; die Form wird erneut geprüft.
  4. Form nach `ez_events_shape`, Längen, R2, Ende nach Beginn → Fehlercodes aus Abschnitt 5.
  5. Ort aktiv (nur bei Anlage oder Änderung des Orts) → `EZ_LOCATION_INACTIVE` (R12).
  6. Organisierende Person mit Ehrenamtsstatus „aktiv“ (nur bei Anlage oder Änderung) → `EZ_ORGANIZER_NOT_ACTIVE` (R11).
  7. Anwesenheiten (`p_attendances`: Liste von {person_id, role, status}) ersetzen die gespeicherten vollständig (fehlende werden gelöscht, vorhandene aktualisiert, neue angelegt). Prüfungen: R17 (`EZ_DUPLICATE_PERSON`); Teilnehmer:innen müssen am start_date laut `gr_group_roster(group_id, start_date)` Teilnehmer:in der Gruppe sein (`EZ_PARTICIPANT_NOT_IN_GROUP`); Trainer:innen und Helfer:innen müssen laut Roster eine Funktion in der Gruppe haben oder Ehrenamtsstatus „aktiv“ haben (`EZ_PERSON_NOT_ACTIVE`; beim Ändern bleiben bereits gespeicherte Personen erlaubt); `is_substitute` = nicht als Gruppenleitung/Trainer:in/Helfer:in im Roster; Status `registered` nur beim Arbeitseinsatz (`EZ_STATUS_NOT_ALLOWED`); Rolle Teilnehmer:in nicht beim Arbeitseinsatz.
  8. R5 Mindestbesetzung (nicht beim Arbeitseinsatz) → `EZ_MIN_ATTENDANCE`.
  9. Probetrainings (`p_trials`: Liste von Vornamen) ersetzen die gespeicherten; R6.
  10. R8 Doppelte Erfassung: gibt es einen anderen Einsatz mit gleicher Gruppe, gleichem start_date und gleicher Einsatzart und ist `p_confirm_duplicate = false`, dann Fehler `EZ_DUPLICATE_EVENT` mit Detail `existing_id` nur, wenn der vorhandene Einsatz lesbar ist (US-EZ-17 AK4).
  11. Audit: created_* bei Anlage, updated_* bei Änderung (Trigger).
- `ez_delete_event(p_id uuid)` – nur `ez_can_delete()`, sonst `EZ_DELETE_FORBIDDEN`; löscht Einsatz mit Anwesenheiten und Probetrainings (cascade); Personen bleiben (R15).
- `ez_create_helper(p_event uuid, p_first text, p_last text, p_preferred text default null, p_email text default null) returns uuid` – nur für Arbeitseinsätze (`EZ_KIND_NOT_ALLOWED`) mit `ez_can_write(referat)`; ruft `ea_create_volunteer` mit der Eigenschaftsart `system_key = 'function'` und dem Wert Helfer:in in `p_field_values` [ANNAHME: Feldschlüssel legt die erste EA-Migration fest], Referat des Einsatzes, `p_valid_from = start_date`, `p_contact_email`; legt die Anwesenheit (Rolle Helfer:in, Status `present`) an; gibt die person_id zurück. Fehler aus `ea_create_volunteer` werden durchgereicht (R45 der Administration). Die Dublettenprüfung ruft das Frontend vorher über `ad_find_similar_persons` auf.

Trigger:
- `ez_events_before_insert`: setzt `referat_id` aus der Gruppe (ignoriert den gelieferten Wert), `created_by_person_id`.
- `ez_events_before_update`: verhindert Änderung von kind, group_id, referat_id, created_* (`EZ_FIELD_LOCKED`); setzt updated_*.
- `ez_attendances_set_audit`: created_*/updated_*.

## 3. Rechte / RLS

Grundsatz: Lesen per RLS über `ez_can_read`; Schreiben nur über die Funktionen aus Abschnitt 2 (keine Insert/Update/Delete-Policies, keine Grants dafür). Namen von Personen nie direkt aus `ea_persons`, nur über `ea_person_names` (Bedingung `ez_person_visible`), `ea_search_active_persons` und `gr_group_roster` (R44 der Administration).

| Rechtevorlage (Startwert) | Lesen | Anlegen | Ändern | Löschen | Personen anlegen (Arbeitseinsatz) |
|---|---|---|---|---|---|
| Admin (EZ lesen, alle) | alle Einsätze | – | – | – | – |
| Geschäftsstelle (EZ verwalten, alle) | alle | ja | ja | ja | ja |
| Referent:in (EZ bearbeiten, Referat) | Einsätze ihrer Referate | nur für ihre Referate (Gruppen ihrer Referate bzw. Arbeitseinsatz mit ihrem Referat) | Einsätze ihrer Referate | – | ja, für ihre Referate |
| Vorstand (Startwert ohne Rechte) | – (mit „EZ lesen“ vom Admin: alle) | – | – | – | – |
| Gruppenleitung / Trainer:in | Iteration 1 (Reichweite „Gruppe“) | | | | |

| Tabelle / Objekt | Lesen | Anlegen | Ändern | Löschen |
|---|---|---|---|---|
| ez_events | `ez_can_read(referat_id)` | `ez_save_event` | `ez_save_event` | `ez_delete_event` |
| ez_attendances | Einsatz lesbar | `ez_save_event`, `ez_create_helper` | `ez_save_event` | `ez_save_event` (Ersetzen), cascade |
| ez_trial_participants | Einsatz lesbar | `ez_save_event` | `ez_save_event` | `ez_save_event`, cascade |

Gruppen und Anwesenheitslisten: über `gr_groups_for_attendance`, `gr_group_roster`, `gr_my_groups` (Rechteprüfung in Gruppen). Orte: `ad_locations` (lesbar mit aktivem Zugang). Referate: `ea_referate`.

Routenschutz: `/ez/*` ohne `ad_has_any_level('EZ','read')` → /kein-zugriff. Schaltflächen „Neuer Einsatz“, „Bearbeiten“ nur bei `ad_has_any_level('EZ','edit')` bzw. `ez_can_write(referat)` des Einsatzes; „Löschen“ nur bei `ad_has_level('EZ','manage')`.

## 4. Zustände und Übergänge

Einsatz: nur „erfasst“ (keine Freigabe im MVP). Löschen entfernt den Einsatz endgültig (nur Geschäftsstelle).

Anwesenheit:

| Von | Nach | Wer | Bedingung |
|---|---|---|---|
| – | anwesend | Nutzer mit Schreibrecht | Ankreuzen bei Training, Fahrt, Wettkampfbegleitung; Hinzufügen beim Arbeitseinsatz vor Ort; neue Person beim Arbeitseinsatz |
| – | eingetragen | Nutzer mit Schreibrecht | nur Arbeitseinsatz (vorab gemeldet) |
| eingetragen | anwesend / nicht erschienen | Nutzer mit Schreibrecht | Arbeitseinsatz; „alle anwesend“ setzt nur „eingetragen“ → „anwesend“ |
| anwesend / nicht erschienen | eingetragen / anwesend / nicht erschienen | Nutzer mit Schreibrecht | Korrektur beim Arbeitseinsatz |
| anwesend | (entfernt) | Nutzer mit Schreibrecht | Haken entfernen bzw. Person entfernen (Korrektur) |

## 5. Geschäftsregeln

R1–R12 aus 01-erhebung.md, R13–R18 aus 02-stories.md, hier mit Meldung und Fehlercode; R19–R21 neu.

- R1 Pflichtfelder je Einsatzart (Tabelle `ez_events_shape`): Wenn ein Pflichtfeld fehlt, dann „Bitte ‚<Feld>‘ angeben.“ (`EZ_FIELD_REQUIRED`, Detail: Feld). Feldnamen: Gruppe, Referat, Titel, Organisierende Person, Datum, Startdatum, Enddatum, Beginn, Ende, Dauer, Ort.
- R2: Wenn bei mehrtägigen Einsätzen das Enddatum nicht nach dem Startdatum liegt, dann „Das Enddatum muss nach dem Startdatum liegen. Für eintägige Einsätze bitte ‚eintägig‘ wählen.“ (`EZ_END_DATE`).
- R3: Eintägige Einsätze außer Training speichern keine Uhrzeiten, nur die Dauer „unter 8 Stunden“ / „mindestens 8 Stunden“.
- R4: Beginn und Ende mehrtägiger Einsätze sind Abfahrt und Rückkehr am Startort; Hinweise am Feld „Abfahrt am Startort“ / „Rückkehr am Startort“.
- R5: Bei Training, Fahrt und Wettkampfbegleitung mindestens eine anwesende Person mit Rolle Trainer:in oder Helfer:in; bei Training zusätzlich mindestens eine anwesende Teilnehmer:in. Sonst Training: „Bitte mindestens eine Trainer:in oder Helfer:in und eine Teilnehmer:in auswählen.“, andere: „Bitte mindestens eine Trainer:in oder Helfer:in auswählen.“ (`EZ_MIN_ATTENDANCE`). Gilt nicht beim Arbeitseinsatz.
- R6: Wenn das Probetraining leer oder länger als 30 Zeichen ist, dann „Bitte einen Vornamen eingeben.“ bzw. „Bitte höchstens 30 Zeichen eingeben.“ (`EZ_TRIAL_NAME`). Hinweis am Feld: „Nur Vorname eintragen.“
- R7: Bemerkung optional, höchstens 500 Zeichen, sonst „Die Bemerkung darf höchstens 500 Zeichen haben.“ (`EZ_REMARK_LENGTH`). Hinweis am Feld: „Keine Angaben zu Gesundheit oder anderen sensiblen Daten von Kindern.“
- R8: Wenn für dieselbe Gruppe, dasselbe Datum (start_date) und dieselbe Einsatzart schon ein Einsatz besteht, dann Rückfrage „Für diese Gruppe ist an diesem Tag bereits ein Einsatz dieser Art erfasst. Trotzdem speichern?“ (`EZ_DUPLICATE_EVENT`); „Trotzdem speichern“ ruft erneut mit `p_confirm_duplicate = true` auf. Link zum vorhandenen Einsatz nur, wenn lesbar.
- R9: „Erfasst von/am“ und „geändert von/am“ setzt das System; nicht änderbar.
- R10: Bezeichnungen der Einsatzarten in der Oberfläche: Training, Tagesausflug, Mehrtagesfahrt, Ausbildungsfahrt, Wettkampfbegleitung, Arbeitseinsatz (später Kurs, Tour, Trainingslager).
- R11: Die organisierende Person muss beim Setzen Ehrenamtsstatus „aktiv“ haben, sonst „Bitte eine aktive Person auswählen.“ (`EZ_ORGANIZER_NOT_ACTIVE`). Auswahl per Suche ab 2 Zeichen; bei gewählter Gruppe stehen deren Gruppenleitung, Trainer:innen und Helfer:innen (aus dem Roster) oben.
- R12: Nur aktive Orte wählbar; beim Speichern eines inaktiven Orts „Dieser Ort ist nicht mehr aktiv. Bitte einen anderen Ort wählen.“ (`EZ_LOCATION_INACTIVE`). Gespeicherte Einsätze behalten einen inzwischen inaktiven Ort.
- R13: Referent:innen sehen, legen an und ändern nur Einsätze ihrer Referate; bei Einsätzen mit Gruppe gilt das Referat der Gruppe. Sonst „Für diesen Bereich hast du keine Rechte.“ (`EZ_FORBIDDEN`); nicht lesbare Einsätze erscheinen als „Einsatz nicht gefunden.“ (`EZ_NOT_FOUND`).
- R14: Admin und Vorstand (mit „EZ lesen“) lesen nur; Schreibversuche → `EZ_FORBIDDEN`.
- R15: Löschen nur mit „EZ verwalten“, nach Rückfrage „Einsatz und alle Anwesenheiten löschen?“; sonst `EZ_DELETE_FORBIDDEN` („Du darfst Einsätze nicht löschen.“). Anwesenheiten und Probetrainings werden mitgelöscht, Personen nicht.
- R16: Die Anwesenheitsliste zeigt Teilnehmer:innen mit gültiger Teilnahme und Gruppenleitung, Trainer:innen, Helfer:innen mit gültiger Funktion am start_date (Stichtag; mehrtägig = Startdatum). Teilnehmer:innen anderer Gruppen können nicht hinzugefügt werden: „Diese Person ist an diesem Tag nicht Teilnehmer:in der Gruppe.“ (`EZ_PARTICIPANT_NOT_IN_GROUP`).
- R17: Eine Person steht je Einsatz höchstens einmal in der Anwesenheit, sonst „Diese Person ist bereits eingetragen.“ (`EZ_DUPLICATE_PERSON`). Ist eine Person in der Gruppe Teilnehmer:in und Helfer:in, zeigt die Liste sie einmal mit der Rolle aus der Funktion (Helfer:in) vorbelegt; die Rolle ist änderbar.
- R18: Vorschlag der eigenen Gruppe nach `gr_my_groups(start_date)`: genau eine eigene, für den Nutzer beschreibbare Gruppe → vorausgewählt; mehrere → oben in der Auswahl, vorausgewählt die eine, deren Trainingszeit auf den Wochentag fällt [ANNAHME], sonst keine. Der Vorschlag gibt keine Rechte; wählbar sind nur Gruppen aus `gr_groups_for_attendance` mit `ez_can_write(referat_id)`.
- R19 (neu): Einsatzart, Gruppe und Referat sind nach dem Speichern nicht änderbar (bestätigt 22.10.2026; Referat beim Arbeitseinsatz [ANNAHME]); „Einsatzart, Gruppe und Referat können nicht geändert werden. Bitte den Einsatz löschen lassen und neu erfassen.“ (`EZ_FIELD_LOCKED`).
- R20 (neu): Trainer:innen und Helfer:innen ohne Funktion in der Gruppe am Stichtag (Vertretungen, Personen beim Arbeitseinsatz) müssen beim Hinzufügen Ehrenamtsstatus „aktiv“ haben, sonst „Bitte eine aktive Person auswählen.“ (`EZ_PERSON_NOT_ACTIVE`).
- R21 (neu): Status „eingetragen“ gibt es nur beim Arbeitseinsatz (`EZ_STATUS_NOT_ALLOWED`); die Rolle Teilnehmer:in gibt es beim Arbeitseinsatz nicht (`EZ_ROLE_NOT_ALLOWED`, „Beim Arbeitseinsatz gibt es keine Teilnehmer:innen.“). Kurs, Tour und Trainingslager sind im MVP nicht anlegbar (`EZ_KIND_NOT_AVAILABLE`).
- Längen: Titel 1–60 Zeichen, sonst „Bitte einen Titel mit höchstens 60 Zeichen eingeben.“ (`EZ_TITLE_LENGTH`). Training: Ende nach Beginn, sonst „Das Ende muss nach dem Beginn liegen.“ (`EZ_END_TIME`).
- Weitere Meldungen: Netzfehler „Die Eingabe wurde nicht gesendet. Bitte bei Verbindung erneut speichern.“; Sitzung abgelaufen „Bitte erneut anmelden.“; Löschen fehlgeschlagen „Der Einsatz konnte nicht gelöscht werden. Bitte erneut versuchen.“; Suche ohne Treffer „Keine aktive Person gefunden.“; unerwartet „Etwas ist schiefgelaufen. Bitte versuche es erneut.“

Fehlercodes neu: `EZ_FORBIDDEN`, `EZ_NOT_FOUND`, `EZ_DELETE_FORBIDDEN`, `EZ_FIELD_REQUIRED`, `EZ_FIELD_LOCKED`, `EZ_END_DATE`, `EZ_END_TIME`, `EZ_TITLE_LENGTH`, `EZ_TRIAL_NAME`, `EZ_REMARK_LENGTH`, `EZ_LOCATION_INACTIVE`, `EZ_LOCATION_NO_POINTS`, `EZ_ORGANIZER_NOT_ACTIVE`, `EZ_PERSON_NOT_ACTIVE`, `EZ_PARTICIPANT_NOT_IN_GROUP`, `EZ_DUPLICATE_PERSON`, `EZ_DUPLICATE_EVENT`, `EZ_MIN_ATTENDANCE`, `EZ_STATUS_NOT_ALLOWED`, `EZ_ROLE_NOT_ALLOWED`, `EZ_KIND_NOT_AVAILABLE`, `EZ_KIND_NOT_ALLOWED`. Ergänzung in `docs/specs/ad-administration/contracts/error-codes.md` (gemeinsame Liste) mit deutschem Text je Code.

## 6. Screens und Interaktionen

Allgemein wie Administration: deutsch, „du“, Datum TT.MM.JJJJ, Zeit HH:MM, shadcn/ui, ab 375 px ohne horizontales Scrollen; Namen „Rufname Nachname“, sonst „Vorname Nachname“. Startseite: Kachel „Anwesenheitserfassung“ über `ad_my_modules` (mit `is_available`).

| Route | Zeigt | Aktionen | Leer / Fehler | Story |
|---|---|---|---|---|
| /ez | Liste: Datum bzw. Zeitraum („07.–09.11.2026“), Einsatzart, Gruppe oder Titel, Referat, Anzahl anwesend je Rolle (z. B. „2 T · 1 H · 9 TN“); Filter Zeitraum (Standard: aktuelles Halbjahr; Auswahl „1. Halbjahr JJJJ“, „2. Halbjahr JJJJ“, frei), Referat (nur lesbare), Gruppe, Einsatzart; 50 je Seite; mobil als Karten | Neuer Einsatz; Einsatz öffnen | „Keine Einsätze gefunden.“ | US-EZ-14, -15 |
| /ez/neu | Schritt 1: Einsatzart als große Schaltflächen (Training, Tagesausflug, Mehrtagesfahrt, Ausbildungsfahrt, Wettkampfbegleitung, Arbeitseinsatz). Schritt 2: Formular je Einsatzart (unten). Schritt 3 (gleiche Seite, unter dem Formular): Anwesenheit | Speichern; Abbrechen | Fehler je Feld; R8-Rückfrage | US-EZ-01, -05, -06, -08, -09, -19 |
| /ez/:id | Kopf (Einsatzart, Gruppe/Titel, Referat, Zeiten, Ort, organisierende Person, Bemerkung, erfasst von/am, geändert von/am), Anwesenheit nach Rolle mit Stand und Kennzeichen „Vertretung“, Probetrainings | Bearbeiten; Löschen (nur Geschäftsstelle, mit Rückfrage); beim Arbeitseinsatz direkt „anwesend“/„nicht erschienen“ je Person, „alle anwesend“, „Person hinzufügen“, „Neue Person anlegen“ | „Einsatz nicht gefunden.“ | US-EZ-10, -12, -13, -15 |
| /ez/:id/bearbeiten | wie /ez/neu Schritt 2–3, Einsatzart und Gruppe nur angezeigt | Speichern | wie oben | US-EZ-12 |
| /ez/kletterhalle | Ort (nur aktive und inaktive Orte mit Punktekonto), Zeitraum (Standard: Vormonat); Tabelle je Training: Datum, Beginn, Gruppe, anwesende Teilnehmer:innen, Probetrainings; Summenzeile | – | „Keine Trainings im Zeitraum.“ | US-EZ-16 |

Formular je Einsatzart:
- **Training:** Gruppe (Auswahl, eigene Gruppe vorbelegt nach R18, eigene Gruppen oben) → Datum (Standard heute) → Beginn/Ende (aus `training_times` des Rosters für den Wochentag vorbelegt; bei keiner Trainingszeit leer; bei mehreren Trainingszeiten am Wochentag die erste, Auswahl der anderen per Knopf) → Ort (Auswahlfeld „Ort“ der Administration) → Anwesenheit → Probetraining (Liste, „Probetraining hinzufügen“) → Bemerkung.
- **Tagesausflug:** Gruppe → Titel → Organisierende Person → Datum → Dauer (zwei Optionen) → Anwesenheit → Bemerkung.
- **Mehrtagesfahrt:** Gruppe → Titel → Organisierende Person → Startdatum, Beginn („Abfahrt am Startort“) → Enddatum, Ende („Rückkehr am Startort“) → Anwesenheit → Bemerkung.
- **Ausbildungsfahrt, Wettkampfbegleitung:** zuerst „eintägig“ / „mehrtägig“, dann wie Tagesausflug bzw. Mehrtagesfahrt; Wettkampfbegleitung ohne organisierende Person.
- **Arbeitseinsatz:** Referat (nur beschreibbare; bei genau einem vorausgewählt) → Titel → eintägig/mehrtägig → Zeiten → Personen eintragen (Suche „Aktive“, Rolle Helfer:in vorbelegt und änderbar, Status „eingetragen“) → Bemerkung.

Anwesenheit (Training, Fahrt, Wettkampfbegleitung):
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
| Touren und Kurse | – | später Übernahme geplanter Kurse/Touren [OFFEN] |
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
| 1 | Training, Gruppe Test Klettern | 13.10.2026, 17:00–19:00, Kletterhalle Test | Toni Muster (Trainer:in), 5 Teilnehmer:innen; Probetraining „Lena“ | Normalfall, Kontrollliste |
| 2 | Training, Gruppe Test Klettern | 20.10.2026, 17:00–19:00, Kletterhalle Test | Karl Zweireferat (Helfer:in, Vertretung), 4 Teilnehmer:innen | Vertretung, Summe Kontrollliste |
| 3 | Training, Gruppe Test Jugend | 14.10.2026, 16:30–18:00, Fels Test | Trainer:in der Gruppe, 3 Teilnehmer:innen | anderes Referat: für Rita nicht sichtbar |
| 4 | Tagesausflug „Boulderfelsen“, Gruppe Test Klettern | 03.10.2026, mindestens 8 Stunden, organisiert von Toni Muster | 2 Trainer:innen, 6 Teilnehmer:innen | eintägig |
| 5 | Mehrtagesfahrt „Elbsandstein“, Gruppe Test Jugend | 07.11.2026 16:00 – 09.11.2026 18:30, organisiert von Karl Zweireferat | 2 Trainer:innen, 8 Teilnehmer:innen | mehrtägig, Stichtag |
| 6 | Wettkampfbegleitung „Jugendcup Test“, Gruppe Test Klettern | 24.10.2026, unter 8 Stunden | 1 Trainer:in, 3 Teilnehmer:innen | ohne organisierende Person |
| 7 | Arbeitseinsatz „Aufbau Test-Cup“, Referat Klettern | 17.10.2026, mindestens 8 Stunden | 3 eingetragen, 2 anwesend, 1 nicht erschienen | Stände |
| 8 | Ausbildungsfahrt mehrtägig „Alpinfahrt Test“, Gruppe Test Klettern | 01.08.2026 08:00 – 08.08.2026 20:00 | 1 Trainer:in, 1 Helfer:in, 4 Teilnehmer:innen | 2. Halbjahr 2026; Stichtag: eine Teilnehmerin mit Eintrittsdatum 01.09.2026 erscheint nicht in der Anwesenheitsliste und wird beim Speichern mit `EZ_PARTICIPANT_NOT_IN_GROUP` abgelehnt |

Erwartete Sichtbarkeit (Grundlage pgTAP T9):

| Testzugang | sieht Einsätze | darf schreiben | darf löschen |
|---|---|---|---|
| Admin (EZ lesen) | 1–8 | nein | nein |
| Geschäftsstelle (EZ verwalten) | 1–8 | alle | ja |
| Referent:in Klettern | 1, 2, 4, 6, 7, 8 | diese | nein |
| Vorstand (ohne EZ) | keine | nein | nein |

Zusätzlich: `ez_person_visible` für Rita liefert Namen der Personen aus 1, 2, 4, 6, 7, 8, nicht die Teilnehmer:innen aus 3 und 5; `ez_climbing_points_report(Kletterhalle Test, 01.10.2026, 31.10.2026)` liefert 2 Zeilen mit 5 und 4 Teilnehmer:innen und 1 bzw. 0 Probetrainings.

## 10. Umsetzungs-Tasks

Voraussetzung: Administration T50–T58, Gruppen US-GR-18 bis US-GR-20 (inkl. `gr_groups_for_attendance`).

- [ ] T1: Migration Typen und Tabellen: Enums, `ez_events` mit Check `ez_events_shape` und `ez_events_kind_mvp`, `ez_attendances`, `ez_trial_participants`, Indizes, RLS an, Select-Policies, keine Schreib-Grants (US-EZ-01, -05, -06, -08, -09)
- [ ] T2: Migration Rechte- und Sichtbarkeitsfunktionen: `ez_can_read`, `ez_can_write`, `ez_can_delete`, `ez_person_visible` (ersetzt Platzhalter) (US-EZ-14, -15, R13, R14)
- [ ] T3: Migration Trigger: Referat aus Gruppe, Audit inkl. `*_person_id`, Sperre unveränderlicher Felder (R9, R19)
- [ ] T4: Migration `ez_save_event` mit allen Prüfungen aus Abschnitt 2 (Schritte 1–11) und Fehlercodes (US-EZ-01 bis -12, -17, -18)
- [ ] T5: Migration `ez_delete_event`, `ez_create_helper` (US-EZ-11, -13)
- [ ] T6: Migration Lesefunktionen `ez_list_events`, `ez_get_event`, `ez_climbing_points_report`, View `ez_v_events` (US-EZ-14, -15, -16)
- [ ] T7: Fehlercodes in contracts/error-codes.md (Abschnitt 5)
- [ ] T8: Seed nach Abschnitt 9 (US-EZ alle)
- [ ] T9: pgTAP: Sichtbarkeitsmatrix Abschnitt 9; jede Regel R1–R21 mit mindestens einem Fehlerfall; Idempotenz `client_request_id`; Stichtag (Einsatz 8); direkte Insert/Update/Delete auf `ez_`-Tabellen abgelehnt; `ez_person_visible` nur Namen lesbarer Einsätze; Mengentest Abschnitt 8
- [ ] T10: Frontend Liste /ez mit Filtern und Paginierung (US-EZ-14, -15)
- [ ] T11: Frontend Formular Einsatzart-Auswahl und Formulare je Einsatzart inkl. Gruppenvorschlag (R18) und Vorbelegung der Zeiten (US-EZ-01, -05, -06, -08, -09, -19)
- [ ] T12: Frontend Anwesenheitsliste aus `gr_group_roster`, Vertretung, Probetraining, Bemerkung (US-EZ-02, -03, -04)
- [ ] T13: Frontend organisierende Person (US-EZ-07)
- [ ] T14: Frontend Detail /ez/:id inkl. Arbeitseinsatz-Stände, „alle anwesend“, neue Person anlegen (US-EZ-10, -11), Bearbeiten (US-EZ-12), Löschen (US-EZ-13)
- [ ] T15: Frontend Doppel-Warnung, Entwurf im Browser, Netzfehler (US-EZ-17, -18)
- [ ] T16: Frontend Kontrollliste /ez/kletterhalle (US-EZ-16)
- [ ] T17: Abnahme in TEST mit den Testzugängen auf dem Telefon (375 px): Admin, Geschäftsstelle, Referent:in, Vorstand; danach `ad_modules.is_available = true` für EZ per Migration (Freigabe durch den Product Owner)

## 11. Annahmen und offene Punkte

Bestätigt vom Product Owner (21./22.10.2026): Modulname und Kürzel; Einsatzarten und Bezeichnungen wie im Forms-Formular; Erfassung je Gruppe; Kinder mit Vor- bzw. Rufname und Nachname; organisierende Person aus allen Aktiven; Zeiten eintägig über Dauer-Kategorie, mehrtägig mit Start und Ende (ab Startort); Orte als Stammdaten, nur Admin pflegt, Startliste bei der Umsetzung; Kontrolle Punktekonto nur Kinder; Löschen nur Geschäftsstelle; Einsatzart und Gruppe nicht änderbar; Standardrolle Helfer:in beim Arbeitseinsatz; keine organisierende Person bei der Wettkampfbegleitung; Stichtag (mehrtägig: Startdatum); Feldlängen; Vorschlag der eigenen Gruppe ohne Rechte; kein Offline-Betrieb.

Annahmen (bei Abnahme bestätigen):
- [ANNAHME] Schreiben nur über Datenbankfunktionen (keine direkten Insert/Update-Policies); fachlich keine Auswirkung.
- [ANNAHME] Wettkampfbegleitung nur mit Gruppe.
- [ANNAHME] Referat beim Arbeitseinsatz nach dem Speichern nicht änderbar (wie Gruppe).
- [ANNAHME] „Eintägig/mehrtägig“ (span) nach dem Speichern änderbar, weil es nur die Zeitangaben betrifft; Prüfung der Form erneut.
- [ANNAHME] Gruppenleitung erscheint in der Anwesenheit mit Rolle Trainer:in vorbelegt.
- [ANNAHME] Probetrainings in der Oberfläche nur beim Training.
- [ANNAHME] R5 nur Trainer:in/Helfer:in bei Fahrten und Wettkampfbegleitung; Teilnehmer:in nur beim Training Pflicht.
- [ANNAHME] Neue Person beim Arbeitseinsatz erst nach dem ersten Speichern des Einsatzes (Referat und Datum stehen dann fest).
- [ANNAHME] Dublettentreffer, die nicht aktiv sind, können nicht direkt eingetragen werden (Hinweis an die Geschäftsstelle); Reaktivierung im Ehrenamtsmanagement.
- [ANNAHME] Liste Standard aktuelles Halbjahr; 50 je Seite.
- [ANNAHME] Vorauswahl bei mehreren eigenen Gruppen über den Wochentag der Trainingszeit.
- [ANNAHME] Mengengerüst und Antwortzeiten aus Abschnitt 8.
- [ANNAHME] `ez_person_visible` enger als in spec.md AD v0.8 beschrieben (nur Personen gespeicherter, lesbarer Einsätze).
- [ANNAHME] Namen der Testgruppen werden an den Seed Gruppen angepasst.

Offen (kein Blocker für den MVP):
- [OFFEN] Übernahme von Kursen und Touren aus dem Modul Touren und Kurse; danach Stories und Freigabe der Einsatzarten Kurs, Tour, Trainingslager.
- [OFFEN] Löschfrist der Einsätze und Anwesenheiten (mit Finanzen; Aufbewahrung für Abrechnung).
- [OFFEN] Information nach Art. 13 DSGVO an Personen, die beim Arbeitseinsatz angelegt werden.
- [OFFEN] Sperre nach Abgabe des Halbjahres (Finanzen).
