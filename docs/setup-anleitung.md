# Setup-Anleitung: Vereins OS mit Claude Code

Stand: 24.10.2026 · Version 0.4 · Grundlage: tech-stack.md v0.6, rollen.md v0.6, spec.md AD v0.5.1
Ablage: `docs/setup-anleitung.md`

Legende: **[DU]** = manuell im Browser/Dashboard · **[CC]** = in Claude Code ausführen lassen · [ANNAHME] / [OFFEN] wie im Projekt üblich.

Reihenfolge ist verbindlich: Konten → Repo → Claude Code → Frontend → Supabase → Cloudflare → Prüfung. Erst danach mit Spec Kit an US-AD-01 beginnen.

Änderungen v0.4 (24.10.2026): Umzug nach `DAV-Sektion-Leipzig/vereins-os` (öffentlich); Phase 6 auf Produktion und Vorschau-Basis von Cloudflare umgestellt (`npx wrangler preview`, `"previews": {}` in `wrangler.jsonc`, Build-Variablen je Konfiguration); offene Punkte zu Sichtbarkeit des Repositorys und Trennung PROD/TEST entschieden; Merge-Art als offener Punkt.

Änderungen v0.3 (21.10.2026): Impeccable über `npx impeccable install`, PRODUCT.md und DESIGN.md im Wurzelverzeichnis; Supabase MCP zurückgestellt; Spec-Kit-Befehle mit Bindestrich; kein `supabase config push`, Auth-Einstellungen per Dashboard-Checkliste; Phase 8 abgeschlossen bis auf P3 und P7.

---

## Phase 0: Voraussetzungen (lokal)

| Werkzeug | Zweck | Prüfung |
|---|---|---|
| Git | Versionsverwaltung | `git --version` |
| Node.js LTS + npm | Vite, shadcn, Wrangler, Supabase CLI | `node -v` |
| uv (Python-Tool-Manager) | Installation Spec Kit | `uv --version` |
| VS Code + Claude Code | Entwicklung | `claude --version` |
| Docker Desktop | nicht nötig: kein Docker lokal, pgTAP läuft in der GitHub Action (Frage 2, entschieden) | – |

---

## Phase 1: Konten und Projekte anlegen [DU]

Diese Schritte kann Claude Code nicht übernehmen (Login, Verträge, Region).

### 1.1 GitHub
- [ ] Repository `vereins-os` im Konto der Sektion anlegen, Branch `main`. [OFFEN] öffentlich oder privat (siehe offene Punkte).
- [ ] Settings → Code security: **Secret scanning** und **Push protection** aktivieren (Schutz gegen versehentlich eingecheckte Keys).
- [ ] Branch-Schutz für `main` per Ruleset: Pull Request erforderlich, kein Force-Push, kein Löschen (entschieden 19.10.2026, tech-stack.md).

### 1.2 Supabase (Free-Plan, 2 Projekte)
- [ ] Projekt `vereins-os-test` anlegen, Region **EU Central (Frankfurt)**.
- [ ] Projekt `vereins-os-prod` anlegen, Region **EU Central (Frankfurt)**. Region ist nachträglich nicht änderbar.
- [ ] Je Projekt notieren (nicht ins Repo): Project Ref, Project URL, Anon-/Publishable Key, DB-Passwort.
- [ ] Persönliches Access Token unter Account → Access Tokens erzeugen (für die CLI).
- [ ] Auftragsverarbeitungsvertrag (DPA) mit Supabase abschließen.

### 1.3 Google-Konto der Sektion (SMTP für Login-Mails)
- [ ] Zwei-Faktor-Anmeldung aktivieren (Voraussetzung für App-Passwörter).
- [ ] App-Passwort „Vereins OS Supabase“ erzeugen. Nur in den Supabase-Einstellungen hinterlegen (Schritt 5.4), nie im Repo.

### 1.4 Cloudflare
- [ ] Konto anlegen (Free-Plan).
- [ ] Auftragsverarbeitungsvertrag (DPA) abschließen.
- [ ] GitHub-App von Cloudflare erst in Phase 6 verbinden.

---

## Phase 2: Repository und Claude Code vorbereiten

### 2.1 Repo öffnen [DU]
Das Repo liegt lokal unter `~/GitHub/vereins-os` (angelegt mit GitHub Desktop). In VS Code: Datei → Ordner öffnen → `~/GitHub/vereins-os`.

### 2.2 Projektdokumente übernehmen [DU]
Aus dem Claude-Projekt nach `docs/` kopieren: vision.md, modul-landkarte.md, rollen.md, glossar.md, tech-stack.md, vorlagen.md, offene-punkte.md, diese Datei; nach `docs/specs/ad-administration/`: 00-steckbrief.md, 01-erhebung.md, 02-stories.md, spec.md.

### 2.3 .gitignore und .env [CC]
Prompt:
> Lege `.gitignore` an für Node/Vite, `.env*` (außer `.env.example`), `.wrangler/`, `supabase/.temp/`, `supabase/.branches/`. Lege `.env.example` an mit `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`, `SEED_TEST_PASSWORD` – ohne Werte.

Danach **[DU]**: `.env.local` mit den Werten von **TEST** befüllen. Lokal wird nie gegen PROD entwickelt.

### 2.4 CLAUDE.md [CC]
Prompt:
> Erstelle `CLAUDE.md` aus `docs/tech-stack.md` Abschnitt 6 (Konventionen) und 7 (Repo-Struktur). Inhalte: fachliche Quelle ist `docs/specs/<modul>/`; Begriffe nach `docs/glossar.md`; DB englisch snake_case mit Modulpräfix; UI deutsch, Ansprache „du“; RLS auf jeder Tabelle; Schemaänderungen nur per Migration; keine Echtdaten, keine Secrets; nie gegen PROD arbeiten; offene Punkte nicht selbst entscheiden, sondern als [OFFEN] melden.

### 2.5 Berechtigungen für Claude Code [CC]
Prompt:
> Lege `.claude/settings.json` an: Lesen und Ändern von `.env`, `.env.local` und `.env.*.local` verbieten; Befehle `supabase db push`, `supabase link`, `supabase functions deploy`, `supabase secrets set`, `wrangler deploy` (auch mit `npx`) und `git push` nur mit Rückfrage.

Grund: Ein falsches `supabase link` lenkt Migrationen auf PROD.

---

## Phase 3: Spec Kit

### 3.1 Installieren [DU]
```bash
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git
specify version
```
Nur das Paket aus `github/spec-kit` verwenden; gleichnamige Pakete auf PyPI sind nicht offiziell.

### 3.2 Im Repo initialisieren [DU]
```bash
specify init --here --integration claude
```
Erzeugt `.specify/` und die Befehle für Claude Code als Skills unter `.claude/skills/`. Aufruf mit Bindestrich: `/speckit-constitution`, `/speckit-specify`, `/speckit-clarify`, `/speckit-plan`, `/speckit-tasks`, `/speckit-implement`, dazu `/speckit-analyze`, `/speckit-checklist`, `/speckit-converge`. Danach Claude Code neu starten.

### 3.3 Constitution [CC]
> `/speckit-constitution` Leite die Constitution aus den Prinzipien in `docs/vision.md` und den Konventionen in `docs/tech-stack.md` Abschnitt 6 ab. Ergänze: `docs/specs/<modul>/spec.md` ist führend; `/speckit-specify` wird nicht genutzt.

**Ablage:** Spec Kit legt standardmäßig eigene Ordner `specs/<nr>-<feature>/` mit eigener spec.md an. Im Vereins OS ist `docs/specs/<modul>/spec.md` führend; Spec Kit erzeugt dort nur plan.md, tasks.md und die Begleitdokumente. Umsetzung: `/speckit-specify` überspringen, `/speckit-plan` mit Verweis auf `docs/specs/<modul>/spec.md` aufrufen. Für AD umgesetzt und geprüft (`check-prerequisites.sh` liefert `docs/specs/ad-administration` als FEATURE_DIR).

---

## Phase 4: Frontend-Grundgerüst [CC]

### 4.1 Vite + React + TypeScript
> Erzeuge im Repo-Root ein Vite-Projekt mit Template `react-ts` (vorhandene Dateien nicht überschreiben). Installiere `@supabase/supabase-js` und `react-router-dom`. Lege `src/lib/supabase.ts` an, das URL und Key aus `import.meta.env` liest.

### 4.2 Tailwind CSS v4 + shadcn/ui
> Installiere `tailwindcss` und `@tailwindcss/vite`, trage das Plugin in `vite.config.ts` ein. Setze den Alias `@` → `./src` in `tsconfig.json`, `tsconfig.app.json` und `vite.config.ts`. Führe `npx shadcn@latest init` aus (kein `tailwind.config.js`, Tailwind v4). Füge `button`, `input`, `label`, `card`, `dialog`, `table`, `badge`, `select`, `sonner` hinzu.

### 4.3 Impeccable (Design-Regeln)
[DU] Installation:
```bash
npx impeccable install
```
Bei der Auswahl nur **Claude Code** und den Bereich **Project** wählen. Das legt den Skill unter `.claude/skills/impeccable/` und die Hilfs-Agents unter `.claude/agents/` an. Das plattformabhängige Programm unter `.claude/skills/impeccable/scripts/bin/` steht in `.gitignore`; der Starter lädt es bei Bedarf selbst.

[CC] Danach:
> `/impeccable init` und `/impeccable document`.

Impeccable legt `PRODUCT.md` und `DESIGN.md` im **Wurzelverzeichnis** an (Konvention des Skills), nicht in `docs/`. Markenvorgaben des DAV stehen in `docs/marke.md`, das Logo unter `src/assets/brand/`.

### 4.4 Cloudflare-Anbindung im Code
> Installiere `@cloudflare/vite-plugin` und `wrangler` als devDependencies, trage das Plugin in `vite.config.ts` ein. Lege `wrangler.jsonc` an: name `vereins-os`, aktuelles `compatibility_date`, `assets.not_found_handling = "single-page-application"`, kein Worker-Code (`main` weglassen).

Die SPA-Einstellung liefert für alle unbekannten Routen `index.html` aus (Routing `/ad/personen/:id` usw.).

### 4.5 Lokaler Test [DU]
```bash
npm run dev
```
Startseite lädt, keine Fehler in der Konsole.

---

## Phase 5: Supabase

### 5.1 CLI und Projektstruktur [CC]
> Installiere die Supabase CLI als devDependency (`npm i -D supabase`). Führe `npx supabase init` aus. In `supabase/config.toml`: `enable_signup = false`, Mindestlänge Passwort 8, `site_url` und `additional_redirect_urls` mit Platzhaltern für lokal, Vorschau und PROD.

### 5.2 Mit TEST verknüpfen [DU]
```bash
npx supabase login
npx supabase link --project-ref <ref-test>
```
**Regel:** Das Repo ist immer mit TEST verknüpft. Wie Migrationen nach PROD kommen: [OFFEN], siehe offene Punkte.

### 5.3 Supabase MCP: zurückgestellt
Supabase MCP wird vorerst nicht genutzt (Entscheidung tech-stack.md Abschnitt 6): OAuth scheitert mit der projektgebundenen URL, die Basis-URL hätte Zugriff auf PROD. Datenbankarbeit läuft über die Supabase CLI. Es gibt keine `.mcp.json` im Repo. Falls später doch: nur gegen TEST und nur lesend (`read_only=true`).

### 5.4 Auth-Einstellungen im Dashboard [DU] – je Projekt TEST und PROD
Kein `supabase config push` und kein `supabase config diff`, weder gegen TEST noch gegen PROD. `supabase/config.toml` gilt nur für den lokalen Stack der GitHub Action. Die Auth-Einstellungen (Selbstregistrierung aus, Passwortlänge, SMTP, Rate Limits, URL Configuration, Mailvorlagen) stellt der Product Owner im Dashboard ein, nach der Checkliste in `supabase/setup/README.md`, und hakt sie dort je Projekt ab.

Stand: TEST vollständig abgehakt (Punkte 1–9); PROD folgt bei der Ersteinrichtung.

### 5.5 Erweiterungen
`citext`, `pg_trgm`, `pg_cron` werden per Migration aktiviert (spec.md AD, T1). Kein manueller Schritt im Dashboard.

### 5.6 Edge Functions
Service-Schlüssel und Projekt-URL stehen Edge Functions automatisch als Umgebungsvariablen zur Verfügung. Weitere Secrets nur per `npx supabase secrets set …` (mit Rückfrage, siehe 2.5).

### 5.7 Seed in TEST
Der Seed läuft über `supabase/seed.sh` (Daten in `supabase/seed.sql`). Das Skript übergibt das Testpasswort aus `SEED_TEST_PASSWORD` per `psql -v` und prüft vorher die Project Ref; bei vereins-os-prod bricht es mit „Seed in PROD nicht erlaubt.“ ab (spec.md AD Abschnitt 9, Frage 3 entschieden).

---

## Phase 6: Cloudflare (Hosting)

### 6.1 Worker mit GitHub verbinden [DU]
- [ ] Workers & Pages → Worker `vereins-os` → Einstellungen → Builds → Git-Repository: `DAV-Sektion-Leipzig/vereins-os`. Die GitHub-App von Cloudflare ist in der Organisation DAV-Sektion-Leipzig installiert und hat Zugriff auf `vereins-os`.
- [ ] API-Token: „Workers Builds – 2026-10-19 18:29“ (gilt für Produktion und Vorschau-Basis).

Cloudflare führt die Builds in zwei Konfigurationen (Einstellungen → Builds, Umschalter „Produktion“ / „Vorschau-Basis“):

| Einstellung | Produktion | Vorschau-Basis |
|---|---|---|
| Gilt für | Produktionsbranch `main` | jeden anderen Branch (eine Vorschau je Branch) |
| Build-Befehl | `npm run build` | `npm run build` |
| Befehl danach | Bereitstellungsbefehl `npx wrangler deploy` | Vorschau-Befehl `npx wrangler preview` |
| Stammverzeichnis | `/` | `/` |
| Schalter | „Builds deaktivieren“ aus | „Builds für Vorschau-Zweige“ an |
| Adresse | `https://vereins-os.sektion-leipzig.workers.dev` | `https://<branch>-vereins-os.sektion-leipzig.workers.dev` (Schrägstriche im Branchnamen werden zu `-`, z. B. `claude/abc` → `claude-abc-vereins-os…`) |

- `wrangler.jsonc` braucht dafür den Block `"previews": {}` (darf leer sein); ohne ihn bricht `npx wrangler preview` mit „missing a previews block“ ab.
- `npx wrangler versions upload` funktioniert mit der Vorschau-Basis nicht mehr (Fehler „The name in your wrangler.json file (vereins-os) must match the name of your Worker“), weil jede Vorschau ein eigener Worker ist. Die frühere Einstellung „Builds for non-production branches“ bietet Cloudflare für diesen Worker nicht mehr an.
- Neue Vorschauen übernehmen Befehl und Variablen aus der Vorschau-Basis. Wird ein Branch gelöscht, löscht Cloudflare seine Vorschau („Automatisches Löschen“ an).
- Domänen: workers.dev an, Vorschau-URLs an.

### 6.2 Umgebungsvariablen für den Build [DU]
Vite schreibt `VITE_*`-Werte beim Build in das Bundle. Sie stehen deshalb unter **Builds → Variablen und geheime Schlüssel** (Build-Variablen), nicht als Laufzeitvariablen, und zwar in **beiden** Konfigurationen:

| Variable | Produktion | Vorschau-Basis |
|---|---|---|
| `VITE_SUPABASE_URL` | bis zum Go-live TEST (`https://zskpywhanbthaytmiqxe.supabase.co`), danach PROD | immer TEST |
| `VITE_SUPABASE_ANON_KEY` | bis zum Go-live Publishable Key von TEST, danach von PROD | immer Publishable Key von TEST |

URL ohne Anführungszeichen, ohne Leerzeichen, ohne `/rest/v1` und ohne Schrägstrich am Ende. Fehlen die Werte, bricht die App beim Start mit „Supabase-Konfiguration fehlt“ ab.

Damit sind PROD- und TEST-Werte getrennt: Beim Go-live werden nur die Werte unter **Produktion** auf PROD umgestellt; Vorschauen bleiben auf TEST.

Anon-/Publishable Key ist öffentlich (Schutz nur über RLS). Der Service-Schlüssel kommt **nie** zu Cloudflare.

### 6.3 Redirect-URLs nachtragen [DU]
`https://vereins-os.sektion-leipzig.workers.dev` (PROD) und das Muster der Vorschau-URLs `https://*-vereins-os.sektion-leipzig.workers.dev/**` (TEST) in Supabase → URL Configuration eintragen (Checkliste `supabase/setup/README.md`, Punkte 5 und 6).

---

## Phase 7: Werkzeuge ohne Code

| Werkzeug | Einrichtung |
|---|---|
| Excalidraw | VS Code-Erweiterung „Excalidraw“; Dateien in `docs/diagrams/*.excalidraw` |
| Claude Design | läuft in claude.ai, nicht in Claude Code; Ergebnisse als Bild/Markdown in `docs/` ablegen |

---

## Phase 8: Abnahme des Setups

Abgeschlossen am 21.10.2026, außer P3 und P7.

| # | Prüfung | Erwartet | Stand |
|---|---|---|---|
| P1 | `npm run dev` | App lokal erreichbar, verbunden mit TEST | erledigt |
| P2 | `npx supabase migration list` | zeigt TEST, keine Fehler | erledigt |
| P3 | In Claude Code: „Liste die Tabellen in TEST“ (MCP) | Antwort aus TEST, nicht PROD | entfällt (MCP zurückgestellt, 5.3) |
| P4 | Push auf einen Branch | Vorschau-URL erreichbar | erledigt |
| P5 | Merge nach `main` | `*.workers.dev` erreichbar, Direktaufruf `/ad` liefert die App (SPA-Fallback) | erledigt |
| P6 | `git grep -i "service_role\|sb_secret\|app-passwort"` | keine Treffer | erledigt |
| P7 | Testmail „Passwort vergessen“ an eine reale @dav-leipzig.de-Adresse | kommt an, nicht im Spam (Risiko aus Steckbrief AD) | offen: bei der Ersteinrichtung von PROD (US-AD-01 AK5) |
| P8 | `/speckit-constitution` ausgeführt, `.specify/memory/constitution.md` gefüllt | ja | erledigt |

Danach: Umsetzung AD in der Reihenfolge aus 02-stories.md mit `/speckit-plan`, `/speckit-tasks` und `/speckit-implement` für `docs/specs/ad-administration/spec.md`.

---

## Annahmen und offene Punkte

Entschieden:
- Branch-Schutz auf `main` per Ruleset (19.10.2026).
- Spec Kit arbeitet mit `docs/specs/<modul>/` als Quelle (für AD geprüft).
- Impeccable über `npx impeccable install`; PRODUCT.md und DESIGN.md im Wurzelverzeichnis.
- Supabase MCP zurückgestellt; Datenbankarbeit über die Supabase CLI.
- Kein `supabase config push`; Auth-Einstellungen per Dashboard-Checkliste (`supabase/setup/README.md`).
- Kein Docker lokal: Die Datenbanktests (pgTAP, `supabase test db`) laufen in einer GitHub Action mit lokalem Supabase-Stack und Seed; die fachliche Abnahme läuft in TEST.
- Seed über `supabase/seed.sh` mit Passwort aus `SEED_TEST_PASSWORD`; Abbruch mit „Seed in PROD nicht erlaubt.“ (spec.md AD Abschnitt 9).
- Repository öffentlich unter `DAV-Sektion-Leipzig/vereins-os` (Umzug von `DAVLeipzig/vereins-os`, 24.10.2026). Im kostenlosen Plan sind Ruleset für `main` und Auto-Merge nur für öffentliche Repositories verfügbar.
- Cloudflare-Vorschau je Branch über die Vorschau-Basis mit `npx wrangler preview`; Build-Variablen getrennt für Produktion und Vorschau-Basis (6.1, 6.2; 24.10.2026).

Offen:
- [OFFEN] Weg der Migrationen nach PROD: manuell durch den Product Owner (`supabase link` auf PROD, `db push`, zurück auf TEST) oder per GitHub Action beim Merge auf `main`? Vor dem ersten PROD-Deployment. (offene-punkte.md AD)
- [OFFEN] Merge-Art für Pull Requests: Merge-Commit (CLAUDE.md, `gh pr merge --merge`) oder Squash. Bis zur Entscheidung Merge-Commit.
