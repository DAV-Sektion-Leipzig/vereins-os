import { useState } from 'react'
import { FileDownIcon, PlusIcon } from 'lucide-react'
import { Link, useLoaderData, useNavigate } from 'react-router-dom'
import { ResponsiveTable, type Column } from '@/components/ResponsiveTable'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { ConfirmDialog } from '@/features/ez/shared/ConfirmDialog'
import type { RunRow, RunsResult } from '@/features/fi/auszahlungen/data'
import { FI_MESSAGES } from '@/features/fi/errors'
import { downloadPayoutFiles, reportDownload } from '@/features/fi/export/payout'
import { currentHalf, formatMoney, halfKey, halfLabel, halfOptions, nextWorkday, parseHalf, RUN_STATUS_LABELS } from '@/features/fi/labels'
import { fiRpc } from '@/features/fi/rpc'
import { FormDialog } from '@/features/fi/shared/FormDialog'
import { LoadFailed, selectClassName } from '@/features/gr/shared/ui'
import { formatDate, formatDateTime, todayIso } from '@/lib/format'

// FT14 (US-FI-14, -16): Auszahlungsrunden mit „Neue Runde“; freigegebene Runden erneut abrufen (Warnung R29).
export function AuszahlungenPage() {
  const { runs, failed } = useLoaderData() as RunsResult
  const navigate = useNavigate()
  const [creating, setCreating] = useState(false)
  const [refetch, setRefetch] = useState<RunRow | null>(null)
  const [pending, setPending] = useState(false)
  const [error, setError] = useState<string | null>(null)

  async function create(half: string, date: string) {
    const h = parseHalf(half)
    if (!h) return
    setPending(true)
    setError(null)
    const res = await fiRpc<string>('fi_create_payout_run', { p_year: h.year, p_half: h.half, p_execution_date: date })
    setPending(false)
    if (res.error) return setError(res.error.text)
    navigate(`/fi/auszahlungen/${res.data}`)
  }

  async function download(run: RunRow) {
    setPending(true)
    const result = await downloadPayoutFiles(run.id)
    setPending(false)
    if (result.error) return setError(result.error)
    setRefetch(null)
    reportDownload(result.bankChanged)
  }

  const columns: Column<RunRow>[] = [
    {
      key: 'run',
      header: 'Runde',
      cell: (r) => (
        <Link to={`/fi/auszahlungen/${r.id}`} className="font-medium underline-offset-4 hover:underline">
          {halfLabel(r)} – Runde {r.number}
        </Link>
      ),
    },
    { key: 'date', header: 'Ausführungsdatum', cell: (r) => formatDate(r.execution_date) },
    { key: 'status', header: 'Zustand', cell: (r) => <Badge variant={r.status === 'released' ? 'default' : 'outline'}>{RUN_STATUS_LABELS[r.status]}</Badge> },
    { key: 'count', header: 'Anzahl', cell: (r) => (r.status === 'released' ? `${r.line_count} Überweisungen` : `${r.settlement_count} Abrechnungen`), className: 'tabular-nums' },
    { key: 'total', header: 'Summe', cell: (r) => (r.total !== null ? formatMoney(r.total) : '–'), className: 'text-right tabular-nums', headerClassName: 'text-right' },
    { key: 'released', header: 'Freigegeben', cell: (r) => (r.released_at ? `${formatDateTime(r.released_at)} von ${r.released_by_name ?? 'unbekannt'}` : '–'), className: 'text-sm' },
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
        <h1 className="text-xl font-semibold">Auszahlungsrunden</h1>
        <Button onClick={() => setCreating(true)}>
          <PlusIcon data-icon="inline-start" aria-hidden="true" />
          Neue Runde
        </Button>
      </div>
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
                <Link to={`/fi/auszahlungen/${r.id}`} className="font-medium underline-offset-4 hover:underline">
                  {halfLabel(r)} – Runde {r.number}
                </Link>
                <Badge variant={r.status === 'released' ? 'default' : 'outline'}>{RUN_STATUS_LABELS[r.status]}</Badge>
              </div>
              <span className="text-sm text-muted-foreground">
                Ausführung {formatDate(r.execution_date)}
                {r.total !== null ? ` · ${r.line_count} Überweisungen · ${formatMoney(r.total)}` : ` · ${r.settlement_count} Abrechnungen`}
              </span>
              {r.status === 'released' && (
                <Button variant="outline" size="sm" className="self-start" onClick={() => setRefetch(r)}>
                  <FileDownIcon data-icon="inline-start" aria-hidden="true" />
                  PDF und XML
                </Button>
              )}
            </div>
          )}
          empty="Noch keine Auszahlungsrunden."
          caption="Auszahlungsrunden"
        />
      )}

      {creating && <NewRunDialog pending={pending} error={error} onClose={() => { setCreating(false); setError(null) }} onCreate={create} />}
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
          {FI_MESSAGES.alreadyReleased}
        </ConfirmDialog>
      )}
    </section>
  )
}

function NewRunDialog({
  pending,
  error,
  onClose,
  onCreate,
}: {
  pending: boolean
  error: string | null
  onClose: () => void
  onCreate: (half: string, date: string) => void
}) {
  const current = currentHalf()
  // Standard: vorheriges Halbjahr (dessen Abrechnungen werden ausgezahlt), sonst das aktuelle
  const options = halfOptions()
  const [half, setHalf] = useState(halfKey(options[1] ?? current))
  const [date, setDate] = useState(nextWorkday())
  return (
    <FormDialog
      title="Neue Auszahlungsrunde"
      description="Alle abgegebenen, auszahlbaren Abrechnungen des Halbjahres ohne Runde werden zugeordnet. Die Auswahl kann danach geändert werden."
      submitLabel="Anlegen"
      pendingLabel="Wird angelegt …"
      pending={pending}
      error={error}
      onClose={onClose}
      onSubmit={() => onCreate(half, date)}
    >
      <div className="flex flex-col gap-2">
        <Label htmlFor="fi-run-half">Halbjahr</Label>
        <select id="fi-run-half" value={half} onChange={(e) => setHalf(e.target.value)} className={selectClassName}>
          {options.map((h) => (
            <option key={halfKey(h)} value={halfKey(h)}>
              {halfLabel(h)}
            </option>
          ))}
        </select>
      </div>
      <div className="flex flex-col gap-2">
        <Label htmlFor="fi-run-date">Ausführungsdatum</Label>
        <Input id="fi-run-date" type="date" value={date} min={todayIso()} onChange={(e) => setDate(e.target.value)} className="sm:w-44" />
      </div>
    </FormDialog>
  )
}
