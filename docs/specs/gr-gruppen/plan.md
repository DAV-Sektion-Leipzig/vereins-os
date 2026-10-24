# Implementation Plan: Gruppen (GR)

**Branch**: `gr-plan` (Plan); Umsetzung auf den Branches aus Abschnitt „Branches“ | **Date**: 2026-10-24 | **Spec**: [spec.md](spec.md) v0.2 (Ready)

**Input**: [spec.md](spec.md) v0.2 (führend), [02-stories.md](02-stories.md) v0.8, [01-erhebung.md](01-erhebung.md) v0.7, [00-steckbrief.md](00-steckbrief.md) v0.7, [uebergabe-administration.md](uebergabe-administration.md) v1.0 (Ü1–Ü7), [uebergabe-nachtrag-administration.md](uebergabe-nachtrag-administration.md) v1.1, [spec.md Administration](../ad-administration/spec.md) v0.9.3, [plan.md Ehrenamtsmanagement](../ea-ehrenamt/plan.md), [spec.md Ehrenamtsmanagement](../ea-ehrenamt/spec.md) v0.2.1, [Constitution](../../../.specify/memory/constitution.md) v1.2.0

**Artefakte**: [research.md](research.md) · [data-model.md](data-model.md) · [contracts/](contracts/) · [quickstart.md](quickstart.md) · tasks.md (folgt mit `/speckit-tasks`)

## Summary

Gruppen löst die Excel-Datei des Kinder- und Jugendbereichs ab. Die Geschäftsstelle pflegt Gruppen, Trainingszeiten, Teilnehmer:innen, Erziehungsberechtigte, Notfallkontakte, Verträge mit SEPA-Mandat, Fotoerlaubnis und Gesundheitsangaben. Die Anwesenheitserfassung bekommt Gruppen, Trainingszeiten und Namenslisten zum Stichtag über eigene Lesefunktionen. Der Bestand kommt einmalig per Skript aus der Excel.

Technisch baut das Modul auf dem Personenmodell der Administration und den System-Eigenschaftsarten des Ehrenamtsmanagements auf. Anders als EA legt Gruppen eigene Tabellen an:
- 11 Tabellen `gr_*` mit RLS. Für `authenticated` gibt es nur `select`, geschrieben wird ausschließlich über `security definer`-Funktionen (spec.md 2).
- Ergänzungen an Objekten der Administration, die spec.md AD der ersten GR-Migration zuweist: `related_group_id`, `ea_properties_validate`/`_history`, `ea_property_writable` (R39), `gr_person_visible`/`gr_person_ids` (Ersatz der Platzhalter), System-Eigenschaftsart `group_function`.
- Vorgezogen aus der Übergabe an die Administration: Ü1 (`ea_set_status_from_group`) und Ü3 (`ad_v_person_overview` mit Gruppenbezug). Ü2 betrifft nur die Oberfläche.
- Lesefunktionen für die Oberfläche und die Anwesenheitserfassung, ein Import nur für `service_role`, Seed-Personen 23–32, pgTAP ab Nummer 410.
- Oberflächen unter /gr. Sie hängen den Dublettendialog und die Formular-Bausteine der Administration ein.
- Importskript `scripts/gr-import/` (TypeScript mit `tsx`, `exceljs`).

## Technical Context

**Language/Version**: SQL (PostgreSQL 17, Supabase); TypeScript (Frontend, Vite); TypeScript mit `tsx` (Importskript, Node)
**Primary Dependencies**: wie Administration und Ehrenamtsmanagement (Supabase, React 19, react-router-dom 7, @supabase/supabase-js 2, shadcn/ui, Tailwind v4, sonner). Neu nur für das Skript: `exceljs` (devDependency, kostenfrei)
**Storage**: 11 neue Tabellen `gr_*` in Schema `public`; Personen und Personenangaben in den Tabellen der Administration (`ea_persons`, `ea_properties`)
**Testing**: pgTAP in der GitHub Action `db-tests.yml` (lokaler Stack, Seed), Dateien ab `410_`; Mengentest mit 20 Gruppen und 400 Teilnehmer:innen; Probelauf des Skripts mit fiktiver `beispiel.xlsx`; fachliche Abnahme in TEST
**Target Platform**: Browser, mobil ab 375 px; Cloudflare Workers mit Static Assets; Supabase Free-Plan EU; Skript lokal beim Admin
**Project Type**: Web-Anwendung (statische SPA, Supabase als einziges Backend) plus lokales Kommandozeilen-Skript
**Performance Goals**: `gr_group_overview` und Gruppendetail < 1 s; `gr_group_roster` < 300 ms; `gr_person_visible` für 500 Personen in einer Liste < 1 s (spec.md 8)
**Constraints**: 0 €; RLS auf jeder Tabelle; keine Insert-/Update-/Delete-Grants auf `gr_`-Tabellen; Gesundheitsangaben nie über „Gruppen lesen“, den Pfad AD oder andere Module; keine Echtdaten; nie gegen PROD; kein Docker lokal (pgTAP nur in CI)
**Scale/Scope**: ca. 13 Gruppen, 150–200 Teilnehmer:innen, ca. 300 Erziehungsberechtigte und Notfallkontakte, 50 Betreuer:innen; 20 Stories; 19 Spec-Tasks (T1–T19)

## Constitution Check

*GATE: vor Phase 0 geprüft, nach Phase 1 erneut geprüft.*

| Prinzip | Prüfung | Ergebnis |
|---|---|---|
| I Fachliche Quelle | Plan setzt spec.md v0.2 um, nicht mehr. Artefakte liegen in `docs/specs/gr-gruppen/`. Begriffe nach glossar.md (Gruppe, Teilnehmer:in, Erziehungsberechtigte:r, Notfallkontakt, Vertrag, Trainingszeit, Referat). Technische Hilfsfunktionen, die die Spec nicht nennt, sind in research.md begründet (R-GR-05, R-GR-09) und ändern kein fachliches Verhalten. | ✅ |
| II Offene Punkte | O1 und O2 unten sind gemeldet, nicht entschieden. Die [ANNAHME]n aus spec.md 11 sind bestätigt. Die fünf [OFFEN]-Punkte vor Go-live aus spec.md 11 sind übernommen. | ✅ |
| III Sicherheit in der DB | RLS auf allen 11 Tabellen mit Select-Policy; Grants an `authenticated` nur `select` bzw. `execute`; Schreiben nur über `security definer`-Funktionen mit Rechteprüfung am Anfang; Gesundheitsangaben über eigene Policy `gr_can_read_health`; interne Funktionen (`gr_has_current_relation`, `gr_is_adult`, `ea_set_status_from_group`) ohne Grant an `authenticated` | ✅ |
| III, Ausnahme Import | `gr_import_groups` ist `security definer` mit Grant nur an `service_role`. Begründung wie `ea_import_volunteers`: Schreiben ohne Nutzerkontext in einer Transaktion (US-GR-16 AK4). | ✅ begründet |
| III/V Secrets | spec.md 7 sieht für das Skript `.env.migration.local` mit `SUPABASE_SERVICE_ROLE_KEY` vor. Das widerspricht Prinzip III („Secret Key nie in `.env`-Dateien“) und der Entscheidung zum EA-Skript (EA plan.md O1, 23.10.2026). | ❌ → O1 |
| IV Personenmodell/Historie | Personenangaben als Eigenschaften der System-Eigenschaftsarten; Funktion in Gruppe als Eigenschaft `group_function`. Trainingszeiten, Teilnahmen, Verträge, Funktionen mit gültig von/bis; Fotoerlaubnis, Einwilligung und Gesundheitsangaben mit Historie; kein Löschen im MVP. Löschlauf nach MVP (R15), Datenmodell vorbereitet. | ✅ |
| V Daten/Umgebungen | Seed fiktiv (Personen 23–32, `@dav-leipzig.de`-Testzugang, Beispiel-IBAN `DE89370400440532013000` und Varianten mit gültiger Prüfsumme); Excel und Berichte nie im Repository (`.gitignore`); Claude Code arbeitet nur gegen TEST; PROD-Lauf durch den Admin | ✅ |
| VI Einmal pflegen | Eine Person für alle Module (E1); keine Kopien von Personendaten in `gr_`-Tabellen; Adresse übernehmen kopiert einmalig in die Kontaktdaten des Kindes (A3, fachlich entschieden) | ✅ |
| VII Kostenfrei/einfach/mobil | nur Free-Pläne und freie npm-Pakete; Notfallkontakte mobil in zwei Schritten; Tabellen werden ab 375 px zu Karten; UI deutsch mit „du“ | ✅ |

**Gate-Ergebnis:** bestanden für Datenbank und Oberfläche (T1–T17, T19). **T18 (Importskript) ist gesperrt, bis O1 entschieden ist.** Das Gate betrifft nur die Art der Schlüsseleingabe, nicht die Datenbankfunktion `gr_import_groups`.

**Re-Check nach Phase 1:** data-model.md legt jede Tabelle mit RLS, Select-Policy und `grant select … to authenticated` an. Keine Insert-, Update- oder Delete-Policy auf `gr_`-Tabellen. Alle Funktionen haben `set search_path = ''`. Keine Grants an `anon`. Die Views haben `security_invoker = true`. Keine weiteren Verstöße.

## Project Structure

### Documentation (this feature)

```text
docs/specs/gr-gruppen/
├── 00-steckbrief.md, 01-erhebung.md, 02-stories.md, spec.md    (fachliche Quelle, nicht ändern)
├── uebergabe-administration.md, uebergabe-nachtrag-administration.md (fachlich)
├── plan.md              # diese Datei
├── research.md          # Phase 0
├── data-model.md        # Phase 1
├── quickstart.md        # Phase 1
├── contracts/           # database-api.md, error-codes.md, routes.md, import-script.md
└── tasks.md             # Phase 2 (/speckit-tasks)
```

Die Fehlercodes stehen normativ in [contracts/error-codes.md](contracts/error-codes.md) (spec.md 5, T2).

### Source Code (repository root)

```text
supabase/
├── migrations/                          # 20261025000100_gr_*.sql ff. nach data-model.md
├── tests/database/4x0_gr_*.test.sql     # T10 (research.md R-GR-14)
└── seed.sql                             # T9: Gruppen, Personen 23–32, Testzugang Kim Kinderjugend

scripts/gr-import/                       # T18 (gesperrt bis O1)
├── index.ts, run.ts, sheet.ts, training-times.ts, report.ts (+ *.test.ts)
└── beispiel.xlsx                        # fiktiv, alle Fälle
package.json                             # Script "gr:import", "gr:import:test"; devDependency exceljs
.gitignore                               # *.xlsx außer beispiel.xlsx, Prüf- und Abschlussberichte

src/
├── lib/            errors.ts (GR-Codes), format.ts (Wochentag, Uhrzeit, Alter)
└── features/
    ├── start/      modules.ts (Kachel GR nach T19)
    └── gr/
        ├── GrLayout.tsx, access.ts, routes.tsx                       # T11
        ├── gruppen/   GruppenPage, GruppeFormDialog, AuflösenDialog,
        │              GruppeDetailPage (Reiter Teilnehmer:innen, Betreuung, Trainingszeiten),
        │              TrainingszeitDialog, FunktionDialog, EmailListeButton  # T12, T13, T16
        ├── aufnahme/  AufnahmenPage, AufnahmeAssistent (5 Schritte)          # T14
        └── personen/  PersonPage (Notfallkontakte oben, Stammdaten, Erziehungsberechtigte,
                       Teilnahmen/Verträge, Fotoerlaubnis, Gesundheit)        # T15
```

**Structure Decision:** Wie Administration und Ehrenamtsmanagement: SPA in `src/`, Supabase in `supabase/`. Dublettendialog (`src/features/shared/DublettenDialog.tsx`, Prop `hitAction`) und Formular-Bausteine werden eingehängt, nicht kopiert. Neu ist `scripts/gr-import/` für das lokale Skript (spec.md 7).

## Voraussetzungen und Stand (geprüft 24.10.2026, main @ ada30f1)

| Voraussetzung (spec.md 10) | Stand | Folge |
|---|---|---|
| Kern der Administration T1–T49 inkl. Ü2 aus EA (`birth_year`) | erledigt (`20261020000100`–`20261023001800`); offen nur Abnahmen AD T102–T104 | – |
| Erste EA-Migration: System-Eigenschaftsarten `birth_date`, `contact`, `member`; `ea_iban_valid`, `ea_iban_normalize` | erledigt (`20261024000100`, `…000400`) | – |
| Platzhalter `gr_person_visible`, `gr_person_ids`; R39-Prüfung im Trigger | vorhanden (`20261023001000`, `…000900`) | werden in T1/T2 ersetzt |
| Ü1, Ü3 aus uebergabe-administration.md | nicht in spec.md AD eingearbeitet | laut Übergabe als vorgezogene Tasks der ersten GR-Migration erlaubt → T1/T2/T7 |
| Ü2 (Dublettendialog: „Vorhandene Person übernehmen“ auch für nicht sichtbare Treffer) | `ad_find_similar_persons` liefert `is_visible`; Dialog hat Prop `hitAction` | nur Oberfläche, T14 |
| Ü5: AD v0.8 T50 (Modul EZ in `ad_modules`, Startwerte EZ) und Reichweite „Referat“ für EZ (R30) | **nicht umgesetzt**; AD tasks.md schließt v0.8 aus; `ad_template_rights` lässt Reichweite „Referat“ nur für EA zu | → O2; betrifft die EZ-Pfade in T8, T9, T10 |
| Migrationsnummern | letzte auf `main`: `20261024000700`; `…000800` ist für EA T055 reserviert | GR beginnt mit `20261025000100` |

## Branches

Nach CLAUDE.md: je Story bzw. Aufgabe ein Branch. Was sich gegenseitig bedingt, kommt auf einen gemeinsamen Branch. Jeder Pull Request nennt Stories, Spec-Tasks und die Cloudflare-Vorschau-URL.

| # | Branch | Spec-Tasks | Stories | Inhalt | hängt ab von | Merge |
|---|---|---|---|---|---|---|
| 1 | `gr-plan` | – | – | plan.md, research.md, data-model.md, contracts/, quickstart.md; danach tasks.md | – | Auto |
| 2 | `gr-kern-datenbank` | T1–T7, T9, T10 (ohne T8-Teile) mit Ü1, Ü3 | 01, 03, 04, 06–13, 17, 18; Datenbankteil | Migrationen `…000100`–`…000700`, Seed, pgTAP 410–470, contracts/error-codes.md | – | Auto |
| 3 | `us-gr-19-lesefunktionen` | T8, T10 (Lesefunktionen, Mengentest) | 02, 05, 15, 19, 20 | Migration `…000800`, pgTAP 480–490; EZ-Pfade nach O2 | 2 | Auto |
| 4 | `us-gr-02-uebersicht` | T11 | 02 | Navigation, Routenschutz, /gr | 3 | PO |
| 5 | `us-gr-03-gruppe` | T12 | 03, 04, 18 | Anlegen, Ändern, Auflösen, Trainingszeiten | 4 | PO |
| 6 | `us-gr-05-gruppendetail` | T13 | 05, 15 | Gruppendetail, E-Mail-Liste | 4 | PO |
| 7 | `us-gr-06-aufnahme` | T14 | 06–10, 12 | Aufnahme-Assistent, /gr/aufnahmen, Dublettendialog (Ü2) | 6 | PO |
| 8 | `us-gr-14-person` | T15 | 07–12, 14 | Personendetail, Notfallansicht mobil, Verträge, Gesundheit | 6 | PO |
| 9 | `us-gr-13-betreuung` | T16, T17 | 13 | Betreuung, Anzeige im Ehrenamtsmanagement | 6 | PO |
| 10 | `us-gr-16-import` | T18 | 16 | `gr_import_groups` (Migration nach `20261027000100`), pgTAP 495, Skript inkl. G8 | 2, 13 | PO (Skript ist kein reiner DB-PR) |
| 11 | `gr-abnahme` | – | alle | Abnahme nach quickstart.md D; Anpassungen | 4–9 | PO |
| 12 | `gr-freischalten` | T19 | 02 | Migration `ad_modules.is_available = true` für GR | 11, Freigabe PO | Auto |
| 13 | `gr-trainingszeit-wochentag` | T20 | 16, 18, 19 | Übergabe EZ G6–G9: Migration `20261027000100`, pgTAP 410/480, Umsetzungsdateien | spec.md v0.3 | Auto |
| 14 | `gr-trainingszeit-dialog` | T20 (Oberfläche) | 18 | `TrainingszeitDialog.tsx` ohne Hinweis, `errors.ts` mit `GR_TRAINING_TIME_WEEKDAY_EXISTS` | 13 | PO |

Reihenfolge: 1 → 2 → 3 → 4 → 5, 6 → 7, 8, 9 → 11 → 12. Branch 10 parallel nach 2, sobald O1 entschieden ist.

## Umsetzungsentscheidungen (Kurzfassung, Details in research.md)

- **Schreiben nur über Funktionen** (R-GR-08): Alle Schreibfunktionen sind `security definer`, prüfen das GR-Recht als erste Anweisung und laufen als Eigentümer an RLS vorbei. `ea_property_writable` liefert für Arten mit Bezug „Gruppe“ immer `false`; der Trigger `ea_properties_validate` prüft R39 weiter für den Fall mit Nutzerkontext.
- **Ehrenamtsstatus aus Gruppen (Ü1, R-GR-04):** `ea_set_status_from_group` nutzt das vorhandene Kennzeichen `ea.status_change` des Triggers `ea_persons_guard`; der Trigger bleibt unverändert.
- **Gruppenbezug in der Personenübersicht (Ü3, R-GR-05):** `gr_has_current_relation` bleibt ohne Grant. Die View `ad_v_person_overview` (security invoker) ruft eine schmale Hülle `gr_person_has_group_relation`, die nur mit AD ≥ lesen antwortet.
- **Sichtbarkeit als Menge (R-GR-06):** `gr_person_ids` wird mengenbasiert neu geschrieben, damit die Policies auf `ea_persons` und `ea_properties` den Mengentest schaffen.
- **Datum (R-GR-03):** Gruppen rechnet mit `gr_today()` (Europe/Berlin). Funktionen der Administration bleiben bei `current_date`.
- **EZ-Rechte vor Ü5 (R-GR-11):** Die Lesefunktionen prüfen `ad_has_level('EZ', …)` und `ad_my_referate('EZ', …)` schon jetzt. Ohne Modul EZ liefern beide „kein Recht“; die Tests der EZ-Pfade hängen an O2.
- **Hinweis „unter 18 ohne Erziehungsberechtigte“ (R2, R-GR-09):** wird in der Datenbank berechnet (`gr_needs_guardian`), damit Nutzer ohne „Gruppen verwalten“ den Hinweis sehen, aber kein Alter.

## Offene Punkte

Gemeldet an den Product Owner. Nichts davon hat Claude Code entschieden.

- **O1 – Schlüssel des Importskripts (entschieden, Product Owner 24.10.2026: verdeckte Eingabe im Terminal wie beim EA-Skript).** Quelle: spec.md Abschnitt 7 („Umgebungsvariablen `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` aus `.env.migration.local`“) und US-GR-16. Widerspruch zu Constitution Prinzip III („Secret Key / `service_role` nie in `.env`-Dateien“) und zur Entscheidung für das EA-Skript (EA plan.md O1, EA spec.md v0.2.1 Abschnitt 7, 23.10.2026: Abfrage beim Start, verdeckte Eingabe, nur im Arbeitsspeicher; Probelauf und Lauf durch den Admin). Vorschlag: spec.md GR Abschnitt 7 und US-GR-16 wie EA v0.2.1 anpassen (Branch `docs/gr-import-schluessel`). Bis dahin ist T18 gesperrt.
- **O2 – Rechte der Anwesenheitserfassung vor der Umsetzung von T8 (Ü5; entschieden, Product Owner 24.10.2026: Variante b, EZ-Pfade als pgTAP-`todo`).** Quelle: uebergabe-administration.md Ü5; spec.md Abschnitt 10 („für T8 zusätzlich Administration v0.8 T50 … und Reichweite ‚Referat‘ für EZ“); spec.md AD Kopf (Nachtrag v0.8 Status „Entwurf“). Weder Modul EZ noch Reichweite „Referat“ für EZ gibt es auf `main`. Folge: `gr_group_roster` und `gr_groups_for_attendance` lassen sich bauen, aber nur über „Gruppen lesen“ nutzen; die Zeilen Rita Referentin, Kim Kinderjugend und „Admin … EZ lesen“ der Tabelle in spec.md 9 sind nicht testbar. Zur Wahl:
  - (a) AD v0.8 T50 und R30 für EZ vorher als eigener Branch umsetzen (setzt Freigabe des Nachtrags v0.8 voraus),
  - (b) T8 jetzt umsetzen, EZ-Pfade in pgTAP als `todo` führen und nachziehen, sobald AD v0.8 umgesetzt ist (Vorschlag; blockiert Gruppen nicht, weil die Anwesenheitserfassung ohnehin nach Gruppen kommt).
- Übernommen aus spec.md 11 (kein Blocker für die Umsetzung, vor Go-live zu klären): Einwilligung im Anmeldebogen; Rechtsgrundlage für Notfallkontakte ohne Erziehungsberechtigung; Löschfristen Vertrags-/Mandatsdaten mit Finanzen; Bankdaten für Gruppenleitung und Trainer:innen nach MVP; Speicherung von Gesundheitsangaben nach Widerruf (R24).

Hinweise (keine Entscheidung nötig):
- **H1 – Übergabe an die Administration:** Ü1 und Ü3 setzt Gruppen vorgezogen um (wie T0a/T0b beim Ehrenamtsmanagement), Ü2 in der Oberfläche (T14), Ü7 in T1. uebergabe-administration.md als erledigt zu markieren und spec.md AD nachzuziehen ist eine fachliche Änderung (Branch `docs/…`, Product Owner).
- **H2 – Code für „gültig bis vor gültig von“ bei Funktionen:** spec.md 2.3 nennt `EA_VALID_TO_BEFORE_FROM` „bzw. Text aus AD“. Den Code gibt es nicht; die Administration meldet `EA_VALID_RANGE` (Constraint `ea_properties_valid_range`). Gruppen nutzt `EA_VALID_RANGE`, wie es die Spec mit „bzw. Text aus AD“ zulässt.
- **H3 – `search_path`:** spec.md 2.3 nennt `search_path = public`. Alle Funktionen im Repository nutzen `''` mit vollständig qualifizierten Namen (AD research.md R-19). Gruppen folgt dem Repository; fachlich ohne Wirkung.
- **H4 – Technische Hilfsfunktionen ohne Nennung in der Spec:** `gr_person_has_group_relation` (Ü3, R-GR-05), `gr_needs_guardian` (R2, R-GR-09), `gr_v_pending_admissions` (Liste /gr/aufnahmen, R-GR-09) mit `gr_user_name` (Name der anlegenden Person), `gr_weekday_label`. Sie geben nichts preis, was die Spec nicht ohnehin zeigt.
- **H6 – Filter „aktiv ohne Funktion oder Amt“ im Ehrenamtsmanagement (entschieden, Product Owner 24.10.2026, wie vorgeschlagen; Migration `20261025000900`):** `ea_volunteer_list` zählt nur die Arten `function`, `position`, `committee` als Zuordnung. Betreuer:innen, die nur eine Funktion in einer Gruppe haben (Seed: Lars Lehrer, Sam Sechzehn), erscheinen deshalb unter „aktiv ohne Funktion oder Amt“. Quelle: EA spec.md (Filter, US-EA-03); GR spec.md R29 (Gruppen setzt „aktiv“). Vorschlag: `group_function` als Zuordnung mitzählen (EA-Migration, gleiche Signatur).
- **H7 – Übergabe aus der Anwesenheitserfassung (uebergabe-gruppen.md v1.0, spec.md v0.3, T20):** höchstens eine Trainingszeit je Gruppe und Wochentag; Umsetzung nach R-GR-17 (Ausschluss-Constraint und Prüfung in den Funktionen). Seed und Mengentest erfüllen die Regel bereits (Test 2: Mittwoch bis 31.12.2025 und ab 01.01.2026 nacheinander). Vor `db push` nach TEST wird lesend geprüft, ob dort Zeilen gegen die Regel verstoßen; sonst scheitert der Constraint. Wortlaut festgelegt (Product Owner 24.10.2026: Vorschlag von Claude Code übernehmen, „… in diesem Zeitraum …“). Offen in spec.md 11: Verlängern von „gültig bis“ (umgesetzt wie vorgeschlagen, weil G6 es ohnehin ausschließt), Import (G8, betrifft T048).
- **H5 – Rückgabe von `gr_dissolve_group`:** spec.md 2.3 nennt „Rückgabe `void`“ und zugleich, dass Funktionen und Trainingszeiten, die erst nach der Auflösung beginnen, „im Bericht zurückgegeben“ werden. Umgesetzt als jsonb mit dieser Liste (im Normalfall leer); contracts/database-api.md. Wenn die Spec `void` ohne Liste meint, genügt ein Hinweis an Claude Code.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| `gr_import_groups` mit Grant an `service_role` statt `authenticated` | Schreiben ohne Nutzerkontext in einer Transaktion (US-GR-16 AK4) | Ein Grant an `authenticated` würde den Import für jeden Nutzer öffnen; mehrere RPC-Aufrufe wären keine Transaktion. Gleiches Muster wie `ea_import_volunteers`. |
| Ersatz von Funktionen der Administration (`ea_properties_validate`, `ea_properties_history`, `ea_property_writable`, `gr_person_visible`, `gr_person_ids`, View `ad_v_person_overview`) per `create or replace` | spec.md AD weist diese Änderungen der ersten GR-Migration zu (Abgrenzung spec.md GR) | Eine eigene GR-Variante neben der AD-Fassung würde zwei Regeln für dieselbe Tabelle erzeugen. |
