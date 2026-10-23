import { CircleAlertIcon, DownloadIcon, RotateCwIcon } from 'lucide-react'
import { Link, useLoaderData, useRevalidator, useSearchParams } from 'react-router-dom'
import { ResponsiveTable, type Column } from '@/components/ResponsiveTable'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { downloadCsv } from '@/features/ea/ablauf/csv'
import type { ExpiryListResult, ExpiryListRow } from '@/features/ea/ablauf/data'
import { AblaufBadge } from '@/features/ea/shared/AblaufBadge'
import { MESSAGES } from '@/lib/errors'
import { formatDate, personName } from '@/lib/format'

const selectClassName =
  'h-8 w-full rounded-lg border border-input bg-background px-2.5 text-base outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 sm:w-auto sm:text-sm'

const name = (r: ExpiryListRow) => personName({ first_name: r.firstName, preferred_name: r.preferredName, last_name: r.lastName })
const qualification = (r: ExpiryListRow) => (r.code ? `${r.code} – ${r.qualificationName}` : r.qualificationName)

// T047, T048 (US-EA-12): Stichtagsliste je Jahr mit CSV-Export (nur verwalten, R11).
export function AblaufPage() {
  const { year, years, rows, canExport, failed } = useLoaderData() as ExpiryListResult
  const [, setSearchParams] = useSearchParams()
  const revalidator = useRevalidator()

  return (
    <section className="flex flex-col gap-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-xl font-semibold">Ablauf</h1>
        {canExport && rows.length > 0 && (
          <Button variant="outline" onClick={() => downloadCsv(rows, year)}>
            <DownloadIcon data-icon="inline-start" aria-hidden="true" />
            CSV exportieren
          </Button>
        )}
      </div>

      <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:gap-3">
        <Label htmlFor="ea-ablauf-jahr">Ablauf im Jahr</Label>
        <select
          id="ea-ablauf-jahr"
          value={year}
          onChange={(e) => setSearchParams({ jahr: e.target.value }, { replace: true })}
          className={selectClassName}
        >
          {years.map((y) => (
            <option key={y} value={y}>
              {y}
            </option>
          ))}
        </select>
      </div>

      {failed ? (
        <div className="flex flex-col items-start gap-3">
          <p role="alert" className="flex items-center gap-2 text-sm text-destructive">
            <CircleAlertIcon aria-hidden="true" className="size-4 shrink-0" />
            {MESSAGES.unexpected}
          </p>
          <Button variant="outline" onClick={() => revalidator.revalidate()} disabled={revalidator.state === 'loading'}>
            <RotateCwIcon data-icon="inline-start" aria-hidden="true" />
            {revalidator.state === 'loading' ? 'Wird geladen …' : 'Erneut laden'}
          </Button>
        </div>
      ) : (
        <ResponsiveTable
          rows={rows}
          rowKey={(r) => r.propertyId}
          columns={COLUMNS}
          card={(r) => <ExpiryCard row={r} />}
          empty={`Im Jahr ${year} läuft keine Qualifikation ab.`}
          caption={`Ablauf im Jahr ${year}`}
        />
      )}
    </section>
  )
}

function NameLink({ row }: { row: ExpiryListRow }) {
  return (
    <Link to={`/ea/aktive/${row.personId}`} className="font-medium underline-offset-4 hover:underline">
      {name(row)}
    </Link>
  )
}

const COLUMNS: Column<ExpiryListRow>[] = [
  { key: 'name', header: 'Name', cell: (r) => <NameLink row={r} />, className: 'whitespace-normal' },
  {
    key: 'referate',
    header: 'Referate',
    cell: (r) => (r.referate.length ? r.referate.join(', ') : <span className="text-muted-foreground">–</span>),
    className: 'whitespace-normal',
  },
  { key: 'qualification', header: 'Qualifikationsart', cell: qualification, className: 'whitespace-normal' },
  { key: 'until', header: 'gültig bis', cell: (r) => formatDate(r.validUntil) },
  { key: 'status', header: 'Ablauf', cell: (r) => <AblaufBadge status={r.status} /> },
]

function ExpiryCard({ row }: { row: ExpiryListRow }) {
  return (
    <div className="flex flex-col gap-1">
      <NameLink row={row} />
      <span className="text-sm">{qualification(row)}</span>
      {row.referate.length > 0 && <span className="text-sm text-muted-foreground">Referate: {row.referate.join(', ')}</span>}
      <div className="flex flex-wrap items-center gap-2 text-sm">
        <span>gültig bis {formatDate(row.validUntil)}</span>
        <AblaufBadge status={row.status} />
      </div>
    </div>
  )
}
