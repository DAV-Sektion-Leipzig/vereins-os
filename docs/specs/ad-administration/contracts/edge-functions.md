# Contract: Edge Functions AD

Grundlage: [spec.md](../spec.md) v0.3 Abschnitt 4 und 7. Technik: [research.md](../research.md) R-07.

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
| `login_email` endet auf `@dav-leipzig.de` (R1) | 422 `AD_EMAIL_DOMAIN` |
| `login_email` keinem anderen Auth-Nutzer zugeordnet (R2) | 409 `AD_EMAIL_TAKEN` |
| mindestens eine wirksame Zuweisung (R17) | 422 `AD_NO_TEMPLATE` |
| Status ist `none` oder `invited` | 409 `AD_INVALID_STATUS` |

Ablauf:
1. Gibt es schon einen Auth-Nutzer mit abweichender E-Mail (R20), wird diese zuerst per `auth.admin.updateUserById` auf `login_email` gesetzt.
2. `auth.admin.inviteUserByEmail(login_email, { redirectTo: SITE_URL + '/passwort-setzen' })`.
3. Bei Erfolg: `ad_apply_invite` setzt Status `invited`, `last_invited_at`, `auth_user_id` und schreibt das Protokoll `invited`.

Schlägt der Mailversand fehl: 502 `AD_MAIL_FAILED`, es wird nichts geändert (US-AD-08 AK5).

## ad-access

Request: `{ "person_id": "<uuid>", "action": "lock" | "unlock" }`

| action | erlaubter Ausgangsstatus | Auth | Ergebnis | Protokoll |
|---|---|---|---|---|
| lock | `invited`, `active` | `ban_duration: '876000h'` | `locked`, `locked_at`, `locked_by` | `locked` |
| unlock | `locked` | `ban_duration: 'none'` | `active`, wenn ein Passwort gesetzt ist (`encrypted_password` nicht leer), sonst `invited` | `unlocked` |

Beim Sperren wird nichts gelöscht (US-AD-09 AK6).
