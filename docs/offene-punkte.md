# Offene Punkte je Modul: Vereins OS

Stand: 20.10.2026 · Version 0.6

Jeder Abschnitt wird beim Steckbrief des Moduls in „Offene Fragen“ übernommen und dort geklärt. Erledigte Punkte werden hier gestrichen.

## AD – Administration (Priorität 0)

- [OFFEN] Vertretung des Admin-Zugangs: welche:r Mitarbeiter:in der Geschäftsstelle, ab wann? Kein Blocker. (00-steckbrief.md AD)
- [OFFEN] Weg der Migrationen nach PROD: manuell durch den Product Owner oder GitHub Action beim Merge auf main? Vor dem ersten PROD-Deployment. (spec.md AD Abschnitt 11)

## EA – Ehrenamtsmanagement (Priorität 1)

- [OFFEN] Ist eine Person mit nur einem Einsatz (z. B. einmalige Helferin) Aktive:r, und wie lange? (glossar.md)
- [OFFEN] Kann jemand die Funktion Trainer:in ohne Lizenz haben? (glossar.md)
- [OFFEN] Vollständige Liste der Lizenzarten nach DAV-Ausbildungsstruktur als Stammdaten. (glossar.md)
- [OFFEN] Haben Weiterbildungen (z. B. Erste Hilfe) ein Ablaufdatum? (glossar.md)
- [OFFEN] Für welche Funktionen ist die Führungszeugnis-Einsicht Pflicht, und nach wie vielen Jahren wird sie erneuert? (glossar.md)
- [OFFEN] Gibt es weitere Nachweise außer der Führungszeugnis-Einsicht? (glossar.md)
- [OFFEN] Ist „Bereich“ als eigener Begriff nötig, oder reichen Gruppe und Funktion? (glossar.md)
- [OFFEN] Ist „Mitarbeiter:in Mitgliederverwaltung“ eine ehrenamtliche Funktion oder ein Hauptamt? (glossar.md)
- [OFFEN] Person, deren letzte Eigenschaft vor mehr als 5 Jahren endete: ganz löschen oder Stammdaten behalten? (rollen.md)
- [OFFEN] Löschung des Zugangs (Supabase-Auth-Eintrag), wenn eine Person nach der 5-Jahres-Regel gelöscht wird. (01-erhebung.md AD)
- [OFFEN] Excel-Import: Spaltenzuordnung, Ablauf der Dublettenprüfliste (übernehmen / überspringen / zusammenführen), Regeln für das Zusammenführen (Eigenschaften, Historie, Einsätze). (00-steckbrief.md AD)

## GR – Gruppen (Priorität 2)

- [OFFEN] Liegen Teilnehmer:innen in derselben Personen-Tabelle wie Aktive? (modul-landkarte.md)
- [OFFEN] Welche Daten zu Teilnehmer:innen werden gespeichert (Minderjährige, ggf. Eltern als Kontakt)? (modul-landkarte.md)
- [OFFEN] Nutzen FI und OA Gruppendaten, und welche? (modul-landkarte.md)

## FI – Finanzen (Priorität 3)

- [OFFEN] Was ist ein „Vertrag“ im Bereich Kinder und Jugend? Wird er in FI oder GR geführt, hängt er an einer Gruppe? (vision.md, glossar.md, modul-landkarte.md)
- [OFFEN] Richtung des Buchungslaufs (Auszahlung oder Einzug) und Empfänger der Mails. (vision.md)
- [OFFEN] Übergabe: DATEV-Buchungsexport oder SEPA-Datei; Datei-Export oder Schnittstelle über SC? (vision.md, modul-landkarte.md)
- [OFFEN] Aufbewahrungsfristen für Abrechnungsdaten (Steuer, Buchhaltung) gegenüber der 5-Jahres-Regel. (rollen.md)

## OA – Öffentlichkeitsarbeit (Priorität 4)

- [OFFEN] Gehören Umfragen zu OA? Welcher Umfrage-Dienst? (modul-landkarte.md)
- [OFFEN] Weitere Abhängigkeiten zu anderen Modulen. (modul-landkarte.md)

## SC – Schnittstellen-Connector (spätestens mit OA)

- [OFFEN] API-Key-Verwaltung als Erweiterung von AD: Felder, Anzeige der letzten Zeichen, Erinnerung vor Ablauf per E-Mail. (modul-landkarte.md, 00-steckbrief.md AD)
- Weitere Anforderungen kommen aus FI (DATEV/Sparkasse) und OA (Instagram, Umfragen).

## PM, GS, AM – Projekt-, Geschäftsstellen-, Aufgabenmanagement (Priorität 5)

- [OFFEN] Inhalt, Hauptnutzer und Abgrenzung von PM gegenüber GS. (modul-landkarte.md)
- [OFFEN] Werden Aufgaben nur Nutzern oder auch Personen ohne Login zugewiesen? (modul-landkarte.md)
- [OFFEN] Messgröße für Vision-Ziel Z3 (Aufgaben mit Erinnerungen). (vision.md)

## Übergreifend

- [OFFEN] Zeitpunkt und Umfang des Rollouts sowie Rechte und Reichweiten für weitere Personen mit Amt, Gruppenleitungen und Aktive. (vision.md, rollen.md)

## Merkposten nach MVP

- Personenakte / Hinweise an Personen (Zweck, Inhalt, Leserechte, Löschfrist klären; DSGVO Art. 15).
- Einzelrechte, Rechte je Objekt, Reichweiten Bereich / Gruppe / nur eigene.
- Befristung der Zuweisung einer Rechtevorlage in der Oberfläche.
- Startkonfiguration der Rechtevorlage Vorstand (Admin konfiguriert in der Oberfläche).
- E-Mail-Benachrichtigung bei Anmeldung des Notfall-Admins (mit SC).
- Einstellungen verwalten (AD).
- SSO über den Microsoft-Tenant (Zustimmung und Mitwirkung des Bundesverbands nötig).
- Login für Aktive.
- Login-Adresse nach der Aktivierung ändern (z. B. Namensänderung).
- Supabase MCP erneut prüfen (OAuth mit projektgebundener URL).
- Sicherheitshinweis in shadcn-CLI (braces) vor Go-live mit `npm audit` prüfen.
- Vorschau-URLs mit Cloudflare Access schützen.
- GitHub: gemeinsames Konto DAVLeipzig in eine Organisation überführen.

## Erledigt am 19.10.2026

| Punkt | Entscheidung |
|---|---|
| Spec Kit und `docs/specs/<modul>/` | bestätigt: `docs/specs/<modul>/` führend, Spec Kit erzeugt plan.md und tasks.md |
| Tabellen-Präfix oder Schema | Präfix nach Modulkürzel, kein eigenes Schema |
| Backup PROD | nicht im Scope, Risiko akzeptiert |
| Auftragsverarbeitungsvertrag Cloudflare | schließt der Product Owner ab |
| Zuständig für Datenschutz | Toni Werner |
| Vorstand vs. Geschäftsstelle | unterschiedliche, konfigurierbare Rechtevorlagen; Vorstand grundsätzlich weniger Rechte |
| Zählen bezahlte Trainer:innen als Aktive? | ja, wenn kein Anstellungsverhältnis (Ehrenamt kann vergütet sein; Hauptamt = Anstellung) |
| Nutzer und Person | jeder Zugang hängt an einer Person; AD baut die Grundstruktur des Personenmodells |
| Rechte im MVP | nur Rechtevorlagen je Modul, Reichweite „alle“; Admin hat AD, SC, EA verwalten |
| Startkonfiguration Vorstand (AD) | Vorlage ohne Rechte; Konfiguration durch den Admin nach MVP |
| Erinnerung vor Ablauf eines API-Keys (AD) | verschoben zu SC |
| Schutz vor Aussperren | Notfall-Admin über geschaeftsstelle@dav-leipzig.de; Risiko des gemeinsamen Postfachs akzeptiert |
| Login-Mails | Supabase Auth mit Gmail als SMTP; Einladung nur auf Knopfdruck |
| Login-Adresse bei „eingeladen“ ändern (AD) | nimmt die Einladung zurück; alter Link ungültig |
| Fehlgeschlagene Einladungs-Mail (AD) | ad-invite räumt auf, Status bleibt |
| Abnahme Mail-Abläufe in TEST (AD) | eigene private Adressen des Product Owners; zusätzliche Domain nur in TEST (ad_test_login_domains); Aufräumen im TEST-Dashboard (20.10.2026) |
