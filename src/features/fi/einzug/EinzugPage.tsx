import { useState } from 'react'
import { FileDownIcon, PlusIcon } from 'lucide-react'
import { Link, useLoaderData, useNavigate } from 'react-router-dom'
import { ResponsiveTable, type Column } from '@/components/ResponsiveTable'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { ConfirmDialog } from '@/features/ez/shared/ConfirmDialog'
import { runTitle, type CollectionRunRow, type RunsResult } from '@/features/fi/einzug/data'
import { FI_MESSAGES } from '@/features/fi/errors'
import { downloadCollectionFiles, reportCollectionDownload } from '@/features/fi/export/collection'
import { formatMoney } from '@/features/fi/labels'
import { fiRpc } from '@/features/fi/rpc'
import { FormDialog } from '@/features/fi/shared/FormDialog'
import { LoadFailed } from '@/features/gr/shared/ui'
import { formatDate, formatDateTime, todayIso } from '@/lib/format'

const STATUS_LABELS = { draft: 'Entwurf', released: 'freigegeben' } as const

// FT23 (US-FI-18, -21): Buchungsläufe Verträge mit „Neuer Buchungslauf“; freigegebene Läufe erneut abrufen (Warnung).
export function EinzugPage() {
  const { runs, collectionStart, failed } = useLoaderData() as RunsResult
  const navigate = useNavigate()
  const [creating, setCreating] = useState(false)
  const [refetch, setRefetch] = useState<CollectionRunRow | null>(null)
  const [pending, setPending] = useState(false)
  const [error, setError] = useState<string | null>(null)

  async function create(month: string) {
    setPending(true)
    setError(null)
    const res = await fiRpc<string>('fi_create_collection_run', { p_month: `${month}-01` })
    setPending(false)
    if (res.error) return setError(res.error.text)
    navigate(`/fi/einzug/${res.data}`)
  }

  async function download(run: CollectionRunRow) {
    setPending(true)
    const result = await downloadCollectionFiles(run.id)
    setPending(false)
    if (result.error) return setError(result.error)
    setRefetch(null)
    reportCollectionDownload(result.bankChanged)
  }

  const count = (r: CollectionRunRow) => (r.status === 'released' ? (r.line_count ?? 0) : r.included_count)
  const total = (r: CollectionRunRow) => (r.status === 'released' ? r.total : r.included_total)

  const columns: Column<CollectionRunRow>[] = [
    {
      key: 'run',
      header: 'Buchungslauf',
      cell: (r) => (
        <Link to={`/fi/einzug/${r.id}`} className="font-medium underline-offset-4 hover:underline">
          {runTitle(r)}
        </Link>
      ),
    },
    { key: 'due', header: 'Fälligkeit', cell: (r) => formatDate(r.due_date), className: 'tabular-nums' },
    { key: 'status', header: 'Zustand', cell: (r) => <Badge variant={r.status === 'released' ? 'default' : 'outline'}>{STATUS_LABELS[r.status]}</Badge> },
    { key: 'count', header: 'Lastschriften', cell: (r) => count(r), className: 'tabular-nums' },
    { key: 'total', header: 'Summe', cell: (r) => formatMoney(total(r)), className: 'text-right tabular-nums', headerClassName: 'text-right' },
    {
      key: 'released',
      header: 'Freigegeben',
      cell: (r) => (r.released_at ? `${formatDateTime(r.released_at)}${r.released_by_name ? ` von ${r.released_by_name}` : ''}` : '–'),
      className: 'text-sm',
    },
    {
      key: 'files',
      header: <span className="sr-only">Dateien</span>,
      cell: (r) =>
        r.status === 'released' && (
          <Button variant="outline" size="sm" onClick={() => setRefetch(r)}>
            <FileDownIcon data-icon="inline-start" aria-hidden="true" />
            PDF und XML
          </Button>
        ),
    },
  ]

  return (
    <section className="flex flex-col gap-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-xl font-semibold">Buchungsläufe Verträge</h1>
        <Button onClick={() => setCreating(true)} disabled={!collectionStart}>
          <PlusIcon data-icon="inline-start" aria-hidden="true" />
          Neuer Buchungslauf
        </Button>
      </div>
      {!collectionStart && (
        <p className="rounded-lg border bg-muted/50 p-3 text-sm">
          Der Stichtag des ersten Buchungslaufs ist noch nicht festgelegt. Bitte den Admin informieren (Administration →
          Auszahlung).
        </p>
      )}
      {failed ? (
        <LoadFailed />
      ) : (
        <ResponsiveTable
          rows={runs}
          rowKey={(r) => r.id}
          columns={columns}
          card={(r) => (
            <div className="flex flex-col gap-2">
              <div className="flex items-start justify-between gap-3">
                <Link to={`/fi/einzug/${r.id}`} className="font-medium underline-offset-4 hover:underline">
                  {runTitle(r)}
                </Link>
                <Badge variant={r.status === 'released' ? 'default' : 'outline'}>{STATUS_LABELS[r.status]}</Badge>
              </div>
              <span className="text-sm text-muted-foreground">
                Fälligkeit {formatDate(r.due_date)} · {count(r)} Lastschriften · {formatMoney(total(r))}
              </span>
              {r.status === 'released' && (
                <Button variant="outline" size="sm" className="self-start" onClick={() => setRefetch(r)}>
                  <FileDownIcon data-icon="inline-start" aria-hidden="true" />
                  PDF und XML
                </Button>
              )}
            </div>
          )}
          empty="Noch keine Buchungsläufe."
          caption="Buchungsläufe Verträge"
        />
      )}

      {creating && (
        <NewRunDialog
          start={collectionStart}
          pending={pending}
          error={error}
          onClose={() => {
            setCreating(false)
            setError(null)
          }}
          onCreate={create}
        />
      )}
      {refetch && (
        <ConfirmDialog
          title="Dateien erneut abrufen?"
          confirmLabel="Herunterladen"
          pendingLabel="Wird erzeugt …"
          pending={pending}
          error={error}
          onConfirm={() => download(refetch)}
          onClose={() => {
            setRefetch(null)
            setError(null)
          }}
        >
          {FI_MESSAGES.collectionReleased}
        </ConfirmDialog>
      )}
    </section>
  )
}

/** Monat: Standard nächster Monat (frühestens der Stichtag); Fälligkeit schlägt die Datenbank vor (heute + 3 Tage). */
function NewRunDialog({
  start,
  pending,
  error,
  onClose,
  onCreate,
}: {
  start: string | null
  pending: boolean
  error: string | null
  onClose: () => void
  onCreate: (month: string) => void
}) {
  const [y, m] = todayIso().split('-').map(Number)
  const next = m === 12 ? `${y + 1}-01` : `${y}-${String(m + 1).padStart(2, '0')}`
  const min = [todayIso().slice(0, 7), start?.slice(0, 7) ?? ''].sort().at(-1) ?? next
  const [month, setMonth] = useState(next < min ? min : next)
  return (
    <FormDialog
      title="Neuer Buchungslauf"
      description="Alle Verträge, die am 1. des Monats laufen und für diesen Monat noch nicht eingezogen sind, werden übernommen. Der Fälligkeitstag ist mit heute + 3 Tagen vorbelegt und danach änderbar."
      submitLabel="Erstellen"
      pendingLabel="Wird erstellt …"
      pending={pending}
      error={error}
      onClose={onClose}
      onSubmit={() => onCreate(month)}
    >
      <div className="flex flex-col gap-2">
        <Label htmlFor="fi-collection-month">Monat</Label>
        <Input id="fi-collection-month" type="month" value={month} min={min} onChange={(e) => setMonth(e.target.value)} className="sm:w-48" />
      </div>
    </FormDialog>
  )
}
