# Spec: Dashboard (DS) mit Bereich Budget (FI)

Version: 0.2 · Status: Ready (freigegeben 26.10.2026) · Stand: 26.10.2026 · Product Owner: Toni Werner
Stories: docs/specs/ds-dashboard/02-stories.md (US-DS-07 bis US-DS-20, v0.2) und docs/specs/fi-finanzen/02-stories.md (Nachtrag v0.3, US-FI-22 bis US-FI-29)
Grundlage: 00-steckbrief.md v0.13, 01-erhebung.md v0.2 (Regeln R1–R24), 02-stories.md v0.2 (R25, R26), sichten.md v0.8, prototyp-budget-dashboard.md v1.0, uebergabe-administration.md v1.4 (D1–D10), uebergabe-finanzen.md v1.8 (B1–B17), glossar.md v1.7; bestehende Migrationen AD (`ad_has_level`, `ad_has_any_level`, `ad_my_referate`, `ad_template_rights.can_approve`) und FI (`fi_payout_runs`, `fi_payout_lines`).
Änderungen v0.2: Status Ready (Product Owner 26.10.2026); Annahmen in Abschnitt 11 bestätigt.
Änderungen v0.1: Erster Entwurf für den MVP (Budget-Sicht, Budgetpflege, Pflege durch Referent:innen, Zu tun im MVP-Umfang).

Regelverweise: „R…“ = 01-erhebung.md DS; „DS R25/R26“ = 02-stories.md DS.

**Voraussetzungen der Umsetzung:** (1) Nachtrag der Administration nach uebergabe-administration.md v1.4 (Modul DS, Reichweite „Referat“ für DS, Kennzeichen „darf Budget pflegen“, Vorlage „Budgetpflege“, neue Referate, Startseite) – in dieser Spec als Tasks T1–T4 beschrieben, weil die Administration keinen eigenen Nachtrag dafür hat [ANNAHME: Umsetzung im selben Branch, spec.md AD erhält den Verweis]; (2) Finanzen MVP (Auszahlungsrunden) ist umgesetzt.

## 1. Ziel und Scope

**Ziel:** Referent:innen, Vorstand, Geschäftsstelle und Admin sehen den Stand des Budgets im Vereins OS statt im Offline-Prototyp; jede Referent:in sieht das gesamte Budget als Summen und pflegt ihr eigenes (Hinweise, Umschichtungen, Vorschläge); der 1. Vorsitzende und die Schatzmeister:in pflegen Finanzplan, Zuordnung und DATEV-Import. Die Zahlen sind identisch mit dem Prototyp (`build.py`).

**Im Scope (MVP):**
- Bereich Budget in Finanzen: Finanzplan einlesen, Gesamtbudgets und Referate, Zuordnungsregeln mit Historie, Übernahme der `zuordnung.csv`, DATEV-Import mit Prüfung, Umschlüsseln, Löschlauf, neues Budgetjahr (US-FI-22 bis US-FI-29).
- Dashboard: Budget meines Referats, Budget des Vereins, Einzelbuchungen, Vorjahr, Hinweise, Umschichtung, Umschlüsselungs-Vorschlag, Vorschau abgerechneter Vergütung, Zu tun (MVP), Prüfung, Druckansicht, Startseite (US-DS-07 bis US-DS-20).
- Administration: Modul DS, Kennzeichen „darf Budget pflegen“, Vorlage „Budgetpflege“, Referate Öffentlichkeitsarbeit und Umwelt und Naturschutz.

**Nicht im Scope:** Referats-Kennzahlen aus GR, EZ, EA, TK und Gruppendetail (Iteration 1, sichten.md Abschnitte 4–5); DATEV-Schnittstelle (Schnittstellen-Connector); Planen des Finanzplans im Vereins OS; Buchen; Daten aus Buchungsläufen als Beträge (Regel „eine Quelle für Geld“).

**Verarbeitung der Dateien (Entscheidung dieser Spec):** Excel und DATEV-CSV werden **im Browser** gelesen (wie im Prototyp; keine Datei wird gespeichert, keine Edge Function, keine Kosten); der Browser schickt die erkannten Zeilen als JSON an eine Datenbankfunktion. **Alle fachlichen Regeln** (Zuordnung, Vorzeichen, Ausschlüsse, Prüfungen) laufen **in der Datenbank**, damit es nur eine Rechenlogik gibt (R1–R11). Das Lesen der Excel braucht eine Bibliothek im Frontend [ANNAHME: Auswahl in plan.md, z. B. `read-excel-file`, Lizenz und Größe prüfen].

## 2. Datenmodell

Alle Tabellen im Schema `public`, Präfix `fi_budget_`, RLS auf jeder Tabelle, Grants nur an `authenticated`, Schreiben nur über Funktionen (Abschnitt 2.3). Beträge `numeric(12,2)` in Euro (Prototyp: Cent; Umrechnung beim Lesen) [ANNAHME: wie fi_payout_runs].

### 2.1 Typen

- `fi_budget_kind`: `income`, `expense` (Oberfläche: Einnahme, Ausgabe)
- `fi_budget_visibility`: `referat`, `all`, `none` (Referat, alle, ohne Referat)
- `fi_budget_rule_type`: `booking`, `account`, `main_account`, `range` (Einzelbuchung, Konto, Hauptkonto, Kontenbereich)
- `fi_budget_rule_status`: `ok`, `uncertain`, `open`, `no_booking` (ok, unsicher, offen, keine Buchung)
- `fi_budget_realloc_status`: `requested`, `withdrawn`, `confirmed`, `rejected`
- `fi_budget_proposal_status`: `proposed`, `withdrawn`, `accepted`, `rejected`, `obsolete`

### 2.2 Tabellen

#### fi_budget_plans (Finanzplan je Jahr)
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| year | smallint | ja | – | PK; 2026–2100 |
| source_file | text | ja | – | Dateiname der Excel |
| sheet | text | ja | – | „Finanzplan 2027“ |
| sum_income, sum_expense | numeric(12,2) | nein | – | Summenzeilen der Excel |
| imported_at | timestamptz | ja | now() | |
| imported_by | uuid | ja | auth.uid() | |

#### fi_budget_groups (Gesamtbudget)
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| year | smallint | ja | – | FK fi_budget_plans |
| name | text | ja | – | 1–80 Zeichen; unique (year, name) |
| visibility | fi_budget_visibility | ja | 'none' | R22 |
| referat_id | uuid | nein | – | FK ea_referate; Pflicht genau dann, wenn visibility = 'referat' (Check) |
| sort_order | int | ja | – | Reihenfolge wie Excel |

#### fi_budget_items (Budgetposten)
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| year | smallint | ja | – | |
| group_id | uuid | ja | – | FK fi_budget_groups (gleiches Jahr, Trigger) |
| kind | fi_budget_kind | ja | – | |
| name | text | ja | – | genau wie Excel; unique (year, kind, group_id, name) |
| plan_decided | numeric(12,2) | nein | – | beschlossener Plan; null = „kein Plan“ |
| excel_row | int | nein | – | |
| sort_order | int | ja | – | |
| no_booking | boolean | ja | false | „keine Buchung“ (z. B. Auflösung Rücklagen) |
| removed_at | timestamptz | nein | – | beim erneuten Einlesen entfallen (bleibt für Verweise; nicht angezeigt) |

Aktueller Plan = `plan_decided` + Summe bestätigter Umschichtungen hinein − hinaus (View 2.4).

#### fi_budget_rules (Zuordnungsregel, mit Historie)
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| year | smallint | ja | – | |
| rule_type | fi_budget_rule_type | ja | – | |
| account_text | text | ja | – | Eingabe wie im Prototyp („6326 3“, „6326“, „4000-7999“) |
| main_account | int | nein | – | bei account, main_account, booking |
| sub_account | smallint | nein | – | bei account, booking |
| range_from, range_to | int | nein | – | bei range; `range_full` = mit Unterkonto (Hauptkonto×10+Unterkonto) |
| range_full | boolean | nein | – | |
| cost_centers | text[] | ja | '{}' | KOST1; leer = alle |
| item_id | uuid | nein | – | FK fi_budget_items; null = bewusst „nicht zugeordnet“ |
| status | fi_budget_rule_status | ja | 'ok' | |
| note | text | nein | – | Hinweis der Budgetpflege |
| account_label | text | nein | – | Kontobezeichnung, nur Info |
| b_date, b_receipt, b_amount, b_side, b_text | date, text, numeric, char(1), text | nein | – | nur bei booking (Einzelbuchung); b_side 'S'/'H' |
| reason | text | nein | – | Grund (Pflicht bei booking, A2) |
| valid_from | timestamptz | ja | now() | |
| valid_to | timestamptz | nein | – | null = gültig |
| created_by | uuid | ja | auth.uid() | |
| comment | text | nein | – | Kommentar der Änderung (R24) |

Eindeutig (R11): partieller Unique-Index auf (year, rule_type, main_account, sub_account, range_from, range_to, cost_centers, b_date, lower(b_receipt), b_amount, b_side, lower(b_text)) `where valid_to is null`. Ändern = alte Zeile `valid_to = now()`, neue Zeile (Historie).

#### fi_budget_imports (DATEV-Import)
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| year | smallint | ja | – | |
| file_name | text | ja | – | |
| export_info | text | nein | – | Zeile 1 (Mandant, Exportzeit), ohne Personendaten |
| data_until | date | nein | – | Datenstand = letzte Buchung (R7) |
| rows_read, rows_saved, rows_ignored, rows_opening, rows_other_year | int | ja | – | R4 |
| checks | jsonb | ja | '[]' | je Konto: Kontenübersicht, Summe Einzelbuchungen, ok |
| warnings | jsonb | ja | '[]' | R8, R9 |
| is_current | boolean | ja | true | genau ein aktueller Import je Jahr (partieller Unique-Index) |
| imported_at, imported_by | timestamptz, uuid | ja | now(), auth.uid() | |

#### fi_budget_bookings (Buchung)
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| import_id | uuid | ja | – | FK fi_budget_imports on delete cascade |
| year | smallint | ja | – | |
| main_account, sub_account | int, smallint | ja | – | „6326 3“ → 6326, 3 |
| booking_date | date | ja | – | |
| bu | text | nein | – | |
| contra_account, contra_label | text | nein | – | |
| booking_text | text | nein | – | kann Namen enthalten (F) |
| receipt | text | nein | – | Belegfeld 1 |
| debit, credit | numeric(12,2) | ja | 0 | Umsatz Soll / Haben |
| cost_center | text | nein | – | KOST1 |
| line_no | int | ja | – | Zeile in der Datei |

Nur Zeilen, deren Konto eine gültige Regel trifft (R1); Index (year, main_account, sub_account).

#### fi_budget_account_totals (Kontenübersicht des Imports, für die Prüfung)
import_id, main_account, sub_account, opening, debit, credit (Summen aus dem Export; PK import_id + Konto).

#### fi_budget_month_totals (Kontensumme je Monat)
year, month, main_account, sub_account, cost_center, debit, credit; PK (year, month, main_account, sub_account, cost_center). Beim Import des Jahres ersetzt; bleibt nach dem Löschlauf (R19).

#### fi_budget_reallocations (Umschichtung)
id, year, from_item, to_item (FK fi_budget_items), amount (> 0), reason (1–500), status (fi_budget_realloc_status, Default 'requested'), requested_by, requested_by_person_id, requested_at, decided_by, decided_by_person_id, decided_at, decision_reason. Check `from_item <> to_item`.

#### fi_budget_proposals (Umschlüsselungs-Vorschlag)
id, year, booking_id (FK fi_budget_bookings on delete set null), b_date, b_main_account, b_sub_account, b_receipt, b_amount, b_side, b_text (Merkmale zur Wiedererkennung nach neuem Import), from_item, to_item, reason, status (Default 'proposed'), proposed_by, proposed_by_person_id, proposed_at, decided_by, decided_at, decision_reason, rule_id (angelegte Regel). Partieller Unique-Index: je Buchungsmerkmal höchstens ein `proposed` (R16).

#### fi_budget_notes (Hinweis je Budgetposten, mit Historie)
id, item_id, text (1–500), created_by, created_by_person_id, created_at, valid_to (null = aktuell; partieller Unique-Index item_id where valid_to is null).

#### fi_budget_payout_marks (Auszahlungsrunde von Hand als gebucht markiert)
run_id (PK, FK fi_payout_runs), marked_by, marked_at. Ergänzt den automatischen Abgleich (R18).

#### fi_budget_log (Protokoll, R24)
id, year, action (text: plan_import, group_set, rule_save, rule_end, rules_csv_import, booking_import, rekey, rekey_undo, note, realloc_request, realloc_withdraw, realloc_confirm, realloc_reject, proposal_create, proposal_withdraw, proposal_accept, proposal_reject, payout_mark, purge), object_id, details jsonb (ohne Buchungstexte), actor, actor_person_id, at. Löschung nach 5 Jahren.

### 2.3 Funktionen (security definer, `set search_path = ''`, Grants nur an `authenticated`)

**Rechte (Administration, Tasks T1–T2):**
- `ad_has_budget_maintain() returns boolean` – Zuweisung mit Recht DS (Stufe ≥ read, Reichweite „alle“) und `can_maintain_budget = true` an einem aktiven Zugang.
- `fi_budget_can_read() returns boolean` – `ad_has_any_level('DS','read')`.
- `fi_budget_scope_all() returns boolean` – `ad_has_level('DS','read')` (Reichweite „alle“) oder `ad_has_budget_maintain()`.
- `fi_budget_group_mine(p_group uuid) returns boolean` – visibility = 'referat' und referat_id = any(`ad_my_referate('DS','read')`).
- `fi_budget_can_see_bookings(p_item uuid) returns boolean` – `fi_budget_scope_all()` oder Gesamtbudget visibility = 'all' oder `fi_budget_group_mine` (R13).
- `fi_budget_can_edit_item(p_item uuid) returns boolean` – `ad_has_budget_maintain()` oder `fi_budget_group_mine` (R15–R17).

**Rechnen (intern, kein Grant):**
- `fi_budget_match(p_booking fi_budget_bookings) returns uuid` – gültige Regel nach Vorrang R2 (Einzelbuchung → Konto → Hauptkonto → engster Bereich; mit Kostenstelle vor ohne); Rückgabe Regel-ID.
- `fi_budget_amount(p_kind, p_debit, p_credit) returns numeric` – R3.

**Finanzplan und Gesamtbudgets (nur `ad_has_budget_maintain()`, sonst `FI_BUDGET_FORBIDDEN`):**
- `fi_budget_plan_preview(p_year smallint, p_source jsonb) returns jsonb` – p_source = {file, sheet, items:[{kind, name, plan, row}], sums:{income, expense}} aus dem Browser; prüft R10, ordnet doppelte Namen dem Gesamtbudget darüber zu (Gesamtbudget je Posten aus vorhandener Zuordnung bzw. Vorjahr, sonst Postenname), liefert neue / entfallene / geänderte Posten und betroffene Umschichtungen.
- `fi_budget_plan_import(p_year, p_source) returns jsonb` – wie Preview, schreibt; bei R10-Verstoß `FI_BUDGET_SUM_MISMATCH`.
- `fi_budget_year_from_previous(p_year) returns jsonb` – Vorschlag Gesamtbudgets, Sichtbarkeit, Regeln aus p_year − 1 (ohne Einzelbuchungsregeln; US-FI-29); schreibt erst nach Bestätigung (`p_apply boolean`).
- `fi_budget_group_set(p_group uuid, p_visibility fi_budget_visibility, p_referat uuid)` – `FI_BUDGET_REFERAT_REQUIRED`.

**Zuordnung:**
- `fi_budget_rule_parse(p_text text) returns jsonb` – Kontoangabe wie `regel_aus_konto`/`konto_teile` (build.py); `FI_BUDGET_ACCOUNT_INVALID`, `FI_BUDGET_RANGE_INVALID`. Grant an authenticated (für Prüfung beim Tippen).
- `fi_budget_rule_save(p_rule jsonb, p_comment text) returns uuid` – neu oder Ersatz (Historie); `FI_BUDGET_RULE_DUPLICATE`.
- `fi_budget_rule_end(p_rule uuid, p_comment text)`.
- `fi_budget_rules_import_csv(p_year smallint, p_rows jsonb) returns jsonb` – Zeilen der `zuordnung.csv` (Browser liest die CSV); Ergebnis und Fehler wie `lese_zuordnung` (US-FI-25); `FI_BUDGET_ITEM_UNKNOWN` je Zeile.

**Import:**
- `fi_budget_import_preview(p_year smallint, p_file jsonb) returns jsonb` – p_file = {name, info, overview:[{konto, eb, soll, haben}], rows:[{konto, datum, bu, gegenkonto, gegenkonto_label, text, beleg, soll, haben, kost1, line}]}; filtert R4, behält nur Zeilen mit Regel (R1), rechnet Prüfung R8, sucht Einzelbuchungsregeln (R9), liefert Ergebnis ohne zu schreiben.
- `fi_budget_import(p_year, p_file) returns uuid` – schreibt Import, Buchungen, Kontenübersicht, Monatssummen; setzt vorigen Import `is_current = false` und löscht dessen Buchungen (R9); markiert Vorschläge ohne wiedergefundene Buchung als `obsolete` [A5]. Fehler `FI_BUDGET_NO_ROWS` („Die Datei enthält keine Buchungsliste. Bitte die Kontenblätter aller Konten als CSV exportieren.“), `FI_BUDGET_NO_PLAN`.

**Umschlüsseln und Vorschläge:**
- `fi_budget_rekey(p_booking uuid, p_item uuid, p_scope text, p_reason text) returns uuid` – p_scope 'booking' (Einzelbuchungsregel) oder 'account' (Kontoregel ersetzen); nur Budgetpflege; `FI_BUDGET_REASON_REQUIRED`.
- `fi_budget_rekey_undo(p_rule uuid)` – Einzelbuchungsregel beenden.
- `fi_budget_proposal_create(p_booking uuid, p_to uuid, p_reason text) returns uuid` – Buchung muss nach `fi_budget_match` einem Posten mit `fi_budget_can_edit_item` gehören (R16); `FI_BUDGET_PROPOSAL_OPEN`, `FI_BUDGET_FORBIDDEN`.
- `fi_budget_proposal_withdraw(p_id)` – nur Vorschlagende:r, Zustand proposed.
- `fi_budget_proposal_decide(p_id uuid, p_accept boolean, p_scope text, p_reason text)` – Budgetpflege; annehmen ruft `fi_budget_rekey`; ablehnen mit Grund.

**Hinweise und Umschichtungen:**
- `fi_budget_note_save(p_item uuid, p_text text)` – `fi_budget_can_edit_item`; leerer Text beendet den Hinweis; `FI_BUDGET_NOTE_TOO_LONG`.
- `fi_budget_realloc_request(p_from uuid, p_to uuid, p_amount numeric, p_reason text) returns uuid` – R15; `FI_BUDGET_REALLOC_GROUP` („Umschichten geht nur zwischen Posten desselben Gesamtbudgets und derselben Art.“), `FI_BUDGET_REALLOC_AMOUNT` („Der Betrag ist höher als der Plan von ‚…‘.“). Budgetpflege mit `p_direct = true` [ANNAHME] → sofort confirmed.
- `fi_budget_realloc_withdraw(p_id)`.
- `fi_budget_realloc_decide(p_id uuid, p_confirm boolean, p_reason text)` – Budgetpflege, nicht eigener Antrag (`FI_BUDGET_OWN_REQUEST`); prüft R15 erneut (`FI_BUDGET_REALLOC_STALE`).
- `fi_budget_payout_mark(p_run uuid, p_booked boolean)` – Budgetpflege; Fallback für R18.

**Lesen für das Dashboard (Grant an authenticated, Prüfung `fi_budget_can_read()`, sonst leere Menge):**
- `ds_budget_years() returns setof smallint` – Jahre mit Finanzplan (laufendes und Vorjahr).
- `ds_budget_overview(p_year smallint) returns table(...)` – je Budgetposten: Gesamtbudget, visibility, referat_id, kind, name, plan_decided, plan_current, actual, actual_prev_same_day, actual_prev_full, pct, ampel, note, note_by, note_at, can_see_bookings, can_edit, open_reallocations, open_proposals, preview (nur Posten „Vergütung Aktive“, R18), status_uncertain (Regel unsicher/offen); für **alle** mit DS lesen (R12).
- `ds_budget_head(p_year) returns jsonb` – Summen Verein (Plan, verbraucht, frei, Einnahmen erreicht / fehlt noch), Datenstand, Jahresfortschritt, Datenstand-Warnung (R23).
- `ds_budget_bookings(p_item uuid) returns table(booking_date, account, booking_text, receipt, amount, rekeyed, rekey_info, proposal_open)` – nur bei `fi_budget_can_see_bookings`, sonst `FI_BUDGET_FORBIDDEN`.
- `ds_budget_account_sums(p_item uuid)` – Summe je Konto des Postens (gleiche Prüfung).
- `ds_budget_unassigned(p_year)` – nicht zugeordnete Buchungen; nur `fi_budget_scope_all()` (R14).
- `ds_budget_checks(p_year)` – Prüfergebnis des aktuellen Imports, umgeschlüsselte Buchungen; nur `fi_budget_scope_all()`.
- `ds_budget_requests(p_year)` – Umschichtungen und Vorschläge: eigene (alle) und, mit Budgetpflege, alle offenen.
- `ds_todo()` – Punkte für Block ① (US-DS-17): eigene Anträge/Vorschläge mit Zustand; Abrechnungen zur Bestätigung (Abrechnungen im Zustand Entwurf mit offener Bestätigung eines Referats aus `fi_confirm_referate()`, Frist aus `ad_settlement_deadline`); für Budgetpflege offene Anträge, nicht zugeordnete Buchungen (Anzahl), unsichere Regeln (Anzahl), Datenstand > 42 Tage, Löschlauf fehlgeschlagen.

**Löschlauf (pg_cron, täglich 03:15, nur intern):**
- `fi_budget_purge()` – löscht am oder nach dem 01.01. des Jahres J+2 Buchungen, Kontenübersichten, Einzelbuchungsregeln und Vorschläge des Jahres J; protokolliert Anzahl (R19); Fehler → Eintrag `purge_failed` im Protokoll, erscheint in `ds_todo()`.

### 2.4 Views (security_invoker)

- `fi_budget_items_current` – Posten mit plan_current (Umschichtungen confirmed).
- `fi_budget_bookings_assigned` – Buchung + `fi_budget_match` → Regel, Posten, Betrag nach R3 mit Art des Postens; Grundlage aller Summen (nur intern genutzt durch die `ds_`-Funktionen, kein Grant) [ANNAHME: Leistung reicht bei ca. 1.300 Zeilen je Jahr; sonst gespeicherte Zuordnung mit Neuberechnung nach Regeländerung].

### 2.5 Beziehungen und Indizes

fi_budget_plans 1–n groups 1–n items; items 1–n rules (item_id), notes, reallocations (from/to), proposals (from/to); imports 1–n bookings, account_totals. Indizes: bookings (year, main_account, sub_account), bookings (import_id), rules (year) where valid_to is null, reallocations (status) where status = 'requested', proposals (status) where status = 'proposed'.

## 3. Rechte / RLS

Grundsatz: Tabellen ohne direkten Lesezugriff für Referent:innen auf Buchungen; Lesen über die `ds_`-Funktionen (security definer, Prüfung wie unten). RLS-Policies für direkten Zugriff nur `fi_budget_scope_all()` (lesen) – Schreiben ausschließlich über Funktionen.

| Rechtevorlage (Startwert) | Summen aller Gesamtbudgets | Einzelbuchungen | nicht zugeordnet, Prüfung | Hinweis | Umschichtung beantragen | Umschlüsselung vorschlagen | Pflege (Plan einlesen, Zuordnung, Import, umschlüsseln, entscheiden) |
|---|---|---|---|---|---|---|---|
| Referent:in (DS lesen, Referat) | ja | eigene Gesamtbudgets und „alle“ | – | eigene | eigene | eigene | – |
| Vorstand (DS lesen, alle) | ja | alle | ja | – | – | – | – |
| Geschäftsstelle (DS lesen, alle) | ja | alle | ja | – | – | – | – |
| Admin, Notfall-Admin (DS lesen, alle) | ja | alle | ja | – | – | – | – |
| Budgetpflege (DS lesen alle + „darf Budget pflegen“): 1. Vorsitzender, Schatzmeister:in | ja | alle | ja | alle | alle (direkt) | – | ja; eigene Anträge entscheidet die andere Person |
| ohne DS | – | – | – | – | – | – | – |

| Tabelle | Lesen (RLS) | Schreiben |
|---|---|---|
| fi_budget_plans, groups, items, notes | `fi_budget_can_read()` (keine Personendaten) | Funktionen |
| fi_budget_rules, imports, account_totals, month_totals, log | `fi_budget_scope_all()` | Funktionen |
| fi_budget_bookings | `fi_budget_scope_all()`; Referent:innen nur über `ds_budget_bookings` | Funktionen |
| fi_budget_reallocations, proposals | eigene Zeilen oder `fi_budget_scope_all()` | Funktionen |
| fi_budget_payout_marks | `fi_budget_scope_all()` | `fi_budget_payout_mark` |

Routenschutz: `/dashboard` ohne `ad_has_any_level('DS','read')` → /kein-zugriff; `/dashboard/budget/pflege*` nur mit `ad_has_budget_maintain()`.

## 4. Zustände und Übergänge

**Umschichtung**
| Von | Nach | Wer | Bedingung |
|---|---|---|---|
| – | requested | Referent:in (`fi_budget_group_mine`) | R15, Grund |
| – | confirmed | Budgetpflege (direkt) | R15 |
| requested | withdrawn | Antragsteller:in | – |
| requested | confirmed | Budgetpflege, nicht Antragsteller:in | R15 erneut erfüllt |
| requested | rejected | Budgetpflege | Grund |

**Umschlüsselungs-Vorschlag**
| Von | Nach | Wer | Bedingung |
|---|---|---|---|
| – | proposed | Referent:in | R16, Grund |
| proposed | withdrawn | Vorschlagende:r | – |
| proposed | accepted | Budgetpflege | legt Regel an (booking oder account) |
| proposed | rejected | Budgetpflege | Grund |
| proposed | obsolete | System (Import) | Buchung nicht wiedergefunden (A5) |

**Import:** neuer Import → `is_current = true`, vorheriger → false (Buchungen gelöscht, Kopfzeile bleibt im Protokoll). **Regel:** gültig (valid_to null) → beendet (valid_to gesetzt).

## 5. Geschäftsregeln

Es gelten R1–R24 aus 01-erhebung.md und DS R25, DS R26 aus 02-stories.md. Ergänzend für die Umsetzung:

- R1 Umsetzung: `fi_budget_import` speichert eine Zeile genau dann, wenn `fi_budget_match` eine gültige Regel findet (auch Regel ohne Posten = „nicht zugeordnet“). Zeilen ohne jede Regel zählen als „ignoriert“.
- R3 Umsetzung: Betrag = Soll − Haben bei Art `expense`, Haben − Soll bei `income`; „nicht zugeordnet“ als Soll − Haben.
- R6 Umsetzung: Ampel aus `actual / plan_current`; plan_current ≤ 0 oder null mit actual > 0 → ■ „ohne Budget“.
- R7: Jahresfortschritt = (data_until − 01.01. + 1) / Tage des Jahres.
- R8: Abweichung > 0,01 € je Konto → Warnung „Export unvollständig: Konto 6330 3 – Kontenübersicht 736,05 €, Einzelbuchungen 76,39 €“ (Beispielzahlen fiktiv).
- R18 Umsetzung: Eine freigegebene Auszahlungsrunde gilt als **gebucht**, wenn im aktuellen Import auf einem Konto, das einer Regel des Postens „Vergütung Aktive“ eines Gesamtbudgets zugeordnet ist, eine Buchung im Soll mit Betrag = Summe der Runde (oder = Summe der Zeilen des Referats in der Runde) und Datum zwischen Ausführungsdatum − 3 und + 14 Tagen steht, oder wenn die Budgetpflege sie von Hand markiert hat (`fi_budget_payout_marks`). Vorschau je Referat = Summe der `fi_payout_lines` (Referat über `referat_id` bzw. `gr_groups.referat_id`) nicht gebuchter, freigegebener Runden des Budgetjahres; zusätzlich abgeschlossene, noch nicht ausgezahlte Abrechnungen [ANNAHME: beides zählt zur Vorschau, getrennt ausgewiesen].
- R20 Umsetzung: actual_prev_same_day aus Buchungen des Vorjahres bis zum Tag/Monat von data_until; nach dem Löschlauf aus fi_budget_month_totals bis Ende des Vormonats [ANNAHME: Näherung, tritt erst nach J+2 ein und betrifft dann kein angezeigtes Vorjahr].
- Fehlercodes (Ergänzung contracts/error-codes.md bei der Umsetzung): `FI_BUDGET_FORBIDDEN` „Für diesen Bereich hast du keine Rechte.“ · `FI_BUDGET_SUM_MISMATCH` · `FI_BUDGET_SHEET_MISSING` „Kein Tabellenblatt ‚Finanzplan JJJJ‘ gefunden.“ (Browser) · `FI_BUDGET_ACCOUNT_INVALID` · `FI_BUDGET_RANGE_INVALID` · `FI_BUDGET_RULE_DUPLICATE` · `FI_BUDGET_ITEM_UNKNOWN` · `FI_BUDGET_REFERAT_REQUIRED` „Bitte ein Referat wählen.“ · `FI_BUDGET_NO_ROWS` · `FI_BUDGET_NO_PLAN` „Für JJJJ ist noch kein Finanzplan eingelesen.“ · `FI_BUDGET_REASON_REQUIRED` „Bitte einen Grund angeben.“ · `FI_BUDGET_NOTE_TOO_LONG` „Der Hinweis darf höchstens 500 Zeichen haben.“ · `FI_BUDGET_REALLOC_GROUP` · `FI_BUDGET_REALLOC_AMOUNT` · `FI_BUDGET_REALLOC_STALE` „Die Umschichtung passt nicht mehr zum Plan. Bitte ablehnen oder neu beantragen lassen.“ · `FI_BUDGET_OWN_REQUEST` „Deinen eigenen Antrag bestätigt eine andere Person mit Budgetpflege.“ · `FI_BUDGET_PROPOSAL_OPEN` „Zu dieser Buchung gibt es schon einen offenen Vorschlag.“

## 6. Screens und Interaktionen

| Route | Zeigt | Aktionen | Leer / Fehler | Stories |
|---|---|---|---|---|
| / (Startseite) | mit DS lesen: Dashboard (Sicht „Mein Referat“ bzw. „Verein“); sonst wie heute | – | – | US-DS-20 |
| /dashboard | Sichtwahl (Mein Referat / weitere Referate / Verein, je nach Reichweite), Jahr (laufend, Vorjahr); Block ① Zu tun; Block ② Budget meines Referats (Kacheln Plan aktuell/beschlossen, verbraucht mit Vorjahr, frei mit Vorschau, Verbrauch mit Ampel; Zeilen je Budgetposten mit Balken, Strich Jahresfortschritt, Vorschau schraffiert, Hinweis); Block ④ Budget des Vereins (zugeklappt, eigenes Referat hervorgehoben) | Hinweis eintragen, Umschichtung beantragen (Dialog: von, nach, Betrag, Grund), Einzelbuchungen öffnen, Drucken | DS R26 | US-DS-07, -08, -10, -11, -12, -16, -17, -19 |
| /dashboard/budget/posten/:id | Summe je Konto, Einzelbuchungen (sortier- und durchsuchbar), Etiketten „umgeschlüsselt“, „Vorschlag offen“; Hinweis-Verlauf; Umschichtungen des Postens | Umschlüsselung vorschlagen (Referent:in), umschlüsseln ⇄ (Budgetpflege) | ohne Recht nur Summen, Text „Einzelbuchungen siehst du nur für dein Referat.“ | US-DS-09, -14, US-FI-27 |
| /dashboard/verein | Sicht Verein: Kopf, Gesamtbudgets nach Ampel, nicht zugeordnete Buchungen, Prüfung | Drucken | – | US-DS-08, -18, -19 |
| /dashboard/budget/pflege | Budgetpflege: Reiter **Finanzplan** (Upload, Vorschau, übernehmen; neues Jahr), **Gesamtbudgets** (Sichtbarkeit, Referat), **Zuordnung** (Liste mit Filtern, anlegen, ändern, beenden, Verlauf; Übernahme `zuordnung.csv`), **Import** (Upload, Ergebnis, übernehmen; Liste der Importe), **Anträge** (Umschichtungen, Vorschläge: bestätigen/annehmen, ablehnen), **Protokoll** | wie links | Fehlermeldungen Abschnitt 5 | US-FI-22 bis -27, -29, US-DS-13, -15 |

Mobil ab 375 px: Kacheln untereinander, Zeilen als Karten, Tabellen mit seitlichem Scrollen; Pflege am Arbeitsplatz (mobil lesbar). Druck: A4 quer, Ampeln mit Form und Wort. Darstellung nach der Skizze „Dashboard Kinder und Jugend“ und DESIGN.md.

## 7. Schnittstellen

- Excel und DATEV-CSV: Upload im Browser, Lesen im Browser (Spalten über Namen, UTF-8 mit BOM oder Windows-1252, Zeile 1, Abschnitte Kontenübersicht und Buchungsliste wie prototyp-budget-dashboard.md Abschnitt 3), Übergabe als JSON an `fi_budget_plan_*` bzw. `fi_budget_import*`. Dateien werden nicht gespeichert.
- Finanzen: `fi_payout_runs`, `fi_payout_lines` (Vorschau, R18); Bestätigungen offener Abrechnungen für `ds_todo()`.
- Administration: `ad_has_level`, `ad_has_any_level`, `ad_my_referate` für DS; neues `ad_has_budget_maintain()`; Referate.
- Iteration 1: Lesefunktionen aus GR, EZ, EA, TK nach den Übergaben (nicht in dieser Spec).

## 8. Nicht-funktionale Anforderungen

- Gleiche Zahlen wie `build.py`/Prototyp für denselben Export (Abnahme mit fiktivem Export und Referenzwerten; echte Referenzwerte nur lokal durch den Product Owner).
- Budget-Sicht < 2 s, Import-Vorschau < 10 s bei 6.000 Zeilen [ANNAHME].
- Keine Kosten; keine Edge Function.
- Keine Buchungstexte in Protokoll, Fehlermeldungen oder Logs.
- Barrierefreiheit: Ampeln mit Form und Wort, Balken mit Text-Alternative, Tastaturbedienung aller Dialoge.

## 9. Testdaten (supabase/seed-ds.sql, nur TEST, nach den bestehenden Seeds)

Fiktiv, keine Echtdaten; Finanzplan „Finanzplan 2026“ und „Finanzplan 2027“ mit Gesamtbudgets wie im Steckbrief, Beträge erfunden.

| # | Datensatz | Zweck |
|---|---|---|
| 1 | Gesamtbudget „Kinder und Jugend“ (Referat Kinder und Jugend) mit „Kinder und Jugend Kosten“ (Plan 30.000 €), „Ausbildung KiJu“ (6.000 €), „Vergütung Aktive“ (12.000 €), Einnahme „Kinder und Jugend“ (9.000 €) | Sicht Referentin |
| 2 | Gesamtbudget „Leistungssport“ (Referat Leistungssport), mit zweitem „Vergütung Aktive“ | doppelter Name (R10) |
| 3 | „Veranstaltungen“ (alle), „Vereinszentrum“ (ohne Referat) | R13, R22 |
| 4 | Regeln: 4000-7999 ohne Posten, 6326 6 → Kinder und Jugend Kosten, 6326 (Hauptkonto) → Kinder und Jugend Kosten mit Kostenstelle 3, Einzelbuchung „Startgebühr Testcup“ | R2 |
| 5 | Import 2026 und 2027 (je ca. 60 Zeilen): Doppelbuchung über Bank und Sammelkonto, Storno, Umbuchung, EB-Wert, Buchung 2025, Konto mit fehlender Einzelbuchung | R1, R3, R4, R8, R9 |
| 6 | Umschichtung beantragt (500 € Kinder und Jugend Kosten → Ausbildung KiJu) durch Testzugang Referent:in Kinder und Jugend | US-DS-12, -13 |
| 7 | Vorschlag offen zu einer Buchung | US-DS-14, -15 |
| 8 | Auszahlungsrunde freigegeben, nicht gebucht (Vorschau) und eine gebucht | R18 |
| 9 | Testzugang „Budgetpflege“ (fiktiver 1. Vorsitzender) und „Schatzmeisterin Test“ mit Vorlage Budgetpflege | Vier-Augen-Prinzip |

## 10. Umsetzungs-Tasks

- [ ] T1: AD-Migration: Modul DS in `ad_modules`; R30-Check um DS; Spalte `can_maintain_budget` an `ad_template_rights` (nur DS, Reichweite alle, Stufe ≥ read; Guard wie can_approve); `ad_has_budget_maintain()`; Zeilen DS für alle Vorlagen (D1, D2, D4, D6)
- [ ] T2: AD-Migration: Startwerte DS (Admin, Geschäftsstelle, Vorstand alle; Referent:in Referat); Vorlage „Budgetpflege“; Referate Öffentlichkeitsarbeit, Umwelt und Naturschutz (D3, D6, D10); Oberfläche Rechtevorlagen: Kennzeichen „darf Budget pflegen“
- [ ] T3: pgTAP AD: Rechte DS, Kennzeichen-Guard, Startwerte, neue Referate
- [ ] T4: Startseite: Dashboard für Nutzer mit DS (D7, US-DS-20)
- [ ] T5: FI-Migration Budget: Typen, Tabellen 2.2, RLS, Grants, Indizes
- [ ] T6: FI-Migration Budget: `fi_budget_rule_parse`, `fi_budget_match`, Views 2.4 (R1–R3, R11)
- [ ] T7: Finanzplan: `fi_budget_plan_preview/_import`, `fi_budget_group_set`, `fi_budget_year_from_previous` (US-FI-22, -23, -29)
- [ ] T8: Zuordnung: `fi_budget_rule_save/_end`, `fi_budget_rules_import_csv` (US-FI-24, -25)
- [ ] T9: Import: `fi_budget_import_preview/_import`, Monatssummen, Prüfung (US-FI-26)
- [ ] T10: Umschlüsseln, Vorschläge, Hinweise, Umschichtungen, payout_mark (US-FI-27, US-DS-11 bis -15)
- [ ] T11: Lesefunktionen `ds_budget_*`, `ds_todo` inkl. Vorschau R18 (US-DS-07 bis -10, -16 bis -18)
- [ ] T12: Löschlauf `fi_budget_purge` mit pg_cron (US-FI-28)
- [ ] T13: pgTAP Budget: Rechenregeln gegen fiktiven Export mit Referenzsummen (alle Sonderfälle), Rechte je Vorlage (Referent:in sieht keine fremden Buchungen), Zustände, Fehlercodes, Löschlauf
- [ ] T14: Frontend: Lesen Excel und DATEV-CSV im Browser (Parser wie build.py/Prototyp; Unit-Tests mit fiktiven Dateien)
- [ ] T15: Frontend: /dashboard (Blöcke ①, ②, ④), Postendetail, Dialoge Hinweis/Umschichtung/Vorschlag, Vorschau, Druck
- [ ] T16: Frontend: /dashboard/verein, /dashboard/budget/pflege (Reiter)
- [ ] T17: Seed `seed-ds.sql` (Abschnitt 9) und Testzugänge
- [ ] T18: Anleitung: neuer Teil „Dashboard“ (Referent:innen, Budgetpflege), Screenshots, Ablaufbilder Umschichtung und Import (CLAUDE.md, neue Hauptversion)
- [ ] T19: abnahme-test.md: Vergleich mit Prototyp (fiktiver Export), Rechte, Vier-Augen-Prinzip

## 11. Annahmen und offene Punkte

- Bestätigt (Product Owner 26.10.2026): Verarbeitung der Dateien im Browser, Regeln in der Datenbank (Abschnitt 1).
- Bestätigt (Product Owner 26.10.2026): Beträge `numeric(12,2)`; Excel-Bibliothek nach plan.md.
- Bestätigt (Product Owner 26.10.2026): Zuordnung zur Laufzeit per View; gespeicherte Zuordnung nur bei Leistungsproblemen.
- Bestätigt (Product Owner 26.10.2026): Vorschau umfasst freigegebene, nicht gebuchte Runden und abgeschlossene, nicht ausgezahlte Abrechnungen; Abgleichfenster −3/+14 Tage.
- Bestätigt (Product Owner 26.10.2026): Budgetpflege darf direkt umschichten; eigene Anträge bestätigt die Schatzmeister:in bzw. die andere Person mit Budgetpflege.
- Bestätigt (Product Owner 26.10.2026): Admin-Nachtrag (T1–T4) in diesem Vorhaben statt eigener Spec der Administration; spec.md AD erhält einen Verweis.
- [OFFEN] Eintrag im Verarbeitungsverzeichnis vor Echtdaten (01-erhebung.md F).
- [OFFEN] rollen.md: Spalte DS, Vorlage Budgetpflege, Admin sieht Budget (uebergabe-administration.md D5).
