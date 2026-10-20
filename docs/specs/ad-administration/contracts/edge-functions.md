# Contract: Edge Functions AD

Grundlage: [spec.md](../spec.md) v0.5 Abschnitt 4 und 7. Technik: [research.md](../research.md) R-07.

## Für beide Functions

- Methode `POST`, `Content-Type: application/json`, Header `Authorization: Bearer <JWT des Aufrufers>`.
- CORS: erlaubt sind die Redirect-Adressen aus `supabase/config.toml` (PROD, Vorschau, lokal).
- Zuerst wird das Recht geprüft: `ad_has_level('AD','edit')` im Kontext des Aufrufers. Ohne dieses Recht passiert nichts weiter.
- Antwort bei Erfolg: `200 { "status": "<ad_access_status>", "last_invited_at"?: "<ISO>" }`.
- Antwort bei Fehler: `{ "code": "<FEHLERCODE>" }`. Codes und Meldungen: [error-codes.md](error-codes.md).

| HTTP | code | wann |
|---|---|---|
| 400 | `AD_BAD_REQUEST` | Request ungültig |
| 401 | `AD_UNAUTHENTICATED` | kein oder ungültiges JWT |
| 403 | `AD_FORBIDDEN` | Aufrufer hat nicht AD ≥ edit (US-AD-08 AK6, US-AD-09 AK5) |
| 404 | `AD_PERSON_NOT_FOUND` | `person_id` unbekannt |
| 409 | `AD_INVALID_STATUS` | Übergang aus dem aktuellen Status nicht erlaubt |
| 500 | `AD_UNEXPECTED` | sonst |

## ad-invite

Request: `{ "person_id": "<uuid>" }`

| Vorbedingung | Fehler |
|---|---|
| Zeile in `ad_accesses` mit `login_email` vorhanden | 422 `AD_EMAIL_MISSING` |
| `ad_login_email_allowed(login_email)` (R1; in TEST zusätzlich Domains aus `ad_test_login_domains`) | 422 `AD_EMAIL_DOMAIN` |
| `login_email` keinem anderen Auth-Nutzer zugeordnet (R2) | 409 `AD_EMAIL_TAKEN` |
| mindestens eine wirksame Zuweisung (R17) | 422 `AD_NO_TEMPLATE` |
| Status ist `none` oder `invited` | 409 `AD_INVALID_STATUS` |

Ablauf:
1. Ausgangsstand merken: `status`, `auth_user_id`, `last_invited_at`.
2. `auth.admin.inviteUserByEmail(login_email, { redirectTo: SITE_URL + '/passwort-setzen' })`.
3. Bei Erfolg: `ad_apply_invite` setzt Status `invited`, `last_invited_at` und `auth_user_id` und schreibt das Protokoll `invited`.

Bei einem Fehler der Auth-Admin-API, z. B. beim Mailversand (US-AD-08 AK5):
1. Gibt es jetzt einen Auth-Eintrag mit `login_email`, der vor dem Aufruf nicht da war (Ausgangsstand ohne `auth_user_id`), wird er mit `auth.admin.deleteUser` gelöscht.
2. `ad_revert_invite` stellt Status, `auth_user_id` und `last_invited_at` auf den Ausgangsstand zurück. Ein Protokolleintrag entsteht nicht.
3. Antwort: 502 `AD_MAIL_FAILED`.

Dieses Verhalten gilt unabhängig davon, ob Supabase Auth bei SMTP-Fehlern einen Eintrag anlegt. Abgesichert ist es durch einen Deno-Test mit simuliertem Fehler (Auth-Admin-Client als austauschbare Abhängigkeit, T9).

## ad-access

Request: `{ "person_id": "<uuid>", "action": "lock" | "unlock" | "change_email", "login_email"?: "<adresse>" }` (`login_email` nur bei `change_email`, sonst 400 `AD_BAD_REQUEST`)

| action | erlaubter Ausgangsstatus | Auth | Ergebnis | Protokoll |
|---|---|---|---|---|
| lock | `invited`, `active` | `ban_duration: '876000h'` | `locked`, `locked_at`, `locked_by` | `locked` |
| unlock | `locked` | `ban_duration: 'none'` | `active`, wenn ein Passwort gesetzt ist (`encrypted_password` nicht leer), sonst `invited` | `unlocked` |
| change_email | `invited` (sonst 409 `AD_EMAIL_LOCKED`) | prüft R1 über `ad_login_email_allowed` (`AD_EMAIL_DOMAIN`), R2 (`AD_EMAIL_TAKEN`); `auth.admin.deleteUser(auth_user_id)` | `ad_apply_email_change`: neue `login_email`, `auth_user_id` null, Status `none`; Antwort `200 { "status": "none", "code": "AD_EMAIL_CHANGED" }` | `email_changed` (Details: alte → neue Adresse) |

Beim Sperren wird nichts gelöscht (US-AD-09 AK6). `change_email` löscht nur den Auth-Eintrag einer noch nicht aktivierten Einladung; der alte Link ist damit ungültig (US-AD-03 AK7). Bei Status `none` ändert die Oberfläche die Login-Adresse direkt in `ad_accesses`.
