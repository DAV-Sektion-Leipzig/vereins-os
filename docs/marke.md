# Marke: Vereins OS

Stand: 20.10.2026 · Version 0.2

Auszug aus dem DAV-Corporate-Design für das Vereins OS. Quelle: „Der DAV-Logo Refresh“, Handout des Bundesverbands, Januar 2024 (Datei `2406-DAV-Logo-Refresh-Handout_RZ.pdf`, 38 Seiten, liegt beim Product Owner und nicht im Repo). Das DAV-Corporate-Design ist verbindlich (PRODUCT.md, bestätigt 20.10.2026). Seitenangaben beziehen sich auf das Handout.

## 1. Logo im Repo

| Datei | Logotyp | Farbmodus | Inhalt |
|---|---|---|---|
| `src/assets/brand/DAVLogo-lg_Leipzig-1378_RGB.svg` | light (`lg`) | RGB (Bildschirm) | Edelweiß, Wortmarke „DAV“, Zeilen „Sektion“ und „Leipzig“; Felsgrau `#6E767F`; ohne Hintergrund |

- Die Datei ist unverändert aus der Vorlage der Sektion übernommen. Der Dateiname folgt dem DAV-Schema `DAVLogo-<Logotyp>_<Farbmodus>.<Dateiart>` (S. 37).
- Farbwert in der Datei `#6E767F`; das Handout nennt für Felsgrau `#707680`. Alle RGB- und Hex-Werte sind laut Handout nur Annäherungen an den CMYK-Originalton (S. 7, 20). Die Datei wird nicht angepasst.

## 2. Welches Logo wofür

| Version | Aussehen | Einsatz laut Handout | Im Vereins OS |
|---|---|---|---|
| classic | grüner Kasten, weißer Rahmen, Unterzeile „Deutscher Alpenverein“ bzw. Sektionsname | erste Wahl, wenn die Sektion als Organisation auftritt: Briefpapier, Urkunden, Formulare, Ausweise (S. 8, 35) | für Dokumente, die das Vereins OS erzeugt und die nach außen gehen (z. B. Bescheinigungen), falls nötig. Datei fehlt noch. |
| light | Edelweiß und „DAV“ in Felsgrau, kastenfrei, Sektionsname darunter | zweite Wahl; Webseiten, Branding, Social Media, Video; dort, wo es technisch besser umzusetzen ist (S. 21, 35) | **Logo der Oberfläche** (Anmeldung, Kopfzeile) |
| brand / label | Edelweiß allein (brand) bzw. Edelweiß über „DAV“ (label), quadratisch oder hochkant auf Felsgrau, Grün oder Weiß | Profilbilder, Branding, Etiketten (S. 24–26, 36) | Grundlage für Favicon und App-Symbol. Dateien fehlen noch. |

Begründung für light in der Oberfläche: Bildschirm-Anwendung, kastenfrei und damit ruhiger in einem Arbeitswerkzeug; das Handout nennt Webseiten ausdrücklich als Einsatz für light.

## 3. Regeln für das Logo

**Nicht verändern** (S. 17, 22):

- keine Kontur, keinen zusätzlichen Rahmen
- Farbe und Schrift nicht ändern; das Logo light **nicht in DAV-Grün** einfärben
- Bild- und Wortmarke nicht tauschen, das Edelweiß nicht ersetzen oder verändern
- keine eigenen Textzusätze (also kein „Vereins OS“ in das Logo setzen)
- beim Logo classic: weißen Rahmen und Unterzeile nicht entfernen oder verändern

**Erlaubte Varianten des Logo light** (S. 20): positiv Felsgrau oder negativ Weiß, auch in Abstufungen (Weiß mit 75 %).

**Schutzzone:** Logo light: Höhe des Edelweiß, gemessen ab den Außenkanten des Logos. Logo classic: Buchstabenhöhe „DAV“. In Einzelfällen (z. B. Profilbilder) darf sie verringert werden (S. 17, 22).

**Themenlogos** (S. 23): Der Bundesverband hängt Angebotsnamen in Meta Normal und Versalien an die Wortmarke an (z. B. „DAV SHOP“, „DAV INTERN“). [OFFEN] Ob das Vereins OS ein solches Themenlogo bekommt, entscheidet der Bundesverband; bis dahin steht „Vereins OS“ getrennt vom Logo, außerhalb der Schutzzone.

## 4. Farben

Originalton ist immer der gedruckte CMYK-Wert; Hex-Werte sind Annäherungen (S. 15). Primärwert je Gruppe fett.

| Farbgruppe | light | medium | dark | Zuordnung |
|---|---|---|---|---|
| Mittelgrün | **`#50AE2F`** | `#2c8732` | `#00652d` | DAV-Logo classic |
| Felsgrau | `#a5aeb8` | **`#707680`** | `#363b44` | DAV-Logo light |
| Warmgrün | **`#A2C617`** | `#638d24` | `#2d5e20` | |
| Kaltgrün | **`#42B38E`** | `#008a77` | `#00675f` | |
| Kaltblau | **`#80A8D1`** | `#2c7eb2` | `#00578d` | |
| Eisblau | **`#46BFE0`** | `#0092a7` | `#006c76` | |
| Sandstein | **`#D6AD00`** | `#9c761f` | `#694718` | |
| Kaltgrau | **`#82AABD`** | `#4b7d90` | `#005264` | |
| Klettergebiete | `#96A499` | **`#c8ccc9`** | `#677266` | |
| Kletterthemen/Indoor | **`#F9B000`** | `#f18700` | `#ec6608` | |
| MTB | `#8ebda7` | `#69917f` | **`#3B594C`** | |

Hinweis für die Oberfläche (WCAG 2.2 AA, PRODUCT.md): Kontrast auf Weiß, gerechnet mit den Hex-Werten:

| Farbe | Kontrast | normaler Text (4,5 : 1) | Bedienelemente, Grafik (3 : 1) |
|---|---|---|---|
| Mittelgrün light `#50AE2F` | 2,8 : 1 | nein | nein |
| Mittelgrün medium `#2c8732` | 4,6 : 1 | ja, knapp | ja |
| Mittelgrün dark `#00652d` | 7,2 : 1 | ja | ja |
| Felsgrau light `#a5aeb8` | 2,3 : 1 | nein | nein |
| Felsgrau medium `#707680` (Logo `#6E767F`) | 4,6 : 1 | ja, knapp | ja |
| Felsgrau dark `#363b44` | 11,3 : 1 | ja | ja |

Die hellen Primärwerte taugen also nur für Flächen und Dekor, nicht für Text oder Bedienelemente auf Weiß. Welche Farben das Vereins OS wofür nutzt, legt DESIGN.md fest.

## 5. Schrift

Quellen: Handout S. 16 und ein Hinweis des Bundesverbands zu Schrift und Typografie (vom Product Owner übermittelt am 20.10.2026).

| Schrift | Einsatz laut DAV |
|---|---|
| **Meta**, Meta Condensed | Hausschrift; Druck. Fließtext Meta Normal 9 pt; Head- und Sublines auch Meta Condensed. Sektionsnamen im Logo in Meta Book (S. 28, 34). |
| **Fira Sans** | Online-Bereich |
| Tahoma | Mails, PowerPoint, Word und Ähnliches |
| Google Fonts | Druckprodukte, sofern die Lizenz den freien Einsatz erlaubt oder Rechte erworben werden |

Meta und Fira gibt es laut Hinweis bei Adobe Fonts.

**Im Vereins OS gilt Fira Sans.** Das Vereins OS ist eine Online-Anwendung. Die Meta wird nicht eingebunden; eine Webfont-Lizenz ist damit nicht nötig.

- Fira Sans steht unter der SIL Open Font License und darf frei eingebunden werden. Die Meta-Ableitung Fira Sans Condensed übernimmt bei Bedarf die Rolle der Meta Condensed.
- **Einbinden nur selbst gehostet**, mit den Schriftdateien im Build, z. B. über das npm-Paket `@fontsource/fira-sans`. Kein Laden von Google- oder Adobe-Servern: Das gibt IP-Adressen der Nutzer:innen an Dritte weiter (DSGVO) und bräuchte zusätzliche Auftragsverarbeitung.
- Typografische Regeln aus dem Handout, die übertragbar sind: Hervorhebungen in Bold, Zitate kursiv. Größen, Schnitte und Hierarchie für den Bildschirm legt DESIGN.md fest.
- E-Mails aus dem Vereins OS (Einladung, Passwort zurücksetzen): Laut Hinweis ist Tahoma die Mail-Schrift. Die Mailvorlagen in `supabase/templates/` setzen bisher keine Schrift; bei der nächsten Überarbeitung Tahoma mit Systemschriften als Rückfall verwenden.

## 6. Offene Punkte

Übernommen in docs/offene-punkte.md (Abschnitt Übergreifend):

- [OFFEN] Weitere Logodateien der Sektion: light negativ Weiß (SVG), classic (SVG), brand (Edelweiß quadratisch) für Favicon und App-Symbol. (marke.md)
- [OFFEN] Themenlogo „DAV …“ für das Vereins OS: gewünscht und mit dem Bundesverband abzustimmen? (marke.md)
