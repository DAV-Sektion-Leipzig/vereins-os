# Spec: Planungshilfe Touren und Kurse (TK)

Version: 0.4 · Status: **Ready** (freigegeben am 26.10.2026; verbleibende [OFFEN]-Punkte in Abschnitt 11 blockieren den Start nicht) · Stand: 26.10.2026 · Product Owner: Toni Werner
Stories: docs/specs/tk-touren-kurse/02-stories.md (US-TK-01 bis US-TK-24, v0.4)
Grundlage: 00-steckbrief.md v0.8, 01-erhebung.md v0.8 (B1–B9, R1–R11), 02-stories.md v0.5, pruefliste-referat-touren.md v1.0 (A1–A12), prototyp-tourenkonzept.md (im Folgenden „Prototyp“ mit Abschnittsnummer), glossar.md v1.7, rollen.md v1.3, tech-stack.md v0.6, spec.md Administration v0.11 (`ad_has_level`, `ad_my_referate`, `ad_has_any_level`, `ad_can_approve`, `ad_rates_at`, `ad_remuneration_kinds`, `ea_referate`, `ea_person_names`, `ea_search_active_persons`, `ea_person_licenses`), spec.md Anwesenheitserfassung v0.6 (`ez_upsert_planned_event`, `ez_cancel_planned_event`, `ez_planned_event_state`), spec.md Finanzen v0.3; Übergaben an Administration v1.8, Anwesenheitserfassung v1.3, Finanzen v1.3; Übergaben an die Planungshilfe: specs/ad-administration/uebergabe-planungshilfe-freigabe.md v1.0 (P1–P5), specs/fi-finanzen/uebergabe-planungshilfe.md v1.0 (T1–T7)
Änderungen v0.4 (26.10.2026): Status Ready (Product Owner); keine Abweichung vom Lizenz-Ergebnis durch die freigebende Person (Lizenz wird im Ehrenamtsmanagement nachgetragen); restliche Annahmen aus Steckbrief und Erhebung bestätigt (Statusmodell, Admin liest, Berechnung in der Datenbank, PDF der Einreichung nicht gespeichert, Planwerte nur Vorbelegung); Begriffe im Glossar v1.7.
Änderungen v0.3 (26.10.2026, Wiederaufnahme, Abgleich mit dem Stand der anderen Module): Freigaberecht über die Aktion „darf freigeben“ der Administration (`ad_can_approve('TK', referat)`) statt Modul TKF (Übergabe AD → TK P1–P5); Titel ohne Kürzung (Anwesenheitserfassung erlaubt 90 Zeichen); Enduhrzeit beim Publizieren keine Pflicht mehr (Beginn und Ende mehrtägiger Einsätze in EZ optional); Abrechnungsart des Einsatzes: Gemeinschaftstour übergibt „Gemeinschaftstour“ an die Anwesenheitserfassung (Product Owner 26.10.2026, Übergabe an EZ v1.3); Kurse auch mehrtägig nur nach Lehreinheiten, ohne Vorschlag bei mehrtägigen Kursen, ohne Organisationspauschale (Product Owner 26.10.2026; R22); Trainersatz auch bei Erwerb der Lizenz im Halbjahr des Startdatums, wie in Finanzen (Product Owner 26.10.2026, Übergabe FI → TK T2; Übergabe an AD v1.8); Folgen aus der Übergabe FI → TK (T1–T7) eingearbeitet; Voraussetzungen an den Umsetzungsstand angepasst. Zweiter Teil (Product Owner 26.10.2026): externe Leitende direkt aus der Planung anlegen bzw. wieder aktivieren (R23, `tk_create_leader`, `tk_reactivate_leader`, `tk_privacy_confirmations`; Übergabe an AD v1.8 Punkt 16); „in Yolawo angelegt“ nur mit Freigaberecht oder Geschäftsstelle; Löschfrist Kontaktdaten 30 Tage; Annahmen der Stories und der Spec bestätigt; Prototyp-Werte als Startbestand mit Prüfliste für das Referat Touren (pruefliste-referat-touren.md), Flug-Warnung ab 1.000 km; Material nur als Ausrüstungsliste.
Änderungen v0.2: Übergabe an die Administration in spec.md AD v0.9 eingearbeitet (Modul TK und TKF, `ad_rates`, `ea_person_licenses`, `tk_person_visible`); Namen der Testpersonen an den Seed der Administration angeglichen; Stories v0.4.
Änderungen v0.1: Erster Entwurf.

**Voraussetzungen für die Umsetzung (Stand 26.10.2026):**
1. Administration: schon umgesetzt sind die Aktion „darf freigeben“ (T68, `ad_can_approve`), Reichweite „Referat“ für TK (R30), `ad_rates` mit `ad_rates_at` und die Sätze der Vergütung (T60, T61 Teil), Abrechnungsarten mit Vorbelegung (T69). **Noch umzusetzen vor der ersten Migration der Planungshilfe:** Nachtrag v0.9 T59 (Modul TK, Startwerte, Vorlage „Freigabe Touren und Kurse“ mit „darf freigeben“), T61 Rest (Schlüssel der Planungshilfe außerhalb der Vergütung, Abschnitt 7), T62 (`tk_person_visible`, Namen, Suche, `ea_person_licenses` mit Erwerbsdatum nach Übergabe an AD v1.8), T63–T67.
2. Anwesenheitserfassung: Tabelle und Spalten sind umgesetzt (`ez_events.tk_plan_id`, `cancelled_*`, `ez_attendances.from_plan`); die Funktionen `ez_upsert_planned_event` (mit Abrechnungsart nach Übergabe an EZ v1.3), `ez_cancel_planned_event` und `ez_planned_event_state` (EZ T036–T038) entstehen zusammen mit T13 der Planungshilfe, weil sie `tk_can_write` und `tk_can_read` nutzen.
3. Die Planungshilfe legt keine Tabellen oder Funktionen anderer Module an; Ausnahme: die Funktionen aus 2. entstehen im selben Pull Request, gehören fachlich zur Anwesenheitserfassung.

## 1. Ziel und Scope

**Ziel:** Das Erhebungsformular des HTML-Prototyps „Tourenkonzept“ (Schritte 1–7) vollständig im Vereins OS, mit Status, Freigabe, Leitung aus den Aktiven, Kalkulation, CO2-Bilanz je Planung, Yolawo-Ausgaben und Kostenauswertung; alle Angaben strukturiert in der Datenbank (R10). Erfolg: Die Beispieldaten des Prototyps (Abschnitt 3.5, angepasst nach Abschnitt 9 dieser Spec) ergeben in TEST dieselben Werte wie der Prototyp (735 € Gesamtkosten, Vorschlag 160 €, kostendeckend ab 5, CO2 Tour 564,3 kg), abgesehen von den gewollten Änderungen (Abschnitt 5, R14).

**Im Scope (MVP):** US-TK-01 bis US-TK-24 (Must, Should, Could laut Stories).

**Nicht im Scope:**
- PDF-Übernahme aus dem HTML-Formular (Referat überträgt von Hand).
- Stornoregel und Rückerstattung (R11).
- CO2-Auswertung über mehrere Planungen (Iteration 1); Eingabe durch Tourenleitende, öffentliches Formular, Ablösung des HTML-Formulars (Iteration 2).
- Pflegeoberfläche der Sätze (Administration); Ist-Kosten, Belege, Auszahlung (Finanzen); Erfassung der Anwesenheit (Anwesenheitserfassung).
- Anmeldung und Zahlung (Yolawo); Schnittstelle zu Yolawo; Foto-Upload; E-Mail-Benachrichtigungen.
- Anmeldung von Fahrten (Kinder- und Jugendfahrten), Material der Sektion.

## 2. Datenmodell

Konventionen nach tech-stack.md: Schema `public`, Präfix `tk_`, snake_case, RLS auf jeder Tabelle. Datum und Uhrzeit lokal (Europe/Berlin) ohne Zeitzone (`date`, `time`, `timestamp`). Beträge `numeric(10,2)`, Mengen `numeric(10,2)`. Audit-Spalten per Default bzw. Trigger. Direktes Insert/Update/Delete auf `tk_`-Tabellen ist für `authenticated` nicht erlaubt; geschrieben wird nur über die Funktionen in diesem Abschnitt.

### Typen

| Typ | Werte (Code → Oberfläche) |
|---|---|
| `tk_plan_type` | `guided_tour` → Führungstour · `course` → Kurs / Ausbildungstour · `community_tour` → Gemeinschaftstour |
| `tk_plan_status` | `draft` → Entwurf · `submitted` → eingereicht · `query` → Rückfrage · `approved` → freigegeben · `published` → in Yolawo angelegt · `done` → durchgeführt · `closed` → abgeschlossen · `cancelled` → abgesagt |
| `tk_leader_role` | `lead` → Leitung · `co_lead` → Co-Leitung · `helper` → Helfer:in |
| `tk_rate_kind` | `trainer` → Trainer:in · `helper` → Helfer:in (berechnet, R2) |
| `tk_transport` | `rail_long` (bahnFV) · `rail_regional` (bahnNV) · `coach` (bus) · `local_bus` (linienbus) · `tram` · `car` (pkw) · `ecar` (epkw) · `van` · `flight` (flug) · `bike` (rad) – Bezeichnungen Prototyp 5.3 |
| `tk_accommodation` | `none` · `hut` · `self_catering` (svh) · `hotel` · `camping` – Bezeichnungen Prototyp 3.1 |
| `tk_cost_group` | `leader` (Kosten der Leitung) · `fixed` (Sonstige Tourkosten) · `per_participant` (Leistungen je TN) · `self_paid` (Selbst zu zahlen) |
| `tk_prebriefing` | `none` · `online` · `office` (praesenz) |
| `tk_public_transport` | `together` (gemeinsam) · `possible` (moeglich) · `not_possible` (nein) |
| `tk_image_source` | `own` (eigen) · `referat` |
| `tk_fitness` | `low` (gering) · `medium` (mittel) · `high` (groß) · `very_high` (sehr groß) |
| `tk_technique` | `easy` (leicht) · `medium` (mittel) · `hard` (schwer) · `very_hard` (sehr schwer) |
| `tk_yolawo_by` | `referat` (Das Tourenreferat) · `leader` (Ich selbst, mit eigenem Yolawo-Zugang) |

Freie Auswahllisten als `text` mit Check gegen feste Werte (Werte und Anzeige wie Prototyp 3.1/3.3): `sport` (15 Sportarten), `target_groups text[]` (Familienwanderungen, Flinke Füße, Einsteiger, FLINTA*), `registration_questions text[]` (11 Werte aus Prototyp 3.3).

### tk_plans (Planung)

| Spalte | Typ | Pflicht | Default | Beschreibung / Prototyp-Feld |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| plan_type | tk_plan_type | ja | – | `typ` |
| referat_id | uuid | ja | – | FK ea_referate(id); vom Trigger aus plan_type: `course` → Referat Ausbildung, sonst Referat Touren (R12) |
| status | tk_plan_status | ja | 'draft' | nur über Statusfunktionen änderbar |
| title | text | ja | – | `titel`, getrimmt, 1–90 Zeichen |
| community_reason | text | nein | null | `gtGrund`; Pflicht zum Einreichen bei Gemeinschaftstour |
| sport | text | nein | null | `sportart` |
| target_groups | text[] | ja | '{}' | `c.zusatz` |
| region, base, teaser, programme | text | nein | null | `region`, `stuetzpunkt`, `teaser`, `programm` |
| image_source | tk_image_source | nein | null | `bild` |
| image_credit | text | nein | null | `bildrechte` |
| start_date, end_date | date | nein | null | `dStart`, `dEnd` |
| meet_time, end_time | time | nein | null | `tStart`, `tEnd` |
| meeting_point, meeting_coords | text | nein | null | `treffpunkt`, `koord` |
| prebriefing | tk_prebriefing | ja | 'none' | `vorbesprechung` |
| prebriefing_at | timestamp | nein | null | `vbDatum`; null bei `none` |
| public_transport | tk_public_transport | nein | null | `oev` |
| travel_notes | text | nein | null | `anreise` |
| accommodation | tk_accommodation | ja | 'none' | `unterkunft` |
| nights | int ≥ 0 | nein | null | `naechte` |
| co2_persons | int ≥ 0 | nein | null | `co2Pers` |
| meeting_near_pt | boolean | ja | false | `oevTreff` |
| max_walk_hours | numeric(4,1) ≥ 0 | nein | null | `gehzeit` |
| max_ascent, max_descent | int ≥ 0 | nein | null | `hmAuf`, `hmAb` |
| max_distance_km | numeric(6,1) ≥ 0 | nein | null | `km` |
| fitness | tk_fitness | nein | null | `kond` |
| technique | tk_technique | nein | null | `tech` |
| grade, requirements, equipment | text | nein | null | `grad`, `vorauss`, `ausruestung` |
| non_members_allowed | boolean | ja | false | `auchNM` (Standard: nur DAV-Mitglieder) |
| non_members_reason | text | nein | null | `nmGrund` |
| min_participants, max_participants | int ≥ 1 | nein | null | `minTN`, `maxTN` |
| registration_deadline | date | nein | null | `anmeldeschluss` |
| waitlist | boolean | ja | true | `warteliste` |
| accommodation_cancellation | text | nein | null | `stornoUnterkunft` (Stornobedingungen der Unterkunft, intern; bleibt, R11 betrifft nur die Stornoregel der Sektion) |
| registration_questions | text[] | ja | 6 Standardwerte (Prototyp 3.3) | `c.fragen` |
| custom_question | text | nein | null | `frageEigen` |
| days_full, days_half, teaching_hours, org_days | int ≥ 0 | nein | null | `tageVoll`, `tageHalb`, `lehrStd`, `orgTage`; bei Kurs nur `teaching_hours` (R22) |
| car_reason | text | nein | null | `pkwGrund` |
| no_fee | boolean | ja | false | `ohneBeitrag` |
| price_member, price_non_member | numeric(10,2) ≥ 0 | nein | null | `preisM`, `preisN`; null = Vorschlag verwenden |
| yolawo_by | tk_yolawo_by | ja | 'referat' | `ylw` |
| notes_for_referat | text | nein | null | `hinweise` |
| confirm_license, confirm_calculation, confirm_ul_declaration, confirm_emergency_card | boolean | ja | false | `c1`–`c4` |
| feedback_form | boolean | ja | false | `evaluation` |
| touched | text[] | ja | '{}' | Felder mit Vorschlag, die geändert wurden: `days_full`, `days_half`, `org_days`, `teaching_hours`, `nights`, `co2_persons` (Prototyp 4.2; `teaching_hours` nur bei eintägigem Kurs, R22) |
| rates_frozen_on | date | nein | null | gesetzt bei `approved`: Satzstand eingefroren (R3) |
| yolawo_ref | text | nein | null | Link oder Nummer des Angebots, max. 200 Zeichen |
| ez_event_id | uuid | nein | null | Einsatz in der Anwesenheitserfassung (kein FK, um keine Abhängigkeit in der Migration zu erzeugen [ANNAHME]; Konsistenz über `ez_events.tk_plan_id`) |
| cancelled_at | timestamptz | nein | null | Zeitpunkt der Absage |
| cancel_reason | text | nein | null | Pflicht bei Absage, 1–500 Zeichen |
| contacts_purged_at | timestamptz | nein | null | Löschung der Kontaktdaten (R16) |
| row_version | int | ja | 1 | Schutz gegen gleichzeitiges Bearbeiten (R20) |
| client_request_id | uuid | ja | – | unique; Schutz gegen doppeltes Anlegen |
| created_at/_by, updated_at/_by, created_by_person_id, updated_by_person_id | | | | Audit wie Anwesenheitserfassung |

Checks: `end_date >= start_date`; `prebriefing_at is null` bei `none`; `title` 1–90; Längen der Freitexte max. 4.000 Zeichen [ANNAHME]; `target_groups` und `registration_questions` nur erlaubte Werte; `sport` nur erlaubte Werte.

Indizes: `(referat_id, start_date)`, `(status)`, `(start_date)`, unique `(client_request_id)`.

### tk_plan_leaders (Leitung und Helfende)

| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| plan_id | uuid | ja | – | FK tk_plans on delete cascade |
| person_id | uuid | ja | – | FK ea_persons(id) on delete restrict; Ehrenamtsstatus „aktiv“ beim Hinzufügen (R13) |
| role | tk_leader_role | ja | 'lead' | Rolle in der Planung |
| sort_order | int | ja | – | Reihenfolge (erste `lead` = organisierende Person, R15) |
| rate_kind | tk_rate_kind | ja | 'helper' | berechnet bei jedem Speichern (R2); nicht vom Frontend |
| license_type_id | uuid | nein | null | Qualifikationsart der Lizenz, die den Trainersatz begründet (aus `ea_person_licenses`) |
| license_valid_from | date | nein | null | Erwerbsdatum dieser Lizenz (Kopie, für R2 und Nachvollziehbarkeit) |
| license_valid_until | date | nein | null | Ablaufdatum dieser Lizenz (Kopie zum Satzstand, für Nachvollziehbarkeit) |

Unique `(plan_id, person_id)` (R17).

### tk_plan_contacts (Kontakt- und Notfalldaten, eigene Tabelle wegen RLS)

| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| leader_id | uuid | ja | – | PK, FK tk_plan_leaders on delete cascade |
| plan_id | uuid | ja | – | FK tk_plans (für RLS) |
| email | text | nein | null | `kontaktMail`; Pflicht für die erste Leitung zum Einreichen |
| mobile | text | nein | null | `kontaktTel` |
| emergency_name | text | nein | null | `notfallName`; Pflicht für die erste Leitung zum Einreichen |
| emergency_phone | text | nein | null | `notfallTel`; Pflicht für die erste Leitung zum Einreichen |

Telefonnummern: nur Ziffern, Leerzeichen, `+ / - ( )`, 5–30 Zeichen (R18). E-Mail: einfache Formprüfung `^[^@\s]+@[^@\s]+\.[^@\s]+$`.

### tk_plan_legs (Teilstrecken der An- und Abreise)

| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| plan_id | uuid | ja | – | FK on delete cascade |
| sort_order | int | ja | – | |
| mode | tk_transport | ja | 'rail_long' | `mode` |
| label | text | nein | null | `l` (Strecke), max. 200 |
| km_one_way | numeric(8,1) ≥ 0 | ja | 0 | `km` |
| persons | int ≥ 0 | ja | 0 | `p` |
| vehicles | int ≥ 0 | ja | 0 | `f`; nur bei `car`, `ecar`, `van` > 0 erlaubt (Check) |
| round_trip | boolean | ja | true | `rt` |

### tk_plan_costs (Kostenzeilen)

| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| plan_id | uuid | ja | – | FK on delete cascade |
| cost_group | tk_cost_group | ja | – | Tabelle im Prototyp 3.2 |
| sort_order | int | ja | – | |
| label | text | ja | – | `l`, 1–200 |
| quantity | numeric(10,2) ≥ 0 | ja | 0 | `m` |
| unit_price | numeric(10,2) ≥ 0 | ja | 0 | `p` |
| is_car | boolean | ja | false | Kennzeichen „PKW-Fahrt“ (ersetzt die Texterkennung „beginnt mit PKW“ aus Prototyp 9.4); vom Schnellknopf gesetzt, in der Zeile umschaltbar |
| is_overnight | boolean | ja | false | Kennzeichen „Übernachtung“ (ersetzt Texterkennung) |
| is_hut_half_board | boolean | ja | false | Kennzeichen „Hütte mit Halbpension“ (nur `self_paid`; ersetzt Texterkennung) |

### tk_plan_results (berechnete Werte, 1:1 zur Planung)

Vom System bei jedem Speichern über `tk_calculate` geschrieben (R1). Spalten: `plan_id` (PK, FK), `days`, `hours_day1`, `fee_total` (honorar), `org_total` (org), `leader_costs` (leit), `fixed_costs` (fix), `per_participant_costs` (varTN), `self_paid_per_participant` (selbst), `total_costs` (kosten), `fee_method` (Schlüssel der teuersten aktiven Zahlmethode), `price_raw` (roh), `price_suggested` (vorschlag), `price_member_effective` (pM), `price_non_member_suggested`, `price_non_member_effective` (pN), `net_per_participant` (netto(pM)), `contribution_per_participant` (dbTN), `break_even` (int), `result_min`, `result_max`, `fees_at_min`, `is_free` (frei), `section_bears` (Betrag, den die Sektion trägt: bei `is_free` = total_costs), `co2_mobility_kg`, `co2_stay_kg`, `co2_food_kg`, `co2_tour_kg`, `co2_all_kg`, `co2_per_person_kg`, `co2_per_person_day_kg`, `climate_budget_eur`, `co2_status` (`missing`, `mostly_pt`, `mixed`, `mostly_car_flight`), `fitness_suggested`, `rates_valid_on` (Datum, mit dem `ad_rates_at` aufgerufen wurde), `missing` (text[] Schlüssel fehlender Pflichtangaben, R6), `warnings` (text[] Schlüssel der Warnungen), `calculated_at`.

### tk_plan_rates (eingefrorener Satzstand)

`plan_id`, `rate_key`, `value numeric`, `percent numeric`, `fixed numeric`, `active boolean`, `valid_from date`; PK `(plan_id, rate_key)`. Wird bei `approved` aus `ad_rates_at(start_date)` kopiert (R3); danach rechnet `tk_calculate` mit diesen Werten statt mit `ad_rates_at`.

### tk_plan_history (Verlauf)

| Spalte | Typ | Beschreibung |
|---|---|---|
| id | uuid | PK |
| plan_id | uuid | FK on delete cascade |
| at | timestamptz | now() |
| by_user / by_person_id | uuid | auth.uid() / Person |
| event | text | `created`, `saved`, `submitted`, `query`, `approved`, `published`, `cancelled`, `done`, `closed`, `contacts_purged`, `ez_sync_failed`, `ez_locked` |
| from_status / to_status | tk_plan_status | bei Statuswechseln |
| comment | text | Pflicht bei `query` und `cancelled`; optional bei `approved` |
| changed_fields | text[] | bei `saved` ab Status `approved`: geänderte Felder aus Termin (start_date, end_date, meet_time, end_time), Leitung, Beitrag (price_member, price_non_member), Gesamtkosten (R19) |

### tk_qualification_sports (Zuordnung Qualifikationsart → Sportart, C3)

`qualification_type_id` (FK ad_qualification_types), `sport` (text, Check), PK beides. Startbestand per Migration aus Prototyp 4.8 über die Bezeichnungen der Qualifikationsarten [ANNAHME: Zuordnung der Prototyp-Bezeichnungen zu den 47 Qualifikationsarten legt die Migration fest; nicht zuordenbare werden im Migrationsprotokoll gemeldet]. Pflege im MVP nur per Migration [ANNAHME].

### tk_privacy_confirmations (Hinweis nach Art. 13 DSGVO bei neuen Personen, R23)

Wie `ez_privacy_confirmations` der Anwesenheitserfassung: `id` uuid PK, `person_id` uuid FK ea_persons on delete cascade, `plan_id` uuid FK tk_plans on delete set null, `notice_version` text 1–50, `confirmed_at` timestamptz default now(), `confirmed_by` uuid, `confirmed_by_person_id` uuid. Geschrieben nur von `tk_create_leader`.

### Funktionen (security definer, fester `search_path`, Grants nur an `authenticated`)

Rechte (zentrale Stelle):
- `tk_can_read(p_referat uuid)` – `ad_has_level('TK','read') or p_referat = any(ad_my_referate('TK','read'))`.
- `tk_can_write(p_referat uuid)` – `ad_has_level('TK','edit') or p_referat = any(ad_my_referate('TK','edit'))`.
- `tk_can_approve(p_referat uuid)` – Freigaberecht im Referat: `ad_can_approve('TK', p_referat)` (R50 AD; Abschnitt 3). Die Vorlage „Freigabe Touren und Kurse“ hat zugleich TK bearbeiten, deshalb ist keine Oder-Verknüpfung in `tk_can_read`/`tk_can_write` nötig.
- `tk_can_manage()` – `ad_has_level('TK','manage')`.
- `tk_can_read_contacts(p_referat uuid)` – `tk_can_write(p_referat)` (nicht: nur lesen; A3).

Lesen:
- `tk_list_plans(p_year int default null, p_referat uuid default null, p_type tk_plan_type default null, p_status tk_plan_status[] default null, p_limit int default 50, p_offset int default 0)` – Zeilen aus `tk_plans` mit `tk_can_read`; dazu Name der ersten Leitung (über `ea_person_names`), `price_member_effective`, `total_count`. Standard ohne p_status: alle außer `cancelled`, `closed`. Sortierung start_date asc nulls last.
- `tk_get_plan(p_id uuid) returns jsonb` – Planung mit Leitung (inkl. rate_kind, Lizenz), Kontakten (nur bei `tk_can_read_contacts`, sonst Schlüssel fehlt), Teilstrecken, Kosten, Ergebnissen, Satzstand (`ad_rates_at(start_date)` bzw. `tk_plan_rates`), Verlauf, Schaltflächen-Rechte (`can_write`, `can_approve`, `can_manage`). `TK_NOT_FOUND`, wenn nicht vorhanden oder nicht lesbar.
- `tk_cost_report(p_year int, p_referat uuid default null, p_type tk_plan_type default null, p_include_cancelled boolean default false)` – je lesbarer Planung: id, title, plan_type, referat, start_date, end_date, status, fee_total, org_total, leader_costs, fixed_costs, total_costs, price_member_effective, min/max_participants, result_min, result_max, section_bears; Summenzeile berechnet das Frontend. Keine Kontaktdaten (US-TK-20).
- `tk_settlement_draft(p_plan_id uuid) returns jsonb` – nur ab Status `published`, Rechte `tk_can_manage()` oder `ad_has_level('FI','read')`; Inhalt nach Übergabe Finanzen v1.3; `TK_PLAN_CANCELLED` bei abgesagter Planung (US-TK-24).

Rechnen:
- `tk_calculate(p_plan_id uuid)` – berechnet alle Werte von `tk_plan_results` nach Prototyp 4.1–4.8 mit den Änderungen aus Abschnitt 5 (R2, R4, R14) und schreibt Vorschläge in `tk_plans` für Felder, die nicht in `touched` stehen (Prototyp 4.2). Sätze aus `tk_plan_rates`, wenn vorhanden, sonst aus `ad_rates_at(coalesce(start_date, current_date))`. Satzart der Leitung über `ea_person_licenses(person_ids, start_date)` (R2, mit Erwerbsdatum). Kurs nach R22. Wird von `tk_save_plan` aufgerufen; nicht direkt für Nutzer freigegeben.
- Gleiche Formeln als TypeScript-Modul `src/modules/tk/calc.ts` für die Live-Anzeige; beide gegen dieselben Testfälle (T6, T20). Maßgeblich ist das Ergebnis der Datenbank (R1).

Schreiben:
- `tk_save_plan(p_plan jsonb, p_leaders jsonb, p_contacts jsonb, p_legs jsonb, p_costs jsonb, p_row_version int) returns jsonb` – anlegen (ohne `id`, mit `client_request_id`) oder ändern; in einer Transaktion:
  1. Rechte: Anlegen mit `tk_can_write(referat aus plan_type)`; Ändern mit Status-Regel R19; sonst `TK_FORBIDDEN`.
  2. Idempotenz über `client_request_id` (gibt vorhandene Planung zurück).
  3. `p_row_version` ≠ gespeicherte → `TK_CONFLICT` (R20); bei Erfolg `row_version + 1`.
  4. Wechsel von plan_type mit anderem Referat nur mit `tk_can_write` im neuen Referat (`TK_FORBIDDEN_REFERAT`).
  5. Feldprüfungen (Checks, R17, R18); Unterlisten `p_leaders`, `p_legs`, `p_costs` ersetzen die gespeicherten vollständig; `p_contacts` nur bei `tk_can_read_contacts`, sonst bleiben gespeicherte Kontakte unverändert.
  6. Neue Personen in der Leitung: Ehrenamtsstatus „aktiv“ (R13).
  7. `tk_calculate`.
  8. Ab Status `approved`: Verlaufseintrag mit `changed_fields` (R19). Ab Status `published` und vorhandenem Einsatz: `ez_upsert_planned_event` (R15); Fehler `EZ_EVENT_LOCKED` oder `EZ_SETTLED` (Einsatz abgerechnet, Übergabe FI → TK T7) → Planung bleibt gespeichert, Verlauf `ez_locked`, Rückgabe `warning = 'TK_EZ_LOCKED'`; anderer Fehler → Rückgabe `warning = 'TK_EZ_SYNC_FAILED'`, Verlauf `ez_sync_failed`.
  9. Rückgabe: id, row_version, Ergebnisse, Warnungen.
- `tk_change_status(p_id uuid, p_action text, p_comment text default null, p_yolawo_ref text default null, p_row_version int)` – Aktionen nach Abschnitt 4 (`submit`, `query`, `resubmit`, `approve`, `publish`, `cancel`, `done`, `close`); prüft Rechte, Ausgangsstatus (`TK_STATUS_NOT_ALLOWED`), Pflichtangaben (`missing` leer bei `submit`, `resubmit`, `approve`, `publish` → sonst `TK_MISSING_FIELDS` mit Liste), Kommentar (`TK_COMMENT_REQUIRED`); schreibt Verlauf. Bei `approve`: `tk_plan_rates` aus `ad_rates_at(start_date)` kopieren, `rates_frozen_on = current_date`. Bei `publish`: `ez_upsert_planned_event` in derselben Transaktion; Fehler → Abbruch mit `TK_EZ_FAILED` (US-TK-16 AK4). Bei `cancel`: `cancelled_at`, `cancel_reason`; vorhandener Einsatz → `ez_cancel_planned_event` in derselben Transaktion; `EZ_EVENT_LOCKED` oder `EZ_SETTLED` (Personen schon anwesend bzw. Einsatz abgerechnet) → Abbruch mit `TK_EZ_LOCKED`, sonstiger Fehler → `TK_EZ_FAILED`.
- `tk_copy_plan(p_id uuid, p_client_request_id uuid) returns uuid` – US-TK-23 AK1; nur aktive Personen der Leitung werden übernommen, Rückgabe der entfernten Namen als Hinweis.
- `tk_delete_plan(p_id uuid)` – nur `tk_can_manage()` und Status `draft` oder `cancelled` ohne Einsatz [ANNAHME]; sonst `TK_DELETE_FORBIDDEN`.
- `tk_create_leader(p_plan_id uuid, p_first text, p_last text, p_preferred text default null, p_email text default null, p_privacy_confirmed boolean default false, p_notice_version text default null) returns uuid` – R23: neue Person aus der Planung anlegen; nur `tk_can_write(referat)` der Planung und Status bearbeitbar (R19); ohne `p_privacy_confirmed = true` und `p_notice_version` → `TK_PRIVACY_NOT_CONFIRMED`, nichts wird angelegt; ruft `ea_create_volunteer` mit der Eigenschaftsart `system_key = 'function'`, Wert Helfer:in, Referat der Planung, `p_valid_from = current_date` [ANNAHME], `p_contact_email`; `created_in = 'TK'` (bzw. `'EA'` bei passenden EA-Rechten, wie AD v0.8.2 für EZ); schreibt `tk_privacy_confirmations`; gibt die person_id zurück. Die Person wird nicht automatisch in die Leitung eingetragen; das Frontend ergänzt sie und speichert über `tk_save_plan`. Dublettenprüfung vorher über `ad_find_similar_persons`.
- `tk_reactivate_leader(p_plan_id uuid, p_person uuid) returns void` – R23: Person mit Ehrenamtsstatus „ruhend“, „ausgeschieden“ oder ohne Ehrenamtsstatus wieder aktivieren; Rechte wie `tk_create_leader`; ruft `ea_activate_person` mit Funktion Helfer:in, Referat der Planung, `p_valid_from = current_date`; sonst `TK_PERSON_NOT_INACTIVE` („Diese Person ist bereits aktiv.“). Kein Häkchen nach Art. 13 DSGVO (Person war schon erfasst).
- `tk_purge_contacts()` – nur für den Scheduler (Grant an `postgres`/Service-Rolle, nicht an `authenticated`); R16; täglich 03:15 Uhr per `pg_cron`.

Trigger: `tk_plans_before_insert` (referat_id aus plan_type, Audit), `tk_plans_before_update` (Audit; Statusänderung nur innerhalb von `tk_change_status`, sonst `TK_STATUS_DIRECT`), Audit-Trigger der Untertabellen.

## 3. Rechte / RLS

**Freigaberecht:** Freigeben ist eine eigene Aktion im Rechtemodell der Administration: Kennzeichen „darf freigeben“ am Recht TK (`ad_template_rights.can_approve`, R50 AD v0.10; Q1, Product Owner 24./26.10.2026). Das frühere Modul TKF entfällt. Die Rechtevorlage „Freigabe Touren und Kurse“ enthält TK bearbeiten + darf freigeben mit Reichweite „Referat“; der Admin vergibt sie zusätzlich zu Referent:in bzw. an andere Personen (Product Owner 22.10.2026). Startwert: alle Referent:innen der Referate Touren und Ausbildung erhalten sie (A2). Prüfung über `ad_can_approve('TK', referat)`.

| Rechtevorlage (Startwert) | Lesen | Anlegen / Bearbeiten | Einreichen, Rückfrage | Freigeben | In Yolawo angelegt, Absagen, Durchgeführt | Abgeschlossen | Löschen | Kontaktdaten |
|---|---|---|---|---|---|---|---|---|
| Admin (TK lesen, alle) | alle | – | – | – | – | – | – | nein |
| Geschäftsstelle (TK verwalten, alle) | alle | ja | ja | – (A2) | ja | ja | ja (draft, cancelled) | ja |
| Referent:in (TK bearbeiten, Referat) | eigenes Referat | eigenes Referat, Status nach R19 | ja | nur mit Freigaberecht | Absagen, Durchgeführt; „in Yolawo angelegt“ nur mit Freigaberecht | – | – | ja, eigenes Referat |
| Freigabe Touren und Kurse (TK bearbeiten + darf freigeben, Referat) | eigenes Referat | eigenes Referat, alle Status bis `published` | ja | ja | ja | – | – | ja, eigenes Referat |
| Vorstand (Startwert ohne Rechte) | – | – | – | – | – | – | – | – |

| Tabelle | Lesen (RLS) | Schreiben |
|---|---|---|
| tk_plans, tk_plan_leaders, tk_plan_legs, tk_plan_costs, tk_plan_results, tk_plan_rates, tk_plan_history | `tk_can_read(referat_id)` der Planung | nur Funktionen |
| tk_plan_contacts | `tk_can_read_contacts(referat_id)` | nur `tk_save_plan`, `tk_purge_contacts` |
| tk_qualification_sports | alle mit `ad_has_any_level('TK','read')` | nur Migration |
| tk_privacy_confirmations | `tk_can_manage()` | nur `tk_create_leader` |

Namen von Personen nur über `ea_person_names` (Bedingung `tk_person_visible`: Person steht in einer lesbaren Planung als Leitung; TK ersetzt den Platzhalter aus AD v0.9 mit gleicher Signatur) und `ea_search_active_persons`; Lizenzen nur über `ea_person_licenses` (Übergabe an die Administration). Kein direkter Zugriff auf `ea_persons` oder `ea_properties`.

Routenschutz: `/tk/*` ohne `ad_has_any_level('TK','read')` → /kein-zugriff („Kein Zugriff auf die Planungshilfe Touren und Kurse.“). Kachel über `ad_my_modules`.

## 4. Zustände und Übergänge

| Von | Nach | Aktion | Wer | Bedingung |
|---|---|---|---|---|
| – | draft | Anlegen, Kopieren | `tk_can_write` | – |
| draft | submitted | submit | `tk_can_write` | `missing` leer; c1–c4 nach Tourtyp (Prototyp 6.1) |
| submitted | query | query | `tk_can_write` | Kommentar Pflicht |
| query | submitted | resubmit | `tk_can_write` | `missing` leer |
| submitted | approved | approve | `tk_can_approve` | `missing` leer; Satzstand wird eingefroren (R3) |
| approved | published | publish | `tk_can_approve` oder `tk_can_manage` (A11, Product Owner 26.10.2026) | Einsatz wird erzeugt (R15); optional yolawo_ref |
| published | done | done | `tk_can_write` | end_date < current_date (`TK_NOT_FINISHED`) |
| done | closed | close | `tk_can_manage` | – |
| draft, submitted, query, approved, published | cancelled | cancel | `tk_can_write` | Grund Pflicht; Einsatz → „abgesagt“ |

Bearbeiten nach Status (R19): `draft`, `submitted`, `query` – `tk_can_write`; `approved`, `published` – `tk_can_approve` oder `tk_can_manage`; `done`, `closed`, `cancelled` – niemand (nur lesen).

## 5. Geschäftsregeln

R1–R11 aus 01-erhebung.md (hier präzisiert), R12–R21 neu. Meldungen in der Oberfläche wie angegeben; Fehlercodes für die gemeinsame Liste `docs/specs/ad-administration/contracts/error-codes.md`.

- **R1 Berechnung:** Formeln Prototyp 4.1–4.8 unverändert, außer R2, R4, R14. Leere Zahlen = 0; Tage mit 12:00 Uhr gerechnet; Rundung des Beitrags `ceil(roh / rRund − 1e−9) × rRund`; Nichtmitglieder aus dem effektiven Mitgliederbeitrag, erneut aufgerundet. Abnahmewerte Abschnitt 9.
- **R2 Satzart:** `trainer`, wenn Rolle ≠ `helper` und `ea_person_licenses(person, start_date)` eine förderfähige Lizenz liefert, die (a) am Startdatum gültig ist (`valid_from <= start_date` oder ohne Erwerbsdatum, und `valid_until >= start_date` oder ohne Ablauf) **oder** (b) im Kalenderhalbjahr des Startdatums erworben wurde (`valid_from` im selben Halbjahr, auch nach dem Startdatum) – gleiche Regel wie Finanzen R8 (Product Owner 26.10.2026, Übergabe FI → TK T2). Fall (b) mit Hinweis `license_acquired_in_half` („Lizenz erworben am {Datum} – Trainersatz für das ganze Halbjahr.“). Läuft die Lizenz vor `end_date` ab, bleibt `trainer` für die ganze Tour (Product Owner 22.10.2026) mit Warnung `license_expires_during` („Lizenz läuft während der Tour ab ({Datum}) – Verlängerung für künftige Touren nötig.“). Sonst `helper` mit Warnung `helper_rate` („Ohne gültige Lizenz wird der Helfersatz gerechnet.“). Ohne start_date: Satzart `helper`, Warnung „Für die Satzart fehlt der Beginn.“ `nTL = 1` ohne erfasste Person aus Prototyp 4.3 entfällt: ohne Leitung ist die Vergütung 0.
- **R3 Satzstand:** bis `approved` gilt `ad_rates_at(start_date)` (Wert mit spätestem `valid_from <= start_date` je Schlüssel); ab `approved` die Kopie in `tk_plan_rates`. Fehlt ein Schlüssel: Warnung und `missing` „Satz {Bezeichnung}“ („Für {Bezeichnung} ist zum {Datum} kein Satz hinterlegt. Bitte den Admin informieren.“).
- **R4 Gemeinschaftstour:** keine Tagessätze, Halbtagessätze, Lehreinheiten, keine Kosten der Leitung, sonstigen Kosten und Leistungen je Teilnehmer:in (Tabellen ausgeblendet, Werte 0); **Organisationspauschale = org_days × rOrg** (Vergütungsordnung Ziff. 9.2; Prototyp 4.3/4.9 an dieser Stelle fehlerhaft); kein Teilnahmebeitrag (`is_free = true`), `section_bears = org_total` (Product Owner 22.10.2026). Bestätigungen c1–c3 ausgeblendet, `community_reason` Pflicht. Text in der Ausschreibung: „Gemeinschaftstour ohne Teilnahmebeitrag. Alle Kosten tragen die Teilnehmenden selbst.“ (unverändert, weil die Organisationspauschale nicht die Teilnehmenden betrifft).
- **R5 Mitgliedschaft:** Standard nur DAV-Mitglieder; `non_members_allowed` nur mit `non_members_reason` (außer Gemeinschaftstour); bei nur Mitgliedern wird in der ersten Anmeldefrage „ / kein Mitglied“ entfernt und die Voraussetzung „Mitgliedschaft im DAV“ ergänzt (Prototyp 7.2).
- **R6 Pflichtangaben und Warnungen:** Liste Prototyp 6.1 (Schlüssel = Feldname) ohne PDF-bezogene Punkte; zusätzlich `leader_person` („Leitung ohne zugeordnete Person“ – entfällt technisch, weil nur Personen wählbar sind; bleibt als Prüfung „mindestens eine Leitung“), `rates_missing` (R3). Warnungen Prototyp 6.2/6.3 mit den Grenzwerten aus `ad_rates` (`car_permit_km` 500, `flight_min_km` 1000, `hut_hp_min` 45, `hut_hp_max` 90, `rUe` 70, Richtwert `rKmTag1`/`rKmTagN`) statt fester Werte. Erkennung PKW, Übernachtung, Hütte mit Halbpension über die Kennzeichen der Kostenzeilen (`is_car`, `is_overnight`, `is_hut_half_board`), nicht über Text.
- **R7 Einsatz:** genau ein Einsatz je Planung, erzeugt bei `publish` (R15).
- **R8 Notfallkontakte:** nie in Liste, Auswertung, Export, Yolawo-Texten; Löschung R16.
- **R9 Titel:** 1–90 Zeichen; wird ungekürzt an den Einsatz übergeben (Anwesenheitserfassung erlaubt 1–90 Zeichen, Product Owner 24.10.2026; A4 entfällt).
- **R10 Strukturierte Speicherung:** alle Angaben in Spalten bzw. Untertabellen; kein JSON-Feld für fachliche Angaben (Ausnahme: Rückgabewerte von Funktionen).
- **R11 Keine Stornoregel:** keine Spalte, keine Zeile „Anmeldezeitraum & Rückerstattung → Stornoregeln“ im Eingabeblatt, keine Zeile „Stornierung …“ im Ausschreibungstext, kein Abschnitt in Zusammenfassung und PDF. Die Stornobedingungen der Unterkunft (intern) bleiben.
- **R12 Referat aus Tourtyp:** `course` → Referat „Ausbildung“, `guided_tour` und `community_tour` → Referat „Touren“ (Auflösung über den Namen in `ea_referate` per Migration als Konstante [ANNAHME: feste IDs]). Ohne Schreibrecht im Ziel-Referat: „Für Kurse ist das Referat Ausbildung zuständig. Dir fehlt das Recht für dieses Referat.“ bzw. sinngemäß für Touren (`TK_FORBIDDEN_REFERAT`).
- **R13 Leitung:** nur Personen mit Ehrenamtsstatus „aktiv“ beim Hinzufügen; sonst „Bitte eine aktive Person auswählen.“ (`TK_PERSON_NOT_ACTIVE`). Bereits gespeicherte Personen bleiben erlaubt. Mindestens eine Person mit Rolle `lead` zum Einreichen.
- **R14 Abweichungen vom Prototyp:** R2 (Lizenz aus dem Ehrenamtsmanagement, Stichtag Startdatum oder Erwerb im Halbjahr), R4 (Organisationspauschale Gemeinschaftstour), R22 (mehrtägige Kurse nach Lehreinheiten statt Tagessätzen), R6 (Kennzeichen statt Texterkennung, Grenzwerte aus Stammdaten), R11 (keine Stornoregel), keine eingebetteten PDF-Daten, kein localStorage-Entwurf mit Personendaten.
- **R15 Einsatz-Inhalt:** `kind` = `course` bei Kurs, sonst `tour`; `referat_id`; `title` nach R9; `span` = `single` bei start_date = end_date, sonst `multi`; eintägig: `day_category` = `at_least_8h` wenn days_full ≥ 1, sonst `under_8h`; mehrtägig: `start_time` = meet_time, `end_time` = end_time (beide optional, Anwesenheitserfassung Product Owner 24.10.2026); `organizer_person_id` = erste Person mit Rolle `lead`; Personen: alle Leitenden mit EZ-Rolle `trainer` bei rate_kind `trainer`, sonst `helper`, Stand `registered`; **Abrechnungsart** (Product Owner 26.10.2026): Gemeinschaftstour → `COMMUNITY_TOUR`, sonst keine Angabe (Vorbelegung der Anwesenheitserfassung: Kurs → „Kurse“, Führungstour → „Mehrtageskurse, Führungstouren, Trainingslager“). Ein Wechsel des Tourtyps zwischen Führungs- und Gemeinschaftstour nach dem Publizieren ändert die Abrechnungsart des Einsatzes mit, solange er nicht gesperrt ist.
- **R16 Löschung Kontaktdaten:** täglich; Planungen mit (Status in `published`, `done`, `closed` und end_date + 30 Tage < heute) oder (Status `cancelled` und cancelled_at + 30 Tage < heute) (Product Owner 26.10.2026): alle Zeilen in `tk_plan_contacts` löschen, `contacts_purged_at` setzen, Verlauf `contacts_purged` (A6). Danach entfallen die Pflichtprüfungen zu Kontaktdaten. Keine Wiederherstellung.
- **R17 Doppelte Person:** eine Person höchstens einmal je Planung: „Diese Person ist schon eingetragen.“ (`TK_DUPLICATE_PERSON`).
- **R18 Telefon, E-Mail:** „Bitte eine Telefonnummer eingeben.“ (`TK_PHONE_INVALID`), „Bitte eine gültige E-Mail-Adresse eingeben.“ (`TK_EMAIL_INVALID`).
- **R19 Bearbeiten nach Status:** siehe Abschnitt 4; sonst „Nach der Freigabe ändern nur Personen mit Freigaberecht oder die Geschäftsstelle.“ bzw. „Diese Planung ist abgeschlossen und kann nicht mehr geändert werden.“ (`TK_LOCKED`). Ab `approved` werden Änderungen an Termin, Leitung, Beitrag und Gesamtkosten im Verlauf mit Feldnamen protokolliert (ohne Werte von Kontaktdaten).
- **R20 Gleichzeitiges Bearbeiten:** „Die Planung wurde inzwischen von {Name} geändert. Bitte neu laden; deine Eingaben bleiben bis dahin sichtbar.“ (`TK_CONFLICT`).
- **R22 Kurs nach Lehreinheiten (Product Owner 26.10.2026):** Kurse werden ein- und mehrtägig nur nach Lehreinheiten vergütet: `fee_total = nTrainer × teaching_hours × rLE`; Helfende erhalten 0; keine Tagessätze, Halbtagessätze und keine Organisationspauschale (Abrechnungsart „Kurse“ der Administration). Vorschlag für `teaching_hours` nur bei eintägigem Kurs (Prototyp 4.2); bei mehrtägigem Kurs kein Vorschlag, Pflichtangabe zum Einreichen (`missing` `teaching_hours`, „Lehreinheiten“). Ersetzt für mehrtägige Kurse die Tagessätze aus Prototyp 4.3.
- **R23 Externe Leitende (Product Owner 26.10.2026):** Wer die Planung bearbeiten darf (`tk_can_write` im Referat der Planung), kann eine Person, die noch nicht in den Aktiven ist, direkt aus der Planung anlegen: Dialog wie beim Arbeitseinsatz (Vorname, Nachname, Rufname optional, E-Mail optional, Pflicht-Häkchen „Ich habe die Person über die Speicherung ihrer Daten informiert und auf die Datenschutzhinweise der Sektion hingewiesen.“ mit Link; Text, Link und `notice_version` wie in der Anwesenheitserfassung), vorher Dublettenprüfung (`ad_find_similar_persons`). Die Person erhält Ehrenamtsstatus „aktiv“ und die Funktion Helfer:in im Referat der Planung; den Trainersatz bekommt sie erst, wenn die Geschäftsstelle die Lizenz im Ehrenamtsmanagement einträgt (R2). Treffer mit Ehrenamtsstatus „ruhend“, „ausgeschieden“ oder ohne Ehrenamtsstatus können nach Rückfrage wieder aktiviert werden. Ohne Häkchen: „Bitte bestätige, dass du die Person informiert hast.“ (`TK_PRIVACY_NOT_CONFIRMED`).
- **R21 Absage:** Grund 1–500 Zeichen, „Bitte einen Grund angeben.“ (`TK_COMMENT_REQUIRED`); Rückfrage ebenso „Bitte die Rückfrage beschreiben.“.
- Weitere Meldungen: „Noch {n} Angaben offen.“ (`TK_MISSING_FIELDS`, Detail Liste); „Freigabe nicht möglich: Angaben fehlen.“; „Einsatz konnte nicht angelegt werden. Bitte später erneut versuchen.“ (`TK_EZ_FAILED`); „Der Einsatz ist schon erfasst oder abgerechnet und wurde nicht geändert. Bitte in der Anwesenheitserfassung anpassen.“ (`TK_EZ_LOCKED`; bei Absage: „Absage nicht möglich: Im Einsatz sind schon Personen als anwesend erfasst oder er ist abgerechnet.“); „Die Tour ist noch nicht vorbei.“ (`TK_NOT_FINISHED`); „Speichern fehlgeschlagen. Deine Eingaben sind noch da – bitte erneut speichern.“ (Netzfehler); „Kein Zugriff auf die Planungshilfe Touren und Kurse.“; „Planung nicht gefunden.“ (`TK_NOT_FOUND`); „Keine Berechtigung.“ (`TK_FORBIDDEN`).

Fehlercodes neu: `TK_FORBIDDEN`, `TK_FORBIDDEN_REFERAT`, `TK_NOT_FOUND`, `TK_CONFLICT`, `TK_LOCKED`, `TK_STATUS_NOT_ALLOWED`, `TK_STATUS_DIRECT`, `TK_MISSING_FIELDS`, `TK_COMMENT_REQUIRED`, `TK_PERSON_NOT_ACTIVE`, `TK_DUPLICATE_PERSON`, `TK_PHONE_INVALID`, `TK_EMAIL_INVALID`, `TK_NOT_FINISHED`, `TK_EZ_FAILED`, `TK_EZ_LOCKED`, `TK_EZ_SYNC_FAILED`, `TK_DELETE_FORBIDDEN`, `TK_PLAN_CANCELLED`, `TK_PRIVACY_NOT_CONFIRMED`, `TK_PERSON_NOT_INACTIVE`.

## 6. Screens und Interaktionen

Allgemein wie Administration: deutsch, „du“, Datum TT.MM.JJJJ, Beträge „1.234,56 €“, shadcn/ui, ab 375 px ohne horizontales Scrollen; Bearbeiten der Kalkulation für Desktop optimiert, mobil lesbar und Status änderbar. Namen „Rufname Nachname“. Feldbezeichnungen, Hilfetexte und Auswahltexte aus dem Prototyp (Abschnitt 3, 6.3) übernehmen, ohne Stornoregel. Speichern explizit („Speichern“) und automatisch 2 s nach der letzten Änderung, solange die Planung bearbeitbar ist [ANNAHME]; kein Entwurf im Browser-Speicher.

| Route | Zeigt | Aktionen | Leer / Fehler | Story |
|---|---|---|---|---|
| /tk | Liste: Titel, Tourtyp, Referat, Termin („12.–16.07.2027“), erste Leitung, Status (Badge), Beitrag Mitglieder; Filter Status (Standard ohne abgesagt/abgeschlossen), Tourtyp, Jahr; 50 je Seite; mobil als Karten | Neue Planung (mit Schreibrecht); öffnen; Kopieren (Menü) | „Noch keine Planungen.“ | US-TK-01, -23 |
| /tk/neu | Auswahl Tourtyp (drei Karten wie Prototyp Schritt 1), Titel → legt Entwurf an und öffnet /tk/:id | Anlegen | R12-Meldung | US-TK-02 |
| /tk/:id | Kopf: Titel, Status, Referat, Termin, Verlauf (aufklappbar). Reiter **Schritte 1–7** wie Prototyp (Leitung, Ausschreibung, Termin & Anreise, Anforderungen, Teilnahme, Kalkulation, Einreichen). Seitenleiste (mobil unten): Beitrag mit Status-Pill, CO2-Bilanz mit Status-Pill, Fortschritt je Schritt, Hinweise. Reiter **Ausgaben**: Yolawo-Eingabeblatt, Ausschreibungstext, Zusammenfassung, PDF | Speichern; Statusaktionen je Recht (Einreichen, Rückfrage, Freigeben, In Yolawo angelegt, Absagen, Durchgeführt, Abgeschlossen) mit Dialog für Kommentar/Grund/Yolawo-Link; „n offen“ springt zum ersten offenen Feld | „Planung nicht gefunden.“; R20-Dialog | US-TK-03 bis -18, -21 |
| /tk/auswertung | Kostenauswertung: Filter Jahr (Standard laufendes), Referat (nur lesbare), Tourtyp, „abgesagte anzeigen“; Tabelle nach US-TK-20 AK1 mit Summenzeile | CSV-Export (nur `tk_can_manage`; Trennzeichen Semikolon, UTF-8 mit BOM) | „Keine Planungen für diese Auswahl.“ | US-TK-20 |

Schritt 1 „Leitung“: Liste der Personen mit Rolle (Auswahl), Satzart-Badge („Trainersatz“ / „Helfersatz“), Lizenz („Trainer*in C Bergwandern, gültig bis 30.10.2027“) und Hinweisen (R2); „Person hinzufügen“ öffnet die Komponente „Personensuche Aktive“ der Administration, darin „Neue Person anlegen“ (R23, Dialog und Dublettendialog wie beim Arbeitseinsatz, Treffer ruhend/ausgeschieden mit „Wieder aktivieren“); Sortieren per Ziehen bzw. Pfeilen. Darunter je Person mit Rolle Leitung/Co-Leitung die Kontaktfelder (nur mit `tk_can_read_contacts`), Datenschutzhinweis (US-TK-04 AK2). Nach Löschung: „Kontaktdaten gelöscht am …“.

Schritt 3: Tabelle Teilstrecken (Verkehrsmittel, Strecke, km einfach, Personen, Fahrzeuge – nur bei PKW/E-PKW/Kleinbus aktiv –, hin und zurück, kg CO2e berechnet); „+ Teilstrecke“ übernimmt Personen aus co2_persons.

Schritt 6: Vergütung (Führungstour: Tagessätze, Halbtagessätze, Organisationstage; Kurs: Lehreinheiten, R22; Gemeinschaftstour: Organisationstage) mit Vorschlägen (Kennzeichen „geändert“ bei touched, Knopf „Vorschlag übernehmen“ entfernt den Eintrag aus touched); vier Kostentabellen mit Schnellknöpfen (Prototyp 3.2; Werte aus den Sätzen; setzen die Kennzeichen `is_car`, `is_overnight`, `is_hut_half_board`); Beitrag (Vorschlag, eigener Wert, Nichtmitglieder), Zeile „Gerechnet mit Sätzen gültig ab …“ mit aufklappbarer Satzliste (nur lesen).

Ausgaben: Eingabeblatt mit Knopf „Kopieren“ je Feld (Prototyp 7.1 ohne Stornoregeln); Ausschreibungstext mit „Alles kopieren“ (Prototyp 7.2 ohne Stornozeile); Zusammenfassung (Prototyp 7.3 ohne Storno, Kontaktdaten nur mit `tk_can_read_contacts`); PDF (Prototyp 7.5 Aufbau und Dateiname, jsPDF als npm-Paket im Bundle, keine eingebetteten Daten, Kontaktdaten nur mit `tk_can_read_contacts`).

Navigation TK: Planungen · Auswertung.

## 7. Schnittstellen

| Schnittstelle | Richtung | Inhalt |
|---|---|---|
| Administration | AD → TK | `ad_has_level`, `ad_my_referate`, `ad_has_any_level`, `ad_can_approve`, `ad_my_modules`, `ad_modules` (TK), `ea_referate`, `ea_person_names`, `ea_search_active_persons`, `ea_person_licenses(person_ids, date)` (mit Erwerbsdatum), `ad_qualification_types`, `ad_rates_at(date)`, `ad_remuneration_kinds` (Code `COMMUNITY_TOUR`), `ea_create_volunteer`, `ea_activate_person`, `ad_find_similar_persons` (R23, mit TK-Rechten); Komponenten „Personensuche Aktive“ und Dublettendialog |
| Administration | TK → AD | Fehlercodes in contracts/error-codes.md; Übergabe v1.8 (Rechtevorlage „Freigabe Touren und Kurse“ mit „darf freigeben“, Schlüssel der Sätze unten, Erwerbsdatum in `ea_person_licenses`, Anlegen und Reaktivieren aus der Planung mit `created_in = 'TK'`) |
| Anwesenheitserfassung | TK → EZ | `ez_upsert_planned_event` (mit Abrechnungsart, Übergabe v1.3), `ez_cancel_planned_event`, `ez_planned_event_state`; Inhalt R15 |
| Finanzen | TK → FI | `tk_settlement_draft` (US-TK-24); Finanzen nutzt die Vorbelegung ab Iteration 1 (Kurs und Tour); Planwerte sind Vorschlag, maßgeblich sind Anwesenheit und Belege (Übergabe FI → TK T1, T4) |
| Yolawo | TK → Yolawo | manuell kopieren |

Schlüssel der Sätze in `ad_rates` (Startbestand Prototyp 5.1–5.4, Werte dort; die Vergütungsschlüssel `rTL`, `rTLh`, `rH`, `rHh`, `rOrg`, `rLE` sind schon angelegt (AD T123), die übrigen kommen mit AD T61 Rest; `flight_min_km` = 1.000 km (Product Owner 26.10.2026); alle Prototyp-Werte sind Startbestand, Bestätigung durch das Referat Touren über pruefliste-referat-touren.md bis zur Abnahme): Vergütung `rTL`, `rTLh`, `rH`, `rHh`, `rOrg`, `rLE`; Reisekosten `rKm`, `rUe`, `rSH`, `rKSH`; Beitrag `rNM`, `rRund`, `rVat`; Zahlungsgebühren `fee_sepa`, `fee_card`, `fee_paypal`, `fee_klarna`, `fee_transfer` (je %, fix, aktiv); Klima `rCO2`, `rKmTag1`, `rKmTagN`, Emissionsfaktoren `ef_rail_long`, `ef_rail_regional`, `ef_coach`, `ef_local_bus`, `ef_tram`, `ef_car`, `ef_ecar`, `ef_van`, `ef_flight`, `ef_bike`, `ef_stay_hut`, `ef_stay_self_catering`, `ef_stay_hotel`, `ef_stay_camping`, `ef_food_overnight`, `ef_food_day`; Grenzwerte `car_permit_km`, `flight_min_km`, `hut_hp_min`, `hut_hp_max`, `planning_lead_months` (6). Hüttenrichtwerte (Prototyp 5.4) bleiben Hilfetext.

## 8. Nicht-funktionale Anforderungen

- RLS auf jeder `tk_`-Tabelle; Schreiben nur über Funktionen; pgTAP für jede Rechtevorlage inkl. Freigaberecht.
- Rechengenauigkeit: Ergebnisse der Datenbank und des TypeScript-Moduls auf den Cent bzw. 0,01 kg gleich (T20).
- Mengengerüst [ANNAHME]: ca. 60 Planungen je Jahr, je Planung bis 10 Leitende, 10 Teilstrecken, 40 Kostenzeilen; `tk_save_plan` < 1 s; Liste und Auswertung eines Jahres < 1 s.
- Keine externen Abrufe im Frontend (jsPDF gebündelt); Kosten 0 €.
- Datenschutz: Verarbeitungsverzeichnis „Planungshilfe Touren und Kurse“ (Zweck: Planung, Freigabe, Notfall während der Tour, Abrechnungsvorbereitung; Kategorien: Namen und Lizenzen der Leitenden, Kontaktdaten, Notfallkontakte als Daten Dritter mit Löschung nach 30 Tagen; Bestätigung des Hinweises nach Art. 13 DSGVO bei neu angelegten Personen). Keine Daten von Teilnehmenden. Aufbewahrung der Planungen 5 Jahre nach Tourende; kein Löschlauf im MVP.

## 9. Testdaten (supabase/seed.sql, nur TEST, nach den Seeds der Administration)

Voraussetzung Seed Administration: Testzugänge Tina Touren (Referent:in Touren + Freigabe Touren), Alex Ausbildung (Referent:in Ausbildung, ohne Freigaberecht), Fritz Freigabe (nur Freigabe Touren und Kurse, Referat Touren), Anna Fiktiv (Geschäftsstelle), Test Admin, Bernd Beispiel; Aktive Bernd Berg (Trainer*in C Bergwandern, förderfähig, gültig bis 30.10.2027), Hilde Helfer (keine Lizenz), Karl Kletter (Trainer*in C Sportklettern, gültig bis 31.12.2025); `ad_rates` Startbestand gültig ab 01.01.2026. Alle Namen fiktiv.

| # | Planung | Daten | Zweck / erwartete Werte |
|---|---|---|---|
| 1 | Führungstour „Hüttentour Stubaier Alpen (Test)“, Status `submitted` | Beispiel Prototyp 3.5: 12.–16.07.2027, Leitung Bernd Berg, Kosten der Leitung 2 × 105 + 5 × 45 + 5 × 0, Teilstrecken Bahn 650 km und Linienbus 30 km je 9 Personen, Hütte, min 5/max 8 | fee 250, org 50, Kosten 735, Vorschlag 160 (PayPal), Nichtmitglieder 210 bei Ausnahme, break_even 5, result_min 18,71, result_max 470,93; CO2 mob 352,8, stay 335,52, food 211,5, tour 564,3, je Person ≈ 100, Budget 79,00 |
| 2 | Kurs „Vorstieg am Fels (Test)“, Referat Ausbildung, `draft` | 15.10.2027, 09:00–17:00, Leitung Bernd Berg, min 4/max 6 | eintägiger Kurs: 8 Lehreinheiten × 15 € = 120 €, Org 0; Warnung Sportart (Klettern nicht durch Bergwandern abgedeckt); für Tina nicht sichtbar |
| 9 | Kurs „Grundkurs Hochtouren (Test)“, Referat Ausbildung, `draft` | 01.–03.07.2027, Leitung Bernd Berg und Hilde Helfer (Helfer:in), ohne Lehreinheiten | kein Vorschlag, `missing` enthält `teaching_hours`; nach Eingabe 20 Lehreinheiten: 20 × 15 € = 300 € (nur Bernd), Org 0, keine Tagessätze (R22) |
| 3 | Führungstour „Herbstwanderung (Test)“, `approved` | 29.10.–01.11.2027, Leitung Bernd Berg | Satzart Trainer trotz Ablauf 30.10. (R2), Warnung `license_expires_during`; Satzstand eingefroren |
| 4 | Führungstour „Novembertour (Test)“, `draft` | 02.11.2027, Leitung Bernd Berg | Satzart Helfer (R2) |
| 5 | Gemeinschaftstour „Sächsische Schweiz (Test)“, `published` | 10.–12.09.2027, Leitung Hilde Helfer, org_days 3 | Org 30 € (R4), Beitrag 0, section_bears 30; Einsatz vorhanden mit Abrechnungsart „Gemeinschaftstour“ (R15) |
| 6 | Führungstour „Absage (Test)“, `cancelled` | 05.06.2027, Grund „Mindestteilnehmerzahl nicht erreicht“, cancelled_at vor 20 Tagen, Kontaktdaten vorhanden | R16 löscht Kontaktdaten beim nächsten Lauf; in Auswertung nur mit „abgesagte anzeigen“ |
| 7 | Führungstour „Familienwanderung (Test)“, `draft`, Zielgruppe Familienwanderungen, Tagestour, ohne Beitrag | 18.04.2027 | is_free, section_bears = Gesamtkosten |
| 8 | Führungstour „Alte Tour (Test)“, `closed` | 12.07.2026 | nur lesen; Kontaktdaten gelöscht |

Erwartete Sichtbarkeit (pgTAP T18):

| Testzugang | sieht Planungen | bearbeitet | gibt frei | Kontaktdaten |
|---|---|---|---|---|
| Admin (TK lesen) | 1–9 | nein | nein | nein |
| Geschäftsstelle (TK verwalten) | 1–9 | 1, 2, 4, 7, 9 (+ 3, 5 nach R19) | nein | ja |
| Tina (Referent:in Touren + Freigabe) | 1, 3–8 | 1, 4, 7, 3, 5 | 1 | ja (Touren) |
| Alex (Referent:in Ausbildung) | 2, 9 | 2, 9 | nein | ja (Ausbildung) |
| Fritz (nur Vorlage „Freigabe Touren und Kurse“, Referat Touren) | 1, 3–8 | 1, 4, 7, 3, 5 | 1 | ja (Touren) |
| Vorstand | keine | nein | nein | nein |

## 10. Umsetzungs-Tasks

Voraussetzung: Administration Nachtrag v0.9 Rest umgesetzt (T59, T61 Rest, T62–T67; siehe Voraussetzungen oben). T13/T14 zusammen mit EZ T036–T038 (Übergabe an EZ v1.3).

- [ ] T1: Migration Typen, Tabellen `tk_plans`, `tk_plan_leaders`, `tk_plan_contacts`, `tk_plan_legs`, `tk_plan_costs`, `tk_plan_results`, `tk_plan_rates`, `tk_plan_history`, `tk_qualification_sports`, Checks, Indizes, RLS an, Select-Policies, keine Schreib-Grants (US-TK-01, -02, R10)
- [ ] T2: Migration Rechtefunktionen `tk_can_read`, `tk_can_write`, `tk_can_approve` (über `ad_can_approve('TK', …)`), `tk_can_manage`, `tk_can_read_contacts`; `tk_person_visible` (ersetzt den Platzhalter aus AD v0.9, gleiche Signatur: Person ist Leitung in einer Planung mit `tk_can_read`); Policies (US-TK-01, -04, -14)
- [ ] T3: Migration Startbestand `tk_qualification_sports` (Prototyp 4.8) mit Protokoll nicht zuordenbarer Bezeichnungen (US-TK-03 AK5)
- [ ] T4: Migration Trigger (Referat aus Tourtyp R12, Audit, Sperre direkter Statusänderung)
- [ ] T5: Migration `tk_calculate` nach R1–R4, R6, R22 (US-TK-06, -07, -08, -10, -11, -12, -19)
- [ ] T6: pgTAP Rechentests mit Planungen 1–5, 7, 9 aus Abschnitt 9, Lizenz-Erwerb im Halbjahr (R2 b) (erwartete Werte), Satzwechsel nach `valid_from` (US-TK-19 AK2), fehlender Satz (AK4)
- [ ] T7: Migration `tk_save_plan` (Schritte 1–9), `tk_copy_plan`, `tk_delete_plan` (US-TK-02 bis -11, -23)
- [ ] T8: Migration `tk_change_status` ohne EZ-Aufrufe (submit, query, resubmit, approve mit Satzstand, done, close, cancel ohne Einsatz) (US-TK-13, -14, -17, -18)
- [ ] T9: Migration Lesefunktionen `tk_list_plans`, `tk_get_plan`, `tk_cost_report` (US-TK-01, -20)
- [ ] T10: Migration `tk_purge_contacts` und `pg_cron`-Job (US-TK-22)
- [ ] T11: Migration `tk_settlement_draft` (US-TK-24)
- [ ] T12: Fehlercodes in contracts/error-codes.md (Abschnitt 5)
- [ ] T13: Migration EZ-Anbindung in `tk_change_status` (publish, cancel) und `tk_save_plan` (Synchronisation, Abrechnungsart, Warnungen) (US-TK-16, -17) – zusammen mit EZ T036–T038 (`ez_upsert_planned_event` mit Abrechnungsart nach Übergabe v1.3)
- [ ] T14: pgTAP EZ-Anbindung: Einsatz nach publish mit Inhalt R15 (Gemeinschaftstour mit Abrechnungsart „Gemeinschaftstour“); Änderung vor/nach erster Anwesenheit und nach Abrechnung (`EZ_SETTLED`); Absage markiert Einsatz, mit anwesenden Personen `TK_EZ_LOCKED`; Fehler rollt zurück
- [ ] T15: Seed nach Abschnitt 9
- [ ] T16: Frontend Liste /tk, /tk/neu, Kopieren (US-TK-01, -02, -23)
- [ ] T17: Frontend /tk/:id Schritte 1–7, Seitenleiste, Speichern mit row_version und Autospeichern, Statusdialoge, Verlauf (US-TK-03 bis -14, -16 bis -18)
- [ ] T18: pgTAP Sichtbarkeitsmatrix Abschnitt 9, R19 je Status, R17, R13, Kontaktdaten-RLS, direkte Schreibzugriffe abgelehnt, Löschjob (R16)
- [ ] T19: Frontend Ausgaben: Eingabeblatt, Ausschreibungstext, Zusammenfassung (Port der Prototyp-Funktionen `yolawoFields`, `descText`, `mailText` ohne Storno), PDF mit jsPDF (US-TK-15, -21)
- [ ] T20: TypeScript-Modul `calc.ts` mit Vitest gegen dieselben Testfälle wie T6 (Live-Anzeige)
- [ ] T21: Frontend /tk/auswertung mit CSV-Export (US-TK-20)
- [ ] T23: Migration `tk_privacy_confirmations`, `tk_create_leader`, `tk_reactivate_leader` mit pgTAP (Häkchen Pflicht, Funktion Helfer:in, Referat der Planung, Rechte, Reaktivieren) und Fehlercodes `TK_PRIVACY_NOT_CONFIRMED`, `TK_PERSON_NOT_INACTIVE` (R23, US-TK-03 AK9, AK10) – nach AD T62 mit Übergabe v1.8 Punkt 16; Frontend-Dialog in T17
- [ ] T22: Abnahme in TEST mit allen Testzugängen (Desktop und 375 px); Vergleich Planung 1 mit dem Prototyp; danach `ad_modules.is_available = true` für TK per Migration (Freigabe durch den Product Owner)

## 11. Annahmen und offene Punkte

Bestätigt vom Product Owner (26.10.2026): Freigabe über die Aktion „darf freigeben“ (Q1, statt TKF); Titel ungekürzt (90 Zeichen in der Anwesenheitserfassung); Gemeinschaftstour übergibt die Abrechnungsart; Kurse ein- und mehrtägig nur nach Lehreinheiten, kein Vorschlag bei mehrtägigen Kursen, keine Organisationspauschale; Trainersatz auch bei Lizenz-Erwerb im Halbjahr des Startdatums (wie Finanzen).

Bestätigt vom Product Owner (22.10.2026): Modulname, Kürzel TK; Kurse im Referat Ausbildung; Leitung aus den Aktiven; Lizenz-Stichtag erster Tag, Trainersatz für die ganze Tour; Freigabe durch Referent:innen, delegierbar, vergeben durch den Admin, mit Bearbeitungs- und Rückfragerecht; Einsatz bei „in Yolawo angelegt“, bei Absage „abgesagt“; Abrechnung vorbefüllen, Finanzen rechnet; Gemeinschaftstour mit Organisationspauschale, die vorerst die Sektion trägt; Sätze in der Administration, Pflege nur Admin; keine Stornoregel; keine PDF-Übernahme; MVP Kostenauswertung, CO2-Auswertung Iteration 1, Eingabe durch Tourenleitende Iteration 2; strukturierte Speicherung.

Bestätigt vom Product Owner (26.10.2026, zweiter Teil): externe Leitende direkt aus der Planung anlegen bzw. wieder aktivieren, mit Funktion Helfer:in, durch alle mit TK bearbeiten (R23; A9 geändert); „in Yolawo angelegt“ nur mit Freigaberecht oder Geschäftsstelle (A11 geändert); Löschung der Kontaktdaten 30 Tage nach Tourende bzw. Absage, inkl. E-Mail und Mobilnummer (A6 geändert, R16); alle 24 Stories im MVP; Annahmen bestätigt: Startwert der Vorlage „Freigabe Touren und Kurse“ für alle Referent:innen Touren und Ausbildung, Geschäftsstelle gibt nicht frei (A2); Referat aus dem Tourtyp (A1, R12); Admin sieht keine Kontaktdaten (A3); „durchgeführt“ manuell, „abgeschlossen“ nur Geschäftsstelle (A5); Spalten der Kostenauswertung, CSV nur Geschäftsstelle (A7); keine E-Mails (A8); c1 bleibt Bestätigung (A10); Kennzeichen an Kostenzeilen statt Texterkennung, Grenzwerte als Sätze (R6); Autospeichern 2 s, kein Entwurf im Browser; Löschen nur Geschäftsstelle (`draft`, `cancelled` ohne Einsatz); Zuordnung Qualifikationsart → Sportart per Migration aus Prototyp 4.8, Pflege später; Mengengerüst und Antwortzeiten (Abschnitt 8); Aufbewahrung 5 Jahre. Umsetzung mit den Werten des Prototyps; „benötigtes Material“ nur als Ausrüstungsliste (Freitext), Reservierung von Material der Sektion später. Keine manuelle Abweichung vom Ergebnis der Lizenzprüfung (R2); fehlende Lizenzen trägt die Geschäftsstelle im Ehrenamtsmanagement nach. Statusmodell (Abschnitt 4), Admin liest, Berechnung in der Datenbank, PDF der Einreichung nicht gespeichert, Planwerte nur Vorbelegung für Finanzen.

Annahmen (bei Abnahme bestätigen):
- [ANNAHME] Neue Personen aus der Planung: Funktion Helfer:in gültig ab dem Tag der Anlage (nicht ab dem Startdatum der Tour) (R23).
- [ANNAHME] Länge der Freitexte max. 4.000 Zeichen; Name `ez_event_id` ohne FK (Abschnitt 2).

Offen (kein Blocker für den Start der Umsetzung, aber vor der Abnahme):
- [OFFEN] Prüfliste für das Referat Touren (pruefliste-referat-touren.md): MwSt. 19 % auf Zahlungsgebühren, Konditionsgrenzen, Technikstufen, Zuordnung Qualifikation → Sportart, Hüttenpreis-Plausibilität, Faktoren Reisebus und Selbstversorgerhütte, Flug-Warnung ab 1.000 km, echte Gültig-ab-Daten der Sätze (Startbestand nutzt 01.01.2026). Bis dahin gelten die Werte des Prototyps.
- [OFFEN] Text und Link des Datenschutzhinweises (gemeinsam mit der Anwesenheitserfassung).
- [OFFEN] Gemeinschaftstour: Organisationspauschale später von Teilnehmenden zurückholen? (nach dem MVP)
- [OFFEN] Iteration 2: öffentliches Formular oder Zugang für Tourenleitende.
- [OFFEN] Löschung der E-Mails mit Einreichungen im Postfach des Referats (organisatorisch, außerhalb des Vereins OS).
