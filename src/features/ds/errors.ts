// Fehlercodes des Bereichs Budget → Meldungen nach docs/specs/ad-administration/contracts/error-codes.md
// (Abschnitt „Bereich Budget“). Codes ohne Meldung in der Spec [OFFEN] zeigen die allgemeine Meldung.
import { MESSAGES, toMessage } from '@/lib/errors'
import { supabase } from '@/lib/supabase'

export const DS_MESSAGES = {
  forbidden: 'Für diesen Bereich hast du keine Rechte.',
  sumMismatch: 'Die Summe der Budgetposten passt nicht zur Summenzeile der Excel.',
  sheetMissing: (year: number) => `Kein Tabellenblatt ‚Finanzplan ${year}‘ gefunden.`,
  accountInvalid: 'Die Kontoangabe ist ungültig.',
  rangeInvalid: 'Der Kontenbereich ist ungültig.',
  ruleDuplicate: 'Für diese Kontoangabe gibt es schon eine gültige Regel.',
  itemUnknown: 'Budgetposten nicht gefunden.',
  referatRequired: 'Bitte ein Referat wählen.',
  noRows: 'Die Datei enthält keine Buchungen.',
  noPlan: (year: number | string) => `Für ${year} ist noch kein Finanzplan eingelesen.`,
  reasonRequired: 'Bitte einen Grund angeben.',
  noteTooLong: 'Der Hinweis darf höchstens 500 Zeichen haben.',
  reallocGroup: 'Umschichten geht nur zwischen Posten desselben Gesamtbudgets und derselben Art.',
  reallocAmount: (name: string) => `Der Betrag ist höher als der Plan von ‚${name}‘.`,
  reallocStale: 'Die Umschichtung passt nicht mehr zum Plan. Bitte ablehnen oder neu beantragen lassen.',
  ownRequest: 'Deinen eigenen Antrag bestätigt eine andere Person mit Budgetpflege.',
  proposalOpen: 'Zu dieser Buchung gibt es schon einen offenen Vorschlag.',
  // Leere Zustände (DS R26)
  noImport: (year: number | string) => `Noch kein DATEV-Export für ${year} eingespielt.`,
  noReferatBudget: 'Für dein Referat gibt es keinen Budgetposten im Finanzplan.',
  bookingsHidden: 'Einzelbuchungen siehst du nur für dein Referat.',
} as const

export type DsError = { code: string; details: string; text: string }

function field(value: unknown, key: string): string {
  if (typeof value !== 'object' || value === null) return ''
  const v = (value as Record<string, unknown>)[key]
  return typeof v === 'string' ? v : ''
}

export function dsError(error: unknown): DsError {
  const code = field(error, 'message')
  const details = field(error, 'details')
  const text = (() => {
    switch (code) {
      case 'FI_BUDGET_FORBIDDEN':
        return DS_MESSAGES.forbidden
      case 'FI_BUDGET_SUM_MISMATCH':
        return DS_MESSAGES.sumMismatch
      case 'FI_BUDGET_ACCOUNT_INVALID':
        return details ? `${DS_MESSAGES.accountInvalid} (${details})` : DS_MESSAGES.accountInvalid
      case 'FI_BUDGET_RANGE_INVALID':
        return details ? `${DS_MESSAGES.rangeInvalid} (${details})` : DS_MESSAGES.rangeInvalid
      case 'FI_BUDGET_RULE_DUPLICATE':
        return details ? `${DS_MESSAGES.ruleDuplicate} (${details})` : DS_MESSAGES.ruleDuplicate
      case 'FI_BUDGET_ITEM_UNKNOWN':
        return DS_MESSAGES.itemUnknown
      case 'FI_BUDGET_REFERAT_REQUIRED':
        return DS_MESSAGES.referatRequired
      case 'FI_BUDGET_NO_ROWS':
        return DS_MESSAGES.noRows
      case 'FI_BUDGET_NO_PLAN':
        return 'Für dieses Jahr ist noch kein Finanzplan eingelesen.'
      case 'FI_BUDGET_REASON_REQUIRED':
        return DS_MESSAGES.reasonRequired
      case 'FI_BUDGET_NOTE_TOO_LONG':
        return DS_MESSAGES.noteTooLong
      case 'FI_BUDGET_REALLOC_GROUP':
        return DS_MESSAGES.reallocGroup
      case 'FI_BUDGET_REALLOC_AMOUNT':
        return DS_MESSAGES.reallocAmount(details || '…')
      case 'FI_BUDGET_REALLOC_STALE':
        return DS_MESSAGES.reallocStale
      case 'FI_BUDGET_OWN_REQUEST':
        return DS_MESSAGES.ownRequest
      case 'FI_BUDGET_PROPOSAL_OPEN':
        return DS_MESSAGES.proposalOpen
      default:
        return code.startsWith('FI_BUDGET_') ? MESSAGES.unexpected : toMessage(error).text
    }
  })()
  return { code, details, text }
}

export type DsResult<T> = { data: T; error: null } | { data: null; error: DsError }

export async function dsRpc<T = unknown>(name: string, args: Record<string, unknown> = {}): Promise<DsResult<T>> {
  try {
    const { data, error } = await supabase.rpc(name, args)
    if (error) return { data: null, error: dsError(error) }
    return { data: data as T, error: null }
  } catch (caught) {
    return { data: null, error: dsError(caught) }
  }
}
