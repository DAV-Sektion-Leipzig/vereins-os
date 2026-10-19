# Vereins OS Constitution

## Core Principles

### I. Fachliche Quelle: docs/specs/<modul>/spec.md

- `docs/specs/<modul>/spec.md` ist die führende fachliche Quelle eines Moduls. Umgesetzt wird,
  was dort steht – nicht mehr und nicht weniger. Ergänzend gelten `00-steckbrief.md`,
  `01-erhebung.md` und `02-stories.md` desselben Ordners.
- Eine eigene Spec-Kit-`spec.md` wird nicht gepflegt; `/speckit-specify` wird nicht genutzt.
- `plan.md` und `tasks.md` werden aus der `spec.md` erzeugt und in `docs/specs/<modul>/`
  abgelegt.
- Begriffe MÜSSEN [docs/glossar.md](../../docs/glossar.md) folgen: ein Begriff pro Sache,
  keine Synonyme; im Code (Datenbank) englisch, in der Oberfläche deutsch.

Begründung: Eine einzige fachliche Quelle verhindert, dass Spec-Kit-Artefakte und
Fachdokumente auseinanderlaufen.

### II. Offene Punkte werden gemeldet, nicht entschieden

- Fehlt eine fachliche Entscheidung oder widersprechen sich Dokumente, DARF der Agent sie
  NICHT selbst treffen bzw. auflösen.
- Der Punkt MUSS als `[OFFEN]` gekennzeichnet und mit Quelle (Datei) gemeldet werden, im
  Format von [docs/offene-punkte.md](../../docs/offene-punkte.md).
- Annahmen bleiben als `[ANNAHME]` sichtbar, bis der Product Owner sie bestätigt.

Begründung: Fachliche Entscheidungen liegen beim Product Owner; stille Annahmen im Code
sind später kaum auffindbar.

### III. Sicherheit in der Datenbank (NICHT VERHANDELBAR)

- **RLS auf jeder Tabelle**, ohne Ausnahme. Keine Tabelle ohne Policy.
- Rechteprüfung erfolgt in der Datenbank (RLS über Rechte-Tabellen), nie nur im Frontend.
- GRANTs nur an `authenticated`, nie an `anon`. Jede Migration, die eine Tabelle, View oder
  Funktion anlegt, vergibt Rechte ausdrücklich per `grant … to authenticated`.
- Das Frontend nutzt ausschließlich den Publishable Key (`sb_publishable_…`, Variable
  `VITE_SUPABASE_ANON_KEY`); Schutz entsteht allein über RLS.
- Secret Key / `service_role` nie im Frontend, nie in `.env`-Dateien, nie im Repo.

Begründung: Das Frontend greift direkt auf Supabase zu und das Repository ist öffentlich;
die Datenbank ist die einzige verlässliche Schutzschicht.

### IV. Personenmodell, Historie und Datensparsamkeit

- Eigenschaften einer Person werden als eigene Zeilen geführt (Person – Eigenschaftsart –
  Wert – gültig von/bis), nicht als Spalten (siehe [docs/rollen.md](../../docs/rollen.md)).
- Neue Eigenschaftsarten MÜSSEN ohne Änderung der Datenstruktur möglich sein.
- Einträge tragen `valid_from`/`valid_to`; automatische Löschung 5 Jahre nach Ende der
  Gültigkeit.
- Gespeichert werden nur Daten, die ein konkreter Ablauf braucht.

Begründung: Rechte je Eigenschaftsart per RLS, frei definierbare Felder und Historie;
Grundlage für DSGVO-konforme Löschung.

### V. Daten, Secrets und Umgebungen (NICHT VERHANDELBAR)

- Keine Echtdaten, weder in Tests noch im Projekt TEST. Testdaten nur fiktiv über
  `supabase/seed.sql`, inkl. Testzugängen je Rechtevorlage.
- Keine Secrets im Repo. Keys nur in Supabase Vault bzw. GitHub-Secrets.
- Lokale Werte stehen in `.env.local` (nicht versioniert, Vorlage `.env.example`);
  `.env.local` wird vom Agenten nie gelesen, angezeigt oder geändert.
- Nie gegen PROD arbeiten: Lokale Entwicklung und Vorschau-Deployments nutzen ausschließlich
  `vereins-os-test`. Keine Migrationen, Seeds, Abfragen oder CLI-Befehle gegen
  `vereins-os-prod`; PROD wird nur über das Deployment von `main` angesprochen.

Begründung: Für PROD gibt es kein Backup (Risiko akzeptiert, tech-stack.md); ein Fehler
dort ist nicht wiederherstellbar.

### VI. Automatisieren, einmal pflegen, verknüpfen

- Wiederkehrende Abläufe laufen per Knopfdruck oder zeitgesteuert (pg_cron), statt manuell
  erfasst zu werden.
- Daten werden einmal gepflegt und modulübergreifend genutzt (Verknüpfung statt
  Einzellisten); Module DÜRFEN keine eigenen Kopien von Personendaten anlegen.
- Nicht-Ziele aus vision.md sind bindend: keine Finanzbuchhaltung (nur Übergabe), keine
  Mitgliederverwaltung („Mitglied ja/nein“ ist eine Eigenschaft), im MVP keine Anmeldung von
  Aktiven.

Begründung: Das Vereins OS ersetzt unverknüpfte Excel-Listen und manuelle Läufe.

### VII. Kostenfrei, einfach, mobil

- Nur kostenfreie Pläne (Supabase, Cloudflare, GitHub, Gmail), solange kein Budget
  freigegeben ist; keine kostenpflichtigen Dienste in den ersten 6 Monaten.
- Bedienbar ohne Schulung durch die Geschäftsstelle.
- Alle Screens mobil nutzbar ab 375 px Breite.
- UI-Texte deutsch, Ansprache mit „du“.

Begründung: Betrieb mit 0 €/Monat (Ziel Z4) und kleine Nutzergruppe ohne Schulungsaufwand.

## Technische Konventionen

- **Stack:** Supabase (Free-Plan, EU) für Datenbank, Auth, Edge Functions und Jobs;
  React + TypeScript + Vite mit shadcn/ui als statische SPA; Hosting auf Cloudflare Workers
  mit Static Assets. Keine Serverlogik bei Cloudflare – es gibt nur ein Backend.
- **Datenbanknamen:** englisch, snake_case (`ea_persons`, `ea_property_types`, `valid_from`).
- **Tabellen je Modul:** Präfix nach Modulkürzel in Kleinbuchstaben (`ad_api_keys`,
  `ea_persons`, `ea_assignments`, `gr_groups`). Alle Tabellen im Schema `public`, kein eigenes
  Schema je Modul.
- **Schemaänderungen nur per Migration** in `supabase/migrations/`, nie direkt im Dashboard.
- **Mails** enthalten keine Personendaten außer der Empfängeradresse und einem kurzen
  Hinweistext mit Link ins Vereins OS.
- **Repo-Struktur** nach [docs/tech-stack.md](../../docs/tech-stack.md) Abschnitt 7.

## Arbeitsablauf mit Spec Kit

1. Fachliche Grundlage ist `docs/specs/<modul>/spec.md` (Prinzip I). `/speckit-specify`
   entfällt; `/speckit-clarify` DARF Unklarheiten nur als `[OFFEN]` melden, nicht entscheiden.
2. Vor `/speckit-plan` wird das Feature-Verzeichnis auf `docs/specs/<modul>/` gesetzt
   (`SPECIFY_FEATURE_DIRECTORY` bzw. `.specify/feature.json`), damit `plan.md`, `tasks.md`
   und weitere Plan-Artefakte dort entstehen.
3. Der „Constitution Check“ in `plan.md` prüft jedes Prinzip I–VII. Verstöße MÜSSEN begründet
   oder behoben werden, bevor `/speckit-tasks` läuft.
4. Umsetzung test- und spec-getrieben (`/speckit-implement`): Tests laufen gegen Supabase TEST
   mit Seed-Daten; RLS-Policies werden je Rechtevorlage mit den Testzugängen geprüft.
5. Arbeit auf eigenem Branch je Story bzw. Aufgabe (z. B. `us-ad-01-ersteinrichtung`);
   Abnahme im Cloudflare-Vorschau-Deployment (gegen TEST), Produktion nur über `main`.

## Governance

- Diese Constitution hat Vorrang vor anderen Arbeitsweisen. Sie wird aus docs/vision.md,
  docs/tech-stack.md und CLAUDE.md abgeleitet; ändert sich eine dieser Quellen, wird die
  Constitution nachgezogen. Widersprechen sich Quelle und Constitution, gilt Prinzip II.
- Änderungen nur per Pull Request: Arbeit auf eigenem Branch je Story bzw. Aufgabe
  (z. B. `us-ad-01-ersteinrichtung`), Freigabe durch den Product Owner (Toni Werner) nach
  Prüfung der Cloudflare-Vorschau. Nie direkt auf `main` committen oder pushen.
- Versionierung nach SemVer: MAJOR bei Entfernen oder Umdeuten eines Prinzips, MINOR bei
  neuem Prinzip oder Abschnitt bzw. wesentlicher Erweiterung, PATCH bei Klarstellungen.
- Jeder Plan (Constitution Check) und jeder Pull Request MUSS die Einhaltung prüfen.
- Laufende Arbeitsanweisungen für den Agenten stehen in [CLAUDE.md](../../CLAUDE.md).

**Version**: 1.0.1 | **Ratified**: 2026-10-19 | **Last Amended**: 2026-10-19
