---
description: "Tasks für das Modul Administration (AD), Kern bis v0.7.1"
---

# Tasks: Administration (AD) – Kern bis v0.7.1

**Input**: [plan.md](plan.md) (Stand 22.10.2026), [spec.md](spec.md) v0.9 (führend, Umfang Kern bis v0.7.1), [02-stories.md](02-stories.md) v0.8.1, [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md), [Constitution](../../../.specify/memory/constitution.md) v1.1.1

**Stand**: Phasen 1–3 (T001–T031) sind erledigt und bleiben mit Nummer und Text unverändert, weil spec.md und querschnitt-administration.md darauf verweisen. Die Tasks ab T032 ersetzen die offenen Tasks der Fassung vom 20.10.2026 (Grundlage spec.md v0.5); deren Nummern T032–T079 sind damit neu belegt.

**Abgrenzung**: Der Nachtrag v0.8 (spec T50–T58) folgt in Phase 15 (seit 24.10.2026). Nicht umgesetzt wird der Nachtrag v0.9 (spec T59–T67); bis Phase 14 galt auch für v0.8: Einzelheiten in plan.md, Abschnitt „Abgrenzung“. Insbesondere: R30 nur für EA; `ad_modules` ohne EZ, TK, TKF und ohne `is_hidden`; keine `ad_locations`, `ad_rates`; keine Namens-, Lizenz- und Satzfunktionen; `ea_create_volunteer` und `ad_find_similar_persons` ohne EZ-Erweiterung; Seed nur Personen 1–12.

**Tests**: Die Constitution verlangt eine test- und spec-getriebene Umsetzung mit pgTAP-Tests der RLS je Rechtevorlage (Arbeitsablauf Nr. 4). Vor jeder Migration und jeder Edge Function steht eine Test-Task; die Tests müssen zuerst fehlschlagen. Für das Frontend gilt die Abnahme in TEST (spec T25, T32, T49).

**Organisation**: Phasen nach den Branches aus plan.md. Phase 4 ist die gemeinsame Datenbank-Grundlage aller übrigen Stories (Branch `ad-kern-datenbank`); danach eine Phase je Branch mit den Oberflächen.

## Format: `- [ ] T### [P?] [US-AD-xx] (spec Tn) Beschreibung`

- **T###**: laufende Task-ID dieser Datei
- **[P]**: parallel ausführbar (andere Datei, keine offene Abhängigkeit)
- **[US-AD-xx]**: Story aus 02-stories.md
- **(spec Tn)**: Task-Nummer aus spec.md Abschnitt 10; „Teil“ bedeutet, dass nur ein Teil dieser spec-Task umgesetzt wird

## Regeln für alle Tasks

- **Nie gegen PROD.** Alle CLI-Befehle gehen nur gegen vereins-os-test oder gegen den lokalen Stack in der GitHub Action. Vor jedem Befehl mit `--linked` muss `npx supabase projects list` zeigen, dass TEST verknüpft ist.
- **Kein `supabase config push` und kein `supabase config diff`**, weder gegen TEST noch gegen PROD. `supabase/config.toml` gilt nur für den lokalen Stack (CI). Auth-Einstellungen in TEST und PROD stellt der Product Owner nach der Checkliste in `supabase/setup/README.md` im Dashboard ein.
- **Keine Einladungen an Seed-Adressen in TEST** (`test.*@dav-leipzig.de`): Sie erzeugen Bounces und verbrauchen das Mail-Limit. In TEST werden nur die eigenen Adressen des Product Owners eingeladen (T103).
- **Bestehende Migrationen nicht ändern** (`20261020000100`–`0600` sind in TEST ausgerollt). Jede Änderung kommt per neuer Migration.
- Jede Migration enthält für die Tabellen, Views und Funktionen, die sie anlegt: `enable row level security`, Policies, `revoke all … from anon, public` und `grant … to authenticated`. Für interne Funktionen gilt stattdessen `grant execute … to service_role`. Für `ad_test_login_domains` gibt es weder Policy noch Grant (Ausnahme in Constitution III).
- security-definer-Funktionen haben immer `set search_path = ''` und nutzen voll qualifizierte Namen.
- Datei `.env.local` nie lesen, anzeigen oder ändern. Keine Secrets, keine echten Adressen in Dateien.
- Fehlercodes und Meldungen nur aus [contracts/error-codes.md](contracts/error-codes.md).
- Dateien unter `docs/` nicht ändern (kommen aus OneDrive, CLAUDE.md). Ausnahme: die von Spec Kit bzw. Claude Code gepflegten Dateien plan.md, research.md, data-model.md, quickstart.md, tasks.md, contracts/ und abnahme-test.md.
- Commits auf Deutsch, auf dem Branch der jeweiligen Phase; jeder Pull Request nennt Stories, Tasks und die Cloudflare-Vorschau-URL.

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
- test.vorstand sieht „Für dich sind noch keine Module freigeschaltet.“ und darunter „Wende dich an den Admin, wenn du Zugriff brauchst.“ (AK2).
- test.geschaeftsstelle sieht auf /ad die Kein-Zugriff-Seite, ohne dass Daten abgefragt werden (AK3).
- Breite 375 px funktioniert (AK5).

- [X] T030 [P] [US-AD-05] (spec T14) Platzhalterbild `src/assets/willkommen.svg` (neutral, ohne Personen oder Logos Dritter)
- [X] T031 [US-AD-05] (spec T14) `src/features/start/StartPage.tsx`: Willkommensgrafik, Kacheln aus `rpc('ad_my_modules')` (Link je Modul, AD → /ad), leerer Zustand „Für dich sind noch keine Module freigeschaltet.“ und darunter „Wende dich an den Admin, wenn du Zugriff brauchst.“; Ladezustand; Daten bei jedem Aufruf neu laden (AK4)

**Checkpoint**: Die Startseite zeigt je Testzugang die richtigen Kacheln.

---

## Phase 4: Datenbank-Kern v0.6/v0.7 (Branch `ad-kern-datenbank`) 🎯 Grundlage für alle weiteren Phasen

**Ziel**: Alle Datenbankteile des Kerns: Reichweite „Referat“ (nur EA), Referate und Gremien, Qualifikationsarten mit Startbestand, Personenmodell mit Rufname und Ehrenamtsstatus, Eigenschaftsarten mit Feldern, Eigenschaften, Sichtbarkeit je Pfad, EA-Funktionen, Startvorlage Referent:in, Personenübersicht, Dublettenprüfung, Notfall-Hinweis, Löschlauf des Protokolls; Seed Personen 1–12.

**Stories (Datenbankteil)**: US-AD-06, 07, 12, 13, 14, 15, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26

**Unabhängiger Test**: Die GitHub Action ist grün; die Sichtbarkeitsmatrix aus data-model.md („Testdaten“) gilt für Admin, Geschäftsstelle, Referent:in und Vorstand; `supabase db push --linked` und `supabase/seed.sh` laufen gegen TEST ohne Fehler.

### Tests für Phase 4 ⚠️ (zuerst schreiben, müssen fehlschlagen)

- [x] T032 [US-AD-23] (spec T7 Teil) Bestehende Tests an das neue Modell anpassen: `supabase/tests/database/020_persons_rights.test.sql` (Lesen/Schreiben auf `ea_persons` jetzt nach R32: test.geschaeftsstelle sieht keine Personen ohne Ehrenamtsstatus; Anlegen direkt nur mit AD ≥ edit) und `supabase/tests/database/050_policies.test.sql` (`policies_are`/`table_privs_are` für alle neuen Tabellen aus data-model.md, ersetzte Policies auf `ea_persons`, Grant `update (level, scope)` auf `ad_template_rights`)
- [x] T033 [P] [US-AD-20] (spec T7 Teil) `supabase/tests/database/070_scope_referate.test.sql`:
  - `ad_template_rights.scope` hat den Typ `ad_scope`; `scope = 'referat'` für EA erlaubt, für GR → `AD_SCOPE_NOT_ALLOWED`.
  - `ad_assign_template` mit Vorlage Referent:in ohne Referat bzw. nur mit inaktivem Referat → `AD_REFERAT_REQUIRED`; mit Referat Klettern → Zuweisung, `ad_assignment_referate`, Protokoll `template_assigned` mit „Klettern“ in `details`; bei einer Vorlage ohne Reichweite „Referat“ werden übergebene Referate nicht gespeichert (R31).
  - `ad_set_assignment_referate` Klettern → Touren schreibt `referate_changed` mit „vorher → nachher“ (US-AD-21 AK3).
  - test.referent: `ad_my_referate('EA','edit')` = {Klettern}, `ad_user_level('EA')` = `none`, `ad_has_any_level('EA','read')` = true; ohne aktiven Zugang leer (R5).
  - `ad_my_modules()` liefert `level` als höchste Stufe über beide Reichweiten; nur Module mit `is_available`.
  - test.geschaeftsstelle und test.vorstand: `ad_assign_template` → `AD_FORBIDDEN`.
- [x] T034 [P] [US-AD-20] (spec T7 Teil) `supabase/tests/database/080_referate_gremien.test.sql`: Startbestand 7 Referate und 4 Gremien in der Reihenfolge aus spec.md; Lesen für jeden Testzugang mit aktivem Zugang; Anlegen/Ändern nur test.admin und test.geschaeftsstelle (EA verwalten), test.vorstand und test.referent abgelehnt; doppelte Bezeichnung ohne Groß-/Kleinschreibung → `ea_referate_name_key`; kein Delete
- [x] T035 [P] [US-AD-17] (spec T29) `supabase/tests/database/090_qualification_types.test.sql`:
  - 47 Einträge nach dem Startbestand; PSA mit Status `historic`.
  - R21 `AD_QUALIFICATION_NAME_REQUIRED`, `AD_QUALIFICATION_NAME_TAKEN` (ohne Groß-/Kleinschreibung); R22 `AD_QUALIFICATION_CODE_TAKEN`, `AD_QUALIFICATION_CODE_FORMAT`, Kürzel `tcspi` wird `TCSPI`; R23 `AD_QUALIFICATION_LEVEL_REQUIRED`; R24 `AD_QUALIFICATION_VALIDITY` (0, 11, fehlend bei Lizenz), bei Zusatzqualifikation und Lehrgang wird `validity_years` geleert.
  - `source_ref` für Nutzer nicht änderbar.
  - Lesen für alle Testzugänge mit aktivem Zugang; Schreiben test.admin und test.geschaeftsstelle; test.vorstand abgelehnt; kein Delete.
  - Der Insert-Block der Startbestands-Migration läuft ein zweites Mal ohne Änderung; ein vorher geänderter Eintrag bleibt geändert.
- [x] T036 [P] [US-AD-24] (spec T7 Teil) `supabase/tests/database/100_persons_v07.test.sql`: neue Spalten mit Defaults (`created_in = 'AD'` für den Bestand); Rufname wird getrimmt, leer → null; Check `volunteer_status`/`volunteer_status_since` beide oder keiner; Funktionsperson mit Ehrenamtsstatus abgelehnt; Nutzer-Update von `volunteer_status`, `kind` oder `created_in` abgelehnt; ohne Nutzerkontext ist der Ehrenamtsstatus setzbar
- [x] T037 [P] [US-AD-22] (spec T7 Teil) `supabase/tests/database/110_property_types.test.sql`:
  - `ea_save_property_type` ohne Felder → `EA_NO_FIELDS`; leerer Zweck → `EA_PURPOSE_REQUIRED`; Auswahlliste ohne Werte → `EA_CHOICE_VALUES_REQUIRED`; doppelter Name → `ea_property_types_name_key`; doppelte Feldbezeichnung → `ea_property_fields_label_key`; unbekannter Modulcode in `visible_in` abgelehnt.
  - test.geschaeftsstelle: `read_level = 'confidential'` setzen → `AD_CONFIDENTIAL_ONLY_AD`; vertrauliche Arten und ihre Felder sind für sie und test.referent unsichtbar.
  - Mit vorhandenen Eigenschaften: Datentyp ändern → `EA_DATA_TYPE_LOCKED`; Bezug ändern → `EA_RELATION_LOCKED`; neues Pflichtfeld → `EA_FIELD_NEW_REQUIRED`; Auswahlwert entfernen → `EA_CHOICE_VALUE_REMOVED`, ergänzen erlaubt; Feldschlüssel ändern abgelehnt.
  - `system_key` nur ohne Nutzerkontext setzbar; `relation_kind = 'group'` ohne GR = verwalten abgelehnt.
- [x] T038 [P] [US-AD-19] (spec T7 Teil) `supabase/tests/database/120_properties.test.sql`:
  - R35: fehlendes Pflichtfeld → `EA_FIELD_REQUIRED` mit Feldbezeichnung im `detail`; Text statt Datum → `EA_VALUE_TYPE` mit Feldbezeichnung; unbekannter Schlüssel → `EA_FIELD_UNKNOWN`; Wert außerhalb der Auswahlliste → `EA_FIELD_CHOICE`; Jahr 1899 und 2101 abgelehnt.
  - R37: zweiter überlappender Eintrag bei `allow_multiple = false` → `EA_SINGLE_VALUE`; nicht überlappend erlaubt.
  - R38: Bezug Pflicht ohne Referat → `EA_RELATION_REQUIRED`; inaktives Referat nicht neu wählbar.
  - R27: historische Qualifikationsart mit Nutzerkontext neu gesetzt → `AD_QUALIFICATION_HISTORIC`, ohne Nutzerkontext erlaubt; andere Werte einer solchen Eigenschaft änderbar. R28: falscher Typ → `AD_QUALIFICATION_KIND`; nicht vorhandene Qualifikationsart → `EA_VALUE_TYPE`.
  - `valid_to < valid_from` → `ea_properties_valid_range`; ein Update schreibt die alte Fassung in `ea_property_history`.
- [x] T039 [P] [US-AD-23] (spec T45) `supabase/tests/database/130_visibility.test.sql`:
  - Sichtbarkeitsmatrix aus data-model.md („Testdaten“) für Personen über `ea_persons` und `ea_v_persons` je Testzugang.
  - Lesestufen nach R29: test.geschaeftsstelle liest „Geburtsdatum (Test)“, aber kein „Hauptamt“; test.referent liest weder Geburtsdatum noch Hauptamt; test.admin liest alles; Historie folgt der Eigenschaft.
  - test.referent: Eigenschaft mit Bezug Klettern an Person 4 anlegen erlaubt; Bezug Ausbildung → `EA_RELATION_FOREIGN_REFERAT`; Funktion von Person 10 im Referat Ausbildung lesbar, nicht änderbar (R41); Person 11 (ausgeschieden) unsichtbar (R34).
  - Eigenschaft einer Art mit Bezug Gruppe aus dem Pfad EA schreiben → `EA_GROUP_RELATION_ONLY_GR` (R39; Art ohne Nutzerkontext angelegt).
  - Person 12 (`created_in = 'GR'`, ohne Ehrenamtsstatus) ist mit nur EA-Rechten nicht lesbar, mit AD-Rechten lesbar (Übergabe GR, v0.7.1).
  - Eine neue Eigenschaft ändert `ad_user_level` und `ad_my_referate` nicht (R7).
  - test.vorstand sieht keine Person und keine Eigenschaft.
- [x] T040 [P] [US-AD-23] (spec T7 Teil) `supabase/tests/database/140_volunteer_functions.test.sql`:
  - `ea_set_volunteer_status`: test.geschaeftsstelle setzt Person 5 auf `active` mit Historie (wer, wann); test.referent setzt Person 4 auf `dormant`, für Person 5 → `EA_STATUS_FORBIDDEN`; test.vorstand → `EA_STATUS_FORBIDDEN`.
  - `ea_create_volunteer`: test.referent mit Referat Klettern → Person mit `created_in = 'EA'`, Status `active` mit Historie, erste Eigenschaft mit Bezug Klettern; mit Referat Ausbildung → `EA_RELATION_FOREIGN_REFERAT`; test.geschaeftsstelle ohne Art und Referat erlaubt; die Funktion hat keinen Parameter `p_contact_email`.
  - `ea_activate_person`: test.referent übernimmt Person 11 mit Zuordnung Klettern (Status `active`, keine neue Person); Funktionsperson abgelehnt.
  - `ea_person_referate(4)` = {Klettern} für Nutzer mit Pfad EA, sonst keine Zeile.
- [x] T041 [P] [US-AD-20] (spec T7 Teil) `supabase/tests/database/150_start_templates.test.sql`: Vorlage „Referent:in“ mit EA `edit`, scope `referat`, alle übrigen 8 Module `none`; Vorlage Admin GR = `read`; zweiter Lauf des Migrationsblocks ändert nichts; eine vom Admin geänderte Stufe bleibt erhalten
- [x] T042 [P] [US-AD-25] (spec T7 Teil) `supabase/tests/database/160_find_similar.test.sql`:
  - `('Anton','Muster',null)` und `('Tony','Muster',null)` finden Toni Muster (4) und Anton Muster (5); `('Erika','Neu',null)` findet nichts; Funktionsperson 8 nie.
  - Login-Adresse und die E-Mail aus „Kontaktdaten (Test)“ von Person 12 (`paul.nurgruppe@example.test`) werden gefunden.
  - Rückgabe genau `person_id, first_name, last_name, preferred_name, birth_year, volunteer_status, left_since, is_visible`; `birth_year` 1990 für Person 4; `left_since` nur bei Person 11.
  - `is_visible` für test.referent bei Person 5 false, bei Person 4 true.
  - Aufrufbar für test.admin, test.geschaeftsstelle, test.referent; test.vorstand → `AD_FORBIDDEN`.
- [x] T043 [P] [US-AD-06] (spec T7 Teil) `supabase/tests/database/170_person_overview.test.sql`: `ad_v_person_overview` liefert für test.admin 12 Zeilen mit Rufname, `access_status = 'none'` ohne Zugang, Ehrenamtsstatus, `created_in` und wirksamen Vorlagen mit Referaten (Person 9: „Referent:in (Klettern)“); test.geschaeftsstelle nur Personen nach Pfad EA; test.vorstand 0 Zeilen; `ad_me()` liefert `preferred_name`; `ad_qualification_usage` zählt verschiedene Personen (TCSPI: 1) und ist für test.vorstand verboten
- [x] T044 [P] [US-AD-15] (spec T7 Teil) `supabase/tests/database/180_emergency_notice.test.sql`:
  - `ad_pending_emergency_logins()` zählt `emergency_login`-Einträge nach `emergency_acknowledged_until` (ohne Zeile: alle); `ad_acknowledge_emergency()` setzt den Zeitpunkt für `auth.uid()`; beide für test.geschaeftsstelle `AD_FORBIDDEN`.
  - Löschen eines Auth-Nutzers löscht seine Zeile in `ad_notice_acks` mit (cascade).
  - `cron.job` enthält `ad_audit_log_retention` mit `15 1 * * *`; der Befehl, in der Transaktion ausgeführt, löscht einen Eintrag von vor 6 Jahren und behält einen von gestern; test.admin: update/delete auf `ad_audit_log` abgelehnt (US-AD-14 AK2, AK4).
- [x] T045 [P] [US-AD-23] (spec T45 Teil) `supabase/tests/database/190_mengentest.test.sql` nach research.md R-27: 1.000 Personen mit Ehrenamtsstatus und je 30 Eigenschaften; als test.referent eine Seite (50) der Personenübersicht und die Eigenschaften der sichtbaren Personen in je < 1 s
- [x] T046 [P] [US-AD-26] (spec T7 Teil) `supabase/tests/database/200_seed.test.sql`: 12 Personen (eine `function`); aktive Testzugänge Admin, Geschäftsstelle, Vorstand, Notfall-Admin, Referent:in; Ehrenamtsstatus der Personen 4, 5, 9, 10, 11 nach spec.md Abschnitt 9 mit Historie; 8 Testarten mit Feldern; Person 5 mit historischer Qualifikationsart; 4 Protokolleinträge, davon `template_assigned` für Rita Referentin mit Referat Klettern; keine `system_key` `function`, `contact`, `license`

### Umsetzung für Phase 4

- [x] T047 (spec T26, T33, T35, T37 Teil) Migration `supabase/migrations/20261023000100_ad_kern_enums.sql` nach research.md R-17: `alter type public.ea_data_type add value` `number`, `year`, `qualification_type`; `alter type public.ad_audit_action add value 'referate_changed'`; neue Enums `ad_scope` (`all`, `referat`), `ea_read_level` (`all`, `office`, `confidential`), `ea_relation_kind` (`none`, `referat`, `gremium`, `group`), `ea_property_category` (`master_data`, `contact`, `assignment`, `qualification`, `proof`, `yearly`, `issue`, `external_access`, `other`), `ea_volunteer_status` (`active`, `dormant`, `left`), `ad_qualification_kind` (`license`, `add_on`, `course`, `training`), `ad_license_level` (`pre`, `C`, `B`, `A`, `none`), `ad_qualification_status` (`current`, `historic`); `grant usage on type … to authenticated`
- [x] T048 [US-AD-20] (spec T34, T26 Teil) Migration `…000200_ea_referate_gremien.sql`: `ad_has_active_access()`; `ea_referate`, `ea_gremien` nach data-model.md mit Startbestand (Referate: Ausbildung, Touren, Kinder und Jugend, Klettern, Leistungssport, Karl-Stein-Hütte, Sulzenauhütte; Gremien: Vorstand, Beirat, Ehrenrat, Jugendausschuss), Trigger `updated_*`, Policies, Grants; Tests T034 grün
- [x] T049 [US-AD-20] (spec T33) Migration `…000300_ad_scope.sql` nach research.md R-18: Check `ad_template_rights_scope_mvp` entfernen, `scope` auf `ad_scope` umstellen, Check `ad_template_rights_scope_allowed` (`scope = 'all' or (scope = 'referat' and module_code = 'EA')`), Trigger mit `AD_SCOPE_NOT_ALLOWED`; `ad_assignment_referate`; `ad_my_referate`, `ad_has_any_level`; neue Fassungen `ad_user_level` (nur scope `all`), `ad_my_modules`; `ad_assign_template(p_person, p_template, p_referate uuid[] default null)` (alte Signatur entfernen) mit R31 (`AD_REFERAT_REQUIRED`) und Protokoll; `ad_set_assignment_referate`; Grant `update (level, scope)`; Tests T033 grün
- [x] T050 [US-AD-17] (spec T26) Migration `…000400_ad_qualification_types.sql` nach data-model.md und research.md R-24: Tabelle, Checks, Indizes, Trigger `ad_qualification_types_guard` (R21–R24), `ad_can_edit_qualification_types()`, Policies (select `ad_has_active_access()`, insert/update `ad_can_edit_qualification_types()`), kein Delete
- [x] T051 [US-AD-18] (spec T27) Migration `…000500_ad_qualification_types_data.sql`: die 47 Zeilen aus `docs/specs/ea-ehrenamt/stammdaten-qualifikationsarten.md` v0.2 Abschnitt 3 (Quell-ID → `source_ref`, Kürzel → `code`, Bezeichnung → `name`, Sparte → `discipline`, Typ → `kind`, Lizenzstufe → `level`, Spezifikation, Aussteller → `issuer`, DOSB → `dosb_eligible`, Gültigkeitsdauer → `validity_years`, Status, Hinweis → `note`); PSA mit `historic`; `insert … on conflict (source_ref) do nothing`; Tests T035 grün
- [x] T052 [US-AD-24] (spec T37) Migration `…000600_ea_persons_v07.sql` nach data-model.md und research.md R-23: Spalten `preferred_name`, `created_in`, `volunteer_status`, `volunteer_status_since` mit Checks und Indizes; `ea_persons_normalize` um Rufname erweitern; `ea_volunteer_status_history`; Trigger `ea_persons_guard`; Tests T036 grün
- [x] T053 [US-AD-22] (spec T35) Migration `…000800_ea_property_types.sql` nach data-model.md und research.md R-21: `ea_property_types`, `ea_property_fields`, Trigger, `ea_save_property_type(p_type jsonb, p_fields jsonb)`; Policies vorläufig nur für AD (endgültig in T055); Tests T037 grün (soweit ohne Eigenschaften prüfbar)
- [x] T054 [US-AD-13] (spec T36) Migration `…000900_ea_properties.sql` nach research.md R-20: `ea_properties` (`field_values jsonb not null default '{}'`, `related_referat_id`, `related_gremium_id`, `valid_from` Pflicht, `valid_to`, Check `ea_properties_valid_range`), Indizes, Trigger `ea_properties_validate` und `ea_properties_history`, `ea_property_history`; Tests T038 grün
- [x] T055 [US-AD-23] (spec T38) Migration `…001000_ea_visibility.sql` nach research.md R-19 und R-22: Funktionen `ea_person_in_referate`, `ea_person_visible_ad`, `ea_person_visible_ea`, `gr_person_visible` (Platzhalter `false`), `ea_person_visible`, `ea_property_readable`, `ea_property_writable`; bisherige Policies auf `ea_persons` per `drop policy` ersetzen; Policies auf `ea_volunteer_status_history`, `ea_property_types`, `ea_property_fields`, `ea_properties`, `ea_property_history`; Tests T032, T039 grün
- [x] T056 [US-AD-23] (spec T39) Migration `…001100_ea_volunteer_functions.sql`: `ea_set_volunteer_status`, `ea_person_referate`, `ea_create_volunteer(p_first text, p_last text, p_preferred text, p_property_type uuid, p_referat uuid, p_field_values jsonb, p_valid_from date)` ohne EZ-Erweiterung, `ea_activate_person`; alle setzen das Kennzeichen `ea.status_change`; Tests T040 grün
- [x] T057 [US-AD-20] (spec T40) Migration `…000700_ad_start_templates_v07.sql`: Vorlage „Referent:in“ (Rechte über `ad_templates_init_rights`, dann EA `edit` mit scope `referat`), Admin GR `read` nur wo noch `none`; idempotent; Tests T041 grün
- [x] T058 [US-AD-06] (spec T6 Teil, T41, T26 Teil) Migration `…001200_ad_person_overview.sql`: View `ad_v_person_overview` nach data-model.md; `ad_me()` per `drop` und neu mit `preferred_name`; `ad_qualification_usage(p_id uuid)`; Tests T043 grün
- [x] T059 [US-AD-25] (spec T8, T43) Migration `…001300_ad_find_similar_persons.sql` nach research.md R-25; Tests T042 grün
- [x] T060 [US-AD-15] (spec T4 Teil) Migration `…001400_ad_emergency_notice.sql`: `ad_notice_acks` (user_id PK default `auth.uid()`, FK `auth.users(id) on delete cascade`, `emergency_acknowledged_until`), Policies auf die eigene Zeile; `ad_pending_emergency_logins() returns table (count int, last_at timestamptz)` und `ad_acknowledge_emergency()` mit Prüfung AD ≥ read; `cron.schedule('ad_audit_log_retention', '15 1 * * *', $$delete from public.ad_audit_log where occurred_at < now() - interval '5 years'$$)`; Tests T044 grün
- [x] T061 [US-AD-26] (spec T23 Teil, T48) `supabase/seed.sql` nach spec.md Abschnitt 9 und research.md R-26 ergänzen: Personen 9–12 (feste UUIDs `…09`–`…12`), Testzugang test.referent@dav-leipzig.de (aktiv, Vorlage Referent:in mit Referat Klettern, Auth-Nutzer `…09`), 8 Testarten mit Feldern („Hauptamt“, „T-Shirt-Größe“, „Erste-Hilfe-Kurs am“, „Lizenz (Test)“, „Funktion (Test)“, „Amt (Test)“, „Geburtsdatum (Test)“ mit `system_key = 'birth_date'`, „Kontaktdaten (Test)“), Eigenschaften der Personen 2, 4, 5, 7, 9–12, Ehrenamtsstatus mit Historie, Protokolleintrag `template_assigned` für Rita Referentin; keine Personen 13–18, keine Orte, keine Sätze; Tests T046 und alle Sichtbarkeitstests grün
- [x] T062 [P] (spec T12 Teil, T42) `src/lib/errors.ts`: alle Codes des Kerns aus contracts/error-codes.md (Abschnitte AD und EA, ohne die Codes der Nachträge) und die Constraints `ad_template_rights_scope_allowed`, `ad_qualification_types_name_key`, `ad_qualification_types_code_key`, `ea_referate_name_key`, `ea_property_fields_label_key`; `EA_VALUE_TYPE` mit dem neuen Text; Platzhalter `<Feld>` aus dem `detail` des Fehlers füllen
- [x] T063 [P] [US-AD-24] (spec T47 Teil) `src/lib/format.ts`: `personName({ first_name, preferred_name, last_name })` → „Rufname Nachname“, sonst „Vorname Nachname“; `src/components/layout/AppHeader.tsx` nutzt den Rufname aus `ad_me()`
- [x] T064 [P] (spec T12 Teil) `src/lib/rights.ts`: `hasAnyLevel(module, min)` über `rpc('ad_has_any_level')` und `canEditQualificationTypes()` über `rpc('ad_can_edit_qualification_types')`
- [x] T065 Nach TEST ausrollen (nach Prüfung, dass TEST verknüpft ist): `npx supabase db push --linked --dry-run`, dann `npx supabase db push --linked`; danach `supabase/seed.sh` gegen TEST; Ergebnis im Pull Request nennen

**Checkpoint**: Die Datenbank des Kerns steht in TEST; alle Oberflächen-Phasen können beginnen.

---

## Phase 5: US-AD-10, US-AD-20 Rechtevorlagen mit Reichweite (Branch `us-ad-10-rechtevorlagen`)

**Ziel**: Rechtevorlagen in der Oberfläche anlegen und ändern, mit Spalte Reichweite.

**Unabhängiger Test**: test.admin legt eine Vorlage an, ändert eine Stufe der Vorlage Vorstand und erhält bei einem doppelten Namen „Eine Rechtevorlage mit diesem Namen gibt es bereits.“; „Referat“ ist nur bei Ehrenamtsmanagement wählbar; die Vorlage „Referent:in“ zeigt EA bearbeiten mit Reichweite Referat (US-AD-10 AK1–AK3, US-AD-20 AK1–AK3).

- [x] T066 [US-AD-10] Bestehenden Branch `us-ad-10-rechtevorlagen` auf `main` rebasen; die Änderungen an `docs/offene-punkte.md` und an `tasks.md` aus Commit `ddf6279` nicht übernehmen; Code aus `fc70e8e` (AdLayout, Rechtevorlagen-Liste und -Formular, `data.ts`, `access.ts`) übernehmen und an T062–T064 anpassen
- [x] T067 [US-AD-10] (spec T20 Teil) `src/features/ad/AdLayout.tsx`: Navigation Personen · Rechtevorlagen · Eigenschaftsarten · Qualifikationsarten · Protokoll; Unterrouten in `src/App.tsx`; Schreibknöpfe nur bei `ad_has_level('AD','edit')`
- [x] T068 [P] [US-AD-10] (spec T20) `src/features/ad/rechtevorlagen/RechtevorlagenListe.tsx`: Spalten Name, Beschreibung, Anzahl Personen (wirksame Zuweisungen); Knöpfe „Neu“ und „Öffnen“; mobil als Karten
- [x] T069 [US-AD-20] (spec T20, T44 Teil) `src/features/ad/rechtevorlagen/RechtevorlageBearbeiten.tsx` (/ad/rechtevorlagen/neu und /:id): Name, Beschreibung, Matrix mit den 9 Modulen aus `ad_modules` und je einer Auswahl „kein Zugriff / lesen / bearbeiten / verwalten“; Spalte Reichweite „alle / Referat“, „Referat“ nur bei Ehrenamtsmanagement wählbar; Speichern (insert/update `ad_templates`, update `ad_template_rights.level` und `scope`); Fehler über `errors.ts` (R30)

**Checkpoint**: Vorlagen mit Reichweite sind über die Oberfläche pflegbar.

---

## Phase 6: US-AD-06, US-AD-15 Personenübersicht (Branch `us-ad-06-personen`)

**Ziel**: Übersicht aller lesbaren Personen mit Status, Ehrenamtsstatus, Vorlagen, Suche, Filtern, Paginierung und Notfall-Hinweis.

**Unabhängiger Test**: test.admin sieht 12 Personen mit Status, Ehrenamtsstatus und Vorlagen (Person 9 mit „Klettern“); Suche nach „Muster“ und nach einem Rufnamen, Filter „gesperrt“ und „nur Gruppen“ (Person 12) funktionieren; „Keine Personen gefunden.“; nach einer Anmeldung von test.notfall erscheint der Hinweis und verschwindet mit „Zur Kenntnis genommen“; test.vorstand landet auf /kein-zugriff (US-AD-06 AK1–AK5, US-AD-15 AK2).

- [x] T070 [P] [US-AD-06] (spec T15 Teil) `src/components/StatusBadge.tsx` (kein Zugang / eingeladen / aktiv / gesperrt), `src/components/ResponsiveTable.tsx` (Tabelle ab 640 px, darunter Karten), `src/components/Pagination.tsx` (50 je Seite, „Zurück“/„Weiter“, Anzeige „n–m von k“)
- [x] T071 [US-AD-06] (spec T15) `src/features/ad/personen/PersonenUebersicht.tsx` (/ad) aus `ad_v_person_overview`: Name über `personName()`, Kennzeichen „Funktionsperson“, Login-Adresse, Status-Badge, Ehrenamtsstatus (falls vorhanden), Vorlagen mit Referaten; Suche nach Vor-, Ruf- und Nachname; Filter Zugangsstatus; Filter Zugehörigkeit (mit Zugang, Funktionsperson, Ehrenamtsmanagement, nur Gruppen, ohne Zugehörigkeit) nach research.md R-28; Paginierung; „Keine Personen gefunden.“; Knöpfe „Person anlegen“ und „Öffnen“
- [x] T072 [US-AD-15] (spec T15 Teil) `src/features/ad/personen/NotfallHinweis.tsx` oben in `PersonenUebersicht.tsx`: „Der Notfall-Admin hat sich n-mal angemeldet, zuletzt am TT.MM.JJJJ um HH:MM.“ mit dem Knopf „Zur Kenntnis genommen“ (`rpc('ad_acknowledge_emergency')`); nur bei count > 0

**Checkpoint**: Die Übersicht zeigt die Seed-Daten aller Pfade.

---

## Phase 7: US-AD-07, US-AD-24, US-AD-25 Person anlegen mit Dublettenwarnung (Branch `us-ad-07-person-anlegen`)

**Ziel**: Person mit Rufname anlegen; modulübergreifende Dublettenwarnung als wiederverwendbare Komponente; Seitengerüst der Personendetails.

**Unabhängiger Test**: „Erika Neu“ wird ohne Warnung angelegt; „Tony Muster“ zeigt Toni und Anton Muster nur mit Name, Rufname, Geburtsjahr bzw. „ausgeschieden seit“; „Trotzdem anlegen“ legt an; „Vorhandene Person öffnen“ nur bei sichtbaren Treffern; leerer Name, fremde Domain, doppelte Login-Adresse zeigen R4, R1, R2 (US-AD-07 AK1–AK5, US-AD-25 AK1–AK3, US-AD-24).

- [x] T073 [P] [US-AD-25] (spec T49 Teil) `src/features/shared/DublettenDialog.tsx`: Trefferliste nach R40 (Name über `personName()`, Geburtsjahr, „ausgeschieden seit TT.MM.JJJJ“), Aktionen als Props je Modul (in AD: „Trotzdem anlegen“, „Vorhandene Person öffnen“ nur bei `is_visible`, „Abbrechen“)
- [x] T074 [US-AD-07] (spec T16) `src/features/ad/personen/PersonNeu.tsx` (/ad/personen/neu): Vorname, Nachname, optional Rufname, optional Login-Adresse; R4 im Frontend; `rpc('ad_find_similar_persons')`; bei Treffern `DublettenDialog`; Anlegen: insert `ea_persons`, bei Login-Adresse insert `ad_accesses`; Fehler über `errors.ts`
- [x] T075 [US-AD-24] (spec T17 Teil, T47 Teil) `src/features/ad/personen/PersonDetail.tsx` (/ad/personen/:id): Seitengerüst mit den Abschnitten Stammdaten, Zugang, Rechtevorlagen, Eigenschaften; `StammdatenAbschnitt.tsx`: Vorname, Rufname, Nachname bearbeitbar, Art als Anzeige, Ehrenamtsstatus nur lesen mit „seit TT.MM.JJJJ“

**Checkpoint**: Anlegen, Dublettenwarnung und Stammdaten funktionieren.

---

## Phase 8: US-AD-17, US-AD-18 Qualifikationsarten (Branch `us-ad-17-qualifikationsarten`)

**Ziel**: Qualifikationsarten ansehen, anlegen, ändern, auf „historisch“ setzen; Auswahlfeld „Qualifikationsart“ als Komponente.

**Unabhängiger Test**: Liste mit 47 Einträgen, gruppiert nach Sparte, Standardfilter „aktuell“; Suche nach „TCSPI“; Anlegen und Ändern durch test.admin und test.geschaeftsstelle mit den Meldungen R21–R26; test.vorstand sieht keine Bearbeiten-Knöpfe; Detail zeigt „Verwendet bei n Personen“ (US-AD-17, US-AD-18).

- [x] T076 [P] [US-AD-19] (spec T30 Teil) `src/features/shared/QualifikationsartAuswahl.tsx`: durchsuchbar nach Bezeichnung und Kürzel, Anzeige „Kürzel – Bezeichnung“, gruppiert nach Sparte, nur Status „aktuell“ und erlaubte Typen (Prop)
- [x] T077 [P] [US-AD-17] (spec T30) `src/features/ad/qualifikationsarten/QualifikationsartenListe.tsx` (/ad/qualifikationsarten): Tabelle gruppiert nach Sparte mit Kürzel, Bezeichnung, Typ, Lizenzstufe, Gültigkeitsdauer, Status-Badge; Suche; Filter Sparte, Typ, Status (Standard „aktuell“); „Keine Qualifikationsarten gefunden.“
- [x] T078 [US-AD-17] (spec T30) `src/features/ad/qualifikationsarten/QualifikationsartFormular.tsx` (/ad/qualifikationsarten/neu und /:id): Felder nach spec.md Abschnitt 6 (Sparte und Aussteller mit Vorschlägen aus vorhandenen Werten, Lizenzstufe nur bei Lizenz, Gültigkeitsdauer nach R24, DOSB „ja / nein / nicht bekannt“, Quell-ID nur lesen); Detail mit „Verwendet bei n Personen“ (`rpc('ad_qualification_usage')`) und geändert am/von; nach Änderung der Gültigkeitsdauer Hinweis „Die Änderung gilt für neue Einträge. Vorhandene Ablaufdaten bleiben unverändert.“ (R26); Bearbeiten nur bei `canEditQualificationTypes()`
- [x] T079 [US-AD-17] (spec T30) Routen /ad/qualifikationsarten* in `src/App.tsx`; die Komponenten so ablegen, dass /ea/qualifikationsarten sie mit EA ohne Änderung einhängt (Routen unter /ea noch nicht aktiv)

**Checkpoint**: Qualifikationsarten sind pflegbar.

---

## Phase 9: US-AD-12, US-AD-19, US-AD-22 Eigenschaftsarten mit Feldern (Branch `us-ad-12-eigenschaftsarten`)

**Ziel**: Eigenschaftsarten mit Zweck, Kategorie, Lesestufe, Bezug, „sichtbar in“ und Feldern pflegen.

**Unabhängiger Test**: Anlegen mit Hinweis Art. 9 DSGVO; Art „Lizenz (Test)“ mit drei Feldern (Qualifikationsart nur Typ Lizenz); Meldungen zu R9, R29, R36 und doppeltem Namen; test.geschaeftsstelle sieht „vertraulich“ nicht als Option und keine vertraulichen Arten (US-AD-12, US-AD-19 AK1, US-AD-22).

- [x] T080 [P] [US-AD-22] (spec T46) `src/features/ad/eigenschaftsarten/EigenschaftsartenListe.tsx` (/ad/eigenschaftsarten): Name, Kategorie, Lesestufe, Bezug, Anzahl Felder, sichtbar in; „Noch keine Eigenschaftsarten.“
- [x] T081 [US-AD-22] (spec T46) `src/features/ad/eigenschaftsarten/EigenschaftsartBearbeiten.tsx` (/ad/eigenschaftsarten/neu und /:id):
  - Name, Zweck, Kategorie, Lesestufe (drei Optionen mit Erklärung; „vertraulich“ nur mit AD ≥ bearbeiten), Bezug (kein / Referat / Gremium; „Gruppe“ nur mit GR = verwalten), Bezug Pflicht, mehrere gültige Einträge erlaubt, sichtbar in (Mehrfachauswahl aus `ad_modules`).
  - Felder als Liste: Bezeichnung, Schlüssel (aus der Bezeichnung vorgeschlagen, nach Anlage nicht änderbar), Datentyp (Text, Zahl, Datum, Jahr, Ja/Nein, Auswahlliste, Qualifikationsart), Pflicht, Auswahlwerte bzw. erlaubte Typen (Mehrfachauswahl, leer = alle), Reihenfolge per Auf/Ab; vorhandene Auswahlwerte nicht entfernbar; Datentyp gesperrt, wenn Eigenschaften existieren.
  - Beim Anlegen der Hinweis „Erfasse keine Gesundheitsdaten, Religion, politische Meinung oder andere besondere Kategorien nach Art. 9 DSGVO.“
  - Speichern über `rpc('ea_save_property_type')`; Fehler über `errors.ts`.

**Checkpoint**: Eigenschaftsarten mit Feldern sind pflegbar.

---

## Phase 10: US-AD-13, US-AD-19, US-AD-23 Eigenschaften einer Person (Branch `us-ad-13-eigenschaften`)

**Ziel**: Eigenschaften an der Person nach Kategorie mit Feldern, Bezug, Gültigkeit und Historie; Eigenschaftsformular als Komponente.

**Unabhängiger Test**: Bei Person 4 erscheinen die Eigenschaften nach Kategorie, Felder als „Bezeichnung: Wert“, Bezug als „Referat Klettern“, Qualifikationsart als „TCSPI – …“; Anlegen, Ändern, Beenden mit Historie; Meldungen zu R27, R28, R35, R37, R38; nur Arten mit „sichtbar in“ AD (US-AD-13 AK1–AK6, US-AD-19 AK2–AK4).

- [x] T082 [P] [US-AD-19] (spec T47) `src/features/shared/Eigenschaftsformular.tsx`: Eingaben aus `ea_property_fields` (Text, Zahl, Datum, Jahr, Ja/Nein, Auswahlliste, Qualifikationsart über `QualifikationsartAuswahl`), Bezug-Auswahl (aktive Referate bzw. Gremien; bei Reichweite Referat nur `ad_my_referate`), gültig von/bis; Fehler je Feld (R35)
- [x] T083 [US-AD-13] (spec T19, T47) `src/features/ad/personen/EigenschaftenAbschnitt.tsx` in `PersonDetail.tsx`: nach Kategorie gruppiert, aktuelle oben, beendete (`valid_to < heute`) als „beendet“; nur Arten mit `visible_in` ∋ `AD`; Felder als „Bezeichnung: Wert“; historische Qualifikationsart mit „(historisch)“; Historie je Eigenschaft aufklappbar (geändert am/von); Hinzufügen, Ändern, Beenden über `Eigenschaftsformular`; „Noch keine Eigenschaften.“

**Checkpoint**: Eigenschaften mit Feldern und Historie sind pflegbar.

---

## Phase 11: US-AD-11, US-AD-21 Rechtevorlagen zuweisen mit Referaten (Branch `us-ad-11-zuweisen`)

**Ziel**: Vorlagen an der Person zuweisen und entziehen; Referate bei Vorlagen mit Reichweite „Referat“.

**Unabhängiger Test**: Geschäftsstelle und Vorstand zuweisen ergibt die höhere Stufe, mit Protokoll; Referent:in ohne Referat → „Bitte mindestens ein Referat auswählen.“; Referat ändern schreibt „Referate geändert“; Entziehen wird protokolliert; zugewiesene Vorlagen werden nicht erneut angeboten (US-AD-11 AK1–AK3, US-AD-21 AK1–AK3).

- [x] T084 [US-AD-21] (spec T18, T44 Teil) `src/features/ad/personen/RechtevorlagenAbschnitt.tsx` in `PersonDetail.tsx`: wirksame Vorlagen mit Referaten; „Vorlage hinzufügen“ nur mit nicht zugewiesenen Vorlagen, bei Reichweite Referat Mehrfachauswahl der aktiven Referate (`rpc('ad_assign_template', { p_referate })`); „Referate ändern“ (`rpc('ad_set_assignment_referate')`); „Entziehen“ mit Bestätigung (`rpc('ad_revoke_template')`)

**Checkpoint**: Zuweisungen mit Referaten sind pflegbar.

---

## Phase 12: US-AD-08, US-AD-03, US-AD-04, US-AD-09 Zugang (Branch `us-ad-08-zugang`)

**Ziel**: Einladen, erneut einladen, Login-Adresse nach R20 ändern, Passwort setzen, Passwort vergessen, sperren und entsperren.

**Unabhängiger Test**: Deno-Tests grün (Aufräumen bei simuliertem Fehler, 403 ohne Recht); in TEST „Einladen“ ohne Vorlage → R17; Sperren von Eva Eingeladen und Entsperren von Dieter Gesperrt nach spec.md Abschnitt 4; Mailversand wird in T103 mit eigenen Adressen des Product Owners abgenommen.

### Tests für Phase 12 ⚠️

- [x] T085 [P] [US-AD-08] (spec T7 Teil) `supabase/tests/database/210_invite_functions.test.sql`: `authenticated` darf `ad_apply_invite`, `ad_revert_invite` und `ad_apply_email_change` nicht ausführen, `service_role` darf es; `ad_apply_invite` setzt `invited`, `last_invited_at`, `auth_user_id` und schreibt `invited`; `ad_revert_invite` stellt den Ausgangsstand ohne Protokoll her; `ad_apply_email_change` setzt die neue Adresse, `auth_user_id` null, `none` und schreibt `email_changed` mit „alt → neu“
- [x] T086 [P] [US-AD-08] (spec T9) Deno-Test `supabase/functions/ad-invite/index.test.ts` mit simuliertem Auth-Admin-Client und DB-Client: 401 ohne JWT; 403 `AD_FORBIDDEN` ohne AD ≥ edit; 422 `AD_EMAIL_MISSING` / `AD_EMAIL_DOMAIN` / `AD_NO_TEMPLATE`; 409 `AD_EMAIL_TAKEN` / `AD_INVALID_STATUS`; Erfolg ruft `ad_apply_invite`; simulierter Fehler von `inviteUserByEmail`: neu angelegter Auth-Eintrag wird mit `deleteUser` gelöscht, `ad_revert_invite` aufgerufen, kein `ad_apply_invite`, 502 `AD_MAIL_FAILED`; bei erneuter Einladung wird nichts gelöscht
- [x] T087 [P] [US-AD-08] (spec T10 Teil) Deno-Test `supabase/functions/ad-access/index.test.ts`, Fälle `change_email`: nur bei `invited`, sonst 409 `AD_EMAIL_LOCKED`; R1 → `AD_EMAIL_DOMAIN`; R2 → `AD_EMAIL_TAKEN`; Erfolg: `deleteUser`, dann `ad_apply_email_change`, 200 mit `code: "AD_EMAIL_CHANGED"`; Fehler bei `deleteUser` → keine DB-Änderung; 403 ohne Recht; 400 ohne `login_email`
- [x] T088 [P] [US-AD-09] (spec T7 Teil) `supabase/tests/database/220_lock_functions.test.sql`: `ad_apply_lock` setzt `locked`, `locked_at`, `locked_by`, schreibt `locked`; danach `ad_user_level` und `ad_my_referate` sofort leer (R5, R10); `ad_apply_unlock` führt mit Passwort zu `active`, ohne zu `invited`, schreibt `unlocked`; Eigenschaften und Zuweisungen bleiben; nur `service_role`
- [x] T089 [P] [US-AD-09] (spec T10 Teil) `supabase/functions/ad-access/index.test.ts` ergänzen, Fälle `lock`/`unlock`: Ausgangsstatus nach contracts/edge-functions.md, sonst 409 `AD_INVALID_STATUS`; `ban_duration: '876000h'` bzw. `'none'`, danach `ad_apply_lock`/`ad_apply_unlock`; 403 ohne Recht

### Umsetzung für Phase 12

- [x] T090 [US-AD-08] (spec T4 Teil) Migration `supabase/migrations/20261023001500_ad_invite_functions.sql`: `ad_apply_invite(p_person uuid, p_auth_user uuid, p_actor uuid)`, `ad_revert_invite(p_person uuid, p_status ad_access_status, p_auth_user uuid, p_last_invited_at timestamptz)`, `ad_apply_email_change(p_person uuid, p_new_email citext, p_actor uuid)` (setzt `set_config('ad.email_change','on', true)`); security definer; nur `grant execute … to service_role`; Tests T085 grün
- [x] T091 [US-AD-09] (spec T4 Teil) Migration `…001600_ad_lock_functions.sql`: `ad_apply_lock(p_person uuid, p_actor uuid)`, `ad_apply_unlock(p_person uuid, p_actor uuid)` (Zielstatus über `auth.users.encrypted_password`); security definer; nur `service_role`; Tests T088 grün
- [x] T092 [P] [US-AD-08] (spec T9 Teil, T10 Teil) `supabase/functions/_shared/`: `cors.ts` (Origins aus den Redirect-URLs), `caller.ts` (Client mit dem JWT des Aufrufers und `rpc('ad_has_level', { p_module: 'AD', p_min: 'edit' })`), `responses.ts` (JSON `{ code }` mit HTTP-Status nach contracts/edge-functions.md), `admin.ts` (Service-Client aus `SUPABASE_SERVICE_ROLE_KEY` der Edge-Umgebung)
- [x] T093 [US-AD-08] (spec T9) `supabase/functions/ad-invite/index.ts`: Handler mit übergebbaren Clients nach contracts/edge-functions.md (Vorbedingungen, `inviteUserByEmail` mit `redirectTo` `<SITE_URL>/passwort-setzen`, Aufräumen bei Fehlern); Tests T086 grün
- [x] T094 [US-AD-09] (spec T10) `supabase/functions/ad-access/index.ts` mit `change_email`, `lock`, `unlock` nach contracts/edge-functions.md; Tests T087, T089 grün
- [x] T095 [US-AD-08] (spec T17 Teil) `src/features/ad/personen/ZugangAbschnitt.tsx` in `PersonDetail.tsx`: Login-Adresse, Status, zuletzt eingeladen, gesperrt am/von; Login-Adresse speichern bei „kein Zugang“ direkt, bei „eingeladen“ über `functions.invoke('ad-access', { action: 'change_email' })` mit Hinweis `AD_EMAIL_CHANGED`, sonst nicht bearbeitbar; „Einladen“ / „Erneut einladen“ (ohne wirksame Vorlage deaktiviert, Hinweis R17); „Sperren“ mit Bestätigung und „Bereits angemeldete Nutzer verlieren den Zugriff spätestens nach einer Stunde.“; „Entsperren“
- [x] T096 [P] [US-AD-03] (spec T13 Teil) `src/features/auth/PasswortSetzenPage.tsx` (/passwort-setzen?token_hash=…&type=invite|recovery): Passwort und Wiederholung; R19 vor dem Absenden („Das Passwort muss mindestens 8 Zeichen lang sein.“, „Die Passwörter stimmen nicht überein.“); erst beim Speichern `verifyOtp({ token_hash, type })`, dann `updateUser({ password })`, Erfolg → /; ungültiger Link: bei `invite` „Der Link ist abgelaufen oder ungültig. Bitte wende dich an den Admin.“, bei `recovery` „Der Link ist abgelaufen oder ungültig. Bitte fordere einen neuen an.“
- [x] T097 [P] [US-AD-04] (spec T13 Teil) `src/features/auth/PasswortVergessenPage.tsx` (/passwort-vergessen): Login-Adresse; `resetPasswordForEmail(email, { redirectTo: <origin>/passwort-setzen })`; zeigt immer „Wenn ein Zugang zu dieser Adresse besteht, haben wir dir eine E-Mail mit einem Link geschickt.“ (R18), auch bei Fehlern
- [x] T098 [US-AD-08] (spec T9, T10) Nach TEST ausrollen (nach Prüfung, dass TEST verknüpft ist): `npx supabase db push --linked`, `npx supabase functions deploy ad-invite ad-access`

**Checkpoint**: Zugänge sind in TEST vollständig verwaltbar; Mailversand folgt in T103.

---

## Phase 13: US-AD-14 Protokoll einsehen (Branch `us-ad-14-protokoll`)

**Ziel**: Protokollansicht mit Namen. Löschlauf und Unveränderbarkeit sind mit T044/T060 erledigt.

**Unabhängiger Test**: test.admin sieht die Seed-Einträge, neueste zuerst, mit Namen und deutschen Aktionen inkl. „Referate geändert“; „Noch keine Einträge.“; test.geschaeftsstelle erhält keine Daten (US-AD-14 AK1, AK3, AK5).

- [x] T099 [P] [US-AD-14] (spec T7 Teil) `supabase/tests/database/230_audit_view.test.sql`: `ad_v_audit_log` liefert für test.admin den Namen des Akteurs und der betroffenen Person, für test.geschaeftsstelle 0 Zeilen
- [x] T100 [US-AD-14] (spec T4 Teil) Migration `supabase/migrations/20261023001700_ad_audit_view.sql`: View `ad_v_audit_log` (`security_invoker = true`) mit Namen der betroffenen Person und des Akteurs (über `ad_accesses.auth_user_id` → `ea_persons`, Rufname bevorzugt); `grant select … to authenticated`; Tests T099 grün
- [x] T101 [US-AD-14] (spec T22) `src/features/ad/protokoll/ProtokollPage.tsx` (/ad/protokoll): Zeitpunkt, ausgeführt von, betroffene Person, Aktion (eingeladen, Login-Adresse geändert, Vorlage zugewiesen, Vorlage entzogen, Referate geändert, gesperrt, entsperrt, Anmeldung Notfall-Admin), Details; neueste zuerst, 50 je Seite; „Noch keine Einträge.“

**Checkpoint**: Das Protokoll ist einsehbar.

---

## Phase 13a: Review des Kerns (Branch `ad-kern-review-1`, spec v0.9.3 / Kern v0.7.4)

**Zweck**: Bestätigte Befunde aus dem Review-Workflow und die vier Entscheidungen des Product Owners vom 23.10.2026 (spec.md Abschnitt 11) umsetzen.

- [x] T106 [US-AD-07] (spec T5 Teil, T4 Teil, T39 Teil) `supabase/tests/database/240_review_1.test.sql` und Migration `supabase/migrations/20261023001800_ad_review_1.sql`: `ad_login_email_ok` (R1 im Frontend), Protokolleintrag `invited` ohne Akteur bei Einladung über das Dashboard (Trigger) und Vervollständigung in `ad_apply_invite`, `ea_check_create` prüft Lesestufe/Bezugsart (R29, R39, R41), `ea_person_in_referate` ohne Grant an `authenticated`
- [x] T107 [US-AD-03] [US-AD-09] `supabase/functions/ad-invite/handler.ts`, `ad-access/handler.ts`, `_shared/db.ts`, `ad-access/index.test.ts`: Rechteprüfung vor der Body-Validierung, Datenbankfehler in `hasAdEdit` → 500, Fehler beim Aufräumen des Auth-Eintrags im Log; Tests 401/404/403-vor-400
- [x] T108 [US-AD-07] [US-AD-12] [US-AD-17] Frontend: `PersonNeu.tsx`/`personen/data.ts` prüfen R1 vor dem Anlegen (`checkLoginEmail`), `eigenschaftsarten/data.ts` schickt `allowed_qualification_kinds: []` zum Zurücksetzen (R28), `lib/functions.ts` leitet bei 401 zu /login, `DublettenDialog.tsx` ohne hängendes „ · “, `NotfallHinweis.tsx` „n-mal“, `QualifikationsartFormular.tsx` prüft Sparte/Aussteller, `lib/errors.ts` mit Constraints `ea_property_types_valid_from_label_length`/`…_to_label_length`, `ea_referate_name_key`, `ea_gremien_name_key`, `ad_qualification_types_discipline_not_blank`/`…_issuer_not_blank`
- [x] T109 [P] Doku: spec.md v0.9.3 (Abschnitt 2, 4, 5 R1/R42, 11), 02-stories.md v0.8.2 (US-AD-06 AK5, US-AD-07 AK5), contracts/error-codes.md (Status „umgesetzt“ für Edge-Codes, R26-Hinweis, `AD_SCOPE_NOT_ALLOWED`; Frontend-Meldungen als [ANNAHME]), data-model.md
- [x] T110 (spec T9, T10) Nach TEST ausrollen (23.10.2026, nach Merge von PR #31): `npx supabase db push --linked` (`20261023001800_ad_review_1.sql`), `npx supabase functions deploy ad-invite ad-access`

---

## Phase 14: Abnahme und Querschnitt (Branch `ad-kern-abnahme`)

**Zweck**: Fachliche Abnahme des Kerns in TEST (spec T25, T32, T49) und Abschluss.

- [ ] T102 [US-AD-25] (spec T25 Teil) Dublettenschwelle in TEST abnehmen (quickstart.md C: Toni/Anton/Tony Muster, Tippfehler) und das Ergebnis in `docs/specs/ad-administration/abnahme-test.md` festhalten (ohne private Adressen); bei Bedarf Schwelle per neuer Migration anpassen (Rückfrage beim Product Owner)
- [ ] T103 [US-AD-08] (spec T25 Teil) Abnahmeablauf C1 vorbereiten: TEST auf Stand (`db push`, `functions deploy`, Seed; Auth-Einstellungen hat der Product Owner nach `supabase/setup/README.md` gesetzt). Danach führt **der Product Owner selbst** C1 durch (Domain per SQL-Editor, Personen mit eigenen Adressen, Einladung, Adressänderung, Passwort setzen, Passwort vergessen) und räumt nach C2 auf. Claude Code trägt keine Domain und keine Adresse ein. Ergebnis ohne Adressen in `abnahme-test.md`. Betrifft US-AD-03, US-AD-04, US-AD-08
- [ ] T104 [US-AD-26] (spec T25 Teil, T32, T49) Szenarien aus quickstart.md C und C3 mit den Testzugängen Admin, Geschäftsstelle, Referent:in, Vorstand und test.notfall abnehmen, auch bei 375 px; offene `[PRÜFEN T25]`-Punkte aus research.md abhaken bzw. melden; Ergebnis in `abnahme-test.md`
- [x] T105 [P] (spec T12 Teil) Querschnitt: `npm run lint` und `npm run build` ohne Fehler; `npm audit` und Ergebnis melden; keine Secrets oder realen Adressen im Diff (`git grep` auf `@` außerhalb von `@dav-leipzig.de`, `example.test`, `example.org`)

---

## Phase 15: Nachtrag v0.8 Anwesenheitserfassung (Branch `ad-nachtrag-v08`, spec v0.9.4 / Nachtrag v0.8.1)

**Zweck**: spec T50–T58 inklusive Übergabe EZ A9 (US-AD-27 bis US-AD-30). Datenbank, pgTAP und Seed; die Oberfläche (spec T55) ist zurückgestellt, weil `src/` für die Sitzung vom 24.10.2026 ausgeschlossen war. `ad_modules.is_available` für EZ bleibt `false`.

**Unabhängiger Test**: pgTAP 250–280 grün; bestehende Tests an das neue Modul angepasst; die EZ-Pfade in `480_gr_read_functions.test.sql` (`todo`) laufen durch.

- [x] T111 [US-AD-28] (spec T50, T56 Teil) `supabase/tests/database/250_ez_module.test.sql` und `supabase/migrations/20261026000100_ad_ez_module.sql`: Modul EZ direkt nach GR (`is_available = false`), Zeile EZ je Vorlage, Startwerte Admin `read`, Geschäftsstelle `manage`, Referent:in `edit`/`referat`, Vorstand `none` ohne Änderungen des Admins zu überschreiben, Check und Trigger R30 für EA und EZ, `ea_persons.created_in` mit `EZ`
- [x] T112 [US-AD-27] (spec T51, T56 Teil) `supabase/tests/database/260_ad_locations.test.sql` und `supabase/migrations/20261026000200_ad_locations.sql`: Tabelle `ad_locations`, „Bezeichnung getrimmt, nicht leer; eindeutig ohne Groß-/Kleinschreibung“ (R43, `AD_LOCATION_NAME_REQUIRED`, `AD_LOCATION_NAME_TAKEN`), `ad_can_edit_locations()` = nur Admin, RLS lesen mit aktivem Zugang, kein Delete
- [x] T113 [US-AD-29] (spec T52, T56 Teil, Abschnitt 8) `supabase/tests/database/270_name_functions.test.sql` und `supabase/migrations/20261026000300_ad_name_functions.sql`: `ez_person_visible` (Platzhalter), `ea_person_names` (höchstens 500 IDs, `AD_TOO_MANY_IDS`), `ea_search_active_persons` (EZ ≥ bearbeiten, ≥ 2 Zeichen, 1–50 Treffer, nur „aktiv“); Mengentest 300 Aktive / 50 IDs je < 300 ms
- [x] T114 [US-AD-30] (spec T53, T56 Teil; A4, A9) `supabase/tests/database/280_ez_create.test.sql` und `supabase/migrations/20261026000400_ad_ez_create.sql`: `ea_create_path` (research.md R-30), `ea_create_volunteer` mit `p_contact_email` und `created_in = 'EZ'`, `ea_activate_person` mit EZ-Weg (ruhend, ausgeschieden, ohne Status, auch referatsübergreifend; R45a), `ad_find_similar_persons` mit EZ ≥ bearbeiten; Test mit einem Nutzer nur mit EZ-Rechten (Entscheidung Product Owner 24.10.2026)
- [x] T115 Bestehende pgTAP-Tests an das Modul EZ angepasst: `010_foundation` (10 Module, Reihenfolge), `020_persons_rights` (Startvorlagen, 10 Zeilen je Vorlage), `050_policies` und `140_volunteer_functions` (neue Signatur), `100_persons_v07` (`created_in` EZ zulässig), `150_start_templates` (Referent:in EZ)
- [x] T116 [US-AD-27] (spec T57) `supabase/seed.sql`: Testorte „Kletterhalle Test“ (Punktekonto, aktiv), „Fels Test“, „Halle alt Test“ (inaktiv); Testzugänge erhalten die EZ-Startwerte über ihre Vorlagen
- [x] T117 [P] (spec T54) `contracts/error-codes.md` (Status v0.8, `EA_CREATE_FOREIGN_REFERAT` entfällt, `AD_TOO_MANY_IDS` allgemeine Meldung, Text `AD_SCOPE_NOT_ALLOWED`), `contracts/database-api.md`
- [x] T118 [P] `plan.md` (Abschnitt Nachtrag v0.8), `research.md` (R-30, R-31), `data-model.md`, `quickstart.md` (C4)
- [x] T119 Übergabe an Gruppen `docs/specs/ad-administration/uebergabe-gruppen-v08.md` und Hinweis in `docs/offene-punkte.md` (Abschnitt Gruppen): EZ-Pfade in `480_gr_read_functions.test.sql` aktivieren (PR #28, gemergt 24.10.2026)
- [ ] T120 [US-AD-27] [US-AD-28] [US-AD-29] (spec T55) Oberfläche: Zeile Anwesenheitserfassung und Reichweite „Referat“ für EZ in der Vorlagen-Matrix (R30, neuer Meldungstext in `src/lib/errors.ts`), /ad/orte Liste und Formular mit Navigationseintrag, Komponenten „Personensuche Aktive“ und „Auswahlfeld Ort“ – **zurückgestellt** (src/ nicht Teil der Sitzung vom 24.10.2026)
- [ ] T121 (spec T58) Nach Freigabe des Product Owners nach TEST ausrollen (`npx supabase db push --linked`, Seed-Ergänzung Orte) und quickstart.md C4 mit den Testzugängen abnehmen

## Phase 16: Nachtrag v0.10 Finanzen und Aktion „freigeben“ (Branch `ad-nachtrag-v010`, spec v0.10.0)

**Zweck**: spec T68–T73, T75, T76 sowie T60 und der Vergütungsteil von T61 (Sätze aus Nachtrag v0.9, mit Finanzen vorgezogen). Datenbank, pgTAP, Seed, Fehlercodes. Die Oberfläche (spec T74) folgt auf einem eigenen Branch, weil `src/` nicht auto-gemergt wird. Die Schlüssel der Planungshilfe außerhalb der Vergütung (Reisekosten, Beitrag, Zahlungsgebühren, Klima, Grenzwerte der Planung) kommen mit der Planungshilfe (T61 Rest); für `flight_min_km` gibt es noch keinen Wert.

**Unabhängiger Test**: pgTAP 290–293 grün; angepasste Tests 020, 070, 150 grün.

- [x] T122 [spec T68] `supabase/migrations/20261029000100_ad_approve.sql`, `supabase/tests/database/290_ad_approve.test.sql`: Spalte `ad_template_rights.can_approve` mit Check und Trigger (R50, `AD_APPROVE_NOT_ALLOWED`), R30 für EA, EZ, TK, FI; `ad_my_approve_referate`, `ad_has_approve`, `ad_can_approve`
- [x] T123 [spec T60, T61 Teil, T69 Teil] `supabase/migrations/20261029000200_ad_rates.sql`, `supabase/tests/database/291_ad_rates.test.sql`: Enum `ad_rate_group`, Tabelle `ad_rates` (R46), `ad_can_edit_rates`, `ad_can_read_rates` (ohne TKF), `ad_rates_at`; Startbestand Vergütung (`rTL`, `rTLh`, `rH`, `rHh`, `rOrg`, `rLE`, `rTE`, `rTEH`, `rFT`, `rFTh`, `rFH`, `rFHh`, `rWK`, `rWKH`) und `maxUeL` (3.000 € ab 2021, 3.300 € ab 2026)
- [x] T124 [spec T69, T70] `supabase/migrations/20261029000300_ad_remuneration.sql`, `supabase/tests/database/292_ad_remuneration.test.sql`: `ad_remuneration_kinds`, `ad_remuneration_positions`, `ad_remuneration_defaults`, `ad_settlement_deadlines`, `ad_payout_settings`, `ea_referate.semiannual_settlement` (R51–R54) mit Startbestand; `ad_can_edit_remuneration`, `ad_can_read_remuneration`, `ad_remuneration_default_at`, `ad_settlement_deadline`, `ad_payout_settings_at`
- [x] T125 [spec T71] `supabase/migrations/20261029000400_ad_fi_start_values.sql`: Referent:in FI lesen + freigeben (Reichweite Referat), ohne Änderungen des Admins zu überschreiben; Tests 020, 150 angepasst, 070 prüft den Check jetzt mit SC
- [x] T126 [spec T72] `supabase/migrations/20261029000500_ad_finance_data.sql`, `supabase/tests/database/293_ad_finance_data.test.sql`: `fi_person_visible` (Platzhalter), `ea_person_names` um Finanzen erweitert, `ea_person_finance_data` (R55, R56)
- [x] T127 [P] [spec T73] `contracts/error-codes.md`: neue Codes v0.10, Text `AD_SCOPE_NOT_ALLOWED`
- [x] T128 [spec T76] `supabase/seed.sql`: fiktive Angaben der Sektion (Beispiel-IBAN, BIC `TESTDEFFXXX`, Sachkonto „0000 0“)
- [x] T129 [spec T74] Oberfläche (Branch `us-ad-v010-oberflaeche`; zusätzlich Reichweite „Referat“ für EZ in der Matrix, Teil von T120): Spalte „darf freigeben“ in der Vorlagen-Matrix, Seiten /ad/saetze (aus v0.9 T64), /ad/abrechnungsarten, /ad/auszahlung, Navigationseinträge – eigener Branch `us-ad-v010-oberflaeche`
- [x] T130 [spec T77] Nach Freigabe des Product Owners nach TEST ausrollen und mit Admin und Geschäftsstelle abnehmen (Product Owner 26.10.2026, mit der Abnahme Finanzen)

## Abhängigkeiten und Reihenfolge

### Zwischen den Phasen

- **Phasen 1–3** sind erledigt.
- **Phase 4** (Datenbank-Kern) blockiert alle weiteren Phasen.
- Danach: Phase 5 → 6 → 7 → 8 → 9 → 10 → 11 → 12 → 13 → 14.
  - Phase 5 liefert `AdLayout` für alle Oberflächen unter /ad.
  - Phase 7 liefert `PersonDetail` für die Phasen 10–12.
  - Phase 8 liefert `QualifikationsartAuswahl` für Phase 9 und 10.
  - Phase 9 vor Phase 10 (Eigenschaftsarten vor Eigenschaften).
  - Phase 11 braucht Phase 5 (Reichweite) und Phase 7 (Detailseite).
  - Phase 14 erst, wenn alle Phasen fertig sind.

### Innerhalb von Phase 4

Migrationen in der Reihenfolge der Dateinamen: T047 → T048 → T049 → T050 → T051 → T052 → T057 → T053 → T054 → T055 → T056 → T058 → T059 → T060 → T061 → T065. Die Tests T032–T046 entstehen vorher und parallel; jede Migration macht ihre Tests grün. T062–T064 laufen parallel zu den Migrationen.

### Innerhalb einer Story

Erst die Tests (müssen fehlschlagen), dann die Migration, dann Edge Functions, dann die Oberfläche, dann das Ausrollen nach TEST.

### Parallel möglich

- Phase 4: T033–T046 (Testdateien) parallel; T062, T063, T064 parallel zu den Migrationen.
- Phase 6: T070 parallel zu T071-Vorbereitung.
- Phase 8: T076, T077 parallel.
- Phase 12: T085–T089 parallel; T092 parallel zu T090/T091; T096, T097 parallel.

## Beispiel: parallel in Phase 4

```text
T033 supabase/tests/database/070_scope_referate.test.sql
T034 supabase/tests/database/080_referate_gremien.test.sql
T035 supabase/tests/database/090_qualification_types.test.sql
T037 supabase/tests/database/110_property_types.test.sql
T039 supabase/tests/database/130_visibility.test.sql
T062 src/lib/errors.ts
```

## Umsetzungsstrategie

1. **Datenbank-Kern zuerst:** Phase 4 auf `ad-kern-datenbank`, PR mit grüner Action und Ausrollen nach TEST. Danach ist der Kern über SQL/REST in TEST prüfbar (Sichtbarkeit, Referate, Eigenschaften).
2. **Pflege in AD:** Phasen 5–11 je Branch, jeweils mit Abnahme in der Cloudflare-Vorschau gegen TEST.
3. **Zugänge:** Phase 12 (Einladen, Annehmen, Reset, Sperren).
4. **Nachvollziehbarkeit und Abnahme:** Phase 13, dann Phase 14 (Grundlage für Schritt 7 des Arbeitsplans).

Offen: [OFFEN] O1 – Weg nach PROD (spec.md Abschnitt 11). Keine Task in dieser Datei führt etwas gegen PROD aus.
