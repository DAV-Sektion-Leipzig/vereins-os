// DATEV-Kontenblätter (CSV) lesen wie der Prototyp (prototyp-budget-dashboard.md Abschnitt 3): Kopfzeile mit Mandant und
// Exportzeit, Abschnitt Kontenübersicht (Summen je Konto), Abschnitt Buchungsliste. Spalten werden über ihre Namen
// gefunden. Ergebnis geht unverändert an fi_budget_import_preview / fi_budget_import (alle Regeln in der Datenbank).
import { decodeText, headerKey, parseAmount, parseCsv, parseGermanDate } from './csv.ts'

export type DatevOverview = { konto: string; eb: number | null; soll: number | null; haben: number | null }

export type DatevRow = {
  line: number
  konto: string
  datum: string | null
  bu: string
  gegenkonto: string
  gegenkonto_label: string
  text: string
  beleg: string
  soll: number | null
  haben: number | null
  kost1: string
}

export type DatevFile = { name: string; info: string; overview: DatevOverview[]; rows: DatevRow[] }

export type DatevProblem = { line: number; type: 'date' | 'amount' | 'both_sides'; value: string }

export type DatevResult =
  | { ok: true; file: DatevFile; problems: DatevProblem[] }
  | { ok: false; error: 'no_bookings' | 'columns_missing'; missing?: string[] }

const BOOKING_COLUMNS = {
  konto: ['konto', 'kontonummer'],
  datum: ['datum', 'belegdatum'],
  bu: ['bu', 'bu-schlüssel', 'bu schlüssel'],
  gegenkonto: ['gegenkonto', 'gegenkonto (ohne bu-schlüssel)'],
  gegenkonto_label: ['beschriftung gegenkonto', 'gegenkontobeschriftung'],
  text: ['buchungstext'],
  beleg: ['belegfeld 1', 'belegfeld1', 'beleg'],
  soll: ['umsatz soll', 'soll'],
  haben: ['umsatz haben', 'haben'],
  kost1: ['kost1', 'kost 1', 'kostenstelle', 'kost1 - kostenstelle'],
} as const

const REQUIRED_BOOKING: (keyof typeof BOOKING_COLUMNS)[] = ['konto', 'datum', 'text', 'soll', 'haben']

const OVERVIEW_COLUMNS = {
  konto: ['konto', 'kontonummer'],
  eb: ['eb-wert', 'eb wert', 'eröffnungsbilanzwert'],
  soll: ['umsatz soll', 'soll'],
  haben: ['umsatz haben', 'haben'],
} as const

function findColumns<K extends string>(header: string[], spec: Record<K, readonly string[]>): Record<K, number> {
  const keys = header.map(headerKey)
  const result = {} as Record<K, number>
  for (const name of Object.keys(spec) as K[]) {
    result[name] = keys.findIndex((k) => spec[name].includes(k))
  }
  return result
}

function isBookingHeader(row: string[]): boolean {
  const keys = row.map(headerKey)
  return keys.includes('buchungstext') && keys.some((k) => k === 'konto' || k === 'kontonummer')
}

function isOverviewHeader(row: string[]): boolean {
  const keys = row.map(headerKey)
  return (
    keys.some((k) => OVERVIEW_COLUMNS.konto.includes(k as never)) &&
    keys.some((k) => OVERVIEW_COLUMNS.eb.includes(k as never)) &&
    !keys.includes('buchungstext')
  )
}

function cell(row: string[], index: number): string {
  return index >= 0 ? (row[index] ?? '').trim() : ''
}

export function parseDatev(name: string, bytes: ArrayBuffer | Uint8Array): DatevResult {
  return parseDatevText(name, decodeText(bytes))
}

export function parseDatevText(name: string, text: string): DatevResult {
  const lines = parseCsv(text)
  const info = (lines[0] ?? []).map((c) => c.trim()).filter(Boolean).join(' · ').slice(0, 300)
  const overview: DatevOverview[] = []
  const rows: DatevRow[] = []
  const problems: DatevProblem[] = []
  let mode: 'none' | 'overview' | 'bookings' = 'none'
  let ov: Record<keyof typeof OVERVIEW_COLUMNS, number> | null = null
  let bk: Record<keyof typeof BOOKING_COLUMNS, number> | null = null

  for (let i = 0; i < lines.length; i++) {
    const row = lines[i]
    const lineNo = i + 1
    if (row.every((c) => c.trim() === '')) continue
    if (isBookingHeader(row)) {
      bk = findColumns(row, BOOKING_COLUMNS)
      const missing = REQUIRED_BOOKING.filter((k) => bk![k] < 0)
      if (missing.length > 0) return { ok: false, error: 'columns_missing', missing }
      mode = 'bookings'
      continue
    }
    if (isOverviewHeader(row)) {
      ov = findColumns(row, OVERVIEW_COLUMNS)
      mode = ov.konto >= 0 ? 'overview' : 'none'
      continue
    }
    if (mode === 'overview' && ov) {
      const konto = cell(row, ov.konto)
      if (!/^\d/.test(konto)) continue
      overview.push({
        konto,
        eb: numberOrNull(parseAmount(cell(row, ov.eb))),
        soll: numberOrNull(parseAmount(cell(row, ov.soll))),
        haben: numberOrNull(parseAmount(cell(row, ov.haben))),
      })
    } else if (mode === 'bookings' && bk) {
      const konto = cell(row, bk.konto)
      if (!/^\d/.test(konto)) continue
      const rawDate = cell(row, bk.datum)
      const datum = parseGermanDate(rawDate)
      if (!datum) problems.push({ line: lineNo, type: 'date', value: rawDate })
      const soll = parseAmount(cell(row, bk.soll))
      const haben = parseAmount(cell(row, bk.haben))
      if (Number.isNaN(soll) || Number.isNaN(haben)) {
        problems.push({ line: lineNo, type: 'amount', value: `${cell(row, bk.soll)} / ${cell(row, bk.haben)}` })
      } else if ((soll ?? 0) !== 0 && (haben ?? 0) !== 0) {
        problems.push({ line: lineNo, type: 'both_sides', value: `${cell(row, bk.soll)} / ${cell(row, bk.haben)}` })
      }
      rows.push({
        line: lineNo,
        konto,
        datum,
        bu: cell(row, bk.bu),
        gegenkonto: cell(row, bk.gegenkonto),
        gegenkonto_label: cell(row, bk.gegenkonto_label),
        text: cell(row, bk.text),
        beleg: cell(row, bk.beleg),
        soll: numberOrNull(soll),
        haben: numberOrNull(haben),
        kost1: cell(row, bk.kost1),
      })
    }
  }
  if (rows.length === 0) return { ok: false, error: 'no_bookings' }
  return { ok: true, file: { name, info, overview, rows }, problems }
}

function numberOrNull(value: number | null): number | null {
  return value === null || Number.isNaN(value) ? null : value
}
