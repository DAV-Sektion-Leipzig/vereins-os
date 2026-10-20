# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

- **Geschäftsstelle (3 Mitarbeitende):** Hauptnutzer:innen, tägliche Arbeit. Sie pflegen Personen und ihre Eigenschaften, wählen Aktive für Einsätze aus, führen Gruppen, rechnen Trainer:innen ab, erstellen den Buchungslauf und halten Aufgaben nach. Sie arbeiten im Büro und mobil etwa gleich oft, z. B. bei Einsätzen, in der Kletterhalle oder bei Veranstaltungen.
- **Admin (Product Owner, 1. Vorsitzender):** richtet Zugänge, Rechtevorlagen und Eigenschaftsarten in AD ein. Ist zugleich Nutzer mit der Vorlage Vorstand.
- **Notfall-Admin:** Funktionszugang über das Postfach der Geschäftsstelle, nur zum Schutz vor dem Aussperren.
- **Nach dem MVP:** weitere Personen mit Amt; Aktive mit Einzelrechten (z. B. Trainer:in liest nur die eigene Gruppe). Im MVP sind Aktive nur Datensätze und haben keine eigene Anmeldung.

Quellen: docs/vision.md, docs/rollen.md.

## Product Purpose

Das Vereins OS ist ein modulares Arbeitsinstrument der Sektion Leipzig des Deutschen Alpenvereins. Es hält Personen, Einsätze und Gruppen zentral und automatisiert wiederkehrende Abläufe. Heute liegen diese Daten in unflexiblen, nicht verknüpften Excel-Listen.

Erfolg nach 12 Monaten:

- Die Excel-Liste der ca. 250 Aktiven ist abgelöst.
- Der monatliche Buchungslauf für Verträge dauert ca. 1 statt ca. 30 Minuten.
- Die Aufgaben der Geschäftsstelle laufen mit Erinnerungen im System.
- Der Betrieb verursacht 0 € laufende Kosten.

## Positioning

Kein System am Markt bildet die Kernbereiche der Sektion flexibel ab. Das Vereins OS ist auf genau diese Sektion zugeschnitten:

- **Flexibles Personenmodell:** Eigenschaften wie Mitglied, Amt, Funktion, Qualifikation, Nachweis und frei definierte Eigenschaftsarten sind eigene Einträge mit Gültigkeit und Historie, keine starren Spalten.
- **Einmal gepflegt, überall genutzt:** Personen und Einsätze stehen allen Modulen zur Verfügung, von der Auswahl für Einsätze bis zur Abrechnung.
- **Bewusst getrennt von der Mitgliederverwaltung:** „Mitglied ja/nein“ ist nur eine Eigenschaft.

## Operating Context

- Typische Arbeiten: Aktive für den nächsten Arbeitseinsatz auswählen, Trainer:innen abrechnen und Überweisungslisten für DATEV erstellen, Verträge im Bereich Kinder und Jugend nachhalten, Gruppen mit Gruppenleitung und Teilnehmer:innen führen, Pressemitteilungen und Instagram-Beiträge vorbereiten, Aufgaben mit Erinnerungen verwalten.
- Arbeitsorte: Schreibtisch in der Geschäftsstelle und unterwegs auf dem Smartphone, etwa gleich oft. Mobile Nutzung ist ein vollwertiger Arbeitsweg, nicht nur zum Nachschlagen.
- Datenmengen: ca. 250 Aktive; Gruppen im Kinder-, Jugend- und Erwachsenenbereich; laufend neue Einsätze (jede Trainingseinheit ist ein Einsatz).
- Anmeldung mit E-Mail und Passwort, nur mit Adressen @dav-leipzig.de. Login-Mails kommen aus dem Google-Konto der Sektion und enthalten nur einen kurzen Hinweis mit Link, keine Personendaten.
- Module nach Priorität: AD (Administration) → EA (Ehrenamtsmanagement) → GR (Gruppen) → FI (Finanzen) → OA (Öffentlichkeitsarbeit) → PM, GS, AM (Projekte, Geschäftsstelle, Aufgaben). SC (Schnittstellen-Connector) spätestens mit OA. Details in docs/modul-landkarte.md.

## Capabilities and Constraints

- **Sprache:** Oberfläche deutsch, Ansprache mit „du“. Begriffe streng nach docs/glossar.md: ein Begriff pro Sache, keine Synonyme (z. B. „Rechtevorlage“, nie „Rolle“; „Aktive:r“, nie „Ehrenamtliche:r“). Gendern mit Doppelpunkt (Trainer:in).
- **Ohne Schulung bedienbar** durch die Geschäftsstelle (bestätigt 19.10.2026).
- **Mobil ab 375 px Breite**, alle Screens. Tabellen werden mobil zu Karten (docs/setup-anleitung.md).
- **Sichtbar ist nur, wofür Rechte bestehen:** Die Startseite zeigt nur Module, für die die Person Rechte hat. Stufen je Modul: lesen, bearbeiten, verwalten (zusätzlich löschen, exportieren, Abläufe auslösen). Durchgesetzt wird das in der Datenbank, nicht nur in der Oberfläche.
- **Vertrauliche Eigenschaften** (z. B. Hauptamt) sieht nur, wer Rechte auf AD hat.
- **Datensparsam und DSGVO:** nur Daten speichern, die ein konkreter Ablauf braucht. Beim Anlegen einer Eigenschaftsart ist ein Zweck Pflicht, und ein Hinweis warnt vor besonderen Kategorien (Art. 9 DSGVO). Die Führungszeugnis-Einsicht speichert nur Daten, nie den Inhalt. Einträge werden 5 Jahre nach Ende ihrer Gültigkeit gelöscht.
- **Dublettenwarnung** beim Anlegen einer Person; das Anlegen bleibt trotzdem möglich.
- **Technik:** React, TypeScript und Vite als statische SPA; shadcn/ui mit Tailwind CSS; Supabase (Auth, Postgres mit RLS, Edge Functions); Cloudflare Workers mit Static Assets. Nur kostenfreie Pläne, keine Serverlogik bei Cloudflare. Adresse vorerst `*.workers.dev`, die Domain dav-leipzig.de ist nicht nutzbar.
- **Nicht-Ziele:** keine Finanzbuchhaltung (nur Übergabe von Daten), keine Mitgliederverwaltung, im MVP keine Anmeldung von Aktiven, keine kostenpflichtigen Dienste in den ersten 6 Monaten.
- **Offen:** siehe docs/offene-punkte.md (u. a. Rollout an weitere Personen mit Amt, Messgröße für Aufgaben, Vertrag und Buchungslauf).

## Brand Commitments

- **Name:** Vereins OS. Betreiberin ist die Sektion Leipzig des Deutschen Alpenvereins (in der Oberfläche „Sektion“, nicht „Verein“).
- **DAV-Corporate-Design ist verbindlich** (bestätigt vom Product Owner, 20.10.2026). Grundlage ist das Handout „Der DAV-Logo Refresh“ (Bundesverband, Januar 2024). Die für das Vereins OS geltenden Regeln zu Logo, Farben und Schrift stehen in docs/marke.md.
- **Logo:** Sektionslogo „light“ (Edelweiß, „DAV“, „Sektion Leipzig“ in Felsgrau), `src/assets/brand/DAVLogo-lg_Leipzig-1378_RGB.svg`. Das Logo wird nie verändert: keine Kontur, kein Einfärben in DAV-Grün, keine Textzusätze. „Vereins OS“ steht getrennt vom Logo.
- **Schrift:** Online gilt laut DAV Fira Sans (Hausschrift Meta nur für Druck). Das Vereins OS nutzt Fira Sans, selbst gehostet, nicht von Google- oder Adobe-Servern geladen. Mails in Tahoma (docs/marke.md).
- **Tonfall:** sachlich, freundlich, mit „du“. Kein generischer „KI-Look“ (docs/tech-stack.md).

## Evidence on Hand

- Fachliche Dokumentation: docs/vision.md, docs/rollen.md, docs/modul-landkarte.md, docs/glossar.md, docs/specs/ad-administration/.
- Umgesetzte Oberflächen: Ersteinrichtung und Anmelden/Abmelden (src/features/auth, src/features/start).
- Marke: Sektionslogo light als SVG (src/assets/brand/), Auswertung des DAV-Handouts in docs/marke.md. Das Handout selbst (PDF, 38 Seiten) liegt beim Product Owner, nicht im Repo.
- **Nicht vorhanden:** Logo light negativ Weiß, Logo classic, Bildmarke (Edelweiß) für Favicon und App-Symbol, Fotos, Illustrationen. public/favicon.svg ist noch das Vite-Standardsymbol. Nichts davon darf erfunden oder aus dem vorhandenen Logo nachgebaut werden.
- **Keine Echtdaten:** Beispiele und Testdaten sind nur fiktiv (supabase/seed.sql).

## Product Principles

1. **Werkzeug für den Arbeitsalltag:** Die Geschäftsstelle erledigt ihre Aufgabe schnell und ohne Schulung, am Schreibtisch wie unterwegs.
2. **Automatisieren vor manuell erfassen:** Wiederkehrende Abläufe laufen per Knopfdruck oder zeitgesteuert.
3. **Einmal pflegen, überall nutzen:** Verknüpfung statt Einzellisten; ein Begriff pro Sache.
4. **Flexibel auf der Person:** Neue Eigenschaftsarten brauchen keine Änderung der Datenstruktur, mit Gültigkeit und Historie.
5. **Datensparsam und vertrauenswürdig:** Nur nötige Daten speichern, Rechte in der Datenbank durchsetzen und Vertrauliches erkennbar schützen.

## Accessibility & Inclusion

- WCAG 2.2 AA (bestätigt vom Product Owner, 20.10.2026): Kontraste, vollständige Tastaturbedienung, Screenreader-Unterstützung.
- Bedienbar auf dem Smartphone ab 375 px mit ausreichend großen Zielflächen für die mobile Nutzung unterwegs.
- Gendergerechte Sprache mit Doppelpunkt (Trainer:in, Mitarbeiter:in).
