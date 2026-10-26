// Finanzplan aus der Excel lesen (US-FI-22, B1; prototyp-budget-dashboard.md Abschnitt 2): Blatt „Finanzplan JJJJ“,
// Kopfzeile mit „Einnahmen“ und „Ausgaben“, je Seite eine Spalte „Plan JJJJ“; flache Liste der Budgetposten; Zeilen
// „Summe…“ sind Kontrollsummen (R10 prüft die Datenbank). Arbeitet auf den Zellen eines Blattes, damit es ohne
// Excel-Bibliothek testbar ist.
import { headerKey, parseAmount } from './csv.ts'

export type PlanItem = { kind: 'income' | 'expense'; name: string; plan: number; row: number }

export type PlanSource = {
  file: string
  sheet: string
  items: PlanItem[]
  sums: { income: number | null; expense: number | null }
}

export type PlanResult =
  | { ok: true; source: PlanSource }
  | { ok: false; error: 'sheet_missing' | 'header_missing' | 'plan_column_missing' | 'empty' | 'amount'; row?: number }

type Cell = unknown

export function planSheetName(year: number): string {
  return `Finanzplan ${year}`
}

/** Blatt „Finanzplan JJJJ“ (Groß/klein und Leerraum egal) aus der Liste der Blätter. */
export function findPlanSheet<T extends { sheet: string }>(sheets: T[], year: number): T | undefined {
  const wanted = headerKey(planSheetName(year))
  return sheets.find((s) => headerKey(s.sheet) === wanted)
}

function text(value: Cell): string {
  if (value === null || value === undefined) return ''
  return String(value).trim()
}

export function parsePlanSheet(file: string, sheet: string, data: Cell[][], year: number): PlanResult {
  // Kopfzeile: erste Zeile mit „Einnahmen“ und „Ausgaben“
  const headerIndex = data.findIndex((row) => {
    const keys = row.map(headerKey)
    return keys.some((k) => k.startsWith('einnahmen')) && keys.some((k) => k.startsWith('ausgaben'))
  })
  if (headerIndex < 0) return { ok: false, error: 'header_missing' }
  const header = data[headerIndex].map(headerKey)
  const planKey = headerKey(`Plan ${year}`)
  const sides: { kind: 'income' | 'expense'; nameCol: number; planCol: number }[] = []
  for (const [kind, prefix] of [['income', 'einnahmen'], ['expense', 'ausgaben']] as const) {
    const nameCol = header.findIndex((k) => k.startsWith(prefix))
    const planCol = header.findIndex((k, i) => i > nameCol && k === planKey)
    if (planCol < 0) return { ok: false, error: 'plan_column_missing' }
    sides.push({ kind, nameCol, planCol })
  }
  // Spalte „Plan JJJJ“ der Einnahmen darf nicht hinter der Namensspalte der Ausgaben liegen
  const income = sides[0]
  const expense = sides[1]
  if (income.nameCol < expense.nameCol && income.planCol > expense.nameCol) {
    return { ok: false, error: 'plan_column_missing' }
  }

  const items: PlanItem[] = []
  const sums: PlanSource['sums'] = { income: null, expense: null }
  for (let r = headerIndex + 1; r < data.length; r++) {
    const row = data[r] ?? []
    for (const side of sides) {
      const name = text(row[side.nameCol])
      const raw = row[side.planCol]
      if (name === '') continue
      const amount = parseAmount(raw)
      if (/^summe/i.test(name)) {
        if (amount !== null && !Number.isNaN(amount)) sums[side.kind] = amount
        continue
      }
      if (amount === null) continue
      if (Number.isNaN(amount)) return { ok: false, error: 'amount', row: r + 1 }
      items.push({ kind: side.kind, name, plan: Math.round(amount * 100) / 100, row: r + 1 })
    }
  }
  if (items.length === 0) return { ok: false, error: 'empty' }
  items.sort((a, b) => (a.kind === b.kind ? a.row - b.row : a.kind === 'income' ? -1 : 1))
  return { ok: true, source: { file, sheet, items, sums } }
}
