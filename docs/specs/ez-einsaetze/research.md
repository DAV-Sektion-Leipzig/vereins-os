# Research: Anwesenheitserfassung (EZ)

Stand: 24.10.2026 · Grundlage: [spec.md](spec.md) v0.5, Repository `main` @ 71eb204

Keine `NEEDS CLARIFICATION` im Technical Context. Fachliche Lücken stehen als O1–O4 in [plan.md](plan.md). Hier stehen nur technische Entscheidungen.

## R-EZ-01 Migrationen: Schnitt und Nummern

- **Decision:** Sechs Migrationen ab `20261028000100`, geschnitten nach den Spec-Tasks (Liste in [data-model.md](data-model.md), Abschnitt „Migrationen“). Freischalten (T17) und Anbindung der Planungshilfe (T19) folgen als eigene Migrationen.
- **Rationale:** Letzte Migration auf `main` ist `20261027000100`. Ein eigener Tag vermeidet Kollisionen mit parallelen Sitzungen (Gruppen, Administration). Rechtefunktionen `ez_can_*` hängen nicht von Tabellen ab und stehen deshalb in der ersten Migration vor den Policies; `ez_person_visible` braucht die Tabellen und folgt danach.
- **Alternatives considered:** Eine große Migration (schlecht prüfbar); Nummern direkt nach `…27000100` (Kollisionsgefahr mit Gruppen).

## R-EZ-02 `search_path` und Qualifizierung

- **Decision:** Alle Funktionen `set search_path = ''`, alle Namen voll qualifiziert.
- **Rationale:** Muster des Repositorys (AD research.md R-19, GR R-GR-02).

## R-EZ-03 Datum

- **Decision:** `date` und `time` ohne Zeitzone (spec.md 2). Die Datenbank braucht für EZ kein „heute“; der Standardwert „heute“ im Formular kommt aus dem Browser (Ortszeit). Stichtag ist immer `start_date` (R16).
- **Rationale:** spec.md 8 „Datum und Zeit ohne Zeitzone, immer Ortszeit Leipzig“.

## R-EZ-04 Schreiben nur über Funktionen, Fehler

- **Decision:** Auf `ez_`-Tabellen nur `grant select … to authenticated` und eine Select-Policy. Alle Schreibfunktionen `security definer`, erste Prüfung Rechte, dann Fachprüfungen, dann Schreiben, alles in einer Transaktion (eine Funktion = eine Transaktion). Fehler: `raise exception '<CODE>' using errcode = 'P0001', detail = …`. `detail` enthält bei `EZ_FIELD_REQUIRED` den Feldnamen aus R1 (z. B. `Titel`), bei `EZ_DUPLICATE_EVENT` die `existing_id` (nur wenn lesbar, sonst leer), bei `EZ_DUPLICATE_PERSON`, `EZ_PERSON_NOT_ACTIVE` und `EZ_PARTICIPANT_NOT_IN_GROUP` die `person_id`.
- **Rationale:** spec.md 2 und 3; Muster der Administration (`detail` für Platzhalter).
- **Alternatives considered:** Insert-Policies je Tabelle (Regeln doppelt, R16/R20 in Policies nicht abbildbar).

## R-EZ-05 Form je Einsatzart (R1–R3, R28)

- **Decision:** Check-Constraint `ez_events_shape` nach der Tabelle in spec.md 2 als Sicherung. `ez_save_event` prüft vorher in fester Reihenfolge (Gruppe/Referat, Titel, organisierende Person, Datum, Enddatum, Dauer, Ort) und meldet den ersten Fehler mit Code. Felder, die zur Einsatzart nicht gehören, setzt die Funktion auf `null` (z. B. `start_time` bei eintägigen Einsätzen, `title` beim Training); `span` setzt sie bei Training, Tagesausflug (`single`), Mehrtagesfahrt und Trainingslager (`multi`) selbst. Leere Strings gelten als `null`, Texte werden getrimmt.
- **Rationale:** Der Constraint hält die Form auch beim Schreiben als Eigentümer (Seed, spätere Planungshilfe) ein; die Funktion liefert die Meldungen für die Oberfläche. Normalisieren statt Ablehnen, weil die Oberfläche beim Wechsel „eintägig/mehrtägig“ Restwerte mitschicken kann.
- **Alternatives considered:** Nur Constraint (Meldung `23514` ohne Feld); Ablehnen überzähliger Felder (unnötige Fehler für Nutzer).

## R-EZ-06 Roster und Stichtag in `ez_save_event`

- **Decision:** Für Einsätze mit Gruppe ruft `ez_save_event` `gr_group_roster(group_id, start_date)` für die erste und jede weitere Gruppe auf und bildet daraus eine Menge (person_id, Rolle). Daraus:
  - R16: Teilnehmer:in muss mit Rolle `participant` in einer der Gruppen stehen (`EZ_PARTICIPANT_NOT_IN_GROUP`).
  - R20: Trainer:in/Helfer:in ohne Rolle `group_lead`/`trainer`/`helper` in einer der Gruppen braucht Ehrenamtsstatus `active` (`EZ_PERSON_NOT_ACTIVE`); beim Ändern bleiben bereits gespeicherte Personen erlaubt.
  - `is_substitute` = Rolle Trainer:in/Helfer:in und keine Funktion in einer der Gruppen.
  - Die wählbaren Gruppen prüft die Funktion vorher über `gr_groups_for_attendance(start_date)`; fehlt die Gruppe dort, gilt O1 (Vorschlag `EZ_FIELD_REQUIRED`, Feld „Gruppe“). `GR_ROSTER_FORBIDDEN` kann danach nicht mehr auftreten, weil `ez_can_write` ≥ `ez_can_read` gilt; tritt es doch auf, wird es als `EZ_FORBIDDEN` gemeldet.
- **Rationale:** spec.md 2 Schritt 7 verweist auf `gr_group_roster`; Gruppen bleibt die einzige Stelle für Teilnahmen und Funktionen. `security definer` ändert `auth.uid()` nicht, die Rechteprüfung des Rosters greift also für den aufrufenden Nutzer.
- **Alternatives considered:** Direkt `gr_memberships` und `ea_properties` lesen (doppelte Regel für den Stichtag, bricht bei Änderungen in Gruppen).

## R-EZ-07 Rechte und Referat

- **Decision:** `ez_can_read`, `ez_can_write`, `ez_can_delete` wie spec.md 2 (`stable`, `security definer`, Grant an `authenticated`). Referat bei Einsätzen mit Gruppe = `gr_groups_for_attendance.referat_id` der ersten Gruppe; der Trigger `ez_events_before_insert` setzt es zusätzlich aus `gr_groups`. Beim Ändern eines Einsatzes ohne Gruppe mit neuem Referat: `ez_can_write` für altes und neues Referat (R19).
- **Rationale:** Eine zentrale Stelle für Iteration 1 (Reichweite „Gruppe“).

## R-EZ-08 `ez_person_visible`

- **Decision:** `create or replace function public.ez_person_visible(p_person uuid) returns boolean` (`stable`, `security definer`, Grant bleibt). Wahr, wenn ein Einsatz mit `ez_can_read(referat_id)` existiert, in dem die Person in `ez_attendances`, als `organizer_person_id`, `created_by_person_id` oder `updated_by_person_id` vorkommt. Umsetzung als `exists` über eine `union all` der vier Wege, jeweils über Index auf der Personenspalte. Ohne EZ-Recht sofort `false` (`ad_has_any_level('EZ','read')`).
- **Rationale:** spec.md 2; `ea_person_names` ruft die Funktion je ID (≤ 500) auf. Der Schnellausstieg ohne Recht hält Nutzer ohne EZ (z. B. Vorstand) billig.
- **Hinweis:** `cancelled_by_person_id` braucht keinen eigenen Weg: Der Trigger setzt beim Absagen `updated_by_person_id` auf dieselbe Person.

## R-EZ-09 Audit

- **Decision:** `created_at`/`created_by` per Default (`now()`, `auth.uid()`), `created_by` `not null` (spec.md 2: Pflicht), ohne Fremdschlüssel auf `auth.users`, damit das Aufräumen von Testnutzern in TEST nicht an Einsätzen scheitert; angezeigt wird `created_by_person_id`. Trigger `ez_events_before_insert` setzt `created_by_person_id` über `ad_accesses.auth_user_id = auth.uid()`; `ez_events_before_update` setzt `updated_at`, `updated_by`, `updated_by_person_id`. `ez_attendances_set_audit` setzt `created_*`/`updated_*`. `cancelled_by`, `cancelled_by_person_id` setzt `ez_cancel_event`. Der Seed setzt für seinen Abschnitt den Nutzerkontext der Geschäftsstelle (`request.jwt.claims`), damit `created_by` gefüllt ist.
- **Rationale:** R9; Muster `ad_set_updated`. Ohne Nutzerkontext gäbe es keinen „erfasst von“.
- **Alternatives considered:** `created_by` nullable wie bei Gruppen (widerspricht spec.md 2).

## R-EZ-10 Unveränderliche Felder (R19, R25)

- **Decision:** Trigger `ez_events_before_update` meldet `EZ_FIELD_LOCKED` bei Änderung von `kind`, `group_id`, `tk_plan_id`, `client_request_id`, `created_*` und von `referat_id`, wenn `group_id` oder `tk_plan_id` gesetzt ist. `ez_save_event` prüft dieselben Felder vorher (Meldung vor dem Trigger) und zusätzlich: weitere Gruppen (Vergleich der Menge), abgesagt (`EZ_EVENT_CANCELLED`), Planungshilfe (`EZ_TK_MANAGED` bei jeder Änderung außer `remark`).
- **Rationale:** spec.md 2 Trigger und Schritt 3.

## R-EZ-11 Idempotenz (US-EZ-18)

- **Decision:** Nach der Rechteprüfung: gibt es einen Einsatz mit gleicher `client_request_id`, gibt die Funktion dessen `id` zurück, ohne zu schreiben – auch ohne Prüfung der übrigen Daten. Gleichzeitige Aufrufe: `insert` fängt `unique_violation` auf `ez_events_client_request_id_key` ab und gibt die vorhandene `id` zurück. Beim Ändern (mit `id`) wird `client_request_id` nicht geprüft.
- **Rationale:** spec.md 2 Schritt 2.

## R-EZ-12 Doppelte Erfassung (R8)

- **Decision:** Gleiche erste Gruppe (`group_id`), gleiches `start_date`, gleiche `kind`, `cancelled_at is null`, andere `id`. Gilt nur für Einsätze mit Gruppe. Prüfung als letzter Schritt vor dem Schreiben (Schritt 10), damit Formfehler zuerst gemeldet werden. `detail` = `existing_id`, wenn `ez_can_read` für den vorhandenen Einsatz gilt.
- **Rationale:** spec.md 2, R8; US-EZ-17 AK4.

## R-EZ-13 Lesen

- **Decision:**
  - View `ez_v_events` (`security_invoker = true`) mit Zählungen aus `ez_attendances` und `ez_trial_participants` per Unterabfrage.
  - `ez_list_events` als `security definer`, `stable`, liest `ez_v_events` mit Filter `ez_can_read(referat_id)`, ergänzt `group_name` (bei weiteren Gruppen „A + B“ in Reihenfolge erste Gruppe, dann Name), `referat_name`, `total_count` per `count(*) over ()`. `p_limit` außerhalb 1–200 wird auf 1–200 begrenzt, `p_offset` < 0 auf 0 (kein neuer Fehlercode).
  - `ez_get_event` als `security definer`, liefert jsonb nach [contracts/database-api.md](contracts/database-api.md).
  - `ez_climbing_points_report` als `security definer`: Trainings (`kind = 'training'`, nicht abgesagt, `ez_can_read`), Ort mit `has_climbing_points`.
- **Rationale:** spec.md 2 Views; `gr_groups` ist für Referent:innen ohne EA-/GR-Recht nicht lesbar. `security definer` mit ausdrücklichem Filter gibt nur, was `ez_can_read` erlaubt.
- **Alternatives considered:** Policy auf `gr_groups` für EZ (Änderung an Gruppen).

## R-EZ-14 Weitere Schreibfunktionen

- **Decision:**
  - `ez_create_helper`: Prüfungen in der Reihenfolge Einsatz lesbar (`EZ_NOT_FOUND`), Arbeitseinsatz (`EZ_KIND_NOT_ALLOWED`), `ez_can_write` (`EZ_FORBIDDEN`), abgesagt (`EZ_EVENT_CANCELLED`), Häkchen und `notice_version` 1–50 Zeichen (`EZ_PRIVACY_NOT_CONFIRMED`); dann `ea_create_volunteer(p_first, p_last, p_preferred, <Art function>, referat_id, '{"function": "Helfer:in"}', start_date, p_email)`, Anwesenheit (`helper`, `present`, `is_substitute = false`) und Zeile in `ez_privacy_confirmations`. Fehler aus `ea_create_volunteer` (z. B. `EA_*`) werden nicht umbenannt.
  - `ez_reactivate_helper`: wie oben bis `EZ_EVENT_CANCELLED`; Person `kind = 'human'`; `volunteer_status = 'active'` → `EZ_PERSON_NOT_INACTIVE`; schon im Einsatz → `EZ_DUPLICATE_PERSON`; dann `ea_activate_person(p_person, <Art function>, referat_id, '{"function": "Helfer:in"}', start_date)` und Anwesenheit.
  - `ez_cancel_event`, `ez_restore_event`, `ez_delete_event` nach spec.md 2.
- **Rationale:** spec.md 2; AD `ea_create_path` verlangt genau diese Werte für den EZ-Weg.

## R-EZ-15 pgTAP-Dateien

- **Decision:** 510 Struktur, RLS, Grants, direkte Schreibversuche; 520 Sichtbarkeitsmatrix spec.md 9 und `ez_person_visible`; 530 `ez_save_event` (R1–R12, R16–R21, R28, R30, Idempotenz, Stichtag); 540 Absage, Löschen, neue Helfer:innen (R15, R22–R24, R29, R31); 550 Lesefunktionen und Kontrollliste; 560 Einsätze aus der Planungshilfe (R25 mit im Test gesetztem `tk_plan_id`); 590 Mengentest.
- **Rationale:** AD 010–280, EA 310–390, GR 410–495.

## R-EZ-16 Seed

- **Decision:** Eigener Abschnitt „9. Anwesenheitserfassung“ am Ende von `supabase/seed.sql`, nach Orten und Gruppen. Zuordnung der Platzhalter aus spec.md 9: „Gruppe Test Klettern“ = „Klettergruppe Test“ (`c…03`, Referat Klettern), „Gruppe Test Jugend“ = „Jugendgruppe Test 1“ (`c…01`, Referat Kinder und Jugend). Ergänzt werden nur fiktive Daten mit festen Datumswerten:
  - Personen 33–50 (Kinder und Betreuer:innen, `created_in = 'GR'` bzw. `'AD'`), Teilnahmen in `c…03` ab 01.09.2025 (eine Teilnehmerin erst ab 01.09.2026, Einsatz 8) und `c…01` ab 01.09.2025;
  - Funktionen in Gruppen: Toni Muster (4) Trainer:in in `c…03`, Rita Referentin (9) Trainer:in in `c…03`, weitere Betreuer:innen; Trainingszeit Di 17:00–19:00 für `c…03` ab 01.09.2025;
  - Einsätze 1–11 mit UUIDs `f0000000-…-0000000000NN`, Anwesenheiten `f1…`, Probetraining `f2…`; Einsatz 11 mit `cancelled_at` und Grund „Wetter“.
  Der Abschnitt setzt `request.jwt.claims` auf die Geschäftsstelle (R-EZ-09) und schreibt als Eigentümer direkt in die Tabellen (die Trigger laufen mit).
- **Rationale:** spec.md 9 [bestätigt: Namen an den Seed Gruppen angepasst]. Feste Datumswerte, weil die Einsätze feste Daten haben (Oktober 2026); die relativen Daten des GR-Seeds würden den Stichtag-Test verschieben.
- **Folge für Tests (plan.md O3):** Die Tests 200 (Administration), 420 und 480 (Gruppen) zählen Seed-Zeilen exakt; der EZ-Seed ändert diese Zähler. Deshalb eigener Branch `ez-seed` (ohne Auto-Merge) mit Übergabe. Die EZ-Tests 520 ff. legen die Daten aus spec.md 9 in der Testtransaktion mit denselben UUIDs und `on conflict do nothing` an; sie laufen damit mit und ohne EZ-Seed.

## R-EZ-17 Oberfläche

- **Decision:** Feature-Ordner `src/features/ez` nach dem Muster von `src/features/gr` (Layout, `access.ts` mit `ad_has_any_level`, Loader in `react-router`). Schreiben über `supabase.rpc('ez_…')`, Lesen über `ez_list_events`, `ez_get_event`, `ez_climbing_points_report`, `gr_groups_for_attendance`, `gr_group_roster`, `gr_my_groups`, `ad_locations`, `ea_referate`, Namen über `ea_person_names`. Fehlercodes über `src/lib/errors.ts`. Darstellung: Datum über `formatDate()`, Namen über `personName()`, Tabellen über `ResponsiveTable`.
- **Schreibrecht je Referat im Frontend:** `ad_has_level('EZ','edit')` und `ad_my_referate('EZ','edit')` einmal beim Laden; daraus „beschreibbar“ für Gruppen und Referate (nur Anzeige, die Datenbank prüft selbst).
- **Rationale:** Wiederverwendung statt Kopie (Prinzip VI).

## R-EZ-18 Entwurf im Browser (US-EZ-18)

- **Decision:** `localStorage`-Schlüssel `ez-entwurf:<auth-user-id>` mit Feldwerten, Person-IDs, `client_request_id` und Zeitstempel, keine Namen. Geschrieben bei jeder Änderung (entprellt), gelöscht nach Erfolg, bei „Abbrechen“ und beim Abmelden (Listener `supabase.auth.onAuthStateChange` → `SIGNED_OUT` löscht alle Schlüssel `ez-entwurf:*`). Lesen und Schreiben in `try/catch`.
- **Rationale:** spec.md 6 und 8; ohne Änderung am gemeinsamen Layout.

## R-EZ-19 Anbindung der Planungshilfe (zurückgestellt)

- **Decision:** `tk_plan_id`, `from_plan`, `cancelled_*` und die Prüfungen `EZ_TK_MANAGED` werden jetzt gebaut (R25 gilt schon für `ez_save_event`, `ez_cancel_event`, `ez_restore_event`, `ez_delete_event`). `ez_upsert_planned_event`, `ez_cancel_planned_event`, `ez_planned_event_state` folgen mit TK T13 (Spec T19–T21).
- **Rationale:** spec.md Kopf; `tk_can_write` gibt es noch nicht.
