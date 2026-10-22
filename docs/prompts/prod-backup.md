# Prompt für Claude Code: Tägliches Backup von PROD

Stand: 21.10.2026 · Version 0.1 · Ändert Entscheidung „kein Backup von PROD“ (tech-stack.md, 19.10.2026)

---

## Kontext

Vereins OS läuft auf Supabase Free-Plan. Für Free-Projekte gibt es keine nutzbaren Backups durch Supabase. PROD (`vereins-os-prod`) enthält ab dem Modul Gruppen Verträge, Bankverbindungen und Daten Minderjähriger. Datenverlust wäre nicht wiederherstellbar.

Lies vor Beginn: `CLAUDE.md`, `docs/tech-stack.md`, `docs/rollen.md`. Arbeite auf einem eigenen Branch, Änderungen nur per Pull Request.

## Ziel

Ein täglicher, automatischer Dump der PROD-Datenbank auf dem Rechner des Product Owners, verschlüsselt abgelegt in einem Ordner, der von seinem Cloud-Laufwerk synchronisiert wird. Wiederherstellung ist dokumentiert und lokal getestet.

## Entscheidungen

- **Kein GitHub Action.** Das Repository ist öffentlich; Dumps, Logs oder Artefakte mit Echtdaten dürfen nie über GitHub laufen.
- **Ausführung lokal** auf dem Rechner des Product Owners per Betriebssystem-Scheduler (macOS: launchd; Windows: Aufgabenplanung). Betriebssystem: [OFFEN → vom Product Owner angeben].
- **Häufigkeit:** täglich; ein verpasster Lauf (Rechner aus) wird beim nächsten Start nachgeholt.
- **Werkzeug:** `supabase db dump` gemäß aktueller Supabase-Dokumentation „Backup and restore using CLI“ (Rollen, Schema, Daten als getrennte Dateien). Prüfe vorab, ob Docker benötigt wird; falls ja, Fallback mit `pg_dump` in passender Postgres-Version dokumentieren.
- **Verschlüsselung:** `age` mit Schlüsselpaar. Öffentlicher Schlüssel liegt im Skript-Ordner bzw. in der Konfiguration; der private Schlüssel liegt nicht im Cloud-Laufwerk und nicht im Repo (Product Owner verwahrt ihn, z. B. im Passwortmanager). [ANNAHME]
- **Aufbewahrung:** 30 Tage; ältere Dumps löscht das Skript selbst. [ANNAHME] Grund: Backups dürfen die 5-Jahres-Löschung nicht dauerhaft unterlaufen.
- **Zugang zur Datenbank:** eigene Postgres-Rolle `backup_reader` nur mit Leserechten auf die zu sichernden Schemas, per Migration angelegt (ohne Passwort im Repo). Das Passwort setzt der Product Owner manuell; die Verbindungszeichenfolge liegt lokal außerhalb des Repos (Schlüsselbund bzw. Anmeldeinformationsverwaltung des Betriebssystems, notfalls `.env` außerhalb des Repos mit Leserechten nur für den Nutzer). Prüfe, ob die Rolle für einen vollständigen Dump (inkl. `auth`-Schema) ausreicht; falls nicht, Alternative mit Begründung vorschlagen und auf Freigabe warten.
- **Nur PROD.** TEST enthält nur fiktive Daten und wird nicht gesichert.

## Anforderungen

R1: Wenn der Job läuft, dann erzeugt er Rollen-, Schema- und Datendump von PROD, verschlüsselt jede Datei mit `age` und legt sie im Zielordner unter `vereins-os-prod/JJJJ-MM-TT/` ab.
R2: Unverschlüsselte Dateien existieren nur in einem temporären Ordner und werden nach dem Verschlüsseln gelöscht – auch bei Abbruch (trap/finally).
R3: Wenn ein Schritt fehlschlägt, dann wird kein unvollständiger Tagesordner hinterlassen und ein Eintrag ins lokale Log geschrieben; der Product Owner erhält eine lokale Systembenachrichtigung.
R4: Das Log enthält Zeitpunkt, Ergebnis und Dateigrößen, nie Verbindungsdaten oder Inhalte.
R5: Dumps älter als 30 Tage werden nach einem erfolgreichen Lauf gelöscht; nie, wenn der aktuelle Lauf fehlgeschlagen ist.
R6: Das Skript bricht ab, wenn die Verbindung nicht auf das PROD-Projekt zeigt (Projekt-Referenz prüfen), damit nicht versehentlich TEST oder ein anderes Projekt gesichert wird.
R7: Zielordner, Projekt-Referenz und Pfad des öffentlichen Schlüssels sind konfigurierbar (Konfigurationsdatei außerhalb des Repos oder Umgebungsvariablen); im Repo liegt nur eine Beispieldatei ohne echte Werte.

## Wiederherstellung

- Schreibe `docs/runbooks/prod-restore.md`: entschlüsseln, in einen **lokalen** Supabase-Stack (`supabase start`) einspielen, prüfen.
- Echtdaten nie in Supabase TEST einspielen.
- Ein Skript für den Restore-Test in den lokalen Stack; danach lokalen Stack zurücksetzen und entschlüsselte Dateien löschen.
- Wiederherstellung in PROD nur manuell durch den Product Owner nach Runbook.

## Ablage im Repo

```
scripts/backup/
├── backup-prod.sh (bzw. .ps1 für Windows)
├── restore-local.sh
├── config.example.env
└── README.md            Einrichtung Scheduler, Schlüssel, Rolle
docs/runbooks/prod-restore.md
supabase/migrations/<timestamp>_backup_reader_role.sql
```

`.gitignore` ergänzen: `*.sql.age`, `*.dump`, `backups/`, `config.env`.

## Akzeptanzkriterien

- AK1: Gegeben Rechner an und PROD erreichbar, wenn der Scheduler auslöst, dann liegen im Zielordner drei verschlüsselte Dateien des Tages und keine unverschlüsselte Datei.
- AK2: Gegeben Rechner war zur geplanten Zeit aus, wenn er wieder läuft, dann wird der Lauf nachgeholt.
- AK3: Gegeben falsches Passwort oder PROD nicht erreichbar, wenn der Job läuft, dann bleibt kein Tagesordner zurück, das Log enthält den Fehler ohne Zugangsdaten, und eine Systembenachrichtigung erscheint.
- AK4: Gegeben Konfiguration zeigt auf TEST, wenn der Job läuft, dann bricht er vor dem Dump ab (R6).
- AK5: Gegeben Dumps älter als 30 Tage, wenn ein Lauf erfolgreich ist, dann sind sie gelöscht; bei fehlgeschlagenem Lauf bleiben sie erhalten.
- AK6: Gegeben ein verschlüsselter Dump und der private Schlüssel, wenn das Restore-Skript läuft, dann ist die Datenbank im lokalen Stack vollständig (Stichprobe: Anzahl Zeilen je Tabelle wie in PROD).
- AK7: Im Repo, in Commits und in GitHub-Logs finden sich keine Zugangsdaten, Schlüssel oder Dumps.

## Nicht Teil dieser Aufgabe

- Sicherung von Supabase Storage (wird derzeit nicht genutzt [ANNAHME]).
- Sicherung von Edge Functions und Konfiguration (liegen als Code im Repo).
- Backup von TEST.
- Automatische Wiederherstellung in PROD.
- Wechsel auf den Pro-Plan.

## Vor dem Start vom Product Owner zu klären

- [OFFEN] Betriebssystem des Rechners.
- [OFFEN] Cloud-Laufwerk und Zielordner.
- [OFFEN] Aufbewahrung 30 Tage bestätigen.

## Nach Umsetzung

- `docs/tech-stack.md`, Abschnitt „Backups“ und „Entscheidungen“: neue Entscheidung eintragen (lokales, verschlüsseltes Backup; Aufbewahrung; Restore nur lokal).
- Verarbeitungsverzeichnis: Speicherort der Backups ergänzen.
