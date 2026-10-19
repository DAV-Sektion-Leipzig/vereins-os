# Rollen und Rechte: Vereins OS

Stand: 19.10.2026 · Version 0.6

Begriffe nach glossar.md. „Rolle“ wird nicht mehr verwendet; es heißt **Rechtevorlage**. Details zu AD: docs/specs/ad-administration/.

## 1. Grundsatz

- **Rechte hängen an der Person.** Für jede Person kann festgelegt werden, was sie sehen und tun darf.
- **Rechte wirken nur mit Zugang im Status „aktiv“.** Eine Person nutzt ihre Rechte über ihren Zugang (Login-Adresse @dav-leipzig.de). Personen ohne Zugang sind der Normalfall.
- **Rechte entstehen aus zwei Quellen, die sich addieren:**
  1. **Rechtevorlage:** fertiges Bündel, z. B. „Geschäftsstelle“. Eine Person kann mehrere Vorlagen haben; je Modul gilt die höchste Stufe.
  2. **Einzelrechte:** individuell an der Person (nach MVP), z. B. ein aktives Mitglied, das neu im Bereich Ausbildung mitarbeitet, darf Qualifikationen dort bearbeiten.
- **Kein Automatismus:** Ein Amt, eine Funktion oder ein Hauptamt bringt keine Rechte mit. Rechte vergibt und entzieht immer der Admin. (Kann später geändert werden; das Datenmodell soll eine spätere Ableitung nicht verhindern.)
- **Rechtevorlagen sind konfigurierbar:** Der Admin legt Vorlagen an und ändert ihre Rechte in AD; sie sind nicht fest im Code hinterlegt.
- **Rechte sind befristbar** (gültig von/bis) im Datenmodell; in der Oberfläche erst nach MVP.
- **Rechte erweitern nur**, es gibt keine Verbote.

## 2. Aufbau eines Rechts

| Teil | Bedeutung | Beispiele |
|---|---|---|
| Modul | In welchem Modul | EA, GR, FI |
| Objekt | Worauf | Person, Eigenschaftsart (z. B. Qualifikation, Nachweis), Gruppe, Abrechnung |
| Aktion | Was | lesen, bearbeiten, verwalten |
| Reichweite | Für welche Daten | alle · Bereich · Gruppe · nur eigene Daten |

**Im MVP:** Rechte nur je Modul (lesen / bearbeiten / verwalten / kein Zugriff), Reichweite immer „alle“. Objekt und Reichweite sind im Datenmodell vorgesehen und werden nach dem MVP gepflegt. Einzige Ausnahme im MVP: Kennzeichen „vertraulich“ an der Eigenschaftsart (siehe 3).

Beispiel Einzelrecht (nach MVP): EA · Qualifikation · bearbeiten · Bereich Ausbildung · gültig bis 31.12.2027.

## 3. Personenmodell (Kurzfassung)

Die Grundstruktur (Person, Eigenschaftsart, Eigenschaft) entsteht mit AD; EA erweitert sie um Oberflächen, Filter, Import und Löschlauf.

- Die **Person** ist das zentrale Objekt, Mitglied oder Nicht-Mitglied. Sonderfall **Funktionsperson** (z. B. „Geschäftsstelle“ für den Notfall-Admin): erscheint nicht in EA, keine 5-Jahres-Löschung.
- Ein **Zugang** hängt immer an genau einer Person. Login-Adresse (Zugang) und Kontaktadresse (Eigenschaft) sind getrennt.
- Eine Person hat beliebig viele **Eigenschaften**, z. B.:
  - Mitglied ja/nein
  - Amt (z. B. 1. Vorsitzender)
  - Funktion mit Bezug (z. B. Trainer:in für Gruppe X)
  - Hauptamt (Anstellung; vertraulich)
  - Qualifikation (Lizenz, z. B. Trainer C Sportklettern, oder Weiterbildung, z. B. Erste Hilfe)
  - Nachweis (z. B. Führungszeugnis-Einsicht)
  - Kontaktdaten
  - frei definierte Eigenschaftsarten, die wie Spalten in Excel ergänzt werden
- Jede **Eigenschaftsart** hat Zweck (Pflicht), Datentyp (Text, Datum, Ja/Nein, Auswahlliste), „sichtbar in“ (Module, nur Anzeige) und Kennzeichen „vertraulich“ (Lesezugriff nur mit AD-Rechten, per RLS).
- Jede Eigenschaft ist **zeitlich gültig** (von/bis) und hat eine **Historie**: frühere Werte bleiben nachvollziehbar.
- **Aufbewahrung:** Es soll 5 Jahre rückwirkend nachvollziehbar sein, wer wann wo aktiv war. Einträge, deren Gültigkeit seit mehr als 5 Jahren beendet ist, werden gelöscht. [ANNAHME: Löschung statt Anonymisierung; automatisch]
- Alle Eigenschaften, auch frei definierte, sind **in anderen Modulen auswertbar** (filtern, auswählen, Abrechnung) – vertrauliche nur mit AD-Rechten.
- Neue Eigenschaftsarten legen die **Geschäftsstelle** (in EA) und der **Admin** (in AD) an, ohne Änderung der Datenstruktur.

## 4. Rechtevorlagen im MVP

### Admin
- **Wer:** Product Owner (Toni Werner). Vertretung später: ein:e Mitarbeiter:in der Geschäftsstelle.
- **Tut:** Personen anlegen, Zugänge einladen, sperren und entsperren, Rechtevorlagen pflegen und zuweisen, Eigenschaftsarten anlegen und ändern, Eigenschaften von Personen pflegen, Protokoll einsehen.
- **Sichtbarkeit:** AD, SC und EA vollständig, inklusive vertraulicher Eigenschaften. Mit „EA verwalten“ darf der Admin in EA auch löschen und exportieren, sobald EA das anbietet (bewusst in Kauf genommen).
- **Hinweis:** Zugang zum Supabase-Dashboard zeigt technisch alle Daten; nur für den Admin.

### Notfall-Admin
- **Wer:** Zugang mit Vorlage Admin, Login-Adresse geschaeftsstelle@dav-leipzig.de, an der Funktionsperson „Geschäftsstelle“.
- **Zweck:** nur Schutz vor Aussperren. Jede Anmeldung wird protokolliert; der Admin sieht in AD einen Hinweis darauf.
- **Risiko (akzeptiert 19.10.2026):** Alle mit Zugriff auf das Postfach der Geschäftsstelle können über „Passwort vergessen“ Admin-Rechte erlangen.

### Geschäftsstelle
- **Wer:** 3 Mitarbeitende der Geschäftsstelle, alle mit denselben Rechten.
- **Tut:** Personen und ihre Eigenschaften pflegen, Eigenschaftsarten anlegen und anpassen, Aktive für Einsätze auswählen, Gruppen pflegen, Trainer:innen abrechnen, Buchungslauf erstellen, Öffentlichkeitsarbeit vorbereiten, Aufgaben nachhalten.
- **Sichtbarkeit:** alles in allen Fachmodulen, inklusive Abrechnungs- und Bankdaten; keine vertraulichen Eigenschaften, kein AD.

### Vorstand
- **Wer:** im MVP nur der 1. Vorsitzende (Toni Werner).
- **Tut / Sichtbarkeit:** grundsätzlich weniger Rechte als die Geschäftsstelle. Die Vorlage wird ohne Rechte angelegt; der Admin konfiguriert sie später in der Oberfläche (Startkonfiguration nach MVP).

### Testnutzer
- **Wer:** fiktive Testzugänge, je einer pro Vorlage (Admin, Geschäftsstelle, Vorstand). Ein Testzugang mit Einzelrechten kommt erst mit den Einzelrechten.
- **Sichtbarkeit:** nur Supabase TEST mit fiktiven Daten (siehe tech-stack.md).

## 5. Rechte-Matrix der Vorlagen (Startwerte MVP)

Stufen: **lesen** = ansehen · **bearbeiten** = anlegen und ändern · **verwalten** = zusätzlich löschen, exportieren, Abläufe auslösen (z. B. Buchungslauf) · – = kein Zugriff. Reichweite im MVP: immer „alle“.

| Vorlage | AD | SC | EA | GR | FI | OA | PM | GS | AM |
|---|---|---|---|---|---|---|---|---|---|
| Admin | verwalten | verwalten | verwalten | – | – | – | – | – | – |
| Geschäftsstelle | – | – | verwalten | verwalten | verwalten | verwalten | verwalten | verwalten | verwalten |
| Vorstand | – | – | – | – | – | – | – | – | – |

Vorstand: Startwerte ohne Rechte; je Modul höchstens so viel wie Geschäftsstelle. Das Anlegen von Eigenschaftsarten gehört zu „EA verwalten“ bzw. „AD verwalten“. Vertrauliche Eigenschaften lesen nur Vorlagen mit Rechten auf AD.

## 6. Beispiele

| Person | Vorlagen | Einzelrechte | Ergebnis |
|---|---|---|---|
| Toni Werner | Admin, Vorstand | – | AD, SC, EA verwalten; übrige Fachmodule gemäß Vorlage Vorstand |
| Funktionsperson „Geschäftsstelle“ | Admin | – | wie Admin; nur für den Notfall |
| Mitarbeiter:in Geschäftsstelle | Geschäftsstelle | – | alle Fachmodule verwalten; keine vertraulichen Eigenschaften |
| Aktives Mitglied, neu im Bereich Ausbildung (nach MVP) | – | EA · Qualifikation · bearbeiten · Bereich Ausbildung | nur Qualifikationen im Bereich Ausbildung bearbeiten |
| Trainer:in Gruppe X (nach MVP) | – | GR · Gruppe · lesen · Gruppe X | nur Gruppe X lesen; ohne dieses Einzelrecht nichts, obwohl die Funktion besteht |

## 7. Hinweise

- **Datenarchitektur:** Supabase-RLS prüft Zeilen, nicht Spalten. Deshalb wird jede Eigenschaft als eigene Zeile gespeichert (Person – Eigenschaftsart – Wert – gültig von/bis), nicht als Spalte (festgelegt in tech-stack.md).
- **Komplexität:** Entschieden 19.10.2026: im MVP nur Vorlagen je Modul mit Reichweite „alle“; Datenmodell für Einzelrechte, Objekt, Reichweite und Befristung ausgelegt.
- **Frei definierte Eigenschaftsarten und DSGVO:** Sie laden dazu ein, sensible Daten zu erfassen (Gesundheit, Religion, Notizen über Personen). Deshalb Pflichtangabe „Zweck“ je Eigenschaftsart und ein Hinweistext beim Anlegen, dass keine besonderen Kategorien (Art. 9 DSGVO) erfasst werden. Beschäftigtendaten (z. B. Hauptamt) werden als vertraulich gekennzeichnet.
- **Neue Eigenschaftsarten und Sichtbarkeit:** sofort für alle Vorlagen mit Zugriff auf das Modul sichtbar (gemäß „sichtbar in“), vertrauliche nur mit AD-Rechten. Für Einzelrechte (nach MVP) muss der Admin sie ergänzen. [ANNAHME]
- **5 Jahre Aufbewahrung:** Zweck dokumentieren (Nachweis der Tätigkeit, z. B. für Bescheinigungen), Eintrag im Verarbeitungsverzeichnis. Abrechnungsdaten können längeren gesetzlichen Fristen unterliegen (Steuer, Buchhaltung); klären im Modul FI.
- **Nachvollziehbarkeit:** Einladungen, Vergabe und Entzug von Rechtevorlagen, Sperren/Entsperren und Anmeldungen des Notfall-Admins werden protokolliert (wer, wem, was, wann); Aufbewahrung 5 Jahre.
- **Mitglied als Eigenschaft:** EA hält „Mitglied ja/nein“, verwaltet aber keine Mitgliedschaften (Beitrag, Ein-/Austritt). Damit bleibt das Nicht-Ziel „keine Mitgliederverwaltung“ gewahrt.

## 8. Offene Punkte

Den Modulen zugeordnet in offene-punkte.md: Vertretung des Admins (AD), Löschung nach 5 Jahren inkl. Zugang (EA), Aufbewahrung Abrechnungsdaten (FI), Startkonfiguration Vorstand und Rechte nach dem MVP (übergreifend).
