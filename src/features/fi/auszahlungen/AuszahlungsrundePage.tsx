import { useState } from 'react'
import { FileDownIcon, SendIcon, Trash2Icon } from 'lucide-react'
import { Link, useLoaderData, useNavigate, useRevalidator } from 'react-router-dom'
import { toast } from 'sonner'
import { ResponsiveTable, type Column } from '@/components/ResponsiveTable'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { ConfirmDialog } from '@/features/ez/shared/ConfirmDialog'
import type { Available, PreviewLine, RunPreview, RunResult } from '@/features/fi/auszahlungen/data'
import { FI_MESSAGES } from '@/features/fi/errors'
import { downloadPayoutFiles, reportDownload } from '@/features/fi/export/payout'
import { formatMoney, halfLabel, hintLabel, RUN_STATUS_LABELS } from '@/features/fi/labels'
import { fiRpc } from '@/features/fi/rpc'
import { FormError, LoadFailed } from '@/features/gr/shared/ui'
import { formatDate, formatDateTime, todayIso } from '@/lib/format'

type Dialog = 'release' | 'discard' | 'refetch' | null

// FT14 (US-FI-14, -15, -16): Runde im Entwurf mit Auswahl, Ausführungsdatum und Vorschau der Auszahlzeilen;
// Freigabe mit Rückfrage, danach Download von Auszahlliste (PDF) und Überweisungsdatei (XML); freigegeben: erneut abrufen.
export function AuszahlungsrundePage() {
  const { preview, failed } = useLoaderData() as RunResult
  if (failed || !preview) {
    return (
      <section className="flex flex-col gap-4">
        <h1 className="text-xl font-semibold">Auszahlungsrunde</h1>
        <LoadFailed />
        <Button variant="outline" asChild className="self-start">
          <Link to="/fi/auszahlungen">Zur Liste</Link>
        </Button>
      </section>
    )
  }
  return <Run key={preview.run.id} preview={preview} />
}

function Run({ preview }: { preview: RunPreview }) {
  const { run, lines, total, available } = preview
  const navigate = useNavigate()
  const revalidator = useRevalidator()
  const [dialog, setDialog] = useState<Dialog>(null)
  const [pending, setPending] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [date, setDate] = useState(run.execution_date)
  const draft = run.status === 'draft'
  const selectedIds = new Set(lines.map((l) => l.settlement_id))
  const names = Object.fromEntries(available.map((a) => [a.settlement_id, a.display_name]))

  function close() {
    setDialog(null)
    setError(null)
  }

  async function setSelection(ids: string[]) {
    setPending(true)
    setError(null)
    const res = await fiRpc('fi_set_payout_run_settlements', { p_run: run.id, p_ids: ids }, names)
    setPending(false)
    if (res.error) return setError(res.error.text)
    revalidator.revalidate()
  }

  async function saveDate() {
    setPending(true)
    setError(null)
    const res = await fiRpc('fi_update_payout_run', { p_run: run.id, p_execution_date: date })
    setPending(false)
    if (res.error) return setError(res.error.text)
    toast.success('Das Ausführungsdatum wurde gespeichert.')
    revalidator.revalidate()
  }

  async function discard() {
    setPending(true)
    const res = await fiRpc('fi_discard_payout_run', { p_run: run.id })
    setPending(false)
    if (res.error) return setError(res.error.text)
    toast.success('Die Runde wurde verworfen.')
    navigate('/fi/auszahlungen')
  }

  async function release() {
    setPending(true)
    setError(null)
    const res = await fiRpc('fi_release_payout_run', { p_run: run.id }, names)
    if (res.error) {
      setPending(false)
      return setError(res.error.text)
    }
    const files = await downloadPayoutFiles(run.id)
    setPending(false)
    close()
    revalidator.revalidate()
    if (files.error) return toast.error(`Die Runde ist freigegeben. ${files.error} Bitte die Dateien erneut abrufen.`)
    reportDownload(files.bankChanged)
  }

  async function refetch() {
    setPending(true)
    const files = await downloadPayoutFiles(run.id)
    setPending(false)
    if (files.error) return setError(files.error)
    close()
    reportDownload(files.bankChanged)
  }

  const lineColumns: Column<PreviewLine>[] = [
    { key: 'last', header: 'Zuname', cell: (l) => l.last_name },
    { key: 'first', header: 'Vorname', cell: (l) => l.first_name },
    { key: 'amount', header: 'Betrag', cell: (l) => formatMoney(l.amount), className: 'text-right tabular-nums', headerClassName: 'text-right' },
    { key: 'group', header: 'Gruppe', cell: (l) => l.group_label },
  ]

  return (
    <section className="flex flex-col gap-6">
      <header className="flex flex-col gap-3">
        <div className="flex flex-col gap-1">
          <Link to="/fi/auszahlungen" className="text-sm text-muted-foreground underline-offset-4 hover:underline">
            Auszahlungsrunden
          </Link>
          <div className="flex flex-wrap items-baseline justify-between gap-3">
            <h1 className="text-xl font-semibold">
              {halfLabel(run)} – Runde {run.number}
            </h1>
            <span className="text-xl font-semibold tabular-nums">{formatMoney(total)}</span>
          </div>
          <div>
            <Badge variant={draft ? 'outline' : 'default'}>{RUN_STATUS_LABELS[run.status]}</Badge>
          </div>
        </div>
        <div className="flex flex-wrap gap-2">
          {draft ? (
            <>
              <Button onClick={() => setDialog('release')} disabled={lines.length === 0 || pending}>
                <SendIcon data-icon="inline-start" aria-hidden="true" />
                Freigeben
              </Button>
              <Button variant="outline" onClick={() => setDialog('discard')} disabled={pending}>
                <Trash2Icon data-icon="inline-start" aria-hidden="true" />
                Verwerfen
              </Button>
            </>
          ) : (
            <Button variant="outline" onClick={() => setDialog('refetch')}>
              <FileDownIcon data-icon="inline-start" aria-hidden="true" />
              PDF und XML erneut abrufen
            </Button>
          )}
        </div>
        {!dialog && <FormError text={error} />}
      </header>

      {draft ? (
        <form
          onSubmit={(e) => {
            e.preventDefault()
            void saveDate()
          }}
          className="flex flex-wrap items-end gap-2"
        >
          <div className="flex flex-col gap-2">
            <Label htmlFor="fi-run-date">Ausführungsdatum</Label>
            <Input id="fi-run-date" type="date" value={date} min={todayIso()} onChange={(e) => setDate(e.target.value)} className="sm:w-44" />
          </div>
          <Button type="submit" variant="outline" disabled={pending || date === run.execution_date}>
            Speichern
          </Button>
        </form>
      ) : (
        <dl className="grid gap-x-6 gap-y-2 text-sm sm:grid-cols-[max-content_1fr]">
          {(
            [
              ['Ausführungsdatum', formatDate(run.execution_date)],
              ['Freigegeben', run.released_at ? formatDateTime(run.released_at) : '–'],
              ['Überweisungen', String(run.line_count ?? lines.length)],
              ['Nachrichten-ID', run.msg_id ?? '–'],
              ['Zahlungs-ID', run.pmt_inf_id ?? '–'],
            ] as [string, string][]
          ).map(([label, value]) => (
            <div key={label} className="contents">
              <dt className="text-muted-foreground">{label}</dt>
              <dd className="mb-2 font-mono text-sm break-all sm:mb-0">{value}</dd>
            </div>
          ))}
        </dl>
      )}

      {draft && (
        <section aria-labelledby="fi-run-select" className="flex flex-col gap-2">
          <h2 id="fi-run-select" className="text-lg font-semibold">
            Abgegebene Abrechnungen
          </h2>
          {available.length === 0 ? (
            <p className="text-sm text-muted-foreground">Keine auszahlbaren Abrechnungen.</p>
          ) : (
            <ul className="flex flex-col divide-y rounded-xl border">
              {available.map((a) => (
                <AvailableRow
                  key={a.settlement_id}
                  item={a}
                  checked={selectedIds.has(a.settlement_id)}
                  disabled={pending || (!a.payable && !selectedIds.has(a.settlement_id))}
                  onToggle={(on) =>
                    setSelection(on ? [...selectedIds, a.settlement_id] : [...selectedIds].filter((id) => id !== a.settlement_id))
                  }
                />
              ))}
            </ul>
          )}
        </section>
      )}

      <section aria-labelledby="fi-run-lines" className="flex flex-col gap-2">
        <div className="flex items-baseline justify-between gap-3">
          <h2 id="fi-run-lines" className="text-lg font-semibold">
            {draft ? 'Vorschau der Auszahlzeilen' : 'Auszahlzeilen'}
          </h2>
          <span className="text-sm text-muted-foreground tabular-nums">
            {lines.length} Zeilen · {formatMoney(total)}
          </span>
        </div>
        <ResponsiveTable
          rows={lines}
          rowKey={(l) => `${l.settlement_id}-${l.group_label}`}
          columns={lineColumns}
          card={(l) => (
            <div className="flex items-start justify-between gap-3">
              <span className="flex flex-col">
                <span className="font-medium">
                  {l.last_name}, {l.first_name}
                </span>
                <span className="text-sm text-muted-foreground">{l.group_label}</span>
              </span>
              <span className="tabular-nums">{formatMoney(l.amount)}</span>
            </div>
          )}
          empty="Keine auszahlbaren Abrechnungen."
          caption="Auszahlzeilen"
        />
      </section>

      {dialog === 'release' && (
        <ConfirmDialog
          title="Runde freigeben?"
          confirmLabel="Freigeben"
          pendingLabel="Wird freigegeben …"
          pending={pending}
          error={error}
          onConfirm={release}
          onClose={close}
        >
          Runde {run.number} mit {lines.length} Überweisungen über {formatMoney(total)} freigeben? Danach sind die Abrechnungen
          ausgezahlt.
        </ConfirmDialog>
      )}
      {dialog === 'discard' && (
        <ConfirmDialog
          title="Runde verwerfen?"
          confirmLabel="Verwerfen"
          pendingLabel="Wird verworfen …"
          pending={pending}
          error={error}
          destructive
          onConfirm={discard}
          onClose={close}
        >
          Die Abrechnungen werden wieder frei. Die Nummer der Runde wird nicht erneut vergeben.
        </ConfirmDialog>
      )}
      {dialog === 'refetch' && (
        <ConfirmDialog
          title="Dateien erneut abrufen?"
          confirmLabel="Herunterladen"
          pendingLabel="Wird erzeugt …"
          pending={pending}
          error={error}
          onConfirm={refetch}
          onClose={close}
        >
          {FI_MESSAGES.alreadyReleased}
        </ConfirmDialog>
      )}
    </section>
  )
}

function AvailableRow({ item: a, checked, disabled, onToggle }: { item: Available; checked: boolean; disabled: boolean; onToggle: (on: boolean) => void }) {
  const id = `fi-run-s-${a.settlement_id}`
  return (
    <li className="flex flex-wrap items-center justify-between gap-2 pr-3">
      <label htmlFor={id} className="flex min-h-11 flex-1 cursor-pointer items-center gap-3 pl-3">
        <input id={id} type="checkbox" checked={checked} disabled={disabled} onChange={(e) => onToggle(e.target.checked)} className="size-5 shrink-0 accent-primary" />
        <span className="flex flex-col">
          <Link to={`/fi/abrechnung/${a.settlement_id}`} className="underline-offset-4 hover:underline">
            {a.display_name}
          </Link>
          {!a.payable && (
            <span className="text-sm text-destructive">nicht auszahlbar: {a.reasons.map((r) => hintLabel(r)).join(', ')}</span>
          )}
        </span>
      </label>
      <span className="tabular-nums">{formatMoney(a.amount)}</span>
    </li>
  )
}
