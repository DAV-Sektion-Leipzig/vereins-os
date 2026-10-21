---
name: Vereins OS
description: Arbeitswerkzeug der DAV Sektion Leipzig – nüchtern, gesichert, im DAV-Corporate-Design
colors:
  mittelgruen-dark: "#00652d"
  mittelgruen-medium: "#2c8732"
  mittelgruen-light: "#50ae2f"
  mittelgruen-toenung: "#e6f4e2"
  felsgrau-dark: "#363b44"
  felsgrau-medium: "#707680"
  felsgrau-flaeche: "#f4f4f5"
  felsgrau-linie: "#d6dbdf"
  felsgrau-toenung: "#e8ebed"
  weiss: "#ffffff"
  kaltblau-medium: "#2c7eb2"
  kaltblau-dark: "#00578d"
  kaltblau-toenung: "#e3ecf5"
  sandstein-dark: "#694718"
  kletterthemen-toenung: "#feefcc"
  fehlerrot: "#b42318"
typography:
  headline:
    fontFamily: "Fira Sans, system-ui, sans-serif"
    fontSize: "1.25rem"
    fontWeight: 600
    lineHeight: 1.4
  title:
    fontFamily: "Fira Sans, system-ui, sans-serif"
    fontSize: "1rem"
    fontWeight: 500
    lineHeight: 1.375
  body:
    fontFamily: "Fira Sans, system-ui, sans-serif"
    fontSize: "0.875rem"
    fontWeight: 400
    lineHeight: 1.43
  label:
    fontFamily: "Fira Sans, system-ui, sans-serif"
    fontSize: "0.875rem"
    fontWeight: 500
    lineHeight: 1
  badge:
    fontFamily: "Fira Sans, system-ui, sans-serif"
    fontSize: "0.75rem"
    fontWeight: 500
    lineHeight: 1.33
rounded:
  sm: "6px"
  md: "8px"
  lg: "10px"
  xl: "14px"
  pill: "26px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "16px"
  lg: "24px"
components:
  button-primary:
    backgroundColor: "{colors.mittelgruen-dark}"
    textColor: "{colors.weiss}"
    rounded: "{rounded.lg}"
    padding: "0 10px"
    height: "32px"
  button-primary-hover:
    backgroundColor: "{colors.mittelgruen-medium}"
    textColor: "{colors.weiss}"
  button-outline:
    backgroundColor: "{colors.weiss}"
    textColor: "{colors.felsgrau-dark}"
    rounded: "{rounded.lg}"
    height: "32px"
  button-destructive:
    backgroundColor: "#f8e9e8"
    textColor: "{colors.fehlerrot}"
    rounded: "{rounded.lg}"
    height: "32px"
  input:
    backgroundColor: "{colors.weiss}"
    textColor: "{colors.felsgrau-dark}"
    rounded: "{rounded.lg}"
    padding: "4px 10px"
    height: "32px"
  card:
    backgroundColor: "{colors.weiss}"
    textColor: "{colors.felsgrau-dark}"
    rounded: "{rounded.xl}"
    padding: "16px"
  status-kein-zugang:
    backgroundColor: "{colors.felsgrau-toenung}"
    textColor: "{colors.felsgrau-dark}"
    rounded: "{rounded.pill}"
    typography: "{typography.badge}"
    height: "20px"
  status-eingeladen:
    backgroundColor: "{colors.kaltblau-toenung}"
    textColor: "{colors.kaltblau-dark}"
    rounded: "{rounded.pill}"
    typography: "{typography.badge}"
    height: "20px"
  status-aktiv:
    backgroundColor: "{colors.mittelgruen-toenung}"
    textColor: "{colors.mittelgruen-dark}"
    rounded: "{rounded.pill}"
    typography: "{typography.badge}"
    height: "20px"
  status-gesperrt:
    backgroundColor: "{colors.kletterthemen-toenung}"
    textColor: "{colors.sandstein-dark}"
    rounded: "{rounded.pill}"
    typography: "{typography.badge}"
    height: "20px"
---

# Design System: Vereins OS

## Overview

**Creative North Star: "Die Seilschaft"**

Das Vereins OS ist ein Werkzeug für Menschen, die täglich mit vielen Personen, Zuständen und Fristen arbeiten, am Schreibtisch wie unterwegs. Wie in einer Seilschaft gilt: dicht beieinander, gut gesichert, jeder Schritt nachvollziehbar. Die Oberfläche ist kompakt und ruhig, damit Status und Handlung immer im Blick sind und nichts gesucht werden muss.

Die Marke kommt aus dem DAV-Corporate-Design (docs/marke.md), nicht aus eigener Erfindung. Felsgrau trägt die Fläche und den Text, Mittelgrün markiert das Handeln. Das helle DAV-Grün erscheint genau einmal als schmales Markenband am oberen Rand. Das Sektionslogo „light“ steht unverändert in der Kopfzeile und auf der Anmeldung. Ausdruck zeigt sich in Präzision: saubere Kontraste, eindeutige Zustände, eine durchgehende Schrift.

Das System kennt nur den hellen Modus. Shadcn/ui (Stil „radix-nova“) liefert die Bauteile; dieses Dokument legt fest, wie sie im DAV-Kleid aussehen.

**Key Characteristics:**
- Weiß als Grund, Felsgrau für Text und Linien, Mittelgrün nur für Handlung und Erfolg
- Jeder Zustand mit Text und Symbol, nie nur Farbe
- Kompakte Dichte (32 px hohe Bedienelemente), mobil ab 375 px
- Fira Sans durchgehend, selbst gehostet
- Logo unverändert, „Vereins OS“ getrennt davon

## Colors

Eine zurückhaltende Palette aus der DAV-Farbwelt: Felsgrau als Grundton, Mittelgrün als einzige Handlungsfarbe, Kaltblau und Sandstein nur für Fokus und Status. Hex-Werte der DAV-Farben sind laut Handout Annäherungen an den gedruckten CMYK-Ton. Die Tönungen (Werte, die auf „toenung“, „flaeche“ oder „linie“ enden) sind keine DAV-Werte, sondern mit Weiß aufgehellte DAV-Farben.

### Primary
- **Mittelgrün dunkel** (DAV Mittelgrün d): Hauptschaltfläche, Links, aktiver Navigationspunkt, Text im Status „aktiv“. Weiß darauf 7,2 : 1.
- **Mittelgrün mittel** (DAV Mittelgrün m): Hover der Hauptschaltfläche. Weiß darauf 4,6 : 1.
- **Mittelgrün hell** (DAV Mittelgrün l, Primärwert des Logo classic): nur das 3 px hohe Markenband oben an Kopfzeile und Anmeldung. 2,8 : 1 auf Weiß, deshalb nie Text, nie Bedienelement.
- **Grüner Hauch** (Mittelgrün hell, 14 % auf Weiß): Hintergrund von „aktiv“, Hover in Menüs und Auswahllisten, Textmarkierung.

### Secondary
- **Kaltblau mittel** (DAV Kaltblau m): Fokusring. Bewusst nicht grün, damit Fokus und Handlung unterscheidbar bleiben. 4,4 : 1.
- **Kaltblau dunkel** (DAV Kaltblau d): Text im Status „eingeladen“.

### Tertiary
- **Sandstein dunkel** (DAV Sandstein d): Text im Status „gesperrt“, auf **Klettergelb-Hauch** (Kletterthemen l, 20 % auf Weiß). 7,3 : 1.
- **Fehlerrot** (keine DAV-Farbe): Fehlermeldungen und Löschen. Die DAV-Farbwelt hat kein Rot; das dunkelste Orange erreicht nur 3,3 : 1. Funktionale Ausnahme, bestätigt vom Product Owner am 20.10.2026.

### Neutral
- **Felsgrau dunkel** (DAV Felsgrau d): gesamter Text, Überschriften, Beschriftungen. 11,3 : 1.
- **Felsgrau mittel** (DAV Felsgrau m, Farbe des Logo light): Sekundärtext und Rahmen von Eingabefeldern. 4,6 : 1 auf Weiß.
- **Weiß**: Seite, Karten, Dialoge.
- **Felsgrau-Fläche** (8 %): gedämpfte Flächen wie Tabellenkopf und Kartenfuß.
- **Felsgrau-Linie** (Felsgrau hell, 45 %): Trennlinien, Kartenrand. Nur Gliederung, trägt keine Information.
- **Felsgrau-Hauch** (Felsgrau hell, 25 %): Hintergrund von „kein Zugang“.

### Named Rules
**Die Markenband-Regel.** Das helle DAV-Grün erscheint nur als Band am oberen Rand. Wer es für Text, Symbole oder Rahmen nutzt, verletzt WCAG.

**Die Ein-Grün-Regel.** Mittelgrün dunkel bedeutet „handeln“ oder „in Ordnung“. Keine grünen Überschriften, keine grünen Flächen zur Dekoration.

**Die Weißgrund-Regel.** Felsgrau mittel als Text nur auf Weiß. Auf der Felsgrau-Fläche fällt es auf 4,2 : 1; dort Felsgrau dunkel verwenden.

**Die Text-und-Symbol-Regel.** Ein Zustand ist nie nur Farbe. Jedes Status-Kennzeichen trägt Wort und Symbol.

## Typography

**Body Font:** Fira Sans (mit system-ui, sans-serif)

**Character:** Fira Sans ist die DAV-Schrift für den Online-Bereich und eine Verwandte der Hausschrift Meta: humanistisch, gut lesbar in kleinen Größen, sachlich ohne kühl zu sein. Eine Familie für alles; die Hierarchie entsteht über Größe und Schnitt.

Eingebunden über `@fontsource/fira-sans`, nur der Latin-Schnitt (enthält ä, ö, ü, ß) in 400, 400 kursiv, 500 und 600. Kein Laden von Google- oder Adobe-Servern (DSGVO).

### Hierarchy
- **Headline** (600, 1.25rem, 1.4): Seitentitel, eine je Seite.
- **Title** (500, 1rem, 1.375): Kartentitel, Abschnittsüberschriften, Produktname in der Kopfzeile (600).
- **Body** (400, 0.875rem, 1.43): Standardtext der Oberfläche. Eingabefelder mobil 1rem, damit iOS nicht zoomt.
- **Label** (500, 0.875rem): Feldbeschriftungen, Schaltflächen.
- **Badge** (500, 0.75rem): Status-Kennzeichen.

### Named Rules
**Die Eine-Familie-Regel.** Nur Fira Sans. Fira Sans Condensed ist erlaubt, wenn eine breite Tabelle sie braucht; keine weitere Schrift, auch keine Monospace als Stilmittel.

**Die Ziffern-Regel.** Tabellen setzen Ziffern in Tabellenziffern (`tabular-nums`), damit Beträge und Daten untereinander stehen.

## Layout

Eine Spalte, maximal 64rem (1024 px) breit, mittig, 16 px Seitenrand. Kopfzeile und Inhalt nutzen dieselbe Breite. Abstände auf dem 4-px-Raster: 8 px innerhalb von Gruppen, 16 px zwischen Feldern, 24 px zwischen Abschnitten.

Mobil ab 375 px: Die Kopfzeile zeigt Logo und Modulname, der Name der angemeldeten Person rückt in eine zweite Zeile. Ohne Modul steht dort „Vereins OS“. Tabellen werden mobil zu Karten (PRODUCT.md).

## Elevation & Depth

Flach. Tiefe entsteht über Linien (Felsgrau-Linie) und die gedämpfte Fläche, nicht über Schatten. Karten haben einen 1-px-Rand und keinen Schatten. Nur schwebende Ebenen (Auswahllisten, Dialoge) tragen den weichen Schatten der shadcn-Bauteile.

### Named Rules
**Die Flach-in-Ruhe-Regel.** Was auf der Seite liegt, wirft keinen Schatten. Schatten zeigt nur an, dass etwas über der Seite schwebt.

## Shapes

Sanft gerundete Ecken: 10 px für Bedienelemente, 14 px für Karten, Pillenform für Status-Kennzeichen. Linien immer 1 px; das Markenband ist mit 3 px die einzige Ausnahme.

## Components

### Buttons
- **Shape:** sanft gerundet (10 px), 32 px hoch, auf der Anmeldung 36 px.
- **Primary:** Mittelgrün dunkel, weißer Text (500). Eine Hauptschaltfläche je Bereich.
- **Hover / Focus:** Hover wechselt auf Mittelgrün mittel. Fokus: 1-px-Rand und 3-px-Ring in Kaltblau.
- **Outline:** weiß mit Felsgrau-Linie, für „Abbrechen“ und Nebenaktionen.
- **Destructive:** Fehlerrot auf zartem Rot, für Löschen und Sperren.
- **Link:** Mittelgrün dunkel, unterstrichen beim Hover.

### Status-Kennzeichen (Zugang)
Signature-Komponente `AccessStatusBadge`: Pille, 20 px hoch, Symbol links, Begriff nach Glossar.
- **kein Zugang:** gestrichelter Kreis, Felsgrau dunkel auf Felsgrau-Hauch.
- **eingeladen:** Brief, Kaltblau dunkel auf Kaltblau-Hauch.
- **aktiv:** Kreis mit Haken, Mittelgrün dunkel auf grünem Hauch.
- **gesperrt:** Schloss, Sandstein dunkel auf Klettergelb-Hauch.

### Cards / Containers
- **Corner Style:** 14 px.
- **Background:** Weiß; Fuß in Felsgrau-Fläche.
- **Shadow Strategy:** keiner (siehe Elevation & Depth).
- **Border:** 1 px, Vordergrundfarbe mit 10 % Deckkraft.
- **Internal Padding:** 16 px, kompakt 12 px.

### Inputs / Fields
- **Style:** 1-px-Rand in Felsgrau mittel (4,6 : 1, sichtbar abgegrenzt), weißer Grund, 10 px Ecken, 32 px hoch.
- **Focus:** Rand und 3-px-Ring in Kaltblau. Einfügemarke in Mittelgrün dunkel.
- **Error / Disabled:** Fehler mit Rand in Fehlerrot und Meldung darunter; deaktiviert mit 50 % Deckkraft.

### Navigation (Kopfzeile)
- **Aufbau:** 3-px-Markenband oben, dann Sektionslogo „light“ (44 px mobil, 48 px ab 640 px), 1-px-Trennlinie, „Vereins OS“ (600) und Modulname (Felsgrau mittel). Rechts Name der Person und „Abmelden“ als Ghost-Schaltfläche.
- **Logo:** führt zur Startseite. Alternativtext „DAV Sektion Leipzig“.
- **Mobil:** Modulname statt „Vereins OS“, Name der Person in zweiter Zeile.

### Anmeldung
Markenband oben, Sektionslogo „light“ 80 px hoch über der Karte, mit 40 px Abstand (Schutzzone). Karte maximal 24rem breit.

## Do's and Don'ts

### Do:
- **Do** das Logo als Datei `src/assets/brand/DAVLogo-lg_Leipzig-1378_RGB.svg` unverändert einbinden, mit Abstand zu allem anderen.
- **Do** Text in Felsgrau dunkel setzen; Felsgrau mittel nur auf Weiß.
- **Do** jeden Zustand mit Wort und Symbol zeigen.
- **Do** neue Farben nur aus der DAV-Farbwelt (docs/marke.md) ableiten und den Kontrast nachrechnen: Text 4,5 : 1, Bedienelemente und Rahmen von Feldern 3 : 1.
- **Do** Tabellenziffern in Tabellen verwenden.

### Don't:
- **Don't** das Logo einfärben (auch nicht DAV-Grün), umranden, verzerren oder Text daran setzen.
- **Don't** Mittelgrün hell oder Felsgrau hell für Text, Symbole oder Rahmen von Bedienelementen verwenden.
- **Don't** einen Dunkelmodus anbieten; das System ist nur hell.
- **Don't** Schriften von Google- oder Adobe-Servern laden.
- **Don't** Fehlerrot als Markenfarbe oder Dekoration einsetzen.
- **Don't** Schatten auf ruhende Karten legen.
