# Spec: Finanzen (FI)

Version: 0.3 · Status: Ready (MVP freigegeben am 26.10.2026; Nachtrag v0.3 Buchungslauf Verträge freigegeben am 26.10.2026) · Stand: 26.10.2026 · Product Owner: Toni Werner
Stories: docs/specs/fi-finanzen/02-stories.md (US-FI-01 bis US-FI-21, v0.2.1)
Grundlage: 00-steckbrief.md v0.5 (abgeschlossen), 01-erhebung.md v0.6 (R1–R30, C6, C7), 02-stories.md v0.1 (R31–R33), glossar.md v1.6, rollen.md v1.2, tech-stack.md, Übergaben FI → AD v1.3 (A1–A10), FI → EZ v1.2 (Z1–Z5), FI → TK v1.0; spec.md Administration v0.9 (`ad_rates`, `ad_rates_at`, `ea_person_names`), spec.md Anwesenheitserfassung v0.5 (`ez_events`, `ez_attendances`, `ez_climbing_points_report`)
Änderungen v0.3: Nachtrag Buchungslauf Verträge (Abschnitt 12; 01-erhebung.md v0.7.1, R34–R47; US-FI-18 bis US-FI-21); Status Ready (Product Owner 26.10.2026).
Änderungen v0.2: Status Ready (Product Owner 26.10.2026); [ANNAHME]-Punkte bleiben sichtbar und werden bei der Abnahme in TEST bestätigt. Voraussetzung der Umsetzung: Administration Nachtrag v0.10 und Anwesenheitserfassung Nachtrag v0.6.
Änderungen v0.1.2: Namen der Anwesenheitserfassung bestätigt (spec.md EZ v0.6: `remuneration_kind_id`, `ez_settlement_basis`, `fi_attendance_locked`, `fi_event_locked`); Annahmen dazu entfallen.
Änderungen v0.1.1: Namen an den Nachtrag v0.10 der Administration angeglichen (`ad_my_approve_referate`, `ad_can_approve`, `ad_remuneration_kinds`/`ad_remuneration_positions`, `ad_settlement_deadline`, `ad_payout_settings_at`, `ea_person_finance_data`); Annahme zu den AD-Namen entfällt.
Änderungen v0.1: Erster Entwurf.

**Voraussetzungen für die Umsetzung:** (1) Nachtrag der Administration nach Übergabe FI → AD v1.3 (Abrechnungsarten, Vorbelegung, Sätze, Höchstbetrag, Fristen, Kennzeichen am Referat, Angaben der Sektion, Lesefunktion Personendaten, Modul FI, Aktion „freigeben“ aus Q1, `fi_person_visible`) und (2) Nachtrag der Anwesenheitserfassung nach Übergabe FI → EZ v1.2 (Abrechnungsart am Einsatz, Lesefunktion `ez_settlement_basis`, Platzhalter `fi_attendance_locked` und `fi_event_locked`). Namen der Objekte aus den Nachträgen sind hier als [ANNAHME] verwendet; maßgeblich ist der jeweilige Nachtrag. Finanzen legt keine Tabellen oder Funktionen anderer Module an; es ersetzt nur die Platzhalter `fi_person_visible`, `fi_attendance_locked` und `fi_event_locked` (gleiche Signatur).

## 1. Ziel und Scope

**Ziel:** Die halbjährliche Abrechnung der Übungsleiterpauschale für die Referate Kinder und Jugend und Leistungssport entsteht vollständig aus der Anwesenheitserfassung; die Auszahlung erfolgt in Auszahlungsrunden mit Auszahlliste (PDF) für die Buchhaltung und Überweisungsdatei (XML) für die Sparkasse. Erfolg: Aufwand der Geschäftsstelle je Abrechnungshalbjahr von ca. 3–5 Arbeitstagen auf höchstens 2 Stunden [ANNAHME: Zielwert]; keine Übertragung aus Excel.

**Im Scope (MVP):**
- Berechnung je Person und Abrechnungshalbjahr aus Einsätzen mit Abrechnungsart (Training, Tagesausflug, Mehrtagesfahrt, Ausbildungsfahrt, Trainingslager, Wettkampfbetreuung) der Referate mit Kennzeichen „halbjährliche Abrechnung“; Trainingseinheiten, Tages- und Halbtagessätze, Wettkampfbetreuung je Kalendertag, Organisationspauschale; Satz Trainer:in nach förderfähiger Lizenz.
- Hinweise (Bestätigung steuerfreie Einnahmen, Trainervereinbarung, Bankverbindung, Höchstbetrag, ohne Uhrzeit, ohne Trainingszeit, keine förderfähige Lizenz, Satz fehlt).
- Korrektur je Position mit Begründung; Begründung einer Ausnahme (Lizenz) durch die Referent:in.
- Bestätigung durch Referent:innen („sachlich richtig“), Vertretung durch die Geschäftsstelle.
- Abschluss mit Abrechnungsdokument (PDF) und Sperre der Anwesenheiten; Rücknahme vor der Abgabe.
- Abgabe (auch nach der Frist mit Begründung) und Verfall von Hand.
- Auszahlungsrunden: zusammenstellen, freigeben, Auszahlliste (PDF) und Überweisungsdatei (XML, pain.001.001.03) erzeugen, erneut abrufen.
- Abgleich Punktekonto Kletterhalle.

**Nicht im Scope:**
- Iteration 1: Kurs und Tour (Einzelabrechnung, Vorbelegung aus der Planungshilfe), Einzelabrechnung anderer Referate, Reisekosten und Kostenerstattung, Kosten bei Absage, Liste „nicht abgerechnet nach 4 Wochen“, Storno einer Auszahlungsrunde, Entscheidung zu Probetrainings, Sonderfälle (Nachzahlung, Rückforderung).
- Später: Buchungslauf für Verträge, Budget, Dashboard, Ehrenamtspauschale (inkl. vergüteter Arbeitseinsätze), DATEV-Export.
- Pflege von Sätzen, Abrechnungsarten, Fristen, Höchstbetrag, Angaben der Sektion (Administration); Pflege von Einsätzen (Anwesenheitserfassung); Pflege von Bankverbindung, Nachweisen, Lizenzen (Ehrenamtsmanagement).
- Elektronische Unterschrift; Speichern von PDF- oder XML-Dateien; Bankschnittstelle; E-Mails; Löschlauf nach Frist (mit dem übergreifenden Löschlauf).

## 2. Datenmodell

Konventionen nach tech-stack.md: Schema `public`, Präfix `fi_`, snake_case, RLS auf jeder Tabelle, Grants nur an `authenticated`. Beträge `numeric(10,2)`, Mengen `numeric(6,2)`. Datum `date` (Europe/Berlin). Audit-Spalten `*_by` = `auth.uid()`, `*_by_person_id` per Trigger über `ad_accesses`.

Typen:
- `fi_settlement_status`: `draft` (Entwurf), `confirmed` (bestätigt), `closed` (abgeschlossen), `submitted` (abgegeben), `expired` (verfallen), `paid` (ausgezahlt).
- `fi_rate_role`: `trainer` (Trainer:in), `helper` (Helfer:in), `none` (ohne Rolle, z. B. Organisationspauschale).
- `fi_position`: `training_unit` (Trainingseinheit), `day` (Tagessatz), `half_day` (Halbtagessatz), `competition_day` (Wettkampfbetreuung je Tag), `organization_day` (Organisationspauschale je Tag). Weitere (Lehreinheit) in Iteration 1.
- `fi_hint`: `no_time` (ohne Uhrzeit), `no_training_time` (ohne Trainingszeit), `no_license` (keine förderfähige Lizenz), `rate_missing` (Satz fehlt).
- `fi_run_status`: `draft` (Entwurf), `released` (freigegeben). `cancelled` (storniert) kommt mit Iteration 1.
- `fi_log_action`: `calculated`, `corrected`, `exception_reason`, `confirmed`, `confirmed_substitute`, `confirmation_reset`, `closed`, `reopened`, `submitted`, `expired`, `paid`.

### fi_settlements (Abrechnung)

| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| person_id | uuid | ja | – | FK ea_persons(id) on delete restrict; nur `kind = 'human'` |
| year | smallint | ja | – | Jahr des Abrechnungshalbjahres (2026–2100) |
| half | smallint | ja | – | 1 oder 2 (Check) |
| status | fi_settlement_status | ja | 'draft' | Zustand (Abschnitt 4) |
| amount | numeric(10,2) | ja | 0 | Summe der Positionen (wirksame Beträge), vom System gesetzt |
| closed_at / closed_by / closed_by_person_id | timestamptz / uuid / uuid | nein | null | abgeschlossen am / von |
| submitted_on | date | nein | null | unterschrieben abgegeben am (R19) |
| submitted_late_reason | text | nein | null | Begründung bei Abgabe nach der Frist, 1–500 Zeichen; Pflicht genau dann, wenn `submitted_on` nach der Frist liegt (Prüfung in der Funktion) |
| expired_at / expired_by | timestamptz / uuid | nein | null | verfallen gesetzt am / von |
| payout_run_id | uuid | nein | null | FK fi_payout_runs(id) on delete set null; Runde im Entwurf oder freigegeben (R25) |
| created_at / created_by, updated_at / updated_by | | | | Audit |

Unique `(person_id, year, half)`. Index `(year, half, status)`, `(payout_run_id)`.

### fi_settlement_items (Position)

| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| settlement_id | uuid | ja | – | FK fi_settlements(id) on delete cascade |
| event_id | uuid | ja | – | FK ez_events(id) on delete restrict |
| attendance_id | uuid | nein | null | FK ez_attendances(id) on delete restrict; null bei der Organisationspauschale einer nicht anwesenden organisierenden Person |
| event_date | date | ja | – | Datum bzw. Startdatum (Sortierung, Satzstand R9) |
| referat_id | uuid | ja | – | Referat des Einsatzes (Sichtbarkeit R31, Bestätigung R23) |
| group_id | uuid | nein | null | erste Gruppe des Einsatzes (R24); FK gr_groups(id) on delete restrict |
| remuneration_kind_id | uuid | ja | – | Abrechnungsart des Einsatzes; FK ad_remuneration_kinds(id) (spec.md AD v0.10) |
| position | fi_position | ja | – | |
| recorded_role | ez_role | nein | null | Rolle in der Anwesenheit (`trainer`/`helper`); null bei Organisationspauschale |
| calc_rate_role | fi_rate_role | ja | – | berechnete Satzart (R8) |
| calc_quantity | numeric(6,2) | ja | – | berechnete Menge |
| override_rate_role | fi_rate_role | nein | null | Korrektur Satzart (R16) |
| override_quantity | numeric(6,2) | nein | null | Korrektur Menge, ≥ 0 |
| correction_reason | text | nein | null | Pflicht genau dann, wenn eine Korrektur gesetzt ist (Check), 1–500 Zeichen |
| corrected_at / corrected_by | timestamptz / uuid | nein | null | |
| exception_reason | text | nein | null | Begründung der Referent:in für eine Ausnahme (Lizenz), 1–500 Zeichen |
| rate_key | text | nein | null | Schlüssel in `ad_rates`, nach wirksamer Satzart |
| rate | numeric(10,2) | nein | null | Satz am `event_date`; null bei `rate_missing` |
| amount | numeric(10,2) | nein | null | wirksame Menge × Satz; null bei `rate_missing` |
| hints | fi_hint[] | ja | '{}' | Hinweise der Position |

Unique `(settlement_id, event_id, position)` (R10). Index `(attendance_id)`, `(event_id)`.

### fi_settlement_confirmations (Bestätigung je Referat)

| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| settlement_id | uuid | ja | – | FK fi_settlements(id) on delete cascade |
| referat_id | uuid | ja | – | FK ea_referate(id) |
| confirmed_at / confirmed_by / confirmed_by_person_id | timestamptz / uuid / uuid | ja | now() / auth.uid() / Trigger | |
| is_substitute | boolean | ja | false | Vertretung durch die Geschäftsstelle (US-FI-09) |
| substitute_reason | text | nein | null | Pflicht genau dann, wenn `is_substitute` (Check), 1–500 Zeichen |

PK `(settlement_id, referat_id)`.

### fi_settlement_log (Verlauf, R33)

| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | bigint identity | ja | – | PK |
| settlement_id | uuid | ja | – | FK fi_settlements(id) on delete cascade |
| action | fi_log_action | ja | – | |
| detail | jsonb | nein | null | z. B. Referat, Position, alte/neue Werte, Begründung |
| at / by / by_person_id | timestamptz / uuid / uuid | ja | now() / auth.uid() / Trigger | |

Nur Insert durch die Funktionen.

### fi_payout_runs (Auszahlungsrunde)

| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| year / half | smallint | ja | – | Abrechnungshalbjahr |
| number | smallint | ja | – | fortlaufend je Halbjahr ab 1, vom System (R25) |
| status | fi_run_status | ja | 'draft' | |
| execution_date | date | ja | – | Ausführungsdatum (R30) |
| msg_id | text | nein | null | Nachrichten-ID, bei Freigabe gesetzt, unique, max. 35 Zeichen, `^[A-Za-z0-9-]+$` [ANNAHME: `FI-{Jahr}-{Halbjahr}-{Nummer, 2-stellig}-{8 Zeichen Zufall}`] |
| pmt_inf_id | text | nein | null | Zahlungs-ID, Aufbau wie msg_id mit Zusatz `-P` |
| line_count | integer | nein | null | Anzahl Auszahlzeilen bei Freigabe |
| total | numeric(12,2) | nein | null | Summe bei Freigabe |
| released_at / released_by / released_by_person_id | timestamptz / uuid / uuid | nein | null | |
| created_at / created_by | | | | |

Unique `(year, half, number)`. Eine Runde im Entwurf wird beim Verwerfen gelöscht; ihre Nummer wird nicht erneut vergeben (Zähler je Halbjahr = max(number) aller je angelegten Runden; eigene Zählertabelle `fi_run_counters (year, half, last_number)`) [ANNAHME].

### fi_payout_lines (Auszahlzeile)

| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| run_id | uuid | ja | – | FK fi_payout_runs(id) on delete restrict |
| settlement_id | uuid | ja | – | FK fi_settlements(id) on delete restrict |
| person_id | uuid | ja | – | Person der Abrechnung |
| group_id | uuid | nein | null | Gruppe (R24); null nur bei Positionen ohne Gruppe (Iteration 1) |
| group_label | text | ja | – | Name der Gruppe zum Zeitpunkt der Freigabe (für Liste und Verwendungszweck) |
| amount | numeric(10,2) | ja | – | > 0 |
| remittance | text | ja | – | Verwendungszweck, max. 140 Zeichen (R26) |
| end_to_end_id | text | ja | – | unique, max. 35 Zeichen: `{msg_id ohne Zufallsteil}-{laufende Nummer, 4-stellig}` [ANNAHME] |
| sort_no | integer | ja | – | Reihenfolge in Liste und Datei (R28) |

Entsteht nur bei der Freigabe. Unique `(run_id, settlement_id, group_id)`. Kein Name, keine IBAN (R21).

### fi_climbing_checks (Abgleich Punktekonto)

| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| location_id | uuid | ja | – | FK ad_locations(id) on delete restrict; Ort mit Punktekonto |
| period_from / period_to | date | ja | – | Zeitraum, from ≤ to |
| counted_without_trials / counted_with_trials | integer | ja | – | Summen aus der Anwesenheitserfassung zum Zeitpunkt des Speicherns |
| invoiced | integer | ja | – | Anzahl bzw. Punkte laut Rechnung, ≥ 0 |
| invoice_number | text | nein | null | max. 50 Zeichen |
| remark | text | nein | null | max. 500 Zeichen |
| created_at / created_by / created_by_person_id | | | | |

### Funktionen (security definer, fester `search_path`, Grants nur an `authenticated`)

Rechte (zentrale Stelle):
- `fi_can_manage() returns boolean` – `ad_has_level('FI','manage')`.
- `fi_can_read_all() returns boolean` – `ad_has_level('FI','read')` (Reichweite alle).
- `fi_read_referate() returns uuid[]` – `ad_my_referate('FI','read')`.
- `fi_confirm_referate() returns uuid[]` – Referate, für die der Nutzer die Aktion „freigeben“ in FI hat = `ad_my_approve_referate('FI')` (spec.md AD v0.10, R50); Prüfung einzelner Referate über `ad_can_approve('FI', referat)`.
- `fi_can_read_settlement(p_id uuid) returns boolean` – `fi_can_read_all()` oder es gibt eine Position mit `referat_id = any(fi_read_referate())` (R31).

Ersetzte Platzhalter (gleiche Signatur):
- `fi_person_visible(p_person uuid) returns boolean` (Administration, A9) – wahr, wenn eine lesbare Abrechnung die Person betrifft.
- `fi_attendance_locked(p_attendance uuid) returns boolean` (Anwesenheitserfassung, Z3) – wahr, wenn die Anwesenheit in einer Position einer Abrechnung im Zustand `closed`, `submitted`, `expired` oder `paid` steckt.
- `fi_event_locked(p_event uuid) returns boolean` (Anwesenheitserfassung, Z3) – wahr, wenn der Einsatz eine Position in einer solchen Abrechnung hat (sperrt die abrechnungsrelevanten Kopfdaten) (spec.md EZ v0.6, R34).

Lesen:
- `fi_list_settlements(p_year smallint, p_half smallint, p_status fi_settlement_status default null, p_group uuid default null, p_with_hint boolean default null, p_to_confirm boolean default null, p_limit int default 50, p_offset int default 0) returns setof (id, person_id, display_name, groups text[], amount, status, hints text[], confirmations jsonb, total_count)` – nur Zeilen mit `fi_can_read_settlement`; `display_name` über die Namenslogik der Administration; `p_to_confirm` = Entwurf mit Positionen in `fi_confirm_referate()` ohne Bestätigung dieses Referats; Sortierung Nachname, Vorname.
- `fi_get_settlement(p_id uuid) returns jsonb` – Kopf, Positionen (mit Einsatz: Einsatzart, Titel bzw. Gruppe, Datum, Zeiten), Bestätigungen je Referat, Verlauf, Hinweise auf Ebene der Abrechnung (R11–R14, berechnet); Fehler `FI_NOT_FOUND`, wenn nicht vorhanden oder nicht lesbar.
- `fi_settlement_document(p_ids uuid[]) returns jsonb` – Daten für das Abrechnungsdokument (R18) je Abrechnung im Zustand `closed` oder später; nur `fi_can_manage()`; Abgabefrist aus den Stammdaten (A5).
- `fi_list_payout_runs(p_year smallint default null, p_half smallint default null) returns setof (…)` – nur `fi_can_manage()`.
- `fi_preview_payout_run(p_run uuid) returns jsonb` – Auszahlzeilen (berechnet nach R24) und ausgeschlossene Abrechnungen mit Grund; nur `fi_can_manage()`.
- `fi_payout_export(p_run uuid) returns jsonb` – nur `fi_can_manage()`, nur Runden `released`: Kopf (msg_id, pmt_inf_id, Zeitpunkt der Freigabe, Ausführungsdatum, Anzahl, Summe), Angaben der Sektion (A10), Bestätigungen für „sachl. richtig“ (je Referat Namen und Datum, Vertretung gekennzeichnet), je Auszahlzeile Zuname, Vorname, Betrag, Gruppe, Verwendungszweck, Ende-zu-Ende-ID **sowie Kontoinhaber:in und IBAN aus der Lesefunktion der Administration (A8)** und Kennzeichen „Bankverbindung seit Freigabe geändert“ (R21). Daraus erzeugt das Frontend PDF und XML im Browser; nichts wird gespeichert.
- `fi_climbing_report(p_location uuid, p_from date, p_to date) returns setof (…)` – ruft `ez_climbing_points_report` mit FI-Rechten (Z2); nur `fi_can_manage()`.
- `fi_list_climbing_checks(p_location uuid default null) returns setof (…)` – nur `fi_can_manage()`.

Schreiben (keine Insert/Update/Delete-Grants auf `fi_`-Tabellen; alle Schreibvorgänge über diese Funktionen):
- `fi_calculate_half(p_year smallint, p_half smallint) returns jsonb` – nur `fi_can_manage()` (`FI_FORBIDDEN`). Liest `ez_settlement_basis` (Z2) für das Halbjahr und die Referate mit Kennzeichen „halbjährliche Abrechnung“ (A6). Je Person: Abrechnung anlegen, falls nicht vorhanden; nur Abrechnungen im Zustand `draft` oder `confirmed` werden neu berechnet (R15); vorhandene Korrekturen und Ausnahmebegründungen bleiben bei Positionen erhalten, deren Einsatz, Position und Rolle unverändert sind; entfallene Positionen werden entfernt. Bei Änderung einer bestätigten Abrechnung fällt die Bestätigung der betroffenen Referate zurück (R23). Berechnung nach R3–R10 (Abschnitt 5). Rückgabe: Anzahl angelegt, neu berechnet, unverändert, mit Hinweis.
- `fi_correct_item(p_item uuid, p_rate_role fi_rate_role, p_quantity numeric, p_reason text)` – nur `fi_can_manage()`; Abrechnung `draft` oder `confirmed` (sonst `FI_STATUS`); `null` in beiden Werten entfernt die Korrektur; Begründung Pflicht (`FI_REASON_REQUIRED`); setzt Bestätigung des Referats der Position zurück; berechnet Betrag und Summe neu; Verlauf.
- `fi_set_exception_reason(p_item uuid, p_reason text)` – Referat der Position in `fi_confirm_referate()` oder `fi_can_manage()`; Zustand `draft`; 1–500 Zeichen; Verlauf.
- `fi_confirm(p_ids uuid[])` – für jede Abrechnung: Zustand `draft`, Bestätigung aller Referate der Positionen, die in `fi_confirm_referate()` liegen und noch nicht bestätigt sind; keine solche Position → `FI_FORBIDDEN`; sind danach alle Referate bestätigt → `confirmed`; Verlauf.
- `fi_confirm_substitute(p_id uuid, p_referat uuid, p_reason text)` – nur `fi_can_manage()`; wie oben mit `is_substitute = true` und Pflichtbegründung.
- `fi_close(p_ids uuid[])` – nur `fi_can_manage()`; je Abrechnung: Zustand `confirmed` (`FI_NOT_CONFIRMED`); keine Position mit `rate_missing` (`FI_RATE_MISSING`); Betrag > 0 (`FI_AMOUNT_ZERO`); der Nutzer hat keine der Bestätigungen gegeben (`FI_SAME_PERSON`); setzt `closed`, `closed_*`; Verlauf. Alle oder keine (eine Transaktion; Fehler nennen die betroffene Abrechnung im Detail).
- `fi_reopen(p_id uuid)` – nur `fi_can_manage()`; nur `closed` (`FI_STATUS`); setzt `draft`, löscht Bestätigungen; Verlauf.
- `fi_record_submission(p_id uuid, p_date date, p_late_reason text default null)` – nur `fi_can_manage()`; nur `closed`; Datum nicht in der Zukunft (`FI_DATE_FUTURE`); nach der Frist (A5) ohne Begründung → `FI_LATE_REASON_REQUIRED` (Frontend zeigt die Rückfrage R19 und fragt die Begründung ab); setzt `submitted`; Verlauf.
- `fi_expire(p_ids uuid[])` – nur `fi_can_manage()`; nur `closed` und Frist abgelaufen (`FI_DEADLINE_NOT_PASSED`); setzt `expired`; Verlauf.
- `fi_create_payout_run(p_year smallint, p_half smallint, p_execution_date date) returns uuid` – nur `fi_can_manage()`; Ausführungsdatum ≥ heute (`FI_EXECUTION_DATE`); nächste Nummer (R25); ordnet alle abgegebenen, noch keiner Runde zugeordneten Abrechnungen des Halbjahres zu, die die Voraussetzungen erfüllen (R12–R14, Betrag > 0).
- `fi_set_payout_run_settlements(p_run uuid, p_ids uuid[])` – nur Runde `draft`; Abrechnungen müssen `submitted`, ohne andere Runde und auszahlbar sein (`FI_NOT_PAYABLE`, Detail: Grund).
- `fi_update_payout_run(p_run uuid, p_execution_date date)` – nur Runde `draft`.
- `fi_discard_payout_run(p_run uuid)` – nur Runde `draft`; löst die Zuordnung der Abrechnungen; löscht die Runde.
- `fi_release_payout_run(p_run uuid) returns uuid` – nur `fi_can_manage()`; Runde `draft` mit mindestens einer Abrechnung (`FI_RUN_EMPTY`); Angaben der Sektion vollständig (`FI_PAYOUT_SETTINGS_MISSING`); jede Abrechnung weiterhin auszahlbar, insbesondere Bankverbindung vorhanden (`FI_NOT_PAYABLE` mit Name im Detail); bildet die Auszahlzeilen nach R24 mit Verwendungszweck (R26) und IDs; setzt `released`, `msg_id`, `pmt_inf_id`, `line_count`, `total`; setzt die Abrechnungen auf `paid`; Verlauf. Gibt die Runden-ID zurück; das Frontend ruft danach `fi_payout_export` auf.
- `fi_save_climbing_check(p_location uuid, p_from date, p_to date, p_invoiced int, p_invoice_number text default null, p_remark text default null) returns uuid` – nur `fi_can_manage()`; Ort mit Punktekonto (`FI_LOCATION_NO_POINTS`); speichert die aktuellen Summen aus `fi_climbing_report`.

Trigger: Audit (`*_by_person_id`), Sperre von `person_id`, `year`, `half` nach Anlage; `fi_settlement_items` berechnet `amount` aus wirksamer Menge und Satz.

### Benötigt aus anderen Modulen [ANNAHME: Namen nach den Nachträgen]

| Objekt | Modul | Zweck |
|---|---|---|
| `ad_remuneration_kinds`, `ad_remuneration_positions` (Satzschlüssel je Rolle) | AD (A1) | Satzschlüssel je Position und Satzart |
| `ad_rates_at(date)` mit Schlüsseln aus A3 und Höchstbetrag (A4) | AD | Sätze, Höchstbetrag |
| `ad_settlement_deadline(year, half)` | AD (A5) | R19 |
| `ea_referate.semiannual_settlement` | AD (A6) | R2 |
| `ad_payout_settings_at(date)` (Name, IBAN, BIC, Sachkonto) | AD (A10) | Auszahlliste, Überweisungsdatei |
| `ea_person_finance_data(ids, date)` | AD (A8) | Bankverbindung, Trainervereinbarung, Bestätigung steuerfreie Einnahmen, förderfähige Lizenzen mit gültig von/bis |
| Modul FI, Reichweite „Referat“, `ad_my_approve_referate`, `ad_can_approve`, `fi_person_visible` (Platzhalter) | AD (A7, A9, Q1) | Rechte, Namen |
| `ez_events.remuneration_kind_id` | EZ (Z1) | Abrechnungsart des Einsatzes |
| `ez_settlement_basis(from, to, referate)` mit Dauer der Trainingszeit und Gruppenname | EZ (Z2) | Grundlage der Berechnung |
| `ez_climbing_points_report` mit FI-Rechten | EZ (Z2) | Abgleich Punktekonto |
| Platzhalter `fi_attendance_locked`, `fi_event_locked`, Prüfung in den Schreibfunktionen | EZ (Z3) | Sperre |

## 3. Rechte / RLS

Grundsatz: Lesen per RLS über `fi_can_read_settlement` bzw. `fi_can_manage`; Schreiben nur über die Funktionen aus Abschnitt 2. Namen nur über die Namenslogik der Administration (`fi_person_visible`). Bankverbindung, Nachweise und Lizenzen nur über die Lesefunktion A8 und nur in `fi_calculate_half`, den Hinweisen und `fi_payout_export` (Referent:innen erhalten nur berechnete Hinweise).

| Rechtevorlage (Startwert) | Abrechnungen lesen | berechnen, korrigieren | bestätigen | Ausnahme begründen | abschließen, zurücknehmen, Abgabe, Verfall | Auszahlungsrunden | Abgleich Punktekonto |
|---|---|---|---|---|---|---|---|
| Geschäftsstelle (FI verwalten, alle) | alle | ja | nur in Vertretung | ja | ja | ja | ja |
| Referent:in (FI lesen + „freigeben“, Referat) | Abrechnungen mit Position ihrer Referate, ganz (R31) | – | Positionen ihrer Referate | Positionen ihrer Referate | – | – | – |
| Admin | – | – | – | – | – | – | – |
| Vorstand | – (Startwert ohne Rechte) | – | – | – | – | – | – |

| Tabelle | Lesen (RLS) | Schreiben |
|---|---|---|
| fi_settlements | `fi_can_read_settlement(id)` | Funktionen |
| fi_settlement_items | Abrechnung lesbar | Funktionen |
| fi_settlement_confirmations | Abrechnung lesbar | `fi_confirm`, `fi_confirm_substitute`, Rücksetzen durch Korrektur, Neuberechnung, `fi_reopen` |
| fi_settlement_log | Abrechnung lesbar | Funktionen |
| fi_payout_runs, fi_payout_lines, fi_run_counters | `fi_can_manage()` | Funktionen |
| fi_climbing_checks | `fi_can_manage()` | `fi_save_climbing_check` |

Routenschutz: `/fi/*` ohne `ad_has_any_level('FI','read')` → /kein-zugriff; `/fi/auszahlungen*` und `/fi/kletterhalle` nur mit `fi_can_manage()`. Schaltflächen nach Abschnitt 6.

## 4. Zustände und Übergänge

Abrechnung:

| Von | Nach | Wer | Bedingung |
|---|---|---|---|
| – | Entwurf | Geschäftsstelle (`fi_calculate_half`) | Person hat abrechenbare Anwesenheiten im Halbjahr |
| Entwurf | Entwurf | Geschäftsstelle | neu berechnen, korrigieren; Referent:in begründet Ausnahme |
| Entwurf | bestätigt | Referent:in(nen) bzw. Geschäftsstelle in Vertretung | alle Referate der Positionen bestätigt (R23) |
| bestätigt | Entwurf | Geschäftsstelle / System | Korrektur, Neuberechnung mit Änderung |
| bestätigt | abgeschlossen | Geschäftsstelle | R9, Betrag > 0, nicht dieselbe Person wie bei einer Bestätigung; Sperre (R17) |
| abgeschlossen | Entwurf | Geschäftsstelle | Rücknahme; Bestätigungen entfallen; Sperre aufgehoben |
| abgeschlossen | abgegeben | Geschäftsstelle | Abgabedatum; nach der Frist mit Begründung |
| abgeschlossen | verfallen | Geschäftsstelle | Frist abgelaufen, von Hand |
| abgegeben | ausgezahlt | Geschäftsstelle (`fi_release_payout_run`) | in freigegebener Runde |

Eine Abrechnung ohne Positionen nach Neuberechnung im Entwurf wird gelöscht [ANNAHME].

Auszahlungsrunde:

| Von | Nach | Wer | Bedingung |
|---|---|---|---|
| – | Entwurf | Geschäftsstelle | Ausführungsdatum ≥ heute |
| Entwurf | Entwurf | Geschäftsstelle | Auswahl, Ausführungsdatum ändern |
| Entwurf | (gelöscht) | Geschäftsstelle | verwerfen; Nummer wird nicht wieder vergeben |
| Entwurf | freigegeben | Geschäftsstelle | mindestens eine auszahlbare Abrechnung; Angaben der Sektion vollständig |

## 5. Geschäftsregeln

R1–R30 aus 01-erhebung.md, R31–R33 aus 02-stories.md; hier mit Berechnungsdetails, Meldung und Fehlercode.

- R1 Grundlage: `ez_settlement_basis` liefert nur Anwesenheiten `present` mit Rolle `trainer`/`helper` an nicht abgesagten Einsätzen mit Abrechnungsart.
- R2 Halbjahr: `start_date` zwischen 01.01. und 30.06. bzw. 01.07. und 31.12.; nur Referate mit `semiannual_settlement = true`.
- R3 Trainingseinheiten: `calc_quantity = ceil(Dauer in Minuten / 30)` aus der Trainingszeit am Wochentag; Position `training_unit`.
- R4 Ohne Trainingszeit: `calc_quantity = 0`, Hinweis `no_training_time`.
- R5 Tage: eintägig: `under_8h` → `half_day` (Menge 1), `at_least_8h` → `day` (Menge 1). Mehrtägig: Tage = `end_date - start_date + 1`; erster Tag = 24:00 − `start_time`, letzter Tag = `end_time` − 0:00; je Tag < 8 h → Halbtag, sonst Tag; Zwischentage Tag; fehlt `start_time` bzw. `end_time`, zählt der Tag als Tag mit Hinweis `no_time`. Es entstehen bis zu zwei Positionen (`day` mit Menge = Anzahl Tage, `half_day` mit Menge = Anzahl Halbtage).
- R6 Wettkampfbetreuung: Position `competition_day`, Menge = Anzahl Kalendertage (eintägig 1).
- R7 Organisationspauschale: Position `organization_day` für `organizer_person_id`, wenn die Abrechnungsart sie enthält; Menge = Anzahl Kalendertage; Satzart `none`; auch ohne Anwesenheit der Person (`attendance_id` null) [ANNAHME].
- R8 Satzart: `recorded_role = helper` → `helper`. `trainer` → `trainer`, wenn A8 für die Person eine förderfähige Lizenz liefert mit (`valid_from` ≤ `event_date` und (`valid_until` ≥ `event_date` oder null)) oder (`valid_from` im Halbjahr der Abrechnung); sonst `helper` mit Hinweis `no_license`.
- R9 Satz: `ad_rates_at(event_date)` mit dem Schlüssel der Position für die wirksame Satzart; fehlt er → `rate`, `amount` null, Hinweis `rate_missing`; „Für eine Position fehlt der Satz.“ (`FI_RATE_MISSING`) beim Abschluss.
- R10 Eindeutigkeit: je Abrechnung, Einsatz und Position eine Zeile; Wettkampfbetreuung mit mehreren Gruppen: eine Zeile, Gruppe = erste Gruppe.
- R11 Höchstbetrag: Summe = `amount` aller Abrechnungen der Person mit Zustand `closed`, `submitted`, `paid` und Auszahlungsjahr J (bei `paid`: Jahr des Ausführungsdatums; sonst Jahr des Endes der Abgabefrist) + diese Abrechnung; Höchstbetrag `ad_rates_at(31.12.J)`; Hinweis „Höchstbetrag überschritten ({Summe} von {Höchstbetrag})“; keine Sperre.
- R12 Bestätigung steuerfreie Einnahmen: vorhanden, wenn A8 eine Bestätigung mit „für Jahr“ = Jahr der Abrechnung oder ohne Jahr liefert; sonst Hinweis „Bestätigung steuerfreie Einnahmen {Jahr} fehlt“; nicht auszahlbar.
- R13 Bankverbindung: sonst Hinweis „Bankverbindung fehlt“; nicht auszahlbar.
- R14 Trainervereinbarung: gültige Eigenschaft vorhanden; sonst Hinweis „Trainervereinbarung fehlt“; nicht auszahlbar.
- R15 Neu berechnen nur `draft`/`confirmed`.
- R16 Korrektur: Begründung 1–500 Zeichen, sonst „Bitte eine Begründung angeben.“ (`FI_REASON_REQUIRED`); Menge ≥ 0 und höchstens 2 Nachkommastellen, sonst „Bitte eine gültige Menge eingeben.“ (`FI_QUANTITY`).
- R17 Sperre: `fi_attendance_locked`, `fi_event_locked`; Meldung in der Anwesenheitserfassung „Dieser Einsatz ist abgerechnet. Änderungen nur nach Rücknahme des Abschlusses in Finanzen.“ (`EZ_SETTLED`, Nachtrag EZ).
- R18 Abrechnungsdokument: Inhalt nach 01-erhebung.md R18; Erklärung [ANNAHME: Wortlaut] als Text-Konstante im Frontend.
- R19 Frist: Abgabedatum > Frist → `FI_LATE_REASON_REQUIRED`; Rückfrage „Die Frist ist abgelaufen. Der Anspruch ist erloschen. Trotzdem als abgegeben erfassen?“ mit Pflichtfeld „Begründung“.
- R20 Ausgezahlte Abrechnungen sind nicht änderbar (`FI_STATUS`, „In diesem Zustand ist das nicht möglich.“).
- R21 Kein Speichern von Kontoinhaber:in, IBAN, PDF oder XML; Hinweis bei geänderter Bankverbindung beim erneuten Abruf.
- R22 Aufbewahrung 5 Jahre nach Ende des Kalenderjahres der Auszahlung bzw. des Verfalls (Löschlauf mit dem übergreifenden Löschlauf, nicht in diesem MVP).
- R23 Bestätigung: siehe `fi_confirm`; Abschluss durch eine bestätigende Person → „Du hast diese Abrechnung bestätigt. Eine andere Person muss abschließen.“ (`FI_SAME_PERSON`); nicht alle bestätigt → „Die Abrechnung ist noch nicht von allen Referaten bestätigt.“ (`FI_NOT_CONFIRMED`).
- R24 Auszahlzeilen: je Abrechnung Summe der wirksamen Beträge je `group_id`; Zeilen mit Betrag 0 entfallen.
- R25 Nummer: `fi_run_counters`; eine Abrechnung höchstens in einer Runde.
- R26 Überweisungsdatei: pain.001.001.03 nach 01-erhebung.md C7; Verwendungszweck `ÜL-Vergütung {half}. Hj {year} {group_label}`, auf 140 Zeichen gekürzt; Betrag mit Punkt und 2 Nachkommastellen; `Cdtr/Nm` = Kontoinhaber:in, auf 70 Zeichen gekürzt; Zeichen außerhalb des SEPA-Zeichensatzes werden ersetzt (Umlaute bleiben, wie in der Vorlage) [ANNAHME].
- R27 Auszahlliste: nach 01-erhebung.md C6; Titel „Auszahlliste Übungsleitervergütung {half}. Hj. {year} – Runde {number}“.
- R28 Gleichheit: PDF und XML aus demselben `fi_payout_export`; Test: Summe Liste = `CtrlSum`, Zeilen = `NbOfTxs`.
- R29 Erneuter Abruf: gleiche IDs; Warnung „Diese Runde ist bereits freigegeben. Die Überweisungsdatei nicht erneut hochladen.“
- R30 Ausführungsdatum ≥ heute, sonst „Das Ausführungsdatum darf nicht in der Vergangenheit liegen.“ (`FI_EXECUTION_DATE`); Standard nächster Werktag (Mo–Fr; Feiertage nicht berücksichtigt) [ANNAHME].
- R31 Sichtbarkeit Referent:in: `fi_can_read_settlement`; sonst „Abrechnung nicht gefunden.“ (`FI_NOT_FOUND`).
- R32 Rechte: sonst „Für diesen Bereich hast du keine Rechte.“ (`FI_FORBIDDEN`).
- R33 Verlauf: `fi_settlement_log`.
- Weitere Meldungen: Runde ohne Abrechnungen „Die Runde enthält keine auszahlbaren Abrechnungen.“ (`FI_RUN_EMPTY`); Angaben der Sektion fehlen „Die Angaben der Sektion für die Auszahlung fehlen. Bitte den Admin informieren.“ (`FI_PAYOUT_SETTINGS_MISSING`); nicht auszahlbar „Nicht auszahlbar: {Name} ({Grund}).“ (`FI_NOT_PAYABLE`); Betrag 0 „Die Abrechnung hat keinen Betrag.“ (`FI_AMOUNT_ZERO`); Frist nicht abgelaufen „Die Frist ist noch nicht abgelaufen.“ (`FI_DEADLINE_NOT_PASSED`); Datum in der Zukunft „Das Datum darf nicht in der Zukunft liegen.“ (`FI_DATE_FUTURE`); Ort ohne Punktekonto (`FI_LOCATION_NO_POINTS`); unerwartet „Etwas ist schiefgelaufen. Bitte versuche es erneut.“

Fehlercodes neu (Ergänzung in `docs/specs/ad-administration/contracts/error-codes.md`): `FI_FORBIDDEN`, `FI_NOT_FOUND`, `FI_STATUS`, `FI_REASON_REQUIRED`, `FI_QUANTITY`, `FI_RATE_MISSING`, `FI_AMOUNT_ZERO`, `FI_NOT_CONFIRMED`, `FI_SAME_PERSON`, `FI_DATE_FUTURE`, `FI_LATE_REASON_REQUIRED`, `FI_DEADLINE_NOT_PASSED`, `FI_EXECUTION_DATE`, `FI_NOT_PAYABLE`, `FI_RUN_EMPTY`, `FI_PAYOUT_SETTINGS_MISSING`, `FI_LOCATION_NO_POINTS`.

## 6. Screens und Interaktionen

Allgemein wie Administration: deutsch, „du“, Datum TT.MM.JJJJ, Beträge „1.234,56 €“, shadcn/ui, ab 375 px ohne horizontales Scrollen; Namen „Rufname Nachname“. Startseite: Kachel „Finanzen“ über `ad_my_modules`.

| Route | Zeigt | Aktionen | Leer / Fehler | Story |
|---|---|---|---|---|
| /fi | Abrechnungen eines Halbjahres (Auswahl „1. Halbjahr JJJJ“/„2. Halbjahr JJJJ“, Standard aktuelles): Name, Gruppe(n), Betrag, Zustand (Abzeichen), Hinweise (Symbole mit Text), Bestätigung je Referat; Filter Zustand, Gruppe, „mit Hinweis“, „zu bestätigen“ (Referent:in), „Frist abgelaufen“; 50 je Seite; Mehrfachauswahl; mobil als Karten | Geschäftsstelle: berechnen, abschließen (markierte), Abrechnungsdokumente drucken (markierte), verfallen (markierte); Referent:in: bestätigen (markierte) | „Für dieses Halbjahr gibt es noch keine Abrechnungen.“ | US-FI-01, -05, -06, -08, -10, -12 |
| /fi/abrechnung/:id | Kopf (Person, Halbjahr, Zustand, Betrag, Hinweise, Bestätigungen, abgeschlossen/abgegeben), Positionen gruppiert nach Gruppe mit Zwischensumme (Datum, Einsatz, Rolle, Satzart, Menge, Satz, Betrag, Hinweis, Korrektur mit Begründung, Ausnahmebegründung), Verlauf | Geschäftsstelle: Position korrigieren (Dialog Satzart, Menge, Begründung), in Vertretung bestätigen, abschließen, Abrechnungsdokument, Abschluss zurücknehmen, Abgabe erfassen (Datum; nach Frist Rückfrage mit Begründung), verfallen; Referent:in: Ausnahme begründen, bestätigen | „Abrechnung nicht gefunden.“ | US-FI-02 bis -12 |
| /fi/auszahlungen | Runden (Halbjahr, Runde, Ausführungsdatum, Zustand, Anzahl, Summe, freigegeben am/von) | Neue Runde; Runde öffnen; PDF/XML einer freigegebenen Runde abrufen (mit Warnung R29) | „Noch keine Auszahlungsrunden.“ | US-FI-14, -16 |
| /fi/auszahlungen/:id | Entwurf: Ausführungsdatum, gewählte Abrechnungen, Vorschau der Auszahlzeilen (Zuname, Vorname, Betrag, Gruppe) mit Summe, ausgeschlossene Abrechnungen mit Grund; freigegeben: Zeilen, IDs | Entwurf: Abrechnungen ab-/zuwählen, Ausführungsdatum ändern, verwerfen, freigeben (Rückfrage „Runde {n} mit {Anzahl} Überweisungen über {Summe} freigeben? Danach sind die Abrechnungen ausgezahlt.“) → Download Auszahlliste.pdf und Ueberweisungen.xml; freigegeben: erneut abrufen | „Keine auszahlbaren Abrechnungen.“ | US-FI-14, -15, -16 |
| /fi/kletterhalle | Ort (nur mit Punktekonto), Zeitraum (Standard Vormonat); Tabelle je Training (Datum, Gruppe, Teilnehmer:innen, Probetrainings), Summen ohne/mit Probetrainings; Eingabe Anzahl laut Rechnung, Rechnungsnummer, Bemerkung; Abweichungen; gespeicherte Abgleiche | Abgleich speichern | „Keine Trainings im Zeitraum.“ | US-FI-17 |

Erzeugung der Dateien im Browser [ANNAHME: PDF-Bibliothek legt plan.md fest]: Abrechnungsdokument A4 hoch (eine Person je Seite), Auszahlliste A4 quer, Layout nach marke.md; XML als UTF-8-Text nach C7. Dateinamen: `Abrechnung_UEL_{JJJJ}_{H}_{Name}.pdf` bzw. `Abrechnungen_UEL_{JJJJ}_{H}.pdf`, `Auszahlliste_UEL_{JJJJ}_{H}_Runde{n}.pdf`, `Ueberweisungen_UEL_{JJJJ}_{H}_Runde{n}.xml` [ANNAHME]. Nach dem Download Hinweis „Bitte die Überweisungsdatei nach dem Hochladen im Online-Banking von diesem Rechner löschen.“

## 7. Schnittstellen

| Schnittstelle | Richtung | Inhalt |
|---|---|---|
| Administration | AD → FI | `ad_has_level`, `ad_has_any_level`, `ad_my_referate`, Aktion „freigeben“ (Q1), `ad_my_modules`, `ad_rates_at`, Abrechnungsarten (A1, A2), Fristen (A5), Kennzeichen am Referat (A6), Angaben der Sektion (A10), Lesefunktion Personendaten (A8), Namenslogik mit `fi_person_visible` (A9) |
| Administration | FI → AD | ersetzt `fi_person_visible`; Fehlercodes in contracts/error-codes.md |
| Anwesenheitserfassung | EZ → FI | `ez_settlement_basis`, `ez_climbing_points_report` mit FI-Rechten (Z2) |
| Anwesenheitserfassung | FI → EZ | ersetzt `fi_attendance_locked`, `fi_event_locked` (Z3) |
| Planungshilfe | TK → FI | Iteration 1 (`tk_settlement_draft`) |
| Sparkasse | FI → extern | Überweisungsdatei pain.001.001.03, manueller Upload |
| Finanzbuchhaltung | FI → extern | Auszahlliste (Papier mit Unterschriften), Abrechnungsdokumente |

## 8. Nicht-funktionale Anforderungen

- Mengengerüst: 130 Personen, 4.000 abrechenbare Anwesenheiten und 6 Runden je Halbjahr; `fi_calculate_half` < 10 s, `fi_list_settlements` < 2 s, `fi_payout_export` < 2 s, Erzeugung von PDF und XML im Browser < 5 s [ANNAHME]; Mengentest in pgTAP.
- Berechnung ausschließlich in der Datenbank; pgTAP-Tests je Regel R3–R11, R23–R26, R28 und Sichtbarkeit R31.
- XML gegen das XSD pain.001.001.03 geprüft (Test im Frontend mit fiktiven Daten) [ANNAHME: XSD als Testressource im Repository, keine Echtdaten].
- Keine Echtdaten; Seed nur fiktiv, IBAN nur `DE89370400440532013000`.
- Barrierearm: Tabellen mit Überschriften, Zustände nicht nur über Farbe.
- Keine laufenden Kosten.

## 9. Testdaten (supabase/seed-fi.sql, nur TEST, nach seed.sql und seed-ez.sql)

Wie der Seed der Anwesenheitserfassung als eigene Datei, geladen mit `SEED_WITH_FI=1` (nicht in CI; pgTAP legt die Daten selbst an) [ANNAHME]. Alle Namen fiktiv; Beispiel-IBAN. Halbjahr: 1. Halbjahr 2026.

Voraussetzungen im Seed: Referate Kinder und Jugend und Leistungssport mit Kennzeichen „halbjährliche Abrechnung“; Gruppe „Jugendgruppe Test 1“ (c…01, Kinder und Jugend, Trainingszeit Mo 17:00–18:15), neue Gruppe „Leistungsgruppe Test“ (Leistungssport, Di 16:00–18:00); Testzugang Referent:in Kinder und Jugend (Kim Kinderjugend) mit Aktion „freigeben“; neuer Testzugang „Lea Leistung“ (Referent:in Leistungssport, `test.leistung@dav-leipzig.de`); zweiter Testzugang Geschäftsstelle „Gerd Geschäftsstelle“ (`test.geschaeftsstelle2@dav-leipzig.de`) für US-FI-09; Angaben der Sektion in TEST: Name „Sektion Test“, IBAN `DE89370400440532013000`, BIC `TESTDEFFXXX`, Sachkonto „0000 0“.

| # | Person | Daten | Erwartung |
|---|---|---|---|
| 1 | Tina Trainerin | förderfähige Lizenz bis 31.12.2027; Bankverbindung, Trainervereinbarung, Bestätigung 2026; 3 Trainings Jugendgruppe Test 1 (Mo, 75 Min.) | 3 × 3 TE × 6,00 € = 54,00 € (R3) |
| 2 | Ben Lizenzneu | Lizenz erworben 15.05.2026; Trainings 13.04. und 18.05. (Leistungsgruppe Test, 2 h) als Trainer:in | beide mit Satz Trainer:in: 2 × 4 TE × 6,00 € = 48,00 € (R8) |
| 3 | Clara Ablauf | Lizenz gültig bis 31.03.2026; Trainings 30.03. und 13.04. (Jugendgruppe Test 1) als Trainer:in; Mehrtagesfahrt 30.03.–01.04. ohne Uhrzeit | 30.03. Trainer:in, 13.04. Helfer:in mit `no_license`; Fahrt ganz Trainer:in, 3 Tagessätze mit `no_time` |
| 4 | Hans Helfer | Helfer:in Wettkampfbetreuung Sa–So (Leistungsgruppe Test) | 2 × 40,00 € = 80,00 € (R6) |
| 5 | Olga Ohnebank | 1 Training als Helfer:in; keine Bankverbindung | Hinweis „Bankverbindung fehlt“; nicht auszahlbar |
| 6 | Paul Zweigruppen | Trainer:in in Jugendgruppe Test 1 und Leistungsgruppe Test | Abrechnung mit Positionen beider Referate; zwei Bestätigungen nötig; zwei Auszahlzeilen (R24) |
| 7 | Mira Ohnezeit | Training an einem Mittwoch ohne Trainingszeit | Menge 0, `no_training_time` (R4) |
| 8 | Toni Muster | nur Einsätze im Referat Klettern (seed-ez) | keine Abrechnung (R2) |

Erwartete Sichtbarkeit (pgTAP):

| Testzugang | sieht Abrechnungen | darf bestätigen | darf abschließen / Runden |
|---|---|---|---|
| Geschäftsstelle | 1–7 | nur in Vertretung | ja |
| Kim Kinderjugend (Referent:in K&J) | 1, 3, 5, 6, 7 | K&J-Positionen | nein |
| Lea Leistung (Referent:in LS) | 2, 4, 6 | LS-Positionen | nein |
| Admin, Vorstand | keine | nein | nein |

Zusätzlich: Runde 1 mit 1, 2, 4, 6 (nach Bestätigung, Abschluss und Abgabe) → 5 Auszahlzeilen; `CtrlSum` = Summe der Liste; `fi_payout_export` für Kim → `FI_FORBIDDEN`; Abschluss von 1 durch eine Person, die 1 bestätigt hat → `FI_SAME_PERSON`.

## 10. Umsetzungs-Tasks

Voraussetzung: Nachträge AD und EZ umgesetzt (eigene Tasks dort).

- [ ] T1: Migration Typen und Tabellen `fi_settlements`, `fi_settlement_items`, `fi_settlement_confirmations`, `fi_settlement_log`, `fi_payout_runs`, `fi_run_counters`, `fi_payout_lines`, `fi_climbing_checks` mit Checks, Indizes, RLS, Grants, Audit-Triggern (Abschnitt 2, 3)
- [ ] T2: Migration Rechtefunktionen und Ersatz der Platzhalter `fi_person_visible`, `fi_attendance_locked`, `fi_event_locked` (R17, R31)
- [ ] T3: Migration `fi_calculate_half` mit R1–R10, Hinweisen R11–R14 (US-FI-01 bis -05)
- [ ] T4: Migration Lesefunktionen `fi_list_settlements`, `fi_get_settlement`, `fi_settlement_document` (US-FI-06, -10)
- [ ] T5: Migration Schreibfunktionen Korrektur, Ausnahme, Bestätigung, Vertretung, Abschluss, Rücknahme, Abgabe, Verfall (US-FI-07 bis -12)
- [ ] T6: Migration Auszahlungsrunden: anlegen, Auswahl, Vorschau, verwerfen, freigeben, `fi_payout_export`, `fi_list_payout_runs` (US-FI-14 bis -16)
- [ ] T7: Migration Abgleich Punktekonto `fi_climbing_report`, `fi_save_climbing_check`, `fi_list_climbing_checks` (US-FI-17)
- [ ] T8: Fehlercodes in contracts/error-codes.md; Modul FI `is_available` mit der Freigabe
- [ ] T9: pgTAP: Struktur, RLS, Sichtbarkeit (Tabelle Abschnitt 9), Berechnung je Regel, Zustände, Sperre, Runden, Mengentest
- [ ] T10: Seed `seed-fi.sql` (Abschnitt 9), `seed.sh` mit `SEED_WITH_FI`
- [ ] T11: Frontend /fi Liste mit Filtern, Mehrfachaktionen (US-FI-01, -05, -06, -08, -10, -12)
- [ ] T12: Frontend /fi/abrechnung/:id mit Dialogen (US-FI-02 bis -12)
- [ ] T13: Frontend Abrechnungsdokument (PDF) (US-FI-10)
- [ ] T14: Frontend /fi/auszahlungen und /fi/auszahlungen/:id; Auszahlliste (PDF) und Überweisungsdatei (XML) mit Schema-Test (US-FI-14 bis -16)
- [ ] T15: Frontend /fi/kletterhalle (US-FI-17)
- [ ] T16: abnahme-test.md und Abnahme in TEST

## 11. Annahmen und offene Punkte

Entscheidungen des Product Owners: siehe 00-steckbrief.md (24.–26.10.2026) und 01-erhebung.md.

Annahmen (sichtbar, Bestätigung bei Freigabe oder Abnahme):
- Namen der Objekte anderer Module: spec.md AD v0.10 und spec.md EZ v0.6.
- [ANNAHME] Begriff „abschließen“; Wortlaut der Erklärung auf dem Abrechnungsdokument.
- [ANNAHME] Organisationspauschale auch ohne eigene Anwesenheit der organisierenden Person; zusätzlich zum Tagessatz; Halbtage zählen als Tag.
- [ANNAHME] Satzstand am Datum bzw. Startdatum; Halbjahr nach Startdatum.
- [ANNAHME] Höchstbetrag: Auszahlungsjahr bei nicht ausgezahlten Abrechnungen = Jahr des Endes der Abgabefrist.
- [ANNAHME] Bestätigung steuerfreie Einnahmen ohne Jahr gilt.
- [ANNAHME] Trainervereinbarung gilt auch für Helfer:innen.
- [ANNAHME] Referent:innen können ihre Bestätigung nicht selbst zurücknehmen.
- [ANNAHME] Erzeugung von PDF und XML im Browser; keine Speicherung; Aufbau der IDs; Dateinamen.
- [ANNAHME] Ausführungsdatum Standard nächster Werktag ohne Feiertage.
- [ANNAHME] Seed als eigene Datei mit `SEED_WITH_FI`; neue Testzugänge Lea Leistung und Gerd Geschäftsstelle; neue Gruppe Leistungsgruppe Test.
- [ANNAHME] Mengengerüst und Antwortzeiten.

Offen für Iteration 1 (kein Blocker): Storno einer Runde; Probetrainings Kletterhalle; Sonderfälle; Kurs und Tour; Reisekosten.

## 12. Nachtrag v0.3: Buchungslauf Verträge (Ready, 26.10.2026)

Grundlage: 01-erhebung.md v0.7.1 Abschnitt H (R34–R47, C8–C11), 02-stories.md v0.2.1 (US-FI-18 bis US-FI-21), Übergaben FI → AD v1.4 (A11, A13), FI → GR v1.0 (G1–G4). Voraussetzung: Nachtrag AD v0.11 und GR v0.4 (gleiche Migration-Reihe).

### 12.1 Datenmodell

Typen: `fi_collection_status` (`draft`, `released`), `fi_sequence` (`FRST`, `RCUR`).

**fi_collection_runs (Buchungslauf)**

| Spalte | Typ | Pflicht | Beschreibung |
|---|---|---|---|
| id | uuid | ja | PK |
| month | date | ja | 1. des Monats (Check) |
| number | smallint | ja | je Monat ab 1, Zähler `fi_collection_counters (month, last_number)`, nicht wieder vergeben (R35) |
| status | fi_collection_status | ja | Default `draft` |
| due_date | date | ja | Fälligkeitstag (R39) |
| msg_id, pmt_inf_id_frst, pmt_inf_id_rcur | text | bei Freigabe | R40 |
| line_count, total, total_frst, total_rcur | integer, numeric(12,2) | bei Freigabe | |
| released_at / released_by / released_by_person_id | | bei Freigabe | |
| created_at / created_by | | ja | |

Unique `(month, number)`.

**fi_collections (Einzug)**

| Spalte | Typ | Pflicht | Beschreibung |
|---|---|---|---|
| id | uuid | ja | PK |
| run_id | uuid | ja | FK fi_collection_runs on delete cascade |
| contract_id | uuid | ja | FK gr_contracts on delete restrict |
| month | date | ja | = Monat des Laufs |
| included | boolean | ja | Default true; abgewählt = false (bleibt im Entwurf sichtbar) |
| excluded_reason | text | nein | `mandate_not_signed` (R37); dann `included = false`, nicht wählbar |
| monthly_amount | numeric(10,2) | ja | > 0, Stand Erstellen/Aktualisieren (R34) |
| extra_amount, extra_text, extra_reason | numeric(10,2), text, text | nein | R47; alle drei oder keins (Check) |
| amount | numeric(10,2) | ja | generiert: monthly_amount + coalesce(extra_amount, 0) |
| sequence | fi_sequence | ja | R38 |
| group_id, group_label, participant_person_id, holder_person_id | | ja | aus G1 |
| mandate_reference, mandate_signed_on | text, date | ja | aus G1 |
| remittance, end_to_end_id, sort_no | text, text, integer | bei Freigabe | R40, R42 |
| bank_check | text | ja | Prüfwert aus G2 (R43) |

Unique `(contract_id, month) where included` (R35). Keine IBAN, kein Kontoinhaber. Beim Freigeben werden nicht enthaltene Zeilen gelöscht.

### 12.2 Funktionen (security definer, `set search_path = ''`, nur `fi_can_manage()`, sonst `FI_FORBIDDEN`)

- `fi_default_due_date(p_today date default current_date) returns date` – heute + 3 Tage, Samstag/Sonntag → Montag (R39).
- `fi_create_collection_run(p_month date, p_due_date date default null) returns uuid` – Monat = 1. des Monats, nicht vor dem aktuellen Monat und nicht vor `ad_collection_start()` (`FI_COLLECTION_MONTH`); Fälligkeitstag nach R39 (`FI_DUE_DATE`); legt den Lauf mit nächster Nummer an und übernimmt alle Verträge aus `gr_contracts_for_collection(p_month)`, die im Monat noch keinen enthaltenen Einzug haben (R34, R35), mit Sequenz nach R38 und Ausschluss nach R37.
- `fi_refresh_collection_run(p_run uuid)` – nur Entwurf (`FI_STATUS`): aktualisiert Beträge, Mandatsangaben, Gruppe und Sequenz, entfernt nicht mehr aktive Verträge, ergänzt neue; Abwahl und Zusatzbeträge bleiben.
- `fi_update_collection_run(p_run uuid, p_due_date date)` – nur Entwurf; R39; Ausschluss R37 neu bewerten.
- `fi_set_collection_included(p_collection uuid, p_included boolean)` – nur Entwurf; ausgeschlossene Zeile → `FI_COLLECTION_EXCLUDED`; Vertrag im Monat schon in anderem Lauf enthalten → `FI_COLLECTION_TAKEN`.
- `fi_set_collection_extra(p_collection uuid, p_amount numeric, p_text text, p_reason text)` – nur Entwurf; `p_amount` null entfernt; sonst Betrag > 0 mit höchstens 2 Nachkommastellen (`FI_AMOUNT_INVALID`), Text 1–60 und Begründung 1–500 Zeichen (`FI_EXTRA_REQUIRED`) (R47).
- `fi_discard_collection_run(p_run uuid)` – nur Entwurf; löscht den Lauf mit seinen Zeilen.
- `fi_release_collection_run(p_run uuid) returns uuid` – nur Entwurf; mindestens ein enthaltener Einzug (`FI_COLLECTION_EMPTY`); Angaben der Sektion mit Gläubiger-ID am Fälligkeitstag (`FI_COLLECTION_SETTINGS_MISSING`); R39 (`FI_DUE_DATE`); jeder enthaltene Vertrag weiter aktiv und Betrag, Mandat unverändert (`FI_COLLECTION_CHANGED`, Detail Name); Sequenz neu nach R38; vergibt IDs (R40), Verwendungszweck (R42), Reihenfolge (Gruppe natürlich, Nachname, Vorname); löscht nicht enthaltene Zeilen; setzt `released`.
- `fi_list_collection_runs() returns setof (id, month, number, status, due_date, line_count, total, included_count, included_total, released_at, released_by_name)`.
- `fi_get_collection_run(p_run uuid) returns jsonb` – Kopf, Zeilen mit Namen (Teilnehmer:in, Vertragsinhaber:in), Gruppe, Beträge, Sequenz, Ausschluss, `iban_last4`, Hinweis `bank_changed_since_last` (R44), Summen je Gruppe; `FI_NOT_FOUND`.
- `fi_collection_export(p_run uuid) returns jsonb` – nur `released` (`FI_STATUS`): Kopf, Angaben der Sektion (`ad_payout_settings_at(due_date)` mit Gläubiger-ID und Sachkonto der Gruppenbeiträge), je Einzug Kontoinhaber:in und IBAN aus `gr_contracts_for_collection(null, ids)`, Kennzeichen `bank_changed` (R43). Das Frontend erzeugt daraus Lastschriftdatei und Einzugsliste.

Grants nur an `authenticated`; Tabellen nur `select` mit RLS `fi_can_manage()`; Schreiben nur über die Funktionen.

### 12.3 Fehlercodes (Ergänzung contracts/error-codes.md)

| Code | Meldung |
|---|---|
| `FI_COLLECTION_MONTH` | Für diesen Monat ist kein Buchungslauf möglich. |
| `FI_DUE_DATE` | Der Fälligkeitstag muss mindestens einen Bankarbeitstag in der Zukunft liegen. |
| `FI_COLLECTION_EMPTY` | Der Buchungslauf enthält keine Lastschriften. |
| `FI_COLLECTION_SETTINGS_MISSING` | Die Angaben der Sektion für den Einzug fehlen. Bitte den Admin informieren. |
| `FI_COLLECTION_TAKEN` | Dieser Vertrag ist in diesem Monat bereits in einem anderen Buchungslauf. |
| `FI_COLLECTION_EXCLUDED` | Diese Lastschrift kann nicht gewählt werden (Mandat noch nicht unterschrieben). |
| `FI_COLLECTION_CHANGED` (Detail: Name) | Verträge haben sich seit dem Erstellen geändert. Bitte den Buchungslauf aktualisieren. |
| `FI_EXTRA_REQUIRED` | Bitte Text und Begründung angeben. |
| `FI_AMOUNT_INVALID` | Bitte einen gültigen Betrag eingeben. |

### 12.4 Oberfläche

| Route | Zeigt | Aktionen |
|---|---|---|
| /fi/einzug | Buchungsläufe (Monat, Lauf, Fälligkeitstag, Zustand, Anzahl, Summe, freigegeben am/von) | Neuer Buchungslauf (Monat, Fälligkeitstag vorbelegt); Dateien erneut abrufen (Warnung) |
| /fi/einzug/:id | Entwurf: Fälligkeitstag, Lastschriften je Gruppe (Teilnehmer:in, Vertragsinhaber:in, Mandatsreferenz, IBAN gekürzt, Sequenz, Betrag, Zusatz), ausgeschlossene, Summen; freigegeben: Zeilen und IDs | Entwurf: abwählen/wählen, Zusatzbetrag (Dialog), Fälligkeitstag ändern, aktualisieren, verwerfen, freigeben (Rückfrage R45-Text) → Download `Lastschriften_Vertraege_{JJJJ}_{MM}_Lauf{n}.xml`, `Einzugsliste_Vertraege_{JJJJ}_{MM}_Lauf{n}.pdf`; freigegeben: erneut abrufen |

Navigation Finanzen: „Buchungsläufe“ nur mit „FI verwalten“. Lastschriftdatei nach C11 mit Test gegen das XSD pain.008.001.02 (wie FT14).

### 12.5 Tasks

- FT17 Migration AD v0.11 (A11, A13) – siehe spec.md AD
- FT18 Migration GR v0.4 (G1, G2) – siehe spec.md GR
- FT19 Migration FI Buchungslauf (12.1, 12.2)
- FT20 pgTAP: Auswahl (R34), Nachtrag (R35), Sequenz (R38), Fälligkeit (R39), Ausschluss (R37), Zusatzbetrag (R47), Freigabe mit IDs und Verwendungszweck (R40, R42), Rechte, keine IBAN in `fi_`-Tabellen
- FT21 Seed: Gläubiger-ID (Test-ID `DE98ZZZ09999999999`), Sachkonto, Stichtag
- FT22 Oberfläche Administration (Gläubiger-ID, Sachkonto der Gruppenbeiträge, Stichtag)
- FT23 Oberfläche /fi/einzug, /fi/einzug/:id
- FT24 Lastschriftdatei (pain.008.001.02) mit Test, Einzugsliste (PDF)
- FT25 Abnahme in TEST
