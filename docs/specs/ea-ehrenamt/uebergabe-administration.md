# Übergabe an die Administration: Bezeichnungen „gültig von/bis“, Geburtsjahr in der Dublettenwarnung, Seed

Stand: 22.10.2026 · Version 1.1 · Von: Ehrenamtsmanagement (EA) · An: Administration (AD) · Status: offen
Quelle: specs/ea-ehrenamt/01-erhebung.md v0.5 (C2, C2a, F), 02-stories.md v0.1 (US-EA-19); Entscheidungen des Product Owners vom 22.10.2026
Änderungen v1.1: Ü3 (Testarten im Seed gegenüber den System-Eigenschaftsarten) ergänzt.
Betrifft: Kern der Administration (spec.md AD v0.7.1, T35, T43, T46, T47, T49). Ü1 und Ü2 sind Ergänzungen ohne Umbau, günstig vor bzw. mit T35 und T43; Ü3 setzt das Ehrenamtsmanagement selbst um.

## Anforderungen

- **Ü1 – Bezeichnungen für „gültig von / gültig bis“ je Eigenschaftsart:**
  - `ea_property_types` erhält zwei Spalten: `valid_from_label text null`, `valid_to_label text null`; getrimmt, leer → null, höchstens 40 Zeichen (Check).
  - Formular der Eigenschaftsart (/ad/eigenschaftsarten/:id, T46): zwei optionale Eingaben „Bezeichnung für ‚gültig von‘“ und „Bezeichnung für ‚gültig bis‘“.
  - Eigenschaftsformular und Anzeige im Personendetail (T47, T19): verwenden die Bezeichnungen, sonst „gültig von“ bzw. „gültig bis“. Fehlermeldung „‚Gültig bis‘ darf nicht vor ‚gültig von‘ liegen.“ mit den jeweiligen Bezeichnungen [ANNAHME].
  - Rechte wie die übrigen Spalten der Eigenschaftsart. Kein Einfluss auf RLS.
  - Startwerte setzt die erste Migration des Ehrenamtsmanagements (01-erhebung.md C2a).
- **Ü2 – Geburtsjahr in der Dublettenwarnung nur für Geschäftsstelle und Admin:**
  - `ad_find_similar_persons` liefert `birth_year` nur, wenn der Aufrufer `ad_has_level('AD','read')` oder `ad_has_level('EA','manage')` oder `ad_has_level('GR','manage')` hat (entspricht Lesestufe „nur Geschäftsstelle und Admin“); sonst `null`.
  - R40 entsprechend ergänzen; Dublettendialog zeigt das Geburtsjahr nur, wenn geliefert.
  - pgTAP (T45): Referent:in Klettern erhält für „Toni Muster“ (Person 4) `birth_year = null`; Geschäftsstelle erhält 1990.
  - Grund: Das Geburtsdatum hat Lesestufe „nur Geschäftsstelle und Admin“; Referent:innen sollen es auch nicht teilweise sehen (DSGVO, Datensparsamkeit).
  - Hinweis: Gruppen (US-GR-06 AK2) nennt das Geburtsjahr in der Dublettenwarnung; mit GR = verwalten bleibt es sichtbar.

- **Ü3 – Seed und System-Eigenschaftsarten:** Die erste Migration des Ehrenamtsmanagements legt Eigenschaftsarten mit `system_key` `birth_date`, `function`, `position`, `contact`, `license`, `employment` u. a. an (01-erhebung.md C2). Der Seed der Administration (spec.md AD Abschnitt 9) legt Testarten mit `system_key = 'birth_date'` (Kern) bzw. `function`, `contact`, `license` (v0.8/v0.9) an; nach der EA-Migration verletzt das die Eindeutigkeit von `system_key`.
  - Lösung [ANNAHME]: Mit der ersten EA-Migration ändert das Ehrenamtsmanagement `supabase/seed.sql` so, dass die Testarten „Funktion (Test)“, „Amt (Test)“, „Lizenz (Test)“, „Geburtsdatum (Test)“, „Kontaktdaten (Test)“ und „Hauptamt“ entfallen und die Eigenschaften der Seed-Personen 2–12 (und 13–18, sobald v0.9 umgesetzt ist) auf die System-Eigenschaftsarten mit deren Feldschlüsseln verweisen (Auflösung über `system_key`). „T-Shirt-Größe“ und „Erste-Hilfe-Kurs am“ bleiben als Testarten.
  - Die erwarteten Ergebnisse in spec.md AD Abschnitt 9 (Sichtbarkeit, Namensfunktionen, Lizenzen) bleiben gültig; die pgTAP-Tests T45/T56/T65 laufen nach der Umstellung unverändert grün.
  - Bitte in spec.md AD Abschnitt 9 vermerken, dass die Testarten mit `system_key` nur bis zur ersten EA-Migration gelten.

## Offene Punkte

- keine

## Folgeänderungen in der Administration (durch den Chat der Administration)

- spec.md: Abschnitt 2 (`ea_property_types`), R40, Abschnitt 6 (Formulare), T35, T43, T45–T47 ergänzen; Annahme in Abschnitt 11.
- 02-stories.md: US-AD-22 (Eigenschaftsart) und US-AD-25 (Dublettenwarnung) um je ein Akzeptanzkriterium ergänzen.
- Nach dem Einarbeiten: diese Übergabe als erledigt markieren.
