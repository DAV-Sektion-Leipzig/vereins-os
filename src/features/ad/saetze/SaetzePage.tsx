import { useMemo, useState, type FormEvent } from 'react'
import { CircleAlertIcon, PlusIcon, RotateCwIcon } from 'lucide-react'
import { useLoaderData, useRevalidator } from 'react-router-dom'
import { toast } from 'sonner'
import { ResponsiveTable, type Column } from '@/components/ResponsiveTable'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { useAdAccess } from '@/features/ad/access'
import {
  formatRate,
  GROUP_LABELS,
  GROUPS,
  parseNumber,
  ratesAt,
  saveNewRate,
  type Rate,
  type RatesData,
} from '@/features/ad/saetze/data'
import { MESSAGES, toMessage } from '@/lib/errors'
import { formatDate, todayIso } from '@/lib/format'

// T129 (spec.md AD v0.10, R46): Sätze und Pauschalen je Gruppe mit „Stand am“, Historie und neuem Wert (nur Admin).
export function SaetzePage() {
  const { rates, failed } = useLoaderData() as RatesData
  const { canEdit } = useAdAccess()
  const revalidator = useRevalidator()
  const [day, setDay] = useState(todayIso())
  const [editing, setEditing] = useState<Rate | null>(null)

  const current = useMemo(() => ratesAt(rates, day || todayIso()), [rates, day])
  const history = useMemo(() => {
    const map = new Map<string, Rate[]>()
    for (const rate of rates) map.set(rate.rate_key, [...(map.get(rate.rate_key) ?? []), rate])
    return map
  }, [rates])

  const columns: Column<Rate>[] = [
    {
      key: 'label',
      header: 'Bezeichnung',
      cell: (r) => (
        <span className="flex flex-col">
          <span>{r.label}</span>
          <span className="text-xs text-muted-foreground">{r.rate_key}</span>
        </span>
      ),
      className: 'whitespace-normal',
    },
    { key: 'value', header: 'Wert', cell: (r) => formatRate(r), className: 'tabular-nums' },
    { key: 'from', header: 'gültig ab', cell: (r) => formatDate(r.valid_from), className: 'tabular-nums' },
    { key: 'source', header: 'Quelle', cell: (r) => r.source, className: 'whitespace-normal text-muted-foreground' },
    { key: 'history', header: 'Historie', cell: (r) => <History rows={history.get(r.rate_key) ?? []} /> },
    ...(canEdit
      ? [
          {
            key: 'action',
            header: <span className="sr-only">Aktion</span>,
            cell: (r: Rate) => (
              <Button variant="outline" size="sm" onClick={() => setEditing(r)}>
                Neuer Wert
              </Button>
            ),
          },
        ]
      : []),
  ]

  return (
    <section className="flex flex-col gap-4">
      <div className="flex flex-col gap-1">
        <h1 className="text-xl font-semibold">Sätze und Pauschalen</h1>
        <p className="text-sm text-muted-foreground">
          Ein neuer Wert gilt ab seinem Datum; frühere Werte bleiben in der Historie. Finanzen und Planungshilfe rechnen mit
          dem Wert, der am Datum des Einsatzes gilt.
        </p>
      </div>

      <div className="flex flex-col gap-2 sm:max-w-xs">
        <Label htmlFor="rates-day">Stand am</Label>
        <Input id="rates-day" type="date" value={day} onChange={(event) => setDay(event.target.value)} />
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
      ) : current.size === 0 ? (
        <p className="text-sm text-muted-foreground">Noch keine Sätze angelegt.</p>
      ) : (
        GROUPS.map((group) => {
          const rows = [...current.values()]
            .filter((r) => r.rate_group === group)
            .sort((a, b) => a.label.localeCompare(b.label, 'de'))
          if (rows.length === 0) return null
          return (
            <section key={group} aria-labelledby={`group-${group}`} className="flex flex-col gap-2">
              <h2 id={`group-${group}`} className="font-medium">
                {GROUP_LABELS[group]}
              </h2>
              <ResponsiveTable
                rows={rows}
                rowKey={(r) => r.rate_key}
                columns={columns}
                empty=""
                caption={GROUP_LABELS[group]}
                card={(r) => (
                  <div className="flex flex-col gap-1">
                    <span className="font-medium">{r.label}</span>
                    <span className="text-sm tabular-nums">
                      {formatRate(r)} · ab {formatDate(r.valid_from)}
                    </span>
                    <span className="text-sm text-muted-foreground">{r.source}</span>
                    <History rows={history.get(r.rate_key) ?? []} />
                    {canEdit && (
                      <Button variant="outline" size="sm" className="self-start" onClick={() => setEditing(r)}>
                        Neuer Wert
                      </Button>
                    )}
                  </div>
                )}
              />
            </section>
          )
        })
      )}

      {editing && (
        <NewRateDialog
          rate={editing}
          onClose={() => setEditing(null)}
          onSaved={() => {
            setEditing(null)
            revalidator.revalidate()
          }}
        />
      )}
    </section>
  )
}

function History({ rows }: { rows: Rate[] }) {
  if (rows.length < 2) return <span className="text-sm text-muted-foreground">–</span>
  return (
    <details className="text-sm">
      <summary className="cursor-pointer text-muted-foreground">{rows.length} Werte</summary>
      <ul className="mt-1 flex flex-col gap-0.5 tabular-nums">
        {rows.map((r) => (
          <li key={r.id}>
            ab {formatDate(r.valid_from)}: {formatRate(r)}
          </li>
        ))}
      </ul>
    </details>
  )
}

function NewRateDialog({ rate, onClose, onSaved }: { rate: Rate; onClose: () => void; onSaved: () => void }) {
  const isFee = rate.rate_group === 'payment_fee'
  const [value, setValue] = useState('')
  const [percent, setPercent] = useState('')
  const [fixed, setFixed] = useState('')
  const [active, setActive] = useState(rate.active)
  const [validFrom, setValidFrom] = useState('')
  const [source, setSource] = useState(rate.source)
  const [note, setNote] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)
    const parsed = { value: parseNumber(value), percent: parseNumber(percent), fixed: parseNumber(fixed) }
    const numbers = isFee ? [parsed.percent, parsed.fixed] : [parsed.value]
    if (!validFrom || !source.trim() || numbers.some((n) => n === null)) {
      setError(MESSAGES.rateFieldRequired)
      return
    }
    if (numbers.some((n) => Number.isNaN(n) || (n as number) < 0)) {
      setError(MESSAGES.rateValue)
      return
    }
    setPending(true)
    const { error: saveError } = await saveNewRate({ base: rate, ...parsed, active, validFrom, source, note })
    setPending(false)
    if (saveError) {
      setError(toMessage(saveError).text)
      return
    }
    toast.success(`Neuer Wert ab ${formatDate(validFrom)} gespeichert.`)
    onSaved()
  }

  return (
    <Dialog open onOpenChange={(open) => !open && !pending && onClose()}>
      <DialogContent>
        <form onSubmit={onSubmit} noValidate className="flex flex-col gap-4">
          <DialogHeader>
            <DialogTitle>Neuer Wert: {rate.label}</DialogTitle>
            <DialogDescription>
              Bisher {formatRate(rate)} ab {formatDate(rate.valid_from)}. Berechnungen ab dem neuen Datum nutzen den neuen
              Wert; frühere Einsätze behalten ihren Satzstand.
            </DialogDescription>
          </DialogHeader>
          {isFee ? (
            <div className="grid grid-cols-2 gap-3">
              <div className="flex flex-col gap-2">
                <Label htmlFor="rate-percent">Prozent</Label>
                <Input id="rate-percent" inputMode="decimal" value={percent} onChange={(e) => setPercent(e.target.value)} />
              </div>
              <div className="flex flex-col gap-2">
                <Label htmlFor="rate-fixed">fester Betrag (€)</Label>
                <Input id="rate-fixed" inputMode="decimal" value={fixed} onChange={(e) => setFixed(e.target.value)} />
              </div>
              <label className="col-span-2 flex items-center gap-2 text-sm">
                <input type="checkbox" checked={active} onChange={(e) => setActive(e.target.checked)} className="size-4 accent-primary" />
                Zahlmethode aktiv
              </label>
            </div>
          ) : (
            <div className="flex flex-col gap-2">
              <Label htmlFor="rate-value">Wert ({rate.unit})</Label>
              <Input id="rate-value" inputMode="decimal" value={value} onChange={(e) => setValue(e.target.value)} />
            </div>
          )}
          <div className="flex flex-col gap-2">
            <Label htmlFor="rate-from">gültig ab</Label>
            <Input id="rate-from" type="date" value={validFrom} onChange={(e) => setValidFrom(e.target.value)} />
          </div>
          <div className="flex flex-col gap-2">
            <Label htmlFor="rate-source">Quelle</Label>
            <Input id="rate-source" value={source} onChange={(e) => setSource(e.target.value)} />
          </div>
          <div className="flex flex-col gap-2">
            <Label htmlFor="rate-note">
              Hinweis <span className="font-normal text-muted-foreground">(optional)</span>
            </Label>
            <Input id="rate-note" value={note} onChange={(e) => setNote(e.target.value)} />
          </div>
          {error && (
            <p role="alert" className="flex items-center gap-2 text-sm text-destructive">
              <CircleAlertIcon aria-hidden="true" className="size-4 shrink-0" />
              {error}
            </p>
          )}
          <DialogFooter>
            <Button type="button" variant="outline" onClick={onClose} disabled={pending}>
              Abbrechen
            </Button>
            <Button type="submit" disabled={pending}>
              <PlusIcon data-icon="inline-start" aria-hidden="true" />
              {pending ? 'Speichern …' : 'Speichern'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
