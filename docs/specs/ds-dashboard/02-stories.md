# Stories: Dashboard

Stand: 26.10.2026 · Version 0.2 · Kürzel: DS · Status: Entwurf
Quellen: 00-steckbrief.md (v0.13), 01-erhebung.md (v0.1, Regeln R1–R24), sichten.md (v0.8), uebergabe-finanzen.md (v1.7), uebergabe-administration.md (v1.3), glossar.md (v1.7).
Umfang: MVP – Budget-Sicht (Blöcke ② und ④, Einzelbuchungen, Vorjahr, Vorschau), Budgetpflege (Finanzplan, Gesamtbudgets, Zuordnung, Import, Umschlüsseln), Pflege durch Referent:innen (Hinweis, Umschichtung, Umschlüsselungs-Vorschlag), Block ① „Zu tun“ im MVP-Umfang, Druckansicht, Startseite. Iteration 1 (Referats-Kennzahlen, Gruppendetail) folgt mit den Übergaben an GR, EZ, EA, TK.
Änderungen v0.2: Die Stories der Budgetpflege (bisher US-DS-01 bis US-DS-06, US-DS-21, US-DS-22) stehen jetzt als US-FI-22 bis US-FI-29 in specs/fi-finanzen/02-stories.md (Finanzen fertig, (Product Owner 26.10.2026)); Vertretung beim Bestätigen durch die Schatzmeister:in; Abgleich der Vorschau über Betrag und Datum; Übernahme ins neue Jahr als Vorschlag.
Änderungen v0.1: Erster Entwurf.

Beispiele sind fiktiv (Personen, Gruppen, Beträge, Buchungstexte).

**Umsetzung:** Stories mit „DS“ sind Oberfläche und Lesefunktionen des Dashboards. Die Budgetpflege (Finanzplan, Gesamtbudgets, Zuordnung, Übernahme aus dem Prototyp, DATEV-Import, Umschlüsseln, Löschlauf, neues Jahr) steht als **US-FI-22 bis US-FI-29** in specs/fi-finanzen/02-stories.md (Nachtrag v0.3 „Bereich Budget“); Stories mit „FI-Budget“ hier brauchen zusätzlich Tabellen und Funktionen dort.

## Zusätzliche Regeln (Ergänzung zu 01-erhebung.md, Abschnitt D)

- **R25 – Nur lesen ohne Recht:** Wer kein Kennzeichen „darf Budget pflegen“ hat, sieht keine Schaltflächen für Einlesen, Import, Zuordnung und Entscheidungen über Anträge; Referent:innen sehen „Hinweis eintragen“, „Umschichtung beantragen“ und „Umschlüsselung vorschlagen“ nur bei Budgetposten des eigenen Referats. Direkte Aufrufe lehnt die Datenbank ab: „Für diesen Bereich hast du keine Rechte.“
- **R26 – Leere Zustände:** ohne Finanzplan „Für 2027 ist noch kein Finanzplan eingelesen.“; ohne Import „Noch kein DATEV-Export für 2027 eingespielt.“; ohne Budget des Referats „Für dein Referat gibt es keinen Budgetposten im Finanzplan.“

## Übersicht

| ID | Titel | Priorität | Rechtevorlage | Umsetzung |
|---|---|---|---|---|
| US-FI-22 | Finanzplan einlesen | Must | Budgetpflege | → Finanzen (Nachtrag v0.3) |
| US-FI-23 | Gesamtbudgets einem Referat zuordnen | Must | Budgetpflege | → Finanzen (Nachtrag v0.3) |
| US-FI-24 | Zuordnung Konto → Budgetposten pflegen | Must | Budgetpflege | → Finanzen (Nachtrag v0.3) |
| US-FI-25 | Zuordnung aus dem Prototyp übernehmen | Must | Budgetpflege | → Finanzen (Nachtrag v0.3) |
| US-FI-26 | DATEV-Export einspielen | Must | Budgetpflege | → Finanzen (Nachtrag v0.3) |
| US-FI-27 | Buchung umschlüsseln | Must | Budgetpflege | → Finanzen (Nachtrag v0.3) |
| US-DS-07 | Budget meines Referats ansehen | Must | Referent:in | DS |
| US-DS-08 | Budget des Vereins ansehen | Must | alle mit DS lesen | DS |
| US-DS-09 | Einzelbuchungen eines Budgetpostens ansehen | Must | alle mit DS lesen | DS |
| US-DS-10 | Vorjahr zum gleichen Stichtag | Must | alle mit DS lesen | DS, FI-Budget |
| US-DS-11 | Hinweis zu einem Budgetposten eintragen | Must | Referent:in, Budgetpflege | FI-Budget, DS |
| US-DS-12 | Umschichtung beantragen | Must | Referent:in | FI-Budget, DS |
| US-DS-13 | Umschichtung bestätigen oder ablehnen | Must | Budgetpflege | FI-Budget, DS |
| US-DS-14 | Umschlüsselung vorschlagen | Must | Referent:in | FI-Budget, DS |
| US-DS-15 | Umschlüsselungs-Vorschlag entscheiden | Must | Budgetpflege | FI-Budget, DS |
| US-DS-16 | Vorschau abgerechneter Vergütung | Should | alle mit DS lesen | DS, FI |
| US-DS-17 | Zu tun (MVP) | Must | alle mit DS lesen | DS |
| US-DS-18 | Prüfung und nicht zugeordnete Buchungen | Must | Vorstand, Geschäftsstelle, Admin, Budgetpflege | DS |
| US-DS-19 | Druckansicht für die Vorstandssitzung | Must | alle mit DS lesen | DS |
| US-DS-20 | Dashboard als Startseite | Should | alle mit DS lesen | DS, AD |
| US-FI-28 | Einzelbuchungen nach Frist löschen | Must | System | → Finanzen (Nachtrag v0.3) |
| US-FI-29 | Neues Budgetjahr anlegen | Should | Budgetpflege | → Finanzen (Nachtrag v0.3) |

---

### US-DS-07: Budget meines Referats ansehen

**Als** Referent:in
**möchte ich** das Budget meines Referats mit Plan, verbraucht, frei und Ampel sehen,
**damit** ich weiß, ob mein Geld reicht, ohne nachfragen zu müssen.
**Priorität:** Must · **Regeln:** R6, R7, R12, R26 · **Abhängig von:** US-FI-23, US-FI-26; Übergabe AD D1–D4

**Akzeptanzkriterien**
- AK1: Gegeben ich bin Referentin Kinder und Jugend, wenn ich das Dashboard öffne, dann sehe ich Block ② mit dem Gesamtbudget „Kinder und Jugend“: Plan (aktuell und beschlossen), verbraucht, frei, Verbrauch in %, Ampel, Datenstand, und je Budgetposten einen Balken mit Strich für den Jahresfortschritt.
- AK2: Gegeben „Ausbildung KiJu“ hat 87 % des aktuellen Plans verbraucht, dann ▲; über 100 % ■; unter 80 % ● (R6).
- AK3: Einnahmen zeigen „erreicht“ und „fehlt noch“.
- AK4: Gegeben ich bin Referent:in mehrerer Referate, dann wähle ich das Referat oben; Standard ist das erste [ANNAHME].
- AK5 (leer): Referat Sulzenauhütte → „Für dein Referat gibt es keinen Budgetposten im Finanzplan.“ (R26)
- AK6 (Rechte): ohne DS lesen ist der Menüpunkt „Dashboard“ nicht sichtbar, ein direkter Aufruf zeigt „Für diesen Bereich hast du keine Rechte.“

### US-DS-08: Budget des Vereins ansehen

**Als** Person mit DS lesen
**möchte ich** alle Gesamtbudgets des Vereins als Summen sehen,
**damit** ich Anträge und Umschichtungen einordnen kann.
**Priorität:** Must · **Regeln:** R6, R12 · **Abhängig von:** US-DS-07

**Akzeptanzkriterien**
- AK1: Gegeben ich bin Referent:in, dann sehe ich Block ④ zugeklappt; aufgeklappt alle Gesamtbudgets mit Verbrauch in % und Ampel, mein Referat hervorgehoben.
- AK2: Klick auf ein fremdes Gesamtbudget zeigt seine Budgetposten mit Summen, aber keine Einzelbuchungen (R13).
- AK3: Vorstand, Geschäftsstelle und Admin sehen „Verein“ als eigene Sicht mit Kopf (Gesamtbudget, verbraucht, frei, Einnahmen) und den Gesamtbudgets sortiert nach Ampel.
- AK4 (Rechte): Gruppenleitungen (später) sehen Block ④ nicht (Q-DS8).

### US-DS-09: Einzelbuchungen eines Budgetpostens ansehen

**Als** Person mit DS lesen
**möchte ich** die Buchungen eines Budgetpostens sehen,
**damit** ich nachvollziehen kann, wofür das Geld ausgegeben wurde.
**Priorität:** Must · **Regeln:** R13, R14 · **Abhängig von:** US-DS-07

**Akzeptanzkriterien**
- AK1: Gegeben ich bin Referentin Kinder und Jugend, wenn ich „Kinder und Jugend Kosten“ öffne, dann sehe ich Summe je Konto und alle Buchungen (Datum, Konto, Buchungstext, Beleg, Betrag), sortier- und durchsuchbar.
- AK2: Umgeschlüsselte Buchungen tragen das Etikett „umgeschlüsselt“; Buchungen mit offenem Vorschlag das Etikett „Vorschlag offen“.
- AK3: Bei „Veranstaltungen“ (alle) sehe ich die Buchungen ebenfalls.
- AK4 (Rechte): Bei „Leistungssport Kosten“ (anderes Referat) sehe ich nur die Summe; die Datenbank liefert keine Buchungen (R13).
- AK5 (Rechte): Nicht zugeordnete Buchungen sehe ich als Referent:in nicht (R14).

### US-DS-10: Vorjahr zum gleichen Stichtag

**Als** Person mit DS lesen
**möchte ich** neben jedem Betrag den Wert des Vorjahres zum gleichen Stichtag sehen,
**damit** ich einschätzen kann, ob wir schneller oder langsamer ausgeben als sonst.
**Priorität:** Must · **Regeln:** R19, R20 · **Abhängig von:** US-FI-26 (zwei Jahre importiert)

**Akzeptanzkriterien**
- AK1: Gegeben der Datenstand 2027 ist der 30.09.2027, dann steht neben „verbraucht“ der Wert vom 30.09.2026 mit ▲/▼ und auf Wunsch das ganze Vorjahr.
- AK2: Gegeben ein Budgetposten gibt es im Vorjahr nicht unter gleichem Namen und Gesamtbudget, dann steht „neu“.
- AK3: Vergleich nur mit dem Vorjahr, nie mit früheren Jahren (Q-DS19).
- AK4 (leer): ohne Import des Vorjahres steht „kein Vorjahr“.
- AK5 (Rechte): Für Budgetposten fremder Referate nur die Summen des Vorjahres.

### US-DS-11: Hinweis zu einem Budgetposten eintragen

**Als** Referent:in
**möchte ich** zu einem Budgetposten meines Referats einen Hinweis schreiben,
**damit** alle sehen, was noch kommt (z. B. eine erwartete Rechnung).
**Priorität:** Must · **Regeln:** R17, R25 · **Abhängig von:** US-DS-07

**Akzeptanzkriterien**
- AK1: Gegeben „Kinder und Jugend Kosten“, wenn ich „Rechnung Herbstfahrt kommt im Oktober (ca. 1.800 €)“ eintrage, dann steht der Hinweis in der Zeile des Postens für alle mit Budget-Sicht, mit meinem Namen und Datum.
- AK2: Ändern ersetzt den Hinweis; der frühere bleibt im Verlauf.
- AK3: Die Budgetpflege kann Hinweise zu allen Budgetposten schreiben.
- AK4 (Fehler): mehr als 500 Zeichen → „Der Hinweis darf höchstens 500 Zeichen haben.“
- AK5 (Rechte): Bei Budgetposten anderer Referate sehe ich „Hinweis eintragen“ nicht; ein direkter Aufruf wird abgelehnt.

### US-DS-12: Umschichtung beantragen

**Als** Referent:in
**möchte ich** Plan zwischen zwei Budgetposten meines Gesamtbudgets umschichten,
**damit** ich auf Bedarf reagieren kann, ohne das Budget des Vereins zu ändern.
**Priorität:** Must · **Regeln:** R15, R24, R25 · **Abhängig von:** US-DS-07

**Akzeptanzkriterien**
- AK1: Gegeben „Kinder und Jugend Kosten“ (Plan 30.000 €) und „Ausbildung KiJu“ (Plan 6.000 €), wenn ich 500 € mit Grund „mehr Ausbildungsplätze“ beantrage, dann ist der Antrag „beantragt“, die Pläne bleiben unverändert, und unter „Zu tun“ sehe ich „Umschichtung wartet auf Bestätigung“.
- AK2: Solange „beantragt“, kann ich zurückziehen.
- AK3: Nach Bestätigung zeigt die Sicht aktuellen Plan 29.500 € bzw. 6.500 € und den beschlossenen Plan daneben; die Summe des Gesamtbudgets bleibt gleich.
- AK4 (Fehler): Ziel in einem anderen Gesamtbudget oder andere Art → „Umschichten geht nur zwischen Posten desselben Gesamtbudgets und derselben Art.“; Betrag über dem aktuellen Plan → „Der Betrag ist höher als der Plan von ‚…‘.“
- AK5 (Rechte): bei Gesamtbudgets anderer Referate, „alle“ oder „ohne Referat“ keine Schaltfläche; direkter Aufruf abgelehnt.

### US-DS-13: Umschichtung bestätigen oder ablehnen

**Als** Person mit Budgetpflege
**möchte ich** beantragte Umschichtungen bestätigen oder mit Grund ablehnen,
**damit** der Plan nur mit Vier-Augen-Prinzip geändert wird.
**Priorität:** Must · **Regeln:** R15, R21, R24 · **Abhängig von:** US-DS-12

**Akzeptanzkriterien**
- AK1: Unter „Zu tun“ sehe ich „1 Umschichtung wartet auf Bestätigung“; die Liste zeigt Referat, von, nach, Betrag, Grund, Antragsteller:in, Datum.
- AK2: Bestätigen → Zustand „bestätigt“, Pläne geändert; die Referent:in sieht unter „Zu tun“ das Ergebnis.
- AK3: Ablehnen nur mit Grund; die Referent:in sieht den Grund.
- AK4 (Fehler): Ist R15 inzwischen verletzt (z. B. Plan durch neues Einlesen gesunken), dann „Die Umschichtung passt nicht mehr zum Plan. Bitte ablehnen oder neu beantragen lassen.“
- AK5 (Rechte): Einen eigenen Antrag kann ich nicht selbst bestätigen; dann bestätigt die **Schatzmeister:in** als anderes Mitglied des Vorstands (Product Owner 26.10.2026). Ohne Budgetpflege keine Schaltflächen.

### US-DS-14: Umschlüsselung vorschlagen

**Als** Referent:in
**möchte ich** für eine Buchung meines Budgets einen anderen Budgetposten vorschlagen,
**damit** Fehlbuchungen korrigiert werden, ohne dass ich selbst umschlüsseln darf.
**Priorität:** Must · **Regeln:** R16, R24, R25 · **Abhängig von:** US-DS-09

**Akzeptanzkriterien**
- AK1: Gegeben die Buchung „Seile Leistungsgruppe“ steht bei „Kinder und Jugend Kosten“, wenn ich „Leistungssport Kosten“ mit Grund vorschlage, dann trägt die Buchung „Vorschlag offen“, zählt aber weiter bei Kinder und Jugend.
- AK2: Solange „vorgeschlagen“, kann ich zurückziehen; je Buchung nur ein offener Vorschlag.
- AK3: Nach Entscheidung sehe ich unter „Zu tun“ „angenommen“ bzw. „abgelehnt“ mit Grund.
- AK4 (Fehler): ohne Grund → „Bitte einen Grund angeben.“
- AK5 (Rechte): für Buchungen anderer Referate keine Schaltfläche; direkter Aufruf abgelehnt (R16).

### US-DS-15: Umschlüsselungs-Vorschlag entscheiden

**Als** Person mit Budgetpflege
**möchte ich** Vorschläge der Referent:innen annehmen oder ablehnen,
**damit** die Zuordnung richtig wird und ich nicht selbst nach Fehlbuchungen suchen muss.
**Priorität:** Must · **Regeln:** R16, R21, R24 · **Abhängig von:** US-DS-14, US-FI-27

**Akzeptanzkriterien**
- AK1: „Annehmen“ legt eine Einzelbuchungsregel an (wie US-FI-27); ich kann stattdessen „alle Buchungen auf Konto …“ wählen.
- AK2: „Ablehnen“ nur mit Grund.
- AK3: Unter „Zu tun“ sehe ich die Anzahl offener Vorschläge.
- AK4 (Fehler): Buchung im neuen Import nicht mehr vorhanden → Vorschlag wird als „gegenstandslos“ markiert [ANNAHME].
- AK5 (Rechte): ohne Budgetpflege keine Schaltflächen.

### US-DS-16: Vorschau abgerechneter Vergütung

**Als** Referent:in
**möchte ich** sehen, wie viel Vergütung schon abgerechnet, aber noch nicht gebucht ist,
**damit** ich nicht mit Geld plane, das schon vergeben ist.
**Priorität:** Should · **Regeln:** R18 · **Abhängig von:** Finanzen (Auszahlungsrunden); Abgleich „noch nicht gebucht“ über Betrag und Datum der Auszahlungsrunde auf dem Konto des Budgetpostens „Vergütung Aktive“ (Product Owner 26.10.2026)

**Akzeptanzkriterien**
- AK1: Gegeben 3.250 € abgeschlossen und ausgezahlt im 2. Halbjahr, noch nicht im Import, dann steht am Posten „Vergütung Aktive“ „Vorschau +3.250 € · nicht im Ist“ mit schraffiertem Balkenstück.
- AK2: Verbraucht, frei und Ampel ändern sich dadurch nicht.
- AK3: Übersteigen Ist und Vorschau den aktuellen Plan, dann ▲ „mit Vorschau über Plan“.
- AK4: Sobald die Auszahlung im Import gebucht ist, verschwindet sie aus der Vorschau.
- AK5 (Rechte): Vorschau nur als Summe je Referat; keine Namen oder Beträge einzelner Personen.

### US-DS-17: Zu tun (MVP)

**Als** Person mit DS lesen
**möchte ich** oben sehen, was ich erledigen muss,
**damit** ich nichts übersehe.
**Priorität:** Must · **Regeln:** R23 · **Abhängig von:** US-DS-12 bis US-DS-15; FI (Bestätigung von Abrechnungen)

**Akzeptanzkriterien**
- AK1 (Referent:in): eigene Anträge und Vorschläge mit Zustand (Z4); Abrechnungen meines Referats, die auf meine Bestätigung warten, mit Tagen bis zur Frist (Z1).
- AK2 (Budgetpflege): offene Umschichtungen und Vorschläge, nicht zugeordnete Buchungen, unsichere Zuordnungen, Datenstand älter als 6 Wochen (Z8, R23).
- AK3: Jeder Punkt hat einen Link zur Stelle, an der man ihn erledigt.
- AK4 (leer): „Nichts zu tun.“
- AK5 (Rechte): Punkte erscheinen nur, wenn die Person sie auch erledigen darf.

**Nicht Teil dieser Story:** Punkte aus GR, EA, TK, EZ (Iteration 1).

### US-DS-18: Prüfung und nicht zugeordnete Buchungen

**Als** Vorstand oder Person mit Budgetpflege
**möchte ich** die nicht zugeordneten Buchungen und das Prüfergebnis des letzten Imports sehen,
**damit** keine Buchung verloren geht und ich unvollständige Exporte erkenne.
**Priorität:** Must · **Regeln:** R8, R14 · **Abhängig von:** US-FI-26

**Akzeptanzkriterien**
- AK1: Abschnitt „Nicht zugeordnete Buchungen“ mit Summe je Konto und Buchungen.
- AK2: Abschnitt „Prüfung“: je Konto Einzelbuchungen = Kontenübersicht ✓/✗; ausgewertet = Ausgaben − Einnahmen + nicht zugeordnet ✓/✗; Liste umgeschlüsselter Buchungen mit Warnung, wenn sie fehlen.
- AK3: Von einer nicht zugeordneten Buchung aus kann die Budgetpflege direkt eine Regel anlegen.
- AK4 (Rechte): Referent:innen sehen beide Abschnitte nicht (R14).

### US-DS-19: Druckansicht für die Vorstandssitzung

**Als** Person mit DS lesen
**möchte ich** die Budget-Sicht drucken,
**damit** ich sie in der Vorstandssitzung oder Referatssitzung auf Papier habe.
**Priorität:** Must · **Abhängig von:** US-DS-07, US-DS-08

**Akzeptanzkriterien**
- AK1: „Drucken“ erzeugt A4 quer mit allen Gesamtbudgets aufgeklappt, Datenstand und Druckdatum im Kopf.
- AK2: Ist eine Detailansicht offen, wird nur sie gedruckt.
- AK3: Ampeln mit Form und Wort, auch in Schwarz-Weiß lesbar.
- AK4 (Rechte): gedruckt wird nur, was die Person sieht (keine Einzelbuchungen fremder Referate).

### US-DS-20: Dashboard als Startseite

**Als** Person mit DS lesen
**möchte ich** nach der Anmeldung direkt mein Dashboard sehen,
**damit** ich ohne Klick weiß, was ansteht.
**Priorität:** Should · **Abhängig von:** Übergabe AD D7

**Akzeptanzkriterien**
- AK1: Mit DS lesen zeigt die Startseite die Sicht „Mein Referat“ (Referent:in) bzw. „Verein“ (Reichweite „alle“).
- AK2: Ohne DS lesen bleibt die Startseite wie heute.
- AK3: Der Menüpunkt „Dashboard“ steht an erster Stelle.
- AK4 (Rechte): Die Startseite zeigt nichts, was die Person nicht lesen darf.

---

## Annahmen dieser Stories

- A1: Die Geschäftsstelle sieht die Zuordnung nur lesend (US-FI-24 AK6).
- A2: Grund ist beim Umschlüsseln Pflicht (US-FI-27 AK4; im Prototyp optional).
- A3: Bei mehreren Referaten ist das erste Standard (US-DS-07 AK4).
- A4: entschieden – eigene Umschichtungsanträge der Budgetpflege bestätigt die Schatzmeister:in (US-DS-13 AK5).
- A5: Ein Vorschlag zu einer verschwundenen Buchung wird „gegenstandslos“ (US-DS-15 AK4).
