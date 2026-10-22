# CLAUDE.md

Arbeitsanweisungen für Claude Code im Vereins OS. Grundlage: [docs/tech-stack.md](docs/tech-stack.md), Abschnitte 6 (Konventionen) und 7 (Repo-Struktur).

Antworte immer auf Deutsch.

## Fachliche Quelle

- `docs/specs/<modul>/` ist die fachliche Quelle: `00-steckbrief.md`, `01-erhebung.md`, `02-stories.md`, `spec.md`. Umgesetzt wird, was dort steht.
- Spec Kit liest die `spec.md` eines Moduls und erzeugt daraus `plan.md` und `tasks.md`. Eine eigene Spec-Kit-`spec.md` wird nicht separat gepflegt.
- Begriffe nach [docs/glossar.md](docs/glossar.md): ein Begriff pro Sache, keine Synonyme. Im Code (Datenbank) englisch, in der Oberfläche deutsch.

## Fachliche Dokumente (Quelle: OneDrive)

- Quelle der fachlichen Dokumente ist der Ordner
  `~/Library/CloudStorage/OneDrive-DeutscherAlpenvereine.V/Claude/VereinsOS`
  (Spiegel des Projektwissens). Ins Repository gehören daraus nur `PRODUCT.md` und `docs/`.
  Nie übernehmen: `_alt/`, `_nur-projektwissen/`, `Claude outputs/`, `.DS_Store`.

- Zu Beginn jeder Aufgabe abgleichen:
  ```bash
  SRC=~/Library/CloudStorage/OneDrive-DeutscherAlpenvereine.V/Claude/VereinsOS
  diff -rq -x .DS_Store "$SRC/docs" docs | grep -v "^Only in docs"
  diff -q "$SRC/PRODUCT.md" PRODUCT.md
  ```
  Gibt es Unterschiede: eigener Branch `docs/sync-JJJJ-MM-TT`, dann
  ```bash
  rsync -av --checksum --exclude .DS_Store "$SRC/docs/" docs/
  cp "$SRC/PRODUCT.md" PRODUCT.md
  ```
  Ohne `--delete`: Dateien, die nur im Repository liegen (z. B. `contracts/`), bleiben.
  Danach die Personendaten-Prüfung (unten), dann ein Pull Request mit der Liste der
  geänderten Dateien und ihrer Version und der vollständigen Cloudflare-Vorschau-URL.
  Betrifft die Aufgabe geänderte Dokumente, erst nach dem Merge weitermachen.

- Die übernommenen Dateien nicht ändern. Bei Widerspruch oder Lücke anhalten und
  beschreiben (Datei, Abschnitt, Vorschlag). Die Änderung erfolgt im Anforderungs-Chat
  und kommt über OneDrive zurück. Ausnahme: Was Spec Kit oder Claude Code erzeugt
  (z. B. `plan.md`, `tasks.md`, `contracts/`), wird nur im Repository gepflegt.

- Personendaten-Prüfung vor jedem Commit von `docs/` (öffentliches Repository):
  ```bash
  grep -rEn "DE[0-9]{20}" docs PRODUCT.md
  grep -rEhoi "[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}" docs PRODUCT.md | sort -u
  ```
  Bei einer IBAN oder einer E-Mail-Adresse außerhalb von @dav-leipzig.de, example.test
  und example.org (reservierte Beispieldomains): anhalten und fragen.

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
- **Je Story ein Branch** (z. B. `us-ad-01-ersteinrichtung`).
- **Commit-Nachrichten deutsch.**
- **Pull Request erstellt der Product Owner** bzw. Claude Code erst nach Rückfrage.

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
