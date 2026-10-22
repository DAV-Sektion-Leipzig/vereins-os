# Übergabe: Anforderungen aus der Spec Gruppen an die Administration

Stand: 22.10.2026 · Version 1.0 · Von: Gruppen (GR) · An: Administration (AD) · Status: offen
Quelle: specs/gr-gruppen/spec.md v0.2 (Ready) (Abschnitte 2.3, 7, 10, 11)
Grundlage: specs/ad-administration/spec.md v0.9 (Kern bis v0.7.1) mit Ü2 aus specs/ea-ehrenamt/uebergabe-administration.md

Diese Datei ersetzt keine gemeinsame Datei. Sie wird im Chat der Administration in spec.md AD eingearbeitet und danach als erledigt markiert. Reicht die Zeit nicht, darf Claude Code Ü1–Ü3 als vorgezogene Tasks der ersten GR-Migration aus dieser Übergabe umsetzen (wie T0a/T0b beim Ehrenamtsmanagement).

## Anforderungen

| Nr | Anforderung | Grund | Ort in spec.md AD |
|---|---|---|---|
| Ü1 | Interne Funktion `ea_set_status_from_group(p_person uuid, p_valid_from date)` – security definer, `revoke execute from public, authenticated` (nur aus Security-Definer-Funktionen desselben Eigentümers aufrufbar): setzt `volunteer_status = 'active'` mit `volunteer_status_since = p_valid_from` und Historie in `ea_volunteer_status_history`, **nur wenn** `volunteer_status is null` und `kind = 'human'`; sonst ohne Änderung. Der Trigger auf `ea_persons` lässt diese Funktion zu (wie `ea_set_volunteer_status`, `ea_create_volunteer`, `ea_activate_person`). | Gruppen setzt „aktiv“ für Gruppenleitung, Trainer:in, Helfer:in ohne Status (R29 Gruppen; Entscheidung Product Owner 22.10.2026). Die vorhandenen Funktionen gehen nicht: `ea_set_volunteer_status` verlangt Sichtbarkeit im Pfad EA, `ea_activate_person` EA bearbeiten und eine Zuordnung zu einem Referat. | Abschnitt 2 Funktionen „Ehrenamtsstatus und Anlegen“; Abschnitt 4 Tabelle Ehrenamtsstatus (Zeile „GR setzt aktiv“ von [ANNAHME] auf entschieden); T37/T39 |
| Ü2 | Dublettendialog (R3): Aktion für Gruppen „Vorhandene Person übernehmen“ – auch für **nicht sichtbare** Treffer, wenn der Nutzer GR ≥ bearbeiten hat. Die Übernahme macht die Person über eine Gruppen-Funktion im Pfad GR sichtbar. | Entscheidung Product Owner 22.10.2026; vermeidet Dubletten (E1). Folge: Kontaktdaten der übernommenen Person werden für Nutzer mit „Gruppen lesen“ sichtbar (Verarbeitungsverzeichnis). | R3; Komponente Dublettendialog (T49) |
| Ü3 | `ad_v_person_overview`: „Gruppenbezug ja/nein“ über `gr_has_current_relation(person_id)` (legt Gruppen an; ohne Rechteprüfung, nur Ja/Nein); bis zur ersten GR-Migration wie bisher `created_in = 'GR'`. Filter „nur Gruppen“ = Gruppenbezug und kein Ehrenamtsstatus und kein Zugang. | `gr_person_visible` prüft Rechte des Aufrufers und zählt nur laufende Bezüge; die Übersicht braucht ein reines Kennzeichen. | Abschnitt 2 Views; T44/T46 |
| Ü4 | Hinweis zur Sichtbarkeit: `gr_person_visible` zählt nur **laufende** Bezüge (offene Aufnahme, laufende Teilnahme, nicht beendeter Vertrag, Erziehungsberechtigung/Notfallkontakt eines solchen Kindes, nicht beendete Funktion in Gruppe). Personen mit nur beendeten Bezügen sind nur über den Pfad AD sichtbar. | Entscheidung Product Owner 22.10.2026 | Abschnitt 2 „Sichtbarkeit“ (Beschreibung des Platzhalters), Abschnitt 3 Tabelle Lesepfade |
| Ü5 | Reihenfolge: Für US-GR-19/20 (`gr_group_roster`, `gr_groups_for_attendance`) müssen aus dem Nachtrag v0.8 mindestens T50 (Modul EZ in `ad_modules`, Startwerte EZ) und die Reichweite „Referat“ für EZ (R30, `ad_my_referate('EZ', …)`) **vor** der Umsetzung von Gruppen T8 umgesetzt sein, nicht erst vor der ersten Migration der Anwesenheitserfassung. | Gruppen wird vor der Anwesenheitserfassung umgesetzt; die Lesefunktionen prüfen EZ-Rechte. | Hinweis zum Umsetzungsstand; Abschnitt 10 |
| Ü6 | Hinweis Seed: Gruppen ergänzt einen Testzugang „Kim Kinderjugend“ (test.kiju@dav-leipzig.de, Vorlage Referent:in, Referat Kinder und Jugend) und Personen 23–32 im Seed (spec.md GR Abschnitt 9). Keine Änderung an Personen 1–22. | US-GR-17 AK5 (Roster für Referent:in Kinder und Jugend) | Abschnitt 9 (nur Hinweis) |
| Ü7 | Präzisierung R38/R39 (bereits der GR-Migration zugewiesen, zur Kenntnis): `ea_properties_validate` prüft bei `relation_kind = 'group'` `related_group_id`; Eigenschaften mit Bezug auf eine Gruppe schreiben Nutzer nur über Funktionen von Gruppen (`ea_property_writable` liefert für diese Arten false). Die GR-Migration ändert dazu `ea_property_writable` per `create or replace` mit gleicher Signatur. | Schreiben über RLS scheitert, weil die Person erst mit der neuen Zeile im Pfad GR sichtbar wird. | Abschnitt 2 ea_properties, R39 |

## Tests (pgTAP in der Administration oder in Gruppen T10)

- `ea_set_status_from_group` ist für `authenticated` nicht ausführbar; über `gr_add_group_function` setzt sie „aktiv“ bei Person ohne Status, ändert „ruhend“ und „ausgeschieden“ nicht.
- Dublettentreffer ohne Sichtbarkeit: mit GR bearbeiten übernehmbar, mit nur GR lesen nicht.
- `ad_v_person_overview` zeigt für Admin Gruppenbezug bei Personen mit laufendem Bezug.
