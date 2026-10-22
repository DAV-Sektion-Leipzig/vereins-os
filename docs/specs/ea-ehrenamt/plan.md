# Implementation Plan: Ehrenamtsmanagement (EA)

**Branch**: `claude/beautiful-shannon-667zkn` (Plan); Umsetzung auf den Branches aus Abschnitt „Branches“ | **Date**: 2026-10-22 | **Spec**: [spec.md](spec.md) v0.2 (Ready)

**Input**: [spec.md](spec.md) v0.2 (führend), [02-stories.md](02-stories.md) v0.2, [01-erhebung.md](01-erhebung.md) v0.5, [00-steckbrief.md](00-steckbrief.md) v0.7, [migration-aktivenliste.md](migration-aktivenliste.md) v0.5, [uebergabe-administration.md](uebergabe-administration.md) v1.1, [spec.md Administration](../ad-administration/spec.md) v0.9.2, [plan.md Administration](../ad-administration/plan.md), [arbeitsplan.md](../../arbeitsplan.md) v0.3, [Constitution](../../../.specify/memory/constitution.md) v1.2.0

**Artefakte**: [research.md](research.md) · [data-model.md](data-model.md) · [contracts/](contracts/) · [quickstart.md](quickstart.md) · tasks.md (folgt mit `/speckit-tasks`)

## Summary

Das Ehrenamtsmanagement löst die Excel-Aktivenliste ab. Geschäftsstelle, Admin und Referent:innen finden Aktive über Tabelle und Filter, pflegen Eigenschaften mit Historie, setzen den Ehrenamtsstatus, sehen den Ablauf von Qualifikationen und exportieren die Stichtagsliste. Die ca. 130 Trainer:innen der Aktivenliste kommen einmalig per Skript in PROD.

Technisch baut das Modul vollständig auf dem Kern der Administration auf: Personenmodell, RLS, Sichtbarkeit, Statusfunktionen, Dublettenwarnung und Formular-Komponenten. Es legt **keine Tabelle** an (spec.md Abschnitt 2). Es ergänzt:
- 2 Migrationen mit Stammdaten: 25 System-Eigenschaftsarten, 10 Qualifikationsarten.
- 4 Migrationen mit View, Funktionen und Trigger: Ablauf, Liste, IBAN, Status, Verlängern, Import.
- 1 Migration zum Freischalten nach der Abnahme.
- die Seed-Umstellung auf System-Eigenschaftsarten (Ü3) und die Testpersonen 19–22.
- pgTAP-Tests ab Nummer 200 inklusive Mengentest.
- die Oberflächen unter /ea, die die Komponenten der Administration einhängen.
- das lokale Migrationsskript `scripts/ea-migrate/` mit Datenbankfunktion `ea_import_volunteers` (nur `service_role`).

## Technical Context

**Language/Version**: SQL (PostgreSQL 17, Supabase); TypeScript (Frontend, Vite); TypeScript mit `tsx` (Migrationsskript, Node); Bash (`seed.sh`, unverändert)
**Primary Dependencies**: wie Administration (Supabase, React 19, react-router-dom 7, @supabase/supabase-js 2, shadcn/ui, Tailwind v4, sonner). Neu nur für das Skript: `tsx`, `csv-parse` (devDependencies, kostenfrei)
**Storage**: Tabellen der Administration in Schema `public`; keine neuen Tabellen
**Testing**: pgTAP in der GitHub Action `db-tests.yml` (lokaler Stack, Seed), Dateien ab `210_`; Mengentest 1.000 Personen × 30 Eigenschaften; Probelauf des Skripts gegen TEST mit fiktiven Beispieldateien; fachliche Abnahme in TEST (T21); keine Frontend-Unit-Tests gefordert
**Target Platform**: Browser, mobil ab 375 px; Cloudflare Workers mit Static Assets; Supabase Free-Plan EU; Skript lokal beim Admin
**Project Type**: Web-Anwendung (statische SPA, Supabase als einziges Backend) plus lokales Kommandozeilen-Skript
**Performance Goals**: `ea_volunteer_list` (Referent:in, alle Filter) < 1 s, `ea_v_expiry` für ein Jahr < 2 s, Detail < 1 s bei 1.000 Personen × 30 Eigenschaften; Import von 300 Zeilen < 60 s (spec.md Abschnitt 8)
**Constraints**: 0 €; keine neue Tabelle, keine neue Policy; neue Funktionen `security invoker` außer Import; keine Echtdaten; nie gegen PROD (der PROD-Lauf ist Sache des Admins); kein Docker lokal (Tests nur in CI)
**Scale/Scope**: ca. 250 Aktive (130 aus der Migration), 1.000 Personen; 19 Stories; 23 Spec-Tasks (T1–T23; T0a, T0b entfallen, weil Ü1 und Ü2 im Kern umgesetzt sind)

## Constitution Check

*GATE: vor Phase 0 geprüft, nach Phase 1 erneut geprüft.*

| Prinzip | Prüfung | Ergebnis |
|---|---|---|
| I Fachliche Quelle | Plan setzt spec.md v0.2 vollständig um, nicht mehr; Artefakte in `docs/specs/ea-ehrenamt/`; Begriffe nach glossar.md (Aktive:r, Ehrenamtsstatus, Eigenschaftsart, Qualifikationsart, Referat, Gremium) | ✅ |
| II Offene Punkte | Widersprüche und Lücken unten als O1–O3 und H1–H2 gemeldet; O2 und O3 hat der Product Owner am 23.10.2026 entschieden, O1 ist offen; [ANNAHME]n aus spec.md Abschnitt 11 sind bestätigt; neue Annahmen nur in Umsetzungsdetails (Texte im Prüfbericht) und als solche markiert | ✅ |
| III Sicherheit in der DB | Keine neue Tabelle; die View hat `security_invoker`, die Funktionen sind `security invoker` (RLS der Administration gilt); Grants nur an `authenticated` | ⚠️ siehe unten |
| III, Ausnahme Import | `ea_import_volunteers` ist `security definer` mit Grant nur an `service_role`, nicht an `authenticated`. Begründung: Der Lauf muss ohne Nutzerkontext schreiben (Altbestand, Status, `created_in = 'script'`) und eine Transaktion sein (A3). Gleiches Muster wie `ad_apply_*` der Administration. Kein Weg aus dem Frontend. | ✅ begründet |
| III/V Secrets | spec.md Abschnitt 7 sieht `SUPABASE_SERVICE_ROLE_KEY` in `.env.migration.local` vor. Constitution III („Secret Key / service_role … nie in `.env`-Dateien“) und CLAUDE.md verbieten das. | ❌ **O1, Product Owner** |
| IV Personenmodell/Historie | Eigenschaften als Zeilen über System-Eigenschaftsarten; Verlängern und Ausscheiden beenden Einträge über `valid_to` statt zu überschreiben; Statushistorie über die Funktionen der Administration; kein Löschen | ✅ |
| V Daten/Umgebungen | Seed fiktiv (Personen 19–22, `example.test`, Beispiel-IBAN `DE89370400440532013000`); CSV und Berichte nie im Repository (`.gitignore`); Claude Code arbeitet nur gegen TEST; PROD-Lauf durch den Admin (T23); Reset von TEST nur auf Auftrag | ✅ |
| VI Einmal pflegen | eine gemeinsame Personen-Tabelle; Stammdaten einmal; System-Schlüssel für andere Module (data-model.md); keine Kopien von Personendaten | ✅ |
| VII Kostenfrei/einfach/mobil | nur Free-Pläne und freie npm-Pakete; Karten ab 375 px; UI deutsch mit „du“ | ✅ |

**Gate-Ergebnis:** bestanden für alle Tasks außer **T20 (Migrationsskript)**. T20 bleibt gesperrt, bis O1 entschieden und spec.md Abschnitt 7 angepasst ist. Die Datenbankfunktion `ea_import_volunteers` (T7) ist davon nicht berührt, weil sie keinen Schlüssel braucht.

**Re-Check nach Phase 1:** data-model.md legt keine Tabelle und keine Policy an. Die View hat `security_invoker`. Alle Funktionen außer dem Import sind `security invoker` und haben einen festen `search_path`. Kein Grant an `anon`. Der Import ist nur für `service_role` ausführbar; pgTAP prüft die Ablehnung für `authenticated`. Das Ergebnis bleibt unverändert: Nur O1 ist offen.

## Project Structure

### Documentation (this feature)

```text
docs/specs/ea-ehrenamt/
├── 00-steckbrief.md, 01-erhebung.md, 02-stories.md, spec.md        (fachliche Quelle, nicht ändern)
├── migration-aktivenliste.md, stammdaten-qualifikationsarten.md   (fachlich)
├── uebergabe-administration.md, uebergabe-anwesenheitserfassung.md (fachlich)
├── plan.md              # diese Datei
├── research.md          # Phase 0
├── data-model.md        # Phase 1
├── quickstart.md        # Phase 1
├── contracts/           # database-api.md, routes.md, migration-script.md
└── tasks.md             # Phase 2 (/speckit-tasks)
```

Die Fehlercodes stehen normativ in [error-codes.md der Administration](../ad-administration/contracts/error-codes.md) (spec.md Abschnitt 5, T8); contracts/database-api.md nennt sie nur.

### Source Code (repository root)

```text
supabase/
├── migrations/                         # …_ea_*.sql nach data-model.md
├── tests/database/2xx_ea_*.test.sql    # T9 (research.md R-EA-12)
└── seed.sql                            # T3: Umstellung Ü3, Personen 19–22

scripts/ea-migrate/                     # T20 (gesperrt bis O1)
├── index.ts, csv.ts, columns.ts, report.ts
├── vorlage.csv, beispiel.csv, beispiel-fehler.csv
package.json                            # Script "ea:migrate", devDependencies tsx, csv-parse
.gitignore                              # CSV und Berichte im Skriptordner

src/
├── lib/            errors.ts (neue EA-Codes), format.ts (personName, bestehend)
└── features/
    ├── start/      modules.ts (Kachel EA)
    └── ea/
        ├── EaLayout.tsx, routes.tsx                     # T10
        ├── aktive/    AktivePage, Filterleiste, PersonNeuPage, PersonDetailPage,
        │              StatusDialog, AusscheidenSchritt, VerlaengernDialog        # T11–T15
        ├── ablauf/    AblaufPage, csv.ts                                         # T16
        ├── gremien/   GremienPage                                                # T17
        └── stammdaten/ StammdatenPage (Referate, Gremien)                        # T18
            (/ea/eigenschaftsarten*, /ea/qualifikationsarten*: Seiten der Administration, T19)
```

**Structure Decision:** Wie in der Administration: SPA in `src/`, Supabase in `supabase/`. Neu ist nur `scripts/ea-migrate/` für das lokale Skript (spec.md Abschnitt 7). Formulare, Dublettendialog und Seiten für Eigenschafts- und Qualifikationsarten werden aus der Administration eingehängt, nicht kopiert (US-EA-15).

## Voraussetzungen und Stand (geprüft 23.10.2026, main @ 9e05a8b)

| Voraussetzung | Stand | Folge |
|---|---|---|
| AD T33, T34, T26, T27, T37, T40 (Reichweite, Referate/Gremien, Qualifikationsarten, Personen-Spalten, Startvorlagen) | erledigt (`20261023000100`–`0700`) | – |
| AD T35, T36, T38, T39, T41, T43 (Eigenschaftsarten, Eigenschaften, Sichtbarkeit, EA-Funktionen, Dubletten) | erledigt (`20261023000800`–`1400`, PR #15) | – |
| AD T48 (Seed Personen 1–12 mit Eigenschaften) | erledigt (AD tasks.md T061) | – |
| Ü1, Ü2, R3a (AD v0.7.2/v0.7.3), Datenbank | erledigt (`…000800` Bezeichnungen, `…001300` Geburtsjahr nach Lesestufe und `ad_first_names_match`) | T0a, T0b entfallen |
| Ü1, Ü2, Oberfläche | Dublettendialog (T073) und Formular der Eigenschaftsart (T081) mit Ü1/Ü2 auf den Branches `us-ad-07-person-anlegen` bzw. `us-ad-12-eigenschaftsarten` (noch nicht gemergt); Bezeichnungen im Eigenschaftsformular und in der Anzeige (T082, T083) offen | Teil der AD-Komponenten, siehe H1 |
| AD T30, T46, T47, T49 (Komponenten: Auswahlfeld Qualifikationsart, Eigenschaftsarten, Eigenschaftsformular, Dublettendialog) | offen (AD tasks.md T073, T076, T081, T082) | blockiert T12–T15, T19 |
| AD-Migrationen `…001500`–`…001700` (Zugang, Protokoll) | offen | vor der ersten EA-Migration nach TEST bringen oder einmal `--include-all` (research.md R-EA-01) |
| TEST zurücksetzen vor der ersten EA-Migration | Entscheidung Product Owner (spec.md AD Abschnitt 9) | quickstart.md B, durch den Product Owner oder auf Auftrag |

Der Datenbankteil des Ehrenamtsmanagements (Branch `ea-datenbank`, ohne T20) kann beginnen, sobald TEST zurückgesetzt ist bzw. der Product Owner das freigibt (quickstart.md B). Die Oberflächen warten auf die Komponenten der Administration. arbeitsplan.md Schritt 8 sieht EA nach der Abnahme des Kerns (Schritt 7) vor; ob der Datenbankteil vorgezogen wird, entscheidet der Product Owner.

## Branches

Nach CLAUDE.md: je Story bzw. Aufgabe ein Branch. Was sich gegenseitig bedingt, kommt auf einen gemeinsamen Branch. Jeder Pull Request nennt Stories, Spec-Tasks und die Cloudflare-Vorschau-URL.

| # | Branch | Spec-Tasks | Stories | Inhalt | hängt ab von |
|---|---|---|---|---|---|
| 1 | `claude/beautiful-shannon-667zkn` | – | – | plan.md, research.md, data-model.md, contracts/, quickstart.md; danach tasks.md | – |
| 2 | `ea-datenbank` | T1–T6, T8, T9 (ohne Import); Fehlercodes beim Anlegen (O3) | 16, 19; Datenbankteil von 02, 03, 06–09, 11, 12 | Migrationen …000100–…000500, Fehlercodes, Seed, pgTAP 210–270, 290 | AD-Kern Datenbank (erledigt) |
| 3 | `us-ea-17-import` | T7, T9 (Import), T20 | 17, 18 | `ea_import_volunteers`, pgTAP 280, Skript | 2; T20 zusätzlich O1 |
| 4 | `us-ea-01-navigation` | T10 | 01 | Routen, EaLayout, Routenschutz | 2 |
| 5 | `us-ea-02-aktive` | T11 | 02, 03 | Übersicht, Filter, URL, Karten | 4 |
| 6 | `us-ea-04-detail` | T12 | 04, 11 | Detail, Historie, Bezeichnungen, Ablauf-Badges | 4, AD T47 |
| 7 | `us-ea-05-person-anlegen` | T13 | 05, 10 | Anlegen, Dublettendialog-Aktionen | 6, AD T49 |
| 8 | `us-ea-06-eigenschaften` | T14 | 06, 07 | Eigenschaften pflegen, Vorbelegung, Verlängern | 6, AD T30, T47 |
| 9 | `us-ea-08-status` | T15 | 08, 09 | Status ändern, Ausscheiden | 6 |
| 10 | `us-ea-12-ablauf` | T16 | 12 | Stichtagsliste, CSV | 4 |
| 11 | `us-ea-13-gremien` | T17 | 13 | Gremium-Sichten | 4 |
| 12 | `us-ea-14-stammdaten` | T18 | 14 | Referate und Gremien | 4 |
| 13 | `us-ea-15-arten` | T19 | 15 | Einhängen der AD-Seiten | 4, AD T30, T46 |
| 14 | `ea-abnahme` | T21 | alle | Abnahme nach quickstart.md D; Anpassungen aus der Abnahme | 2–13 |
| 15 | `ea-freischalten` | T22 | 01 (AK1) | Migration …000700 | 14 |

Reihenfolge: 1 → 2 → (3 parallel) → 4 → 5, 6, 10–13 → 7, 8, 9 → 14 → 15. T23 (Lauf gegen PROD) macht der Admin nach 15 und nach Klärung von O1 der Administration (Weg der Migrationen nach PROD).

## Umsetzungsentscheidungen (Kurzfassung, Details in research.md)

- **Reihenfolge in `ea_leave`:** erst Eigenschaften beenden, dann Status setzen. Sonst verliert die Referent:in mitten in der Transaktion die Sichtbarkeit (R-EA-09).
- **Import und Dubletten:** `ad_find_similar_persons` braucht einen Nutzerkontext. Der Import wendet deshalb `ad_first_names_match` (R3a AD) direkt an; R28 prüft er selbst, weil der Trigger ohne Nutzerkontext nicht prüft (R-EA-10).
- **Vorbelegung „gültig bis“:** nur in der Datenbank (`ea_default_valid_until`); Frontend und Import rufen dieselbe Funktion (R-EA-13).
- **Tests mit relativem Datum:** Erwartungen zur Stichtagsliste werden aus `current_date` berechnet (R-EA-06).
- **Freischalten:** zuletzt, nach der Abnahme; US-EA-01 AK1 wird danach in TEST geprüft (R-EA-14).

## Offene Punkte

Gemeldet an den Product Owner. Nichts davon hat Claude Code entschieden.

- [OFFEN] **O1 – Schlüssel des Migrationsskripts (blockiert T20):** spec.md Abschnitt 7 sieht `SUPABASE_URL` und `SUPABASE_SERVICE_ROLE_KEY` in `.env.migration.local` vor (in `.gitignore`). Constitution Prinzip III und CLAUDE.md („Secret Key / service_role … nie in `.env`-Dateien, nie im Repo“) verbieten den Schlüssel in `.env`-Dateien. Quelle: `docs/specs/ea-ehrenamt/spec.md` Abschnitt 7 gegen `.specify/memory/constitution.md` Prinzip III.
  - *Vorschlag:* Das Skript liest beide Werte nur aus der Umgebung der laufenden Shell. Der Admin setzt den Schlüssel unmittelbar vor dem Aufruf, ohne ihn in einer Datei abzulegen (z. B. `read -s SUPABASE_SERVICE_ROLE_KEY; export SUPABASE_SERVICE_ROLE_KEY`). spec.md Abschnitt 7 würde dann auf einem Branch `docs/ea-schluessel` angepasst.
  - *Alternative:* eine eng gefasste Ausnahme in der Constitution (wie die in Prinzip V).
  - Außerdem zu klären: Wer führt den Probelauf gegen TEST aus (US-EA-17 AK6, T20)? Vorschlag: der Admin, nicht Claude Code, weil Claude Code dafür den Secret Key von TEST bräuchte.
- **O2 – Verlängern bei historischer Qualifikationsart (entschieden, Product Owner 23.10.2026):** Der Knopf „Verlängern“ erscheint nur bei Lizenzen und Qualifikationen, deren Qualifikationsart den Status „aktuell“ hat. Bei historischen Arten fehlt er. Die Datenbank lehnt das Verlängern ohnehin ab (R27 AD). Umsetzung in T14 (Branch `us-ea-06-eigenschaften`). spec.md Abschnitt 6 (Dialog „Verlängern“) beschreibt das noch nicht; Nachtrag nur auf Auftrag (Branch `docs/…`).
- **O3 – Fehlercodes beim Anlegen (entschieden, Product Owner 23.10.2026, wie vorgeschlagen):** Eine neue Migration auf dem Branch `ea-datenbank` (`…_ea_check_create.sql`, `create or replace` mit gleicher Signatur) ersetzt die Prüfung `ea_check_create` der Administration (Migration `20261023001100`, genutzt von `ea_create_volunteer` und `ea_activate_person`):
  - ohne EA-Recht (z. B. Vorstand): `EA_CREATE_FORBIDDEN` → „Für diesen Bereich hast du keine Rechte.“ (statt `AD_FORBIDDEN`; US-EA-05 AK6),
  - Referent:in ohne Funktion oder Amt: `EA_CREATE_REFERAT_REQUIRED` → „Bitte eine Funktion oder ein Amt in deinem Referat angeben.“ (statt `EA_RELATION_REQUIRED`; R3, US-EA-05 AK2, US-EA-10 AK5),
  - fremdes Referat: unverändert `EA_RELATION_FOREIGN_REFERAT`.
  - Codes eingetragen in contracts/error-codes.md der Administration. Die pgTAP-Tests der Administration (`140_volunteer_functions`), die die alten Codes prüfen, werden im selben Pull Request angepasst. Die spätere Erweiterung um die Anwesenheitserfassung (AD T53) baut auf dieser Fassung auf. Das Formular prüft R3 zusätzlich vor dem Aufruf.
- Übernommen aus spec.md Abschnitt 11 (kein Blocker): Karteileichen; Fördergeber und Förderart; Jahreskarte, Forms, Redaktion, Mailingliste; Amtszeit Jugendausschuss; „Mitarbeiter:in Mitgliederverwaltung“; Regelwerk Führungszeugnis-Einsicht. Text und Link zu Art. 13 DSGVO betreffen die Anwesenheitserfassung.

Hinweise (keine Entscheidung nötig):
- **H1 – Übergabe Ü1/Ü2:** Datenbankteil mit PR #15 umgesetzt; T073 und T081 der Administration berücksichtigen Ü1/Ü2 bereits (Branches `us-ad-07-person-anlegen`, `us-ad-12-eigenschaftsarten`). Beim Bau von T082/T083 (Eigenschaftsformular, Anzeige im Personendetail) die Bezeichnungen „gültig von/bis“ der Eigenschaftsart verwenden (spec.md AD T47, R49). tasks.md der Administration wird hier nicht geändert, weil parallel daran gearbeitet wird. Die Datei uebergabe-administration.md steht noch auf „offen“; sie als erledigt zu markieren ist eine fachliche Änderung (Branch `docs/…`, Product Owner).
- **H2 – Erwartete Ergebnisse spec.md Abschnitt 9:** In der Spalte `ea_v_expiry` Jahr 2027 nennt die Zeile Referent:in „nur Personen 4, 10, 19, 22“. Personen 10 und 22 haben keine Lizenz oder Qualifikation, und Lena (19) läuft am 22.10.2026 noch im Jahr 2026 ab. Der Test prüft deshalb „nur Personen aus {4, 10, 19, 22}“ mit der Erwartung aus `current_date` (research.md R-EA-06). Keine Änderung der Spec nötig.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| `SUPABASE_SERVICE_ROLE_KEY` in `.env.migration.local` (spec.md Abschnitt 7) | Das Skript braucht für den Import ohne Nutzerkontext einen Schlüssel mit vollen Rechten. | Nicht aufgelöst. Die Datei verstößt gegen Prinzip III. Vorschlag ohne Verstoß: Schlüssel nur in der Shell-Umgebung (O1). Entscheidung beim Product Owner; bis dahin ist T20 gesperrt. |
| `ea_import_volunteers` mit Grant an `service_role` statt `authenticated` | Schreiben ohne Nutzerkontext (Altbestand, Status) in einer Transaktion (A3) | Ein Grant an `authenticated` würde den Import für jeden Nutzer öffnen. Mehrere RPC-Aufrufe aus dem Skript wären keine Transaktion. Gleiches Muster wie `ad_apply_*`. |
