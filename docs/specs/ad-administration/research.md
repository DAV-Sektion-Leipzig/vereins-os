# Research: Administration (AD)

Stand: 19.10.2026 · Phase 0 zu [plan.md](plan.md) · Grundlage: [spec.md](spec.md) v0.3

Hier steht nur, *wie* umgesetzt wird. Was fachlich entschieden ist, steht in spec.md v0.3 Abschnitt 11. Annahmen, die bei der Abnahme in TEST zu prüfen sind, tragen den Vermerk `[PRÜFEN T25]`.

---

## R-01 Reihenfolge der Migrationen und Policies

- **Entscheidung (spec.md Abschnitt 2/3, v0.3):** Jede Migration bringt für ihre Tabellen `enable row level security`, Policies, `revoke … from anon, public` und `grant … to authenticated` mit. `ad_user_level`/`ad_has_level` entstehen in T1 als `plpgsql`-Funktionen; `plpgsql` löst Tabellennamen erst zur Laufzeit auf, deshalb dürfen `ad_accesses` und `ad_template_assignments` später (T3) folgen.
- **Begründung:** Kreisabhängigkeit – `ad_accesses` verweist per FK auf `ea_persons` (T2), die Policies auf `ea_*` brauchen `ad_has_level`.
- T6 enthält die View `ad_v_person_overview`, die Funktion `ad_me()` und den Abgleich aller Policies mit spec.md Abschnitt 3.

## R-02 Grants und Standardrechte von Supabase

- Supabase vergibt in `public` standardmäßig Rechte an `anon`, `authenticated` und `service_role`; PostgreSQL vergibt `EXECUTE` auf Funktionen an `PUBLIC`. Deshalb widerruft jede Migration ausdrücklich (`revoke all … from anon, public`, `revoke execute … from anon, public`) und vergibt dann gezielt.
- Spaltenrechte auf `ad_accesses`: `insert (person_id, login_email)`, `update (login_email)`. Status, `auth_user_id`, `locked_*`, `last_invited_at` und `is_emergency` lassen sich nur über interne Funktionen und Trigger ändern.
- Interne Statusfunktionen `ad_apply_invite`, `ad_apply_lock`, `ad_apply_unlock`: `grant execute … to service_role`, kein Grant an `authenticated` (spec.md v0.3).
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

Drei `security definer`-Trigger-Funktionen im Schema `public`, `set search_path = ''`, ohne Grant (spec.md v0.3 Abschnitt 2):

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
- **ad-invite und R20:**
  - Gibt es einen Auth-Nutzer und weicht seine E-Mail von `login_email` ab, wird sie vorher mit `auth.admin.updateUserById(id, { email: login_email, email_confirm: true })` angepasst.
  - Danach `auth.admin.inviteUserByEmail(login_email, { redirectTo: SITE_URL + '/passwort-setzen' })`.
  - `[PRÜFEN T25]` Eine Änderung der E-Mail über die Admin-API löst trotz `double_confirm_changes = true` keine Bestätigungsmails aus.
  - `[PRÜFEN T25]` Eine erneute Einladung an einen unbestätigten Auth-Nutzer wird versendet.
  - `[PRÜFEN T25]` Bei einem SMTP-Fehler bleibt kein neuer Auth-Nutzer zurück. Bliebe einer zurück, würde der Insert-Trigger den Status auf `invited` setzen; das widerspräche US-AD-08 AK5. Dann `ad_apply_invite` nicht aufrufen und den Status per `ad_apply_*`-Rücksetzung korrigieren (Umsetzung in T9 klären).
- **ad-access unlock:** Das Ziel hängt davon ab, ob `auth.users.encrypted_password` gefüllt ist (spec.md Abschnitt 4).
- **Deployment:** `supabase functions deploy` funktioniert ohne Docker. Der Weg nach PROD ist O1.

## R-08 pg_cron

`cron.schedule('ad_audit_log_retention', '15 1 * * *', …)` – 01:15 UTC (spec.md v0.3).

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
- Tests liegen unter `supabase/tests/database/*.test.sql`. Jede Datei läuft in `begin; … rollback;`. Rollenwechsel mit `set local role authenticated` und `set local request.jwt.claims` auf die Seed-Testzugänge (Constitution 1.0.2, Arbeitsablauf Nr. 4).
- Die Action greift nie auf TEST oder PROD zu. Sie braucht weder einen Access-Token noch ein DB-Passwort eines Projekts.
- Lokal gibt es kein Docker, deshalb laufen die Tests nur in CI.

## R-12 Migrationen nach PROD

- Für TEST: `supabase db push --linked`, ohne Docker.
- [OFFEN] **O1** Wie kommen Migrationen, Edge Functions und Auth-Konfiguration nach PROD? Das betrifft auch das Einrichtungsskript und den Zustellungstest (US-AD-01 AK5). Quelle: spec.md Abschnitt 11. Der Agent führt nichts gegen PROD aus.

## R-13 Auth-Konfiguration als Code

- `supabase/config.toml`:
  - `[auth.email.template.invite]` und `[auth.email.template.recovery]` mit `content_path = "./templates/invite.html"` bzw. `recovery.html`, Betreff deutsch.
  - `[auth.rate_limit] email_sent = 30`. Bisher steht dort 2; spec.md Abschnitt 8 nennt 30 je Stunde.
- Übertragung nach TEST mit `supabase config diff` und danach `supabase config push`.
- SMTP-Zugangsdaten nur im Dashboard.

## R-14 Frontend

- Vorhandener Stack: React 19, react-router-dom 7 (`createBrowserRouter` mit Loadern), supabase-js 2, shadcn/ui, Tailwind v4, sonner.
- Datenzugriff über kleine Hooks je Feature, kein zusätzliches State-Management.
- Routenschutz: Der Loader prüft die Sitzung und leitet sonst auf /login um. AD-Routen prüfen `ad_has_level('AD','read')`; ohne Recht geht es auf /kein-zugriff, bevor Daten abgefragt werden.
- Kopfzeile und Startseite nutzen `ad_me()` und `ad_my_modules()`.
- Datum: `Intl.DateTimeFormat('de-DE', { timeZone: 'Europe/Berlin' })`. Tabellen werden unter 640 px zu Karten.
- Frontend-Unit-Tests fordert spec.md nicht; die Abnahme läuft in TEST (T25).

## R-15 Branches

Der Plan entsteht auf `us-ad-01-ersteinrichtung`. Die Datenbank-Grundlage (T1–T8) inklusive der DB-Teile von US-AD-10 und US-AD-11 gehört zu US-AD-01 (02-stories.md v0.3). Die übrigen Stories bekommen je einen eigenen Branch.
