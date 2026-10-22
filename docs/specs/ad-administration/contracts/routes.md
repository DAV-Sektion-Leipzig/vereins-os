# Contract: Routen und Routenschutz

Stand: 22.10.2026 · Routen, Inhalte und Texte: [spec.md](../spec.md) Abschnitt 6, Umfang Kern bis v0.7.1 (ohne /ad/orte und /ad/saetze). Hier nur Schutz und Datenquelle.

| Route | Schutz | Datenquelle | Task |
|---|---|---|---|
| /login | öffentlich; mit Sitzung → / | `auth.signInWithPassword` | T13 |
| /passwort-vergessen | öffentlich | `auth.resetPasswordForEmail(email, { redirectTo })` | T13 |
| /passwort-setzen | öffentlich, erwartet `token_hash` + `type` | R19 prüfen (Länge, Übereinstimmung) → `auth.verifyOtp` → `auth.updateUser` | T13 |
| / | Sitzung | `ad_me`, `ad_my_modules` | T14 |
| /kein-zugriff | Sitzung | – | T12 |
| /ad | Sitzung + `AD ≥ read` | `ad_v_person_overview`, `ad_pending_emergency_logins` | T15 |
| /ad/personen/neu | wie /ad; Speichern nur AD ≥ edit | `ad_find_similar_persons`, Insert `ea_persons`, `ad_accesses` | T16, T49 |
| /ad/personen/:id | wie /ad | siehe [database-api.md](database-api.md) | T17–T19, T44, T47 |
| /ad/rechtevorlagen, /ad/rechtevorlagen/neu, /ad/rechtevorlagen/:id | wie /ad | `ad_templates`, `ad_template_rights`, `ad_modules` | T20, T44 |
| /ad/eigenschaftsarten, /ad/eigenschaftsarten/neu, /ad/eigenschaftsarten/:id | wie /ad | `ea_property_types`, `ea_property_fields`, `ea_save_property_type` | T46 |
| /ad/qualifikationsarten, /ad/qualifikationsarten/neu, /ad/qualifikationsarten/:id | wie /ad; Bearbeiten nur bei `ad_can_edit_qualification_types()` | `ad_qualification_types`, `ad_qualification_usage` | T30 |
| /ad/protokoll | wie /ad | `ad_audit_log` | T22 |
| /ea/qualifikationsarten* | `ad_has_any_level('EA','read')` und EA = manage; aktiv erst, wenn EA verfügbar ist (`ad_modules.is_available`) | dieselben Komponenten wie unter /ad | mit EA |

- Ohne Sitzung → /login (US-AD-02 AK5). /ad/* ohne `AD ≥ read` → /kein-zugriff, bevor Daten abgefragt werden (US-AD-05 AK3).
- Abmelden: `auth.signOut()` → /login (US-AD-02 AK4).
- Navigation AD: Personen · Rechtevorlagen · Eigenschaftsarten · Qualifikationsarten · Protokoll.
- Schreibende Aktionen (Buttons) werden nur bei `AD ≥ edit` angezeigt; die Datenbank prüft unabhängig davon.
- Kopfzeile: „Vereins OS“ (→ /), Modulname, Name des Nutzers (über `ad_me()`, Rufname bevorzugt), „Abmelden“.
