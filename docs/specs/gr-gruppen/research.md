# Research: Gruppen (GR)

Stand: 24.10.2026 · Grundlage: [spec.md](spec.md) v0.2, Repository `main` @ ada30f1

Keine `NEEDS CLARIFICATION` im Technical Context. Fachliche Lücken stehen als O1, O2 in [plan.md](plan.md). Hier stehen nur technische Entscheidungen.

## R-GR-01 Migrationen: Schnitt und Nummern

- **Decision:** Neun Migrationen ab `20261025000100`, geschnitten nach den Spec-Tasks (Liste in [data-model.md](data-model.md), Abschnitt „Migrationen“). T19 (Freischalten) folgt als eigene Migration nach der Abnahme.
- **Rationale:** `20261024000800` ist für EA T055 (Freischalten EA) vorgesehen. Ein neuer Tag vermeidet Kollisionen, auch wenn EA später freigeschaltet wird. Schnitt nach Tasks hält die Pull Requests prüfbar.
- **Alternatives considered:** Eine große Migration (schlecht prüfbar, ein Fehler blockiert alles); Nummern direkt nach `…000700` (Kollision mit EA T055).

## R-GR-02 `search_path` und Qualifizierung

- **Decision:** Alle Funktionen `set search_path = ''`, alle Namen voll qualifiziert (`public.…`, `extensions.…`).
- **Rationale:** So arbeitet das ganze Repository (AD research.md R-19). Schützt `security definer`-Funktionen gegen Objekte in fremden Schemas. spec.md 2.3 nennt `public`; fachlich ohne Wirkung (plan.md H3).
- **Alternatives considered:** `search_path = public` wie in der Spec (uneinheitlich, schwächer).

## R-GR-03 Datum „heute“

- **Decision:** `gr_today()` = `(now() at time zone 'Europe/Berlin')::date`, `stable`, Grant an `authenticated`. Alle GR-Funktionen und -Views nutzen sie. Funktionen der Administration (`ea_person_in_referate`, `ad_user_level` usw.) bleiben bei `current_date`.
- **Rationale:** spec.md 2 legt die Datumskonvention fest. Supabase läuft in UTC; zwischen 0 und 2 Uhr Berliner Zeit wäre `current_date` der Vortag. Die AD-Funktionen zu ändern gehört nicht zu Gruppen.
- **Alternatives considered:** `current_date` überall (falscher Tag nachts); AD-Funktionen mit umstellen (außerhalb des Scopes, eigener Auftrag).
- **Tests:** Erwartungen werden aus `gr_today()` berechnet, nicht aus festen Daten (Seed relativ zu `current_date`, spec.md 9 [ANNAHME bestätigt]).

## R-GR-04 Ü1: `ea_set_status_from_group`

- **Decision:** Interne Funktion `public.ea_set_status_from_group(p_person uuid, p_valid_from date) returns boolean` (true = Status gesetzt), `security definer`, `revoke all … from public, anon, authenticated`. Ändert nur bei `volunteer_status is null and kind = 'human'`: setzt `ea.status_change` transaktionslokal auf `on`, aktualisiert `volunteer_status = 'active'`, `volunteer_status_since = p_valid_from`, setzt das Kennzeichen zurück und schreibt `ea_volunteer_status_history`.
- **Rationale:** Gleiches Muster wie `ea_activate_person` (Migration `20261023001100`). Der Trigger `ea_persons_guard` lässt Statuswechsel mit diesem Kennzeichen zu; er muss nicht geändert werden. Ohne Grant ist die Funktion nur aus `security definer`-Funktionen desselben Eigentümers aufrufbar (Ü1).
- **Alternatives considered:** `ea_set_volunteer_status` aufrufen (verlangt Sichtbarkeit im Pfad EA, Ü1); Trigger um Ausnahme erweitern (unnötig).

## R-GR-05 Ü3: Gruppenbezug in `ad_v_person_overview`

- **Decision:** `gr_has_current_relation(p_person)` ohne Grant an `authenticated` (spec.md 2.3). Dazu eine Hülle `gr_person_has_group_relation(p_person) returns boolean`, `security definer`, Grant an `authenticated`: liefert `gr_has_current_relation(p_person)`, wenn `ad_has_level('AD','read')`, sonst `null`. `ad_v_person_overview` wird per `create or replace view` mit gleicher Spaltenliste neu angelegt; `has_group_relation` = `coalesce(public.gr_person_has_group_relation(p.id), false)`.
- **Rationale:** Die View hat `security_invoker = true`. Ruft sie `gr_has_current_relation` direkt, braucht der Aufrufer `execute` darauf. Damit könnte jeder angemeldete Nutzer für beliebige IDs abfragen, ob ein Gruppenbezug besteht. Die Hülle gibt das Kennzeichen nur Nutzern, die die Übersicht ohnehin lesen (AD ≥ lesen).
- **Alternatives considered:** Grant an `authenticated` (Informationsabfluss, widerspricht spec.md 2.3); View ohne `security_invoker` (widerspricht der Konvention der Administration).
- **Filter „nur Gruppen“:** Die Oberfläche der Administration filtert bereits über `has_group_relation`, `volunteer_status is null` und `access_status = 'none'` (`src/features/ad/personen/data.ts`). Keine Änderung im Frontend nötig.

## R-GR-06 Sichtbarkeit: `gr_person_visible` und `gr_person_ids`

- **Decision:**
  - `gr_person_visible(p_person, p_min)` per `create or replace` (gleiche Signatur, `security definer`, `stable`): `ad_has_level('GR', p_min) and Person kind = 'human' and gr_has_current_relation(p_person)`.
  - `gr_person_ids(p_min)` per `create or replace` mengenbasiert: bei fehlendem Recht leere Menge, sonst `union` der Personen-IDs der fünf Bezüge aus spec.md 2.3 (offene Aufnahme, laufende Teilnahme, Teilnehmer:in bzw. Vertragsinhaber:in nicht beendeter Verträge, Erziehungsberechtigte und Notfallkontakte solcher Kinder, laufende `group_function`), gefiltert auf `kind = 'human'`.
- **Rationale:** Die Policies auf `ea_persons`, `ea_properties` und `ea_volunteer_status_history` nutzen `gr_person_ids`. Die Platzhalter-Fassung ruft je Person `gr_person_visible` auf; das hält den Mengentest (500 Personen < 1 s) nicht sicher ein. Eine Menge wird je Abfrage einmal berechnet (AD research.md R-19).
- **Alternatives considered:** Platzhalter-Fassung behalten (Leistung); materialisierte Tabelle der Bezüge (Pflegeaufwand, Trigger auf sechs Tabellen).
- **Tests:** pgTAP prüft, dass `gr_person_ids` und `gr_person_visible` für alle Seed-Personen dasselbe Ergebnis liefern.

## R-GR-07 Ergänzungen an `ea_properties` (R38, R39, Ü7)

- **Decision:**
  - `alter table ea_properties add column related_group_id uuid references gr_groups(id) on delete restrict`, Index `where related_group_id is not null`; `ea_property_history.related_group_id uuid`; Spalte in die Insert-/Update-Grants von `ea_properties` aufnehmen ist **nicht** nötig (Schreiben nur über GR-Funktionen), daher kein neuer Spalten-Grant.
  - `ea_properties_validate` per `create or replace` (vollständige neue Fassung): neuer Zweig `relation_kind = 'group'` (genau `related_group_id`; `EA_RELATION_REQUIRED` bei Pflicht und leerem Bezug; `GR_GROUP_DISSOLVED`, wenn bei Insert oder Wechsel der Gruppe `dissolved_on < valid_from`); in den Zweigen `referat`, `gremium`, `none` wird `related_group_id := null` gesetzt. Prüfung R39 mit Nutzerkontext bleibt.
  - `ea_properties_history` per `create or replace`: vergleicht und schreibt `related_group_id` mit.
  - `ea_property_writable` per `create or replace`, gleiche Signatur: für `relation_kind = 'group'` immer `false` (Ü7).
- **Rationale:** spec.md 2.2 und Abgrenzung. Mit `false` scheitern direkte Schreibversuche aus EA und AD an der Policy; die GR-Funktionen schreiben als Eigentümer an RLS vorbei.
- **Vorhandene Tests:** `130_visibility` prüft mit einer Testart (Bezug „Gruppe“), dass der Admin `EA_GROUP_RELATION_ONLY_GR` erhält. Der Trigger läuft vor der `with check`-Prüfung der Policy, die Erwartung bleibt also gültig. Neu in 470: Auch mit GR ≥ bearbeiten scheitert ein direkter Insert (Policy, `42501`); nur die GR-Funktionen schreiben.

## R-GR-08 Schreiben nur über Funktionen

- **Decision:** Auf `gr_`-Tabellen nur `grant select … to authenticated` und eine Select-Policy. Alle Schreibfunktionen `security definer`, erste Anweisung Rechteprüfung (`GR_FORBIDDEN`), danach Fachprüfungen, dann Schreiben. Fehler mit `raise exception '<CODE>' using errcode = 'P0001'` und optional `detail` (Muster der Administration). Mehrschrittige Abläufe (`gr_admit`, `gr_cancel_contract`, `gr_dissolve_group`) sind eine Funktion und damit eine Transaktion.
- **Rationale:** spec.md 2 und 3. Die Personen werden oft erst durch die neue Zeile im Pfad GR sichtbar; RLS-Schreiben würde daran scheitern (Ü7).
- **Alternatives considered:** Insert-Policies je Tabelle (Henne-Ei-Problem bei Sichtbarkeit, doppelte Regeln).
- **Audit-Spalten:** `created_by`/`updated_by` per Default `auth.uid()` bzw. Trigger `ad_set_updated` (vorhanden) oder eigener Trigger, wo `updated_by` gesetzt wird.

## R-GR-09 Hinweise ohne Alter (R2) und Liste offener Aufnahmen

- **Decision:**
  - `gr_needs_guardian(p_person) returns boolean`, `security definer`, Grant an `authenticated`: `null` ohne `gr_row_visible(p_person)`; sonst true, wenn die Person eine laufende Teilnahme oder offene Aufnahme hat, nicht `gr_is_adult(p_person, gr_today())` ist und keine Zeile in `gr_guardians` als Kind hat. Ohne Geburtsdatum gilt sie als minderjährig (`gr_is_adult` = false), der Hinweis erscheint also.
  - `gr_v_memberships` erhält dazu die Spalte `needs_guardian`.
  - View `gr_v_pending_admissions` (`security_invoker`): Person, Gruppe, angelegt am/von (Name aus `ea_persons` der anlegenden Person über `ad_accesses.auth_user_id`, nach RLS), `needs_guardian`.
- **Rationale:** R2 verlangt die Prüfung „unter 18“ in der Datenbank, Nutzer ohne „Gruppen verwalten“ sehen den Hinweis, aber kein Alter. `gr_is_adult` hat laut Spec keinen Grant; die Hülle gibt nur ein Ja/Nein für sichtbare Personen.
- **Alternatives considered:** Alter im Frontend berechnen (geht nicht ohne Geburtsdatum); `gr_is_adult` freigeben (Rückschluss auf Volljährigkeit beliebiger Personen).

## R-GR-10 Trainingszeiten (R18, R19, A13)

- **Decision:** Trigger `gr_training_times_guard` (before update): Änderung von `group_id`, `weekday`, `starts_at`, `ends_at`, `valid_from` → `GR_TRAINING_TIME_LOCKED`. Überschneidung (gleiche Gruppe, gleicher Wochentag, Zeitspannen und Gültigkeit überlappen) als `exists` mit `daterange(…,'[]')` und Zeitvergleich; Rückgabe `overlap` in jsonb, kein Fehler. `gr_change_training_time` beendet die alte Zeile über `update … set valid_to` und legt die neue an.
- **Rationale:** spec.md 2.1 und 2.3.

## R-GR-11 EZ-Rechte vor Ü5

- **Decision:** `gr_group_roster` und `gr_groups_for_attendance` werden vollständig nach spec.md 2.3 gebaut. `ad_has_level('EZ', …)` liefert ohne Modul EZ `none`, `ad_my_referate('EZ', …)` ein leeres Feld; die Funktionen sind damit sicher, nur noch nicht über EZ nutzbar. pgTAP prüft die Pfade über „Gruppen lesen“ und die Ablehnung ohne Rechte; die EZ-Pfade (Rita, Kim, Admin mit EZ lesen) stehen als `todo` mit Verweis auf O2. Seed: Kim Kinderjugend bekommt die Vorlage Referent:in mit Referat Kinder und Jugend (heute nur für EA wirksam).
- **Rationale:** Blockiert Gruppen nicht; sobald AD v0.8 umgesetzt ist, werden die `todo`-Tests scharf geschaltet, ohne die GR-Funktionen zu ändern.
- **Alternatives considered:** EZ-Teile weglassen und später ergänzen (zweite Migration für dieselben Funktionen); AD v0.8 vorziehen (Entscheidung Product Owner, O2 Variante a).

## R-GR-12 Gesundheitsangaben

- **Decision:** Eigene Select-Policy `gr_can_read_health(person_id)` auf `gr_health_notes` und `gr_health_note_history`; `gr_health_consents` mit `gr_person_visible(person_id,'edit')`. Kein Pfad AD (`ea_person_visible_ad`) in diesen Policies. Keine Spalte mit Gesundheitsangaben in Views oder Lesefunktionen.
- **Rationale:** R11, R24. Der Admin hat AD ≥ lesen und GR lesen; er darf nichts davon sehen.
- **Tests:** je Testzugang `select count(*)` auf beiden Tabellen; Widerruf (Person 25) ergibt 0 Zeilen auch für die Geschäftsstelle.

## R-GR-13 Import (`gr_import_groups`, Skript)

- **Decision:** Datenbankfunktion nach Muster `ea_import_volunteers` (`security definer`, Grant nur `service_role`, Prüfung aller Zeilen, Rückgabe `errors/warnings/counts/written`, eine Transaktion). Dublettenerkennung ohne Nutzerkontext über `ad_first_names_match` plus Nachname und Geburtsdatum (wie EA research.md R-EA-10). Das Skript liest die Excel mit `exceljs`, zerlegt Trainingszeit-Freitexte selbst (Muster spec.md 7) und übergibt strukturierte Zeilen.
- **Offen:** Schlüsseleingabe (plan.md O1). Bis zur Entscheidung keine Umsetzung von T18.
- **Beispieldatei:** `beispiel.xlsx` wird von einem kleinen Erzeugungsskript im selben Ordner aus fiktiven Daten gebaut, damit der Inhalt im Diff prüfbar bleibt (Quelle als TypeScript, Binärdatei daneben).

## R-GR-14 pgTAP-Dateien

- **Decision:** Nummern 410–495, je Thema eine Datei: 410 Basis und Trainingszeiten, 420 Sichtbarkeit und RLS je Testzugang, 430 Aufnahme und Personen, 440 Teilnahme und Vertrag, 450 Fotoerlaubnis, Einwilligung, Gesundheit, 460 Funktionen und Ehrenamtsstatus (Ü1), 470 Ergänzungen an AD-Objekten (R38, R39, Ü3, Tests aus AD T45), 480 Lesefunktionen und Spaltenlisten, 490 Mengentest, 495 Import.
- **Rationale:** AD nutzt 010–240, EA 310–390.

## R-GR-15 Seed

- **Decision:** Personen 23–32 mit UUIDs `a0000000-0000-4000-8000-0000000000NN` (wie 1–22). Gruppen `c0000000-0000-4000-8000-00000000000N` (Präfix `c` ist frei). Testzugang Kim Kinderjugend: Zugang zu Person 32, Auth-Nutzer `b0000000-0000-4000-8000-000000000032`. Funktionen in Gruppen und Personenangaben als Eigenschaften mit IDs `e…` ab 25 bzw. über `system_key`. Daten relativ zu `current_date`. Läuft ohne Nutzerkontext (Status setzbar).
- **Rationale:** spec.md 9; Muster des vorhandenen Seeds.

## R-GR-17 Eine Trainingszeit je Gruppe und Wochentag (spec.md v0.3 R19, T20)

- **Decision:** Ausschluss-Constraint `gr_training_times_one_per_weekday` (`exclude using gist (group_id with =, weekday with =, daterange(valid_from, valid_to, '[]') with &&)`, Extension `btree_gist` im Schema `extensions`) als Sicherung in der Datenbank. Zusätzlich prüfen `gr_add_training_time`, `gr_change_training_time` und `gr_end_training_time` vorher über die interne Funktion `gr_training_time_weekday_taken` und melden `GR_TRAINING_TIME_WEEKDAY_EXISTS` (P0001); der Constraint meldet nur `23P01` ohne fachlichen Code. „Ändern ab“ prüft die neue Zeile ohne die alte, weil die alte zum Vortag endet. `gr_training_time_overlaps` und `overlap` in der Rückgabe entfallen. Neue Migration `20261027000100_gr_training_time_weekday.sql`; die gemergten Migrationen bleiben unverändert.
- **Rationale:** Der Constraint hält G6 auch bei gleichzeitigen Aufrufen und beim direkten Schreiben als Eigentümer (Seed, Import) ein; die Prüfung in den Funktionen liefert die Meldung für die Oberfläche. Das Verlängern von „gültig bis“ in eine spätere Trainingszeit am selben Wochentag würde G6 verletzen und scheitert deshalb ohnehin am Constraint; die Funktion meldet dafür denselben Code (spec.md 11, Vorschlag).
- **Alternatives considered:** Nur Prüfung in den Funktionen (ohne Constraint): nicht sicher bei gleichzeitigen Aufrufen und ohne Schutz beim direkten Schreiben. Constraint-Trigger: mehr Code bei gleicher Wirkung. Uhrzeit in die Prüfung einbeziehen: widerspricht G6 (je Wochentag eine Trainingszeit unabhängig von der Uhrzeit).

## R-GR-16 Oberfläche

- **Decision:** Feature-Ordner `src/features/gr` nach dem Muster von `src/features/ea` (Layout, `access.ts` mit Rechten aus `ad_my_modules`/`ad_has_level`, Routen). Daten über `supabase.from('gr_v_…')` und `supabase.rpc('gr_…')`. Fehlercodes über `src/lib/errors.ts` (neue GR-Einträge aus contracts/error-codes.md). Dublettendialog mit `hitAction` „Vorhandene Person übernehmen“ für alle Treffer, auch `is_visible = false`, wenn GR ≥ bearbeiten (Ü2). Personensuche über `ea_v_persons` (RLS).
- **Rationale:** Wiederverwendung statt Kopie (Prinzip VI, US-GR-06).
