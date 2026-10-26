# Spec: Gruppen (GR)

Version: 0.4 · Status: Ready (Nachtrag v0.4 Lesefunktion Buchungslauf freigegeben am 26.10.2026) · Stand: 26.10.2026 · Product Owner: Toni Werner
Stories: docs/specs/gr-gruppen/02-stories.md (US-GR-01 bis US-GR-20, v0.9.1)
Grundlage: 00-steckbrief.md v0.7, 01-erhebung.md v0.8.1 (R1–R20), 02-stories.md v0.9.1, glossar.md v1.5, rollen.md v1.1, tech-stack.md v0.6, specs/ad-administration/spec.md v0.9 (Kern bis v0.7.1; Abschnitte 2, 3, 5, 7, 9) mit Ü2 aus specs/ea-ehrenamt/uebergabe-administration.md (Geburtsjahr in R40, laut Product Owner Teil von AD v0.7.2), specs/ea-ehrenamt/01-erhebung.md v0.5 (C2), specs/ea-ehrenamt/spec.md v0.2 (Abschnitte 2, 7), specs/ez-einsaetze/spec.md v0.1, specs/ez-einsaetze/uebergabe-trainingszeiten.md v1.3, specs/ez-einsaetze/uebergabe-gruppen.md v1.0
Änderungen v0.3.1: Wortlaut von `GR_TRAINING_TIME_WEEKDAY_EXISTS` festgelegt (R19, Abschnitt 11; Product Owner, 24.10.2026).
Änderungen v0.3: Übergabe aus der Anwesenheitserfassung (uebergabe-gruppen.md v1.0, G6–G9) eingearbeitet: höchstens eine gültige Trainingszeit je Gruppe und Wochentag (Product Owner, 24.10.2026); Verstoß wird mit `GR_TRAINING_TIME_WEEKDAY_EXISTS` abgelehnt statt mit Hinweis gespeichert (2.1, 2.3, R19); `gr_group_roster` liefert höchstens eine Trainingszeit (2.3); Import bei zwei Zeiten am selben Wochentag (7); Task T20. Offene Punkte in Abschnitt 11.
Änderungen v0.2.1: Schlüssel des Importskripts nur verdeckt im Terminal eingeben, keine `.env`-Datei (Abschnitt 7; plan.md O1, Entscheidung Product Owner 24.10.2026).
Änderungen v0.2: Annahmen in Abschnitt 11 und Datenschutzhinweis zu R24 vom Product Owner bestätigt (22.10.2026); Status Ready.
Änderungen v0.1: Erster Entwurf nach Abgleich mit Administration und Ehrenamtsmanagement (Widersprüche W1–W10) und Entscheidungen des Product Owners vom 22.10.2026 (Abschnitt 11).

**Abgrenzung:** Datenmodell, Rechte und Sichtbarkeit des Personenmodells (`ea_persons`, `ea_property_*`, Lesepfade, Lesestufen, Dublettenprüfung) liegen in der Administration. Gruppen ergänzt nur, was spec.md AD der ersten GR-Migration zuweist: `gr_person_visible` (Ersatz des Platzhalters, gleiche Signatur), `ea_properties.related_group_id` und `ea_property_history.related_group_id` mit Fremdschlüssel, Validierung und R39, Funktionen zum Anlegen von Personen mit Gruppenbezug (A6), Startwert Admin „Gruppen lesen“ ist bereits AD T40. Alles Weitere liegt in eigenen `gr_`-Tabellen. Anforderungen an die Administration: specs/gr-gruppen/uebergabe-administration.md v1.0 (Ü1–Ü5).

## 1. Ziel und Scope

**Ziel:** Die Excel-Datei des Kinder- und Jugendbereichs ist abgelöst. Gruppen, Trainingszeiten, Teilnehmer:innen, Erziehungsberechtigte, Notfallkontakte, Verträge mit SEPA-Mandat, Fotoerlaubnis und Gesundheitsangaben liegen in PROD und werden nur dort gepflegt. Gruppen liefert der Anwesenheitserfassung Gruppen, Trainingszeiten und Namenslisten zum Stichtag. Erfolg: Import der Excel ohne Abtippen; Geschäftsstelle findet Notfallkontakte eines Kindes auf dem Telefon in höchstens zwei Schritten; Anwesenheitserfassung kann ohne Rechte auf Gruppen Namenslisten laden.

**Im Scope (MVP):** US-GR-01 bis US-GR-20: Gruppen anlegen, ändern, auflösen; Trainingszeiten mit Historie; Aufnahme von Teilnehmer:innen mit Zwischenspeichern („Aufnahme offen“); Erziehungsberechtigte (höchstens zwei), Notfallkontakte mit Reihenfolge; Vertrag je Teilnahme mit Kündigung und Folgevertrag; Fotoerlaubnis und Einwilligung zu Gesundheitsangaben mit Historie; Gesundheitsangaben mit Historie; Gruppenleitung, Trainer:innen, Helfer:innen als Eigenschaft mit Bezug auf die Gruppe; E-Mail-Liste der Erziehungsberechtigten; Lesefunktionen für die Anwesenheitserfassung; einmaliger Import per Skript; Seed.

**Nicht im Scope:** Erwachsenenbereich; Zugang und Pflege durch Gruppenleitungen und Trainer:innen, Reichweite „Gruppe“ (Iteration 1 der Anwesenheitserfassung); Rundmails; Vertragsübersicht, Buchungslauf, SEPA-Datei (Finanzen); Erfassung von Trainings und Anwesenheit (Anwesenheitserfassung); Freigabe von Ausfahrten; Ausfallzeiten; Auslastung/Bedarf; Wartelisten, Anmeldung durch Erziehungsberechtigte; Abgleich mit der Mitgliederverwaltung; Importfunktion in der Oberfläche; Löschen von Personen und Löschlauf (nach MVP, Datenmodell vorbereitet); Zusammenführen von Dubletten; Prüfung von Lizenzen der Trainer:innen in Gruppen; Import der Funktionen aus der Aktivenliste (Nacharbeit über US-GR-13).

## 2. Datenmodell

Konventionen nach tech-stack.md und spec.md AD: Schema `public`, snake_case, Präfix `gr_`, RLS auf jeder Tabelle, Audit-Spalten `*_by` → `auth.users(id)` per Default `auth.uid()` bzw. Trigger. Migrationen `…_gr_*.sql`. **Alle Schreibzugriffe auf `gr_`-Tabellen laufen über Datenbankfunktionen** (Abschnitt 2.3); für `authenticated` gibt es auf `gr_`-Tabellen nur `select` (keine Insert-/Update-/Delete-Grants und -Policies).

**Datumskonvention (gilt überall):** „heute“ = `gr_today()` = `(now() at time zone 'Europe/Berlin')::date`. Enddaten („Teilnahme bis“, Vertragsende, „gültig bis“, „aufgelöst am“) sind der **letzte gültige Tag**. Etwas gilt am Datum D, wenn Beginn ≤ D und (Ende leer oder Ende ≥ D).

### 2.1 Tabellen

#### gr_groups (Gruppe)
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| name | text | ja | – | getrimmt, 1–80 Zeichen |
| referat_id | uuid | ja | – | FK ea_referate(id) on delete restrict; beim Anlegen und Ändern nur aktive Referate (R21) |
| dissolved_on | date | nein | null | aufgelöst am (letzter Tag der Gruppe); nur über `gr_dissolve_group`; nicht zurücksetzbar |
| created_at / created_by | timestamptz / uuid | ja / nein | now() / auth.uid() | |
| updated_at / updated_by | timestamptz / uuid | nein | – | Trigger |

Indizes: unique `(lower(name)) where dissolved_on is null` (R1), `(referat_id)`. Kein Löschen. `ez_events.group_id` verweist mit `on delete restrict` auf `id` (Anwesenheitserfassung).

#### gr_training_times (Trainingszeit)
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| group_id | uuid | ja | – | FK gr_groups(id) on delete restrict |
| weekday | smallint | ja | – | 1–7 (ISO, 1 = Montag) (Check) |
| starts_at | time | ja | – | Beginn (HH:MM) |
| ends_at | time | ja | – | Ende; Check `ends_at > starts_at` (R18) |
| valid_from | date | ja | – | gültig von |
| valid_to | date | nein | null | gültig bis; Check `valid_to >= valid_from` (R18) |
| created_at / created_by, updated_at / updated_by | | | | Audit |

Trigger: `group_id`, `weekday`, `starts_at`, `ends_at`, `valid_from` sind nach dem Anlegen nicht änderbar (A13, R19, `GR_TRAINING_TIME_LOCKED`). Index `(group_id, weekday)`. Kein Löschen. Je `group_id` und `weekday` keine zwei Zeilen mit sich überschneidendem Gültigkeitszeitraum `[valid_from, valid_to]` (offenes Ende = unbegrenzt), unabhängig von Beginn und Ende (R19, v0.3; Umsetzung in der Datenbank, z. B. Ausschluss-Constraint oder Prüfung in den Funktionen, Wahl in research.md).

#### gr_pending_admissions (Aufnahme offen)
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| person_id | uuid | ja | – | PK, FK ea_persons(id) |
| group_id | uuid | ja | – | FK gr_groups(id); Gruppe, in die aufgenommen wird |
| created_at / created_by | timestamptz / uuid | ja / nein | now() / auth.uid() | |

Eine Person hat höchstens eine offene Aufnahme. Die Zeile wird beim Anlegen der Teilnahme (`gr_admit`) oder durch „Aufnahme abbrechen“ gelöscht (nur über Funktionen).

#### gr_memberships (Teilnahme)
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| group_id | uuid | ja | – | FK gr_groups(id) on delete restrict |
| person_id | uuid | ja | – | FK ea_persons(id) on delete restrict; Teilnehmer:in |
| joined_on | date | ja | – | Eintrittsdatum |
| left_on | date | nein | null | „Teilnahme bis“; Check `left_on >= joined_on` (R8) |
| created_at / created_by, updated_at / updated_by | | | | Audit |

Indizes: `(group_id)`, `(person_id)`. Keine Überschneidung zweier Teilnahmen derselben Person an derselben Gruppe (R10, geprüft in `gr_admit`). Aktiv am Datum D: `joined_on <= D and (left_on is null or left_on >= D)`. **Laufend** (für Sichtbarkeit): `left_on is null or left_on >= gr_today()` (auch künftige).

#### gr_contracts (Vertrag)
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| membership_id | uuid | ja | – | FK gr_memberships(id) on delete restrict |
| holder_person_id | uuid | ja | – | FK ea_persons(id); Vertragsinhaber:in (R4) |
| starts_on | date | ja | – | Vertragsbeginn |
| cancelled_on | date | nein | null | Kündigungsdatum (Eingang); Pflicht, wenn `ends_on` gesetzt (Check) |
| ends_on | date | nein | null | Vertragsende (letzter Tag); Check `ends_on >= starts_on` (R8) |
| account_holder | text | ja | – | Kontoinhaber:in; getrimmt, 1–70 Zeichen (SEPA) |
| iban | text | ja | – | normalisiert über `ea_iban_normalize`, gültig nach `ea_iban_valid` (R5; Funktionen aus spec.md EA 2.3) |
| mandate_reference | text | ja | – | getrimmt, 1–35 Zeichen, nur `A–Z a–z 0–9 + ? / - : ( ) . , ' Leerzeichen` (SEPA); eindeutig ohne Groß-/Kleinschreibung über alle Verträge (R6) |
| mandate_signed_on | date | ja | – | Unterschriftsdatum des Mandats; ≤ heute |
| purpose | text | ja | – | Verwendungszweck; getrimmt, 1–140 Zeichen (SEPA) |
| monthly_amount | numeric(10,2) | ja | – | Betrag je Monat in EUR; Check `> 0` |
| created_at / created_by, updated_at / updated_by | | | | Audit |

Indizes: unique `(lower(mandate_reference))`, `(membership_id)`, `(holder_person_id)`. Status (abgeleitet, Funktion `gr_contract_status(ends_on, D)`): `active` (aktiv), wenn `ends_on is null`; `cancelled` (gekündigt zum …), wenn `ends_on >= D`; `ended` (beendet), wenn `ends_on < D`. Je Teilnahme überschneiden sich Verträge nicht: ein Folgevertrag ist nur möglich, wenn alle vorhandenen Verträge der Teilnahme ein Vertragsende haben und `starts_on` des neuen > größtes `ends_on` (R8a). Änderbar nach dem Anlegen: Kontoinhaber:in, IBAN, Mandatsreferenz, Unterschriftsdatum, Verwendungszweck, Betrag, Vertragsinhaber:in (nur über `gr_update_contract`); Vertragsbeginn und Teilnahme nicht. Kein Löschen.

#### gr_guardians (Erziehungsberechtigung)
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| child_person_id | uuid | ja | – | FK ea_persons(id); Teilnehmer:in |
| guardian_person_id | uuid | ja | – | FK ea_persons(id); Check `<> child_person_id` |
| created_at / created_by | timestamptz / uuid | ja / nein | now() / auth.uid() | |

Unique `(child_person_id, guardian_person_id)`; höchstens zwei je Kind (Trigger, R3). Index `(guardian_person_id)`. Entfernen über `gr_remove_guardian` (Löschen der Zeile), außer die Person ist Vertragsinhaber:in eines nicht beendeten Vertrags des Kindes (R22).

#### gr_emergency_contacts (Notfallkontakt)
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| child_person_id | uuid | ja | – | FK ea_persons(id) |
| contact_person_id | uuid | ja | – | FK ea_persons(id); Check `<> child_person_id` |
| sort_order | int | ja | – | 1 = zuerst anrufen |
| created_at / created_by | timestamptz / uuid | ja / nein | now() / auth.uid() | |

Unique `(child_person_id, contact_person_id)` (R23). Telefon und E-Mail liegen an der Person (Kontaktdaten, 2.2). Entfernen über `gr_remove_emergency_contact`.

#### gr_photo_consents (Fotoerlaubnis, Historie)
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | bigint identity | ja | – | PK |
| person_id | uuid | ja | – | FK ea_persons(id) |
| granted | boolean | ja | – | ja/nein |
| effective_on | date | ja | – | Datum der Erteilung bzw. des Widerrufs; ≤ heute (R12) |
| created_at / created_by | timestamptz / uuid | ja / nein | now() / auth.uid() | ändernde Person und Zeitpunkt |

Nur Einfügen. Aktueller Stand = Zeile mit größtem `(effective_on, created_at)`; keine Zeile = „nein“. Index `(person_id, effective_on desc, created_at desc)`.

#### gr_health_consents (Einwilligung Gesundheitsangaben, Historie)
Aufbau wie `gr_photo_consents`. Aktueller Stand „ja“ ist Voraussetzung für Lesen und Schreiben von Gesundheitsangaben (R11, R24).

#### gr_health_notes (gesundheitliche Einschränkungen)
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| person_id | uuid | ja | – | PK, FK ea_persons(id) |
| note | text | ja | – | Freitext, getrimmt, 1–2000 Zeichen |
| updated_at / updated_by | timestamptz / uuid | ja / nein | now() / auth.uid() | |

#### gr_health_note_history
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | bigint identity | ja | – | PK |
| person_id | uuid | ja | – | FK ea_persons(id) |
| note | text | ja | – | Fassung vor der Änderung |
| valid_since | timestamptz | ja | – | `updated_at` der alten Fassung |
| replaced_at / replaced_by | timestamptz / uuid | ja / nein | now() / auth.uid() | |

Trigger `gr_health_notes_history` (after update): schreibt die alte Fassung. Kein Leeren des Texts: „Keine Einschränkungen“ wird nicht gespeichert; wird die Angabe hinfällig, überschreibt die Geschäftsstelle sie mit einem Text (z. B. „keine mehr“) [ANNAHME].

### 2.2 Personenmodell (Tabellen der Administration)

Personen sind Zeilen in `ea_persons` (`created_in = 'GR'` bei Anlage aus Gruppen). Vorname, Rufname, Nachname in `ea_persons`. Personenangaben als Eigenschaften der System-Eigenschaftsarten des Ehrenamtsmanagements (spec.md EA 2.1, „sichtbar in“ enthält GR):

| Angabe in Gruppen | Eigenschaftsart (`system_key`) | Feldschlüssel | Lesestufe | Konvention |
|---|---|---|---|---|
| Geburtsdatum | `birth_date` | `date` | nur Geschäftsstelle und Admin | eine Eigenschaft; `valid_from` = Geburtsdatum [ANNAHME] |
| Adresse | `contact` | `street`, `postal_code`, `city` | alle mit Zugriff | eine Eigenschaft je Person (nicht mehrfach); `valid_from` = Datum der Anlage; Änderungen als Update (Historie über `ea_property_history`) |
| Telefon mobil / Festnetz | `contact` | `phone_mobile`, `phone_landline` | alle mit Zugriff | wie oben |
| E-Mail | `contact` | `email` | alle mit Zugriff | wie oben |
| Mitgliedsnummer | `member` | `is_member` = true, `member_number` | alle mit Zugriff | nur wenn eine Nummer angegeben ist; ohne Nummer keine Eigenschaft (R25) |

Die Pflichtregeln von Gruppen (R2, R7, R26) prüfen die Funktionen von Gruppen, nicht die Felder der Eigenschaftsart (dort optional).

**Neue System-Eigenschaftsart der ersten GR-Migration „Funktion in Gruppe“** (ohne Nutzerkontext, idempotent `on conflict (system_key) do nothing`):

| Spalte | Wert |
|---|---|
| name | Funktion in Gruppe |
| system_key | `group_function` |
| purpose | Betreuung einer Gruppe (Gruppenleitung, Trainer:in, Helfer:in) |
| category | `assignment` |
| read_level | `all` |
| relation_kind / relation_required | `group` / true |
| allow_multiple | true |
| visible_in | `{AD,EA,GR}` |
| origin | `system` |
| valid_from_label / valid_to_label | „seit“ / „bis“ (falls Ü1 aus EA umgesetzt) |
| Feld | `function` (Funktion, Auswahl: Gruppenleitung, Trainer:in, Helfer:in, Pflicht, sort_order 1) |

Rückgabewerte der Lesefunktionen: Gruppenleitung → `group_lead`, Trainer:in → `trainer`, Helfer:in → `helper`; Teilnehmer:in → `participant`.

**Ergänzung der Tabellen der Administration (A4 der Übergabe, spec.md AD 2):**
- `ea_properties.related_group_id uuid null` FK `gr_groups(id)` on delete restrict; Index `(related_group_id) where related_group_id is not null`.
- `ea_property_history.related_group_id uuid null` (Fassung vor der Änderung).
- Trigger `ea_properties_validate` (R38): bei `relation_kind = 'group'` genau `related_group_id` gefüllt, `related_referat_id` und `related_gremium_id` null; bei `relation_required` und leerem Bezug `EA_RELATION_REQUIRED` mit Text „Bitte ein Referat (bzw. Gremium, Gruppe) wählen.“; aufgelöste Gruppen (`dissolved_on < valid_from`) nicht neu wählbar (`GR_GROUP_DISSOLVED`). `ea_properties_history` schreibt `related_group_id` mit.
- R39: Eigenschaften mit `relation_kind = 'group'` schreiben Nutzer nur über `gr_add_group_function` und `gr_end_group_function` (security definer); `ea_property_writable` liefert für diese Arten false (Meldung im EA „Diese Angabe wird im Modul Gruppen gepflegt.“, `EA_GROUP_RELATION_ONLY_GR`). Umsetzung als `create or replace` von `ea_property_writable` mit unveränderter Signatur, nur die Bedingung für `group` wird verschärft.
- Eine Funktion in Gruppe gilt für Gruppen-Lesefunktionen am Datum D, wenn `valid_from <= D and (valid_to is null or valid_to >= D)`.

### 2.3 Funktionen

Alle mit festem `search_path = public`, Grant `execute` nur an `authenticated` (Ausnahmen genannt). Fehler mit Code nach Abschnitt 5. „GR-Recht“ = `ad_has_level('GR', …)` (Reichweite „alle“; Reichweite „Referat“ gibt es für GR nicht, R30 AD).

**Hilfsfunktionen**
- `gr_today() returns date` – stable: heute in Europe/Berlin.
- `gr_has_current_relation(p_person uuid) returns boolean` – security definer, stable, **ohne Rechteprüfung**, Grant nur an Funktionen/Views (kein `authenticated`): wahr, wenn mindestens eins gilt:
  1. offene Aufnahme (`gr_pending_admissions`);
  2. laufende Teilnahme (`left_on is null or left_on >= gr_today()`);
  3. Teilnehmer:in oder Vertragsinhaber:in eines Vertrags mit `ends_on is null or ends_on >= gr_today()`;
  4. Erziehungsberechtigte:r oder Notfallkontakt eines Kindes, für das 1., 2. oder 3. gilt;
  5. Eigenschaft der Art `group_function` mit `valid_to is null or valid_to >= gr_today()`.
- `gr_person_visible(p_person uuid, p_min ad_level default 'read') returns boolean` – ersetzt den Platzhalter der Administration (`create or replace`, gleiche Signatur), security definer, stable: `ad_has_level('GR', p_min) and gr_has_current_relation(p_person)` und Person `kind = 'human'`. Personen mit nur beendeten Bezügen sind damit nur noch über den Pfad AD sichtbar (Entscheidung Product Owner 22.10.2026).
- `gr_row_visible(p_person uuid) returns boolean` – security definer, stable: `ad_has_level('GR','read') and (gr_person_visible(p_person) or ad_has_level('AD','read'))`. Grundlage der RLS auf personenbezogenen `gr_`-Tabellen.
- `gr_is_adult(p_person uuid, p_date date) returns boolean` – security definer, stable, kein Grant an `authenticated`: Geburtsdatum aus `birth_date` + 18 Jahre ≤ p_date; ohne Geburtsdatum false. Nur intern (R4, R13); das Alter wird nie zurückgegeben.
- `gr_can_read_health(p_person uuid) returns boolean` – security definer, stable: `gr_person_visible(p_person, 'edit')` und aktuelle Einwilligung (gr_health_consents) = ja.

**Gruppen und Trainingszeiten** (security definer; Prüfung `ad_has_level('GR','edit')`, sonst `GR_FORBIDDEN`; aufgelöste Gruppen sind nicht änderbar, `GR_GROUP_DISSOLVED`)
- `gr_save_group(p_id uuid, p_name text, p_referat_id uuid) returns uuid` – Anlegen (p_id null) oder Ändern von Name und Referat; R1, R21, Pflicht (`GR_GROUP_FIELDS_REQUIRED`).
- `gr_dissolve_group(p_id uuid, p_dissolved_on date)` – R9: keine Teilnahme mit `left_on is null or left_on > p_dissolved_on` und keine offene Aufnahme der Gruppe (`GR_GROUP_HAS_MEMBERS`, `GR_GROUP_HAS_PENDING`); `p_dissolved_on <= gr_today()` (`GR_DATE_IN_FUTURE`); setzt `dissolved_on`; setzt in einer Transaktion bei allen `group_function`-Eigenschaften der Gruppe mit `valid_to is null or valid_to > p_dissolved_on` und `valid_from <= p_dissolved_on` `valid_to = p_dissolved_on` und bei allen Trainingszeiten der Gruppe entsprechend `valid_to = p_dissolved_on` (A12); Funktionen und Trainingszeiten mit `valid_from > p_dissolved_on` bleiben unverändert und werden mit „beginnt nach Auflösung“ im Bericht zurückgegeben [ANNAHME: kommt praktisch nicht vor]. Rückgabe `void`.
- `gr_add_training_time(p_group uuid, p_weekday smallint, p_starts time, p_ends time, p_valid_from date, p_valid_to date default null) returns jsonb` – R18; R19: gibt es für die Gruppe am Wochentag eine Trainingszeit mit sich überschneidender Gültigkeit, `GR_TRAINING_TIME_WEEKDAY_EXISTS`; legt an; Rückgabe `{"id":…}` (v0.3: ohne `overlap`).
- `gr_change_training_time(p_id uuid, p_from date, p_weekday smallint, p_starts time, p_ends time) returns jsonb` – „Ändern ab“: `p_from > valid_from` und (`valid_to is null or p_from <= valid_to`), sonst `GR_CHANGE_DATE_INVALID`; setzt an der alten `valid_to = p_from - 1`, legt die neue mit `valid_from = p_from` und dem alten `valid_to` an; R18; R19 für die neue Trainingszeit (die alte zählt mit ihrem neuen `valid_to` = `p_from - 1`), sonst `GR_TRAINING_TIME_WEEKDAY_EXISTS`; Rückgabe wie oben.
- `gr_end_training_time(p_id uuid, p_valid_to date)` – setzt `valid_to` (≥ valid_from, R18); auch Ändern eines vorhandenen „gültig bis“. [OFFEN, Abschnitt 11: Verlängern über den Beginn einer späteren Trainingszeit am selben Wochentag ebenfalls `GR_TRAINING_TIME_WEEKDAY_EXISTS`?]

**Personen und Aufnahme** (security definer; Prüfung `ad_has_level('GR','edit')`, sonst `GR_FORBIDDEN`)

Gemeinsamer Parameter `p_new_person jsonb` für neu anzulegende Personen: `{"first_name", "last_name", "preferred_name", "birth_date", "street", "postal_code", "city", "phone_mobile", "phone_landline", "email", "member_number"}`; leere Strings gelten als null. Anlage: `ea_persons` mit `created_in = 'GR'`, dann Eigenschaften nach 2.2 (Kontaktdaten nur, wenn mindestens ein Kontaktfeld gesetzt ist; Mitglied nur mit Nummer; Geburtsdatum nur mit `ad_has_level('GR','manage')`, sonst `GR_BIRTH_DATE_FORBIDDEN`). R4 der Administration (Vor- und Nachname) gilt.

Gemeinsame Übernahmeregel `p_person_id` (vorhandene Person): Person muss `kind = 'human'` sein (`GR_PERSON_INVALID`). Sie darf für den Nutzer nicht sichtbar sein; dann wird sie mit dem neuen Bezug in Gruppen sichtbar (Übernahme nicht sichtbarer Dublettentreffer ab „Gruppen bearbeiten“, Entscheidung Product Owner 22.10.2026; Ü2 an die Administration).

- `gr_start_admission(p_group uuid, p_person_id uuid default null, p_new_person jsonb default null) returns uuid` – genau einer der beiden Parameter (`GR_PERSON_INVALID`); Gruppe nicht aufgelöst; bei neuer Person R2 (Vorname, Nachname, Geburtsdatum, Straße, PLZ, Ort; `GR_PARTICIPANT_FIELDS_REQUIRED`); legt `gr_pending_admissions` an (bei vorhandener offener Aufnahme `GR_PENDING_EXISTS`); R10 gegen laufende Teilnahme an derselben Gruppe (`GR_ALREADY_MEMBER`). Gibt die Person-ID zurück.
- `gr_cancel_admission(p_person uuid)` – löscht die offene Aufnahme („Aufnahme abbrechen“). Erziehungsberechtigte und Notfallkontakte bleiben als Zuordnung bestehen; ohne laufenden Bezug sind alle Beteiligten danach nur über den Pfad AD sichtbar.
- `gr_update_person(p_person uuid, p_data jsonb)` – ändert Namen (`ea_persons`) und Personenangaben nach 2.2 einer Person mit `gr_person_visible(p_person,'edit')` (sonst `GR_FORBIDDEN`); Geburtsdatum nur mit GR verwalten; prüft R2 (Teilnehmer:in mit laufender Teilnahme oder offener Aufnahme), R26 (Erziehungsberechtigte:r: Straße, PLZ, Ort) und R7 (Notfallkontakt: Telefon mobil, Festnetz oder E-Mail); Änderungen wirken in allen Modulen (eine Person).
- `gr_copy_address(p_child uuid, p_from_guardian uuid)` – kopiert Straße, PLZ, Ort der erziehungsberechtigten Person in die Kontaktdaten des Kindes (einmalig, A3).
- `gr_add_guardian(p_child uuid, p_person_id uuid default null, p_new_person jsonb default null) returns uuid` – Kind sichtbar mit edit; neue Person: Vorname, Nachname, Straße, PLZ, Ort Pflicht (R26, `GR_GUARDIAN_FIELDS_REQUIRED`), kein Geburtsdatum; R3 (`GR_GUARDIAN_LIMIT`); doppelte Zuordnung `GR_GUARDIAN_EXISTS`.
- `gr_remove_guardian(p_child uuid, p_guardian uuid)` – R22 (`GR_GUARDIAN_IS_HOLDER`).
- `gr_add_emergency_contact(p_child uuid, p_person_id uuid default null, p_new_person jsonb default null) returns uuid` – R7 (`GR_CONTACT_REACHABILITY`) gegen die Kontaktdaten der Person nach dem Speichern; R23 (`GR_EMERGENCY_EXISTS`); `sort_order` = höchste + 1.
- `gr_remove_emergency_contact(p_child uuid, p_contact uuid)`; `gr_reorder_emergency_contacts(p_child uuid, p_contact_ids uuid[])` – Liste muss genau alle Notfallkontakte des Kindes enthalten (`GR_ORDER_INVALID`); setzt `sort_order` 1…n.

**Teilnahme und Vertrag** (security definer; `ad_has_level('GR','edit')`)

Parameter `p_contract jsonb`: `{"holder_person_id", "starts_on", "account_holder", "iban", "mandate_reference", "mandate_signed_on", "purpose", "monthly_amount"}`, alle Pflicht (`GR_CONTRACT_FIELDS_REQUIRED`).
- `gr_admit(p_person uuid, p_group uuid, p_joined_on date, p_contract jsonb) returns uuid` – legt Teilnahme und Vertrag in einer Transaktion an (R16) und löscht eine offene Aufnahme der Person für diese Gruppe. Prüft: Gruppe nicht aufgelöst; R10; R4, R5, R6, Vertragsfelder (R27); bei Fehler wird nichts gespeichert. Gilt auch ohne offene Aufnahme für Personen, die bereits sichtbar sind (z. B. Kind in Gruppe A wird in Gruppe B aufgenommen, US-GR-08 AK4). Gibt die Teilnahme-ID zurück.
- `gr_add_contract(p_membership uuid, p_contract jsonb) returns uuid` – Folgevertrag nach R8a (`GR_CONTRACT_EXISTS`); R4–R6, R27.
- `gr_update_contract(p_contract uuid, p_data jsonb)` – ändert die in 2.1 genannten Felder; R4–R6, R27.
- `gr_cancel_contract(p_contract uuid, p_cancelled_on date, p_ends_on date, p_end_membership boolean)` – setzt Kündigungsdatum und Vertragsende (R8, `GR_CONTRACT_END_BEFORE_START`); ist `p_end_membership` true, setzt sie `left_on = p_ends_on` an der Teilnahme, falls diese offen ist oder ein späteres `left_on` hat (R8b); eine Transaktion. Ändern eines gesetzten Vertragsendes: erneuter Aufruf.
- `gr_end_membership(p_membership uuid, p_left_on date)` – setzt oder ändert „Teilnahme bis“ (R8, `GR_LEFT_BEFORE_JOINED`); Vertrag bleibt unverändert (R8b).

**Fotoerlaubnis, Einwilligung, Gesundheitsangaben** (security definer)
- `gr_set_photo_consent(p_person uuid, p_granted boolean, p_effective_on date)` – `gr_person_visible(p_person,'edit')`; Datum Pflicht und ≤ heute (R12, `GR_CONSENT_DATE_REQUIRED`, `GR_DATE_IN_FUTURE`); fügt eine Zeile ein; gleicher Wert wie aktuell → `GR_CONSENT_UNCHANGED`.
- `gr_set_health_consent(p_person uuid, p_granted boolean, p_effective_on date)` – wie oben, aber `gr_person_visible(p_person,'edit')` (R11). Bei „nein“ bleiben vorhandene Gesundheitsangaben gespeichert, sind aber nicht mehr lesbar (R24).
- `gr_save_health_note(p_person uuid, p_note text)` – erlaubt mit `gr_can_read_health(p_person)` (sonst `GR_HEALTH_CONSENT_REQUIRED`, wenn die Person sichtbar ist und die Einwilligung fehlt, sonst `GR_FORBIDDEN`); Insert oder Update; Länge 1–2000 (`GR_HEALTH_NOTE_INVALID`).

**Funktionen in Gruppen** (security definer; `ad_has_level('GR','edit')`)
- `gr_add_group_function(p_group uuid, p_function text, p_valid_from date, p_valid_to date default null, p_person_id uuid default null, p_new_person jsonb default null) returns uuid` – `p_function in ('Gruppenleitung','Trainer:in','Helfer:in')`; neue Person: Vorname, Nachname Pflicht, übrige optional; Gruppe nicht aufgelöst; R28 (gleiche Funktion derselben Person in derselben Gruppe mit überschneidendem Zeitraum, `GR_FUNCTION_OVERLAP`); `valid_to >= valid_from` (`EA_VALID_TO_BEFORE_FROM` bzw. Text aus AD). Legt die Eigenschaft der Art `group_function` mit `related_group_id` an. Hat die Person keinen Ehrenamtsstatus, setzt sie über `ea_set_status_from_group(p_person, p_valid_from)` (Ü1 an die Administration) den Status „aktiv“ (R29). Hat sie „ruhend“ oder „ausgeschieden“, bleibt der Status; die Rückgabe enthält den Hinweis (Oberfläche: „Die Person ist im Ehrenamtsmanagement ruhend.“ bzw. „… ausgeschieden.“). Rückgabe `jsonb {"property_id", "status_hint": null | "dormant" | "left", "status_set": bool}`.
- `gr_end_group_function(p_property uuid, p_valid_to date)` – nur Eigenschaften der Art `group_function`; setzt bzw. ändert `valid_to` (≥ valid_from); der Ehrenamtsstatus bleibt unverändert.

**Lesefunktionen für Oberfläche und andere Module**
- View `gr_v_memberships` (`security_invoker = true`): je Teilnahme Gruppe, Person (Vorname, Rufname, Nachname aus `ea_persons` nach RLS), `joined_on`, `left_on`, `birth_date` (aus `birth_date`-Eigenschaft nach RLS; null, wenn nicht lesbar), aktueller Vertrag (id, Status nach `gr_contract_status`, `ends_on`), Fotoerlaubnis aktuell, `needs_clarification` (R17), `has_emergency_contact` (R7). Das Alter berechnet das Frontend aus `birth_date`; ist es null, wird keine Altersspalte gezeigt (W2, Entscheidung Product Owner 22.10.2026).
- `gr_group_overview(p_include_dissolved boolean default false) returns setof (id uuid, name text, referat_id uuid, referat_name text, dissolved_on date, training_times_today text, active_count int, clarify_count int, no_emergency_count int, pending_count int)` – security invoker (RLS entscheidet); `training_times_today` z. B. „Di 16:30–18:00 · Do 17:00–18:30“ (sortiert nach Wochentag, Beginn) oder null.
- `gr_guardian_emails(p_group uuid) returns setof text` – security definer; `ad_has_level('GR','read')`, sonst `GR_FORBIDDEN`: E-Mail-Adressen (Feld `email` der Kontaktdaten) der Erziehungsberechtigten aller am heutigen Tag aktiven Teilnahmen der Gruppe; bei Teilnehmer:innen mit `gr_is_adult(person, gr_today())` deren eigene Adresse statt der Erziehungsberechtigten (R13, A9); ohne Dubletten (ohne Groß-/Kleinschreibung), sortiert. Nie Gesundheitsangaben oder andere Felder.
- `gr_group_roster(p_group_id uuid, p_date date) returns jsonb` – security definer, stable (R20):
  - Rechte: `ad_has_level('GR','read') or ad_has_level('EZ','read') or (Referat der Gruppe) = any(ad_my_referate('EZ','read'))`, sonst `GR_ROSTER_FORBIDDEN` („Für diesen Bereich hast du keine Rechte.“). Prüfung der Existenz erst nach der Rechteprüfung auf Ebene „irgendein Recht“: Ohne jedes der drei Rechte immer `GR_ROSTER_FORBIDDEN`; mit Recht und unbekannter Gruppe oder `dissolved_on < p_date` `GR_GROUP_NOT_FOUND` („Gruppe nicht gefunden.“).
  - Rückgabe: `{"group": {"id", "name", "referat_id", "referat_name"}, "training_times": [{"starts_at": "HH:MM", "ends_at": "HH:MM"}], "persons": [{"person_id", "first_name", "preferred_name", "last_name", "role"}]}`; `training_times`: am Datum gültige Trainingszeit mit `weekday = isodow(p_date)`, höchstens ein Eintrag (R19, v0.3; Liste und Schlüssel unverändert); `persons`: Teilnehmer:innen mit am Datum aktiver Teilnahme (`participant`) sowie Personen mit am Datum gültiger `group_function` (`group_lead`, `trainer`, `helper`); eine Person je Rolle einmal; sortiert nach Rolle (group_lead, trainer, helper, participant), dann Nachname, Rufname bzw. Vorname. Leere Listen statt Fehler (AK6). Nur Menschen.
- `gr_groups_for_attendance(p_date date) returns setof (group_id uuid, group_name text, referat_id uuid, referat_name text)` – security definer, stable: Gruppen mit `dissolved_on is null or dissolved_on >= p_date`; mit `ad_has_level('GR','read') or ad_has_level('EZ','read')` alle, sonst Gruppen mit `referat_id = any(ad_my_referate('EZ','read'))`; ohne Rechte leere Menge; sortiert nach Name.
- `gr_my_groups(p_date date) returns setof (group_id uuid, group_name text, referat_id uuid, referat_name text, function text, weekdays smallint[])` – security definer, stable: Person aus `ad_me()`; ohne Person oder Zugang nicht `active` leere Menge; je am Datum gültiger `group_function` der eigenen Person in einer am Datum nicht aufgelösten Gruppe eine Zeile mit `function` in `group_lead`/`trainer`/`helper` und den Wochentagen der am Datum gültigen Trainingszeiten (sortiert, ohne Dubletten). Kein Parameter Person.

**Import** (nur `service_role`)
- `gr_import_groups(p_rows jsonb, p_import_date date, p_dry_run boolean) returns jsonb` – security definer, `grant execute` nur an `service_role`; Aufbau wie `ea_import_volunteers` (spec.md EA 7): Prüfung aller Zeilen, Rückgabe `{"errors":[{"sheet","row","message"}], "warnings":[…], "counts":{…}, "written": bool}`; schreibt nur ohne Fehler und mit `p_dry_run = false`, alles in einer Transaktion (US-GR-16 AK4). Details Abschnitt 7.

### 2.4 Beziehungen

`gr_groups` 1–n `gr_training_times`, `gr_memberships`, `gr_pending_admissions`, `ea_properties` (Funktion in Gruppe). `gr_memberships` 1–n `gr_contracts`. `ea_persons` 1–n `gr_memberships`, `gr_guardians` (als Kind und als Erziehungsberechtigte:r), `gr_emergency_contacts` (beide Seiten), `gr_photo_consents`, `gr_health_consents`, 1–1 `gr_health_notes`, 0–1 `gr_pending_admissions`. `ea_referate` 1–n `gr_groups`.

## 3. Rechte / RLS

Startwerte der Rechtevorlagen für GR (spec.md AD Abschnitt 3; nicht durch Gruppen gesetzt): Admin lesen, Geschäftsstelle verwalten, Referent:in und Vorstand kein Zugriff. Reichweite nur „alle“. „bearbeiten“ und „verwalten“ unterscheiden sich in Gruppen nur beim Geburtsdatum (Lesestufe „nur Geschäftsstelle und Admin“ = GR verwalten, R29 AD) und damit beim Anlegen von Teilnehmer:innen (Geburtsdatum Pflicht). Im MVP hat keine Vorlage „Gruppen bearbeiten“.

| Tabelle / Objekt | Lesen | Anlegen | Ändern | Löschen |
|---|---|---|---|---|
| gr_groups | `ad_has_level('GR','read') or ad_has_any_level('EA','read')` (Gruppenname zur Anzeige der Funktion im EA, US-GR-13 AK3) | `gr_save_group` (GR ≥ edit) | `gr_save_group`, `gr_dissolve_group` | – |
| gr_training_times | `ad_has_level('GR','read')`; Anwesenheitserfassung nur über Funktionen | `gr_add_training_time`, `gr_change_training_time` | `gr_end_training_time`; Kernfelder gesperrt (Trigger) | – |
| gr_pending_admissions | `ad_has_level('GR','read')` | `gr_start_admission` | – | `gr_admit`, `gr_cancel_admission` |
| gr_memberships | `gr_row_visible(person_id)` | `gr_admit` | `gr_end_membership`, `gr_cancel_contract` | – |
| gr_contracts | `gr_row_visible(Teilnehmer:in der Teilnahme)` | `gr_admit`, `gr_add_contract` | `gr_update_contract`, `gr_cancel_contract` | – |
| gr_guardians | `gr_row_visible(child_person_id)` | `gr_add_guardian` | – | `gr_remove_guardian` |
| gr_emergency_contacts | `gr_row_visible(child_person_id)` | `gr_add_emergency_contact` | `gr_reorder_emergency_contacts` | `gr_remove_emergency_contact` |
| gr_photo_consents | `gr_row_visible(person_id)` | `gr_set_photo_consent` | – | – |
| gr_health_consents | `gr_person_visible(person_id,'edit')` | `gr_set_health_consent` | – | – |
| gr_health_notes, gr_health_note_history | `gr_can_read_health(person_id)` | `gr_save_health_note` | `gr_save_health_note` | – |
| ea_persons, ea_properties | RLS der Administration (Pfad GR über `gr_person_visible`) | über GR-Funktionen | Namen und Eigenschaften nach R42 AD; Personenangaben über `gr_update_person`; `group_function` nur über GR-Funktionen | – |

Grundsätze:
- Gesundheitsangaben und die Einwilligung dazu sind nie über „Gruppen lesen“, nie über den Pfad AD und nie über andere Module lesbar (R11). Der Admin hat GR lesen und sieht sie daher nicht.
- Personenbezogene `gr_`-Zeilen zu Personen ohne laufenden Bezug liest nur, wer zusätzlich AD ≥ lesen hat (Admin).
- Nutzer nur mit Rechten auf die Anwesenheitserfassung lesen keine `gr_`-Tabelle direkt; Namen nur über `gr_group_roster`, Gruppen über `gr_groups_for_attendance`, eigene Gruppen über `gr_my_groups` (R20, US-GR-01 AK7).
- Schreiben ausschließlich über die Funktionen aus 2.3; keine Insert-/Update-/Delete-Grants auf `gr_`-Tabellen für `authenticated`.
- Routenschutz: `/gr/*` ohne `ad_has_level('GR','read')` → `/kein-zugriff`, keine Datenabfrage. Bearbeiten-Knöpfe nur mit `ad_has_level('GR','edit')`; Geburtsdatum-Eingabe und Aufnahme neuer Teilnehmer:innen nur mit `ad_has_level('GR','manage')`; Abschnitt Gesundheit nur mit `ad_has_level('GR','edit')`.

## 4. Zustände und Übergänge

Gruppe:

| Von | Nach | Wer | Bedingung |
|---|---|---|---|
| – | aktiv | GR ≥ bearbeiten | R1, R21 |
| aktiv | aufgelöst | GR ≥ bearbeiten | R9; Datum ≤ heute; beendet Funktionen und Trainingszeiten zum Datum (A12) |

Kein Wiederaufnehmen. Aufgelöste Gruppen sind nur lesbar.

Aufnahme / Teilnahme:

| Von | Nach | Wer | Bedingung |
|---|---|---|---|
| – | Aufnahme offen | GR ≥ bearbeiten (neue Person: GR verwalten) | `gr_start_admission`; R2, R10 |
| Aufnahme offen | – (abgebrochen) | GR ≥ bearbeiten | `gr_cancel_admission` |
| Aufnahme offen oder sichtbare Person | Teilnahme aktiv | GR ≥ bearbeiten | `gr_admit` mit Vertrag (R16) |
| aktiv | beendet | System (Datum) | „Teilnahme bis“ < heute |
| aktiv/beendet | aktiv/beendet | GR ≥ bearbeiten | „Teilnahme bis“ ändern (R8) |

Vertrag:

| Von | Nach | Wer | Bedingung |
|---|---|---|---|
| – | aktiv | GR ≥ bearbeiten | `gr_admit` oder Folgevertrag (R8a) |
| aktiv | gekündigt | GR ≥ bearbeiten | Kündigungsdatum und Vertragsende; Vertragsende ≥ heute |
| aktiv | beendet | GR ≥ bearbeiten | Vertragsende < heute (nachträglich erfasst) |
| gekündigt | beendet | System (Datum) | Vertragsende < heute |
| gekündigt/beendet | gekündigt/beendet | GR ≥ bearbeiten | Vertragsende ändern (R8) |

Ist eine Teilnahme laufend und hat sie keinen Vertrag mit Status aktiv oder gekündigt, gilt „Teilnahme klären“ (R17).

Fotoerlaubnis und Einwilligung Gesundheitsangaben: nein ↔ ja; jeder Wechsel neue Zeile mit Datum (R12, R24). Funktion in Gruppe: gültig ab „seit“, beendet nach „bis“. Ehrenamtsstatus: kein Status → aktiv durch Gruppen (R29); alle übrigen Wechsel im Ehrenamtsmanagement.

## 5. Geschäftsregeln

Regeln R1–R20 aus 01-erhebung.md, hier verbindlich präzisiert; R21–R29 neu.

- R1: Wenn eine nicht aufgelöste Gruppe mit gleichem Namen (ohne Groß-/Kleinschreibung) existiert, dann „Eine Gruppe mit diesem Namen gibt es bereits.“ (`GR_GROUP_NAME_TAKEN`). Fehlen Name oder Referat: „Bitte Name und Referat angeben.“ (`GR_GROUP_FIELDS_REQUIRED`).
- R2: Wenn bei einer neuen Teilnehmer:in Vorname, Nachname, Geburtsdatum oder Adresse (Straße und Hausnummer, PLZ, Ort) fehlen, dann „Bitte Vorname, Nachname, Geburtsdatum und Adresse angeben.“ (`GR_PARTICIPANT_FIELDS_REQUIRED`). Wenn eine Teilnehmer:in mit laufender Teilnahme oder offener Aufnahme unter 18 ist und keine erziehungsberechtigte Person hat, dann Hinweis „Bitte mindestens eine erziehungsberechtigte Person angeben.“ (keine Sperre). Die Prüfung „unter 18“ erfolgt in der Datenbank; Nutzer ohne GR verwalten sehen den Hinweis, aber kein Alter.
- R3: Wenn bereits zwei erziehungsberechtigte Personen zugeordnet sind, dann „Es können höchstens zwei erziehungsberechtigte Personen angegeben werden.“ (`GR_GUARDIAN_LIMIT`).
- R4: Die Vertragsinhaber:in muss für die Teilnehmer:in erziehungsberechtigt sein oder – wenn die Teilnehmer:in am Vertragsbeginn volljährig ist – die Teilnehmer:in selbst; sonst „Vertragsinhaber:in muss eine erziehungsberechtigte Person sein.“ (`GR_HOLDER_INVALID`).
- R5: Wenn die IBAN-Prüfsumme ungültig ist, dann „Die IBAN ist ungültig.“ (`GR_IBAN_INVALID`; Prüfung über `ea_iban_valid`).
- R6: Wenn die Mandatsreferenz (ohne Groß-/Kleinschreibung) bereits in irgendeinem Vertrag vergeben ist, dann „Diese Mandatsreferenz ist bereits vergeben.“ (`GR_MANDATE_TAKEN`).
- R7: Ein Notfallkontakt braucht Telefon mobil, Telefon Festnetz oder E-Mail; sonst „Bitte Telefon oder E-Mail angeben.“ (`GR_CONTACT_REACHABILITY`). Hat eine laufende Teilnahme keinen Notfallkontakt, dann Hinweis „Kein Notfallkontakt hinterlegt.“ in Gruppe und Teilnehmer:in.
- R8: Wenn „Teilnahme bis“ vor dem Eintrittsdatum liegt, dann „‚Teilnahme bis‘ darf nicht vor dem Eintrittsdatum liegen.“ (`GR_LEFT_BEFORE_JOINED`); wenn das Vertragsende vor dem Vertragsbeginn liegt, dann „Das Vertragsende darf nicht vor dem Vertragsbeginn liegen.“ (`GR_CONTRACT_END_BEFORE_START`).
- R8a: Ein Vertrag gehört zu genau einer Teilnahme. Ein weiterer Vertrag ist nur möglich, wenn alle Verträge der Teilnahme ein Vertragsende haben und der neue danach beginnt; sonst „Für diese Teilnahme gibt es bereits einen Vertrag.“ (`GR_CONTRACT_EXISTS`). Beendete Verträge bleiben sichtbar.
- R8b: Vertragsende und „Teilnahme bis“ sind unabhängig. Beim Speichern eines Vertragsendes fragt die Oberfläche „Endet auch die Teilnahme an der Gruppe?“ (Ja: „Teilnahme bis“ = Vertragsende; Nein: unverändert).
- R9: Wenn eine Gruppe eine Teilnahme mit „Teilnahme bis“ leer oder nach dem Auflösungsdatum hat, dann „Die Gruppe hat noch aktive Teilnehmer:innen.“ (`GR_GROUP_HAS_MEMBERS`); bei offener Aufnahme „Die Gruppe hat noch offene Aufnahmen.“ (`GR_GROUP_HAS_PENDING`).
- R10: Wenn die Person bereits eine laufende Teilnahme an derselben Gruppe oder eine offene Aufnahme hat, dann „Diese Person ist bereits in der Gruppe.“ (`GR_ALREADY_MEMBER`) bzw. „Für diese Person gibt es schon eine offene Aufnahme.“ (`GR_PENDING_EXISTS`).
- R11: Gesundheitsangaben liest und schreibt nur, wer mindestens „Gruppen bearbeiten“ hat, die Person im Pfad Gruppen sieht und für die Person eine aktuelle Einwilligung „ja“ vorliegt; nie über „Gruppen lesen“, den Pfad AD oder andere Module; nicht in E-Mail-Liste, Anwesenheitsliste, Exporten, Prüfberichten oder E-Mails.
- R12: Fotoerlaubnis ist ohne Eintrag „nein“; jede Änderung speichert Wert, Datum (Pflicht, ≤ heute), ändernde Person und Zeitpunkt; frühere Stände bleiben sichtbar. Fehlt das Datum: „Bitte das Datum angeben.“ (`GR_CONSENT_DATE_REQUIRED`); Datum in der Zukunft: „Das Datum darf nicht in der Zukunft liegen.“ (`GR_DATE_IN_FUTURE`).
- R13: Die E-Mail-Liste enthält die Adressen der Erziehungsberechtigten der heute aktiven Teilnahmen, bei volljährigen Teilnehmer:innen deren eigene Adresse; ohne Dubletten, getrennt durch „; “. Leer: „Keine E-Mail-Adressen vorhanden.“
- R14: Funktionen in Gruppen sind im Ehrenamtsmanagement nur lesbar: „Diese Angabe wird im Modul Gruppen gepflegt.“ (R39 AD).
- R15: Löschung (nach MVP): 5 Jahre nach dem späteren Datum aus Ende der letzten Teilnahme und Ende des letzten Vertrags [ANNAHME, OFFEN mit Finanzen]; eine Person nur, wenn kein Pfad sie mehr braucht. Im MVP wird nichts gelöscht.
- R16: Eine Teilnahme entsteht nur zusammen mit einem Vertrag (`gr_admit`); direkter Aufruf ohne Vertrag ist nicht möglich: „Eine Teilnahme kann nur mit einem aktiven Vertrag angelegt werden.“ (`GR_CONTRACT_REQUIRED`).
- R17: Wenn eine Teilnahme laufend ist und kein Vertrag der Teilnahme den Status aktiv oder gekündigt hat, dann Hinweis „Vertrag beendet am TT.MM.JJJJ – Teilnahme klären.“ (Datum = größtes Vertragsende) in Übersicht (Zähler), Gruppendetail und Teilnehmer:in; Filter „Teilnahme klären“. Kein automatisches Beenden.
- R18: Wochentag, Beginn, Ende und „gültig von“ sind Pflicht: „Bitte Wochentag, Beginn, Ende und ‚gültig von‘ angeben.“ (`GR_TRAINING_TIME_REQUIRED`); Ende nicht nach Beginn: „Das Ende muss nach dem Beginn liegen.“ (`GR_TRAINING_TIME_END`); „gültig bis“ vor „gültig von“: „‚Gültig bis‘ darf nicht vor ‚gültig von‘ liegen.“ (`GR_VALID_TO_BEFORE_FROM`).
- R19: Trainingszeiten werden nicht überschrieben (A13); „Ändern ab“ beendet die alte zum Vortag und legt eine neue an. Datum für „Ändern ab“ nach „gültig von“ und höchstens am „gültig bis“ der alten: sonst „Das Datum muss nach ‚gültig von‘ und innerhalb der Gültigkeit der bisherigen Trainingszeit liegen.“ (`GR_CHANGE_DATE_INVALID`). Je Gruppe und Wochentag höchstens eine gültige Trainingszeit an jedem Datum, unabhängig von der Uhrzeit; mehrere Wochentage bleiben möglich (Product Owner, 24.10.2026). Anlegen oder „Ändern ab“, das eine zweite Trainingszeit derselben Gruppe am selben Wochentag mit sich überschneidender Gültigkeit ergäbe, wird abgelehnt: „Für diesen Wochentag gibt es in diesem Zeitraum bereits eine Trainingszeit. Bitte die bestehende mit ‚Ändern ab‘ anpassen.“ (`GR_TRAINING_TIME_WEEKDAY_EXISTS`). Der frühere Hinweis auf Überschneidung entfällt (v0.3). Änderungsversuch der Kernfelder: „Wochentag und Uhrzeit können nicht geändert werden. Bitte ‚Ändern ab‘ verwenden.“ (`GR_TRAINING_TIME_LOCKED`).
- R20: `gr_group_roster`, `gr_groups_for_attendance`, `gr_my_groups` liefern nur die in 2.3 genannten Spalten bzw. Schlüssel, nie Geburtsdatum, Alter, Kontaktdaten, Erziehungsberechtigte, Notfallkontakte, Verträge, Bankdaten, Gesundheitsangaben oder Fotoerlaubnis. Rechte und Stichtag nach 2.3.
- R21 (neu): Beim Anlegen oder Ändern einer Gruppe nur aktive Referate; sonst „Dieses Referat ist nicht mehr aktiv.“ (`GR_REFERAT_INACTIVE`).
- R22 (neu): Wenn eine erziehungsberechtigte Person Vertragsinhaber:in eines nicht beendeten Vertrags des Kindes ist, dann kann sie nicht entfernt werden: „Diese Person ist Vertragsinhaber:in. Bitte zuerst den Vertrag ändern.“ (`GR_GUARDIAN_IS_HOLDER`). Doppelte Zuordnung: „Diese Person ist bereits erziehungsberechtigt.“ (`GR_GUARDIAN_EXISTS`).
- R23 (neu): Dieselbe Person nur einmal als Notfallkontakt je Kind: „Diese Person ist bereits Notfallkontakt.“ (`GR_EMERGENCY_EXISTS`).
- R24 (neu): Gesundheitsangaben speichern nur mit aktueller Einwilligung „ja“; sonst „Bitte zuerst die Einwilligung der Erziehungsberechtigten erfassen.“ (`GR_HEALTH_CONSENT_REQUIRED`). Wird die Einwilligung auf „nein“ gesetzt (Widerruf), bleiben die Angaben samt Historie gespeichert, sind aber für niemanden mehr lesbar, bis wieder „ja“ erfasst wird (Entscheidung Product Owner 22.10.2026; Datenschutzhinweis Abschnitt 11). Jede Änderung des Texts erzeugt eine Historienzeile.
- R25 (neu): Mitgliedsnummer gesetzt → Eigenschaft Mitglied mit `is_member` = ja und Nummer; leer → keine neue Eigenschaft; eine vorhandene Eigenschaft wird beim Leeren der Nummer zum Vortag beendet (`valid_to`) [ANNAHME].
- R26 (neu): Neue erziehungsberechtigte Person braucht Vorname, Nachname und Adresse: „Bitte Vorname, Nachname und Adresse angeben.“ (`GR_GUARDIAN_FIELDS_REQUIRED`).
- R27 (neu): Vertragsfelder Pflicht: „Bitte alle Vertragsangaben ausfüllen.“ (`GR_CONTRACT_FIELDS_REQUIRED`); Betrag > 0: „Der Betrag muss größer als 0 sein.“ (`GR_AMOUNT_INVALID`); Mandatsreferenz Format: „Die Mandatsreferenz darf höchstens 35 Zeichen haben und nur Buchstaben, Ziffern und + ? / - : ( ) . , ' enthalten.“ (`GR_MANDATE_FORMAT`); Kontoinhaber:in höchstens 70, Verwendungszweck höchstens 140 Zeichen: „Der Text ist zu lang (höchstens n Zeichen).“ (`GR_TEXT_TOO_LONG`); Unterschriftsdatum in der Zukunft: `GR_DATE_IN_FUTURE`.
- R28 (neu): Dieselbe Funktion derselben Person in derselben Gruppe darf sich zeitlich nicht überschneiden: „Diese Person hat diese Funktion in der Gruppe bereits.“ (`GR_FUNCTION_OVERLAP`).
- R29 (neu): Wird eine Person ohne Ehrenamtsstatus als Gruppenleitung, Trainer:in oder Helfer:in eingetragen, erhält sie den Ehrenamtsstatus „aktiv“ ab „seit“ der Funktion (Historie in `ea_volunteer_status_history`). Ist sie „ruhend“ oder „ausgeschieden“, ändert Gruppen den Status nicht; Hinweis „Die Person ist im Ehrenamtsmanagement ruhend.“ bzw. „… ausgeschieden.“ Ende einer Funktion ändert den Status nicht.

Weitere Meldungen: keine Rechte „Für diesen Bereich hast du keine Rechte.“ (`GR_FORBIDDEN`, `GR_ROSTER_FORBIDDEN`); „Gruppe nicht gefunden.“ (`GR_GROUP_NOT_FOUND`); aufgelöste Gruppe ändern „Die Gruppe ist aufgelöst und kann nicht mehr geändert werden.“ (`GR_GROUP_DISSOLVED`); Geburtsdatum ohne Recht „Das Geburtsdatum kann nur die Geschäftsstelle erfassen.“ (`GR_BIRTH_DATE_FORBIDDEN`); ungültige Personenauswahl „Bitte eine vorhandene Person wählen oder eine neue anlegen.“ (`GR_PERSON_INVALID`); Reihenfolge „Die Reihenfolge ist unvollständig. Bitte neu laden.“ (`GR_ORDER_INVALID`); Wert unverändert „Der Wert ist bereits so gespeichert.“ (`GR_CONSENT_UNCHANGED`); Text Gesundheit „Bitte einen Text mit höchstens 2000 Zeichen eingeben.“ (`GR_HEALTH_NOTE_INVALID`); unerwartet „Etwas ist schiefgelaufen. Bitte versuche es erneut.“ Alle Codes mit Text in `docs/specs/gr-gruppen/contracts/error-codes.md` (T2).

## 6. Screens und Interaktionen

Allgemein wie spec.md AD 6: deutsch, „du“, TT.MM.JJJJ, HH:MM, shadcn/ui, ab 375 px ohne horizontales Scrollen (Tabellen → Karten), Personennamen „Rufname Nachname“ bzw. „Vorname Nachname“. Telefonnummern als `tel:`-Links, E-Mail als `mailto:`. Navigation Gruppen: Gruppen · Aufnahmen offen. Startseiten-Kachel über `ad_my_modules` (setzt `ad_modules.is_available` für GR mit der Freigabe, T19).

| Route | Zeigt | Aktionen | Leerer Zustand / Fehler | Story |
|---|---|---|---|---|
| /gr | `gr_group_overview`: je Gruppe Name, Referat, heutige Trainingszeiten oder „Keine Trainingszeit“, aktive Teilnahmen, Hinweiszähler („Teilnahme klären“, „Kein Notfallkontakt hinterlegt.“, „Aufnahme offen“); Suche Namensteil; Filter Referat; Filter „aufgelöst“ | Gruppe anlegen (edit); Gruppe öffnen | „Keine Gruppen gefunden.“ | US-GR-02 |
| /gr/aufnahmen | offene Aufnahmen: Name, Gruppe, angelegt am/von, Hinweise (fehlende Erziehungsberechtigte) | Aufnahme fortsetzen; Aufnahme abbrechen (Bestätigung „Die Person wird aus Gruppen entfernt. Ihre Daten bleiben gespeichert.“) | „Keine offenen Aufnahmen.“ | US-GR-06 |
| /gr/gruppen/neu, Dialog Ändern | Name, Referat (nur aktive), optional erste Trainingszeit | Speichern | R1, R21 | US-GR-03 |
| /gr/gruppen/:id | Kopf: Name, Referat, heute gültige Trainingszeiten, Gruppenleitung, Trainer:innen, Helfer:innen; Reiter **Teilnehmer:innen** (`gr_v_memberships`: Name, Alter nur bei lesbarem Geburtsdatum, Eintritt, Vertragsstatus, Fotoerlaubnis, Hinweise R7/R17; Filter alle / „Teilnahme klären“ / „beendet“ (nur Admin, da beendete sonst nicht sichtbar)); Reiter **Betreuung** (Funktionen mit seit/bis, beendete aufklappbar); Reiter **Trainingszeiten** (gültige; künftige mit „ab TT.MM.JJJJ“; „Frühere Trainingszeiten“ aufklappbar) | Teilnehmer:in aufnehmen (manage); E-Mail-Adressen kopieren (read); Funktion hinzufügen/beenden; Trainingszeit hinzufügen / Ändern ab / Beenden; Gruppe ändern; Gruppe auflösen (Datum, Bestätigung); aufgelöste Gruppe nur lesend | „Noch keine Teilnehmer:innen.“; „Noch keine Betreuung festgelegt.“; „Keine Trainingszeit.“; R9, R18, R19, R28 | US-GR-04, -05, -13, -15, -18 |
| /gr/gruppen/:id/aufnehmen | Assistent in Schritten, jeder Schritt speichert sofort: 1. Person suchen oder neu (Dublettenprüfung `ad_find_similar_persons`, Dialog nach R3/R40 mit „Trotzdem anlegen“ / „Vorhandene Person übernehmen“ (auch nicht sichtbare Treffer) / „Abbrechen“) → `gr_start_admission`; 2. Erziehungsberechtigte (`gr_add_guardian`, „Adresse übernehmen“); 3. Notfallkontakte; 4. Fotoerlaubnis, Einwilligung und Gesundheitsangaben; 5. Teilnahme und Vertrag (`gr_admit`). Bei Personen mit laufender Teilnahme in anderer Gruppe direkt Schritt 5. Abbrechen jederzeit: Person bleibt unter „Aufnahmen offen“ | Weiter, Zurück, Speichern, Aufnahme abbrechen | R2–R7, R10, R16, R24, R26, R27 | US-GR-06–10, -12 |
| /gr/personen/:id | Teilnehmer:in: **Notfallkontakte** oben (Reihenfolge, Telefon mobil/Festnetz, E-Mail als Links; bei keinem: „Kein Notfallkontakt hinterlegt.“ und darunter Erziehungsberechtigte mit Kontakt); Stammdaten (Name, Rufname, Geburtsdatum und Alter nur bei Recht, Adresse, Kontakt, Mitgliedsnummer); Erziehungsberechtigte; Teilnahmen mit Verträgen (Status, Historie); Fotoerlaubnis mit Historie; Gesundheit (nur edit: Einwilligung mit Historie, Text, Historie aufklappbar, Hinweis „Nur erfassen, wenn eine schriftliche Einwilligung der Erziehungsberechtigten vorliegt. Nur Angaben, die für Training und Ausfahrten nötig sind.“) | Ändern je Abschnitt; Vertrag kündigen (Rückfrage R8b); Folgevertrag; Teilnahme beenden; Erziehungsberechtigte/Notfallkontakte hinzufügen, entfernen, sortieren | R2–R8b, R12, R17, R22–R25 | US-GR-07–12, -14 |
| /gr/personen/:id (Erziehungsberechtigte:r, Notfallkontakt, Betreuer:in) | Stammdaten und Kontakt; „erziehungsberechtigt für …“, „Notfallkontakt für …“, Funktionen | Ändern | R7, R26 | US-GR-07, -09 |

Mobile Notfallweg (US-GR-14): /gr → Gruppe → Kind antippen → Notfallkontakte oben auf /gr/personen/:id (zwei Schritte ab Gruppe). Trefferflächen ≥ 44 px.

E-Mail-Liste: Knopf ruft `gr_guardian_emails`, verbindet mit „; “, kopiert in die Zwischenablage, Meldung „N Adressen kopiert. Bitte in Blindkopie (BCC) einfügen.“

Komponenten der Administration: Dublettendialog (Aktion „Vorhandene Person übernehmen“ für GR nach Ü2), Personensuche über RLS-lesbare Personen (eigene Suche in Gruppen über `ea_v_persons` mit Pfad GR bzw. EA).

## 7. Schnittstellen

| Modul / System | Richtung | Inhalt |
|---|---|---|
| Administration | ↔ | nutzt `ad_has_level`, `ad_has_any_level`, `ad_my_referate`, `ad_me`, `ad_find_similar_persons` (R40 inkl. Ü2: Geburtsjahr nur mit AD lesen, EA verwalten, GR verwalten), `ea_persons`, `ea_v_persons`, `ea_property_*`, `ea_referate`; ersetzt `gr_person_visible`; ergänzt `related_group_id`, R38/R39; braucht `ea_set_status_from_group` (Ü1) und Dublettenaktion für GR (Ü2); `ad_v_person_overview` nutzt für „Gruppenbezug“ `gr_has_current_relation` (Ü3) |
| Ehrenamtsmanagement | ↔ | nutzt System-Eigenschaftsarten `birth_date`, `contact`, `member` und `ea_iban_valid`/`ea_iban_normalize` (Voraussetzung: erste EA-Migration); legt `group_function` an; EA zeigt Funktionen in Gruppen nur lesend (R14) |
| Anwesenheitserfassung | Gruppen → | `gr_group_roster`, `gr_groups_for_attendance`, `gr_my_groups`; FK `ez_events.group_id → gr_groups(id)` |
| Finanzen (später) | Gruppen → | liest `gr_contracts`, `gr_memberships` (eigene Rechte in der FI-Migration ergänzen; Modell SEPA-fähig: IBAN normalisiert, Mandatsreferenz ≤ 35, Unterschriftsdatum, Verwendungszweck ≤ 140, Betrag je Monat, Vertragsende) |
| Öffentlichkeitsarbeit (später) | Gruppen → | Fotoerlaubnis (aktueller Stand) |
| Bestands-Excel | → Gruppen | Importskript (unten) |
| Mitgliederverwaltung | keine | – |

**Importskript** (`scripts/gr-import/`, TypeScript mit `tsx`; Abhängigkeiten `@supabase/supabase-js`, `exceljs`):
- Aufruf `npm run gr:import -- --file <pfad> --dry-run` bzw. `--run`; `--import-date <TT.MM.JJJJ>` (Standard heute; „gültig von“ der Trainingszeiten, A11). Das Skript fragt beim Start die Projekt-URL (`https://<ref>.supabase.co`) und den Secret Key des Projekts ab; der Schlüssel wird verdeckt eingegeben (wie ein Passwort), nur im Arbeitsspeicher gehalten und nie in eine Datei, ein Log oder einen Bericht geschrieben. Es gibt keine `.env`-Datei für das Skript (Constitution Prinzip III; wie spec.md EA v0.2.1 Abschnitt 7; Entscheidung Product Owner 24.10.2026). Leere Eingabe: Abbruch „Schlüssel fehlt.“ Probelauf und Lauf – auch gegen TEST – führt der Admin aus, nicht Claude Code. Liegt die Datei im Repository-Verzeichnis: Abbruch „Die Datei darf nicht im Repository liegen.“ `--run` fragt „Lauf gegen <Projekt-Ref> – zum Bestätigen Projekt-Ref eingeben:“ und führt vorher einen Probelauf aus (Fehler → „Probelauf hat Fehler. Lauf abgebrochen.“).
- Je Tabellenblatt eine Gruppe: F1 Name, C1 Referat („Jugendgruppe“ → Kinder und Jugend; sonst Name eines aktiven Referats, ohne Groß-/Kleinschreibung; unbekannt = Fehler), H1 Trainingszeit (Freitext). Zeilen ab der ersten Datenzeile [ANNAHME: Zeile 3, im Probelauf mit fiktiver Vorlage festzulegen]: B Vorname, C Nachname, D Geburtsdatum, F Mitgliedsnummer, G Name Erziehungsberechtigte:r (Teilung am letzten Leerzeichen: Vorname = alles davor; nicht teilbar = Fehler), H–I Adresse, J Telefon (beginnt mit „01“ oder „+491“ bzw. „00491“ → mobil, sonst Festnetz [ANNAHME]), K E-Mail, L–O Notfallkontakte (je Kontakt Vorname, Nachname und Telefon oder E-Mail; nicht zuordenbare Zellen = Warnung, Kontakt wird nicht angelegt), P Kontoinhaber:in, Q IBAN, R Mandatsreferenz, S Unterschriftsdatum, T Verwendungszweck, U Betrag, V Vertragsbeginn, W gesundheitliche Einschränkungen, X Fotoerlaubnis (ja/nein). Nicht übernommen: E Alter, J1/K1 Bedarf, Y „IBAN korrekt“.
- Trainingszeit: Muster „Mo|Di|Mi|Do|Fr|Sa|So“ bzw. ausgeschriebene Wochentage („Mittwochs“), mehrere mit „+“, „und“, „,“; Zeiten „HH:MM“, „HH“, „HH.MM“, getrennt durch „–“, „-“ oder „bis“, optional „Uhr“. Je Wochentag eine Trainingszeit mit `valid_from = import_date`. Nicht eindeutig lesbar → Warnung, Gruppe ohne Trainingszeit (A11). Zwei Zeiten am selben Wochentag (z. B. „Mi 16–17 + Mi 18–19“) → für diesen Wochentag keine Trainingszeit, Warnung im Prüfbericht beim Tabellenblatt, kein Abbruch (R19, Übergabe G8) [OFFEN, Abschnitt 11: nur dieser Wochentag oder die ganze Gruppe ohne Trainingszeit].
- Erzeugt je Zeile: Person (Kind; Adresse = Adresse der Erziehungsberechtigten), Person Erziehungsberechtigte:r mit Kontaktdaten, Zuordnung, Notfallkontakte, Fotoerlaubnis (`effective_on = import_date`), bei Text in W Einwilligung „ja“ (`effective_on = import_date`) [ANNAHME: Einwilligung liegt mit dem Anmeldebogen vor, OFFEN Steckbrief] und Gesundheitsangabe, Teilnahme (`joined_on` = Vertragsbeginn, A10), Vertrag (Vertragsinhaber:in = Erziehungsberechtigte:r). Dublettenverdacht (gleiche Logik wie `ad_find_similar_persons`, zusätzlich gleiches Geburtsdatum) über alle Blätter und gegen vorhandene Personen: gleiche Person in mehreren Blättern (gleicher Name und Geburtsdatum) → eine Person, mehrere Teilnahmen; sonst Warnung. Erziehungsberechtigte mit gleichem Namen und gleicher E-Mail oder Adresse → eine Person.
- Fehler (blockieren): fehlende Pflichtfelder (R2), Zeile ohne Vertragsdaten (R16), ungültige IBAN, doppelte Mandatsreferenz, unbekanntes Referat, nicht teilbarer Name. Prüfbericht `<datei>.pruefbericht.md` bzw. `.abschlussbericht.md` neben der Datei, ohne Gesundheitsangaben, IBAN nur letzte 4 Stellen (A10). `created_in = 'script'`.
- Repository: `scripts/gr-import/beispiel.xlsx` (fiktiv, alle Fälle); `.gitignore`: `scripts/gr-import/*.xlsx` außer `beispiel.xlsx`, `*.pruefbericht.md`, `*.abschlussbericht.md`.

## 8. Nicht-funktionale Anforderungen

- RLS auf jeder `gr_`-Tabelle; Schreiben nur über Funktionen; Rechteprüfung nie nur im Frontend.
- Mengengerüst: ca. 13 Gruppen, 150–200 Teilnehmer:innen, ca. 300 Erziehungsberechtigte und Notfallkontakte, 50 Betreuer:innen [ANNAHME]. `gr_group_overview` und Gruppendetail < 1 s; `gr_group_roster` < 300 ms; `gr_person_visible` für 500 Personen in einer Liste < 1 s (Mengentest in pgTAP mit 20 Gruppen, 400 Teilnehmer:innen).
- Mobil ab 375 px; Notfallkontakte in höchstens zwei Schritten ab Gruppe.
- pgTAP-Tests je Rechtevorlage (Abschnitt 9), Spaltenlisten der Lesefunktionen, Stichtage, keine Gesundheitsangaben über GR lesen, AD-Pfad oder andere Module.
- Kosten: 0 €; Speicher im Free-Plan ausreichend.
- Echtdaten nur in PROD und auf dem Rechner des Product Owners; Excel nie im Repository, nie in TEST.
- Verarbeitungsverzeichnis: Eintrag „Gruppen Kinder und Jugend“ (Zweck, Kategorien inkl. Gesundheitsangaben, Bankdaten, Zugriffsberechtigte: Geschäftsstelle; Admin ohne Gesundheitsangaben; Nutzer der Anwesenheitserfassung nur Namen; Übernahme nicht sichtbarer Personen macht deren Kontaktdaten für Gruppen-Nutzer sichtbar).

## 9. Testdaten (supabase/seed.sh, nie PROD)

Ergänzung des Seeds der Administration (Personen 1–18) und des Ehrenamtsmanagements (19–22, spec.md EA 9). Alle Daten fiktiv; IBANs gültige Test-IBANs ohne echte Konten (z. B. DE89370400440532013000 und Varianten mit korrekter Prüfsumme); Stichtag der Daten relativ zu `current_date` des Seed-Laufs, damit Status stabil bleiben [ANNAHME].

Gruppen: „Jugendgruppe Test 1“ (Kinder und Jugend; Di 16:30–18:00 und Do 17:00–18:30 seit 01.09.2025), „Jugendgruppe Test 2“ (Kinder und Jugend; Mi 17:00–18:30 bis 31.12.2025, Mi 18:00–19:30 seit 01.01.2026), „Klettergruppe Test“ (Klettern; ohne Trainingszeit), „Altgruppe Test“ (Kinder und Jugend; aufgelöst am 30.06.2025).

| # | Person | Rolle | Besonderheit |
|---|---|---|---|
| 23 | Mia Fiktiv (Kind, Geburtsdatum vor 12 Jahren) | Teilnehmer:in Test 1 und Klettergruppe | zwei Teilnahmen, zwei Verträge; Notfallkontakte 24, 29; Gesundheit mit Einwilligung „ja“ und Text; Fotoerlaubnis ja |
| 24 | Jana Fiktiv | Erziehungsberechtigte von 23 und 25, Vertragsinhaberin | Geschwister-Fall; E-Mail gesetzt |
| 25 | Ben Fiktiv (Kind) | Teilnehmer Test 2 | Vertrag beendet vor 10 Tagen, Teilnahme offen (R17); kein Notfallkontakt (R7) |
| 26 | Lars Lehrer | Erziehungsberechtigter von 27 und Trainer Test 1 | Elternteil zugleich Trainer:in; Ehrenamtsstatus aktiv |
| 27 | Lea Lehrer (Kind) | Teilnehmerin Test 1 | „Teilnahme bis“ vor 30 Tagen (Stichtag, nur Admin sieht sie) |
| 28 | Sam Sechzehn (16 Jahre) | Teilnehmer Test 2 und Helfer Test 1 | Jugendliche:r zugleich Helfer:in |
| 29 | Erika Oma | Notfallkontakt von 23 | nur Telefon mobil |
| 30 | Paula Plan | offene Aufnahme Test 2 | nur Person, noch ohne Erziehungsberechtigte |
| 31 | Tom Ehemals | Trainer Test 2 bis vor 60 Tagen | beendete Funktion (Stichtag US-GR-19) |
| 32 | Kim Kinderjugend | Testzugang test.kiju@dav-leipzig.de, Referent:in (Referat Kinder und Jugend) | für US-GR-17 AK5; Amt Referent:in K+J |

Zusätzlich: Gesundheitsangabe für 25 mit Einwilligung „nein“ nach vorherigem „ja“ (Widerruf, Text vorhanden aber nicht lesbar).

Erwartete Ergebnisse (pgTAP):

| Testzugang | sieht Kinder 23, 25, 28, 30 | sieht 27 (beendet) | Geburtsdatum Kind | Gesundheit 23 | Gesundheit 25 | Roster Test 1 heute | Roster Klettergruppe |
|---|---|---|---|---|---|---|---|
| Admin (AD, GR lesen, EZ lesen) | ja | ja (Pfad AD) | ja (Pfad AD) | nein | nein | Liste | Liste |
| Geschäftsstelle (GR verwalten) | ja | nein | ja | ja | nein (Widerruf) | Liste | Liste |
| Rita Referentin (Klettern, EZ Referat) | nein | nein | nein | nein | nein | `GR_ROSTER_FORBIDDEN` | Liste (nur Namen) |
| Kim Kinderjugend (K+J, EZ Referat) | nein | nein | nein | nein | nein | Liste (nur Namen) | `GR_ROSTER_FORBIDDEN` |
| Vorstand | nein | nein | nein | nein | nein | `GR_ROSTER_FORBIDDEN` | `GR_ROSTER_FORBIDDEN` |
| Vorstand mit GR lesen (im Test zugewiesen) | ja | nein | nein, Alter leer | nein | nein | Liste | Liste |

Weiter: `gr_group_roster(Test 1, Datum vor 40 Tagen)` enthält 27; `gr_group_roster(Test 2, Datum vor 90 Tagen)` enthält 31 als `trainer`; 28 erscheint in Test 1 als `helper` und in Test 2 als `participant`; `gr_group_roster(Altgruppe, heute)` → `GR_GROUP_NOT_FOUND`; Trainingszeiten Test 2 an einem Mittwoch 2025 = 17:00–18:30, 2026 = 18:00–19:30. `gr_my_groups` für Lars Lehrer (falls Testzugang) bzw. per `set_config` simuliert: Test 1, `trainer`, Wochentage {2,4}. Person 26 erscheint im Ehrenamtsmanagement für die Geschäftsstelle mit Funktion „Trainer:in – Jugendgruppe Test 1“ (nur lesbar); Person 23 nicht. `gr_guardian_emails(Test 1)` enthält Janas Adresse genau einmal.

## 10. Umsetzungs-Tasks

Voraussetzungen: Kern der Administration (T1–T49) inkl. Ü2 aus EA (`birth_year`); erste EA-Migration (System-Eigenschaftsarten, `ea_iban_valid`); Administration Ü1–Ü3 dieser Spec; für T8 zusätzlich Administration v0.8 T50 (Modul EZ, Startwerte EZ) und Reichweite „Referat“ für EZ (T33/T52). Je Story ein Branch und ein Pull Request mit vollständiger Cloudflare-Vorschau-URL; pgTAP grün.

- [ ] T1: Migration Gruppen-Basis: `gr_today`, `gr_groups`, `gr_training_times` mit Checks, Trigger (Sperre der Kernfelder), RLS; `ea_properties.related_group_id`, `ea_property_history.related_group_id`, Erweiterung `ea_properties_validate`/`ea_properties_history` (R38), `ea_property_writable` (R39); System-Eigenschaftsart `group_function` (US-GR-01, -03, -18)
- [ ] T2: Migration Personenbezug: `gr_pending_admissions`, `gr_memberships`, `gr_contracts`, `gr_guardians`, `gr_emergency_contacts`, `gr_photo_consents`, `gr_health_consents`, `gr_health_notes`, `gr_health_note_history` mit Trigger; `gr_has_current_relation`, `gr_person_visible` (Ersatz), `gr_row_visible`, `gr_is_adult`, `gr_can_read_health`, `gr_contract_status`; RLS nach Abschnitt 3; `contracts/error-codes.md` (US-GR-01)
- [ ] T3: Funktionen Gruppen und Trainingszeiten: `gr_save_group`, `gr_dissolve_group`, `gr_add_training_time`, `gr_change_training_time`, `gr_end_training_time` (US-GR-03, -04, -18)
- [ ] T4: Funktionen Personen und Aufnahme: `gr_start_admission`, `gr_cancel_admission`, `gr_update_person`, `gr_copy_address`, `gr_add_guardian`, `gr_remove_guardian`, `gr_add_emergency_contact`, `gr_remove_emergency_contact`, `gr_reorder_emergency_contacts` (US-GR-06, -07, -09)
- [ ] T5: Funktionen Teilnahme und Vertrag: `gr_admit`, `gr_add_contract`, `gr_update_contract`, `gr_cancel_contract`, `gr_end_membership` (US-GR-08, -11)
- [ ] T6: Funktionen Fotoerlaubnis, Einwilligung, Gesundheit: `gr_set_photo_consent`, `gr_set_health_consent`, `gr_save_health_note` (US-GR-10, -12)
- [ ] T7: Funktionen in Gruppen: `gr_add_group_function`, `gr_end_group_function` mit `ea_set_status_from_group` (Ü1) (US-GR-13)
- [ ] T8: Lesefunktionen: `gr_v_memberships`, `gr_group_overview`, `gr_guardian_emails`, `gr_group_roster`, `gr_groups_for_attendance`, `gr_my_groups` (US-GR-02, -05, -15, -19, -20)
- [ ] T9: Seed-Erweiterung nach Abschnitt 9 inkl. Testzugang Kim Kinderjugend; Abbruch in PROD (US-GR-17)
- [ ] T10: pgTAP: Rechte je Testzugang nach Tabelle Abschnitt 9; R1–R29; Spaltenlisten bzw. JSON-Schlüssel der Lesefunktionen; Stichtage; Gesundheitsangaben nie mit GR lesen, AD-Pfad, EA, EZ; Widerruf; die drei Tests aus T45 der Administration (Teilnehmer:in nicht über EA lesbar; Erziehungsberechtigte:r zugleich Trainer:in über EA ohne gruppenspezifische Daten; nur „Gruppen lesen“ liest Kontaktdaten, nicht Geburtsdatum; Funktion in Gruppe im EA nicht änderbar); Mengentest (US-GR-01, -17, -19, -20)
- [ ] T11: Frontend Übersicht /gr und Navigation, Routenschutz (US-GR-02)
- [ ] T12: Frontend Gruppe anlegen, ändern, auflösen, Trainingszeiten (US-GR-03, -04, -18)
- [ ] T13: Frontend Gruppendetail mit Reitern, E-Mail-Liste (US-GR-05, -15)
- [ ] T14: Frontend Aufnahme-Assistent und /gr/aufnahmen inkl. Dublettendialog (US-GR-06–10, -12)
- [ ] T15: Frontend Personendetail inkl. Notfallansicht mobil, Verträge, Kündigung, Folgevertrag, Gesundheit (US-GR-07–12, -14)
- [ ] T16: Frontend Betreuung (Funktionen mit Statushinweis) (US-GR-13)
- [ ] T17: Anzeige Funktion in Gruppe im Ehrenamtsmanagement prüfen (nur lesen, Gruppenname) – Abnahme mit Seed (US-GR-13 AK3)
- [ ] T18: Importskript `scripts/gr-import/` mit `gr_import_groups`, Beispieldatei, Probelauf, Bericht (US-GR-16)
- [ ] T20 (neu v0.3): Migration Trainingszeit je Wochentag: Prüfung nach R19 in der Datenbank, `GR_TRAINING_TIME_WEEKDAY_EXISTS` in `gr_add_training_time` und `gr_change_training_time`, Rückgabe ohne `overlap`; pgTAP (Ablehnung am selben Wochentag, „Ändern ab“ möglich, zweiter Wochentag erlaubt, `gr_group_roster` höchstens ein Eintrag); Frontend Trainingszeit-Dialog Fehler statt Hinweis; Import nach Abschnitt 7 (US-GR-16, -18, -19)
- [ ] T19: Migration `ad_modules.is_available = true` für GR nach Abnahme (Freigabe Product Owner)

## 11. Annahmen und offene Punkte

Entschieden vom Product Owner am 22.10.2026 (Chat Gruppen):
- A11 bestätigt: Import „gültig von“ = Importdatum; nicht lesbare Trainingszeiten brechen nicht ab.
- A12 bestätigt: Auflösen beendet offene Trainingszeiten zum Auflösungsdatum.
- „Gruppe nicht gefunden.“ bei unbekannter oder am Datum bereits aufgelöster Gruppe (US-GR-19 AK6) bestätigt.
- W2: Nutzer mit nur „Gruppen lesen“ sehen weder Alter noch Geburtsdatum.
- W6: Gruppen setzt „aktiv“ für Gruppenleitung, Trainer:in, Helfer:in ohne Status; bei ruhend/ausgeschieden nur Hinweis.
- W5: Referent:innen sehen Betreuer:innen der Gruppen ihres Referats im Ehrenamtsmanagement nur mit eigener Funktion oder eigenem Amt mit Referatsbezug (keine Änderung an `ea_person_in_referate`).
- W7: Zwischenspeichern bei der Aufnahme („Aufnahme offen“); Abbrechen entfernt die Person aus Gruppen.
- Übernahme nicht sichtbarer Dublettentreffer ab „Gruppen bearbeiten“.
- W3: Telefon mobil und Festnetz getrennt.
- W8: Funktionen aus der Aktivenliste werden nicht importiert (Nacharbeit über US-GR-13).
- US-GR-12: Einwilligung zu Gesundheitsangaben als eigenes Feld mit Datum und Historie; Widerruf: Angaben bleiben gespeichert, sind nicht mehr lesbar; Historie der Gesundheitsangaben wird aufbewahrt.
- Personen ohne laufenden Bezug zu Gruppen sind nur noch für den Admin sichtbar.

**Datenschutzhinweis zu R24 (bestätigt 22.10.2026; Klärung mit Datenschutzbeauftragter:m vor Go-live, siehe unten):** Nach einem Widerruf der Einwilligung (Art. 7 Abs. 3, Art. 9 Abs. 2 a DSGVO) fehlt in der Regel die Rechtsgrundlage für die weitere Speicherung; Art. 17 Abs. 1 b verlangt dann die Löschung, sofern keine andere Rechtsgrundlage greift. „Behalten, nicht anzeigen“ und die Aufbewahrung der Historie sind daher rechtlich angreifbar. Vorschlag: im MVP wie entschieden umsetzen, aber vor Go-live mit der bzw. dem Datenschutzbeauftragten klären; das Datenmodell erlaubt ein späteres Löschen (Text und Historie je Person).

Bestätigt vom Product Owner am 22.10.2026:
- Geburtsdatum-Eigenschaft mit `valid_from` = Geburtsdatum; Kontaktdaten mit `valid_from` = Anlagedatum.
- Neue Teilnehmer:innen kann nur anlegen, wer das Geburtsdatum erfassen darf (GR verwalten); „Gruppen bearbeiten“ ohne Wirkung im MVP.
- Auflösungsdatum ≤ heute; offene Aufnahmen verhindern das Auflösen.
- Vertragsende braucht ein Kündigungsdatum; Status am Tag des Vertragsendes „gekündigt“, ab dem Folgetag „beendet“.
- Folgevertrag beginnt nach dem letzten Vertragsende (keine Überschneidung).
- Volljährigkeit für R4 am Vertragsbeginn, für R13 am heutigen Tag.
- Mandatsreferenz eindeutig über alle Verträge, auch beendete; SEPA-Zeichensatz und Längen (35/70/140).
- Betrag je Monat > 0.
- Fotoerlaubnis und Einwilligung: Datum Pflicht für ja und nein, nicht in der Zukunft.
- Gesundheitsangabe kann nicht geleert, nur überschrieben werden; höchstens 2000 Zeichen.
- Mitgliedsnummer leeren beendet die Eigenschaft Mitglied zum Vortag (R25).
- `gr_groups` lesbar auch mit EA-Rechten (Gruppenname bei der Funktion im Ehrenamtsmanagement).
- Gleiche Funktion derselben Person in derselben Gruppe nicht überschneidend (R28); verschiedene Funktionen gleichzeitig erlaubt.
- Import: erste Datenzeile, Teilung der Namen am letzten Leerzeichen, Telefon-Zuordnung nach Vorwahl, Einwilligung „ja“ bei vorhandenem Gesundheitstext, Erkennung derselben Person über Name und Geburtsdatum.
- Seed-Personen 23–32 und Testzugang test.kiju@dav-leipzig.de.
- Funktionen und Trainingszeiten, die erst nach dem Auflösungsdatum beginnen, bleiben unverändert.

Aus der Übergabe der Anwesenheitserfassung (uebergabe-gruppen.md v1.0): Wortlaut der Ablehnung festgelegt (Product Owner, 24.10.2026, R19). Weiter offen, Blocker für T20 bzw. T18:
- [OFFEN] Gilt die Ablehnung auch, wenn `gr_end_training_time` das „gültig bis“ so verlängert, dass sich die Trainingszeit mit einer späteren am selben Wochentag überschneidet? Die Übergabe (G7) nennt nur Anlegen und „Ändern ab“. Vorschlag: ja, gleicher Code (US-GR-18 AK8).
- [OFFEN] Import bei zwei Zeiten am selben Wochentag: entfällt nur dieser Wochentag (andere Wochentage desselben Kopfs werden übernommen) oder wird die ganze Gruppe ohne Trainingszeit angelegt? Vorschlag: nur dieser Wochentag (US-GR-16 AK8).

Weiter offen, kein Blocker für die Umsetzung:
- [OFFEN] Ist die ausdrückliche Einwilligung zu Gesundheitsangaben im bestehenden Anmeldebogen enthalten? (vor Go-live; betrifft Import)
- [OFFEN] Rechtsgrundlage für Notfallkontakte ohne Erziehungsberechtigung (vor Go-live).
- [OFFEN] Löschfristen und Aufbewahrung Vertrags-/Mandatsdaten mit Finanzen (vor dem Löschlauf, nach MVP).
- [OFFEN] Bankdaten für Gruppenleitung und Trainer:innen nach MVP (Iteration mit Zugang).
- [OFFEN] Speicherung von Gesundheitsangaben nach Widerruf (R24) mit Datenschutzbeauftragter:m klären (vor Go-live).

## Nachtrag v0.4: Lesefunktion für den Buchungslauf (Finanzen) – Ready (26.10.2026)

Grundlage: specs/fi-finanzen/uebergabe-gruppen.md v1.0 (G1–G4).

- `gr_contracts_for_collection(p_month date, p_ids uuid[] default null) returns setof (contract_id, membership_id, group_id, group_name, referat_id, participant_person_id, participant_first_name, participant_preferred_name, participant_last_name, holder_person_id, holder_first_name, holder_preferred_name, holder_last_name, account_holder, iban, mandate_reference, mandate_signed_on, purpose, monthly_amount, starts_on, ends_on, bank_check)` – security definer, stable; nur mit `ad_has_level('FI','manage')`, sonst `GR_FORBIDDEN`. Mit `p_ids`: genau diese Verträge (Wiederabruf); sonst alle Verträge mit `starts_on <= p_month` und (`ends_on is null or ends_on >= p_month`). `bank_check` = md5(IBAN || '|' || Kontoinhaber:in). Keine weiteren Felder (G1, G2).
- G3: Verträge werden nicht gelöscht, solange Einzüge in Finanzen auf sie verweisen (Fremdschlüssel on delete restrict); Löschfrist bleibt nach R15.
- G4: Doppelte Mandatsreferenzen in den Bestandsdaten bereinigt die Geschäftsstelle vor dem Import; der Probelauf meldet sie (R6).
- Task: T053 Migration und pgTAP (Umsetzung mit FI FT18).
