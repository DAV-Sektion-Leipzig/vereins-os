# Spec: Administration (AD)

Version: 0.9.4 · Status: Abschnitte bis v0.7.4 (Kern) Ready · Nachtrag v0.8 (Anwesenheitserfassung) Ready (v0.8.1, freigegeben am 24.10.2026) · Nachtrag v0.9 (Planungshilfe Touren und Kurse) Entwurf, Annahmen in Abschnitt 11 · Stand: 24.10.2026 · Product Owner: Toni Werner
Stories: docs/specs/ad-administration/02-stories.md (US-AD-01 bis US-AD-30); Nachtrag v0.8 mit US-AD-27 bis US-AD-30 (v0.8.1) und den Tasks T50–T58; Nachtrag v0.9 ohne eigene Stories, Abnahme über die Übergabe-Anforderungen und die Tasks T59–T67
Grundlage: 00-steckbrief.md v1.1, 01-erhebung.md v0.7 (R1–R20), glossar.md v1.5, rollen.md v1.0, tech-stack.md v0.6, specs/ea-ehrenamt/stammdaten-qualifikationsarten.md v0.2, specs/ea-ehrenamt/00-steckbrief.md v0.6, specs/ea-ehrenamt/migration-aktivenliste.md v0.4, specs/gr-gruppen/uebergabe-nachtrag-administration.md v1.0, specs/ez-einsaetze/uebergabe-rechte-administration.md v1.5 (A1–A9), specs/ez-einsaetze/spec.md v0.4 (Abschnitte 2, 3, 7), specs/gr-gruppen/01-erhebung.md v0.7 (R20 `gr_group_roster`), specs/tk-touren-kurse/uebergabe-administration.md v1.6, specs/tk-touren-kurse/spec.md v0.2, specs/ea-ehrenamt/uebergabe-administration.md v1.1 (Ü1–Ü3), specs/ea-ehrenamt/01-erhebung.md v0.5 (C2, C2a), specs/ea-ehrenamt/spec.md v0.2
Änderungen v0.3 (19.10.2026): Klärung der Widersprüche aus plan.md (W1–W14, A1–A5, P1); siehe Abschnitt 11.
Änderungen v0.4 (19.10.2026): Adressänderung bei „eingeladen“ nimmt die Einladung zurück, Aufräumen in ad-invite bei Fehlern, Abnahme der Mail-Abläufe mit Plus-Adressen; siehe Abschnitt 11.
Änderungen v0.5 (20.10.2026): Abnahme der Mail-Abläufe mit eigenen Adressen des Product Owners; R1 per Trigger mit zusätzlichen Domains nur in TEST (Tabelle ad_test_login_domains); siehe Abschnitt 11.
Änderungen v0.5.1 (21.10.2026): Startseite mit Ladezustand und Hinweis auf den Admin im leeren Zustand (US-AD-05 AK2).
Änderungen v0.6 (21.10.2026): Stammdaten Qualifikationsarten (Tabelle ad_qualification_types, Startbestand 47 per Migration, Pflege durch Admin und Geschäftsstelle), Datentyp „Qualifikationsart“ für Eigenschaftsarten, Regeln R21–R28, Tasks T26–T32 (US-AD-17 bis US-AD-19); siehe Abschnitt 11.
Änderungen v0.7 (21.10.2026, Nachtrag Personenmodell): aus EA – Rechtevorlage Referent:in mit Reichweite „Referat“, Referate und Gremien als Stammdaten, Lesestufe statt Kennzeichen „vertraulich“, Eigenschaftsart mit mehreren Feldern, Kategorie und Bezug, Rufname, Ehrenamtsstatus (Datenmodell und Funktionen), Dublettenwarnung modulübergreifend; aus GR (Übergabe v1.0) – gemeinsame Personen-Tabelle, Sichtbarkeit je Zugehörigkeit (Pfade AD, EA, GR), Startwert Admin „Gruppen lesen“, Anlegen von Personen durch GR, Bezug auf Gruppen. Neue Regeln R29–R42, Stories US-AD-20 bis US-AD-26, Tasks T33–T49. Ersetzt die noch nicht umgesetzten Teile von T2 (ea_property_types, ea_properties, ea_property_history) sowie T28 und T31.
Änderungen v0.7.1 (21.10.2026, Freigabe Product Owner): Der Admin (AD ≥ lesen) sieht immer alle Personen aller Module mit allen Eigenschaften, damit Vollständigkeit herstellbar ist (ersetzt E2 der Übergabe aus GR für die Administration); Übernahme von Personen aus anderen Modulen durch Referent:innen und Bedeutung der Lesestufe „nur Geschäftsstelle und Admin“ bestätigt; Personenübersicht mit Filter „Zugehörigkeit“ und Paginierung.
Änderungen v0.8 (22.10.2026, Nachtrag Anwesenheitserfassung, Übergabe uebergabe-rechte-administration.md v1.2): Modul Anwesenheitserfassung (EZ) in `ad_modules`; Startwerte EZ (Admin lesen, Geschäftsstelle verwalten, Referent:in bearbeiten mit Reichweite Referat, Vorstand ohne Rechte); Reichweite „Referat“ für EA und EZ (R30); Namensfunktionen für die Anwesenheitserfassung statt eines weiteren RLS-Pfads (`ez_person_visible` als Platzhalter, `ea_person_names`, `ea_search_active_persons`); Anlegen von Aktiven aus einem Arbeitseinsatz über `ea_create_volunteer` mit EZ-Rechten; Stammdaten Orte (`ad_locations`); Regeln R43–R45; Tasks T50–T58; Reichweite „Gruppe“ und Vorlage Gruppenleitung für Iteration 1 vorgemerkt.
Änderungen v0.9 (22.10.2026, Nachtrag Planungshilfe Touren und Kurse, Übergabe specs/tk-touren-kurse/uebergabe-administration.md v1.6; auf Wunsch des Product Owners im Chat Planungshilfe Touren und Kurse eingearbeitet, weil der Chat der Administration in einem anderen Projekt liegt): Module Planungshilfe Touren und Kurse (TK) und Freigabe Touren und Kurse (TKF, ohne Seiten) in `ad_modules` mit Spalte `is_hidden`; Startwerte TK (Admin lesen, Geschäftsstelle verwalten, Referent:in bearbeiten mit Reichweite Referat, Vorstand ohne); neue Rechtevorlage „Freigabe Touren und Kurse“ (TKF bearbeiten, Reichweite Referat); Reichweite „Referat“ für EA, EZ, TK, TKF (R30); Stammdaten Sätze und Pauschalen `ad_rates` mit `ad_rates_at`, Pflege nur Admin (R46); Lesefunktion `ea_person_licenses` (R47); Namenssuche und Namen für TK (`tk_person_visible` als Platzhalter, R48); Seed-Ergänzung (Personen 13–18); Tasks T59–T67.
Änderungen v0.9.1 (22.10.2026, **Kern v0.7.2**, Übergabe specs/ea-ehrenamt/uebergabe-administration.md v1.1): Bezeichnungen „gültig von/bis“ je Eigenschaftsart (`valid_from_label`, `valid_to_label`, R49, Ü1); Geburtsjahr in der Dublettenwarnung abhängig von Lesestufe und Rechten (R40, Ü2); Testarten mit `system_key` nur bis zur ersten Migration des Ehrenamtsmanagements, Feldschlüssel der Testarten nach 01-erhebung.md EA C2, TEST wird vor der ersten EA-Migration zurückgesetzt (Abschnitt 9, Ü3); Feldschlüssel `birth_date.date`, `contact.email`/`dav_email`, `function.function`, `license.qualification_type`/`valid_until` in den Nachträgen v0.8 und v0.9 angeglichen; Tasks T35, T42, T43, T45–T49, T53, T57, T62, T66 ergänzt. Gehört zum Kern (vor bzw. mit T35/T43), nicht zu den Nachträgen.
Änderungen v0.9.3 (23.10.2026, **Kern v0.7.4**, Entscheidungen des Product Owners aus dem Review des Kerns): R1-Prüfung für das Frontend vor dem Anlegen einer Person (`ad_login_email_ok`, US-AD-07 AK5); Einladung über das Supabase-Dashboard wird protokolliert (Trigger auf auth.users, Abschnitt 2 und 4); R42 präzisiert: Referent:innen schreiben nur Eigenschaften mit Bezug auf ein eigenes Referat (gewollt); `ea_create_volunteer`/`ea_activate_person` prüfen Lesestufe und Bezugsart der Eigenschaftsart; US-AD-06 AK5 an R32 angeglichen.
Änderungen v0.9.2 (22.10.2026, **Kern v0.7.3**, Rückfrage aus der Umsetzung T43): Namensregel der Dublettenprüfung präzisiert (R3a): „Teilwort“ ersetzt durch gemeinsame Zeichenfolge von mindestens 3 Buchstaben im Vornamen oder Rufnamen, weil Toni/Anton weder Teilwort ist noch die Trigramm-Schwelle erreicht (similarity 0,1); Hilfsfunktion `ad_first_names_match`; erwartete Ergebnisse in Abschnitt 9 ergänzt; T43, T45, T25.
Änderungen v0.9.4 (24.10.2026, **Nachtrag v0.8.1**, Übergabe specs/ez-einsaetze/uebergabe-rechte-administration.md v1.5 A9, Abgleich mit specs/ez-einsaetze/spec.md v0.4, Entscheidungen des Product Owners): `ea_activate_person` mit dem Pfad der Anwesenheitserfassung – ruhende, ausgeschiedene und Personen ohne Ehrenamtsstatus beim Arbeitseinsatz direkt wieder aktiv eintragen, auch referatsübergreifend (neue R45a); Inhalt von `ez_person_visible` nach spec.md EZ v0.4; fremdes Referat über EZ meldet `EA_RELATION_FOREIGN_REFERAT` (`EA_CREATE_FOREIGN_REFERAT` entfällt); `AD_TOO_MANY_IDS` ohne eigenen Text; Orte ohne Startbestand im Nachtrag, Pflege nur Admin; erwartete Ergebnisse in Abschnitt 9 an den Seed auf main angeglichen; Stories US-AD-27 bis US-AD-30; Annahmen v0.8 bestätigt, Nachtrag v0.8 Ready (Abschnitt 11).

**Hinweis zum Umsetzungsstand (Repository main @ 67f68d9, geprüft 21.10.2026):** Erledigt sind im Repository T001–T031 (Nummerierung von Spec Kit; US-AD-01, US-AD-02, US-AD-05). `ea_persons` existiert bereits (Migration `20261020000200_ea_persons.sql`, in TEST, nicht in PROD). Alle Änderungen an `ea_persons` und an bestehenden Policies erfolgen per **neuer** Migration. `ea_property_types`, `ea_properties` und `ea_property_history` existieren noch nicht und werden direkt in der Form dieser Spec angelegt. Branch `us-ad-10-rechtevorlagen` ist unfertig und pausiert. Der Nachtrag v0.7 ist freigegeben (21.10.2026); die Umsetzung kann mit T33 wieder aufgenommen werden. Die Ergänzungen **v0.7.2** (Ü1, Ü2, Seed) gehören zum Kern: Sind T35, T43 oder T48 bei Erscheinen dieser Fassung bereits umgesetzt, werden sie per **neuer** Migration bzw. Seed-Änderung nachgezogen (Stand je Task prüft Claude Code). Der Nachtrag v0.8 setzt T33, T38, T39 und T40 voraus und wird vor der ersten Migration der Anwesenheitserfassung umgesetzt; Reihenfolge der Module: Gruppen → Anwesenheitserfassung → Finanzen (Product Owner, 22.10.2026). Der Nachtrag v0.9 setzt T33–T40 und T52 voraus und wird vor der ersten Migration der Planungshilfe Touren und Kurse umgesetzt; `ea_person_licenses` setzt zusätzlich die System-Eigenschaftsart Lizenz der ersten EA-Migration voraus (R47).

## 1. Ziel und Scope

**Ziel:** Login, Zugänge und Rechte für das Vereins OS; Grundstruktur des Personenmodells (Person, Eigenschaftsart, Eigenschaft) für alle Module mit einer gemeinsamen Personen-Tabelle; Stammdaten der Qualifikationsarten, Referate, Gremien, Orte und Sätze. Erfolg: alle 4 Nutzer melden sich in PROD an; der Admin legt Personen an, lädt ein, weist Rechtevorlagen (auch mit Referaten) zu, ändert sie und sperrt Zugänge ohne Code-Änderung; je Rechtevorlage ein Testzugang in TEST; die 47 Qualifikationsarten liegen in TEST und PROD vor und sind ohne Code-Änderung pflegbar; jede Person ist nur in den Modulen lesbar, zu denen sie gehört.

**Im Scope:** Login/Logout, Einladung und Passwort setzen, Passwort vergessen (Supabase Auth, SMTP über Google-Konto der Sektion); Startseite; Personenübersicht mit Zugangsstatus; Person anlegen mit Dublettenwarnung (modulübergreifend, minimale Trefferdaten); Zugang einladen, erneut einladen, sperren, entsperren; Rechtevorlagen anlegen, ändern, zuweisen, entziehen, mit Reichweite „alle“ oder „Referat“ (Referat nur für EA, EZ, TK und TKF); Referate je Zuweisung; Eigenschaftsarten mit Zweck, Kategorie, Lesestufe, Bezug und 1–n Feldern anlegen und ändern; Eigenschaften pflegen inkl. Historie; Rufname; Notfall-Admin mit Protokoll und Hinweis; Protokoll (5 Jahre); Ersteinrichtung PROD; Seed für TEST; Qualifikationsarten anlegen, ändern, auf „historisch“ setzen; Startbestand Qualifikationsarten, Referate und Gremien per Migration; Datentyp „Qualifikationsart“ (Verweis) je Feld; Datenmodell und Datenbankfunktionen für den Ehrenamtsstatus; Sichtbarkeit von Personen und Eigenschaften je Pfad (AD, EA, GR) per RLS; **v0.8:** Modul Anwesenheitserfassung in `ad_modules` mit Startwerten der Rechtevorlagen; Namensfunktionen für die Anwesenheitserfassung (Namen zu Personen-IDs, Suche über Aktive); Anlegen von Aktiven aus der Anwesenheitserfassung; Stammdaten Orte mit Pflege durch den Admin; **neu v0.9:** Module Planungshilfe Touren und Kurse und Freigabe Touren und Kurse mit Startwerten und Rechtevorlage „Freigabe Touren und Kurse“; Stammdaten Sätze und Pauschalen (Vergütungs- und Reisekostenordnung, Zahlungsgebühren, Emissionsfaktoren, Grenzwerte) mit Pflege durch den Admin; Lesefunktion Lizenzen gewählter Personen; Namensfunktionen für die Planungshilfe.

**Nicht im Scope:** E-Mails aus Fachabläufen; automatische Einladung; sofortiges Beenden der Frontend-Sitzung beim Sperren; Befristung von Zuweisungen in der Oberfläche; Rechte je Objekt, Einzelrechte, Reichweiten „Gruppe“ (vorgemerkt für Iteration 1 der Anwesenheitserfassung, Abschnitt 11) und „nur eigene“ (vorgemerkt für Iteration 2 der Planungshilfe); Reichweite „Referat“ für andere Module als EA, EZ, TK und TKF; Startkonfiguration Vorstand; Löschfunktionen in AD (auch für Qualifikationsarten, Referate, Gremien, Orte, Sätze); API-Key-Verwaltung (mit SC); Einstellungen; Personenakte; Excel-Import, Dublettenprüfliste, Zusammenführen; Oberflächen für Ehrenamtsstatus, Sicht je Referat, Gremium-Sichten, Filter, Ablaufdaten, Ablaufstatus, Stichtagsliste und Fortbildungen an Personen, Migration der Aktivenliste (alles EA); Tabellen und Oberflächen für Gruppen, Teilnahme, Erziehungsberechtigte, Notfallkontakte, Verträge (alles GR); Tabellen und Oberflächen für Einsätze und Anwesenheiten, Funktion `ez_person_visible` in endgültiger Form (alles EZ); Tabellen und Oberflächen für Planungen, Funktion `tk_person_visible` in endgültiger Form (alles TK); Pflege der Sätze durch Geschäftsstelle oder Referent:innen (später möglich); Löschlauf für Personen nach 5 Jahren (nach MVP, alle Module); Abgleich der Qualifikationsarten mit dem Bundesverband; Login für Aktive und Gruppenleitungen; SSO.

## 2. Datenmodell

Konventionen nach tech-stack.md: Schema `public`, snake_case, Präfix nach Modulkürzel, RLS auf jeder Tabelle. Die Tabellen des Personenmodells und die Stammdaten Referate und Gremien tragen das Präfix `ea_` (wie in tech-stack.md benannt), werden aber mit AD angelegt. Die Stammdaten der Qualifikationsarten, der Orte und der Sätze tragen das Präfix `ad_`, weil AD sie führt. Audit-Spalten `*_by` verweisen auf `auth.users(id)` und werden per Default `auth.uid()` bzw. Trigger gesetzt, nie vom Frontend.

Erweiterungen: `citext`, `pg_trgm`, `pg_cron`.

Typen:
- `ad_level` (Enum, Reihenfolge relevant): `none` < `read` < `edit` < `manage` (UI: kein Zugriff / lesen / bearbeiten / verwalten).
- `ad_access_status` (Enum): `none` (kein Zugang), `invited` (eingeladen), `active` (aktiv), `locked` (gesperrt).
- `ad_scope` (Enum, neu v0.7): `all` (alle), `referat` (Referat). Ersetzt den Text-Check auf `ad_template_rights.scope`. Der Wert `group` (Gruppe) kommt mit Iteration 1 der Anwesenheitserfassung (A6, Abschnitt 11).
- `ea_data_type` (Enum, v0.7 erweitert): `text`, `number`, `date`, `year`, `boolean`, `choice`, `qualification_type` (UI: Text, Zahl, Datum, Jahr, Ja/Nein, Auswahlliste, Qualifikationsart). Gilt je Feld.
- `ea_read_level` (Enum, neu v0.7): `all` (alle mit Zugriff), `office` (nur Geschäftsstelle und Admin), `confidential` (vertraulich).
- `ea_relation_kind` (Enum, neu v0.7): `none` (kein Bezug), `referat`, `gremium`, `group` (Gruppe; Bezugsspalte und Fremdschlüssel ergänzt die erste GR-Migration).
- `ea_property_category` (Enum, neu v0.7): `master_data` (Stammdaten), `contact` (Kontakt), `assignment` (Zuordnung), `qualification` (Qualifikationen), `proof` (Nachweise), `yearly` (Jahreseinträge), `issue` (Ausgaben), `external_access` (Zugänge), `other` (Sonstiges).
- `ea_volunteer_status` (Enum, neu v0.7): `active` (aktiv), `dormant` (ruhend), `left` (ausgeschieden).
- `ea_person_kind` (Enum): `human` (Mensch), `function` (Funktionsperson).
- `ad_audit_action` (Enum, v0.7 erweitert): `invited`, `email_changed`, `template_assigned`, `template_revoked`, `referate_changed`, `locked`, `unlocked`, `emergency_login`.
- `ad_qualification_kind` (Enum): `license` (Lizenz), `add_on` (Zusatzqualifikation), `course` (Lehrgang), `training` (Weiterbildung). UI-Bezeichnung des Felds: „Typ“.
- `ad_license_level` (Enum): `pre` (Vorstufe), `C`, `B`, `A`, `none` (ohne Stufe).
- `ad_qualification_status` (Enum): `current` (aktuell), `historic` (historisch).
- `ad_rate_group` (Enum, neu v0.9): `remuneration` (Vergütung), `travel` (Reisekosten), `fee` (Beitrag und Rundung), `payment_fee` (Zahlungsgebühr), `climate` (Klima und Emissionsfaktor), `threshold` (Grenzwert).

### ad_modules
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| code | text | ja | – | PK: AD, SC, EA, GR, EZ, TK, TKF, FI, OA, PM, GS, AM |
| name | text | ja | – | Anzeigename, z. B. „Administration“, „Anwesenheitserfassung“, „Planungshilfe Touren und Kurse“ |
| sort_order | int | ja | – | Reihenfolge auf der Startseite |
| is_available | boolean | ja | false | Modul umgesetzt; nur dann auf der Startseite. Im MVP nur AD = true |
| is_hidden | boolean | ja | false | **neu v0.9:** Modul ohne eigene Seiten (nur Recht); erscheint nie auf der Startseite und nicht in `ad_my_modules`, aber in der Vorlagen-Matrix |

Stammdaten per Migration. **v0.8:** Zeile `EZ` / „Anwesenheitserfassung“ / `is_available = false` per Migration der Administration (T50), nicht erst mit der ersten Migration der Anwesenheitserfassung, damit Startwerte und Reichweite vorher gesetzt und getestet werden können. `sort_order` direkt nach GR (bestätigt 24.10.2026). `is_available` setzt die Anwesenheitserfassung mit ihrer Freigabe.
**Neu v0.9 (T59):** Zeilen `TK` / „Planungshilfe Touren und Kurse“ / `is_available = false` / `is_hidden = false` (sort_order nach EZ) und `TKF` / „Freigabe Touren und Kurse“ / `is_available = false` / `is_hidden = true` (sort_order direkt nach TK). `is_available` für beide setzt die Planungshilfe mit ihrer Freigabe. TKF bildet das Freigaberecht im bestehenden Modell ab (Stufe „bearbeiten“ = darf freigeben), ohne eine neue Aktion einzuführen (Entscheidung Product Owner 22.10.2026: Freigabe delegierbar, vergeben durch den Admin; Umsetzung über TKF [ANNAHME]).

### ea_persons (bestehend; Änderungen v0.7 per neuer Migration)
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| first_name | text | ja | – | Vorname; getrimmt, nicht leer (R4) |
| last_name | text | ja | – | Nachname; getrimmt, nicht leer (R4) |
| preferred_name | text | nein | null | **neu** Rufname; getrimmt; leer → null. Anzeige „Rufname Nachname“, sonst „Vorname Nachname“; Suche über Vor-, Ruf- und Nachname |
| kind | ea_person_kind | ja | human | Funktionsperson nur durch AD (R15) |
| created_in | text | ja | 'AD' | **neu** Modul der Anlage: `AD`, `EA`, `GR`, `EZ` (neu v0.8), `script` (Check); nicht änderbar. Bestand bei der Migration: `AD`. Die Planungshilfe legt keine Personen an (v0.9) |
| volunteer_status | ea_volunteer_status | nein | null | **neu** aktueller Ehrenamtsstatus; null = kein Ehrenamtsstatus (Person gehört nicht zum Ehrenamtsmanagement). Nur über `ea_set_volunteer_status`, `ea_create_volunteer`, `ea_activate_person` oder ohne Nutzerkontext (Migrationsskript) änderbar (Trigger) |
| volunteer_status_since | date | nein | null | **neu** gültig ab; Check: beide null oder beide gesetzt |
| created_at | timestamptz | ja | now() | |
| created_by | uuid | nein | auth.uid() | null bei Migration/Skript |

Indizes: `gin (first_name gin_trgm_ops)`, `(lower(last_name))`, neu `gin (preferred_name gin_trgm_ops)`, `(volunteer_status) where volunteer_status is not null`.
Check (neu): `kind = 'function'` → `volunteer_status is null` (Funktionspersonen erhalten nie einen Ehrenamtsstatus, R15).

### ea_volunteer_status_history (neu v0.7)
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | bigint identity | ja | – | PK |
| person_id | uuid | ja | – | FK ea_persons(id) on delete cascade |
| status | ea_volunteer_status | ja | – | gesetzter Status |
| valid_from | date | ja | – | gültig ab |
| set_at | timestamptz | ja | now() | |
| set_by | uuid | nein | auth.uid() | null bei Skript |

Jeder Statuswechsel erzeugt eine Zeile (auch der erste). Kein direktes Schreiben für Nutzer. Index `(person_id, set_at desc)`.

### ea_referate (neu v0.7)
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| name | text | ja | – | eindeutig ohne Groß-/Kleinschreibung |
| sort_order | int | ja | – | Reihenfolge |
| is_active | boolean | ja | true | inaktive Referate sind nicht neu wählbar; kein Löschen |
| created_at / updated_at / updated_by | timestamptz / timestamptz / uuid | ja / nein / nein | now() / – / – | per Trigger |

Startbestand per Migration (TEST und PROD, keine Personendaten): Ausbildung, Touren, Kinder und Jugend, Klettern, Leistungssport, Karl-Stein-Hütte, Sulzenauhütte.

### ea_gremien (neu v0.7)
Aufbau wie `ea_referate`. Startbestand per Migration: Vorstand, Beirat, Ehrenrat, Jugendausschuss. Im Code getrennt von der Rechtevorlage „Vorstand“ und vom Amt.

### ad_locations (Orte, neu v0.8)
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| name | text | ja | – | Bezeichnung; getrimmt, nicht leer; eindeutig ohne Groß-/Kleinschreibung (unique index auf lower(name)) (R43) |
| has_climbing_points | boolean | ja | false | Kennzeichen „Punktekonto Kletterhalle“ (bestätigt 24.10.2026); die Anwesenheitserfassung liefert für Trainings an diesen Orten die Anwesenheit der Kinder zur Kontrolle des Punktekontos |
| is_active | boolean | ja | true | inaktive Orte sind nicht neu wählbar; vorhandene Einsätze behalten den Ort; kein Löschen |
| created_at / created_by | timestamptz / uuid | ja / nein | now() / auth.uid() | |
| updated_at / updated_by | timestamptz / uuid | nein | – | per Trigger |

Keine Personendaten. Kein Delete (keine Policy, kein Grant). Startbestand: keiner im Nachtrag v0.8 (Product Owner 24.10.2026). Den Startbestand liefert der Product Owner vor der Freigabe der Anwesenheitserfassung; dann per eigener Migration in TEST und PROD (`insert … on conflict do nothing` über lower(name)). Bis dahin in TEST nur Testorte aus dem Seed (Abschnitt 9). Die Anwesenheitserfassung verweist mit Fremdschlüssel auf `ad_locations(id)` (on delete restrict). Änderungen werden nicht protokolliert (nur updated_at/by).

### ad_rates (Sätze und Pauschalen, neu v0.9)
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| rate_key | text | ja | – | technischer Schlüssel (`^[a-zA-Z][a-zA-Z0-9_]{1,39}$`), z. B. `rOrg`, `fee_paypal`, `ef_rail_long`; Liste spec.md TK Abschnitt 7 |
| label | text | ja | – | Bezeichnung, z. B. „Organisationspauschale je Tag“ |
| rate_group | ad_rate_group | ja | – | Gruppe für die Anzeige |
| unit | text | ja | – | Einheit, z. B. „€“, „€/km“, „%“, „g je Personen-km“, „km“ |
| value | numeric(12,4) | nein | null | Wert; Pflicht außer bei `payment_fee` (Check); ≥ 0 |
| percent | numeric(6,3) | nein | null | nur `payment_fee`: Prozentsatz (Check); ≥ 0 |
| fixed | numeric(10,2) | nein | null | nur `payment_fee`: fester Betrag je Zahlung; ≥ 0 |
| active | boolean | ja | true | nur bei `payment_fee` fachlich genutzt (Zahlmethode in Yolawo aktiv) |
| valid_from | date | ja | – | gültig ab |
| source | text | ja | – | Quelle, z. B. „Vergütungsordnung 2025, Anhang 1“ |
| note | text | nein | null | Hinweis |
| created_at / created_by, updated_at / updated_by | | | | Audit |

Unique `(rate_key, valid_from)` (R46). Je Schlüssel mehrere Zeilen mit unterschiedlichem `valid_from` (Historie). Kein Delete (keine Policy, kein Grant); eine falsche Zeile wird korrigiert, nicht gelöscht. Startbestand per Migration in TEST und PROD (T61): alle Schlüssel aus spec.md TK Abschnitt 7 mit den Werten aus specs/tk-touren-kurse/prototyp-tourenkonzept.md 5.1–5.4, `valid_from = 2026-01-01` [OFFEN: echte Gültig-ab-Daten], `insert … on conflict (rate_key, valid_from) do nothing`. Keine Stornoregel (Entscheidung Product Owner 22.10.2026). Finanzen nutzt dieselben Sätze der Vergütungsordnung (keine eigene Tabelle). Änderungen werden nicht protokolliert (nur updated_at/by) [ANNAHME].

### ea_property_types (v0.7 neu gefasst; noch nicht umgesetzt)
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| name | text | ja | – | eindeutig ohne Groß-/Kleinschreibung (unique index auf lower(name)) |
| purpose | text | ja | – | Zweck, nicht leer (R9) |
| category | ea_property_category | ja | 'other' | Kategorie, nur Anzeige |
| read_level | ea_read_level | ja | 'all' | Lesestufe (R29); `confidential` setzen/ändern nur AD ≥ edit (Trigger) |
| relation_kind | ea_relation_kind | ja | 'none' | Bezug; nicht änderbar, sobald Eigenschaften existieren (Trigger) |
| relation_required | boolean | ja | false | Bezug Pflicht; nur bei relation_kind ≠ none (Check) |
| allow_multiple | boolean | ja | true | mehrere gleichzeitig gültige Eigenschaften dieser Art je Person erlaubt (R37) |
| system_key | text | nein | null | unique; Kennung für Eigenschaftsarten, auf die Code verweist; nur per Migration bzw. ohne Nutzerkontext setzbar. Schlüssel und Feldschlüssel legt die erste EA-Migration nach specs/ea-ehrenamt/01-erhebung.md C2 fest (v0.7.2). Von der Administration genutzt: `birth_date` (Feld `date`), `contact` (Felder `email`, `dav_email`), v0.8: `function` (Feld `function`, Wert „Helfer:in“), v0.9: `license` (Felder `qualification_type`, `valid_until`) |
| valid_from_label | text | nein | null | **neu v0.7.2 (Ü1):** Bezeichnung für „gültig von“ in Formular und Anzeige, z. B. „Amtszeit von“, „ausgegeben am“; getrimmt, leer → null; höchstens 40 Zeichen (Check `char_length(valid_from_label) <= 40`, R49) |
| valid_to_label | text | nein | null | **neu v0.7.2 (Ü1):** Bezeichnung für „gültig bis“, z. B. „beendet am“, „zurückgegeben am“; Regeln wie valid_from_label |
| visible_in | text[] | ja | – | ≥ 1 Modulcode aus ad_modules; nur Anzeige |
| origin | text | ja | 'custom' | 'system' oder 'custom' |
| created_at / created_by | timestamptz / uuid | ja / nein | now() / auth.uid() | |
| updated_at / updated_by | timestamptz / uuid | nein | – | per Trigger |

Entfällt gegenüber v0.6: `data_type`, `choice_values`, `allowed_qualification_kinds` (→ ea_property_fields), `confidential` (→ `read_level = 'confidential'`).
`valid_from_label` und `valid_to_label` (v0.7.2): Trimmen und leer → null in `ea_save_property_type` und per Trigger (auch bei direktem Schreiben ohne Nutzerkontext); Rechte wie die übrigen Spalten; kein Einfluss auf RLS. Startwerte für die System-Eigenschaftsarten setzt die erste EA-Migration (01-erhebung.md EA C2a).
Anlegen und Ändern: AD ≥ edit oder EA = manage (Reichweite „alle“); `relation_kind = 'group'` zusätzlich GR = manage [ANNAHME]; `read_level = 'confidential'` nur AD ≥ edit.

### ea_property_fields (neu v0.7)
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| property_type_id | uuid | ja | – | FK ea_property_types(id) on delete restrict |
| key | text | ja | – | technischer Schlüssel im Wert (`^[a-z][a-z0-9_]{0,39}$`), unique je Eigenschaftsart; aus der Bezeichnung vorgeschlagen; nach Anlage nicht änderbar |
| label | text | ja | – | Bezeichnung in der Oberfläche; unique je Eigenschaftsart ohne Groß-/Kleinschreibung |
| data_type | ea_data_type | ja | – | nicht änderbar, sobald Eigenschaften der Art existieren (R36) |
| is_required | boolean | ja | false | Pflichtfeld |
| choice_values | text[] | nein | null | Pflicht und ≥ 1 Wert bei `choice`, sonst null (Check); Werte dürfen ergänzt, nicht entfernt werden (Trigger) |
| allowed_qualification_kinds | ad_qualification_kind[] | nein | null | nur bei `qualification_type`, sonst null (Check); null = alle Typen erlaubt (R28) |
| sort_order | int | ja | – | Reihenfolge im Formular |
| created_at / updated_at / updated_by | timestamptz / timestamptz / uuid | ja / nein / nein | now() / – / – | per Trigger |

Jede Eigenschaftsart hat mindestens ein Feld (Prüfung beim Speichern über `ea_save_property_type`, R9). Felder werden nicht gelöscht. Neue Felder an Eigenschaftsarten mit vorhandenen Eigenschaften dürfen nicht Pflicht sein (R36). Lesen und Schreiben wie ea_property_types.

### ea_properties (v0.7 neu gefasst; noch nicht umgesetzt)
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| person_id | uuid | ja | – | FK ea_persons(id) |
| property_type_id | uuid | ja | – | FK ea_property_types(id), on delete restrict |
| field_values | jsonb | ja | '{}' | Werte je Feld: `{ "<key>": <wert> }`; Text und Auswahl als String, Zahl als Zahl, Datum als `YYYY-MM-DD`, Jahr als Zahl, Ja/Nein als boolean, Qualifikationsart als uuid-String |
| related_referat_id | uuid | nein | null | FK ea_referate(id); nur bei relation_kind `referat` |
| related_gremium_id | uuid | nein | null | FK ea_gremien(id); nur bei relation_kind `gremium` |
| valid_from | date | ja | – | gültig von (Bezeichnung in der Oberfläche: `valid_from_label` der Eigenschaftsart, sonst „gültig von“, R49) |
| valid_to | date | nein | – | gültig bis (Bezeichnung: `valid_to_label`, sonst „gültig bis“); Check valid_to ≥ valid_from |
| created_at / created_by | timestamptz / uuid | ja / nein | now() / auth.uid() | |
| updated_at / updated_by | timestamptz / uuid | ja / nein | now() / auth.uid() | |

`related_group_id` (FK auf die Gruppentabelle) ergänzt die erste GR-Migration (A4 der Übergabe aus GR).
Trigger `ea_properties_validate` (before insert/update) prüft R35, R37, R38 sowie R27/R28 je Feld vom Typ Qualifikationsart: Existenz der Qualifikationsart (sonst `EA_VALUE_TYPE`); Status `current`, wenn das Feld neu gesetzt oder geändert wird (sonst `AD_QUALIFICATION_HISTORIC`, R27; nicht geprüft ohne Nutzerkontext, d. h. `auth.uid() is null` bei Migration, Seed und Migrationsskript der Aktivenliste, damit Altbestand übernommen werden kann); Typ in `allowed_qualification_kinds`, falls gesetzt (sonst `AD_QUALIFICATION_KIND`, R28). Änderungen anderer Werte einer Eigenschaft mit historischer Qualifikationsart bleiben erlaubt.
Indizes: `(person_id)`, `(property_type_id)`, `(related_referat_id) where related_referat_id is not null`, `(related_gremium_id) where related_gremium_id is not null`, `gin (field_values jsonb_path_ops)`.

### ea_property_history (v0.7 neu gefasst)
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | bigint identity | ja | – | PK |
| property_id | uuid | ja | – | FK ea_properties(id) on delete cascade |
| field_values | jsonb | ja | – | Fassung vor der Änderung |
| related_referat_id / related_gremium_id | uuid | nein | – | Fassung vor der Änderung (GR ergänzt related_group_id) |
| valid_from / valid_to | date | ja / nein | – | Fassung vor der Änderung |
| changed_at | timestamptz | ja | now() | Zeitpunkt der Ablösung |
| changed_by | uuid | nein | auth.uid() | |

Trigger `ea_properties_history` (after update): schreibt die alte Fassung. Keine direkten Schreibrechte für Nutzer.

### ad_qualification_types (Qualifikationsarten)
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| code | text | nein | null | Kürzel, z. B. TCSPI; getrimmt, nur Großbuchstaben und Ziffern, max. 10 Zeichen (Check, R22) |
| name | text | ja | – | Bezeichnung; getrimmt, nicht leer (R21) |
| discipline | text | ja | – | Sparte (Klassifizierung des Bundesverbands, kein Bezug zu Referaten); Startwerte: Klettersport, Bergsport Sommer, Berg- und Klettersport Winter, Jugend und Familie; neue Werte möglich |
| kind | ad_qualification_kind | ja | – | Typ |
| level | ad_license_level | nein | null | Lizenzstufe; Pflicht bei `license`, sonst null (Check, R23) |
| specification | text | nein | null | Spezifikation (Fachrichtung) |
| issuer | text | ja | 'Bundesverband' | Aussteller; Startwerte: Bundesverband, Bundesverband (JDAV); weitere möglich (z. B. Landessportbund) |
| dosb_eligible | boolean | nein | null | DOSB-lizenzfähig; null = nicht bekannt. v0.9: Grundlage für „förderfähig“ in `ea_person_licenses` [ANNAHME, glossar.md „Lizenz“] |
| validity_years | smallint | nein | null | Gültigkeitsdauer in Jahren (bei DAV-Lizenzen = Fortbildungsintervall); Pflicht bei `license`, 1–10; bei `add_on` und `course` null (Check, R24) |
| status | ad_qualification_status | ja | 'current' | R25 |
| note | text | nein | null | Hinweis |
| source_ref | text | nein | null | Quell-ID aus dem Export des Bundesverbands; nur Migration, in der Oberfläche nur lesen |
| created_at / created_by | timestamptz / uuid | ja / nein | now() / auth.uid() | |
| updated_at / updated_by | timestamptz / uuid | nein | – | per Trigger |

Indizes: unique `lower(name)`; unique `lower(code) where code is not null`; unique `source_ref where source_ref is not null`; `(discipline, kind)`.
Kein Delete (keine Policy, kein Grant).
Startbestand per Migration (T27): 47 Einträge aus specs/ea-ehrenamt/stammdaten-qualifikationsarten.md v0.2, Abschnitt 3; `insert … on conflict (source_ref) do nothing`, damit Änderungen aus der Oberfläche nie überschrieben werden. Einträge mit [ANNAHME] im Status werden mit dem genannten Status angelegt; PSA (Status [OFFEN]) mit `historic`, bis der Product Owner entscheidet. Kürzel mit [ANNAHME] (TBEK, JL) werden übernommen. Die Migration enthält keine Personendaten und läuft deshalb in TEST und PROD.
Verweise aus Eigenschaften liegen v0.7 in `ea_properties.field_values` (ohne Fremdschlüssel); `ea_properties_validate` prüft die Existenz. Qualifikationsarten werden nie gelöscht.

### ad_templates (Rechtevorlagen)
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| name | text | ja | – | eindeutig ohne Groß-/Kleinschreibung |
| description | text | nein | – | |
| created_at / created_by, updated_at / updated_by | | | | |

Startwerte per Migration: „Admin“, „Geschäftsstelle“, „Vorstand“ (US-AD-01 AK1); v0.7: „Referent:in“ (US-AD-20); **neu v0.9:** „Freigabe Touren und Kurse“ (Beschreibung „Darf Touren und Kurse des zugewiesenen Referats freigeben, bearbeiten und Rückfragen stellen.“).

### ad_template_rights
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| template_id | uuid | ja | – | FK ad_templates(id) on delete cascade |
| module_code | text | ja | – | FK ad_modules(code) |
| object | text | nein | null | für Rechte je Objekt nach MVP; im MVP Check `object is null` |
| scope | ad_scope | ja | 'all' | Reichweite; v0.9: Check `scope = 'all' or (scope = 'referat' and module_code in ('EA','EZ','TK','TKF'))` (R30) |
| level | ad_level | ja | 'none' | Stufe; bei TKF nur `none` oder `edit` (Check, neu v0.9) |

Unique: `(template_id, module_code, coalesce(object, ''))`. Je Vorlage wird für jedes Modul eine Zeile geführt; die Migration T50 ergänzt für jede vorhandene Vorlage (auch vom Admin selbst angelegte) eine Zeile EZ mit `none`, außer den Startwerten; **T59 ebenso für TK und TKF.**
Startwerte: Admin = AD, SC, EA `manage`, **GR `read` (v0.7, E5)**, **EZ `read` (v0.8, A1)**, **TK `read` (neu v0.9)**, TKF `none`, übrige `none`; Geschäftsstelle = EA, GR, **EZ (v0.8)**, **TK (neu v0.9)**, FI, OA, PM, GS, AM `manage`, AD/SC/TKF `none`; Vorstand = alle `none` (Ziel laut Product Owner: EZ lesen, vom Admin zu setzen); **Referent:in (v0.7) = EA `edit` mit scope `referat`, EZ `edit` mit scope `referat` (v0.8), TK `edit` mit scope `referat` (neu v0.9), übrige `none`**; **Freigabe Touren und Kurse (neu v0.9) = TKF `edit` mit scope `referat`, übrige `none`**. Alle Startwerte mit scope `all`, außer Referent:in EA, EZ, TK und Freigabe TKF. Die Startwerte für EZ, TK und TKF setzt die Migration nur, wenn die Zeile noch nicht existiert bzw. noch `none` ist (keine Überschreibung von Änderungen des Admins).

### ad_template_assignments
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| person_id | uuid | ja | – | FK ea_persons(id) |
| template_id | uuid | ja | – | FK ad_templates(id) |
| valid_from / valid_to | date | nein | null | nur Datenmodell; im MVP nicht in der Oberfläche |
| assigned_at / assigned_by | timestamptz / uuid | ja / nein | now() / auth.uid() | |
| revoked_at / revoked_by | timestamptz / uuid | nein | – | gesetzt beim Entziehen (kein Löschen) |

Unique (partiell): `(person_id, template_id) where revoked_at is null`. Wirksam ist eine Zuweisung, wenn `revoked_at is null` und das heutige Datum in [valid_from, valid_to] liegt (null = offen).

### ad_assignment_referate (neu v0.7)
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| assignment_id | uuid | ja | – | FK ad_template_assignments(id) on delete cascade |
| referat_id | uuid | ja | – | FK ea_referate(id) |

PK `(assignment_id, referat_id)`. Referate einer Zuweisung, deren Vorlage mindestens ein Recht mit scope `referat` hat (R31). Die Referate gelten für alle Module der Vorlage mit scope `referat` gemeinsam (v0.8: EA und EZ; v0.9: zusätzlich TK; A2 der Übergabe aus EZ). Die Vorlage „Freigabe Touren und Kurse“ hat eigene Zuweisungen mit eigenen Referaten. Schreiben nur über `ad_assign_template` und `ad_set_assignment_referate`. Lesen: AD ≥ read; der Nutzer selbst über `ad_my_referate`.

### ad_accesses (Zugänge)
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| person_id | uuid | ja | – | FK ea_persons(id), unique (ein Zugang je Person) |
| login_email | citext | ja | – | unique (R2); R1 per Trigger `ad_accesses_guard` über `ad_login_email_allowed()` (kein Check-Constraint); direkt änderbar nur bei Status `none`; bei `invited` nur über `ad-access` (`change_email`); sonst Fehler (Trigger, R20) |
| status | ad_access_status | ja | 'none' | |
| auth_user_id | uuid | nein | – | FK auth.users(id) on delete set null, unique; gesetzt bei Einladung |
| is_emergency | boolean | ja | false | Notfall-Admin; partieller Unique-Index `where is_emergency` |
| last_invited_at | timestamptz | nein | – | zuletzt eingeladen am |
| locked_at / locked_by | timestamptz / uuid | nein | – | |
| created_at / created_by | timestamptz / uuid | ja / nein | now() / auth.uid() | |

Personen ohne Zeile in ad_accesses haben den Status „kein Zugang“.

### ad_test_login_domains (nur TEST)
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| domain | citext | ja | – | PK; zusätzlich erlaubte Domain für Login-Adressen, ohne „@“ (z. B. die Domain der privaten Adresse des Product Owners) |
| created_at | timestamptz | ja | now() | |

In PROD immer leer. Befüllt nur der Product Owner in TEST per SQL-Editor im Supabase-Dashboard; nie per Migration, Seed oder Repo. RLS an, keine Policies, keine Grants an `authenticated` oder `anon`.

### ad_audit_log (Protokoll)
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | bigint identity | ja | – | PK |
| occurred_at | timestamptz | ja | now() | |
| actor_user_id | uuid | nein | auth.uid() | ausgeführt von (bei emergency_login der Notfall-Admin selbst) |
| subject_person_id | uuid | ja | – | betroffene Person, FK ea_persons(id) |
| action | ad_audit_action | ja | – | |
| details | text | nein | – | z. B. Name der Vorlage; bei `template_assigned` und `referate_changed` zusätzlich die Referate |

Index: `(occurred_at desc)`, `(action, occurred_at desc)`. Einträge nur über Security-Definer-Funktionen und Trigger; kein Insert/Update/Delete für Nutzer (US-AD-14 AK4). Änderungen an Qualifikationsarten, Referaten, Gremien, Orten und Sätzen werden nicht protokolliert (nur updated_at/by). Wechsel des Ehrenamtsstatus stehen in `ea_volunteer_status_history`, nicht im Protokoll. Vergabe und Entzug der Vorlage „Freigabe Touren und Kurse“ werden wie jede Vorlage protokolliert (v0.9).

### ad_notice_acks
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| user_id | uuid | ja | auth.uid() | PK, FK auth.users(id) |
| emergency_acknowledged_until | timestamptz | ja | – | Zeitpunkt „Zur Kenntnis genommen“ |

### Views (security_invoker = true)
- `ad_v_person_overview`: Person (inkl. Rufname), Art, Login-Adresse, Zugangsstatus (`coalesce(status,'none')`), Ehrenamtsstatus, Gruppenbezug ja/nein (ab erster GR-Migration über `gr_person_visible`-Logik; bis dahin `created_in = 'GR'`) [ANNAHME], Liste der wirksamen Vorlagen mit Referaten. Für US-AD-06. Zeigt durch RLS nur Personen, die der Nutzer lesen darf (R32; Admin: alle).
- `ea_v_persons`: nur `kind = 'human'`. Alle Fachmodule lesen Personen über diese View (R15). Welche Zeilen ein Nutzer sieht, entscheidet die RLS auf ea_persons (R32). Ausnahme v0.8/v0.9: Anwesenheitserfassung und Planungshilfe lesen Namen über `ea_person_names` und `ea_search_active_persons` (R44, R48), nicht über die View.

### Funktionen
Rechte und Stammdaten:
- `ad_user_level(p_module text) returns ad_level` – security definer, stable: höchste Stufe aller wirksamen Zuweisungen des aufrufenden Nutzers für das Modul **mit Reichweite `all`**; `none`, wenn kein Zugang mit Status `active` besteht (R5, R6). Rechte mit Reichweite `referat` zählen hier nicht (R30).
- `ad_has_level(p_module text, p_min ad_level) returns boolean` – Hilfsfunktion für RLS; Reichweite `all`.
- `ad_my_referate(p_module text, p_min ad_level) returns uuid[]` – **neu**, security definer, stable: Referate aus allen wirksamen Zuweisungen des aufrufenden Nutzers, deren Vorlage für das Modul ein Recht mit scope `referat` und Stufe ≥ p_min hat; leer ohne aktiven Zugang. Gilt ab v0.8 auch für `p_module = 'EZ'` (genutzt von der Anwesenheitserfassung und von `gr_group_roster`, R20 der Erhebung Gruppen), ab v0.9 für `TK` und `TKF` (Planungshilfe; Freigaberecht = `ad_my_referate('TKF','edit')`).
- `ad_has_any_level(p_module text, p_min ad_level) returns boolean` – **neu**: `ad_has_level(...)` oder `cardinality(ad_my_referate(...)) > 0`; für Navigation und Routenschutz.
- `ad_has_active_access() returns boolean` – security definer, stable: wahr, wenn der aufrufende Nutzer einen Zugang mit Status `active` hat; für das Lesen der Qualifikationsarten, Referate, Gremien und Orte.
- `ad_can_edit_qualification_types() returns boolean` – `ad_has_level('AD','edit') or ad_has_level('EA','manage')`; für RLS und Oberfläche.
- `ad_can_edit_locations() returns boolean` – **neu v0.8**: `ad_has_level('AD','edit')` (nur Admin, Product Owner 22.10.2026); für RLS und Oberfläche.
- `ad_can_edit_rates() returns boolean` – **neu v0.9**: `ad_has_level('AD','edit')` (nur Admin, Product Owner 22.10.2026); zentrale Stelle, damit Geschäftsstelle oder Referent:innen später ohne Umbau ergänzt werden können; für RLS und Oberfläche.
- `ad_can_read_rates() returns boolean` – **neu v0.9**: `ad_has_level('AD','read') or ad_has_any_level('TK','read') or ad_has_any_level('TKF','edit') or ad_has_level('FI','read')`.
- `ad_rates_at(p_date date) returns setof (rate_key text, label text, rate_group ad_rate_group, unit text, value numeric, percent numeric, fixed numeric, active boolean, valid_from date, source text)` – **neu v0.9**, security definer, stable: je `rate_key` die Zeile mit dem spätesten `valid_from <= p_date`; Schlüssel ohne gültige Zeile fehlen (die Planungshilfe meldet sie, R3 der Spec TK). Erlaubt mit `ad_can_read_rates()`, sonst `AD_FORBIDDEN`.
- `ad_qualification_usage(p_id uuid) returns int` – security definer, stable: Anzahl verschiedener Personen mit einer Eigenschaft, deren `field_values` auf die Qualifikationsart verweist (auch über vertrauliche Eigenschaftsarten, nur die Zahl, keine Namen); erlaubt, wenn `ad_can_edit_qualification_types()`.
- `ad_my_modules() returns setof (code, name, level)` – für Startseite und Navigation; nur Module mit `is_available`, **nicht `is_hidden` (v0.9)**, und `ad_has_any_level(code,'read')`; level = höchste Stufe über beide Reichweiten. Für TK gilt zusätzlich: wer nur TKF hat, sieht die Kachel TK (`ad_has_any_level('TKF','edit')`) [ANNAHME].
- `ad_me() returns (person_id uuid, first_name text, last_name text, preferred_name text, access_status ad_access_status)` – security definer, stable: nur die eigene Person und der eigene Zugang des aufrufenden Nutzers; für Kopfzeile und Startseite (alle angemeldeten Nutzer). v0.7 um Rufname ergänzt.
- `ad_assign_template(p_person uuid, p_template uuid, p_referate uuid[] default null)` – prüft AD ≥ edit; hat die Vorlage ein Recht mit scope `referat` (in EA, EZ, TK oder TKF), ist p_referate mit ≥ 1 aktivem Referat Pflicht (R31), sonst muss es null oder leer sein; schreibt Zuweisung, ad_assignment_referate und Protokoll `template_assigned` (Details: Vorlage, Referate).
- `ad_set_assignment_referate(p_assignment uuid, p_referate uuid[])` – **neu**, prüft AD ≥ edit und R31; ersetzt die Referate; Protokoll `referate_changed` (Details: vorher → nachher).
- `ad_revoke_template(p_person uuid, p_template uuid)` – prüft AD ≥ edit, schreibt Entzug und Protokoll.
- `ad_acknowledge_emergency()` – prüft AD ≥ read; setzt ad_notice_acks.
- `ad_pending_emergency_logins() returns (count int, last_at timestamptz)` – prüft AD ≥ read; Anmeldungen des Notfall-Admins nach `emergency_acknowledged_until`.
- Interne Funktionen für Statuswechsel des Zugangs (`ad_apply_invite`, `ad_apply_lock`, `ad_apply_unlock`) – security definer; `grant execute` nur an `service_role`, aufgerufen ausschließlich von den Edge Functions.
- `ad_user_level` und `ad_has_level` entstehen in der ersten Migration (T1), damit jede folgende Tabelle ihre Policies direkt mitbringt; `ad_my_referate`, `ad_has_any_level` und die geänderte Fassung von `ad_user_level` in T33.
- `ad_login_email_allowed(p_email citext) returns boolean` – security definer, stable: wahr, wenn die Adresse auf `@dav-leipzig.de` endet oder ihre Domain in `ad_test_login_domains` steht (R1). Genutzt vom Trigger `ad_accesses_guard` und von den Edge Functions `ad-invite` und `ad-access`.
- `ad_login_email_ok(p_email citext) returns boolean` – **neu v0.7.4**, security definer, stable: dieselbe Prüfung für das Frontend, bevor eine Person mit Login-Adresse angelegt wird (US-AD-07 AK5); erlaubt mit AD ≥ edit, EA ≥ edit (beide Reichweiten) oder GR ≥ edit, sonst `AD_FORBIDDEN`. Die Liste der Testdomains bleibt unsichtbar (nur Ja/Nein).

Sichtbarkeit (neu v0.7, R32; alle security definer, stable, fester `search_path`):
- `ea_person_in_referate(p_person uuid, p_referate uuid[]) returns boolean` – wahr, wenn die Person eine heute gültige Eigenschaft (valid_from ≤ heute, valid_to null oder ≥ heute) mit `related_referat_id = any(p_referate)` hat.
- `ea_person_visible_ad(p_person uuid) returns boolean` – `ad_has_level('AD','read')`; der Admin sieht alle Personen aller Module (v0.7.1, Entscheidung Product Owner: Vollständigkeit). `created_in` dient nur der Anzeige und Auswertung.
- `ea_person_visible_ea(p_person uuid, p_min ad_level default 'read') returns boolean` – Person `kind = 'human'` und `volunteer_status is not null` und (
  (`ad_has_level('EA', p_min)` und (`volunteer_status <> 'left'` oder `ad_has_level('EA','manage')`))
  oder (`volunteer_status <> 'left'` und `ea_person_in_referate(p_person, ad_my_referate('EA', p_min))`)).
- `gr_person_visible(p_person uuid, p_min ad_level default 'read') returns boolean` – Platzhalter, liefert `false`; die erste GR-Migration ersetzt die Funktion (`create or replace`) mit derselben Signatur (Gruppenbezug: Teilnahme, Erziehungsberechtigung, Notfallkontakt oder Eigenschaft mit Bezug auf eine Gruppe) [ANNAHME].
- `ea_person_visible(p_person uuid) returns boolean` – Oder-Verknüpfung der drei Pfade AD, EA, GR; Grundlage der Policies. **v0.8: Die Anwesenheitserfassung ist bewusst kein vierter Pfad**, weil sie nur Namen sehen darf (A3); ein RLS-Pfad auf `ea_persons` würde zusätzlich Ehrenamtsstatus und Anlagemodul freigeben. **v0.9: ebenso die Planungshilfe** (Namen und Lizenzen nur über Funktionen, R47, R48).
- `ea_property_readable(p_property_type uuid, p_person uuid) returns boolean` – nach R29: `confidential` → nur Pfad AD; `office` → Pfad AD oder (Pfad EA und `ad_has_level('EA','manage')`) oder (Pfad GR und `ad_has_level('GR','manage')`); `all` → irgendein Pfad.
- `ea_property_writable(p_property_type uuid, p_person uuid, p_referat uuid) returns boolean` – nach R42: lesbar und (AD ≥ edit im Pfad AD oder EA ≥ edit im Pfad EA – bei Reichweite Referat zusätzlich Bezug-Referat ∈ `ad_my_referate('EA','edit')` (R41) – oder GR ≥ edit im Pfad GR); `confidential` nur AD ≥ edit; `relation_kind = 'group'` nur GR ≥ edit (R39). Wird von den Policies für alte und neue Fassung aufgerufen.

Namen für Anwesenheitserfassung und Planungshilfe (v0.8 A3, R44; v0.9 R48; security definer, stable, fester `search_path`):
- `ez_person_visible(p_person uuid) returns boolean` – Platzhalter, liefert `false`; die erste Migration der Anwesenheitserfassung ersetzt die Funktion (`create or replace`) mit derselben Signatur. Inhalt nach spec.md EZ v0.4 Abschnitt 2 (v0.8.1, Product Owner 24.10.2026): wahr, wenn die Person in einem für den Nutzer lesbaren Einsatz als Anwesenheit, organisierende Person oder als Person, die den Einsatz angelegt oder geändert hat, vorkommt. Namen vor dem Speichern eines Einsatzes kommen über `gr_group_roster` und `ea_search_active_persons` (Datensparsamkeit).
- `tk_person_visible(p_person uuid) returns boolean` – **neu v0.9**, Platzhalter, liefert `false`; die erste Migration der Planungshilfe ersetzt die Funktion mit derselben Signatur (Person ist Leitung oder Helfer:in in einer für den Nutzer lesbaren Planung; spec.md TK T2).
- `ea_person_names(p_ids uuid[]) returns setof (id uuid, first_name text, preferred_name text, last_name text)` – liefert nur Menschen (`kind = 'human'`), für die `ea_person_visible(id) or ez_person_visible(id) or tk_person_visible(id)` (v0.9) wahr ist; andere IDs werden ohne Fehler ausgelassen. Höchstens 500 IDs je Aufruf, sonst Fehler `AD_TOO_MANY_IDS` (bestätigt 24.10.2026; nur bei einem Programmierfehler, die Oberfläche zeigt die allgemeine Meldung von `AD_UNEXPECTED`). Keine weiteren Spalten.
- `ea_search_active_persons(p_query text, p_limit int default 20) returns setof (id uuid, first_name text, preferred_name text, last_name text)` – erlaubt mit `ad_has_any_level('EZ','edit')` **oder (v0.9) `ad_has_any_level('TK','edit')` oder `ad_has_any_level('TKF','edit')`**, sonst Fehler `AD_FORBIDDEN`; sucht in Menschen mit `volunteer_status = 'active'` über Vor-, Ruf- und Nachname (Teilwort, ohne Groß-/Kleinschreibung, `pg_trgm`); p_query getrimmt mindestens 2 Zeichen, sonst `AD_SEARCH_TOO_SHORT`; p_limit 1–50; Sortierung Nachname, Rufname bzw. Vorname. Für die Auswahl der organisierenden Person und für Vertretungen über Referatsgrenzen hinweg (Product Owner, 22.10.2026) sowie für die Leitung von Touren und Kursen (v0.9). Liefert keine Referate, Funktionen oder sonstigen Eigenschaften.

Lizenzen für die Planungshilfe (neu v0.9, R47; security definer, stable, fester `search_path`):
- `ea_person_licenses(p_person_ids uuid[], p_date date) returns setof (person_id uuid, qualification_type_id uuid, qualification_code text, qualification_name text, valid_until date, is_fundable boolean, valid_on_date boolean)` – erlaubt mit `ad_has_any_level('TK','read')` oder `ad_has_any_level('TKF','edit')`, sonst `AD_FORBIDDEN`; höchstens 50 IDs (`AD_TOO_MANY_IDS`); nur Menschen mit Ehrenamtsstatus „aktiv“ oder „ruhend“; liefert je Person alle heute oder am p_date gültigen Eigenschaften der Art mit `system_key = 'license'`, deren Feld vom Typ Qualifikationsart auf eine Qualifikationsart mit `kind = 'license'` verweist: Kürzel und Bezeichnung der Qualifikationsart, `valid_until` aus dem Feld `valid_until` der Eigenschaft (Pflichtfeld nach 01-erhebung.md EA C2 Nr. 9; v0.9.1: kein Rückfall auf `valid_to`, weil `valid_to` dort „beendet am“ bedeutet, nicht Ablauf; fehlt der Wert, wird `valid_until` null und `valid_on_date` wahr [ANNAHME]), `is_fundable = coalesce(dosb_eligible, false)` [ANNAHME: förderfähig = DOSB-lizenzfähig], `valid_on_date = valid_until is null or valid_until >= p_date`. Lesestufe der Eigenschaftsart muss `all` sein, sonst keine Zeile. Keine Lizenznummer, keine anderen Eigenschaften.

Ehrenamtsstatus und Anlegen (neu v0.7; Oberflächen in EA):
- `ea_set_volunteer_status(p_person uuid, p_status ea_volunteer_status, p_valid_from date default current_date)` – security definer: erlaubt, wenn `ea_person_visible_ea(p_person, 'edit')` (R33); setzt Status und schreibt ea_volunteer_status_history; sonst Fehler `EA_STATUS_FORBIDDEN`. Setzt keine Enddaten an Eigenschaften (das macht EA im Dialog, siehe Steckbrief EA).
- `ea_person_referate(p_person uuid) returns setof (id uuid, name text)` – security definer: aktuelle Referate der Person (Name), erlaubt, wenn `ea_person_visible_ea(p_person)`; für den Bestätigungsdialog „Die Person ist auch in … tätig“.
- `ea_create_volunteer(p_first text, p_last text, p_preferred text, p_property_type uuid, p_referat uuid, p_field_values jsonb, p_valid_from date, p_contact_email text default null) returns uuid` – security definer: legt in einer Transaktion Person, Ehrenamtsstatus „aktiv“ (Historie) und die erste Zuordnung (Eigenschaft der Art p_property_type mit Bezug auf p_referat) an. Erlaubt mit `ad_has_level('EA','edit')` oder p_referat ∈ `ad_my_referate('EA','edit')` (R41) – **neu v0.8 (A4, R45):** oder mit `ad_has_level('EZ','edit')` oder p_referat ∈ `ad_my_referate('EZ','edit')`. Mit Reichweite „alle“ (Geschäftsstelle, Admin) sind p_property_type und p_referat optional (z. B. Mitglied eines Gremiums ohne Referat); mit Reichweite „Referat“ Pflicht. Beim Aufruf nur über EZ-Rechte (kein passendes EA-Recht) gilt zusätzlich: p_referat ist Pflicht, p_property_type muss die Eigenschaftsart mit `system_key = 'function'` sein und p_field_values genau `{"function": "Helfer:in"}` sein (keine weiteren Feldschlüssel, auch nicht `training_units_per_week`), sonst `EA_CREATE_FORBIDDEN` (bestätigt 24.10.2026). Ohne passendes EA- oder EZ-Recht: `EA_CREATE_FORBIDDEN`; Reichweite „Referat“ und fremdes Referat: `EA_RELATION_FOREIGN_REFERAT`, für EA und EZ gleich (v0.8.1; `EA_CREATE_FOREIGN_REFERAT` entfällt). `created_in` = `'EZ'`, wenn der Aufruf nur über EZ-Rechte erlaubt ist, sonst `'EA'`. p_contact_email (neu v0.8, optional): legt zusätzlich eine Eigenschaft der Art mit `system_key = 'contact'` an, `field_values = {"email": <p_contact_email getrimmt>}`, gültig von = p_valid_from (R35 gilt; Feldschlüssel nach 01-erhebung.md EA C2 Nr. 4). Grund: Ohne Ehrenamtsstatus bzw. ohne Zuordnung wäre eine angelegte Person sofort unsichtbar. **v0.7.4:** `ea_create_volunteer` und `ea_activate_person` prüfen die Eigenschaftsart: Lesestufe „vertraulich“ nur mit AD ≥ edit (`AD_CONFIDENTIAL_ONLY_AD`), Bezug „Gruppe“ nie (`EA_GROUP_RELATION_ONLY_GR`), mit Reichweite „Referat“ nur Arten mit Bezug „Referat“ (`EA_RELATION_REQUIRED`); eine Art ohne Bezug „Referat“ zusammen mit p_referat ist `AD_BAD_REQUEST`. Die bestehende Signatur bleibt durch den Default-Parameter aufrufbar. Die Planungshilfe nutzt die Funktion nicht (v0.9: externe Leitende werden vorher im Ehrenamtsmanagement angelegt).
- `ea_activate_person(p_person uuid, p_property_type uuid, p_referat uuid, p_field_values jsonb, p_valid_from date)` – security definer: für die Rückkehr Ausgeschiedener und für Menschen, die schon in einem anderen Pfad existieren (z. B. Erziehungsberechtigte:r wird Trainer:in, E1): setzt Status „aktiv“ (Historie) und legt die Zuordnung an. Erlaubt wie `ea_create_volunteer` (R41). **Neu v0.8.1 (Übergabe EZ A9, R45a):** auch mit `ad_has_level('EZ','edit')` oder p_referat ∈ `ad_my_referate('EZ','edit')`. Die Prüfung steht in der Funktion selbst; sie entspricht `ez_can_write` der Anwesenheitserfassung, die es bei der Migration der Administration noch nicht gibt. Beim Aufruf nur über EZ-Rechte gilt wie bei `ea_create_volunteer`: p_referat ist Pflicht, p_property_type ist die Eigenschaftsart mit `system_key = 'function'` und p_field_values genau `{"function": "Helfer:in"}`, sonst `EA_CREATE_FORBIDDEN`; fremdes Referat `EA_RELATION_FOREIGN_REFERAT`. Über den EZ-Weg zulässig sind Personen mit Ehrenamtsstatus „ruhend“, „ausgeschieden“ oder ohne Ehrenamtsstatus (z. B. nur über Gruppen bekannt); bei „aktiv“ bleibt der Status und die Funktion wird ergänzt, wie im EA-Weg. Die Person muss für den Aufrufer nicht sichtbar sein und darf zuletzt in einem anderen Referat aktiv gewesen sein (Product Owner 24.10.2026). Aufrufer ist `ez_reactivate_helper` (spec.md EZ v0.4, R31). Die frühere Annahme „aus der Anwesenheitserfassung wird … nicht reaktiviert“ entfällt. Person muss `kind = 'human'` sein.
- Personen ohne Ehrenamtsstatus anlegen: AD ≥ edit (`created_in = 'AD'`) direkt; GR ≥ edit über eine Funktion der GR-Migration (A6).

Dublettenprüfung (v0.7 geändert, R40):
- `ad_first_names_match(p_a text, p_b text) returns boolean` – **neu v0.7.3**, immutable, ohne Tabellenzugriff: Beide Werte werden getrimmt und kleingeschrieben; leer oder null → false. Wahr, wenn (1) `similarity(a, b) >= 0.3` oder (2) einer im anderen vollständig enthalten ist (z. B. „jo“/„johanna“) oder (3) beide eine gemeinsame zusammenhängende Zeichenfolge von mindestens 3 Zeichen haben (z. B. „toni“/„anton“: „ton“; „ben“/„benjamin“). Umsetzung von (3) z. B. über `generate_series` und `strpos` auf allen Teilfolgen der Länge 3 des kürzeren Werts. Grant an `authenticated` [ANNAHME].
- `ad_find_similar_persons(p_first text, p_last text, p_email text) returns setof (person_id uuid, first_name text, last_name text, preferred_name text, birth_year int, volunteer_status ea_volunteer_status, left_since date, is_visible boolean)` – security definer: sucht in allen Personen `kind = 'human'` nach R3a (gleicher Nachname und `ad_first_names_match(p_first, first_name)` oder `ad_first_names_match(p_first, preferred_name)`; oder p_email ohne Groß-/Kleinschreibung gleich einer Login-Adresse oder dem Feld `email` bzw. `dav_email` einer Eigenschaft der Art mit `system_key = 'contact'` [ANNAHME v0.9.1, ersetzt „Kategorie Kontakt“]). Liefert nur die genannten Spalten; `birth_year` = Jahr aus dem Feld `date` der Eigenschaft der Art mit `system_key = 'birth_date'` (heute gültige Eigenschaft, sonst die mit dem spätesten valid_from [ANNAHME]; null, wenn es die Art oder die Eigenschaft nicht gibt). **v0.7.2 (Ü2, R40):** `birth_year` wird nur geliefert, wenn die Lesestufe der Art mit `system_key = 'birth_date'` es für den Aufrufer erlaubt: `all` → jeder berechtigte Aufrufer; `office` → `ad_has_level('AD','read') or ad_has_level('EA','manage') or ad_has_level('GR','manage')`; `confidential` → `ad_has_level('AD','read')`; sonst `null`. Die Prüfung hängt nicht davon ab, ob der Treffer für den Aufrufer sichtbar ist; `left_since` nur bei Status `left`; `is_visible = ea_person_visible(person_id)`. Aufrufbar mit AD ≥ edit, EA ≥ edit (beide Reichweiten), GR ≥ edit oder – **neu v0.8** – EZ ≥ edit (beide Reichweiten, `ad_has_any_level('EZ','edit')`). Schwelle wird in TEST mit Beispielen abgenommen (T25).

### Trigger auf auth.users (security definer, Schema public)
- after insert: Zugang mit gleicher `login_email` → `auth_user_id` setzen; Status `none` → `invited`. Gilt für `ad-invite` und für Einladungen über das Supabase-Dashboard (Ersteinrichtung, US-AD-01). **v0.7.4:** Beim Wechsel `none` → `invited` schreibt der Trigger einen Protokolleintrag `invited` ohne Akteur (Details „Einladung über das Supabase-Dashboard“); läuft die Einladung über `ad-invite`, vervollständigt `ad_apply_invite` diesen Eintrag mit dem Akteur statt einen zweiten anzulegen.
- after update of `encrypted_password`: war das Passwort leer und ist jetzt gesetzt und der Zugang `invited` → `active`. Ein eingelöster Link ohne gespeichertes Passwort ändert den Status nicht.
- after update of `last_sign_in_at`: ist `is_emergency` → Protokolleintrag `emergency_login` (R16, auch nach „Passwort vergessen“, US-AD-15 AK4).
- „Passwort gesetzt“ bedeutet in dieser Spec: `auth.users.encrypted_password` ist nicht leer.

### Zeitgesteuerte Jobs (pg_cron)
- täglich 01:15 UTC (pg_cron läuft in UTC; 02:15 bzw. 03:15 Ortszeit): `delete from ad_audit_log where occurred_at < now() - interval '5 years'` (R13).
- Löschlauf für Personen: nicht im MVP. Eine Person darf nur gelöscht werden, wenn kein Pfad sie mehr braucht (A8 der Übergabe aus GR); Regel folgt mit dem Löschlauf. Ab v0.8 zählt dazu auch die Anwesenheit bei Einsätzen (Aufbewahrung für Abrechnung und Nachweis, Frist [OFFEN] im Modul Anwesenheitserfassung), ab v0.9 die Leitung in Planungen der Planungshilfe.

## 3. Rechte / RLS

Grundsatz: Rechte werden bei jeder Abfrage über `ad_has_level` (Reichweite „alle“) bzw. `ad_my_referate` (Reichweite „Referat“) geprüft. Jede Tabelle erhält ihre Policies in der Migration, die sie anlegt; geänderte Policies auf bestehenden Tabellen per neuer Migration. Grants nur an `authenticated` (nie `anon`), interne Statusfunktionen nur an `service_role`. Da der Zugangsstatus Teil der Prüfung ist, enden Datenzugriffe nach Sperren oder Entziehen sofort; nur die Anmeldung im Frontend bleibt bis Ablauf des Zugriffstokens (bis zu 1 Stunde) bestehen. Das erfüllt R10 („spätestens“).

Stufen in AD: lesen = alles in AD ansehen inkl. Protokoll und vertraulicher Eigenschaften; bearbeiten = anlegen, ändern, einladen, sperren, entsperren, zuweisen; verwalten = wie bearbeiten (keine zusätzliche Funktion im MVP, da in AD nichts gelöscht wird).

**Lesepfade für Personen und Eigenschaften (R32, neu v0.7):** Eine Person ist für einen Nutzer lesbar, wenn mindestens ein Pfad zutrifft:

| Pfad | Bedingung Recht | Bedingung Person |
|---|---|---|
| AD | AD ≥ lesen | alle Personen (v0.7.1) |
| EA, Reichweite alle | EA ≥ lesen | Mensch mit Ehrenamtsstatus; „ausgeschieden“ nur mit EA = verwalten |
| EA, Reichweite Referat | EA ≥ lesen für mindestens ein Referat | Mensch mit Ehrenamtsstatus „aktiv“ oder „ruhend“ und heute gültiger Eigenschaft mit Bezug auf eines dieser Referate |
| GR | GR ≥ lesen | Gruppenbezug (Funktion `gr_person_visible`, ab erster GR-Migration) |

Anwesenheitserfassung (neu v0.8): kein Lesepfad auf `ea_persons` und `ea_properties`. Namen nur über `ea_person_names` (Bedingung `ez_person_visible`) und `ea_search_active_persons` (nur aktive Personen, nur mit EZ ≥ bearbeiten); Namen von Gruppen-Teilnehmer:innen über `gr_group_roster` (Modul Gruppen, R20 der Erhebung Gruppen). Eigenschaften, Kontaktdaten und Geburtsdaten sind über die Anwesenheitserfassung nie lesbar (R44).

Planungshilfe Touren und Kurse (neu v0.9): kein Lesepfad auf `ea_persons` und `ea_properties`. Namen nur über `ea_person_names` (Bedingung `tk_person_visible`) und `ea_search_active_persons` (nur mit TK ≥ bearbeiten oder TKF); Lizenzen nur über `ea_person_licenses` (R47). Keine Kontaktdaten, Geburtsdaten, Lizenznummern oder anderen Eigenschaften (R48).

Eigenschaften sind lesbar, wenn die Person über einen Pfad lesbar ist und die Lesestufe es in diesem Pfad erlaubt (R29):

| Lesestufe | Pfad AD | Pfad EA | Pfad GR |
|---|---|---|---|
| alle mit Zugriff | ja | ja | ja |
| nur Geschäftsstelle und Admin | ja | nur EA = verwalten (Reichweite alle) | nur GR = verwalten |
| vertraulich | ja | nein | nein |

„Sichtbar in“ steuert weiterhin nur die Anzeige, nicht den Zugriff.

| Tabelle / Objekt | Lesen | Anlegen | Ändern | Löschen |
|---|---|---|---|---|
| ad_modules | jeder angemeldete Nutzer | – | – | – |
| ad_templates, ad_template_rights | AD ≥ read | AD ≥ edit | AD ≥ edit | – |
| ad_template_assignments, ad_assignment_referate | AD ≥ read | nur über ad_assign_template | nur über ad_revoke_template, ad_set_assignment_referate | – |
| ad_accesses | AD ≥ read | AD ≥ edit | AD ≥ edit; Statuswechsel nur über Edge Functions/Trigger | – |
| ad_audit_log | AD ≥ read | nur System | – | nur pg_cron |
| ad_test_login_domains | – (nur über ad_login_email_allowed) | nur SQL-Editor in TEST | – | nur SQL-Editor in TEST |
| ad_notice_acks | eigene Zeile | eigene Zeile | eigene Zeile | – |
| ad_qualification_types | jeder Nutzer mit Zugang „aktiv“ (ad_has_active_access) | AD ≥ edit oder EA = manage | AD ≥ edit oder EA = manage; `source_ref` nur Migration | – |
| ad_locations (v0.8) | jeder Nutzer mit Zugang „aktiv“ (ad_has_active_access) | `ad_can_edit_locations()` | `ad_can_edit_locations()` | – |
| ad_rates (neu v0.9) | `ad_can_read_rates()` | `ad_can_edit_rates()` (nur Admin) | `ad_can_edit_rates()`; `rate_key` und `valid_from` nicht änderbar (Trigger) | – |
| ea_referate, ea_gremien | jeder Nutzer mit Zugang „aktiv“ | AD ≥ edit oder EA = manage [ANNAHME] | wie Anlegen | – |
| ea_persons | `ea_person_visible(id)` (R32) | AD ≥ edit direkt (created_in = AD); EA (beide Reichweiten) und EZ (beide Reichweiten, v0.8) nur über `ea_create_volunteer` bzw. `ea_activate_person` (v0.8.1), damit die Person sofort einen Ehrenamtsstatus hat; GR ≥ edit über GR-Funktion (A6); `kind = 'function'` nur AD | Namen und Rufname: wer die Person über einen Pfad mit ≥ edit lesen darf; `volunteer_status` nur über die EA-Funktionen (Trigger); `kind`, `created_in` nicht änderbar | – (Löschlauf nach MVP) |
| ea_volunteer_status_history | wie ea_persons | nur über EA-Funktionen | – | – |
| ea_property_types, ea_property_fields | AD ≥ read: alle; EA ≥ read (beide Reichweiten) oder GR ≥ read: nur `read_level <> 'confidential'` | AD ≥ edit oder EA = manage; `confidential` nur AD ≥ edit; `group` zusätzlich GR = manage [ANNAHME] | wie Anlegen; R36 | – |
| ea_properties | `ea_person_visible(person_id)` und `ea_property_readable(...)` | `ea_property_writable(...)`; aus der Anwesenheitserfassung nur über `ea_create_volunteer` und `ea_activate_person` (v0.8, v0.8.1) | `ea_property_writable(...)` für alte und neue Fassung | – |
| ea_property_history | wie ea_properties | nur Trigger | – | – |

Rechtevorlagen (Startwerte, R6; Reichweite „alle“, außer wo genannt):

| Rechtevorlage | AD | SC | EA | GR | EZ (v0.8) | TK (neu v0.9) | TKF (neu v0.9) | FI | OA | PM | GS | AM |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Admin | verwalten | verwalten | verwalten | lesen (v0.7) | lesen | lesen | – | – | – | – | – | – |
| Geschäftsstelle | – | – | verwalten | verwalten | verwalten | verwalten | – | verwalten | verwalten | verwalten | verwalten | verwalten |
| Referent:in (v0.7) | – | – | bearbeiten, Reichweite Referat | – | bearbeiten, Reichweite Referat | bearbeiten, Reichweite Referat | – | – | – | – | – | – |
| Freigabe Touren und Kurse (neu v0.9) | – | – | – | – | – | – | bearbeiten (= freigeben), Reichweite Referat | – | – | – | – | – |
| Vorstand | – | – | – | – | – (Ziel: lesen, vom Admin zu setzen) | – | – | – | – | – | – | – |

Die Geschäftsstelle pflegt Qualifikationsarten über „EA verwalten“, ohne Rechte auf AD (Entscheidung Product Owner 21.10.2026). Die Rechte-Matrix ändert sich dadurch nicht. Hüttenwart:innen erhalten die Vorlage Referent:in mit ihrem Hütten-Referat; damit erfassen sie auch Arbeitseinsätze ihres Hütten-Referats in der Anwesenheitserfassung (v0.8). Die Vorlage Referent:in gibt TK-Rechte in allen ihren Referaten; Planungen gibt es nur in den Referaten Touren und Ausbildung (spec.md TK R12), andere Referent:innen sehen dort nichts (v0.9). Die Vorlage „Freigabe Touren und Kurse“ vergibt der Admin auf Wunsch der Referent:in an Referent:innen der Referate Touren und Ausbildung und an weitere Personen (Delegation, Product Owner 22.10.2026); sie wirkt auch ohne die Vorlage Referent:in (Bearbeiten und Rückfragen in der Planungshilfe). Zugänge werden schrittweise vergeben: zuerst Referent:innen und Vorstand, später Gruppenleitungen, dann stellvertretende Gruppenleitungen und weitere Trainer:innen; Erziehungsberechtigte und Teilnehmer:innen erhalten keinen Zugang (E6). Eine Vorlage für Gruppenleitungen folgt mit der Reichweite „Gruppe“ (Iteration 1 der Anwesenheitserfassung, A6/A7, Abschnitt 11).

Edge Functions prüfen das Recht des Aufrufers selbst (JWT auswerten, `ad_has_level('AD','edit')` im Kontext des Aufrufers), bevor sie mit dem Service-Schlüssel arbeiten. Der Service-Schlüssel liegt nur in den Secrets der Edge Functions.

## 4. Zustände und Übergänge

Zugang:

| Von | Nach | Wer | Bedingung |
|---|---|---|---|
| kein Zugang | eingeladen | Admin (Edge Function ad-invite) | Login-Adresse gültig (R1, R2), mind. eine wirksame Vorlage (R17), Mail erfolgreich versendet |
| kein Zugang | eingeladen | System (Trigger auf auth.users) | Nutzer in Supabase Auth angelegt, z. B. Einladung über das Dashboard bei der Ersteinrichtung; Protokoll `invited` ohne Akteur (v0.7.4) |
| eingeladen | eingeladen | Admin (ad-invite) | erneut einladen; last_invited_at aktualisiert |
| eingeladen | kein Zugang | Admin (ad-access, `change_email`) | Login-Adresse geändert; Auth-Eintrag gelöscht, alter Link ungültig (R20) |
| eingeladen | aktiv | Nutzer (Trigger auf auth.users) | Passwort erstmals gesetzt |
| eingeladen | gesperrt | Admin (ad-access) | Einladung zurückziehen |
| aktiv | gesperrt | Admin (ad-access) | – |
| gesperrt | aktiv | Admin (ad-access) | Passwort gesetzt |
| gesperrt | eingeladen | Admin (ad-access) | kein Passwort gesetzt; danach erneut einladen möglich |

Sperren setzt in Supabase Auth einen Bann (`ban_duration`), Entsperren hebt ihn auf. Jeder Übergang außer „eingeladen → aktiv“ erzeugt einen Protokolleintrag.

Ehrenamtsstatus (neu v0.7; Oberfläche in EA, R33):

| Von | Nach | Wer | Bedingung |
|---|---|---|---|
| kein Status | aktiv | EA ≥ bearbeiten (Reichweite alle) oder Referent:in | `ea_create_volunteer` oder `ea_activate_person` mit Zuordnung zu einem (bei Referent:innen eigenen) Referat; GR setzt „aktiv“, wenn eine Person ohne Status als Trainer:in oder Helfer:in eingetragen wird [ANNAHME, GR-Migration] |
| (neue Person) | aktiv | EZ ≥ bearbeiten (Reichweite alle) oder Referent:in über die Anwesenheitserfassung (neu v0.8) | `ea_create_volunteer` mit Funktion Helfer:in und Bezug auf das Referat des Arbeitseinsatzes (R45) |
| ruhend, ausgeschieden oder kein Status | aktiv | EZ ≥ bearbeiten (Reichweite alle) oder Referent:in über die Anwesenheitserfassung (neu v0.8.1) | `ea_activate_person` mit Funktion Helfer:in und Bezug auf das Referat des Arbeitseinsatzes, auch wenn die Person zuletzt in einem anderen Referat aktiv war (R45a) |
| aktiv | ruhend | EA ≥ bearbeiten (Reichweite alle) oder Referent:in eines Referats der Person | – |
| aktiv, ruhend | ausgeschieden | wie oben | – |
| ruhend | aktiv | wie oben | – |
| ausgeschieden | aktiv | EA ≥ bearbeiten (Reichweite alle) über `ea_set_volunteer_status`; Referent:in nur über `ea_activate_person` mit Zuordnung zu einem eigenen Referat | Rückkehr; keine neue Person |

Jeder Wechsel schreibt `ea_volunteer_status_history`. Der Status gilt für die ganze Person, nicht je Referat. Ein Zurücksetzen auf „kein Status“ gibt es nicht.

Zustände einer Qualifikationsart: aktuell ↔ historisch; Wechsel in beide Richtungen jederzeit durch Admin oder Geschäftsstelle (R25).

Zustände eines Orts (neu v0.8): aktiv ↔ inaktiv; Wechsel in beide Richtungen jederzeit durch Nutzer mit `ad_can_edit_locations()` (R43).

Sätze (neu v0.9): keine Zustände; ein neuer Wert entsteht als neue Zeile mit späterem `valid_from` (R46). Zahlungsgebühren haben das Kennzeichen aktiv/inaktiv.

## 5. Geschäftsregeln

- R1: Wenn die Login-Adresse nicht auf @dav-leipzig.de endet, dann Fehler, sonst Fehlermeldung „Zugang nur mit Adresse @dav-leipzig.de möglich.“ Ausnahme nur in TEST: Domains aus `ad_test_login_domains` sind zusätzlich erlaubt (Abnahme der Mail-Abläufe, Abschnitt 9). Die Meldung bleibt gleich. **v0.7.4:** Beim Anlegen einer Person mit Login-Adresse prüft das Frontend die Adresse vorab über `ad_login_email_ok`, damit keine Person ohne Zugang stehen bleibt; der Trigger prüft erneut.
- R2: Wenn die Login-Adresse bereits einem Zugang gehört, dann Fehlermeldung „Diese Login-Adresse ist bereits vergeben.“
- **R3a (neu v0.7.3, Ähnlichkeit):** Eine Person gilt als ähnlich, wenn der Nachname ohne Groß-/Kleinschreibung und ohne führende oder folgende Leerzeichen gleich ist und der eingegebene Vorname zum Vornamen oder Rufnamen der vorhandenen Person passt (`ad_first_names_match`: Trigramm-Ähnlichkeit ≥ 0,3, einer im anderen enthalten oder gemeinsame Zeichenfolge von mindestens 3 Buchstaben, z. B. Toni/Anton) – oder wenn die E-Mail-Adresse übereinstimmt. Fehltreffer bei gleichem Nachnamen sind gewollt (die Warnung ist nur eine Rückfrage) [ANNAHME].
- R3: Wenn beim manuellen Anlegen `ad_find_similar_persons` Treffer liefert, dann Warndialog mit Trefferliste (nur Daten nach R40) und „Trotzdem anlegen“ / „Vorhandene Person öffnen“ (nur bei sichtbaren Treffern) / „Abbrechen“; in EA zusätzlich „Wieder aktivieren“ bzw. „Ins Ehrenamtsmanagement übernehmen“ für nicht sichtbare Treffer (über `ea_activate_person`); in der Anwesenheitserfassung (v0.8) statt „Vorhandene Person öffnen“ „Diese Person eintragen“ (setzt die vorhandene Person auf die Anwesenheitsliste, ohne sie neu anzulegen).
- R4: Wenn Vorname oder Nachname leer ist, dann Fehlermeldung „Bitte Vorname und Nachname angeben.“
- R5: Wenn der Zugang nicht `active` ist, dann wirken keine Rechte (ad_user_level = none, ad_my_referate leer).
- R6: Rechte = höchste Stufe je Modul über alle wirksamen Vorlagen; keine Verbote. Rechte mit Reichweite „alle“ und „Referat“ werden getrennt ausgewertet; „alle“ schließt jedes Referat ein.
- R7: Eigenschaften erzeugen keine Rechte; keine Ableitung im Code (auch nicht aus dem Amt Referent:in oder Hüttenwart:in).
- R8: Vertrauliche Eigenschaften lesen nur Nutzer mit AD ≥ read (RLS). v0.7: Teil von R29 (Lesestufe „vertraulich“).
- R9: Wenn der Zweck leer ist, dann „Bitte einen Zweck angeben.“; wenn ein Feld vom Typ Auswahlliste keine Werte hat, dann „Bitte mindestens einen Auswahlwert angeben.“; wenn eine Eigenschaftsart kein Feld hat, dann „Bitte mindestens ein Feld anlegen.“
- R10: Wenn ein Zugang gesperrt ist, dann ist keine Anmeldung möglich; Datenzugriff endet sofort (RLS), Frontend-Sitzung spätestens nach 1 Stunde.
- R11: Einladungen nur über den Knopf „Einladen“ / „Erneut einladen“; kein Trigger, Import oder Job lädt ein.
- R12: Keine Löschfunktion in AD. Ausscheiden = Ehrenamtsstatus „ausgeschieden“ (EA), Zugang sperren (AD) und ggf. gültig bis an Eigenschaften. Qualifikationsarten werden nicht gelöscht, sondern auf „historisch“ gesetzt (R25); Referate, Gremien und Orte werden inaktiv gesetzt; Sätze erhalten einen neuen Wert mit späterem „gültig ab“ (R46).
- R13: Einladen, Zuweisen, Entziehen, Referate ändern, Sperren, Entsperren, Anmeldung Notfall-Admin → Protokolleintrag; Löschung nach 5 Jahren.
- R14: Genau ein Zugang mit `is_emergency = true` (geschaeftsstelle@dav-leipzig.de, Vorlage Admin).
- R15: Wenn `kind = 'function'`, dann nicht in `ea_v_persons`, kein Ehrenamtsstatus, nicht für EA-, GR-, EZ- oder TK-Rechte sichtbar (auch nicht in `ea_person_names`, `ea_search_active_persons` und `ea_person_licenses`), nicht im Löschlauf.
- R16: Jede Anmeldung des Notfall-Admins → Protokoll + Hinweis in AD bis „Zur Kenntnis genommen“.
- R17: Wenn keine wirksame Vorlage zugewiesen ist, dann „Bitte zuerst mindestens eine Rechtevorlage zuweisen.“ und keine Einladung.
- R18: Login-Fehler immer „Anmeldung fehlgeschlagen. Bitte E-Mail-Adresse und Passwort prüfen.“; „Passwort vergessen“ immer „Wenn ein Zugang zu dieser Adresse besteht, haben wir dir eine E-Mail mit einem Link geschickt.“
- R19: Wenn das Passwort kürzer als 8 Zeichen ist, dann „Das Passwort muss mindestens 8 Zeichen lang sein.“; wenn die beiden Eingaben verschieden sind, dann „Die Passwörter stimmen nicht überein.“
- R20: Die Login-Adresse ist nur bei Status „kein Zugang“ oder „eingeladen“ änderbar. Bei „eingeladen“ wird die Einladung zurückgenommen: Der Eintrag in Supabase Auth wird gelöscht, der alte Link ist ungültig, der Status wird „kein Zugang“; Meldung „Die Login-Adresse wurde geändert. Bitte die Einladung erneut senden.“ Bei „aktiv“ oder „gesperrt“: „Die Login-Adresse kann nur vor der Aktivierung des Zugangs geändert werden.“
- R21: Wenn die Bezeichnung einer Qualifikationsart leer ist, dann „Bitte eine Bezeichnung angeben.“; wenn sie ohne Groß-/Kleinschreibung bereits existiert, dann „Eine Qualifikationsart mit dieser Bezeichnung gibt es bereits.“
- R22: Wenn das Kürzel gesetzt und bereits vergeben ist, dann „Dieses Kürzel ist bereits vergeben.“; wenn es andere Zeichen als Großbuchstaben und Ziffern enthält oder länger als 10 Zeichen ist, dann „Das Kürzel darf nur Großbuchstaben und Ziffern enthalten (max. 10 Zeichen).“ Kleinbuchstaben werden beim Speichern in Großbuchstaben umgewandelt.
- R23: Wenn der Typ „Lizenz“ ist und keine Lizenzstufe gewählt ist, dann „Bitte eine Lizenzstufe wählen.“; bei anderen Typen wird keine Lizenzstufe gespeichert (Feld ausgeblendet).
- R24: Wenn der Typ „Lizenz“ ist und die Gültigkeitsdauer fehlt oder nicht ganzzahlig zwischen 1 und 10 liegt, dann „Bitte eine Gültigkeitsdauer in Jahren angeben (1–10).“; bei „Weiterbildung“ optional (1–10); bei „Zusatzqualifikation“ und „Lehrgang“ ausgeblendet und leer.
- R25: Qualifikationsarten werden nicht gelöscht. Status „historisch“: nicht neu vergebbar; vorhandene Eigenschaften bleiben gültig und zeigen „(historisch)“; Listen blenden historische standardmäßig aus; Rückkehr auf „aktuell“ jederzeit möglich.
- R26: Wenn die Gültigkeitsdauer einer Qualifikationsart geändert wird, dann bleiben vorhandene Ablaufdaten an Personen unverändert; beim Speichern erscheint „Die Änderung gilt für neue Einträge. Vorhandene Ablaufdaten bleiben unverändert.“ [ANNAHME]
- R27: Wenn ein Nutzer ein Feld neu auf eine historische Qualifikationsart verweisen lässt, dann „Diese Qualifikationsart ist historisch und kann nicht neu vergeben werden.“ Migrationen und Skripte ohne Nutzerkontext dürfen historische Qualifikationsarten setzen (Altbestand).
- R28: Wenn das Feld die erlaubten Typen einschränkt und die gewählte Qualifikationsart einen anderen Typ hat, dann „Dieser Typ von Qualifikation ist hier nicht erlaubt.“
- **R29 (neu, Lesestufe):** Jede Eigenschaftsart hat genau eine Lesestufe: „alle mit Zugriff“, „nur Geschäftsstelle und Admin“ oder „vertraulich“. Wirkung je Pfad nach Abschnitt 3. „Vertraulich“ setzt und ändert nur, wer AD ≥ bearbeiten hat, sonst „Nur mit Rechten auf die Administration möglich.“ Beim Anlegen erscheint der Hinweis zu Art. 9 DSGVO.
- **R30 (Reichweite, v0.9 erweitert):** Eine Rechtevorlage hat je Modul eine Reichweite „alle“ oder „Referat“; „Referat“ ist im MVP nur für das Ehrenamtsmanagement (EA), die Anwesenheitserfassung (EZ), die Planungshilfe Touren und Kurse (TK) und die Freigabe Touren und Kurse (TKF) zulässig, sonst „Die Reichweite ‚Referat‘ ist nur im Ehrenamtsmanagement, in der Anwesenheitserfassung und in der Planungshilfe Touren und Kurse möglich.“ Rechte mit Reichweite „Referat“ wirken in EA nur auf Personen, die nach R32 über eines der zugewiesenen Referate sichtbar sind, in EZ nur auf Einsätze dieser Referate (Einsatz mit Gruppe über das Referat der Gruppe, sonst direkt; Prüfung in den Policies der Anwesenheitserfassung), in TK und TKF nur auf Planungen dieser Referate (Prüfung in der Planungshilfe). TKF kennt nur die Stufen „kein Zugriff“ und „bearbeiten“ (= freigeben), sonst „Für die Freigabe gibt es nur ‚kein Zugriff‘ oder ‚bearbeiten‘.“ (`AD_LEVEL_NOT_ALLOWED`).
- **R31 (neu):** Wenn eine Vorlage mit Reichweite „Referat“ zugewiesen wird, dann ist mindestens ein aktives Referat Pflicht, sonst „Bitte mindestens ein Referat auswählen.“ Bei Vorlagen ohne Reichweite „Referat“ werden keine Referate gespeichert. Eine Person kann mehrere Referate haben. Die Referate einer Zuweisung gelten für alle Module der Vorlage mit Reichweite „Referat“ (v0.8).
- **R32 (neu, Sichtbarkeit je Zugehörigkeit):** Personen und Eigenschaften sind nur über die Pfade AD, EA und GR nach Abschnitt 3 lesbar. Nutzer mit AD-Rechten (Admin) sehen alle Personen. In EA und GR erscheinen nur Personen mit Ehrenamtsstatus bzw. Gruppenbezug: Personen, die nur in Gruppen vorkommen, sind in EA nicht sichtbar; Personen nur aus AD (z. B. Hauptamtliche ohne Ehrenamt) nicht in EA und GR. Bekommt eine Person einen Ehrenamtsstatus oder Gruppenbezug, erscheint sie ab dann im jeweiligen Pfad. Anwesenheitserfassung und Planungshilfe erhalten nur Namen (und die Planungshilfe Lizenzen) nach R44, R47, R48.
- **R33 (neu, Ehrenamtsstatus):** Den Ehrenamtsstatus setzen Nutzer mit EA ≥ bearbeiten (Reichweite alle) für jede Person mit Status und Referent:innen für Personen, die über eines ihrer Referate sichtbar sind; Wirkung für die ganze Person. Sonst „Du darfst den Status dieser Person nicht ändern.“ Jeder Wechsel wird mit Datum, wer und wann gespeichert.
- **R34 (neu):** Ausgeschiedene Personen lesen im Pfad EA nur Nutzer mit EA = verwalten (Reichweite alle), d. h. Geschäftsstelle und Admin.
- **R35 (neu, Felder):** Wenn ein Pflichtfeld fehlt, dann „Bitte ‚<Feld>‘ ausfüllen.“; wenn ein Wert nicht zum Datentyp passt, dann „Der Wert für ‚<Feld>‘ passt nicht zum Datentyp.“; wenn ein Schlüssel kein Feld der Eigenschaftsart ist, dann „Unbekanntes Feld.“; wenn ein Auswahlwert nicht in der Liste steht, dann „Bitte einen Wert aus der Liste wählen.“; Jahr: ganzzahlig 1900–2100; Zahl: Dezimalzahl.
- **R36 (neu):** Der Datentyp eines Felds ist nicht änderbar, sobald Eigenschaften der Art existieren („Der Datentyp kann nicht geändert werden, solange Eigenschaften dieser Art existieren.“). Felder werden nicht gelöscht. Neue Felder an Eigenschaftsarten mit vorhandenen Eigenschaften dürfen nicht Pflicht sein („Neue Felder können nur optional angelegt werden, solange es Eigenschaften dieser Art gibt.“). Auswahlwerte können ergänzt, nicht entfernt werden.
- **R37 (neu):** Wenn eine Eigenschaftsart keine mehrfachen Einträge erlaubt und die Person im Zeitraum bereits eine gültige Eigenschaft dieser Art hat, dann „Für diese Eigenschaftsart ist nur ein gültiger Eintrag je Zeitraum erlaubt.“ (Beispiel: Geburtsdatum, Geschlecht).
- **R38 (neu, Bezug):** Hat die Eigenschaftsart einen Bezug, wird genau die passende Bezugsspalte gefüllt; bei „Bezug Pflicht“ ohne Bezug „Bitte ein Referat (bzw. Gremium, Gruppe) wählen.“; inaktive Referate und Gremien sind nicht neu wählbar.
- **R39 (neu):** Eigenschaften mit Bezug auf eine Gruppe schreiben nur Nutzer mit GR ≥ bearbeiten; im Ehrenamtsmanagement nur lesen („Diese Angabe wird im Modul Gruppen gepflegt.“).
- **R40 (neu, Dublettenwarnung modulübergreifend; v0.7.2 ergänzt):** Die Dublettenprüfung sucht in allen Personen (Mensch), zeigt aber für jeden Treffer nur Vorname, Nachname, Rufname, Geburtsjahr und bei Ausgeschiedenen „ausgeschieden seit“; keine Eigenschaften, Kontaktdaten oder Zugehörigkeiten aus fremden Pfaden. Ziel: ein Mensch existiert nur einmal (E1). Das Geburtsjahr erhält nur, wer die Lesestufe der Eigenschaftsart Geburtsdatum erfüllt: bei „nur Geschäftsstelle und Admin“ (Startwert) nur mit AD lesen, EA verwalten oder GR verwalten, bei „vertraulich“ nur mit AD lesen, bei „alle mit Zugriff“ jeder, der die Prüfung aufrufen darf. Sonst zeigt der Dialog kein Geburtsjahr (keine Lücke, kein Hinweis). Referent:innen sehen das Geburtsjahr damit nicht (Datensparsamkeit, Ü2).
- **R41 (neu):** Referent:innen legen Eigenschaften mit Bezug auf ein Referat nur für eigene Referate an oder ändern sie dorthin; sonst „Du kannst nur Zuordnungen zu deinen Referaten pflegen.“ Eigenschaften anderer Referate derselben Person sehen sie (Lesestufe „alle mit Zugriff“), ändern sie aber nicht.
- **R42 (neu):** Schreiben setzt Lesen voraus: Eine Eigenschaft anlegen oder ändern darf nur, wer sie im selben Pfad lesen darf und dort mindestens „bearbeiten“ hat. **v0.7.4 (Entscheidung Product Owner 23.10.2026):** Mit Reichweite „Referat“ schreiben Referent:innen nur Eigenschaften mit Bezug auf ein eigenes Referat; Eigenschaften ohne Bezug (z. B. Erste-Hilfe-Kurs, T-Shirt-Größe) pflegen Geschäftsstelle und Admin.
- **R43 (neu v0.8, Orte):** Wenn die Bezeichnung eines Orts leer ist, dann „Bitte eine Bezeichnung angeben.“; wenn sie ohne Groß-/Kleinschreibung bereits existiert, dann „Einen Ort mit dieser Bezeichnung gibt es bereits.“ Orte werden nicht gelöscht, sondern inaktiv gesetzt; inaktive Orte sind in der Anwesenheitserfassung nicht neu wählbar, vorhandene Einsätze zeigen sie weiter. Ohne Recht: „Für diesen Bereich hast du keine Rechte.“
- **R44 (neu v0.8, Namen für die Anwesenheitserfassung):** Über die Anwesenheitserfassung sind von Personen nur Vorname, Rufname und Nachname lesbar – nie Eigenschaften, Kontaktdaten, Geburtsdatum, Ehrenamtsstatus oder Zugehörigkeiten. `ea_person_names` liefert nur Personen nach `ez_person_visible` (bzw. die ohnehin über einen Pfad lesbar sind); `ea_search_active_persons` liefert nur Personen mit Ehrenamtsstatus „aktiv“ und nur an Nutzer mit EZ ≥ bearbeiten (v0.9 zusätzlich TK ≥ bearbeiten oder TKF, R48); Suchbegriff mindestens 2 Zeichen („Bitte mindestens 2 Zeichen eingeben.“), höchstens 50 Treffer.
- **R45 (neu v0.8, Personen aus der Anwesenheitserfassung anlegen):** Mit EZ ≥ bearbeiten (Reichweite alle oder Referat des Einsatzes) darf beim Arbeitseinsatz eine neue Person angelegt werden: Vorname und Nachname Pflicht (R4), Rufname und Kontakt-E-Mail optional; sie erhält Ehrenamtsstatus „aktiv“ und die Funktion Helfer:in mit Bezug auf das Referat des Einsatzes. Vorher läuft die Dublettenprüfung (R3, R40). Bei Reichweite Referat und fremdem Referat: „Du kannst nur Zuordnungen zu deinen Referaten pflegen.“ (`EA_RELATION_FOREIGN_REFERAT`, v0.8.1).
- **R45a (neu v0.8.1, Personen beim Arbeitseinsatz wieder aktiv eintragen, Übergabe EZ A9):** Mit EZ ≥ bearbeiten (Reichweite alle oder Referat des Einsatzes) darf eine vorhandene Person mit Ehrenamtsstatus „ruhend“, „ausgeschieden“ oder ohne Ehrenamtsstatus beim Arbeitseinsatz direkt wieder aktiv eingetragen werden, auch wenn sie zuletzt in einem anderen Referat aktiv war: Ehrenamtsstatus „aktiv“ mit Historie und Funktion Helfer:in mit Bezug auf das Referat des Einsatzes (`ea_activate_person`). Andere Eigenschaftsarten oder Werte: „Für diesen Bereich hast du keine Rechte.“ (`EA_CREATE_FORBIDDEN`); fremdes Referat wie R45.
- **R46 (neu v0.9, Sätze):** Sätze, Pauschalen, Zahlungsgebühren, Emissionsfaktoren und Grenzwerte pflegt nur der Admin (Product Owner 22.10.2026), sonst „Für diesen Bereich hast du keine Rechte.“ Ein neuer Wert wird als neue Zeile mit „gültig ab“ angelegt; Schlüssel und „gültig ab“ einer Zeile sind nicht änderbar; je Schlüssel und Datum höchstens eine Zeile („Für dieses Datum gibt es schon einen Wert.“, `AD_RATE_DUPLICATE`); Werte ≥ 0 („Wert ungültig.“, `AD_RATE_VALUE`); Bezeichnung, Einheit und Quelle Pflicht („Bitte ‚<Feld>‘ angeben.“, `AD_RATE_FIELD_REQUIRED`). Zahlungsgebühren mit Prozentsatz und festem Betrag statt Wert. Beim Speichern eines neuen Werts erscheint „Planungen im Entwurf oder eingereicht mit Beginn ab {gültig ab} rechnen mit dem neuen Wert. Freigegebene Planungen behalten ihren Satzstand.“ Kein Löschen.
- **R47 (neu v0.9, Lizenzen für die Planungshilfe):** Die Planungshilfe erhält von Personen nur Lizenzen nach `ea_person_licenses`: Qualifikationsart (Kürzel, Bezeichnung), gültig bis, förderfähig und gültig am Datum; keine Lizenznummer, keine anderen Eigenschaften; nur für aktive und ruhende Personen und nur aus Eigenschaftsarten mit Lesestufe „alle mit Zugriff“.
- **R48 (neu v0.9, Namen für die Planungshilfe):** Über die Planungshilfe sind von Personen nur Vorname, Rufname und Nachname lesbar (`ea_person_names` mit `tk_person_visible`; `ea_search_active_persons` mit TK ≥ bearbeiten oder TKF), dazu Lizenzen nach R47; nie Kontaktdaten, Geburtsdatum, Ehrenamtsstatus oder Zugehörigkeiten. Kontakt- und Notfalldaten der Leitung erfasst die Planungshilfe je Planung selbst (spec.md TK).
- **R49 (neu v0.7.2, Bezeichnungen „gültig von/bis“):** Eine Eigenschaftsart kann für „gültig von“ und „gültig bis“ je eine eigene Bezeichnung haben (höchstens 40 Zeichen, sonst „Die Bezeichnung darf höchstens 40 Zeichen lang sein.“, `EA_LABEL_TOO_LONG`); leer = „gültig von“ bzw. „gültig bis“. Eigenschaftsformular, Personendetail und Historie verwenden sie; die Meldung „gültig bis vor gültig von“ nennt sie wie die Standardmeldung (erste Bezeichnung mit großem Anfangsbuchstaben), z. B. „‚Beendet am‘ darf nicht vor ‚erworben bzw. verlängert am‘ liegen.“ [ANNAHME].

Weitere Meldungen:
- Datentyp ändern bei vorhandenen Eigenschaften: „Der Datentyp kann nicht geändert werden, solange Eigenschaften dieser Art existieren.“
- Auswahlwert entfernen: „Auswahlwerte können ergänzt, aber nicht entfernt werden.“
- Bezug ändern bei vorhandenen Eigenschaften: „Der Bezug kann nicht geändert werden, solange Eigenschaften dieser Art existieren.“
- Name doppelt: „Eine Rechtevorlage mit diesem Namen gibt es bereits.“ / „Eine Eigenschaftsart mit diesem Namen gibt es bereits.“ / „Ein Feld mit dieser Bezeichnung gibt es bereits.“
- gültig bis vor gültig von: „‚Gültig bis‘ darf nicht vor ‚gültig von‘ liegen.“; v0.7.2 mit den Bezeichnungen der Eigenschaftsart (R49)
- Mailversand fehlgeschlagen: „Die Einladung konnte nicht verschickt werden. Bitte später erneut versuchen.“
- Link ungültig (Einladung): „Der Link ist abgelaufen oder ungültig. Bitte wende dich an den Admin.“; (Passwort vergessen): „Der Link ist abgelaufen oder ungültig. Bitte fordere einen neuen an.“
- Keine Rechte: „Für diesen Bereich hast du keine Rechte.“
- Unerwarteter Fehler: „Etwas ist schiefgelaufen. Bitte versuche es erneut.“

Datenbankfehler und Edge Functions tragen einen Code (bisher `AD_EMAIL_DOMAIN`, `AD_EMAIL_TAKEN`, `AD_EMAIL_LOCKED`, `AD_NO_TEMPLATE`, `AD_FORBIDDEN`, `EA_VALUE_TYPE`, `AD_QUALIFICATION_NAME_REQUIRED`, `AD_QUALIFICATION_NAME_TAKEN`, `AD_QUALIFICATION_CODE_TAKEN`, `AD_QUALIFICATION_CODE_FORMAT`, `AD_QUALIFICATION_LEVEL_REQUIRED`, `AD_QUALIFICATION_VALIDITY`, `AD_QUALIFICATION_HISTORIC`, `AD_QUALIFICATION_KIND`; neu v0.7 `AD_CONFIDENTIAL_ONLY_AD`, `EA_LABEL_TOO_LONG` (v0.7.2), `AD_SCOPE_NOT_ALLOWED`, `AD_REFERAT_REQUIRED`, `EA_FIELD_REQUIRED`, `EA_FIELD_UNKNOWN`, `EA_FIELD_CHOICE`, `EA_FIELD_LOCKED`, `EA_FIELD_NEW_REQUIRED`, `EA_NO_FIELDS`, `EA_SINGLE_VALUE`, `EA_RELATION_REQUIRED`, `EA_RELATION_LOCKED`, `EA_RELATION_FOREIGN_REFERAT`, `EA_GROUP_RELATION_ONLY_GR`, `EA_STATUS_FORBIDDEN`; neu v0.8 `AD_LOCATION_NAME_REQUIRED`, `AD_LOCATION_NAME_TAKEN`, `AD_SEARCH_TOO_SHORT`, `AD_TOO_MANY_IDS`, `EA_CREATE_FORBIDDEN` (`EA_CREATE_FOREIGN_REFERAT` entfällt mit v0.8.1, stattdessen `EA_RELATION_FOREIGN_REFERAT`); neu v0.9 `AD_LEVEL_NOT_ALLOWED`, `AD_RATE_DUPLICATE`, `AD_RATE_VALUE`, `AD_RATE_FIELD_REQUIRED`, `AD_RATE_LOCKED`); die vollständige Liste mit deutschem Meldungstext je Code steht in `docs/specs/ad-administration/contracts/error-codes.md`. `AD_SCOPE_NOT_ALLOWED` meldet ab v0.9 den Text aus R30. `AD_RATE_LOCKED`: „Schlüssel und ‚gültig ab‘ können nicht geändert werden. Bitte einen neuen Wert anlegen.“ `EA_VALUE_TYPE` meldet v0.7 den Feldnamen mit (R35). Das Frontend bildet Codes auf die Meldungen ab.

## 6. Screens und Interaktionen

Allgemein: deutsch, Ansprache „du“, Datum TT.MM.JJJJ, Zeit HH:MM (Europe/Berlin), shadcn/ui, nutzbar ab 375 px ohne horizontales Scrollen (Tabellen werden mobil zu Karten). Kopfzeile: Vereins OS (Link Startseite), Modulname, Name des Nutzers (über `ad_me()`, Rufname bevorzugt), „Abmelden“. Personennamen werden überall als „Rufname Nachname“ angezeigt, falls ein Rufname gesetzt ist, sonst „Vorname Nachname“.

| Route | Zeigt | Aktionen | Leerer Zustand / Fehler | Story |
|---|---|---|---|---|
| /login | Login-Adresse, Passwort | Anmelden; Link „Passwort vergessen“ | R18-Meldung | US-AD-02 |
| /passwort-vergessen | Login-Adresse | Link anfordern | immer R18-Bestätigung | US-AD-04 |
| /passwort-setzen | Passwort, Wiederholung | Speichern (aus Einladungs- oder Reset-Link) | R19 (Länge, Übereinstimmung); Link ungültig | US-AD-03, US-AD-04 |
| / | Willkommensgrafik (Platzhalterbild im Repo), Kacheln aus ad_my_modules; Ladezustand | Modul öffnen | „Für dich sind noch keine Module freigeschaltet.“ und darunter „Wende dich an den Admin, wenn du Zugriff brauchst.“ | US-AD-05 |
| /kein-zugriff | Meldung „Für diesen Bereich hast du keine Rechte.“ | Zur Startseite | – | US-AD-05 |
| /ad | Personenübersicht (ad_v_person_overview): Name, Art-Kennzeichen „Funktionsperson“, Login-Adresse, Status-Badge, Ehrenamtsstatus (falls vorhanden), Vorlagen (bei Reichweite Referat mit Referaten); Suche nach Namensteil (Vor-, Ruf-, Nachname); Filter Zugangsstatus; Filter Zugehörigkeit (mit Zugang, Funktionsperson, Ehrenamtsmanagement, nur Gruppen, ohne Zugehörigkeit) [ANNAHME]; Paginierung (50 je Seite) [ANNAHME]; oben ggf. Hinweis Notfall-Admin („Der Notfall-Admin hat sich n-mal angemeldet, zuletzt am …“) | Person anlegen; Person öffnen; „Zur Kenntnis genommen“ | „Keine Personen gefunden.“ | US-AD-06, US-AD-15 |
| /ad/personen/neu | Vorname, Nachname, optional Rufname, optional Login-Adresse | Speichern → Dublettenprüfung → ggf. Warndialog (Treffer nur mit Daten nach R40; „Vorhandene Person öffnen“ nur bei sichtbaren Treffern) | R1, R2, R4 | US-AD-07, US-AD-25 |
| /ad/personen/:id | Abschnitte: **Stammdaten** (Vorname, Rufname, Nachname, Art; bearbeitbar; Ehrenamtsstatus nur lesen mit „seit“); **Zugang** (Login-Adresse, Status, zuletzt eingeladen, gesperrt am/von); **Rechtevorlagen** (wirksame Vorlagen, bei Reichweite Referat mit Referaten); **Eigenschaften** (nach Kategorie gruppiert; aktuelle oben, beendete als „beendet“; je Eigenschaft Historie aufklappbar; nur Arten mit „sichtbar in“ AD; Felder als „Bezeichnung: Wert“; gültig von/bis mit den Bezeichnungen der Eigenschaftsart (R49, v0.7.2); Bezug als „Referat …“ bzw. „Gremium …“; Qualifikationsart als „Kürzel – Bezeichnung“, historische mit „(historisch)“) | Stammdaten speichern; Login-Adresse speichern (nur bei „kein Zugang“/„eingeladen“, R20); Einladen / Erneut einladen / Sperren (mit Bestätigung und Hinweis „Bereits angemeldete Nutzer verlieren den Zugriff spätestens nach einer Stunde.“) / Entsperren; Vorlage hinzufügen (nur nicht zugewiesene; bei Reichweite Referat Mehrfachauswahl der Referate, R31) / Referate ändern / entziehen; Eigenschaft hinzufügen (Formular aus den Feldern der Eigenschaftsart, Bezug-Auswahl), ändern, beenden | „Noch keine Eigenschaften.“; R1, R2, R17, R27, R28, R31, R35, R37, R38, Mailfehler | US-AD-08, 09, 11, 13, 19, 21, 24 |
| /ad/rechtevorlagen | Liste: Name, Beschreibung, Anzahl Personen | Neu; öffnen | – | US-AD-10 |
| /ad/rechtevorlagen/:id | Name, Beschreibung, Matrix 12 Module × Stufe (Auswahl je Zeile; v0.8 mit Zeile Anwesenheitserfassung; v0.9 mit Zeilen Planungshilfe Touren und Kurse und Freigabe Touren und Kurse – bei Freigabe nur „kein Zugriff“ / „bearbeiten (freigeben)“); Spalte Reichweite (alle / Referat), „Referat“ nur bei Ehrenamtsmanagement, Anwesenheitserfassung, Planungshilfe und Freigabe wählbar | Speichern | Name doppelt; R30 | US-AD-10, US-AD-20 |
| /ad/eigenschaftsarten | Liste: Name, Kategorie, Lesestufe, Bezug, Anzahl Felder, sichtbar in | Neu; öffnen | „Noch keine Eigenschaftsarten.“ | US-AD-12, US-AD-22 |
| /ad/eigenschaftsarten/:id | Name, Zweck, Kategorie, Lesestufe (drei Optionen mit Erklärung; „vertraulich“ nur mit AD ≥ bearbeiten), Bezug (kein / Referat / Gremium; „Gruppe“ nur mit GR = verwalten), Bezug Pflicht, mehrere gültige Einträge erlaubt, sichtbar in (Mehrfachauswahl); optional „Bezeichnung für ‚gültig von‘“ und „Bezeichnung für ‚gültig bis‘“ (je höchstens 40 Zeichen, Platzhalter „gültig von“ bzw. „gültig bis“; v0.7.2, R49); **Felder** als Liste (Bezeichnung, Schlüssel, Datentyp, Pflicht, Auswahlwerte bei Auswahlliste bzw. erlaubte Typen bei Qualifikationsart (Mehrfachauswahl, leer = alle), Reihenfolge per Auf/Ab); Hinweis Art. 9 DSGVO beim Anlegen | Speichern; Feld hinzufügen | R9, R29, R36, R49, Name doppelt | US-AD-12, US-AD-19, US-AD-22 |
| /ad/qualifikationsarten | Tabelle gruppiert nach Sparte: Kürzel, Bezeichnung, Typ, Lizenzstufe, Gültigkeitsdauer, Status-Badge; Suche nach Bezeichnung oder Kürzel; Filter Sparte, Typ, Status (Standard „aktuell“) | Neu; öffnen | „Keine Qualifikationsarten gefunden.“ | US-AD-17 |
| /ad/qualifikationsarten/neu, /ad/qualifikationsarten/:id | Formular: Bezeichnung, Kürzel, Sparte (Eingabe mit Vorschlägen aus vorhandenen Werten), Typ, Lizenzstufe (nur bei Lizenz), Spezifikation, Aussteller (Vorschläge), DOSB-lizenzfähig (ja / nein / nicht bekannt), Gültigkeitsdauer in Jahren (nach R24), Status, Hinweis, Quell-ID (nur lesen); Detailansicht zusätzlich „Verwendet bei n Personen“ und geändert am/von | Speichern | R21–R26 | US-AD-17 |
| /ea/qualifikationsarten, /ea/qualifikationsarten/neu, /ea/qualifikationsarten/:id | dieselben Komponenten wie unter /ad, eingehängt in die Navigation des Ehrenamtsmanagements | wie oben | wie oben | US-AD-17 |
| /ad/orte (v0.8) | Liste: Bezeichnung, Punktekonto Kletterhalle ja/nein, Status-Badge (aktiv/inaktiv); Filter Status (Standard „aktiv“); sortiert nach Bezeichnung | Neu; öffnen | „Noch keine Orte angelegt.“ | Übergabe EZ A8 |
| /ad/orte/neu, /ad/orte/:id (v0.8) | Formular: Bezeichnung, Punktekonto Kletterhalle (Ja/Nein), Status (aktiv/inaktiv); Detail zusätzlich geändert am/von | Speichern | R43 | Übergabe EZ A8 |
| /ad/saetze (neu v0.9) | Tabelle gruppiert nach Gruppe (Vergütung, Reisekosten, Beitrag und Rundung, Zahlungsgebühren, Klima und Emissionsfaktoren, Grenzwerte): Bezeichnung, aktueller Wert mit Einheit (bei Zahlungsgebühren „% + € fix“, aktiv), gültig ab, Quelle; Auswahl „Stand am“ (Standard heute, zeigt `ad_rates_at`); je Schlüssel aufklappbare Historie aller Werte | Neuer Wert (je Schlüssel: Wert bzw. %/fix/aktiv, gültig ab, Quelle, Hinweis); Bezeichnung/Quelle/Hinweis einer Zeile korrigieren; nur mit `ad_can_edit_rates()` | „Noch keine Sätze angelegt.“; R46 | Übergabe TK 10, 13 |

Navigation AD: Personen · Rechtevorlagen · Eigenschaftsarten · Qualifikationsarten · Orte (v0.8) · Sätze (neu v0.9) · Protokoll.

Routenschutz: ohne Sitzung → /login (US-AD-02 AK5); /ad/* ohne AD ≥ read → /kein-zugriff, keine Datenabfrage (US-AD-05 AK3); /ea/* ohne `ad_has_any_level('EA','read')` → /kein-zugriff; /ea/qualifikationsarten* ohne EA = manage → /kein-zugriff. Bearbeiten-Knöpfe nur bei `ad_can_edit_qualification_types()` bzw. bei Orten `ad_can_edit_locations()`, bei Sätzen `ad_can_edit_rates()`. Die Routen unter /ea werden aktiv, sobald EA umgesetzt ist (`ad_modules.is_available`); bis dahin pflegt nur der Admin. Navigation wird bei jedem Seitenaufruf aus ad_my_modules geladen.

Wiederverwendbare Komponenten für AD, EA, GR, EZ und TK:
- Auswahlfeld „Qualifikationsart“ (v0.6): durchsuchbar nach Bezeichnung und Kürzel, Anzeige „Kürzel – Bezeichnung“, gruppiert nach Sparte, nur Status „aktuell“ und erlaubte Typen.
- **Eigenschaftsformular** (neu v0.7): baut Eingaben aus ea_property_fields (Text, Zahl, Datum, Jahr, Ja/Nein, Auswahlliste, Qualifikationsart), Bezug-Auswahl (bei Reichweite Referat nur eigene Referate), gültig von/bis mit den Bezeichnungen der Eigenschaftsart (R49, v0.7.2); zeigt Fehler je Feld (R35).
- **Dublettendialog** (neu v0.7): Trefferliste nach R40; Geburtsjahr nur, wenn die Funktion es liefert (v0.7.2); Aktionen je Modul (R3).
- **Personensuche „Aktive“** (v0.8): Eingabefeld mit Vorschlägen aus `ea_search_active_persons` ab 2 Zeichen, Anzeige „Rufname Nachname“; für die Anwesenheitserfassung (organisierende Person, Vertretung) und die Planungshilfe (Leitung, v0.9).
- **Auswahlfeld „Ort“** (v0.8): nur aktive Orte, sortiert nach Bezeichnung; für die Anwesenheitserfassung.

## 7. Schnittstellen

| Schnittstelle | Art | Beschreibung |
|---|---|---|
| Supabase Auth | Konfiguration (config.toml + Dashboard) | E-Mail/Passwort; Selbstregistrierung aus (`enable_signup = false`); Mindestlänge Passwort 8; Redirect-URLs: PROD-Adresse (`*.workers.dev`), Vorschau-Adressen, lokal; deutsche Mailvorlagen „Einladung“ und „Passwort zurücksetzen“ nur mit kurzem Hinweistext und Link |
| SMTP | Supabase Auth → Google-Konto der Sektion | App-Passwort nur in den Supabase-Einstellungen; Absendername „Vereins OS“ |
| Edge Function `ad-invite` | POST `{ person_id }`, Bearer-JWT des Aufrufers | prüft AD ≥ edit, R1, R2, R17, Status; lädt per Auth-Admin-API ein (neu oder erneut); bei Erfolg: Status `invited`, last_invited_at, auth_user_id, Protokoll `invited`; bei Fehler der Auth-Admin-API (z. B. Mailversand): hat der Aufruf einen Auth-Eintrag neu angelegt, löscht die Function ihn wieder und setzt Status, auth_user_id und last_invited_at auf den Stand vor dem Aufruf zurück; kein Protokolleintrag; Fehlercode `AD_MAIL_FAILED`. Das Verhalten hängt nicht davon ab, ob Supabase Auth bei SMTP-Fehlern einen Eintrag anlegt; abgesichert durch einen Test der Function mit simuliertem Fehler; ohne Recht: 403 |
| Edge Function `ad-access` | POST `{ person_id, action: "lock" \| "unlock" \| "change_email", login_email? }` | prüft AD ≥ edit; `lock`/`unlock`: setzt bzw. entfernt Bann in Auth, Status nach Abschnitt 4, Protokoll `locked` / `unlocked`; `change_email` (nur bei Status `invited`, sonst `AD_EMAIL_LOCKED`): prüft R1, R2, löscht den Auth-Eintrag, setzt neue login_email, auth_user_id null, Status `none`, Protokoll `email_changed` (Details: alte → neue Adresse), Meldung „Die Login-Adresse wurde geändert. Bitte die Einladung erneut senden.“; ohne Recht: 403 |
| EA | Datenbank | nutzt ea_persons (über ea_v_persons), ea_property_types, ea_property_fields, ea_properties, ea_referate, ea_gremien; setzt den Ehrenamtsstatus über `ea_set_volunteer_status`, legt Personen über `ea_create_volunteer` an, übernimmt bzw. reaktiviert über `ea_activate_person`; nutzt `ea_person_referate` für den Bestätigungsdialog; liest ad_qualification_types; nutzt Eigenschaftsformular, Dublettendialog und Auswahlfeld „Qualifikationsart“ sowie die Seiten unter /ea/qualifikationsarten; legt die 25 System-Eigenschaftsarten nach 01-erhebung.md EA C2 per Migration an, mit Bezeichnungen „gültig von/bis“ nach C2a (v0.7.2); von der Administration genutzt: `birth_date` (Feld `date`), `contact` (Felder `email`, `dav_email`), `function` (Feld `function`), `license` (Felder `qualification_type`, `valid_until`); stellt den Seed auf die System-Eigenschaftsarten um (Ü3, Abschnitt 9); das Migrationsskript der Aktivenliste schreibt ohne Nutzerkontext (`created_in = 'script'`, Status nach migration-aktivenliste.md) |
| GR | Datenbank | ersetzt `gr_person_visible` (gleiche Signatur); ergänzt `ea_properties.related_group_id` und `ea_property_history.related_group_id` mit Fremdschlüssel, Validierung und R39; ergänzt eine Funktion zum Anlegen von Personen mit Gruppenbezug (`created_in = 'GR'`, A6); nutzt die gemeinsamen Eigenschaftsarten Kontaktdaten, Geburtsdatum, Mitglied („sichtbar in“ enthält GR, A3); gruppenspezifische Daten in `gr_`-Tabellen; setzt für Trainer:innen und Helfer:innen ohne Ehrenamtsstatus „aktiv“ [ANNAHME]; v0.8: `gr_group_roster(group_id, date)` prüft u. a. `ad_has_level('EZ','read')` und `ad_my_referate('EZ','read')` (R20 der Erhebung Gruppen) |
| EZ (Anwesenheitserfassung, v0.8) | Datenbank | Rechte über `ad_has_level('EZ', …)` und `ad_my_referate('EZ', …)` (Reichweite Referat, R30); ersetzt `ez_person_visible` (gleiche Signatur); liest Namen nur über `ea_person_names` und `ea_search_active_persons` (R44) und Gruppenlisten über `gr_group_roster`; legt Helfer:innen beim Arbeitseinsatz über `ad_find_similar_persons` und `ea_create_volunteer` an (R45, `created_in = 'EZ'`); verweist mit Fremdschlüssel auf `ad_locations` (Ort beim Training) und `ea_referate`; liest ad_qualification_types (Lizenzprüfung für die Vergütung, später); setzt `ad_modules.is_available` für EZ mit ihrer Freigabe |
| TK (Planungshilfe Touren und Kurse, neu v0.9) | Datenbank | Rechte über `ad_has_level('TK', …)`, `ad_my_referate('TK', …)` und Freigabe über `ad_my_referate('TKF','edit')` (R30); ersetzt `tk_person_visible` (gleiche Signatur); liest Namen nur über `ea_person_names` und `ea_search_active_persons`, Lizenzen nur über `ea_person_licenses` (R47, R48); liest Sätze über `ad_rates_at` (R46); liest ad_qualification_types; nutzt die Komponente „Personensuche Aktive“; setzt `ad_modules.is_available` für TK und TKF mit ihrer Freigabe (spec.md TK) |
| FI (Finanzen, später) | Datenbank | liest Sätze der Vergütungsordnung über `ad_rates_at` (keine eigene Tabelle; v0.9) |
| alle Module | Datenbank | RLS über ad_has_level, ad_my_referate, ea_person_visible; Navigation über ad_my_modules |

## 8. Nicht-funktionale Anforderungen

- RLS auf jeder Tabelle; keine Tabelle ohne Policy; Rechteprüfung nie nur im Frontend.
- Schemaänderungen nur per Migration; Seed nur in TEST. Ausnahme Stammdaten ohne Personendaten (ad_modules, Startvorlagen inkl. Referent:in und „Freigabe Touren und Kurse“, Startwerte EZ und TK, Startbestand Qualifikationsarten, Referate, Gremien, Orte, Sätze): per Migration in TEST und PROD.
- Keine Secrets im Repo (Service-Schlüssel, SMTP-App-Passwort, Testpasswörter).
- Login-Mails enthalten keine Personendaten außer Empfängeradresse und Link.
- Auth-Mails: max. 30 pro Stunde (Supabase-Grenze mit eigenem SMTP) – ausreichend.
- Mobil ab 375 px; bedienbar ohne Schulung.
- Antwortzeit Personenübersicht bei 1.000 Personen (alle Module, v0.7.1) < 1 s je Seite; Liste der Qualifikationsarten bei 100 Einträgen < 1 s.
- Neu v0.7: Liste von 1.000 Personen (Aktive, Teilnehmer:innen, Erziehungsberechtigte) mit je 30 Eigenschaften im Pfad EA mit Reichweite Referat < 1 s; Sichtbarkeitsfunktionen `stable`, Indizes auf `related_referat_id` und `volunteer_status`; geprüft per Mengentest in pgTAP [ANNAHME: Mengengerüst].
- Neu v0.8: `ea_search_active_persons` bei 300 Aktiven und `ea_person_names` mit 50 IDs je < 300 ms (Eingabe auf dem Telefon während des Trainings) (bestätigt 24.10.2026); geprüft im Mengentest.
- Neu v0.9: `ad_rates_at` bei 100 Schlüsseln mit je 5 Werten und `ea_person_licenses` mit 10 IDs je < 100 ms [ANNAHME]; geprüft im Mengentest.
- Kosten: 0 €.
- Zustellung der Login-Mails (Spam-Filter) wird bei der Ersteinrichtung von PROD geprüft: Die erste echte Einladung (Toni Werner) und ein „Passwort vergessen“ gehen an seine reale Adresse @dav-leipzig.de. In TEST keine realen Adressen; einzige Ausnahme: eigene Adressen des Product Owners für die Abnahme von Einladung und Passwort-Links (Abschnitt 9).

## 9. Testdaten (supabase/seed.sh, nie PROD)

Der Seed läuft über `supabase/seed.sh` (Daten in `supabase/seed.sql`, Passwort per Parameter). Er läuft gegen den lokalen Stack (CI) und gegen TEST und bricht ab, wenn die Project Ref die von vereins-os-prod ist („Seed in PROD nicht erlaubt.“). Passwort der Testzugänge aus `SEED_TEST_PASSWORD` (lokal `.env.local`, CI: GitHub-Secret). Alle Namen und Adressen fiktiv; die Adressen existieren nicht. Der Notfall-Admin in TEST nutzt `test.notfall@dav-leipzig.de`; R14 (`geschaeftsstelle@dav-leipzig.de`) gilt für PROD.

Abnahme von Einladung, Passwort setzen und Passwort vergessen in TEST (US-AD-03, US-AD-04, US-AD-08): Der Product Owner nutzt dafür eigene private Adressen (eigene Daten, mit seiner Einwilligung):
1. Er trägt die Domain seiner privaten Adressen in TEST per SQL-Editor in `ad_test_login_domains` ein.
2. Er legt über die Oberfläche fiktive Personen mit diesen Adressen an und lädt sie ein.
3. Nach der Abnahme löscht er im TEST-Dashboard die Auth-Nutzer, die Testpersonen (per SQL) und die Domain aus `ad_test_login_domains`.

Domain und Adressen stehen nie im Repo, im Seed, in `.env.local` oder in einer Migration. Ein Löschen über die Oberfläche ist nicht Teil des MVP.

| # | Person | Art | Zugang | Status | Vorlagen | Ehrenamtsstatus | Eigenschaften |
|---|---|---|---|---|---|---|---|
| 1 | Test Admin | Mensch | test.admin@dav-leipzig.de | aktiv | Admin | – | – |
| 2 | Anna Fiktiv | Mensch | test.geschaeftsstelle@dav-leipzig.de | aktiv | Geschäftsstelle | – | Hauptamt „Mitarbeiterin Geschäftsstelle“ seit 01.03.2024 (vertraulich) |
| 3 | Bernd Beispiel | Mensch | test.vorstand@dav-leipzig.de | aktiv | Vorstand | – | – |
| 4 | Toni Muster | Mensch | – | kein Zugang | – | aktiv seit 01.03.2025 | Funktion (Test) „Trainer:in“, Referat Klettern, seit 01.03.2025; Lizenz (Test) TCSPI, Lizenznummer „TEST-0001“, gültig bis 31.12.2027; T-Shirt-Größe „M“ seit 01.01.2025; Geburtsdatum (Test) 12.05.1990 |
| 5 | Anton Muster | Mensch | – | kein Zugang | – | ruhend seit 01.01.2026 | Funktion (Test) „Trainer:in“, Referat Ausbildung, seit 01.05.2016; Lizenz (Test) TCSP (historisch) seit 01.05.2016, gültig bis 31.12.2019 (v0.7.2 [ANNAHME], weil `valid_until` in der System-Eigenschaftsart Lizenz Pflicht ist) (Dublettenpaar zu 4) |
| 6 | Eva Eingeladen | Mensch | test.eingeladen@dav-leipzig.de | eingeladen | Geschäftsstelle | – | – |
| 7 | Dieter Gesperrt | Mensch | test.gesperrt@dav-leipzig.de | gesperrt | Geschäftsstelle | – | Hauptamt 01.01.2020–31.12.2025 (beendet, vertraulich) |
| 8 | Geschäftsstelle Notfall-Admin | Funktionsperson | test.notfall@dav-leipzig.de (is_emergency) | aktiv | Admin | – | – |
| 9 | Rita Referentin | Mensch | test.referent@dav-leipzig.de | aktiv | Referent:in (Referat Klettern; wirkt ab v0.8 für EA und EZ, ab v0.9 auch TK) | aktiv seit 01.01.2024 | Amt (Test) „Referent:in“, Referat Klettern, seit 01.01.2024 |
| 10 | Karl Zweireferat | Mensch | – | kein Zugang | – | aktiv seit 01.01.2023 | Funktion (Test) „Helfer:in“, Referat Klettern; Funktion (Test) „Trainer:in“, Referat Ausbildung; Geburtsdatum (Test) 03.03.1985 |
| 11 | Olga Ausgeschieden | Mensch | – | kein Zugang | – | ausgeschieden seit 30.06.2025 | Funktion (Test) „Trainer:in“, Referat Klettern, 01.01.2020–30.06.2025 |
| 12 | Paul Nurgruppe | Mensch (`created_in = 'GR'`) | – | kein Zugang | – | – | Kontaktdaten (Test) E-Mail „paul.nurgruppe@example.test“ (simuliert eine Person nur aus Gruppen) |
| 13 | Tina Touren (neu v0.9) | Mensch | test.touren@dav-leipzig.de | aktiv | Referent:in (Referat Touren); Freigabe Touren und Kurse (Referat Touren) | aktiv seit 01.01.2024 | Amt (Test) „Referent:in“, Referat Touren, seit 01.01.2024 |
| 14 | Alex Ausbildung (neu v0.9) | Mensch | test.ausbildung@dav-leipzig.de | aktiv | Referent:in (Referat Ausbildung) – ohne Freigabe | aktiv seit 01.01.2024 | Amt (Test) „Referent:in“, Referat Ausbildung, seit 01.01.2024 |
| 15 | Fritz Freigabe (neu v0.9) | Mensch | test.freigabe@dav-leipzig.de | aktiv | Freigabe Touren und Kurse (Referat Touren) – ohne Referent:in | aktiv seit 01.01.2025 | Funktion (Test) „Helfer:in“, Referat Touren, seit 01.01.2025 |
| 16 | Bernd Berg (neu v0.9) | Mensch | – | kein Zugang | – | aktiv seit 01.01.2020 | Funktion (Test) „Trainer:in“, Referat Touren; Lizenz (Test) „Trainer*in C Bergwandern“ [ANNAHME: Qualifikationsart im Startbestand vorhanden, DOSB-lizenzfähig], gültig bis 30.10.2027 |
| 17 | Hilde Helfer (neu v0.9) | Mensch | – | kein Zugang | – | aktiv seit 01.01.2022 | Funktion (Test) „Helfer:in“, Referat Touren; keine Lizenz |
| 18 | Karl Kletter (neu v0.9) | Mensch | – | kein Zugang | – | aktiv seit 01.01.2018 | Funktion (Test) „Trainer:in“, Referat Ausbildung; Lizenz (Test) TCSPI, gültig bis 31.12.2025 (abgelaufen) |

Eigenschaftsarten im Seed (Felder in Klammern; v0.7.2: Feldschlüssel wie in 01-erhebung.md EA C2, damit die Umstellung nach Ü3 nur die Eigenschaftsart austauscht):
- „Hauptamt“ (Bezeichnung: Text, Pflicht, Schlüssel `title`) – vertraulich, Kategorie Sonstiges, sichtbar in AD, Zweck „Zuordnung der hauptamtlich Beschäftigten“.
- „T-Shirt-Größe“ (Größe: Auswahlliste S, M, L, XL, Pflicht) – alle mit Zugriff, Kategorie Ausgaben, nur ein gültiger Eintrag, sichtbar in EA, Zweck „Bestellung von Vereinskleidung“.
- „Erste-Hilfe-Kurs am“ (Datum: Datum, Pflicht) – alle mit Zugriff, Kategorie Qualifikationen, sichtbar in EA, Zweck „Nachweis für Tätigkeiten mit Gruppen“.
- „Lizenz (Test)“ (Qualifikationsart: Qualifikationsart, nur Typ Lizenz, Pflicht, Schlüssel `qualification_type`; Lizenznummer: Text, Schlüssel `license_number`; gültig bis: Datum, Schlüssel `valid_until`) – alle mit Zugriff, Kategorie Qualifikationen, sichtbar in AD und EA, Zweck „Nachweis der Trainerlizenz“; ohne `system_key` (v0.9.1: der Nachtrag v0.9 wird nach der ersten EA-Migration umgesetzt und nutzt die System-Eigenschaftsart `license`).
- „Funktion (Test)“ (Funktion: Auswahlliste Trainer:in, Helfer:in, Pflicht, Schlüssel `function`) – Bezug Referat (Pflicht), Kategorie Zuordnung, alle mit Zugriff, sichtbar in AD und EA, Zweck „Zuordnung zu Referaten“; ohne `system_key` (v0.9.1: der Nachtrag v0.8 wird nach der ersten EA-Migration umgesetzt und nutzt die System-Eigenschaftsart `function`).
- „Amt (Test)“ (Amt: Auswahlliste Referent:in, Hüttenwart:in, Pflicht, Schlüssel `position`) – Bezug Referat (Pflicht), Kategorie Zuordnung, alle mit Zugriff, sichtbar in AD und EA, Zweck „Gewählte Verantwortung für ein Referat“.
- „Geburtsdatum (Test)“ (Geburtsdatum: Datum, Pflicht, Schlüssel `date`) – nur Geschäftsstelle und Admin, Kategorie Stammdaten, `system_key = 'birth_date'`, nur ein gültiger Eintrag, sichtbar in AD, EA, GR, Zweck „Lizenzanträge“.
- „Kontaktdaten (Test)“ (E-Mail: Text, Schlüssel `email`; Telefon mobil: Text, Schlüssel `phone_mobile`) – alle mit Zugriff, Kategorie Kontakt, sichtbar in AD, EA, GR, Zweck „Erreichbarkeit“; im Kern-Seed mit `system_key = 'contact'` (Dublettenprüfung per E-Mail, T43).

**Testarten mit `system_key` gelten nur bis zur ersten Migration des Ehrenamtsmanagements (v0.7.2, Ü3).** Im Kern tragen nur „Geburtsdatum (Test)“ (`birth_date`) und „Kontaktdaten (Test)“ (`contact`) einen `system_key`. Die erste EA-Migration legt die endgültigen System-Eigenschaftsarten an (01-erhebung.md EA C2); mit ihr stellt das Ehrenamtsmanagement `supabase/seed.sql` um (spec.md EA T3): Die Testarten „Funktion (Test)“, „Amt (Test)“, „Lizenz (Test)“, „Geburtsdatum (Test)“, „Kontaktdaten (Test)“ und „Hauptamt“ entfallen; die Eigenschaften der Personen 2–12 verweisen auf die System-Eigenschaftsarten (Auflösung über `system_key`, Feldschlüssel unverändert). „T-Shirt-Größe“ und „Erste-Hilfe-Kurs am“ bleiben Testarten. Die Seed-Ergänzungen der Nachträge v0.8 (T57) und v0.9 (T66, Personen 13–18) verwenden von Anfang an die System-Eigenschaftsarten (Funktion, Amt, Lizenz). Die erwarteten Ergebnisse dieses Abschnitts gelten vor und nach der Umstellung unverändert; T45, T56 und T65 bleiben grün.

**TEST vor der ersten EA-Migration (Entscheidung Product Owner 22.10.2026):** TEST wird zurückgesetzt (Datenbank neu aus allen Migrationen, danach `supabase/seed.sh` mit dem umgestellten Seed), weil die Seed-Arten sonst mit den System-Eigenschaftsarten kollidieren (Eindeutigkeit von `system_key` und Name „Hauptamt“). TEST enthält nur Seed-Daten; Auth-Nutzer der Testzugänge legt der Seed neu an. Einträge in `ad_test_login_domains` und Testpersonen der Mail-Abnahme sind vorher nach den Schritten oben entfernt. In CI ist nichts zu tun (lokaler Stack immer neu). PROD ist nicht betroffen.

Qualifikationsarten, Referate, Gremien, Sätze: kommen aus Migrationen, nicht aus dem Seed. Die Eigenschaft von Person 5 (Altbestand mit historischer Qualifikationsart) fügt der Seed ohne Nutzerkontext ein; R27 greift dort nicht.

Orte im Seed (neu v0.8, nur TEST, solange der Startbestand [OFFEN] ist): „Kletterhalle Test“ (Punktekonto Kletterhalle ja, aktiv), „Fels Test“ (nein, aktiv), „Halle alt Test“ (nein, inaktiv).

Sätze (neu v0.9): Startbestand per Migration T61 (gültig ab 01.01.2026); der Seed ergänzt nur in TEST einen zweiten Wert `rOrg = 12` gültig ab 01.01.2028 (für US-TK-19 AK2).

Erwartete Ergebnisse der Dublettenprüfung (v0.7.2, Grundlage der pgTAP-Tests T45; Aufruf `ad_find_similar_persons('Toni','Muster',null)`, Treffer 4 und 5):

| Testzugang | Lesestufe Geburtsdatum | `birth_year` Person 4 |
|---|---|---|
| Admin | nur Geschäftsstelle und Admin (Startwert) | 1990 |
| Geschäftsstelle | nur Geschäftsstelle und Admin | 1990 |
| Referent:in (Klettern) | nur Geschäftsstelle und Admin | null |
| Geschäftsstelle | vertraulich (im Test gesetzt) | null |
| Admin | vertraulich (im Test gesetzt) | 1990 |
| Referent:in (Klettern) | alle mit Zugriff (im Test gesetzt) | 1990 |
| Vorstand | – | Fehler `AD_FORBIDDEN` |

Person 5 hat kein Geburtsdatum (`birth_year` immer null).

Namensregel R3a (v0.7.3, pgTAP T45; Aufruf als Admin):

| Aufruf | Erwartete Treffer | Grund |
|---|---|---|
| `('Anton','Muster',null)` | 4 und 5 | 4: „ton“ gemeinsam; 5: gleicher Vorname |
| `('Toni','Muster',null)` | 4 und 5 | 5: „ton“ gemeinsam (similarity nur 0,1) |
| `(' toni ','MUSTER',null)` | 4 und 5 | Trimmen, Groß-/Kleinschreibung |
| `('Paul','Muster',null)` | keine | keine gemeinsame Zeichenfolge, similarity < 0,3 |
| `('Toni','Mustermann',null)` | keine | Nachname nicht gleich |

`ad_first_names_match` direkt: ('Toni','Anton') wahr; ('Jo','Johanna') wahr; ('Ben','Benjamin') wahr; ('Paul','Anton') falsch; ('', 'Anton') falsch; (null,'Anton') falsch. Aufruf mit `p_email = 'paul.nurgruppe@example.test'` liefert Person 12 (Feld `email` der Art `contact`).

Protokoll im Seed: je ein Eintrag `invited`, `template_assigned` (Rita Referentin, Referat Klettern), `locked`, `emergency_login`.

Erwartete Sichtbarkeit (Grundlage der pgTAP-Tests T45; Personen 13–18 v0.9 analog: Geschäftsstelle sieht 13–18 im Pfad EA, Referent:in Klettern keine davon):

| Testzugang | sieht Personen | sieht nicht |
|---|---|---|
| Admin | 1–18 (Pfad AD: alle Personen), alle Lesestufen | – |
| Geschäftsstelle | 4, 5, 9, 10, 11, 13–18 (EA verwalten), Lesestufen „alle mit Zugriff“ und „nur Geschäftsstelle und Admin“ | 1–3, 6–8 (kein AD, kein Ehrenamtsstatus), 12; vertrauliche Eigenschaften |
| Referent:in (Klettern) | 4, 9, 10 (Referat Klettern); bei 10 auch die Funktion im Referat Ausbildung (lesen, nicht ändern) | 5 (nur Ausbildung), 11 (ausgeschieden), 12, 13–18, alle ohne Ehrenamtsstatus; Geburtsdatum; vertrauliche Eigenschaften |
| Vorstand | niemanden | alle |

Erwartete Ergebnisse der Namensfunktionen (v0.8, Grundlage der pgTAP-Tests T56; `ez_person_visible` als Platzhalter `false`):

| Testzugang | `ea_search_active_persons('Muster')` | `ea_search_active_persons('Karl')` | `ea_person_names([4, 5, 12])` |
|---|---|---|---|
| Admin (EZ lesen) | Fehler `AD_FORBIDDEN` | Fehler `AD_FORBIDDEN` | 4, 5, 12 (Pfad AD) |
| Geschäftsstelle (EZ verwalten) | 4 (nicht 5: ruhend) | 10 | 4, 5, 12 (Pfade EA und GR) |
| Referent:in (Klettern, EZ bearbeiten Referat) | 4 | 10 | 4 (Pfad EA Referat) |
| Vorstand | Fehler `AD_FORBIDDEN` | Fehler `AD_FORBIDDEN` | keine |

Zusätzlich: Funktionsperson 8 nie in den Ergebnissen; Suchbegriff „M“ → `AD_SEARCH_TOO_SHORT`; Rückgabe enthält nur die vier Spalten.

Stand v0.8.1 (24.10.2026): an den Seed auf main angeglichen (Personen 1–12, Ehrenamtsmanagement 19–22, Gruppen 23–32). Person 12 ist für die Geschäftsstelle über den Pfad GR sichtbar. Der Nachtrag v0.9 ergänzt bei „Karl“ die Person 18. Weichen die Werte bei der Umsetzung ab, meldet Claude Code die Abweichung (T56).

Erwartete Ergebnisse beim Reaktivieren (v0.8.1, R45a, Grundlage T56; Aufruf `ea_activate_person` mit der Eigenschaftsart `function`, Wert Helfer:in):

| Testzugang | Person | Referat | Ergebnis |
|---|---|---|---|
| Referent:in (Klettern) | 11 Olga Ausgeschieden | Klettern | Ehrenamtsstatus „aktiv“ mit Historie, Funktion Helfer:in im Referat Klettern |
| Referent:in (Klettern) | 12 Paul Nurgruppe (kein Status) | Klettern | „aktiv“, Funktion Helfer:in |
| Referent:in (Klettern) | 5 Anton Muster (ruhend) | Ausbildung | `EA_RELATION_FOREIGN_REFERAT` |
| Referent:in (Klettern) | 5 Anton Muster | Klettern, Wert Trainer:in | `EA_CREATE_FORBIDDEN` |
| Vorstand | 11 | Klettern | `EA_CREATE_FORBIDDEN` |

Erwartete Ergebnisse v0.9 (Grundlage der pgTAP-Tests T65; `tk_person_visible` als Platzhalter `false`):

| Testzugang | `ad_my_referate('TK','edit')` | `ad_my_referate('TKF','edit')` | `ea_search_active_persons('Berg')` | `ea_person_licenses([16, 17, 18], 2027-10-29)` | `ad_rates_at(2028-01-01)` Wert `rOrg` |
|---|---|---|---|---|---|
| Admin (TK lesen) | {} | {} | Fehler `AD_FORBIDDEN` | 16: Bergwandern, bis 30.10.2027, förderfähig, gültig; 18: TCSPI, bis 31.12.2025, nicht gültig | 12 |
| Geschäftsstelle (TK verwalten) | {} (Reichweite alle) | {} | 16 | wie Admin | 12 |
| Tina Touren | {Touren} | {Touren} | 16 | wie Admin | 12 |
| Alex Ausbildung | {Ausbildung} | {} | 16 | wie Admin | 12 |
| Fritz Freigabe | {} | {Touren} | 16 | wie Admin | 12 |
| Rita Referentin (Klettern) | {Klettern} | {} | 16 (wegen EZ bearbeiten) | wie Admin (TK bearbeiten Referat Klettern) | 12 |
| Vorstand | {} | {} | Fehler `AD_FORBIDDEN` | Fehler `AD_FORBIDDEN` | Fehler `AD_FORBIDDEN` |

Zusätzlich: `ad_rates_at(2027-12-31)` liefert `rOrg = 10`; Person 17 ohne Zeile in `ea_person_licenses`; Lizenznummer nie in der Rückgabe; `ad_my_modules` liefert für Fritz Freigabe die Kachel TK (sobald verfügbar), nie TKF; Schreiben in `ad_rates` nur für den Admin.

## 10. Umsetzungs-Tasks

Hinweis: Spec Kit erzeugt aus dieser Spec plan.md und tasks.md mit eigener Nummerierung (im Repository T001 ff.; laut Übergabe aus GR erledigt: T001–T031 für US-AD-01, US-AD-02, US-AD-05). Die folgenden Tn verweisen auf diese Spec.

- [ ] T1: Migration Grundlagen: Erweiterungen, Enums, ad_modules mit Stammdaten (US-AD-01, US-AD-05)
- [ ] T2: Migration Personenmodell: ea_persons, View ea_v_persons (US-AD-07, US-AD-15). v0.7: ea_property_types, ea_properties, ea_property_history und ihre Trigger entstehen nicht hier, sondern in T35/T36.
- [ ] T3: Migration Rechte: ad_templates, ad_template_rights, ad_template_assignments, ad_accesses, Startvorlagen, Funktionen ad_user_level, ad_has_level, ad_my_modules, ad_assign_template, ad_revoke_template (US-AD-01, US-AD-10, US-AD-11)
- [ ] T4: Migration Protokoll: ad_audit_log, ad_notice_acks, Funktionen ad_pending_emergency_logins, ad_acknowledge_emergency, pg_cron-Job Löschung nach 5 Jahren (US-AD-14, US-AD-15)
- [ ] T5: Trigger auf auth.users: Verknüpfung per E-Mail, Status aktiv, Protokoll Notfall-Admin; Trigger `ad_accesses_guard` für R1 (über `ad_login_email_allowed`) und R20; Tabelle `ad_test_login_domains` (US-AD-03, US-AD-08, US-AD-15)
- [ ] T6: View ad_v_person_overview, Funktion ad_me(); Abgleich aller Policies gegen Abschnitt 3 (die Policies selbst entstehen in T1–T4 je Migration) (US-AD-06, US-AD-13 AK4 u. a.)
- [ ] T7: Datenbanktests (pgTAP, `supabase test db`) in einer GitHub Action mit lokalem Supabase-Stack und Seed: je Vorlage Lese-/Schreibrechte, vertrauliche Eigenschaften, Funktionsperson in ea_v_persons, gesperrter Zugang ohne Rechte, Protokoll unveränderbar, R1 mit und ohne Eintrag in `ad_test_login_domains` (Testdomain `example.test` nur innerhalb des Tests), `ad_test_login_domains` für `authenticated` nicht lesbar (alle Rechte-Fälle)
- [ ] T8: Funktion ad_find_similar_persons (US-AD-07). v0.7: neue Rückgabe nach R40 in T43.
- [ ] T9: Edge Function ad-invite inkl. Fehlercodes und Aufräumen bei Fehlern der Auth-Admin-API, mit Test bei simuliertem Fehler (US-AD-08 AK5)
- [ ] T10: Edge Function ad-access mit lock, unlock und change_email (US-AD-08 AK7, US-AD-09)
- [ ] T11: Auth-Konfiguration: Selbstregistrierung aus, Passwortlänge 8, Redirect-URLs, deutsche Mailvorlagen; SMTP-Einstellungen dokumentieren (US-AD-02, 03, 04)
- [ ] T12: Frontend-Grundgerüst: Routing, Routenschutz, Kopfzeile, Fehlercode-Abbildung, /kein-zugriff (US-AD-02, US-AD-05)
- [ ] T13: Screens Login, Passwort vergessen, Passwort setzen, Abmelden (US-AD-02, 03, 04)
- [ ] T14: Startseite mit Willkommensgrafik und Modulkacheln (US-AD-05)
- [ ] T15: Personenübersicht mit Suche, Filter, Notfall-Hinweis (US-AD-06, US-AD-15)
- [ ] T16: Person anlegen mit Dublettendialog (US-AD-07)
- [ ] T17: Personendetail: Stammdaten und Zugang (Login-Adresse ändern, einladen, erneut einladen, sperren, entsperren) (US-AD-08, US-AD-09)
- [ ] T18: Personendetail: Rechtevorlagen zuweisen und entziehen (US-AD-11)
- [ ] T19: Personendetail: Eigenschaften mit Historie (US-AD-13). v0.7: mit Eigenschaftsformular aus T47. v0.7.2: gültig von/bis mit den Bezeichnungen der Eigenschaftsart (R49).
- [ ] T20: Rechtevorlagen Liste und Bearbeiten mit Modul-Matrix (US-AD-10)
- [ ] T21: Eigenschaftsarten Liste und Bearbeiten (US-AD-12). v0.7: ersetzt durch T46.
- [ ] T22: Protokoll-Ansicht (US-AD-14)
- [ ] T23: supabase/seed.sh und supabase/seed.sql nach Abschnitt 9 inkl. Abbruch bei PROD und Passwort aus Umgebungsvariable (US-AD-16). v0.7: Erweiterung in T48.
- [ ] T24: Einrichtungsskript PROD (`supabase/setup/prod-bootstrap.sql`), idempotent, Parameter: Vor-/Nachname und Login-Adresse des Admins; legt Toni Werner (Admin, Vorstand) und Funktionsperson mit Notfall-Zugang (Admin) an; Anleitung für die erste Einladung über das Supabase-Dashboard inkl. Zustellungstest der Login-Mails; bricht ab, wenn `ad_test_login_domains` Einträge hat (US-AD-01)
- [ ] T25: Abnahme in TEST: Dublettenschwelle mit Beispielen (Toni/Anton Muster, Tippfehler; Regel R3a, v0.7.3), alle Stories mit den Testzugängen; Einladung, Adresse ändern, Passwort setzen und Passwort vergessen mit eigenen Adressen des Product Owners nach Abschnitt 9, danach Aufräumen (US-AD-03, US-AD-04, US-AD-07, US-AD-08, US-AD-16)
- [ ] T26: Migration Qualifikationsarten: Enums ad_qualification_kind, ad_license_level, ad_qualification_status; Tabelle ad_qualification_types mit Checks (R21–R24), Indizes, Trigger updated_*, Großschreibung Kürzel; Funktionen ad_has_active_access, ad_can_edit_qualification_types, ad_qualification_usage (v0.7: über field_values); RLS nach Abschnitt 3 (US-AD-17)
- [ ] T27: Migration Startbestand: 47 Qualifikationsarten aus stammdaten-qualifikationsarten.md v0.2, idempotent über source_ref, ohne Überschreiben (US-AD-18)
- [ ] T28: entfällt v0.7 (Datentyp Qualifikationsart je Feld in T35/T36)
- [ ] T29: pgTAP: Lesen für jede Vorlage mit aktivem Zugang, kein Lesen ohne aktiven Zugang; Schreiben nur AD ≥ edit oder EA = manage, Vorstand abgelehnt; kein Löschen; R21–R24, R27, R28 (v0.7 je Feld); T27 zweimal ausführbar ohne Änderung bearbeiteter Einträge (US-AD-17–19)
- [ ] T30: Screens Qualifikationsarten Liste und Formular unter /ad, Navigationseintrag, Fehlercodes in contracts/error-codes.md; Komponenten so, dass /ea/qualifikationsarten sie später ohne Änderung einhängt (US-AD-17)
- [ ] T31: entfällt v0.7 (Datentyp Qualifikationsart und erlaubte Typen je Feld in T46; Auswahlfeld „Qualifikationsart“ bleibt Teil von T46/T47)
- [ ] T32: Seed-Ergänzung nach Abschnitt 9; Abnahme in TEST mit Testzugängen Admin, Geschäftsstelle (nur lesen, solange EA nicht verfügbar; Schreibrecht per Datenbanktest) und Vorstand (US-AD-17–19)

Nachtrag v0.7:
- [ ] T33: Migration Reichweite: Enum `ad_scope`, Umstellung `ad_template_rights.scope` mit Check R30, Tabelle `ad_assignment_referate`, Funktionen `ad_my_referate`, `ad_has_any_level`, neue Fassung von `ad_user_level` (nur Reichweite all) und `ad_my_modules`, `ad_assign_template` mit p_referate (R31), `ad_set_assignment_referate`, Enum-Wert `referate_changed` (US-AD-20, US-AD-21)
- [ ] T34: Migration Stammdaten Referate und Gremien: `ea_referate` (7), `ea_gremien` (4), Trigger updated_*, RLS (US-AD-20, US-AD-22)
- [ ] T35: Migration Eigenschaftsarten: Enums `ea_data_type` (erweitert), `ea_read_level`, `ea_relation_kind`, `ea_property_category`; Tabellen `ea_property_types`, `ea_property_fields`; Trigger (vertraulich nur AD, Bezug und Datentyp gesperrt bei vorhandenen Eigenschaften, Auswahlwerte nur ergänzen, neue Felder optional, Schlüssel unveränderlich); Funktion `ea_save_property_type` (Art mit Feldern in einer Transaktion, R9) (US-AD-22). **v0.7.2 (Ü1):** Spalten `valid_from_label`, `valid_to_label` mit Check ≤ 40 Zeichen, Trimmen und leer → null (Trigger), Annahme in `ea_save_property_type`; ist T35 schon umgesetzt: neue Migration
- [ ] T36: Migration Eigenschaften: `ea_properties` (field_values, Bezugsspalten), `ea_property_history`, Trigger `ea_properties_validate` (R27, R28, R35, R37, R38) und `ea_properties_history` (US-AD-13, US-AD-19, US-AD-22)
- [ ] T37: Migration Personen: neue Spalten an `ea_persons` (preferred_name, created_in, volunteer_status, volunteer_status_since) mit Checks und Indizes; Bestand `created_in = 'AD'`; Tabelle `ea_volunteer_status_history`; Trigger, der direkte Änderungen von volunteer_status, kind und created_in verhindert (US-AD-23, US-AD-24)
- [ ] T38: Migration Sichtbarkeit: Funktionen `ea_person_in_referate`, `ea_person_visible_ad`, `ea_person_visible_ea`, `gr_person_visible` (Platzhalter false), `ea_person_visible`, `ea_property_readable`, `ea_property_writable`; Policies auf ea_persons (ersetzen die bestehenden aus `20261020000200_ea_persons.sql`), ea_volunteer_status_history, ea_property_types, ea_property_fields, ea_properties, ea_property_history (US-AD-23)
- [ ] T39: Migration EA-Funktionen: `ea_set_volunteer_status`, `ea_person_referate`, `ea_create_volunteer`, `ea_activate_person` (US-AD-23)
- [ ] T40: Migration Startvorlagen: Vorlage „Referent:in“ (EA bearbeiten, Reichweite Referat), Admin GR = read (E5) (US-AD-20)
- [ ] T41: Anpassung `ad_v_person_overview` (Rufname, Ehrenamtsstatus, Referate), `ad_me` (Rufname), `ad_qualification_usage` (field_values) (US-AD-06, US-AD-24)
- [ ] T42: Fehlercodes v0.7 in contracts/error-codes.md (US-AD-20 bis US-AD-25); v0.7.2: `EA_LABEL_TOO_LONG`
- [ ] T43: Funktion `ad_find_similar_persons` neu nach R40, inkl. Rufname und E-Mail aus den Feldern `email`, `dav_email` der Art `contact` (US-AD-25). **v0.7.3:** Namensregel über `ad_first_names_match` (R3a) statt „Teilwort“. **v0.7.2 (Ü2):** `birth_year` aus Feld `date` der Art `birth_date`, nur nach Lesestufe und Rechten (Abschnitt 2, R40); ist T43 schon umgesetzt: neue Migration mit `create or replace` (gleiche Signatur und Rückgabe)
- [ ] T44: Frontend: Reichweite in der Vorlagen-Matrix (R30); Referate beim Zuweisen und Ändern (R31); Anzeige der Referate in Übersicht und Personendetail (US-AD-20, US-AD-21)
- [ ] T45: pgTAP Nachtrag: Sichtbarkeitsmatrix aus Abschnitt 9; R29–R42; Tests aus der Übergabe GR: Teilnehmer:in ohne Ehrenamtsstatus nicht lesbar mit nur EA-Rechten (Person 12, sofort), mit AD-Rechten lesbar (v0.7.1); Erziehungsberechtigte:r zugleich Trainer:in über EA lesbar ohne gruppenspezifische Daten; ein Nutzer mit nur „Gruppen lesen“ (ohne AD) liest Kontaktdaten eines Kindes, nicht dessen Geburtsdatum (A2; der Admin liest es über AD); Funktion mit Gruppenbezug in EA nicht änderbar (diese drei mit der ersten GR-Migration); Mengentest Abschnitt 8; **v0.7.2:** Tabelle „Erwartete Ergebnisse der Dublettenprüfung“ in Abschnitt 9; **v0.7.3:** Tabelle „Namensregel R3a“ in Abschnitt 9; Bezeichnungen: 41 Zeichen abgelehnt, „  “ → null, Rechte wie die übrigen Spalten (Referent:in und Vorstand abgelehnt) (US-AD-20 bis US-AD-26)
- [ ] T46: Frontend: Eigenschaftsarten Liste und Formular mit Feldern, Kategorie, Lesestufe, Bezug; Datentyp Qualifikationsart mit erlaubten Typen je Feld; v0.7.2: Eingaben „Bezeichnung für ‚gültig von‘/‚gültig bis‘“ (R49) (US-AD-12, US-AD-19, US-AD-22)
- [ ] T47: Frontend: wiederverwendbares Eigenschaftsformular und Auswahlfeld „Qualifikationsart“; Anzeige nach Kategorie im Personendetail; Rufname in Stammdaten, Suche und Namensanzeige; Ehrenamtsstatus nur lesen; v0.7.2: Bezeichnungen „gültig von/bis“ im Eigenschaftsformular, in der Anzeige und in der Fehlermeldung (R49) (US-AD-13, US-AD-19, US-AD-22, US-AD-23, US-AD-24)
- [ ] T48: Seed-Erweiterung nach Abschnitt 9 (Personen 9–12, Testzugang Referent:in, Testarten mit Feldern) (US-AD-26). v0.7.2: Feldschlüssel nach 01-erhebung.md EA C2, `system_key = 'contact'` an „Kontaktdaten (Test)“, „gültig bis“ an der Lizenz von Person 5
- [ ] T49: Frontend: Dublettendialog nach R40 als wiederverwendbare Komponente, Geburtsjahr nur, wenn geliefert (v0.7.2); Abnahme in TEST mit den Testzugängen Admin, Geschäftsstelle, Referent:in und Vorstand (US-AD-25, US-AD-26)

Nachtrag v0.8 (Anwesenheitserfassung; Voraussetzung T33, T38, T39, T40; vor der ersten Migration der Anwesenheitserfassung). T50 und R30 für EZ sind außerdem Voraussetzung der EZ-Pfade in `gr_group_roster` und `gr_groups_for_attendance` (Übergabe GR Ü5):
- [ ] T50: Migration Modul EZ: Zeile `EZ` / „Anwesenheitserfassung“ in `ad_modules` (`is_available = false`); `ad_template_rights` je vorhandener Vorlage um EZ ergänzen (`none`); Startwerte Admin `read`, Geschäftsstelle `manage`, Referent:in `edit` mit scope `referat`, Vorstand `none` – ohne Änderungen des Admins zu überschreiben; Check auf `ad_template_rights.scope` nach R30 (EA und EZ); Check `ea_persons.created_in` um `EZ` erweitern (Übergabe EZ A1, A2)
- [ ] T51: Migration Orte: Tabelle `ad_locations` mit Unique-Index auf lower(name), Trigger updated_*, Funktion `ad_can_edit_locations`, RLS nach Abschnitt 3, kein Delete (A8, R43)
- [ ] T52: Migration Namensfunktionen: `ez_person_visible` (Platzhalter false), `ea_person_names`, `ea_search_active_persons` mit Index-Nutzung (`pg_trgm` auf first_name, preferred_name, last_name), Grants nur an `authenticated` (A3, R44)
- [ ] T53: Migration Anlegen aus der Anwesenheitserfassung: `ea_create_volunteer` um EZ-Rechte, Einschränkung auf `{"function":"Helfer:in"}`, `created_in = 'EZ'` und Parameter `p_contact_email` (Feld `email` der Art `contact`) erweitern; `ad_find_similar_persons` für EZ ≥ edit freigeben (A4, R45); `ea_activate_person` um den Pfad der Anwesenheitserfassung erweitern (A9, R45a)
- [ ] T54: Fehlercodes v0.8 in contracts/error-codes.md (`AD_LOCATION_NAME_REQUIRED`, `AD_LOCATION_NAME_TAKEN`, `AD_SEARCH_TOO_SHORT`, `AD_TOO_MANY_IDS` mit der allgemeinen Meldung, `EA_CREATE_FORBIDDEN`, `EA_RELATION_FOREIGN_REFERAT` auch für EZ; `EA_CREATE_FOREIGN_REFERAT` als entfallen kennzeichnen; neuer Text für `AD_SCOPE_NOT_ALLOWED`)
- [ ] T55: Frontend: Zeile Anwesenheitserfassung und Reichweite „Referat“ für EZ in der Vorlagen-Matrix (R30); Screens /ad/orte Liste und Formular mit Navigationseintrag; Komponenten „Personensuche Aktive“ und „Auswahlfeld Ort“ für die Anwesenheitserfassung (A8)
- [ ] T56: pgTAP Nachtrag v0.8: Startwerte EZ je Vorlage; Reichweite „Referat“ für EZ erlaubt, für GR abgelehnt (`AD_SCOPE_NOT_ALLOWED`); `ad_my_referate('EZ','edit')` für Rita Referentin = {Klettern}; Orte: Lesen mit aktivem Zugang, Schreiben nur `ad_can_edit_locations()`, kein Löschen, R43; Namensfunktionen nach der Tabelle in Abschnitt 9 inkl. Spaltenliste; `ea_create_volunteer` über EZ-Rechte: Referent:in Klettern legt Helfer:in für Klettern an (`created_in = 'EZ'`, Status aktiv, Funktion Helfer:in), für Ausbildung abgelehnt (`EA_RELATION_FOREIGN_REFERAT`), mit Funktion Trainer:in abgelehnt (`EA_CREATE_FORBIDDEN`); `ea_activate_person` über EZ-Rechte nach der Tabelle „Reaktivieren“ in Abschnitt 9 (A9, R45a); Mengentest Abschnitt 8 (A1–A4, A8)
- [ ] T57: Seed-Ergänzung v0.8: Orte nach Abschnitt 9; Testzugänge erhalten die EZ-Startwerte über ihre Vorlagen (A5). v0.9.1: kein `system_key` an Testarten mehr nötig, der Seed nutzt seit der ersten EA-Migration die System-Eigenschaftsarten (Ü3)
- [ ] T58: Abnahme in TEST mit den Testzugängen Admin (EZ nur lesen), Geschäftsstelle, Referent:in (Klettern) und Vorstand (kein Zugriff): Vorlagen-Matrix, Orte pflegen (nur Admin), Namenssuche und Anlegen per SQL-Aufruf, solange die Oberfläche der Anwesenheitserfassung fehlt (A1–A5, A8)

Nachtrag v0.9 (Planungshilfe Touren und Kurse; Voraussetzung T33–T40, T52; vor der ersten Migration der Planungshilfe):
- [ ] T59: Migration Module TK und TKF: Spalte `ad_modules.is_hidden` (Default false); Zeilen `TK` und `TKF` (`is_available = false`, TKF `is_hidden = true`); `ad_my_modules` ohne `is_hidden`, Kachel TK auch bei `ad_has_any_level('TKF','edit')`; `ad_template_rights` je vorhandener Vorlage um TK und TKF ergänzen (`none`); Startwerte Admin TK `read`, Geschäftsstelle TK `manage`, Referent:in TK `edit` mit scope `referat`, Vorstand `none`; neue Vorlage „Freigabe Touren und Kurse“ mit TKF `edit` scope `referat`, übrige `none` – ohne Änderungen des Admins zu überschreiben; Checks R30 (Reichweite für EA, EZ, TK, TKF; TKF nur `none`/`edit`) (Übergabe TK 1–3, 9, 11)
- [ ] T60: Migration Sätze: Enum `ad_rate_group`, Tabelle `ad_rates` mit Checks, Unique `(rate_key, valid_from)`, Trigger updated_* und Sperre von `rate_key`/`valid_from`; Funktionen `ad_can_edit_rates`, `ad_can_read_rates`, `ad_rates_at`; RLS nach Abschnitt 3, kein Delete (R46; Übergabe TK 10, 12)
- [ ] T61: Migration Startbestand Sätze: alle Schlüssel aus spec.md TK Abschnitt 7 mit Werten, Einheiten und Quellen aus prototyp-tourenkonzept.md 5.1–5.4, gültig ab 01.01.2026, idempotent ohne Überschreiben (Übergabe TK 13)
- [ ] T62: Migration Namen und Lizenzen für TK: `tk_person_visible` (Platzhalter false); `ea_person_names` um `tk_person_visible` erweitern; `ea_search_active_persons` für TK ≥ edit und TKF freigeben; `ea_person_licenses` nach Abschnitt 2, Feldschlüssel `qualification_type`, `valid_until` ohne Rückfall auf `valid_to` (R47, R48; Übergabe TK 4, 5, 8, 12)
- [ ] T63: Fehlercodes v0.9 in contracts/error-codes.md (`AD_LEVEL_NOT_ALLOWED`, `AD_RATE_DUPLICATE`, `AD_RATE_VALUE`, `AD_RATE_FIELD_REQUIRED`, `AD_RATE_LOCKED`; neuer Text für `AD_SCOPE_NOT_ALLOWED`)
- [ ] T64: Frontend: Zeilen Planungshilfe und Freigabe in der Vorlagen-Matrix (R30, Stufen bei TKF eingeschränkt); Screens /ad/saetze mit „Stand am“, Historie und „Neuer Wert“; Navigationseintrag „Sätze“; Personensuche „Aktive“ für TK freigeben
- [ ] T65: pgTAP Nachtrag v0.9: Startwerte TK/TKF je Vorlage; Reichweite „Referat“ für TK/TKF erlaubt; TKF `manage` abgelehnt (`AD_LEVEL_NOT_ALLOWED`); Tabelle „Erwartete Ergebnisse v0.9“ in Abschnitt 9; `ad_rates`: Lesen nach `ad_can_read_rates`, Schreiben nur Admin, R46, kein Löschen, `ad_rates_at` nach Datum; `ea_person_licenses`: Spaltenliste ohne Lizenznummer, nur Lesestufe „alle mit Zugriff“, Funktionsperson und ausgeschiedene Personen nie; Mengentest Abschnitt 8
- [ ] T66: Seed-Ergänzung v0.9: Personen 13–18 mit Zugängen und Vorlagen (inkl. Referaten), Eigenschaften über die System-Eigenschaftsarten Funktion, Amt und Lizenz (v0.9.1, Ü3), zweiter Wert `rOrg` gültig ab 01.01.2028 (nur TEST)
- [ ] T67: Abnahme in TEST mit Admin (Sätze pflegen, Freigabe-Vorlage vergeben und entziehen inkl. Protokoll), Geschäftsstelle (Sätze nur lesen), Tina Touren, Alex Ausbildung, Fritz Freigabe (per SQL-Aufruf der Funktionen, solange die Oberfläche der Planungshilfe fehlt), Vorstand (kein Zugriff)

## 11. Annahmen und offene Punkte

Bestätigt vom Product Owner am 19.10.2026: alle Annahmen aus Steckbrief, Erhebung und Stories sowie die technischen Festlegungen dieser Spec:
- Tabellen des Personenmodells mit Präfix `ea_`, obwohl sie mit AD entstehen (Benennung nach tech-stack.md).
- AD „bearbeiten“ und „verwalten“ sind im MVP gleichwertig, da AD keine Löschfunktionen hat.
- Datenzugriffe enden beim Sperren oder Entziehen sofort (RLS prüft Status), die Frontend-Sitzung bis zu 1 Stunde später.
- Ähnlichkeitsschwelle 0,3 (pg_trgm) als Startwert; endgültig nach Abnahme T25. v0.7.3: ergänzt um gemeinsame Zeichenfolge ≥ 3 Buchstaben und „enthalten“ (R3a).
- [ANNAHME] v0.7.3: Namensregel R3a statt „Teilwort“ (Rückfrage aus T43, 22.10.2026): Toni/Anton erreicht weder similarity (0,1) noch word_similarity (ca. 0,2) die Schwelle. Mehr Fehltreffer bei gleichem Nachnamen (z. B. Anna/Hannah) werden in Kauf genommen. Kein Abgleich von Kosenamen-Listen (z. B. Sepp/Josef) im MVP.
- Testadressen @dav-leipzig.de im Seed existieren nicht als Postfächer.
- Personenübersicht ohne Paginierung bis ca. 300 Personen. (v0.7.1 ersetzt: Paginierung, da der Admin alle Personen aller Module sieht.)

Entschieden vom Product Owner am 19.10.2026 (v0.3, aus der Prüfung durch /speckit-plan):
- Statuswechsel an das Passwort gekoppelt: Anlage in Supabase Auth → „eingeladen“, erstes Passwort → „aktiv“ (W1, W2).
- Login-Adresse nur vor der Aktivierung änderbar (R20).
- Seed über seed.sh mit Abbruch bei PROD; pgTAP-Tests in GitHub Action mit lokalem Stack; Abnahme in TEST (W5, W6).
- Policies je Migration, `ad_has_level` in T1; interne Statusfunktionen nur an `service_role`; zusätzliche Fehlercodes mit deutschen Meldungen; Löschlauf 01:15 UTC; Funktion `ad_me()`; Zustellungstest bei der Ersteinrichtung von PROD (A1–A5, P1, W7–W13).

Entschieden vom Product Owner am 19.10.2026 (v0.4, aus dem Abgleich des Plans):
- Login-Adresse bei „eingeladen“ ändern nimmt die Einladung zurück (Auth-Eintrag löschen, Status „kein Zugang“), damit der alte Link nicht mehr gilt (R20).
- `ad-invite` räumt bei Fehlern der Auth-Admin-API selbst auf; der Status bleibt unverändert (US-AD-08 AK5).

Entschieden vom Product Owner am 20.10.2026 (v0.5):
- Abnahme der Mail-Abläufe in TEST mit eigenen privaten Adressen des Product Owners; Datenschutz nicht betroffen (eigene Daten). Ausnahme in Constitution V (Version 1.1.0).
- R1 per Trigger statt Check-Constraint; zusätzliche Domains nur in TEST über `ad_test_login_domains`, befüllt per SQL-Editor; PROD bleibt bei @dav-leipzig.de (Variante B).
- Aufräumen nach der Abnahme über das TEST-Dashboard; keine Löschfunktion in der Oberfläche.

Entschieden vom Product Owner am 21.10.2026 (v0.6):
- Qualifikationsarten sind Stammdaten der Administration; EA und spätere Module greifen per Verweis darauf zu.
- Pflege durch Admin und Geschäftsstelle; die Geschäftsstelle pflegt über „EA verwalten“ ohne Rechte auf AD.
- Die Sparte (Klettersport, Bergsport Sommer, Berg- und Klettersport Winter, Jugend und Familie) ist eine Klassifizierung des Bundesverbands nur für Qualifikationsarten, ohne Bezug zu Referaten.
- Startbestand: Liste stammdaten-qualifikationsarten.md (47 Einträge) inkl. historischer Einträge; historische sind nicht neu vergebbar.

Annahmen v0.6 (bei Abnahme bestätigen):
- [ANNAHME] Lesen der Qualifikationsarten für alle Nutzer mit aktivem Zugang (keine Personendaten).
- [ANNAHME] Änderung der Gültigkeitsdauer ohne Rückwirkung auf vorhandene Ablaufdaten (R26).
- [ANNAHME] Sparte und Aussteller als Text mit Vorschlägen statt fester Liste.
- [ANNAHME] Änderungen an Qualifikationsarten nur mit updated_at/by, ohne Protokolleintrag.
- [ANNAHME] PSA wird bis zur Entscheidung als historisch angelegt.

Entschieden vom Product Owner am 21.10.2026 (v0.7, aus Steckbrief EA v0.3–v0.6 und Übergabe GR v1.0):
- Rechtevorlage Referent:in mit „EA bearbeiten“ und Reichweite „Referat“ im MVP; Hüttenwart:innen erhalten dieselbe Vorlage; eine Person kann mehrere Referate haben.
- Referate (7) und Gremien (4) als Stammdaten; Zuordnung von Personen über Funktion bzw. Amt mit Bezug.
- Drei feste Lesestufen je Eigenschaftsart (Option A); frei wählbare Leserechte nach MVP.
- Eigenschaftsart mit mehreren Feldern und Kategorie; Rufname an der Person.
- Ehrenamtsstatus aktiv, ruhend, ausgeschieden; manuell, für die ganze Person; Referent:innen setzen alle drei Status; Ausgeschiedene nur für Geschäftsstelle und Admin; Rückkehr ohne neue Person.
- E1: Eine gemeinsame Personen-Tabelle für Aktive, Teilnehmer:innen, Erziehungsberechtigte und Notfallkontakte.
- E2: AD zeigt nur Personen mit Zugang, Funktionspersonen und Personen mit Ehrenamtsstatus; Personen nur aus Gruppen nicht. **Ersetzt am 21.10.2026 (v0.7.1):** Der Admin sieht immer alle Personen aller Module, damit Vollständigkeit herstellbar ist.
- E3: EA zeigt nur Personen mit Ehrenamtsstatus. E4: GR zeigt nur Personen mit Gruppenbezug.
- E5: Rechtevorlage Admin erhält „Gruppen lesen“; Vorstand bleibt ohne Rechte.
- E6: Zugänge schrittweise (Referent:innen und Vorstand, dann Gruppenleitungen, dann Stellvertretungen und weitere Trainer:innen); Erziehungsberechtigte und Teilnehmer:innen nie.
- Dublettenwarnung modulübergreifend mit Vorname, Nachname, Geburtsjahr bzw. „ausgeschieden seit“ (US-GR-06 AK2). **Ergänzt am 22.10.2026 (v0.7.2):** Geburtsjahr nur nach Lesestufe und Rechten (R40).

Entschieden vom Product Owner am 21.10.2026 (v0.7.1, Freigabe des Nachtrags):
- Der Admin (AD ≥ lesen) sieht alle Personen aller Module mit allen Eigenschaften (alle Lesestufen); gruppenspezifische Daten in `gr_`-Tabellen regelt das Modul Gruppen. Damit entfällt die Annahme „in AD angelegte Personen“.
- Referent:innen dürfen Personen aus anderen Modulen über die Dublettenwarnung ins Ehrenamtsmanagement übernehmen (`ea_activate_person`) und sehen danach deren Eigenschaften mit Lesestufe „alle mit Zugriff“.
- Lesestufe „nur Geschäftsstelle und Admin“ = Stufe „verwalten“ (Reichweite alle) im jeweiligen Modul (A2).

Annahmen v0.7 (bei Abnahme bestätigen):
- [ANNAHME] Personenübersicht in AD mit Filter „Zugehörigkeit“ und Paginierung (50 je Seite).
- [ANNAHME] Datenschutz: Mit der Vorlage Admin sieht auch der Notfall-Admin (Postfach der Geschäftsstelle) alle Personen inkl. Kontaktdaten und Geburtsdatum von Kindern; Risiko wie beim Notfall-Admin akzeptiert, Gegenmaßnahme Protokoll und Hinweis.
- [ANNAHME] Werte der Felder als `jsonb` an der Eigenschaft (eine Zeile je Eigenschaft, RLS je Zeile); Bezug auf Referat, Gremium und Gruppe als eigene Spalten für RLS und Filter; Qualifikationsart im `jsonb` ohne Fremdschlüssel, Existenz per Trigger geprüft.
- [ANNAHME] Referent:innen legen Personen nur zusammen mit einer ersten Zuordnung zu einem eigenen Referat an (`ea_create_volunteer`).
- [ANNAHME] Eigenschaftsarten mit Bezug „Gruppe“ legen nur Nutzer mit GR = verwalten (zusätzlich zu AD/EA) an.
- [ANNAHME] Referate und Gremien pflegen AD ≥ bearbeiten oder EA = verwalten; Oberfläche dafür in EA.
- [ANNAHME] `gr_person_visible` wird in AD als Platzhalter (false) angelegt und von der ersten GR-Migration ersetzt.
- [ANNAHME] Mengengerüst 1.000 Personen für den Leistungstest.
- [ANNAHME] Ehrenamtsstatus in AD nur lesen; Pflege in EA.
- [ANNAHME] Dublettenprüfung per E-Mail zusätzlich gegen E-Mail-Felder der Kategorie Kontakt. (v0.9.1 präzisiert: Felder `email`, `dav_email` der Art `contact`.)

Entschieden vom Product Owner am 21./22.10.2026 (v0.8, Übergabe aus der Anwesenheitserfassung v1.2; auf Wunsch des Product Owners im Chat Anwesenheitserfassung eingearbeitet):
- Modulname „Anwesenheitserfassung“, Kürzel EZ.
- Startwerte: Admin lesen, Geschäftsstelle verwalten, Referent:in bearbeiten mit Reichweite Referat, Vorstand ohne Rechte (Ziel lesen, vom Admin zu setzen) (A1).
- Reichweite „Referat“ auch für die Anwesenheitserfassung mit denselben Referaten der Zuweisung (A2).
- Die Anwesenheitserfassung sieht von Personen nur Namen; wer Einsätze anlegen darf, sucht die organisierende Person über alle Aktiven (A3, 22.10.2026).
- Beim Arbeitseinsatz können neue Personen angelegt werden; sie werden Aktive (Ehrenamtsstatus „aktiv“) (A4; glossar.md „Aktive:r“).
- Orte sind Stammdaten der Administration, gepflegt vom Admin (A8, 22.10.2026).
- Reihenfolge der Module: Gruppen → Anwesenheitserfassung → Finanzen (22.10.2026).

Bestätigt vom Product Owner am 24.10.2026 (Nachtrag v0.8.1, Status Ready; vorher Annahmen v0.8):
- Kein vierter RLS-Pfad für die Anwesenheitserfassung; Namen nur über die Funktionen `ea_person_names` und `ea_search_active_persons` (Datensparsamkeit, R44).
- `ez_person_visible` wird in AD als Platzhalter (false) angelegt und von der ersten Migration der Anwesenheitserfassung ersetzt; Inhalt nach spec.md EZ v0.4 (Personen in lesbaren Einsätzen, Entscheidung unten).
- Die Suche über alle Aktiven liefert nur Status „aktiv“ (nicht „ruhend“) und nur an Nutzer mit EZ ≥ bearbeiten; höchstens 50 Treffer, ab 2 Zeichen.
- Aus der Anwesenheitserfassung angelegte Personen erhalten genau die Funktion Helfer:in mit Bezug auf das Referat des Einsatzes; optional Kontakt-E-Mail; `created_in = 'EZ'`.
- System-Schlüssel `function` und `contact` für die Eigenschaftsarten Funktion und Kontaktdaten: festgelegt in 01-erhebung.md EA C2 (Feldschlüssel `function`, `email`; v0.9.1).
- Ort mit Kennzeichen „Punktekonto Kletterhalle“; Lesen für alle Nutzer mit aktivem Zugang; nie löschen, nur inaktiv.
- Neue Vorlagen erhalten für EZ die Stufe `none`; die Migration überschreibt keine Änderungen des Admins.
- Höchstens 500 IDs je Aufruf von `ea_person_names`; Antwortzeit < 300 ms.

Entschieden vom Product Owner am 24.10.2026 (Nachtrag v0.8.1; Übergabe EZ v1.5 A9, Abgleich mit spec.md EZ v0.4):
- A9: `ea_activate_person` erhält den Pfad der Anwesenheitserfassung; ruhende und ausgeschiedene Personen werden beim Arbeitseinsatz direkt wieder aktiv eingetragen, auch wenn sie zuletzt in einem anderen Referat aktiv waren (R45a). Die Annahme „aus der Anwesenheitserfassung … nicht reaktiviert“ entfällt.
- Inhalt von `ez_person_visible` nach spec.md EZ v0.4 (nur Personen in lesbaren Einsätzen), nicht mehr Gruppen und Aktive der Referate.
- Die Rechteprüfung des EZ-Wegs steht in `ea_activate_person` selbst (`ad_has_level('EZ','edit')` oder Referat aus `ad_my_referate('EZ','edit')`), kein Platzhalter `ez_can_write` in der Administration.
- Über den EZ-Weg zulässig sind auch Personen ohne Ehrenamtsstatus; bei „aktiv“ bleibt der Status, die Funktion wird ergänzt.
- Auch beim Reaktivieren über EZ nur die Funktion Helfer:in.
- Fremdes Referat meldet für EA und EZ `EA_RELATION_FOREIGN_REFERAT`; `EA_CREATE_FOREIGN_REFERAT` entfällt.
- `AD_TOO_MANY_IDS` ohne eigenen Meldungstext (allgemeine Meldung).
- Orte: kein Startbestand im Nachtrag v0.8 (nur Testorte im Seed); Startbestand vor der Freigabe der Anwesenheitserfassung; Pflege nur Admin (22.10.2026).
- Erwartete Ergebnisse der Namensfunktionen an den Seed auf main angeglichen (Abschnitt 9).
- Eigene Stories US-AD-27 bis US-AD-30 für den Nachtrag v0.8.
- Q2 aus dem Querschnitts-Check: `ea_person_names` wird je Modul erweitert (v0.8 EZ, v0.9 TK).

Entschieden vom Product Owner am 22.10.2026 (v0.9, Übergabe aus der Planungshilfe Touren und Kurse v1.6; auf Wunsch des Product Owners im Chat Planungshilfe Touren und Kurse eingearbeitet, weil der Chat der Administration in einem anderen Projekt liegt):
- Modulname „Planungshilfe Touren und Kurse“, Kürzel TK; Nutzer im MVP Referent:innen Touren und Ausbildung und Geschäftsstelle.
- Freigabe von Touren und Kursen liegt bei den Referent:innen und ist delegierbar; das Freigaberecht vergibt und entzieht der Admin; wer es hat, darf Planungen auch bearbeiten und Rückfragen stellen.
- Sätze und Pauschalen (u. a. Organisationspauschale, Tagessätze, Hüttenpauschalen) sind Stammdaten der Administration; Pflege vorerst nur durch den Admin; Finanzen nutzt dieselben Sätze.
- Keine Stornoregel in den Sätzen.
- Lizenz-Stichtag für den Trainersatz: erster Tag der Tour (Prüfung in der Planungshilfe über `ea_person_licenses` mit dem Startdatum).

Annahmen v0.9 (bei Abnahme bestätigen):
- [ANNAHME] Freigaberecht als zweites Modul TKF ohne Seiten (`is_hidden`), Stufe „bearbeiten“ = freigeben; Alternative wäre eine neue Aktion „freigeben“ im Rechtemodell.
- [ANNAHME] Startwerte TK: Admin lesen, Geschäftsstelle verwalten, Referent:in bearbeiten mit Reichweite Referat, Vorstand ohne; die Geschäftsstelle erhält kein Freigaberecht.
- [ANNAHME] Wer nur die Vorlage „Freigabe Touren und Kurse“ hat, sieht die Kachel der Planungshilfe.
- System-Schlüssel `license` und Feldschlüssel `qualification_type`, `valid_until` für die Eigenschaftsart Lizenz: festgelegt in 01-erhebung.md EA C2 (v0.9.1).
- [ANNAHME] „Förderfähig“ = Qualifikationsart mit `dosb_eligible = true` (glossar.md „Lizenz“).
- [ANNAHME] `ea_person_licenses` liefert nur Lizenzen aus Eigenschaftsarten mit Lesestufe „alle mit Zugriff“, höchstens 50 IDs, ohne Lizenznummer.
- [ANNAHME] Änderungen an Sätzen nur mit updated_at/by, ohne Protokolleintrag; nie löschen.
- [ANNAHME] Lesen der Sätze für AD lesen, TK lesen (beide Reichweiten), TKF und FI lesen.
- [ANNAHME] Seed-Lizenz „Trainer*in C Bergwandern“ ist im Startbestand der Qualifikationsarten enthalten und DOSB-lizenzfähig; sonst wird eine passende Qualifikationsart verwendet.

Entschieden vom Product Owner am 23.10.2026 (Kern v0.7.4, Review des Kerns):
- Referent:innen schreiben mit Reichweite „Referat“ nur Eigenschaften mit Bezug auf ein eigenes Referat; Eigenschaften ohne Bezug pflegen Geschäftsstelle und Admin (R42). Gewollt.
- US-AD-06 AK5 an R32 angeglichen: Die Geschäftsstelle liest Personen nach ihrem Pfad (EA), die Seite /ad bleibt für sie gesperrt. Den Ehrenamtsstatus setzt sie über EA (R33); mehr Rechte vergibt der Admin über die Rechtevorlage.
- Person anlegen: R1 wird vor dem Anlegen im Frontend über `ad_login_email_ok` geprüft, damit keine Person ohne Zugang stehen bleibt.
- Einladung über das Supabase-Dashboard (Ersteinrichtung) wird protokolliert (Trigger, Eintrag ohne Akteur).

Entschieden vom Product Owner am 22.10.2026 (Kern v0.7.2, Übergabe aus dem Ehrenamtsmanagement v1.1):
- Ü1: Bezeichnungen „gültig von/bis“ je Eigenschaftsart, höchstens 40 Zeichen; Startwerte setzt die erste EA-Migration (R49).
- Ü2: Geburtsjahr in der Dublettenwarnung nur für Geschäftsstelle und Admin (Datensparsamkeit); ergänzt um die Kopplung an die Lesestufe der Eigenschaftsart Geburtsdatum (R40).
- Ü3: Testarten mit `system_key` gelten nur bis zur ersten EA-Migration; danach Seed über die System-Eigenschaftsarten (Umsetzung durch das Ehrenamtsmanagement).
- TEST wird vor der ersten EA-Migration zurückgesetzt und neu befüllt (Abschnitt 9).
- Ü1 und Ü2 gehören zum Kern (T35, T43); sind diese Tasks schon umgesetzt, folgt eine neue Migration. spec.md EA T0a/T0b prüfen dann nur noch.

Annahmen v0.7.2 / v0.9.1 (bei Abnahme bestätigen):
- [ANNAHME] Meldung „gültig bis vor gültig von“ mit den Bezeichnungen der Eigenschaftsart, erste Bezeichnung mit großem Anfangsbuchstaben; Fehlercode `EA_LABEL_TOO_LONG`.
- [ANNAHME] `birth_year` aus der heute gültigen Geburtsdatum-Eigenschaft, sonst der mit dem spätesten „gültig von“; die Lesestufe wird ohne Prüfung der Sichtbarkeit des Treffers angewandt (Zweck der Dublettenwarnung).
- [ANNAHME] Dublettenprüfung per E-Mail gegen Login-Adresse und die Felder `email` und `dav_email` der Art `contact` (ersetzt „E-Mail-Felder der Kategorie Kontakt“).
- [ANNAHME] Testarten im Kern-Seed mit den Feldschlüsseln aus EA C2; „Kontaktdaten (Test)“ trägt schon im Kern `system_key = 'contact'`; Person 5 erhält „gültig bis 31.12.2019“.
- `ea_create_volunteer` über EZ-Rechte nimmt genau `{"function":"Helfer:in"}` an (keine Trainingseinheiten); bestätigt 24.10.2026.
- [ANNAHME] `ea_person_licenses` ohne Rückfall auf `valid_to`.

Vorgemerkt für Iteration 1 der Anwesenheitserfassung (nicht MVP):
- A6 – Reichweite „Gruppe“: Enum-Wert `group` für `ad_scope`, Tabelle `ad_assignment_groups` (analog `ad_assignment_referate`), Funktion `ad_my_groups(p_module, p_min)`; bei Zuweisung legt der Admin eine oder mehrere Gruppen fest [ANNAHME]; zunächst nur für die Anwesenheitserfassung.
- A7 – Rechtevorlage „Gruppenleitung“: EZ bearbeiten mit Reichweite „Gruppe“ (Einsätze der eigenen Gruppen anlegen, Anwesenheit erfassen); dieselbe Vorlage für Trainer:innen [ANNAHME]; Zugänge nach E6.

Vorgemerkt für später (Planungshilfe):
- Reichweite „nur eigene“ für Tourenleitende (Iteration 2 der Planungshilfe; öffentliches Formular oder Zugang [OFFEN]).
- Pflege der Sätze auch durch Geschäftsstelle oder Referent:innen (Erweiterung von `ad_can_edit_rates`).

Offen (kein Blocker für AD):
- [OFFEN] Wie kommen Migrationen nach PROD (manuell durch den Product Owner oder GitHub Action beim Merge auf main)? Klärung vor dem ersten PROD-Deployment; bis dahin wird PROD nicht angefasst.
- [OFFEN] Vertretung des Admin-Zugangs (Toni Werner).
- [OFFEN] Löschlauf nach 5 Jahren über alle Pfade (A8 der Übergabe GR): Person nur löschen, wenn kein Pfad sie mehr braucht; Löschung des Zugangs. Nach MVP. Ab v0.8 inklusive Anwesenheiten (Aufbewahrungsfrist im Modul Anwesenheitserfassung), ab v0.9 inklusive Leitung in Planungen.
- [OFFEN] Startbestand der Orte: liefert der Product Owner vor der Freigabe der Anwesenheitserfassung (eigene Migration).
- [OFFEN] Echte Gültig-ab-Daten der Sätze (Startbestand nutzt 01.01.2026); Bestätigung der Prototyp-Annahmen durch das Referat Touren (spec.md TK Abschnitt 11).
- [OFFEN] Eigene Rechtevorlage für Trainer:innen oder dieselbe wie Gruppenleitung (Iteration 1)?
- [OFFEN] Stories für den Nachtrag v0.9 (US-AD-31 ff.) nachziehen oder Abnahme über T65/T67 genügen lassen (v0.8: Stories US-AD-27 bis US-AD-30, entschieden 24.10.2026).
- [OFFEN] Q1 aus dem Querschnitts-Check ist entschieden (24.10.2026): eine eigene Aktion „freigeben“ im Rechtemodell statt des Musters „Modul ohne Seiten“ (TKF). Nachtrag v0.9 und die Planungshilfe sind anzupassen; noch nicht eingearbeitet.
- [OFFEN] Hinweis an die Anwesenheitserfassung: `ez_reactivate_helper` (spec.md EZ v0.4) lässt nur „ruhend“ und „ausgeschieden“ zu; die Administration erlaubt über den EZ-Weg auch Personen ohne Ehrenamtsstatus (24.10.2026). Ob die Anwesenheitserfassung das nutzt, entscheidet sie.
