# Ersteinrichtung und Auth-Einstellungen (Product Owner)

> **Nur durch den Product Owner. Claude Code führt nichts gegen PROD aus.**
> Grundlage: `docs/specs/ad-administration/spec.md` (US-AD-01, spec T11, T24) und `quickstart.md` Abschnitt D.

`supabase/config.toml` gilt nur für den lokalen Stack (GitHub Action). Es gibt **kein** `supabase config push` und **kein** `supabase config diff` gegen TEST oder PROD. Die Auth-Einstellungen in TEST und PROD setzt der Product Owner im Dashboard, und zwar nach der Checkliste unten.

## 1. Checkliste „Auth-Einstellungen im Dashboard“

Für **TEST** und für **PROD** je einmal abhaken. TEST: Punkte 1–7 und 9 erledigt (Product Owner, 20.10.2026).

| # | Einstellung (Dashboard) | Wert | TEST | PROD |
|---|---|---|---|---|
| 1 | Authentication → Sign In / Providers → „Allow new users to sign up“ | aus (`enable_signup = false`) | ☑ | ☐ |
| 2 | Authentication → Sign In / Providers → Email | an; „Confirm email“ wie in `config.toml` | ☑ | ☐ |
| 3 | Passwort-Mindestlänge | 8 (`minimum_password_length = 8`), keine weiteren Zeichenregeln | ☑ | ☐ |
| 4 | Authentication → Rate Limits → E-Mails je Stunde | 30 (`email_sent = 30`) | ☑ | ☐ |
| 5 | Authentication → URL Configuration → Site URL | PROD: `https://vereins-os.sektion-leipzig.workers.dev`; TEST: dieselbe bzw. die Vorschau-Adresse | ☑ | ☐ |
| 6 | Authentication → URL Configuration → Redirect URLs | wie `additional_redirect_urls` in `config.toml`; in TEST zusätzlich Vorschau (`https://*-vereins-os.sektion-leipzig.workers.dev/**`) und lokal (`http://localhost:5173/**`) | ☑ | ☐ |
| 7 | Authentication → Emails → „Invite user“ | Betreff „Einladung ins Vereins OS“, Inhalt aus `supabase/templates/invite.html` | ☑ | ☐ |
| 8 | Authentication → Emails → „Reset password“ | Betreff „Passwort zurücksetzen“, Inhalt aus `supabase/templates/recovery.html` | ☐ | ☐ |
| 9 | Authentication → Emails → SMTP Settings | Google-Konto der Sektion; App-Passwort nur hier eintragen; Absendername „Vereins OS“ | ☑ | ☐ |

Die Mailvorlagen enthalten nur einen kurzen Hinweistext und den Link, keine Personendaten.

### SMTP (TEST und PROD)

- Versand der Login-Mails über das Google-Konto der Sektion (Gmail-SMTP: `smtp.gmail.com`, Port 465 oder 587).
- Benutzer ist die Adresse des Google-Kontos; als Passwort dient ein **App-Passwort** des Google-Kontos. Es wird nur im Dashboard (Authentication → Emails → SMTP Settings) eingetragen, nie im Repo, in `config.toml` oder in `.env.local`.
- Absendername „Vereins OS“, Absenderadresse die Adresse des Google-Kontos.
- Supabase begrenzt Auth-Mails mit eigenem SMTP; eingestellt sind 30 je Stunde (Checkliste Punkt 4).

## 2. Ersteinrichtung PROD (US-AD-01)

1. **Migrationen und Edge Functions nach PROD bringen.** Wie das geschieht, ist noch offen: [OFFEN] O1 (manuell oder per GitHub Action beim Merge auf `main`, spec.md Abschnitt 11).
2. **Auth-Einstellungen** nach der Checkliste in Abschnitt 1 für PROD setzen.
3. **Einrichtungsskript ausführen** (psql, z. B. über `brew install libpq`):

   ```sh
   psql "<PROD-Verbindung>" -v ON_ERROR_STOP=1 \
     -v admin_first='<Vorname>' -v admin_last='<Nachname>' \
     -v admin_email='<login>@dav-leipzig.de' \
     -f supabase/setup/prod-bootstrap.sql
   ```

   Ergebnis: Person Admin mit Zugang (Vorlagen Admin und Vorstand) und Funktionsperson „Geschäftsstelle / Notfall-Admin“ mit Zugang `geschaeftsstelle@dav-leipzig.de` (Vorlage Admin), beide im Status „kein Zugang“. Mehrfaches Ausführen legt nichts doppelt an. Das Skript bricht ab, wenn `ad_test_login_domains` Einträge hat.
4. **Erste Einladung über das Dashboard:** Authentication → Users → „Invite user“ mit der Login-Adresse des Admins. In `ad_accesses` wechselt der Status auf „eingeladen“.
5. **Zustellungstest (US-AD-01 AK5):** Die Einladung muss im Posteingang liegen, nicht im Junk-Ordner und nicht in der Quarantäne. Passwort über den Link setzen; der Status wechselt auf „aktiv“. Danach auf der Login-Seite „Passwort vergessen“ auslösen; auch diese Mail muss im Posteingang liegen.
6. **Notfall-Admin einladen:** in AD über „Einladen“ bei der Funktionsperson (US-AD-08).

## 3. GitHub-Secret für die Datenbanktests

Die Action `.github/workflows/db-tests.yml` braucht das Repository-Secret `SEED_TEST_PASSWORD` (Passwort der fiktiven Testzugänge im lokalen Stack). Anlegen: GitHub → Repository → Settings → Secrets and variables → Actions → „New repository secret“, Name `SEED_TEST_PASSWORD`.
