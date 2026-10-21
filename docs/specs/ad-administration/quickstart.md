# Quickstart: Validierung AD

Stand: 20.10.2026 · Phase 1 zu [plan.md](plan.md) · Grundlage: [spec.md](spec.md) v0.5

Datenbanktests laufen automatisch in der GitHub Action (lokaler Stack). Die fachliche Abnahme läuft in **vereins-os-test**. Kein Schritt dieser Anleitung wird gegen PROD ausgeführt.

## A. Datenbanktests (GitHub Action)

| # | Schritt | Erwartet |
|---|---|---|
| 1 | Pull Request öffnen oder aktualisieren | Workflow `.github/workflows/db-tests.yml` startet |
| 2 | `supabase start` (automatischer Seed aus) → `supabase/seed.sh` gegen den lokalen Stack | 8 Personen, 3 aktive Testzugänge, 4 Protokolleinträge |
| 3 | `supabase test db` | alle pgTAP-Tests grün (research.md R-11) |
| 4 | `deno test supabase/functions` | Aufräumen von `ad-invite` bei simuliertem Auth-Fehler grün (US-AD-08 AK5) |

Voraussetzung: GitHub-Secret `SEED_TEST_PASSWORD`.

## B. Bereitstellung in TEST

Voraussetzungen:
- Die Supabase CLI ist mit vereins-os-test verknüpft. Vor jedem Befehl mit `npx supabase projects list` prüfen, welches Projekt verknüpft ist.
- `.env.local` enthält `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY` (Publishable Key), `SEED_TEST_PASSWORD` und `SEED_DB_URL` (Verbindung zu TEST). Vorlage ist `.env.example`.
- `psql` ist installiert.
- SMTP ist im Dashboard von TEST eingetragen, Absendername „Vereins OS“.

| # | Schritt | Befehl / Aktion | Erwartet |
|---|---|---|---|
| 1 | Migrationen prüfen | `npx supabase db push --linked --dry-run` | listet nur die neuen AD-Migrationen |
| 2 | Migrationen anwenden | `npx supabase db push --linked` | läuft ohne Fehler |
| 3 | Auth-Einstellungen | **manuell durch den Product Owner im TEST-Dashboard** nach der Checkliste in `supabase/setup/README.md`; kein `config push`/`config diff` (`config.toml` gilt nur für den lokalen Stack) | Selbstregistrierung aus, Passwort ≥ 8, Redirect-URLs, deutsche Vorlagen aus `supabase/templates/`, `email_sent = 30` |
| 4 | Edge Functions | `npx supabase functions deploy ad-invite ad-access` | beide aktiv |
| 5 | Seed | `supabase/seed.sh` | Testdaten nach spec.md Abschnitt 9 |
| 6 | Seed-Schutz | `seed.sh` mit einer Verbindung, deren Project Ref die von vereins-os-prod ist (nur Prüfung der Ref, ohne Verbindung) | Abbruch „Seed in PROD nicht erlaubt.“ |
| 7 | Frontend | `npm run dev` → http://localhost:5173, alternativ Cloudflare-Vorschau | Login-Seite |

## C. Fachliche Abnahme in TEST (T25)

Testzugänge nach spec.md Abschnitt 9, Passwort aus `SEED_TEST_PASSWORD`. Die Seed-Adressen `test.*@dav-leipzig.de` sind fiktiv. **An Seed-Adressen werden in TEST keine Einladungen verschickt** (Bounces, Mail-Limit von 30 je Stunde); kein „Einladen“ oder „Erneut einladen“ bei Seed-Personen. Eingeladen werden nur die eigenen Adressen des Product Owners (C1).

### C1. Mail-Abläufe mit eigenen Adressen des Product Owners

Grundlage: spec.md v0.5 Abschnitt 9 und Constitution V (Ausnahme). Alle Schritte führt der Product Owner selbst aus. Domain und Adressen stehen nie im Repo, im Seed, in `.env.local` oder in einer Migration. Unten heißen sie `<private Adresse 1>` und `<private Adresse 2>`; beide haben dieselbe Domain.

1. Im TEST-Dashboard im SQL-Editor die Domain der privaten Adressen (ohne „@“) in `ad_test_login_domains` eintragen.
2. Als test.admin in der Oberfläche fiktive Personen anlegen, ihnen die privaten Adressen als Login-Adresse geben und eine Vorlage zuweisen.
3. Die Szenarien unten mit den Zeilen „eigene Adresse“ durchspielen.
4. Danach aufräumen (C2).

| Szenario | Zugang | Erwartet | Story |
|---|---|---|---|
| Login, Startseite | test.admin | Name in der Kopfzeile, nur Kachel AD | US-AD-02 AK1, US-AD-05 AK1 |
| Login Vorstand | test.vorstand | Name in der Kopfzeile, „Für dich sind noch keine Module freigeschaltet.“ und darunter „Wende dich an den Admin, wenn du Zugriff brauchst.“ | US-AD-05 AK2 |
| /ad direkt aufrufen | test.geschaeftsstelle | „Für diesen Bereich hast du keine Rechte.“, keine Abfrage auf AD-Tabellen | US-AD-05 AK3, US-AD-06 AK5 |
| Login gesperrt | test.gesperrt | R18-Meldung | US-AD-02 AK3 |
| Dublette | test.admin legt „Toni Muster“, „Tony Muster“, „Anton Muster“ an | Warndialog mit Treffern; Schwelle 0,3 abnehmen | US-AD-07 AK3 |
| Einladen ohne Vorlage | test.admin, neue Person | „Bitte zuerst mindestens eine Rechtevorlage zuweisen.“ | US-AD-08 AK2 |
| R1 in TEST | test.admin: Login-Adresse mit einer nicht freigegebenen Domain | „Zugang nur mit Adresse @dav-leipzig.de möglich.“ | US-AD-07 AK5 |
| Einladung (eigene Adresse) | Person mit `<private Adresse 1>`, „Einladen“ | Mail im Posteingang, Status „eingeladen“, Protokoll „eingeladen“ | US-AD-08 AK1 |
| Login-Adresse bei „eingeladen“ ändern (eigene Adresse) | dieselbe Person: Adresse auf `<private Adresse 2>` ändern | Hinweis „Die Login-Adresse wurde geändert. Bitte die Einladung erneut senden.“, Status „kein Zugang“, Protokoll „Login-Adresse geändert“; alter Link an Adresse 1 → „Der Link ist abgelaufen oder ungültig. Bitte wende dich an den Admin.“; „Einladen“ → Mail an Adresse 2 | US-AD-08 AK7, US-AD-03 AK7 |
| Login-Adresse bei „aktiv“ ändern | test.admin bei Bernd Beispiel | „Die Login-Adresse kann nur vor der Aktivierung des Zugangs geändert werden.“ | US-AD-08 AK7 |
| Passwort setzen (eigene Adresse) | Link aus der Mail an `<private Adresse 2>` → /passwort-setzen | ungleiche Eingaben → R19-Meldung; Seite ohne Speichern verlassen → Status bleibt „eingeladen“; Speichern → „aktiv“, Startseite | US-AD-03 AK1, AK2, AK6 |
| Passwort vergessen (eigene Adresse) | beliebige Adresse; danach `<private Adresse 2>` (jetzt aktiv) | immer die R18-Bestätigung; Mail an Adresse 2 kommt an, neues Passwort funktioniert | US-AD-04 AK1, AK2 |
| Sperren/Entsperren | test.admin bei Eva Eingeladen und Dieter Gesperrt | Status nach spec.md Abschnitt 4, Protokolleinträge | US-AD-09 |
| Vertrauliche Eigenschaft | test.geschaeftsstelle per REST auf `ea_properties` | Hauptamt fehlt | US-AD-13 AK4, US-AD-16 AK2 |
| Notfall-Admin | Login test.notfall, danach öffnet test.admin /ad | Hinweis mit Anzahl und Zeitpunkt; „Zur Kenntnis genommen“ blendet ihn aus | US-AD-15 AK1, AK2 |
| Protokoll unveränderbar | test.admin per REST `PATCH`/`DELETE` auf `ad_audit_log` | abgelehnt | US-AD-14 AK4 |
| Mobil | alle Screens bei 375 px | kein horizontales Scrollen | spec.md Abschnitt 6 |

### C2. Aufräumen nach der Abnahme (Product Owner, TEST-Dashboard)

Nach spec.md Abschnitt 9 Schritt 3. Es gibt keine Löschfunktion in der Oberfläche.
1. Unter Authentication → Users die Auth-Nutzer mit den privaten Adressen löschen. `ad_accesses.auth_user_id` wird dabei leer (`on delete set null`), `ad_notice_acks` wird mitgelöscht.
2. Im SQL-Editor die Testpersonen der Abnahme löschen. Wegen der Fremdschlüssel in dieser Reihenfolge, jeweils gefiltert auf die IDs der Testpersonen: `ad_audit_log` (Einträge mit `subject_person_id`), `ad_template_assignments`, `ad_accesses`, `ea_properties` (die Historie wird per Cascade mitgelöscht), `ea_persons`.
3. Die Domain aus `ad_test_login_domains` löschen.
4. Zur Kontrolle: `select count(*) from ad_test_login_domains` = 0; keine Login-Adresse mit der privaten Domain mehr in `ad_accesses`.

Hinweis: Schritt 2 löscht auch die Protokolleinträge der Testpersonen. Sie enthalten die privaten Adressen (Details von `email_changed`). Das ist eine enge Ausnahme nur für dieses Aufräumen in TEST (Constitution V, Version 1.1.1). Für Nutzer bleibt das Protokoll unveränderbar (US-AD-14 AK4).

Außerdem zu prüfen: alle Stellen in [research.md](research.md), die mit `[PRÜFEN T25]` markiert sind.

## D. Ersteinrichtung PROD (nur Dokumentation)

Ausführung nur durch den Product Owner, nie durch den Agenten. Der Weg nach PROD ist [OFFEN] (O1).
1. Migrationen und Edge Functions nach PROD bringen (Weg nach O1). Auth-Einstellungen und SMTP im Dashboard von PROD nach der Checkliste in `supabase/setup/README.md` setzen.
2. `supabase/setup/prod-bootstrap.sql` mit den Parametern Vorname, Nachname und Login-Adresse des Admins ausführen (T24). Das Skript bricht ab, wenn `ad_test_login_domains` Einträge hat.
3. Toni Werner über das Supabase-Dashboard einladen. Der Status wechselt auf „eingeladen“.
4. Zustellungstest (US-AD-01 AK5): Die Einladung muss im Posteingang liegen, nicht im Junk-Ordner oder in der Quarantäne. Passwort setzen; der Status wechselt auf „aktiv“. Danach „Passwort vergessen“ auslösen; auch diese Mail muss im Posteingang liegen.
5. Den Notfall-Admin (geschaeftsstelle@dav-leipzig.de) über AD einladen (US-AD-08).
