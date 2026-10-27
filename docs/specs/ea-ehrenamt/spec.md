# Spec: Ehrenamtsmanagement (EA)

Version: 0.2.3 · Status: Ready · Stand: 27.10.2026 · Product Owner: Toni Werner
Stories: docs/specs/ea-ehrenamt/02-stories.md (US-EA-01 bis US-EA-19, v0.1)
Grundlage: 00-steckbrief.md v0.7, 01-erhebung.md v0.5 (Regeln R1–R17, Daten C2–C4 – **verbindlich**), migration-aktivenliste.md v0.5, stammdaten-qualifikationsarten.md v0.2, specs/ad-administration/spec.md v0.9 (Kern bis v0.7.1), uebergabe-administration.md v1.1 (Ü1–Ü3), glossar.md v1.5, tech-stack.md v0.6
Änderungen v0.2.3 (Entscheidung Product Owner 27.10.2026): Filter „Qualifikation“ in /ea/aktive zeigt nur aktuell vergebene Qualifikationsarten (Abschnitt 6).
Änderungen v0.2.2 (Entscheidung Product Owner 27.10.2026): Übersicht /ea/aktive zeigt in der Spalte „Ablauf“ unter dem Badge, welche Eigenschaften abgelaufen sind oder bald ablaufen; bei Trainer:innen ohne gültige Lizenz ersetzt das Kennzeichen mit der abgelaufenen Lizenz das Ablauf-Badge, damit derselbe Sachverhalt nicht doppelt steht (Abschnitt 6). Filter unverändert.
Änderungen v0.2.1 (Entscheidungen Product Owner 23.10.2026, plan.md O1–O3): Schlüssel des Migrationsskripts nur verdeckt im Terminal eingeben, nie in einer Datei (Abschnitt 7, Constitution Prinzip III); Probelauf und Lauf führt der Admin aus; Knopf „Verlängern“ nur bei Qualifikationsarten mit Status „aktuell“ (Abschnitt 6); Fehlercodes `EA_CREATE_FORBIDDEN` und `EA_CREATE_REFERAT_REQUIRED` beim Anlegen (Abschnitt 5).
Änderungen v0.2: Freigabe durch den Product Owner (22.10.2026), Status Ready; Annahmen in Abschnitt 11 bestätigt; Ü1 und Ü2 gelten nach uebergabe-administration.md als verbindliche Ergänzung des Kerns der Administration.
Änderungen v0.1: Ersterstellung.

**Voraussetzungen der Umsetzung:**
- Kern der Administration umgesetzt (spec.md AD T1–T49), inklusive Ü1 (`ea_property_types.valid_from_label`, `valid_to_label`) und Ü2 (`birth_year` in `ad_find_similar_persons` nur für Geschäftsstelle und Admin). Ü1 und Ü2 sind in uebergabe-administration.md verbindlich beschrieben, auch solange spec.md AD sie noch nicht enthält; sind sie noch nicht umgesetzt, werden sie als erste Tasks (T0a, T0b) per neuer Migration der Administration umgesetzt.
- Nachträge v0.8 und v0.9 der Administration sind **nicht** Voraussetzung. Das Ehrenamtsmanagement legt die Schlüssel `function`, `contact`, `license` so an, dass sie später passen.
- Regeln „R… AD“ verweisen auf spec.md AD Abschnitt 5; „R…“ ohne Zusatz auf 01-erhebung.md Abschnitt D (hier in Abschnitt 5 wiederholt).

## 1. Ziel und Scope

**Ziel:** Geschäftsstelle, Admin und Referent:innen führen die Aktiven der Sektion im Vereins OS statt in der Excel-Liste. Erfolg: die ca. 130 Trainer:innen der Aktivenliste sind per Skript migriert; Aktive sind über Tabelle und Filter auffindbar; Ablauf von Qualifikationen ist markiert und als Stichtagsliste abrufbar; die Referate haben das Modul abgenommen.

**Im Scope:**
- Startbestand der 25 System-Eigenschaftsarten (C2, C2a) und 10 zusätzlicher Qualifikationsarten (C4) per Migration.
- Übersicht der Aktiven mit Suche, Filtern, Paginierung; Detailansicht nach Kategorie mit Historie.
- Person anlegen mit erster Zuordnung und Dublettendialog (Wieder aktivieren, Übernehmen).
- Eigenschaften hinzufügen, ändern, beenden; Lizenz und Qualifikation mit Vorbelegung „gültig bis“ und Verlängern; IBAN-Prüfung.
- Ehrenamtsstatus ändern; Ausscheiden mit Beenden von Zuordnungen und Hinweisen.
- Ablaufstatus (Qualifikationen, Führungszeugnis-Einsicht, Trainer:in ohne gültige Lizenz); Stichtagsliste mit CSV-Export.
- Gremium-Sichten; Pflege von Referaten und Gremien; Einhängen der Seiten Eigenschaftsarten und Qualifikationsarten der Administration.
- Migrationsskript der Aktivenliste (bereinigte CSV, Probelauf, Lauf) mit Datenbankfunktion `ea_import_volunteers`.
- Seed-Umstellung auf System-Eigenschaftsarten (Ü3) und Testpersonen 19–22.
- Freischalten des Moduls (`ad_modules.is_available`).

**Nicht im Scope:** Datenmodell, RLS und Funktionen des Personenmodells (Administration); Löschen von Personen und Eigenschaften; Ehrenamtsstatus je Referat; Einsatzhistorie (Iteration 2, Modul Anwesenheitserfassung); E-Mails vor Ablauf und Geburtstagserinnerung (Schnittstellen-Connector, nach MVP); Dashboard; Import-Oberfläche, Zusammenführen; Filter über frei angelegte Felder; konfigurierbare Ablaufregeln; Ablaufmarkierung der DOSB-Lizenz; Regelwerk Führungszeugnis-Einsicht; Karteileichen; Migration weiterer Listen (Skript wiederverwendbar, nach MVP); Pflege von Gruppen-Funktionen (Gruppen); Dokumentablage; Verpflichtungserklärung zum Datenschutz.

## 2. Datenmodell

Das Ehrenamtsmanagement legt **keine neuen Tabellen** an. Es nutzt die Tabellen der Administration (`ea_persons`, `ea_volunteer_status_history`, `ea_referate`, `ea_gremien`, `ea_property_types`, `ea_property_fields`, `ea_properties`, `ea_property_history`, `ad_qualification_types`) und ergänzt Stammdaten, eine View, Funktionen und einen Trigger. Migrationen mit Präfix im Dateinamen `…_ea_*.sql`.

Begriffe in dieser Spec:
- **aktuell** (Eigenschaft): `valid_from <= current_date and (valid_to is null or valid_to >= current_date)`.
- **Aktive:r**: Mensch mit `volunteer_status in ('active','dormant')`.

### 2.1 System-Eigenschaftsarten (Migration, Daten)

Verbindlich ist 01-erhebung.md C2 (Nr. 1–25: Name, `system_key`, Kategorie, Lesestufe, Bezug, mehrfach, Felder mit Schlüssel, Bezeichnung, Typ, Pflicht, Auswahlwerten, Zweck) und C2a (Bezeichnungen „gültig von/bis“). Abbildung:

| Erhebung | Spalte |
|---|---|
| Name | `ea_property_types.name` |
| Zweck | `purpose` |
| Kategorie Stammdaten / Kontakt / Zuordnung / Qualifikationen / Nachweise / Jahreseinträge / Ausgaben / Zugänge / Sonstiges | `category` = `master_data` / `contact` / `assignment` / `qualification` / `proof` / `yearly` / `issue` / `external_access` / `other` |
| Lesestufe alle / GST / vertr. | `read_level` = `all` / `office` / `confidential` |
| Bezug – / Referat / Gremium; „(Pflicht)“ | `relation_kind` = `none` / `referat` / `gremium`; `relation_required` = true nur bei „(Pflicht)“ |
| mehrfach ja / nein | `allow_multiple` |
| Bezeichnungen C2a | `valid_from_label`, `valid_to_label` („–“ = null) |
| Felder | je Feld eine Zeile `ea_property_fields` (`key`, `label`, `data_type`, `is_required`, `choice_values`, `allowed_qualification_kinds`, `sort_order` in der Reihenfolge der Erhebung) |

Datentypen der Felder: Text → `text`, Zahl → `number`, Datum → `date`, Jahr → `year`, Ja/Nein → `boolean`, Auswahl → `choice`, Qualifikationsart → `qualification_type`. `allowed_qualification_kinds`: Nr. 9 `license.qualification_type` = `{license}`; Nr. 10 `qualification.qualification_type` = `{add_on,course,training}`; Nr. 11 `further_training.qualification_type` = `{license}`.

Weitere Werte: `origin = 'system'`; `visible_in` = `{AD,EA}`, zusätzlich `GR` bei `member`, `birth_date`, `contact`; Nr. 24 `employment` nur `{AD}`.

Migration `…_ea_system_property_types.sql`:
- läuft ohne Nutzerkontext; schreibt direkt in `ea_property_types` und `ea_property_fields` (Trigger der Administration erlauben `confidential` und `system_key` ohne Nutzerkontext).
- idempotent: `insert … on conflict (system_key) do nothing`; Felder nur für neu angelegte Arten.
- Abbruch mit `raise exception 'Eigenschaftsart % existiert bereits ohne system_key.'`, wenn eine Art gleichen Namens (ohne Groß-/Kleinschreibung) ohne `system_key` existiert (A7).

### 2.2 Qualifikationsarten (Migration, Daten)

Migration `…_ea_qualification_types.sql`: die 10 Einträge aus 01-erhebung.md C4 in `ad_qualification_types` (`discipline` „Allgemein“ bzw. „Jugend und Familie“; `kind` `training` bzw. `course`; `validity_years` 2 bzw. null; `issuer` „extern“ bzw. „Bundesverband (JDAV)“; `status = 'current'`; `source_ref` null). Kürzel und Bezeichnungen der Aufbaumodule: AMAK „JDAV-Aufbaumodul Alpinklettern“, AMBS „… Bergsteigen“, AMHT „… Hochtouren“, AMKS „… Klettersteig“, AMMB „… Mountainbike“, AMSB „… Skibergsteigen“, AMSH „… Skihochtouren“, AMSK „… Sportklettern“. Idempotent über `lower(name)`, ohne Überschreiben.

### 2.3 Funktionen und View

Alle Funktionen mit festem `search_path = public`, Grant `execute` nur an `authenticated` (Ausnahme `ea_import_volunteers`: nur `service_role`).

**`ea_expiry_status(p_valid_until date, p_today date default current_date) returns text`** – immutable: `'none'` bei null; `'expired'` wenn `p_valid_until < p_today`; `'expiring'` wenn `p_valid_until <= p_today + interval '3 months'`; sonst `'valid'` (R9).

**`ea_default_valid_until(p_qualification_type uuid, p_valid_from date, p_last_training date default null) returns date`** – stable, security invoker: `make_date(extract(year from coalesce(p_last_training, p_valid_from))::int + validity_years, 12, 31)`; null, wenn die Qualifikationsart keine Gültigkeitsdauer hat (R5).

**`ea_iban_normalize(p_iban text) returns text`** und **`ea_iban_valid(p_iban text) returns boolean`** – immutable: Leerzeichen entfernen, Großbuchstaben; gültig, wenn `^[A-Z]{2}[0-9]{2}[A-Z0-9]{11,30}$` und Prüfsumme nach ISO 13616 (mod 97 = 1) (R13).

**Trigger `ea_properties_iban`** (before insert or update on `ea_properties`; Name so gewählt, dass er vor `ea_properties_validate` läuft): nur wenn die Eigenschaftsart `system_key = 'bank_account'` hat und `field_values ? 'iban'`: setzt `field_values.iban = ea_iban_normalize(...)`; ist sie ungültig → Fehler `EA_IBAN_INVALID`.

**View `ea_v_expiry`** (`security_invoker = true`, RLS der Administration gilt): eine Zeile je aktueller Eigenschaft von Aktiven mit Ablaufdatum:

| Spalte | Herkunft |
|---|---|
| `person_id`, `property_id`, `property_type_id`, `system_key` | Eigenschaft |
| `kind` | `license` / `qualification` / `police_clearance` |
| `qualification_type_id`, `qualification_code`, `qualification_name`, `discipline` | aus `field_values->>'qualification_type'` (bei `police_clearance` null) |
| `valid_until` | `(field_values->>'valid_until')::date`; bei `police_clearance`: `(field_values->>'issued_on')::date + interval '3 years'` (R10) |
| `expiry_status` | `ea_expiry_status(valid_until)` |

Einbezogen: Arten mit `system_key in ('license','qualification','police_clearance')`. Zeilen ohne `valid_until` erscheinen mit `expiry_status = 'none'`.

**`ea_volunteer_list(...) returns table`** – stable, security invoker (RLS entscheidet über Personen und Eigenschaften):

Parameter (alle optional): `p_search text`, `p_status ea_volunteer_status[] default '{active,dormant}'`, `p_referate uuid[]`, `p_function text`, `p_position text`, `p_gremium uuid`, `p_qualification_type uuid`, `p_discipline text`, `p_expiry text[]` (Werte aus `ea_expiry_status`), `p_trainer_without_license boolean default false`, `p_without_assignment boolean default false`, `p_limit int default 50` (1–200), `p_offset int default 0`.

Rückgabe je Person: `id`, `first_name`, `preferred_name`, `last_name`, `volunteer_status`, `volunteer_status_since`, `referate text[]` (Namen der Referate aus aktuellen `function`/`position`, sortiert nach `sort_order`), `functions text[]`, `positions text[]` (Werte, unterschieden nach Referat z. B. „Trainer:in – Klettern“), `license_codes text[]`, `worst_expiry text` (schlechtester Wert aus `ea_v_expiry`: expired > expiring > valid > none), `trainer_without_license boolean` (R14), `total_count bigint` (`count(*) over ()`).

Logik:
- Basis: `ea_persons` mit `kind = 'human'` und `volunteer_status = any(p_status)`.
- `p_search`: getrimmt; Teilwort ohne Groß-/Kleinschreibung in `first_name`, `preferred_name` oder `last_name`.
- `p_referate`: Person hat aktuelle `function`- oder `position`-Eigenschaft mit `related_referat_id = any(p_referate)`.
- `p_function` / `p_position`: aktuelle Eigenschaft mit `field_values->>'function'` bzw. `->>'position'` gleich Wert (in Kombination mit `p_referate` dieselbe Eigenschaft).
- `p_gremium`: aktuelle `committee`-Eigenschaft mit `related_gremium_id = p_gremium`.
- `p_qualification_type` / `p_discipline`: Zeile in `ea_v_expiry` mit passender Qualifikationsart bzw. Sparte.
- `p_expiry`: `worst_expiry = any(p_expiry)`.
- `trainer_without_license`: aktuelle `function` mit Wert „Trainer:in“ und keine Zeile in `ea_v_expiry` mit `kind = 'license'` und `valid_until >= current_date`.
- `p_without_assignment`: Status `active` und keine aktuelle `function`, `position` oder `committee`.
- Sortierung: `lower(last_name)`, `lower(coalesce(preferred_name, first_name))`.

**`ea_change_volunteer_status(p_person uuid, p_status ea_volunteer_status, p_valid_from date) returns void`** – security invoker: prüft `p_status <> 'left'` (sonst `ea_leave` nutzen → `EA_STATUS_FORBIDDEN`), `p_valid_from <= current_date + interval '1 year'` (sonst `EA_STATUS_DATE`, A1), Status ungleich aktuellem (sonst `EA_STATUS_UNCHANGED`); ruft `ea_set_volunteer_status` (Administration).

**`ea_leave(p_person uuid, p_valid_from date, p_end_property_ids uuid[]) returns void`** – security invoker, eine Transaktion (A2): prüft Datum wie oben; ruft `ea_set_volunteer_status(p_person, 'left', p_valid_from)`; setzt für jede ID `valid_to = p_valid_from` (Update unterliegt RLS `ea_property_writable`). Gehört eine ID nicht zur Person, ist sie nicht aktuell oder liegt ihr `valid_from` nach `p_valid_from`: `EA_LEAVE_PROPERTY`. Bei jedem Fehler wird nichts geändert.

**`ea_renew_property(p_property uuid, p_valid_from date, p_field_values jsonb, p_training jsonb default null) returns uuid`** – security invoker (R6): erlaubt nur für aktuelle Eigenschaften mit `system_key in ('license','qualification')` und `p_valid_from > valid_from` der alten (sonst `EA_RENEW_INVALID`). Legt eine neue Eigenschaft mit derselben Person und Art an: `field_values = alte || p_field_values`, `valid_from = p_valid_from`; setzt bei der alten `valid_to = p_valid_from - 1`. Ist `p_training` gesetzt (`{"year":…, "title":…}`), legt sie zusätzlich eine `further_training`-Eigenschaft mit `qualification_type` der Lizenz und `valid_from = p_valid_from` an. Gibt die ID der neuen Eigenschaft zurück.

**`ea_import_volunteers(p_rows jsonb, p_cutoff date, p_dry_run boolean) returns jsonb`** – security definer, `grant execute` **nur an `service_role`** (A3): siehe Abschnitt 7.

Indizes (Migration der Funktionen): `create index on ea_properties ((field_values->>'valid_until')) where field_values ? 'valid_until'`.

## 3. Rechte / RLS

Keine neuen Tabellen, keine neuen Policies. Alle Lese- und Schreibzugriffe laufen über die Tabellen der Administration mit deren RLS (R29–R42 AD); die neuen Funktionen sind `security invoker`, außer `ea_import_volunteers` (nur `service_role`).

| Rechtevorlage | Aktive lesen | Person anlegen | Eigenschaften pflegen | Status / Ausscheiden | Ablauf, Stichtagsliste | CSV-Export | Gremien | Stammdaten (Referate, Gremien, Eigenschafts- und Qualifikationsarten) | Löschen |
|---|---|---|---|---|---|---|---|---|---|
| Admin (EA verwalten, AD verwalten) | alle inkl. ausgeschiedener; alle Lesestufen | ja | ja, inkl. vertraulich | ja | ja | ja | ja | ja, inkl. Lesestufe vertraulich | – |
| Geschäftsstelle (EA verwalten) | alle inkl. ausgeschiedener; Lesestufen alle, GST | ja, auch ohne Zuordnung | ja (nicht vertraulich) | ja | ja | ja | ja | ja, ohne vertraulich | – |
| Referent:in (EA bearbeiten, Referat) | aktiv/ruhend mit aktueller Zuordnung zu eigenem Referat; Lesestufe alle | nur mit Funktion oder Amt im eigenen Referat | Lesestufe alle; Zuordnungen nur eigene Referate (R12) | ja (R33 AD) | nur eigene Referate | nein | nein | nein | – |
| Vorstand | – | – | – | – | – | – | – | – | – |

Oberfläche (Routenschutz, Knöpfe): „verwalten“ = `ad_has_level('EA','manage')`; Zugang zum Modul = `ad_has_any_level('EA','read')`; eigene Referate = `ad_my_referate('EA','edit')`. Der CSV-Export ist eine Oberflächenfunktion über bereits lesbare Daten; er wird nur mit „verwalten“ angeboten (R11).

## 4. Zustände und Übergänge

Ehrenamtsstatus (Datenmodell spec.md AD Abschnitt 4):

| Von | Nach | Wer | Bedingung / Funktion |
|---|---|---|---|
| (neu) | aktiv | Geschäftsstelle, Admin; Referent:in mit Zuordnung zum eigenen Referat | `ea_create_volunteer`, gültig ab heute (R4) |
| aktiv | ruhend | Geschäftsstelle, Admin, Referent:in eines Referats der Person | `ea_change_volunteer_status`; Bestätigung bei weiteren Referaten (R7) |
| ruhend | aktiv | wie oben | `ea_change_volunteer_status` |
| aktiv, ruhend | ausgeschieden | wie oben | `ea_leave` mit Auswahl der zu beendenden Eigenschaften (R8) |
| ausgeschieden | aktiv | Geschäftsstelle, Admin | `ea_change_volunteer_status` |
| ausgeschieden, kein Status | aktiv | Referent:in (und Geschäftsstelle, Admin) | Dublettendialog → `ea_activate_person` mit Zuordnung zum eigenen Referat |

Ablaufstatus (berechnet, `ea_expiry_status`): gültig → läuft in ≤ 3 Monaten ab → abgelaufen; „ohne Ablauf“ ohne Datum. Verlängern (`ea_renew_property`) beendet die alte Eigenschaft und legt eine neue an.

## 5. Geschäftsregeln

Regeln R1–R42 der Administration gelten unverändert. Zusätzlich (Nummern wie 01-erhebung.md D):

- R1: Wenn die Übersicht ohne Statusfilter geöffnet wird, dann zeigt sie „aktiv“ und „ruhend“; „ausgeschieden“ bietet der Filter nur mit EA = verwalten an.
- R2: Namen werden als „Rufname Nachname“ angezeigt, sonst „Vorname Nachname“.
- R3: Wenn eine Referent:in eine Person ohne Funktion oder Amt in einem eigenen Referat anlegen oder wieder aktivieren will, dann Fehlermeldung „Bitte eine Funktion oder ein Amt in deinem Referat angeben.“
- R4: Neue Personen erhalten Status „aktiv“ ab dem Tag der Anlage.
- R5: Wenn eine Lizenz oder Qualifikation mit Qualifikationsart mit Gültigkeitsdauer erfasst wird, dann wird „gültig bis“ mit `ea_default_valid_until` vorbelegt (neu berechnet bei Änderung von Qualifikationsart, „gültig von“ oder „letzte Fortbildung“, solange der Nutzer das Feld nicht selbst geändert hat); ohne Gültigkeitsdauer bleibt es leer.
- R6: Wenn verlängert wird, dann entsteht ein neuer Eintrag und der bisherige endet am Vortag; sonst (alte Eigenschaft nicht aktuell oder neues Datum nicht später) „Nur aktuelle Lizenzen und Qualifikationen können verlängert werden; das neue Datum muss nach dem bisherigen liegen.“ (`EA_RENEW_INVALID`).
- R7: Wenn eine Person auf „ruhend“ oder „ausgeschieden“ gesetzt wird und `ea_person_referate` Referate außerhalb von `ad_my_referate('EA','edit')` liefert (für Nutzer mit Reichweite „alle“: mehr als ein Referat), dann Bestätigung „Die Person ist auch in <Referate> tätig. Der Status gilt für alle Referate.“
- R8: Wenn auf „ausgeschieden“ gesetzt wird, dann sind alle aktuellen Eigenschaften der Arten `function`, `position`, `committee`, die der Nutzer ändern darf, vorausgewählt zum Beenden am selben Datum (abwählbar); nicht änderbare erscheinen als „wird nicht beendet (anderes Referat)“; Eigenschaften mit Bezug auf eine Gruppe als „im Modul Gruppen beenden“; aktuelle `issued_item`- und `external_access`-Eigenschaften als Hinweis.
- R9: Ablaufstatus nach `ea_expiry_status`; Grenze 3 Monate.
- R10: Die Führungszeugnis-Einsicht läuft 3 Jahre nach dem Ausstellungsdatum ab.
- R11: Die Stichtagsliste zeigt alle Zeilen aus `ea_v_expiry` mit `kind in ('license','qualification')` und `valid_until` im gewählten Jahr; Export nur mit EA = verwalten.
- R12: Eigenschaften pflegt, wer sie lesen darf und EA ≥ bearbeiten hat (R42 AD); Zuordnungen von Referent:innen nur zu eigenen Referaten (R41 AD).
- R13: Wenn die IBAN nach Normalisierung ungültig ist, dann „Die IBAN ist ungültig.“ (`EA_IBAN_INVALID`).
- R14: „Trainer:in ohne gültige Lizenz“ = aktuelle Funktion Trainer:in ohne aktuelle Lizenz mit „gültig bis“ ≥ heute; keine automatische Änderung.
- R15–R17: Migration, siehe Abschnitt 7.
- R18 (neu): Wenn ein Statusdatum später als heute + 1 Jahr liegt, dann „Bitte ein Datum bis spätestens <TT.MM.JJJJ> wählen.“ (`EA_STATUS_DATE`).
- R19 (neu): Wenn der gewählte Status dem aktuellen entspricht, dann „Die Person hat diesen Status bereits.“ (`EA_STATUS_UNCHANGED`).
- R20 (neu): Wenn beim Ausscheiden eine Eigenschaft nicht beendet werden darf oder kann, dann „Diese Angabe kann hier nicht beendet werden.“ (`EA_LEAVE_PROPERTY`); es wird nichts geändert.

Neue Fehlercodes (in `docs/specs/ad-administration/contracts/error-codes.md` ergänzen, Abschnitt „Ehrenamtsmanagement“): `EA_IBAN_INVALID`, `EA_STATUS_DATE`, `EA_STATUS_UNCHANGED`, `EA_LEAVE_PROPERTY`, `EA_RENEW_INVALID`. v0.2.1: `ea_create_volunteer` und `ea_activate_person` melden ohne EA-Recht `EA_CREATE_FORBIDDEN` („Für diesen Bereich hast du keine Rechte.“) und für Referent:innen ohne Funktion oder Amt `EA_CREATE_REFERAT_REQUIRED` (Meldung R3); die Prüfung der Administration (`ea_check_create`) ersetzt eine Migration des Ehrenamtsmanagements. Datenbankfehler tragen den Code als `MESSAGE` mit `DETAIL` für Platzhalter (wie Administration).

## 6. Screens und Interaktionen

Allgemein wie Administration (deutsch, „du“, TT.MM.JJJJ, shadcn/ui, ab 375 px, Tabellen mobil als Karten). Navigation (A6): Geschäftsstelle und Admin: Aktive · Ablauf · Gremien · Eigenschaftsarten · Qualifikationsarten · Referate und Gremien; Referent:in: Aktive · Ablauf.

| Route | Zeigt | Aktionen | Leer / Fehler | Story |
|---|---|---|---|---|
| /ea | Weiterleitung auf /ea/aktive | – | ohne `ad_has_any_level('EA','read')` → /kein-zugriff | US-EA-01 |
| /ea/aktive | Tabelle aus `ea_volunteer_list`: Name, Status mit „seit“, Referate, Funktionen und Ämter, Lizenzkürzel, Ablauf-Badge (schlechtester Status), darunter die abgelaufenen und in ≤ 3 Monaten ablaufenden Eigenschaften mit Datum (aus `ea_v_expiry`, RLS entscheidet); bei „Trainer:in ohne gültige Lizenz“ ersetzt das Kennzeichen „ohne gültige Lizenz“ mit der abgelaufenen Lizenz das Ablauf-Badge (v0.2.2); Suche (ab 1 Zeichen, 300 ms Verzögerung); Filterleiste (R1, US-EA-03; Referent:in: Referatsfilter nur eigene, vorbelegt, ohne Gremium, ohne „ausgeschieden“; Filter „Qualifikation“ bietet nur Arten an, die bei sichtbaren Aktiven aktuell vergeben sind, v0.2.3); Filter und Seite in der URL (A5); 50 je Seite | „Person anlegen“ (EA ≥ bearbeiten); Zeile öffnet Detail | „Keine Aktiven gefunden.“ | US-EA-02, 03 |
| /ea/aktive/neu | Vorname, Nachname, Rufname; erste Zuordnung: Art (Funktion oder Amt), Wert, Referat (Referent:in: nur eigene, Pflicht; Geschäftsstelle/Admin: optional), „seit“ (Standard heute) | Speichern → `ad_find_similar_persons` → bei Treffern Dublettendialog (Administration) mit Aktionen: „Vorhandene Person öffnen“ (sichtbar), „Wieder aktivieren“ (ausgeschieden), „Ins Ehrenamtsmanagement übernehmen“ (ohne Status) → `ea_activate_person` mit der eingegebenen Zuordnung; „Trotzdem anlegen“ → `ea_create_volunteer`; „Abbrechen“ | R3, R4 AD | US-EA-05, 10 |
| /ea/aktive/:id | Kopf: Name, Rufname, Status-Badge mit „seit“, Historie aufklappbar; Kennzeichen „Trainer:in ohne gültige Lizenz“. Abschnitte je Kategorie (Reihenfolge laut Enum) mit allen lesbaren Eigenschaften, deren Art „sichtbar in“ EA enthält; je Eigenschaft Felder „Bezeichnung: Wert“, Bezug, „gültig von/bis“ mit Bezeichnungen der Art, Ablauf-Badge (Lizenz, Qualifikation, Führungszeugnis), Historie aufklappbar; beendete eingeklappt unter „beendet“ | „Status ändern“; „Eigenschaft hinzufügen“ (nur Arten mit `sichtbar in` EA, die der Nutzer schreiben darf; Referent:in ohne GST und vertraulich); je Eigenschaft „Ändern“, „Beenden“, bei Lizenz/Qualifikation „Verlängern“ (nur, wenn die Qualifikationsart den Status „aktuell“ hat; v0.2.1); Knöpfe nur, wenn schreibbar (eigene Referate bzw. verwalten); Gruppen-Bezug nur lesen mit Hinweis | nicht lesbar: „Diese Person wurde nicht gefunden oder du hast keine Rechte.“; R35–R38 AD, R13 | US-EA-04, 06, 07, 11 |
| Dialog „Eigenschaft“ | Eigenschaftsformular der Administration; bei `license`/`qualification` Vorbelegung „gültig bis“ (R5) | Speichern | Fehler je Feld | US-EA-06, 07 |
| Dialog „Verlängern“ | neues „erworben bzw. verlängert am“ (Pflicht), „letzte Fortbildung“, „gültig bis“ (vorbelegt), optional „Fortbildung anlegen“ (Jahr, Titel) | Speichern → `ea_renew_property` | R6 | US-EA-07 |
| Dialog „Status ändern“ | Auswahl aktiv/ruhend/ausgeschieden (ohne aktuellen), Datum (Standard heute) | bei weiteren Referaten Bestätigung (R7); bei „ausgeschieden“ zweiter Schritt nach R8 mit Checkboxen und Hinweisen; Speichern → `ea_change_volunteer_status` bzw. `ea_leave` | R18–R20, R33 AD | US-EA-08, 09 |
| /ea/ablauf | Jahr (Standard Folgejahr, Auswahl aktuelles Jahr bis +3); Tabelle aus `ea_v_expiry` (R11) mit Name, Referate, Kürzel – Bezeichnung, gültig bis, Badge; sortiert nach gültig bis, Name | „CSV exportieren“ (nur verwalten): `ablauf-<jahr>.csv`, UTF-8 mit BOM, Semikolon, Spalten Nachname; Vorname; Rufname; Referate; Kürzel; Bezeichnung; gültig bis | „Im Jahr <jahr> läuft keine Qualifikation ab.“ | US-EA-12 |
| /ea/gremien | je aktivem Gremium (sort_order) aktuelle `committee`-Eigenschaften: Name, Rolle, seit, bis | Name öffnet Detail | „Keine Mitglieder eingetragen.“; ohne verwalten → /kein-zugriff | US-EA-13 |
| /ea/stammdaten | zwei Listen Referate, Gremien: Bezeichnung, Reihenfolge, Status | Neu, Bearbeiten (Bezeichnung, Reihenfolge, aktiv) | doppelte Bezeichnung: „Diese Bezeichnung gibt es bereits.“; ohne verwalten → /kein-zugriff | US-EA-14 |
| /ea/eigenschaftsarten, /ea/eigenschaftsarten/:id, /ea/qualifikationsarten, /ea/qualifikationsarten/:id | Komponenten der Administration unverändert eingehängt; `system_key` nur lesen | wie Administration | ohne verwalten → /kein-zugriff | US-EA-15 |

## 7. Schnittstellen

| Schnittstelle | Art | Beschreibung |
|---|---|---|
| Administration | Datenbank, Komponenten | Tabellen und Funktionen nach Abschnitt 2; `ea_create_volunteer`, `ea_activate_person`, `ea_set_volunteer_status`, `ea_person_referate`, `ad_find_similar_persons`, `ad_my_referate`, `ad_has_level`, `ad_has_any_level`; Komponenten Eigenschaftsformular, Dublettendialog, Auswahlfeld Qualifikationsart, Seiten Eigenschafts- und Qualifikationsarten |
| Gruppen, Anwesenheitserfassung, Planungshilfe Touren und Kurse, Finanzen | Datenbank (lesen) | nutzen die System-Eigenschaftsarten über `system_key` und Feldschlüssel (01-erhebung.md C2); keine eigenen Schnittstellen des Ehrenamtsmanagements |
| Migrationsskript | lokales Node-Skript | siehe unten |

**Migrationsskript** (`scripts/ea-migrate/`, TypeScript, ausgeführt mit `tsx`; Abhängigkeiten `@supabase/supabase-js`, `csv-parse`):
- Aufruf: `npm run ea:migrate -- --file <pfad> --dry-run` bzw. `--run`; optional `--cutoff <TT.MM.JJJJ>` (Stichtag, Standard heute). Das Skript fragt beim Start die Projekt-URL (`https://<ref>.supabase.co`) und den Secret Key des Projekts ab; der Schlüssel wird verdeckt eingegeben (wie ein Passwort), nur im Arbeitsspeicher gehalten und nie in eine Datei, ein Log oder einen Bericht geschrieben. Es gibt keine `.env`-Datei für das Skript (Constitution Prinzip III, Entscheidung Product Owner 23.10.2026). Leere Eingabe: Abbruch „Schlüssel fehlt.“ Probelauf und Lauf – auch gegen TEST – führt der Admin aus, nicht Claude Code.
- Eingabe: CSV nach 01-erhebung.md C3 (UTF-8, Semikolon, Kopfzeile Pflicht). Fehlt eine Spalte der Vorlage: Abbruch „Spalte <name> fehlt.“ Jahresspalten (`fb_<jahr>`, `marke_<jahr>`, `foerderung_<jahr>`, `jahreskarte_<jahr>`) werden über das Muster erkannt.
- Das Skript wandelt Datumswerte in ISO, Listen in Arrays und Zeilennummern in `row` und ruft `ea_import_volunteers(p_rows, p_cutoff, p_dry_run)` per RPC auf. Formatfehler (Datum nicht lesbar, „ja/nein“ erwartet) meldet schon das Skript als Fehler im Bericht.
- `--run` fragt vorher: „Lauf gegen <Projekt-Ref> – zum Bestätigen Projekt-Ref eingeben:“ (A4); führt zuerst intern einen Probelauf aus und bricht bei Fehlern ab („Probelauf hat Fehler. Lauf abgebrochen.“).
- Ausgabe: `<datei>.pruefbericht.md` bzw. `<datei>.abschlussbericht.md` neben der CSV (enthält Namen → bleibt lokal).
- Repository: `scripts/ea-migrate/vorlage.csv` (nur Kopfzeile) und `scripts/ea-migrate/beispiel.csv` (5 fiktive Zeilen, alle Fälle); `.gitignore`: `scripts/ea-migrate/*.csv` außer diesen beiden, `*.pruefbericht.md`, `*.abschlussbericht.md`.

**`ea_import_volunteers(p_rows jsonb, p_cutoff date, p_dry_run boolean) returns jsonb`** (security definer, nur `service_role`):
- Prüft jede Zeile: Pflichtfelder (Nachname, Vorname, aktiv); Referate gegen aktive `ea_referate` (Name ohne Groß-/Kleinschreibung); Qualifikationsarten in `l1–l3_art` und `qualifikationen` über Kürzel oder Bezeichnung in `ad_qualification_types` (auch historisch, R27 AD); Typ Lizenz für `l*_art`; IBAN (`ea_iban_valid`); Geschlecht und Auswahlwerte gegen die Felder der System-Eigenschaftsarten; „gültig bis“ der Lizenz fehlt → Wert aus `ea_default_valid_until` und Warnung.
- Dublettenverdacht (Warnung): gleiche Logik wie `ad_find_similar_persons` (R3 AD) gegen vorhandene Personen und innerhalb der Datei.
- Weitere Warnungen: mehr Lizenzen als Lizenznummern; Werte in `gruppe`/`gruppenleitung` (für den Gruppen-Import); Anzahl Eigenschaften mit „gültig von“ = Stichtag (R17).
- Rückgabe: `{"errors":[{"row":n,"message":…}], "warnings":[…], "counts":{"persons":n, "<system_key>":n, …}, "written": bool}`.
- Schreibt nur, wenn `p_dry_run = false` und keine Fehler; alles in einer Transaktion (A3). Je Zeile: Person (`created_in = 'script'`, `created_by = null`); Status `active` (aktiv = ja) bzw. `dormant` (nein) mit `valid_from = p_cutoff` und Historie (ein Eintrag); Eigenschaften nach C3 und R15 (je Referat `function` „Trainer:in“ bei mindestens einer Lizenz, sonst „Helfer:in“, `valid_from = aktiv_seit` oder Stichtag; `training_units_per_week` aus `te_pro_woche` an Trainer:in-Funktionen); Datum unbekannt → `valid_from = p_cutoff`.

## 8. Nicht-funktionale Anforderungen

- Keine Tabelle ohne RLS; keine neue Rechteprüfung nur im Frontend; neue Funktionen `security invoker` (Ausnahme Import, nur `service_role`).
- Schemaänderungen und Stammdaten (System-Eigenschaftsarten, Qualifikationsarten) per Migration in TEST und PROD; Personendaten nur per Seed (TEST) bzw. Migrationsskript (PROD).
- Keine Echtdaten im Repository oder in TEST; CSV und Berichte nur lokal beim Admin.
- Leistung bei 1.000 Personen mit je 30 Eigenschaften: `ea_volunteer_list` (Referent:in, alle Filter) < 1 s, `ea_v_expiry` für ein Jahr < 2 s, Detail < 1 s; geprüft per Mengentest in pgTAP.
- Import von 300 Zeilen < 60 s.
- Mobil ab 375 px.
- Kosten 0 €.

## 9. Testdaten

**Seed-Umstellung (Ü3):** Mit der Migration aus 2.1 entfallen im Seed (`supabase/seed.sql`) die Testarten „Funktion (Test)“, „Amt (Test)“, „Lizenz (Test)“, „Geburtsdatum (Test)“, „Kontaktdaten (Test)“ und „Hauptamt“. Die Eigenschaften der Personen 2–12 (spec.md AD Abschnitt 9) verweisen auf die System-Eigenschaftsarten (Auflösung über `system_key`) mit den Feldschlüsseln aus C2 (z. B. Lizenz: `qualification_type`, `license_number`, `valid_until`; Kontaktdaten: `email`; Geburtsdatum: `date`; Hauptamt: `title`). „T-Shirt-Größe“ und „Erste-Hilfe-Kurs am“ bleiben Testarten. Erwartete Sichtbarkeit und Tests der Administration bleiben gültig.

**Zusätzliche Personen** (alle `kind = human`, kein Zugang; Datumswerte relativ zu `current_date` beim Seed):

| # | Person | Ehrenamtsstatus | Eigenschaften |
|---|---|---|---|
| 19 | Lena Lizenz | aktiv seit 01.01.2024 | Funktion Trainer:in, Referat Klettern, seit 01.01.2024; Lizenz TCBO, Nr. „TEST-0019“, gültig von 01.06.2022, gültig bis heute + 2 Monate |
| 20 | Max Abgelaufen | aktiv seit 01.01.2020 | Funktion Trainer:in, Referat Kinder und Jugend, seit 01.01.2020; Lizenz TCSPI, gültig von 01.05.2021, gültig bis 31.12.2025; Führungszeugnis-Einsicht Ausstellungsdatum heute − 34 Monate, eingesehen am Ausstellungsdatum + 7 Tage |
| 21 | Greta Gremium | aktiv seit 01.01.2023 | Gremium Beirat, Rolle Mitglied, seit 01.07.2023; kein Referat |
| 22 | Sven Schlüssel | aktiv seit 01.01.2025 | Funktion Helfer:in, Referat Klettern, seit 01.01.2025; Ausgabe Schlüssel K4, Nr. „TEST-K4-22“, ausgegeben 01.02.2025, nicht zurückgegeben; Zugang extern DAV360 seit 01.02.2025; Bankverbindung „Sven Schlüssel“, IBAN DE89370400440532013000 |

Nummern 13–18 bleiben für den Nachtrag v0.9 der Administration reserviert.

**Erwartete Ergebnisse** (Grundlage der pgTAP-Tests):

| Testzugang | `ea_volunteer_list()` (Standard) | `p_trainer_without_license` | `ea_v_expiry` Jahr 2027 | Bankverbindung Sven |
|---|---|---|---|---|
| Admin | 4, 5, 9, 10, 19, 20, 21, 22 | 20 | Toni Muster TCSPI 31.12.2027 (+ Lena, falls heute + 2 Monate in 2027) | lesbar |
| Geschäftsstelle | wie Admin | 20 | wie Admin | lesbar |
| Referent:in (Klettern) | 4, 9, 10, 19, 22 | – | nur Personen 4, 10, 19, 22 | nicht lesbar |
| Vorstand | keine | keine | keine | nicht lesbar |

Zusätzlich: Statusfilter `{left}` liefert für Geschäftsstelle Person 11, für Referent:in nichts; Person 12 erscheint für niemanden in `ea_volunteer_list`; `ea_expiry_status` für Person 19 = `expiring`, für Person 20 Lizenz = `expired` und Führungszeugnis = `expiring`; Referent:in sieht in `ea_v_expiry` keine `police_clearance`-Zeile.

**Beispiel-CSV** (`scripts/ea-migrate/beispiel.csv`, fiktiv): 5 Zeilen – aktiv mit zwei Lizenzen und einer Nummer; ruhend mit abgelaufener historischer Lizenz (TCSP) und zwei Referaten; Helfer:in ohne Lizenz mit Ausgabe und Zugang extern; Zeile mit Fortbildungen 2019, 2023 und Erste Hilfe; Zeile mit Dublettenverdacht zu Toni Muster. Eine sechste Datei `beispiel-fehler.csv` mit unbekanntem Kürzel und ungültiger IBAN für den Fehlerfall.

## 10. Umsetzungs-Tasks

Voraussetzung: Administration T1–T49 umgesetzt.

- [ ] T0a: Ü1 nach uebergabe-administration.md, falls noch nicht umgesetzt: Migration `ea_property_types.valid_from_label`, `valid_to_label` mit Check; Formular der Eigenschaftsart, Eigenschaftsformular und Anzeige im Personendetail der Administration; pgTAP
- [ ] T0b: Ü2 nach uebergabe-administration.md, falls noch nicht umgesetzt: neue Fassung von `ad_find_similar_persons` (`birth_year` nur mit AD lesen, EA verwalten oder GR verwalten); Dublettendialog; pgTAP Je Story ein Branch und ein Pull Request mit vollständiger Cloudflare-Vorschau-URL; pgTAP-Tests grün.

- [ ] T1: Migration System-Eigenschaftsarten nach 2.1 (US-EA-16)
- [ ] T2: Migration Qualifikationsarten nach 2.2 (US-EA-16)
- [ ] T3: Seed-Umstellung (Ü3) und Personen 19–22 nach Abschnitt 9; prüfen, dass T45 der Administration grün bleibt (US-EA-19)
- [ ] T4: Migration Funktionen Ablauf und Liste: `ea_expiry_status`, `ea_default_valid_until`, View `ea_v_expiry`, `ea_volunteer_list`, Index (US-EA-02, 03, 11, 12)
- [ ] T5: Migration IBAN: `ea_iban_normalize`, `ea_iban_valid`, Trigger `ea_properties_iban` (US-EA-06)
- [ ] T6: Migration Status und Verlängern: `ea_change_volunteer_status`, `ea_leave`, `ea_renew_property` (US-EA-07, 08, 09)
- [ ] T7: Migration Import: `ea_import_volunteers`, Grant nur `service_role` (US-EA-17, 18)
- [ ] T8: Fehlercodes in contracts/error-codes.md (Abschnitt 5)
- [ ] T9: pgTAP: Erwartete Ergebnisse Abschnitt 9; R5, R6, R9, R10, R13, R14, R18–R20; Rechte-Fälle aus allen Stories (Funktionen mit Vorstand und Referent:in); `ea_import_volunteers` für `authenticated` nicht ausführbar; Idempotenz T1/T2; Mengentest Abschnitt 8
- [ ] T10: Frontend: Routen /ea/*, Navigation (A6), Routenschutz (US-EA-01)
- [ ] T11: Frontend: /ea/aktive mit Suche, Filtern, URL-Zustand, Paginierung, mobile Karten (US-EA-02, 03)
- [ ] T12: Frontend: Detail mit Kategorien, Historie, Bezeichnungen, Ablauf-Badges (US-EA-04, 11)
- [ ] T13: Frontend: Person anlegen mit Dublettendialog-Aktionen „Wieder aktivieren“ und „Übernehmen“ (US-EA-05, 10)
- [ ] T14: Frontend: Eigenschaft hinzufügen/ändern/beenden mit Vorbelegung R5; Dialog Verlängern (US-EA-06, 07)
- [ ] T15: Frontend: Dialoge Status ändern und Ausscheiden (R7, R8) (US-EA-08, 09)
- [ ] T16: Frontend: /ea/ablauf mit CSV-Export (US-EA-12)
- [ ] T17: Frontend: /ea/gremien (US-EA-13)
- [ ] T18: Frontend: /ea/stammdaten Referate und Gremien (US-EA-14)
- [ ] T19: Frontend: Einhängen /ea/eigenschaftsarten, /ea/qualifikationsarten (US-EA-15)
- [ ] T20: Migrationsskript `scripts/ea-migrate/` mit `vorlage.csv`, `beispiel.csv`, `beispiel-fehler.csv`, `.gitignore`, `npm run ea:migrate`; Probelauf und Lauf gegen TEST mit den Beispieldateien (US-EA-17, 18)
- [ ] T21: Abnahme in TEST mit Admin, Geschäftsstelle, Referent:in (Klettern), Vorstand; alle Stories
- [ ] T22: Migration `ad_modules.is_available = true` für EA (erst nach Abnahme; US-EA-01)
- [ ] T23: Lauf gegen PROD durch den Admin (nicht Claude Code): Probelauf, Korrektur, Lauf; Archivierung der Excel-Liste

## 11. Annahmen und offene Punkte

Entschieden vom Product Owner (21./22.10.2026): siehe 00-steckbrief.md, 01-erhebung.md (Abschnitt „Erledigt“) und 02-stories.md (Annahmen A1–A7 bestätigt am 22.10.2026).

Annahmen dieser Spec (bestätigt vom Product Owner am 22.10.2026):
- [ANNAHME] Keine neuen Tabellen; Liste und Ablauf über security-invoker-Funktion bzw. View über den Tabellen der Administration.
- [ANNAHME] Import über eine Datenbankfunktion nur für `service_role`, damit der Lauf eine Transaktion ist; das Skript liest die CSV und ruft die Funktion auf.
- [ANNAHME] Vorbelegung „gültig bis“ wird neu berechnet, solange der Nutzer das Feld nicht selbst geändert hat.
- [ANNAHME] Qualifikationsarten aus C4: Kürzel, Sparte „Allgemein“, Aussteller „extern“.
- [ANNAHME] CSV-Export mit BOM für Excel; Jahresauswahl aktuelles Jahr bis +3.
- [ANNAHME] Verlängern ist nur für `license` und `qualification` möglich; optional zugleich Fortbildung.
- [ANNAHME] Leere Lizenz-„gültig bis“ im Import wird aus der Gültigkeitsdauer berechnet (Warnung).
- [ANNAHME] Mengengerüst 1.000 Personen; Import 300 Zeilen.

Offen (keine Blocker für die Umsetzung):
- [OFFEN] Übergaben an die Administration (Ü1–Ü3, v1.1) und an die Anwesenheitserfassung (v1.0) einarbeiten lassen; Ü1 und Ü2 sind Voraussetzung (siehe oben).
- [OFFEN] Karteileichen; Fördergeber und Förderart; Jahreskarte, Forms, Redaktion, Mailingliste; Amtszeit Jugendausschuss; „Mitarbeiter:in Mitgliederverwaltung“; Regelwerk Führungszeugnis-Einsicht (01-erhebung.md, Offene Fragen).

**Status Ready** seit 22.10.2026 (Freigabe Product Owner). Die Übernahme von Ü1–Ü3 in spec.md AD erfolgt im Chat der Administration; bis dahin ist uebergabe-administration.md maßgeblich.
