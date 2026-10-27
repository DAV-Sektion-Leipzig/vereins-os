# Spec: Schnittstellen-Connector (SC) – MVP E-Mail über Brevo

Version: 0.1 · Status: Entwurf · Stand: 27.10.2026 · Product Owner: Toni Werner
Stories: docs/specs/sc-schnittstellen/02-stories.md (US-SC-01 bis US-SC-16, v0.2)
Grundlage: 00-steckbrief.md v0.6, 01-erhebung.md v0.4 (Regeln R1–R16), 02-stories.md v0.2 (R17, R18), rollen.md v1.4, glossar.md v1.11, tech-stack.md v0.10, spec.md AD (Zugänge, `ad_audit_log`, Notfall-Admin, Muster der Edge Functions `ad-invite`), querschnitt-administration.md (P9, P10, P16).
Änderungen v0.1: Erster Entwurf.

Regelverweise: „R…“ = 01-erhebung.md SC (R1–R16) bzw. 02-stories.md SC (R17, R18).

## 1. Ziel und Scope

**Ziel:** Das Vereins OS versendet E-Mails aus Abläufen zentral über Brevo. Fachmodule legen E-Mails eines eigenen Anlasses in den Postausgang, ohne Dienst, Key oder Adresse zu kennen. Der Admin pflegt Anbindung, Key, Freigaben und Texte in der Oberfläche „Schnittstellen“; die Geschäftsstelle sieht Zustand, Postausgang (ohne Inhalt) und Protokoll.

**Im Scope (MVP):**
- Rahmen für Anbindungen (Art im MVP: nur „E-Mail (Brevo)“), API-Key in Supabase Vault, Freigabe je Modul, Testaufruf, Zustände (US-SC-01 bis US-SC-06).
- Anlässe mit Vorlagen, Postausgang, Versand über die Brevo-API mit Wiederholungen und Grenzen (100 je Stunde, 300 je Tag), Postausgang ansehen, erneut senden, verwerfen (US-SC-07 bis US-SC-10).
- Protokoll, Erinnerung vor Ablauf eines Keys, Hinweise auf Störungen, Löschlauf nach 90 Tagen (US-SC-11 bis US-SC-13, US-SC-15).
- Anlässe „Test-E-Mail“, „Ablauf eines API-Keys“ (SC) und „Anmeldung des Notfall-Admins“ (AD) (US-SC-14).
- Startwerte (Geschäftsstelle SC lesen), Modul SC sichtbar, Testdaten (US-SC-16).
- Anleitung für Nutzer:innen: neuer Abschnitt „Schnittstellen“ (CLAUDE.md).

**Nicht im Scope:** Login-Mails (bleiben bei Supabase Auth, entfallen mit SSO; Erhebung E11); DATEV (Iteration 1); Instagram (Iteration 2); Anlässe der Fachmodule EA und FI (eigene Stories dort); Abbestellen (R16); HTML-Mails, Anhänge, Tracking von Öffnungen und Klicks; eingehende Schnittstellen (Webhooks); Löschen von Anbindungen; Export des Protokolls.

**Architektur (Entscheidung dieser Spec) [ANNAHME bis Ready]:**
- **Einstellen** in den Postausgang nur über die Datenbankfunktion `sc_mail_enqueue` (security definer, nicht für `authenticated` ausführbar), aufgerufen aus Datenbankfunktionen und Triggern der Module.
- **Versenden** nur über die Edge Function `sc-send` (R1). pg_cron ruft alle 5 Minuten `sc_dispatch()` auf; diese ruft über **pg_net** die Edge Function mit einem Dispatch-Geheimnis auf, aber nur, wenn E-Mails fällig sind. Die Edge Function holt die fälligen E-Mails über Funktionen, die nur `service_role` ausführen darf (Muster `ad_apply_invite`), liest den Key aus Vault und ruft `POST https://api.brevo.com/v3/smtp/email` auf.
- **Key** liegt in Vault unter dem Namen `sc_connection_<id>`; `sc_connections` speichert nur die letzten 4 Zeichen. Schreiben über `sc_set_key` (Admin), Lesen nur über `sc_connection_key` (nur `service_role`).
- **Test-E-Mail** sendet `sc-send` synchron im Auftrag des Admins (JWT, Prüfung SC ≥ edit), damit die Oberfläche das Ergebnis sofort zeigt.

## 2. Datenmodell

Alle Tabellen im Schema `public`, Präfix `sc_`, RLS auf jeder Tabelle, Grants nur an `authenticated` (Lesen) bzw. `service_role` (nur Funktionen der Edge Function); Schreiben nur über Funktionen (Abschnitt 2.3). Zeitstempel `timestamptz`; „Tag“ und „Stunde“ für die Grenzen in `Europe/Berlin`.

### 2.1 Typen

| Typ | Werte |
|---|---|
| `sc_connection_kind` | `email_brevo` |
| `sc_connection_state` | `disabled` (abgeschaltet), `active` (aktiv), `disturbed` (gestört), `expired` (abgelaufen) |
| `sc_outbox_state` | `waiting` (wartet), `sent` (versendet), `failed` (fehlgeschlagen), `discarded` (verworfen) |
| `sc_log_kind` | `connection_created`, `connection_changed`, `key_changed`, `state_changed`, `modules_changed`, `template_changed`, `test`, `send`, `enqueue_rejected`, `retry`, `discard`, `limit_reached` |
| `sc_log_result` | `ok`, `error`, `rejected` |

### 2.2 Tabellen

**`sc_connections`** – Anbindung

| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| kind | sc_connection_kind | ja | – | Art |
| name | text | ja | – | 1–80 Zeichen, eindeutig |
| state | sc_connection_state | ja | `disabled` | Zustand (Abschnitt 4) |
| sender_email | citext | ja | – | Absenderadresse, z. B. `noreply@vereinsos.dav-leipzig.de` |
| sender_name | text | ja | `Vereins OS` | 1–80 Zeichen |
| key_last4 | text | nein | – | letzte 4 Zeichen des Keys; null = kein Key |
| key_expires_on | date | nein | – | Ablaufdatum des Keys (optional) |
| key_changed_at, key_changed_by | timestamptz, uuid | nein | – | zuletzt gewechselt |
| config_changed_at | timestamptz | ja | now() | letzte Änderung von Absender oder Key (für R3) |
| last_test_ok_at | timestamptz | nein | – | letzter erfolgreicher Test |
| last_success_at | timestamptz | nein | – | letzter erfolgreicher Aufruf |
| last_error_at, last_error | timestamptz, text | nein | – | letzter Fehler, Meldung gekürzt auf 300 Zeichen |
| consecutive_failures | int | ja | 0 | Fehler in Folge (R7) |
| hourly_limit | int | ja | 100 | 1–100 (R13) |
| daily_limit | int | ja | 300 | 1–300; Seed TEST: 50 (R13) |
| created_at, created_by | timestamptz, uuid | ja | now(), auth.uid() | – |

Constraint: höchstens eine Zeile je `kind` mit `state = 'active'` (partieller Unique-Index, R4).

**`sc_connection_modules`** – Freigabe (R2): `connection_id` (FK, PK-Teil), `module_code` (FK `ad_modules.code`, PK-Teil), `granted_at` (now()), `granted_by` (auth.uid()).

**`sc_mail_occasions`** – Anlass mit Vorlage

| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| code | text | ja | – | PK, z. B. `sc_test`, `sc_key_expiry`, `ad_emergency_login` |
| module_code | text | ja | – | FK `ad_modules.code`; nur dieses Modul darf den Anlass einstellen |
| name | text | ja | – | Anzeige, z. B. „Anmeldung des Notfall-Admins“ |
| description | text | ja | – | wann die E-Mail kommt |
| placeholders | text[] | ja | `{}` | erlaubte Platzhalter ohne Klammern, z. B. `{zeitpunkt,link}` |
| subject | text | ja | – | 1–150 Zeichen (R9) |
| body | text | ja | – | 1–2.000 Zeichen, reiner Text (R9) |
| updated_at, updated_by | timestamptz, uuid | ja/nein | now() | – |

Anlässe legt die Migration des nutzenden Moduls an (`on conflict do nothing`, damit Texte des Admins erhalten bleiben).

**`sc_outbox`** – Postausgang

| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| occasion_code | text | ja | – | FK `sc_mail_occasions` |
| module_code | text | ja | – | einstellendes Modul |
| recipient_person_id | uuid | ja | – | FK `ea_persons` |
| recipient_email | citext | ja | – | ermittelt nach R5 beim Einstellen |
| subject, body | text | ja | – | zusammengesetzt beim Einstellen; **nicht** lesbar für SC lesen (Spaltenrechte) |
| dedupe_key | text | ja | – | R10; Unique-Index `where state <> 'discarded'` |
| state | sc_outbox_state | ja | `waiting` | Abschnitt 4 |
| attempts | int | ja | 0 | 0–3 |
| next_attempt_at | timestamptz | ja | now() | fällig ab |
| claimed_until | timestamptz | nein | – | Sperre während des Versands (10 Minuten) |
| last_error | text | nein | – | gekürzt auf 300 Zeichen |
| connection_id | uuid | nein | – | FK, gesetzt beim Versand |
| provider_message_id | text | nein | – | `messageId` von Brevo |
| created_at | timestamptz | ja | now() | eingestellt |
| created_by | uuid | nein | auth.uid() | null = Job |
| sent_at | timestamptz | nein | – | versendet |
| state_changed_at | timestamptz | ja | now() | Grundlage für R12 |

Indizes: `(state, next_attempt_at)`, `(state_changed_at)`, `(created_at)`.

**`sc_log`** – Protokoll (R15): `id`, `created_at` (now()), `connection_id` (nullable FK), `module_code` (nullable), `actor_user_id` (nullable, null = Job), `kind`, `result`, `message` (≤ 300 Zeichen, nie Key oder Inhalt), `outbox_id` (nullable, ohne FK, damit der Löschlauf unabhängig ist). Nur Einfügen über Funktionen; kein Update, kein Delete außer Löschlauf. Index `(created_at)`.

### 2.3 Funktionen

Alle `security definer`, `set search_path = ''`, `revoke all … from public, anon, authenticated`, danach gezielter `grant`.

**Für die Oberfläche (`grant execute … to authenticated`, Prüfung im Rumpf; Fehlercodes als `raise exception using errcode = 'P0001', message = 'SC_…'`):**

| Funktion | Recht | Wirkung |
|---|---|---|
| `sc_save_connection(p_id uuid, p_kind, p_name, p_sender_email, p_sender_name, p_key_expires_on, p_hourly_limit, p_daily_limit) returns uuid` | SC manage | anlegen (`p_id` null) oder ändern; Änderung von Absender setzt `config_changed_at`; Protokoll `connection_created`/`connection_changed` |
| `sc_set_key(p_id uuid, p_key text, p_expires_on date) returns void` | SC manage | Key 8–500 Zeichen, nach Vault (`vault.create_secret` bzw. `vault.update_secret`, Name `sc_connection_<id>`); `key_last4`, `key_changed_*`, `config_changed_at`; Zustand `active` → `disturbed` bis zum Test [ANNAHME: zwingt Test]; Protokoll `key_changed` mit `…last4` |
| `sc_set_state(p_id uuid, p_state sc_connection_state) returns void` | SC manage | nur `active` oder `disabled`; Prüfungen R3, R4 (Abschnitt 4); Protokoll `state_changed` |
| `sc_set_modules(p_id uuid, p_modules text[]) returns void` | SC manage | ersetzt die Freigaben; Protokoll `modules_changed` mit alter und neuer Liste |
| `sc_save_occasion(p_code text, p_subject text, p_body text) returns void` | SC edit | prüft R9 (Platzhalter, Längen); Protokoll `template_changed` |
| `sc_preview_occasion(p_code text, p_subject text, p_body text) returns table(subject text, body text)` | SC edit | setzt Beispielwerte ein |
| `sc_outbox_retry(p_id uuid)` / `sc_outbox_discard(p_id uuid)` | SC edit | Übergänge nach Abschnitt 4; Protokoll `retry`/`discard` |
| `sc_outbox_content(p_id uuid) returns table(subject text, body text)` | SC edit | Inhalt einer E-Mail (Geschäftsstelle nicht) |
| `sc_status() returns table(kind text, count int, text text)` | SC read | Hinweise für Seite und Startseite (US-SC-13); leer ohne Recht |

**Für die Module (kein Grant an `authenticated`; Aufruf nur aus anderen `security definer`-Funktionen und Triggern):**
- `sc_mail_enqueue(p_occasion text, p_person uuid, p_values jsonb, p_dedupe_key text) returns uuid` – prüft: Anlass vorhanden; es gibt eine Anbindung der Art `email_brevo` (beliebiger Zustand außer keine), die für `module_code` des Anlasses freigegeben ist (R2, sonst `SC_MODULE_NOT_ALLOWED`); Adresse nach R5 (`ad_accesses.login_email` bei `status = 'active'`, sonst Feld E-Mail der Eigenschaft mit `system_key = 'contact'`, gültig heute; sonst `SC_NO_EMAIL`); nur erlaubte Platzhalter in `p_values` (sonst `SC_PLACEHOLDER_UNKNOWN`); `{link}` setzt SC selbst aus der Basis-URL der Umgebung [ANNAHME: Vault-Eintrag `sc_app_url`]; Dedupe (R10: vorhandene id zurück, keine zweite Zeile). Bei Ablehnung Protokoll `enqueue_rejected` und Fehler an den Aufrufer.
- Das aufrufende Modul ist der `module_code` des Anlasses; ein Modul kann so nur eigene Anlässe einstellen (US-SC-08 AK5).

**Für die Edge Function `sc-send` (`grant execute … to service_role`):**
- `sc_check_dispatch_secret(p_secret text) returns boolean` – Vergleich mit Vault `sc_dispatch_secret`.
- `sc_claim(p_max int) returns table(outbox_id, connection_id, recipient_email, subject, body, sender_email, sender_name)` – nur bei aktiver Anbindung; beachtet `hourly_limit` und `daily_limit` (Zählung: `sent` + laufende Sperren in der Stunde bzw. am Tag); `for update skip locked`; setzt `claimed_until = now() + 10 min`, `attempts + 1`; bei erreichtem Limit Protokoll `limit_reached` (einmal je Stunde bzw. Tag).
- `sc_connection_key(p_connection uuid) returns text` – liest aus `vault.decrypted_secrets`.
- `sc_report(p_outbox uuid, p_ok boolean, p_message text, p_provider_id text)` – Übergänge nach Abschnitt 4, R7 (Wiederholung, `consecutive_failures`, `disturbed`), Protokoll `send`.
- `sc_test_prepare(p_connection uuid, p_user uuid) returns table(recipient_email, subject, body, sender_email, sender_name)` und `sc_test_report(p_connection uuid, p_user uuid, p_ok boolean, p_message text)` – Test-E-Mail an die Login-Adresse des Admins; Erfolg setzt `last_test_ok_at`, bei `disturbed`/`expired` mit gültigem Datum zurück auf `active`; Protokoll `test`.

**Jobs (pg_cron, Eigentümer postgres):**
- `sc_dispatch()` alle 5 Minuten (`*/5 * * * *`): gibt es fällige E-Mails (`waiting`, `next_attempt_at <= now()`, nicht gesperrt) und eine aktive Anbindung, dann `net.http_post` an Vault `sc_dispatch_url` mit Header `x-sc-dispatch-secret`; fehlt einer der Vault-Einträge, nichts tun (lokaler Stack, CI).
- `sc_daily()` täglich 02:40: (1) Erinnerung Ablauf: für Anbindungen mit `key_expires_on = heute + 30` bzw. `+ 7` je Nutzer mit SC manage `sc_mail_enqueue('sc_key_expiry', …)`, Dedupe `sc_key_expiry:<id>:<datum>:<30|7>`; (2) `key_expires_on <= heute` → `expired`; (3) `waiting` älter als 7 Tage → `failed` „zu alt“; (4) Löschlauf R12: `sc_outbox` und `sc_log` mit `state_changed_at` bzw. `created_at` älter als 90 Tage.

**Trigger (Anlass AD, US-SC-14):** `after insert on ad_audit_log for each row when (new.action = 'emergency_login')` → für jede Person mit aktivem Zugang, AD manage und `is_emergency = false`: `sc_mail_enqueue('ad_emergency_login', person, {"zeitpunkt": …}, 'ad_emergency_login:<log-id>:<person>')`. Jeder Fehler wird abgefangen und als `enqueue_rejected` protokolliert; die Anmeldung scheitert nie.

Hilfsfunktion: `sc_persons_with_level(p_module text, p_min ad_level) returns setof uuid` – Personen mit aktivem Zugang und mindestens dieser Stufe über ihre Rechtevorlagen (gleiche Logik wie `ad_user_level`, aber für alle Zugänge) [ANNAHME: neue Funktion in SC statt Änderung an AD].

## 3. Rechte / RLS

| Rechtevorlage | `sc_connections`, `sc_connection_modules` | `sc_mail_occasions` | `sc_outbox` | `sc_log` |
|---|---|---|---|---|
| Admin (SC manage) | lesen; ändern über Funktionen | lesen, Texte ändern (Funktion) | lesen inkl. Inhalt (Funktion), erneut senden, verwerfen | lesen |
| Geschäftsstelle (SC read) | lesen | lesen ohne `subject`, `body` | lesen ohne `subject`, `body` | lesen |
| alle anderen | – | – | – | – |
| `service_role` (Edge Function) | nur über Funktionen | nur über Funktionen | nur über Funktionen | nur über Funktionen |

- Policies: `select` für `authenticated` mit `public.ad_has_level('SC', 'read')` auf allen fünf Tabellen; keine Policies für insert/update/delete (Schreiben nur über Funktionen).
- Spaltenrechte: `grant select (… ohne subject, body)` auf `sc_mail_occasions` und `sc_outbox` an `authenticated`; Inhalt nur über `sc_mail_occasions`-Pflege (SC edit) bzw. `sc_outbox_content` [ANNAHME: Admin liest Vorlagentexte über eine Lesefunktion `sc_occasion_texts()` mit SC edit].
- Kein Key in einer Tabelle; Vault ist für `authenticated` nicht lesbar.
- Startwerte (Migration, Muster T125 AD): Admin hat SC manage (besteht); Geschäftsstelle SC `read`, nur wenn die Vorlage für SC noch `none` hat und vom Admin nicht geändert wurde; `ad_modules.is_available = true` für SC.

## 4. Zustände und Übergänge

**Anbindung**

| Von | Nach | Wer | Bedingung |
|---|---|---|---|
| – | `disabled` | Admin | `sc_save_connection` |
| `disabled` | `active` | Admin | Key vorhanden, `last_test_ok_at > config_changed_at` (R3, sonst `SC_TEST_REQUIRED`), keine andere aktive derselben Art (R4, sonst `SC_ALREADY_ACTIVE`), `key_expires_on` leer oder in der Zukunft |
| `active`, `disturbed`, `expired` | `disabled` | Admin | – |
| `active` | `disturbed` | System | `consecutive_failures >= 3` (R7) oder neuer Key gesetzt |
| `active` | `expired` | System | `key_expires_on <= heute` (R6) |
| `disturbed`, `expired` | `active` | System nach Test | erfolgreiche Test-E-Mail, Key gültig, R4 |

**E-Mail im Postausgang**

| Von | Nach | Wer | Bedingung |
|---|---|---|---|
| – | `waiting` | Modul | `sc_mail_enqueue` |
| `waiting` | `sent` | Edge Function | Brevo antwortet 201 |
| `waiting` | `waiting` | Edge Function | Fehler bei Versuch 1 → `next_attempt_at = now() + 15 min`; Versuch 2 → `+ 1 h` (R7) |
| `waiting` | `failed` | Edge Function / Job | Fehler bei Versuch 3; Brevo 400 mit ungültiger Empfängeradresse sofort; älter als 7 Tage („zu alt“) |
| `failed` | `waiting` | Admin | `sc_outbox_retry` (attempts = 0, next_attempt_at = now()) |
| `waiting`, `failed` | `discarded` | Admin | `sc_outbox_discard` |
| alle | gelöscht | Job | 90 Tage nach `state_changed_at` (R12) |

Fehlerarten von Brevo: 401/403 (Key) zählt für `consecutive_failures`; 429 (Grenze) und 5xx zählen als Versuch; 400 mit Empfängerfehler → sofort `failed`, zählt nicht für die Störung [ANNAHME]. Ein Erfolg setzt `consecutive_failures = 0`.

## 5. Geschäftsregeln

- R1: Wenn ein Modul oder das Frontend einen externen Dienst ansprechen will, dann nur über `sc_mail_enqueue` bzw. die Edge Function `sc-send`; kein anderer Code kennt die Brevo-Adresse oder den Key.
- R2: Wenn der Anlass einem Modul gehört, das für die E-Mail-Anbindung nicht freigegeben ist, dann Fehler `SC_MODULE_NOT_ALLOWED` „Die Schnittstelle ist für dieses Modul nicht freigegeben.“
- R3: Wenn der Admin aktiviert, ohne dass nach der letzten Änderung ein Test erfolgreich war, dann `SC_TEST_REQUIRED` „Bitte zuerst einen erfolgreichen Test durchführen.“
- R4: Wenn schon eine Anbindung derselben Art aktiv ist, dann `SC_ALREADY_ACTIVE` „Es ist schon eine E-Mail-Anbindung aktiv.“
- R5: Adresse = `ad_accesses.login_email` bei aktivem Zugang, sonst Kontakt-E-Mail; sonst `SC_NO_EMAIL` „Für diese Person ist keine E-Mail-Adresse hinterlegt.“
- R6: Wenn `key_expires_on` erreicht ist, dann `expired`; Erinnerung 30 und 7 Tage vorher an alle mit SC manage.
- R7: Höchstens 3 Versuche (sofort, + 15 min, + 1 h); nach 3 Fehlern in Folge `disturbed`.
- R8: Vorlagen enthalten keine Platzhalter für Personendaten; Anrede „Hallo,“ ohne Namen.
- R9: Wenn eine Vorlage einen nicht erlaubten Platzhalter enthält, dann `SC_PLACEHOLDER_UNKNOWN` „Der Platzhalter {…} ist für diesen Anlass nicht erlaubt.“; Betreff > 150 oder Text > 2.000 Zeichen → `SC_TOO_LONG` „Höchstens 150 Zeichen im Betreff und 2.000 im Text.“
- R10: Wenn es für `dedupe_key` schon eine E-Mail gibt (nicht verworfen), dann keine zweite; die vorhandene id wird zurückgegeben.
- R11: Der Key ist nach dem Speichern nicht mehr lesbar; nur `key_last4`.
- R12: Postausgang und Protokoll werden 90 Tage nach dem letzten Zustandswechsel bzw. Eintrag gelöscht.
- R13: Höchstens `hourly_limit` (100) je Stunde und `daily_limit` (300, TEST 50) je Tag; darüber bleibt die E-Mail `waiting`; ab 250 bzw. Erreichen der Grenze Hinweis in `sc_status()`.
- R14: Kein echter Key in Repository, Seed oder Tests; Tests der Edge Function nutzen ein Fake für `fetch`.
- R15: Jede Änderung an Anbindung, Key, Zustand, Freigaben und Vorlagen schreibt `sc_log` (wer, wann, was, ohne Key und ohne Inhalt).
- R16: Kein Abbestellen im MVP.
- R17: Ohne SC edit bzw. manage keine Aktionen; Funktionen lehnen mit `SC_FORBIDDEN` „Dafür fehlt dir das Recht.“ ab.
- R18: Leere Zustände nach 02-stories.md.

## 6. Screens und Interaktionen

Route `/schnittstellen`, Navigationspunkt „Schnittstellen“ nur mit SC ≥ read. Vier Reiter; mobil als Liste ab 375 px.

1. **Anbindungen** (US-SC-01 bis US-SC-06): Hinweisleiste (`sc_status()`); Karte je Anbindung mit Name, Art, Zustand (Farbe und Wort), Absender, Key „…k3x9“, Ablaufdatum, zuletzt gewechselt, letzter Erfolg, letzter Fehler, Grenzen (heute versendet / 300), freigegebene Module. Aktionen (nur SC manage): „Anbindung anlegen“, „bearbeiten“, „Key wechseln“ (Feld leer, Hinweis „hinterlegt: …k3x9“), „Test-E-Mail senden“ (SC edit), „aktivieren“, „abschalten“ (mit Bestätigung), „Module freigeben“ (Häkchen je verfügbarem Modul). Leer: R18.
2. **Vorlagen** (US-SC-07): Liste der Anlässe (Modul, Name, Beschreibung). SC edit: Betreff und Text bearbeiten, erlaubte Platzhalter als Chips zum Einfügen, Zeichenzähler, „Vorschau“; Geschäftsstelle sieht nur Name und Beschreibung.
3. **Postausgang** (US-SC-10): Tabelle mit Anlass, Modul, Empfänger, Zustand, Versuche, letzter Fehler, eingestellt, versendet; Filter Zustand, Modul, Anlass, Zeitraum; SC edit: „Inhalt ansehen“, „erneut senden“, „verwerfen“ (Bestätigung). Leer: R18.
4. **Protokoll** (US-SC-11): Tabelle mit Zeitpunkt, Anbindung, Modul, Nutzer oder „Job“, Art, Ergebnis, Meldung; Filter Anbindung, Art, Ergebnis, Zeitraum.

**Startseite** (US-SC-13): Hinweiskarte aus `sc_status()` für Nutzer mit SC ≥ read, z. B. „Der E-Mail-Versand ist gestört. Prüfe die Schnittstellen.“, „2 E-Mails konnten nicht versendet werden.“, „Der Key der Anbindung „E-Mail Sektion“ läuft am 30.06.2027 ab.“, „Tageslimit fast erreicht (260 von 300).“

Texte deutsch, Ansprache mit „du“, Begriffe nach glossar.md (Schnittstellen, Anbindung, Postausgang, Anlass).

## 7. Schnittstellen

| Schnittstelle | Aufruf | Inhalt |
|---|---|---|
| Brevo | `POST https://api.brevo.com/v3/smtp/email`, Header `api-key`, `content-type: application/json` | `{ sender: { email, name }, to: [{ email }], subject, textContent }`; Antwort 201 `{ messageId }`; Fehler 400, 401, 429, 5xx; Zeitlimit 15 s |
| Edge Function `sc-send` (Job) | POST, Header `x-sc-dispatch-secret` | prüft Geheimnis (`sc_check_dispatch_secret`), `sc_claim(20)`, je E-Mail Key lesen, Brevo, `sc_report`; Antwort `{ sent, failed }` |
| Edge Function `sc-send` (Test) | POST `{ connection_id }`, Bearer-JWT | prüft `ad_has_level('SC','edit')` mit dem JWT des Aufrufers; `sc_test_prepare`, Brevo, `sc_test_report`; Antwort `{ ok, message }` |
| pg_net | `net.http_post` aus `sc_dispatch()` | nur wenn E-Mails fällig; URL und Geheimnis aus Vault |
| Vault-Einträge je Umgebung (Product Owner, Checkliste `supabase/setup/README.md`) | `sc_dispatch_url`, `sc_dispatch_secret`, `sc_app_url` | nicht im Repository; Keys der Anbindungen setzt der Admin in der Oberfläche |
| AD | Trigger auf `ad_audit_log`, Lesen `ad_accesses`, `ad_modules`, Rechtevorlagen | Anlass `ad_emergency_login` |
| EA | Lesen Eigenschaft `contact` | Kontakt-E-Mail (R5) |

## 8. Nicht-funktionale Anforderungen

- Versand innerhalb von 10 Minuten nach dem Einstellen bei aktiver Anbindung.
- Grenzen: 100 E-Mails je Stunde, 300 je Tag (kostenloser Brevo-Tarif, TEST und PROD im selben Konto; TEST 50).
- Sicherheit: Key nur in Vault und im Speicher der Edge Function während eines Aufrufs; nie in Logs, Fehlermeldungen, Protokoll oder Antworten; Fehlermeldungen von Brevo werden vor dem Speichern gekürzt und auf den Key geprüft (Key-Text wird ersetzt).
- Datenschutz: keine Personendaten im Inhalt außer Empfängeradresse und Link; Löschung nach 90 Tagen; Brevo als Auftragsverarbeiter.
- Mobil ab 375 px; Barrierefreiheit wie im Rest der App (DESIGN.md).
- Nie gegen PROD: Tests und Seed nur lokal bzw. in TEST.

## 9. Testdaten (supabase/seed-sc.sql, nur TEST, nach den bestehenden Seeds)

Alle Daten fiktiv; Adressen nur `@example.test` bzw. Testzugänge `@dav-leipzig.de`; kein Key.

| Nr | Datensatz | Werte |
|---|---|---|
| 1 | Anbindung „E-Mail Test“ | `email_brevo`, `disabled`, Absender `vereinsos.test@example.org`, „Vereins OS (TEST)“, kein Key, `daily_limit` 50, freigegeben für AD und SC |
| 2 | Postausgang | `sc_test` an Testzugang Admin, `sent`, vor 2 Tagen |
| 3 | Postausgang | `ad_emergency_login` an Testzugang Admin, `waiting`, Versuch 1, Fehler „Zeitüberschreitung“ |
| 4 | Postausgang | `sc_key_expiry` an Testzugang Admin, `failed`, 3 Versuche, „Key not found“ |
| 5 | Postausgang | `ad_emergency_login` an Testzugang Admin, `discarded` |
| 6 | Postausgang | `sc_test` an Testzugang Admin, `sent`, vor 95 Tagen (für den Löschlauf) |
| 7 | Protokoll | `connection_created`, `modules_changed`, `test` (error), `send` (ok), `send` (error) |

Testzugänge: bestehende Admin- und Geschäftsstelle-Zugänge; Referent:in als Fall „kein Recht“.

## 10. Umsetzungs-Tasks

- [ ] T1: Migration Typen, Tabellen, Indizes, RLS, Policies, Spaltenrechte (`sc_connections`, `sc_connection_modules`, `sc_mail_occasions`, `sc_outbox`, `sc_log`) (US-SC-01, 02, 10, 11)
- [ ] T2: Migration Startwerte: Geschäftsstelle SC `read` (ohne Überschreiben), `ad_modules.is_available` für SC, Anlässe `sc_test`, `sc_key_expiry` mit Starttexten (US-SC-16)
- [ ] T3: Funktionen der Oberfläche `sc_save_connection`, `sc_set_key` (Vault), `sc_set_state`, `sc_set_modules` mit Protokoll (US-SC-02 bis 06)
- [ ] T4: Funktionen Vorlagen `sc_save_occasion`, `sc_preview_occasion`, `sc_occasion_texts` (US-SC-07)
- [ ] T5: `sc_mail_enqueue` mit R2, R5, R8–R10; `sc_persons_with_level` (US-SC-08)
- [ ] T6: Funktionen für `service_role`: `sc_check_dispatch_secret`, `sc_claim` (Grenzen R13), `sc_connection_key`, `sc_report` (R7), `sc_test_prepare`, `sc_test_report` (US-SC-03, 09)
- [ ] T7: `sc_outbox_retry`, `sc_outbox_discard`, `sc_outbox_content`, `sc_status` (US-SC-10, 13)
- [ ] T8: Jobs: pg_net aktivieren, `sc_dispatch()` (5 Minuten), `sc_daily()` (Erinnerung, abgelaufen, „zu alt“, Löschlauf) (US-SC-09, 12, 15)
- [ ] T9: Anlass `ad_emergency_login` und Trigger auf `ad_audit_log`, fehlertolerant (US-SC-14)
- [ ] T10: pgTAP-Tests je Funktion und Policy: Rechte-Fälle (Admin, Geschäftsstelle, Referent:in, anon), R2–R13, Dedupe, Spaltenrechte, Key nie lesbar, Trigger bricht Anmeldung nie ab (alle)
- [ ] T11: Edge Function `sc-send` (Job- und Testmodus) mit `_shared`-Mustern, Brevo-Client, Kürzen und Bereinigen von Fehlermeldungen; Deno-Tests mit Fake-`fetch` (201, 400, 401, 429, Zeitüberschreitung) (US-SC-03, 09)
- [ ] T12: Seed `supabase/seed-sc.sql` und Aufnahme in `seed.sh` (US-SC-16)
- [ ] T13: Oberfläche Route `/schnittstellen`, Navigation, Reiter „Anbindungen“ mit Dialogen (anlegen, bearbeiten, Key wechseln, Test, aktivieren, abschalten, Module) (US-SC-01 bis 06)
- [ ] T14: Reiter „Vorlagen“ mit Platzhalter-Chips, Zähler, Vorschau (US-SC-07)
- [ ] T15: Reiter „Postausgang“ und „Protokoll“ mit Filtern und Aktionen (US-SC-10, 11)
- [ ] T16: Hinweiskarte auf der Startseite und Hinweisleiste (US-SC-13)
- [ ] T17: Checkliste `supabase/setup/README.md`: Vault-Einträge `sc_dispatch_url`, `sc_dispatch_secret`, `sc_app_url` je Umgebung, Brevo-Keys je Umgebung, Bereitstellung der Edge Function (Product Owner)
- [ ] T18: Anleitung: Abschnitt „Schnittstellen“ (Admin, Geschäftsstelle), Screenshots, Ablaufbild Postausgang, Tabelle „Welche Module gibt es?“, neue Hauptversion (CLAUDE.md)
- [ ] T19: abnahme-test.md für TEST: Anbindung mit echtem TEST-Key anlegen, Test-E-Mail an einen Testzugang, Notfall-Admin-Anmeldung, Zustellung an eine DAV-Adresse (Spam-Ordner prüfen)

## 11. Annahmen und offene Punkte

Annahmen [ANNAHME], vom Product Owner bis Ready zu bestätigen:
- A1 Versand über die Brevo-HTTP-API (nicht SMTP-Relay); Auslösen per pg_cron → pg_net → Edge Function; Geheimnis und URLs in Vault, gesetzt vom Product Owner je Umgebung.
- A2 Stufen in SC: read = ansehen; edit = Vorlagen, Test, erneut senden, verwerfen, Inhalt ansehen; manage = Anbindung, Key, Zustand, Freigaben. Der Admin hat manage, die Geschäftsstelle read.
- A3 Ein neuer Key setzt eine aktive Anbindung auf „gestört“, bis die Test-E-Mail erfolgreich war.
- A4 Grenzen als Spalten der Anbindung (100, 300; TEST 50), änderbar nur nach unten.
- A5 Absendername „Vereins OS“; in TEST „Vereins OS (TEST)“.
- A6 Link in E-Mails aus der Basis-URL der Umgebung (`sc_app_url`), die SC selbst einsetzt; Module übergeben nur einen Pfad [ANNAHME: `{link}` zeigt auf die zum Anlass passende Seite, z. B. `/administration/protokoll`].
- A7 Brevo-Fehler 400 wegen Empfänger → sofort „fehlgeschlagen“, ohne Störung der Anbindung.
- A8 Reiner Text, kein HTML; kein Tracking.
- A9 Kein Löschen von Anbindungen im MVP; Abschalten genügt.
- A10 Begriffe **Dienst**, **Anbindung**, **Aufruf**, **Postausgang**, **Anlass** kommen mit Ready ins Glossar (Definition of Ready).

Offene Punkte: keine. Abhängig: Iteration 1 (DATEV, Q-SC4) und Iteration 2 (Instagram, Q-SC5) mit eigener Spec-Erweiterung.
