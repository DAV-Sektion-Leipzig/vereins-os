# Glossar: Vereins OS

Stand: 19.10.2026 · Version 0.4

Regel: ein Begriff pro Sache. Synonyme stehen nur in „Nicht verwechseln mit“. Im Code (Datenbank) englisch, in der Oberfläche deutsch.

## Verein und Umfeld

| Begriff | Definition | Nicht verwechseln mit | Beispiel |
|---|---|---|---|
| Sektion | Die Sektion Leipzig des Deutschen Alpenvereins: eigenständiger eingetragener Verein, gemeinnützig, mit Freistellungsbescheid des Finanzamts. Betreiberin des Vereins OS. | Verein (Synonym, nicht verwenden); Bundesverband | „Die Sektion ist Mitglied im Stadtsportbund.“ |
| Bundesverband | Übergeordnete Instanz des Deutschen Alpenvereins mit Sitz in München; die Sektion ist dort Mitglied. Präsident (Stand 10/2026): Roland Stierle. | DAV (umgangssprachlich für beides); Sektion | Lizenzausbildungen orientieren sich an den Vorgaben des Bundesverbands. |
| Stadtsportbund | Stadtsportbund Leipzig; die Sektion ist dort Mitglied. | Landessportbund | – |
| Landessportbund | Landessportbund Sachsen; die Sektion ist über den Stadtsportbund dort Mitglied. | Stadtsportbund | – |
| Geschäftsstelle | Hauptamtliche Verwaltung der Sektion mit 3 Mitarbeitenden; Hauptnutzer des Vereins OS. | Vorstand; Funktionsperson „Geschäftsstelle“ | Die Geschäftsstelle erstellt den monatlichen Buchungslauf. |
| Mitgliederverwaltung | Bestehendes System bzw. Aufgabe zur Führung der Vereinsmitgliedschaften. Nicht Teil des Vereins OS. | Vereins OS; Funktion „Mitarbeiter:in Mitgliederverwaltung“ | Ein- und Austritte werden in der Mitgliederverwaltung geführt. |

## Personen und Eigenschaften

| Begriff | Definition | Nicht verwechseln mit | Beispiel |
|---|---|---|---|
| Person | Oberbegriff für jeden Menschen, der im Vereins OS erfasst ist – Mitglied oder Nicht-Mitglied. Zentrales Objekt. Sonderfall: Funktionsperson. | Mitglied; Nutzer | Toni Werner ist eine Person. |
| Funktionsperson | Personendatensatz ohne Menschen dahinter; dient nur als Träger eines Funktionszugangs. Erscheint nicht in EA und fällt nicht unter die 5-Jahres-Löschung. | Person (Mensch); Funktion | Funktionsperson „Geschäftsstelle“ für den Notfall-Admin |
| Eigenschaft | Zeitlich gültiger Eintrag an einer Person (gültig von/bis, mit Historie). Eine Person kann beliebig viele Eigenschaften haben. | Feld, Attribut, Spalte | „Funktion Trainer, Gruppe X, seit 01.03.2025“ |
| Eigenschaftsart | Art einer Eigenschaft, festgelegt vom System oder angelegt von Admin bzw. Geschäftsstelle (frei definierbar wie eine Excel-Spalte). Hat Zweck, Datentyp (Text, Datum, Ja/Nein, Auswahlliste), Angabe „sichtbar in“ und Kennzeichen „vertraulich“. | Freies Feld (Synonym, nicht verwenden) | Mitglied, Amt, Funktion, Qualifikation, Kontaktdaten, Hauptamt, „T-Shirt-Größe“ |
| sichtbar in | Angabe an einer Eigenschaftsart, in welchen Modulen sie angezeigt wird. Steuert nur die Anzeige, nicht den Zugriff. | vertraulich; Reichweite | Hauptamt: sichtbar in AD |
| vertraulich | Kennzeichen an einer Eigenschaftsart: Eigenschaften dieser Art darf nur lesen, wer Rechte auf AD hat; durchgesetzt in der Datenbank. | sichtbar in | Hauptamt ist vertraulich. |
| Mitglied | Eigenschaft einer Person: ist Mitglied der Sektion (ja/nein). Die Mitgliedschaft selbst wird in der Mitgliederverwaltung geführt. | Aktive:r; Person | Eine Helferin beim Europacup ist kein Mitglied, aber Person. |
| Aktive:r | Person, die ehrenamtlich für die Sektion tätig ist – auch wenn die Tätigkeit vergütet wird –, d. h. mindestens ein gültiges Amt, eine gültige Funktion oder einen Einsatz hat. Kein Anstellungsverhältnis. [ANNAHME: Einsatz zählt mit] | Ehrenamtliche:r, ehrenamtlich Aktive:r (Synonyme, nicht verwenden); Mitglied; Hauptamtliche:r | Rund 250 Aktive, davon über 150 in Training, Jugend und Ausbildung. Vergütete Trainer:innen ohne Anstellung sind Aktive. |
| Hauptamtliche:r | Person in einem Anstellungsverhältnis mit der Sektion. Gepflegt über die vertrauliche Eigenschaftsart „Hauptamt“. Eine Person kann zugleich hauptamtlich und aktiv sein. | Aktive:r; Nutzer | Denise, Mitarbeiterin der Geschäftsstelle |
| Amt | Gewählte Position, immer für eine bestimmte Dauer (Amtszeit). | Funktion (nicht gewählt); Funktionär, Amtsträger:in (nicht verwenden) | Vorstand (z. B. 1. Vorsitzender), Referent:in, Beirat, Ehrenrat, Jugendausschuss |
| Amtszeit | Gültigkeit eines Amts von Wahl bis Ende der Wahlperiode. | Gültigkeit einer Lizenz | 1. Vorsitzender, gewählt bis [Datum] |
| Funktion | Nicht gewählte ehrenamtliche Tätigkeit einer Person, ggf. mit Bezug auf eine Gruppe oder einen Bereich. | Amt (gewählt); Hauptamt (Anstellung); Funktionsperson; Funktionär, Amtsträger:in (nicht verwenden – für Personen mit Amt gilt „Person mit Amt“) | Trainer:in, Mitarbeiter:in Ausleihe, Mitarbeiter:in Mitgliederverwaltung [OFFEN: ehrenamtlich oder hauptamtlich?] |
| Trainer:in | Funktion: leitet Training, mit Bezug (z. B. Gruppe). | Bereich; Lizenz „Trainer C“ (Qualifikation) | Toni Werner – Funktion Trainer |
| Gruppenleitung | Funktion: leitet eine Gruppe. [ANNAHME] | Trainer:in | Gruppenleitung Jugendgruppe X |
| Qualifikation | Oberbegriff für Befähigungen einer Person: Lizenz oder Weiterbildung. | Funktion (was jemand tut ≠ was jemand kann); Nachweis | Trainer C Sportklettern, Erste-Hilfe-Kurs |
| Lizenz | Qualifikation nach den Vorgaben des Bundesverbands, immer mit Ablaufdatum. Besteht aus Stufe und Spezifikation. | Weiterbildung; Funktion Trainer | Trainer C Sportklettern, Trainer B Bergsteigen, Jugendleiterlizenz |
| Lizenzstufe | Stufe einer Trainerlizenz: C, B oder A. | Spezifikation | C |
| Spezifikation | Fachrichtung einer Lizenz, nach DAV-Ausbildungsstruktur. | Lizenzstufe | Sportklettern, Bergsteigen |
| Weiterbildung | Qualifikation ohne Lizenzcharakter. [OFFEN] mit oder ohne Ablaufdatum | Lizenz | Erste-Hilfe-Kurs |
| Nachweis | Information, die die Sektion an einer Person erfassen muss, weil eine Tätigkeit sie voraussetzt. Keine Qualifikation. | Qualifikation | Führungszeugnis-Einsicht |
| Führungszeugnis-Einsicht | Nachweis, dass die Sektion das erweiterte Führungszeugnis einer Person eingesehen hat. Erforderlich vor allem für Trainer:innen im Kinder- und Jugendbereich und für Tätigkeiten in der Arbeit mit Menschen. Gespeichert wird nur: eingesehen am, Ausstellungsdatum, ohne Eintrag ja/nein – nie der Inhalt. [ANNAHME] | Qualifikation; Weiterbildung | eingesehen am 12.02.2026 |
| Bereich | Tätigkeitsfeld der Sektion, dem Funktionen, Einsätze und Gruppen zugeordnet werden. [ANNAHME] | Gruppe; Funktion; Amt | Jugend, Ausbildung, Bergfilmfestival, Europacup |
| Einsatz | Einzelne, konkrete Tätigkeit einer Person für die Sektion an einem Termin. Jede Trainingseinheit ist ein eigener Einsatz. Grundlage für „letzter Einsatz“, Auswertung und Abrechnung. | Funktion (dauerhafte Zuordnung ≠ konkrete Tätigkeit); Einsatzserie | Arbeitseinsatz am 08.11.; Helferdienst Europacup; Training Gruppe X am 14.10. |
| Einsatzserie | Wiederkehrende Folge von Einsätzen nach einem Muster; jede Einheit wird als eigener Einsatz erfasst. [ANNAHME] | Einsatz | wöchentliches Training Gruppe X, dienstags, seit März |
| Dublettenwarnung | Hinweis beim Anlegen einer Person, dass bereits eine ähnliche Person existiert (gleiche E-Mail-Adresse oder gleicher Nachname mit ähnlichem Vorname). Anlegen bleibt möglich. | Zusammenführen (EA) | „Anton Werner ähnelt Toni Werner.“ |

## Gruppen

| Begriff | Definition | Nicht verwechseln mit | Beispiel |
|---|---|---|---|
| Gruppe | Feste Gruppe im Kinder-, Jugend- oder Erwachsenenbereich mit Gruppenleitung und Teilnehmern. | Bereich; Gremium (z. B. Jugendausschuss = Amt) | Jugendgruppe X |
| Teilnehmer:in | Person, die einer Gruppe angehört. Nur die Zugehörigkeit wird gepflegt. | Aktive:r; Mitglied | Kind in Jugendgruppe X |

## System und Rechte

| Begriff | Definition | Nicht verwechseln mit | Beispiel |
|---|---|---|---|
| Vereins OS | Modulares Arbeitsinstrument der Sektion für Geschäftsstelle, Personen mit Amt und Aktive. | Mitgliederverwaltung; Finanzbuchhaltung | – |
| Modul | Fachlich abgegrenzter Teil des Vereins OS mit Kürzel. | Basismodul | EA, GR, FI |
| Basismodul | Modul, das Dienste für alle anderen bereitstellt. | Fachmodul | AD, SC |
| Zugang | Login einer Person zum Vereins OS mit Login-Adresse und Status (kein Zugang, eingeladen, aktiv, gesperrt). Hängt immer an genau einer Person. | Nutzer; Konto, Account (nicht verwenden) | Zugang von Denise, Status aktiv |
| Login-Adresse | E-Mail-Adresse, mit der sich eine Person anmeldet; immer @dav-leipzig.de. Gehört zum Zugang. | Kontaktadresse (Eigenschaft der Person) | denise.muster@dav-leipzig.de |
| Einladung | E-Mail aus dem Vereins OS, mit der eine Person ihr Passwort setzt und ihren Zugang aktiviert. Geht nur auf Knopfdruck des Admins raus. | Selbstregistrierung (gibt es nicht) | Einladung an Denise am 19.10.2026 |
| sperren | Zugang so stellen, dass kein Login mehr möglich ist. Daten bleiben erhalten; entsperren ist möglich. | deaktivieren (Synonym, nicht verwenden); löschen | Zugang beim Ausscheiden sperren |
| Nutzer | Person mit Zugang im Status „aktiv“. | Person (ohne Zugang); Zugang | Mitarbeiterin der Geschäftsstelle |
| Admin | Nutzer mit der Rechtevorlage Admin; verwaltet Zugänge, Rechte und Eigenschaftsarten. | Vorstand; Notfall-Admin | Toni Werner |
| Notfall-Admin | Zweiter Zugang mit Rechtevorlage Admin über die Login-Adresse geschaeftsstelle@dav-leipzig.de an der Funktionsperson „Geschäftsstelle“. Nur zum Schutz vor Aussperren; jede Anmeldung wird protokolliert. | Admin; Vertretung des Admins | – |
| Recht | Erlaubnis aus Modul, Objekt, Aktion und Reichweite; befristbar. Im MVP nur je Modul mit Reichweite „alle“. | Amt, Funktion (bringen keine Rechte) | EA · verwalten |
| Rechtevorlage | Fertiges, vom Admin konfigurierbares Bündel von Rechten, das einer Person zugewiesen wird. | Rolle (Synonym, nicht verwenden) | Admin, Geschäftsstelle, Vorstand |
| Einzelrecht | Recht, das der Admin einer einzelnen Person zusätzlich gibt. Nach MVP. | Rechtevorlage | – |
| Reichweite | Für welche Daten ein Recht gilt: alle, Bereich, Gruppe, nur eigene. | Sichtbarkeit (Synonym, nicht verwenden); sichtbar in | Bereich Ausbildung |
| Protokoll | Nachvollziehbare Liste der Einladungen, Vergaben und Entzüge von Rechtevorlagen, Sperren/Entsperren und Anmeldungen des Notfall-Admins (wer, wem, was, wann); 5 Jahre aufbewahrt. | Historie (frühere Werte einer Eigenschaft) | „19.10.2026 14:00 Toni Werner hat Denise Muster die Vorlage Geschäftsstelle zugewiesen.“ |
| API-Key | Zugangsschlüssel für einen externen Dienst; im Admin-Modul nachgehalten (mit SC), in Supabase Vault gespeichert. | Passwort eines Nutzers | Instagram-Key, gültig bis 30.06.2027 |

## Finanzen und Aufgaben

| Begriff | Definition | Nicht verwechseln mit | Beispiel |
|---|---|---|---|
| Vertrag | [OFFEN] Vereinbarung im Bereich Kinder und Jugend, Grundlage des monatlichen Buchungslaufs. | Lizenz | [OFFEN] |
| Abrechnung | Berechnung des Betrags, der einer Person für Einsätze oder andere Anlässe zusteht. | Buchungslauf | Trainerabrechnung Oktober |
| Buchungslauf | Monatlich erzeugte Zusammenstellung, die an die Finanzbuchhaltung bzw. die Sparkasse übergeben wird. | Abrechnung; Buchung in der Finanzbuchhaltung | Buchungslauf Verträge November |
| Aufgabe | Zu erledigende Tätigkeit mit Zuständigkeit, Frist und Erinnerung. | Einsatz | Förderantrag einreichen bis 31.01. |
| Checkliste | Geordnete Folge von Aufgaben zu einem Vorgang, ggf. wiederkehrend. | Aufgabe | Checkliste Förderunterlagen |

## Offene Punkte

- [OFFEN] Ist eine Person mit nur einem Einsatz (z. B. einmalige Helferin) Aktive:r, und wie lange?
- [OFFEN] Für welche Funktionen ist die Führungszeugnis-Einsicht Pflicht, und nach wie vielen Jahren muss sie erneuert werden?
- [OFFEN] Gibt es weitere Nachweise außer der Führungszeugnis-Einsicht?
- [OFFEN] Kann jemand die Funktion Trainer ohne Lizenz haben?
- [OFFEN] Ablaufdatum bei Weiterbildungen (z. B. Erste Hilfe).
- [OFFEN] Vollständige Liste der Lizenzarten nach DAV-Ausbildungsstruktur (Stammdaten für EA).
- [OFFEN] Definition „Vertrag“ (Modul FI).
- [OFFEN] Ist „Bereich“ als eigener Begriff nötig, oder reicht Gruppe/Funktion?
- [OFFEN] Ist „Mitarbeiter:in Mitgliederverwaltung“ eine ehrenamtliche Funktion oder ein Hauptamt?

Erledigt am 19.10.2026: Bezahlte Trainer:innen ohne Anstellung zählen als Aktive (Ehrenamt kann vergütet sein; Hauptamt = Anstellung).
