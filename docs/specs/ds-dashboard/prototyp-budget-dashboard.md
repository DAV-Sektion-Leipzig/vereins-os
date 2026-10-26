# Übergabe: Prototyp Budget-Dashboard

Stand dieser Übergabe: 26.10.2026 · Version 1.0. Grundlage: die Dateien des Prototyps des 1. Vorsitzenden (`budget-dashboard.html`, `build.py`, `README.md`, Arbeitsnotizen, `kostenstellen.csv`), Stand 18.10.2026. Die Dateien selbst liegen nicht im Repository (sie enthalten den Finanzplan und Zuordnungen der Sektion); Beträge, Referenzsummen und Namen aus Buchungen sind hier bewusst weggelassen (öffentliches Repository).

Kennzeichnung: **[ANNAHME]** = Annahme, nicht festgelegt oder nicht belegt.

---

## 1. Zweck und Stand

- Offline-Dashboard (eine HTML-Datei) für den 1. Vorsitzenden: DATEV-Kontenblätter als CSV hineinziehen → je Budgetposten Budget, verbraucht, frei.
- Läuft vollständig im Browser (Chrome, macOS). Eine Content-Security-Policy verbietet jede Netzwerkverbindung; die CSV wird nur im Speicher ausgewertet und nicht gespeichert.
- Budget und Zuordnung sind in die HTML-Datei eingebettet (Datenblock `budget-daten`, JSON). `build.py` (nur Python-Standardbibliothek) liest Excel, Zuordnung und Kostenstellen und schreibt den Datenblock neu.
- Nutzer ist kein Programmierer; Sprache Deutsch.

## 2. Quellen

| Quelle | Inhalt | Pflege |
|---|---|---|
| Excel „Finanzen Sektion JJJJ.xlsx“, Blatt „Finanzplan JJJJ“ | Kopfzeile mit „Einnahmen“ und „Ausgaben“, je Seite eine Spalte „Plan JJJJ“; flache Liste der Budgetposten; Zeilen „Summe…“ sind Kontrollsummen | Vorstand (Haushaltsplan) |
| `zuordnung.csv` | Konto → Budgetposten. Spalten: Konto; Kontobezeichnung; Art; Gesamtbudget; Budgetposten; Kostenstelle; Status; Hinweis; Datum; Beleg; Betrag; Buchungstext | im Dashboard (Reiter „Zuordnung bearbeiten“) oder in Excel |
| `Zuordnung-Versionen/` | jede gespeicherte Fassung der Zuordnung und `protokoll.csv` (Version, Zeitpunkt, Quelle, Kommentar, Änderungen) | automatisch |
| `kostenstellen.csv` | KOST1 → Name der Sphäre: 1 Ideeller Bereich, 2 Vermögensverwaltung, 3 Zweckbetrieb, 4 Wirtschaftlicher Geschäftsbetrieb | selten |
| DATEV-Export (Kontenblätter aller Konten, CSV) | Kontenübersicht (Summen je Konto) und Buchungsliste | Buchhaltung, eingespielt durch den 1. Vorsitzenden |

## 3. DATEV-Export (Format)

- UTF-8 mit BOM (Windows-1252 wird auch erkannt), Trennzeichen `;`, CRLF, Beträge `1.234,56` in getrennten Spalten Umsatz Soll / Umsatz Haben (nie beide), Datum TT.MM.JJJJ.
- Zeile 1: Mandant; Berater; Mandantnr.; Exportzeit. Dann Abschnitt **Kontenübersicht** (Konto, EB-Wert, Umsatz Soll …) = Summen je Konto, keine Buchungen.
- Dann **Buchungsliste**: Konto; Beschriftung Konto; Datum; BU; Gegenkonto; Beschriftung Gegenkonto; Buchungstext; Belegfeld 1; Umsatz Soll; Umsatz Haben; KOST1. Spalten werden über ihre Namen gefunden, nicht über die Position.
- Kontonummer „6326 3“: Die letzte Ziffer kennzeichnet den Bereich der Buchhaltung (1 Geschäftsstelle, 2 Mitgliederverwaltung [ANNAHME], 3 Karl-Stein-Hütte, 4 Bergfilmfestival [ANNAHME], 5 Ausbildung, 6 Kinder und Jugend, 7 Klettern, 8 Leistungssport, 9 Touren), nicht ganz konsequent. Kontenrahmen SKR 04. Personenkonten ab 10000. Hinweis Glossar: Im Vereins OS heißt die Organisationseinheit „Referat“; „Bereich“ ist hier nur die Bezeichnung der Buchhaltung.
- KOST1 = Sphäre (steuerlich), nicht Referat.
- Eröffnungsbuchungen („EB-Wert“, Gegenkonto 9000 Saldenvorträge) stehen in der Buchungsliste; keine Summenzeilen.
- Bekannt aus dem Erstexport: Die Buchhaltung bucht mit Verzug (Export vom 18.10. enthielt Buchungen bis 30.06.); bei einem Konto fehlten zwei Einzelbuchungen gegenüber der Kontenübersicht – die Prüfung hat das gemeldet.

## 4. Rechenregeln

- **Keine Doppelzählung:** Jede Buchung steht 2–3-mal im Export (Erfolgskonto, Bank/Kreditor, Sammelkonto). Gezählt werden nur Zeilen, deren *Konto* eine Regel der Zuordnung trifft; der Bereich `4000-7999` (Erfolgskonten) ist als Auffangregel eingetragen. Alles andere wird ignoriert.
- **Regelvorrang:** Einzelbuchung (Datum, Beleg, Betrag wie „2.800,00 S“, Buchungstext) vor Einzelkonto „6326 3“ vor Hauptkonto „6326“ vor Kontenbereich (engster zuerst); mit Kostenstelle vor ohne. Bereich ohne Budgetposten → „nicht zugeordnet“.
- **Vorzeichen:** Ausgabe = Soll − Haben, Einnahme = Haben − Soll. Stornos, Gutschriften und Rücklastschriften mindern automatisch; Umbuchungen zwischen zwei Budgetkonten zählen auf beiden Konten mit eigenem Vorzeichen.
- **Saldovorträge** (Buchungstext „EB-Wert“ bzw. Gegenkonto „Saldenvortr…“) und Buchungen außerhalb des Budgetjahres zählen nicht.
- **Netto/brutto:** wie auf den Erfolgskonten gebucht – netto, wo Vorsteuer/Umsatzsteuer abgespalten wird (Zweckbetrieb, wirtschaftlicher Geschäftsbetrieb), sonst brutto. Der Plan gilt als gleiche Basis.
- **Anlagekonten** können ausdrücklich als Ausgabe zugeordnet werden (z. B. geringwertige Wirtschaftsgüter → Geschäftsstelle; Anlagen im Bau → Planung Vereinszentrum).
- **Status einer Zuordnung:** ok, unsicher, offen, keine Buchung (kalkulatorischer Posten wie „Auflösung Rücklagen“: wird angezeigt, zählt nicht bei „fehlt noch“). Unsichere Zuordnungen bekommen ein „?“ am Posten.
- **Gesamtbudget:** Gruppierung der Budgetposten (z. B. „Kinder und Jugend“), steht in der Zuordnung, nicht in der Excel. Ein doppelter Postenname in der Excel (z. B. „Vergütung Aktive“) gehört zum Gesamtbudget des Postens darüber.
- Geschäftsjahr = Kalenderjahr.

## 5. Anzeige

- **Kopf:** Gesamtbudget, verbraucht, frei, Verbrauch in %, Einnahmen (Plan / erreicht / fehlt noch), Datenstand = Datum der letzten Buchung im Export (nicht heute).
- **Balken je Posten** mit senkrechtem Strich = Anteil des abgelaufenen Jahres bis zum Datenstand (umschaltbar auf „heute“); rechts vom Strich = schneller verbraucht als geplant.
- **Ampel (Ausgaben):** grün unter 80 %, gelb 80–100 %, rot über 100 % oder Ausgaben ohne Budget; Formen ● ▲ ■ zusätzlich zur Farbe.
- Gesamtbudgets aufklappbar; Klick auf einen Posten → Summe je Konto und alle Einzelbuchungen (Datum, Konto, Buchungstext, Beleg, Betrag), sortier- und durchsuchbar.
- **Nicht zugeordnete Buchungen** (Erfolgskonten ohne Budgetposten), damit nichts verloren geht.
- **Filter:** Suche (auch Kontonummer), Ampel, Sphäre (KOST1), Sortierung.
- **Drucken** für die Vorstandssitzung (alle Gesamtbudgets aufgeklappt; offene Detailansicht wird allein gedruckt).
- **Prüfung:** Summe je Konto aus den Einzelbuchungen = Kontenübersicht des Exports; ausgewertet = Ausgaben − Einnahmen + nicht zugeordnet; Warnungen (Export unvollständig, Buchungen anderer Jahre, umgeschlüsselte Buchung im neuen Export nicht mehr vorhanden).

## 6. Pflege

- **Umschlüsseln (⇄):** einzelne Buchung oder alle Buchungen eines Kontos einem anderen Budgetposten zuordnen, mit Grund; Etikett „umgeschlüsselt“ mit Herkunft, Zeitpunkt, Grund; Rücknahme möglich. Einzelbuchungen werden über Datum, Konto, Beleg, Betrag mit S/H und Buchungstext wiedererkannt.
- **Zuordnung bearbeiten:** Zeilen ändern, neu anlegen, löschen; Prüfung auf unverständliche Kontonummern und doppelte Konten; Speichern erst ohne Fehler; Kommentar je Speichern.
- **Versionen:** Jede gespeicherte Fassung wird abgelegt und protokolliert (Nummer, Zeitpunkt, Quelle, Kommentar, Änderungen als lesbarer Text, z. B. „6420 1 …: Öffentlichkeitsarbeit → Umwelt und Naturschutz“).
- **Neues Budgetjahr:** neues Blatt „Finanzplan JJJJ“, Zuordnung anpassen (Postennamen müssen exakt passen), `build.py` ausführen.
- Speichern über die File System Access API in den Projektordner (Chrome); ungespeicherte Änderungen im localStorage.
- Geplant (Iteration 2 des Prototyps): Versionen vergleichen und per Klick zurückholen.

## 7. Was sich im Vereins OS ändert [ANNAHME: Vorschlag, zu klären im Steckbrief]

| Prototyp | Vereins OS |
|---|---|
| Datenblock in der HTML-Datei, `build.py` | Tabellen in Supabase (Finanzplan, Budgetposten, Gesamtbudget, Zuordnungsregeln) per Import der Excel bzw. Pflege in der Oberfläche |
| `zuordnung.csv` + Versionsordner + Protokoll | Zuordnungsregeln mit `valid_from`/`valid_to` und Protokoll der Änderungen (Historie wie im Personenmodell) |
| CSV nur im Browser, nichts gespeichert | [OFFEN, Q-DS1] Summen speichern oder Buchungsliste speichern |
| ein Nutzer | Rechte über die Administration; Sicht je Referat über Reichweite „Referat“ |
| Umschlüsselung im localStorage bis zum Speichern | sofort gespeichert, mit Grund und Protokoll |
| Prüfung im Browser | Prüfung beim Import; Import wird bei Fehlern nicht übernommen [ANNAHME] |
| Referenzwerte des Erstexports | Abnahmetest mit fiktiven Daten im Repository; Vergleich mit echten Referenzwerten nur lokal durch den Product Owner |
