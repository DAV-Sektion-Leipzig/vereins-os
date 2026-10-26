import { useState } from 'react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { euroCents } from '@/features/ds/budget/ui'
import { findPlanSheet, parsePlanSheet, type PlanSource } from '@/features/ds/budget/parse/plan'
import { DS_MESSAGES } from '@/features/ds/errors'
import type { PflegeData } from '@/features/ds/pflege/data'
import { FilePick, Note, useAction } from '@/features/ds/pflege/shared'
import { FormError } from '@/features/gr/shared/ui'
import { formatDateTime } from '@/lib/format'

type PlanPreview = {
  items: { kind: string; name: string; group: string; plan: number; row: number; status: 'new' | 'changed' | 'same' }[]
  removed: { kind: string; name: string; group: string }[]
  warnings: { type: string; name?: string; row?: number; group?: string; amount?: number }[]
  sums: { income: number; expense: number }
}

type YearPreview = { groups: number; rules: number; unmapped: { account?: string; account_text?: string; item?: string }[] }

const STATUS = { new: 'neu', changed: 'geändert', same: 'unverändert' } as const

const PARSE_ERRORS: Record<string, string> = {
  header_missing: 'Im Blatt fehlt die Kopfzeile mit „Einnahmen“ und „Ausgaben“.',
  plan_column_missing: 'Im Blatt fehlt je Seite die Spalte „Plan JJJJ“.',
  empty: 'Das Blatt enthält keine Budgetposten.',
  amount: 'Ein Planbetrag ist keine Zahl',
}

// US-FI-22, -29 (B1, R10): Excel im Browser lesen, Vorschau aus der Datenbank, übernehmen; neues Jahr aus dem Vorjahr.
export function FinanzplanTab({ data }: { data: PflegeData }) {
  const { year, plan } = data
  const [source, setSource] = useState<PlanSource | null>(null)
  const [preview, setPreview] = useState<PlanPreview | null>(null)
  const [reading, setReading] = useState(false)
  const [yearPreview, setYearPreview] = useState<YearPreview | null>(null)
  const action = useAction()

  async function read(file: File) {
    setSource(null)
    setPreview(null)
    action.setError(null)
    setReading(true)
    try {
      // Bibliothek erst bei Bedarf laden (eigener Chunk, plan.md P6)
      const { default: readXlsxFile } = await import('read-excel-file/browser')
      const sheets = await readXlsxFile(file)
      const sheet = findPlanSheet(sheets, year)
      if (!sheet) return action.setError(DS_MESSAGES.sheetMissing(year))
      const result = parsePlanSheet(file.name, sheet.sheet, sheet.data as unknown[][], year)
      if (!result.ok) return action.setError(PARSE_ERRORS[result.error] + (result.row ? ` (Zeile ${result.row}).` : ''))
      const res = await action.run<PlanPreview>('fi_budget_plan_preview', { p_year: year, p_source: result.source }, false)
      if (res) {
        setSource(result.source)
        setPreview(res.data)
      }
    } catch {
      action.setError('Die Datei ist keine lesbare Excel-Datei (.xlsx).')
    } finally {
      setReading(false)
    }
  }

  async function apply() {
    if (!source) return
    const res = await action.run<PlanPreview>('fi_budget_plan_import', { p_year: year, p_source: source })
    if (res) {
      toast.success(`Finanzplan ${year} übernommen: ${res.data.items.length} Budgetposten.`)
      setSource(null)
      setPreview(null)
    }
  }

  async function fromPrevious(apply: boolean) {
    const res = await action.run<YearPreview>('fi_budget_year_from_previous', { p_year: year, p_apply: apply }, apply)
    if (!res) return
    if (apply) {
      toast.success(`Aus ${year - 1} übernommen: ${res.data.groups} Gesamtbudgets angepasst, ${res.data.rules} Regeln.`)
      setYearPreview(null)
    } else {
      setYearPreview(res.data)
    }
  }

  return (
    <div className="flex flex-col gap-5">
      {plan ? (
        <p className="text-sm">
          Eingelesen: „{plan.source_file}“, Blatt „{plan.sheet}“, am {formatDateTime(plan.imported_at)} · Einnahmen{' '}
          {euroCents(plan.sum_income)} · Ausgaben {euroCents(plan.sum_expense)}
        </p>
      ) : (
        <p className="text-sm text-muted-foreground">{DS_MESSAGES.noPlan(year)}</p>
      )}
      <div className="flex flex-wrap items-center gap-3">
        <FilePick accept=".xlsx" label={plan ? 'Finanzplan neu einlesen' : 'Finanzplan einlesen'} onFile={read} disabled={reading || action.pending} />
        <span className="text-sm text-muted-foreground">Excel mit dem Blatt „Finanzplan {year}“. Die Datei wird nicht gespeichert.</span>
      </div>
      {reading && <p role="status" className="text-sm text-muted-foreground">Datei wird gelesen …</p>}
      <FormError text={action.error} />

      {preview && (
        <section aria-label="Vorschau Finanzplan" className="flex flex-col gap-3">
          <Note>
            Vorschau: {preview.items.length} Budgetposten · Einnahmen {euroCents(preview.sums.income)} · Ausgaben {euroCents(preview.sums.expense)}
            {preview.removed.length > 0 && ` · ${preview.removed.length} entfallen`}
          </Note>
          {preview.warnings.map((w, i) => (
            <Note key={i} tone="warn">
              {w.type === 'duplicate_name'
                ? `Doppelter Name „${w.name}“ (Zeile ${w.row}) gehört zum Gesamtbudget „${w.group}“ darüber.`
                : `Eine bestätigte Umschichtung (${euroCents(w.amount)}) betrifft einen entfallenen Posten.`}
            </Note>
          ))}
          <div className="max-h-[28rem] overflow-auto rounded-xl border">
            <Table>
              <TableHeader>
                <TableRow className="bg-muted hover:bg-muted">
                  <TableHead className="pl-4">Art</TableHead>
                  <TableHead>Gesamtbudget</TableHead>
                  <TableHead>Budgetposten</TableHead>
                  <TableHead className="text-right">Plan</TableHead>
                  <TableHead className="pr-4">Änderung</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {preview.items.map((it) => (
                  <TableRow key={`${it.kind}-${it.row}-${it.name}`}>
                    <TableCell className="pl-4">{it.kind === 'income' ? 'Einnahme' : 'Ausgabe'}</TableCell>
                    <TableCell>{it.group}</TableCell>
                    <TableCell>{it.name}</TableCell>
                    <TableCell className="text-right tabular-nums">{euroCents(it.plan)}</TableCell>
                    <TableCell className="pr-4">{STATUS[it.status]}</TableCell>
                  </TableRow>
                ))}
                {preview.removed.map((it) => (
                  <TableRow key={`removed-${it.kind}-${it.group}-${it.name}`} className="text-muted-foreground">
                    <TableCell className="pl-4">{it.kind === 'income' ? 'Einnahme' : 'Ausgabe'}</TableCell>
                    <TableCell>{it.group}</TableCell>
                    <TableCell>{it.name}</TableCell>
                    <TableCell className="text-right">–</TableCell>
                    <TableCell className="pr-4">entfällt</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
          <div className="flex gap-2">
            <Button onClick={apply} disabled={action.pending}>
              {action.pending ? 'Wird übernommen …' : 'Übernehmen'}
            </Button>
            <Button variant="outline" onClick={() => (setPreview(null), setSource(null))} disabled={action.pending}>
              Verwerfen
            </Button>
          </div>
        </section>
      )}

      {plan && data.years.includes(year - 1) && (
        <section aria-labelledby="prev-heading" className="flex flex-col gap-2 border-t pt-4">
          <h3 id="prev-heading" className="font-medium">
            Neues Jahr: aus {year - 1} übernehmen
          </h3>
          <p className="text-sm text-muted-foreground">
            Sichtbarkeit der Gesamtbudgets und Zuordnungsregeln (ohne Einzelbuchungsregeln) des Vorjahres. Danach anpassen.
          </p>
          {yearPreview ? (
            <div className="flex flex-col gap-2">
              <Note>
                {yearPreview.groups} Gesamtbudgets bekommen die Sichtbarkeit aus {year - 1}, {yearPreview.rules} Regeln werden übernommen
                {yearPreview.unmapped.length > 0 && `, ${yearPreview.unmapped.length} Regeln ohne passenden Posten`}.
              </Note>
              <div className="flex gap-2">
                <Button onClick={() => fromPrevious(true)} disabled={action.pending}>
                  Übernehmen
                </Button>
                <Button variant="outline" onClick={() => setYearPreview(null)}>
                  Verwerfen
                </Button>
              </div>
            </div>
          ) : (
            <Button variant="outline" className="self-start" onClick={() => fromPrevious(false)} disabled={action.pending}>
              Vorschau
            </Button>
          )}
        </section>
      )}
    </div>
  )
}
