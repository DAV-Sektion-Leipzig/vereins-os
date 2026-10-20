---
description: "Tasks für das Modul Administration (AD)"
---

# Tasks: Administration (AD)

**Input**: [plan.md](plan.md), [spec.md](spec.md) v0.5 (führend), [02-stories.md](02-stories.md) v0.5, [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md), [Constitution](../../../.specify/memory/constitution.md) v1.1.1

**Tests**: Die Constitution verlangt eine test- und spec-getriebene Umsetzung mit pgTAP-Tests der RLS je Rechtevorlage (Arbeitsablauf Nr. 4). spec.md verlangt in T9 einen Test der Edge Function mit simuliertem Fehler. Deshalb steht vor jeder Datenbank-Migration und vor jeder Edge Function eine Test-Task. Die Tests müssen zuerst fehlschlagen. Für das Frontend fordert spec.md keine Tests; dort gilt die Abnahme in TEST (spec T25).

**Organisation**: Eine Phase je Story in der Reihenfolge aus 02-stories.md: 01 → 02 → 05 → 10 → 06 → 07 → 12 → 13 → 11 → 08 → 03 → 04 → 09 → 14 → 15 → 16. Die letzte Phase ist die Abnahme.

## Format: `- [ ] T### [P?] [US-AD-xx] (spec Tn) Beschreibung`

- **T###**: laufende Task-ID dieser Datei
- **[P]**: parallel ausführbar (andere Datei, keine offene Abhängigkeit)
- **[US-AD-xx]**: Story aus 02-stories.md
- **(spec Tn)**: Task-Nummer aus spec.md Abschnitt 10; „Teil“ bedeutet, dass nur ein Teil dieser spec-Task umgesetzt wird

## Regeln für alle Tasks

- **Nie gegen PROD.** Alle CLI-Befehle gehen nur gegen vereins-os-test oder gegen den lokalen Stack in der GitHub Action. Vor jedem Befehl mit `--linked` muss `npx supabase projects list` zeigen, dass TEST verknüpft ist.
- **Kein `supabase config push` und kein `supabase config diff`**, weder gegen TEST noch gegen PROD. `supabase/config.toml` gilt nur für den lokalen Stack (CI). Auth-Einstellungen in TEST und PROD stellt der Product Owner nach der Checkliste in `supabase/setup/README.md` im Dashboard ein.
- **Keine Einladungen an Seed-Adressen in TEST** (`test.*@dav-leipzig.de`): Sie erzeugen Bounces und verbrauchen das Mail-Limit. In TEST werden nur die eigenen Adressen des Product Owners eingeladen (T077).
- Jede Migration enthält für die Tabellen, Views und Funktionen, die sie anlegt: `enable row level security`, Policies, `revoke all … from anon, public` und `grant … to authenticated`. Für interne Funktionen gilt stattdessen `grant execute … to service_role`. Für `ad_test_login_domains` gibt es weder Policy noch Grant (Ausnahme in Constitution III).
- security-definer-Funktionen haben immer `set search_path = ''` und nutzen voll qualifizierte Namen.
- Datei `.env.local` nie lesen, anzeigen oder ändern. Keine Secrets, keine echten Adressen in Dateien.
- Fehlercodes und Meldungen nur aus [contracts/error-codes.md](contracts/error-codes.md).
- Commits auf Deutsch, auf dem Branch der jeweiligen Story.

---

## Phase 1: US-AD-01 Ersteinrichtung PROD (Priorität: Must) 🎯 MVP-Fundament

**Ziel**: Datenbank-Fundament mit Personen, Rechtevorlagen, Zugängen, Protokoll und Auth-Triggern; Seed und CI; Einrichtungsskript und Anleitung für PROD.

**Unabhängiger Test**: Die Action `db-tests.yml` ist grün. Das heißt:
- AK1: Startvorlagen nach den Migrationen vorhanden.
- AK3: `prod-bootstrap.sql` ist auf dem lokalen Stack zweimal hintereinander ausführbar und legt nichts doppelt an.
- AK4: Ein Nutzer ohne AD-Rechte kann die Vorlage „Admin“ nicht ändern.

Außerdem laufen `db push` und `seed.sh` gegen TEST ohne Fehler. AK2 und AK5 werden erst bei der Ersteinrichtung von PROD durch den Product Owner geprüft (O1).

### Infrastruktur für US-AD-01

- [X] T001 [US-AD-01] (spec T7 Teil, T23 Teil) Leere Verzeichnisse mit `.gitkeep` anlegen: `supabase/tests/database/`, `supabase/tests/bootstrap/`, `supabase/setup/`, `supabase/templates/`, `.github/workflows/`
- [X] T002 [US-AD-01] (spec T23 Teil) `supabase/config.toml`: `[db.seed] enabled = false` setzen (sonst führen `supabase start`/`db reset` die Datei `seed.sql` ohne psql-Variable aus). In `.env.example` die Zeile `SEED_DB_URL=` ergänzen (leer, mit Kommentar „Verbindung zu TEST; nie PROD“)
- [X] T003 [US-AD-01] (spec T7 Teil) Workflow `.github/workflows/db-tests.yml` anlegen:
  - Auslöser `pull_request`. Supabase CLI über `supabase/setup-cli`, Deno über `denoland/setup-deno`.
  - `supabase start`
  - Block A (Einrichtungsskript): `supabase db reset` → `psql "$DB_URL" -v ON_ERROR_STOP=1 -v admin_first=Erika -v admin_last=Beispiel -v admin_email=erika.beispiel@dav-leipzig.de -f supabase/setup/prod-bootstrap.sql` zweimal hintereinander → `supabase test db supabase/tests/bootstrap`
  - Block B (Rechte und Seed): `supabase db reset` → `supabase/seed.sh` mit `SEED_DB_URL=$DB_URL` (aus `supabase status -o env`) und `SEED_TEST_PASSWORD` aus dem GitHub-Secret → `supabase test db supabase/tests/database`
  - `deno test supabase/functions`, sobald Tests vorhanden sind
  - Keine Projekt-Secrets und kein Zugriff auf TEST oder PROD.

### Tests für US-AD-01 (zuerst schreiben, müssen fehlschlagen) ⚠️

- [X] T004 [P] [US-AD-01] (spec T7 Teil) `supabase/tests/database/010_foundation.test.sql` (pgTAP, `begin; … rollback;`). Prüft:
  - Erweiterungen `citext`, `pg_trgm`, `pg_cron` sind vorhanden.
  - Enum-Werte exakt: `ad_level` = `none`,`read`,`edit`,`manage` in dieser Reihenfolge; `ad_access_status` = `none`,`invited`,`active`,`locked`; `ea_person_kind` = `human`,`function`; `ad_audit_action` = `invited`,`email_changed`,`template_assigned`,`template_revoked`,`locked`,`unlocked`,`emergency_login`.
  - `ad_modules` hat 9 Zeilen; nur `AD` hat `is_available = true`.
  - Jede Tabelle in `public` hat `relrowsecurity = true`.
  - `anon` hat auf keine Tabelle, View oder Funktion in `public` ein Recht.
- [X] T005 [P] [US-AD-01] (spec T7 Teil) `supabase/tests/database/020_persons_rights.test.sql`. Rollenwechsel über `set local role authenticated` und `set local request.jwt.claims` auf die Seed-Testzugänge (feste UUIDs aus T015). Prüft:
  - Startvorlagen-Matrix nach spec.md Abschnitt 3.
  - `ad_user_level`: Geschäftsstelle + Vorstand ergibt je Modul die höchste Stufe (R6); `none` ohne Zugang mit Status `active` (R5); eine entzogene oder abgelaufene Zuweisung wirkt nicht.
  - Ein Nutzer ohne AD-Rechte kann `ad_templates`/`ad_template_rights` von „Admin“ nicht ändern (US-AD-01 AK4).
  - Neue Vorlage: Trigger legt 9 Zeilen `none` an; doppelter Name ohne Groß-/Kleinschreibung → `ad_templates_name_key`.
  - `ad_template_assignments`: kein direkter Insert für `authenticated`; `ad_assign_template`/`ad_revoke_template` nur mit AD ≥ edit, sonst `AD_FORBIDDEN`; Zuweisen schreibt `template_assigned`, Entziehen `template_revoked`; erneutes Zuweisen erzeugt keinen zweiten Eintrag.
  - `ad_my_modules` liefert nur Module mit `is_available` und Stufe ≥ `read`.
  - `ea_persons`: Lesen mit AD ≥ read alle, mit EA ≥ read nur `kind = 'human'`; Anlegen nur mit AD ≥ edit oder EA ≥ edit (`function` nur AD); leerer Name → `AD_NAME_REQUIRED`.
  - `ea_v_persons` enthält keine Funktionsperson (R15).
  - `ad_audit_log` für `authenticated` ohne insert/update/delete.
- [X] T006 [P] [US-AD-01] (spec T7 Teil) `supabase/tests/database/030_auth_triggers.test.sql`. Prüft:
  - Insert in `auth.users` mit passender `login_email` setzt `auth_user_id` und Status `none` → `invited`.
  - Update von `encrypted_password` von leer auf einen Hash setzt `invited` → `active`; ohne Passwort bleibt der Status `invited`.
  - Update von `last_sign_in_at` bei `is_emergency` schreibt `emergency_login` mit `actor_user_id = id` des Nutzers.
  - R1: Login-Adresse `x@example.test` → `AD_EMAIL_DOMAIN`. Nach `insert into ad_test_login_domains values ('example.test')` (nur in dieser Transaktion) ist sie erlaubt.
  - `authenticated` erhält beim `select` auf `ad_test_login_domains` einen Rechtefehler.
  - R20: `login_email` ändern ist bei `none` erlaubt, bei `invited` (direkt) → `AD_EMAIL_CHANGE_VIA_FUNCTION`, bei `active`/`locked` → `AD_EMAIL_LOCKED`.
  - R2: doppelte Login-Adresse → `ad_accesses_login_email_key`.
  - Rollenfall: `authenticated` mit AD ≥ edit (test.admin) legt einen Zugang mit gültiger `@dav-leipzig.de`-Adresse an und ändert ihn bei Status `none`, ohne Rechtefehler (der Trigger liest `ad_test_login_domains` als security definer).
- [X] T007 [P] [US-AD-01] (spec T6 Teil) `supabase/tests/database/050_policies.test.sql`: `policies_are` bzw. `table_privs_are` je Tabelle aus T009–T013, abgeglichen mit spec.md Abschnitt 3 (Lesen, Anlegen, Ändern, Löschen je Tabelle). `ad_test_login_domains` hat keine Policy und keinen Grant.
- [X] T008 [P] [US-AD-01] (spec T7 Teil, T24 Teil) `supabase/tests/bootstrap/010_prod_bootstrap.test.sql` (läuft nach dem doppelten Bootstrap in Block A von T003). Prüft:
  - genau 1 Person „Erika Beispiel“ mit Zugang `erika.beispiel@dav-leipzig.de`, Status `none`, wirksamen Vorlagen Admin und Vorstand;
  - genau 1 Funktionsperson „Geschäftsstelle“ / „Notfall-Admin“ (`kind = 'function'`) mit Zugang `geschaeftsstelle@dav-leipzig.de`, `is_emergency = true`, Vorlage Admin;
  - Vorlagen nicht doppelt (US-AD-01 AK2, AK3);
  - nach einem Insert in `ad_test_login_domains` bricht das Skript mit einer Fehlermeldung ab (über `throws_ok` bzw. einen Funktionsaufruf des Prüfblocks).

### Umsetzung für US-AD-01

- [X] T009 [US-AD-01] (spec T1) Migration `supabase/migrations/20261020000100_ad_foundation.sql`:
  - Erweiterungen `citext`, `pg_trgm`, `pg_cron`.
  - Enums `ad_level`, `ad_access_status`, `ea_data_type` (`text`,`date`,`boolean`,`choice`), `ea_person_kind`, `ad_audit_action` exakt nach spec.md Abschnitt 2, mit `grant usage … to authenticated`.
  - `ad_modules` (code PK, name, sort_order, is_available default false), Stammdaten AD, SC, EA, GR, FI, OA, PM, GS, AM (nur AD `true`), Policy select für `authenticated`.
  - `ad_user_level(p_module text) returns ad_level` und `ad_has_level(p_module text, p_min ad_level) returns boolean` als plpgsql, security definer, stable: höchste Stufe aller wirksamen Zuweisungen; `none`, wenn kein Zugang mit Status `active` (R5, R6).
- [X] T010 [US-AD-01] (spec T2 Teil) Migration `supabase/migrations/20261020000200_ea_persons.sql`:
  - `ea_persons` (id uuid default gen_random_uuid(), first_name, last_name, kind default `human`, created_at, created_by default auth.uid()).
  - Checks `btrim(first_name) <> ''` und `btrim(last_name) <> ''`; Trigger `ea_persons_normalize` (trimmen, `AD_NAME_REQUIRED`).
  - Indizes `gin (first_name gin_trgm_ops)`, `(lower(last_name))`.
  - Policies nach data-model.md; Grants `select`, `insert/update (first_name, last_name, kind)`.
  - View `ea_v_persons` (`security_invoker = true`, `where kind = 'human'`).
- [X] T011 [US-AD-01] (spec T3) Migration `supabase/migrations/20261020000300_ad_rights.sql`:
  - Tabelle `ad_templates`: Unique-Index `lower(name)` mit Namen `ad_templates_name_key`; Audit-Spalten.
  - Tabelle `ad_template_rights`:
    - Checks `object is null` und `scope = 'all'`; Unique `(template_id, module_code, coalesce(object,''))`; Grant nur `update (level)`.
    - Trigger `ad_templates_init_rights` (legt je Modul eine Zeile `none` an).
    - Startvorlagen per `on conflict do nothing`: Admin = AD, SC, EA `manage`; Geschäftsstelle = EA, GR, FI, OA, PM, GS, AM `manage`; Vorstand = alle `none`.
  - Tabelle `ad_template_assignments`: partieller Unique-Index `(person_id, template_id) where revoked_at is null`; nur select-Grant.
  - Tabelle `ad_accesses`:
    - person_id unique; `login_email citext`, unique `ad_accesses_login_email_key`, **kein Check-Constraint für R1**.
    - `auth_user_id` FK `auth.users(id) on delete set null`, unique; partieller Unique-Index `where is_emergency`.
    - Grants `select`, `insert (person_id, login_email)`, `update (login_email)`.
  - Funktionen `ad_my_modules()`, `ad_assign_template(p_person, p_template)`, `ad_revoke_template(p_person, p_template)` (security definer, AD ≥ edit sonst `AD_FORBIDDEN`, Protokoll mit Vorlagenname in `details`).
  - Policies nach spec.md Abschnitt 3.
- [X] T012 [US-AD-01] (spec T4 Teil) Migration `supabase/migrations/20261020000400_ad_audit_log.sql`:
  - `ad_audit_log` (id bigint identity, occurred_at default now(), actor_user_id default auth.uid() **ohne FK**, subject_person_id FK ea_persons, action ad_audit_action, details).
  - Indizes `(occurred_at desc)`, `(action, occurred_at desc)`.
  - Policy select AD ≥ read; Grant nur `select`.
- [X] T013 [US-AD-01] (spec T5) Migration `supabase/migrations/20261020000500_ad_auth_triggers.sql`:
  - Tabelle `ad_test_login_domains` (domain citext PK ohne „@“, created_at): RLS an, `revoke all … from anon, authenticated, public`, keine Policy, kein Grant.
  - Funktion `ad_login_email_allowed(p_email citext) returns boolean` (security definer mit `set search_path = ''`, stable; `@dav-leipzig.de` oder Domain in `ad_test_login_domains`; `grant execute … to service_role`).
  - Trigger `ad_accesses_guard` (before insert or update of login_email):
    - security definer mit `set search_path = ''` (liest `ad_test_login_domains`, die `authenticated` nicht lesen darf); R1 → `AD_EMAIL_DOMAIN`.
    - R20: bei `invited` nur mit `current_setting('ad.email_change', true) = 'on'`, sonst `AD_EMAIL_CHANGE_VIA_FUNCTION`; bei `active`/`locked` → `AD_EMAIL_LOCKED`.
  - Drei Trigger auf `auth.users` nach research.md R-06: after insert; after update of encrypted_password; after update of last_sign_in_at mit `emergency_login`.
  - Keine Grants auf Trigger-Funktionen.
- [X] T014 [US-AD-01] (spec T23 Teil) Skript `supabase/seed.sh` (ausführbar, Bash, `set -euo pipefail`):
  - Liest `.env.local` nur, wenn die Datei existiert (`set -a; . ./.env.local`), ohne Werte auszugeben.
  - Bricht ab, wenn `SEED_TEST_PASSWORD` oder `SEED_DB_URL` fehlen.
  - Liest die Project Ref aus `SEED_DB_URL` (`db.<ref>.supabase.co` bzw. Benutzer `postgres.<ref>`; lokaler Stack `127.0.0.1`/`localhost` hat keine Ref). Ist es die PROD-Ref (Konstante `PROD_PROJECT_REF` im Skript, der Product Owner trägt den Wert ein): Ausgabe „Seed in PROD nicht erlaubt.“ und Exit 1. Solange die Konstante leer ist, bricht das Skript bei jeder entfernten Verbindung mit derselben Meldung ab (lieber zu streng als PROD).
  - Dann `psql "$SEED_DB_URL" -v ON_ERROR_STOP=1 -v test_password="$SEED_TEST_PASSWORD" -f supabase/seed.sql`.
- [X] T015 [US-AD-01] (spec T23 Teil) `supabase/seed.sql` (nur fiktive Daten nach spec.md Abschnitt 9, feste UUIDs, idempotent):
  - Personen 1–8.
  - `ad_accesses` mit Zielstatus (`active`, `invited`, `locked`, Notfall `is_emergency` mit `test.notfall@dav-leipzig.de`).
  - Zuweisungen nach Tabelle.
  - `auth.users` und `auth.identities` für die Zugänge 1, 2, 3, 6, 7, 8. Passwort `crypt(:'test_password', gen_salt('bf'))` außer bei Eva Eingeladen (leeres Passwort); `banned_until` für Dieter Gesperrt.
  - Protokoll je ein Eintrag `invited`, `template_assigned`, `locked`, `emergency_login`.
  - Reihenfolge nach research.md R-10. Eigenschaften folgen in T049.
- [X] T016 [US-AD-01] (spec T11 Teil) Für den **lokalen Stack (CI)** in `supabase/config.toml`: `[auth.rate_limit] email_sent = 30`; `[auth.email.template.invite]` mit deutschem Betreff „Einladung ins Vereins OS“ und `content_path = "./supabase/templates/invite.html"`. Datei `supabase/templates/invite.html` anlegen: nur kurzer Hinweistext und Link `{{ .SiteURL }}/passwort-setzen?token_hash={{ .TokenHash }}&type=invite`, keine Personendaten. Diese HTML-Datei überträgt der Product Owner per Checkliste (T018) ins Dashboard von TEST und PROD; nötig für die Dashboard-Einladung (US-AD-01 AK2, AK5). Kein `config push`.
- [X] T017 [US-AD-01] (spec T24) Skript `supabase/setup/prod-bootstrap.sql` (psql-Variablen `admin_first`, `admin_last`, `admin_email`):
  - Bricht ab, wenn eine Variable fehlt oder `exists (select 1 from public.ad_test_login_domains)`.
  - Läuft idempotent in einer Transaktion: Person Admin (`human`) mit Zugang `admin_email`, Status `none`, Zuweisungen Admin und Vorstand. Funktionsperson „Geschäftsstelle“ / „Notfall-Admin“ (`function`) mit Zugang `geschaeftsstelle@dav-leipzig.de`, `is_emergency = true`, Zuweisung Admin. Protokoll `template_assigned` mit `actor_user_id` null.
  - Keine Namen echter Personen im Skript.
  - **Nur erzeugen, nie ausführen** (außer gegen den lokalen Stack in CI).
- [X] T018 [US-AD-01] (spec T24) Anleitung `supabase/setup/README.md` für den Product Owner, Schritte nach quickstart.md D:
  - Migrationen und Edge Functions nach PROD bringen: Weg [OFFEN] O1. Auth-Einstellungen nach der Checkliste unten.
  - SMTP im PROD-Dashboard eintragen.
  - `prod-bootstrap.sql` mit den Parametern ausführen.
  - Erste Einladung über das Dashboard; Status „eingeladen“ prüfen.
  - Zustellungstest Einladung und „Passwort vergessen“ (Posteingang, nicht Junk).
  - Notfall-Admin über AD einladen.
  - Hinweis oben: „Nur durch den Product Owner. Claude Code führt nichts gegen PROD aus.“
  - **Checkliste „Auth-Einstellungen im Dashboard“** (je für TEST und PROD abhaken, da `config.toml` nur für den lokalen Stack gilt und nie per `config push` übertragen wird):
    - Authentication → Sign In / Providers: Selbstregistrierung aus (`enable_signup = false`), E-Mail-Anmeldung an.
    - Passwort-Mindestlänge 8 (`minimum_password_length = 8`), keine weiteren Zeichenregeln.
    - Rate Limits: E-Mails je Stunde 30 (`email_sent = 30`).
    - URL-Konfiguration: Site URL und Redirect-URLs wie in `supabase/config.toml` (`[auth]`), für TEST mit Vorschau- und lokaler Adresse.
    - E-Mail-Vorlagen „Invite user“ und „Reset password“: Betreff deutsch, Inhalt aus `supabase/templates/invite.html` bzw. `recovery.html` kopieren.
    - SMTP: Google-Konto der Sektion, App-Passwort nur hier, Absendername „Vereins OS“.
- [X] T019 [US-AD-01] (spec T1, T3, T5, T23 Teil) Gegen TEST ausrollen (nach Prüfung, dass TEST verknüpft ist):
  - `npx supabase db push --linked --dry-run`, dann `npx supabase db push --linked`.
  - Kein `config push`/`config diff`. Den Product Owner bitten, die Checkliste „Auth-Einstellungen im Dashboard“ (T018) für TEST abzuarbeiten.
  - `supabase/seed.sh` gegen TEST. Ergebnis kurz in der PR-Beschreibung festhalten.

**Checkpoint**: Action grün, TEST mit Schema und Seed. Die Datenbankteile von US-AD-10 und US-AD-11 sind fertig.

---

## Phase 2: US-AD-02 Anmelden und abmelden (Must)

**Ziel**: Login, Abmelden, Routenschutz, Kopfzeile mit Namen.

**Unabhängiger Test**:
- test.admin meldet sich an und landet auf / (AK1).
- Falsches Passwort und test.gesperrt zeigen die R18-Meldung (AK2, AK3).
- „Abmelden“ führt zu /login (AK4).
- /ad ohne Sitzung führt zu /login (AK5).

### Tests für US-AD-02 ⚠️

- [X] T020 [P] [US-AD-02] (spec T7 Teil, T6 Teil) `supabase/tests/database/060_ad_me.test.sql`: `ad_me()` liefert für test.admin, test.geschaeftsstelle und test.vorstand jeweils genau die eigene Person mit Status; ohne Zugang keine Zeile; keine fremden Daten.

### Umsetzung für US-AD-02

- [X] T021 [US-AD-02] (spec T6 Teil) Migration `supabase/migrations/20261020000600_ad_me.sql`: `ad_me() returns table (person_id uuid, first_name text, last_name text, access_status ad_access_status)`, security definer, stable, nur über `ad_accesses.auth_user_id = auth.uid()`; `grant execute … to authenticated`
- [X] T022 [US-AD-02] (spec T11 Teil) `supabase/config.toml`:
  - `[auth.email.template.recovery]` mit Betreff „Passwort zurücksetzen“ und `content_path = "./supabase/templates/recovery.html"`; Datei `supabase/templates/recovery.html` mit Link `{{ .SiteURL }}/passwort-setzen?token_hash={{ .TokenHash }}&type=recovery`.
  - Prüfen: `enable_signup = false` und `minimum_password_length = 8`.
  - In `supabase/setup/README.md` einen Abschnitt „SMTP (TEST und PROD)“ ergänzen: Google-Konto der Sektion, App-Passwort nur im Dashboard, Absendername „Vereins OS“.
  - Kein `config push`/`config diff`. `recovery.html` in die Checkliste aus T018 aufnehmen; der Product Owner überträgt sie ins Dashboard von TEST.
- [X] T023 [P] [US-AD-02] (spec T12) `src/lib/errors.ts`: Abbildung aller Codes und Constraint-Namen aus contracts/error-codes.md auf die Meldungen. `AD_EMAIL_CHANGED` liefert die Art „Hinweis“ statt „Fehler“, SQLSTATE `42501` die Rechte-Meldung, alles Unbekannte die allgemeine Meldung.
- [X] T024 [P] [US-AD-02] (spec T12) `src/lib/format.ts`: Datum TT.MM.JJJJ und Zeit HH:MM mit `Intl.DateTimeFormat('de-DE', { timeZone: 'Europe/Berlin' })`
- [X] T025 [P] [US-AD-02] (spec T12) `src/lib/rights.ts`: `requireSession()` (redirect `/login`), `requireLevel(module, min)` über `rpc('ad_has_level')` (redirect `/kein-zugriff`, bevor Daten geladen werden), `loadMe()` über `rpc('ad_me')`
- [X] T026 [US-AD-02] (spec T12) Router in `src/App.tsx` und `src/main.tsx` mit `createBrowserRouter`:
  - Öffentliche Routen /login, /passwort-vergessen, /passwort-setzen.
  - Geschützter Bereich mit Loader `requireSession` für / und /kein-zugriff.
  - Bereich /ad/* mit Loader `requireLevel('AD','read')`.
  - Platzhalter-Seiten für noch nicht umgesetzte Routen.
- [X] T027 [US-AD-02] (spec T12) `src/components/layout/AppHeader.tsx`: „Vereins OS“ (Link /), Modulname, Name aus `ad_me()`, Knopf „Abmelden“ (`auth.signOut()` → /login); ab 375 px ohne horizontales Scrollen
- [X] T028 [P] [US-AD-02] (spec T12) `src/features/start/KeinZugriffPage.tsx`: „Für diesen Bereich hast du keine Rechte.“ und Knopf „Zur Startseite“
- [X] T029 [US-AD-02] (spec T13 Teil) `src/features/auth/LoginPage.tsx`: Felder Login-Adresse und Passwort, Knopf „Anmelden“, Link „Passwort vergessen“. `signInWithPassword`; **jeder** Fehler zeigt „Anmeldung fehlgeschlagen. Bitte E-Mail-Adresse und Passwort prüfen.“ (R18); Erfolg → /; mit Sitzung → /

**Checkpoint**: Login, Abmelden und Routenschutz funktionieren mit den Seed-Zugängen in TEST.

---

## Phase 3: US-AD-05 Startseite mit Modulen nach Rechten (Must)

**Ziel**: Startseite mit Willkommensgrafik und Kacheln nach Rechten.

**Unabhängiger Test**:
- test.admin sieht nur die Kachel AD (AK1).
- test.vorstand sieht „Für dich sind noch keine Module freigeschaltet.“ (AK2).
- test.geschaeftsstelle sieht auf /ad die Kein-Zugriff-Seite, ohne dass Daten abgefragt werden (AK3).
- Breite 375 px funktioniert (AK5).

- [ ] T030 [P] [US-AD-05] (spec T14) Platzhalterbild `src/assets/willkommen.svg` (neutral, ohne Personen oder Logos Dritter)
- [ ] T031 [US-AD-05] (spec T14) `src/features/start/StartPage.tsx`: Willkommensgrafik, Kacheln aus `rpc('ad_my_modules')` (Link je Modul, AD → /ad), leerer Zustand „Für dich sind noch keine Module freigeschaltet.“; Daten bei jedem Aufruf neu laden (AK4)

**Checkpoint**: Die Startseite zeigt je Testzugang die richtigen Kacheln.

---

## Phase 4: US-AD-10 Rechtevorlage anlegen und ändern (Must)

**Ziel**: Oberfläche für Rechtevorlagen. Die Datenbank-Seite ist mit T011 fertig und mit T005 getestet (AK4).

**Unabhängiger Test**: test.admin legt eine Vorlage an, ändert eine Stufe der Vorlage Vorstand und erhält bei einem doppelten Namen „Eine Rechtevorlage mit diesem Namen gibt es bereits.“ (AK1–AK3).

- [ ] T032 [US-AD-10] (spec T20 Teil) `src/features/ad/AdLayout.tsx`: AD-Navigation (Personen, Rechtevorlagen, Eigenschaftsarten, Protokoll), Unterrouten in `src/App.tsx` eintragen; Schreibknöpfe nur bei `ad_has_level('AD','edit')`
- [ ] T033 [P] [US-AD-10] (spec T20) `src/features/ad/rechtevorlagen/RechtevorlagenListe.tsx`: Spalten Name, Beschreibung, Anzahl Personen (wirksame Zuweisungen); Knöpfe „Neu“ und „Öffnen“; mobil als Karten
- [ ] T034 [US-AD-10] (spec T20) `src/features/ad/rechtevorlagen/RechtevorlageBearbeiten.tsx` (/ad/rechtevorlagen/neu und /:id): Name, Beschreibung, Matrix mit 9 Modulen und je einer Auswahl „kein Zugriff / lesen / bearbeiten / verwalten“; Speichern (insert/update `ad_templates`, update `ad_template_rights.level`); Fehler über `errors.ts`

**Checkpoint**: Vorlagen sind über die Oberfläche pflegbar.

---

## Phase 5: US-AD-06 Übersicht Personen und Zugänge (Must)

**Ziel**: Personenübersicht mit Status, Vorlagen, Suche und Filter.

**Unabhängiger Test**:
- test.admin sieht 8 Personen mit Status und Vorlagen; die Funktionsperson ist gekennzeichnet (AK1, AK3).
- Suche nach „Muster“ und Filter „gesperrt“ funktionieren; wenn nichts passt, erscheint „Keine Personen gefunden.“ (AK2, AK4).
- test.geschaeftsstelle erhält keine Daten (AK5).

### Tests für US-AD-06 ⚠️

- [ ] T035 [P] [US-AD-06] (spec T7 Teil) `supabase/tests/database/070_person_overview.test.sql`: `ad_v_person_overview` liefert `access_status = 'none'` für Personen ohne Zugang und nur wirksame Vorlagen; test.geschaeftsstelle und test.vorstand erhalten 0 Zeilen; die Funktionsperson ist enthalten und als `function` gekennzeichnet

### Umsetzung für US-AD-06

- [ ] T036 [US-AD-06] (spec T6 Teil) Migration `supabase/migrations/20261020000700_ad_person_overview.sql`: View `ad_v_person_overview` (`security_invoker = true`): person_id, first_name, last_name, kind, login_email, `coalesce(status,'none') as access_status`, Array der Namen wirksamer Vorlagen; `grant select … to authenticated`
- [ ] T037 [P] [US-AD-06] (spec T15 Teil) `src/components/StatusBadge.tsx` (kein Zugang / eingeladen / aktiv / gesperrt) und `src/components/ResponsiveTable.tsx` (Tabelle ab 640 px, darunter Karten)
- [ ] T038 [US-AD-06] (spec T15) `src/features/ad/personen/PersonenUebersicht.tsx` (/ad): Name, Kennzeichen „Funktionsperson“, Login-Adresse, Status-Badge, Vorlagen; Suche nach Namensteil; Filter Status; „Keine Personen gefunden.“; Knöpfe „Person anlegen“ und „Öffnen“; < 1 s bei 300 Personen

**Checkpoint**: Die Übersicht zeigt die Seed-Daten.

---

## Phase 6: US-AD-07 Person anlegen mit Dublettenwarnung (Must)

**Ziel**: Person anlegen mit Dublettenprüfung und optionaler Login-Adresse.

**Unabhängiger Test**:
- „Erika Neu“ wird ohne Warnung angelegt (AK1).
- „Anton Muster“ bzw. „Tony Muster“ lösen den Warndialog aus (AK3); „Trotzdem anlegen“ legt die Person an (AK4).
- Ein leerer Name, eine fremde Domain oder eine doppelte Login-Adresse führen zu den Meldungen aus R4, R1 und R2 (AK2, AK5).

### Tests für US-AD-07 ⚠️

- [ ] T039 [P] [US-AD-07] (spec T7 Teil) `supabase/tests/database/080_find_similar.test.sql`:
  - `ad_find_similar_persons('Anton','Muster',null)` und `('Tony','Muster',null)` finden Toni Muster; `('Erika','Neu',null)` findet nichts.
  - Eine vorhandene Login-Adresse findet die Person, aber nur für Nutzer mit AD ≥ read (RLS).
  - test.vorstand erhält keine Treffer.

### Umsetzung für US-AD-07

- [ ] T040 [US-AD-07] (spec T8) Migration `supabase/migrations/20261020000800_ad_find_similar_persons.sql`: `ad_find_similar_persons(p_first text, p_last text, p_email text) returns setof ea_persons`, security invoker, stable. Treffer, wenn `lower(last_name) = lower(p_last)` und (`similarity(first_name, p_first) >= 0.3` oder Teilwort in beide Richtungen, ohne Groß-/Kleinschreibung), oder wenn `p_email` gleich einer `ad_accesses.login_email` ist. `grant execute … to authenticated`
- [ ] T041 [US-AD-07] (spec T16) `src/features/ad/personen/PersonNeu.tsx` (/ad/personen/neu) mit Dialog `DublettenDialog.tsx`:
  - Felder Vorname, Nachname, optional Login-Adresse.
  - Prüfung R4 im Frontend, danach `ad_find_similar_persons`.
  - Bei Treffern: Liste mit „Trotzdem anlegen“, „Vorhandene Person öffnen“, „Abbrechen“.
  - Anlegen: insert `ea_persons`, bei Login-Adresse insert `ad_accesses`. Fehler über `errors.ts`.
- [ ] T042 [US-AD-07] (spec T17 Teil) `src/features/ad/personen/PersonDetail.tsx` (/ad/personen/:id): Seitengerüst mit den Abschnitten Stammdaten, Zugang, Rechtevorlagen, Eigenschaften (zunächst leer). Abschnitt `StammdatenAbschnitt.tsx`: Name bearbeitbar, Art als Anzeige. Nötig für „Vorhandene Person öffnen“.

**Checkpoint**: Anlegen und Dublettenwarnung funktionieren.

---

## Phase 7: US-AD-12 Eigenschaftsart anlegen und ändern (Must)

**Ziel**: Eigenschaftsarten mit Zweck, Datentyp, „sichtbar in“ und „vertraulich“.

**Unabhängiger Test**:
- Anlegen mit Art.-9-Hinweis (AK1).
- Fehlender Zweck oder Auswahlliste ohne Werte (AK2) sowie ein doppelter Name (AK3) führen zu den Meldungen.
- Auswahlwerte entfernen ist abgelehnt (AK4).
- Geschäftsstelle (EA verwalten) kann „vertraulich“ nicht setzen (AK5).

### Tests für US-AD-12 ⚠️

- [ ] T043 [P] [US-AD-12] (spec T7 Teil) `supabase/tests/database/090_property_types.test.sql`:
  - Leerer Zweck → `EA_PURPOSE_REQUIRED`; `choice` ohne Werte → `EA_CHOICE_VALUES_REQUIRED`; doppelter Name → `ea_property_types_name_key`.
  - Auswahlwert entfernen → `EA_CHOICE_VALUE_REMOVED`; Wert ergänzen ist erlaubt.
  - Unbekannter Modulcode in `visible_in` → Fehler.
  - test.geschaeftsstelle: Art mit `confidential = false` anlegen erlaubt, mit `true` abgelehnt; vertrauliche Arten sind für sie unsichtbar.
  - test.admin darf alles.

### Umsetzung für US-AD-12

- [ ] T044 [US-AD-12] (spec T2 Teil) Migration `supabase/migrations/20261020000900_ea_property_types.sql`:
  - `ea_property_types` nach spec.md Abschnitt 2 (name, purpose, data_type, choice_values text[], visible_in text[], confidential default false, origin default `custom`, Audit-Spalten).
  - Checks und Unique-Index `lower(name)` nach data-model.md.
  - Trigger `ea_property_types_guard`: `visible_in` ⊆ `ad_modules`; Datentyp-Sperre `EA_DATA_TYPE_LOCKED`, die zur Laufzeit gegen `ea_properties` prüft (plpgsql); `EA_CHOICE_VALUE_REMOVED`; `EA_CONFIDENTIAL_FORBIDDEN`; `updated_*`.
  - Policies nach spec.md Abschnitt 3; Grants.
- [ ] T045 [P] [US-AD-12] (spec T21) `src/features/ad/eigenschaftsarten/EigenschaftsartenListe.tsx` (/ad/eigenschaftsarten): Name, Datentyp, sichtbar in, vertraulich; „Noch keine Eigenschaftsarten.“
- [ ] T046 [US-AD-12] (spec T21) `src/features/ad/eigenschaftsarten/EigenschaftsartBearbeiten.tsx`:
  - Felder Name, Zweck, Datentyp (Text / Datum / Ja/Nein / Auswahlliste), Auswahlwerte (nur bei Auswahlliste; vorhandene nicht entfernbar), „sichtbar in“ (Mehrfachauswahl aus `ad_modules`), „vertraulich“.
  - Beim Anlegen der Hinweis: „Erfasse keine Gesundheitsdaten, Religion, politische Meinung oder andere besondere Kategorien nach Art. 9 DSGVO.“
  - Datentyp gesperrt, wenn Eigenschaften existieren.

**Checkpoint**: Eigenschaftsarten sind pflegbar.

---

## Phase 8: US-AD-13 Eigenschaften einer Person pflegen (Must)

**Ziel**: Eigenschaften mit Gültigkeit und Historie an der Person.

**Unabhängiger Test**:
- Anlegen, Ändern und Beenden mit sichtbarer Historie (AK1, AK2).
- Ungültiger Zeitraum und falscher Typ zeigen die Meldungen (AK3).
- test.geschaeftsstelle sieht das Hauptamt nicht (AK4).
- Rechte bleiben unverändert (AK5).
- Nur Arten, deren „sichtbar in“ AD enthält, erscheinen; beendete sind gekennzeichnet (AK6).

### Tests für US-AD-13 ⚠️

- [ ] T047 [P] [US-AD-13] (spec T7 Teil) `supabase/tests/database/100_properties.test.sql`:
  - Falsche Wertspalte bzw. Wert außerhalb `choice_values` → `EA_VALUE_TYPE`; `valid_to < valid_from` → `ea_properties_valid_range`.
  - Ein Update schreibt die alte Fassung in `ea_property_history` mit `changed_by`.
  - test.geschaeftsstelle liest weder vertrauliche Eigenschaften noch deren Historie, und keine Eigenschaften von Funktionspersonen.
  - Eine neue Eigenschaft ändert `ad_user_level` nicht (R7).
  - Datentyp einer Art mit Eigenschaften ändern → `EA_DATA_TYPE_LOCKED`.

### Umsetzung für US-AD-13

- [ ] T048 [US-AD-13] (spec T2 Teil) Migration `supabase/migrations/20261020001000_ea_properties.sql`:
  - `ea_properties` (Wertspalten value_text/value_date/value_boolean, valid_from Pflicht, valid_to, Check `ea_properties_valid_range`, updated_at/updated_by), Indizes `(person_id)`, `(property_type_id)`.
  - Trigger `ea_properties_validate`.
  - `ea_property_history` (FK on delete cascade) mit Trigger `ea_properties_history` (after update, security definer).
  - Policies nach spec.md Abschnitt 3; Grants (Historie nur select).
- [ ] T049 [US-AD-13] (spec T23 Teil) `supabase/seed.sql` ergänzen:
  - Eigenschaftsarten „Hauptamt“ (Text, sichtbar in AD, vertraulich, Zweck „Zuordnung der hauptamtlich Beschäftigten“), „T-Shirt-Größe“ (Auswahlliste S, M, L, XL, sichtbar in EA, Zweck „Bestellung von Vereinskleidung“), „Erste-Hilfe-Kurs am“ (Datum, sichtbar in EA, Zweck „Nachweis für Tätigkeiten mit Gruppen“).
  - Eigenschaften: Anna Fiktiv Hauptamt „Mitarbeiterin Geschäftsstelle“ seit 01.03.2024; Toni Muster T-Shirt-Größe „M“ seit 01.01.2025; Dieter Gesperrt Hauptamt 01.01.2020–31.12.2025.
- [ ] T050 [US-AD-13] (spec T19) `src/features/ad/personen/EigenschaftenAbschnitt.tsx`:
  - Nur Arten mit `visible_in` ∋ `AD`; aktuelle oben, beendete (`valid_to < heute`) als „beendet“; „Noch keine Eigenschaften.“
  - Hinzufügen und Ändern mit einem Eingabefeld je Datentyp; Beenden durch Setzen von „gültig bis“.
  - Historie je Eigenschaft aufklappbar (geändert am/von).

**Checkpoint**: Eigenschaften mit Historie sind pflegbar; die vertrauliche Eigenschaft ist geschützt.

---

## Phase 9: US-AD-11 Rechtevorlage zuweisen und entziehen (Must)

**Ziel**: Oberfläche für Zuweisen und Entziehen. Datenbank und Tests sind mit T011 und T005 fertig (AK1, AK3–AK5).

**Unabhängiger Test**:
- Geschäftsstelle und Vorstand zuweisen ergibt die höhere Stufe je Modul, mit Protokolleintrag (AK1).
- Entziehen wird protokolliert (AK2).
- Eine bereits zugewiesene Vorlage wird nicht noch einmal angeboten (AK3).

- [ ] T051 [US-AD-11] (spec T18) `src/features/ad/personen/RechtevorlagenAbschnitt.tsx`: Liste der wirksamen Vorlagen mit „Entziehen“ (Bestätigung, `rpc('ad_revoke_template')`); „Vorlage hinzufügen“ bietet nur nicht zugewiesene Vorlagen an (`rpc('ad_assign_template')`); in `PersonDetail.tsx` einbinden

**Checkpoint**: Zuweisungen sind in der Oberfläche pflegbar.

---

## Phase 10: US-AD-08 Zugang einrichten und einladen (Must)

**Ziel**: Einladen, erneut einladen, Login-Adresse nach R20 ändern, Aufräumen bei Fehlern.

**Unabhängiger Test**:
- Deno-Tests grün: Aufräumen bei simuliertem Fehler (AK5), 403 ohne Recht (AK6).
- In TEST führt „Einladen“ ohne Vorlage zu „Bitte zuerst mindestens eine Rechtevorlage zuweisen.“ (AK2).
- Adresse ändern bei „eingeladen“ führt zum Hinweis und zum Status „kein Zugang“ (AK7).
- Der Mailversand selbst wird in T077 abgenommen.

### Tests für US-AD-08 ⚠️

- [ ] T052 [P] [US-AD-08] (spec T7 Teil) `supabase/tests/database/120_invite_functions.test.sql`:
  - `authenticated` darf `ad_apply_invite`, `ad_revert_invite` und `ad_apply_email_change` nicht ausführen; `service_role` darf es.
  - `ad_apply_invite` setzt `invited`, `last_invited_at`, `auth_user_id` und schreibt `invited`.
  - `ad_revert_invite` stellt den Ausgangsstand ohne Protokoll her.
  - `ad_apply_email_change` setzt die neue Adresse, `auth_user_id` null, `none` und schreibt `email_changed` mit Details „alt → neu“.
- [ ] T053 [P] [US-AD-08] (spec T9) Deno-Test `supabase/functions/ad-invite/index.test.ts` mit simuliertem Auth-Admin-Client und DB-Client:
  - 401 ohne JWT; 403 `AD_FORBIDDEN` ohne AD ≥ edit (keine Einladung).
  - 422 `AD_EMAIL_MISSING` / `AD_EMAIL_DOMAIN` / `AD_NO_TEMPLATE`; 409 `AD_EMAIL_TAKEN` / `AD_INVALID_STATUS`.
  - Erfolg ruft `ad_apply_invite` auf.
  - **Simulierter Fehler von `inviteUserByEmail`:** neu angelegter Auth-Eintrag wird mit `deleteUser` gelöscht, `ad_revert_invite` aufgerufen, kein `ad_apply_invite`, Antwort 502 `AD_MAIL_FAILED`. Bei einem Ausgangsstand mit `auth_user_id` (erneute Einladung) wird nichts gelöscht.
- [ ] T054 [P] [US-AD-08] (spec T10 Teil) Deno-Test `supabase/functions/ad-access/index.test.ts`, Fälle `change_email`:
  - nur bei `invited`, sonst 409 `AD_EMAIL_LOCKED`.
  - R1 über `ad_login_email_allowed` → `AD_EMAIL_DOMAIN`; R2 → `AD_EMAIL_TAKEN`.
  - Erfolg: `deleteUser` und danach `ad_apply_email_change`, Antwort 200 mit `code: "AD_EMAIL_CHANGED"`.
  - Fehler bei `deleteUser` → keine DB-Änderung.
  - 403 ohne Recht; 400 ohne `login_email`.

### Umsetzung für US-AD-08

- [ ] T055 [US-AD-08] (spec T4 Teil) Migration `supabase/migrations/20261020001100_ad_invite_functions.sql`: `ad_apply_invite(p_person uuid, p_auth_user uuid, p_actor uuid)`, `ad_revert_invite(p_person uuid, p_status ad_access_status, p_auth_user uuid, p_last_invited_at timestamptz)`, `ad_apply_email_change(p_person uuid, p_new_email citext, p_actor uuid)` (setzt `set_config('ad.email_change','on', true)`). Alle security definer; `revoke … from public, anon, authenticated`; `grant execute … to service_role`
- [ ] T056 [P] [US-AD-08] (spec T9 Teil, T10 Teil) Gemeinsamer Code `supabase/functions/_shared/`:
  - `cors.ts`: erlaubte Origins aus den Redirect-URLs.
  - `caller.ts`: Client mit dem JWT des Aufrufers und `rpc('ad_has_level', { p_module: 'AD', p_min: 'edit' })`.
  - `responses.ts`: JSON-Antworten `{ code }` mit HTTP-Status nach contracts/edge-functions.md.
  - `admin.ts`: Service-Client aus `SUPABASE_SERVICE_ROLE_KEY` der Edge-Umgebung.
- [ ] T057 [US-AD-08] (spec T9) `supabase/functions/ad-invite/index.ts`: Handler mit übergebbaren Clients nach contracts/edge-functions.md (Vorbedingungen, `inviteUserByEmail` mit `redirectTo` `<SITE_URL>/passwort-setzen`, Aufräumen bei Fehlern); Tests aus T053 grün
- [ ] T058 [US-AD-08] (spec T10 Teil) `supabase/functions/ad-access/index.ts`: Handler mit Aktion `change_email` nach contracts/edge-functions.md (lock/unlock folgen in T066); Tests aus T054 grün
- [ ] T059 [US-AD-08] (spec T17 Teil) `src/features/ad/personen/ZugangAbschnitt.tsx` in `PersonDetail.tsx`:
  - Anzeige Login-Adresse, Status, „zuletzt eingeladen am“.
  - Login-Adresse speichern: bei „kein Zugang“ direkt (insert/update `ad_accesses`); bei „eingeladen“ über `functions.invoke('ad-access', { action: 'change_email' })` mit Hinweis `AD_EMAIL_CHANGED`; bei „aktiv“/„gesperrt“ nicht bearbeitbar, mit der Meldung zu `AD_EMAIL_LOCKED`.
  - Knöpfe „Einladen“ / „Erneut einladen“ (`functions.invoke('ad-invite')`); ohne wirksame Vorlage deaktiviert, mit Hinweis R17.
- [ ] T060 [US-AD-08] (spec T9, T10) Edge Functions nach TEST ausrollen: `npx supabase functions deploy ad-invite ad-access` (nach Prüfung, dass TEST verknüpft ist)

**Checkpoint**: Einladen und Adressänderung sind per Deno-Tests abgesichert. In TEST werden **keine Seed-Adressen eingeladen** (Bounces, Mail-Limit); in TEST prüfbar ist hier nur R17 ohne Mailversand. Einladen und Adressänderung mit echtem Mailversand nimmt der Product Owner mit eigenen Adressen in T077 ab.

---

## Phase 11: US-AD-03 Einladung annehmen und Passwort setzen (Must)

**Ziel**: Passwort über den Einladungslink setzen.

**Unabhängiger Test** (mit eigener Adresse nach T077):
- Speichern setzt den Status auf „aktiv“ (AK1).
- Ungleiche Eingaben bzw. weniger als 8 Zeichen führen zu den R19-Meldungen (AK2).
- Ein ungültiger oder alter Link zeigt die Einladungs-Meldung (AK3, AK4, AK7).
- Verlassen ohne Speichern lässt den Status auf „eingeladen“ (AK6).

- [ ] T061 [US-AD-03] (spec T13 Teil) `src/features/auth/PasswortSetzenPage.tsx` (/passwort-setzen?token_hash=…&type=invite|recovery):
  - Felder Passwort und Wiederholung. R19 vor dem Absenden: „Das Passwort muss mindestens 8 Zeichen lang sein.“ bzw. „Die Passwörter stimmen nicht überein.“
  - Erst beim Speichern `verifyOtp({ token_hash, type })`, dann `updateUser({ password })`. Erfolg → /.
  - Ungültiger Link: bei `invite` „Der Link ist abgelaufen oder ungültig. Bitte wende dich an den Admin.“, bei `recovery` „Der Link ist abgelaufen oder ungültig. Bitte fordere einen neuen an.“

**Checkpoint**: Der Einladungslink führt zum aktiven Zugang.

---

## Phase 12: US-AD-04 Passwort vergessen (Must)

**Ziel**: Passwort selbst über einen Link zurücksetzen.

**Unabhängiger Test**:
- Jede Adresse führt zur gleichen Bestätigung (AK1).
- Ein Reset mit eigener Adresse funktioniert (AK2, in T077).
- Ein abgelaufener Link zeigt die Reset-Meldung (AK3).
- Ein gesperrter Zugang bleibt gesperrt (AK4).

- [ ] T062 [US-AD-04] (spec T13 Teil) `src/features/auth/PasswortVergessenPage.tsx` (/passwort-vergessen): Feld Login-Adresse; `resetPasswordForEmail(email, { redirectTo: <origin>/passwort-setzen })`; zeigt **immer** „Wenn ein Zugang zu dieser Adresse besteht, haben wir dir eine E-Mail mit einem Link geschickt.“ (R18), auch bei Fehlern

**Checkpoint**: Der Reset-Ablauf ist vollständig (die Reset-Seite stammt aus T061).

---

## Phase 13: US-AD-09 Zugang sperren und entsperren (Must)

**Ziel**: Sperren und Entsperren mit Bann in Auth und Protokoll.

**Unabhängiger Test**:
- Eva Eingeladen sperren führt zu „gesperrt“ mit Protokoll (AK1).
- Dieter Gesperrt entsperren führt zu „aktiv“, weil er ein Passwort hat (AK2); eine gesperrte Person ohne Passwort wird „eingeladen“ (AK3).
- test.geschaeftsstelle wird abgelehnt (AK5).
- Es wird nichts gelöscht (AK6).

### Tests für US-AD-09 ⚠️

- [ ] T063 [P] [US-AD-09] (spec T7 Teil) `supabase/tests/database/130_lock_functions.test.sql`:
  - `ad_apply_lock` setzt `locked`, `locked_at`, `locked_by` und schreibt `locked`; danach liefert `ad_user_level` für den Nutzer sofort `none` (R5, R10).
  - `ad_apply_unlock` führt mit gesetztem `encrypted_password` zu `active`, ohne zu `invited`, und schreibt `unlocked`.
  - Eigenschaften und Zuweisungen bleiben erhalten.
  - Nur `service_role` darf die Funktionen ausführen.
- [ ] T064 [P] [US-AD-09] (spec T10 Teil) `supabase/functions/ad-access/index.test.ts` ergänzen, Fälle `lock`/`unlock`:
  - Ausgangsstatus nach contracts/edge-functions.md, sonst 409 `AD_INVALID_STATUS`.
  - `ban_duration: '876000h'` bzw. `'none'`; danach `ad_apply_lock`/`ad_apply_unlock`.
  - 403 ohne Recht.

### Umsetzung für US-AD-09

- [ ] T065 [US-AD-09] (spec T4 Teil) Migration `supabase/migrations/20261020001200_ad_lock_functions.sql`: `ad_apply_lock(p_person uuid, p_actor uuid)`, `ad_apply_unlock(p_person uuid, p_actor uuid)` (Zielstatus über `auth.users.encrypted_password`); security definer; nur `grant execute … to service_role`
- [ ] T066 [US-AD-09] (spec T10) `supabase/functions/ad-access/index.ts` um `lock` und `unlock` erweitern; Tests aus T064 grün; erneut nach TEST deployen
- [ ] T067 [US-AD-09] (spec T17 Teil) `src/features/ad/personen/ZugangAbschnitt.tsx`:
  - „Sperren“ mit Bestätigungsdialog und dem Hinweis „Bereits angemeldete Nutzer verlieren den Zugriff spätestens nach einer Stunde.“
  - „Entsperren“; Anzeige „gesperrt am/von“.

**Checkpoint**: Sperren und Entsperren funktionieren in TEST.

---

## Phase 14: US-AD-14 Protokoll einsehen (Should)

**Ziel**: Protokollansicht und Löschlauf nach 5 Jahren.

**Unabhängiger Test**:
- test.admin sieht die Seed-Einträge, neueste zuerst, mit Namen (AK1).
- Der Job ist um 01:15 UTC eingeplant und löscht nur Einträge, die älter als 5 Jahre sind (AK2).
- Ohne Einträge erscheint „Noch keine Einträge.“ (AK3).
- PATCH/DELETE werden abgelehnt (AK4).
- test.geschaeftsstelle erhält keine Daten (AK5).

### Tests für US-AD-14 ⚠️

- [ ] T068 [P] [US-AD-14] (spec T7 Teil) `supabase/tests/database/140_audit_log.test.sql`:
  - `cron.job` enthält `ad_audit_log_retention` mit `15 1 * * *`; der Befehl des Jobs, in der Transaktion ausgeführt, löscht einen Eintrag von vor 6 Jahren und behält einen von gestern.
  - test.admin: update/delete auf `ad_audit_log` abgelehnt.
  - `ad_v_audit_log` liefert den Namen des Akteurs für AD ≥ read und 0 Zeilen für test.geschaeftsstelle.

### Umsetzung für US-AD-14

- [ ] T069 [US-AD-14] (spec T4 Teil) Migration `supabase/migrations/20261020001300_ad_audit_retention.sql`:
  - `cron.schedule('ad_audit_log_retention', '15 1 * * *', $$delete from public.ad_audit_log where occurred_at < now() - interval '5 years'$$)`.
  - View `ad_v_audit_log` (`security_invoker = true`): Einträge mit Namen der betroffenen Person und des Akteurs (über `ad_accesses.auth_user_id` → `ea_persons`); `grant select … to authenticated`.
- [ ] T070 [US-AD-14] (spec T22) `src/features/ad/protokoll/ProtokollPage.tsx` (/ad/protokoll): Zeitpunkt, ausgeführt von, betroffene Person, Aktion (deutsche Bezeichnungen: eingeladen, Login-Adresse geändert, Vorlage zugewiesen, Vorlage entzogen, gesperrt, entsperrt, Anmeldung Notfall-Admin), Details; neueste zuerst, 50 Einträge je Seite mit „Weiter blättern“; „Noch keine Einträge.“

**Checkpoint**: Das Protokoll ist einsehbar.

---

## Phase 15: US-AD-15 Notfall-Admin nutzen und nachvollziehen (Must)

**Ziel**: Hinweis auf Anmeldungen des Notfall-Admins in AD.

**Unabhängiger Test**:
- test.notfall meldet sich an; das Protokoll enthält „Anmeldung Notfall-Admin“ (AK1, aus T013).
- test.admin sieht in /ad den Hinweis mit Anzahl und Zeitpunkt; „Zur Kenntnis genommen“ blendet ihn aus (AK2).
- Die Funktionsperson fehlt in `ea_v_persons` (AK3, aus T005).
- test.geschaeftsstelle erhält keine Daten (AK5).

### Tests für US-AD-15 ⚠️

- [ ] T071 [P] [US-AD-15] (spec T7 Teil) `supabase/tests/database/150_emergency_notice.test.sql`:
  - `ad_pending_emergency_logins()` zählt `emergency_login`-Einträge nach `emergency_acknowledged_until` (ohne Zeile: alle).
  - `ad_acknowledge_emergency()` setzt den Zeitpunkt für `auth.uid()`.
  - Beide Funktionen liefern für test.geschaeftsstelle `AD_FORBIDDEN`.
  - Löschen eines Auth-Nutzers löscht seine Zeile in `ad_notice_acks` mit (cascade).

### Umsetzung für US-AD-15

- [ ] T072 [US-AD-15] (spec T4 Teil) Migration `supabase/migrations/20261020001400_ad_emergency_notice.sql`: `ad_notice_acks` (user_id PK default auth.uid(), FK `auth.users(id) on delete cascade`, emergency_acknowledged_until), Policies für die eigene Zeile; `ad_pending_emergency_logins() returns table (count int, last_at timestamptz)` und `ad_acknowledge_emergency()`, beide security definer mit Prüfung AD ≥ read; `grant execute … to authenticated`
- [ ] T073 [US-AD-15] (spec T15 Teil) `src/features/ad/personen/NotfallHinweis.tsx` oben in `PersonenUebersicht.tsx`: „Der Notfall-Admin hat sich n-mal angemeldet, zuletzt am TT.MM.JJJJ um HH:MM.“ mit dem Knopf „Zur Kenntnis genommen“ (`rpc('ad_acknowledge_emergency')`); nur bei count > 0

**Checkpoint**: Der Notfall-Hinweis funktioniert mit test.notfall.

---

## Phase 16: US-AD-16 Testzugänge in TEST (Must)

**Ziel**: Vollständiger, geprüfter Seed nach spec.md Abschnitt 9.

**Unabhängiger Test**:
- `seed.sh` gegen TEST ergibt 8 Personen, 3 aktive Testzugänge sowie Eigenschaften mit Hauptamt und dem Dublettenpaar (AK1).
- Die Geschäftsstelle sieht kein Hauptamt (AK2).
- Das Passwort steht nicht im Repo (AK3).
- Bei PROD-Ref erscheint „Seed in PROD nicht erlaubt.“ (AK4).

### Tests für US-AD-16 ⚠️

- [ ] T074 [P] [US-AD-16] (spec T7 Teil) `supabase/tests/database/160_seed.test.sql`:
  - 8 Personen, davon 1 `function`.
  - Status je Zugang nach spec.md Abschnitt 9; 3 Eigenschaftsarten; 3 Eigenschaften; 4 Protokolleinträge.
  - test.geschaeftsstelle sieht Annas Hauptamt nicht.

### Umsetzung für US-AD-16

- [ ] T075 [US-AD-16] (spec T23) `supabase/seed.sh` und `supabase/seed.sql` gegen spec.md Abschnitt 9 abgleichen; Schutzprüfung mit einer Test-URL ausprobieren, die die PROD-Ref enthält: Abbruch vor jeder Verbindung (quickstart.md B6). Danach `supabase/seed.sh` gegen TEST (nach Prüfung, dass TEST verknüpft ist).

**Checkpoint**: Alle Testzugänge funktionieren in TEST.

---

## Phase 17: Abnahme und Querschnitt

**Zweck**: Fachliche Abnahme in TEST (spec T25) und Abschluss.

- [ ] T076 [US-AD-07] (spec T25 Teil) Dublettenschwelle in TEST abnehmen (quickstart.md C: Toni/Anton/Tony Muster, Tippfehler) und das Ergebnis in `docs/specs/ad-administration/abnahme-test.md` festhalten (ohne private Adressen); bei Bedarf Schwelle in einer neuen Migration anpassen (Rückfrage beim Product Owner)
- [ ] T077 [US-AD-08] (spec T25 Teil) Abnahmeablauf C1 vorbereiten: TEST auf Stand bringen (`db push`, `functions deploy`, Seed; die Auth-Einstellungen hat der Product Owner nach der Checkliste in `supabase/setup/README.md` im Dashboard gesetzt, kein `config push`). Eingeladen werden nur die eigenen Adressen des Product Owners. Danach führt **der Product Owner selbst** C1 durch (Domain per SQL-Editor, Personen mit eigenen Adressen über die Oberfläche, Einladung, Adressänderung, Passwort setzen, Passwort vergessen) und räumt nach C2 auf. Claude Code trägt keine Domain und keine Adresse ein. Ergebnis ohne Adressen in `docs/specs/ad-administration/abnahme-test.md`. Betrifft US-AD-03, US-AD-04, US-AD-08.
- [ ] T078 [US-AD-16] (spec T25 Teil) Übrige Szenarien aus quickstart.md C mit den drei Testzugängen und test.notfall abnehmen, auch in der Breite 375 px; offene `[PRÜFEN T25]`-Punkte aus research.md abhaken bzw. melden; Ergebnis in `docs/specs/ad-administration/abnahme-test.md`
- [ ] T079 [P] [US-AD-01] (spec T12 Teil) Querschnitt: `npm run lint` und `npm run build` ohne Fehler; `npm audit` und Ergebnis melden (Merkposten shadcn-CLI aus offene-punkte.md); keine Secrets oder realen Adressen im Diff (`git grep` auf `@` außerhalb von `@dav-leipzig.de`/`example.test`)

---

## Abhängigkeiten und Reihenfolge

### Zwischen den Phasen

- **Phase 1 (US-AD-01)** blockiert alles: Schema, Rechte, Trigger, Seed und CI.
- **Phase 2 (US-AD-02)** blockiert alle Oberflächen (Router, Routenschutz, `errors.ts`, Kopfzeile).
- Phase 3 → Phase 4 (`AdLayout`) → Phasen 5–16 folgen der Reihenfolge aus 02-stories.md.
- Fachliche Abhängigkeiten:
  - US-AD-07 baut die Detailseite (T042), die Phasen 8–10 und 13 brauchen sie.
  - US-AD-12 vor US-AD-13 (Eigenschaftsarten vor Eigenschaften).
  - US-AD-08 vor US-AD-03 und US-AD-09 (`ad-access`, Zugangsabschnitt).
  - US-AD-14 vor US-AD-15 wird nur für die Anzeige gebraucht; das Protokoll entsteht bereits in T012.
- Phase 17 erst, wenn alle Phasen fertig sind.

### Innerhalb einer Story

Erst die Tests (müssen fehlschlagen), dann die Migration, dann Edge Functions, dann die Oberfläche, dann das Ausrollen nach TEST.

### Parallel möglich

- Phase 1: T004–T008 (Testdateien) parallel; T014/T015 parallel zu T016 und T017/T018, nachdem die Migrationen stehen.
- Phase 2: T023, T024, T025, T028 parallel.
- Phase 10: T052, T053, T054 parallel; T056 parallel zu T055.
- Phase 13: T063 und T064 parallel.

## Beispiel: parallel in US-AD-01

```text
T004 supabase/tests/database/010_foundation.test.sql
T005 supabase/tests/database/020_persons_rights.test.sql
T006 supabase/tests/database/030_auth_triggers.test.sql
T007 supabase/tests/database/050_policies.test.sql
T008 supabase/tests/bootstrap/010_prod_bootstrap.test.sql
```

## Umsetzungsstrategie

1. **MVP-Fundament:** Phase 1 (US-AD-01) auf `us-ad-01-ersteinrichtung`, PR mit grüner Action. Danach ist die Ersteinrichtung von PROD durch den Product Owner möglich, sobald O1 geklärt ist.
2. **Nutzbare Anmeldung:** Phasen 2–3 (US-AD-02, US-AD-05); Abnahme in der Cloudflare-Vorschau gegen TEST.
3. **Pflege in AD:** Phasen 4–9 je Story auf eigenem Branch.
4. **Zugänge:** Phasen 10–13 (Einladen, Annehmen, Reset, Sperren).
5. **Nachvollziehbarkeit:** Phasen 14–16, dann die Abnahme in Phase 17.

Offen: [OFFEN] O1 – Weg nach PROD (spec.md Abschnitt 11). Keine Task in dieser Datei führt etwas gegen PROD aus.
