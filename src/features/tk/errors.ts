// Fehlercodes der Planungshilfe → Meldungen nach docs/specs/ad-administration/contracts/error-codes.md (Abschnitt TK).
// Codes anderer Module (EA_*, AD_*) übernimmt toMessage (src/lib/errors.ts).
import { MESSAGES, toMessage } from '@/lib/errors'
import { MISSING_LABELS } from '@/features/tk/labels'

export const TK_MESSAGES = {
  forbidden: 'Keine Berechtigung.',
  forbiddenCourse: 'Für Kurse ist das Referat Ausbildung zuständig. Dir fehlt das Recht für dieses Referat.',
  forbiddenTour: 'Für Touren ist das Referat Touren zuständig. Dir fehlt das Recht für dieses Referat.',
  notFound: 'Planung nicht gefunden.',
  conflict: 'Die Planung wurde inzwischen von <Name> geändert. Bitte neu laden; deine Eingaben bleiben bis dahin sichtbar.',
  lockedApproved: 'Nach der Freigabe ändern nur Personen mit Freigaberecht oder die Geschäftsstelle.',
  lockedFinal: 'Diese Planung ist abgeschlossen und kann nicht mehr geändert werden.',
  statusNotAllowed: 'Dieser Schritt ist im aktuellen Status nicht möglich.',
  missing: 'Noch <n> Angaben offen.',
  missingApprove: 'Freigabe nicht möglich: Angaben fehlen.',
  commentQuery: 'Bitte die Rückfrage beschreiben.',
  commentCancel: 'Bitte einen Grund angeben.',
  personNotActive: 'Bitte eine aktive Person auswählen.',
  duplicatePerson: 'Diese Person ist schon eingetragen.',
  phoneInvalid: 'Bitte eine Telefonnummer eingeben.',
  emailInvalid: 'Bitte eine gültige E-Mail-Adresse eingeben.',
  notFinished: 'Die Tour ist noch nicht vorbei.',
  ezFailed: 'Einsatz konnte nicht angelegt werden. Bitte später erneut versuchen.',
  ezLocked: 'Der Einsatz ist schon erfasst oder abgerechnet und wurde nicht geändert. Bitte in der Anwesenheitserfassung anpassen.',
  ezLockedCancel: 'Absage nicht möglich: Im Einsatz sind schon Personen als anwesend erfasst oder er ist abgerechnet.',
  ezSyncFailed: 'Die Planung ist gespeichert, der Einsatz konnte nicht aktualisiert werden. Bitte später erneut speichern.',
  deleteForbidden: 'Löschen ist nur für Entwürfe und abgesagte Planungen ohne Einsatz möglich.',
  planCancelled: 'Die Planung ist abgesagt.',
  privacyNotConfirmed: 'Bitte bestätige, dass du die Person informiert hast.',
  personNotInactive: 'Diese Person ist bereits aktiv.',
  fieldInvalid: 'Bitte die Eingabe prüfen.',
  // Nur Frontend (spec.md 5, „Weitere Meldungen“)
  saveFailed: 'Speichern fehlgeschlagen. Deine Eingaben sind noch da – bitte erneut speichern.',
  noAccess: 'Kein Zugriff auf die Planungshilfe Touren und Kurse.',
} as const

export type TkError = {
  code: string
  details: string
  text: string
  /** Fehlende Angaben bei TK_MISSING_FIELDS (Schlüssel). */
  missing?: string[]
}

function field(value: unknown, key: string): string {
  if (typeof value !== 'object' || value === null) return ''
  const v = (value as Record<string, unknown>)[key]
  return typeof v === 'string' ? v : ''
}

function isNetworkError(error: unknown): boolean {
  return error instanceof TypeError || /Failed to fetch|NetworkError|Load failed/i.test(field(error, 'message'))
}

const SIMPLE: Record<string, string> = {
  TK_FORBIDDEN: TK_MESSAGES.forbidden,
  TK_NOT_FOUND: TK_MESSAGES.notFound,
  TK_STATUS_NOT_ALLOWED: TK_MESSAGES.statusNotAllowed,
  TK_PERSON_NOT_ACTIVE: TK_MESSAGES.personNotActive,
  TK_DUPLICATE_PERSON: TK_MESSAGES.duplicatePerson,
  TK_PHONE_INVALID: TK_MESSAGES.phoneInvalid,
  TK_EMAIL_INVALID: TK_MESSAGES.emailInvalid,
  TK_NOT_FINISHED: TK_MESSAGES.notFinished,
  TK_EZ_FAILED: TK_MESSAGES.ezFailed,
  TK_EZ_SYNC_FAILED: TK_MESSAGES.ezSyncFailed,
  TK_DELETE_FORBIDDEN: TK_MESSAGES.deleteForbidden,
  TK_PLAN_CANCELLED: TK_MESSAGES.planCancelled,
  TK_PRIVACY_NOT_CONFIRMED: TK_MESSAGES.privacyNotConfirmed,
  TK_PERSON_NOT_INACTIVE: TK_MESSAGES.personNotInactive,
  TK_FIELD_INVALID: TK_MESSAGES.fieldInvalid,
  TK_STATUS_DIRECT: MESSAGES.unexpected,
  TK_FIELD_LOCKED: MESSAGES.unexpected,
  TK_REFERAT_MISSING: MESSAGES.unexpected,
}

export function tkError(error: unknown, action?: string): TkError {
  const code = field(error, 'message')
  const details = field(error, 'details')
  if (code === 'TK_MISSING_FIELDS') {
    const missing = details ? details.split(',') : []
    const base = action === 'approve' ? TK_MESSAGES.missingApprove : TK_MESSAGES.missing.replace('<n>', String(missing.length))
    return { code, details, missing, text: base }
  }
  if (code === 'TK_FORBIDDEN_REFERAT') {
    return { code, details, text: details === 'course' ? TK_MESSAGES.forbiddenCourse : TK_MESSAGES.forbiddenTour }
  }
  if (code === 'TK_CONFLICT') return { code, details, text: TK_MESSAGES.conflict.replace('<Name>', details || 'einer anderen Person') }
  if (code === 'TK_LOCKED') {
    return { code, details, text: details === 'approved' ? TK_MESSAGES.lockedApproved : TK_MESSAGES.lockedFinal }
  }
  if (code === 'TK_COMMENT_REQUIRED') {
    return { code, details, text: details === 'cancel' ? TK_MESSAGES.commentCancel : TK_MESSAGES.commentQuery }
  }
  if (code === 'TK_EZ_LOCKED') {
    return { code, details, text: action === 'cancel' ? TK_MESSAGES.ezLockedCancel : TK_MESSAGES.ezLocked }
  }
  if (code === 'TK_FIELD_INVALID' && details && MISSING_LABELS[details]) {
    return { code, details, text: `${TK_MESSAGES.fieldInvalid} (${MISSING_LABELS[details]})` }
  }
  if (code in SIMPLE) return { code, details, text: SIMPLE[code] }
  if (isNetworkError(error)) return { code: 'NETWORK', details: '', text: TK_MESSAGES.saveFailed }
  return { code, details, text: toMessage(error).text }
}
