# Implementation Plan: Administration (AD) – Kern bis v0.7.1

**Branch**: `ad-kern-plan` (Plan); Umsetzung auf den Branches aus Abschnitt „Branches“ | **Date**: 2026-10-22 | **Spec**: [spec.md](spec.md) v0.9, umgesetzt wird der Kern (Abschnitte bis v0.7.1)

**Input**: [spec.md](spec.md) v0.9 (führend), [02-stories.md](02-stories.md) v0.8.1, [01-erhebung.md](01-erhebung.md) v0.7, [00-steckbrief.md](00-steckbrief.md) v1.1, [querschnitt-administration.md](../../querschnitt-administration.md) v0.1, [arbeitsplan.md](../../arbeitsplan.md) v0.1, [tech-stack.md](../../tech-stack.md) v0.6, [stammdaten-qualifikationsarten.md](../ea-ehrenamt/stammdaten-qualifikationsarten.md) v0.2, [Constitution](../../../.specify/memory/constitution.md) v1.1.1

**Artefakte**: [research.md](research.md) · [data-model.md](data-model.md) · [contracts/](contracts/) · [quickstart.md](quickstart.md) · [tasks.md](tasks.md)

## Summary

Der Kern der Administration umfasst alle Tasks T1–T49 der Spec. Erledigt sind T1–T3, T5, T12, T14, T24 und T42 (in tasks.md T001–T031), teilweise T4, T6, T7, T11, T13 und T23; T21, T28 und T31 entfallen (spec.md v0.7). Dieser Plan beschreibt den Rest: den Nachtrag v0.7/v0.7.1 (gemeinsames Personenmodell mit Feldern, Lesestufen, Referaten, Ehrenamtsstatus und Sichtbarkeit je Pfad), die Qualifikationsarten (v0.6) und die noch offenen Oberflächen und Edge Functions aus v0.5.

Technisch kommen dazu:
- 14 neue Migrationen für den Kern, danach 2 für die Edge Functions. Bestehende Migrationen (`20261020000100`–`0600`) sind in TEST ausgerollt und werden nicht geändert; alles Neue kommt per neuer Migration.
- die Edge Functions `ad-invite` und `ad-access`.
- pgTAP-Tests für jede Migration, inklusive Sichtbarkeitsmatrix und Mengentest.
- der Seed für die Personen 1–12.
- die Oberflächen unter /ad und die wiederverwendbaren Komponenten Eigenschaftsformular, Dublettendialog und Auswahlfeld „Qualifikationsart“.

## Nachtrag v0.8 (Umsetzung ab 24.10.2026, Branch `ad-nachtrag-v08`)

Grundlage: spec.md v0.9.4 (Nachtrag v0.8.1, Ready seit 24.10.2026), 02-stories.md v0.9 (US-AD-27 bis US-AD-30). Damit gilt die Tabelle „Abgrenzung“ unten für EZ nicht mehr; für TK, TKF und v0.9 gilt sie weiter. Tasks: tasks.md Phase 15 (T111–T121).

| Thema | Umsetzung | Migration |
|---|---|---|
| Modul EZ, Startwerte, R30 für EA und EZ, `created_in = 'EZ'` | spec T50; EZ direkt nach GR, `is_available = false` | `20261026000100_ad_ez_module.sql` |
| Orte | spec T51; ohne Startbestand, Testorte im Seed | `20261026000200_ad_locations.sql` |
| Namensfunktionen | spec T52; Trigramm-Index auf `last_name` | `20261026000300_ad_name_functions.sql` |
| Anlegen und Wieder-aktiv-Eintragen über EZ | spec T53, A9; interne Funktion `ea_create_path` (research.md R-30) | `20261026000400_ad_ez_create.sql` |
| Oberfläche (Vorlagen-Matrix, /ad/orte, Komponenten) | spec T55; **zurückgestellt**, `src/` war für die Sitzung vom 24.10.2026 ausgeschlossen | – |
| Abnahme in TEST | spec T58; erst nach Ausrollen nach TEST mit Freigabe des Product Owners | – |

`ad_modules.is_available` für EZ bleibt `false`; das setzt die Anwesenheitserfassung mit ihrer Freigabe. Gruppen kann die EZ-Pfade in `480_gr_read_functions.test.sql` (heute `todo`, GR plan.md O2) aktivieren; Übergabe in [uebergabe-gruppen-v08.md](uebergabe-gruppen-v08.md).

## Abgrenzung: Kern ohne Nachträge v0.8 und v0.9

Nicht umgesetzt werden der Nachtrag v0.8 (T50–T58) und der Nachtrag v0.9 (T59–T67) ([arbeitsplan.md](../../arbeitsplan.md) 4.1, [querschnitt-administration.md](../../querschnitt-administration.md) Abschnitt 2). Wo spec.md v0.9 in den Kernabschnitten Text mit „v0.8“ oder „v0.9“ markiert, gilt die Fassung ohne diese Ergänzung. Für den Kern heißt das:

| Thema | Im Kern | Kommt mit |
|---|---|---|
| R30 Reichweite „Referat“ | nur für EA; Check `scope = 'all' or (scope = 'referat' and module_code = 'EA')`; Meldung aus US-AD-20 AK3: „Die Reichweite ‚Referat‘ ist nur im Ehrenamtsmanagement möglich.“ | EZ: T50; TK, TKF: T59 |
| `ad_modules` | die 9 bestehenden Zeilen (AD, SC, EA, GR, FI, OA, PM, GS, AM), keine Spalte `is_hidden` | EZ: T50; TK, TKF, `is_hidden`: T59 |
| Startwerte | Admin = AD, SC, EA `manage`, GR `read`; Geschäftsstelle wie bisher; Referent:in = EA `edit` mit scope `referat`; Vorstand ohne | EZ-, TK-, TKF-Startwerte, Vorlage „Freigabe Touren und Kurse“: T50, T59 |
| Tabellen | keine `ad_locations`, keine `ad_rates` | T51, T60 |
| Funktionen | keine `ea_person_names`, `ea_search_active_persons`, `ez_person_visible`, `tk_person_visible`, `ea_person_licenses`, `ad_rates_at`, `ad_can_edit_locations`, `ad_can_edit_rates`, `ad_can_read_rates` | T52, T62, T63 |
| `ea_create_volunteer` | ohne `p_contact_email`, ohne `created_in = 'EZ'`, ohne EZ-Rechte | T53 |
| `ad_find_similar_persons` | aufrufbar mit AD ≥ edit, EA ≥ edit (beide Reichweiten), GR ≥ edit | EZ ≥ edit: T53 |
| `ea_persons.created_in` | Check `AD`, `EA`, `GR`, `script` | `EZ`: T53 |
| `ad_my_modules` | `is_available` und `ad_has_any_level(code,'read')` | `is_hidden`, Sonderfall TKF: T59 |
| Rechtevorlagen-Matrix | 9 Module × Stufe, Spalte Reichweite („Referat“ nur bei EA) | Zeilen EZ, TK, TKF: T55, T64 |
| Seed | Personen 1–12 nach spec.md Abschnitt 9; Testarten ohne `system_key` `function`, `contact`, `license`; `birth_date` (v0.7) bleibt | Personen 13–18, Orte, Sätze, `system_key` der Testarten: T57, T66 |
| Fehlercodes | `AD_LOCATION_*`, `AD_SEARCH_TOO_SHORT`, `AD_TOO_MANY_IDS`, `EA_CREATE_*` und alle `EZ_*` bleiben in contracts/error-codes.md als „geplant“ stehen, werden aber nicht umgesetzt | T52–T54, Anwesenheitserfassung |
| Navigation AD | Personen · Rechtevorlagen · Eigenschaftsarten · Qualifikationsarten · Protokoll | Orte: T55; Sätze: T64 |

Die Nachträge ergänzen später per neuer Migration (neue Zeilen, Tabellen, Funktionen, erweiterter Check); keine Kern-Tabelle wird dafür umgebaut ([querschnitt-administration.md](../../querschnitt-administration.md) Abschnitt 2).

## Technical Context

**Language/Version**: SQL (PostgreSQL 17, Supabase); TypeScript (Frontend, Vite); TypeScript/Deno (Edge Functions); Bash (`seed.sh`)
**Primary Dependencies**: Supabase (Auth, PostgREST, Edge Functions, pg_cron, pg_trgm, citext); React 19, react-router-dom 7, @supabase/supabase-js 2, shadcn/ui, Tailwind CSS v4, sonner; Vite mit @cloudflare/vite-plugin
**Storage**: Supabase PostgreSQL, Schema `public`; Supabase Auth (`auth.users`)
**Testing**: pgTAP (`supabase test db`) und Deno-Tests der Edge Functions in der GitHub Action `db-tests.yml` mit lokalem Stack und Seed; Mengentest (1.000 Personen × 30 Eigenschaften) in pgTAP; fachliche Abnahme in TEST (T25, T32, T49); keine Frontend-Unit-Tests gefordert
**Target Platform**: Browser, mobil ab 375 px; Cloudflare Workers mit Static Assets; Supabase Free-Plan EU
**Project Type**: Web-Anwendung – statische SPA, Supabase als einziges Backend
**Performance Goals**: Personenübersicht bei 1.000 Personen < 1 s je Seite; Pfad EA mit Reichweite Referat bei 1.000 Personen × 30 Eigenschaften < 1 s; Liste der Qualifikationsarten bei 100 Einträgen < 1 s (spec.md Abschnitt 8)
**Constraints**: 0 €; keine Serverlogik bei Cloudflare; kein Docker lokal (Tests nur in CI); nie gegen PROD; kein `config push`/`config diff`; Auth-Mails max. 30 je Stunde
**Scale/Scope**: 4 Nutzer in PROD (später Referent:innen), ca. 1.000 Personen, 26 Stories, 49 Spec-Tasks im Kern T1–T49 (davon 8 erledigt, 7 teilweise, 3 entfallen)

## Constitution Check

*GATE: vor Phase 0 geprüft, nach Phase 1 erneut geprüft.*

| Prinzip | Prüfung | Ergebnis |
|---|---|---|
| I Fachliche Quelle | Plan setzt spec.md v0.9 im Umfang des Kerns um; Abgrenzung nach arbeitsplan.md und querschnitt-administration.md; Artefakte in `docs/specs/ad-administration/`; Begriffe nach glossar.md | ✅ |
| II Offene Punkte | O1 (Weg nach PROD) und die übrigen [OFFEN] aus spec.md Abschnitt 11 werden gemeldet, nicht entschieden; die [ANNAHME]n v0.6 und v0.7 werden umgesetzt und bei der Abnahme bestätigt (arbeitsplan.md Schritt 7) | ✅ |
| III Sicherheit in der DB | Jede neue Tabelle mit RLS, Policies, `revoke … from anon, public`, Grants an `authenticated`; Sichtbarkeit je Pfad ausschließlich über security-definer-Funktionen mit festem `search_path` und Policies; Schreiben auf `ea_volunteer_status_history`, `ad_assignment_referate`, `ea_property_history` nur über Funktionen/Trigger; Edge Functions prüfen das JWT selbst | ✅ |
| IV Personenmodell/Historie | Eigenschaften als Zeilen mit `valid_from`/`valid_to`, Werte je Feld in `field_values`; Historie per Trigger; Ehrenamtsstatus mit Historie; Löschlauf für Personen nach MVP (spec.md Abschnitt 2), AD löscht nur das Protokoll nach 5 Jahren | ✅ |
| V Daten/Secrets/Umgebungen | Seed nur fiktiv (Personen 1–12), `example.test` für Kontaktadressen; Startbestände ohne Personendaten per Migration; nie gegen PROD | ✅ |
| VI Automatisieren/einmal pflegen | eine gemeinsame Personen-Tabelle für alle Module (E1); Qualifikationsarten, Referate, Gremien einmal als Stammdaten; pg_cron-Löschlauf des Protokolls | ✅ |
| VII Kostenfrei/einfach/mobil | nur Free-Pläne; Screens ab 375 px; UI deutsch mit „du“ | ✅ |

**Gate-Ergebnis:** bestanden. **Re-Check nach Phase 1:** data-model.md hält III ein: Jede neue Tabelle hat Policies; die Sichtbarkeitsfunktionen sind die einzige Stelle, an der Pfade ausgewertet werden; keine Tabelle bekommt Grants an `anon`. Keine Verstöße.

## Project Structure

### Documentation (this feature)

```text
docs/specs/ad-administration/
├── 00-steckbrief.md, 01-erhebung.md, 02-stories.md, spec.md   (fachliche Quelle, aus OneDrive)
├── plan.md              # diese Datei
├── research.md          # Phase 0
├── data-model.md        # Phase 1
├── quickstart.md        # Phase 1
├── contracts/           # database-api.md, edge-functions.md, error-codes.md (normativ), routes.md
└── tasks.md             # Phase 2 (/speckit-tasks)
```

Die fachlichen Dateien kommen aus OneDrive und werden im Repository nicht geändert; plan.md, research.md, data-model.md, quickstart.md, tasks.md und contracts/ pflegt Claude Code nur im Repository (CLAUDE.md).

### Source Code (repository root)

```text
.github/workflows/db-tests.yml         # vorhanden: lokaler Stack + seed.sh + supabase test db + deno test
supabase/
├── migrations/                        # neue Dateien ab 20261023000100 (data-model.md)
├── functions/_shared/, ad-invite/, ad-access/   # T9, T10
├── tests/database/*.test.sql          # T7, T29, T45
├── seed.sh, seed.sql                  # T23, T48 (Personen 1–12)
└── setup/                             # vorhanden (T24)

src/
├── lib/            errors.ts (neue Codes), rights.ts (ad_has_any_level), format.ts (Personenname)
├── components/     StatusBadge, ResponsiveTable, Pagination
└── features/
    ├── auth/       PasswortVergessenPage, PasswortSetzenPage                      # T13
    └── ad/
        ├── AdLayout.tsx                                                           # Navigation AD
        ├── personen/          Übersicht, Neu, Detail (Stammdaten, Zugang, Rechtevorlagen, Eigenschaften)   # T15–T19, T44, T47
        ├── rechtevorlagen/    Liste, Bearbeiten mit Matrix und Reichweite       # T20, T44
        ├── eigenschaftsarten/ Liste, Bearbeiten mit Feldern                     # T46
        ├── qualifikationsarten/ Liste, Formular                                 # T30
        └── protokoll/         ProtokollPage                                     # T22
    └── shared/      Eigenschaftsformular, Dublettendialog, QualifikationsartAuswahl   # T47, T49, T30
```

**Structure Decision**: Eine SPA in `src/` (bestehendes Gerüst) und Supabase in `supabase/`, Repo-Struktur nach tech-stack.md Abschnitt 7. Die wiederverwendbaren Komponenten liegen unter `src/features/shared/`, damit EA, GR und spätere Module sie ohne Änderung einhängen (spec.md Abschnitt 6).

## Stand der Umsetzung (geprüft 22.10.2026, main @ c52aa7b)

| Spec-Task | Stand | Beleg / Rest |
|---|---|---|
| T1, T3, T5 | erledigt | `20261020000100`, `…0300`, `…0500` |
| T2 | erledigt | `ea_persons`, `ea_v_persons`; Rest ersetzt durch T35/T36 |
| T4 | Teil | `ad_audit_log`; offen: `ad_notice_acks`, Notfall-Funktionen, pg_cron, interne `ad_apply_*` |
| T6 | Teil | `ad_me()`, Abgleich der Policies; offen: `ad_v_person_overview` (kommt direkt in der Fassung T41) |
| T7 | Teil | Action und Tests 010–060; wächst mit jeder Migration |
| T8 | offen | entsteht direkt in der Fassung von T43 |
| T9, T10 | offen | keine Edge Functions im Repository |
| T11 | Teil | `config.toml` für CI erledigt; TEST/PROD stellt der Product Owner im Dashboard ein (supabase/setup/README.md) |
| T12, T14, T24 | erledigt | Frontend-Gerüst, Startseite, Einrichtungsskript PROD |
| T13 | Teil | Login, Abmelden; offen: Passwort setzen, Passwort vergessen |
| T15–T20, T22 | offen | T20: unfertiger Stand auf Branch `us-ad-10-rechtevorlagen` (T032–T034), wird übernommen |
| T21, T28, T31 | entfällt | spec.md v0.7 |
| T23 | Teil | `seed.sh`; `seed.sql` mit Personen 1–8, Zugängen, Zuweisungen, Protokoll; offen: Eigenschaften, Personen 9–12 (T48) |
| T25 | offen | Abnahme |
| T26, T27, T29, T30, T32 | offen | Qualifikationsarten |
| T33–T41, T43–T49 | offen | Nachtrag v0.7 |
| T42 | erledigt | contracts/error-codes.md; Text von `AD_SCOPE_NOT_ALLOWED` für den Kern angepasst (dieser Plan) |

## Branches

CLAUDE.md: je Story bzw. Aufgabe ein Branch; bedingen sich Stories gegenseitig, kommt der zusammenhängende Teil auf einen gemeinsamen Branch. Jeder Pull Request nennt die enthaltenen Stories und Tasks und die Cloudflare-Vorschau-URL.

| # | Branch | Spec-Tasks | Stories | Inhalt |
|---|---|---|---|---|
| 1 | `ad-kern-plan` | – | – | plan.md, research.md, data-model.md, contracts/, quickstart.md, tasks.md |
| 2 | `ad-kern-datenbank` | T4 Teil, T6 Teil, T7 Teil, T8, T23 Teil, T26, T27, T29, T33–T41, T43, T45, T48 | 06, 07, 12, 13, 15, 17–26 (jeweils Datenbankteil) | Migrationen `20261023000100`–`1400`, pgTAP, Seed Personen 1–12 |
| 3 | `us-ad-10-rechtevorlagen` | T20, T44 Teil | 10, 20 | übernimmt T032–T034 vom bestehenden Branch; Spalte Reichweite (R30) |
| 4 | `us-ad-06-personen` | T15 | 06, 15, 24 | Übersicht mit Suche (Vor-, Ruf-, Nachname), Filter Zugangsstatus und Zugehörigkeit, Paginierung, Notfall-Hinweis |
| 5 | `us-ad-07-person-anlegen` | T16, T49 Teil | 07, 24, 25 | Person anlegen mit Rufname; Dublettendialog als Komponente |
| 6 | `us-ad-17-qualifikationsarten` | T30, T32 Teil | 17, 18 | Liste und Formular; Auswahlfeld „Qualifikationsart“ |
| 7 | `us-ad-12-eigenschaftsarten` | T46 | 12, 19, 22 | Eigenschaftsarten mit Feldern, Kategorie, Lesestufe, Bezug |
| 8 | `us-ad-13-eigenschaften` | T17 Teil (Gerüst, Stammdaten), T19, T47 | 13, 19, 23, 24 | Personendetail; Eigenschaftsformular; Ehrenamtsstatus nur lesen |
| 9 | `us-ad-11-zuweisen` | T18, T44 Teil | 11, 21 | Vorlagen zuweisen, entziehen; Referate (R31) |
| 10 | `us-ad-08-zugang` | T4 Teil, T9, T10, T13, T17 Teil | 03, 04, 08, 09 | Edge Functions, interne Statusfunktionen, Passwort-Seiten, Abschnitt Zugang |
| 11 | `us-ad-14-protokoll` | T22 | 14 | Protokoll-Ansicht |
| 12 | `ad-kern-abnahme` | T25, T32, T49 | 16, 26, alle | Abnahme in TEST nach quickstart.md; Anpassungen aus der Abnahme |

Reihenfolge: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10 → 11 → 12. Die Branches 3–11 hängen nur von 2 ab und von den Komponenten, die sie nutzen (8 nach 6 und 7; 9 nach 3 und 8; 10 nach 8). Der alte Branch `us-ad-10-rechtevorlagen` wird nach Übernahme gelöscht; seine Änderung an `docs/offene-punkte.md` wird nicht übernommen (Datei kommt aus OneDrive).

## Offene Punkte

- [OFFEN] **O1** Weg der Migrationen und Edge Functions nach PROD (manuell oder GitHub Action beim Merge auf `main`); bis zur Klärung wird PROD nicht angefasst (spec.md Abschnitt 11). Kein Blocker für den Kern in TEST.
- Übernommen aus spec.md Abschnitt 11 (kein Blocker): [OFFEN] Vertretung des Admin-Zugangs; [OFFEN] Löschlauf nach 5 Jahren über alle Pfade.
- Gemeldet an den Product Owner (22.10.2026): neuere Fassung `arbeitsplan.md` v0.2 liegt in OneDrive unter `Claude outputs/`, nicht unter `docs/` (CLAUDE.md, Abschnitt Fachliche Dokumente).

## Complexity Tracking

Keine Verstöße gegen die Constitution.
