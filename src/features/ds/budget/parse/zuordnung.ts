// zuordnung.csv des Prototyps lesen (US-FI-25, B8). Spalten: Konto; Kontobezeichnung; Art; Gesamtbudget; Budgetposten;
// Kostenstelle; Status; Hinweis; Datum; Beleg; Betrag; Buchungstext. Die Prüfung macht fi_budget_rules_import_csv.
import { decodeText, headerKey, parseCsv } from './csv.ts'

export type ZuordnungRow = {
  line: number
  konto: string
  kontobezeichnung: string
  art: string
  gesamtbudget: string
  budgetposten: string
  kostenstelle: string
  status: string
  hinweis: string
  datum: string
  beleg: string
  betrag: string
  buchungstext: string
}

export type ZuordnungResult = { ok: true; rows: ZuordnungRow[] } | { ok: false; error: 'header_missing' }

const FIELDS = ['konto', 'kontobezeichnung', 'art', 'gesamtbudget', 'budgetposten', 'kostenstelle', 'status',
  'hinweis', 'datum', 'beleg', 'betrag', 'buchungstext'] as const

export function parseZuordnung(bytes: ArrayBuffer | Uint8Array): ZuordnungResult {
  return parseZuordnungText(decodeText(bytes))
}

export function parseZuordnungText(text: string): ZuordnungResult {
  const lines = parseCsv(text)
  const headerIndex = lines.findIndex((row) => {
    const keys = row.map(headerKey)
    return keys.includes('konto') && keys.includes('budgetposten')
  })
  if (headerIndex < 0) return { ok: false, error: 'header_missing' }
  const keys = lines[headerIndex].map(headerKey)
  const col = Object.fromEntries(FIELDS.map((f) => [f, keys.indexOf(f)])) as Record<(typeof FIELDS)[number], number>
  const rows: ZuordnungRow[] = []
  for (let i = headerIndex + 1; i < lines.length; i++) {
    const row = lines[i]
    if (row.every((c) => c.trim() === '')) continue
    const entry = { line: i + 1 } as ZuordnungRow
    for (const f of FIELDS) entry[f] = col[f] >= 0 ? (row[col[f]] ?? '').trim() : ''
    rows.push(entry)
  }
  return { ok: true, rows }
}
