# Backup und Wiederherstellung (Desaster Recovery)

Stand: 29.10.2026 · Version 0.1 · Auftrag des Product Owners vom 29.10.2026 (tägliches Backup, Ablage in einer Cloud, Lebenszeichen für Supabase, Dokumentation der Wiederherstellung)

Ersetzt die Entscheidung vom 19.10.2026 „Kein eigenes Backup von PROD (Risiko akzeptiert)“ in [tech-stack.md](tech-stack.md).

## 1. Kurz gesagt

| Frage | Antwort |
|---|---|
| Was wird gesichert? | Die gesamte Datenbank von **vereins-os-prod**: Rollen, Schema und Daten (auch Zugänge in `auth.users`) |
| Wann? | Täglich um 01:17 UTC (02:17 Uhr Winterzeit, 03:17 Uhr Sommerzeit), zusätzlich jederzeit von Hand |
| Womit? | GitHub Action [`.github/workflows/backup.yml`](../.github/workflows/backup.yml) mit den Skripten in [`scripts/backup/`](../scripts/backup/) |
| Wohin? | Cloudflare R2 (S3-kompatibler Cloud-Speicher im vorhandenen Cloudflare-Konto), Bucket `vereins-os-backup` [ANNAHME] |
| Wie geschützt? | Verschlüsselt mit [age](https://age-encryption.org); den privaten Schlüssel hat nur der Product Owner (und eine Vertretung), nie GitHub oder Cloudflare |
| Wie lange? | Tagessicherungen 35 Tage, Monatssicherungen (jeweils vom 1.) 13 Monate [ANNAHME, Vorschlag; Bestätigung Product Owner] |
| Wird geprüft, ob es klappt? | Ja, jede Nacht: Die Action spielt die frische Sicherung in einen leeren lokalen Supabase-Stack im Runner ein und vergleicht die Zeilenzahlen |
| Hält es Supabase am Leben? | Ja, für PROD durch die Sicherung selbst; TEST bekommt im selben Lauf ein eigenes Lebenszeichen (Abschnitt 3) |
| Wer erfährt von Fehlern? | Issue „Backup fehlgeschlagen“ (Label `backup`) im Repository, schließt sich beim nächsten erfolgreichen Lauf |
| Wie viel Datenverlust höchstens (RPO)? | Bis zu 24 Stunden (alles seit der letzten Sicherung) |
| Wie lange bis zum Betrieb (RTO)? | Etwa ein halber Arbeitstag für die vollständige Wiederherstellung [ANNAHME, nach der ersten Probe anpassen] |

```
GitHub Action „Backup“ (täglich, nur main, Environment „backup“)
  │
  ├─ pg_dump über Session-Pooler ─────────────▶ vereins-os-prod   (= Lebenszeichen PROD)
  ├─ Abfrage + Auth-API ──────────────────────▶ vereins-os-test   (= Lebenszeichen TEST)
  │
  ├─ roles.sql, schema.sql, data.sql, manifest.tsv, info.txt
  │     └─ tar.gz ─▶ age (öffentlicher Schlüssel) ─▶ *.tar.gz.age + .sha256
  │                                                  └─▶ Cloudflare R2: daily/  (am 1. auch monthly/)
  ├─ Probe: leerer lokaler Supabase-Stack im Runner ◀─ Sicherung einspielen, Zeilenzahlen vergleichen
  └─ Ergebnis ─▶ Issue „Backup fehlgeschlagen“ öffnen / ergänzen / schließen
```

## 2. Was gesichert wird und was nicht

| Bestandteil | In der Sicherung? | Woher bei der Wiederherstellung |
|---|---|---|
| Tabellen in `public` (alle Module) mit Daten | ja | Sicherung |
| Zugänge (`auth.users`, Passwort-Hashes) | ja | Sicherung; alle melden sich danach neu an |
| Funktionen, Policies (RLS), Trigger, GRANTs | ja (schema.sql) | Sicherung |
| Zeitgesteuerte Jobs (pg_cron) | nicht sicher [ANNAHME: hängt von der Supabase-CLI ab] | nach der Wiederherstellung prüfen, fehlende aus den Migrationen anlegen (Abschnitt 6.3, Schritt 9) |
| Einträge im Vault (z. B. `sc_dispatch_secret`, API-Keys der Schnittstellen) | Inhalte sind an das Projekt gebunden und in einem neuen Projekt **nicht lesbar** | neu anlegen bzw. in der Oberfläche „Schnittstellen“ neu hinterlegen |
| Dateien in Supabase Storage | derzeit keine im Einsatz | – (wenn später genutzt: Sicherung ergänzen) |
| Auth-Einstellungen, SMTP, Mailvorlagen | nein (Dashboard) | Checkliste in [`supabase/setup/README.md`](../supabase/setup/README.md) Abschnitt 1 |
| Edge Functions, Migrationen, Frontend | nein | Git (`main`) |
| Secrets (GitHub, Cloudflare, Brevo, Google-App-Passwort) | nein | jeweilige Verwaltung; neu erzeugen, wo nötig |

## 3. Bleibt Supabase damit „am Leben“? (Ergebnis der Prüfung)

Supabase pausiert Projekte im Free-Plan nach 7 Tagen mit zu wenig „Datenbank-Aktivität“. Supabase legt nicht offen, was genau zählt.

- **PROD:** Die Sicherung meldet sich bei der Datenbank an und liest jede Tabelle (`pg_dump` in einer Transaktion, danach Zählabfragen je Tabelle). Das sind echte Abfragen, nicht nur ein Verbindungsaufbau. Dazu ruft die Action die Auth-API von PROD auf (`/auth/v1/health`), sobald die Variable `PROD_SUPABASE_URL` gesetzt ist. Damit gibt es täglich Aktivität auf beiden Wegen (Datenbank und API). **Ergebnis: PROD bleibt aktiv**, auch in Ferien ohne Nutzung durch die Geschäftsstelle.
- **TEST:** Der Job `keepalive-test` stellt täglich zwei Abfragen an TEST und ruft die Auth-API auf. TEST wird **nicht** gesichert (nur fiktive Daten). Damit entfällt das Wiederanstarten von TEST im Dashboard.
- **Selbstkontrolle:** Ist ein Projekt doch pausiert, schlägt der Lauf fehl und das Issue „Backup fehlgeschlagen“ erscheint. Dann das Projekt im Dashboard wieder starten.
- Rest-Unsicherheit: Ändert Supabase die Regeln, kann ein Projekt trotzdem pausieren. Die Selbstkontrolle meldet das spätestens am nächsten Tag; Daten gehen dabei nicht verloren.

**Wichtig – GitHub schaltet Zeitpläne ab:** In öffentlichen Repositories deaktiviert GitHub zeitgesteuerte Workflows, wenn 60 Tage lang nichts im Repository passiert (kein Push, kein Merge). Dann laufen weder Sicherung noch Lebenszeichen, und **es kommt kein Issue**. Gegenmittel: die vierteljährliche Probe (Abschnitt 7) und ein Blick auf „Actions → Backup“. Wieder einschalten: Actions → Backup → „Enable workflow“.

## 4. Einrichtung (einmalig, Product Owner)

> Claude Code richtet nichts gegen PROD ein und führt die Action nicht aus. Die Action ist der einzige automatisierte Lesezugriff auf PROD; sie läuft nur von `main`.

### 4.1 Schlüssel für die Verschlüsselung (age)

1. age installieren (Mac: `brew install age`).
2. Zwei Schlüsselpaare erzeugen, eins für den Product Owner, eins für die Vertretung (Notfall-Admin der Geschäftsstelle):

   ```sh
   age-keygen -o vereins-os-backup-po.key      # zeigt „Public key: age1…“
   age-keygen -o vereins-os-backup-gs.key
   ```

3. Die **privaten Schlüssel** (Dateien `*.key`) sicher verwahren: im Passwortmanager der Sektion **und** ausgedruckt im Tresor der Geschäftsstelle. Nie ins Repository, nie in GitHub, nie in Cloudflare, nie per E-Mail.
   **Ohne privaten Schlüssel ist keine Sicherung lesbar.**
4. Die beiden öffentlichen Schlüssel (`age1…`) kommen in die GitHub-Variable `BACKUP_AGE_RECIPIENTS` (eine Zeile je Schlüssel).

### 4.2 Cloudflare R2

1. Cloudflare-Dashboard → R2 Object Storage → R2 aktivieren (Free-Plan: 10 GB Speicher frei; die Sicherungen sind voraussichtlich wenige MB groß). Für die Aktivierung verlangt Cloudflare ggf. eine Zahlungsmethode; im Rahmen des freien Kontingents fallen keine Kosten an. [ANNAHME]
2. Bucket anlegen: Name `vereins-os-backup`, Standort **Europe (EU)** (Jurisdiction „EU“).
3. Bucket → Settings → **Object lifecycle rules**:
   - Präfix `daily/`: Objekte nach 35 Tagen löschen
   - Präfix `monthly/`: Objekte nach 400 Tagen löschen
   - Präfix `logs/`: Objekte nach 35 Tagen löschen
4. R2 → „Manage API tokens“ → „Create API token“: Berechtigung **Object Read & Write**, nur für den Bucket `vereins-os-backup`. Angezeigt werden Access Key ID, Secret Access Key und die Account ID.
5. Der Auftragsverarbeitungsvertrag mit Cloudflare (tech-stack.md Abschnitt 3) muss R2 abdecken.

### 4.3 Verbindung zu PROD und TEST

Supabase-Dashboard → Projekt → „Connect“ → **Session pooler** (IPv4; die GitHub-Runner können keine direkte IPv6-Verbindung). Format:

```
postgresql://postgres.<projekt-ref>:<datenbank-passwort>@aws-0-eu-central-1.pooler.supabase.com:5432/postgres
```

### 4.4 GitHub: Environment „backup“

GitHub → Repository → Settings → Environments → „New environment“ → Name `backup`.

1. **Deployment branches and tags:** „Selected branches and tags“ → nur `main`. So kann kein anderer Branch und kein Pull Request die Secrets lesen.
2. **Environment secrets:**

   | Name | Inhalt |
   |---|---|
   | `PROD_DB_URL` | Session-Pooler-Verbindung PROD (4.3) |
   | `TEST_DB_URL` | Session-Pooler-Verbindung TEST (4.3) |
   | `R2_ACCESS_KEY_ID` | aus 4.2 Schritt 4 |
   | `R2_SECRET_ACCESS_KEY` | aus 4.2 Schritt 4 |

3. **Environment variables** (nicht geheim):

   | Name | Inhalt |
   |---|---|
   | `BACKUP_AGE_RECIPIENTS` | öffentliche age-Schlüssel, je Zeile einer (4.1) |
   | `R2_ACCOUNT_ID` | Cloudflare Account ID |
   | `R2_BUCKET` | `vereins-os-backup` |
   | `PROD_SUPABASE_URL` | `https://<prod-ref>.supabase.co` |
   | `PROD_SUPABASE_PUBLISHABLE_KEY` | Publishable Key PROD (`sb_publishable_…`, steht ohnehin im Frontend) |
   | `TEST_SUPABASE_URL` | `https://<test-ref>.supabase.co` |
   | `TEST_SUPABASE_PUBLISHABLE_KEY` | Publishable Key TEST |

### 4.5 Erster Lauf

1. GitHub → Actions → „Backup“ → „Run workflow“ (Branch `main`).
2. Alle drei Jobs grün? In der Zusammenfassung stehen „Abgelegt: daily/…“ und „Probe-Wiederherstellung erfolgreich“.
3. In R2 liegt `daily/vereins-os-prod_<Datum>.tar.gz.age` mit `.sha256`.
4. Gleich danach die erste Probe nach Abschnitt 7 machen: Nur so ist sicher, dass der private Schlüssel passt.

## 5. Überwachung

- **Issue „Backup fehlgeschlagen“** (Label `backup`): legt die Action bei einem Fehler an bzw. ergänzt es um eine Zeile je Tag; beim nächsten erfolgreichen Lauf schließt sie es. Wer das Repository beobachtet („Watch“), bekommt eine E-Mail. Empfehlung: Product Owner und Notfall-Admin beobachten das Repository mindestens für Issues.
- **Ursachen und Abhilfe:**

  | Meldung im Lauf | Ursache | Abhilfe |
  |---|---|---|
  | „Im Environment „backup“ fehlt …“ | Secret oder Variable fehlt | Abschnitt 4.4 |
  | Verbindungsfehler bei „Sicherung erstellen“ | PROD pausiert, Passwort geändert, Supabase gestört | Dashboard prüfen; nach Passwortwechsel `PROD_DB_URL` erneuern |
  | Fehler bei „In Cloudflare R2 ablegen“ | Token abgelaufen oder gelöscht, Bucket voll | Token neu erzeugen (4.2), Secrets erneuern |
  | Fehler bei „Probe-Wiederherstellung“ | Sicherung lässt sich nicht einspielen (z. B. neue Supabase-Version) | Die Sicherung liegt trotzdem in R2. Protokoll `logs/…_restore-check.log.age` aus R2 laden, entschlüsseln (7.), Ursache klären. Im öffentlichen Log stehen absichtlich keine Werte. |
  | Fehler bei „Lebenszeichen TEST“ | TEST pausiert oder `TEST_DB_URL` falsch | TEST im Dashboard starten, Secret prüfen |

- **Keine Läufe mehr?** Siehe Hinweis zur 60-Tage-Regel in Abschnitt 3.
- Ein roter Lauf wird nicht einfach neu gestartet, sondern erst die Ursache geklärt.

## 6. Desaster Recovery

### 6.1 Grundsätze

- **Echtdaten nie in TEST.** Eine Sicherung wird nur in ein **neues, leeres** Supabase-Projekt oder in einen lokalen Stack auf dem Rechner des Product Owners eingespielt. `scripts/backup/restore.sh` bricht ab, wenn das Ziel schon Tabellen in `public` hat.
- **Nicht über PROD drüberspielen.** Ist PROD noch erreichbar, bleibt es unverändert, bis das neue Projekt geprüft ist (Rückweg).
- Wiederherstellen dürfen nur der Product Owner oder die Vertretung mit privatem Schlüssel.
- Alles, was nach der Sicherung geändert wurde (bis zu 24 Stunden), ist verloren und muss aus Belegen, E-Mails usw. nachgetragen werden.
- **Löschungen nachziehen:** Hat jemand nach dem Datum der Sicherung Daten löschen lassen (Löschfristen, Auskunfts- oder Löschverlangen nach DSGVO), diese Löschungen nach der Wiederherstellung erneut ausführen.
- Datenpanne prüfen: Bei Verlust, Zerstörung oder unbefugtem Zugriff auf Personendaten muss die Sektion prüfen, ob eine Meldung an die Aufsichtsbehörde nötig ist (Art. 33 DSGVO, binnen 72 Stunden). Zuständig: Toni Werner (Datenschutz).

### 6.2 Welches Szenario?

| Szenario | Vorgehen |
|---|---|
| **A. Einzelne Datensätze** versehentlich gelöscht oder falsch geändert | Sicherung **lokal** einspielen (Abschnitt 7), die betroffenen Werte nachsehen und in PROD über die Oberfläche wieder eintragen. Kein Einspielen in PROD. |
| **B. Daten in PROD großflächig zerstört** (Projekt läuft noch) | Vollständige Wiederherstellung in ein neues Projekt (6.3), danach umschalten. PROD bis zur Abnahme stehen lassen. |
| **C. PROD weg** (Projekt gelöscht, Konto gesperrt, Supabase-Region dauerhaft ausgefallen) | Vollständige Wiederherstellung (6.3); bei gesperrtem Konto zuerst ein neues Supabase-Konto der Sektion anlegen. |
| **D. Supabase kurzzeitig gestört** | Abwarten (status.supabase.com). Keine Wiederherstellung. |
| **E. Cloudflare-Konto oder Bucket weg** | PROD läuft weiter. Neuen Bucket anlegen (4.2), Secrets erneuern, Lauf von Hand starten. Ältere Sicherungen sind verloren, wenn es keine Kopie gibt (Empfehlung: monatlich eine Sicherung zusätzlich im Sektions-Speicher ablegen). |
| **F. Privater age-Schlüssel verloren** | Die Sicherungen sind unlesbar. Sofort neues Schlüsselpaar erzeugen (4.1), `BACKUP_AGE_RECIPIENTS` ersetzen, Lauf von Hand starten. Ist ein privater Schlüssel in falsche Hände geraten: zusätzlich alle Sicherungen in R2 löschen. |
| **G. R2-Token oder Datenbank-Passwort kompromittiert** | Token in Cloudflare widerrufen bzw. Datenbank-Passwort in Supabase zurücksetzen, Secrets erneuern. Die Sicherungen bleiben verschlüsselt. |

### 6.3 Vollständige Wiederherstellung (Szenario B und C)

Voraussetzungen auf dem Rechner: `age`, `psql` ab Version 17 (Mac: `brew install age libpq`), Zugang zu Cloudflare, Supabase und GitHub, ein privater age-Schlüssel, ein Checkout dieses Repositorys.

1. **Platz schaffen.** Der Free-Plan erlaubt nur zwei aktive Projekte. Bei Szenario B (PROD läuft noch) zuerst **vereins-os-test pausieren** (Dashboard → Project Settings → General → „Pause project“). TEST wird später wieder gestartet.
2. **Neues Projekt anlegen:** Name `vereins-os-prod-2`, Region **Frankfurt (eu-central-1)**, starkes Datenbank-Passwort in den Passwortmanager. Postgres-Version wie in `info.txt` der Sicherung (`server_version_num`, z. B. 170004 = 17).
3. **Sicherung holen:** Cloudflare → R2 → `vereins-os-backup` → `daily/` → jüngste brauchbare Datei (vor dem Schaden!) und ihre `.sha256` herunterladen.
4. **Prüfen und entschlüsseln:**

   ```sh
   shasum -a 256 -c vereins-os-prod_<Datum>.tar.gz.age.sha256
   age -d -i vereins-os-backup-po.key vereins-os-prod_<Datum>.tar.gz.age | tar -xzf -
   ```

   Ergebnis: Ordner `vereins-os-prod_<Datum>/` mit `roles.sql`, `schema.sql`, `data.sql`, `manifest.tsv`, `info.txt`. Der Ordner enthält Echtdaten: nur auf dem eigenen, verschlüsselten Rechner, am Ende löschen.
5. **Einspielen** (Verbindung des neuen Projekts: „Connect“ → Session pooler):

   ```sh
   RESTORE_DB_URL='postgresql://postgres.<neue-ref>:<passwort>@aws-0-eu-central-1.pooler.supabase.com:5432/postgres' \
     scripts/backup/restore.sh vereins-os-prod_<Datum>
   ```

   Das Skript fragt nach und spielt alles in **einer** Transaktion ein: Bei einem Fehler bleibt das Projekt leer und der Schritt kann nach der Korrektur wiederholt werden.
6. **Vergleichen:**

   ```sh
   VERIFY_DB_URL='<wie oben>' scripts/backup/verify.sh vereins-os-prod_<Datum>/manifest.tsv
   ```

   Erwartet: „0 Fehler“. Kleine Abweichungen sind möglich (Zählung und Sicherung laufen nacheinander).
7. **Auth-Einstellungen** im Dashboard des neuen Projekts nach [`supabase/setup/README.md`](../supabase/setup/README.md) Abschnitt 1 (Punkte 1–9, inkl. SMTP mit App-Passwort und Mailvorlagen).
8. **Edge Functions bereitstellen** wie in `supabase/setup/README.md` Abschnitt 2a Schritt 1 (z. B. `supabase functions deploy sc-send --no-verify-jwt --project-ref <neue-ref>`).
9. **Zeitgesteuerte Jobs prüfen** (SQL-Editor des neuen Projekts):

   ```sql
   select jobname, schedule from cron.job order by jobname;
   ```

   Fehlen Jobs, die betreffenden `cron.schedule(…)`-Aufrufe aus `supabase/migrations/` im SQL-Editor ausführen (Suche: `grep -rn "cron.schedule" supabase/migrations`).
10. **Vault neu befüllen:** alte Einträge löschen und neu anlegen (Werte sind im neuen Projekt nicht lesbar):

    ```sql
    delete from vault.secrets where name in ('sc_dispatch_url', 'sc_dispatch_secret', 'sc_app_url');
    ```

    Danach die drei Einträge wie in `supabase/setup/README.md` Abschnitt 2a Schritt 2 mit der **neuen** Projektadresse anlegen. Die API-Keys der Schnittstellen (Brevo) in der Oberfläche „Schnittstellen“ über „Key wechseln“ neu hinterlegen.
11. **Frontend umschalten:** Cloudflare → Workers → `vereins-os` → Settings → Variables and Secrets (Build): `VITE_SUPABASE_URL` und `VITE_SUPABASE_ANON_KEY` (Publishable Key) des neuen Projekts eintragen, dann den letzten Build von `main` neu ausführen („Retry build“).
12. **GitHub anpassen:** im Environment `backup` `PROD_DB_URL`, `PROD_SUPABASE_URL` und `PROD_SUPABASE_PUBLISHABLE_KEY` auf das neue Projekt setzen; einen Lauf „Backup“ von Hand starten.
13. **Abnahme:** mit dem eigenen Zugang anmelden (Passwort wie vorher), Stichproben in allen Modulen, Test-E-Mail unter „Schnittstellen“ senden, „Passwort vergessen“ testen.
14. **Nutzer:innen informieren:** Alle müssen sich neu anmelden; Änderungen seit dem Datum der Sicherung bitte nachtragen. Löschungen seit dem Datum der Sicherung nachziehen (6.1).
15. **Aufräumen:** Ordner und entschlüsselte Dateien auf dem Rechner löschen. Das alte PROD-Projekt erst nach einigen Tagen stabilem Betrieb löschen; danach das neue Projekt bei Bedarf umbenennen und TEST wieder starten.
16. **Nachbereitung:** kurzer Bericht (was, wann, Datenverlust, Ursache) an den Vorstand; diese Anleitung anpassen, wo etwas nicht gepasst hat.

## 7. Probe-Wiederherstellung (vierteljährlich, Product Owner)

Die Action probt jede Nacht das Einspielen, aber **nicht** das Entschlüsseln: den privaten Schlüssel hat sie nicht. Deshalb einmal im Quartal (Januar, April, Juli, Oktober) und nach jeder Änderung an den Schlüsseln:

1. Jüngste Sicherung aus R2 laden, prüfen und entschlüsseln (6.3 Schritt 3–4), einmal mit jedem der beiden Schlüssel.
2. Einspielen in einen lokalen Stack (Docker Desktop nötig), ohne TEST oder PROD zu berühren:

   ```sh
   scripts/backup/restore-check.sh vereins-os-prod_<Datum> restore-check.log
   ```

   Erwartet: „Probe-Wiederherstellung erfolgreich.“ Für Szenario A danach selbst in den lokalen Stack schauen: Statt `restore-check.sh` einen lokalen Stack mit `supabase start` in einem leeren Ordner starten, `restore.sh` mit dessen `DB_URL` aufrufen und im lokalen Studio (http://localhost:54323) nachsehen.
3. Prüfen, ob die Action in den letzten Tagen gelaufen ist (Actions → Backup) und ob in R2 Tages- und Monatssicherungen liegen.
4. Entschlüsselte Dateien und `restore-check.log` löschen.
5. Ergebnis mit Datum in der Tabelle unten eintragen (Pull Request).

| Datum | Wer | Sicherung vom | Ergebnis |
|---|---|---|---|
| – | – | – | erste Probe nach der Einrichtung |

## 8. Datenschutz

- Die Sicherungen enthalten Personendaten (Echtdaten). Sie liegen nur verschlüsselt in R2; unverschlüsselt existieren sie nur kurz im GitHub-Runner (wird nach dem Lauf verworfen) und bei einer Wiederherstellung auf dem Rechner des Product Owners.
- Die Logs der Action sind öffentlich. Die Skripte geben deshalb keine Inhalte und keine Zeilenzahlen aus; Fehlermeldungen werden ohne Werte gezeigt, das volle Protokoll liegt nur verschlüsselt in R2.
- Aufbewahrung: Gelöschte Daten bleiben bis zu 35 Tage in Tagessicherungen und bis zu 13 Monate in Monatssicherungen erhalten. Das gehört in den Eintrag im Verarbeitungsverzeichnis und ist bei Löschverlangen zu erwähnen.
- Auftragsverarbeiter: Cloudflare (R2, Speicherort EU) und GitHub (Ausführung der Action). GitHub sieht die Daten nur unverschlüsselt im Runner während des Laufs.

## 9. Offene Punkte

- [OFFEN] Aufbewahrungsfristen (35 Tage / 13 Monate) bestätigen; Quelle: diese Datei, Abschnitt 1.
- [OFFEN] Speicherort Cloudflare R2 bestätigen (Alternative: anderer S3-kompatibler Speicher; die Action braucht dann nur einen anderen Endpunkt); Quelle: diese Datei, Abschnitt 4.2.
- [OFFEN] Zusätzliche Kopie außerhalb von Cloudflare (z. B. monatlich von Hand in den Speicher der Sektion) gewünscht? Quelle: diese Datei, Abschnitt 6.2, Szenario E.
