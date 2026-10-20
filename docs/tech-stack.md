# Tech-Stack: Vereins OS

Stand: 20.10.2026 · Version 0.6 · Vorbild: Architektur eines vergleichbaren Projekts (Development Layer, Skills & Frameworks, GitHub, statisches Frontend-Hosting, zwei Supabase-Instanzen); Hosting abweichend vom Vorbild bei Cloudflare statt GitHub Pages

## Überblick

```
Entwicklung (lokal)                     Versionsverwaltung            Betrieb
VS Code + Claude Code  ── push/pull ──▶ GitHub (Sektions-Repo) ──▶ Cloudflare (Frontend, statisch)
   │  lokales Frontend ──▶ Supabase TEST     │                       ├─ Produktion   ──▶ Supabase PROD
   └─ Skills: shadcn/ui, Impeccable,         │                       └─ Vorschau je Branch ──▶ Supabase TEST
      Spec Kit, Supabase CLI,                └──▶ Supabase CLI: Migrationen, Edge Functions
      Excalidraw, Claude Design
```

## 1. Datenbank & Auth

- **Supabase, Free-Plan**, zwei Projekte:

| Projekt | Zweck | Daten |
|---|---|---|
| vereins-os-test | Entwicklung, Tests, Abnahme, Testzugänge | nur fiktive Daten (Seed) |
| vereins-os-prod | Produktivbetrieb Geschäftsstelle | Echtdaten |

- Free-Plan erlaubt genau 2 aktive Projekte; damit ist das Kontingent ausgeschöpft.
- **Pausierung:** Free-Projekte werden nach 7 Tagen geringer Aktivität pausiert. PROD ist durch tägliche Nutzung der Geschäftsstelle geschützt; TEST wird bei Bedarf im Dashboard wieder gestartet. [ANNAHME: kein Keep-alive-Job nötig]
- **Backups:** Im Free-Plan gibt es keine herunterladbaren Backups. Eine eigene Sicherung von PROD ist bewusst nicht im Scope (Entscheidung Product Owner, 19.10.2026). Akzeptiertes Risiko: Datenverlust in PROD ist nicht wiederherstellbar; TEST enthält nur fiktive Daten und ersetzt kein Backup.
- **Region:** EU (Frankfurt). [ANNAHME]
- **Auth:** E-Mail und Passwort. Benutzername ist immer die DAV-E-Mail-Adresse der Person (gepflegt über das Portal „DAV 360 Mitarbeiter“). SSO später prüfen.
- **Selbstregistrierung aus.** Nutzer legt nur der Admin an (Einladung). [ANNAHME]
- **Secrets / API-Keys:** Supabase Vault; Zugriff nur serverseitig (Edge Functions, Datenbankfunktionen). Metadaten (Dienst, zuletzt gewechselt, Ablaufdatum) in einer Tabelle im Modul AD.
- **Serverlogik:** Supabase Edge Functions für externe Dienste und E-Mail-Versand; zeitgesteuerte Jobs (Erinnerungen, Buchungslauf, Löschung nach 5 Jahren) per Datenbank-Scheduler (pg_cron). [ANNAHME]
- **Datenschutz:** Auftragsverarbeitungsvertrag (DPA) mit Supabase abschließen; Eintrag im Verarbeitungsverzeichnis der Sektion.

## 2. Frontend

- **React + TypeScript + Vite**, als statische Single-Page-App gebaut. [ANNAHME: Vite statt Next.js; die gesamte Serverlogik liegt in Supabase, das Frontend braucht keinen eigenen Server]
- **UI-Bibliothek:** shadcn/ui mit Tailwind CSS; Komponenten-Setup und Design-Muster als Code im Repo.
- **Design-Regeln:** Impeccable-Skill mit `PRODUCT.md` und `DESIGN.md` im Wurzelverzeichnis (Impeccable-Konvention), Einstellungen in `.impeccable/`; Markenvorgaben des DAV in `docs/marke.md`. Ziel: kein generischer „KI-Look“.
- **Schrift:** Fira Sans (DAV-Vorgabe für den Online-Bereich), selbst gehostet, nicht von Google- oder Adobe-Servern geladen. Ersetzt die bisherige Geist; Umsetzung im Code folgt nach DESIGN.md.
- **Routing:** SPA-Routing mit Rückfall auf `index.html` (von Cloudflare unterstützt).
- **Mobil nutzbar:** alle Screens ab 375 px Breite. [ANNAHME]
- **Supabase-Zugriff:** direkt aus dem Frontend mit dem öffentlichen Anon-Key; Schutz ausschließlich über RLS.

## 3. Hosting

| Umgebung | Frontend | Backend |
|---|---|---|
| Lokal | `npm run dev` auf dem Entwicklungsrechner | Supabase TEST |
| Vorschau / Abnahme | Cloudflare-Vorschau-Deployment je Branch bzw. Pull Request | Supabase TEST |
| Produktion | Cloudflare, automatisches Deployment bei Push auf `main` | Supabase PROD |

- **Anbieter:** Cloudflare, kostenfrei. Free-Plan: 500 Builds pro Monat, ein Build gleichzeitig, unbegrenzt viele Vorschau-Deployments. Für ein Projekt dieser Größe ausreichend.
- **Pages oder Workers:** Cloudflare empfiehlt für neue Projekte Workers mit Static Assets; Pages wird weiter unterstützt, bekommt aber keine neuen Funktionen mehr. Für eine reine statische App sind beide gleichwertig. Entscheidung: Workers mit Static Assets. [ANNAHME]
- **Keine Serverlogik bei Cloudflare.** Cloudflare liefert nur das Frontend aus; Logik, Daten und Jobs liegen ausschließlich in Supabase. So gibt es nur ein Backend.
- **Repository:** öffentliches Repository der Sektion auf GitHub (Organisationskonto). Unkritisch, solange keine Daten, Keys oder Passwörter im Repo liegen.
- **Änderungen nur per Pull Request:** Arbeit auf eigenem Branch je Story bzw. Aufgabe; Freigabe durch den Product Owner per Merge nach Prüfung der Cloudflare-Vorschau. `main` ist per Ruleset geschützt (Pull Request erforderlich, kein Force-Push, kein Löschen).
- **Domain:** Die eigene Domain dav-leipzig.de ist nicht nutzbar (kein DNS-Zugriff). Adresse vorerst die Standard-Adresse von Cloudflare (`*.workers.dev`).
- **Datenschutz:** Cloudflare verarbeitet beim Ausliefern IP-Adressen der Nutzer. Den Auftragsverarbeitungsvertrag mit Cloudflare schließt der Product Owner ab.

## 4. E-Mail und externe Dienste

| Zweck | Dienst | Stand |
|---|---|---|
| Login-Mails (Einladung, Passwort zurücksetzen) | Google-Konto der Sektion als SMTP in Supabase Auth | MVP |
| Erinnerungen, Mails aus Abläufen | Google-Konto der Sektion über SC (Edge Function) | ab SC |
| Versand über Vereinsdomain / Microsoft-Tenant | Microsoft Graph | später; nur nach Abstimmung mit dem Bundesverband |
| Instagram, Umfrage-Dienst | über SC | ab OA |
| DATEV / Sparkasse | Datei-Export oder Schnittstelle | [OFFEN], Klärung in FI |

- Eigener SMTP ist im Free-Plan möglich; Supabase begrenzt Auth-Mails dann standardmäßig auf 30 pro Stunde. Für ca. 4 Nutzer ausreichend.
- Login-Mails gehen an DAV-Adressen (Microsoft-Tenant des Bundesverbands). Zustellung aus einem Google-Konto vor Go-live testen (Spam-Filter). [ANNAHME]
- Das Google-Konto ist ein normales Gmail-Konto. Versand per SMTP mit App-Passwort; das App-Passwort liegt nur in den Supabase-Einstellungen bzw. in Vault.
- **Datenschutz:** Für ein normales Gmail-Konto gibt es keinen Auftragsverarbeitungsvertrag. Regel: Mails enthalten keine Personendaten außer der Empfängeradresse und einem kurzen Hinweistext mit Link ins Vereins OS (z. B. „Du hast eine neue Aufgabe“ statt Aufgabeninhalt).
- Wechsel auf Microsoft Graph (Vereinsdomain) bleibt Ziel, sobald der Bundesverband zustimmt.

## 5. Werkzeuge (Skills & Frameworks)

| Werkzeug | Einsatz im Vereins OS |
|---|---|
| VS Code + Claude Code | Entwicklung |
| Spec Kit | Spec- und testgetriebene Umsetzung: constitution, specify, clarify, plan, tasks, implement |
| Supabase CLI | Schema, Migrationen, Edge Functions, Konfiguration als Code; Agent steuert Backend darüber |
| shadcn/ui | Komponenten, globales Designmuster |
| Impeccable | Design-Qualität, `PRODUCT.md`, `DESIGN.md` |
| Excalidraw | Diagramme (Datenmodell, Abläufe) als Austausch zwischen Mensch und Agent |
| Claude Design | Prototypen, Hilfsmittel in der Anforderungserhebung |

## 6. Konventionen

- **Datenbank:** Namen englisch, snake_case (`ea_persons`, `ea_property_types`, `valid_from`).
- **UI-Texte:** deutsch, Begriffe nach glossar.md.
- **RLS auf jeder Tabelle**, ohne Ausnahme. Keine Tabelle ohne Policy.
- **Schemaänderungen nur per Migration** (`supabase/migrations/`), nie direkt im Dashboard.
- **Keine Echtdaten in Tests** und nie im Projekt TEST. Testdaten nur per `supabase/seed.sh` (Daten in `seed.sql`, Passwort aus `SEED_TEST_PASSWORD`), inkl. Testzugängen je Rechtevorlage; bricht bei PROD ab.
- **Tests:** Datenbanktests (pgTAP) in einer GitHub Action mit lokalem Supabase-Stack; fachliche Abnahme in TEST mit den Testzugängen.
- **Keine Secrets im Repo.** Keys nur in Vault bzw. GitHub-Secrets.
- **Personenmodell:** Eigenschaften als eigene Zeilen (Person – Eigenschaftsart – Wert – gültig von/bis), nicht als Spalten. Grund: Rechte je Eigenschaftsart per RLS, frei definierbare Felder, Historie (siehe rollen.md).
- **Historie und Löschung:** Einträge mit `valid_from`/`valid_to`; automatische Löschung 5 Jahre nach Ende der Gültigkeit.
- **Rechte:** Rechteprüfung in der Datenbank (RLS über Rechte-Tabellen), nie nur im Frontend.
- **Supabase MCP:** vorerst nicht im Einsatz (OAuth scheitert mit projektgebundener URL; Basis-URL hätte Zugriff auf PROD). Datenbankarbeit über die Supabase CLI. Wenn später: nur gegen TEST und nur lesend (`read_only=true`).
- **Tabellen je Modul:** Präfix nach Modulkürzel in Kleinbuchstaben (z. B. `ad_api_keys`, `ea_persons`, `ea_assignments`, `gr_groups`). Alle Tabellen im Schema `public`, kein eigenes Schema je Modul.

## 7. Repo-Struktur

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
│   ├── templates/                  Mailvorlagen (Einladung, Passwort zurücksetzen)
│   ├── tests/                      pgTAP-Tests
│   ├── setup/                      Einrichtungsskript PROD
│   ├── seed.sh                     Seed-Skript, bricht bei PROD ab
│   └── seed.sql                    nur fiktive Daten
├── .github/workflows/              GitHub Actions (Datenbanktests)
├── src/                            Frontend
│   └── assets/brand/               DAV-Logos (unverändert)
└── wrangler.jsonc                  Cloudflare-Konfiguration
```

## Spec Kit und Dokumentstruktur (bestätigt 19.10.2026)

- `docs/specs/<modul>/` ist die fachliche Quelle (Steckbrief, Erhebung, Stories, Spec nach vorlagen.md).
- Spec Kit liest die spec.md eines Moduls und erzeugt daraus plan.md und tasks.md; die eigene spec.md von Spec Kit wird nicht separat gepflegt.
- Die constitution von Spec Kit wird aus den Prinzipien in vision.md und den Konventionen dieser Datei abgeleitet.

## Entscheidungen vom 19.10.2026

- Spec Kit wie oben beschrieben.
- Tabellen-Präfix nach Modulkürzel, kein eigenes Schema.
- Kein eigenes Backup von PROD (Risiko akzeptiert).
- Auftragsverarbeitungsvertrag mit Cloudflare: schließt der Product Owner ab.
- Seed über `seed.sh`, pgTAP in GitHub Action mit lokalem Stack, Abnahme in TEST.
- Änderungen nur per Pull Request, Branch-Schutz für `main` (Product Owner, 19.10.2026).
- Supabase MCP vorerst nicht nutzen; Datenbankarbeit über die Supabase CLI (Merkposten: erneut prüfen).

Keine offenen Punkte in dieser Datei.
