# Implementation Plan: Anwesenheitserfassung (EZ)

**Branch**: `ez-plan` (Plan); Umsetzung auf den Branches aus Abschnitt „Branches“ | **Date**: 2026-10-24 | **Spec**: [spec.md](spec.md) v0.5 (Ready)

**Input**: [spec.md](spec.md) v0.5 (führend), [02-stories.md](02-stories.md) v0.6, [01-erhebung.md](01-erhebung.md) v0.4, [00-steckbrief.md](00-steckbrief.md) v0.8, Übergaben dieses Ordners, [spec.md Administration](../ad-administration/spec.md) v0.9.5 mit Nachtrag v0.8.2, [spec.md Gruppen](../gr-gruppen/spec.md) v0.3.1, [plan.md Gruppen](../gr-gruppen/plan.md), [Constitution](../../../.specify/memory/constitution.md) v1.2.0

**Artefakte**: [research.md](research.md) · [data-model.md](data-model.md) · [contracts/](contracts/) · [quickstart.md](quickstart.md) · [tasks.md](tasks.md) · [abnahme-test.md](abnahme-test.md)

## Summary

Die Anwesenheitserfassung löst das Forms-Formular ab. Geschäftsstelle und Referent:innen erfassen Trainings, Fahrten, Wettkampfbetreuungen, Trainingslager, Arbeitseinsätze, Kurse und Touren mit Anwesenheit, mobil ab 375 px. Finanzen liest die Daten später für die Trainerabrechnung.

Technisch:
- 5 Tabellen `ez_*` mit RLS (`ez_events`, `ez_event_groups`, `ez_attendances`, `ez_trial_participants`, `ez_privacy_confirmations`). Für `authenticated` nur `select`; geschrieben wird ausschließlich über `security definer`-Funktionen (spec.md 2, 3).
- Rechte zentral in `ez_can_read`, `ez_can_write`, `ez_can_delete` (Iteration 1 ergänzt dort die Reichweite „Gruppe“).
- `ez_person_visible` ersetzt den Platzhalter der Administration mit gleicher Signatur. Sonst legt EZ keine Objekte anderer Module an und ändert keine.
- Gruppen, Anwesenheitslisten und Trainingszeiten kommen aus `gr_groups_for_attendance`, `gr_group_roster`, `gr_my_groups`; Namen aus `ea_person_names` und `ea_search_active_persons`; neue Helfer:innen über `ea_create_volunteer` und `ea_activate_person`.
- Oberfläche unter `/ez` (Liste, Erfassen in drei Schritten, Detail, Bearbeiten, Kontrollliste Kletterhalle).
- Die Anbindung der Planungshilfe (Spec T19–T21) ist zurückgestellt bis TK T13; Spalten `tk_plan_id` und `from_plan` werden jetzt angelegt und bleiben leer bzw. `false`.

## Technical Context

**Language/Version**: SQL (PostgreSQL 17, Supabase); TypeScript (Frontend, Vite)
**Primary Dependencies**: wie Administration, Ehrenamtsmanagement und Gruppen (Supabase, React 19, react-router-dom 7, @supabase/supabase-js 2, shadcn/ui, Tailwind v4, sonner). Keine neuen Pakete.
**Storage**: 5 neue Tabellen `ez_*` in Schema `public`; Personen in `ea_persons` (Administration), Gruppen in `gr_groups` (nur per FK und über GR-Lesefunktionen)
**Testing**: pgTAP in der GitHub Action `db-tests.yml` (lokaler Stack, Seed), Dateien `510_`–`590_` (research.md R-EZ-15); Mengentest mit 1.200 Einsätzen und 15.000 Anwesenheiten; fachliche Abnahme in TEST (quickstart.md D, abnahme-test.md). Kein Docker lokal: pgTAP läuft nur in CI.
**Target Platform**: Browser, mobil ab 375 px; Cloudflare Workers mit Static Assets; Supabase Free-Plan EU
**Project Type**: Web-Anwendung (statische SPA, Supabase als einziges Backend)
**Performance Goals**: Liste (50 Zeilen) < 1 s; `ez_save_event` mit 30 Anwesenheiten < 1 s; Kontrollliste eines Monats < 1 s (spec.md 8)
**Constraints**: 0 €; RLS auf jeder Tabelle; keine Insert-/Update-/Delete-Grants auf `ez_`-Tabellen; Namen nie direkt aus `ea_persons`; keine Personendaten im Browser-Speicher außer Person-IDs im Entwurf; keine Echtdaten; nie gegen PROD
**Scale/Scope**: ca. 13 Gruppen, 1.200 Einsätze und 15.000 Anwesenheiten je Jahr; 23 Stories; Spec-Tasks T1–T18 (T19–T21 zurückgestellt)

## Constitution Check

*GATE: vor Phase 0 geprüft, nach Phase 1 erneut geprüft.*

| Prinzip | Prüfung | Ergebnis |
|---|---|---|
| I Fachliche Quelle | Plan setzt spec.md v0.5 um, nicht mehr. Artefakte in `docs/specs/ez-einsaetze/`. Begriffe nach glossar.md (Einsatz, Einsatzart, Anwesenheit, Trainer:in, Helfer:in, Teilnehmer:in, Probetraining, organisierende Person, Ort, Referat, Vertretung, Wettkampfbetreuung). Technische Hilfsobjekte ohne Nennung in der Spec sind in research.md begründet und ändern kein fachliches Verhalten. | ✅ |
| II Offene Punkte | O1–O4 unten gemeldet, nicht entschieden; für die Umsetzung gilt jeweils der Vorschlag als vorläufig, sichtbar als `[OFFEN]` bzw. `[ANNAHME]`. Die [OFFEN]-Punkte aus spec.md 11 sind übernommen. | ✅ |
| III Sicherheit in der DB | RLS auf allen 5 Tabellen mit Select-Policy; Grants an `authenticated` nur `select` bzw. `execute`; Schreiben nur über `security definer`-Funktionen mit Rechteprüfung als erstem Schritt; `ez_privacy_confirmations` nur mit „EZ verwalten“ lesbar; interne Hilfsfunktionen ohne Grant | ✅ |
| IV Personenmodell/Historie | Keine Personenangaben in `ez_`-Tabellen, nur `person_id` (Probetraining nur Vorname, R6). Neue Helfer:innen als Person mit Eigenschaft Funktion über `ea_create_volunteer`. Löschfrist [OFFEN] mit Finanzen, kein Löschlauf im MVP (spec.md 8). | ✅ (Löschlauf offen laut Spec) |
| V Daten/Umgebungen | Seed fiktiv (Personen ab 33, Einsätze nach spec.md 9); keine Befehle gegen TEST ohne Freigabe des Product Owners; nie gegen PROD | ✅ |
| VI Einmal pflegen | Keine Kopien von Personen- oder Gruppendaten; Namen, Gruppen, Trainingszeiten und Orte werden gelesen, nicht kopiert | ✅ |
| VII Kostenfrei/einfach/mobil | keine neuen Dienste oder Pakete; Erfassung als eine Seite in drei Schritten; Trefferflächen ≥ 44 px; Liste ab 375 px als Karten; UI deutsch mit „du“ | ✅ |

**Gate-Ergebnis:** bestanden für Datenbank (T1–T9) und Oberfläche (T10–T16, T18). T17 (Abnahme, Freischalten) wartet auf AD T120/T121 und die Freigabe des Product Owners.

**Re-Check nach Phase 1:** data-model.md legt jede Tabelle mit RLS, Select-Policy und `grant select … to authenticated` an. Keine Insert-, Update- oder Delete-Policy auf `ez_`-Tabellen. Alle Funktionen haben `set search_path = ''`. Keine Grants an `anon`. Die View `ez_v_events` hat `security_invoker = true`. Keine weiteren Verstöße.

## Project Structure

### Documentation (this feature)

```text
docs/specs/ez-einsaetze/
├── 00-steckbrief.md, 01-erhebung.md, 02-stories.md, spec.md     (fachliche Quelle, nicht ändern)
├── uebergabe-*.md                                                 (fachlich, nicht ändern)
├── plan.md              # diese Datei
├── research.md          # Phase 0
├── data-model.md        # Phase 1
├── quickstart.md        # Phase 1
├── contracts/           # database-api.md, error-codes.md, routes.md
├── tasks.md             # Phase 2 (/speckit-tasks)
└── abnahme-test.md      # Abnahme T17 (Ergebnisse trägt der Product Owner ein)
```

Die Fehlercodes stehen normativ in [contracts/error-codes.md](contracts/error-codes.md); die gemeinsame Liste [ad-administration/contracts/error-codes.md](../ad-administration/contracts/error-codes.md) verweist im Abschnitt EZ darauf (Spec T7).

### Source Code (repository root)

```text
supabase/
├── migrations/                          # 20261028000100_ez_*.sql ff. nach data-model.md
├── tests/database/5x0_ez_*.test.sql     # T9 (research.md R-EZ-15)
├── seed.sh                              # T8: lädt seed-ez.sql nur mit SEED_WITH_EZ=1 (O3)
└── seed-ez.sql                          # T8: Testdaten nach spec.md 9, Personen ab 33, Einsätze f0…

src/
├── App.tsx                              # Routen /ez (Einbindung)
├── lib/errors.ts                        # EZ-Codes
└── features/
    ├── start/      modules.ts (Kachel EZ erscheint mit is_available, T17)
    └── ez/
        ├── EzLayout.tsx, access.ts, labels.ts, data.ts             # T10
        ├── liste/      EinsaetzePage, Filter                        # T10
        ├── erfassen/   EinsatzNeuPage, EinsatzartAuswahl, EinsatzFormular (je Einsatzart),
        │               Anwesenheit (Roster), PersonenEintragen, Probetrainings, draft.ts   # T11–T13, T15
        ├── detail/     EinsatzDetailPage, AbsageDialog, NeuePersonDialog, EinsatzBearbeitenPage  # T14, T18
        ├── kletterhalle/ KletterhallePage                           # T16
        └── shared/     AktivenSuche, OrtAuswahl (vorläufig, O2)
```

**Structure Decision:** Wie Administration, Ehrenamtsmanagement und Gruppen: SPA in `src/`, Supabase in `supabase/`. Der Dublettendialog (`src/features/shared/DublettenDialog.tsx`, Prop `hitAction`) wird eingehängt, nicht kopiert.

## Voraussetzungen und Stand (geprüft 24.10.2026, main @ 71eb204)

| Voraussetzung (spec.md Kopf, 10) | Stand | Folge |
|---|---|---|
| AD Nachtrag v0.8.2 Datenbank (AD T111–T119) | erledigt (`20261026000100`–`…000400`) | – |
| `ad_modules` EZ (`is_available = false`), Startwerte, Reichweite „Referat“ für EZ | vorhanden (`…26000100`) | Freischalten in T17 |
| `ad_locations` (`name`, `has_climbing_points`, `is_active`) | vorhanden (`…26000200`) | FK `ez_events.location_id` |
| `ez_person_visible(uuid) returns boolean` (Platzhalter `false`) | vorhanden (`…26000300`) | Ersatz in T2, gleiche Signatur |
| `ea_person_names(uuid[])` (≤ 500 IDs), `ea_search_active_persons(text, int)` (EZ ≥ bearbeiten) | vorhanden (`…26000300`) | – |
| `ea_create_volunteer(…, p_contact_email)`, `ea_activate_person`, `ea_create_path` | vorhanden (`…26000400`); EZ-Weg verlangt Art `system_key = 'function'` und genau `{"function": "Helfer:in"}` | erledigt die [ANNAHME] zum Feldschlüssel in spec.md T5 |
| `ad_find_similar_persons` mit EZ ≥ bearbeiten | vorhanden (`…26000400`) | – |
| `gr_group_roster`, `gr_groups_for_attendance`, `gr_my_groups` | vorhanden (`…25000800`) | Rückgaben passen; siehe H1, O1 |
| Eine Trainingszeit je Gruppe und Wochentag (GR v0.3.1) | vorhanden (`…27000100`) | R28 |
| Dublettendialog | `src/features/shared/DublettenDialog.tsx` mit `hitAction` | US-EZ-11 |
| Komponenten „Personensuche Aktive“, „Auswahlfeld Ort“ (AD T120) | **fehlen** (AD T120 zurückgestellt) | → O2 |
| AD T121 (Ausrollen nach TEST) | offen | Voraussetzung für T17 |
| Migrationsnummern | letzte auf `main`: `20261027000100` | EZ beginnt mit `20261028000100` |
| pgTAP-Nummern | AD 010–280, EA 310–390, GR 410–495 | EZ 510–590 |

## Branches

Nach CLAUDE.md: je Story bzw. Aufgabe ein Branch, jeweils vom aktuellen `origin/main`. Jeder Pull Request nennt Stories, Spec-Tasks und (bei Oberfläche) die Cloudflare-Vorschau-URL.

| # | Branch | Spec-Tasks | Stories | Inhalt | hängt ab von | Merge |
|---|---|---|---|---|---|---|
| 1 | `ez-plan` | – | – | plan.md, research.md, data-model.md, contracts/, quickstart.md, tasks.md, abnahme-test.md | – | Auto |
| 2 | `ez-kern-datenbank` | T1–T7, T9 | alle (Datenbankteil) | Migrationen `20261028000100`–`…000600`, pgTAP 510–590 (Testdaten in der Transaktion, O3 a), EZ-Codes in `ad-administration/contracts/error-codes.md` | 1 | Auto |
| 2a | `ez-seed` (PR #42) | T8 | alle | `supabase/seed-ez.sql`, Schalter `SEED_WITH_EZ` in `seed.sh` (O3), Übergabe | 2 | PO (`seed.sh`) |
| 3 | `us-ez-14-liste` (PR #38) | T10 | 14, 15 | Routen, Navigation, Routenschutz, /ez, Kachel, EZ-Fehlermeldungen | 2 | PO |
| 4 | `us-ez-10-detail` (PR #39) | T14 (ohne Formular), T18 | 10, 11, 13, 15, 22, 23 | /ez/:id mit Ständen, Person hinzufügen, neue Person (R29, R31), Absage, Löschen; vorläufige Komponenten (O2) | 3 | PO |
| 5 | `us-ez-01-erfassen` (PR #40) | T11, T12, T13, T14 (Bearbeiten), T15 | 01–09, 12, 17–21 | /ez/neu und /ez/:id/bearbeiten für alle Einsatzarten mit Anwesenheit, Entwurf, Doppel-Warnung | 4 | PO |
| 6 | `us-ez-16-kletterhalle` (PR #41) | T16 | 16 | /ez/kletterhalle; Umsetzungsdateien nachgezogen | 5 | PO |
| 7 | `ez-freischalten` | T17 | alle | Migration `ad_modules.is_available = true` für EZ | AD T120, T121, Abnahme, Freigabe PO | Auto (erst nach Freigabe) |
| – | (später) | T19–T21 | 23 | Anbindung Planungshilfe | TK T13 | – |

Die Oberflächen-Branches bauen aufeinander auf (Stapel). Abweichend vom ersten Plan (sechs Branches) sind es vier: Die Detailseite kommt vor dem Formular, weil das Formular nach dem Speichern dorthin führt; alle Formulare je Einsatzart teilen sich eine Komponente und stehen deshalb auf einem Branch. Solange der Vorgänger nicht gemergt ist, zielt der Pull Request auf den Vorgänger-Branch; nach dessen Merge wird er auf `main` umgestellt.

## Umsetzungsentscheidungen (Kurzfassung, Details in research.md)

- **Schreiben nur über Funktionen** (R-EZ-04): `security definer`, Rechteprüfung zuerst, Fehler als `raise exception '<CODE>' using errcode = 'P0001'` mit `detail` für Feldnamen bzw. `existing_id`.
- **Form je Einsatzart doppelt gesichert** (R-EZ-05): Check `ez_events_shape` in der Tabelle; `ez_save_event` prüft vorher mit Fehlercodes und setzt Felder, die zur Einsatzart nicht gehören, auf `null`.
- **Roster als einzige Quelle für Stichtag und Funktion** (R-EZ-06): `ez_save_event` ruft `gr_group_roster` je Gruppe auf und rechnet daraus R16, R20 und `is_substitute`.
- **Audit mit Nutzerkontext** (R-EZ-09): `created_by`/`updated_by` aus `auth.uid()`, `*_person_id` über `ad_accesses.auth_user_id`; der Seed setzt den Nutzerkontext der Geschäftsstelle.
- **Lesen mit Namen von Gruppen und Orten** (R-EZ-13): `ez_list_events`, `ez_get_event` als `security definer` mit Filter `ez_can_read`; die View `ez_v_events` bleibt `security_invoker`.
- **Komponenten der Administration** (O2): vorläufig in `src/features/ez/shared/`, mit der Schnittstelle, die AD T120 übernehmen kann.

## Offene Punkte

Gemeldet an den Product Owner. Nichts davon hat Claude Code entschieden; umgesetzt wird bis zur Entscheidung der jeweilige Vorschlag, sichtbar markiert.

- **O1 – Fehlercode für eine nicht wählbare Gruppe (entschieden, Product Owner 24.10.2026: wie vorgeschlagen).** Quelle: spec.md Abschnitt 2, `ez_save_event` Schritt 1 und 7. Ist die Gruppe am `start_date` aufgelöst oder unbekannt, meldet `gr_group_roster` `GR_GROUP_NOT_FOUND`, ohne Rechte `GR_ROSTER_FORBIDDEN`. Die Spec sagt nicht, was `ez_save_event` meldet. Vorschlag: ohne Rechte `EZ_FORBIDDEN`; Gruppe nicht wählbar (nicht in `gr_groups_for_attendance(start_date)`) `EZ_FIELD_REQUIRED` mit Feld „Gruppe“. Praktisch nur erreichbar, wenn das Datum nach der Gruppenwahl hinter die Auflösung verschoben wird.
- **O2 – Komponenten „Personensuche Aktive“ und „Auswahlfeld Ort“ fehlen (entschieden, Product Owner 24.10.2026: vorläufig in `src/features/ez/shared/`).** Quelle: spec.md 6 und 7 (Komponenten der Administration), AD tasks.md T120 (zurückgestellt). Vorschlag: EZ baut beide vorläufig in `src/features/ez/shared/` auf `ea_search_active_persons` bzw. `ad_locations`; AD T120 kann sie nach `src/features/shared/` übernehmen. Ohne sie lassen sich Training (Ort), Vertretung, organisierende Person und Arbeitseinsatz nicht bauen.
- **O3 – Testdaten in den Gruppen des Seeds brechen Tests anderer Module (entschieden, Product Owner 24.10.2026: EZ-Seed als eigene Datei `supabase/seed-ez.sql`, geladen von `seed.sh` nur mit `SEED_WITH_EZ=1` für TEST; Übergabe `uebergabe-seed-umsetzung.md` v1.1).** Quelle: spec.md 9 („Namen der Gruppen … an den Seed Gruppen angepasst“); `supabase/tests/database/200_seed.test.sql` (Zähler Personen 26, Eigenschaften 41, Statushistorie 13), `420_gr_visibility.test.sql` (Teilnahmen 5/4, Verträge 4), `480_gr_read_functions.test.sql` (Teilnahmen 4/5, Übersicht „Klettergruppe Test“ 1/0/0/0 ohne Trainingszeit, Trainingszeit heute `[]`). Die Seed-Gruppen haben zu wenige Personen für spec.md 9; jede Ergänzung (Personen, Teilnahmen, Funktionen, Trainingszeit Di 17:00–19:00) ändert diese exakten Zähler. Vorschlag: (a) Die EZ-Tests (T9) bauen die Daten aus spec.md 9 in der Testtransaktion selbst auf und hängen nicht vom Seed ab; `ez-kern-datenbank` bleibt damit frei von Änderungen an fremden Tests. (b) Der Seed (T8) kommt auf einen eigenen Branch `ez-seed` mit der Übergabe `uebergabe-gruppen-umsetzung.md` und den angepassten Zählern in 200, 420, 480; kein Auto-Merge, der Product Owner entscheidet. Zuordnung: „Gruppe Test Klettern“ = „Klettergruppe Test“ (`c…03`), „Gruppe Test Jugend“ = „Jugendgruppe Test 1“ (`c…01`); Personen ab 33 mit festen Datumswerten.
- **O4 – [OFFEN] aus spec.md 11: Text und Link der Datenschutzhinweise, Kennung `notice_version`.** Die Oberfläche nimmt den Wortlaut des Häkchens aus spec.md 6; Link und `notice_version` stehen als Konfiguration in `src/features/ez/config.ts` mit dem vorläufigen Wert `entwurf` und ohne Link. Vor der Abnahme (T17) zu klären.
- Übernommen aus spec.md 11 (kein Blocker): Lehreinheiten bei Kursen; doppelte Erfassung von Kurs und Tour; Abrechnung erster und letzter Tag mehrtägiger Einsätze; Löschfrist; Sperre nach Abgabe des Halbjahres.

Hinweise (keine Entscheidung nötig):
- **H1 – Mehrfachzeilen im Roster:** `gr_group_roster` liefert eine Person, die Teilnehmer:in und Helfer:in ist (oder zwei Funktionen hat), mehrfach. EZ fasst sie zu einer Zeile zusammen; die Funktion hat Vorrang (R17), Reihenfolge Gruppenleitung → Trainer:in → Helfer:in → Teilnehmer:in.
- **H2 – `ea_activate_person` meldet keine bereits aktive Person:** `ez_reactivate_helper` prüft `EZ_PERSON_NOT_INACTIVE` selbst, bevor es aufruft.
- **H3 – Feldschlüssel der Funktion:** Die [ANNAHME] in spec.md T5 ist durch AD `ea_create_path` festgelegt: Art `system_key = 'function'`, Wert `{"function": "Helfer:in"}`.
- **H4 – Gemeinsame Fehlerliste veraltet:** Der EZ-Abschnitt in `ad-administration/contracts/error-codes.md` hat den Stand spec.md v0.1 (`EZ_END_TIME`, `EZ_KIND_NOT_AVAILABLE`, Titel 60 Zeichen, alte Texte zu R5, R19, R21). Er wird in T7 durch einen Verweis auf [contracts/error-codes.md](contracts/error-codes.md) und die vollständige Liste nach spec.md v0.5 ersetzt (einzige Änderung in `ad-administration/`).
- **H5 – `search_path`:** alle Funktionen `''` mit voll qualifizierten Namen (wie AD research.md R-19).
- **H6 – Zusätzliche Indizes:** neben den Indizes aus spec.md 2 ein Teilindex auf `ez_events.organizer_person_id` und Indizes auf `ez_event_groups.group_id` und `ez_trial_participants.event_id`, damit `ez_person_visible` und die Fremdschlüssel den Mengentest schaffen.
- **H7 – Test 270 der Administration:** prüft `ez_person_visible(Person 4) = false` ohne Nutzerkontext. Mit dem Ersatz bleibt das Ergebnis ohne Nutzerkontext `false` (`ez_can_read` ist dann falsch); der Test muss nicht geändert werden.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| `ez_person_visible` (Objekt der Administration) per `create or replace` | spec.md AD weist den Ersatz der ersten EZ-Migration zu (Platzhalter mit gleicher Signatur) | Eine eigene EZ-Variante neben der AD-Fassung bräuchte eine Änderung an `ea_person_names` |
| `ez_list_events`, `ez_get_event`, `ez_climbing_points_report` als `security definer` | Gruppen- und Ortsnamen: `gr_groups` ist für Nutzer der Anwesenheitserfassung nicht direkt lesbar (spec.md 2, Views) | Eine Select-Policy auf `gr_groups` für EZ wäre eine Änderung an Gruppen |
