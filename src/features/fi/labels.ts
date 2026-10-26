// Bezeichnungen der Finanzen nach glossar.md und spec.md FI 2 (Typen), Beträge „1.234,56 €“ (spec.md FI 6).
import { todayIso } from '@/lib/format'

export type SettlementStatus = 'draft' | 'confirmed' | 'closed' | 'submitted' | 'expired' | 'paid'
export type RateRole = 'trainer' | 'helper' | 'none'
export type Position = 'training_unit' | 'day' | 'half_day' | 'competition_day' | 'organization_day'
export type RunStatus = 'draft' | 'released'

export const STATUS_LABELS: Record<SettlementStatus, string> = {
  draft: 'Entwurf',
  confirmed: 'bestätigt',
  closed: 'abgeschlossen',
  submitted: 'abgegeben',
  expired: 'verfallen',
  paid: 'ausgezahlt',
}

export const STATUSES = Object.keys(STATUS_LABELS) as SettlementStatus[]

export const RUN_STATUS_LABELS: Record<RunStatus, string> = { draft: 'Entwurf', released: 'freigegeben' }

export const RATE_ROLE_LABELS: Record<RateRole, string> = { trainer: 'Trainer:in', helper: 'Helfer:in', none: 'ohne Rolle' }

export const POSITION_LABELS: Record<Position, string> = {
  training_unit: 'Trainingseinheit',
  day: 'Tagessatz',
  half_day: 'Halbtagessatz',
  competition_day: 'Wettkampfbetreuung je Tag',
  organization_day: 'Organisationspauschale je Tag',
}

/** Hinweise der Abrechnung (R11–R14) und der Positionen (R4, R5, R8, R9). */
export const HINT_LABELS: Record<string, string> = {
  no_tax_confirmation: 'Bestätigung steuerfreie Einnahmen fehlt',
  no_bank_account: 'Bankverbindung fehlt',
  no_trainer_agreement: 'Trainervereinbarung fehlt',
  max_exceeded: 'Höchstbetrag überschritten',
  has_new_events: 'nicht abgerechnete Einsätze',
  no_time: 'ohne Uhrzeit',
  no_training_time: 'ohne Trainingszeit',
  no_license: 'keine förderfähige Lizenz',
  rate_missing: 'Satz fehlt',
  amount_zero: 'kein Betrag',
}

export function hintLabel(hint: string, year?: number): string {
  if (hint === 'no_tax_confirmation' && year) return `Bestätigung steuerfreie Einnahmen ${year} fehlt`
  return HINT_LABELS[hint] ?? hint
}

export const LOG_LABELS: Record<string, string> = {
  calculated: 'berechnet',
  corrected: 'Position korrigiert',
  exception_reason: 'Ausnahme begründet',
  confirmed: 'bestätigt',
  confirmed_substitute: 'in Vertretung bestätigt',
  confirmation_reset: 'Bestätigung zurückgesetzt',
  closed: 'abgeschlossen',
  reopened: 'Abschluss zurückgenommen',
  submitted: 'Abgabe erfasst',
  expired: 'verfallen',
  paid: 'ausgezahlt',
}

const money = new Intl.NumberFormat('de-DE', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
const quantity = new Intl.NumberFormat('de-DE', { maximumFractionDigits: 2 })

export function formatMoney(value: number | string | null | undefined): string {
  if (value === null || value === undefined || value === '') return '–'
  return `${money.format(Number(value))} €`
}

export function formatQuantity(value: number | string | null | undefined): string {
  if (value === null || value === undefined || value === '') return '–'
  return quantity.format(Number(value))
}

/** Halbjahr als Schlüssel „JJJJ-1“ bzw. „JJJJ-2“. */
export type Half = { year: number; half: 1 | 2 }

export function halfKey(h: Half): string {
  return `${h.year}-${h.half}`
}

export function parseHalf(key: string | null): Half | null {
  const m = key?.match(/^(\d{4})-([12])$/)
  return m ? { year: Number(m[1]), half: Number(m[2]) as 1 | 2 } : null
}

export function halfLabel(h: Half): string {
  return `${h.half}. Halbjahr ${h.year}`
}

/** Standard: aktuelles Halbjahr (spec.md FI 6). */
export function currentHalf(today = todayIso()): Half {
  const [y, m] = today.split('-').map(Number)
  return { year: y, half: m <= 6 ? 1 : 2 }
}

/** Auswahl: von 1. Halbjahr 2026 bis zum aktuellen Halbjahr, neuestes zuerst. */
export function halfOptions(today = todayIso()): Half[] {
  const current = currentHalf(today)
  const list: Half[] = []
  for (let y = current.year; y >= 2026; y--) {
    for (const half of [2, 1] as const) {
      if (y === current.year && half > current.half) continue
      list.push({ year: y, half })
    }
  }
  return list
}

/** Nächster Werktag Mo–Fr nach heute (R30 [ANNAHME]; Feiertage nicht berücksichtigt). */
export function nextWorkday(today = todayIso()): string {
  const [y, m, d] = today.split('-').map(Number)
  const date = new Date(Date.UTC(y, m - 1, d))
  do date.setUTCDate(date.getUTCDate() + 1)
  while (date.getUTCDay() === 0 || date.getUTCDay() === 6)
  return date.toISOString().slice(0, 10)
}

const MONTHS = ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember']

/** Monat ausgeschrieben, z. B. „Dezember 2026“ (Buchungslauf, R42). */
export function monthLabel(month: string): string {
  const [y, m] = month.split('-').map(Number)
  return `${MONTHS[m - 1]} ${y}`
}
