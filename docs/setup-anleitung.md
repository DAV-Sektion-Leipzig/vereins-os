# Setup-Anleitung: Vereins OS mit Claude Code

Stand: 20.10.2026 · Version 0.2 · Grundlage: tech-stack.md v0.5, rollen.md v0.6, spec.md AD v0.5
Ablage: `docs/setup-anleitung.md`

Legende: **[DU]** = manuell im Browser/Dashboard · **[CC]** = in Claude Code ausführen lassen · [ANNAHME] / [OFFEN] wie im Projekt üblich.

Reihenfolge ist verbindlich: Konten → Repo → Claude Code → Frontend → Supabase → Cloudflare → Prüfung. Erst danach mit Spec Kit an US-AD-01 beginnen.

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
- [ ] Repository `vereins-os` im Organisationskonto der Sektion anlegen, **öffentlich**, Branch `main`.
- [ ] Settings → Code security: **Secret scanning** und **Push protection** aktivieren (öffentliches Repo, Schutz gegen versehentlich eingecheckte Keys).
- [ ] Branch-Schutz für `main`: Änderungen nur per Pull Request. [ANNAHME]

### 1.2 Supabase (Free-Plan, 2 Projekte)
- [ ] Projekt `vereins-os-test` anlegen, Region **EU Central (Frankfurt)**.
- [ ] Projekt `vereins-os-prod` anlegen, Region **EU Central (Frankfurt)**. Region ist nachträglich nicht änderbar.
- [ ] Je Projekt notieren (nicht ins Repo): Project Ref, Project URL, Anon-/Publishable Key, DB-Passwort.
- [ ] Persönliches Access Token unter Account → Access Tokens erzeugen (für CLI und MCP).
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
> Lege `.claude/settings.json` an: Lesen von `.env*` verbieten; Befehle `supabase db push`, `supabase link`, `supabase functions deploy`, `supabase secrets set` und `wrangler deploy` nur mit Rückfrage.

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
Erzeugt `.specify/` und die Befehle für Claude Code (`/speckit.constitution`, `/speckit.specify`, `/speckit.clarify`, `/speckit.plan`, `/speckit.tasks`, `/speckit.implement`). Danach Claude Code neu starten.

### 3.3 Constitution [CC]
> `/speckit.constitution` Leite die Constitution aus den Prinzipien in `docs/vision.md` und den Konventionen in `docs/tech-stack.md` Abschnitt 6 ab. Ergänze: `docs/specs/<modul>/spec.md` ist führend; `/speckit.specify` wird nicht genutzt.

**Hinweis Widerspruch:** Spec Kit legt standardmäßig eigene Ordner `specs/<nr>-<feature>/` mit eigener spec.md an. tech-stack.md legt fest, dass `docs/specs/<modul>/spec.md` führend ist und Spec Kit nur plan.md und tasks.md erzeugt. [ANNAHME] Umsetzung: `/speckit.specify` überspringen, `/speckit.plan` mit Verweis auf `docs/specs/ad-administration/spec.md` aufrufen; Ablageort von plan.md/tasks.md = `docs/specs/<modul>/`. Beim ersten Lauf prüfen, ob die Skripte von Spec Kit das zulassen.

---

## Phase 4: Frontend-Grundgerüst [CC]

### 4.1 Vite + React + TypeScript
> Erzeuge im Repo-Root ein Vite-Projekt mit Template `react-ts` (vorhandene Dateien nicht überschreiben). Installiere `@supabase/supabase-js` und `react-router-dom`. Lege `src/lib/supabase.ts` an, das URL und Key aus `import.meta.env` liest.

### 4.2 Tailwind CSS v4 + shadcn/ui
> Installiere `tailwindcss` und `@tailwindcss/vite`, trage das Plugin in `vite.config.ts` ein. Setze den Alias `@` → `./src` in `tsconfig.json`, `tsconfig.app.json` und `vite.config.ts`. Führe `npx shadcn@latest init` aus (kein `tailwind.config.js`, Tailwind v4). Füge `button`, `input`, `label`, `card`, `dialog`, `table`, `badge`, `select`, `sonner` hinzu.

### 4.3 Impeccable (Design-Regeln)
[DU] Installation auf Projektebene:
```bash
npx skills add https://github.com/pbakaus/impeccable --skill impeccable
```
[ANNAHME] Installationsweg laut Repository; vor Ausführung README unter github.com/pbakaus/impeccable prüfen.

[CC] Danach:
> Erstelle mit Impeccable `docs/product.md` und `docs/design.md`. Kontext: Arbeitswerkzeug für 4 Nutzer einer DAV-Sektion, deutsch, sachlich, mobil ab 375 px, Tabellen werden mobil zu Karten, kein „KI-Look“.

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
**Regel:** Das Repo ist immer mit TEST verknüpft. Wie Migrationen nach PROD kommen: [OFFEN] siehe Frage 1.

### 5.3 Supabase MCP für Claude Code (nur TEST) [DU]
```bash
claude mcp add --scope project --transport http supabase \
  "https://mcp.supabase.com/mcp?project_ref=<ref-test>&features=database,docs,debugging,development,functions"
```
Danach in Claude Code `/mcp` → supabase → Authenticate.

- Immer mit `project_ref` von **TEST**. Supabase selbst rät, den MCP-Server nie mit Produktionsdaten zu verbinden.
- `.mcp.json` wird eingecheckt; sie enthält nur die Project Ref, kein Token. Die Project Ref von TEST ist im öffentlichen Repo unkritisch [ANNAHME].
- Schemaänderungen trotzdem nur per Migrationsdatei (Konvention), nicht per MCP direkt.

### 5.4 Auth-Einstellungen im Dashboard [DU] – je Projekt TEST und PROD
- [ ] Authentication → Sign In / Providers: E-Mail an, Selbstregistrierung aus.
- [ ] Authentication → SMTP: eigener SMTP, Host `smtp.gmail.com`, Port 587, Benutzer = Gmail-Adresse, Passwort = App-Passwort, Absendername „Vereins OS“.
- [ ] Authentication → Rate Limits: Mails ≤ 30/Stunde (Standard bei eigenem SMTP).
- [ ] Authentication → URL Configuration: Site URL und Redirect-URLs (nach Phase 6 nachtragen).
- [ ] Mailvorlagen „Invite user“ und „Reset password“ auf Deutsch, nur Hinweistext + Link (Text erzeugt [CC] im Rahmen von T11).

### 5.5 Erweiterungen
`citext`, `pg_trgm`, `pg_cron` werden per Migration aktiviert (spec.md AD, T1). Kein manueller Schritt im Dashboard.

### 5.6 Edge Functions
Service-Schlüssel und Projekt-URL stehen Edge Functions automatisch als Umgebungsvariablen zur Verfügung. Weitere Secrets nur per `npx supabase secrets set …` (mit Rückfrage, siehe 2.5).

### 5.7 Seed in TEST
Der Seed läuft über `supabase/seed.sh` (Daten in `supabase/seed.sql`). Das Skript übergibt das Testpasswort aus `SEED_TEST_PASSWORD` per `psql -v` und prüft vorher die Project Ref; bei vereins-os-prod bricht es mit „Seed in PROD nicht erlaubt.“ ab (spec.md AD Abschnitt 9, Frage 3 entschieden).

---

## Phase 6: Cloudflare (Hosting)

### 6.1 Worker mit GitHub verbinden [DU]
- [ ] Workers & Pages → Create → Import a repository → `vereins-os`.
- [ ] Build command: `npm run build` · Deploy command: `npx wrangler deploy` · Produktionsbranch: `main`.
- [ ] **Builds for non-production branches** aktivieren → jeder Branch-Push erzeugt eine Vorschau-Version mit eigener Vorschau-URL (Deploy-Befehl dort: `npx wrangler versions upload`).

### 6.2 Umgebungsvariablen für den Build [DU]
Vite schreibt `VITE_*`-Werte beim Build in das Bundle. Produktion braucht PROD-Werte, Vorschau braucht TEST-Werte.

[OFFEN] Wie werden PROD- und TEST-Werte je Branch getrennt? [ANNAHME] Workers Builds stellt den Branchnamen als Build-Variable bereit; ein kleines Skript wählt danach die Werte. Vor Umsetzung in der Cloudflare-Dokumentation prüfen. Bis zur Klärung: Vorschau-Builds deaktiviert lassen oder nur TEST-Werte hinterlegen und PROD erst bei Go-live umstellen.

Anon-/Publishable Key ist öffentlich (Schutz nur über RLS). Der Service-Schlüssel kommt **nie** zu Cloudflare.

### 6.3 Redirect-URLs nachtragen [DU]
`https://vereins-os.<konto>.workers.dev` (PROD) und das Muster der Vorschau-URLs (TEST) in Supabase → URL Configuration eintragen.

---

## Phase 7: Werkzeuge ohne Code

| Werkzeug | Einrichtung |
|---|---|
| Excalidraw | VS Code-Erweiterung „Excalidraw“; Dateien in `docs/diagrams/*.excalidraw` |
| Claude Design | läuft in claude.ai, nicht in Claude Code; Ergebnisse als Bild/Markdown in `docs/` ablegen |

---

## Phase 8: Abnahme des Setups

| # | Prüfung | Erwartet |
|---|---|---|
| P1 | `npm run dev` | App lokal erreichbar, verbunden mit TEST |
| P2 | `npx supabase migration list` | zeigt TEST, keine Fehler |
| P3 | In Claude Code: „Liste die Tabellen in TEST“ (MCP) | Antwort aus TEST, nicht PROD |
| P4 | Push auf Branch `setup-check` | Vorschau-URL erreichbar |
| P5 | Merge nach `main` | `*.workers.dev` erreichbar, Direktaufruf `/ad` liefert die App (SPA-Fallback) |
| P6 | `git grep -i "service_role\|sb_secret\|app-passwort"` | keine Treffer |
| P7 | Testmail „Passwort vergessen“ aus TEST an eine reale @dav-leipzig.de-Adresse | kommt an, nicht im Spam (Risiko aus Steckbrief AD) |
| P8 | `/speckit.constitution` vorhanden, `.specify/memory/constitution.md` gefüllt | ja |

Danach: Umsetzung AD in der Reihenfolge aus 02-stories.md, beginnend mit `/speckit.plan` für `docs/specs/ad-administration/spec.md`.

---

## Annahmen und offene Punkte

- [ANNAHME] Branch-Schutz auf `main`.
- [ANNAHME] Project Ref von TEST darf im öffentlichen Repo stehen (`.mcp.json`).
- [ANNAHME] Installationsweg Impeccable per `npx skills add`; vor Ausführung prüfen.
- [ANNAHME] Spec Kit lässt sich auf `docs/specs/<modul>/` als Quelle einstellen.
- [OFFEN] Frage 1: Migrationen nach PROD – manuell durch den Product Owner (`supabase link` auf PROD, `db push`, zurück auf TEST) oder per GitHub Action bei Merge auf `main`?
- Frage 2 (entschieden): kein Docker lokal. Die Datenbanktests (pgTAP, `supabase test db`, Task T7) laufen in einer GitHub Action mit lokalem Supabase-Stack und Seed; die fachliche Abnahme läuft in TEST.
- Frage 3 (entschieden): Seed über `supabase/seed.sh` mit Passwort aus `SEED_TEST_PASSWORD`; Abbruch mit „Seed in PROD nicht erlaubt.“ (spec.md AD Abschnitt 9, T23).
- [OFFEN] Trennung PROD-/TEST-Werte bei Cloudflare-Vorschau-Builds (6.2).
