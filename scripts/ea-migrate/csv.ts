// CSV der Aktivenliste lesen und in die Form für ea_import_volunteers bringen (contracts/migration-script.md; T023).
import { parse } from 'csv-parse/sync'
import { ACCESS_COLUMNS, BOOLEAN_COLUMNS, DATE_COLUMNS, REQUIRED_COLUMNS, YEAR_COLUMN } from './columns.ts'

export type Finding = { row: number; message: string }

export type ImportRow = Record<string, unknown> & { row: number }

export type ParseResult = { rows: ImportRow[]; formatErrors: Finding[] }

export class MissingColumnError extends Error {
  constructor(readonly column: string) {
    super(`Spalte ${column} fehlt.`)
  }
}

/** TT.MM.JJJJ (auch T.M.JJJJ) → JJJJ-MM-TT; null, wenn kein gültiges Datum. */
export function toIsoDate(value: string): string | null {
  const m = /^(\d{1,2})\.(\d{1,2})\.(\d{4})$/.exec(value.trim())
  if (!m) return null
  const [day, month, year] = [Number(m[1]), Number(m[2]), Number(m[3])]
  const date = new Date(Date.UTC(year, month - 1, day))
  if (date.getUTCFullYear() !== year || date.getUTCMonth() !== month - 1 || date.getUTCDate() !== day) return null
  return `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`
}

/** ja/nein (ohne Groß-/Kleinschreibung) → boolean; null bei anderem Wert. */
export function toBoolean(value: string): boolean | null {
  const v = value.trim().toLowerCase()
  if (v === 'ja') return true
  if (v === 'nein') return false
  return null
}

function toNumber(value: string): number | null {
  const n = Number(value.trim().replace(',', '.'))
  return Number.isFinite(n) ? n : null
}

/** Liste „Kürzel:Datum:gültig bis:Angabe“, Einträge getrennt durch „,“ (C3). */
function parseQualifications(value: string, row: number, errors: Finding[]) {
  return value
    .split(',')
    .map((entry) => entry.trim())
    .filter(Boolean)
    .map((entry) => {
      const [code = '', date = '', validUntil = '', ...detail] = entry.split(':').map((s) => s.trim())
      const item: Record<string, string> = { code }
      for (const [key, raw] of [['date', date], ['valid_until', validUntil]] as const) {
        if (!raw) continue
        const iso = toIsoDate(raw)
        if (iso) item[key] = iso
        else errors.push({ row, message: `Zeile ${row}: qualifikationen nicht lesbar` })
      }
      if (detail.join(':')) item.detail = detail.join(':')
      return item
    })
}

/** Liest die CSV (UTF-8, Semikolon, Kopfzeile Pflicht). Fehlt eine Pflichtspalte: MissingColumnError. */
export function parseCsv(content: string): ParseResult {
  const records = parse(content, {
    delimiter: ';',
    bom: true,
    skip_empty_lines: true,
    relax_column_count: true,
    trim: true,
  }) as string[][]
  const [header = [], ...lines] = records
  const columns = header.map((c) => c.trim().toLowerCase())
  for (const required of REQUIRED_COLUMNS) {
    if (!columns.includes(required)) throw new MissingColumnError(required)
  }

  const formatErrors: Finding[] = []
  const rows = lines.map((cells, index) => {
    const row = index + 2 // Kopfzeile = Zeile 1
    const out: ImportRow = { row }
    const unreadable = (column: string) => formatErrors.push({ row, message: `Zeile ${row}: ${column} nicht lesbar` })

    columns.forEach((column, i) => {
      const value = (cells[i] ?? '').trim()
      if (!value) return // leere Zellen fehlen im Objekt

      const year = YEAR_COLUMN.exec(column)
      if (year) {
        const [, kind, rawYear] = year
        const key = rawYear === 'vor_2016' ? '2015' : rawYear
        const bucket = ((out[kind] as Record<string, unknown> | undefined) ??= {})
        if (kind === 'fb') bucket[key] = rawYear === 'vor_2016' ? `${value} (vor 2016)` : value
        else if (kind === 'foerderung') {
          const b = toBoolean(value)
          if (b === null) unreadable(column)
          else bucket[key] = b
        } else {
          const iso = toIsoDate(value)
          if (iso) bucket[key] = iso
          else unreadable(column)
        }
        return
      }

      if (DATE_COLUMNS.has(column)) {
        const iso = toIsoDate(value)
        if (iso) out[column] = iso
        else unreadable(column)
      } else if (BOOLEAN_COLUMNS.has(column)) {
        const b = toBoolean(value)
        if (b === null) unreadable(column)
        else out[column] = b
      } else if (ACCESS_COLUMNS.has(column)) {
        if (value.toLowerCase() === 'x') out[column] = 'x'
        else {
          const iso = toIsoDate(value)
          if (iso) out[column] = iso
          else unreadable(column)
        }
      } else if (column === 'te_pro_woche') {
        const n = toNumber(value)
        if (n === null) unreadable(column)
        else out[column] = n
      } else if (column === 'referate') {
        out.referate = value.split(',').map((r) => r.trim()).filter(Boolean)
      } else if (column === 'qualifikationen') {
        out.qualifikationen = parseQualifications(value, row, formatErrors)
      } else {
        out[column] = value
      }
    })
    return out
  })

  return { rows, formatErrors }
}
