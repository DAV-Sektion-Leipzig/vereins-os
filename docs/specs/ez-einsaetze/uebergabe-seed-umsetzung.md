# Übergabe: Seed der Anwesenheitserfassung und Tests anderer Module

Version 1.0 · Stand 24.10.2026 · von: Umsetzung Anwesenheitserfassung (Claude Code) · an: Product Owner; betrifft Administration, Ehrenamtsmanagement, Gruppen (Umsetzung)
Bezug: spec.md EZ v0.5 Abschnitt 9 und T8, plan.md O3, tasks.md T017/T018, Draft-PR #42 (Branch `ez-seed`)

## Anlass

spec.md Abschnitt 9 verlangt Testdaten in `supabase/seed.sql` mit Personen in den Gruppen des Seeds (Teilnahmen, Funktionen von Toni Muster und Rita Referentin, Trainingszeit Di 17:00–19:00 der Klettergruppe Test) und elf Einsätzen. Die Tests anderer Module prüfen den Seed mit exakten Zählern und Listen. Der Lauf von `db-tests` auf `ez-seed` (Run 40128060010) zeigt, welche Prüfungen sich dadurch ändern. Claude Code ändert diese Tests nicht (Code anderer Module).

Die EZ-Tests 510–590 sind davon unabhängig: Sie legen dieselben Daten mit denselben UUIDs in der Testtransaktion selbst an und laufen mit und ohne EZ-Seed.

## Betroffene Prüfungen (39 in 10 Dateien)

| Datei | Modul | Prüfungen | Ursache |
|---|---|---|---|
| `020_persons_rights.test.sql` | AD | 34 | Liste der sichtbaren Personen der Geschäftsstelle (neue Personen 33–49) |
| `100_persons_v07.test.sql` | AD | 5, 6, 21 | Ehrenamtsstatus und Historie (Personen 40, 49 aktiv) |
| `130_visibility.test.sql` | AD | 1, 5, 6, 7, 13 | Personenlisten je Pfad, Geburtsdatum-Lesbarkeit über die Liste |
| `170_person_overview.test.sql` | AD | 1, 6, 9 | Anzahl Personen, Gruppenbezug (Ü3) |
| `200_seed.test.sql` | AD | 1, 9, 18, 22, 24 | Personen 26 → 43, Eigenschaften 41 → 45, Statushistorie 13 → 15, `created_in = 'GR'` 10 → 27, Teilnahmen 5 → 20 |
| `340_ea_volunteer_list.test.sql` | EA | 1–4, 13, 17, 36, 37, 39, 40 | Liste der Aktiven, Sortierung, `total_count`, Seiten (Personen 40, 49) |
| `410_gr_groups.test.sql` | GR | 8 | Trainingszeiten der Klettergruppe Test (neu Di 17:00–19:00) |
| `420_gr_visibility.test.sql` | GR | 4, 5, 7, 14 | Pfad GR, Teilnahmen 5/4 |
| `470_gr_admin_objects.test.sql` | GR | 16 | Gruppenbezug je Person (Ü3, Ü4) |
| `480_gr_read_functions.test.sql` | GR | 2, 3, 6, 8, 9, 19 | Teilnahmen, Übersicht der Klettergruppe Test, Roster Test 1 heute |

## Vorschläge

- **(a) Getrennte Seed-Datei für TEST (Vorschlag):** Der EZ-Abschnitt kommt nach `supabase/seed-ez.sql`; `supabase/seed.sh` lädt ihn nur für vereins-os-test (z. B. Schalter `SEED_WITH_EZ=1`), nicht in CI. Die Tests anderer Module bleiben unverändert; die EZ-Tests brauchen den Seed nicht. Erfordert eine kleine Änderung an `seed.sh` (gemeinsame Infrastruktur, Freigabe durch dich).
- **(b) Tests anderer Module anpassen:** Die 39 Prüfungen werden an den erweiterten Seed angepasst, durch die jeweilige Umsetzung (Administration, Ehrenamtsmanagement, Gruppen) oder durch Claude Code nach deinem ausdrücklichen Auftrag. Aufwand höher; jede künftige Seed-Ergänzung wiederholt das Problem.
- **(c) Seed ohne Gruppendaten:** nur Einsätze mit vorhandenen Personen. Erfüllt spec.md 9 nicht (Teilnehmer:innen, Funktionen, Trainingszeit fehlen).

Bis zur Entscheidung bleibt PR #42 ein Entwurf; `db-tests` ist dort erwartungsgemäß rot.
