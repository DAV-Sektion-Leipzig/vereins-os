# Arbeitsplan: Mittelweg Administration und nächste Module

Stand: 22.10.2026 · Version 0.3 · Product Owner: Toni Werner
Änderungen v0.3: Quelle der Wahrheit ist das Repository (main); der OneDrive-Ordner „VereinsOS“ ist eingefroren (Entscheidung Product Owner 22.10.2026). Abschnitt 1 „Ablage“ und Abschnitt 3 angepasst.
Änderungen v0.2: Vorgabe des Product Owners: Dateien immer zusätzlich im OneDrive-Ordner „VereinsOS“ in Repository-Struktur ablegen; Abschnitt 3 auf diese Quelle umgestellt.
Ablage: im Repository `docs/arbeitsplan.md`
Grundlage: Entscheidung des Product Owners vom 22.10.2026 (Mittelweg), querschnitt-administration.md v0.1, modul-landkarte.md, offene-punkte.md

## 1. Grundsätze

- Ein Modul je Chat, immer nur ein Modul zur Zeit (Projektanweisung). Neue Chats legst du in diesem Projekt „Vereins OS Anforderungen“ an, damit das Projektwissen gilt.
- Übergreifende Fragen (Reifegrad, Querschnitt, Reihenfolge) werden im Chat **„Überblick“** geklärt, in dem dieser Plan entstanden ist.
- Claude Code arbeitet im Repository (VS Code), nicht in einem Chat dieses Projekts. Was Claude Code braucht, muss vorher unter `docs/` im Repository liegen.
- Gemeinsame Dateien werden vor jedem Schreiben neu eingelesen (Projektanweisung). Im Überblick-Chat schreibe ich nur in `offene-punkte.md`, `modul-landkarte.md` und in die Dateien dieses Plans.
- **Ablage (Entscheidung Product Owner 22.10.2026):** Quelle der Wahrheit für alle Dokumente ist das Repository DAVLeipzig/vereins-os (`main`), Ordner `docs/` und `PRODUCT.md`. Änderungen entstehen auf einem Branch `docs/<thema>` und kommen per Pull Request nach `main`. Der OneDrive-Ordner „VereinsOS“ ist eingefroren und wird nicht mehr bearbeitet. Chats ohne Zugriff auf das Repository nennen am Ende die geänderten Dateien mit Inhalt; Claude Code übernimmt sie per Pull Request. Das Projektwissen des claude.ai-Projekts wird über die GitHub-Anbindung auf `docs/` gelesen.

## 2. Schritte

| Nr | Schritt | Wo | Wer | Voraussetzung | Ergebnis |
|---|---|---|---|---|---|
| 1 | Fragen Q1–Q9 aus querschnitt-administration.md beantworten | **dieser Chat (Überblick)** | Product Owner | – | Querschnitt v0.2, Entscheidungen in offene-punkte.md |
| 2 | Repository nachziehen: aktuelle Dokumente nach `docs/` (Liste in Abschnitt 3) | Repository, per Pull Request | Product Owner (oder Claude Code mit den Dateien) | – | `docs/` auf Stand 22.10.2026 |
| 3 | Kern der Administration ab T33 umsetzen (ohne Nachträge v0.8 und v0.9) | **Claude Code** (Prompt in Abschnitt 4.1) | Claude Code, Abnahme Product Owner | 2 | Kern in TEST, Abnahme bis T49 |
| 4 | Aktivenliste sichten (Zuordnung der Lizenzbezeichnungen zu Kürzeln, Karteileichen) | offline | Product Owner | – | Grundlage für das Migrationsskript |
| 5 | Ehrenamtsmanagement: Erhebung, Stories, Spec | **neuer Chat „Ehrenamtsmanagement“** (Prompt 4.2) | Product Owner | parallel zu 3; Ergebnis aus 4 für die Migration | 01-erhebung.md, 02-stories.md, spec.md (Ready) |
| 6 | Gruppen: Annahmen bestätigen, Spec | **neuer Chat „Gruppen“** (Prompt 4.3) | Product Owner | nach 5 | spec.md Gruppen (Ready) |
| 7 | Abnahme des Kerns der Administration, Annahmen v0.6 und v0.7 bestätigen | **neuer Chat „Administration“** (Prompt 4.4) | Product Owner | 3 fertig | Spec Administration bis v0.7.1 „Fertig“ |
| 8 | Ehrenamtsmanagement umsetzen, danach Gruppen | Claude Code | Claude Code, Abnahme Product Owner | 5, 7 | Module in TEST; nach Abnahme Prüfung Regelbetrieb |
| 9 | Anwesenheitserfassung: Übergabe der Planungshilfe (v1.2) einarbeiten, Annahmen bestätigen, Spec Ready; Q1 und Q2 entschieden | Chat „Anwesenheitserfassung“ (bestehend, falls in diesem Projekt; sonst neu) | Product Owner | 6; Q1, Q2 | spec.md Anwesenheitserfassung (Ready), danach Nachtrag v0.8 der Administration umsetzen |
| 10 | Finanzen: Steckbrief, beide Übergaben (v1.5, v1.3) einarbeiten | **neuer Chat „Finanzen“** | Product Owner | Q4 geklärt; frühestens parallel zur Umsetzung der Anwesenheitserfassung | 00-steckbrief.md Finanzen |
| 11 | Planungshilfe Touren und Kurse: Priorität festlegen, Annahmen bestätigen | Chat „Planungshilfe Touren und Kurse“ (bestehend) | Product Owner | bis dahin **eingefroren** | Einordnung in die Reihenfolge |

Parallel möglich: Schritt 3 (Claude Code baut) und Schritt 5 (du erhebst das Ehrenamtsmanagement). Schritt 1 kann jederzeit dazwischen beantwortet werden; nur Q1 und Q2 müssen vor Schritt 9 entschieden sein.

Später, je eigener neuer Chat: Schnittstellen-Connector (spätestens mit Öffentlichkeitsarbeit), Öffentlichkeitsarbeit, Projekt-, Geschäftsstellen- und Aufgabenmanagement.

Offene Entscheidung, aufgeschoben: Stories für die Nachträge v0.8 und v0.9 (US-AD-27 ff.) nachziehen oder Abnahme über die Tasks. Vorschlag: Entscheidung, wenn der jeweilige Nachtrag umgesetzt wird.

## 3. Dateien für das Repository (Schritt 2)

Erledigt am 22.10.2026: Alle Dateien liegen im Repository (`docs/`, `PRODUCT.md`); seither ist das Repository die Quelle (Abschnitt 1). Die folgende Liste bleibt als Übersicht der Zuordnung.

**Für den Kern der Administration nötig:**

| Name im Projektwissen | Pfad im Repository |
|---|---|
| ad-administration_00-steckbrief.md | docs/specs/ad-administration/00-steckbrief.md |
| ad-administration_01-erhebung.md | docs/specs/ad-administration/01-erhebung.md |
| ad-administration_02-stories.md | docs/specs/ad-administration/02-stories.md |
| ad-administration_spec.md | docs/specs/ad-administration/spec.md |
| glossar.md | docs/glossar.md |
| rollen.md | docs/rollen.md |
| tech-stack.md | docs/tech-stack.md |
| vision.md | docs/vision.md |
| modul-landkarte.md | docs/modul-landkarte.md |
| offene-punkte.md | docs/offene-punkte.md |
| vorlagen.md | docs/vorlagen.md |
| ea-ehrenamt_stammdaten-qualifikationsarten.md | docs/specs/ea-ehrenamt/stammdaten-qualifikationsarten.md |
| gr-gruppen_uebergabe-nachtrag-administration.md | docs/specs/gr-gruppen/uebergabe-nachtrag-administration.md |
| claude/querschnitt-administration.md | docs/querschnitt-administration.md |
| claude/arbeitsplan.md | docs/arbeitsplan.md |

**Empfohlen gleich mit, als Entwurf (damit die Spec auflösbare Verweise hat):** alle übrigen Dateien der Module Ehrenamtsmanagement (`ea-ehrenamt_*`), Gruppen (`gr-gruppen_*`), Anwesenheitserfassung (`ez-einsaetze_*`) und Planungshilfe Touren und Kurse (`claude/tk-touren-kurse_*` → `docs/specs/tk-touren-kurse/<rest>.md`, z. B. `claude/tk-touren-kurse_spec.md` → `docs/specs/tk-touren-kurse/spec.md`), dazu `marke.md` → `docs/marke.md` und `product.md` → `PRODUCT.md`, falls geändert.

Nicht ins Repository: `umzug-kontext.md`.

## 4. Startprompts

### 4.1 Claude Code: Kern der Administration ab T33

```
Kontext: Vereins OS, Repository DAVLeipzig/vereins-os
(https://github.com/DAVLeipzig/vereins-os). Unter docs/ liegen jetzt die Dokumente
mit Stand 22.10.2026, u. a. docs/specs/ad-administration/spec.md Version 0.9,
02-stories.md, docs/rollen.md, docs/glossar.md, docs/tech-stack.md,
docs/querschnitt-administration.md und docs/arbeitsplan.md. Lies sie zuerst.

Auftrag: Setze den Kern der Administration fort, also den Nachtrag v0.7/v0.7.1
(Tasks T33–T49 der Spec) und alle noch offenen Tasks aus T1–T32, die dafür
Voraussetzung sind. Prüfe zuerst tasks.md, die Migrationen und den Code und melde
mir den Stand (erledigt / offen je Task), bevor du Code schreibst. Aktualisiere
plan.md und tasks.md mit Spec Kit.

Nicht umsetzen: Nachtrag v0.8 (T50–T58) und Nachtrag v0.9 (T59–T67).
Für den Kern gilt deshalb:
- R30: Reichweite „Referat“ nur für das Ehrenamtsmanagement (EA). EZ, TK und TKF
  ergänzen spätere Migrationen.
- ad_modules: keine Zeilen EZ, TK, TKF und keine Spalte is_hidden.
- Keine Tabellen ad_locations und ad_rates; keine Funktionen ea_person_names,
  ea_search_active_persons, ez_person_visible, tk_person_visible,
  ea_person_licenses, ad_rates_at, ad_can_edit_locations, ad_can_edit_rates,
  ad_can_read_rates.
- ea_create_volunteer und ad_find_similar_persons ohne die Erweiterungen für die
  Anwesenheitserfassung (kein p_contact_email, kein created_in = 'EZ').
- Seed nur Personen 1–12 nach Abschnitt 9; keine Personen 13–18, keine Orte,
  keine Sätze.
Wo die Spec in den Kernabschnitten Text mit „v0.8“ oder „v0.9“ markiert, gilt die
Fassung ohne diese Ergänzung.

Arbeitsweise wie bisher: je Story ein Branch und ein Pull Request, pgTAP-Tests grün,
keine Echtdaten, keine Secrets im Repository. Nenne in jedem Pull Request die
vollständige Cloudflare-Vorschau-URL des Branches. Bei Widersprüchen oder
Unklarheiten anhalten und fragen, nicht annehmen.
```

### 4.2 Neuer Chat „Ehrenamtsmanagement“

```
Wir arbeiten am Modul Ehrenamtsmanagement (EA). Lies:
ea-ehrenamt_00-steckbrief.md (v0.6), ea-ehrenamt_migration-aktivenliste.md (v0.4),
ea-ehrenamt_stammdaten-qualifikationsarten.md (v0.2),
ez-einsaetze_uebergabe-ehrenamtsmanagement.md (v1.2, offen),
den Abschnitt EA in offene-punkte.md, claude/querschnitt-administration.md,
claude/arbeitsplan.md und in ad-administration_spec.md die Abschnitte 2, 3, 5 und 7
(was die Administration für das Ehrenamtsmanagement schon festlegt).

Ziel dieses Chats: 01-erhebung.md, danach 02-stories.md und spec.md nach
vorlagen.md, so dass Claude Code ohne Rückfragen umsetzen kann. Datenmodell und
Sichtbarkeit des Personenmodells liegen in der Administration; das
Ehrenamtsmanagement baut die Oberflächen, die System-Eigenschaftsarten (u. a.
system_key birth_date, function, contact, license mit den Feldern
qualification_type und valid_until) und das Migrationsskript der Aktivenliste.

Starte mit einem Abgleich: Was aus dem Steckbrief ist durch die Spec der
Administration schon festgelegt, was ist noch offen? Danach Fragen in Blöcken von
höchstens 3, zuerst die offenen Punkte, die die Migration blockieren. Übergabe aus
der Anwesenheitserfassung einarbeiten und als erledigt markieren.
```

### 4.3 Neuer Chat „Gruppen“

```
Wir arbeiten am Modul Gruppen (GR). Lies gr-gruppen_00-steckbrief.md,
gr-gruppen_01-erhebung.md, gr-gruppen_02-stories.md (je v0.7),
gr-gruppen_uebergabe-nachtrag-administration.md, den Abschnitt GR in
offene-punkte.md, claude/querschnitt-administration.md, claude/arbeitsplan.md und
in ad-administration_spec.md die Abschnitte 2, 3 und 7 (Gruppen).

Ziel: offene Annahmen (A11, A12, Fehlertext in US-GR-19) bestätigen lassen, dann
spec.md nach vorlagen.md mit Status Ready. Prüfe zuerst alle Stories gegen die
Definition of Ready und liste die Lücken. Fragen in Blöcken von höchstens 3.
```

### 4.4 Neuer Chat „Administration“ (Abnahme des Kerns)

```
Wir arbeiten am Modul Administration (AD). Der Kern (Spec bis v0.7.1, T1–T49) ist
in TEST umgesetzt. Lies ad-administration_spec.md, ad-administration_02-stories.md,
den Abschnitt AD in offene-punkte.md, claude/querschnitt-administration.md und
claude/arbeitsplan.md. Ziel: Abnahme vorbereiten (Checkliste je Story mit den
Testzugängen), Annahmen v0.6 und v0.7 einzeln bestätigen lassen, offenen Punkt
„Weg der Migrationen nach PROD“ klären. Die Nachträge v0.8 und v0.9 bleiben Entwurf.
```

## 5. Was im Chat „Überblick“ vorbereitet wurde (22.10.2026)

- querschnitt-administration.md v0.1 (Prüffelder P1–P18, Fragen Q1–Q9)
- dieser Arbeitsplan v0.1
- offene-punkte.md v3.9 und modul-landkarte.md v2.6 mit der Entscheidung „Mittelweg“
