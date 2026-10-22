# Übergabe: Anforderungen aus Gruppen an den Nachtrag Personenmodell (Administration)

Stand: 21.10.2026 · Version 1.1 · Quelle: Chat Gruppen · Empfänger: der Chat, der spec.md Administration v0.7 (Nachtrag Personenmodell) schreibt
Grundlage: specs/gr-gruppen/00-steckbrief.md v0.6, 01-erhebung.md v0.6, 02-stories.md v0.3 (US-GR-01), spec.md Administration v0.6, glossar.md v1.1, Repository DAVLeipzig/vereins-os main @ 67f68d9

Änderungen v1.1: E2 geändert – die Administration zeigt alle Personen (Product Owner, 21.10.2026, 17:43). A1 Pfad AD und Tests angepasst; A2 präzisiert.

Diese Datei ersetzt keine gemeinsame Datei. Sie wird beim Schreiben des Nachtrags eingearbeitet und danach als erledigt markiert.

## 1. Umsetzungsstand im Repository (geprüft 21.10.2026)

- Erledigt: T001–T031 (US-AD-01, US-AD-02, US-AD-05). Migrationen `20261020000100` bis `20261020000600` laufen in TEST, nicht in PROD.
- `ea_persons` existiert (Migration `20261020000200_ea_persons.sql`) mit RLS: AD ≥ read liest **alle** Personen, EA ≥ read alle Menschen. → Änderung nur per **neuer** Migration.
- `ea_property_types` und `ea_properties` existieren noch **nicht** (T044, T048 offen) → können direkt mit mehreren Feldern, Kategorie und Lesestufe gebaut werden.
- Branch `us-ad-10-rechtevorlagen` (T032–T034) unfertig, pausiert. Umsetzung gestoppt (Product Owner, 21.10.2026).

## 2. Entscheidungen des Product Owners (21.10.2026), die der Nachtrag abbilden muss

| Nr | Entscheidung |
|---|---|
| E1 | Eine gemeinsame Personen-Tabelle für Aktive, Teilnehmer:innen, Erziehungsberechtigte und Notfallkontakte (Variante B). Ein Mensch existiert nur einmal. |
| E2 | **Administration** zeigt **alle** Personen, auch Teilnehmer:innen, Erziehungsberechtigte und Notfallkontakte. Der Admin hat die Gesamtübersicht und pflegt Personendaten (Name, Rufname, Geburtsdatum, Kontaktdaten, Mitgliedsnummer) zentral, damit Änderungen nicht je Modul nötig sind. Bewusst entschieden (21.10.2026, ersetzt die frühere Fassung „nur Personen mit Zugang, Funktionspersonen und Ehrenamtsstatus“). |
| E3 | **Ehrenamtsmanagement** zeigt nur Personen mit Ehrenamtsstatus (wie EA v0.6). |
| E4 | **Gruppen** zeigt nur Personen mit Gruppenbezug: Teilnahme, Erziehungsberechtigung, Notfallkontakt oder Funktion mit Bezug auf eine Gruppe. |
| E5 | Rechtevorlage Admin erhält für Gruppen den Startwert „lesen“ (Risikomanagement). Vorstand bleibt ohne Rechte. |
| E6 | Zugänge werden schrittweise vergeben: zuerst Referent:innen und Vorstand, später Gruppenleitungen, dann stellvertretende Gruppenleitungen und weitere Trainer:innen. Erziehungsberechtigte und Teilnehmer:innen erhalten keinen Zugang. |

## 3. Anforderungen an das Personenmodell

- **A1 Sichtbarkeit je Zugehörigkeit (E2–E4):** RLS auf `ea_persons` und `ea_properties` als Oder-Verknüpfung von Lesepfaden:
  - Pfad AD: AD ≥ read → alle Personen und alle Eigenschaften inkl. aller Lesestufen (entspricht der bestehenden Policy in `ea_persons`; keine Änderung nötig). Gruppenspezifische `gr_`-Tabellen sind nicht über den Pfad AD lesbar; Gesundheitsangaben nie.
  - Pfad EA: EA ≥ read und Person hat Ehrenamtsstatus (Ausgeschiedene nur für Geschäftsstelle und Admin, Reichweite „Referat“ nach EA).
  - Pfad GR: GR ≥ read und Person hat Gruppenbezug.
  - Vorschlag: je Pfad eine Funktion (z. B. `ea_person_visible_ad(id)`, `ea_person_visible_ea(id)`, `gr_person_visible(id)`), die Policies verknüpfen sie. `gr_person_visible` wird in AD als Platzhalter (liefert false) angelegt und mit der ersten Gruppen-Migration ersetzt [ANNAHME].
- **A2 Lesestufe im Pfad Gruppen** [ANNAHME, im Nachtrag bestätigen lassen]: „alle mit Zugriff“ = GR ≥ read · „nur Geschäftsstelle und Admin“ = GR ≥ manage · „vertraulich“ = nur AD. Folge: Wer nur „Gruppen lesen“ hat (z. B. Vorstand), sieht Kontaktdaten von Kindern, aber kein Geburtsdatum. Der Admin sieht es trotzdem, über den Pfad AD (E2).
- **A3 Eigenschaftsarten für Gruppen nutzen die gemeinsamen Arten:** Kontaktdaten (Adresse, Telefon, E-Mail), Geburtsdatum, Mitglied (mit Mitgliedsnummer). „sichtbar in“ muss GR enthalten. Gruppenspezifisches (Teilnahme, Erziehungsberechtigung, Notfallkontakt, Vertrag, Fotoerlaubnis, gesundheitliche Einschränkungen) liegt in `gr_`-Tabellen, nicht in `ea_properties`.
- **A4 Funktion mit Bezug auf eine Gruppe:** Gruppenleitung, Trainer:in, Helfer:in werden im Modul Gruppen gepflegt, im Ehrenamtsmanagement nur gelesen (R14 Gruppen). Das Personenmodell braucht dafür einen Bezug auf eine Gruppe (Feld-Datentyp „Gruppe“ oder Bezugsspalte, die die Gruppen-Migration ergänzt) und eine Schreibregel: Eigenschaften mit Gruppenbezug schreibt nur GR ≥ edit. Wird eine Person als Trainer:in oder Helfer:in eingetragen und hat keinen Ehrenamtsstatus, setzt Gruppen „aktiv“ (Annahme aus EA v0.6).
- **A5 Dublettenwarnung modulübergreifend:** Treffer zeigen nur Vorname, Nachname und Geburtsjahr bzw. „ausgeschieden seit“; keine Eigenschaften aus fremden Pfaden (US-GR-06 AK2, A2 bestätigt).
- **A6 Anlegen und Ändern von Personen:** zusätzlich GR ≥ edit (Teilnehmer:innen, Erziehungsberechtigte, Notfallkontakte). Heute nur AD ≥ edit oder EA ≥ edit. AD ≥ edit darf Personendaten aller Personen ändern (E2).
- **A7 Startwert Rechtevorlage Admin:** GR „lesen“ (E5) per neuer Migration auf `ad_template_rights`.
- **A8 Löschlauf** (nach MVP, alle Module): Eine Person wird nur gelöscht, wenn kein Pfad sie mehr braucht (R15 Gruppen).

## 4. Tests, die der Nachtrag vorsehen sollte

- Teilnehmer:in ohne Ehrenamtsstatus: nicht lesbar mit nur EA-Rechten (Tabelle und Eigenschaften); lesbar und änderbar mit AD ≥ read bzw. edit.
- Admin: liest über die Administration keine `gr_`-Tabellen und nie Gesundheitsangaben.
- Erziehungsberechtigte:r, zugleich Trainer:in: lesbar über EA, aber ohne gruppenspezifische Daten.
- Nutzer nur mit „Gruppen lesen“ (ohne AD): liest Kontaktdaten eines Kindes, nicht dessen Geburtsdatum (A2).
- Funktion mit Gruppenbezug: im Ehrenamtsmanagement nicht änderbar.
