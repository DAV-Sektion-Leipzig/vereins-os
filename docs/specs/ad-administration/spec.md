# Spec: Administration (AD)

Version: 0.2 · Status: Ready · Stand: 19.10.2026 · Product Owner: Toni Werner
Stories: docs/specs/ad-administration/02-stories.md (US-AD-01 bis US-AD-16)
Grundlage: 00-steckbrief.md v0.9, 01-erhebung.md v0.4 (R1–R19), glossar.md v0.4, rollen.md v0.6, tech-stack.md v0.3

## 1. Ziel und Scope

**Ziel:** Login, Zugänge und Rechte für das Vereins OS; Grundstruktur des Personenmodells (Person, Eigenschaftsart, Eigenschaft), auf der EA aufbaut. Erfolg: alle 4 Nutzer melden sich in PROD an; der Admin legt Personen an, lädt ein, weist Rechtevorlagen zu, ändert sie und sperrt Zugänge ohne Code-Änderung; je Rechtevorlage ein Testzugang in TEST.

**Im Scope:** Login/Logout, Einladung und Passwort setzen, Passwort vergessen (Supabase Auth, SMTP über Google-Konto der Sektion); Startseite; Personenübersicht mit Zugangsstatus; Person anlegen mit Dublettenwarnung; Zugang einladen, erneut einladen, sperren, entsperren; Rechtevorlagen anlegen, ändern, zuweisen, entziehen; Eigenschaftsarten anlegen und ändern; Eigenschaften pflegen inkl. Historie; Kennzeichen „vertraulich“; Notfall-Admin mit Protokoll und Hinweis; Protokoll (5 Jahre); Ersteinrichtung PROD; Seed für TEST.

**Nicht im Scope:** E-Mails aus Fachabläufen; automatische Einladung; sofortiges Beenden der Frontend-Sitzung beim Sperren; Befristung von Zuweisungen in der Oberfläche; Rechte je Objekt, Einzelrechte, Reichweiten außer „alle“; Startkonfiguration Vorstand; Löschfunktionen in AD; API-Key-Verwaltung (mit SC); Einstellungen; Personenakte; Excel-Import, Dublettenprüfliste, Zusammenführen, Filter aktiv/ausgeschieden, 5-Jahres-Löschung von Personen (alles EA); Login für Aktive; SSO.

## 2. Datenmodell

Konventionen nach tech-stack.md: Schema `public`, snake_case, Präfix nach Modulkürzel, RLS auf jeder Tabelle. Die Tabellen des Personenmodells tragen das Präfix `ea_` (wie in tech-stack.md benannt), werden aber mit AD angelegt. Audit-Spalten `*_by` verweisen auf `auth.users(id)` und werden per Default `auth.uid()` bzw. Trigger gesetzt, nie vom Frontend.

Erweiterungen: `citext`, `pg_trgm`, `pg_cron`.

Typen:
- `ad_level` (Enum, Reihenfolge relevant): `none` < `read` < `edit` < `manage` (UI: kein Zugriff / lesen / bearbeiten / verwalten).
- `ad_access_status` (Enum): `none` (kein Zugang), `invited` (eingeladen), `active` (aktiv), `locked` (gesperrt).
- `ea_data_type` (Enum): `text`, `date`, `boolean`, `choice` (UI: Text, Datum, Ja/Nein, Auswahlliste).
- `ea_person_kind` (Enum): `human` (Mensch), `function` (Funktionsperson).
- `ad_audit_action` (Enum): `invited`, `template_assigned`, `template_revoked`, `locked`, `unlocked`, `emergency_login`.

### ad_modules
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| code | text | ja | – | PK: AD, SC, EA, GR, FI, OA, PM, GS, AM |
| name | text | ja | – | Anzeigename, z. B. „Administration“ |
| sort_order | int | ja | – | Reihenfolge auf der Startseite |
| is_available | boolean | ja | false | Modul umgesetzt; nur dann auf der Startseite. Im MVP nur AD = true |

Stammdaten per Migration.

### ea_persons
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| first_name | text | ja | – | Vorname; getrimmt, nicht leer (R4) |
| last_name | text | ja | – | Nachname; getrimmt, nicht leer (R4) |
| kind | ea_person_kind | ja | human | Funktionsperson nur durch AD (R15) |
| created_at | timestamptz | ja | now() | |
| created_by | uuid | nein | auth.uid() | null bei Migration/Skript |

Indizes: `gin (first_name gin_trgm_ops)`, `(lower(last_name))`.

### ea_property_types
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| name | text | ja | – | eindeutig ohne Groß-/Kleinschreibung (unique index auf lower(name)) |
| purpose | text | ja | – | Zweck, nicht leer (R9) |
| data_type | ea_data_type | ja | – | nicht änderbar, sobald Eigenschaften dieser Art existieren (Trigger) |
| choice_values | text[] | nein | null | Pflicht und ≥ 1 Wert bei `choice`, sonst null (Check); Werte dürfen ergänzt, nicht entfernt werden (Trigger) |
| visible_in | text[] | ja | – | ≥ 1 Modulcode aus ad_modules; nur Anzeige |
| confidential | boolean | ja | false | vertraulich (R8); setzen/ändern nur mit AD ≥ edit (Trigger) |
| origin | text | ja | 'custom' | 'system' oder 'custom' |
| created_at / created_by | timestamptz / uuid | ja / nein | now() / auth.uid() | |
| updated_at / updated_by | timestamptz / uuid | nein | – | per Trigger |

### ea_properties
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| person_id | uuid | ja | – | FK ea_persons(id) |
| property_type_id | uuid | ja | – | FK ea_property_types(id), on delete restrict |
| value_text | text | nein | – | für `text` und `choice` (bei `choice` muss der Wert in choice_values liegen) |
| value_date | date | nein | – | für `date` |
| value_boolean | boolean | nein | – | für `boolean` |
| valid_from | date | ja | – | gültig von |
| valid_to | date | nein | – | gültig bis; Check valid_to ≥ valid_from |
| updated_at / updated_by | timestamptz / uuid | ja / nein | now() / auth.uid() | |

Trigger `ea_properties_validate` (before insert/update): genau die zum Datentyp passende Wertspalte gefüllt, übrige null; sonst Fehler `EA_VALUE_TYPE` („Der Wert passt nicht zum Datentyp der Eigenschaftsart.“).
Indizes: `(person_id)`, `(property_type_id)`.

### ea_property_history
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | bigint identity | ja | – | PK |
| property_id | uuid | ja | – | FK ea_properties(id) on delete cascade |
| value_text / value_date / value_boolean | wie oben | nein | – | Fassung vor der Änderung |
| valid_from / valid_to | date | ja / nein | – | Fassung vor der Änderung |
| changed_at | timestamptz | ja | now() | Zeitpunkt der Ablösung |
| changed_by | uuid | nein | auth.uid() | |

Trigger `ea_properties_history` (after update): schreibt die alte Fassung. Keine direkten Schreibrechte für Nutzer.

### ad_templates (Rechtevorlagen)
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| name | text | ja | – | eindeutig ohne Groß-/Kleinschreibung |
| description | text | nein | – | |
| created_at / created_by, updated_at / updated_by | | | | |

Startwerte per Migration: „Admin“, „Geschäftsstelle“, „Vorstand“ (US-AD-01 AK1).

### ad_template_rights
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| template_id | uuid | ja | – | FK ad_templates(id) on delete cascade |
| module_code | text | ja | – | FK ad_modules(code) |
| object | text | nein | null | für Rechte je Objekt nach MVP; im MVP Check `object is null` |
| scope | text | ja | 'all' | Reichweite; im MVP Check `scope = 'all'` |
| level | ad_level | ja | 'none' | Stufe |

Unique: `(template_id, module_code, coalesce(object, ''))`. Je Vorlage wird für jedes Modul eine Zeile geführt.
Startwerte: Admin = AD, SC, EA `manage`, übrige `none`; Geschäftsstelle = EA, GR, FI, OA, PM, GS, AM `manage`, AD/SC `none`; Vorstand = alle `none`.

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

### ad_accesses (Zugänge)
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | uuid | ja | gen_random_uuid() | PK |
| person_id | uuid | ja | – | FK ea_persons(id), unique (ein Zugang je Person) |
| login_email | citext | ja | – | unique (R2); Check `login_email like '%@dav-leipzig.de'` (R1) |
| status | ad_access_status | ja | 'none' | |
| auth_user_id | uuid | nein | – | FK auth.users(id), unique; gesetzt bei Einladung |
| is_emergency | boolean | ja | false | Notfall-Admin; partieller Unique-Index `where is_emergency` |
| last_invited_at | timestamptz | nein | – | zuletzt eingeladen am |
| locked_at / locked_by | timestamptz / uuid | nein | – | |
| created_at / created_by | timestamptz / uuid | ja / nein | now() / auth.uid() | |

Personen ohne Zeile in ad_accesses haben den Status „kein Zugang“.

### ad_audit_log (Protokoll)
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| id | bigint identity | ja | – | PK |
| occurred_at | timestamptz | ja | now() | |
| actor_user_id | uuid | nein | auth.uid() | ausgeführt von (bei emergency_login der Notfall-Admin selbst) |
| subject_person_id | uuid | ja | – | betroffene Person, FK ea_persons(id) |
| action | ad_audit_action | ja | – | |
| details | text | nein | – | z. B. Name der Vorlage |

Index: `(occurred_at desc)`, `(action, occurred_at desc)`. Einträge nur über Security-Definer-Funktionen und Trigger; kein Insert/Update/Delete für Nutzer (US-AD-14 AK4).

### ad_notice_acks
| Spalte | Typ | Pflicht | Default | Beschreibung |
|---|---|---|---|---|
| user_id | uuid | ja | auth.uid() | PK, FK auth.users(id) |
| emergency_acknowledged_until | timestamptz | ja | – | Zeitpunkt „Zur Kenntnis genommen“ |

### Views (security_invoker = true)
- `ad_v_person_overview`: Person, Art, Login-Adresse, Zugangsstatus (`coalesce(status,'none')`), Liste der wirksamen Vorlagen. Für US-AD-06.
- `ea_v_persons`: nur `kind = 'human'`. Alle Fachmodule lesen Personen über diese View (R15).

### Funktionen
- `ad_user_level(p_module text) returns ad_level` – security definer, stable: höchste Stufe aller wirksamen Zuweisungen des aufrufenden Nutzers für das Modul; `none`, wenn kein Zugang mit Status `active` besteht (R5, R6).
- `ad_has_level(p_module text, p_min ad_level) returns boolean` – Hilfsfunktion für RLS.
- `ad_my_modules() returns setof (code, name, level)` – für Startseite und Navigation; nur Module mit `is_available` und level ≥ `read`.
- `ad_find_similar_persons(p_first text, p_last text, p_email text) returns setof ea_persons` – Dublettenprüfung (R3): gleicher Nachname (ohne Groß-/Kleinschreibung) und `similarity(first_name, p_first) >= 0.3` oder Vorname ist Teilwort des anderen (Toni/Anton), oder `p_email` gleich einer vorhandenen Login-Adresse. Schwelle wird in TEST mit Beispielen abgenommen (T25).
- `ad_assign_template(p_person uuid, p_template uuid)`, `ad_revoke_template(p_person uuid, p_template uuid)` – prüfen AD ≥ edit, schreiben Zuweisung und Protokoll.
- `ad_acknowledge_emergency()` – setzt ad_notice_acks.
- `ad_pending_emergency_logins() returns (count int, last_at timestamptz)` – Anmeldungen des Notfall-Admins nach `emergency_acknowledged_until`.

### Trigger auf auth.users (security definer, Schema public)
- after insert: Zugang mit gleicher `login_email` → `auth_user_id` setzen (auch für Einladungen über das Supabase-Dashboard bei der Ersteinrichtung).
- after update of `last_sign_in_at`: ist der Zugang `invited` → `active`. Ist `is_emergency` → Protokolleintrag `emergency_login` (R16, auch nach „Passwort vergessen“, US-AD-15 AK4).

### Zeitgesteuerte Jobs (pg_cron)
- täglich 03:15 (Europe/Berlin): `delete from ad_audit_log where occurred_at < now() - interval '5 years'` (R13).

## 3. Rechte / RLS

Grundsatz: Rechte werden bei jeder Abfrage über `ad_has_level` geprüft. Da der Zugangsstatus Teil der Prüfung ist, enden Datenzugriffe nach Sperren oder Entziehen sofort; nur die Anmeldung im Frontend bleibt bis Ablauf des Zugriffstokens (bis zu 1 Stunde) bestehen. Das erfüllt R10 („spätestens“).

Stufen in AD: lesen = alles in AD ansehen inkl. Protokoll und vertraulicher Eigenschaften; bearbeiten = anlegen, ändern, einladen, sperren, entsperren, zuweisen; verwalten = wie bearbeiten (keine zusätzliche Funktion im MVP, da in AD nichts gelöscht wird).

| Tabelle / Objekt | Lesen | Anlegen | Ändern | Löschen |
|---|---|---|---|---|
| ad_modules | jeder angemeldete Nutzer | – | – | – |
| ad_templates, ad_template_rights | AD ≥ read | AD ≥ edit | AD ≥ edit | – |
| ad_template_assignments | AD ≥ read | nur über ad_assign_template | nur über ad_revoke_template | – |
| ad_accesses | AD ≥ read | AD ≥ edit | AD ≥ edit; Statuswechsel nur über Edge Functions/Trigger | – |
| ad_audit_log | AD ≥ read | nur System | – | nur pg_cron |
| ad_notice_acks | eigene Zeile | eigene Zeile | eigene Zeile | – |
| ea_persons | AD ≥ read: alle; EA ≥ read: nur `kind = 'human'` | AD ≥ edit oder EA ≥ edit; `kind = 'function'` nur AD | wie Anlegen | – (EA später) |
| ea_property_types | AD ≥ read: alle; EA ≥ read: nur `confidential = false` | AD ≥ edit oder EA = manage; `confidential = true` nur AD ≥ edit | wie Anlegen; Ändern von `confidential` nur AD ≥ edit | – |
| ea_properties | AD ≥ read: alle; EA ≥ read: nur nicht vertrauliche Arten an Personen `kind = 'human'` | AD ≥ edit; EA ≥ edit nur nicht vertrauliche Arten | wie Anlegen | – |
| ea_property_history | wie ea_properties | nur Trigger | – | – |

Rechtevorlagen (Startwerte, R6):

| Rechtevorlage | AD | SC | EA | GR | FI | OA | PM | GS | AM |
|---|---|---|---|---|---|---|---|---|---|
| Admin | verwalten | verwalten | verwalten | – | – | – | – | – | – |
| Geschäftsstelle | – | – | verwalten | verwalten | verwalten | verwalten | verwalten | verwalten | verwalten |
| Vorstand | – | – | – | – | – | – | – | – | – |

Edge Functions prüfen das Recht des Aufrufers selbst (JWT auswerten, `ad_has_level('AD','edit')` im Kontext des Aufrufers), bevor sie mit dem Service-Schlüssel arbeiten. Der Service-Schlüssel liegt nur in den Secrets der Edge Functions.

## 4. Zustände und Übergänge (Zugang)

| Von | Nach | Wer | Bedingung |
|---|---|---|---|
| kein Zugang | eingeladen | Admin (Edge Function ad-invite) | Login-Adresse gültig (R1, R2), mind. eine wirksame Vorlage (R17), Mail erfolgreich versendet |
| eingeladen | eingeladen | Admin (ad-invite) | erneut einladen; last_invited_at aktualisiert |
| eingeladen | aktiv | Nutzer (Trigger auf auth.users) | erste Anmeldung nach Setzen des Passworts |
| eingeladen | gesperrt | Admin (ad-access) | Einladung zurückziehen |
| aktiv | gesperrt | Admin (ad-access) | – |
| gesperrt | aktiv | Admin (ad-access) | `auth.users.last_sign_in_at is not null` |
| gesperrt | eingeladen | Admin (ad-access) | `last_sign_in_at is null`; danach erneut einladen möglich |

Sperren setzt in Supabase Auth einen Bann (`ban_duration`), Entsperren hebt ihn auf. Jeder Übergang außer „eingeladen → aktiv“ erzeugt einen Protokolleintrag.

## 5. Geschäftsregeln

- R1: Wenn die Login-Adresse nicht auf @dav-leipzig.de endet, dann Fehler, sonst Fehlermeldung „Zugang nur mit Adresse @dav-leipzig.de möglich.“
- R2: Wenn die Login-Adresse bereits einem Zugang gehört, dann Fehlermeldung „Diese Login-Adresse ist bereits vergeben.“
- R3: Wenn beim manuellen Anlegen `ad_find_similar_persons` Treffer liefert, dann Warndialog mit Trefferliste und „Trotzdem anlegen“ / „Vorhandene Person öffnen“ / „Abbrechen“.
- R4: Wenn Vorname oder Nachname leer ist, dann Fehlermeldung „Bitte Vorname und Nachname angeben.“
- R5: Wenn der Zugang nicht `active` ist, dann wirken keine Rechte (ad_user_level = none).
- R6: Rechte = höchste Stufe je Modul über alle wirksamen Vorlagen; keine Verbote.
- R7: Eigenschaften erzeugen keine Rechte; keine Ableitung im Code.
- R8: Wenn eine Eigenschaftsart vertraulich ist, dann lesen ihre Eigenschaften nur Nutzer mit AD ≥ read (RLS).
- R9: Wenn der Zweck leer ist, dann „Bitte einen Zweck angeben.“; wenn Auswahlliste ohne Werte, dann „Bitte mindestens einen Auswahlwert angeben.“
- R10: Wenn ein Zugang gesperrt ist, dann ist keine Anmeldung möglich; Datenzugriff endet sofort (RLS), Frontend-Sitzung spätestens nach 1 Stunde.
- R11: Einladungen nur über den Knopf „Einladen“ / „Erneut einladen“; kein Trigger, Import oder Job lädt ein.
- R12: Keine Löschfunktion in AD; Ausscheiden = Sperren + gültig bis an Eigenschaften.
- R13: Einladen, Zuweisen, Entziehen, Sperren, Entsperren, Anmeldung Notfall-Admin → Protokolleintrag; Löschung nach 5 Jahren.
- R14: Genau ein Zugang mit `is_emergency = true` (geschaeftsstelle@dav-leipzig.de, Vorlage Admin).
- R15: Wenn `kind = 'function'`, dann nicht in `ea_v_persons`, nicht für EA-Rechte sichtbar, nicht in der 5-Jahres-Löschung (EA).
- R16: Jede Anmeldung des Notfall-Admins → Protokoll + Hinweis in AD bis „Zur Kenntnis genommen“.
- R17: Wenn keine wirksame Vorlage zugewiesen ist, dann „Bitte zuerst mindestens eine Rechtevorlage zuweisen.“ und keine Einladung.
- R18: Login-Fehler immer „Anmeldung fehlgeschlagen. Bitte E-Mail-Adresse und Passwort prüfen.“; „Passwort vergessen“ immer „Wenn ein Zugang zu dieser Adresse besteht, haben wir dir eine E-Mail mit einem Link geschickt.“
- R19: Wenn das Passwort kürzer als 8 Zeichen ist, dann „Das Passwort muss mindestens 8 Zeichen lang sein.“

Weitere Meldungen:
- Datentyp ändern bei vorhandenen Eigenschaften: „Der Datentyp kann nicht geändert werden, solange Eigenschaften dieser Art existieren.“
- Auswahlwert entfernen: „Auswahlwerte können ergänzt, aber nicht entfernt werden.“
- Name doppelt: „Eine Rechtevorlage mit diesem Namen gibt es bereits.“ / „Eine Eigenschaftsart mit diesem Namen gibt es bereits.“
- gültig bis vor gültig von: „‚Gültig bis‘ darf nicht vor ‚gültig von‘ liegen.“
- Mailversand fehlgeschlagen: „Die Einladung konnte nicht verschickt werden. Bitte später erneut versuchen.“
- Link ungültig (Einladung): „Der Link ist abgelaufen oder ungültig. Bitte wende dich an den Admin.“; (Passwort vergessen): „Der Link ist abgelaufen oder ungültig. Bitte fordere einen neuen an.“
- Keine Rechte: „Für diesen Bereich hast du keine Rechte.“
- Unerwarteter Fehler: „Etwas ist schiefgelaufen. Bitte versuche es erneut.“

Datenbankfehler tragen einen Code (z. B. `AD_EMAIL_DOMAIN`, `AD_EMAIL_TAKEN`, `AD_NO_TEMPLATE`, `EA_VALUE_TYPE`); das Frontend bildet Codes auf die Meldungen ab.

## 6. Screens und Interaktionen

Allgemein: deutsch, Ansprache „du“, Datum TT.MM.JJJJ, Zeit HH:MM (Europe/Berlin), shadcn/ui, nutzbar ab 375 px ohne horizontales Scrollen (Tabellen werden mobil zu Karten). Kopfzeile: Vereins OS (Link Startseite), Modulname, Name des Nutzers, „Abmelden“.

| Route | Zeigt | Aktionen | Leerer Zustand / Fehler | Story |
|---|---|---|---|---|
| /login | Login-Adresse, Passwort | Anmelden; Link „Passwort vergessen“ | R18-Meldung | US-AD-02 |
| /passwort-vergessen | Login-Adresse | Link anfordern | immer R18-Bestätigung | US-AD-04 |
| /passwort-setzen | Passwort, Wiederholung | Speichern (aus Einladungs- oder Reset-Link) | R19; Link ungültig | US-AD-03, US-AD-04 |
| / | Willkommensgrafik (Platzhalterbild im Repo), Kacheln aus ad_my_modules | Modul öffnen | „Für dich sind noch keine Module freigeschaltet.“ | US-AD-05 |
| /kein-zugriff | Meldung „Für diesen Bereich hast du keine Rechte.“ | Zur Startseite | – | US-AD-05 |
| /ad | Personenübersicht (ad_v_person_overview): Name, Art-Kennzeichen „Funktionsperson“, Login-Adresse, Status-Badge, Vorlagen; Suche nach Namensteil; Filter Status; oben ggf. Hinweis Notfall-Admin („Der Notfall-Admin hat sich n-mal angemeldet, zuletzt am …“) | Person anlegen; Person öffnen; „Zur Kenntnis genommen“ | „Keine Personen gefunden.“ | US-AD-06, US-AD-15 |
| /ad/personen/neu | Vorname, Nachname, optional Login-Adresse | Speichern → Dublettenprüfung → ggf. Warndialog | R1, R2, R4 | US-AD-07 |
| /ad/personen/:id | Abschnitte: **Stammdaten** (Name, Art; bearbeitbar); **Zugang** (Login-Adresse, Status, zuletzt eingeladen, gesperrt am/von); **Rechtevorlagen** (wirksame Vorlagen); **Eigenschaften** (aktuelle oben, beendete als „beendet“, je Eigenschaft Historie aufklappbar; nur Arten mit „sichtbar in“ AD) | Login-Adresse speichern; Einladen / Erneut einladen / Sperren (mit Bestätigung und Hinweis „Bereits angemeldete Nutzer verlieren den Zugriff spätestens nach einer Stunde.“) / Entsperren; Vorlage hinzufügen (nur nicht zugewiesene) / entziehen; Eigenschaft hinzufügen, ändern, beenden | „Noch keine Eigenschaften.“; R1, R2, R17, Mailfehler | US-AD-08, 09, 11, 13 |
| /ad/rechtevorlagen | Liste: Name, Beschreibung, Anzahl Personen | Neu; öffnen | – | US-AD-10 |
| /ad/rechtevorlagen/:id | Name, Beschreibung, Matrix 9 Module × Stufe (Auswahl je Zeile) | Speichern | Name doppelt | US-AD-10 |
| /ad/eigenschaftsarten | Liste: Name, Datentyp, sichtbar in, vertraulich | Neu; öffnen | „Noch keine Eigenschaftsarten.“ | US-AD-12 |
| /ad/eigenschaftsarten/:id | Name, Zweck, Datentyp, Auswahlwerte (bei Auswahlliste), sichtbar in (Mehrfachauswahl), vertraulich; Hinweis Art. 9 DSGVO beim Anlegen | Speichern | R9, Name doppelt, Datentyp gesperrt | US-AD-12 |
| /ad/protokoll | Einträge neueste zuerst, 50 je Seite: Zeitpunkt, ausgeführt von, betroffene Person, Aktion, Details | Weiter blättern | „Noch keine Einträge.“ | US-AD-14 |

Routenschutz: ohne Sitzung → /login (US-AD-02 AK5); ohne AD ≥ read → /kein-zugriff, keine Datenabfrage (US-AD-05 AK3). Navigation wird bei jedem Seitenaufruf aus ad_my_modules geladen.

## 7. Schnittstellen

| Schnittstelle | Art | Beschreibung |
|---|---|---|
| Supabase Auth | Konfiguration (config.toml + Dashboard) | E-Mail/Passwort; Selbstregistrierung aus (`enable_signup = false`); Mindestlänge Passwort 8; Redirect-URLs: PROD-Adresse (`*.workers.dev`), Vorschau-Adressen, lokal; deutsche Mailvorlagen „Einladung“ und „Passwort zurücksetzen“ nur mit kurzem Hinweistext und Link |
| SMTP | Supabase Auth → Google-Konto der Sektion | App-Passwort nur in den Supabase-Einstellungen; Absendername „Vereins OS“ |
| Edge Function `ad-invite` | POST `{ person_id }`, Bearer-JWT des Aufrufers | prüft AD ≥ edit, R1, R2, R17, Status; lädt per Auth-Admin-API ein (neu oder erneut); bei Erfolg: Status `invited`, last_invited_at, auth_user_id, Protokoll `invited`; bei Mailfehler: keine Änderung, Fehlercode `AD_MAIL_FAILED`; ohne Recht: 403 |
| Edge Function `ad-access` | POST `{ person_id, action: "lock" \| "unlock" }` | prüft AD ≥ edit; setzt bzw. entfernt Bann in Auth; Status nach Abschnitt 4; Protokoll `locked` / `unlocked`; ohne Recht: 403 |
| EA | Datenbank | EA nutzt ea_persons (über ea_v_persons), ea_property_types, ea_properties und erweitert sie |
| alle Module | Datenbank | RLS über ad_has_level; Navigation über ad_my_modules |

## 8. Nicht-funktionale Anforderungen

- RLS auf jeder Tabelle; keine Tabelle ohne Policy; Rechteprüfung nie nur im Frontend.
- Schemaänderungen nur per Migration; Seed nur in TEST.
- Keine Secrets im Repo (Service-Schlüssel, SMTP-App-Passwort, Testpasswörter).
- Login-Mails enthalten keine Personendaten außer Empfängeradresse und Link.
- Auth-Mails: max. 30 pro Stunde (Supabase-Grenze mit eigenem SMTP) – ausreichend.
- Mobil ab 375 px; bedienbar ohne Schulung.
- Antwortzeit Personenübersicht bei 300 Personen < 1 s.
- Kosten: 0 €.
- Vor Go-live: Zustellung von Einladung und „Passwort vergessen“ an je eine reale Adresse @dav-leipzig.de testen (Spam-Filter).

## 9. Testdaten (supabase/seed.sql, nur TEST)

Seed bricht ab, wenn die Projektkennung nicht die von vereins-os-test ist („Seed nur für TEST erlaubt.“). Passwörter der Testzugänge aus Umgebungsvariable `SEED_TEST_PASSWORD` (lokal `.env`, CI: GitHub-Secret). Alle Namen und Adressen fiktiv; die Adressen existieren nicht.

| # | Person | Art | Zugang | Status | Vorlagen | Eigenschaften |
|---|---|---|---|---|---|---|
| 1 | Test Admin | Mensch | test.admin@dav-leipzig.de | aktiv | Admin | – |
| 2 | Anna Fiktiv | Mensch | test.geschaeftsstelle@dav-leipzig.de | aktiv | Geschäftsstelle | Hauptamt „Mitarbeiterin Geschäftsstelle“ seit 01.03.2024 (vertraulich) |
| 3 | Bernd Beispiel | Mensch | test.vorstand@dav-leipzig.de | aktiv | Vorstand | – |
| 4 | Toni Muster | Mensch | – | kein Zugang | – | T-Shirt-Größe „M“ seit 01.01.2025 |
| 5 | Anton Muster | Mensch | – | kein Zugang | – | – (Dublettenpaar zu 4) |
| 6 | Eva Eingeladen | Mensch | test.eingeladen@dav-leipzig.de | eingeladen | Geschäftsstelle | – |
| 7 | Dieter Gesperrt | Mensch | test.gesperrt@dav-leipzig.de | gesperrt | Geschäftsstelle | Hauptamt 01.01.2020–31.12.2025 (beendet, vertraulich) |
| 8 | Geschäftsstelle Notfall-Admin | Funktionsperson | test.notfall@dav-leipzig.de (is_emergency) | aktiv | Admin | – |

Eigenschaftsarten im Seed: „Hauptamt“ (Text, sichtbar in AD, vertraulich, Zweck „Zuordnung der hauptamtlich Beschäftigten“); „T-Shirt-Größe“ (Auswahlliste S, M, L, XL, sichtbar in EA, Zweck „Bestellung von Vereinskleidung“); „Erste-Hilfe-Kurs am“ (Datum, sichtbar in EA, Zweck „Nachweis für Tätigkeiten mit Gruppen“).

Protokoll im Seed: je ein Eintrag `invited`, `template_assigned`, `locked`, `emergency_login`.

## 10. Umsetzungs-Tasks

- [ ] T1: Migration Grundlagen: Erweiterungen, Enums, ad_modules mit Stammdaten (US-AD-01, US-AD-05)
- [ ] T2: Migration Personenmodell: ea_persons, ea_property_types, ea_properties, ea_property_history, Trigger (Validierung, Historie, Datentyp-Sperre, Auswahlwerte, vertraulich nur AD), View ea_v_persons (US-AD-07, US-AD-12, US-AD-13, US-AD-15)
- [ ] T3: Migration Rechte: ad_templates, ad_template_rights, ad_template_assignments, ad_accesses, Startvorlagen, Funktionen ad_user_level, ad_has_level, ad_my_modules, ad_assign_template, ad_revoke_template (US-AD-01, US-AD-10, US-AD-11)
- [ ] T4: Migration Protokoll: ad_audit_log, ad_notice_acks, Funktionen ad_pending_emergency_logins, ad_acknowledge_emergency, pg_cron-Job Löschung nach 5 Jahren (US-AD-14, US-AD-15)
- [ ] T5: Trigger auf auth.users: Verknüpfung per E-Mail, Status aktiv, Protokoll Notfall-Admin (US-AD-03, US-AD-15)
- [ ] T6: RLS-Policies aller Tabellen nach Abschnitt 3; View ad_v_person_overview (US-AD-06, US-AD-13 AK4 u. a.)
- [ ] T7: Datenbanktests (pgTAP, `supabase test db`): je Vorlage Lese-/Schreibrechte, vertrauliche Eigenschaften, Funktionsperson in ea_v_persons, gesperrter Zugang ohne Rechte, Protokoll unveränderbar (alle Rechte-Fälle)
- [ ] T8: Funktion ad_find_similar_persons (US-AD-07)
- [ ] T9: Edge Function ad-invite inkl. Fehlercodes (US-AD-08)
- [ ] T10: Edge Function ad-access (US-AD-09)
- [ ] T11: Auth-Konfiguration: Selbstregistrierung aus, Passwortlänge 8, Redirect-URLs, deutsche Mailvorlagen; SMTP-Einstellungen dokumentieren (US-AD-02, 03, 04)
- [ ] T12: Frontend-Grundgerüst: Routing, Routenschutz, Kopfzeile, Fehlercode-Abbildung, /kein-zugriff (US-AD-02, US-AD-05)
- [ ] T13: Screens Login, Passwort vergessen, Passwort setzen, Abmelden (US-AD-02, 03, 04)
- [ ] T14: Startseite mit Willkommensgrafik und Modulkacheln (US-AD-05)
- [ ] T15: Personenübersicht mit Suche, Filter, Notfall-Hinweis (US-AD-06, US-AD-15)
- [ ] T16: Person anlegen mit Dublettendialog (US-AD-07)
- [ ] T17: Personendetail: Stammdaten und Zugang (einladen, erneut einladen, sperren, entsperren) (US-AD-08, US-AD-09)
- [ ] T18: Personendetail: Rechtevorlagen zuweisen und entziehen (US-AD-11)
- [ ] T19: Personendetail: Eigenschaften mit Historie (US-AD-13)
- [ ] T20: Rechtevorlagen Liste und Bearbeiten mit Modul-Matrix (US-AD-10)
- [ ] T21: Eigenschaftsarten Liste und Bearbeiten (US-AD-12)
- [ ] T22: Protokoll-Ansicht (US-AD-14)
- [ ] T23: supabase/seed.sql nach Abschnitt 9 inkl. Abbruch bei PROD und Passwort aus Umgebungsvariable (US-AD-16)
- [ ] T24: Einrichtungsskript PROD (`supabase/setup/prod-bootstrap.sql`), idempotent, Parameter: Vor-/Nachname und Login-Adresse des Admins; legt Toni Werner (Admin, Vorstand) und Funktionsperson mit Notfall-Zugang (Admin) an; Anleitung für die erste Einladung über das Supabase-Dashboard (US-AD-01)
- [ ] T25: Abnahme in TEST: Dublettenschwelle mit Beispielen (Toni/Anton Muster, Tippfehler), alle Stories mit den drei Testzugängen; vor Go-live Zustellungstest der Login-Mails (US-AD-07, US-AD-16)

## 11. Annahmen und offene Punkte

Bestätigt vom Product Owner am 19.10.2026: alle Annahmen aus Steckbrief, Erhebung und Stories sowie die technischen Festlegungen dieser Spec:
- Tabellen des Personenmodells mit Präfix `ea_`, obwohl sie mit AD entstehen (Benennung nach tech-stack.md).
- AD „bearbeiten“ und „verwalten“ sind im MVP gleichwertig, da AD keine Löschfunktionen hat.
- Datenzugriffe enden beim Sperren oder Entziehen sofort (RLS prüft Status), die Frontend-Sitzung bis zu 1 Stunde später.
- Ähnlichkeitsschwelle 0,3 (pg_trgm) als Startwert; endgültig nach Abnahme T25.
- Testadressen @dav-leipzig.de im Seed existieren nicht als Postfächer.
- Personenübersicht ohne Paginierung bis ca. 300 Personen.

Offen (kein Blocker für AD):
- [OFFEN] Vertretung des Admin-Zugangs (Toni Werner).
- [OFFEN] Löschung des Zugangs, wenn eine Person nach der 5-Jahres-Regel gelöscht wird (Klärung im Steckbrief EA).
