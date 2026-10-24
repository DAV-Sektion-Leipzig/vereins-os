# Research: Administration (AD)

Stand: 22.10.2026 · Phase 0 zu [plan.md](plan.md) · Grundlage: [spec.md](spec.md) v0.9, Umfang Kern bis v0.7.1 (R-01 bis R-16 aus v0.5, R-17 ff. neu)

Hier steht nur, *wie* umgesetzt wird. Was fachlich entschieden ist, steht in spec.md Abschnitt 11. Annahmen, die bei der Abnahme in TEST zu prüfen sind, tragen den Vermerk `[PRÜFEN T25]`.

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

Ersetzt durch R-25 (spec.md v0.7, R40): Die Funktion sucht modulübergreifend und ist deshalb security definer. Die Schwelle 0,3 bleibt eine Konstante; die Abnahme folgt in T25.

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

Ersetzt durch plan.md, Abschnitt „Branches“: Die Datenbankteile des Kerns hängen voneinander ab (Reichweite, Referate, Eigenschaftsarten, Sichtbarkeit) und kommen auf den gemeinsamen Branch `ad-kern-datenbank`; die Oberflächen je Story auf eigene Branches (CLAUDE.md, Git-Workflow).

## R-17 Enum-Erweiterungen in eigener Migration

- **Entscheidung:** Die neuen Enum-Werte (`ea_data_type`: `number`, `year`, `qualification_type`; `ad_audit_action`: `referate_changed`) und die neuen Enums des Kerns entstehen in der ersten Migration `20261023000100_ad_kern_enums.sql`, vor allen Objekten, die sie nutzen.
- **Begründung:** `alter type … add value` ist in einer Transaktion erlaubt, der neue Wert darf aber erst nach dem Commit genutzt werden. Jede Migrationsdatei läuft in einer eigenen Transaktion; Defaults, Checks oder Inserts mit den neuen Werten stehen deshalb erst in späteren Dateien.
- **Alternative:** Enums neu anlegen und Spalten umstellen – unnötig, weil die bestehenden Werte gültig bleiben.

## R-18 Reichweite und Zuweisung mit Referaten

- `ad_template_rights.scope` ist heute `text` mit Check `scope = 'all'`. Die Migration T33 entfernt den Check, stellt die Spalte per `alter column … type public.ad_scope using scope::public.ad_scope` um und legt den Check für den Kern an: `scope = 'all' or (scope = 'referat' and module_code = 'EA')` (Constraint-Name `ad_template_rights_scope_allowed`). Verstöße meldet ein Trigger mit `AD_SCOPE_NOT_ALLOWED`, der Check sichert ab. T50 ersetzt den Check später um EZ, T59 um TK und TKF.
- `ad_user_level` wird per `create or replace` auf Reichweite `all` eingeschränkt (Signatur unverändert). `ad_my_modules` per `create or replace` mit `ad_has_any_level`; `level` = höchste Stufe über beide Reichweiten.
- `ad_assign_template(p_person, p_template)` bekommt den Parameter `p_referate uuid[] default null`. Weil sich die Signatur ändert, wird die alte Funktion mit `drop function` entfernt und neu angelegt (Grants neu). Ein Aufruf ohne Referate bleibt gültig.
- Protokoll: `template_assigned` mit Details „Vorlage, Referate: …“; `ad_set_assignment_referate` schreibt `referate_changed` mit „vorher → nachher“.

## R-19 Sichtbarkeit je Pfad (R32)

- Alle Sichtbarkeitsfunktionen (`ea_person_in_referate`, `ea_person_visible_ad`, `ea_person_visible_ea`, `gr_person_visible`, `ea_person_visible`, `ea_property_readable`, `ea_property_writable`) sind `security definer`, `stable`, `set search_path = ''`. Sie lesen `ea_persons` und `ea_properties` als Eigentümer ohne RLS; damit gibt es keine Rekursion zwischen Policy und Funktion.
- Die Policies auf `ea_persons`, `ea_properties`, `ea_property_history`, `ea_volunteer_status_history` rufen nur diese Funktionen auf. Die bisherigen Policies aus `20261020000200_ea_persons.sql` werden in T38 mit `drop policy` ersetzt.
- `gr_person_visible` ist ein Platzhalter (`false`), den die erste GR-Migration mit gleicher Signatur ersetzt.
- Leistung (Ergebnis Mengentest, R-27): Die Policies auf `ea_persons`, `ea_properties` und `ea_volunteer_status_history` rufen nicht je Zeile `ea_person_visible`/`ea_property_readable` auf (30.000 Eigenschaften: 2,8 s), sondern die Mengenfunktionen `ea_person_ids_ea(p_min)`, `gr_person_ids(p_min)` und `ea_readable_type_ids(p_path)` in `in (select …)`; PostgreSQL wertet sie einmal je Abfrage aus (gleicher Fall: 4 ms). Die Regeln sind dieselben; `ea_person_visible` und `ea_property_readable` bleiben für Funktionen und Tests erhalten. `gr_person_ids` leitet sich aus `gr_person_visible` ab, damit die erste GR-Migration nur diese Funktion ersetzen muss.
- Schreib-Policies (`ea_property_writable`) bleiben zeilenweise; sie betreffen nur einzelne Zeilen.

## R-20 Werte je Feld in `field_values` (R35)

- `ea_properties.field_values` ist ein `jsonb`-Objekt `{ "<key>": <wert> }`. Der Trigger `ea_properties_validate` prüft je Feld der Art: Pflicht (`EA_FIELD_REQUIRED`, Detail = Bezeichnung), unbekannter Schlüssel (`EA_FIELD_UNKNOWN`), Typ (`EA_VALUE_TYPE`, Detail = Bezeichnung): Text/Auswahl als String, Zahl als Zahl, Datum als String `YYYY-MM-DD` (gültiges Datum), Jahr als ganze Zahl 1900–2100, Ja/Nein als boolean, Qualifikationsart als uuid-String einer vorhandenen Qualifikationsart; Auswahl im Wertebereich (`EA_FIELD_CHOICE`). Leere Strings gelten als nicht gesetzt.
- Der Feldname geht im `detail` des Fehlers (`using detail = …`) ans Frontend; `src/lib/errors.ts` setzt ihn in die Meldung ein.
- R37 (`EA_SINGLE_VALUE`): Überschneidung der Zeiträume `[valid_from, coalesce(valid_to, 'infinity')]` mit einer anderen Eigenschaft derselben Person und Art, wenn `allow_multiple = false`.
- R38: genau die zum `relation_kind` passende Bezugsspalte; Pflicht (`EA_RELATION_REQUIRED`); inaktive Referate/Gremien nur, wenn der Bezug unverändert bleibt.
- R27/R28 nur bei neu gesetztem oder geändertem Wert und nur mit Nutzerkontext (`auth.uid() is not null`).

## R-21 Eigenschaftsart mit Feldern speichern

- Die Oberfläche speichert Art und Felder in einem Aufruf: `ea_save_property_type(p_type jsonb, p_fields jsonb) returns uuid`, `security invoker` (RLS der Tabellen gilt), in einer Transaktion. Sie prüft R9 (mindestens ein Feld, `EA_NO_FIELDS`) und legt neue Felder an bzw. ändert vorhandene. Felder werden nicht gelöscht.
- Trigger auf `ea_property_types`: `visible_in` nur Codes aus `ad_modules`; `read_level = 'confidential'` setzen/ändern nur mit AD ≥ edit (`AD_CONFIDENTIAL_ONLY_AD`); `relation_kind` gesperrt bei vorhandenen Eigenschaften (`EA_RELATION_LOCKED`); `relation_kind = 'group'` nur mit GR = manage (`AD_FORBIDDEN`); `system_key` nur ohne Nutzerkontext.
- Trigger auf `ea_property_fields`: `key` nach Anlage unveränderlich; Datentyp gesperrt bei vorhandenen Eigenschaften (`EA_DATA_TYPE_LOCKED`); Auswahlwerte nur ergänzen (`EA_CHOICE_VALUE_REMOVED`); neues Pflichtfeld bei vorhandenen Eigenschaften (`EA_FIELD_NEW_REQUIRED`); Bezeichnung eindeutig je Art (Unique-Index `lower(label)`; Meldung „Ein Feld mit dieser Bezeichnung gibt es bereits.“ über den Constraint-Namen).
- Bezeichnungen „gültig von/bis“ (R49, spec v0.7.2): Spalten `valid_from_label`, `valid_to_label`; der Trigger trimmt, leer → null, über 40 Zeichen `EA_LABEL_TOO_LONG` (Check als Absicherung); Rechte wie die übrigen Spalten.
- `EA_FIELD_LOCKED` wird im Kern nicht ausgelöst, solange die Abgrenzung zu `EA_DATA_TYPE_LOCKED` [OFFEN] ist (contracts/error-codes.md); der Datentyp-Fall nutzt `EA_DATA_TYPE_LOCKED`.

## R-22 Policies für Eigenschaften (R29, R41, R42)

- `ea_properties`: select `ea_person_visible(person_id) and ea_property_readable(property_type_id, person_id)`; insert with check `ea_property_writable(property_type_id, person_id, related_referat_id)`; update using (alte Fassung) und with check (neue Fassung) jeweils `ea_property_writable(…)`. Kein Delete (Beenden über `valid_to`).
- Fehlercodes für abgelehnte Schreibversuche: Die Policies selbst liefern SQLSTATE `42501`. Für die fachlich unterscheidbaren Fälle prüft der Trigger `ea_properties_validate` vorab und meldet `EA_RELATION_FOREIGN_REFERAT` (R41) bzw. `EA_GROUP_RELATION_ONLY_GR` (R39); alles andere bleibt `42501` → „Für diesen Bereich hast du keine Rechte.“
- `ea_property_history`: select über `exists` auf die lesbare Eigenschaft; nur Trigger schreibt.

## R-23 Geschützte Spalten an `ea_persons`

- Neue Spalten nach spec.md Abschnitt 2 per `alter table`; Bestand `created_in = 'AD'` per Default.
- Trigger `ea_persons_guard` (before update): `kind`, `created_in` unveränderlich; `volunteer_status`/`volunteer_status_since` nur, wenn `auth.uid() is null` (Migration, Seed, Migrationsskript) oder das transaktionslokale Kennzeichen `ea.status_change` gesetzt ist. Das Kennzeichen setzen nur `ea_set_volunteer_status`, `ea_create_volunteer` und `ea_activate_person` (Muster wie `ad.email_change` in R-16).
- Insert: Policy erlaubt direktes Anlegen nur mit AD ≥ edit (`created_in = 'AD'`, `volunteer_status is null`); EA legt nur über `ea_create_volunteer` an.
- Rufname: `ea_persons_normalize` trimmt zusätzlich `preferred_name`, leer → null.

## R-24 Qualifikationsarten

- Tabelle, Checks und Indizes nach spec.md Abschnitt 2; Kürzel per Trigger in Großbuchstaben, danach Check `^[A-Z0-9]{1,10}$` (`AD_QUALIFICATION_CODE_FORMAT`). Fachliche Prüfungen R21–R24 im Trigger mit den Codes aus contracts/error-codes.md; Unique-Indizes mit Namen `ad_qualification_types_name_key`, `…_code_key` als Absicherung.
- Startbestand (T27): eigene Migration, 47 Zeilen aus stammdaten-qualifikationsarten.md v0.2 Abschnitt 3, `insert … on conflict (source_ref) do nothing`; keine Personendaten, läuft in TEST und PROD.
- `ad_qualification_usage` entsteht nach `ea_properties` (sucht in `field_values` aller Felder vom Typ `qualification_type`).

## R-25 Dublettenprüfung modulübergreifend (R3, R40)

- `ad_find_similar_persons(p_first, p_last, p_email)` ist `security definer`, `stable`, `set search_path = ''`. Prüft zuerst das Recht (AD ≥ edit, `ad_has_any_level('EA','edit')`, GR ≥ edit), sonst `AD_FORBIDDEN`.
- Treffer nach R3a (spec v0.7.3): `kind = 'human'` und gleicher Nachname (getrimmt, ohne Groß-/Kleinschreibung) und `ad_first_names_match(p_first, first_name)` oder `ad_first_names_match(p_first, preferred_name)`; oder `p_email` gleich der Login-Adresse oder dem Feld `email` bzw. `dav_email` einer Eigenschaft der Art mit `system_key = 'contact'` (spec v0.7.2).
- `ad_first_names_match` (immutable): Trigramm-Ähnlichkeit ≥ 0,3, einer im anderen enthalten oder gemeinsame Teilfolge von 3 Zeichen (über `generate_series` und `strpos` auf allen Teilfolgen des kürzeren Werts).
- Rückgabe nur die Spalten nach spec.md; `birth_year` aus dem Feld `date` der Art mit `system_key = 'birth_date'` (heute gültige Eigenschaft, sonst die mit dem spätesten `valid_from`), nur wenn die Lesestufe dieser Art es für den Aufrufer erlaubt (R40, Ü2); `is_visible = ea_person_visible(person_id)`.
- Ersetzt T8 vollständig; die Fassung aus v0.5 wird nicht mehr gebaut.

## R-26 Seed Personen 1–12

- Personen 9–12, Eigenschaftsarten (Testarten aus spec.md Abschnitt 9, ohne `system_key` `function`, `contact`, `license`; mit `system_key = 'birth_date'`), Eigenschaften, Ehrenamtsstatus mit Historie, Zuweisung Referent:in mit Referat Klettern und der Protokolleintrag `template_assigned` werden in `seed.sql` ergänzt.
- Der Seed läuft ohne Nutzerkontext (`auth.uid()` ist null): Die Trigger erlauben das Setzen des Ehrenamtsstatus und historischer Qualifikationsarten (Person 5, R27).
- Feste UUIDs für die neuen Personen (`a…09`–`a…12`) und Testzugang Referent:in (`b…09`), damit die pgTAP-Tests sie ansprechen.

## R-27 Mengentest (spec.md Abschnitt 8)

- Eigene pgTAP-Datei, läuft in `begin; … rollback;`: erzeugt 1.000 Personen mit Ehrenamtsstatus und je 30 Eigenschaften (davon ein Teil mit Bezug auf Referate), wechselt auf den Testzugang Referent:in und misst mit `clock_timestamp()` eine Seite der Personenübersicht und die Eigenschaften aller sichtbaren Personen. Erwartet < 1 s.
- Läuft nur in CI (lokaler Stack); die Werte sind ein Anhaltspunkt, kein Nachweis für TEST.

## R-28 Frontend des Kerns

- Navigation und Routenschutz: /ad/* mit `ad_has_level('AD','read')` wie bisher; Bearbeiten-Knöpfe bei Qualifikationsarten über `ad_can_edit_qualification_types()`. /ea/qualifikationsarten wird erst mit EA aktiv; die Komponenten liegen so, dass EA sie ohne Änderung einhängt.
- Personenübersicht: Paginierung 50 je Seite über `range` und `count: 'exact'`; Suche über Vor-, Ruf- und Nachname (`or(…ilike…)`); Filter Zugangsstatus und Zugehörigkeit (mit Zugang, Funktionsperson, Ehrenamtsmanagement, nur Gruppen = `created_in = 'GR'` ohne Ehrenamtsstatus, ohne Zugehörigkeit).
- Personenname überall über eine Hilfsfunktion `personName()` in `src/lib/format.ts`: „Rufname Nachname“, sonst „Vorname Nachname“.
- Fehlercodes mit Feldname (`EA_FIELD_REQUIRED`, `EA_VALUE_TYPE`) setzen das `detail` des Fehlers in den Platzhalter `<Feld>` ein.
- Der bestehende Stand auf `us-ad-10-rechtevorlagen` (AdLayout, Rechtevorlagen-Liste und -Formular, `data.ts`, `access.ts`) wird per Rebase auf `main` übernommen und um die Spalte Reichweite ergänzt.

## R-29 Meldung für R30 im Kern

- Ohne Nachtrag v0.8 gilt der Text aus 02-stories.md US-AD-20 AK3: „Die Reichweite ‚Referat‘ ist nur im Ehrenamtsmanagement möglich.“ contracts/error-codes.md führt diesen Text; der Text aus v0.8 („… und in der Anwesenheitserfassung …“) folgt mit T50.

## R-30 EA- oder EZ-Weg beim Anlegen und Wieder-aktiv-Eintragen (Nachtrag v0.8.1, T53)

- Entscheidung: Eine interne Funktion `ea_create_path(p_property_type, p_referat, p_field_values)` prüft zuerst den EA-Weg über `ea_check_create` (alle Prüfungen und Codes des Ehrenamtsmanagements). Scheitert er mit `EA_CREATE_FORBIDDEN` (kein EA-Recht) oder mit `EA_RELATION_FOREIGN_REFERAT` und deckt ein EZ-Recht das Referat, gilt der EZ-Weg: Referat Pflicht, Eigenschaftsart `function`, Wert genau `{"function": "Helfer:in"}`, sonst `EA_CREATE_FORBIDDEN`; fremdes Referat `EA_RELATION_FOREIGN_REFERAT`. Andere Fehler des EA-Wegs (z. B. `AD_CONFIDENTIAL_ONLY_AD`, `EA_CREATE_REFERAT_REQUIRED`) bleiben bestehen, damit Nutzer mit EA-Rechten die genaue Meldung sehen.
- Begründung: spec.md Abschnitt 2 („`created_in = 'EZ'`, wenn der Aufruf nur über EZ-Rechte erlaubt ist“). Die Vorlage Referent:in hat EA und EZ im selben Referat; Referent:innen nutzen deshalb den EA-Weg (`created_in = 'EA'`, auch Trainer:in erlaubt). Den EZ-Weg nutzen Nutzer mit EZ- ohne passende EA-Rechte (Entscheidung Product Owner 24.10.2026: Regel gilt, Tests mit einem Nutzer nur mit EZ-Rechten).
- Bekannte Grenze: Ein Nutzer mit EA-Rechten im Referat A und EZ-Rechten nur im Referat B (zwei Zuweisungen) scheitert beim Anlegen für B am Trigger `ea_properties_validate` (R41 prüft nur EA-Referate). Mit den Startvorlagen kommt das nicht vor; Lösung bei Bedarf über den Trigger.
- `ea_create_volunteer` hat eine neue Signatur mit `p_contact_email text default null`; die alte Fassung mit sieben Parametern ist entfernt, damit Aufrufe nicht mehrdeutig werden. Aufrufe mit benannten Parametern (Frontend EA) bleiben gültig.

## R-31 Namensfunktionen (Nachtrag v0.8.1, T52)

- `ea_search_active_persons`: jedes Wort des Suchbegriffs muss als Teilwort in Vor-, Ruf- oder Nachname vorkommen (`ilike`, Platzhalter maskiert); Trigramm-Indizes auf allen drei Spalten. `p_limit` außerhalb 1–50 → `AD_BAD_REQUEST`.
- `ea_person_names` prüft je ID `ea_person_visible or ez_person_visible`; höchstens 500 IDs. Mengentest (270): 300 Aktive bzw. 50 IDs je < 300 ms als Anhaltspunkt aus CI.
