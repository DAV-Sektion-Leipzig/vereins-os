# Übergabe: Finanzen → Administration

Stand: 24.10.2026 · Version 1.0 · Status: offen · Von: Finanzen (FI) · An: Administration (AD)
Grundlage: docs/specs/fi-finanzen/00-steckbrief.md v0.1, 01-erhebung.md v0.1; spec.md AD v0.9 (Nachtrag v0.9, `ad_rates`, `ea_person_licenses`); querschnitt-administration.md v0.1 (P6, P7, P11, P14, Q2, Q6)
Änderungen v1.0: Erste Fassung.

## Anlass

Finanzen rechnet die Vergütung nach der Vergütungsordnung aus der Anwesenheitserfassung ab. Der Product Owner möchte die Tabelle aus Anhang 1 der Vergütungsordnung in der Administration konfigurieren und je Einsatz wählen, welche Vergütung gilt (24.10.2026). Finanzen pflegt keine eigenen Sätze (Übergabe TK → FI v1.3, Punkt 3). Die Umsetzung gehört in einen Nachtrag der Administration vor der ersten Migration von Finanzen; die Teile A1–A3 werden auch von der Anwesenheitserfassung gebraucht (Übergabe FI → EZ v1.0).

## Anforderungen

- **A1 – Abrechnungsarten mit Positionen (Anhang 1):** Stammdaten „Abrechnungsart“ (z. B. Trainingseinheiten; Kinder- und Jugendfahrten/Gruppenfahrten; Wettkampfbetreuung; Kurse; Mehrtageskurse/Führungstouren/Trainingslager; Gemeinschaftstour) mit Positionen (Einheit: Trainingseinheit, Tagessatz, Halbtagessatz, Satz je Tag, Lehreinheit, Organisationspauschale je Tag) und dem Satz je Rolle (Trainer:in, Helfer:in, ohne Rolle) als Verweis auf einen Schlüssel in `ad_rates`. Pflege nur durch den Admin (wie R46); „gültig ab“ bzw. Historie; kein Löschen, Status aktiv/inaktiv [ANNAHME]. Startbestand nach Übergabe EZ → FI v1.6, F3.
- **A2 – Vorbelegung je Einsatzart:** Je Einsatzart der Anwesenheitserfassung und eintägig/mehrtägig eine Abrechnungsart oder „keine Vergütung“, mit „gültig ab“; Pflege nur Admin. Startwerte nach F2 (Training → Trainingseinheiten; Tagesausflug, Mehrtagesfahrt → Fahrten; Ausbildungsfahrt mehrtägig, Trainingslager, Tour → Mehrtageskurse; Wettkampfbetreuung → Wettkampfbetreuung; Kurs → Kurse; Arbeitseinsatz → keine Vergütung). [OFFEN] Startwert eintägige Ausbildungsfahrt (Mehrtageskurse oder Fahrten).
- **A3 – Fehlende Satzschlüssel in `ad_rates`:** Der Startbestand v0.9 enthält nur die Schlüssel der Planungshilfe (`rTL`, `rTLh`, `rH`, `rHh`, `rOrg`, `rLE`). Ergänzen (Schlüssel [ANNAHME], Werte Stand Anhang 1, Gruppe `remuneration`): Trainingseinheit Trainer:in 6,00 € / Helfer:in 4,00 €; Fahrten Tagessatz 30,00 / 20,00 €, Halbtagessatz 15,00 / 10,00 €; Wettkampfbetreuung je Tag 50,00 / 40,00 €. Organisationspauschale (`rOrg`, 10,00 €) und Lehreinheit (`rLE`, 15,00 €) gemeinsam nutzen.
- **A4 – Steuerfreier Höchstbetrag:** Schlüssel in `ad_rates`, Gruppe `threshold`, mit „gültig ab“ (Q6, Product Owner 24.10.2026). Wert nach § 3 Nr. 26 EStG [OFFEN: aktueller Betrag, von der Schatzmeister:in zu bestätigen].
- **A5 – Abgabefristen der halbjährlichen Abrechnung:** Stammdaten mit „gültig ab“: Frist 1. Halbjahr (Tag und Monat, Start 31.07.), Frist 2. Halbjahr (Start 15.12.); Pflege nur Admin (Q6, Product Owner 24.10.2026). Form (eigene Tabelle oder `ad_rates` mit Einheit „Tag des Jahres“) legt die Administration fest [ANNAHME: eigene kleine Tabelle, weil Datumswerte].
- **A6 – Kennzeichen am Referat:** „halbjährliche Abrechnung“ (ja/nein) an `ea_referate`, Startwert ja für Kinder und Jugend und Leistungssport, sonst nein [ANNAHME: Kennzeichen statt fester Liste im Code]; Pflege wie die Referate.
- **A7 – Modul FI in `ad_modules`:** Startwerte nach rollen.md 5: Geschäftsstelle verwalten; Admin, Referent:in, Vorstand kein Zugriff. Reichweite im MVP nur „alle“. `ad_can_read_rates()` enthält FI bereits (v0.9). Die eigene Aktion „freigeben“ (Q1) wird im MVP nicht gebraucht (Freigabe ist Teil von „verwalten“) [ANNAHME]; später für Schatzmeister:in.
- **A8 – Lesefunktion Personendaten für Finanzen (P7, Product Owner 24.10.2026):** Funktion mit festen Spalten, erlaubt mit FI ≥ lesen (Reichweite alle), unabhängig von Rechten auf das Ehrenamtsmanagement, z. B. `ea_person_finance_data(p_person_ids uuid[], p_date date)` [ANNAHME: Name]: Kontoinhaber:in und IBAN (`bank_account`), Datum Trainervereinbarung (`trainer_agreement`), Jahre mit Bestätigung steuerfreie Einnahmen (`tax_free_confirmation.year` mit Abgabedatum), förderfähige Lizenzen (Qualifikationsart, gültig von = Erwerb, gültig bis, förderfähig) auch in der Vergangenheit (Prüfung für das Halbjahr). Keine Lizenznummer, keine anderen Eigenschaften; nur Menschen; auch ausgeschiedene Personen, solange eine Abrechnung offen ist [ANNAHME]. Höchstzahl IDs wie `ea_person_licenses`.
- **A9 – Namen für Finanzen (Q2):** `ea_person_names` um `fi_person_visible` erweitern (Platzhalter `false`, gleiche Signatur; Finanzen ersetzt ihn): Personen mit einer Abrechnung oder einer abrechenbaren Anwesenheit.
- **A10 – Auftraggeberkonto der Sektion für SEPA:** [OFFEN] Ort der Pflege (Vorschlag: Einstellung in der Administration, nur Admin; Name, IBAN, BIC). Keine Secrets; die IBAN der Sektion ist keine Personenangabe, steht aber nicht im Repository.

## Offene Punkte

- [OFFEN] Startwert eintägige Ausbildungsfahrt (A2).
- [OFFEN] Betrag des steuerfreien Höchstbetrags (A4).
- [OFFEN] Ort der Pflege des Auftraggeberkontos (A10).

## Einarbeitung

- [ ] eingearbeitet in Administration (Datei, Version): –
