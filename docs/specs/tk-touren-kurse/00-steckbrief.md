# Steckbrief: Planungshilfe Touren und Kurse

Stand: 26.10.2026 · Version 0.8 · Kürzel: TK · Ablage: docs/specs/tk-touren-kurse/ · Status: Entwurf · Product Owner: Toni Werner
Änderungen v0.8: Wiederaufnahme, Abgleich mit den anderen Modulen: externe Leitende aus der Planung anlegen; Löschfrist Notfallkontakte 30 Tage; Material nur Ausrüstungsliste; Titel ungekürzt (Anwesenheitserfassung erlaubt 90 Zeichen); Kurse ein- und mehrtägig nach Lehreinheiten; Trainersatz auch bei Lizenz-Erwerb im Halbjahr des Startdatums wie in Finanzen; Freigabe über die Aktion „darf freigeben“ der Administration (Product Owner 24./26.10.2026).
Änderungen v0.7: Organisationspauschale der Gemeinschaftstour trägt vorerst die Sektion (Umlage auf Teilnehmende später klären); Sätze pflegt vorerst nur der Admin (Product Owner 22.10.2026).
Änderungen v0.6: Gemeinschaftstour mit Organisationspauschale nach Vergütungsordnung Ziff. 9.2 (Fehler im Prototyp); Sätze und Pauschalen als Stammdaten in der Administration; Stornoregel (Rückerstattung 90 %/50 %) nicht im Scope (Product Owner 22.10.2026).
Änderungen v0.5: PDF-Übernahme nicht im Scope (Referat überträgt Einreichungen von Hand bis Iteration 2); Person mit Freigaberecht darf Planungen bearbeiten und Rückfragen stellen; Iteration 2 (öffentliches Formular oder Zugang) als offener Punkt für später; Stories v0.1 (Product Owner 22.10.2026).
Änderungen v0.4: Freigaberecht vergibt der Admin; Iterationen festgelegt: MVP = vollständiges Erhebungsformular im Vereins OS mit Kalkulation und Kostenauswertung, CO2-Daten werden von Anfang an erfasst und berechnet; CO2-Auswertung in Iteration 1; Ablösung des HTML-Formulars und Eingabe durch Tourenleitende (öffentliche Integration oder Zugang) in Iteration 2 (Product Owner 22.10.2026).
Änderungen v0.3: Ziel: HTML-Formular ablösen und alle Einreichungen zentral in der Datenbank speichern (Auswertung CO2, Einsätze); Lizenz-Stichtag = erster Tag (läuft die Lizenz während der Tour ab, gilt der Trainersatz für die ganze Tour); Freigabe durch Referent:innen, delegierbar über ein eigenes Freigaberecht; Einreichungen weiter an tourenreferat@dav-leipzig.de, auch für Kurse; bei Absage wird der Einsatz als abgesagt markiert (Product Owner 22.10.2026).
Änderungen v0.2: Kurse gehören zum Referat Ausbildung und werden ebenfalls mit der Planungshilfe geplant; der Einsatz entsteht erst mit Status „in Yolawo angelegt“; Trainersatz nur, wenn die Lizenz am letzten Tag der Tour bzw. des Kurses gültig ist (Product Owner 22.10.2026).
Änderungen v0.1: Erster Entwurf aus dem HTML-Prototyp „Tourenkonzept“ des Referats Touren (Tourenkonzept_DAV-Leipzig.html, Stand Oktober 2026) und dessen Übergabe (prototyp-tourenkonzept.md); Vorgaben Product Owner 22.10.2026: Leitung aus Personen (Trainer:innen), Einsatz in der Anwesenheitserfassung erzeugen, Abrechnung vorbefüllen (Finanzen rechnet), CO2-Bilanz, Planungsunterstützung; Kürzel TK; Nutzer im MVP Referat Touren und Geschäftsstelle.

**Problem heute:**
Tourenleitende planen Touren und Kurse mit einer eigenständigen HTML-Datei („Tourenkonzept“), kalkulieren dort den Teilnahmebeitrag nach Vergütungs- und Reisekostenordnung, erzeugen eine CO2-Bilanz und schicken ein PDF per E-Mail an das Referat Touren. Das Referat öffnet das PDF wieder im Formular, prüft per E-Mail und legt das Angebot von Hand in Yolawo an. Es gibt keinen Status, keine Übersicht aller geplanten Touren, keine Verbindung zu den Lizenzen der Leitenden (Name, Qualifikation und Lizenzjahr werden je Tour frei eingetippt) und keine Übergabe an Anwesenheitserfassung und Abrechnung: Nach der Tour füllt die Leitung die Formulare „Reisekosten“ und „Kostenabrechnung“ erneut von Hand aus. Sätze und Emissionsfaktoren stehen im HTML-Code; eine Änderung heißt: Datei ändern und neu verteilen. Beispiel: Für die Hüttentour Stubai (5 Tage, 735 € Kosten, Beitrag 160 €) tippt die Leitung Tagessätze, Bahnkosten und Leitung dreimal ein – im Tourenkonzept, in der Reisekostenabrechnung und in der Kostenabrechnung.

**Ziel / Erfolgsmessung:**
- Jede Führungstour, Gemeinschaftstour und jeder Kurs des Tourenprogramms 2027 [ANNAHME: Startjahr] ist als Planung im Vereins OS erfasst, mit Status von „Entwurf“ bis „abgeschlossen“; das Referat Touren sieht alle Planungen in einer Liste.
- Leitung und Helfende werden aus den Aktiven gewählt; Trainersatz oder Helfersatz ergibt sich aus der gültigen Lizenz im Ehrenamtsmanagement, ohne Freitext.
- Kalkulation (Vergütung, Kosten, Teilnahmebeitrag, Kostendeckung) und CO2-Bilanz liefern bei den Beispieldaten des Prototyps dieselben Ergebnisse (160 € Beitrag, kostendeckend ab 5 Teilnehmenden, ca. 100 kg CO2e je Person).
- Sobald das Angebot in Yolawo angelegt ist, entsteht ohne erneutes Eintippen ein Einsatz (Kurs bzw. Tour) in der Anwesenheitserfassung mit Leitung und Helfenden als „eingetragen“.
- Finanzen erhält je Planung die geplanten Vergütungstage bzw. Lehreinheiten und Kosten der Leitung als Vorbelegung der Abrechnung; die Tourenleitung tippt diese Werte nach der Tour nicht neu ein.
- Sätze, Zahlungsgebühren und Emissionsfaktoren sind ohne Code-Änderung mit „gültig ab“ pflegbar; jede Kalkulation speichert, mit welchem Stand gerechnet wurde.
- MVP: Das Erhebungsformular des Prototyps (Schritte 1–7) ist vollständig im Vereins OS nachgebaut; alle Angaben einer Planung liegen strukturiert in der Datenbank (nicht nur als PDF oder JSON), inklusive der CO2-Daten (Product Owner 22.10.2026).
- MVP: Kostenauswertung über alle Planungen (geplante Kosten, Vergütung, Beiträge, Kostendeckung je Tour, Jahr, Referat, Tourtyp).
- Iteration 1: CO2-Auswertung über alle Planungen (je Jahr, Referat, Verkehrsmittel).
- Iteration 2: Das HTML-Formular „Tourenkonzept“ ist abgelöst; Tourenleitende geben direkt ein (öffentliche Integration oder Zugang mit Reichweite „nur eigene“ [OFFEN: Weg]).

**Nutzer & Rechtevorlagen:**
- Referent:in – TK bearbeiten, Reichweite „Referat“: Referat Touren für Führungs- und Gemeinschaftstouren, Referat Ausbildung für Kurse (Product Owner 22.10.2026); legt Planungen des eigenen Referats an, überträgt Einreichungen, prüft, legt das Angebot in Yolawo an.
- **Freigabe** von Touren und Kursen liegt bei den Referent:innen des jeweiligen Referats und kann an andere Personen delegiert werden (Product Owner 22.10.2026). Dafür ein eigenes Recht „TK freigeben“ mit Reichweite „Referat“, unabhängig von der Rechtevorlage Referent:in [ANNAHME: als eigene Rechtevorlage, weil Einzelrechte erst nach dem MVP kommen]. Vergeben und entziehen durch den Admin, auf Wunsch der Referent:in. Wer das Freigaberecht hat, darf Planungen des Referats auch bearbeiten und Rückfragen stellen (Product Owner 22.10.2026). Die Geschäftsstelle gibt nicht frei [ANNAHME].
- Geschäftsstelle – TK verwalten: alles lesen und bearbeiten, Planungen löschen, Sätze und Faktoren pflegen [ANNAHME].
- Admin – TK lesen [ANNAHME, wie bei der Anwesenheitserfassung].
- Vorstand – Vorlage ohne Rechte; Ziel lesen (Freigabe von Ausnahmen wie PKW über 500 km) [ANNAHME].
- Tourenleitende (Trainer:innen, Wanderleiter:innen, Helfende) – im MVP und in Iteration 1 **kein Zugang**; sie reichen das PDF aus dem HTML-Formular per E-Mail an tourenreferat@dav-leipzig.de ein, auch für Kurse; das Referat überträgt die Angaben von Hand ins Vereins OS (keine PDF-Übernahme, Product Owner 22.10.2026). In Iteration 2 geben sie direkt ein [OFFEN: öffentliches Formular oder Zugang]; dann entfällt das HTML-Formular.
- Rechte vergibt der Admin; ein Amt (z. B. Referent:in Touren) bringt keine Rechte mit.

**Iterationen (Product Owner 22.10.2026):**
- **MVP:** Erhebungsformular vollständig im Vereins OS (alle Felder, Berechnungen, Prüfungen des Prototyps, inkl. CO2-Bilanz je Planung), Status und Freigabe, Leitung aus Personen, Yolawo-Ausgaben, Kostenauswertung; Einsatz erzeugen und Abrechnung vorbefüllen, sobald Anwesenheitserfassung bzw. Finanzen verfügbar sind.
- **Iteration 1:** CO2-Auswertung über alle Planungen.
- **Iteration 2:** Ablösung des HTML-Formulars: Eingabe durch Tourenleitende (öffentliche Integration oder Zugang), PDF-Übernahme nicht vorgesehen.

**Im Scope (MVP):**
- **Planung** einer Tour oder eines Kurses mit Tourtyp Führungstour, Kurs (Ausbildungstour) oder Gemeinschaftstour; Referat ergibt sich aus dem Tourtyp: Kurs → Ausbildung, Führungs- und Gemeinschaftstour → Touren [ANNAHME: nicht frei wählbar]; Inhalte wie im Prototyp (Schritte 1–7: Leitung, Ausschreibung, Termin und Anreise, Anforderungen, Teilnahme, Kalkulation, Einreichen), Felder und Regeln nach prototyp-tourenkonzept.md Abschnitt 3–6.
- **Gemeinschaftstour:** keine Tagessätze, keine Lehreinheiten, keine Kosten der Leitung; die **Organisationspauschale wird nach Vergütungsordnung Ziff. 9.2 gezahlt** (Prototyp-Regel „keine Organisationspauschale“ war ein Fehler, Product Owner 22.10.2026); kein Teilnahmebeitrag, die Organisationspauschale trägt vorerst die Sektion (Product Owner 22.10.2026).
- **Stornoregel** (Rückerstattung bis 4 Wochen 90 %, bis 2 Wochen 50 %) ist nicht im Scope (Product Owner 22.10.2026): kein Feld, keine Zeile im Eingabeblatt und im Ausschreibungstext; Stornoregeln legt das Referat in Yolawo selbst fest.
- **Status:** Entwurf → eingereicht → Rückfrage → freigegeben → in Yolawo angelegt → durchgeführt → abgeschlossen; abgesagt aus jedem Status vor „durchgeführt“ [ANNAHME: Status nach Vorschlag 11.2 des Prototyps]. Freigabe mit Kommentar und Verlauf durch Personen mit Freigaberecht im Referat (Zulassung nach Vergütungsordnung Ziff. 9).
- **Leitung aus Personen:** Leitung, Co-Leitung und Helfer:innen werden aus den Aktiven gewählt (Suche über alle Aktiven, nur Name); angezeigt werden die gültigen Lizenzen der Person (Qualifikationsart, gültig bis). Trainersatz, wenn die förderfähige Lizenz am ersten Tag der Tour bzw. des Kurses gültig ist („gültig bis“ ≥ Startdatum); läuft sie während der Tour ab, gilt der Trainersatz für die ganze Tour, keine tageweise Rechnung (Product Owner 22.10.2026). Beispiel: Lizenz gültig bis 30.10.2027 – Kurs am 15.10.2027 und Tour 29.10.–01.11.2027 Trainersatz; Kurs am 02.11.2027 Helfersatz; sonst Helfersatz. Hinweis, wenn keine Qualifikation der Leitung die Sportart abdeckt (Zuordnung Qualifikationsart → Sportart als Stammdaten [ANNAHME]).
- **Kalkulation:** Vergütung (Tagessätze, Halbtagessätze, Lehreinheiten, Organisationspauschale), Kosten der Leitung, sonstige Kosten, Leistungen je Teilnehmer:in, „selbst zu zahlen“, Teilnahmebeitrag mit Zahlungsgebühren (teuerste aktive Zahlmethode), Rundung auf 5 €, Nichtmitgliederbeitrag (+30 %), Kostendeckung ab n Teilnehmenden, Ergebnis bei Mindest- und Höchstzahl. Formeln nach prototyp-tourenkonzept.md Abschnitt 4; Berechnung in der Datenbank, nicht nur im Browser [ANNAHME].
- **CO2-Bilanz (Planung):** An- und Abreise je Teilstrecke und Verkehrsmittel, Unterkunft, Verpflegung; je Person, je Person und Tag, Klimaschutzbudget (interner CO2-Preis); DAV-Hütten nicht im Tourbudget; Leipziger Richtwert PKW als Hinweis.
- **Planungsunterstützung:** Prüfung der Pflichtangaben mit Fortschritt, Warnungen und Hinweise (6-Monats-Vorlauf, Anmeldeschluss, PKW über 500 km, Übernachtung über 70 €, Freiplatz 5+1 auf Hütten, Hüttenpreis-Plausibilität, Flug unter 1000 km, Konditions-Vorschlag aus Gehzeit und Höhenmetern, Lizenz läuft vor dem Tourjahr ab); automatische Vorschläge für Tage, Nächte, Personen.
- **Ausgaben:** Yolawo-Eingabeblatt (Feld für Feld kopierbar), Ausschreibungstext, Zusammenfassung, PDF-Export.
- **Einsatz erzeugen:** Beim Übergang auf „in Yolawo angelegt“ (Product Owner 22.10.2026) legt das System in der Anwesenheitserfassung einen Einsatz (Einsatzart Kurs bzw. Tour) an: Referat, Titel, Zeiten, organisierende Person, Leitung und Helfende mit Rolle und Stand „eingetragen“. Spätere Änderungen von Termin oder Leitung werden übertragen, solange keine Anwesenheit bestätigt ist [ANNAHME]. Bei Absage wird der Einsatz als „abgesagt“ markiert, nicht gelöscht (Product Owner 22.10.2026). Anwesenheit und Durchführung erfasst die Anwesenheitserfassung.
- **Abrechnung vorbefüllen:** Planwerte je Person (Rolle, Satzart Trainer:in/Helfer:in, Tage, Halbtage, Lehreinheiten, Organisationspauschale) und Plan-Kosten der Leitung (Positionen, z. B. Bahn, Übernachtung, PKW-km) stehen Finanzen als Vorbelegung zur Verfügung; Finanzen rechnet mit Ist-Werten aus der Anwesenheitserfassung und Belegen ab.
- **Sätze und Annahmen:** Sätze (Vergütungs- und Reisekostenordnung inkl. Organisationspauschale und Hüttenpauschalen), Zahlungsgebühren, Emissionsfaktoren, CO2-Preis und Grenzwerte sind Stammdaten der **Administration** mit „gültig ab“ und Quelle, pflegbar ohne Code-Änderung (Product Owner 22.10.2026); Pflege vorerst nur durch den Admin (Product Owner 22.10.2026); Geschäftsstelle oder Referent:innen später möglich; Finanzen nutzt dieselben Sätze. Jede Kalkulation speichert den verwendeten Satzstand.
- **Datenhaltung und Kostenauswertung:** Alle Planungen werden strukturiert gespeichert (keine Ablage als Datei oder JSON-Block), auch alle CO2-Angaben, damit spätere Auswertungen ohne Nacherfassung möglich sind. Im MVP Kostenauswertung: Liste der Planungen mit Filter (Jahr, Referat, Tourtyp, Status) und Summen von geplanten Kosten, Vergütung, Kosten der Leitung, Beiträgen, Ergebnis bei Mindest- und Höchstzahl; Export als CSV mit „verwalten“ [ANNAHME].
- **Notfallkontakte** der Leitung je Planung (Name, Telefon), nur für Referat Touren und Geschäftsstelle lesbar, automatisch gelöscht nach „durchgeführt“ + Frist [OFFEN: Frist].
- Mobil nutzbar ab 375 px (Lesen, Status ändern); Bearbeiten der Kalkulation am Desktop [ANNAHME].

**Nicht im Scope:**
- Stornoregel und Rückerstattung bei Stornierung (90 %/50 %, Prototyp 3.1 Schritt 5, 5.4, 7.1, 7.2).
- Anmeldung von Teilnehmenden und Zahlung (bleibt in Yolawo); Prüfung der DAV-Mitgliedschaft.
- Automatischer Import nach Yolawo (Yolawo bietet keinen Import von Angeboten; Schreib-Schnittstelle [OFFEN]).
- Abrechnung, Belegprüfung und Auszahlung (Finanzen); Erfassung der Anwesenheit (Anwesenheitserfassung).
- Zugang bzw. öffentliche Eingabe für Tourenleitende und Ablösung des HTML-Formulars (Iteration 2).
- CO2-Auswertung über mehrere Planungen (Iteration 1); im MVP nur die CO2-Bilanz je Planung.
- Anmeldung von Fahrten, auch Kinder- und Jugendfahrten (bisher dem Modul zugeordnet, modul-landkarte.md v1.4) – [OFFEN]: eigene spätere Iteration oder anderes Modul; der Prototyp deckt sie nicht ab.
- Benötigtes Material der Sektion (Ausleihe) – später (eigenes Modul); im MVP nur Ausrüstungsliste für Teilnehmende als Text (Product Owner 26.10.2026).
- Ist-CO2-Bilanz nach der Tour, Feedbackbogen, Tourenberichte (später).
- Fotos hochladen (Titelbild weiter per E-Mail) [ANNAHME].
- Erwachsenenfahrten und Ausfahrten von Gruppen.

**Abhängigkeiten:**
- Administration → Planungshilfe Touren und Kurse: Stammdaten Sätze, Pauschalen, Gebühren, Emissionsfaktoren (neu); Modul TK in `ad_modules`, Rechtevorlagen mit Reichweite „Referat“ für TK, eigenes Freigaberecht (vergeben durch den Admin), Namenssuche über Aktive, Lesefunktion für gültige Lizenzen der gewählten Personen; Referate. Übergabe: uebergabe-administration.md (v1.6).
- Ehrenamtsmanagement → Planungshilfe Touren und Kurse: Aktive, Qualifikationen (Lizenz mit Qualifikationsart und Ablaufdatum), Kennzeichen förderfähig; nur lesen. Fallback-Hinweis „keine Lizenz hinterlegt“.
- Planungshilfe Touren und Kurse → Anwesenheitserfassung: Einsatz Kurs bzw. Tour mit Leitung als „eingetragen“, erzeugt mit Status „in Yolawo angelegt“; Rückmeldung „durchgeführt“ aus der Anwesenheitserfassung [ANNAHME]. Übergabe: uebergabe-anwesenheitserfassung.md (v1.2). Löst den offenen Punkt der Anwesenheitserfassung zur Übernahme geplanter Kurse und Touren.
- Planungshilfe Touren und Kurse → Finanzen: Planwerte als Vorbelegung der Abrechnung; Sätze der Vergütungsordnung gemeinsam nutzen. Übergabe: uebergabe-finanzen.md (v1.3).
- Extern: Yolawo (nur manuell über das Eingabeblatt); HTML-Formular des Referats Touren (Einreichungsformat Version 1).
- Reihenfolge: nach Anwesenheitserfassung [ANNAHME]; Einsatz und Abrechnung setzen die Anwesenheitserfassung und Finanzen voraus. Ohne sie läuft die Planung allein (Einsatz erzeugen und Abrechnung vorbefüllen werden dann nachgezogen).

**Risiken / Besonderheiten:**
- **Fehler im Prototyp:** Der Prototyp rechnet die Gemeinschaftstour ohne Organisationspauschale; richtig ist die Vergütungsordnung Ziff. 9.2 (Product Owner 22.10.2026). Die Prototyp-Übergabe (Abschnitt 4.9, 10) ist an dieser Stelle überholt.
- **Notfallkontakte sind Daten Dritter:** im Prototyp Freitext im PDF und im Browser; hier nur Name und Telefon, eingeschränkte Lesbarkeit, automatische Löschung; Löschfrist vom Vorstand/Datenschutz zu bestätigen. Widerspruch zum Personenmodell (Notfallkontakt = Person in der gemeinsamen Tabelle): hier bewusst Freitext an der Planung [ANNAHME].
- **Einreichung als PDF bis Iteration 2:** Das Referat überträgt von Hand (Aufwand, Tippfehler); das HTML-Formular rechnet mit eigenen Sätzen, das System mit den Stammdaten – Beiträge können abweichen, maßgeblich ist das System.
- **Sätze zentral in der Administration:** Finanzen und Planungshilfe lesen dieselben Sätze; Abhängigkeit: die Stammdaten müssen vor der Planungshilfe in der Administration umgesetzt sein (Übergabe v1.4).
- **Annahmen des Prototyps** (MwSt. 19 % auf Gebühren, Konditionsgrenzen, Technikstufen, Zuordnung Qualifikation → Sportart, Hüttenpreis 45–90 €, Faktoren Reisebus und Selbstversorgerhütte) sind nicht vom Referat Touren bestätigt.
- **Yolawo-Feldbezeichnungen** sind aus dem Buchungs-Widget abgeleitet, nicht in der Verwaltungsoberfläche geprüft.
- **Lizenzdaten im Ehrenamtsmanagement unvollständig:** Bis zur Migration fehlen viele Lizenzen; Wanderleiter:innen und externe Leitende ohne Lizenzeintrag bekommen den Helfersatz. Gegenmaßnahme: Hinweis, die freigebende Person kann begründet abweichen [OFFEN: ob erlaubt].
- **Kosten:** keine zusätzlichen; PDF-Erzeugung im Browser [ANNAHME].

**Offene Fragen:**
- [OFFEN] Wer setzt „in Yolawo angelegt“, wenn die Tourenleitung das Angebot selbst anlegt (Prototyp: „Ich selbst, mit eigenem Yolawo-Zugang“)? Vorschlag: Referent:in nach Rückmeldung.
- [OFFEN] Gemeinschaftstour: Später klären, ob die Organisationspauschale von den Teilnehmenden zurückgeholt wird (Umlage oder kleiner Beitrag); bis dahin trägt sie die Sektion (Product Owner 22.10.2026).
- Entschieden 26.10.2026: Notfallkontakte werden 30 Tage nach Tourende bzw. Absage gelöscht.
- [OFFEN] Anmeldung von Fahrten (Kinder- und Jugendfahrten): weiter in diesem Modul (spätere Iteration) oder neu zuordnen?
- Entschieden 26.10.2026: „Benötigtes Material“ nur als Ausrüstungsliste; Reservierung von Material der Sektion später.
- [OFFEN] Iteration 2 (später anschauen): öffentliches Formular ohne Login (Datenschutz, Missbrauchsschutz) oder Zugang für Tourenleitende mit Reichweite „nur eigene“?
- [OFFEN] Priorität und Einordnung in die Reihenfolge der Module.
- [ANNAHME] bestätigen: Kürzel TK und Ablage; Statusmodell; Admin liest; Berechnung serverseitig; Planwerte nur als Vorbelegung für Finanzen.

**Folgeänderungen in anderen Dokumenten (ausgeführt):**
- spec.md v0.1 (22.10.2026): Übergabe an Administration v1.6; modul-landkarte.md v2.4; offene-punkte.md v3.7.
- v0.7 (22.10.2026): 01-erhebung.md v0.7; 02-stories.md v0.3; Übergabe an Administration v1.5; offene-punkte.md v3.6.
- v0.6 (22.10.2026): 01-erhebung.md v0.6; 02-stories.md v0.2; Übergaben an Administration v1.4 und Finanzen v1.3; modul-landkarte.md v2.3; offene-punkte.md v3.5.
- v0.5 (22.10.2026): 01-erhebung.md v0.5; 02-stories.md v0.1; modul-landkarte.md v2.2; offene-punkte.md v3.4.
- v0.4 (22.10.2026): 01-erhebung.md v0.4; modul-landkarte.md v2.1; offene-punkte.md v3.3; Übergabe an Administration v1.3.
- v0.3 (22.10.2026): 01-erhebung.md v0.3; modul-landkarte.md v2.0; offene-punkte.md v3.2; Übergaben an Administration, Anwesenheitserfassung, Finanzen (je v1.2).
- v0.2 (22.10.2026): 01-erhebung.md v0.2; modul-landkarte.md v1.9; offene-punkte.md v3.1; Übergaben an Administration, Anwesenheitserfassung, Finanzen (je v1.1).
- v0.1 (22.10.2026): modul-landkarte.md v1.8; offene-punkte.md v3.0; Übergaben an Administration, Anwesenheitserfassung, Finanzen (je v1.0); prototyp-tourenkonzept.md (Übergabe des Prototyps, unverändert übernommen).
- Noch nicht ausgeführt: glossar.md (Modulname, neue Begriffe) und rollen.md (Spalte TK) – mit den Stories bzw. nach Einarbeitung der Übergabe in der Administration.
