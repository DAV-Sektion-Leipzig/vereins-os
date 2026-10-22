# Contract: Fehlercodes → Meldungen

Stand: 22.10.2026 · Grundlage: [spec.md Administration](../spec.md) v0.9 (Abschnitt 5 und Abschnitt 2; umgesetzt wird zunächst der Kern bis v0.7.1, siehe [plan.md](../plan.md)), [02-stories.md Gruppen](../../gr-gruppen/02-stories.md) v0.7 (US-GR-19), [spec.md Anwesenheitserfassung](../../ez-einsaetze/spec.md) v0.1 (Abschnitt 5)

Diese Liste ist vollständig und normativ: Die Specs verweisen für die Zuordnung Code → Meldung auf sie. Die Meldungstexte stehen wörtlich in der jeweiligen Spec. Das Frontend bildet die Codes in `src/lib/errors.ts` auf die Meldungen ab.

- **Regel:** R-Nummer aus der Spec des jeweiligen Abschnitts (AD und EA: spec.md Administration; EZ: spec.md Anwesenheitserfassung).
- **Status:** „umgesetzt“ = Code bzw. Constraint existiert in einer Migration oder Edge Function auf `main`. „geplant (Tn)“ = Task aus Abschnitt 10 der jeweiligen spec.md (nicht die Nummerierung von tasks.md).
- **`<Feld>`** wird durch den Feldnamen ersetzt, den die Datenbank im Detail des Fehlers mitliefert.
- **[OFFEN]** = Meldungstext oder Bedeutung ist in der Spec nicht festgelegt; siehe „Offene Punkte“ am Ende.

## Administration (AD)

| Code / Constraint | Meldung | Regel | Status |
|---|---|---|---|
| `AD_EMAIL_DOMAIN` (Trigger `ad_accesses_guard`, Edge Functions) | Zugang nur mit Adresse @dav-leipzig.de möglich. | R1 | umgesetzt |
| `AD_EMAIL_MISSING` | Zugang nur mit Adresse @dav-leipzig.de möglich. | R1 | geplant (T9) |
| `AD_EMAIL_TAKEN` / `ad_accesses_login_email_key` | Diese Login-Adresse ist bereits vergeben. | R2 | umgesetzt |
| `AD_EMAIL_LOCKED` | Die Login-Adresse kann nur vor der Aktivierung des Zugangs geändert werden. | R20 | umgesetzt |
| `AD_EMAIL_CHANGE_VIA_FUNCTION` (direktes Update bei Status `invited`, nur bei Umgehung der Oberfläche) | Etwas ist schiefgelaufen. Bitte versuche es erneut. | R20 | umgesetzt |
| `AD_NAME_REQUIRED` / `ea_persons_first_name_not_blank`, `ea_persons_last_name_not_blank` | Bitte Vorname und Nachname angeben. | R4 | umgesetzt |
| `AD_NO_TEMPLATE` | Bitte zuerst mindestens eine Rechtevorlage zuweisen. | R17 | geplant (T9) |
| `AD_MAIL_FAILED` | Die Einladung konnte nicht verschickt werden. Bitte später erneut versuchen. | – | geplant (T9) |
| `AD_TEMPLATE_NAME_TAKEN` / `ad_templates_name_key` | Eine Rechtevorlage mit diesem Namen gibt es bereits. | – | umgesetzt |
| `AD_SCOPE_NOT_ALLOWED` / `ad_template_rights_scope_allowed` | Die Reichweite ‚Referat‘ ist nur im Ehrenamtsmanagement möglich. | R30 | umgesetzt |
| `AD_REFERAT_REQUIRED` | Bitte mindestens ein Referat auswählen. | R31 | umgesetzt |
| `AD_CONFIDENTIAL_ONLY_AD` | Nur mit Rechten auf die Administration möglich. | R29 | umgesetzt |
| `AD_QUALIFICATION_NAME_REQUIRED` | Bitte eine Bezeichnung angeben. | R21 | umgesetzt |
| `AD_QUALIFICATION_NAME_TAKEN` | Eine Qualifikationsart mit dieser Bezeichnung gibt es bereits. | R21 | umgesetzt |
| `AD_QUALIFICATION_CODE_TAKEN` | Dieses Kürzel ist bereits vergeben. | R22 | umgesetzt |
| `AD_QUALIFICATION_CODE_FORMAT` | Das Kürzel darf nur Großbuchstaben und Ziffern enthalten (max. 10 Zeichen). | R22 | umgesetzt |
| `AD_QUALIFICATION_LEVEL_REQUIRED` | Bitte eine Lizenzstufe wählen. | R23 | umgesetzt |
| `AD_QUALIFICATION_VALIDITY` | Bitte eine Gültigkeitsdauer in Jahren angeben (1–10). | R24 | umgesetzt |
| `AD_QUALIFICATION_HISTORIC` | Diese Qualifikationsart ist historisch und kann nicht neu vergeben werden. | R27 | umgesetzt |
| `AD_QUALIFICATION_KIND` | Dieser Typ von Qualifikation ist hier nicht erlaubt. | R28 | umgesetzt |
| `AD_LOCATION_NAME_REQUIRED` | Bitte eine Bezeichnung angeben. | R43 | geplant (T51) |
| `AD_LOCATION_NAME_TAKEN` | Einen Ort mit dieser Bezeichnung gibt es bereits. | R43 | geplant (T51) |
| `AD_SEARCH_TOO_SHORT` | Bitte mindestens 2 Zeichen eingeben. | R44 | geplant (T52) |
| `AD_TOO_MANY_IDS` | [OFFEN] Meldung fehlt in spec.md | – | geplant (T52) |
| `AD_FORBIDDEN`, SQLSTATE `42501` | Für diesen Bereich hast du keine Rechte. | R8, R43 | umgesetzt |
| `AD_UNAUTHENTICATED` | weiter zu /login (keine Meldung) | – | geplant (T9, T10) |
| `AD_PERSON_NOT_FOUND`, `AD_INVALID_STATUS`, `AD_BAD_REQUEST`, `AD_UNEXPECTED`, unbekannt | Etwas ist schiefgelaufen. Bitte versuche es erneut. | – | geplant (T9, T10) |

`AD_EMAIL_DOMAIN` meldet in TEST denselben Text, wenn die Domain nicht in `ad_test_login_domains` freigegeben ist (R1).

`AD_EMAIL_MISSING` übernimmt die R1-Meldung, weil ohne Adresse keine Einladung möglich ist. Die Oberfläche bietet „Einladen“ ohne Login-Adresse gar nicht erst an.

`AD_FORBIDDEN` meldet auch `ea_search_active_persons` ohne EZ ≥ bearbeiten (spec.md Abschnitt 2).

`AD_SCOPE_NOT_ALLOWED`: Im Kern (bis v0.7.1) gilt der Text aus 02-stories.md US-AD-20 AK3. Mit dem Nachtrag v0.8 (T50, T54) wird er ersetzt durch „Die Reichweite ‚Referat‘ ist nur im Ehrenamtsmanagement und in der Anwesenheitserfassung möglich.“ (spec.md R30).

## Ehrenamtsmanagement (EA)

Soweit in spec.md Administration definiert (Personenmodell, Eigenschaftsarten, Eigenschaften, Ehrenamtsstatus).

| Code / Constraint | Meldung | Regel | Status |
|---|---|---|---|
| `EA_PROPERTY_TYPE_NAME_TAKEN` / `ea_property_types_name_key` | Eine Eigenschaftsart mit diesem Namen gibt es bereits. | – | umgesetzt |
| `EA_PURPOSE_REQUIRED` | Bitte einen Zweck angeben. | R9 | umgesetzt |
| `EA_CHOICE_VALUES_REQUIRED` | Bitte mindestens einen Auswahlwert angeben. | R9 | umgesetzt |
| `EA_NO_FIELDS` | Bitte mindestens ein Feld anlegen. | R9 | umgesetzt |
| `EA_DATA_TYPE_LOCKED` | Der Datentyp kann nicht geändert werden, solange Eigenschaften dieser Art existieren. | R36 | umgesetzt |
| `EA_FIELD_LOCKED` | Der Datentyp kann nicht geändert werden, solange Eigenschaften dieser Art existieren. [OFFEN] Abgrenzung zu `EA_DATA_TYPE_LOCKED` | R36 | geplant (T35) |
| `EA_FIELD_NEW_REQUIRED` | Neue Felder können nur optional angelegt werden, solange es Eigenschaften dieser Art gibt. | R36 | umgesetzt |
| `EA_CHOICE_VALUE_REMOVED` | Auswahlwerte können ergänzt, aber nicht entfernt werden. | R36 | umgesetzt |
| `EA_RELATION_LOCKED` | Der Bezug kann nicht geändert werden, solange Eigenschaften dieser Art existieren. | – | umgesetzt |
| `EA_LABEL_TOO_LONG` / `ea_property_types_valid_from_label_length`, `…_valid_to_label_length` | Die Bezeichnung darf höchstens 40 Zeichen lang sein. | R49 | umgesetzt |
| Constraint `ea_property_fields_label_key` (kein Code, [OFFEN]) | Ein Feld mit dieser Bezeichnung gibt es bereits. | – | umgesetzt |
| `EA_FIELD_REQUIRED` | Bitte ‚<Feld>‘ ausfüllen. | R35 | umgesetzt |
| `EA_VALUE_TYPE` | Der Wert für ‚<Feld>‘ passt nicht zum Datentyp. | R35 | umgesetzt |
| `EA_FIELD_UNKNOWN` | Unbekanntes Feld. | R35 | umgesetzt |
| `EA_FIELD_CHOICE` | Bitte einen Wert aus der Liste wählen. | R35 | umgesetzt |
| `EA_SINGLE_VALUE` | Für diese Eigenschaftsart ist nur ein gültiger Eintrag je Zeitraum erlaubt. | R37 | umgesetzt |
| `EA_RELATION_REQUIRED` | Bitte ein Referat (bzw. Gremium, Gruppe) wählen. | R38 | umgesetzt |
| `EA_VALID_RANGE` / `ea_properties_valid_range` | ‚Gültig bis‘ darf nicht vor ‚gültig von‘ liegen. | – | umgesetzt |
| `EA_GROUP_RELATION_ONLY_GR` | Diese Angabe wird im Modul Gruppen gepflegt. | R39 | umgesetzt |
| `EA_RELATION_FOREIGN_REFERAT` | Du kannst nur Zuordnungen zu deinen Referaten pflegen. | R41 | umgesetzt |
| `EA_CONFIDENTIAL_FORBIDDEN` | Für diesen Bereich hast du keine Rechte. [OFFEN] gilt nach R29 noch? | R8 | [OFFEN] |
| `EA_STATUS_FORBIDDEN` | Du darfst den Status dieser Person nicht ändern. | R33 | umgesetzt |
| `EA_CREATE_FOREIGN_REFERAT` | Du kannst nur Personen für deine Referate anlegen. | R45 | geplant (T53) |
| `EA_CREATE_FORBIDDEN` | Für diesen Bereich hast du keine Rechte. | R41, R45 | geplant (Ehrenamtsmanagement, Branch `ea-datenbank`; Entscheidung Product Owner 23.10.2026, plan.md EA O3) |
| `EA_CREATE_REFERAT_REQUIRED` | Bitte eine Funktion oder ein Amt in deinem Referat angeben. | R3 EA | geplant (Ehrenamtsmanagement, Branch `ea-datenbank`; Entscheidung Product Owner 23.10.2026, plan.md EA O3) |

`EA_VALUE_TYPE`, `EA_FIELD_REQUIRED`, `EA_FIELD_CHOICE`, `AD_QUALIFICATION_HISTORIC` und `AD_QUALIFICATION_KIND` liefern die Feldbezeichnung im `detail` des Fehlers; `src/lib/errors.ts` setzt sie für „<Feld>“ ein. Der frühere Text von `EA_VALUE_TYPE` „Der Wert passt nicht zum Datentyp der Eigenschaftsart.“ entfällt.

`EA_VALID_RANGE` (Constraint `ea_properties_valid_range`): Die Oberfläche nennt statt „Gültig bis“/„gültig von“ die Bezeichnungen der Eigenschaftsart, falls gesetzt (R49), z. B. „‚Beendet am‘ darf nicht vor ‚erworben bzw. verlängert am‘ liegen.“ [ANNAHME spec v0.7.2].

## Gruppen (GR)

| Code / Constraint | Meldung | Regel | Status |
|---|---|---|---|
| `GR_ROSTER_FORBIDDEN` (`gr_group_roster`) | Für diesen Bereich hast du keine Rechte. | US-GR-19 AK5 | geplant (US-GR-19; Gruppen hat noch keine spec.md) |

## Anwesenheitserfassung (EZ)

| Code / Constraint | Meldung | Regel | Status |
|---|---|---|---|
| `EZ_FIELD_REQUIRED` | Bitte ‚<Feld>‘ angeben. | R1 | geplant (T4) |
| `EZ_END_DATE` | Das Enddatum muss nach dem Startdatum liegen. Für eintägige Einsätze bitte ‚eintägig‘ wählen. | R2 | geplant (T4) |
| `EZ_END_TIME` | Das Ende muss nach dem Beginn liegen. | – | geplant (T4) |
| `EZ_TITLE_LENGTH` | Bitte einen Titel mit höchstens 60 Zeichen eingeben. | – | geplant (T4) |
| `EZ_MIN_ATTENDANCE` | Training: „Bitte mindestens eine Trainer:in oder Helfer:in und eine Teilnehmer:in auswählen.“ Andere: „Bitte mindestens eine Trainer:in oder Helfer:in auswählen.“ | R5 | geplant (T4) |
| `EZ_TRIAL_NAME` | Leer: „Bitte einen Vornamen eingeben.“ Zu lang: „Bitte höchstens 30 Zeichen eingeben.“ | R6 | geplant (T4) |
| `EZ_REMARK_LENGTH` | Die Bemerkung darf höchstens 500 Zeichen haben. | R7 | geplant (T4) |
| `EZ_DUPLICATE_EVENT` (Rückfrage, kein Abbruch) | Für diese Gruppe ist an diesem Tag bereits ein Einsatz dieser Art erfasst. Trotzdem speichern? | R8 | geplant (T4) |
| `EZ_ORGANIZER_NOT_ACTIVE` | Bitte eine aktive Person auswählen. | R11 | geplant (T4) |
| `EZ_LOCATION_INACTIVE` | Dieser Ort ist nicht mehr aktiv. Bitte einen anderen Ort wählen. | R12 | geplant (T4) |
| `EZ_FORBIDDEN` | Für diesen Bereich hast du keine Rechte. | R13, R14 | geplant (T4) |
| `EZ_PARTICIPANT_NOT_IN_GROUP` | Diese Person ist an diesem Tag nicht Teilnehmer:in der Gruppe. | R16 | geplant (T4) |
| `EZ_DUPLICATE_PERSON` | Diese Person ist bereits eingetragen. | R17 | geplant (T4) |
| `EZ_FIELD_LOCKED` (Trigger `ez_events_before_update`, `ez_save_event`) | Einsatzart, Gruppe und Referat können nicht geändert werden. Bitte den Einsatz löschen lassen und neu erfassen. | R19 | geplant (T3, T4) |
| `EZ_PERSON_NOT_ACTIVE` | Bitte eine aktive Person auswählen. | R20 | geplant (T4) |
| `EZ_STATUS_NOT_ALLOWED` | [OFFEN] Meldung fehlt in spec.md | R21 | geplant (T4) |
| `EZ_ROLE_NOT_ALLOWED` | Beim Arbeitseinsatz gibt es keine Teilnehmer:innen. | R21 | geplant (T4) |
| `EZ_KIND_NOT_AVAILABLE` | [OFFEN] Meldung fehlt in spec.md | R21 | geplant (T4) |
| `EZ_DELETE_FORBIDDEN` | Du darfst Einsätze nicht löschen. | R15 | geplant (T5) |
| `EZ_KIND_NOT_ALLOWED` (`ez_create_helper` außerhalb des Arbeitseinsatzes) | [OFFEN] Meldung fehlt in spec.md | – | geplant (T5) |
| `EZ_NOT_FOUND` | Einsatz nicht gefunden. | R13 | geplant (T6) |
| `EZ_LOCATION_NO_POINTS` | [OFFEN] Meldung fehlt in spec.md | – | geplant (T6) |

`EZ_DUPLICATE_EVENT` bricht das Speichern ab und liefert `existing_id` nur, wenn der vorhandene Einsatz lesbar ist. „Trotzdem speichern“ ruft `ez_save_event` erneut mit `p_confirm_duplicate = true` auf (R8).

## Hinweise (keine Fehlermeldungen)

Diese Codes bzw. Fälle melden einen **erfolgreichen** Vorgang. Das Frontend zeigt sie als Hinweis an (z. B. sonner-Toast „info“) und nicht als Fehler. Die Aktion ist ausgeführt.

| Code / Fall | Hinweis | Regel | Status |
|---|---|---|---|
| `AD_EMAIL_CHANGED` (Antwort von `ad-access` `change_email`, HTTP 200) | Die Login-Adresse wurde geändert. Bitte die Einladung erneut senden. | R20 | geplant (T10) |
| Gültigkeitsdauer einer Qualifikationsart geändert (kein Code) | Die Änderung gilt für neue Einträge. Vorhandene Ablaufdaten bleiben unverändert. | R26 | geplant (T30) |

## Nur Frontend

### Administration (Supabase Auth)

| Fall | Meldung | Regel |
|---|---|---|
| jeder Login-Fehler | Anmeldung fehlgeschlagen. Bitte E-Mail-Adresse und Passwort prüfen. | R18 |
| Passwort vergessen (immer) | Wenn ein Zugang zu dieser Adresse besteht, haben wir dir eine E-Mail mit einem Link geschickt. | R18 |
| Passwort kürzer als 8 Zeichen | Das Passwort muss mindestens 8 Zeichen lang sein. | R19 |
| Eingaben verschieden | Die Passwörter stimmen nicht überein. | R19 |
| Link ungültig, `type=invite` | Der Link ist abgelaufen oder ungültig. Bitte wende dich an den Admin. | – |
| Link ungültig, `type=recovery` | Der Link ist abgelaufen oder ungültig. Bitte fordere einen neuen an. | – |

### Anwesenheitserfassung

| Fall | Meldung | Regel |
|---|---|---|
| Netzfehler | Die Eingabe wurde nicht gesendet. Bitte bei Verbindung erneut speichern. | – |
| Sitzung abgelaufen | Bitte erneut anmelden. | – |
| Löschen fehlgeschlagen | Der Einsatz konnte nicht gelöscht werden. Bitte erneut versuchen. | – |
| Suche ohne Treffer | Keine aktive Person gefunden. | – |
| unerwartet | Etwas ist schiefgelaufen. Bitte versuche es erneut. | – |

## Offene Punkte

- [OFFEN] Meldungstext fehlt in der Spec für `AD_TOO_MANY_IDS` (Quelle: docs/specs/ad-administration/spec.md v0.8, Abschnitt 2) sowie `EZ_STATUS_NOT_ALLOWED`, `EZ_KIND_NOT_AVAILABLE`, `EZ_KIND_NOT_ALLOWED`, `EZ_LOCATION_NO_POINTS` (Quelle: docs/specs/ez-einsaetze/spec.md v0.1, Abschnitte 2 und 5). Bis zur Klärung zeigt das Frontend die Meldung für unerwartete Fehler.
- [OFFEN] `EA_FIELD_LOCKED` und `EA_DATA_TYPE_LOCKED`: Beide stehen für R36. Ist `EA_FIELD_LOCKED` der Nachfolger (Datentyp je Feld seit v0.7) oder ein eigener Fall? (Quelle: docs/specs/ad-administration/spec.md v0.8, R36 und Abschnitt 5)
- [OFFEN] `EA_CONFIDENTIAL_FORBIDDEN`: Seit R29 regelt die Lesestufe „vertraulich“ den Lesezugriff, beim Setzen gilt `AD_CONFIDENTIAL_ONLY_AD`. Bleibt der Code? (Quelle: docs/specs/ad-administration/spec.md v0.8, R8, R29)
- [OFFEN] Ohne Code in der Spec: „Ein Feld mit dieser Bezeichnung gibt es bereits.“ (spec.md Administration, Abschnitt 5, „Weitere Meldungen“) und „Gruppe nicht gefunden.“ (gr-gruppen/02-stories.md v0.7, US-GR-19 AK6).
- Hinweis: Ein fehlendes Pflichtfeld heißt in EA „Bitte ‚<Feld>‘ ausfüllen.“ (R35), in EZ „Bitte ‚<Feld>‘ angeben.“ (EZ R1). Beide Texte sind wörtlich aus der jeweiligen Spec übernommen.
