# Übergabe: Finanzen → Gruppen

Stand: 26.10.2026 · Version 1.0 · Status: offen · Von: Finanzen (FI) · An: Gruppen (GR)
Grundlage: docs/specs/fi-finanzen/01-erhebung.md v0.7 (Abschnitt H, R34–R46), 02-stories.md v0.2 (US-FI-18 bis US-FI-21); spec.md GR (`gr_contracts`, R8, R8a, R8b, Abschnitt 3 RLS); glossar.md „Vertrag“, „Mandatsreferenz“, „Buchungslauf“
Änderungen v1.0: Erste Fassung.

## Anlass

Finanzen zieht die Verträge monatlich per SEPA-Lastschrift ein (Buchungslauf, Product Owner 26.10.2026). Die Verträge mit SEPA-Mandat liegen in `gr_contracts` und sind heute nur mit „GR lesen“ sichtbar (`gr_row_visible`). Die Geschäftsstelle hat zwar GR-Rechte; Finanzen soll aber wie bei der Bankverbindung der Aktiven (Administration A8) über eine eigene Lesefunktion mit festen Spalten lesen, unabhängig von GR-Rechten und ohne Gesundheitsangaben oder Kontaktdaten. Finanzen legt keine Tabellen oder Funktionen anderer Module an.

## Bedarf

| # | Bedarf | Vorschlag |
|---|---|---|
| G1 | **Lesefunktion Verträge für den Einzug** | `gr_contracts_for_collection(p_month date) returns setof (contract_id uuid, membership_id uuid, group_id uuid, group_name text, referat_id uuid, participant_person_id uuid, participant_first_name text, participant_last_name text, holder_person_id uuid, holder_name text, account_holder text, iban text, mandate_reference text, mandate_signed_on date, purpose text, monthly_amount numeric, starts_on date, ends_on date)` – security definer, stable; nur mit `ad_has_level('FI','manage')`, sonst `GR_FORBIDDEN` [ANNAHME: Code]; liefert alle Verträge mit `starts_on <= p_month` und (`ends_on is null or ends_on >= p_month`), `p_month` = 1. des Monats (R34 FI). Keine weiteren Felder. |
| G2 | **Prüfwert der Bankverbindung** | in G1 zusätzlich `bank_check text` = md5 aus IBAN und Kontoinhaber:in, damit Finanzen ohne Speichern der IBAN erkennt, dass sich die Bankverbindung seit dem letzten Einzug geändert hat (R43, R44 FI). |
| G4 | **Mandatsreferenzen vor dem Import prüfen** | In der Lastschriftdatei Oktober 2026 der Geschäftsstelle kommt eine Mandatsreferenz bei zwei verschiedenen Zahlungspflichtigen vor, und eine Referenz erscheint mit und ohne führende Null. Der Import (US-GR-16, R6) lehnt doppelte Referenzen ab; Vorschlag: Bereinigung durch die Geschäftsstelle vor dem Import, der Probelauf meldet die Fälle. Daten nicht im Repository. |
| G3 | **Löschfrist** | spec.md GR R15 „[ANNAHME, OFFEN mit Finanzen]“: Einzüge in Finanzen verweisen auf `gr_contracts` (Fremdschlüssel, on delete restrict). Vorschlag: Ein Vertrag wird frühestens gelöscht, wenn seine Einzüge nach der Frist von Finanzen gelöscht sind (5 Jahre nach Ende des Kalenderjahres, R43 FI). |

## Nicht Teil dieser Übergabe

Keine Änderung an Verträgen, Teilnahme oder Oberfläche der Gruppen. Hinweise in Gruppen („bereits eingezogen“) und Sperren bei Kündigung nach einem Einzug sind nicht vorgesehen (R46 FI).
