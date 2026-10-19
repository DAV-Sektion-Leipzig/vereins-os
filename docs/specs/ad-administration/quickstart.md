# Quickstart: Validierung AD

Stand: 19.10.2026 · Phase 1 zu [plan.md](plan.md) · Grundlage: [spec.md](spec.md) v0.3

Datenbanktests laufen automatisch in der GitHub Action (lokaler Stack). Die fachliche Abnahme läuft in **vereins-os-test**. Kein Schritt dieser Anleitung wird gegen PROD ausgeführt.

## A. Datenbanktests (GitHub Action)

| # | Schritt | Erwartet |
|---|---|---|
| 1 | Pull Request öffnen oder aktualisieren | Workflow `.github/workflows/db-tests.yml` startet |
| 2 | `supabase start` (automatischer Seed aus) → `supabase/seed.sh` gegen den lokalen Stack | 8 Personen, 3 aktive Testzugänge, 4 Protokolleinträge |
| 3 | `supabase test db` | alle pgTAP-Tests grün (research.md R-11) |

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
| 3 | Auth-Konfiguration | `npx supabase config diff` → `npx supabase config push` | Selbstregistrierung aus, Passwort ≥ 8, Redirect-URLs, deutsche Vorlagen, `email_sent = 30` |
| 4 | Edge Functions | `npx supabase functions deploy ad-invite ad-access` | beide aktiv |
| 5 | Seed | `supabase/seed.sh` | Testdaten nach spec.md Abschnitt 9 |
| 6 | Seed-Schutz | `seed.sh` mit einer Verbindung, deren Project Ref die von vereins-os-prod ist (nur Prüfung der Ref, ohne Verbindung) | Abbruch „Seed in PROD nicht erlaubt.“ |
| 7 | Frontend | `npm run dev` → http://localhost:5173, alternativ Cloudflare-Vorschau | Login-Seite |

## C. Fachliche Abnahme in TEST (T25)

Testzugänge nach spec.md Abschnitt 9, Passwort aus `SEED_TEST_PASSWORD`. Nur fiktive Adressen. Einladungs-Mails an `test.*@dav-leipzig.de` kommen nicht an; geprüft wird dabei nur, ob Status und Protokoll stimmen.

| Szenario | Zugang | Erwartet | Story |
|---|---|---|---|
| Login, Startseite | test.admin | Name in der Kopfzeile, nur Kachel AD | US-AD-02 AK1, US-AD-05 AK1 |
| Login Vorstand | test.vorstand | Name in der Kopfzeile, „Für dich sind noch keine Module freigeschaltet.“ | US-AD-05 AK2 |
| /ad direkt aufrufen | test.geschaeftsstelle | „Für diesen Bereich hast du keine Rechte.“, keine Abfrage auf AD-Tabellen | US-AD-05 AK3, US-AD-06 AK5 |
| Login gesperrt | test.gesperrt | R18-Meldung | US-AD-02 AK3 |
| Dublette | test.admin legt „Toni Muster“, „Tony Muster“, „Anton Muster“ an | Warndialog mit Treffern; Schwelle 0,3 abnehmen | US-AD-07 AK3 |
| Einladen ohne Vorlage | test.admin, neue Person | „Bitte zuerst mindestens eine Rechtevorlage zuweisen.“ | US-AD-08 AK2 |
| Login-Adresse ändern | test.admin bei Eva Eingeladen → speichern → „Erneut einladen“; bei Bernd Beispiel (aktiv) → speichern | eingeladen: Adresse wird übernommen, auch in Auth; aktiv: „Die Login-Adresse kann nur vor der Aktivierung des Zugangs geändert werden.“ | US-AD-08 AK7 |
| Passwort setzen | Einladungslink an eine fiktive Adresse – wie der Link in TEST abgerufen wird, ist noch ungeklärt (siehe Meldung zum Abgleich v0.3) → /passwort-setzen | ungleiche Eingaben → R19-Meldung; Seite ohne Speichern verlassen → Status bleibt „eingeladen“; Speichern → „aktiv“ | US-AD-03 AK1, AK2, AK6 |
| Passwort vergessen | beliebige Adresse | immer die R18-Bestätigung | US-AD-04 AK1 |
| Sperren/Entsperren | test.admin bei Eva Eingeladen und Dieter Gesperrt | Status nach spec.md Abschnitt 4, Protokolleinträge | US-AD-09 |
| Vertrauliche Eigenschaft | test.geschaeftsstelle per REST auf `ea_properties` | Hauptamt fehlt | US-AD-13 AK4, US-AD-16 AK2 |
| Notfall-Admin | Login test.notfall, danach öffnet test.admin /ad | Hinweis mit Anzahl und Zeitpunkt; „Zur Kenntnis genommen“ blendet ihn aus | US-AD-15 AK1, AK2 |
| Protokoll unveränderbar | test.admin per REST `PATCH`/`DELETE` auf `ad_audit_log` | abgelehnt | US-AD-14 AK4 |
| Mobil | alle Screens bei 375 px | kein horizontales Scrollen | spec.md Abschnitt 6 |

Außerdem zu prüfen: alle Stellen in [research.md](research.md), die mit `[PRÜFEN T25]` markiert sind.

## D. Ersteinrichtung PROD (nur Dokumentation)

Ausführung nur durch den Product Owner, nie durch den Agenten. Der Weg nach PROD ist [OFFEN] (O1).
1. Migrationen, Edge Functions und Auth-Konfiguration nach PROD bringen (Weg nach O1). SMTP im Dashboard von PROD eintragen.
2. `supabase/setup/prod-bootstrap.sql` mit den Parametern Vorname, Nachname und Login-Adresse des Admins ausführen (T24).
3. Toni Werner über das Supabase-Dashboard einladen. Der Status wechselt auf „eingeladen“.
4. Zustellungstest (US-AD-01 AK5): Die Einladung muss im Posteingang liegen, nicht im Junk-Ordner oder in der Quarantäne. Passwort setzen; der Status wechselt auf „aktiv“. Danach „Passwort vergessen“ auslösen; auch diese Mail muss im Posteingang liegen.
5. Den Notfall-Admin (geschaeftsstelle@dav-leipzig.de) über AD einladen (US-AD-08).
