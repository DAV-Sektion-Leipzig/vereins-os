// Fehlercodes der Finanzen → Meldungen nach docs/specs/ad-administration/contracts/error-codes.md (Abschnitt FI).
import { MESSAGES, toMessage } from '@/lib/errors'

export const FI_MESSAGES = {
  forbidden: 'Für diesen Bereich hast du keine Rechte.',
  notFound: 'Abrechnung nicht gefunden.',
  status: 'In diesem Zustand ist das nicht möglich.',
  reasonRequired: 'Bitte eine Begründung angeben.',
  quantity: 'Bitte eine gültige Menge eingeben.',
  rateMissing: 'Für eine Position fehlt der Satz.',
  amountZero: 'Die Abrechnung hat keinen Betrag.',
  notConfirmed: 'Die Abrechnung ist noch nicht von allen Referaten bestätigt.',
  samePerson: 'Du hast diese Abrechnung bestätigt. Eine andere Person muss abschließen.',
  dateFuture: 'Das Datum darf nicht in der Zukunft liegen.',
  lateReason: 'Die Frist ist abgelaufen. Der Anspruch ist erloschen. Trotzdem als abgegeben erfassen?',
  deadlineNotPassed: 'Die Frist ist noch nicht abgelaufen.',
  executionDate: 'Das Ausführungsdatum darf nicht in der Vergangenheit liegen.',
  notPayable: 'Nicht auszahlbar: <Name>.',
  runEmpty: 'Die Runde enthält keine auszahlbaren Abrechnungen.',
  payoutSettingsMissing: 'Die Angaben der Sektion für die Auszahlung fehlen. Bitte den Admin informieren.',
  locationNoPoints: 'Dieser Ort hat kein Punktekonto.',
  collectionMonth: 'Für diesen Monat ist kein Buchungslauf möglich.',
  dueDate: 'Der Fälligkeitstag muss mindestens einen Bankarbeitstag in der Zukunft liegen.',
  collectionEmpty: 'Der Buchungslauf enthält keine Lastschriften.',
  collectionSettingsMissing: 'Die Angaben der Sektion für den Einzug fehlen. Bitte den Admin informieren.',
  collectionTaken: 'Dieser Vertrag ist in diesem Monat bereits in einem anderen Buchungslauf.',
  collectionExcluded: 'Diese Lastschrift kann nicht gewählt werden (Mandat noch nicht unterschrieben).',
  collectionChanged: 'Verträge haben sich seit dem Erstellen geändert. Bitte den Buchungslauf aktualisieren.',
  extraRequired: 'Bitte Text und Begründung angeben.',
  amountInvalid: 'Bitte einen gültigen Betrag eingeben.',
  collectionReleased: 'Dieser Buchungslauf ist bereits freigegeben. Die Lastschriftdatei nicht erneut hochladen.',
  // Nur Frontend (spec.md FI 6)
  emptyHalf: 'Für dieses Halbjahr gibt es noch keine Abrechnungen.',
  deleteXmlHint: 'Bitte die Überweisungsdatei nach dem Hochladen im Online-Banking von diesem Rechner löschen.',
  alreadyReleased: 'Diese Runde ist bereits freigegeben. Die Überweisungsdatei nicht erneut hochladen.',
} as const

const CODES: Record<string, string> = {
  FI_FORBIDDEN: FI_MESSAGES.forbidden,
  FI_NOT_FOUND: FI_MESSAGES.notFound,
  FI_STATUS: FI_MESSAGES.status,
  FI_PERIOD_INVALID: MESSAGES.unexpected,
  FI_REASON_REQUIRED: FI_MESSAGES.reasonRequired,
  FI_QUANTITY: FI_MESSAGES.quantity,
  FI_RATE_MISSING: FI_MESSAGES.rateMissing,
  FI_AMOUNT_ZERO: FI_MESSAGES.amountZero,
  FI_NOT_CONFIRMED: FI_MESSAGES.notConfirmed,
  FI_SAME_PERSON: FI_MESSAGES.samePerson,
  FI_DATE_FUTURE: FI_MESSAGES.dateFuture,
  FI_LATE_REASON_REQUIRED: FI_MESSAGES.lateReason,
  FI_DEADLINE_NOT_PASSED: FI_MESSAGES.deadlineNotPassed,
  FI_EXECUTION_DATE: FI_MESSAGES.executionDate,
  FI_NOT_PAYABLE: FI_MESSAGES.notPayable,
  FI_RUN_EMPTY: FI_MESSAGES.runEmpty,
  FI_PAYOUT_SETTINGS_MISSING: FI_MESSAGES.payoutSettingsMissing,
  FI_LOCATION_NO_POINTS: FI_MESSAGES.locationNoPoints,
  FI_COLLECTION_MONTH: FI_MESSAGES.collectionMonth,
  FI_DUE_DATE: FI_MESSAGES.dueDate,
  FI_COLLECTION_EMPTY: FI_MESSAGES.collectionEmpty,
  FI_COLLECTION_SETTINGS_MISSING: FI_MESSAGES.collectionSettingsMissing,
  FI_COLLECTION_TAKEN: FI_MESSAGES.collectionTaken,
  FI_COLLECTION_EXCLUDED: FI_MESSAGES.collectionExcluded,
  FI_COLLECTION_CHANGED: FI_MESSAGES.collectionChanged,
  FI_EXTRA_REQUIRED: FI_MESSAGES.extraRequired,
  FI_AMOUNT_INVALID: FI_MESSAGES.amountInvalid,
}

export type FiError = {
  code: string
  /** detail der Datenbank: betroffene Abrechnung (id), Name (FI_NOT_PAYABLE) oder Frist (FI_LATE_REASON_REQUIRED). */
  details: string
  text: string
}

function field(value: unknown, key: string): string {
  if (typeof value !== 'object' || value === null) return ''
  const v = (value as Record<string, unknown>)[key]
  return typeof v === 'string' ? v : ''
}

/**
 * Meldung zu einem Fehler. names löst eine Abrechnungs-ID im Detail in einen Namen auf
 * (Mehrfachaktionen: „Anna Beispiel: Für eine Position fehlt der Satz.“).
 */
export function fiError(error: unknown, names: Record<string, string> = {}): FiError {
  const code = field(error, 'message')
  const details = field(error, 'details')
  if (code in CODES) {
    const who = names[details]
    if (code === 'FI_COLLECTION_CHANGED' && details) return { code, details, text: `${CODES[code]} (${details})` }
    if (code === 'FI_NOT_PAYABLE') return { code, details, text: CODES[code].replace('<Name>', who ?? (details || 'eine Abrechnung')) }
    return { code, details, text: who ? `${who}: ${CODES[code]}` : CODES[code] }
  }
  return { code, details, text: toMessage(error).text }
}
