// Fehlercodes → Meldungen nach docs/specs/ad-administration/contracts/error-codes.md (normativ).

export type MessageKind = 'error' | 'info'

export type AppMessage = {
  kind: MessageKind
  text: string
}

export const MESSAGES = {
  emailDomain: 'Zugang nur mit Adresse @dav-leipzig.de möglich.',
  emailTaken: 'Diese Login-Adresse ist bereits vergeben.',
  emailLocked: 'Die Login-Adresse kann nur vor der Aktivierung des Zugangs geändert werden.',
  emailChanged: 'Die Login-Adresse wurde geändert. Bitte die Einladung erneut senden.',
  nameRequired: 'Bitte Vorname und Nachname angeben.',
  noTemplate: 'Bitte zuerst mindestens eine Rechtevorlage zuweisen.',
  mailFailed: 'Die Einladung konnte nicht verschickt werden. Bitte später erneut versuchen.',
  templateNameTaken: 'Eine Rechtevorlage mit diesem Namen gibt es bereits.',
  propertyTypeNameTaken: 'Eine Eigenschaftsart mit diesem Namen gibt es bereits.',
  purposeRequired: 'Bitte einen Zweck angeben.',
  choiceValuesRequired: 'Bitte mindestens einen Auswahlwert angeben.',
  dataTypeLocked: 'Der Datentyp kann nicht geändert werden, solange Eigenschaften dieser Art existieren.',
  choiceValueRemoved: 'Auswahlwerte können ergänzt, aber nicht entfernt werden.',
  validRange: '‚Gültig bis‘ darf nicht vor ‚gültig von‘ liegen.',
  valueType: 'Der Wert für ‚<Feld>‘ passt nicht zum Datentyp.',
  noFields: 'Bitte mindestens ein Feld anlegen.',
  fieldNewRequired: 'Neue Felder können nur optional angelegt werden, solange es Eigenschaften dieser Art gibt.',
  relationLocked: 'Der Bezug kann nicht geändert werden, solange Eigenschaften dieser Art existieren.',
  fieldLabelTaken: 'Ein Feld mit dieser Bezeichnung gibt es bereits.',
  labelTooLong: 'Die Bezeichnung darf höchstens 40 Zeichen lang sein.',
  fieldRequired: 'Bitte ‚<Feld>‘ ausfüllen.',
  fieldUnknown: 'Unbekanntes Feld.',
  fieldChoice: 'Bitte einen Wert aus der Liste wählen.',
  singleValue: 'Für diese Eigenschaftsart ist nur ein gültiger Eintrag je Zeitraum erlaubt.',
  relationRequired: 'Bitte ein Referat (bzw. Gremium, Gruppe) wählen.',
  groupRelationOnlyGr: 'Diese Angabe wird im Modul Gruppen gepflegt.',
  relationForeignReferat: 'Du kannst nur Zuordnungen zu deinen Referaten pflegen.',
  statusForbidden: 'Du darfst den Status dieser Person nicht ändern.',
  confidentialOnlyAd: 'Nur mit Rechten auf die Administration möglich.',
  scopeNotAllowed: 'Die Reichweite ‚Referat‘ ist nur im Ehrenamtsmanagement möglich.',
  referatRequired: 'Bitte mindestens ein Referat auswählen.',
  qualificationNameRequired: 'Bitte eine Bezeichnung angeben.',
  qualificationNameTaken: 'Eine Qualifikationsart mit dieser Bezeichnung gibt es bereits.',
  qualificationCodeTaken: 'Dieses Kürzel ist bereits vergeben.',
  qualificationCodeFormat: 'Das Kürzel darf nur Großbuchstaben und Ziffern enthalten (max. 10 Zeichen).',
  qualificationLevelRequired: 'Bitte eine Lizenzstufe wählen.',
  qualificationValidity: 'Bitte eine Gültigkeitsdauer in Jahren angeben (1–10).',
  qualificationHistoric: 'Diese Qualifikationsart ist historisch und kann nicht neu vergeben werden.',
  qualificationKind: 'Dieser Typ von Qualifikation ist hier nicht erlaubt.',
  disciplineRequired: 'Bitte eine Sparte angeben.',
  issuerRequired: 'Bitte einen Aussteller angeben.',
  referatNameTaken: 'Ein Referat mit dieser Bezeichnung gibt es bereits.',
  gremiumNameTaken: 'Ein Gremium mit dieser Bezeichnung gibt es bereits.',
  forbidden: 'Für diesen Bereich hast du keine Rechte.',
  unexpected: 'Etwas ist schiefgelaufen. Bitte versuche es erneut.',
  loginFailed: 'Anmeldung fehlgeschlagen. Bitte E-Mail-Adresse und Passwort prüfen.',
  resetRequested: 'Wenn ein Zugang zu dieser Adresse besteht, haben wir dir eine E-Mail mit einem Link geschickt.',
  passwordTooShort: 'Das Passwort muss mindestens 8 Zeichen lang sein.',
  passwordMismatch: 'Die Passwörter stimmen nicht überein.',
  inviteLinkInvalid: 'Der Link ist abgelaufen oder ungültig. Bitte wende dich an den Admin.',
  recoveryLinkInvalid: 'Der Link ist abgelaufen oder ungültig. Bitte fordere einen neuen an.',
} as const

// Codes aus Datenbank (raise exception '<CODE>') und Edge Functions ({ code })
const CODE_MESSAGES: Record<string, string> = {
  AD_EMAIL_DOMAIN: MESSAGES.emailDomain,
  AD_EMAIL_MISSING: MESSAGES.emailDomain,
  AD_EMAIL_TAKEN: MESSAGES.emailTaken,
  AD_EMAIL_LOCKED: MESSAGES.emailLocked,
  AD_NAME_REQUIRED: MESSAGES.nameRequired,
  AD_NO_TEMPLATE: MESSAGES.noTemplate,
  AD_MAIL_FAILED: MESSAGES.mailFailed,
  AD_TEMPLATE_NAME_TAKEN: MESSAGES.templateNameTaken,
  EA_PROPERTY_TYPE_NAME_TAKEN: MESSAGES.propertyTypeNameTaken,
  EA_PURPOSE_REQUIRED: MESSAGES.purposeRequired,
  EA_CHOICE_VALUES_REQUIRED: MESSAGES.choiceValuesRequired,
  EA_DATA_TYPE_LOCKED: MESSAGES.dataTypeLocked,
  EA_CHOICE_VALUE_REMOVED: MESSAGES.choiceValueRemoved,
  EA_VALID_RANGE: MESSAGES.validRange,
  EA_VALUE_TYPE: MESSAGES.valueType,
  EA_NO_FIELDS: MESSAGES.noFields,
  EA_FIELD_NEW_REQUIRED: MESSAGES.fieldNewRequired,
  EA_RELATION_LOCKED: MESSAGES.relationLocked,
  EA_LABEL_TOO_LONG: MESSAGES.labelTooLong,
  EA_FIELD_REQUIRED: MESSAGES.fieldRequired,
  EA_FIELD_UNKNOWN: MESSAGES.fieldUnknown,
  EA_FIELD_CHOICE: MESSAGES.fieldChoice,
  EA_SINGLE_VALUE: MESSAGES.singleValue,
  EA_RELATION_REQUIRED: MESSAGES.relationRequired,
  EA_GROUP_RELATION_ONLY_GR: MESSAGES.groupRelationOnlyGr,
  EA_RELATION_FOREIGN_REFERAT: MESSAGES.relationForeignReferat,
  EA_STATUS_FORBIDDEN: MESSAGES.statusForbidden,
  AD_CONFIDENTIAL_ONLY_AD: MESSAGES.confidentialOnlyAd,
  AD_SCOPE_NOT_ALLOWED: MESSAGES.scopeNotAllowed,
  AD_REFERAT_REQUIRED: MESSAGES.referatRequired,
  AD_QUALIFICATION_NAME_REQUIRED: MESSAGES.qualificationNameRequired,
  AD_QUALIFICATION_NAME_TAKEN: MESSAGES.qualificationNameTaken,
  AD_QUALIFICATION_CODE_TAKEN: MESSAGES.qualificationCodeTaken,
  AD_QUALIFICATION_CODE_FORMAT: MESSAGES.qualificationCodeFormat,
  AD_QUALIFICATION_LEVEL_REQUIRED: MESSAGES.qualificationLevelRequired,
  AD_QUALIFICATION_VALIDITY: MESSAGES.qualificationValidity,
  AD_QUALIFICATION_HISTORIC: MESSAGES.qualificationHistoric,
  AD_QUALIFICATION_KIND: MESSAGES.qualificationKind,
  AD_FORBIDDEN: MESSAGES.forbidden,
  EA_CONFIDENTIAL_FORBIDDEN: MESSAGES.forbidden,
}

// Hinweise: erfolgreicher Vorgang, keine Fehlermeldung
const INFO_CODES: Record<string, string> = {
  AD_EMAIL_CHANGED: MESSAGES.emailChanged,
}

// Constraint-Namen (Absicherung in der Datenbank)
const CONSTRAINT_MESSAGES: Record<string, string> = {
  ad_accesses_login_email_key: MESSAGES.emailTaken,
  ad_templates_name_key: MESSAGES.templateNameTaken,
  ea_property_types_name_key: MESSAGES.propertyTypeNameTaken,
  ea_properties_valid_range: MESSAGES.validRange,
  ea_persons_first_name_not_blank: MESSAGES.nameRequired,
  ea_persons_last_name_not_blank: MESSAGES.nameRequired,
  ea_property_fields_label_key: MESSAGES.fieldLabelTaken,
  ad_template_rights_scope_allowed: MESSAGES.scopeNotAllowed,
  ad_qualification_types_name_key: MESSAGES.qualificationNameTaken,
  ad_qualification_types_code_key: MESSAGES.qualificationCodeTaken,
  ad_qualification_types_discipline_not_blank: MESSAGES.disciplineRequired,
  ad_qualification_types_issuer_not_blank: MESSAGES.issuerRequired,
  ea_property_types_valid_from_label_length: MESSAGES.labelTooLong,
  ea_property_types_valid_to_label_length: MESSAGES.labelTooLong,
  ea_referate_name_key: MESSAGES.referatNameTaken,
  ea_gremien_name_key: MESSAGES.gremiumNameTaken,
}

type ErrorLike = {
  code?: unknown
  message?: unknown
  details?: unknown
}

function asErrorLike(value: unknown): ErrorLike {
  return typeof value === 'object' && value !== null ? (value as ErrorLike) : {}
}

/** Setzt den Feldnamen aus dem detail des Datenbankfehlers in den Platzhalter „<Feld>“ ein (R35). */
function withField(text: string, details: string): string {
  return text.replace('<Feld>', details || 'Feld')
}

function findConstraint(text: string): string | undefined {
  return Object.keys(CONSTRAINT_MESSAGES).find((name) => text.includes(name))
}

/** Bildet einen Code (Datenbank, Edge Function) oder einen Fehler auf eine Meldung ab. */
export function toMessage(errorOrCode: unknown): AppMessage {
  if (typeof errorOrCode === 'string') {
    if (errorOrCode in INFO_CODES) return { kind: 'info', text: INFO_CODES[errorOrCode] }
    return { kind: 'error', text: withField(CODE_MESSAGES[errorOrCode] ?? MESSAGES.unexpected, '') }
  }

  const error = asErrorLike(errorOrCode)
  const code = typeof error.code === 'string' ? error.code : ''
  const message = typeof error.message === 'string' ? error.message : ''
  const details = typeof error.details === 'string' ? error.details : ''

  // Codes aus der Datenbank kommen als Meldungstext (raise exception '<CODE>'), aus Edge Functions als code
  for (const candidate of [message, code]) {
    if (candidate in INFO_CODES) return { kind: 'info', text: INFO_CODES[candidate] }
    if (candidate in CODE_MESSAGES) return { kind: 'error', text: withField(CODE_MESSAGES[candidate], details) }
  }

  const constraint = findConstraint(`${message} ${details}`)
  if (constraint) return { kind: 'error', text: CONSTRAINT_MESSAGES[constraint] }

  if (code === '42501') return { kind: 'error', text: MESSAGES.forbidden }

  return { kind: 'error', text: MESSAGES.unexpected }
}
