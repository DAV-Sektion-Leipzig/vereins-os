import { useState } from 'react'
import { Link, useLoaderData, useRevalidator } from 'react-router-dom'
import { ResponsiveTable, type Column } from '@/components/ResponsiveTable'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { useGrAccess } from '@/features/gr/access'
import { continueHref, type PendingResult, type PendingRow } from '@/features/gr/aufnahme/data'
import { grRpc } from '@/features/gr/shared/rpc'
import { FormError, HintBadge, LoadFailed } from '@/features/gr/shared/ui'
import { formatDateTime, personName } from '@/lib/format'

// T036 (US-GR-06, W7): offene Aufnahmen mit „Aufnahme fortsetzen“ und „Aufnahme abbrechen“
export function AufnahmenPage() {
  const { rows, failed } = useLoaderData() as PendingResult
  const { canEdit } = useGrAccess()
  const revalidator = useRevalidator()
  const [cancelling, setCancelling] = useState<PendingRow | null>(null)

  const actions = (row: PendingRow) =>
    canEdit && (
      <span className="flex flex-wrap gap-2">
        <Button asChild className="h-11 sm:h-8">
          <Link to={continueHref(row)}>Aufnahme fortsetzen</Link>
        </Button>
        <Button variant="ghost" onClick={() => setCancelling(row)} className="h-11 sm:h-8">
          Aufnahme abbrechen
        </Button>
      </span>
    )

  const columns: Column<PendingRow>[] = [
    { key: 'name', header: 'Name', cell: (r) => <span className="font-medium">{personName(r)}</span>, className: 'whitespace-normal' },
    { key: 'group', header: 'Gruppe', cell: (r) => <Link to={`/gr/gruppen/${r.group_id}`} className="underline-offset-4 hover:underline">{r.group_name}</Link> },
    {
      key: 'created',
      header: 'angelegt',
      cell: (r) => (
        <span>
          {formatDateTime(r.created_at)}
          {r.created_by_name && <span className="text-muted-foreground"> von {r.created_by_name}</span>}
        </span>
      ),
    },
    { key: 'hints', header: 'Hinweise', cell: (r) => (r.needs_guardian ? <HintBadge>Erziehungsberechtigte fehlen</HintBadge> : '–') },
    { key: 'actions', header: <span className="sr-only">Aktionen</span>, cell: actions },
  ]

  return (
    <section className="flex flex-col gap-4">
      <h1 className="text-xl font-semibold">Aufnahmen offen</h1>
      {failed ? (
        <LoadFailed />
      ) : (
        <ResponsiveTable
          rows={rows}
          rowKey={(r) => r.person_id}
          columns={columns}
          card={(r) => (
            <>
              <div className="flex flex-col gap-1">
                <span className="font-medium">{personName(r)}</span>
                <span className="text-sm text-muted-foreground">
                  {r.group_name} · angelegt {formatDateTime(r.created_at)}
                  {r.created_by_name && ` von ${r.created_by_name}`}
                </span>
                {r.needs_guardian && <HintBadge>Erziehungsberechtigte fehlen</HintBadge>}
              </div>
              {actions(r)}
            </>
          )}
          empty="Keine offenen Aufnahmen."
          caption="Offene Aufnahmen"
        />
      )}
      {cancelling && <CancelDialog row={cancelling} onClose={() => setCancelling(null)} onDone={() => (setCancelling(null), revalidator.revalidate())} />}
    </section>
  )
}

function CancelDialog({ row, onClose, onDone }: { row: PendingRow; onClose: () => void; onDone: () => void }) {
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)

  async function cancel() {
    setPending(true)
    const result = await grRpc('gr_cancel_admission', { p_person: row.person_id })
    setPending(false)
    if (result.error !== null) return setError(result.error)
    onDone()
  }

  return (
    <Dialog open onOpenChange={(open) => !open && !pending && onClose()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Aufnahme abbrechen: {personName(row)}</DialogTitle>
          <DialogDescription>Die Person wird aus Gruppen entfernt. Ihre Daten bleiben gespeichert.</DialogDescription>
        </DialogHeader>
        <FormError text={error} />
        <DialogFooter>
          <Button variant="outline" onClick={onClose} disabled={pending}>
            Zurück
          </Button>
          <Button variant="destructive" onClick={() => void cancel()} disabled={pending}>
            {pending ? 'Wird abgebrochen …' : 'Aufnahme abbrechen'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
