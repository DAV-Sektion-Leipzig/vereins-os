# Contract: Routen und Routenschutz EZ

Stand: 24.10.2026 · Inhalte und Texte: [spec.md](../spec.md) Abschnitt 6. Hier stehen nur Schutz, Datenquelle und Task.

| Route | Schutz | Datenquelle | Spec-Task |
|---|---|---|---|
| /ez | Sitzung + `ad_has_any_level('EZ','read')` | `ez_list_events`, `ea_referate`, `gr_groups_for_attendance` (Filter Gruppe) | T10 |
| /ez/neu | `ad_has_any_level('EZ','edit')` | `gr_groups_for_attendance`, `gr_my_groups`, `gr_group_roster`, `ad_locations`, `ea_referate`, `ad_my_referate('EZ','edit')`, `ea_search_active_persons`, `ez_save_event` | T11–T13, T15 |
| /ez/:id | wie /ez; Bearbeiten, Absagen, Stände nur mit `can_write`; Löschen nur mit `can_delete` | `ez_get_event`, `ea_person_names`, `ez_save_event`, `ez_cancel_event`, `ez_restore_event`, `ez_delete_event`, `ad_find_similar_persons`, `ez_create_helper`, `ez_reactivate_helper` | T14, T18 |
| /ez/:id/bearbeiten | wie /ez/neu und `can_write` des Einsatzes | wie /ez/neu, dazu `ez_get_event` | T14 |
| /ez/kletterhalle | `ad_has_any_level('EZ','edit') or ad_has_level('EZ','read')` (spec.md 6 Navigation: Bearbeiten oder Admin) | `ad_locations` (`has_climbing_points`), `ez_climbing_points_report` | T16 |

- Ohne Sitzung → /login. Ohne `ad_has_any_level('EZ','read')` → /kein-zugriff, **bevor** Daten abgefragt werden.
- Nicht lesbarer oder unbekannter Einsatz: „Einsatz nicht gefunden.“
- Navigation: Einsätze · Kontrolle Kletterhalle (nur mit `ad_has_any_level('EZ','edit')` oder Admin).
- Kachel „Anwesenheitserfassung“ auf der Startseite über `ad_my_modules()`; erscheint erst mit `ad_modules.is_available = true` (T17). Bis dahin ist /ez nur per direkter URL erreichbar (Vorschau).
- Mobil: Liste als Karten, Kontrollkästchen mit Trefferfläche ≥ 44 px, ab 375 px ohne horizontales Scrollen.
