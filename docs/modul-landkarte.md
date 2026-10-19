# Modul-Landkarte: Vereins OS

Stand: 19.10.2026 · Version 0.6

## Basismodule

| Modul | Kürzel | Zweck in einem Satz | Hauptnutzer | Status | Priorität | Abhängigkeiten |
|---|---|---|---|---|---|---|
| Administration | AD | Login, Personen mit Zugang anlegen, Nutzer einladen und sperren, Rechtevorlagen pflegen und zuweisen, Eigenschaftsarten und Eigenschaften pflegen; später API-Keys (mit SC). | Admin (MVP: Product Owner; Notfall-Admin über Postfach der Geschäftsstelle; Vertretung später: Mitarbeiter:in der Geschäftsstelle) | Stories | 0 – erstes Modul | liefert Nutzer und Rechte an alle Module; baut die Grundstruktur des Personenmodells für EA; extern: Supabase Auth mit Gmail als SMTP |
| Schnittstellen-Connector | SC | Externe Dienste zentral und generisch anbinden: Instagram, Umfrage-Dienst, E-Mail-Versand aus Abläufen; offen für DATEV. Mit SC kommt die API-Key-Verwaltung in AD. | Admin (Konfiguration); Module (Nutzung) | Idee | spätestens mit OA (4) [ANNAHME] | AD → API-Keys; genutzt von OA, AM, FI [ANNAHME] |

### Umfang AD im MVP

Siehe docs/specs/ad-administration/00-steckbrief.md. Kurzfassung:

- Login über Supabase Auth (E-Mail und Passwort, nur @dav-leipzig.de); Einladung nur auf Knopfdruck je Person; „Passwort vergessen“ per Link. Login-Mails über das Google-Konto der Sektion.
- Startseite als Platzhalter (Willkommensgrafik); sichtbar nur Module mit Rechten.
- Personen anlegen mit Dublettenwarnung; Zugang einrichten, einladen, sperren und entsperren.
- Rechtevorlagen je Modul anlegen, ändern, zuweisen (mehrere je Person).
- Eigenschaftsarten (Zweck, Datentyp, „sichtbar in“, „vertraulich“) und Eigenschaften pflegen.
- Notfall-Admin, Protokoll (5 Jahre), Testzugänge je Vorlage in TEST.
- Nach MVP bzw. mit SC: API-Key-Verwaltung inkl. Erinnerung vor Ablauf, Einzelrechte, Befristung, SSO.

## Fachmodule

| Modul | Kürzel | Zweck in einem Satz | Hauptnutzer | Status | Priorität | Abhängigkeiten |
|---|---|---|---|---|---|---|
| Ehrenamtsmanagement | EA | Personen mit ihren Eigenschaften (Mitglied, Amt, Funktion, Qualifikation, Nachweis, Kontaktdaten, frei definierte Felder) und Einsätzen erfassen und für Einsätze auswählen; Excel-Import mit Dublettenprüfliste und Zusammenführen, Filter aktiv/ausgeschieden, Löschlauf nach 5 Jahren; löst die Excel-Liste der Aktiven ab. | Geschäftsstelle, Vorstand | Idee | 1 | AD → Nutzer, Rechte, Grundstruktur Personenmodell (Person, Eigenschaftsart, Eigenschaft); blendet Funktionspersonen aus; liefert Personen, Eigenschaften, Einsätze an alle Fachmodule |
| Gruppen | GR | Gruppen im Kinder-, Jugend- und Erwachsenenbereich mit Gruppenleitungen und Teilnehmern verwalten; löst die Excel-Teilnehmerlisten ab. | Geschäftsstelle | Idee | 2 | EA → Personen (Gruppenleitungen) lesen |
| Finanzen | FI | Abrechnungen aus Einsätzen und anderen Anlässen erstellen, monatlichen Buchungslauf für Verträge als Übergabe an Finanzbuchhaltung bzw. Sparkasse erzeugen, Budget-Übersicht und Dashboard. | Geschäftsstelle | Idee | 3 | EA → Personen, Einsätze lesen; GR → [OFFEN] ob Verträge an Gruppen hängen; SC → E-Mail-Versand [ANNAHME] |
| Öffentlichkeitsarbeit | OA | Pressemitteilungen und Instagram-Beiträge erstellen; Umfragen über Schnittstellen. [ANNAHME: Umfragen gehören hierher] | Geschäftsstelle [ANNAHME] | Idee | 4 | SC → Instagram, Umfrage-Dienst; weitere [OFFEN] |
| Projektmanagement | PM | [OFFEN] Projekte mit Aufgaben planen und nachhalten. | [OFFEN] | Idee | 5 (gemeinsam mit GS, AM) | AM → Aufgaben, Erinnerungen; EA → Personen (Zuständige) [ANNAHME] |
| Geschäftsstellenmanagement | GS | Aufgaben der Geschäftsstelle nachhalten: Aufgaben sich selbst oder anderen zuweisen, Checklisten (z. B. Förderunterlagen) mit Fristen und Erinnerungen, wiederkehrende Abläufe (wöchentlich, monatlich). | Geschäftsstelle | Idee | 5 (gemeinsam mit PM, AM) | AM → Aufgaben, Checklisten, Erinnerungen |
| Aufgabenmanagement | AM | Gemeinsame Basis für Aufgaben, Checklisten, Fristen und Erinnerungen, die GS und PM nutzen. | alle Nutzer | Idee | 5 (gemeinsam mit PM, GS) | AD → Nutzer (Zuweisung); SC → E-Mail-Versand für Erinnerungen [ANNAHME] |

## Gemeinsame Basisdaten

Begriffe nach glossar.md.

| Basisdaten | Beschreibung | Gepflegt in | Genutzt von |
|---|---|---|---|
| Zugang / Nutzer | Login einer Person (Login-Adresse @dav-leipzig.de, Status). Nutzer = Person mit aktivem Zugang. MVP: 3 Mitarbeitende der Geschäftsstelle, 1. Vorsitzender, Notfall-Admin. | AD | alle |
| Recht / Rechtevorlage | Erlaubnis aus Modul, Objekt, Aktion und Reichweite; im MVP nur je Modul über Vorlagen; durchgesetzt per RLS. | AD | alle |
| Protokoll | Einladungen, Rechtevergaben, Sperren, Anmeldungen des Notfall-Admins; 5 Jahre. | AD | AD |
| Einstellung / API-Key | Konfiguration externer Dienste; Keys nur serverseitig gespeichert und genutzt (mit SC). | AD | SC |
| Person | Zentrales Objekt: jeder erfasste Mensch, Mitglied oder Nicht-Mitglied; getrennt von der Mitgliederverwaltung. Ca. 250 Aktive. Sonderfall Funktionsperson (nur AD). | AD (Grundstruktur, Personen mit Zugang), EA (alle übrigen, Import) | GR, FI, PM, AM |
| Eigenschaft / Eigenschaftsart | Zeitlich gültiger Eintrag an einer Person mit Historie; Eigenschaftsarten mit Zweck, Datentyp, „sichtbar in“, „vertraulich“; anlegen System, Geschäftsstelle (EA) oder Admin (AD). | AD, EA | alle |
| Amt | Gewählte Position mit Amtszeit. Beispiel: Toni Werner – 1. Vorsitzender. | EA | alle |
| Funktion | Nicht gewählte ehrenamtliche Tätigkeit, ggf. mit Bezug auf Gruppe oder Bereich. Beispiel: Toni Werner – Trainer. | EA | GR, FI |
| Hauptamt | Anstellung bei der Sektion; vertrauliche Eigenschaft, nur in AD sichtbar. | AD | AD |
| Qualifikation | Lizenz (Stufe + Spezifikation, mit Ablaufdatum) oder Weiterbildung. Beispiel: Toni Werner – Trainer C Sportklettern. | EA | GR, FI |
| Nachweis | Pflichtinformation für bestimmte Tätigkeiten, z. B. Führungszeugnis-Einsicht (nur Datum, nie Inhalt). | EA | GR |
| Bereich | Tätigkeitsfeld, z. B. Jugend, Ausbildung, Bergfilmfestival, Europacup. | EA | GR, FI, OA |
| Einsatz / Einsatzserie | Einzelne Tätigkeit an einem Termin; wiederkehrende Einsätze (z. B. wöchentliches Training) als Serie, jede Einheit einzeln erfasst. Grundlage für „letzter Einsatz“, Auswertung und Abrechnung. | EA | FI |
| Gruppe | Gruppe mit Gruppenleitung(en) und Teilnehmern. | GR | FI [OFFEN], OA [OFFEN] |
| Teilnehmer:in | Person in einer Gruppe; nur Zugehörigkeit gepflegt. [OFFEN] Liegen Teilnehmer in derselben Personen-Tabelle wie Aktive? | GR | FI [OFFEN] |
| Aufgabe | Aufgabe mit Zuständigkeit, Frist und Erinnerung; ggf. Teil einer Checkliste. | AM | GS, PM |

Regeln:
- Eine Person kann gleichzeitig beliebig viele Eigenschaften haben (Ämter, Funktionen, Hauptamt, Qualifikationen, Nachweise).
- Personendaten werden einmal gepflegt (AD bzw. EA, gleiche Tabellen); andere Module verweisen darauf und kopieren sie nicht. [ANNAHME]
- Ein Zugang hängt immer an genau einer Person; Login-Adresse (Zugang) und Kontaktadresse (Eigenschaft) sind getrennt.
- Rechte werden in AD vergeben und in jedem Modul per RLS durchgesetzt; es gibt kein eigenes Rechte-Modul.
- API-Keys liegen nie im Frontend und nie in einer für Nutzer lesbaren Tabelle; externe Aufrufe laufen nur serverseitig.

## Hinweise

- Vision-Ziel Z3 (Aufgaben mit Erinnerungen in 12 Monaten) bleibt bestehen, obwohl AM auf Priorität 5 steht. Risiko: Z3 wird nur erreicht, wenn alle Module davor innerhalb von 12 Monaten fertig sind.
- Vertretung für den Admin-Zugang: Mitarbeiter:in der Geschäftsstelle, nicht im ersten Schritt. Bis dahin Notfall-Admin.
- Reihenfolge AD vor EA: Das Personenmodell entsteht in AD; EA muss es ohne Umbau erweitern können.
- Datenschutz GR: Teilnehmer von Kinder- und Jugendgruppen sind Minderjährige; Datenumfang im Steckbrief GR festlegen.
- Offene Punkte je Modul: siehe offene-punkte.md.
