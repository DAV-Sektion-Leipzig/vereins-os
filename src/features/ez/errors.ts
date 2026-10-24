// Fehlercodes der Anwesenheitserfassung → Meldungen nach docs/specs/ez-einsaetze/contracts/error-codes.md.
// Codes anderer Module übernimmt toMessage (src/lib/errors.ts).
import { MESSAGES, toMessage } from '@/lib/errors'

export const EZ_MESSAGES = {
  forbidden: 'Für diesen Bereich hast du keine Rechte.',
  notFound: 'Einsatz nicht gefunden.',
  deleteForbidden: 'Du darfst Einsätze nicht löschen.',
  fieldRequired: 'Bitte ‚<Feld>‘ angeben.',
  fieldLocked: 'Einsatzart und Gruppe können nicht geändert werden. Bitte den Einsatz löschen lassen und neu erfassen.',
  endDate: 'Das Enddatum muss nach dem Startdatum liegen. Für eintägige Einsätze bitte ‚eintägig‘ wählen.',
  titleLength: 'Bitte einen Titel mit höchstens 90 Zeichen eingeben.',
  trialRequired: 'Bitte einen Vornamen eingeben.',
  trialTooLong: 'Bitte höchstens 30 Zeichen eingeben.',
  remarkLength: 'Die Bemerkung darf höchstens 500 Zeichen haben.',
  locationInactive: 'Dieser Ort ist nicht mehr aktiv. Bitte einen anderen Ort wählen.',
  personNotActive: 'Bitte eine aktive Person auswählen.',
  participantNotInGroup: 'Diese Person ist an diesem Tag nicht Teilnehmer:in der Gruppe.',
  duplicatePerson: 'Diese Person ist bereits eingetragen.',
  duplicateEvent: 'Für diese Gruppe ist an diesem Tag bereits ein Einsatz dieser Art erfasst. Trotzdem speichern?',
  minAttendance: 'Bitte mindestens eine Trainer:in oder Helfer:in und eine Teilnehmer:in auswählen.',
  roleNotAllowed: 'Bei dieser Einsatzart gibt es keine Teilnehmer:innen.',
  groupReferatMismatch: 'Alle Gruppen müssen zum selben Referat gehören.',
  eventCancelled: 'Der Einsatz ist abgesagt. Bitte zuerst die Absage zurücknehmen.',
  cancelReason: 'Bitte einen Grund mit höchstens 500 Zeichen angeben.',
  cancelNotAllowed: 'Der Einsatz hat schon anwesende Personen und kann nicht abgesagt werden.',
  tkManaged: 'Dieser Einsatz kommt aus der Planungshilfe Touren und Kurse. Bitte dort ändern.',
  eventLocked: 'Der Einsatz ist schon erfasst und wurde nicht geändert.',
  privacyNotConfirmed: 'Bitte bestätige, dass die Person informiert wurde.',
  personNotInactive: 'Diese Person ist bereits aktiv.',
  // Nur Frontend (spec.md 5, „Weitere Meldungen“)
  network: 'Die Eingabe wurde nicht gesendet. Bitte bei Verbindung erneut speichern.',
  sessionExpired: 'Bitte erneut anmelden.',
  deleteFailed: 'Der Einsatz konnte nicht gelöscht werden. Bitte erneut versuchen.',
  noActivePerson: 'Keine aktive Person gefunden.',
} as const

const CODES: Record<string, string> = {
  EZ_FORBIDDEN: EZ_MESSAGES.forbidden,
  EZ_NOT_FOUND: EZ_MESSAGES.notFound,
  EZ_DELETE_FORBIDDEN: EZ_MESSAGES.deleteForbidden,
  EZ_FIELD_REQUIRED: EZ_MESSAGES.fieldRequired,
  EZ_FIELD_LOCKED: EZ_MESSAGES.fieldLocked,
  EZ_END_DATE: EZ_MESSAGES.endDate,
  EZ_TITLE_LENGTH: EZ_MESSAGES.titleLength,
  EZ_REMARK_LENGTH: EZ_MESSAGES.remarkLength,
  EZ_LOCATION_INACTIVE: EZ_MESSAGES.locationInactive,
  EZ_ORGANIZER_NOT_ACTIVE: EZ_MESSAGES.personNotActive,
  EZ_PERSON_NOT_ACTIVE: EZ_MESSAGES.personNotActive,
  EZ_PARTICIPANT_NOT_IN_GROUP: EZ_MESSAGES.participantNotInGroup,
  EZ_DUPLICATE_PERSON: EZ_MESSAGES.duplicatePerson,
  EZ_DUPLICATE_EVENT: EZ_MESSAGES.duplicateEvent,
  EZ_MIN_ATTENDANCE: EZ_MESSAGES.minAttendance,
  EZ_ROLE_NOT_ALLOWED: EZ_MESSAGES.roleNotAllowed,
  EZ_GROUP_REFERAT_MISMATCH: EZ_MESSAGES.groupReferatMismatch,
  EZ_EVENT_CANCELLED: EZ_MESSAGES.eventCancelled,
  EZ_CANCEL_REASON: EZ_MESSAGES.cancelReason,
  EZ_CANCEL_NOT_ALLOWED: EZ_MESSAGES.cancelNotAllowed,
  EZ_TK_MANAGED: EZ_MESSAGES.tkManaged,
  EZ_EVENT_LOCKED: EZ_MESSAGES.eventLocked,
  EZ_PRIVACY_NOT_CONFIRMED: EZ_MESSAGES.privacyNotConfirmed,
  EZ_PERSON_NOT_INACTIVE: EZ_MESSAGES.personNotInactive,
  // ohne eigene Meldung in spec.md: allgemeine Meldung (contracts/error-codes.md)
  EZ_STATUS_NOT_ALLOWED: MESSAGES.unexpected,
  EZ_KIND_NOT_ALLOWED: MESSAGES.unexpected,
  EZ_LOCATION_NO_POINTS: MESSAGES.unexpected,
}

export type EzError = {
  code: string
  /** detail der Datenbank: Feldname (EZ_FIELD_REQUIRED), person_id, existing_id (EZ_DUPLICATE_EVENT). */
  details: string
  text: string
}

function field(value: unknown, key: string): string {
  if (typeof value !== 'object' || value === null) return ''
  const v = (value as Record<string, unknown>)[key]
  return typeof v === 'string' ? v : ''
}

/** Netzfehler (fetch scheitert) bzw. abgelaufene Sitzung erkennen (US-EZ-18). */
function isNetworkError(error: unknown): boolean {
  const message = field(error, 'message')
  return error instanceof TypeError || /Failed to fetch|NetworkError|Load failed/i.test(message)
}

export function ezError(error: unknown): EzError {
  const code = field(error, 'message')
  const details = field(error, 'details')
  if (code in CODES) return { code, details, text: CODES[code].replace('<Feld>', details || 'Feld') }
  if (code === 'EZ_TRIAL_NAME') {
    return { code, details, text: details === 'too_long' ? EZ_MESSAGES.trialTooLong : EZ_MESSAGES.trialRequired }
  }
  if (isNetworkError(error)) return { code: 'NETWORK', details: '', text: EZ_MESSAGES.network }
  const pgCode = field(error, 'code')
  if (pgCode === 'PGRST301' || /JWT expired/i.test(code)) return { code: 'SESSION', details: '', text: EZ_MESSAGES.sessionExpired }
  return { code: code || pgCode, details, text: toMessage(error).text }
}
