# Übergabe an Gruppen: EZ-Rechte aus dem Nachtrag v0.8 der Administration

Stand: 24.10.2026 · Version 1.0 · Von: Administration (AD) · An: Gruppen (GR) · Status: offen
Quelle: specs/ad-administration/spec.md v0.9.5 (Nachtrag v0.8.2), tasks.md Phase 15 (T111–T118), Pull Request „AD Nachtrag v0.8“ (Migrationen `20261026000100`–`0400`); specs/gr-gruppen/plan.md O2 und Übergabe GR → AD v1.0 Ü5
Änderungen v1.0: Erste Fassung.

## Anlass

Gruppen hat die EZ-Pfade von `gr_group_roster` und `gr_groups_for_attendance` umgesetzt, bevor es das Modul EZ gab (GR plan.md O2, Variante b). Die Tests dafür laufen in `supabase/tests/database/480_gr_read_functions.test.sql` als pgTAP-`todo`. Mit dem Nachtrag v0.8 der Administration gibt es jetzt:

- das Modul EZ in `ad_modules` (`is_available = false`),
- die Startwerte EZ: Admin lesen, Geschäftsstelle verwalten, Referent:in bearbeiten mit Reichweite Referat, Vorstand ohne,
- die Reichweite „Referat“ für EZ (R30); `ad_my_referate('EZ', …)` liefert die Referate der Zuweisung.

Damit ist Ü5 der Übergabe aus Gruppen an die Administration erfüllt.

## Anforderungen

| Nr | Anforderung | Grund |
|---|---|---|
| G1 | In `480_gr_read_functions.test.sql` die Zeile `select todo('O2: EZ-Rechte (Modul EZ, Reichweite Referat) fehlen bis AD v0.8', 4);` entfernen. Die vier Tests (Rita: Klettergruppe; Kim: Test 1; Kim: Gruppen ihres Referats; Rita: Klettergruppe) laufen mit den Migrationen der Administration bereits durch (lokal geprüft am 24.10.2026). | Die EZ-Pfade sind dann regulär abgesichert. |
| G2 | GR plan.md O2 als erledigt kennzeichnen und den Kommentar zu Kim Kinderjugend in `supabase/seed.sql` („EZ-Rechte folgen mit AD v0.8“) anpassen. Kim erhält die EZ-Rechte über die Vorlage Referent:in (Referat Kinder und Jugend). | Stand der Dokumentation. |
| G3 | Zur Kenntnis: `ea_create_volunteer` hat seit dem Nachtrag eine neue Signatur mit `p_contact_email text default null`; die Fassung mit sieben Parametern gibt es nicht mehr. Aufrufe mit benannten Parametern bleiben gültig. Gruppen ruft die Funktion heute nicht auf. | Falls Gruppen sie später nutzt. |

## Voraussetzung

Der Pull Request „AD Nachtrag v0.8“ ist auf `main` gemergt. Vorher schlagen G1 und G2 fehl.
