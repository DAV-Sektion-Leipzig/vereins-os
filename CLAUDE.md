# CLAUDE.md

Arbeitsanweisungen für Claude Code im Vereins OS. Grundlage: [docs/tech-stack.md](docs/tech-stack.md), Abschnitte 6 (Konventionen) und 7 (Repo-Struktur).

## Fachliche Quelle

- `docs/specs/<modul>/` ist die fachliche Quelle: `00-steckbrief.md`, `01-erhebung.md`, `02-stories.md`, `spec.md`. Umgesetzt wird, was dort steht.
- Spec Kit liest die `spec.md` eines Moduls und erzeugt daraus `plan.md` und `tasks.md`. Eine eigene Spec-Kit-`spec.md` wird nicht separat gepflegt.
- Begriffe nach [docs/glossar.md](docs/glossar.md): ein Begriff pro Sache, keine Synonyme. Im Code (Datenbank) englisch, in der Oberfläche deutsch.

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

- **Keine Echtdaten**, weder in Tests noch im Projekt TEST. Testdaten nur fiktiv über `supabase/seed.sql`, inkl. Testzugängen je Rechtevorlage.
- **Keine Secrets im Repo.** Keys nur in Supabase Vault bzw. GitHub-Secrets.
- **Lokale Werte stehen in `.env.local`** (nicht versioniert); Vorlage ist `.env.example`. `.env.local` nie lesen, anzeigen oder ändern.
- **Supabase-Key im Frontend** ist ausschließlich der Publishable Key (`sb_publishable_…`), Variable `VITE_SUPABASE_ANON_KEY`.
- **Secret Key / `service_role`** nie im Frontend, nie in `.env`-Dateien, nie im Repo.

### Umgebungen

- **Nie gegen PROD arbeiten.** Lokale Entwicklung und Vorschau-Deployments nutzen ausschließlich Supabase TEST (`vereins-os-test`).
- Keine Migrationen, Seeds, Abfragen oder CLI-Befehle gegen `vereins-os-prod`. PROD wird nur über das Deployment von `main` angesprochen.

## Repo-Struktur

```
/
├── CLAUDE.md                       Arbeitsanweisungen für Claude Code
├── .specify/                       Spec Kit (constitution, Vorlagen, Skripte)
├── docs/
│   ├── vision.md
│   ├── modul-landkarte.md
│   ├── rollen.md
│   ├── glossar.md
│   ├── tech-stack.md
│   ├── vorlagen.md
│   ├── design.md                   Impeccable
│   ├── product.md                  Impeccable
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
│   └── seed.sql                    nur fiktive Daten
├── src/                            Frontend (React + TypeScript + Vite, shadcn/ui)
└── wrangler.jsonc                  Cloudflare-Konfiguration
```
