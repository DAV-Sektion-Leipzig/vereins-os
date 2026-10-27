# Anleitung für den Admin

Für den Admin mit der Rechtevorlage „Admin“. Der Admin richtet Personen, Zugänge und Rechte ein und pflegt die Stammdaten.

[Zurück zur Übersicht](README.md) · Zuerst lesen: [Erste Schritte](01-erste-schritte.md)

## Was du siehst

| Modul | Deine Rechte |
|---|---|
| Administration | verwalten: alles |
| Ehrenamtsmanagement | verwalten: wie die Geschäftsstelle, dazu vertrauliche Angaben |
| Gruppen, Anwesenheitserfassung | lesen (zum Beispiel für einen Notfall auf einer Ausfahrt) |
| Schnittstellen | verwalten: E-Mail-Versand einrichten, Key, Vorlagen, Postausgang |

Die Seiten der Administration findest du oben in der Leiste: Personen, Rechtevorlagen, Eigenschaftsarten, Qualifikationsarten, Sätze, Abrechnungsarten, Auszahlung, Protokoll.

---

## Personen und Zugänge

### Die Personenliste

![Personenliste mit Name, Login-Adresse, Zugang, Ehrenamtsstatus und Vorlagen](bilder/ad-personen.png)

Hier siehst du **alle Personen** aus allen Modulen. Mit **Suche**, **Zugangsstatus** und **Zugehörigkeit** grenzt du die Liste ein.

Der **Zugang** hat einen von vier Zuständen:

| Zustand | Bedeutung |
|---|---|
| kein Zugang | Die Person kann sich nicht anmelden. Das ist der Normalfall. |
| eingeladen | Die Einladung ist verschickt, das Passwort noch nicht gesetzt. |
| aktiv | Die Person kann sich anmelden. |
| gesperrt | Die Person kann sich nicht mehr anmelden. |

### Einer Person einen Zugang geben

![Ablauf vom Anlegen bis zur ersten Anmeldung](diagramme/zugang.png)

**Schritt 1: Person anlegen**

![Formular „Person anlegen“ mit Vorname, Rufname, Nachname und Login-Adresse](bilder/ad-person-neu.png)

1. Klicke in **„Personen“** auf **„Person anlegen“**.
2. Trage **Vorname**, **Nachname** und die **Login-Adresse** (@dav-leipzig.de) ein.
3. Klicke auf **„Speichern“**.

Gibt es die Person schon, zum Beispiel aus dem Ehrenamtsmanagement, lege sie nicht neu an. Öffne sie in der Liste und klicke bei „Zugang“ auf **„Login-Adresse festlegen“**.

**Schritt 2: Rechtevorlage zuweisen**

![Person mit Zugang, zugewiesener Rechtevorlage und Auswahl für eine weitere Vorlage](bilder/ad-vorlage-zuweisen.png)

1. Öffne die Person.
2. Klicke unter **„Rechtevorlagen“** auf **„Vorlage hinzufügen“**.
3. Wähle die Vorlage, zum Beispiel „Referent:in“.
4. Bei Vorlagen mit Reichweite „Referat“ wählst du die **Referate**.
5. Klicke auf **„Zuweisen“**.

**Schritt 3: Einladen**

Klicke bei „Zugang“ auf **„Einladen“**. Die Person bekommt eine E-Mail. Sobald sie ihr Passwort gesetzt hat, steht der Zugang auf **aktiv**.

### Einen Zugang verwalten

![Detailseite einer Person mit Stammdaten, Zugang, Rechtevorlagen und Eigenschaften](bilder/ad-person.png)

| Was du willst | So geht es |
|---|---|
| Einladung noch einmal schicken | **„Erneut einladen“**. Der alte Link wird ungültig. |
| Login-Adresse korrigieren | **„Login-Adresse ändern“**. Geht nur, solange der Zugang noch nicht aktiv ist. |
| Person darf sich nicht mehr anmelden | **„Sperren“**. Mit **„Entsperren“** machst du das rückgängig. |
| Referate einer Vorlage ändern | bei der Vorlage **„Referate ändern“** |
| Rechte wegnehmen | bei der Vorlage **„Entziehen“** |
| Name korrigieren | **„Stammdaten bearbeiten“** |

> **Gut zu wissen:** Ein Amt bringt keine Rechte mit. Wird jemand Referent:in, musst du die Vorlage selbst zuweisen. Hört jemand auf, entziehe die Vorlage oder sperre den Zugang.

> **Schutz vor Aussperren:** Deinen eigenen Zugang kannst du nicht sperren. Den Zugang des Notfall-Admins kannst du nicht sperren und ihm die Admin-Rechte nicht entziehen. Mindestens ein aktiver Zugang muss die Administration verwalten können: Den letzten solchen Zugang kannst du nicht sperren, ihm die Vorlage nicht entziehen und in seiner Vorlage die Stufe für die Administration nicht herabsetzen.

### Eigenschaften einer Person

Unten auf der Detailseite pflegst du die **Eigenschaften** der Person, zum Beispiel Kontaktdaten oder Funktionen. Das geht genauso wie im [Ehrenamtsmanagement](02-referentinnen.md#eine-person-ansehen). Als Admin siehst du auch **vertrauliche** Eigenschaften, zum Beispiel ein Hauptamt.

### Notfall-Admin

Es gibt einen zweiten Admin-Zugang über das Postfach der Geschäftsstelle. Er ist nur dafür da, dass niemand ausgesperrt wird. Meldet sich der Notfall-Admin an, siehst du oben in der Personenliste einen gelben Hinweis. Prüfe, ob die Anmeldung in Ordnung war, und klicke auf **„Zur Kenntnis genommen“**.

---

## Rechtevorlagen

![Liste der Rechtevorlagen](bilder/ad-rechtevorlagen.png)

Eine Rechtevorlage legt fest, was jemand in jedem Modul darf. Eine Person kann mehrere Vorlagen haben. Je Modul gilt dann die höchste Stufe.

![Rechtevorlage „Referent:in“ mit Stufe, Reichweite und „darf freigeben“ je Modul](bilder/ad-rechtevorlage.png)

1. Klicke auf eine Vorlage oder auf **„Neu“**.
2. Wähle je Modul eine Stufe: **kein Zugriff**, **lesen**, **bearbeiten** oder **verwalten**.
3. **Reichweite:** „alle“ oder „Referat“. Die Referate wählst du später bei der Zuweisung an eine Person.
4. **darf freigeben:** In Finanzen heißt das, Abrechnungen als „sachlich richtig“ bestätigen. Beim Dashboard steht an dieser Stelle **„Budget pflegen“**: Finanzplan, Zuordnung und DATEV-Import pflegen und Anträge entscheiden. Das geht nur mit Reichweite „alle“.
5. Klicke auf **„Speichern“**.

Änderungen gelten sofort für alle Personen mit dieser Vorlage.

| Vorlage | Für wen |
|---|---|
| Admin | Product Owner |
| Geschäftsstelle | Mitarbeiter:innen der Geschäftsstelle |
| Referent:in | Referent:innen und Hüttenwart:innen, mit ihren Referaten |
| Vorstand | Dashboard lesen (alle Referate) |
| Budgetpflege | 1. Vorsitzende:r und Schatzmeister:in: Dashboard lesen und Budget pflegen |

![Rechtevorlage „Budgetpflege“: Dashboard lesen mit „Budget pflegen“](bilder/ad-rechtevorlage-budget.png)

Die Rechtevorlage „Referent:in“ hat im Dashboard „lesen“ mit Reichweite „Referat“: Referent:innen sehen das Budget ihrer Referate mit Einzelbuchungen und die Summen aller anderen.

---

## Eigenschaftsarten

![Liste der Eigenschaftsarten mit Kategorie, Lesestufe, Bezug, Feldern und „sichtbar in“](bilder/ad-eigenschaftsarten.png)

Eine Eigenschaftsart legt fest, **was** man zu einer Person eintragen kann. Beispiele: Funktion, Lizenz, Bankverbindung, Erste-Hilfe-Kurs.

Mit **„Neu“** legst du eine Eigenschaftsart an:

- **Zweck:** wofür die Angabe gebraucht wird (Pflicht).
- **Kategorie:** Bereich auf der Detailseite, zum Beispiel „Nachweise“.
- **Lesestufe:** Wer darf die Angabe sehen?
  - *alle mit Zugriff:* alle, die die Person sehen dürfen
  - *nur Geschäftsstelle und Admin:* zum Beispiel Bankverbindung
  - *vertraulich:* nur der Admin
- **Bezug:** optional ein Referat, Gremium oder eine Gruppe.
- **Felder:** eine oder mehrere Angaben mit Datentyp, zum Beispiel Text, Datum, Ja/Nein, Auswahlliste oder Qualifikationsart.
- **Sichtbar in:** in welchen Modulen die Angabe angezeigt wird.

Eigenschaftsarten mit dem Zeichen **System** braucht das Vereins OS selbst. Ändere sie vorsichtig.

## Qualifikationsarten

![Liste der Qualifikationsarten](bilder/ad-qualifikationsarten.png)

Hier stehen die Lizenzen und Ausbildungen des DAV mit Kürzel, Lizenzstufe und Gültigkeitsdauer. Die Spalte **„Personen“** zeigt, wie viele Personen die Qualifikation gerade haben. **„DOSB-lizenzfähig“** ist wichtig für Finanzen: Nur mit einer förderfähigen Lizenz gibt es den Trainer:innen-Satz. Gelöscht wird nichts.

---

## Einstellungen für Finanzen

### Sätze

![Sätze und Pauschalen mit Wert, gültig ab und Quelle](bilder/ad-saetze.png)

Hier stehen die Beträge aus der Vergütungsordnung, zum Beispiel der Tagessatz für Trainer:innen. Ändert sich ein Betrag, klicke auf **„Neuer Wert“** und trage den Betrag und das Datum **„gültig ab“** ein. Der alte Wert bleibt in der Historie. Finanzen rechnet immer mit dem Wert, der am Tag des Einsatzes galt.

### Abrechnungsarten

![Abrechnungsarten mit ihren Positionen und Sätzen](bilder/ad-abrechnungsarten.png)

Eine Abrechnungsart legt fest, **welcher Satz** für welche Position gilt, zum Beispiel „Trainingseinheiten: Trainer:in 6 €, Helfer:in 4 €“. Jeder Einsatzart ist eine Abrechnungsart vorbelegt.

### Auszahlung

![Einstellungen für die Auszahlung: Abgabefristen, Referate mit halbjährlicher Abrechnung, Angaben der Sektion](bilder/ad-auszahlung.png)

- **Abgabefristen** je Halbjahr.
- **Halbjährliche Abrechnung je Referat:** Für diese Referate rechnet Finanzen je Halbjahr ab.
- **Angaben der Sektion:** Name, IBAN und BIC für die Überweisungsdatei.

---

## Protokoll

![Protokoll mit Einladungen, Rechtevergaben, Sperren und Anmeldungen des Notfall-Admins](bilder/ad-protokoll.png)

Das Protokoll zeigt, wer wann jemanden eingeladen, gesperrt oder Rechte vergeben hat. Es wird 5 Jahre aufbewahrt.

---

## Schnittstellen

Über die **Schnittstellen** verschickt das Vereins OS E-Mails aus Abläufen, zum Beispiel wenn sich der Notfall-Admin anmeldet oder wenn ein API-Key bald abläuft. Die E-Mails gehen über den Dienst **Brevo** von der Adresse `noreply@vereinsos.dav-leipzig.de`. Die Einladung und „Passwort vergessen“ laufen **nicht** hierüber.

![So kommt eine E-Mail an: Ein Modul legt sie in den Postausgang, alle 5 Minuten verschickt das Vereins OS wartende E-Mails über Brevo; bei Fehlern bis zu 3 Versuche](diagramme/postausgang.png)

Oben stehen vier Reiter: **Anbindungen**, **Vorlagen**, **Postausgang**, **Protokoll**. Ist etwas gestört, siehst du oben einen roten Hinweis – auch auf der Startseite.

### Den E-Mail-Versand einrichten

![Anbindung mit Zustand, Absender, Key, Grenzen und freigegebenen Modulen](bilder/sc-anbindungen.png)

1. Im Brevo-Konto der Sektion einen **API-Key** erzeugen (für TEST und PROD je einen eigenen).
2. **„Anbindung anlegen“**: Name, Absenderadresse und Absendername sind schon vorbelegt. Ein Ablaufdatum für den Key ist freiwillig.
3. **„Key hinterlegen“**: den Key einfügen und speichern. Danach siehst du nur noch die letzten 4 Zeichen, zum Beispiel „…k3x9“.
4. **„Module freigeben“**: Häkchen bei Administration und Schnittstellen setzen. Nur freigegebene Module dürfen E-Mails verschicken.
5. **„Test-E-Mail senden“**: Die E-Mail geht an deine Login-Adresse. Schau nach, ob sie im Posteingang liegt (nicht im Junk-Ordner).
6. **„aktivieren“**: geht erst nach einer erfolgreichen Test-E-Mail.

**Zustände einer Anbindung:**

| Zustand | Bedeutung | Was tun? |
|---|---|---|
| aktiv | E-Mails gehen hinaus. | nichts |
| abgeschaltet | Du hast die Anbindung abgeschaltet. Wartende E-Mails bleiben liegen. | „aktivieren“ |
| gestört | 3 Fehler hintereinander oder ein neuer Key ohne Test. | Fehler lesen, ggf. Key wechseln, „Test-E-Mail senden“ |
| abgelaufen | Das Ablaufdatum des Keys ist erreicht. | „Key wechseln“ mit neuem Datum, dann „Test-E-Mail senden“ |

**Grenzen:** Höchstens **100 E-Mails je Stunde** und **300 je Tag** (kostenloser Tarif von Brevo). Weitere E-Mails warten bis zur nächsten Stunde bzw. bis zum nächsten Tag. TEST und PROD teilen sich das Konto; in TEST deshalb höchstens 50 am Tag.

**Key wechseln:** „Key wechseln“, neuen Key einfügen, speichern, dann „Test-E-Mail senden“. Bis der Test klappt, ist die Anbindung „gestört“. 30 und 7 Tage vor dem Ablaufdatum bekommst du eine Erinnerung per E-Mail.

**Abschalten:** zum Beispiel, wenn ein Key in falsche Hände geraten ist. Wartende E-Mails bleiben im Postausgang; nach 7 Tagen gelten sie als „zu alt“.

### Vorlagen

![Vorlage bearbeiten mit Betreff, Text, Platzhaltern und Vorschau](bilder/sc-vorlage.png)

Jeder **Anlass** hat eine eigene E-Mail. Du kannst Betreff (höchstens 150 Zeichen) und Text (höchstens 2.000 Zeichen) ändern.

- **Platzhalter** wie `{zeitpunkt}` oder `{link}` setzt das Vereins OS beim Versand ein. Klick auf einen Platzhalter fügt ihn in den Text ein.
- **Keine Namen und keine anderen Personendaten** in die E-Mail schreiben. Die Anrede ist „Hallo,“. Die E-Mail enthält nur einen kurzen Hinweis und einen Link ins Vereins OS.
- Mit **„Vorschau“** siehst du die E-Mail mit Beispielwerten.
- Der neue Text gilt für E-Mails, die nach dem Speichern verschickt werden.

### Postausgang

![Postausgang mit Filtern, Zustand und Aktionen](bilder/sc-postausgang.png)

Hier stehen alle E-Mails der letzten **90 Tage** mit Zustand: **wartet**, **versendet**, **fehlgeschlagen** oder **verworfen**.

- **„Inhalt“** zeigt Betreff und Text.
- **„erneut senden“** bei fehlgeschlagenen E-Mails, zum Beispiel nachdem du den Key gewechselt hast.
- **„verwerfen“**, wenn die E-Mail nicht mehr gesendet werden soll.

Nach 90 Tagen löscht das Vereins OS E-Mails und Protokolleinträge automatisch.

### Protokoll der Schnittstellen

![Protokoll der Schnittstellen mit Versand, Tests und Änderungen](bilder/sc-protokoll.png)

Das Protokoll zeigt jeden Versand, jeden Test und jede Änderung an Anbindungen, Freigaben und Vorlagen. Den Key und den Inhalt der E-Mails zeigt es nie.
