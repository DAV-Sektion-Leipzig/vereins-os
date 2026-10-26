# Übergabe: Planungshilfe Touren und Kurse → Administration

Stand: 26.10.2026 · Version 1.8 · Status: eingearbeitet (26.10.2026) · Von: Planungshilfe Touren und Kurse (TK) · An: Administration (AD)
Änderungen v1.8: Punkt 16 neu: Anlegen und Reaktivieren von Aktiven aus der Planungshilfe (Product Owner 26.10.2026). Punkt 15 neu: Erwerbsdatum der Lizenz in `ea_person_licenses` (Trainersatz auch bei Erwerb im Halbjahr des Startdatums, wie Finanzen; Product Owner 26.10.2026). Hinweis: Punkte 9 und 11 (Modul TKF) sind durch Nachtrag v0.10 AD ersetzt (Aktion „darf freigeben“, Übergabe AD → TK `uebergabe-planungshilfe-freigabe.md`).
Änderungen v1.7: Eingearbeitet in spec.md Administration v0.9 (T59–T67) im Chat Planungshilfe Touren und Kurse (Product Owner 22.10.2026: Chat der Administration liegt in einem anderen Projekt).
Änderungen v1.6: Konkretisierung aus spec.md TK v0.1: Freigaberecht über zweites Modul TKF, Schlüssel der Sätze, Signatur von `ea_person_licenses` und `ad_rates_at`, Testzugänge.
Änderungen v1.5: Sätze und Pauschalen pflegt vorerst nur der Admin (Product Owner 22.10.2026).
Änderungen v1.4: Neue Stammdaten „Sätze und Pauschalen“ für Touren und Kurse in der Administration (Product Owner 22.10.2026).
Änderungen v1.3: Freigaberecht vergibt und entzieht der Admin (Product Owner 22.10.2026); offener Punkt zur Delegation erledigt.
Änderungen v1.2: Eigenes, delegierbares Freigaberecht für Touren und Kurse; Lizenz-Stichtag = Startdatum (Product Owner 22.10.2026).
Änderungen v1.1: Reichweite „Referat“ für TK mit den Referaten Touren und Ausbildung; Testzugang auch für Referat Ausbildung (Product Owner 22.10.2026).
Änderungen v1.0: Erste Fassung.

Grundlage: docs/specs/tk-touren-kurse/00-steckbrief.md v0.7, 01-erhebung.md v0.7, 02-stories.md v0.3, spec.md v0.1 (Abschnitte 3, 7, 9) (A, B3).

## Anforderungen an die Administration

1. Modul TK in `ad_modules` (Bezeichnung „Planungshilfe Touren und Kurse“), `is_available` erst mit Freigabe.
2. Reichweite „Referat“ auch für TK (wie für Ehrenamtsmanagement und Anwesenheitserfassung, R30).
3. Startwerte der Rechtevorlagen [ANNAHME]: Admin TK lesen; Geschäftsstelle TK verwalten; Referent:in TK bearbeiten mit Reichweite „Referat“; Vorstand ohne Rechte.
4. Namenssuche: `ea_search_active_persons` und `ea_person_names` auch für Nutzer mit TK-Rechten freigeben (nur Name, Status „aktiv“).
5. Neue Lesefunktion für Lizenzen ausgewählter Personen, z. B. `ea_person_licenses(p_person_ids uuid[], p_date date)` → je Person: Qualifikationsart (ID, Bezeichnung), gültig bis, förderfähig (DOSB-lizenzfähig), gültig am Datum; nur Lesestufe „alle mit Zugriff“, keine weiteren Eigenschaften; aufrufbar mit TK lesen [ANNAHME]. Betrifft Daten des Ehrenamtsmanagements; Funktion nach dem Muster v0.8 in AD.
6. Lesefunktion Kontaktdaten der Leitung (E-Mail, Mobilnummer) als Vorschlag, nur für TK bearbeiten [ANNAHME] – [OFFEN] ob nötig oder Eingabe je Planung genügt.
7. Testzugänge Referent:in mit Referat Touren und Referent:in mit Referat Ausbildung in TEST.
8. `ea_person_licenses` prüft „gültig am Datum“ taggenau („gültig bis“ ≥ Datum); TK übergibt das **Startdatum** der Tour bzw. des Kurses (Lizenz läuft während der Tour ab → Trainersatz für die ganze Tour).
9. Freigaberecht: Freigabe von Touren und Kursen liegt bei den Referent:innen und kann an andere Personen delegiert werden (Product Owner 22.10.2026). Vorschlag: eigene Rechtevorlage „Freigabe Touren und Kurse“ (TK, Aktion freigeben, Reichweite „Referat“), zusätzlich zur Vorlage Referent:in vergeben; Startwert: Referent:innen Touren und Ausbildung erhalten sie [ANNAHME]. Das Rechtemodell kennt bisher nur lesen/bearbeiten/verwalten – [OFFEN] eigene Aktion „freigeben“ im Modell oder Lösung über eine eigene Vorlage mit Prüfung in TK. Delegation: Das Freigaberecht vergibt und entzieht der Admin, auf Wunsch der Referent:in (Product Owner 22.10.2026; entspricht rollen.md); Protokoll der Vergabe wie bei anderen Rechtevorlagen.

10. **Stammdaten Sätze und Pauschalen** (Product Owner 22.10.2026: Pauschalen für Touren und Kurse im Administrationsteil bearbeitbar): Tabelle z. B. `ad_rates` mit Schlüssel, Bezeichnung, Gruppe (Vergütung, Reisekosten, Zahlungsgebühr, Emissionsfaktor, Grenzwert), Wert, Einheit, Quelle, gültig ab; je Schlüssel mehrere Zeilen mit unterschiedlichem „gültig ab“ (Historie), nie löschen. Zahlungsgebühren zusätzlich mit %, fix € und aktiv. Startbestand per Migration aus prototyp-tourenkonzept.md Abschnitt 5.1–5.3 und Grenzwerten 5.4 (ohne Stornoregel). Pflege: nur Admin (Recht „AD bearbeiten“) (Product Owner 22.10.2026); Geschäftsstelle oder Referent:innen können später ergänzt werden (Prüfung zentral in einer Funktion, z. B. `ad_can_edit_rates()`); lesen: alle Nutzer mit TK- oder FI-Rechten. Lesefunktion `ad_rates_at(p_date)` → gültige Werte zum Datum. Finanzen nutzt dieselbe Tabelle (Sätze der Vergütungsordnung). Prüfungen: Wert ≥ 0, kein doppeltes „gültig ab“ je Schlüssel.

11. **Umsetzung des Freigaberechts (Vorschlag spec.md TK Abschnitt 3):** zweites Modul `TKF` „Freigabe Touren und Kurse“ in `ad_modules` mit Kennzeichen „ohne Kachel/Seiten“ (z. B. `ad_modules.is_hidden = true`, `ad_my_modules` liefert es nicht); Reichweite „Referat“ für TKF; Rechtevorlage „Freigabe Touren und Kurse“ (TKF bearbeiten, Reichweite Referat). Die Planungshilfe prüft `ad_my_referate('TKF','edit')`. Alternative: neue Aktion „freigeben“ im Rechtemodell – Entscheidung in der Administration.
12. **Signaturen:** `ea_person_licenses(p_person_ids uuid[], p_date date) returns table(person_id uuid, qualification_type_id uuid, qualification_name text, valid_until date, is_fundable boolean, valid_on_date boolean)`, nur Typ Lizenz; aufrufbar mit TK lesen oder TKF; höchstens 50 IDs. `ad_rates_at(p_date date) returns table(rate_key text, label text, rate_group text, value numeric, unit text, percent numeric, fixed numeric, active boolean, valid_from date, source text)`.
13. **Schlüssel und Startbestand der Sätze:** Liste in spec.md TK Abschnitt 7 (Werte aus prototyp-tourenkonzept.md 5.1–5.4, gültig ab 01.01.2026 [OFFEN: echte Daten]).
14. **Testzugänge (Seed TEST):** Tina Touren (Referent:in Touren + Freigabe), Alex Ausbildung (Referent:in Ausbildung ohne Freigabe), Fritz Freigabe (nur Freigabe, Referat Touren); Aktive Bernd Berg (Trainer*in C Bergwandern, förderfähig, gültig bis 30.10.2027), Hilde Helfer (ohne Lizenz), Karl Kletter (Trainer*in C Sportklettern, bis 31.12.2025) (spec.md TK Abschnitt 9).

15. **Erwerbsdatum der Lizenz (neu v1.8, Product Owner 26.10.2026):** `ea_person_licenses` liefert zusätzlich `valid_from date` (Erwerbsdatum bzw. „gültig ab“ der Lizenz, gleiche Quelle wie `licenses` in `ea_person_finance_data`). Die Planungshilfe rechnet den Trainersatz auch, wenn die förderfähige Lizenz im Kalenderhalbjahr des Startdatums erworben wurde (spec.md TK v0.3 R2, gleiche Regel wie Finanzen R8). Deshalb liefert die Funktion auch Lizenzen, deren `valid_from` nach `p_date` liegt, sofern im selben Halbjahr; `valid_on_date` bleibt die taggenaue Prüfung. Gehört zu AD T62.
16. **Anlegen und Reaktivieren aus der Planungshilfe (neu v1.8, Product Owner 26.10.2026):** Externe Leitende werden direkt aus der Planung angelegt bzw. wieder aktiviert, wie beim Arbeitseinsatz der Anwesenheitserfassung (AD v0.8.2, R45, R45a), aufgerufen über `tk_create_leader` und `tk_reactivate_leader` (spec.md TK v0.3 R23). Nötig: `ea_create_volunteer` und `ea_activate_person` mit dem Pfad TK erlaubt, wenn der Aufruf über `ad_has_any_level('TK','edit')` mit dem Referat der Planung in der Reichweite erlaubt ist; Einschränkung auf `{"function":"Helfer:in"}`; `created_in = 'TK'` (neuer Wert im Check `created_in`; `'EA'`, wenn der Nutzer passende EA-Rechte hat, wie für EZ); `ad_find_similar_persons` für TK ≥ edit freigeben. Damit entfällt der Satz „Die Planungshilfe legt keine Personen an (v0.9)“ in spec.md AD Abschnitt 2. Gehört zu AD T62 bzw. einem neuen Task neben T53.

## Offen

- [OFFEN] Externe Leitende ohne Ehrenamtsstatus: Anlegen über `ea_create_volunteer` (`created_in = 'TK'`) wie beim Arbeitseinsatz?
- [OFFEN] Stammdaten „Qualifikationsart → Sportart“ (Hinweis „Qualifikation deckt Sportart ab“): in TK oder als Feld an der Qualifikationsart in AD?
- [OFFEN] Reichweite „nur eigene“ für Tourenleitende (spätere Iteration).

## Einarbeitung

- [x] Punkte 15 und 16 eingearbeitet in Administration: docs/specs/ad-administration/spec.md v0.12 (26.10.2026; R47a, R59, Signatur `ea_person_licenses`, `ea_create_volunteer`, `ea_activate_person`, `ad_find_similar_persons`).
- [x] eingearbeitet in Administration: docs/specs/ad-administration/spec.md v0.9 (22.10.2026) – Abschnitte 2 (ad_modules `is_hidden`, TK/TKF, ad_rates, `ad_rates_at`, `ea_person_licenses`, `tk_person_visible`), 3 (Startwerte, Vorlage „Freigabe Touren und Kurse“), 5 (R30, R46–R48), 6 (/ad/saetze), 9 (Personen 13–18), 10 (T59–T67), 11.
- Punkt 6 (Kontaktdaten der Leitung als Vorschlag) nicht übernommen: Die Planungshilfe erfasst Kontaktdaten je Planung selbst (R48).
- Offen bleiben: externe Leitende ohne Ehrenamtsstatus (im MVP vorher im Ehrenamtsmanagement anlegen, A9 der Stories); Zuordnung Qualifikationsart → Sportart liegt in der Planungshilfe (`tk_qualification_sports`); Reichweite „nur eigene“ (später).
