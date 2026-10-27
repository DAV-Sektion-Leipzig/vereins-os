import { useEffect, useState } from 'react'
import { FileTextIcon, RotateCcwIcon, Trash2Icon } from 'lucide-react'
import { useLoaderData, useNavigate, useRevalidator } from 'react-router-dom'
import { toast } from 'sonner'
import { Pagination } from '@/components/Pagination'
import { ResponsiveTable, type Column } from '@/components/ResponsiveTable'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { useScAccess } from '@/features/sc/access'
import {
  discardMail,
  loadMailContent,
  OUTBOX_LABELS,
  retryMail,
  type OutboxData,
  type OutboxFilter,
  type OutboxRow,
} from '@/features/sc/data'
import { ErrorText, FilterDate, FilterSelect, LoadFailed, OutboxBadge } from '@/features/sc/ui'
import { toMessage } from '@/lib/errors'
import { formatDateTime } from '@/lib/format'

const PARAMS: Record<keyof OutboxFilter, string> = { state: 'zustand', module: 'modul', occasion: 'anlass', from: 'von', to: 'bis' }

function href(filter: OutboxFilter, page = 1) {
  const p = new URLSearchParams()
  for (const key of Object.keys(PARAMS) as (keyof OutboxFilter)[]) if (filter[key]) p.set(PARAMS[key], filter[key])
  if (page > 1) p.set('seite', String(page))
  const q = p.toString()
  return q ? `/schnittstellen/postausgang?${q}` : '/schnittstellen/postausgang'
}

type Action = { kind: 'content' | 'discard'; row: OutboxRow } | null

// US-SC-10: Postausgang der letzten 90 Tage; Betreff und Text nur mit SC bearbeiten (Erhebung E1).
export function PostausgangPage() {
  const data = useLoaderData() as OutboxData
  const { canEdit } = useScAccess()
  const navigate = useNavigate()
  const revalidator = useRevalidator()
  const [action, setAction] = useState<Action>(null)
  const [pending, setPending] = useState<string | null>(null)

  if (data.failed) return <LoadFailed title="Postausgang" />

  const occasionName = (code: string) => data.occasions.find((o) => o.code === code)?.name ?? code
  const setFilter = (key: keyof OutboxFilter, value: string) => navigate(href({ ...data.filter, [key]: value }))

  async function retry(row: OutboxRow) {
    setPending(row.id)
    const { error } = await retryMail(row.id)
    setPending(null)
    if (error) toast.error(toMessage(error).text)
    else {
      toast.success('Die E-Mail wird erneut gesendet.')
      revalidator.revalidate()
    }
  }

  const actions = (r: OutboxRow) =>
    canEdit && (
      <span className="flex flex-wrap gap-1">
        <Button variant="ghost" size="xs" onClick={() => setAction({ kind: 'content', row: r })}>
          <FileTextIcon data-icon="inline-start" aria-hidden="true" />
          Inhalt
        </Button>
        {r.state === 'failed' && (
          <Button variant="ghost" size="xs" onClick={() => retry(r)} disabled={pending === r.id}>
            <RotateCcwIcon data-icon="inline-start" aria-hidden="true" />
            erneut senden
          </Button>
        )}
        {(r.state === 'failed' || r.state === 'waiting') && (
          <Button variant="ghost" size="xs" onClick={() => setAction({ kind: 'discard', row: r })}>
            <Trash2Icon data-icon="inline-start" aria-hidden="true" />
            verwerfen
          </Button>
        )}
      </span>
    )

  const columns: Column<OutboxRow>[] = [
    { key: 'created', header: 'Eingestellt', cell: (r) => formatDateTime(r.created_at), className: 'whitespace-nowrap tabular-nums' },
    { key: 'occasion', header: 'Anlass', cell: (r) => `${occasionName(r.occasion_code)} (${r.module_code})` },
    { key: 'recipient', header: 'Empfänger', cell: (r) => <Email value={r.recipient_email} />, className: 'whitespace-normal' },
    { key: 'state', header: 'Zustand', cell: (r) => <OutboxBadge state={r.state} /> },
    { key: 'attempts', header: 'Versuche', cell: (r) => r.attempts, className: 'tabular-nums' },
    {
      key: 'info',
      header: 'Versendet / Fehler',
      cell: (r) => (r.sent_at ? formatDateTime(r.sent_at) : (r.last_error ?? '–')),
      className: 'whitespace-normal',
    },
    ...(canEdit ? [{ key: 'actions', header: <span className="sr-only">Aktionen</span>, cell: actions }] : []),
  ]

  return (
    <section className="flex flex-col gap-4">
      <div className="flex flex-col gap-1">
        <h1 className="text-xl font-semibold">Postausgang</h1>
        <p className="text-sm text-muted-foreground">
          E-Mails der letzten 90 Tage. Fehlgeschlagene E-Mails kannst du erneut senden oder verwerfen.
        </p>
      </div>

      <div className="flex flex-wrap items-end gap-3">
        <FilterSelect
          id="sc-filter-state"
          label="Zustand"
          value={data.filter.state}
          options={Object.entries(OUTBOX_LABELS).map(([value, label]) => ({ value, label }))}
          onChange={(v) => setFilter('state', v)}
        />
        <FilterSelect
          id="sc-filter-occasion"
          label="Anlass"
          value={data.filter.occasion}
          options={data.occasions.map((o) => ({ value: o.code, label: o.name }))}
          onChange={(v) => setFilter('occasion', v)}
        />
        <FilterSelect
          id="sc-filter-module"
          label="Modul"
          value={data.filter.module}
          options={[...new Set(data.occasions.map((o) => o.module_code))].map((m) => ({ value: m, label: m }))}
          onChange={(v) => setFilter('module', v)}
        />
        <FilterDate id="sc-filter-from" label="von" value={data.filter.from} onChange={(v) => setFilter('from', v)} />
        <FilterDate id="sc-filter-to" label="bis" value={data.filter.to} onChange={(v) => setFilter('to', v)} />
      </div>

      <ResponsiveTable
        rows={data.rows}
        rowKey={(r) => r.id}
        columns={columns}
        empty="Keine E-Mails in den letzten 90 Tagen."
        caption="Postausgang"
        card={(r) => (
          <div className="flex flex-col gap-1 text-sm">
            <span className="flex items-center justify-between gap-2">
              <span className="font-medium">{occasionName(r.occasion_code)}</span>
              <OutboxBadge state={r.state} />
            </span>
            <span className="break-all">{r.recipient_email}</span>
            <span className="text-muted-foreground tabular-nums">
              {formatDateTime(r.created_at)} · {r.attempts === 1 ? '1 Versuch' : `${r.attempts} Versuche`}
            </span>
            {r.last_error && r.state !== 'sent' && <span className="text-destructive">{r.last_error}</span>}
            {actions(r)}
          </div>
        )}
      />
      <Pagination page={data.page} total={data.total} href={(p) => href(data.filter, p)} label="E-Mails" />

      {action?.kind === 'content' && <ContentDialog row={action.row} onClose={() => setAction(null)} />}
      {action?.kind === 'discard' && (
        <DiscardDialog
          row={action.row}
          onClose={() => setAction(null)}
          onDone={() => {
            toast.success('Die E-Mail ist verworfen.')
            setAction(null)
            revalidator.revalidate()
          }}
        />
      )}
    </section>
  )
}

function ContentDialog({ row, onClose }: { row: OutboxRow; onClose: () => void }) {
  const [content, setContent] = useState<{ subject: string; body: string } | null>(null)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    let active = true
    loadMailContent(row.id).then(({ data, error: loadError }) => {
      if (!active) return
      if (loadError) setError(toMessage(loadError).text)
      else setContent(((data ?? []) as { subject: string; body: string }[])[0] ?? null)
    })
    return () => {
      active = false
    }
  }, [row.id])

  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="sm:max-w-2xl">
        <DialogHeader>
          <DialogTitle>Inhalt der E-Mail</DialogTitle>
          <DialogDescription>An {row.recipient_email}</DialogDescription>
        </DialogHeader>
        {content ? (
          <div className="flex flex-col gap-1 rounded-lg bg-muted px-3 py-2 text-sm">
            <span className="font-medium">{content.subject}</span>
            <span className="whitespace-pre-line">{content.body}</span>
          </div>
        ) : (
          !error && <p className="text-sm text-muted-foreground">Wird geladen …</p>
        )}
        <ErrorText text={error} />
        <DialogFooter>
          <Button type="button" variant="outline" onClick={onClose}>
            Schließen
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

function DiscardDialog({ row, onClose, onDone }: { row: OutboxRow; onClose: () => void; onDone: () => void }) {
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)

  async function confirm() {
    setPending(true)
    const { error: discardError } = await discardMail(row.id)
    setPending(false)
    if (discardError) setError(toMessage(discardError).text)
    else onDone()
  }

  return (
    <Dialog open onOpenChange={(open) => !open && !pending && onClose()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>E-Mail verwerfen?</DialogTitle>
          <DialogDescription>Die E-Mail an {row.recipient_email} wird nicht mehr gesendet.</DialogDescription>
        </DialogHeader>
        <ErrorText text={error} />
        <DialogFooter>
          <Button type="button" variant="outline" onClick={onClose} disabled={pending}>
            Abbrechen
          </Button>
          <Button type="button" variant="destructive" onClick={confirm} disabled={pending}>
            {pending ? 'Wird verworfen …' : 'Verwerfen'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

/** E-Mail-Adresse, die nur vor dem „@“ umbricht. */
function Email({ value }: { value: string }) {
  const at = value.indexOf('@')
  if (at < 0) return <>{value}</>
  return (
    <span>
      <span className="whitespace-nowrap">{value.slice(0, at)}</span>
      <wbr />
      <span className="whitespace-nowrap">{value.slice(at)}</span>
    </span>
  )
}
