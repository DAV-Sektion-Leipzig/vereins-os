# Querschnitts-Check: Auswirkungen der übrigen Module auf die Administration

Stand: 22.10.2026 · Version 0.1 · Status: Entwurf · Product Owner: Toni Werner
Ablage: Projektwissen `claude/querschnitt-administration.md`; im Repository `docs/querschnitt-administration.md` [ANNAHME]
Grundlage: ad-administration_spec.md (Administration v0.9), rollen.md v1.1, modul-landkarte.md v2.5, offene-punkte.md v3.8, vision.md v0.4, tech-stack.md v0.6, ea-ehrenamt_00-steckbrief.md v0.6, ez-einsaetze_uebergabe-finanzen.md v1.5, tk-touren-kurse_uebergabe-finanzen.md v1.3

## 1. Zweck

Entscheidung des Product Owners (22.10.2026, „Mittelweg“): Der Kern der Administration wird weiter umgesetzt. Zuvor wird geprüft, ob die noch nicht spezifizierten Module (Finanzen, Schnittstellen-Connector, Öffentlichkeitsarbeit, Projektmanagement, Geschäftsstellenmanagement, Aufgabenmanagement) den Kern ändern würden. Was nur ergänzt werden muss, kommt später als Nachtrag.

Dieses Dokument enthält:

- die Abgrenzung zwischen Kern und Nachträgen (Abschnitt 2),
- die Prüffelder mit Einschätzung (Abschnitt 3),
- das Ergebnis (Abschnitt 4),
- die Fragen an den Product Owner (Abschnitt 5).

Es ersetzt keinen Steckbrief. Die Fachlichkeit der Module wird in deren eigenen Chats erhoben.

## 2. Abgrenzung Kern und Nachträge

| Teil | Inhalt | Tasks (spec.md Administration) | Umsetzung |
|---|---|---|---|
| Kern | Spec bis v0.7.1: Login, Zugänge, Rechtevorlagen mit Reichweite „alle“ und „Referat“ (nur Ehrenamtsmanagement), gemeinsames Personenmodell mit Eigenschaftsarten, Feldern, Lesestufen, Rufname, Ehrenamtsstatus, Sichtbarkeit je Pfad (Administration, Ehrenamtsmanagement, Gruppen), Qualifikationsarten, Referate, Gremien, Dublettenwarnung, Protokoll, Seed Personen 1–12 | T1–T49, soweit nicht erledigt (erledigt: T001–T031 nach Nummerierung von Spec Kit = US-AD-01, US-AD-02, US-AD-05) | jetzt, ab T33 |
| Nachtrag v0.8 (Anwesenheitserfassung) | Modul EZ in `ad_modules`, Reichweite „Referat“ für EZ, Orte, Namensfunktionen, Anlegen von Helfer:innen | T50–T58 | vor der ersten Migration der Anwesenheitserfassung |
| Nachtrag v0.9 (Planungshilfe Touren und Kurse) | Module TK und TKF, Rechtevorlage „Freigabe Touren und Kurse“, Sätze und Pauschalen, Lizenzen und Namen für die Planungshilfe, Seed Personen 13–18 | T59–T67 | vor der ersten Migration der Planungshilfe; Sätze ggf. früher, falls Finanzen vorgezogen wird |

Hinweise:

- Beide Nachträge sind Ergänzungen (neue Zeilen, Tabellen, Funktionen, erweiterte Checks). Sie ändern keine Kern-Tabelle in ihrer Struktur, außer zwei Erweiterungen bestehender Objekte: `ad_modules.is_hidden` (v0.9) und der Check auf `ad_template_rights.scope` (R30). Beides geht per neuer Migration.
- Die spec.md v0.9 hat Text der Nachträge in die Kernabschnitte geschrieben (markiert mit v0.8 bzw. v0.9). Für die Umsetzung des Kerns gilt die Fassung ohne diese Ergänzungen. Die Anweisung an Claude Code steht in arbeitsplan.md.
- Muster-Entscheidungen aus diesem Check (Q1, Q2) betreffen nur die Nachträge. Sie sind noch nicht umgesetzt und deshalb jetzt günstig änderbar.

## 3. Prüffelder

Legende: **K** = ändert den Kern, vor Abnahme des Kerns entscheiden · **N** = später als Nachtrag ergänzbar, ohne Umbau · **–** = keine Auswirkung auf die Administration

| Nr | Thema | Auslöser (Modul) | Was die Administration bräuchte | Einschätzung | Begründung |
|---|---|---|---|---|---|
| P1 | Freigaben und weitere Aktionen | Finanzen (Abrechnung freigeben, Buchungslauf auslösen), Planungshilfe Touren und Kurse (Freigabe) | Aktion über lesen / bearbeiten / verwalten hinaus | N | „Abläufe auslösen“ ist Teil von „verwalten“ (rollen.md 5). Die Freigabe ist in v0.9 als Modul ohne Seiten (TKF) gelöst. Eine eigene Aktion „freigeben“ wäre eine Änderung an `ad_template_rights`; da v0.9 nicht umgesetzt ist, wäre ein Wechsel jetzt noch billig (Q1). |
| P2 | Reichweite „Gruppe“ | Anwesenheitserfassung (Iteration 1) | Enum-Wert `group`, Tabelle `ad_assignment_groups`, `ad_my_groups` | N | vorgemerkt als A6 in spec.md Administration Abschnitt 11; analog zur Reichweite „Referat“. |
| P3 | Reichweite „nur eigene“ | Planungshilfe Touren und Kurse (Iteration 2), Aufgabenmanagement (eigene Aufgaben), Finanzen (eigene Abrechnung, falls Trainer:innen Zugang erhalten) | Verknüpfung Datensatz ↔ Person des Nutzers | N | Ein Zugang hängt an genau einer Person (`ad_accesses.person_id`); Module prüfen gegen die eigene Person aus `ad_me()`. Neuer Enum-Wert, kein Umbau [ANNAHME]. |
| P4 | Rechte je Objekt, Projektteams | Projektmanagement, Öffentlichkeitsarbeit (Redaktion) | Rechte je Projekt oder Kanal | N | Spalte `ad_template_rights.object` und Enum `ad_scope` sind dafür vorgesehen; eine Reichweite „Projekt“ ginge analog zu `ad_assignment_referate` (Q8). |
| P5 | Einzelrechte | alle | Rechte direkt an einer Person | N | Datenmodell ausgelegt (rollen.md 1, 7); eigene Tabelle nach dem MVP. |
| P6 | Namen von Personen in weiteren Modulen | Aufgabenmanagement (Zuständige), Finanzen (Empfänger:innen), Öffentlichkeitsarbeit | Namen lesen ohne vollen Lesepfad | N, Muster offen | v0.8 und v0.9 erweitern `ea_person_names` je Modul (`ez_person_visible`, `tk_person_visible`). Jedes weitere Modul müsste die Funktion erneut ändern (Q2). |
| P7 | Personendaten für Finanzen | Finanzen | Bankverbindung, Nachweise (Bestätigung steuerfreie Einnahmen), förderfähige Lizenz lesen | N | Die Geschäftsstelle liest heute über „Ehrenamtsmanagement verwalten“ (Pfad Ehrenamtsmanagement, Lesestufe „nur Geschäftsstelle und Admin“). Nur für Nutzer mit Rechten auf Finanzen, aber nicht auf das Ehrenamtsmanagement (z. B. Schatzmeister:in), bräuchte es eine Lesefunktion wie `ea_person_licenses` oder einen Pfad Finanzen. Entscheidung im Steckbrief Finanzen. Datenschutz: Bankverbindung ist sensibel, eine Lesefunktion mit festen Spalten ist datensparsamer als ein Pfad. |
| P8 | Aufgaben an Personen ohne Zugang | Aufgabenmanagement, Geschäftsstellenmanagement | Zuweisung an eine Person statt an einen Nutzer | – | Fremdschlüssel auf `ea_persons` ist möglich; Benachrichtigung braucht eine Adresse (Login-Adresse oder Kontakt-E-Mail, Versand über den Schnittstellen-Connector) (Q7). |
| P9 | E-Mails aus Abläufen | Schnittstellen-Connector, Aufgabenmanagement, Ehrenamtsmanagement, Finanzen | Versand, Empfängeradresse, ggf. Abbestellen | N | Login-Adresse liegt in `ad_accesses`, Kontakt-E-Mail als Eigenschaft (`system_key = 'contact'`). Mails ohne Personendaten außer Empfänger und Link (tech-stack.md 4). Benachrichtigungseinstellungen je Nutzer [OFFEN], später unter „Einstellungen“. |
| P10 | API-Keys und Einstellungen | Schnittstellen-Connector | `ad_api_keys`, Vault, Seiten „Einstellungen“ | N | im Steckbrief Administration als „nach MVP bzw. mit SC“ vorgesehen. |
| P11 | Pflegbare Parameter | Finanzen (Fristen 31.07. und 15.12., steuerfreier Höchstbetrag, Zuordnung Einsatzart → Abrechnungsart) | Werte mit „gültig ab“ ohne Code-Änderung | N | `ad_rates` (v0.9) hat die Gruppe „Grenzwert“ und passt für Beträge, nicht für Datumsfristen oder Zuordnungstabellen (Q6). |
| P12 | Protokoll | Finanzen (Bankverbindung geändert, Abrechnung freigegeben oder ausgezahlt), alle Fachmodule | Nachvollziehbarkeit über Zugänge und Rechte hinaus | – | `ad_audit_log` ist auf Zugänge und Rechte zugeschnitten (betroffene Person Pflicht, feste Aktionen). Fachmodule führen einen eigenen Verlauf (wie die Planungshilfe); Änderungen an Eigenschaften stehen mit „wer, wann“ in `ea_property_history` [ANNAHME: bleibt so]. |
| P13 | Aufbewahrung und Löschung | Finanzen | längere Fristen für Abrechnungsgrundlagen | – für den Kern | Der Kern löscht nur das Protokoll nach 5 Jahren; der Löschlauf für Personen kommt nach dem MVP mit der Regel „nur löschen, wenn kein Modul die Person mehr braucht“. Die gesetzlichen Aufbewahrungsfristen für Buchungsunterlagen können deutlich länger als 5 Jahre sein; die 5-Jahres-Regel in rollen.md braucht dafür eine Ausnahme [OFFEN] (Q4). |
| P14 | Modulstruktur und Navigation | Finanzen (Abrechnung als eigenes Modul), Geschäftsstellen-, Projekt-, Aufgabenmanagement | neue Modulcodes, ggf. Untermodule | N | neue Zeile in `ad_modules` mit Startwerten (Muster T50, T59). Eine Hierarchie bräuchte eine zusätzliche Spalte (z. B. übergeordnetes Modul) (Q5). |
| P15 | Verpflichtungserklärung zum Datenschutz | übergreifend (Zugänge für ehrenamtliche Referent:innen und Hüttenwart:innen) | Bestätigung bei der ersten Anmeldung, versioniert | N | eigene Tabelle analog `ad_notice_acks` und Prüfung im Routenschutz; reine Ergänzung. Offen ist der Zeitpunkt (Q3). |
| P16 | Zeitgesteuerte Abläufe | Finanzen (Buchungslauf), Aufgabenmanagement (Erinnerungen) | Jobs ohne angemeldeten Nutzer | – | `pg_cron` ist mit der Administration eingerichtet; Jobs laufen als Datenbankfunktionen im jeweiligen Modul. |
| P17 | Neue Nutzergruppen | Finanzen (Schatzmeister:in, Kassenprüfung), Öffentlichkeitsarbeit (Redaktion) | weitere Rechtevorlagen | – | Rechtevorlagen sind konfigurierbar; Startwerte setzt die erste Migration des Moduls (Q9). |
| P18 | Umstellung der Mitgliederverwaltung auf Salesforce (voraussichtlich 2028) | extern | – | – | keine Schnittstelle vorgesehen; „Mitglied“ bleibt eine Eigenschaft. |

## 4. Ergebnis

- Kein Prüffeld erfordert eine Änderung am Kern (T1–T49) [ANNAHME: gilt, bis der Product Owner Q1–Q9 beantwortet hat]. Grund: Das Datenmodell ist für Einzelrechte, Objekt, weitere Reichweiten und Befristung ausgelegt; Personen liegen zentral; neue Module kommen über `ad_modules` und eigene Migrationen.
- **Claude Code kann den Kern ab T33 sofort fortsetzen**, unabhängig von den Antworten.
- Zwei Muster-Entscheidungen (Q1 Freigabe, Q2 Namenszugriff) betreffen die Nachträge v0.8 und v0.9. Sie sollten vor der Umsetzung von T50 entschieden sein, also spätestens vor dem Start der Anwesenheitserfassung.
- Zwei Datenschutzthemen gehören vor den Rollout an weitere Nutzer: Verpflichtungserklärung (Q3) und Aufbewahrungsfristen (Q4).
- Abhängigkeit: Wird Finanzen vor der Planungshilfe umgesetzt, wird der Teil „Sätze und Pauschalen“ aus dem Nachtrag v0.9 (T60, T61) mit Finanzen vorgezogen.

## 5. Fragen an den Product Owner

Je Frage ein Vorschlag. Antwort im Chat „Überblick“ (siehe arbeitsplan.md).

**Block A – Rechtemodell (vor Umsetzung des Nachtrags v0.8)**

- **Q1 – Freigaben:** Soll das Muster „Modul ohne Seiten“ (TKF) die Regel für Freigaben bleiben, oder soll es eine eigene Aktion „freigeben“ im Rechtemodell geben? *Vorschlag:* Muster beibehalten (bereits spezifiziert, kein Eingriff in den Kern). Eine eigene Aktion erst, wenn mehr als zwei Module Freigaben brauchen.
- **Q2 – Namenszugriff:** Soll jedes weitere Modul, das nur Namen braucht, `ea_person_names` erweitern (Muster v0.8 und v0.9), oder wird die Funktion jetzt verallgemeinert? *Vorschlag:* je Modul erweitern; verallgemeinern, wenn ein drittes Modul es braucht.
- **Q3 – Verpflichtungserklärung:** Soll die Verpflichtungserklärung zum Datenschutz vor dem ersten Zugang einer Referent:in vorhanden sein? *Vorschlag:* ja, als kleiner Nachtrag der Administration vor dem Rollout an Referent:innen und Hüttenwart:innen (ehrenamtliche Nutzer mit Zugriff auf Personendaten).

**Block B – Finanzen**

- **Q4 – Aufbewahrungsfristen:** Wer klärt die Fristen für Abrechnungsdaten und Einsätze als Abrechnungsgrundlage (z. B. Schatzmeister:in, Steuerberatung)? *Vorschlag:* Klärung vor dem Steckbrief Finanzen; bis dahin kein Löschlauf für Personen.
- **Q5 – Abrechnung als eigenes Modul:** *Vorschlag:* Entscheidung im Steckbrief Finanzen; für die Administration ist es nur eine weitere Zeile in `ad_modules`.
- **Q6 – Parameter:** Sollen Beträge wie der steuerfreie Höchstbetrag in den Stammdaten Sätze (`ad_rates`, Gruppe „Grenzwert“) liegen und Datumsfristen im Modul Finanzen? *Vorschlag:* ja.

**Block C – Aufgaben, Projekte, Nutzergruppen**

- **Q7 – Aufgaben an Personen ohne Zugang:** *Vorschlag:* im MVP des Aufgabenmanagements nur an Nutzer mit Zugang; Personen ohne Zugang später.
- **Q8 – Projektteams mit eigenen Rechten (Reichweite „Projekt“):** *Vorschlag:* mit dem Steckbrief Projektmanagement entscheiden; das Datenmodell lässt es zu.
- **Q9 – Weitere Nutzergruppen mit Zugang:** Sind Schatzmeister:in, Kassenprüfung oder eine Redaktion als Nutzer absehbar? *Vorschlag:* ja, als eigene Rechtevorlagen ohne Änderung am Kern; Zeitpunkt mit dem Rollout (offene-punkte.md „Übergreifend“).

## 6. Nächste Schritte

Siehe arbeitsplan.md. Nach den Antworten: Version 0.2 dieses Dokuments, Übernahme der Entscheidungen in offene-punkte.md und bei Bedarf eine Übergabe an die Administration.
