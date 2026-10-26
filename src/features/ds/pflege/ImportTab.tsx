import { useState } from 'react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { parseDatev, type DatevFile, type DatevProblem } from '@/features/ds/budget/parse/datev'
import { euro, euroCents } from '@/features/ds/budget/ui'
import { DS_MESSAGES } from '@/features/ds/errors'
import type { PflegeData } from '@/features/ds/pflege/data'
import { FilePick, Note, useAction } from '@/features/ds/pflege/shared'
import { FormError } from '@/features/gr/shared/ui'
import { formatDate, formatDateTime } from '@/lib/format'

type ImportResult = {
  rows_read: number
  rows_saved: number
  rows_ignored: number
  rows_opening: number
  rows_other_year: number
  data_until: string | null
  warnings: { type: string; konto?: string; overview?: number; rows?: number; date?: string; amount?: number; side?: string }[]
  import_id: string | null
  proposals_obsolete?: number
}

const PROBLEMS: Record<DatevProblem['type'], string> = {
  date: 'Datum nicht lesbar',
  amount: 'Betrag nicht lesbar',
  both_sides: 'Soll und Haben gleichzeitig',
}

// US-FI-26 (R1, R4, R8, R9): DATEV-Kontenblätter im Browser lesen, Vorschau mit Prüfung, übernehmen; Liste der Importe;
// Auszahlungsrunden als gebucht markieren (R18).
export function ImportTab({ data }: { data: PflegeData }) {
  const { year, plan, imports, runs } = data
  const [file, setFile] = useState<DatevFile | null>(null)
  const [problems, setProblems] = useState<DatevProblem[]>([])
  const [preview, setPreview] = useState<ImportResult | null>(null)
  const action = useAction()

  async function read(f: File) {
    setFile(null)
    setPreview(null)
    action.setError(null)
    const parsed = parseDatev(f.name, await f.arrayBuffer())
    if (!parsed.ok) {
      return action.setError(
        parsed.error === 'no_bookings'
          ? 'In der Datei wurde keine Buchungsliste gefunden (Spalten Konto, Datum, Buchungstext, Umsatz Soll, Umsatz Haben).'
          : `In der Buchungsliste fehlen Spalten: ${(parsed.missing ?? []).join(', ')}.`,
      )
    }
    const res = await action.run<ImportResult>('fi_budget_import_preview', { p_year: year, p_file: parsed.file }, false)
    if (res) {
      setFile(parsed.file)
      setProblems(parsed.problems)
      setPreview(res.data)
    }
  }

  async function apply() {
    if (!file) return
    const res = await action.run<ImportResult>('fi_budget_import', { p_year: year, p_file: file })
    if (res) {
      toast.success(
        `DATEV-Export übernommen: ${res.data.rows_saved} Buchungen` +
          (res.data.proposals_obsolete ? `, ${res.data.proposals_obsolete} Vorschläge gegenstandslos` : '') +
          '.',
      )
      setFile(null)
      setPreview(null)
    }
  }

  if (!plan) return <p className="text-sm text-muted-foreground">{DS_MESSAGES.noPlan(year)}</p>

  return (
    <div className="flex flex-col gap-5">
      <div className="flex flex-wrap items-center gap-3">
        <FilePick accept=".csv,text/csv" label="DATEV-Export einlesen" onFile={read} disabled={action.pending} />
        <span className="text-sm text-muted-foreground">
          Kontenblätter aller Konten als CSV. Gespeichert werden nur Buchungen auf Konten mit Regel; die Datei selbst nicht.
        </span>
      </div>
      <FormError text={action.error} />

      {preview && file && (
        <section aria-label="Vorschau Import" className="flex flex-col gap-2">
          <Note>
            {preview.rows_read} Zeilen gelesen · {preview.rows_saved} werden ausgewertet · {preview.rows_ignored} ohne Regel (ignoriert) ·{' '}
            {preview.rows_opening} Saldovorträge · {preview.rows_other_year} aus anderen Jahren · Datenstand{' '}
            {preview.data_until ? formatDate(preview.data_until) : '–'}
          </Note>
          {problems.length > 0 && (
            <Note tone="warn">
              {problems.length} Zeile{problems.length === 1 ? '' : 'n'} mit Auffälligkeiten:{' '}
              {problems
                .slice(0, 5)
                .map((p) => `Zeile ${p.line} ${PROBLEMS[p.type]} („${p.value}“)`)
                .join('; ')}
              {problems.length > 5 ? ' …' : ''}
            </Note>
          )}
          {preview.warnings.map((w, i) => (
            <Note key={i} tone="warn">
              {w.type === 'incomplete'
                ? `Export unvollständig: Konto ${w.konto} – Kontenübersicht ${euroCents(w.overview)}, Einzelbuchungen ${euroCents(w.rows)}`
                : `Umgeschlüsselte Buchung nicht mehr im Export: ${w.konto} · ${w.date ? formatDate(w.date) : '–'} · ${euroCents(w.amount)} ${w.side ?? ''}`}
            </Note>
          ))}
          {preview.warnings.length === 0 && <Note tone="ok">Summe je Konto stimmt mit der Kontenübersicht überein.</Note>}
          <div className="flex gap-2">
            <Button onClick={apply} disabled={action.pending}>
              {action.pending ? 'Wird übernommen …' : 'Übernehmen'}
            </Button>
            <Button variant="outline" onClick={() => (setPreview(null), setFile(null))} disabled={action.pending}>
              Verwerfen
            </Button>
          </div>
          <p className="text-xs text-muted-foreground">Übernehmen ersetzt die Buchungen des bisherigen Imports für {year}.</p>
        </section>
      )}

      <section aria-labelledby="imports-heading" className="flex flex-col gap-2">
        <h3 id="imports-heading" className="font-medium">
          Importe {year}
        </h3>
        {imports.length === 0 ? (
          <p className="text-sm text-muted-foreground">{DS_MESSAGES.noImport(year)}</p>
        ) : (
          <div className="overflow-x-auto rounded-xl border">
            <Table>
              <TableHeader>
                <TableRow className="bg-muted hover:bg-muted">
                  <TableHead className="pl-4">eingespielt</TableHead>
                  <TableHead>Datei</TableHead>
                  <TableHead>Datenstand</TableHead>
                  <TableHead className="text-right">Zeilen</TableHead>
                  <TableHead className="text-right">ausgewertet</TableHead>
                  <TableHead className="pr-4">Warnungen</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {imports.map((im) => (
                  <TableRow key={im.id} className={im.is_current ? '' : 'text-muted-foreground'}>
                    <TableCell className="pl-4">
                      {formatDateTime(im.imported_at)}
                      {im.is_current && <span className="ml-2 text-xs font-medium text-primary">aktuell</span>}
                    </TableCell>
                    <TableCell>{im.file_name}</TableCell>
                    <TableCell>{im.data_until ? formatDate(im.data_until) : '–'}</TableCell>
                    <TableCell className="text-right tabular-nums">{im.rows_read}</TableCell>
                    <TableCell className="text-right tabular-nums">{im.rows_saved}</TableCell>
                    <TableCell className="pr-4">{im.warnings.length || '–'}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </section>

      <section aria-labelledby="runs-heading" className="flex flex-col gap-2">
        <h3 id="runs-heading" className="font-medium">
          Auszahlungsrunden {year}
        </h3>
        <p className="text-sm text-muted-foreground">
          Freigegebene Runden gelten als gebucht, wenn im Import eine passende Buchung auf „Vergütung Aktive“ steht (Betrag, Datum −3 bis +14
          Tage). Sonst erscheinen sie als Vorschau. Findet der Abgleich die Buchung nicht, hier von Hand markieren.
        </p>
        {runs.length === 0 ? (
          <p className="text-sm text-muted-foreground">Keine freigegebenen Auszahlungsrunden.</p>
        ) : (
          <ul className="flex flex-col divide-y rounded-xl border text-sm">
            {runs.map((r) => (
              <RunRow key={r.run_id} run={r} />
            ))}
          </ul>
        )}
      </section>
    </div>
  )
}

function RunRow({ run }: { run: PflegeData['runs'][number] }) {
  const action = useAction()
  const auto = run.booked && !run.marked
  return (
    <li className="flex flex-wrap items-center gap-x-3 gap-y-1 px-3 py-2">
      <span className="font-medium">
        Runde {run.half}/{run.number}
      </span>
      <span>
        ausgeführt {formatDate(run.execution_date)} · {euro(run.total)}
      </span>
      <span className="flex-1 text-muted-foreground">{run.marked ? 'von Hand als gebucht markiert' : auto ? 'gebucht (Abgleich)' : 'noch nicht gebucht (Vorschau)'}</span>
      {!auto && (
        <Button
          size="sm"
          variant="outline"
          disabled={action.pending}
          onClick={async () => {
            const res = await action.run('fi_budget_payout_mark', { p_run: run.run_id, p_booked: !run.marked })
            if (res) toast.success(run.marked ? 'Markierung entfernt.' : 'Als gebucht markiert.')
          }}
        >
          {run.marked ? 'Markierung entfernen' : 'Als gebucht markieren'}
        </Button>
      )}
      <FormError text={action.error} />
    </li>
  )
}
