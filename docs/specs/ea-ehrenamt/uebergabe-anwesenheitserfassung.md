# Übergabe an die Anwesenheitserfassung: Information nach Art. 13 DSGVO beim Anlegen von Personen

Stand: 22.10.2026 · Version 1.0 · Von: Ehrenamtsmanagement (EA) · An: Anwesenheitserfassung (EZ) · Status: offen
Quelle: specs/ea-ehrenamt/01-erhebung.md v0.4 (F); specs/ez-einsaetze/uebergabe-ehrenamtsmanagement.md v1.3 (offener Punkt Art. 13 DSGVO); Entscheidung des Product Owners vom 22.10.2026

## Anforderungen

- **A1 – Bestätigung beim Anlegen einer Person im Arbeitseinsatz:** Im Dialog „Neue Person anlegen“ (Arbeitseinsatz, `ea_create_volunteer`) steht ein Pflicht-Häkchen: „Ich habe die Person über die Speicherung ihrer Daten informiert und auf die Datenschutzhinweise der Sektion hingewiesen.“ mit Link auf die Datenschutzhinweise. Ohne Häkchen ist „Anlegen“ nicht möglich; Meldung „Bitte bestätige, dass die Person informiert wurde.“ [ANNAHME: Wortlaut].
- **A2 – Text und Link:** liefert der Product Owner vor dem Start der Anwesenheitserfassung [OFFEN]. [ANNAHME] Der Link wird als Konfiguration im Frontend hinterlegt (keine Personendaten).
- **A3 – Nachweis:** [ANNAHME] Die Bestätigung wird nicht gespeichert; Nachweis ist „angelegt von / am“ (`created_by`, `created_at`) und die Pflicht in der Oberfläche. Falls ein gespeicherter Nachweis gewünscht ist, im Chat Anwesenheitserfassung entscheiden.

## Offene Punkte

- [OFFEN] Text des Hinweises und Link auf die Datenschutzhinweise der Sektion (Product Owner).

## Folgeänderungen in der Anwesenheitserfassung (durch den Chat Anwesenheitserfassung)

- Story zum Anlegen neuer Personen beim Arbeitseinsatz und Spec (Abschnitte 5, 6) ergänzen; offenen Punkt Art. 13 DSGVO im Steckbrief bzw. in der Spec als entschieden markieren.
- Nach dem Einarbeiten: diese Übergabe als erledigt markieren.
