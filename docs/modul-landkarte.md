# Modul-Landkarte: Vereins OS

Stand: 22.10.2026 · Version 1.7
Änderungen v1.7: Anwesenheitserfassung: Stories v0.3 und Spec v0.1 (Entwurf); Übergaben an Administration und Gruppen eingearbeitet (spec.md AD v0.8; Gruppen Stories v0.7 mit `gr_group_roster`, `gr_my_groups`, `gr_groups_for_attendance`); Kurs, Tour, Trainingslager im MVP von EZ gesperrt bis zur Klärung mit Touren und Kurse; Orte: nur Admin pflegt, Startliste bei der Umsetzung; Vorschlag der eigenen Gruppe beim Erfassen.
Änderungen v1.6: Modul Touren und Kurse geschärft: eigenständiges Planungstool für Erstellung, Planung und Kalkulation von Kursen und Touren (Kosten, Ausgaben, Deckungsbeitrag, Material, CO2); Durchführung und Anwesenheit in EZ; Vorlage: HTML-Prototyp des Referenten Touren. Abweichung von Vergütungsordnung Punkt 7 gestrichen (kein Vorstandsbeschluss nötig).
Änderungen v1.5: Reihenfolge Gruppen → Anwesenheitserfassung → Finanzen (Priorität EZ „2b“); Orte als Stammdaten der Administration; mehrtägige Einsätze mit Enduhrzeit; Wettkampfbegleitung ein- oder mehrtägig; Erwachsenenfahrten nicht im Scope von EZ; Idee eines eigenen Abrechnungsmoduls, das in Finanzen aufgeht.
Änderungen v1.4: Anwesenheitserfassung: Erhebung v0.1 aus dem Forms-Formular; Zeiten bei Fahrten wie heute; Ort beim Training. Modul Touren und Kurse übernimmt auch die Anmeldung von Fahrten (inkl. Kinder- und Jugendfahrten).
Änderungen v1.3: Modul Einsätze heißt **Anwesenheitserfassung** (Kürzel EZ bleibt [ANNAHME]); Kurse, Touren, Mehrtageskurse/Trainingslager im Umfang; neues Modul für Touren und Kurse als Idee.
Änderungen v1.2: Vergütungsordnung eingearbeitet: Trainingseinheit 30 Minuten, Sätze nach Anhang 1 mit Pflege in Finanzen [ANNAHME]; Einsatzart Wettkampfbegleitung; Rolle je Anwesenheit.
Änderungen v1.1: Steckbrief Einsätze (EZ v0.1); Trainerabrechnung in Finanzen; Übergaben.
Änderungen v1.0: Nachtrag Personenmodell aus EA und GR in AD eingearbeitet (spec.md AD v0.7).
Änderungen v0.9: Qualifikationsarten als Stammdaten der Administration (spec.md AD v0.6).

## Basismodule

| Modul | Kürzel | Zweck in einem Satz | Hauptnutzer | Status | Priorität | Abhängigkeiten |
|---|---|---|---|---|---|---|
| Administration | AD | Login, Personen mit Zugang anlegen, Nutzer einladen und sperren, Rechtevorlagen (mit Reichweite) pflegen und zuweisen, Eigenschaftsarten mit Feldern und Eigenschaften pflegen, Stammdaten (Qualifikationsarten, Referate, Gremien, Orte) führen, Sichtbarkeit von Personen je Modul durchsetzen; später API-Keys (mit SC). | Admin (MVP: Product Owner; Notfall-Admin über Postfach der Geschäftsstelle; Vertretung später: Mitarbeiter:in der Geschäftsstelle); Geschäftsstelle nur für Qualifikationsarten (über EA) | Spec v0.7.1 Ready (Nachtrag freigegeben 21.10.2026); Nachtrag v0.8 (Anwesenheitserfassung) Entwurf; Umsetzung wird mit T33 fortgesetzt (US-AD-01, 02, 05 umgesetzt in TEST) | 0 – erstes Modul | liefert Nutzer, Rechte, Reichweiten an alle Module; baut das gemeinsame Personenmodell inkl. Ehrenamtsstatus für EA und GR; liefert Qualifikationsarten, Referate, Gremien an EA, GR, EZ; liefert EZ Startwerte, Reichweite „Referat“, Namensfunktionen, Anlegen von Helfer:innen, Orte (v0.8, Übergabe eingearbeitet); Reichweite „Gruppe“ für Iteration 1 von EZ vorgemerkt; extern: Supabase Auth mit Gmail als SMTP; Ausbildungsstruktur des Bundesverbands |
| Schnittstellen-Connector | SC | Externe Dienste zentral und generisch anbinden: Instagram, Umfrage-Dienst, E-Mail-Versand aus Abläufen (z. B. Hinweis vor Ablauf einer Lizenz); offen für DATEV. Mit SC kommt die API-Key-Verwaltung in AD. | Admin (Konfiguration); Module (Nutzung) | Idee | spätestens mit OA (4) [ANNAHME] | AD → API-Keys; genutzt von EA, OA, AM, FI [ANNAHME] |

### Umfang AD im MVP

Siehe docs/specs/ad-administration/00-steckbrief.md (v1.1) und spec.md (v0.8). Kurzfassung:

- Login über Supabase Auth (E-Mail und Passwort, nur @dav-leipzig.de); Einladung nur auf Knopfdruck je Person; „Passwort vergessen“ per Link. Login-Mails über das Google-Konto der Sektion.
- Startseite als Platzhalter (Willkommensgrafik); sichtbar nur Module mit Rechten.
- Personen anlegen (mit Rufname) mit Dublettenwarnung über alle Module; Zugang einrichten, einladen, sperren und entsperren.
- Rechtevorlagen je Modul anlegen, ändern, zuweisen (mehrere je Person); Reichweite „alle“ oder – für EA und EZ – „Referat“ mit Referaten je Zuweisung; Startvorlagen Admin (inkl. Gruppen lesen, Anwesenheitserfassung lesen), Geschäftsstelle, Referent:in, Vorstand.
- Eigenschaftsarten (Zweck, Kategorie, Lesestufe, Bezug, 1–n Felder, „sichtbar in“) und Eigenschaften pflegen.
- Gemeinsame Personen-Tabelle; Sichtbarkeit je Modul (Pfade AD, EA, GR) per RLS; für EZ nur Namen über Funktionen; Ehrenamtsstatus (Datenmodell und Funktionen; Oberfläche in EA).
- Stammdaten: Qualifikationsarten (Startbestand 47), Referate (7), Gremien (4) per Migration; Orte (Pflege nur Admin, Startliste liefert der Product Owner bei der Umsetzung).
- Notfall-Admin, Protokoll (5 Jahre), Testzugänge je Vorlage in TEST (inkl. Referent:in).
- Nach MVP bzw. mit SC: API-Key-Verwaltung inkl. Erinnerung vor Ablauf, Einzelrechte, weitere Reichweiten, Befristung, SSO.

## Fachmodule

| Modul | Kürzel | Zweck in einem Satz | Hauptnutzer | Status | Priorität | Abhängigkeiten |
|---|---|---|---|---|---|---|
| Ehrenamtsmanagement | EA | Aktive mit ihren Eigenschaften (frei definierbare Eigenschaftsarten mit mehreren Feldern, u. a. Amt, Funktion, Qualifikation, Nachweis, Kontaktdaten, Ausgaben, Jahreseinträge) je Referat und Gremium pflegen, filtern und finden; Ehrenamtsstatus setzen; Ablauf von Qualifikationen anzeigen; löst die Excel-Aktivenliste ab (einmalige Migration per Skript). | Geschäftsstelle, Referent:innen (inkl. Hüttenwart:innen) | Steckbrief | 1 | AD → Nutzer, Rechte, Reichweite „Referat“, Personenmodell mit Feldern, Lesestufen, Ehrenamtsstatus, Referate, Gremien, Qualifikationsarten (Verweis; Pflegeseiten für die Geschäftsstelle unter /ea/qualifikationsarten); blendet Funktionspersonen aus; GR → Gruppen-Funktionen (nur lesen); liefert Personen, Eigenschaften, Ehrenamtsstatus an alle Fachmodule; liefert Lizenzen und Nachweise (Bestätigung steuerfreie Einnahmen) an FI; SC → E-Mail vor Ablauf (nach MVP); EZ → Einsatzhistorie und letzter Einsatz (Iteration 2); offen: Übergabe aus der Anwesenheitserfassung v1.2 |
| Gruppen | GR | Gruppen im Kinder-, Jugend- und Erwachsenenbereich mit Gruppenleitungen und Teilnehmern verwalten; löst die Excel-Teilnehmerlisten ab. Anforderung läuft parallel. | Geschäftsstelle | Steckbrief v0.7, Erhebung v0.7, Stories v0.7 | 2 | AD → gemeinsame Personen-Tabelle, Platzhalter `gr_person_visible` (GR ersetzt ihn), Admin „Gruppen lesen“; EA → Personen, Referate lesen; AD → Qualifikationsarten lesen (Trainer:in braucht Lizenz); pflegt Gruppen-Funktionen (Bezug Gruppe); liefert EZ strukturierte Trainingszeiten und Lesefunktionen ohne Personendaten außer Namen: `gr_groups_for_attendance`, `gr_group_roster` (Stichtag), `gr_my_groups` (Übergabe eingearbeitet) |
| Anwesenheitserfassung | EZ [ANNAHME: Kürzel bleibt] | Einsätze (Trainings mit Vorschlag aus den Trainingszeiten der Gruppen, Ausfahrten, Ausbildungsfahrten, Wettkampfbegleitungen, Arbeitseinsätze inkl. Veranstaltungen wie Europacup und Bergfilmfestival; später Kurse, Touren, Trainingslager) anlegen und die Anwesenheit mit Rolle erfassen; reine Erhebung und zentrale Speicherung als Grundlage für Abrechnung nach der Vergütungsordnung und Auswertung; löst das Microsoft-Forms-Formular „Anwesenheitserfassung – Jugend“ ab (mit Iteration 1). Früher „Einsätze“ bzw. „Einsatzerhebung“. | Geschäftsstelle, Referent:innen (MVP); Gruppenleitungen und Trainer:innen (Iteration 1) | Steckbrief v0.7 (abgeschlossen), Erhebung v0.3, Stories v0.3, Spec v0.1 (Entwurf) | 2b – nach GR, vor FI (Product Owner 22.10.2026) | AD → Rechte mit Reichweite „Referat“, Namensfunktionen, Anlegen von Aktiven, Stammdaten Orte (eingearbeitet in spec.md AD v0.8); Reichweite „Gruppe“ (Iteration 1); EA → Aktive, Referate, Funktionen; GR → Gruppen, Anwesenheitsliste zum Stichtag, eigene Gruppen für den Vorschlag (eingearbeitet in Stories GR v0.7); Touren und Kurse → geplante Kurse und Touren [OFFEN: Übernahme als Einsatz]; liefert Einsätze und Anwesenheit an FI, Einsatzhistorie an EA (Iteration 2), Auslastung an GR (Iteration 2) |
| Touren und Kurse [ANNAHME: Arbeitstitel] | [OFFEN] | Eigenständiges Planungstool: Kurse und Touren erstellen, planen und kalkulieren – Kosten, Ausgaben, Deckungsbeitrag, benötigtes Material, CO2-Berechnung; auch Anmeldung von Fahrten (inkl. Kinder- und Jugendfahrten). Vorlage: HTML-Prototyp (mit Claude erstellt) des Referenten Touren. Erhebung in eigenem Chat. | [OFFEN] Referat Touren, Referat Ausbildung, Referat Kinder und Jugend [ANNAHME] | Idee | [OFFEN] | EZ → Durchführung und Anwesenheit; FI → Abrechnung der Vergütung [OFFEN: Abgrenzung zur Kalkulation]; EA → Personen (Leitung) [ANNAHME]; GR → Gruppen (Kinder- und Jugendfahrten) [ANNAHME] |
| Finanzen | FI | Abrechnungen aus Einsätzen nach der Vergütungsordnung (Übungsleiterpauschale: Trainingseinheiten, Fahrten, Wettkampfbegleitung, Kurse, Mehrtageskurse) und aus anderen Anlässen erstellen, inkl. halbjährlicher Abrechnungsdokumente und Kontrolle der Rechnungen der Kletterhalle; Sätze der Vergütungsordnung pflegen [ANNAHME]; monatlichen Buchungslauf für Verträge als Übergabe an Finanzbuchhaltung bzw. Sparkasse erzeugen, Budget-Übersicht und Dashboard. [OFFEN: Abrechnung als eigenes Modul, das in Finanzen aufgeht (Idee Product Owner 22.10.2026)] | Geschäftsstelle | Idee | 3 – nach EZ | EA → Personen, Bankverbindung, Trainervereinbarung, Lizenzen, Bestätigung steuerfreie Einnahmen lesen; EZ → Einsätze und Anwesenheit mit Rolle lesen; GR → Verträge; SC → E-Mail-Versand [ANNAHME]; offen: Übergabe aus der Anwesenheitserfassung v1.5 (Vergütungsordnung, Zuordnung der Einsatzarten, Kletterhalle); Abgrenzung zu Touren und Kurse (Kalkulation dort, Vergütung hier [ANNAHME]) |
| Öffentlichkeitsarbeit | OA | Pressemitteilungen und Instagram-Beiträge erstellen; Umfragen über Schnittstellen. [ANNAHME: Umfragen gehören hierher] | Geschäftsstelle [ANNAHME] | Idee | 4 | SC → Instagram, Umfrage-Dienst; weitere [OFFEN] |
| Projektmanagement | PM | [OFFEN] Projekte mit Aufgaben planen und nachhalten. | [OFFEN] | Idee | 5 (gemeinsam mit GS, AM) | AM → Aufgaben, Erinnerungen; EA → Personen (Zuständige) [ANNAHME] |
| Geschäftsstellenmanagement | GS | Aufgaben der Geschäftsstelle nachhalten: Aufgaben sich selbst oder anderen zuweisen, Checklisten (z. B. Förderunterlagen) mit Fristen und Erinnerungen, wiederkehrende Abläufe (wöchentlich, monatlich). | Geschäftsstelle | Idee | 5 (gemeinsam mit PM, AM) | AM → Aufgaben, Checklisten, Erinnerungen |
| Aufgabenmanagement | AM | Gemeinsame Basis für Aufgaben, Checklisten, Fristen und Erinnerungen, die GS und PM nutzen. | alle Nutzer | Idee | 5 (gemeinsam mit PM, GS) | AD → Nutzer (Zuweisung); SC → E-Mail-Versand für Erinnerungen [ANNAHME] |

### Umfang Anwesenheitserfassung (EZ) im MVP

Siehe docs/specs/ez-einsaetze/00-steckbrief.md (v0.7), 01-erhebung.md (v0.3), 02-stories.md (v0.3) und spec.md (v0.1). Kurzfassung:

- Einsatzarten (Bezeichnungen wie im heutigen Forms-Formular): Training, Tagesausflug, Mehrtagesfahrt, Ausbildungsfahrt und Wettkampfbegleitung (je ein- oder mehrtägig), Arbeitseinsatz (auch Europacup, Bergfilmfestival); Erfassung von Gruppen-Einsätzen immer je Gruppe. Kurs, Tour, Trainingslager sind im Datenmodell vorgesehen und werden nach Klärung mit dem Modul Touren und Kurse freigeschaltet.
- Trainings: Trainingszeit der Gruppe als Vorschlag, Ort aus den Stammdaten der Administration; ein Training entsteht erst mit der Erfassung (Ferien: nichts erfassen). Wer selbst Gruppenleitung, Trainer:in oder Helfer:in ist, bekommt seine Gruppe vorgeschlagen (ohne zusätzliche Rechte).
- Fahrten: Titel, organisierende Person (Suche über alle Aktiven, Personen der Gruppe zuerst); eintägig Datum und Dauer „unter / mindestens 8 Stunden“; mehrtägig Startdatum, Beginn, Enddatum, Ende (ab bzw. bis Startort).
- Anwesenheit mit Rolle (Trainer:in, Helfer:in, Teilnehmer:in): Gruppe zum Stichtag (mehrtägig: Startdatum) vorbelegt zum Ankreuzen, Kinder mit Vor- und Nachname; Vertretung hinzufügen; Probetraining als Freitext (nur Vorname); Bemerkung mit Hinweis; beim Arbeitseinsatz eingetragen / anwesend / nicht erschienen, neue Personen werden als Aktive angelegt.
- Einsatzart und Gruppe nach dem Speichern nicht änderbar; Löschen nur durch die Geschäftsstelle.
- Einfache Listen inkl. Kontrollliste für das Punktekonto der Kletterhalle (nur Kinder, je Ort); mobil ab 375 px, kein Offline-Betrieb.
- Erfassung durch Geschäftsstelle und Referent:innen; Gruppenleitungen und Trainer:innen ab Iteration 1; Auswertungen auf Gruppenebene (inkl. Betreuungsschlüssel) und Einsatzhistorie ab Iteration 2.
- Nicht hier: Erstellung, Planung, Kalkulation und Anmeldung von Kursen, Touren und Fahrten (Modul Touren und Kurse); Erwachsenenfahrten (später, gleiche Logik).

## Gemeinsame Basisdaten

Begriffe nach glossar.md.

| Basisdaten | Beschreibung | Gepflegt in | Genutzt von |
|---|---|---|---|
| Zugang / Nutzer | Login einer Person (Login-Adresse @dav-leipzig.de, Status). Nutzer = Person mit aktivem Zugang. MVP: 3 Mitarbeitende der Geschäftsstelle, 1. Vorsitzender, Notfall-Admin, danach Referent:innen und Hüttenwart:innen. | AD | alle |
| Recht / Rechtevorlage | Erlaubnis aus Modul, Objekt, Aktion und Reichweite; im MVP je Modul über Vorlagen, Reichweite „alle“ oder (EA, EZ) „Referat“; durchgesetzt per RLS. | AD | alle |
| Protokoll | Einladungen, Rechtevergaben, Änderung der Referate, Sperren, Anmeldungen des Notfall-Admins; 5 Jahre. | AD | AD |
| Einstellung / API-Key | Konfiguration externer Dienste; Keys nur serverseitig gespeichert und genutzt (mit SC). | AD | SC |
| Person | Zentrales Objekt in einer gemeinsamen Tabelle: jeder erfasste Mensch (Aktive:r, Teilnehmer:in, Erziehungsberechtigte:r, Notfallkontakt), mit optionalem Rufnamen; getrennt von der Mitgliederverwaltung. Sichtbar in EA und GR nur bei Zugehörigkeit; in EZ nur Name: über die Anwesenheitsliste der Gruppe zum Stichtag, gespeicherte lesbare Einsätze und die Suche über alle Aktiven; der Admin sieht alle Personen. Ca. 250 Aktive, davon ca. 130 Trainer:innen in der ersten Migration; 150–200 Teilnehmer:innen. Sonderfall Funktionsperson (nur AD). | AD (Datenmodell, Personen mit Zugang), EA (Aktive, Migration per Skript), GR (Teilnehmer:innen usw.), EZ (Aktive aus Arbeitseinsätzen) | alle |
| Ehrenamtsstatus | aktiv, ruhend, ausgeschieden; für die ganze Person, mit Historie; bestimmt die Sichtbarkeit im Ehrenamtsmanagement. | AD (Datenmodell, Funktionen), EA (Oberfläche) | EA, GR, EZ, FI |
| Eigenschaft / Eigenschaftsart | Zeitlich gültiger Eintrag an einer Person mit Historie; Eigenschaftsarten mit Zweck, Kategorie, 1–n Feldern, Bezug, „sichtbar in“ und Lesestufe; anlegen System, Geschäftsstelle (EA) oder Admin (AD). | AD, EA | alle |
| Lesestufe | Wer Eigenschaften einer Art lesen darf: alle mit Zugriff · nur Geschäftsstelle und Admin („verwalten“ im jeweiligen Modul) · vertraulich (nur AD-Rechte). | AD, EA | alle |
| Amt | Gewählte Position mit Amtszeit, ggf. mit Bezug auf Referat oder Gremium. Beispiele: 1. Vorsitzender, Referent:in Ausbildung, Hüttenwart:in Karl-Stein-Hütte, Mitglied Beirat. | EA | alle |
| Funktion | Nicht gewählte ehrenamtliche Tätigkeit, ggf. mit Bezug auf Referat oder Gruppe. Funktionen mit Bezug auf eine Gruppe pflegt GR. Beispiel: Toni Werner – Trainer, Referat Klettern. | EA, GR | GR, EZ, FI |
| Hauptamt | Anstellung bei der Sektion; vertrauliche Eigenschaft, nur in AD sichtbar. | AD | AD |
| Qualifikationsart | Stammdaten: Kürzel, Bezeichnung, Sparte (Klassifizierung des Bundesverbands), Typ (Lizenz, Zusatzqualifikation, Lehrgang, Weiterbildung), Lizenzstufe, Spezifikation, Aussteller, DOSB-lizenzfähig, Gültigkeitsdauer, Status (aktuell, historisch). Startbestand 47. Keine Personendaten. | AD (Admin; Geschäftsstelle über EA) | EA, GR, EZ, FI (förderfähige Lizenz) |
| Qualifikation | Lizenz, Zusatzqualifikation, Lehrgang oder Weiterbildung an einer Person; verweist auf eine Qualifikationsart; Lizenznummer, Ablaufdatum (falls Gültigkeitsdauer), Fortbildungen. Beispiel: Toni Werner – Trainer*in C Sportklettern Breitensport Indoor. | EA | GR, EZ, FI |
| Nachweis | Pflichtinformation für bestimmte Tätigkeiten, z. B. Führungszeugnis-Einsicht (nur Datum, nie Inhalt), Ehrenkodex, Trainervereinbarung, Bestätigung steuerfreie Einnahmen, Erklärung zur Ehrenamtspauschale. | EA | GR, FI |
| Bankverbindung (Aktive) | Kontoinhaber:in und IBAN einer aktiven Person für die Trainerabrechnung; Lesestufe „nur Geschäftsstelle und Admin“. | EA | FI |
| Referat | Organisatorische Einheit mit eigener Zuständigkeit und Sicht: Ausbildung, Touren, Kinder und Jugend, Klettern, Leistungssport, Karl-Stein-Hütte, Sulzenauhütte. Grundlage der Reichweite „Referat“. | AD (Tabelle, Startbestand per Migration), EA (Pflege-Oberfläche) | AD, EA, GR, EZ, FI, OA |
| Gremium | Gewähltes Gremium mit Sicht nur zum Lesen: Vorstand, Beirat, Ehrenrat, Jugendausschuss. | AD (Tabelle, Startbestand per Migration), EA (Pflege-Oberfläche) | EA |
| Ort | Stammdaten der Trainingsorte (Bezeichnung, Kennzeichen „Punktekonto Kletterhalle“ [ANNAHME], aktiv/inaktiv); Auswahl beim Training, Grundlage der Kontrolle des Punktekontos. Pflege nur durch den Admin; Startliste liefert der Product Owner bei der Umsetzung. | AD (Admin; Product Owner 22.10.2026) | EZ, FI |
| Einsatz / Einsatzserie | Einzelner Einsatz (Training, Tagesausflug, Mehrtagesfahrt, Ausbildungsfahrt, Wettkampfbegleitung, Arbeitseinsatz; später Kurs, Tour, Trainingslager) mit Referat, ggf. Gruppe, Titel und organisierender Person; Zeiten je nach Art (Training: Datum, Beginn, Ende, Ort; eintägig: Datum, Dauer-Kategorie; mehrtägig: Startdatum, Beginn, Enddatum, Ende). Trainings mit Vorschlag aus den Trainingszeiten der Gruppen; ein Training entsteht erst mit der Erfassung. Grundlage für „letzter Einsatz“, Auswertung und Abrechnung. | EZ | EA (Einsatzhistorie, Iteration 2), GR (Auslastung, Iteration 2), FI |
| Anwesenheit | Zuordnung einer Person zu einem Einsatz mit Stand eingetragen, anwesend oder nicht erschienen und Rolle (Trainer:in, Helfer:in, Teilnehmer:in); bei Trainings zusätzlich Probetraining als Freitext (nur Vorname). | EZ | EA, FI |
| Veranstaltung | Einzelne Veranstaltung der Sektion (z. B. Europacup, Bergfilmfestival); wird in der Anwesenheitserfassung als Arbeitseinsatz eines Referats erfasst, ohne eigene Rechte für Projektteams. | EZ | FI, OA |
| Trainingszeit | Strukturierte Trainingszeit einer Gruppe (Wochentag, Beginn, Ende, gültig von/bis); Vorschlag beim Erfassen eines Trainings. | GR | EZ |
| Kalkulation (Kurs, Tour) | Planungsrechnung vor der Durchführung: Kosten, Ausgaben, Deckungsbeitrag, Material, CO2. | Touren und Kurse | [OFFEN] FI |
| Sätze der Vergütungsordnung | Trainingseinheit (30 Minuten) mit Betrag je Rolle, Tages- und Halbtagessätze, Organisationspauschale, Wettkampfbegleitung, Lehreinheit; mit gültig ab, ohne Code-Änderung pflegbar (Vorstand kann die Vergütungsordnung jederzeit ändern). | FI [ANNAHME] | FI, ggf. Touren und Kurse (Kalkulation) [ANNAHME] |
| Gruppe | Gruppe mit Gruppenleitung(en) und Teilnehmern. | GR | EZ, FI [OFFEN], OA [OFFEN] |
| Teilnehmer:in | Person in einer Gruppe; Details im Steckbrief GR. | GR | EZ (nur Name), FI [OFFEN] |
| Aufgabe | Aufgabe mit Zuständigkeit, Frist und Erinnerung; ggf. Teil einer Checkliste. | AM | GS, PM |

Regeln:
- Eine Person kann gleichzeitig beliebig viele Eigenschaften haben (auch mehrere derselben Art) und mehreren Referaten zugeordnet sein.
- Personendaten werden einmal gepflegt (gemeinsame Tabelle); andere Module verweisen darauf und kopieren sie nicht. Fachmodule sehen nur Personen, die zu ihnen gehören; der Admin sieht alle.
- Stammdaten (Referate, Gremien, Qualifikationsarten, Orte) werden einmal gepflegt; Module verweisen darauf, statt Text zu kopieren.
- Ein Zugang hängt immer an genau einer Person; Login-Adresse (Zugang) und Kontaktadresse (Eigenschaft) sind getrennt.
- Rechte werden in AD vergeben und in jedem Modul per RLS durchgesetzt; es gibt kein eigenes Rechte-Modul. Vorschläge in der Oberfläche (z. B. eigene Gruppe in EZ) geben keine Rechte.
- API-Keys liegen nie im Frontend und nie in einer für Nutzer lesbaren Tabelle; externe Aufrufe laufen nur serverseitig.
- „Vorstand“ (Amt, Gremium, Rechtevorlage) und „Referent:in“ (Amt, Rechtevorlage) sind im Code getrennte Objekte.
- „Sparte“ (Qualifikationsarten) und „Referat“ (Organisation) sind getrennt; aus der Sparte entstehen keine Rechte.
- Planung und Kalkulation (Touren und Kurse) → Durchführung und Anwesenheit (Anwesenheitserfassung) → Vergütung (Finanzen bzw. Abrechnung). Die Anwesenheitserfassung erhebt und speichert; Abrechnung und Auswertungen über einfache Listen hinaus liegen in anderen Modulen.

## Hinweise

- Vision-Ziel Z3 (Aufgaben mit Erinnerungen in 12 Monaten) bleibt bestehen, obwohl AM auf Priorität 5 steht. Risiko: Z3 wird nur erreicht, wenn alle Module davor innerhalb von 12 Monaten fertig sind.
- Vertretung für den Admin-Zugang: Mitarbeiter:in der Geschäftsstelle, nicht im ersten Schritt. Bis dahin Notfall-Admin.
- Reihenfolge AD vor EA und GR: Das Personenmodell entsteht in AD. Der Nachtrag v0.7.1 ist freigegeben und muss vor Umsetzung von EA und GR umgesetzt sein. Die Qualifikationsarten (AD v0.6) müssen vor der Migration der Aktivenliste in PROD sein.
- Reihenfolge der Fachmodule nach EA (Product Owner 22.10.2026): Gruppen → Anwesenheitserfassung → Finanzen. Die Anwesenheitserfassung braucht vorher den Nachtrag v0.8 der Administration (T50–T58) und aus Gruppen US-GR-18 bis US-GR-20 (Trainingszeiten, `gr_groups_for_attendance`, `gr_group_roster`, `gr_my_groups`).
- Nach Abnahme von AD und EA wird der Regelbetrieb geprüft; die übrigen Module folgen iterativ.
- Einsätze wurden am 21.10.2026 aus EA in das Modul EZ verschoben; das Modul heißt seit 21.10.2026 Anwesenheitserfassung (Steckbrief v0.7 abgeschlossen, Erhebung v0.3, Stories v0.3, Spec v0.1). Entschieden: Trainerabrechnung in FI; Veranstaltungen als Arbeitseinsätze; Kurse und Touren werden dort erfasst (Durchführung, nach Klärung mit Touren und Kurse); Zeiten bei Fahrten wie im heutigen Formular, mehrtägig mit Enduhrzeit; Reisezeit = Arbeitszeit ohne Vorstandsbeschluss. Offen: Navigation.
- Struktur Finanzen (Idee Product Owner 22.10.2026): Abrechnung ggf. als eigenes Modul, das in Finanzen aufgeht; Entscheidung mit der Navigation.
- Modul Touren und Kurse (22.10.2026): eigenständiges Planungstool (Erstellung, Planung, Kalkulation inkl. CO2 und Deckungsbeitrag; Anmeldung von Fahrten). HTML-Prototyp des Referenten Touren folgt. Offen beim Steckbrief: wie aus einem geplanten Kurs bzw. einer Tour ein Einsatz in EZ wird; Abgrenzung Kalkulation zu Abrechnung in FI.
- Das Microsoft-Forms-Formular für Trainings läuft bis Iteration 1 von EZ parallel (Erfassung durch Gruppenleitungen und Trainer:innen setzt Reichweite „Gruppe“ in AD voraus); Abschalttermin nicht Teil des Steckbriefs. Fristen der halbjährlichen Abrechnung (31.07., 15.12.) gelten unabhängig davon.
- Datenschutz GR: Teilnehmer von Kinder- und Jugendgruppen sind Minderjährige; Datenumfang im Steckbrief GR festgelegt. EZ zeigt Teilnehmer:innen nur mit Vor- und Nachname, auch Referent:innen.
- Offene Punkte je Modul: siehe offene-punkte.md.
