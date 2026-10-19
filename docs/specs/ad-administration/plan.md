# Implementation Plan: Administration (AD)

**Branch**: `us-ad-01-ersteinrichtung` (Plan); Umsetzung je Story auf eigenem Branch | **Date**: 2026-10-19 | **Spec**: [spec.md](spec.md) v0.3

**Input**: [spec.md](spec.md) v0.3 (führend), [02-stories.md](02-stories.md) v0.3, [01-erhebung.md](01-erhebung.md) v0.5, [00-steckbrief.md](00-steckbrief.md) v0.9, [tech-stack.md](../../tech-stack.md) v0.5, [Constitution](../../../.specify/memory/constitution.md) v1.0.2

**Artefakte**: [research.md](research.md) · [data-model.md](data-model.md) · [contracts/](contracts/) · [quickstart.md](quickstart.md)

## Summary

AD liefert Login, Zugänge, Rechtevorlagen und die Grundstruktur des Personenmodells (Person, Eigenschaftsart, Eigenschaft).

Technisch besteht AD aus:
- sieben SQL-Migrationen in `supabase/migrations/`. Jede bringt RLS, Policies und Grants für ihre Tabellen mit.
- zwei Edge Functions (`ad-invite`, `ad-access`) für alles, was den Service-Schlüssel braucht.
- Trigger auf `auth.users`, die den Zugangsstatus an das Passwort koppeln.
- der Auth-Konfiguration als Code in `supabase/config.toml`.
- einem Seed über `seed.sh`.
- pgTAP-Tests in einer GitHub Action mit lokalem Stack.
- einer React-SPA mit den Routen aus spec.md Abschnitt 6.

Rechte werden ausschließlich in der Datenbank geprüft (`ad_has_level`). Das Frontend blendet nur aus.

## Technical Context

**Language/Version**: SQL (PostgreSQL 17, Supabase); TypeScript ~7.0 (Frontend); TypeScript/Deno (Edge Functions); Bash (`seed.sh`)
**Primary Dependencies**: Supabase (Auth, PostgREST, Edge Functions, pg_cron, pg_trgm, citext); React 19, react-router-dom 7, @supabase/supabase-js 2, shadcn/ui (radix-ui), Tailwind CSS v4, sonner; Vite 8 mit @cloudflare/vite-plugin
**Storage**: Supabase PostgreSQL, Schema `public`; Supabase Auth (`auth.users`)
**Testing**: pgTAP (`supabase test db`) in einer GitHub Action mit lokalem Supabase-Stack und Seed; fachliche Abnahme in TEST (T25); keine Frontend-Unit-Tests gefordert
**Target Platform**: Browser (mobil ab 375 px); Cloudflare Workers mit Static Assets (`*.workers.dev`); Supabase Free-Plan EU
**Project Type**: Web-Anwendung – statische SPA, Supabase als einziges Backend
**Performance Goals**: Personenübersicht bei 300 Personen < 1 s
**Constraints**: 0 €; keine Serverlogik bei Cloudflare; kein Docker lokal (Tests nur in CI); kein Supabase MCP; nie gegen PROD; Auth-Mails max. 30 je Stunde
**Scale/Scope**: 4 Nutzer in PROD, ca. 300 Personen, 16 Stories, 25 Tasks

## Constitution Check

*GATE: vor Phase 0 geprüft, nach Phase 1 erneut geprüft.*

| Prinzip | Prüfung | Ergebnis |
|---|---|---|
| I Fachliche Quelle | Plan setzt spec.md v0.3 um; alle Artefakte liegen in `docs/specs/ad-administration/`; Begriffe nach glossar.md | ✅ |
| II Offene Punkte | O1 gemeldet, nicht entschieden | ✅ |
| III Sicherheit in der DB | RLS und Policies in jeder Migration; `revoke` von `anon`/`public`; Grants an `authenticated`; interne Statusfunktionen nur an `service_role` (spec.md v0.3 Abschnitt 3); Edge Functions prüfen das JWT selbst | ✅ |
| IV Personenmodell/Historie | Eigenschaften als Zeilen mit `valid_from`/`valid_to`, Historie per Trigger. Die 5-Jahres-Löschung von Personen und Eigenschaften gehört laut spec.md Abschnitt 1 zu EA; AD löscht nur das Protokoll (R13) | ✅ |
| V Daten/Secrets/Umgebungen | Seed nur fiktiv über `seed.sh`, bricht bei PROD ab; Passwort aus `SEED_TEST_PASSWORD`; in TEST keine realen Adressen; CI ohne Projektzugang; PROD nur durch den Product Owner (O1) | ✅ |
| VI Automatisieren/einmal pflegen | pg_cron-Löschlauf; Fachmodule lesen `ea_v_persons`, keine Kopien | ✅ |
| VII Kostenfrei/einfach/mobil | nur Free-Pläne (GitHub Actions, Supabase, Cloudflare); Screens ab 375 px; UI deutsch mit „du“ | ✅ |

**Gate-Ergebnis:** bestanden. **Re-Check nach Phase 1:** data-model.md und contracts/ halten III ein: Jede Tabelle hat Policies, Protokoll und Zuweisungen haben keine Schreib-Grants, Statuswechsel laufen nur über Edge Functions und Trigger.

## Project Structure

### Documentation (this feature)

```text
docs/specs/ad-administration/
├── 00-steckbrief.md, 01-erhebung.md, 02-stories.md, spec.md   (fachliche Quelle)
├── plan.md              # diese Datei
├── research.md          # Phase 0
├── data-model.md        # Phase 1
├── quickstart.md        # Phase 1
├── contracts/           # edge-functions.md, database-api.md, error-codes.md (normativ), routes.md
└── tasks.md             # Phase 2 (/speckit-tasks)
```

`.specify/feature.json` zeigt auf `docs/specs/ad-administration`. Die Datei steht in `.specify/.gitignore` und wird nicht versioniert.

### Source Code (repository root)

```text
.github/workflows/db-tests.yml         # T7: lokaler Stack + seed.sh + supabase test db
supabase/
├── config.toml                        # T11 Auth; T23 [db.seed] enabled = false
├── templates/invite.html, recovery.html   # T11
├── migrations/                        # T1–T6, T8 (Dateinamen: data-model.md)
├── functions/_shared/, ad-invite/, ad-access/   # T9, T10
├── tests/database/*.test.sql          # T7
├── seed.sh, seed.sql                  # T23
└── setup/prod-bootstrap.sql           # T24 (Ausführung nur durch den Product Owner)

src/
├── main.tsx, App.tsx                  # Router (T12)
├── lib/  supabase.ts (vorhanden), errors.ts, format.ts, rights.ts
├── components/  ui/ (shadcn), layout/AppHeader.tsx, StatusBadge.tsx, ResponsiveTable.tsx
├── assets/willkommen.svg              # T14
└── features/
    ├── auth/   LoginPage, PasswortVergessenPage, PasswortSetzenPage   # T13
    ├── start/  StartPage, KeinZugriffPage                             # T12, T14
    └── ad/
        ├── personen/          Übersicht, Neu, Detail (Stammdaten, Zugang, Rechtevorlagen, Eigenschaften)   # T15–T19
        ├── rechtevorlagen/    Liste, Bearbeiten                        # T20
        ├── eigenschaftsarten/ Liste, Bearbeiten                        # T21
        └── protokoll/         ProtokollPage                            # T22
```

**Structure Decision**: Eine SPA in `src/` (bestehendes Gerüst) und Supabase in `supabase/`, Repo-Struktur nach tech-stack.md v0.5 Abschnitt 7.

## Umsetzung nach Tasks (spec.md Abschnitt 10)

Story-Reihenfolge nach 02-stories.md v0.3: 01 → 02 → 05 → 10 → 06 → 07 → 12 → 13 → 11 → 08 → 03 → 04 → 09 → 14 → 15 → 16. Die Datenbankteile aller Stories, auch von US-AD-10 und US-AD-11, entstehen mit US-AD-01.

### US-AD-01 Ersteinrichtung – Datenbank-Fundament

| Task | Inhalt | Stories |
|---|---|---|
| T1 | Erweiterungen, Enums, `ad_modules` + Stammdaten, `ad_user_level`, `ad_has_level` | 01, 05 |
| T2 | Personenmodell mit Triggern (Validierung, Historie, Datentyp-Sperre, Auswahlwerte, vertraulich nur AD), `ea_v_persons`, Policies | 07, 12, 13, 15 |
| T3 | Vorlagen, Rechte, Zuweisungen, Zugänge (inkl. R20-Trigger), Startvorlagen, `ad_my_modules`, `ad_assign_template`, `ad_revoke_template`, Policies | 01, 10, 11 |
| T4 | Protokoll, `ad_notice_acks`, Notfall-Funktionen (AD ≥ read), pg_cron 01:15 UTC, interne `ad_apply_*` | 14, 15 |
| T5 | Trigger auf `auth.users`: Insert (`auth_user_id`, `none` → `invited`), erstes Passwort (`invited` → `active`), Anmeldung des Notfall-Admins (Protokoll) | 01, 03, 15 |
| T6 | `ad_v_person_overview`, `ad_me()`, Abgleich aller Policies mit Abschnitt 3 | 06, 13, Kopfzeile |
| T8 | `ad_find_similar_persons` | 07 |
| T7 | pgTAP-Tests, wachsen mit T1–T8; Workflow `db-tests.yml` | alle Rechte-Fälle |
| T23 | `seed.sh` + `seed.sql` (wird für T7 in CI gebraucht, daher früh) | 16 |
| T24 | `prod-bootstrap.sql`, idempotent, parametrisiert; Anleitung Dashboard-Einladung und Zustellungstest (quickstart.md D) | 01 |

Abnahme: Die Action ist grün, `db push --linked` gegen TEST läuft ohne Fehler, der Seed in TEST ist vollständig.

### Weitere Stories

| # | Story | Tasks | Plan-Hinweise |
|---|---|---|---|
| 2 | US-AD-02 Anmelden/Abmelden | T11, T12, T13 | T11 inkl. `email_sent = 30` und deutscher Vorlagen; jeder Login-Fehler → R18 |
| 3 | US-AD-05 Startseite | T14 | Kacheln aus `ad_my_modules`; Name aus `ad_me()`; /kein-zugriff ohne Datenabfrage |
| 4 | US-AD-10 Rechtevorlagen | T20 | Matrix 9 Module × Stufe |
| 5 | US-AD-06 Übersicht | T15 | Suche und Filter; mobil als Karten; der Notfall-Hinweis kommt mit #15 |
| 6 | US-AD-07 Person anlegen | T16 | R4/R1 → `ad_find_similar_persons` → ggf. Warndialog → Insert |
| 7 | US-AD-12 Eigenschaftsarten | T21 | Art.-9-Hinweis; Datentyp gesperrt, solange Eigenschaften existieren |
| 8 | US-AD-13 Eigenschaften | T19 | nur Arten, deren „sichtbar in“ AD enthält; „beendet“; Historie aufklappbar |
| 9 | US-AD-11 Zuweisen/Entziehen | T18 | nur nicht zugewiesene Vorlagen anbieten; RPC |
| 10 | US-AD-08 Einladen | T9, T17 | contracts/edge-functions.md; Login-Adresse nur bei „kein Zugang“/„eingeladen“ bearbeitbar (R20) |
| 11 | US-AD-03 Einladung annehmen | T13 | token_hash-Flow (research.md R-04); Status über das Passwort (T5) |
| 12 | US-AD-04 Passwort vergessen | T13 | immer dieselbe Bestätigung |
| 13 | US-AD-09 Sperren/Entsperren | T10, T17 | Bestätigungsdialog mit dem Hinweis auf eine Stunde |
| 14 | US-AD-14 Protokoll | T22 | 50 Einträge je Seite, neueste zuerst |
| 15 | US-AD-15 Notfall-Admin | T15 | Hinweis in /ad, „Zur Kenntnis genommen“ |
| 16 | US-AD-16 Testzugänge | T23, T25 | Seed schon mit #1; hier fachliche Abnahme |
| – | Abnahme | T25 | quickstart.md C; alle `[PRÜFEN T25]` |

## Offene Punkte

- [OFFEN] **O1** Wie kommen Migrationen, Edge Functions und Auth-Konfiguration nach PROD: manuell durch den Product Owner oder per GitHub Action beim Merge auf `main`? Zu klären vor dem ersten PROD-Deployment; bis dahin wird PROD nicht angefasst. Betroffen sind T24 und US-AD-01 AK5. (spec.md Abschnitt 11; docs/offene-punkte.md)
- Übernommen aus spec.md Abschnitt 11 (kein Blocker): [OFFEN] Vertretung des Admin-Zugangs; [OFFEN] Löschung des Zugangs bei Löschung der Person nach der 5-Jahres-Regel (EA).

## Abweichungen und Widersprüche

Die Punkte W1–W14, A1–A5, P1 und O2–O4 aus der ersten Fassung dieses Plans sind mit spec.md v0.3 entschieden (spec.md Abschnitt 11). Offen bleibt nur O1, siehe oben.

## Complexity Tracking

Keine Verstöße gegen die Constitution.
