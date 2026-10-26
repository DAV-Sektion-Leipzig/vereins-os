# Contract: Fehlercodes → Meldungen

Stand: 23.10.2026 · Grundlage: [spec.md Administration](../spec.md) v0.9 (Abschnitt 5 und Abschnitt 2; umgesetzt wird zunächst der Kern bis v0.7.1, siehe [plan.md](../plan.md)), [02-stories.md Gruppen](../../gr-gruppen/02-stories.md) v0.7 (US-GR-19), [spec.md Anwesenheitserfassung](../../ez-einsaetze/spec.md) v0.5 (Abschnitt 5)

Diese Liste ist vollständig und normativ: Die Specs verweisen für die Zuordnung Code → Meldung auf sie. Die Meldungstexte stehen wörtlich in der jeweiligen Spec. Das Frontend bildet die Codes in `src/lib/errors.ts` auf die Meldungen ab.

- **Regel:** R-Nummer aus der Spec des jeweiligen Abschnitts (AD und EA: spec.md Administration; EZ: spec.md Anwesenheitserfassung).
- **Status:** „umgesetzt“ = Code bzw. Constraint existiert in einer Migration oder Edge Function auf `main`. „geplant (Tn)“ = Task aus Abschnitt 10 der jeweiligen spec.md (nicht die Nummerierung von tasks.md).
- **`<Feld>`** wird durch den Feldnamen ersetzt, den die Datenbank im Detail des Fehlers mitliefert.
- **[OFFEN]** = Meldungstext oder Bedeutung ist in der Spec nicht festgelegt; siehe „Offene Punkte“ am Ende.

## Administration (AD)

| Code / Constraint | Meldung | Regel | Status |
|---|---|---|---|
| `AD_EMAIL_DOMAIN` (Trigger `ad_accesses_guard`, Edge Functions) | Zugang nur mit Adresse @dav-leipzig.de möglich. | R1 | umgesetzt |
| `AD_EMAIL_MISSING` | Zugang nur mit Adresse @dav-leipzig.de möglich. | R1 | umgesetzt |
| `AD_EMAIL_TAKEN` / `ad_accesses_login_email_key` | Diese Login-Adresse ist bereits vergeben. | R2 | umgesetzt |
| `AD_EMAIL_LOCKED` | Die Login-Adresse kann nur vor der Aktivierung des Zugangs geändert werden. | R20 | umgesetzt |
| `AD_EMAIL_CHANGE_VIA_FUNCTION` (direktes Update bei Status `invited`, nur bei Umgehung der Oberfläche) | Etwas ist schiefgelaufen. Bitte versuche es erneut. | R20 | umgesetzt |
| `AD_NAME_REQUIRED` / `ea_persons_first_name_not_blank`, `ea_persons_last_name_not_blank` | Bitte Vorname und Nachname angeben. | R4 | umgesetzt |
| `AD_NO_TEMPLATE` | Bitte zuerst mindestens eine Rechtevorlage zuweisen. | R17 | umgesetzt |
| `AD_MAIL_FAILED` | Die Einladung konnte nicht verschickt werden. Bitte später erneut versuchen. | – | umgesetzt |
| `AD_TEMPLATE_NAME_TAKEN` / `ad_templates_name_key` | Eine Rechtevorlage mit diesem Namen gibt es bereits. | – | umgesetzt |
| `AD_SCOPE_NOT_ALLOWED` / `ad_template_rights_scope_allowed` | Die Reichweite ‚Referat‘ ist nur im Ehrenamtsmanagement, in der Anwesenheitserfassung, in der Planungshilfe Touren und Kurse und in Finanzen möglich. | R30 | umgesetzt; Text v0.10 (`20261029000100`) |
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
| `AD_LOCATION_NAME_REQUIRED` | Bitte eine Bezeichnung angeben. | R43 | Datenbank umgesetzt (`20261026000200`); Oberfläche T120 |
| `AD_LOCATION_NAME_TAKEN` | Einen Ort mit dieser Bezeichnung gibt es bereits. | R43 | Datenbank umgesetzt (`20261026000200`); Oberfläche T120 |
| `AD_SEARCH_TOO_SHORT` | Bitte mindestens 2 Zeichen eingeben. | R44 | Datenbank umgesetzt (`20261026000300`) |
| `AD_TOO_MANY_IDS` | Etwas ist schiefgelaufen. Bitte versuche es erneut. (allgemeine Meldung, Programmierfehler; Product Owner 24.10.2026) | R44 | Datenbank umgesetzt (`20261026000300`) |
| `AD_APPROVE_NOT_ALLOWED` / `ad_template_rights_approve_allowed` | ‚Darf freigeben‘ ist nur in Finanzen und in der Planungshilfe und nur zusammen mit einer Stufe möglich. | R50 | Datenbank umgesetzt (`20261029000100`); Oberfläche T74 |
| `AD_RATE_FIELD_REQUIRED` (Detail: Feld) | Bitte ‚<Feld>‘ angeben. | R46, R51, R54 | Datenbank umgesetzt (`20261029000200`, `…0300`) |
| `AD_RATE_VALUE` | Wert ungültig. | R46 | Datenbank umgesetzt (`20261029000200`) |
| `AD_RATE_DUPLICATE` | Für dieses Datum gibt es schon einen Wert. | R46, R52, R53, R54 | Datenbank umgesetzt (`20261029000200`, `…0300`) |
| `AD_REMUNERATION_DUPLICATE` | Diese Bezeichnung gibt es schon. | R51 | Datenbank umgesetzt (`20261029000300`) |
| `AD_RATE_KEY_UNKNOWN` (Detail: Schlüssel) | Den Satz ‚<Schlüssel>‘ gibt es nicht. | R51 | Datenbank umgesetzt (`20261029000300`) |
| `AD_REMUNERATION_POSITION` | Organisationspauschale und Lehreinheit nur ‚ohne Rolle‘, übrige Positionen mit Sätzen für Trainer:in und Helfer:in. | R51 | Datenbank umgesetzt (`20261029000300`) |
| `AD_REMUNERATION_INACTIVE` | Diese Abrechnungsart ist nicht mehr aktiv. Bitte eine andere wählen. | R52 | Datenbank umgesetzt (`20261029000300`) |
| `AD_DEADLINE_INVALID` | Bitte ein gültiges Datum angeben. | R53 | Datenbank umgesetzt (`20261029000300`) |
| `AD_DEADLINE_MISSING` | Etwas ist schiefgelaufen. Bitte versuche es erneut. (keine Frist für das Halbjahr; Stammdaten prüfen) | R53 | Datenbank umgesetzt (`20261029000300`) |
| `AD_BIC_INVALID` | BIC ungültig. | R54 | Datenbank umgesetzt (`20261029000300`) |
| `AD_CREDITOR_ID_INVALID` | Bitte eine gültige Gläubiger-Identifikationsnummer eingeben. | R57 | Datenbank umgesetzt (`20261102000100`) |
| `AD_FORBIDDEN`, SQLSTATE `42501` | Für diesen Bereich hast du keine Rechte. | R8, R43 | umgesetzt |
| Constraint `ea_referate_name_key` bzw. `ea_gremien_name_key` (kein Code, [ANNAHME]) | ~~Ein Referat mit dieser Bezeichnung gibt es bereits. / Ein Gremium mit dieser Bezeichnung gibt es bereits.~~ ersetzt durch „Diese Bezeichnung gibt es bereits.“ (EA spec.md Abschnitt 6, US-EA-14 AK3; Zeile im Abschnitt EA) | – | umgesetzt (Oberfläche: `/ea/stammdaten`) |
| Constraint `ad_qualification_types_discipline_not_blank` / `…_issuer_not_blank` (kein Code, [ANNAHME]) | Bitte eine Sparte angeben. / Bitte einen Aussteller angeben. | US-AD-17 AK2 | umgesetzt |
| `AD_UNAUTHENTICATED` (Edge Functions, HTTP 401) | weiter zu /login (keine Meldung) | – | umgesetzt |
| `AD_PERSON_NOT_FOUND`, `AD_INVALID_STATUS`, `AD_BAD_REQUEST`, `AD_UNEXPECTED`, unbekannt | Etwas ist schiefgelaufen. Bitte versuche es erneut. | – | umgesetzt |

`AD_EMAIL_DOMAIN` meldet in TEST denselben Text, wenn die Domain nicht in `ad_test_login_domains` freigegeben ist (R1).

`AD_EMAIL_MISSING` übernimmt die R1-Meldung, weil ohne Adresse keine Einladung möglich ist. Die Oberfläche bietet „Einladen“ ohne Login-Adresse gar nicht erst an.

`AD_FORBIDDEN` meldet auch `ea_search_active_persons` ohne EZ ≥ bearbeiten (spec.md Abschnitt 2).

`AD_SCOPE_NOT_ALLOWED`: Im Kern (bis v0.7.1) gilt der Text aus 02-stories.md US-AD-20 AK3. Mit dem Nachtrag v0.8 (T50, T54) wird er ersetzt durch „Die Reichweite ‚Referat‘ ist nur im Ehrenamtsmanagement und in der Anwesenheitserfassung möglich.“ (spec.md R30). Umgesetzt in der Datenbank mit `20261026000100`; die Oberfläche zeigt den neuen Text mit T120.

## Ehrenamtsmanagement (EA)

Soweit in spec.md Administration definiert (Personenmodell, Eigenschaftsarten, Eigenschaften, Ehrenamtsstatus).

| Code / Constraint | Meldung | Regel | Status |
|---|---|---|---|
| `EA_PROPERTY_TYPE_NAME_TAKEN` / `ea_property_types_name_key` | Eine Eigenschaftsart mit diesem Namen gibt es bereits. | – | umgesetzt |
| `EA_PURPOSE_REQUIRED` | Bitte einen Zweck angeben. | R9 | umgesetzt |
| `EA_CHOICE_VALUES_REQUIRED` | Bitte mindestens einen Auswahlwert angeben. | R9 | umgesetzt |
| `EA_NO_FIELDS` | Bitte mindestens ein Feld anlegen. | R9 | umgesetzt |
| `EA_DATA_TYPE_LOCKED` | Der Datentyp kann nicht geändert werden, solange Eigenschaften dieser Art existieren. | R36 | umgesetzt |
| `EA_FIELD_LOCKED` | Der Datentyp kann nicht geändert werden, solange Eigenschaften dieser Art existieren. [OFFEN] Abgrenzung zu `EA_DATA_TYPE_LOCKED` | R36 | nicht umgesetzt, bis [OFFEN] entschieden (der Kern wirft `EA_DATA_TYPE_LOCKED`) |
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
| `EA_RELATION_FOREIGN_REFERAT` | Du kannst nur Zuordnungen zu deinen Referaten pflegen. | R41, R45, R45a | umgesetzt; auch EZ-Weg (`20261026000400`) |
| `EA_CONFIDENTIAL_FORBIDDEN` | Für diesen Bereich hast du keine Rechte. [OFFEN] gilt nach R29 noch? | R8 | [OFFEN] |
| `EA_STATUS_FORBIDDEN` | Du darfst den Status dieser Person nicht ändern. | R33 | umgesetzt |
| `EA_CREATE_FOREIGN_REFERAT` | – | R45 | **entfällt** (spec.md v0.9.4, Nachtrag v0.8.1): fremdes Referat meldet auch über die Anwesenheitserfassung `EA_RELATION_FOREIGN_REFERAT` |
| `EA_CREATE_FORBIDDEN` | Für diesen Bereich hast du keine Rechte. | R41, R45, R45a | umgesetzt (EA, `20261024000600_ea_check_create`; Entscheidung Product Owner 23.10.2026, plan.md EA O3); EZ-Weg `20261026000400` |
| `EA_CREATE_REFERAT_REQUIRED` | Bitte eine Funktion oder ein Amt in deinem Referat angeben. | R3 EA | umgesetzt (EA, `20261024000600_ea_check_create`; Entscheidung Product Owner 23.10.2026, plan.md EA O3) |
| `EA_IBAN_INVALID` | Die IBAN ist ungültig. | R13 EA | umgesetzt (EA, `20261024000400_ea_iban`, Trigger `ea_properties_iban`) |
| `EA_STATUS_DATE` | Bitte ein Datum bis spätestens <TT.MM.JJJJ> wählen. | R18 EA | umgesetzt (EA, `20261024000500_ea_status_renew`; Grenzdatum im `detail`) |
| `EA_STATUS_UNCHANGED` | Die Person hat diesen Status bereits. | R19 EA | umgesetzt (EA, `20261024000500_ea_status_renew`) |
| `EA_LEAVE_PROPERTY` | Diese Angabe kann hier nicht beendet werden. | R20 EA | umgesetzt (EA, `20261024000500_ea_status_renew`) |
| `EA_RENEW_INVALID` | Nur aktuelle Lizenzen und Qualifikationen können verlängert werden; das neue Datum muss nach dem bisherigen liegen. | R6 EA | umgesetzt (EA, `20261024000500_ea_status_renew`) |
| Constraints `ea_referate_name_key`, `ea_gremien_name_key` (kein Code) | Diese Bezeichnung gibt es bereits. | US-EA-14 AK3 | umgesetzt (Index aus `20261023000200`) |

`EA_VALUE_TYPE`, `EA_FIELD_REQUIRED`, `EA_FIELD_CHOICE`, `AD_QUALIFICATION_HISTORIC` und `AD_QUALIFICATION_KIND` liefern die Feldbezeichnung im `detail` des Fehlers; `src/lib/errors.ts` setzt sie für „<Feld>“ ein. `EA_STATUS_DATE` liefert das Grenzdatum `TT.MM.JJJJ` im `detail` für „<TT.MM.JJJJ>“. „R… EA“ verweist auf docs/specs/ea-ehrenamt/spec.md Abschnitt 5. Der frühere Text von `EA_VALUE_TYPE` „Der Wert passt nicht zum Datentyp der Eigenschaftsart.“ entfällt.

`EA_VALID_RANGE` (Constraint `ea_properties_valid_range`): Die Oberfläche nennt statt „Gültig bis“/„gültig von“ die Bezeichnungen der Eigenschaftsart, falls gesetzt (R49), z. B. „‚Beendet am‘ darf nicht vor ‚erworben bzw. verlängert am‘ liegen.“ [ANNAHME spec v0.7.2].

## Gruppen (GR)

Die Codes von Gruppen stehen normativ in [contracts/error-codes.md Gruppen](../../gr-gruppen/contracts/error-codes.md) (spec.md Gruppen v0.2, Abschnitt 5 und T2), dort auch `GR_ROSTER_FORBIDDEN` und `GR_GROUP_NOT_FOUND` für die Anwesenheitserfassung.

## Anwesenheitserfassung (EZ)

Stand spec.md Anwesenheitserfassung v0.5 (Abschnitt 5 und 2). Ausführlich mit „Ausgelöst in“, weitergereichten Codes und Hinweisen: [contracts/error-codes.md Anwesenheitserfassung](../../ez-einsaetze/contracts/error-codes.md). Entfallen gegenüber v0.1: `EZ_END_TIME`, `EZ_KIND_NOT_AVAILABLE`.

| Code | Meldung | Regel | Status |
|---|---|---|---|
| `EZ_FORBIDDEN` | Für diesen Bereich hast du keine Rechte. | R13, R14 | umgesetzt |
| `EZ_NOT_FOUND` | Einsatz nicht gefunden. | R13 | umgesetzt |
| `EZ_DELETE_FORBIDDEN` | Du darfst Einsätze nicht löschen. | R15 | umgesetzt |
| `EZ_FIELD_REQUIRED` | Bitte ‚<Feld>‘ angeben. (Feld in `details`: Gruppe, Referat, Titel, Organisierende Person, Datum, Startdatum, Enddatum, Beginn, Ende, Dauer, Ort, Grund) | R1 | umgesetzt |
| `EZ_FIELD_LOCKED` | Einsatzart und Gruppe können nicht geändert werden. Bitte den Einsatz löschen lassen und neu erfassen. | R19 | umgesetzt |
| `EZ_END_DATE` | Das Enddatum muss nach dem Startdatum liegen. Für eintägige Einsätze bitte ‚eintägig‘ wählen. | R2 | umgesetzt |
| `EZ_TITLE_LENGTH` | Bitte einen Titel mit höchstens 90 Zeichen eingeben. | Längen | umgesetzt |
| `EZ_TRIAL_NAME` | Leer: „Bitte einen Vornamen eingeben.“ Zu lang: „Bitte höchstens 30 Zeichen eingeben.“ | R6 | umgesetzt |
| `EZ_REMARK_LENGTH` | Die Bemerkung darf höchstens 500 Zeichen haben. | R7 | umgesetzt |
| `EZ_LOCATION_INACTIVE` | Dieser Ort ist nicht mehr aktiv. Bitte einen anderen Ort wählen. | R12 | umgesetzt |
| `EZ_LOCATION_NO_POINTS` | Etwas ist schiefgelaufen. Bitte versuche es erneut. (keine eigene Meldung in spec.md; die Oberfläche bietet nur Orte mit Punktekonto an) | US-EZ-16 | umgesetzt |
| `EZ_ORGANIZER_NOT_ACTIVE` | Bitte eine aktive Person auswählen. | R11 | umgesetzt |
| `EZ_PERSON_NOT_ACTIVE` | Bitte eine aktive Person auswählen. | R20 | umgesetzt |
| `EZ_PARTICIPANT_NOT_IN_GROUP` | Diese Person ist an diesem Tag nicht Teilnehmer:in der Gruppe. | R16 | umgesetzt |
| `EZ_DUPLICATE_PERSON` | Diese Person ist bereits eingetragen. | R17 | umgesetzt |
| `EZ_DUPLICATE_EVENT` (Rückfrage, kein Abbruch) | Für diese Gruppe ist an diesem Tag bereits ein Einsatz dieser Art erfasst. Trotzdem speichern? | R8 | umgesetzt |
| `EZ_MIN_ATTENDANCE` | Bitte mindestens eine Trainer:in oder Helfer:in und eine Teilnehmer:in auswählen. | R5 | umgesetzt |
| `EZ_STATUS_NOT_ALLOWED` | Etwas ist schiefgelaufen. Bitte versuche es erneut. (keine eigene Meldung in spec.md; die Oberfläche bietet „eingetragen“ nur bei Arbeitseinsatz, Kurs und Tour an) | R21 | umgesetzt |
| `EZ_ROLE_NOT_ALLOWED` | Bei dieser Einsatzart gibt es keine Teilnehmer:innen. | R21 | umgesetzt |
| `EZ_KIND_NOT_ALLOWED` | Etwas ist schiefgelaufen. Bitte versuche es erneut. (keine eigene Meldung in spec.md; nur bei Aufrufen außerhalb der Oberfläche) | R30, US-EZ-11 | umgesetzt |
| `EZ_GROUP_REFERAT_MISMATCH` | Alle Gruppen müssen zum selben Referat gehören. | R30 | umgesetzt |
| `EZ_EVENT_CANCELLED` | Der Einsatz ist abgesagt. Bitte zuerst die Absage zurücknehmen. | R22 | umgesetzt |
| `EZ_CANCEL_REASON` | Bitte einen Grund mit höchstens 500 Zeichen angeben. | R23 | umgesetzt |
| `EZ_CANCEL_NOT_ALLOWED` | Der Einsatz hat schon anwesende Personen und kann nicht abgesagt werden. | R23 | umgesetzt |
| `EZ_TK_MANAGED` | Dieser Einsatz kommt aus der Planungshilfe Touren und Kurse. Bitte dort ändern. | R25 | umgesetzt |
| `EZ_EVENT_LOCKED` | Der Einsatz ist schon erfasst und wurde nicht geändert. | R26, R27 | zurückgestellt (T19) |
| `EZ_SETTLED` (Detail: person_id bei einer Anwesenheit) | Dieser Einsatz ist abgerechnet. Änderungen nur nach Rücknahme des Abschlusses in Finanzen. | R34 (v0.6) | Datenbank umgesetzt (`20261030000200`); Oberfläche EZ T27 |
| `EZ_REMUNERATION_INACTIVE` | Diese Abrechnungsart ist nicht mehr aktiv. Bitte eine andere wählen. | R32 (v0.6) | Datenbank umgesetzt (`20261030000200`); Oberfläche EZ T27 |
| `EZ_PRIVACY_NOT_CONFIRMED` | Bitte bestätige, dass die Person informiert wurde. | R29 | umgesetzt |
| `EZ_PERSON_NOT_INACTIVE` | Diese Person ist bereits aktiv. | R31 | umgesetzt |

`EZ_DUPLICATE_EVENT` bricht das Speichern ab und liefert `existing_id` nur, wenn der vorhandene Einsatz lesbar ist. „Trotzdem speichern“ ruft `ez_save_event` erneut mit `p_confirm_duplicate = true` auf (R8).

## Finanzen (FI)

spec.md FI v0.2 Abschnitt 5; Datenbank umgesetzt (`20261031000100`–`…0700`), Oberfläche folgt.

| Code | Meldung | Regel | Status |
|---|---|---|---|
| `FI_FORBIDDEN` | Für diesen Bereich hast du keine Rechte. | R32 | Datenbank umgesetzt |
| `FI_NOT_FOUND` | Abrechnung nicht gefunden. | R31 | Datenbank umgesetzt |
| `FI_STATUS` | In diesem Zustand ist das nicht möglich. | R20 | Datenbank umgesetzt |
| `FI_PERIOD_INVALID` | Etwas ist schiefgelaufen. Bitte versuche es erneut. (ungültiges Halbjahr, Programmierfehler) | – | Datenbank umgesetzt |
| `FI_REASON_REQUIRED` | Bitte eine Begründung angeben. | R16, R23 | Datenbank umgesetzt |
| `FI_QUANTITY` | Bitte eine gültige Menge eingeben. | R16 | Datenbank umgesetzt |
| `FI_RATE_MISSING` | Für eine Position fehlt der Satz. | R9 | Datenbank umgesetzt |
| `FI_AMOUNT_ZERO` | Die Abrechnung hat keinen Betrag. | US-FI-10 | Datenbank umgesetzt |
| `FI_NOT_CONFIRMED` | Die Abrechnung ist noch nicht von allen Referaten bestätigt. | R23 | Datenbank umgesetzt |
| `FI_SAME_PERSON` | Du hast diese Abrechnung bestätigt. Eine andere Person muss abschließen. | R23 | Datenbank umgesetzt |
| `FI_DATE_FUTURE` | Das Datum darf nicht in der Zukunft liegen. | US-FI-12 | Datenbank umgesetzt |
| `FI_LATE_REASON_REQUIRED` (Detail: Frist) | Die Frist ist abgelaufen. Der Anspruch ist erloschen. Trotzdem als abgegeben erfassen? (Rückfrage mit Begründung) | R19 | Datenbank umgesetzt |
| `FI_DEADLINE_NOT_PASSED` | Die Frist ist noch nicht abgelaufen. | US-FI-12 | Datenbank umgesetzt |
| `FI_EXECUTION_DATE` | Das Ausführungsdatum darf nicht in der Vergangenheit liegen. | R30 | Datenbank umgesetzt |
| `FI_NOT_PAYABLE` (Detail: Name bzw. ID) | Nicht auszahlbar: {Name} ({Grund}). | R12–R14 | Datenbank umgesetzt |
| `FI_RUN_EMPTY` | Die Runde enthält keine auszahlbaren Abrechnungen. | US-FI-15 | Datenbank umgesetzt |
| `FI_PAYOUT_SETTINGS_MISSING` | Die Angaben der Sektion für die Auszahlung fehlen. Bitte den Admin informieren. | R26 | Datenbank umgesetzt |
| `FI_LOCATION_NO_POINTS` | Dieser Ort hat kein Punktekonto. | US-FI-17 | Datenbank umgesetzt |
| `FI_COLLECTION_MONTH` | Für diesen Monat ist kein Buchungslauf möglich. | R36, R38 | Datenbank umgesetzt (`20261102000300`) |
| `FI_DUE_DATE` | Der Fälligkeitstag muss mindestens einen Bankarbeitstag in der Zukunft liegen. | R39 | Datenbank umgesetzt |
| `FI_COLLECTION_EMPTY` | Der Buchungslauf enthält keine Lastschriften. | R45 | Datenbank umgesetzt |
| `FI_COLLECTION_SETTINGS_MISSING` | Die Angaben der Sektion für den Einzug fehlen. Bitte den Admin informieren. | R45 | Datenbank umgesetzt |
| `FI_COLLECTION_TAKEN` | Dieser Vertrag ist in diesem Monat bereits in einem anderen Buchungslauf. | R35 | Datenbank umgesetzt |
| `FI_COLLECTION_EXCLUDED` | Diese Lastschrift kann nicht gewählt werden (Mandat noch nicht unterschrieben). | R37 | Datenbank umgesetzt |
| `FI_COLLECTION_CHANGED` (Detail: Name) | Verträge haben sich seit dem Erstellen geändert. Bitte den Buchungslauf aktualisieren. | R34 | Datenbank umgesetzt |
| `FI_EXTRA_REQUIRED` | Bitte Text und Begründung angeben. | R47 | Datenbank umgesetzt |
| `FI_AMOUNT_INVALID` | Bitte einen gültigen Betrag eingeben. | R47 | Datenbank umgesetzt |

## Hinweise (keine Fehlermeldungen)

Diese Codes bzw. Fälle melden einen **erfolgreichen** Vorgang. Das Frontend zeigt sie als Hinweis an (z. B. sonner-Toast „info“) und nicht als Fehler. Die Aktion ist ausgeführt.

| Code / Fall | Hinweis | Regel | Status |
|---|---|---|---|
| `AD_EMAIL_CHANGED` (Antwort von `ad-access` `change_email`, HTTP 200) | Die Login-Adresse wurde geändert. Bitte die Einladung erneut senden. | R20 | umgesetzt |
| Gültigkeitsdauer einer Qualifikationsart geändert (kein Code) | Die Änderung gilt für neue Einträge. Vorhandene Ablaufdaten bleiben unverändert. | R26 | umgesetzt |

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

### Administration, Formulare ([ANNAHME], ohne Quelle in spec.md)

| Fall | Meldung | Regel |
|---|---|---|
| Vorlage zuweisen ohne Auswahl | Bitte eine Vorlage wählen. | US-AD-11 |
| Feld einer Eigenschaftsart ohne Bezeichnung | Bitte jedem Feld eine Bezeichnung geben. | US-AD-22 |
| Eigenschaftsart ohne Modul unter „sichtbar in“ | Bitte mindestens ein Modul unter „sichtbar in“ wählen. | US-AD-12 AK1 |

### Anwesenheitserfassung

| Fall | Meldung | Regel |
|---|---|---|
| Netzfehler | Die Eingabe wurde nicht gesendet. Bitte bei Verbindung erneut speichern. | – |
| Sitzung abgelaufen | Bitte erneut anmelden. | – |
| Löschen fehlgeschlagen | Der Einsatz konnte nicht gelöscht werden. Bitte erneut versuchen. | – |
| Suche ohne Treffer | Keine aktive Person gefunden. | – |
| unerwartet | Etwas ist schiefgelaufen. Bitte versuche es erneut. | – |

## Offene Punkte

- Erledigt 24.10.2026: `AD_TOO_MANY_IDS` nutzt die allgemeine Meldung (spec.md v0.9.4). [OFFEN] Meldungstext fehlt in der Spec für `EZ_STATUS_NOT_ALLOWED`, `EZ_KIND_NOT_ALLOWED`, `EZ_LOCATION_NO_POINTS` (Quelle: docs/specs/ez-einsaetze/spec.md v0.5, Abschnitte 2 und 5; `EZ_KIND_NOT_AVAILABLE` entfällt seit v0.2). Die Oberfläche bietet diese Fälle nicht an; tritt einer doch auf, zeigt das Frontend die Meldung für unerwartete Fehler.
- [OFFEN] `EA_FIELD_LOCKED` und `EA_DATA_TYPE_LOCKED`: Beide stehen für R36. Ist `EA_FIELD_LOCKED` der Nachfolger (Datentyp je Feld seit v0.7) oder ein eigener Fall? (Quelle: docs/specs/ad-administration/spec.md v0.8, R36 und Abschnitt 5)
- [OFFEN] `EA_CONFIDENTIAL_FORBIDDEN`: Seit R29 regelt die Lesestufe „vertraulich“ den Lesezugriff, beim Setzen gilt `AD_CONFIDENTIAL_ONLY_AD`. Bleibt der Code? (Quelle: docs/specs/ad-administration/spec.md v0.8, R8, R29)
- [OFFEN] Ohne Code in der Spec: „Ein Feld mit dieser Bezeichnung gibt es bereits.“ (spec.md Administration, Abschnitt 5, „Weitere Meldungen“) und „Gruppe nicht gefunden.“ (gr-gruppen/02-stories.md v0.7, US-GR-19 AK6).
- Hinweis: Ein fehlendes Pflichtfeld heißt in EA „Bitte ‚<Feld>‘ ausfüllen.“ (R35), in EZ „Bitte ‚<Feld>‘ angeben.“ (EZ R1). Beide Texte sind wörtlich aus der jeweiligen Spec übernommen.
