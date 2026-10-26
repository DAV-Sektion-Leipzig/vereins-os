---
name: "anleitung-nachziehen"
description: "Anleitung für Nutzer:innen (docs/anleitung) nach Änderungen an einem Modul nachziehen: offenes Issue mit Label „anleitung“ abarbeiten, Text und Screenshots aktualisieren, Version erhöhen, Pull Request öffnen. Auch für die werktägliche Routine „Anleitung nachziehen“."
argument-hint: "Optional: Modul oder Issue-Nummer"
---

# Anleitung nachziehen

Die Anleitung unter `docs/anleitung/` beschreibt, was auf `main` umgesetzt ist (CLAUDE.md, Abschnitt „Anleitung für
Nutzer:innen“). Der Workflow `.github/workflows/anleitung-pruefen.yml` sammelt Änderungen an der Oberfläche, die ohne
Anpassung der Anleitung gemergt wurden, im offenen Issue mit dem Label `anleitung`. Dieser Skill arbeitet das Issue ab.

## 1. Gibt es etwas zu tun?

1. Offene Issues mit Label `anleitung` in `DAV-Sektion-Leipzig/vereins-os` suchen. Keins: beenden, nichts ändern,
   keine Nachricht an den Product Owner.
2. Gibt es schon einen offenen Pull Request, der das Issue schließt (`Closes #<Nummer>`)? Dann nur prüfen, ob seit
   seinem Stand neue Einträge im Issue stehen; wenn nein: beenden. Wenn ja: auf dessen Branch weiterarbeiten.
3. Alle Einträge des Issues lesen (Text und Kommentare): betroffene Module, Stand (`alt..neu`), Dateien.

## 2. Was hat sich geändert?

1. `git fetch origin main` und je Eintrag `git diff <alt>..<neu> -- src supabase/migrations` lesen.
2. Fachlich einordnen über `docs/specs/<modul>/02-stories.md` und `tasks.md` (welche Story, welche Oberfläche).
3. Entscheiden, ob die Anleitung betroffen ist: neue oder geänderte Seiten, Knöpfe, Felder, Abläufe, Rechte,
   Freischaltung eines Moduls. Reine Technik (Refactoring, Typen, Tests) betrifft sie nicht.
4. Nichts betroffen: Issue mit kurzer Begründung je Eintrag schließen und beenden.

## 3. Anleitung anpassen

Auf einem Branch `anleitung-nachziehen-<JJJJ-MM-TT>` von `origin/main` (Schritt 1.2 ausgenommen):

1. **Text:** betroffene Teile ergänzen (`02-referentinnen.md`, `03-geschaeftsstelle.md`, `04-admin.md`,
   `01-erste-schritte.md`). Stil wie dort: einfache Sprache, „du“, nummerierte Schritte, Knöpfe fett in „…“,
   Begriffe nach `docs/glossar.md`. Nur beschreiben, was umgesetzt ist; nichts Fachliches entscheiden. Widersprüche
   oder Lücken als `[OFFEN]` im Pull Request melden, nicht in die Anleitung schreiben.
2. **Tabelle „Welche Module gibt es?“** in `README.md` und die Tabellen „Was du siehst“ anpassen (z. B. „in
   Vorbereitung“ → „freigeschaltet“, wenn eine Migration `ad_modules.is_available` setzt). Den Hinweis
   *In Vorbereitung* im Abschnitt des Moduls dann entfernen.
3. **Bilder:** neue Seiten in `SHOTS` in `scripts/anleitung/screenshots.ts` eintragen (feste IDs aus dem Seed).
   Lokalen Stack starten und Bilder erzeugen, **nur die betroffenen** (Filter nach Namen), damit der Pull Request
   keine Bilder mit nur geänderten Zeitstempeln enthält:
   ```bash
   export SEED_TEST_PASSWORD="anleitung-$(date +%s)"   # frei wählbar, nur lokal
   scripts/anleitung/lokaler-stack.sh
   npm run anleitung:screenshots -- --vorbereiten ez- fi-abrechnung
   ```
   Nie gegen PROD, nie gegen TEST ohne Auftrag. Jedes neue oder geänderte Bild ansehen (Read) und prüfen, dass es
   das Richtige zeigt.
4. **Ablaufbilder:** neue oder geänderte Abläufe in `docs/anleitung/diagramme/*.mmd`, dann
   `npm run anleitung:diagramme -- <name>`.
5. **Version** in `README.md`: neues Modul oder neuer Teil = neue Hauptversion, sonst Unterversion; Zeile
   `Stand: <TT.MM.JJJJ> · Version x.y` und eine neue Zeile `Änderungen vx.y: …` darunter.
6. **PDF prüfen:** `npm run anleitung:pdf`, einige Seiten mit `pdftoppm` rendern und ansehen (Umbrüche, Bildgrößen).

## 4. Abschließen

1. Personendaten-Prüfung aus CLAUDE.md ausführen.
2. Lint der Skripte, falls geändert: `npx oxlint scripts/anleitung`.
3. Commit (deutsch), push, Pull Request mit `Closes #<Issue>`, betroffenen Stories/Tasks und Merges, Liste der
   geänderten Abschnitte und Bilder, ggf. `[OFFEN]`-Punkten. Kein Auto-Merge (fachliches Dokument); der Product
   Owner mergt. Nach dem Merge erzeugt `anleitung-pdf.yml` das PDF und das Release `anleitung-v<Version>`.
