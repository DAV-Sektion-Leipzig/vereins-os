# Übergabe an die Administration: Rechte, Personen und Orte für die Anwesenheitserfassung

Stand: 22.10.2026 · Version 1.3 · Von: Anwesenheitserfassung (EZ) · An: Administration (AD) · Status: **erledigt (eingearbeitet am 22.10.2026)**
Quelle: specs/ez-einsaetze/00-steckbrief.md (v0.6), 01-erhebung.md (v0.2)
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

## Folgen für die Anwesenheitserfassung

- Die erste Migration der Anwesenheitserfassung ersetzt `ez_person_visible` mit derselben Signatur und setzt `ad_modules.is_available` für EZ erst mit der Freigabe.
- Namen von Personen nur über `ea_person_names`, `ea_search_active_persons` und `gr_group_roster`; nie direkt aus `ea_persons`.
- Neue Personen beim Arbeitseinsatz über `ad_find_similar_persons` und `ea_create_volunteer` (`created_in = 'EZ'`).

## Offene Punkte

- [OFFEN] Eigene Vorlage für Trainer:innen oder dieselbe wie Gruppenleitung? (Iteration 1)
- [OFFEN] Startbestand der Orte; Pflege auch durch die Geschäftsstelle?
- Neue Annahmen der Administration v0.8 (Abschnitt 11) vom Product Owner zu bestätigen.
- Erledigt (v1.1): Admin liest die Anwesenheitserfassung.
