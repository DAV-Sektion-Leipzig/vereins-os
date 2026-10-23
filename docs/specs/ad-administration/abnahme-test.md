# Abnahme-Test: Administration, Kern v0.7.4

Umsetzungsdatei (Phase 14 in [tasks.md](tasks.md), T102–T105). Grundlage: [quickstart.md](quickstart.md) Abschnitte C, C2 und C3, spec.md v0.9.3. Stand: 23.10.2026. Private Adressen stehen hier nie; Mail-Abläufe (C1) führt der Product Owner selbst aus.

Legende: **erledigt** = von Claude Code geprüft, Ergebnis festgehalten · **offen (PO)** = nur mit Testzugang, Oberfläche oder Postfach prüfbar, führt der Product Owner aus und trägt das Ergebnis ein.

## 1. Stand in TEST (T103, Vorbereitung)

| Punkt | Stand |
|---|---|
| Migrationen `20261020000100` … `20261023001800` | `npx supabase migration list --linked`: 24 Migrationen lokal und remote gleich (23.10.2026) |
| Edge Functions `ad-invite`, `ad-access` | deployt 23.10.2026 (Stand `main` nach PR #31) |
| Seed (Personen 1–12, Testzugänge, 47 Qualifikationsarten) | vorhanden (`inspect db table-stats`: `ea_persons` 13, `ad_qualification_types` 47, `ad_accesses` 8, `ad_template_rights` 36) |
| `ad_test_login_domains` | 0 Zeilen, bereit für C1 Schritt 1 |
| Auth-Einstellungen und SMTP | stellt der Product Owner nach `supabase/setup/README.md` ein; nicht von hier prüfbar |

Claude Code hat weder eine Domain noch eine Adresse eingetragen.

## 2. Querschnitt (T105) – erledigt

| Prüfung | Ergebnis |
|---|---|
| `npm run lint` | keine Fehler; Warnungen nur in `src/components/ui/button.tsx` und `badge.tsx` (shadcn-Vorlage, `only-export-components`) sowie in `.claude/skills/impeccable/scripts/*` (fremde Skripte, kein Projektcode) |
| `npm run build` | ohne Fehler; Hinweis auf Chunk-Größe > 500 kB (bekannt) |
| `npm audit --omit=dev` | 0 Schwachstellen im Produktivcode |
| `npm audit` (mit Entwicklungsabhängigkeiten) | 7 „hoch“: `braces` → `micromatch` → `fast-glob` → `@shadcn/registry`/`shadcn` und `@ts-morph/common`/`ts-morph`. Nur Werkzeuge der shadcn-CLI, nicht im Bundle. Behebung hängt an einem Update der shadcn-CLI |
| Adressen im Repo (`git grep` auf `@`) | nur `@dav-leipzig.de`, `example.test`, `example.org`, `rita@woanders.test` (reservierte Testdomain in `supabase/tests/database/030_auth_triggers.test.sql`) und das auskommentierte Supabase-Beispiel `admin@email.com` in `supabase/config.toml` |
| Secrets im Diff | keine; Frontend-Bundle enthält nur die TEST-URL und den Publishable Key (öffentlich, gewollt) |

## 3. Prüfungen ohne Anmeldung gegen TEST (T104, Teil) – erledigt

REST mit dem Publishable Key ohne Sitzung (Rolle `anon`), 23.10.2026. Erwartung nach CLAUDE.md („GRANTs nur an `authenticated`“) und spec.md Abschnitt 3.

| Aufruf | Ergebnis |
|---|---|
| `GET /rest/v1/ea_persons` | 401, `42501 permission denied` |
| `GET /rest/v1/ad_accesses` | 401, `42501` |
| `GET /rest/v1/ea_properties` | 401, `42501` |
| `GET /rest/v1/ad_test_login_domains` | 401, `42501` |
| `GET /rest/v1/ad_v_audit_log` | 401, `42501 permission denied for view` |
| `POST /rest/v1/rpc/ad_login_email_ok` | 401, `42501 permission denied for function` |
| `POST /rest/v1/rpc/ad_find_similar_persons` | 401, `42501 permission denied for function` |
| `POST /functions/v1/ad-invite` ohne JWT | 401, `{"code":"AD_UNAUTHENTICATED"}` |
| `POST /functions/v1/ad-access` ohne JWT | 401, `{"code":"AD_UNAUTHENTICATED"}` |

## 4. Dublettenschwelle (T102) – Bewertung erledigt, Bestätigung im Dialog offen (PO)

Regel R3a (spec.md Abschnitt 5): Nachname gleich (ohne Groß-/Kleinschreibung, getrimmt) **und** Vorname passt zu Vorname oder Rufname über `ad_first_names_match` (`similarity ≥ 0,3`, Enthaltensein oder gemeinsame Zeichenfolge aus 3 Buchstaben).

Durchgeführt am 23.10.2026 gegen den lokalen Stack mit denselben Migrationen und demselben Seed wie TEST (Datenbankstand identisch; die Oberfläche in TEST zeigt dieselben Treffer). Zusätzlich zu den Seed-Personen Toni Muster (4) und Anton Muster (5) wurden in einer zurückgerollten Transaktion Antonia, Tanja und Tom Muster angelegt. Aufruf als Admin.

| Eingabe | Treffer | Keine Treffer |
|---|---|---|
| Tony Muster | Toni, Anton, Antonia | Tanja, Tom |
| Toni Muster | Toni, Anton, Antonia | Tanja, Tom |
| Anton Muster | Anton, Toni, Antonia | Tanja, Tom |
| Tonni Muster (Tippfehler Vorname) | Toni, Anton, Antonia | Tanja, Tom |
| Toni Mustre (Tippfehler Nachname) | – | alle (R3a verlangt gleichen Nachnamen) |

Ähnlichkeit der Vornamen (`pg_trgm`): Tony/Toni 0,43 · Tonni/Toni 0,57 · Anton/Antonia 0,56 · Tony/Tom 0,29 · Tony/Tanja 0,10 · Tony/Anton 0,10 (Treffer über die gemeinsame Zeichenfolge „ton“).

Zur Bewertung durch den Product Owner (T102, bei Bedarf Schwelle per neuer Migration):
- Ein Tippfehler im Nachnamen führt zu keiner Warnung. Das entspricht R3a; ob das reicht, entscheidet der Product Owner.
- „Tony“ warnt auch vor „Antonia“ (gemeinsame Zeichenfolge „ton“). Gewollt nach v0.7.3 (Toni/Anton), Nebenwirkung bei längeren Namen.
- Ergebnis im Dialog in TEST (quickstart.md C, Zeile „Dublette“; nur Name, Rufname, Geburtsjahr, ggf. „ausgeschieden seit“): **offen (PO)**

## 5. Szenarien mit Testzugängen (T102, T104) – offen (PO)

Mit den Testzugängen `test.admin`, `test.geschaeftsstelle`, `test.referent`, `test.vorstand`, `test.gesperrt`, `test.notfall` (Passwort `SEED_TEST_PASSWORD`). Erwartung je Zeile steht in quickstart.md; hier nur das Ergebnis. Bei 375 px zusätzlich: kein horizontales Scrollen.

### 5.1 quickstart.md C (ohne Mail-Zeilen)

| Szenario | Story | Ergebnis |
|---|---|---|
| Login, Startseite (test.admin) | US-AD-02 AK1, US-AD-05 AK1 | offen |
| Login Vorstand, Hinweis ohne Module | US-AD-05 AK2 | offen |
| /ad direkt als test.geschaeftsstelle → /kein-zugriff ohne Abfrage | US-AD-05 AK3, US-AD-06 AK5 | offen |
| Login gesperrt (test.gesperrt) → R18 | US-AD-02 AK3 | offen |
| Dublette „Tony Muster“ anlegen → Dialog | US-AD-07 AK3, US-AD-25 | offen |
| Einladen ohne Vorlage → Meldung | US-AD-08 AK2 | offen |
| R1: Login-Adresse mit fremder Domain → Meldung vor dem Anlegen (v0.7.4, Vorabprüfung) | US-AD-07 AK5 | offen |
| Login-Adresse bei „aktiv“ ändern (Bernd Beispiel) → abgelehnt | US-AD-08 AK7 | offen |
| Sperren Eva Eingeladen / Entsperren Dieter Gesperrt, Protokoll | US-AD-09 | offen |
| Vertrauliche Eigenschaft per REST als Geschäftsstelle → Hauptamt fehlt | US-AD-13 AK4, US-AD-16 AK2 | offen |
| Notfall-Admin: Login test.notfall, Hinweis bei test.admin, „Zur Kenntnis genommen“ | US-AD-15 AK1, AK2 | offen |
| Protokoll per REST `PATCH`/`DELETE` → abgelehnt | US-AD-14 AK4 | offen |
| Mobil 375 px, alle Screens | spec.md Abschnitt 6 | offen |

### 5.2 quickstart.md C1 (Mail-Abläufe mit eigenen Adressen, nur Product Owner)

| Szenario | Story | Ergebnis |
|---|---|---|
| Einladung an `<private Adresse 1>`: Mail, Status „eingeladen“, Protokoll | US-AD-08 AK1 | offen |
| Login-Adresse bei „eingeladen“ ändern → Hinweis, „kein Zugang“, Protokoll; alter Link ungültig; erneut einladen | US-AD-08 AK7, US-AD-03 AK7 | offen |
| Passwort setzen über den Link (R19, Abbruch, Speichern → „aktiv“) | US-AD-03 AK1, AK2, AK6 | offen |
| Passwort vergessen (immer R18-Bestätigung, Mail kommt an) | US-AD-04 AK1, AK2 | offen |
| Aufräumen nach C2 (Auth-Nutzer, Testpersonen, Domain; Kontrolle `ad_test_login_domains` = 0) | spec.md Abschnitt 9 | offen |

### 5.3 quickstart.md C3 (Kern v0.7)

| Szenario | Story | Ergebnis |
|---|---|---|
| Sichtbarkeit je Pfad (Tabelle in data-model.md, Vorstand sieht niemanden) | US-AD-23, US-AD-26 | offen |
| Lesestufen: Geschäftsstelle ohne „Hauptamt“, Referent:in ohne „Geburtsdatum“ und „Hauptamt“ | US-AD-22, US-AD-23 | offen |
| Reichweite „Referat“ in einer GR-Vorlage → Meldung | US-AD-20 | offen |
| Referent:in ohne Referat zuweisen → Meldung; mit Referat → Protokoll | US-AD-21 | offen |
| Eigenschaftsart mit zwei Feldern; Datentyp-Änderung mit Daten abgelehnt | US-AD-22 | offen |
| Qualifikationsarten: 47 Einträge, Filter „aktuell“, Vorstand kann nicht speichern | US-AD-17, US-AD-18 | offen |
| Historische Qualifikationsart als Feldwert → Meldung | US-AD-19 | offen |
| Rufname an Person 4 → Übersicht, Detail, Kopfzeile | US-AD-24 | offen |
| Mobil 375 px, neue Screens | spec.md Abschnitt 6 | offen |

Diese Zeilen sind in der Datenbank durch pgTAP abgedeckt (Dateien 060–240, in CI grün); offen ist nur die Bestätigung in der Oberfläche von TEST.

## 6. `[PRÜFEN T25]`-Punkte aus research.md

| Punkt | Stand |
|---|---|
| Pflichtspalten von `auth.users` und `auth.identities` | **erledigt**: Seed (direkte Inserts) läuft in TEST und im lokalen Stack ohne Fehler; Migration 001800 (Trigger auf `auth.users`) in TEST angewendet |
| Eingeladene Nutzer haben leeres `encrypted_password` | offen (PO): nach C1 im SQL-Editor von TEST `select encrypted_password = '' from auth.users where email = '<private Adresse 1>'` prüfen; Grundlage für `ad_apply_unlock` (Zielstatus) |
| Erneute Einladung an unbestätigten Nutzer wird versendet | offen (PO): C1, „Einladen“ ein zweites Mal bei Status „eingeladen“ |
| `verifyOtp` schlägt für gebannte Nutzer fehl | offen (PO): in C1 eine eingeladene Testperson sperren und den Link aus der Mail öffnen; Erwartung „Der Link ist abgelaufen oder ungültig …“ |

## 7. Grenzen dieser Abnahme

- Claude Code hat in dieser Umgebung keinen Browser und kein Testpasswort; Oberfläche und Testzugänge prüft der Product Owner in TEST (Abschnitt 5).
- Direkte SQL-Abfragen gegen TEST sind für Claude Code nicht vorgesehen (Verbindungsdaten liegen nur in `.env.local`); Datenbankverhalten ist über die pgTAP-Tests mit identischen Migrationen und identischem Seed abgedeckt.
- Ergebnisse des zweiten Review-Workflows (Stand nach Review 1) werden hier als Nachtrag ergänzt, sobald sie vorliegen.
