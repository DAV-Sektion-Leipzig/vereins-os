# CLAUDE.md

Arbeitsanweisungen für Claude Code im Vereins OS. Grundlage: [docs/tech-stack.md](docs/tech-stack.md), Abschnitte 6 (Konventionen) und 7 (Repo-Struktur).

Antworte immer auf Deutsch.

## Fachliche Quelle

- `docs/specs/<modul>/` ist die fachliche Quelle: `00-steckbrief.md`, `01-erhebung.md`, `02-stories.md`, `spec.md`. Umgesetzt wird, was dort steht.
- Spec Kit liest die `spec.md` eines Moduls und erzeugt daraus `plan.md` und `tasks.md`. Eine eigene Spec-Kit-`spec.md` wird nicht separat gepflegt.
- Begriffe nach [docs/glossar.md](docs/glossar.md): ein Begriff pro Sache, keine Synonyme. Im Code (Datenbank) englisch, in der Oberfläche deutsch.

## Fachliche Dokumente (Quelle: Git)

- **Quelle der Wahrheit ist `main` in diesem Repository** (seit 22.10.2026). Die fachlichen
  Dokumente liegen unter `docs/` und in `PRODUCT.md`. Es gibt keine zweite Kopie, die
  abgeglichen wird.
- Der frühere OneDrive-Ordner `~/Library/CloudStorage/OneDrive-DeutscherAlpenvereine.V/Claude/VereinsOS`
  ist eingefroren: nicht mehr lesen, nicht abgleichen, nichts daraus übernehmen.
- Zu Beginn jeder Aufgabe `main` aktualisieren (`git pull`) und von dort einen Branch anlegen.
- **Fachliche Dateien** (`00-steckbrief.md`, `01-erhebung.md`, `02-stories.md`, `spec.md`,
  Übergaben, `glossar.md`, `rollen.md`, `offene-punkte.md` usw.) ändert Claude Code nur auf
  ausdrücklichen Auftrag des Product Owners, auf einem Branch `docs/<thema>` mit eigenem
  Pull Request. Findet Claude Code bei der Umsetzung einen Widerspruch oder eine Lücke:
  anhalten und beschreiben (Datei, Abschnitt, Vorschlag), nicht selbst entscheiden.
- **Umsetzungsdateien** (`plan.md`, `research.md`, `data-model.md`, `quickstart.md`,
  `tasks.md`, `contracts/`, `abnahme-test.md`) pflegt Claude Code selbst.
- Arbeiten Anforderungs-Chats oder Claude Cowork an Dateien mit, dann in einem eigenen
  Checkout des Repositorys (nicht im Arbeitsordner von Claude Code) und auf einem eigenen
  Branch `docs/<thema>`; der Product Owner mergt den Pull Request.
- Dateien werden per `git mv` umbenannt und per `git rm` gelöscht, damit es im Diff sichtbar ist.

- Personendaten-Prüfung vor jedem Commit von `docs/` (öffentliches Repository):
  ```bash
  grep -rEn "DE[0-9]{20}" docs PRODUCT.md
  grep -rEhoi "[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}" docs PRODUCT.md | sort -u
  ```
  Bei einer IBAN oder einer E-Mail-Adresse außerhalb von @dav-leipzig.de, example.test
  und example.org (reservierte Beispieldomains): anhalten und fragen. Ausnahme: die
  allgemein bekannte Beispiel-IBAN `DE89370400440532013000` für fiktive Testdaten.

## Anleitung für Nutzer:innen

- Die Anleitung liegt unter `docs/anleitung/` (einfache Sprache, je Nutzergruppe ein Teil, Screenshots und
  Ablaufbilder). Claude Code pflegt sie selbst (Auftrag des Product Owners 26.10.2026); sie beschreibt nur, was
  umgesetzt ist, und entscheidet nichts Fachliches.
- **Mit jedem neuen Modul oder jeder neuen Oberfläche** die Anleitung im selben Pull Request ergänzen: Abschnitt in den
  betroffenen Teilen, Bilder in `scripts/anleitung/screenshots.ts` eintragen und mit `npm run anleitung:screenshots`
  gegen den lokalen Stack erzeugen (nie gegen PROD), Ablaufbilder in `docs/anleitung/diagramme/*.mmd` mit
  `npm run anleitung:diagramme`, Tabelle „Welche Module gibt es?“ und Version in `docs/anleitung/README.md` anpassen.
- Version: neues Modul oder neuer Teil = neue Hauptversion, sonst Unterversion; je Version eine Zeile „Änderungen“.
  Auf `main` erzeugt der Workflow `anleitung-pdf.yml` das PDF und bei neuer Version ein Release `anleitung-v<Version>`.

## Offene Punkte

- Offene Punkte nicht selbst entscheiden. Fehlt eine fachliche Entscheidung oder widersprechen sich Dokumente: als `[OFFEN]` kennzeichnen und melden, mit Quelle (Datei), wie in [docs/offene-punkte.md](docs/offene-punkte.md).

## Konventionen

### Datenbank

- Namen englisch, snake_case (`ea_persons`, `ea_property_types`, `valid_from`).
- Tabellen mit Präfix nach Modulkürzel in Kleinbuchstaben (z. B. `ad_api_keys`, `ea_persons`, `ea_assignments`, `gr_groups`). Alle Tabellen im Schema `public`, kein eigenes Schema je Modul.
- **RLS auf jeder Tabelle**, ohne Ausnahme. Keine Tabelle ohne Policy.
- **GRANTs nur an `authenticated`**, nie an `anon`: Jede Migration, die eine Tabelle, View oder Funktion anlegt, vergibt Rechte ausdrücklich per `grant … to authenticated`.
- **Rechteprüfung in der Datenbank** (RLS über Rechte-Tabellen), nie nur im Frontend. Das Frontend nutzt den öffentlichen Publishable Key; Schutz ausschließlich über RLS.
- **Schemaänderungen nur per Migration** in `supabase/migrations/`, nie direkt im Dashboard.
- **Personenmodell:** Eigenschaften als eigene Zeilen (Person – Eigenschaftsart – Wert – gültig von/bis), nicht als Spalten (siehe [docs/rollen.md](docs/rollen.md)).
- **Historie und Löschung:** Einträge mit `valid_from`/`valid_to`; automatische Löschung 5 Jahre nach Ende der Gültigkeit.

### Oberfläche

- UI-Texte deutsch, Begriffe nach glossar.md.
- Ansprache der Nutzer:innen mit „du“.

### Daten und Secrets

- **Keine Echtdaten**, weder in Tests noch im Projekt TEST. Testdaten nur fiktiv über `supabase/seed.sh` (Daten in `supabase/seed.sql`, Abbruch bei PROD), inkl. Testzugängen je Rechtevorlage.
- **Keine Secrets im Repo.** Keys nur in Supabase Vault bzw. GitHub-Secrets.
- **Lokale Werte stehen in `.env.local`** (nicht versioniert); Vorlage ist `.env.example`. `.env.local` nie lesen, anzeigen oder ändern.
- **Supabase-Key im Frontend** ist ausschließlich der Publishable Key (`sb_publishable_…`), Variable `VITE_SUPABASE_ANON_KEY`.
- **Secret Key / `service_role`** nie im Frontend, nie in `.env`-Dateien, nie im Repo.

### Umgebungen

- **Nie gegen PROD arbeiten.** Lokale Entwicklung und Vorschau-Deployments nutzen ausschließlich Supabase TEST (`vereins-os-test`).
- Keine Migrationen, Seeds, Abfragen oder CLI-Befehle gegen `vereins-os-prod`. PROD wird nur über das Deployment von `main` angesprochen.
- **Kein `supabase config push` und kein `supabase config diff`**, weder gegen TEST noch gegen PROD. `supabase/config.toml` gilt nur für den lokalen Stack (CI); Auth-Einstellungen in TEST und PROD stellt der Product Owner manuell im Dashboard ein (Checkliste in `supabase/setup/README.md`).

## Git-Workflow

- **Nie auf `main` committen oder pushen.** `main` ist geschützt; Änderungen nur per Pull Request.
- **Je Story bzw. Aufgabe ein Branch** (z. B. `us-ad-01-ersteinrichtung`), wie in
  tech-stack.md Abschnitt 3 und der Constitution. Bedingen sich Stories gegenseitig
  (z. B. gemeinsame Migrationen), kommt der zusammenhängende Teil auf einen gemeinsamen
  Branch (z. B. `ad-kern-datenbank`); der Pull Request nennt die enthaltenen Stories und Tasks.
- **Commit-Nachrichten deutsch.**
- **Pull Requests legt Claude Code selbst an** (`gh pr create`, GitHub CLI unter `~/.local/bin/gh`).
  Der PR nennt Stories, Tasks und die vollständige Cloudflare-Vorschau-URL.
- **Mergen** (Entscheidung Product Owner 23.10.2026):
  - **Auto-Merge** (`gh pr merge --auto --merge`) nur, wenn der PR ausschließlich Migrationen,
    pgTAP-Tests, Seed oder Umsetzungsdateien (`plan.md`, `research.md`, `data-model.md`,
    `quickstart.md`, `tasks.md`, `contracts/`, `abnahme-test.md`) ändert. GitHub mergt, sobald
    die Pflicht-Checks `db-tests` und `Workers Builds: vereins-os` grün sind.
  - **Kein Auto-Merge**, sobald der PR die Oberfläche (`src/`), Edge Functions, fachliche
    Dokumente (`docs/` außer Umsetzungsdateien, `PRODUCT.md`), `CLAUDE.md`, die Constitution
    oder `.github/` ändert. Dann mergt der Product Owner nach Prüfung der Vorschau.
  - Ist ein Check rot, nicht erneut anstoßen, sondern Ursache melden.

## Repo-Struktur

```
/
├── CLAUDE.md                       Arbeitsanweisungen für Claude Code
├── PRODUCT.md                      Impeccable (Produktkontext)
├── DESIGN.md                       Impeccable (Designsystem)
├── .impeccable/                    Impeccable-Einstellungen
├── .specify/                       Spec Kit (constitution, Vorlagen, Skripte)
├── docs/
│   ├── vision.md
│   ├── modul-landkarte.md
│   ├── rollen.md
│   ├── glossar.md
│   ├── tech-stack.md
│   ├── vorlagen.md
│   ├── marke.md                    DAV-Corporate-Design (Auszug)
│   ├── diagrams/                   Excalidraw-Dateien
│   ├── anleitung/                  Anleitung für Nutzer:innen (Bilder, Ablaufbilder, PDF über Workflow)
│   └── specs/
│       └── <modul>/                z. B. ad-administration, ea-ehrenamt
│           ├── 00-steckbrief.md
│           ├── 01-erhebung.md
│           ├── 02-stories.md
│           └── spec.md
├── supabase/
│   ├── config.toml
│   ├── migrations/
│   ├── functions/                  Edge Functions
│   ├── seed.sh                     Seed-Skript, bricht bei PROD ab
│   └── seed.sql                    nur fiktive Daten
├── src/                            Frontend (React + TypeScript + Vite, shadcn/ui)
│   └── assets/brand/               DAV-Logos (unverändert)
└── wrangler.jsonc                  Cloudflare-Konfiguration
```
