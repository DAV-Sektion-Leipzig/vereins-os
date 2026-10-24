# Contract: Routen und Routenschutz GR

Stand: 24.10.2026 · Inhalte und Texte: [spec.md](../spec.md) Abschnitt 6. Hier stehen nur Schutz, Datenquelle und Task.

| Route | Schutz | Datenquelle | Spec-Task |
|---|---|---|---|
| /gr | Sitzung + `ad_has_level('GR','read')` | `gr_group_overview`, `ea_referate` | T11 |
| /gr/aufnahmen | wie /gr; Aktionen nur mit edit | `gr_v_pending_admissions`, `gr_cancel_admission` | T14 |
| /gr/gruppen/neu | `ad_has_level('GR','edit')` | `ea_referate` (aktiv), `gr_save_group`, `gr_add_training_time` | T12 |
| /gr/gruppen/:id | wie /gr; Bearbeiten-Knöpfe nur mit edit, „Teilnehmer:in aufnehmen“ nur mit manage | `gr_groups`, `gr_training_times`, `gr_v_memberships`, `ea_properties` (Art `group_function`, `related_group_id`), `gr_guardian_emails`; Schreiben über die Funktionen aus 2.3 | T12, T13, T16 |
| /gr/gruppen/:id/aufnehmen | edit; neue Person nur mit manage | `ea_v_persons` (Suche), `ad_find_similar_persons`, `gr_start_admission`, `gr_add_guardian`, `gr_copy_address`, `gr_add_emergency_contact`, `gr_set_photo_consent`, `gr_set_health_consent`, `gr_save_health_note`, `gr_admit` | T14 |
| /gr/personen/:id | wie /gr; Abschnitt Gesundheit nur mit edit; Geburtsdatum-Eingabe nur mit manage | `ea_persons`, `ea_properties`, `gr_guardians`, `gr_emergency_contacts`, `gr_v_memberships`, `gr_contracts`, `gr_photo_consents`, `gr_health_consents`, `gr_health_notes`, `gr_health_note_history`, `gr_needs_guardian` | T15 |

- Ohne Sitzung → /login. Ohne `ad_has_level('GR','read')` → /kein-zugriff, **bevor** Daten abgefragt werden (spec.md 3, US-GR-01).
- Unbekannte oder nicht sichtbare Gruppe bzw. Person: „Gruppe nicht gefunden.“ bzw. Leerzustand der Seite, ohne Hinweis darauf, ob es die Person gibt.
- Navigation: Gruppen · Aufnahmen offen.
- Kachel auf der Startseite über `ad_my_modules()`; sie erscheint erst mit `ad_modules.is_available = true` (T19).
- Mobil (US-GR-14): /gr → Gruppe → Kind; Notfallkontakte oben auf /gr/personen/:id; Telefon als `tel:`, E-Mail als `mailto:`; Trefferflächen ≥ 44 px.
- Ehrenamtsmanagement (T17): /ea/aktive/:id zeigt Funktionen in Gruppen nur lesend mit Gruppenname aus `gr_groups` (Policy mit `ad_has_any_level('EA','read')`) und dem Text „Diese Angabe wird im Modul Gruppen gepflegt.“
