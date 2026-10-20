# Contract: Fehlercodes → Meldungen

Diese Liste ist vollständig und normativ: [spec.md](../spec.md) v0.5 Abschnitt 5 verweist auf sie. Die Meldungstexte stehen wörtlich in spec.md bzw. 02-stories.md. Das Frontend bildet die Codes in `src/lib/errors.ts` auf die Meldungen ab.

## Datenbank und Edge Functions

| Code / Constraint | Meldung | Regel |
|---|---|---|
| `AD_EMAIL_DOMAIN` (Trigger `ad_accesses_guard`, Edge Functions) | Zugang nur mit Adresse @dav-leipzig.de möglich. Gilt auch in TEST bei nicht freigegebener Domain. | R1 |
| `AD_EMAIL_TAKEN` / `ad_accesses_login_email_key` | Diese Login-Adresse ist bereits vergeben. | R2 |
| `AD_EMAIL_LOCKED` | Die Login-Adresse kann nur vor der Aktivierung des Zugangs geändert werden. | R20 |
| `AD_EMAIL_CHANGE_VIA_FUNCTION` (direktes Update bei Status `invited`, nur bei Umgehung der Oberfläche) | Etwas ist schiefgelaufen. Bitte versuche es erneut. | R20 |
| `AD_EMAIL_MISSING` | Zugang nur mit Adresse @dav-leipzig.de möglich. | R1 |
| `AD_NAME_REQUIRED` | Bitte Vorname und Nachname angeben. | R4 |
| `AD_NO_TEMPLATE` | Bitte zuerst mindestens eine Rechtevorlage zuweisen. | R17 |
| `AD_MAIL_FAILED` | Die Einladung konnte nicht verschickt werden. Bitte später erneut versuchen. | – |
| `AD_TEMPLATE_NAME_TAKEN` / `ad_templates_name_key` | Eine Rechtevorlage mit diesem Namen gibt es bereits. | – |
| `EA_PROPERTY_TYPE_NAME_TAKEN` / `ea_property_types_name_key` | Eine Eigenschaftsart mit diesem Namen gibt es bereits. | – |
| `EA_PURPOSE_REQUIRED` | Bitte einen Zweck angeben. | R9 |
| `EA_CHOICE_VALUES_REQUIRED` | Bitte mindestens einen Auswahlwert angeben. | R9 |
| `EA_DATA_TYPE_LOCKED` | Der Datentyp kann nicht geändert werden, solange Eigenschaften dieser Art existieren. | – |
| `EA_CHOICE_VALUE_REMOVED` | Auswahlwerte können ergänzt, aber nicht entfernt werden. | – |
| `EA_VALID_RANGE` / `ea_properties_valid_range` | ‚Gültig bis‘ darf nicht vor ‚gültig von‘ liegen. | – |
| `EA_VALUE_TYPE` | Der Wert passt nicht zum Datentyp der Eigenschaftsart. | – |
| `AD_FORBIDDEN`, `EA_CONFIDENTIAL_FORBIDDEN`, SQLSTATE `42501` | Für diesen Bereich hast du keine Rechte. | R8 |
| `AD_UNAUTHENTICATED` | weiter zu /login (keine Meldung) | – |
| `AD_PERSON_NOT_FOUND`, `AD_INVALID_STATUS`, `AD_BAD_REQUEST`, `AD_UNEXPECTED`, unbekannt | Etwas ist schiefgelaufen. Bitte versuche es erneut. | – |

`AD_EMAIL_MISSING` übernimmt die R1-Meldung, weil ohne Adresse keine Einladung möglich ist. Die Oberfläche bietet „Einladen“ ohne Login-Adresse gar nicht erst an.

## Hinweise (keine Fehlermeldungen)

Diese Codes melden einen **erfolgreichen** Vorgang. Das Frontend zeigt sie als Hinweis an (z. B. sonner-Toast „info“) und nicht als Fehler. Die Aktion ist ausgeführt.

| Code | Hinweis | Regel |
|---|---|---|
| `AD_EMAIL_CHANGED` (Antwort von `ad-access` `change_email`, HTTP 200) | Die Login-Adresse wurde geändert. Bitte die Einladung erneut senden. | R20 |

## Nur Frontend (Supabase Auth)

| Fall | Meldung | Regel |
|---|---|---|
| jeder Login-Fehler | Anmeldung fehlgeschlagen. Bitte E-Mail-Adresse und Passwort prüfen. | R18 |
| Passwort vergessen (immer) | Wenn ein Zugang zu dieser Adresse besteht, haben wir dir eine E-Mail mit einem Link geschickt. | R18 |
| Passwort kürzer als 8 Zeichen | Das Passwort muss mindestens 8 Zeichen lang sein. | R19 |
| Eingaben verschieden | Die Passwörter stimmen nicht überein. | R19 |
| Link ungültig, `type=invite` | Der Link ist abgelaufen oder ungültig. Bitte wende dich an den Admin. | – |
| Link ungültig, `type=recovery` | Der Link ist abgelaufen oder ungültig. Bitte fordere einen neuen an. | – |
