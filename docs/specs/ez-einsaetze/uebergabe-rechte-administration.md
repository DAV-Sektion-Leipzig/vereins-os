# Übergabe an die Administration: Rechte, Personen und Orte für die Anwesenheitserfassung

Stand: 24.10.2026 · Version 1.5 · Von: Anwesenheitserfassung (EZ) · An: Administration (AD) · Status: **offen (A9)**; A1–A8 erledigt (eingearbeitet am 22.10.2026)
Quelle: specs/ez-einsaetze/00-steckbrief.md (v0.6), 01-erhebung.md (v0.2)
Änderungen v1.5: A9 gilt auch referatsübergreifend (Product Owner 24.10.2026).
Änderungen v1.4: Nachtrag A9 – ruhende und ausgeschiedene Personen beim Arbeitseinsatz direkt wieder aktiv eintragen (Product Owner 24.10.2026; spec.md EZ v0.3 R31). Widerspricht der Annahme bei `ea_activate_person` in spec.md AD v0.8 („aus der Anwesenheitserfassung … nicht reaktiviert“).
Änderungen v1.3: Als erledigt markiert. A1–A5 und A8 eingearbeitet in specs/ad-administration/spec.md v0.8 (R30 erweitert, R43–R45, Tabelle `ad_locations`, Funktionen `ez_person_visible`, `ea_person_names`, `ea_search_active_persons`, erweitertes `ea_create_volunteer`, Tasks T50–T58); A6–A7 dort in Abschnitt 11 für Iteration 1 vorgemerkt. Auf Wunsch des Product Owners direkt aus dem Chat Anwesenheitserfassung eingearbeitet.
Änderungen v1.2: A3 um die Suche über alle Aktiven (organisierende Person) erweitert; A8 Stammdaten Orte neu (Product Owner 22.10.2026).
Änderungen v1.1: Modulname Anwesenheitserfassung (vorher Einsätze); Admin erhält Startwert „lesen“.

## Anlass

Die Anwesenheitserfassung braucht Rechte je Referat, einen eigenen Sichtbarkeitspfad für Personen, das Anlegen von Aktiven aus einem Arbeitseinsatz und Stammdaten für Trainingsorte. Für Iteration 1 (Erfassung durch Gruppenleitungen und Trainer:innen) braucht es die Reichweite „Gruppe“.

## Anforderungen und Verbleib

| Nr | Anforderung (Kurzform) | Eingearbeitet in spec.md Administration v0.8 |
|---|---|---|
| A1 | Startwerte EZ: Admin lesen, Geschäftsstelle verwalten, Referent:in bearbeiten (Referat), Vorstand ohne Rechte | Abschnitt 2 `ad_template_rights`, Abschnitt 3 Matrix, T50 |
| A2 | Reichweite „Referat“ für EZ mit denselben Referaten der Zuweisung | R30, R31, `ad_assignment_referate`, T50 |
| A3 | Nur Namen sichtbar; Suche der organisierenden Person über alle Aktiven | Abweichende Umsetzung: kein RLS-Pfad, sondern `ez_person_visible` (Platzhalter, Inhalt durch die Anwesenheitserfassung) + `ea_person_names` + `ea_search_active_persons` (R44, T52) |
| A4 | Personen beim Arbeitseinsatz anlegen, Ehrenamtsstatus „aktiv“, Funktion Helfer:in, Dublettenwarnung | `ea_create_volunteer` erweitert, `ad_find_similar_persons` für EZ (R45, T53) |
| A5 | Testzugänge mit EZ-Startwerten | Abschnitt 9, T57, T58 |
| A8 | Stammdaten Orte, gepflegt vom Admin | `ad_locations`, R43, Screens /ad/orte, T51, T55 |
| A6 | Reichweite „Gruppe“ (Iteration 1) | Abschnitt 11, vorgemerkt |
| A7 | Rechtevorlage Gruppenleitung (Iteration 1) | Abschnitt 11, vorgemerkt |
| A9 | **Neu v1.4 (offen):** `ea_activate_person` um den Pfad der Anwesenheitserfassung erweitern, wie `ea_create_volunteer` (R45): erlaubt auch mit `ez_can_write(p_referat)` bzw. Schreibrecht EZ im Referat, wenn die Eigenschaftsart die Funktion (`system_key = 'function'`) mit Wert Helfer:in ist; Person mit Ehrenamtsstatus „ruhend“ oder „ausgeschieden“, auch wenn sie zuletzt in einem anderen Referat aktiv war (Product Owner 24.10.2026); setzt Status „aktiv“ mit Historie und legt die Funktion mit Bezug auf das Referat an. Aufruf aus `ez_reactivate_helper` (spec.md EZ v0.3). Die Annahme in spec.md AD v0.8 zu `ea_activate_person` („aus der Anwesenheitserfassung … nicht reaktiviert“) entfällt. | – (Nachtrag v0.8, vor T53) |

## Folgen für die Anwesenheitserfassung

- Die erste Migration der Anwesenheitserfassung ersetzt `ez_person_visible` mit derselben Signatur und setzt `ad_modules.is_available` für EZ erst mit der Freigabe.
- Namen von Personen nur über `ea_person_names`, `ea_search_active_persons` und `gr_group_roster`; nie direkt aus `ea_persons`.
- Neue Personen beim Arbeitseinsatz über `ad_find_similar_persons` und `ea_create_volunteer` (`created_in = 'EZ'`).

## Offene Punkte

- [OFFEN] Eigene Vorlage für Trainer:innen oder dieselbe wie Gruppenleitung? (Iteration 1)
- [OFFEN] Startbestand der Orte; Pflege auch durch die Geschäftsstelle?
- Neue Annahmen der Administration v0.8 (Abschnitt 11) vom Product Owner zu bestätigen.
- Erledigt (v1.1): Admin liest die Anwesenheitserfassung.
- Entschieden 24.10.2026 (Product Owner): A9 gilt auch referatsübergreifend – eine Referent:in darf eine Person reaktivieren, die zuletzt in einem anderen Referat aktiv war; die Person ist danach im Referat des Einsatzes aktiv (Funktion Helfer:in).
