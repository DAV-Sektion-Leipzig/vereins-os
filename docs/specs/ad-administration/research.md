# Research: Administration (AD)

Stand: 20.10.2026 · Phase 0 zu [plan.md](plan.md) · Grundlage: [spec.md](spec.md) v0.5

Hier steht nur, *wie* umgesetzt wird. Was fachlich entschieden ist, steht in spec.md v0.5 Abschnitt 11. Annahmen, die bei der Abnahme in TEST zu prüfen sind, tragen den Vermerk `[PRÜFEN T25]`.

---

## R-01 Reihenfolge der Migrationen und Policies

- **Entscheidung (spec.md Abschnitt 2/3, seit v0.3):** Jede Migration bringt für ihre Tabellen `enable row level security`, Policies, `revoke … from anon, public` und `grant … to authenticated` mit. `ad_user_level`/`ad_has_level` entstehen in T1 als `plpgsql`-Funktionen; `plpgsql` löst Tabellennamen erst zur Laufzeit auf, deshalb dürfen `ad_accesses` und `ad_template_assignments` später (T3) folgen.
- **Begründung:** Kreisabhängigkeit – `ad_accesses` verweist per FK auf `ea_persons` (T2), die Policies auf `ea_*` brauchen `ad_has_level`.
- T6 enthält die View `ad_v_person_overview`, die Funktion `ad_me()` und den Abgleich aller Policies mit spec.md Abschnitt 3.

## R-02 Grants und Standardrechte von Supabase

- Supabase vergibt in `public` standardmäßig Rechte an `anon`, `authenticated` und `service_role`; PostgreSQL vergibt `EXECUTE` auf Funktionen an `PUBLIC`. Deshalb widerruft jede Migration ausdrücklich (`revoke all … from anon, public`, `revoke execute … from anon, public`) und vergibt dann gezielt.
- Spaltenrechte auf `ad_accesses`: `insert (person_id, login_email)`, `update (login_email)`. Status, `auth_user_id`, `locked_*`, `last_invited_at` und `is_emergency` lassen sich nur über interne Funktionen und Trigger ändern.
- Interne Statusfunktionen `ad_apply_invite`, `ad_revert_invite`, `ad_apply_lock`, `ad_apply_unlock` und `ad_apply_email_change`: `grant execute … to service_role`, kein Grant an `authenticated` (spec.md v0.5 Abschnitt 3).
- `ad_audit_log.actor_user_id` hat keinen FK auf `auth.users`. Grund: `ad-invite` (Aufräumen) und `change_email` löschen Auth-Einträge. Hat der Notfall-Admin einen Link eingelöst, ohne ein Passwort zu setzen, gibt es bereits einen Eintrag `emergency_login` mit seiner ID; ein FK würde das Löschen verhindern. Die übrigen `*_by`-Spalten verweisen auf `auth.users` mit `on delete set null`; noch nicht aktivierte Nutzer haben dort keine Einträge.
- Trigger-Funktionen: kein Grant.

## R-03 Fehlercodes

- Fachliche Prüfungen in Triggern und Funktionen: `raise exception '<CODE>' using errcode = 'P0001'`. Constraints bleiben als Absicherung und tragen feste Namen. Das Frontend bildet Code bzw. Constraint-Namen über `src/lib/errors.ts` auf die Meldungen ab.
- Die vollständige Liste ist normativ (spec.md Abschnitt 5 verweist darauf): [contracts/error-codes.md](contracts/error-codes.md).

## R-04 Einladungs- und Reset-Link (token_hash)

- **Entscheidung:** Die Mailvorlagen verlinken direkt auf die SPA: `{{ .SiteURL }}/passwort-setzen?token_hash={{ .TokenHash }}&type=invite` bzw. `type=recovery`. Die Seite zeigt zuerst das Formular und prüft R19 (Länge, Übereinstimmung). Erst beim Speichern ruft sie `verifyOtp({ token_hash, type })` und unmittelbar danach `updateUser({ password })` auf.
- **Begründung:** Virenscanner im Microsoft-Tenant (Safe Links) rufen Links vorab auf. Ein Aufruf der SPA verbraucht den Token nicht. Über `type` lassen sich die beiden Meldungen für ungültige Links unterscheiden.
- Der Status hängt nicht mehr an der Anmeldung, sondern am Passwort (R-06). Ein eingelöster Link ohne Passwort lässt den Zugang auf „eingeladen“ (US-AD-03 AK6), auch wenn `updateUser` scheitert.

## R-05 Gesperrte Zugänge in Supabase Auth

- Sperren: `auth.admin.updateUserById(id, { ban_duration: '876000h' })`. Entsperren: `ban_duration: 'none'`.
- Jeder Login-Fehler wird mit der R18-Meldung angezeigt.
- R5 wirkt zusätzlich in der Datenbank.
- `[PRÜFEN T25]` `verifyOtp` mit einem Einladungs- oder Reset-Token schlägt für gebannte Nutzer fehl (US-AD-03 AK4, US-AD-04 AK4).

## R-06 Trigger auf auth.users

Drei `security definer`-Trigger-Funktionen im Schema `public`, `set search_path = ''`, ohne Grant (spec.md v0.5 Abschnitt 2). Dazu kommen in T5 die Tabelle `ad_test_login_domains`, die Funktion `ad_login_email_allowed` und der Trigger `ad_accesses_guard` für R1 und R20 (R-16, data-model.md):

| Trigger | Bedingung | Wirkung |
|---|---|---|
| `after insert` | Zugang mit `login_email = new.email` | `auth_user_id = new.id`; Status `none` → `invited` |
| `after update of encrypted_password` | `coalesce(old.encrypted_password,'') = ''` und `coalesce(new.encrypted_password,'') <> ''` | Status `invited` → `active` |
| `after update of last_sign_in_at` | Wert hat sich geändert, Zugang `is_emergency` | Protokoll `emergency_login`, `actor_user_id = new.id` ausdrücklich gesetzt (`auth.uid()` ist im Auth-Server leer) |

- `[PRÜFEN T25]` Eingeladene Nutzer haben in Supabase Auth ein leeres `encrypted_password` (`''`). Das gilt für `inviteUserByEmail` und für die Einladung über das Dashboard.
- **Hinweis:** Ein Auth-Nutzer, der schon *mit* Passwort angelegt wird (Dashboard „Create user“, Seed), durchläuft kein Update von `encrypted_password` und bliebe „eingeladen“. Der Seed setzt den Status deshalb selbst (R-10). „Create user“ ist kein vorgesehener Weg.

## R-07 Edge Functions ad-invite und ad-access

- Deno, `supabase/functions/ad-invite/`, `supabase/functions/ad-access/`, gemeinsamer Code in `supabase/functions/_shared/`.
- Ablauf:
  1. Mit dem JWT des Aufrufers `ad_has_level('AD','edit')` aufrufen; ohne Recht 403 `AD_FORBIDDEN`.
  2. Fachliche Prüfungen.
  3. Auth-Admin-API mit `SUPABASE_SERVICE_ROLE_KEY`, den das Edge-Runtime automatisch bereitstellt (kein Secret im Repo).
  4. Erst nach Erfolg `ad_apply_*(…, p_actor)` aufrufen: Status, Zeitstempel und Protokoll in einer Transaktion.
- **ad-invite:**
  - `auth.admin.inviteUserByEmail(login_email, { redirectTo: SITE_URL + '/passwort-setzen' })`, für neue und erneute Einladungen.
  - Aufräumen bei jedem Fehler der Auth-Admin-API (spec.md v0.5 Abschnitt 7): Ein neu angelegter Auth-Eintrag wird mit `auth.admin.deleteUser` gelöscht, danach stellt `ad_revert_invite` den Ausgangsstand her (Status, `auth_user_id`, `last_invited_at`). Der Insert-Trigger hat den Status unter Umständen schon auf `invited` gesetzt; die Rücksetzung korrigiert das.
  - Der Auth-Admin-Client wird der Handler-Funktion übergeben. So kann ein Deno-Test (`supabase/functions/ad-invite/index.test.ts`) einen Fehler simulieren und die Aufräum-Aufrufe prüfen, ohne Supabase-Projekt und ohne Docker.
  - `[PRÜFEN T25]` Eine erneute Einladung an einen unbestätigten Auth-Nutzer wird versendet.
- **ad-access change_email (R20):** nur bei Status `invited`. Prüft R1 und R2, löscht den Auth-Eintrag (der alte Link wird ungültig) und ruft `ad_apply_email_change` auf: neue Adresse, `auth_user_id` null, Status `none`, Protokoll `email_changed` mit „alt → neu“. Schlägt das Löschen fehl, ändert sich nichts. Bei Status `none` ändert die Oberfläche die Adresse direkt; der Trigger `ad_accesses_guard` lässt das zu.
- **ad-access unlock:** Das Ziel hängt davon ab, ob `auth.users.encrypted_password` gefüllt ist (spec.md Abschnitt 4).
- **Deployment:** `supabase functions deploy` funktioniert ohne Docker. Der Weg nach PROD ist O1.

## R-08 pg_cron

`cron.schedule('ad_audit_log_retention', '15 1 * * *', …)` – 01:15 UTC (spec.md v0.5).

## R-09 Dublettenprüfung

`ad_find_similar_persons` als `security invoker`, `stable`, Bedingung nach spec.md. Treffer über die Login-Adresse erhält nur, wer `ad_accesses` lesen darf (RLS). Die Schwelle 0,3 ist eine Konstante; die Abnahme folgt in T25.

## R-10 Seed: seed.sh + seed.sql

- `supabase/seed.sql` enthält nur fiktive Daten nach spec.md Abschnitt 9 und nutzt die psql-Variable `:'test_password'`. Feste UUIDs für die Testzugänge, damit pgTAP-Tests sie ansprechen können.
- Ablauf von `supabase/seed.sh`:
  1. `SEED_TEST_PASSWORD` muss gesetzt sein, sonst Abbruch. Lokal kommt der Wert aus `.env.local`, das Skript liest die Datei selbst; in CI kommt er aus einem GitHub-Secret.
  2. Zielverbindung aus einer Variable (Vorschlag `SEED_DB_URL`). Lokaler Stack: `DB_URL` aus `supabase status -o env`. TEST: Verbindungszeichenfolge aus `.env.local`.
  3. Project Ref aus der Verbindungszeichenfolge lesen (`db.<ref>.supabase.co` bzw. Benutzer `postgres.<ref>` beim Pooler). Ist es die Ref von vereins-os-prod: Abbruch „Seed in PROD nicht erlaubt.“ Die PROD-Ref steht als Konstante im Skript; sie ist kein Secret, weil sie ohnehin in der Frontend-URL steht.
  4. `psql -v ON_ERROR_STOP=1 -v test_password="$SEED_TEST_PASSWORD" -f supabase/seed.sql`.
- `supabase/config.toml`: `[db.seed] enabled = false`. Sonst würden `supabase start` und `db reset` die Datei `seed.sql` ohne psql-Variable ausführen und abbrechen.
- `.env.example` erhält zusätzlich `SEED_DB_URL=`.
- Reihenfolge im Seed:
  1. `ea_persons` und Zuweisungen.
  2. `ad_accesses` mit Zielstatus.
  3. `auth.users` und `auth.identities` mit `crypt(:'test_password', gen_salt('bf'))`. Der Insert-Trigger setzt dann nur `auth_user_id`, weil der Status nicht `none` ist.
  4. Für „Dieter Gesperrt“ `banned_until` setzen.
  5. Protokolleinträge.
- `[PRÜFEN T25]` Pflichtspalten von `auth.users` und `auth.identities` in der aktuellen Supabase-Version.
- `psql` muss lokal installiert sein (kostenfrei, ohne Docker).

## R-11 Datenbanktests (pgTAP) in GitHub Actions

- `.github/workflows/db-tests.yml`, ausgelöst bei Pull Requests:
  1. Checkout und Supabase CLI.
  2. `supabase start` (Docker steht im Runner zur Verfügung), der Seed ist dabei abgeschaltet.
  3. `supabase/seed.sh` gegen den lokalen Stack mit `SEED_TEST_PASSWORD` aus einem GitHub-Secret.
  4. `supabase test db`.
- Zusätzlicher Schritt: `deno test supabase/functions` (Deno-Tests der Edge Functions mit simulierten Auth-Fehlern; ohne Supabase-Projekt).
- Tests liegen unter `supabase/tests/database/*.test.sql`. Jede Datei läuft in `begin; … rollback;`. Rollenwechsel mit `set local role authenticated` und `set local request.jwt.claims` auf die Seed-Testzugänge (Constitution 1.1.0, Arbeitsablauf Nr. 4).
- R1 wird mit der Testdomain `example.test` geprüft: ohne Eintrag in `ad_test_login_domains` abgelehnt, mit Eintrag (nur innerhalb der Test-Transaktion, danach `rollback`) erlaubt. Außerdem wird geprüft, dass `authenticated` die Tabelle nicht lesen kann (spec.md T7).
- Die Action greift nie auf TEST oder PROD zu. Sie braucht weder einen Access-Token noch ein DB-Passwort eines Projekts.
- Lokal gibt es kein Docker, deshalb laufen die Tests nur in CI.

## R-12 Migrationen nach PROD

- Für TEST: `supabase db push --linked`, ohne Docker.
- [OFFEN] **O1** Wie kommen Migrationen und Edge Functions nach PROD? (Auth-Einstellungen setzt der Product Owner manuell im Dashboard, R-13.) Das betrifft auch das Einrichtungsskript und den Zustellungstest (US-AD-01 AK5). Quelle: spec.md Abschnitt 11. Der Agent führt nichts gegen PROD aus.

## R-13 Auth-Konfiguration als Code

- `supabase/config.toml`:
  - `[auth.email.template.invite]` und `[auth.email.template.recovery]` mit `content_path = "./supabase/templates/invite.html"` bzw. `recovery.html`, Betreff deutsch.
  - `[auth.rate_limit] email_sent = 30`. Bisher steht dort 2; spec.md Abschnitt 8 nennt 30 je Stunde.
- `config.toml` gilt **nur für den lokalen Stack (CI)**. Kein `supabase config push` und kein `config diff` gegen TEST oder PROD. Die Auth-Einstellungen (Mailvorlagen aus `supabase/templates/`, `email_sent = 30`, `minimum_password_length = 8`, `enable_signup = false`, Redirect-URLs, SMTP) stellt der Product Owner manuell im Dashboard ein, nach der Checkliste in `supabase/setup/README.md`.

## R-14 Frontend

- Vorhandener Stack: React 19, react-router-dom 7 (`createBrowserRouter` mit Loadern), supabase-js 2, shadcn/ui, Tailwind v4, sonner.
- Datenzugriff über kleine Hooks je Feature, kein zusätzliches State-Management.
- Routenschutz: Der Loader prüft die Sitzung und leitet sonst auf /login um. AD-Routen prüfen `ad_has_level('AD','read')`; ohne Recht geht es auf /kein-zugriff, bevor Daten abgefragt werden.
- Kopfzeile und Startseite nutzen `ad_me()` und `ad_my_modules()`.
- Datum: `Intl.DateTimeFormat('de-DE', { timeZone: 'Europe/Berlin' })`. Tabellen werden unter 640 px zu Karten.
- Frontend-Unit-Tests fordert spec.md nicht; die Abnahme läuft in TEST (T25).

## R-16 R1 per Trigger und Testdomains (spec.md v0.5)

- `ad_login_email_allowed(p_email citext)`: `lower(split_part(p_email, '@', 2)) = 'dav-leipzig.de'` oder die Domain steht in `ad_test_login_domains`. Die Funktion ist security definer mit `set search_path = ''`, weil `authenticated` die Tabelle nicht lesen darf. Aus demselben Grund ist auch die Trigger-Funktion `ad_accesses_guard` security definer mit `set search_path = ''`; sonst bekäme ein Admin beim Speichern einer gültigen Adresse einen Rechtefehler.
- Die Funktion wird an drei Stellen genutzt: im Trigger `ad_accesses_guard` (Insert und Update), in `ad-invite` vor dem Einladen und in `ad-access` bei `change_email`. Die Edge Functions rufen sie mit dem Service-Client auf; deshalb `grant execute` nur an `service_role`, und die Liste der Testdomains bleibt für Nutzer unsichtbar.
- Die Meldung bleibt bei jeder Domain dieselbe (R1).
- T24 prüft zu Beginn `exists (select 1 from ad_test_login_domains)` und bricht dann ab (spec.md T24). Damit kann eine freigegebene Testdomain nicht unbemerkt in PROD bleiben.
- Abnahme und Aufräumen: quickstart.md C.

## R-15 Branches

Der Plan entsteht auf `us-ad-01-ersteinrichtung`. Die Datenbank-Grundlage (T1–T8) inklusive der DB-Teile von US-AD-10 und US-AD-11 gehört zu US-AD-01 (02-stories.md v0.5). Die übrigen Stories bekommen je einen eigenen Branch.
