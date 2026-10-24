# Contract: Fehlercodes → Meldungen Gruppen

Stand: 24.10.2026 · Grundlage: [spec.md](../spec.md) v0.2, Abschnitt 5 und 2.3

Diese Liste ist normativ für Gruppen (spec.md 5, T2). Die Meldungstexte stehen wörtlich in spec.md. Die Datenbank meldet `raise exception '<CODE>' using errcode = 'P0001'`; das Frontend bildet die Codes in `src/lib/errors.ts` auf die Meldungen ab. Codes der Administration und des Ehrenamtsmanagements: [error-codes.md Administration](../../ad-administration/contracts/error-codes.md).

**Status:** „geplant (Tn)“ = Spec-Task aus spec.md Abschnitt 10; „umgesetzt“, sobald die Migration auf `main` ist.

## Fehler

| Code | Meldung | Regel | Ausgelöst in | Status |
|---|---|---|---|---|
| `GR_FORBIDDEN` | Für diesen Bereich hast du keine Rechte. | spec.md 3 | alle Schreibfunktionen, `gr_guardian_emails` | umgesetzt (Lesefunktionen T8 folgen) |
| `GR_ROSTER_FORBIDDEN` | Für diesen Bereich hast du keine Rechte. | R20, US-GR-19 AK5 | `gr_group_roster` | geplant (T8) |
| `GR_GROUP_NOT_FOUND` | Gruppe nicht gefunden. | US-GR-19 AK6 | `gr_group_roster`; Funktionen mit unbekannter Gruppe | umgesetzt (Lesefunktionen T8 folgen) |
| `GR_GROUP_DISSOLVED` | Die Gruppe ist aufgelöst und kann nicht mehr geändert werden. | spec.md 4, R38 | Gruppen-, Trainingszeit-, Aufnahme- und Funktionsfunktionen; `ea_properties_validate` | umgesetzt (Lesefunktionen T8 folgen) |
| `GR_GROUP_NAME_TAKEN` | Eine Gruppe mit diesem Namen gibt es bereits. | R1 | `gr_save_group` | umgesetzt |
| `GR_GROUP_FIELDS_REQUIRED` | Bitte Name und Referat angeben. | R1 | `gr_save_group` | umgesetzt |
| `GR_REFERAT_INACTIVE` | Dieses Referat ist nicht mehr aktiv. | R21 | `gr_save_group` | umgesetzt |
| `GR_GROUP_HAS_MEMBERS` | Die Gruppe hat noch aktive Teilnehmer:innen. | R9 | `gr_dissolve_group` | umgesetzt |
| `GR_GROUP_HAS_PENDING` | Die Gruppe hat noch offene Aufnahmen. | R9 | `gr_dissolve_group` | umgesetzt |
| `GR_DATE_IN_FUTURE` | Das Datum darf nicht in der Zukunft liegen. | R12, R27, spec.md 2.3 | `gr_dissolve_group`, Fotoerlaubnis, Einwilligung, Unterschriftsdatum | umgesetzt |
| `GR_TRAINING_TIME_REQUIRED` | Bitte Wochentag, Beginn, Ende und ‚gültig von‘ angeben. | R18 | Trainingszeit-Funktionen | umgesetzt |
| `GR_TRAINING_TIME_END` | Das Ende muss nach dem Beginn liegen. | R18 | Trainingszeit-Funktionen | umgesetzt |
| `GR_VALID_TO_BEFORE_FROM` | ‚Gültig bis‘ darf nicht vor ‚gültig von‘ liegen. | R18 | `gr_add_training_time`, `gr_end_training_time` | umgesetzt |
| `GR_CHANGE_DATE_INVALID` | Das Datum muss nach ‚gültig von‘ und innerhalb der Gültigkeit der bisherigen Trainingszeit liegen. | R19 | `gr_change_training_time` | umgesetzt |
| `GR_TRAINING_TIME_LOCKED` | Wochentag und Uhrzeit können nicht geändert werden. Bitte ‚Ändern ab‘ verwenden. | R19, A13 | Trigger `gr_training_times_guard` | umgesetzt |
| `GR_PERSON_INVALID` | Bitte eine vorhandene Person wählen oder eine neue anlegen. | spec.md 2.3 | Funktionen mit `p_person_id`/`p_new_person` | umgesetzt |
| `GR_BIRTH_DATE_FORBIDDEN` | Das Geburtsdatum kann nur die Geschäftsstelle erfassen. | spec.md 2.3 | `gr_start_admission`, `gr_update_person` | umgesetzt |
| `GR_PARTICIPANT_FIELDS_REQUIRED` | Bitte Vorname, Nachname, Geburtsdatum und Adresse angeben. | R2 | `gr_start_admission`, `gr_update_person` | umgesetzt |
| `GR_PENDING_EXISTS` | Für diese Person gibt es schon eine offene Aufnahme. | R10 | `gr_start_admission` | umgesetzt |
| `GR_ALREADY_MEMBER` | Diese Person ist bereits in der Gruppe. | R10 | `gr_start_admission`, `gr_admit` | umgesetzt |
| `GR_GUARDIAN_FIELDS_REQUIRED` | Bitte Vorname, Nachname und Adresse angeben. | R26 | `gr_add_guardian`, `gr_update_person` | umgesetzt |
| `GR_GUARDIAN_LIMIT` | Es können höchstens zwei erziehungsberechtigte Personen angegeben werden. | R3 | `gr_add_guardian`, Trigger auf `gr_guardians` | umgesetzt |
| `GR_GUARDIAN_EXISTS` | Diese Person ist bereits erziehungsberechtigt. | R22 | `gr_add_guardian` | umgesetzt |
| `GR_GUARDIAN_IS_HOLDER` | Diese Person ist Vertragsinhaber:in. Bitte zuerst den Vertrag ändern. | R22 | `gr_remove_guardian` | umgesetzt |
| `GR_CONTACT_REACHABILITY` | Bitte Telefon oder E-Mail angeben. | R7 | `gr_add_emergency_contact`, `gr_update_person` | umgesetzt |
| `GR_EMERGENCY_EXISTS` | Diese Person ist bereits Notfallkontakt. | R23 | `gr_add_emergency_contact` | umgesetzt |
| `GR_ORDER_INVALID` | Die Reihenfolge ist unvollständig. Bitte neu laden. | spec.md 2.3 | `gr_reorder_emergency_contacts` | umgesetzt |
| `GR_CONTRACT_REQUIRED` | Eine Teilnahme kann nur mit einem aktiven Vertrag angelegt werden. | R16 | `gr_admit` ohne Vertrag | umgesetzt |
| `GR_CONTRACT_FIELDS_REQUIRED` | Bitte alle Vertragsangaben ausfüllen. | R27 | Vertragsfunktionen | umgesetzt |
| `GR_HOLDER_INVALID` | Vertragsinhaber:in muss eine erziehungsberechtigte Person sein. | R4 | Vertragsfunktionen | umgesetzt |
| `GR_IBAN_INVALID` | Die IBAN ist ungültig. | R5 | Vertragsfunktionen | umgesetzt |
| `GR_MANDATE_TAKEN` | Diese Mandatsreferenz ist bereits vergeben. | R6 | Vertragsfunktionen, Unique-Index | umgesetzt |
| `GR_MANDATE_FORMAT` | Die Mandatsreferenz darf höchstens 35 Zeichen haben und nur Buchstaben, Ziffern und + ? / - : ( ) . , ' enthalten. | R27 | Vertragsfunktionen | umgesetzt |
| `GR_TEXT_TOO_LONG` | Der Text ist zu lang (höchstens `<n>` Zeichen). | R27 | Vertragsfunktionen (`detail` = n) | umgesetzt |
| `GR_AMOUNT_INVALID` | Der Betrag muss größer als 0 sein. | R27 | Vertragsfunktionen | umgesetzt |
| `GR_CONTRACT_EXISTS` | Für diese Teilnahme gibt es bereits einen Vertrag. | R8a | `gr_add_contract` | umgesetzt |
| `GR_CONTRACT_END_BEFORE_START` | Das Vertragsende darf nicht vor dem Vertragsbeginn liegen. | R8 | `gr_cancel_contract` | umgesetzt |
| `GR_LEFT_BEFORE_JOINED` | ‚Teilnahme bis‘ darf nicht vor dem Eintrittsdatum liegen. | R8 | `gr_end_membership`, `gr_cancel_contract` | umgesetzt |
| `GR_CONSENT_DATE_REQUIRED` | Bitte das Datum angeben. | R12 | `gr_set_photo_consent`, `gr_set_health_consent` | umgesetzt |
| `GR_CONSENT_UNCHANGED` | Der Wert ist bereits so gespeichert. | spec.md 2.3 | `gr_set_photo_consent`, `gr_set_health_consent` | umgesetzt |
| `GR_HEALTH_CONSENT_REQUIRED` | Bitte zuerst die Einwilligung der Erziehungsberechtigten erfassen. | R24 | `gr_save_health_note` | umgesetzt |
| `GR_HEALTH_NOTE_INVALID` | Bitte einen Text mit höchstens 2000 Zeichen eingeben. | spec.md 2.1 | `gr_save_health_note` | umgesetzt |
| `GR_FUNCTION_OVERLAP` | Diese Person hat diese Funktion in der Gruppe bereits. | R28 | `gr_add_group_function`, `gr_end_group_function` | umgesetzt |

Weiterverwendete Codes anderer Module: `AD_NAME_REQUIRED` (R4 AD, neue Person), `EA_RELATION_REQUIRED` und `EA_GROUP_RELATION_ONLY_GR` (R38, R39), `EA_VALID_RANGE` („gültig bis“ einer Funktion vor „seit“, plan.md H2). Unerwartete Fehler: „Etwas ist schiefgelaufen. Bitte versuche es erneut.“

## Hinweise (keine Fehler)

| Hinweis | Text | Regel | Quelle |
|---|---|---|---|
| unter 18 ohne Erziehungsberechtigte | Bitte mindestens eine erziehungsberechtigte Person angeben. | R2 | `gr_needs_guardian`, `gr_v_memberships.needs_guardian` |
| kein Notfallkontakt | Kein Notfallkontakt hinterlegt. | R7 | `gr_v_memberships.has_emergency_contact`, `gr_group_overview.no_emergency_count` |
| Teilnahme klären | Vertrag beendet am TT.MM.JJJJ – Teilnahme klären. | R17 | `gr_v_memberships.needs_clarification` |
| Trainingszeit überschneidet sich | Diese Trainingszeit überschneidet sich mit einer anderen. | R19 | Rückgabe `overlap` |
| Status ruhend/ausgeschieden | Die Person ist im Ehrenamtsmanagement ruhend. / … ausgeschieden. | R29 | Rückgabe `status_hint` von `gr_add_group_function` |
| E-Mail-Liste leer | Keine E-Mail-Adressen vorhanden. | R13 | leere Menge von `gr_guardian_emails` |
| E-Mail-Liste kopiert | N Adressen kopiert. Bitte in Blindkopie (BCC) einfügen. | spec.md 6 | Frontend |
