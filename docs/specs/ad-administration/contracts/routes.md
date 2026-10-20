# Contract: Routen und Routenschutz

Routen, Inhalte und Texte: [spec.md](../spec.md) v0.5 Abschnitt 6. Hier nur Schutz und Datenquelle.

| Route | Schutz | Datenquelle | Task |
|---|---|---|---|
| /login | öffentlich; mit Sitzung → / | `auth.signInWithPassword` | T13 |
| /passwort-vergessen | öffentlich | `auth.resetPasswordForEmail(email, { redirectTo })` | T13 |
| /passwort-setzen | öffentlich, erwartet `token_hash` + `type` | R19 prüfen (Länge, Übereinstimmung) → `auth.verifyOtp` → `auth.updateUser` | T13 |
| / | Sitzung | `ad_me`, `ad_my_modules` | T14 |
| /kein-zugriff | Sitzung | – | T12 |
| /ad, /ad/** | Sitzung + `AD ≥ read` (sonst /kein-zugriff, keine Datenabfrage) | siehe [database-api.md](database-api.md) | T15–T22 |

- Ohne Sitzung → /login (US-AD-02 AK5).
- Abmelden: `auth.signOut()` → /login (US-AD-02 AK4).
- Schreibende Aktionen (Buttons) werden nur bei `AD ≥ edit` angezeigt; die Datenbank prüft unabhängig davon.
- Kopfzeile: „Vereins OS“ (→ /), Modulname, Name des Nutzers (über `ad_me()`), „Abmelden“.
