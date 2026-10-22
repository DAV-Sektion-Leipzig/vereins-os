# Contract: Routen und Routenschutz EA

Stand: 22.10.2026 · Inhalte und Texte: [spec.md](../spec.md) Abschnitt 6. Hier stehen nur Schutz, Datenquelle und Task.

| Route | Schutz | Datenquelle | Spec-Task |
|---|---|---|---|
| /ea | Sitzung + `ad_has_any_level('EA','read')` → Weiterleitung /ea/aktive | – | T10 |
| /ea/aktive | wie /ea | `ea_volunteer_list`, `ea_referate`, `ea_gremien` (nur verwalten), `ad_qualification_types`, `ad_my_referate('EA','edit')` | T11 |
| /ea/aktive/neu | wie /ea; Knopf nur mit `ad_has_level('EA','edit')` oder eigenen Referaten | `ad_find_similar_persons`, `ea_create_volunteer`, `ea_activate_person` | T13 |
| /ea/aktive/:id | wie /ea | `ea_persons`, `ea_volunteer_status_history`, `ea_properties` (+ Arten, Felder, Historie), `ea_v_expiry`, `ea_volunteer_list` (Kennzeichen „ohne gültige Lizenz“) | T12, T14, T15 |
| /ea/ablauf | wie /ea; Export nur `ad_has_level('EA','manage')` | `ea_v_expiry`, `ea_volunteer_list` (Referate) | T16 |
| /ea/gremien | `ad_has_level('EA','manage')` | `ea_properties` (Art `committee`), `ea_gremien` | T17 |
| /ea/stammdaten | `ad_has_level('EA','manage')` | `ea_referate`, `ea_gremien` | T18 |
| /ea/eigenschaftsarten, /ea/eigenschaftsarten/:id | `ad_has_level('EA','manage')` | Komponenten der Administration (T46) | T19 |
| /ea/qualifikationsarten, /ea/qualifikationsarten/:id | `ad_has_level('EA','manage')` | Komponenten der Administration (T30) | T19 |

- Ohne Sitzung → /login. Ohne Recht → /kein-zugriff, **bevor** Personendaten abgefragt werden (US-EA-01 AK4, AK5).
- Navigation (A6): mit EA = verwalten: Aktive · Ablauf · Gremien · Eigenschaftsarten · Qualifikationsarten · Referate und Gremien; sonst: Aktive · Ablauf.
- Kachel auf der Startseite über `ad_my_modules()` (Administration). Sie erscheint erst mit `ad_modules.is_available = true` (T22).
- Schreibende Knöpfe nur, wenn schreibbar (`ea_property_writable` bzw. eigene Referate); die Datenbank prüft unabhängig davon.
- Neue Routen /ea/* ersetzen den Eintrag „/ea/qualifikationsarten*“ in [routes.md der Administration](../../ad-administration/contracts/routes.md) (dort „mit EA“).
