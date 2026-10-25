# Rollen und Rechte: Vereins OS

Stand: 25.10.2026 · Version 1.2
Änderungen v1.2: Finanzen (Steckbrief FI v0.3, Product Owner 24./25.10.2026): Referent:innen bestätigen die Abrechnungen ihres Referats vor der Freigabe durch die Geschäftsstelle (Vier-Augen-Prinzip; FI lesen mit Aktion „freigeben“ nach Q1, Reichweite „Referat“, ohne Bankdaten); Reichweite „Referat“ auch für FI; Aufbewahrung der Abrechnungsdaten 5 Jahre, Belege in der Finanzbuchhaltung. Umsetzung über die Übergabe an die Administration (specs/fi-finanzen/uebergabe-administration.md A7).
Änderungen v1.1: Planungshilfe Touren und Kurse (TK) und Freigabe Touren und Kurse (TKF) in Rechte-Matrix und Beispielen; neue Rechtevorlage „Freigabe Touren und Kurse“ (delegierbares Freigaberecht, vergeben durch den Admin); Reichweite „Referat“ auch für TK und TKF; Sichtbarkeitspfad Planungshilfe (Namen und Lizenzen); Sätze und Pauschalen als Stammdaten, Pflege nur Admin (spec.md AD v0.9).
Änderungen v1.0: Modul Einsätze heißt Anwesenheitserfassung (EZ); Admin erhält Startwert „Anwesenheitserfassung lesen“ (Entscheidung Product Owner 21.10.2026).
Änderungen v0.9: Steckbrief Einsätze (EZ v0.1): Spalte EZ in der Rechte-Matrix (Geschäftsstelle verwalten, Referent:in bearbeiten mit Reichweite „Referat“); Reichweite „Referat“ auch für EZ; Sichtbarkeitspfad Einsätze (nur Name); Vorlage Gruppenleitung mit Reichweite „Gruppe“ für EZ in Iteration 1 vorgemerkt.
Änderungen v0.8: Nachtrag Personenmodell (spec.md AD v0.7): Rechtevorlage Referent:in mit Reichweite „Referat“; Admin erhält „Gruppen lesen“; Lesestufen statt Kennzeichen „vertraulich“; gemeinsame Personen-Tabelle mit Sichtbarkeit je Zugehörigkeit (Pfade AD, EA, GR); Ehrenamtsstatus; schrittweise Vergabe von Zugängen.
Änderungen v0.7: Pflegerecht für Qualifikationsarten (Admin über AD, Geschäftsstelle über „EA verwalten“); Lesen der Qualifikationsarten für alle Nutzer mit aktivem Zugang.

Begriffe nach glossar.md. „Rolle“ wird nicht mehr verwendet; es heißt **Rechtevorlage**. Details zu AD: docs/specs/ad-administration/.

## 1. Grundsatz

- **Rechte hängen an der Person.** Für jede Person kann festgelegt werden, was sie sehen und tun darf.
- **Rechte wirken nur mit Zugang im Status „aktiv“.** Eine Person nutzt ihre Rechte über ihren Zugang (Login-Adresse @dav-leipzig.de). Personen ohne Zugang sind der Normalfall.
- **Rechte entstehen aus zwei Quellen, die sich addieren:**
  1. **Rechtevorlage:** fertiges Bündel, z. B. „Geschäftsstelle“. Eine Person kann mehrere Vorlagen haben; je Modul gilt die höchste Stufe.
  2. **Einzelrechte:** individuell an der Person (nach MVP), z. B. ein aktives Mitglied, das neu im Referat Ausbildung mitarbeitet, darf Qualifikationen dort bearbeiten.
- **Kein Automatismus:** Ein Amt (auch Referent:in oder Hüttenwart:in), eine Funktion oder ein Hauptamt bringt keine Rechte mit. Rechte vergibt und entzieht immer der Admin. (Kann später geändert werden; das Datenmodell soll eine spätere Ableitung nicht verhindern.) Das gilt auch für das Freigaberecht der Planungshilfe Touren und Kurse: Referent:innen können es delegieren, indem der Admin es auf ihren Wunsch einer anderen Person gibt (Product Owner 22.10.2026).
- **Rechtevorlagen sind konfigurierbar:** Der Admin legt Vorlagen an und ändert ihre Rechte in AD; sie sind nicht fest im Code hinterlegt.
- **Rechte sind befristbar** (gültig von/bis) im Datenmodell; in der Oberfläche erst nach MVP.
- **Rechte erweitern nur**, es gibt keine Verbote.
- **Zugänge werden schrittweise vergeben** (Entscheidung 21.10.2026): zuerst Referent:innen und Vorstand, später Gruppenleitungen, dann stellvertretende Gruppenleitungen und weitere Trainer:innen. Erziehungsberechtigte und Teilnehmer:innen erhalten keinen Zugang. Tourenleitende erhalten frühestens mit Iteration 2 der Planungshilfe einen Zugang [OFFEN: öffentliches Formular oder Zugang].

## 2. Aufbau eines Rechts

| Teil | Bedeutung | Beispiele |
|---|---|---|
| Modul | In welchem Modul | EA, GR, EZ, TK, TKF, FI |
| Objekt | Worauf | Person, Eigenschaftsart (z. B. Qualifikation, Nachweis), Gruppe, Einsatz, Planung, Abrechnung |
| Aktion | Was | lesen, bearbeiten, verwalten |
| Reichweite | Für welche Daten | alle · Referat · Gruppe · nur eigene Daten |

**Im MVP:** Rechte je Modul (lesen / bearbeiten / verwalten / kein Zugriff). Reichweite „alle“ für alle Module; im Ehrenamtsmanagement, in der Anwesenheitserfassung, in der Planungshilfe Touren und Kurse (inkl. Freigabe) und in Finanzen (neu v1.2) zusätzlich „Referat“: Die Referate legt der Admin bei der Zuweisung der Vorlage fest (eine Person kann mehrere haben). Objekt sowie Reichweiten „Gruppe“ und „nur eigene“ sind im Datenmodell vorgesehen und kommen nach dem MVP; die Reichweite „Gruppe“ zuerst für die Anwesenheitserfassung (Iteration 1 von EZ), „nur eigene“ für Tourenleitende (Iteration 2 der Planungshilfe). Ausnahmen im MVP: Lesestufe an der Eigenschaftsart (siehe 3); Qualifikationsarten dürfen mit „AD bearbeiten“ oder „EA verwalten“ gepflegt werden (siehe 4).

**Freigaberecht (neu v1.1):** Das Freigeben von Touren und Kursen ist keine eigene Aktion, sondern ein eigenes Modul ohne Seiten: **TKF „Freigabe Touren und Kurse“**, Stufe „bearbeiten“ = darf freigeben (mit Reichweite „Referat“) [ANNAHME: Umsetzung, spec.md AD v0.9]. Wer es hat, darf Planungen des Referats auch bearbeiten und Rückfragen stellen (Product Owner 22.10.2026).

Beispiel Einzelrecht (nach MVP): EA · Qualifikation · bearbeiten · Referat Ausbildung · gültig bis 31.12.2027.

## 3. Personenmodell (Kurzfassung)

Die Grundstruktur (Person, Eigenschaftsart, Eigenschaft) entsteht mit AD; EA und GR erweitern sie um Oberflächen, Filter, Import und gruppenspezifische Tabellen.

- Die **Person** ist das zentrale Objekt in **einer gemeinsamen Tabelle** für Aktive, Teilnehmer:innen, Erziehungsberechtigte und Notfallkontakte; ein Mensch existiert nur einmal. Sonderfall **Funktionsperson** (z. B. „Geschäftsstelle“ für den Notfall-Admin): erscheint nicht in EA und GR, keine 5-Jahres-Löschung.
- Eine Person hat optional einen **Rufnamen** (Anzeige „Rufname Nachname“).
- Ein **Zugang** hängt immer an genau einer Person. Login-Adresse (Zugang) und Kontaktadresse (Eigenschaft) sind getrennt.
- Der **Ehrenamtsstatus** (aktiv, ruhend, ausgeschieden) gilt für die ganze Person, wird manuell gesetzt und mit Historie gespeichert. Wer einen Ehrenamtsstatus hat, gehört zum Ehrenamtsmanagement.
- Eine Person hat beliebig viele **Eigenschaften**, z. B. Mitglied, Amt (mit Bezug auf Referat oder Gremium), Funktion (mit Bezug auf Referat oder Gruppe), Hauptamt (vertraulich), Qualifikation (mit Verweis auf eine Qualifikationsart), Nachweis, Kontaktdaten, frei definierte Eigenschaftsarten.
- Jede **Eigenschaftsart** hat Zweck (Pflicht), Kategorie (nur Anzeige), ein oder mehrere **Felder** (je Feld Datentyp: Text, Zahl, Datum, Jahr, Ja/Nein, Auswahlliste, Qualifikationsart), optional einen **Bezug** (Referat, Gremium, Gruppe), „sichtbar in“ (Module, nur Anzeige) und eine **Lesestufe**:
  - **alle mit Zugriff:** alle, die die Person in einem Modul lesen dürfen (z. B. Kontaktdaten, Qualifikation, Funktion)
  - **nur Geschäftsstelle und Admin:** nur mit „verwalten“ (Reichweite alle) im jeweiligen Modul oder mit AD-Rechten (z. B. Führungszeugnis-Einsicht, Bankverbindung, Geburtsdatum)
  - **vertraulich:** nur mit AD-Rechten (z. B. Hauptamt)
- Jede Eigenschaft ist **zeitlich gültig** (von/bis) und hat eine **Historie**: frühere Werte bleiben nachvollziehbar.
- **Sichtbarkeit je Zugehörigkeit** (Pfade, durchgesetzt per RLS):
  - **Administration:** alle Personen aller Module (Entscheidung 21.10.2026: Vollständigkeit).
  - **Ehrenamtsmanagement:** nur Personen mit Ehrenamtsstatus; Ausgeschiedene nur für Geschäftsstelle und Admin; mit Reichweite „Referat“ nur Personen mit einer gültigen Eigenschaft mit Bezug auf eines der eigenen Referate.
  - **Gruppen:** nur Personen mit Gruppenbezug (Teilnahme, Erziehungsberechtigung, Notfallkontakt, Funktion mit Bezug auf eine Gruppe).
  - **Anwesenheitserfassung (v0.9, eingearbeitet in spec.md AD v0.8):** nur Vorname, Rufname, Nachname; nur Personen auf der Anwesenheitsliste eines lesbaren Einsatzes, Personen mit Gruppenbezug zu einer Gruppe des eigenen Referats (Vorbelegung) und Aktive der eigenen Referate (Vertretung, Arbeitseinsatz). Keine Eigenschaften, keine weiteren Daten aus Gruppen.
  - **Planungshilfe Touren und Kurse (neu v1.1, spec.md AD v0.9):** nur Vorname, Rufname, Nachname von Leitenden lesbarer Planungen und Suche über alle Aktiven; dazu nur die Lizenzen (Qualifikationsart, gültig bis, förderfähig), keine Lizenznummer, keine anderen Eigenschaften. Kontakt- und Notfalldaten der Leitung erfasst die Planungshilfe je Planung selbst (nur Referat, Freigabe, Geschäftsstelle; Löschung nach der Tour).
  - Personen, die nur in Gruppen vorkommen, sind im Ehrenamtsmanagement nicht sichtbar.
- **Aufbewahrung:** Es soll 5 Jahre rückwirkend nachvollziehbar sein, wer wann wo aktiv war. Einträge, deren Gültigkeit seit mehr als 5 Jahren beendet ist, werden gelöscht. [ANNAHME: Löschung statt Anonymisierung; automatisch] Eine Person wird erst gelöscht, wenn kein Modul sie mehr braucht (nach MVP).
- Neue Eigenschaftsarten legen die **Geschäftsstelle** (in EA) und der **Admin** (in AD) an, ohne Änderung der Datenstruktur.
- **Qualifikationsarten, Referate und Gremien** sind Stammdaten ohne Personendaten: lesen dürfen alle Nutzer mit aktivem Zugang [ANNAHME]; pflegen dürfen Admin (in AD) und Geschäftsstelle (in EA); gelöscht wird nie. **Sätze und Pauschalen** (neu v1.1) pflegt vorerst nur der Admin (Product Owner 22.10.2026); lesen dürfen Nutzer mit Rechten auf AD, die Planungshilfe oder Finanzen.

## 4. Rechtevorlagen im MVP

### Admin
- **Wer:** Product Owner (Toni Werner). Vertretung später: ein:e Mitarbeiter:in der Geschäftsstelle.
- **Tut:** Personen anlegen, Zugänge einladen, sperren und entsperren, Rechtevorlagen pflegen und zuweisen (inkl. Referate und Freigaberecht der Planungshilfe), Eigenschaftsarten anlegen und ändern, Eigenschaften von Personen pflegen, Qualifikationsarten pflegen, Orte pflegen, Sätze und Pauschalen pflegen (neu v1.1), Protokoll einsehen.
- **Sichtbarkeit:** alle Personen aller Module mit allen Eigenschaften (auch Kinder und Erziehungsberechtigte aus Gruppen); AD, SC und EA vollständig, inklusive vertraulicher Eigenschaften und ausgeschiedener Personen; **Gruppen lesen** (v0.8, Risikomanagement z. B. bei einem Notfall auf einer Ausfahrt), dort Lesestufe „alle mit Zugriff“, ohne Gesundheitsangaben. **Anwesenheitserfassung lesen** (v1.0). **Planungshilfe lesen** (neu v1.1), ohne Kontakt- und Notfalldaten der Leitung [ANNAHME]. Mit „EA verwalten“ darf der Admin in EA auch löschen und exportieren, sobald EA das anbietet (bewusst in Kauf genommen).
- **Hinweis:** Zugang zum Supabase-Dashboard zeigt technisch alle Daten; nur für den Admin.

### Notfall-Admin
- **Wer:** Zugang mit Vorlage Admin, Login-Adresse geschaeftsstelle@dav-leipzig.de, an der Funktionsperson „Geschäftsstelle“.
- **Zweck:** nur Schutz vor Aussperren. Jede Anmeldung wird protokolliert; der Admin sieht in AD einen Hinweis darauf.
- **Risiko (akzeptiert 19.10.2026):** Alle mit Zugriff auf das Postfach der Geschäftsstelle können über „Passwort vergessen“ Admin-Rechte erlangen.

### Geschäftsstelle
- **Wer:** 3 Mitarbeitende der Geschäftsstelle, alle mit denselben Rechten.
- **Tut:** Personen und ihre Eigenschaften pflegen, Ehrenamtsstatus setzen, Eigenschaftsarten anlegen und anpassen, Qualifikationsarten, Referate und Gremien pflegen (über „EA verwalten“), Gremium-Zugehörigkeiten pflegen, Einsätze anlegen und Anwesenheit erfassen und korrigieren, Gruppen pflegen, Planungen von Touren und Kursen anlegen, bearbeiten, Rückfragen stellen, als „in Yolawo angelegt“, „abgesagt“ und „abgeschlossen“ markieren (nicht freigeben, [ANNAHME]), Kostenauswertung exportieren, Trainer:innen abrechnen, Buchungslauf erstellen, Öffentlichkeitsarbeit vorbereiten, Aufgaben nachhalten.
- **Sichtbarkeit:** alles in allen Fachmodulen inklusive Lesestufe „nur Geschäftsstelle und Admin“, ausgeschiedener Personen, Abrechnungs- und Bankdaten, Kontakt- und Notfalldaten der Tourenleitung; keine vertraulichen Eigenschaften, kein AD (Sätze nur über die Planungshilfe lesen).

### Referent:in (v0.8)
- **Wer:** Referent:innen der 7 Referate und Hüttenwart:innen (Karl-Stein-Hütte, Sulzenauhütte); im MVP ca. 8–10 Personen [ANNAHME]; alle mit Adresse @dav-leipzig.de.
- **Tut:** im Ehrenamtsmanagement für Personen ihres Referats bzw. ihrer Referate: Personen anlegen (immer mit Zuordnung zu einem eigenen Referat), Eigenschaften pflegen (insbesondere Qualifikationen und Ablaufdaten), Ehrenamtsstatus setzen (aktiv, ruhend, ausgeschieden; gilt für die ganze Person), Ausgeschiedene über die Dublettenwarnung wieder aktivieren. In der Anwesenheitserfassung für ihr Referat: Einsätze anlegen (z. B. Arbeitseinsatz, Europacup), Anwesenheit erfassen, neue Personen beim Arbeitseinsatz als Aktive anlegen. In der Planungshilfe (neu v1.1, wirksam für die Referate Touren und Ausbildung): Planungen ihres Referats anlegen, bearbeiten, einreichen, als „in Yolawo angelegt“ markieren, absagen; freigeben nur mit der zusätzlichen Vorlage „Freigabe Touren und Kurse“. In Finanzen (neu v1.2, wirksam für die Referate Kinder und Jugend und Leistungssport): Abrechnungen ihres Referats ansehen (nur Positionen des eigenen Referats), Ausnahmen (Lizenz) begründen und als sachlich richtig bestätigen; keine Bankverbindung, keine Überweisungsdatei.
- **Sichtbarkeit:** nur Personen mit Status „aktiv“ oder „ruhend“ und gültiger Eigenschaft mit Bezug auf eines ihrer Referate; dort alle Eigenschaften mit Lesestufe „alle mit Zugriff“, auch aus anderen Referaten (nur lesen). Keine Ausgeschiedenen, keine Personen ohne Referat, keine Gremium-Sichten, keine Lesestufe „nur Geschäftsstelle und Admin“, kein AD. In der Anwesenheitserfassung: Einsätze ihres Referats bzw. der Gruppen ihres Referats; Teilnehmer:innen nur mit Namen. In der Planungshilfe: Planungen ihres Referats inkl. Kontakt- und Notfalldaten der Leitung.
- **Rechte:** EA bearbeiten mit Reichweite „Referat“; EZ bearbeiten mit Reichweite „Referat“; TK bearbeiten mit Reichweite „Referat“ (neu v1.1); FI lesen mit Aktion „freigeben“, Reichweite „Referat“ (neu v1.2) [ANNAHME: Umsetzung der Aktion nach Q1]; Referate legt der Admin bei der Zuweisung fest.

### Freigabe Touren und Kurse (neu v1.1)
- **Wer:** Startwert: Referent:innen der Referate Touren und Ausbildung [ANNAHME]; zusätzlich Personen, an die eine Referent:in die Freigabe delegiert (der Admin vergibt die Vorlage auf ihren Wunsch).
- **Tut:** in der Planungshilfe Planungen des zugewiesenen Referats freigeben, bearbeiten (auch nach der Freigabe), Rückfragen stellen, als „in Yolawo angelegt“ markieren, absagen (Product Owner 22.10.2026).
- **Sichtbarkeit:** Planungen des zugewiesenen Referats inkl. Kontakt- und Notfalldaten der Leitung; Namen und Lizenzen der Leitenden. Keine Rechte in anderen Modulen.
- **Rechte:** TKF bearbeiten mit Reichweite „Referat“.

### Vorstand
- **Wer:** im MVP nur der 1. Vorsitzende (Toni Werner).
- **Tut / Sichtbarkeit:** grundsätzlich weniger Rechte als die Geschäftsstelle. Die Vorlage wird ohne Rechte angelegt; der Admin konfiguriert sie später in der Oberfläche (Startkonfiguration nach MVP). Ziel für die Anwesenheitserfassung: lesen, Reichweite alle (Steckbrief EZ); Ziel für die Planungshilfe: lesen [ANNAHME].

### Testnutzer
- **Wer:** fiktive Testzugänge, je einer pro Vorlage (Admin, Geschäftsstelle, Vorstand, Referent:in mit Referat Klettern); neu v1.1: Referent:in Touren mit Freigabe (Tina Touren), Referent:in Ausbildung ohne Freigabe (Alex Ausbildung), nur Freigabe Touren (Fritz Freigabe). Ein Testzugang mit Einzelrechten kommt erst mit den Einzelrechten.
- **Sichtbarkeit:** nur Supabase TEST mit fiktiven Daten (siehe tech-stack.md).

### Gruppenleitung (Iteration 1 von EZ, vorgemerkt)
- **Wer:** Gruppenleitungen, später Trainer:innen [ANNAHME: gleiche Vorlage]; Zugänge nach der Reihenfolge in Abschnitt 1.
- **Tut:** in der Anwesenheitserfassung für die eigenen Gruppen Einsätze anlegen und Anwesenheit erfassen (löst das Microsoft-Forms-Formular ab).
- **Rechte:** EZ bearbeiten mit Reichweite „Gruppe“; Gruppen legt der Admin bei der Zuweisung fest [ANNAHME].

## 5. Rechte-Matrix der Vorlagen (Startwerte MVP)

Stufen: **lesen** = ansehen · **bearbeiten** = anlegen und ändern · **verwalten** = zusätzlich löschen, exportieren, Abläufe auslösen (z. B. Buchungslauf), Lesestufe „nur Geschäftsstelle und Admin“ · – = kein Zugriff. Reichweite „alle“, außer wo genannt. EZ = Anwesenheitserfassung, TK = Planungshilfe Touren und Kurse, TKF = Freigabe Touren und Kurse (bearbeiten = freigeben). **freigeben** (neu v1.2) = eigene Aktion nach Q1 (Product Owner 24.10.2026), in Finanzen: Abrechnungen bestätigen.

| Vorlage | AD | SC | EA | GR | EZ | TK | TKF | FI | OA | PM | GS | AM |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Admin | verwalten | verwalten | verwalten | lesen | lesen | lesen | – | – | – | – | – | – |
| Geschäftsstelle | – | – | verwalten | verwalten | verwalten | verwalten | – | verwalten | verwalten | verwalten | verwalten | verwalten |
| Referent:in | – | – | bearbeiten (Reichweite Referat) | – | bearbeiten (Reichweite Referat) | bearbeiten (Reichweite Referat) | – | lesen + freigeben (Reichweite Referat) | – | – | – | – |
| Freigabe Touren und Kurse | – | – | – | – | – | – | bearbeiten (Reichweite Referat) | – | – | – | – | – |
| Vorstand | – | – | – | – | – | – | – | – | – | – | – | – |

Vorstand: Startwerte ohne Rechte; je Modul höchstens so viel wie Geschäftsstelle. Das Anlegen von Eigenschaftsarten gehört zu „EA verwalten“ bzw. „AD verwalten“. Das Pflegen von Qualifikationsarten gehört zu „EA verwalten“ bzw. „AD bearbeiten“. Das Pflegen von Sätzen und Pauschalen gehört zu „AD bearbeiten“ (nur Admin). Vertrauliche Eigenschaften lesen nur Vorlagen mit Rechten auf AD.

## 6. Beispiele

| Person | Vorlagen | Einzelrechte | Ergebnis |
|---|---|---|---|
| Toni Werner | Admin, Vorstand | – | AD, SC, EA verwalten; Gruppen, Anwesenheitserfassung und Planungshilfe lesen; Qualifikationsarten, Orte, Sätze pflegen; übrige Fachmodule gemäß Vorlage Vorstand |
| Funktionsperson „Geschäftsstelle“ | Admin | – | wie Admin; nur für den Notfall |
| Mitarbeiter:in Geschäftsstelle | Geschäftsstelle | – | alle Fachmodule verwalten; Qualifikationsarten pflegen; Planungen bearbeiten, nicht freigeben; keine vertraulichen Eigenschaften, kein AD |
| Referentin Kinder und Jugend | Referent:in (Referat Kinder und Jugend) | – | Aktive des Referats lesen und pflegen, Status setzen; kein Geburtsdatum, keine Bankverbindung; Einsätze der Jugendgruppen anlegen und Anwesenheit erfassen (Kinder nur mit Namen) |
| Referent Leistungssport | Referent:in (Referat Leistungssport) | – | Einsätze der Leistungssportgruppen lesen und erfassen; keine Einsätze anderer Referate |
| Hüttenwart Karl-Stein-Hütte | Referent:in (Referat Karl-Stein-Hütte) | – | wie Referent:in, nur Referat Karl-Stein-Hütte (z. B. Arbeitseinsätze an der Hütte) |
| Referent Touren (neu v1.1) | Referent:in (Referat Touren), Freigabe Touren und Kurse (Referat Touren) | – | Aktive des Referats Touren pflegen; Touren planen, einreichen, freigeben, in Yolawo anlegen, absagen |
| Referentin Ausbildung (neu v1.1) | Referent:in (Referat Ausbildung), Freigabe Touren und Kurse (Referat Ausbildung) | – | Kurse planen und freigeben; keine Touren des Referats Touren |
| Erfahrene Tourenleiterin mit delegierter Freigabe (neu v1.1) | Freigabe Touren und Kurse (Referat Touren) | – | Touren des Referats Touren prüfen, bearbeiten, Rückfragen stellen, freigeben; kein Ehrenamtsmanagement, keine Anwesenheitserfassung |
| Referent Klettern, zugleich Gruppenleitung Jugend (nach MVP) | Referent:in (Klettern) | GR · Gruppe · lesen · Gruppe X | Aktive Klettern pflegen; Gruppe X lesen |
| Aktives Mitglied, neu im Referat Ausbildung (nach MVP) | – | EA · Qualifikation · bearbeiten · Referat Ausbildung | nur Qualifikationen im Referat Ausbildung bearbeiten |
| Trainer:in Gruppe X (nach MVP) | – | GR · Gruppe · lesen · Gruppe X | nur Gruppe X lesen; ohne dieses Einzelrecht nichts, obwohl die Funktion besteht |
| Gruppenleitung Gruppe X (Iteration 1 EZ) | Gruppenleitung (Gruppe X) | – | Trainings der Gruppe X anlegen und Anwesenheit erfassen |

## 7. Hinweise

- **Datenarchitektur:** Supabase-RLS prüft Zeilen, nicht Spalten. Deshalb wird jede Eigenschaft als eigene Zeile gespeichert (Person – Eigenschaftsart – Werte der Felder – gültig von/bis), nicht als Spalte (festgelegt in tech-stack.md). Die Lesestufe hängt an der Eigenschaftsart, damit RLS je Zeile entscheiden kann. Kontakt- und Notfalldaten der Planungshilfe liegen aus demselben Grund in einer eigenen Tabelle.
- **Komplexität:** Entschieden 19.10.2026: im MVP nur Vorlagen je Modul; erweitert 21.10.2026 um Reichweite „Referat“ für EA (und EZ), 22.10.2026 für TK und TKF. Datenmodell für Einzelrechte, Objekt, weitere Reichweiten und Befristung ausgelegt. Die Sichtbarkeit je Pfad macht die RLS-Regeln deutlich komplexer; sie wird mit einer Sichtbarkeitsmatrix getestet (spec.md AD Abschnitt 9).
- **Status für die ganze Person:** Eine Referentin kann eine Person, die auch in anderen Referaten tätig ist, für alle auf „ruhend“ oder „ausgeschieden“ setzen (bewusst entschieden, 21.10.2026). Gegenmaßnahme: Hinweis auf die anderen Referate mit Bestätigung, Historie mit „wer, wann“.
- **Frei definierte Eigenschaftsarten und DSGVO:** Sie laden dazu ein, sensible Daten zu erfassen (Gesundheit, Religion, Notizen über Personen). Deshalb Pflichtangabe „Zweck“ je Eigenschaftsart, Lesestufe und ein Hinweistext beim Anlegen, dass keine besonderen Kategorien (Art. 9 DSGVO) erfasst werden. Beschäftigtendaten (z. B. Hauptamt) werden als vertraulich gekennzeichnet. Gesundheitsangaben von Teilnehmer:innen liegen nicht in Eigenschaften, sondern in einer eigenen Tabelle des Moduls Gruppen.
- **Kinder in der Anwesenheitserfassung (v0.9):** Referent:innen sehen über Anwesenheitslisten Namen von Teilnehmer:innen (Minderjährige), ohne Rechte auf Gruppen. Nur Name, nie Geburtsdatum, Kontaktdaten oder Gesundheitsangaben; Eintrag im Verarbeitungsverzeichnis. Freitext Probetraining nur Vorname.
- **Notfallkontakte in der Planungshilfe (neu v1.1):** Daten Dritter; nur für das zuständige Referat, Personen mit Freigaberecht und die Geschäftsstelle; automatische Löschung nach der Tour [OFFEN: Frist, Vorschlag 14 Tage]; Eintrag im Verarbeitungsverzeichnis.
- **Neue Eigenschaftsarten und Sichtbarkeit:** sofort für alle mit Zugriff auf die Person sichtbar, soweit die Lesestufe es erlaubt; „sichtbar in“ steuert nur die Anzeige. Für Einzelrechte (nach MVP) muss der Admin sie ergänzen. [ANNAHME]
- **Dublettenwarnung:** sucht in allen Personen, zeigt aber nur Vorname, Nachname, Rufname, Geburtsjahr und „ausgeschieden seit“; keine Daten aus fremden Modulen.
- **Qualifikationsarten:** Die Zahl „Verwendet bei n Personen“ zählt auch vertrauliche Eigenschaften mit, zeigt aber keine Namen.
- **5 Jahre Aufbewahrung:** Zweck dokumentieren (Nachweis der Tätigkeit, z. B. für Bescheinigungen), Eintrag im Verarbeitungsverzeichnis. Gilt auch für Abrechnungsdaten und Einsätze als Abrechnungsgrundlage (Product Owner 24./25.10.2026, Q4): Die steuerlich aufbewahrungspflichtigen Belege liegen mit den gesetzlichen Fristen in der Finanzbuchhaltung, nicht im Vereins OS.
- **Nachvollziehbarkeit:** Einladungen, Vergabe und Entzug von Rechtevorlagen (auch „Freigabe Touren und Kurse“), Änderung der Referate einer Zuweisung, Sperren/Entsperren und Anmeldungen des Notfall-Admins werden protokolliert (wer, wem, was, wann); Aufbewahrung 5 Jahre. Der Ehrenamtsstatus hat eine eigene Historie; Statuswechsel von Planungen stehen im Verlauf der Planung.
- **Mitglied als Eigenschaft:** EA hält „Mitglied ja/nein“, verwaltet aber keine Mitgliedschaften (Beitrag, Ein-/Austritt). Damit bleibt das Nicht-Ziel „keine Mitgliederverwaltung“ gewahrt.

## 8. Offene Punkte

Den Modulen zugeordnet in offene-punkte.md: Vertretung des Admins (AD), Freigabe der Annahmen des Nachtrags Personenmodell (AD), Löschung nach 5 Jahren über alle Module inkl. Zugang, Startkonfiguration Vorstand, Vorlage für Gruppenleitungen mit Reichweite „Gruppe“ und Rechte nach dem MVP (übergreifend), Annahmen Nachtrag v0.9 (AD: Freigaberecht über TKF, Startwerte TK, förderfähig = DOSB-lizenzfähig), Pflege der Sätze durch Geschäftsstelle oder Referent:innen (später), Zugang für Tourenleitende (Iteration 2 der Planungshilfe).
