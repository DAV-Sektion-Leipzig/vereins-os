# Stories: Planungshilfe Touren und Kurse (TK) – MVP

Stand: 26.10.2026 · Version 0.5 · Status: Entwurf · Product Owner: Toni Werner
Änderungen v0.5: Wiederaufnahme: Fritz Freigabe mit Vorlage „Freigabe Touren und Kurse“ (TK bearbeiten + darf freigeben); US-TK-03 AK7 Lizenz-Erwerb im Halbjahr; US-TK-10 AK2 auch mehrtägige Kurse nach Lehreinheiten (AK7 neu); US-TK-16 AK6 Titel ungekürzt, AK7 Abrechnungsart Gemeinschaftstour; A4 entfällt (Product Owner 24./26.10.2026).
Änderungen v0.4: Namen der Testpersonen an den Seed der Administration angeglichen (Tina Touren, Alex Ausbildung, Anna Fiktiv, Test Admin, Bernd Beispiel).
Änderungen v0.3: A12 bestätigt (Organisationspauschale der Gemeinschaftstour trägt vorerst die Sektion); Sätze pflegt nur der Admin (US-TK-19) (Product Owner 22.10.2026).
Änderungen v0.2: Gemeinschaftstour mit Organisationspauschale (US-TK-10 AK3, US-TK-11 AK7); US-TK-19 neu: Sätze aus der Administration verwenden (Pflege dort, Übergabe v1.4); Stornoregel entfernt (US-TK-09, US-TK-15) (Product Owner 22.10.2026).
Änderungen v0.1: Erste Fassung der MVP-Stories (US-TK-01 bis US-TK-22) auf Grundlage von 00-steckbrief.md v0.5, 01-erhebung.md v0.5 und prototyp-tourenkonzept.md.

Grundlagen: docs/specs/tk-touren-kurse/00-steckbrief.md · 01-erhebung.md (Regeln R1–R10, Abläufe B1–B9) · prototyp-tourenkonzept.md (im Folgenden „Prototyp“ mit Abschnittsnummer; dort stehen Felder, Auswahllisten, Formeln und Texte vollständig). Begriffe nach glossar.md.

## Übersicht

| Story | Titel | Priorität | Abhängig von |
|---|---|---|---|
| US-TK-01 | Planungen des eigenen Referats sehen | Must | Administration (Modul TK, Reichweite Referat) |
| US-TK-02 | Planung anlegen und als Entwurf speichern | Must | US-TK-01 |
| US-TK-03 | Leitung und Helfende aus den Aktiven wählen | Must | US-TK-02; Administration (Namenssuche, `ea_person_licenses`) |
| US-TK-04 | Kontakt- und Notfalldaten der Leitung erfassen | Must | US-TK-03 |
| US-TK-05 | Ausschreibung erfassen (Schritt 2) | Must | US-TK-02 |
| US-TK-06 | Termin, Treffpunkt und Anreise erfassen (Schritt 3) | Must | US-TK-02 |
| US-TK-07 | CO2-Bilanz der Planung berechnen | Must | US-TK-06, US-TK-19 |
| US-TK-08 | Anforderungen erfassen (Schritt 4) | Must | US-TK-02 |
| US-TK-09 | Teilnahme und Anmeldung festlegen (Schritt 5) | Must | US-TK-02 |
| US-TK-10 | Vergütung und Kosten kalkulieren (Schritt 6) | Must | US-TK-03, US-TK-19 |
| US-TK-11 | Teilnahmebeitrag und Kostendeckung berechnen | Must | US-TK-09, US-TK-10 |
| US-TK-12 | Pflichtangaben, Fortschritt und Hinweise sehen | Must | US-TK-03 bis US-TK-11 |
| US-TK-13 | Planung einreichen | Must | US-TK-12 |
| US-TK-14 | Rückfrage stellen und freigeben | Must | US-TK-13; Administration (Freigaberecht) |
| US-TK-15 | Yolawo-Eingabeblatt und Ausschreibungstext nutzen | Must | US-TK-05 bis US-TK-11 |
| US-TK-16 | Als „in Yolawo angelegt“ markieren und Einsatz erzeugen | Must | US-TK-14; Anwesenheitserfassung (`ez_upsert_planned_event`) |
| US-TK-17 | Planung absagen | Must | US-TK-02; Anwesenheitserfassung (`ez_cancel_planned_event`) |
| US-TK-18 | Planung als durchgeführt und abgeschlossen markieren | Should | US-TK-16 |
| US-TK-19 | Sätze aus der Administration verwenden | Must | Administration (Stammdaten Sätze, Übergabe v1.5) |
| US-TK-20 | Kostenauswertung über alle Planungen | Must | US-TK-11 |
| US-TK-21 | Planung als PDF exportieren | Should | US-TK-15 |
| US-TK-22 | Notfallkontakte automatisch löschen | Must | US-TK-04 |
| US-TK-23 | Planung kopieren | Could | US-TK-02 |
| US-TK-24 | Planwerte für die Abrechnung bereitstellen | Should | US-TK-10; Finanzen |

Nicht im MVP (Won't): PDF-Übernahme aus dem HTML-Formular; CO2-Auswertung über mehrere Planungen (Iteration 1); Eingabe durch Tourenleitende, öffentliches Formular, Ablösung des HTML-Formulars (Iteration 2); Ist-Kosten, Feedbackbogen, Foto-Upload.

Testpersonen der Akzeptanzkriterien (fiktiv, Seed TEST): **Tina Touren** (Referent:in, Referat Touren), **Alex Ausbildung** (Referent:in, Referat Ausbildung), **Fritz Freigabe** (Vorlage „Freigabe Touren und Kurse“ = TK bearbeiten + darf freigeben, Referat Touren; ohne Vorlage Referent:in), **Anna Fiktiv** (Geschäftsstelle), **Test Admin** (Admin), **Bernd Beispiel** (Vorstand ohne Rechte). Aktive: **Bernd Berg** (Trainer*in C Bergwandern, förderfähig, gültig bis 30.10.2027), **Hilde Helfer** (keine Lizenz), **Karl Kletter** (Trainer*in C Sportklettern, gültig bis 31.12.2025).

---

### US-TK-01: Planungen des eigenen Referats sehen
**Als** Referent:in (TK bearbeiten, Reichweite Referat) bzw. Geschäftsstelle (TK verwalten)
**möchte ich** eine Liste aller Planungen sehen, die ich lesen darf, mit Titel, Tourtyp, Referat, Termin, Leitung, Status und Beitrag Mitglieder,
**damit** ich weiß, was in welchem Stand ist.
**Priorität:** Must · **Regeln:** Rechte A · **Abhängig von:** Administration (Modul TK, Startwerte der Rechtevorlagen, Reichweite „Referat“)
**Akzeptanzkriterien**
- AK1: Gegeben Tina (Referat Touren) und je eine Planung der Referate Touren und Ausbildung, wenn Tina die Liste öffnet, dann sieht sie nur die Planung des Referats Touren.
- AK2: Gegeben Anna Fiktiv (Geschäftsstelle), wenn sie die Liste öffnet, dann sieht sie Planungen aller Referate.
- AK3: Gegeben die Liste, wenn ich nach Status, Tourtyp, Jahr (Startdatum) filtere, dann zeigt sie nur passende Planungen; Standard: alle Status außer „abgesagt“ und „abgeschlossen“, sortiert nach Startdatum aufsteigend [ANNAHME].
- AK4 (Rechte): Gegeben Bernd Beispiel (Vorstand ohne Rechte), wenn sie /tk aufruft, dann erscheint „Kein Zugriff auf die Planungshilfe Touren und Kurse.“ und der Modul-Eintrag fehlt auf der Startseite; auch direkte Datenbankabfragen liefern keine Zeilen (RLS).
- AK5 (leer): Gegeben keine lesbare Planung, wenn die Liste geöffnet wird, dann erscheint „Noch keine Planungen.“ und – bei Schreibrecht – der Knopf „Neue Planung“.
**Nicht Teil dieser Story:** Kostensummen (US-TK-20); Notfallkontakte in der Liste (nie).

### US-TK-02: Planung anlegen und als Entwurf speichern
**Als** Referent:in bzw. Geschäftsstelle
**möchte ich** eine neue Planung mit Tourtyp anlegen und jederzeit speichern, auch unvollständig,
**damit** ich eine Einreichung schrittweise übertragen oder selbst planen kann.
**Priorität:** Must · **Regeln:** R10, B1, B4 · **Abhängig von:** US-TK-01
**Akzeptanzkriterien**
- AK1: Gegeben Tina, wenn sie „Neue Planung“ wählt, Tourtyp „Führungstour“ und Titel eingibt und speichert, dann entsteht eine Planung im Status „Entwurf“ mit Referat Touren und einem Verlaufseintrag „angelegt von Tina Touren, Datum, Uhrzeit“.
- AK2: Gegeben Tourtyp „Kurs“, wenn gespeichert wird, dann erhält die Planung das Referat Ausbildung; bei „Führungstour“ und „Gemeinschaftstour“ das Referat Touren; das Referat ist nicht frei wählbar [ANNAHME].
- AK3 (Rechte): Gegeben Tina (nur Referat Touren), wenn sie Tourtyp „Kurs“ wählt und speichert, dann erscheint „Für Kurse ist das Referat Ausbildung zuständig. Dir fehlt das Recht für dieses Referat.“ und nichts wird gespeichert.
- AK4: Gegeben ein Entwurf, wenn ich ein Pflichtfeld leer lasse und speichere, dann wird gespeichert; die Lücke erscheint nur in der Prüfung (US-TK-12).
- AK5 (Fehler): Gegeben die Verbindung bricht beim Speichern ab, wenn ich speichere, dann erscheint „Speichern fehlgeschlagen. Deine Eingaben sind noch da – bitte erneut speichern.“ und die Eingaben bleiben im Formular.
- AK6: Gegeben ein gespeicherter Entwurf, wenn ich den Tourtyp ändere und damit das Referat wechseln würde, dann ist das nur möglich, wenn ich auch im neuen Referat Schreibrecht habe; sonst Fehlermeldung wie AK3.
**Nicht Teil dieser Story:** Inhalte der Schritte (US-TK-03 bis US-TK-11); Kopie (US-TK-23); PDF-Übernahme (nicht im Scope).

### US-TK-03: Leitung und Helfende aus den Aktiven wählen
**Als** Referent:in bzw. Geschäftsstelle
**möchte ich** Leitung, Co-Leitung und Helfer:innen aus den Aktiven suchen und sehen, welche Lizenzen sie haben,
**damit** der richtige Satz (Trainer:in oder Helfer:in) ohne Freitext ermittelt wird.
**Priorität:** Must · **Regeln:** R2, R6, B3 · **Abhängig von:** US-TK-02; Administration (`ea_search_active_persons`, `ea_person_licenses`)
**Akzeptanzkriterien**
- AK1: Gegeben die Suche, wenn ich „Ber“ eingebe, dann erscheinen Aktive mit Status „aktiv“, deren Vor-, Ruf- oder Nachname passt (ab 2 Zeichen, höchstens 50 Treffer), nur mit Namen.
- AK2: Gegeben Bernd Berg als Leitung und Startdatum 29.10.2027 (Tour bis 01.11.2027), wenn die Satzart berechnet wird, dann ist sie „Trainer:in“ für die ganze Tour, mit Hinweis „Lizenz läuft während der Tour ab (30.10.2027) – Verlängerung für künftige Touren nötig.“
- AK3: Gegeben Bernd Berg und Startdatum 02.11.2027, wenn die Satzart berechnet wird, dann ist sie „Helfer:in“ mit Hinweis „Ohne gültige Lizenz wird der Helfersatz gerechnet.“
- AK4: Gegeben Hilde Helfer mit Rolle „Co-Leitung“, wenn die Satzart berechnet wird, dann ist sie „Helfer:in“; gegeben Rolle „Helfer:in“, dann immer „Helfer:in“, auch mit Lizenz.
- AK5: Gegeben Sportart „Klettern“ und nur Bernd Berg als nicht helfende Person, wenn geprüft wird, dann erscheint „Keine der angegebenen Qualifikationen deckt Klettern als Führungstour ab. Bitte Qualifikation, Sportart oder Tourtyp prüfen.“ (Prototyp 6.3, Zuordnung nach Erhebung C3).
- AK6 (Fehler): Gegeben dieselbe Person zweimal, wenn ich sie erneut hinzufüge, dann erscheint „Diese Person ist schon eingetragen.“
- AK7: Gegeben Karl Kletter mit einer förderfähigen Lizenz, erworben am 15.08.2027, und ein Kurs am 10.07.2027, wenn die Satzart berechnet wird, dann ist sie „Trainer:in“ mit Hinweis „Lizenz erworben am 15.08.2027 – Trainersatz für das ganze Halbjahr.“ (gleiche Regel wie Finanzen, Product Owner 26.10.2026).
- AK7 (Rechte): Gegeben eine Person ohne Ehrenamtsstatus „aktiv“, dann erscheint sie nicht in der Suche; die Planungshilfe zeigt keine weiteren Eigenschaften der Person als Name und Lizenzen (Qualifikationsart, gültig bis, förderfähig).
**Nicht Teil dieser Story:** Anlegen externer Leitender ohne Ehrenamtsstatus [OFFEN]; Pflege von Lizenzen (Ehrenamtsmanagement).

### US-TK-04: Kontakt- und Notfalldaten der Leitung erfassen
**Als** Referent:in bzw. Geschäftsstelle
**möchte ich** E-Mail, Mobilnummer und Notfallkontakt je leitender Person erfassen,
**damit** das Referat im Notfall während der Tour handeln kann.
**Priorität:** Must · **Regeln:** R8, F · **Abhängig von:** US-TK-03
**Akzeptanzkriterien**
- AK1: Gegeben eine leitende Person, wenn ich die Planung bearbeite, dann kann ich E-Mail (Pflicht für die erste Leitung), Mobilnummer und Notfallkontakt (Name und Telefon, Pflicht für die erste Leitung) eintragen; weitere Leitende optional.
- AK2: Gegeben die Felder, dann steht darüber der Datenschutzhinweis des Prototyps (8.3, sinngemäß angepasst: „… werden im Vereins OS gespeichert und nach der Tour gelöscht.“).
- AK3 (Rechte): Gegeben Test Admin (Admin, TK lesen), wenn er die Planung öffnet, dann sieht er keine Notfallkontakte und keine Mobilnummer [ANNAHME]; Tina sieht sie nur für Planungen ihres Referats.
- AK4: Gegeben Notfallkontakte, dann erscheinen sie nie im Ausschreibungstext, im Yolawo-Eingabeblatt, in der Liste oder im CSV-Export.
- AK5 (Fehler): Gegeben die Telefonnummer enthält Buchstaben, wenn gespeichert wird, dann erscheint „Bitte eine Telefonnummer eingeben.“ [ANNAHME: Ziffern, Leerzeichen, +, /, - erlaubt].
**Nicht Teil dieser Story:** Löschung (US-TK-22); Vorschlag der Kontaktdaten aus dem Ehrenamtsmanagement [ANNAHME: später].

### US-TK-05: Ausschreibung erfassen (Schritt 2)
**Als** Referent:in bzw. Geschäftsstelle
**möchte ich** Titel, Sportart, Zielgruppe, Region, Stützpunkt, Kurzbeschreibung, Programm und Titelbild erfassen,
**damit** daraus der Ausschreibungstext entsteht.
**Priorität:** Must · **Regeln:** R9; Felder Prototyp 3.1 Schritt 2 · **Abhängig von:** US-TK-02
**Akzeptanzkriterien**
- AK1: Gegeben Schritt 2, dann gibt es die Felder und Auswahllisten aus Prototyp 3.1 (Sportart mit 15 Werten, Zielgruppe mit 4 Werten, Titelbild „eigen“/„referat“) mit denselben Bezeichnungen.
- AK2: Gegeben Titelbild „Eigenes Foto“, wenn Bildrechte leer sind, dann ist „Bildrechte“ Pflicht; bei „Referat wählt ein Bild“ ist das Feld ausgeblendet.
- AK3 (Fehler): Gegeben ein Titel mit 91 Zeichen, wenn ich tippe, dann lässt das Feld nicht mehr als 90 Zeichen zu und zeigt „90/90“.
- AK4 (Rechte): Gegeben eine Planung im Status „freigegeben“, wenn Tina (ohne Freigaberecht) den Titel ändern will, dann ist das Feld gesperrt mit Hinweis „Nach der Freigabe ändern nur Personen mit Freigaberecht oder die Geschäftsstelle.“
**Nicht Teil dieser Story:** Foto-Upload (Foto kommt weiter per E-Mail).

### US-TK-06: Termin, Treffpunkt und Anreise erfassen (Schritt 3)
**Als** Referent:in bzw. Geschäftsstelle
**möchte ich** Beginn, Ende, Treffpunkt, Vorbesprechung, Anreise mit Teilstrecken, Unterkunft und Nächte erfassen,
**damit** Termin, Vergütungstage und CO2-Bilanz stimmen.
**Priorität:** Must · **Regeln:** R1 (Prototyp 4.1, 4.2), R10 · **Abhängig von:** US-TK-02
**Akzeptanzkriterien**
- AK1: Gegeben Beginn 12.07.2027 und Ende 16.07.2027, dann zeigt das System „Mehrtagestour, 5 Tage“ und schlägt Tagessätze 5, Halbtagessätze 0, Organisationstage 5 vor (Prototyp 4.2); eigene Änderungen bleiben erhalten („touched“).
- AK2: Gegeben eine Teilstrecke Bahn Fernverkehr 650 km, 9 Personen, hin und zurück, wenn gespeichert wird, dann wird sie als eigene Zeile (Verkehrsmittel, Strecke, km, Personen, Fahrzeuge, hin und zurück) gespeichert (R10).
- AK3: Gegeben Verkehrsmittel PKW, dann ist „Fahrzeuge“ Pflicht und „Personen“ informativ; bei Personen ÷ Fahrzeuge < 3 erscheint der Hinweis zu Fahrgemeinschaften (Prototyp 6.3).
- AK4 (Fehler): Gegeben Ende vor Beginn, wenn gespeichert wird, dann wird gespeichert, aber die Prüfung zeigt „Ende liegt vor Beginn“ und Einreichen ist gesperrt.
- AK5: Gegeben Unterkunft „DAV-Hütte“ und 5 Tage, dann schlägt das System 4 Nächte und Personen gesamt = Höchstzahl + Anzahl Leitende vor.
**Nicht Teil dieser Story:** CO2-Berechnung (US-TK-07).

### US-TK-07: CO2-Bilanz der Planung berechnen
**Als** Referent:in bzw. Geschäftsstelle
**möchte ich** die CO2-Bilanz der Planung (An- und Abreise, Unterkunft, Verpflegung, je Person, Klimaschutzbudget) sehen,
**damit** ich die Anreise klimafreundlich plane und die Werte später ausgewertet werden können.
**Priorität:** Must · **Regeln:** R1 (Prototyp 4.7), R3 · **Abhängig von:** US-TK-06, US-TK-19
**Akzeptanzkriterien**
- AK1: Gegeben die Beispieldaten des Prototyps (3.5), wenn berechnet wird, dann ergibt sich: An- und Abreise 352,8 kg, Unterkunft 335,52 kg (Hütte, nicht im Tourbudget), Verpflegung 211,5 kg, Tour 564,3 kg, je Person ca. 100 kg, Klimaschutzbudget 79,00 € (Prototyp 4.7).
- AK2: Gegeben PKW-Teilstrecke 400 km einfach bei 3 Tagen, dann erscheint der Hinweis zum Leipziger Richtwert (350 km).
- AK3: Gegeben Flug 600 km, dann erscheint „Flug unter 1000 km: nach DAV-Selbstverpflichtung ausgeschlossen“.
- AK4 (Fehler): Gegeben keine Teilstrecke mit km > 0, dann zeigt die Statusanzeige „Anreise fehlt“ und die Prüfung meldet „Geplante An- und Abreise (CO2)“.
- AK5: Gegeben die Berechnung, dann werden Ergebnis und verwendeter Satzstand der Faktoren an der Planung gespeichert (R3).
- AK6 (Rechte): Gegeben Test Admin (TK lesen), dann sieht er die CO2-Bilanz, kann sie aber nicht ändern.
**Nicht Teil dieser Story:** Auswertung über mehrere Planungen (Iteration 1).

### US-TK-08: Anforderungen erfassen (Schritt 4)
**Als** Referent:in bzw. Geschäftsstelle
**möchte ich** Gehzeit, Höhenmeter, Strecke, Kondition, Technik, Schwierigkeit, Voraussetzungen, Ausrüstung und die Ausnahme für Nichtmitglieder erfassen,
**damit** die Ausschreibung die Anforderungen richtig beschreibt.
**Priorität:** Must · **Regeln:** R1 (Prototyp 4.8), R5 · **Abhängig von:** US-TK-02
**Akzeptanzkriterien**
- AK1: Gegeben Gehzeit 7 h und 1.000 Hm, dann schlägt das System Kondition „groß“ vor; bei gewählter „mittel“ erscheint „Nach Gehzeit und Höhenmetern passt eher „groß“.“
- AK2: Gegeben Standard, dann gilt „nur DAV-Mitglieder“; wird „Ausnahme: auch Nichtmitglieder zulassen“ gesetzt (keine Gemeinschaftstour), ist „Begründung der Ausnahme“ Pflicht.
- AK3 (Fehler): Gegeben Voraussetzungen leer, wenn eingereicht werden soll, dann meldet die Prüfung „Voraussetzungen“.
- AK4 (Rechte): Gegeben Planung im Status „eingereicht“ und Tina, dann darf sie ändern; ab „freigegeben“ siehe US-TK-05 AK4.
**Nicht Teil dieser Story:** automatische Prüfung der Technikstufe.

### US-TK-09: Teilnahme und Anmeldung festlegen (Schritt 5)
**Als** Referent:in bzw. Geschäftsstelle
**möchte ich** Mindest- und Höchstzahl, Anmeldeschluss, Warteliste, Stornobedingungen der Unterkunft und die Fragen im Anmeldeformular festlegen,
**damit** Kalkulation und Yolawo-Angebot stimmen.
**Priorität:** Must · **Regeln:** Prototyp 3.1 Schritt 5, 3.3 · **Abhängig von:** US-TK-02
**Akzeptanzkriterien**
- AK1: Gegeben eine neue Planung, dann sind die 6 Anmeldefragen aus Prototyp 3.3 vorausgewählt, Warteliste „ja“; Zahlungsart ist fest angezeigt; eine Stornoregel gibt es nicht (R11).
- AK2 (Fehler): Gegeben Mindestzahl 9 und Höchstzahl 8, dann erscheint „Die Mindestanzahl ist größer als die Höchstanzahl.“ und Einreichen ist gesperrt.
- AK3 (Fehler): Gegeben Anmeldeschluss am oder nach dem Beginn, dann erscheint „Anmeldeschluss liegt nicht vor Tourbeginn“.
- AK4: Gegeben „nur DAV-Mitglieder“, dann entfällt im Eingabeblatt bei der Frage zur Mitgliedschaft der Teil „/ kein Mitglied“.
- AK5 (Rechte): Gegeben Test Admin (TK lesen), dann sind alle Felder nur lesbar.
**Nicht Teil dieser Story:** Anmeldung der Teilnehmenden (Yolawo).

### US-TK-10: Vergütung und Kosten kalkulieren (Schritt 6)
**Als** Referent:in bzw. Geschäftsstelle
**möchte ich** Vergütung der Leitung, Kosten der Leitung, sonstige Kosten, Leistungen je Teilnehmer:in und „selbst zu zahlen“ erfassen,
**damit** die Gesamtkosten der Tour feststehen.
**Priorität:** Must · **Regeln:** R1 (Prototyp 4.3, 4.4), R2, R3, R4 · **Abhängig von:** US-TK-03, US-TK-19
**Akzeptanzkriterien**
- AK1: Gegeben die Beispieldaten (1 Trainer:in, 5 Tagessätze, 5 Organisationstage, Kosten der Leitung 435 €), dann ergibt sich Vergütung 250 €, Organisationspauschale 50 €, Gesamtkosten 735 € (Prototyp 4.5).
- AK2: Gegeben Tourtyp „Kurs“ (ein- oder mehrtägig), dann wird nur nach Lehreinheiten gerechnet (Satz 15 €); Helfende erhalten 0 €; keine Tagessätze; Organisationspauschale 0 € (Product Owner 26.10.2026).
- AK3: Gegeben Tourtyp „Gemeinschaftstour“ mit 3 Tagen, dann sind Tagessätze, Kosten der Leitung, sonstige Kosten und Leistungen je Teilnehmer:in ausgeblendet und 0, die Organisationspauschale wird gerechnet (3 × 10 € = 30 €, Vergütungsordnung Ziff. 9.2; Product Owner 22.10.2026); „selbst zu zahlen“ bleibt.
- AK4: Gegeben die Schnellknöpfe (+ PKW-Fahrt, + Übernachtung, + Pauschale Sulzenauhütte, + Pauschale Karl-Stein-Hütte, + Hütte Ü+HP, + Getränke …), dann fügen sie Zeilen nach Prototyp 3.2 mit den aktuellen Sätzen ein; jede Kostenzeile wird als eigene Zeile gespeichert (R10).
- AK5 (Fehler): Gegeben eine Zeile „PKW …“ in den Kosten der Leitung und leere PKW-Begründung, dann meldet die Prüfung „Begründung PKW-Fahrt“; Summe PKW-km > 500 zeigt die Genehmigungswarnung.
- AK6 (Rechte): Gegeben Planung „freigegeben“, dann ändern nur Personen mit Freigaberecht und Geschäftsstelle die Kalkulation; jede Änderung des Beitrags oder der Gesamtkosten erscheint im Verlauf.
- AK7: Gegeben ein mehrtägiger Kurs, dann schlägt die Kalkulation keine Lehreinheiten vor; ohne Eingabe meldet die Prüfung „Lehreinheiten“ und Einreichen ist gesperrt (Product Owner 26.10.2026).
**Nicht Teil dieser Story:** Ist-Kosten und Belege (Finanzen).

### US-TK-11: Teilnahmebeitrag und Kostendeckung berechnen
**Als** Referent:in bzw. Geschäftsstelle
**möchte ich** den kostendeckenden Beitrag inkl. Zahlungsgebühren, den Beitrag für Nichtmitglieder und die Kostendeckung bei Mindest- und Höchstzahl sehen,
**damit** der Beitrag nach Vergütungsordnung Ziff. 9.1 ausreichend bemessen ist.
**Priorität:** Must · **Regeln:** R1 (Prototyp 4.5, 4.6) · **Abhängig von:** US-TK-09, US-TK-10
**Akzeptanzkriterien**
- AK1: Gegeben die Beispieldaten und die aktiven Zahlmethoden SEPA, Karte, PayPal, dann ist der Vorschlag 160 € (PayPal als teuerste Methode), kostendeckend ab 5 Teilnehmenden, Ergebnis 18,71 € bei 5 und 470,93 € bei 8 Teilnehmenden (Prototyp 4.5).
- AK2: Gegeben Ausnahme Nichtmitglieder, dann ist der Vorschlag 210 € (+30 %, auf 5 € aufgerundet).
- AK3 (Fehler): Gegeben ein eigener Beitrag 150 € unter dem Vorschlag, dann wird er übernommen, aber die Warnung „Beitrag liegt unter dem kostendeckenden Vorschlag“ erscheint.
- AK4: Gegeben Mindestzahl leer, dann zeigt die Statusanzeige „Mindestanzahl fehlt“ und kein Beitrag.
- AK5: Gegeben Tagestour, Zielgruppe „Familienwanderungen“ und „Ohne Teilnahmebeitrag“, dann ist der Beitrag 0 und es erscheint „Ohne Teilnahmebeitrag trägt die Sektion {Kosten}.“
- AK6: Gegeben dieselben Eingaben, dann ergibt die Berechnung in der Datenbank auf den Cent dasselbe wie die Anzeige im Browser.
- AK7: Gegeben eine Gemeinschaftstour, dann gibt es keinen Teilnahmebeitrag; die Anzeige lautet „Gemeinschaftstour ohne Teilnahmebeitrag. Die Organisationspauschale ({Betrag}) trägt die Sektion.“ (Product Owner 22.10.2026).
**Nicht Teil dieser Story:** Pflege der Gebühren (Administration).

### US-TK-12: Pflichtangaben, Fortschritt und Hinweise sehen
**Als** Referent:in bzw. Geschäftsstelle
**möchte ich** jederzeit sehen, welche Pflichtangaben fehlen und welche Hinweise es gibt,
**damit** die Planung vollständig eingereicht wird.
**Priorität:** Must · **Regeln:** R6 (Prototyp 6.1–6.4) · **Abhängig von:** US-TK-03 bis US-TK-11
**Akzeptanzkriterien**
- AK1: Gegeben eine Planung, dann zeigt eine Seitenleiste Beitrag, CO2-Bilanz, Fortschritt „erfüllt/gesamt“ und je Schritt „fertig“ oder „n offen“ (Prototyp 6.4); mobil als Leiste unten.
- AK2: Gegeben die Pflichtangaben aus Prototyp 6.1 (ohne PDF-spezifische Punkte) plus „Leitung ohne zugeordnete Person“, dann wird jede genau einmal gezählt; ausgeblendete Felder zählen nicht.
- AK3: Gegeben Beginn in weniger als 6 Monaten, dann erscheint „Weniger als 6 Monate bis Tourbeginn“ als Hinweis (nicht blockierend).
- AK4 (Fehler): Gegeben ein Klick auf „n offen“, dann springt die Ansicht zum ersten offenen Feld und markiert alle offenen Felder rot.
- AK5 (Rechte): Gegeben Test Admin (TK lesen), dann sieht er Fortschritt und Hinweise, aber keine Bearbeitungsknöpfe.
**Nicht Teil dieser Story:** Hinweise per E-Mail.

### US-TK-13: Planung einreichen
**Als** Referent:in bzw. Geschäftsstelle
**möchte ich** eine vollständige Planung mit den Bestätigungen einreichen,
**damit** sie zur Freigabe bereitliegt.
**Priorität:** Must · **Regeln:** B4, R6 · **Abhängig von:** US-TK-12
**Akzeptanzkriterien**
- AK1: Gegeben eine vollständige Planung und gesetzte Bestätigungen c1–c4 (bei Gemeinschaftstour nur c4), wenn ich „Einreichen“ wähle, dann wechselt der Status auf „eingereicht“ mit Verlaufseintrag.
- AK2 (Fehler): Gegeben 3 offene Pflichtangaben, wenn ich einreiche, dann erscheint „Noch 3 Angaben offen.“ mit Liste, die offenen Felder werden markiert, der Status bleibt „Entwurf“.
- AK3: Gegeben das Feld „Wer legt das Angebot in Yolawo an?“, dann ist „Das Tourenreferat“ vorbelegt; „Ich selbst“ ist wählbar.
- AK4 (Rechte): Gegeben Test Admin (TK lesen), dann sieht er keinen Knopf „Einreichen“; ein direkter Aufruf der Datenbankfunktion liefert „Keine Berechtigung.“ (`TK_FORBIDDEN`).
**Nicht Teil dieser Story:** E-Mail-Benachrichtigung an das Referat [ANNAHME: nicht im MVP].

### US-TK-14: Rückfrage stellen und freigeben
**Als** Referent:in des Referats bzw. Person mit Freigaberecht
**möchte ich** eine eingereichte Planung prüfen, bearbeiten, mit Rückfrage zurückgeben oder freigeben,
**damit** nur geprüfte Touren und Kurse ins Programm kommen (Vergütungsordnung Ziff. 9).
**Priorität:** Must · **Regeln:** B4 · **Abhängig von:** US-TK-13; Administration (Rechtevorlage „Freigabe Touren und Kurse“ mit „darf freigeben“)
**Akzeptanzkriterien**
- AK1: Gegeben eine eingereichte Planung des Referats Touren und Fritz (Freigaberecht Touren), wenn er „Freigeben“ wählt, dann wechselt der Status auf „freigegeben“ mit Verlaufseintrag „freigegeben von Fritz Freigabe“ und optionalem Kommentar.
- AK2: Gegeben Fritz, dann darf er die Planung auch bearbeiten und „Rückfrage“ stellen (Product Owner 22.10.2026); Rückfrage verlangt einen Kommentar und setzt den Status auf „Rückfrage“.
- AK3 (Fehler): Gegeben eine Rückfrage ohne Kommentar, dann erscheint „Bitte die Rückfrage beschreiben.“
- AK4 (Fehler): Gegeben eine Leitung ohne zugeordnete Person oder offene Pflichtangaben, wenn freigegeben werden soll, dann erscheint „Freigabe nicht möglich: Angaben fehlen.“ mit Liste.
- AK5 (Rechte): Gegeben Fritz (Freigaberecht nur Touren) und eine Kurs-Planung (Referat Ausbildung), dann sieht er sie nicht; gegeben Anna Fiktiv (Geschäftsstelle), dann kann sie Rückfragen stellen, aber nicht freigeben [ANNAHME].
- AK6: Gegeben Tina mit Vorlage Referent:in Touren, dann darf sie freigeben, wenn ihr der Admin auch das Freigaberecht gegeben hat [ANNAHME: Startwert für alle Referent:innen Touren und Ausbildung]; ohne Freigaberecht fehlt der Knopf.
**Nicht Teil dieser Story:** Vergabe des Freigaberechts (Administration, durch den Admin).

### US-TK-15: Yolawo-Eingabeblatt und Ausschreibungstext nutzen
**Als** Referent:in bzw. Person mit Freigaberecht
**möchte ich** das Eingabeblatt Feld für Feld kopieren und den Ausschreibungstext übernehmen,
**damit** ich das Angebot in Yolawo schnell und fehlerfrei anlege.
**Priorität:** Must · **Regeln:** Prototyp 7.1, 7.2 · **Abhängig von:** US-TK-05 bis US-TK-11
**Akzeptanzkriterien**
- AK1: Gegeben die Beispieldaten, dann erzeugt das System Eingabeblatt und Ausschreibungstext wie Prototyp 7.1 und 7.2 (gleiche Gruppen, Felder, Reihenfolge, Texte), jedoch ohne die Zeilen zu Stornoregel und Rückerstattung (R11).
- AK2: Gegeben jedes Feld des Eingabeblatts, wenn ich „Kopieren“ wähle, dann liegt der Wert in der Zwischenablage und es erscheint „Kopiert“.
- AK3 (Fehler): Gegeben leere Felder, dann erscheinen sie rot als „fehlt“.
- AK4: Gegeben Notfallkontakte und interne Felder, dann erscheinen sie nicht im Ausschreibungstext und nicht im Eingabeblatt.
- AK5 (Rechte): Gegeben Test Admin (TK lesen), dann sieht er Eingabeblatt und Text (lesen).
**Nicht Teil dieser Story:** automatische Übertragung nach Yolawo.

### US-TK-16: Als „in Yolawo angelegt“ markieren und Einsatz erzeugen
**Als** Referent:in bzw. Person mit Freigaberecht
**möchte ich** eine freigegebene Planung als „in Yolawo angelegt“ markieren,
**damit** der Einsatz in der Anwesenheitserfassung ohne erneutes Eintippen entsteht.
**Priorität:** Must · **Regeln:** R7, B5 · **Abhängig von:** US-TK-14; Anwesenheitserfassung (`ez_upsert_planned_event`, Übergabe v1.3)
**Akzeptanzkriterien**
- AK1: Gegeben eine freigegebene Planung, wenn ich „In Yolawo angelegt“ wähle (optional Link oder Nummer des Angebots), dann wechselt der Status, und in der Anwesenheitserfassung entsteht genau ein Einsatz (Kurs bzw. Tour) mit Referat, Titel, Zeiten, organisierender Person (erste Leitung) und allen Leitenden und Helfenden mit Rolle Trainer:in bzw. Helfer:in im Stand „eingetragen“.
- AK2: Gegeben der Einsatz existiert und ich ändere Termin oder Leitung, wenn ich speichere, dann wird der Einsatz aktualisiert, solange keine Anwesenheit „anwesend“ eingetragen ist.
- AK3 (Fehler): Gegeben eine Anwesenheit „anwesend“ existiert, wenn ich den Termin ändere, dann wird die Planung gespeichert, der Einsatz nicht, und es erscheint „Der Einsatz ist schon erfasst und wurde nicht geändert. Bitte in der Anwesenheitserfassung anpassen.“
- AK4 (Fehler): Gegeben die Anwesenheitserfassung ist nicht verfügbar, wenn ich markiere, dann wird nichts geändert und es erscheint „Einsatz konnte nicht angelegt werden. Bitte später erneut versuchen.“ (eine Transaktion).
- AK5 (Rechte): Gegeben Anna Fiktiv (Geschäftsstelle), dann darf sie markieren; Test Admin nicht.
- AK6: Gegeben ein Titel mit bis zu 90 Zeichen, dann wird er ungekürzt in den Einsatz übernommen.
- AK7: Gegeben eine Gemeinschaftstour, dann erhält der Einsatz die Abrechnungsart „Gemeinschaftstour“; bei Kurs und Führungstour die Vorbelegung der Anwesenheitserfassung (Product Owner 26.10.2026).
**Nicht Teil dieser Story:** Erfassung der Anwesenheit (Anwesenheitserfassung); Teilnehmende.

### US-TK-17: Planung absagen
**Als** Referent:in, Person mit Freigaberecht bzw. Geschäftsstelle
**möchte ich** eine Planung mit Grund absagen,
**damit** sie nicht mehr im Programm, in der Abrechnung und in Auswertungen zählt.
**Priorität:** Must · **Regeln:** B4, B5 · **Abhängig von:** US-TK-02; Anwesenheitserfassung (`ez_cancel_planned_event`)
**Akzeptanzkriterien**
- AK1: Gegeben eine Planung vor „durchgeführt“, wenn ich „Absagen“ mit Grund wähle, dann wechselt der Status auf „abgesagt“ mit Verlaufseintrag.
- AK2: Gegeben ein vorhandener Einsatz, dann wird er in der Anwesenheitserfassung als „abgesagt“ markiert, nicht gelöscht (Product Owner 22.10.2026).
- AK3 (Fehler): Gegeben kein Grund, dann erscheint „Bitte einen Grund angeben.“
- AK4 (Fehler): Gegeben Status „durchgeführt“, dann gibt es keinen Knopf „Absagen“.
- AK5 (Rechte): Gegeben Test Admin, dann kann er nicht absagen.
- AK6: Gegeben eine abgesagte Planung, dann ist sie nur lesbar; die Kostenauswertung blendet sie standardmäßig aus.
**Nicht Teil dieser Story:** Erstattung bereits angefallener Kosten [OFFEN, Finanzen]; Information der Angemeldeten (Yolawo).

### US-TK-18: Planung als durchgeführt und abgeschlossen markieren
**Als** Referent:in bzw. Geschäftsstelle
**möchte ich** eine Planung nach der Tour als „durchgeführt“ und nach der Abrechnung als „abgeschlossen“ markieren,
**damit** der Stand stimmt und die Notfallkontakte gelöscht werden.
**Priorität:** Should · **Regeln:** B4, R8 · **Abhängig von:** US-TK-16
**Akzeptanzkriterien**
- AK1: Gegeben Status „in Yolawo angelegt“ und Enddatum in der Vergangenheit, wenn Tina „Durchgeführt“ wählt, dann wechselt der Status [ANNAHME: manuell im MVP; Übernahme aus der Anwesenheitserfassung später].
- AK2 (Fehler): Gegeben Enddatum in der Zukunft, dann erscheint „Die Tour ist noch nicht vorbei.“
- AK3: Gegeben „durchgeführt“, wenn Anna Fiktiv „Abgeschlossen“ wählt, dann wechselt der Status; danach ist die Planung nur lesbar.
- AK4 (Rechte): Gegeben Tina, dann darf sie nicht „abgeschlossen“ setzen (nur Geschäftsstelle) [ANNAHME].
**Nicht Teil dieser Story:** Abrechnung (Finanzen).

### US-TK-19: Sätze aus der Administration verwenden
**Als** Referent:in bzw. Geschäftsstelle
**möchte ich**, dass jede Kalkulation die zum Startdatum gültigen Sätze, Pauschalen, Gebühren und Faktoren aus den Stammdaten der Administration verwendet und den Satzstand speichert,
**damit** Änderungen der Vergütungs- oder Reisekostenordnung ohne Code-Änderung wirken und nachvollziehbar bleibt, womit gerechnet wurde.
**Priorität:** Must · **Regeln:** R3, C2 · **Abhängig von:** Administration (Stammdaten Sätze; Pflege nur durch den Admin, Übergabe v1.5)
**Akzeptanzkriterien**
- AK1: Gegeben die Stammdaten mit Startbestand (Prototyp 5.1–5.3, Grenzwerte 5.4, ohne Stornoregel), wenn eine Planung berechnet wird, dann verwendet sie je Schlüssel den Wert mit dem spätesten „gültig ab“ ≤ Startdatum.
- AK2: Gegeben „Organisationspauschale = 12 € gültig ab 01.01.2028“ in der Administration, dann rechnen Planungen mit Startdatum ab 01.01.2028 im Status „Entwurf“ oder „eingereicht“ mit 12 €, ältere mit 10 €; freigegebene Planungen behalten ihren gespeicherten Satzstand (R3).
- AK3: Gegeben eine Planung, dann zeigt sie in Schritt 6 „Gerechnet mit Sätzen gültig ab …“ und je Satz Wert und Quelle (nur lesen).
- AK4 (Fehler): Gegeben für einen Schlüssel gibt es keinen Wert am Startdatum, dann erscheint „Für {Bezeichnung} ist zum {Datum} kein Satz hinterlegt. Bitte den Admin informieren.“ und Einreichen ist gesperrt.
- AK5 (Rechte): Gegeben Tina oder Anna Fiktiv, dann können sie Sätze nicht ändern; gepflegt wird nur vom Admin in der Administration (Product Owner 22.10.2026).
**Nicht Teil dieser Story:** Pflegeoberfläche der Sätze (Administration).

### US-TK-20: Kostenauswertung über alle Planungen
**Als** Geschäftsstelle bzw. Referent:in
**möchte ich** die geplanten Kosten aller lesbaren Planungen mit Summen sehen und exportieren,
**damit** wir das Programm finanziell überblicken (erste Auswertung, Product Owner 22.10.2026).
**Priorität:** Must · **Regeln:** B9 · **Abhängig von:** US-TK-11
**Akzeptanzkriterien**
- AK1: Gegeben Filter Jahr 2027 und Referat Touren, dann zeigt die Auswertung je Planung Titel, Tourtyp, Termin, Status, Vergütung, Organisationspauschale, Kosten der Leitung, sonstige Kosten, Gesamtkosten, Beitrag Mitglieder, Mindest-/Höchstzahl, Ergebnis bei Mindest- und Höchstzahl, „Sektion trägt“ – und eine Summenzeile [ANNAHME: Spalten].
- AK2: Gegeben abgesagte Planungen, dann sind sie standardmäßig ausgeblendet und per Filter einblendbar.
- AK3 (Rechte): Gegeben Tina, dann enthält die Auswertung nur Planungen des Referats Touren; CSV-Export nur für Geschäftsstelle (verwalten) [ANNAHME].
- AK4 (leer): Gegeben keine passenden Planungen, dann erscheint „Keine Planungen für diese Auswahl.“ und Summen 0.
- AK5: Gegeben der CSV-Export, dann enthält er keine Kontakt- oder Notfalldaten.
**Nicht Teil dieser Story:** CO2-Auswertung (Iteration 1); Ist-Kosten.

### US-TK-21: Planung als PDF exportieren
**Als** Referent:in bzw. Geschäftsstelle
**möchte ich** eine Planung als PDF speichern,
**damit** ich sie weitergeben oder ablegen kann.
**Priorität:** Should · **Regeln:** Prototyp 7.5 (ohne eingebettete Daten) · **Abhängig von:** US-TK-15
**Akzeptanzkriterien**
- AK1: Gegeben eine Planung, dann erzeugt das PDF Aufbau und Dateiname wie Prototyp 7.5 (Abschnitte 1–9), im Browser, ohne externe Abrufe.
- AK2: Gegeben eine unvollständige Planung, dann trägt das PDF den Hinweis „Noch unvollständig. Es fehlen: …“.
- AK3 (Rechte): Gegeben Test Admin (TK lesen), dann enthält sein PDF keine Kontakt- und Notfalldaten [ANNAHME].
- AK4 (Fehler): Gegeben der Browser blockiert Downloads, dann erscheint „PDF konnte nicht gespeichert werden.“
**Nicht Teil dieser Story:** eingebettete Formulardaten.

### US-TK-22: Notfallkontakte automatisch löschen
**Als** Geschäftsstelle (für die Sektion als Verantwortliche)
**möchte ich**, dass Notfallkontakte nach der Tour automatisch gelöscht werden,
**damit** Daten Dritter nicht länger als nötig gespeichert sind.
**Priorität:** Must · **Regeln:** R8, B8 · **Abhängig von:** US-TK-04
**Akzeptanzkriterien**
- AK1: Gegeben eine Planung mit Enddatum vor mehr als 14 Tagen [OFFEN: Frist] und Status „in Yolawo angelegt“, „durchgeführt“, „abgeschlossen“ oder „abgesagt“, wenn der tägliche Job läuft, dann werden Name und Telefon aller Notfallkontakte und die Mobilnummern der Leitung gelöscht [ANNAHME: Mobilnummer auch].
- AK2: Gegeben die Löschung, dann zeigt die Planung „Notfallkontakte gelöscht am …“ und der Verlauf einen Eintrag (ohne Inhalte).
- AK3: Gegeben eine abgesagte Planung, dann gilt die Frist ab dem Datum der Absage [ANNAHME].
- AK4 (Fehler): Gegeben der Job schlägt fehl, dann läuft er am nächsten Tag erneut und erfasst alle fälligen Planungen.
- AK5 (Rechte): Gegeben niemand, dann kann gelöschte Notfalldaten wiederherstellen (keine Historie der Werte).
**Nicht Teil dieser Story:** Löschung im E-Mail-Postfach des Referats.

### US-TK-23: Planung kopieren
**Als** Referent:in bzw. Geschäftsstelle
**möchte ich** eine frühere Planung kopieren,
**damit** ich wiederkehrende Touren und Kurse nicht neu eingeben muss.
**Priorität:** Could · **Regeln:** B1 · **Abhängig von:** US-TK-02
**Akzeptanzkriterien**
- AK1: Gegeben eine lesbare Planung, wenn ich „Kopieren“ wähle, dann entsteht ein Entwurf mit allen Inhalten außer Termin, Anmeldeschluss, Vorbesprechungsdatum, Status, Verlauf, Einsatz, Yolawo-Angebot, Kontakt- und Notfalldaten und Bestätigungen.
- AK2: Gegeben die Kopie, dann rechnet sie mit den aktuellen Sätzen.
- AK3 (Rechte): Gegeben eine Planung eines anderen Referats, dann kann ich sie nicht kopieren.
- AK4 (Fehler): Gegeben eine Person der Leitung ist nicht mehr „aktiv“, dann wird sie nicht übernommen, Hinweis „Bernd Berg ist nicht mehr aktiv und wurde entfernt.“
**Nicht Teil dieser Story:** Vorlagen.

### US-TK-24: Planwerte für die Abrechnung bereitstellen
**Als** Geschäftsstelle (in Finanzen)
**möchte ich** die Planwerte einer Tour als Vorbelegung der Abrechnung lesen,
**damit** Tage, Satzart und Kosten der Leitung nicht neu eingetippt werden.
**Priorität:** Should · **Regeln:** B6 · **Abhängig von:** US-TK-10; Finanzen (Übergabe v1.2)
**Akzeptanzkriterien**
- AK1: Gegeben eine Planung ab „in Yolawo angelegt“, wenn `tk_settlement_draft(plan_id)` aufgerufen wird, dann liefert die Funktion Personen mit Satzart, Tage, Halbtage, Lehreinheiten, Organisationstage, Kostenpositionen der Leitung, PKW-Begründung, Gesamtkosten, Beitrag und Satzstand.
- AK2 (Fehler): Gegeben eine abgesagte Planung, dann liefert die Funktion `TK_PLAN_CANCELLED`.
- AK3 (Rechte): Gegeben ein Nutzer ohne FI- oder TK-verwalten-Recht, dann `TK_FORBIDDEN`.
**Nicht Teil dieser Story:** Oberfläche in Finanzen.

---

## Annahmen dieser Stories (vom Product Owner zu bestätigen)

- A1: Referat folgt aus dem Tourtyp (Kurs → Ausbildung, sonst Touren), nicht frei wählbar (US-TK-02).
- A2: Freigaberecht als eigene Rechtevorlage (TK bearbeiten + darf freigeben); Startwert für alle Referent:innen Touren und Ausbildung; Geschäftsstelle gibt nicht frei, darf aber Rückfragen stellen (US-TK-14).
- A3: Admin (TK lesen) sieht keine Kontakt- und Notfalldaten (US-TK-04, US-TK-21).
- A4: entfällt (Titel ungekürzt, Anwesenheitserfassung erlaubt 90 Zeichen).
- A5: „durchgeführt“ manuell im MVP; „abgeschlossen“ nur Geschäftsstelle (US-TK-18).
- A6: Löschfrist Notfallkontakte 14 Tage nach Enddatum bzw. Absage, inkl. Mobilnummer der Leitung (US-TK-22).
- A7: Spalten der Kostenauswertung; CSV nur Geschäftsstelle (US-TK-20).
- A8: Keine E-Mail-Benachrichtigungen im MVP (US-TK-13).
- A9: Externe Leitende ohne Ehrenamtsstatus sind im MVP nicht wählbar; sie müssen vorher im Ehrenamtsmanagement angelegt werden (US-TK-03).
- A10: Bestätigung c1 bleibt eine Bestätigung (keine automatische Prüfung im Ehrenamtsmanagement).
- A12: bestätigt 22.10.2026 – bei Gemeinschaftstouren trägt vorerst die Sektion die Organisationspauschale; kein Teilnahmebeitrag (US-TK-11 AK7).
- A11: Wer „in Yolawo angelegt“ setzt, wenn die Tourenleitung selbst anlegt: Referent:in oder Person mit Freigaberecht nach Rückmeldung.

## Offen vor der Spec

- [OFFEN] Gemeinschaftstour: Später klären, ob die Organisationspauschale von den Teilnehmenden zurückgeholt wird (Umlage oder kleiner Beitrag); bis dahin trägt sie die Sektion (Product Owner 22.10.2026).
- [OFFEN] Echte Gültig-ab-Daten der Sätze; Annahmen des Prototyps (MwSt. 19 %, Konditionsgrenzen, Technikstufen, Qualifikation → Sportart, Hüttenpreise) – Referat Touren.
- Erledigt 24.10.2026: Titel 90 Zeichen in der Anwesenheitserfassung.
